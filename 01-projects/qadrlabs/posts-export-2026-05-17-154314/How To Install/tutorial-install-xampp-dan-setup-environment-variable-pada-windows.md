---
title: "Tutorial Install XAMPP dan Setup Environment Variable pada Windows"
slug: "tutorial-install-xampp-dan-setup-environment-variable-pada-windows"
category: "How To Install"
date: "2024-09-15"
status: "published"
---

Pada tutorial kali ini kita akan belajar bagaimana caranya menginstall Xampp dan setup environment variable pada Windows. Mungkin ada bertanya kenapa saya menuliskan tutorial xampp ini di tahun 2024, padahal di artikel sebelumnya saya [memilih laragon](https://qadrlabs.com/post/setup-laravel-development-environment-di-os-windows#tools-2) untuk environment development dalam pengembangan aplikasi web di lingkungan OS Windows. Alasan menuliskan tutorial ini karena ada permintaan dari teman saya yang baru memulai kembali untuk belajar pemrograman web dan lebih memilih xampp karena lebih familiar. Dan tentu saja untukmu juga, yang baru memulai belajar.

## Introduction{#introduction}
XAMPP merupakan salah satu software open source yang telah mendapatkan popularitas luas di kalangan pengembang web. Fungsi utamanya adalah menyediakan lingkungan pengembangan lokal yang memungkinkan pengguna untuk menjalankan aplikasi berbasis web. Dengan mengintegrasikan server Apache, MySQL, dan PHP dalam satu paket, XAMPP menjadi alat yang sangat berharga bagi para pengembang untuk mengembangkan, menguji, dan melakukan debugging pada aplikasi mereka sebelum diterapkan ke server yang dapat diakses publik.

Saat di awal-awal saya menulis tutorial di [qadrlabs](https://qadrlabs.com), Xampp ini sudah membersamai saya untuk membuat tutorial. Terutama pada saat menulis [Tutorial Series Belajar Codeigniter 3](https://qadrlabs.com/series/belajar-codeigniter-3). Dan tentunya beberapa tutorial lain, sebelum saya memutuskan pindah ke OS Ubuntu. Dan pada saat itu saya belum sempat menulis tutorial tentang panduan instalasi xampp dan setup environment variable. Jadi panduan ini akan memfokuskan pada proses instalasi XAMPP, dengan penekanan khusus pada versi yang mencakup PHP 8.2. Selain itu, kami akan membahas secara rinci langkah-langkah untuk mengkonfigurasi variabel lingkungan (environment variable) di sistem operasi Windows. Konfigurasi ini penting untuk memastikan bahwa PHP dapat diakses dan digunakan melalui Command Prompt (CMD), memberikan fleksibilitas lebih dalam pengembangan dan manajemen proyek web Anda.

## Overview{#overview}
Artikel ini menyajikan panduan lengkap untuk menginstal XAMPP dengan PHP 8.2 dan mengkonfigurasi environment variable di Windows. XAMPP merupakan software open source populer yang mengintegrasikan Apache, MySQL, dan PHP dalam satu paket, menjadikannya pilihan ideal bagi pengembang web untuk membuat lingkungan pengembangan lokal.

Panduan ini dibagi menjadi tiga bagian utama:

1. **Instalasi XAMPP dengan PHP 8.2**
   - Proses download XAMPP dari situs resmi
   - Langkah-langkah instalasi termasuk pemilihan komponen dan lokasi
   - Konfigurasi izin firewall untuk Apache dan MySQL
   - Verifikasi instalasi dengan mengakses localhost dan phpMyAdmin

2. **Setup Environment Variable untuk PHP**
   - Cara mengakses pengaturan environment variable di Windows
   - Langkah-langkah menambahkan path PHP ke variabel Path sistem
   - Petunjuk menyimpan konfigurasi dengan benar

3. **Verifikasi Konfigurasi PHP**
   - Cara memeriksa keberhasilan konfigurasi melalui Command Prompt
   - Memastikan PHP dapat diakses dan dijalankan melalui CMD

Dengan mengikuti panduan ini, pengguna dapat menyiapkan lingkungan pengembangan web lokal yang komprehensif, memungkinkan mereka untuk mengembangkan, menguji, dan melakukan debugging aplikasi web sebelum menerapkannya ke server publik. Tutorial ini cocok untuk pemula yang baru memulai perjalanan pemrograman web maupun pengembang yang ingin mengatur ulang lingkungan pengembangan mereka.

## Table of Content{#table-of-content}
- [Introduction](#introduction)
- [Overview](#overview)
- [Step 1: Install XAMPP](#step-1-install-xampp)
- [Step 2: Setup Environment Variable](#step-2-setup-environment-variable)
- [Step 3: Verifikasi PHP di Command Prompt](#step-3-verifikasi-php-di-command-prompt)
- [Penutup](#penutup)

## Step 1: Install XAMPP{#step-1-install-xampp}

### Download XAMPP
Langkah pertama dalam proses instalasi adalah mengunduh XAMPP. Anda dapat mendownloadnya dari situs web resmi XAMPP. Pastikan Anda memilih versi yang mendukung PHP 8.2 untuk kompatibilitas maksimal dengan aplikasi web modern. Setelah file installer selesai diunduh, buka file tersebut untuk memulai proses instalasi.

![Download XAMPP](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/xampp/01-download-xampp.png)

### Mulai Instalasi
Buka file **xampp-windows-x64-8.2.12-0-VS16-installer** yang telah Anda unduh sebelumnya. Setelah membuka installer, Anda akan melihat tampilan awal yang meminta untuk melanjutkan instalasi. Klik **Next** untuk melanjutkan proses instalasi XAMPP.

![XAMPP Installer](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/xampp/02-xampp-installer.png)

### Pilih Komponen yang Akan Diinstall
Pada bagian ini, Anda akan diminta untuk memilih komponen apa saja yang ingin diinstall. Untuk penggunaan umum, Apache, MySQL, dan PHP sudah cukup. Jadi Anda bisa tetap melanjutkan tanpa mengubah pilihan apapun. Klik **Next**.

![Select Component](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/xampp/03-select-component.png)

### Pilih Lokasi Instalasi
Di bagian ini, Anda bisa memilih di mana XAMPP akan diinstall. Secara default, XAMPP akan diinstall di `C:/xampp`. Jika Anda tidak ingin mengubahnya, cukup klik **Next** untuk melanjutkan.

![Pilih Folder](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/xampp/04-select-folder.png)

### Pilih Bahasa
Selanjutnya, pilih bahasa yang ingin Anda gunakan selama instalasi. Di sini, kita akan menggunakan bahasa **English**. Setelah memilih bahasa, klik **Next**.

![Pilih Bahasa](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/xampp/05-pilih-bahasa.png)

### Siap untuk Install
Pada layar ini, Anda sudah siap untuk memulai instalasi XAMPP. Pastikan semua pengaturan sudah benar, lalu klik **Next** untuk memulai instalasi.

![Ready Install](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/xampp/06-ready-install.png)

### Proses Instalasi
Tunggu sampai proses instalasi selesai. Lamanya waktu instalasi tergantung pada spesifikasi komputer Anda.

![Mulai Proses Install](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/xampp/07-mulai-proses-install.png)

### Izinkan Firewall
Jika muncul popup dari Windows Security yang menyatakan bahwa firewall memblokir Apache, klik **Allow** untuk memberikan izin. Ini penting agar XAMPP bisa berfungsi dengan baik.

![Popup Firewall Apache](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/xampp/08-allow-apache-http-server.png)

### Instalasi Selesai
Setelah instalasi selesai, klik **Finish** untuk membuka XAMPP Control Panel. Di sinilah Anda bisa mengelola berbagai layanan seperti Apache dan MySQL.

![Finish Install XAMPP](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/xampp/09-finish-install.png)

### Menjalankan Apache
Untuk menjalankan server web lokal, buka XAMPP Control Panel dan klik tombol **Start** pada baris **Apache**.

![Start Apache](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/xampp/11-start-apache2.png)

Setelah Apache berjalan, buka browser dan ketikkan `localhost` di address bar. Anda akan melihat halaman default XAMPP, yang menandakan bahwa Apache sudah berjalan dengan baik.

![Tampilan Localhost](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/xampp/12-tampilan-localhost.png)

### Menjalankan MySQL
Setelah Apache berjalan, kembali ke XAMPP Control Panel dan klik **Start** di sebelah **MySQL**. Ini akan memulai server database lokal.

Jika muncul popup firewall yang sama seperti sebelumnya, pastikan Anda mengklik **Allow** untuk mengizinkan MySQL berjalan.

![Popup Firewall MySQL](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/xampp/13-allow-mysqld.png)

Sekarang Anda bisa mengakses **phpMyAdmin** dengan membuka `localhost/phpmyadmin` di browser. Di sini Anda dapat mengelola database MySQL melalui antarmuka web yang user-friendly.

![Tampilan phpMyAdmin](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/xampp/15-phpmyadmin.png)

## Step 2: Setup Environment Variable{#step-2-setup-environment-variable}

Agar kita bisa menjalankan PHP langsung dari Command Prompt (CMD), kita perlu men-setup environment variable pada Windows.

### Langkah 1: Cari Environment Variables
Buka **Start Menu**, ketik **"environment variable"** pada kolom pencarian, lalu klik **Edit the system environment variables**.

![Search Environment Variable](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/setup-enviroment-variable/01-search-environment-variable.png)

### Langkah 2: Buka Pengaturan Environment Variables
Di jendela **System Properties**, klik tombol **Environment Variables** di bagian bawah.

![Klik Environment Variable](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/setup-enviroment-variable/02-klik-environment-variable.png)

### Langkah 3: Edit Path Variable
Di bagian **System Variables**, scroll ke bawah sampai menemukan variable **Path**, kemudian klik **Edit**.

![Klik Path dan Edit](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/setup-enviroment-variable/03-klik-path-and-edit-button.png)

### Langkah 4: Tambahkan Path PHP
Klik **Browse** dan navigasikan ke folder `C:/xampp/php`, lalu klik **OK**.

![Browse Folder PHP](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/setup-enviroment-variable/05-pilih-xampp-php.png)

### Langkah 5: Simpan Path
Sekarang Anda akan melihat path ke PHP di dalam jendela environment variable. Klik **OK** untuk menyimpan perubahan.

![Path PHP Ada](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/setup-enviroment-variable/06-path-php-ada.png)

## Step 3: Verifikasi PHP di Command Prompt{#step-3-verifikasi-php-di-command-prompt}

Setelah environment variable diatur, saatnya melakukan verifikasi apakah PHP sudah terinstall dengan benar.

### Langkah 1: Buka Command Prompt
Buka **CMD** dengan mengetikkan **"cmd"** di Start Menu, lalu tekan **Enter**.

### Langkah 2

: Cek Versi PHP
Ketikkan perintah berikut di CMD:

```bash
php -v
```

Jika setup environment variable berhasil, CMD akan menampilkan versi PHP yang sudah diinstall.

![Cek PHP di CMD](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/setup-enviroment-variable/07-cek-php.png)

Sekarang, PHP siap digunakan melalui Command Prompt. Anda dapat mulai menjalankan aplikasi berbasis PHP atau mengelola server lokal menggunakan XAMPP.

## Penutup{#penutup}
Dalam tutorial ini, kita telah membahas langkah-langkah untuk menginstall **XAMPP** di Windows, menjalankan Apache dan MySQL, serta melakukan setup environment variable untuk PHP. Dengan mengikuti langkah-langkah ini, Anda telah berhasil membuat environment pengembangan lokal yang siap digunakan untuk pengembangan aplikasi berbasis web.