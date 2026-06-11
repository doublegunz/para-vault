Selama beberapa lesson terakhir, kita telah membangun banyak hal di atas asumsi bahwa pengguna sudah login, berkat route `/dev-login` yang kita buat sebagai jalan pintas sementara. Itu cukup untuk mengembangkan fitur CRUD tanpa terhambat oleh sistem autentikasi yang belum ada. Namun jalan pintas itu tidak bisa bertahan selamanya, dan lesson ini adalah saat kita menggantinya dengan yang sesungguhnya.

## Overview {#overview}

### Apa yang Akan Anda Bangun

Pada akhir lesson ini, route `/dev-login` dapat dihapus secara permanen. Pengguna akan dapat mendaftar dengan akun sungguhan, otomatis login setelah registrasi, dan seluruh alur yang telah kita bangun sejak Lesson 7 akhirnya dapat diuji dengan cara yang benar.

### Apa yang Akan Anda Pelajari

- Apa itu authentication dan mengapa Catatku membutuhkannya
- Cara membuat `AuthController` khusus untuk menangani registrasi
- Cara memvalidasi input registrasi dengan rule seperti `unique`, `confirmed`, dan `min`
- Mengapa password harus di-hash sebelum disimpan dan bagaimana `Hash::make()` bekerja
- Bagaimana `Auth::login()` membuat session untuk pengguna yang baru saja mendaftar
- Bagaimana `middleware('guest')` membatasi halaman hanya untuk pengunjung yang belum login
- Bagaimana field `password_confirmation` bekerja dengan validation rule `confirmed`

### Apa yang Anda Butuhkan

- Project `catatku` terbuka di VS Code dengan development server berjalan
- Semua perubahan dari lesson sebelumnya sudah disimpan dan berfungsi
- Route `/dev-login` sementara masih ada (kita akan menghapusnya di akhir lesson ini)

---

## Step 1: Membuat AuthController {#step-1-create-the-authcontroller}

Logika authentication tidak seharusnya berada di `EntryController`. Entries dan akun pengguna adalah dua hal yang berbeda, sehingga keduanya mendapatkan controller terpisah. Jalankan perintah berikut untuk membuat controller baru:

```bash
php artisan make:controller AuthController
```
Output:
```
$ php artisan make:controller AuthController

   INFO  Controller [app/Http/Controllers/AuthController.php] created successfully.
```

Buka `app/Http/Controllers/AuthController.php` dan tambahkan method registrasi:

```php
<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function showRegister()
    {
        return view('auth.register');
    }

    public function register(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'name'     => $validated['name'],
            'email'    => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        Auth::login($user);

        return redirect('/entries')
            ->with('success', 'Welcome to Catatku, ' . $user->name . '!');
    }
}
```

Controller ini memiliki dua method yang mengikuti pola form dua langkah yang sama seperti yang kita gunakan untuk membuat entries: satu method GET untuk menampilkan form dan satu method POST untuk memproses submission. Mari kita telusuri method `register()` langkah demi langkah.

### Validation Rules {#validation-rules}

```php
$validated = $request->validate([
    'name'     => 'required|string|max:255',
    'email'    => 'required|email|unique:users,email',
    'password' => 'required|string|min:8|confirmed',
]);
```

Sebagian besar rule ini sudah familiar dari lesson sebelumnya. Yang baru adalah:

`email` memastikan nilai memiliki format email yang valid (mengandung simbol `@` dan nama domain).

`unique:users,email` memeriksa database untuk memverifikasi bahwa email ini belum digunakan oleh pengguna lain. Formatnya adalah `unique:table_name,column_name`. Jika seseorang mencoba mendaftar dengan email yang sudah ada, validasi akan gagal dengan pesan error yang jelas.

`min:8` mengharuskan password memiliki panjang minimal 8 karakter. Password yang pendek mudah ditebak atau di-brute-force, sehingga menerapkan panjang minimum adalah langkah keamanan dasar.

`confirmed` adalah rule khusus yang mengharuskan adanya field konfirmasi yang cocok. Ketika Anda menambahkan `confirmed` pada field `password`, Laravel secara otomatis mencari field bernama `password_confirmation` pada data form. Jika kedua nilai tidak cocok, validasi gagal. Ini mencegah pengguna salah ketik password secara tidak sengaja saat registrasi, yang dapat membuat mereka terkunci dari akun mereka sendiri.

### Password Hashing {#password-hashing}

```php
'password' => Hash::make($validated['password']),
```

Password **tidak boleh** disimpan sebagai teks biasa. Jika database pernah diretas, password setiap pengguna akan langsung terekspos. `Hash::make()` mengubah password menjadi hash yang tidak dapat dikembalikan ke bentuk semula:

```
Input:   "secret123"
Output:  "$2y$12$LkIKjbPXRGkpVBz..."
```

Setiap kali Anda meng-hash password yang sama, hasilnya akan berbeda karena `Hash::make()` menambahkan salt acak. Namun Laravel tetap dapat memverifikasi password terhadap hash-nya menggunakan `Hash::check('secret123', $hashedValue)`. Sifat satu arah ini adalah inti dari keamanan password: Anda dapat memverifikasi tanpa pernah menyimpan atau mengungkapkan nilai aslinya.

### Automatic Login {#automatic-login}

```php
Auth::login($user);
```

Setelah pengguna berhasil dibuat, kita langsung login-kan mereka tanpa perlu mengunjungi halaman login dan memasukkan kredensial lagi. Ini menciptakan pengalaman pengguna yang lebih baik. Method `Auth::login()` membuat session untuk pengguna, dan mulai dari titik ini, `auth()->user()` akan mengembalikan objek pengguna ini di semua request berikutnya.

---

## Step 2: Menambahkan Route Registrasi {#step-2-add-the-registration-routes}

Perbarui `routes/web.php` dengan route registrasi dan hapus jalan pintas `/dev-login`:

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EntryController;
use App\Http\Controllers\AuthController; // [ ... Add this line of code ... ]

Route::get('/', function () {
    return view('home');
});

// Add a route for the registration feature
Route::middleware('guest')->group(function () {
    Route::get('/register', [AuthController::class, 'showRegister']);
    Route::post('/register', [AuthController::class, 'register']);
});

Route::get('/entries', [EntryController::class, 'index']);

Route::middleware('auth')->group(function () {
    Route::get('/entries/create', [EntryController::class, 'create']);
    Route::post('/entries', [EntryController::class, 'store']);
    Route::get('/entries/{entry}', [EntryController::class, 'show']);
    Route::get('/entries/{entry}/edit', [EntryController::class, 'edit']);
    Route::put('/entries/{entry}', [EntryController::class, 'update']);
    Route::delete('/entries/{entry}', [EntryController::class, 'destroy']);
});
```

Perhatikan bahwa route `/dev-login` sudah hilang. Kita tidak membutuhkannya lagi.

Route registrasi dibungkus dengan `middleware('guest')`. Middleware ini adalah kebalikan dari `middleware('auth')`: hanya mengizinkan pengunjung yang belum login. Jika pengguna yang sudah login mencoba mengakses `/register`, mereka akan dialihkan ke halaman home secara otomatis. Tidak ada alasan bagi pengguna yang sudah login untuk melihat form registrasi.

Sekarang kita memiliki dua kelompok middleware di file route. Kelompok `guest` berisi halaman yang hanya boleh dilihat oleh pengunjung yang belum login (registrasi, dan segera, login). Kelompok `auth` berisi halaman yang membutuhkan autentikasi (semua hal yang membuat, mengubah, atau menghapus entries). Dan beberapa route, seperti `/entries` (daftar entries) dan `/` (halaman home), berada di luar kedua kelompok karena dapat diakses oleh siapa saja.

---

## Step 3: Memverifikasi User Model {#step-3-verify-the-user-model}

Sebelum menguji registrasi, mari pastikan `User` model sudah dikonfigurasi untuk menerima field yang kita kirimkan. Buka `app/Models/User.php`. Di Laravel 13, User model default sudah menggunakan attribute `#[Fillable]`:

```php
#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    // ...
}
```

Attribute `#[Fillable]` mendaftarkan `name`, `email`, dan `password` sebagai field yang dapat di-mass-assign. Ini cocok persis dengan apa yang dikirimkan method `register()` kita ke `User::create()`. Attribute `#[Hidden]` memastikan bahwa `password` dan `remember_token` dikecualikan ketika model di-serialize ke JSON, mencegah data sensitif bocor secara tidak sengaja dalam respons API.

Jika User model Anda masih menggunakan sintaks lama `protected $fillable`, kedua pendekatan tetap berfungsi. Namun attribute `#[Fillable]` adalah standar di Laravel 13, seperti yang kita bahas di Lesson 6.

---

## Step 4: Membuat View Registrasi {#step-4-create-the-registration-view}

Buat folder `resources/views/auth/` dan file `resources/views/auth/register.blade.php`:

```html
<x-layout title="Register — Catatku">

    <div class="max-w-sm mx-auto">

        <div class="text-center mb-8">
            <p class="text-4xl mb-2">📓</p>
            <h1 class="text-2xl font-bold text-gray-900">Join Catatku</h1>
            <p class="text-sm text-gray-500 mt-1">
                Your personal journal space
            </p>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 p-6">
            <form method="POST" action="/register">
                @csrf

                {{-- Name --}}
                <div class="mb-4">
                    <label for="name"
                           class="block text-sm font-medium text-gray-700 mb-1">
                        Name
                    </label>
                    <input
                        type="text"
                        id="name"
                        name="name"
                        value="{{ old('name') }}"
                        placeholder="Your full name"
                        class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                               focus:ring-2 focus:ring-gray-900 focus:border-transparent
                               {{ $errors->has('name') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                        autofocus
                    >
                    @error('name')
                        <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Email --}}
                <div class="mb-4">
                    <label for="email"
                           class="block text-sm font-medium text-gray-700 mb-1">
                        Email
                    </label>
                    <input
                        type="email"
                        id="email"
                        name="email"
                        value="{{ old('email') }}"
                        placeholder="name@email.com"
                        class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                               focus:ring-2 focus:ring-gray-900 focus:border-transparent
                               {{ $errors->has('email') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                    >
                    @error('email')
                        <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Password --}}
                <div class="mb-4">
                    <label for="password"
                           class="block text-sm font-medium text-gray-700 mb-1">
                        Password
                    </label>
                    <input
                        type="password"
                        id="password"
                        name="password"
                        placeholder="At least 8 characters"
                        class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                               focus:ring-2 focus:ring-gray-900 focus:border-transparent
                               {{ $errors->has('password') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                    >
                    @error('password')
                        <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Confirm Password --}}
                <div class="mb-6">
                    <label for="password_confirmation"
                           class="block text-sm font-medium text-gray-700 mb-1">
                        Confirm Password
                    </label>
                    <input
                        type="password"
                        id="password_confirmation"
                        name="password_confirmation"
                        placeholder="Re-enter your password"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm
                               focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent"
                    >
                </div>

                <button type="submit"
                    class="w-full bg-gray-900 text-white py-2.5 rounded-lg text-sm font-medium
                           hover:bg-gray-700 transition-colors">
                    Create Account
                </button>

            </form>
        </div>

        <p class="text-center text-sm text-gray-500 mt-4">
            Already have an account?
            <a href="/login" class="text-gray-900 font-medium hover:underline">
                Log in here
            </a>
        </p>

    </div>

</x-layout>
```

Form ini mengikuti pola yang sama seperti yang sudah kita gunakan: `@csrf` untuk perlindungan CSRF, `old()` untuk mempertahankan input setelah validasi gagal, `@error` untuk menampilkan pesan error spesifik per field, dan kelas CSS kondisional untuk indikator visual error.

Ada dua hal yang perlu diperhatikan tentang field password. Pertama, input `password` tidak menggunakan `old()`. Ini disengaja. Untuk alasan keamanan, Anda tidak boleh pernah mengirim kembali nilai password ke browser, bahkan setelah validasi gagal. Pengguna harus mengetik ulang password mereka, yang merupakan ketidaknyamanan kecil tetapi merupakan praktik keamanan yang penting.

Kedua, field `password_confirmation` memiliki nama persis `password_confirmation`. Konvensi penamaan ini diwajibkan oleh validation rule `confirmed`. Ketika Laravel melihat `confirmed` pada field `password`, ia mencari field pendamping bernama `{fieldname}_confirmation`. Jika Anda menamainya dengan nama lain, validasi tidak akan berfungsi.

---

## Step 5: Menguji Alur Registrasi {#step-5-test-the-registration-flow}
Pada step ini, kita akan menguji fitur registrasi. Jika kita sudah login, kita dapat menggunakan browser yang berbeda untuk menguji fitur registrasi ini.

Pastikan development server berjalan, lalu uji skenario berikut:

1. Buka `http://127.0.0.1:8000/register`. Anda akan melihat form registrasi dengan field untuk name, email, password, dan password confirmation.
![access register page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/16-access-register-page.webp)

2. Coba submit form dengan semua field kosong. Anda akan diarahkan kembali ke form dengan input berbingkai merah dan pesan error di bawah setiap field yang wajib diisi.
![validation test -- all empty](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/17-register-validation-test-all-empty.webp)

3. Isi name dan email, tetapi masukkan password yang lebih pendek dari 8 karakter. Field password akan menampilkan error tentang panjang minimum.

![validation test - password field shorter](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/18-register-validation-password-field.webp)

4. Masukkan password yang valid pada field password, tetapi ketikkan sesuatu yang berbeda pada field konfirmasi. Anda akan melihat error yang menyatakan bahwa password confirmation tidak cocok.
![validation test - password not match](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/19-register-validation-password-not-match.webp)

5. Isi semua field dengan benar menggunakan data yang valid dan klik "Create Account." Anda akan diarahkan ke daftar entries dengan pesan selamat datang seperti "Welcome to Catatku, New user!"
![new user registered](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/20-user-registered.webp)

6. Coba kunjungi `/register` lagi saat masih login. Anda akan diarahkan keluar dari halaman registrasi karena middleware `guest` mencegah pengguna yang sudah login mengaksesnya.

7. Coba mendaftar dengan email yang sama yang baru saja Anda gunakan. Anda akan melihat error pada field email yang menyatakan bahwa email tersebut sudah digunakan.
![validation test - email taken](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/21-register-validation-email-taken.webp)

---

## Apa itu Authentication? {#what-is-authentication}

Authentication adalah proses membuktikan identitas, memverifikasi bahwa seseorang adalah benar-benar siapa yang mereka klaim. Di Catatku, authentication melibatkan tiga operasi:

**Registration** adalah ketika pengguna mendaftar dengan name, email, dan password. Data divalidasi, password di-hash, akun disimpan ke database, dan pengguna otomatis login.

**Login** adalah ketika pengguna yang sudah ada memasukkan email dan password mereka. Sistem memverifikasi kredensial terhadap apa yang tersimpan di database. Jika cocok, sebuah session dibuat.

**Logout** adalah ketika session dihancurkan. Pengguna kembali menjadi pengunjung yang belum login.

Tanpa authentication, kita tidak akan memiliki cara untuk mengetahui siapa yang menulis entry mana, dan semua fitur privasi yang telah kita bangun tidak akan berfungsi dengan benar. Kolom `user_id` pada tabel `entries`, pengecekan `abort(403)` di controller, dan directive `@auth` di layout, semuanya bergantung pada mengetahui siapa pengguna saat ini.

Pada lesson ini, kita membangun bagian registrasi. Login dan logout akan diselesaikan pada lesson berikutnya.

---

## Conclusion {#conclusion}

Sistem registrasi sekarang sudah berfungsi penuh. Berikut adalah poin-poin pentingnya:

- **Authentication** adalah proses memverifikasi identitas pengguna. Registration, login, dan logout adalah tiga operasi inti.
- `AuthController` menangani logika authentication secara terpisah dari pengelolaan entries, menjaga concern tetap terpisah dengan baik.
- `unique:users,email` memeriksa database untuk memastikan tidak ada dua pengguna yang memiliki alamat email yang sama.
- Validation rule `confirmed` mengharuskan adanya field pendamping bernama `{field}_confirmation` dengan nilai yang cocok. Ini mencegah typo password saat registrasi.
- `Hash::make()` mengubah password teks biasa menjadi hash bcrypt yang tidak dapat dikembalikan. **Jangan pernah menyimpan password sebagai teks biasa.** Jika database diretas, password yang sudah di-hash melindungi pengguna Anda karena nilai aslinya tidak dapat dipulihkan.
- `Auth::login($user)` membuat session untuk pengguna, langsung login-kan mereka setelah registrasi sehingga mereka tidak perlu memasukkan kredensial untuk kedua kalinya.
- `middleware('guest')` membatasi route hanya untuk pengunjung yang belum login. Pengguna yang sudah login akan otomatis dialihkan. Ini adalah pasangan dari `middleware('auth')`.
- Field password **tidak boleh** pernah menggunakan `old()` untuk mempertahankan nilai setelah validasi gagal. Mengirim kembali password ke browser, bahkan dalam field form, adalah risiko keamanan.
- Route `/dev-login` tidak lagi diperlukan dan telah dihapus. Mulai dari titik ini, semua authentication melewati sistem yang sesungguhnya.
- `User` model default di Laravel 13 menggunakan attribute `#[Fillable(['name', 'email', 'password'])]` dan `#[Hidden(['password', 'remember_token'])]`, sesuai dengan pendekatan berbasis attribute modern yang kita gunakan untuk model `Entry`.

Pada lesson berikutnya, kita akan menyelesaikan sistem authentication dengan fungsi login dan logout. Setelah itu, Catatku akan berdiri sepenuhnya di atas fondasinya sendiri, tanpa jalan pintas atau workaround yang tersisa.
