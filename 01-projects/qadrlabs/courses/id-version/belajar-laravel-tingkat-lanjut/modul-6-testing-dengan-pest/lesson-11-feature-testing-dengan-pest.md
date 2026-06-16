## 1. Sebelum Anda Memulai

Setiap kali Anda menambahkan sebuah fitur, Anda memperkenalkan kemungkinan merusak sesuatu yang lain. Tanpa test, Anda harus mengeklik aplikasi secara manual untuk memverifikasi tidak ada yang mengalami regresi. Dengan test, satu perintah memverifikasi seluruh aplikasi dalam hitungan detik. Feature test menyimulasikan HTTP request dan memeriksa respons, berperilaku seperti seorang user yang sangat cepat dan sangat sabar yang tidak pernah bosan mengeklik setiap link.

Lesson ini mengajarkan Anda menulis feature test untuk Catatku menggunakan Pest, sebuah framework testing PHP modern yang ramah dan mudah dibaca. Pest dibangun di atas PHPUnit (test runner PHP tradisional), tetapi memiliki sintaks yang lebih bersih yang terinspirasi oleh Jest dari JavaScript. Anda akan menulis test yang membuat user, membuat HTTP request, dan menegaskan bahwa respons berisi apa yang Anda harapkan. Test berjalan di database test yang terisolasi sehingga mereka tidak mencemari data development Anda.

### What You'll Build

Anda akan menginstal Pest, mengonfigurasi sebuah database test menggunakan SQLite in-memory, dan menulis feature test untuk alur CRUD entri: guest diarahkan, user yang terautentikasi dapat membuat entri, hanya pemilik yang dapat mengedit entri mereka sendiri, dan notifikasi komentar di-dispatch.

### What You'll Learn

- ✅ Menginstal Pest
- ✅ Trait `RefreshDatabase`
- ✅ Menulis feature test dengan `it()`, `test()`, `expect()`
- ✅ Assertion HTTP: `get()`, `post()`, `assertStatus()`, `assertSee()`
- ✅ Melakukan authentication di test dengan `actingAs()`
- ✅ Menggunakan factory untuk membuat data test
- ✅ Menjalankan test dengan `php artisan test`

### What You'll Need

- Lesson 10 sudah selesai

---

## 2. Menginstal Pest

Aplikasi Catatku disiapkan dengan PHPUnit, test runner default Laravel. Sebelum menginstal Pest, Anda perlu menghapus PHPUnit untuk menghindari konflik dependensi. Anda kemudian akan menginstal dua package: `pestphp/pest` (framework test inti) dan `pestphp/pest-plugin-laravel` (integrasi Laravel yang menyediakan helper test seperti `actingAs()`, `get()`, dan `post()` di dalam fungsi test Pest).

### Step 1: Menghapus PHPUnit

Jalankan perintah berikut untuk meng-uninstall PHPUnit dari proyek.

```bash
composer remove phpunit/phpunit
```

Menghapus PHPUnit sebelum menginstal Pest mencegah konflik versi antara kedua framework, karena Pest dibangun di atas PHPUnit secara internal tetapi mengelola versinya sendiri yang kompatibel.

### Step 2: Menginstal Package Pest

Jalankan perintah berikut untuk menginstal Pest dan plugin Laravel bersama-sama.

```bash
composer require pestphp/pest pestphp/pest-plugin-laravel --dev --with-all-dependencies
```

Flag `--dev` menandai kedua package sebagai dependensi yang hanya untuk development. Flag `--with-all-dependencies` meresolusi versi yang kompatibel untuk semua dependensi transitif sekaligus. Package `pestphp/pest-plugin-laravel` diperlukan untuk helper spesifik Laravel: tanpanya, memanggil `actingAs()`, `get()`, atau `post()` di dalam sebuah fungsi test akan melemparkan fatal error yang menyatakan fungsi tidak terdefinisi.

### Step 3: Menginisialisasi Pest

Jalankan perintah berikut untuk menyelesaikan setup Pest.

```bash
./vendor/bin/pest --init
```

Perintah ini membuat `tests/Pest.php`, yaitu file konfigurasi global tempat Anda dapat mendefinisikan helper bersama, dataset provider, dan pemanggilan `uses()` yang berlaku untuk semua file test. Ia juga memperbarui `phpunit.xml` untuk mendaftarkan Pest sebagai test runner.

### Step 4: Memverifikasi Instalasi

Jalankan test suite untuk mengonfirmasi Pest bekerja dengan benar.

```bash
php artisan test
```

Anda akan melihat output Pest dengan indikator pass/fail berwarna. Jika sebuah test contoh default ada di `tests/Feature/ExampleTest.php`, ia seharusnya lulus. Jika Anda melihat kegagalan merah, pesan error biasanya menunjuk langsung ke apa yang perlu dikonfigurasi.

---

## 3. Mengonfigurasi Database Test

Test seharusnya berjalan terhadap database terpisah sehingga mereka tidak memengaruhi data development Anda. Pendekatan tercepat adalah SQLite in-memory, yang membuat database baru per test run sepenuhnya di RAM. Ini menjaga test suite tetap cepat (tanpa disk I/O) dan menjamin isolasi antar run.

### Step 1: Mengedit phpunit.xml

Buka `phpunit.xml` dan perbarui bagian `<php>` untuk mengonfigurasi semua variabel environment khusus test.

```xml
<php>
    <env name="APP_ENV" value="testing"/>
    <env name="DB_CONNECTION" value="sqlite"/>
    <env name="DB_DATABASE" value=":memory:"/>
    <env name="MAIL_MAILER" value="array"/>
    <env name="QUEUE_CONNECTION" value="sync"/>
    <env name="SESSION_DRIVER" value="array"/>
    <env name="CACHE_STORE" value="array"/>
</php>
```

Masing-masing variabel environment ini memiliki tujuan spesifik di lingkungan test. `APP_ENV=testing` mengganti Laravel ke mode testing, yang menonaktifkan pemeriksaan keamanan tertentu dan mengaktifkan perilaku khusus test. `DB_CONNECTION=sqlite` dengan `DB_DATABASE=:memory:` menggunakan database SQLite in-memory yang hanya ada selama test run; tidak ada file yang ditulis dan tidak ada yang bertahan antar run. `MAIL_MAILER=array` menangkap email yang dikirim di memori alih-alih benar-benar mengirimkannya, sehingga Anda dapat menegaskan bahwa sebuah email tertentu di-dispatch tanpa menghubungi server mail eksternal. `QUEUE_CONNECTION=sync` memproses queued job seketika alih-alih menundanya ke worker background. `SESSION_DRIVER=array` dan `CACHE_STORE=array` menggunakan penyimpanan berbasis memori untuk alasan yang sama. Nilai-nilai ini menimpa pengaturan di `.env`, tetapi hanya saat menjalankan test.

---

## 4. Menulis Feature Test Pertama Anda

Feature test mencakup seluruh siklus HTTP request: request masuk, respons keluar. Anda akan menulis test yang mencakup alur entri utama, termasuk redirect guest, akses terautentikasi, penegakan authorization, soft delete, dan validasi. Setiap test adalah satu skenario tunggal yang seharusnya lulus atau gagal secara independen dari yang lain.

### Step 1: Membuat File Test

Jalankan perintah berikut untuk membuat file feature test.

```bash
php artisan make:test EntryTest
```

Perintah ini membuat `tests/Feature/EntryTest.php`. Secara default ia menggunakan gaya class PHPUnit; kita akan menulisnya ulang dalam gaya fungsional Pest, yang lebih bersih dan lebih mudah dibaca.

### Step 2: Menulis Test

Buka `tests/Feature/EntryTest.php` dan ganti kontennya dengan berikut.

```php
<?php

use App\Models\Entry;
use App\Models\User;

use function Pest\Laravel\{actingAs, get, post, put, delete};

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

test('guest is redirected from entries index to login', function () {
    get('/entries')->assertRedirect('/login');
});

test('authenticated user can view entries index', function () {
    $user = User::factory()->create();

    actingAs($user)->get('/entries')
        ->assertStatus(200)
        ->assertSee('Entries');
});

test('authenticated user can create an entry', function () {
    $user = User::factory()->create();

    actingAs($user)->post('/entries', [
        'title' => 'Test Entry',
        'content' => 'This is a test entry.',
    ])->assertRedirect(route('entries.index'));

    expect(Entry::count())->toBe(1);
    expect(Entry::first())
        ->title->toBe('Test Entry')
        ->user_id->toBe($user->id);
});

test('user cannot edit another user entry', function () {
    $userA = User::factory()->create();
    $userB = User::factory()->create();
    $entry = Entry::factory()->for($userA)->create();

    actingAs($userB)->get(route('entries.edit', $entry))
        ->assertStatus(403);
});

test('user can delete their own entry', function () {
    $user = User::factory()->create();
    $entry = Entry::factory()->for($user)->create();

    actingAs($user)->delete(route('entries.destroy', $entry))
        ->assertRedirect(route('entries.index'));

    expect($entry->fresh()->trashed())->toBeTrue();
});

test('validation fails on empty title', function () {
    $user = User::factory()->create();

    actingAs($user)->post('/entries', ['content' => 'No title'])
        ->assertSessionHasErrors('title');
});
```

Mari kita telusuri setiap bagian dari file test ini secara perlahan, karena ada banyak fungsionalitas yang dikemas dalam sejumlah kecil kode. Di bagian atas, statement `use` mengimpor model yang akan kita gunakan dan mengimpor fungsi helper HTTP Pest (`actingAs`, `get`, `post`, dll.) sebagai named function import dari namespace `Pest\Laravel`. Pemanggilan `uses(\Illuminate\Foundation\Testing\RefreshDatabase::class)` menerapkan trait `RefreshDatabase` ke setiap test di file ini, yang menghapus database dan menjalankan ulang migration sebelum setiap test untuk menjamin isolasi. Tanpa ini, test dapat mencemari satu sama lain berdasarkan urutan eksekusi.

Test pertama memverifikasi akses yang tidak terautentikasi. `get('/entries')` menyimulasikan sebuah HTTP GET request, dan `assertRedirect('/login')` menegaskan respons adalah sebuah redirect ke halaman login. Tidak ada browser yang berjalan; Laravel men-dispatch request secara internal melalui sistem routing-nya, yang itulah yang membuat test cepat. Test kedua membuat sebuah user dengan `User::factory()->create()` (yang menggunakan factory untuk menghasilkan data palsu), memanggil `actingAs($user)` untuk melakukan authentication sebagai user tersebut, dan merantai `->get('/entries')` untuk HTTP request. Assertion mengonfirmasi respons OK dan berisi teks yang diharapkan.

Test ketiga (pembuatan entri) mengirim sebuah POST request dengan data form dan mengharapkan sebuah redirect saat sukses. Setelah request, kita menggunakan `expect()` untuk membuat assertion bergaya Pest tentang kondisi database: persis satu entri seharusnya ada, dan title serta `user_id`-nya seharusnya cocok. Sintaks berantai `->title->toBe(...)` adalah akses property fluent Pest yang terbaca secara natural.

Test keempat membuktikan bahwa policy dari Lesson 5 bekerja: User B yang mencoba mengedit entri User A mendapatkan 403 Forbidden. Helper `->for($userA)` pada factory mengatur relationship ownership secara otomatis. Test kelima memverifikasi soft delete dari Lesson 4: setelah penghapusan, entri seharusnya ter-trash. Test keenam memverifikasi validasi: mengirim tanpa title seharusnya menampilkan error, yang diperiksa `assertSessionHasErrors('title')`.

### Step 3: Membuat Entry Factory

Test mereferensikan `Entry::factory()`, tetapi factory hanya ada jika Anda membuatnya.

```bash
php artisan make:factory EntryFactory --model=Entry
```

Buka `database/factories/EntryFactory.php` dan definisikan data default-nya.

```php
<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class EntryFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'title' => fake()->sentence(6),
            'content' => fake()->paragraphs(3, true),
        ];
    }
}
```

Memeriksa factory: method `definition()` mengembalikan sebuah array berisi nilai kolom default untuk entri baru. `User::factory()` adalah referensi factory bersarang: jika Anda membuat sebuah Entry tanpa menentukan user, sebuah user baru dihasilkan secara otomatis dan ID-nya digunakan. Helper `fake()` mengembalikan sebuah instance `Faker` yang menghasilkan data test yang realistis: `sentence(6)` menghasilkan sesuatu seperti "The quick brown fox jumps over", dan `paragraphs(3, true)` menghasilkan tiga paragraf lorem ipsum sebagai satu string yang digabungkan. Menggunakan data yang dihasilkan membuat test lebih tidak rapuh daripada string hardcode karena setiap run menggunakan nilai yang sedikit berbeda.

Anda juga perlu menambahkan trait `HasFactory` ke model Entry jika belum ada. Buka `app/Models/Entry.php` dan pastikan trait disertakan.

```php
<?php
// ... others lines of code
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Entry extends Model
{
    use HasFactory, SoftDeletes;

    // ... other methods and properties
}
```

Trait `HasFactory` menambahkan method statis `factory()` ke model, yang mengembalikan sebuah instance `EntryFactory` yang siap membangun entri dengan method berantai seperti `->for($user)` dan `->create()`.

---

## 5. Menjalankan Test

Pest menyediakan beberapa cara untuk menjalankan test tergantung pada seberapa banyak feedback yang Anda butuhkan. Menjalankan suite penuh setelah setiap perubahan itu lambat; memfilter ke file atau nama test tertentu memberi Anda iterasi yang lebih cepat saat Anda memperbaiki sebuah kegagalan.

### Step 1: Menjalankan Semua Test

Jalankan perintah berikut untuk mengeksekusi test suite penuh.

```bash
php artisan test
```

Anda akan melihat output mirip dengan berikut.

```
  PASS  Tests\Feature\EntryTest
  ✓ guest is redirected from entries index to login
  ✓ authenticated user can view entries index
  ✓ authenticated user can create an entry
  ✓ user cannot edit another user entry
  ✓ user can delete their own entry
  ✓ validation fails on empty title

  Tests:    6 passed (12 assertions)
  Duration: 0.45s
```

Pest menampilkan centang hijau untuk setiap test yang lulus dan X merah untuk kegagalan, beserta alasan kegagalan yang biasanya menunjuk langsung ke masalahnya. Jumlah assertion mencerminkan bahwa satu test dapat membuat beberapa assertion.

### Step 2: Menjalankan Satu File Test

Untuk menjalankan hanya test di file tertentu, teruskan nama class-nya ke flag `--filter`.

```bash
php artisan test --filter=EntryTest
```

Flag `--filter` memungkinkan Anda fokus pada satu file atau satu test tertentu berdasarkan nama. Ini berguna ketika Anda memperbaiki satu test yang gagal dan tidak ingin menunggu seluruh suite.

### Step 3: Menjalankan Satu Test

Untuk menjalankan satu test berdasarkan nama, teruskan string deskripsi test yang persis ke `--filter`.

```bash
php artisan test --filter="user can delete their own entry"
```

Meneruskan nama test yang persis ke `--filter` menjalankan hanya test tersebut, yang merupakan loop feedback tercepat saat melakukan iterasi pada sebuah kegagalan tertentu.

### Step 4: Men-debug Test yang Gagal

Jika sebuah test gagal, Pest menampilkan kegagalan dengan pesan yang membantu. Status respons 500 berarti sebuah exception terjadi di controller. Periksa `storage/logs/laravel.log` untuk detail exception, atau tambahkan `->dumpSession()` di dalam rantai test untuk memeriksa data session (yang sering mengungkap error validasi atau petunjuk lain) pada titik di mana assertion gagal.

---

## 6. Memperbaiki Error pada Kode Anda

Berikut adalah kesalahan paling umum saat menulis feature test dengan Pest dan Laravel.

**Error 1: Lupa trait `RefreshDatabase`, menyebabkan test berbagi kondisi database.**

Error ini terjadi ketika test menulis ke database tetapi trait `RefreshDatabase` tidak diterapkan. Setiap test meninggalkan datanya, dan test berikutnya melihatnya. Assertion tentang jumlah record menjadi tidak andal karena jumlahnya bergantung pada test mana yang berjalan sebelumnya.

```php
// Wrong: no database reset, tests contaminate each other
uses(); // RefreshDatabase not included

test('can create entry', function () {
    $user = User::factory()->create();
    actingAs($user)->post('/entries', ['title' => 'A', 'content' => 'B']);
    expect(Entry::count())->toBe(1); // Passes only if no previous tests created entries
});

// Correct: RefreshDatabase resets the database before each test
uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

test('can create entry', function () {
    $user = User::factory()->create();
    actingAs($user)->post('/entries', ['title' => 'A', 'content' => 'B']);
    expect(Entry::count())->toBe(1); // Always correct because database is clean
});
```

Tanpa `RefreshDatabase`, sebuah test yang menegaskan `Entry::count() === 1` akan gagal jika test sebelumnya sudah membuat entri. Dengan `RefreshDatabase`, setiap test dimulai dengan database yang benar-benar kosong, sehingga assertion jumlah menjadi andal dan urutan eksekusi test tidak penting.

---

**Error 2: Tidak memanggil `actingAs()` sebelum mengenai route yang dilindungi.**

Error ini terjadi ketika Anda menguji sebuah route yang dilindungi (yang berada di belakang middleware `auth`) tanpa melakukan authentication terlebih dahulu. Middleware `auth` mengarahkan request yang tidak terautentikasi ke halaman login dengan respons 302, menyebabkan assertion yang mengharapkan 200 gagal.

```php
// Wrong: no authentication, auth middleware redirects to /login
test('can view entries', function () {
    get('/entries')->assertStatus(200); // Fails! Receives 302 redirect
});

// Correct: authenticate as a user before accessing protected routes
test('can view entries', function () {
    $user = User::factory()->create();
    actingAs($user)->get('/entries')->assertStatus(200);
});
```

Versi yang salah membuat pemanggilan `get('/entries')` polos tanpa user yang terautentikasi. Karena route entri memerlukan authentication, middleware mengembalikan sebuah redirect 302 dan assertion `assertStatus(200)` gagal. Versi yang benar membuat sebuah user sungguhan dengan factory dan meneruskannya ke `actingAs()`, yang melakukan authentication pada request tanpa melalui form login.

---

**Error 3: Menegaskan pada model in-memory yang basi setelah sebuah HTTP request memodifikasi database.**

Error ini terjadi ketika Anda menangkap sebuah variabel model sebelum membuat sebuah request, lalu menegaskan padanya setelahnya. Variabel menyimpan kondisi in-memory dari sebelum request, bukan kondisi database saat ini.

```php
// Wrong: $entry is the in-memory copy, it was not refreshed after the delete request
test('entry is deleted', function () {
    $user = User::factory()->create();
    $entry = Entry::factory()->for($user)->create();

    actingAs($user)->delete(route('entries.destroy', $entry));

    expect($entry->trashed())->toBeTrue(); // Fails! $entry still has deleted_at = null
});

// Correct: call fresh() to reload the model from the database after the request
test('entry is deleted', function () {
    $user = User::factory()->create();
    $entry = Entry::factory()->for($user)->create();

    actingAs($user)->delete(route('entries.destroy', $entry));

    expect($entry->fresh()->trashed())->toBeTrue(); // Passes! fresh() reloads from DB
});
```

Versi yang salah menegaskan `$entry->trashed()` pada objek asli, yang masih memiliki `deleted_at = null` di memori karena penghapusan terjadi di dalam HTTP request (bukan langsung pada variabel ini). Versi yang benar memanggil `$entry->fresh()`, yang mengeksekusi sebuah query `SELECT` baru dan mengembalikan sebuah instance model baru yang mencerminkan baris database saat ini, di mana `deleted_at` sekarang sudah diatur.

---

## 7. Latihan

Tulis setiap test secara independen, menggunakan pola dari lesson ini. Setiap test seharusnya mandiri: membuat user, entri, dan data lain apa pun yang dibutuhkannya sendiri, dan tidak membuat asumsi tentang apa yang ditinggalkan test lain di database.

**Latihan 1:** Tulis sebuah test yang memverifikasi komentar dapat dikirim: buat sebuah user, buat sebuah entri, bertindak sebagai user, POST ke `/entries/{id}/comments`, dan tegaskan komentar dibuat di database.

**Latihan 2:** Tulis sebuah test yang memverifikasi daftar entri menampilkan entri dari user yang terautentikasi tetapi tidak dari yang lain. Buat dua user, masing-masing dengan satu entri, lalu bertindak sebagai satu user dan periksa bahwa hanya entri mereka yang muncul di respons.

**Latihan 3:** Tulis sebuah test yang memverifikasi sebuah email dikirim ketika sebuah komentar diposting. Gunakan `Mail::fake()` di awal, lakukan aksi komentar, lalu gunakan `Mail::assertSent(NewCommentEmail::class)` untuk memverifikasi.

---

## 8. Solusi

Setiap solusi menambahkan sebuah fungsi test baru ke `tests/Feature/EntryTest.php`. Semua test di file itu sudah memiliki `RefreshDatabase` yang diterapkan melalui `uses()`, sehingga masing-masing dimulai dengan database yang bersih secara otomatis.

**Solusi untuk Latihan 1:**

Tambahkan test berikut ke `tests/Feature/EntryTest.php`.

```php
test('authenticated user can post a comment', function () {
    $author = User::factory()->create();
    $commenter = User::factory()->create();
    $entry = Entry::factory()->for($author)->create();

    actingAs($commenter)->post("/entries/{$entry->id}/comments", [
        'body' => 'Great entry!',
    ])->assertRedirect();

    expect(\App\Models\Comment::count())->toBe(1);
    expect(\App\Models\Comment::first())
        ->body->toBe('Great entry!')
        ->user_id->toBe($commenter->id)
        ->entry_id->toBe($entry->id);
});
```

Test membuat dua user sehingga komentar diposting oleh seseorang selain penulis entri, yang merupakan skenario realistis. `assertRedirect()` memverifikasi bahwa controller mengembalikan sebuah redirect (redirect `back()` dari Lesson 1) tanpa memeriksa tujuan spesifiknya. Tiga assertion `expect()` kemudian mengonfirmasi record database dibuat dengan body, pemilik, dan asosiasi entri yang benar. Sintaks property berantai Pest (`->body->toBe(...)`) membaca attribute model secara langsung, membuat assertion menjadi jelas dan ringkas.

---

**Solusi untuk Latihan 2:**

Tambahkan test berikut ke `tests/Feature/EntryTest.php`.

```php
test('entry index shows only the authenticated users own entries', function () {
    $userA = User::factory()->create();
    $userB = User::factory()->create();

    Entry::factory()->for($userA)->create(['title' => 'User A Entry']);
    Entry::factory()->for($userB)->create(['title' => 'User B Entry']);

    actingAs($userA)->get('/entries')
        ->assertStatus(200)
        ->assertSee('User A Entry')
        ->assertDontSee('User B Entry');
});
```

Test membuat dua entri dengan title yang berbeda dan dapat dikenali. Setelah melakukan authentication sebagai User A, respons seharusnya berisi "User A Entry" tetapi tidak "User B Entry". `assertSee()` mencari body respons penuh untuk string yang diberikan dan gagal jika ia absen. `assertDontSee()` adalah kebalikannya: ia gagal jika string ditemukan. Test ini membuktikan bahwa scope `auth()->user()->entries()` dari controller memfilter dengan benar, karena jika ia menggunakan `Entry::all()` sebagai gantinya, kedua title akan muncul di respons.

---

**Solusi untuk Latihan 3:**

Tambahkan test berikut ke `tests/Feature/EntryTest.php`.

```php
use App\Mail\NewCommentEmail;
use Illuminate\Support\Facades\Mail;

test('email sent when comment is posted on another users entry', function () {
    Mail::fake();

    $author = User::factory()->create();
    $commenter = User::factory()->create();
    $entry = Entry::factory()->for($author)->create();

    actingAs($commenter)->post("/entries/{$entry->id}/comments", [
        'body' => 'Nice entry!',
    ]);

    Mail::assertSent(NewCommentEmail::class, function ($mail) use ($author) {
        return $mail->hasTo($author->email);
    });
});
```

`Mail::fake()` mencegat semua pengiriman mail selama durasi test ini, mencegah email sungguhan keluar dan menjaga test tetap mandiri. Setelah POST komentar, `Mail::assertSent(NewCommentEmail::class, ...)` memverifikasi bahwa setidaknya satu `NewCommentEmail` di-dispatch. Closure menerima instance Mailable dan harus mengembalikan true agar assertion lulus; di sini kita memverifikasi alamat `to` cocok dengan email penulis entri. Jika notifikasi komentar hilang dari controller atau guard self-comment terpicu dengan salah, assertion ini akan gagal dan memberi tahu Anda email mana yang dikirim (atau tidak dikirim).

---

## Selanjutnya - Lesson 12

Di lesson ini Anda menyiapkan sebuah feature test suite lengkap untuk Catatku menggunakan Pest. Anda mengonfigurasi SQLite in-memory untuk test run yang cepat dan terisolasi dan menerapkan `RefreshDatabase` untuk menjamin setiap test dimulai dengan kondisi yang bersih. Anda menggunakan `User::factory()->create()` dan `Entry::factory()->for($user)->create()` untuk membangun data test yang realistis tanpa SQL manual, dan `actingAs($user)` untuk melakukan authentication request tanpa melalui form login. Anda menguji authorization (403 untuk akses tidak sah), soft delete (memeriksa `trashed()` setelah penghapusan), validasi (menegaskan pada error session), dan dispatch email (menggunakan `Mail::fake()` dan `Mail::assertSent`).

Di Lesson 12, Anda akan mempelajari unit testing: bagaimana menguji method, accessor, mutator, dan scope individual secara terisolasi tanpa HTTP, routing, atau view, menggunakan helper `dataset()` dari Pest untuk menguji beberapa input dalam satu test.
