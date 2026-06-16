## 1. Sebelum Anda Memulai

Di course pemula, entri Catatku bersifat privat: setiap user hanya melihat entri mereka sendiri. Tetapi apa yang terjadi jika seseorang mengetik `/entries/42/edit` secara manual di browser, di mana entri 42 milik user lain? Tanpa authorization, mereka dapat melihat atau memodifikasi entri jurnal milik orang lain. Authentication menjawab "siapa Anda?" Authorization menjawab "apa yang boleh Anda lakukan?" Lesson ini menutup celah keamanan tersebut.

Laravel menyediakan dua tool untuk authorization: Gate untuk pemeriksaan sederhana berbasis closure (seperti "apakah user ini admin?") dan Policy untuk aturan spesifik model (seperti "dapatkah user ini mengedit entri ini?"). Policy adalah pendekatan standar untuk authorization CRUD dan terintegrasi dengan rapi dengan controller dan Blade view. Di akhir lesson ini, Catatku akan dengan benar menolak upaya User B untuk membaca atau memodifikasi entri User A, tidak peduli bagaimana upaya tersebut dilakukan.

### What You'll Build

Anda akan membuat sebuah `EntryPolicy` yang membatasi melihat, mengedit, dan menghapus entri hanya untuk pemilik entri. Anda juga akan menambahkan admin bypass menggunakan `Gate::before()`.

### What You'll Learn

- ✅ Membuat Policy dengan `make:policy`
- ✅ Method Policy: `view`, `update`, `delete`
- ✅ Menggunakan `$this->authorize()` di controller
- ✅ Menggunakan `@can` dan `@cannot` di Blade view
- ✅ Gate untuk pemeriksaan authorization sederhana
- ✅ Admin bypass dengan `Gate::before()`

### What You'll Need

- Lesson 4 sudah selesai

---

## 2. Membuat Policy Entry

Sebuah Policy mengelompokkan logika authorization untuk model tertentu. Laravel menemukan policy secara otomatis ketika mereka mengikuti konvensi penamaan: `EntryPolicy` untuk model `Entry`. Konvensi penamaan ini serupa dengan bagaimana migration, controller, dan factory mengikuti pola penamaan yang dapat diprediksi untuk mengurangi konfigurasi.

### Step 1: Membuat Policy

Jalankan perintah Artisan berikut untuk membuat file policy dengan signature method yang sudah disiapkan.

```bash
php artisan make:policy EntryPolicy --model=Entry
```

Perintah ini membuat `app/Policies/EntryPolicy.php` dengan method kerangka untuk setiap aksi CRUD. Flag `--model=Entry` memberi tahu Artisan untuk menghasilkan signature method yang menerima model Entry sebagai parameter keduanya, menghemat Anda dari menulisnya secara manual.

### Step 2: Mendefinisikan Aturan Authorization

Buka `app/Policies/EntryPolicy.php` dan ganti kontennya dengan berikut.

```php
<?php

namespace App\Policies;

use App\Models\Entry;
use App\Models\User;

class EntryPolicy
{
    public function view(User $user, Entry $entry): bool
    {
        return $user->id === $entry->user_id;
    }

    public function update(User $user, Entry $entry): bool
    {
        return $user->id === $entry->user_id;
    }

    public function delete(User $user, Entry $entry): bool
    {
        return $user->id === $entry->user_id;
    }
}
```

Mari kita telusuri Policy ini dengan cermat. Deklarasi `namespace App\Policies;` cocok dengan struktur direktori. Statement `use` mengimpor dua class model sehingga keduanya dapat di-type-hint sebagai parameter. Class diberi nama `EntryPolicy` agar cocok dengan konvensi auto-discovery Laravel: Laravel mencari `{ModelName}Policy` di direktori `app/Policies` saat memeriksa izin untuk model tersebut. Setiap method menerima `User` yang terautentikasi sebagai parameter pertama dan `Entry` yang sedang diakses sebagai parameter kedua, dan mengembalikan `true` jika aksi diizinkan atau `false` jika harus ditolak.

Logikanya sama untuk ketiga aksi: bandingkan ID user dengan `user_id` entri. Jika keduanya cocok, user adalah pemiliknya dan aksi diizinkan. Karena Catatku adalah aplikasi jurnal privat, bahkan melihat pun dibatasi hanya untuk pemilik. Di aplikasi blog publik, Anda mungkin mengizinkan siapa saja untuk melihat tetapi membatasi pengeditan hanya untuk penulis.

> **Catatan:** Membatasi `view` hanya untuk pemilik juga berarti bahwa notifikasi komentar lintas-user yang Anda bangun di Lesson 8 (sebuah email ke penulis entri ketika *orang lain* berkomentar) belum dapat dijangkau melalui UI; tidak ada selain pemilik yang dapat membuka entri untuk berkomentar di dalamnya. Fitur itu baru menjadi user-facing setelah entri dapat dibagikan atau dijadikan publik. Jika nanti Anda melonggarkan aturan `view` ini untuk mengizinkan entri yang dibagikan, sistem komentar dan notifikasinya sudah berada di tempatnya.

### Step 3: Menerapkan di Controller

Buka `app/Http/Controllers/EntryController.php` dan perbarui method yang mengakses entri tertentu. Di Laravel 13, controller tidak lagi disertai helper `authorize()` secara default; gunakan `Gate::authorize()` dari facade `Gate` sebagai gantinya, yang berperilaku identik: ia melemparkan exception 403 Forbidden jika method Policy mengembalikan `false`. Tambahkan import `Gate` bersama statement `use` yang sudah ada. Pemanggilan ini juga menggantikan pemeriksaan manual `if ($entry->user_id !== auth()->id()) { abort(403); }` dari course dasar.

```php
<?php
// ... others lines of code
use Illuminate\Support\Facades\Gate;

class EntryController extends Controller
{
    // ... other methods

    public function show(Entry $entry)
    {
        Gate::authorize('view', $entry);

        $entry->load('comments.user', 'tags');

        return view('entries.show', compact('entry'));
    }

    public function edit(Entry $entry)
    {
        Gate::authorize('update', $entry);

        $tags = Tag::orderBy('name')->get();

        return view('entries.edit', compact('entry', 'tags'));
    }

    public function update(Request $request, Entry $entry)
    {
        Gate::authorize('update', $entry);

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

        return redirect()->route('entries.index')->with('success', 'Entry updated!');
    }

    public function destroy(Entry $entry)
    {
        Gate::authorize('delete', $entry);

        $entry->delete();

        return redirect()->route('entries.index')->with('success', 'Entry deleted.');
    }

    public function restore(Entry $entry)
    {
        Gate::authorize('update', $entry);

        $entry->restore();

        return redirect()->route('entries.trash')->with('success', 'Entry restored!');
    }

    // ... other methods
}
```

Memeriksa pola di setiap method: baris paling pertama dari setiap aksi yang menyentuh entri tertentu adalah `Gate::authorize('ability_name', $entry)`. Untuk `show`, kita melakukan authorize `view`; untuk `edit`, `update`, dan `restore`, kita melakukan authorize `update`; untuk `destroy`, kita melakukan authorize `delete`. Argumen pertama adalah nama ability sebagai string, yang harus cocok dengan nama method pada Policy. Argumen kedua adalah entri yang sedang diperiksa.

Jika method Policy mengembalikan `false`, Laravel secara otomatis melemparkan exception HTTP 403 Forbidden, merender halaman error 403 default, dan kode controller di bawah pemanggilan `Gate::authorize()` tidak pernah dijalankan. Anda tidak perlu menulis logika if/else atau melakukan redirect secara manual. Perhatikan bahwa kita menempatkan `Gate::authorize()` sebelum validasi dan sebelum pekerjaan lain apa pun, karena tidak ada gunanya memvalidasi atau memproses data yang tidak boleh disentuh user.

### Step 4: Menggunakan di Blade View

Buka `resources/views/components/entry-card.blade.php`. Di section tombol aksi, ganti tombol Edit dan Delete yang ada dengan versi yang dibungkus `@can` di bawah ini sehingga keduanya hanya ditampilkan kepada pemilik entri.

```blade
{{-- Action buttons --}}
<div class="flex items-center gap-3 pt-3 border-t border-gray-100">
    <a href="/entries/{{ $entry->id }}" class="text-xs text-blue-600 hover:text-blue-800">
        Read
    </a>
    @can('update', $entry)
    <a href="{{ route('entries.edit', $entry) }}" class="text-xs text-gray-500 hover:text-gray-800">
        Edit
    </a>
    @endcan
    @can('delete', $entry)
    <form method="POST" action="{{ route('entries.destroy', $entry) }}" onsubmit="return confirm('Delete this entry?')"
        class="ml-auto">
        @csrf
        @method('DELETE')
        <button type="submit" class="text-xs text-red-400 hover:text-red-600">
            Delete
        </button>
    </form>
    @endcan
</div>
```

Directive `@can('update', $entry)` merender HTML yang dilampirkan hanya jika user saat ini diizinkan menurut method `update` dari Policy. `@endcan` menutup blok. Ini menyembunyikan tombol yang tidak dapat digunakan user, yang meningkatkan pengalaman pengguna. Namun, menyembunyikan tombol saja tidak cukup untuk keamanan. User yang gigih dapat melakukan POST langsung ke endpoint delete menggunakan curl tanpa mengeklik tombol apa pun. Penegakan keamanan yang sebenarnya terjadi di pemanggilan `Gate::authorize()` controller. Selalu gunakan keduanya: `@can` untuk UX dan `Gate::authorize()` untuk keamanan.

Setelah perubahan, file `entry-card.blade.php` lengkap terlihat seperti ini:

```blade
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
        @can('update', $entry)
        <a href="{{ route('entries.edit', $entry) }}" class="text-xs text-gray-500 hover:text-gray-800">
            Edit
        </a>
        @endcan
        @can('delete', $entry)
        <form method="POST" action="{{ route('entries.destroy', $entry) }}" onsubmit="return confirm('Delete this entry?')"
            class="ml-auto">
            @csrf
            @method('DELETE')
            <button type="submit" class="text-xs text-red-400 hover:text-red-600">
                Delete
            </button>
        </form>
        @endcan
    </div>

</div>
```

### Step 5: Menerapkan Pola yang Sama untuk Comment

Entri bukan satu-satunya model yang memiliki pemilik. Di Lesson 1 Anda menambahkan method `destroy` ke `CommentController` yang menghapus sebuah komentar setelah pemeriksaan ownership manual. Sekarang setelah Anda memahami Policy, berikan komentar Policy mereka sendiri dan refactor method tersebut untuk menggunakannya; persis sama dengan upgrade yang baru saja Anda lakukan untuk entri.

Buat policy-nya:

```bash
php artisan make:policy CommentPolicy --model=Comment
```

Buka `app/Policies/CommentPolicy.php` dan ganti kontennya dengan satu aturan `delete`.

```php
<?php

namespace App\Policies;

use App\Models\Comment;
use App\Models\User;

class CommentPolicy
{
    public function delete(User $user, Comment $comment): bool
    {
        return $user->id === $comment->user_id;
    }
}
```

Lalu buka `app/Http/Controllers/CommentController.php` dan ganti pemeriksaan manual `if (...) abort(403)` di `destroy` dengan `Gate::authorize('delete', $comment)`. Tambahkan import facade `Gate` di bagian atas file.

```php
use Illuminate\Support\Facades\Gate;

public function destroy(Comment $comment)
{
    Gate::authorize('delete', $comment);

    $comment->delete();

    return back()->with('success', 'Comment deleted.');
}
```

Laravel menemukan `CommentPolicy` secara otomatis untuk model `Comment` dengan cara yang sama seperti `EntryPolicy`, sehingga `Gate::authorize('delete', $comment)` memanggil `CommentPolicy::delete()` dan melemparkan 403 ketika user yang terautentikasi bukan penulis komentar. Perilakunya identik dengan pemeriksaan manual dari Lesson 1, tetapi aturan authorization sekarang berada di satu tempat yang dapat digunakan kembali; dan directive `@can('delete', $comment)` menjadi tersedia untuk menyembunyikan tombol Delete komentar juga, persis seperti tombol entri di atas.

---

## 3. Gate untuk Admin Bypass

Gate lebih sederhana daripada Policy. Mereka adalah closure yang didefinisikan di sebuah service provider alih-alih class khusus. Method `Gate::before()` berjalan sebelum setiap pemeriksaan Policy dan dapat menimpa hasilnya, yang persis kita butuhkan untuk user admin yang seharusnya dapat melakukan aksi apa pun.

### Step 1: Menambahkan Admin Bypass

Buka `app/Providers/AppServiceProvider.php` dan tambahkan pemanggilan `Gate::before()` di dalam method `boot()` dari class `AppServiceProvider`.

```php
<?php
// ... others lines of code
use Illuminate\Support\Facades\Gate;

class AppServiceProvider extends ServiceProvider
{
    // ... other methods

    public function boot(): void
    {
        Gate::before(function ($user) {
            if ($user->email === 'admin@example.com') {
                return true;
            }
        });
    }
}
```

Memeriksa snippet ini: `Gate::before()` mendaftarkan sebuah closure yang berjalan sebelum setiap pemeriksaan Policy di seluruh aplikasi. Closure menerima user yang terautentikasi. Jika email user cocok dengan nilai admin, kita mengembalikan `true`, yang memotong semua pemeriksaan Policy dan mengizinkan aksi. Jika kondisinya false, closure tidak mengembalikan apa-apa (PHP secara implisit mengembalikan `null`), dan Laravel kemudian melanjutkan dengan pemeriksaan Policy normal. Ini berarti user admin dapat melihat, mengedit, dan menghapus entri apa pun tanpa Policy perlu mengetahui tentang admin. Di production, Anda akan menggunakan kolom database seperti `is_admin` alih-alih memeriksa email, tetapi polanya identik.

---

## 4. Menjalankan dan Menguji

Mari kita verifikasi bahwa authorization berfungsi dengan benar baik dari browser maupun Tinker.

### Step 1: Menguji sebagai Pemilik

Jalankan server dan login dengan akun Anda yang sudah ada.

```bash
php artisan serve
```

Navigasikan ke salah satu entri Anda. Anda akan melihat tombol Edit dan Delete karena method `update` dan `delete` dari Policy mengembalikan `true` untuk pemilik. Klik Edit untuk memverifikasi Anda dapat mengakses form edit. Klik Delete untuk memverifikasi entri berhasil di-soft-delete.

### Step 2: Menguji Kegagalan Authorization

Cara termudah untuk menguji penolakan adalah melalui Tinker. Buat user kedua dan periksa hasil authorization secara programatik.

```bash
php artisan tinker
```

Jalankan perintah berikut satu per satu untuk membandingkan bagaimana user yang berbeda dievaluasi terhadap policy yang sama.

```php
$user2 = \App\Models\User::factory()->create([
    'email' => 'test2@example.com',
    'password' => bcrypt('password'),
]);

$entry = \App\Models\Entry::first();

$user2->can('update', $entry);

$entry->user->can('update', $entry);
```

`$user2->can('update', $entry)` mengevaluasi method `update` dari Policy dengan user kedua dan entri, mengembalikan `false` karena ID-nya tidak cocok. `$entry->user->can('update', $entry)` melakukan pemeriksaan yang sama untuk pemilik entri yang sebenarnya, mengembalikan `true`. Method `can` pada model User adalah padanan programatik dari directive Blade `@can`, dan Anda dapat menggunakannya di mana pun Anda perlu memeriksa izin di luar controller. Ketik `exit` untuk keluar dari Tinker.

### Step 3: Menguji di Browser

Logout, lalu login sebagai user kedua yang baru Anda buat. Sekarang navigasikan secara manual ke `/entries/{id}/edit` di mana `{id}` adalah entri milik user pertama. Anda seharusnya melihat halaman error 403 Forbidden alih-alih form edit, mengonfirmasi bahwa controller memblokir akses tidak sah bahkan ketika UI tidak menautkan ke halaman tersebut.

### Step 4: Menguji Admin Bypass (Opsional)

Buat user dengan email `admin@example.com`, login sebagai mereka, dan coba mengedit entri user lain. Karena `Gate::before()` mengembalikan `true` untuk email ini, Anda seharusnya dapat mengakses form edit. Ini membuktikan override admin berfungsi sambil membiarkan user normal tetap dibatasi dengan tepat.

---

## 5. Memperbaiki Error pada Kode Anda

Berikut adalah kesalahan paling umum saat mengimplementasikan authorization dengan Gate dan Policy di Laravel.

**Error 1: Memanggil `authorize()` tanpa meneruskan instance model.**

Error ini terjadi ketika Anda memanggil `$this->authorize()` hanya dengan nama ability tetapi lupa meneruskan instance model. Laravel membutuhkan model untuk memanggil method Policy yang benar dengan argumen yang tepat.

```php
// Wrong: no entry passed, Laravel cannot call the Policy method
$this->authorize('update');

// Correct: pass the entry so the Policy receives it as the second argument
$this->authorize('update', $entry);
```

Tanpa argumen kedua, Laravel tidak tahu entri mana yang harus diperiksa authorization-nya. Method `update(User $user, Entry $entry)` dari Policy mengharapkan sebuah entri, sehingga pemanggilan gagal dengan error tentang argumen yang hilang. Versi yang benar meneruskan `$entry`, memberikan Policy segala yang dibutuhkannya untuk membandingkan ID user.

---

**Error 2: Class Policy dinamai dengan salah, merusak auto-discovery.**

Error ini terjadi ketika Anda memberi nama class Policy selain `{ModelName}Policy`. Mekanisme auto-discovery Laravel mencari pola yang persis ini, sehingga class dengan nama berbeda tidak pernah ditemukan secara otomatis.

```php
// Wrong: class named EntryAuth instead of EntryPolicy
// Laravel looks for EntryPolicy, not EntryAuth
class EntryAuth
{
    public function update(User $user, Entry $entry): bool
    {
        return $user->id === $entry->user_id;
    }
}

// Correct: follows the ModelNamePolicy naming convention
class EntryPolicy
{
    public function update(User $user, Entry $entry): bool
    {
        return $user->id === $entry->user_id;
    }
}
```

Versi yang salah menggunakan `EntryAuth`, yang tidak dapat ditemukan Laravel secara otomatis. Setiap pemanggilan `authorize('update', $entry)` lolos tanpa mengenai policy apa pun, dan hasilnya entah selalu diizinkan atau selalu ditolak tergantung konfigurasi Anda. Versi yang benar menggunakan `EntryPolicy`, yang ditemukan Laravel secara otomatis. Jika Anda harus menggunakan nama kustom, daftarkan pemetaannya secara manual di `AppServiceProvider::boot()` menggunakan `Gate::policy(Entry::class, EntryAuth::class)`.

---

**Error 3: Method Policy mengembalikan void alih-alih bool.**

Error ini terjadi ketika seorang developer menulis method policy untuk memanggil `abort(403)` secara langsung alih-alih mengembalikan sebuah boolean. Method Policy harus mengembalikan `bool`; jika method mengembalikan `void` atau `null`, pemeriksaan authorization selalu gagal atau menghasilkan perilaku yang tidak terduga.

```php
// Wrong: calling abort() inside a policy method bypasses the framework's response flow
public function update(User $user, Entry $entry): void
{
    if ($user->id !== $entry->user_id) {
        abort(403);
    }
}

// Correct: return bool and let authorize() handle the 403 response
public function update(User $user, Entry $entry): bool
{
    return $user->id === $entry->user_id;
}
```

Versi yang salah menggunakan `void` sebagai return type dan memanggil `abort(403)` di dalam policy. Meskipun ini dapat bekerja dalam beberapa kasus, ia melewati alur authorization yang bersih dari framework: policy seharusnya mengembalikan sebuah keputusan, bukan menghasilkan sebuah respons. Versi yang benar mengembalikan `true` atau `false`, dan `$this->authorize()` di controller bertanggung jawab untuk melemparkan exception 403 ketika ia menerima `false`.

---

## 6. Latihan

Berlatihlah menerapkan pola authorization dari lesson ini ke bagian Catatku yang belum dilindungi. Setiap latihan mengembangkan apa yang Anda bangun tanpa memerlukan perubahan pada logika policy inti yang sudah Anda tulis.

**Latihan 1:** Di Lesson 1 tombol Delete komentar di `entries/show.blade.php` dibungkus dalam `@if (auth()->id() === $comment->user_id)`. Sekarang setelah `CommentPolicy` ada (ditambahkan di lesson utama di atas), refactor kondisi view tersebut untuk menggunakan directive `@can('delete', $comment)` sebagai gantinya, sehingga visibilitas tombol digerakkan oleh Policy yang sama yang ditegakkan controller.

**Latihan 2:** Tambahkan kolom boolean `is_admin` ke tabel users. Perbarui pemeriksaan `Gate::before()` untuk menggunakan kolom ini alih-alih perbandingan email.

**Latihan 3:** Tambahkan method `viewAny` ke `EntryPolicy` yang selalu mengembalikan `true` (semua orang dapat melihat daftar entri). Gunakan `$this->authorize('viewAny', Entry::class)` di method index (catatan: argumen kedua adalah class, bukan instance).

---

## 7. Solusi

Setiap solusi di bawah ini lengkap dan dapat langsung diterapkan ke proyek Catatku Anda. Baca narasi setelah setiap blok kode untuk memahami bagaimana bagian-bagiannya terhubung sebelum melanjutkan ke latihan berikutnya.

**Solusi untuk Latihan 1:**

Buka `resources/views/entries/show.blade.php` dan temukan form Delete komentar yang Anda tambahkan di Lesson 1. Ganti pemeriksaan ownership mentah `@if` dengan directive `@can`.

```blade
{{-- Before (Lesson 1): manual ownership check --}}
@if (auth()->id() === $comment->user_id)
    <form method="POST" action="{{ route('comments.destroy', $comment) }}"
          onsubmit="return confirm('Delete this comment?')" style="margin-top: 6px;">
        @csrf
        @method('DELETE')
        <button type="submit" style="font-size: 0.8em; color: #dc2626; background: none; border: none; cursor: pointer; padding: 0;">
            Delete
        </button>
    </form>
@endif

{{-- After: driven by CommentPolicy --}}
@can('delete', $comment)
    <form method="POST" action="{{ route('comments.destroy', $comment) }}"
          onsubmit="return confirm('Delete this comment?')" style="margin-top: 6px;">
        @csrf
        @method('DELETE')
        <button type="submit" style="font-size: 0.8em; color: #dc2626; background: none; border: none; cursor: pointer; padding: 0;">
            Delete
        </button>
    </form>
@endcan
```

`@can('delete', $comment)` menanyakan kepada `CommentPolicy::delete()` apakah user saat ini boleh menghapus komentar ini, mengembalikan jawaban yang sama yang ditegakkan `Gate::authorize('delete', $comment)` di controller. Mengarahkan visibilitas tombol melalui Policy menjaga UI dan server tetap selaras: jika suatu saat Anda mengubah aturan penghapusan (misalnya, juga mengizinkan pemilik entri menghapus komentar pada entrinya), Anda mengedit Policy sekali dan baik tombol maupun controller mengikuti. Seperti biasa, `@can` hanyalah kenyamanan UX; `Gate::authorize()` di controller adalah perlindungan yang sebenarnya.

---

**Solusi untuk Latihan 2:**

Buat dan jalankan sebuah migration untuk menambahkan kolom `is_admin` ke tabel users.

```bash
php artisan make:migration add_is_admin_to_users --table=users
```

Di file migration, tambahkan definisi kolom.

```php
public function up(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->boolean('is_admin')->default(false);
    });
}

public function down(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->dropColumn('is_admin');
    });
}
```

Jalankan migration, lalu perbarui `AppServiceProvider::boot()` untuk menggunakan kolom database alih-alih perbandingan email.

```php
Gate::before(function ($user) {
    if ($user->is_admin) {
        return true;
    }
});
```

Ekspresi `$user->is_admin` membaca kolom boolean langsung dari model. Pendekatan ini lebih mudah dipelihara daripada perbandingan email karena Anda dapat memberikan atau mencabut status admin melalui database tanpa melakukan deploy ulang kode.

---

**Solusi untuk Latihan 3:**

Buka `app/Policies/EntryPolicy.php` dan tambahkan method `viewAny` di dalam body class.

```php
public function viewAny(User $user): bool
{
    return true;
}
```

Tidak seperti `view`, `update`, dan `delete`, method `viewAny` hanya menerima user yang terautentikasi dan tidak ada instance model. Ini karena aksi tersebut menargetkan daftar secara keseluruhan, bukan entri tunggal mana pun. Mengembalikan `true` tanpa syarat berarti setiap user yang terautentikasi boleh mengakses index entri. Di `app/Http/Controllers/EntryController.php`, tambahkan `Gate::authorize()` sebagai baris pertama dari method `index` di class `EntryController`.

```php
<?php
// ... others lines of code
use Illuminate\Support\Facades\Gate;

class EntryController extends Controller
{
    // ... other methods

    public function index(Request $request)
    {
        Gate::authorize('viewAny', Entry::class);

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

Perhatikan bahwa argumen kedua untuk `Gate::authorize()` adalah `Entry::class`, nama class sebagai string, alih-alih instance model. Laravel menggunakan ini untuk menemukan policy yang tepat (`EntryPolicy`) dan memanggil method `viewAny`-nya. Meneruskan sebuah class alih-alih instance diperlukan setiap kali aksi tidak melibatkan record tertentu. Jika nanti Anda ingin membatasi listing hanya untuk user admin, Anda dapat mengubah nilai return menjadi `return $user->is_admin;` tanpa menyentuh controller.

---

## Selanjutnya - Lesson 6

Di lesson ini Anda menambahkan lapisan authorization lengkap ke Catatku menggunakan sistem Policy Laravel. Anda membuat `EntryPolicy` dengan method `view`, `update`, dan `delete` yang masing-masing membandingkan ID user yang terautentikasi dengan `user_id` entri. Anda menerapkan `$this->authorize()` di setiap method controller yang mengakses entri tertentu, memastikan bahwa request tidak sah ditolak dengan respons 403 terlepas dari bagaimana mereka tiba. Anda menggunakan directive Blade `@can` untuk menyembunyikan kontrol UI bagi user yang tidak berwenang, dan Anda menambahkan callback `Gate::before()` untuk memberi user admin sebuah bypass di seluruh policy.

Di Lesson 6, Anda akan mempelajari middleware dan proteksi route: bagaimana membuat custom middleware, bagaimana mengorganisasi route ke dalam group middleware, dan bagaimana menerapkan rate limiting untuk mencegah penyalahgunaan.
