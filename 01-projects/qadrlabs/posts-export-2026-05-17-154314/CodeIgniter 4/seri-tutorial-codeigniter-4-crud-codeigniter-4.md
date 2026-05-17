---
title: "Tutorial Membuat Fitur CRUD di CodeIgniter 4 untuk Pemula"
slug: "seri-tutorial-codeigniter-4-crud-codeigniter-4"
category: "CodeIgniter 4"
date: "2020-01-30"
status: "published"
---

## Introduction {#introduction}
Dalam dunia pengembangan web, fitur CRUD (Create, Read, Update, Delete) adalah salah satu konsep dasar yang wajib dikuasai oleh setiap developer. Fitur ini memungkinkan kita untuk mengelola data dalam aplikasi, seperti menambahkan, membaca, memperbarui, dan menghapus data dari database. Nah, dalam tutorial ini, kita akan mempelajari **cara membuat fitur CRUD menggunakan CodeIgniter 4**, framework PHP yang ringan, cepat, dan mudah dipelajari.

Tutorial ini merupakan **edisi pertama** dari seri tutorial **Belajar CodeIgniter 4**. Jika Anda tertarik untuk mempelajari lebih banyak tentang CodeIgniter 4, Anda dapat mengakses seri lengkapnya di [Belajar CodeIgniter 4](https://qadrlabs.com/series/belajar-codeigniter-4).

### **Apa Itu CRUD?**
CRUD adalah singkatan dari **Create, Read, Update, dan Delete**. Keempat operasi ini merupakan fondasi dasar dalam pengembangan aplikasi berbasis database. Berikut penjelasan singkatnya:
- **Create**: Menambahkan data baru ke dalam database.
- **Read**: Membaca atau menampilkan data yang sudah tersimpan.
- **Update**: Memperbarui data yang sudah ada.
- **Delete**: Menghapus data dari database.

Dalam tutorial CodeIgniter 4 ini, kita tidak hanya akan belajar tentang CRUD, tetapi juga akan mempelajari cara menggunakan **Model**, **Migration**, dan **Templating UI** secara praktis.

### **Kenapa CodeIgniter 4?**
CodeIgniter 4 adalah framework PHP yang ringan, cepat, dan mudah dipelajari. Dengan dukungan fitur-fitur modern seperti **Migration**, **Model**, dan **Templating**, CodeIgniter 4 menjadi pilihan tepat untuk membangun aplikasi web dengan cepat. Beberapa keunggulan CodeIgniter 4 antara lain:
- **Ringan dan Cepat**: Performa yang optimal untuk aplikasi web skala kecil hingga menengah.
- **Mudah Dipelajari**: Sintaks yang sederhana dan dokumentasi yang lengkap.
- **Fitur Modern**: Dukungan untuk migration, namespace, dan library yang powerful.

Jika Anda ingin mempelajari cara membuat fitur CRUD di CodeIgniter 4, tutorial ini adalah tempat yang tepat untuk memulai.

## Overview {#overview}
Dalam tutorial ini, kita akan membangun sebuah **aplikasi blog sederhana** yang memungkinkan pengguna untuk mengelola post (artikel) dengan fitur CRUD (Create, Read, Update, Delete). Aplikasi ini akan menggunakan **CodeIgniter 4**, sebuah framework PHP yang ringan dan powerful, serta dilengkapi dengan fitur-fitur modern seperti **Migration**, **Model**, dan **Templating**.

#### **Apa yang Akan Kita Build?**
Kita akan membuat aplikasi blog sederhana dengan fitur-fitur berikut:
- **Menampilkan Daftar Post**: Menampilkan semua post yang telah dibuat dalam bentuk tabel.
- **Membuat Post Baru**: Menambahkan post baru ke dalam database melalui form input.
- **Memperbarui Post**: Mengedit atau memperbarui post yang sudah ada.
- **Menghapus Post**: Menghapus post dari database.

#### **Apa yang Akan Kita Pelajari?**
Selama mengikuti tutorial ini, Anda akan mempelajari:
- Cara menginstal dan mengkonfigurasi **CodeIgniter 4**.
- Cara membuat dan mengelola database menggunakan **Migration**.
- Cara membuat tampilan UI sederhana dengan **Templating**.
- Cara mengimplementasikan operasi CRUD (Create, Read, Update, Delete) menggunakan **Model** di CodeIgniter 4.
- Cara menggunakan **Pagination** untuk menampilkan data dalam bentuk halaman.

#### **Goal Tutorial Ini**
Tujuan dari tutorial ini adalah:
- Memberikan pemahaman dasar tentang cara membangun aplikasi web dengan **CodeIgniter 4**.
- Membantu Anda menguasai konsep CRUD dan implementasinya dalam framework modern.
- Memberikan panduan praktis yang dapat langsung diaplikasikan dalam proyek nyata.

---

### **Apa Saja Langkah-Langkahnya?**
Tertarik untuk mempelajari lebih lanjut? Yuk, simak langkah-langkah lengkapnya di bawah ini! 

---

**Daftar Isi**
1. [Persiapan Development](#step-1-persiapan-development)
2. [Instalasi CodeIgniter 4](#step-2-instalasi-codeigniter-4)
3. [Konfigurasi Project](#step-3-konfigurasi-project)
4. [Membuat Database](#step-4-membuat-database)
5. [Membuat File Migration](#step-5-membuat-file-migration)
6. [Membuat Template UI](#step-6-membuat-template-ui)
7. [Fitur Menampilkan Daftar Post](#step-7-read-post)
8. [Fitur Membuat Post Baru](#step-8-create-post)
9. [Fitur Memperbarui Post](#step-9-update-post)
10. [Fitur Menghapus Post](#step-10-delete-post)
11. [Uji Coba Project](#step-11-uji-coba-project)
12. [Kesimpulan](#kesimpulan)

---

**Yuk, mulai langkah pertama!**

## Step 1 Persiapan Development {#step-1-persiapan-development}

Menurut Dokumentasi Resminya[^1], ada beberapa requirement untuk menggunakan CodeIgniter 4, *check this out ya!*

1. PHP yang digunakan adalah versi 8.1 atau yang terbaru, dengan  '*intl*' extension.
2. Ekstensi php-json
3. Ekstensi php-mbstring
4. Ekstensi php-mysqlnd
5. Ekstensi php-xml
6. libcurl untuk kebutuhan CURLRequest

**Catatan:** lupa install ekstensi *intl* ini menjadi salah satu penyebab error dan sering ditanyakan di forum programmer, jadi pastikan kawan-kawan sudah install ekstensinya ya..

Dan untuk database, ada beberapa database yang sudah didukung oleh CodeIgniter:

1. MySQL (5.1+) via MySQLi driver
2. PostgreSQL via Postgre driver
3. SQLite3 via SQLite3 driver

Di tutorial ini, kita akan menggunakan MYSQL untuk database-nya dan, untuk proses instalasi kita juga akan menggunakan ```composer``` (**recommended**). Jadi pastikan ```composer``` sudah terinstall. Kalau belum diinstall boleh baca [tutorial install composer](https://qadrlabs.com/post/cara-installasi-dan-penggunaan-composer-pada-ubuntu-16-04) terlebih dahulu.

## Step 2 Instalasi CodeIgniter 4 {#step-2-instalasi}

Langkah pertama adalah instalasi CodeIgniter 4. Ada beberapa cara untuk instal CodeIgniter 4, yang pertama [secara manual](https://codeigniter4.github.io/userguide/installation/installing_manual.html) dan yang kedua adalah menggunakan ```composer```. Karena ada banyak manfaat yang sudah saya rasakan setelah menggunakan `composer`, jadi saya lebih merekomendasikan instalasi menggunakan `composer`.

Untuk menginstal CodeIgniter 4 menggunakan `composer`. Kita buka terminal atau cmd terlebih dahulu, lalu kita jalankan *command*:

```
composer create-project codeigniter4/appstarter blog
```

Tunggu sampai proses instalasi menggunakan ```composer``` selesai.

Nah, setelah instalasi CodeIgniter 4 selesai, selanjutnya masuk ke folder project dengan *command*:

```
cd blog
```

Selanjutnya kita coba cek apakah CodeIgniter 4 sudah berhasil kita install. Kita coba running project kita menggunakan server built-in untuk development dengan menggunakan *command*:

```
php spark serve
```

Buka browser lalu kita buka url ```http://localhost:8080```. Kita bisa lihat tampilan awal dari CodeIgniter 4.

## Step 3 Konfigurasi Project {#step-3-konfigurasi-project}

Selanjutnya kita akan mengatur beberapa konfigurasi seperti environment project, base url, dan konfigurasi database. Buat file ```.env``` dengan menggunakan *command*:

```
cp env .env
```

Maksud `command` di atas adalah mengcopy-paste file `env` yang ada di project kita lalu direname dengan nama `.env`. Ya, kawan.. selain menggunakan terminal kita bisa langsung buat file `.env` secara manual juga.

Selanjutnya kita buka project kita di text editor. Nah kita bisa lihat ada file ```.env``` yang baru saja kita buat. Selanjutnya buka file ```.env```, lalu kita temukan kode berikut ini:

```
# CI_ENVIRONMENT = production

# app.baseURL = ''

# database.default.hostname = localhost
# database.default.database = ci4
# database.default.username = root
# database.default.password = root
# database.default.DBDriver = MySQLi

```

Kita sesuaikan konfigurasinya menjadi seperti di bawah ini.

```
CI_ENVIRONMENT = development

app.baseURL = 'http://localhost:8080/'

database.default.hostname = localhost
database.default.database = blog
database.default.username = root
database.default.password = 
database.default.DBDriver = MySQLi
```

**Catatan:** di baris kode di atas, Variable `CI_ENVIRONMENT` ini digunakan untuk mengatur enviroment project kita. Karena kita masih dalam tahap development, jadi kita atur menjadi `development`. Selain itu ada juga variable untuk konfigurasi database. Untuk `database.default.password`, teman-teman sesuaikan dengan password akun mysql masing-masing. Jika menggunakan XAMPP, biasanya passwordnya kosong atau tidak diisi seperti yang tertulis di baris kode di atas.

## Step 4 Membuat Database {#step-4-membuat-database}

Oke langkah selanjutnya, kita buat dulu database dengan nama seperti yang ada di file ```.env``` yaitu database ```blog```. Buka phpMyAdmin, lalu buat database baru dengan nama ```blog```.

## Step 5 Membuat file migration {#step-5-membuat-file-migration}

Langkah selanjutnya adalah membuat table baru untuk menyimpan data post. Nah, berbeda dengan edisi tutorial sebelumnya, kali ini kita akan belajar menggunakan fitur **migration** punya CodeIgniter 4[^2] *lho!* 

Pada langkah ini, kita buat file migration untuk membuat table ```posts```. Buka kembali ```terminal``` / ```cmd```, lalu jalankan *command* berikut ini untuk membuat file migration:

```
php spark make:migration Posts
```

Output:

```bash
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-06 14:06:31 UTC+00:00

File created: APPPATH/Database/Migrations/2024-05-06-140631_Posts.php
```


Selanjutnya kita bisa lihat file baru yang dibuat *command* di atas di direktori ```app/Database/Migrations``` dan memiliki nama dengan format ```YYYY-MM-DD-HHIISS_namatable.php``` misalnya ```2024-05-06-140631_Posts.php``` sesuai dengan timestamp ketika filenya dibuat. Buka file ```2024-05-06-140631_Posts.php``` lalu sesuaikan kodenya menjadi seperti berikut ini:

```php
<?php namespace App\Database\Migrations;

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

Selanjutnya kita run perintah ```migrate``` di terminal atau cmd. Buka terminal atau cmd lalu jalankan *command*:

```
php spark migrate
```

Output:

```bash
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-06 14:09:06 UTC+00:00

Running all new migrations...
	Running: (App) 2024-05-06-140631_App\Database\Migrations\Posts
Migrations complete.
```

Ketika kita cek di phpMyAdmin, kita bisa melihat terdapat dua table baru di database ```blog```, ada table ```migrations``` dan table ```posts``` sesuai dengan file migration yang sudah kita ketik sebelumnya.

## Step 6 Membuat template UI {#step-6-membuat-template-ui}

CodeIgniter mendukung sistem layout yang mudah dan fleksibel, sehingga dapat digunakan untuk lebih dari satu layout tampilan halaman untuk project kita. Nah di langkah ini kita akan menggunakan sistem layout milik CodeIgniter untuk membuat template UI. Selain itu kita juga akan menggunakan Bootsrap 4 untuk  UI project kita.

Nah sekarang kita buat folder baru di direktori ```app/Views``` dengan nama ```layouts```. Lalu buat file baru di dalam folder tersebut (```app/Views/layouts```) dengan nama ```main.php```. Lalu ketik kode berikut ini ya.. 

```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta name="<?= csrf_token() ?>" content="<?= csrf_hash() ?>">
    <title><?= $title; ?></title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css" integrity="sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh" crossorigin="anonymous">
</head>

<body>

    <!-- Content -->
    <?= $this->renderSection('content') ?>

    <!-- /.Content -->

    <footer class="text-center mt-5">
        <p><em><small>Seri Tutorial CodeIgniter 4: CRUD CodeIgniter @ <a href="https://qadrlabs.com/">qadrLabs</a></small></em></p>
    </footer>
    <script src="https://code.jquery.com/jquery-3.4.1.slim.min.js" integrity="sha384-J6qa4849blE2+poT4WnyKhv5vZF5SrPo0iEjwBvKU7imGFAV0wwj1yYfoRSJoZ+n" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js" integrity="sha384-Q6E9RHvbIyZFJoft+2mJbHaEWldlvI9IOYy5n3zV9zzTtmI3UksdQRVvoxMfooAo" crossorigin="anonymous"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js" integrity="sha384-wfSDF2E50Y2D1uUdj0O3uMBJnjuUD4Ih7YwaYd1iqfktj0Uod8GCExl3Og8ifwB6" crossorigin="anonymous"></script>

    <?= $this->renderSection('extra-js') ?>

</body>

</html>

```

Di dalam code di atas, terdapat code ``` $this->renderSection('content')``` dan juga ```$this->renderSection('extra-js')```. code tersebut nantinya akan kita gunakan untuk me-render tampilan untuk masing-masing content dan extra-js untuk me-render section khusus javascript.

## Step 7 Fitur Menampilkan Daftar Post {#step-7-read-post}

Fitur yang akan kita buat adalah fitur untuk menampilkan daftar Post. Pertama kita buat file model dengan nama ```PostModel```. 

Buka terminal, lalu run command berikut ini.

```
php spark make:model PostModel
```

Output di terminal:

```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-06 14:10:44 UTC+00:00

File created: APPPATH/Models/PostModel.php
```

Kita bisa lihat ada file baru yang berhasil digenerate setelah kita run command di atas.



Selanjutnya buat sebuah Controller baru dengan nama ```Post.php``` di direktori ```app/Controllers```. Buka kembali terminal, lalu run command berikut ini.

```
php spark make:controller Post
```

Output:

```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-06 14:12:12 UTC+00:00

File created: APPPATH/Controllers/Post.php
```



Selanjutnya kita sesuaikan file `Controllers/Post.php` menjadi seperti baris kode berikut ini.

```php
<?php namespace App\Controllers;

use App\Models\PostModel;

class Post extends BaseController
{
	/**
	 *
	 * @var Model
	 */
	protected $model;
	
	public function __construct()
	{
		$this->model = new PostModel();
		$this->helpers = ['form', 'url'];
		
	}

	public function index()
	{
		$data = [
			'posts' => $this->model->paginate(10),
			'pager' => $this->model->pager,
			'title' => 'POST LIST'
		];

		return view('posts/index', $data);
	}

}


```



Save kembali file `Controllers/Post.php`.



Pada baris kode di atas, di blok kode method ```index()``` terdapat code ```return view('posts/index', $data);``` itu artinya method tersebut me-render sebuah view dengan nama ```index.php``` yang ada di direktori ```app/Views/posts```.

Langkah selanjutnya kita buat folder baru sesuai dengan view yang dirender di method ```index()```. Buat folder baru dengan nama ```posts``` (*pake s ya..*) di direktori ```app/Views```. Lalu buat file baru dengan nama ```index.php``` di dalam folder yang baru saja dibuat. Selanjutnya yuk kita ketik kode ini:

```html
<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>

<div class="container mt-5">
    <div class="row">
        <div class="col-md-12">
            <div class="card">
                <div class="card-header">
                    POST
                    <a href="<?php echo base_url('post/create'); ?>" class="btn btn-primary btn-sm float-right">New Record</a>
                </div>
                <div class="card-body">

                    <?php if (session()->getFlashdata('success')) { ?>
                        <div class="alert alert-success">
                            <?php echo session()->getFlashdata('success'); ?>
                        </div>
                    <?php } ?>

                    <?php if (session()->getFlashdata('error')) { ?>
                        <div class="alert alert-danger">
                            <?php echo session()->getFlashdata('error'); ?>
                        </div>
                    <?php } ?>

                    <table class="table table-bordered">
                        <thead class="text-center">
                            <tr>
                                <th scope="col">Title</th>
                                <th scope="col">Status</th>
                                <th scope="col">Created Date</th>
                                <th scope="col">Action</th>
                            </tr>
                        </thead>
                        <tbody class="text-center">
                            <?php if (!empty($posts) && is_array($posts)) { ?>
                                <?php foreach ($posts as $row) { ?>
                                    <tr>
                                        <td><?php echo $row['title']; ?></td>
                                        <td><?php echo ($row['status'] == 2) ? 'Publish':'Draft'; ?></td>
                                        <td><?= $row['created_at'] ?></td>
                                        <td>
                                            

                                            <form onsubmit="return confirm('Apakah Anda Yakin ?');"  
                                                action="<?php echo base_url('post/destroy/' . $row['id']); ?>" method="POST">  

                                                <input type="hidden" name="{csrf_token}" value="{csrf_hash}">
                                                <input type="hidden" name="_method" value="DELETE"> 

                                                <a href="<?php echo base_url('post/edit/' . $row['id']); ?>" class="btn btn-primary btn-sm">Edit</a>

                                                <button type="submit" class="btn btn-danger btn-sm">Delete</button>  
                                            </form>  
                                        </td>
                                    </tr>

                                <?php } ?>
                            <?php } else { ?>
                                <tr>
                                    <td colspan="4" class="text-center">No post found.</td>
                                </tr>

                            <?php } ?>
                        </tbody>
                    </table>

                    <?= $pager->links(); ?>
                </div>

            </div>
        </div>
    </div>
</div>

<?= $this->endSection() ?>

<?= $this->section('extra-js') ?>
<script>
    $(document).ready(function() {
        $('.pagination li').addClass('page-item');
        $('.pagination li a').addClass('page-link');
    })
</script>
<?= $this->endSection() ?>
```

Oke, fitur untuk menampilkan daftar post sudah selesai. Nah supaya ketika halaman daftar post ini pertama kali ditampilkan ketika project kita running di browser, kita harus atur dulu route untuk default controller-nya.

Jadi kita atur route-nya supaya controller ```Post``` sebagai controller default ketika project kita running. Buka file ```app/Config/Routes.php```, lalu cek baris kode ke-75 (kurang lebih). Temukan kode seperti ini:

```php
$routes->get('/', 'Home::index');

```

Lalu kita ubah menjadi:

```php
$routes->get('/', 'Post::index');

```

Karena pada real project jarang ada yang menampilkan data berupa table di halaman pertama, sebagai pembelajaran kita tambahkan route kedua untuk menampilkan data post.

```php
$routes->get('/', 'Post::index');
$routes->get('/post', 'Post::index');
```

Untuk running project, buka cmd atau terminal lalu jalankan *command*:

```
php spark serve
```

Lalu buka url ```http://localhost:8080``` di browser, maka project kita akan menampilkan halaman daftar post.

Okee, kita lanjut coding fitur selanjutnya...

## Step 8 Fitur Membuat Post Baru {#step-8-create-post}

Selanjutnya kita buat fitur untuk menambahkan postingan baru. Buka kembali file model ```PostModel.php```, lalu kita sesuaikan beberapa properties di dalam class ```PostModel```:

```php
<?php

namespace App\Models;

use CodeIgniter\Model;

class PostModel extends Model
{
    protected $table = 'posts';
    protected $allowedFields = ['title', 'slug' , 'content', 'status'];
    protected $useTimestamps = true;
    protected $createdField = 'created_at';
    protected $updatedField = 'updated_at';
    protected $deletedField = 'deleted_at';
    
    protected $validationRules = [
        'title' => 'required|min_length[10]|max_length[100]',
        'content' => 'required',
        'status' => 'required'
    ];

    protected $skipValidation = false;

}
```

Selanjutnya, buka kembali file controller ```Post.php```, lalu tambahkan method ```create()``` di dalam class ```Post```.

```php
  // [CODE SEBELUMNYA]

	public function create()
	{
		$data = ['title' => 'Create new post'];

		return view('posts/create', $data);
  	}
  
  // [CODE SELANJUTNYA]

```

Setelah itu, kita buat file baru dengan nama ```create.php``` di dalam direktori ```app/Views/posts```. *Yuk* kita ketik kode ini...

```html
<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>

<div class="container mt-5">
    <div class="row">
        <div class="col-md-12">
            <div class="card">
                <div class="card-header">
                    <?= $title ?>
                </div>
                <div class="card-body">

                    <?php if (session()->getFlashdata('error')) : ?>
                        <div class="alert alert-danger">
                            <?php echo session()->getFlashdata('error'); ?>
                        </div>
                    <?php endif; ?>

                    <?= validation_list_errors() ?>
                    
                    <?= form_open('post/store'); ?>
                    <div class="form-group">
                        <label for="title">Title</label>
                        <input type="text" name="title" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label for="content">Content</label>
                        <textarea name="content" id="post_content" class="form-control" required></textarea>
                    </div>
                    <div class="form-group">
                        <label for="status">Status</label>
                        <select name="status" id="" class="form-control">
                            <option value="1" selected>Draft</option>
                            <option value="2">Publish</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <button class="btn btn-primary">Save</button>
                        <a href="<?= base_url('post') ?>" class="btn btn-link">Back</a>
                    </div>
                    <?= form_close(); ?>
                </div>

            </div>
        </div>
    </div>
</div>

<?= $this->endSection() ?>

<?= $this->section('extra-js') ?>
<!-- include summernote css/js -->
<link href="https://cdn.jsdelivr.net/npm/summernote@0.8.15/dist/summernote-bs4.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/summernote@0.8.15/dist/summernote-bs4.min.js"></script>
<script>
    $(document).ready(function() {
        $('#post_content').summernote({
            tabsize: 2,
            height: 500
        });
    })
</script>
<?= $this->endSection() ?>
```

Selanjutnya kita tambahkan method untuk menyimpan data post ke database. Buka kembali file controller ```Post.php```. Kita tambahkan method ```store()``` untuk menangani proses insert data ke dalam table ```posts```. 

```php
  // ... [CODE SEBELUMNYA]

    public function store()
    {
        $data = $this->request->getPost(['title', 'content', 'status']);

        if (! $this->validateData($data, $this->model->validationRules)) {
            return $this->create();
        }

        $post = $this->validator->getValidated();

        $save = $this->model->save([
            'title' => $post['title'],
            'content' => $post['content'],
            'status' => $post['status'],
            'slug' => url_title(strtolower($post['title'])),
        ]);

        session()->setFlashdata('success', 'Post has been added successfully.');
        return redirect()->to(base_url('post'));
  }

  // ... [CODE SELANJUTNYA]

```

Sehingga keseluruhan file ```Post.php``` menjadi:

```php
<?php namespace App\Controllers;

use App\Models\PostModel;

class Post extends BaseController
{
    /**
     *
     * @var Model
     */
    protected $model;

    public function __construct()
    {
        $this->model = new PostModel();
        $this->helpers = ['form', 'url'];

    }

    public function index()
    {
        $data = [
            'posts' => $this->model->paginate(10),
            'pager' => $this->model->pager,
            'title' => 'POST LIST'
        ];

        return view('posts/index', $data);
    }

    public function create()
    {
        $data = ['title' => 'Create new post'];

        return view('posts/create', $data);
    }

    public function store()
    {
        $data = $this->request->getPost(['title', 'content', 'status']);

        if (! $this->validateData($data, $this->model->validationRules)) {
            return $this->create();
        }

        $post = $this->validator->getValidated();

        $save = $this->model->save([
            'title' => $post['title'],
            'content' => $post['content'],
            'status' => $post['status'],
            'slug' => url_title(strtolower($post['title'])),
        ]);

        session()->setFlashdata('success', 'Post has been added successfully.');
        return redirect()->to(base_url('post'));
  }

}
```

Selanjutnya kita tambahkan route baru untuk create dan store data post. Buka kembali file `app/Config/Routes.php`, lalu kita tambahkan route baru.

```
$routes->get('/post/create', 'Post::create');
$routes->post('/post/store', 'Post::store');
```

Save kembali file `app/Config/Routes.php`.

## Step 9 Fitur Update Post {#step-9-update-post}

Selanjutnya kita tambahkan fitur untuk memperbaharui data post ke dalam project kita. Buka kembali file controller ```Post.php```. Lalu kita tambahkan method ```edit()``` di dalam class ```Post```. Yuk kita ketik lagi kodenya... ^^

```php
  	public function edit($id)
	{
		$post = $this->model->find($id);

		if (empty($post)) {
			session()->setFlashdata('error','Post not found');
			return redirect()->back();
		}

		$data = [
			'title' => 'Edit Post',
			'post' => $post
		];

		return view('posts/edit', $data);


	}
```

Dan seperti biasa kita buat file untuk *view*-nya. Kita buat file ```edit.php``` di dalam direktori ```app/Views/posts```, lalu kita ketik baris code di bawah ini.

```html
<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>

<div class="container mt-5">
    <div class="row">
        <div class="col-md-12">
            <div class="card">
                <div class="card-header">
                    <?= $title ?>
                </div>
                <div class="card-body">

                    <?php if (session()->getFlashdata('error')) : ?>
                        <div class="alert alert-danger">
                            <?php echo session()->getFlashdata('error'); ?>
                        </div>
                    <?php endif; ?>

                    <?= validation_list_errors() ?>

                    <?= form_open('post/update/'. $post['id']); ?>
                    <input type="hidden" name="_method" value="PUT">

                    <div class="form-group">
                        <label for="title">Title</label>
                        <input type="text" name="title" value="<?= $post['title'];?>" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label for="content">Content</label>
                        <textarea name="content" id="post_content" class="form-control" required><?= $post['content'];?></textarea>
                    </div>
                    <div class="form-group">
                        <label for="status">Status</label>
                        <select name="status" id="" class="form-control">
                            <option value="1" <?php echo ($post['status'] == 1) ? 'selected':'';?>>Draft</option>
                            <option value="2" <?php echo ($post['status'] == 2) ? 'selected':'';?>>Publish</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <button class="btn btn-primary">Update</button>
                        <a href="<?= base_url('post') ?>" class="btn btn-link">Back</a>
                    </div>
                    <?= form_close(); ?>

                </div>

            </div>
        </div>
    </div>
</div>

<?= $this->endSection() ?>

<?= $this->section('extra-js') ?>
<!-- include summernote css/js -->
<link href="https://cdn.jsdelivr.net/npm/summernote@0.8.15/dist/summernote-bs4.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/summernote@0.8.15/dist/summernote-bs4.min.js"></script>
<script>
    $(document).ready(function() {
        $('#post_content').summernote({
            tabsize: 2,
            height: 500
        });
    })
</script>
<?= $this->endSection() ?>
```

Selanjutnya kita tambahkan code untuk memperbaharui data yang ada di database. Buka kembali file controller ```Post.php``` lalu kita tambahkan method ```update()``` di dalam class ```Post```.

```php
    public function update($id)
    {
        $post = $this->model->find($id);

        if (empty($post)) {
            session()->setFlashdata('error','Post not found');
            return redirect()->back();
        }

        $data = $this->request->getPost(['title', 'content', 'status']);

        if (! $this->validateData($data, $this->model->validationRules)) {
            return $this->create();
        }

        $updatedPost = $this->validator->getValidated();

        $update = $this->model->update($post['id'], $updatedPost);

        if ($update) {
            session()->setFlashdata('success', 'Post has been updated successfully');
            return redirect()->to(base_url('post'));
        } else {
            session()->setFlashdata('error', 'Some problems occured, please try again.');
            return redirect()->back();
        }
    }
```

Sehingga keseluruhan file controller ```Post.php``` menjadi:

```php
<?php namespace App\Controllers;

use App\Models\PostModel;
use CodeIgniter\Exceptions\PageNotFoundException;

class Post extends BaseController
{
    /**
     *
     * @var Model
     */
    protected $model;

    public function __construct()
    {
        $this->model = new PostModel();
        $this->helpers = ['form', 'url'];

    }

    public function index()
    {
        $data = [
            'posts' => $this->model->paginate(10),
            'pager' => $this->model->pager,
            'title' => 'POST LIST'
        ];

        return view('posts/index', $data);
    }

    public function create()
    {
        $data = ['title' => 'Create new post'];

        return view('posts/create', $data);
    }

    public function store()
    {
        $data = $this->request->getPost(['title', 'content', 'status']);

        if (! $this->validateData($data, $this->model->validationRules)) {
            return $this->create();
        }

        $post = $this->validator->getValidated();

        $save = $this->model->save([
            'title' => $post['title'],
            'content' => $post['content'],
            'status' => $post['status'],
            'slug' => url_title(strtolower($post['title'])),
        ]);

        session()->setFlashdata('success', 'Post has been added successfully.');
        return redirect()->to(base_url('post'));
  }

    public function edit($id)
    {
        $post = $this->model->find($id);

        if (empty($post)) {
            session()->setFlashdata('error','Post not found');
            return redirect()->back();
        }

        $data = [
            'title' => 'Edit Post',
            'post' => $post
        ];

        return view('posts/edit', $data);
    }

    public function update($id)
    {
        $post = $this->model->find($id);

        if (empty($post)) {
            session()->setFlashdata('error','Post not found');
            return redirect()->back();
        }

        $data = $this->request->getPost(['title', 'content', 'status']);

        if (! $this->validateData($data, $this->model->validationRules)) {
            return $this->create();
        }

        $updatedPost = $this->validator->getValidated();

        $update = $this->model->update($post['id'], $updatedPost);

        if ($update) {
            session()->setFlashdata('success', 'Post has been updated successfully');
            return redirect()->to(base_url('post'));
        } else {
            session()->setFlashdata('error', 'Some problems occured, please try again.');
            return redirect()->back();
        }
    }
}
```

Selanjutnya kita daftarkan route untuk menangani proses menampilkan form update dan proses update. Buka kembali file `app/Config/Routes.php`, lalu tambahkan route berikut ini.

```php
$routes->get('/post/edit/(:num)', 'Post::edit/$1');
$routes->put('/post/update/(:num)', 'Post::update/$1');
```

Save kembali file `app/Config/Routes.php`.

## Step 10 Fitur Hapus Post {#step-10-delete-post}

Fitur terakhir adalah fitur untuk menghapus data post di project kita. Buka kembali file controller ```Post.php```, lalu kita tambahkan method ```destroy()``` di dalam class ```Post```.

```php
	public function destroy($id)
	{
		
		if (empty($id)) {
			return redirect()->to(base_url('post'));
		}

		$delete = $this->model->delete($id);

		if ($delete) {
			session()->setFlashdata('success', 'Post has been removed successfully.');
			return redirect()->to(base_url('post'));
		} else {
			session()->setFlashdata('error', 'Some problems occured, please try again.');
			return redirect()->to(base_url('post'));
		}

	}
```

Sehingga keseluruhan file controller ```Post.php``` menjadi:

```php
<?php namespace App\Controllers;

use App\Models\PostModel;
use CodeIgniter\Exceptions\PageNotFoundException;

class Post extends BaseController
{
    /**
     *
     * @var Model
     */
    protected $model;

    public function __construct()
    {
        $this->model = new PostModel();
        $this->helpers = ['form', 'url'];

    }

    public function index()
    {
        $data = [
            'posts' => $this->model->paginate(10),
            'pager' => $this->model->pager,
            'title' => 'POST LIST'
        ];

        return view('posts/index', $data);
    }

    public function create()
    {
        $data = ['title' => 'Create new post'];

        return view('posts/create', $data);
    }

    public function store()
    {
        $data = $this->request->getPost(['title', 'content', 'status']);

        if (! $this->validateData($data, $this->model->validationRules)) {
            return $this->create();
        }

        $post = $this->validator->getValidated();

        $save = $this->model->save([
            'title' => $post['title'],
            'content' => $post['content'],
            'status' => $post['status'],
            'slug' => url_title(strtolower($post['title'])),
        ]);

        session()->setFlashdata('success', 'Post has been added successfully.');
        return redirect()->to(base_url('post'));
  }

    public function edit($id)
    {
        $post = $this->model->find($id);

        if (empty($post)) {
            session()->setFlashdata('error','Post not found');
            return redirect()->back();
        }

        $data = [
            'title' => 'Edit Post',
            'post' => $post
        ];

        return view('posts/edit', $data);
    }

    public function update($id)
    {
        $post = $this->model->find($id);

        if (empty($post)) {
            session()->setFlashdata('error','Post not found');
            return redirect()->back();
        }

        $data = $this->request->getPost(['title', 'content', 'status']);

        if (! $this->validateData($data, $this->model->validationRules)) {
            return $this->create();
        }

        $updatedPost = $this->validator->getValidated();

        $update = $this->model->update($post['id'], $updatedPost);

        if ($update) {
            session()->setFlashdata('success', 'Post has been updated successfully');
            return redirect()->to(base_url('post'));
        } else {
            session()->setFlashdata('error', 'Some problems occured, please try again.');
            return redirect()->back();
        }
    }

    public function destroy($id)
    {

        if (empty($id)) {
            return redirect()->to(base_url('post'));
        }

        $delete = $this->model->delete($id);

        if ($delete) {
            session()->setFlashdata('success', 'Post has been removed successfully.');
            return redirect()->to(base_url('post'));
        } else {
            session()->setFlashdata('error', 'Some problems occured, please try again.');
            return redirect()->to(base_url('post'));
        }

    }
}
```

Sekarang kita daftarkan route terakhir untuk menghapus data. Buka kembali file `app/Config/Routes.php`, lalu kita tambahkan route baru.

```php
$routes->delete('/post/destroy/(:num)', 'Post::destroy/$1');
```

## Step 11 Uji Coba Project {#step-11-testing-project}

Langkah terakhir dari tutorial ini kita coba running aplikasi kita, lalu kita cek satu persatu fitur yang sudah kita coding di langkah-langkah sebelumnya. Untuk running project kita, buka ```terminal``` atau ```cmd``` lalu jalankan *command* berikut ini:

```
php spark serve
```

Buka browser, lalu buka project kita di url ```http://localhost:8080```. Ya, tampilan yang pertama kali muncul adalah tampilan daftar post.

![Uji coba project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/crud/step-1.png)

Selanjutnya kita coba buat post baru, tekan tombol ```New Record``` yang ada di atas tabel post.

Ya, muncul tampilan post dan juga di sini kita gunakan ```summernote``` untuk menulis artikel baru.

![Uji coba project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/crud/step-2.png)

Nah sekarang kita coba ketik post baru, kita tulis bebas aja.

![Uji coba project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/crud/step-3.png)

Lalu kita tekan tombol ```save```.

Nah, ketika berhasil, project akan kembali ke halaman daftar post dan juga ada notifikasi post berhasil disimpan. ^^

![Uji coba project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/crud/step-4.png)

Selanjutnya kita coba tambahkan beberapa postingan sampai sebelas (11) postingan atau lebih. Yep, ketika data kita udah lebih dari sepuluh, kita bisa lihat adanya pagination di bawah table daftar post kita.

![Uji coba project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/crud/step-5.png)

Oke, selanjutnya kita coba perbaharui data salah satu post. Tekan tombol ```edit``` di salah satu data. Maka akan tampil halaman form untuk edit post.

Kita coba edit isi postnya dan statusnya kita coba ubah menjadi publish.

![Uji coba project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/crud/step-6.png)

Lalu kita tekan tombol ```update```. Nah ketika data berhasil diperbaharui, project kita akan menampilkan kembali daftar post dan juga ada notifikasi data post berhasil diperbaharui.

![Uji coba project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/crud/step-7.png)


Nah selanjutnya kita coba fitur terakhir, yaitu  hapus data post. Tekan tombol ```Delete``` di salah satu data post. Ketika tombol ```Delete``` ditekan, akan muncul pop up tulisan *'Kamu yakin?'*. Tekan tombol ```ok``` dan apabila data berhasil dihapus, project akan menampilkan kembali daftar post dan juga notifikasi bahwa datanya berhasil dihapus.

![Uji coba project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/crud/step-8.png)

![Uji coba project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/crud/step-9.png)


## Kesimpulan {#kesimpulan}

Dalam tutorial ini, kita telah mempelajari **cara membuat fitur CRUD (Create, Read, Update, Delete) menggunakan CodeIgniter 4**. Mulai dari instalasi dan konfigurasi framework, pembuatan database dengan **Migration**, hingga implementasi operasi CRUD menggunakan **Model**, kita telah membangun sebuah **aplikasi blog sederhana** yang memungkinkan pengguna untuk mengelola post dengan mudah.

#### **Poin-Poin Penting yang Telah Dipelajari:**
1. **Instalasi dan Konfigurasi CodeIgniter 4**: Kita belajar cara menginstal CodeIgniter 4 menggunakan Composer dan mengkonfigurasi environment project.
2. **Membuat Database dengan Migration**: Fitur Migration memudahkan kita dalam membuat dan mengelola struktur database secara terstruktur.
3. **Implementasi CRUD**: Kita berhasil membuat fitur untuk menampilkan daftar post, menambahkan post baru, memperbarui post, dan menghapus post.
4. **Templating UI**: Dengan menggunakan sistem layout CodeIgniter 4, kita dapat membuat tampilan UI yang konsisten dan mudah dikelola.
5. **Pagination**: Kita juga belajar cara menampilkan data dalam bentuk halaman menggunakan fitur pagination yang disediakan oleh CodeIgniter 4.

#### **Manfaat yang Didapat:**
- **Pemahaman Dasar CodeIgniter 4**: Tutorial ini memberikan fondasi yang kuat untuk memahami cara kerja CodeIgniter 4.
- **Keterampilan CRUD**: Anda sekarang memiliki kemampuan untuk mengimplementasikan operasi CRUD dalam aplikasi web.
- **Praktis dan Langsung Dapat Diterapkan**: Langkah-langkah yang dijelaskan dalam tutorial ini dapat langsung diaplikasikan dalam proyek nyata.

#### **Langkah Selanjutnya**
Jika Anda ingin mendalami lebih lanjut tentang CodeIgniter 4, jangan ragu untuk menjelajahi seri tutorial lainnya di [Belajar CodeIgniter 4](https://qadrlabs.com/series/belajar-codeigniter-4). Anda juga dapat mencoba mengembangkan aplikasi ini lebih lanjut, seperti menambahkan fitur autentikasi, validasi form, atau integrasi dengan library pihak ketiga.

Terima kasih telah mengikuti tutorial ini! Semoga panduan ini bermanfaat dan membantu Anda dalam perjalanan belajar pengembangan web dengan CodeIgniter 4. Selamat coding! 😊

Sampai jumpa lagi di [edisi tutorial](https://qadrlabs.com/post/seri-tutorial-codeigniter-4-membuat-fitur-login-dan-register) berikutnya... ^^

[^1]: Server Requirement @ [https://codeigniter4.github.io/userguide/intro/requirements.html](https://codeigniter4.github.io/userguide/intro/requirements.html) 
[^2]: Database Migration @ [https://codeigniter4.github.io/userguide/dbmgmt/migration.html](https://codeigniter4.github.io/userguide/dbmgmt/migration.html) 
[^3]: Model dan operasi CRUD di CodeIgniter 4 @ [https://codeigniter4.github.io/userguide/models/model.html#](https://codeigniter4.github.io/userguide/models/model.html#)