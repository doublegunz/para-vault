---
title: "Panduan Lengkap: Cara Install LEMP Stack (Nginx, MariaDB, PHP 8.3) di Ubuntu 24.04"
slug: "panduan-lengkap-cara-install-lemp-stack-nginx-mariadb-php-83-di-ubuntu-2404"
category: "How To Install"
date: "2024-11-09"
status: "published"
---

Salah satu stack alternatif yang dapat kita gunakan sebagai server untuk menjalankan aplikasi web ataupun website selain menggunakan LAMP Stack adalah LEMP Stack. **LEMP Stack** adalah kombinasi perangkat lunak open-source yang memungkinkan server kita untuk menjalankan aplikasi web dinamis. "LEMP" adalah singkatan dari:
- **Linux**: Sistem operasi berbasis open-source.
- **Nginx** (dibaca "engine x"): Server web yang sangat cepat dan efisien.
- **MariaDB**: Sistem manajemen basis data yang tangguh.
- **PHP**: Bahasa pemrograman yang digunakan untuk menghasilkan konten web dinamis.

## Overview {#overview}
Pada panduan ini kita akan belajar setup LEMP stack di VPS dengan sistem operasi Ubuntu 24.04. Berbeda dengan [Panduan install LAMPP Stack](https://qadrlabs.com/post/panduan-lengkap-cara-install-lamp-stack-dengan-mariadb-di-ubuntu-2404) sebelumnya yang menggunakan apache sebagai web server, LEMP Stack menggunakan Nginx sebagai web server  dan panduan ini akan membahas secara detail bagaimana cara menginstal dan mengkonfigurasi LEMP Stack di Ubuntu 24.04.

### Apa yang akan kamu pelajari
1. Instalasi Nginx
2: Konfigurasi Firewall
3: Instalasi MariaDB
4: Konfigurasi Keamanan MariaDB
5: Instalasi PHP 8.3
6: Setup Server Block di Nginx

Setelah kita selesai melakukan semua langkah-langkah setup LEMP Stack, kita akan uji coba dengan membuat file `php` untuk menampilkan informasi php dan ekstensi yang digunakan.

### Apa yang perlu kamu persiapkan
- VPS dengan OS Ubuntu 24.04 yang sudah terinstall.
- Akses pengguna dengan hak sudo.
- Koneksi internet yang stabil.
- Akses server melalui SSH

## Step 1: Instalasi Nginx {#step-1-instalasi-nginx}
Pada langkah pertama ini kita akan install Nginx sebagai web server. Sebelum kita mulai install Nginx, kita perbaharui terlebih dahulu package sistem dengan run command berikut ini.

```bash
sudo apt update
sudo apt upgrade -y
```

Kita tunggu sampai proses pembaharuan package sistem selesai. 

Apabila sudah selesai, kita install Nginx menggunakan command berikut.
```bash
sudo apt install nginx
```
Ketika tampil prompt, ketik `Y`, lalu tekan `enter` untuk konfirmasi install Nginx. 

Setelah proses instalasi selesai, Nginx web server aktif dan running di server kita. Untuk mengecek status Nginx kita bisa run command berikut ini:

```bash
sudo systemctl status nginx
```
Output yang ditampilkan:
```
$ sudo systemctl status nginx
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: en>
     Active: active (running) since Mon 2024-11-18 06:33:39 UTC; 3min 26s ago
       Docs: man:nginx(8)
    Process: 2882 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_proce>
    Process: 2884 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (c>
   Main PID: 2885 (nginx)
      Tasks: 3 (limit: 2320)
     Memory: 2.4M (peak: 2.6M)
        CPU: 22ms
     CGroup: /system.slice/nginx.service
             ├─2885 "nginx: master process /usr/sbin/nginx -g daemon on; master>
             ├─2886 "nginx: worker process"
             └─2887 "nginx: worker process"

Nov 18 06:33:39 qadrlabs systemd[1]: Starting nginx.service - A high performanc>
Nov 18 06:33:39 qadrlabs systemd[1]: Started nginx.service - A high performance>
lines 1-17/17 (END)

```

Pada output yang ditampilkan kita bisa melihat status **active (running)**.

Selain status web server, kita juga verifikasi instalasi dengan cara mengecek versi Nginx. Untuk cek versi Nginx, kita bisa run command berikut ini:

```bash
nginx -v
```

Output yang ditampilkan kurang lebih seperti berikut ini:
```
nginx version: nginx/1.24.0 (Ubuntu)
```

Seperti yang terlihat pada output, versi nginx yang terinstall adalah 1.24.0 pada saat panduan ini diujicoba di vps.

## Step 2: Konfigurasi Firewall {#step-2-konfigurasi-firewall}
Setelah Nginx sudah terinstall, kita perlu atur konfiigurasi firewall supaya kita dapat akses web server melalui port HTTP. Untuk mengatur konfigurasi firewall, kita akan gunakan UFW (Uncomplicated Firewall). 

Sekarang kita coba lihat terlebih dahulu dafar aplikasi yang terdaftar di UFW. Kitia buka kembali terminal, lalu kita run command berikut ini untuk menampilkan daftar aplikasi yang terdaftar di UFW.
```
sudo ufw app list
```
Output:
```
Available applications:
  Nginx Full
  Nginx HTTP
  Nginx HTTPS
  OpenSSH
```

**Penjelasan dari Output:**
- **Nginx Full**:
  - Mengizinkan akses ke **port 80 (HTTP)** dan **port 443 (HTTPS)**.
- **Nginx HTTP**:
  - Mengizinkan akses hanya ke **port 80 (HTTP)**.
- **Nginx HTTPS**:
  - Mengizinkan akses hanya ke **port 443 (HTTPS)**.
- **OpenSSH**:
  - Mengizinkan akses ke **port 22 (SSH)** untuk koneksi **Secure Shell (SSH)**.

Untuk mengizinkan akses ke port HTTP, kita run command berikut ini:
```
sudo ufw allow 'Nginx HTTP'
```

Selanjutnya kita cek status UFW untuk verifikasi perubahan.
```
sudo ufw status
```
Output:

```
Status: active

To                         Action      From
--                         ------      ----
Nginx HTTP                 ALLOW       Anywhere                  
Nginx HTTP (v6)            ALLOW       Anywhere (v6) 
```

Selanjutnya kita bisa coba akses server dengan url `http://ip-public-server-kamu` di browser. Ketika kita akses, kita bisa lihat tampilan default web server Nginx.


**Catatan:**
Apabila ketika kita running command berikut ini:

```bash
sudo ufw status
```

menampilkan status firewall UFW (Uncomplicated Firewall). Output:

```
Status: inactive
```

berarti **firewall UFW belum aktif**, sehingga saat ini **tidak ada aturan firewall yang diterapkan**.

---

### Untuk mengaktifkan UFW:

Jalankan perintah berikut:

```bash
sudo ufw enable
```

Kemudian periksa ulang statusnya:

```bash
sudo ufw status verbose
```

---

### (Opsional) Sebelum mengaktifkan:

Sebaiknya pastikan SSH tetap diizinkan (jika kamu mengakses server lewat SSH):

```bash
sudo ufw allow ssh
```

atau jika SSH memakai port custom, misalnya port 2222:

```bash
sudo ufw allow 2222/tcp
```

Setelah semua aturan yang dibutuhkan ditambahkan, baru jalankan `sudo ufw enable`.




## Step 3: Instalasi MariaDB {#step-3-instalasi-mariadb}
Sekarang server kita sudah tersedia Nginx web server, untuk menyimpan data tentu kita perlu database. Pada tahapan ini kita akan install MariaDB server dan juga client untuk berinteraksi dengan server melalui terminal. Untuk install MariaDB server dan client, kita run command berikut ini.

```bash
sudo apt install mariadb-server mariadb-client
```
Jika tampil prompt, ketik `y` lalu tekan `enter` untuk melanjutkan proses install MariaDB server dan client.

Setelah proses install selesai, MariaDB aktif dan running secara otomatis. Kita bisa verifikasi dengan run command berikut ini:
```
sudo systemctl status mariadb
```

Output yang ditampilkan:
```
$ sudo systemctl status mariadb
● mariadb.service - MariaDB 10.11.8 database server
     Loaded: loaded (/usr/lib/systemd/system/mariadb.service; enabled; preset: >
     Active: active (running) since Mon 2024-11-18 06:59:55 UTC; 44s ago
       Docs: man:mariadbd(8)
             https://mariadb.com/kb/en/library/systemd/
   Main PID: 3906 (mariadbd)
     Status: "Taking your SQL requests now..."
      Tasks: 12 (limit: 15313)
     Memory: 78.8M (peak: 81.9M)
        CPU: 730ms
     CGroup: /system.slice/mariadb.service
             └─3906 /usr/sbin/mariadbd

```
Pada output yang ditampilkan di terminal, kita bisa lihat status MariaDB adalah ` active (running)`.

## Step 4: Konfigurasi Keamanan MariaDB {#step-4-konfigurasi-keamanan-mariadb}
Setelah proses install selesai, dari berbagai sumber, sangat direkomendasikan untuk run script untuk mengatur konfigurasi keamanan MariaDB. Untuk run script keamanan MariaDB dengan command berikut ini:

```bash
sudo mysql_secure_installation
```

Output:
```
NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user. If you've just installed MariaDB, and
haven't set the root password yet, you should just press enter here.

Enter current password for root (enter for none): 

```
Tekan `enter` untuk melanjutkan.
Selanjutnya tampil prompt berikut ini:
```
OK, successfully used password, moving on...

Setting the root password or using the unix_socket ensures that nobody
can log into the MariaDB root user without the proper authorisation.

You already have your root account protected, so you can safely answer 'n'.

Switch to unix_socket authentication [Y/n] 

```
Ketik `Y`, lalu tekan `enter` untuk melanjutkan.
```
Enabled successfully!
Reloading privilege tables..
 ... Success!


You already have your root account protected, so you can safely answer 'n'.

Change the root password? [Y/n] 

```
Pada output yang ditampilkan di atas, kita ketik `Y` untuk mengubah password root. Selanjutnya kita masukan password dan konfirmasi password untuk root.
```
New password: 
Re-enter new password: 
Password updated successfully!
Reloading privilege tables..
 ... Success!

```

Setelah setup password root berhasil, selanjutnya terdapat prompt untuk menghapus anonymous user.
```
By default, a MariaDB installation has an anonymous user, allowing anyone
to log into MariaDB without having to have a user account created for
them.  This is intended only for testing, and to make the installation
go a bit smoother.  You should remove them before moving into a
production environment.

Remove anonymous users? [Y/n] 

```
Ketik `y`, lalu tekan `enter` untuk menghapus anonymous user.

```
Remove anonymous users? [Y/n] y
 ... Success!

Normally, root should only be allowed to connect from 'localhost'.  This
ensures that someone cannot guess at the root password from the network.

Disallow root login remotely? [Y/n] 

```
Pada prompt selanjutnya, kita set disallow login root secara remote dengan mengetik `y`, lalu tekan `enter`.
```
Disallow root login remotely? [Y/n] y
 ... Success!

By default, MariaDB comes with a database named 'test' that anyone can
access.  This is also intended only for testing, and should be removed
before moving into a production environment.

Remove test database and access to it? [Y/n] 

```
Lalu pada prompt selanjutnya, kita pilih `y`, tekan `enter` untuk menghapus database `test`.

```
Remove test database and access to it? [Y/n] y
 - Dropping test database...
 ... Success!
 - Removing privileges on test database...
 ... Success!

Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.

Reload privilege tables now? [Y/n] 

```
Selanjutnya kita reload privilege table dengan menekan `y`, lalu tekan `enter`.

```
Reload privilege tables now? [Y/n] y
 ... Success!

Cleaning up...

All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!

```

Setelah kita pilih reload, tahapan konfigurasi database sudah selesai dan kita bisa uji coba login ke console mariadb.
```
sudo mariadb
```
Output:
```
$ sudo mariadb
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 41
Server version: 10.11.8-MariaDB-0ubuntu0.24.04.1 Ubuntu 24.04

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> 

```
Lalu kita keluar dari console dengan run command berikut ini.
```
exit
```

Selain menggunakan sudo, kita bisa login ke console mariadb dengan command berikut ini:
```
mariadb -u root -p
```
Lalu ketik password root yang sudah kita atur pada tahapan sebelumnya.
Output:
```
$ mariadb -u root -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 42
Server version: 10.11.8-MariaDB-0ubuntu0.24.04.1 Ubuntu 24.04

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> 
```

## Step 5: Instalasi PHP 8.3 {#step-5-instalasi-php-8-3}
kita sudah install **Nginx** untuk menampilkan konten website dan **MySQL** untuk menyimpan serta mengelola data. Langkah selanjutnya adalah install **PHP** agar bisa menjalankan kode dan membuat konten website yang dinamis.

Berbeda dengan **Apache** yang langsung menjalankan PHP di setiap permintaan, **Nginx membutuhkan program eksternal** untuk memproses PHP. Program ini akan menjadi penghubung antara Nginx dan PHP agar bisa bekerja sama. Meskipun butuh konfigurasi tambahan, cara ini umumnya memberikan **kinerja yang lebih baik** untuk website berbasis PHP.

Untuk itu, kita perlu menginstal:

* `php-fpm`: singkatan dari **PHP FastCGI Process Manager**, yaitu program yang memproses permintaan PHP untuk Nginx.
* `php-mysql`: modul PHP yang memungkinkan PHP terhubung dan berkomunikasi dengan database MySQL.

Saat menginstal kedua paket ini, **paket inti PHP lainnya akan ikut terpasang secara otomatis** sebagai dependensi.

Untuk installnya, jalankan perintah berikut di terminal:

```bash
sudo apt install php-fpm php-mysql
```


Setelah proses install selesai, kita bisa cek versi php terinstall.
```
php -v
```
Output:
```
$ php -v
PHP 8.3.6 (cli) (built: Mar 19 2025 10:08:38) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.3.6, Copyright (c) Zend Technologies
    with Zend OPcache v8.3.6, Copyright (c), by Zend Technologies

```
Pada saat panduan ini diuji coba di ubuntu 24.04, versi php yang terinstall adalah php versi 8.3.6.

Selain php, kita cek juga status php-fpm yang terinstall dengan run command berikut ini

```bash
sudo systemctl status php8.3-fpm
```

Output:
```
$ sudo systemctl status php8.3-fpm
● php8.3-fpm.service - The PHP 8.3 FastCGI Process Manager
     Loaded: loaded (/usr/lib/systemd/system/php8.3-fpm.service; enabled; prese>
     Active: active (running) since Tue 2025-06-03 11:39:06 UTC; 4min 41s ago
       Docs: man:php-fpm8.3(8)
    Process: 10337 ExecStartPost=/usr/lib/php/php-fpm-socket-helper install /ru>
   Main PID: 10334 (php-fpm8.3)
     Status: "Processes active: 0, idle: 2, Requests: 0, slow: 0, Traffic: 0req>
      Tasks: 3 (limit: 2317)
     Memory: 7.7M (peak: 8.6M)
        CPU: 84ms
     CGroup: /system.slice/php8.3-fpm.service
             ├─10334 "php-fpm: master process (/etc/php/8.3/fpm/php-fpm.conf)"
             ├─10335 "php-fpm: pool www"
             └─10336 "php-fpm: pool www"

Jun 03 11:39:06 qadrlabs systemd[1]: Starting php8.3-fpm.service - The PHP 8.3 >
Jun 03 11:39:06 qadrlabs systemd[1]: Started php8.3-fpm.service - The PHP 8.3 F>
```

Bisa kita lihat pada output yang ditampilkan di terminal, status php-fpm adalah `active (running)`.

## Step 6: Setup Server Block di Nginx {#step-6-setup-server-block-di-nginx}
Ketika kita menggunakan Nginx web server, kita bisa atur konfigurasi server block. Server block ini adalah istilah yang sama dengan **virtual host** ketika kita menggunakan apache web server.

Pada tahapan ini kita coba hapus terlebih dahulu konfigurasi default Nginx:

```bash
sudo rm /etc/nginx/sites-enabled/default
```

Lalu kita buat file server block baru dengan run command berikut ini:

```bash
sudo nano /etc/nginx/conf.d/default.conf
```

Tambahkan konfigurasi berikut:

```nginx
server {
    listen 80;
    root /var/www/html;
    index index.php index.html index.htm;
    server_name localhost;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }
}
```
Setelah selesai kita save terlebih dahulu, lalu kita keluar dari nano text editor.

**Penjelasan Konfigurasi**
- **`root /var/www/html;`**: Menunjukkan direktori root dari aplikasi web Anda.
- **`index index.php index.html;`**: Menentukan file default yang akan di-load.
- **`try_files $uri $uri/ =404;`**: Mencoba menemukan file yang diminta, jika tidak ditemukan akan memberikan **404**.
- **`fastcgi_pass unix:/run/php/php8.3-fpm.sock;`**: Menggunakan **PHP 8.3-FPM** untuk memproses file PHP.

Setelah menambahkan konfigurasi, **periksa apakah konfigurasi Nginx valid**:

```bash
sudo nginx -t
sudo systemctl reload nginx
```
Output:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

```

Jika tidak ada error, kita **muat ulang Nginx** dengan run command berikut ini:

```bash
sudo systemctl reload nginx
```


## Step 7: Uji Coba dan Verifikasi {#step-7-uji-coba-dan-verifikasi}
Pada tahapan ini kita uji coba dan verifikasi. Untuk menguji coba, kita buat file `info.php` untuk memverifikasi instalasi PHP:

```bash
sudo nano /var/www/html/info.php
```

Tambahkan kode berikut:

```php
<?php phpinfo(); ?>
```

Akses file tersebut di browser:

```
http://server-ip-address/info.php
```

Kita bisa lihat pada browser ditampilkan versi php dan juga ekstensi yang tersedia pada server yang telah kita persiapkan.

![verifikasi versi php dengan run phpinfo](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/lemp-stack-ubuntu-24.04/1-phpinfo.png)

Setelah verifikasi, kita hapus file tersebut untuk alasan keamanan:

```bash
sudo rm /var/www/html/info.php
```


## Kesimpulan {#kesimpulan}
Selamat! Kita telah berhasil menginstal LEMP Stack (Nginx, MariaDB, PHP 8.3) di Ubuntu 24.04. Dengan mengikuti langkah-langkah ini, kita sekarang memiliki server yang dioptimalkan untuk performa dan keamanan. Pastikan untuk selalu memperbarui paket-paket server kita agar tetap aman dan berjalan optimal.

Dengan setup ini, kita siap untuk meng-host aplikasi web berbasis PHP. Jika teman-teman mengalami kendala, jangan ragu untuk memeriksa dokumentasi resmi atau meninggalkan pertanyaan di komunitas Linux.

---

**FAQ**
1. **Apa itu LEMP Stack?**
   LEMP adalah singkatan dari Linux, Nginx, MariaDB, dan PHP. Ini adalah kombinasi perangkat lunak yang digunakan untuk menjalankan server web.

2. **Apa perbedaan antara LEMP dan LAMP?**
   LEMP menggunakan Nginx sebagai server web, sedangkan LAMP menggunakan Apache.

3. **Apakah PHP-FPM diperlukan?**
   PHP-FPM meningkatkan kinerja server, terutama untuk situs web dengan lalu lintas tinggi.

Semoga panduan ini membantu Anda mengoptimalkan server Ubuntu Anda dengan LEMP Stack!