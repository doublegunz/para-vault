## 1. Sebelum Anda Memulai

API yang Anda bangun di Lesson 9 mengembalikan model Eloquent mentah sebagai JSON. Ini bekerja untuk prototype cepat, tetapi mengekspos setiap kolom di database, termasuk field internal yang mungkin tidak ingin Anda jadikan publik. Ia juga tidak menyediakan envelope yang konsisten atau strategi versioning. API Resource menyelesaikan ini dengan memberi Anda kendali penuh atas struktur JSON. Laravel Sanctum menyediakan authentication token yang ringan sehingga aplikasi mobile dan SPA dapat mengidentifikasi diri mereka ke API Anda tanpa cookie atau session.

Lesson ini mengubah API Catatku dari prototype cepat menjadi antarmuka kelas production. Anda akan membentuk output JSON dengan class Resource, sehingga respons berisi persis field yang Anda inginkan dalam persis format yang Anda inginkan. Anda akan mengimplementasikan login berbasis token sehingga client eksternal dapat melakukan authentication, menyimpan token dengan aman, dan membuat request yang terautentikasi. Di akhir, API Catatku akan konsisten, aman, dan siap dikonsumsi oleh aplikasi mobile atau SPA.

### What You'll Build

Anda akan membungkus setiap respons entri dalam sebuah `EntryResource`, membuat sebuah endpoint login yang menerbitkan token Sanctum, dan memperbarui route API untuk memerlukan token authentication.

### What You'll Learn

- ✅ API Resource dengan `make:resource`
- ✅ Resource collection dengan pagination
- ✅ Personal access token Sanctum
- ✅ Membuat token di endpoint login
- ✅ Melakukan authentication request dengan token `Bearer`
- ✅ Mencabut token saat logout

### What You'll Need

- Lesson 9 sudah selesai
- Sanctum sudah terinstal (perintah `install:api` melakukan ini di Lesson 9)

---

## 2. Membuat API Resource

Sebuah API Resource adalah class PHP yang mengubah sebuah model menjadi associative array. Method `toArray` mendefinisikan bentuk JSON. Pemisahan ini memungkinkan Anda mengembangkan skema database tanpa merusak kontrak API publik, karena Resource bertindak sebagai lapisan terjemahan di antara keduanya.

### Step 1: Membuat Entry Resource

Jalankan perintah Artisan berikut untuk membuat class Resource.

```bash
php artisan make:resource EntryResource
```

Perintah ini membuat `app/Http/Resources/EntryResource.php` dengan method kerangka `toArray`. Resource berada di namespace mereka sendiri agar tetap terorganisasi, dan file yang dihasilkan mewarisi dari `JsonResource` yang menyediakan logika serialisasi.

### Step 2: Mendefinisikan Bentuk Resource

Buka `app/Http/Resources/EntryResource.php` dan ganti kontennya dengan berikut.

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EntryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'excerpt' => $this->excerpt,
            'content' => $this->content,
            'cover_image_url' => $this->cover_image
                ? asset('storage/' . $this->cover_image)
                : null,
            'reading_time' => $this->reading_time,
            'author' => [
                'id' => $this->user->id,
                'name' => $this->user->name,
            ],
            'tags' => $this->whenLoaded('tags', function () {
                return $this->tags->map(fn ($tag) => [
                    'id' => $tag->id,
                    'name' => $tag->name,
                    'slug' => $tag->slug,
                ]);
            }),
            'comments_count' => $this->whenCounted('comments'),
            'created_at' => $this->created_at->toIso8601String(),
            'updated_at' => $this->updated_at->toIso8601String(),
        ];
    }
}
```

Mari kita telusuri resource ini field demi field. Method `toArray()` menerima sebuah objek `Request` (berguna ketika Anda ingin mengembalikan field yang berbeda untuk client yang berbeda) dan mengembalikan sebuah associative array yang menjadi respons JSON. Field `id`, `title`, dan `content` adalah pemetaan langsung dari model. Nilai `excerpt` dan `reading_time` berasal dari accessor yang Anda definisikan di Lesson 3, sehingga nilai yang dikomputasi disertakan secara gratis tanpa perhitungan manual apa pun di Resource.

Untuk `cover_image_url`, kita mengubah path relatif tersimpan menjadi URL publik lengkap ketika sebuah gambar ada, atau mengembalikan null jika tidak. Ini jauh lebih berguna bagi API client daripada path storage mentah, karena client membutuhkan URL lengkap untuk menampilkan gambar. Key `author` meratakan relationship user menjadi objek sederhana dengan hanya `id` dan `name`, dengan sengaja menyembunyikan field sensitif seperti `email` dan `password`.

Key `tags` menggunakan `$this->whenLoaded('tags', ...)`, yang merupakan helper kondisional: ia hanya menyertakan key ini jika relationship tags secara eksplisit di-eager-load di controller. Jika Anda lupa melakukan eager load, key tersebut hanya absen dari respons alih-alih memicu query lazy-loading selama serialisasi, yang akan menciptakan kembali masalah N+1. `whenCounted()` bekerja dengan cara yang sama untuk field `comments_count`: ia hanya muncul ketika `withCount('comments')` dipanggil. Timestamp menggunakan `toIso8601String()`, yang menghasilkan format ISO 8601 universal seperti `2026-04-17T10:30:45+00:00`, kompatibel dengan setiap timezone dan setiap API client.

### Step 3: Menggunakan Resource di Controller

Buka `app/Http/Controllers/Api/EntryController.php` dan tambahkan import `EntryResource` ke bagian atas file bersama statement `use` yang sudah ada. Lalu perbarui method `index`, `show`, dan `store` untuk membungkus respons mereka dalam Resource seperti ditunjukkan di bawah ini.

```php
<?php
// ... others lines of code
use App\Http\Resources\EntryResource;

class EntryController extends Controller
{
    // ... other methods

    public function index(Request $request): JsonResponse
    {
        $entries = Entry::with('tags', 'user')
            ->withCount('comments')
            ->latest()
            ->paginate(15);

        return response()->json(EntryResource::collection($entries));
    }

    public function show(Entry $entry): JsonResponse
    {
        $entry->load('tags', 'user', 'comments.user');
        $entry->loadCount('comments');

        return response()->json(new EntryResource($entry));
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'tags' => 'nullable|array',
            'tags.*' => 'exists:tags,id',
        ]);

        $entry = $request->user()->entries()->create([
            'title' => $validated['title'],
            'content' => $validated['content'],
        ]);

        $entry->tags()->sync($validated['tags'] ?? []);
        $entry->load('tags', 'user');
        $entry->loadCount('comments');

        return response()->json(new EntryResource($entry), 201);
    }

    // ... other methods
}
```

Menganalisis setiap perubahan: statement `use` mengimpor class Resource sehingga ia tersedia di setiap method. Di `index()`, `EntryResource::collection($entries)` membungkus setiap entri dalam koleksi dengan transformasi Resource, dan Laravel secara otomatis mempertahankan envelope pagination dalam output karena ia mendeteksi bahwa `$entries` adalah sebuah `LengthAwarePaginator`. Di `show()` dan `store()`, kita membungkus satu entri dengan `new EntryResource($entry)`. Perhatikan bahwa kita memanggil `loadCount('comments')` pada entri tunggal karena `withCount('comments')` hanya bekerja ketika membangun sebuah query; `loadCount` adalah method padanannya untuk memuat jumlah pada instance model yang sudah diambil.

---

## 3. Menyiapkan Authentication Sanctum

Laravel Sanctum terinstal secara otomatis ketika Anda menjalankan `install:api` di Lesson 9. Sekarang Anda perlu menyiapkan model User dan membuat sebuah endpoint login yang menerbitkan token. Sanctum menyediakan personal access token yang disimpan client dan dikirim bersama setiap request berikutnya.

### Step 1: Menambahkan Trait HasApiTokens

Buka `app/Models/User.php` dan tambahkan trait `HasApiTokens` ke statement `use` dan ke daftar trait di bagian atas class.

```php
<?php
// ... others lines of code
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    // ... other methods and properties
}
```

Trait `HasApiTokens` menambahkan tiga method ke model User: `createToken()` untuk menerbitkan token baru, `tokens()` untuk mengakses token user yang sudah ada sebagai sebuah relationship, dan `currentAccessToken()` untuk memeriksa token yang digunakan pada request saat ini. Di balik layar, token disimpan di tabel `personal_access_tokens` yang dibuat Sanctum selama langkah instalasinya, dengan field untuk nama token, nilai yang di-hash, scope ability, dan kedaluwarsa opsional. Melakukan hash pada token sebelum penyimpanan berarti pembobolan database tidak secara langsung mengekspos string token yang dapat digunakan.

### Step 2: Membuat Auth Controller

Buat file controller authentication.

```bash
php artisan make:controller Api/AuthController
```

Buka `app/Http/Controllers/Api/AuthController.php` dan ganti kontennya dengan berikut.

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
            'device_name' => 'required|string',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        $token = $user->createToken($validated['device_name'])->plainTextToken;

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
            'token' => $token,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(null, 204);
    }
}
```

Menguraikan controller ini dengan cermat: method `login` memvalidasi tiga field. `email` dan `password` adalah kredensial standar. `device_name` adalah label yang mengidentifikasi client yang memanggil, seperti "Alice's iPhone" atau "Acme Dashboard", yang berguna karena user nantinya dapat melihat dan mencabut token untuk setiap perangkat.

Setelah validasi, kita mencari user berdasarkan email. Jika user tidak ada atau hash password tidak cocok, kita melemparkan sebuah `ValidationException` dengan pesan generik. Menggunakan pesan yang sama untuk kedua kasus kegagalan mencegah account enumeration: seorang penyerang tidak dapat menentukan apakah sebuah email tertentu terdaftar berdasarkan pesan error. Baris yang krusial adalah `$user->createToken($validated['device_name'])->plainTextToken`. Method `createToken()` menyisipkan sebuah baris baru di `personal_access_tokens` dan mengembalikan sebuah objek dengan dua property: `accessToken` (record database) dan `plainTextToken` (string token yang sebenarnya, ditampilkan hanya sekali karena database menyimpan sebuah hash). Client harus menangkap dan menyimpan string ini segera; ia tidak dapat diambil lagi.

Di `logout()`, `$request->user()->currentAccessToken()->delete()` menghapus hanya token yang digunakan untuk request saat ini, bukan semua token user. Ini adalah perilaku yang benar: logout di satu perangkat seharusnya tidak membuat user logout di perangkat mereka yang lain.

### Step 3: Mendaftarkan Route Auth

Buka `routes/api.php` dan ganti kontennya dengan berikut, yang menambahkan import `AuthController`, sebuah route login publik, dan sebuah route logout di dalam group yang terautentikasi.

```php
<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\EntryController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/entries', [EntryController::class, 'index']);
Route::get('/entries/{entry}', [EntryController::class, 'show']);

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::post('/entries', [EntryController::class, 'store']);
    Route::put('/entries/{entry}', [EntryController::class, 'update']);
    Route::delete('/entries/{entry}', [EntryController::class, 'destroy']);
});
```

Endpoint `/login` bersifat publik sehingga client yang tidak terautentikasi dapat memperoleh sebuah token sejak awal. Semua endpoint tulis, termasuk logout, dilindungi oleh `auth:sanctum`. Route logout memerlukan authentication karena Anda perlu membuktikan identitas Anda agar server tahu token mana yang harus dicabut.

---

## 4. Menjalankan dan Menguji

Mari kita verifikasi alur authentication dan resource lengkap menggunakan perintah curl.

### Step 1: Memastikan Akun Test Ada

Sebelum memanggil endpoint login, Anda membutuhkan sebuah akun user di database. Jika Anda sudah mendaftar melalui form web Catatku di lesson sebelumnya, Anda dapat menggunakan kredensial tersebut di langkah berikutnya dan melewati yang ini.

Jika Anda memulai dari awal atau menginginkan akun test khusus, buat satu menggunakan Tinker.

```bash
php artisan tinker
```

Jalankan perintah berikut, lalu ketik `exit` untuk keluar dari Tinker.

```php
\App\Models\User::factory()->create([
    'name' => 'Admin',
    'email' => 'admin@example.com',
    'password' => bcrypt('password'),
]);
```

`User::factory()->create()` menyisipkan sebuah user baru menggunakan default factory, hanya menimpa field yang Anda tentukan. `bcrypt('password')` melakukan hash pada string teks polos menggunakan algoritma bcrypt, yang merupakan algoritma yang sama yang digunakan Laravel ketika user mendaftar melalui form web. Setelah menjalankan ini, user ada di database dan dapat melakukan authentication melalui form web maupun endpoint login API.

### Step 2: Login dan Mendapatkan Token

Kirim request login dengan kredensial dari langkah sebelumnya.

```bash
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "password",
    "device_name": "Test Device"
  }'
```

Respons seharusnya berupa sebuah objek JSON dengan info user dan sebuah field `token` yang berisi string panjang seperti `1|aB3dE5fG7hI9jK1lM3nO5pQ7rS9tU1vW3xY5zA7bC9dE1fG3hI`. Salin nilai token tersebut; Anda akan membutuhkannya untuk request berikutnya. Jika Anda melihat error validasi 422, verifikasi bahwa email cocok dengan user yang ada di database dan password-nya benar.

### Step 3: Membuat Entri dengan Token

Ganti `YOUR_TOKEN_HERE` dengan nilai token dari langkah sebelumnya.

```bash
curl -X POST http://localhost:8000/api/entries \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"title":"From API","content":"Hello API"}'
```

Header `Authorization: Bearer TOKEN` mengidentifikasi Anda ke API. Sanctum mencari token di database, menemukan user yang terkait, dan membuat user tersebut tersedia melalui `$request->user()` di controller. Respons seharusnya berupa entri yang baru dibuat yang dibungkus dalam bentuk `EntryResource` dengan kode status 201.

### Step 4: Memverifikasi Persistensi Token

Buat request terautentikasi lain, seperti endpoint list, menggunakan token yang sama untuk memverifikasi ia tetap valid di beberapa request.

```bash
curl -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  http://localhost:8000/api/entries
```

Token tidak kedaluwarsa secara default. Anda dapat mengonfigurasi kedaluwarsa dalam menit melalui key `expiration` di `config/sanctum.php`, tetapi default-nya adalah masa berlaku tak terbatas.

### Step 5: Logout dan Memverifikasi Pencabutan

Kirim request logout untuk menghapus token saat ini dari database.

```bash
curl -X POST http://localhost:8000/api/logout \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

Setelah logout, coba membuat sebuah entri menggunakan token yang sama. Request sekarang seharusnya mengembalikan 401 Unauthorized karena record token telah dihapus.

```bash
curl -X POST http://localhost:8000/api/entries \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"title":"After logout","content":"Should fail"}'
```

Anda seharusnya menerima respons 401 Unauthorized, mengonfirmasi bahwa logout dengan benar mencabut token.

### Step 6: Memeriksa Token di Tinker

Buka Tinker untuk memeriksa record token yang tersimpan di database.

```bash
php artisan tinker
```

Jalankan perintah berikut untuk melihat token aktif untuk user pertama.

```php
$user = \App\Models\User::first();
$user->tokens->count();
$user->tokens->pluck('name');
```

`$user->tokens->count()` mengembalikan jumlah token aktif yang tertaut ke user ini. `$user->tokens->pluck('name')` mengekstrak hanya kolom name, menunjukkan dari perangkat mana user memiliki session aktif. Ketik `exit` untuk keluar dari Tinker.

---

## 5. Memperbaiki Error pada Kode Anda

Berikut adalah kesalahan paling umum saat mengimplementasikan API Resource dan authentication Sanctum.

**Error 1: Mencoba membaca token teks polos setelah request selesai.**

Error ini terjadi ketika seorang developer membuat sebuah token di satu request lalu mencoba mengambil nilai teks polos dari database di request selanjutnya. Sanctum melakukan hash pada token sebelum menyimpannya, sehingga nilai teks polos hanya tersedia segera setelah memanggil `createToken()`.

```php
// Wrong: capturing the token object and trying to read plainTextToken later
$tokenObject = $user->createToken('api');
// ... other code ...
$plainText = $tokenObject->plainTextToken; // Still works in the same request

// Also wrong: trying to read from the database after the request
$storedPlainText = $user->fresh()->tokens->first()->plainTextToken; // null - only hash stored

// Correct: capture plainTextToken immediately and include it in the response
$token = $user->createToken('device_name')->plainTextToken;
return response()->json(['token' => $token]);
```

Versi yang salah menunda pembacaan `plainTextToken`, atau mencoba mengambilnya dari database, di mana hanya nilai yang di-hash yang tersimpan. Client yang kehilangan token mereka tidak dapat memulihkannya dari API; mereka harus login lagi untuk memperoleh yang baru. Versi yang benar menangkap `plainTextToken` segera dari nilai return `createToken()` dan menyertakannya di respons saat ini.

---

**Error 2: Mengirim header Authorization tanpa prefix `Bearer`.**

Error ini terjadi ketika seorang client mengirim nilai token saja di header Authorization, menghilangkan prefix `Bearer ` yang diperlukan. Sanctum mengharapkan format HTTP Bearer token standar.

```bash
# Wrong: token sent without the Bearer prefix
Authorization: abc123def456

# Correct: token sent with the required Bearer prefix and a space
Authorization: Bearer abc123def456
```

Tanpa prefix `Bearer`, Sanctum tidak mengenali header sebagai sebuah token dan memperlakukan request sebagai tidak terautentikasi, mengembalikan respons 401 meskipun token yang valid disediakan. Format header adalah `Authorization: Bearer <token>` dengan B kapital, kata Bearer, satu spasi, lalu nilai token.

---

**Error 3: Mengakses sebuah relationship di Resource tanpa `whenLoaded()`, menyebabkan lazy loading.**

Error ini terjadi ketika sebuah Resource langsung mengakses sebuah relationship seperti `$this->tags->map(...)` tanpa memeriksa apakah relationship tersebut di-eager-load. Jika relationship tidak dimuat, Eloquent menjalankan sebuah query untuk setiap item dalam koleksi, menciptakan kembali masalah N+1 di dalam serialisasi.

```php
// Wrong: direct relationship access triggers a query if not eager loaded
public function toArray(Request $request): array
{
    return [
        'tags' => $this->tags->map(fn ($tag) => ['name' => $tag->name]),
    ];
}

// Correct: whenLoaded() omits the key entirely if not eager loaded
public function toArray(Request $request): array
{
    return [
        'tags' => $this->whenLoaded('tags', fn () => $this->tags->map(
            fn ($tag) => ['name' => $tag->name]
        )),
    ];
}
```

Versi yang salah mengakses `$this->tags` secara langsung. Jika 50 entri sedang diserialisasi dan tag tidak di-eager-load, Eloquent menjalankan 50 query `SELECT * FROM tags WHERE entry_id = ?` individual. Versi yang benar menggunakan `whenLoaded('tags', ...)`, yang mengembalikan `MissingValue` (sebuah sentinel yang dikecualikan Laravel dari output JSON) ketika relationship tidak dimuat. Selalu lakukan eager load di controller dan gunakan `whenLoaded` di Resource.

---

## 6. Latihan

Latihan ini memperkuat dua keterampilan utama dari lesson ini: membentuk output JSON melalui Resource dan mengendalikan akses melalui ability token Sanctum. Latihan 1 harus diselesaikan sebelum Latihan 2, karena `UserResource` yang dibuat di Latihan 1 digunakan di endpoint `/api/me` di Latihan 2.

**Latihan 1:** Buat sebuah `UserResource` yang hanya mengembalikan `id`, `name`, dan `created_at` (diformat sebagai ISO 8601), dengan sengaja menghilangkan `email` dan field privat lainnya. Gunakan ia di `EntryResource` untuk menggantikan array `author` inline.

**Latihan 2:** Tambahkan sebuah endpoint `/api/me` yang mengembalikan data user yang terautentikasi yang dibungkus dalam `UserResource`. Lindungi dengan middleware `auth:sanctum`.

**Latihan 3:** Tambahkan ability ke token saat dibuat: `$user->createToken('api', ['entries:write'])`. Periksa ability di route dengan `middleware('abilities:entries:write')`.

---

## 7. Solusi

Setiap solusi di bawah ini dibangun di atas yang sebelumnya. Selesaikan Latihan 1 terlebih dahulu sehingga `UserResource` tersedia saat mengimplementasikan endpoint `/api/me` di Latihan 2.

**Solusi untuk Latihan 1:**

Buat file UserResource.

```bash
php artisan make:resource UserResource
```

Buka `app/Http/Resources/UserResource.php` dan definisikan bentuknya.

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'joined_at' => $this->created_at->toIso8601String(),
        ];
    }
}
```

Resource ini mengekspos tiga field: `id`, `name`, dan `joined_at` (sebuah `created_at` yang diganti namanya dengan pemformatan ISO 8601). Field `email` dan `password` dengan sengaja absen, memastikan keduanya tidak akan pernah secara tidak sengaja bocor melalui permukaan API ini. Perbarui `EntryResource` untuk menggunakannya pada field `author`.

```php
use App\Http\Resources\UserResource;

'author' => new UserResource($this->whenLoaded('user')),
```

Meneruskan `$this->whenLoaded('user')` alih-alih `$this->user` memastikan field author hanya disertakan ketika relationship user di-eager-load di controller, mempertahankan keamanan N+1 yang sama seperti `whenLoaded` pada relationship lain.

---

**Solusi untuk Latihan 2:**

Buka `app/Http/Controllers/Api/AuthController.php` dan tambahkan import `UserResource` ke bagian atas file bersama statement `use` yang sudah ada, lalu tambahkan method `me` setelah method `logout` yang sudah ada.

```php
<?php
// ... others lines of code
use App\Http\Resources\UserResource;

class AuthController extends Controller
{
    // ... other methods

    public function me(Request $request): JsonResponse
    {
        return response()->json(new UserResource($request->user()));
    }
}
```

`$request->user()` mengembalikan user terautentikasi yang diresolusi dari token Sanctum pada request saat ini. Membungkusnya dalam `new UserResource(...)` menerapkan pembentukan field yang sama yang didefinisikan di Latihan 1, sehingga respons hanya mengekspos `id`, `name`, dan `joined_at` tanpa membocorkan `email` atau attribute privat lainnya. Daftarkan route di `routes/api.php` di dalam group middleware `auth:sanctum`.

```php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // ... existing entry routes
});
```

Uji endpoint dengan mengirim sebuah request GET dengan bearer token yang valid.

```bash
curl -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  http://localhost:8000/api/me
```

Respons seharusnya berupa bentuk `UserResource` dengan hanya tiga field yang diizinkan. Jika Anda menerima 401, verifikasi bahwa token valid dan bahwa header `Authorization` menyertakan prefix `Bearer`.

---

**Solusi untuk Latihan 3:**

Buka `app/Http/Controllers/Api/AuthController.php` dan perbarui method `login` untuk meneruskan ability sebagai argumen kedua ke `createToken()`. Perubahan ada pada baris `createToken()`; segala sesuatu yang lain di method tetap sama.

```php
<?php
// ... others lines of code

class AuthController extends Controller
{
    // ... other methods

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
            'device_name' => 'required|string',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        $token = $user->createToken($validated['device_name'], ['entries:write'])->plainTextToken;

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
            'token' => $token,
        ]);
    }

    // ... other methods
}
```

Argumen kedua untuk `createToken()` adalah sebuah array berisi string ability. Sebuah token yang menyertakan `entries:write` diizinkan untuk melakukan operasi tulis pada entri. Sebuah token yang dibuat tanpa ability ini, atau dengan kumpulan ability yang berbeda, akan ditolak ketika ia mengenai sebuah route yang dijaga oleh middleware `abilities`. Perbarui `routes/api.php` untuk menambahkan middleware ability ke route tulis.

```php
Route::middleware(['auth:sanctum', 'abilities:entries:write'])->group(function () {
    Route::post('/entries', [EntryController::class, 'store']);
    Route::put('/entries/{entry}', [EntryController::class, 'update']);
    Route::delete('/entries/{entry}', [EntryController::class, 'destroy']);
});
```

`abilities:entries:write` adalah middleware bawaan Sanctum yang memeriksa apakah daftar ability token saat ini menyertakan `entries:write`. Jika token dibuat tanpa ability tersebut, middleware menolak request dengan respons 403 Forbidden sebelum method controller dijalankan. Pola scoping ini berguna ketika Anda ingin menerbitkan token hanya-baca ke client tertentu dan token tulis ke yang lain, semuanya dari endpoint login yang sama dengan memvariasikan array ability.

---

## Selanjutnya - Lesson 11

Di lesson ini Anda meningkatkan API Catatku dari prototype Eloquent mentah menjadi antarmuka yang terbentuk dengan baik dan terautentikasi. Anda membuat `EntryResource` dengan `whenLoaded()` dan `whenCounted()` untuk menghasilkan JSON konsisten yang tidak pernah memicu query lazy-loading. Anda menambahkan trait `HasApiTokens` ke model User dan membangun sebuah `AuthController` dengan method login dan logout. Login menerbitkan sebuah personal access token Sanctum yang disimpan client dan dikirim sebagai header `Bearer` pada setiap request yang terautentikasi. Logout menghapus hanya token saat ini, membiarkan session perangkat lain tidak tersentuh.

Di Lesson 11, Anda akan mempelajari feature testing dengan Pest: bagaimana menulis test yang menyimulasikan browser yang memverifikasi aplikasi Anda bekerja dari awal hingga akhir, menggunakan factory, isolasi database, dan helper authentication untuk menulis test suite yang cepat dan andal.
