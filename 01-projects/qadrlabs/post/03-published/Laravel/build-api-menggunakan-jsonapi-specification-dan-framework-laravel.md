---
title: "Build API menggunakan JSON:API Specification dan Framework Laravel"
slug: "build-api-menggunakan-jsonapi-specification-dan-framework-laravel"
category: "Laravel"
date: "2024-06-27"
status: "published"
---

Beberapa waktu yang lalu saya bekerja sama dengan staf IT di salah satu perguruan tinggi swasta untuk membangun api service. Karena IT di lingkungan kampus tersebut belum memiliki standar yang jelas, kebanyakan waktu dihabiskan untuk membahas bagaimana seharusnya response JSON diformat. Untuk menangani kendala tersebut, saya mencoba melakukan riset dan akhirnya menemukan salah satu solusi yang kemungkinan dapat disepakati, yaitu mengikuti spesifikasi JSON: API. Untuk mempelajari spesifikasi tersebut, saya coba mengimplementasikan menggunakan framework Laravel. Jadi dalam tutorial laravel kali ini kita akan sama-sama belajar membangun API menggunakan JSON:API Spesification. Sebelum masuk ke tutorial, yuk kita bahas dulu apa itu JSON:API Specification.

## Apa itu JSON:API Specification?{#apa-itu-json-api-specification}
[JSON:API Specification](https://jsonapi.org) adalah spesifikasi tentang bagaimana klien harus meminta sumber daya diambil atau dimodifikasi, dan bagaimana server harus merespons permintaan tersebut. JSON:API dapat dengan mudah diperluas dengan ekstensi dan profil. Spesifikasi ini dirancang untuk meminimalkan jumlah permintaan dan jumlah data yang ditransmisikan antara klien dan server. Efisiensi ini dicapai tanpa mengorbankan keterbacaan, fleksibilitas, atau kemampuan ditemukan. Untuk proses pertukaran data, spesifikasi ini memerlukan penggunaan tipe media JSON:API (application/vnd.api+json).

## Alasan Penggunaan JSON:API Spesification{#alasan-penggunaan-json-api-spesification}
Penggunaan JSON:API Specification oleh developer dipicu oleh beberapa kendala dan masalah umum yang sering dihadapi dalam pengembangan dan integrasi API. Beberapa kendala utama yang melatarbelakangi adopsi spesifikasi ini adalah:
1. **Inconsistency in API Design:**
   - Tanpa spesifikasi yang standar, setiap developer atau tim pengembang dapat merancang API mereka sendiri dengan cara yang berbeda, yang sering kali mengakibatkan ketidakkonsistenan dalam format data, struktur URL, penanganan kesalahan, dan mekanisme autentikasi. JSON:API memberikan standar yang konsisten sehingga mempermudah pemahaman dan penggunaan API.

2. **Difficulties in Parsing and Handling Data:**
   - Dengan banyaknya variasi format API, klien harus menulis banyak kode khusus untuk menangani setiap variasi. JSON:API menyediakan format data yang seragam, sehingga mengurangi kompleksitas parsing dan penanganan data di sisi klien.

3. **Complex Relationship Management:**
   - Mengelola relasi antara berbagai sumber daya dalam API bisa menjadi rumit dan membingungkan. JSON:API memiliki cara yang standar dan jelas untuk mendefinisikan dan menangani relasi antar sumber daya, yang memudahkan pengelolaan data yang terhubung.

4. **Error Handling:**
   - Format penanganan kesalahan yang berbeda-beda dari berbagai API dapat menyulitkan klien dalam menafsirkan dan merespons kesalahan. JSON:API menyediakan format kesalahan yang konsisten dan mudah dimengerti, sehingga membantu klien dalam menangani situasi kesalahan dengan lebih baik.

5. **Pagination, Sorting, and Filtering:**
   - Setiap API memiliki caranya sendiri untuk menangani paginasi, pengurutan, dan penyaringan data, yang dapat membingungkan dan sulit diimplementasikan. JSON:API mendefinisikan cara standar untuk melakukan operasi-operasi ini, sehingga mempermudah klien dalam mengambil dan mengelola data.

6. **Documentation and Discoverability:**
   - API yang tidak terdokumentasi dengan baik dapat sulit digunakan dan dipahami. JSON:API mendorong dokumentasi yang jelas dan penggunaan objek `links` untuk meningkatkan discoverability dan navigasi dalam API.

7. **Performance Optimization:**
   - Pengambilan data secara berlebihan (over-fetching) atau pengambilan data yang tidak mencukupi (under-fetching) adalah masalah umum yang dapat mempengaruhi performa aplikasi. JSON:API membantu mengatasi masalah ini dengan memungkinkan klien untuk secara eksplisit menentukan data yang mereka butuhkan melalui parameter `include` dan `fields`.

Dari kendala dan masalah yang sering dihadapi dalam pengembangan dan integrasi API, JSON:API Specification memberikan manfaat berikut:
1. **Konsistensi**: JSON API menyediakan aturan yang ketat mengenai bagaimana data harus diformat. Ini mengurangi ambiguitas dan meningkatkan konsistensi antara berbagai API yang mengikuti spesifikasi ini.
2. **Efisiensi**: Dengan mendefinisikan cara untuk mengirim dan menerima data, JSON API mengurangi overhead komunikasi antara klien dan server. Fitur seperti pagination, filtering, dan sparse fieldsets membantu mengurangi jumlah data yang dikirim dan diterima.
3. **Interoperabilitas**: JSON API memudahkan integrasi dengan berbagai klien (seperti aplikasi web, mobile, dan layanan pihak ketiga) karena mengikuti standar yang telah diterima secara luas.
4. **Dokumentasi yang Jelas**: API yang mengikuti spesifikasi JSON API cenderung memiliki dokumentasi yang lebih baik karena format dan struktur datanya sudah jelas dan baku.
5. **Penanganan Error yang Terstandarisasi**: JSON API mendefinisikan bagaimana error harus dikomunikasikan antara server dan klien, membuat penanganan kesalahan lebih mudah diimplementasikan dan dipahami oleh pengembang.

## Komponen Utama JSON:API Specification{#komponen-utama-json-api-spesification}
Berikut ini komponen utama dalam JSON:API Specification.
- **Resource Objects**: Objek yang mewakili data utama yang dikelola oleh API, seperti pengguna, artikel, atau produk. Setiap resource object memiliki `type` dan `id`.
- **Attributes**: Properti dari resource object yang berisi data terkait. Sebagai contoh, dalam resource object "artikel" terdapat atribut seperti judul, konten, dan tanggal publikasi.
- **Relationships**: Relasi antara resource objects. Misalnya, artikel memiliki relasi dengan pengguna yang menulisnya.
- **Links**: URL yang menyediakan informasi lebih lanjut tentang resource atau relasi antara resource.
- **Meta**: Informasi tambahan yang mungkin diperlukan oleh klien tetapi tidak sesuai dengan atribut atau relasi resource.
- **Errors**: Format standar untuk mengembalikan informasi kesalahan yang terjadi selama pemrosesan permintaan API.

Berikut ini adalah contoh response dari blog yang mengimplementasikan JSON:API.

```json
{
  "data": {
    "type": "articles",
    "id": "1",
    "attributes": {
      "title": "JSON API Guide",
      "content": "This is a comprehensive guide to JSON API.",
      "published_at": "2023-06-01T12:00:00Z"
    },
    "relationships": {
      "author": {
        "data": { "type": "users", "id": "1" }
      }
    },
    "links": {
      "self": "http://example.com/articles/1"
    }
  }
}
```

## HTTP Methods dan Status Codes{#http-methods-dan-status-codes}
JSON API Specification menggunakan metode HTTP standar untuk operasi CRUD (Create, Read, Update, Delete). Setiap metode HTTP memiliki kegunaan dan kode status yang sesuai.
**Metode HTTP**

1. **GET**: Digunakan untuk mengambil data dari server. Bisa digunakan untuk mengambil daftar resource atau detail resource tertentu.
2. **POST**: Digunakan untuk membuat resource baru di server.
3. **PATCH**: Digunakan untuk memperbarui resource yang ada di server.
4. **DELETE**: Digunakan untuk menghapus resource dari server.

**Kode Status HTTP**
1. **200 OK**: Permintaan berhasil dan respons berisi data yang diminta.
2. **201 Created**: Resource berhasil dibuat dan lokasi resource baru diberikan dalam header Location.
3. **204 No Content**: Permintaan berhasil, tetapi tidak ada data yang dikembalikan.
4. **400 Bad Request**: Permintaan tidak valid atau data yang dikirim tidak sesuai dengan spesifikasi.
5. **401 Unauthorized**: Klien tidak memiliki hak akses untuk resource yang diminta.
6. **403 Forbidden**: Klien dilarang mengakses resource yang diminta.
7. **404 Not Found**: Resource yang diminta tidak ditemukan.
8. **500 Internal Server Error**: Kesalahan terjadi di sisi server.

Berikut adalah contoh struktur JSON untuk operasi CRUD (Create, Read, Update, dan Delete) serta response ketika terjadi error dalam JSON:API:
### 1. Create (Membuat Sumber Daya)

**Permintaan POST:**

```http
POST /articles HTTP/1.1
Content-Type: application/vnd.api+json

{
  "data": {
    "type": "articles",
    "attributes": {
      "title": "JSON:API paints my bikeshed!",
      "body": "The shortest article. Ever."
    }
  }
}
```

**Respon 201 Created:**

```json
{
  "data": {
    "type": "articles",
    "id": "1",
    "attributes": {
      "title": "JSON:API paints my bikeshed!",
      "body": "The shortest article. Ever."
    },
    "links": {
      "self": "/articles/1"
    }
  }
}
```

### 2. Read (Membaca Sumber Daya)

**Permintaan GET satu sumber daya:**

```http
GET /articles/1 HTTP/1.1
Accept: application/vnd.api+json
```

**Respon 200 OK:**

```json
{
  "data": {
    "type": "articles",
    "id": "1",
    "attributes": {
      "title": "JSON:API paints my bikeshed!",
      "body": "The shortest article. Ever."
    },
    "relationships": {
      "author": {
        "links": {
          "self": "/articles/1/relationships/author",
          "related": "/articles/1/author"
        },
        "data": { "type": "people", "id": "9" }
      }
    },
    "links": {
      "self": "/articles/1"
    }
  }
}
```

**Permintaan GET koleksi sumber daya:**

```http
GET /articles HTTP/1.1
Accept: application/vnd.api+json
```

**Respon 200 OK:**

```json
{
  "data": [
    {
      "type": "articles",
      "id": "1",
      "attributes": {
        "title": "JSON:API paints my bikeshed!",
        "body": "The shortest article. Ever."
      },
      "relationships": {
        "author": {
          "links": {
            "self": "/articles/1/relationships/author",
            "related": "/articles/1/author"
          },
          "data": { "type": "people", "id": "9" }
        }
      },
      "links": {
        "self": "/articles/1"
      }
    },
    {
      "type": "articles",
      "id": "2",
      "attributes": {
        "title": "Another article",
        "body": "The body of the second article."
      },
      "relationships": {
        "author": {
          "links": {
            "self": "/articles/2/relationships/author",
            "related": "/articles/2/author"
          },
          "data": { "type": "people", "id": "10" }
        }
      },
      "links": {
        "self": "/articles/2"
      }
    }
  ]
}
```

### 3. Update (Memperbarui Sumber Daya)

**Permintaan PATCH:**

```http
PATCH /articles/1 HTTP/1.1
Content-Type: application/vnd.api+json

{
  "data": {
    "type": "articles",
    "id": "1",
    "attributes": {
      "title": "Updated JSON:API article title"
    }
  }
}
```

**Respon 200 OK:**

```json
{
  "data": {
    "type": "articles",
    "id": "1",
    "attributes": {
      "title": "Updated JSON:API article title",
      "body": "The shortest article. Ever."
    },
    "links": {
      "self": "/articles/1"
    }
  }
}
```

### 4. Delete (Menghapus Sumber Daya)

**Permintaan DELETE:**

```http
DELETE /articles/1 HTTP/1.1
Accept: application/vnd.api+json
```

**Respon 204 No Content:**

```http
HTTP/1.1 204 No Content
```

### Respon Ketika Error

**Respon 400 Bad Request:**

```json
{
  "errors": [
    {
      "status": "400",
      "title": "Bad Request",
      "detail": "The request could not be understood by the server due to malformed syntax."
    }
  ]
}
```

**Respon 404 Not Found:**

```json
{
  "errors": [
    {
      "status": "404",
      "title": "Not Found",
      "detail": "The requested resource could not be found."
    }
  ]
}
```

**Respon 500 Internal Server Error:**

```json
{
  "errors": [
    {
      "status": "500",
      "title": "Internal Server Error",
      "detail": "An unexpected error occurred on the server."
    }
  ]
}
```

Dengan contoh-contoh di atas, JSON:API Specification menyediakan cara yang jelas dan konsisten untuk mengelola operasi CRUD dan menangani kesalahan dalam API.

## Project Overview{#overview}
Pada edisi tutorial laravel kali ini kita akan coba mengembangkan API dengan mengimplementasikan spesifikasi JSON:API menggunakan framework laravel. Untuk proses pengembangan API, kita akan coba bagi tutorial ini menjadi dua bagian, yaitu:
1. Membangun API untuk operasi CRUD sesuai dengan spesifikasi JSON:API.
2. Menulis feature testing untuk menguji masing-masing endpoint operasi CRUD.

Untuk studi kasus, kita akan coba sesuai dengan contoh response json:api yang sudah dituliskan sebelumnya di bagian [Komponen Utama JSON:API Specification](#komponen-utama-json-api-spesification). Kita akan coba buat API untuk data `articles` yang memiliki field `title`, `content`, `published_at` dan `author_id`, di mana `author_id` ini merupakan id dari `users`. Jadi ketika response ditampilkan, kita bisa lihat juga data relasi ke table `users`.

Goal kita di tutorial ini adalah ketika proses pengujian, response yang dikembalikan ketika kita mengirimkan request ke api endpoint untuk masing-masing operasi CRUD sesuai dengan spesifikasi JSON:API.
.
.
.
Yuk kita mulai~

**Updated: 20 Maret 2025**, Tutorial ini diujicoba kembali menggunakan Laravel 12.

## Step 1: Create Project Baru{#step-1-create-project-baru}
Pada step satu ini kita akan membuat project baru untuk tutorial laravel ini. Sekarang kita buka terminal, lalu run command berikut ini untuk membuat project laravel baru.

```
composer create-project --prefer-dist laravel/laravel json-api-project
```

Tunggu sampai proses install selesai.

Apabila proses buat project baru selesai, selanjutnya kita masuk ke direktori project menggunakan command berikut ini

```
cd json-api-project
```

Kemudian kita bisa coba run project dengan cara run command berikut ini.

```
php artisan serve
```



## Step 2: Atur Konfigurasi database{#step-2-atur-konfigurasi-database}

Setelah proses create baru selesai, selanjutnya kita akan atur konfigurasi database di file `.env`. Sekarang kita buka file `.env`, lalu sesuaikan konfigurasi database.

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=json_api_db
DB_USERNAME=root
DB_PASSWORD=password
```

Jangan lupa sesuaikan credentials mysql sesuai dengan credentials mysql teman-teman.

Save kembali file `.env` apabila sudah selesai.



Selanjutnya kita run migrate command.

```
php artisan migrate
```

Output yang ditampilkan apabila belum membuat database yang kita atur di file `.env`.

```
   WARN  The database 'json_api_db' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘

```

Selanjutnya pilih `yes` untuk membuat database baru, lalu tekan enter untuk melanjutkan.

```
   WARN  The database 'json_api_db' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ Yes                                                          │
 └──────────────────────────────────────────────────────────────┘

   INFO  Preparing database.  

  Creating migration table ...................................... 34.79ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table ......................... 161.42ms DONE
  0001_01_01_000001_create_cache_table .......................... 60.50ms DONE
  0001_01_01_000002_create_jobs_table .......................... 142.30ms DONE

```



## Step 3: Create file model dan migration{#step-3-create-model-dan-migration}

Seperti yang sudah disebutkan sebelumnya di [overview](#overview), kita akan coba buat model dan migration untuk table `articles`. Sekarang kita buka kembali terminal, lalu run command berikut ini untuk membuat model.

```
php artisan make:model Article -m
```

Output:

```
   INFO  Model [app/Models/Article.php] created successfully.  

   INFO  Migration [database/migrations/2024_06_10_080838_create_articles_table.php] created successfully.
```



Sekarang kita buka file migration `database/migrations/xxxx_xx_xx_xxxxxx_create_articles_table.php`, lalu kita sesuaikan menjadi baris kode berikut ini.

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
        Schema::create('articles', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('content');
            $table->timestamp('published_at')->nullable();
            $table->foreignId('author_id')->constrained('users')->onDelete('cascade'); // Menambahkan relasi dengan tabel users
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('articles');
    }
};
```

Setelah selesai save kembali file `database/migrations/xxxx_xx_xx_xxxxxx_create_articles_table.php`.



Selanjutnya kita buka file model `app/Models/Article.php`, lalu kita tambahkan attribute `$fillable`.



```
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Article extends Model
{
    use HasFactory;

    protected $fillable = ['title', 'content', 'published_at', 'author_id'];
}
```

Selanjutnya kita tambahkan relasi ke model `User`.

```
<?php

// ... baris kode lainnya

use Illuminate\Database\Eloquent\Relations\BelongsTo; // tambahkan ini

class Article extends Model
{
    // ... baris kode lainnya

    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

Jangan lupa tambahkan `use` statement tepat sebelum deklarasi class `Article`.

```
use Illuminate\Database\Eloquent\Relations\BelongsTo;
```

Setelah selesai save kembali file `app/Models/Article.php`.



Selanjutnya kita run kembali migration command.

```
php artisan migrate
```

Output:

```
   INFO  Running migrations.  

  2024_06_10_080838_create_articles_table ....................... 79.98ms DONE
```

Seperti yang terlihat di output terminal di atas, table `articles` berhasil dibuat.



## Step 4: Create Resources Class{#step-4-create-resources-class}

Untuk mengembalikan data yang sesuai dengan spesifikasi JSON:API, kita perlu buat resources class yang akan menangani proses tersebut. Sekarang kita buka kembali terminal lalu run command berikut ini untuk generate resources class.

```
php artisan make:resource UserResource
```

Output:

```
   INFO  Resource [app/Http/Resources/UserResource.php] created successfully.
```



Setelah resource class berhasil kita generate menggunakan command di atas, selanjutnya kita buka file `app/Http/Resources/UserResource.php`, lalu kita sesuaikan method `toArray()` menjadi baris kode berikut ini.

```
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'type' => 'users',
            'id' => (string) $this->id,
            'attributes' => [
                'name' => $this->name,
                'email' => $this->email,
                'created_at' => $this->created_at,
                'updated_at' => $this->updated_at,
            ],
            'links' => [
                'self' => url('/api/users/' . $this->id)
            ]
        ];
    }
}
```



Selanjutnya kita buat file resource kedua untuk menampilkan data `article`.

```
php artisan make:resource ArticleResource
```

Output:

```
   INFO  Resource [app/Http/Resources/ArticleResource.php] created successfully.
```

Selanjutnya kita buka file `app/Http/Resources/ArticleResource.php`, lalu kita sesuaikan method `toArray()` menjadi baris kode berikut ini.

```
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ArticleResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'type' => 'articles',
            'id' => (string) $this->id,
            'attributes' => [
                'title' => $this->title,
                'content' => $this->content,
                'published_at' => $this->published_at,
                'created_at' => $this->created_at,
                'updated_at' => $this->updated_at,
            ],
            'relationships' => [
                'author' => new UserResource($this->whenLoaded('author')),
            ],
            'links' => [
                'self' => url('/api/articles/' . $this->id)
            ]
        ];
    }
}
```

Seperti yang terlihat pada baris kode di atas, data yang di-return sebagai json kita sesuaikan dengan spesifikasi JSON:API yang sebelumnya kita bahas di bagian [Komponen Utama JSON:API Specification](#komponen-utama-json-api-spesification)



## Step 5: Create Controller Baru{#step-5-create-controller-baru}

Selanjutnya kita buat controller untuk menangani api endpoint untuk operasi CRUD data article. Buka kembali terminal, lalu run command berikut ini.

```
php artisan make:controller Api/ArticleController
```

Output:

```
   INFO  Controller [app/Http/Controllers/Api/ArticleController.php] created successfully. 
```



Sekarang buka file `app/Http/Controllers/Api/ArticleController.php`, lalu kita sesuaikan menjadi baris kode berikut ini.

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ArticleResource;
use App\Models\Article;
use App\Models\User;
use Illuminate\Http\Request;

class ArticleController extends Controller
{
    public function index()
    {
        return response()->json([
            'data' => ArticleResource::collection(Article::with('author')->paginate()),
        ])->header('Content-Type', 'application/vnd.api+json');
    }

    public function show($id)
    {
        $article = Article::with('author')->find($id);

        if (!$article) {
            return response()->json([
                'errors' => [
                    'status' => '404',
                    'title' => 'Not Found',
                    'detail' => 'Article not found.'
                ]
            ], 404)->header('Content-Type', 'application/vnd.api+json');
        }

        return (new ArticleResource($article))
            ->response()
            ->header('Content-Type', 'application/vnd.api+json');
    }

    public function store(Request $request)
    {
        $validatedData = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'published_at' => 'nullable|date',
            'author_id' => 'required|exists:users,id'
        ]);

        $article = new Article($validatedData);
        $article->author()->associate(User::find($validatedData['author_id']));
        $article->save();

        return (new ArticleResource($article))
            ->response()
            ->header('Content-Type', 'application/vnd.api+json')
            ->setStatusCode(201);
    }

    public function update(Request $request, $id)
    {
        $article = Article::find($id);

        if (!$article) {
            return response()->json([
                'errors' => [
                    'status' => '404',
                    'title' => 'Not Found',
                    'detail' => 'Article not found.'
                ]
            ], 404)->header('Content-Type', 'application/vnd.api+json');
        }

        $validatedData = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'content' => 'sometimes|required|string',
            'published_at' => 'nullable|date',
            'author_id' => 'sometimes|required|exists:users,id'
        ]);

        $article->update($validatedData);

        if (isset($validatedData['author_id'])) {
            $article->author()->associate(User::find($validatedData['author_id']));
        }

        return (new ArticleResource($article))
            ->response()
            ->header('Content-Type', 'application/vnd.api+json');
    }

    public function destroy($id)
    {
        $article = Article::find($id);

        if (!$article) {
            return response()->json([
                'errors' => [
                    'status' => '404',
                    'title' => 'Not Found',
                    'detail' => 'Article not found.'
                ]
            ], 404)->header('Content-Type', 'application/vnd.api+json');
        }

        $article->delete();

        return response()->json([], 204)->header('Content-Type', 'application/vnd.api+json');
    }
}

```



## Step 6: Register Route Baru{#step-6-register-route-baru}

Secara default file `routes/api.php` tidak tersedia di laravel 11. Kita harus generate terlebih dahulu file tersebut. Sekarang kita buka terminal, lalu run command berikut ini.

```
php artisan install:api
```

Setelah proses setup selesai, kita bisa lihat file route `routes/api.php`. 



Buka file `routes/api.php`, lalu kita tambahkan route baru.

```
<?php

// ... baris kode lainnya

use App\Http\Controllers\Api\ArticleController; // tambahkan ini

// ... baris kode lainnya

// tambahkan baris kode berikut ini
Route::prefix('v1')->group(function () {
    Route::apiResource('articles', ArticleController::class);
});
```

Save kembali file `routes/api.php`.



## Step 7: Uji Coba{#step-7-uji-coba}

Pada tahapan ini, bagian pertama tutorial ini telah selesai. Selanjutnya kita akan masuk ke proses uji coba api yang sebelumnya sudah kita coding.



###  Step 7.1: Setup Phpunit

Sekarang kita atur konfigurasi phpunit terlebih dahulu. Buka file `phpunit.xml`, lalu temukan baris kode berikut ini.

```
        <env name="APP_ENV" value="testing"/>
        <env name="APP_MAINTENANCE_DRIVER" value="file"/>
        <env name="BCRYPT_ROUNDS" value="4"/>
        <env name="CACHE_STORE" value="array"/>
        <!-- <env name="DB_CONNECTION" value="sqlite"/> -->
        <!-- <env name="DB_DATABASE" value=":memory:"/> -->
        <env name="MAIL_MAILER" value="array"/>
        <env name="PULSE_ENABLED" value="false"/>
        <env name="QUEUE_CONNECTION" value="sync"/>
        <env name="SESSION_DRIVER" value="array"/>
        <env name="TELESCOPE_ENABLED" value="false"/>
```

Lalu kita hapus komentar untuk `DB_CONNECTION` dan `DB_DATABASE`.

```
        <env name="APP_ENV" value="testing"/>
        <env name="APP_MAINTENANCE_DRIVER" value="file"/>
        <env name="BCRYPT_ROUNDS" value="4"/>
        <env name="CACHE_STORE" value="array"/>
        <env name="DB_CONNECTION" value="sqlite"/> 
        <env name="DB_DATABASE" value=":memory:"/> 
        <env name="MAIL_MAILER" value="array"/>
        <env name="PULSE_ENABLED" value="false"/>
        <env name="QUEUE_CONNECTION" value="sync"/>
        <env name="SESSION_DRIVER" value="array"/>
        <env name="TELESCOPE_ENABLED" value="false"/>
```

Save kembali file `phpunit.xml`.

### Step 7.2: Create Factory Class

Untuk melakukan uji coba kita perlu sample data. Oleh karena itu kita perlu membuat terlebih dahulu factory class. Untuk generate Factory Class untuk model `Article`, buka kembali terminal, lalu run command berikut ini.

```
php artisan make:factory ArticleFactory --model=Article
```

Output:

```
   INFO  Factory [database/factories/ArticleFactory.php] created successfully.
```



Selanjutnya kita buka file `database/factories/ArticleFactory.php`, lalu kita sesuaikan baris kode untuk method `definition()`.

```
<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use App\Models\User; // tambahkan ini

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Article>
 */
class ArticleFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'title' => $this->faker->sentence,
            'content' => $this->faker->paragraph,
            'published_at' => $this->faker->optional()->dateTime,
            'author_id' => User::factory(), // Relasi ke User
        ];
    }
}
```

Jangan lupa tambahkan `use` statement.

```
use App\Models\User;
```



Setelah selesai kita save kembali file `database/factories/ArticleFactory.php`.

### Step 7.3: Create Testing Class

Selanjutnya kita buat file testing untuk menguji api endpoint.

```
php artisan make:test ArticleApiTest
```

Output:

```
   INFO  Test [tests/Feature/ArticleApiTest.php] created successfully. 
```



Selanjutnya kita buka file `tests/Feature/ArticleApiTest.php`, lalu kita sesuaikan seperti baris kode berikut ini.

```
<?php
namespace Tests\Feature;

use App\Models\Article;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ArticleApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_an_article()
    {
        $user = User::factory()->create();
        $data = [
            'title' => 'New Article',
            'content' => 'Article content',
            'published_at' => now(),
            'author_id' => $user->id
        ];

        $response = $this->postJson('/api/v1/articles', $data);

        $response->assertStatus(201)
            ->assertJson([
                'data' => [
                    'type' => 'articles',
                    'attributes' => [
                        'title' => 'New Article',
                        'content' => 'Article content',
                    ]
                ]
            ]);

        // Periksa data di database
        $this->assertDatabaseHas('articles', [
            'title' => 'New Article',
            'content' => 'Article content',
            'author_id' => $user->id
        ]);
    }

    public function test_user_can_get_article_list()
    {
        Article::factory()->count(3)->create();

        $response = $this->getJson('/api/v1/articles');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    '*' => ['type', 'id', 'attributes']
                ]
            ]);
    }

    public function test_user_can_get_a_single_article()
    {
        $article = Article::factory()->create();

        $response = $this->getJson('/api/v1/articles/' . $article->id);

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'type' => 'articles',
                    'id' => (string) $article->id,
                    'attributes' => [
                        'title' => $article->title,
                        'content' => $article->content,
                    ]
                ]
            ]);
    }

    public function test_user_can_update_an_article()
    {
        $article = Article::factory()->create();
        $data = [
            'title' => 'Updated Article Title',
            'content' => 'Updated Article Content'
        ];

        $response = $this->patchJson('/api/v1/articles/' . $article->id, $data);

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'type' => 'articles',
                    'attributes' => [
                        'title' => 'Updated Article Title',
                        'content' => 'Updated Article Content',
                    ]
                ]
            ]);

        $this->assertDatabaseHas('articles', $data);
    }

    public function test_user_can_delete_an_article()
    {
        $article = Article::factory()->create();

        $response = $this->deleteJson('/api/v1/articles/' . $article->id);

        $response->assertStatus(204);
        $this->assertDatabaseMissing('articles', ['id' => $article->id]);
    }
}
```



Save kembali file `tests/Feature/ArticleApiTest.php`.



### Step 7.4: Run Testing

Langkah selanjutnya adalah menjalankan test cases . Untuk menjalankan test cases, gunakan perintah berikut di terminal:

```
php artisan test
```

Output:

```
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ArticleApiTest
  ✓ user can create an article                                           0.13s  
  ✓ user can get article list                                            0.01s  
  ✓ user can get a single article                                        0.01s  
  ✓ user can update an article                                           0.01s  
  ✓ user can delete an article                                           0.01s  

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.01s  

  Tests:    7 passed (24 assertions)
  Duration: 0.21s

```



Seperti yang terlihat pada output terminal di atas pada bagian berikut ini.

```
   PASS  Tests\Feature\ArticleApiTest
  ✓ user can create an article                                           0.13s  
  ✓ user can get article list                                            0.01s  
  ✓ user can get a single article                                        0.01s  
  ✓ user can update an article                                           0.01s  
  ✓ user can delete an article                                           0.01s 
```

API yang telah kita bangun pass testing yang kita tulis.

## Penutup{#penutup}

Pada tutorial laravel ini kita sudah bahas apa itu spesifikasi JSON:API secara singkat. Selain itu kita sudah coba implementasikan spesifikasi tersebut untuk membangun API untuk data `articles`. Pada bagian kedua tutorial, kita juga coba menuliskan feature testing untuk menguji masing-masing endpoint yang sebelumnya sudah kita coding untuk membangun API. Setelah kita run testing, kita bisa lihat API yang kita bangun lolos testing.



## Selanjutnya

Pada tutorial ini kita hanya membahas JSON:API Spesification secara sekilas, untuk mempelajari lebih jauh teman-teman dapat mengunjungi situs resmi JSON:API Specification, yaitu [https://jsonapi.org](https://jsonapi.org).