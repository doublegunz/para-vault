---
title: "TUTORIAL INSTALL PHPMYADMIN DI HP ANDROID MENGGUNAKAN TERMUX"
slug: "tutorial-install-phpmyadmin-di-hp-android-menggunakan-termux"
category: "How To Install"
date: "2022-01-30"
status: "published"
---

Halo, di postingan ini kita akan melanjutkan kembali seri tutorial [Persiapan Belajar Coding di HP](https://qadrlabs.com/series/persiapan-belajar-coding-di-hp) menggunakan termux. Di tutorial sebelumnya, kita sudah berhasil install apache web server, php dan juga mariadb. Selanjutnya kita akan coba install phpMyadmin melalui termux. 

phpMyAdmin adalah sebuah tool yang digunakan untuk menangani pengelolaan database yang dapat diakses melalui web. Biasanya ketika kita mulai belajar web programming menggunakan php, kita bisa lihat phpmyadmin ini setelah kita install XAMPP. Ya, di dalam XAMPP ini  biasanya sudah ada phpMyadmin, satu bundle dengan apache2, php dan juga mariadb. Jadi untuk melengkapi perlengkapan belajar teman-teman yang belajar ngoding menggunakan hp, kita akan coba install phpMyadmin melalui termux.

## Step 1 - Persiapan{#step-1}
Sebelum mengikuti tutorial install phpMyadmin ini, pastikan kamu sudah mengikuti tutorial sebelumnya yaitu [tutorial install Apache2 dan php](https://qadrlabs.com/post/tutorial-instalasi-apache-web-server-dan-php-di-hp-android-menggunakan-termux) dan [tutorial install mysql atau mariadb](https://qadrlabs.com/post/tutorial-install-mysql-di-hp-android-menggunakan-termux). Selain itu kita perlu install terlebih dahulu dua tools yang akan kita gunakan, yaitu `wget` untuk download phpmyadmin dan `nano` text editor untuk keperluan edit konfigurasi.
 
 Untuk install `wget`, run command ini di termux.
 ```bash
 pkg install wget
 ```
 
 dan untuk install `nano`, run command berikut ini.
 ```bash
 pkg install nano
 ```
 
 Oh iya, kalau di hp kamu sudah ada text editor, kamu boleh skip proses install `nano`.

## Step 2 - Download phpMyAdmin{#step-2}
Selanjutnya kita akan install phpmyadmin di dalam `htdocs`, jadi kita pindah dahulu ke direktori `htdocs`.

```bash
cd /sdcard/htdocs/
```

Langkah selanjutnya adalah download `phpmyadmin` menggunakan `wget`. Kita bisa cek versi stable-nya di [web resmi phpmyadmin](https://www.phpmyadmin.net/files/). Di sini saya coba download versi `5.1.2`. 

Untuk download `phpmyadmin`, run command berikut ini.
```bash
wget https://files.phpmyadmin.net/phpMyAdmin/5.1.2/phpMyAdmin-5.1.2-english.zip
```

Kita tunggu sampai proses download selesai.

Setelah selesai, langkah selanjutnya adalah `unzip` menggunakan command.
```bash
unzip phpMyAdmin-5.1.2-english.zip
```

Supaya mudah digunakan, kita rename terlebih dahulu direktori `phpmyadmin`-nya.
```bash
mv phpMyAdmin-5.1.2-english phpmyadmin
```

## Step 3 - Konfigurasi phpMyadmin{#step-3}
Langkah selanjutnya adalah melakukan konfigurasi supaya phpmyadmin bisa digunakan.

Pertama kita masuk direktori `phpmyadmin`.
```bash
cd phpmyadmin
```

Kalau kita ketik command `ls`, di dalam direktori `phpmyadmin` ada file konfigurasi namanya `config.sample.inc.php`. Selanjutnya buka file `config.sample.inc.php` ini menggunakan text editor. Kamu bebas buka filenya pakai text editor apa saja, di sini saya coba buka menggunakan `nano` yang sebelumnya sudah diinstall di tahapan persiapan.
```bash
nano config.sample.inc.php
```

Selanjutnya kita cari pengaturan `host` nya, lalu isi value-nya menjadi `127.0.0.1':
```bash
$cfg['Servers'][$i]['host'] = '127.0.0.1';
```

Setelah selesai, jangan lupa save kembali filenya. Kalau menggunakan `nano`, gunakan `ctrl`+`o` untuk save, lalu `ctrl`+`x` untuk exit dari text editor.

Dan terakhir kita rename nama file nya:
```bash
mv config.sample.inc.php config.inc.php
```

## Step 4 - Uji coba{#step-4}
Untuk mencoba `phpmyadmin`, kita start dulu `apache2` dan `mysql`. 

Untuk start apache, ketik command ini.
```bash
apachectl
```

Untuk start mysql, ketik command ini.
```bash
mysqld_safe -u root &
```

Selanjutnya buka browser, lalu akses url:
```
localhost:8080/phpmyadmin
```

Untuk login, bisa coba login menggunakan credentials yang sudah dibuat di tutorial sebelumnya:
```
username root
password 1234
```

![uji coba - login](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-phpmyadmin/1-login.jpg)

Setelah berhasil login dan masuk ke dalam `phpmyadmin`, kita bisa lihat ada database `db_codelab` yang sudah kita buat di tutorial sebelumnya.

![ada database dari tutorial sebelumnya](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-phpmyadmin/2-setelah-login.jpg)

![tampiran phpmyadmin](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-phpmyadmin/3-tampilan-phpmyadmin.jpg)

## Penutup{#penutup}
Pada tutorial ini kita sudah coba belajar bagaimana cara menginstall phpMyadmin di hp android menggunakan termux. Di mulai dari instalasi, konfigurasi dan juga uji coba untuk menggunakan phpmyadmin di hp android. Tutorial ini melengkapi tutorial persiapan belajar web programming di hp android menggunakan termux, sebagai gambaran apa saja yang biasanya dipersiapkan ketika belajar web programming menggunakan komputer maupun laptop.