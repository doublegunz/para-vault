Lesson sebelumnya menyelesaikan separuh dari siklus CRUD. Pengguna sekarang dapat menulis entri baru dan melihatnya di listing. Namun entri yang sudah tersimpan belum bisa diubah jika ada yang perlu diperbaiki, dan belum ada cara untuk menghapusnya jika sudah tidak diperlukan lagi. Lesson ini melengkapi separuh lainnya.

## Overview {#overview}

### Apa yang Akan Anda Bangun

Di akhir lesson ini, siklus CRUD lengkap untuk Catatku akan selesai: create, read, update, dan delete. Ketujuh operasi akan memiliki route, controller method, dan view masing-masing, semuanya bekerja dengan konvensi RESTful dan pemeriksaan otorisasi yang tepat.

### Apa yang Akan Anda Pelajari

- Cara membangun form edit yang terisi otomatis dengan data yang sudah ada
- Cara kerja `old('field', $default)` dengan argumen kedua untuk form edit
- Apa itu method spoofing dan mengapa hal itu diperlukan (`@method('PUT')` dan `@method('DELETE')`)
- Cara mengimplementasikan controller method `update()` dan `destroy()`
- Mengapa setiap operasi yang mengubah data memerlukan pemeriksaan kepemilikan `abort(403)`
- Konvensi routing RESTful lengkap untuk sebuah resource Laravel

### Apa yang Anda Butuhkan

- Proyek `catatku` terbuka di VS Code dengan development server berjalan
- Sudah login melalui `/dev-login` (route sementara dari Lesson 8)
- Setidaknya satu entri sudah dibuat sehingga Anda memiliki sesuatu untuk diedit dan dihapus

---

## Step 1: Menambahkan Route Edit dan Delete {#step-1-add-the-edit-and-delete-routes}

Perbarui `routes/web.php` dengan kumpulan route lengkap untuk entries:

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
    Route::get('/entries/{entry}/edit', [EntryController::class, 'edit']); // add this
    Route::put('/entries/{entry}', [EntryController::class, 'update']); // add this
    Route::delete('/entries/{entry}', [EntryController::class, 'destroy']); // add this
});

// ONLY FOR DEVELOPMENT - delete after lesson 10
Route::get('/dev-login', function () {
    auth()->loginUsingId(1);
    return redirect('/entries');
});
```

Tiga route baru telah ditambahkan di dalam group `middleware('auth')`.

`Route::get('/entries/{entry}/edit', ...)` menampilkan form edit yang sudah terisi otomatis dengan data entri saat ini. Parameter `{entry}` akan diselesaikan oleh Route Model Binding, sama seperti pada method `show()`.

`Route::put('/entries/{entry}', ...)` memproses pengiriman form edit. Perhatikan bahwa HTTP method-nya adalah PUT, bukan POST. Dalam konvensi RESTful, POST membuat resource baru sedangkan PUT memperbarui resource yang sudah ada.

`Route::delete('/entries/{entry}', ...)` menangani penghapusan sebuah entri. Method DELETE menandakan bahwa resource pada URL ini harus dihapus.

---

## Step 2: Menambahkan Controller Method {#step-2-add-the-controller-methods}

Buka `app/Http/Controllers/EntryController.php` dan tambahkan method `edit()`, `update()`, dan `destroy()`. Berikut adalah controller lengkapnya:

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
            ->with('success', 'Entry updated successfully.');
    }

    public function destroy(Entry $entry): RedirectResponse
    {
        if ($entry->user_id !== auth()->id()) {
            abort(403);
        }

        $entry->delete();

        return redirect('/entries')
            ->with('success', 'Entry deleted successfully.');
    }
}
```

> **Catatan tentang `index()`:** Method `index()` saat ini menggunakan `Entry::with('user')->latest()->get()`, yang mengambil semua entri dari semua pengguna. Ini bersifat sementara. Setelah kita menyelesaikan sistem authentication di Lesson 11 dan memindahkan `/entries` ke dalam group `middleware('auth')`, kita akan memperbarui ini menjadi `auth()->user()->entries()->latest()->get()` sehingga setiap pengguna hanya melihat entri miliknya sendiri.

Mari kita lihat setiap method baru secara lebih detail.

### Method `edit()` {#the-edit-method}

```php
public function edit(Entry $entry)
{
    if ($entry->user_id !== auth()->id()) {
        abort(403);
    }

    return view('entries.edit', compact('entry'));
}
```

Method ini secara struktur identik dengan `show()`. Method ini menerima objek `Entry` melalui Route Model Binding, memeriksa bahwa pengguna yang sedang login memiliki entri tersebut, dan meneruskannya ke sebuah view. Perbedaannya murni terletak pada view: `show` menampilkan halaman detail yang hanya bisa dibaca, sedangkan `edit` menampilkan form yang sudah terisi otomatis dengan data entri saat ini.

### Method `update()` {#the-update-method}

```php
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
        ->with('success', 'Entry updated successfully.');
}
```

Bandingkan ini dengan method `store()` dari Lesson 8. Aturan validasinya identik karena field yang sama membutuhkan batasan yang sama, baik saat membuat maupun saat memperbarui. Perbedaan utamanya terletak pada cara data disimpan: `store()` menggunakan `$request->user()->entries()->create($validated)` untuk membuat record baru, sedangkan `update()` menggunakan `$entry->update($validated)` untuk memperbarui record yang sudah ada.

`$entry->update($validated)` adalah satu baris yang memperbarui entri di database dengan data yang sudah divalidasi. Eloquent secara otomatis mengatur kolom `updated_at` ke waktu saat ini. Setelah penyimpanan, kita melakukan redirect ke halaman detail entri (bukan ke listing) sehingga pengguna dapat langsung melihat perubahannya.

### Method `destroy()` {#the-destroy-method}

```php
public function destroy(Entry $entry): RedirectResponse
{
    if ($entry->user_id !== auth()->id()) {
        abort(403);
    }

    $entry->delete();

    return redirect('/entries')
        ->with('success', 'Entry deleted successfully.');
}
```

Ini adalah method paling sederhana di dalam controller. Setelah pemeriksaan kepemilikan, `$entry->delete()` menghapus record dari database secara permanen. Kita melakukan redirect ke listing entries karena entri tersebut sudah tidak ada lagi, sehingga tidak ada tempat lain untuk dituju.

### Mengapa Setiap Method Membutuhkan `abort(403)` {#why-every-method-needs-abort-403}

Anda mungkin sudah memperhatikan bahwa pemeriksaan kepemilikan muncul di setiap method yang bekerja dengan entri tertentu: `show()`, `edit()`, `update()`, dan `destroy()`. Pengulangan ini disengaja.

Meskipun entri dimaksudkan untuk bersifat privat, pengguna yang kreatif bisa saja mencoba menebak URL milik entri orang lain. Jika entri Anda berada di `/entries/5`, tidak ada yang menghalangi pengguna lain untuk mengetikkan `/entries/5/edit` di browser mereka dan mencoba memodifikasinya. Pemeriksaan `abort(403)` memastikan bahwa operasi apa pun, baik membaca, mengedit, maupun menghapus, hanya berhasil jika entri tersebut benar-benar dimiliki oleh pengguna yang sedang login. Pengguna lainnya akan mendapatkan response 403 Forbidden.

Pada aplikasi yang lebih besar, pola ini biasanya dikelola melalui sistem Policy atau Gate milik Laravel, yang memusatkan logika otorisasi. Namun prinsipnya tetap sama persis: verifikasi kepemilikan sebelum mengizinkan tindakan apa pun.

---

## Step 3: Membuat View Form Edit {#step-3-create-the-edit-form-view}

Buat file `resources/views/entries/edit.blade.php`:

```html
<x-layout :title="'Edit: ' . $entry->title . ' — Catatku'">

    <div class="mb-6">
        <a href="/entries/{{ $entry->id }}"
           class="text-sm text-gray-400 hover:text-gray-700">
            ← Back to entry
        </a>
    </div>

    <h2 class="text-lg font-semibold text-gray-900 mb-4">Edit Entry</h2>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
        <form method="POST" action="/entries/{{ $entry->id }}">
            @csrf
            @method('PUT')

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
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent resize-y
                           {{ $errors->has('content') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}"
                >{{ old('content', $entry->content) }}</textarea>
                @error('content')
                    <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Buttons --}}
            <div class="flex items-center justify-between">
                <a href="/entries/{{ $entry->id }}"
                   class="text-sm text-gray-500 hover:text-gray-900">
                    Cancel
                </a>
                <button type="submit"
                    class="bg-gray-900 text-white text-sm px-5 py-2 rounded-lg
                           hover:bg-gray-700 transition-colors">
                    Save Changes
                </button>
            </div>

        </form>
    </div>

</x-layout>
```

Form ini terlihat sangat mirip dengan form create dari Lesson 8, tetapi ada tiga perbedaan penting.

`@method('PUT')` muncul tepat setelah `@csrf`. Ini memberi tahu Laravel untuk memperlakukan pengiriman form sebagai request PUT, meskipun atribut `method` pada form HTML adalah `POST`. Kita akan menjelaskan mengapa hal ini diperlukan pada bagian referensi di bawah.

`old('title', $entry->title)` menggunakan argumen kedua. Helper `old()` menerima nilai default sebagai parameter keduanya. Saat halaman edit pertama kali dimuat, belum ada input "old" di session, sehingga `old()` jatuh kembali ke `$entry->title`, yaitu nilai entri saat ini dari database. Jika pengguna mengirimkan form dan validasi gagal, `old()` mengembalikan nilai yang baru saja mereka ketik (argumen pertama lebih diutamakan), sehingga mereka tidak kehilangan perubahan mereka. Pola dua argumen ini adalah yang membuat form edit bekerja dengan benar pada kedua skenario.

`action="/entries/{{ $entry->id }}"` mengarahkan form ke URL entri yang spesifik, bukan ke `/entries` seperti pada form create. Dikombinasikan dengan `@method('PUT')`, ini memberi tahu Laravel untuk merutekan pengiriman ke method `update()`.

---

## Step 4: Memverifikasi Semua Route {#step-4-verify-all-routes}

Jalankan perintah berikut untuk memastikan bahwa semua route sudah terdaftar dengan benar:

```bash
php artisan route:list
```

Output yang diharapkan:

```
$ php artisan route:list

  GET|HEAD  / ............................................... routes/web.php:6
  GET|HEAD  dev-login ...................................... routes/web.php:22
  GET|HEAD  entries .................................... EntryController@index
  POST      entries .................................... EntryController@store
  GET|HEAD  entries/create ............................ EntryController@create
  GET|HEAD  entries/{entry} ............................. EntryController@show
  PUT       entries/{entry} ........................... EntryController@update
  DELETE    entries/{entry} .......................... EntryController@destroy
  GET|HEAD  entries/{entry}/edit ........................ EntryController@edit
```

Ini adalah kumpulan lengkap route RESTful untuk resource entries. Tujuh route, tujuh controller method, mencakup setiap operasi CRUD.

---

## Step 5: Menguji Edit dan Delete {#step-5-test-edit-and-delete}

Pastikan Anda sudah login (melalui `/dev-login`), lalu uji alur lengkapnya:

1. Buka `http://127.0.0.1:8000/entries` dan pastikan Anda memiliki setidaknya satu entri. Jika belum ada, buat satu dari `/entries/create`.
2. Klik link **Edit** pada salah satu kartu entri. Form edit seharusnya terbuka dengan field title dan content yang sudah terisi otomatis dengan data entri saat ini.
![access edit page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/11-access-edit-page.webp)

3. Ubah title atau content, lalu klik **Save Changes**. Anda akan diarahkan ke halaman detail entri dengan pesan sukses berwarna hijau yang bertuliskan "Entry updated successfully." Konten seharusnya mencerminkan perubahan Anda.
![change title or content](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/12-change-title-for-edit-feature-testing.webp)

![entry updated](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/13-entry-updated.webp)

4. Kembali ke listing entries dan klik **Delete** pada salah satu entri. Sebuah dialog konfirmasi browser akan muncul dengan pertanyaan "Delete this entry?" Klik OK. Anda akan diarahkan ke listing dengan pesan sukses yang bertuliskan "Entry deleted successfully." dan entri tersebut tidak akan muncul lagi.

![test delete](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/14-test-delete.webp)

![entry deleted](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/15-entry-deleted.webp)

5. Coba uji pemeriksaan otorisasi. Kita dapat menggunakan Tinker untuk menambahkan pengguna baru, sama seperti yang kita lakukan di Lesson 6. Setelah itu, kita dapat login ke akun kedua dengan cara yang sama, yaitu mengubah nilai `id` pada `auth()->loginUsingId(1)` di route `/dev-login` menjadi 2. Login ke akun kedua kita dengan membuka `http://127.0.0.1:8000/entries` di browser. Setelah itu, kita dapat mencoba mengklik "Read" pada salah satu data entri milik akun User 1. Anda seharusnya melihat error 403 Forbidden.

![error 403](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/07-error-403.webp)

---

## Apa itu Method Spoofing? {#what-is-method-spoofing}

Form HTML hanya mendukung dua HTTP method: GET dan POST. Ini adalah keterbatasan pada spesifikasi HTML itu sendiri, bukan pada Laravel atau PHP. Namun konvensi routing RESTful menggunakan method tambahan seperti PUT (untuk update) dan DELETE (untuk penghapusan) agar tujuan dari setiap request menjadi jelas.

Laravel menyelesaikan ketidaksesuaian ini dengan **method spoofing**. Saat Anda menyertakan `@method('PUT')` di dalam sebuah form, Blade akan menghasilkan field input tersembunyi:

```html
<input type="hidden" name="_method" value="PUT">
```

Form tersebut tetap dikirim sebagai request POST (karena itulah yang didukung oleh HTML), tetapi Laravel membaca field `_method` dan memperlakukan request tersebut seolah-olah merupakan request PUT. Mekanisme yang sama berlaku untuk `@method('DELETE')`.

Inilah sebabnya form delete pada komponen EntryCard menggunakan `method="POST"` di HTML namun menyertakan `@method('DELETE')`:

```html
<form method="POST" action="/entries/{{ $entry->id }}">
    @csrf
    @method('DELETE')
    <button type="submit">Delete</button>
</form>
```

Browser mengirimkannya sebagai POST, tetapi Laravel merutekannya ke method `destroy()` karena adanya field `_method`. Pola ini bukan hal unik milik Laravel. Banyak framework web menggunakan pendekatan yang sama karena mereka semua menghadapi keterbatasan HTML yang sama.

---

## Konvensi Routing RESTful {#restful-routing-conventions}

Laravel mengikuti konvensi RESTful untuk penamaan route dan controller method. Berikut adalah tabel lengkap untuk resource "entries":

| Action | HTTP Method | URL | Controller Method |
|--------|-------------|-----|-------------------|
| List all | GET | `/entries` | `index()` |
| Show create form | GET | `/entries/create` | `create()` |
| Save new | POST | `/entries` | `store()` |
| Show detail | GET | `/entries/{entry}` | `show()` |
| Show edit form | GET | `/entries/{entry}/edit` | `edit()` |
| Save changes | PUT/PATCH | `/entries/{entry}` | `update()` |
| Delete | DELETE | `/entries/{entry}` | `destroy()` |

Dengan mengikuti konvensi ini, siapa pun yang familiar dengan Laravel dapat langsung memprediksi struktur route hanya dari nama controller dan method. Konsistensi ini membuat codebase lebih mudah dijelajahi, terutama saat bekerja dalam tim.

Perhatikan bahwa `create` dan `store` terpisah, begitu juga `edit` dan `update`. Ini mencerminkan pola form dua langkah: langkah pertama (GET) menampilkan form, dan langkah kedua (POST/PUT) memproses pengiriman. Pemisahan ini juga berarti bahwa jika validasi gagal pada langkah kedua, form (langkah pertama) dapat ditampilkan kembali dengan error tanpa kebingungan tentang URL mana yang harus dituju untuk redirect.

---

## Kesimpulan {#conclusion}

Siklus CRUD kini sudah lengkap. Ketujuh operasi yang membentuk manajemen entri sudah berjalan dengan route, controller method, dan view yang tepat. Berikut adalah poin-poin pentingnya:

- Form HTML hanya mendukung GET dan POST. **Method spoofing** dengan `@method('PUT')` dan `@method('DELETE')` memungkinkan Laravel memperlakukan pengiriman POST sebagai request PUT atau DELETE agar sesuai dengan konvensi RESTful.
- `@method('PUT')` menghasilkan `<input type="hidden" name="_method" value="PUT">`. Laravel membaca field ini untuk menentukan HTTP method yang sebenarnya dimaksudkan.
- **Form edit** secara struktur mirip dengan form create, dengan dua perbedaan: form edit menyertakan `@method('PUT')`, dan menggunakan `old('field', $entry->field)` untuk mengisi field secara otomatis dengan data yang sudah ada.
- `old('field', $default)` dengan **argumen kedua** sangat penting untuk form edit. Pada saat dimuat pertama kali, ia menampilkan nilai database saat ini. Setelah validasi gagal, ia menampilkan apa yang baru saja diketik pengguna.
- `$entry->update($validated)` memodifikasi record yang sudah ada di database. Eloquent secara otomatis memperbarui timestamp `updated_at`.
- `$entry->delete()` menghapus record secara permanen dari database. Setelah penghapusan, lakukan redirect ke listing karena entri tersebut sudah tidak ada lagi.
- Setiap method yang beroperasi pada entri tertentu menyertakan pemeriksaan kepemilikan **`abort(403)`** untuk memastikan hanya pemilik entri yang dapat membaca, mengedit, atau menghapusnya.
- **Konvensi routing RESTful** menyediakan struktur yang dapat diprediksi dan menjadi standar industri: tujuh route, tujuh controller method, masing-masing dengan nama dan tujuan yang jelas.
- `php artisan route:list` menampilkan semua route yang terdaftar dan berguna untuk memverifikasi bahwa struktur route Anda sudah lengkap dan benar.
- Method `index()` saat ini menampilkan semua entri. Ini akan diperbarui di Lesson 11 agar hanya menampilkan entri milik pengguna yang sedang login setelah sistem authentication lengkap diterapkan.

Pada dua lesson berikutnya, kita akan membangun sistem authentication yang sesungguhnya: halaman registrasi untuk membuat akun baru dan halaman login yang memverifikasi identitas pengguna sebelum memberikan akses. Route sementara `/dev-login` telah menyelesaikan tugasnya dan akhirnya akan dihapus.
