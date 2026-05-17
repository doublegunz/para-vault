---
title: "Tutorial Laravel: Import Data Dari File Excel"
slug: "tutorial-laravel-import-data-dari-file-excel"
category: "Laravel"
date: "2024-08-03"
status: "published"
---

Mengimpor data dari file Excel ke dalam aplikasi Laravel dapat menjadi task yang sangat berguna, terutama jika kita bekerja dengan data yang besar atau data yang sering diperbarui. Dalam tutorial ini, kita akan membahas langkah-langkah untuk mengimpor data Excel ke Laravel 12 dengan menggunakan package `maatwebsite/excel`, di mana  package tersebut sudah kita gunakan di tutorial [Membuat Fitur Export Dengan Format Excel](https://qadrlabs.com/post/tutorial-laravel-membuat-fitur-export-dengan-format-excel).

## Persiapan{#persiapan}
Sebelum kita mulai, pastikan kita sudah memiliki:

- Project Laravel 12
- File Excel yang akan diimpor

Untuk file excel, teman-teman bisa akses di [sini](https://docs.google.com/spreadsheets/d/1rLzW23u977ILQUzqsD-sdzFpRjINTuz9/edit?usp=sharing&ouid=116412255805077435275&rtpof=true&sd=true), lalu download.

## Overview {#overview}
Pada tutorial kali ini, kita akan membuat project sederhana yang berisi form untuk upload file excel yang akan diimport. Setelah itu kita akan gunakan salah satu library untuk melakukan proses import data dari file excel lalu kita simpan ke dalam database. 

Sebagai studi kasus, data yang akan kita gunakan adalah data `student` yang memiliki field `nis`, `name` dan `email`.  Sebagai sample data, teman-teman bisa lihat di file excel yang sudah teman-teman download sebelumnya.


## Step 1: Instalasi Laravel Excel{#step-1}
**Laravel Excel** adalah package yang populer dan powerfull untuk bekerja dengan file Excel di Laravel. Kita akan menginstalnya menggunakan Composer.

```bash
composer require maatwebsite/excel
```

Setelah instalasi selesai, Laravel Excel akan otomatis terdaftar di dalam file `config/app.php`. Jika kita menggunakan Laravel versi terbaru, langkah ini bisa dilewati karena Laravel secara otomatis mengkonfigurasi package ini.

## Step 2: Konfigurasi Laravel Excel {#step-2}
Setelah menginstal package, kita perlu mempublikasikan konfigurasi dari Laravel Excel. Buka terminal, lalu kita run command berikut:

```bash
php artisan vendor:publish --provider="Maatwebsite\Excel\ExcelServiceProvider"
```

Ini akan membuat file konfigurasi di `config/excel.php` yang dapat kita sesuaikan sesuai kebutuhan.

## Step 3: Membuat Model dan Migrasi {#step-3}
Kita akan membuat model dan migrasi untuk tabel yang akan kita gunakan untuk menyimpan data yang diimpor. Seperti yang telah disebutkan sebelumnya kita akan mengimpor data `student` jadi kita buat model dan migration untuk table `student`. Buka terminal lalu run command berikut ini.

```bash
php artisan make:model Student -m
```

Output:

```
   INFO  Model [app/Models/Student.php] created successfully.  

   INFO  Migration [database/migrations/2024_08_03_072315_create_students_table.php] created successfully.
```


Ini akan membuat file model dan file migrasi. Selanjutnya, kita sesuaikan field yang diperlukan di file migration `database/migrations/2024_xx_xx_xxxxxx_create_students_table.php`.

```php
public function up(): void
{
    Schema::create('students', function (Blueprint $table) {
        $table->id();
        $table->string('nis')->unique();
        $table->string('name');
        $table->string('email')->unique();
        $table->timestamps();
    });
}
```

Jalankan migrasi untuk membuat tabel:

```bash
php artisan migrate
```


Selanjutnya buka file `app/Models/Student.php` , lalu kita tambahkan  attribute `$fillable`.

```
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    use HasFactory;

    protected $fillable = [
        'nis',
        'name',
        'email'
    ];
}

```

Simpan kembali file `app/Models/Student.php`.

## Step 4: Membuat Import Class{#step-4}
Selanjutnya kita akan membuat import class yang akan kita gunakan untuk menentukan bagaimana data dari file Excel diimpor ke database. Kita akan membuat kelas import untuk model `Student`.

```bash
php artisan make:import StudentsImport --model=Student
```

Output:

```
   INFO  Import [app/Imports/StudentsImport.php] created successfully. 
```

Selanjutnya kita buka file `app/Imports/UsersImport.php`. Kita perlu menambahkan logika untuk mengimpor data di file ini:

```php
<?php

namespace App\Imports;

use App\Models\Student;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;

class StudentsImport implements ToModel, WithHeadingRow
{
    public function model(array $row)
    {
        return new Student([
            'nis' => $row['nis'],
            'name' => $row['name'],
            'email' => $row['email'],
        ]);
    }
}
```

`WithHeadingRow` digunakan untuk menentukan bahwa file Excel memiliki baris header (header `nim`, `name` dan `email`).

## Step 5: Membuat Controller dan Route{#step-5}
Kita akan membuat controller untuk meng-handle upload dan import file Excel. Kita buka kembali terminal, lalu kita run command berikut untuk membuat controller:

```bash
php artisan make:controller StudentController
```

Output:

```
   INFO  Controller [app/Http/Controllers/StudentController.php] created successfully.  
```



Di dalam `StudentController`, tambahkan method untuk menampilkan form upload dan meng-handle upload dan import file Excel:

```php
<?php

namespace App\Http\Controllers;

use App\Imports\StudentsImport;
use Illuminate\Http\Request;
use Maatwebsite\Excel\Facades\Excel;

class StudentController extends Controller
{
    public function showImportForm()
    {
        return view('import');
    }

    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|mimes:xls,xlsx'
        ]);

        Excel::import(new StudentsImport(), $request->file('file'));

        return redirect()->back()->with('success', 'Data siswa berhasil di import');
    }
}

```

Selanjutnya kita tambahkan route untuk menampilkan form upload dan meng-handle request import di `routes/web.php`:

```php
Route::get('import-students', [\App\Http\Controllers\StudentController::class, 'showImportForm']);
Route::post('import-students', [\App\Http\Controllers\StudentController::class, 'import'])->name('student.import');
```


## Step 6: Membuat Form Upload{#step-6}
Selanjutnya kita buat file view `import.blade.php` untuk menampilkan form upload:

```html
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Tutorial import excel @ qadrlabs.com</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
</head>
<body>
<div class="container">
    <div class="card mt-3">
        <div class="card-body">
            <h1>Form import excel</h1>
            @if(session('success'))
                <div class="alert alert-success" role="alert">
                    {{ session('success') }}
                </div>
            @endif

            <form action="{{ route('student.import') }}" method="POST" enctype="multipart/form-data">
                @csrf
                <div class="mb-3">
                    <label for="file" class="form-label">File excel</label>
                    <input class="form-control" type="file" id="file" name="file" required>
                </div>

                <button type="submit" class="btn btn-primary">Import</button>
            </form>
        </div>
    </div>
</div>


<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
</body>
</html>

```

Save kembali file `import.blade.php`.

## Step 7: Uji Coba {#step-7}
Untuk menguji coba, kita run terlebih dulu project laravel kita. Buka kembali terminal, lalu run command berikut in.

```
php artisan serve
```

Sekarang, buka browser dan akses `http://127.0.0.1:8000/import-students`. Selanjutnya kita bisa coba upload file excel yang sudah kita download dan setelah itu kita bisa cek data di database.

## Kesimpulan{#kesimpulan}
Mengimpor data dari file Excel ke Laravel 12 dapat menjadi task yang mudah jika kita menggunakan package yang tepat dan mengikuti langkah-langkah yang benar. Dengan mengikuti tutorial ini, kita dapat mengimpor data dari file Excel ke dalam aplikasi Laravel dengan mudah dan efisien.