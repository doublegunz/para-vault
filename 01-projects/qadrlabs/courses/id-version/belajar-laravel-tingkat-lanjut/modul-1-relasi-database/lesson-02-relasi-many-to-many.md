## 1. Sebelum Anda Memulai

One-to-many mencakup relationship parent-child di mana satu sisi jelas memiliki sisi yang lain. Tetapi beberapa relationship bersifat simetris: sebuah entri dapat memiliki banyak tag, dan sebuah tag dapat dimiliki oleh banyak entri. Tidak ada sisi yang "memiliki" sisi yang lain. Ini adalah relationship many-to-many, dan ia membutuhkan tabel ketiga (sebuah pivot table) untuk menyimpan koneksi antara kedua model.

Lesson ini mengajarkan `belongsToMany`, pivot table, dan method `attach`, `detach`, `sync` untuk mengelola relationship many-to-many. Anda akan menambahkan sistem tagging ke Catatku sehingga user dapat mengkategorikan entri jurnal mereka dengan label seperti "personal", "travel", atau "work". Di akhir lesson Anda akan dapat membuat entri dengan tag, mengedit tag tersebut melalui checkbox, dan menampilkannya sebagai badge berwarna.

### What You'll Build

Anda akan membuat model Tag, sebuah pivot table, dan mengintegrasikan pemilihan tag ke dalam form pembuatan dan pengeditan entri. Tag akan ditampilkan sebagai badge berwarna pada setiap entri, dan Anda akan menambahkan halaman penjelajahan tag sehingga pembaca dapat menampilkan semua tag dan melihat setiap entri di bawah sebuah tag tertentu.

### What You'll Learn

- ✅ `belongsToMany()` pada kedua model
- ✅ Migration pivot table dan konvensi penamaan
- ✅ `attach()`, `detach()`, `sync()`, `toggle()`
- ✅ Melakukan query relationship many-to-many dari kedua sisi (`$entry->tags`, `$tag->entries`)
- ✅ Menampilkan tag di Blade view
- ✅ Pemilihan tag dengan checkbox di form
- ✅ Menjelajahi entri berdasarkan tag dengan route model binding berbasis slug

### What You'll Need

- Lesson 1 sudah selesai dengan komentar yang berfungsi

---

## 2. Membuat Model Tag dan Pivot Table

Sebuah relationship many-to-many membutuhkan tiga tabel database: dua tabel utama (`entries` dan `tags`) dan sebuah pivot table (`entry_tag`) yang menyimpan entri mana yang memiliki tag mana. Setiap baris di pivot table merepresentasikan satu koneksi antara sebuah entri dan sebuah tag, sehingga satu entri yang diberi tiga label akan menghasilkan tiga baris di pivot table.

### Step 1: Membuat Model Tag dan Migration

Jalankan perintah berikut untuk membuat baik model maupun file migration-nya.

```bash
php artisan make:model Tag -m
```

Perintah ini membuat `app/Models/Tag.php` (class model Eloquent) dan sebuah file migration di `database/migrations/` (definisi skema). Flag `-m` adalah shortcut yang meminta Artisan untuk menghasilkan migration bersama model, menghemat Anda dari menjalankan dua perintah terpisah.

### Step 2: Mendefinisikan Migration Tabel Tags

Buka file migration yang baru dibuat dan ganti method `up()` dengan skema berikut.

```php
public function up(): void
{
    Schema::create('tags', function (Blueprint $table) {
        $table->id();
        $table->string('name')->unique();
        $table->string('slug')->unique();
        $table->timestamps();
    });
}
```

Inilah yang dilakukan setiap kolom. `$table->id()` membuat primary key auto-increment bernama `id`. `$table->string('name')->unique()` membuat kolom VARCHAR untuk nama tampilan (misalnya, "Personal" atau "Travel") dan menambahkan unique index sehingga Anda tidak dapat membuat dua tag dengan nama yang sama. `$table->string('slug')->unique()` menyimpan versi nama yang ramah URL (seperti "personal" atau "travel"), juga unik, yang nanti akan Anda gunakan di URL seperti `/tags/personal`. `$table->timestamps()` menambahkan kolom `created_at` dan `updated_at` yang dikelola Eloquent secara otomatis.

### Step 3: Membuat Migration Pivot Table

Pivot table menghubungkan entri ke tag. Buat migration terpisah untuknya.

```bash
php artisan make:migration create_entry_tag_table
```

Buka file migration baru dan definisikan skema pivot table.

```php
public function up(): void
{
    Schema::create('entry_tag', function (Blueprint $table) {
        $table->id();
        $table->foreignId('entry_id')->constrained()->cascadeOnDelete();
        $table->foreignId('tag_id')->constrained()->cascadeOnDelete();
        $table->timestamps();
    });
}

public function down(): void
{
    Schema::dropIfExists('entry_tag');
}
```

Nama pivot table mengikuti konvensi Laravel: dua nama model dalam urutan alfabet, keduanya singular, dipisahkan oleh underscore. "Entry" datang sebelum "Tag" secara alfabet, jadi tabel diberi nama `entry_tag`. Mari kita periksa setiap kolom. `id()` memberi setiap baris pivot sebuah primary key (beberapa developer melewatkan ini pada pivot table, tetapi memilikinya membuat debugging lebih mudah). `foreignId('entry_id')->constrained()->cascadeOnDelete()` membuat kolom `entry_id` dengan foreign key yang menunjuk ke `entries.id`, dan `cascadeOnDelete()` memastikan bahwa menghapus sebuah entri secara otomatis menghapus semua baris pivot-nya. `foreignId('tag_id')->constrained()->cascadeOnDelete()` melakukan hal yang sama untuk sisi tag. `timestamps()` memungkinkan Anda melacak kapan setiap tag ditambahkan ke sebuah entri. Method `down()` menghapus seluruh pivot table jika Anda melakukan rollback.

### Step 4: Menjalankan Kedua Migration

Jalankan migration untuk membuat kedua tabel baru di database.

```bash
php artisan migrate
```

Anda akan melihat output yang mengonfirmasi bahwa tabel `tags` dan tabel `entry_tag` berhasil dibuat. Jika salah satu migration gagal, periksa bahwa tabel `entries` Anda sudah ada (dari course pemula) sehingga foreign key constraint dapat menunjuk ke sana.

> **Catatan tentang urutan migration.** Laravel menjalankan migration dalam urutan nama file, yang dimulai dengan timestamp. Jika Anda menghasilkan migration `tags` dan `entry_tag` dalam *detik yang sama* (sehingga timestamp keduanya identik), Laravel beralih ke urutan alfabet, dan `create_entry_tag_table` terurut *sebelum* `create_tags_table`. Migration pivot kemudian akan dijalankan lebih dulu dan gagal dengan foreign-key error seperti `Base table or view not found: ... 'tags'`, karena tabel `tags` yang ditunjuknya belum ada. Jika itu terjadi, ubah nama file migration pivot sehingga timestamp-nya lebih lambat daripada migration `tags` (misalnya, naikkan digit terakhir satu angka), atau hapus dan hasilkan ulang sesaat kemudian, lalu jalankan `php artisan migrate` lagi. Biasanya selisih beberapa detik antara dua perintah `make:` sudah cukup untuk menjaga timestamp tetap berbeda, jadi ini hanya menjadi masalah jika Anda menjalankan perintah secara berurutan dalam skrip.

---

## 3. Mendefinisikan Relationship

Kedua model membutuhkan `belongsToMany()` karena relationship-nya simetris. Sebuah entri dapat memiliki banyak tag, dan sebuah tag dapat dimiliki oleh banyak entri. Tidak seperti one-to-many, tidak ada "parent" atau "child" di sini, sehingga kedua sisi menggunakan tipe relationship yang sama.

### Step 1: Memperbarui Model Entry

Buka `app/Models/Entry.php` dan tambahkan method relationship `tags()` di dalam body class.

```php
<?php

// ... others lines of code

use Illuminate\Database\Eloquent\Relations\BelongsToMany;


#[Fillable(['title', 'content'])]
class Entry extends Model
{
    // ... other methods and properties

    public function tags(): BelongsToMany
    {
        return $this->belongsToMany(Tag::class)->withTimestamps();
    }
}
```

Memeriksa kode ini dengan cermat: statement `use` mengimpor `BelongsToMany` sehingga Anda dapat melakukan type-hint pada return. Method ini diberi nama `tags` karena itu menjadi nama property dan method yang akan Anda gunakan di tempat lain: `$entry->tags` (collection) atau `$entry->tags()` (query builder). Di dalamnya, `$this->belongsToMany(Tag::class)` memberi tahu Eloquent bahwa entri ini dapat memiliki banyak tag melalui sebuah pivot table. Laravel secara otomatis menemukan pivot table menggunakan konvensi penamaan (`entry_tag`), jadi Anda tidak perlu menentukannya. Pemanggilan berantai `withTimestamps()` memberi tahu Laravel bahwa pivot table memiliki kolom `created_at` dan `updated_at` dan untuk terus memperbaruinya; tanpa ini, kolom-kolom tersebut pada pivot table akan tetap NULL meskipun keduanya ada.

### Step 2: Mendefinisikan Model Tag

Buka `app/Models/Tag.php` dan ganti kontennya dengan berikut.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

#[Fillable(['name', 'slug'])]
class Tag extends Model
{
    public function entries(): BelongsToMany
    {
        return $this->belongsToMany(Entry::class)->withTimestamps();
    }
}
```

Model Tag mencerminkan relationship Entry karena many-to-many bersifat simetris. Attribute `#[Fillable(['name', 'slug'])]` mendaftar `name` dan `slug` sebagai field yang dapat di-mass assign sehingga Anda dapat membuat tag dengan `Tag::create(['name' => 'Personal', 'slug' => 'personal'])`. Method `entries()` mendefinisikan sisi inverse dari relationship sehingga Anda dapat memanggil `$tag->entries` untuk mendapatkan semua entri yang menggunakan tag ini. Kedua pemanggilan pada akhirnya melakukan query pada pivot table `entry_tag` yang sama tetapi dimulai dari arah yang berbeda.

---

## 4. Melakukan Seed Beberapa Tag

Sebelum membangun UI, mari kita buat beberapa tag untuk dikerjakan. Seeding berarti mengisi database dengan data awal, dan Anda dapat melakukannya secara interaktif melalui Tinker tanpa menulis class seeder penuh.

### Step 1: Membuat Tag di Tinker

Luncurkan Tinker dari terminal Anda.

```bash
php artisan tinker
```

Setelah berada di dalam Tinker, jalankan perintah berikut untuk menyisipkan lima tag ke dalam database.

```php
use App\Models\Tag;

Tag::create(['name' => 'Personal', 'slug' => 'personal']);

Tag::create(['name' => 'Travel', 'slug' => 'travel']);

Tag::create(['name' => 'Work', 'slug' => 'work']);

Tag::create(['name' => 'Ideas', 'slug' => 'ideas']);

Tag::create(['name' => 'Gratitude', 'slug' => 'gratitude']);
```

Setiap pemanggilan `Tag::create(...)` menyisipkan satu baris ke dalam tabel `tags`. Statement `use` di bagian atas memungkinkan Anda menulis `Tag::create` alih-alih path class lengkap. Ketik `exit` untuk keluar dari Tinker. Anda sekarang memiliki lima tag di database, yang cukup beragam untuk menguji fitur tagging.

---

## 5. Mengelola Tag pada Entri

Empat method kunci untuk mengelola relationship many-to-many adalah `attach`, `detach`, `sync`, dan `toggle`. Masing-masing memiliki tujuan yang berbeda, dan Anda akan paling sering menggunakan `sync` karena ia cocok sempurna dengan perilaku form: ia mengganti seluruh kumpulan asosiasi dalam satu pemanggilan.

### Step 1: Memperbarui Entry Controller

Buka `EntryController.php` Anda dan perbarui method `create`, `store`, `edit`, dan `update` untuk menangani tag.

Di method `create`, teruskan semua tag ke view sehingga form dapat merender checkbox untuk masing-masing.

```php
use App\Models\Tag;

public function create()
{
    $tags = Tag::orderBy('name')->get();

    return view('entries.create', compact('tags'));
}
```

Method ini mengambil semua tag secara alfabet sehingga checkbox form muncul dalam urutan yang dapat diprediksi. Klausa `orderBy('name')` mengurutkan berdasarkan kolom name secara ascending (default), dan `get()` mengeksekusi query. View menerima koleksi tag sebagai `$tags`.

Di method `store`, lakukan sync pada tag yang dipilih setelah membuat entri.

```php
public function store(Request $request)
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

    return redirect()->route('entries.index')->with('success', 'Entry created!');
}
```

Menguraikannya dengan cermat: aturan validasi `'tags' => 'nullable|array'` mengizinkan field tags berupa array berisi ID atau tidak ada sama sekali (user dapat membuat entri tanpa tag). Aturan `'tags.*' => 'exists:tags,id'` berlaku untuk setiap elemen array menggunakan wildcard `*`, dan `exists:tags,id` memverifikasi bahwa setiap ID yang dikirim benar-benar ada sebagai baris di tabel `tags`, mencegah data tidak valid atau pengiriman jahat. Setelah validasi, `$request->user()->entries()->create(...)` membuat entri baru yang dimiliki oleh user yang terautentikasi, secara otomatis menetapkan `user_id`. Baris yang krusial adalah `$entry->tags()->sync($validated['tags'] ?? [])`: method `sync()` mengganti semua asosiasi tag yang ada dengan yang dikirim. Jika user menghilangkan centang sebuah tag, `sync()` menghapusnya dari pivot table. Jika mereka mencentang tag baru, `sync()` menambahkannya. Operator null coalescing `?? []` menggunakan array kosong sebagai fallback ketika user sama sekali tidak mengirim tag.

Di method `edit`, teruskan entri dan semua tag sehingga form dapat melakukan pre-check pada pilihan yang sudah ada. Pertahankan pemeriksaan authorization dari course dasar.

```php
public function edit(Entry $entry)
{
    if ($entry->user_id !== auth()->id()) {
        abort(403);
    }

    $tags = Tag::orderBy('name')->get();

    return view('entries.edit', compact('entry', 'tags'));
}
```

Method edit mempertahankan authorization guard dari course dasar dan menambahkan variabel `$tags` sehingga form dapat merender checkbox.

Di method `update`, lakukan sync pada tag setelah memperbarui field entri. Pertahankan pemeriksaan authorization dan target redirect aslinya.

```php
public function update(Request $request, Entry $entry)
{
    if ($entry->user_id !== auth()->id()) {
        abort(403);
    }

    $validated = $request->validate([
        'title' => 'required|string|max:255',
        'content' => 'required|string',
        'tags' => 'nullable|array',
        'tags.*' => 'exists:tags,id',
    ]);

    $entry->update([
        'title' => $validated['title'],
        'content' => $validated['content'],
    ]);

    $entry->tags()->sync($validated['tags'] ?? []);

    return redirect()->route('entries.show', $entry)->with('success', 'Entry updated!');
}
```

Method update mengikuti pola yang sama seperti store: validasi, perbarui field entri, lalu sync tag. Menggunakan `sync()` untuk create maupun update berarti logika yang sama menangani kedua kasus dengan rapi. Jika user memulai dengan tag Personal dan Travel lalu mengirim form dengan Personal dan Work yang dicentang, `sync()` menghitung selisihnya dan hanya memperbarui apa yang berubah.

### Step 2: Menambahkan Checkbox Tag ke Form

Buka `resources/views/entries/create.blade.php` (atau view form entri Anda) dan tambahkan section pemilihan tag di bawah textarea content.

```blade
{{-- Tag selection --}}
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
```

Menelusuri view ini: `<div>` terluar membungkus seluruh section. `<label>` di bagian atas memberi label pada group. Loop `@foreach` melakukan iterasi pada koleksi tag yang Anda teruskan dari controller. Setiap iterasi merender sebuah `<label>` yang membungkus sebuah checkbox sehingga mengeklik nama tag mengaktifkan checkbox. Attribute yang krusial adalah `name="tags[]"`: `[]` memberi tahu PHP untuk mengumpulkan semua kotak yang dicentang ke dalam sebuah array di bawah key `tags` dalam pengiriman form. `value="{{ $tag->id }}"` menetapkan apa yang dikirim saat dicentang. Directive Blade `@checked(...)` menambahkan attribute `checked` secara kondisional ketika ekspresinya bernilai truthy; di sini ia memeriksa apakah `old('tags')` (nilai yang dikirim sebelumnya, digunakan untuk mengisi ulang setelah kegagalan validasi) adalah sebuah array dan berisi ID tag ini.

Untuk form edit (`entries/edit.blade.php`), directive `@checked` perlu memperhitungkan baik old input maupun tag yang sudah ada.

```blade
@checked(
    (is_array(old('tags')) && in_array($tag->id, old('tags')))
    || (!old('tags') && $entry->tags->contains($tag->id))
)
```

Kondisi yang lebih kompleks ini menangani dua skenario. Bagian pertama menangani kasus di mana user baru saja mengirim form dan validasi gagal, sehingga kita ingin memulihkan pilihan checkbox mereka dari old input. Bagian kedua menangani pemuatan halaman pertama ketika tidak ada old input, sehingga kita melakukan pre-check pada tag yang saat ini dimiliki entri. `||` menggabungkannya sehingga checkbox dicentang jika salah satu kondisi bernilai true.

---

## 6. Menampilkan Tag di View Entri

Tag seharusnya muncul sebagai badge berwarna pada setiap entri di feed dan di halaman detail sehingga user dapat melihat sekilas bagaimana setiap entri dikategorikan.

### Step 1: Memperbarui Method Index Controller

Buka `EntryController.php` dan perbarui method `index` untuk memuat tag bersama entri menggunakan eager loading.

```php
public function index()
{
    $entries = auth()->user()->entries()
        ->with('tags')
        ->withCount('comments')
        ->latest()
        ->get();

    return view('entries.index', compact('entries'));
}
```

Tambahan kunci di sini adalah `->with('tags')`, yang melakukan eager load semua tag untuk setiap entri dalam satu query. Tanpanya, menampilkan tag dalam sebuah loop akan memicu query baru untuk setiap entri (masalah N+1 yang dibahas Lesson 4 secara mendetail). `withCount('comments')` menambahkan attribute `comments_count` secara hemat melalui sebuah subquery. `latest()` mengurutkan berdasarkan `created_at` secara descending sehingga entri terbaru muncul lebih dulu. `get()` mengeksekusi query lengkap dan mengembalikan sebuah Collection.

### Step 2: Menampilkan Tag di View

Buka `resources/views/components/entry-card.blade.php` dan tambahkan blok berikut di bawah section snippet konten dan di atas section tombol aksi.

```blade
{{-- Tags --}}
@if($entry->tags->isNotEmpty())
    <div style="margin-top: 8px; display: flex; flex-wrap: wrap; gap: 4px;">
        @foreach ($entry->tags as $tag)
            <span style="background: #dbeafe; color: #1e40af; padding: 2px 10px; border-radius: 12px; font-size: 0.75em; font-weight: 600;">
                {{ $tag->name }}
            </span>
        @endforeach
    </div>
@endif
```

Melihat ini dengan cermat: pemeriksaan `@if($entry->tags->isNotEmpty())` mencegah merender kontainer kosong ketika sebuah entri tidak memiliki tag, karena `isNotEmpty()` mengembalikan false pada koleksi kosong. `@foreach` mengulang koleksi tag yang sudah di-eager-load. Setiap tag menjadi sebuah `<span>` yang diberi style agar terlihat seperti badge pil: background biru muda, teks biru lebih gelap, sudut membulat, padding kecil, dan font weight semibold.

---

## 7. Menjelajahi Entri berdasarkan Tag

Tag paling berguna ketika pembaca dapat mengeklik salah satunya dan melihat setiap entri yang membawanya. Di section ini Anda akan menambahkan `TagController` khusus dengan dua halaman, yaitu daftar semua tag, dan halaman entri untuk satu tag, yang dihubungkan dengan named route. Ini mengerahkan arah *lain* dari relationship many-to-many (`$tag->entries`).

### Step 1: Membuat Tag Controller

```bash
php artisan make:controller TagController
```

Buka `app/Http/Controllers/TagController.php` dan tambahkan method `index` dan `show`.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Tag;

class TagController extends Controller
{
    public function index()
    {
        $tags = Tag::withCount('entries')->orderBy('name')->get();

        return view('tags.index', compact('tags'));
    }

    public function show(Tag $tag)
    {
        $entries = $tag->entries()->with('user')->latest()->paginate(10);

        return view('tags.show', compact('tag', 'entries'));
    }
}
```

Method `index` menggunakan `withCount('entries')` untuk menyematkan attribute `entries_count` ke setiap tag dengan satu subquery yang efisien, lalu mengurutkan tag secara alfabet. Method `show` menerima sebuah `Tag` melalui route model binding dan melakukan query pada relationship inverse `$tag->entries()` (sebagai query builder, dengan tanda kurung) sehingga ia dapat merantai `with('user')` untuk menghindari N+1 pada penulis, `latest()` untuk menampilkan yang terbaru lebih dulu, dan `paginate(10)` untuk halaman yang dapat dinavigasi.

### Step 2: Mendaftarkan Route Tag

Buka `routes/web.php` dan tambahkan dua route tag di dalam group middleware `auth`, bersama route entri.

```php
use App\Http\Controllers\TagController;

Route::middleware('auth')->group(function () {
    // ... entry and comment routes above ...
    Route::get('/tags', [TagController::class, 'index'])->name('tags.index');
    Route::get('/tags/{tag:slug}', [TagController::class, 'show'])->name('tags.show');
});
```

Sintaks `{tag:slug}` memberi tahu Laravel untuk meresolusi `Tag` berdasarkan kolom `slug`-nya alih-alih `id`-nya, memberi Anda URL yang ramah seperti `/tags/travel` alih-alih `/tags/3`. Ini berfungsi karena kolom `slug` bersifat unik, yang Anda jamin di migration.

### Step 3: Membuat View Tag

Buat `resources/views/tags/index.blade.php` untuk menampilkan setiap tag beserta jumlah entrinya.

```blade
<x-layout title="Tags — Catatku">

    <div class="flex items-center justify-between mb-6">
        <h2 class="text-lg font-semibold text-gray-900">Tags</h2>
        <a href="{{ route('entries.index') }}" class="text-sm text-blue-600 hover:underline">
            ← Back to Entries
        </a>
    </div>

    <div class="space-y-2">
        @forelse ($tags as $tag)
            <div class="bg-white rounded-xl border border-gray-200 p-4 flex items-center justify-between">
                <a href="{{ route('tags.show', $tag) }}" class="font-bold text-blue-700 hover:underline">
                    {{ $tag->name }}
                </a>
                <span style="color: #888;">({{ $tag->entries_count }} entries)</span>
            </div>
        @empty
            <p class="text-gray-400">No tags yet.</p>
        @endforelse
    </div>

</x-layout>
```

Lalu buat `resources/views/tags/show.blade.php` untuk menampilkan entri untuk satu tag.

```blade
<x-layout :title="$tag->name . ' — Catatku'">

    <div class="flex items-center justify-between mb-6">
        <h2 class="text-lg font-semibold text-gray-900">Tag: {{ $tag->name }}</h2>
        <a href="{{ route('tags.index') }}" class="text-sm text-blue-600 hover:underline">
            ← All Tags
        </a>
    </div>

    <div class="space-y-4">
        @forelse ($entries as $entry)
            <div class="bg-white rounded-xl border border-gray-200 p-5">
                <a href="{{ route('entries.show', $entry) }}" class="font-semibold text-gray-900 hover:text-gray-600">
                    {{ $entry->title }}
                </a>
                <p class="text-xs text-gray-400 mt-1">by {{ $entry->user->name }}</p>
            </div>
        @empty
            <p class="text-gray-400">No entries with this tag.</p>
        @endforelse
    </div>

    <div style="margin-top: 20px;">
        {{ $entries->links() }}
    </div>

</x-layout>
```

View index mengulang tag dan membaca attribute `entries_count` yang disuntikkan `withCount`. View show mengulang entri yang dipaginasi dan merender `{{ $entries->links() }}` di bagian bawah, yang berfungsi karena `show()` mengembalikan `paginate(10)` alih-alih `get()`. Meneruskan `$tag` ke `route('tags.show', $tag)` mengisi segmen `{tag:slug}` dengan slug tag secara otomatis karena binding `:slug` yang Anda deklarasikan. Kunjungi `/tags` di browser untuk melihat daftar tag, lalu klik tag mana pun untuk melihat entrinya.

---

## 8. Menjalankan dan Menguji

Mari kita verifikasi sistem tagging lengkap berfungsi dari awal hingga akhir.

### Step 1: Menjalankan Server

Jalankan development server dengan perintah berikut dan biarkan tetap berjalan selama pengujian Anda.

```bash
php artisan serve
```

Biarkan terminal ini terbuka; server berjalan selama perintah ini aktif.

### Step 2: Membuat Entri dengan Tag

Buka `http://localhost:8000` di browser dan login. Navigasikan ke halaman pembuatan entri. Anda akan melihat checkbox tag tersusun secara horizontal di bawah textarea content. Tulis sebuah entri jurnal dengan judul seperti "Weekend in Bandung" dan beberapa konten, lalu centang "Personal" dan "Travel". Klik submit. Anda akan diarahkan ke feed entri dengan pesan sukses, dan entri akan muncul dengan dua badge tag biru di sampingnya.

### Step 3: Mengedit Tag

Klik tombol edit pada entri yang baru saja Anda buat. Perhatikan bahwa checkbox "Personal" dan "Travel" sudah dicentang sebelumnya karena logika directive `@checked`. Hilangkan centang "Travel" dan centang "Work" sebagai gantinya. Simpan. Entri sekarang seharusnya menampilkan badge "Personal" dan "Work" tetapi tidak ada badge "Travel". Ini membuktikan bahwa `sync()` dengan benar menambahkan tag baru dan menghapus yang lama.

### Step 4: Membuat Entri Tanpa Tag

Coba buat entri baru tanpa memilih tag apa pun. Setelah menyimpan, entri seharusnya muncul di feed tanpa badge tag apa pun, mengonfirmasi bahwa pemeriksaan `@if($entry->tags->isNotEmpty())` berfungsi.

### Step 5: Memverifikasi di Tinker

Buka terminal baru dan luncurkan Tinker untuk memeriksa relationship dari command line.

```bash
php artisan tinker
```

Jalankan perintah berikut satu per satu untuk memverifikasi relationship berfungsi dari kedua arah.

```php
$entry = \App\Models\Entry::with('tags')->first();
$entry->tags->pluck('name');

$tag = \App\Models\Tag::where('slug', 'personal')->first();
$tag->entries->count();
```

Blok pertama mengambil entri pertama dengan tag-nya yang sudah di-eager-load, lalu menggunakan `pluck('name')` untuk mengekstrak hanya nama tag ke dalam array sederhana agar mudah dibaca. Blok kedua mencari tag Personal berdasarkan slug, lalu menghitung semua entri yang terkait dengannya, membuktikan relationship berfungsi dari sisi tag juga. Ketik `exit` untuk keluar dari Tinker.

---

## 9. Memperbaiki Error pada Kode Anda

Berikut adalah kesalahan paling umum saat bekerja dengan relationship many-to-many. Memahaminya sekarang akan menyelamatkan Anda dari error database yang membingungkan nanti.

**Error 1: Nama pivot table yang salah.**

Error ini terjadi ketika Anda membuat pivot table dengan nama yang tidak mengikuti konvensi alfabet dan singular Laravel. Ketika nama tabel tidak cocok dengan yang diharapkan Eloquent, setiap query melalui relationship akan gagal dengan error "table not found".

```php
// Wrong: table named in wrong order
Schema::create('tags_entries', function (Blueprint $table) {
    $table->id();
    $table->foreignId('entry_id')->constrained()->cascadeOnDelete();
    $table->foreignId('tag_id')->constrained()->cascadeOnDelete();
    $table->timestamps();
});

// Correct: alphabetical order, singular model names
Schema::create('entry_tag', function (Blueprint $table) {
    $table->id();
    $table->foreignId('entry_id')->constrained()->cascadeOnDelete();
    $table->foreignId('tag_id')->constrained()->cascadeOnDelete();
    $table->timestamps();
});
```

Versi yang salah memberi nama tabel `tags_entries`, yang membalik urutan alfabet dan menggunakan nama plural. Eloquent tidak dapat menemukan pivot table secara otomatis dan relationship gagal. Versi yang benar menggunakan `entry_tag` karena "Entry" datang sebelum "Tag" secara alfabet. Jika Anda harus menggunakan nama kustom, Anda dapat menentukannya sebagai argumen kedua pada `belongsToMany`: `$this->belongsToMany(Tag::class, 'my_custom_table')`.

---

**Error 2: Membuat pivot entry duplikat dengan `attach()`.**

Error ini terjadi ketika Anda memanggil `attach()` dalam sebuah loop atau memanggilnya dua kali untuk ID yang sama, membuat baris duplikat di pivot table. Jika Anda memiliki unique constraint pada kolom pivot, ini menghasilkan pelanggaran SQL integrity constraint.

```php
// Wrong: attach called twice for the same tag
$entry->tags()->attach(1);
$entry->tags()->attach(1);

// Correct: use sync() to replace all associations at once
$entry->tags()->sync([1, 2, 3]);
```

Versi yang salah memanggil `attach(1)` dua kali, menyisipkan baris pivot duplikat, yang merusak keunikan jika diberlakukan dan merusak data jika tidak. Versi yang benar menggunakan `sync()`, yang menangani perbandingan secara internal: ia menambahkan ID yang belum ada dan menghapus ID yang telah dihapus. Jika Anda ingin menambahkan sebuah tag tanpa memengaruhi yang lain dan tanpa risiko duplikat, gunakan `syncWithoutDetaching([1])` sebagai gantinya.

---

**Error 3: Timestamp NULL pada pivot table.**

Error ini terjadi ketika pivot table Anda memiliki kolom `created_at` dan `updated_at` tetapi Anda lupa menambahkan `withTimestamps()` ke definisi relationship. Laravel tidak tahu untuk mengisi kolom-kolom tersebut, sehingga keduanya tetap NULL pada setiap baris.

```php
// Wrong: withTimestamps() is missing
public function tags(): BelongsToMany
{
    return $this->belongsToMany(Tag::class);
}

// Correct: withTimestamps() tells Laravel to manage the pivot timestamps
public function tags(): BelongsToMany
{
    return $this->belongsToMany(Tag::class)->withTimestamps();
}
```

Tanpa `withTimestamps()`, setiap insert melalui `attach()` atau `sync()` meninggalkan `created_at` dan `updated_at` sebagai NULL meskipun kolomnya ada. Menambahkan `withTimestamps()` membuat Laravel mengisinya secara otomatis. Tambahkan ke kedua sisi relationship demi konsistensi.

---

## 10. Latihan

**Latihan 1:** Ubah daftar tag (yang dibangun di lesson utama) menjadi "tag cloud" yang diurutkan berdasarkan popularitas. Ubah `TagController@index` untuk mengurutkan tag berdasarkan jumlah entrinya secara descending, dan di view skalakan ukuran font setiap tag berdasarkan berapa banyak entri yang dimilikinya, sehingga tag populer tampil lebih besar.

**Latihan 2:** Tambahkan pemfilteran tag ke feed entri. Terima parameter query-string `tag` seperti `/entries?tag=travel`, dan di `EntryController@index` gunakan `whereHas('tags', ...)` untuk menampilkan hanya entri yang membawa tag dengan slug tersebut ketika parameter ada.

**Latihan 3:** Tambahkan kemampuan untuk membuat tag baru secara inline. Tambahkan input teks di form entri tempat user dapat mengetik nama tag baru. Di controller, gunakan `Tag::firstOrCreate(['name' => $name, 'slug' => Str::slug($name)])` sebelum melakukan sync.

---

## 11. Solusi

**Solusi untuk Latihan 1:**

Di `TagController@index`, urutkan tag berdasarkan jumlah entrinya alih-alih berdasarkan nama.

```php
public function index()
{
    $tags = Tag::withCount('entries')->orderByDesc('entries_count')->get();

    return view('tags.index', compact('tags'));
}
```

`withCount('entries')` tetap menyematkan attribute `entries_count`, tetapi `orderByDesc('entries_count')` sekarang mengurutkan berdasarkan agregat tersebut sehingga tag yang paling banyak digunakan datang lebih dulu. Di `resources/views/tags/index.blade.php`, skalakan ukuran font berdasarkan jumlah untuk mendapatkan tampilan tag-cloud klasik.

```blade
@foreach ($tags as $tag)
    <a href="{{ route('tags.show', $tag) }}"
       style="font-size: {{ 0.8 + min($tag->entries_count, 10) * 0.15 }}em; margin-right: 10px;"
       class="text-blue-700 hover:underline">
        {{ $tag->name }}
    </a>
@endforeach
```

`font-size` inline tumbuh seiring `entries_count` (dibatasi melalui `min(..., 10)` sehingga satu tag yang sangat populer tidak mendominasi layout), mengubah daftar datar menjadi cloud yang berbobot.

---

**Solusi untuk Latihan 2:**

Di `EntryController@index`, terapkan filter `whereHas` ketika parameter query `tag` ada. Karena method index sudah membangun query sebelum memanggil `get()`/`paginate()`, Anda hanya perlu menyisipkan filter kondisional.

```php
public function index(Request $request)
{
    $query = auth()->user()->entries()->with('tags')->withCount('comments');

    if ($request->filled('tag')) {
        $query->whereHas('tags', function ($q) use ($request) {
            $q->where('slug', $request->input('tag'));
        });
    }

    $entries = $query->latest()->paginate(15);

    return view('entries.index', compact('entries'));
}
```

`$request->filled('tag')` bernilai true hanya ketika `?tag=` ada dan tidak kosong. `whereHas('tags', ...)` menambahkan subquery `EXISTS` yang hanya mempertahankan entri yang tertaut ke sebuah tag yang `slug`-nya cocok, menjalankan filter di database alih-alih di PHP. Sekarang `/entries?tag=travel` hanya menampilkan entri yang ber-tag travel; tanpa parameter, feed lengkap dikembalikan tanpa perubahan. Anda dapat mengubah badge tag pada setiap card menjadi link (`route('tags.show', $tag)` atau `/entries?tag={{ $tag->slug }}`) agar user dapat memicu filter ini dengan mengeklik.

---

**Solusi untuk Latihan 3:**

Di form entri, tambahkan input teks di bawah checkbox tempat user dapat mengetik nama tag baru.

```blade
<div style="margin-top: 10px;">
    <label style="display: block; font-size: 0.85em; color: #555; margin-bottom: 4px;">
        Or add a new tag:
    </label>
    <input
        type="text"
        name="new_tag"
        placeholder="e.g. Fitness"
        style="padding: 6px 10px; border: 1px solid #d1d5db; border-radius: 6px; width: 200px;"
    >
</div>
```

Di method `store` dan `update` dari `EntryController`, tambahkan blok berikut sebelum memanggil `sync()`.

```php
use Illuminate\Support\Str;

$tagIds = $validated['tags'] ?? [];

if ($request->filled('new_tag')) {
    $newTag = Tag::firstOrCreate(
        ['slug' => Str::slug($request->input('new_tag'))],
        ['name' => trim($request->input('new_tag'))]
    );
    $tagIds[] = $newTag->id;
}

$entry->tags()->sync($tagIds);
```

`Tag::firstOrCreate()` menerima dua array: yang pertama adalah kondisi pencarian (cari berdasarkan slug), dan yang kedua adalah data tambahan yang hanya digunakan saat membuat record baru. `Str::slug()` mengonversi nama yang diketik menjadi slug yang aman untuk URL (misalnya, "My Ideas" menjadi "my-ideas"). Jika sebuah tag dengan slug tersebut sudah ada, `firstOrCreate()` mengembalikan record yang ada alih-alih menyisipkan duplikat. ID tag baru kemudian ditambahkan ke array `$tagIds` sebelum `sync()` dijalankan, sehingga tag yang dibuat secara inline disertakan dalam asosiasi akhir.

---

## Selanjutnya - Lesson 3

Di lesson ini Anda membangun sistem tagging many-to-many yang lengkap. Anda membuat tabel `tags` dan pivot table `entry_tag` mengikuti konvensi penamaan alfabet dan singular Laravel. Anda mendefinisikan `belongsToMany()` pada kedua model Entry dan Tag, menggunakan `sync()` untuk mengganti asosiasi tag ketika sebuah form dikirim, dan memvalidasi ID tag yang dikirim dengan aturan `exists:tags,id`. Anda menambahkan `TagController` dengan route berbasis slug sehingga pembaca dapat menjelajahi semua tag dan masuk ke entri di bawah salah satunya, mengerahkan sisi inverse `$tag->entries` dari relationship. Anda juga mempelajari perbedaan antara `attach`, `detach`, `sync`, dan `toggle`, dan kapan menggunakan masing-masing.

Di Lesson 3, Anda akan mempelajari scope, accessor, dan mutator: bagaimana mendefinisikan filter query yang dapat digunakan kembali langsung pada model Entry, bagaimana mengubah data saat dibaca dengan accessor, dan bagaimana membersihkan input secara otomatis saat menulis dengan mutator.
