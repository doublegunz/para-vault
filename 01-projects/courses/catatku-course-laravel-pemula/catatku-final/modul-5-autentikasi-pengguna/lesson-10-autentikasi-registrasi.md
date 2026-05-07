# Lesson 10 — Autentikasi Dasar: Registrasi

## Tujuan Pembelajaran

Di akhir lesson ini, kamu akan:
- Memahami bagaimana sistem autentikasi bekerja secara teknis
- Membuat `AuthController` dengan method untuk registrasi
- Membangun form registrasi dengan validasi lengkap
- Meng-hash password sebelum disimpan ke database
- Login otomatis setelah registrasi berhasil

---

## Apa itu Autentikasi?

Autentikasi adalah proses membuktikan identitas — memverifikasi bahwa seseorang adalah siapa yang mereka klaim. Di Catatku, autentikasi berarti:

1. **Registrasi** — User daftar dengan nama, email, password → tersimpan di database → langsung login
2. **Login** — User masukkan email + password → diverifikasi → jika cocok, buat session
3. **Logout** — Hapus session → user kembali jadi tamu

Tanpa autentikasi, kita tidak bisa tahu siapa yang menulis catatan mana, dan semua fitur privat yang sudah kita bangun tidak akan berfungsi dengan benar.

---

## Membuat AuthController

Buat controller khusus untuk autentikasi:

```bash
php artisan make:controller AuthController
```

Buka `app/Http/Controllers/AuthController.php` dan tambahkan method untuk registrasi:

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
        // Langkah 1: Validasi input
        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|string|min:8|confirmed',
        ]);

        // Langkah 2: Simpan user baru dengan password yang di-hash
        $user = User::create([
            'name'     => $validated['name'],
            'email'    => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        // Langkah 3: Login otomatis
        Auth::login($user);

        // Langkah 4: Arahkan ke daftar catatan
        return redirect('/entries')
            ->with('success', 'Selamat datang di Catatku, ' . $user->name . '!');
    }
}
```

---

## Memahami Setiap Bagian

### Validasi Registrasi

```php
$validated = $request->validate([
    'name'     => 'required|string|max:255',
    'email'    => 'required|email|unique:users,email',
    'password' => 'required|string|min:8|confirmed',
]);
```

**`email`** — Memastikan format email valid (ada tanda `@` dan domain).

**`unique:users,email`** — Mengecek ke database bahwa email ini belum digunakan user lain. Format: `unique:nama_tabel,nama_kolom`.

**`min:8`** — Password minimal 8 karakter.

**`confirmed`** — Aturan ini membutuhkan field tambahan bernama `password_confirmation` yang isinya sama persis dengan `password`. Jika berbeda, validasi gagal. Ini mencegah user salah ketik password.

### Hashing Password

```php
'password' => Hash::make($validated['password']),
```

Password **tidak boleh** disimpan sebagai teks biasa. Jika database bocor, semua password pengguna langsung terbaca.

`Hash::make()` mengubah password menjadi hash yang tidak bisa dibalik:

```
Input:   "rahasia123"
Output:  "$2y$12$LkIKjbPXRGkpVBz..."
```

Setiap kali di-hash, hasilnya berbeda karena menggunakan salt acak. Tapi Laravel tetap bisa memverifikasi dengan `Hash::check('rahasia123', $hash)`.

### Login Otomatis

```php
Auth::login($user);
```

Setelah user berhasil dibuat, kita login langsung tanpa perlu redirect ke halaman login. Pengalaman yang lebih baik — pengguna tidak perlu memasukkan kredensial dua kali.

---

## Menambahkan Routes Registrasi

Perbarui `routes/web.php` dengan menambahkan routes untuk autentikasi:

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EntryController;
use App\Http\Controllers\AuthController;

// Route untuk tamu (belum login)
Route::middleware('guest')->group(function () {
    Route::get('/register', [AuthController::class, 'showRegister']);
    Route::post('/register', [AuthController::class, 'register']);
});

// Route daftar catatan (publik, tapi controller akan cek auth)
Route::get('/entries', [EntryController::class, 'index']);

// Route yang butuh login
Route::middleware('auth')->group(function () {
    Route::get('/entries/create', [EntryController::class, 'create']);
    Route::post('/entries', [EntryController::class, 'store']);
    Route::get('/entries/{entry}', [EntryController::class, 'show']);
    Route::get('/entries/{entry}/edit', [EntryController::class, 'edit']);
    Route::put('/entries/{entry}', [EntryController::class, 'update']);
    Route::delete('/entries/{entry}', [EntryController::class, 'destroy']);
});
```

`middleware('guest')` memastikan halaman registrasi hanya bisa diakses tamu. User yang sudah login akan diarahkan ke halaman utama jika mencoba membuka `/register`.

---

## Membuat View Registrasi

Buat file `resources/views/auth/register.blade.php`:

```html
<x-layout title="Daftar — Catatku">

    <div class="max-w-sm mx-auto">

        <div class="text-center mb-8">
            <p class="text-4xl mb-2">📓</p>
            <h1 class="text-2xl font-bold text-gray-900">Bergabung di Catatku</h1>
            <p class="text-sm text-gray-500 mt-1">
                Tempat menyimpan catatan harianmu
            </p>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 p-6">
            <form method="POST" action="/register">
                @csrf

                {{-- Nama --}}
                <div class="mb-4">
                    <label for="name"
                           class="block text-sm font-medium text-gray-700 mb-1">
                        Nama
                    </label>
                    <input
                        type="text"
                        id="name"
                        name="name"
                        value="{{ old('name') }}"
                        placeholder="Nama lengkapmu"
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
                        placeholder="nama@email.com"
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
                        placeholder="Minimal 8 karakter"
                        class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                               focus:ring-2 focus:ring-gray-900 focus:border-transparent
                               {{ $errors->has('password') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                    >
                    @error('password')
                        <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Konfirmasi Password --}}
                <div class="mb-6">
                    <label for="password_confirmation"
                           class="block text-sm font-medium text-gray-700 mb-1">
                        Konfirmasi Password
                    </label>
                    <input
                        type="password"
                        id="password_confirmation"
                        name="password_confirmation"
                        placeholder="Ulangi password"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm
                               focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent"
                    >
                </div>

                <button type="submit"
                    class="w-full bg-gray-900 text-white py-2.5 rounded-lg text-sm font-medium
                           hover:bg-gray-700 transition-colors">
                    Buat Akun
                </button>

            </form>
        </div>

        <p class="text-center text-sm text-gray-500 mt-4">
            Sudah punya akun?
            <a href="/login" class="text-gray-900 font-medium hover:underline">
                Masuk di sini
            </a>
        </p>

    </div>

</x-layout>
```

---

## Memastikan Model User Bisa Diisi

Buka `app/Models/User.php` dan pastikan kolom `name`, `email`, `password` ada di `$fillable`:

```php
protected $fillable = [
    'name',
    'email',
    'password',
];
```

Ini biasanya sudah ada bawaan Laravel, tapi pastikan untuk memverifikasi.

---

## Mencoba Registrasi

Hapus route `/dev-login` yang dibuat di lesson sebelumnya, lalu:

1. Akses `http://127.0.0.1:8000/register`
2. Isi form dengan data yang valid, klik "Buat Akun"
3. Kamu langsung masuk dan melihat halaman daftar catatan dengan pesan selamat datang
4. Coba daftar dengan email yang sama → error "email sudah digunakan"
5. Coba isi password dan konfirmasi berbeda → error validasi "password confirmation tidak cocok"

---

## Ringkasan

Kita telah:
- Membuat `AuthController` dengan method `showRegister()` dan `register()`
- Mengimplementasikan validasi `required`, `email`, `unique`, `min:8`, dan `confirmed`
- Menyimpan user baru dengan password yang di-hash menggunakan `Hash::make()`
- Login otomatis setelah registrasi dengan `Auth::login($user)`
- Melindungi halaman registrasi dengan `middleware('guest')`

Di lesson berikutnya, kita akan melengkapi sistem autentikasi dengan fitur **login** dan **logout**.
