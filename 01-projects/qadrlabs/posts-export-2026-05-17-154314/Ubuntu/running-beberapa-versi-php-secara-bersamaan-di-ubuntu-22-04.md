---
title: "Running Beberapa Versi PHP secara bersamaan di Ubuntu 22.04"
slug: "running-beberapa-versi-php-secara-bersamaan-di-ubuntu-22-04"
category: "Ubuntu"
date: "2024-01-08"
status: "published"
---

Pernahkah Anda menghadapi situasi di mana harus menangani dua project PHP dengan versi yang berbeda, namun keduanya perlu berjalan secara bersamaan? Saya baru saja mengalami hal tersebut - mengelola dua project yang saling terintegrasi, satu menggunakan PHP 7.4 dan lainnya PHP 8.1. Tantangannya? Setup LAMP stack konvensional hanya mendukung satu versi PHP dalam satu waktu.

Setelah melakukan riset, saya menemukan solusi yang elegant menggunakan PHP-FPM (FastCGI Process Manager). PHP-FPM adalah implementasi FastCGI yang dirancang khusus untuk menangani beban kerja tinggi dan menawarkan fitur-fitur canggih, termasuk kemampuan untuk menjalankan multiple PHP versions dalam satu server.

### Keunggulan PHP-FPM:
- Manajemen proses yang fleksibel dengan kemampuan start/stop yang smooth
- Dukungan untuk multiple PHP pools dengan konfigurasi berbeda
- Logging dan monitoring yang komprehensif
- Performa yang optimal untuk high-traffic websites
- Kemampuan menjalankan different PHP versions secara simultan

Berbeda dengan tutorial [multiple PHP versions](https://qadrlabs.com/post/tutorial-setup-dan-menggunakan-multiple-version-php-di-ubuntu) sebelumnya yang hanya bisa menjalankan satu versi PHP dalam satu waktu, kombinasi PHP-FPM dengan Apache dan virtual hosts memungkinkan kita untuk **menjalankan multiple PHP projects dengan versi yang berbeda secara bersamaan**.

*Note: Tutorial ini akan memandu Anda step-by-step dalam mengonfigurasi environment development yang bisa menjalankan PHP 7.4 dan PHP 8.1 secara bersamaan menggunakan PHP-FPM di Ubuntu 22.04.*

*Status Update: November 1, 2024*

### Compatibility Check
Tutorial ini telah diuji dan terverifikasi berjalan dengan baik pada:
- Ubuntu 24.04 LTS (Noble Numbat)
- PHP 7.4.x dan 8.1.x
- Apache 2.4.x

### Perubahan di Ubuntu 24.04
Tidak ada perubahan signifikan dalam prosedur instalasi dan konfigurasi untuk Ubuntu 24.04. Seluruh command dan langkah-langkah yang dijelaskan dalam tutorial masih relevan dan berfungsi sebagaimana mestinya.

### Catatan Penting
- Pastikan selalu menggunakan repository terbaru
- Lakukan update dan upgrade sistem sebelum memulai instalasi
  ```bash
  sudo apt update && sudo apt upgrade -y
  ```
- PHP 7.4 akan mencapai End of Life (EOL) - pertimbangkan untuk upgrade ke versi yang lebih baru untuk production environment
- Beberapa package mungkin memiliki versi baru - ikuti rekomendasi sistem saat instalasi

*Artikel ini akan terus diperbarui sesuai dengan perkembangan teknologi dan feedback dari komunitas. Terakhir diupdate: 1 November 2024.*

## Persyaratan{#persyaratan}

Sebelum memulai tutorial ini, pastikan Anda memenuhi persyaratan berikut:

### Kebutuhan Sistem:
- Komputer/laptop/server dengan Ubuntu 22.04 LTS
- Minimal RAM 4GB (direkomendasikan)
- Ruang disk minimal 20GB
- Koneksi internet yang stabil

### Software Requirements:
1. **Apache Web Server**
   - Terinstall dan running
   - Versi 2.4 atau lebih baru
   - Pastikan service berjalan dengan command:
     ```bash
     sudo systemctl status apache2
     ```

### Konfigurasi Awal:
- User dengan akses sudo
- Terminal/Command line access
- Text editor (nano/vim/VSCode)

### Pengetahuan Dasar:
- Familiar dengan command line Linux
- Pemahaman dasar tentang web server
- Pengalaman basic dengan PHP

*Note: Tutorial ini diasumsikan Anda menggunakan fresh install Ubuntu 22.04. Jika Anda menggunakan versi atau distribusi Linux lain, beberapa command mungkin perlu disesuaikan.*

## Overview{#overview}

Tutorial ini akan membahas implementasi multiple PHP versions dalam satu server menggunakan studi kasus yang konkret. Kita akan membangun environment development yang dapat menjalankan dua aplikasi web dengan versi PHP yang berbeda secara simultan.

### Studi Kasus
Kita akan mengonfigurasi dua aplikasi web berikut:

1. **Aplikasi Pertama (`http://app_one.test`)**
   - Menggunakan PHP versi 7.4
   - Ideal untuk legacy applications
   - Mensimulasikan aplikasi yang membutuhkan kompatibilitas dengan sistem lama
   - Menggunakan virtual host khusus
   - Berjalan melalui PHP-FPM pool terpisah

2. **Aplikasi Kedua (`http://app_two.test`)**
   - Menggunakan PHP versi 8.1
   - Memanfaatkan fitur PHP modern
   - Mensimulasikan aplikasi yang telah diupgrade ke versi terbaru
   - Menggunakan virtual host terpisah
   - Berjalan pada PHP-FPM pool yang berbeda

### Tujuan Implementasi
- Memastikan kedua aplikasi dapat berjalan secara bersamaan
- Mengonfigurasi PHP-FPM untuk menangani multiple versions
- Mengatur virtual hosts untuk routing yang tepat
- Memisahkan process handling untuk setiap versi PHP
- Mengoptimalkan performa masing-masing aplikasi

### Arsitektur Sistem
```
                    Apache Web Server
                           |
            --------------------------------
            |                              |
        PHP-FPM 7.4                    PHP-FPM 8.1
            |                              |
     app_one.test                    app_two.test
```

### Yang Akan Dipelajari
1. Instalasi dan konfigurasi PHP-FPM
2. Setup multiple PHP versions
3. Konfigurasi Apache virtual hosts
4. Manajemen PHP pools
5. Testing dan verifikasi setup

*Note: Pastikan untuk mengikuti setiap langkah secara berurutan untuk menghindari konflik konfigurasi. Tutorial ini dirancang dengan mempertimbangkan best practices dalam pengelolaan multiple PHP versions.*

## Step 1 - Install PHP Versi 7.4 dan 8.1 dengan PHP-FPM {#step-1}
Pada tahapan ini kita akan menginstall PHP versi 7.4, PHP versi 8.1, PHP-FPM dan beberapa extention yang diperlukan. Selain itu kita juga perlu menginstall beberapa software dan repositori yang diperlukan.

Pertama kita install terlebih dahulu `software-properties-common`. Buka terminal, lalu run command berikut ini untuk menginstall `software-properties-common`.

```
sudo apt install software-properties-common -y 
```

Tunggu sampai proses install `software-properties-common` selesai.

Sekarang kita tambahkan repositori `ondrej/php` ke dalam sistem kita untuk menginstall beberapa versi PHP. Buka kembali terminal, lalu kita tambahkan repositori `ondrej/php`.

```
sudo add-apt-repository ppa:ondrej/php
```

Selanjutnya update repositori.
```
sudo apt update -y
```

Tunggu sampai proses update repositori selesai.

Sekarang kita sudah bisa menginstall PHP versi 7.4 dan PHP versi 8.1 dan beberapa extension yang diperlukan.

Buka kembali terminal, lalu kita install PHP versi 7.4 dan extension menggunakan command berikut ini.

```
sudo apt-get install php7.4 php7.4-fpm php7.4-mysql libapache2-mod-php7.4 libapache2-mod-fcgid -y
```

Tunggu sampai proses instalasi selesai.

Berikut ini adalah penjelasan command di atas:

1. `sudo`: Menggunakan hak akses superuser (root) untuk menjalankan perintah. Dibutuhkan hak akses superuser untuk menginstal atau menghapus paket perangkat lunak.

2. `apt-get`: Manajer paket untuk sistem operasi berbasis Debian, termasuk Ubuntu. Digunakan untuk menginstal, menghapus, dan mengelola paket perangkat lunak.

3. `install`: Opsi dari `apt-get` yang digunakan untuk menginstal paket-paket yang disebutkan setelahnya.

4. `php7.4`: Instalasi paket PHP versi 7.4. Ini mencakup inti PHP dan paket-paket standar.

5. `php7.4-fpm`: FastCGI Process Manager untuk PHP versi 7.4. Ini memungkinkan menjalankan PHP dengan menggunakan FastCGI, yang dapat meningkatkan kinerja situs web.

6. `php7.4-mysql`: Integrasi MySQL untuk PHP versi 7.4. Paket ini diperlukan jika Anda berencana untuk menggunakan PHP dengan database MySQL.

7. `libapache2-mod-php7.4`: Modul Apache untuk mengintegrasikan PHP versi 7.4 dengan server web Apache. Diperlukan agar Apache dapat memproses dan menjalankan skrip PHP.

8. `libapache2-mod-fcgid`: Modul Apache untuk mendukung FastCGI. Digunakan ketika PHP dijalankan melalui FastCGI Process Manager.

9. `-y`: Opsi untuk memberikan persetujuan otomatis saat instalasi. Dengan menambahkan opsi ini, perintah tidak akan menunggu konfirmasi dari pengguna dan secara otomatis menginstal paket-paket yang dibutuhkan.

Selanjutnya kita install juga PHP 8.1 dan extension yang diperlukan menggunakan command berikut ini.
```
sudo apt-get install php8.1 php8.1-fpm php8.1-mysql libapache2-mod-php8.1 libapache2-mod-fcgid -y
```

Tunggu sampai proses install PHP 8.1 selesai.

Selanjutnya kita cek start `php7.4-fpm`.
```
sudo systemctl start php7.4-fpm
```

Lalu kita verifikasi status `php7.4-fpm`.
```
sudo systemctl status php7.4-fpm
```
Output yang ditampilkan:
```
● php7.4-fpm.service - The PHP 7.4 FastCGI Process Manager
     Loaded: loaded (/lib/systemd/system/php7.4-fpm.service; enabled; vendor pr>
     Active: active (running) since Mon 2024-01-08 07:54:44 WIB; 1h 33min ago
       Docs: man:php-fpm7.4(8)
    Process: 1495 ExecStartPost=/usr/lib/php/php-fpm-socket-helper install /run>
   Main PID: 1223 (php-fpm7.4)
     Status: "Processes active: 0, idle: 2, Requests: 0, slow: 0, Traffic: 0req>
      Tasks: 3 (limit: 18923)
     Memory: 23.1M
        CPU: 325ms
     CGroup: /system.slice/php7.4-fpm.service
             ├─1223 "php-fpm: master process (/etc/php/7.4/fpm/php-fpm.conf)" ">
             ├─1491 "php-fpm: pool www" "" "" "" "" "" "" "" "" "" "" "" "" "" >
             └─1493 "php-fpm: pool www" "" "" "" "" "" "" "" "" "" "" "" "" "" >


```

Selanjutnya kita start juga `php8.1-fpm`.
```
sudo systemctl start php8.1-fpm
```

Setelah itu kita verifikasi status `php8.1-fpm`.
```
sudo systemctl status php8.1-fpm
```
Output yang ditampilkan di terminal seperti berikut ini.
```
● php8.1-fpm.service - The PHP 8.1 FastCGI Process Manager
     Loaded: loaded (/lib/systemd/system/php8.1-fpm.service; enabled; vendor pr>
     Active: active (running) since Mon 2024-01-08 07:54:44 WIB; 1h 35min ago
       Docs: man:php-fpm8.1(8)
    Process: 1293 ExecStartPost=/usr/lib/php/php-fpm-socket-helper install /run>
   Main PID: 1225 (php-fpm8.1)
     Status: "Processes active: 0, idle: 2, Requests: 0, slow: 0, Traffic: 0req>
      Tasks: 3 (limit: 18923)
     Memory: 19.9M
        CPU: 333ms
     CGroup: /system.slice/php8.1-fpm.service
             ├─1225 "php-fpm: master process (/etc/php/8.1/fpm/php-fpm.conf)" ">
             ├─1291 "php-fpm: pool www" "" "" "" "" "" "" "" "" "" "" "" "" "" >
             └─1292 "php-fpm: pool www" "" "" "" "" "" "" "" "" "" "" "" "" "" >


```

Kedua service `php7.4-fpm` dan `php8.1-fpm` sudah active.

Selanjutnya kita enable beberapa modul supaya service apache2 dapat bekerja dengan beberapa versi PHP.
```
sudo a2enmod actions fcgid alias proxy_fcgi
```

Perintah Linux tersebut digunakan untuk mengaktifkan beberapa modul Apache yang diperlukan untuk mengonfigurasi FastCGI, yang dapat digunakan untuk meningkatkan kinerja dan skalabilitas server web. Berikut adalah penjelasan singkat untuk setiap modul yang diaktifkan oleh perintah tersebut:

1. `sudo`: Menggunakan hak akses superuser (root) untuk menjalankan perintah. Dibutuhkan hak akses superuser untuk melakukan konfigurasi pada level sistem.

2. `a2enmod`: Ini adalah skrip utilitas di lingkungan Debian (termasuk Ubuntu) yang digunakan untuk mengaktifkan modul-modul Apache.

3. `actions`: Modul Actions digunakan untuk mendefinisikan aksi yang dapat dilakukan oleh server Apache berdasarkan peristiwa tertentu, seperti permintaan HTTP tertentu.

4. `fcgid`: Modul FCGID (FastCGI) adalah modul untuk Apache yang mendukung FastCGI, yang memungkinkan server web menjalankan skrip PHP secara efisien dan terisolasi.

5. `alias`: Modul Alias memungkinkan Anda membuat alias atau pemetaan URL yang dapat digunakan untuk menyederhanakan struktur URL pada server web.

6. `proxy_fcgi`: Modul ini memungkinkan Apache untuk bertindak sebagai pengaturan antara server web dan server FastCGI, mengarahkan permintaan PHP ke FastCGI Process Manager.

Dengan mengaktifkan modul-modul ini, Anda dapat mengonfigurasi Apache untuk mengelola permintaan PHP menggunakan FastCGI, yang dapat meningkatkan kinerja dan responsifitas server web Anda. Setelah menjalankan perintah ini, selanjutnya kita perlu me-restart server Apache agar perubahan konfigurasi berlaku dengan perintah berikut ini. 

```
sudo service apache2 restart
```

## Step 2 - Setup Project{#step-2}
Pada tahapan ini kita akan coba setup project sesuai yang sudah kita bahas di section overview di atas. Kita akan buat dua direktori project untuk php versi 7.4 dan php versi 8.1.

Sekarang kita buat direktori untuk kedua project, yaitu `app_one.test` dan `app_two.test`.

```
sudo mkdir /var/www/app_one.test
sudo mkdir /var/www/app_two.test
```

```
sudo chown -R www-data:www-data /var/www/app_one.test
sudo chown -R www-data:www-data /var/www/app_two.test
sudo chmod -R 755 /var/www/app_one.test
sudo chmod -R 755 /var/www/app_two.test
```

Selanjutnya kita buat file `index.php` di kedua project kita. Pada file ini kita gunakan untuk menampilkan informasi versi PHP yang digunakan.

Kita buat file `index.php` untuk project `app_one.test` terlebih dahulu. Buka terminal, lalu run command berikut ini.
```
sudo nano /var/www/app_one.test/index.php 
```

Selanjutnya kita ketik baris kode berikut ini.
```
<?php phpinfo(); ?>
```

Save kembali file `/var/www/app_one.test/index.php`.

Selanjutnya kita buat juga file `index.php` untuk project `app_two.test`.
```
sudo nano /var/www/app_two.test/index.php
```

Selanjutnya kita ketik baris kode berikut ini.
```
<?php phpinfo(); ?>
```

Save kembali file `/var/www/app_two.test/index.php`.

## Step 3 - Mengatur Konfigurasi Apache untuk kedua project{#step-3}
Pada tahapan ini kita akan membuat dua file konfigurasi virtual host. Dengan konfigurasi ini, kedua project kita dapat berjalan secara bersamaan.

Sekarang kita buat file konfigurasi untuk project `app_one.test` dengan menggunakan php versi 7.4.
```
sudo nano /etc/apache2/sites-available/app_one.test.conf
```

Lalu kita tambahkan konfigurasi berikut ini.
```
<VirtualHost *:80>
     ServerAdmin admin@app_one.test
     ServerName app_one.test
     DocumentRoot /var/www/app_one.test
     DirectoryIndex index.php

     <Directory /var/www/app_one.test>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
     </Directory>

    <FilesMatch \.php$>
        # From the Apache version 2.4.10 and above, use the SetHandler to run PHP as a fastCGI process server
         SetHandler "proxy:unix:/run/php/php7.4-fpm.sock|fcgi://localhost"
    </FilesMatch>

     ErrorLog ${APACHE_LOG_DIR}/app_one.test_error.log
     CustomLog ${APACHE_LOG_DIR}/app_one.test_access.log combined
</VirtualHost>
```

Save kembali file `/etc/apache2/sites-available/app_one.test.conf`.

Selanjutnya kita buat file konfigurasi kedua untuk project `app_two.test` dengan php versi 8.1.
```
sudo nano /etc/apache2/sites-available/app_two.test.conf
```

Lalu kita tambahkan konfigurasi berikut ini.
```
<VirtualHost *:80>
     ServerAdmin admin@app_two.test
     ServerName app_two.test
     DocumentRoot /var/www/app_two.test
     DirectoryIndex index.php

     <Directory /var/www/app_two.test>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
     </Directory>

    <FilesMatch \.php$>
        # From the Apache version 2.4.10 and above, use the SetHandler to run PHP as a fastCGI process server
         SetHandler "proxy:unix:/run/php/php8.1-fpm.sock|fcgi://localhost"
    </FilesMatch>

     ErrorLog ${APACHE_LOG_DIR}/app_two.test_error.log
     CustomLog ${APACHE_LOG_DIR}/app_two.test_access.log combined
</VirtualHost>
```

Save kembali file `/etc/apache2/sites-available/app_two.test.conf`.

Sekarang kita cek apakah konfigurasi sudah sesuai.
```
sudo apachectl configtest
```
Output yang ditampilkan
```
Syntax OK
```

Selanjutnya kita enable kedua file konfigurasi virtual host yang sudah kita tambahkan.
```
sudo a2ensite app_one.test
sudo a2ensite app_two.test
```

Selanjutnya kita restart service apache untuk mengimplementasi perubahan konfigurasi.
```
sudo systemctl restart apache2
```

## Step 4 - Menambahkan domain ke /etc/hosts{#step-4}
Selanjutnya kita tambahkan domain kedua project kita ke file `/etc/hosts`. 

Buka file `/etc/hosts` menggunakan command berikut ini. 
```
sudo nano /etc/hosts
```

Lalu tambahkan domain `app_one.test` dan `app_two.test`.
```
127.0.0.1     app_one.test
127.0.0.1     app_two.test

```

Save kembali file `/etc/hosts`.

## Step 5 - Uji Coba{#step-5}
Tahapan selanjutnya adalah menguji coba apakah kedua project kita berjalan dan apakah kedua project kita menggunakan versi PHP yang sesuai.

Sekarang kita buka project kita di browser dengan mengetikan `http://app_one.test` di url. Selanjutnya kita bisa lihat project `app_one.test` menampilkan informasi PHP yang digunakan.
![Project app_one.test](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/dev-environment/ubuntu/run-multi-version-php/ss_app_one-test.png)

Bisa kita lihat pada gambar di atas, versi PHP yang digunakan adalah PHP versi 7.4

Selanjutnya kita buka project kedua di browser dengan mengetikan `http://app_two.test`. Selanjutnya kita bisa lihat tampilah project `app_two.test` dan informasi PHP yang digunakan.
![Project app_two.test](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/dev-environment/ubuntu/run-multi-version-php/ss_app_two-test.png)
Bisa kita lihat pada gambar di atas, versi PHP yang digunakan adalah PHP  versi 8.1.

## Penutup{#penutup}

Dalam tutorial ini, kita telah berhasil mengimplementasikan solusi untuk menjalankan multiple PHP versions menggunakan kombinasi PHP-FPM, Apache, dan virtual hosts. Pendekatan ini menawarkan beberapa keunggulan signifikan:

### Hasil yang Dicapai
1. **Fleksibilitas Development**
   - Menjalankan aplikasi PHP 7.4 dan 8.1 secara bersamaan
   - Isolasi environment yang baik
   - Kemudahan dalam maintenance

2. **Performa Optimal**
   - Process management yang efisien melalui PHP-FPM
   - Resource allocation yang terpisah
   - Minimal overhead dalam pengelolaan multiple versions

3. **Skalabilitas**
   - Mudah menambahkan versi PHP baru
   - Konfigurasi yang modular
   - Adaptable untuk kebutuhan project yang berbeda

### Alternatif Solusi Lain
Selain menggunakan PHP-FPM, terdapat beberapa alternatif yang bisa dipertimbangkan:
- Docker containers
- Virtual machines
- Project-specific LAMP stacks
- Cloud hosting dengan multiple environments

### Best Practices & Rekomendasi
- Regular monitoring terhadap resource usage
- Backup konfigurasi secara berkala
- Update security patches untuk semua versi PHP
- Dokumentasi setup yang lengkap

### Next Steps
1. Implementasi monitoring tools
2. Setup automated backups
3. Konfigurasi load balancing jika diperlukan
4. Optimasi performa untuk production environment

### Mari Berbagi Pengalaman
Kami mengundang Anda untuk berbagi pengalaman dan solusi yang Anda gunakan dalam menangani multiple PHP versions:
- Bagaimana Anda mengelola project dengan requirement berbeda?
- Tools atau teknik apa yang Anda gunakan?
- Challenges apa yang Anda hadapi dan bagaimana mengatasinya?

Silakan bagikan pengalaman Anda di kolom komentar di bawah. Sharing pengalaman Anda akan sangat bermanfaat bagi komunitas developer PHP!

*Remember: Tidak ada solusi yang "one-size-fits-all". Pilih pendekatan yang paling sesuai dengan kebutuhan project dan team Anda.*

---
**Resources:**
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)
- [Apache Virtual Hosts Guide](https://httpd.apache.org/docs/2.4/vhosts/)
- [PHP Version Management Best Practices](https://php.net/supported-versions.php)