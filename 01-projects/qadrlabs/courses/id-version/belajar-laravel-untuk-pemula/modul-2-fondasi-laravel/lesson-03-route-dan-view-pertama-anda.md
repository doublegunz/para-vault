Pada lesson sebelumnya, kita sudah menyiapkan lingkungan pengembangan secara lengkap dan menjalankan proyek Laravel di browser. Namun yang Anda lihat adalah halaman welcome bawaan Laravel, bukan sesuatu yang kita bangun sendiri. Lesson ini akan mengubahnya. Untuk pertama kalinya, kita akan membuat halaman yang benar-benar menjadi bagian dari Catatku: sebuah halaman home dan halaman daftar entries yang dapat Anda buka di browser dan lihat konten nyata yang dirender dari data.

## Ikhtisar {#overview}

### Apa yang Akan Anda Bangun

Di akhir lesson ini, Anda akan dapat membuka browser, pergi ke `http://127.0.0.1:8000/entries`, dan melihat halaman daftar entri jurnal dengan beberapa entri yang ditampilkan dengan rapi. Data yang ditampilkan akan berasal dari array yang kita tulis sendiri, belum dari database, tetapi layout dan alurnya sudah mencerminkan cara kerja aplikasi sungguhan. Anda juga akan membuat halaman home khusus untuk Catatku untuk menggantikan halaman welcome bawaan Laravel.

### Apa yang Akan Anda Pelajari

- Apa itu route dan bagaimana ia menghubungkan URL dengan kode yang dijalankan
- Cara mendefinisikan route di `routes/web.php`
- Cara membuat view Blade dan mengorganisasikannya dalam folder
- Sintaks dasar Blade: `{{ }}` untuk menampilkan variabel, `@foreach` untuk loop, dan `{{-- --}}` untuk komentar
- Bagaimana data mengalir dari route ke view menggunakan `compact()`

### Apa yang Anda Butuhkan

- Proyek `catatku` terbuka di VS Code
- Development server yang berjalan dengan `php artisan serve`
- Tidak ada yang perlu diinstal baru. Semua yang Anda butuhkan sudah ada di dalam proyek Laravel yang kita buat di Lesson 2

---

## Langkah 1: Jelajahi File Route Default {#step-1-explore-the-default-route-file}

Buka `routes/web.php` di VS Code. Anda akan menemukan satu route yang dibuat oleh Laravel untuk Anda:

```php
<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});
```

Bacalah baris ini sebagai: "Ketika ada GET request ke URL `/`, jalankan fungsi ini, yang mengembalikan file view bernama `welcome.blade.php`."

Ada dua konsep penting di sini. Pertama, `Route::get('/', ...)` memberi tahu Laravel untuk mendengarkan GET request pada URL root. GET adalah HTTP method yang digunakan browser Anda saat Anda mengetik URL dan menekan Enter. Kedua, `return view('welcome')` memberi tahu Laravel untuk mencari file bernama `welcome.blade.php` di dalam `resources/views/` dan mengirimkan konten HTML-nya kembali ke browser.

Inilah route yang bertanggung jawab atas halaman welcome Laravel yang Anda lihat di lesson sebelumnya saat Anda membuka `http://127.0.0.1:8000`.

Sebuah **view** adalah file yang mengubah data menjadi HTML yang dikirim ke browser. Laravel menggunakan **Blade** sebagai template engine-nya. File Blade adalah HTML biasa yang ditingkatkan dengan sintaks PHP yang lebih bersih dan aman, yang membuat bekerja dengan data dinamis menjadi jauh lebih menyenangkan.

---

## Langkah 2: Buat Halaman Home {#step-2-create-the-home-page}

Daripada menampilkan halaman welcome bawaan Laravel, mari kita buat halaman home yang sesuai untuk Catatku. Pertama, perbarui route di `routes/web.php` agar mengarah ke view baru:

```php
<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('home');
});
```

Satu-satunya perubahan di sini adalah mengganti `'welcome'` dengan `'home'`. Ini memberi tahu Laravel untuk mencari `home.blade.php` alih-alih `welcome.blade.php` ketika seseorang mengunjungi URL root.

Sekarang buat file view-nya. Buat file baru di `resources/views/home.blade.php` dan tambahkan konten berikut:

```html
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Catatku - Simple Journal App</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-50 text-gray-900 font-sans antialiased selection:bg-blue-100">
    <div class="min-h-screen flex flex-col items-center justify-center bg-gradient-to-b from-blue-50 to-white">
        <div class="max-w-2xl w-full text-center px-6 py-12">
            <h1 class="text-5xl font-extrabold tracking-tight text-blue-600 mb-6 drop-shadow-sm">Catatku</h1>
            <p class="text-xl text-gray-600 mb-10 leading-relaxed">
                A simple journal app to accompany your day. Start capturing what matters, easily and quickly.
            </p>
            
            <div class="flex flex-col sm:flex-row gap-4 justify-center items-center">
                @auth
                    <a href="" class="inline-flex items-center justify-center px-8 py-3.5 border border-transparent text-lg font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow flex-1 sm:flex-none transition-all duration-200 hover:scale-105">
                        My Entries
                    </a>
                @else
                    <a href="" class="inline-flex items-center justify-center px-8 py-3.5 border border-transparent text-lg font-medium rounded-xl text-white bg-blue-600 hover:bg-blue-700 shadow flex-1 sm:flex-none transition-all duration-200 hover:scale-105">
                        Log In
                    </a>
                    <a href="" class="inline-flex items-center justify-center px-8 py-3.5 border border-gray-200 text-lg font-medium rounded-xl text-blue-700 bg-white hover:bg-gray-50 shadow-sm flex-1 sm:flex-none transition-all duration-200 hover:border-gray-300">
                        Register
                    </a>
                @endauth
            </div>
        </div>
    </div>
</body>
</html>
```

Simpan file tersebut.
Sebagai pengingat, jika development server belum berjalan, jalankan dulu perintah berikut `php artisan serve`, lalu buka `http://127.0.0.1:8000` di browser Anda.

Alih-alih halaman default Laravel, sekarang Anda seharusnya melihat halaman home Catatku dengan judul aplikasi, deskripsi, dan tombol navigasi.

![catatku homepage](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/02-catatku-landing-page.webp)

Perhatikan directive `@auth` dan `@else` pada template. Ini adalah Blade conditional yang memeriksa apakah pengguna sedang login. Karena kita belum membangun authentication, browser akan menampilkan tombol "Log In" dan "Register" (blok `@else`). Atribut `href` masih kosong untuk saat ini. Kita akan menghubungkannya pada Lesson 11 ketika sistem authentication sudah lengkap.

---

## Langkah 3: Tambahkan Route Entries {#step-3-add-the-entries-route}

Sekarang mari kita buat route untuk halaman daftar entri jurnal. Kita akan menggunakan dummy data untuk saat ini sehingga kita bisa fokus memahami cara kerja route dan view sebelum menyentuh database.

Buka `routes/web.php` dan tambahkan route baru di bawah route yang sudah ada:

```php
<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('home');
});

Route::get('/entries', function () {
    $entries = [
        [
            'id'         => 1,
            'title'      => 'Year-end vacation plans',
            'content'    => 'It has been a while since the last vacation. Maybe Yogyakarta or Lombok. Need to research the budget and best timing.',
            'created_at' => '20 February 2026',
        ],
        [
            'id'         => 2,
            'title'      => 'First day learning Laravel',
            'content'    => 'Started learning Laravel today. Turns out it is not as hard as I expected. Routing and views are quite intuitive.',
            'created_at' => '19 February 2026',
        ],
        [
            'id'         => 3,
            'title'      => 'This month\'s resolutions',
            'content'    => 'Want to be more consistent writing entries every day. At least one paragraph before bed.',
            'created_at' => '18 February 2026',
        ],
    ];

    return view('entries.index', compact('entries'));
});
```

Route baru ini mendengarkan GET request ke `/entries`. Di dalam closure, kita membuat array `$entries` yang berisi tiga entri jurnal palsu. Setiap entri memiliki field `id`, `title`, `content`, dan `created_at`, meniru struktur yang nantinya akan kita gunakan dengan record database sungguhan.

Baris `return view('entries.index', compact('entries'))` melakukan dua hal. Argumen pertama `'entries.index'` memberi tahu Laravel untuk mencari file view di `resources/views/entries/index.blade.php`. Notasi titik ini memetakan langsung ke struktur folder. Argumen kedua `compact('entries')` adalah singkatan PHP untuk `['entries' => $entries]`. Ia mengambil variabel `$entries` dan membuatnya tersedia di dalam view dengan nama yang sama. Beginilah cara data berpindah dari route ke view.

---

## Langkah 4: Buat View Entries {#step-4-create-the-entries-view}

Buat folder baru bernama `entries` di dalam `resources/views/`, lalu buat file bernama `index.blade.php` di dalamnya:

```
resources/
└── views/
    ├── home.blade.php
    └── entries/
        └── index.blade.php   ← create this file
```

Tambahkan konten berikut ke `resources/views/entries/index.blade.php`:

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

        {{-- Entry list --}}
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

Mari kita bahas sintaks Blade yang digunakan dalam template ini.

`{{ $entry['title'] }}` menampilkan nilai dari sebuah variabel. Tanda kurung kurawal ganda ini bukan sekadar untuk tampilan. Laravel secara otomatis menjalankan output melalui `htmlspecialchars`, yang melindungi aplikasi Anda dari serangan XSS (Cross-Site Scripting). Anda harus selalu menggunakan `{{ }}` daripada `echo` PHP mentah saat menampilkan data yang akan dilihat pengguna.

`@foreach ($entries as $entry) ... @endforeach` adalah loop yang melakukan iterasi pada setiap item di array `$entries`. Untuk setiap entri, Blade merender blok HTML di dalam loop satu kali, dengan `$entry` berisi data item saat ini. Beginilah cara kita menampilkan daftar item tanpa menduplikasi HTML secara manual.

`{{-- Entry list --}}` adalah komentar Blade. Berbeda dengan komentar HTML (`<!-- -->`), komentar Blade sepenuhnya dihapus dari output. Komentar ini tidak pernah muncul di HTML yang dikirim ke browser, yang berarti komentar ini tidak terlihat oleh siapa pun yang melihat source halaman Anda.

---

## Langkah 5: Lihat Hasilnya {#step-5-view-the-result}

Pastikan development server masih berjalan (kita memulainya sebelumnya dengan `php artisan serve`), lalu buka browser Anda dan pergi ke `http://127.0.0.1:8000/entries`.

![View entries page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/03-catatku-entries-page.webp)

Anda seharusnya melihat halaman daftar entries dengan tiga entri jurnal yang ditampilkan dengan rapi, masing-masing menampilkan judul, tanggal, dan cuplikan konten. Data tersebut berasal dari array yang kita definisikan di route. Tombol "+ Write New Entry" belum berfungsi karena kita belum membuat route tersebut, tetapi halaman itu sendiri sudah berfungsi sepenuhnya.

Coba kunjungi juga `http://127.0.0.1:8000` untuk memastikan halaman home masih berfungsi. Sekarang Anda memiliki dua route yang berfungsi di aplikasi Anda: `/` untuk halaman home dan `/entries` untuk daftar entries.

---

## Apa itu Route? {#what-is-a-route}

Setelah Anda melihat route bekerja, mari kita mundur sejenak dan memahami konsepnya dengan lebih jelas.

Ketika Anda mengetik `http://127.0.0.1:8000/entries` di browser Anda, sesuatu perlu memutuskan halaman apa yang akan ditampilkan. Sesuatu itu adalah sebuah **route**.

Route adalah pemetaan antara URL dan kode yang harus dijalankan ketika URL tersebut diminta. Di Laravel, semua web route didefinisikan di file `routes/web.php`.

Bayangkan route seperti seorang resepsionis di sebuah gedung perkantoran. Ketika seorang pengunjung datang dan berkata "Saya perlu pergi ke ruang arsip," resepsionis mengarahkan mereka ke lantai dan ruangan yang tepat. Route bekerja dengan cara yang sama: ketika browser meminta URL tertentu, route mengarahkan request tersebut ke kode yang tepat.

Pola dasarnya terlihat seperti ini:

```php
Route::get('/url', function () {
    // Code that runs when this URL is visited
    return view('template-name');
});
```

`Route::get` berarti route ini merespons HTTP GET request (jenis request yang dibuat browser Anda saat Anda mengetik URL). Argumen pertama adalah path URL. Argumen kedua adalah closure (fungsi anonim) yang berisi kode yang akan dieksekusi. Apa pun yang dikembalikan oleh fungsi ini adalah yang dikirim kembali ke browser.

---

## Alur Data: Route ke View {#data-flow-route-to-view}

Memahami bagaimana data bergerak melalui aplikasi Anda sangatlah penting. Berikut adalah pola yang kita gunakan dalam lesson ini:

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

Data dibuat di route, diteruskan ke view melalui `compact()`, dan ditampilkan menggunakan sintaks Blade. Pola ini akan tetap persis sama sepanjang sisa course ini. Satu-satunya yang akan berubah adalah dari mana data tersebut berasal. Saat ini data berupa array hardcoded. Dalam beberapa lesson ke depan, `$entries` akan berasal dari database melalui Eloquent. Namun alur dari route ke view tetap identik.

Inilah salah satu hal terpenting yang perlu dipahami sejak awal: **mekanisme untuk meneruskan data ke view tidak berubah berdasarkan sumber datanya.** Baik data tersebut berasal dari array, API, atau query database, view selalu menerimanya dengan cara yang sama dan merendernya dengan cara yang sama.

---

## Kesimpulan {#conclusion}

Lesson ini membawa Catatku dari proyek kosong menjadi sesuatu yang dapat Anda lihat dan interaksikan di browser. Berikut adalah poin-poin penting yang perlu diingat:

- Sebuah **route** memetakan URL ke kode yang harus dijalankan ketika URL tersebut diminta. Semua web route berada di `routes/web.php`.
- `Route::get('/path', function () { ... })` mendefinisikan route yang merespons GET request pada path yang diberikan.
- Sebuah **view** adalah file template Blade yang mengubah data menjadi HTML. View berada di `resources/views/` dan menggunakan ekstensi `.blade.php`.
- Laravel menggunakan **notasi titik** untuk memetakan nama view ke path folder: `'entries.index'` memetakan ke `resources/views/entries/index.blade.php`.
- `compact('entries')` adalah singkatan untuk `['entries' => $entries]` dan merupakan cara standar untuk meneruskan data dari route ke view.
- `{{ $variable }}` menampilkan nilai dengan perlindungan XSS otomatis. Selalu gunakan ini daripada `echo` PHP mentah.
- `@foreach` melakukan loop pada koleksi untuk merender blok HTML berulang tanpa duplikasi kode.
- `{{-- comment --}}` membuat komentar yang sepenuhnya dihapus dari output HTML.
- **Pola alur data** (route menyiapkan data, meneruskannya ke view, Blade merendernya) tetap sama sepanjang course ini. Hanya sumber datanya yang berubah.

Pada lesson berikutnya, kita akan mempelajari **pola MVC** dan alasan mengapa Laravel mengorganisasikan kode dengan cara seperti itu. Saat ini, semua logika dan data kita berada bersama-sama di `routes/web.php`, dan itu akan mulai terasa tidak nyaman seiring berkembangnya aplikasi. Controller menyelesaikan masalah ini, dan memahami alasan keberadaannya akan membuat semua yang kita bangun selanjutnya terasa jauh lebih natural.
