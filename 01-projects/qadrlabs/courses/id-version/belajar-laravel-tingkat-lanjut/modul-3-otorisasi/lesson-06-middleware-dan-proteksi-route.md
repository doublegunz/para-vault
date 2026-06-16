## 1. Sebelum Anda Memulai

Middleware adalah kode yang berjalan sebelum (atau sesudah) sebuah request mencapai controller Anda. Anda sudah menggunakan middleware `auth` dari course pemula untuk memastikan user sudah login. Di lesson ini, Anda akan memahami bagaimana middleware pipeline bekerja, membuat custom middleware Anda sendiri, dan mengorganisasi route ke dalam group dengan middleware bersama.

Middleware bertindak sebagai serangkaian filter untuk HTTP request. Setiap middleware dapat memeriksa request, memodifikasinya, atau menolaknya sepenuhnya sebelum mencapai controller. Middleware bawaan Laravel menangani authentication, proteksi CSRF, dan rate limiting. Anda dapat membuat custom middleware untuk logika spesifik aplikasi apa pun. Di akhir lesson ini, Catatku akan mencatat setiap request yang terautentikasi, membatasi laju komentar untuk mencegah spam, dan mengorganisasi route-nya dengan rapi ke dalam group.

### What You'll Build

Anda akan membuat custom middleware yang mencatat informasi request, mengorganisasi route Catatku ke dalam group middleware yang rapi, dan menerapkan rate limiting ke route pembuatan komentar.

### What You'll Learn

- ✅ Bagaimana middleware pipeline bekerja
- ✅ Membuat custom middleware dengan `make:middleware`
- ✅ Mendaftarkan alias middleware
- ✅ Menerapkan middleware ke route dan group
- ✅ Middleware bawaan: `auth`, `guest`, `throttle`
- ✅ Rate limiting pada route tertentu

### What You'll Need

- Lesson 5 sudah selesai dengan authorization

---

## 2. Memahami Middleware Pipeline

Ketika sebuah request tiba di aplikasi Laravel Anda, ia melewati serangkaian middleware sebelum mencapai controller. Setiap middleware dapat melakukan salah satu dari tiga hal: meneruskan request ke middleware berikutnya, memodifikasi request sebelum meneruskannya, atau menolak request sepenuhnya dengan mengembalikan sebuah respons atau melakukan redirect.

Anggaplah ini sebagai checkpoint keamanan di sebuah gedung. Penjaga pertama memeriksa ID Anda (middleware authentication). Yang kedua memeriksa badge Anda (middleware authorization). Yang ketiga mencatat waktu masuk Anda (middleware logging). Jika Anda gagal di pemeriksaan mana pun, Anda diputar balik sebelum mencapai tujuan. Jika Anda lolos semua pemeriksaan, Anda mencapai controller. Pola yang sama melindungi aplikasi Anda: setiap middleware menangani satu kepentingan, dan bersama-sama mereka membentuk sebuah pipeline yang harus dilalui setiap request.

---

## 3. Membuat Custom Middleware

Di section ini Anda akan membuat custom middleware logging dan mendaftarkannya sehingga Anda dapat menerapkannya ke route berdasarkan nama.

### Step 1: Membuat Middleware

Jalankan perintah Artisan berikut untuk membuat file middleware.

```bash
php artisan make:middleware LogRequest
```

Perintah ini membuat `app/Http/Middleware/LogRequest.php` dengan method kerangka `handle()` yang akan Anda isi berikutnya.

### Step 2: Menulis Logika Middleware

Buka `app/Http/Middleware/LogRequest.php` dan ganti kontennya dengan berikut.

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class LogRequest
{
    public function handle(Request $request, Closure $next): Response
    {
        $start = microtime(true);

        $response = $next($request);

        $duration = round((microtime(true) - $start) * 1000, 2);

        Log::info('Request processed', [
            'method' => $request->method(),
            'url' => $request->fullUrl(),
            'user' => $request->user()?->id,
            'status' => $response->getStatusCode(),
            'duration_ms' => $duration,
        ]);

        return $response;
    }
}
```

Mari kita telusuri middleware langkah demi langkah. Statement `use` mengimpor empat class: `Closure` untuk callable `$next`, `Request` untuk HTTP request yang masuk, `Log` untuk menulis ke file log Laravel, dan `Response` untuk return type. Method `handle()` adalah entry point yang harus diimplementasikan setiap middleware.

`$start = microtime(true)` menangkap waktu saat ini dalam detik dengan presisi mikrodetik sebelum apa pun yang lain dijalankan. Baris `$response = $next($request)` adalah yang paling penting: ia meneruskan request ke middleware berikutnya dalam pipeline, dan akhirnya ke controller. Apa pun yang dikembalikan controller kembali ke sini sebagai respons. Tanpa memanggil `$next($request)`, request tidak akan pernah mencapai controller dan user akan melihat halaman kosong.

Setelah `$next($request)` mengembalikan nilai, kita berada dalam mode "after". `$duration = round((microtime(true) - $start) * 1000, 2)` menghitung milidetik yang berlalu dengan mengurangi waktu mulai dari waktu saat ini, mengalikan dengan 1000 untuk mengonversi detik ke milidetik, dan membulatkan ke 2 angka desimal. `Log::info('Request processed', [...])` menulis entri log terstruktur dengan lima field: method HTTP, URL lengkap, ID user yang terautentikasi (menggunakan operator null-safe `?->` jika user tidak login), kode status respons HTTP, dan durasi. Akhirnya, kita mengembalikan `$response` sehingga ia melanjutkan kembali ke atas pipeline menuju browser. Middleware tunggal ini mendemonstrasikan baik perilaku "before" (memulai penghitungan waktu) maupun perilaku "after" (mencatat hasil yang sudah selesai).

### Step 3: Mendaftarkan Middleware

Buka `bootstrap/app.php` dan tambahkan pendaftaran alias di dalam closure `withMiddleware()` yang **sudah ada**; jangan tambahkan pemanggilan `withMiddleware()` kedua.

```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'log.request' => \App\Http\Middleware\LogRequest::class,
    ]);
})
```

Langkah pendaftaran ini diperlukan karena Laravel perlu mengetahui tentang middleware Anda sebelum Anda dapat mereferensikannya berdasarkan nama di route. Closure `withMiddleware()` sudah ada di `bootstrap/app.php` dan awalnya kosong. Pemanggilan `alias()` memetakan nama pendek `log.request` ke nama class yang sepenuhnya berkualifikasi. Tanpa alias ini, upaya menggunakan `log.request` dalam definisi route akan melemparkan error "target class not found".

---

## 4. Mengorganisasi Route dengan Group Middleware

Buka `routes/web.php` dan buat dua perubahan pada file yang ada: tambahkan `'log.request'` ke group middleware `auth`, dan ganti tujuh route entri individual dengan satu pemanggilan `Route::resource()`. Ganti seluruh konten file dengan berikut.

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EntryController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\TagController;
use App\Http\Controllers\CommentController;

Route::get('/', function () {
    return view('home');
});

Route::middleware('guest')->group(function () {
    Route::get('/register', [AuthController::class, 'showRegister']);
    Route::post('/register', [AuthController::class, 'register']);

    Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AuthController::class, 'login']);
});

Route::middleware(['auth', 'log.request'])->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/entries/trash', [EntryController::class, 'trash'])->name('entries.trash');
    Route::resource('entries', EntryController::class);
    Route::patch('/entries/{entry}/restore', [EntryController::class, 'restore'])
        ->name('entries.restore')
        ->withTrashed();

    Route::post('/entries/{entry}/comments', [CommentController::class, 'store'])
        ->name('comments.store')
        ->middleware('throttle:10,1');
    Route::delete('/comments/{comment}', [CommentController::class, 'destroy'])->name('comments.destroy');

    Route::get('/tags', [TagController::class, 'index'])->name('tags.index');
    Route::get('/tags/{tag:slug}', [TagController::class, 'show'])->name('tags.show');
});
```

Ada dua perubahan yang berarti dari lesson sebelumnya. Pertama, group middleware sekarang berbunyi `['auth', 'log.request']`; menambahkan `log.request` di samping `auth` sehingga setiap request yang terautentikasi dicatat secara otomatis. Kedua, tujuh route entri individual (index, create, store, show, edit, update, destroy) diganti oleh `Route::resource('entries', EntryController::class)`, yang menghasilkan ketujuhnya dengan nama route yang identik dalam satu baris. Segala sesuatu yang lain dibawa dari lesson sebelumnya dan hanya dikelompokkan di sini di bawah middleware baru: group guest dan logout dari course pemula, route `comments.store`/`comments.destroy` dan `CommentController` dari Lesson 1, dan route `tags.index`/`tags.show` serta `TagController` dari Lesson 2. Pastikan controller-controller tersebut ada (mereka dibangun di body Lesson 1 dan 2) sebelum memuat ulang aplikasi, atau file route akan gagal meresolusinya.

Perhatikan bahwa `Route::get('/entries/trash', ...)` ditempatkan **sebelum** `Route::resource('entries', ...)`. Alasannya adalah `Route::resource()` secara internal mendaftarkan `GET /entries/{entry}` sebagai route show. Laravel mencocokkan route dalam urutan pendaftaran, jadi jika route trash ditempatkan setelah resource, mengunjungi `/entries/trash` akan cocok dengan `{entry}=trash` dan memanggil `show()` alih-alih `trash()`. Menempatkan route literal lebih dulu memastikan ia menang sebelum wildcard dievaluasi.

Route store komentar menerima middleware inline tambahan: `->middleware('throttle:10,1')` membatasi setiap user maksimal 10 pengiriman komentar per menit. Menumpuk middleware tambahan pada route tertentu tidak memengaruhi route lain dalam group; `auth` dan `log.request` tingkat group tetap berlaku untuk semuanya.

---

## 5. Menjalankan dan Menguji

Mari kita verifikasi ketiga aspek lesson ini - logging, rate limiting, dan proteksi route - berfungsi dengan benar.

### Step 1: Menguji Logging Middleware

Jalankan development server.

```bash
php artisan serve
```

Kunjungi `http://localhost:8000/entries` di browser saat sedang login. Lalu buka `storage/logs/laravel.log` di editor atau terminal Anda dan lihat baris terakhir. Anda akan melihat entri log mirip dengan berikut.

```
[2026-04-17 10:30:45] local.INFO: Request processed {"method":"GET","url":"http://localhost:8000/entries","user":1,"status":200,"duration_ms":45.23}
```

Ini mengonfirmasi middleware berjalan pada setiap request di dalam group yang terautentikasi. Field-nya mencakup persis apa yang kita catat: method HTTP, URL lengkap, ID user, kode status respons, dan durasi dalam milidetik.

### Step 2: Menguji Rate Limiting

Navigasikan ke halaman detail sebuah entri dan kirim lebih dari 10 komentar dalam satu menit. Setelah komentar kesepuluh, Anda akan melihat halaman error 429 Too Many Requests. Tunggu satu menit dan coba lagi; pengiriman seharusnya berhasil. Middleware `throttle` melacak request per user menggunakan cache Laravel dan secara otomatis menolak request begitu batas terlampaui, mengembalikan header `Retry-After` sehingga client tahu kapan harus mencoba lagi.

### Step 3: Menguji Proteksi Route

Logout dan coba mengakses `/entries` secara langsung dengan mengetik URL di browser. Anda seharusnya diarahkan ke halaman login oleh middleware `auth`. Ini mengonfirmasi bahwa user yang tidak terautentikasi tidak dapat melewati alur login hanya dengan mengetahui sebuah URL.

### Step 4: Memverifikasi Urutan Middleware

Buka `storage/logs/laravel.log` dan konfirmasi bahwa request dari user yang tidak terautentikasi tidak menghasilkan entri `log.request`. Ini karena middleware `auth` berjalan lebih dulu dalam array group dan menolak request sebelum `log.request` pernah berjalan. Middleware dalam array group dieksekusi dalam urutan dari kiri ke kanan, dan middleware pertama yang menolak sebuah request menghentikan pipeline sepenuhnya.

---

## 6. Memperbaiki Error pada Kode Anda

Berikut adalah kesalahan paling umum saat membuat dan menerapkan middleware di Laravel.

**Error 1: Middleware membuat loop redirect tak terbatas.**

Error ini terjadi ketika sebuah middleware mengarahkan user ke sebuah route yang juga dilindungi oleh middleware yang sama. User diarahkan, route tersebut menjalankan middleware lagi, middleware mengarahkan lagi, dan siklus berulang hingga browser melaporkan "Too many redirects".

```php
// Wrong: ProfileSetup middleware redirects to /profile/setup,
// but that route also uses ProfileSetup middleware
public function handle(Request $request, Closure $next): Response
{
    if (!$request->user()->hasProfile()) {
        return redirect('/profile/setup');
    }
    return $next($request);
}

// Correct: exclude the destination route from the middleware check
public function handle(Request $request, Closure $next): Response
{
    if (!$request->user()->hasProfile() && $request->path() !== 'profile/setup') {
        return redirect('/profile/setup');
    }
    return $next($request);
}
```

Versi yang salah melakukan redirect tanpa syarat, jadi ketika user tiba di `/profile/setup`, middleware berjalan lagi, mengarahkan lagi, dan loop tidak pernah berakhir. Versi yang benar menambahkan pemeriksaan path dengan `$request->path() !== 'profile/setup'` untuk melewati redirect ketika user sudah berada di route tujuan. Sebagai alternatif, Anda dapat mengecualikan route tertentu dari middleware menggunakan `$middleware->except(['profile.setup'])` di pendaftaran.

---

**Error 2: Lupa mengembalikan `$next($request)`.**

Ini adalah kesalahan middleware paling kritis. Jika Anda lupa mengembalikan hasil dari `$next($request)`, request tidak pernah mencapai controller dan browser menerima respons kosong.

```php
// Wrong: $next($request) is called but its result is not returned
public function handle(Request $request, Closure $next): Response
{
    Log::info('Request received');
    $next($request);
}

// Correct: always return the result of $next($request)
public function handle(Request $request, Closure $next): Response
{
    Log::info('Request received');
    return $next($request);
}
```

Pada versi yang salah, `$next($request)` dipanggil dan controller berjalan, tetapi respons dibuang karena method `handle` tidak pernah mengembalikannya. Browser menerima respons null atau kosong. Versi yang benar mengembalikan hasil dari `$next($request)`, yang meneruskan respons kembali ke atas rantai menuju browser. Ini tidak opsional: selalu kembalikan hasilnya.

---

**Error 3: Menggunakan alias middleware yang tidak pernah didaftarkan.**

Error ini terjadi ketika Anda mereferensikan sebuah middleware berdasarkan nama pendek dalam definisi route tetapi lupa mendaftarkan alias-nya. Laravel tidak memiliki cara untuk memetakan string ke sebuah class.

```php
// Wrong: log.request used in route but not registered as an alias
Route::middleware('log.request')->group(function () {
    Route::resource('entries', EntryController::class);
});

// Correct: register the alias first in bootstrap/app.php
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'log.request' => \App\Http\Middleware\LogRequest::class,
    ]);
})
```

Versi yang salah menggunakan `'log.request'` di route, tetapi tanpa alias yang terdaftar, Laravel tidak tahu class apa yang harus diinstansiasi dan melemparkan "Target class [log.request] does not exist". Versi yang benar mendaftarkan alias terlebih dahulu di `bootstrap/app.php` sehingga Laravel dapat meresolusi string ke class middleware yang benar saat memproses route.

---

## 7. Latihan

Latihan ini mengembangkan pola middleware dari lesson ini ke bagian lain dari Catatku. Masing-masing memerlukan pembuatan atau modifikasi middleware secara mandiri, memberi Anda latihan menerapkan konsep pipeline tanpa panduan langkah demi langkah.

**Latihan 1:** Buat sebuah middleware `AdminOnly` yang memeriksa apakah user memiliki `is_admin = true` dan mengembalikan 403 jika tidak. Terapkan ke sebuah group route admin.

**Latihan 2:** Buat sebuah middleware `TrackLastActivity` yang memperbarui kolom `last_active_at` user pada setiap request. Tambahkan migration kolomnya terlebih dahulu.

**Latihan 3:** Terapkan `throttle:5,1` ke route `store` entri untuk membatasi pembuatan entri menjadi 5 per menit. Uji dengan mengirim form create secara cepat.

---

## 8. Solusi

Setiap solusi di bawah ini adalah implementasi lengkap yang dapat Anda terapkan langsung ke Catatku. Perhatikan di mana middleware didaftarkan dan bagaimana ia terhubung ke route, karena kedua langkah itu sama-sama diperlukan agar middleware berlaku.

**Solusi untuk Latihan 1:**

Buat file middleware dengan Artisan.

```bash
php artisan make:middleware AdminOnly
```

Buka `app/Http/Middleware/AdminOnly.php` dan tulis logikanya.

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AdminOnly
{
    public function handle(Request $request, Closure $next): Response
    {
        if (!$request->user()?->is_admin) {
            abort(403, 'Admin access required.');
        }
        return $next($request);
    }
}
```

Di `bootstrap/app.php`, tambahkan alias `admin.only` di dalam closure `withMiddleware()` yang sudah ada bersama `log.request`.

```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'log.request' => \App\Http\Middleware\LogRequest::class,
        'admin.only'  => \App\Http\Middleware\AdminOnly::class,
    ]);
})
```

Lalu terapkan alias ke sebuah group route admin di `routes/web.php`.

```php
Route::middleware(['auth', 'admin.only'])->prefix('admin')->group(function () {
    Route::get('/dashboard', [AdminController::class, 'index'])->name('admin.dashboard');
});
```

Fungsi `abort(403)` melemparkan exception HTTP yang merender halaman error 403. Operator null-safe `?->` mencegah fatal error ketika user tidak terautentikasi; ekspresi memotong menjadi `null`, yang bernilai falsy, menyebabkan abort dijalankan. Pemanggilan `$next($request)` hanya dicapai jika user lolos pemeriksaan admin.

---

**Solusi untuk Latihan 2:**

Buat dan jalankan migration untuk menambahkan kolom `last_active_at`.

```bash
php artisan make:migration add_last_active_at_to_users --table=users
```

Di file migration, tambahkan definisi kolom.

```php
public function up(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->timestamp('last_active_at')->nullable();
    });
}

public function down(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->dropColumn('last_active_at');
    });
}
```

`$table->timestamp('last_active_at')->nullable()` menambahkan kolom TIMESTAMP yang menerima NULL sebagai nilai default-nya. Nullable diperlukan di sini karena user yang sudah ada di database belum memiliki activity timestamp, sehingga kolom harus mengizinkan NULL sampai mereka membuat request pertama mereka setelah migration dijalankan. Method `down()` menghapus kolom jika Anda melakukan rollback. Jalankan migration dengan `php artisan migrate`, lalu buat file middleware.

```bash
php artisan make:middleware TrackLastActivity
```

Perintah ini membuat `app/Http/Middleware/TrackLastActivity.php` dengan method `handle()` kosong. Buka dan ganti konten file dengan berikut.

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class TrackLastActivity
{
    public function handle(Request $request, Closure $next): Response
    {
        if ($request->user()) {
            $request->user()->update(['last_active_at' => now()]);
        }

        return $next($request);
    }
}
```

Guard `if ($request->user())` mencegah update dijalankan untuk user yang tidak terautentikasi. `$request->user()->update(['last_active_at' => now()])` menulis timestamp saat ini ke database. Daftarkan alias middleware dan tambahkan ke group route yang terautentikasi. Untuk performa, Anda mungkin ingin menambahkan pemeriksaan cache sehingga database hanya diperbarui sekali per menit alih-alih pada setiap tampilan halaman.

---

**Solusi untuk Latihan 3:**

Buka `routes/web.php` dan pisahkan route `store` dari macro `Route::resource()` sehingga Anda dapat menambahkan middleware throttle padanya secara independen. Pertahankan `Route::get('/entries/trash', ...)` sebelum resource untuk menjaga urutan route yang benar.

```php
Route::middleware(['auth', 'log.request'])->group(function () {
    Route::get('/entries/trash', [EntryController::class, 'trash'])->name('entries.trash');

    Route::resource('entries', EntryController::class)->except(['store']);

    Route::post('/entries', [EntryController::class, 'store'])
        ->name('entries.store')
        ->middleware('throttle:5,1');

    Route::patch('/entries/{entry}/restore', [EntryController::class, 'restore'])
        ->name('entries.restore')
        ->withTrashed();

    Route::post('/entries/{entry}/comments', [CommentController::class, 'store'])
        ->name('comments.store')
        ->middleware('throttle:10,1');
});
```

Pemanggilan `->except(['store'])` menghapus route POST `/entries` yang biasanya dihasilkan `Route::resource()`, membebaskan Anda untuk mendefinisikannya ulang secara manual di baris berikutnya dengan middleware `throttle:5,1` tambahan. Tanpa `except(['store'])`, dua route akan cocok dengan URL dan method yang sama, yang menyebabkan perilaku tidak terduga. Named route `entries.store` harus cocok dengan apa yang akan dihasilkan macro resource sehingga action form dan pemanggilan `route()` yang ada di view Anda terus berfungsi tanpa perubahan. Untuk menguji, kirim form pembuatan entri enam kali atau lebih dalam satu menit dan konfirmasi upaya keenam mengembalikan respons 429 Too Many Requests.

---

## Selanjutnya - Lesson 7

Di lesson ini Anda mempelajari bagaimana middleware pipeline memfilter HTTP request sebelum mereka mencapai controller. Anda membuat custom middleware `LogRequest` yang mendemonstrasikan perilaku "before" dan "after": menangkap sebuah timestamp sebelum meneruskan request dan menulis entri log terstruktur setelah controller mengembalikan nilai. Anda mengorganisasi route Catatku ke dalam group terautentikasi yang rapi dengan middleware bersama, dan menerapkan `throttle:10,1` ke route pembuatan komentar untuk mencegah spam. Anda juga mempelajari tiga aturan paling kritis: selalu daftarkan alias middleware sebelum menggunakannya, selalu kembalikan `$next($request)`, dan selalu kecualikan tujuan redirect saat menolak request.

Di Lesson 7, Anda akan mempelajari file upload dan storage: bagaimana menambahkan upload gambar sampul ke entri Catatku menggunakan facade Storage Laravel, memvalidasi tipe dan ukuran file, dan menampilkan gambar yang diupload di view.
