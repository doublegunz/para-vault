---
title: "Belajar Laravel 8: Testing CRUD Feature"
slug: "belajar-laravel-8-testing-crud-feature"
category: "Laravel"
date: "2021-12-30"
status: "published"
---

Halo, pada postingan ini kita akan belajar bagaimana cara melakukan testing di aplikasi yang dibangun menggunakan framework laravel. Berbeda dengan testing yang sering kita coba dan terapkan di tutorial-tutorial sebelumnya, testing yang akan kita coba itu bukan testing manual, melainkan menggunakan package phpunit dan Laravel BrowserKit Testing.

Kenapa tiba-tiba ingin pakai phpunit dan bukan testing secara manual? Ya, ada ceritanya saya mencoba menggunakan phpunit ini. Saya cerita dikita ya... Beberapa waktu yang lalu, alhamdulillah saya menerima job untuk maintenance project yang sudah running di production. Selain maintenance, client meminta saya untuk melakukan penambahan fitur juga. Setelah melakukan proses analisis dan desain, coding dan sampai pada proses testing. Biasanya untuk proses testing ini saya lakukan secara manual. Saya tulis dulu fitur apa saja yang mau saya testing, lalu saya coba fitur itu satu per satu. Sekali lagi, saya coba satu per satu. Kalau satu fitur masih bisa saya coba, kalau banyak gimana? Masih bisa juga, tetapi setelah selesai testing, eh ternyata sudah habis beberapa hari. Dan setelah testing pun, kadang kepikiran, gimana kalau user begini, gimana kalau user input begitu, eh tadi ada yang kelewat testing nya ga ya, dan lain-lain. Di sini saya perlu pendekatan berbeda untuk proses testing dan kalau bisa diotomatiskan. Setelah googling dan baca-baca mengenai testing, banyak yang membahas tentang penggunaan `phpunit` dan `Laravel BrowserKit Testing`.

[PHPUnit](https://phpunit.de/) adalah sebuah framework testing untuk PHP dan merupakan sebuah instance dari xUnit architecture untuk unit testing framework. Dengan menggunakan PHPUnit ini kita bisa melakukan pengujian dengan cara menuliskan skenario pengujian dalam bentuk kode. Jadi yang tadi awalnya testing secara manual, nanti bisa melakukan testing dengan bantuan PHPUnit ini. Setiap kali terpikir skenario untuk testing, nanti bisa dituangkan langsung dalam bentuk kode.

Setelah baca-baca bagian dokumentasinya, phpunit ini bisa kita [install melalui composer](https://phpunit.readthedocs.io/en/9.5/installation.html#composer).
```
composer require --dev phpunit/phpunit ^9
```

Untuk yang sudah terbiasa menggunakan laravel, phpunit ini sudah terintegrasi secara default dengan laravel. Kita bisa cek di file `composer.json` dan kita bisa lihat ada package phpunit.
```
    "require-dev": {
        "facade/ignition": "^2.5",
        "fakerphp/faker": "^1.9.1",
        "laravel/sail": "^1.0.1",
        "mockery/mockery": "^1.4.2",
        "nunomaduro/collision": "^5.0",
        "phpunit/phpunit": "^9.3.3"
    },
```

Setelah *googling* tentang phpunit ini, saya coba terapkan di aplikasi CRUD sederhana hasil dari tutorial [Belajar Laravel 8 edisi sebelumnya](https://qadrlabs.com/post/belajar-laravel-8-membuat-aplikasi-crud-sederhana). Biasanya uji coba tutorial itu saya tuliskan manual, kini saya coba gunakan phpunit untuk testing. Berikut ini tahapan yang saya coba saat melakukan testing fitur CRUD yang ada di aplikasi.
- Step 1: Setup.
- Step 2: Buat Class Testing dan definisikan fitur testing.
- Step 3: Test fitur create new post.
- Step 4: Test fitur browse halaman daftar post.
- Step 5: Test fitur update post.
- Step 6: Test fitur delete post.


## Overview {#overview}
Tutorial ini membahas cara melakukan testing otomatis pada aplikasi Laravel menggunakan PHPUnit dan Laravel BrowserKit Testing. Berbeda dengan testing manual yang sering dilakukan, pendekatan ini memungkinkan pengembang menuliskan skenario pengujian dalam bentuk kode, sehingga proses testing menjadi lebih efisien dan dapat diotomatiskan. Tutorial ini mencakup langkah-langkah praktis untuk menguji fitur CRUD (Create, Read, Update, Delete) pada aplikasi Laravel 8, mulai dari setup awal hingga implementasi skenario pengujian untuk setiap fitur. Dengan menggunakan PHPUnit, pengembang dapat menghemat waktu, mengurangi kesalahan manual, dan memastikan aplikasi berjalan sesuai spesifikasi yang direncanakan. Selain itu, tutorial ini juga memberikan wawasan tentang manfaat automated testing serta ruang lingkup pengembangan lebih lanjut, seperti penerapan Test-Driven Development (TDD).

### Apa yang akan dipelajari
Dalam tutorial ini, kita akan mempelajari:
1. **Dasar-dasar Automated Testing**: Memahami konsep dasar automated testing menggunakan PHPUnit dan Laravel BrowserKit Testing.
2. **Setup Lingkungan Testing**: Cara mengonfigurasi lingkungan testing, termasuk pengaturan database SQLite untuk keperluan testing.
3. **Membuat Skenario Testing**: Menulis skenario pengujian untuk fitur CRUD dalam bentuk kode.
4. **Implementasi Testing**: Langkah-langkah praktis untuk menguji fitur Create, Read, Update, dan Delete pada aplikasi Laravel.
5. **Analisis Hasil Testing**: Memahami output dari PHPUnit dan cara mengidentifikasi kesalahan atau kegagalan dalam testing.

### Goal Tutorial
Tujuan utama dari tutorial ini adalah:
1. **Mengotomatiskan Proses Testing**: Mengurangi ketergantungan pada testing manual dengan menerapkan automated testing menggunakan PHPUnit.
2. **Memastikan Kualitas Aplikasi**: Memastikan bahwa aplikasi CRUD sederhana yang dibangun menggunakan Laravel 8 berfungsi sesuai dengan spesifikasi yang direncanakan.
3. **Meningkatkan Efisiensi Pengembangan**: Menghemat waktu dan usaha dengan menulis skenario testing sekali dan menjalankannya secara otomatis setiap kali diperlukan.
4. **Menyiapkan Dasar untuk TDD**: Memberikan pemahaman dasar tentang automated testing sebagai langkah awal menuju penerapan Test-Driven Development (TDD) di proyek-proyek mendatang.

Dengan mengikuti tutorial ini, kita diharapkan dapat mengimplementasikan automated testing pada aplikasi Laravel kita, sehingga meningkatkan kualitas kode dan efisiensi dalam pengembangan perangkat lunak.

## Prasyarat{#Prasyarat}
Seperti yang sudah disebutkan sebelumnya, aplikasi yang saya coba testing di tutorial ini adalah hasil belajar laravel 8 edisi sebelumnya tentang membuat aplikasi CRUD sederhana. Oleh karena itu untuk mengikuti tutorial ini, teman-teman boleh selesaikan terlebih dahulu [project aplikasi CRUD sederhana di tutorial sebelumnya](https://qadrlabs.com/post/belajar-laravel-8-membuat-aplikasi-crud-sederhana). Setelah project selesai, kita bisa langsung mulai langkah berikutnya

## Step 1: Setup{#step-1}
Baik, sebelum memulai persiapan, instalasi package tambahan yang diperlukan, dan rangkaian test lainnya, kita coba run dulu phpunit yang sebelumnya sudah tersedia di dalam framework laravel. Buka terminal, lalu kita run phpunit.
```
vendor/bin/phpunit
```

Kita bisa lihat output seperti berikut ini di terminal:
```
PHPUnit 9.5.11 by Sebastian Bergmann and contributors.

..                                                                  2 / 2 (100%)

Time: 00:00.063, Memory: 20.00 MB

OK (2 tests, 2 assertions)


```

Dari output di atas, kita bisa lihat ada dua tests yang sudah disediakan secara default ketika laravel diinstall dan hasilnya itu ok, tanda sudah sesuai. Ada dua file testing yang berhasil ditest, yaitu `tests/Feature/ExampleTest.php` dan `tests/Unit/ExampleTest.php` dan kalau kita buka di dalamnya masing-masing terdapat method untuk testing yaitu `test_example()`. Jadi `OK (2 tests, 2 assertions)` di atas merujuk ke kedua method `test_example()` yang ada di dua file tersebut.

Selanjutnya kita edit pengaturan phpunit. Buka file `phpunit.xml` di texteditor. Lalu temukan baris kode berikut ini.
```
    <php>
        <server name="APP_ENV" value="testing"/>
        <server name="BCRYPT_ROUNDS" value="4"/>
        <server name="CACHE_DRIVER" value="array"/>
        <!-- <server name="DB_CONNECTION" value="sqlite"/> -->
        <!-- <server name="DB_DATABASE" value=":memory:"/> -->
        <server name="MAIL_MAILER" value="array"/>
        <server name="QUEUE_CONNECTION" value="sync"/>
        <server name="SESSION_DRIVER" value="array"/>
        <server name="TELESCOPE_ENABLED" value="false"/>
    </php>
```

Studi kasus kita kali ini adalah melakukan testing untuk fitur CRUD, jadi kita perlu atur terlebih dahulu database yang akan kita gunakan. Di sini kita akan coba memakai sqlite sebagai database untuk keperluan testing. Kita hapus tanda komentar untuk `DB_CONNECTION` dan `DB_DATABASE` . Sehingga pengaturannya menjadi seperti berikut ini:
```
    <php>
        <server name="APP_ENV" value="testing"/>
        <server name="BCRYPT_ROUNDS" value="4"/>
        <server name="CACHE_DRIVER" value="array"/>
        <server name="DB_CONNECTION" value="sqlite"/>
        <server name="DB_DATABASE" value=":memory:"/>
        <server name="MAIL_MAILER" value="array"/>
        <server name="QUEUE_CONNECTION" value="sync"/>
        <server name="SESSION_DRIVER" value="array"/>
        <server name="TELESCOPE_ENABLED" value="false"/>
    </php>
```

Selanjutnya kita install package `laravel BrowserKit Testing` sebagai package tambahan.
```
composer require laravel/browser-kit-testing:^6.4 --dev -W
```

> **Keterangan**
> Pada saat tutorial ini ditulis, versi package yang digunakan adalah versi 6.4. Jadi supaya tutorial masih relevan, proses install package disesuaikan.



Kita tunggu sampai proses install package selesai.



Selanjutnya buka file `tests/TestCase.php`. Di file ini, kita modifikasi `TestCase` Class untuk extend ke `Laravel\BrowserKitTesting\TestCase`, yang awalnya extends ke `Illuminate\Foundation\Testing\TestCase`. Selain itu kita tambahkan juga atribut `$baseUrl`.
```
<?php

namespace Tests;

use Laravel\BrowserKitTesting\TestCase as BaseTestCase; // ubah class parent

abstract class TestCase extends BaseTestCase
{
    use CreatesApplication;

    public $baseUrl = 'http://localhost'; // tambah $baseUrl
}

```

Sampai tahapan ini kita sudah bisa melakukan testing. Kita coba test menggunakan contoh sederhana. Buka file `tests/Feature/ExampleTest.php`, lalu selanjutnya kita modifikasi dan definisikan `test_example()` method di dalam `ExampleTest` class menjadi seperti baris kode berikut ini.
```php
<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    /**
     * A basic test example.
     *
     * @return void
     */
    public function test_example()
    {
        $this->visit('/')
             ->see('Laravel')
             ->dontSee('Rails');

    }
}

```

Setelah itu kita run kembali phpunit.
```
vendor/bin/phpunit
```

Kurang lebih outputnya seperti berikut ini.
```
PHPUnit 9.5.11 by Sebastian Bergmann and contributors.

..                                                                  2 / 2 (100%)

Time: 00:00.072, Memory: 22.00 MB

OK (2 tests, 4 assertions)

```

Bisa kita lihat, proses testing untuk contoh nya berjalan dengan baik dan tidak ada error. Jadi ketika proses testing, `visit` method akan melakukan `GET` request ke aplikasi, lalu selanjutnya `see` method menegaskan kita bisa lihat tulisan `Laravel` ketika membuka halaman awal dan `dontSee` method menegaskan tidak ada tulisan `Rails` ketika membuka halaman tersebut. 

Kalau menguji coba secara manual, ketika aplikasi kita run dan kita buka halaman awal di browser, kita bisa melihat tulisan `Laravel` di halaman awal dan tidak ada tulisan `Rails`.

Untuk melihat testing yang hasilnya gagal, teman-teman bisa coba ubah tulisan `Laravel` di parameter method `see()`, lalu coba run kembali phpunitnya.

## Step 2: buat class testing dan definisikan feature yang akan di-testing{#step-2}
Untuk melakukan test fitur CRUD manajemen post, kita akan coba buat class khusus untuk handle proses test. Katakanlah nama class-nya itu `ManagePostsTest`, di dalamnya kita definisikan fitur yang akan kita test menggunakan `phpunit`.

Baik, kita buat dulu class-nya menggunakan `artisan command` berikut ini.
```
php artisan make:test ManagePostsTest
```

Selanjutnya buka class `tests/Feature/ManagePostsTest.php`, lalu kita tambahkan beberapa method untuk mendefinisikan fitur crud yang akan ditest.
```
<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

class ManagePostsTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function user_can_create_a_post()
    {
        $this->assertTrue(true);
    }

    /** @test */
    public function user_can_browse_posts_index_page()
    {
        $this->assertTrue(true);
    }

    /** @test */
    public function user_can_edit_existing_post()
    {
        $this->assertTrue(true);
    }

    /** @test */
    public function user_can_delete_existing_post()
    {
        $this->assertTrue(true);
    }
}
```

Ya, nama method untuk testing panjang-panjang dan sebisa mungkin deskriptif sesuai dengan proses testing-nya. Jadi ketika ada hasil yang gagal atau fail nanti merujuk langsung ke method testing yang bersangkutan.

Selanjutnya kita coba test menggunakan `phpunit`. Kita run kembali command ini.
```
vendor/bin/phpunit
```

Kurang lebih output yang ditampilkan di terminal seperti ini.
```
PHPUnit 9.5.11 by Sebastian Bergmann and contributors.

......                                                              6 / 6 (100%)

Time: 00:00.120, Memory: 26.00 MB

OK (6 tests, 8 assertions)
```

Ya, terdapat 6 test, 8 assertions dan hasil testnya sukses. Kita perhatikan lagi sample testing-nya terdapat function `asertTrue()`. Function `assertTrue()` ini mengecek apakah parameter bernilai true. Teman-teman boleh coba tulis ` $this->assertTrue(false);`, lalu coba run phpunit untuk melihat hasil yang berbeda.

## Step 3: test create new post{#step-3}
Kita akan melakukan test untuk fitur yang pertama, yaitu membuat post baru. Skenario untuk alur test fitur membuat post baru:
1. User buka halaman buat post baru.
2. User isi `title`, `status` dan `content`, lalu klik tombol `Save`.
3. Lihat apakah data post berhasil masuk ke database.
4. Web dialihkan ke halaman daftar post.
5. Di halaman daftar post, user bisa lihat tulisan `title` yang disimpan dan juga status publish.

Buka kembali file class `tests/Feature/ManagePostsTest.php`, lalu kita modifikasi `user_can_create_a_post()` dan kita sesuaikan dengan alur test fitur membuat post baru.

```
<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

class ManagePostsTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function user_can_create_a_post()
    {
        // user buka halaman buat post baru
        $this->visit('/post/create');

        // user isi `title`, publish status dan content,
        // lalu klik tombol save
        $this->submitForm('Save', [
            'title' => 'Belajar Laravel 8 at qadrLabs',
            'status' => 1, // publish
            'content' => 'Ini adalah content tutorial belajar laravel 8 di qadrLabs'
        ]);

        // lihat data post di database
        $this->seeInDatabase('posts', [
            'title' => 'Belajar Laravel 8 at qadrLabs',
            'status' => 1,
            'content' => 'Ini adalah content tutorial belajar laravel 8 di qadrLabs'
        ]);

        // ter-redirect ke halaman daftar post
        $this->seePageIs('/post');

        // lihat post yang sudah diinput
        $this->see('Belajar Laravel 8 at qadrLabs'); // ini titlenya
        $this->see('Publish'); // ini statusnya


    }
    
    // ... baris kode lainnya
}

```

Bisa kita lihat pada baris kode di atas, proses testingnya kita sesuaikan dengan alur test-nya. Apakah hasil testnya sukses? Kita coba run kembali `phpunit` nya. Buka kembali terminal lalu kita run `phpunit`.
```
vendor/bin/phpunit
```

Dan hasil output nya adalah:
```
PHPUnit 9.5.11 by Sebastian Bergmann and contributors.

......                                                              6 / 6 (100%)

Time: 00:00.144, Memory: 28.00 MB

OK (6 tests, 15 assertions)
```

Ya, hasil testnya sukses.

Misalkan untuk penasaran kalau hasil testnya failed atau gagal itu seperti apa. Kita bisa coba edit di bagian `submitForm()` dan `seeInDatabase`. Misalkan di `submitForm()` kita tulis masih seperti di contoh.
```
        $this->submitForm('Save', [
            'title' => 'Belajar Laravel 8 at qadrLabs',
            'status' => 1, // publish
            'content' => 'Ini adalah content tutorial belajar laravel 8 di qadrLabs'
        ]);
```

Lalu di method `seeInDatabase` kita tulis seperti ini
```
        $this->seeInDatabase('posts', [
            'title' => 'Belajar CodeIgniter 4 at qadrLabs',
            'status' => 1,
            'content' => 'Ini adalah content tutorial belajar CodeIgniter 4 di qadrLabs'
        ]);
```

Ketika kita run `phpunit` nanti tampil output seperti ini:
```
PHPUnit 9.5.11 by Sebastian Bergmann and contributors.

..F...                                                              6 / 6 (100%)

Time: 00:00.136, Memory: 28.00 MB

There was 1 failure:

1) Tests\Feature\ManagePostsTest::user_can_create_a_post
Unable to find row in database table [posts] that matched attributes [{"title":"Belajar CodeIgniter 4 at qadrLabs","status":1,"content":"Ini adalah content tutorial belajar CodeIgniter 4 di qadrLabs"}].
Failed asserting that 0 is greater than 0.

/direktori-laravel/testing-2/vendor/laravel/browser-kit-testing/src/Concerns/InteractsWithDatabase.php:24
/direktori-laravel/testing-2/tests/Feature/ManagePostsTest.php:30

FAILURES!
Tests: 6, Assertions: 22, Failures: 1.
```

Ya, tampil error `Unable to find row in database table [posts] ....`, karena data yang disubmit dan data yang dicari di database itu beda. Selain itu perhatikan juga ada petunjuk yang mengarah ke baris kodenya, yaitu `direktori-laravel-kamu/tests/Feature/ManagePostsTest.php:30`. 

**Note**: Misalkan ada error sewaktu kita nulis kode testing, kita perbaiki kode errornya, lalu run kembali phpunit, dan begitu seterusnya sampai hasilnya itu sukses.

## Step 4: test browse post index page{#step-4}
Fitur berikutnya yang akan kita test adalah browse post index page atau membuka halaman daftar post. Skenario alur untuk testnya kita definisikan seperti ini:
1. Generate 2 sample post 
2. User membuka halaman daftar post
3. User dapat melihat judul dari post yang sebelumnya sudah di-generate.

Kita buka lagi file `tests/Feature/ManagePostsTest.php`, lalu kita modifikasi `user_can_browse_posts_index_page()` method dan kita sesuaikan dengan skenario alur untuk testing.

```
<?php

namespace Tests\Feature;

use App\Models\Post; // tambahkan statement `use`
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

class ManagePostsTest extends TestCase
{
    // .. baris kode lainnya

    /** @test */
    public function user_can_browse_posts_index_page()
    {
        // generate 2 record baru di table `posts`
        $postOne = Post::create([
            'title' => 'Belajar Laravel 8 at qadrLabs edisi 1',
            'content' => 'ini adalah tutorial belajar laravel 8 edisi 1',
            'status' => 1, // publish
            'slug' => 'belajar-laravel-8-edisi-1'
        ]);

        $postTwo = Post::create([
            'title' => 'Belajar Laravel 8 at qadrLabs edisi 2',
            'content' => 'ini adalah tutorial belajar laravel 8 edisi 2',
            'status' => 1, // publish
            'slug' => 'belajar-laravel-8-edisi-2'
        ]);

        // user membuka halaman daftar post
        $this->visit('/post');

        // user melihat dua title dari data post
        $this->see('Belajar Laravel 8 at qadrLabs edisi 1');
        $this->see('Belajar Laravel 8 at qadrLabs edisi 2');

    }

    // ... baris kode lainnya
}

```

Karena kita menambahkan post baru, jangan lupa tambahkan statement `use` untuk import model `Posts`.

```
use App\Models\Post; // tambahkan statement `use`
```

Selanjutnya kita coba run testing.
```
vendor/bin/phpunit
```

Dan kita bisa lihat output-nya kurang lebih seperti di bawah ini.
```
PHPUnit 9.5.11 by Sebastian Bergmann and contributors.

......                                                              6 / 6 (100%)

Time: 00:00.134, Memory: 28.00 MB

OK (6 tests, 17 assertions)

```

## Step 5: test update existing post{#step-5}
Selanjutnya kita test proses update data post dan skenario alur testingnya seperti ini.
1. Generate 1 data post yang akan kita edit.
2. User buka halaman daftar post.
3. User membuka halaman edit post.
4. Ketika masuk halaman edit post, lihat url apakah sesuai dengan url edit post.
5. Di halaman edit post terdapat form untuk edit post dengan action mengarahkan route edit post berdasarkan id.
6. user isi data post yang diperbaharui, lalu klik tombol `Update`.
7. Terdapat perubahan di table `posts`.
8. Halaman web dialihkan ke halaman daftar post.

Selanjutnya kita sesuaikan isi `user_can_edit_existing_post()` method dengan skenario di atas.

```php
<?php

namespace Tests\Feature;

use App\Models\Post;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

class ManagePostsTest extends TestCase
{
    // ... baris kode lainnya

    /** @test */
    public function user_can_edit_existing_post()
    {
        // generate 1 data post
        $post = Post::create([
            'title' => 'Belajar Laravel 8',
            'content' => 'ini content belajar laravel 8',
            'status' => 1, // publish
            'slug' => 'belajar-laravel-8'
        ]);

        // user buka halaman daftar post
        $this->visit('/post');

        // user click tombol edit post
        $this->visit("post/{$post->id}/edit");

        // lihat url yang dituju sesuai dengan post yang diedit
        $this->seePageIs("post/{$post->id}/edit");

        // tampil form edit post
        $this->seeElement('form', [
            'action' => url('post/' . $post->id)
        ]);

        // user submit data post yang diupdate
        $this->submitForm('Update', [
            'title' => 'belajar laravel 8 [update]'
        ]);

        // check perubahan data di table post
        $this->seeInDatabase('posts', [
            'id' => $post->id,
            'title' => 'belajar laravel 8 [update]'
        ]);

        // lihat halaman web yang ter-redirect
        $this->seePageIs('/post');
    }

    // ... baris kode lainnya
}

```

Setelah selesai kita ketik baris kode di atas, kita run kembali testing menggunakan `phpunit`.
```
vendor/bin/phpunit
```

Dan outputnya adalah sebagai berikut:
```
PHPUnit 9.5.11 by Sebastian Bergmann and contributors.

......                                                              6 / 6 (100%)

Time: 00:00.145, Memory: 28.00 MB

OK (6 tests, 26 assertions)

```
Hasilnya sesuai dengan skenario yang sebelumnya kita definisikan.

## Step 6: test delete existing data{#step-6}
Fitur terakhir yang akan kita test adalah fitur delete data post. Skenario alur testingnya kita definisikan seperti di bawah ini.
1. Generate 1 sample data post.
2. Mengirimkan post request untuk menghapus data berdasarkan id
3. Check apakah datanya ada di table `posts`.

Selanjutnya kita sesuaikan isi `user_can_delete_existing_post()` method menjadi seperti baris kode berikut ini.

```php
<?php

namespace Tests\Feature;

use App\Models\Post;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

class ManagePostsTest extends TestCase
{
    // ... baris kode lainnya

    /** @test */
    public function user_can_delete_existing_post()
    {
        // generate 1 post data
        $post = Post::create([
            'title' => 'Belajar Laravel 8',
            'content' => 'ini content belajar laravel 8',
            'status' => 1, // publish
            'slug' => 'belajar-laravel-8'
        ]);

        // post delete request
        $this->post('/post/' . $post->id, [
            '_method' => 'DELETE'
        ]);

        // check data di table post
        $this->dontSeeInDatabase('posts', [
            'id' => $post->id
        ]);
    }
}

```

Setelah selesai, kita run kembali `phpunit`:
```
vendor/bin/phpunit
```

Dan outputnya adalah seperti di bawah ini:
```
PHPUnit 9.5.11 by Sebastian Bergmann and contributors.

......                                                              6 / 6 (100%)

Time: 00:00.152, Memory: 28.00 MB

OK (6 tests, 26 assertions)

```
Ya, ada 6 test, 26 assertions dan hasilnya OK atau sukses.

## Penutup{#penutup}
Setelah mencoba menggunakan phpunit untuk proses testing ini ada satu hal yang yang menjadi pembeda dengan testing manual, yaitu kita perlu coding script untuk testing. Tampak seperti kerja dua kali, karena harus menuliskan kode untuk testing setelah aplikasinya jadi. Tapi tampaknya ini sepadan dengan manfaat yang dirasakan. Ada beberapa catatan setelah menggunakan phpunit untuk testing.
1. Kita tidak perlu melakukan testing manual dan berulang. Apabila ada skenario untuk testing, kita bisa menuliskan langsung dalam bentuk kode.
2. Kita bisa mendapatkan hasil testing langsung ketika aplikasi tidak sesuai dengan spesifikasi yang sudah direncanakan.
3. Aplikasi crud sederhana hasil dari belajar laravel 8 sebelumnya ternyata masih bisa ditingkatkan supaya bisa testing sesuai skenario. Misalkan untuk edit data, kita bisa tambahkan skenario user klik link edit, di sini kita belum bisa terapkan karena link edit-nya tidak memiliki id unik. Selain itu kita juga bisa menambahkan skenario untuk fitur delete, misalnya ada tambahan skenario user menekan tombol delete sesuai dengan id-nya.

## Selanjutnya Gimana?{#next}
Ada beberapa hal yang bisa kita tingkatkan untuk aplikasi CRUD sederhana hasil belajar laravel 8 edisi sebelumnya supaya lebih test-able, dengan menambahkan skenario seperti kita menguji coba dengan membuka aplikasinya langsung di browser, misalkan ada proses klik link untuk edit data, ada proses klik button untuk delete dan lain-lain. Kita bisa juga menambahkan testing untuk validasi ketika proses menambahkan data ataupun memperbaharui data post.

Selain itu ada beberapa hal yang bisa kita pelajari lebih lanjut, misalnya best practice untuk testing ini seperti apa, tentang Test Drivent Development (TDD) atau tentang automated testing yang (mungkin) akan dibahas di postingan selanjutnya. 

Demikian catatan saya ketika belajar testing untuk aplikasi yang dibangun menggunakan framework Laravel 8. Semoga bermanfaat.