## 1. Sebelum Anda Memulai

Setiap aplikasi mengulang query tertentu: "ambil hanya entri terbaru", "ambil entri berdasarkan user saat ini", "cari entri berdasarkan kata kunci". Menulis `where('created_at', '>=', now()->subDays(7))` setiap kali itu melelahkan dan rawan kesalahan. Scope Eloquent memungkinkan Anda mendefinisikan filter query yang dapat digunakan kembali pada model itu sendiri. Demikian pula, Anda sering perlu mengubah data: menampilkan tanggal yang sudah diformat saat membaca, atau membuat huruf kapital otomatis pada judul saat menulis. Accessor mengubah data saat dibaca, dan mutator mengubah data saat ditulis.

Lesson ini membahas local scope untuk filter query yang dapat digunakan kembali, accessor untuk memformat output, dan mutator untuk membersihkan input. Ketiganya diterapkan pada model Entry di Catatku, menjaga logika transformasi tetap di dalam model dan keluar dari controller serta view. Dengan memusatkan pola-pola ini, kode Anda tetap konsisten baik data mengalir melalui controller, Tinker, seeder, maupun test.

### What You'll Build

Anda akan menambahkan scope untuk query umum (entri terbaru, search, entri dengan komentar), accessor excerpt untuk menampilkan pratinjau konten, accessor reading time, dan mutator title yang membuat huruf kapital otomatis.

### What You'll Learn

- ✅ Local scope: `scopeRecent`, `scopeSearch`, `scopeByUser`
- ✅ Menggunakan scope: `Entry::recent()->get()`
- ✅ Accessor: `Attribute::get()` (sintaks Laravel 11+)
- ✅ Mutator: `Attribute::set()`
- ✅ Menggabungkan scope untuk query kompleks

### What You'll Need

- Lesson 2 sudah selesai dengan tag yang berfungsi

---

## 2. Local Scope

Sebuah local scope adalah method pada model yang diberi prefix `scope`. Ia menerima sebuah query builder dan menambahkan constraint. Ketika Anda memanggil scope, Anda menghilangkan prefix `scope`: `scopeRecent` menjadi `Entry::recent()`. Konvensi penamaan inilah cara Eloquent mengenali method mana yang merupakan scope versus method model biasa.

### Step 1: Menambahkan Scope ke Model Entry

Buka `app/Models/Entry.php` dan tambahkan keempat method scope di bawah ini ke class `Entry`. Tambahkan import `Builder` bersama statement `use` yang sudah ada di bagian atas file.

```php
<?php
// ... others lines of code
use Illuminate\Database\Eloquent\Builder;

#[Fillable(['title', 'content'])]
class Entry extends Model
{
    // ... other methods and properties

    public function scopeRecent(Builder $query): Builder
    {
        return $query->where('created_at', '>=', now()->subDays(7));
    }

    public function scopeByUser(Builder $query, int $userId): Builder
    {
        return $query->where('user_id', $userId);
    }

    public function scopeHasComments(Builder $query): Builder
    {
        return $query->has('comments');
    }

    public function scopeSearch(Builder $query, string $keyword): Builder
    {
        return $query->where(function (Builder $q) use ($keyword) {
            $q->where('title', 'like', "%{$keyword}%")
              ->orWhere('content', 'like', "%{$keyword}%");
        });
    }
}
```

Mari kita periksa setiap scope secara detail agar Anda memahami bagaimana mereka disusun. Setiap method scope mengikuti pola yang sama: namanya dimulai dengan `scope`, ia menerima sebuah `Builder $query` sebagai parameter pertama (yang disuntikkan Laravel secara otomatis ketika Anda memanggil scope), ia menambahkan kondisi query, dan ia mengembalikan builder yang sudah dimodifikasi.

`scopeRecent` menambahkan klausa `where` yang memfilter `created_at` ke 7 hari terakhir menggunakan helper Carbon `now()->subDays(7)`. `scopeByUser` mengambil parameter tambahan `int $userId`; argumen yang Anda teruskan saat memanggil scope dipetakan ke parameter tambahan ini setelah `$query` yang disuntikkan. `scopeHasComments` menggunakan method `has()` dari Eloquent, yang menambahkan subquery `WHERE EXISTS` untuk memeriksa bahwa setidaknya satu komentar terkait ada.

`scopeSearch` adalah yang paling kompleks. Ia membungkus kondisinya di dalam `where(function (Builder $q) use ($keyword) { ... })` sehingga kondisi `OR` antara title dan content dikelompokkan dengan benar di dalam tanda kurung. Tanpa pengelompokan ini, merantai `->recent()->search('hello')` dapat menghasilkan SQL seperti `WHERE created_at >= ? AND title LIKE ? OR content LIKE ?`, yang secara semantik salah karena `OR` memiliki presedensi lebih rendah daripada `AND`. Versi yang dibungkus closure menghasilkan `WHERE created_at >= ? AND (title LIKE ? OR content LIKE ?)`, yang dengan benar mengelompokkan kondisi pencarian.

### Step 2: Menggunakan Scope di Controller

Buka `app/Http/Controllers/EntryController.php` dan perbarui method `index` di class `EntryController` untuk menerapkan scope search secara kondisional berdasarkan request yang masuk.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function index(Request $request)
    {
        $query = auth()->user()->entries()->with('tags')->withCount('comments');

        if ($request->filled('search')) {
            $query->search($request->input('search'));
        }

        $entries = $query->latest()->get();

        return view('entries.index', compact('entries'));
    }

    // ... other methods
}
```

Membaca kode ini: baris pertama memulai sebuah query builder untuk entri milik user yang terautentikasi, melakukan eager load tag, dan menambahkan subquery untuk jumlah komentar. Karena kita belum memanggil `get()`, ini tetap menjadi query builder yang dapat kita modifikasi lebih lanjut. Pemeriksaan `if ($request->filled('search'))` mengembalikan true hanya ketika input `search` ada dan tidak kosong, sehingga mengirim `?search=` tanpa mengetik apa pun tidak memicu pemfilteran. Ketika tidak kosong, `$query->search(...)` memanggil method `scopeSearch` yang Anda definisikan, menambahkan kondisi LIKE title/content ke builder yang ada. Akhirnya, `latest()->get()` mengurutkan berdasarkan `created_at` secara descending dan mengeksekusi query lengkap. Scope berkomposisi secara natural dengan method query lain mana pun karena semuanya memodifikasi builder yang mendasari yang sama.

---

## 3. Accessor

Accessor mengubah data ketika Anda membaca sebuah property model. Mereka tidak mengubah apa yang disimpan di database; mereka mengubah apa yang Anda lihat saat mengakses property. Anggap mereka sebagai computed property, serupa dengan getter method di OOP tradisional tetapi dengan sintaks yang lebih bersih menyerupai property. Laravel 11+ menggunakan class `Attribute` untuk mendefinisikan accessor dan mutator, yang merupakan API yang lebih baru dan lebih ekspresif daripada gaya method `getXxxAttribute` yang lama.

### Step 1: Menambahkan Accessor ke Model Entry

Buka `app/Models/Entry.php` dan tambahkan ketiga method accessor di bawah ini ke class `Entry`. Tambahkan import `Attribute` bersama statement `use` yang sudah ada di bagian atas file.

```php
<?php
// ... others lines of code
use Illuminate\Database\Eloquent\Casts\Attribute;

#[Fillable(['title', 'content'])]
class Entry extends Model
{
    // ... other methods and properties

    protected function excerpt(): Attribute
    {
        return Attribute::get(fn () => str($this->content)->limit(100)->toString());
    }

    protected function readingTime(): Attribute
    {
        return Attribute::get(fn () => max(1, (int) ceil(str_word_count($this->content) / 200)));
    }

    protected function createdAtHuman(): Attribute
    {
        return Attribute::get(fn () => $this->created_at?->diffForHumans());
    }
}
```

Menelusuri setiap accessor dengan cermat: statement `use` mengimpor class `Attribute`. Setiap method bersifat `protected` (accessor tidak perlu public karena Anda tidak memanggilnya secara langsung) dan mengembalikan sebuah instance `Attribute`. Factory `Attribute::get(...)` menerima sebuah closure yang menghitung nilai setiap kali Anda membaca property.

Accessor `excerpt` membungkus content dalam fluent string helper Laravel menggunakan `str($this->content)`, memanggil `limit(100)` untuk memotong menjadi 100 karakter dan menambahkan ellipsis default, dan mengonversi hasilnya kembali menjadi string biasa dengan `toString()`. Accessor `readingTime` memperkirakan durasi membaca: `str_word_count($this->content)` menghitung kata menggunakan fungsi bawaan PHP, membaginya dengan 200 (kecepatan membaca rata-rata dalam kata per menit), membulatkan ke atas dengan `ceil()` sehingga 0,3 menjadi 1, melakukan cast ke integer untuk output yang bersih, dan membungkusnya dalam `max(1, ...)` untuk menjamin setidaknya satu menit bahkan untuk entri yang sangat pendek. Accessor `createdAtHuman` menggunakan `diffForHumans()` dari Carbon untuk menghasilkan string seperti "3 hours ago", dengan operator null-safe `?->` yang mencegah error jika `created_at` entah bagaimana bernilai null.

Nama method menggunakan camelCase, tetapi Laravel secara otomatis mengonversinya menjadi snake_case ketika Anda mengaksesnya sebagai property: `$entry->excerpt`, `$entry->reading_time`, `$entry->created_at_human`.

### Step 2: Menggunakan Accessor di View

Buka `resources/views/components/entry-card.blade.php`. Di section snippet konten, ganti blok `<p>` yang ada dengan dua elemen berikut; yang pertama menggunakan `$entry->excerpt` alih-alih content mentah, dan yang kedua menambahkan reading time dan tanggal relatif di bawahnya.

```blade
{{-- Content snippet --}}
<p class="text-sm text-gray-500 line-clamp-2 mb-2">
    {{ $entry->excerpt }}
</p>
<span style="color: #9ca3af; font-size: 0.8em;">
    {{ $entry->reading_time }} min read · {{ $entry->created_at_human }}
</span>
```

Perhatikan bagaimana accessor diakses seperti property biasa tanpa sintaks pemanggilan fungsi. `{{ $entry->excerpt }}` memicu closure excerpt di balik layar dan menghasilkan string yang dikomputasi. Demikian pula, `{{ $entry->reading_time }}` mengeksekusi perhitungan. Laravel secara otomatis mengonversi nama method camelCase (`readingTime`) menjadi snake_case (`reading_time`) saat mencocokkan akses property, itulah sebabnya Anda harus menggunakan snake_case di template meskipun method Anda menggunakan camelCase.

Setelah perubahan, file `entry-card.blade.php` lengkap terlihat seperti ini:

```
@props(['entry'])

<div class="bg-white rounded-xl border border-gray-200 p-5 hover:border-gray-300 transition-colors">

    {{-- Header: title and date --}}
    <div class="flex items-start justify-between gap-3 mb-3">
        <a href="/entries/{{ $entry->id }}" class="font-semibold text-gray-900 hover:text-gray-600 leading-snug">
            {{ $entry->title }}
        </a>
        <span class="text-xs text-gray-400 whitespace-nowrap mt-0.5">
            {{ $entry->created_at->format('d M Y') }}
        </span>
    </div>

    {{-- Content snippet --}}
    <p class="text-sm text-gray-500 line-clamp-2 mb-2">
        {{ $entry->excerpt }}
    </p>
    <span style="color: #9ca3af; font-size: 0.8em;">
        {{ $entry->reading_time }} min read · {{ $entry->created_at_human }}
    </span>

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

    {{-- Action buttons --}}
    <div class="flex items-center gap-3 pt-3 border-t border-gray-100">
        <a href="/entries/{{ $entry->id }}" class="text-xs text-blue-600 hover:text-blue-800">
            Read
        </a>
        <a href="/entries/{{ $entry->id }}/edit" class="text-xs text-gray-500 hover:text-gray-800">
            Edit
        </a>
        <form method="POST" action="/entries/{{ $entry->id }}" onsubmit="return confirm('Delete this entry?')"
            class="ml-auto">
            @csrf
            @method('DELETE')
            <button type="submit" class="text-xs text-red-400 hover:text-red-600">
                Delete
            </button>
        </form>
    </div>

</div>
```

---

## 4. Mutator

Mutator mengubah data sebelum disimpan ke database. Mereka adalah kebalikan dari accessor: mereka mengubah apa yang disimpan, bukan apa yang ditampilkan. Ini adalah tempat yang tepat untuk pembersihan dan normalisasi data karena ia berjalan otomatis tidak peduli dari mana data berasal, baik itu dari controller, seeder, queue job, maupun Tinker.

### Step 1: Menambahkan Mutator Title

Buka `app/Models/Entry.php` dan tambahkan method berikut ke class `Entry`.

```php
<?php
// ... others lines of code

#[Fillable(['title', 'content'])]
class Entry extends Model
{
    // ... other methods and properties

    protected function title(): Attribute
    {
        return Attribute::make(
            get: fn (string $value) => $value,
            set: fn (string $value) => ucfirst(trim($value)),
        );
    }
}
```

Mutator ini menggunakan `Attribute::make()` alih-alih pemanggilan `get()` atau `set()` yang terpisah karena kita ingin mendefinisikan perilaku baca dan tulis dalam satu method. Callback `get` menerima nilai mentah dari database dan mengembalikan apa yang Anda lihat saat membaca `$entry->title`; di sini kita mengembalikannya tanpa perubahan karena kita tidak ingin mengubah tampilannya. Callback `set` menerima apa yang user coba simpan dan mengembalikan versi yang sudah dinormalisasi. Di dalamnya, `trim($value)` menghapus whitespace dari kedua ujung, dan `ucfirst()` membuat huruf pertama dari hasil menjadi kapital. Jadi ketika user mengetik "  my vacation diary  ", database menyimpan "My vacation diary". Saat menggunakan `Attribute::make()`, baik key `get` maupun `set` wajib ada; jika Anda hanya membutuhkan satu arah, gunakan `Attribute::get()` atau `Attribute::set()` secara terpisah.

---

## 5. Menjalankan dan Menguji

Mari kita verifikasi bahwa scope, accessor, dan mutator semuanya berfungsi dengan benar dengan menjalankan masing-masing secara berurutan.

### Step 1: Menguji Scope di Tinker

Buka terminal dan luncurkan Tinker.

```bash
php artisan tinker
```

Setelah berada di dalam Tinker, jalankan perintah berikut satu per satu untuk memverifikasi setiap scope.

```php
use App\Models\Entry;

Entry::recent()->count();

Entry::search('vacation')->get()->pluck('title');

Entry::recent()->hasComments()->count();
```

Baris pertama menghitung entri dari tujuh hari terakhir menggunakan `scopeRecent`. Baris kedua mencari entri yang title atau content-nya mengandung "vacation" menggunakan `scopeSearch`, lalu `pluck('title')` mengekstrak hanya kolom title ke dalam array sederhana agar mudah dilihat. Baris ketiga merantai dua scope bersama untuk menemukan entri yang sekaligus terbaru dan memiliki setidaknya satu komentar, membuktikan bahwa scope berkomposisi secara natural. Ketik `exit` untuk keluar dari Tinker.

### Step 2: Menguji Accessor di Tinker

Luncurkan Tinker lagi dan akses computed property baru pada entri yang sudah ada.

```bash
php artisan tinker
```

Jalankan perintah berikut untuk memverifikasi setiap accessor mengembalikan output yang diharapkan.

```php
$entry = \App\Models\Entry::first();

$entry->excerpt;

$entry->reading_time;

$entry->created_at_human;
```

Setiap akses property memicu closure accessor yang sesuai. `$entry->excerpt` mengembalikan snippet content yang dipotong dengan ellipsis. `$entry->reading_time` mengembalikan integer yang merepresentasikan perkiraan menit untuk membaca entri. `$entry->created_at_human` mengembalikan string relatif seperti "2 days ago". Perhatikan bahwa Anda membacanya sebagai property, bukan dengan memanggil method, yang merupakan keunggulan utama dari API Attribute. Ketik `exit` untuk keluar dari Tinker.

### Step 3: Menguji Mutator

Masih di Tinker (atau sesi baru), uji bahwa mutator title menormalisasi input sebelum menyimpan.

```php
$entry = \App\Models\Entry::first();
$entry->title = "  hello world  ";
$entry->save();
$entry->fresh()->title;
```

Penugasan `$entry->title = "  hello world  "` memicu callback `set` dari mutator title, yang memangkas whitespace dan membuat huruf pertama menjadi kapital. Memanggil `save()` mempersistenkan nilai yang sudah ditransformasi ke database. `fresh()` memuat ulang model dari database untuk membuktikan bahwa nilai yang tersimpan benar-benar "Hello world" dan bukan sekadar transformasi in-memory yang akan hilang pada request berikutnya.

### Step 4: Menguji Search di Browser

Jalankan development server dan uji scope search melalui UI.

```bash
php artisan serve
```

Login, navigasikan ke halaman entri, dan tambahkan `?search=vacation` ke URL di address bar. Hanya entri yang mengandung "vacation" di title atau content yang akan muncul. Coba beberapa kata kunci berbeda untuk mengonfirmasi search berfungsi secara konsisten. Ini membuktikan bahwa scope terintegrasi dengan baik dengan logika controller dan rendering view.

---

## 6. Memperbaiki Error pada Kode Anda

Berikut adalah kesalahan paling umum saat bekerja dengan scope, accessor, dan mutator. Masing-masing mudah dilakukan dan mudah diperbaiki begitu Anda tahu apa yang harus dicari.

**Error 1: Method scope tanpa prefix `scope`.**

Error ini terjadi ketika Anda mendefinisikan sebuah method pada model dengan maksud menggunakannya sebagai scope tetapi lupa menambahkan prefix `scope`. Laravel hanya mengenali method scope berdasarkan prefix-nya, jadi tanpa itu method diperlakukan sebagai instance method biasa dan tidak dapat dipanggil sebagai scope statis.

```php
// Wrong: no scope prefix, this is just a regular method
public function recent(Builder $query): Builder
{
    return $query->where('created_at', '>=', now()->subDays(7));
}

// Correct: scope prefix tells Eloquent this is a scope
public function scopeRecent(Builder $query): Builder
{
    return $query->where('created_at', '>=', now()->subDays(7));
}
```

Versi yang salah mendefinisikan `recent` tanpa prefix `scope`. Memanggil `Entry::recent()` kemudian gagal dengan error "Call to undefined method". Versi yang benar memberi nama method `scopeRecent`, memungkinkan Anda memanggilnya sebagai `Entry::recent()` di mana Laravel menghapus prefix secara otomatis.

---

**Error 2: Mengakses property accessor menggunakan camelCase alih-alih snake_case.**

Error ini terjadi ketika Anda mendefinisikan accessor sebagai `readingTime()` tetapi mencoba mengaksesnya di view atau controller sebagai `$entry->readingTime` alih-alih `$entry->reading_time`. Laravel menggunakan konvensi snake_case untuk akses property terlepas dari casing nama method.

```php
// Wrong: camelCase access returns null
$entry->readingTime;

// Correct: snake_case access triggers the accessor
$entry->reading_time;
```

Versi yang salah mengakses property dalam camelCase dan mendapatkan `null` karena Laravel tidak mencocokkannya dengan method `readingTime()`. Versi yang benar menggunakan snake_case (`reading_time`), yang dikonversi Laravel kembali menjadi camelCase secara internal untuk menemukan method accessor yang tepat. Selalu akses property accessor kustom dalam snake_case di view dan controller.

---

**Error 3: Mutator menyebabkan rekursi tak terbatas dengan menugaskan ke `$this`.**

Error ini terjadi ketika Anda menulis callback set sebuah mutator sehingga ia menugaskan sebuah nilai kembali ke property yang sama pada model, yang memicu mutator lagi, menciptakan loop rekursif tak terbatas yang pada akhirnya crash dengan stack overflow.

```php
// Wrong: assigning to $this->title triggers the mutator again
protected function title(): Attribute
{
    return Attribute::set(fn ($value) => $this->title = ucfirst($value));
}

// Correct: return the transformed value directly
protected function title(): Attribute
{
    return Attribute::set(fn ($value) => ucfirst($value));
}
```

Versi yang salah menugaskan hasilnya kembali ke `$this->title` di dalam callback set. Penugasan itu memicu mutator title lagi, yang memicunya lagi, dan seterusnya hingga execution stack overflow. Versi yang benar mengembalikan nilai yang sudah ditransformasi langsung dari closure. Eloquent mengambil nilai yang dikembalikan dan menyimpannya di array attribute model tanpa memicu mutator lagi.

---

## 7. Latihan

Berlatihlah mengembangkan model Entry menggunakan tiga pola dari lesson ini. Setiap latihan bersifat mandiri dan dibangun langsung di atas apa yang Anda tambahkan di langkah-langkah di atas. Coba masing-masing sendiri sebelum memeriksa solusinya.

**Latihan 1:** Tambahkan sebuah scope `scopePopular` yang memfilter entri dengan jumlah komentar lebih dari angka tertentu. Gunakan `$query->withCount('comments')->having('comments_count', '>=', $min)`. Panggil dengan `Entry::popular(3)->get()`.

**Latihan 2:** Tambahkan sebuah accessor `word_count` yang mengembalikan jumlah kata dalam content. Tampilkan di view di sebelah reading time: "245 words · 2 min read".

**Latihan 3:** Tambahkan sebuah mutator `content` yang memangkas whitespace di awal dan akhir dari content sebelum menyimpan. Uji dengan membuat entri dengan spasi ekstra dan memverifikasi content yang tersimpan sudah dipangkas.

---

## 8. Solusi

Setiap solusi di bawah ini menunjukkan satu implementasi yang benar untuk latihan tersebut. Kode Anda dapat berbeda dalam detail kecil selama perilakunya cocok dengan apa yang dijelaskan latihan.

**Solusi untuk Latihan 1:**

Buka `app/Models/Entry.php` dan tambahkan method berikut di dalam body class.

```php
public function scopePopular(Builder $query, int $min = 3): Builder
{
    return $query->withCount('comments')->having('comments_count', '>=', $min);
}
```

`withCount('comments')` menambahkan kolom `comments_count` ke hasil query melalui sebuah subquery. Klausa `having()` memfilter berdasarkan jumlah itu setelah subquery dijalankan. Kita menggunakan `having` alih-alih `where` karena `comments_count` adalah agregat yang dihasilkan oleh subquery, bukan kolom nyata pada tabel `entries`, dan `having` dirancang untuk memfilter pada agregat. Nilai default `$min = 3` memungkinkan Anda memanggil `Entry::popular()->get()` tanpa argumen untuk mendapatkan entri dengan tiga komentar atau lebih, sementara `Entry::popular(5)->get()` menaikkan ambang batas menjadi lima.

---

**Solusi untuk Latihan 2:**

Buka `app/Models/Entry.php` dan tambahkan accessor berikut di dalam body class.

```php
protected function wordCount(): Attribute
{
    return Attribute::get(fn () => str_word_count($this->content));
}
```

Accessor ini memanggil fungsi bawaan PHP `str_word_count()`, yang menghitung jumlah kata dalam sebuah string dan mengembalikan sebuah integer. Akses di view sebagai `$entry->word_count` (snake_case). Perbarui view untuk menampilkan jumlah kata dan reading time bersama-sama.

```blade
<span style="color: #9ca3af; font-size: 0.8em;">
    {{ $entry->word_count }} words · {{ $entry->reading_time }} min read
</span>
```

`$entry->word_count` membaca integer yang dikembalikan oleh accessor, dan titik di antaranya adalah pemisah teks biasa. Tidak ada query tambahan yang dijalankan untuk menghasilkan output ini.

---

**Solusi untuk Latihan 3:**

Buka `app/Models/Entry.php` dan tambahkan method berikut di dalam body class.

```php
protected function content(): Attribute
{
    return Attribute::make(
        get: fn (string $value) => $value,
        set: fn (string $value) => trim($value),
    );
}
```

Callback `set` memanggil `trim()` pada nilai yang masuk sebelum disimpan di database. Callback `get` mengembalikan nilai tersimpan tanpa perubahan. Ini berarti setiap kali content ditulis ke model (melalui `create()`, `update()`, atau penugasan langsung diikuti oleh `save()`), whitespace di awal dan akhir secara otomatis dihapus. Untuk memverifikasinya, buka Tinker dan buat sebuah entri dengan spasi ekstra, lalu gunakan `fresh()` untuk memuat ulang dari database dan mengonfirmasi content yang tersimpan tidak memiliki whitespace di sekitarnya.

---

## Selanjutnya - Lesson 4

Di lesson ini Anda menambahkan tiga jenis kecerdasan model ke model Entry milik Catatku. Local scope mengenkapsulasi filter query yang dapat digunakan kembali sehingga Anda dapat memanggil `Entry::recent()` atau merantai `->search('keyword')` dari controller mana pun tanpa menulis ulang kondisi SQL. Accessor seperti `excerpt` dan `reading_time` menghitung nilai turunan secara langsung tanpa mengubah apa yang disimpan di database, dan view Anda mengaksesnya persis seperti kolom biasa. Mutator seperti `title` menormalisasi input secara otomatis sebelum mencapai database, memastikan konsistensi di setiap jalur kode yang membuat atau memperbarui entri.

Di Lesson 4, Anda akan mempelajari eager loading, soft delete, dan pagination: bagaimana menghilangkan query N+1 dengan `with()`, bagaimana dengan aman "menghapus" entri dengan tetap menyimpannya di database beserta timestamp, dan bagaimana memaginasi hasil yang besar dengan paginator bawaan Laravel.
