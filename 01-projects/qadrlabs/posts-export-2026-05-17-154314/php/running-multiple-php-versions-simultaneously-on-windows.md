---
title: "Running multiple PHP versions simultaneously on windows"
slug: "running-multiple-php-versions-simultaneously-on-windows"
category: "php"
date: "2024-11-29"
status: "published"
---

Ketika menangani project, saya selalu menggunakan OS Ubuntu untuk development project. Dalam menangani project tersebut, tidak semua project menggunakan stack terbaru. Sebagian besar masih menggunakan stack lama dengan php versi lama juga. Untuk running project dengan versi php berbeda secara bersamaan sudah saya tuliskan di tutorial [Running Beberapa Versi PHP secara bersamaan di Ubuntu 22.04](Running Beberapa Versi PHP secara bersamaan di Ubuntu 22.04). Beberapa waktu yang lalu saya tidak membawa laptop dan saya harus melakukan proses maintainance project yang menggunakan framework codeigniter 3 dan juga laravel, di mana versi php yang digunakan berbeda. Selain itu project tersebut saling terintegrasi dan harus dijalankan secara bersamaan. Untuk maintainance project tersebut saya meminjam laptop yang kebetulan menggunakan Windows 11. Dalam kondisi tersebut muncul pertanyaan, **Bagaimana cara running project dengan versi php yang berbeda secara bersamaan?**.

Pertanyaan tersebut terjawab ketika saya menuliskan [Panduan Install Laravel Herd dan MySQL di Windows](https://qadrlabs.com/post/panduan-install-laravel-herd-dan-mysql-di-windows) dan setelah membaca dokumentasi resmi Laravel Herd. Berdasarkan dokumentasi laravel herd[^1], kita bisa gunakan versi php tertentu untuk aplikasi tertentu. Untuk setting versi php tertentu, kita bisa gunakan dua cara, yang pertama melalui GUI laravel herd dan yang kedua melalui cli. Untuk mencoba fitur laravel herd tersebut, kita akan coba bahas pada tutorial ini.

## Overview {#overview}
Pada tutorial ini kita akan coba gunakan fitur php per site dari laravel herd untuk run project dengan versi php yang berbeda secara bersamaan. Sebagai studi kasus, kita akan coba simulasikan sesuai dengan kondisi yang saya alami. Kita akan running dua project di mana ketika kita run kedua project tersebut, di browser akan tampil versi php yang digunakan.

![Overview project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/17-buka-phpinfo-di-kedua-project.png)

Untuk project pertama kita akan gunakan project laravel hasil uji coba dari [Panduan Install Laravel Herd dan MySQL di Windows](https://qadrlabs.com/post/panduan-install-laravel-herd-dan-mysql-di-windows) yang sebelumnya kita beri nama `belajar_laravel` dan PHP versi 8.3. Untuk project kedua, kita gunakan codeigniter 3 yang terbaru dengan PHP versi 8.1.

Karena project pertama sudah tersedia hasil dari panduan sebelumnya, jadi yang akan kita lakukan di tutorial ini adalah
1. Install PHP 8.1
2. Setup Project CodeIgniter 3
3. Coding untuk menampilkan versi php di project codeigniter 3
4. Coding untuk menampilkan versi php di project laravel
5. Uji coba running kedua project secara bersamaan.

## Step 1 - Install PHP 8.1{#step-1-install-php-8.1}
Pada panduan sebelumnya, php yang terinstall setelah kita install laravel herd adalah PHP versi 8.3. Jadi sekarang kita akan tambahkan versi php yang akan kita gunakan untuk uji coba tutorial ini, yaitu PHP versi 8.1. Untuk install php 8.1, kita buka Laravel Herd terlebih dahulu, lalu tekan menu **PHP** untuk menampilkan windows PHP. Pada windows PHP, kita bisa lihat daftar PHP yang terinstall maupun yang belum terinstall. Selanjutnya kita tekan button **Install** sebelah PHP 8.1 untuk install PHP 8.1.

![install php 8.1](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/1-install-php-8-1.png)

Setelah kita tekan button tersebut, laravel herd akan memulai proses download dan proses install PHP 8.1.

![memulai proses install php 8.1](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/2-proses-install-php-8-1.png)

Kita tunggu sampai proses install PHP 8.1 selesai.

## Step 2 - Setup Project CodeIgniter 3{#step-2-setup-project-codeigniter}
Selanjutnya kita buka halaman [Download codeigniter 3](https://codeigniter.com/userguide3/installation/downloads.html), lalu tekan link **CodeIgniter v3.1.13 (Current version)** untuk download codeigniter 3 terbaru.
![download codeigniter 3](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/3-download-codeigniter-3.png)

Setelah selesai download, Extract file `CodeIgniter-3.1.13.zip`, lalu pindahkan ke direktori laravel herd `C:\Users\[username]\Herd` dan kita rename menjadi `belajar_ci3`. 

![extract dan rename menjadi belajar_ci3](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/4-extract-dan-rename-ci3.png)

Sebagai catatan, isi dari folder `belajar_ci3` ini terdapat folder dari framework codeigniter 3 seperti `application` dan  `system`.

Selanjutnya kita buka kembali Laravel Herd, lalu kita tekan button **Open Sites** untuk melihat daftar project yang tersedia.
![buka dashboard Laravel Herd lalu tekan open site](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/5-buka-dashboard-herd.png)

Pada windows `sites`, kita bisa lihat project `belajar_ci3` dan kita bisa lihat preview dengan error karena codeigniter 3 tidak support versi php 8.3.
![buka project belajar ci](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/6-buka-project-belajar-ci.png)

Selanjutnya kita ubah versi php yang kita gunakan untuk project `belajar_ci3` menjadi 8.1 seperti yang ditampilkan pada gambar berikut ini.
![ubah versi php ke php 8.1](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/7-ubah-versi-php-ke-php-8-1.png)

Setelah itu kita bisa coba run project dengan menekan link `http://belajar_ci3.test`.
![buka project belajar ci di browser](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/8-buka-project-ci.png)

Setelah kita tekan link tersebut, kita bisa lihat project `belajar_ci3` dibuka di browser.
![project di-run di browser](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/9-run-project-ci-di-browser.png)

Sekarang kita tambahkan kode untuk menampilkan informasi versi php yang digunakan. Buka project `belajar_ci3` di visual studio code. Arahkan ke `C:\Users\[username]\Herd`, lalu pilih folder `belajar_ci3` untuk membuka project di visual studio code.
![buka project belajar_ci di vscode](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/10-buka-project-ci-di-vscode.png)

Setelah itu kita klik icon `New File` untuk membuat file baru dengan nama `info.php`.
![buat file info.php](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/11-buat-file-info-php.png)

Pada file `info.php`, kita ketik baris kode berikut ini.
```
<?php phpinfo(); ?>
```

![tambahkan kode](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/12-coding-phpinfo.png)

Save kembali file `info.php`.

## Step 3 - Modifikasi Project Laravel {#step-3-modifikasi-project-laravel}
Pada panduan sebelumnya kita sudah setup project laravel dengan nama `belajar_laravel`, sekarang kita buka kembali project tersebut menggunakan visual studio code. Pada menu visual studio code, kita klik menu **File**, lalu pilih menu **Open Folder**.
![buka project belajar_laravel di vscode](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/13-pilih-open-folder-untuk-buka-project-laravel.png)

Selanjutnya kita arahkan kembali ke direktori laravel herd, lalu pilih folder `belajar_laravel`, dan klik **Select Folder** untuk membuka project di visual studio code.
![pilih folder project belajar_laravel](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/14-pilih-folder-belajar-laravel.png)

Selanjutnya kita buka file `routes/web.php`, lalu kita ubah route default project laravel menjadi seperti pada gambar berikut ini.
![coding phpinfo di route](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/15-coding-phpinfo-di-route.png)

```
Route::get('/', function () {
    return phpinfo();
});
```
Save kembali file `routes/web.php`. 

## Step 4 - Uji coba {#step-4-uji-coba}
Selanjutnya kita akan uji coba dengan membuka kedua project secara bersamaan. Pertama kita buka project laravel bisa langsung akses di browser atau klik link `http://belajar_laravel.test` di UI laravel herd.
![buka project detail untuk project belajar_laravel](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/16-buka-project-laravel.png)
Untuk project codeigniter, kita akses url `http://belajar_ci3/info.php` di tab kedua. Kita run kedua project ini secara bersamaan seperti yang ditampilkan pada gambar berikut ini.

![uji coba project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/run-multiple-php-version/17-buka-phpinfo-di-kedua-project.png)

Seperti yang terlihat pada gambar di atas, project codeignite 3 menggunakan php versi 8.1.31. Sedangkan project laravel menggunakan php versi 8.3.12.

## Penutup{#penutup}
Pada tutorial ini kita sudah coba solusi untuk run project dengan versi php berbeda secara bersamaan. Solusi yang kita gunakan adalah dengan menggunakan fitur dari laravel herd untuk menggunakan php versi tertentu yang di-isolate ke project tertentu. Pada tutorial ini kita coba gunakan fitur tersebut untuk run dua project, yaitu project codeigniter 3 dengan php versi 8.1 dan project laravel dengan php versi 8.3. Dan seperti yang kita lihat pada hasil uji coba, kita bisa run project tersebut secara bersamaan dengan menampilkan versi php yang digunakan.


[^1]: Per-site php versions @ [https://herd.laravel.com/docs/windows/1/advanced-usage/php-versions#per-site-php-versions](https://herd.laravel.com/docs/windows/1/advanced-usage/php-versions#per-site-php-versions)