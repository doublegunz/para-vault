Pada lesson sebelumnya, kita membuat tabel `entries` di database. Namun sebuah tabel yang hanya duduk diam di database tidak banyak artinya jika kita tidak tahu cara berkomunikasi dengannya dari kode PHP kita. Lesson ini menjawab pertanyaan tersebut, dan jawabannya disebut **Eloquent**.

## Ikhtisar {#overview}

### What You'll Build

Di akhir lesson ini, controller tidak akan lagi menggunakan array hardcoded. Sebagai gantinya, controller akan melakukan query ke database secara langsung menggunakan Eloquent. View akan diperbarui agar bekerja dengan objek Eloquent, dan akan menangani dengan baik kondisi ketika belum ada entry sama sekali. Anda juga akan memiliki model `Entry` yang sudah dikonfigurasi sepenuhnya dengan mass assignment protection, relationship yang terdefinisi ke model `User`, dan beberapa seed data agar Anda dapat melihat entry sungguhan di browser.

### What You'll Learn

- Apa itu Eloquent ORM dan mengapa Eloquent membuat interaksi database jauh lebih bersih dibandingkan SQL mentah
- Cara mengonfigurasi model `Entry` menggunakan attribute `#[Fillable]` dari Laravel 13
- Apa itu mass assignment protection dan mengapa hal ini penting untuk keamanan
- Cara mendefinisikan relationship antar model (`belongsTo` dan `hasMany`)
- Cara memperbarui controller agar mengambil data sungguhan dari database
- Cara memperbarui view agar bekerja dengan objek Eloquent, bukan array
- Perbedaan antara `@foreach` dan `@forelse` di Blade
- Cara memasukkan seed data menggunakan Artisan Tinker untuk pengujian

### What You'll Need

- Project `catatku` terbuka di VS Code dengan development server berjalan
- Tabel `entries` sudah dibuat di database dari Lesson 5
- Anda dapat memverifikasinya dengan membuka HeidiSQL dari Laragon dan memeriksa bahwa tabel `entries` ada di `db_catatku`

---

## Step 1: Memahami Entry Model {#step-1-understand-the-entry-model}

Pada lesson sebelumnya, Artisan membuat file `app/Models/Entry.php` saat kita menjalankan `php artisan make:model Entry -m`. Buka file tersebut:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Entry extends Model
{
    //
}
```

Ini adalah model Eloquent yang kosong. Bahkan dalam kondisi ini, model sudah mengetahui cukup banyak hal. Karena class ini bernama `Entry`, Eloquent secara otomatis memetakannya ke tabel `entries` di database. Karena class ini extends `Model`, ia mewarisi semua query method milik Eloquent, penanganan timestamp, dan kemampuan relationship. Namun kita perlu menambahkan beberapa hal lagi agar model ini benar-benar berguna.

---

## Step 2: Konfigurasi Entry Model {#step-2-configure-the-entry-model}

Perbarui `app/Models/Entry.php` dengan mass assignment protection dan sebuah relationship:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['title', 'content'])]
class Entry extends Model
{
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

Ada dua penambahan penting di sini. Mari kita bahas satu per satu.

### Attribute `#[Fillable]` {#the-fillable-attribute}

Baris `#[Fillable(['title', 'content'])]` di bagian atas class menggunakan PHP attribute untuk mendeklarasikan kolom mana saja yang diizinkan untuk diisi melalui mass assignment. Laravel 13 memperkenalkan pendekatan ini sebagai cara modern untuk mendefinisikan fillable field. Jika Anda pernah melihat tutorial Laravel yang lebih lama, mereka menggunakan `protected $fillable = [...]` sebagai property di dalam class. Attribute `#[Fillable]` mencapai hasil yang sama dengan sintaks yang lebih bersih dan lebih deklaratif.

Jika Anda melihat model `User` default di `app/Models/User.php`, Anda akan melihat bahwa Laravel 13 sudah menggunakan pola yang sama:

```php
#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    // ...
}
```

Ini adalah pendekatan standar di Laravel 13. Attribute menjaga konfigurasi model tetap terlihat sekilas, tepat di bagian atas class, alih-alih terkubur di antara property dan method.

### Relationship `belongsTo` {#the-belongsto-relationship}

Method `user()` mendefinisikan bahwa setiap entry dimiliki oleh satu user. Ini berkaitan dengan kolom foreign key `user_id` yang kita tambahkan ke tabel `entries` pada Lesson 5. Ketika Anda memanggil `$entry->user`, Eloquent secara otomatis menjalankan query untuk mengambil record `User` yang terkait. Kita akan menggunakan relationship ini nanti saat membangun fungsi store, di mana entry akan dibuat melalui relationship milik user yang sedang login.

---

## Step 3: Tambahkan Reverse Relationship ke User {#step-3-add-the-reverse-relationship-to-user}

Relationship bekerja dalam dua arah. Kita sudah mendefinisikan bahwa sebuah entry dimiliki oleh seorang user, tetapi kita juga perlu memberi tahu model `User` bahwa seorang user dapat memiliki banyak entry.

Buka `app/Models/User.php` dan tambahkan method `entries()`:

```php
use Illuminate\Database\Eloquent\Relations\HasMany;

// Inside the User class, add this method:
public function entries(): HasMany
{
    return $this->hasMany(Entry::class);
}
```

Jadi, kode lengkap untuk class model User adalah sebagai berikut:
```php
<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Database\Eloquent\Relations\HasMany; // add this lines of code


#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    // add this lines of code
    public function entries(): HasMany
    {
        return $this->hasMany(Entry::class);
    }
}

```

Dengan kedua sisi relationship sudah terdefinisi, Anda dapat bernavigasi ke arah mana pun:

Dari sebuah entry ke pemiliknya: `$entry->user->name`

Dari seorang user ke semua entry miliknya: `$user->entries()->get()`

Relationship dua arah ini akan menjadi sangat penting pada lesson-lesson berikutnya. Ketika kita membangun fungsi store, kita akan membuat entry melalui relationship user: `$request->user()->entries()->create($validated)`. Ini secara otomatis mengisi kolom `user_id` tanpa kita perlu menentukannya secara manual, yang sekaligus praktis dan aman.

---

## Step 4: Perbarui Controller {#step-4-update-the-controller}

Sekarang mari kita ganti array hardcoded di `EntryController` dengan query database sungguhan. Buka `app/Http/Controllers/EntryController.php` dan perbarui method `index()`.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Entry; // add this line of code
use Illuminate\Http\Request;

class EntryController extends Controller
{
    public function index()
    {
        $entries = Entry::with('user')->latest()->get();

        return view('entries.index', compact('entries'));
    }
}
```

Mari kita uraikan query `Entry::with('user')->latest()->get()`:

`Entry::` memulai query pada tabel `entries` melalui model Eloquent.

`with('user')` memberi tahu Eloquent untuk eager load record `User` yang terkait untuk setiap entry. Tanpa ini, mengakses `$entry->user` di view akan memicu query database terpisah untuk setiap entry (dikenal sebagai "N+1 problem"). Dengan `with('user')`, Eloquent mengambil semua user terkait dalam satu query tambahan, berapa pun jumlah entry yang ada.

`latest()` mengurutkan hasil berdasarkan `created_at` secara descending (terbaru lebih dulu). Ini adalah shortcut untuk `orderBy('created_at', 'desc')`.

`get()` mengeksekusi query dan mengembalikan hasilnya sebagai Eloquent Collection.

Perhatikan bahwa kita mengambil semua entry dari database, bukan hanya entry milik user tertentu. Ini memang disengaja untuk saat ini. Sistem authentication belum ada, sehingga memanggil `auth()->user()` akan membuat aplikasi crash. Setelah kita membangun authentication pada Lesson 11, kita akan memperbarui query ini menjadi `auth()->user()->entries()->latest()->get()` agar setiap user hanya melihat entry miliknya sendiri.

---

## Step 5: Perbarui View {#step-5-update-the-view}

Data yang diterima view sekarang adalah collection objek Eloquent, bukan array. Sintaks untuk mengakses property berubah dari notasi bracket (`$entry['title']`) menjadi notasi arrow (`$entry->title`).

Perbarui `resources/views/entries/index.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Entries — Catatku</title>
    <script src="https://unpkg.com/@tailwindcss/browser@4"></script>
</head>
<body class="bg-gray-50">

    <nav class="bg-white border-b border-gray-200 px-6 py-4">
        <h1 class="text-xl font-bold text-gray-900">Catatku 📓</h1>
    </nav>

    <div class="max-w-2xl mx-auto mt-8 px-4">

        <div class="flex items-center justify-between mb-6">
            <h2 class="text-lg font-semibold text-gray-900">My Entries</h2>
            <a href="/entries/create"
               class="bg-gray-900 text-white text-sm px-4 py-2 rounded-lg hover:bg-gray-700">
                + Write New Entry
            </a>
        </div>

        @forelse ($entries as $entry)
            <div class="bg-white rounded-xl border border-gray-200 p-5 mb-4">
                <h3 class="font-semibold text-gray-900 mb-1">
                    {{ $entry->title }}
                </h3>
                <p class="text-xs text-gray-400 mb-3">
                    {{ $entry->created_at->format('d F Y') }}
                </p>
                <p class="text-sm text-gray-600 line-clamp-2">
                    {{ $entry->content }}
                </p>
            </div>
        @empty
            <div class="text-center py-16 text-gray-400">
                <p class="text-5xl mb-4">📓</p>
                <p class="font-medium text-gray-500">No entries yet</p>
                <p class="text-sm mt-1">Start writing your first entry!</p>
            </div>
        @endforelse

    </div>

</body>
</html>
```

Ada tiga perubahan penting dari versi sebelumnya:

`$entry->title` alih-alih `$entry['title']`. Model Eloquent adalah objek, sehingga Anda mengakses property-nya dengan operator arrow `->`, bukan bracket array `[]`. Ini adalah perbedaan mendasar yang akan Anda lihat di sepanjang sisa course ini.

`$entry->created_at->format('d F Y')`. Laravel secara otomatis mengonversi kolom timestamp menjadi objek Carbon. Carbon adalah library tanggal/waktu yang powerful dan sudah disertakan bersama Laravel. Method `format('d F Y')` menghasilkan output seperti "20 February 2026". Anda dapat mengubah format string untuk menampilkan tanggal dalam format apa pun yang Anda butuhkan.

`@forelse ... @empty ... @endforelse` menggantikan `@foreach` yang kita gunakan sebelumnya. Directive `@forelse` bekerja persis seperti `@foreach`, tetapi menyertakan blok `@empty` yang dirender ketika collection tidak memiliki item. Ini jauh lebih bersih dibandingkan memeriksa panjang array secara manual sebelum memutuskan apa yang akan ditampilkan.

---

## Step 6: Masukkan Seed Data dengan Tinker {#step-6-insert-seed-data-with-tinker}

Database saat ini masih kosong, sehingga mengunjungi `/entries` akan menampilkan empty state "No entries yet". Mari kita masukkan beberapa data uji menggunakan Artisan Tinker agar kita dapat melihat entry ditampilkan di browser.

Buka terminal baru (biarkan development server tetap berjalan) dan jalankan Tinker:

```bash
php artisan tinker
```

Pertama, buat user sementara. Kita memerlukannya karena setiap entry membutuhkan `user_id`:

```php
$user = \App\Models\User::create([
    'name'     => 'Budi',
    'email'    => 'budi@example.com',
    'password' => bcrypt('password123'),
]);
```

Sekarang buat beberapa entry melalui relationship milik user:

```php
$user->entries()->create(['title' => 'My first entry', 'content' => 'This is my very first journal entry. Feels great to get started!']);

$user->entries()->create(['title' => 'Learning Laravel', 'content' => 'Today I learned about Eloquent ORM. Turns out interacting with the database can be this clean and expressive.']);

$user->entries()->create(['title' => 'Weekend plans', 'content' => 'Planning to finish the Laravel course this weekend and maybe start building a side project.']);
```

Output:
```
$ php artisan tinker
Psy Shell v0.12.22 (PHP 8.4.5 — cli) by Justin Hileman
New PHP manual is available (latest: 3.0.2). Update with `doc --update-manual`

> $user = \App\Models\User::create([
.     'name'     => 'Budi',
.     'email'    => 'budi@example.com',
.     'password' => bcrypt('password123'),
. ]);

= App\Models\User {#7909
    name: "Budi",
    email: "budi@example.com",
    #password: "\$2y\$12\$ho.DIN6DCiHFqKwiEzb8GuFdTkFEdDKhyL6x8E4MqjL0Zrf7/Tncu",
    updated_at: "2026-03-29 08:12:19",
    created_at: "2026-03-29 08:12:19",
    id: 1,
  }

> $user->entries()->create(['title' => 'My first entry', 'content' => 'This is my very first journal entry. Feels great to get started!']);

= App\Models\Entry {#8652
    title: "My first entry",
    content: "This is my very first journal entry. Feels great to get started!",
    user_id: 1,
    updated_at: "2026-03-29 08:12:29",
    created_at: "2026-03-29 08:12:29",
    id: 1,
  }

> $user->entries()->create(['title' => 'Learning Laravel', 'content' => 'Today I learned about Eloquent ORM. Turns out interacting with the database can be this clean and expressive.']);

= App\Models\Entry {#7407
    title: "Learning Laravel",
    content: "Today I learned about Eloquent ORM. Turns out interacting with the database can be this clean and expressive.",
    user_id: 1,
    updated_at: "2026-03-29 08:12:38",
    created_at: "2026-03-29 08:12:38",
    id: 2,
  }

> $user->entries()->create(['title' => 'Weekend plans', 'content' => 'Planning to finish the Laravel course this weekend and maybe start building a side project.']);

= App\Models\Entry {#7350
    title: "Weekend plans",
    content: "Planning to finish the Laravel course this weekend and maybe start building a side project.",
    user_id: 1,
    updated_at: "2026-03-29 08:12:43",
    created_at: "2026-03-29 08:12:43",
    id: 3,
  }


```

![insert data via tinker](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/04-insert-dummy-data-via-tinker.webp)

Ketik `exit` untuk keluar dari Tinker.

Perhatikan bagaimana kita menggunakan `$user->entries()->create([...])` untuk memasukkan entry. Ini adalah pendekatan berbasis relationship yang sama yang akan kita gunakan di controller nanti. Kolom `user_id` diisi secara otomatis karena kita membuatnya melalui relationship `entries()` milik user.

---

## Step 7: Lihat Hasilnya {#step-7-view-the-result}

Buka `http://127.0.0.1:8000/entries` di browser Anda. Anda sekarang akan melihat tiga entry yang baru saja kita buat, ditampilkan dengan judul, tanggal, dan cuplikan kontennya. Data ini berasal dari database, bukan dari array hardcoded.

![fetch data from database](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/05-fetch-data-from-database.webp)

Ini mengonfirmasi bahwa model sudah terhubung dengan benar ke database, query Eloquent berfungsi, dan view merender objek Eloquent dengan benar.

---

## Apa itu Eloquent ORM? {#what-is-eloquent-orm}

Setelah Anda menggunakan Eloquent secara praktik, mari kita pahami apa itu Eloquent pada level konseptual.

ORM adalah singkatan dari Object-Relational Mapping. Ini adalah teknik yang memungkinkan Anda berinteraksi dengan tabel database menggunakan objek PHP, bukan menulis SQL mentah. Setiap tabel di database mendapatkan class model yang sesuai di PHP. Setiap baris di tabel menjadi instance dari class tersebut. Dan setiap kolom menjadi property pada objek tersebut.

Tanpa Eloquent, mengambil entry dari database membutuhkan kode seperti ini:

```php
$pdo = new PDO('mysql:host=127.0.0.1;dbname=db_catatku', 'root', '');
$stmt = $pdo->prepare('SELECT * FROM entries ORDER BY created_at DESC');
$stmt->execute();
$entries = $stmt->fetchAll(PDO::FETCH_ASSOC);
```

Dengan Eloquent, operasi yang sama menjadi:

```php
$entries = Entry::latest()->get();
```

Perbedaannya sangat terasa. Versi Eloquent lebih singkat, lebih ekspresif, dan lebih mudah dibaca. Ini juga lebih aman karena Eloquent menangani parameter binding dan pencegahan SQL injection secara otomatis. Anda tidak perlu khawatir tentang escaping nilai atau menyiapkan statement secara manual.

---

## Apa itu Mass Assignment Protection? {#what-is-mass-assignment-protection}

Attribute `#[Fillable(['title', 'content'])]` adalah fitur keamanan yang layak dijelaskan lebih dalam.

Mass assignment adalah ketika Anda meneruskan array data secara langsung ke method seperti `Entry::create()` atau `$entry->update()`. Ini praktis karena Anda dapat membuat record dalam satu baris:

```php
Entry::create(['title' => 'My Entry', 'content' => 'Hello world']);
```

Namun ini menjadi berbahaya ketika data berasal dari input user. Bayangkan sebuah form dengan field `title` dan `content`. Seorang user yang berniat jahat dapat menambahkan field tambahan `user_id=5` ke request, mencoba memalsukan kepemilikan entry tersebut. Jika Anda menulis ini di controller Anda:

```php
Entry::create($request->all()); // Dangerous!
```

`user_id` dari request yang sudah dimanipulasi tersebut akan disimpan ke database. Penyerang baru saja mengklaim kepemilikan atas entry milik orang lain.

Attribute `#[Fillable]` mencegah hal ini. Dengan mendeklarasikan hanya `['title', 'content']` sebagai fillable, setiap upaya untuk mass-assign `user_id` atau kolom lainnya akan diabaikan secara diam-diam. `user_id` tidak ada dalam daftar fillable, sehingga tidak dapat diisi melalui mass assignment.

Lalu bagaimana cara kita mengisi `user_id`? Kita melakukannya secara eksplisit melalui relationship. Pada lesson selanjutnya ketika kita membangun fungsi store, kodenya akan terlihat seperti ini:

```php
$request->user()->entries()->create($validated);
```

Ini membuat entry melalui relationship `entries()` milik user yang sedang login, yang secara otomatis mengisi `user_id` dengan ID user saat ini. Nilai ini berasal dari session di sisi server, bukan dari input user, sehingga tidak mungkin dipalsukan.

---

## Kesimpulan {#conclusion}

Lesson ini mengubah model `Entry` dari file kosong menjadi model yang berfungsi penuh, aman, dan terhubung ke database. Berikut adalah poin-poin pentingnya:

- **Eloquent ORM** memetakan tabel database ke class PHP, baris ke objek, dan kolom ke property. Ini memungkinkan Anda berinteraksi dengan database menggunakan kode PHP yang ekspresif, bukan SQL mentah.
- Laravel 13 menggunakan attribute **`#[Fillable]`** untuk mendeklarasikan kolom mana saja yang dapat di-mass-assign. Ini menggantikan property `protected $fillable` yang lebih lama dengan sintaks yang lebih bersih dan lebih deklaratif.
- **Mass assignment protection** mencegah user yang berniat jahat untuk mengisi kolom yang seharusnya tidak dapat mereka akses (seperti `user_id`). Hanya kolom yang terdaftar di `#[Fillable]` yang dapat diisi melalui `create()` atau `update()`.
- Relationship **`belongsTo`** pada `Entry` menyatakan "setiap entry dimiliki oleh satu user." Relationship **`hasMany`** pada `User` menyatakan "setiap user dapat memiliki banyak entry."
- `Entry::with('user')->latest()->get()` mengambil semua entry beserta user terkaitnya dalam satu query yang efisien, diurutkan dari yang terbaru. Query ini akan diperbarui untuk dibatasi per user setelah authentication dibangun.
- **Eager loading** dengan `with('user')` mencegah N+1 query problem dengan mengambil semua record terkait dalam satu query tambahan.
- Objek Eloquent menggunakan **notasi arrow** (`$entry->title`) alih-alih notasi bracket array (`$entry['title']`).
- Laravel secara otomatis mengonversi kolom timestamp menjadi objek **Carbon**, memberikan Anda method format tanggal yang powerful seperti `->format('d F Y')`.
- **`@forelse`** seperti `@foreach` tetapi menyertakan blok `@empty` untuk menangani collection kosong dengan baik.
- **Artisan Tinker** memungkinkan Anda berinteraksi dengan model dan database secara langsung dari command line. Ini sangat berharga untuk pengujian dan memasukkan seed data selama pengembangan.

Pada lesson berikutnya, kita akan merapikan view menggunakan **Blade components**, cara Laravel untuk memecah template HTML menjadi bagian-bagian yang dapat digunakan kembali. Navigation bar, page layout, dan elemen struktural lainnya hanya perlu ditulis sekali dan dapat digunakan bersama di setiap halaman. Ini adalah langkah pertama menuju membuat Catatku terlihat dan terasa seperti aplikasi sungguhan.
