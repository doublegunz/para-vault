## 1. Sebelum Anda Memulai

View Catatku telah diberi style dengan CSS inline demi kesederhanaan. Setiap `<button>` memiliki attribute `style="background: #2563eb; ..."`. Ini baik untuk belajar, tetapi menyakitkan untuk proyek nyata: mengubah warna biru memerlukan pengeditan setiap view, dan markup menjadi berantakan dengan aturan style. Tailwind CSS menyediakan utility class (`class="bg-blue-600 text-white"`) yang menjaga styling tetap ringkas sambil berada di file yang sama dengan markup Anda. Vite adalah build tool yang mengompilasi CSS dan JavaScript Anda untuk production, menghasilkan bundle yang dioptimalkan dengan fitur seperti reload otomatis selama development.

Lesson ini mengajarkan Anda menyiapkan Vite dan Tailwind di Catatku, bermigrasi dari inline style ke utility class, dan mengonfigurasi hot reloading untuk feedback instan selama development. Laravel 13 disertai Vite dan Tailwind yang sudah terkonfigurasi di proyek baru, jadi jika proyek Anda sudah memiliki `vite.config.js` dan `tailwind.config.js`, Anda sebagian besar perlu memahami apa yang ada dan cara menggunakannya. Di akhir, view Anda akan lebih bersih, pengalaman development Anda akan lebih cepat dengan reload instan, dan build production Anda akan dioptimalkan.

### What You'll Build

Anda akan mengonfigurasi Vite dan Tailwind, memigrasikan satu view (index entri) dari inline style ke class Tailwind, dan menyiapkan alur kerja development dengan `npm run dev` untuk hot reloading.

### What You'll Learn

- ✅ Apa itu Vite dan mengapa kita membutuhkan build tool
- ✅ Utility class Tailwind CSS
- ✅ Directive Blade `@vite`
- ✅ Menjalankan `npm run dev` dan `npm run build`
- ✅ Konfigurasi Tailwind kustom
- ✅ Varian responsive dan hover

### What You'll Need

- Lesson 15 sudah selesai
- Node.js 18+ terinstal di mesin Anda

---

## 2. Menginstal Vite dan Tailwind

Laravel 13 disertai Vite, Tailwind CSS v4, dan integrasinya yang sudah terkonfigurasi. Periksa proyek Anda untuk `package.json` dan `vite.config.js`. Jika keduanya ada, lewati ke Section 3. Jika salah satu hilang, ikuti dua langkah di bawah ini.

### Step 1: Menginstal Dependensi

Pertama, periksa apakah `axios` terdaftar di dependensi `package.json` Anda. Beberapa scaffold Laravel yang lebih lama atau default menyertakannya, tetapi Catatku tidak menggunakannya secara langsung. Jika Anda melihatnya, hapus dari daftar package dan juga bersihkan import-nya dari `resources/js/bootstrap.js`.

Jalankan perintah uninstall untuk menghapus package.

```bash
npm uninstall axios
```

Menghapus package saja tidak cukup. Vite memindai `resources/js/bootstrap.js` saat startup dan akan tetap melemparkan error `Failed to run dependency scan` karena file tersebut berisi sebuah baris `import axios from 'axios'`. Buka `resources/js/bootstrap.js` dan ganti seluruh kontennya dengan berikut.

```javascript
// No third-party imports required for Catatku.
```

`bootstrap.js` asli menetapkan axios sebagai global dan mengonfigurasi header `X-Requested-With` untuk request AJAX. Catatku menggunakan pengiriman form HTML standar dan API Sanctum alih-alih pemanggilan axios langsung, sehingga tidak ada setup itu yang dibutuhkan. Membersihkan file mencegah Vite mencoba meresolusi sebuah package yang tidak lagi ada.

Lalu instal semua package yang tersisa.

```bash
npm install --ignore-scripts
```

Ini menginstal Vite, `laravel-vite-plugin`, dan Tailwind CSS v4 (melalui plugin `@tailwindcss/vite`). Tidak seperti Tailwind CSS v3, versi 4 tidak memerlukan PostCSS atau file `tailwindcss.config.js` terpisah. Integrasi build ditangani sepenuhnya melalui plugin Vite.

### Step 2: Mengonfirmasi Entry Point CSS

Buka `resources/css/app.css`. Konten default dari scaffold Laravel 13 terlihat seperti ini.

```css
@import 'tailwindcss';

@source '../../vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php';
@source '../../storage/framework/views/*.php';
@source '../**/*.blade.php';
@source '../**/*.js';

@theme {
    --font-sans: 'Instrument Sans', ui-sans-serif, system-ui, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji',
        'Segoe UI Symbol', 'Noto Color Emoji';
}
```

Mari kita telusuri setiap section. Baris `@import 'tailwindcss'` menggantikan tiga directive `@tailwind base/components/utilities` dari Tailwind v3: satu import adalah semua yang dibutuhkan Tailwind v4. Directive `@source` memberi tahu Tailwind persis path file mana yang harus dipindai untuk nama class; Tailwind menghasilkan CSS hanya untuk class yang benar-benar ditemukannya di file tersebut, yang itulah cara ia menghasilkan bundle production yang kecil. Path vendor Pagination memastikan style link paginator dihasilkan meskipun file tersebut berada di luar `resources/`. Blok `@theme` mendefinisikan CSS custom property yang dipetakan Tailwind ke utility class secara otomatis.

Untuk menambahkan warna brand untuk Catatku, kembangkan blok `@theme` yang ada dengan token warna. Buka `resources/css/app.css` dan tambahkan empat baris `--color-brand-*` di dalam blok `@theme`.

```css
@import 'tailwindcss';

@source '../../vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php';
@source '../../storage/framework/views/*.php';
@source '../**/*.blade.php';
@source '../**/*.js';

@theme {
    --font-sans: 'Instrument Sans', ui-sans-serif, system-ui, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji',
        'Segoe UI Symbol', 'Noto Color Emoji';

    --color-brand-50: #eff6ff;
    --color-brand-500: #3b82f6;
    --color-brand-600: #2563eb;
    --color-brand-700: #1d4ed8;
}
```

Setiap custom property `--color-brand-*` secara otomatis dipetakan ke utility class: `--color-brand-600` menjadi tersedia sebagai `bg-brand-600`, `text-brand-600`, `border-brand-600`, dan setiap varian utility warna lainnya. Tidak ada file konfigurasi JavaScript yang dibutuhkan.

### Step 3: Mengonfirmasi Konfigurasi Vite

Buka `vite.config.js` dan konfirmasi ia cocok dengan berikut.

```javascript
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
        tailwindcss(),
    ],
    server: {
        watch: {
            ignored: ['**/storage/framework/views/**'],
        },
    },
});
```

Kedua plugin bekerja bersama dengan cara yang spesifik. Plugin `laravel` mengintegrasikan Vite dengan asset versioning Laravel dan directive Blade `@vite()`, dan opsi `refresh: true` membuat browser memuat ulang secara otomatis ketika file Blade berubah. Plugin `tailwindcss()` dari `@tailwindcss/vite` menangani semua pemrosesan Tailwind CSS langsung di dalam Vite tanpa memerlukan PostCSS. Aturan `server.watch.ignored` mencegah Vite mengawasi cache view yang dikompilasi Laravel, yang akan menyebabkan rebuild yang tidak perlu.

---

## 3. Menyertakan Vite di Layout Anda

File layout `resources/views/components/layout.blade.php` saat ini memuat Tailwind CSS dari sebuah CDN menggunakan tag `<script>`. Ganti satu baris itu dengan directive Blade `@vite()` sehingga layout menggunakan aset yang dikompilasi secara lokal sebagai gantinya.

Di section `<head>`, temukan dan ganti baris ini:

```
<script src="https://unpkg.com/@tailwindcss/browser@4"></script>
```

Ganti dengan:

```
@vite(['resources/css/app.css', 'resources/js/app.js'])
```

Directive `@vite([...])` melakukan dua hal berbeda tergantung pada environment saat ini. Dalam mode development (ketika `npm run dev` berjalan), ia menghasilkan tag `<link>` dan `<script>` yang menunjuk ke dev server lokal Vite di `http://localhost:5173`, yang mengaktifkan hot module replacement dan refresh browser instan saat menyimpan file. Dalam mode production (setelah `npm run build`), ia membaca `public/build/manifest.json` untuk menemukan nama file yang ber-hash konten dari aset yang dikompilasi dan menghasilkan tag yang sesuai yang menunjuk ke file statis tersebut. Anda menulis satu directive dan kedua mode bekerja secara otomatis.

Setelah perubahan, file `layout.blade.php` lengkap terlihat seperti ini:

```blade
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title ?? 'Catatku' }}</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>

<body class="bg-gray-50 min-h-screen">

    <nav class="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div class="max-w-2xl mx-auto px-4 py-3 flex items-center justify-between">
            <a href="/entries" class="text-xl font-bold text-gray-900 hover:text-gray-700">
                Catatku 📓
            </a>
            <div class="flex items-center gap-4">
                @auth
                <span class="text-sm text-gray-500">{{ auth()->user()->name }}</span>
                <form method="POST" action="/logout">
                    @csrf
                    <button type="submit" class="text-sm text-gray-500 hover:text-gray-900 transition-colors">
                        Logout
                    </button>
                </form>
                @else
                <a href="/login" class="text-sm text-gray-600 hover:text-gray-900">Log In</a>
                <a href="/register"
                    class="text-sm bg-gray-900 text-white px-3 py-1.5 rounded-lg hover:bg-gray-700 transition-colors">
                    Register
                </a>
                @endauth
            </div>
        </div>
    </nav>

    <main class="max-w-2xl mx-auto px-4 py-8">

        @if (session('success'))
            <x-alert type="success">
                {{ session('success') }}
            </x-alert>
        @endif

        @if (session('error'))
            <x-alert type="error">
                {{ session('error') }}
            </x-alert>
        @endif

        {{ $slot }}
    </main>

</body>

</html>
```

---

## 4. Migrasi View ke Tailwind

Dengan Vite sekarang menyuplai CSS, langkah berikutnya adalah memperbarui view sehingga mereka memanfaatkannya sepenuhnya. Section ini memigrasikan view index entri dan component entry card dari inline style ke utility class Tailwind.

### Step 1: Memperbarui View Index Entri

Buka `resources/views/entries/index.blade.php` dan ganti kontennya dengan berikut.

```
<x-layout title="My Entries — Catatku">

    <div class="flex items-center justify-between mb-6">
        <h2 class="text-lg font-semibold text-gray-900">My Entries</h2>
        <a href="{{ route('entries.create') }}"
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
                <p class="text-sm text-gray-400 mt-1">Start writing your first entry!</p>
                <a href="{{ route('entries.create') }}" class="inline-block mt-4 text-sm text-blue-600 hover:underline">
                    Write now →
                </a>
            </div>
        @endforelse
    </div>

    <div class="mt-6">
        {{ $entries->links() }}
    </div>

</x-layout>
```

Prop `title="My Entries — Catatku"` meneruskan title halaman ke component layout, yang menggunakannya di tag `<title>{{ $title ?? 'Catatku' }}</title>`. Directive `@forelse` menangani kedua kasus dalam satu blok: ketika entri ada ia merender loop, dan ketika daftar kosong ia menampilkan prompt kondisi-kosong yang terpusat. Utility `space-y-4` pada div kontainer menambahkan spasi vertikal yang konsisten antar entry card tanpa memerlukan sebuah class `mb-4` pada setiap component card. Pemanggilan `{{ $entries->links() }}` merender kontrol pagination di bagian bawah; ini berfungsi karena method `index()` di `EntryController` menggunakan `paginate(15)` alih-alih `get()`.

### Step 2: Memperbarui Entry Card Component

Buka `resources/views/components/entry-card.blade.php` dan ganti semua inline style dengan class Tailwind. Pembaruan ini mempertahankan tombol aksi Read, Edit, dan Delete dari lesson sebelumnya.

```
<div class="bg-white rounded-xl border border-gray-200 p-4 hover:border-gray-300 transition-colors">

    <div class="flex items-start justify-between gap-3 mb-3">
        <a href="{{ route('entries.show', $entry) }}"
            class="font-semibold text-gray-900 hover:text-gray-600 leading-snug">
            {{ $truncatedTitle() }}
        </a>
        <span class="text-xs text-gray-400 whitespace-nowrap mt-0.5">
            {{ $entry->created_at->format('d M Y') }}
        </span>
    </div>

    <p class="text-sm text-gray-500 line-clamp-2 mb-2">
        {{ $entry->excerpt }}
    </p>

    <span class="text-xs text-gray-400">
        {{ $entry->reading_time }} min read
    </span>

    @if($entry->tags->isNotEmpty())
        <div class="mt-2 flex flex-wrap gap-1">
            @foreach($entry->tags as $tag)
                <span class="bg-blue-100 text-blue-800 text-xs px-2 py-0.5 rounded-full font-semibold">
                    {{ $tag->name }}
                </span>
            @endforeach
        </div>
    @endif

    <div class="flex items-center gap-3 pt-3 border-t border-gray-100 mt-3">
        <a href="{{ route('entries.show', $entry) }}" class="text-xs text-blue-600 hover:text-blue-800">
            Read
        </a>
        @can('update', $entry)
            <a href="{{ route('entries.edit', $entry) }}" class="text-xs text-amber-500 hover:text-amber-700">
                Edit
            </a>
        @endcan
        @can('delete', $entry)
            <form method="POST" action="{{ route('entries.destroy', $entry) }}" class="inline">
                @csrf
                @method('DELETE')
                <button type="submit" onclick="return confirm('Delete this entry?')"
                    class="text-xs text-red-600 hover:text-red-800 bg-transparent border-0 cursor-pointer p-0">
                    Delete
                </button>
            </form>
        @endcan
    </div>

</div>
```

Setiap attribute `style` inline dari versi lesson-15 sekarang adalah sebuah utility class Tailwind. Class `bg-white rounded-xl border border-gray-200` pada div terluar menggantikan border dan background CSS mentah. Pasangan `hover:border-gray-300 transition-colors` menganimasikan warna border saat hover, membuat card terasa interaktif. Baris tombol aksi di bagian bawah menggunakan `@can('update', $entry)` dan `@can('delete', $entry)` untuk menampilkan tombol hanya untuk pemilik entri, yang merupakan Policy dari Lesson 5. Form Delete menggunakan `bg-transparent border-0 cursor-pointer p-0` untuk menghilangkan tampilan tombol default tanpa menambahkan aturan reset CSS terpisah.

---

## 5. Menjalankan dan Menguji

Dengan Vite terkonfigurasi dan view dimigrasikan ke Tailwind, Anda membutuhkan dua proses berjalan secara bersamaan: Laravel dev server dan Vite dev server. Langkah di bawah ini memandu Anda memulai keduanya, memverifikasi hot reload bekerja, dan melakukan build untuk production.

### Step 1: Menjalankan Vite Dev Server

Buka terminal baru (biarkan `php artisan serve` berjalan di yang lain) dan jalankan perintah berikut.

```bash
npm run dev
```

Anda seharusnya melihat output yang mengonfirmasi Vite siap.

```
VITE v5.0 ready in 300 ms
➜  Local:   http://localhost:5173/
```

Vite sekarang mengawasi file Anda. Ketika Anda mengedit sebuah Blade view, file CSS, atau file JavaScript, browser memperbarui hampir seketika tanpa refresh manual.

### Step 2: Memuat Halaman

Navigasikan ke `http://localhost:8000/entries`. Halaman seharusnya dirender dengan styling Tailwind: header baru, tombol biru, background abu-abu, dan entry card yang diberi style. Jika Anda melihat HTML tanpa style (teks hitam polos pada background putih), verifikasi bahwa directive `@vite(...)` ada di layout Anda dan bahwa baik `php artisan serve` maupun `npm run dev` berjalan secara bersamaan.

### Step 3: Menguji Hot Reload

Buka `resources/views/entries/index.blade.php` dan ubah class heading dari `text-lg` menjadi `text-xl` pada tag `<h2>`. Simpan file. Browser seharusnya memperbarui hampir seketika tanpa refresh manual, menampilkan heading yang sedikit lebih besar. Ini mengonfirmasi fitur hot reload Vite aktif, dan Anda dapat mengembalikan class kembali ke `text-lg` setelah mengonfirmasi.

### Step 4: Build untuk Production

Ketika Anda siap menguji output production, jalankan berikut.

```bash
npm run build
```

Perintah ini mengompilasi semuanya menjadi bundle yang dioptimalkan di direktori `public/build/` dengan nama file yang ber-hash konten (seperti `app-abc123.css`) untuk cache busting browser. Jalankan ini sebelum setiap deployment production sehingga directive `@vite(...)` mengambil file yang sudah di-build. Di production, tidak ada Vite dev server yang berjalan; file dilayani sebagai aset statis oleh web server Anda.

---

## 6. Memperbaiki Error pada Kode Anda

Berikut adalah kesalahan paling umum saat menyiapkan Vite dan Tailwind di sebuah proyek Laravel.

**Error 1: Path file Blade tidak tercakup oleh directive `@source` di `app.css`.**

Error ini terjadi ketika Tailwind tidak dapat menemukan nama class di file Blade Anda karena path file tidak dideklarasikan di sebuah directive `@source`. Tailwind v4 memindai hanya file yang cocok dengan pola yang terdaftar di deklarasi `@source` dan menghasilkan CSS hanya untuk class yang ditemukannya. Jika sebuah path hilang, class tersebut absen dari output dan halaman yang terpengaruh dirender tanpa style.

```css
/* Wrong: no @source pointing to Blade files */
@import 'tailwindcss';

/* Tailwind scans nothing — all utility classes missing from output */

/* Correct: declare @source directives covering Blade and JS files */
@import 'tailwindcss';

@source '../**/*.blade.php';
@source '../**/*.js';
```

Versi yang salah mengimpor Tailwind tetapi tidak mendeklarasikan path `@source` apa pun, sehingga Tailwind tidak memiliki file untuk dipindai untuk nama class. CSS yang dihasilkan hanya berisi style reset dasar tanpa utility class. Versi yang benar menambahkan deklarasi `@source` yang mencakup semua Blade view dan file JavaScript di direktori `resources/`. Setelah menambahkan path source yang hilang, restart `npm run dev` untuk memicu rebuild penuh.

---

**Error 2: Menggunakan nama class dinamis yang tidak dapat dideteksi Tailwind.**

Error ini terjadi ketika Anda menyusun sebuah nama class dengan menggabungkan variabel PHP dengan fragmen string. Tailwind memindai file sebagai teks mentah dan tidak dapat mengevaluasi ekspresi PHP, sehingga sebuah nama class parsial seperti `bg-{{ $color }}-500` tidak pernah dikenali sebagai `bg-red-500` atau `bg-blue-500`.

```blade
{{-- Wrong: Tailwind cannot detect the full class name in the source text --}}
<div class="bg-{{ $color }}-500">...</div>

{{-- Correct: use complete class names in conditional expressions --}}
<div class="{{ $color === 'red' ? 'bg-red-500' : 'bg-blue-500' }}">...</div>
```

Versi yang salah menghasilkan `bg-red-500` saat runtime, tetapi Tailwind tidak pernah melihat `bg-red-500` di file source karena ia hanya melihat fragmen `bg-`. Versi yang benar menggunakan sebuah ekspresi ternary dengan nama class lengkap sebagai kedua cabang. Scanner Tailwind menemukan `bg-red-500` dan `bg-blue-500` sebagai string lengkap di file dan menghasilkan CSS untuk keduanya.

---

**Error 3: Lupa menjalankan `npm run build` sebelum melakukan deploy ke production.**

Error ini terjadi ketika server production tidak memiliki aset yang sudah di-build di `public/build/`. Directive `@vite(...)` dalam mode production membaca file manifest di `public/build/manifest.json` untuk menemukan nama file aset yang benar. Jika `public/build/` tidak ada, Vite melemparkan sebuah exception pada setiap request halaman.

```bash
# Wrong: deploy code without building assets first
git push origin main
# Deploy completes, but public/build/ is empty or missing
# Result: every page throws "Vite manifest not found" exception

# Correct: build assets as part of the deployment script
npm ci && npm run build
# Then deploy, so public/build/ contains the compiled files
```

Versi yang salah melewati langkah build. Directive `@vite(...)` mencoba membaca `public/build/manifest.json`, menemukan file hilang, dan melemparkan sebuah exception yang terlihat oleh setiap user. Versi yang benar menjalankan `npm ci` (menginstal dependensi yang terkunci) diikuti oleh `npm run build` sebelum atau selama deployment, memastikan `public/build/` berisi CSS, JavaScript, dan manifest yang dikompilasi. Tambahkan ini sebagai sebuah langkah di skrip deploy Anda sehingga ia berjalan secara otomatis setiap kali.

---

## 7. Latihan

Berlatihlah memigrasikan dan mengembangkan setup Tailwind secara independen menggunakan pola dari lesson ini.

**Latihan 1:** Migrasikan view show entri (`resources/views/entries/show.blade.php`) ke Tailwind. Ganti semua inline style dengan utility class, dan tambahkan sebuah section tampilan cover image yang menggunakan `object-cover` dan `rounded-lg`.

**Latihan 2:** Tambahkan sebuah toggle dark mode. Tambahkan varian `dark:` ke class kunci (misalnya `bg-white dark:bg-gray-900`) dan tambahkan sebuah tombol yang men-toggle class `dark` pada elemen `<html>` menggunakan sebuah snippet JavaScript kecil.

**Latihan 3:** Buat sebuah class component kustom menggunakan `@layer components` di `resources/css/app.css` sehingga `<button class="btn-primary">` bekerja tanpa mengulang seluruh kumpulan utility class pada setiap tombol.

---

## 8. Solusi

Bandingkan implementasi Anda dengan yang di bawah. Fokus pada bagaimana `object-cover` menjaga gambar tetap proporsional, bagaimana `@custom-variant dark` mengaktifkan dark mode berbasis class di Tailwind v4, dan mengapa `@layer components` tepat untuk kombinasi utility yang berulang.

**Solusi untuk Latihan 1:**

Buka `resources/views/entries/show.blade.php` dan ganti kontennya dengan berikut.

```blade
<x-layout>
    <div class="max-w-2xl mx-auto">
        @if($entry->cover_image)
            <img
                src="{{ Storage::url($entry->cover_image) }}"
                alt="Cover image"
                class="w-full h-64 object-cover rounded-lg mb-6"
            >
        @endif

        <div class="flex items-center justify-between mb-4">
            <h1 class="text-3xl font-bold text-gray-900">{{ $entry->title }}</h1>
            @can('update', $entry)
                <a href="{{ route('entries.edit', $entry) }}"
                   class="text-sm text-brand-600 hover:text-brand-700 font-medium">
                    Edit
                </a>
            @endcan
        </div>

        <div class="flex items-center gap-4 text-sm text-gray-400 mb-6">
            <span>{{ $entry->reading_time }} min read</span>
            <span>{{ $entry->created_at->diffForHumans() }}</span>
        </div>

        @if($entry->tags->isNotEmpty())
            <div class="flex flex-wrap gap-2 mb-6">
                @foreach($entry->tags as $tag)
                    <span class="bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded-full">
                        {{ $tag->name }}
                    </span>
                @endforeach
            </div>
        @endif

        <div class="text-gray-700 leading-relaxed whitespace-pre-line mb-8">
            {{ $entry->content }}
        </div>
    </div>
</x-layout>
```

Class `object-cover` pada gambar membuatnya mengisi kontainer (`w-full h-64`) tanpa mendistorsi rasio aspek, memotong tepinya sebagai gantinya. Ini adalah perilaku yang benar untuk sebuah hero/cover image di mana tinggi yang konsisten lebih penting daripada menampilkan gambar penuh. Class `rounded-lg` memberinya sudut yang lembut yang cocok dengan style card di halaman index. Class `whitespace-pre-line` pada div content mempertahankan line break dari teks yang disimpan sehingga paragraf ditampilkan dengan benar tanpa memerlukan markup HTML.

---

**Solusi untuk Latihan 2:**

Pertama, aktifkan dark mode berbasis class dengan menambahkan sebuah directive `@custom-variant` ke `resources/css/app.css`, setelah baris `@import`.

```css
@import 'tailwindcss';

@custom-variant dark (&:where(.dark, .dark *));
```

Ini adalah cara Tailwind v4 mengaktifkan dark mode berbasis class. Deklarasi `@custom-variant dark` memberi tahu Tailwind bahwa prefix `dark:` seharusnya cocok dengan elemen yang berada di dalam sebuah ancestor dengan class `dark`, yang itulah yang diekspresikan `&:where(.dark, .dark *)` sebagai sebuah CSS selector. Tidak ada perubahan file konfigurasi yang dibutuhkan.

Buka `resources/views/components/layout.blade.php` dan tambahkan varian `dark:` ke elemen layout kunci, ditambah sebuah tombol toggle di nav.

```blade
<body class="bg-gray-50 dark:bg-gray-900 text-gray-800 dark:text-gray-100 font-sans antialiased">
    <nav class="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 px-4 py-3">
        <div class="max-w-4xl mx-auto flex items-center justify-between">
            <a href="/" class="text-xl font-bold text-brand-700 dark:text-brand-500">Catatku</a>
            <div class="flex items-center gap-4">
                <button
                    onclick="document.documentElement.classList.toggle('dark')"
                    class="text-sm text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
                >
                    Toggle Dark
                </button>
                @auth
                    <form method="POST" action="{{ route('logout') }}">
                        @csrf
                        <button type="submit" class="text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white">
                            Logout
                        </button>
                    </form>
                @endauth
            </div>
        </div>
    </nav>

    <main class="max-w-4xl mx-auto p-4">
        {{ $slot }}
    </main>
</body>
```

Directive `@custom-variant dark` yang ditambahkan ke `app.css` memberi tahu Tailwind untuk mengaktifkan varian `dark:` hanya ketika sebuah elemen ancestor memiliki class `dark`, yang itulah yang ditentukan selector `&:where(.dark, .dark *)`. Handler `onclick` tombol toggle menambahkan atau menghapus class `dark` pada `document.documentElement` (tag `<html>`). Untuk mempertahankan preferensi di antara pemuatan halaman, kembangkan script untuk menyimpan kondisi di `localStorage` dan memulihkannya saat pemuatan halaman. Tanpa persistensi, dark mode reset pada setiap navigasi.

---

**Solusi untuk Latihan 3:**

Buka `resources/css/app.css` dan tambahkan class component kustom di dalam sebuah blok `@layer components`, setelah baris `@import` yang ada.

```css
@import 'tailwindcss';

@layer components {
    .btn-primary {
        @apply bg-brand-600 hover:bg-brand-700 text-white px-5 py-2 rounded-md font-semibold transition;
    }

    .btn-danger {
        @apply bg-red-600 hover:bg-red-700 text-white px-5 py-2 rounded-md font-semibold transition;
    }
}
```

Directive `@apply` memungkinkan Anda menyusun utility Tailwind di dalam sebuah class CSS kustom. Sekarang elemen mana pun dapat menggunakan `class="btn-primary"` alih-alih string utility lengkap. Tailwind memproses instruksi `@apply` dan menyisipkan style utility yang direferensikan ke dalam class kustom Anda di CSS output. Pendekatan ini paling baik untuk elemen yang Anda ulang sangat sering (seperti tombol) di mana mengetik string utility lengkap setiap kali tidak praktis. Namun, untuk sebagian besar component, pendekatan Blade component dari Lesson 15 lebih disukai karena ia menjaga keputusan styling tetap di dalam satu file component.

---

## Selanjutnya - Lesson 17

Di lesson ini Anda menyiapkan sebuah pipeline build frontend lengkap untuk Catatku. Anda menjalankan `npm install` untuk mengonfirmasi semua dependensi, memverifikasi entry point `@import 'tailwindcss'` di `resources/css/app.css`, menambahkan token warna brand menggunakan blok `@theme {}`, mengonfirmasi setup `vite.config.js` dengan plugin `@tailwindcss/vite`, dan mengganti tag script CDN di layout Anda dengan directive `@vite([...])`. Anda memigrasikan view index entri untuk menggunakan `<x-entry-card>` dan link pagination, memperbarui template entry card component untuk menggunakan utility class Tailwind alih-alih inline style, dan menjalankan `npm run dev` untuk mengaktifkan hot reloading dengan refresh browser instan pada setiap penyimpanan file.

Di Lesson 17, Anda akan mempelajari deploy ke production: bagaimana mengonfigurasi environment dengan aman, menjalankan perintah optimasi, menjaga queue worker tetap berjalan dengan Supervisor, dan menyiapkan Nginx untuk HTTPS dengan deployment tanpa downtime.
