---
title: "Panduan Install Laravel Herd dan MySQL di Windows"
slug: "panduan-install-laravel-herd-dan-mysql-di-windows"
category: "How To Install"
date: "2024-10-24"
status: "published"
---

## Pendahuluan{#pendahuluan}
Pada saat [Setup Laravel Development Environment di OS Windows](https://qadrlabs.com/post/setup-laravel-development-environment-di-os-windows), saya sempat menyebutkan tools alternatif laragon yang dapat kita gunakan untuk development aplikasi berbasis web, yaitu laravel herd. Laravel Herd merupakan solusi all-in-one untuk pengembangan aplikasi Laravel di sistem operasi Windows. Dengan Laravel Herd, proses setup environment development Laravel menjadi lebih mudah karena sudah mencakup PHP, Composer, Node.js dan tools pendukung lainnya dalam satu installer. Pada tutorial ini, kita akan membahas langkah demi langkah cara menginstall Laravel Herd, dilanjutkan dengan instalasi MySQL sebagai database server, dan diakhiri dengan uji coba membuat project Laravel baru. Tutorial ini cocok untuk pemula yang ingin memulai pengembangan aplikasi menggunakan Laravel di Windows dengan cara yang lebih praktis dan straightforward. Selain itu dapat menjadi alternatif juga ketika teman-teman mengalami kendala pada saat [setup laragon](https://qadrlabs.com/post/panduan-update-versi-php-di-laragon).

Mari kita mulai proses instalasinya!

## Overview{#overview}
Panduan ini akan membahas tiga bagian utama dalam setup environment development Laravel menggunakan Laravel Herd di Windows:

1. **Instalasi Laravel Herd**  
   Bagian ini mencakup proses download, instalasi, dan konfigurasi awal Laravel Herd sebagai all-in-one development environment yang menyediakan PHP, Composer, Node.js dan tools pendukung lainnya.

2. **Instalasi MySQL**  
   Karena Laravel Herd versi free tidak menyediakan MySQL, kita akan bahas cara instalasi MySQL secara terpisah sebagai database server untuk aplikasi Laravel.

3. **Uji Coba Project Laravel**  
   Pada bagian terakhir, kita akan mencoba membuat project Laravel baru menggunakan Laravel Herd, melakukan konfigurasi database, dan menjalankan migration untuk memastikan environment development berjalan dengan baik.

Setiap bagian akan dijelaskan secara detail dengan langkah-langkah yang disertai screenshot untuk memudahkan pemahaman. Mari kita mulai dengan instalasi Laravel Herd!
## Install Laravel Herd{#install-laravel-herd}
Pada bagian pertama ini kita akan coba install Laravel Herd. Berikut ini adalah langkah-langkahnya.
### 1. Download Laravel Herd
Sekarang kita akses situr resmi [https://herd.laravel.com/windows](https://herd.laravel.com/windows). Pada halaman web Laravel Herd Kita bisa lihat button **Download for Windows**. Untuk memulai proses download Laravel Herd installer, tekan button tersebut. Kita tunggu sampai proses download selesai. Setelah selesai kita bisa lihat ada file `Herd-1.11.1-setup.exe` (Versi laravel herd installer pada saat panduan ini ditulis).

### 2. Run Laravel Herd Installer
Setelah laravel herd installer selesai kita download, kita run installler dengan cara **run as adminstrator**, lalu ikuti langkah-langkahnya sampai proses install selesai.

**Catatan:** Laravel herd perlu permission sebagai admin supaya installer dapat menambahkan HerdHelper service yang bertanggung jawab untuk memperbaharui file `hosts`, map direktori dan link project ke domain `.test`.


### 3. Run Laravel Herd
Setelah proses instalasi selesai, selanjutnya kita bisa run langsung laravel herd yang sudah kita install. Ketika pertama kali laravel herd kita run, kita akan membuka windows untuk setup awal. Untuk melanjutkan, kita tekan button **Let's get started** untuk memulai proses setup awal laravel herd. 

![tampilan awal laravel herd setelah install](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/1%20tampilan%20awal%20setelah%20install.png)

Selanjutnya laravel herd akan mendownload php, node js dan tools lainnya. 
![install php, nodejs dan lain-lain](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/2%20install%20php%208.3.png)

Setelah proses download selesai, selanjutnya akan masuk ke windows untuk aktivasi laraverd herd pro. Kita bisa tekan link **Skip for now** untuk menyelesaikan proses setup laravel herd.

![aktivasi laravel pro](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/3.%20aktivasi%20laravel%20herd%20pro.png)

Selanjutnya kita bisa lihat windows setup completed. Kita bisa pilih tekan button **Open Dashboard** untuk membuka dashboard Laravel herd.
![tampilan setup laravel herd selesai](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/4%20tampilan%20setup%20laravel%20herd%20selesai.png)

Kita bisa lihat tampilan dashboard laravel herd. Pada dashboard kita bisa lihat informasi seperti service yang aktif, menu untuk laravel herd pro, dan quick access dengan button ke halaman untuk mengelola project kita.
![tampilan dashboard laravel herd](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/5%20tampilan%20dashboard%20laravel%20herd.png)

Selanjutnya kita akan coba cek php, laravel, composer dan nodejs yang terinstall dengan run command berikut ini di command prompt windows atau [Cmder](https://qadrlabs.com/post/setup-laravel-development-environment-di-os-windows#tools-1).
```
php --version
laravel --version
composer --version
node --version
```

Ketika command di atas kita run akan tampil output berikut ini.
```
C:\Users\[nama user]>php --version
PHP 8.3.12 (cli) (built: Sep 24 2024 20:22:14) (NTS Visual C++ 2019 x64)
Copyright (c) The PHP Group
Zend Engine v4.3.12, Copyright (c) Zend Technologies
    with Zend OPcache v8.3.12, Copyright (c), by Zend Technologies

C:\Users\[nama user]>laravel --version
Laravel Installer 5.8.5

C:\Users\[nama user]>composer --version
Composer version 2.7.7 2024-06-10 22:11:12
PHP version 8.3.12 (C:\Users\InformatikaUMMI\.config\herd\bin\php83\php.exe)
Run the "diagnose" command to get more detailed diagnostics output.

C:\Users\[nama user]>node --version
v23.0.0
```

## Install MySQL {#install-mysql}
Seperti yang telah disebutkan sebelumnya, laravel herd versi free tidak menyediakan MySql. Jadi kita coba install MySQL secara terpisah. Berikut ini adalah langkah-langkah install MySQL di windows.

### 1. Download MySQL Installer
Kita akses halaman [https://dev.mysql.com/downloads/installer/](https://dev.mysql.com/downloads/installer/) terlebih dahulu.
![akses halaman download mysql installer](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/mysql-windows/1%20akses%20web%20mysql%20dan%20download.png)

Pada halaman ini kita bisa lihat terdapat dua opsi untuk download mysql installer. Di sini kita pilih opsi installer yang sizenya 305.4 M, supaya nanti kita tidak perlu download lagi pada saat proses install. Kita download `mysql-installer-community-8.0.40.0.msi` dengan tekan button **Download**.  Selanjutnya kita akan diminta untuk login atau sign up, kita klik link **No thanks, just start my download** (link ini ada di bawah) untuk melanjutkan proses download. Tunggu sampai proses download selesai.

### 2. Run MySQL Installer 
Selanjutnya kita bisa langsung run file `mysql-installer-community-8.0.40.0.msi` yang baru saja kita download, lalu kita ikuti langkah-langkahnya. Untuk setiap konfigurasi kita atur default dan satu-satunya yang kita ubah atau sesuaikan adalah credential mysql. 
Pada konfigurasi mysql ini, kita bisa atur password **Root**.

![atur password root mysql](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/mysql-windows/9%20konfigurasi%20password%20root%20mysql.png)

Password mysql ini nanti akan kita gunakan pada saat uji coba install project laravel. Selain credential mysql, terdapat tahapan pengaturan windows service.
![konfigurasi windows service](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/mysql-windows/10%20konfigurasi%20windows%20service.png)
Pada isian `Windows Service Name`, secara default namanya `MySQL80`. Windows service name ini kita gunakan pada saat mengelola service mysql untuk run `start`, `stop`, `pause` dan `restart` mysql service.

Lanjutkan rangkaian langkah-langkah instalasi MySql sampai selesai.

![apply configuration](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/mysql-windows/12%20konfigurasi%20apply%20configuration.png)

![memulai proses apply configuration](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/mysql-windows/13%20proses%20apply%20configuration.png)

![Finish configuration](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/mysql-windows/14%20finish%20konfigurasi.png)

![Next step installation](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/mysql-windows/15%20next%20step%20installation.png)

![Finish installation](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/mysql-windows/16%20finish%20installation.png)

### 3. Manage MySQL 
Setelah proses instalasi selesai, kita bisa kelola service mysql menggunakan aplikasi services windows. Search `Services` dari start bar, lalu klik `Services` untuk run aplikasi Services windows. 

![Search service app windows](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/mysql-windows/17%20search%20service%20di%20start%20bar.png)

Di dalam aplikasi tersebut, kita bisa lihat daftar service. Cari MySQL service (`MySQL80`) dan ketika kita klik mysql service, kita bisa run `stop`, `pause` dan `restart` service mysql.
![service mysql](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/mysql-windows/18%20manage%20service%20mysql.png)

## Uji Coba Install Laravel{#uji-coba-install-laravel}
Setelah menginstall laravel herd dan mysql, kita bisa langsung coba install project baru menggunakan framework laravel. Untuk menginstall project baru, kita bisa gunakan dua cara. Cara yang pertama menggunakan command prompt windows dan cara kedua menggunakan fitur yang tersedia di laravel herd. Karena sekarang kita sedang membahas tentang laravel herd, jadi kita coba gunakan fitur buat project baru di laravel herd.

Baik, mari kita mulai uji coba install laravel menggunakan fitur di laravel herd.

Pertama kita buka kembali dashboard Laravel Herd, lalu kita klik **Open Sites** untuk membuka daftar project.
![Akses site list di laravel herd](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/test-install-laravel/1%20akses%20list%20site.png)

Karena kita baru install laravel herd, tentu daftar project kita masih kosong. Untuk membuat project baru, kita klik **Add Site**.
![Klik add site](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/test-install-laravel/2%20klik%20add%20site.png)

Lalu pada windows Create New Site, kita pilih **New Laravel Project** dan klik button **Next** untuk melanjutkan.
![Create new laravel project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/test-install-laravel/3%20buat%20new%20laravel%20project.png)

Setelah itu kita pilih **No Starter Kit** dan klik kembali button **Next** untuk melanjutkan.
![Pilih starter kit](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/test-install-laravel/4%20buat%20new%20laravel%20project%20-%20pilih%20starter%20kit.png)

Pada windows selanjutnya kita isi nama projectnya `belajar_laravel`, setelah itu kita klik **Next**.
![isi nama project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/test-install-laravel/5%20buat%20new%20laravel%20project%20-%20isi%20nama%20project.png)

Pada windows selanjutnya kita bisa lihat proses inisiasi create project. Kita tunggu sampai prosesnya selesai.
![inisiasi create project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/test-install-laravel/6%20buat%20new%20laravel%20project%20-%20proses%20inisiasi%20project.png)

Ketika proses create project selesai, kita bisa tes run di browser dengan cara klik **Open In Browser**.
![klik open in browser](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/test-install-laravel/7%20run%20project%20di%20browser.png)

Kita bisa lihat tampilan awal laravel di browser setelah kita klik button Open In Browser.
![new project created](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/test-install-laravel/8%20new%20project%20created.png)

Oke kita kembali ke dashboard laravel dan kita bsa lihat di daftar site yang sebelumnya kosong kini menampilkan project yang baru saja kita buat.
![informasi project di dashboard laravel herd](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/test-install-laravel/9%20informasi%20project%20setelah%20proses%20buat%20project%20baru.png)

Selanjutnya kita akan coba buat setup konfigurasi database dan run `migrate` command. Untuk setup konfigurasi project kita buka project laravel kita di visual studio code dan untuk run command kita bisa gunakan command prompt windows atau Cmder (apabila sudah terinstall).

Sekarang kita coba buka command prompt langsung dari dashboard laravel herd dengan cara klik **Open** untuk terminal.
![klik Open untuk buka command prompt](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/test-install-laravel/10%20klik%20open%20untuk%20buka%20cmd.png)

Ketika command prompt dibuka setelah kita klik Open, kita bisa lihat command prompt langsung mengarah ke direktori project `belajar_laravel`, jadi kita tidak perlu pindah direktori.

Selanjutnya kita run command `code .` untuk membuka project `belajar_laravel` di visual studio code.
![run command untuk buka visual studio code](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/test-install-laravel/11%20run%20command%20untuk%20buka%20vscode.png)

Setelah project `belajar_laravel` terbuka di visual studio code, buka file `.env`, lalu kita coba sesuaikan konfigurasi database.
![setup konfigurasi database](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/test-install-laravel/12%20setup%20konfigurasi%20database.png)

Sebagai contoh di sini saya isi konfigurasi seperti berikut ini.
```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_belajar_laravel
DB_USERNAME=root
DB_PASSWORD=password
```

Di sini saya coba isi nama database dengan `db_belajar_laravel` dan credential mysql seperti yang saya isi ketika kita install MySql.

Setelah selesai jangan lupa save kembali file `.env` dan setelah itu kita coba run `php artisan migrate`. Apabila tampil prompt `database does not exist, would you like to create it`, ketik `yes` lalu enter untuk membuat database baru dengan nama `db_belajar_laravel` dan melanjutkan proses `migrate`.

![run php artisan migrate](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/test-install-laravel/13%20run%20php%20artisan%20migrate%20command.png)

Kalau lihat output yang ditampilkan di command prompt kita bisa lihat database dan table berhasil kita buat. Untuk memastikan kita akan cek melalui adminer. Untuk membuka adminer, kita klik Open di windows project kita di laravel herd.
![buka adminer via laravel herd](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/test-install-laravel/14%20klik%20open%20adminer.png)

Selanjutnya kita masukan credential mysql dan nama database sesuai dengan yang kita atur d file `.env`, lalu tekan button **Login**.
![login ke database via adminer](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/test-install-laravel/15%20login%20ke%20database%20via%20adminer.png)

Di adminer, kita bisa lihat daftar table yang berhasil kita migrate menggunakan `migrate` command.
![tampilan daftar table di database](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laravel-herd/test-install-laravel/16%20database%20dan%20table%20berhasil%20dibuat.png)

## Penutup{#penutup}

Demikianlah langkah-langkah menginstall Laravel Herd dan MySQL sebagai environment development Laravel di Windows. Seperti yang kita lihat, Laravel Herd sangat memudahkan proses setup karena mengintegrasikan berbagai tools development dalam satu aplikasi. Mulai dari instalasi Laravel Herd, setup MySQL, hingga pembuatan project pertama dan konfigurasi database, semuanya dapat dilakukan dengan lebih efisien. Dengan environment development yang sudah siap, Anda dapat langsung fokus untuk belajar dan mengembangkan aplikasi menggunakan Laravel. Selamat mencoba dan semoga tutorial ini bermanfaat untuk memulai perjalanan Anda dalam pengembangan aplikasi web menggunakan Laravel!