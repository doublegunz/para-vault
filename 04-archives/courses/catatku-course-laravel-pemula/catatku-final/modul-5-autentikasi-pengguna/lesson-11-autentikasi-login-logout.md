# Lesson 11 — Autentikasi Dasar: Login dan Logout

## Tujuan Pembelajaran

Di akhir lesson ini, kamu akan:
- Membuat form login dan memproses verifikasi credentials
- Memahami cara kerja session di Laravel
- Mengimplementasikan logout yang aman
- Melindungi halaman `/entries` agar hanya bisa diakses setelah login
- Memiliki sistem autentikasi Catatku yang lengkap dan berfungsi

---

## Bagaimana Login Bekerja?

Ketika user mengisi form login dan klik "Masuk", ini yang terjadi di balik layar:

```
1. Browser kirim POST /login
   { email: "budi@example.com", password: "rahasia123" }
         │
         ▼
2. Auth::attempt() cari user berdasarkan email
   lalu cocokkan password dengan Hash::check()
         │
         ├── Tidak cocok → kembali ke form dengan pesan error
         │
         └── Cocok → buat session
                       Session ID disimpan di server
                       ID-nya dikirim ke browser sebagai cookie
         │
         ▼
3. Redirect ke daftar catatan
   Setiap request berikutnya membawa cookie,
   Laravel tahu siapa user yang aktif
```

---

## Menambahkan Method Login dan Logout ke AuthController

Buka `app/Http/Controllers/AuthController.php` dan tambahkan dua method baru:

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
    // --- Registrasi (dari lesson 10) ---

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
            ->with('success', 'Selamat datang di Catatku, ' . $user->name . '!');
    }

    // --- Login ---

    public function showLogin()
    {
        return view('auth.login');
    }

    public function login(Request $request): RedirectResponse
    {
        // Langkah 1: Validasi format input
        $credentials = $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        // Langkah 2: Coba login dengan credentials
        if (Auth::attempt($credentials)) {
            // Regenerate session ID untuk keamanan
            $request->session()->regenerate();

            return redirect('/entries')
                ->with('success', 'Selamat datang kembali!');
        }

        // Langkah 3: Gagal — kembalikan ke form dengan pesan error
        return back()->withErrors([
            'email' => 'Email atau password yang kamu masukkan salah.',
        ])->onlyInput('email');
    }

    // --- Logout ---

    public function logout(Request $request): RedirectResponse
    {
        Auth::logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect('/login');
    }
}
```

---

## Memahami Setiap Bagian

### `Auth::attempt($credentials)`

Method ini melakukan dua hal sekaligus: mencari user berdasarkan email, lalu memverifikasi password menggunakan `Hash::check()`. Mengembalikan `true` jika berhasil, `false` jika gagal. Kita tidak perlu menulis logika ini secara manual.

### `$request->session()->regenerate()`

Setelah login berhasil, session ID diperbarui. Ini melindungi dari serangan **session fixation** — di mana penyerang mencuri session ID sebelum korban login, lalu menggunakannya setelah login berhasil.

### Pesan error yang umum, bukan spesifik

```php
'email' => 'Email atau password yang kamu masukkan salah.',
```

Kita sengaja tidak membedakan antara "email tidak ditemukan" dan "password salah". Pesan yang terlalu spesifik membantu penyerang mengetahui apakah sebuah email sudah terdaftar di sistem kita.

### `back()->withErrors([...])->onlyInput('email')`

- `back()` — kembali ke halaman sebelumnya (form login)
- `withErrors([...])` — kirim pesan error ke view
- `onlyInput('email')` — kembalikan nilai email ke form, tapi **tidak** password. Demi keamanan, password tidak boleh diisi ulang otomatis.

### Tiga langkah logout yang aman

```php
Auth::logout();                        // Hapus data user dari session
$request->session()->invalidate();     // Hapus seluruh data session dari server
$request->session()->regenerateToken(); // Buat CSRF token baru
```

Tiga langkah ini memastikan tidak ada sisa data session yang bisa disalahgunakan setelah logout.

---

## Memperbarui Routes

Perbarui `routes/web.php` dengan konfigurasi route yang lengkap dan final:

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EntryController;
use App\Http\Controllers\AuthController;

// Route untuk tamu (hanya bisa diakses sebelum login)
Route::middleware('guest')->group(function () {
    Route::get('/register', [AuthController::class, 'showRegister']);
    Route::post('/register', [AuthController::class, 'register']);
    Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AuthController::class, 'login']);
});

// Semua route yang butuh login
Route::middleware('auth')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/entries', [EntryController::class, 'index']);
    Route::get('/entries/create', [EntryController::class, 'create']);
    Route::post('/entries', [EntryController::class, 'store']);
    Route::get('/entries/{entry}', [EntryController::class, 'show']);
    Route::get('/entries/{entry}/edit', [EntryController::class, 'edit']);
    Route::put('/entries/{entry}', [EntryController::class, 'update']);
    Route::delete('/entries/{entry}', [EntryController::class, 'destroy']);
});

// Redirect halaman awal ke login
Route::get('/', function () {
    return redirect('/login');
});
```

Perubahan penting dari sebelumnya:

**`/entries` dipindahkan ke dalam `middleware('auth')`** — Catatan bersifat sepenuhnya privat. Tamu yang mencoba mengakses `/entries` langsung akan diarahkan ke halaman login.

**`.name('login')`** — Memberi nama pada route login. Middleware `auth` bawaan Laravel akan mencari route bernama `login` untuk mengarahkan tamu yang belum login. Tanpa ini, tamu yang mengakses route terlindungi akan mendapat error.

**`Route::get('/')` redirect ke login** — Agar halaman awal tidak kosong.

---

## Membuat View Login

Buat file `resources/views/auth/login.blade.php`:

```html
<x-layout title="Masuk — Catatku">

    <div class="max-w-sm mx-auto">

        <div class="text-center mb-8">
            <p class="text-4xl mb-2">📓</p>
            <h1 class="text-2xl font-bold text-gray-900">Masuk ke Catatku</h1>
            <p class="text-sm text-gray-500 mt-1">
                Lanjutkan menulis catatanmu
            </p>
        </div>

        <div class="bg-white rounded-xl border border-gray-200 p-6">
            <form method="POST" action="/login">
                @csrf

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
                        autofocus
                    >
                    @error('email')
                        <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Password --}}
                <div class="mb-6">
                    <label for="password"
                           class="block text-sm font-medium text-gray-700 mb-1">
                        Password
                    </label>
                    <input
                        type="password"
                        id="password"
                        name="password"
                        placeholder="Password kamu"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm
                               focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent"
                    >
                </div>

                <button type="submit"
                    class="w-full bg-gray-900 text-white py-2.5 rounded-lg text-sm font-medium
                           hover:bg-gray-700 transition-colors">
                    Masuk
                </button>

            </form>
        </div>

        <p class="text-center text-sm text-gray-500 mt-4">
            Belum punya akun?
            <a href="/register" class="text-gray-900 font-medium hover:underline">
                Daftar sekarang
            </a>
        </p>

    </div>

</x-layout>
```

---

## Pengujian Akhir: Alur Lengkap Catatku

Sekarang uji seluruh alur dari awal tanpa route development apapun:

**Skenario 1: Pengguna baru**
1. Buka `http://127.0.0.1:8000` → diarahkan ke `/login`
2. Klik "Daftar sekarang" → isi form registrasi → langsung masuk ke daftar catatan
3. Tulis beberapa catatan, baca, edit, hapus — semua berfungsi
4. Klik "Logout" → diarahkan ke halaman login

**Skenario 2: Pengguna kembali**
1. Buka halaman login, masukkan email dan password yang benar → masuk ke daftar catatan
2. Catatan yang sebelumnya ditulis masih ada

**Skenario 3: Credentials salah**
1. Di halaman login, masukkan password yang salah
2. Pesan error muncul, email tetap terisi, password kosong

**Skenario 4: Tamu mencoba akses langsung**
1. Logout terlebih dahulu
2. Coba akses `http://127.0.0.1:8000/entries` langsung dari URL bar
3. Otomatis diarahkan ke `/login`

**Skenario 5: User yang sudah login mencoba akses `/register`**
1. Pastikan sudah login
2. Coba akses `http://127.0.0.1:8000/register`
3. Otomatis diarahkan ke `/entries` (karena middleware `guest`)

---

## Tampilan Alur Aplikasi yang Sudah Selesai

```
Tamu membuka Catatku
    │
    ├── Halaman awal → redirect ke /login
    ├── Klik "Daftar" → form registrasi → langsung masuk ✓
    └── Isi form login → masuk ke daftar catatan ✓

User yang sudah login
    │
    ├── Lihat daftar catatan milik sendiri ✓
    ├── Buka detail catatan ✓
    ├── Tulis catatan baru ✓
    ├── Edit catatan ✓
    ├── Hapus catatan ✓
    └── Logout → kembali ke halaman login ✓

Keamanan
    ├── Tamu tidak bisa akses /entries → redirect ke login ✓
    ├── User A tidak bisa baca catatan User B → 403 ✓
    ├── User A tidak bisa edit catatan User B → 403 ✓
    └── User A tidak bisa hapus catatan User B → 403 ✓
```

---

## Ringkasan

Sistem autentikasi Catatku kini lengkap:

**Login** menggunakan `Auth::attempt()` yang otomatis memverifikasi password yang ter-hash, diikuti `session()->regenerate()` untuk keamanan.

**Logout** menjalankan tiga langkah: `Auth::logout()`, `session()->invalidate()`, dan `session()->regenerateToken()` untuk memastikan tidak ada sisa session.

**Proteksi route** menggunakan `middleware('auth')` untuk semua halaman yang butuh login, dan `middleware('guest')` untuk halaman yang hanya boleh diakses tamu.

Dengan selesainya lesson ini, aplikasi Catatku sudah memiliki semua fitur yang direncanakan sejak Lesson 1 — mulai dari menulis catatan hingga sistem autentikasi yang aman.
