---
title: "Testing Laravel dengan PHPUnit"
slug: "testing-laravel-dengan-phpunit"
category: "Laravel"
date: "2025-01-26"
status: "published"
---

## Introduction{#introduction}  
Testing adalah komponen kritis dalam pengembangan aplikasi Laravel untuk memastikan fungsionalitas berjalan sesuai ekspektasi. Laravel secara default menyediakan PHPUnit sebagai framework testing utama. Meskipun Pest semakin populer, PHPUnit tetap menjadi pilihan utama bagi banyak developer karena kematangan dan integrasinya yang kuat dengan ekosistem PHP.  

Artikel ini akan membahas implementasi automated testing menggunakan PHPUnit di Laravel 11 dengan studi kasus yang sama seperti [tutorial Pest sebelumnya](https://qadrlabs.com/post/testing-menggunakan-pest). Tujuannya adalah memberikan perbandingan langsung antara PHPUnit dan Pest dalam hal sintaks, kemudahan penggunaan, dan fitur.  

## Apa itu PHPUnit?{#apa-itu-phpunit}  
PHPUnit adalah *framework* **unit testing** paling populer untuk bahasa pemrograman PHP. Dikembangkan oleh Sebastian Bergmann, PHPUnit menjadi standar *de facto* untuk pengujian perangkat lunak di ekosistem PHP, termasuk Laravel.  

Beberapa karakteristik utamanya:  
1. **Sintaks Berbasis Class**: PHPUnit menggunakan pendekatan berbasis class dan method dengan annotations seperti `@test` atau prefix `test`.  
   ```php
   class ExampleTest extends TestCase {
       /** @test */
       public function user_can_be_created() {
           // Test logic
       }
   }
   ```  

2. **Assertions Kaya Fitur**: Menyediakan banyak method assertions untuk validasi hasil testing.  
   ```php
   $this->assertEquals(1, User::count());
   ```  

3. **Kompatibilitas dengan Laravel**: Terintegrasi penuh dengan fitur Laravel seperti database testing dan HTTP requests.  

4. **Dukungan Komunitas Luas**: Dokumentasi lengkap dan komunitas yang aktif.  

5. **Kustomisasi Tinggi**: Mendukung ekstensi melalui plugin dan configuration XML.  

Meskipun powerful, PHPUnit sering dianggap lebih verbose dibanding Pest, terutama untuk test case sederhana.  

## Overview{#overview}  
Tutorial ini akan mengimplementasikan testing fitur CRUD di Laravel 11 menggunakan PHPUnit. Fokus utama:  

### Yang Akan Dipelajari:  
- Konfigurasi PHPUnit di Laravel 11  
- Penulisan test case untuk operasi CRUD  
- Eksekusi dan interpretasi hasil testing  

### Goals Tutorial:  
1. Memahami struktur testing dengan PHPUnit  
2. Membandingkan sintaks PHPUnit vs. Pest  
3. Menguasai teknik testing CRUD dasar  

### Prasyarat:  
- Project Laravel 11 dengan fitur CRUD user dari [tutorial sebelumnya](https://qadrlabs.com/post/percobaan-development-crud-app-sederhana-menggunakan-laravel-11)  
- PHPUnit terinstall (default di Laravel)  

## Persiapan Studi Kasus {#persiapan}  
Gunakan project yang sama seperti tutorial Pest, yaitu sample project CRUD. Sample project dapat diakses di [repositori](https://github.com/qadrLabs/crud-laravel-11), lalu ikuti langkah-langkah setup yang ada di `README`. Setelah setup selesai, pastikan fitur CRUD user sudah berjalan.  

## Step 1: Konfigurasi PHPUnit{#step-1-konfigurasi-phpunit}  
Laravel 11 sudah menyertakan PHPUnit secara default. Untuk memverifikasi, buka `phpunit.xml` di root project. Jika ingin menambahkan dependencies, jalankan:  
```bash
composer require --dev phpunit/phpunit  
```  

## Step 2: Membuat Test CRUD dengan PHPUnit{#step-2-membuat-test-crud}  
Buat test class untuk fitur CRUD:  
```bash
php artisan make:test ManageUserTest  
```  
Output:
```
➜  crud-laravel-11 git:(main) php artisan make:test ManageUserTest

   INFO  Test [tests/Feature/ManageUserTest.php] created successfully.
```

Buka `tests/Feature/ManageUserTest.php` dan isi dengan kode berikut:  

```php
<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ManageUserTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function can_display_user_index_page()
    {
        User::factory(10)->create();

        $response = $this->get(route('user.index'));

        $response->assertStatus(200);
        $response->assertViewIs('users.index');
        $response->assertViewHas('users');
    }

    /** @test */
    public function can_display_create_user_form()
    {
        $response = $this->get(route('user.create'));

        $response->assertStatus(200);
        $response->assertViewIs('users.create');
    }

    /** @test */
    public function can_store_new_user()
    {
        $data = [
            'name' => 'John Doe',
            'email' => 'john.doe@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ];

        $response = $this->post(route('user.store'), $data);

        $response->assertRedirect(route('user.index'));
        $response->assertSessionHas('message', 'New user created successfully');

        $this->assertDatabaseHas('users', ['email' => 'john.doe@example.com']);
    }

    /** @test */
    public function can_display_edit_user_form()
    {
        $user = User::factory()->create();

        $response = $this->get(route('user.edit', $user));

        $response->assertStatus(200);
        $response->assertViewIs('users.edit');
        $response->assertViewHas('user', $user);
    }

    /** @test */
    public function can_update_user()
    {
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
    }

    /** @test */
    public function can_delete_user()
    {
        $user = User::factory()->create();

        $response = $this->delete(route('user.destroy', $user));

        $response->assertRedirect(route('user.index'));
        $response->assertSessionHas('message', 'User deleted successfully');

        $this->assertDatabaseMissing('users', ['id' => $user->id]);
    }
}
```  

---

## Step 3: Menjalankan Test{#step-3-run-test}  
Eksekusi test dengan perintah:  
```bash
./vendor/bin/phpunit  
```  

Hasil yang diharapkan:  
```
➜  crud-laravel-11 git:(testing-with-phpunit) ✗ ./vendor/bin/phpunit
PHPUnit 10.5.41 by Sebastian Bergmann and contributors.

Runtime:       PHP 8.2.18
Configuration: /Users/gungunpriatna/learning-lab/laravel/crud-laravel-11/phpunit.xml

........                                                            8 / 8 (100%)

Time: 00:00.370, Memory: 42.50 MB

OK (8 tests, 22 assertions)
```  

Seperti yang terlihat testing berjalan dengan baik dan terdapat 8 test serta 22 assertions. Untuk bisa melihat detail testing yang dieksekusi, sebagai alternatif kita bisa run testing menggunakan command berikut ini.
```
php artisan test
```
Output yang ditampilkan:
```
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.11s

   PASS  Tests\Feature\ManageUserTest
  ✓ can display user index page                                          0.08s
  ✓ can display create user form                                         0.01s
  ✓ can store new user                                                   0.03s
  ✓ can display edit user form                                           0.02s
  ✓ can update user                                                      0.02s
  ✓ can delete user                                                      0.02s

  Tests:    8 passed (22 assertions)
  Duration: 0.34s
```
Pada output yang ditampilkan, kita bisa lihat testing sesuai dengan yang kita tulis di file `tests/Feature/ManageUserTest.php`.

## Perbandingan PHPUnit vs. Pest{#perbandingan}  
Berikut perbedaan utama antara PHPUnit dan Pest berdasarkan studi kasus ini:  

<table class="table table-bordered table-striped">
<thead>
<tr>
<th><strong>Aspek</strong></th>
<th><strong>PHPUnit</strong></th>
<th><strong>Pest</strong></th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>Sintaks</strong></td>
<td>Berbasis class dan method dengan annotations</td>
<td>Sintaks fungsional dengan closure dan <code>test()</code></td>
</tr>
<tr>
<td><strong>Readability</strong></td>
<td>Lebih verbose</td>
<td>Lebih ringkas dan ekspresif</td>
</tr>
<tr>
<td><strong>Dataset Testing</strong></td>
<td>Menggunakan <code>@dataProvider</code></td>
<td>Fitur <code>with()</code> bawaan</td>
</tr>
<tr>
<td><strong>Assertions</strong></td>
<td><code>$this-&gt;assert...</code></td>
<td><code>expect()-&gt;toBe...</code></td>
</tr>
<tr>
<td><strong>Eksekusi Test</strong></td>
<td><code>./vendor/bin/phpunit</code></td>
<td><code>./vendor/bin/pest</code></td>
</tr>
<tr>
<td><strong>Learning Curve</strong></td>
<td>Lebih curam karena struktur class</td>
<td>Lebih mudah untuk pemula</td>
</tr>
<tr>
<td><strong>Fitur Tambahan</strong></td>
<td>Plugin eksternal diperlukan</td>
<td>Higher-order testing dan integrasi plugin mudah</td>
</tr>
</tbody>
</table>


## Penutup{#penutup}  
PHPUnit tetap menjadi pilihan solid untuk testing di Laravel, terutama untuk proyek besar yang membutuhkan kontrol penuh dan kustomisasi. Namun, Pest menawarkan pengalaman yang lebih modern dengan sintaks yang lebih intuitif.  

**Kapan Memilih PHPUnit?**  
- Proyek dengan tim terbiasa menggunakan PHPUnit  
- Membutuhkan integrasi dengan tools legacy  
- Kebutuhan kustomisasi ekstensif  

**Kapan Memilih Pest?**  
- Proyek baru dengan fokus developer experience  
- Menginginkan penulisan test yang lebih cepat  
- Fitur seperti dataset dan higher-order testing dibutuhkan  

Kedua framework memiliki keunggulannya masing-masing. Pemilihan akhir tergantung pada kebutuhan tim dan kompleksitas proyek.