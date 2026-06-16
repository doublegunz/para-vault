## 1. Sebelum Anda Memulai

Entri jurnal menjadi lebih ekspresif dengan gambar. Sebuah entri liburan lebih hidup dengan foto dari pantai. Sebuah catatan resep lebih jelas dengan gambar hidangan yang sudah jadi. Facade `Storage` Laravel menyediakan API yang bersih dan terpadu untuk menyimpan file di disk lokal atau layanan cloud seperti Amazon S3, menggunakan kode yang sama untuk keduanya.

Lesson ini mengajarkan Anda menangani file upload di Laravel: memvalidasi tipe dan ukuran file, menyimpan file di disk, menampilkan gambar yang diupload di view, dan membersihkan file lama selama update. Anda akan menambahkan fitur cover image ke entri Catatku, dan sepanjang jalan Anda akan mempelajari mengapa storage symlink ada dan bagaimana menghindari jebakan umum berupa file yatim.

### What You'll Build

Anda akan menambahkan cover image opsional ke setiap entri jurnal. User dapat mengupload sebuah gambar saat membuat atau mengedit sebuah entri, dan gambar ditampilkan di bagian atas halaman detail entri.

### What You'll Learn

- ✅ Menangani file upload dengan `$request->file()`
- ✅ Memvalidasi file: `image`, `mimes`, `max`, `dimensions`
- ✅ Menyimpan file: `store()` dan public disk
- ✅ Membuat storage symbolic link
- ✅ Menampilkan gambar yang diupload dengan `asset('storage/...')`
- ✅ Menghapus file lama selama update

### What You'll Need

- Lesson 6 sudah selesai

---

## 2. Setup: Storage Link dan Migration

Sebelum mengupload file, Anda membutuhkan dua hal: sebuah symbolic link agar browser dapat mengakses file yang tersimpan, dan sebuah kolom database untuk menyimpan path file. Tanpa symbolic link, file Anda akan tersimpan dengan benar tetapi tidak dapat dijangkau melalui URL.

### Step 1: Membuat Symbolic Link

Laravel menyimpan file yang diupload di `storage/app/public/`, yang tidak dapat diakses secara langsung dari browser. Symbolic link membuat sebuah shortcut dari `public/storage` ke `storage/app/public/`, sehingga sebuah file di `storage/app/public/avatars/foo.jpg` menjadi dapat diakses di `http://yoursite.com/storage/avatars/foo.jpg`.

```bash
php artisan storage:link
```

Anda akan melihat: "The [public/storage] link has been connected to [storage/app/public]." Perintah ini hanya perlu dijalankan sekali per environment (local, staging, production). Anda tidak perlu menjalankannya ulang pada setiap deployment kecuali symlink dihapus secara manual.

### Step 2: Menambahkan Kolom Cover Image

Buat sebuah migration untuk menambahkan kolom path cover image ke tabel entries.

```bash
php artisan make:migration add_cover_image_to_entries --table=entries
```

Flag `--table=entries` menghasilkan kerangka migration yang memodifikasi tabel `entries` yang sudah ada alih-alih membuat yang baru. Buka file migration dan tambahkan definisi kolom.

```php
public function up(): void
{
    Schema::table('entries', function (Blueprint $table) {
        $table->string('cover_image')->nullable()->after('content');
    });
}

public function down(): void
{
    Schema::table('entries', function (Blueprint $table) {
        $table->dropColumn('cover_image');
    });
}
```

Mari kita lihat setiap bagian. `Schema::table('entries', ...)` membuka tabel entries yang sudah ada untuk dimodifikasi. `$table->string('cover_image')` membuat kolom VARCHAR untuk menampung path file (bukan file itu sendiri; file berada di disk, bukan di database). `->nullable()` membuat kolom bersifat opsional, yang penting karena cover image tidak wajib untuk sebuah entri. `->after('content')` menempatkan kolom setelah kolom content untuk keterbacaan saat Anda memeriksa skema database. Method `down()` menggunakan `$table->dropColumn('cover_image')` untuk membalik perubahan jika diperlukan. Jalankan migration untuk menerapkan perubahan.

```bash
php artisan migrate
```

### Step 3: Memperbarui Model Entry

Buka `app/Models/Entry.php` dan tambahkan `'cover_image'` ke attribute `#[Fillable]` di bagian atas class.

```php
<?php
// ... others lines of code

#[Fillable(['title', 'content', 'cover_image'])]
class Entry extends Model
{
    // ... other methods and properties
}
```

Tanpa menambahkan `cover_image` ke `#[Fillable]`, method `create()` dan `update()` akan diam-diam mengabaikan field tersebut, dan path gambar tidak akan pernah disimpan ke database. Ini akan menyebabkan bug yang membuat frustrasi di mana upload tampak "berfungsi" (file berakhir di disk) tetapi entri tidak memiliki referensi ke sana.

---

## 3. Menangani Upload di Controller

Penanganan file upload memiliki tiga bagian: validasi, penyimpanan, dan penyimpanan path. Controller mengelola ketiganya secara berurutan.

### Step 1: Memperbarui Method Store

Buka `app/Http/Controllers/EntryController.php` dan perbarui method `store`. Tambahkan import `Storage` ke bagian atas file bersama statement `use` yang sudah ada, lalu ganti body method `store` seperti ditunjukkan di bawah ini.

```php
<?php
// ... others lines of code
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class EntryController extends Controller
{
    // ... other methods

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'cover_image' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
            'tags' => 'nullable|array',
            'tags.*' => 'exists:tags,id',
        ]);

        if ($request->hasFile('cover_image')) {
            $validated['cover_image'] = $request->file('cover_image')
                ->store('entries/covers', 'public');
        }

        $entry = $request->user()->entries()->create([
            'title' => $validated['title'],
            'content' => $validated['content'],
            'cover_image' => $validated['cover_image'] ?? null,
        ]);

        $entry->tags()->sync($validated['tags'] ?? []);

        return redirect()->route('entries.index')->with('success', 'Entry created!');
    }

    // ... other methods
}
```

Menelusuri method ini bagian demi bagian: import `use Illuminate\Support\Facades\Storage;` memungkinkan kita mereferensikan facade Storage untuk penghapusan file di method selanjutnya. Array validasi menyertakan aturan baru untuk `cover_image`: `nullable` membuatnya opsional, `image` memastikan file yang diupload adalah sebuah gambar berdasarkan kontennya alih-alih hanya ekstensinya, `mimes:jpg,jpeg,png,webp` membatasi ke empat format gambar umum, dan `max:2048` membatasi file hingga 2048 kilobyte (2 MB).

Pemeriksaan `if ($request->hasFile('cover_image'))` mengembalikan true hanya ketika sebuah file sungguhan diupload; ia mengembalikan false ketika user mengirim form tanpa memilih file. Di dalamnya, `$request->file('cover_image')->store('entries/covers', 'public')` melakukan tiga hal: ia menghasilkan nama file unik (berbasis UUID) untuk mencegah benturan, menyimpan file ke `storage/app/public/entries/covers/`, dan mengembalikan path relatif seperti `entries/covers/abc123.jpg`. Kita menugaskan path yang dikembalikan ini ke `$validated['cover_image']` sehingga ia berakhir di database. Saat membuat entri, `$validated['cover_image'] ?? null` menggunakan path yang diupload jika tersedia atau null jika tidak.

### Step 2: Memperbarui Method Update

Method update membutuhkan logika tambahan untuk menghapus gambar lama ketika gambar baru diupload. Tanpa pembersihan ini, storage terisi dengan file yatim yang tidak direferensikan apa pun. Masih di `app/Http/Controllers/EntryController.php`, tambahkan import facade `Gate` ke statement `use` yang sudah ada di bagian atas, lalu perbarui method `update` seperti ditunjukkan di bawah ini.

```php
<?php
// ... others lines of code
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;

class EntryController extends Controller
{
    // ... other methods

    public function update(Request $request, Entry $entry)
    {
        Gate::authorize('update', $entry);

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'cover_image' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
            'tags' => 'nullable|array',
            'tags.*' => 'exists:tags,id',
        ]);

        if ($request->hasFile('cover_image')) {
            if ($entry->cover_image) {
                Storage::disk('public')->delete($entry->cover_image);
            }
            $validated['cover_image'] = $request->file('cover_image')
                ->store('entries/covers', 'public');
        }

        $entry->update([
            'title' => $validated['title'],
            'content' => $validated['content'],
            'cover_image' => $validated['cover_image'] ?? $entry->cover_image,
        ]);

        $entry->tags()->sync($validated['tags'] ?? []);

        return redirect()->route('entries.index')->with('success', 'Entry updated!');
    }

    // ... other methods
}
```

Membaca method update ini dengan cermat: method dimulai seperti method update lainnya, dengan authorization dan validasi. `if ($request->hasFile('cover_image'))` terluar hanya berjalan ketika sebuah gambar baru sungguh-sungguh diupload. Di dalam blok tersebut, `if ($entry->cover_image)` yang bersarang memeriksa apakah path gambar lama ada di database. Jika ya, `Storage::disk('public')->delete($entry->cover_image)` menghapus file lama dari disk untuk mencegah akumulasi file yatim. Lalu kita menyimpan file baru menggunakan pola yang sama seperti method store.

Pemanggilan `$entry->update(...)` menggunakan `$validated['cover_image'] ?? $entry->cover_image` sebagai nilainya: jika user mengupload gambar baru, gunakan path baru itu; jika tidak, pertahankan path yang ada. Ini memastikan bahwa mengedit sebuah entri tanpa mengupload gambar baru tidak mengosongkan cover image yang sudah ada.

---

## 4. Memperbarui View

Form create dan edit keduanya membutuhkan sebuah file input dan attribute `enctype`, dan view show perlu menampilkan gambar yang diupload. Masing-masing adalah file terpisah yang perlu diperbarui.

### Step 1: Menambahkan File Input ke Form Create

Buka `resources/views/entries/create.blade.php` dan buat dua perubahan: tambahkan `enctype="multipart/form-data"` ke tag form, dan tambahkan sebuah section cover image di bawah textarea content dan di atas section tags.

Attribute `enctype="multipart/form-data"` pada tag `<form>` sangat penting dan mudah dilupakan. Tanpanya, browser mengirim form sebagai teks URL-encoded, dan `$request->file()` mengembalikan null karena data file tidak pernah mencapai server. `<input type="file" name="cover_image">` membuat tombol file picker. Attribute `accept="image/*"` hanya menampilkan file gambar di dialog file picker OS sebagai petunjuk kenyamanan, tetapi ini bukan keamanan; validasi sisi server adalah penegakan yang sebenarnya. Blok `@error('cover_image')` menampilkan pesan error validasi yang spesifik untuk field ini.

Setelah perubahan, file `create.blade.php` lengkap terlihat seperti ini:

```blade
<x-layout title="Write Entry — Catatku">

    <div class="mb-6">
        <a href="{{ route('entries.index') }}" class="text-sm text-gray-400 hover:text-gray-700">
            ← Back to list
        </a>
    </div>

    <h2 class="text-lg font-semibold text-gray-900 mb-4">Write New Entry</h2>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
        <form method="POST" action="{{ route('entries.store') }}" enctype="multipart/form-data">
            @csrf

            {{-- Title --}}
            <div class="mb-5">
                <label for="title" class="block text-sm font-medium text-gray-700 mb-1">
                    Title
                </label>
                <input type="text" id="title" name="title" value="{{ old('title') }}" placeholder="Entry title..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent
                           {{ $errors->has('title') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}" autofocus>
                @error('title')
                <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Content --}}
            <div class="mb-6">
                <label for="content" class="block text-sm font-medium text-gray-700 mb-1">
                    Content
                </label>
                <textarea id="content" name="content" rows="12" placeholder="Write your entry here..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent resize-y
                           {{ $errors->has('content') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}">{{ old('content') }}</textarea>
                @error('content')
                <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Cover image --}}
            <div style="margin-bottom: 16px;">
                <label style="display: block; font-weight: bold; margin-bottom: 6px; color: #1e293b;">
                    Cover Image (optional)
                </label>
                <input type="file" name="cover_image" accept="image/*"
                       style="border: 1px solid #d1d5db; border-radius: 6px; padding: 8px; width: 100%; box-sizing: border-box;">
                <p style="color: #9ca3af; font-size: 0.8em; margin-top: 4px;">
                    JPG, PNG, or WebP. Max 2MB.
                </p>
                @error('cover_image')
                    <p style="color: #dc2626; font-size: 0.85em; margin-top: 4px;">{{ $message }}</p>
                @enderror
            </div>

            {{-- Tags --}}
            <div style="margin-bottom: 16px;">
                <label style="display: block; font-weight: bold; margin-bottom: 6px; color: #1e293b;">Tags</label>
                <div style="display: flex; flex-wrap: wrap; gap: 10px;">
                    @foreach ($tags as $tag)
                        <label style="display: flex; align-items: center; gap: 4px; cursor: pointer;">
                            <input
                                type="checkbox"
                                name="tags[]"
                                value="{{ $tag->id }}"
                                @checked(is_array(old('tags')) && in_array($tag->id, old('tags')))
                            >
                            {{ $tag->name }}
                        </label>
                    @endforeach
                </div>
            </div>

            {{-- Buttons --}}
            <div class="flex items-center justify-between">
                <a href="{{ route('entries.index') }}" class="text-sm text-gray-500 hover:text-gray-900">
                    Cancel
                </a>
                <button type="submit" class="bg-gray-900 text-white text-sm px-5 py-2 rounded-lg
                           hover:bg-gray-700 transition-colors">
                    Save Entry
                </button>
            </div>

        </form>
    </div>

</x-layout>
```

### Step 2: Menambahkan File Input ke Form Edit

Buka `resources/views/entries/edit.blade.php` dan buat tiga perubahan: tambahkan `enctype="multipart/form-data"` ke tag form, tambahkan sebuah blok yang menampilkan cover image saat ini (jika ada) dengan sebuah checkbox remove, dan tambahkan sebuah file input untuk mengupload gambar baru. Tempatkan section cover image di bawah textarea content dan di atas section tags.

Form edit berbeda dari form create dalam dua hal. Pertama, ia menampilkan cover image yang ada sehingga user dapat melihat apa yang saat ini tersimpan. Kedua, ia memberi user opsi untuk menghapus gambar tanpa menggantinya, menggunakan checkbox sederhana. File input itu sendiri bekerja secara identik dengan form create: membiarkannya kosong berarti "pertahankan gambar yang ada", yang sudah ditangani oleh fallback `$validated['cover_image'] ?? $entry->cover_image` di method update.

Setelah perubahan, file `edit.blade.php` lengkap terlihat seperti ini:

```blade
<x-layout :title="'Edit: ' . $entry->title . ' — Catatku'">

    <div class="mb-6">
        <a href="{{ route('entries.show', $entry) }}" class="text-sm text-gray-400 hover:text-gray-700">
            ← Back to entry
        </a>
    </div>

    <h2 class="text-lg font-semibold text-gray-900 mb-4">Edit Entry</h2>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
        <form method="POST" action="{{ route('entries.update', $entry) }}" enctype="multipart/form-data">
            @csrf
            @method('PUT')

            {{-- Title --}}
            <div class="mb-5">
                <label for="title" class="block text-sm font-medium text-gray-700 mb-1">
                    Title
                </label>
                <input type="text" id="title" name="title" value="{{ old('title', $entry->title) }}"
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent
                           {{ $errors->has('title') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}" autofocus>
                @error('title')
                <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Content --}}
            <div class="mb-6">
                <label for="content" class="block text-sm font-medium text-gray-700 mb-1">
                    Content
                </label>
                <textarea id="content" name="content" rows="12"
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent resize-y
                           {{ $errors->has('content') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}">{{ old('content', $entry->content) }}</textarea>
                @error('content')
                <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Cover image --}}
            <div style="margin-bottom: 16px;">
                <label style="display: block; font-weight: bold; margin-bottom: 6px; color: #1e293b;">
                    Cover Image (optional)
                </label>
                @if($entry->cover_image)
                    <img src="{{ asset('storage/' . $entry->cover_image) }}"
                         alt="{{ $entry->title }}"
                         style="max-width: 100%; height: 120px; object-fit: cover; border-radius: 6px; margin-bottom: 8px;">
                    <label style="display: flex; align-items: center; gap: 6px; color: #dc2626; font-size: 0.9em; cursor: pointer; margin-bottom: 8px;">
                        <input type="checkbox" name="remove_image" value="1">
                        Remove current image
                    </label>
                @endif
                <input type="file" name="cover_image" accept="image/*"
                       style="border: 1px solid #d1d5db; border-radius: 6px; padding: 8px; width: 100%; box-sizing: border-box;">
                <p style="color: #9ca3af; font-size: 0.8em; margin-top: 4px;">
                    JPG, PNG, or WebP. Max 2MB. Leave empty to keep the current image.
                </p>
                @error('cover_image')
                    <p style="color: #dc2626; font-size: 0.85em; margin-top: 4px;">{{ $message }}</p>
                @enderror
            </div>

            {{-- Tags --}}
            <div style="margin-bottom: 16px;">
                <label style="display: block; font-weight: bold; margin-bottom: 6px; color: #1e293b;">Tags</label>
                <div style="display: flex; flex-wrap: wrap; gap: 10px;">
                    @foreach ($tags as $tag)
                        <label style="display: flex; align-items: center; gap: 4px; cursor: pointer;">
                            <input
                                type="checkbox"
                                name="tags[]"
                                value="{{ $tag->id }}"
                                @checked(
                                    (is_array(old('tags')) && in_array($tag->id, old('tags')))
                                    || (!old('tags') && $entry->tags->contains($tag->id))
                                )
                            >
                            {{ $tag->name }}
                        </label>
                    @endforeach
                </div>
            </div>

            {{-- Buttons --}}
            <div class="flex items-center justify-between">
                <a href="{{ route('entries.show', $entry) }}" class="text-sm text-gray-500 hover:text-gray-900">
                    Cancel
                </a>
                <button type="submit" class="bg-gray-900 text-white text-sm px-5 py-2 rounded-lg
                           hover:bg-gray-700 transition-colors">
                    Save Changes
                </button>
            </div>

        </form>
    </div>

</x-layout>
```

### Step 3: Menampilkan Gambar di View Show

Buka `resources/views/entries/show.blade.php` dan tambahkan blok tampilan gambar di bagian paling atas kontainer `<div>`, di atas judul entri.

Pemeriksaan `@if($entry->cover_image)` memastikan kita hanya merender tag gambar ketika entri memilikinya, menghindari ikon gambar rusak ketika tidak ada cover. Helper `asset('storage/' . $entry->cover_image)` menghasilkan URL publik lengkap ke gambar. Prefix `storage/` memetakan ke symbolic link `public/storage`, yang menunjuk ke `storage/app/public/`, sehingga path tersimpan seperti `entries/covers/abc.jpg` menjadi `http://yoursite.com/storage/entries/covers/abc.jpg`. Attribute `alt` menggunakan judul entri untuk aksesibilitas screen reader. Property CSS `object-fit: cover` memotong gambar secara proporsional sehingga ia mengisi frame pada tinggi maksimum tanpa distorsi.

Setelah perubahan, file `show.blade.php` lengkap terlihat seperti ini:

```blade
<x-layout>
    <div style="max-width: 700px; margin: 0 auto;">

        @if($entry->cover_image)
            <img src="{{ asset('storage/' . $entry->cover_image) }}"
                 alt="{{ $entry->title }}"
                 style="width: 100%; max-height: 300px; object-fit: cover; border-radius: 8px; margin-bottom: 16px;">
        @endif

        {{-- Entry content --}}
        <h1 style="font-size: 1.5em; color: #1e293b; margin-bottom: 8px;">{{ $entry->title }}</h1>
        <p style="color: #888; font-size: 0.85em; margin-bottom: 16px;">
            Written {{ $entry->created_at->diffForHumans() }}
        </p>
        <div style="line-height: 1.7; color: #333; margin-bottom: 30px;">
            {{ $entry->content }}
        </div>

        <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 20px 0;">

        {{-- Comments section --}}
        <h2 style="font-size: 1.2em; color: #1e293b; margin-bottom: 16px;">
            Comments ({{ $entry->comments->count() }})
        </h2>

        @forelse ($entry->comments as $comment)
            <div style="padding: 12px 0; border-bottom: 1px solid #f3f4f6;">
                <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
                    <strong style="color: #1e293b;">{{ $comment->user->name }}</strong>
                    <span style="color: #9ca3af; font-size: 0.8em;">{{ $comment->created_at->diffForHumans() }}</span>
                </div>
                <p style="color: #4b5563; margin: 0;">{{ $comment->body }}</p>
            </div>
        @empty
            <p style="color: #9ca3af; text-align: center; padding: 20px 0;">
                No comments yet. Be the first to comment!
            </p>
        @endforelse

        {{-- Comment form --}}
        <div style="margin-top: 20px; background: #f9fafb; padding: 16px; border-radius: 8px;">
            <h3 style="font-size: 1em; margin-bottom: 10px; color: #1e293b;">Write a Comment</h3>

            <form method="POST" action="{{ route('comments.store', $entry) }}">
                @csrf

                <textarea
                    name="body"
                    rows="3"
                    placeholder="Write your comment..."
                    style="width: 100%; padding: 10px; border: 1px solid #d1d5db; border-radius: 6px; resize: vertical; box-sizing: border-box; font-family: inherit;"
                >{{ old('body') }}</textarea>

                @error('body')
                    <p style="color: #dc2626; font-size: 0.85em; margin: 4px 0 0;">{{ $message }}</p>
                @enderror

                <button
                    type="submit"
                    style="margin-top: 10px; background: #2563eb; color: white; padding: 8px 20px; border: none; border-radius: 6px; cursor: pointer; font-weight: bold;"
                >
                    Post Comment
                </button>
            </form>
        </div>

        <a href="{{ route('entries.index') }}" style="display: inline-block; margin-top: 20px; color: #2563eb; text-decoration: none;">
            &larr; Back to entries
        </a>
    </div>
</x-layout>
```

---

## 5. Menjalankan dan Menguji

Mari kita verifikasi alur upload lengkap bekerja dari awal hingga akhir di browser.

### Step 1: Menjalankan Server

Jalankan development server dan biarkan tetap berjalan selama pengujian Anda.

```bash
php artisan serve
```

### Step 2: Membuat Entri dengan Cover Image

Buka `http://localhost:8000` dan login. Navigasikan ke halaman pembuatan entri. Isi title dan content seperti biasa. Klik file input dan pilih sebuah gambar JPG atau PNG di bawah 2 MB. Kirim form. Anda seharusnya diarahkan ke daftar entri dengan pesan sukses.

### Step 3: Melihat Entri

Klik entri yang baru saja Anda buat. Cover image seharusnya muncul di bagian atas entri, di atas title, terpasang ke frame. Jika gambar tidak muncul, periksa bahwa Anda sudah menjalankan `php artisan storage:link` dan bahwa direktori `storage/app/public/entries/covers/` berisi file yang diupload. Anda dapat memeriksa source HTML untuk melihat URL yang dihasilkan; ia seharusnya terlihat seperti `http://localhost:8000/storage/entries/covers/xxx.jpg`.

### Step 4: Menguji Validasi

Coba upload sebuah file yang bukan gambar, seperti PDF. Anda akan melihat error validasi: "The cover image field must be an image." Coba upload sebuah gambar yang lebih besar dari 2 MB. Anda akan melihat: "The cover image field must not be greater than 2048 kilobytes." Pesan-pesan ini mengonfirmasi aturan validasi berjalan dengan benar.

### Step 5: Menguji Update dengan Gambar Baru

Edit entri dan upload gambar yang berbeda. Setelah menyimpan, halaman detail seharusnya menampilkan gambar baru. Periksa direktori `storage/app/public/entries/covers/`: file gambar lama seharusnya terhapus dan hanya yang baru yang tersisa.

### Step 6: Menguji Update Tanpa Mengupload Gambar Baru

Edit entri, ubah hanya title atau content, dan kirim tanpa menyentuh file input. Cover image yang ada seharusnya masih ada setelah menyimpan, membuktikan bahwa fallback `?? $entry->cover_image` di method update bekerja dengan benar.

---

## 6. Memperbaiki Error pada Kode Anda

Berikut adalah kesalahan paling umum saat mengimplementasikan file upload di Laravel.

**Error 1: `enctype` hilang pada tag form.**

Ini adalah kesalahan file upload yang paling umum. Tanpa tipe encoding `multipart/form-data`, browser mengirim form sebagai teks URL-encoded dan menghilangkan data file sepenuhnya. Server menerima request tetapi file tidak ada.

```blade
{{-- Wrong: no enctype, file data is never sent to the server --}}
<form method="POST" action="{{ route('entries.store') }}">

{{-- Correct: enctype tells the browser to include file data in the request --}}
<form method="POST" action="{{ route('entries.store') }}" enctype="multipart/form-data">
```

Tanpa `enctype="multipart/form-data"`, `$request->hasFile('cover_image')` selalu mengembalikan false dan `$request->file('cover_image')` mengembalikan null, bahkan ketika user memilih sebuah file. Menambahkan `enctype="multipart/form-data"` ke tag pembuka `<form>` adalah perbaikannya. Attribute ini diperlukan pada setiap form yang menyertakan sebuah file input.

---

**Error 2: Menyimpan di disk yang salah.**

Error ini terjadi ketika Anda memanggil `store()` tanpa menentukan disk `public`. Disk default Laravel adalah `local`, yang menyimpan file di `storage/app/`, sebuah direktori privat yang tidak dapat diakses melalui URL. File yang tersimpan di sana tidak dapat ditampilkan di browser.

```php
// Wrong: stores in storage/app/entries/covers/ which is private
$request->file('cover_image')->store('entries/covers');

// Correct: stores in storage/app/public/entries/covers/ which is accessible via symlink
$request->file('cover_image')->store('entries/covers', 'public');
```

Tanpa argumen kedua `'public'`, file berakhir di `storage/app/entries/covers/` dan URL yang dihasilkan oleh `asset('storage/...')` menunjuk ke sebuah file yang tidak ada di direktori publik. Menambahkan `'public'` sebagai argumen kedua menyimpan file di `storage/app/public/entries/covers/`, yang dapat diakses melalui symbolic link di `public/storage`.

---

**Error 3: File tersimpan dengan benar tetapi URL mengembalikan 404.**

Error ini terjadi ketika Anda lupa menjalankan `php artisan storage:link`. File tersimpan di disk yang benar, tetapi direktori `public/storage` tidak ada sebagai symbolic link, sehingga setiap URL yang menunjuk ke `storage/` mengembalikan 404.

```bash
# Wrong: storage:link never run, public/storage directory does not exist
# Result: all image URLs return 404

# Correct: run this once per environment to create the symbolic link
php artisan storage:link
```

Tanpa symbolic link, request ke `http://yoursite.com/storage/entries/covers/abc.jpg` gagal karena web server tidak memiliki direktori `storage` di bawah `public/`. Menjalankan `php artisan storage:link` membuat `public/storage` sebagai symlink yang menunjuk ke `storage/app/public/`, membuat semua file di public disk dapat diakses melalui URL. Jalankan perintah ini sekali saat menyiapkan environment baru.

---

## 7. Latihan

Latihan ini mengembangkan pola file upload ke bagian lain dari Catatku. Latihan 1 menerapkan teknik storage yang sama ke model yang berbeda, Latihan 2 menambahkan alur penghapusan untuk file yang ada, dan Latihan 3 memperketat validasi dengan constraint dimensi.

**Latihan 1:** Tambahkan upload avatar ke profil user. Buat sebuah migration untuk kolom `avatar` pada users, tambahkan penanganan upload ke controller profil, dan tampilkan avatar di samping nama user di komentar.

**Latihan 2:** Tambahkan sebuah checkbox "Remove image" ke form edit yang menghapus cover image tanpa mengupload yang baru. Di controller, periksa checkbox dan panggil `Storage::disk('public')->delete()`.

**Latihan 3:** Tambahkan validasi dimensi gambar: `'cover_image' => 'nullable|image|dimensions:min_width=400,min_height=200|max:2048'`. Uji dengan sebuah gambar yang terlalu kecil.

---

## 8. Solusi

Setiap solusi di bawah ini adalah implementasi lengkap. Solusi untuk Latihan 1 dan 2 memerlukan beberapa file, jadi ikuti langkah-langkah secara berurutan untuk memastikan setiap bagian berada di tempatnya sebelum yang berikutnya bergantung padanya.

**Solusi untuk Latihan 1:**

Buat sebuah migration untuk menambahkan kolom `avatar` ke tabel users.

```bash
php artisan make:migration add_avatar_to_users --table=users
```

Buka file migration dan definisikan kolom.

```php
public function up(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->string('avatar')->nullable()->after('name');
    });
}

public function down(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->dropColumn('avatar');
    });
}
```

`$table->string('avatar')->nullable()` menyimpan path file relatif, bukan gambar itu sendiri. Nullable diperlukan karena user yang sudah ada belum memiliki avatar. Jalankan `php artisan migrate` untuk menerapkan perubahan. Selanjutnya, buat sebuah `ProfileController` untuk menangani update avatar.

```bash
php artisan make:controller ProfileController
```

Buka `app/Http/Controllers/ProfileController.php` dan tambahkan method update.

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    public function edit()
    {
        return view('profile.edit');
    }

    public function update(Request $request)
    {
        $request->validate([
            'avatar' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:1024',
        ]);

        $user = $request->user();

        if ($request->hasFile('avatar')) {
            if ($user->avatar) {
                Storage::disk('public')->delete($user->avatar);
            }
            $user->avatar = $request->file('avatar')->store('avatars', 'public');
            $user->save();
        }

        return back()->with('success', 'Avatar updated.');
    }
}
```

`$user->avatar` menyimpan path yang dikembalikan oleh `store('avatars', 'public')`. `if ($user->avatar)` yang bersarang menghapus file lama sebelum menyimpan yang baru, mengikuti pola pencegahan yatim yang sama yang digunakan di method update entri. Daftarkan route di dalam group middleware `auth` di `routes/web.php`.

```php
Route::get('/profile/edit', [ProfileController::class, 'edit'])->name('profile.edit');
Route::post('/profile', [ProfileController::class, 'update'])->name('profile.update');
```

Untuk menampilkan avatar di samping nama setiap penulis komentar, buka partial komentar di `entries/show.blade.php` dan tambahkan gambar sebelum username.

```blade
@if($comment->user->avatar)
    <img src="{{ asset('storage/' . $comment->user->avatar) }}"
         alt="{{ $comment->user->name }}"
         style="width: 28px; height: 28px; border-radius: 50%; object-fit: cover;">
@endif
<strong style="color: #1e293b;">{{ $comment->user->name }}</strong>
```

`border-radius: 50%` membuat gambar menjadi lingkaran, yang merupakan konvensi visual standar untuk avatar user. `object-fit: cover` memotong gambar secara proporsional untuk mengisi kotak tetap 28x28. Perhatikan bahwa `$comment->user` harus di-eager-load di controller dengan `$entry->load('comments.user')`, yang sudah berada di tempatnya dari Lesson 1.

---

**Solusi untuk Latihan 2:**

Di form edit, tambahkan checkbox remove di bawah blok tampilan cover image yang sudah ada.

```blade
@if($entry->cover_image)
    <img src="{{ asset('storage/' . $entry->cover_image) }}"
         alt="{{ $entry->title }}"
         style="max-width: 100%; height: 120px; object-fit: cover; border-radius: 6px; margin-bottom: 8px;">
    <label style="display: flex; align-items: center; gap: 6px; color: #dc2626; font-size: 0.9em; cursor: pointer;">
        <input type="checkbox" name="remove_image" value="1">
        Remove current image
    </label>
@endif
```

Di `app/Http/Controllers/EntryController.php`, tambahkan blok remove-image di dalam method `update`, sebelum pemeriksaan `hasFile` yang ada. Method `update` lengkap seharusnya terlihat seperti ini:

```php
<?php
// ... others lines of code
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;

class EntryController extends Controller
{
    // ... other methods

    public function update(Request $request, Entry $entry)
    {
        Gate::authorize('update', $entry);

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'cover_image' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
            'tags' => 'nullable|array',
            'tags.*' => 'exists:tags,id',
        ]);

        if ($request->boolean('remove_image') && $entry->cover_image) {
            Storage::disk('public')->delete($entry->cover_image);
            $validated['cover_image'] = null;
        }

        if ($request->hasFile('cover_image')) {
            if ($entry->cover_image) {
                Storage::disk('public')->delete($entry->cover_image);
            }
            $validated['cover_image'] = $request->file('cover_image')
                ->store('entries/covers', 'public');
        }

        $entry->update([
            'title' => $validated['title'],
            'content' => $validated['content'],
            'cover_image' => $validated['cover_image'] ?? $entry->cover_image,
        ]);

        $entry->tags()->sync($validated['tags'] ?? []);

        return redirect()->route('entries.index')->with('success', 'Entry updated!');
    }

    // ... other methods
}
```

`$request->boolean('remove_image')` mengembalikan `true` jika checkbox dicentang dan dikirim bersama form. Guard `&& $entry->cover_image` yang bersarang memastikan kita hanya memanggil delete ketika sebuah path file sungguh-sungguh ada di database, menghindari pemanggilan delete pada path kosong. `Storage::disk('public')->delete($entry->cover_image)` menghapus file fisik. Menetapkan `$validated['cover_image'] = null` kemudian menyebabkan update database membersihkan kolom. Ketika entri kemudian diperbarui, ekspresi `$validated['cover_image'] ?? $entry->cover_image` bernilai `null`, menghapus referensi. Perhatikan bahwa blok `remove_image` berjalan sebelum blok `hasFile`: jika user entah bagaimana mencentang kotak remove dan juga mengupload file baru, upload baru diutamakan karena `hasFile` berjalan kedua dan menimpa `$validated['cover_image']`.

---

**Solusi untuk Latihan 3:**

Buka `app/Http/Controllers/EntryController.php` dan perbarui aturan validasi `cover_image` di method `store` dan `update` untuk menyertakan constraint `dimensions`. Aturannya identik di kedua method. Di bawah ini adalah bagaimana ia terlihat di method `store`; terapkan perubahan yang sama ke `update`.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'cover_image' => 'nullable|image|mimes:jpg,jpeg,png,webp|dimensions:min_width=400,min_height=200|max:2048',
            'tags' => 'nullable|array',
            'tags.*' => 'exists:tags,id',
        ]);

        // ... rest of method unchanged
    }

    // ... other methods
}
```

Aturan `dimensions` menerima daftar constraint yang dipisahkan koma: `min_width=400` mengharuskan gambar setidaknya selebar 400 piksel, dan `min_height=200` mengharuskan setidaknya setinggi 200 piksel. Anda juga dapat menggabungkan constraint seperti `max_width`, `max_height`, dan `ratio` (misalnya, `ratio=16/9`). Ketika sebuah gambar gagal pada aturan ini, Laravel mengembalikan error validasi "The cover image field has invalid image dimensions." Untuk mengujinya, upload sebuah gambar yang lebih kecil dari 400x200 piksel. Perhatikan bahwa aturan `dimensions` hanya bekerja dengan gambar di mana PHP dapat membaca dimensi file melalui `getimagesize()`, sehingga ia memerlukan aturan `image` muncul sebelumnya dalam rantai aturan untuk menjamin file adalah gambar yang valid terlebih dahulu.

---

## Selanjutnya - Lesson 8

Di lesson ini Anda membangun fitur file upload lengkap untuk Catatku. Anda membuat symbolic link `public/storage` sehingga file yang diupload dapat diakses melalui URL, menambahkan kolom `cover_image` yang nullable ke tabel entries, dan menangani validasi file dengan aturan `image`, `mimes`, dan `max` di controller. Anda mempelajari bahwa `store('path', 'public')` menghasilkan nama file unik dan mengembalikan path relatif untuk penyimpanan database, dan bahwa `Storage::disk('public')->delete()` menghapus file lama selama update untuk mencegah file yatim menumpuk di disk.

Di Lesson 8, Anda akan mempelajari pengiriman email dengan Mailable: bagaimana membuat class Mailable, mendesain template email Blade Markdown, mengirim email selamat datang saat registrasi, dan memberi tahu penulis entri ketika seseorang berkomentar di entri mereka.
