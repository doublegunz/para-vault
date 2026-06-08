---
title: "Tutorial Laravel: Membuat Fitur Generate dan Verifikasi QR Code"
slug: "tutorial-laravel-membuat-fitur-generate-dan-verifikasi-qr-code"
category: "Laravel"
date: "2024-08-16"
status: "published"
---

Dalam era digital saat ini, penggunaan QR Code semakin populer, terutama untuk keperluan verifikasi. Pada tutorial ini, kita akan membahas cara membuat fitur generate dan verifikasi QR Code menggunakan Laravel. Studi kasus yang diambil adalah pembuatan sertifikat peserta kursus yang dapat diverifikasi melalui QR Code. Dengan mengikuti langkah-langkah ini, kita akan dapat menghasilkan sertifikat dengan QR Code yang bisa diverifikasi melalui aplikasi Laravel.

## Overview{#overview}
Tutorial ini menjelaskan cara mengimplementasikan fitur generate dan verifikasi QR Code menggunakan Laravel 12. Dengan studi kasus pembuatan sertifikat peserta kursus yang dapat diverifikasi, tutorial ini mencakup langkah-langkah lengkap mulai dari:

1. Persiapan project Laravel baru
2. Instalasi library QR Code (simple-qrcode)
3. Pembuatan model dan migrasi database untuk sertifikat
4. Pembuatan controller untuk mengelola generate dan verifikasi QR Code
5. Pengaturan routing dan symlink storage
6. Pembuatan tampilan (views) untuk menampilkan, membuat, dan memverifikasi sertifikat
7. Implementasi logika untuk menghasilkan QR Code yang berisi URL verifikasi

![Preview Project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/qr-code/1-certificate-list.png)

Dengan mengikuti tutorial ini, pembaca dapat membuat sistem yang memungkinkan pembuatan sertifikat dengan QR Code yang dapat dipindai untuk memverifikasi keaslian sertifikat tersebut, menjamin keamanan dan kemudahan verifikasi dokumen penting.

## Step 1: Buat Project Laravel Baru{#step-1-buat-project-laravel-baru}
Pertama kita buat terlebih dahulu project laravel baru. Untuk membuat project laravel baru, buka terminal lalu run command berikut ini.
```bash
composer create-project --prefer-dist laravel/laravel laravel-qrcode
```
Tunggu sampai proses create project laravel selesai.

## Step 2: Instalasi Library QR Code{#step-2-instalasi-library-qr-code}
Setelah project Laravel siap, pindah ke direktori project:
```bash
cd laravel-qrcode
```

Untuk menghasilkan QR Code di Laravel, kita akan menggunakan library `simple-qrcode`. Instal library ini menggunakan Composer:
```bash
composer require simplesoftwareio/simple-qrcode
```

Setelah instalasi selesai, library ini siap digunakan untuk menghasilkan QR Code dalam project kita.

## Step 3: Buat Model dan Migrasi untuk Sertifikat{#step-3-buat-model-dan-migrasi-untuk-sertifikat}
Kita perlu membuat model dan migrasi untuk menyimpan data sertifikat peserta kursus. Jalankan command berikut untuk membuat model dan migrasi:
```bash
php artisan make:model Certificate -m
```

Output:

```
   INFO  Model [app/Models/Certificate.php] created successfully.  
   INFO  Migration [database/migrations/2024_08_16_020453_create_certificates_table.php] created successfully. 
```

Selanjutnya buka file migrasi yang baru dibuat di `database/migrations/` dan tambahkan kolom berikut:

```php
public function up()
{
    Schema::create('certificates', function (Blueprint $table) {
        $table->id();
        $table->string('participant_name');
        $table->string('course_name');
        $table->string('qr_code_path')->nullable();
        $table->timestamps();
    });
}
```

Setelah itu, jalankan migrasi untuk membuat tabel `certificates`:

```bash
php artisan migrate
```

Selanjutnya kita atur mass assignment untuk model `App\Models\Certificate`. Buka file model `app/Models/Certificate.php` dan tambahkan atribut `$fillable` sebagai berikut:

```php
protected $fillable = [
    'participant_name',
    'course_name',
    'qr_code_path'
];
```

## Step 4: Generate QR Code di Laravel{#step-4-generate-qr-code-di-laravel}
Selanjutnya, kita akan membuat class controller yang akan menangani manajemen sertifikat dengan nama `CertificateController`. Untuk membuat class `CertificateController`, buka terminal lalu run command berikut ini.

```bash
php artisan make:controller CertificateController
```

Output:

```
   INFO  Controller [app/Http/Controllers/CertificateController.php] created successfully.  
```

Buka `CertificateController` dan tambahkan beberapa metode untuk menampilkan daftar sertifikat, menambahkan sertifikat baru, berbagi QR Code, dan verifikasi QR Code:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Certificate;
use SimpleSoftwareIO\QrCode\Facades\QrCode;

class CertificateController extends Controller
{
    public function index()
    {
        $certificates = Certificate::all();
        return view('certificates.index', compact('certificates'));
    }

    public function create()
    {
        return view('certificates.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'participant_name' => 'required|string|max:255',
            'course_name' => 'required|string|max:255',
        ]);

        $certificate = Certificate::create([
            'participant_name' => $request->participant_name,
            'course_name' => $request->course_name,
        ]);

        $qrCodePath = 'qrcodes/' . $certificate->id . '.png';
        $fullPath = storage_path('app/public/' . $qrCodePath);

        // Cek apakah folder qrcodes sudah ada, jika belum buat folder tersebut
        if (!file_exists(dirname($fullPath))) {
            mkdir(dirname($fullPath), 0755, true);
        }

        QrCode::format('png')->size(200)->generate(route('certificates.verify', $certificate->id), $fullPath);

        $certificate->update(['qr_code_path' => $qrCodePath]);

        return redirect()->route('certificates.index')->with('success', 'Sertifikat berhasil dibuat dengan QR Code!');
    }

    public function shareQrCode($id)
    {
        $certificate = Certificate::find($id);

        if ($certificate) {
            $qrCodePath = $certificate->qr_code_path;
            return response()->download(storage_path('app/public/' . $qrCodePath));
        } else {
            return redirect()->route('certificates.index')->with('error', 'QR Code tidak ditemukan.');
        }
    }

    public function verify($id)
    {
        $certificate = Certificate::find($id);

        if ($certificate) {
            return view('certificates.verify', compact('certificate'));
        } else {
            return view('certificates.notfound');
        }
    }
}
```

Berikut adalah penjelasan untuk kode di atas:

### Kode Penjelasan

#### 1. **Controller Setup:**
   - **Namespace dan Penggunaan:**
     - Kode ini merupakan bagian dari Controller `CertificateController` di Laravel yang menggunakan `Request` untuk menangani input dari pengguna.
     - `Certificate` adalah model yang digunakan untuk menyimpan data sertifikat.
     - `QrCode` adalah library untuk menghasilkan QR Code.

#### 2. **Method `index`:**
   - Mengambil semua data sertifikat dari database menggunakan `Certificate::all()`.
   - Data sertifikat kemudian dikirim ke view `certificates.index` untuk ditampilkan.

#### 3. **Method `create`:**
   - Mengembalikan view `certificates.create` yang menampilkan form untuk membuat sertifikat baru.

#### 4. **Method `store`:**
   - Melakukan validasi data input dari form. Nama peserta dan nama kursus harus berupa string dan tidak boleh kosong.
   - Jika validasi berhasil, data sertifikat baru dibuat dan disimpan ke database.
   - QR Code dihasilkan menggunakan library `QrCode` dengan URL untuk verifikasi sertifikat, dan disimpan di direktori `storage/app/public/qrcodes/`.
   - Jika direktori `qrcodes/` belum ada, maka dibuat terlebih dahulu.
   - Lokasi file QR Code disimpan di kolom `qr_code_path` pada tabel `certificates`.
   - user kemudian diarahkan kembali ke halaman index sertifikat dengan pesan sukses.

#### 5. **Method `shareQrCode`:**
   - Mengambil data sertifikat berdasarkan ID.
   - Jika sertifikat ditemukan, file QR Code diunduh oleh pengguna.
   - Jika sertifikat tidak ditemukan, user diarahkan kembali ke halaman index sertifikat dengan pesan error.

#### 6. **Method `verify`:**
   - Mengambil data sertifikat berdasarkan ID.
   - Jika sertifikat ditemukan, halaman verifikasi `certificates.verify` ditampilkan dengan detail sertifikat.
   - Jika sertifikat tidak ditemukan, halaman `certificates.notfound` ditampilkan dengan pesan bahwa sertifikat tidak ditemukan.
   

Karena terdapat proses untuk menampilkan QR Code, kita perlu membuat symlink ke storage dengan command:

```bash
php artisan storage:link
```

## Step 5: Menambahkan Routing{#step-5-menambahkan-routing}
Tambahkan route untuk mengakses method di `CertificateController`. Buka file `routes/web.php` dan tambahkan rute berikut:

```php
use App\Http\Controllers\CertificateController;

Route::get('/certificates', [CertificateController::class, 'index'])->name('certificates.index');
Route::get('/certificates/create', [CertificateController::class, 'create'])->name('certificates.create');
Route::post('/certificates', [CertificateController::class, 'store'])->name('certificates.store');
Route::get('/certificates/verify/{id}', [CertificateController::class, 'verify'])->name('certificates.verify');
Route::get('/certificates/share/{id}', [CertificateController::class, 'shareQrCode'])->name('certificates.shareQrCode');
```

**Penjelasan:**

- **`/certificates`**: Menampilkan daftar semua sertifikat.
- **`/certificates/create`**: Menampilkan form untuk membuat sertifikat baru.
- **`/certificates/verify/{id}`**: Menampilkan halaman verifikasi sertifikat berdasarkan ID.
- **`/certificates/share/{id}`**: Mengunduh QR Code dari sertifikat.

## Step 6: Membuat View Layout dan Daftar Sertifikat{#step-6-membuat-view}
Selanjutnya, kita buat beberapa file view untuk menampilkan halaman yang diperlukan.

### Layouts{#layouts}

Buat file layout utama `resources/views/layouts/app.blade.php`:

```php
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Tutorial Laravel: Membuat Fitur Generate dan Verifikasi QR Code</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
</head>
<body>
<nav class="navbar navbar-expand-lg bg-body-tertiary">
    <div class="container-fluid">
        <a class="navbar-brand" href="{{ url('/') }}">qadrlabs</a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarSupportedContent">
            <ul class="navbar-nav ms-auto mb-2 mb-lg-0">
                <li class="nav-item">
                    <a class="nav-link" href="{{ url('/certificates') }}">Certificates</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="{{ url('/certificates/create') }}">Create Certificate</a>
                </li>
            </ul>
        </div>
    </div>
</nav>
<div class="container mt-4">
    @yield('content')
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
</body>
</html>
```

### Daftar Sertifikat{#daftar-sertifikat}
Selanjutnya kita buat file view `resources/views/certificates/index.blade.php` yang berfungsi untuk menampilkan daftar sertifikat:

```php
@extends('layouts.app')

@section('content')
    <div class="container">
        <h1>Daftar Sertifikat</h1>

        @if(session()->has('success'))
            <div class="alert alert-success">
                {{ session()->get('success') }}
            </div>
        @endif

        <table class="table">
            <thead>
                <tr class="text-center">
                    <th scope="col">Nama Peserta</th>
                    <th scope="col">Nama Kursus</th>
                    <th scope="col">QR CODE</th>
                    <th scope="col">Aksi</th>
                </tr>
            </thead>
            <tbody>
            @forelse ($certificates as $certificate)
                <tr class="text-center">
                    <td>{{ $certificate->participant_name }}</td>
                    <td>{{ $certificate->course_name }}</td>
                    <td>
                        <img src="{{ asset('storage/' . $certificate->qr_code_path) }}" alt="QR Code Sertifikat" width="100">
                    </td>
                    <td>
                        <a href="{{ route('certificates.shareQrCode', $certificate->id) }}" class="btn btn-primary">Unduh QR Code</a>
                    </td>
                </tr>
            @empty
                <tr>
                    <td class="text-center" colspan="4">Belum ada data sertifikat</td>
                </tr>
            @endforelse
            </tbody>
        </table>
    </div>
@endsection
```

## Step 7: Membuat View untuk Form Pembuatan Sertifikat{#step-7-membuat-view-untuk-form-pembuatan-sertifikat}

Selanjutnya, buat file view `resources/views/certificates/create.blade.php` untuk menampilkan form pembuatan sertifikat:

```php
@extends('layouts.app')

@section('content')
    <div class="container">
        <h1>Buat Sertifikat Baru</h1>

        @if ($errors->any())
            <div class="alert alert-danger">
                <ul>
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('certificates.store') }}" method="POST">
            @csrf
            <div class="mb-3">
                <label for="participant_name">Nama Peserta</label>
                <input type="text" class="form-control" id="participant_name" name="participant_name" required>
            </div>

            <div class="mb-3">
                <label for="course_name">Nama Kursus</label>
                <input type="text" class="form-control" id="course_name" name="course_name" required>
            </div>

            <button type="submit" class="btn btn-primary">Buat Sertifikat</button>
        </form>
    </div>
@endsection
```

## Step 8: Membuat View untuk Verifikasi Sertifikat{#step-8-membuat-view-untuk-verifikasi-sertifikat}

Buat file view `resources/views/certificates/verify.blade.php` untuk menampilkan halaman verifikasi sertifikat:

```php
@extends('layouts.app')

@section('content')
    <div class="container">
        <h1>Verifikasi Sertifikat</h1>

        <div class="card">
            <div class="card-body">
                <h2>Sertifikat Status: <span class="badge text-bg-success">Verified</span></h2>
                <table class="table table-bordered">
                    <tr>
                        <td>Nama Peserta</td>
                        <td>{{ $certificate->participant_name }}</td>
                    </tr>
                    <tr>
                        <td>Nama Kursus</td>
                        <td>{{ $certificate->course_name }}</td>
                    </tr>
                </table>
            </div>
        </div>
    </div>
@endsection
```

Buat juga file view `resources/views/certificates/notfound.blade.php` untuk menampilkan pesan jika sertifikat tidak ditemukan:

```php
@extends('layouts.app')

@section('content')
    <div class="container">
        <h1>Verifikasi Sertifikat</h1>

        <div class="card">
            <div class="card-body">
                <h2>Sertifikat Status: <span class="badge text-bg-danger">Not Found</span></h2>
            </div>
        </div>
    </div>
@endsection
```

## Step 9: Uji Coba{#step-9-uji-coba}
Jalankan server Laravel:
```bash
php artisan serve
```

Buka browser dan kunjungi alamat `http://localhost:8000/certificates` untuk melihat daftar sertifikat.
![Akses halaman daftar sertifikat](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/qr-code/1-certificate-list.png)
Gambar di atas adalah contoh tampilan daftar sertifikat setelah kita tambahkan data. Untuk menambahkan data, kita bisa klik link `Create Certificate`. Selanjutnya akan tampil halaman form untuk menambahkan data baru.
![Akses form untuk menambahkan data baru](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/qr-code/2-form-tambah-data.png)

Teman-teman bisa coba tambahkan sertifikat baru. Selanjutnya kita bisa coba verifikasi dengan mengakses link dengan scan qr code. Karena ini masih project di localhost, ketika kita scan akan mengarah ke `http://localhost:8000/certificates/verify/id-nya` dan kalau menggunakan hp kita perlu koneksi ke jaringan terlebh dahulu supaya dapat mengaksesnya. Jadi sebagai contoh verifikasi kita bisa langsung akses halaman `http://localhost:8000/certificates/verify/1` dan `1` itu adalah ID dari sertifikat.
![tes verifikasi sertifikat melalui qr code](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/qr-code/3-verifikasi-sertifikat.png)

## Conclusion{#conclusion}
Dalam tutorial ini, kita telah berhasil mengimplementasikan fitur generate dan verifikasi QR Code menggunakan Laravel. Melalui studi kasus pembuatan sertifikat peserta kursus, kita telah mempelajari bagaimana:

1. Membuat project Laravel dan mengintegrasikan library simple-qrcode
2. Menyiapkan struktur database dan model untuk menyimpan data sertifikat
3. Membuat controller dengan fungsi-fungsi untuk mengelola sertifikat dan QR Code
4. Menghasilkan QR Code yang berisi URL untuk verifikasi sertifikat
5. Membuat tampilan untuk melihat, menambah, dan memverifikasi sertifikat
6. Membangun sistem verifikasi yang memastikan keaslian sertifikat

Implementasi QR Code seperti ini sangat bermanfaat tidak hanya untuk verifikasi sertifikat, tetapi juga dapat diterapkan pada berbagai kasus lain seperti tiket event, kartu identitas, atau sistem presensi. Dengan memodifikasi logika bisnis dan tampilan sesuai kebutuhan, Anda dapat mengadaptasi tutorial ini untuk keperluan proyek lainnya.

Semoga tutorial ini bermanfaat dan dapat menjadi langkah awal bagi Anda untuk mengembangkan aplikasi dengan fitur QR Code yang lebih kompleks dan sesuai dengan kebutuhan bisnis Anda.