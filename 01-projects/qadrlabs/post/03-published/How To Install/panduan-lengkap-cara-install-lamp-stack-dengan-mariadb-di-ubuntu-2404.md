---
title: "Panduan Lengkap Cara Install LAMP Stack dengan MariaDB di Ubuntu 24.04"
slug: "panduan-lengkap-cara-install-lamp-stack-dengan-mariadb-di-ubuntu-2404"
category: "How To Install"
date: "2024-11-08"
status: "published"
---

Tahapan yang dilakukan setelah project kita selesai proses development dan juga proses testing adalah proses deployment ke server production. Untuk proses deployment tentu kita harus mempersiapkan terlebih dahulu environment untuk menjalankan project tersebut. Dan tentu environment yang dipersiapkan harus sesuai dengan bahasa pemrograman yang digunakan. Sebagai contoh di sini kita sudah selesai mengembangkan aplikasi web yang dibangun menggunakan bahasa pemrograman PHP. Untuk dapat menjalankan aplikasi web di server production, salah satu stack yang dapat kita gunakan adalah **LAMP Stack**. Panduan ini akan menjelaskan bagaimana cara menginstall LAMP Stack di Ubuntu 24.04, di mana database yang akan kita gunakan adalah MariaDB.

LAMP stack adalah kumpulan software open-source yang sering digunakan bersama untuk mendukung server dalam menjalankan website dinamis dan aplikasi web. Dalam panduan ini, kita akan menggunakan:
- **Linux** sebagai sistem operasi,
- **Apache** sebagai web server,
- **MariaDB** sebagai database,
- **PHP** sebagai bahasa pemrograman

LAMP stack ini sebelumnya saya bahas pada tutorial sebelumnya, yaitu [Tutorial Install LAMP di Ubuntu 16.04 Dengan Apache, PHP 7 dan MariaDB](https://qadrlabs.com/post/tutorial-install-lamp-di-ubuntu-16-04-dengan-apache-php-7-dan-mariadb). Perbedaan dengan tutorial tersebut adalah:
1. Os yang digunakan Ubuntu 16.04, sedangkan pada panduan ini kita akan gunakan Ubuntu 24.04.
2. Proses install dan uji coba di laptop, sedangkan pada panduan ini kita uji coba langsung di vps.
3. PHP yang akan kita install di panduan ini adalah PHP versi 8.3.
4. Panduan ini tidak akan membahas tentang ssl.
5. Pada panduan ini, kita bahas cara instal php-fpm.

Panduan ini akan membimbing teman-teman langkah demi langkah untuk menginstal LAMP stack (Linux, Apache, MariaDB, dan PHP) di Ubuntu 24.04, memastikan lingkungan server Anda siap untuk menangani aplikasi modern.

## Overview {#overview}
Pada panduan ini kita akan membahas langkah-langkah dalam menginstall LAMP stack yang mencakup:
1. Instalasi dan konfigurasi Apache.
2. Setup MariaDB sebagai server database.
3. Instalasi PHP 8.3 dan pengaturan optimal menggunakan PHP-FPM.

Pada saat panduan ini disusun, langkah-langkah pada panduan ini saya uji coba pada vps dengan OS **Ubuntu 24.04** dan menggunakan user yang memiliki privileges sebagai **sudoer**. Untuk mengakses vps tersebut, saya akses melalui **SSH**. Jadi untuk mengikuti panduan ini teman-teman perlu server dengan Os Ubuntu 24.04 dan akun user non-root dengan privileges sebagai sudoer.

Setelah semua langkah-langkah dilakukan, teman-teman dapat menggunakan server untuk mendeploy aplikasi yang dibangun menggunakan PHP. Untuk saya pribadi, saya gunakan untuk deploy web yang dibangun menggunakan framework php (laravel).

## Daftar Isi {#table-of-content}
- [Overview](#overview)
- [Step 1: Install dan Konfigurasi Apache](#step-1)
- [Step 2: Membuka Firewall untuk Apache](#step-2)
- [Step 3: Install MariaDB](#step-3)
- [Step 4: Mengamankan MariaDB](#step-4)
- [Step 5: Install PHP dan Ekstensi yang Dibutuhkan](#step-5)
- [Step 6: Menggunakan PHP-FPM untuk Optimasi](#step-6)
- [Step 7: Uji Coba Konfigurasi PHP](#step-7)
- [Kesimpulan](#kesimpulan)

---

## Step 1: Install dan Konfigurasi Apache {#step-1}
Pada tahapan ini kita akan install apache. Sebelum kita mulai proses install apache, kita pastikan semua package di sistem kita telah diperbarui dengan run command berikut ini di terminal.

```bash
sudo apt update
sudo apt upgrade -y
```

Apabila ini pertama kali kita run command `sudo`, akan tampil prompt untuk input password. Kita masukan password, lalu tekan `enter` untuk melanjutkan. Tunggu sampai proses pembaharuan package selesai.

Selanjutnya kita install Apache beserta utilitas pendukungnya:

```bash
sudo apt install -y apache2 apache2-utils
```

Tunggu sampai proses instalasi selesai.

Apabila proses install selesai, kita cek status Apache untuk memastikan apakah apache sudah berjalan:

```bash
sudo systemctl status apache2
```

Output pada terminal:
```
$ sudo systemctl status apache2
● apache2.service - The Apache HTTP Server
     Loaded: loaded (/usr/lib/systemd/system/apache2.service; enabled; preset: >
     Active: active (running) since Fri 2024-11-08 04:00:37 UTC; 18min ago
       Docs: https://httpd.apache.org/docs/2.4/
   Main PID: 2335 (apache2)
      Tasks: 55 (limit: 2320)
     Memory: 6.0M (peak: 6.4M)
        CPU: 155ms
     CGroup: /system.slice/apache2.service
             ├─2335 /usr/sbin/apache2 -k start
             ├─2338 /usr/sbin/apache2 -k start
             └─2339 /usr/sbin/apache2 -k start

```

Pada output yang ditampilkan pada terminal kita bisa lihat apache2 sudah `active`.

Umumnya setelah selesai install Apache langsung aktif. Namun apabila Apache belum aktif, kita jalankan perintah berikut:

```bash
sudo systemctl start apache2
sudo systemctl enable apache2
```

Selanjutnya kita bisa verifikasi versi Apache yang terinstall dengan run command berikut ini:

```bash
apache2 -v
```

Output:
```
Server version: Apache/2.4.58 (Ubuntu)
```

Pada saat panduan ini diujicoba, versi apache yang terinstall adalah `Apache 2.4.58`.

## Step 2: Membuka Firewall untuk Apache {#step-2}
Pada tahapan ini kita akan update pengaturan Firewall supaya apache web server dapat diakses. Untuk update firewall, kita gunakan tools konfigurasi firewall yang secara default sudah terinstall pada ubuntu, yaitu **Uncomplicated Firewall** (UFW). Untuk menampilkan daftar aplikasi yang memiliki profil **firewall** yang sudah terdefinisi di UFW, kita run command berikut ini.

```
sudo ufw app list
```

Output yang ditampilkan:
```
Available applications:
  Apache
  Apache Full
  Apache Secure
  OpenSSH

```
**Penjelasan Output**:
- **Apache**: Profil ini membuka port yang dibutuhkan oleh **Apache web server** (biasanya port **80** untuk HTTP).
- **Apache Full**: Profil ini membuka port **80** (HTTP) dan **443** (HTTPS) untuk Apache.
- **Apache Secure**: Profil ini hanya membuka port **443** (HTTPS).
- **OpenSSH**: Profil ini membuka port **22**, yang digunakan oleh **SSH**.

Seperti yang dijelaskan pada penjelasan output di atas, kita perlu membuka port yang dibutuhkan oleh Apache web server. Untuk membuka port yang digunakan apache, kita run command berikut ini:
```
sudo ufw allow in "Apache"
```

Setelah kita run command di atas, kita periksa perubahan status pada UFW dengan run command berikut ini di terminal.
```
sudo ufw status
```

Output yang ditampilkan:
```
$ sudo ufw status
Status: inactive
```

> **Keterangan:**
> Pada saat panduan ini diuji coba di VPS tampil output di atas, karena saat itu vm baru saja dibuat dan sama sekali belum digunakan. 

Apabila status yang ditampilkan di terminal seperti di atas (`inactive`), ini tandanya UFW belum diaktifkan dan kita harus aktifkan terlebih dahulu UFW. Namun apabila UFW diaktifkan, ada kemungkinan akses SSH kita akan terputus karena port ssh belum kita ijinkan.

Supaya koneksi SSH tidak terputus pada saat kita aktifkan firewall, kita buka port yang digunakan SSH terlebih dahulu dengan run command berikut ini.
```
sudo ufw allow OpenSSH
```

Setelah kita run command di atas, selanjutnya kita aktifkan UFW dengan run command berikut ini.

```
sudo ufw enable
```

Selanjutnya kita cek kembali status UFW dengan run command berikut ini.

```
sudo ufw status
```

Output:
```
$ sudo ufw status
Status: active

To                         Action      From
--                         ------      ----
OpenSSH                    ALLOW       Anywhere                  
Apache                     ALLOW       Anywhere                  
OpenSSH (v6)               ALLOW       Anywhere (v6)             
Apache (v6)                ALLOW       Anywhere (v6) 
```

Bisa kita lihat pada output yang ditampilkan di terminal, sekarang port 80 untuk apache web server sudah dapat diakses dan kita bisa uji coba akses server melalui browser dengan mengetikkan `http://ip-address-server-kamu`. Ketika kita akses public ip address server, kita bisa lihat tampilan awal apache di browser.

![tampilan default apache web server](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/lamp-stack-ubuntu/3-akses-ip-address-setelah-install-apache.png)

## Step 3: Install MariaDB {#step-3}

MariaDB adalah alternatif open-source dari MySQL. Untuk menginstall MariaDB di ubuntu 24.04, kita run command berikut ini:

```bash
sudo apt install -y mariadb-server mariadb-client
```

Kita tunggu sampai proses install selesai. Apabila proses install MariaDB sudah selesai, kita bisa cek status MariaDB dengan run command berikut ini

```bash
sudo systemctl status mariadb
```

Output yang ditampilkan pada terminal:

```
$ sudo systemctl status mariadb
● mariadb.service - MariaDB 10.3.39 database server
     Loaded: loaded (/lib/systemd/system/mariadb.service; enabled; vendor prese>
     Active: active (running) since Fri 2024-11-08 03:08:26 UTC; 44s ago
       Docs: man:mysqld(8)
             https://mariadb.com/kb/en/library/systemd/
   Main PID: 23887 (mysqld)
     Status: "Taking your SQL requests now..."
      Tasks: 31 (limit: 2308)
     Memory: 63.1M
     CGroup: /system.slice/mariadb.service
             └─23887 /usr/sbin/mysqld
```


Umumnya MariaDB sudah aktif setelah kita install dan apabila belum aktif kita bisa run command berikut ini:

```bash
sudo systemctl start mariadb
```

Dan apabila kita ingin mariadb run secara otomatis setiap kali sistem dinyalakan, kita bisa gunakan command berikut ini:
```
sudo systemctl enable mariadb
```

Untuk mengecek versi MariaDB yang terinstall, kita bisa run command berikut ini.

```bash
mariadb --version
```

Output yang ditampilkan:
```
mariadb --version
mariadb  Ver 15.1 Distrib 10.3.39-MariaDB, for debian-linux-gnu (x86_64) using readline 5.2
```

Pada saat panduan ini diujicoba, versi MariaDB yang terinstall adalah `mariadb  Ver 15.1 `.


## Step 4: Mengamankan MariaDB {#step-4}
Mengamankan MariaDB adalah langkah penting untuk mengurangi potensi celah keamanan. Pada saat mariadb kita install, terdapat script yang dapat kita gunakan untuk menghapus pengaturan default mariadb. Untuk run script tersebut, run command berikut ini di terminal.

```bash
sudo mysql_secure_installation
```

Ketika kita run command di atas, akan tampil prompt interaktif untuk mengatur keamanan MariaDB.
```
NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user.  If you've just installed MariaDB, and
you haven't set the root password yet, the password will be blank,
so you should just press enter here.

Enter current password for root (enter for none): 
```
Karena pertama kali, kita tekan `enter` untuk melanjutkan.

Selanjutnya tampil prompt sebagai berikut secara berurutan:
- **Switch to unix_socket authentication**: y
- **Change the root password**: y
- **Remove anonymous users**: y
- **Disallow root login remotely**: y
- **Remove test database**: y
- **Reload privilege tables**: y

Output keseluruhan:
```
NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user.  If you've just installed MariaDB, and
you haven't set the root password yet, the password will be blank,
so you should just press enter here.

Enter current password for root (enter for none): 

Setting the root password or using the unix_socket ensures that nobody
can log into the MariaDB root user without the proper authorisation.

You already have your root account protected, so you can safely answer 'n'.

Switch to unix_socket authentication [Y/n] y

Setting the root password ensures that nobody can log into the MariaDB
root user without the proper authorisation.

Set root password? [Y/n] y

Setting the root password ensures that nobody can log into the MariaDB
root user without the proper authorisation.

Set root password? [Y/n] y
New password: 
Re-enter new password: 
Password updated successfully!
Reloading privilege tables..
 ... Success!

By default, a MariaDB installation has an anonymous user, allowing anyone
to log into MariaDB without having to have a user account created for
them.  This is intended only for testing, and to make the installation
go a bit smoother.  You should remove them before moving into a
production environment.

Remove anonymous users? [Y/n] y

Normally, root should only be allowed to connect from 'localhost'.  This
ensures that someone cannot guess at the root password from the network.

Disallow root login remotely? [Y/n] y
 ... Success!

By default, MariaDB comes with a database named 'test' that anyone can
access.  This is also intended only for testing, and should be removed
before moving into a production environment.

Remove test database and access to it? [Y/n] y

Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.

Reload privilege tables now? [Y/n] y

Reload privilege tables now? [Y/n] y
 ... Success!

Cleaning up...

All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!

```


Selanjutnya kita bisa masuk ke mariaDB dengan run command berikut ini.

```bash
mariadb -u root -p
```

Masukan password yang kita atur pada tahapan sebelumnya dan apabila berhasil kita bisa lihat output yang ditampilkan:
```
mariadb -u root -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 44
Server version: 10.3.39-MariaDB-0ubuntu0.20.04.2 Ubuntu 20.04

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> 
```

Lalu untuk keluar dari mariaDB, kita bisa ketikan `exit;` lalu tekan enter untuk melanjutkan.
```
MariaDB [(none)]> exit;
Bye
```

Pada tahapan ini kita sudah install MariaDB dan sudah kita atur konfigurasi keamanan. Pada tahapan selanjutnya kita install PHP.

## Step 5: Install PHP dan Ekstensi yang Dibutuhkan {#step-5}

Ubuntu 24.04 secara default menggunakan PHP 8.3. Untuk menginstal PHP beserta ekstensi yang diperlukan, gunakan perintah berikut:

```bash
sudo apt install php libapache2-mod-php php-mysql php-common php-cli php-json php-opcache php-readline php-mbstring php-gd php-dom php-zip php-curl
```

Setelah proses install selesai, kita bisa verifikasi versi PHP yang terpasang dengan run command berikut ini:

```bash
php -v
```

Setelah run command di atas, kita lihat versi php yang terinstall.

![cek versi php yang terinstall di ubuntu 24.04](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/lamp-stack-ubuntu/6-cek%20versi%20php.png)

Pada saat panduan ini diujicoba, php yang terinstall adalah PHP versi 8.3.6.

Pada tahapan ini LAMPP stack kita sudah siap untuk kita gunakan. Untuk langkah berikutnya adalah langkah opsional apabila teman-teman ingin menggunakan PHP-FPM.

## Step 6: Install PHP-FPM{#step-6}
Seperti yang disebutkan sebelumnya, tahapan ini adalah opsional untuk teman-teman yang ingin menggunakan PHP-FPM. PHP-FPM dapat meningkatkan performa untuk website dengan traffic tinggi. Untuk menginstall PHP-FPM yang sesuai dengan php terinstall run command berikut ini.

```bash
sudo apt install php8.3-fpm
```

Setelah proses install selesai, kita aktifkan Modul Apache untuk PHP-FPM dengan run command berikut ini:

```bash
sudo a2enmod proxy_fcgi setenvif
```
 
 Setelah itu kita aktifkan Konfigurasi PHP-FPM agar Apache dapat menggunakan PHP-FPM sebagai handler untuk file PHP.

```bash
sudo a2enconf php8.3-fpm
```

Selanjutnya kita restart service apache.

```bash
sudo systemctl restart apache2
```

Pastikan **tidak ada error** selama proses ini. Kita bisa memeriksa status Apache dengan run command berikut ini:

  ```bash
  sudo systemctl status apache2
  ```

Kita juga bisa aktifkan PHP-FPM untuk memulai secara otomatis setiap kali sistem boot.

```bash
sudo systemctl enable php8.3-fpm
```

Selain itu kita juga dapat mengecek status PHP-FPM untuk memastikan bahwa service berjalan menggunakan command berikut ini:

```bash
sudo systemctl status php8.3-fpm
```

## Step 7: Uji Coba Konfigurasi PHP {#step-7}
Pada tahapan ini kita akan menguji coba php yang sebelumnya sudah kita install. Untuk menguji apakah PHP sudah berjalan dengan baik, buat file `info.php`:

```bash
sudo nano /var/www/html/info.php
```

Pada file `info.php`, kita tambahkan kode berikut:

```php
<?php phpinfo(); ?>
```

Save kembali file `info.php`.

Selanjutnya kita buka browser, akses `http://ip-address/info.php`. Kita akan melihat halaman informasi PHP.
![cek versi php via phpinfo di browser](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/lamp-stack-ubuntu/cek-versi-php-via-phpinfo.png)

Setelah selesai, hapus file `info.php` untuk alasan keamanan:

```bash
sudo rm /var/www/html/info.php
```

## Kesimpulan {#kesimpulan}
Selamat! Kita telah berhasil menginstal LAMP stack dengan MariaDB dan PHP 8.3 di VPS dengan OS Ubuntu 24.04. Dengan mengikuti panduan ini, kita kini memiliki server yang siap untuk menjalankan aplikasi web modern dengan Apache sebagai web server dan mariaDB sebagai database system.

Pada saat uji coba, kita bisa akses web server melalui HTTP. Hal-hal yang bisa kita lakukan selanjutnya adalah 
1. Bagaimana caranya supaya server kita bisa diakses melalui HTTPS supaya lebih aman, 
2. Bagaimana caranya supaya kita bisa akses menggunakan domain atau 
3. Bagaimana cara deploy aplikasi yang dibangun menggunakan PHP.
4. Bagaimana cara menggunakan PHP-FPM.