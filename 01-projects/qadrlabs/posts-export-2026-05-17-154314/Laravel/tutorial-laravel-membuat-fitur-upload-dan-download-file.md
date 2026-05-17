---
title: "Tutorial Laravel: Membuat Fitur Upload dan Download File"
slug: "tutorial-laravel-membuat-fitur-upload-dan-download-file"
category: "Laravel"
date: "2024-04-26"
status: "published"
---

Fitur upload dan download file merupakan fitur umum yang biasa kita temukan di aplikasi. Dengan menggunakan framework laravel, kita bisa dengan mudah mengembangkan fitur untuk mengupload pdf, gambar atau jenis file yang lainnya. Begitu pun dengan fitur untuk download, kita bisa dengan mudah menambahkan fitur tersebut. Di edisi tutorial laravel kali ini kita akan coba membuat dua fitur tersebut, yaitu fitur upload file dan download file.

## Overview{#overview}
Pada tutorial laravel ini kita akan membuat sebuah project sederhana, di mana project sederhana ini memiliki fitur untuk mengupload file, download file dan juga menampilkan daftar file yang berhasil kita upload.

Untuk fitur upload file, kita akan coba membatasi hanya file pdf dan docx saja yang bisa kita upload. Jadi di sini kita akan menerapkan validasi form untuk proses upload dengan mengecek tipe file yang diupload. Selain itu kita juga akan mengimplementasikan hasil belajar [CRUD laravel 12](https://qadrlabs.com/post/tutorial-crud-laravel-12-untuk-pemula), yaitu menyimpan data file yang diupload dan menampilkan di daftar file yang telah diupload.

Untuk fitur download file, kita akan coba menggunakan kembali nama original file sebagai nama file yang didownload.

**Keterangan:**
Tutorial laravel ini telah diupdate dan diujicoba menggunakan Laravel versi 12 per tanggal 19 Maret 2025.

## Step 1 - Setup Project{#step-1}
Pertama kita buat project laravel baru menggunakan composer. Sekarang kita buka terminal, lalu kita run command berikut ini.
```
composer create-project --prefer-dist laravel/laravel upload-download-example
```

Tunggu sampai proses install laravel selesai. Apabila proses install selesai, kita bisa buka project di code editor.

## Step 2 - Atur Konfigurasi Database{#step-2}
Selanjutnya kita atur konfigurasi database. Buka file `.env`, lalu sesuaikan menjadi seperti berikut ini.

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_belajar_laravel
DB_USERNAME=root
DB_PASSWORD=password
```

Seperti yang terlihat pada baris kode di atas, koneksi database yang kita gunakan adalah `mysql`. Untuk username dan password database sesuaikan dengan credentials mysql yang sudah teman-teman setting. Sedangkan nama database project bisa diisi bebas, sebagai contoh di sini kita gunakan nama `db_belajar_laravel`.

Jangan lupa save kembali file `.env`.

## Step 3 - Buat file model dan migration{#step-3}
Karena project kita berhubungan dengan file, kita akan buat table dengan nama `files`. Selanjutnya kita buat file model dan migration untuk table `files`. Buka kembali terminal, lalu run command berikut ini.
```
php artisan make:model File -m

```

Output:
```

   INFO  Model [app/Models/File.php] created successfully.  

   INFO  Migration [database/migrations/2024_04_26_071942_create_files_table.php] created successfully.  
```

File model dan migration berhasil kita generate. Sekarang buka file migration `database/migrations/2024_xx_xx_xxxxxx_create_files_table.php` di code editor, lalu modifikasi method `up()`.
```php
    public function up(): void
    {
        Schema::create('files', function (Blueprint $table) {
            $table->id();
            $table->string('original_name');
            $table->string('generated_name');
            $table->timestamps();
        });
    }

```

Setelah selesai, save kembali file migration.

Pada baris kode di atas, kita bisa lihat terdapat field `original_name` dan `generated_name`.  Seperti yang sudah disebutkan sebelumnya, kita akan gunakan nama original file ketika file didownload. Jadi kita tambahkan field `original_name` untuk menyimpan nama file yang diupload. Sedangkan untuk file yang disimpan distorage, kita akan simpan nama yang sudah dihash dan kita simpan di field `generated_name`.

Selanjutnya kita run command migration.
```
php artisan migrate
```

Apabila database belum kita buat, akan tampil warning yang ditampilkan di output terminal.
```
   WARN  The database 'db_belajar_laravel' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘


```
Di sini kita bisa buat database baru melalui command migration. Untuk membuat database baru, pilih Yes, lalu tekan enter untuk melanjutkan.

Output di terminal:
```
   WARN  The database 'db_belajar_laravel' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ Yes                                                          │
 └──────────────────────────────────────────────────────────────┘

   INFO  Preparing database.  

  Creating migration table ...................................... 53.83ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table .......................... 79.62ms DONE
  0001_01_01_000001_create_cache_table .......................... 33.49ms DONE
  0001_01_01_000002_create_jobs_table ........................... 61.35ms DONE
  2024_04_26_032944_create_files_table .......................... 15.68ms DONE

```

Database dan juga table sudah kita buat menggunakan migration command. 
Selanjutnya kita akan modifikasi file `app/Models/File.php` untuk menambahkan pengaturan mass assignment.

Sekarang kita buka file `app/Models/File.php`, lalu kita tambahkan `$fillable` properti untuk mengijinkan mass assignment ketika nanti kita tambahkan data baru.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class File extends Model
{
    use HasFactory;

    protected $fillable = [
        'original_name',
        'generated_name'
    ];
}


```

Save kembali file `app/Models/File.php`.

## Step 4 - Coding fitur view daftar file{#step-4}
Untuk menambahkan fitur baru, kita buat terlebih dahulu controller untuk menangani fitur-fitur tersebut. Buka kembali terminal, lalu run command berikut ini untuk membuat controller baru.

```
php artisan make:controller FileController --model=File --resource

```

Output di terminal:
```
   INFO  Controller [app/Http/Controllers/FileController.php] created successfully. 
```

Fitur pertama yang akan kita tambahkan adalah fitur untuk menampilkan daftar file yang terupload. Sekarang kita buka file `app/Http/Controllers/FileController.php` di code editor, lalu modifikasi method `index()`.

```php
<?php

namespace App\Http\Controllers;

use App\Models\File;
use Illuminate\Http\Request;

class FileController extends Controller
{

    public function index()
    {
        $files = File::latest()->paginate(10);
        return view('files.index', compact('files'));
    }

    // baris kode lainnya

}

```

Save kembali file `app/Http/Controllers/FileController.php`.

Method `index()` pada baris kode di atas kita gunakan sebagai method yang menangani permintaan untuk menampilkan halaman indeks atau daftar file. Di dalam method ini, kita menggunakan model `App\Models\File` untuk mengambil daftar file dari database, mengurutkannya berdasarkan tanggal terbaru, dan membaginya menjadi beberapa halaman (paginate). Kemudian, kita memasukkan daftar file tersebut ke dalam view `files.index` menggunakan method view(). Keyword `compact('files')` digunakan untuk mengirimkan variabel `$files` ke view dengan nama yang sama.

Selanjutnya kita buat file view baru, yaitu `resources/views/files/index.blade.php`. Lalu kita coding baris kode berikut ini.
```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>File Management - qadrlabs.com</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>

    <div class="container mt-5">
        <div class="row">
            <div class="col-md-12">
                <div>
                    <h4 class="text-center my-4">Tutorial Laravel 12: Upload dan Download File @ <a href="https://qadrlabs.com">qadrlabs.com</a></h4>
                </div>
                <div class="card rounded">
                    <div class="card-body">
                        <a href="{{ route('files.create') }}" class="btn btn-md btn-primary mb-3 float-end">Upload File</a>
                        <table class="table table-bordered">
                            <thead>
                                <tr>
                                    <th scope="col">Nama File</th>
                                    <th scope="col" style="width: 20%">Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse ($files as $file)
                                    <tr>
                                        <td>{{ $file->original_name }}</td>
                                        <td class="text-center">
                                        <a href="{{ route('files.download', $file) }}" class="btn btn-sm btn-primary">Download</a>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="2" class="text-muted text-center">Data file belum tersedia</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                        {{ $files->links() }}
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
```

Setelah selesai save kembali file `resources/views/files/index.blade.php`.

Seperti yang terlihat pada baris kode di atas, kita menggunakan Bootstrap 5 untuk tampilan project kita. Karena secara default laravel 12 menggunakan tailwindcss, jadi kita perlu menyesuaikan tampilan paginationnya. Buka file `app/Providers/AppServiceProvider.php`, lalu tambahkan baris kode berikut ini.

```php
<?php

// baris kode lainnya

use Illuminate\Pagination\Paginator; // tambahkan kode ini

class AppServiceProvider extends ServiceProvider
{
    // baris kode lainnya

    public function boot(): void
    {
        Paginator::useBootstrapFive(); // tambahkan kode ini
    }
}

```
Pada baris kode diatas, kita gunakan bootstrap 5 untuk tampilan paginator.

## Step 5 - Coding fitur upload file{#step-5}
Selanjutnya kita akan menambahkan fitur untuk upload file. Buka kembali file controller `app/Http/Controllers/FileController.php`, lalu kita modifikasi method `create()`.

```php
<?php

namespace App\Http\Controllers;

use App\Models\File;
use Illuminate\Http\Request;

class FileController extends Controller
{
    // baris kode lainnya

    public function create()
    {
        return view('files.create');
    }

    // baris kode lainnya

}

```

Method `create()` kita gunakan sebagai method yang menangani request untuk menampilkan form upload file baru. 

Selanjutnya kita buat file view baru, yaitu `resources/views/files/create.blade.php`. Di sini kita tambahkan form untuk upload file.

```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Upload File Baru - qadrlabs.com</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>

    <div class="container mt-5">
        <div class="row">
            <div class="col-md-12">
                <div>
                    <h4 class="text-center my-4">Tutorial Laravel 12: Upload dan Download File @ <a href="https://qadrlabs.com">qadrlabs.com</a></h4>
                </div>
                <a href="{{ route('files.index') }}" class="btn btn-md btn-link mb-3">Back</a>

                <div class="card rounded">
                    <div class="card-body">

                        <form action="{{ route('files.store') }}" method="POST" enctype="multipart/form-data">
                        
                            @csrf

                            <div class="form-group mb-3">
                                <label class="font-weight-bold">File</label>
                                <input type="file" class="form-control @error('file') is-invalid @enderror" name="file">
                            
                                <!-- error message untuk image -->
                                @error('file')
                                    <div class="alert alert-danger mt-2">
                                        {{ $message }}
                                    </div>
                                @enderror
                            </div>


                            <button type="submit" class="btn btn-md btn-primary me-3">Upload</button>

                        </form> 
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
```

Save kembali file view `resources/views/files/create.blade.php`.

Selanjutnya kita modifikasi method `store()` di `app/Http/Controllers/FileController.php` untuk menangani proses upload file.
```php
<?php

namespace App\Http\Controllers;

use App\Models\File;
use Illuminate\Http\Request;

class FileController extends Controller
{
    // baris kode lainnya

    public function store(Request $request)
    {
        $request->validate([
            'file' => 'required|mimes:docx,pdf|max:2048'
        ]);

        $file = $request->file('file');
        $fileName = $file->hashName();
        $file->storeAs('uploads', $fileName);

        File::create([
            'original_name' => $file->getClientOriginalName(),
            'generated_name' => $fileName
        ]);

        return redirect()
            ->route('files.index')
            ->with('success', 'File berhasil diupload');
    }

    // baris kode lainnya

}

```

Pada baris kode di atas, method `store()` adalah method yang menangani proses penyimpanan (upload) file yang dikirim melalui form upload. Di dalam method ini, kita melakukan validasi terhadap input yang diterima menggunakan method `validate()` untuk memastikan bahwa file yang diunggah memenuhi persyaratan yang ditentukan, yaitu `pdf` dan `docx`. Setelah itu, kita mengambil file yang diupload dari request menggunakan `$request->file('file')`. Kemudian, kita tentukan nama file yang akan disimpan menggunakan `hashName()` untuk memastikan bahwa nama file yang diupload unik. Selanjutnya, kita menyimpan file tersebut ke dalam storage yang telah ditentukan menggunakan `storeAs()`. Setelah file berhasil disimpan, kita membuat entri baru dalam tabel `files` dengan menggunakan model `File` dan method `create()`. Terakhir, kita mengarahkan pengguna kembali ke halaman indeks file (`files.index`) dengan pesan notifikasi bahwa file berhasil diupload menggunakan `redirect()->route()->with()`.

## Step 6 - Coding fitur download file{#step-6}
Untuk menambahkan fitur download file, buka kembali file controller `app/Http/Controllers/FileController.php`. Kemudian kita tambahkan method baru `download()` yang menangani proses download file yang telah kita upload sebelumnya.
```php
<?php

namespace App\Http\Controllers;

use App\Models\File;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage; // tambahkan ini

class FileController extends Controller
{

    //baris kode lainnya

    public function download(File $file)
    {
        if (Storage::exists('uploads/' . $file->generated_name)) {
            // Unduh file dengan nama asli yang ditentukan
            return Storage::download('uploads/' . $file->generated_name, $file->original_name);
        } else {
            // Kembalikan error 404 jika file tidak ditemukan
            abort(404);
        }
    }

}

```

Apabila telah selesai, save kembali file controller.

Method `download()` dalam class `FileController` digunakan untuk proses download file yang telah diupload sebelumnya. Pada method tersebut kita gunakan alur berikut ini.
1. Memastikan file yang diminta untuk di download menggunakan `if (Storage::exists('uploads/' . $file->generated_name))`.
2. Mengirim file tersebut ke pengguna dengan nama asli file tersebut menggunakan function download `Storage::download()`.
3. Menampilkan pesan error jika file tidak ditemukan.

## Step 7 - Definisikan Route baru{#step-7}
Coding fitur utama telah selesai, langkah selanjutnya adalah mendefinisikan beberapa route baru. 

Buka file `routes/web.php`, lalu kita definisikan beberapa route baru.

```php
<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// tambahkan route baru
Route::get('/files', [App\Http\Controllers\FileController::class, 'index'])
    ->name('files.index');

Route::get('/files/create', [App\Http\Controllers\FileController::class, 'create'])
    ->name('files.create');

Route::post('/files/store', [App\Http\Controllers\FileController::class, 'store'])
    ->name('files.store');

Route::get('/files/{file}/download', [App\Http\Controllers\FileController::class, 'download'])
    ->name('files.download');
```

Save kembali file `routes/web.php`.

## Step 8 - Uji coba{#step-8}
Untuk uji coba, kita run terlebih dahulu project kita.
```
php artisan serve
```

Setelah itu kita akses `http://127.0.0.1:8000/files` di browser. Di sini kita bisa lihat halaman daftar file yang nantinya kita upload.

![Akses halaman daftar file](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/upload-download-file/gambar-1-run-akses-halaman-daftar-file.png)

Selanjutnya kita klik button Upload File, untuk masuk ke halaman upload file.
![Akses halaman upload file](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/upload-download-file/gambar-2-akses-halaman-upload-file.png)

Kita coba pilih sample file untuk kita upload, kemudian kita klik button Upload untuk memulai proses upload.
![File berhasil diupload](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/upload-download-file/gambar-3-file-berhasil-diupload.png)

Kita bisa lihat ada file baru yang berhasil kita upload.

Sekarang kita klik button download, untuk download file yang sudah kita upload sebelumnya. Akan muncul popup untuk memilih lokasi untuk menyimpan file yang akan kita download.
![Pilih lokasi simpan file](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/upload-download-file/gambar-4-pilih-lokasi-untuk-simpan-file.png)

Kita bisa lihat file berhasil kita download dengan nama original file.
![File berhasil didownload](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/upload-download-file/gambar-5-file-berhasil-didownload.png)

**Catatan:**
Pada saat uji coba menggunakan Laravel 12, file diupload ke direktori `storage/app/private/` berbeda dengan versi sebelumnya yang masuk ke direktori `storage/app/public`. Setelah dieksplore, kita bisa sesuaikan pengaturan value `FILESYSTEM_DISK` di file `.env`.
- Untuk masuk ke direktori `storage/app/private/`, kita set value `local` untuk variable `FILESYSTEM_DISK`.
- Untuk masuk ke direktori `storage/app/public/`, kita set value `public` untuk variable `FILESYSTEM_DISK`.

## Penutup{#penutup}
Pada tutorial laravel ini kita sudah coba kembangkan project sederhana dengan fitur untuk mengupload file, download file dan menampilkan daftar file yang telah diupload. Pada proses upload file kita implementasikan form validation untuk membatasi tipe data tertentu saja yang dapat diupload. Selain itu kita juga sudah coba mengimplementasikan hasil belajar CRUD laravel untuk menyimpan data dan juga menampilkan data. Di sini kita simpan nama original file yang kita gunakan sebagai nama file yang akan kita download.