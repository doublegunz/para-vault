---
title: "Cara Memperbaiki Error Pada Saat Install CodeIgniter 4"
slug: "cara-memperbaiki-error-pada-saat-install-codeigniter-4"
category: "CodeIgniter 4"
date: "2021-09-05"
status: "published"
---

Salah satu kendala yang sering terjadi pada saat menginstall CodeIgniter 4 adalah belum terinstallnya extension yang menjadi [requirement untuk CodeIgniter 4](https://qadrlabs.com/post/seri-tutorial-codeigniter-4-crud-codeigniter-4#step-1-persiapan-development). Kendala tersebut merupakan hal yang sering ditanyakan di komunitas programmer yang saya ikuti. Dan umumnya kendala ini sering dijumpai pada saat menggunakan XAMPP di OS Windows. Dan boleh jadi untuk yang menggunakan linux juga pernah mengalaminya. Kira-kira seperti apa kendala yang sering ditanyakan dan **bagaimana cara memperbaiki error pada saat instalasi CodeIgniter 4**? Yuk kita bahas!

## Simulasi error dan proses debug{#simulasi-error}

Pada percobaaan kali ini, saya mencoba untuk mereproduksi error ataupun kendala yang sering menjadi pertanyaan di forum programmer. Untuk menghasilkan error yang sama, saya coba disable salah satu extension, lalu saya mencoba untuk membuat project codeigniter 4 baru melalui `composer`. Kurang lebih output yang ditampilkan pada saat membuat project baru seperti yang terlihat di bawah ini.

```php
$ composer create-project codeigniter4/appstarter tes-intl-error
Creating a "codeigniter4/appstarter" project at "./tes-intl-error"
Installing codeigniter4/appstarter (v4.6.0)
  - Installing codeigniter4/appstarter (v4.6.0): Extracting archive
Created project in /home/gun-gun-priatna/learning-lab/testing-tutorial/tes-intl-error
Loading composer repositories with package information
Updating dependencies
Your requirements could not be resolved to an installable set of packages.

  Problem 1
    - codeigniter4/framework[4.0.0, ..., v4.6.0] require ext-intl * -> it is missing from your system. Install or enable PHP's intl extension.
    - Root composer.json requires codeigniter4/framework ^4.0 -> satisfiable by codeigniter4/framework[4.0.0, ..., v4.6.0].


```

Baik, kurang lebih sama dengan pesan error yang ditanyakan di forum, mungkin yang berbeda dari pesan di atas di bagian direktori project disimpan.

Pada saat kita menemukan pesan error seperti di atas, hal yang pertama kita lakukan adalah membaca pesan error tersebut. Pada pesan error yang ditampilkan, terdapat petunjuk penyebab errornya. 

1. Petunjuk pertama terdapat pada tulisan `Your requirements could not be resolved to an installable set of packages.`, ini artinya ada requirement yang belum terinstall untuk melanjukan proses instalasi. 
2. Petunjuk kedua terdapat pada tulisan ` codeigniter4/framework[4.0.0, ..., v4.1.3] require ext-intl * -> it is missing from your system`. Pesan ini menunjukan requirement apa yang belum terpenuhi atau belum terinstall. Dan di sini tertulis jelas, kita perlu menginstall `ext-intl` untuk melanjutkan proses instalasi.

Dari proses debug error ini, kita bisa mengetahui penyebab errornya, yaitu belum terinstallnya `intl` extension. Jadi solusi untuk memperbaiki error ini adalah dengan cara menginstall `intl` extension dan tentu langkah berikutnya adalah memperbaiki errornya dengan cara menginstall `Intl` extension tersebut. 

## Cara mengaktifkan Intl extension di Xampp Windows{#aktifkan-extension-intl-windows}

Karena umumnya yang menemukan kendala ini adalah yang menggunakan Xampp, kita coba perbaiki kendala `intl extension` di Xampp terlebih dahulu. *Jadi bagaimana cara menginstall `intl extension` di Xampp?* Jawabannya adalah kita tidak perlu menginstall ekstensi tersebut, karena ekstensi `intl` biasanya sudah ikut terinstall pada saat kita install Xampp bersama dengan extension-extension lainnya. Jadi kita hanya perlu mengaktifkan `intl extension`.

Berikut ini adalah langkah-langkah untuk mengaktifkan ekstensi `intl` di XAMPP.

1. Buka XAMPP Control Panel.
2. Stop Apache server, apabila server sedang running.
3. Buka file `php.ini` dengan cara menekan tombol `Config` atau bisa juga langsung akses di `C:\xampp\php\php.ini`.

![Buka php.ini](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/bug-fix/2-open-control-panel-xampp.png)

4. Setelah itu, kita bisa lihat file `php.ini` terbuka di Notepad (atau text editor yang diset default), tekan tombol `Ctrl + F` dan cari `;extension=intl`. 
5. Setelah ketemu, hapus tanda titik koma.

![cari extension](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/bug-fix/3-uncomment-titik-koma.png)

6. Save kembali file `php.ini`, setelah itu restart Apache server.

## Cara mengaktifkan Intl extension di Ubuntu{#enable-intl-extension-ubuntu}

Nah untuk yang menggunakan OS Ubuntu, sebagai asumsi lingkungan kerja tidak menggunakan XAMPP untuk linux, melainkan menginstall langsung Apache Server, dan PHP nya satu persatu. Dan kebetulan kita belum menginstall `Intl` extension. Baik kita coba install extension nya melalui terminal. Buka terminal lalu run `command` berikut ini.

```php
sudo apt-get install php-intl
```

Sebagai info, kita tidak perlu menuliskan nomer versi pada PHP versi 7, misalnya `php7.2-intl`. Kita bisa langsung run `command` seperti di atas.

Setelah itu, kita restart apache.

```php
sudo service apache2 restart
```

Selanjutnya kita bisa cek apakah extensionnya sudah terinstall atau belum menggunakan `command`.

```php
php -m | grep intl
```

Kita bisa lihat outputnya apabila extension sudah terinstal.
Output:
```
$ php -m | grep intl
intl
```

## Tes Buat Project Baru{#tes-buat-project}

Setelah `intl` extension kita aktifkan, kita bisa mencoba kembali untuk membuat project baru menggunakan `composer`.

```php
composer create-project codeigniter4/appstarter tes-project
```

Dan kita bisa lihat `codeigniter 4` bisa terinstall dengan baik.

## Kesimpulan{#kesimpulan}

Lupa menginstall ekstension yang menjadi requirement menjadi salah satu penyebab error dan merupakan kendala yang sering kita alami ketika instalasi CodeIgniter 4. Kabar baiknya kita bisa memperbaiki error ini dengan cara mengaktifkan extension apabila menggunakan XAMPP di OS Windows dan menginstallnya langsung apabila kita menggunakan OS Ubuntu. Dan tentu saja melakukan [persiapan development](https://qadrlabs.com/post/seri-tutorial-codeigniter-4-crud-codeigniter-4#step-1-persiapan-development) terlebih dahulu itu selalu lebih baik.

Pada postingan ini, kita sudah mencoba untuk mereproduksi error, cara membaca dan memahami pesan error, dan juga cara memperbaiki error dengan cara menginstall `intl` extension atau pun mengaktifkan extension tersebut untuk OS windows dan juga ubuntu. 

Semoga uraian pada percobaan kali ini bermanfaat dan sampai jumpa kembali di postingan berikutnya.