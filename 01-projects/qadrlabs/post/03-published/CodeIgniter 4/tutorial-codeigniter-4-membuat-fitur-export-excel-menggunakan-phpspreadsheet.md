---
title: "Tutorial CodeIgniter 4 Membuat fitur export excel menggunakan PhpSpreadsheet"
slug: "tutorial-codeigniter-4-membuat-fitur-export-excel-menggunakan-phpspreadsheet"
category: "CodeIgniter 4"
date: "2021-03-19"
status: "published"
---

Fitur export ke dalam format excel itu merupakan salah satu fitur yang biasa terdapat pada program yang kita buat. Biasanya fitur ini digunakan dalam modul reporting atau pembuatan laporan. Meski program kita sudah bisa mencetak laporan langsung, adakalanya pengguna itu memerlukan laporan dalam format yang berbeda, misalnya dalam format excel maupun pdf. Untuk memenuhi kebutuhan tersebut, edisi tutorial [Belajar CodeIgniter 4](https://qadrlabs.com/series/belajar-codeigniter-4) ini akan membahas tentang membuat **fitur export excel di framework CodeIgniter 4** menggunakan salah satu library yang sering digunakan untuk menangani export excel yaitu library PhpSpreadsheet.

**PhpSpreadsheet** adalah sebuah library yang ditulis menggunakan bahasa pemrograman PHP dan menyediakan beberapa class yang memudahkan kita untuk menulis dan membaca file spreasheet dalam format seperti excel dan LibreOffice Calc. Di tutorial ini kita akan coba class untuk menuliskan file excel. 

Selain format excel, ada beberapa format file yang disupport library ini. Untuk menulis, library ini mendukung format Open Document/OASIS (`.ods`), Office Open Xml (`.xlsx`) Excel 2007 ke atas, BIFF 8 (`.xls`) Excel 97 ke atas dan lain-lain. Karena di tutorial export to excel CodeIgniter sebelumnya itu tanpa library apapun dan tampaknya banyak yang tidak bisa buka file excel hasil generate dari codingannya, di tutorial ini saya mencoba menggunakan cara yang berbeda untuk membuat fitur export dalam format excel.

## Web App Overview{#overview}

Dalam tutorial ini, kita akan membangun sebuah fitur **export data ke format Excel** menggunakan framework **CodeIgniter 4** dan library **PhpSpreadsheet**. Aplikasi yang akan dibuat merupakan sebuah contoh sederhana untuk mengeksport data dari database ke dalam file Excel yang dapat diunduh oleh pengguna.

### Apa yang akan dibuild:
Kita akan membuat sebuah halaman web sederhana yang berisi tombol untuk memicu proses export data. Data tersebut berasal dari tabel pengguna (misalnya nama, email, dan tanggal pembuatan akun), dan akan diekspor ke dalam format Excel (.xlsx). File Excel hasil ekspor kemudian dapat langsung diunduh oleh pengguna melalui browser.

### Apa yang akan dipelajari:
1. **Instalasi Library PhpSpreadsheet**: Anda akan belajar cara mengintegrasikan library PhpSpreadsheet ke dalam proyek CodeIgniter 4 menggunakan Composer.
2. **Membuat Model dan Controller**: Anda akan belajar cara membuat model untuk mengambil data dari database serta controller untuk menangani logika export data.
3. **Menggunakan PhpSpreadsheet untuk Export Excel**: Anda akan mempelajari cara menggunakan class `Spreadsheet` dan `Writer` dari PhpSpreadsheet untuk membuat file Excel secara dinamis berdasarkan data dari database.
4. **Routing di CodeIgniter 4**: Anda akan belajar cara mendefinisikan route khusus untuk mengakses halaman utama dan menjalankan proses export.

### Goal Tutorial Ini:
Tujuan utama dari tutorial ini adalah memberikan pemahaman praktis tentang cara mengimplementasikan fitur **export data ke Excel** di aplikasi web berbasis CodeIgniter 4. Dengan mengikuti langkah-langkah ini, Anda akan memiliki dasar yang kuat untuk mengembangkan fitur serupa dengan lebih kompleks di masa mendatang. Di akhir tutorial, Anda akan memiliki aplikasi sederhana yang mampu mengekspor data ke Excel dengan benar dan tanpa kendala. 

Semoga tutorial ini membantu Anda memahami konsep dasar dan mempersiapkan Anda untuk proyek yang lebih besar!

## Persiapan{#persiapan}

Untuk proses export data tentu kita perlu ada data terlebih dahulu. Untuk itu kita akan coba memanfaatkan hasil dari tutorial sebelumnya tentang generate dummy data menggunakan database seeder.

Untuk teman-teman yang sudah selesai project tersebut dapat langsung mengikuti tutorial export excel ini. Dan untuk yang belum ada hasil project tersebut, boleh mengikuti [tutorial sebelumnya](https://qadrlabs.com/post/database-seeder-codeigniter-4) untuk persiapan.

## Step 1 - Install library PHPSpreadSheet{#step-1}

Kawan, hal pertama yang akan kita lakukan adalah menginstall library. Seperti proses instalasi CodeIgniter 4, kita pakai composer untuk menginstall library PHPSpreadsheet. Buka terminal lalu run `command` ini ya..

```bash
composer require phpoffice/phpspreadsheet
```

Selanjutnya kita tunggu sampai proses instalasi selesai.

## Step 2 - Membuat fitur export ke excel{#step-2}

Library PhpSpreadsheet sudah kita install, langkah selanjutnya adalah membuat fitur export ke excel. 

Kita buat dulu model class sesuai dengan sample data yang kita punya. Buka kembali terminal, lalu run command berikut ini untuk generate model dengan nama `UsersModel`.

```
php spark make:model UsersModel
```

Output:

```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 13:57:36 UTC+00:00

File created: APPPATH/Models/UsersModel.php
```



Selanjutnya kita buat controller yang akan menangani proses export. Buka kembali terminal, lalu kita generate controller menggunakan `spark` command:

```bash
php spark make:controller User
```

Buka file yang baru saja kita generate menggunakan `spark`, yaitu file `User.php`. di direktori `app/Controllers/`. Kemudian kita modifikasi class controller `User` di dalam file `User.php`. Kita import terlebih dahulu library yang akan kita gunakan menggunakan statement `use`.

```php
<?php

namespace App\Controllers;

use App\Controllers\BaseController;
use App\Models\UsersModel;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;

class User extends BaseController
{
  // isi class User
}

```

Selanjutnya kita buat method baru untuk menghandle proses export ke excel.

```php
<?php

namespace App\Controllers;

use App\Controllers\BaseController;
use App\Models\UsersModel;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;

class User extends BaseController
{

	public function export()
	{
		$userModel = new UsersModel();
		$users = $userModel->findAll();

		$spreadsheet = new Spreadsheet();

		$spreadsheet->setActiveSheetIndex(0)
			->setCellValue('A1', 'Nama')
			->setCellValue('B1', 'Email')
			->setCellValue('C1', 'Tanggal dibuat');

		$column = 2;

		foreach ($users as $user) {
			$spreadsheet->setActiveSheetIndex(0)
				->setCellValue('A' . $column, $user['name'])
				->setCellValue('B' . $column, $user['email'])
				->setCellValue('C' . $column, $user['created_at']);

			$column++;
		}

		$writer = new Xlsx($spreadsheet);
		$filename = date('Y-m-d-His'). '-Data-User';

		header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
		header('Content-Disposition: attachment;filename=' . $filename . '.xlsx');
		header('Cache-Control: max-age=0');

		$writer->save('php://output');
	}
}

```

Save kembali file `User.php`.

Pada tahapan ini kita sudah bisa melakukan proses export ke excel. Hanya saja kita mesti menuliskan urlnya langsung di address bar browser untuk mengaksesnya. Supaya lebih mudah untuk proses uji coba, kita buat user interfacenya.

## Step 3 - Membuat halaman untuk download hasil export{#step-3}

Buka kembali file controller `User.php`, kita tambahkan method `index()` untuk menampilkan halaman untuk export ke excel.

```php
<?php

namespace App\Controllers;

use App\Controllers\BaseController;
use App\Models\UsersModel;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;

class User extends BaseController
{
	public function index()
	{
		return view('index');

	}

	// baris kode selanjutnya..

}

```

Sehingga keseluruhan class controller `User` menjadi seperti berikut ini.

```php
<?php

namespace App\Controllers;

use App\Controllers\BaseController;
use App\Models\UsersModel;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;

class User extends BaseController
{
	public function index()
	{
		return view('index');

	}

	public function export()
	{
		$userModel = new UsersModel();
		$users = $userModel->findAll();

		$spreadsheet = new Spreadsheet();

		$spreadsheet->setActiveSheetIndex(0)
			->setCellValue('A1', 'Nama')
			->setCellValue('B1', 'Email')
			->setCellValue('C1', 'Tanggal dibuat');

		$column = 2;

		foreach ($users as $user) {
			$spreadsheet->setActiveSheetIndex(0)
				->setCellValue('A' . $column, $user['name'])
				->setCellValue('B' . $column, $user['email'])
				->setCellValue('C' . $column, $user['created_at']);

			$column++;
		}

		$writer = new Xlsx($spreadsheet);
		$filename = date('Y-m-d-His'). '-Data-User';

		header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
		header('Content-Disposition: attachment;filename=' . $filename . '.xlsx');
		header('Cache-Control: max-age=0');

		$writer->save('php://output');
	}
}

```

Selanjutnya kita buat file view `index.php` di folder `app/Views`, lalu kita tambahkan baris kode berikut ini.

```html
<!DOCTYPE html>  
<html lang="en">  
  
<head>  
    <meta charset="UTF-8">  
    <meta http-equiv="X-UA-Compatible" content="IE=edge">  
    <meta name="viewport" content="width=device-width, initial-scale=1.0">  
    <title>Tutorial CodeIgniter 4 Export excel menggunakan PhpSpreadsheet at qadrLabs</title>  
</head>  
  
<body>  
<h2>Tutorial CodeIgniter 4 Export excel menggunakan PhpSpreadsheet at qadrLabs</h2>  
<form action="<?php echo site_url('user/export'); ?>" method="post">  
    <button type="submit">Export Excel</button>  
</form>  
  
</body>  
  
</html>
```

Seperti yang terlihat di baris kode di atas, tampilannya cukup sederhana. Pada halaman ini hanya menampilkan tulisan header dan button untuk memulai proses Export ke dalam format excel.

## Step 4 - Definisikan route{#step-4}

Setelah update baru, codeigniter 4 secara default menonaktif-kan `autoroute` nya dan sebetulnya ini termasuk best practice. Jadi sekarang kita coba tambahkan route baru untuk halaman index dan proses export ke dalam format excel. Buka file `app/Config/Routes.php`, lalu temukan kode berikut ini.

```php
$routes->get('/', 'Home::index');
```

Kita modifikasi supaya halaman untuk export yang pertama kali ditampilkan ketika project kita run.

```php
$routes->get('/', 'User::index');
```

Selanjutnya kita tambahkan route untuk proses export.

```php
$routes->post('/user/export', 'User::export');
```

Ya, kita arahkan ke method `export()` yang ada di dalam class `User`.


## Uji Coba{#uji-coba}

Untuk uji coba, kita running dulu project kita. Kita buka terminal lalu run `command` berikut ini.

```bash
php spark serve
```

Selanjutnya buka browser, ketik url di addressbar. 

```
http://localhost:8080
```

Project kita akan menampilkan halaman yang berisi tulisan dan juga button untuk proses export ke excel. Selanjutnya kita klik button `Export excel` untuk memulai proses export ke excel.

Ya kita bisa lihat file excelnya bisa kita download.

## Penutup{#penutup}

Di edisi tutorial kali ini kita sudah coba membuat fitur untuk export ke dalam format excel menggunakan library PhpSpreadsheet. Kita coba untuk menuliskan file excel menggunakan class `Writer` dari library PhpSpreadsheet, yaitu class `PhpOffice\PhpSpreadsheet\Writer\Xlsx`. Dan setelah proses uji coba, berbeda dengan tutorial sebelumnya, di tutorial kali ini kita sudah bisa menuliskan dan menggenerate file excel (untuk saat ini) tanpa ada kendala. 

Meski sample code yang dicontohkan masih sederhana, semoga memudahkan kamu untuk memahami dasar pengembangan fitur yang menggunakan library. Semoga bermanfaat dan sampai jumpa di edisi tutorial berikutnya.