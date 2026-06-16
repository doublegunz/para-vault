## 1. Sebelum Anda Memulai

Lihatlah Blade view Anda untuk Catatku. Kemungkinan besar Anda melihat pola yang berulang: styling tombol yang sama di beberapa tempat, kotak alert serupa dengan warna yang sedikit berbeda, entry card yang sama diulang di beberapa halaman. Menyalin dan menempel HTML menciptakan kerumitan pemeliharaan: ketika desain berubah, Anda mencari di setiap file untuk memperbarui setiap salinan. Blade component menyelesaikan ini dengan mengemas potongan UI yang dapat digunakan kembali ke dalam component bernama dengan parameter mereka sendiri.

Lesson ini mengajarkan Anda membuat Blade component, meneruskan data ke mereka melalui attribute, dan menggunakan slot untuk konten yang fleksibel. Anda sudah menggunakan component di template email (`<x-mail::button>` di Lesson 8). Sekarang Anda akan menerapkan ide yang sama ke view biasa. Di akhir, template Catatku akan lebih bersih, duplikasi akan hilang, dan perubahan desain akan memerlukan pengeditan satu file alih-alih sepuluh.

### What You'll Build

Anda akan membuat sebuah Button component, sebuah Alert component, dan sebuah EntryCard component. Anda akan menggunakan slot untuk konten yang fleksibel dan attribute passing untuk kustomisasi. Anda akan me-refactor view yang sudah ada untuk menggunakan component ini.

### What You'll Learn

- ✅ Membuat component dengan `make:component`
- ✅ Anonymous component (view-only) vs class-based component
- ✅ Meneruskan data melalui attribute dan constructor
- ✅ Default slot dan named slot
- ✅ `$attributes` untuk pass-through HTML attribute

### What You'll Need

- Lesson 14 sudah selesai

---

## 2. Anonymous Component

Component yang paling sederhana adalah sebuah file Blade di `resources/views/components/`. Tidak ada class PHP yang diperlukan. Ini disebut anonymous component karena mereka tidak memiliki class pendukung, hanya sebuah file template. Mereka sempurna untuk elemen UI yang tidak membutuhkan logika yang dikomputasi.

### Step 1: Membuat Button Component

Buat file `resources/views/components/button.blade.php` dengan konten berikut.

```
@props([
    'type' => 'button',
    'variant' => 'primary',
])

@php
    $classes = match($variant) {
        'primary' => 'background: #2563eb; color: white;',
        'danger' => 'background: #dc2626; color: white;',
        'secondary' => 'background: #e5e7eb; color: #1f2937;',
        default => 'background: #2563eb; color: white;',
    };
@endphp

<button
    type="{{ $type }}"
    {{ $attributes->merge(['style' => "padding: 8px 20px; border: none; border-radius: 6px; cursor: pointer; font-weight: bold; {$classes}"]) }}
>
    {{ $slot }}
</button>
```

Mari kita telusuri component ini dengan saksama karena ada beberapa fitur khusus Blade yang bekerja di sini. Directive `@props([...])` mendeklarasikan prop yang diterima dan nilai default-nya, serupa dengan signature sebuah fungsi. Component ini menerima dua prop: `type`, yang default-nya `"button"` (sehingga tombol biasa tidak secara tidak sengaja mengirim form), dan `variant`, yang default-nya `"primary"`. Prop secara otomatis diekstrak dari daftar attribute yang diteruskan oleh caller, sehingga menulis `<x-button variant="danger">` menempatkan `"danger"` ke dalam variabel `$variant` di dalam component.

Blok `@php ... @endphp` melakukan logika PHP inline untuk memetakan nama variant ke CSS inline menggunakan ekspresi `match` PHP 8. Ekspresi `match` lebih bersih daripada rantai if/elseif dan memerlukan pencocokan menyeluruh melalui klausa `default`. Tag `<button>` menggunakan `{{ $attributes->merge([...]) }}`, yang merupakan helper Blade yang mengambil HTML attribute apa pun yang tidak dikonsumsi oleh prop yang dideklarasikan (seperti `onclick`, `disabled`, atau `class`) dan menggabungkannya dengan style dasar. Mekanisme pass-through ini adalah yang membuat component fleksibel: caller dapat menambahkan HTML attribute apa pun dan ia mengalir ke elemen yang dirender. Akhirnya, `{{ $slot }}` merender konten apa pun yang ditempatkan caller di antara tag pembuka dan penutup.

### Step 2: Menggunakan Button Component

Buka `resources/views/entries/create.blade.php`. Di bagian bawah form pada section Buttons, ganti elemen mentah `<button type="submit">` dengan component.

```
<x-button type="submit" variant="primary">
    Save Entry
</x-button>
```

Sintaks `<x-button>` adalah cara Blade mereferensikan component. Prefix `x-` memberi tahu Blade bahwa ini adalah sebuah component, bukan elemen HTML native. Attribute `type` dan `variant` dipetakan ke prop yang dideklarasikan. Segala sesuatu di antara tag pembuka dan penutup menjadi konten `$slot`. Segarkan halaman di browser untuk mengonfirmasi tombol dirender dengan styling yang diharapkan.

Setelah perubahan, file `create.blade.php` lengkap terlihat seperti ini:

```blade
<x-layout title="Write Entry — Catatku">

    <div class="mb-6">
        <a href="{{ route('entries.index') }}" class="text-sm text-gray-400 hover:text-gray-700">
            ← Back to list
        </a>
    </div>

    <h2 class="text-lg font-semibold text-gray-900 mb-4">Write New Entry</h2>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
        <form method="POST" action="{{ route('entries.store') }}">
            @csrf

            <div class="mb-5">
                <label for="title" class="block text-sm font-medium text-gray-700 mb-1">
                    Title
                </label>
                <input type="text" id="title" name="title" value="{{ old('title') }}" placeholder="Entry title..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent
                           {{ $errors->has('title') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}" autofocus>
                @error('title')
                <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            <div class="mb-6">
                <label for="content" class="block text-sm font-medium text-gray-700 mb-1">
                    Content
                </label>
                <textarea id="content" name="content" rows="12" placeholder="Write your entry here..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent resize-y
                           {{ $errors->has('content') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}">{{ old('content') }}</textarea>
                @error('content')
                <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            <div class="flex items-center justify-between">
                <a href="{{ route('entries.index') }}" class="text-sm text-gray-500 hover:text-gray-900">
                    Cancel
                </a>
                <x-button type="submit" variant="primary">
                    Save Entry
                </x-button>
            </div>

        </form>
    </div>

</x-layout>
```

---

## 3. Component dengan Slot

Slot membuat component fleksibel. Variabel `$slot` menyimpan konten utama yang ditempatkan di antara tag component. Anda juga dapat mendefinisikan named slot untuk beberapa region konten. Ini sangat berguna untuk component mirip card yang membutuhkan section terpisah untuk title, body, dan footer.

### Step 1: Membuat Alert Component

Buat file `resources/views/components/alert.blade.php` dengan konten berikut.

```
@props([
    'type' => 'info',
])

@php
    $colors = match($type) {
        'success' => 'background: #dcfce7; color: #166534; border-left: 4px solid #16a34a;',
        'error' => 'background: #fee2e2; color: #991b1b; border-left: 4px solid #dc2626;',
        'warning' => 'background: #fef3c7; color: #92400e; border-left: 4px solid #d97706;',
        default => 'background: #dbeafe; color: #1e3a8a; border-left: 4px solid #2563eb;',
    };
@endphp

<div {{ $attributes->merge(['style' => "padding: 12px 16px; border-radius: 6px; margin-bottom: 16px; {$colors}"]) }}>
    @if (isset($title))
        <strong style="display: block; margin-bottom: 4px;">{{ $title }}</strong>
    @endif
    {{ $slot }}
</div>
```

Alert component memperkenalkan sebuah pola untuk named slot opsional. Pemeriksaan `@if (isset($title))` memverifikasi apakah caller menyediakan sebuah slot `title`. Jika ya, kita merendernya sebagai heading tebal di atas konten utama. Jika tidak, alert dirender hanya dengan body utama. Pola ini memungkinkan component yang sama melayani baik alert satu baris sederhana maupun alert yang lebih detail dengan title yang terlihat. Empat varian warna (success hijau, error merah, warning oranye, info biru default) menggunakan aksen `border-left` berwarna yang memperkuat makna semantik dari setiap tipe alert.

Untuk meneruskan sebuah named slot, sertakan tag `<x-slot:title>` di dalam tag component. Segala sesuatu di luar tag named slot secara otomatis mengisi `$slot` default.

```blade
<x-alert type="success">
    <x-slot:title>Entry Created!</x-slot:title>
    Your new entry has been saved successfully.
</x-alert>
```

Tag `<x-slot:title>` mengisi named slot `$title` di dalam component. Bagian `:title` menautkan ke nama variabel yang digunakan di pemeriksaan `isset($title)` di dalam template.

Ketika tidak ada slot `title` yang diteruskan, component dengan mulus melewati heading dan hanya merender teks body.

```blade
<x-alert type="error">
    Something went wrong. Please try again.
</x-alert>
```

Karena tidak ada tag `<x-slot:title>` yang ada, `isset($title)` mengembalikan false dan elemen heading dihilangkan sepenuhnya. Named slot selalu opsional ketika dijaga dengan `isset()`.

---

## 4. Class-Based Component

Beberapa component membutuhkan logika PHP: memformat data, membuat keputusan, atau menghitung nilai. Class-based component memungkinkan Anda mendefinisikan sebuah class PHP bersama template, menjaga logika kompleks tetap keluar dari template itu sendiri.

### Step 1: Membuat Component

Jalankan perintah Artisan berikut untuk membuat sebuah class-based component.

```bash
php artisan make:component EntryCard
```

Perintah ini membuat satu file baru: `app/View/Components/EntryCard.php`, class PHP yang berisi logika component. Anda akan melihat pesan sukses yang mengonfirmasi class dibuat.

Jika `resources/views/components/entry-card.blade.php` sudah ada dari course Catatku pemula, Laravel akan mencetak `ERROR  View already exists.` dan melewati pembuatan file view. Ini adalah perilaku yang diharapkan dan tidak mencegah Anda melanjutkan. File view yang sudah ada tetap di tempatnya, dan Anda akan mengganti kontennya sepenuhnya di Step 3. Output penting yang harus dikonfirmasi adalah `Component [app/View/Components/EntryCard.php] created successfully.`

### Step 2: Mendefinisikan Class Component

Buka `app/View/Components/EntryCard.php` dan ganti kontennya dengan berikut.

```php
<?php

namespace App\View\Components;

use App\Models\Entry;
use Illuminate\View\Component;
use Illuminate\View\View;

class EntryCard extends Component
{
    public function __construct(public Entry $entry) {}

    public function truncatedTitle(): string
    {
        return str($this->entry->title)->limit(50)->toString();
    }

    public function render(): View
    {
        return view('components.entry-card');
    }
}
```

Membaca class ini dengan cermat: constructor menggunakan property promotion untuk menerima dan menyimpan sebuah model Entry. Public property dan public method pada class component secara otomatis tersedia di dalam Blade template, itulah sebabnya kita dapat memanggil `{{ $truncatedTitle() }}` dari view tanpa meneruskannya secara eksplisit. Method `truncatedTitle()` menunjukkan cara menambahkan logika yang dikomputasi: ia menggunakan fluent string helper `str()` Laravel untuk membatasi title hingga 50 karakter, mengembalikan sebuah string biasa. Method `render()` memberi tahu Laravel template mana yang akan digunakan; menurut konvensi ia adalah versi kebab-case dari nama class di direktori `components`.

### Step 3: Menulis Template

Buka `resources/views/components/entry-card.blade.php` dan ganti kontennya dengan berikut. Template ini mempertahankan semua tombol aksi dari file yang ada (Read, Edit, Delete) dan menambahkan method `$truncatedTitle()` dari class.

```
<div style="border: 1px solid #e5e7eb; padding: 16px; margin-bottom: 12px; border-radius: 8px;">
    <div style="display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; margin-bottom: 8px;">
        <a href="{{ route('entries.show', $entry) }}"
           style="color: #1e293b; text-decoration: none; font-weight: 600; line-height: 1.4;">
            {{ $truncatedTitle() }}
        </a>
        <span style="font-size: 0.75em; color: #9ca3af; white-space: nowrap; margin-top: 2px;">
            {{ $entry->created_at->format('d M Y') }}
        </span>
    </div>

    <p style="color: #6b7280; margin: 0 0 8px; font-size: 0.9em; line-height: 1.5;">
        {{ $entry->excerpt }}
    </p>

    <span style="color: #9ca3af; font-size: 0.8em;">
        {{ $entry->reading_time }} min read
    </span>

    @if($entry->tags->isNotEmpty())
        <div style="margin-top: 8px;">
            @foreach($entry->tags as $tag)
                <span style="background: #dbeafe; color: #1e40af; padding: 2px 8px; border-radius: 12px; font-size: 0.75em;">
                    {{ $tag->name }}
                </span>
            @endforeach
        </div>
    @endif

    <div style="display: flex; align-items: center; gap: 12px; padding-top: 12px; border-top: 1px solid #f3f4f6; margin-top: 12px;">
        <a href="{{ route('entries.show', $entry) }}" style="font-size: 0.75em; color: #2563eb;">
            Read
        </a>
        @can('update', $entry)
            <a href="{{ route('entries.edit', $entry) }}" style="font-size: 0.75em; color: #d97706; text-decoration: none;">
                Edit
            </a>
        @endcan
        @can('delete', $entry)
            <form method="POST" action="{{ route('entries.destroy', $entry) }}" style="display: inline;">
                @csrf
                @method('DELETE')
                <button type="submit" onclick="return confirm('Delete this entry?')"
                    style="font-size: 0.75em; color: #dc2626; background: none; border: none; cursor: pointer; padding: 0;">
                    Delete
                </button>
            </form>
        @endcan
    </div>
</div>
```

Template menggunakan `$entry` (public property yang dipromosikan constructor) dan memanggil `$truncatedTitle()` (public method dari class). Keduanya tersedia di template secara otomatis. Nilai `$entry->excerpt` dan `$entry->reading_time` berasal dari accessor yang didefinisikan di Lesson 3. Tombol aksi di bagian bawah dibungkus dalam directive `@can('update', $entry)` dan `@can('delete', $entry)` dari Policy yang diperkenalkan di Lesson 5, sehingga setiap tombol hanya dirender untuk user yang diizinkan melakukan aksi tersebut.

### Step 4: Memverifikasi Penggunaan Entry Card

Buka `resources/views/entries/index.blade.php`. Jika Anda menyelesaikan course Catatku pemula, loop entri sudah menggunakan component dan tidak diperlukan perubahan di sini. Beginilah tampilan loop tersebut:

```blade
@foreach($entries as $entry)
    <x-entry-card :entry="$entry" />
@endforeach
```

Sintaks `:entry="$entry"` (dengan prefix titik dua) mengevaluasi ekspresi PHP dan meneruskan objek Entry yang sebenarnya ke constructor component. Tanpa titik dua, nilai attribute akan diperlakukan sebagai string literal `"$entry"` alih-alih variabel. Tag yang menutup sendiri `<x-entry-card ... />` digunakan karena kita tidak membutuhkan konten slot apa pun; semuanya digerakkan oleh prop.

---

## 5. Menjalankan dan Menguji

Dengan ketiga component berada di tempatnya, jalankan server dan verifikasi masing-masing dirender dengan benar. Perhatikan perilaku attribute pass-through dan visibilitas named slot, karena itu adalah area yang paling umum di mana kesalahan halus muncul.

### Step 1: Mengunjungi Index Entri

Jalankan server dan muat `/entries`. Anda seharusnya melihat entry card yang dirender oleh component, terlihat identik dengan sebelum refactor. Coba ubah warna border di template component dari `#e5e7eb` menjadi merah, simpan file, dan segarkan: setiap card di halaman mencerminkan perubahan seketika, membuktikan bahwa pendekatan single-source-of-truth bekerja.

### Step 2: Menguji Alert Component

Buka `resources/views/components/layout.blade.php`. Layout sudah berisi sebuah blok flash success menggunakan `<div>` HTML mentah. Ganti div mentah itu dengan `<x-alert>`, dan tambahkan sebuah blok kedua untuk key session `error` yang sebelumnya tidak ada.

```blade
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
```

Blok `success` menggantikan div mentah yang ada. Blok `error` adalah hal baru: ia tidak ada di layout sebelumnya karena hanya pesan sukses yang ditampilkan. Menambahkannya berarti controller mana pun yang mengembalikan `redirect()->with('error', '...')` sekarang akan menampilkan alert merah yang diberi style secara otomatis. Kedua nilai flash dikonsumsi oleh Laravel pada request berikutnya dan dihapus dari session, sehingga alert menghilang setelah satu pemuatan halaman.

Setelah perubahan, file `layout.blade.php` lengkap terlihat seperti ini:

```blade
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title ?? 'Catatku' }}</title>
    <script src="https://unpkg.com/@tailwindcss/browser@4"></script>
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

Picu sebuah pesan sukses dengan membuat sebuah entri dan konfirmasi alert hijau muncul dengan aksen border kiri. Untuk menguji varian error, untuk sementara tambahkan `return redirect()->with('error', 'Test error.');` ke method controller mana pun, picu, dan amati alert merah sebelum menghapus kode test.

### Step 3: Menguji Button Component

Ganti sebuah elemen mentah `<button>` di sebuah form yang ada dengan `<x-button variant="primary">`. Konfirmasi ia dirender dengan style primary biru. Coba `variant="danger"` pada sebuah tombol delete untuk melihat varian merah.

### Step 4: Attribute Pass-Through

Tambahkan attribute ekstra saat menggunakan tombol untuk memverifikasi pass-through `$attributes->merge()` bekerja.

```blade
<x-button variant="danger" onclick="return confirm('Are you sure?')" class="ml-2">
    Delete
</x-button>
```

Attribute `onclick` dan `class` tidak dideklarasikan sebagai prop, sehingga mereka mengalir melalui `$attributes->merge()` ke elemen `<button>` yang dirender. Klik tombol dan konfirmasi dialog konfirmasi JavaScript muncul, membuktikan bahwa HTML attribute sembarang diteruskan dengan benar.

---

## 6. Memperbaiki Error pada Kode Anda

Berikut adalah kesalahan paling umum saat membuat dan menggunakan Blade component.

**Error 1: Lupa prefix titik dua saat meneruskan sebuah variabel PHP sebagai prop.**

Error ini terjadi ketika Anda mereferensikan sebuah variabel PHP sebagai attribute component tanpa prefix titik dua. Tanpa titik dua, Blade memperlakukan nilai attribute sebagai string literal alih-alih mengevaluasinya sebagai ekspresi PHP.

```blade
{{-- Wrong: passes the literal string "$entry" to the component --}}
<x-entry-card entry="$entry" />

{{-- Correct: evaluates the expression and passes the actual Entry object --}}
<x-entry-card :entry="$entry" />
```

Versi yang salah meneruskan string `"$entry"` ke component, sehingga `$entry->title` di dalam template melemparkan error pemanggilan method pada string. Versi yang benar menggunakan prefix titik dua, yang memberi tahu Blade untuk mengevaluasi ekspresi PHP `$entry` dan meneruskan objek yang dihasilkan. Nilai non-string apa pun (variabel, array, pemanggilan method, ekspresi ternary) harus menggunakan prefix titik dua.

---

**Error 2: File component dinamai dengan underscore alih-alih kebab-case.**

Error ini terjadi ketika sebuah file component disimpan dengan underscore (snake_case) di nama file. Resolusi component Blade mengonversi tag `<x-kebab-case-name>` menjadi sebuah path file menggunakan tanda hubung, bukan underscore.

```
Wrong:  resources/views/components/entry_card.blade.php
<x-entry-card /> resolves to entry-card.blade.php but finds no match

Correct: resources/views/components/entry-card.blade.php
<x-entry-card /> resolves correctly
```

Blade memetakan `<x-entry-card>` ke `resources/views/components/entry-card.blade.php`. Jika file Anda dinamai `entry_card.blade.php` (dengan underscore), resolusi gagal dan Blade melemparkan error component not found. Ubah nama file untuk menggunakan tanda hubung agar cocok dengan konvensi kebab-case. Untuk class-based component, `make:component EntryCard` menangani penamaan secara otomatis.

---

**Error 3: Memeriksa variabel named slot dengan `if ($title)` alih-alih `isset($title)`.**

Error ini terjadi ketika Anda menggunakan pemeriksaan `if ($title)` langsung untuk sebuah named slot di dalam sebuah template component. Ketika named slot tidak diteruskan oleh caller, variabel tidak terdefinisi alih-alih false atau null, sehingga pemeriksaan boolean langsung menyebabkan error "Undefined variable".

```blade
{{-- Wrong: $title is undefined when no title slot is passed, causing an error --}}
@if ($title)
    <strong>{{ $title }}</strong>
@endif

{{-- Correct: isset() safely returns false for undefined variables --}}
@if (isset($title))
    <strong>{{ $title }}</strong>
@endif
```

Versi yang salah mengasumsikan `$title` ada di scope template. Ketika caller tidak menyediakan sebuah blok `<x-slot:title>`, variabel tidak pernah diatur dan pemeriksaan `if ($title)` melemparkan sebuah PHP notice atau exception. Versi yang benar menggunakan `isset($title)`, yang mengembalikan `false` untuk variabel yang tidak terdefinisi tanpa melemparkan error. Selalu gunakan `isset()` saat memeriksa named slot opsional.

---

## 7. Latihan

Coba bangun component ini secara independen menggunakan pola dari lesson ini. Fokus pada deklarasi `@props`, named slot, dan `$attributes->merge()` untuk masing-masing.

**Latihan 1:** Buat sebuah component `<x-form-input>` yang menerima prop `name`, `label`, dan `type`. Ia seharusnya merender sebuah elemen label, sebuah elemen input dengan `old($name)` untuk pengisian nilai sebelumnya, dan sebuah blok `@error` untuk pesan validasi.

**Latihan 2:** Buat sebuah component `<x-card>` dengan named slot `title`, default slot `body`, dan named slot `footer` opsional. Gunakan ia untuk membungkus view detail entri dalam layout card yang konsisten.

**Latihan 3:** Buat Alert component menutup secara otomatis setelah 5 detik menggunakan JavaScript. Terima sebuah prop `auto-dismiss` yang default-nya `false`, dan secara kondisional sertakan sebuah tag `<script>` kecil di dalam component yang memanggil `setTimeout()` ketika prop bernilai true.

---

## 8. Solusi

Bandingkan component Anda dengan solusi di bawah, perhatikan bagaimana named slot opsional menggunakan `isset()` dan bagaimana prop tanpa nilai default menegakkan attribute yang diperlukan.

**Solusi untuk Latihan 1:**

Buat `resources/views/components/form-input.blade.php` dengan konten berikut.

```blade
@props(['name', 'label', 'type' => 'text'])

<div style="margin-bottom: 16px;">
    <label style="display: block; font-weight: bold; margin-bottom: 6px;">
        {{ $label }}
    </label>
    <input
        type="{{ $type }}"
        name="{{ $name }}"
        value="{{ old($name) }}"
        {{ $attributes->merge(['style' => 'width: 100%; padding: 8px; border: 1px solid #d1d5db; border-radius: 6px;']) }}
    >
    @error($name)
        <p style="color: #dc2626; font-size: 0.85em; margin-top: 4px;">{{ $message }}</p>
    @enderror
</div>
```

Gunakan component di form mana pun dengan sintaks berikut.

```blade
<x-form-input name="title" label="Title" required />
<x-form-input name="email" label="Email" type="email" />
```

Prop `name` dan `label` bersifat wajib (tidak ada nilai default yang disediakan di `@props`). Prop `type` default-nya `"text"`. Helper `old($name)` mengisi ulang input dengan nilai yang sebelumnya dikirim setelah validasi gagal, mencegah user mengetik ulang semua input mereka. Directive `@error($name)` menampilkan pesan validasi spesifik field di bawah input. Pass-through `$attributes->merge(...)` memungkinkan caller menambahkan HTML attribute ekstra seperti `required`, `placeholder`, atau `autocomplete` tanpa mengubah definisi component. Component ini memusatkan semua rendering input form, sehingga memperbarui style input global memerlukan pengeditan satu file.

---

**Solusi untuk Latihan 2:**

Buat `resources/views/components/card.blade.php` dengan konten berikut.

```blade
@props([])

<div style="border: 1px solid #e5e7eb; border-radius: 8px; overflow: hidden; margin-bottom: 16px;">
    @if(isset($title))
        <div style="padding: 12px 16px; border-bottom: 1px solid #e5e7eb; font-weight: bold; font-size: 1.1em;">
            {{ $title }}
        </div>
    @endif

    <div style="padding: 16px;">
        {{ $slot }}
    </div>

    @if(isset($footer))
        <div style="padding: 10px 16px; border-top: 1px solid #e5e7eb; background: #f9fafb; font-size: 0.9em; color: #6b7280;">
            {{ $footer }}
        </div>
    @endif
</div>
```

Gunakan component di view detail entri dengan sintaks berikut.

```blade
<x-card>
    <x-slot:title>{{ $entry->title }}</x-slot:title>

    <p>{{ $entry->content }}</p>

    <x-slot:footer>
        Published {{ $entry->created_at->diffForHumans() }}
    </x-slot:footer>
</x-card>
```

Baik `$title` maupun `$footer` adalah named slot opsional yang diperiksa dengan `isset()`. Ketika tidak ada yang disediakan, card hanya merender section body yang berpadding. Ketika hanya slot `title` yang diteruskan, header muncul tetapi footer dihilangkan. Layout tiga-region ini (header, body, footer) adalah pola UI yang umum, dan memusatkannya di satu component berarti Anda dapat mengubah style semua card di seluruh Catatku dengan mengedit satu file.

---

**Solusi untuk Latihan 3:**

Buka `resources/views/components/alert.blade.php` dan tambahkan prop `autoDismiss` bersama blok script kondisional.

```blade
@props([
    'type' => 'info',
    'autoDismiss' => false,
])

@php
    $colors = match($type) {
        'success' => 'background: #dcfce7; color: #166534; border-left: 4px solid #16a34a;',
        'error' => 'background: #fee2e2; color: #991b1b; border-left: 4px solid #dc2626;',
        'warning' => 'background: #fef3c7; color: #92400e; border-left: 4px solid #d97706;',
        default => 'background: #dbeafe; color: #1e3a8a; border-left: 4px solid #2563eb;',
    };
    $alertId = 'alert-' . uniqid();
@endphp

<div id="{{ $alertId }}" {{ $attributes->merge(['style' => "padding: 12px 16px; border-radius: 6px; margin-bottom: 16px; {$colors}"]) }}>
    @if(isset($title))
        <strong style="display: block; margin-bottom: 4px;">{{ $title }}</strong>
    @endif
    {{ $slot }}
</div>

@if($autoDismiss)
<script>
    setTimeout(function () {
        var el = document.getElementById('{{ $alertId }}');
        if (el) el.remove();
    }, 5000);
</script>
@endif
```

Gunakan varian auto-dismiss pada alert flash message mana pun.

```blade
<x-alert type="success" auto-dismiss>
    {{ session('success') }}
</x-alert>
```

Blade secara otomatis mengonversi attribute kebab-case `auto-dismiss` menjadi variabel camelCase `$autoDismiss` saat mencocokkan terhadap `@props`. Sebuah `$alertId` unik dihasilkan menggunakan `uniqid()` sehingga setiap alert di halaman memiliki `id` DOM yang berbeda, yang mencegah script secara tidak sengaja menghapus elemen yang salah ketika beberapa alert terlihat sekaligus. Blok `<script>` hanya dirender ketika `$autoDismiss` bernilai true, sehingga alert tanpa prop memiliki overhead JavaScript nol.

---

## Selanjutnya - Lesson 16

Di lesson ini Anda membangun tiga Blade component yang dapat digunakan kembali untuk Catatku. Anonymous component `<x-button>` menggunakan `@props` untuk mendeklarasikan `type` dan `variant`, sebuah ekspresi `match` untuk memetakan variant ke CSS inline, dan `$attributes->merge()` untuk meneruskan HTML attribute sembarang ke elemen yang dirender. Anonymous component `<x-alert>` memperkenalkan named slot dengan `isset($title)` untuk region konten opsional. Class-based component `<x-entry-card>` memasangkan sebuah class PHP (dengan property `$entry` yang dipromosikan constructor dan sebuah method `truncatedTitle()`) dengan sebuah Blade template yang mereferensikan baik public property maupun method secara otomatis. Anda me-refactor index entri untuk menggunakan component, mengonfirmasi bahwa satu perubahan template memperbarui setiap card di halaman.

Di Lesson 16, Anda akan mempelajari Vite dan Tailwind CSS: bagaimana memodernisasi frontend Catatku dengan pipeline build aset yang tepat menggunakan Vite dan styling utility-first menggunakan Tailwind, menggantikan inline style dengan CSS berbasis class yang dapat dipelihara.
