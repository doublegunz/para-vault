---
title: "Database Seeder CodeIgniter 4"
slug: "database-seeder-codeigniter-4"
category: "CodeIgniter 4"
date: "2020-12-28"
status: "published"
---

Beberapa waktu yang lalu, saya menangani pengembangan web yang harus terintegrasi dengan sistem yang sudah ada. Akun yang dipakai untuk login ke dalam web yang saya kembangkan itu pun akun dari sistem yang saat ini sudah berjalan. Selain data akun, perlu juga data pendukung lainnya untuk keperluan development web. Karena belum ada database yang bisa digunakan untuk keperluan development, akhirnya saya membuat database khusus untuk development dan datanya pun digenerate langsung menggunakan library faker. Solusi ini biasanya disebut Database Seeding dan saya coba terapkan database seeding ini di codeigniter 4 untuk generate dummy data.

Di [Dokumentasi codeigniter 4 tentang Database Seeding](https://codeigniter.com/user_guide/dbmgmt/seeds.html), Database seeding merupakan salah satu cara yang memudahkan developer dan biasa digunakan untuk menambahkan data ke dalam database. Sebetulnya bisa saja kita insert langsung kalau datanya sedikit. Nah kalau datanya banyak? ratusan? ribuan? ga mungkin kita tambahkan satu satu datanya. Jadi database seeding ini benar-benar mempermudah untuk membuat atau generate dummy data di project CodeIgniter 4 dan tentu untuk framework lainnya.

Pada seri tutorial [Belajar Codeigniter 4](https://qadrlabs.com/series/belajar-codeigniter-4) edisi kali ini, supaya sample datanya kelihatan seperti data beneran, kita akan gunakan [Library Faker](https://github.com/fzaninotto/Faker). Library faker ini biasa digunakan untuk generate data seperti nama, alamat, email, text dan lainnya. Oh iya, Library Faker ini sudah include ketika kita install CodeIgniter 4, jadi kita tidak perlu install secara manual. Untuk memastikan, kita bisa buka file `composer.json`.

```json
{
    "name": "codeigniter4/appstarter",
    "description": "CodeIgniter4 starter app",
    "license": "MIT",
    "type": "project",
    "homepage": "https://codeigniter.com",
    "support": {
        "forum": "https://forum.codeigniter.com/",
        "source": "https://github.com/codeigniter4/CodeIgniter4",
        "slack": "https://codeigniterchat.slack.com"
    },
    "require": {
        "php": "^8.1",
        "codeigniter4/framework": "^4.0"
    },
    "require-dev": {
        "fakerphp/faker": "^1.9",
        "mikey179/vfsstream": "^1.6",
        "phpunit/phpunit": "^10.5.16"
    },
    "autoload": {
        "psr-4": {
            "App\\": "app/",
            "Config\\": "app/Config/"
        },
        "exclude-from-classmap": [
            "**/Database/Migrations/**"
        ]
    },
    "autoload-dev": {
        "psr-4": {
            "Tests\\Support\\": "tests/_support"
        }
    },
    "config": {
        "optimize-autoloader": true,
        "preferred-install": "dist",
        "sort-packages": true
    },
    "scripts": {
        "test": "phpunit"
    }
}

```

Bisa kita perhatikan di bagian `require-dev`, terdapat library `fakerphp/faker` yang sudah terinstall.

**Daftar Isi**

1. [Overview](#overview)
2. [Step 1: Instalasi CodeIgniter 4](#step-1-instalasi-codeigniter)
3. [Step 2: konfigurasi project](#step-2-konfigurasi-project)
4. [Step 3: Membuat database](#step-3-create-database)
5. [Step 4: Membuat file migration](#step-4-create-migration)
6. [Step 5: Membuat database seeder](#step-5-create-seeder)
7. [Step 6: Run database seeder](#step-6-run-seeder)
8. [Kesimpulan](#kesimpulan)
9. [Referensi](#referensi)

## Overview {#overview}
Pada tutorial Database Seeder CodeIgniter 4 ini kita akan membuat sample project untuk keperluan generate dummy data. Data yang akan kita coba generate adalah data ```users```. Di dalam tabel ```users``` ini nanti ada field untuk `id`, `name`, `email`, dan `password`.

Output sample project ini adalah berupa data yang berhasil digenerate ketika database seeder kita run. Kita bisa pastikan apakah data sudah berhasil digenerate dengan mengecek table `users`.

## Step 1 - Instalasi CodeIgniter 4 {#step-1-instalasi-codeigniter}

Langkah pertama adalah instalasi codeigniter 4. Dalam proses instalasi codeigniter 4, cara yang akan digunakan adalah instalasi menggunakan ```composer```. Hal ini dilakukan supaya kita terbiasa menggunakan `composer`, dan boleh jadi nanti kedepannya kita bisa buat library sendiri.

Sekarang kita buka terminal atau cmd. Di dalam terminal eksekusi `composer command` ini:

```bash
composer create-project codeigniter4/appstarter dbseeder-example
```

Seperti yang kita lihat, nama project kita cukup sederhana ```dbseeder-example```, disesuaikan dengan tujuan tutorial ini. Oke seperti biasa kita tunggu proses instalasinya selesai.

## Step 2 - konfigurasi project {#step-2-konfigurasi-project}

Pada tahapan kedua ini kita akan mengatur konfigurasi project, seperti database dan base url. Sebagai pengingat ada beberapa cara untuk mengatur konfigurasi. Yang pertama itu kita bisa atur langsung konfigurasi yang ada di direktori ```app/Config```, seperti pengaturan base url di file ```App.php``` atau database di file ```Database.php``` yang ada di direktori tersebut. Cara kedua adalah kita atur semua konfigurasi di file ```.env```. Di tutorial ini kita akan pakai cara kedua, supaya terbiasa mengatur konfigurasi untuk keperluan di environment production dan **supaya credentials seperti akun database tidak ikut ke push** ketika kita menggunakan `git` repositori seperti github atau gitlab.

Sebelum mengatur konfigurasi, kita pindah dulu ke direktori project, yaitu ```dbseeder-example```. Eksekusi command ini di terminal, untuk pindah ke direktori project:

```bash
cd dbseeder-example
```

Kalau kita perhatikan di dalam folder project kita terdapat beberapa file, diantaranya file ```env``` (tanpa tanda titik). Kita copy file ini ```env``` ini, lalu kita rename menjadi ```.env```.  Buka lagi terminalnya lalu jalankan command ini untuk copy file `env` menjadi file `.env`.

```bash
cp env .env
```

Setelah command di atas dieksekusi, kita bisa lihat file baru dengan nama ```.env```. Apabila teman-teman menggunakan OS Windows, bisa copy file seperti biasa, lalu copy-paste isi dari file `env` ke file `.env`.

Selanjutnya kita buka project kita di text editor. kita bisa open folder di text editor langsung. Kalau text editor yang digunakan visual studio code, bisa juga ketik command ini untuk buka project di visual studio code.

```bash
code .
```

Selanjutnya buka file ```.env``` yang sebelumnya sudah kita copy. Di dalamnya cari baris kode ini.

```
# CI_ENVIRONMENT = production

# app.baseURL = ''

# database.default.hostname = localhost
# database.default.database = ci4
# database.default.username = root
# database.default.password = root
# database.default.DBDriver = MySQLi
```

hapus tanda ```#```, lalu sesuaikan menjadi seperti ini:

```
CI_ENVIRONMENT = development

app.baseURL = 'http://localhost:8080/'

database.default.hostname = localhost
database.default.database = db_ci4
database.default.username = root
database.default.password = passwordmysqlkita
database.default.DBDriver = MySQLi
```

Bisa kita lihat di baris kode di atas, kita atur environmentnya `CI_ENVIRONMENT` menjadi development, supaya jikalau seandainya nanti ada error, petunjuk errornya ini bisa langsung ditampilkan di browser. Konfigurasi selanjutnya adalah base url atau `app.baseURL` dan juga konfigurasi database. Untuk konfigurasi database, nama databasenya ```db_ci4``` dan untuk username & passwordnya sesuaikan dengan username & password yang kamu gunakan.

Jangan lupa, save file ```.env```.

## Step 3 - Membuat database {#step-3-create-database}

Setelah pengaturan database selesai, langkah berikutnya adalah membuat database. Buka phpMyAdmin, lalu buat database baru dengan nama ```db_ci4```. Ya, nama databasenya sesuai dengan nama database yang ada di file ```.env``` yang sebelumnya sudah kita modifikasi.

## Step 4 - Membuat file migration {#step-4-create-migration}

Untuk pembuatan tabel, kita ga langsung buat tabelnya melalui phpMyAdmin. Di sini kita belajar membuat tabel menggunakan migration punya codeigniter 4. Nah sebagai contoh untuk nama tabelnya adalah ```users```.

Kita buka kembali terminal, lalu eksekusi `spark` command ini:

```bash
php spark make:migration Users
```

Output:

```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 12:00:56 UTC+00:00

File created: APPPATH/Database/Migrations/2024-05-08-120056_Users.php

```



Command di atas adalah command untuk membuat file migration baru. Kita cek filenya di direktori ```app/Database/Migrations```. Nah di direktori tersebut ada file dengan format nama ```YYYY-MM-DD-HHIISS_namatable.php```. File hasil generate secara otomatis ketika tutorial ini dibuat `2024-05-08-120056_Users.php`. Ya kita buka filenya, lalu kita modifikasi method ```up()``` dan method ```down()```.

```php
<?php namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class Users extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id' => [
                'type' => 'INT',
                'unsigned' => TRUE,
                'auto_increment' => TRUE
            ],
            'name' => [
                'type' => 'VARCHAR',
                'constraint' => 255,
                'null' => FALSE,
            ],
            'email' => [
                'type' => 'VARCHAR',
                'constraint' => 255,
                'null' => FALSE,
                'unique' => TRUE,
            ],
            'password' => [
                'type' => 'VARCHAR',
                'constraint' => 255,
                'null' => FALSE,
            ],
            'created_at' => [
                'type' => 'datetime',
                'null' => TRUE
            ],
            'updated_at' => [
                'type' => 'datetime',
                'null' => TRUE
            ]
        ]);

        $this->forge->addKey('id', TRUE);
        $this->forge->createTable('users');
    }

    //--------------------------------------------------------------------

    public function down()
    {
        $this->forge->dropTable('users');
    }
}
```

Setelah selesai ketik baris kode di atas. Save kembali file migrationnya. Selanjutnya kita run perintah ```migrate``` di terminal. Buka terminal, lalu eksekusi command ini:

```bash
php spark migrate
```

Output:

```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 12:02:14 UTC+00:00

Running all new migrations...
	Running: (App) 2024-05-08-120056_App\Database\Migrations\Users
Migrations complete.
```

Setelah selesai, kita bisa lihat di database ```db_ci4``` ada dua tabel baru yaitu tabel ```migrations``` dan juga tabel ```users```.

## Step 5 - Membuat database seeder {#step-5-create-seeder}

Tahapan berikutnya adalah inti dari tutorial ini yaitu membuat database seeder. Kita buat file seeder di direktori ```app\Database\Seeds``` dengan nama ```UsersSeeder.php``` atau kita bisa juga coba gunakan `spark` command di bawah ini untuk generate file seeder.

```bash
php spark make:seeder UsersSeeder
```

Output:

```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 12:02:42 UTC+00:00

File created: APPPATH/Database/Seeds/UsersSeeder.php

```



Selanjutnya kita sesuaikan baris kode berikut ini di dalam file seeder yang baru saja dibuat.

```php
<?php

namespace App\Database\Seeds;

class UsersSeeder extends \CodeIgniter\Database\Seeder
{
    public function run()
    {
        $faker = \Faker\Factory::create('id_ID');

        for ($i = 0; $i < 100; $i++) {
            $gender = $faker->randomElements(['male', 'female'])[0];

            $data = [
                'name' => $faker->firstName($gender),
                'email' => $faker->email,
                'password' => password_hash('1234567', PASSWORD_DEFAULT),
                'created_at' => date("Y-m-d H:i:s"),
            ];
            print_r($data);
            $this->db->table('users')->insert($data);
        }
    }
}


```

Save kembali file seeder ```UsersSeeder.php```.

Seperti yang bisa kita lihat di baris kode di atas. Nama filenya disesuaikan dengan nama class, yaitu ```UsersSeeder```. Class ```UsersSeeder```  ini kita jadikan turunan dari parent class ```\CodeIgniter\Database\Seeder```. 

Untuk generate dummy data, kita gunakan library Faker, yang sudah terinstall ketika kita install CodeIgniter. Sebagai contoh data yang kita generate ada 99 data. Dan untuk melakukan proses insert data, kita gunakan query builder.


## Step 6 - Run database seeder {#step-6-run-seeder}

Selanjutnya kita coba running seeder untuk generate dummy data. Buka kembali terminal, lalu eksekusi `spark` command:

```bash
php spark db:seed UsersSeeder
```

Setelah command di atas selesai dieksekusi, kita bisa lihat output seperti di bawah ini.

```bash
~/learning-lab/codeigniter/dbseeder-example$ php spark db:seed UsersSeeder
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 12:03:29 UTC+00:00

Array
(
    [name] => Dewi
    [email] => nramadan@gmail.com
    [password] => $2y$10$sO3MXVz44Iak5mwdv/bs3ulzPOWcIUMpokNbhdPXj5r6WtdM.0sH2
    [created_at] => 2024-05-08 12:03:30
)
Array
(
    [name] => Eka
    [email] => gilda70@halimah.tv
    [password] => $2y$10$LQbhagDX9j.N6SOL8DvALOXEPF8ai5lObOobM5jYvlhzuc3SjZYRC
    [created_at] => 2024-05-08 12:03:30
)


... dan output lainnya

```

Untuk memastikan apakah data nya berhasil di-generate dan berhasil disimpan di database, kita bisa buka phpmyadmin dan kita cek table `users`. Ya, datanya tersimpan sebanyak data yang sudah kita atur di file `UsersSeeder.php`.


## Kesimpulan {#kesimpulan}
Adakalanya kita perlu sample data pada saat testing web yang kita kembangkan maupun pada saat development. Data yang kita perlukan itu kadang tidak hanya lima baris data. Kadang bisa ratusan, kadang bisa ribuan. Kombinasi Database Seeding di CodeIgniter 4 dan library Faker ini memudahkan kita sebagai developer untuk generate dummy data yang bisa kita gunakan untuk keperluan development. 

Solusi ini sudah bermanfaat untukku. Kawan, semoga bermanfaat untukmu juga.

## Referensi {#referensi}

- [Dokumentasi tentang Database Seeder](https://codeigniter.com/user_guide/dbmgmt/seeds.html)
- [Repositori Library Faker](https://github.com/fzaninotto/Faker)
- Per tanggal 20 Desember 2022, library yang terinstall dari repositori [fakerphp/faker](https://github.com/FakerPHP/Faker)