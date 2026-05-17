---
title: "Tutorial Laravel: Membuat Fitur Live CRUD menggunakan Ajax"
slug: "tutorial-laravel-membuat-fitur-live-crud-menggunakan-ajax"
category: "Laravel"
date: "2024-08-21"
status: "published"
---

Tutorial laravel kali ini terinspirasi ketika saya menggunakan salah satu web untuk project management. Saat membuka web tersebut, saya sedang menambahkan member dan mengedit member yang sudah ada. Ketika saya klik text di table member, text tersebut berubah menjadi form input dan saya dapat langsung mengedit member tanpa harus bolak balik ke halaman edit satu per satu. Dari pengalaman ini, saya coba membuat project web sederhana yang memiliki behaviour yang sama. Di sini saya gunakan laravel dan ajax untuk memperoleh behaviour yang sama. Dan sebagai catatan saya coba tuliskan dalam bentuk tutorial laravel. Jadi, seri tutorial Laravel kali ini, kita akan fokus pada pembuatan fitur Live CRUD (Create, Read, Update, Delete) menggunakan Ajax.

## Overview{#overview}

Pada tutorial ini, kita akan membahas bagaimana cara membuat aplikasi sederhana. Di mana pada aplikasi ini kita dapat melakukan proses operasi CRUD di dalam satu halaman tanpa perlu merefresh halaman. 

<video width="600" controls>
  <source src="https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/live-crud-ajax/Screencast%20from%202024-08-22%2009-48-46.webm" type="video/webm">
  Uji coba
</video>



Sebagai studi kasus kita akan buat aplikasi untuk manajemen data member dengan field `name`, `email`, dan `phone`. Studi kasus ini akan membantu kita memahami bagaimana mengintegrasikan Laravel dengan Ajax untuk menciptakan operasi CRUD yang lebih interaktif dan efisien. 

Goal akhir dari tutorial ini adalah membangun aplikasi Laravel yang memungkinkan pengguna untuk menambah, mengedit, dan menghapus data member secara langsung pada halaman web tanpa perlu me-refresh halaman. Kita akan membahas secara detail setiap langkah mulai dari pembuatan project, konfigurasi database, hingga testing aplikasi.

## Table of Content{#table-of-content}

- [Overview](#overview)
- [Step 1: Buat Project Baru](#step-1-buat-project-baru)
- [Step 2: Atur Konfigurasi Database](#step-2-atur-konfigurasi-database)
- [Step 3: Membuat Model dan Migration](#step-3-membuat-model-dan-migration)
- [Step 4: Membuat Controller](#step-4-membuat-controller)
- [Step 5: Membuat View](#step-5-membuat-view)
- [Step 6: Register Route Baru](#step-6-register-route-baru)
- [Step 7: Uji Coba](#step-7-uji-coba)
- [Penutup](#penutup)

## Step 1: Buat Project Baru{#step-1-buat-project-baru}

Langkah pertama adalah membuat project Laravel baru. Kita buka terminal, lalu run command berikut di terminal:

```bash
composer create-project --prefer-dist laravel/laravel live-crud
```

Setelah project berhasil dibuat, masuk ke direktori project dengan command:

```bash
cd live-crud
```

Selanjutnya, kita bisa coba testing run project.

```bash
php artisan serve
```

## Step 2: Atur Konfigurasi Database{#step-2-atur-konfigurasi-database}

Langkah berikutnya adalah mengatur konfigurasi database untuk project live crud dengan ajax. Untuk mengatur konfigurasi database, buka file `.env` menggunakan code editor, lalu cari bagian konfigurasi database dan sesuaikan seperti berikut:

```bash
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_live_crud
DB_USERNAME=root
DB_PASSWORD=password
```

## Step 3: Membuat Model dan Migration{#step-3-membuat-model-dan-migration}

Selanjutnya, kita akan membuat model dan migration untuk tabel `members`. Jalankan command berikut di terminal:

```bash
php artisan make:model Member -m
```

Command di atas akan membuat model `Member` dan file migration yang terkait. Kita akan melihat output seperti berikut:

```bash
   INFO  Model [app/Models/Member.php] created successfully.  

   INFO  Migration [database/migrations/2024_08_22_020957_create_members_table.php] created successfully. 
```

Buka file migration yang baru dibuat di `database/migrations/` dan tambahkan kolom `name`, `email`, dan `phone` seperti contoh di bawah ini:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('members', function (Blueprint $table) {
            $table->id();
            $table->string('name')->nullable();
            $table->string('email')->nullable();
            $table->string('phone')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('members');
    }
};
```



Setelah itu, buka file model `app/Models/Member.php` dan tambahkan atribut `$fillable` agar kita bisa melakukan mass assignment untuk kolom-kolom tersebut:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Member extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'email',
        'phone'
    ];
}
```

Langkah berikutnya adalah menjalankan migrasi untuk membuat tabel `members` di database:

```bash
php artisan migrate
```

Jika Kita melihat prompt untuk membuat database, pilih `Yes` untuk melanjutkan.

```
 
   WARN  The database 'db_live_crud' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ Yes                                                          │
 └──────────────────────────────────────────────────────────────┘

   INFO  Preparing database.  

  Creating migration table ...................................... 38.59ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table ......................... 157.54ms DONE
  0001_01_01_000001_create_cache_table .......................... 52.13ms DONE
  0001_01_01_000002_create_jobs_table .......................... 167.96ms DONE
  2024_08_22_020957_create_members_table ........................ 33.38ms DONE
```



## Step 4: Membuat Controller{#step-4-membuat-controller}

Untuk menangani proses operasi crud, kita perlu membuat controller baru. Jalankan command berikut di terminal:

```bash
php artisan make:controller MemberController --model=Member
```

Output:

```
   INFO  Controller [app/Http/Controllers/MemberController.php] created successfully.  

```





Controller ini akan berfungsi sebagai tempat logika aplikasi, seperti mengambil data dari database, menyimpan data baru, mengedit data, dan menghapus data. Buka file `app/Http/Controllers/MemberController.php` dan modifikasi seperti berikut:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Member;
use Illuminate\Http\Request;

class MemberController extends Controller
{
    public function index()
    {
        $members = Member::orderBy('id', 'desc')->get();
        return view('member.index', compact('members'));
    }

    public function create()
    {
        $member = Member::create(['name' => '']);
        return response()->json(['id' => $member->id]);
    }

    public function update(Request $request)
    {
        $member = Member::find($request->id);
        $member->update([$request->modul => $request->value]);
        return response()->json([]);
    }

    public function delete(Request $request)
    {
        $member = Member::find($request->id);
        $member->delete();
        return response()->json([]);
    }
}
```

## Step 5: Membuat View{#step-5-membuat-view}

Proses operasi CRUD di project kita akan dilakukan di satu halaman yang sama. Jadi di sini kita cukup buat satu file saja. Sekarang kita buat file baru bernama `resources/views/member/index.blade.php` dan tambahkan kode berikut:

```html
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Member Management | Live CRUD Tutorial @ qadrlabs.com</title>
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <!-- Styles -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.6.0/css/all.min.css" integrity="sha512-Kc323vGBEqzTmouAECnVceyQqyqdsSiqLQISBL29aUW4U/M7pSPA/gEUZQqv1cwx4OnYxTxve5UMg5GT6L4JJg==" crossorigin="anonymous" referrerpolicy="no-referrer" />

    <style>
        td {
            cursor: pointer;
        }

        .editor {
            display: none;
        }
    </style>
</head>
<body>
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <h2>Member Management</h2>
            <div class="card">
                <div class="card-body">
                    <button class="btn btn-primary mb-3 float-end" id="tambah-data"><i class="fa-solid fa-plus"></i> Tambah</button>

                    <table id="table-data" class="table table-striped table-bordered mt-3">
                        <thead>
                        <tr>
                            <th width="30%">name</th>
                            <th width="30%">Email</th>
                            <th width="20%">Phone</th>
                            <th width="20%">Hapus</th>
                        </tr>
                        </thead>
                        <tbody id="table-body">
                        @foreach ($members as $member)
                            <tr data-id="{{ $member->id }}">
                                <td><span class='span-name caption' data-id='{{ $member->id }}'>{{ $member->name }}</span>
                                    <input type='text' class='field-name form-control editor' value='{{ $member->name }}'
                                           data-id='{{ $member->id }}'/></td>
                                <td><span class='span-email caption' data-id='{{ $member->id }}'>{{ $member->email }}</span>
                                    <input type='text' class='field-email form-control editor' value='{{ $member->email }}'
                                           data-id='{{ $member->id }}'/></td>
                                <td><span class='span-phone caption' data-id='{{ $member->id }}'>{{ $member->phone }}</span>
                                    <input type='text' class='field-phone form-control editor' value='{{ $member->phone }}'
                                           data-id='{{ $member->id }}'/></td>
                                <td>
                                    <button class='btn btn-xs btn-danger hapus-member' data-id='{{ $member->id }}'>
                                        <i class="fa-solid fa-trash"></i> Hapus
                                    </button>
                                </td>
                            </tr>
                        @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
<!-- Scripts -->
<script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
<script src="https://unpkg.com/sweetalert/dist/sweetalert.min.js"></script>
<script>
    $(function () {
        $.ajaxSetup({
            type: "post",
            cache: false,
            dataType: "json",
            headers: {
                'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
            }
        });

        $(document).on("click", "td", function () {
            $(this).find("span[class~='caption']").hide();
            $(this).find("input[class~='editor']").fadeIn().focus();
        });

        $("#tambah-data").click(function () {
            $.ajax({
                url: "{{ route('members.create') }}",
                success: function (a) {
                    var ele = "";
                    ele += "<tr data-id='" + a.id + "'>";
                    ele += "<td><span class='span-name caption' data-id='" + a.id + "'></span> <input type='text' class='field-name form-control editor' data-id='" + a.id + "' /></td>";
                    ele += "<td><span class='span-email caption' data-id='" + a.id + "'></span> <input type='text' class='field-email form-control editor' data-id='" + a.id + "' /></td>";
                    ele += "<td><span class='span-phone caption' data-id='" + a.id + "'></span> <input type='text' class='field-phone form-control editor' data-id='" + a.id + "' /></td>";
                    ele += "<td><button class='btn btn-xs btn-danger hapus-member' data-id='" + a.id + "'><i class='fa-solid fa-trash'></i> Hapus</button></td>";
                    ele += "</tr>";

                    var element = $(ele);
                    element.hide();
                    element.prependTo("#table-body").fadeIn(1500);
                }
            });
        });

        $(document).on("keydown", ".editor", function (e) {
            if (e.keyCode == 13) {
                var target = $(e.target);
                var value = target.val();
                var id = target.attr("data-id");
                var data = {id: id, value: value};
                if (target.is(".field-name")) {
                    data.modul = "name";
                } else if (target.is(".field-email")) {
                    data.modul = "email";
                } else if (target.is(".field-phone")) {
                    data.modul = "phone";
                }

                $.ajax({
                    data: data,
                    url: "{{ route('members.update') }}",
                    success: function () {
                        target.hide();
                        target.siblings("span[class~='caption']").html(value).fadeIn();
                    }
                })
            }
        });

        $(document).on("click", ".hapus-member", function () {
            var id = $(this).attr("data-id");

            swal({
                title: "Hapus Member",
                text: "Yakin akan menghapus member ini?",
                icon: "warning",
                buttons: {
                    cancel: "Batal",
                    confirm: {
                        text: "Hapus",
                        value: true,
                        visible: true,
                        className: "btn-danger",
                        closeModal: false
                    }
                },
                dangerMode: true,
            })
                .then((willDelete) => {
                    if (willDelete) {
                        $.ajax({
                            url: "{{ route('members.delete') }}",
                            data: {id: id},
                            success: function () {
                                $("tr[data-id='" + id + "']").fadeOut("fast", function () {
                                    $(this).remove();
                                });

                                swal("Member berhasil dihapus!", {
                                    icon: "success",
                                });
                            },
                            error: function() {
                                swal("Terjadi kesalahan dalam server!", "error");
                            }
                        });
                    } else {
                        swal("Hapus Member dibatalkan");
                    }
                });
        });
    });
</script>
</body>
</html>

```

## Step 6: Register Route Baru{#step-6-register-route-baru}

Setelah membuat controller dan view, sekarang  kita daftar route yang akan digunakan untuk mengakses fitur CRUD ini. Buka file `routes/web.php` dan tambahkan kode berikut:

```php
use App\Http\Controllers\MemberController;

Route::get('/members', [MemberController::class, 'index'])->name('members.index');
Route::post('/members/create', [MemberController::class, 'create'])->name('members.create');
Route::post('/members/update', [MemberController::class, 'update'])->name('members.update');
Route::post('/members/delete', [MemberController::class, 'delete'])->name('members.delete');
```

Kode ini mendefinisikan route yang akan digunakan untuk menampilkan daftar member, menambah member baru, mengupdate data member, dan menghapus member.

## Step 7: Uji Coba{#step-7-uji-coba}

Setelah semua langkah di atas selesai, sekarang saatnya untuk melakukan uji coba. Jalankan server Laravel dengan command:

```bash
php artisan serve
```

Buka browser dan akses URL `http://localhost:8000/members` untuk melihat tampilan manajemen data member yang telah kita buat. Pada halaman ini kita bisa lihat table dan tombol untuk menambahkan data baru.

![Uji coba buka halaman member management](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/live-crud-ajax/image-2.png)



Untuk menambahkan data baru kita bisa klik tombol `Tambah`. Kita bisa lihat ada row baru yang ditampilkan ketika kita klik tombol tersebut.

![Uji coba tambah data baru](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/live-crud-ajax/image-3.png)

Kita bisa `klik` row pada table yang baru saja ditampilkan dan kita bisa lihat ada form input untuk mengedit data.

![Uji coba edit data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/live-crud-ajax/image-4.png)



Kita bisa isi nama di form input, lalu tekan enter untuk memperbaharui nama.

![Uji coba edit nama](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/live-crud-ajax/image-5.png)

Selanjutnya kita bisa isi row email dan phone dengan cara yang sama.

![Uji coba edit data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/live-crud-ajax/image-6.png)



Misalnya kita ingin mengedit kembali, kita bisa klik kembali di row yang ingin kita edit. Nanti form input akan kembali ditampilkan supaya kita bisa edit datanya.

![Uji coba edit data lagi](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/live-crud-ajax/image-7.png)

Untuk proses hapus data, kita bisa klik tombol hapus. Setelah kita klik, akan tampil pop up konfirmasi.

![uji coba hapus](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/live-crud-ajax/image-8.png)

Selanjutnya kita klik Hapus, untuk melanjutkan proses hapus dan pop up window akan menampilkan keterangan data berhasil dihapus

![Uji coba konfirmasi hapus](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/live-crud-ajax/image-9.png)



## Penutup{#penutup}

Dalam tutorial ini, kita telah berhasil membuat aplikasi manajemen data member dengan fitur Live CRUD menggunakan Laravel dan Ajax. Dengan mengikuti langkah-langkah ini, Kita telah belajar bagaimana mengintegrasikan Ajax ke dalam aplikasi Laravel untuk membuat pengalaman pengguna yang lebih interaktif. Semoga tutorial ini bermanfaat dan dapat membantu Kita dalam mengembangkan aplikasi web yang lebih dinamis dan responsif. Jika ada pertanyaan atau saran, jangan ragu untuk meninggalkan komentar!