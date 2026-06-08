---
title: "Setup Minimalist Laravel Development Environment di Ubuntu 24.04"
slug: "setup-minimalist-laravel-development-environment-di-ubuntu-2404"
category: "How To Install"
date: "2024-05-01"
status: "published"
---

Mencari panduan lengkap cara setup Laravel development environment di Ubuntu 24.04 LTS? Tutorial ini akan memandu Anda langkah demi langkah dalam mengonfigurasi environment development Laravel di Ubuntu 24.04 LTS (Noble Numbat) yang baru dirilis pada tanggal 25 April 2024. Panduan ini dibuat berdasarkan pengalaman langsung saat melakukan fresh install Ubuntu 24.04 dan menyiapkan environment development untuk project Laravel. Anda akan mempelajari cara menginstal dan mengonfigurasi PHP 8.2, Composer, dan MySQL - tiga komponen utama yang diperlukan untuk memulai pengembangan aplikasi Laravel di Ubuntu terbaru.

Ubuntu 24.04 LTS (Noble Numbat) telah dirilis pada tanggal 25 April 2024 lalu. Karena terdapat problem di laptop saya, saya coba install ubuntu 24.04 di laptop dan mencoba setup environment untuk development beberapa project. Jadi tutorial kali ini kita akan membahas cara laravel development environment di Ubuntu 24.04.

## Overview{#overview}
Tutorial ini akan memandu Anda dalam menyiapkan environment development Laravel di Ubuntu 24.04 secara lengkap namun tetap praktis. Fokus panduan ini adalah memastikan Anda bisa mulai mengembangkan project Laravel dengan setup yang minimal namun optimal. Untuk mencapai hal tersebut, kita akan menginstal dan mengonfigurasi tiga komponen utama:

1. **PHP 8.2 dan Extension Pendukung Laravel**: Menginstal PHP versi terbaru yang stabil beserta extension yang diperlukan untuk development Laravel.
2. **Composer Package Manager**: Menginstal dan mengonfigurasi Composer untuk manajemen dependensi PHP dan instalasi Laravel.
3. **MySQL Database Server**: Menyiapkan dan mengonfigurasi MySQL sebagai database backend untuk aplikasi Laravel.

Target akhir dari tutorial ini adalah memastikan Anda bisa langsung mulai membuat, menginstal, dan menjalankan project Laravel baru setelah menyelesaikan semua langkah konfigurasi environment. Setiap langkah akan dijelaskan secara detail dengan command-command yang diperlukan beserta penjelasannya.

## Step 1: Install PHP 8.2 dan Ekstensinya{#step-1-install-php}
Untuk menginstall PHP 8.2 dan ekstensinya, buka terminal lalu run command-comand berikut ini
```
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:ondrej/php
sudo apt update
sudo apt install -y php8.2 php8.2-common php8.2-cli 
sudo apt install -y php8.2-bz2 php8.2-curl php8.2-gd php8.2-mbstring php8.2-mysql php8.2-sqlite3 php8.2-tidy php8.2-xml php8.2-xsl php8.2-zip php8.2-pgsql
```

Keterangan

1. **`sudo apt update`**: command ini digunakan untuk memperbarui daftar paket yang tersedia dari repositori yang diinstal di sistem kita. Ini memastikan bahwa kita memiliki informasi terbaru tentang paket yang tersedia untuk diinstal.

2. **`sudo apt install -y software-properties-common`**: command ini menginstal paket `software-properties-common`, yang menyediakan utilitas yang diperlukan untuk menambahkan repositori PPA.

3. **`sudo add-apt-repository -y ppa:ondrej/php`**: command ini menambahkan repositori PPA `ondrej/php` ke sistem Anda. Repositori ini dikelola oleh Ondřej Surý dan menyediakan paket PHP yang lebih baru dari yang disediakan oleh repositori bawaan Ubuntu.

4. **`sudo apt update`**: Setelah menambahkan repositori PPA baru, kita perlu memperbarui daftar paket lagi agar sistem kita menyadari paket-paket yang tersedia dari repositori baru tersebut.

5. **`sudo apt install -y php8.2 php8.2-common php8.2-cli`**: command ini menginstal paket inti PHP 8.2 beserta beberapa paket dasar yang diperlukan.

6. **`sudo apt install -y php8.2-bz2 php8.2-curl php8.2-gd php8.2-mbstring php8.2-mysql php8.2-sqlite3 php8.2-tidy php8.2-xml php8.2-xsl php8.2-zip php8.2-pgsql`**: command ini menginstal beberapa ekstensi PHP yang umum digunakan seperti mbstring, MySQL, Curl, dan lain-lain. Kita dapat menyesuaikan daftar ekstensi sesuai kebutuhan aplikasi kita.

Setelah menjalankan perintah-perintah ini, PHP 8.2 dan ekstensi yang dipilih akan diinstal di sistem kita.

Selanjutnya kita bisa run command berikut ini untuk mengecek versi php yang terinstall.

```
php -v
```

Output:
```
PHP 8.2.18 (cli) (built: Apr 11 2024 20:37:56) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.2.18, Copyright (c) Zend Technologies
    with Zend OPcache v8.2.18, Copyright (c), by Zend Technologies
```

## Step 2: Install Composer{#step-2-install-composer}
Untuk menginstall laravel kita perlu terlebih dahulu menginstall composer. Jadi sekarang kita install composer dengan run command berikut ini.

```
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'c8b085408188070d5f52bcfe4ecfbee5f727afa458b2573b8eaaf77b3419b0bf2768dc67c86944da1544f06fa544fd47') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
php composer-setup.php
php -r "unlink('composer-setup.php');"
```

Selanjutnya kita pindahkan composer ke direktori `/usr/local/bin`

```
sudo mv composer.phar /usr/local/bin/composer
```

Sekarang kita bisa run command composer.
```
composer
```
Output yang ditampilkan:
```
   ______
  / ____/___  ____ ___  ____  ____  ________  _____
 / /   / __ \/ __ `__ \/ __ \/ __ \/ ___/ _ \/ ___/
/ /___/ /_/ / / / / / / /_/ / /_/ (__  )  __/ /
\____/\____/_/ /_/ /_/ .___/\____/____/\___/_/
                    /_/
Composer version 2.7.4 2024-04-22 21:17:03

Usage:
  command [options] [arguments]

Options:
  -h, --help                     Display help for the given command. When no command is given display help for the list command

--- dan output lainnya ---
```

## Step 3: Install MySQL{#step-3-install-mysql}
Step berikutnya adalah menginstall MySQL, buka terminal lalu run command berikut ini.

```
sudo apt install mysql-server
```

Setelah selesai kita atur password untuk user `root`, buka kembali terminal lalu run command berikut ini untuk masuk ke console MySQL.
```
sudo mysql
```

Pada console MySL ketik command berikut untuk setup password user `root`.
```
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
```

Selanjutnya run command berikut ini untuk keluar dari console MySQL
```
exit
```
Output:
```
mysql> exit;
Bye
```

Selanjutnya kita bisa masuk ke mysql dengan menggunakan user root.
```
mysql -u root -p
```
Masukkan `password` sebagai password untuk user root.

Output:
```
$ mysql -u root -p
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 15
Server version: 8.0.36-2ubuntu3 (Ubuntu)

Copyright (c) 2000, 2024, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> 

```
Tanda bahwa kita berhasil setting password untuk user root.

## Step 4: Test Install Laravel{#step-4-test-install-laravel}
Sekarang kita akan coba untuk menginstall laravel.

Buka terminal lalu run command berikut ini untuk menginstall laravel melalui `composer`.
```
composer create-project --prefer-dist laravel/laravel sample-app
```

Tunggu sampai proses install laravel selesai.

Apabila laravel berhasil diinstall tanpa kendala, ini berarti **environment development yang kita siapkan sudah sesuai**.

Selanjutnya masuk ke direktori project
```
cd sample-app
```

Di sini kita coba atur konfigurasi database, kita hubungkan dengan mysql yang sebelumnya sudah kita install.

Selanjutnya buka file `.env` di code editor, lalu kita modifikasi `DB_CONNECTION` menjadi `mysql` dan kita sesuaikan konfigurasi databasenya.

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_belajar
DB_USERNAME=root
DB_PASSWORD=password
```

Save kembali file `.env`.

Bisa kita lihat pada baris kode di atas, kita atur root sebagai `DB_USERNAME` dan `password` sebagai `DB_PASSWORD` yang sebelumnya sudah kita setting ketika setup password untuk user root. Untuk `DB_DATABASE` kita isi dengan `db_belajar` dan sebagai catatan database `db_belajar` belum kita buat.

Selanjutnya kita run migrate command.
```
php artisan migrate
```

Tampil warning di output yang ditampilkan di terminal, karena `db_belajar` belum kita buat.
```
   WARN  The database 'db_belajar' does not exist on the 'mysql' connection. 
```

Di sini kita bisa langsung buat database, pilih `yes` lalu enter untuk melanjutkan.

Output di terminal:
```
$ php artisan migrate

   WARN  The database 'db_belajar' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ Yes                                                          │
 └──────────────────────────────────────────────────────────────┘

   INFO  Preparing database.  

  Creating migration table ...................................... 25.71ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table ......................... 117.40ms DONE
  0001_01_01_000001_create_cache_table .......................... 42.43ms DONE
  0001_01_01_000002_create_jobs_table .......................... 104.85ms DONE


```


Kita run project
```
php artisan serve
```

Dan selanjutnya kita akses project melalui url `http://127.0.0.1:8000/` di browser dan kita bisa lihat laravel berhasil dirun.

## Kesimpulan{#kesimpulan}
Selamat! Anda telah berhasil menyiapkan environment development Laravel di Ubuntu 24.04 dengan konfigurasi yang minimal namun powerful. Mari kita rangkum apa yang telah kita capai dalam tutorial ini:

1. **Setup Komponen Inti**:
   - Instalasi PHP 8.2 dengan semua ekstensi yang diperlukan Laravel
   - Konfigurasi Composer sebagai package manager
   - Setup MySQL database server dengan konfigurasi dasar yang aman

2. **Verifikasi Keberhasilan**:
   - Laravel berhasil diinstal tanpa error
   - Database terhubung dan berfungsi dengan baik
   - Aplikasi dapat dijalankan di environment lokal

Dengan mengikuti panduan ini, Anda kini memiliki environment development yang siap digunakan untuk mengembangkan aplikasi Laravel. Setup minimal ini memberikan fondasi yang solid untuk memulai project Laravel Anda di Ubuntu 24.04.

Untuk langkah selanjutnya, Anda bisa mulai membuat project Laravel baru atau mengimpor project yang sudah ada ke environment ini. Selamat coding!

## Langkah Selanjutnya: Setup Tambahan untuk Development{#next-steps}
Setelah berhasil menyiapkan environment dasar Laravel, Anda mungkin memerlukan Node.js untuk development frontend atau ingin mengatur environment serupa di sistem operasi Windows. Berikut adalah panduan lanjutan yang bisa Anda ikuti:

1. **Setup Node.js di Ubuntu**:
   Untuk development modern Laravel yang sering menggunakan tools JavaScript seperti Vite atau Mix, Anda perlu menginstal Node.js. Ikuti panduan lengkap [cara install multiple Node.js version menggunakan NVM di Ubuntu](https://qadrlabs.com/post/cara-install-multiple-node-js-version-menggunakan-nvm-di-ubuntu-22-04) untuk fleksibilitas dalam mengelola berbagai versi Node.js.

2. **Setup di Windows**:
   Jika Anda juga bekerja dengan Windows atau ingin menyiapkan environment development Laravel di Windows, Anda bisa mengikuti tutorial lengkap [setup Laravel development environment di OS Windows](https://qadrlabs.com/post/setup-laravel-development-environment-di-os-windows).

Kedua tutorial tersebut akan melengkapi pemahaman Anda tentang setup Laravel development environment di berbagai platform dan membantu Anda menyiapkan tools tambahan yang diperlukan untuk development modern.