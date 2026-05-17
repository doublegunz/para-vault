---
title: "Panduan Update Versi PHP di Laragon"
slug: "panduan-update-versi-php-di-laragon"
category: "How To Install"
date: "2024-10-16"
status: "published"
---

Pada postingan sebelumnya kita sudah coba [install laragon](https://qadrlabs.com/post/panduan-lengkap-menggunakan-visual-studio-code-dan-laragon-untuk-web-development#step-2-menginstal-laragon). Dan setelah kita verifikasi, versi php yang terinstall adalah PHP versi 8.1 dan kalau kita coba install laravel, tentu laravel yang terinstall bukan laravel versi 11. Karena salah satu syarat untuk menginstall Laravel versi terbaru (Laravel 11) adalah versi PHP yang digunakan minimal PHP versi 8.2 berdasarkan [dokumentasi laravel](https://laravel.com/docs/11.x/releases#php-8). Supaya kita bisa install laravel 11, kita akan coba update versi PHP di laragon menjadi versi PHP terbaru, yaitu PHP 8.3.

Hal yang mungkin menjadi pertanyaan ketika teman-teman akan melakukan proses download PHP 8.3 adalah **memilih php 8.3 Non Thread Safe atau Thread Safe**? Berdasarkan [Manual PHP Installation on Windows](https://www.php.net/manual/en/install.windows.manual.php), terdapat kriteria berikut:
- Thread-Safe (TS) - untuk web server dengan single process, seperti Apache dengan `mod_php`
- Non-Thread-Safe (NTS) - untuk IIS and web server FastCGI (Nginx, Apache dengan `mod_fastcgi`) dan direkomenedasikan untuk command-line script
- x86 - for 32-bit systems.
- x64 - for 64-bit systems.

Jadi apabila menggunakan web server default laragon, yaitu Apache dengan `mod_php`, kita pilih PHP 8.3 Thread Safe, sedangkan kalau pakai Nginx kita pilih php 8.3 Non Thread Safe. Sebagai contoh di artikel ini kita akan coba PHP 8.3 64-bit Non Thread Safe dengan web server Nginx. 

## Overview{#overview}
Pada panduan ini, kita akan membahas tiga tahapan utama dalam memperbarui PHP di Laragon:
1. **Download dan Setup**: Download dan menyiapkan file PHP versi 8.3 di Laragon.
2. **Konfigurasi Environment**: Mengaktifkan PHP versi baru dan mengatur Nginx sebagai web server.
3. **Verifikasi Instalasi**: Memastikan PHP 8.3 sudah berjalan baik melalui pengecekan di browser dan terminal.

Panduan ini dibuat sederhana dan sistematis agar proses update dapat dilakukan dalam 10–15 menit tanpa hambatan, sehingga Anda bisa langsung melanjutkan pekerjaan dengan environment PHP terbaru.

## Tahap 1: Download dan Setup PHP 8.3 64-bit NTS{#tahap-1-download-dan-setup-php-83-64-bit-nts}
Tahap pertama melibatkan proses download file PHP 8.3 dan mempersiapkannya di direktori Laragon. Berikut langkah-langkahnya:

### Download PHP 8.3{#download-php-83}

1. **Akses Situs PHP Resmi**: Buka halaman [https://windows.php.net/download/](https://windows.php.net/download/).
2. **Download PHP 8.3 64-bit NTS**: Cari link download PHP versi 8.3 64-bit Non-Thread Safe (NTS). Anda bisa mengklik [di sini](https://windows.php.net/downloads/releases/php-8.3.12-nts-Win32-vs16-x64.zip) untuk langsung mengunduh file dengan ekstensi `.zip`.

   ![download php 8.3](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/1%20download%20php%208.2.png)

### Ekstrak File PHP ke Laragon{#ekstrak-file-php-ke-laragon}

Setelah proses download selesai, ikuti langkah-langkah berikut:

1. **Pindahkan File ZIP**: Pindahkan file `php-8.3.13-nts-Win32-vs16-x64.zip` ke folder `C:\laragon\bin\php` di komputer Anda.
   ![pindahkan file zip php ke direktori php di laragon direktori](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/2%20pindahkan%20ke%20direktori%20php%20di%20laragon.png)

2. **Ekstrak File**: Klik kanan file ZIP dan pilih **Extract All**. Kemudian, klik tombol **Extract** untuk memulai proses ekstraksi. Setelah selesai, Anda akan melihat folder baru dengan nama `php-8.3.13-nts-Win32-vs16-x64`.
   ![extract all](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/3%20Extract%20all.png)

   ![folder hasil extract](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/4%20folder%20hasil%20extract.png)

---

## Tahap 2: Konfigurasi Environment{#tahap-2-konfigurasi-environment}

Setelah file PHP 8.3 berhasil diekstrak, langkah selanjutnya adalah mengkonfigurasi Laragon agar menggunakan versi PHP yang baru ini.

### Memilih PHP 8.3 di Laragon{#memilih-php-83-di-laragon}

1. **Buka Laragon**: Jalankan aplikasi Laragon yang sudah Anda install sebelumnya.
2. **Pilih PHP Versi 8.3**: Di Laragon, pilih **Menu** > **PHP** > **Version** > `php-8.3.13-nts-Win32-vs16-x64` untuk mengaktifkan PHP 8.3 sebagai versi PHP utama.
   ![switch php version](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/5%20switch%20php%20version.png)

### Mengatur Nginx Sebagai Web Server{#mengatur-nginx-sebagai-web-server}

Agar lebih optimal, kita akan menggunakan Nginx sebagai web server:

1. **Buka Preferences**: Di Laragon, buka menu **Preferences**.
   ![klik menu preferences](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/6%20klik%20menu%20preferences.png)

2. **Aktifkan Nginx dan Matikan Apache**:
   - Masuk ke tab **Services & Ports**.
   - Hapus centang pada **Apache** dan aktifkan **Nginx** dengan mencentang checkbox Nginx.
   - Atur port Nginx ke **80**.
   
   ![enable nginx](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/7%20enable%20nginx.png)

3. **Jalankan Semua Layanan**: Setelah itu, kembali ke UI utama Laragon dan klik tombol **Start All** untuk menjalankan Nginx dan layanan lainnya.

   ![start all services](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/8%20start%20all%20services.png)

---

## Tahap 3: Verifikasi Instalasi PHP 8.3{#tahap-3-verifikasi-instalasi-php-83}

Setelah konfigurasi selesai, kita perlu memverifikasi apakah PHP 8.3 sudah terpasang dengan benar di sistem Anda.

### Verifikasi PHP di Browser{#verifikasi-php-di-browser}

1. **Buka Localhost**: Di UI Laragon, klik tombol **Web** untuk membuka `localhost` di browser.
   
   ![buka localhost di browser](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/9%20buka%20localhost%20di%20browser.png)

2. **Cek Versi PHP di Halaman**: Setelah membuka halaman `localhost`, Anda akan melihat tampilan yang menunjukkan versi PHP yang sedang digunakan, yaitu `PHP version: 8.3.13`.
   
   ![halaman localhost](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/10%20halaman%20localhost.png)

3. **Verifikasi di `phpinfo()`**: Klik link **info** di halaman `localhost` untuk melihat detail konfigurasi PHP melalui `phpinfo()`.

   ![halaman info](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/12%20halaman%20info%20menampilkan%20php%20versi%208.3.png)

### Verifikasi PHP di CLI{#verifikasi-php-di-cli}

1. **Buka Terminal Laragon**: Kembali ke UI Laragon dan klik **Terminal** untuk membuka Cmder atau terminal.
   
   ![klik menu terminal di laragon ui](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/13%20klik%20menu%20terminal%20di%20ui%20laragon.png)

2. **Cek Versi PHP di Terminal**: Jalankan perintah berikut untuk memeriksa versi PHP yang digunakan di CLI:
   
   ```bash
   php -v
   ```

   Output akan menunjukkan versi PHP terbaru seperti berikut:
   ```bash
   PHP 8.3.13 (cli) (built: Oct 22 2024 21:07:34) (NTS Visual C++ 2019 x64)
   ```
   
   ![cek versi php di cmder](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/14%20cek%20versi%20php%20di%20cmder%20-%202.png)

---

## Kesimpulan{#kesimpulan}

Dengan mengikuti panduan ini, Anda telah berhasil memperbarui versi PHP di Laragon ke versi terbaru, yaitu PHP 8.3, yang mendukung penggunaan Laravel 11 dan framework modern lainnya. Langkah-langkah yang dijelaskan — mulai dari proses download, setup, konfigurasi environment, hingga verifikasi instalasi — dirancang agar dapat diikuti dengan mudah, cepat, dan aman.

Perubahan ke PHP 8.3 tidak hanya memenuhi kebutuhan kompatibilitas dengan Laravel 11 tetapi juga meningkatkan keamanan dan performa aplikasi Anda secara keseluruhan. Selain itu, pilihan web server Nginx dan penggunaan PHP versi Non-Thread Safe telah memberikan fleksibilitas tambahan dalam pengaturan environment pengembangan Anda.

Dengan environment yang kini terbarui, Anda siap untuk menjelajahi berbagai fitur terbaru dan mendukung perkembangan aplikasi yang lebih modern dan efisien. Pastikan untuk terus memeriksa kompatibilitas aplikasi di environment development sebelum diterapkan di production agar aplikasi tetap berjalan optimal.