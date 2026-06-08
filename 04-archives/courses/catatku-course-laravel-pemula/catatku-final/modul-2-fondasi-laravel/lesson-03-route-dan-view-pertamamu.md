# Lesson 3 — Route dan View Pertamamu

## Tujuan Pembelajaran

Di akhir lesson ini, kamu akan:
- Memahami konsep route dan bagaimana URL terhubung ke kode
- Membuat route pertama di `routes/web.php`
- Membuat view Blade pertama untuk halaman daftar catatan
- Memahami sintaks dasar Blade template

---

## Apa itu Route?

Ketika kamu mengetikkan `http://catatku.test/entries` di browser, siapa yang memutuskan halaman apa yang ditampilkan? Jawabannya: **route**.

Route adalah peta yang menghubungkan URL dengan kode yang harus dijalankan. Di Laravel, semua route didefinisikan di file `routes/web.php`.

Bayangkan route seperti resepsionis di kantor. Ketika tamu datang dan berkata "Saya ingin ke ruang arsip", resepsionis mengarahkan ke lantai dan ruangan yang tepat. Route bekerja sama: ketika browser meminta URL tertentu, route mengarahkan ke kode yang tepat.

---

## Membuka File Route

Buka `routes/web.php`. Kamu akan menemukan satu route bawaan Laravel:

```php
<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});
```

Baca baris ini sebagai: "Ketika ada request GET ke URL `/`, jalankan fungsi ini, yang mengembalikan view bernama `welcome`."

---

## Membuat Route untuk Daftar Catatan

Kita akan menambahkan route baru untuk halaman daftar catatan. Untuk saat ini, kita gunakan data palsu dulu agar bisa fokus memahami cara kerja route dan view sebelum menyentuh database.

Tambahkan route baru di `routes/web.php`:

```php
<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/entries', function () {
    $entries = [
        [
            'id'         => 1,
            'title'      => 'Rencana liburan akhir tahun',
            'content'    => 'Sudah lama tidak liburan. Mungkin bisa ke Yogyakarta atau Lombok. Perlu riset dulu soal budget dan waktu yang tepat.',
            'created_at' => '20 Februari 2026',
        ],
        [
            'id'         => 2,
            'title'      => 'Belajar Laravel hari pertama',
            'content'    => 'Hari ini mulai belajar Laravel. Ternyata tidak sesulit yang dibayangkan. Routing dan view cukup intuitif.',
            'created_at' => '19 Februari 2026',
        ],
        [
            'id'         => 3,
            'title'      => 'Resolusi bulan ini',
            'content'    => 'Ingin lebih konsisten menulis catatan setiap hari. Minimal satu paragraf sebelum tidur.',
            'created_at' => '18 Februari 2026',
        ],
    ];

    return view('entries.index', compact('entries'));
});
```

`compact('entries')` adalah cara singkat PHP untuk membuat array `['entries' => $entries]`. Dengan ini, variabel `$entries` tersedia di dalam view dengan nama yang sama.

---

## Membuat View Pertama

View adalah file yang merender data menjadi HTML yang dikirim ke browser. Laravel menggunakan **Blade** sebagai template engine — HTML biasa yang diperkaya sintaks PHP yang lebih bersih dan aman.

Buat folder `resources/views/entries/` dan di dalamnya buat file `index.blade.php`:

```
resources/
└── views/
    └── entries/
        └── index.blade.php   ← buat file ini
```

Isi file `resources/views/entries/index.blade.php`:

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

        {{-- Daftar catatan --}}
        @foreach ($entries as $entry)
            <div class="bg-white rounded-xl border border-gray-200 p-5 mb-4">
                <h3 class="font-semibold text-gray-900 mb-1">
                    {{ $entry['title'] }}
                </h3>
                <p class="text-sm text-gray-500 mb-3">
                    {{ $entry['created_at'] }}
                </p>
                <p class="text-sm text-gray-700 line-clamp-2">
                    {{ $entry['content'] }}
                </p>
            </div>
        @endforeach

    </div>

</body>
</html>
```

### Sintaks Blade yang Digunakan

**`{{ $variabel }}`** — Menampilkan nilai variabel. Laravel otomatis mengamankan output dari serangan XSS menggunakan `htmlspecialchars`.

**`@foreach ($entries as $entry) ... @endforeach`** — Perulangan untuk menampilkan setiap item dalam koleksi.

**`{{-- komentar --}}`** — Komentar Blade yang tidak muncul di HTML output yang dikirim ke browser.

---

## Melihat Hasil

Pastikan development server masih berjalan, lalu buka browser dan akses `http://127.0.0.1:8000/entries`.

Kamu akan melihat halaman daftar catatan dengan tiga entri palsu yang kita definisikan di route tadi — lengkap dengan judul, tanggal, dan potongan isi catatan.

---

## Alur Data: Route → View

Penting untuk memahami bagaimana data mengalir:

```
routes/web.php
    $entries = [...];
    return view('entries.index', compact('entries'));
            │
            ▼
resources/views/entries/index.blade.php
    @foreach ($entries as $entry)
        {{ $entry['title'] }}
    @endforeach
```

Data dibuat di route, dikirim ke view melalui `compact()`, dan ditampilkan menggunakan sintaks Blade. Pola ini akan terus kita gunakan — meskipun nanti `$entries` akan datang dari database, bukan array manual.

---

## Ringkasan

Kita telah:
- Memahami route sebagai peta URL ke kode
- Menambahkan route `/entries` yang mengirim data ke view
- Membuat view Blade pertama dengan `{{ }}` dan `@foreach`
- Melihat halaman daftar catatan di browser

Di lesson berikutnya, sebelum menghubungkan ke database, kita akan belajar konsep **MVC** yang membuat struktur kode Laravel tetap rapi dan terorganisir.
