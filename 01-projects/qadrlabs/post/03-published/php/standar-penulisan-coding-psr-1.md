---
title: "Standar Penulisan Coding PSR-1"
slug: "standar-penulisan-coding-psr-1"
category: "php"
date: "2021-09-24"
status: "published"
---

Tulisan ini adalah catatan lama tentang Standar Penulisan Kode ketika mengikuti sesi diskusi di kuliah Telegram PHPID for Students mengenai PHP OOP pada sekitar tanggal 13 Desember 2016. Dalam sesi diskusi tersebut, ada satu pertanyaan yang masih saya ingat hingga sekarang, dan baru-baru ini kembali teringat saat mempelajari framework [Laravel](https://qadrlabs.com/posts/category/laravel). Salah satu peserta diskusi menyebutkan tentang **standarisasi dalam penulisan kode PHP**. Kala itu, saya belum sempat mencoba menerapkan standar penulisan ini, meskipun sudah terpikirkan sebelumnya. Setelah mencari informasi di Google, saya menemukan banyak situs dan blog yang merujuk pada PSR-1. Jadi, apa itu PSR-1?

## 1. PSR-1: Basic Coding Standard {#psr-1-basic-coding-standard}

**PSR (PHP Standards Recommendation)-1** adalah rekomendasi standar untuk penulisan kode PHP. Di dalam standar ini, terdapat beberapa hal penting yang perlu diperhatikan dalam penulisan kode. Standarisasi ini sangat bermanfaat bagi kita sebagai developer. Salah satu manfaat utamanya adalah, jika para developer menggunakan standar kode yang sama dalam pengembangan aplikasi, pemindahan modul menjadi lebih mudah tanpa menimbulkan masalah.

Berdasarkan PSR-1, ada beberapa hal yang harus diperhatikan dalam penulisan kode. Apa saja itu? *Check this out!*

## 2. File {#file}

Dalam sebuah file PHP, ada tiga poin penting yang menjadi standar berdasarkan PSR-1:

### 2.1. PHP Tags

Seperti yang kita ketahui, ada beberapa variasi tag yang sering kita jumpai dalam coding PHP. Berdasarkan rekomendasi PSR-1, ada tag yang **harus** digunakan dalam kode PHP, yaitu `<?php ?>` atau `<?= ?>`. Penggunaan variasi tag lainnya **tidak disarankan**.

### 2.2. Character Encoding

Selain tag PHP, kita juga harus memperhatikan karakter encoding. Berdasarkan PSR-1, kode PHP **harus** menggunakan karakter encoding UTF-8 tanpa BOM (Byte Order Mark).

### 2.3. Side Effects

Dalam sebuah file, biasanya ada deklarasi simbol baru dan kode logika yang dapat menyebabkan efek samping (*side effect*). Berdasarkan PSR-1, **sebaiknya tidak** melakukan deklarasi simbol baru dan menuliskan logika yang menyebabkan efek samping secara bersamaan dalam satu file. Jika kita membuat file, **sebaiknya** memisahkan deklarasi simbol baru (seperti `class`, `function`, `constant`, dll.) dari kode yang mengeksekusi logika dengan efek samping.

### Apa itu Side Effects?

Side effects adalah eksekusi logika yang tidak terkait langsung dengan deklarasi `Class`, `Function`, `Constants`, dll. Contoh side effects termasuk:

- Menghasilkan output,
- Menggunakan `require` atau `include`,
- Menghubungkan ke layanan eksternal,
- Memodifikasi pengaturan `ini`,
- Menampilkan pesan error atau exception,
- Memodifikasi variabel global atau statik,
- Membaca atau menulis file, dan sebagainya.

Berikut ini contoh file dengan deklarasi dan side effect yang **harus dihindari**:

```php
<?php
// side effect: mengubah pengaturan ini
ini_set('error_reporting', E_ALL);

// side effect: memuat file
include "file.php";

// side effect: menghasilkan output
echo "<html>\n";

// deklarasi
function foo()
{
   // isi fungsi
}
```

Contoh di bawah ini adalah format yang **disarankan** oleh PSR-1:

```php
<?php
// deklarasi
function foo()
{
   // isi fungsi
}

// deklarasi kondisional *bukan* efek samping
if (! function_exists('bar')) {
   function bar()
   {
     // isi fungsi
   }
}
```

## 3. Namespace dan Nama Class {#namespace-and-classname}

Penulisan `Namespace` dan `Class` juga memiliki standar tersendiri. Pertama, `Namespace` dan `Class` **harus** mengikuti PSR "autoloading" [PSR-0, PSR-4]. Ini berarti setiap file hanya boleh berisi satu `class`, dan harus terdapat `namespace` setidaknya satu level, misalnya dengan nama vendor di tingkat atasnya.

Kedua, nama `Class` **harus** ditulis menggunakan gaya `StudlyCaps`. Untuk kode PHP 5.3 ke atas, `namespace` juga **harus** digunakan. Contoh kode berikut menunjukkan bagaimana `namespace` dan `class` dideklarasikan:

```php
<?php
// PHP 5.3 ke atas:
namespace Vendor\Model;

class Foo
{

}
```

Untuk kode PHP 5.2.x ke bawah, disarankan menggunakan konvensi pseudo-namespace atau menambahkan prefix `Vendor_` pada nama class, seperti di bawah ini:

```php
<?php
// PHP 5.2.x dan sebelumnya:
class Vendor_Model_Foo
{

}
```

## 4. Class Constants, Properties, dan Methods {#constant-properties-method}

Berdasarkan PSR-1, ada beberapa hal yang perlu diperhatikan dalam penulisan `Constant`, `Properties`, dan `Methods` dalam sebuah `Class`. Istilah `class` ini juga mencakup `interface` dan `trait`. Berikut ini adalah standar penulisan kode dasar dalam sebuah `Class`:

### 4.1. Constants

Constants dalam sebuah `Class` **harus** dideklarasikan dengan huruf kapital semua dan dipisahkan dengan underscore. Contoh:

```php
<?php
namespace Vendor\Model;

class Foo
{
   const VERSION = '1.0';
   const DATE_APPROVED = '2012-06-01';
}
```

### 4.2. Properties

PSR-1 tidak memberikan rekomendasi khusus terkait penulisan `Properties` apakah menggunakan `$StudlyCaps`, `$camelCase`, atau `$under_score`. Namun, penamaan properties **sebaiknya** konsisten sesuai dengan ruang lingkupnya (vendor-level, package-level, class-level, atau method-level).

### 4.3. Methods

Nama method **harus** dideklarasikan menggunakan penulisan `camelCase()`.

## Code Formatting Tools {#tools}

Untuk mempermudah penggunaan gaya penulisan sesuai standar PSR, kita bisa menggunakan beberapa tools berikut untuk memformat kode secara otomatis:
1. [PHP CS Fixer](https://github.com/FriendsOfPHP/PHP-CS-Fixer)
2. [PHP CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer)

\*\*\*

Dengan memperhatikan standar penulisan kode, developer akan lebih mudah memahami kode, terutama saat kode tersebut dibagikan ke developer lain atau saat kita membuka kembali kode lama di repositori.

Yuk, mulai terapkan gaya penulisan kode yang lebih baik!

\*\*\*

**Referensi:**
PSR-1 @ [http://www.php-fig.org/psr/psr-1/](http://www.php-fig.org/psr/psr-1/)

Untuk mempelajari lebih lanjut:
[PSR-12: Extended Coding Style](https://www.php-fig.org/psr/psr-12/)

Daftar lengkapnya bisa diakses di:
[PHP Standards Recommendations](https://www.php-fig.org/psr/)