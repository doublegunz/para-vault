---
title: "Tutorial CodeIgniter 4: Login dan Register menggunakan CodeIgniter Shield"
slug: "tutorial-codeigniter-4-login-dan-register-menggunakan-codeigniter-shield"
category: "CodeIgniter 4"
date: "2024-08-11"
status: "published"
---

Membangun sistem otentikasi yang aman dan andal adalah elemen kunci dalam pengembangan aplikasi web. Dengan CodeIgniter 4, kita memiliki tools yang powerfull bernama CodeIgniter Shield untuk mempermudah proses ini. Dalam tutorial ini, kita akan membahas cara mengintegrasikan CodeIgniter Shield untuk membangun fitur login dan register. Setiap langkah akan dijelaskan secara detail agar mudah diikuti oleh pemula maupun pengembang berpengalaman.

## Apa itu CodeIgniter Shield?{#apa-itu-codeigniter-shield}
CodeIgniter Shield adalah library resmi untuk otentikasi dan otorisasi di CodeIgniter 4. Library ini dirancang agar fleksibel dan mudah dikustomisasi, memungkinkan pengembang untuk mengubah hampir setiap bagiannya. Shield berfokus pada keamanan, menyediakan berbagai fitur otentikasi seperti otentikasi berbasis session, token, dan JWT. Selain itu, Shield juga mendukung verifikasi email, otentikasi dua faktor, dan kontrol akses berbasis grup. Library ini sangat dapat disesuaikan dan mudah diperluas sesuai kebutuhan aplikasi.

## Overview{#overview}
Dalam tutorial CodeIgniter 4 ini, kita akan membahas cara mengimplementasikan fitur login dan register yang aman menggunakan CodeIgniter Shield. CodeIgniter Shield adalah library otentikasi yang powerfull dan fleksibel, dirancang untuk mempermudah pengelolaan otentikasi pengguna dalam aplikasi CodeIgniter. Tutorial ini akan memandu kita dari awal hingga akhir, mulai dari pembuatan project baru hingga pengujian fitur login dan register. Pada akhir tutorial, kita akan memiliki sistem otentikasi yang siap digunakan dalam aplikasi web kita, lengkap dengan keamanan yang terjamin dan antarmuka pengguna yang intuitif.

## Step 1: Buat Project Baru{#step-1-buat-project-baru}
Langkah pertama adalah membuat project CodeIgniter 4 baru. Untuk itu, kita akan menggunakan Composer, yang merupakan tool manajemen dependensi untuk PHP. Buka terminal kita dan jalankan perintah berikut:

```bash
composer create-project codeigniter4/appstarter sample-app
```

Perintah ini akan mengunduh dan menginstal CodeIgniter 4 serta seluruh dependensi yang diperlukan. Setelah selesai, kita akan memiliki framework CodeIgniter 4 yang siap digunakan.

## Step 2: Atur Konfigurasi{#step-2-atur-konfigurasi}
Setelah project berhasil dibuat, kita perlu melakukan beberapa pengaturan konfigurasi dasar. Pindah ke direktori project yang baru saja dibuat:

```bash
cd sample-app/
```

Langkah selanjutnya adalah menyalin file `.env` dari template yang sudah disediakan dan mengonfigurasinya sesuai kebutuhan kita. Jalankan perintah berikut:

```bash
cp env .env
```

Kemudian, buka file `.env` dengan editor teks favorit kita dan lakukan perubahan berikut:

```ini
CI_ENVIRONMENT = development
app.baseURL = 'http://localhost:8080/'
database.default.hostname = localhost
database.default.database = db_belajar_ci4
database.default.username = root
database.default.password = password
database.default.DBDriver = MySQLi
```

Pengaturan ini memastikan bahwa lingkungan pengembangan kita siap untuk digunakan, dengan basis data yang sudah terhubung.

## Step 3: Install dan Setup CodeIgniter Shield{#step-3-install-dan-setup-codeigniter-shield}
Sekarang saatnya menginstal CodeIgniter Shield, tools yang akan kita gunakan untuk menambahkan fitur otentikasi ke aplikasi kita. Untuk itu, jalankan perintah berikut di terminal:

```bash
composer require codeigniter4/shield
```

Setelah proses instalasi selesai, kita perlu melakukan setup awal untuk CodeIgniter Shield dengan menjalankan perintah:

```bash
php spark shield:setup
```

Selama proses setup, kita akan diminta untuk menjalankan migrasi. Pilih `y` untuk melanjutkan:

```bash
Run `spark migrate --all` now? [y, n]: y
```

Perintah ini akan membuat file konfigurasi yang diperlukan, memperbarui beberapa file penting, dan menjalankan migrasi yang diperlukan untuk membuat tabel yang dibutuhkan oleh CodeIgniter Shield.

## Step 4: Uji Coba{#step-4-uji-coba}
Dengan semua pengaturan yang sudah selesai, kita siap untuk menjalankan proyek dan menguji fitur login serta register yang baru saja kita buat.

Untuk run project, buka terminal lalu run command berikut ini:

```bash
php spark serve
```

Server development akan berjalan pada `http://localhost:8080/`. kita dapat mengakses halaman register dengan membuka `http://localhost:8080/register` di browser. Demikian juga, untuk halaman login, kita bisa mengakses `http://localhost:8080/login`.

Apabila kedua halaman ini bisa kita akses, itu artinya kita telah berhasil menambahkan fitur login dan register ke aplikasi CodeIgniter 4 kita, di mana fitur ini merupakan fitur dari library CodeIgniter Shield.


## Kesimpulan{#kesimpulan}
Dengan mengikuti langkah-langkah dalam tutorial ini, kita telah berhasil mengintegrasikan fitur login dan register yang aman ke dalam aplikasi CodeIgniter 4 kita menggunakan CodeIgniter Shield. Langkah-langkah yang dijelaskan dirancang untuk mudah diikuti, sehingga kita dapat segera menerapkan fitur ini dalam project  kita. Pastikan untuk selalu menguji fitur yang kita tambahkan dan sesuaikan konfigurasi sesuai dengan kebutuhan aplikasi kita.

## Referensi{#referensi}

- [Dokumentasi Resmi CodeIgniter 4](https://codeigniter.com/user_guide/)
- [CodeIgniter Shield GitHub Repository](https://github.com/codeigniter4/shield)
- [CodeIgniter 4 User Guide - Shield](https://shield.codeigniter.com/getting_started/install/)

---

Dengan mengikuti panduan ini, kita sekarang memiliki fitur otentikasi yang siap digunakan dalam aplikasi Anda. Selamat mencoba dan jangan ragu untuk bereksperimen dengan fitur-fitur lain yang ditawarkan oleh CodeIgniter Shield!