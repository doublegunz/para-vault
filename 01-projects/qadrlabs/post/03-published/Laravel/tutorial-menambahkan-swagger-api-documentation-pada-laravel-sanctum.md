---
title: "Tutorial: Menambahkan Swagger API Documentation pada Laravel Sanctum"
slug: "tutorial-menambahkan-swagger-api-documentation-pada-laravel-sanctum"
category: "Laravel"
date: "2025-08-18"
status: "published"
---

Selamat datang kembali di seri tutorial Laravel API! Pada pembahasan sebelumnya, kita telah berhasil membangun sistem authentication REST API menggunakan laravel sanctum yang mencakup fitur register, login, logout dan pengambilan data user. Sistem yang telah kita buat berfungsi dengan baik dan siap digunakan. Namun, ada satu aspek penting yang masih perlu kita tambahkan agar API kita lebih profesional dan mudah digunakan oleh developer lain - yaitu dokumentasi.

Dalam pengembangan API, dokumentasi memegang peranan krusial sebagai jembatan komunikasi antara backend developer dengan frontend developer atau pihak ketiga yang akan mengonsumsi API. Tanpa dokumentasi yang jelas, developer lain akan kesulitan memahami endpoint yang akan diterima, hingga cara melakukan authentication. Hal ini tentunya akan memperlambat proses integrasi dan meningkatkan potensi kesalahan dalam implementasi.

Di sinilah Swagger hadir sebagai solusi. Swagger adalah framework dokumentasi yang telah menjadi standar de facto dalam industri untuk mendokumentasikan RESTful API. Berbeda dengan dokumentasi tradisional yang statis, Swagger menawarkan pendekatan interaktif yang memungkinkan developer tidak hanya membaca dokumentasi, tetapi juga mencoba setiap endpoint secara langsung melalui browser. Fitur "try it out" yang disediakan Swagger UI mengeliminasi kebutuhan tools eksternal seperti Postman untuk tahap eksplorasi API.

Pada tutorial kali ini, kita akan melanjutkan project Laravel Sanctum yang telah kita bangun dengan mengintegrasikan Swagger untuk menghasilkan dokumentasi API yang profesional dan interaktif. Kita akan menggunakan package L5-Swagger yang merupakan wrapper khusus untuk Laravel, sehingga proses integrasi menjadi lebih mudah dan natural dengan struktur project Laravel kita.

## Tutorial Menambahkan Swagger API Documentation{#table-of-content}

- [Overview](#overview)
- [Persiapan](#persiapan)
- [Step 1 - Install L5-Swagger Package](#step-1)
- [Step 2 - Konfigurasi Swagger](#step-2)
- [Step 3 - Update AuthController dengan Anotasi Swagger](#step-3)
- [Step 4 - Tambahkan Anotasi untuk Route User](#step-4)
- [Step 5 - Generate Documentation](#step-5)
- [Step 6 - Uji Coba Documentation](#step-6)
- [Kustomisasi Tambahan](#kustomisasi)
- [Penutup](#penutup)

## Overview{#overview}

Pada tutorial ini kita akan melanjutkan project Laravel Sanctum yang telah dibuat sebelumnya, yaitu tutorial [REST API Authentication dengan Laravel Sanctum](https://qadrlabs.com/post/rest-api-authentication-with-laravel-sanctum), dengan menambahkan dokumentasi API menggunakan Swagger. Kita akan menggunakan package L5-Swagger yang merupakan implementasi Swagger untuk Laravel. Package ini memungkinkan kita untuk menambahkan anotasi pada controller yang kemudian akan di-generate menjadi dokumentasi API yang interaktif.

Setelah menyelesaikan tutorial ini, project kita akan memiliki dokumentasi API yang dapat diakses melalui browser dengan tampilan yang profesional. Dokumentasi ini akan mencakup semua endpoint yang telah kita buat sebelumnya yaitu register, login, logout, dan get user data. Selain itu, dokumentasi ini juga akan mendukung authentication menggunakan Bearer token sehingga kita dapat menguji endpoint yang memerlukan authentication secara langsung dari interface Swagger.

## Persiapan{#persiapan}

Sebelum memulai tutorial ini, pastikan Anda telah menyelesaikan tutorial sebelumnya tentang REST API Authentication dengan Laravel Sanctum. Project yang akan kita gunakan adalah project yang sama dengan tutorial sebelumnya, jadi pastikan project tersebut masih berjalan dengan baik dan semua endpoint API dapat diakses dengan normal.

Selain itu, pastikan juga bahwa database yang digunakan masih dalam kondisi yang sama seperti di akhir tutorial sebelumnya, dengan tabel users dan personal_access_tokens yang telah ter-migrate dengan benar.

## Step 1 - Install L5-Swagger Package{#step-1}

Langkah pertama yang perlu kita lakukan adalah menginstall package L5-Swagger. Package ini merupakan implementasi Swagger untuk Laravel yang akan membantu kita membuat dokumentasi API. Buka terminal dan pastikan Anda berada di direktori project Laravel Sanctum yang telah dibuat sebelumnya, kemudian jalankan command berikut untuk menginstall package.

```bash
composer require "darkaonline/l5-swagger"
```

Tunggu hingga proses instalasi selesai. Package ini akan mendownload semua dependency yang diperlukan untuk menjalankan Swagger pada Laravel.

Setelah instalasi selesai, kita perlu mempublish file konfigurasi Swagger ke dalam project kita. Jalankan command berikut untuk mempublish konfigurasi.

```bash
php artisan vendor:publish --provider "L5Swagger\L5SwaggerServiceProvider"
```

Command ini akan membuat file konfigurasi `config/l5-swagger.php` dan beberapa file view yang diperlukan untuk menampilkan interface Swagger. File konfigurasi ini berisi pengaturan-pengaturan penting untuk customize tampilan dan behavior dari dokumentasi Swagger yang akan kita buat.

## Step 2 - Konfigurasi Swagger{#step-2}

Setelah menginstall package L5-Swagger, langkah selanjutnya adalah mengkonfigurasi pengaturan Swagger sesuai dengan kebutuhan project kita. Buka file `config/l5-swagger.php` yang telah di-generate pada step sebelumnya.

Pada file konfigurasi ini, kita perlu memastikan beberapa pengaturan penting telah sesuai. Cari bagian konfigurasi dan pastikan pengaturan berikut ini sudah sesuai.

```php
'default' => 'default',
'documentations' => [
    'default' => [
        'api' => [
            'title' => 'Laravel Sanctum API Documentation',
        ],
        'routes' => [
            'api' => 'api/documentation',
        ],
        'paths' => [
            'use_absolute_path' => env('L5_SWAGGER_USE_ABSOLUTE_PATH', true),
            'docs_json' => 'api-docs.json',
            'docs_yaml' => 'api-docs.yaml',
            'format_to_use_for_docs' => env('L5_FORMAT_TO_USE_FOR_DOCS', 'json'),
            'annotations' => [
                base_path('app'),
            ],
        ],
    ],
],
```

Konfigurasi di atas mengatur beberapa hal penting. Bagian `title` menentukan judul yang akan ditampilkan pada halaman dokumentasi. Bagian `routes` menentukan URL dimana dokumentasi dapat diakses, dalam hal ini dokumentasi akan dapat diakses di `/api/documentation`. Bagian `annotations` menentukan direktori mana yang akan dipindai untuk mencari anotasi Swagger, dalam hal ini direktori `app` yang berisi semua controller kita.

Save file `config/l5-swagger.php` setelah melakukan perubahan konfigurasi.

## Step 3 - Update AuthController dengan Anotasi Swagger{#step-3}

Sekarang kita akan menambahkan anotasi Swagger pada AuthController yang telah dibuat pada tutorial sebelumnya. Anotasi ini akan digunakan untuk mengenerate dokumentasi API secara otomatis berdasarkan kode yang telah kita tulis.

Buka file `app/Http/Controllers/Api/AuthController.php` dan kita akan menambahkan anotasi Swagger untuk setiap method yang ada. Pertama-tama, tambahkan anotasi utama untuk mendefinsikan informasi umum tentang API kita di bagian atas class.

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

/**
 * @OA\Info(
 *     title="Laravel Sanctum API",
 *     version="1.0.0",
 *     description="API Documentation untuk Laravel Sanctum Authentication",
 *     @OA\Contact(
 *         email="admin@example.com"
 *     )
 * )
 * 
 * @OA\SecurityScheme(
 *     securityScheme="bearerAuth",
 *     type="http",
 *     scheme="bearer",
 *     bearerFormat="JWT"
 * )
 */
class AuthController extends Controller
{
    // method akan ditambahkan di sini
}
```

Anotasi `@OA\Info` mendefinisikan informasi umum tentang API seperti title, versi, dan deskripsi. Anotasi `@OA\SecurityScheme` mendefinisikan skema authentication yang digunakan, dalam hal ini Bearer token authentication yang menggunakan token dari Laravel Sanctum.

Sekarang kita akan menambahkan anotasi untuk method `register()`. Tambahkan anotasi berikut tepat di atas method register yang sudah ada.

```php
    /**
     * @OA\Post(
     *     path="/api/register",
     *     tags={"Authentication"},
     *     summary="Register user baru",
     *     description="Mendaftarkan user baru dan mengembalikan access token",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\MediaType(
     *             mediaType="application/x-www-form-urlencoded",
     *             @OA\Schema(
     *                 required={"name", "email", "password"},
     *                 @OA\Property(property="name", type="string", example="John Doe"),
     *                 @OA\Property(property="email", type="string", format="email", example="john@example.com"),
     *                 @OA\Property(property="password", type="string", format="password", minLength=8, example="password123")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="User berhasil didaftarkan",
     *         @OA\JsonContent(
     *             @OA\Property(
     *                 property="data",
     *                 type="object",
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="name", type="string", example="John Doe"),
     *                 @OA\Property(property="email", type="string", example="john@example.com"),
     *                 @OA\Property(property="created_at", type="string", example="2023-01-01T00:00:00.000000Z"),
     *                 @OA\Property(property="updated_at", type="string", example="2023-01-01T00:00:00.000000Z")
     *             ),
     *             @OA\Property(property="access_token", type="string", example="1|abcdef123456"),
     *             @OA\Property(property="token_type", type="string", example="Bearer")
     *         )
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Validation error",
     *         @OA\JsonContent(
     *             @OA\Property(property="name", type="array", @OA\Items(type="string")),
     *             @OA\Property(property="email", type="array", @OA\Items(type="string")),
     *             @OA\Property(property="password", type="array", @OA\Items(type="string"))
     *         )
     *     )
     * )
     */
    public function register(Request $request)
    {
        // kode method register tetap sama seperti sebelumnya
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|max:255|unique:users',
            'password' => 'required|string|min:8'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors());
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password)
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'data' => $user,
            'access_token' => $token,
            'token_type' => 'Bearer'
        ]);
    }
```

Anotasi untuk method register ini mendefinisikan berbagai aspek dari endpoint register. Bagian `@OA\Post` menunjukkan bahwa ini adalah endpoint POST dengan path `/api/register`. Bagian `@OA\RequestBody` mendefinisikan parameter yang diperlukan untuk request, sementara `@OA\Response` mendefinisikan format response yang akan dikembalikan beserta contoh datanya.

Selanjutnya, tambahkan anotasi untuk method `login()`.

```php
    /**
     * @OA\Post(
     *     path="/api/login",
     *     tags={"Authentication"},
     *     summary="Login user",
     *     description="Login user dan mengembalikan access token",
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\MediaType(
     *             mediaType="application/x-www-form-urlencoded",
     *             @OA\Schema(
     *                 required={"email", "password"},
     *                 @OA\Property(property="email", type="string", format="email", example="john@example.com"),
     *                 @OA\Property(property="password", type="string", format="password", example="password123")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Login berhasil",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Login success"),
     *             @OA\Property(property="access_token", type="string", example="1|abcdef123456"),
     *             @OA\Property(property="token_type", type="string", example="Bearer")
     *         )
     *     ),
     *     @OA\Response(
     *         response=401,
     *         description="Unauthorized",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Unauthorized")
     *         )
     *     )
     * )
     */
    public function login(Request $request)
    {
        // kode method login tetap sama seperti sebelumnya
        if (! Auth::attempt($request->only('email', 'password'))) {
            return response()->json([
                'message' => 'Unauthorized'
            ], 401);
        }

        $user = User::where('email', $request->email)->firstOrFail();

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login success',
            'access_token' => $token,
            'token_type' => 'Bearer'
        ]);
    }
```

Dan terakhir, tambahkan anotasi untuk method `logout()`.

```php
    /**
     * @OA\Post(
     *     path="/api/logout",
     *     tags={"Authentication"},
     *     summary="Logout user",
     *     description="Logout user dan menghapus semua token",
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="Logout berhasil",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="logout success")
     *         )
     *     ),
     *     @OA\Response(
     *         response=401,
     *         description="Unauthenticated",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Unauthenticated.")
     *         )
     *     )
     * )
     */
    public function logout()
    {
        // kode method logout tetap sama seperti sebelumnya
        Auth::user()->tokens()->delete();
        return response()->json([
            'message' => 'logout success'
        ]);
    }
```

Perhatikan bahwa pada anotasi method logout terdapat bagian `security={{"bearerAuth":{}}}` yang menunjukkan bahwa endpoint ini memerlukan authentication menggunakan Bearer token. Hal ini sesuai dengan middleware `auth:sanctum` yang telah kita definisikan pada route logout di tutorial sebelumnya.

Save file `AuthController.php` setelah menambahkan semua anotasi.

## Step 4 - Tambahkan Anotasi untuk Route User{#step-4}

Selain endpoint authentication, kita juga perlu menambahkan anotasi untuk endpoint get user data yang telah dibuat di tutorial sebelumnya. Karena endpoint ini didefinisikan langsung di file routes, kita perlu membuat anotasi terpisah atau menambahkannya di AuthController.

Untuk mempermudah, kita akan menambahkan anotasi untuk endpoint get user di AuthController. Tambahkan anotasi berikut di dalam class AuthController setelah method logout.

```php
    /**
     * @OA\Get(
     *     path="/api/user",
     *     tags={"User"},
     *     summary="Get data user yang sedang login",
     *     description="Mendapatkan data user berdasarkan token yang diberikan",
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="Data user berhasil diambil",
     *         @OA\JsonContent(
     *             @OA\Property(property="id", type="integer", example=1),
     *             @OA\Property(property="name", type="string", example="John Doe"),
     *             @OA\Property(property="email", type="string", example="john@example.com"),
     *             @OA\Property(property="email_verified_at", type="string", nullable=true),
     *             @OA\Property(property="created_at", type="string", example="2023-01-01T00:00:00.000000Z"),
     *             @OA\Property(property="updated_at", type="string", example="2023-01-01T00:00:00.000000Z")
     *         )
     *     ),
     *     @OA\Response(
     *         response=401,
     *         description="Unauthenticated",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Unauthenticated.")
     *         )
     *     )
     * )
     */
    public function user(): void
    {

    }
```

Anotasi ini mendefinisikan endpoint GET `/api/user` yang memerlukan authentication dan mengembalikan data user yang sedang login. Meskipun kita tidak membuat method untuk ini di AuthController, anotasi ini akan tetap terbaca oleh Swagger generator karena berada di dalam class yang dipindai.

Save kembali file `AuthController.php`.

## Step 5 - Generate Documentation{#step-5}

Setelah menambahkan semua anotasi yang diperlukan, langkah selanjutnya adalah meng-generate dokumentasi Swagger berdasarkan anotasi yang telah kita buat. Buka terminal dan pastikan Anda berada di direktori project, kemudian jalankan command berikut.

```bash
php artisan l5-swagger:generate
```

Command ini akan memindai semua file di direktori `app` untuk mencari anotasi Swagger dan kemudian meng-generate file dokumentasi dalam format JSON. Jika proses generate berhasil, Anda akan melihat output seperti berikut di terminal.

```
Regenerating docs
Writing to .../storage/api-docs/api-docs.json
```

Output ini menunjukkan bahwa file dokumentasi telah berhasil di-generate dan disimpan di direktori `storage/api-docs/api-docs.json`. File inilah yang akan digunakan oleh Swagger UI untuk menampilkan dokumentasi API kita.

Jika terjadi error saat proses generate, periksa kembali anotasi yang telah ditambahkan. Pastikan tidak ada syntax error dalam anotasi dan semua tag telah ditutup dengan benar.

## Step 6 - Uji Coba Documentation{#step-6}

Sekarang saatnya untuk menguji dokumentasi Swagger yang telah kita buat. Pertama-tama, pastikan Laravel development server masih berjalan. Jika belum, jalankan command berikut di terminal.

```bash
php artisan serve
```

Setelah server berjalan, buka browser dan akses URL berikut untuk melihat dokumentasi Swagger.

```
http://127.0.0.1:8000/api/documentation
```

Anda akan melihat halaman Swagger UI yang menampilkan semua endpoint API yang telah kita dokumentasikan. Interface ini menampilkan endpoint yang dikelompokkan berdasarkan tag yang telah kita definisikan, yaitu "Authentication" dan "User".

### Uji Coba Endpoint Register

Untuk menguji endpoint register melalui Swagger UI, ikuti langkah berikut. Klik pada endpoint POST `/api/register` untuk membuka detail endpoint. Kemudian klik tombol "Try it out" yang berada di bagian kanan atas. Setelah itu, form input akan muncul dimana Anda dapat memasukkan data untuk testing.

Isi form dengan data sample seperti berikut. Pada field `name` masukkan "John Doe", pada field `email` masukkan "john@example.com", dan pada field `password` masukkan "password123". Setelah mengisi semua field, klik tombol "Execute" untuk mengirim request.

Swagger akan menampilkan response yang dikembalikan oleh API beserta status code dan header. Jika berhasil, Anda akan melihat response dengan status 200 yang berisi data user dan access token, sama seperti ketika kita menguji menggunakan Postman pada tutorial sebelumnya.

### Uji Coba Endpoint Login

Setelah berhasil register, kita dapat menguji endpoint login. Klik pada endpoint POST `/api/login` dan klik "Try it out". Masukkan email dan password yang sama dengan yang digunakan saat register, kemudian klik "Execute".

Jika berhasil, response akan berisi message "Login success" beserta access token yang dapat kita gunakan untuk testing endpoint yang memerlukan authentication.

### Uji Coba Endpoint dengan Authentication

Untuk menguji endpoint yang memerlukan authentication seperti logout atau get user data, kita perlu terlebih dahulu melakukan setup authentication di Swagger UI. Copy access token yang didapat dari proses login, kemudian klik tombol "Authorize" yang berada di bagian atas halaman Swagger UI.

Pada dialog yang muncul, masukkan token dengan format `Bearer [access_token]`. Misalnya jika token yang didapat adalah "1|abcdef123456", maka masukkan "Bearer 1|abcdef123456" pada field value. Setelah itu klik "Authorize" dan kemudian "Close".

Sekarang Anda dapat menguji endpoint GET `/api/user` dan POST `/api/logout`. Kedua endpoint ini akan secara otomatis menggunakan token yang telah diset untuk authentication. Hasil yang diperoleh akan sama dengan hasil testing menggunakan Postman pada tutorial sebelumnya.

## Kustomisasi Tambahan{#kustomisasi}

Swagger UI yang telah kita setup dapat dikustomisasi lebih lanjut untuk memenuhi kebutuhan yang lebih spesifik. Salah satu kustomisasi yang dapat dilakukan adalah mengubah tampilan interface atau menambahkan informasi server environment.

Untuk mengubah tampilan, kita dapat memodifikasi file konfigurasi `config/l5-swagger.php`. Cari bagian `ui` dan sesuaikan pengaturan sesuai kebutuhan.

```php
'ui' => [
    'display' => [
        'dark_mode' => false,
        'doc_expansion' => 'none',
        'filter' => true,
    ],
],
```

Pengaturan `dark_mode` dapat diubah menjadi `true` untuk mengaktifkan tema gelap. Pengaturan `doc_expansion` menentukan apakah endpoint akan ditampilkan dalam keadaan expanded atau collapsed secara default. Pengaturan `filter` mengaktifkan fitur pencarian endpoint.

Kita juga dapat menambahkan informasi server environment pada anotasi utama di AuthController. Tambahkan anotasi berikut setelah anotasi `@OA\Info`.

```php
/**
 * @OA\Server(
 *     url="http://127.0.0.1:8000",
 *     description="Development Server"
 * )
 * 
 * @OA\Server(
 *     url="https://api.yourdomain.com",
 *     description="Production Server"
 * )
 */
```

Anotasi ini akan menambahkan dropdown server selection pada Swagger UI, sehingga pengguna dapat memilih server mana yang akan digunakan untuk testing API.

Setelah melakukan kustomisasi, jangan lupa untuk meng-generate ulang dokumentasi dengan menjalankan `php artisan l5-swagger:generate`.

## Penutup{#penutup}

Pada tutorial Laravel kali ini kita telah berhasil menambahkan dokumentasi API menggunakan Swagger pada project Laravel Sanctum yang telah dibuat sebelumnya. Dengan menggunakan package L5-Swagger, kita dapat dengan mudah membuat dokumentasi API yang interaktif dan profesional hanya dengan menambahkan anotasi pada controller yang sudah ada.

Dokumentasi Swagger yang telah kita buat mencakup semua endpoint API yang tersedia yaitu register, login, logout, dan get user data. Selain itu, dokumentasi ini juga mendukung authentication menggunakan Bearer token sehingga memudahkan proses testing endpoint yang memerlukan authentication. Interface Swagger UI yang dihasilkan sangat user-friendly dan memungkinkan developer lain untuk dengan mudah memahami dan menggunakan API yang telah kita buat.

Keuntungan utama menggunakan Swagger adalah dokumentasi akan selalu sinkron dengan kode yang ada karena di-generate berdasarkan anotasi yang ada di dalam kode itu sendiri. Hal ini memastikan bahwa dokumentasi tidak akan tertinggal ketika ada perubahan pada API. Selain itu, interface yang interaktif memungkinkan testing API secara langsung tanpa perlu menggunakan tools tambahan seperti Postman.

Untuk pengembangan selanjutnya, Anda dapat menambahkan anotasi Swagger pada controller atau endpoint lain yang mungkin akan ditambahkan ke dalam project. Anda juga dapat mengeksplorasi fitur-fitur lanjutan dari Swagger seperti grouping endpoint, menambahkan example yang lebih kompleks, atau mengintegrasikan dengan testing automation. Dokumentasi API yang baik merupakan salah satu kunci kesuksesan dalam pengembangan aplikasi berbasis API, terutama ketika bekerja dalam tim atau ketika API akan digunakan oleh developer lain.