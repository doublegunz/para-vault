---
title: "Generate Model, Migration and Seeder from Existing Database"
slug: "generate-model-migration-and-seeder-from-existing-database"
category: "Laravel"
date: "2025-01-16"
status: "published"
---

## Introduction {#introduction}
Beberapa waktu yang lalu, kami di QadrLabs memutuskan untuk melakukan migrasi aplikasi dari CodeIgniter 3 ke Laravel. Keputusan ini diambil setelah mempertimbangkan beberapa faktor, terutama kebutuhan untuk memodernisasi aplikasi dan memanfaatkan fitur-fitur terbaru yang ditawarkan Laravel sebagai framework PHP modern.

Salah satu tantangan terbesar dalam proses migrasi adalah bagaimana cara memindahkan database yang sudah ada ke struktur Laravel tanpa kehilangan data dan meminimalisir downtime. Database yang kami miliki cukup kompleks dengan table dan records data yang perlu dipertahankan. Melakukan migrasi secara manual tentunya akan memakan waktu yang lama dan berisiko tinggi terjadi kesalahan.

Beruntungnya, ekosistem Laravel menyediakan beberapa package yang bisa membantu proses migrasi database. Package-package ini memungkinkan kita untuk menghasilkan Model, Migration File, dan Seeder File secara otomatis dari database yang sudah ada. Dengan cara ini, kita bisa memastikan tidak ada struktur database atau data yang tertinggal atau salah dalam proses migrasi.

Pada artikel ini, saya akan berbagi pengalaman bagaimana kami melakukan proses migrasi database tersebut. Untuk memudahkan pemahaman, kita akan menggunakan contoh sederhana dengan satu table, namun konsep dan langkah-langkah yang sama bisa diterapkan untuk database yang lebih kompleks. Mari kita mulai dengan melihat tools apa saja yang akan kita gunakan dan bagaimana cara menggunakannya.

## Overview {#overview}

Dalam proses migrasi aplikasi dari satu framework ke framework lain, salah satu tantangan utama adalah memindahkan struktur database beserta datanya. Laravel, sebagai framework yang modern, menyediakan fitur-fitur seperti Model, Migration, dan Seeder untuk mengelola database. Namun, ketika kita memiliki database yang sudah ada, kita perlu cara untuk mengkonversi struktur database tersebut ke dalam format yang sesuai dengan Laravel.

Pada tutorial ini, kita akan mempelajari cara menggunakan tiga package yang sangat membantu dalam proses migrasi database ke Laravel:

1. `reliese/laravel` - Package ini akan membantu kita menghasilkan Model Laravel secara otomatis berdasarkan struktur table yang sudah ada di database.

2. `kitloong/laravel-migrations-generator` - Package ini berguna untuk menghasilkan Migration File dari database yang sudah ada, sehingga struktur database bisa didokumentasikan dalam format Laravel Migration.

3. `orangehill/iseed` - Package ini akan membantu kita menghasilkan Seeder File yang berisi data-data yang sudah ada di database, berguna untuk keperluan development atau backup data.

Dengan menggunakan ketiga package tersebut, kita bisa menghemat waktu dan mengurangi kemungkinan kesalahan dalam proses migrasi database ke Laravel. Tutorial ini akan menunjukkan langkah demi langkah bagaimana menggunakan package-package tersebut menggunakan contoh kasus sederhana dengan sebuah table buku.

## Persiapan {#persiapan}

Sebagai simulasi dari real case project, kita akan membuat database yang akan kita gunakan untuk proses generate model, migration dan seeder. Untuk membuat database kita bisa pakai tools apapun dan sebagai contoh studi kasus kita buat database baru dengan nama `db_belajar`. 

Apabila sudah selesai buat database baru, selanjutnya kita buat sample table dengan nama `tbl_buku`. Untuk membuat table dan juga data dummy, run command sql berikut ini.

```jsx
 -- --------------------------------------------------------  

 --  
 -- Table structure for table `tbl_buku`  
 --  

 CREATE TABLE `tbl_buku` (  
  `id` int(8) NOT NULL AUTO_INCREMENT,  
  `judul` varchar(100) NOT NULL,  
  `penulis` varchar(30) NOT NULL,  
  `isbn` varchar(30) NOT NULL,  
  PRIMARY KEY (`id`)  
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;  

 --  
 -- Dumping data for table `tbl_buku`  
 --  

 INSERT INTO `tbl_buku` (`id`, `judul`, `penulis`, `isbn`) VALUES  
 (1, 'Learning PHP, MySQL & JavaScript', 'Robin Nixon', 'ISBN-13: 978-1491918661'),  
 (2, 'PHP and MySQL for Dynamic Web Sites', 'Larry Ullman', 'ISBN-13: 978-0321784070'),  
 (3, 'PHP Cookbook', 'David Sklar', 'ISBN-13: 978-1449363758'),  
 (4, 'Programming PHP', 'Kevin Tatroe', 'ISBN-13: 978-1449392772'),  
 (5, 'Modern PHP: New Features and Good Practices', 'Josh Lockhart', 'ISBN-13: 978-1491905012'),  
 (6, 'Modern PHP New Features and Good Practices', 'Josh Lockhart', 'ISBN-13: 978-1491905012'),  
 (7, 'Learning PHP MySQL & JavaScript', 'Robin Nixon', 'ISBN-13: 978-1491918661'),  
 (8, 'PHP and MySQL for Dynamic Web Sites', 'Larry Ullman', 'ISBN-13: 978-0321784070'),  
 (9, 'PHP Cookbook', 'David Sklar', 'ISBN-13: 978-1449363758'),  
 (10, 'Programming PHP', 'Kevin Tatroe', 'ISBN-13: 978-1449392772'),  
 (11, 'Modern PHP New Features and Good Practices', 'Josh Lockhart', 'ISBN-13: 978-1491905012'),  
 (12, 'Learning PHP MySQL & JavaScript', 'Robin Nixon', 'ISBN-13: 978-1491918661'),  
 (13, 'PHP and MySQL for Dynamic Web Sites', 'Larry Ullman', 'ISBN-13: 978-0321784070'),  
 (14, 'PHP Cookbook', 'David Sklar', 'ISBN-13: 978-1449363758'),  
 (15, 'Programming PHP', 'Kevin Tatroe', 'ISBN-13: 978-1449392772'),  
 (16, 'Modern PHP New Features and Good Practices', 'Josh Lockhart', 'ISBN-13: 978-1491905012'),  
 (17, 'Learning PHP MySQL & JavaScript', 'Robin Nixon', 'ISBN-13: 978-1491918661'),  
 (18, 'PHP and MySQL for Dynamic Web Sites', 'Larry Ullman', 'ISBN-13: 978-0321784070'),  
 (19, 'PHP Cookbook', 'David Sklar', 'ISBN-13: 978-1449363758'),  
 (20, 'Programming PHP', 'Kevin Tatroe', 'ISBN-13: 978-1449392772');  

```

Seperti yang sudah disampaikan sebelumnya sample table ini diambil dari tutorial codeigniter sebelumnya, jadi penamaan nama table dan juga field pada table tersebut masih belum sesuai best practice yang umum digunakan.



## Step 1: Create Laravel Project {#step-1-create-laravel-project}

Karena skenario kita adalah migrasi project ke project laravel, jadi di sini kita buat project laravel terlebih dahulu.

```
composer create-project --prefer-dist laravel/laravel sample-project
```

Tunggu sampai proses buat project selesai. 

Apabila proses buat project selesai, selanjutnya kita masuk ke direktori project.

```
cd sample-project
```

Lalu kita buka file `.env` dan kita sesuaikan konfigurasi database.

```jsx
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_belajar
DB_USERNAME=root
DB_PASSWORD=password
```

Pada konfigurasi database di atas, kita gunakan `db_belajar` yang sudah kita buat sebelumnya.



## Step 2: Generate Model File{#step-2-generate-model-file}

Sekarang kita akan install package untuk menangani proses generate model dari existing database, yaitu package `reliese/laravel`. Untuk install package, kita buka kembali terminal dan kita run command berikut ini untuk install package `reliese/laravel.

```jsx
composer require reliese/laravel --dev
```

Selanjutnya kita publish file konfigurasi package dan clear config

```jsx
php artisan vendor:publish --tag=reliese-models
```

Sebelum kita generate, kita clear config terlebih dahulu.

```
php artisan config:clear
```

Sekarang kita sudah bisa gunakan package untuk generate model sesuai dengan table yang ada pada database kita. Untuk memulai proses generate model, run command berikut ini.

```jsx
php artisan code:models
```

Setelah kita run command untuk generate model, kita bisa lihat ada file model yang telah kita generate, yaitu `app\Models\TblBuku.php`. Selanjutnya kita bisa  cek file model `app\Models\TblBuku.php`.

```jsx
<?php

/**
 * Created by Reliese Model.
 */

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Class TblBuku
 * 
 * @property int $id
 * @property string $judul
 * @property string $penulis
 * @property string $isbn
 *
 * @package App\Models
 */
class TblBuku extends Model
{
	protected $table = 'tbl_buku';
	public $timestamps = false;

	protected $fillable = [
		'judul',
		'penulis',
		'isbn'
	];
}

```

Dan bisa kita lihat file model `app\Models\TblBuku.php`, digenerate berdasarkan table yang sudah kita buat sebelumnya, yaitu table `tbl_buku`. Karena penamaan nama table belum sesuai best practice,  file hasil generate pun sesuai dengan nama tablenya.



## Step 3: Generate Migration File {#step-3-generate-migration-file}

Alasan kita generate migration file dari existing database adalah untuk menyesuaikan proses pembuatan table pada tahapan selanjutnya dengan cara mengubah proses manual pembuatan table langsung dari database menjadi menggunakan migration laravel. Apabila kita langsung membuat file migration tanpa generate terlebih dahulu, table yang ada di database boleh jadi tidak sengaja terhapus ketika kita tidak sengaja run `php artisan migrate:fresh`. Jadi ketika kita sudah generate migration file dari existing database, kita bisa membuat file migration seperti biasa.

 Sekarang kita install package untuk menangani proses generate migration file dari existing database, yaitu package `kitloong/laravel-migrations-generator`. Untuk install package `kitloong/laravel-migrations-generator`, buka terminal dan run command berikut ini.

```jsx
composer require --dev kitloong/laravel-migrations-generator
```

Selanjutnya kita bisa langsung gunakan command yang tersedia untuk generate file migration. Pada terminal, kita run command berikut ini untuk generate migration file dari existing database.

```jsx
php artisan migrate:generate
```

Selanjutnya apa terdapat prompt untuk menambakan log proses migration ke migration table, kita ketik `yes` lalu `enter`

```jsx
Using connection: mysql

Generating migrations for: tbl_buku

 Do you want to log these migrations in the migrations table? (yes/no) [yes]:
 > yes

```

Lalu selanjutnya tampil kembali prompt untuk menambahkan nomor batch, kita isi default `0`, lalu tekan `enter` untuk melanjutkan.

```
 Next Batch Number is: 1. We recommend using Batch Number 0 so that it becomes the "first" migration. [Default: 0] [0]:
 > 0
```

Output:

```
Setting up Tables and Index migrations.
Created: database/migrations/xxxx_xx_xx_xxxxxx_create_tbl_buku_table.php

Setting up Views migrations.

Setting up Stored Procedures migrations.

Setting up Foreign Key migrations.

Finished!
```

Seperti yang terlihat pada output yang ditampilkan di atas, terdapat file baru hasil generate, yaitu `database/migrations/xxxx_xx_xx_xxxxxx_create_tbl_buku_table.php`. Selanjutnya kita coba lihat isi file migration hasil generate `xxxx_xx_xx_xxxxxx_create_tbl_buku_table.php`

```jsx
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('tbl_buku', function (Blueprint $table) {
            $table->integer('id', true);
            $table->string('judul', 100);
            $table->string('penulis', 30);
            $table->string('isbn', 30);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_buku');
    }
};

```

Seperti yang terlihat, struktur table yang digenerate sesuai dengan command sql yang kita run pada saat kita buat table `tbl_buku`.



## Step 4: Generate Seeder File {#step-4-generate-seeder-file}

Untuk keperluan kedepannya, kita perlu seeder dari table yang kita generate. Oleh karena itu kita perlu install juga package yang menangani proses generate seeder dari existing database, yaitu package `orangehill/iseed`. Untuk install package tersebut, kita run command berikut ini.

```jsx
composer require orangehill/iseed
```

Setelah proses install selesai, kita bisa langsung generate seeder dari table yang tersedia. Pada studi kasus ini kita coba generate seeder untuk `tbl_buku`. Run command berikut ini untuk memulai proses generate.

```jsx
php artisan iseed tbl_buku
```

Output:

```jsx
$ php artisan iseed tbl_buku
Created a seed file from table tbl_buku
```

Selanjutnya kita bisa lihat ada file seeder baru hasil generate. Sebagai contoh di sini terdapat file  `database\seeders\TblBukuTableSeeder.php` ketika selesai run command di atas. Selanjutnya kita coba buka file `database\seeders\TblBukuTableSeeder.php` dan kita bisa lihat isi dari file tersebut.

```jsx
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class TblBukuTableSeeder extends Seeder
{

    /**
     * Auto generated seed file
     *
     * @return void
     */
    public function run()
    {
        

        \DB::table('tbl_buku')->delete();
        
        \DB::table('tbl_buku')->insert(array (
            0 => 
            array (
                'id' => 1,
                'judul' => 'Learning PHP, MySQL & JavaScript',
                'penulis' => 'Robin Nixon',
                'isbn' => 'ISBN-13: 978-1491918661',
            ),
            1 => 
            array (
                'id' => 2,
                'judul' => 'PHP and MySQL for Dynamic Web Sites',
                'penulis' => 'Larry Ullman',
                'isbn' => 'ISBN-13: 978-0321784070',
            ),
            2 => 
            array (
                'id' => 3,
                'judul' => 'PHP Cookbook',
                'penulis' => 'David Sklar',
                'isbn' => 'ISBN-13: 978-1449363758',
            ),
            3 => 
            array (
                'id' => 4,
                'judul' => 'Programming PHP',
                'penulis' => 'Kevin Tatroe',
                'isbn' => 'ISBN-13: 978-1449392772',
            ),
            4 => 
            array (
                'id' => 5,
                'judul' => 'Modern PHP: New Features and Good Practices',
                'penulis' => 'Josh Lockhart',
                'isbn' => 'ISBN-13: 978-1491905012',
            ),
            5 => 
            array (
                'id' => 6,
                'judul' => 'Modern PHP New Features and Good Practices',
                'penulis' => 'Josh Lockhart',
                'isbn' => 'ISBN-13: 978-1491905012',
            ),
            6 => 
            array (
                'id' => 7,
                'judul' => 'Learning PHP MySQL & JavaScript',
                'penulis' => 'Robin Nixon',
                'isbn' => 'ISBN-13: 978-1491918661',
            ),
            7 => 
            array (
                'id' => 8,
                'judul' => 'PHP and MySQL for Dynamic Web Sites',
                'penulis' => 'Larry Ullman',
                'isbn' => 'ISBN-13: 978-0321784070',
            ),
            8 => 
            array (
                'id' => 9,
                'judul' => 'PHP Cookbook',
                'penulis' => 'David Sklar',
                'isbn' => 'ISBN-13: 978-1449363758',
            ),
            9 => 
            array (
                'id' => 10,
                'judul' => 'Programming PHP',
                'penulis' => 'Kevin Tatroe',
                'isbn' => 'ISBN-13: 978-1449392772',
            ),
            10 => 
            array (
                'id' => 11,
                'judul' => 'Modern PHP New Features and Good Practices',
                'penulis' => 'Josh Lockhart',
                'isbn' => 'ISBN-13: 978-1491905012',
            ),
            11 => 
            array (
                'id' => 12,
                'judul' => 'Learning PHP MySQL & JavaScript',
                'penulis' => 'Robin Nixon',
                'isbn' => 'ISBN-13: 978-1491918661',
            ),
            12 => 
            array (
                'id' => 13,
                'judul' => 'PHP and MySQL for Dynamic Web Sites',
                'penulis' => 'Larry Ullman',
                'isbn' => 'ISBN-13: 978-0321784070',
            ),
            13 => 
            array (
                'id' => 14,
                'judul' => 'PHP Cookbook',
                'penulis' => 'David Sklar',
                'isbn' => 'ISBN-13: 978-1449363758',
            ),
            14 => 
            array (
                'id' => 15,
                'judul' => 'Programming PHP',
                'penulis' => 'Kevin Tatroe',
                'isbn' => 'ISBN-13: 978-1449392772',
            ),
            15 => 
            array (
                'id' => 16,
                'judul' => 'Modern PHP New Features and Good Practices',
                'penulis' => 'Josh Lockhart',
                'isbn' => 'ISBN-13: 978-1491905012',
            ),
            16 => 
            array (
                'id' => 17,
                'judul' => 'Learning PHP MySQL & JavaScript',
                'penulis' => 'Robin Nixon',
                'isbn' => 'ISBN-13: 978-1491918661',
            ),
            17 => 
            array (
                'id' => 18,
                'judul' => 'PHP and MySQL for Dynamic Web Sites',
                'penulis' => 'Larry Ullman',
                'isbn' => 'ISBN-13: 978-0321784070',
            ),
            18 => 
            array (
                'id' => 19,
                'judul' => 'PHP Cookbook',
                'penulis' => 'David Sklar',
                'isbn' => 'ISBN-13: 978-1449363758',
            ),
            19 => 
            array (
                'id' => 20,
                'judul' => 'Programming PHP',
                'penulis' => 'Kevin Tatroe',
                'isbn' => 'ISBN-13: 978-1449392772',
            ),
        ));
        
        
    }
}
```

Seperti yang terlihat, pada  `database\seeders\TblBukuTableSeeder.php` terdapat proses insert data yang sesuai dengan data yang sudah kita tambahkan ketika kita run command sql untuk membuat table `tbl_buku`.



## Penutup {#penutup}

Pada tutorial kali ini, kita telah mempelajari cara melakukan migrasi database dari aplikasi yang sudah ada (dalam hal ini Codeigniter 3) ke Laravel dengan memanfaatkan beberapa package yang memudahkan proses migrasi. Package-package tersebut membantu kita dalam menghasilkan Model, Migration File, dan Seeder secara otomatis dari struktur database yang sudah ada.

Dengan menggunakan `reliese/laravel`, kita bisa menghasilkan Model yang sesuai dengan struktur table yang ada. Kemudian dengan `kitloong/laravel-migrations-generator`, kita bisa membuat Migration File yang akan memudahkan kita dalam proses development selanjutnya karena struktur database sudah terdokumentasi dalam bentuk Migration File. Terakhir, kita menggunakan `orangehill/iseed` untuk menghasilkan Seeder File yang berisi data-data yang sudah ada di database.

Meskipun dalam contoh kasus kita menggunakan table dengan penamaan yang belum sesuai best practice, package-package tersebut tetap bisa menghandle proses generate dengan baik. Untuk pengembangan selanjutnya, kita bisa melakukan refactor terhadap hasil generate tersebut agar sesuai dengan konvensi dan best practice di Laravel.

Proses migrasi dari framework lama ke Laravel memang bukan hal yang mudah, namun dengan memanfaatkan tools yang tepat, kita bisa mempersingkat waktu development dan mengurangi kemungkinan kesalahan dalam proses migrasi tersebut.

## Referensi

- [GitHub - reliese/laravel: Reliese Laravel Model Generator](https://github.com/reliese/laravel)
- [GitHub - kitloong/laravel-migrations-generator: Laravel Migrations Generator: Automatically generate your migrations from an existing database schema.](https://github.com/kitloong/laravel-migrations-generator)
- [GitHub - orangehill/iseed: Laravel Inverse Seed Generator](https://github.com/orangehill/iseed)