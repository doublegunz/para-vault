## 1. Sebelum Anda Memulai

Tiga fitur memisahkan aplikasi Laravel pemula dari yang siap production. Eager loading mencegah masalah query N+1 yang membuat halaman dimuat dengan lambat. Soft delete memungkinkan user memulihkan entri yang terhapus secara tidak sengaja alih-alih kehilangannya secara permanen. Pagination memecah dataset besar menjadi halaman yang dapat dikelola alih-alih memuat ribuan record sekaligus. Lesson ini menambahkan ketiganya ke Catatku.

Masalah N+1 adalah salah satu isu performa paling umum di aplikasi Laravel. Jika halaman feed menampilkan 50 entri, dan setiap entri menampilkan nama penulisnya, itu adalah 51 query database: 1 untuk entri dan 50 lagi untuk setiap penulis. Eager loading mengurangi ini menjadi 2 query. Soft delete menambahkan kolom `deleted_at` yang menandai entri sebagai terhapus tanpa menghapusnya. Pagination hanya memuat 15 (atau berapa pun yang Anda konfigurasikan) entri per halaman. Di akhir lesson ini, feed Catatku akan cepat, perilaku delete-nya akan memaafkan, dan daftar panjang dapat dinavigasi.

### What You'll Build

Anda akan mengoptimalkan feed Catatku dengan eager loading, menambahkan fitur "trash" menggunakan soft delete, dan memaginasi listing entri dengan link navigasi.

### What You'll Learn

- ✅ Masalah query N+1 dan bagaimana `with()` menyelesaikannya
- ✅ Trait `SoftDeletes`: `delete()`, `trashed()`, `restore()`, `forceDelete()`
- ✅ `paginate()`, `simplePaginate()`, dan `$entries->links()` di Blade
- ✅ `withTrashed()` dan `onlyTrashed()` untuk melakukan query entri yang terhapus

### What You'll Need

- Lesson 3 sudah selesai dengan scope dan accessor

---

## 2. Masalah N+1

Untuk memahami eager loading, Anda terlebih dahulu perlu memahami masalah yang diselesaikannya. Masalah N+1 terjadi ketika Anda mengakses sebuah relationship di dalam sebuah loop tanpa memuat data terkait sebelumnya, yang menyebabkan Laravel menjalankan satu query ekstra per iterasi.

### Step 1: Melihat Masalahnya

Buka `app/Http/Controllers/EntryController.php` dan untuk sementara atur method `index` di class `EntryController` menjadi berikut untuk membuat masalah dengan sengaja.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function index()
    {
        $entries = auth()->user()->entries()->latest()->get();

        return view('entries.index', compact('entries'));
    }

    // ... other methods
}
```

Kode ini mengambil entri milik user yang terautentikasi dalam urutan kronologis terbalik. Sekilas terlihat baik-baik saja, tetapi perhatikan bahwa kita memanggil `get()` tanpa pemanggilan `with(...)` apa pun. Ketika Blade view mengakses `$entry->tags` atau `$entry->comments_count`, Eloquent menjalankan query terpisah untuk setiap entri karena relationship tersebut tidak dimuat sebelumnya. Dengan 50 entri, itu adalah 50+ query tambahan. Database menangani masing-masing dengan cepat, tetapi round trip yang terakumulasi menumpuk menjadi lag yang terasa.

### Step 2: Mengukur Masalahnya

Untuk sementara ganti body method `index` di `app/Http/Controllers/EntryController.php` dengan kode diagnostik berikut untuk menghitung query menggunakan query log bawaan Laravel.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function index()
    {
        \DB::enableQueryLog();

        $entries = auth()->user()->entries()->latest()->get();

        foreach ($entries as $entry) {
            $_ = $entry->user->name;
            $_ = $entry->tags->count();
            $_ = $entry->comments->count();
        }

        dd(count(\DB::getQueryLog()));
    }

    // ... other methods
}
```

`\DB::enableQueryLog()` memberi tahu Laravel untuk mulai merekam setiap query SQL yang dijalankannya selama request ini. Pemanggilan `get()` menghasilkan query pertama yang mengambil semua entri. Di dalam loop foreach, setiap akses property memicu query baru karena relationship tersebut tidak dimuat. `dd(count(\DB::getQueryLog()))` mencetak total jumlah query dan menghentikan eksekusi sehingga Anda dapat melihat angkanya. Untuk 50 entri dengan tiga akses relationship masing-masing, Anda mendapatkan 1 + (50 × 3) = 151 query, yang merupakan masalah N+1 dalam kekuatan penuhnya. Hapus kode diagnostik ini setelah mengamati jumlahnya.

### Step 3: Memperbaiki dengan Eager Loading

Perbarui method `index` di `app/Http/Controllers/EntryController.php` dengan eager loading sambil mempertahankan kode diagnostik, sehingga Anda dapat membandingkan jumlah query secara langsung dengan angka yang Anda lihat di Step 2.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function index()
    {
        \DB::enableQueryLog();

        $entries = auth()->user()->entries()
            ->with('tags')
            ->withCount('comments')
            ->latest()
            ->get();

        foreach ($entries as $entry) {
            $_ = $entry->user->name;
            $_ = $entry->tags->count();
            $_ = $entry->comments->count();
        }

        dd(count(\DB::getQueryLog()));
    }

    // ... other methods
}
```

Tambahan kuncinya adalah `->with('tags')` dan `->withCount('comments')` pada query. Method `with('tags')` memuat sebelumnya semua tag untuk semua entri dalam satu query. Alih-alih menjalankan 50 query ketika Anda mengakses `$entry->tags` di view, Eloquent menjalankan satu query menggunakan `WHERE entry_tag.entry_id IN (1, 2, 3, ...)` dan mendistribusikan hasilnya di antara entri-entri di memori. `withCount('comments')` menambahkan attribute `comments_count` ke setiap entri menggunakan sebuah subquery, yang jauh lebih murah daripada memuat setiap record komentar. Totalnya sekarang adalah 3 query terlepas dari berapa banyak entri yang Anda miliki. Segarkan halaman dan bandingkan angka dari `dd()` dengan apa yang Anda lihat di Step 2; selisihnya adalah masalah N+1 yang dihilangkan.

Setelah mengonfirmasi jumlah query turun, hapus semua kode diagnostik dan kembalikan method `index` ke kondisi finalnya dari Lesson 3, yang sudah menyertakan eager loading bersama scope search.

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

---

## 3. Soft Delete

Soft delete menandai record sebagai terhapus dengan menetapkan timestamp `deleted_at`. Record tetap ada di database tetapi dikecualikan dari query normal. Ini memungkinkan user memulihkan entri yang terhapus secara tidak sengaja, yang merupakan pola yang diharapkan user dari aplikasi modern yang memiliki trash atau recycle bin.

### Step 1: Menambahkan Kolom Deleted At

Buat sebuah migration untuk menambahkan kolom soft delete ke tabel entries yang sudah ada.

```bash
php artisan make:migration add_soft_deletes_to_entries --table=entries
```

Flag `--table=entries` memberi tahu Artisan bahwa migration ini memodifikasi tabel yang sudah ada alih-alih membuat yang baru, sehingga file yang dihasilkan menggunakan `Schema::table` alih-alih `Schema::create`. Buka file migration yang dihasilkan dan perbarui method `up()` dan `down()` sebagai berikut.

```php
public function up(): void
{
    Schema::table('entries', function (Blueprint $table) {
        $table->softDeletes();
    });
}

public function down(): void
{
    Schema::table('entries', function (Blueprint $table) {
        $table->dropSoftDeletes();
    });
}
```

Setiap baris melakukan sesuatu yang spesifik. `Schema::table('entries', function (Blueprint $table) { ... })` membuka tabel `entries` yang sudah ada untuk dimodifikasi tanpa menghapusnya. `$table->softDeletes()` adalah shortcut Blueprint yang menambahkan kolom timestamp `deleted_at` yang nullable. Ketika kolom ini NULL, entri aktif. Ketika ia memiliki nilai timestamp, entri "terhapus" tetapi masih ada di database. Method `down()` membalik perubahan menggunakan `$table->dropSoftDeletes()`, menghapus kolom jika Anda melakukan rollback pada migration. Jalankan migration untuk menerapkan perubahan.

```bash
php artisan migrate
```

Anda akan melihat output yang mengonfirmasi kolom ditambahkan ke tabel entries.

### Step 2: Menambahkan Trait ke Model Entry

Buka `app/Models/Entry.php` dan tambahkan import `SoftDeletes` dan deklarasi `use SoftDeletes;` ke class `Entry`.

```php
<?php
// ... others lines of code
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['title', 'content'])]
class Entry extends Model
{
    use SoftDeletes;

    // ... other methods and properties
}
```

Import `use Illuminate\Database\Eloquent\SoftDeletes;` menarik masuk class trait. Menambahkan `use SoftDeletes;` di dalam body class mencampurkan method-methodnya ke dalam model Entry. Di balik layar, trait memodifikasi perilaku default Eloquent: setiap query sekarang secara otomatis menambahkan `WHERE deleted_at IS NULL`, sehingga entri yang ter-soft-delete tidak terlihat oleh query normal. Method `delete()` di-override untuk menetapkan `deleted_at = NOW()` alih-alih menjalankan SQL `DELETE`. Tidak ada perubahan kode lain yang diperlukan; trait menangani semuanya secara transparan.

### Step 3: Memahami Method Soft Delete

Setelah trait aktif, lima method kunci menjadi tersedia pada instance Entry atau query builder mana pun. Tabel di bawah ini merangkum apa yang dilakukan masing-masing.

| Method | Yang dilakukannya |
|---|---|
| `$entry->delete()` | Menetapkan `deleted_at` ke timestamp saat ini |
| `$entry->trashed()` | Mengembalikan `true` jika entri ter-soft-delete |
| `Entry::withTrashed()->get()` | Menyertakan entri yang ter-soft-delete dalam hasil |
| `Entry::onlyTrashed()->get()` | Mengembalikan hanya entri yang ter-soft-delete |
| `$entry->restore()` | Menetapkan `deleted_at` kembali ke NULL |
| `$entry->forceDelete()` | Menghapus baris secara permanen dari database |

`delete()` tetap bekerja sama seperti sebelumnya dari perspektif kode Anda, tetapi secara internal ia sekarang melakukan soft-delete. `trashed()` adalah helper boolean untuk memeriksa kondisinya. `withTrashed()` dan `onlyTrashed()` adalah scope yang disediakan oleh trait untuk melakukan query trash. `restore()` membatalkan soft delete dengan meng-null-kan timestamp. `forceDelete()` melewati soft delete sepenuhnya dan benar-benar menghapus baris; gunakan ini untuk aksi gaya "Empty Trash".

Fungsi delete yang sudah ada di controller Anda sudah bekerja dengan benar; memanggil `$entry->delete()` di `EntryController@destroy` sekarang melakukan soft-delete alih-alih menghapus secara permanen tanpa memerlukan perubahan apa pun pada kode controller Anda.

---

## 4. Pagination

Memuat semua entri baik-baik saja ketika seorang user memiliki 10. Tetapi ketika mereka memiliki 500, halaman menjadi lambat dan browser kesulitan merender daftar. Pagination memuat sejumlah entri tetap per halaman dan menyediakan kontrol navigasi sehingga user dapat berpindah melalui data mereka.

### Step 1: Memperbarui Controller

Buka `app/Http/Controllers/EntryController.php` dan perbarui method `index` di class `EntryController`; satu-satunya perubahan dari Lesson 3 adalah mengganti `->get()` dengan `->paginate(15)` di akhir rantai query.

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

        $entries = $query->latest()->paginate(15);

        return view('entries.index', compact('entries'));
    }

    // ... other methods
}
```

Satu-satunya perubahan dari Lesson 3 adalah `paginate(15)` menggantikan `get()`. Method `paginate(15)` memuat 15 entri per halaman. Ia secara otomatis membaca parameter query `page` dari URL (misalnya, `?page=2`) dan menghitung offset SQL, sehingga Anda tidak perlu melacak nomor halaman secara manual. Objek yang dikembalikan bukan sebuah Collection melainkan sebuah `LengthAwarePaginator`, yang membungkus entri dan menyertakan metadata pagination: nomor halaman saat ini, total halaman, total item, dan URL link untuk Previous dan Next.

### Step 2: Menambahkan Link Pagination ke View

Buka `resources/views/entries/index.blade.php` dan tambahkan link pagination setelah `</div>` penutup dari kontainer daftar entri `space-y-4`.

```blade
{{-- Pagination links --}}
<div style="margin-top: 20px;">
    {{ $entries->links() }}
</div>
```

Method `$entries->links()` merender HTML pagination dengan tombol Previous/Next dan nomor halaman. Laravel secara otomatis memberi style pada ini ketika menggunakan Tailwind CSS (dibahas di Lesson 16). Untuk saat ini, link yang belum di-style tetap fungsional: mengekliknya memperbarui parameter query `?page=N`, dan pemanggilan `paginate()` Laravel membacanya pada request berikutnya untuk mengembalikan potongan data yang benar.

Setelah perubahan, file `index.blade.php` lengkap terlihat seperti ini:

```blade
<x-layout title="My Entries — Catatku">

    <div class="flex items-center justify-between mb-6">
        <h2 class="text-lg font-semibold text-gray-900">My Entries</h2>
        <a href="/entries/create"
            class="bg-gray-900 text-white text-sm px-4 py-2 rounded-lg hover:bg-gray-700 transition-colors">
            + Write New Entry
        </a>
    </div>

    <div class="space-y-4">
        @forelse ($entries as $entry)
        <x-entry-card :entry="$entry" />
        @empty
        <div class="text-center py-16">
            <p class="text-5xl mb-4">📓</p>
            <p class="font-medium text-gray-600">No entries yet</p>
            <p class="text-sm text-gray-400 mt-1">
                Start writing your first entry!
            </p>
            <a href="/entries/create" class="inline-block mt-4 text-sm text-blue-600 hover:underline">
                Write now →
            </a>
        </div>
        @endforelse
    </div>

    {{-- Pagination links --}}
    <div style="margin-top: 20px;">
        {{ $entries->links() }}
    </div>

</x-layout>
```

---

## 5. Menambahkan Halaman Trash

Sekarang setelah soft delete aktif, user seharusnya dapat melihat dan memulihkan entri mereka yang terhapus. Section ini menambahkan halaman trash sederhana untuk memberi mereka kemampuan itu.

### Step 1: Menambahkan Route Trash

Buka `routes/web.php` dan tambahkan dua route baru di dalam group route yang terautentikasi. Route GET trash **harus ditempatkan sebelum** route wildcard `Route::get('/entries/{entry}', ...)` yang sudah ada, jika tidak Laravel akan mencocokkan string literal "trash" sebagai parameter `{entry}` dan memanggil `show()` sebagai gantinya.

```php
Route::get('/entries', [EntryController::class, 'index'])->name('entries.index');
Route::get('/entries/create', [EntryController::class, 'create'])->name('entries.create');
Route::post('/entries', [EntryController::class, 'store'])->name('entries.store');
Route::get('/entries/trash', [EntryController::class, 'trash'])->name('entries.trash'); // must be here, before {entry}
Route::get('/entries/{entry}', [EntryController::class, 'show'])->name('entries.show');
Route::get('/entries/{entry}/edit', [EntryController::class, 'edit'])->name('entries.edit');
Route::put('/entries/{entry}', [EntryController::class, 'update'])->name('entries.update');
Route::delete('/entries/{entry}', [EntryController::class, 'destroy'])->name('entries.destroy');
Route::patch('/entries/{entry}/restore', [EntryController::class, 'restore'])
    ->name('entries.restore')
    ->withTrashed();
Route::post('/entries/{entry}/comments', [CommentController::class, 'store'])->name('comments.store');
```

Laravel mencocokkan route dalam urutan pendaftarannya. Karena `/entries/trash` adalah path literal dan `/entries/{entry}` adalah wildcard, menempatkan trash lebih dulu memastikan route yang spesifik menang. Modifier `->withTrashed()` pada route restore memberi tahu route model binding Laravel untuk menyertakan entri yang ter-soft-delete saat meresolusi parameter `{entry}`. Tanpanya, mengunjungi `/entries/42/restore` akan mengembalikan 404 karena entri 42 memiliki `deleted_at` yang tidak null dan tidak terlihat oleh query normal.

### Step 2: Menambahkan Method Controller

Buka `app/Http/Controllers/EntryController.php` dan tambahkan dua method berikut ke class `EntryController`, setelah method `destroy` yang sudah ada.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function trash()
    {
        $entries = auth()->user()->entries()
            ->onlyTrashed()
            ->latest('deleted_at')
            ->paginate(15);

        return view('entries.trash', compact('entries'));
    }

    public function restore(Entry $entry)
    {
        if ($entry->user_id !== auth()->id()) {
            abort(403);
        }

        $entry->restore();

        return redirect()->route('entries.trash')->with('success', 'Entry restored!');
    }
}
```

Method `trash` menggunakan `onlyTrashed()` untuk menampilkan hanya entri yang ter-soft-delete, yang merupakan kebalikan dari perilaku default. Ia mengurutkan berdasarkan `deleted_at` secara descending sehingga item yang baru ter-trash muncul lebih dulu, dan memaginasi hasilnya. Method `restore` menerima sebuah Entry melalui route model binding; `->withTrashed()` di definisi route memastikan binding dapat menemukan entri yang ter-trash. Pemeriksaan ownership `if ($entry->user_id !== auth()->id())` mengikuti pola yang sama yang digunakan di sepanjang course dasar; jika user yang terautentikasi tidak memiliki entri tersebut, request ditolak dengan 403. `$entry->restore()` menetapkan `deleted_at` kembali ke NULL, mengembalikan entri ke listing normal. Lesson 5 akan mengganti pemeriksaan manual ini dengan sebuah Policy, yang memusatkan logika authorization di satu tempat.

### Step 3: Membuat View Trash

Buat file baru di `resources/views/entries/trash.blade.php` dengan konten berikut.

```blade
<x-layout title="Trash — Catatku">

    <div class="flex items-center justify-between mb-6">
        <h2 class="text-lg font-semibold text-gray-900">Trash</h2>
        <a href="{{ route('entries.index') }}" class="text-sm text-blue-600 hover:underline">
            ← Back to Entries
        </a>
    </div>

    <div class="space-y-4">
        @forelse ($entries as $entry)
        <div class="bg-white rounded-xl border border-gray-200 p-5">
            <div class="flex items-start justify-between gap-3">
                <div>
                    <p class="font-semibold text-gray-900">{{ $entry->title }}</p>
                    <p style="color: #9ca3af; font-size: 0.8em; margin-top: 4px;">
                        Deleted {{ $entry->deleted_at->diffForHumans() }}
                    </p>
                </div>
                <form method="POST" action="{{ route('entries.restore', $entry) }}">
                    @csrf
                    @method('PATCH')
                    <button type="submit" class="text-xs text-blue-600 hover:text-blue-800">
                        Restore
                    </button>
                </form>
            </div>
        </div>
        @empty
        <div class="text-center py-16">
            <p class="text-5xl mb-4">🗑️</p>
            <p class="font-medium text-gray-600">Trash is empty</p>
            <p class="text-sm text-gray-400 mt-1">Deleted entries will appear here.</p>
        </div>
        @endforelse
    </div>

    <div style="margin-top: 20px;">
        {{ $entries->links() }}
    </div>

</x-layout>
```

View menggunakan `<x-layout>` untuk membungkus konten dalam shell aplikasi bersama. Directive `@forelse` mengulang `$entries` yang dipaginasi dan beralih ke kondisi kosong ketika trash tidak memiliki item. Untuk setiap entri, title dan `deleted_at->diffForHumans()` ditampilkan sehingga user tahu kapan entri dihapus. Form Restore menggunakan `@method('PATCH')` karena browser hanya mendukung GET dan POST secara native; field tersembunyi `_method` memberi tahu router Laravel untuk memperlakukannya sebagai request PATCH, mencocokkan route `entries.restore` yang didefinisikan di Step 1. Link pagination di bagian bawah bekerja secara identik dengan listing utama karena keduanya menggunakan `paginate(15)`.

---

## 6. Menjalankan dan Menguji

Mari kita verifikasi ketiga fitur bekerja bersama di browser dan di Tinker.

### Step 1: Menguji Eager Loading

Jalankan server dan navigasikan ke halaman entri.

```bash
php artisan serve
```

Halaman seharusnya dimuat dengan cepat. Untuk memverifikasi jumlah query, terapkan kembali diagnostik query log dari Step 2 Section 2, kali ini dengan eager loading di tempatnya. Total jumlah query seharusnya turun dari ~150 menjadi sekitar 3, terlepas dari berapa banyak entri yang dimiliki user.

### Step 2: Menguji Soft Delete

Hapus sebuah entri dari UI menggunakan tombol delete Anda yang sudah ada. Entri seharusnya menghilang dari listing utama seperti sebelumnya. Navigasikan ke `/entries/trash`. Entri yang dihapus seharusnya muncul di sana dengan title-nya dan timestamp yang menunjukkan kapan ia dihapus. Tambahkan tombol "Restore" ke view trash Anda yang mengirim sebuah form dengan method PATCH yang menunjuk ke route restore. Klik Restore dan konfirmasi entri kembali ke listing utama.

### Step 3: Menguji di Tinker

Buka terminal baru dan jalankan Tinker untuk memverifikasi perilaku soft delete dari command line.

```bash
php artisan tinker
```

Jalankan perintah berikut secara berurutan untuk mengamati bagaimana soft delete memengaruhi hasil query.

```php
$entry = \App\Models\Entry::first();
$entry->delete();

\App\Models\Entry::count();
\App\Models\Entry::withTrashed()->count();

$entry->restore();
\App\Models\Entry::count();
```

Setelah memanggil `delete()`, `count()` pertama mengembalikan angka yang lebih kecil karena query normal melewati baris yang ter-trash. `withTrashed()->count()` menyertakannya, sehingga totalnya tidak berubah. Setelah memanggil `restore()`, `count()` normal kembali ke nilai aslinya. Ini mendemonstrasikan sifat tak-terlihat-tetapi-ada dari soft delete: record tidak pernah meninggalkan database, hanya visibilitasnya yang berubah. Ketik `exit` untuk keluar dari Tinker.

### Step 4: Menguji Pagination

Jika Anda memiliki kurang dari 15 entri, link pagination tidak akan muncul karena hanya ada satu halaman. Untuk sementara ubah `paginate(15)` menjadi `paginate(2)` untuk memaksa pagination dengan entri yang lebih sedikit. Navigasikan antar halaman dan verifikasi entri yang benar muncul di setiap halaman, lalu kembalikan nilai aslinya.

---

## 7. Memperbaiki Error pada Kode Anda

Berikut adalah kesalahan paling umum saat bekerja dengan eager loading, soft delete, dan pagination.

**Error 1: Menggunakan trait `SoftDeletes` tanpa menjalankan migration.**

Error ini terjadi ketika Anda menambahkan `use SoftDeletes;` ke model tetapi lupa membuat dan menjalankan migration yang menambahkan kolom `deleted_at`. Setiap query kemudian gagal karena Eloquent menambahkan `WHERE deleted_at IS NULL` yang mereferensikan kolom yang tidak ada.

```php
// Wrong: trait added to model without a deleted_at column in the database
class Entry extends Model
{
    use SoftDeletes;
}

// Correct: migration creates the column first, then the trait manages it
Schema::table('entries', function (Blueprint $table) {
    $table->softDeletes();
});

class Entry extends Model
{
    use SoftDeletes;
}
```

Versi yang salah mengaktifkan trait pada model sebelum migration apa pun menambahkan kolom `deleted_at` ke database. Setiap query langsung melemparkan "Unknown column 'entries.deleted_at'" karena Eloquent menambahkan `WHERE deleted_at IS NULL` ke setiap query Entry saat trait digunakan. Versi yang benar menjalankan migration terlebih dahulu sehingga kolom ada sebelum trait mereferensikannya. Urutan yang diperlukan adalah: buat migration dengan `php artisan make:migration add_soft_deletes_to_entries --table=entries`, tambahkan `$table->softDeletes()` ke method `up()`-nya, jalankan `php artisan migrate` untuk menerapkannya, dan hanya setelah mengonfirmasi kolom ada barulah tambahkan `use SoftDeletes;` ke model.

---

**Error 2: Memanggil `links()` pada sebuah Collection alih-alih sebuah Paginator.**

Error ini terjadi ketika Anda menggunakan `all()` atau `get()` di controller lalu mencoba memanggil `->links()` di view. Baik `all()` maupun `get()` mengembalikan sebuah `Collection`, yang tidak memiliki method `links()`. Hanya `paginate()` dan `simplePaginate()` yang mengembalikan sebuah Paginator yang mendukung `links()`.

```php
// Wrong: get() returns a Collection which has no links() method
$entries = Entry::latest()->get();

// Correct: paginate() returns a LengthAwarePaginator that supports links()
$entries = Entry::latest()->paginate(15);
```

Versi yang salah memanggil `get()`, sehingga `$entries->links()` di view melemparkan "Method links does not exist". Versi yang benar memanggil `paginate(15)`, yang mengembalikan sebuah `LengthAwarePaginator` yang menyertakan baik entri maupun metadata yang dibutuhkan untuk merender navigasi halaman.

---

**Error 3: Route model binding mengembalikan 404 untuk entri yang ter-soft-delete.**

Error ini terjadi ketika Anda mendefinisikan route restore tetapi lupa menambahkan `->withTrashed()`. Secara default, `{entry}` di sebuah URL route hanya meresolusi entri yang aktif (tidak terhapus), sehingga meminta URL restore dari sebuah entri yang ter-trash mengembalikan 404 alih-alih menemukan record-nya.

```php
// Wrong: missing withTrashed(), soft-deleted entries cannot be resolved
Route::patch('/entries/{entry}/restore', [EntryController::class, 'restore'])
    ->name('entries.restore');

// Correct: withTrashed() tells route model binding to include soft-deleted records
Route::patch('/entries/{entry}/restore', [EntryController::class, 'restore'])
    ->name('entries.restore')
    ->withTrashed();
```

Tanpa `->withTrashed()`, mengunjungi `/entries/42/restore` mengembalikan 404 karena entri 42 memiliki `deleted_at` yang tidak null dan query default Eloquent mengecualikannya. Menambahkan `->withTrashed()` secara eksplisit mengizinkan route model binding menemukan record yang ter-trash sehingga method restore menerimanya dengan benar.

---

## 8. Latihan

Berlatihlah dengan tiga fitur dari lesson ini dengan mengembangkan apa yang sudah Anda bangun. Setiap latihan menargetkan satu konsep spesifik sehingga Anda dapat memverifikasi pemahaman Anda secara independen sebelum melanjutkan.

**Latihan 1:** Gunakan `DB::enableQueryLog()` dan `DB::getQueryLog()` untuk membandingkan jumlah query yang tepat dengan dan tanpa eager loading pada feed entri. Dokumentasikan selisihnya untuk 10 entri.

**Latihan 2:** Tambahkan tombol "Permanently Delete" pada halaman trash yang memanggil `$entry->forceDelete()`. Tambahkan dialog konfirmasi dengan JavaScript `confirm()` sebelum form dikirim.

**Latihan 3:** Beralih dari `paginate(15)` ke `simplePaginate(15)`. Bandingkan HTML yang dirender. `simplePaginate` hanya menampilkan tombol Previous/Next tanpa nomor halaman, yang lebih cepat untuk tabel yang sangat besar karena melewati query penghitungan total.

---

## 9. Solusi

Setiap solusi di bawah ini menyediakan implementasi lengkap untuk latihan yang sesuai. Baca penjelasan setelah setiap blok kode untuk memahami mengapa kode itu berfungsi, bukan hanya apa yang dilakukannya.

**Solusi untuk Latihan 1:**

Untuk sementara ganti body method `index` di `app/Http/Controllers/EntryController.php` dengan kode diagnostik berikut, jalankan halaman, dan bandingkan dengan dan tanpa pemanggilan `with()`.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function index()
    {
        \DB::enableQueryLog();

        $entries = Entry::with('user', 'tags')->withCount('comments')->get();

        foreach ($entries as $entry) {
            $_ = $entry->user->name;
            $_ = $entry->tags->count();
        }

        dd(count(\DB::getQueryLog()));
    }

    // ... other methods
}
```

`\DB::enableQueryLog()` mulai merekam query. `with('user', 'tags')` memuat sebelumnya kedua relationship secara massal. Loop foreach mengakses property tersebut, tetapi karena mereka di-eager-load, tidak ada query baru yang dijalankan. `dd(count(\DB::getQueryLog()))` menampilkan totalnya dan menghentikan eksekusi. Dengan eager loading di tempatnya, jumlahnya seharusnya 3 hingga 4 query terlepas dari jumlah entri. Tanpa eager loading, loop yang sama pada 10 entri menghasilkan 1 + (10 × 2) = 21 query. Selisihnya tumbuh secara linear dengan jumlah entri.

---

**Solusi untuk Latihan 2:**

Daftarkan route force-delete di dalam group route yang terautentikasi di `routes/web.php`.

```php
Route::delete('/entries/{entry}/force-delete', [EntryController::class, 'forceDestroy'])
    ->name('entries.force-destroy')
    ->withTrashed();
```

Tambahkan method controller ke `app/Http/Controllers/EntryController.php`.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function forceDestroy(Entry $entry)
    {
        if ($entry->user_id !== auth()->id()) {
            abort(403);
        }

        $entry->forceDelete();

        return redirect()->route('entries.trash')->with('success', 'Entry permanently deleted.');
    }
}
```

Di `resources/views/entries/trash.blade.php`, tambahkan tombol permanently delete dengan sebuah dialog konfirmasi.

```blade
<form method="POST" action="{{ route('entries.force-destroy', $entry) }}"
      onsubmit="return confirm('This cannot be undone. Permanently delete?')">
    @csrf
    @method('DELETE')
    <button type="submit" style="color: #dc2626; background: none; border: none; cursor: pointer;">
        Permanently Delete
    </button>
</form>
```

Pemeriksaan ownership `if ($entry->user_id !== auth()->id())` mencegah seorang user menghapus secara permanen entri yang ter-trash milik user lain. `forceDelete()` melewati soft delete dan menghapus record secara permanen dari database. JavaScript `confirm()` di `onsubmit` menampilkan dialog browser dan membatalkan pengiriman form jika user mengeklik Cancel. `->withTrashed()` pada route diperlukan sehingga route model binding dapat menemukan entri yang ter-soft-delete.

---

**Solusi untuk Latihan 3:**

Buka `app/Http/Controllers/EntryController.php` dan ganti `paginate(15)` dengan `simplePaginate(15)` di method `index` dari class `EntryController`.

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

        $entries = $query->latest()->simplePaginate(15);

        return view('entries.index', compact('entries'));
    }

    // ... other methods
}
```

Return type berubah dari `LengthAwarePaginator` menjadi `Paginator`. Perbedaan praktisnya adalah `simplePaginate` hanya menjalankan satu query SQL untuk mengambil record halaman saat ini, sementara `paginate` menjalankan query `SELECT COUNT(*)` kedua untuk menentukan jumlah total halaman. Untuk tabel besar dengan jutaan baris, query count itu bisa lambat. Trade-off-nya adalah `$entries->links()` di view sekarang hanya merender tombol Previous dan Next, tanpa link nomor halaman, karena `simplePaginate` tidak mengetahui jumlah total record. Ubah nilainya kembali ke `paginate(15)` untuk Catatku kecuali jumlah entri tumbuh cukup besar untuk membenarkan peralihan.

---

## Selanjutnya - Lesson 5

Di lesson ini Anda menerapkan tiga fitur kelas production ke Catatku. Eager loading dengan `with()` menghilangkan masalah query N+1 dengan memuat sebelumnya relationship secara massal, mengurangi puluhan query menjadi segelintir terlepas dari ukuran dataset. Soft delete dengan trait `SoftDeletes` dan kolom `deleted_at` membuat penghapusan menjadi memaafkan: entri dapat dipulihkan dari halaman trash tanpa kehilangan data apa pun. Pagination dengan `paginate(15)` dan `$entries->links()` memastikan feed tetap cepat dan dapat dinavigasi bahkan ketika seorang user memiliki ratusan entri.

Di Lesson 5, Anda akan mempelajari Gate dan Policy: bagaimana mendefinisikan dan menegakkan aturan authorization sehingga user hanya dapat melihat, mengedit, dan menghapus entri mereka sendiri, tidak peduli bagaimana mereka mencoba mencapai halaman tersebut.
