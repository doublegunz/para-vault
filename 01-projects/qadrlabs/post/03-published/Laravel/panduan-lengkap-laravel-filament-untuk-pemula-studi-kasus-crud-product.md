---
title: "Panduan Lengkap Laravel Filament untuk Pemula: Studi Kasus CRUD Product"
slug: "panduan-lengkap-laravel-filament-untuk-pemula-studi-kasus-crud-product"
category: "Laravel"
date: "2025-01-20"
status: "published"
---

## Introduction {#introduction}
Membangun aplikasi dengan fitur CRUD bisa menjadi pekerjaan yang melelahkan, terutama jika kita harus mengembangkan semuanya dari awal—mulai dari desain form, validasi data, hingga pembuatan tabel untuk menampilkan informasi. Banyak developer sering merasa kewalahan ketika harus mengelola antarmuka admin yang kompleks, apalagi jika aplikasi tersebut memerlukan tampilan yang rapi dan interaksi data yang lancar.

Tanpa alat bantu yang tepat, membangun antarmuka admin untuk mengelola data seperti produk dapat memakan waktu lama dan rawan kesalahan. Kebutuhan untuk membuat form input yang aman, tabel dinamis, hingga fitur unggah gambar sering kali membutuhkan baris kode yang tak sedikit. Ini tentu menambah kerumitan jika kita mengembangkan proyek dalam waktu terbatas.

Tapi jangan khawatir! Tutorial ini akan menunjukkan kepada kita cara menggunakan **Filament**—sebuah library admin panel untuk Laravel yang dirancang untuk menyederhanakan proses pengembangan. Dengan Filament, kita dapat membuat antarmuka CRUD yang canggih, cepat, dan mudah dipelihara. Kita akan membangun sistem manajemen produk yang dilengkapi fitur input data, pengeditan, penghapusan, hingga unggah gambar hanya dengan beberapa langkah sederhana. Yuk, kita mulai perjalanan ini!



## Apa itu Filament? {#apa-itu-filament}

Filament adalah sebuah toolkit berbasis Laravel yang dirancang untuk mempercepat pembangunan panel admin dan dashboard modern. Sebagai solusi open-source, Filament membawa pendekatan yang unik dalam mengatasi kompleksitas pembuatan antarmuka administrasi dengan menyediakan komponen-komponen yang dapat langsung digunakan (pre-built components) namun tetap mempertahankan fleksibilitas untuk kustomisasi.

### Karakteristik Utama

1. **Arsitektur Berbasis Komponen**
   - Menyediakan koleksi lengkap komponen UI yang telah dioptimasi
   - Komponen dapat disusun dan dikonfigurasi dengan mudah
   - Mendukung pengembangan komponen kustom

2. **Sistem Form yang Powerful**
   - Form builder dengan validasi otomatis
   - Mendukung berbagai tipe input kompleks
   - Penanganan upload file yang terintegrasi
   - Validasi real-time dan pesan error yang informatif

3. **Manajemen Data yang Fleksibel**
   - Tabel interaktif dengan fitur sorting dan filtering
   - Sistem relasi database yang mudah dikonfigurasi
   - Dukungan untuk operasi bulk actions
   - Pagination dan pencarian yang dioptimasi

4. **Keamanan dan Otorisasi**
   - Sistem autentikasi yang terintegrasi dengan Laravel
   - Manajemen izin berbasis peran (role-based permissions)
   - Proteksi CSRF bawaan
   - Logging aktivitas pengguna

5. **Performa dan Optimisasi**
   - Lazy loading untuk komponen berat
   - Caching bawaan untuk query database
   - Minifikasi asset otomatis
   - Responsif dan mobile-friendly

### Keunggulan Menggunakan Filament

1. **Kecepatan Development**
   - Mengurangi waktu development hingga 70%
   - Eliminasi kode boilerplate yang berulang
   - Setup cepat untuk fitur-fitur umum

2. **Maintainability**
   - Struktur kode yang terorganisir
   - Dokumentasi yang komprehensif
   - Komunitas yang aktif dan supportive

3. **Skalabilitas**
   - Mudah diperluas sesuai kebutuhan
   - Mendukung aplikasi dari skala kecil hingga enterprise
   - Dapat diintegrasikan dengan berbagai service eksternal

Dengan Filament, developer dapat fokus pada logika bisnis dan kebutuhan spesifik aplikasi, tanpa perlu menghabiskan waktu untuk membangun komponen-komponen dasar interface admin. Framework ini ideal untuk proyek-proyek yang membutuhkan panel admin yang robust namun tetap ingin mempertahankan fleksibilitas dalam pengembangan.



## Overview {#overview}

Pada tutorial ini, kita akan membangun sebuah aplikasi **CRUD (Create, Read, Update, Delete)** menggunakan framework **Laravel** yang dipadukan dengan **Filament**, sebuah library admin panel yang powerful dan modern. Aplikasi ini akan mencakup fitur pengelolaan produk yang mencakup informasi seperti kode produk, nama produk, harga, stok, dan gambar. Dengan tampilan antarmuka yang sederhana dan elegan, Filament memungkinkan kita untuk membuat sistem manajemen data dengan cepat tanpa harus membuat segalanya dari nol.

**Apa yang Akan Dibuild?**

- Sebuah aplikasi CRUD berbasis Laravel untuk mengelola data produk.
- Admin panel berbasis **Filament** untuk mempermudah pengelolaan data.
- Fitur unggah gambar produk yang terintegrasi dengan sistem penyimpanan Laravel.

**Apa yang Akan Dipelajari?**

- Bagaimana cara mengatur konfigurasi database di Laravel.
- Cara membuat model dan migration untuk tabel produk.
- Langkah-langkah menjalankan migrasi database untuk membangun struktur tabel.
- Instalasi dan konfigurasi **Filament** untuk membuat admin panel.
- Cara menambahkan form input dengan validasi menggunakan schema form dari Filament.
- Pembuatan tabel dinamis dengan kolom dan aksi menggunakan komponen **Table** dari Filament.
- Implementasi fitur **file upload** untuk menyimpan gambar produk ke dalam sistem.

**Apa Goal dari Tutorial Ini?**

- Memberikan pemahaman praktis tentang bagaimana mengintegrasikan Laravel dengan Filament untuk membangun sistem CRUD yang fungsional.
- Membantu developer pemula maupun menengah memahami proses pembangunan aplikasi dengan pendekatan modular dan efisien.
- Menyelesaikan sebuah studi kasus nyata yang dapat dikembangkan menjadi aplikasi yang lebih kompleks di masa depan.

Dengan mengikuti tutorial ini, kita akan mendapatkan fondasi yang kuat dalam membangun aplikasi berbasis Laravel dan mengelola data secara efisien menggunakan admin panel Filament. Mari kita mulai!

------

## Persiapan Awal {#persiapan-awal}

Sebelum kita mulai, pastikan kita memiliki:

- PHP versi 8.2 atau lebih baru.
- Composer.
- MySQL atau database kompatibel lainnya.



## Step 1: Membuat Proyek Laravel {#step-1-membuat-proyek-laravel}

Step pertama adalah membuat proyek Laravel baru. Buka terminal, dan run command berikut:

```
composer create-project --prefer-dist laravel/laravel crud-filament-example
```

Setelah selesai, kita pindah ke direktori proyek:

```
cd crud-filament-example
```



## Step 2: Mengatur Konfigurasi Database {#step-2-mengatur-konfigurasi-database}

Buka file `.env` di direktori proyek kita dan ubah app url dan konfigurasi database seperti berikut:

```
APP_URL=http://127.0.0.1:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_filament
DB_USERNAME=root
DB_PASSWORD=password
```

Save kembali file `.env`.

------

## Step 3: Membuat Model dan Migration {#step-3-membuat-model-dan-migration}

Selanjutnya, kita akan membuat model `Product` dengan migration untuk tabelnya:

```
php artisan make:model Product -m
```

Output:

```
   INFO  Model [app/Models/Product.php] created successfully.  

   INFO  Migration [database/migrations/2025_01_20_134316_create_products_table.php] created successfully.  

```



### Menyesuaikan File Migration dan Model

Buka file migration yang baru dibuat di folder `database/migrations`, yaitu `database/migrations/xxxx_xx_xx_xxxxxx_create_products_table.php`, lalu ubah kodenya menjadi:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('code');
            $table->string('name');
            $table->string('image');
            $table->integer('price');
            $table->integer('stock');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
```

Selanjutnya buka file `app/Models/Product.php`, lalu kita tambahkan atribute `$fillable`.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    protected $fillable = [
        'code',
        'name',
        'image',
        'price',
        'stock',
    ];
}

```



## Step 4: Menjalankan Migrasi {#step-4-menjalankan-migrasi}

Setelah menyesuaikan migration, jalankan perintah berikut untuk membuat tabel di database kita:

```
php artisan migrate
```

Apabila kita belum membuat database sesuai dengan yang kita atur di file `.env`, akan tampil prompt untuk membuat database baru.

```
   WARN  The database 'db_filament' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘

```

Pilih `yes`, lalu tekan `enter` untuk melanjutkan.

```
   WARN  The database 'db_filament' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ Yes                                                          │
 └──────────────────────────────────────────────────────────────┘

   INFO  Preparing database.  

  Creating migration table ...................................... 39.95ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table ......................... 135.35ms DONE
  0001_01_01_000001_create_cache_table .......................... 56.49ms DONE
  0001_01_01_000002_create_jobs_table .......................... 145.16ms DONE
  2025_01_20_134316_create_products_table ....................... 31.10ms DONE


```



## Step 5: Instalasi Filament {#step-5-instalasi-filament}

Laravel Filament adalah inti dari tutorial ini. Instal package dengan perintah berikut:

```
composer require filament/filament:"^3.2" -W
```

```
$ composer require filament/filament:"^3.2" -W
./composer.json has been updated
Running composer update filament/filament --with-all-dependencies
.
.
.
```

Seperti yang terlihat pada output yang ditampilkan, kita install package dengan semua dependensi karena kita menambahkan `-W`.

Setelah selesai, jalankan instalasi Filament dengan perintah:

```
php artisan filament:install --panels
```

Ketika tampil prompt berikut ini

```
$ php artisan filament:install --panels

 ┌ What is the ID? ─────────────────────────────────────────────┐
 │ admin                                                        │
 └──────────────────────────────────────────────────────────────┘

```

Tekan `enter` untuk melanjutkan.

Output:

```
$ php artisan filament:install --panels

 ┌ What is the ID? ─────────────────────────────────────────────┐
 │ admin                                                        │
 └──────────────────────────────────────────────────────────────┘

   INFO  Filament panel [app/Providers/Filament/AdminPanelProvider.php] created successfully.  

   WARN  We've attempted to register the AdminPanelProvider in your [bootstrap/providers.php] file. If you get an error while trying to access your panel then this process has probably failed. You can manually register the service provider by adding it to the array.  
```

Selanjutnya kita bisa lihat ada providers baru `app/Providers/Filament/AdminPanelProvider.php` yang ditambahkan ke `bootstrap/providers.php`.



## Step 6: Membuat Admin User {#step-6-membuat-admin-user}

Untuk mengakses panel admin Filament, kita perlu membuat pengguna admin. Gunakan perintah berikut:

```
php artisan make:filament-user
```

Masukkan informasi seperti nama, email, dan password sesuai instruksi di terminal.

Output:

```
$ php artisan make:filament-user

 ┌ Name ────────────────────────────────────────────────────────┐
 │ admin                                                        │
 └──────────────────────────────────────────────────────────────┘

 ┌ Email address ───────────────────────────────────────────────┐
 │ admin@qadrlabs.com                                           │
 └──────────────────────────────────────────────────────────────┘

 ┌ Password ────────────────────────────────────────────────────┐
 │ ••••••••                                                     │
 └──────────────────────────────────────────────────────────────┘

   INFO  Success! admin@qadrlabs.com may now log in at http://127.0.0.1:8000/admin/login. 
```



Selanjutnya kita bisa coba run project.

```
php artisan serve
```

Lalu kita bisa coba akses `http://127.0.0.1:8000/admin/login` untuk login ke admin panel. Masukan email dan password di form login dan ketika berhasil login kita bisa lihat halaman dashboard filament.

![akses admin panel filament](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/filament/crud-filament/1-akses-admin-panel.png)



## Step 7: Membuat Product Resource {#step-7-membuat-product-resource}

Sekarang kita akan membuat CRUD resource untuk produk. Jalankan perintah berikut:

```
php artisan make:filament-resource Product --generate --view
```

Filament akan membuat beberapa file:

- **ProductResource.php**: File utama untuk mengelola resource produk.
- **Pages Folder**: Berisi file untuk halaman CRUD seperti create, edit, dan view.



## Step 8: Menambahkan Schema Form {#step-8-menambahkan-schema-form}

Buka file `app/Filament/Resources/ProductResource.php`, lalu sesuaikan metode `form` untuk menambahkan input form:

```php
public static function form(Form $form): Form
{
    return $form
        ->schema([
            Forms\Components\TextInput::make('code')
                ->required()
                ->maxLength(255)
                ->unique(Product::class, 'code'),
            Forms\Components\TextInput::make('name')
                ->required()
                ->maxLength(255),
            Forms\Components\FileUpload::make('image')
                ->image()
                ->required(),
            Forms\Components\TextInput::make('price')
                ->required()
                ->numeric()
                ->prefix('Rp'),
            Forms\Components\TextInput::make('stock')
                ->required()
                ->numeric(),
        ]);
}
```



## Menambahkan Kolom Tabel {#step-9-menambahkan-kolom-tabel}

Untuk menampilkan data produk di tabel admin, tambahkan kolom di metode `table`:

```php
public static function table(Table $table): Table
{
    return $table
        ->columns([
            Tables\Columns\ImageColumn::make('image')->disk('public'),
            Tables\Columns\TextColumn::make('code')
                ->searchable(),
            Tables\Columns\TextColumn::make('name')
                ->searchable(),
            Tables\Columns\TextColumn::make('price')
                ->money()
                ->sortable(),
            Tables\Columns\TextColumn::make('stock')
                ->numeric()
                ->sortable(),
        ])
        ->filters([
            //
        ])
        ->actions([
            Tables\Actions\ViewAction::make(),
            Tables\Actions\EditAction::make(),
        ])
        ->bulkActions([
            Tables\Actions\BulkActionGroup::make([
                Tables\Actions\DeleteBulkAction::make(),
            ]),
        ]);
}
```

Save kembali file `app/Filament/Resources/ProductResource.php`.

Karena terdapat gambar yang akan ditampilkan pada table, kita harus membuat symbolic link (symlink) dari direktori `storage/app/public` ke direktori `public/storage`.

```
php artisan storage:link
```

Output:

```
$ php artisan storage:link

   INFO  The [public/storage] link has been connected to [storage/app/public].
```



## Uji Coba {#uji-coba}

Setelah kita tambahkan Product Resource, kita bisa langsung uji coba fitur crud untuk mengelola data produk. Kita bisa langsung akses halaman daftar product dengan klik menu `Products` yang secara otomatis ditambahkan pada saat kita generate Product Resources.

![akses halaman daftar product](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/filament/crud-filament/2-akses-halaman-daftar-product.png)

Pada saat akses data produk masih kosong. Untuk menambahkan data produk, klik button `New product`.

![3- akses-halaman-form-tambah-data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/filament/crud-filament/3-akses-halaman-tambah-data.png)

Selanjutnya kita bisa coba isi data pada form, lalu tekan tombol `create` untuk menyimpan data. 

![4-fill-form-add-product](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/filament/crud-filament/4-fill-form-add-product.png)

Ketika berhasil kita dialihkan ke halaman view data.

![5-redirect-ke-halaman-view-data-setelah-menambahkan-data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/filament/crud-filament/5-redirect-ke-halaman-view-data-setelah-menambahkan-data.png)

Selanjutnya kita klik kembali menu `Products` di sidebar untuk kembali ke halaman daftar produk. Pada halaman ini kita bisa lihat data yang sudah kita tambahkan.

![6-akses-kembali-halaman-daftar-produk.png](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/filament/crud-filament/6-akses-kembali-halaman-daftar-produk.png)

Pada baris data terdapat gambar yang ditampilkan dan juga terdapat action untuk `view` dan juga `edit` data sesuai dengan action yang terdapat pada method `table()` di class `ProductResource`.

```
public static function table(Table $table): Table
{
        // baris kode lainnya 

        ->actions([
            Tables\Actions\ViewAction::make(),
            Tables\Actions\EditAction::make(),
        ])

        // baris kode lainnya
}
```

Kita bisa coba edit dengan klik tombol `Edit` yang akan dialihkan ke halaman edit data.

Untuk fitur delete data, kita bisa klik checkbox pada baris data produk.

![Klik checkbox untuk tes delete data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/filament/crud-filament/7-klik-checkbox-untuk-tes-delete-data.png)

Selanjutnya akan tampil modal untuk konfirmasi hapus data dan kita bisa tekan button `Confirm` untuk konfirmasi hapus data.

![Konfirmasi delete data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/filament/crud-filament/8-konfirmasi-delete-data.png)

## Kesimpulan {#kesimpulan}

Tutorial ini telah memperkenalkan pendekatan modern dalam membangun aplikasi CRUD menggunakan kombinasi Laravel dan Filament. Melalui implementasi sistem manajemen produk, kita telah melihat bagaimana Filament dapat secara drastis menyederhanakan proses pembuatan admin panel yang biasanya memakan waktu dan kompleks.

Beberapa pencapaian kunci dari tutorial ini meliputi:

- Pembangunan struktur database yang solid melalui Laravel migrations
- Implementasi sistem CRUD lengkap dengan validasi data
- Integrasi fitur upload file untuk manajemen gambar produk
- Pembuatan tabel interaktif dengan fungsi view, edit, dan delete
- Penggunaan komponen Filament yang reusable untuk mempercepat development

Yang lebih penting, tutorial ini mendemonstrasikan bagaimana developer dapat memanfaatkan kekuatan Filament untuk menghindari penulisan kode boilerplate yang berulang, sambil tetap mempertahankan fleksibilitas dan kontrol penuh atas aplikasi. Pendekatan ini tidak hanya menghemat waktu development, tetapi juga menghasilkan kode yang lebih maintainable dan scalable.

Untuk pengembangan lebih lanjut, developer dapat mengeksplorasi fitur-fitur Filament lainnya seperti:

- Implementasi sistem autentikasi yang lebih kompleks
- Penambahan filter dan pencarian lanjutan pada tabel
- Kustomisasi tampilan dan tema admin panel
- Integrasi dengan layanan pihak ketiga
- Penerapan role-based access control (RBAC)

Dengan fondasi yang telah dibangun melalui tutorial ini, developer memiliki starting point yang solid untuk mengembangkan aplikasi admin yang lebih kompleks sesuai kebutuhan bisnis mereka.