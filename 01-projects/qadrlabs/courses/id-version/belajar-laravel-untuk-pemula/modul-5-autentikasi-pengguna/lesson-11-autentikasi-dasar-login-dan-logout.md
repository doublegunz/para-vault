Lesson sebelumnya menyelesaikan alur registrasi. Pengguna dapat membuat akun dan langsung login secara otomatis. Namun ada satu skenario yang belum kita tangani: pengguna yang sudah memiliki akun, menutup browser, dan kembali keesokan harinya. Mereka membutuhkan cara untuk login kembali. Dan pengguna yang sudah selesai membutuhkan cara untuk logout dengan aman. Lesson ini membangun keduanya, dan ini adalah lesson terakhir yang menyentuh sistem autentikasi.

## Ikhtisar {#overview}

### What You'll Build

Di akhir lesson ini, tidak akan ada celah yang tersisa pada alur autentikasi. Tamu akan diarahkan ke halaman login, pengguna yang sudah login tidak dapat mengakses halaman registrasi atau login lagi, dan seluruh alur dari mendaftar hingga logout berfungsi tanpa jalan pintas pengembangan apa pun. Kita juga akan memperbarui halaman utama dengan tautan navigasi yang sebenarnya, membuat daftar entri sepenuhnya privat, dan memperbarui controller agar hanya menampilkan entri milik pengguna yang sedang login.

### What You'll Learn

- Bagaimana `Auth::attempt()` memverifikasi kredensial terhadap database
- Mengapa regenerasi session setelah login melindungi dari serangan session fixation
- Mengapa pesan error login sebaiknya dibuat samar secara sengaja
- Bagaimana proses logout tiga langkah bekerja dan mengapa setiap langkah penting
- Bagaimana menggunakan `->name('login')` untuk memberi nama pada route yang dibutuhkan oleh middleware auth Laravel
- Bagaimana `back()->withErrors()->onlyInput()` mengirim pesan error kembali ke form sambil hanya mempertahankan input yang aman
- Bagaimana memperbarui halaman utama agar terhubung ke route autentikasi yang sebenarnya
- Mengapa query controller berubah dari `Entry::with('user')` menjadi `auth()->user()->entries()` setelah autentikasi diterapkan

### What You'll Need

- Proyek `catatku` terbuka di VS Code dengan development server berjalan
- `AuthController` dengan method registrasi dari Lesson 10
- Setidaknya satu akun pengguna terdaftar untuk pengujian login

---

## Step 1: Tambahkan Method Login dan Logout ke AuthController {#step-1-add-login-and-logout-methods-to-authcontroller}

Buka `app/Http/Controllers/AuthController.php` dan tambahkan method login dan logout di bawah method registrasi yang sudah ada:

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
    // --- Registration (from Lesson 10) ---

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

    // --- Login ---

    public function showLogin()
    {
        return view('auth.login');
    }

    public function login(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        if (Auth::attempt($credentials)) {
            $request->session()->regenerate();

            return redirect('/entries')
                ->with('success', 'Welcome back!');
        }

        return back()->withErrors([
            'email' => 'The email or password you entered is incorrect.',
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

Mari kita telusuri setiap method baru secara detail.

### Method `login()` {#the-login-method}

Method login memiliki tiga fase yang berbeda: memvalidasi format input, mencoba autentikasi, dan menangani kegagalan.

```php
$credentials = $request->validate([
    'email'    => 'required|email',
    'password' => 'required|string',
]);
```

Langkah pertama ini memvalidasi bahwa field email dan password ada dan memiliki format yang benar. Perhatikan bahwa kita tidak menggunakan `unique` atau `min:8` di sini. Aturan-aturan tersebut adalah untuk registrasi. Saat login, kita hanya peduli bahwa field-field tersebut tidak kosong dan email terlihat seperti email. Verifikasi kredensial yang sebenarnya terjadi pada langkah berikutnya.

```php
if (Auth::attempt($credentials)) {
    $request->session()->regenerate();

    return redirect('/entries')
        ->with('success', 'Welcome back!');
}
```

`Auth::attempt($credentials)` melakukan dua hal dalam satu pemanggilan: mencari pengguna dengan email yang diberikan, lalu memverifikasi password terhadap hash yang tersimpan menggunakan `Hash::check()`. Jika keduanya berhasil, ia membuat session untuk pengguna dan mengembalikan `true`. Jika salah satunya gagal (email tidak ditemukan atau password tidak cocok), ia mengembalikan `false`. Anda tidak perlu menulis sendiri logika pencarian atau verifikasi ini.

`$request->session()->regenerate()` menghasilkan ID session baru segera setelah login berhasil. Ini melindungi dari **serangan session fixation**, di mana penyerang mendapatkan ID session sebelum korban login dan kemudian menggunakan ID yang sama untuk membajak session yang sudah terautentikasi. Dengan meregenerasi ID setelah login, ID session yang sebelumnya didapatkan menjadi tidak berguna.

```php
return back()->withErrors([
    'email' => 'The email or password you entered is incorrect.',
])->onlyInput('email');
```

Jika `Auth::attempt()` mengembalikan `false`, kita mengarahkan pengguna kembali ke form login dengan pesan error. Tiga hal terjadi dalam rangkaian ini:

`back()` mengarahkan kembali ke halaman sebelumnya (form login).

`withErrors(['email' => '...'])` melampirkan pesan error ke field `email`. Pesan tersebut dengan sengaja mengatakan "The email or password you entered is incorrect" tanpa menyebutkan mana yang salah. Kesamaran ini disengaja. Jika pesan error mengatakan "email tidak ditemukan," penyerang dapat menggunakan form login untuk mengetahui alamat email mana saja yang terdaftar di sistem. Menjaga pesan tetap umum mencegah kebocoran informasi ini.

`onlyInput('email')` hanya mempertahankan nilai field email dalam session. Password sengaja dikecualikan. Mengirim password kembali ke browser, bahkan dalam field form, adalah risiko keamanan. Pengguna perlu mengetik ulang password mereka, tetapi alamat email mereka akan tetap terisi.

### Method `logout()` {#the-logout-method}

```php
public function logout(Request $request): RedirectResponse
{
    Auth::logout();

    $request->session()->invalidate();
    $request->session()->regenerateToken();

    return redirect('/login');
}
```

Logout melibatkan tiga langkah, dan masing-masing memiliki tujuan yang berbeda:

`Auth::logout()` menghapus identitas pengguna dari session saat ini. Setelah pemanggilan ini, `auth()->user()` mengembalikan `null`.

`$request->session()->invalidate()` menghancurkan seluruh data session di server. Ini memastikan bahwa tidak ada data sisa dari session yang terautentikasi yang dapat digunakan kembali.

`$request->session()->regenerateToken()` membuat token CSRF baru. Token lama terikat pada session sebelumnya, dan jika seseorang berhasil mendapatkannya, mereka berpotensi menggunakannya untuk memalsukan request. Membuat token baru setelah logout menghilangkan risiko tersebut.

Ketiga langkah ini bersama-sama memastikan logout yang bersih dan aman tanpa sisa session yang dapat dieksploitasi.

---

## Step 2: Perbarui Route {#step-2-update-the-routes}

Perbarui `routes/web.php` dengan konfigurasi route final yang lengkap:

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EntryController;
use App\Http\Controllers\AuthController;

Route::get('/', function () {
    return view('home');
});

// Routes for guests (only accessible before login)
Route::middleware('guest')->group(function () {
    Route::get('/register', [AuthController::class, 'showRegister']);
    Route::post('/register', [AuthController::class, 'register']);
		
	// Add a login route
    Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AuthController::class, 'login']);
});

// All routes that require login
Route::middleware('auth')->group(function () {

	// Add a route for logging out
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/entries', [EntryController::class, 'index']); // Move  /entries route into the `middleware(‘auth’)` group
    Route::get('/entries/create', [EntryController::class, 'create']);
    Route::post('/entries', [EntryController::class, 'store']);
    Route::get('/entries/{entry}', [EntryController::class, 'show']);
    Route::get('/entries/{entry}/edit', [EntryController::class, 'edit']);
    Route::put('/entries/{entry}', [EntryController::class, 'update']);
    Route::delete('/entries/{entry}', [EntryController::class, 'destroy']);
});
```

Ada dua perubahan penting dari file route lesson sebelumnya.

**`/entries` telah dipindahkan ke dalam grup `middleware('auth')`.** Pada lesson-lesson sebelumnya, daftar entri bersifat publik agar kita dapat mengembangkan dan menguji tanpa sistem autentikasi yang berfungsi. Sekarang setelah registrasi dan login berfungsi sepenuhnya, entri menjadi sepenuhnya privat. Tamu mana pun yang mencoba mengakses `/entries` akan secara otomatis diarahkan ke halaman login. Ini sesuai dengan janji inti Catatku: semua entri jurnal bersifat personal dan privat.

Before:
```php
Route::get('/entries', [EntryController::class, 'index']);

Route::middleware('auth')->group(function () {
    
    // ... other routes

});
```
After:
```php
Route::middleware('auth')->group(function () {
    
    Route::get('/entries', [EntryController::class, 'index']);
     // ... other routes

});
```

**`->name('login')` memberi nama pada route login.** Ini bukan sekadar untuk kenyamanan. Middleware `auth` bawaan Laravel mencari route bernama `login` saat perlu mengarahkan pengguna yang belum terautentikasi. Tanpa nama ini, tamu yang mencoba mengakses route yang dilindungi akan mendapatkan error, bukan diarahkan dengan mulus ke halaman login. Method `->name()` adalah cara untuk memberikan nama pada route di Laravel.

Route `logout` menggunakan POST, bukan GET. Ini adalah praktik terbaik keamanan. Jika logout berupa request GET, situs web jahat dapat menyertakan tag image seperti `<img src="http://catatku.test/logout">` yang akan membuat pengguna logout tanpa sepengetahuan mereka. Membuatnya menjadi POST dan mengharuskan token `@csrf` mencegah hal ini.

---

## Step 3: Perbarui EntryController {#step-3-update-the-entrycontroller}

Sekarang setelah `/entries` berada di dalam grup `middleware('auth')`, pengguna selalu dalam keadaan terautentikasi saat method `index()` dijalankan. Ini berarti kita dapat dan sebaiknya memperbarui query untuk hanya menampilkan entri milik pengguna yang sedang login, alih-alih menampilkan entri semua orang.

Buka `app/Http/Controllers/EntryController.php` dan perbarui method `index()`:

```php
public function index()
{
    $entries = auth()->user()->entries()->latest()->get();

    return view('entries.index', compact('entries'));
}
```

Bagian controller lainnya tetap sama. Berikut alasan mengapa perubahan ini penting:

```php
// Before (Lessons 6-9): fetched ALL entries from ALL users
$entries = Entry::with('user')->latest()->get();

// Now (Lesson 11): fetches only the current user's entries
$entries = auth()->user()->entries()->latest()->get();
```

Pada Lesson 6 hingga 9, kita menggunakan `Entry::with('user')->latest()->get()` karena route `/entries` bersifat publik dan sistem autentikasi belum ada. Memanggil `auth()->user()` pada pengunjung yang belum terautentikasi akan membuat aplikasi crash. Menggunakan `Entry::with('user')` adalah pilihan praktis yang memungkinkan kita mengembangkan dan menguji fitur CRUD tanpa terhalang oleh autentikasi.

Sekarang setelah `/entries` berada di dalam `middleware('auth')`, Laravel menjamin bahwa `auth()->user()` selalu mengembalikan objek `User` yang valid. Aman untuk memanggil `auth()->user()->entries()`, dan yang lebih penting, ini adalah hal yang *benar* untuk dilakukan. Catatku adalah aplikasi jurnal privat. Setiap pengguna seharusnya hanya melihat entri mereka sendiri, bukan milik orang lain.

`auth()->user()->entries()->latest()->get()` bekerja melalui relasi `hasMany` yang kita definisikan pada Lesson 6. Ia secara otomatis menambahkan klausa `WHERE user_id = ?` ke query SQL, membatasi hasil hanya untuk pengguna yang terautentikasi. Anda tidak perlu memfilter `user_id` secara manual dalam query. Relasi tersebut yang menanganinya untuk Anda.

Perhatikan bahwa `with('user')` juga tidak lagi diperlukan. Karena kita melakukan query melalui relasi pengguna, kita sudah tahu siapa penggunanya. Tidak perlu melakukan eager load untuk itu.

---

## Step 4: Buat View Login {#step-4-create-the-login-view}

Buat file `resources/views/auth/login.blade.php`:

```html
<x-layout title="Log In — Catatku">

    <div class="max-w-sm mx-auto">

        <div class="text-center mb-8">
            <p class="text-4xl mb-2">📓</p>
            <h1 class="text-2xl font-bold text-gray-900">Log in to Catatku</h1>
            <p class="text-sm text-gray-500 mt-1">
                Continue writing your journal
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
                        placeholder="name@email.com"
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
                        placeholder="Your password"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm
                               focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent"
                    >
                </div>

                <button type="submit"
                    class="w-full bg-gray-900 text-white py-2.5 rounded-lg text-sm font-medium
                           hover:bg-gray-700 transition-colors">
                    Log In
                </button>

            </form>
        </div>

        <p class="text-center text-sm text-gray-500 mt-4">
            Don't have an account?
            <a href="/register" class="text-gray-900 font-medium hover:underline">
                Register now
            </a>
        </p>

    </div>

</x-layout>
```

Form login lebih sederhana dibandingkan form registrasi karena hanya membutuhkan dua field: email dan password. Perhatikan bahwa field password tidak menggunakan `old()`. Seperti yang kita bahas pada Lesson 10, nilai password tidak boleh pernah dikirim kembali ke browser, bahkan setelah percobaan login yang gagal.

Blok `@error('email')` akan menampilkan pesan error generik yang kita definisikan di controller ("The email or password you entered is incorrect.") ketika autentikasi gagal. Karena kita melampirkan error ke key `email` menggunakan `withErrors(['email' => '...'])`, pesan tersebut muncul di bawah field email, tetapi pesannya sendiri mencakup kedua field.

---

## Step 5: Perbarui Halaman Home {#step-5-update-the-home-page}

Tombol-tombol pada halaman utama telah menjadi placeholder kosong sejak Lesson 3. Sekarang setelah autentikasi sudah ada, kita dapat menghubungkannya. Perbarui `resources/views/home.blade.php`:

```html
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Catatku - Simple Journal App</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-50 text-gray-900 font-sans antialiased selection:bg-blue-100">
    <div class="min-h-screen flex flex-col items-center justify-center bg-gradient-to-b from-blue-50 to-white">
        <div class="max-w-2xl w-full text-center px-6 py-12">
            <h1 class="text-5xl font-extrabold tracking-tight text-blue-600 mb-6 drop-shadow-sm">Catatku</h1>
            <p class="text-xl text-gray-600 mb-10 leading-relaxed">
                A simple journal app to accompany your day. Start capturing what matters, easily and quickly.
            </p>
            
            <div class="flex flex-col sm:flex-row gap-4 justify-center items-center">
                @auth
                    <a href="{{ url('/entries') }}" class="inline-flex items-center justify-center px-8 py-3.5 border border-transparent text-lg font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow flex-1 sm:flex-none transition-all duration-200 hover:scale-105">
                        My Entries
                    </a>
                @else
                    <a href="{{ url('/login') }}" class="inline-flex items-center justify-center px-8 py-3.5 border border-transparent text-lg font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow flex-1 sm:flex-none transition-all duration-200 hover:scale-105">
                        Log In
                    </a>
                    <a href="{{ url('/register') }}" class="inline-flex items-center justify-center px-8 py-3.5 border border-gray-200 text-lg font-medium rounded-xl text-blue-700 bg-white hover:bg-gray-50 shadow-sm flex-1 sm:flex-none transition-all duration-200 hover:border-gray-300">
                        Register
                    </a>
                @endauth
            </div>
        </div>
    </div>
</body>
</html>
```

Pada langkah ini, kita menambahkan tautan ke halaman "My Entries," "Login," dan "Register." Placeholder `href=""` sekarang digantikan dengan URL yang sebenarnya menggunakan helper `{{ url('/path') }}`. Blok `@auth` menampilkan tombol "My Entries" untuk pengguna yang sudah login, sementara blok `@else` menampilkan tombol "Log In" dan "Register" untuk tamu.

---

## Step 6: Uji Alur Authentication Secara Lengkap {#step-6-test-the-complete-authentication-flow}

Pastikan development server berjalan, lalu uji skenario-skenario berikut untuk memverifikasi bahwa semuanya berfungsi dengan benar:

**Scenario 1: New user registration**

1. Buka `http://127.0.0.1:8000` dan klik "Register" untuk masuk ke halaman registrasi.
2. Isi form dan klik "Create Account." Anda akan login dan diarahkan ke daftar entri dengan pesan selamat datang.
3. Buat beberapa entri, baca, edit, dan hapus. Semuanya harus berfungsi.
4. Klik "Logout" pada navigation bar. Anda akan diarahkan ke halaman login.

**Scenario 2: Returning user login**

1. Buka halaman login dan masukkan email dan password yang Anda gunakan saat registrasi. Klik "Log In."
2. Anda akan diarahkan ke daftar entri dengan pesan "Welcome back!".
3. Entri yang Anda buat sebelumnya seharusnya masih ada.

**Scenario 3: Wrong credentials**

1. Pada halaman login, masukkan email yang valid tetapi password yang salah. Klik "Log In."
2. Anda akan melihat pesan error "The email or password you entered is incorrect." Field email seharusnya tetap terisi, tetapi field password kosong.

**Scenario 4: Guest tries to access entries directly**

1. Pastikan Anda dalam keadaan logout.
2. Coba akses `http://127.0.0.1:8000/entries` langsung melalui address bar.
3. Anda akan secara otomatis diarahkan ke `/login`.

**Scenario 5: Logged-in user tries to access registration or login**

1. Pastikan Anda dalam keadaan login.
2. Coba akses `http://127.0.0.1:8000/register` atau `http://127.0.0.1:8000/login`.
3. Anda akan diarahkan keluar secara otomatis karena middleware `guest` mencegah pengguna yang sudah terautentikasi mengakses halaman-halaman ini.

**Scenario 6: Multi-user privacy**

1. Daftarkan akun pengguna kedua dengan email yang berbeda.
2. Buat entri dengan akun baru ini.
3. Logout, lalu login dengan akun pertama.
4. Daftar entri seharusnya hanya menampilkan entri milik akun pertama. Entri milik pengguna kedua tidak boleh muncul sama sekali.

---

## Cara Kerja Login di Balik Layar {#how-login-works-behind-the-scenes}

Saat pengguna mengisi form login dan mengklik "Log In," berikut adalah urutan lengkap kejadiannya:

```
1. Browser sends POST /login
   { email: "budi@example.com", password: "secret123" }
         │
         ▼
2. Auth::attempt() finds the user by email
   then verifies the password with Hash::check()
         │
         ├── No match → redirect back with error message
         │
         └── Match → create session
                      Session ID stored on the server
                      Session ID sent to the browser as a cookie
         │
         ▼
3. Redirect to entries listing
   Every subsequent request carries the cookie,
   so Laravel knows which user is active
```

Pendekatan berbasis session berarti server mengingat siapa Anda di berbagai request. Browser menyimpan session cookie (sepotong kecil data yang berisi ID session), dan mengirimkannya secara otomatis dengan setiap request. Laravel membaca cookie tersebut, mencari session di server, dan mengambil pengguna yang terautentikasi. Inilah sebabnya mengapa Anda tetap login saat berpindah antar halaman dan mengapa menutup browser (yang menghapus cookie) mengharuskan Anda login kembali.

---

## Alur Aplikasi Secara Lengkap {#the-complete-application-flow}

Dengan autentikasi yang telah diimplementasikan sepenuhnya, berikut adalah gambaran lengkap bagaimana Catatku bekerja:

```
Guest opens Catatku
    │
    ├── Home page → click "Register" → registration form → logged in automatically
    ├── Home page → click "Log In" → login form → logged in after verification
    └── Tries to access /entries → redirected to /login

Logged-in user
    │
    ├── View own entries listing (only their entries, not anyone else's)
    ├── Read entry detail
    ├── Write new entry
    ├── Edit existing entry
    ├── Delete entry
    └── Logout → redirected to login page

Security
    ├── Guest cannot access /entries → redirect to login
    ├── User A cannot see User B's entries in the listing
    ├── User A cannot read User B's entry → 403
    ├── User A cannot edit User B's entry → 403
    └── User A cannot delete User B's entry → 403
```

Setiap fitur yang dijanjikan pada Lesson 1 kini telah berfungsi. Pengguna dapat registrasi, login, menulis entri, membacanya, memperbarui, menghapus, dan logout. Semuanya dengan keamanan yang tepat dan kode yang terstruktur dengan baik.

---

## Kesimpulan {#conclusion}

Sistem autentikasi untuk Catatku kini telah selesai. Berikut adalah poin-poin penting yang perlu diingat:

- `Auth::attempt($credentials)` menangani pencarian pengguna dan verifikasi password dalam satu pemanggilan. Ia mengembalikan `true` jika berhasil dan `false` jika gagal.
- **Regenerasi session** (`$request->session()->regenerate()`) setelah login mencegah serangan session fixation dengan mengganti ID session sehingga ID yang sebelumnya didapatkan menjadi tidak valid.
- Pesan error login sebaiknya **dibuat samar secara sengaja** ("The email or password you entered is incorrect") untuk mencegah penyerang mengetahui alamat email mana yang terdaftar di sistem Anda.
- `back()->withErrors([...])->onlyInput('email')` mengarahkan kembali ke form dengan pesan error sambil hanya mempertahankan nilai email. Password tidak pernah dikirim kembali ke browser.
- **Logout tiga langkah** sangat penting: `Auth::logout()` menghapus identitas pengguna, `session()->invalidate()` menghancurkan seluruh data session, dan `session()->regenerateToken()` membuat token CSRF baru.
- Logout harus menggunakan **route POST** (bukan GET) untuk mencegah serangan cross-site logout di mana situs jahat dapat membuat pengguna Anda logout tanpa sepengetahuan mereka.
- `->name('login')` pada route login diperlukan karena middleware `auth` Laravel mencari route dengan nama ini saat mengarahkan pengguna yang belum terautentikasi.
- `/entries` kini berada di dalam grup `middleware('auth')`, membuat daftar entri sepenuhnya privat. Tamu akan diarahkan ke halaman login.
- Method `index()` kini menggunakan **`auth()->user()->entries()->latest()->get()`** alih-alih `Entry::with('user')->latest()->get()`. Pada Lesson 6 hingga 9, kita menggunakan `Entry::with('user')` karena auth belum ada dan memanggil `auth()->user()` akan membuat crash. Sekarang setelah route mengharuskan autentikasi, kita dapat dengan aman membatasi query ke pengguna saat ini, memastikan setiap pengguna hanya melihat entri mereka sendiri.
- Middleware `guest` mencegah pengguna yang sudah login mengakses halaman registrasi dan login, karena mereka tidak memiliki alasan untuk melihat form-form tersebut.
- Helper `{{ url('/path') }}` menghasilkan URL lengkap dalam template Blade, yang kita gunakan untuk menghubungkan tombol navigasi pada halaman utama.

Pada lesson terakhir, kita tidak akan menambahkan fitur baru apa pun. Sebagai gantinya, kita akan mundur sejenak dan melihat keseluruhan perjalanan: apa yang telah kita bangun, pola apa yang muncul berulang kali, dan ke mana Anda dapat melangkah selanjutnya untuk terus berkembang sebagai developer Laravel.
