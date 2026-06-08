---
title: "Membangun RESTful API menggunakan CodeIgniter 4"
slug: "membangun-restful-api-menggunakan-codeigniter-4"
category: "CodeIgniter 4"
date: "2021-01-10"
status: "published"
---

Beberapa waktu lalu saya mengisi pelatihan pengembangan aplikasi menggunakan android. Pada pelatihan tersebut, terdapat kebutuhan untuk menggunakan backend untuk mengelola data dari aplikasi yang dikembangkan. Karena fokusnya adalah untuk mengembangkan aplikasi android, jadi kita coba gunakan firebase sebagai backend. Di sesi tanya jawab ada peserta yang bertanya, "A kalau kita mau bikin sendiri backend-nya gimana?". Ini pertanyaan menarik. Untuk menjawab pertanyaan ini, saya coba bereskperimen untuk  **membangun RESTful API menggunakan CodeIgniter 4** sebagai backend-nya. Alasan menggunakan framework CodeIgniter ini karena peserta yang ikut pelatihan kebanyakan terbiasa menggunakan CodeIgniter. Ya, sesederhana itu alasannya.

Sewaktu coba-coba membuat RESTFul API, saya mencoba mengembangkan menggunakan dua versi CodeIgniter yang berbeda, CodeIgniter 3 dan CodeIgniter 4. Setelah mencoba beberapa kali development menggunakan versi berbeda, saya memutuskan untuk rilis tutorial RESTFul API untuk CodeIgniter 4. Untuk versi 3, mungkin saya coba tulis di lain waktu. Dan untuk framework yang berbeda, di postingan sebelumnya saya sudah sempat membahas tentang pengembangan RESTFul API dengan framework yang berbeda.

> [Baca: [TUTORIAL MEMBUAT RESTFUL API MENGGUNAKAN API PLATFORM](https://qadrlabs.com/post/tutorial-membuat-restful-api-menggunakan-api-platform)]

Baik, sekarang kita fokus ke tutorial RESTFul API untuk CodeIgniter 4 dulu. Alasan saya memilih CodeIgniter 4 ini salah satunya dari segi kemudahan pengembangan. Kenapa mudah dari segi pengembangan? karena berbeda dengan pendahulunya CodeIgniter versi 3 yang harus menggunakan library tambahan, di CodeIgniter 4 ini terdapat class yang dapat digunakan untuk membuat RESTFul API[^1], yaitu `ResourceController` class. Dengan menggunakan `ResourceController` classs, kita dapat membuat RESTFul API dengan mudah, karena sudah disediakan method untuk masing-masing endpoint, seperti menampilkan semua data, menampilkan satu data, menambahkan data, memperbaharui data dan juga untuk menghapus data. Selain class, kita juga dapat menggunakan `routes` untuk membuat RESTful route dengan menggunakan satu resource saja, yaitu dengan menggunakan method `resource()`. Method `resource()` ini menyediakan lima routes yang biasa digunakan sebagai resource untuk operasi CRUD. Sebagai contoh, kita membuat `routes` seperti ini:

```php
$routes->resource('photos');
```

Satu baris kode di atas, setara dengan membuat `routes` berikut ini:

```php
$routes->get('photos/new',             'Photos::new');
$routes->post('photos',                'Photos::create');
$routes->get('photos',                 'Photos::index');
$routes->get('photos/(:segment)',      'Photos::show/$1');
$routes->get('photos/(:segment)/edit', 'Photos::edit/$1');
$routes->put('photos/(:segment)',      'Photos::update/$1');
$routes->patch('photos/(:segment)',    'Photos::update/$1');
$routes->delete('photos/(:segment)',   'Photos::delete/$1');
```

Dengan menggunakan satu baris kode, bisa mencakup semua endpoint yang diperlukan. Tentu untuk kebutuhan produksi, kita harus membuat spesifikasinya terlebih dahulu. Karena ini untuk pembelajaran, di tutorial RESTFul API CodeIgniter 4 ini kita akan membuat endpoint untuk menampilkan semua data, menampilkan satu data, menambahkan data, memperbaharui data dan endpoint untuk menghapus data.

## Project Overview{#overview}
Pada tutorial [Belajar CodeIgniter 4](https://qadrlabs.com/series/belajar-codeigniter-4) edisi kali ini, kita akan membahas tentang RESTFul API. Sebagai studi kasus, di dalam tutorial ini kita akan membuat RESTFul API dari `blog` yang sebelumnya sudah kita coba buat di  [edisi tutorial codeigniter 4  sebelumnya](https://qadrlabs.com/post/seri-tutorial-codeigniter-4-crud-codeigniter-4). Skenarionya kurang lebih seperti ini. Katakanlah kita akan membuat aplikasi android yang menampilkan postingan yang diambil dari sebuah blog yang dibangun menggunakan CodeIgniter 4. Selain untuk menampilkan, perlu juga endpoint untuk mengelola data blog, seperti create, update dan delete postingan di blog tersebut. 

Berdasarkan kebutuhan tersebut, kita akan coba mengembangkan sebuah RESTFul API dari blog yang (ceritanya) sudah ada dengan endpoint berikut ini:

1. Endpoint menampilkan semua postingan.
2. Endpoint menampilkan satu postingan.
3. Endpoint menambahkan postingan baru.
4. Endpoint memperbaharui postingan yang ada.
5. Endpoint menghapus postingan yang ada.

## Prasyarat{#prasyarat}

Tahapan uji coba di tutorial Membuat RESTful API CodeIgniter 4 ini menggunakan aplikasi [Postman](https://www.postman.com/), pastikan sudah menginstall postman sebelum mengikuti tutorial ini. 

## Step 1 - Persiapan Development{#step-1}

Langkah yang pertama kali kita lakukan adalah persiapan development, dimulai dari instalasi CodeIgniter 4 sampai mempersiapkan database dan juga membuat tabel menggunakan `migrate` CodeIgniter 4. 

**Note:** *kalau kamu coba melanjutkan project dari  [tutorial  crud codeigniter 4](https://qadrlabs.com/post/seri-tutorial-codeigniter-4-crud-codeigniter-4) kamu boleh skip bagian persiapan development ini.*

Untuk proses instalasi CodeIgniter 4, buka terminal lalu run `command`:

```bash
composer create-project codeigniter4/appstarter restful-api-example
```

Tunggu beberapa saat sampai proses instalasi selesai.

Setelah CodeIgniter selesai diinstall, kita pindah ke direktori project:

```bash
cd restful-api-example
```

Di dalam project kita, terdapat file `env`. Copy file `env` lalu kita coba rename menjadi `.env`. Kalau menggunakan terminal, run `command` ini untuk copy file `env`:

```bash
cp env .env
```

**Note:** *Selain pakai command di atas, kita juga bisa langsung copy paste file `env`, lalu rename filenya menjadi `.env`*

Selanjutnya buka folder project kita di text editor. Di sini saya menggunakan visual studio code, dan untuk membuka folder project di visual studio code langsung di terminal, kita bisa run `command`:

```bash
code .
```

Setelah `command` di atas berhasil dieksekusi, visual studio code langsung terbuka dengan project `restful-api-example`.

Setelah project kita buka di text editor, kita sesuaikan konfigurasi project kita. Buka file `.env` yang sebelumnya sudah kita copy dari file `env`. Di dalam file tersebut terdapat beberapa konfigurasi berikut ini:

```php
# CI_ENVIRONMENT = production

# app.baseURL = ''

# database.default.hostname = localhost
# database.default.database = ci4
# database.default.username = root
# database.default.password = root
# database.default.DBDriver = MySQLi
```

Hapus tanda `#`, lalu sesuaikan menjadi seperti baris kode berikut ini.

```php
CI_ENVIRONMENT = development

app.baseURL = 'http://localhost:8080/'

database.default.hostname = localhost
database.default.database = blog
database.default.username = usernamekamu
database.default.password = passwordkamu
database.default.DBDriver = MySQLi
```

Untuk `username` dan `password`, sesuaikan dengan username dan password mysql kamu. Untuk yang menggunakan xampp, biasanya usernamenya itu `root` dan passwordnya kosong atau tidak diisi.

Selanjutnya kita buat database baru. Kita buat database dengan nama `blog`, sesuai dengan yang ada di file konfigurasi, yaitu file `.env`. Untuk membuat database, kita bisa buat melalui phpmyadmin. Buka phpMyadmin, lalu buat database baru dengan nama `blog`.

Setelah database sudah kita buat, tahapan selanjutnya adalah membuat tabel baru dengan nama `posts`. Seperti biasa untuk membuat tabel baru, kita akan memanfaatkan fitur Migration CodeIgniter. Buka kembali terminal, lalu run `command` berikut ini untuk membuat file migration:

```bash
php spark make:migration Posts
```

Output:

```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 13:29:05 UTC+00:00

File created: APPPATH/Database/Migrations/2024-05-08-132905_Posts.php

```





Di dalam direktori `app/Database/Migrations`, kita bisa lihat ada file baru dengan format `YYYY-MM-DD-HHIISS_namatable.php`. Kita modifikasi file `2024-05-08-132905_Posts.php` (note: nama file di project kita pasti beda-beda sesuai dengan timestamp ketika file migration dibuat), kita sesuaikan kodenya menjadi seperti berikut ini.

```php
<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class Posts extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id' => [
                'type' => 'INT',
                'unsigned' => TRUE,
                'auto_increment' => TRUE
            ],
            'title' => [
                'type' => 'VARCHAR',
                'constraint' => 128,
                'null' => FALSE,
            ],
            'content' => [
                'type' => 'TEXT',
                'null' => FALSE
            ],
            'slug' => [
                'type' => 'VARCHAR',
                'constraint' => 128,
                'null' => FALSE
            ],
            'status' => [
                'type' => 'INT',
                'constraint' => 1,
                'null' => FALSE
            ],
            'created_at' => [
                'type' => 'datetime',
                'null' => TRUE
            ],
            'updated_at' => [
                'type' => 'datetime',
                'null' => TRUE
            ],
            'deleted_at' => [
                'type' => 'datetime',
                'null' => TRUE
            ]
        ]);

        $this->forge->addKey('id', TRUE);
        $this->forge->createTable('posts');
    }

    //--------------------------------------------------------------------

    public function down()
    {
        $this->forge->dropTable('posts');
    }
}
```

Setelah selesai mengetik baris kode di atas, jangan lupa save kembali file `migration` nya.

Seperti yang terlihat di baris kode di atas, di dalam tabel `posts` terdapat beberapa field, yaitu `id` sebagai primary key, `title`, `content`, `slug`, `status`, dan timestamp  seperti `created_at`, `updated_at` dan `deleted_at`.

Sekarang kita coba run file migration untuk membuat tabel `posts`. Buka kembali terminal lalu run `command`:

```bash
php spark migrate
```

Output:

```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 13:32:56 UTC+00:00

Running all new migrations...
	Running: (App) 2024-05-08-132905_App\Database\Migrations\Posts
Migrations complete.
```



Terdapat dua table baru di dalam database `blog` setelah `command migrate` dirun. Nah pada tahapan ini, selanjutnya kita bisa mulai membuat RESTFul API CodeIgniter 4.

## Step 2 - Membuat Entity Class{#step-2}

Di dalam model class, kita akan memerlukan sebuah entity class. Buka kembali terminal lalu kita generate Entity Class menggunakan `command`:

```bash
php spark make:entity Post
```

Output ketika `command` di atas kita run:

```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 13:33:23 UTC+00:00

File created: APPPATH/Entities/Post.php
```


Di dalam direktori `app`, kita bisa lihat ada folder baru dengan nama `Entities`. Lalu kita bisa lihat ada file baru dengan nama `Post.php` di dalam direktori `app/Entities` hasi generate `command` di atas.

Sekarang kita coba tambahkan beberapa baris kode di class `Post` dalam file `Post.php`.

```php
<?php

namespace App\Entities;

use CodeIgniter\Entity\Entity;

class Post extends Entity
{
   // isi Post class 
}
```

Kita tambahkan property `$attributes` di dalam class `Post`.

```php
<?php

namespace App\Entities;

use CodeIgniter\Entity\Entity;

class Post extends Entity
{
    protected $attributes = [
        'title' => null,
        'content' => null,
        'status' => null,
        'slug' => null,
    ];

}
```

Selanjutnya kita tambahkan method setter untuk masing-masing atribut `Post` class.

```php
<?php

namespace App\Entities;

use CodeIgniter\Entity\Entity;

class Post extends Entity
{
    protected $attributes = [
        'title' => null,
        'content' => null,
        'status' => null,
        'slug' => null,
    ];

    public function setTitle(string $title): self
    {
        $this->attributes['title'] = strtoupper($title);
        return $this;
    }

    public function setContent(string $content): self
    {
        $this->attributes['content'] = $content;
        return $this;
    }

    public function setStatus(int $status): self
    {
        $this->attributes['status'] = $status;
        return $this;
    }

    public function setSlug(string $title): self
    {
        $this->attributes['slug'] = url_title(strtolower($title));
        return $this;
    }
}
```

Kita save kembali file `app/Entities/Post.php`.

## Step 3 - Membuat Model Class{#step-3}

Tahapan selanjutnya kita akan membuat Model Class. Buka kembali terminal, lalu kita run `spark command` di bawah ini untuk generate model class.

```bash
php spark make:model PostModel
```

Output ketika `command` di atas kita run.

```bash
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 13:34:17 UTC+00:00

File created: APPPATH/Models/PostModel.php
```

Terdapat file baru dengan nama `PostModel.php` hasil generate di direktori `app/Models`. Di dalam file `PostModel.php`, terdapat class `PostModel`.

```php
<?php

namespace App\Models;

use App\Entities\Post;
use CodeIgniter\Model;

class PostModel extends Model
{
    // isi PostModel Class    
}

```

Selanjutnya kita modifikasi beberapa properties di dalam class `PostModel`.

```php
<?php

namespace App\Models;

use App\Entities\Post;
use CodeIgniter\Model;

class PostModel extends Model
{
    protected $table = 'posts';
    protected $returnType = Post::class;

    protected $allowedFields = [
        'title',
        'slug',
        'content',
        'status'
    ];

    protected $validationRules = [
		    'id' => 'permit_empty|is_natural_no_zero',
        'title' => 'required|alpha_numeric_space|min_length[3]|max_length[255]|is_unique[posts.title,id,{id}]',
        'content' => 'required',
        'status' => 'required'
    ];
}
```

Pada baris kode di atas, kita bisa lihat terdapat beberapa atribut dari `PostModel` class.

- `$table`, atribut ini merujuk ke table di database, yaitu table `posts`.
- `$returnType`, result data dari query kita tentukan sebagai entity dari class `Post` yang sebelumnya kita coding.
- `$allowedFields`, array yang berisi nama field yang diijinkan pada saat proses `save()`, `insert()`, atau `update()`.
- `$validationRules`, array yang digunakan untuk aturan validasi, di sini kita sesuaikan aturan validasi untuk field `id`,`title`, `content`, dan `status`.

Setelah selesai kodingnya, jangan lupa save kembali file `app/Models/PostModel.php`.

## Step 4 - Membuat fitur create data{#step-4}

Tahapan berikutnya adalah membuat fitur untuk create data. Buka kembali terminal, lalu run `spark command` berikut ini untuk generate file controller.

```bash
php spark make:controller Posts
```

Output:

```bash
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 13:35:24 UTC+00:00

File created: APPPATH/Controllers/Posts.php
```

Kita bisa lihat file controller baru dengan nama `Posts.php` di direktori `app/Controllers` setelah `spark command` di atas berhasil di run. Di dalam file `Posts.php`, kita sesuaikan class controller `Posts`.

```php
<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;

class Posts extends ResourceController
{
    protected $modelName = 'App\Models\PostModel';
    protected $format = 'json';

}
```

Di sini kita modifikasi class `Posts` sebagai turunan dari class `ResourceController`, jangan lupa kita tambahkan statement `use` juga sebelum deklarasi class `Posts`.

``` php
use CodeIgniter\RESTful\ResourceController;
```

Untuk menangani create data baru, kita buat method dengan nama `create()` di dalam class `Posts`.

```php
<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;

class Posts extends ResourceController
{
    // [... baris kode sebelumnya ...]

    public function create()
    {
        $data = $this->request->getPost();
        if (!$this->model->save($data)) {
            # code...
            return $this->fail($this->model->errors());
        }

        return $this->respondCreated($data, 'post created');
    }
}
```

Save kembali file `Posts.php`.

## Step 5 - Membuat fitur display data{#step-5}

Untuk menampilkan data, kita akan membuat dua method, yaitu `index()` untuk menangani semua data `post`, dan `show()` untuk menangani display satu data `post` berdasarkan `id`.

Kita buat dulu method yang pertama untuk menampilkan semua data `posts`. Buka kembali file controller `Posts.php`, lalu kita tambahkan method `index()` di dalam class `Posts`.

```php
<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;

class Posts extends ResourceController
{
    // [... baris kode sebelumnya ...]

    public function index()
    {
        return $this->respond($this->model->findAll());
    }

    // [... baris kode berikutnya ...]
}

```

Di baris kode di atas kita gunakan `findAll()` method dari model class Untuk mengambil semua data. Lalu sebagai `return` dari method `index()`, kita gunakan trait `respond()` method yang akan me-return response ke client sesuai dengan format yang sudah kita sesuaikan di atribut `$format` dari class `Posts`, yaitu `json`.

Pada tahapan selanjutnya, kita tambahkan method kedua untuk menampilkan satu data berdasarkan id.

```php
<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;

class Posts extends ResourceController
{
    // [... baris kode sebelumnya ...]
    
    public function show($id = null)
    {
        $record = $this->model->find($id);
        if (!$record) {
            # code...
            return $this->failNotFound(sprintf(
                'post with id %d not found',
                $id
            ));
        }

        return $this->respond($record);
    }

    // [... baris kode berikutnya ...]
}
```

Pada baris kode di atas, kita gunakan `find()` method untuk mengambil data berdasarkan id,  setelah itu kita `return` satu row data sebagai response ke client. Apabila data tidak ditemukan, kita coba `return` pesan error sebagai response ke client.

## Step 6 - Membuat fitur update data{#step-6}

Fitur berikutnya adalah fitur untuk update data. Buka kembali file `Posts.php`, lalu kita tambahkan method yang menangani update data di dalam class `Posts`.

```php
<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;

class Posts extends ResourceController
{
    // [... baris kode sebelumnya ...]

    public function update($id = null)
    {
        $data = $this->request->getRawInput();
        $data['id'] = $id;

        if (!$this->model->save($data)) {
            # code...
            return $this->fail($this->model->errors());
        }

        return $this->respond($data, 200, 'post updated');
    }
}

```

Untuk proses update data di sini kita gunakan `save()` method, di mana method ini sebagai wrapper method `insert()` dan `update()` yang menangani proses insert atau update data secara otomatis berdasarkan primary key `id`. Karena di variable `$data`, kita tambahkan `id`, jadi proses yang akan dieksekusi oleh method `save()` ini adalah proses `update()` apabila `id` di dalam `$data` sama dengan `id` yang ada di table `posts`. Apabila `id` tidak ditemukan, di sini kita `return` pesan error dan apabila proses update berhasil, kita `return` response dengan pesan `post updated` ke client.

Setelah selesai, save kembali file controller `Posts.php`.

## Step 7 - Membuat fitur delete data{#step-7}

Dan fitur yang terakhir yang akan kita tambahkan endpointnya adalah fitur untuk menghapus data. Sama seperti fitur untuk update,terdapat parameter id pada method yang menangani proses menghapus data. Jadi proses menghapus data akan dilakukan berdasarkan id masing-masing data.

Buka kembali file controller `Posts.php`. Kita tambahkan method baru untuk menangani proses delete data di dalam class `Posts`.

```php
<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;

class Posts extends ResourceController
{
    // [... baris kode sebelumnya ...]

    public function delete($id = null)
    {
        $delete = $this->model->delete($id);
        if ($this->model->db->affectedRows() === 0
        ) {
            return $this->failNotFound(sprintf(
                'post with id %id not found or already deleted',
                $id
            ));
        }

        return $this->respondDeleted(['id' => $id], 'post deleted');
    }
}
```

Untuk proses hapus data, kita panggil method `delete()` dari model untuk menangani proses data berdasarkan `id`. Setelah method `delete()` di-run, pada baris kode di atas terdapat pengecekan jumlah row  yang terpengaruh proses delete. Jika nol maka `return` response pesan error ke client dan jika proses delete berhasil `return` response khusus untuk proses delete berhasil ke client. 

Setelah selesai, save kembali file `Posts.php`.

.
.
.

Semua method yang menangani RESTful api sudah selesai kita buat. Di bawah ini baris kode keseluruhan `Posts` class.

```php
<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;

class Posts extends ResourceController
{
    protected $modelName = 'App\Models\PostModel';
    protected $format = 'json';

    public function index()
    {
        return $this->respond($this->model->findAll());
    }

    public function show($id = null)
    {
        $record = $this->model->find($id);
        if (!$record) {
            # code...
            return $this->failNotFound(sprintf(
                'post with id %d not found',
                $id
            ));
        }

        return $this->respond($record);
    }

    public function create()
    {
        $data = $this->request->getPost();
        if (!$this->model->save($data)) {
            # code...
            return $this->fail($this->model->errors());
        }

        return $this->respondCreated($data, 'post created');
    }

    public function update($id = null)
    {
        $data = $this->request->getRawInput();
        $data['id'] = $id;

        if (!$this->model->save($data)) {
            # code...
            return $this->fail($this->model->errors());
        }

        return $this->respond($data, 200, 'post updated');
    }

    public function delete($id = null)
    {
        $delete = $this->model->delete($id);
        if ($this->model->db->affectedRows() === 0) {
            return $this->failNotFound(sprintf(
                'post with id %id not found or already deleted',
                $id
            ));
        }

        return $this->respondDeleted(['id' => $id], 'post deleted');
    }
}
```

## Step 8 - Menambahkan Route baru{#step-8}

Tahapan selanjutnya adalah mendaftarkan `routes` baru untuk mengakses controller yang sudah kita buat di tahapan sebelumnya. Buka file `app/Config/Routes.php`, lalu temukan kode berikut ini:

```php
$routes->get('/', 'Home::index');
```

Selanjutnya kita tambahkan `routes`, tepat di bawah routes untuk `Home`.

```php
$routes->get('/', 'Home::index');
$routes->resource('posts');
```

Save kembali file `Routes.php`.

Pada baris kode di atas, kita menerapkan `Resource Routes`. Dengan satu method `resource()` dapat membuat lima routes yang diperlukan untuk CRUD, seperti menambahkan data, menampilkan semua data, menampilkan satu data, memperbaharui data dan menghapus data.

Dengan menambahkan routes seperti di bawah ini:

```php
$routes->resource('posts');
```

Setara dengan menambahkan routes berikut ini:

```php
$routes->get('posts/new',             'Posts::new');
$routes->post('posts',                'Posts::create');
$routes->get('posts',                 'Posts::index');
$routes->get('posts/(:segment)',      'Posts::show/$1');
$routes->get('posts/(:segment)/edit', 'Posts::edit/$1');
$routes->put('posts/(:segment)',      'Posts::update/$1');
$routes->patch('posts/(:segment)',    'Posts::update/$1');
$routes->delete('posts/(:segment)',   'Posts::delete/$1');
```


## Step 9 - Uji coba{#step-9}

Pada tahapan ini kita akan melakukan proses uji coba project RESTFul API CodeIgniter 4 yang sudah kita coba buat di tahapan-tahapan sebelum. Untuk menguji coba, kita running project kita. Buka kembali terminal, lalu run `command`:

```bash
php spark serve
```

Seperti yang terlihat pada output terminal, url project kita `http://localhost:8080`.

```bash
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 13:37:35 UTC+00:00

CodeIgniter development server started on http://localhost:8080
Press Control-C to stop.
[Wed May  8 20:37:35 2024] PHP 8.2.18 Development Server (http://localhost:8080) started
```

Selanjutnya buka postman, kita coba tes display data. Arahkan url ke `http://localhost:8080/posts` dan pilih `GET` pada method request. Selanjutnya kita klik `Send` untuk mengirimkan request.
![Uji coba display data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/restful-api/Selection_001.png)

Ya responnya masih kosong karena memang belum kita tambahkan data.

Selanjutnya kita coba tambahkan data. Untuk url masih tetap sama, `http://localhost:8080/posts` dan untuk method pilih `POST`. Lalu pilih tab `Body` dan pilih `form-data`. Kita tambahkan beberapa key dan value pada `form-data` yaitu `title`, `status`, dan `content`. Setelah kita isi, selanjutnya kita klik tombol `Send`.
![Uji coba create data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/restful-api/Selection_002.png)

Ya, bisa kita lihat di gambar di atas, respon status nya `201 Created`. Datanya berhasil kita tambahkan.

Misalkan value `title` nya kita tambahkan simbol. Terus kita coba `Send`.
![Uji coba tes error create data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/restful-api/Selection_003.png)

Data gagal ditambahkan dan terdapat pesan kesalahan kalau data tidak sesuai dengan aturan validasi.

```php
{
    "status": 400,
    "error": 400,
    "messages": {
        "title": "The title field may only contain alphanumeric and space characters."
    }
}
```

Untuk sample data kita tambahkan lima data saja.

Selanjutnya, kita coba tampilkan semua data. Pada bagian method, kita set menjadi `GET`, lalu kita coba klik tombol `SEND`.
![Uji coba display semua data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/restful-api/Selection_004.png)

Nah di output tampil semua data.

Sekarang kita coba tampilkan satu data. Misalnya kita mau tampilkan data dengan id 3. Pada url arahkan ke `http://localhost:8080/posts/3`, lalu ketik tombol `Send`.

![Uji coba display satu data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/restful-api/Selection_005.png)

Bisa kita lihat, data dengan id 3 ditampilkan di outputnya.

Uji coba selanjutnya adalah memperbaharui data. Data yang akan kita perbaharui data dengan id 3, pada bagian `url` kita arahkan ke url `http://localhost:8080/posts/3` dan pada bagian method kita set menjadi `PUT`. 

Sama seperti tahapan uji coba insert data, untuk mengirim data, kita pilih tab `body` pada postman, lalu kita pilih tab `x-www-form-urlencode`, lalu tambahkan key sesuai dengan field yang ada pada tabel, yaitu `title`, `status` dan `content`. Pada value masing-masing key, kita coba ubah, lalu ketik tombol `Send`.

![Uji coba update data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/restful-api/Selection_006.png)

Nah kawan, terlihat pada gambar di atas, status responnya itu `200 post data updated`. Itu artinya data berhasil diperbaharui. Untuk memastikan kita coba cek lagi menggunakan method `GET`.

![Uji coba cek data yang diperbaharui](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/restful-api/Selection_007.png)

Yep, datanya sudah berubah.

Dan uji coba terakhir adalah menghapus data. Kita coba hapus data dengan id 1. Pada bagian `url` isi dengan ``http://localhost:8080/posts/1` dan pada bagian method pilih method `DELETE`. Lalu, selanjutnya tekan tombol `SEND`.

![Uji coba hapus data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/restful-api/Selection_008.png)

Pada gambar di atas, status responnya adalah `200 post deleted`, itu artinya data berhasil dihapus. 

Untuk memastikan, kita coba GET data dengan id 1. Pada bagian `url` isi dengan `http://localhost:8080/posts/1` dan pilih method `GET`.

![Uji coba cek data yang sudah dihapus](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/restful-api/Selection_009.png)

Ya datanya tidak ditemukan dan status responnya `404 not found`.

\* \* \*

Salah satu kemudahan ketika membangun RESTFul API CodeIgniter 4 adalah tersedianya class yang dapat kita gunakan untuk membuat RESTFul API, yaitu `ResourceController`. Selain itu terdapat `routes` yang dapat menghandle lima `routes` yang biasa digunakan untuk RESTFul API yang menangani menambahkan data, menampilkan semua maupun satu data, memperbaharui data, dan menghapus data hanya dengan menggunakan satu baris kode.

Tujuan awal eksperimen membuat RESTFul API CodeIgniter 4 ini untuk pengembangan aplikasi android. Namun tidak menutup kemungkinan, RESTFul API di postingan ini bisa digunakan untuk membuat karya yang lain, untuk membuat aplikasi web menggunakan Vue JS misalnya. Selamat mencoba! Semoga belajarnya semakin menyenangkan.. dan sampai jumpa kembali di tutorial CodeIgniter 4 berikutnya.

### Referensi{#referensi}

[^1]: Dokumentasi CodeIgniter 4 tentang RESTFul @ [RESTful Resource Handling](https://codeigniter4.github.io/userguide/incoming/restful.html)