Lesson-lesson sebelumnya telah membawa kita cukup jauh. Model `Entry` sudah terhubung ke database, relasi ke `User` sudah didefinisikan, dan controller sudah bisa mengambil data sungguhan. Namun jika Anda membuka aplikasi sekarang, tampilannya masih terasa mentah: struktur HTML yang berantakan, navigasi yang tidak konsisten, dan setiap halaman baru yang kita buat di masa depan akan memaksa kita mengulang boilerplate yang sama dari awal.

Lesson ini akan memperbaiki hal tersebut.

## Ringkasan {#overview}

### Apa yang Akan Anda Bangun

Pada akhir lesson ini, aplikasi akan memiliki dua halaman yang berfungsi penuh: halaman daftar entri dan halaman detail entri. Keduanya akan berbagi layout yang sama dengan navigasi yang konsisten, dukungan flash message, dan struktur visual yang bersih. Ini merupakan lompatan visual yang signifikan dibandingkan dengan apa yang kita miliki sekarang.

### Apa yang Akan Anda Pelajari

- Cara membuat layout yang reusable menggunakan Blade components dan mekanisme `{{ $slot }}`
- Cara mengekstrak elemen UI yang berulang menjadi component mandiri seperti `EntryCard`
- Cara menggunakan directive `@props` untuk mengoper data ke dalam component
- Cara membangun halaman detail entri dengan method controller `show()`
- Apa itu Route Model Binding dan bagaimana cara kerjanya secara otomatis mengonversi parameter URL menjadi objek Eloquent
- Cara melindungi sebuah halaman agar hanya pemilik entri yang dapat mengaksesnya menggunakan `abort(403)`
- Directive Blade untuk tampilan kondisional: `@auth`, `@else`, `@endauth`

### Apa yang Anda Butuhkan

- Proyek `catatku` terbuka di VS Code dengan development server yang sedang berjalan
- Controller yang sudah terhubung ke database dan view daftar entri dari lesson-lesson sebelumnya
- Data seed yang sudah dimasukkan melalui Tinker dari Lesson 6 sehingga Anda memiliki entri untuk ditampilkan

---

## Step 1: Membuat Layout Utama {#step-1-create-the-main-layout}

Saat ini, `entries/index.blade.php` mencampurkan semuanya menjadi satu: struktur HTML lengkap, navigasi, dan logika daftar entri. Ketika kita membuat halaman detail, form pembuatan, dan halaman login nanti, semuanya akan membutuhkan navigasi yang sama. Kita akan berakhir dengan menyalin dan menempelkan HTML yang sama berulang-ulang.

**Blade components** mengatasi masalah ini dengan memungkinkan kita memecah HTML menjadi bagian-bagian yang reusable. Bagian terpenting adalah layout: sebuah wrapper yang menyediakan kerangka HTML, navigasi, dan elemen umum, sambil menyisakan "lubang" bagi setiap halaman untuk diisi dengan kontennya sendiri.

Buat file `resources/views/components/layout.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title ?? 'Catatku' }}</title>
    <script src="https://unpkg.com/@tailwindcss/browser@4"></script>
</head>
<body class="bg-gray-50 min-h-screen">

    {{-- Navigation --}}
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
                        <button type="submit"
                            class="text-sm text-gray-500 hover:text-gray-900 transition-colors">
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

    {{-- Page content --}}
    <main class="max-w-2xl mx-auto px-4 py-8">

        {{-- Flash success message --}}
        @if (session('success'))
            <div class="mb-6 p-4 bg-green-50 border border-green-200 text-green-800 text-sm rounded-xl">
                {{ session('success') }}
            </div>
        @endif

        {{ $slot }}
    </main>

</body>
</html>
```

Ada beberapa bagian penting dalam layout ini:

`{{ $title ?? 'Catatku' }}` adalah judul halaman. `??` adalah null coalescing operator milik PHP. Jika sebuah halaman mengoper nilai `title`, nilai tersebut akan digunakan. Jika tidak, nilainya akan kembali ke "Catatku". Hal ini memungkinkan setiap halaman menyesuaikan judul tab browsernya sendiri.

`@auth ... @else ... @endauth` adalah directive Blade yang memeriksa status login pengguna. Blok `@auth` ditampilkan ketika pengguna sudah login (menampilkan nama mereka dan tombol logout). Blok `@else` ditampilkan ketika mereka belum login (menampilkan link login dan register). Karena kita belum membangun sistem authentication, Anda akan selalu melihat blok `@else` untuk saat ini.

`@if (session('success'))` memeriksa flash message di dalam session. Setelah menyimpan, memperbarui, atau menghapus sebuah entri, kita akan melakukan redirect dengan pesan sukses. Blok ini menampilkan pesan tersebut di bagian atas halaman. Kita akan menggunakan ini mulai dari lesson berikutnya.

`{{ $slot }}` adalah bagian paling penting. Ini adalah "lubang" tempat konten dari halaman yang menggunakan layout ini akan dimasukkan. Ketika sebuah view membungkus kontennya dalam `<x-layout>...</x-layout>`, segala sesuatu di antara tag-tag tersebut menjadi nilai dari `$slot`.

---

## Step 2: Membuat Component EntryCard {#step-2-create-the-entrycard-component}

Setiap entri dalam daftar ditampilkan sebagai sebuah card dengan judul, tanggal, cuplikan konten, dan tombol aksi. Daripada meletakkan semua HTML tersebut langsung di dalam view daftar, kita akan mengekstraknya menjadi component-nya sendiri. Dengan cara ini, jika kita perlu mengubah tampilan card entri di kemudian hari, kita cukup mengubahnya di satu tempat.

Buat file `resources/views/components/entry-card.blade.php`:

```html
@props(['entry'])

<div class="bg-white rounded-xl border border-gray-200 p-5 hover:border-gray-300 transition-colors">

    {{-- Header: title and date --}}
    <div class="flex items-start justify-between gap-3 mb-3">
        <a href="/entries/{{ $entry->id }}"
           class="font-semibold text-gray-900 hover:text-gray-600 leading-snug">
            {{ $entry->title }}
        </a>
        <span class="text-xs text-gray-400 whitespace-nowrap mt-0.5">
            {{ $entry->created_at->format('d M Y') }}
        </span>
    </div>

    {{-- Content snippet --}}
    <p class="text-sm text-gray-500 line-clamp-2 mb-4">
        {{ $entry->content }}
    </p>

    {{-- Action buttons --}}
    <div class="flex items-center gap-3 pt-3 border-t border-gray-100">
        <a href="/entries/{{ $entry->id }}"
           class="text-xs text-blue-600 hover:text-blue-800">
            Read
        </a>
        <a href="/entries/{{ $entry->id }}/edit"
           class="text-xs text-gray-500 hover:text-gray-800">
            Edit
        </a>
        <form method="POST" action="/entries/{{ $entry->id }}"
              onsubmit="return confirm('Delete this entry?')"
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

`@props(['entry'])` mendeklarasikan bahwa component ini membutuhkan sebuah prop `entry`. Ketika kita menggunakan component ini, kita akan mengoper entri seperti ini: `<x-entry-card :entry="$entry" />`. Tanda titik dua sebelum `entry` memberi tahu Blade untuk mengevaluasi nilainya sebagai ekspresi PHP, bukan memperlakukannya sebagai string biasa.

Card ini mencakup link ke halaman detail (`/entries/{{ $entry->id }}`), halaman edit, dan form delete. Fungsi edit dan delete belum akan berfungsi karena kita belum membangun route-nya, tetapi UI-nya sudah tersedia. Form delete menggunakan `@method('DELETE')` karena form HTML secara native hanya mendukung GET dan POST. Directive Blade ini menambahkan field tersembunyi yang memberi tahu Laravel untuk memperlakukan submission form tersebut sebagai request DELETE.

---

## Step 3: Memperbarui View Daftar Entri {#step-3-update-the-entries-listing-view}

Sekarang perbarui `resources/views/entries/index.blade.php` agar menggunakan layout dan component entry card:

```html
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
                <a href="/entries/create"
                   class="inline-block mt-4 text-sm text-blue-600 hover:underline">
                    Write now →
                </a>
            </div>
        @endforelse
    </div>

</x-layout>
```

Bandingkan ini dengan versi sebelumnya. Seluruh struktur dokumen HTML, bagian `<head>`, dan navigasi sudah hilang. Semuanya kini berada di dalam component layout. View ini hanya berisi konten yang khusus untuk halaman daftar entri.

`<x-layout title="My Entries — Catatku">` membungkus konten halaman dalam component layout dan mengoper judul kustom untuk tab browser. Segala sesuatu di antara `<x-layout>` dan `</x-layout>` menjadi `{{ $slot }}` di dalam layout.

`<x-entry-card :entry="$entry" />` merender satu card entri untuk setiap entri dalam koleksi. Seluruh HTML card ditangani oleh component, sehingga view ini tetap fokus pada struktur level halaman.

---

## Step 4: Menambahkan Halaman Detail Entri {#step-4-add-the-entry-detail-page}

Pengguna perlu dapat membaca entri secara lengkap. Hal ini membutuhkan tiga hal: method controller, route, dan view.

Pertama, tambahkan method `show()` ke `EntryController`:

```php
public function show(Entry $entry)
{
    if ($entry->user_id !== auth()->id()) {
        abort(403);
    }

    return view('entries.show', compact('entry'));
}
```

Ada dua konsep penting dalam method singkat ini.

**Route Model Binding** adalah hal yang membuat parameter `Entry $entry` berfungsi. Ketika Laravel melihat parameter dengan type-hint di dalam method controller, Laravel secara otomatis mencari record database yang sesuai menggunakan nilai dari URL. Jika seseorang mengunjungi `/entries/5`, Laravel menjalankan `Entry::findOrFail(5)` di belakang layar dan menyuntikkan hasilnya sebagai `$entry`. Jika tidak ada entri dengan ID tersebut, Laravel secara otomatis mengembalikan error 404. Anda tidak perlu menulis kode pencarian apa pun sendiri.

**`abort(403)`** menghentikan eksekusi dan mengembalikan error "Forbidden". Pengecekan `if` memastikan bahwa hanya pemilik entri yang dapat melihat entrinya. Jika `$entry->user_id` tidak cocok dengan ID pengguna yang sedang terautentikasi, request akan diblokir.

> **Catatan:** Karena sistem authentication belum dibangun, pengunjung yang belum login dan mengakses URL detail entri secara langsung akan melihat error 403 (karena `auth()->id()` mengembalikan `null`, yang tidak akan pernah cocok dengan `user_id`). Ini bukanlah hal yang ideal. Pada Lesson 8, kita akan memindahkan route ini ke dalam grup `middleware('auth')`, yang akan mengarahkan tamu ke halaman login alih-alih menampilkan error 403. Untuk saat ini, pengecekan kepemilikannya sendiri sudah benar.

Selanjutnya, tambahkan route di `routes/web.php`. Letakkan setelah route `/entries` yang sudah ada:

```php
Route::get('/entries', [EntryController::class, 'index']);
Route::get('/entries/{entry}', [EntryController::class, 'show']);
```

Segmen `{entry}` di dalam URL adalah parameter route. Ini memberi tahu Laravel bahwa bagian URL ini bersifat dinamis. Ketika seseorang mengunjungi `/entries/3`, nilai `3` akan dioper ke method `show()`, di mana Route Model Binding mengonversinya menjadi objek `Entry`.

Terakhir, buat view di `resources/views/entries/show.blade.php`:

```html
<x-layout :title="$entry->title . ' — Catatku'">

    <div class="mb-6">
        <a href="/entries" class="text-sm text-gray-400 hover:text-gray-700">
            ← Back to list
        </a>
    </div>

    <article class="bg-white rounded-xl border border-gray-200 p-6">

        {{-- Header --}}
        <div class="mb-6">
            <h1 class="text-2xl font-bold text-gray-900 mb-2">
                {{ $entry->title }}
            </h1>
            <p class="text-sm text-gray-400">
                Written on {{ $entry->created_at->isoFormat('D MMMM Y') }}
                @if ($entry->updated_at->ne($entry->created_at))
                    · Updated {{ $entry->updated_at->diffForHumans() }}
                @endif
            </p>
        </div>

        {{-- Entry content --}}
        <div class="prose prose-gray max-w-none text-gray-700 leading-relaxed whitespace-pre-line">
            {{ $entry->content }}
        </div>

    </article>

    {{-- Action buttons --}}
    <div class="flex items-center gap-3 mt-4">
        <a href="/entries/{{ $entry->id }}/edit"
           class="text-sm bg-gray-900 text-white px-4 py-2 rounded-lg hover:bg-gray-700 transition-colors">
            Edit Entry
        </a>
        <form method="POST" action="/entries/{{ $entry->id }}"
              onsubmit="return confirm('Delete this entry?')">
            @csrf
            @method('DELETE')
            <button type="submit"
                class="text-sm text-red-500 hover:text-red-700 transition-colors">
                Delete
            </button>
        </form>
    </div>

</x-layout>
```

Ada beberapa hal yang perlu diperhatikan dalam template ini:

`:title="$entry->title . ' — Catatku'"` mengoper judul halaman sebagai ekspresi PHP (perhatikan tanda titik dua di depannya). Ini mengatur tab browser menjadi sesuatu seperti "My first entry - Catatku", yang lebih deskriptif dibandingkan judul generik.

`$entry->created_at->isoFormat('D MMMM Y')` menggunakan method `isoFormat()` milik Carbon, yang menghasilkan output tanggal yang locale-aware seperti "20 February 2026".

`$entry->updated_at->ne($entry->created_at)` memeriksa apakah entri telah diedit setelah pertama kali dibuat. Method `ne()` (singkatan dari "not equal") membandingkan dua tanggal Carbon. Jika keduanya berbeda, template akan menampilkan "Updated 2 hours ago" (atau berapa lama yang lalu editan tersebut dilakukan). Method `diffForHumans()` menghasilkan string waktu relatif yang mudah dibaca manusia secara otomatis.

`whitespace-pre-line` adalah class Tailwind CSS yang mempertahankan line break dalam teks. Tanpa class ini, karakter newline (`\n`) dalam konten akan diabaikan oleh HTML, dan entri multi-paragraf akan tampil sebagai satu blok teks tunggal.

---

## Step 5: Melihat Hasilnya {#step-5-view-the-result}

Pastikan development server sedang berjalan, lalu buka `http://127.0.0.1:8000/entries` di browser Anda.

![entries page after implement layout](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/06-implement-layout.webp)

Anda akan melihat halaman daftar dengan layout baru: navigation bar yang sticky di bagian atas, card entri dengan tombol aksi, dan struktur visual yang bersih. Data seed yang Anda masukkan di Lesson 6 akan ditampilkan sebagai card entri. Mengklik link "Read" atau judul entri pada card mana pun akan membawa Anda ke halaman detail untuk entri tersebut.
![error 403 when access entry detail  page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/07-error-403.webp)
Karena kita belum login, mengklik tombol "Read" akan menghasilkan error 403 Forbidden.

Kedua halaman berbagi component layout yang sama, sehingga navigasi, lebar halaman, dan kesan keseluruhan tetap konsisten di seluruh aplikasi.

---

## Cara Kerja Blade Components {#how-blade-components-work}

Sekarang setelah Anda membangun dan menggunakan beberapa Blade components, mari kita pahami mekanisme di baliknya.

File `.blade.php` mana pun di dalam `resources/views/components/` secara otomatis menjadi sebuah Blade component. Nama file menentukan nama tag-nya: `layout.blade.php` menjadi `<x-layout>`, dan `entry-card.blade.php` menjadi `<x-entry-card>`. Prefix `x-` adalah cara Blade mengidentifikasi tag component.

Component menerima data dengan dua cara. **Slots** adalah konten yang diletakkan di antara tag pembuka dan penutup. Apa pun yang Anda tulis di antara `<x-layout>` dan `</x-layout>` menjadi `{{ $slot }}` di dalam component. **Props** adalah atribut bernama yang Anda oper ke component, seperti `:entry="$entry"` pada `<x-entry-card>`. Directive `@props` di bagian atas sebuah component mendeklarasikan prop apa saja yang diterima.

Prefix titik dua pada atribut itu penting. Tanpa titik dua (`title="My Page"`), nilainya diperlakukan sebagai string literal. Dengan titik dua (`:title="$entry->title"`), nilainya dievaluasi sebagai ekspresi PHP. Inilah cara Anda mengoper variabel dan nilai dinamis ke component.

---

## Cara Kerja Route Model Binding {#how-route-model-binding-works}

Route Model Binding adalah salah satu fitur Laravel yang paling memudahkan. Ketika Anda memberi type-hint pada parameter controller dengan sebuah class model Eloquent, Laravel secara otomatis menyelesaikan parameter route tersebut menjadi sebuah instance model.

Route `Route::get('/entries/{entry}', ...)` mendefinisikan parameter bernama `{entry}`. Method controller `show(Entry $entry)` memberi type-hint pada parameter tersebut sebagai model `Entry`. Laravel menghubungkan keduanya: ia mengambil nilai dari URL (misalnya, `5`), menjalankan `Entry::findOrFail(5)`, dan mengoper hasilnya ke method Anda.

Jika record tersebut tidak ada, `findOrFail` akan melempar `ModelNotFoundException`, yang secara otomatis dikonversi oleh Laravel menjadi response 404. Anda tidak perlu menulis logika "record tidak ditemukan" sendiri.

Nama parameter di dalam route (`{entry}`) harus cocok dengan nama variabel di dalam signature method (`$entry`) agar binding ini dapat berfungsi.

---

## Kesimpulan {#conclusion}

Lesson ini mengubah cara kita membangun view dengan cara yang signifikan. Berikut adalah poin-poin pentingnya:

- **Blade components** memungkinkan Anda mengekstrak HTML yang reusable ke dalam file terpisah. File mana pun di dalam `resources/views/components/` secara otomatis menjadi component.
- **Component layout** (`<x-layout>`) menyediakan kerangka HTML, navigasi, dan dukungan flash message. Setiap halaman menggunakannya, sehingga perubahan pada layout langsung diterapkan ke mana-mana.
- `{{ $slot }}` adalah placeholder di dalam sebuah component tempat konten dari pemanggil dimasukkan. Segala sesuatu di antara `<x-layout>` dan `</x-layout>` menjadi slot tersebut.
- `@props(['entry'])` mendeklarasikan prop yang dibutuhkan untuk sebuah component. Prop dioper menggunakan atribut seperti `:entry="$entry"`, di mana prefix titik dua berarti nilainya adalah ekspresi PHP.
- **Component EntryCard** (`<x-entry-card>`) merangkum logika tampilan untuk satu entri, sehingga view daftar tetap fokus pada struktur halaman.
- **Route Model Binding** (`Entry $entry`) secara otomatis mengonversi parameter URL menjadi objek Eloquent. Jika record tidak ditemukan, Laravel mengembalikan 404.
- `abort(403)` menghentikan eksekusi dan mengembalikan response "Forbidden", menyediakan cara sederhana untuk memblokir akses yang tidak sah. Saat ini, pengunjung yang belum login akan melihat error 403. Ini akan ditingkatkan menjadi redirect ke login setelah kita menambahkan middleware `auth` di lesson berikutnya.
- `@method('DELETE')` menambahkan field form tersembunyi yang memberi tahu Laravel untuk memperlakukan submission POST sebagai request DELETE, karena form HTML secara native hanya mendukung GET dan POST.
- Method Carbon seperti `isoFormat()`, `diffForHumans()`, dan `ne()` membuat tampilan dan perbandingan tanggal menjadi mudah tanpa logika formatting manual.
- Class CSS `whitespace-pre-line` mempertahankan line break dalam konten teks, yang penting untuk menampilkan entri multi-paragraf dengan benar.

Pada lesson berikutnya, kita akan membangun form untuk membuat entri baru. Anda akan mempelajari cara menampilkan form, memvalidasi input pengguna, menyimpan data ke database, dan melakukan redirect dengan pesan sukses. Di sinilah Catatku benar-benar mulai hidup.
