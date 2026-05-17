---
title: "Seri Tutorial CodeIgniter 4: Membuat Fitur Upload"
slug: "seri-tutorial-codeigniter-4-membuat-fitur-upload"
category: "CodeIgniter 4"
date: "2020-03-17"
status: "published"
---

Hallo! Sekarang kita sudah masuk edisi tutorial ke 3 dari Seri Tutorial [Belajar CodeIgniter 4](https://qadrlabs.com/series/belajar-codeigniter-4). Pada edisi kali ini kita akan membahas salah satu fitur yang sering digunakan, yaitu fitur upload. Pada fitur upload ini biasanya bisa kita gunakan untuk meng-upload berkas, gambar dan lain-lain. Karena studi kasus di edisi tutorial sebelumnya kita membuat sebuah manajemen content dan kebetulan belum ada fitur upload gambarnya. Jadi di edisi tutorial CodeIgniter 4 kali ini kita akan fokus membuat **fitur upload di CodeIgniter 4** dan studi kasus edisi kali ini adalah membuat sebuah galeri foto sederhana.

Di tutorial ini, kita akan mengembangkan sebuah galeri foto sederhana yang di dalamnya terdapat:

1. Halaman galeri yang menampilkan foto-foto yang sudah diupload sebelumnya, 
2. Fitur untuk upload foto.

Dari studi kasus ini, kita dapat mempelajari beberapa hal yang dapat dilakukan dalam pengembangan aplikasi menggunakan framework CodeIgniter 4, yaitu:

1. Bagaimana cara upload sebuah file di codeigniter 4.
2. Bagaimana cara memvalidasi file berdasarkan ekstensi maupun mime type.
3. Bagaimana cara menyimpan data file di database.
4. Bagaimana cara menampilkan data file dari database

Karena di tutorial upload CodeIgniter sebelumnya ada permintaan dari teman-teman untuk menambahkan fitur menyimpan data yang sudah diupload ke database, halaman galeri ini akan menampilkan foto-foto yang datanya diambil dari database. Jadi selain fitur upload, kita belajar juga bagaimana caranya menyimpan data dari file yang sudah kita upload ke database. Di akhir tutorial nanti kita dapat membandingkan antara proses save data untuk fitur upload dengan proses save data yang sebelumnya dibahas di [tutorial crud](https://qadrlabs.com/post/seri-tutorial-codeigniter-4-crud-codeigniter-4) edisi sebelumnya. 

Lalu, apa saja langkah-langkah dalam membuat fitur Upload di CodeIgniter 4? *Check this out, ya!*

**Daftar Isi**

1. [Step 1: Instalasi dan set up](#step-1-instalasi)
2. [Step 2: Konfigurasi Project](#step-2-konfigurasi)
3. [Step 3: Membuat Database](#step-3-create-database)
4. [Step 4: Membuat Table Images](#step-4-migration)
5. [Step 5: Membuat template UI](#step-5-template-ui)
6. [Step 6: Membuat Halaman Gallery Image](#step-6-create-gallery-image)
7. [Step 7: Membuat Fitur Upload Image Baru](#step-7-create-upload-feature)
8. [Step 8: Uji Coba Project](#step-8-test-project)
9. [Kesimpulan](#kesimpulan)


## Step 1: Instalasi dan set up {#step-1-instalasi}

Buka terminal atau cmd, lalu jalankan *command* berikut ini di terminal atau cmd:

```bash
composer create-project codeigniter4/appstarter image-gallery
```

Tunggu sampai proses instalasi CodeIgniter 4 selesai.

## Step 2: Konfigurasi Project {#step-2-konfigurasi}

Pada tahapan ini, kita akan mengatur konfigurasi terlebih dahulu. Untuk konfigurasi project, kita akan menggunakan file `.env`. File `.env` ini kita copy dari file `env` (tanpa titik) yang sudah ada di folder root project. Buka kembali terminal, lalu selanjutnya kita masuk ke folder project Image Gallery dengan *command*:

```bash
cd image-gallery
```

Kita copy file ```env``` dengan menggunakan *command* berikut ini:

```bash
cp env .env
```

Setelah kita run `command` di atas, kita bisa lihat ada file `.env`.

Selanjutnya buka project di text editor (di sini saya menggunakan Visual Studio Code). Untuk membuka project, jalankan *command* berikut ini di terminal:

```bash
code .
```

Atau bisa juga langsung buka text editornya, pilih menu `File`, pilih sub menu `Open Folder` dan selanjutnya pilih folder project. 

Selanjutnya buka file ```.env``` di text editor, lalu kita sesuaikan code untuk konfigurasi project kita:

```php
CI_ENVIRONMENT = development

app.baseURL = 'http://localhost:8080/'

database.default.hostname = localhost
database.default.database = db_gallery
database.default.username = root
database.default.password = passwordnyasql
database.default.DBDriver = MySQLi
```

Seperti biasa, untuk password kita sesuaikan dengan password mysql masing-masing. Jika menggunakan `xampp`, biasanya usernamenya itu `root` dan passwordnya kosong, jadi untuk password dikosongkan (tidak perlu diisi) seperti yang terlihat di baris kode konfigurasi di atas.

## Step 3: Membuat Database {#step-3-create-database}

Tahapan selanjutnya adalah membuat database untuk project kita. Untuk membuat database, kita bisa pakai phpmyadmin atau mau langsung dari terminal juga boleh. 
Sekarang kita buat database baru untuk project kita dengan nama ```db_gallery``` sesuai dengan nama database yang ada di file ```.env```. Untuk membuat database, buka ```phpMyAdmin``` (atau bisa menggunakan tool yang lain), lalu buat database dengan nama ```db_gallery```.

Nah database sudah selesai kita buat, selanjutnya kita akan membuat table.

## Step 4: Membuat Table Images {#step-4-migration}

Pada tahapan ini kita pakai fitur `migration` codeigniter 4 untuk membuat table. Buka kembali ```terminal``` atau ```cmd```, lalu jalankan `command` berikut ini untuk membuat file migration:

```bash
php spark make:migration Images
```

Output:

```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 11:33:59 UTC+00:00

File created: APPPATH/Database/Migrations/2024-05-08-113359_Images.php
```



Selanjutnya buka file migration di direktori ```app/Database/Migrations```, dan seperti yang sudah kita ketahui nama file migration akan beda tergantung timestamp ketika filenya dibuat, misalnya ```2024-05-08-113359_Images.php```. Buka file tersebut lalu sesuaikan kodenya...

```php
<?php namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class Images extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id' => [
                'type' => 'INT',
                'unsigned' => TRUE,
                'auto_increment' => TRUE
            ],
            'caption' => [
                'type' => 'VARCHAR',
                'constraint' => 100,
                'null' => FALSE
            ],
            'path' => [
                'type' => 'VARCHAR',
                'constraint' => 255,
                'null' => FALSE
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
        $this->forge->createTable('images');
    }

    //--------------------------------------------------------------------

    public function down()
    {
        $this->forge->dropTable('images');
    }
}

```

Selanjutnya kita jalankan *command* untuk ```migrate```:

```bash
php spark migrate
```

Output:

```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 11:36:04 UTC+00:00

Running all new migrations...
	Running: (App) 2024-05-08-113359_App\Database\Migrations\Images
Migrations complete.
```

Ketika selesai proses `migration`, kita bisa lihat ada table baru di database `db_gallery`.

## Step 5: Membuat template UI {#step-5-template-ui}

Untuk membuat template UI, kita buat folder baru di direktori ```app/Views``` dengan nama ```layouts```. Lalu selanjutnya kita buat file baru untuk template UI kita di folder yang baru saja kita buat (```app/Views/layouts```) dengan nama ```main.php```. Nah selanjutnya kita ketik baris kode di bawah ini...

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
    <p><em><small>Seri Tutorial CodeIgniter 4: Fitur Upload @ <a href="https://qadrlabs.com/">qadrlabs</a></small></em></p>  
</footer>  
<script src="https://code.jquery.com/jquery-3.4.1.slim.min.js" integrity="sha384-J6qa4849blE2+poT4WnyKhv5vZF5SrPo0iEjwBvKU7imGFAV0wwj1yYfoRSJoZ+n" crossorigin="anonymous"></script>  
<script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js" integrity="sha384-Q6E9RHvbIyZFJoft+2mJbHaEWldlvI9IOYy5n3zV9zzTtmI3UksdQRVvoxMfooAo" crossorigin="anonymous"></script>  
<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js" integrity="sha384-wfSDF2E50Y2D1uUdj0O3uMBJnjuUD4Ih7YwaYd1iqfktj0Uod8GCExl3Og8ifwB6" crossorigin="anonymous"></script>  
  
<?= $this->renderSection('extra-js') ?>  
  
</body>  
  
</html>
```

Oke, misalkan sudah ketik kodenya, jangan lupa save filenya.

## Step 6: Membuat Halaman Gallery Image {#step-6-create-gallery-image}

Halaman gallery image ini berfungsi untuk menampilkan gambar atau foto yang sudah kita upload sebelumnya. Data foto atau gambar ini kita ambil dari database lalu kita tampilkan di ```view```. Untuk mengambil data dari database kita perlu sebuah ```model```. Jadi kita buat file ```model``` dulu.

Sekarang kita buat file ```models``` baru dengan nama ```ImageModel.php```. Buka kembali terminal, lalu run command berikut ini.

```
php spark make:model ImageModel
```

Output:

```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 11:37:20 UTC+00:00

File created: APPPATH/Models/ImageModel.php
```





Di dalam file `Models/ImageModel.php`, kita sesuaikan beberapa atribute dari class `ImageModel` seperti baris kode berikut ini.

```php
<?php

namespace App\Models;

use CodeIgniter\Model;

class ImageModel extends Model
{
    protected $table = 'images';
    protected $allowedFields = ['caption', 'path'];

    protected $useTimestamps = true;
    protected $createdField = 'created_at';
    protected $updatedField  = 'updated_at';
}
```

Setelah selesai coding class model `ImageModel`, kita save kembali file  ```ImageModel.php```.

Untuk menangani semua proses yang berhubungan, dengan galeri, kita perlu sebuah controller. Kita buat controller baru dengan nama ```ImageController```. Sekarang kita buka kembali terminal, lalu run command berikut ini.

``` 
php spark make:controller ImageController
```

Output:

```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 11:39:56 UTC+00:00

File created: APPPATH/Controllers/ImageController.php
```

Setelah `Controllers/ImageController.php` kita generate, selanjutnya kita deklarasikan beberapa method untuk class `ImageController`, yaitu constructor dan method `index()`.

```php
<?php

namespace App\Controllers;

use App\Models\ImageModel;

class ImageController extends BaseController
{
    public function __construct()
    {
        $this->model = new ImageModel();
        $this->helpers = ['form', 'url'];
        
    }

    public function index()
    {
        $data = [
            'images' => $this->model->paginate(6),
            'pager' => $this->model->pager,
            'title' => 'Image Gallery - Seri Tutorial CodeIgniter 4: Fitur Upload @ qadrlabs.com'
        ];

        
        return view('images/index', $data);
    }
}
```

Jikalau sudah selesai ngetiknya, jangan lupa save file ```ImageController.php```.

Bisa kita lihat pada method ```index()``` menampilkan view ```images/index```, itu artinya selanjutnya kita membuat file ```index.php``` dan juga folder ```images```. Sekarang kita buat dulu folder ```images``` di direktori ```app/Views```. Lalu kita buat file ```index.php``` di dalam folder tersebuat (```app/Views/images```). Lalu kita ketik kode di bawah ini:

```html
<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>
<section class="jumbotron text-center bg-white">
    <div class="container">
        <h1 class="jumbotron-heading">Image Gallery</h1>
        <p class="lead text-muted">
            Collection of high quality images and pictures.
        </p>
        <p>
            <a href="<?php echo base_url('image/create'); ?>" class="btn btn-primary btn-sm my-2">
                Upload New Image
            </a>
        </p>
    </div>
</section>

<section class="gallery py-5 bg-light">
    <div class="container mt-5">
        <div class="row">
            <div class="col-md-12">

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


            </div>

            <?php if (!empty($images) && is_array($images)) { ?>
                <?php foreach ($images as $row) { ?>
                    <div class="col-md-4">
                        <div class="card mb-4 shadow">
                            <img src="<?php echo base_url('uploads/' . $row['path']); ?>" class="card-img-top" style="height: 300px; width:100%; object-fit: cover;">
                            <div class="card-body">
                                <p class="card-text">
                                    <?php echo $row['caption']; ?>
                                </p>
                                <div class="d-flex justify-content-between align-items-center">
                                    <div class="btn-group">
                                        <button class="btn btn-sm btn-outline-secondary">Like</button>
                                    </div>
                                    <small class="text-muted">
                                        <?php echo $row['created_at']; ?>
                                    </small>
                                </div>

                            </div>
                        </div>
                    </div>
                <?php } ?>
            <?php } else { ?>
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-body">
                            <h2 class="text-muted text-center">
                                No image found
                            </h2>
                            <p class="text-center">
                                <a href="<?php echo base_url('image/create'); ?>" class="btn btn-secondary btn-sm my-2">
                                    Ready to add some images?
                                </a>
                            </p>
                        </div>
                    </div>
                </div>

            <?php } ?>
            <div class="col-md-12">
                <?= $pager->links(); ?>
            </div>
        </div>
    </div>

</section>


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

Save file ```index.php```

Selanjutnya kita atur ```route```. Buka file ```app/Config/Routes.php```, lalu cari baris kode di bawah ini di bagian Route Definition (sekitar line 33).

```php
$routes->get('/', 'Home::index');
```

Lalu ubah kode tersebut menjadi:

```php
$routes->get('/', 'ImageController::index');
```

Tepat di bawah kode tersebut, tambahkan ```route``` untuk menampilkan halaman galeri foto:

```php
$routes->group('image', function($routes) {
    $routes->get('/', 'ImageController::index');
});

```


## Step 7: Membuat Fitur Upload Image Baru {#step-7-create-upload-feature}

Tahapan ini adalah pembahasan utama edisi tutorial kali ini, yaitu membuat fitur upload. Di tahapan ini kita akan membuat sebuah form untuk upload foto. Kita buka kembali controller ```ImageController.php```, lalu kita tambahkan method ```create()``` di dalam class `ImageController`.

```php
<?php

namespace App\Controllers;

use App\Models\ImageModel;

class ImageController extends BaseController
{
   
   // [...] Kode sebelumnya

    public function create()
    {
        $data = [
            'title' => 'Upload new image - Seri Tutorial CodeIgniter 4: Fitur Upload @ qadrlabs.com'
        ];

        return view('images/create', $data);
    }


}
```

Save kembali file ```ImageController.php```.

Selanjutnya kita buat file view baru untuk menampilkan form upload dengan nama ```create.php``` di direktori ```app/Views/images```. Selanjutnya kita ketik baris kode di bawah ini:

```html
<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>
<div class="container mt-5">
    <div class="row">
        <div class="col-md-12">
            <div class="card">
                <div class="card-header">
                    Upload New Image
                    <a href="<?php echo base_url('image'); ?>" class="btn btn-link btn-sm float-right">
                        Back
                    </a>
                </div>
                <div class="card-body">
                    <?php if (session()->getFlashdata('success')) { ?>
                        <div class="alert alert-success">
                            <?php echo session()->getFlashdata('success'); ?>
                        </div>
                    <?php } ?>

                    <?php if (session()->getFlashdata('error')) { ?>
                        <div class="alert alert-danger">
                            <?php foreach (session()->getFlashdata('error') as $field => $error) : ?>
                                <p><?= $error ?></p>
                            <?php endforeach ?>
                        </div>

                    <?php } ?>


                    <?= form_open_multipart('image'); ?>
                    <div class="form-group">
                        <label for="image">Image</label>
                        <input type="file" name="image" class="form-control">
                    </div>
                    <div class="form-group">
                        <label for="caption">Caption</label>
                        <textarea name="caption" id="" cols="30" rows="10" class="form-control"></textarea>
                    </div>
                    <div class="form-group">
                        <button class="btn btn-primary btn-sm">Upload</button>
                    </div>
                    <?= form_close(); ?>
                </div>
            </div>
        </div>
    </div>
</div>


<?= $this->endSection() ?>
```

Setelah selesai, save kembali file ```create.php```.

Untuk menangani proses upload, kita tambahkan method baru di controller kita. Buka kembali file controller ```ImageController.php```, lalu tambahkan method ```store()``` di dalam class ```ImageController```:

```php
    ... baris kode sebelumnya ...

    public function store()
    {
        if ($this->request->getMethod() !== 'POST') {
            return redirect('index');
        }

		$validationRule = [  
		    'image' => [  
		        'label' => 'Image File',  
		        'rules' => 'uploaded[image]'  
		            . '|is_image[image]'  
		            . '|mime_in[image,image/jpg,image/jpeg,image/gif,image/png,image/webp]'  
		            . '|max_size[image,1000]'  
		            . '|max_dims[image,4000,4000]',  
		    ],  
		];
        $validated = $this->validate($validationRule);

        if ($validated) {
            $caption = $this->request->getPost('caption');
            $image = $this->request->getFile('image');
            $filename = $image->getRandomName();
            $image->move(ROOTPATH . 'public/uploads', $filename);

            $uploadedImage = [
                'caption' => $caption,
                'path' => $image->getName()
            ];

            $save = $this->model->save($uploadedImage);
            if ($save) {
                return redirect()->to(base_url('image'))
                    ->with('success', 'Image uploaded');
            } else {
                session()->setFlashdata('error', $this->model->errors());
                return redirect()->back();
            }
            
        }
        
        session()->setFlashdata('error', $this->validator->getErrors());
        return redirect()->back();

        
    }

```

Sehingga keseluruhan file ```ImageController.php``` menjadi seperti baris kode di bawah ini.

```php
<?php  
  
namespace App\Controllers;  
  
use App\Controllers\BaseController;  
use App\Models\ImageModel;  
  
class ImageController extends BaseController  
{  
    public function __construct()  
    {  
        $this->model = new ImageModel();  
        $this->helpers = ['form', 'url'];  
  
    }  
  
    public function index()  
    {  
        $data = [  
            'images' => $this->model->paginate(6),  
            'pager' => $this->model->pager,  
            'title' => 'Image Gallery - Seri Tutorial CodeIgniter 4: Fitur Upload @ qadrlabs.com'  
        ];  
  
        return view('images/index', $data);  
    }  
  
    public function create()  
    {  
        $data = [  
            'title' => 'Upload new image - Seri Tutorial CodeIgniter 4: Fitur Upload @ qadrlabs.com'  
        ];  
  
        return view('images/create', $data);  
    }  
  
    public function store()  
    {  
        if ($this->request->getMethod() !== 'post') {  
            return redirect('index');  
        }  
  
        $validationRule = [  
            'image' => [  
                'label' => 'Image File',  
                'rules' => 'uploaded[image]'  
                    . '|is_image[image]'  
                    . '|mime_in[image,image/jpg,image/jpeg,image/gif,image/png,image/webp]'  
                    . '|max_size[image,1000]'  
                    . '|max_dims[image,4000,4000]',  
            ],  
        ];  
  
        $validated = $this->validate($validationRule);  
  
        if ($validated) {  
            $caption = $this->request->getPost('caption');  
            $image = $this->request->getFile('image');  
            $filename = $image->getRandomName();  
            $image->move(ROOTPATH . 'public/uploads', $filename);  
  
            $uploadedImage = [  
                'caption' => $caption,  
                'path' => $image->getName()  
            ];  
  
            $save = $this->model->save($uploadedImage);  
            if ($save) {  
                return redirect()->to(base_url('image'))  
                    ->with('success', 'Image uploaded');  
            } else {  
                session()->setFlashdata('error', $this->model->errors());  
                return redirect()->back();  
            }  
  
        }  
  
        session()->setFlashdata('error', $this->validator->getErrors());  
        return redirect()->back();  
  
    }  
}
```

Jangan lupa, save kembali file ```ImageController.php```.

Nah langkah terakhir, kita atur ```route``` untuk menampilkan form upload dan menangani proses upload. Buka kembali file ```app/Config/Routes.php```. Tambahkan route di dalam route grup untuk image.

```php
$routes->group('image', function($routes) {
    $routes->get('/', 'ImageController::index');
    $routes->get('create', 'ImageController::create'); //tambahkan kode ini
    $routes->post('/', 'ImageController::store'); //tambahkan kode ini
});
```

Setelah selesai menambahkan ```route```, save kembali file ```Routes.php```.

## Step 8: Uji Coba Project {#step-8-test-project}

Langkah terakhir di tutorial ini adalah menguji coba project kita. Untuk running project, buka kembali ```terminal``` lalu jalankan *command* berikut ini:

```bash
php spark serve
```

Buka browser kesayanganmu, lalu buka project di url ```http://localhost:8080```. Dan tampilan yang pertama kali muncul adalah halaman galeri foto, seperti yang terlihat di gambar ini.

![Uji Coba Project - halaman  galeri](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/upload/img-1.png)

Selanjutnya kita coba upload foto baru. Tekan tombol ```Upload New Image``` untuk masuk ke halaman form upload. Nah setelah tombol tersebut ditekan, aplikasi akan menampilkan form upload.


![Uji Coba Project - halaman form upload](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/upload/img-2.png)

Nah sekarang kita coba tambahkan foto baru dan tulisan untuk captionnya.

![Uji Coba Project - upload image baru](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/upload/img-3.png)

Nah selanjutnya kita coba upload dengan menekan tombol ```upload```. Apabila berhasil, browser akan menampilkan kembali halaman galeri dan juga tampil notifikasi bahwa foto berhasil diupload.

![Uji Coba Project - berhasil upload image baru](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/upload/img-4.png)

Kita bisa cek direktori ```public/uploads``` untuk melihat foto yang berhasil diupload. Selain itu kita juga bisa lihat data foto yang diupload di dalam database.

Nah sekarang kita coba tambahkan beberapa foto. Misalkan di sini saya tambahkan 6 foto lagi. Nah apabila semuanya berhasil diupload, kita bisa lihat terdapat pagination di bawah galeri foto.

![Uji Coba Project - tes pagination](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/upload/img-5.png)


## Kesimpulan {#kesimpulan}

Di edisi tutorial kali kita sudah belajar bagaimana caranya membuat fitur upload di CodeIgniter 4. Selain itu kita juga belajar bagaimana caranya menyimpan data foto yang telah kita upload ke dalam database, lalu kita tampilkan data tersebut di halaman galeri. 

Ada banyak yang bisa teman-teman kembangkan dari project ini, misalkan menambahkan fitur untuk hapus datanya atau bisa juga menambahkan fitur untuk menambahkan komentar di masing-masing foto, atau menambahkan fitur ```like``` seperti di sosial media.

Sampai jumpa lagi di edisi tutorial berikutnya... Semoga bermanfaat dan tetap semangat berkarya ya! ^^

.
.
.

Serial Tutorial CodeIgniter 4 ini berisi tentang tutorial pengembangan aplikasi menggunakan framework CodeIgniter 4. Selain untuk mengikat ilmu, serial ini juga dibuat agar saya dan teman-teman bisa sama-sama belajar.