---
title: "Tutorial Install MYSQL di HP Android Menggunakan Termux"
slug: "tutorial-install-mysql-di-hp-android-menggunakan-termux"
category: "How To Install"
date: "2020-12-20"
status: "published"
---

**Tutorial Install MYSQL di HP Android Menggunakan Termux** ini adalah dokumentasi hasil belajar untuk keperluan share ilmu tentang CRUD database. Setelah berhasil install PHP dan Apache Web server pada kegiatan belajar coding di hp sebelumnya, ada kebutuhan untuk install database karena materi untuk *ngoding bareng* sudah masuk ke operasi CRUD database. Namun setelah saya cek website [Wiki  punya termux](https://wiki.termux.com/wiki/Main_Page), saya tidak menemukan MySQL untuk saya coba install. Kabar baiknya ternyata ada MariaDB yang bisa kita gunakan sebagai sistem database. *For Your Info*, MariaDB ini adalah fork sistem manajemen database relasional MySQL yang dikembangkan oleh komunitas dan didukung secara komersial. Biasanya digunakan sebagai alternatif untuk penggunaan MYSQL di dalam LAMP (Linux, Apache, Mysql,  PHP/Python/Perl) stack.

Karena kebanyakan orang sudah familiar dengan MYSQL, di tutorial **Tutorial Install MYSQL di HP Android Menggunakan Termux** ini kita dapat menyebut MariaDB dan MYSQL secara bergantian. Kalau di tutorial ini, terdapat tulisan mysql, itu merujuk ke MariaDB. Dan begitu pula sebaliknya.

## Prasyarat{#prasyarat}
Sama seperti [tutorial sebelumnya](https://qadrlabs.com/post/tutorial-instalasi-apache-web-server-dan-php-di-hp-android-menggunakan-termux), **Tutorial install MYSQL di HP Android** ini membutuhkan koneksi internet untuk proses instalasi. Pastikan koneksi internetmu stabil dan ada kuota yang cukup. Selain itu, karena tutorial ini merupakan lanjutan dari tutorial sebelumnya, jadi pastikan aplikasi termux sudah terinstall.

## Step 1 - Update packages untuk install MariaDB{#step-1}
Pertama kita update dulu package yang ada di Termux:
```bash
apt update
```

Lalu, selanjutnya kita upgrade menggunakan command:

```bash
apt upgrade
```

Jika ada pertanyaan untuk instalasi tentang penggunaan disk space, ketik Y, lalu enter.

Tunggu sampai proses upgrade selesai. 

## Step 2 - Install MariaDB{#step-2}
Tahapan selanjutnya adalah install MariaDB. Ketik command di bawah ini, lalu tekan enter:

```bash
pkg install mariadb
```

Pada tahapan ini biasanya ada pertanyaan untuk proses installasi. Jika ada pertanyaan: ```Do you want to continue?[Y/n]```, ketik ```Y``` lalu enter untuk memulai proses instalasi MariaDB. 


![step 1 - install MariaDB](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-mysql/img-1.png)

Tunggu sampai proses instalasi selesai.


## Step 3 - Start MariaDB {#step-3}
Setelah proses instalasi selesai, langkah berikutnya kita uji coba apakah proses instalasinya berhasil. Kita coba start mysql daemon, ketik command di bawah ini lalu enter:
```bash
mysqld_safe -u root &
```

**Note:** Jika tampil keterangan `mysqld_safe` deprecated. bisa run command berikut ini untuk start mariadb.

```bash
mariadbd-safe -u root &
```

![start mysql daemon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-mysql/img-2-start-mysql-daemon.png)

Selanjutnya kita coba login menggunakan Termux username. Kita coba enable akses ke akun root menggunakan dengan cara login menggunakan termux username:
```bash
mysql -u root
```

![login menggunakan termux username](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-mysql/img-3-login-using-termux-username.png)

Setelah berhasil login, kita coba buat password baru untuk akun ```root```. Sebagai contoh di sini passwordnya kita set ```1234```.
```bash
use mysql;
set password for 'root'@'localhost' = password('1234');
flush privileges;
quit;
```

![set password untuk akun root](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-mysql/img-4-set-password-untuk-root.png)

Sekarang kita coba login sebagai ```root``.
```bash
mysql -u root -p
```
Kita perlu memasukan password yang sebelumnya sudah kita set. Ketik passwordnya ```1234```, lalu enter.

## Step 4 - Uji Coba Membuat Database Baru{#step-4}
Kita sudah berhasil login sebagai ```root```, selanjutnya kita coba tes dengan membuat database baru. Sebagai contoh di sini nama databasenya ```db_codelab```.

```sql
CREATE DATABASE db_codelab;
```

![Buat database baru](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-mysql/img-5-buat-database.png)

Kita gunakan database yang baru saja kita buat.
```sql
use db_codelab;
```

Kita buat tabel baru dengan nama ```mahasiswa```.
```sql
CREATE TABLE mahasiswa (
 id int(11) NOT NULL AUTO_INCREMENT,
 nama varchar(100) NOT NULL,
 nim varchar(100)NOT NULL,
 PRIMARY KEY (id)
);
```

Setelah tabel kita buat, langkah selanjutnya adalah mencoba menambahkan data, kamu boleh isi nama dan nim nya bebas.
```sql
INSERT INTO mahasiswa VALUES (null, 'Gun Gun Priatna', '123456789');
```

Nah data berhasil kita tambahkan. Untuk memastikan kita coba cek datanya.
```sql
SELECT * FROM mahasiswa;
```

![insert dan select](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-mysql/img-7-insert-dan-select.png)

## Step 5 - Stop MYSQL (optional){#step-5}
Pertama kita cek dulu proses MariaDB menggunakan command ini:
```bash
ps aux | grep mariadb
```

Output:
```
u0_a92    5296  0.2  0.0 10818220 3344 pts/1   S<   05:40   0:00 /data/data/com.termux/files/usr/bin/sh /data/data/com.termux/files/usr/bin/mariadbd-safe -u root
u0_a92    5376  0.9  2.3 11304904 96356 pts/1  S<l  05:40   0:00 /data/data/com.termux/files/usr/bin/mariadbd --basedir=/data/data/com.termux/files/usr --datadir=/data/data/com.termux/files/usr/var/lib/mysql --plugin-dir=/data/data/com.termux/files/usr/lib/mysql/plugin -u root --log-error=/data/data/com.termux/files/usr/var/lib/mysql/localhost.err --pid-file=localhost.pid
u0_a92    5403  1.0  0.0 10792444 3328 pts/1   S<+  05:40   0:00 grep mariadb
```

Kamu bisa lihat ada ```mariadbd-safe ``` di output ketika command di atas dieksekusi.

Selanjutnya kita coba stop MariaDB. Ketik command di bawah ini, lalu enter.
```bash
mariadb-admin -u root -p shutdown
```

Kemudian masukan password `root`, yaitu `1234` untuk melanjutkan. Output yang ditampilkan.
```
[1]+  Done                    mariadbd-safe -u root
```


Nah, kita cek lagi apakah MariaDB nya masih jalan atau sudah berhenti.
```bash
ps aux | grep mariadb
```

output:
```
u0_a92    5492  2.0  0.0 10849788 3400 pts/1   S<+  05:43   0:00 grep mariadb
```

Outputnya agak beda dengan yang sebelumnya dan tidak ditemukan proses ```mariadbd-safe```.

Kawan, kamu sudah berhasil menginstall MariaDB dan di tutorial sebelumnya kita juga sudah coba install Apache Web server dan PHP. Setelah selesai mencoba **Tutorial Install MYSQL di HP Android Menggunakan Termux**, sekarang kamu sudah bisa coba untuk memulai belajar web development dengan fasilitas yang ada. 

Selamat mencoba! 

### Referensi{#referensi}
* [Termux Wiki tentang MariaDB](https://wiki.termux.com/wiki/MariaDB)