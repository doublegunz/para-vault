---
title: "Tutorial Install LAMP di Ubuntu 16.04 Dengan Apache, PHP 7 dan MariaDB"
slug: "tutorial-install-lamp-di-ubuntu-16-04-dengan-apache-php-7-dan-mariadb"
category: "How To Install"
date: "2016-07-27"
status: "published"
---

Entah kenapa belakangan ini saya tertarik sama yang namanya Ubuntu. Dan karena rasa penasaran saya begitu kuat, akhirnya saya coba install OS Ubuntu 16.04, dual boot sama OS Windows. Dan setelah mencoba, ternyata nyamaaaan banget pakai Ubuntu. Terasa ringan. (thanks untuk grup FB AYO BELAJAR LINUX untuk informasinya).

Akhirnya saya pun memutuskan untuk migrasi ke Ubuntu dan mulai mengumpulkan informasi apa saja sih yang nantinya bakalan saya perlukan, terutama untuk coding. Apakah saya perlu install XAMPP untuk keperluan coding? lebih tepatnya, saya berfikir, XAMPP bisa diinstall di Ubuntu ngga sih? Setelah baca-baca dari berbagai sumber, ternyata XAMPP juga bisa diinstall di Ubuntu. Selain XAMPP, ternyata bisa juga pakai LAMP lho kawan.. baru tahu saya hihi.. maklum baru coba Ubuntu.

Jadi.. apa sih LAMP itu? LAMP itu ternyata singkatan dari Linux, Apache, MySQL, PHP. Nah, di tutorial kali ini saya akan coba install PHP 7 dan MariaDB untuk databasenya. Selain itu, akan saya coba install juga PHPMyAdmin untuk memudahkan dalam mengelola MySQL.

Sebagai catatan, untuk semua langkah-langkahnya kita mesti login sebagai root terlebih dahulu. Nah sekarang kita buka terminal lalu kita login sebagai root dengan menjalankan perintah ini di terminal. Ketik perintah di bawah ini ya!
```bash
sudo su 
```

Nah sekarang kita mulai praktiknya. apa aja langkah-langkahnya? Check this out ya!

## Step 1: Install Apache 2.4{#step-1}
Untuk menginstall Apache, kita ketik perintah ini di terminal:
```bash
apt-get -y install apache2 
```

Setelah itu tunggu beberapa saat sampai proses instalasi selesai. Kalau sudah selesai, buka browser kesayangan kamu, lalu masukan localhost pada address bar.

![Tes instalasi](https://3.bp.blogspot.com/-IY7zTGuYWYc/V5ipLanaQhI/AAAAAAAAAaM/ihEGw1GMCNA3Jh_iv3E-xWNlVuHqk3VsACLcB/s320/gambar%2B1.png)

Nah kalau muncul tampilan kaya di atas, itu artinya Apache sudah berhasil kita install.. yeay~! ^^

Sekarang mari kita perhatikan tampilan halaman localhost. Di situ terdapat keterangan kalau document root Apache nya ada di direktori `/var/www/html`. hmm, ternyata berbeda direktori dengan XAMPP ya! ^^
ok, langkah selanjutnya~ 

## Step 2: Install PHP 7{#step-2}
Yep, langkah berikutnya kita coba install PHP 7. Sama seperti langkah sebelumnya, kita hanya perlu mengetik perintah ini di terminal ^^
```bash
apt-get -y install php7.0 libapache2-mod-php7.0 
```

Sekarang kita hanya perlu bersabar menunggu. ^^

Nah, kalau proses instalasi PHP 7 sudah selesai, sekarang kita restart Apache dengan mengetik perintah ini di terminal:
```bash
systemctl restart apache2 
```

Untuk membuktikan apa PHP kita sudah terinstall atau belum, sekarang kita coba bikin file PHP dengan nama info.php, lalu kita simpan di direktori root. Di mana direktorinya? iya, kamu benar.. :D direktorinya ada di `/var/www/html`. Untuk membuat file `info.php` ketik perintah ini di terminal: 
```bash
 gedit /var/www/html/info.php  
```

lalu ketik sintaks di bawah ini di dalam file info.php :
```php
 <?php phpinfo(); ?> 
```

Simpan kembali file info.php dengan menekan Ctrl+s.
Sebelum kita run, kita mesti ubah dulu owner dari file info.php ke www-data user dan grup. Untuk mengubah owner ketik perintah ini di terminal:
```bash
 chown www-data:www-data /var/www/html/info.php 
```

Nah, kalau udah coba kamu run file info.php di browser kesayangan kamu... ^^
![Tes run php](https://2.bp.blogspot.com/-klfhHSjcm_4/V5ipS1pXJ1I/AAAAAAAAAaQ/x0jJQNfdrUM6fj3PcYrcuxOt7gtkAonoQCLcB/w640-h310/gambar%2B2.png)

Kalau berhasil, muncul tampilan kaya gambar di atas. File `info.php` ini bakalan nampilin details PHP yang terinstall, termasuk versi PHP nya. ^^

## Step 3: Install MariaDB{#step-3}
Nah, langkah selanjutnya kita bakalan install MariaDB. Seperti langkah-langkah sebelumnya kita cukup mengetik perintah ini di terminal:
```bash
apt-get -y install mariadb-server mariadb-client 
```

Seperti biasa, kita tunggu dulu sampai proses instalasinya selesai.
.
.
.
.
. 

nah, selesai juga..^^  sekarang kita set password root untuk MariaDBnya yuk! Ketik perintah ini di terminal ya~
```bash
mysql_secure_installation 
```

Nah habis ini bakalan muncul beberapa pertanyaan di terminal. Di bawah ini pertanyaan sama langkah yang mesti kita lakukan.
```bash
 Enter current password for root (enter for none): <-- tekan enter 

 Set root password? [Y/n] <-- ketik y  lalu enter

 New password: <-- masukan password baru untuk maria db 

 Re-enter new password: <-- ulangi lagi passwordnya 

 Remove anonymous users? [Y/n] <-- ketik y lalu enter

 Disallow root login remotely? [Y/n] <-- ketik y lalu enter

 Reload privilege tables now? [Y/n] <-- ketik y lalu enter

```
![Setting password MariaDB](https://2.bp.blogspot.com/-Po--jnddt24/V5ipZGUNSVI/AAAAAAAAAaU/2oU8OA0wVy4d0p4uwmwxuWwIFhOAbDwyACLcB/w640-h374/gambar%2B3.png)

Kalau udah, sekarang kita coba login ke MariaDB pakai command mysql, kita ketik perintah ini di terminal ya!
```bash
mysql -u root -p 
```

Masukin password yang sudah kita buat tadi. Kalau berhasil, nanti muncul tampilan di bawah.. ^^
![tes login MariaDB](https://1.bp.blogspot.com/-XwtZvDLoS8Y/V5ipeuvFocI/AAAAAAAAAaY/r2zpcaPLyywmz4LX3JvuJDn6ARlQjHDpgCLcB/w640-h374/gambar%2B4.png)

Untuk keluar dari shell MariaDB, masukan command `quit`, lalu tekan enter.

## Step 4: Install MySQL / MariaDB support di PHP{#step-4}
Untuk mendapatkan MySQL support di PHP, kita bisa instal paket php7.0-mysql. Selain paket tersebut, ada baiknya kita juga menginstall beberapa paket dan modul yang tersedia, sapa tau nanti berguna buat aplikasi web yang kita buat. Naah, untuk melihat paket sama modul PHP kita ketik perintah ini di terminal:
```bash
apt-cache search php7.0 
```

Pilih paket sama modul yang mau kamu install. Terus buat menginstall modulnya nanti tinggal kamu ketik perintah kaya gini di terminal... ^^
```bash
apt-get -y install php7.0-mysql php7.0-curl php7.0-gd php7.0-intl php-pear php-imagick php7.0-imap php7.0-mcrypt php-memcache php7.0-pspell php7.0-recode php7.0-sqlite3 php7.0-tidy php7.0-xmlrpc php7.0-xsl php7.0-mbstring php-gettext 
```

Tunggu sampai proses instalasi selesai. setelah itu kita restart lagi Apachenya pakai perintah ini:
```bash
 systemctl restart apache2 
```

Coba kamu run lagi file `info.php` di browser, kamu bakalan lihat ada keterangan MySQL / MariaDB support di `phpinfo()`.

## Step 5: Install APCu PHP cache{#step-5}
Kalau kamu bertanya apa itu APCu PHP cache? APCu itu adalah PHP opcode cacher (gratis) yang berguna banget buat mempercepat page PHP dari aplikasi kita. Nah untuk menginstallnya, ketik perintah ini di terminal: 
```bash
 apt-get -y install php-apcu 
```

Setelah proses instalasi selesai, seperti biasa kita mesti restart Apache dengan perintah ini di terminal:
```bash
 systemctl restart apache2 
```

Sekarang coba kamu reload `http://localhost/info.php` di browser kamu, lalu coba kamu scroll ke bawah. kamu bisa lihat banyak sekali modul baru termasuk APCu yang baru saja kita install.. ^^
![cek APCu](https://4.bp.blogspot.com/-qlEwopmmOzo/V5ipnjg77tI/AAAAAAAAAac/s7PsNSahhjcFfOSySeSz-DYVdXct9vJUACLcB/w640-h158/gambar%2B5.png)

Nah, kalau sudah merasa cukup melihat info phpnya.. Jangan lupa hapus file `info.php` untuk alasan keamanan. Ketik perintah ini untuk menghapus file `info.php`:
```bash
rm -f /var/www/html/info.php 
```

## Step 6: Mengaktifkan website SSL di Apache{#step-6}
Untuk mengamankan koneksi antara web browser dan server, biasanya koneksi tersebut dienkripsi menggunakan SSL / TLS. nah untuk supaya support link https:// kita mesti aktifin SSL ini. gimana caranya? Seperti yang sudah-sudah, kita hanya perlu mengetik dua perintah ini di terminal.
```bash
 a2enmod ssl 

 a2ensite default-ssl 
```

kedua perintah di atas berfungsi untuk mengaktifkan modul ssl dan  menambah symlink dalam folder `/etc/apache2/sites-enabled` ke dalam file `/etc/apache2/sites-available/default-ssl.conf`. yang nantinya bakalan ditambahkan ke dalam konfigurasi Apache. Nah, seperti biasa kita restart lagi apachenya untuk melihat efeknya dengan perintah ini di terminal:
```bash
 systemctl restart apache2 
```

Nah sekarang kita coba buka link `https://localhost` di browser. Kamu bakalan nerima SSL warning. Di sini klik advance lalu get certificate. Setelah itu bakalan muncul halaman default dari Apache.

[7] Install phpMyAdmin
Nah, seperti yang kita ketahui, phpMyAdmin itu adalah web interface yang memudahkan kita dalam mengelola MySQL. Untuk menginstall phpMyAdmin, kita ketik perintah ini di terminal:
```bash
apt-get -y install phpmyadmin 
```

Tunggu sejenak hingga muncul beberapa pertanyaan seperti di bawah ini:
```bash
 Web server to configure automatically: <-- pilih apache2 dengan menekan spasi 

 Configure database for phpmyadmin with dbconfig-common? <-- pilih yes 

 MySQL application password for phpmyadmin: <-- Tekan enter 
```


Selanjutnya, ketik perintah di bawah ini:
```bash
echo "update user set plugin='' where User='root'; flush privileges;" | mysql -u root -p mysql 
```

Fungsinya supaya root user bisa login ke dalam phpMyAdmin. 

Nah, sekarang kita coba akses phpMyAdmin dengan buka link `https://localhost/phpmyadmin/` di browser. *Voila~!* phpMyAdmin sudah bisa kita akses.

Gimana? Mudah kan? ngga mudah? hihi, iya sih.. saya juga baru nyoba.. ^^

Ternyata dengan memakai Ubuntu itu banyak hal yang bisa kita pelajari yah.. proses instalasi Apache, PHP sama MariaDBnya pun gak bisa instan dan juga dadakan. 

Semoga bermanfaat.. Semoga semakin semangat belajarnya~ ^^


****
Note:
- [1] Materi praktik tutorial kali ini bersumber dari [sini](https://www.howtoforge.com/tutorial/install-apache-with-php-and-mysql-on-ubuntu-16-04-lamp/).