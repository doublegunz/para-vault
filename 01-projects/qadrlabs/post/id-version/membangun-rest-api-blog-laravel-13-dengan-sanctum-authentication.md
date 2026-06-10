---
title: "Laravel 13: Membangun REST API untuk Blog Anda dengan Sanctum Authentication"
slug: "membangun-rest-api-blog-laravel-13-dengan-sanctum-authentication"
original_title: "Laravel 13: Build a REST API for Your Blog with Sanctum Authentication"
original_slug: "laravel-13-build-a-rest-api-for-your-blog-with-sanctum-authentication"
category: "Laravel"
date: "2026-03-26"
status: "draft"
---

Aplikasi blog kita bekerja dengan baik di browser. Tetapi bagaimana jika Anda ingin membangun aplikasi mobile, frontend Vue.js, atau membiarkan service lain berinteraksi dengan data blog Anda? Anda membutuhkan sebuah API.

Pada tutorial ini, kita akan menambahkan lapisan REST API di atas aplikasi blog yang sudah ada. Kita akan menggunakan Laravel Sanctum untuk authentication berbasis token, membuat API controller dan resource class khusus, serta menulis Pest test untuk memverifikasi setiap endpoint.

Ini adalah Bagian 6 dari seri tutorial blog Laravel 13 kita, melanjutkan [tutorial CRUD](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step), [tutorial testing](https://qadrlabs.com/post/laravel-13-testing-with-pest-write-tests-for-your-crud-application), [tutorial refactoring Form Request](https://qadrlabs.com/post/laravel-13-refactor-your-controller-with-form-request-validation), dan [tutorial authentication dan authorization](https://qadrlabs.com/post/laravel-13-add-authentication-and-authorization-with-php-attributes).


## Ikhtisar {#overview}

Kita akan membangun REST API lengkap yang mencerminkan fungsi CRUD web, dengan sistem authentication terpisah yang berbasis API token.

### What You'll Build

- Endpoint authentication berbasis token (register, login, logout).
- Endpoint API RESTful untuk menampilkan daftar, membuat, melihat, memperbarui, dan menghapus post.
- API resource class untuk format JSON response yang konsisten.
- Pemeriksaan authorization agar user hanya dapat memodifikasi post miliknya sendiri.
- Sebuah Pest test suite lengkap untuk setiap endpoint API.

### What You'll Learn

- Cara menginstal dan mengonfigurasi Laravel Sanctum.
- Cara membangun endpoint authentication yang menerbitkan dan mencabut API token.
- Cara membuat controller khusus API yang terpisah dari web controller.
- Cara menggunakan Eloquent API Resources untuk memformat JSON response.
- Cara melindungi route API dengan Sanctum middleware.
- Cara menggunakan kembali Form Request dan Policy yang sudah ada di lapisan API.
- Cara menulis API test menggunakan `actingAs()` dengan Sanctum.

### What You'll Need

- Proyek blog yang sudah selesai beserta authentication dan authorization dari [tutorial sebelumnya](https://qadrlabs.com/post/laravel-13-add-authentication-and-authorization-with-php-attributes).
- PHP 8.3 atau lebih tinggi.
- Pemahaman dasar tentang REST API dan JSON.


## Step 1: Menginstal Sanctum {#step-1-install-sanctum}

Laravel Sanctum menyediakan sistem authentication yang ringan untuk SPA (single page application), aplikasi mobile, dan API berbasis token. Ia memungkinkan setiap user menghasilkan beberapa API token dengan kemampuan tertentu.

Instal Sanctum dan siapkan file route API:

```
php artisan install:api
```

Perintah ini melakukan beberapa hal sekaligus:

- Menginstal package `laravel/sanctum`.
- Mem-publish file migration milik Sanctum (membuat tabel `personal_access_tokens`).
- Membuat file `routes/api.php`.
- Mendaftarkan route API di route service provider aplikasi Anda.
- Menjalankan migration.

Setelah perintah selesai, verifikasi bahwa trait `HasApiTokens` sudah ditambahkan ke model `User` Anda. Buka `app/Models/User.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    // ... existing code

    public function posts(): HasMany
    {
        return $this->hasMany(Post::class);
    }
}
```

Trait `HasApiTokens` menambahkan method `createToken()` dan `tokens()` ke model User, yang akan kita gunakan untuk menerbitkan dan mengelola API token.

Simpan file.


## Step 2: Membuat API Resource Class {#step-2-create-api-resources}

API Resources mengubah model Eloquent Anda menjadi JSON response yang terstruktur. Mereka memberi Anda kontrol atas field mana saja yang disertakan dan bagaimana relationship diformat.

### Create the PostResource

```
php artisan make:resource PostResource
```

Buka `app/Http/Resources/PostResource.php`:

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PostResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'slug' => $this->slug,
            'content' => $this->content,
            'status' => $this->status,
            'author' => [
                'id' => $this->user->id,
                'name' => $this->user->name,
            ],
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
```

Method `toArray()` mendefinisikan struktur JSON untuk setiap post. Alih-alih mengembalikan model mentah beserta seluruh kolomnya (termasuk `user_id`, `embedding`, atau field internal lainnya), kita secara eksplisit hanya mencantumkan field yang dibutuhkan oleh konsumen API. Key `author` menyarangkan `id` dan `name` milik user untuk response yang lebih bersih daripada mengekspos foreign key `user_id` mentah.

Kita mengakses `$this->user` secara langsung karena resource mem-proxy akses property ke model yang mendasarinya. Kita akan memastikan untuk melakukan eager-load relationship ini di controller.

Simpan file.


## Step 3: Membuat API Authentication Controller {#step-3-auth-controller}

Authentication API bekerja berbeda dari authentication web. Alih-alih session dan cookie, kita menerbitkan token yang disertakan client di setiap request.

Buat controller:

```
php artisan make:controller Api/AuthController
```

Buka `app/Http/Controllers/Api/AuthController.php`:

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Register a new user and return a token.
     */
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'message' => 'Registration successful.',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
            'token' => $token,
        ], 201);
    }

    /**
     * Login and return a token.
     */
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'message' => 'Login successful.',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
            'token' => $token,
        ]);
    }

    /**
     * Logout and revoke the current token.
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully.',
        ]);
    }
}
```

Berikut adalah alur untuk setiap endpoint:

**Register:** Memvalidasi input (termasuk `password_confirmation` melalui aturan `confirmed`), membuat user baru dengan password yang sudah di-hash, menghasilkan API token menggunakan `createToken('api-token')`, dan mengembalikan token beserta data user. Property `plainTextToken` memberi kita string token mentah yang perlu disimpan client. Ini adalah satu-satunya saat token plain text tersedia; Sanctum menyimpan versi yang sudah di-hash di database.

**Login:** Mencari user berdasarkan email, memeriksa password dengan `Hash::check()`, dan menerbitkan token baru jika credentials valid. Jika credentials salah, ia melempar sebuah `ValidationException` yang dikonversi Laravel menjadi JSON response 422 beserta pesan error. Setiap login membuat token baru, sehingga seorang user dapat login dari beberapa perangkat secara bersamaan.

**Logout:** Menghapus hanya token saat ini menggunakan `currentAccessToken()->delete()`. Ini mencabut akses untuk perangkat yang membuat request logout tanpa memengaruhi token di perangkat lain. Jika Anda ingin logout dari semua perangkat, Anda akan menggunakan `$request->user()->tokens()->delete()` sebagai gantinya.

Simpan file.


## Step 4: Membuat API Post Controller {#step-4-api-post-controller}

Kita akan membuat controller terpisah untuk API alih-alih menggunakan kembali web controller. Ini adalah praktik yang umum karena API response (JSON) berbeda dari web response (view dan redirect), dan mencampurnya dalam satu controller mengarah pada logika kondisional yang berantakan.

Buat controller:

```
php artisan make:controller Api/PostController
```

Buka `app/Http/Controllers/Api/PostController.php`:

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StorePostRequest;
use App\Http\Requests\UpdatePostRequest;
use App\Http\Resources\PostResource;
use App\Models\Post;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Http\Request;

class PostController extends Controller
{
    use AuthorizesRequests;

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $posts = Post::with('user')->latest()->paginate(10);

        return PostResource::collection($posts);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StorePostRequest $request)
    {
        $post = $request->user()->posts()->create($request->validated());

        return new PostResource($post->load('user'));
    }

    /**
     * Display the specified resource.
     */
    public function show(Post $post)
    {
        return new PostResource($post->load('user'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdatePostRequest $request, Post $post)
    {
        $this->authorize('update', $post);

        $post->update($request->validated());

        return new PostResource($post->load('user'));
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Post $post)
    {
        $this->authorize('delete', $post);

        $post->delete();

        return response()->json([
            'message' => 'Post deleted successfully.',
        ]);
    }
}
```

Mari kita telusuri keputusan desain utamanya:

**Menggunakan kembali Form Request.** Method `store()` dan `update()` menggunakan `StorePostRequest` dan `UpdatePostRequest` yang sama yang kita buat di [tutorial Form Request](https://qadrlabs.com/post/laravel-13-refactor-your-controller-with-form-request-validation). Pembuatan slug dan aturan validasinya identik baik untuk web maupun API. Ini adalah salah satu manfaat besar dari Form Request: tulis sekali, gunakan di mana saja.

**Menggunakan kembali PostPolicy.** Pemanggilan `authorize('update', $post)` dan `authorize('delete', $post)` menggunakan `PostPolicy` yang sama dari [tutorial auth](https://qadrlabs.com/post/laravel-13-add-authentication-and-authorization-with-php-attributes). Kita menggunakan trait `AuthorizesRequests` dan memanggil `$this->authorize()` secara langsung alih-alih attribute `#[Authorize]`. Kedua pendekatan memanggil method policy yang sama. Pendekatan attribute lebih bersih untuk web controller di mana setiap request terautentikasi, sementara pemanggilan eksplisit `$this->authorize()` lebih umum di API controller.

**Mengembalikan PostResource.** Setiap response melewati `PostResource` untuk format JSON yang konsisten. `PostResource::collection($posts)` membungkus collection yang terpaginasi dan secara otomatis menyertakan metadata pagination (key `links` dan `meta`).

**Eager loading relationship.** `Post::with('user')` dan `$post->load('user')` memastikan relationship user dimuat sebelum meneruskan post ke resource. Tanpa eager loading, mengakses `$this->user` di resource akan memicu query terpisah untuk setiap post (masalah N+1).

**Tidak ada view atau redirect.** Berbeda dengan web controller, setiap method mengembalikan JSON. Ini menjaga API controller tetap fokus pada data, bukan presentasi.

Simpan file.


## Step 5: Mendaftarkan Route API {#step-5-register-routes}

Buka `routes/api.php` dan daftarkan route authentication dan post:

```php
<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PostController;
use Illuminate\Support\Facades\Route;

// Public routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::apiResource('posts', PostController::class)->names([
        'index' => 'api.posts.index',
        'store' => 'api.posts.store',
        'show' => 'api.posts.show',
        'update' => 'api.posts.update',
        'destroy' => 'api.posts.destroy',
    ]);
});
```

Semua route di `routes/api.php` secara otomatis diberi prefix `/api`. Jadi URL lengkapnya menjadi `/api/register`, `/api/login`, `/api/posts`, dan seterusnya.

Strukturnya memisahkan route publik dan terproteksi:

- **Route publik** (`register` dan `login`) tidak membutuhkan authentication. Siapa pun dapat membuat akun atau login untuk menerima token.
- **Route terproteksi** dibungkus dalam `middleware('auth:sanctum')`. Middleware `auth:sanctum` memvalidasi token dari header `Authorization: Bearer {token}`. Jika token hilang atau tidak valid, Sanctum mengembalikan response 401 Unauthorized.
- `Route::apiResource('posts', PostController::class)` mendaftarkan lima route: `index`, `store`, `show`, `update`, dan `destroy`. Ini mirip dengan `Route::resource()` tetapi mengecualikan `create` dan `edit` karena keduanya adalah halaman form yang tidak ada di sebuah API.

**Penting:** Method `->names([...])` menetapkan nama route eksplisit dengan prefix `api.` (misalnya, `api.posts.index` alih-alih `posts.index`). Tanpa ini, nama route API akan berkonflik dengan nama route web dari `Route::resource('posts', ...)` di `routes/web.php`. Keduanya akan mendaftarkan `posts.index`, dan versi API akan menimpa versi web, sehingga merusak web test dan referensi named route Anda.

Simpan file.


## Step 6: Menangani Request API yang Tidak Terautentikasi {#step-6-handle-unauthenticated}

Secara default, ketika request yang tidak terautentikasi mengenai route yang diproteksi Sanctum, Laravel mencoba mengarahkan ke halaman login. Hal ini masuk akal untuk request web, tetapi untuk request API kita menginginkan JSON response sebagai gantinya.

Buka `bootstrap/app.php` dan tambahkan berikut ini untuk memastikan request API yang tidak terautentikasi menerima JSON response yang tepat:

```php
<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Auth\AuthenticationException; // add this line of code
use Illuminate\Http\Request; // add this line of code

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        //
    })
    ->withExceptions(function (Exceptions $exceptions) {
		// [ ... Add this lines of code ... ]
        $exceptions->render(function (AuthenticationException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'message' => 'Unauthenticated.',
                ], 401);
            }
        });
    })->create();
```

Callback `render` memeriksa apakah URL request dimulai dengan `api/`. Jika ya, ia mengembalikan JSON response 401 alih-alih mengarahkan ke halaman login. Request web tetap melakukan redirect seperti sebelumnya.

Simpan file.


## Step 7: Menulis API Test {#step-7-write-api-tests}

Sekarang mari kita tulis test komprehensif untuk API. Buat file test baru:

```
php artisan make:test Api/AuthApiTest --pest
```

### Authentication Tests

Buka `tests/Feature/Api/AuthApiTest.php`:

```php
<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

test('a user can register via the api', function () {
    $response = $this->postJson('/api/register', [
        'name' => 'John Doe',
        'email' => 'john@example.com',
        'password' => 'password123',
        'password_confirmation' => 'password123',
    ]);

    $response->assertStatus(201)
        ->assertJsonStructure([
            'message',
            'user' => ['id', 'name', 'email'],
            'token',
        ]);

    $this->assertDatabaseHas('users', [
        'email' => 'john@example.com',
    ]);
});

test('register validates required fields', function () {
    $response = $this->postJson('/api/register', []);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['name', 'email', 'password']);
});

test('register validates unique email', function () {
    User::factory()->create(['email' => 'taken@example.com']);

    $response = $this->postJson('/api/register', [
        'name' => 'Jane Doe',
        'email' => 'taken@example.com',
        'password' => 'password123',
        'password_confirmation' => 'password123',
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['email']);
});

test('register validates password confirmation', function () {
    $response = $this->postJson('/api/register', [
        'name' => 'John Doe',
        'email' => 'john@example.com',
        'password' => 'password123',
        'password_confirmation' => 'different',
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['password']);
});

test('a user can login via the api', function () {
    $user = User::factory()->create([
        'password' => bcrypt('password123'),
    ]);

    $response = $this->postJson('/api/login', [
        'email' => $user->email,
        'password' => 'password123',
    ]);

    $response->assertStatus(200)
        ->assertJsonStructure([
            'message',
            'user' => ['id', 'name', 'email'],
            'token',
        ]);
});

test('login fails with incorrect credentials', function () {
    $user = User::factory()->create([
        'password' => bcrypt('password123'),
    ]);

    $response = $this->postJson('/api/login', [
        'email' => $user->email,
        'password' => 'wrong-password',
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['email']);
});

test('login validates required fields', function () {
    $response = $this->postJson('/api/login', []);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['email', 'password']);
});

test('a user can logout via the api', function () {
    $user = User::factory()->create();
    $token = $user->createToken('test-token');

    $response = $this->withToken($token->plainTextToken)
        ->postJson('/api/logout');

    $response->assertStatus(200)
        ->assertJson([
            'message' => 'Logged out successfully.',
        ]);
});

test('logout requires authentication', function () {
    $response = $this->postJson('/api/logout');

    $response->assertStatus(401);
});
```

Perhatikan penggunaan `postJson()` alih-alih `post()`. Method `postJson()` mengirim request dengan header `Accept: application/json` dan `Content-Type: application/json`, yang merupakan cara client API berkomunikasi. Ini memastikan Laravel mengembalikan error validasi JSON alih-alih melakukan redirect.

Perhatikan juga `actingAs($user, 'sanctum')` di sebagian besar test. Argumen kedua menentukan guard. Untuk route API Sanctum, Anda harus menggunakan `'sanctum'` sebagai nama guard.

**Test logout** berbeda. Ia menggunakan `createToken()` dan `withToken()` alih-alih `actingAs()`. Ini karena `actingAs($user, 'sanctum')` membuat authentication transien (in-memory) yang tidak menyimpan token nyata di database. Ketika controller logout memanggil `currentAccessToken()->delete()`, ia membutuhkan token nyata untuk dihapus. Dengan membuat token menggunakan `createToken('test-token')` dan melakukan authentication dengan `withToken($token->plainTextToken)`, token tersebut ada di database dan dapat dicabut dengan benar.

Simpan file.

### Post API Tests

Buat file test lain:

```
php artisan make:test Api/PostApiTest --pest
```

Buka `tests/Feature/Api/PostApiTest.php`:

```php
<?php

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->user = User::factory()->create();
});

// ============================================================
// Index
// ============================================================

test('authenticated user can list posts', function () {
    Post::factory()->count(3)->create();

    $response = $this->actingAs($this->user, 'sanctum')
        ->getJson('/api/posts');

    $response->assertStatus(200)
        ->assertJsonStructure([
            'data' => [
                '*' => ['id', 'title', 'slug', 'content', 'status', 'author', 'created_at', 'updated_at'],
            ],
            'links',
            'meta',
        ]);
});

test('post list is paginated', function () {
    Post::factory()->count(15)->create();

    $response = $this->actingAs($this->user, 'sanctum')
        ->getJson('/api/posts');

    $response->assertStatus(200)
        ->assertJsonCount(10, 'data');
});

test('unauthenticated user cannot list posts', function () {
    $response = $this->getJson('/api/posts');

    $response->assertStatus(401);
});

// ============================================================
// Store
// ============================================================

test('authenticated user can create a post', function () {
    $response = $this->actingAs($this->user, 'sanctum')
        ->postJson('/api/posts', [
            'title' => 'API Created Post',
            'content' => 'This post was created via the API.',
            'status' => 'publish',
        ]);

    $response->assertStatus(201)
        ->assertJson([
            'data' => [
                'title' => 'API Created Post',
                'slug' => 'api-created-post',
                'content' => 'This post was created via the API.',
                'status' => 'publish',
                'author' => [
                    'id' => $this->user->id,
                    'name' => $this->user->name,
                ],
            ],
        ]);

    $this->assertDatabaseHas('posts', [
        'title' => 'API Created Post',
        'user_id' => $this->user->id,
    ]);
});

test('store validates required fields via api', function () {
    $response = $this->actingAs($this->user, 'sanctum')
        ->postJson('/api/posts', []);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['title', 'content', 'status']);
});

test('store validates slug uniqueness via api', function () {
    Post::factory()->create(['slug' => 'duplicate-title']);

    $response = $this->actingAs($this->user, 'sanctum')
        ->postJson('/api/posts', [
            'title' => 'Duplicate Title',
            'content' => 'Some content.',
            'status' => 'draft',
        ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['slug']);
});

test('unauthenticated user cannot create a post', function () {
    $response = $this->postJson('/api/posts', [
        'title' => 'Unauthorized Post',
        'content' => 'This should fail.',
        'status' => 'draft',
    ]);

    $response->assertStatus(401);
});

// ============================================================
// Show
// ============================================================

test('authenticated user can view a single post', function () {
    $post = Post::factory()->create();

    $response = $this->actingAs($this->user, 'sanctum')
        ->getJson("/api/posts/{$post->id}");

    $response->assertStatus(200)
        ->assertJson([
            'data' => [
                'id' => $post->id,
                'title' => $post->title,
                'slug' => $post->slug,
            ],
        ]);
});

test('show returns 404 for non-existent post', function () {
    $response = $this->actingAs($this->user, 'sanctum')
        ->getJson('/api/posts/9999');

    $response->assertStatus(404);
});

test('unauthenticated user cannot view a post', function () {
    $post = Post::factory()->create();

    $response = $this->getJson("/api/posts/{$post->id}");

    $response->assertStatus(401);
});

// ============================================================
// Update
// ============================================================

test('post owner can update their post via api', function () {
    $post = Post::factory()->create([
        'title' => 'Original Title',
        'slug' => 'original-title',
        'user_id' => $this->user->id,
    ]);

    $response = $this->actingAs($this->user, 'sanctum')
        ->putJson("/api/posts/{$post->id}", [
            'title' => 'Updated Title',
            'content' => 'Updated content.',
            'status' => 'publish',
        ]);

    $response->assertStatus(200)
        ->assertJson([
            'data' => [
                'title' => 'Updated Title',
                'slug' => 'updated-title',
            ],
        ]);

    $this->assertDatabaseHas('posts', [
        'id' => $post->id,
        'title' => 'Updated Title',
    ]);
});

test('user cannot update a post they do not own via api', function () {
    $otherUser = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $otherUser->id]);

    $response = $this->actingAs($this->user, 'sanctum')
        ->putJson("/api/posts/{$post->id}", [
            'title' => 'Hijacked Title',
            'content' => 'Hijacked content.',
            'status' => 'publish',
        ]);

    $response->assertStatus(403);
});

test('update validates required fields via api', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user, 'sanctum')
        ->putJson("/api/posts/{$post->id}", []);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['title', 'content', 'status']);
});

test('unauthenticated user cannot update a post', function () {
    $post = Post::factory()->create();

    $response = $this->putJson("/api/posts/{$post->id}", [
        'title' => 'Unauthorized Update',
        'content' => 'This should fail.',
        'status' => 'draft',
    ]);

    $response->assertStatus(401);
});

// ============================================================
// Destroy
// ============================================================

test('post owner can delete their post via api', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user, 'sanctum')
        ->deleteJson("/api/posts/{$post->id}");

    $response->assertStatus(200)
        ->assertJson([
            'message' => 'Post deleted successfully.',
        ]);

    $this->assertDatabaseMissing('posts', ['id' => $post->id]);
});

test('user cannot delete a post they do not own via api', function () {
    $otherUser = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $otherUser->id]);

    $response = $this->actingAs($this->user, 'sanctum')
        ->deleteJson("/api/posts/{$post->id}");

    $response->assertStatus(403);

    $this->assertDatabaseHas('posts', ['id' => $post->id]);
});

test('unauthenticated user cannot delete a post', function () {
    $post = Post::factory()->create();

    $response = $this->deleteJson("/api/posts/{$post->id}");

    $response->assertStatus(401);
});
```

Beberapa pola yang perlu diperhatikan di seluruh test ini:

- **Setiap test menggunakan `actingAs($this->user, 'sanctum')`.** Guard `'sanctum'` memberi tahu Laravel untuk melakukan authentication pada request seolah-olah token Sanctum yang valid telah disediakan. Ini lebih bersih daripada menghasilkan token nyata di setiap test.
- **Semua request menggunakan suffix `Json`** (`getJson`, `postJson`, `putJson`, `deleteJson`). Ini memastikan header yang tepat dan JSON error response.
- **Test authentication memeriksa 401.** Setiap endpoint memiliki test terkait yang memverifikasi bahwa request yang tidak terautentikasi ditolak.
- **Test authorization memeriksa 403.** Endpoint update dan delete memverifikasi bahwa user tidak dapat memodifikasi post yang bukan miliknya.
- **Test store memverifikasi `user_id`.** Setelah membuat post, test memeriksa bahwa `user_id` di database cocok dengan user yang terautentikasi, sehingga mengonfirmasi bahwa penetapan kepemilikan bekerja melalui API.
- **Pagination diuji secara terpisah.** Test membuat 15 post dan memverifikasi bahwa hanya 10 yang dikembalikan per halaman.

Simpan file.


## Step 8: Menjalankan Test {#step-8-run-tests}

Jalankan test suite lengkap:

```
php artisan test
```

Output:
```
$ php artisan test

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\Api\AuthApiTest
  ✓ a user can register via the api                                      0.15s  
  ✓ register validates required fields                                   0.01s  
  ✓ register validates unique email                                      0.01s  
  ✓ register validates password confirmation                             0.01s  
  ✓ a user can login via the api                                         0.01s  
  ✓ login fails with incorrect credentials                               0.01s  
  ✓ login validates required fields                                      0.01s  
  ✓ a user can logout via the api                                        0.01s  
  ✓ logout requires authentication                                       0.01s  

   PASS  Tests\Feature\Api\PostApiTest
  ✓ authenticated user can list posts                                    0.02s  
  ✓ post list is paginated                                               0.02s  
  ✓ unauthenticated user cannot list posts                               0.01s  
  ✓ authenticated user can create a post                                 0.01s  
  ✓ store validates required fields via api                              0.01s  
  ✓ store validates slug uniqueness via api                              0.01s  
  ✓ unauthenticated user cannot create a post                            0.01s  
  ✓ authenticated user can view a single post                            0.01s  
  ✓ show returns 404 for non-existent post                               0.01s  
  ✓ unauthenticated user cannot view a post                              0.01s  
  ✓ post owner can update their post via api                             0.01s  
  ✓ user cannot update a post they do not own via api                    0.01s  
  ✓ update validates required fields via api                             0.01s  
  ✓ unauthenticated user cannot update a post                            0.01s  
  ✓ post owner can delete their post via api                             0.01s  
  ✓ user cannot delete a post they do not own via api                    0.01s  
  ✓ unauthenticated user cannot delete a post                            0.01s  

   PASS  Tests\Feature\Auth\LoginTest
  ✓ login page is displayed                                              0.02s  
  ✓ user can login with correct credentials                              0.01s  
  ✓ user cannot login with incorrect password                            0.21s  
  ✓ user cannot login with non-existent email                            0.23s  
  ✓ login validates required fields                                      0.03s  
  ✓ user can logout                                                      0.02s  

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.01s  

   PASS  Tests\Feature\PostControllerTest
  ✓ index page displays a list of posts                                  0.01s  
  ✓ index page shows empty state when no posts exist                     0.01s  
  ✓ create page displays the form                                        0.01s  
  ✓ a new post can be stored                                             0.01s  
  ✓ slug is automatically generated from the title                       0.01s  
  ✓ store validates required fields                                      0.01s  
  ✓ store validates title max length                                     0.01s  
  ✓ store validates status must be draft or publish                      0.01s  
  ✓ store validates slug uniqueness                                      0.01s  
  ✓ show page displays a single post                                     0.01s  
  ✓ show returns 404 for non-existent post                               0.01s  
  ✓ edit page displays the form with existing data                       0.01s  
  ✓ a post can be updated                                                0.01s  
  ✓ update validates required fields                                     0.01s  
  ✓ update allows same slug for the same post                            0.01s  
  ✓ a post can be deleted                                                0.01s  
  ✓ deleting a non-existent post returns 404                             0.01s  
  ✓ unauthenticated user is redirected to login from index               0.01s  
  ✓ unauthenticated user is redirected to login from create              0.01s  
  ✓ unauthenticated user is redirected to login from store               0.01s  
  ✓ unauthenticated user is redirected to login from show                0.01s  
  ✓ unauthenticated user is redirected to login from edit                0.01s  
  ✓ unauthenticated user is redirected to login from update              0.01s  
  ✓ unauthenticated user is redirected to login from destroy             0.01s  
  ✓ user cannot edit a post they do not own                              0.01s  
  ✓ user cannot update a post they do not own                            0.01s  
  ✓ user cannot delete a post they do not own                            0.03s  
  ✓ post owner can edit their own post                                   0.01s  
  ✓ post owner can delete their own post                                 0.01s  

  Tests:    63 passed (194 assertions)
  Duration: 1.25s


```

Anda seharusnya melihat semua test lulus, termasuk web test orisinal dari tutorial sebelumnya dan API test baru. API test suite menambahkan:

- 9 test authentication (register, login, logout dengan data valid/tidak valid/hilang).
- 18 test API post (operasi CRUD dengan pemeriksaan authentication, authorization, dan validasi).

Dikombinasikan dengan web test yang sudah ada, jumlah total test adalah 63 test.


## Step 9: Mencobanya {#step-9-try-it-out}

Jalankan development server:

```
php artisan serve
```

Anda dapat menguji API menggunakan `curl` atau client API apa pun seperti Postman atau Insomnia.

### Register a User

```bash
curl -X POST http://127.0.0.1:8000/api/register \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'
```

Response menyertakan field `token`. Salin token ini untuk request berikutnya.

### Login

```bash
curl -X POST http://127.0.0.1:8000/api/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

### Create a Post

Ganti `YOUR_TOKEN` dengan token dari response register atau login:

```bash
curl -X POST http://127.0.0.1:8000/api/posts \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "title": "My First API Post",
    "content": "This post was created via the REST API.",
    "status": "publish"
  }'
```

### List All Posts

```bash
curl http://127.0.0.1:8000/api/posts \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### View a Single Post

```bash
curl http://127.0.0.1:8000/api/posts/1 \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Update a Post

```bash
curl -X PUT http://127.0.0.1:8000/api/posts/1 \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "title": "Updated API Post",
    "content": "This post was updated via the REST API.",
    "status": "publish"
  }'
```

### Delete a Post

```bash
curl -X DELETE http://127.0.0.1:8000/api/posts/1 \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Logout

```bash
curl -X POST http://127.0.0.1:8000/api/logout \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Setelah logout, token dicabut dan setiap request berikutnya yang menggunakan token yang sama akan menerima response 401.


## Kesimpulan {#conclusion}

Pada tutorial ini, kita menambahkan lapisan REST API lengkap ke aplikasi blog Laravel 13 kita. Kita menginstal Sanctum untuk authentication berbasis token, membuat API controller dan resource class khusus, menggunakan kembali Form Request dan Policy yang sudah ada, dan menulis Pest test suite yang komprehensif.

Berikut adalah poin-poin penting yang bisa diambil:

- **Sanctum membuat auth berbasis token menjadi sederhana.** `createToken()` menerbitkan token, `currentAccessToken()->delete()` mencabutnya. Tidak diperlukan kompleksitas OAuth untuk sebagian besar kasus penggunaan API.
- **Pisahkan API controller dari web controller.** Endpoint API mengembalikan JSON, endpoint web mengembalikan view dan redirect. Menyimpannya dalam controller terpisah menghindari logika kondisional yang berantakan dan membuat setiap controller lebih mudah dipelihara.
- **Form Request dapat digunakan kembali di berbagai lapisan.** `StorePostRequest` dan `UpdatePostRequest` yang kita bangun di tutorial sebelumnya bekerja secara identik di API controller. Tulis validasi sekali, gunakan di mana saja.
- **Policy bekerja sama untuk web dan API.** `PostPolicy` menegakkan pemeriksaan kepemilikan terlepas dari apakah request berasal dari browser atau client API. Satu-satunya perbedaan adalah cara Anda memanggilnya: attribute `#[Authorize]` pada web controller versus `$this->authorize()` di API controller.
- **API Resources memberi Anda kontrol atas struktur JSON.** Alih-alih mengekspos data model mentah, `PostResource` mendefinisikan secara tepat field mana yang dikembalikan API dan bagaimana relationship disarangkan.
- **Selalu tentukan guard `'sanctum'` di test.** Menggunakan `actingAs($user, 'sanctum')` memastikan test melakukan authentication melalui Sanctum guard. Tanpa nama guard, test akan menggunakan web guard default, yang dapat mengarah pada perilaku yang tidak terduga. Satu pengecualian adalah test logout: gunakan `createToken()` dan `withToken()` sebagai gantinya, karena `actingAs()` membuat token in-memory yang tidak dapat dihapus oleh `currentAccessToken()->delete()`.
- **Gunakan `postJson()` alih-alih `post()` untuk API test.** Method dengan suffix `Json` menetapkan header yang benar dan memastikan Laravel mengembalikan error validasi JSON alih-alih melakukan redirect.
- **Beri nama eksplisit pada route API untuk menghindari konflik.** Ketika Anda memiliki baik `Route::resource('posts')` di route web maupun `Route::apiResource('posts')` di route API, keduanya mendaftarkan nama route yang sama (misalnya, `posts.index`). Route API akan menimpa route web, sehingga merusak web test Anda. Gunakan `->names([...])` untuk memberi prefix `api.` pada nama route API (misalnya, `api.posts.index`).

Dari sini, Anda dapat menambahkan kemampuan token (scope) untuk membatasi apa yang dapat dilakukan setiap token, mengimplementasikan rate limiting pada endpoint API, menambahkan versioning API dengan prefix route, atau membangun frontend yang mengonsumsi API ini menggunakan Vue.js, React, atau framework mobile.
