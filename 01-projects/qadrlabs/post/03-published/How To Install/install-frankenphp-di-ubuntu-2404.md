---
title: "Install FrankenPHP di Ubuntu 24.04"
slug: "install-frankenphp-di-ubuntu-2404"
category: "How To Install"
date: "2024-12-25"
status: "published"
---

## Pendahuluan {#pendahuluan}

Dalam dunia pengembangan aplikasi web berbasis PHP, kebutuhan akan performa tinggi, keamanan, dan efisiensi telah menjadi prioritas utama. Dengan teknologi yang terus berkembang, pendekatan tradisional seperti menggunakan Apache atau Nginx dengan PHP-FPM mulai digantikan oleh solusi modern yang lebih terintegrasi, seperti **FrankenPHP**.

FrankenPHP hadir sebagai server aplikasi yang tidak hanya menyederhanakan pengelolaan server tetapi juga meningkatkan kinerja aplikasi PHP dengan memanfaatkan arsitektur modern. Artikel ini bertujuan untuk membantu Anda memahami apa itu FrankenPHP, mengapa ini penting, dan bagaimana cara setup FrankenPHP di Ubuntu 24.04.

## Apa Itu FrankenPHP? {#apa-itu-frankenphp}

**FrankenPHP** adalah server aplikasi modern untuk PHP yang dibangun di atas server web **Caddy**. Server ini dirancang untuk menggabungkan fungsi server web dan eksekusi PHP dalam satu layanan terpadu, memberikan solusi yang lebih sederhana dibandingkan pendekatan tradisional yang menggunakan komponen terpisah seperti Apache atau Nginx dan PHP-FPM.

### Fitur Utama FrankenPHP {#fitur-utama-frankenphp}

1. **Mode Pekerja (Worker Mode):** 
   Aplikasi PHP diinisialisasi satu kali dan tetap berada dalam memori, memungkinkan permintaan berikutnya diproses lebih cepat.

2. **Dukungan Real-Time:** 
   Dengan hub Mercure bawaan, FrankenPHP memudahkan pengiriman data real-time dari server ke klien.

3. **Otomatisasi HTTPS:** 
   Mendukung otomatisasi pembuatan dan pembaruan sertifikat HTTPS untuk koneksi yang aman.

4. **Dukungan HTTP/2 dan HTTP/3:** 
   Memberikan koneksi yang lebih cepat dan efisien dengan protokol web terbaru.

5. **Kompresi Modern:** 
   Mendukung Brotli, Zstandard, dan Gzip untuk mempercepat pengiriman konten.


## Mengapa Memilih FrankenPHP? {#mengapa-memilih-frankenphp}

FrankenPHP membawa berbagai keunggulan yang membuatnya menjadi pilihan ideal untuk menjalankan aplikasi PHP modern. Berikut adalah beberapa alasan utama:

1. **Kinerja Tinggi:** 
   Dengan mode pekerja, FrankenPHP mampu menangani banyak permintaan secara efisien tanpa perlu inisialisasi ulang aplikasi.

2. **Sederhana:** 
   Mengintegrasikan server web dan PHP dalam satu layanan, mengurangi kompleksitas pengaturan.

3. **Kompatibilitas Luas:** 
   Mendukung framework populer seperti Laravel dan Symfony tanpa modifikasi besar.

4. **Keamanan yang Kuat:** 
   Dengan otomatisasi HTTPS dan dukungan protokol modern, FrankenPHP memastikan koneksi yang aman antara server dan klien.

## Overview {#overview}
Artikel ini adalah panduan langkah demi langkah untuk mengatur dan menjalankan FrankenPHP di Ubuntu 24.04. Anda akan belajar:
1. **Apa itu FrankenPHP dan bagaimana ia meningkatkan kinerja aplikasi PHP.**
2. **Fitur utama yang membedakan FrankenPHP dari pendekatan tradisional.**
3. **Langkah-langkah instalasi dan uji coba FrankenPHP.**

Setelah menyelesaikan tutorial ini, Anda akan dapat menginstal FrankenPHP di sistem Anda, menggunakannya untuk menjalankan aplikasi PHP, dan memahami bagaimana teknologi ini dapat meningkatkan efisiensi pengembangan Anda.

---

## Table of Contents {#table-of-contents}
- [Pendahuluan](#pendahuluan)
- [Apa Itu FrankenPHP?](#apa-itu-frankenphp)
- [Mengapa Memilih FrankenPHP?](#mengapa-memilih-frankenphp)
- [Overview](#overview)
- [Langkah-Langkah Setup](#langkah-langkah-setup)
  - [Step 1: Setup FrankenPHP](#step-1-setup-frankenphp)
  - [Step 2: Uji Coba](#step-2-uji-coba)
- [Penutup](#penutup)

---

## Langkah-Langkah Setup {#langkah-langkah-setup}

### Step 1: Setup FrankenPHP {#step-1-setup-frankenphp}

Untuk memulai setup FrankenPHP di Ubuntu 24.04, ikuti langkah-langkah berikut:

#### 1. Unduh dan Instal FrankenPHP
Gunakan perintah berikut untuk mengunduh script instalasi FrankenPHP:

```bash
curl https://frankenphp.dev/install.sh | sh
```

#### Output
Setelah menjalankan perintah di atas, Anda akan melihat proses unduhan seperti berikut:

```
📦 Downloading FrankenPHP for Linux (x86_64):
######################################################################## 100.0%

🥳 FrankenPHP downloaded successfully to /home/user/frankenphp
🔧 Move the binary to /usr/local/bin/ or another directory in your PATH to use it globally:
   sudo mv /home/user/frankenphp /usr/local/bin/
```

#### 2. Pindahkan Binary
Pindahkan file binary ke direktori global PATH agar FrankenPHP dapat digunakan di mana saja:

```bash
sudo mv frankenphp /usr/local/bin/
```

#### 3. Verifikasi Instalasi
Periksa apakah FrankenPHP berhasil diinstal dengan menjalankan perintah berikut:

```bash
frankenphp --version
```

Jika instalasi berhasil, Anda akan melihat output versi seperti ini:

```
FrankenPHP v1.3.6 PHP 8.4.2 Caddy v2.8.4 h1:q3pe0wpBj1OcHFZ3n/1nl4V4bxBrYoSoab7rL9BMYNk=
```


### Step 2: Uji Coba {#step-2-uji-coba}

Mari kita uji coba instalasi FrankenPHP dengan membuat aplikasi PHP sederhana:

#### 1. Buat Direktori Aplikasi
Buat direktori baru untuk proyek Anda:

```bash
mkdir sample-app
cd sample-app
```

#### 2. Tambahkan File PHP
Buat file `index.php` dengan isi berikut:

```bash
echo '<?php echo "Hello, FrankenPHP!"; ?>' > index.php
```

#### 3. Jalankan Server
Jalankan server menggunakan FrankenPHP:

```bash
sudo frankenphp php-server
```

#### 4. Akses di Browser
Buka browser Anda dan akses `http://localhost`. Anda akan melihat pesan:

```
Hello, FrankenPHP!
```

![tes run file php](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/frankenphp-ubuntu-24-04/tes-run-file-php.png)

## Penutup {#penutup}
Dalam tutorial ini, kita telah membahas apa itu FrankenPHP, fitur utamanya, dan bagaimana langkah-langkah untuk menginstalnya di Ubuntu 24.04. Dengan FrankenPHP, Anda tidak hanya mendapatkan kinerja yang lebih baik tetapi juga kemudahan pengelolaan server yang modern dan sederhana.

**Key Takeaways:**
- FrankenPHP adalah solusi ideal untuk meningkatkan kinerja aplikasi PHP.
- Dengan integrasi fitur seperti mode pekerja dan real-time support, FrankenPHP menghilangkan batasan pendekatan tradisional.
- Instalasi yang mudah dan kompatibilitas luas membuat FrankenPHP menjadi pilihan yang tepat untuk pengembang modern.

Selamat mencoba dan jangan ragu untuk mengeksplorasi lebih jauh potensi FrankenPHP dalam proyek Anda!