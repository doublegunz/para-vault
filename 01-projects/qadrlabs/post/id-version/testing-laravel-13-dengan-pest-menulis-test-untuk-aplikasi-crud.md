---
title: "Testing Laravel 13 dengan Pest: Menulis Test untuk Aplikasi CRUD Anda"
slug: "testing-laravel-13-dengan-pest-menulis-test-untuk-aplikasi-crud"
original_title: "Laravel 13 Testing with Pest: Write Tests for Your CRUD Application"
original_slug: "laravel-13-testing-with-pest-write-tests-for-your-crud-application"
category: "Laravel"
date: "2026-03-24"
status: "draft"
---

Anda sudah membangun aplikasi CRUD yang berfungsi, dan semuanya terlihat baik-baik saja ketika Anda mengujinya secara manual di browser. Tapi apa yang terjadi ketika Anda menambahkan fitur baru minggu depan dan secara tidak sengaja merusak form create? Atau ketika rekan satu tim mengubah aturan validasi tanpa menyadari bahwa hal itu memengaruhi alur update? Tanpa automated test, Anda tidak akan menangkap regression semacam ini sampai ada pengguna yang melaporkannya.

Tutorial ini melanjutkan dari titik di mana [Laravel 13 CRUD Tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step) kita berakhir. Kita akan menulis feature test untuk setiap operasi CRUD dalam aplikasi blog menggunakan Pest, testing framework modern yang sudah disertakan secara default di Laravel 13.


## Overview {#overview}

Dalam tutorial ini, kita akan menulis automated test untuk aplikasi blog yang kita bangun di tutorial sebelumnya. Aplikasi ini memiliki model `Post` dengan field `title`, `slug`, `content`, dan `status`, yang dikelola melalui resource controller dengan fungsionalitas CRUD lengkap.

### What You'll Do

Anda akan menulis Pest feature test yang mencakup setiap operasi CRUD: menampilkan daftar post, membuat post baru, melihat satu post, mengedit post, dan menghapus post. Setiap test akan memverifikasi baik HTTP response maupun state database.

### What You'll Learn

Dengan mengikuti tutorial ini, Anda akan belajar cara:

- Mengganti PHPUnit dengan Pest di proyek Laravel 13 yang sudah ada.
- Membuat model factory untuk menghasilkan data test.
- Menulis feature test untuk setiap operasi CRUD.
- Menggunakan `RefreshDatabase` agar test tetap terisolasi.
- Melakukan assert pada HTTP response, redirect, session data, dan state database.
- Memvalidasi bahwa aturan validasi form bekerja dengan benar.
- Menjalankan dan menafsirkan hasil test Pest.

### What You'll Need

- Proyek blog yang sudah selesai dari [Laravel 13 CRUD Tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step).
- PHP 8.3 atau lebih tinggi.
- Familiaritas dasar dengan konsep Laravel dan testing.


## Step 1: Install Pest {#step-1-install-pest}

Proyek blog dari tutorial sebelumnya sudah disertai PHPUnit sebagai testing framework-nya. Kita perlu menggantinya dengan Pest. Buka `composer.json` dan Anda akan melihat PHPUnit terdaftar di dev dependencies:

```json
"require-dev": {
    "fakerphp/faker": "^1.23",
    "laravel/boost": "^2.3",
    "laravel/pail": "^1.2.5",
    "laravel/pint": "^1.27",
    "mockery/mockery": "^1.6",
    "nunomaduro/collision": "^8.6",
    "phpunit/phpunit": "^12.5.12"
},
```

Pertama, hapus PHPUnit, lalu install Pest beserta semua dependensinya:

```
composer remove phpunit/phpunit
composer require pestphp/pest --dev --with-all-dependencies
```

Flag `--with-all-dependencies` memberi tahu Composer untuk juga memperbarui paket-paket yang sudah ada yang perlu disesuaikan agar kompatibel dengan Pest.

Selanjutnya, inisialisasi Pest di proyek Anda:

```
./vendor/bin/pest --init
```

```
$ ./vendor/bin/pest --init
   INFO  Preparing tests directory.
  phpunit.xml ........................................... File already exists.  
  tests/Pest.php ............................................... File created.  
  tests/TestCase.php .................................... File already exists.  
  tests/Unit/ExampleTest.php ............................ File already exists.  
  tests/Feature/ExampleTest.php ......................... File already exists.  
```

Perintah `--init` membuat file `tests/Pest.php`, yang merupakan file konfigurasi Pest. File test yang sudah ada dan `phpunit.xml` dibiarkan tidak tersentuh karena keduanya sudah kompatibel.

### Verify the Test Database Configuration

Buka `phpunit.xml` dan periksa bagian environment variable. Pada proyek ini, database SQLite in-memory sudah dikonfigurasi secara default:

```xml
    <php>
        <env name="APP_ENV" value="testing"/>
        <env name="APP_MAINTENANCE_DRIVER" value="file"/>
        <env name="BCRYPT_ROUNDS" value="4"/>
        <env name="BROADCAST_CONNECTION" value="null"/>
        <env name="CACHE_STORE" value="array"/>
        <env name="DB_CONNECTION" value="sqlite"/>
        <env name="DB_DATABASE" value=":memory:"/>
        <env name="DB_URL" value=""/>
        <env name="MAIL_MAILER" value="array"/>
        <env name="QUEUE_CONNECTION" value="sync"/>
        <env name="SESSION_DRIVER" value="array"/>
        <env name="PULSE_ENABLED" value="false"/>
        <env name="TELESCOPE_ENABLED" value="false"/>
        <env name="NIGHTWATCH_ENABLED" value="false"/>
    </php>
```

`DB_CONNECTION` diatur ke `sqlite` dan `DB_DATABASE` diatur ke `:memory:`. Ini berarti test akan berjalan terhadap database SQLite in-memory yang fresh yang dibuat dan dihancurkan pada setiap kali test dijalankan, sehingga database development Anda sama sekali tidak tersentuh.

### Verify Pest Is Working

Jalankan Pest untuk memastikan semuanya sudah diatur dengan benar:

```
./vendor/bin/pest
```

```
$ ./vendor/bin/pest
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true
   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.09s  
  Tests:    2 passed (2 assertions)
  Duration: 0.13s
```

Kedua test default lolos. Pest sudah terinstal dan berfungsi. Anda juga bisa menjalankan test menggunakan `php artisan test`, yang secara internal memanggil Pest sekarang setelah PHPUnit diganti.


## Step 2: Create a Post Factory {#step-2-create-post-factory}

Test membutuhkan data sampel, dan model factory Laravel adalah cara standar untuk menghasilkannya. Buat factory untuk model `Post`:

```
php artisan make:factory PostFactory --model=Post
```

Buka `database/factories/PostFactory.php` dan definisikan default state-nya:

```php
<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Post>
 */
class PostFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $title = $this->faker->sentence();

        return [
            'title' => $title,
            'slug' => Str::slug($title),
            'content' => $this->faker->paragraphs(3, true),
            'status' => $this->faker->randomElement(['draft', 'publish']),
        ];
    }
}
```

Berikut adalah apa yang dihasilkan oleh masing-masing field:

- `title` menggunakan `sentence()` milik Faker untuk menghasilkan judul yang terlihat realistis seperti "The quick brown fox jumps over."
- `slug` mengubah judul yang dihasilkan menjadi format yang ramah URL menggunakan `Str::slug()`. Sebagai contoh, "The Quick Brown Fox" menjadi "the-quick-brown-fox".
- `content` menggunakan `paragraphs(3, true)` untuk menghasilkan tiga paragraf teks lorem ipsum yang digabungkan sebagai satu string tunggal. Parameter `true` mengembalikan sebuah string alih-alih sebuah array.
- `status` secara acak memilih antara "draft" atau "publish" dari nilai enum yang diizinkan.

Simpan file tersebut.


## Step 3: Write Tests for Listing Posts {#step-3-test-listing-posts}

Sekarang mari kita mulai menulis test yang sebenarnya. Buat file test baru:

```
php artisan make:test PostControllerTest --pest
```

Flag `--pest` menghasilkan file test bergaya Pest alih-alih class PHPUnit tradisional. Buka `tests/Feature/PostControllerTest.php` dan ganti isinya dengan:

```php
<?php

use App\Models\Post;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

test('index page displays a list of posts', function () {
    $posts = Post::factory()->count(3)->create();

    $response = $this->get(route('posts.index'));

    $response->assertStatus(200);
    $response->assertViewIs('posts.index');
    $response->assertViewHas('posts');

    foreach ($posts as $post) {
        $response->assertSee($post->title);
    }
});

test('index page shows empty state when no posts exist', function () {
    $response = $this->get(route('posts.index'));

    $response->assertStatus(200);
    $response->assertSee('No posts found.');
});
```

Mari kita uraikan strukturnya:

- `uses(RefreshDatabase::class)` ditempatkan di bagian atas file dan berlaku untuk setiap test dalam file ini. Ia menjalankan migration sebelum test pertama dan membungkus setiap test dalam sebuah database transaction yang di-rollback ketika test selesai. Ini memastikan setiap test dimulai dengan database yang bersih.
- `test('description', function () { ... })` adalah sintaks Pest untuk mendefinisikan sebuah test case. Argumen pertama adalah deskripsi yang mudah dibaca manusia yang muncul di output test.
- `Post::factory()->count(3)->create()` menggunakan factory yang kita buat di Step 2 untuk memasukkan tiga record post ke dalam database.
- `$this->get(route('posts.index'))` mengirim sebuah GET request ke route index post dan menangkap response-nya.
- `assertStatus(200)` memverifikasi HTTP status code.
- `assertViewIs('posts.index')` memastikan bahwa Blade view yang benar dikembalikan.
- `assertViewHas('posts')` memeriksa bahwa sebuah variabel `posts` diteruskan ke view.
- `assertSee($post->title)` memverifikasi bahwa setiap judul post muncul di suatu tempat dalam HTML yang dirender.

Test kedua memeriksa empty state: ketika tidak ada post di dalam database, halaman seharusnya menampilkan "No posts found." seperti yang kita definisikan di Blade view.

Simpan file tersebut.


## Step 4: Write Tests for Creating Posts {#step-4-test-creating-posts}

Tambahkan test berikut ke file yang sama:

```php
test('create page displays the form', function () {
    $response = $this->get(route('posts.create'));

    $response->assertStatus(200);
    $response->assertViewIs('posts.create');
    $response->assertSee('Create Post');
});

test('a new post can be stored', function () {
    $response = $this->post(route('posts.store'), [
        'title' => 'My First Blog Post',
        'content' => 'This is the content of my first blog post.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post created successfully.');

    $this->assertDatabaseHas('posts', [
        'title' => 'My First Blog Post',
        'slug' => 'my-first-blog-post',
        'content' => 'This is the content of my first blog post.',
        'status' => 'publish',
    ]);
});

test('slug is automatically generated from the title', function () {
    $this->post(route('posts.store'), [
        'title' => 'Laravel 13 Is Amazing',
        'content' => 'Some content here.',
        'status' => 'draft',
    ]);

    $this->assertDatabaseHas('posts', [
        'title' => 'Laravel 13 Is Amazing',
        'slug' => 'laravel-13-is-amazing',
    ]);
});

test('store validates required fields', function () {
    $response = $this->post(route('posts.store'), []);

    $response->assertSessionHasErrors(['title', 'content', 'status']);
});

test('store validates title max length', function () {
    $response = $this->post(route('posts.store'), [
        'title' => str_repeat('a', 256),
        'content' => 'Some content.',
        'status' => 'publish',
    ]);

    $response->assertSessionHasErrors(['title']);
});

test('store validates status must be draft or publish', function () {
    $response = $this->post(route('posts.store'), [
        'title' => 'Test Post',
        'content' => 'Some content.',
        'status' => 'archived',
    ]);

    $response->assertSessionHasErrors(['status']);
});

test('store validates slug uniqueness', function () {
    Post::factory()->create(['title' => 'Duplicate Title', 'slug' => 'duplicate-title']);

    $response = $this->post(route('posts.store'), [
        'title' => 'Duplicate Title',
        'content' => 'Different content.',
        'status' => 'draft',
    ]);

    $response->assertSessionHasErrors(['slug']);
});
```

Test-test ini mencakup baik happy path maupun edge case validasi:

- Test pertama memverifikasi bahwa halaman form create dimuat dengan benar.
- Test store mengirim sebuah POST request dengan data yang valid, lalu memeriksa tiga hal: response melakukan redirect ke halaman index, sebuah success flash message hadir di dalam session, dan data ada di dalam database dengan slug yang benar.
- Test slug secara khusus memverifikasi perilaku auto-generation. Kita mengirim "Laravel 13 Is Amazing" sebagai judul dan memastikan bahwa "laravel-13-is-amazing" disimpan sebagai slug.
- `assertSessionHasErrors(['title', 'content', 'status'])` memverifikasi bahwa error validasi dikembalikan ketika field yang wajib diisi tidak ada.
- Test max length mengirim judul yang lebih panjang dari 255 karakter dan mengharapkan sebuah error validasi.
- Test status mengirim nilai status yang tidak valid ("archived") dan mengharapkannya ditolak karena hanya "draft" dan "publish" yang diizinkan.
- Test uniqueness terlebih dahulu membuat sebuah post dengan slug tertentu, lalu mencoba membuat post lain dengan judul yang sama (dan karenanya slug yang sama) dan mengharapkan sebuah error validasi.


## Step 5: Write Tests for Viewing a Post {#step-5-test-viewing-post}

Tambahkan test berikut untuk memverifikasi halaman show:

```php
test('show page displays a single post', function () {
    $post = Post::factory()->create();

    $response = $this->get(route('posts.show', $post));

    $response->assertStatus(200);
    $response->assertViewIs('posts.show');
    $response->assertSee($post->title);
    $response->assertSee($post->content);
});

test('show returns 404 for non-existent post', function () {
    $response = $this->get(route('posts.show', 9999));

    $response->assertStatus(404);
});
```

Test pertama membuat sebuah post, meminta halaman detailnya, dan memverifikasi bahwa baik judul maupun content terlihat di dalam response. Test kedua meminta sebuah ID post yang tidak ada dan memastikan bahwa Laravel mengembalikan status code 404, yang ditangani secara otomatis oleh route model binding.


## Step 6: Write Tests for Updating Posts {#step-6-test-updating-posts}

Tambahkan test untuk form edit dan operasi update:

```php
test('edit page displays the form with existing data', function () {
    $post = Post::factory()->create();

    $response = $this->get(route('posts.edit', $post));

    $response->assertStatus(200);
    $response->assertViewIs('posts.edit');
    $response->assertSee($post->title);
    $response->assertSee($post->content);
});

test('a post can be updated', function () {
    $post = Post::factory()->create([
        'title' => 'Original Title',
        'slug' => 'original-title',
        'content' => 'Original content.',
        'status' => 'draft',
    ]);

    $response = $this->put(route('posts.update', $post), [
        'title' => 'Updated Title',
        'content' => 'Updated content.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post updated successfully.');

    $this->assertDatabaseHas('posts', [
        'id' => $post->id,
        'title' => 'Updated Title',
        'slug' => 'updated-title',
        'content' => 'Updated content.',
        'status' => 'publish',
    ]);
});

test('update validates required fields', function () {
    $post = Post::factory()->create();

    $response = $this->put(route('posts.update', $post), []);

    $response->assertSessionHasErrors(['title', 'content', 'status']);
});

test('update allows same slug for the same post', function () {
    $post = Post::factory()->create([
        'title' => 'Keep This Title',
        'slug' => 'keep-this-title',
    ]);

    $response = $this->put(route('posts.update', $post), [
        'title' => 'Keep This Title',
        'content' => 'Updated content only.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHasNoErrors();
});
```

Test update membuat sebuah post dengan nilai yang sudah diketahui, mengirim sebuah PUT request dengan data baru, dan memverifikasi bahwa database mencerminkan perubahan tersebut. Perhatikan bahwa kita juga melakukan assert pada `id` untuk memastikan record yang benar yang di-update.

Test terakhir sangat penting. Ia memverifikasi bahwa meng-update sebuah post tanpa mengubah judulnya tidak memicu error slug uniqueness. Ingat dari tutorial CRUD bahwa aturan validasi controller mencakup `unique:posts,slug,' . $post->id`, yang mengecualikan record saat ini dari pemeriksaan uniqueness. Test ini memastikan perilaku tersebut.


## Step 7: Write Tests for Deleting Posts {#step-7-test-deleting-posts}

Tambahkan test untuk operasi delete:

```php
test('a post can be deleted', function () {
    $post = Post::factory()->create();

    $response = $this->delete(route('posts.destroy', $post));

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post deleted successfully.');

    $this->assertDatabaseMissing('posts', [
        'id' => $post->id,
    ]);
});

test('deleting a non-existent post returns 404', function () {
    $response = $this->delete(route('posts.destroy', 9999));

    $response->assertStatus(404);
});
```

Test pertama membuat sebuah post, mengirim sebuah DELETE request, lalu memverifikasi tiga hal: response melakukan redirect ke halaman index, sebuah success message di-flash, dan record tidak lagi ada di dalam database. `assertDatabaseMissing` adalah lawan dari `assertDatabaseHas`, yang memastikan bahwa tidak ada row dengan ID yang diberikan.

Test kedua mencoba menghapus sebuah post yang tidak ada dan memverifikasi bahwa sebuah response 404 dikembalikan.


## Step 8: Run the Tests {#step-8-run-tests}

Dengan semua test sudah ditulis, mari kita jalankan. Buka terminal Anda dan eksekusi:

```
php artisan test
```

Anda seharusnya melihat output yang mirip dengan ini:

```
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response

   PASS  Tests\Feature\PostControllerTest
  ✓ index page displays a list of posts
  ✓ index page shows empty state when no posts exist
  ✓ create page displays the form
  ✓ a new post can be stored
  ✓ slug is automatically generated from the title
  ✓ store validates required fields
  ✓ store validates title max length
  ✓ store validates status must be draft or publish
  ✓ store validates slug uniqueness
  ✓ show page displays a single post
  ✓ show returns 404 for non-existent post
  ✓ edit page displays the form with existing data
  ✓ a post can be updated
  ✓ update validates required fields
  ✓ update allows same slug for the same post
  ✓ a post can be deleted
  ✓ deleting a non-existent post returns 404

  Tests:    19 passed
  Duration: 0.52s
```

Seluruh 19 test lolos. Berikut adalah apa yang sudah kita cakup:

- 2 test untuk halaman listing (dengan data dan empty state).
- 7 test untuk membuat post (tampilan form, store yang berhasil, slug generation, dan 4 skenario validasi).
- 2 test untuk melihat sebuah post (yang ada dan yang tidak ada).
- 4 test untuk meng-update post (tampilan form, update yang berhasil, validasi, dan edge case slug uniqueness).
- 2 test untuk menghapus post (delete yang berhasil dan post yang tidak ada).

Anda juga bisa menjalankan hanya file PostControllerTest:

```
php artisan test --filter=PostControllerTest
```

Atau menjalankan sebuah test tertentu berdasarkan nama:

```
php artisan test --filter="a new post can be stored"
```


## The Complete Test File {#complete-test-file}

Berikut adalah `tests/Feature/PostControllerTest.php` lengkap untuk referensi:

```php
<?php

use App\Models\Post;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

// Index Tests
test('index page displays a list of posts', function () {
    $posts = Post::factory()->count(3)->create();

    $response = $this->get(route('posts.index'));

    $response->assertStatus(200);
    $response->assertViewIs('posts.index');
    $response->assertViewHas('posts');

    foreach ($posts as $post) {
        $response->assertSee($post->title);
    }
});

test('index page shows empty state when no posts exist', function () {
    $response = $this->get(route('posts.index'));

    $response->assertStatus(200);
    $response->assertSee('No posts found.');
});

// Create Tests
test('create page displays the form', function () {
    $response = $this->get(route('posts.create'));

    $response->assertStatus(200);
    $response->assertViewIs('posts.create');
    $response->assertSee('Create Post');
});

test('a new post can be stored', function () {
    $response = $this->post(route('posts.store'), [
        'title' => 'My First Blog Post',
        'content' => 'This is the content of my first blog post.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post created successfully.');

    $this->assertDatabaseHas('posts', [
        'title' => 'My First Blog Post',
        'slug' => 'my-first-blog-post',
        'content' => 'This is the content of my first blog post.',
        'status' => 'publish',
    ]);
});

test('slug is automatically generated from the title', function () {
    $this->post(route('posts.store'), [
        'title' => 'Laravel 13 Is Amazing',
        'content' => 'Some content here.',
        'status' => 'draft',
    ]);

    $this->assertDatabaseHas('posts', [
        'title' => 'Laravel 13 Is Amazing',
        'slug' => 'laravel-13-is-amazing',
    ]);
});

test('store validates required fields', function () {
    $response = $this->post(route('posts.store'), []);

    $response->assertSessionHasErrors(['title', 'content', 'status']);
});

test('store validates title max length', function () {
    $response = $this->post(route('posts.store'), [
        'title' => str_repeat('a', 256),
        'content' => 'Some content.',
        'status' => 'publish',
    ]);

    $response->assertSessionHasErrors(['title']);
});

test('store validates status must be draft or publish', function () {
    $response = $this->post(route('posts.store'), [
        'title' => 'Test Post',
        'content' => 'Some content.',
        'status' => 'archived',
    ]);

    $response->assertSessionHasErrors(['status']);
});

test('store validates slug uniqueness', function () {
    Post::factory()->create(['title' => 'Duplicate Title', 'slug' => 'duplicate-title']);

    $response = $this->post(route('posts.store'), [
        'title' => 'Duplicate Title',
        'content' => 'Different content.',
        'status' => 'draft',
    ]);

    $response->assertSessionHasErrors(['slug']);
});

// Show Tests
test('show page displays a single post', function () {
    $post = Post::factory()->create();

    $response = $this->get(route('posts.show', $post));

    $response->assertStatus(200);
    $response->assertViewIs('posts.show');
    $response->assertSee($post->title);
    $response->assertSee($post->content);
});

test('show returns 404 for non-existent post', function () {
    $response = $this->get(route('posts.show', 9999));

    $response->assertStatus(404);
});

// Edit and Update Tests
test('edit page displays the form with existing data', function () {
    $post = Post::factory()->create();

    $response = $this->get(route('posts.edit', $post));

    $response->assertStatus(200);
    $response->assertViewIs('posts.edit');
    $response->assertSee($post->title);
    $response->assertSee($post->content);
});

test('a post can be updated', function () {
    $post = Post::factory()->create([
        'title' => 'Original Title',
        'slug' => 'original-title',
        'content' => 'Original content.',
        'status' => 'draft',
    ]);

    $response = $this->put(route('posts.update', $post), [
        'title' => 'Updated Title',
        'content' => 'Updated content.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post updated successfully.');

    $this->assertDatabaseHas('posts', [
        'id' => $post->id,
        'title' => 'Updated Title',
        'slug' => 'updated-title',
        'content' => 'Updated content.',
        'status' => 'publish',
    ]);
});

test('update validates required fields', function () {
    $post = Post::factory()->create();

    $response = $this->put(route('posts.update', $post), []);

    $response->assertSessionHasErrors(['title', 'content', 'status']);
});

test('update allows same slug for the same post', function () {
    $post = Post::factory()->create([
        'title' => 'Keep This Title',
        'slug' => 'keep-this-title',
    ]);

    $response = $this->put(route('posts.update', $post), [
        'title' => 'Keep This Title',
        'content' => 'Updated content only.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHasNoErrors();
});

// Delete Tests
test('a post can be deleted', function () {
    $post = Post::factory()->create();

    $response = $this->delete(route('posts.destroy', $post));

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post deleted successfully.');

    $this->assertDatabaseMissing('posts', [
        'id' => $post->id,
    ]);
});

test('deleting a non-existent post returns 404', function () {
    $response = $this->delete(route('posts.destroy', 9999));

    $response->assertStatus(404);
});
```


## Conclusion {#conclusion}

Dalam tutorial ini, kita menulis 19 feature test menggunakan Pest untuk mencakup setiap operasi CRUD dalam aplikasi blog Laravel 13 kita. Setiap test memverifikasi bukan hanya HTTP response, tetapi juga state database, session data, dan content view.

Berikut adalah poin-poin penting yang bisa diambil:

- **Sintaks Pest lebih bersih daripada PHPUnit.** Menulis `test('description', function () { ... })` lebih mudah dibaca daripada membuat method class dengan anotasi `/** @test */`. Deskripsi test terbaca seperti bahasa Inggris biasa.
- **`RefreshDatabase` menjaga test tetap terisolasi.** Setiap test dimulai dengan database yang bersih, sehingga urutan test dijalankan tidak menjadi masalah.
- **Model factory membuat data test menjadi mudah.** Dengan `Post::factory()->create()`, Anda menghasilkan data yang realistis dalam satu baris. Anda bisa meng-override field tertentu ketika Anda membutuhkan nilai yang presisi untuk assertion Anda.
- **Uji baik happy path maupun edge case.** Kita menguji bukan hanya bahwa data yang valid tersimpan dengan benar, tetapi juga bahwa data yang tidak valid ditolak oleh validasi. Ini menangkap bug sebelum mencapai production.
- **Slug uniqueness membutuhkan test khusus.** Edge case di mana meng-update sebuah post tanpa mengubah judulnya seharusnya tidak memicu error uniqueness mudah terlewatkan. Menulis test untuknya mendokumentasikan perilaku yang diharapkan dan mencegah regression.
- **Jalankan test secara berkala.** Biasakan menjalankan `php artisan test` setelah setiap perubahan. Semakin cepat feedback loop Anda, semakin mudah untuk melacak masalah.

Dari sini, Anda bisa memperluas test suite dengan skenario tambahan seperti menguji pagination, menguji bahwa draft post ditampilkan berbeda dari published post, atau menambahkan test autentikasi ketika Anda memperkenalkan fungsionalitas login.

Di tutorial berikutnya, kita akan [me-refactor Controller kita dengan Form Request Validation](https://qadrlabs.com/post/laravel-13-refactor-your-controller-with-form-request-validation).
