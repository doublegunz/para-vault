---
title: "Tutorial CodeIgniter 4: Generate PDF menggunakan DomPDF"
slug: "tutorial-codeigniter-4-generate-pdf-menggunakan-dompdf"
category: "CodeIgniter 4"
date: "2021-06-11"
status: "published"
---

Ingin menambahkan fitur export PDF di aplikasi CodeIgniter 4 Anda? Tutorial ini akan memandu Anda langkah demi langkah dalam mengimplementasikan generate PDF menggunakan library DomPDF. Sebagai salah satu kebutuhan umum dalam pengembangan aplikasi web modern, kemampuan menghasilkan file PDF sangat penting untuk membuat laporan, dokumen, atau data yang bisa diunduh pengguna. 

**DomPDF** merupakan pilihan populer di ekosistem PHP karena kemampuannya mengkonversi HTML dan CSS menjadi file PDF dengan mudah [^1]. Library ini berintegrasi dengan baik di framework CodeIgniter 4 dan mendukung berbagai fitur styling CSS 2.1 yang membuat hasil PDF Anda terlihat profesional.

Di tutorial ini, kita akan membuat contoh aplikasi sederhana untuk menampilkan data mahasiswa dan mengekspornya ke format PDF. Anda akan mempelajari cara menginstall DomPDF, membuat controller khusus untuk handle generate PDF, dan mengatur tampilan yang bisa digunakan baik untuk web maupun template PDF. Tutorial ini cocok untuk developer PHP yang sudah mengenal dasar-dasar CodeIgniter 4 dan ingin menambahkan kemampuan generate PDF di aplikasi mereka.

## Overview {#overview}
Di tutorial series [Belajar CodeIgniter 4](https://qadrlabs.com/series/belajar-codeigniter-4) edisi kali ini kita akan membangun fitur export PDF sederhana menggunakan framework CodeIgniter 4 dan library DomPDF. Kita akan membuat halaman yang menampilkan tabel data mahasiswa dengan kemampuan untuk mengekspor data tersebut ke format PDF.

**Apa yang akan dibangun:**
- Halaman web sederhana yang menampilkan tabel data mahasiswa
- Tombol untuk mengekspor data ke format PDF
- Sistem generate PDF yang mengkonversi tampilan HTML ke file PDF

**Apa yang akan dipelajari:**
- Cara menginstall dan mengintegrasikan DomPDF dengan CodeIgniter 4
- Teknik mengkonversi tampilan HTML menjadi file PDF
- Penggunaan Controller untuk menangani proses generate PDF
- Pembuatan view yang bisa digunakan untuk tampilan web dan template PDF
- Konfigurasi routing di CodeIgniter 4

**Goal Tutorial:**
- Memahami konsep dasar generate PDF di aplikasi web
- Mampu mengimplementasikan fitur export PDF menggunakan DomPDF di aplikasi CodeIgniter 4
- Mengerti cara membuat tampilan yang bisa digunakan untuk web dan PDF sekaligus
- Bisa menghasilkan file PDF dengan format yang sesuai kebutuhan (dalam hal ini landscape A4)

Tutorial ini cocok untuk developer yang sudah familiar dengan CodeIgniter 4 dan ingin menambahkan kemampuan generate PDF di aplikasi mereka.

## Step 1 - Install CodeIgniter 4 App{#step-1}

Pertama kita install CodeIgniter 4 menggunakan `composer`. Buka terminal, lalu run `command` ini untuk menginstall CodeIgniter 4.

```
composer create-project codeigniter4/appstarter ci4-pdf-example

```

Setelah dirun, proses instalasi codeigniter 4 dimulai. Kita tunggu sampai proses installnya selesai.

## Step 2 - Install DomPDF{#step-2}

Langkah kita berikutnya adalah menginstall library DomPDF. Berdasarkan repositori DomPDF, ada beberapa cara untuk menginstall DomPDF. Salah satunya adalah menginstall melalui `composer`. Sebelum menginstall library, kita masuk dulu ke dalam direktori project. 

```
cd ci4-pdf-example
```

Selanjutnya kita install DomPDF, run `command` di bawah ini.

```
composer require dompdf/dompdf
```

Tunggu sampai proses instalasi selesai. Karena kita menginstall menggunakan `composer`, DomPDF bisa langsung kita gunakan tanpa perlu ada konfigurasi.

## Step 3 - Membuat Controller baru{#step-3}

Kita buat sebuah controller yang akan menangani proses generate PDF menggunakan DomPDF, misalkan namanya itu `PdfController`. Di dalam class `PdfController`, kita buat dua method. Method yang pertama untuk menampilkan halaman utama yang memiliki link untuk generate pdf dan method kedua untuk menangani proses generate PDF menggunakan DomPDF.

Sekarang kita buat controller baru dengan nama `PdfController.php`. Buka kembali terminal, lalu run command berikut ini.

```
php spark make:controller PdfController
```

Output:

```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 14:12:52 UTC+00:00

File created: APPPATH/Controllers/PdfController.php
```





Selanjutnya buka controller `Controllers/PdfController.php`, lalu Kita tambahkan kode berikut ini di dalam file `PdfController.php`.

```php
<?php

namespace App\Controllers;
use CodeIgniter\Controller;
use Dompdf\Dompdf;

class PdfController extends Controller
{
    public function index()
    {
        return view('index');
    }

    public function generate()
    {
        $filename = date('y-m-d-H-i-s'). '-qadr-labs-report';

        // instantiate and use the dompdf class
        $dompdf = new Dompdf();

        // load HTML content
        $dompdf->loadHtml(view('pdf_view'));

        // (optional) setup the paper size and orientation
        $dompdf->setPaper('A4', 'landscape');

        // render html as PDF
        $dompdf->render();

        // output the generated pdf
        $dompdf->stream($filename);
    }
}
```

Setelah selesai, kita save kembali file `PdfController.php`.

## Step 4 - Membuat file View{#step-4}

Langkah selanjutnya adalah membuat file view. File view yang akan kita buat ini digunakan untuk menampilkan halaman utama dan juga digunakan untuk tampilan pdf hasil generate menggunakan DomPDF. 
Buat file baru dengan nama `index.php` di `app\Views`, lalu kita ketik kode berikut ini.
```
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Generate PDF CodeIgniter 4 - qadrLabs</title>

</head>

<body>
<h2>Data Mahasiswa </h2>
<a href="<?php echo site_url('pdf/generate') ?>">
    Download PDF
</a>
<table border=1 width=80% cellpadding=2 cellspacing=0 style="margin-top: 5px; text-align:center">
    <thead>    <tr bgcolor=silver align=center>
        <td width="5%">No</td>
        <td width="25%">Nim</td>
        <td width="50%">Nama</td>
        <td width="20%">Nilai</td>
    </tr>    </thead>    <tbody>    <tr>        <td>1</td>
        <td>1930511041</td>
        <td>Resita</td>
        <td>85</td>
    </tr>    <tr>        <td>2</td>
        <td>1930511044</td>
        <td>Tika</td>
        <td>85</td>
    </tr>    <tr>        <td>3</td>
        <td>1930511050</td>
        <td>Ramdan</td>
        <td>80</td>
    </tr>    <tr>        <td>4</td>
        <td>1930511051</td>
        <td>Nahla</td>
        <td>85</td>
    </tr>    <tr>        <td>5</td>
        <td>1930511052</td>
        <td>Reski</td>
        <td>95</td>
    </tr>    </tbody></table>
<p>Jumlah data : 5</p>
</body>

</html>
```

Selanjutnya buat file kedua dengan nama `pdf_view.php` di `app\Views`, lalu kita ketik kode berikut ini.

```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Generate PDF CodeIgniter 4 - qadrLabs</title>

</head>

<body>
<h2>Data Mahasiswa </h2>

<table border=1 width=80% cellpadding=2 cellspacing=0 style="margin-top: 5px; text-align:center">
    <thead>    <tr bgcolor=silver align=center>
        <td width="5%">No</td>
        <td width="25%">Nim</td>
        <td width="50%">Nama</td>
        <td width="20%">Nilai</td>
    </tr>    </thead>    <tbody>    <tr>        <td>1</td>
        <td>1930511041</td>
        <td>Resita</td>
        <td>85</td>
    </tr>    <tr>        <td>2</td>
        <td>1930511044</td>
        <td>Tika</td>
        <td>85</td>
    </tr>    <tr>        <td>3</td>
        <td>1930511050</td>
        <td>Ramdan</td>
        <td>80</td>
    </tr>    <tr>        <td>4</td>
        <td>1930511051</td>
        <td>Nahla</td>
        <td>85</td>
    </tr>    <tr>        <td>5</td>
        <td>1930511052</td>
        <td>Reski</td>
        <td>95</td>
    </tr>    </tbody></table>
<p>Jumlah data : 5</p>
</body>

</html>
```

Setelah selesai, kita save file view `pdf_view.php`.


## Step 5 - Definisikan route{#step-5}

Langkah terakhir untuk fitur generate pdf menggunakan DomPDF di aplikasi CodeIgniter 4 ini adalah mendefinisikan route. Buka file `app/Config/Routes.php`. Temukan kode ini di sekitar baris 35.

```php
$routes->get('/', 'Home::index');
```

Kita ubah routenya, kita arahkan ke controller yang baru saja kita buat.

```php
$routes->get('/', 'PdfController::index');
```

Selanjutnya kita tambahkan route kedua untuk proses generate pdf.

```php
$routes->get('/pdf/generate', 'PdfController::generate');
```

Jadi sekarang kita sudah definisikan dua route.

```php
/*  
 * -------------------------------------------------------------------- * Route Definitions * -------------------------------------------------------------------- */  
// We get a performance increase by specifying the default  
// route since we don't have to scan directories.  
$routes->get('/', 'PdfController::index');  
$routes->get('/pdf/generate', 'PdfController::generate');
```

Save kembali file `Routes.php`.

## Step 6 - Uji Coba{#step-6}

Untuk menguji coba, kita run aplikasi codeigniter 4 menggunakan `command`.

```
php spark serve
```

Selanjutnya buka url ini di browser.

```
http://localhost:8080
```

![run project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/generate-pdf/1-run-project.png)

Kita bisa lihat halaman sederhana yang menampilkan data mahasiswa. Selanjutnya kita coba download file pdf hasil generate menggunakan DomPDF dengan menekan link download. Aplikasi akan memulai proses generate PDF, dan hasilnya dapat kita download berupa file pdf.

![view pdf hasil generate](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/generate-pdf/2-view-pdf-hasil-generate.png)

## Penutup {#penutup}

Selamat! Anda telah berhasil mengimplementasikan fitur generate PDF di aplikasi CodeIgniter 4 menggunakan library DomPDF. Melalui tutorial ini, kita telah mempelajari beberapa hal penting:

- Cara menginstall dan mengintegrasikan DomPDF dengan CodeIgniter 4 menggunakan Composer
- Membuat controller khusus untuk menangani proses generate PDF
- Teknik membuat view yang bisa digunakan untuk tampilan web sekaligus template PDF
- Mengatur paper size dan orientation sesuai kebutuhan
- Implementasi routing untuk fitur generate PDF

DomPDF terbukti menjadi solusi yang powerful untuk kebutuhan generate PDF di aplikasi CodeIgniter 4. Library ini tidak hanya mudah diimplementasikan, tetapi juga mendukung styling CSS yang membuat hasil PDF Anda lebih profesional. Anda bisa mengembangkan lebih lanjut fitur ini sesuai kebutuhan aplikasi, misalnya:

- Menambahkan header dan footer di file PDF
- Mengatur style CSS yang lebih kompleks
- Mengintegrasikan dengan data dinamis dari database
- Menambahkan watermark atau security features
- Mengatur nama file PDF sesuai konteks data

Dengan pemahaman dasar ini, Anda bisa mulai mengeksplorasi fitur-fitur lain dari DomPDF untuk menghasilkan file PDF yang lebih kompleks sesuai kebutuhan proyek Anda.

### Referensi {#referensi}

[^1]: Repositori resmi dompdf @ [Repositori dompdf](https://github.com/dompdf/dompdf)