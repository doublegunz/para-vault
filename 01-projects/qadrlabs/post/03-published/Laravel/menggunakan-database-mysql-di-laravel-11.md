---
title: "Tutorial Laravel 11: Menggunakan Database Mysql di Laravel 11"
slug: "menggunakan-database-mysql-di-laravel-11"
category: "Laravel"
date: "2024-03-12"
status: "published"
---

Halo, pada seri tutorial laravel 11 edisi sebelumnya, yaitu [Development Sample Aplikasi CRUD](https://qadrlabs.com/post/percobaan-development-crud-app-sederhana-menggunakan-laravel-11), kita sudah mencoba mengembangkan contoh aplikasi crud sederhana. Pada tutorial tersebut, kita bisa lihat database yang kita gunakan adalah sqlite. SQLite ini merupakan database yang digunakan secara default pada Laravel 11. Di edisi tutorial laravel 11 kali ini, kita akan coba gunakan database lain di aplikasi crud kita. Sebagai contoh di sini kita akan gunakan Mysql sebagai database di aplikasi crud kita.

## Overview {#overview}
Pada edisi tutorial laravel 11 kali ini kita akan lanjutkan project aplikasi crud yang sudah kita kembangkan di edisi tutorial laravel 11 sebelumnya. Pada edisi kali ini kita akan gunakan MySQL di project aplikasi crud kita. Untuk mengubah database nanti kita akan coba:
1. Membuat database MySQL baru.
2. Mengubah konfigurasi database di aplikasi crud.
3. Run migrate command untuk database mysql baru.
4. Dan terakhir uji coba.

Goal edisi tutorial laravel 11 ini adalah project aplikasi crud kita dapat berjalan setelah kita ubah dan arahkan ke database MySQL.

## Persiapan{#persiapan}
Untuk mengikuti tutorial laravel 11 ini, pastikan teman-teman sudah menyelesaikan project crud app dari [edisi tutorial laravel 11 sebelumnya](https://qadrlabs.com/post/percobaan-development-crud-app-sederhana-menggunakan-laravel-11) dan project aplikasi crud  dapat berjalan dengan baik.

## Step 1 - Buat Database Mysql baru{#step-1-buat-database-mysql}
Pertama kita siapkan terlebih dahulu database yang akan kita gunakan. Kita buat database baru dengan nama `db_belajar`. Teman-teman bisa buat database baru langsung melalui terminal atau bisa juga melalui Phpmyadmin atau tools lainnya.

## Step 2 - Ubah Konfigurasi Database{#step-2-ubah-konfigurasi-database}
Sekarang kita buka file `.env`, lalu kita ubah konfigurasi databasenya.
```
DB_CONNECTION=mysql  
DB_HOST=127.0.0.1  
DB_PORT=3306  
DB_DATABASE=db_belajar  
DB_USERNAME=admin  
DB_PASSWORD=password
```

Pada baris kode konfigurasi di atas, kita bisa lihat koneksi database yang kita gunakan adalah `mysql`, di mana di konfigurasi sebelumnya adalah `sqlite`. Selain itu, kita juga mengarahkan database ke `db_belajar` yang baru saja kita buat. Selain itu, kita sesuaikan juga credential databasenya. 

Setelah selesai coding, kita save kembali file `.env`.

## Step 3 - Run Migrate Command{#step-3-run-migrate-command}
Selanjutnya kita run `migrate` command.
```
php artisan migrate
```

Karena versi MySQL yang saya gunakan bukan yang terbaru, tampil pesan error seperti berikut ini.
```

  SQLSTATE[HY000]: General error: 1273 Unknown collation: 'utf8mb4_0900_ai_ci' (Connection: mysql, SQL: select table_name as `name`, (data_length + index_length) as `size`, table_comment as `comment`, engine as `engine`, table_collation as `collation` from information_schema.tables where table_schema = 'db_belajar' and table_type in ('BASE TABLE', 'SYSTEM VERSIONED') order by table_name)

```

> **Catatan**
> Tulisan tentang error ini opsional untuk dibaca dan bisa diskip, karena di Laravel v11.0.6, collation default diubah kembali menjadi `utf8mb4_unicode_ci`, jadi sudah tidak tampil error lagi ketika kita run `php artisan migrate`. Referensi  [https://github.com/laravel/framework/pull/50555/files](https://github.com/laravel/framework/pull/50555/files).
> Tulisan ini sekarang dijadikan sebagai catatan apabila di kemudian hari terdapat error yang sama.

Error tersebut terjadi karena MySQL versi tertentu tidak mendukung kolasi `utf8mb4_0900_ai_ci`. Kolasi ini merupakan bagian dari versi MySQL yang lebih baru.

Untuk mengatasi masalah ini, kita dapat mengubah kolasi yang digunakan dalam migrasi atau konfigurasi database kita ke kolasi yang didukung oleh versi MySQL yang kita gunakan.

Salah satu pilihan yang dapat kita lakukan adalah mengubah kolasi dalam file `config/database.php` di dalam project crud app. Temukan pengaturan `'collation'` di konfigurasi MySQL kita dan selanjutnya kita dengan kolasi yang didukung, seperti `utf8mb4_unicode_ci`.

Berikut ini adalah konfigurasi default MySQL:

```php
        'mysql' => [
            'driver' => 'mysql',
            'url' => env('DB_URL'),
            'host' => env('DB_HOST', '127.0.0.1'),
            'port' => env('DB_PORT', '3306'),
            'database' => env('DB_DATABASE', 'laravel'),
            'username' => env('DB_USERNAME', 'root'),
            'password' => env('DB_PASSWORD', ''),
            'unix_socket' => env('DB_SOCKET', ''),
            'charset' => env('DB_CHARSET', 'utf8mb4'),
            'collation' => env('DB_COLLATION', 'utf8mb4_0900_ai_ci'),
            'prefix' => '',
            'prefix_indexes' => true,
            'strict' => true,
            'engine' => null,
            'options' => extension_loaded('pdo_mysql') ? array_filter([
                PDO::MYSQL_ATTR_SSL_CA => env('MYSQL_ATTR_SSL_CA'),
            ]) : [],
        ],
```

Selanjutnya kita ubah bagian `collation` menjadi:

```php
        'mysql' => [
            'driver' => 'mysql',
            'url' => env('DB_URL'),
            'host' => env('DB_HOST', '127.0.0.1'),
            'port' => env('DB_PORT', '3306'),
            'database' => env('DB_DATABASE', 'laravel'),
            'username' => env('DB_USERNAME', 'root'),
            'password' => env('DB_PASSWORD', ''),
            'unix_socket' => env('DB_SOCKET', ''),
            'charset' => env('DB_CHARSET', 'utf8mb4'),
            'collation' => env('DB_COLLATION', 'utf8mb4_unicode_ci'), // ubah bagian ini saja
            'prefix' => '',
            'prefix_indexes' => true,
            'strict' => true,
            'engine' => null,
            'options' => extension_loaded('pdo_mysql') ? array_filter([
                PDO::MYSQL_ATTR_SSL_CA => env('MYSQL_ATTR_SSL_CA'),
            ]) : [],
        ],
```

Setelah selesai, kita save kembali file `config/database.php`.

Kemudian kita coba run kembali `migrate` command.
```
php artisan migrate
```

Tampil output berikut ini di terminal.

```
  Creating migration table ....................................... 7.52ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table .......................... 63.49ms DONE
  0001_01_01_000001_create_cache_table .......................... 12.86ms DONE
  0001_01_01_000002_create_jobs_table ........................... 43.72ms DONE

```
Tanda collation masih didukung sama MySQL yang saya gunakan.

## Step 4 - Uji Coba{#step-4-uji-coba}
Sekarang kita tes langsung aplikasi crud kita, apakah masih dapat digunakan atau ada error. Kita buka kembali terminal, lalu kita run aplikasi crud kita.
```
php artisan serve
```

Apabila berhasil, akan tampil halaman `User List`. Di sini kita bisa uji coba untuk menambahkan data baru, memperbaharui data dan menghapus data. Setelah saya coba, semuanya masih dapat digunakan dan berjalan dengan baik.

## Penutup{#penutup}
Pada edisi tutorial laravel 11 kali ini kita sudah mencoba untuk mengganti database yang digunakan di project aplikasi crud dari edisi sebelumnya. Secara default database yang digunakan di laravel 11 adalah SQLite dan di edisi tutorial laravel 11 kali ini kita ubah menjadi MySQL. Pada percobaan sebelumnya, pada saat laravel masih versi 11.00, sempat terjadi error ketika run migrate command. Penyebab error tersebut, karena collation default MySQL belum didukung di MySQL yang terinstall di laptop. Solusi untuk memperbaiki error tersebut adalah mengubah collation menjadi collation yang didukung MySQL yang terinstall. Pada update laravel selanjutnya, yaitu Laravel v11.0.6, collation default direset ke collation yang didukung MySQL versi lama. Sehingga ketika uji coba project aplikasi crud berjalan dengan baik.

Di edisi selanjutnya kita coba [gunakan MariaDB](https://qadrlabs.com/post/menggunakan-mariadb-di-laravel-11) di project crud kita.