# Lesson 9 — Edit dan Hapus Catatan

## Tujuan Pembelajaran

Di akhir lesson ini, kamu akan:
- Memahami konvensi RESTful routing untuk operasi CRUD
- Menambahkan fitur edit catatan dengan form yang sudah terisi data sebelumnya
- Mengimplementasikan fitur hapus catatan dengan konfirmasi
- Memahami method spoofing (`@method('PUT')` dan `@method('DELETE')`)
- Melengkapi siklus CRUD penuh untuk aplikasi Catatku

---

## Konvensi RESTful Routing

Laravel mengikuti konvensi RESTful untuk penamaan route dan method controller. Berikut tabel lengkap untuk resource "entries":

| Aksi | HTTP Method | URL | Method Controller |
|------|-------------|-----|-------------------|
| Tampilkan semua | GET | `/entries` | `index()` |
| Form buat baru | GET | `/entries/create` | `create()` |
| Simpan baru | POST | `/entries` | `store()` |
| Tampilkan detail | GET | `/entries/{entry}` | `show()` |
| Form edit | GET | `/entries/{entry}/edit` | `edit()` |
| Simpan perubahan | PUT/PATCH | `/entries/{entry}` | `update()` |
| Hapus | DELETE | `/entries/{entry}` | `destroy()` |

Dengan mengikuti konvensi ini, siapapun yang familiar dengan Laravel langsung bisa menebak struktur route dari nama controller dan method-nya.

---

## Method Spoofing

HTML form hanya mendukung dua HTTP method: `GET` dan `POST`. Tapi RESTful routing membutuhkan `PUT` dan `DELETE`. Laravel menyiasatinya dengan **method spoofing**.

`@method('PUT')` menghasilkan hidden input:
```html
<input type="hidden" name="_method" value="PUT">
```

Laravel membaca field ini dan memperlakukan request seolah-olah method-nya adalah PUT. Begitu juga dengan `@method('DELETE')`.

---

## Menambahkan Routes untuk Edit dan Hapus

Perbarui `routes/web.php` dengan route yang lengkap:

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EntryController;

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

---

## Melengkapi Controller

Buka `app/Http/Controllers/EntryController.php` dan tambahkan tiga method terakhir:

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
        $validated = $request->validate([
            'title'   => 'required|string|max:255',
            'content' => 'required|string',
        ]);

        $request->user()->entries()->create($validated);

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

    public function edit(Entry $entry)
    {
        if ($entry->user_id !== auth()->id()) {
            abort(403);
        }

        return view('entries.edit', compact('entry'));
    }

    public function update(Request $request, Entry $entry): RedirectResponse
    {
        if ($entry->user_id !== auth()->id()) {
            abort(403);
        }

        $validated = $request->validate([
            'title'   => 'required|string|max:255',
            'content' => 'required|string',
        ]);

        $entry->update($validated);

        return redirect('/entries/' . $entry->id)
            ->with('success', 'Catatan berhasil diperbarui.');
    }

    public function destroy(Entry $entry): RedirectResponse
    {
        if ($entry->user_id !== auth()->id()) {
            abort(403);
        }

        $entry->delete();

        return redirect('/entries')
            ->with('success', 'Catatan berhasil dihapus.');
    }
}
```

### Authorization: Kenapa Perlu `abort(403)`?

```php
if ($entry->user_id !== auth()->id()) {
    abort(403);
}
```

Meski catatan bersifat privat, user yang kreatif bisa mencoba menebak URL catatan orang lain. Misalnya jika catatan milik user A ada di `/entries/5`, user B bisa mencoba mengakses `/entries/5/edit` secara langsung dari browser.

Pengecekan ini memastikan operasi apapun — baca, edit, maupun hapus — hanya berhasil jika catatan memang milik user yang sedang login. Semua yang bukan pemilik mendapat response 403 Forbidden.

### `$entry->update($validated)`

Satu baris ini memperbarui catatan di database dengan data yang sudah divalidasi. Eloquent otomatis mengisi kolom `updated_at` dengan waktu saat ini.

---

## Membuat View Form Edit

Buat file `resources/views/entries/edit.blade.php`:

```html
<x-layout :title="'Edit: ' . $entry->title . ' — Catatku'">

    <div class="mb-6">
        <a href="/entries/{{ $entry->id }}"
           class="text-sm text-gray-400 hover:text-gray-700">
            ← Kembali ke catatan
        </a>
    </div>

    <h2 class="text-lg font-semibold text-gray-900 mb-4">Edit Catatan</h2>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
        <form method="POST" action="/entries/{{ $entry->id }}">
            @csrf
            @method('PUT')

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
                    value="{{ old('title', $entry->title) }}"
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
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent resize-y
                           {{ $errors->has('content') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                >{{ old('content', $entry->content) }}</textarea>
                @error('content')
                    <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Tombol --}}
            <div class="flex items-center justify-between">
                <a href="/entries/{{ $entry->id }}"
                   class="text-sm text-gray-500 hover:text-gray-900">
                    Batal
                </a>
                <button type="submit"
                    class="bg-gray-900 text-white text-sm px-5 py-2 rounded-lg
                           hover:bg-gray-700 transition-colors">
                    Simpan Perubahan
                </button>
            </div>

        </form>
    </div>

</x-layout>
```

**`{{ old('title', $entry->title) }}`** — Argumen kedua adalah nilai default. Pertama kali halaman edit dibuka, field terisi dengan judul catatan yang ada. Jika form di-submit dan gagal validasi, terisi dengan nilai yang baru saja diubah pengguna.

---

## Verifikasi Semua Route

```bash
php artisan route:list
```

Output yang diharapkan:

```
GET|HEAD  /entries                  EntryController@index
GET|HEAD  /entries/create           EntryController@create
POST      /entries                  EntryController@store
GET|HEAD  /entries/{entry}          EntryController@show
GET|HEAD  /entries/{entry}/edit     EntryController@edit
PUT|PATCH /entries/{entry}          EntryController@update
DELETE    /entries/{entry}          EntryController@destroy
```

---

## Pengujian Fitur Edit dan Hapus

Pastikan sudah login (via `/dev-login`), lalu:

1. Buat beberapa catatan baru dari `/entries/create`
2. Klik "Edit" pada salah satu catatan — form edit terbuka dengan konten yang sudah terisi
3. Ubah judul atau isi, klik "Simpan Perubahan" — halaman detail terbuka dengan konten baru
4. Klik "Hapus" — konfirmasi muncul, setelah OK catatan terhapus dan kembali ke daftar
5. Coba akses URL edit catatan orang lain secara langsung — harus muncul error 403

---

## Ringkasan

Siklus CRUD untuk catatan kini lengkap:

| Operasi | HTTP | Route | Controller |
|---------|------|-------|------------|
| Baca semua | GET | `/entries` | `index()` |
| Baca satu | GET | `/entries/{id}` | `show()` |
| Form buat | GET | `/entries/create` | `create()` |
| Simpan baru | POST | `/entries` | `store()` |
| Form edit | GET | `/entries/{id}/edit` | `edit()` |
| Simpan ubah | PUT | `/entries/{id}` | `update()` |
| Hapus | DELETE | `/entries/{id}` | `destroy()` |

Konsep penting yang dipelajari:
- **RESTful routing** — konvensi URL dan HTTP method untuk CRUD
- **Method spoofing** — `@method('PUT')` dan `@method('DELETE')` untuk melewati keterbatasan form HTML
- **Route Model Binding** — Laravel otomatis mengambil model dari database berdasarkan ID di URL
- **Authorization** — `abort(403)` memastikan user hanya bisa mengakses catatan miliknya sendiri

Aplikasi Catatku sekarang sudah punya semua fitur pengelolaan catatan. Selanjutnya, kita akan membangun sistem autentikasi agar pengguna bisa mendaftar dan login dengan benar.
