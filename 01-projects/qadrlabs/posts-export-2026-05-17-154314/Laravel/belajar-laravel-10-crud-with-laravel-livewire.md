---
title: "Belajar Laravel 10: CRUD with Laravel Livewire"
slug: "belajar-laravel-10-crud-with-laravel-livewire"
category: "Laravel"
date: "2023-07-28"
status: "published"
---

Dalam dunia pengembangan web modern, membangun aplikasi full-stack seringkali menjadi tantangan tersendiri bagi developer. Kompleksitas meningkat ketika harus mengintegrasikan multiple framework seperti Vue.js atau React.js dengan backend. Namun, sebuah solusi inovatif hadir melalui Laravel Livewire - sebuah framework yang memungkinkan pengembangan interface aplikasi secara komprehensif hanya dengan menggunakan Laravel.

## Memahami Laravel Livewire{#memahami-laravel-livewire}
Laravel Livewire hadir sebagai framework revolusioner yang memungkinkan developer membangun interface web dinamis melalui pendekatan server-side yang elegan. Framework ini menjembatani gap antara server-side dan client-side development, menghadirkan solusi yang menyederhanakan kompleksitas sambil meningkatkan efisiensi pengembangan.

Mari kita eksplorasi fitur-fitur unggulan Laravel Livewire:

1. **Arsitektur Server-Side Component**
   - Pengembangan komponen berbasis PHP
   - Integrasi seamless antara logika dan tampilan
   - Manajemen event dan data secara server-side
   - Interaksi komponen yang fluid

2. **Sistem Reaktivitas Modern**
   - Penanganan state otomatis
   - Update UI real-time tanpa JavaScript kompleks
   - Sinkronisasi data yang mulus
   - Pengalaman development yang streamlined

3. **Performa Real-Time Superior**
   - Implementasi AJAX yang optimal
   - Komunikasi server tanpa page reload
   - Responsivitas tinggi
   - Interaktivitas yang smooth

4. **Ekosistem Laravel yang Powerful**
   - Integrasi native dengan fitur Laravel
   - Akses penuh ke Eloquent ORM
   - Sistem validasi yang robust
   - Dukungan middleware komprehensif

5. **Optimasi SEO Built-in**
   - Server-side rendering yang optimal
   - Konten yang search-engine friendly
   - Performance yang teroptimasi
   - Aksesibilitas konten yang superior

Laravel Livewire menghadirkan paradigma baru dalam pengembangan aplikasi web interaktif, menawarkan alternatif yang lebih efisien dibandingkan framework JavaScript tradisional seperti Vue atau React. Developer dapat memfokuskan energi pada pengembangan bisnis logic tanpa terjebak dalam kompleksitas manajemen UI.

Breaking News: Pada 25 Agustus 2023, Laravel Livewire mencapai milestone signifikan dengan merilis [versi 3.0.0](https://github.com/livewire/livewire/releases/tag/v3.0.0). Tutorial ini akan menggunakan versi terbaru tersebut, memberikan Anda pengalaman hands-on dengan fitur-fitur terkini dari Livewire 3.

## Overview{#overview}
Pada tutorial laravel 10 ini kita akan coba menggunakan Laravel Livewire 3 untuk membangun project sederhana dengan fitur CRUD. Untuk data yang akan kita gunakan dalam project ini seperti biasa kita gunakan data `post`. Tujuan akhirnya seperti judul tutorial ini, project kita dapat melakukan operasi crud untuk menampilkan data post, membuat post baru, memperbaharui dat apost, dan menghapus data post.

## Step 1 - Setup Project{#step-1}
Pertama kita buat project laravel baru menggunakan `composer`. Buka terminal lalu run command di bawah ini.

```
composer create-project laravel/laravel:^10.0 crud_livewire
```

## Step 2 - Set Konfigurasi Database{#step-2}
Selanjutnya kita masuk ke dalam direktori root project kita menggunakan command di bawah ini.
```
cd crud_livewire
```

Setelah itu buka file `.env` di text editor dan kita sesuaikan credentials database.
```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_crud_livewire
DB_USERNAME=admin
DB_PASSWORD=password
```

Pastikan credentials dan nama database sesuai dengan yang akan kita gunakan. Selanjutnya save kembali file `.env`.


## Step 3 - install Laravel Livewire 3{#step-3}
Langkah selanjutnya adalah install package laravel livewire 3. Buka kembali terminal, lalu kita install `livewire` melalui `composer`.
```
composer require livewire/livewire:^3.0
```
Tunggu sampai proses download package `livewire` selesai.

Kita cek di file `composer.json`, pada saat tutorial ini ditulis, livewire yang terinstall adalah versi 3.
```
    "require": {
        "php": "^8.1",
        "guzzlehttp/guzzle": "^7.2",
        "laravel/framework": "^10.10",
        "laravel/sanctum": "^3.3",
        "laravel/tinker": "^2.8",
        "livewire/livewire": "^3.0"
    },
```

## Step 4 - Buat File Model dan Migration{#step-4}
Persiapan project kita sudah selesai, langkah selanjutnya adalah membuat file model dan migration. Kita generate file model dan migration menggunakan `artisan` command berikut ini.
```
php artisan make:model Post -m
```

Output ketika kita run command di atas:
```
$ php artisan make:model Post -m

   INFO  Model [app/Models/Post.php] created successfully.  

   INFO  Migration [database/migrations/2026_03_02_110349_create_posts_table.php] created successfully. 
```

Setelah file migration berhasil digenerate, kita buka file `database/migrations/20xx_xx_xx_xxxxxx_create_posts_table.php`, lalu kita sesuaikan dengan baris kode berikut ini.

```
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('posts', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('content');
            $table->string('slug');
            $table->smallInteger('status');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('posts');
    }
};


```

Setelah selesai, save kembali file migration dan jangan lupa kita run file migration menggunakan `artisan` command.
```
php artisan migrate
```

Output:
```
$ php artisan migrate

   INFO  Preparing database.  

  Creating migration table ......................................... 11ms DONE

   INFO  Running migrations.  

  2014_10_12_000000_create_users_table ............................. 13ms DONE
  2014_10_12_100000_create_password_reset_tokens_table ............. 27ms DONE
  2019_08_19_000000_create_failed_jobs_table ....................... 24ms DONE
  2019_12_14_000001_create_personal_access_tokens_table ............ 30ms DONE
  2023_07_28_025654_create_posts_table ............................. 13ms DONE

```

Oke, table `posts` sudah siap di database kita.

Selanjutnya kita buka file kedua yaitu file model `app/Models/Post.php`. Pada file tersebut kita tambahkan atribut `$fillable` untuk mengatur mass assignment yang diijinkan.

```
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Post extends Model
{
    use HasFactory;

    protected $fillable = [
        'title', 'content', 'slug', 'status'
    ];
}


```


## Step 5 - Create Post Component{#step-5}
Pada tahapan ini kita sudah mulai masuk penggunaan `livewire`. Sekarang kita coba buat component livewire menggunakan command di bawah ini.
```
php artisan make:livewire post
```

Output:
```
$ php artisan make:livewire post
 COMPONENT CREATED  🤙

CLASS: app/Livewire/Post.php
VIEW:  resources/views/livewire/post.blade.php

  _._
/ /o\ \   || ()                ()  __         
|_\ /_|   || || \\// /_\ \\ // || |~~ /_\   
 |`|`|    || ||  \/  \\_  \^/  || ||  \\_   


Congratulations, you've created your first Livewire component! 🎉🎉🎉


```

Selanjutnya buka file `app/Http/Livewire/Post.php`, lalu kita tambahkan baris kode berikut ini.
```
<?php

namespace App\Livewire;

use Illuminate\Support\Str;
use Livewire\Component;

class Post extends Component
{
    /**
     * define public variable
     */
    public $title, $content, $postId, $slug, $status, $updatePost = false, $addPost = false;

    /**
     * List of add/edit form rules
     */
    protected $rules = [
        'title' => 'required',
        'content' => 'required',
        'status' => 'required'
    ];

    /**
     * Reseting all inputted fields
     * @return void
     */
    public function resetFields()
    {
        $this->title = '';
        $this->content = '';
        $this->status = 1;
    }

    /**
     * render the post data
     * @return \Illuminate\Contracts\View\Factory|\Illuminate\Contracts\View\View
     */
    public function render()
    {
        $posts = \App\Models\Post::latest()->get();
        return view('livewire.post', compact('posts'));
    }

    /**
     * Open Add Post form
     * @return void
     */
    public function create()
    {
        $this->resetFields();
        $this->addPost = true;
        $this->updatePost = false;
    }

    /**
     * store the user inputted post data in the posts table
     * @return void
     */
    public function store()
    {
        $this->validate();
        try {
            \App\Models\Post::create([
                'title' => $this->title,
                'content' => $this->content,
                'status' => $this->status,
                'slug' => Str::slug($this->title)
            ]);

            session()->flash('success', 'Post Created Successfully!!');
            $this->resetFields();
            $this->addPost = false;
        } catch (\Exception $ex) {
            session()->flash('error', 'Something goes wrong!!');
        }
    }

    /**
     * show existing post data in edit post form
     * @param mixed $id
     * @return void
     */
    public function edit($id)
    {
        try {
            $post = \App\Models\Post::findOrFail($id);
            if (!$post) {
                session()->flash('error', 'Post not found');
            } else {
                $this->title = $post->title;
                $this->content = $post->content;
                $this->status = $post->status;
                $this->postId = $post->id;
                $this->updatePost = true;
                $this->addPost = false;
            }
        } catch (\Exception $ex) {
            session()->flash('error', 'Something goes wrong!!');
        }

    }

    /**
     * update the post data
     * @return void
     */
    public function update()
    {
        $this->validate();
        try {
            \App\Models\Post::whereId($this->postId)->update([
                'title' => $this->title,
                'content' => $this->content,
                'status' => $this->status,
                'slug' => Str::slug($this->title)
            ]);
            session()->flash('success', 'Post Updated Successfully!!');
            $this->resetFields();
            $this->updatePost = false;
        } catch (\Exception $ex) {
            session()->flash('error', 'Something goes wrong!!');
        }
    }

    /**
     * Cancel Add/Edit form and redirect to post listing page
     * @return void
     */
    public function cancel()
    {
        $this->addPost = false;
        $this->updatePost = false;
        $this->resetFields();
    }

    /**
     * delete specific post data from the posts table
     * @param mixed $id
     * @return void
     */
    public function destroy($id)
    {
        try {
            \App\Models\Post::find($id)->delete();
            session()->flash('success', "Post Deleted Successfully!!");
        } catch (\Exception $e) {
            session()->flash('error', "Something goes wrong!!");
        }
    }
}

```
Setelah selesai, save kembali file `app/Http/Livewire/Post.php`.

Selanjutnya kita buat file baru `resources/views/home.blade.php`, setelah itu kita tambahkan baris kode berikut ini.

```
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Belajar Laravel 10 - Crud Laravel Livewire @ qadrlabs.com</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet"
          integrity="sha384-9ndCyUaIbzAi2FUVXJi0CjmCapSmO7SnpJef0486qhLnuZ2cdeRhO02iuK6FUUVM" crossorigin="anonymous">

    @livewireStyles
</head>

<body>
<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
    <div class="container-fluid">
        <a class="navbar-brand" href="/">Livewire</a>
    </div>
</nav>
<div class="container">
    <div class="row justify-content-center mt-3">
        @livewire('post')
    </div>
</div>

@livewireScripts
</body>

</html>


```

Untuk menampilkan daftar post, kita buka file component `resources/views/livewire/post.blade.php`, lalu kita sesuaikan isi file `post.blade.php` menjadi baris kode berikut ini.

```
<div>
    <div class="col-md-12 mb-2">
        @if(session()->has('success'))
            <div class="alert alert-success" role="alert">
                {{ session()->get('success') }}
            </div>
        @endif

        @if(session()->has('error'))
            <div class="alert alert-danger" role="alert">
                {{ session()->get('error') }}
            </div>
        @endif

        @if($addPost)
            @include('livewire.create')
        @endif

        @if($updatePost)
            @include('livewire.update')
        @endif
    </div>

    <div class="col-md-12">
        <div class="card">
            <div class="card-header">
                @if(!$addPost)
                    <button wire:click="create()" class="btn btn-primary btn-sm float-end">Add New Post</button>
                @endif
            </div>
            <div class="card-body">

                <div class="table-responsive">
                    <table class="table">
                        <thead>
                        <tr>
                            <th>Name</th>
                            <th>Content</th>
                            <th>Status</th>
                            <th>Action</th>
                        </tr>
                        </thead>
                        <tbody>
                        @forelse ($posts as $post)
                            <tr>
                                <td>
                                    {{$post->title}}
                                </td>
                                <td>
                                    {{$post->content}}
                                </td>
                                <td>{{ $post->status == 1 ? 'Draft':'Publish' }}</td>
                                <td>
                                    <button wire:click="edit({{$post->id}})"
                                            class="btn btn-primary btn-sm">Edit</button>
                                    <button wire:click="destroy({{ $post->id }})"
                                            class="btn btn-danger btn-sm">Delete</button>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="4" align="center">
                                    No Posts Found.
                                </td>
                            </tr>
                        @endforelse
                        </tbody>
                    </table>

                </div>
            </div>
        </div>
    </div>
</div>

```

Sekarang kita buat file component baru untuk menampilkan form untuk menambahkan data, yaitu `resources/views/livewire/create.blade.php`. Lalu kita ketik baris kode berikut ini.
```
<div class="card">
    <div class="card-body">
        <form>
            <div class="form-group mb-3">
                <label for="title">Title:</label>
                <input type="text" class="form-control @error('title') is-invalid @enderror" id="title"
                       placeholder="Enter Title" wire:model="title">
                @error('title')
                <span class="text-danger">{{ $message }}</span>
                @enderror
            </div>
            <div class="form-group mb-3">
                <label for="content">content:</label>
                <textarea class="form-control @error('content') is-invalid @enderror" id="content"
                          wire:model="content" placeholder="Enter content"></textarea>
                @error('content')
                <span class="text-danger">{{ $message }}</span>
                @enderror
            </div>
            <div class="form-group mb-3">
                <label for="status">Status:</label>
                <select name="status" id="status" class="form-control @error('status') is-invalid @enderror" wire:model="status">

                    <option value="1">Draft</option>
                    <option value="2">Publish</option>
                </select>
                @error('status')
                <span class="text-danger">{{ $message }}</span>
                @enderror
            </div>
            <div class="d-grid gap-2">
                <button wire:click.prevent="store()" class="btn btn-success btn-block">Save</button>
                <button wire:click.prevent="cancel()" class="btn btn-secondary btn-block">Cancel</button>
            </div>
        </form>
    </div>
</div>


```

Kita buat file component yang kedua untuk menangani proses update data yaitu `resources/views/livewire/update.blade.php`. Kita sesuaikan dengan baris kode berikut ini.
```
<div class="card">
    <div class="card-body">
        <form>
            <div class="form-group mb-3">
                <label for="title">Title:</label>
                <input type="text" class="form-control @error('title') is-invalid @enderror" id="title"
                       placeholder="Enter Title" wire:model="title">
                @error('title')
                <span class="text-danger">{{ $message }}</span>
                @enderror
            </div>
            <div class="form-group mb-3">
                <label for="content">content:</label>
                <textarea class="form-control @error('content') is-invalid @enderror" id="content"
                          wire:model="content" placeholder="Enter content"></textarea>
                @error('content')
                <span class="text-danger">{{ $message }}</span>
                @enderror
            </div>
            <div class="form-group mb-3">
                <label for="status">Status:</label>
                <select name="status" id="status" class="form-control @error('status') is-invalid @enderror" wire:model="status">
                    <option value="1">Draft</option>
                    <option value="2">Publish</option>
                </select>
                @error('status')
                <span class="text-danger">{{ $message }}</span>
                @enderror
            </div>
            <div class="d-grid gap-2">
                <button wire:click.prevent="update()" class="btn btn-success btn-block">Update</button>
                <button wire:click.prevent="cancel()" class="btn btn-secondary btn-block">Cancel</button>
            </div>
        </form>
    </div>
</div>


```

## Step 6 - Definisikan Route{#step-6}
Buka file `routes/web.php`, lalu definisikan route untuk menampilkan halaman project kita.
```
Route::get('/', function () {
    return view('home');
});

```

## Step 7 - Uji Coba Project{#step-7}
Selanjutnya kita run project kita. Buka kembali terminal lalu run command di bawah ini.
```
php artisan serve
```

Setelah itu buka link `http://127.0.0.1:8000` di browser dan kita bisa coba-coba menambahkan, memperbaharui dan menghapus data.

## Penutup{#penutup}

Selamat! Anda telah berhasil menyelesaikan perjalanan membangun aplikasi CRUD menggunakan Laravel Livewire. Melalui tutorial ini, kita telah mengeksplorasi kekuatan dan fleksibilitas yang ditawarkan oleh package ini dalam membangun interface web yang dinamis.

### Apa yang Sudah Kita Pelajari
- Implementasi operasi CRUD lengkap
- Penggunaan komponen Livewire yang reaktif
- Integrasi dengan Laravel secara seamless
- Manajemen state dan event handling
- Real-time updates tanpa refresh halaman

### Potensi Pengembangan Selanjutnya
Project ini membuka berbagai kemungkinan pengembangan yang menarik, seperti:
- Implementasi fitur pencarian yang powerful
- Sistem sorting data yang dinamis
- Paginasi untuk manajemen data yang lebih efisien
- Real-time updates untuk collaborative features
- UI/UX enhancements dengan Alpine.js

Bagaimana pengalaman Anda mengikuti tutorial ini? Apakah Laravel Livewire memberikan perspektif baru dalam pengembangan aplikasi web? Mari kita eksplorasi lebih lanjut potensi framework ini dalam project Anda berikutnya!