# Lesson 6 — Model Pertamamu

## Tujuan Pembelajaran

Di akhir lesson ini, kamu akan:
- Memahami apa itu Eloquent ORM dan cara kerjanya
- Mengkonfigurasi model `Entry` dengan `$fillable`
- Memahami konsep mass assignment protection
- Mendefinisikan relasi antara Entry dan User
- Menghubungkan controller ke model untuk mengambil data nyata dari database

---

## Apa itu Eloquent ORM?

Tanpa Eloquent, mengambil semua catatan dari database membutuhkan kode seperti ini:

```php
$pdo = new PDO('mysql:host=127.0.0.1;dbname=db_catatku', 'root', '');
$stmt = $pdo->prepare('SELECT * FROM entries WHERE user_id = ? ORDER BY created_at DESC');
$stmt->execute([auth()->id()]);
$entries = $stmt->fetchAll(PDO::FETCH_ASSOC);
```

Dengan **Eloquent**, kode yang sama menjadi:

```php
$entries = auth()->user()->entries()->latest()->get();
```

Jauh lebih pendek, lebih ekspresif, dan lebih mudah dibaca. Eloquent menerjemahkan kode PHP ini ke SQL di balik layar secara otomatis.

---

## Mengkonfigurasi Model Entry

Di lesson sebelumnya, artisan sudah membuat file `app/Models/Entry.php`. Buka file tersebut:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Entry extends Model
{
    //
}
```

Tambahkan properti `$fillable`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Entry extends Model
{
    protected $fillable = [
        'title',
        'content',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

---

## Apa itu Mass Assignment Protection?

`$fillable` adalah daftar kolom yang **boleh** diisi secara massal melalui `Entry::create([...])` atau `$entry->update([...])`.

Ini adalah fitur keamanan. Bayangkan ada form dengan field `title` dan `content`, tapi seseorang yang jahat menambahkan `user_id=5` ke dalam request — mencoba memalsukan kepemilikan catatan. Jika kita menulis:

```php
Entry::create($request->all()); // ⚠️ Berbahaya!
```

Maka `user_id` dari request itu akan ikut tersimpan. Dengan `$fillable`, hanya kolom yang terdaftar yang bisa diisi massal. `user_id` tidak ada di `$fillable` — dan kita akan mengisinya sendiri secara eksplisit dari session pengguna yang login.

---

## Mendefinisikan Relasi

Setiap catatan dimiliki oleh satu user. Relasi ini sudah tercermin di database (kolom `user_id`), dan kita perlu mendefinisikannya di model agar Eloquent bisa menggunakannya.

**Di model `Entry`** (sudah ditambahkan di atas):
```php
public function user(): BelongsTo
{
    return $this->belongsTo(User::class);
}
```

**Di model `User`**, tambahkan relasi baliknya. Buka `app/Models/User.php` dan tambahkan:

```php
use Illuminate\Database\Eloquent\Relations\HasMany;

// Di dalam class User:
public function entries(): HasMany
{
    return $this->hasMany(Entry::class);
}
```

Dengan relasi ini:
- Dari Entry ke User: `$entry->user->name`
- Dari User ke semua Entry-nya: `auth()->user()->entries()->get()`

---

## Menghubungkan Controller ke Model

Sekarang perbarui `EntryController` untuk mengambil data nyata dari database, mengganti array palsu:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Entry;
use Illuminate\Http\Request;

class EntryController extends Controller
{
    public function index()
    {
        // Ambil semua catatan milik user yang login, terbaru di atas
        $entries = auth()->user()->entries()->latest()->get();

        return view('entries.index', compact('entries'));
    }
}
```

Mari bedah query `auth()->user()->entries()->latest()->get()`:

**`auth()->user()`** — Ambil objek User yang sedang login.

**`->entries()`** — Akses relasi `hasMany` ke model Entry. Query ini otomatis ter-scope hanya untuk catatan milik user tersebut — tidak akan mengambil catatan milik orang lain.

**`->latest()`** — Urutkan dari yang paling baru. Shortcut untuk `orderBy('created_at', 'desc')`.

**`->get()`** — Eksekusi query dan kembalikan hasilnya sebagai Collection.

---

## Memperbarui View

Data yang diterima view sekarang adalah koleksi objek Eloquent, bukan array. Cara mengaksesnya menggunakan `->` bukan `[]`.

Perbarui `resources/views/entries/index.blade.php`:

```html
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Catatanku — Catatku</title>
    <script src="https://unpkg.com/@tailwindcss/browser@4"></script>
</head>
<body class="bg-gray-50">

    <nav class="bg-white border-b border-gray-200 px-6 py-4">
        <h1 class="text-xl font-bold text-gray-900">Catatku 📓</h1>
    </nav>

    <div class="max-w-2xl mx-auto mt-8 px-4">

        <div class="flex items-center justify-between mb-6">
            <h2 class="text-lg font-semibold text-gray-900">Catatanku</h2>
            <a href="/entries/create"
               class="bg-gray-900 text-white text-sm px-4 py-2 rounded-lg hover:bg-gray-700">
                + Tulis Catatan Baru
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
                <p class="font-medium text-gray-500">Belum ada catatan</p>
                <p class="text-sm mt-1">Mulai tulis catatan pertamamu!</p>
            </div>
        @endforelse

    </div>

</body>
</html>
```

Perubahan penting:

**`$entry->title`** — Mengakses properti objek Eloquent dengan arrow operator `->`, bukan bracket `[]`.

**`$entry->created_at->format('d F Y')`** — Kolom timestamp secara otomatis dikonversi menjadi objek Carbon oleh Laravel. Method `format('d F Y')` menghasilkan format seperti "20 Februari 2026".

**`@forelse ... @empty ... @endforelse`** — Versi `@foreach` yang punya blok `@empty` untuk kondisi koleksi kosong. Lebih bersih daripada mengecek panjang array secara manual.

---

## Mencoba di Browser

Buka `http://127.0.0.1:8000/entries`. Karena database masih kosong dan kita belum punya sistem login, akan muncul error. Ini normal — kita akan menyelesaikannya di lesson-lesson berikutnya secara bertahap.

Untuk sementara, di lesson 8 kita akan menyediakan cara sementara untuk testing. Sekarang yang penting adalah memahami bahwa model sudah terhubung ke database dengan benar.

---

## Ringkasan

Kita telah:
- Memahami Eloquent ORM dan keunggulannya dibanding SQL manual
- Mengkonfigurasi model `Entry` dengan `$fillable` untuk keamanan mass assignment
- Mendefinisikan relasi `belongsTo` di `Entry` dan `hasMany` di `User`
- Memperbarui controller untuk mengambil data dari database melalui relasi user
- Memperbarui view untuk menampilkan objek Eloquent dan format timestamp

Di lesson berikutnya, kita akan memoles tampilan dengan menggunakan **Blade components** agar kode lebih rapi dan reusable.
