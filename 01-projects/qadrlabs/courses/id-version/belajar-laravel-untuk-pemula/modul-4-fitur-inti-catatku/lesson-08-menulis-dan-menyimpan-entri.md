Lesson sebelumnya menghasilkan sesuatu yang benar-benar dapat Anda lihat dan gunakan: halaman daftar entri dan halaman detail, keduanya bekerja dengan layout bersama yang rapi. Namun jika Anda perhatikan lebih dekat, setiap entri yang ditampilkan dibuat secara manual melalui Tinker. Belum ada cara bagi pengguna untuk menulis entri baru dari dalam aplikasi itu sendiri.

Lesson ini menutup celah tersebut.

## Ikhtisar {#overview}

### Apa yang Akan Anda Bangun

Di akhir lesson ini, pengguna yang sudah login akan dapat membuka sebuah form, menulis entri jurnal, dan melihatnya langsung muncul di daftar entri. Satu alur lengkap, dari form kosong hingga record database yang tersimpan, akan bekerja untuk pertama kalinya.

### Apa yang Akan Anda Pelajari

- Bagaimana Laravel menangani alur form dua langkah: route GET untuk menampilkan form dan route POST untuk memproses pengiriman
- Cara memvalidasi input pengguna menggunakan `$request->validate()` dengan rule seperti `required`, `string`, dan `max`
- Apa yang terjadi ketika validasi gagal: redirect otomatis, pesan error, dan input yang dipertahankan
- Bagaimana `@csrf` melindungi form Anda dari serangan cross-site request forgery
- Bagaimana `old()` mengembalikan nilai yang sebelumnya dimasukkan ketika pengguna dikembalikan ke form
- Cara menyimpan data secara aman melalui relasi Eloquent sehingga `user_id` tidak dapat dipalsukan
- Cara mengelompokkan route dengan `middleware('auth')` untuk mewajibkan autentikasi

### Apa yang Anda Butuhkan

- Proyek `catatku` terbuka di VS Code dengan development server yang berjalan
- Komponen layout, komponen EntryCard, dan view entry dari Lesson 7
- User uji coba yang dibuat melalui Tinker di Lesson 6

---

## Langkah 1: Tambahkan Route {#step-1-add-the-routes}

Kita memerlukan tiga route baru: satu untuk menampilkan form pembuatan (GET), satu untuk memproses pengiriman form (POST), dan satu untuk autentikasi pengguna yang digunakan untuk pengujian

Perbarui `routes/web.php`:

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EntryController;

Route::get('/', function () {
    return view('home');
});

Route::get('/entries', [EntryController::class, 'index']);

Route::middleware('auth')->group(function () {
    Route::get('/entries/create', [EntryController::class, 'create']);
    Route::post('/entries', [EntryController::class, 'store']);
    Route::get('/entries/{entry}', [EntryController::class, 'show']);
});

// ONLY FOR DEVELOPMENT - delete after lesson 10
Route::get('/dev-login', function () {
    auth()->loginUsingId(1);
    return redirect('/entries');
});
```

Ada beberapa hal yang perlu diperhatikan di sini.

Route `/entries` tetap berada di luar group `middleware('auth')`, sehingga siapa pun dapat melihat daftar entri tanpa login. Route create, store, dan show berada di dalam group, yang berarti hanya pengguna yang sudah terautentikasi yang dapat mengaksesnya. Jika pengunjung yang belum login mencoba mengakses route mana pun di dalam group, Laravel secara otomatis mengarahkannya ke halaman login.

`Route::get('/entries/create', ...)` menampilkan form. `Route::post('/entries', ...)` memproses pengiriman form. Pola dua route ini adalah standar di Laravel: GET untuk menampilkan, POST untuk memproses. Anda akan melihat pola ini berulang untuk setiap form di aplikasi.

> **Urutan route penting!** Route `/entries/create` harus dideklarasikan **sebelum** `/entries/{entry}`. Jika urutannya dibalik, Laravel akan mengira kata "create" pada URL adalah ID entry dan mencoba mencari Entry dengan ID "create" di database, yang akan gagal dengan error 404.

Route `/dev-login` di bagian bawah adalah pintasan sementara untuk pengujian. Route ini melakukan login sebagai user dengan ID 1 (user "Budi" yang kita buat melalui Tinker di Lesson 6) dan mengarahkan ke daftar entri. Kita akan menghapus route ini di Lesson 10 ketika kita membangun autentikasi yang sebenarnya.

---

## Langkah 2: Tambahkan Method Controller {#step-2-add-controller-methods}

Buka `app/Http/Controllers/EntryController.php` dan tambahkan method `create()` dan `store()`:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Entry;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse; // add this line of code

class EntryController extends Controller
{
    public function index()
    {
        $entries = Entry::with('user')->latest()->get();

        return view('entries.index', compact('entries'));
    }

    public function create()
    {
        return view('entries.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'title'   => 'required|string|max:255',
            'content' => 'required|string',
        ]);

        $request->user()->entries()->create($validated);

        return redirect('/entries')
            ->with('success', 'Entry saved successfully.');
    }

    public function show(Entry $entry)
    {
        if ($entry->user_id !== auth()->id()) {
            abort(403);
        }

        return view('entries.show', compact('entry'));
    }
}
```

Method `create()` cukup sederhana: method ini hanya mengembalikan view form. Tidak ada persiapan data yang diperlukan karena kita sedang membuat sesuatu yang baru, bukan menampilkan data yang sudah ada.

Method `store()` melakukan pekerjaan sebenarnya. Mari kita telusuri langkah demi langkah.

`$request->validate([...])` memeriksa data yang masuk terhadap rule yang ditentukan. Jika ada rule yang gagal, Laravel secara otomatis mengarahkan pengguna kembali ke form, membawa pesan error dan nilai yang sebelumnya dimasukkan. Jika semua rule lolos, method ini mengembalikan array yang hanya berisi data yang sudah tervalidasi.

Rule validasi dipisahkan oleh karakter pipe (`|`). Untuk field `title`: `required` berarti tidak boleh kosong, `string` berarti harus berupa teks, dan `max:255` membatasinya hingga 255 karakter (sesuai dengan ukuran kolom VARCHAR di database). Untuk field `content`: `required` dan `string` memastikan field tersebut ada dan berupa teks, tanpa batas panjang karena tipe kolom database adalah TEXT.

`$request->user()->entries()->create($validated)` menyimpan entry baru ke database. Satu baris ini melakukan tiga hal penting. `$request->user()` mengambil user yang sedang terautentikasi dari session. `->entries()` mengakses relasi `hasMany` yang kita definisikan di Lesson 6, yang berarti kolom `user_id` otomatis diatur ke ID user saat ini. `->create($validated)` menyisipkan record baru menggunakan hanya data yang sudah tervalidasi.

Pendekatan ini aman karena `user_id` tidak pernah berasal dari input form. Nilainya selalu diturunkan dari session di sisi server. Bahkan jika seseorang mencoba menyisipkan `user_id` palsu ke dalam pengiriman form, atribut `#[Fillable]` pada model Entry akan mengabaikannya (karena hanya `title` dan `content` yang fillable), dan relasi tersebut akan tetap menimpanya dengan nilai yang benar.

`return redirect('/entries')->with('success', '...')` mengirim pengguna kembali ke halaman daftar entri dan menyimpan pesan flash di session. Ingat blok `@if (session('success'))` di komponen layout kita dari Lesson 7? Di sinilah pesan flash tersebut berasal. Pesan tersebut ditampilkan sekali lalu otomatis dihapus dari session.

---

## Langkah 3: Buat View Form {#step-3-create-the-form-view}

Buat file `resources/views/entries/create.blade.php`:

```html
<x-layout title="Write Entry — Catatku">

    <div class="mb-6">
        <a href="/entries" class="text-sm text-gray-400 hover:text-gray-700">
            ← Back to list
        </a>
    </div>

    <h2 class="text-lg font-semibold text-gray-900 mb-4">Write New Entry</h2>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
        <form method="POST" action="/entries">
            @csrf

            {{-- Title --}}
            <div class="mb-5">
                <label for="title"
                       class="block text-sm font-medium text-gray-700 mb-1">
                    Title
                </label>
                <input
                    type="text"
                    id="title"
                    name="title"
                    value="{{ old('title') }}"
                    placeholder="Entry title..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent
                           {{ $errors->has('title') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                    autofocus
                >
                @error('title')
                    <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Content --}}
            <div class="mb-6">
                <label for="content"
                       class="block text-sm font-medium text-gray-700 mb-1">
                    Content
                </label>
                <textarea
                    id="content"
                    name="content"
                    rows="12"
                    placeholder="Write your entry here..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent resize-y
                           {{ $errors->has('content') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                >{{ old('content') }}</textarea>
                @error('content')
                    <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Buttons --}}
            <div class="flex items-center justify-between">
                <a href="/entries"
                   class="text-sm text-gray-500 hover:text-gray-900">
                    Cancel
                </a>
                <button type="submit"
                    class="bg-gray-900 text-white text-sm px-5 py-2 rounded-lg
                           hover:bg-gray-700 transition-colors">
                    Save Entry
                </button>
            </div>

        </form>
    </div>

</x-layout>
```

Ada beberapa mekanisme yang bekerja sama dalam form ini. Mari kita bahas satu per satu.

### Directive `@csrf` {#the-csrf-directive}

Setiap form POST di Laravel harus menyertakan `@csrf`. Directive ini menghasilkan field input tersembunyi yang berisi token unik yang terkait dengan session pengguna:

```html
<!-- What @csrf renders -->
<input type="hidden" name="_token" value="xYz123...">
```

Token ini membuktikan bahwa form dikirim dari halaman di aplikasi Anda sendiri, bukan dari situs eksternal jahat yang mencoba memalsukan request atas nama pengguna Anda. Jenis serangan ini disebut Cross-Site Request Forgery (CSRF). Tanpa token `@csrf`, Laravel menolak semua request POST dengan error 419.

### Helper `old()` {#the-old-helper}

Ketika validasi gagal, Laravel secara otomatis mengarahkan pengguna kembali ke form. Namun tanpa `old()`, semua teks yang sudah mereka ketik akan hilang, memaksa mereka untuk memulai dari awal. Itu adalah pengalaman pengguna yang buruk.

`old('title')` mengambil nilai yang sebelumnya dikirim untuk field `title` dari session. Laravel menyimpan nilai-nilai ini secara otomatis ketika validasi gagal, dan `old()` mengambilnya kembali. Untuk elemen `<input>`, Anda menempatkan `old()` di atribut `value`:

```html
<input value="{{ old('title') }}">
```

Untuk elemen `<textarea>`, Anda menempatkan `old()` di antara tag pembuka dan penutup. Perhatikan bahwa tidak ada whitespace di antara tag dan ekspresi Blade, karena whitespace apa pun akan muncul sebagai konten di dalam textarea:

```html
<textarea>{{ old('content') }}</textarea>
```

### Tampilan Error {#error-display}

Blok `@error('title') ... @enderror` hanya dirender ketika validasi untuk field tersebut gagal. Di dalam blok tersebut, `$message` berisi pesan error yang dihasilkan oleh Laravel (misalnya, "The title field is required.").

Class CSS kondisional `{{ $errors->has('title') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}` mengubah border input menjadi merah dan menambahkan background merah muda ketika ada error validasi untuk field tersebut. Ketika tidak ada error, class ini menggunakan border abu-abu normal. Hal ini memberi pengguna petunjuk visual langsung tentang field mana yang perlu diperhatikan.

---

## Langkah 4: Uji Alur Pembuatan {#step-4-test-the-create-flow}

Dengan user uji coba yang sudah dibuat di Lesson 6 dan route sementara `/dev-login` yang sudah ada, mari kita uji alur lengkapnya.

Pertama, login dengan mengunjungi `http://127.0.0.1:8000/dev-login`. Ini akan mengautentikasi Anda sebagai user dengan ID 1 (Budi) dan mengarahkan Anda ke daftar entri.

Sekarang buka `http://127.0.0.1:8000/entries/create`. Anda akan melihat form dengan input title, textarea content, dan tombol "Save Entry".
![write new entry](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/08-write-new-entry.webp)

Coba kirim form dengan field kosong. Anda akan diarahkan kembali ke form dengan input berbingkai merah dan pesan error di bawah setiap field. Inilah validasi Laravel yang sedang bekerja.

Sekarang isi title dan content, lalu klik "Save Entry". Anda akan diarahkan ke daftar entri, di mana pesan sukses berwarna hijau bertuliskan "Entry saved successfully." dan entry baru Anda muncul di daftar.
![new entry saved](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/09-new-entry-saved.webp)

Klik pada title entry atau link "Read" untuk mengunjungi halaman detail dan memastikan bahwa konten tersimpan dengan benar.
![visit detail page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/10-visit-entry-detail-page.webp)

---

## Alur Form di Laravel {#the-form-flow-in-laravel}

Sekarang setelah Anda melihat seluruh alur ini bekerja, mari kita petakan apa yang terjadi di balik layar ketika pengguna mengirimkan sebuah form:

```
1. Browser sends POST /entries
   { _token: "abc...", title: "My entry", content: "Entry body..." }
         │
         ▼
2. routes/web.php directs to EntryController@store
         │
         ▼
3. Controller validates the data
   Is title present? Is content present?
         │
         ├── Failed  → redirect back to form with errors + old input
         └── Passed  → save to database → redirect to listing with success message
```

Alur ini sama untuk setiap form di Laravel. Detailnya berbeda-beda (field yang berbeda, rule validasi yang berbeda, target redirect yang berbeda), tetapi polanya tetap identik: validasi terlebih dahulu, tolak atau simpan, lalu redirect. Anda akan melihat pola persis ini lagi ketika kita membangun form edit di lesson berikutnya.

---

## Memahami Middleware Group {#understanding-middleware-groups}

Di file route, kita membungkus beberapa route di dalam `Route::middleware('auth')->group(function () { ... })`. Ini berarti setiap route di dalam group memerlukan user yang sudah terautentikasi. Jika seseorang yang belum login mencoba mengakses route mana pun di dalamnya, Laravel secara otomatis mengarahkannya ke halaman login.

Route daftar `/entries` sengaja dibiarkan di luar group sehingga siapa pun dapat menjelajahi entri tanpa login. Tetapi membuat, melihat detail, dan semua operasi di masa depan yang mengubah data akan memerlukan autentikasi.

Pemisahan ini adalah pola umum dalam aplikasi web: akses baca publik dengan akses tulis yang dilindungi. Daftar entri adalah etalase toko yang dapat dilihat siapa saja. Operasi yang mengubah data mengharuskan Anda masuk melalui pintu dan mengidentifikasi diri Anda terlebih dahulu.

---

## Kesimpulan {#conclusion}

Sebuah alur lengkap kini berfungsi: pengguna membuka form, mengisi title dan content, mengirimkannya, dan entry tersebut tersimpan ke database. Berikut adalah poin-poin penting yang perlu diingat:

- Form Laravel mengikuti **pola dua route**: GET untuk menampilkan form, POST untuk memproses pengiriman. Atribut `action` form mengarah ke route POST, dan atribut `method` diatur ke `POST`.
- `$request->validate([...])` memeriksa input terhadap rule. Jika validasi **gagal**, Laravel secara otomatis mengarahkan kembali dengan pesan error dan input lama. Jika **berhasil**, Anda mendapatkan array bersih berisi data yang sudah tervalidasi.
- Rule validasi umum meliputi `required` (harus ada), `string` (harus berupa teks), dan `max:255` (panjang karakter maksimum).
- **`@csrf`** menghasilkan token tersembunyi yang membuktikan bahwa form dikirim dari aplikasi Anda, melindungi dari serangan cross-site request forgery. Setiap form POST harus menyertakannya.
- **`old('field')`** mengambil nilai yang sebelumnya dimasukkan setelah kegagalan validasi, sehingga pengguna tidak kehilangan pekerjaan mereka. Tempatkan di atribut `value` untuk input dan di antara tag untuk textarea.
- **`@error('field') ... @enderror`** merender pesan error untuk field tertentu. Variabel `$message` di dalamnya berisi teks error validasi.
- `$request->user()->entries()->create($validated)` menyimpan data melalui relasi Eloquent, secara otomatis mengatur `user_id` dari session. Ini aman karena `user_id` tidak pernah berasal dari input pengguna.
- `redirect('/path')->with('success', '...')` mengirim pengguna ke halaman baru dengan pesan flash satu kali yang disimpan di session.
- **`Route::middleware('auth')->group(...)`** mewajibkan autentikasi untuk semua route di dalam group. Pengunjung yang belum terautentikasi otomatis diarahkan ke halaman login.
- **Urutan route penting.** Segmen statis seperti `/entries/create` harus dideklarasikan sebelum segmen dinamis seperti `/entries/{entry}`, atau Laravel akan mencoba mencocokkan "create" sebagai ID entry.

Di lesson berikutnya, kita akan mengimplementasikan dua operasi CRUD yang tersisa: mengedit entri yang sudah ada dan menghapusnya. Anda akan mempelajari mengapa browser hanya memahami GET dan POST, dan bagaimana Laravel menggunakan `@method('PUT')` dan `@method('DELETE')` untuk mengatasi keterbatasan tersebut.
