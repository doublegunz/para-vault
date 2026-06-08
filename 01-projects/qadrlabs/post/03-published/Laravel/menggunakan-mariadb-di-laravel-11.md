---
title: "Tutorial Laravel 11: Menggunakan MariaDB di Laravel 11"
slug: "menggunakan-mariadb-di-laravel-11"
category: "Laravel"
date: "2024-03-13"
status: "published"
---

Pada edisi tutorial laravel 11 sebelumnya, kita sudah coba [menggunakan MySQL di laravel 11](https://qadrlabs.com/post/menggunakan-database-mysql-di-laravel-11). Sekarang kita akan coba gunakan database yang berbeda. Pada edisi tutorial laravel 11 kali ini, kita coba **menggunakan MariaDB sebagai database di laravel 11**.

Kenapa kita coba gunakan MariaDB di laravel 11?

Sebetulnya ini untuk menjawab rasa penasaran saya saja. Rasa penasaran ini muncul setelah saya baca-baca kembali [dokumentasi laravel](https://laravel.com/docs/11.x/database#introduction). Pada dokumentasi laravel, disebutkan Laravel 11 support MariaDB juga, selain database SQLite dan MySQL yang sudah sering kita coba di artikel-artikel sebelumnya. Selain itu, penasaran itu muncul juga karena ketika saya buka file `config/database.php` di Laravel 11, saya melihat ada konfigurasi `mariadb` yang langsung disertakan di file konfigurasi.

```
        'mariadb' => [
            'driver' => 'mariadb',
            'url' => env('DB_URL'),
            'host' => env('DB_HOST', '127.0.0.1'),
            'port' => env('DB_PORT', '3306'),
            'database' => env('DB_DATABASE', 'laravel'),
            'username' => env('DB_USERNAME', 'root'),
            'password' => env('DB_PASSWORD', ''),
            'unix_socket' => env('DB_SOCKET', ''),
            'charset' => env('DB_CHARSET', 'utf8mb4'),
            'collation' => env('DB_COLLATION', 'utf8mb4_unicode_ci'),
            'prefix' => '',
            'prefix_indexes' => true,
            'strict' => true,
            'engine' => null,
            'options' => extension_loaded('pdo_mysql') ? array_filter([
                PDO::MYSQL_ATTR_SSL_CA => env('MYSQL_ATTR_SSL_CA'),
            ]) : [],
        ],
```

Berbeda dengan laravel sebelumnya saya belum menemukan konfigurasi langsung disertakan di file konfigurasi database. 

## Overview{#overview}
Pada **edisi tutorial laravel 11** ini kita akan coba gunakan MariaDB sebagai database di project crud hasil dari [tutorial laravel 11 sebelumnya](https://qadrlabs.com/post/percobaan-development-crud-app-sederhana-menggunakan-laravel-11). Di sini kita coba arahkan konfigurasi database ke MariaDB, kita run `php artisan migrate`, lalu kita coba run project kita.

## Persiapan{#persiapan}
Ada beberapa hal yang harus kita persiapkan terlebih dahulu.
### 1. project sample aplikasi crud. 
Untuk mengikuti percobaan ini, pastikan teman-teman sudah mengikuti  [tutorial development aplikasi crud laravel 11 sebelumnya](https://qadrlabs.com/post/percobaan-development-crud-app-sederhana-menggunakan-laravel-11).

### 2. Database MariaDB
Berdasarkan dokumentasi resmi, MariaDB yang disupport laravel 11 adalah **MariaDB 10.3+**. Sekarang kita cek terlebih dahulu versi mariadb yang terinstall. Untuk mengecek versi mariadb, kita buka terminal lalu run command berikut ini.

```
mariadb -V
```
Output yang ditampilkan, ketika saya run command di atas:
```
mariadb  Ver 15.1 Distrib 10.6.16-MariaDB, for debian-linux-gnu (x86_64) using  EditLine wrapper
```

Dari output di atas, MariaDB yang terinstall adalah MariaDB 10.6.16. Ini artinya MariaDB yang terinstall termasuk yang disupport oleh Laravel 11.

## Step 1 - Buat Database MariaDB baru{#step-1-buat-database-mariadb-baru}
Sekarang kita buat database MariaDB baru dengan nama `db_belajar`. Untuk membuat database, kita bisa langsung buat melalui terminal atau kita juga bisa buat melalui PhpMyadmin atau tools lainnya.

## Step 2 - Ubah Konfigurasi Database{#ubah-konfigurasi-database}
Selanjutnya kita buka file `.env`, lalu kita sesuaikan konfigurasi databasenya.

```
DB_CONNECTION=mariadb
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_belajar
DB_USERNAME=admin
DB_PASSWORD=password
```

Save kembali file `.env`.

Seperti yang terlihat di konfigurasi di atas, koneksi database yang digunakan adalah `mariadb`.

## Step 3 - Run Migrate Command{#step-3-run-migrate-command}
Selanjutnya kita run `migrate` command.
```
php artisan migrate
```

Output:
```
   INFO  Preparing database.  

  Creating migration table ....................................... 7.64ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table .......................... 48.72ms DONE
  0001_01_01_000001_create_cache_table .......................... 13.21ms DONE
  0001_01_01_000002_create_jobs_table ........................... 44.10ms DONE

```

Bisa kita lihat dari output yang ditampilkan di terminal, proses migrate berjalan dengan baik.

## Step 4 - Uji Coba{#step-4-uji-coba}
Sekarang kita bisa uji coba dengan run project kita. Buka kembali terminal, lalu run command berikut ini.
```
php artisan serve
```

Ketika kita buka `http://127.0.0.1:8000/` di browser, kita bisa lihat tampilan awal project yang menampilkan User List dan kita bisa lihat tidak ada tanda-tanda error. Kita bisa langsung uji coba operasi crud. Dan kita bisa lihat semuanya masih berjalan dengan baik.

## Penutup{#penutup}
Pada edisi tutorial laravel 11 kali ini kita sudah coba gunakan MariaDB di project sample aplikasi crud kita. Karena versi MariaDB yang terinstall termasuk versi yang disupport Laravel 11 dan collation yang digunakan terdapat di MariaDB, proses migrate berjalan dengan baik. Berbeda dengan pada saat kita gunakan MySQL. Setelah uji coba, project dapat berjalan dengan baik.