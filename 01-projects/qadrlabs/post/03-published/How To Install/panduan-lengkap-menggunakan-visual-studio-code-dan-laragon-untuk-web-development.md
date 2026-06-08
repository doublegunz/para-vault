---
title: "Panduan Lengkap Menggunakan Visual Studio Code dan Laragon untuk Web Development"
slug: "panduan-lengkap-menggunakan-visual-studio-code-dan-laragon-untuk-web-development"
category: "How To Install"
date: "2024-09-15"
status: "published"
---

Apakah Anda menghadapi kendala saat menggunakan XAMPP? Seperti mengalami masalah dengan port yang sudah digunakan oleh aplikasi lain, terutama port 80 dan 443, sedangkan mengubah port default boleh jadi rumit bagi pemula. Kendala pada saat ingin menjalankan multiple versi PHP dalam satu instalasi XAMPP dan untuk upgrade atau downgrade PHP memerlukan reinstalasi XAMPP atau konfigurasi manual yang rumit. Kendala pada saat membuat dan mengkonfigurasi virtual host di XAMPP cenderung lebih kompleks dibandingkan beberapa alternatif lainnya. Kesulitan untuk update php atau mysql, karena proses update PHP atau MySQL bisa menjadi rumit dan berisiko merusak instalasi yang ada. Dan aneka kendala lainnya, seperti keamanan, keterbatasan tools, masalah kompatibilitas dan lain-lain. 

Bayangkan berapa banyak waktu yang terbuang karena masalah-masalah ini. Setiap menit yang Anda habiskan untuk mengatasi konflik port atau berjuang dengan konfigurasi adalah menit yang bisa Anda gunakan untuk coding. Berapa banyak proyek yang tertunda karena Anda tidak bisa menjalankan multiple versi PHP? Bagaimana dengan klien yang menunggu karena lingkungan development Anda tidak portabel?

Pengembangan web seharusnya menyenangkan dan produktif, bukan sumber frustrasi dan hambatan.

Kabar baiknya ada tools alternative yang dapat kita gunakan sebagai solusi terhadap kendala yang kita alami pada saat menggunakan Xampp, yaitu Laragon. Laragon menawarkan:
1. Kemudahan penggunaan dengan antarmuka intuitif
2. Fleksibilitas dengan dukungan multiple PHP versions
3. Performa yang superior dengan konsumsi memori yang lebih rendah
4. Portabilitas untuk development di mana saja
5. Terminal terintegrasi untuk workflow yang mulus
6. Dukungan berbagai framework PHP populer
7. Manajemen database yang lebih baik dengan HeidiSQL
8. Isolasi proyek untuk mengurangi konflik
9. Update dan pemeliharaan yang mudah
10. Komunitas yang aktif dan suportif

Solusi tersebut saya gunakan ketika saya diminta untuk mengisi pelatihan web programming pada saat [Setup Laravel Development Environment di OS Windows](https://qadrlabs.com/post/setup-laravel-development-environment-di-os-windows). Selain laragon, saya juga menggunakan [Visual Studio Code](https://qadrlabs.com/post/setup-laravel-development-environment-di-os-windows#tools-3) sebagai code editor di pelatihan web programming tersebut. Dan pada artikel kali ini, kita akan membahas bagaimana cara menginstal kedua tools tersebut, melakukan konfigurasi, serta tips dan trik agar Anda dapat memulai proyek pengembangan web dengan lebih cepat.

## Overview{#overview}
Panduan ini membahas tentang langkah-langkah instalasi visual studio code dan laragon. Setelah proses install selesai, kita coba buat folder di direktori root laragon dan kita coba buka folder tersebut menggunakan visual studio code sebagai simulasi ketika kita mengembangkan project web.  Selain itu kita juga akan bahas bagaimana cara menambahkan path ke environment variable, sehingga kita bisa run command `php`, `node` dan `composer` yang kedepannya akan sering kita gunakan ketika mengembangkan aplikasi web.

### Tujuan Utama:
- Menginstal Visual Studio Code.
- Menginstal dan mengatur Laragon sebagai server lokal.
- Setup environment variable untuk command yang akan digunakan untuk development.

## Table of Content{#table-of-content}
- [Overview](#overview)
- [Step 1: Menginstal Visual Studio Code](#step-1-menginstal-visual-studio-code)
    - [Download Visual Studio Code](#download-visual-studio-code)
    - [Proses Instalasi](#proses-instalasi)
    - [Menjalankan Visual Studio Code](#menjalankan-visual-studio-code)
- [Step 2: Menginstal Laragon](#step-2-menginstal-laragon)
    - [Download Laragon](#download-laragon)
    - [Proses Instalasi Laragon](#proses-instalasi-laragon)
    - [Menjalankan Laragon](#menjalankan-laragon)
- [Step 3: Konfigurasi Awal](#step-3-konfigurasi-awal)
- [Conclusion](#conclusion)

---

## Step 1: Menginstal Visual Studio Code{#step-1-menginstal-visual-studio-code}

### Download Visual Studio Code{#download-visual-studio-code}

Langkah pertama untuk memulai perjalanan Anda sebagai pengembang web adalah dengan menginstal Visual Studio Code. Akses [website resmi Visual Studio Code](https://code.visualstudio.com/) dan klik tombol **Download** untuk platform Windows.

![download visual studio code](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/01-download.png)

Setelah itu, tunggu hingga proses download selesai.

### Proses Instalasi{#proses-instalasi}

Setelah file installer `VSCodeUserSetup-x64-1.82.2` berhasil diunduh, klik dua kali untuk memulai proses instalasi.

1. Pada halaman pertama instalasi, Anda akan diminta untuk menerima **License Agreement**. Pilih opsi **I accept the agreement** dan klik **Next**.
   
    ![mulai install](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/03-%20setup.png)

2. Pilih direktori tempat Anda ingin menginstal VS Code. Default-nya adalah di `C:\Program Files\Microsoft VS Code`. Anda bisa menggunakan pengaturan default atau menyesuaikan direktori sesuai keinginan Anda. Klik **Next**.

    ![setup direktori vscode](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/04-setup%20direktori.png)

3. Pada halaman **Select Additional Tasks**, Anda dapat mencentang opsi **Create a desktop icon** jika Anda menginginkan shortcut di desktop. Lalu klik **Next**.

    ![select additional task](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/06%20-%20select%20additional%20task.png)

4. Pada halaman **Ready to Install**, klik **Install** dan tunggu hingga proses selesai.

    ![ready to install](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/07%20-%20ready%20to%20install.png)

Setelah instalasi selesai, klik **Finish** untuk menutup installer.
 ![finish install visual studio code](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/09%20-%20finish.png)

### Menjalankan Visual Studio Code{#menjalankan-visual-studio-code}

Setelah instalasi selesai, Anda bisa membuka VS Code langsung dari desktop icon atau melalui start menu. 

## Step 2: Menginstal Laragon{#step-2-menginstal-laragon}

### Download Laragon{#download-laragon}

Untuk lingkungan server lokal, Laragon adalah pilihan yang sempurna karena ringan dan mudah digunakan. Anda bisa mengunduhnya dari [website resmi Laragon](https://laragon.org/index.html). Klik menu **Download** dan pilih versi **Laragon - Full** dari daftar pilihan.

![download laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/01-download.png)

**Keterangan:**
- Setelah laragon versi 7 rilis, file yang didownload di halaman download laragon adalah laragon versi 7. Berdasarkan [diskusi di repositori laragon](https://github.com/leokhoa/laragon/discussions/960), laragon versi 7 **tidak lagi gratis** dan menggunakan **Paid Licensing model**. 
- Apabila ingin menggunakan **laragon versi gratis**, teman-teman bisa download langsung di link github, yaitu [https://github.com/leokhoa/laragon/releases/download/6.0.0/laragon-wamp.exe](https://github.com/leokhoa/laragon/releases/download/6.0.0/laragon-wamp.exe)

### Proses Instalasi Laragon{#proses-instalasi-laragon}

Setelah file `laragon-wamp.exe` selesai diunduh, klik dua kali untuk memulai instalasi. Berikut adalah langkah-langkah instalasi Laragon:

1. Pilih bahasa instalasi (misalnya, **English**), lalu klik **Next**.

    ![pilih bahasa](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/02-pilih-bahasa.png)

2. Pilih lokasi instalasi Laragon, default-nya adalah `C:\Laragon`. Klik **Next** untuk melanjutkan.

    ![pilih lokasi install laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/03-pilih-lokasi-install.png)

3. Anda akan melihat opsi konfigurasi seperti autostart pada saat Windows mulai, dan menambahkan Notepad++ serta terminal ke Laragon. Anda bisa memilih opsi sesuai preferensi, lalu klik **Next**.

    ![atur konfigurasi laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/04-atur-konfigurasi-laragon.png)

4. Pada halaman **Ready to Install**, klik **Install** untuk memulai proses instalasi Laragon.

    ![ready install](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/05-ready-install.png)

5. Tunggu hingga proses instalasi selesai. Setelah itu, klik **Finish** untuk menutup installer dan membuka Laragon.

    ![selesai install laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/07-selesai-install.png)

### Menjalankan Laragon{#menjalankan-laragon}

Setelah Laragon terbuka, Anda akan melihat tampilan antarmuka Laragon yang intuitif dan user-friendly.

![tampilan awal laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/08-tampilan-laragon.png)

Untuk memulai layanan seperti Apache dan MySQL, Anda cukup klik **Start All**. Laragon akan menjalankan semua layanan yang diperlukan untuk pengembangan aplikasi web, termasuk Apache, MySQL, dan PHP.

### Membuka folder project di visual studio code
Setelah menginstal VS Code dan Laragon, langkah selanjutnya adalah menghubungkan keduanya agar Anda bisa bekerja dengan smooth dalam satu environment development. Anda bisa membuka direktori project di Visual Studio Code dengan cara sederhana:

1. Buka Laragon, klik **Root**. Ini akan membuka direktori `root` di mana proyek Anda berada, yaitu `C:\laragon\www`. Sebagai contoh di sini kita akan buat direktori project baru, di mana pada real project nanti kita buat langsung menggunakan command `composer` apabila kita mengembangkan project `laravel`, `codeigniter` ataupun framework php lainnya. Di direktori `root`, kita bisa buat direktori project baru dengan nama `sample-app`.
2. Buka Visual Studio Code, klik menu **File > Open Folder** dan pilih folder yang baru saja Anda buat di direktori `root` Laragon, yaitu `C:\laragon\www\sample-app`.

## Step 3: Konfigurasi Awal{#step-3-konfigurasi-awal}
Pada tahapan ini kita akan setup environment variable supaya kita bisa run command seperti `php`, `node`, dan `composer`, di mana command tersebut dapat kita gunakan ketika kita melakukan development project.

Pertama kita buka kembali laragon, lalu kita klik `menu` untuk membuka menu laragon.

![buka menu laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/09%20menu%20laragon.png)

Lalu selanjutnya kita tambahkan `path` laragon dengan klik menu `Tools` > `Path` > `Add Laragon to Path`.
![add laragon to path](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/10%20set%20environment%20variable.png)

Sekarang kita coba run command untuk mengecek apakah laragon berhasil ditambahkan ke dalam path. Untuk mengecek apakah sudah berhasil, kita buka `terminal` atau `command prompt` dengan menekan menu `Terminal` di inteface laragon.
![Buka terminal](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/11%20akses%20terminal%20via%20laragon.png)
Setelah `terminal` terbuka, kita run command berikut ini untuk mengecek versi php yang terinstall di laragon.
```
php -v
```

Selanjutnya kita bisa lihat versi php pada output yang ditampilkan seperti pada gambar berikut ini.
![cek versi php](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/12%20check%20php.png)

Seperti yang kita lihat pada gambar di atas, versi php yang terinstall adalah PHP versi 8.1

Selanjutnya kita coba cek versi node js yang terinstall, kita buka kembali terminal dan run command berikut ini.
```
node -v
```

![cek versi nodejs](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/13%20check%20node%20js.png)

Seperti yang terlihat pada output yang ditampilkan di terminal, versi node js yang terinstall pada laragon adalah versi 18.8.0.

Dan yang terakhir kita cek apakah kita bisa run `composer`. Buka kembali terminal lalu run command berikut ini.
```
composer
```

![tes run command composer](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/14%20check%20composer.png)

Seperti yang terlihat pada gambar di atas, kita bisa lihat output dari command composer.

## Conclusion{#conclusion}
Dalam tutorial ini, kita telah mempelajari langkah-langkah penting untuk mempersiapkan lingkungan pengembangan web yang efisien dan produktif menggunakan Visual Studio Code dan Laragon. Berikut adalah ringkasan dari apa yang telah kita capai:

1. Menginstal Visual Studio Code sebagai editor kode yang powerful dan fleksibel.
2. Menginstal Laragon sebagai alternatif yang lebih mudah dan fleksibel dibandingkan XAMPP untuk server lokal.
3. Mengkonfigurasi Laragon dan menambahkannya ke path sistem, memungkinkan kita untuk menggunakan berbagai command line tool seperti PHP, Node.js, dan Composer langsung dari terminal.
4. Mendemonstrasikan cara membuat folder project baru di direktori root Laragon dan membukanya di Visual Studio Code.
5. Memverifikasi instalasi dan konfigurasi dengan mengecek versi PHP, Node.js, dan ketersediaan Composer melalui command line.

Dengan lingkungan pengembangan yang sudah siap ini, Anda dapat menghindari berbagai kendala yang sering dijumpai saat menggunakan XAMPP, seperti konflik port, kesulitan dalam menjalankan multiple versi PHP, atau kompleksitas dalam mengkonfigurasi virtual host. Laragon menawarkan solusi yang lebih intuitif dan fleksibel, memungkinkan Anda untuk fokus pada pengembangan aplikasi web tanpa terhambat oleh masalah konfigurasi yang rumit.

Kombinasi Visual Studio Code dan Laragon memberikan Anda toolkit yang powerful untuk memulai perjalanan Anda dalam pengembangan web atau meningkatkan efisiensi workflow Anda jika Anda sudah berpengalaman. Dengan lingkungan yang sudah diatur dengan baik ini, Anda siap untuk memulai proyek web Anda dengan lebih cepat dan produktif.