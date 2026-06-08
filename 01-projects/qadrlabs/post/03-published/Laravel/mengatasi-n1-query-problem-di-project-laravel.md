---
title: "Mengatasi N+1 Query Problem di Project Laravel"
slug: "mengatasi-n1-query-problem-di-project-laravel"
category: "Laravel"
date: "2024-12-27"
status: "published"
---

## Introduction {#introduction}
N+1 Query Problem adalah salah satu tantangan performa terbesar yang dihadapi developer Laravel. Masalah ini muncul ketika aplikasi melakukan query database yang tidak efisien saat mengakses relasi antar model, mengakibatkan eksekusi query berlebihan yang berdampak pada performa aplikasi dan beban server.

Artikel ini akan membahas secara mendalam tentang N+1 query problem di Laravel, cara mengidentifikasinya, dan implementasi solusi menggunakan fitur bawaan Laravel untuk mengoptimalkan performa aplikasi Anda.

## Overview {#overview}
Tutorial ini akan membahas tiga aspek penting:

1. Konsep dasar N+1 Query Problem dalam konteks Laravel
2. Implementasi eager loading sebagai solusi optimasi
3. Demonstrasi performa melalui studi kasus praktis dengan fitur blog sederhana

Melalui studi kasus ini, kita akan mempelajari bagaimana mengidentifikasi N+1 query problem dan menerapkan solusi yang tepat untuk meningkatkan performa aplikasi Laravel.


## Apa Itu N+1 Query Problem? {#apa-itu-n-plus-one-query-problem}

Sebelum masuk ke solusi, penting untuk memahami masalahnya terlebih dahulu. **N+1 Query Problem** adalah pola query database yang tidak efisien, di mana:

1. **1 query** digunakan untuk mengambil data utama (seperti daftar postingan).
2. **N query tambahan** digunakan untuk mengambil data terkait (seperti kategori postingan).

Misalnya, jika kita memiliki 100 postingan dan setiap postingan memiliki kategori, Laravel secara default akan menjalankan **1 query untuk mengambil semua postingan** dan **100 query tambahan** untuk mengambil data kategori. Totalnya menjadi **101 query** hanya untuk memuat data yang seharusnya dapat diambil dengan **2 query**.

### Contoh Masalah {#contoh-masalah}

Kode berikut sering menjadi penyebab N+1 query problem:

```php
$posts = Post::all();
foreach ($posts as $post) {
    echo $post->title . ' - ' .$post->category->name . '<br/>';
}
```

#### Query yang Dihasilkan:

1. Query pertama untuk mengambil semua postingan:

   ```sql
   SELECT * FROM posts;
   ```

2. Query tambahan untuk setiap kategori (contoh, untuk `category_id = 1`):

   ```sql
   SELECT * FROM categories WHERE id = 1 LIMIT 1;
   ```

Jika ada 100 postingan, Laravel akan menjalankan **1 query untuk mengambil postingan** dan **100 query tambahan** untuk mengambil kategori terkait.

------

## Mengidentifikasi N+1 Query di Laravel {#mengidentifikasi-n-plus-one-query-di-laravel}

Untuk mengidentifikasi N+1 query problem di aplikasi Laravel, kita bisa gunakan fitur debugging seperti **Laravel Debugbar**. Debugbar akan menampilkan semua query yang dijalankan selama permintaan HTTP, sehingga kita dapat dengan mudah melihat apakah ada pola N+1.

### Langkah-Langkah Identifikasi

1. Pertama kita instal Laravel Debugbar dengan run command berikut:

   ```bash
   composer require barryvdh/laravel-debugbar --dev
   ```

2. Jalankan aplikasi kita menggunakan `php artisan serve`, akses halaman dan lihat tab **Queries** di Debugbar.

3. Pada tab **Queries** di debugbar, perhatikan jumlah query yang dijalankan. Jika jumlah query tidak masuk akal (misalnya, ratusan untuk data kecil), kemungkinan besar ada masalah N+1.

------

## Solusi: Menggunakan Eager Loading {#solusi-menggunakan-eager-loading}

Laravel menyediakan solusi bawaan untuk masalah ini: **eager loading**. Dengan eager loading, Laravel memuat data relasi sekaligus dalam satu query tambahan, menghilangkan kebutuhan untuk menjalankan query per item.

### Implementasi Eager Loading {#implementasi-eager-loading}

Berikut adalah cara memperbaiki kode sebelumnya menggunakan `with()`:

```php
$posts = Post::with('category')->get();
foreach ($posts as $post) {
    echo $post->title . ' - ' .$post->category->name . '<br/>';
}
```

#### Query yang Dihasilkan:

1. Query pertama untuk mengambil semua postingan:

   ```sql
   SELECT * FROM posts;
   ```

2. Query kedua untuk mengambil semua kategori yang terkait:

   ```sql
   SELECT * FROM categories WHERE id IN (1, 2, 3, ...);
   ```

Hasilnya, hanya ada **2 query** terlepas dari jumlah postingan.

## Cara Kerja dan Optimisasi {#cara-kerja-dan-optimisasi}

Laravel menyediakan dua pendekatan dalam memuat relasi antar model:

**Lazy Loading**
- Merupakan pendekatan default Laravel
- Memuat data relasi hanya saat diakses dalam kode
- Menghasilkan N+1 query problem karena setiap akses relasi memicu query baru
- Contoh:
```php
$posts = Post::all();
foreach ($posts as $post) {
    echo $post->category->name; // Trigger query baru
}
```

**Eager Loading**
- Memuat data relasi di awal bersamaan dengan query utama
- Menggunakan method `with()` untuk menentukan relasi yang akan dimuat
- Menghasilkan jumlah query yang minimal dan konsisten
- Contoh:
```php
$posts = Post::with('category')->get(); // Load semua data sekaligus
foreach ($posts as $post) {
    echo $post->category->name; // Menggunakan data yang sudah dimuat
}
```

Perbedaan performa kedua pendekatan ini signifikan, terutama saat menangani dataset besar. Eager loading menghasilkan query yang lebih efisien dan mengurangi beban database secara substansial.



## Simulasi dan Studi Kasus {#simulasi-dan-studi-kasus}
Untuk demonstrasi praktis, kita akan menggunakan project sederhana yang tersedia di [repository contoh N+1 query problem](https://github.com/qadrLabs/n-1-query-problem-example). Project ini menampilkan daftar blog post beserta kategorinya, dengan 100 data dummy yang digenerate menggunakan seeder.

Project menggunakan dua model utama: `App\Models\Category` dan `App\Models\Post`.

Berikut ini adalah`App\Models\Category`.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
    ];
}
```

Dan berikut ini adalah `App\Models\Post`.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Post extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'content',
        'slug',
        'status',
        'category_id',
    ];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }
}
```

Seperti yang terlihat pada baris kode di atas terdapat relasi ke model `Category`.

Pada project ini, kita akan gunakan controller `PostController` dengan method `index()` yang kita gunakan untuk menampilkan daftar postingan berserta nama kategori masing-masing postingan.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;

class PostController extends Controller
{
    public function index()
    {
        $posts = Post::all();
        foreach ($posts as $post) {
            echo $post->title . ' - ' .$post->category->name . '<br/>';
        }
    }
}
```

Seperti yang terlihat pada baris kode di atas, kita akan ambil semua data post menggunakan `Post::all()`, lalu kita coba tampilkan data tersebut menggunakan `foreach`.

Sekarang kita coba run project kita menggunakan `php artisan serve`, lalu kita akses `http://127.0.0.1:8000/posts`. Pada debugbar, kita klik tab **Queries** seperti yang terlihat pada gambar berikut ini.

![contoh N+1 Query Problem](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/n%2B1-query-problem/1-contoh-n-plus-one-query-problem.png)

Seperti yang terlihat pada gambar di atas, ketika halaman diakses, jumlah query yang dieksekusi untuk menampilkan 100 data postingan adalah **101** yang merupakan **N+1 Query Problem**, di mana **N=100**. 

Untuk mengatasi masalah ini kita akan coba gunakan Eager Loading. Sekarang buka kembali `PostController`, lalu kita modifikasi method `index()` menjadi seperti berikut ini.

```php
    public function index()
    {
        $posts = Post::with('category')->get();
        foreach ($posts as $post) {
            echo $post->title . ' - ' .$post->category->name . '<br/>';
        }
    }
```

Di sini kita ubah code:

```php
$posts = Post::all();
```

Menjadi:

```php
$posts = Post::with('category')->get();
```

Save kembali `PostController`, lalu kita akses kembali `http://127.0.0.1:8000/posts`. 

![implementasi eager loading sebagai solusi N+1 query problem](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/n%2B1-query-problem/2-implementasi-solusi-untuk-n-plus-one-query-problem.png)

Seperti yang terlihat pada gambar di atas, query yang dieksesi adalah **2**.

Mari kita bandingkan performa sebelum dan sesudah menggunakan eager loading.

#### Sebelum Eager Loading:

- Data: 100 postingan, 10 kategori.
- Query: **101 query**.

#### Setelah Eager Loading:

- Data: 100 postingan, 10 kategori.
- Query: **2 query**.

Hasil ini menunjukkan bahwa eager loading dapat mengurangi jumlah query hingga 98%.

## Kesimpulan {#kesimpulan}

N+1 query problem merupakan tantangan performa yang dapat diatasi dengan pemahaman dan implementasi yang tepat. Melalui penggunaan eager loading, jumlah query dapat berkurang secara signifikan - dari 101 query menjadi hanya 2 query untuk 100 data, menghasilkan peningkatan performa hingga 98%.

Poin kunci untuk diingat:
1. Gunakan Laravel Debugbar untuk mengidentifikasi N+1 query
2. Implementasikan eager loading dengan method `with()` pada relasi model
3. Monitor performa query sebelum dan sesudah optimasi

Dengan menerapkan praktik-praktik yang telah dibahas, developer dapat membangun aplikasi Laravel yang lebih efisien dan responsif.