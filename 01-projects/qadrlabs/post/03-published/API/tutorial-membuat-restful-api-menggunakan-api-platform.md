---
title: "Tutorial Membuat Restful API menggunakan API Platform"
slug: "tutorial-membuat-restful-api-menggunakan-api-platform"
category: "API"
date: "2019-07-04"
status: "published"
---

Beberapa pekan lalu, saya mengisi sebuah kelas tentang pengembangan aplikasi mobile. Dan dalam kelas tersebut kami membahas sekilas tentang pengembangan Rest API untuk mendukung pengembangan aplikasi mobile. Karena keterbatasan waktu, kami belum sempat praktik untuk mengembangkan Rest API. **Tutorial membuat Rest API menggunakan API Platform** ini dihadirkan untuk teman-teman yang sudah mengikuti kelas pengembangan aplikasi mobile dan juga kamu (teman-teman pengunjung blog ini). Selamat membaca!

## Apa itu API Platform{#apa-itu-api-platform}
Menurut [dokumentasi resminya](https://api-platform.com/docs/distribution/), API Platform adalah sebuah full stack framework yang di dedikasikan untuk API-driven project. Framework ini berisi library PHP untuk membuat API dengan fitur terlengkap yang mendukung standar industri, seperti JSON-LD, GraphQL, OpenAPI dan lain-lain. 

API Platform juga menyediakan tool Javascript untuk mengkonsumsi API tersebut dalam sekejap (admin, PWA dan mobile apps generator, hypermedia client dan lainnya) dan juga  integrasi Docker dan Kubernetes untuk develop dan deploy secara instant di Cloud.

Untuk membuat API dengan fitur lengkap, admin interface dan Progressive Web App, kita hanya perlu mendesain model data dari API kita dan buat data model tersebut sebagai Plain Old PHP Objects (POPO).

API Platform menggunakan class model untuk expose sebuah web API dengan berbagai fitur, diantaranya:
* Create, Retrieving, Update, dan delete (CRUD)
* Validasi data
* Pagination
* Filtering
* Sorting
* Hypermedia/HATEOAS dan mendukung JSON-LD, HAL, JSON API
* Mendukung GraphQL
* Nice UI dan dokumentasi yang machine-readable
* Authentication (Basic HTTP, cookies seperti JWT dan OAuth melalui extention)
* CORS headers
* Pengecekan keamanan dan header
* invalidation-based HTTP caching
* dan apapun itu yang diperlukan untuk membangun sebuah API yang modern.

Dan satu lagi, di dalam distribusi API Platform ini terdapat framework Symfony. Jadi API Platform ini sangat compatible dengan berbagai Symfony bundles (plugins). Kita bisa menambahkan langsung fitur-fitur seperti custom, service-oriented, API endpoint, JWT atau OAuth authentication, HTTP caching, mengirim email atau asynchronous job untuk API kita.

Jadi gitu teman-teman... karena fiturnya yang segudang, saya memutuskan untuk menggunakan API Platform di tutorial ini. Nah sekarang kita mulai praktek yuk!

## Project Overview{#overview}
Studi kasus yang akan dibahas di **tutorial membangun Rest API menggunakan API Platform** ini adalah tentang aplikasi toko buku atau bookshop. Dalam aplikasi toko buku, setidaknya ada beberapa proses bisnis seperti pengelolaan data buku, pengelolaan stok buku, transaksi pembelian dan lain-lain. Dari beberapa proses bisnis yang tersedia, di tutorial ini kita akan fokus dalam mengelola data buku. 

Sebagai contoh untuk project tutorial ini, skema database untuk aplikasi toko buku ini dapat kita lihat pada gambar berikut ini.

![Skema Database](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/api-platform/skema_database.png)

## Step 1 - Setup Project{#step-1}
Cara terbaik dalam menggunakan API Platform adalah dengan mengunduh langsung distribusi official API Platform. Karena perlu belajar dulu tentang docker, jadi kita coba install API Platform ini menggunakan `symfony cli`.

Pertama kita install dulu `symfony cli`. Buka terminal lalu kita run `command` ini.
```bash
curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | sudo -E bash
sudo apt install symfony-cli

```

Tunggu sampai proses install `symfony cli` selesai.

Selanjutnya kita buat project baru menggunakan `symfony cli`.
```
symfony new bookshop-api
```
Output:
```
* Creating a new Symfony project with Composer
  (running /usr/local/bin/composer create-project symfony/skeleton /home/user/symfony/bookshop-api  --no-interaction)

* Setting up the project under Git version control
  (running git init /home/user/symfony/bookshop-api)

                                                                                
 [OK] Your project is now ready in /home/user/symfony/bookshop-api 
```

Selanjutnya masuk ke direktori projek.
```
cd bookshop-api
```

Di dalam direktori projek kita install api platform.
```
symfony composer require api
```
Kemudian kita tambahkan library `maker-bundle`.
```bash
composer require symfony/maker-bundle --dev
```
Tunggu beberapa saat sampai proses instalasi selesai. 

## Step 2 - Konfigurasi database{#step-2}
Setelah proses instalasi selesai, langkah berikutnya adalah mengatur konfigurasi database. Di tutorial ini, kita buat database dengan nama ``db_bookshop``. Buka file ```.env``` di dalam root project, lalu atur konfigurasi database.
```
DATABASE_URL="mysql://db_user:db_password@127.0.0.1:3306/db_bookshop?serverVersion=8.0.32&charset=utf8mb4"
```
**Note**:
- `db_user` merujuk ke username untuk mysql
- `db_password` merujuk ke password untuk mysql
- `db_bookshop` merujuk ke nama database

Ganti `db_user` dan `db_password` sesuai dengan credential database kamu. Jangan lupa save kembali file `.env`.

Selanjutnya kita akan buat database. Di sini kita coba buat database melalui terminal. Buka terminal, lalu run `command` ini untuk membuat database:

```console
symfony console doctrine:database:create
```
Output:
```
Created database `db_bookshop` for connection named default
```

## Step 3 - Buat Model{#step-3}

Tahapan berikutnya adalah membuat model. Di tahapan ini kita akan membuat dua class model sesuai dengan skema database sebelumnya menggunakan symfony MakerBundle. 

Sekarang kita buat terlebih dahulu entitas ```Book``` dengan fields `isbn`, `title`, `description`, `author`, dan `publicationDate` menggunakan symfony MakerBundle. Buka terminal, lalu run `command` di bawah ini:
```bash
bin/console make:entity --api-resource
```
Selanjutnya akan tampil prompt di output terminal. Kita isi sesuai dengan skema database yang sudah dibuat pada bagian [Overview](#overview):
```bash
$ bin/console make:entity --api-resource
 Class name of the entity to create or update (e.g. AgreeableKangaroo):
 > Book

 created: src/Entity/Book.php
 created: src/Repository/BookRepository.php
 
 Entity generated! Now let's add some fields!
 You can always add more fields later manually or by re-running this command.

 New property name (press <return> to stop adding fields):
 > isbn

 Field type (enter ? to see all types) [string]:
 > string

 Field length [255]:
 > 255

 Can this field be null in the database (nullable) (yes/no) [no]:
 > no

 updated: src/Entity/Book.php

 Add another property? Enter the property name (or press <return> to stop adding fields):
 > title

 Field type (enter ? to see all types) [string]:
 > string

 Field length [255]:
 > 255

 Can this field be null in the database (nullable) (yes/no) [no]:
 > no

 updated: src/Entity/Book.php

 Add another property? Enter the property name (or press <return> to stop adding fields):
 > description

 Field type (enter ? to see all types) [string]:
 > text

 Can this field be null in the database (nullable) (yes/no) [no]:
 > no

 updated: src/Entity/Book.php

 Add another property? Enter the property name (or press <return> to stop adding fields):
 > publicationDate

 Field type (enter ? to see all types) [string]:
 > datetime

 Can this field be null in the database (nullable) (yes/no) [no]:
 > no

 updated: src/Entity/Book.php

 Add another property? Enter the property name (or press <return> to stop adding fields):
 > 


           
  Success! 
           
```


Selanjutnya kita buat entitas yang kedua yaitu ```Review``` dengan fields `rating`, `body`, `author`, dan `publicationDate` menggunakan symfony MakerBundle. Buka terminal, lalu ketik run `command` di bawah ini:
```bash
bin/console make:entity --api-resource
```

Sama seperti sebelumnya, akan muncul prompt interaktif di terminal dan kita isi sesuai dengan skema database untuk Entity `Review`.

```bash
$ bin/console make:entity --api-resource

 Class name of the entity to create or update (e.g. VictoriousJellybean):
 > Review

 created: src/Entity/Review.php
 created: src/Repository/ReviewRepository.php
 
 Entity generated! Now let's add some fields!
 You can always add more fields later manually or by re-running this command.

 New property name (press <return> to stop adding fields):
 > rating

 Field type (enter ? to see all types) [string]:
 > smallint

 Can this field be null in the database (nullable) (yes/no) [no]:
 > no

 updated: src/Entity/Review.php

 Add another property? Enter the property name (or press <return> to stop adding fields):
 > body

 Field type (enter ? to see all types) [string]:
 > text

 Can this field be null in the database (nullable) (yes/no) [no]:
 > no

 updated: src/Entity/Review.php

 Add another property? Enter the property name (or press <return> to stop adding fields):
 > author

 Field type (enter ? to see all types) [string]:
 > string

 Field length [255]:
 > 255

 Can this field be null in the database (nullable) (yes/no) [no]:
 > no

 updated: src/Entity/Review.php

 Add another property? Enter the property name (or press <return> to stop adding fields):
 > publicationDate

 Field type (enter ? to see all types) [string]:
 > datetime

 Can this field be null in the database (nullable) (yes/no) [no]:
 > no

 updated: src/Entity/Review.php

 Add another property? Enter the property name (or press <return> to stop adding fields):
 > 


           
  Success! 
           
```

Setelah kita buat class Entity, kita bisa lihat terdapat dua file hasil generate, yaitu `src/Entity/Book.php` dan `src/Entity/Review.php`.

Dan yang terakhir, gunakan `Doctrine` untuk sinkronisasikan struktur table database dengan data model yang baru dibuat:
```bash
bin/console doctrine:schema:update --force
```

Output:
```
 Updating database schema...

     2 queries were executed

                                                                                
 [OK] Database schema updated successfully!                                     
                                                                                
```

## Step 4 - Uji Coba{#step-4}
Tahapan selanjutnya kita akan menguji coba project kita. Buka kembali terminal, lalu run aplikasi dengan `command` di bawah ini:

```console
symfony serve
```

Selanjutnya buka browser, lalu buka url ```http://127.0.0.1:8000/api```. Kita bisa lihat tampilan dokumentasi api seperti yang terlihat pada gambar di bawah ini.

![Entrypoint](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/api-platform/api_entrypoint.png)

Kita bisa coba-coba langsung mengirimkan request ke API kita melalui UI ini. Dan tentunya, kita bisa menggunakan HTTP client untuk mengirim request ke API kita, misalnya menggunakan Postman.

## Penutup{#penutup}
Ada satu kesimpulan yang dapat kita ambil setelah mencoba membuat project restful api menggunakan api platform ini, yaitu framework api platform ini benar-benar mempermudah kita sebagai developer untuk membuat restful api. Kita hanya perlu membuat `entity` class, lalu restful api sudah tersedia. 

Kalau ada framework ini, apakah sia-sia belajar membuat restful api tanpa framework? Tentu tidak sia-sia ya.. karena ketika kita belajar sejengkal demi sejengkal itu akan menambah pemahaman kita tentang restful api itu sendiri. Bagaimana menurutmu?