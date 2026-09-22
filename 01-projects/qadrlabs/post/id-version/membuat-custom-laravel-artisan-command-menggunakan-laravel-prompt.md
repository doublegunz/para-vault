---
title: "Membuat Custom Laravel Artisan Command menggunakan Laravel Prompt"
slug: "membuat-custom-laravel-artisan-command-menggunakan-laravel-prompt"
category: "Laravel"
date: "2023-08-15"
status: "published"
original_title: "Build a Custom Artisan Command with Laravel Prompts in Laravel 13"
original_slug: "build-a-custom-artisan-command-with-laravel-prompts-in-laravel-13"
---

# Membuat Custom Artisan Command dengan Laravel Prompts di Laravel 13

Membuat akun user lewat query manual terasa praktis sampai Anda lupa melakukan hashing password atau memasukkan email yang sudah digunakan. Mengulang pekerjaan ini tanpa validasi membuat kesalahan mudah terlewat. Dengan custom Artisan command dan Laravel Prompts, Anda dapat memandu operator memasukkan data yang valid langsung dari terminal.

Tutorial ini memperbarui contoh Laravel 10 menjadi project baru Laravel 13 menggunakan Laravel Installer. Kita tetap membuat command `make:user`, tetapi seluruh input sekarang interaktif dan password tidak ditampilkan sebagai teks biasa. Ini adalah tutorial project baru, bukan prosedur upgrade aplikasi yang sudah berjalan.

## Overview {#overview}

Kita akan menggunakan tabel user bawaan dan SQLite agar dapat fokus pada command. Contoh diuji dengan PHP 8.5.9, Laravel Installer 5.32.0, Laravel Framework 13.32.0, dan Laravel Prompts 0.3.24.

### Yang Akan Dibuat

- Command `make:user` yang meminta nama, email, dan password.
- Validasi input sebelum user disimpan ke database.
- Delapan kasus Pest untuk pembuatan user, hashing, dan penolakan input tidak valid.

### Yang Akan Dipelajari

- Membuat project dengan Laravel Installer.
- Membuat custom Artisan command dengan Laravel Prompts.
- Menyembunyikan input password dan menyimpan hash.
- Menguji command interaktif serta hasilnya di database.

### Yang Perlu Disiapkan

- PHP 8.3 atau lebih baru merupakan persyaratan Laravel 13. Untuk mengikuti setup yang diuji di sini, gunakan PHP 8.4 atau lebih baru dengan ekstensi SQLite yang aktif, karena Pest 5.2.1 yang dipasang installer membutuhkan PHP 8.4+.
- Composer dan Laravel Installer yang dapat dijalankan dari terminal.
- Terminal macOS, Linux, atau Windows dengan WSL untuk tampilan interaktif Laravel Prompts.
- Pemahaman dasar PHP, Eloquent, migration, dan penggunaan terminal.

## Step 1: Buat Project Laravel 13 {#step-1-create-project}

Buka terminal di direktori kerja Anda. Jika Laravel Installer belum tersedia, pasang dengan command berikut.

```bash
composer global require laravel/installer
```

Command tersebut memasang installer secara global. Pastikan direktori binary global Composer berada di PATH terminal Anda. Jika installer sudah terpasang, Anda dapat memperbaruinya dengan command berikut.

```bash
composer global update laravel/installer
```

Selanjutnya, buat project baru dengan SQLite dan Pest.

```bash
laravel new custom-command-laravel --no-interaction --database=sqlite --pest --no-boost
cd custom-command-laravel
php artisan --version
```

Installer menggunakan SQLite, memasang Pest, dan melewati instalasi Boost. Opsi `--no-interaction` membuat proses setup tidak memerlukan jawaban interaktif. Command ini mengikuti versi Laravel yang dipilih installer, jadi pastikan hasil pemeriksaan menunjukkan 13.x. Output versi pada pengujian tutorial ini:

```text
Laravel Framework 13.32.0
```

Laravel Prompts sudah disertakan pada Laravel 13, sehingga tidak memerlukan langkah instalasi package terpisah. Lihat [dokumentasi instalasi Laravel](https://laravel.com/docs/13.x/installation) dan [instalasi Laravel Prompts](https://laravel.com/docs/13.x/prompts#installation) untuk detailnya.

## Step 2: Periksa Database dan Model User {#step-2-prepare-database}

Installer menyiapkan database SQLite lokal. Jalankan migration untuk memastikan tabel yang diperlukan tersedia.

```bash
php artisan migrate
```

Pada project pengujian, installer sudah menjalankan migration sehingga hasilnya:

```text

   INFO  Nothing to migrate.  

```

Jika masih ada migration yang belum dijalankan, Laravel akan menjalankannya terlebih dahulu. Anda tidak perlu membuat database MySQL atau menambahkan credentials database untuk contoh ini.

Buka `app/Models/User.php`. Model bawaan pada project yang diuji sudah memiliki atribut berikut. Pastikan isinya sesuai, lalu simpan file jika Anda melakukan penyesuaian.

```php
<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }
}
```

Atribut `#[Fillable]` mengizinkan pengisian nama, email, dan password melalui mass assignment. Atribut `#[Hidden]` menyembunyikan password dan remember token saat model diserialisasi. Cast `hashed` mempertahankan perilaku hashing bawaan model. Periksa sintaksnya:

```bash
php -l app/Models/User.php
```

```text
No syntax errors detected in app/Models/User.php
```

## Step 3: Buat Command Interaktif {#step-3-create-command}

Buat class command menggunakan generator Artisan.

```bash
php artisan make:command MakeUser
```

Command tersebut membuat `app/Console/Commands/MakeUser.php`. Buka file itu, ganti isinya dengan kode lengkap berikut, lalu simpan.

```php
<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;

use function Laravel\Prompts\password;
use function Laravel\Prompts\text;

class MakeUser extends Command
{
    protected $signature = 'make:user';

    protected $description = 'Create a user through interactive prompts';

    public function handle(): int
    {
        // Validate each answer before moving to the next prompt.
        $name = text(
            label: 'What is your name?',
            required: 'The name field is required.',
            validate: ['name' => 'required|string|max:255'],
            transform: fn (string $value) => trim($value),
        );

        $email = text(
            label: 'What is your email?',
            required: 'The email field is required.',
            validate: ['email' => 'required|email|max:255|unique:users,email'],
            transform: fn (string $value) => trim($value),
        );

        // Hide the password while it is typed; do not accept it as an argument.
        $password = password(
            label: 'What is your password?',
            required: 'The password field is required.',
            validate: ['password' => 'required|string|min:8'],
        );

        $user = User::create([
            'name' => $name,
            'email' => $email,
            'password' => Hash::make($password),
        ]);

        $this->info("User {$user->name} created successfully.");

        return self::SUCCESS;
    }
}
```

Signature `make:user` tidak lagi menerima argumen opsional. Fungsi `text()` meminta nama dan email, memangkas whitespace di awal/akhir input, serta memvalidasi nilainya sebelum melanjutkan. Nama wajib diisi dan maksimal 255 karakter. Email wajib memiliki format valid, maksimal 255 karakter, dan belum digunakan pada tabel user.

Fungsi `password()` menyembunyikan karakter yang diketik dan mensyaratkan minimal delapan karakter. `Hash::make()` menghasilkan hash sebelum data disimpan dengan `User::create()`. Hashing bukan enkripsi yang dapat dibalik untuk membaca password asli. Command kemudian menampilkan nama user dan mengembalikan `self::SUCCESS`.

Periksa bahwa Laravel mengenali command baru.

```bash
php artisan help make:user
```

```text
Description:
  Create a user through interactive prompts

Usage:
  make:user

Options:
  -h, --help            Display help for the given command. When no command is given display help for the list command
      --silent          Do not output any message
  -q, --quiet           Only errors are displayed. All other output is suppressed
  -V, --version         Display this application version
      --ansi|--no-ansi  Force (or disable --no-ansi) ANSI output
  -n, --no-interaction  Do not ask any interactive question
      --env[=ENV]       The environment the command should run under
  -v|vv|vvv, --verbose  Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug
```

Class dalam direktori command bawaan ditemukan otomatis. Output di atas menunjukkan signature tanpa argumen data user. Jalankan command secara interaktif, tanpa opsi untuk menonaktifkan interaksi.

## Step 4: Uji Coba {#step-4-try-it-out}

Sekarang kita periksa alur terminal, data yang tersimpan, dan pengujian otomatis. Gunakan data contoh lokal berikut agar mudah membandingkan hasilnya.

### Buat User dari Terminal

```bash
php artisan make:user
```

Isi nama dengan `Admin`, email dengan `admin@example.com`, dan password contoh dengan `demo-password-123`. Tekan Enter setelah setiap jawaban. Password ditampilkan sebagai karakter masking, bukan teks aslinya. Baris terakhir ketika berhasil:

```text
User Admin created successfully.
```

Nama contoh tersebut tidak memberikan hak administrator. Command membuat user biasa menggunakan model bawaan.

Periksa record melalui Tinker dengan hanya menampilkan nama dan email.

```bash
php artisan tinker --execute="dump(App\Models\User::where('email', 'admin@example.com')->first(['name', 'email'])->toArray());"
```

```text
array:2 [
  "name" => "Admin"
  "email" => "admin@example.com"
] // vendor/psy/psysh/src/ExecutionClosure.php(41) : eval()'d code:1
```

Hasil ini menunjukkan data dari database SQLite lokal. Password sengaja tidak disertakan dalam query pemeriksaan.

### Coba Input yang Tidak Valid

Jalankan command kembali. Coba nama kosong, email dengan format salah, email yang sudah digunakan, atau password yang lebih pendek dari delapan karakter. Prompt menampilkan kesalahan dan tetap menunggu jawaban yang valid. Hapus jawaban yang salah sebelum mengetik penggantinya. Untuk email duplikat, gunakan alamat baru agar dapat melanjutkan.

Tidak ada user baru yang disimpan sampai seluruh input lolos validasi. Anda dapat membatalkan sebelum penyimpanan dengan Ctrl+C.

### Tambahkan Delapan Kasus Pest

Buat `tests/Feature/MakeUserTest.php`, isi dengan kode berikut, lalu simpan. Pest sudah dipasang oleh installer, sehingga tidak perlu dipasang ulang.

```php
<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;

uses(RefreshDatabase::class);

it('creates a user from interactive input', function () {
    $this->artisan('make:user')
        ->expectsQuestion('What is your name?', 'Admin')
        ->expectsQuestion('What is your email?', 'admin@example.com')
        ->expectsQuestion('What is your password?', 'demo-password-123')
        ->expectsOutput('User Admin created successfully.')
        ->assertExitCode(0);

    $this->assertDatabaseHas('users', [
        'name' => 'Admin',
        'email' => 'admin@example.com',
    ]);
    $this->assertDatabaseCount('users', 1);
});

it('stores a password hash', function () {
    $this->artisan('make:user')
        ->expectsQuestion('What is your name?', 'Admin')
        ->expectsQuestion('What is your email?', 'admin@example.com')
        ->expectsQuestion('What is your password?', 'demo-password-123')
        ->assertExitCode(0);

    $user = User::where('email', 'admin@example.com')->firstOrFail();

    expect($user->password)->not->toBe('demo-password-123');
    expect(Hash::check('demo-password-123', $user->password))->toBeTrue();
});

it('rejects invalid input', function (string $field, string $invalid, string $error) {
    if ($invalid === 'taken@example.com') {
        User::factory()->create(['email' => $invalid]);
    }

    $command = $this->artisan('make:user');

    // Stop at the invalid field; Laravel ends invalid prompts during tests.
    foreach ([
        'name' => ['What is your name?', 'Admin'],
        'email' => ['What is your email?', 'admin@example.com'],
        'password' => ['What is your password?', 'demo-password-123'],
    ] as $key => [$question, $answer]) {
        if ($key === $field) {
            $command->expectsQuestion($question, $invalid)
                ->expectsOutputToContain($error);
            break;
        }

        $command->expectsQuestion($question, $answer);
    }

    $command->assertExitCode(1)->run();

    $this->assertDatabaseMissing('users', ['email' => 'admin@example.com']);
    $this->assertDatabaseCount('users', $invalid === 'taken@example.com' ? 1 : 0);
})->with([
    'empty name' => ['name', '', 'The name field is required.'],
    'long name' => ['name', str_repeat('a', 256), 'The name field must not be greater than 255 characters.'],
    'empty email' => ['email', '', 'The email field is required.'],
    'invalid email' => ['email', 'not-an-email', 'The email field must be a valid email address.'],
    'duplicate email' => ['email', 'taken@example.com', 'The email has already been taken.'],
    'short password' => ['password', 'short', 'The password field must be at least 8 characters.'],
]);
```

Dua test pertama memeriksa pembuatan user dan hash password. Test ketiga dijalankan untuk enam dataset, sehingga totalnya delapan kasus. Setiap input yang ditolak harus menghasilkan pesan validasi dan tidak menambah record. Pada kasus email duplikat, satu record awal harus tetap menjadi satu record.

Laravel menggunakan fallback prompt saat menjalankan test. Input tidak valid mengakhiri command dengan exit code 1 dalam mode test, sehingga pengujiannya tidak mengirim jawaban perbaikan. Pada terminal interaktif, prompt tetap meminta jawaban yang valid. Perbedaan ini menjelaskan mengapa assertion test tidak meniru seluruh interaksi koreksi input.

Trait `RefreshDatabase` mengisolasi data setiap test. Konfigurasi bawaan `phpunit.xml` menggunakan SQLite dalam memory, sehingga test tidak menghapus user yang Anda buat secara manual. Jalankan test khusus command:

```bash
php artisan test --colors=never --filter=MakeUserTest
```

```text

   PASS  Tests\Feature\MakeUserTest
  ✓ it creates a user from interactive input                             0.15s  
  ✓ it stores a password hash                                            0.01s  
  ✓ it rejects invalid input with dataset "empty name"                   0.01s  
  ✓ it rejects invalid input with dataset "long name"                    0.01s  
  ✓ it rejects invalid input with dataset "empty email"                  0.01s  
  ✓ it rejects invalid input with dataset "invalid email"                0.01s  
  ✓ it rejects invalid input with dataset "duplicate email"              0.02s  
  ✓ it rejects invalid input with dataset "short password"               0.01s  

  Tests:    8 passed (48 assertions)
  Duration: 0.28s

```

Terakhir, jalankan seluruh test project untuk memastikan test bawaan tetap lulus.

```bash
php artisan test --colors=never
```

```text

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.10s  

   PASS  Tests\Feature\MakeUserTest
  ✓ it creates a user from interactive input                             0.08s  
  ✓ it stores a password hash                                            0.01s  
  ✓ it rejects invalid input with dataset "empty name"                   0.01s  
  ✓ it rejects invalid input with dataset "long name"                    0.01s  
  ✓ it rejects invalid input with dataset "empty email"                  0.01s  
  ✓ it rejects invalid input with dataset "invalid email"                0.01s  
  ✓ it rejects invalid input with dataset "duplicate email"              0.01s  
  ✓ it rejects invalid input with dataset "short password"               0.01s  

  Tests:    10 passed (50 assertions)
  Duration: 0.31s

```

Durasi test dapat berbeda pada mesin Anda. Keluaran di atas disalin dari pengujian tutorial; delapan kasus command dan dua test bawaan semuanya lulus.

## Memahami Laravel Prompts {#understanding-laravel-prompts}

Laravel Prompts menyediakan input terminal dengan validasi dan tampilan interaktif. Dalam contoh ini, Artisan menjalankan command, Prompts mengumpulkan jawaban, dan Eloquent menyimpan user setelah jawaban valid. Pembagian ini menjaga alur mudah diikuti tanpa menambahkan controller atau route.

### Password Tersembunyi dan Hashing

Menyembunyikan input melindungi tampilan terminal, sedangkan hashing melindungi representasi password yang disimpan. Keduanya memiliki fungsi berbeda. Cast `hashed` bawaan mengenali hash yang sudah dibuat, sehingga nilai dari `Hash::make()` tidak di-hash dua kali. Pengujian dengan `Hash::check()` memastikan password contoh masih cocok dengan hash yang tersimpan.

### Validasi dan Dukungan Terminal

Validasi email unik memberikan umpan balik sebelum penyimpanan. Unique index bawaan database tetap menjadi pengaman akhir jika dua proses mencoba membuat email yang sama pada saat bersamaan. Contoh ini tidak menambahkan penanganan khusus untuk konflik penyimpanan bersamaan.

Laravel Prompts mendukung macOS, Linux, dan Windows melalui WSL. Lingkungan yang tidak mendukung tampilan tersebut dapat menggunakan fallback, sehingga tampilan prompt dapat berbeda. Pengujian otomatis memverifikasi perilaku command; pemeriksaan terminal memastikan input tersembunyi bekerja secara visual.

Untuk pendalaman, baca [Laravel Prompts](https://laravel.com/docs/13.x/prompts), [Artisan Console](https://laravel.com/docs/13.x/artisan), [Console Tests](https://laravel.com/docs/13.x/console-tests), dan [Eloquent Attribute Casting](https://laravel.com/docs/13.x/eloquent-mutators#attribute-casting).

## Kesimpulan {#conclusion}

Anda sekarang memiliki command interaktif untuk membuat user pada Laravel 13 dengan validasi dan pengujian yang dapat dijalankan ulang.

- **Laravel Installer.** SQLite dan Pest menyiapkan fondasi tutorial tanpa konfigurasi server database terpisah.
- **Laravel Prompts.** Input nama, email, dan password dipandu langsung dari terminal.
- **Validasi dan hashing.** Data diperiksa sebelum disimpan, password disembunyikan saat diketik, dan hanya hash yang disimpan.
- **Pest.** Delapan kasus menguji pembuatan user, hashing, serta penolakan input yang tidak valid.

