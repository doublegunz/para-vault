---
title: "Testing Menggunakan Pest"
slug: "testing-menggunakan-pest"
category: "Laravel"
date: "2024-12-29"
status: "published"
---

## Introduction{#introduction}

Testing merupakan bagian penting dalam pengembangan aplikasi untuk memastikan bahwa setiap fitur berjalan sesuai dengan yang diharapkan. Di ekosistem Laravel, kita memiliki beberapa pilihan framework testing, dan salah satu yang populer adalah Pest PHP.

Tutorial ini akan memandu Anda dalam mengimplementasikan automated testing menggunakan Pest di aplikasi Laravel 11. Kita akan fokus pada pengujian fitur CRUD (Create, Read, Update, Delete) yang merupakan operasi dasar yang sering digunakan dalam pengembangan aplikasi web.

Melalui tutorial ini, Anda akan belajar bagaimana menulis test yang efektif dan mudah dipahami menggunakan sintaks Pest yang elegan. Testing yang baik akan membantu Anda mendeteksi bug lebih awal, meningkatkan kualitas kode, dan memberikan kepercayaan diri saat melakukan perubahan pada aplikasi.

## Apa itu Pest?{#apa-itu-pest}

Pest adalah framework testing modern untuk PHP yang dibangun di atas PHPUnit. Framework ini dikembangkan oleh Nuno Maduro dan telah mendapatkan popularitas yang signifikan di komunitas Laravel karena beberapa keunggulannya:

1. **Sintaks yang Ekspresif**: Pest menawarkan sintaks yang lebih sederhana dan mudah dibaca dibandingkan PHPUnit tradisional. Contohnya:

   ```php
   test('user can be created', function () {
       // test logic here
   });
   ```

2. **Kompatibilitas dengan PHPUnit**: Meskipun memiliki sintaks yang berbeda, Pest sepenuhnya kompatibel dengan PHPUnit. Ini berarti kita dapat menggunakan semua fitur PHPUnit yang sudah familiar.

3. **Higher Order Testing**: Pest mendukung higher order testing yang memungkinkan kita menulis test dengan lebih ringkas dan ekspresif:

   ```php
   it('can create user')->expect(User::count())->toBe(1);
   ```

4. **Dataset Testing**: Memudahkan pengujian dengan berbagai skenario data menggunakan fitur dataset:

   ```php
   it('validates email format')->with([
       'invalid-email',
       'another-invalid-email'
   ]);
   ```

5. **IDE Support**: Pest memiliki dukungan IDE yang baik, termasuk autocompletion dan type hinting, yang membantu dalam proses development.

Dengan menggunakan Pest, kita dapat menulis test yang lebih bersih, lebih mudah dipahami, dan lebih mudah dipelihara. Framework ini sangat cocok untuk pengembangan aplikasi Laravel modern yang membutuhkan test suite yang robust dan mudah dikelola.



## Overview{#overview}

Tutorial ini akan membahas implementasi testing menggunakan Pest PHP di aplikasi Laravel 11. Pest adalah framework testing yang dibangun di atas PHPUnit dengan sintaks yang lebih sederhana dan ekspresif, membuatnya lebih mudah dibaca dan dipelihara.

### Apa yang akan dipelajari:

- Instalasi dan konfigurasi Pest di project Laravel 11
- Migrasi dari PHPUnit ke Pest menggunakan `pest-plugin-drift`
- Studi kasus penulisan test case untuk fitur CRUD menggunakan sintaks Pest
- Eksekusi dan verifikasi hasil testing

### Goals Tutorial:

1. Memahami perbedaan antara PHPUnit dan Pest testing framework
2. Mampu mengimplementasikan automated testing menggunakan Pest di aplikasi Laravel
3. Menguasai penulisan test case untuk operasi CRUD dasar
4. Memastikan fungsionalitas aplikasi berjalan sesuai dengan yang diharapkan melalui automated testing

### Prasyarat:

- Sudah memiliki project Laravel 11 dengan fitur CRUD user dari [Tutorial Laravel 11: Development Sample Aplikasi CRUD](https://qadrlabs.com/post/percobaan-development-crud-app-sederhana-menggunakan-laravel-11)
- Pemahaman dasar tentang Laravel framework
- Pemahaman dasar tentang konsep software testing

Di akhir tutorial ini, anda akan memiliki suite testing yang komprehensif untuk memvalidasi fungsionalitas CRUD di aplikasi Laravel anda menggunakan Pest framework.

## Persiapan Studi Kasus {#persiapan}

Pada studi kasus testing menggunakan Pest ini kita akan gunakan sample project dari [Tutorial Laravel 11: Development Sample Aplikasi CRUD](https://qadrlabs.com/post/percobaan-development-crud-app-sederhana-menggunakan-laravel-11). Untuk bisa mengikuti tutorial ini, silakan teman-teman selesaikan terlebih dahulu project di tutorial tersebut. Sebagai alternatif teman-teman dapat clone sample project dari [repositori project crud laravel 11](https://github.com/qadrLabs/crud-laravel-11), lalu ikuti langkah-langkah setup project yang ada di `README`.

## Step 1: Install dan Setup Pest {#step-1-install-pest-package}

Pada tahapan ini kita akan install dan setup `Pest`. Pertama kita masuk terlebih dahulu ke direktori project menggunakan command `cd nama-direktori-project`, setelah itu kita hapus terlebih dahulu package `phpunit`.

```
composer remove phpunit/phpunit
```

Apabila tampil prompt untuk menghapus package dari `require-dev` seperti di bawah ini, tekan `enter` untuk melanjutkan.

```
$ composer remove phpunit/phpunit
phpunit/phpunit could not be found in require but it is present in require-dev
Do you want to remove it from require-dev [yes]? 
```

Setelah itu kita install package `pest`.

```
composer require pestphp/pest --dev --with-all-dependencies
```

Tunggu sampai proses install `pest` selesai.

Setelah proses install selesai kita perlu inisialisasi Pest di project kita. Tahapan ini akan membuat file konfigurasi dengan nama `Pest.php`. Untuk memulai inisialisasi Pest, run command berikut ini.

```
./vendor/bin/pest --init
```

Output:

```
   INFO  Preparing tests directory.

  phpunit.xml ........................................... File already exists.  
  tests/Pest.php ............................................... File created.  
  tests/TestCase.php .................................... File already exists.  
  tests/Unit/ExampleTest.php ............................ File already exists.  
  tests/Feature/ExampleTest.php ......................... File already exists. 
```

Sekarang kita bisa coba run test dengan menggunakan `pest` command

```
./vendor/bin/pest
```

Output yang ditampilkan:

```
$ ./vendor/bin/pest

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.10s  

  Tests:    2 passed (2 assertions)
  Duration: 0.16s

```



## Step 2: Migrasi dari PHPUnit ke Pest{#step-2-migrasi-dari-phpunit-ke-pest}

Apabila kita buka file `tests/Feature/ExampleTest.php` atau `tests/Unit/ExampleTest.php`, kita bisa lihat kode yang ada masih menggunakan kode untuk test menggunakan `phpunit`. Testing masih bisa kita gunakan karena `pest` dikembangkan di atas `phpunit`. Kita bisa migrasi kode testing yang kita gunakan phpunit ke pest. 

Sekarang kita buka file `tests/Feature/ExampleTest.php` dan kita bisa lihat baris kode berikut ini.

```php
<?php

namespace Tests\Feature;

// use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    /**
     * A basic test example.
     */
    public function test_the_application_returns_a_successful_response(): void
    {
        $response = $this->get('/');

        $response->assertStatus(200);
    }
}

```

Sekarang kita akan coba sesuaikan kode untuk testing menggunakan pest. Untuk migrasi kode, kita install terlebih dahulu package yang dapat menangani proses migrasi.

```
composer require pestphp/pest-plugin-drift --dev
```

Selanjutnya kita konversi kode yang sebelumnya kita gunakan untuk testing menggunakan phpunit menjadi kode untuk pest.

```
./vendor/bin/pest --drift
```

Output yang ditampilkan:

```
$ ./vendor/bin/pest --drift

  ✔✔

   INFO  The [tests] directory has been migrated to PEST with 2 files changed.

```

Sekarang kita buka kembali file `tests/Feature/ExampleTest.php` dan kita bisa lihat baris kode pada file tersebut sudah sesuai dengan sintaks yang digunakan untuk testing menggunakan `pest`.

```php
<?php

test('the application returns a successful response', function () {
    $response = $this->get('/');

    $response->assertStatus(200);
});

```

Dan berikut ini isi dari file `tests/Unit/ExampleTest.php`.

```
<?php

test('that true is true', function () {
    expect(true)->toBeTrue();
});
```

Selanjutnya kita bisa run test kembali menggunakan command berikut ini.

```
/vendor/bin/pest
```

Output yang ditampilkan

```
$ ./vendor/bin/pest

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.10s  

  Tests:    2 passed (2 assertions)
  Duration: 0.16s

```

## Step 3: Membuat testing untuk fitur CRUD {#step-3-membuat-testing-untuk-fitur-crud}

Pada tahapan ini kita akan coba untuk membuat testing untuk fitur CRUD yang sebelumnya sudah coding di tutorial laravel 11 sebelumnya. Kita buka kembali terminal lalu kita generate testing untuk fitur crud.

```
php artisan make:test ManagePostTest
```

Output yang ditampilkan:

```
$ php artisan make:test ManagePostTest

   INFO  Test [tests/Feature/ManagePostTest.php] created successfully.
```

Selanjutnya kita buka file `tests/Feature/ManagePostTest.php` dan kita bisa lihat kode default generate sudah sesuai dengan sintaks yang digunakan untuk test menggunakan `pest`.

```php
<?php

test('example', function () {
    $response = $this->get('/');

    $response->assertStatus(200);
});

```

Kita hapus isi file `tests/Feature/ManagePostTest.php`, lalu kita tambahkan test fitur crud.

```php
<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;

uses(RefreshDatabase::class);

it('can display the user index page', function () {
    User::factory(10)->create();

    $response = $this->get(route('user.index'));

    $response->assertStatus(200);
    $response->assertViewIs('users.index');
    $response->assertViewHas('users');
});

it('can display the create user form', function () {
    $response = $this->get(route('user.create'));

    $response->assertStatus(200);
    $response->assertViewIs('users.create');
});

it('can store a new user', function () {
    $data = [
        'name' => 'John Doe',
        'email' => 'john.doe@example.com',
        'password' => 'password123',
        'password_confirmation' => 'password123',
    ];

    $response = $this->post(route('user.store'), $data);

    $response->assertRedirect(route('user.index'));
    $response->assertSessionHas('message', 'New user created successfully');

    $this->assertDatabaseHas('users', [
        'email' => 'john.doe@example.com',
    ]);
});

it('can display the edit user form', function () {
    $user = User::factory()->create();

    $response = $this->get(route('user.edit', $user));

    $response->assertStatus(200);
    $response->assertViewIs('users.edit');
    $response->assertViewHas('user', $user);
});

it('can update a user', function () {
    $user = User::factory()->create();

    $data = [
        'name' => 'Updated Name',
        'email' => 'updated.email@example.com',
        'password' => '',
    ];

    $response = $this->put(route('user.update', $user), $data);

    $response->assertRedirect(route('user.index'));
    $response->assertSessionHas('message', 'User updated successfully');

    $this->assertDatabaseHas('users', [
        'id' => $user->id,
        'name' => 'Updated Name',
        'email' => 'updated.email@example.com',
    ]);
});

it('can delete a user', function () {
    $user = User::factory()->create();

    $response = $this->delete(route('user.destroy', $user));

    $response->assertRedirect(route('user.index'));
    $response->assertSessionHas('message', 'User deleted successfully');

    $this->assertDatabaseMissing('users', [
        'id' => $user->id,
    ]);
});

```

Save kembali file `tests/Feature/ManagePostTest.php`.

Kode ini menguji seluruh fitur CRUD user yang sudah kita coding di tutorial laravel sebelumnya, termasuk:

1. **Menampilkan halaman index.**
2. **Menampilkan form tambah dan edit user.**
3. **Menyimpan data user baru.**
4. **Memperbarui data user.**
5. **Menghapus data user.**

## Step 4: Run testing fitur CRUD {#step-4-run-testing-fitur-crud}

Untuk run testing fitur crud, kita buka kembali terminal lalu run command berikut ini.

```
./vendor/bin/pest
```

Output yang ditampilkan:

```
$ ./vendor/bin/pest

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.10s  

   PASS  Tests\Feature\ManagePostTest
  ✓ it can display the user index page                                   0.19s  
  ✓ it can display the create user form                                  0.02s  
  ✓ it can store a new user                                              0.03s  
  ✓ it can display the edit user form                                    0.02s  
  ✓ it can update a user                                                 0.02s  
  ✓ it can delete a user                                                 0.02s  

  Tests:    8 passed (22 assertions)
  Duration: 0.47s

```

Seperti yang terlihat pada output yang ditampilkan, kita berhasil menambahkan testing untuk masing-masing fitur CRUD.

## Penutup {#penutup}

Dalam tutorial ini, kita telah mempelajari langkah-langkah implementasi testing menggunakan Pest di aplikasi Laravel 11. Tutorial ini mencakup beberapa tahapan penting:

1. Persiapan environment dengan menginstall package Pest dan menghapus PHPUnit
2. Proses migrasi dari PHPUnit ke Pest menggunakan pest-plugin-drift
3. Implementasi testing untuk fitur CRUD user yang mencakup pengujian untuk:
   - Menampilkan halaman index
   - Menampilkan form create dan edit
   - Menyimpan data user baru
   - Mengupdate data user
   - Menghapus data user

Dari hasil testing yang dijalankan, semua test berhasil dieksekusi dengan total 8 test passed dan 22 assertions. Ini menunjukkan bahwa fitur CRUD yang diimplementasikan berfungsi sesuai dengan yang diharapkan.

Pest menawarkan sintaks yang lebih sederhana dan mudah dibaca dibandingkan PHPUnit, sambil tetap mempertahankan fungsionalitas testing yang powerful. Dengan menggunakan Pest, developer dapat menulis dan mengelola test case dengan lebih efisien sambil memastikan kualitas kode aplikasi Laravel mereka.