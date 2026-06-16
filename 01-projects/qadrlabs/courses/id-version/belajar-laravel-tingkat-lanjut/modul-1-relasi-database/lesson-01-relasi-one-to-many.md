## 1. Sebelum Anda Memulai

Di course pemula, Catatku hanya memiliki satu model: `Entry`. Setiap entri dimiliki oleh seorang user melalui kolom `user_id`, tetapi kita tidak pernah mendefinisikan relationship tersebut secara formal di Eloquent. Kita juga tidak pernah menambahkan data terkait seperti komentar. Di aplikasi nyata, data saling terhubung: user memiliki banyak entri, entri memiliki banyak komentar, order memiliki banyak item. Relationship Eloquent memungkinkan Anda mendefinisikan koneksi ini sekali saja dan melakukan query lintas relationship dengan mudah.

Lesson ini mengajarkan relationship yang paling umum di Laravel: one-to-many. Satu user memiliki banyak entri. Satu entri memiliki banyak komentar. Anda akan mendefinisikan relationship `hasMany` dan `belongsTo`, membuat record terkait, dan melakukan query lintas relationship. Di akhir lesson, entri Catatku akan memiliki sistem komentar yang berfungsi dan dapat Anda gunakan di browser.

### What You'll Build

Anda akan menambahkan model `Comment` ke Catatku. Setiap entri dapat memiliki banyak komentar, dan setiap komentar dimiliki oleh satu user dan satu entri. Anda akan menampilkan komentar di bawah setiap entri dan membuat form untuk mengirim komentar baru.

### What You'll Learn

- ✅ `hasMany()` pada model parent
- ✅ `belongsTo()` pada model child
- ✅ Membuat record terkait dengan `$entry->comments()->create()`
- ✅ Melakukan query relationship: `$user->entries`, `$entry->comments`
- ✅ Inverse relationship dan konvensi foreign key
- ✅ Migration dengan foreign key constraint
- ✅ Menampilkan data terkait di Blade view

### What You'll Need

- Proyek Catatku dari course pemula dengan user dan entri yang sudah berfungsi
- Development server Laravel 13 yang berjalan (`php artisan serve`)

---

## 2. Membuat Migration Comments

Setiap relationship dimulai dari database. Sebelum Eloquent dapat menghubungkan entri ke komentar, tabel `comments` harus ada dengan kolom foreign key yang tepat. Sebuah komentar dimiliki oleh sebuah entri dan seorang user, jadi ia membutuhkan foreign key `entry_id` dan `user_id`. Di section ini Anda akan membuat sebuah model yang dipasangkan dengan migration-nya, mendefinisikan skema tabel, dan menerapkannya ke database.

### Step 1: Membuat Migration dan Model

Buka terminal Anda di direktori proyek Catatku dan jalankan perintah berikut. Flag `-m` memberi tahu Artisan untuk membuat file migration bersama dengan model.

```bash
php artisan make:model Comment -m
```

Perintah ini membuat dua file sekaligus. Yang pertama adalah `app/Models/Comment.php`, yaitu class model Eloquent yang akan Anda gunakan untuk melakukan query dan memanipulasi record komentar. Yang kedua adalah file migration di `database/migrations/` yang nama filenya diawali dengan timestamp (misalnya, `2026_04_17_093000_create_comments_table.php`). Laravel menggunakan timestamp tersebut untuk menentukan urutan migration dijalankan, sehingga migration yang lebih baru selalu dijalankan setelah yang lebih lama.

### Step 2: Mendefinisikan Migration

Buka file migration yang baru saja dibuat di `database/migrations/`. Nama file berisi timestamp diikuti oleh `_create_comments_table.php`. Ganti isi method `up()` dengan definisi skema berikut.

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('comments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('entry_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->text('body');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('comments');
    }
};
```

Sekarang mari kita telusuri setiap baris agar Anda memahami persis apa yang dilakukan migration ini. Statement `use` di bagian atas mengimpor tiga class yang dibutuhkan Laravel untuk migration: `Migration` adalah base class, `Blueprint` adalah objek yang Anda gunakan untuk mendefinisikan kolom, dan `Schema` adalah facade yang berkomunikasi dengan database. Sintaks `return new class extends Migration` adalah anonymous migration class, yang diperkenalkan Laravel untuk menghindari konflik penamaan antar file migration. Di dalam method `up()`, pemanggilan `Schema::create('comments', ...)` memberi tahu Laravel untuk membuat tabel baru bernama `comments`. Closure menerima objek `Blueprint` bernama `$table` yang Anda gunakan untuk mendefinisikan setiap kolom.

`$table->id()` membuat primary key auto-increment bernama `id`. Baris `$table->foreignId('entry_id')->constrained()->cascadeOnDelete()` melakukan tiga hal sekaligus: membuat kolom bernama `entry_id` sebagai unsigned big integer, menambahkan foreign key constraint yang menunjuk ke kolom `id` pada tabel `entries` (Laravel menyimpulkan nama tabel dari nama kolom), dan menetapkan aturan cascading delete sehingga ketika sebuah entri dihapus, setiap komentar milik entri tersebut otomatis ikut terhapus. Pola yang sama berulang untuk `user_id`, yang menghubungkan setiap komentar ke penulisnya di tabel `users`. `$table->text('body')` membuat kolom `TEXT` yang dapat menyimpan konten komentar panjang tanpa batas karakter. `$table->timestamps()` menambahkan dua kolom standar, `created_at` dan `updated_at`, yang dikelola Laravel secara otomatis. Method `down()` mendefinisikan operasi kebalikannya: jika suatu saat Anda melakukan rollback pada migration ini, `Schema::dropIfExists('comments')` akan menghapus seluruh tabel.

### Step 3: Menjalankan Migration

Jalankan migration untuk membuat tabel di database.

```bash
php artisan migrate
```

Anda akan melihat output yang mengonfirmasi bahwa tabel `comments` berhasil dibuat. Jika Anda mendapat error tentang tabel `entries` atau `users` yang tidak ada, pastikan Anda sudah menjalankan semua migration sebelumnya dari course pemula terlebih dahulu, karena foreign key tidak dapat menunjuk ke tabel yang belum ada.

---

## 3. Mendefinisikan Relationship

Setelah tabel database ada, Anda perlu memberi tahu Eloquent bagaimana model-model tersebut saling berhubungan. Relationship didefinisikan sebagai method pada class model. Setelah didefinisikan, nama method menjadi property yang dapat Anda gunakan untuk mengakses data terkait, dan Laravel menangani SQL join yang mendasarinya secara otomatis untuk Anda.

### Step 1: User Memiliki Banyak Entry

Relationship `entries()` sudah didefinisikan pada model `User` di course pemula. Buka `app/Models/User.php` dan pastikan method berikut ada.

```php
use Illuminate\Database\Eloquent\Relations\HasMany;

public function entries(): HasMany
{
    return $this->hasMany(Entry::class);
}
```

Mari kita periksa kode ini bagian demi bagian. Statement `use` mengimpor class `HasMany`, yang merupakan return type dari method relationship. Nama method `entries` penting karena ia menjadi nama property yang Anda gunakan untuk mengakses data terkait: `$user->entries`. Return type `HasMany` adalah type hint yang membuat relationship menjelaskan dirinya sendiri dan membantu IDE Anda menyediakan autocomplete. Di dalam method, `$this->hasMany(Entry::class)` memberi tahu Eloquent bahwa satu User dapat memiliki banyak record Entry. Laravel secara otomatis mencari kolom `user_id` pada tabel `entries` untuk membuat koneksi (inilah konvensi penamaan: nama model parent dalam snake_case ditambah `_id`). Anda sekarang dapat mengakses semua entri milik seorang user dengan `$user->entries` dan mendapatkan kembali sebuah Collection berisi model Entry.

### Step 2: Entry Milik User, Memiliki Banyak Comment

Buka `app/Models/Entry.php` dan perbarui agar mendefinisikan baik relationship `belongsTo` yang sudah ada dengan User maupun relationship `hasMany` yang baru dengan Comment.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['title', 'content'])]
class Entry extends Model
{
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function comments(): HasMany
    {
        return $this->hasMany(Comment::class);
    }
}
```

Membaca class ini dengan cermat, Anda akan melihat tiga bagian penting. Statement `use` membawa masuk class attribute `Fillable` bersama kedua class relationship (`BelongsTo` dan `HasMany`) sehingga masing-masing dapat di-type-hint dengan benar. Attribute `#[Fillable(['title', 'content'])]` yang ditempatkan di atas deklarasi class mendaftar kolom yang diizinkan untuk di-mass assign saat membuat atau memperbarui sebuah entri. Ini adalah fitur keamanan yang dibawa dari course pemula yang mencegah user menetapkan kolom seperti `user_id` melalui input request. Laravel 13 menggunakan sintaks PHP attribute ini sebagai pengganti modern untuk property `protected $fillable = [...]` yang lama; jika Anda pernah melihat tutorial lama, itulah padanannya. Method `user()` mendefinisikan inverse dari relationship one-to-many: entri ini dimiliki oleh satu user. Eloquent mengasumsikan foreign key-nya adalah `user_id` pada tabel `entries` (mengikuti konvensi nama parent ditambah `_id`). Method `comments()` menyatakan bahwa entri ini dapat memiliki banyak komentar, dan Eloquent akan mencari kolom `entry_id` pada tabel `comments`, yang persis merupakan kolom yang Anda definisikan di migration. Perhatikan bagaimana konvensi penamaan mengerjakan banyak hal: karena Anda mengikuti konvensi, Anda tidak pernah perlu menulis satu baris konfigurasi pun untuk memberi tahu Laravel tentang nama kolom.

### Step 3: Comment Milik User dan Entry

Buka `app/Models/Comment.php` dan ganti konten yang dihasilkan dengan kode berikut.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['body', 'user_id'])]
class Comment extends Model
{
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function entry(): BelongsTo
    {
        return $this->belongsTo(Entry::class);
    }
}
```

Sebuah komentar memiliki dua relationship `belongsTo` karena ia berada di persimpangan dua parent. Method `user()` menyatakan bahwa komentar dimiliki oleh user yang menulisnya, dan Eloquent mencari kolom `user_id` untuk membuat koneksi itu. Method `entry()` menyatakan bahwa komentar juga dimiliki oleh entri tempat ia dikirim, menggunakan kolom `entry_id`. `#[Fillable]` menyertakan `body` dan `user_id` karena controller meneruskan keduanya melalui `create()`. `entry_id` sengaja dikecualikan: ia ditetapkan secara otomatis oleh method relationship `$entry->comments()->create(...)`, yang mengisi `entry_id` di balik layar; Anda tidak pernah perlu meneruskannya secara eksplisit. Yang menjadi perhatian keamanan bukanlah apakah `user_id` fillable, melainkan dari mana nilainya berasal: controller selalu mengambilnya dari `$request->user()->id` (session yang terautentikasi), tidak pernah dari input request, sehingga user jahat tidak dapat menimpanya.

---

## 4. Membuat Comment Controller

Dengan model dan relationship yang sudah didefinisikan, Anda membutuhkan sebuah controller untuk menangani pembuatan komentar. Komentar selalu dibuat dalam konteks sebuah entri tertentu, jadi method store menerima sebuah Entry sebagai route parameter, dan controller menggunakan method relationship agar komentar baru mewarisi ID entri secara otomatis.

### Step 1: Membuat Controller

Jalankan perintah Artisan berikut untuk membuat file controller kosong untuk komentar.

```bash
php artisan make:controller CommentController
```

Perintah ini membuat `app/Http/Controllers/CommentController.php`, sebuah class controller kosong yang meng-extend base controller Laravel. Anda akan menambahkan method `store` ke file ini pada langkah berikutnya.

### Step 2: Menulis Method Store

Buka `app/Http/Controllers/CommentController.php` dan ganti kontennya dengan berikut.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Entry;
use Illuminate\Http\Request;

class CommentController extends Controller
{
    public function store(Request $request, Entry $entry)
    {
        $validated = $request->validate([
            'body' => 'required|string|min:2|max:1000',
        ]);

        $entry->comments()->create([
            ...$validated,
            'user_id' => $request->user()->id,
        ]);

        return back()->with('success', 'Comment posted!');
    }
}
```

Mari kita uraikan method ini ke dalam tahap-tahapnya. Signature method `store(Request $request, Entry $entry)` menggunakan dua objek yang di-inject melalui dependency injection. Objek `Request` berisi data pengiriman form. Parameter `Entry $entry` menggunakan route model binding Laravel: ketika URL berbentuk seperti `/entries/5/comments`, Laravel secara otomatis mengambil Entry dengan ID 5 dan menyuntikkannya di sini, mengembalikan 404 jika tidak ada.

Di dalam method, `$request->validate([...])` memeriksa bahwa input memenuhi aturan: `required` berarti field harus ada, `string` berarti harus bertipe string, `min:2` berarti minimal 2 karakter, dan `max:1000` membatasinya hingga 1000 karakter. Jika validasi gagal, Laravel secara otomatis melakukan redirect kembali dengan pesan error, sehingga tidak ada kode lanjutan yang dijalankan. Baris `$entry->comments()->create([...])` adalah tempat interaksi kunci terjadi: ia menggunakan method relationship `comments()` untuk membuat komentar baru, dan Laravel secara otomatis mengisi `entry_id` karena relationship sudah mengetahui entri mana yang sedang Anda kerjakan. Spread operator `...$validated` membongkar data yang tervalidasi (hanya field `body`) ke dalam array, dan kita menambahkan `user_id` secara manual dari user yang terautentikasi. Inilah persis pertahanan yang kita bicarakan sebelumnya: kita tidak pernah menerima `user_id` dari user. Akhirnya, `back()->with('success', 'Comment posted!')` melakukan redirect ke halaman sebelumnya dan menyimpan pesan sukses ke session sehingga request berikutnya dapat menampilkannya.

### Step 3: Mendaftarkan Route

Sebelum menambahkan route komentar, berikan nama pada route entri yang sudah ada. Course pemula tidak membahas nama route, tetapi nama route adalah konvensi yang digunakan di seluruh course ini dan di hampir setiap aplikasi Laravel nyata. Buka `routes/web.php` dan tambahkan `->name(...)` ke setiap route entri di dalam group middleware `auth`.

```php
Route::middleware('auth')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/entries', [EntryController::class, 'index'])->name('entries.index');
    Route::get('/entries/create', [EntryController::class, 'create'])->name('entries.create');
    Route::post('/entries', [EntryController::class, 'store'])->name('entries.store');
    Route::get('/entries/{entry}', [EntryController::class, 'show'])->name('entries.show');
    Route::get('/entries/{entry}/edit', [EntryController::class, 'edit'])->name('entries.edit');
    Route::put('/entries/{entry}', [EntryController::class, 'update'])->name('entries.update');
    Route::delete('/entries/{entry}', [EntryController::class, 'destroy'])->name('entries.destroy');
});
```

Tujuh route ini juga dapat dideklarasikan dalam satu baris menggunakan `Route::resource()`, yang menghasilkan tujuh nama yang sama secara otomatis.

```php
// Route::resource() generates all seven routes above with the same names
Route::resource('entries', EntryController::class);
```

Di course ini kita menulis setiap route secara eksplisit sehingga setiap URL terlihat, tetapi `Route::resource()` adalah bentuk singkat yang digunakan kebanyakan tim setelah mereka memahami route apa yang dihasilkannya.

Nama route digunakan dengan helper `route()` di seluruh view dan controller. Alih-alih menulis `href="/entries/{{ $entry->id }}"` secara hardcode, Anda menulis `href="{{ route('entries.show', $entry) }}"`. Helper tersebut menerjemahkan nama menjadi URL yang benar dan mengisi parameter route apa pun dari model atau array yang Anda teruskan sebagai argumen kedua. Konvensi penamaan `resource.action` (misalnya, `entries.index`, `entries.show`, `entries.destroy`) adalah pola standar Laravel: Anda selalu dapat menebak namanya tanpa harus mencarinya. Manfaat lainnya adalah jika suatu saat Anda mengubah nama sebuah URL, Anda memperbarui satu baris di `routes/web.php` dan setiap pemanggilan `route(...)` di view dan controller Anda diperbarui secara otomatis, karena semuanya merujuk pada nama, bukan path mentah.

Sekarang tambahkan route komentar di dalam group yang sama, di bawah route entri. Kita mendaftarkan dua: satu untuk membuat komentar, dan satu untuk menghapusnya (yang akan Anda implementasikan di Step 4).

```php
use App\Http\Controllers\CommentController;

Route::middleware('auth')->group(function () {
    // ... entry routes above ...
    Route::post('/entries/{entry}/comments', [CommentController::class, 'store'])
        ->name('comments.store');
    Route::delete('/comments/{comment}', [CommentController::class, 'destroy'])
        ->name('comments.destroy');
});
```

Pola URL `/entries/{entry}/comments` menyarangkan endpoint komentar di bawah entri, dan segmen `{entry}` adalah yang memicu route model binding di controller sehingga Laravel meresolusi Entry secara otomatis dari URL. `Route::post(...)` berarti route ini hanya menerima request POST, yang tepat untuk membuat sebuah resource. `->name('comments.store')` menetapkan nama yang digunakan pada action form: `route('comments.store', $entry)`. Meneruskan model entri sebagai argumen kedua memberi tahu helper `route()` untuk mengisi `{entry}` dengan ID entri. Route kedua, `comments.destroy`, mengambil parameter `{comment}` secara langsung karena menghapus sebuah komentar hanya membutuhkan ID komentar, bukan ID entri.

### Step 4: Menambahkan Method untuk Menghapus Comment

Penulis komentar seharusnya dapat menghapus komentarnya sendiri. Buka `app/Http/Controllers/CommentController.php` dan tambahkan method `destroy` di bawah method `store` yang sudah ada.

```php
public function destroy(Comment $comment)
{
    if ($comment->user_id !== auth()->id()) {
        abort(403);
    }

    $comment->delete();

    return back()->with('success', 'Comment deleted.');
}
```

Anda juga perlu mengimpor model `Comment` di bagian atas file, bersama baris `use App\Models\Entry;` yang sudah ada:

```php
use App\Models\Comment;
```

Method menerima sebuah `Comment` melalui route model binding (parameter `{comment}` di route meresolusi ke record yang cocok, mengembalikan 404 jika tidak ada). Pemeriksaan `if ($comment->user_id !== auth()->id())` adalah ownership guard: ia membandingkan penulis komentar dengan user yang sedang terautentikasi dan memanggil `abort(403)` jika keduanya tidak cocok, sehingga seorang user tidak dapat menghapus komentar milik orang lain dengan menebak URL. Ini adalah gaya pemeriksaan manual yang sama seperti yang digunakan di course pemula. Di Lesson 5 Anda akan mengganti `if` inline ini dengan **Policy** khusus (`CommentPolicy`) dan `Gate::authorize('delete', $comment)`, yang memusatkan logika authorization; tetapi pemeriksaan manual ini sudah benar dan cukup untuk saat ini. Setelah menghapus, `back()->with('success', ...)` kembali ke halaman entri dengan flash message.

---

## 5. Menampilkan Comment dan Form Comment

Sekarang Anda perlu memperbarui view detail entri untuk menampilkan komentar yang ada dan menyediakan form untuk mengirim komentar baru. Agar tetap efisien, Anda juga akan melakukan eager load pada penulis komentar sehingga view tidak menjalankan query database terpisah untuk setiap penulis komentar.

### Step 1: Memperbarui Method Show pada Entry Controller

Buka `EntryController.php` Anda dan perbarui method `show` untuk melakukan eager load komentar beserta penulisnya sebelum meneruskan entri ke view.

```php
public function show(Entry $entry)
{
    if ($entry->user_id !== auth()->id()) {
        abort(403);
    }

    $entry->load('comments.user');

    return view('entries.show', compact('entry'));
}
```

Pemeriksaan authorization dari course pemula dipertahankan: jika entri bukan milik user yang sedang terautentikasi, `abort(403)` segera mengembalikan respons Forbidden. Baris baru `$entry->load('comments.user')` melakukan eager load pada dua tingkat relationship: semua komentar untuk entri ini, dan user yang menulis setiap komentar. Notasi titik `comments.user` memberi tahu Eloquent untuk menelusuri satu tingkat lebih jauh setelah memuat komentar. Tanpa eager loading ini, setiap kali view Anda merender `$comment->user->name`, Eloquent akan menjalankan query database baru untuk mengambil user tersebut; sebuah entri dengan 20 komentar akan menghasilkan 21 query (ini disebut masalah N+1, yang dibahas mendalam di Lesson 4). Dengan eager loading, hanya tiga query yang dijalankan secara total berapa pun jumlah komentarnya: satu untuk entri, satu untuk semua komentarnya, dan satu untuk semua penulis komentar. Helper `compact('entry')` membangun array `['entry' => $entry]` untuk diteruskan ke view.

### Step 2: Memperbarui View Show

Buka `resources/views/entries/show.blade.php` dan perbarui dengan section komentar dan form di bawah konten entri.

```blade
<x-layout>
    <div style="max-width: 700px; margin: 0 auto;">

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
                @if (auth()->id() === $comment->user_id)
                    <form method="POST" action="{{ route('comments.destroy', $comment) }}"
                          onsubmit="return confirm('Delete this comment?')" style="margin-top: 6px;">
                        @csrf
                        @method('DELETE')
                        <button type="submit"
                            style="font-size: 0.8em; color: #dc2626; background: none; border: none; cursor: pointer; padding: 0;">
                            Delete
                        </button>
                    </form>
                @endif
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

Mari kita telusuri view ini section demi section agar Anda memahami bagaimana setiap bagian berkontribusi pada halaman. Component `<x-layout>` membungkus semuanya dalam layout halaman bersama dari course pemula sehingga Anda mewarisi navigation bar dan footer. Blok konten entri di bagian atas menampilkan judul entri dengan `{{ $entry->title }}`, menggunakan method `diffForHumans()` dari Carbon untuk menghasilkan timestamp relatif yang ramah seperti "3 hours ago", dan merender body entri.

Heading komentar menggunakan `$entry->comments->count()` untuk menampilkan berapa banyak komentar yang ada. Perhatikan bahwa `comments` di sini diakses sebagai property (tanpa tanda kurung) karena kita sudah memuat koleksinya dengan `$entry->load(...)`, sehingga `count()` tidak menjalankan query lagi. Directive `@forelse` adalah shortcut Blade yang menggabungkan `@foreach` dengan fallback `@empty`: ia mengulang komentar jika ada, jika tidak akan merender pesan "no comments yet". Di dalam loop, setiap komentar menampilkan nama penulis dari relationship `user` yang sudah di-eager-load dan timestamp relatif. Blok `@if (auth()->id() === $comment->user_id)` merender form **Delete** kecil hanya ketika user yang login menulis komentar tersebut, mengirim ke route `comments.destroy` melalui `@method('DELETE')`. Menyembunyikan tombol adalah kenyamanan UX; perlindungan sebenarnya adalah ownership guard `abort(403)` di method `destroy`, sehingga form tetap aman bahkan jika seseorang memalsukan sebuah request.

Form komentar menggunakan `method="POST"` dan `action="{{ route('comments.store', $entry) }}"` untuk mengirim ke route yang Anda definisikan, meneruskan entri saat ini sebagai route parameter. Directive `@csrf` menyisipkan hidden CSRF token yang dibutuhkan Laravel untuk semua form POST guna mencegah cross-site request forgery. Textarea menggunakan `{{ old('body') }}` sehingga jika validasi gagal, teks yang diketik user dipertahankan saat form dirender ulang. Blok `@error('body')` menampilkan pesan error validasi jika ada untuk field `body`.

---

## 6. Menjalankan dan Menguji

Sekarang mari kita verifikasi bahwa semuanya berfungsi dengan benar dengan menjalankan aplikasi dan menguji sistem komentar dari awal hingga akhir.

### Step 1: Menjalankan Development Server

Jalankan perintah berikut untuk memulai development server bawaan Laravel.

```bash
php artisan serve
```

Anda akan melihat output mirip dengan `INFO  Server running on [http://127.0.0.1:8000]`. Biarkan jendela terminal ini tetap terbuka; menutupnya akan menghentikan server.

### Step 2: Menguji di Browser

Buka `http://localhost:8000` di browser Anda dan login dengan akun Anda yang sudah ada. Navigasikan ke halaman detail entri mana pun dengan mengeklik judul entri dari listing utama. Anda akan melihat konten entri diikuti oleh section "Comments (0)" dan form komentar di bawahnya.

Ketik sebuah komentar di textarea (misalnya, "This is my first comment!") dan klik "Post Comment." Halaman akan dimuat ulang dan menampilkan komentar Anda dengan username Anda di sebelah kiri, timestamp relatif di sebelah kanan (seperti "1 second ago"), dan body komentar Anda di bawahnya. Jumlah komentar di heading juga akan diperbarui menjadi "Comments (1)".

### Step 3: Menguji Validasi

Coba kirim form komentar kosong tanpa mengetik apa pun. Anda akan melihat pesan error merah di bawah textarea yang berbunyi "The body field is required." Ini mengonfirmasi bahwa validasi berfungsi dengan benar. Sekarang coba kirim satu karakter saja seperti "a". Anda akan melihat "The body field must be at least 2 characters." Pesan-pesan ini berasal langsung dari aturan `required|string|min:2|max:1000` yang Anda tulis di controller.

### Step 4: Memverifikasi Beberapa Comment

Kirim dua atau tiga komentar lagi pada entri yang sama. Setiap komentar baru akan muncul di daftar dalam urutan kronologis, dan jumlah komentar di heading akan diperbarui setiap kali (misalnya, "Comments (3)"). Coba logout, login sebagai user yang berbeda, dan berkomentar sebagai user tersebut; komentar baru akan menampilkan username yang benar untuk setiap penulis.

### Step 5: Menguji di Tinker (Opsional)

Tinker adalah REPL yang memungkinkan Anda berinteraksi dengan kode aplikasi Anda langsung dari command line. Ia sangat berguna untuk debugging dan mengeksplorasi relationship. Buka terminal baru dan jalankan perintah berikut untuk meluncurkannya.

```bash
php artisan tinker
```

Setelah berada di dalam Tinker, Anda dapat menjalankan kode PHP apa pun terhadap aplikasi Anda. Coba perintah berikut satu per satu untuk mengeksplorasi relationship yang Anda bangun.

```php
$entry = \App\Models\Entry::first();
$entry->comments->count();
$entry->comments->first()->user->name;

$user = \App\Models\User::first();
$user->entries->count();
$user->entries->flatMap->comments->count();
```

Baris pertama mengambil entri pertama dari database. Baris kedua menghitung komentar pada entri tersebut menggunakan koleksi yang sudah di-eager-load. Baris ketiga menelusuri dua tingkat relationship untuk mengambil nama penulis komentar. Baris keempat beralih ke model User dan menghitung berapa banyak entri yang ditulis user tersebut. Baris kelima adalah yang paling lanjut: `flatMap->comments` mengambil koleksi entri, mendapatkan komentar untuk masing-masing, dan meratakannya semua ke dalam satu koleksi sehingga Anda dapat menghitung totalnya. Ketik `exit` untuk keluar dari Tinker setelah Anda selesai.

---

## 7. Memperbaiki Error pada Kode Anda

Berikut adalah kesalahan paling umum saat bekerja dengan relationship one-to-many. Memahaminya sekarang akan menghemat berjam-jam debugging nanti.

**Error 1: Kolom foreign key hilang di migration.**

Error ini terjadi ketika Anda mendefinisikan relationship `belongsTo` di model tetapi lupa menambahkan kolom foreign key yang sesuai di migration. Eloquent tidak dapat menghubungkan komentar ke entri jika kolom `entry_id` tidak ada pada tabel `comments`.

```php
// Wrong: entry_id column is missing from the schema
Schema::create('comments', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->text('body');
    $table->timestamps();
});

// Correct: both foreign keys are present
Schema::create('comments', function (Blueprint $table) {
    $table->id();
    $table->foreignId('entry_id')->constrained()->cascadeOnDelete();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->text('body');
    $table->timestamps();
});
```

Versi yang salah mendefinisikan `user_id` tetapi menghilangkan `entry_id`, sehingga Eloquent tidak memiliki kolom untuk di-join saat Anda memanggil `$entry->comments`. Versi yang benar menyertakan kedua foreign key. Selalu periksa bahwa setiap sisi sebuah relationship memiliki kolom yang tepat sebelum menjalankan migration.

---

**Error 2: Mengakses relationship sebagai method, bukan sebagai property.**

Kebingungan ini sangat umum ketika Anda sedang mempelajari relationship. Memanggil method dengan tanda kurung dan tanpa tanda kurung mengembalikan dua hal yang sama sekali berbeda, dan menggunakan bentuk yang salah dalam konteks yang salah menghasilkan hasil yang tidak terduga.

```php
// Wrong: method call returns a query builder, not a collection
$comments = $entry->comments();

// Correct: property access returns the collection of Comment models
$comments = $entry->comments;
```

`$entry->comments` (tanpa tanda kurung) mengembalikan sebuah Collection berisi model Comment yang dapat Anda ulang di Blade view. `$entry->comments()` (dengan tanda kurung) mengembalikan sebuah instance query builder `HasMany`. Anda menggunakan bentuk method hanya ketika Anda perlu merantai constraint query tambahan, misalnya: `$entry->comments()->where('body', 'like', '%hello%')->get()`. Di view, Anda hampir selalu menginginkan bentuk property.

---

**Error 3: Lupa `#[Fillable]` saat membuat record terkait.**

Method `create()` menggunakan fitur mass assignment Laravel. Jika Anda tidak mendeklarasikan field apa pun sebagai fillable, Laravel melemparkan `MassAssignmentException` bahkan jika nilai yang Anda coba simpan sebenarnya valid.

```php
// Wrong: no #[Fillable] attribute defined on the Comment model
class Comment extends Model
{
}

// Correct: declare the fields that may be mass assigned
#[Fillable(['body', 'user_id'])]
class Comment extends Model
{
}
```

Tanpa `#[Fillable]`, memanggil `$entry->comments()->create(['body' => 'Hello', 'user_id' => 1])` melemparkan `MassAssignmentException: Add [body] to fillable property to allow mass assignment`. Versi yang benar menggunakan attribute `#[Fillable(['body', 'user_id'])]`. `entry_id` sengaja dikecualikan karena method relationship `$entry->comments()->create(...)` mengisinya secara otomatis. `user_id` disertakan karena controller meneruskannya secara eksplisit melalui `create()`, selalu mengambil nilainya dari `$request->user()->id` alih-alih dari input request.

---

## 8. Latihan

**Latihan 1:** Tambahkan relationship `hasMany` dari User ke Comment sehingga Anda dapat mengakses semua komentar yang ditulis oleh seorang user dengan `$user->comments`. Uji di Tinker dengan memanggil `User::first()->comments->count()`.

**Latihan 2:** Tampilkan badge jumlah komentar di samping setiap entri di feed (halaman index). Di controller, gunakan `Entry::withCount('comments')->latest()->get()` untuk memuat entri dengan attribute `comments_count`. Tampilkan di view dengan `{{ $entry->comments_count }} comments`.

**Latihan 3:** Tampilkan pratinjau komentar terbaru dari setiap entri di feed (halaman index). Tambahkan relationship `latestComment` ke model `Entry` menggunakan `hasOne(Comment::class)->latestOfMany()`, lakukan eager load di controller, dan tampilkan body serta penulis komentar terbaru di bawah setiap entri. (Penghapusan komentar sudah dibangun di lesson utama, jadi latihan ini melatih tool one-to-many yang berbeda: mengubah `hasMany` menjadi satu record "terbaru".)

---

## 9. Solusi

**Solusi untuk Latihan 1:**

Buka `app/Models/User.php` dan tambahkan method berikut di dalam body class.

```php
public function comments(): HasMany
{
    return $this->hasMany(Comment::class);
}
```

Method ini memberi tahu Eloquent bahwa seorang user dapat memiliki banyak komentar. Eloquent mencari kolom `user_id` pada tabel `comments`, yang sudah ada dari migration yang Anda jalankan sebelumnya. Setelah method tersebut ada, uji di Tinker dengan menjalankan perintah di bawah ini.

```php
\App\Models\User::first()->comments->count();
```

Baris ini mengambil user pertama, mengakses relationship `comments` sebagai property (yang memicu sebuah query), dan menghitung koleksi yang dihasilkan. Outputnya adalah jumlah total komentar yang telah dikirim user tersebut.

---

**Solusi untuk Latihan 2:**

Di method index `EntryController`, ganti query yang ada dengan berikut.

```php
$entries = Entry::withCount('comments')->latest()->get();
```

Method `withCount('comments')` menambahkan attribute `comments_count` ke setiap model Entry tanpa memuat semua record komentar. Di balik layar, Laravel menjalankan subquery `SELECT COUNT(*)`, yang jauh lebih efisien daripada memuat setiap record komentar hanya untuk memanggil `count()` pada koleksi. Di Blade view, tampilkan jumlah tersebut di samping setiap entri.

```blade
<span style="color: #888; font-size: 0.85em;">{{ $entry->comments_count }} comments</span>
```

Ekspresi ini membaca virtual attribute `comments_count` yang disuntikkan `withCount` ke model. Tidak ada query tambahan yang dijalankan saat view mengaksesnya.

---

**Solusi untuk Latihan 3:**

Buka `app/Models/Entry.php` dan tambahkan relationship `latestComment` di dalam body class.

```php
use Illuminate\Database\Eloquent\Relations\HasOne;

public function latestComment(): HasOne
{
    return $this->hasOne(Comment::class)->latestOfMany();
}
```

`hasOne(Comment::class)->latestOfMany()` adalah varian one-to-one dari relationship `hasMany`: dari semua komentar milik sebuah entri, ia meresolusi ke satu komentar yang paling baru (berdasarkan primary key, atau berdasarkan kolom yang Anda teruskan ke `latestOfMany()`). Ini adalah cara idiomatik untuk mengambil "record terkait terbaru" tanpa memuat seluruh koleksi. Lakukan eager load pada method index `EntryController` sehingga view tidak menjalankan satu query per entri.

```php
$entries = Entry::with('latestComment.user')->latest()->get();
```

`latestComment.user` yang bertitik memuat lebih dulu komentar terbaru dan penulisnya sekaligus. Di entry card (atau view index), tampilkan pratinjau hanya ketika sebuah komentar ada.

```blade
@if ($entry->latestComment)
    <p style="color: #6b7280; font-size: 0.85em; margin-top: 6px;">
        Latest: "{{ $entry->latestComment->body }}" — {{ $entry->latestComment->user->name }}
    </p>
@endif
```

Karena `latestComment` adalah `hasOne`, `$entry->latestComment` adalah satu model `Comment` (atau `null` ketika tidak ada komentar), sehingga guard `@if` mencegah error "property on null" pada entri tanpa komentar.

---

## Selanjutnya - Lesson 2

Di lesson ini Anda membangun fondasi data relasional di Laravel. Anda membuat migration dengan foreign key constraint, mendefinisikan method `hasMany` dan `belongsTo` pada model Eloquent Anda, dan menggunakan relationship tersebut untuk membuat komentar melalui `$entry->comments()->create()`. Anda menambahkan method `destroy` sehingga penulis sebuah komentar dapat menghapusnya, dijaga oleh pemeriksaan ownership manual `abort(403)` (yang akan ditingkatkan Lesson 5 menjadi Policy). Anda juga mempelajari perbedaan antara mengakses relationship sebagai property (untuk mendapatkan Collection) dan sebagai method (untuk mendapatkan query builder), dan Anda melindungi aplikasi Anda dengan pembatasan mass assignment dan authorization berbasis authentication di controller.

Di Lesson 2, Anda akan mempelajari relationship many-to-many: menambahkan tag ke entri menggunakan pivot table, dan menggunakan method `attach`, `detach`, dan `sync` untuk mengelola tag mana yang dimiliki oleh entri mana.
