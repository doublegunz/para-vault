# Lesson 8 — Menulis dan Menyimpan Catatan

## Tujuan Pembelajaran

Di akhir lesson ini, kamu akan:
- Menambahkan halaman form untuk menulis catatan baru
- Mengimplementasikan validasi input di controller
- Menyimpan catatan baru ke database
- Memahami peran CSRF protection dalam keamanan form

---

## Alur Form di Laravel

Ketika pengguna mengisi form dan klik "Simpan Catatan", ini yang terjadi:

```
1. Browser kirim POST /entries
   { title: "Judul catatan", content: "Isi catatan saya..." }
         │
         ▼
2. routes/web.php → EntryController@store
         │
         ▼
3. Controller validasi data
   Apakah title ada? Apakah content ada?
         │
         ├── Gagal → kembali ke form dengan pesan error
         └── Lolos → simpan ke database → redirect ke daftar
```

---

## Menambahkan Routes

Kita butuh dua route: satu untuk menampilkan form (GET) dan satu untuk memproses pengiriman form (POST).

Perbarui `routes/web.php`:

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EntryController;

Route::get('/entries', [EntryController::class, 'index']);
Route::get('/entries/create', [EntryController::class, 'create']);
Route::post('/entries', [EntryController::class, 'store']);
Route::get('/entries/{entry}', [EntryController::class, 'show']);
```

> **Urutan route penting!** Route `/entries/create` harus dideklarasikan **sebelum** `/entries/{entry}`. Jika tidak, Laravel akan mengira kata "create" di URL adalah ID catatan dan akan mencari Entry dengan ID "create" di database.

---

## Menambahkan Methods di Controller

Buka `app/Http/Controllers/EntryController.php` dan tambahkan method `create()` dan `store()`:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Entry;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;

class EntryController extends Controller
{
    public function index()
    {
        $entries = auth()->user()->entries()->latest()->get();
        return view('entries.index', compact('entries'));
    }

    public function create()
    {
        return view('entries.create');
    }

    public function store(Request $request): RedirectResponse
    {
        // Langkah 1: Validasi input
        $validated = $request->validate([
            'title'   => 'required|string|max:255',
            'content' => 'required|string',
        ]);

        // Langkah 2: Simpan catatan baru ke database
        $request->user()->entries()->create($validated);

        // Langkah 3: Redirect ke daftar dengan pesan sukses
        return redirect('/entries')
            ->with('success', 'Catatan berhasil disimpan.');
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

### Memahami Validasi Laravel

`$request->validate([...])` mendefinisikan aturan untuk setiap field:

```php
$validated = $request->validate([
    'title'   => 'required|string|max:255',
    'content' => 'required|string',
]);
```

**`required`** — Field tidak boleh kosong.
**`string`** — Nilai harus berupa teks.
**`max:255`** — Maksimal 255 karakter (sesuai batas VARCHAR di database).

Jika validasi **gagal**, Laravel otomatis kembali ke halaman sebelumnya sambil membawa pesan error dan nilai input yang sudah diketik pengguna. Jika **lolos**, method mengembalikan array data yang bersih dan sudah divalidasi.

### Cara Menyimpan Data dengan Aman

```php
$request->user()->entries()->create($validated);
```

- `$request->user()` — Ambil user yang sedang login
- `->entries()` — Akses relasi, sehingga `user_id` otomatis terisi dengan ID user yang login
- `->create($validated)` — Buat Entry baru hanya dengan data yang sudah divalidasi

Ini aman karena `user_id` tidak bisa dimanipulasi dari form — nilainya selalu diambil dari session login, bukan dari input pengguna.

---

## Membuat View Form Tulis Catatan

Buat file `resources/views/entries/create.blade.php`:

```html
<x-layout title="Tulis Catatan — Catatku">

    <div class="mb-6">
        <a href="/entries" class="text-sm text-gray-400 hover:text-gray-700">
            ← Kembali ke daftar
        </a>
    </div>

    <h2 class="text-lg font-semibold text-gray-900 mb-4">Tulis Catatan Baru</h2>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
        <form method="POST" action="/entries">
            @csrf

            {{-- Judul --}}
            <div class="mb-5">
                <label for="title"
                       class="block text-sm font-medium text-gray-700 mb-1">
                    Judul
                </label>
                <input
                    type="text"
                    id="title"
                    name="title"
                    value="{{ old('title') }}"
                    placeholder="Judul catatan..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent
                           {{ $errors->has('title') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                    autofocus
                >
                @error('title')
                    <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Isi Catatan --}}
            <div class="mb-6">
                <label for="content"
                       class="block text-sm font-medium text-gray-700 mb-1">
                    Isi Catatan
                </label>
                <textarea
                    id="content"
                    name="content"
                    rows="12"
                    placeholder="Tulis catatanmu di sini..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent resize-y
                           {{ $errors->has('content') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                >{{ old('content') }}</textarea>
                @error('content')
                    <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Tombol --}}
            <div class="flex items-center justify-between">
                <a href="/entries"
                   class="text-sm text-gray-500 hover:text-gray-900">
                    Batal
                </a>
                <button type="submit"
                    class="bg-gray-900 text-white text-sm px-5 py-2 rounded-lg
                           hover:bg-gray-700 transition-colors">
                    Simpan Catatan
                </button>
            </div>

        </form>
    </div>

</x-layout>
```

### `@csrf` — Perlindungan CSRF

Setiap form POST di Laravel wajib menyertakan `@csrf`. Directive ini menghasilkan hidden input berisi token unik per session:

```html
<!-- Hasil render @csrf -->
<input type="hidden" name="_token" value="xYz123...">
```

Token ini membuktikan bahwa form dikirim dari halaman di aplikasi kita sendiri, bukan dari situs lain. Tanpa `@csrf`, Laravel akan menolak semua POST request dengan error 419.

### `{{ old('title') }}` — Mempertahankan Input

Ketika validasi gagal, Laravel menyimpan nilai input sebelumnya ke session. `old('title')` mengambilnya kembali sehingga pengguna tidak perlu mengisi ulang form dari awal.

Untuk `<textarea>`, nilai `old()` diletakkan di antara tag pembuka dan penutup:
```html
<textarea ...>{{ old('content') }}</textarea>
```

---

## Menambahkan Middleware Auth pada Route

Saat ini, siapapun bisa mengakses `/entries/create` tanpa login. Kita perlu melindunginya. Perbarui `routes/web.php`:

```php
Route::get('/entries', [EntryController::class, 'index']);

Route::middleware('auth')->group(function () {
    Route::get('/entries/create', [EntryController::class, 'create']);
    Route::post('/entries', [EntryController::class, 'store']);
    Route::get('/entries/{entry}', [EntryController::class, 'show']);
});
```

Semua route di dalam `middleware('auth')` hanya bisa diakses pengguna yang sudah login. Tamu yang mencoba akan diarahkan ke halaman login secara otomatis.

---

## Mencoba Fitur Tulis Catatan

Untuk menguji, kita perlu user yang sudah login. Karena sistem autentikasi belum selesai dibangun, gunakan Tinker untuk membuat user dan login sementara.

Buat user via Tinker:

```bash
php artisan tinker
```

```php
\App\Models\User::create([
    'name'     => 'Budi',
    'email'    => 'budi@example.com',
    'password' => bcrypt('password123'),
]);
```

Tambahkan route login sementara di `routes/web.php` (hapus nanti):

```php
// HANYA UNTUK DEVELOPMENT - hapus setelah lesson 10
Route::get('/dev-login', function () {
    auth()->loginUsingId(1);
    return redirect('/entries');
});
```

Akses `http://127.0.0.1:8000/dev-login`, lalu buka `http://127.0.0.1:8000/entries/create`. Isi form dan klik "Simpan Catatan" — catatan baru akan muncul di daftar!

---

## Ringkasan

Kita telah:
- Menambahkan route `GET /entries/create` dan `POST /entries`
- Mengimplementasikan method `create()` dan `store()` dengan validasi
- Menyimpan catatan baru melalui relasi: `$request->user()->entries()->create($validated)`
- Memahami peran `@csrf` dan `old()` dalam pengelolaan form
- Melindungi route dengan `middleware('auth')`

Di lesson berikutnya, kita akan melengkapi siklus CRUD dengan menambahkan fitur **edit** dan **hapus** catatan.
