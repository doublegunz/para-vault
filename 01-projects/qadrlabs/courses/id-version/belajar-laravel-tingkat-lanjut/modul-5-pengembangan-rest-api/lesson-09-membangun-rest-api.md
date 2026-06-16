## 1. Sebelum Anda Memulai

Aplikasi web sering kali bukan satu-satunya cara user berinteraksi dengan data Anda. Sebuah aplikasi mobile, sebuah desktop client, sebuah single-page application (SPA), dan sistem lain mungkin semuanya membutuhkan akses. Sebuah REST API menyediakan cara yang terstandardisasi untuk mengekspos data melalui HTTP menggunakan JSON. Lesson ini mengajarkan Anda membangun endpoint API untuk Catatku yang mengembalikan respons JSON, yang dapat dikonsumsi aplikasi lain secara programatik.

REST adalah singkatan dari Representational State Transfer. Ia adalah seperangkat konvensi untuk mendesain API: gunakan HTTP verb (GET, POST, PUT, DELETE) untuk aksi, gunakan URL untuk mengidentifikasi resource, dan pertukarkan data sebagai JSON. Laravel memiliki dukungan kelas satu untuk membangun REST API, termasuk file `routes/api.php` terpisah, pemformatan JSON otomatis untuk respons, dan penanganan exception bawaan yang mengembalikan kode status HTTP yang sesuai. Di akhir lesson ini, Catatku akan memiliki sebuah JSON API yang berfungsi yang mengembalikan entri dan memungkinkan client eksternal membuat entri baru.

### What You'll Build

Anda akan membuat endpoint JSON untuk menampilkan daftar entri, menampilkan satu entri, membuat entri, memperbarui entri, dan menghapus entri. Anda akan mengujinya dengan `curl` atau Postman.

### What You'll Learn

- ✅ Konvensi REST dan HTTP verb
- ✅ File `routes/api.php` dan prefix API
- ✅ Mengembalikan respons JSON
- ✅ Kode status HTTP: 200, 201, 204, 404, 422
- ✅ Memvalidasi input JSON
- ✅ Menggunakan `abort` dan penanganan exception untuk error API

### What You'll Need

- Lesson 8 sudah selesai
- Sebuah tool untuk menguji API: `curl`, Postman, atau browser Anda untuk request GET

---

## 2. Konvensi REST untuk Catatku

Sebelum menulis kode, Anda perlu memahami konvensi REST. Setiap resource (seperti entri) memiliki seperangkat endpoint standar yang dipetakan ke HTTP verb. Mengikuti konvensi ini membuat API Anda dapat diprediksi oleh developer lain dan mudah didokumentasikan.

| HTTP Verb | URL                  | Aksi          | Response          |
|-----------|----------------------|---------------|-------------------|
| GET       | `/api/entries`       | Tampilkan semua | 200 + JSON array  |
| POST      | `/api/entries`       | Buat baru     | 201 + JSON object |
| GET       | `/api/entries/{id}`  | Tampilkan satu | 200 + JSON object |
| PUT       | `/api/entries/{id}`  | Update        | 200 + JSON object |
| DELETE    | `/api/entries/{id}`  | Hapus         | 204 + kosong      |

Perhatikan bagaimana URL yang sama (`/api/entries`) berperilaku berbeda tergantung pada HTTP verb: GET membaca, POST membuat. Konvensi ini dibagikan di hampir setiap REST API di web, itulah sebabnya mengikutinya membuat API Anda langsung familiar bagi developer mana pun.

---

## 3. Menginstal API Scaffolding

Laravel 11+ tidak disertai routing API secara default. Anda perlu menginstalnya secara terpisah sehingga sebuah file `routes/api.php` khusus ada dan prefix `/api` yang seragam diterapkan ke semua route di dalamnya.

### Step 1: Menjalankan Perintah Install

Jalankan perintah Artisan berikut untuk menyiapkan infrastruktur API.

```bash
php artisan install:api
```

Perintah ini melakukan tiga hal. Pertama, ia membuat `routes/api.php` tempat route API Anda akan berada. Kedua, ia mendaftarkan file route API di `bootstrap/app.php` sehingga Laravel memuatnya pada setiap request. Ketiga, ia menginstal Laravel Sanctum untuk authentication token (kita akan menggunakan Sanctum di Lesson 10). Setelah perintah ini, setiap route yang Anda letakkan di `routes/api.php` secara otomatis mendapatkan prefix URL `/api`, sehingga `Route::get('/entries', ...)` menjadi dapat diakses di `/api/entries`.

---

## 4. Membuat API Controller

API controller terpisah dari web controller karena mereka mengembalikan JSON alih-alih view, dan karena pola interaksinya berbeda: tidak ada redirect, tidak ada session flash message, tidak ada form HTML. Menjaganya tetap terpisah mencegah kepentingan web bocor ke kode API dan sebaliknya.

### Step 1: Membuat API Controller

Jalankan perintah berikut untuk membuat sebuah controller di namespace `Api`.

```bash
php artisan make:controller Api/EntryController --api
```

Prefix `Api/` mengorganisasi API controller di namespace dan direktori mereka sendiri, menjaganya tetap terpisah dari web controller. Flag `--api` menghilangkan method `create` dan `edit` karena API tidak melayani form HTML; hanya endpoint data (index, show, store, update, destroy) yang penting. File yang dihasilkan berada di `app/Http/Controllers/Api/EntryController.php`.

### Step 2: Mengimplementasikan Method Index dan Show

Buka `app/Http/Controllers/Api/EntryController.php` dan tambahkan implementasi berikut.

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Entry;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EntryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $entries = Entry::with('tags', 'user')
            ->withCount('comments')
            ->latest()
            ->paginate(15);

        return response()->json($entries);
    }

    public function show(Entry $entry): JsonResponse
    {
        $entry->load('tags', 'user', 'comments.user');

        return response()->json($entry);
    }
}
```

Mari kita periksa setiap bagian dengan cermat. Namespace `App\Http\Controllers\Api` cocok dengan direktori. Kedua signature method mendeklarasikan `JsonResponse` sebagai return type, membuat sifat JSON dari respons eksplisit bagi developer dan IDE.

Di `index()`, kita mengambil entri dengan eager loading menggunakan `with('tags', 'user')`, menambahkan subquery jumlah komentar dengan `withCount('comments')`, mengurutkan berdasarkan yang terbaru, dan memaginasi menjadi 15 per halaman. Nilai return `paginate()` adalah sebuah `LengthAwarePaginator`, yang dikonversi Laravel secara otomatis menjadi JSON termasuk metadata pagination: halaman saat ini, jumlah per halaman, total item, dan link navigasi. `response()->json($entries)` menserialisasi objek sebagai JSON dan mengatur header respons `Content-Type: application/json`.

Di `show()`, route model binding menerima `$entry` berdasarkan ID dari URL. Kita kemudian melakukan eager load relationship sebelum mengembalikan, karena tanpa memuatnya secara eksplisit, key `tags` dan `comments` akan absen dari output JSON. `response()->json($entry)` menserialisasi entri tunggal dengan relationship yang dimuatnya.

### Step 3: Mengimplementasikan Store, Update, dan Destroy

Masih di `app/Http/Controllers/Api/EntryController.php`, tambahkan import facade `Gate` ke statement `use` yang sudah ada di bagian atas, lalu tambahkan tiga method berikut setelah method `show` yang sudah ada.

```php
<?php
// ... others lines of code
use Illuminate\Support\Facades\Gate;

class EntryController extends Controller
{
    // ... other methods

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

        return response()->json($entry, 201);
    }

    public function update(Request $request, Entry $entry): JsonResponse
    {
        Gate::authorize('update', $entry);

        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'content' => 'sometimes|required|string',
            'tags' => 'nullable|array',
            'tags.*' => 'exists:tags,id',
        ]);

        $entry->update($validated);

        if (isset($validated['tags'])) {
            $entry->tags()->sync($validated['tags']);
        }

        return response()->json($entry->fresh(['tags', 'user']));
    }

    public function destroy(Entry $entry): JsonResponse
    {
        Gate::authorize('delete', $entry);

        $entry->delete();

        return response()->json(null, 204);
    }
}
```

Menelusuri setiap method: `store()` memvalidasi input, membuat sebuah entri yang dimiliki user yang terautentikasi melalui relationship, melakukan sync tag, melakukan eager load relationship untuk body respons, dan mengembalikan HTTP 201 Created. Argumen kedua untuk `response()->json($data, $status)` mengatur kode status HTTP. Mengembalikan 201 alih-alih 200 penting karena API client menggunakan kode status untuk menentukan apa yang terjadi tanpa mengurai body.

Di `update()`, baris pertama memanggil `Gate::authorize('update', $entry)`, yang menegakkan policy ownership yang didefinisikan di Lesson 5 dan mengembalikan HTTP 403 jika user yang terautentikasi tidak memiliki entri ini. Setelah authorization, perhatikan aturan validasi menggunakan `sometimes|required` alih-alih hanya `required`. Aturan `sometimes` berarti "hanya validasi field ini jika ia disertakan dalam request", yang memungkinkan update parsial di mana client hanya mengirim field yang berubah. Kita hanya melakukan sync tag jika mereka disertakan dalam request (diperiksa dengan `isset($validated['tags'])`). Pemanggilan `fresh(['tags', 'user'])` memuat ulang entri dari database dengan relationship-nya, memastikan respons mencerminkan mutasi tingkat database apa pun.

Di `destroy()`, `Gate::authorize('delete', $entry)` menjalankan pemeriksaan ownership yang sama sebelum penghapusan. Kita kemudian menghapus entri dan mengembalikan HTTP 204 No Content dengan `null` sebagai body. Respons 204 tidak memiliki body menurut konvensi REST; mengembalikan null memberi tahu `response()->json()` untuk menghasilkan body kosong sambil mengatur kode status yang benar.

---

## 5. Mendaftarkan Route API

Buka `routes/api.php` dan ganti kontennya dengan berikut, yang memisahkan endpoint publik yang hanya-baca dari endpoint tulis yang terautentikasi.

```php
<?php

use App\Http\Controllers\Api\EntryController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/entries', [EntryController::class, 'index']);
Route::get('/entries/{entry}', [EntryController::class, 'show']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/entries', [EntryController::class, 'store']);
    Route::put('/entries/{entry}', [EntryController::class, 'update']);
    Route::delete('/entries/{entry}', [EntryController::class, 'destroy']);
});
```

Melihat organisasi route: kita membagi route menjadi publik (GET untuk membaca) dan terautentikasi (POST/PUT/DELETE untuk menulis). Endpoint hanya-baca bersifat publik karena siapa pun dengan URL API seharusnya dapat melihat entri Catatku yang terdaftar secara publik. Operasi tulis memerlukan authentication untuk mencegah pembuatan atau modifikasi anonim. `Route::middleware('auth:sanctum')->group(...)` membungkus route tulis sehingga mereka memerlukan sebuah Sanctum bearer token, yang kita implementasikan di Lesson 10. Untuk saat ini, route yang dilindungi ini akan menolak setiap request karena tidak ada token yang dikirim; route publik bekerja seketika tanpa token apa pun.

---

## 6. Menjalankan dan Menguji

Mari kita verifikasi endpoint API merespons dengan benar menggunakan perintah `curl` dari terminal.

### Step 1: Menguji Endpoint Index

Buka terminal dan jalankan perintah curl berikut saat development server berjalan.

```bash
curl http://localhost:8000/api/entries
```

Perintah curl mengirim sebuah HTTP GET request dan mencetak body respons. Anda akan melihat output JSON dengan metadata pagination yang membungkus sebuah array berisi entri, mirip dengan struktur berikut.

```json
{
    "current_page": 1,
    "data": [
        {
            "id": 1,
            "user_id": 1,
            "title": "My First Entry",
            "content": "...",
            "tags": [{"id": 1, "name": "Personal"}],
            "user": {"id": 1, "name": "Admin"},
            "comments_count": 0
        }
    ],
    "per_page": 15,
    "total": 5
}
```

Jika Anda ingin output diformat agar mudah dibaca, salurkan melalui formatter JSON Python: `curl http://localhost:8000/api/entries | python3 -m json.tool`.

### Step 2: Menguji Endpoint Show

Minta sebuah entri tertentu berdasarkan ID-nya.

```bash
curl http://localhost:8000/api/entries/1
```

Anda akan melihat sebuah objek JSON entri tunggal dengan semua relationship-nya (tags, user, comments, penulis komentar) disertakan. Jika ID tidak ada, Laravel secara otomatis mengembalikan kode status 404 dengan pesan error JSON karena route model binding gagal dengan exception yang sesuai saat menggunakan route API.

### Step 3: Menguji Response 404

Minta sebuah ID yang tidak ada untuk memverifikasi penanganan error.

```bash
curl -i http://localhost:8000/api/entries/99999
```

Flag `-i` memberi tahu curl untuk menyertakan header respons HTTP dalam output. Anda akan melihat `HTTP/1.1 404 Not Found` di header, diikuti oleh body JSON dengan pesan error. Perilaku ini tidak memerlukan kode dari pihak Anda; Laravel menanganinya secara otomatis ketika route model binding gagal dan request mengharapkan respons JSON.

### Step 4: Menguji Error Validasi

Coba melakukan post ke endpoint store yang dilindungi tanpa authentication.

```bash
curl -X POST http://localhost:8000/api/entries \
  -H "Content-Type: application/json" \
  -d '{"title":"Test"}'
```

Flag `-X POST` mengatur method HTTP. Flag `-H` menambahkan header Content-Type sehingga Laravel tahu untuk mengurai body sebagai JSON. Flag `-d` mengirim body request. Anda akan melihat HTTP 401 Unauthorized karena route memerlukan sebuah Sanctum token. Kita akan mengimplementasikan alur penerbitan token di Lesson 10; pada saat itu Anda dapat mencobanya lagi dengan bearer token yang valid dan menerima entah 201 saat sukses atau 422 dengan error validasi jika field yang diperlukan hilang.

---

## 7. Memperbaiki Error pada Kode Anda

Berikut adalah kesalahan paling umum saat membangun REST API di Laravel.

**Error 1: Mengembalikan model Eloquent dari route closure, melewati controller.**

Error ini terjadi ketika developer membuat prototype route dengan mengembalikan model secara langsung dari closure. Meskipun Laravel mengonversi model Eloquent menjadi JSON secara otomatis, pola ini melewati eager loading, pagination, dan authorization, menghasilkan respons yang tidak lengkap atau tidak aman.

```php
// Wrong: returns all entries without eager loading, pagination, or authorization
Route::get('/entries', function () {
    return Entry::all();
});

// Correct: route through a controller for structure, optimization, and security
Route::get('/entries', [EntryController::class, 'index']);
```

Versi yang salah memuat setiap entri tanpa batas, mengekspos semua kolom termasuk yang sensitif, dan melewati pemuatan relationship, sehingga `tags` dan `comments` absen dari output. Versi yang benar merutekan melalui controller di mana `paginate(15)`, `with('tags', 'user')`, dan `withCount('comments')` diterapkan secara konsisten.

---

**Error 2: Mengembalikan 200 alih-alih 201 untuk pembuatan resource yang berhasil.**

Error ini terjadi ketika Anda lupa meneruskan kode status sebagai argumen kedua ke `response()->json()` setelah membuat sebuah resource. Konvensi REST menetapkan 201 (Created) untuk request POST yang berhasil yang membuat resource baru, bukan 200 (OK).

```php
// Wrong: returns 200 OK, which does not indicate a new resource was created
return response()->json($entry);

// Correct: returns 201 Created, signaling a new resource was successfully created
return response()->json($entry, 201);
```

Menggunakan 200 untuk respons pembuatan secara teknis berfungsi tetapi salah menurut konvensi REST. API client yang mengikuti spesifikasi memeriksa 201 untuk memastikan bahwa sebuah resource dibuat. Menggunakan 200 dapat menyebabkan generator SDK dan API client menangani respons dengan salah. Perbaikannya adalah meneruskan `201` sebagai argumen kedua ke `json()`.

---

**Error 3: Menggunakan session flash message dalam respons API, yang bersifat stateless.**

Error ini terjadi ketika developer menyalin pola web controller ke API controller dan menyertakan `->with('success', '...')` setelah respons JSON. Data session flash hanya bekerja dengan session berbasis browser, yang biasanya tidak digunakan API client.

```php
// Wrong: with() adds session data that API clients cannot read
return response()->json($entry)->with('success', 'Entry created!');

// Correct: put status information in the JSON body or rely on status codes
return response()->json(['data' => $entry, 'message' => 'Entry created.'], 201);
```

Versi yang salah memanggil `->with(...)` pada respons JSON, yang di beberapa versi Laravel tidak melakukan apa-apa dan di versi lain melemparkan error, karena `with()` yang dirantai mencoba menulis ke session yang tidak dipertahankan API client antar request. Versi yang benar menyertakan pesan status apa pun yang diperlukan di dalam body JSON itu sendiri, atau cukup mengandalkan kode status HTTP (201 menandakan keberhasilan dengan cukup jelas bagi sebagian besar client). REST API seharusnya stateless: setiap request harus bersifat mandiri.

---

## 8. Latihan

Latihan ini mengembangkan API controller yang Anda bangun di lesson ini. Masing-masing menambahkan kemampuan praktis yang sering diharapkan konsumen API nyata. Coba setiap latihan secara independen sebelum memeriksa solusinya.

**Latihan 1:** Tambahkan pemfilteran ke endpoint index. Terima parameter query `tag` seperti `/api/entries?tag=travel`. Di controller, jika parameter ada, filter entri menggunakan `whereHas` untuk menemukan entri dengan tag yang cocok dengan slug tersebut.

**Latihan 2:** Tambahkan parameter `search` ke endpoint index sehingga client dapat memanggil `/api/entries?search=keyword`. Gunakan kembali scope `scopeSearch` dari Lesson 3.

**Latihan 3:** Buat sebuah `Api/CommentController` dengan method `store` yang menerima komentar JSON pada entri. Kembalikan komentar yang dibuat sebagai JSON dengan status 201.

---

## 9. Solusi

Setiap solusi di bawah ini lengkap dan dapat diterapkan langsung ke API controller Anda. Latihan 1 dan 2 keduanya memodifikasi method `index`, jadi terapkan keduanya bersama dalam urutan yang ditunjukkan untuk menghindari menulis ulang method yang sama dua kali.

**Solusi untuk Latihan 1:**

Di `app/Http/Controllers/Api/EntryController.php`, ganti query tetap di method `index` dengan sebuah builder yang menerapkan filter secara kondisional.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function index(Request $request): JsonResponse
    {
        $query = Entry::with('tags', 'user')->withCount('comments');

        if ($request->filled('tag')) {
            $query->whereHas('tags', function ($q) use ($request) {
                $q->where('slug', $request->input('tag'));
            });
        }

        $entries = $query->latest()->paginate(15);

        return response()->json($entries);
    }

    // ... other methods
}
```

`$request->filled('tag')` mengembalikan true hanya ketika parameter `tag` ada dan tidak kosong. `whereHas('tags', function ($q) { ... })` menambahkan subquery `EXISTS` yang memfilter entri hanya menjadi entri yang memiliki setidaknya satu tag yang cocok dengan slug yang diberikan. Pendekatan ini berjalan di database dan lebih efisien daripada memuat semua entri dan memfilter di PHP.

---

**Solusi untuk Latihan 2:**

Di `app/Http/Controllers/Api/EntryController.php`, perbarui method `index` untuk menyertakan filter search setelah filter tag yang sudah ada. Method lengkap dengan kedua filter terlihat seperti ini:

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function index(Request $request): JsonResponse
    {
        $query = Entry::with('tags', 'user')->withCount('comments');

        if ($request->filled('tag')) {
            $query->whereHas('tags', function ($q) use ($request) {
                $q->where('slug', $request->input('tag'));
            });
        }

        if ($request->filled('search')) {
            $query->search($request->input('search'));
        }

        $entries = $query->latest()->paginate(15);

        return response()->json($entries);
    }

    // ... other methods
}
```

Ini memanggil method `scopeSearch` yang didefinisikan pada model Entry di Lesson 3. Scope menambahkan kondisi `WHERE (title LIKE ? OR content LIKE ?)` dengan kata kunci pencarian. Karena scope memodifikasi query builder yang mendasari yang sama, kedua filter dapat diterapkan secara independen: `/api/entries?tag=travel&search=beach` menemukan entri yang ber-tag "travel" yang juga menyebut "beach" di title atau content.

---

**Solusi untuk Latihan 3:**

Buat API comment controller.

```bash
php artisan make:controller Api/CommentController
```

Buka `app/Http/Controllers/Api/CommentController.php` dan tambahkan method store.

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Entry;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CommentController extends Controller
{
    public function store(Request $request, Entry $entry): JsonResponse
    {
        $validated = $request->validate([
            'body' => 'required|string|min:2|max:1000',
        ]);

        $comment = $entry->comments()->create([
            ...$validated,
            'user_id' => $request->user()->id,
        ]);

        $comment->load('user');

        return response()->json($comment, 201);
    }
}
```

Daftarkan route di `routes/api.php` di dalam group middleware `auth:sanctum`.

```php
Route::post('/entries/{entry}/comments', [CommentController::class, 'store']);
```

Method memvalidasi body komentar, membuat komentar melalui relationship entri (yang secara otomatis mengatur `entry_id`), mengatur `user_id` secara manual dari user yang terautentikasi, dan melakukan eager load pada penulis sebelum mengembalikan. Mengembalikan 201 menandakan bahwa sebuah resource baru dibuat. URL bersarang `/entries/{entry}/comments` mencerminkan route web dari Lesson 1 dan dengan jelas mengomunikasikan bahwa komentar dimiliki oleh entri tertentu.

---

## Selanjutnya - Lesson 10

Di lesson ini Anda membangun sebuah JSON API yang berfungsi untuk Catatku. Anda menginstal API scaffolding dengan `php artisan install:api`, membuat sebuah `Api/EntryController` khusus yang mengembalikan JSON melalui `response()->json()`, dan menerapkan konvensi REST: 201 untuk pembuatan, 204 untuk penghapusan, dan route model binding yang tepat yang secara otomatis mengembalikan 404 untuk resource yang hilang. Anda mengorganisasi route ke dalam group publik dan terautentikasi, menggunakan `sometimes|required` untuk validasi update parsial, dan menguji setiap endpoint dengan curl untuk memverifikasi bentuk respons dan kode status.

Di Lesson 10, Anda akan mempelajari API Resource dan authentication Sanctum: bagaimana membentuk output JSON Anda secara presisi menggunakan class Resource, dan bagaimana menerbitkan Sanctum bearer token sehingga client eksternal dapat melakukan authentication ke endpoint tulis yang dilindungi yang Anda bangun hari ini.
