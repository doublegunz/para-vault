---
title: "Blaze: Cara Cepat Akselerasi Rendering di Laravel"
slug: "blaze-cara-cepat-akselerasi-rendering-di-laravel"
category: "Laravel"
date: "2026-02-27"
status: "published"
---

Artikel ini membahas Livewire Blaze, sebuah paket resmi dari Livewire yang berfungsi sebagai akselerator rendering komponen Blade anonim di aplikasi Laravel kita. Fokus utamanya adalah bagaimana Blaze mampu memangkas overhead rendering Blade hingga lebih dari 90% dengan mengompilasi template menjadi fungsi PHP teroptimasi dan menyediakan beberapa strategi optimasi lanjutan seperti function compiler, runtime memoization, dan compile-time folding. Artikel ini juga mengulas cara instalasi, cara mengaktifkan Blaze di level komponen maupun direktori, keterbatasan yang perlu diperhatikan, serta cara menggunakan debug mode dan profiler untuk mengukur manfaat performa yang kita peroleh.

Selain itu, artikel ini menyajikan contoh-contoh penggunaan yang praktis, pola konfigurasi yang aman, serta tips untuk menghindari bug halus ketika mulai mengadopsi strategi agresif seperti folding. Di bagian akhir, terdapat ringkasan best practice dan key takeaway yang dapat dijadikan pedoman ketika mengintegrasikan Blaze ke dalam codebase Laravel berskala kecil maupun besar.

## Apa Itu Livewire Blaze? {#apa-itu-livewire-blaze}

Livewire Blaze adalah **drop-in replacement** untuk komponen Blade anonim yang bertujuan mempercepat proses rendering tanpa mengubah cara kita menulis template secara signifikan. Alih-alih melewati pipeline rendering Blade standar, Blaze mengompilasi template menjadi fungsi PHP yang dioptimasi sehingga mengurangi overhead hingga sekitar 91–97% pada berbagai skenario.

Dalam pengujian internal yang dirilis di Dokumentasi Blaze, rendering 25.000 komponen anonim dapat turun dari sekitar 500 ms menjadi hanya 13 ms ketika menggunakan Blaze pada skenario tanpa atribut. Penghematan serupa juga terlihat pada variasi lain seperti atribut, props, merge(), slot default, slot bernama, hingga penggunaan `@aware` bersarang, yang semuanya menunjukkan reduksi overhead di atas 90%.

Blaze juga menyediakan dua strategi optimasi tambahan di luar function compiler default, yaitu **Runtime Memoization** (cocok untuk komponen yang sering diulang dengan props yang sama) dan **Compile-Time Folding** (optimasi paling agresif yang mengubah komponen menjadi HTML statis di waktu kompilasi). Kedua strategi ini menawarkan lompatan performa lebih jauh, namun membutuhkan pemahaman mendalam dan kehati-hatian agar tidak menimbulkan bug data basi atau perilaku tak terduga.

## Instalasi dan Prasyarat {#instalasi}

Untuk mulai menggunakan Blaze, kita cukup menambahkannya ke dalam proyek Laravel melalui Composer.

```bash
composer require livewire/blaze
```

Setelah paket terinstal, jika kita menggunakan **Flux UI**, Blaze akan langsung terintegrasi tanpa konfigurasi tambahan; cukup menginstal paket ini saja sudah cukup untuk mendapatkan peningkatan performa di komponen-komponen Flux UI yang relevan. Pada proyek Laravel biasa (tanpa Flux UI), kita perlu mengaktifkan Blaze baik lewat directive `@blaze` di level komponen maupun konfigurasi direktori melalui service provider seperti `AppServiceProvider`.

Setiap kali kita mengubah konfigurasi Blaze (misalnya menambah folder yang dioptimasi atau mengubah strategi), kita **wajib** membersihkan view yang telah dikompilasi dengan perintah berikut:

```bash
php artisan view:clear
```

Perintah ini memastikan Blade dan Blaze menyusun ulang cache view berdasarkan konfigurasi terbaru sehingga kita tidak terkecoh oleh output lama yang masih tersimpan di disk.

## Cara Mengaktifkan Blaze {#cara-mengaktifkan-blaze}

Blaze dapat diaktifkan dengan dua pendekatan utama: secara eksplisit di dalam komponen menggunakan directive `@blaze`, atau secara massal lewat konfigurasi direktori di service provider. Pendekatan pertama cocok untuk mencoba Blaze secara bertahap, sedangkan pendekatan kedua efektif ketika kita ingin mengoptimasi banyak komponen sekaligus dengan pola yang konsisten.

### Opsi A: Directive `@blaze`

Pendekatan paling langsung adalah menambahkan directive `@blaze` di bagian paling atas file komponen Blade anonim Anda.

```
@blaze

<button {{ $attributes }}>
    {{ $slot }}
</button>
```

Begitu directive ini hadir di template, Blaze akan mengompilasi komponen tersebut menggunakan function compiler secara default. kita juga dapat langsung mengaktifkan strategi tertentu melalui argumen, misalnya `memo: true` untuk runtime memoization atau `fold: true` untuk compile-time folding.

```
@blaze(memo: true)

@blaze(fold: true)
```

Pendekatan ini memberi kendali sangat granular: kita bisa mengaktifkan Blaze hanya pada komponen tertentu yang paling mahal secara performa, sambil tetap membiarkan komponen lain berjalan dengan pipeline Blade standar sampai kita yakin untuk mengadopsi Blaze lebih luas.

### Opsi B: Optimasi Direktori dengan `Blaze::optimize()`

Jika kita ingin mengaktifkan Blaze untuk banyak komponen sekaligus, gunakan `Blaze::optimize()` di dalam `AppServiceProvider` (atau service provider lain yang sesuai).

```php
use Livewire\Blaze\Blaze;

public function boot(): void
{
    Blaze::optimize()->in(resource_path('views/components'));

    // ... konfigurasi lain
}
```

Metode `in()` menerima path direktori yang berisi komponen-komponen anonim yang ingin kita optimasi. Direkomendasikan untuk memulai dari direktori yang spesifik (misalnya hanya `views/components/button` atau `views/components/modal`) agar kita dapat menguji kompatibilitas dan menemukan potensi masalah lebih awal, sebelum memperluas cakupan ke seluruh komponen.

```php
Blaze::optimize()
    ->in(resource_path('views/components/button'))
    ->in(resource_path('views/components/modal'));
```

kita juga bisa mengecualikan subdirektori tertentu dengan mengatur `compile: false`, misalnya untuk komponen lama (legacy) yang still bergantung pada fitur-fitur Blade yang tidak didukung Blaze.

```php
Blaze::optimize()
    ->in(resource_path('views/components'))
    ->in(resource_path('views/components/legacy'), compile: false);
```

Terakhir, Blaze mengizinkan kita mengatur strategi berbeda per direktori, misalnya memoization untuk ikon dan folding untuk kartu (cards), sehingga konfigurasi dapat disesuaikan dengan karakteristik masing-masing kelompok komponen.

```php
Blaze::optimize()
    ->in(resource_path('views/components/icons'), memo: true)
    ->in(resource_path('views/components/cards'), fold: true);
```

Perlu diingat bahwa directive `@blaze` di level komponen akan **meng-override** pengaturan di level direktori, sehingga kita masih bisa memodifikasi strategi secara spesifik di komponen tertentu walaupun direktori induknya sudah punya konfigurasi default.

## Keterbatasan dan Hal yang Perlu Diwaspadai {#keterbatasan}

Meskipun Blaze dirancang untuk tetap kompatibel dengan sebagian besar fitur Blade, ada beberapa keterbatasan penting yang perlu kita pahami sebelum mengaktifkannya secara luas. Mengabaikan keterbatasan ini bisa menyebabkan perilaku yang berbeda dibanding Blade standar atau bahkan error yang sulit dilacak.

Berikut beberapa batasan utama Blaze:

- **Komponen berbasis class (class-based components) tidak didukung.** Blaze hanya menargetkan komponen Blade anonim.
- **Variabel `$component` tidak tersedia.** Jika kode kita mengandalkan akses ke `$component`, bagian ini perlu direfaktor.
- **View composers / creators / lifecycle events tidak berjalan.** Pipeline view standar yang memicu hook-hook ini tidak dieksekusi ketika Blaze mengambil alih.
- **`View::share()` tidak di-inject otomatis.** Data yang dibagikan secara global lewat `View::share()` tidak muncul otomatis; kita harus mengambilnya secara manual melalui `$__env->shared('key')`.
- **`@aware` lintas boundary Blade–Blaze terbatas.** Agar `@aware` berfungsi, parent dan child component harus sama-sama menggunakan Blaze.
- **Komponen Blaze tidak bisa dirender lewat `view()`.** Komponen tersebut hanya dapat dirender melalui tag komponen (`<x-component-name>`), bukan via helper `view()`.

Dengan memahami batasan-batasan ini sejak awal, kita dapat memilih direktori atau komponen mana yang aman untuk dioptimasi, serta menghindari refactor besar-besaran yang tidak perlu.

## Strategi Optimasi Blaze {#strategi-optimasi}

Blaze menyediakan tiga strategi utama yang bisa kita gunakan untuk mengoptimasi rendering komponen: **Function Compiler**, **Runtime Memoization**, dan **Compile-Time Folding**. Function compiler berlaku secara default ketika Blaze diaktifkan, sementara memoization dan folding perlu dinyalakan secara eksplisit melalui parameter directive atau konfigurasi direktori.

Setiap strategi memiliki karakteristik dan trade-off berbeda: function compiler relatif aman dan hampir selalu kompatibel, memoization efektif mengurangi perhitungan ulang untuk komponen berulang tanpa slot, dan folding memberikan performa maksimal dengan risiko bug yang lebih halus bila digunakan tanpa pemahaman yang cukup. Sebelum mengaktifkan strategi lanjutan, pastikan kita memahami pola data dan dependensi komponen yang akan dioptimasi.

### Ringkasan Strategi

Dokumentasi Blaze merangkum strategi dalam bentuk tabel seperti berikut:

| Strategi | Parameter | Default | Kegunaan Utama |
|----------|-----------|---------|----------------|
| Function Compiler | `compile` | `true` | Umum, aman untuk hampir semua komponen |
| Runtime Memoization | `memo` | `false` | Komponen yang sering diulang dengan props yang sama |
| Compile-Time Folding | `fold` | `false` | Performa maksimum untuk komponen statis atau semi-statis |

## Function Compiler {#function-compiler}

Function compiler adalah strategi default Blaze dan biasanya menjadi langkah pertama yang aman ketika kita ingin mengadopsi Blaze di proyek yang sudah berjalan. Dengan function compiler, Blaze mengubah template Blade anonim menjadi fungsi PHP biasa yang dipanggil langsung, melewati sebagian besar overhead pipeline Blade standar.

Secara praktis, function compiler cocok hampir di semua komponen karena tidak mengubah sifat dinamis data; ia hanya memangkas lapisan abstraksi di sekitar proses rendering. Dari sisi pengembang, kita tetap menulis Blade seperti biasa (`@props`, `$attributes`, `$slot`, dsb.), tetapi di balik layar Blaze menggantikan cara komponen tersebut dieksekusi.

### Cara Kerja Function Compiler

Saat kita menambahkan directive `@blaze` ke sebuah komponen, Blaze mengompilasi template tersebut ke dalam fungsi PHP dengan signature yang menerima data (`$__data`) dan slot (`$__slots`).

```
@blaze 

@props(['type' => 'button'])

<button {{ $attributes->merge(['type' => $type]) }}>
    {{ $slot }}
</button>
```

Contoh di atas akan dikompilasi kira-kira menjadi fungsi seperti ini:

```php
function _c4f8e2a1($__data, $__slots) {
    $type = $__data['type'] ?? 'button';
    $attributes = new BlazeAttributeBag($__data);
    // ...
}
```

Ketika komponen digunakan di view lain, misalnya:

```
<x-button type="submit">Send</x-button>
```

Blaze akan memanggil fungsi terkompilasi tadi secara langsung:

```php
_c4f8e2a1(['type' => 'submit'], ['default' => 'Send']);
```

Dengan cara ini, Blaze menghindari biaya overhead internal Blade yang biasanya melakukan resolusi komponen, binding data, dan lain-lain secara generik. Namun, seluruh logika dalam template (seperti operasi mahal di dalam `@php` atau query tambahan) tetap dieksekusi dan tetap mempengaruhi performa, jadi kita tetap perlu menulis template yang efisien.

## Runtime Memoization {#runtime-memoization}

Runtime memoization adalah strategi yang ideal untuk komponen yang sering muncul berulang dengan props yang sama, seperti ikon, avatar, atau badge status. Dengan mengaktifkan memoization, Blaze akan merender komponen hanya sekali untuk kombinasi props tertentu, lalu menyajikan ulang hasil HTML yang sudah di-cache pada pemanggilan berikutnya.

Penting untuk dicatat bahwa memoization **hanya berlaku untuk komponen tanpa slot**, karena slot memperkenalkan variasi konten yang tidak dapat dengan mudah disatukan ke dalam satu cache berdasarkan props saja.

### Cara Kerja Memoization

Secara internal, Blaze membuat key cache berdasarkan nama komponen dan nilai props yang diteruskan. Misalnya, untuk komponen ikon:

```
@blaze(memo: true)

@props(['name'])

<x-dynamic-component :component="'icon-' . $name" />
```

Ketika dipanggil seperti ini:

```
<x-icon :name="$task->status->icon" />
```

Blaze akan menghasilkan alur kurang lebih seperti berikut:

```
<?php $key = Memo::key('icon', ['name' => $task->status->icon]); ?>

<?php if (! Memo::has($key)): ?>
    <!-- Render dan simpan ke cache: -->
    <x-icon :name="$task->status->icon">
<?php endif; ?>

<?php echo Memo::get($key); ?>
```

Dengan pola ini, komponen hanya benar-benar dirender satu kali per kombinasi props, sehingga beban CPU berkurang drastis di halaman yang memiliki banyak pengulangan. Di sisi lain, jika konten komponen berubah berdasarkan faktor lain di luar props (misal global state), memoization bisa menimbulkan inkonsistensi, jadi pastikan komponen benar-benar murni bergantung pada props yang diberikan.

## Compile-Time Folding {#compile-time-folding}

Compile-time folding adalah strategi paling agresif di Blaze, di mana komponen praktis **menghilang di runtime** karena sudah di-render seluruhnya menjadi HTML statis pada waktu kompilasi. Tidak ada lagi pemanggilan fungsi, resolusi variabel, atau overhead pipeline; Blade hanya menyajikan HTML yang sudah jadi.

Dalam pengukuran yang diberikan, waktu rendering tetap hampir konstan terlepas dari jumlah komponen: 25.000, 50.000, bahkan 100.000 komponen folded semuanya mencatat waktu sekitar 0,68 ms, sementara Blade standar tumbuh linier (500 ms, 1.000 ms, 2.000 ms). Angka ini menggambarkan bahwa folding sangat efektif ketika kita memiliki komponen yang banyak namun strukturnya relatif statis.

### Konsep Dasar Folding

Hal terpenting yang perlu kita pahami adalah bahwa folding menghasilkan HTML **statis**. Seluruh logika internal, kondisi `if`, dan konten dinamis di dalam komponen dihitung satu kali di waktu kompilasi dan dibekukan ke dalam output HTML, sehingga jika konteks pemakaiannya berubah, hasilnya bisa salah tanpa indikasi yang jelas.

Blaze berusaha menghindari folding ketika terdeteksi pola yang berisiko, tetapi tidak semua kasus dapat dideteksi otomatis. Oleh karena itu, kita tetap perlu menganalisis tiap komponen secara manual dan mengonfigurasi kapan folding boleh dilanjutkan atau harus dibatalkan.

### Global State: Kapan Folding Tidak Boleh Digunakan

Komponen yang mengakses **global state** tidak boleh difolding. Global state di sini mencakup segala sesuatu yang tidak diterima dari luar sebagai props atau slot, misalnya data yang diambil melalui helper, facade, atau directive Blade seperti:

- Query database (`User::get()` dan sejenisnya)
- Autentikasi (`auth()->check()`, `@auth`, `@guest`)
- Session (`session('key')`)
- Request (`request()->path()`, `request()->is()`)
- Validasi (`$errors->has()`, `$errors->first()`)
- Waktu (`now()`, `Carbon::now()`)
- Keamanan (`@csrf`)

Dokumentasi Blaze menegaskan bahwa Blaze akan mencoba mendeteksi penggunaan global state dan melempar exception jika kita tetap menandai komponen tersebut dengan `fold: true`, tetapi mekanisme ini tidak sempurna dan tidak bisa menangkap semua bentuk dependensi global. Cara aman adalah mengasumsikan bahwa komponen yang mengambil data dari luar tanpa melalui props/slot **tidak layak difolding**.

### Contoh: Static Attributes

Untuk memahami folding dalam kasus yang aman, perhatikan contoh komponen tombol yang menyusun kelas Tailwind berdasarkan prop `color`:

```
@blaze(fold: true)

@props(['color'])

@php
$classes = match($color) {
    'red' => 'bg-red-500 hover:bg-red-400',
    'blue' => 'bg-blue-500 hover:bg-blue-400',
    default => 'bg-gray-500 hover:bg-gray-400',
};
@endphp

<button {{ $attributes->class($classes) }}>
    {{ $slot }}
</button>
```

Ketika dipakai seperti ini:

```
<x-button color="red">Submit</x-button>
```

Blaze akan merender komponen sekali pada waktu kompilasi dan menggantinya dengan HTML statis:

```
<button class="bg-red-500 hover:bg-red-400">
    Submit
</button>
```

Perilaku ini aman karena value `color="red"` adalah **prop statis** yang tidak pernah berubah untuk instance tersebut, sehingga mengubahnya menjadi kelas CSS statis tidak menimbulkan masalah.

### Dynamic Pass-Through Attributes

Folding masih bisa bekerja dengan atribut dinamis selama atribut tersebut bersifat **pass-through**, yakni nilainya hanya diteruskan apa adanya ke output tanpa dipakai di logika internal. Blaze mencapai ini dengan mengganti nilai dinamis sementara dengan placeholder ketika pre-rendering, lalu menyisipkan kembali ekspresi aslinya ke HTML final.

Misalnya, kita menambahkan atribut `id` dinamis:

```
<x-button color="red" :id="Str::random()">Submit</x-button>
```

Blaze akan menyimpan mapping seperti:

| Placeholder | Nilai Dinamis |
|-------------|---------------|
| ATTR_PLACEHOLDER_1 | `Str::random()` |

Kemudian melakukan pre-rendering dengan placeholder tersebut dan akhirnya mengganti placeholder di output HTML dengan ekspresi Blade asli `{{ Str::random() }}`. Hasil akhirnya tetap dinamis di runtime, tetapi seluruh logika internal komponen (seperti mapping warna ke kelas) sudah difolding sebelumnya.

### Dynamic Non Pass-Through Attributes

Masalah muncul ketika atribut dinamis **juga didefinisikan di `@props`** dan digunakan dalam logika internal komponen. Dalam kasus ini, Blaze akan **mengaborsi folding secara otomatis** dan kembali ke function compiler, sehingga manfaat folding tidak didapat namun keamanan tetap terjaga.

Jika folding dipaksakan, placeholder seperti `ATTR_PLACEHOLDER_1` akan menggantikan nilai prop di dalam logika `match()` atau sejenisnya, membuat lookup gagal dan komponen selalu jatuh ke cabang default. Dokumentasi Blaze memberikan contoh `color` yang dinamis (`:color="$deleting ? 'red' : 'blue'"`) yang jika difolding secara naif akan selalu menghasilkan tombol abu-abu meskipun kondisi `? 'red' : 'blue'` berubah.

### Slot dan Folding

Slot ditangani serupa dengan atribut: Blaze mengganti konten slot dengan placeholder ketika pre-rendering dan kemudian mengembalikan ekspresi aslinya setelah HTML final terbentuk. Namun, berbeda dengan atribut, slot **selalu dianggap pass-through** dan tidak akan pernah menjadi alasan Blaze mengaborsi folding kecuali kita menandainya sebagai `unsafe` secara eksplisit.

Dengan demikian, slot seperti:

```
<x-button>{{ $action }}</x-button>
```

akan dipetakan ke placeholder `SLOT_PLACEHOLDER_1` selama proses folding dan kemudian diubah kembali menjadi `{{ $action }}` di output akhir. Ini tetap aman selama logika internal komponen tidak mencoba menginspeksi atau mengubah isi slot secara kondisional.

## Selective Folding dengan `safe` dan `unsafe` {#selective-folding}

Secara default, Blaze cenderung konservatif: folding akan dibatalkan ketika ada atribut dinamis yang juga didefinisikan di `@props`, dan semua slot dianggap pass-through. Pendekatan ini mencegah sebagian besar bug umum, tetapi kadang terlalu ketat untuk kasus tertentu di mana kita tahu atribut atau slot tersebut sebenarnya aman untuk difolding atau justru berbahaya dan harus memaksa folding batal.

Untuk mengatasi kebutuhan ini, Blaze menyediakan parameter `safe` dan `unsafe` pada directive `@blaze` untuk menyetel perilaku folding lebih halus di level prop, atribut, maupun slot.

### Menandai Prop `safe`

Gunakan `safe` untuk menandai prop yang bersifat **pass-through**, yakni tidak dipakai dalam logika internal dan hanya diteruskan apa adanya ke output. Dengan menandai prop tertentu sebagai safe, kita mengizinkan folding tetap berjalan walaupun nilai prop tersebut dinamis.

```
@blaze(fold: true, safe: ['level'])

@props(['level' => 1])

<h{{ $level }}>{{ $slot }}</h{{ $level }}>
```

Ketika komponen ini dipakai seperti:

```
<x-heading :level="$isFeaturedSection ? 1 : 2" />
```

Blaze akan tetap melakukan folding dan menghasilkan HTML dengan ekspresi dinamis di tag heading:

```
<h{{ $isFeaturedSection ? 1 : 2 }}></h{{ $isFeaturedSection ? 1 : 2 }}>
```

Pendekatan ini aman karena nilai `level` tidak dipakai untuk logika lain di dalam komponen selain menentukan angka tag heading.

### Menandai Slot `unsafe`

Secara default, slot selalu dianggap pass-through dan tidak menghalangi folding. Namun, ada kasus di mana komponen memeriksa isi slot untuk memutuskan apa yang harus dirender, misalnya memanggil metode `hasActualContent()` pada slot.

Dalam kasus seperti ini, kita harus menandai slot terkait sebagai `unsafe` sehingga Blaze membatalkan folding ketika slot digunakan.

```
@blaze(fold: true, unsafe: ['slot'])

@if ($slot->hasActualContent())
    <span>No results</span>
@else
    <div>{{ $slot }}</div>
@endif
```

Ketika dipanggil:

```
<x-items>
    @if(isPro())
        ...
    @endif
</x-items>
```

Blaze akan menghindari folding karena slot ditandai `unsafe`, memastikan logika yang bergantung pada isi slot tetap berjalan di runtime.

Hal yang sama berlaku untuk named slot; cukup gunakan nama slot di array `unsafe`, seperti `['footer']`, untuk memastikan folding dibatalkan bila slot tersebut diisi.

### Menandai Atribut `unsafe`

Selain props dan slot, kita juga dapat menandai atribut tertentu—termasuk attribute bag `$attributes` utuh—sebagai `unsafe` untuk mencegah folding ketika atribut tersebut dinamis dan digunakan dalam logika internal komponen.

```
@blaze(fold: true, unsafe: ['href'])

@php
$active = $attributes->get('href') === url()->current();
@endphp

<a {{ $attributes->merge(['data-active' => $active]) }}>
    {{ $slot }}
</a>
```

Pada contoh di atas, nilai `href` digunakan untuk menentukan state `active`, sehingga menjadikannya non pass-through dan berpotensi salah jika difolding dengan placeholder. Menandai `href` sebagai unsafe membuat Blaze membatalkan folding ketika `href` dinamis.

kita juga bisa menandai keseluruhan `$attributes` sebagai unsafe:

```
@blaze(fold: true, unsafe: ['attributes'])

@php
$active = $attributes->get('href') === url()->current();
$external = $attributes->get('target') === '_blank';
@endphp

<a {{ $attributes->merge(['data-active' => $active]) }}>
    @if($external)
        ...
    @endif
</a>
```

Dengan konfigurasi ini, **setiap** atribut dinamis yang memengaruhi logika internal akan menyebabkan folding dibatalkan, sehingga kita tidak perlu menandai atribut satu per satu.

## Directive `@unblaze` {#unblaze}

Directive `@unblaze` disediakan untuk kasus di mana sebuah komponen pada dasarnya cocok untuk folding, tetapi memiliki sebagian kecil blok kode yang benar-benar harus tetap dievaluasi di runtime. Dengan `@unblaze`, kita dapat mengecualikan sebagian kecil komponen dari folding sekaligus mengontrol variabel apa saja yang boleh diakses oleh blok dinamis tersebut.

```
@blaze(fold: true)

@props(['name', 'label'])

<div>
    abel>{{ $label }}</label>
    <input name="{{ $name }}">

    @unblaze(scope: ['name' => $name])
        @if($errors->has($scope['name']))
            {{ $errors->first($scope['name']) }}
        @endif
    @endunblaze
</div>
```

Dalam contoh ini, bagian form (label dan input) dapat difolding dengan aman, tetapi pesan error yang mengambil data dari `$errors` (global state validasi) harus tetap dievaluasi di runtime. Dengan membungkus blok tersebut di dalam `@unblaze` dan meneruskan variabel yang dibutuhkan melalui parameter `scope`, Blaze dapat memisahkan bagian statis dan dinamis tanpa mengorbankan keamanan data.

## Debug Mode dan Profiling {#debug-mode}

Blaze menyertakan **debug mode** dengan overlay dan profiler untuk membantu kita mengukur performa rendering dan membandingkan Blaze dengan Blade standar. Fitur ini sangat berguna ketika kita ingin mengidentifikasi komponen mana yang menjadi bottleneck dan mengevaluasi dampak strategi optimasi tertentu.

### Mengaktifkan Debug Mode

kita bisa mengaktifkan debug mode melalui kode di service provider:

```php
use Livewire\Blaze\Blaze;

public function boot(): void
{
    Blaze::debug();

    // ...
}
```

Atau dengan environment variable di `.env`:

```
BLAZE_DEBUG=true
```

Setelah debug mode aktif, jangan lupa menjalankan:

```bash
php artisan view:clear
```

untuk memastikan view dikompilasi ulang dengan konfigurasi terbaru. Setelah itu, setiap halaman akan menampilkan overlay kecil yang berisi waktu rendering untuk request saat ini ketika Blaze aktif.

### Membandingkan Blaze vs Blade

Untuk mengukur seberapa besar peningkatan performa Blaze dibanding pipeline Blade standar, Dokumentasi Blaze menyarankan langkah berikut:

1. Nonaktifkan Blaze sementara dengan menyetel `BLAZE_ENABLED=false` di `.env`.
2. Jalankan `php artisan view:clear` agar view dikompilasi ulang tanpa Blaze.
3. Kunjungi halaman yang ingin diukur; debug bar akan mencatat waktu rendering Blade sebagai baseline.
4. Aktifkan kembali Blaze dengan menghapus environment variable tersebut atau mengembalikannya ke `true`.
5. Jalankan lagi `php artisan view:clear` untuk mengompilasi ulang dengan Blaze.
6. Kunjungi ulang halaman yang sama; debug bar akan menampilkan waktu Blaze berdampingan dengan baseline Blade beserta selisih penghematannya.

Dokumentasi Blaze juga menyarankan untuk me-refresh halaman beberapa kali pada masing-masing mode, karena request pertama biasanya mencakup overhead kompilasi yang bisa membuat angka terlihat lebih buruk daripada request berikutnya.

### Profiler dan Flame Chart

Overlay debug Blaze memiliki tombol **Open Profiler** yang membuka jendela terpisah berisi flame chart trace untuk URL terakhir yang dikunjungi. Workflow-nya adalah:

1. Buka jendela profiler (bisa dibiarkan terbuka).
2. Navigasikan ke halaman yang ingin kita profil.
3. Refresh jendela profiler; trace untuk halaman tersebut akan dimuat.

Trace ini menunjukkan setiap komponen yang dirender selama request, durasi eksekusinya, kedalaman nesting, serta strategi yang digunakan (compiled, folded, memoized, atau Blade biasa). Data ini disimpan di cache store default aplikasi Anda; jika `CACHE_STORE=array` atau cache tidak dapat dijangkau, profiler tidak akan berfungsi.

## Konfigurasi Lanjutan dan Environment {#konfigurasi-lanjutan}

Selain konfigurasi per-direktori dan directive di level komponen, Blaze juga menyediakan beberapa method helper dan environment variable untuk mengontrol perilakunya di runtime.

### Method Blaze

Dokumentasi Blaze mencantumkan beberapa method berikut:

```php
Blaze::enable();    // Mengaktifkan kompilasi Blaze di runtime
Blaze::debug();     // Mengaktifkan debug mode (overlay + profiler)
Blaze::throw();     // Melempar exception folding alih-alih fallback diam-diam
```

Secara default, Blaze akan melakukan fallback diam-diam ke strategi yang lebih aman ketika terjadi error folding. Jika kita ingin menemukan dan memperbaiki semua kasus tersebut secara eksplisit, `Blaze::throw()` akan memaksa exception dilempar sehingga mudah dilacak selama pengembangan.

### Environment Variable

kita juga dapat mengontrol Blaze lewat environment variable berikut:

```
BLAZE_ENABLED=true
BLAZE_DEBUG=false
```

- `BLAZE_ENABLED` mengatur apakah kompilasi Blaze diaktifkan atau tidak secara global.
- `BLAZE_DEBUG` mengontrol apakah debug mode (overlay dan profiler) aktif.

Keduanya memudahkan kita mengubah perilaku Blaze antar environment (local, staging, production) tanpa harus mengubah kode sumber.

## Best Practice dan Pola Penggunaan {#best-practice}

Bagian ini merangkum beberapa best practice ketika mengintegrasikan Blaze ke dalam proyek Laravel yang sudah berjalan maupun yang baru.

- **Mulai dari function compiler saja.** Aktifkan Blaze tanpa `memo` atau `fold` terlebih dahulu untuk mengukur peningkatan performa dasar dan meminimalkan risiko bug.
- **Optimasi per direktori secara bertahap.** Fokuskan pada direktori komponen yang paling sering dirender (misalnya layout, navbar, daftar item) lalu uji aplikasi dengan cukup menyeluruh sebelum memperluas cakupan.
- **Gunakan memoization hanya untuk komponen murni tanpa slot.** Pastikan seluruh output komponen ditentukan sepenuhnya oleh props; hindari komponen yang membaca global state.
- **Gunakan folding pada komponen yang benar-benar stabil.** Contohnya ikon, badge statis, atau komponen UI yang hanya bergantung pada props sederhana dan tidak memeriksa global state atau konten slot.
- **Manfaatkan `safe` dan `unsafe` untuk kasus abu-abu.** Tandai prop/atribut/slot yang jelas pass-through sebagai `safe`, dan tandai yang digunakan di logika internal sebagai `unsafe` untuk memaksa fallback ketika dinamis.
- **Gunakan `@unblaze` untuk bagian yang dinamis.** Ketika satu komponen memadukan bagian statis dan dinamis, letakkan bagian dinamis (misalnya error message atau status user) di dalam blok `@unblaze`.
- **Selalu gunakan debug mode dan profiler ketika tuning.** Pantau komponen mana yang paling mahal, serta lihat strategi apa yang digunakan untuk masing-masing komponen di flame chart.

Dengan mengikuti pola ini, kita dapat memanfaatkan keuntungan performa Blaze secara maksimal sekaligus menjaga stabilitas aplikasi dan menghindari regresi yang sulit dideteksi.


## Penutup {#penutup}

Livewire Blaze memberikan cara yang elegan dan praktis untuk mengakselerasi rendering komponen Blade anonim di aplikasi Laravel tanpa harus menulis ulang seluruh layer view. Dengan memanfaatkan function compiler sebagai baseline dan secara selektif mengaktifkan runtime memoization maupun compile-time folding pada komponen yang tepat, kita dapat memperoleh penghematan performa yang sangat signifikan, terutama di halaman dengan banyak komponen berulang.

Kunci keberhasilan adopsi Blaze terletak pada pemahaman keterbatasannya, penggunaan debug mode dan profiler untuk mengukur dampak nyata di aplikasi Anda, serta disiplin dalam memilih komponen mana yang aman untuk optimasi agresif. Dengan pendekatan bertahap dan hati-hati, Blaze dapat menjadi salah satu alat paling efektif dalam toolbox optimasi performa Laravel modern.

**Key Takeaway:**

- Blaze adalah drop-in replacement untuk komponen Blade anonim yang dapat memangkas overhead rendering lebih dari 90%.
- Function compiler aman untuk hampir semua komponen dan sebaiknya dijadikan langkah awal adopsi.
- Runtime memoization efektif untuk komponen tanpa slot yang sering muncul dengan kombinasi props yang sama.
- Compile-time folding memberikan performa maksimal, tetapi hanya aman untuk komponen yang tidak bergantung pada global state.
- Parameter `safe`, `unsafe`, dan directive `@unblaze` memberi kontrol granular untuk menyeimbangkan antara performa dan akurasi data.
- Debug mode dan profiler Blaze wajib digunakan ketika melakukan tuning agar keputusan optimasi berbasis data, bukan asumsi.


## Referensi {#referensi}
- Repositori Blaze at [https://github.com/livewire/blaze](https://github.com/livewire/blaze)