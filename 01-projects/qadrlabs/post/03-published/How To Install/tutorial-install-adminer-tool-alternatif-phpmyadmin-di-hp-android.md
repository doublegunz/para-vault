---
title: "Tutorial install adminer (tool alternatif phpMyAdmin) di hp android"
slug: "tutorial-install-adminer-tool-alternatif-phpmyadmin-di-hp-android"
category: "How To Install"
date: "2022-02-04"
status: "published"
---

Halo, kembali lagi dengan seri tutorial [Persiapan Belajar Coding di HP](https://qadrlabs.com/series/persiapan-belajar-coding-di-hp) menggunakan termux. Pada edisi tutorial kali ini kita akan belajar bagaimana cara menginstall adminer, salah satu tools alternatif untuk mengelola database. Selain itu kita juga akan membahas contoh penggunaannya untuk mengakses database `db_codelab`, database yang sebelumnya sudah kita buat di tutorial sebelumnya.

## Apa itu Adminer?{#apa-itu-adminer}
Adminer adalah tool untuk mengelola database yang ditulis menggunakan PHP. Tool ini memiliki segudang fitur yang tentunya mendukung DDL (*Data Definition Language*), DML (*Data Manipulation Language*) dan SQL command lainnya, security yang ketat, fitur export, import dan aneka fitur lainnya. Selain untuk mengelola database MySQL atau MariaDB, kita bisa menggunakan Adminer ini untuk database lain, seperti Postgresql, SQLite, MS SQL, Oracle, Elasticsearch, MongoDB dan lain-lain. Dengan kata lain, kita bisa menggunakan adminer ini sebagai alternatif phpmyadmin.

Selain hal yang dijabarkan di atas, ada alasan saya berbagi tools ini ketika share belajar programming menggunakan hp. Alasan itu boleh jadi dapat teman-teman temukan setelah mencoba tutorial ini. Yuk, kita mulai!

## Step 1 - Persiapan{#step-1}
Sama seperti tutorial sebelumnya, tutorial install adminer ini pun perlu menyelesaikan dua tutorial sebelumnya tentang install [apache2, php](https://qadrlabs.com/post/tutorial-instalasi-apache-web-server-dan-php-di-hp-android-menggunakan-termux) dan [mariadb](https://qadrlabs.com/post/tutorial-install-mysql-di-hp-android-menggunakan-termux). Jadi asumsinya di dalam `sdcard` sudah ada direktori `htdocs`, hasil dari proses install tutorial sebelumnya. Selain itu, apache2 dan mariadb juga sudah terinstall dengan baik.

Hal lain yang perlu dipersiapkan adalah tools `wget`. Jika belum tersedia di dalam termux, kita bisa langsung install `wget` menggunakan command.

```bash
pkg install wget
```

## Step 2 - Install Adminer{#step-2}
Pertama buka aplikasi termux terlebih dahulu. Lalu kita masuk ke direktori `htdocs` menggunakan command di bawah ini.
```bash
cd /sdcard/htdocs
```

Selanjutnya kita download `adminer` dari [repositori resmi](https://github.com/vrana/adminer/)-nya menggunakan `wget`. Sebagai catatan, pada saat tutorial ini ditulis, versi yang terbaru adalah `adminer v.8.1`. Jadi kalau ada versi terbaru di kemudian hari, teman-teman boleh install dan sesuaikan versinya. Sekarang kita kembali ke `termux`, lalu kita run command di bawah ini untuk download `adminer`.

```bash
wget https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php -O adminer.php
```

Seperti biasa, kita tunggu sampai  proses download selesai. Eh tampaknya ga jadi nunggu, karena size-nya lumayan kecil, jadi langsung selesai. Kalau kita run command `ls`, kita bisa lihat ada file baru di dalam folder `htdocs`, yaitu file `adminer.php`. 

Ya, dengan satu file php ini kita bisa mengelola database.

## Step 3 - Run Adminer{#step-3}
Untuk menggunakan adminer ini kita tidak perlu melakukan konfigurasi apapun, jadi kita bisa langsung run di browser. Sebelum kita run, kita start dulu apache2 menggunakan command:
```bash
apachectl
```

Selain itu, kita run juga mariadb.
```bash
mysqld_safe -u root &
```

Selanjutnya kita run adminer di browser. Buka browser lalu akses url:
```bash
localhost:8080/adminer.php
```
Kita bisa lihat tampilan awal adminer, terdapat form untuk login ke database. Untuk uji coba, kita gunakan credentials mariadb dari tutorial sebelumnya.
```bash
username: root
password: 1234
database: db_codelab
server: 127.0.0.1
```

![login ke adminer](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-adminer/1-login-adminer.jpg)

Setelah kita masukan credentials yang diperlukan di dalam form login, kita bisa akses database `db_codelab` menggunakan adminer.

![akses db_codelab](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-adminer/2-db-codelab.jpg)

## Penutup{#penutup}
Pada tutorial ini kita belajar bagaimana cara menginstall adminer di hp android menggunakan termux. Adminer ini saya gunakan sebagai alternatif dari phpmyadmin ketika berbagi ilmu programming menggunakan hp android. Selain size adminer ini kecil dan hanya berbentuk satu file php,  alasan lainnya adalah tidak ada konfigurasi apapun ketika menggunakan adminer ini. Sehingga teman-teman yang baru belajar tidak terbebani dengan pengaturan tools yang kompleks.