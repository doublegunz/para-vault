---
title: "Laravel 13: Menambahkan Authentication dan Authorization dengan PHP Attributes"
slug: "menambahkan-authentication-dan-authorization-laravel-13-dengan-php-attributes"
original_title: "Laravel 13: Add Authentication and Authorization with PHP Attributes"
original_slug: "laravel-13-add-authentication-and-authorization-with-php-attributes"
category: "Laravel"
date: "2026-03-25"
status: "draft"
---

Aplikasi blog kita sudah berfungsi, memiliki 19 test yang lulus, dan controller yang sudah di-refactor dengan rapi menggunakan Form Request validation. Namun saat ini, siapa pun dapat membuat, mengedit, atau menghapus post tanpa login. Hal itu wajar untuk sebuah tutorial, tetapi tidak untuk aplikasi nyata.

Pada tutorial ini, kita akan menambahkan authentication dan authorization ke blog. Kita akan membangun sistem login tanpa menggunakan starter kit apa pun, membuat policy untuk mengontrol siapa yang dapat mengedit dan menghapus post, serta menggunakan PHP attributes baru di Laravel 13 (`#[Middleware]` dan `#[Authorize]`) untuk menerapkan aturan ini langsung pada controller. Dan karena kita memiliki test suite, kita akan memperbarui test yang sudah ada serta menulis test baru untuk memverifikasi bahwa lapisan keamanan bekerja dengan benar.

Ini adalah Bagian 4 dari seri tutorial blog Laravel 13 kita, melanjutkan [tutorial CRUD](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step), [tutorial testing](https://qadrlabs.com/post/laravel-13-testing-with-pest-write-tests-for-your-crud-application), dan [tutorial refactoring Form Request](https://qadrlabs.com/post/laravel-13-refactor-your-controller-with-form-request-validation).


## Ikhtisar {#overview}

Kita akan menambahkan dua lapisan proteksi ke blog:

1. **Authentication**: Hanya user yang sudah login yang dapat mengakses halaman pengelolaan post.
2. **Authorization**: Hanya user yang membuat sebuah post yang dapat mengedit atau menghapusnya.

### What You'll Build

- Halaman login serta fungsi login/logout (tanpa starter kit).
- Sebuah kolom `user_id` pada post untuk melacak kepemilikan.
- Sebuah `PostPolicy` untuk mendefinisikan siapa yang dapat melakukan tindakan tertentu.
- PHP attributes pada controller untuk middleware dan authorization.
- Pest test yang diperbarui dan baru yang mencakup skenario authentication dan authorization.

### What You'll Learn

- Cara membangun authentication secara manual tanpa Laravel Breeze atau Jetstream.
- Cara menggunakan `#[Middleware('auth')]` untuk mewajibkan authentication pada sebuah controller.
- Cara menggunakan `#[Authorize]` untuk menegakkan pemeriksaan policy pada method tertentu.
- Cara mengakses model yang terikat route di dalam attribute `#[Authorize]`.
- Cara memperbarui test yang sudah ada dengan `actingAs()` untuk request yang sudah terautentikasi.
- Cara menulis test untuk akses tanpa authentication dan tindakan tanpa authorization.

### What You'll Need

- Proyek blog yang sudah selesai beserta Form Request validation dari [tutorial sebelumnya](https://qadrlabs.com/post/laravel-13-refactor-your-controller-with-form-request-validation).
- PHP 8.3 atau lebih tinggi.
- Pemahaman dasar tentang Laravel middleware dan policy.


## Step 1: Jalankan Test Sebelum Perubahan {#step-1-run-tests-before}

Seperti biasa, mulailah dengan menjalankan test suite yang sudah ada:

```
php artisan test
```

Semua 19 test seharusnya lulus. Ini adalah baseline kita. Setiap perubahan yang kita buat mulai dari sini akan diverifikasi terhadap test ini.


## Step 2: Membangun Sistem Login {#step-2-build-login-system}

Kita akan membangun sistem login dan logout sederhana tanpa menggunakan starter kit apa pun seperti Breeze atau Jetstream. Hal ini menjaga tutorial tetap fokus dan memberi Anda kontrol penuh atas implementasinya.

### Create the LoginController

Buat controller baru:

```
php artisan make:controller Auth/LoginController
```

Buka `app/Http/Controllers/Auth/LoginController.php` dan tambahkan logika login dan logout:

```php
<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LoginController extends Controller
{
    /**
     * Show the login form.
     */
    public function showLoginForm()
    {
        return view('auth.login');
    }

    /**
     * Handle a login request.
     */
    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (Auth::attempt($credentials)) {
            $request->session()->regenerate();

            return redirect()->intended(route('posts.index'));
        }

        return back()->withErrors([
            'email' => 'The provided credentials do not match our records.',
        ])->onlyInput('email');
    }

    /**
     * Log the user out.
     */
    public function logout(Request $request)
    {
        Auth::logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('login');
    }
}
```

Berikut adalah penjelasan apa yang dilakukan setiap method:

- `showLoginForm()` mengembalikan view login. Tidak ada yang istimewa di sini.
- `login()` pertama-tama memvalidasi bahwa email dan password keduanya tersedia. Kemudian `Auth::attempt($credentials)` memeriksa credentials terhadap tabel `users`. Jika credentials cocok, `$request->session()->regenerate()` membuat session ID baru untuk mencegah serangan session fixation, dan `redirect()->intended()` mengirim user ke halaman yang awalnya ingin mereka akses (atau ke halaman posts index sebagai fallback). Jika credentials salah, ia mengarahkan kembali dengan pesan error sambil menjaga input email tetap terisi.
- `logout()` membersihkan state authentication, menginvalidasi session, dan meregenerasi token CSRF untuk mencegah serangan berbasis session apa pun setelah logout.

Simpan file.

### Create the Login View

Buat file baru di `resources/views/auth/login.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-md mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md mt-20">
        <h1 class="text-2xl font-bold text-gray-900 mb-6 text-center">Login</h1>

        @if($errors->any())
            <div class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded mb-6">
                <ul class="list-disc list-inside text-sm">
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('login') }}" method="POST" class="space-y-6">
            @csrf
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                <input type="email" name="email" value="{{ old('email') }}" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition">
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
                <input type="password" name="password" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition">
            </div>

            <div>
                <button type="submit" class="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-md transition duration-200 shadow-sm">
                    Login
                </button>
            </div>
        </form>
    </div>
</body>
</html>
```

Simpan file.

### Register the Auth Routes

Buka `routes/web.php` dan tambahkan route authentication:

```php
<?php

use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\PostController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Authentication routes
Route::get('/login', [LoginController::class, 'showLoginForm'])->name('login');
Route::post('/login', [LoginController::class, 'login']);
Route::post('/logout', [LoginController::class, 'logout'])->name('logout');

Route::resource('posts', PostController::class);
```

Route `login` diberi nama `login` karena middleware `auth` milik Laravel secara default mengarahkan user yang belum terautentikasi ke route bernama `login`. Jika Anda menamainya dengan nama lain, Anda perlu mengonfigurasi path redirect secara terpisah.

Simpan file.

### Add a Logout Button

Perbarui `resources/views/posts/index.blade.php` untuk menyertakan tombol logout pada header. Temukan bagian header yang sudah ada:

```html
<div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold text-gray-900">Manage Posts</h1>
    <a href="{{ route('posts.create') }}" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-md transition duration-200 shadow-sm">
        Create New Post
    </a>
</div>
```

Ganti dengan:

```html
<div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold text-gray-900">Manage Posts</h1>
    <div class="flex items-center space-x-4">
        <a href="{{ route('posts.create') }}" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-md transition duration-200 shadow-sm">
            Create New Post
        </a>
        @auth
        <form action="{{ route('logout') }}" method="POST" class="inline">
            @csrf
            <button type="submit" class="text-gray-600 hover:text-gray-900 text-sm underline transition">
                Logout
            </button>
        </form>
        @endauth
    </div>
</div>
```

Directive `@auth` memastikan tombol logout hanya muncul ketika user sudah login.

Simpan file.


## Step 3: Menambahkan Kepemilikan Post {#step-3-add-post-ownership}

Untuk mengatur authorization siapa yang dapat mengedit atau menghapus sebuah post, kita perlu mengetahui siapa yang membuatnya. Ini berarti menambahkan kolom `user_id` ke tabel `posts`.

### Create the Migration

```
php artisan make:migration add_user_id_to_posts_table --table=posts
```

Buka file migration yang dihasilkan dan tambahkan kolom `user_id`:

```php
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
        Schema::table('posts', function (Blueprint $table) {
            $table->foreignId('user_id')->after('id')->constrained()->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->dropColumn('user_id');
        });
    }
};
```

`foreignId('user_id')->constrained()->onDelete('cascade')` membuat foreign key yang mereferensikan tabel `users`. `after('id')` menempatkan kolom tersebut tepat setelah kolom `id` untuk struktur tabel yang rapi. Ketika sebuah user dihapus, semua post miliknya otomatis ikut terhapus.

Simpan file dan jalankan migration:

```
php artisan migrate
```

### Update the Post Model

Buka `app/Models/Post.php` dan tambahkan `user_id` ke attribute `#[Fillable]` lalu definisikan relationship-nya:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['title', 'slug', 'content', 'status', 'user_id'])] // add user_id to fillable
class Post extends Model
{
    use HasFactory;

	// define relationship
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

Method `user()` mendefinisikan relationship `BelongsTo`, sehingga Anda dapat mengakses penulis post melalui `$post->user`.

Simpan file.

### Update the Post Factory

Buka `database/factories/PostFactory.php` dan tambahkan field `user_id`:

```php
<?php

namespace Database\Factories;

use App\Models\User; // add this line of code
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Post>
 */
class PostFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $title = $this->faker->sentence();

        return [
            'title' => $title,
            'slug' => Str::slug($title),
            'content' => $this->faker->paragraphs(3, true),
            'status' => $this->faker->randomElement(['draft', 'publish']),
            'user_id' => User::factory(), // add this line of code
        ];
    }
}
```

`User::factory()` secara otomatis membuat sebuah user setiap kali sebuah post dihasilkan, sehingga membangun relationship kepemilikan dalam data test.

Simpan file.

### Update the Store Logic

Saat membuat sebuah post, kita perlu menetapkan user yang sedang terautentikasi sebagai pemiliknya. Buka `app/Http/Controllers/PostController.php` dan perbarui method `store()`:

```php
public function store(StorePostRequest $request)
{
    $request->user()->posts()->create($request->validated());

    return redirect()->route('posts.index')->with('success', 'Post created successfully.');
}
```

Alih-alih `Post::create($request->validated())`, sekarang kita menggunakan `$request->user()->posts()->create(...)`. Ini secara otomatis menetapkan `user_id` ke ID user yang terautentikasi tanpa perlu menyertakannya dalam form atau dalam data yang sudah divalidasi.

Agar ini berfungsi, kita perlu menambahkan relationship `posts()` ke model `User`. Buka `app/Models/User.php` dan tambahkan:

```php
use Illuminate\Database\Eloquent\Relations\HasMany;

// Inside the User class:
public function posts(): HasMany
{
    return $this->hasMany(Post::class);
}
```

Isi dari class User Model adalah sebagai berikut:
```php
<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function posts(): HasMany
    {
        return $this->hasMany(Post::class);
    }
}

```

Simpan kedua file.

### Update the StorePostRequest

Karena `user_id` tidak lagi diteruskan melalui form, kita sebaiknya menghapusnya dari field fillable yang disentuh oleh form. `user_id` ditetapkan melalui relationship, sehingga Form Request tidak perlu menanganinya. Tidak ada perubahan yang diperlukan pada `StorePostRequest` karena ia tidak mereferensikan `user_id`.


## Step 4: Membuat Post Policy {#step-4-create-post-policy}

Policy mendefinisikan user mana yang memiliki authorization untuk melakukan tindakan tertentu pada sebuah model. Buat sebuah policy untuk model `Post`:

```
php artisan make:policy PostPolicy --model=Post
```

Buka `app/Policies/PostPolicy.php` dan definisikan aturan authorization-nya:

```php
<?php

namespace App\Policies;

use App\Models\Post;
use App\Models\User;

class PostPolicy
{
    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        return true;
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User $user, Post $post): bool
    {
        return true;
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        return true;
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }
}
```

Logikanya cukup sederhana:

- `viewAny()`, `view()`, dan `create()` mengembalikan `true` karena setiap user yang terautentikasi dapat menampilkan daftar post, melihat post individual, dan membuat post baru.
- `update()` dan `delete()` membandingkan ID user yang terautentikasi dengan `user_id` milik post. Hanya user yang membuat post yang dapat mengedit atau menghapusnya. Perbandingan strict `===` memastikan baik nilai maupun tipenya cocok.

Simpan file.


## Step 5: Menerapkan PHP Attributes pada Controller {#step-5-apply-php-attributes}

Di sinilah PHP attributes baru di Laravel 13 berperan. Alih-alih mendefinisikan middleware di constructor atau di file route, Anda dapat mendeklarasikannya langsung pada class controller dan method menggunakan `#[Middleware]` dan `#[Authorize]`.

Buka `app/Http/Controllers/PostController.php` dan perbarui:

```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\StorePostRequest;
use App\Http\Requests\UpdatePostRequest;
use App\Models\Post;
use Illuminate\Routing\Attributes\Controllers\Middleware;
use Illuminate\Routing\Attributes\Controllers\Authorize;

#[Middleware('auth')]
class PostController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $posts = Post::latest()->paginate(10);
        return view('posts.index', compact('posts'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        return view('posts.create');
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StorePostRequest $request)
    {
        $request->user()->posts()->create($request->validated());

        return redirect()->route('posts.index')->with('success', 'Post created successfully.');
    }

    /**
     * Display the specified resource.
     */
    public function show(Post $post)
    {
        return view('posts.show', compact('post'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    #[Authorize('update', 'post')]
    public function edit(Post $post)
    {
        return view('posts.edit', compact('post'));
    }

    /**
     * Update the specified resource in storage.
     */
    #[Authorize('update', 'post')]
    public function update(UpdatePostRequest $request, Post $post)
    {
        $post->update($request->validated());

        return redirect()->route('posts.index')->with('success', 'Post updated successfully.');
    }

    /**
     * Remove the specified resource from storage.
     */
    #[Authorize('delete', 'post')]
    public function destroy(Post $post)
    {
        $post->delete();

        return redirect()->route('posts.index')->with('success', 'Post deleted successfully.');
    }
}
```

Mari kita uraikan kedua attribute tersebut:

### `#[Middleware('auth')]` on the Class

Menempatkan `#[Middleware('auth')]` pada deklarasi class menerapkan middleware `auth` ke setiap method di dalam controller. Ini berarti semua route yang ditangani oleh `PostController` kini mewajibkan user untuk login. Jika user yang belum terautentikasi mencoba mengakses route post mana pun, mereka akan diarahkan ke halaman login.

Pada versi Laravel sebelumnya, Anda akan mencapai hal ini dengan pemanggilan di constructor:

```php
// Old approach
public function __construct()
{
    $this->middleware('auth');
}
```

Pendekatan attribute lebih deklaratif. Anda dapat melihat kebutuhan middleware secara sekilas tanpa membuka constructor atau file route.

### `#[Authorize('update', 'post')]` on Methods

Attribute `#[Authorize]` ditempatkan pada method individual yang membutuhkan pemeriksaan authorization. Ia menerima dua argumen:

- Argumen pertama (`'update'` atau `'delete'`) adalah method policy yang akan dipanggil.
- Argumen kedua (`'post'`) adalah nama parameter route yang berisi instance model.

Ketika seorang user mengakses `edit()`, `update()`, atau `destroy()`, Laravel secara otomatis memanggil method policy yang sesuai (misalnya, `PostPolicy::update()`) dengan user yang terautentikasi dan instance `Post` yang diselesaikan dari route. Jika policy mengembalikan `false`, Laravel melempar sebuah `AuthorizationException` dan mengembalikan response 403 Forbidden.

String `'post'` harus cocok dengan nama parameter route. Karena kita menggunakan `Route::resource('posts', PostController::class)`, Laravel menamai parameternya `post` (bentuk tunggal dari nama resource). Ini adalah parameter yang sama yang digunakan oleh route model binding untuk menyuntikkan instance `Post $post`.

Perhatikan bahwa `index()`, `create()`, `store()`, dan `show()` tidak memiliki attribute `#[Authorize]`. Hal ini sesuai dengan policy kita: setiap user yang terautentikasi dapat menampilkan daftar, melihat, dan membuat post. Hanya edit, update, dan delete yang membutuhkan verifikasi kepemilikan.

Simpan file.


## Step 6: Menyemai Data Sampel untuk Pengujian Manual {#step-6-seed-sample-data}

Sebelum kita memperbarui automated test, ada baiknya mencoba aplikasi secara manual di browser untuk melihat authentication dan authorization bekerja dari ujung ke ujung. Untuk melakukannya, kita membutuhkan setidaknya satu akun user untuk login. Alih-alih membuat user secara manual melalui tool database, kita akan menggunakan seeder agar pengaturannya dapat diulang.

Untuk mendemonstrasikan authorization dengan baik, kita akan menyemai dua user. User pertama akan memiliki beberapa post. User kedua tidak memiliki satu pun. Ini memungkinkan Anda login sebagai masing-masing user dan memverifikasi bahwa tombol edit dan delete pada post yang bukan milik Anda mengembalikan response 403.

### Create the UserSeeder

```
php artisan make:seeder UserSeeder
```

Buka `database/seeders/UserSeeder.php` dan ganti isinya dengan:

```php
<?php

namespace Database\Seeders;

use App\Models\Post;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // First user: owns all seeded posts
        $alice = User::create([
            'name'     => 'Alice',
            'email'    => 'alice@example.com',
            'password' => Hash::make('password'),
        ]);

        // Create three posts owned by Alice
        $titles = [
            'Getting Started with Laravel 13',
            'Understanding PHP Attributes',
            'Writing Tests with Pest',
        ];

        foreach ($titles as $title) {
            Post::create([
                'title'   => $title,
                'slug'    => Str::slug($title),
                'content' => 'This is a sample post for manual testing purposes.',
                'status'  => 'publish',
                'user_id' => $alice->id, // Alice owns these posts
            ]);
        }

        // Second user: owns no posts, used to test unauthorized access
        User::create([
            'name'     => 'Bob',
            'email'    => 'bob@example.com',
            'password' => Hash::make('password'),
        ]);
    }
}
```

Kedua user berbagi password yang sama (`password`) untuk menjaga pengujian manual tetap sederhana.

### Register the Seeder

Buka `database/seeders/DatabaseSeeder.php` dan panggil `UserSeeder` dari method `run()`:

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            UserSeeder::class,
        ]);
    }
}
```

### Run the Seeder

```
php artisan db:seed
```

### Try It in the Browser

Jalankan development server jika belum berjalan:

```
php artisan serve
```

Buka `http://127.0.0.1:8000/posts`. Karena middleware `auth` kini diterapkan ke seluruh controller, Anda akan langsung diarahkan ke halaman login.

Login dengan credentials Alice (`alice@example.com` / `password`). Anda seharusnya diarahkan ke halaman daftar post, di mana tiga post milik Alice terlihat. Klik **Edit** pada salah satunya. Form seharusnya termuat dengan normal karena Alice memiliki post tersebut.

Sekarang logout dan login kembali sebagai Bob (`bob@example.com` / `password`). Coba klik **Edit** pada salah satu post milik Alice. Anda seharusnya menerima response **403 Forbidden**, yang mengonfirmasi bahwa policy dan attribute `#[Authorize]` bekerja dengan benar.


## Step 7: Memperbarui Test yang Sudah Ada {#step-7-update-existing-tests}

Sekarang setelah setiap route mewajibkan authentication, test yang sudah ada akan gagal karena mereka mengirim request tanpa login. Kita perlu memperbaruinya untuk menggunakan `actingAs()`, yang mensimulasikan user yang terautentikasi.

Buka `tests/Feature/PostControllerTest.php` dan perbarui file tersebut. Pertama, tambahkan import `User` di bagian atas dan buat sebuah helper yang berjalan sebelum setiap test:

```php
<?php

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->user = User::factory()->create();
});
```

`beforeEach()` berjalan sebelum setiap test di dalam file. Ia membuat user baru yang dapat kita gunakan untuk authentication. Sintaks `$this->user` menyimpannya pada instance test sehingga dapat diakses di setiap test.

Sekarang perbarui setiap test yang sudah ada untuk menggunakan `actingAs($this->user)`. Berikut adalah file lengkap yang sudah diperbarui dengan test yang sudah ada dimodifikasi dan test baru ditambahkan:

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
// Index Tests
// ============================================================

test('index page displays a list of posts', function () {
    $posts = Post::factory()->count(3)->create();

    $response = $this->actingAs($this->user)->get(route('posts.index'));

    $response->assertStatus(200);
    $response->assertViewIs('posts.index');
    $response->assertViewHas('posts');

    foreach ($posts as $post) {
        $response->assertSee($post->title);
    }
});

test('index page shows empty state when no posts exist', function () {
    $response = $this->actingAs($this->user)->get(route('posts.index'));

    $response->assertStatus(200);
    $response->assertSee('No posts found.');
});

// ============================================================
// Create Tests
// ============================================================

test('create page displays the form', function () {
    $response = $this->actingAs($this->user)->get(route('posts.create'));

    $response->assertStatus(200);
    $response->assertViewIs('posts.create');
    $response->assertSee('Create Post');
});

test('a new post can be stored', function () {
    $response = $this->actingAs($this->user)->post(route('posts.store'), [
        'title' => 'My First Blog Post',
        'content' => 'This is the content of my first blog post.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post created successfully.');

    $this->assertDatabaseHas('posts', [
        'title' => 'My First Blog Post',
        'slug' => 'my-first-blog-post',
        'content' => 'This is the content of my first blog post.',
        'status' => 'publish',
        'user_id' => $this->user->id,
    ]);
});

test('slug is automatically generated from the title', function () {
    $this->actingAs($this->user)->post(route('posts.store'), [
        'title' => 'Laravel 13 Is Amazing',
        'content' => 'Some content here.',
        'status' => 'draft',
    ]);

    $this->assertDatabaseHas('posts', [
        'title' => 'Laravel 13 Is Amazing',
        'slug' => 'laravel-13-is-amazing',
    ]);
});

test('store validates required fields', function () {
    $response = $this->actingAs($this->user)->post(route('posts.store'), []);

    $response->assertSessionHasErrors(['title', 'content', 'status']);
});

test('store validates title max length', function () {
    $response = $this->actingAs($this->user)->post(route('posts.store'), [
        'title' => str_repeat('a', 256),
        'content' => 'Some content.',
        'status' => 'publish',
    ]);

    $response->assertSessionHasErrors(['title']);
});

test('store validates status must be draft or publish', function () {
    $response = $this->actingAs($this->user)->post(route('posts.store'), [
        'title' => 'Test Post',
        'content' => 'Some content.',
        'status' => 'archived',
    ]);

    $response->assertSessionHasErrors(['status']);
});

test('store validates slug uniqueness', function () {
    Post::factory()->create(['title' => 'Duplicate Title', 'slug' => 'duplicate-title']);

    $response = $this->actingAs($this->user)->post(route('posts.store'), [
        'title' => 'Duplicate Title',
        'content' => 'Different content.',
        'status' => 'draft',
    ]);

    $response->assertSessionHasErrors(['slug']);
});

// ============================================================
// Show Tests
// ============================================================

test('show page displays a single post', function () {
    $post = Post::factory()->create();

    $response = $this->actingAs($this->user)->get(route('posts.show', $post));

    $response->assertStatus(200);
    $response->assertViewIs('posts.show');
    $response->assertSee($post->title);
    $response->assertSee($post->content);
});

test('show returns 404 for non-existent post', function () {
    $response = $this->actingAs($this->user)->get(route('posts.show', 9999));

    $response->assertStatus(404);
});

// ============================================================
// Edit and Update Tests
// ============================================================

test('edit page displays the form with existing data', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user)->get(route('posts.edit', $post));

    $response->assertStatus(200);
    $response->assertViewIs('posts.edit');
    $response->assertSee($post->title);
    $response->assertSee($post->content);
});

test('a post can be updated', function () {
    $post = Post::factory()->create([
        'title' => 'Original Title',
        'slug' => 'original-title',
        'content' => 'Original content.',
        'status' => 'draft',
        'user_id' => $this->user->id,
    ]);

    $response = $this->actingAs($this->user)->put(route('posts.update', $post), [
        'title' => 'Updated Title',
        'content' => 'Updated content.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post updated successfully.');

    $this->assertDatabaseHas('posts', [
        'id' => $post->id,
        'title' => 'Updated Title',
        'slug' => 'updated-title',
        'content' => 'Updated content.',
        'status' => 'publish',
    ]);
});

test('update validates required fields', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user)->put(route('posts.update', $post), []);

    $response->assertSessionHasErrors(['title', 'content', 'status']);
});

test('update allows same slug for the same post', function () {
    $post = Post::factory()->create([
        'title' => 'Keep This Title',
        'slug' => 'keep-this-title',
        'user_id' => $this->user->id,
    ]);

    $response = $this->actingAs($this->user)->put(route('posts.update', $post), [
        'title' => 'Keep This Title',
        'content' => 'Updated content only.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHasNoErrors();
});

// ============================================================
// Delete Tests
// ============================================================

test('a post can be deleted', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user)->delete(route('posts.destroy', $post));

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post deleted successfully.');

    $this->assertDatabaseMissing('posts', [
        'id' => $post->id,
    ]);
});

test('deleting a non-existent post returns 404', function () {
    $response = $this->actingAs($this->user)->delete(route('posts.destroy', 9999));

    $response->assertStatus(404);
});

// ============================================================
// Authentication Tests
// ============================================================

test('unauthenticated user is redirected to login from index', function () {
    $response = $this->get(route('posts.index'));

    $response->assertRedirect(route('login'));
});

test('unauthenticated user is redirected to login from create', function () {
    $response = $this->get(route('posts.create'));

    $response->assertRedirect(route('login'));
});

test('unauthenticated user is redirected to login from store', function () {
    $response = $this->post(route('posts.store'), [
        'title' => 'Test',
        'content' => 'Content',
        'status' => 'draft',
    ]);

    $response->assertRedirect(route('login'));
});

test('unauthenticated user is redirected to login from show', function () {
    $post = Post::factory()->create();

    $response = $this->get(route('posts.show', $post));

    $response->assertRedirect(route('login'));
});

test('unauthenticated user is redirected to login from edit', function () {
    $post = Post::factory()->create();

    $response = $this->get(route('posts.edit', $post));

    $response->assertRedirect(route('login'));
});

test('unauthenticated user is redirected to login from update', function () {
    $post = Post::factory()->create();

    $response = $this->put(route('posts.update', $post), [
        'title' => 'Updated',
        'content' => 'Content',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('login'));
});

test('unauthenticated user is redirected to login from destroy', function () {
    $post = Post::factory()->create();

    $response = $this->delete(route('posts.destroy', $post));

    $response->assertRedirect(route('login'));
});

// ============================================================
// Authorization Tests
// ============================================================

test('user cannot edit a post they do not own', function () {
    $otherUser = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $otherUser->id]);

    $response = $this->actingAs($this->user)->get(route('posts.edit', $post));

    $response->assertStatus(403);
});

test('user cannot update a post they do not own', function () {
    $otherUser = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $otherUser->id]);

    $response = $this->actingAs($this->user)->put(route('posts.update', $post), [
        'title' => 'Hijacked Title',
        'content' => 'Hijacked content.',
        'status' => 'publish',
    ]);

    $response->assertStatus(403);
});

test('user cannot delete a post they do not own', function () {
    $otherUser = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $otherUser->id]);

    $response = $this->actingAs($this->user)->delete(route('posts.destroy', $post));

    $response->assertStatus(403);

    $this->assertDatabaseHas('posts', ['id' => $post->id]);
});

test('post owner can edit their own post', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user)->get(route('posts.edit', $post));

    $response->assertStatus(200);
});

test('post owner can delete their own post', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user)->delete(route('posts.destroy', $post));

    $response->assertRedirect(route('posts.index'));
    $this->assertDatabaseMissing('posts', ['id' => $post->id]);
});
```

Simpan file.

### Key Changes in the Updated Tests

Berikut adalah ringkasan apa yang berubah dan alasannya:

**Setiap request kini menggunakan `actingAs($this->user)`.** Ini mensimulasikan user yang terautentikasi membuat request. Tanpanya, middleware `auth` akan mengarahkan ke halaman login dan test akan gagal.

**Test store kini meng-assert `user_id`.** Pemeriksaan `assertDatabaseHas` menyertakan `'user_id' => $this->user->id` untuk memverifikasi bahwa post ditetapkan dengan benar ke user yang terautentikasi.

**Test edit, update, dan delete menetapkan kepemilikan.** Test yang perlu lolos authorization kini membuat post dengan `'user_id' => $this->user->id` agar user yang terautentikasi menjadi pemiliknya. Tanpa ini, policy akan memblokir request dengan 403.

**Tujuh test authentication baru.** Test ini memverifikasi bahwa user yang belum terautentikasi diarahkan ke halaman login untuk setiap route di dalam controller (index, create, store, show, edit, update, destroy).

**Lima test authorization baru.** Tiga test memverifikasi bahwa seorang user tidak dapat mengedit, memperbarui, atau menghapus post yang dibuat oleh user lain (mengharapkan status 403). Dua test secara eksplisit mengonfirmasi bahwa pemilik post dapat mengedit dan menghapus post miliknya sendiri (test authorization positif).


## Step 8: Menambahkan Test Login {#step-8-add-login-tests}

Mari kita juga tambahkan test untuk fungsi login itu sendiri. Buat file test baru:

```
php artisan make:test Auth/LoginTest --pest
```

Buka `tests/Feature/Auth/LoginTest.php` dan tambahkan:

```php
<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

test('login page is displayed', function () {
    $response = $this->get(route('login'));

    $response->assertStatus(200);
    $response->assertSee('Login');
});

test('user can login with correct credentials', function () {
    $user = User::factory()->create([
        'password' => bcrypt('password123'),
    ]);

    $response = $this->post(route('login'), [
        'email' => $user->email,
        'password' => 'password123',
    ]);

    $response->assertRedirect(route('posts.index'));
    $this->assertAuthenticatedAs($user);
});

test('user cannot login with incorrect password', function () {
    $user = User::factory()->create([
        'password' => bcrypt('password123'),
    ]);

    $response = $this->post(route('login'), [
        'email' => $user->email,
        'password' => 'wrong-password',
    ]);

    $response->assertSessionHasErrors(['email']);
    $this->assertGuest();
});

test('user cannot login with non-existent email', function () {
    $response = $this->post(route('login'), [
        'email' => 'nobody@example.com',
        'password' => 'password123',
    ]);

    $response->assertSessionHasErrors(['email']);
    $this->assertGuest();
});

test('login validates required fields', function () {
    $response = $this->post(route('login'), []);

    $response->assertSessionHasErrors(['email', 'password']);
});

test('user can logout', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)->post(route('logout'));

    $response->assertRedirect(route('login'));
    $this->assertGuest();
});
```

Test ini mencakup:

- `assertAuthenticatedAs($user)` mengonfirmasi bahwa user sudah login setelah percobaan login yang berhasil.
- `assertGuest()` mengonfirmasi bahwa user tidak login setelah percobaan yang gagal atau setelah logout.
- Form login diuji untuk credentials yang valid maupun tidak valid, field yang hilang, dan email yang tidak ada.

Simpan file.


## Step 9: Menjalankan Semua Test {#step-9-run-all-tests}

Jalankan test suite lengkap:

```
php artisan test
```

Anda seharusnya melihat semua test lulus:

```
$ php artisan test

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\Auth\LoginTest
  ✓ login page is displayed                                              0.14s  
  ✓ user can login with correct credentials                              0.03s  
  ✓ user cannot login with incorrect password                            0.21s  
  ✓ user cannot login with non-existent email                            0.23s  
  ✓ login validates required fields                                      0.03s  
  ✓ user can logout                                                      0.01s  

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
  ✓ user cannot delete a post they do not own                            0.01s  
  ✓ post owner can edit their own post                                   0.01s  
  ✓ post owner can delete their own post                                 0.01s  

  Tests:    37 passed (94 assertions)
  Duration: 0.97s

```

Kita beralih dari 19 test menjadi 37 test. Berikut adalah rinciannya:

- **19 test CRUD orisinal** (diperbarui dengan `actingAs` dan kepemilikan)
- **7 test authentication** (redirect ke login untuk setiap route)
- **5 test authorization** (penegakan kepemilikan untuk edit, update, delete)
- **6 test login** (tampilan form, login valid/tidak valid, logout)
- **+1 ExampleTest** (unit) + **+1 ExampleTest** (feature) = sudah dihitung dalam total (test crud orisinal)


## Kesimpulan {#conclusion}

Pada tutorial ini, kita menambahkan authentication dan authorization ke aplikasi blog Laravel 13 kita. Kita membangun sistem login dari nol, melacak kepemilikan post dengan kolom `user_id`, membuat policy untuk menegakkan aturan kepemilikan, dan menggunakan PHP attributes Laravel 13 untuk menerapkan semuanya dengan rapi pada controller.

Berikut adalah poin-poin penting yang bisa diambil:

- **`#[Middleware('auth')]` pada class lebih bersih daripada pemanggilan di constructor.** Anda melihat kebutuhan middleware secara sekilas, tepat di bagian atas class. Tidak perlu memeriksa constructor atau file route.
- **`#[Authorize('update', 'post')]` mengikat pemeriksaan policy ke method.** Argumen kedua adalah nama parameter route, bukan nama variabel. Laravel menyelesaikan instance model dari route dan meneruskannya ke policy.
- **Policy menjaga logika authorization tetap terpisah.** Alih-alih menulis pernyataan `if` di controller, policy merangkum semua pemeriksaan kepemilikan di satu tempat. Jika aturan berubah, Anda memperbarui satu file.
- **`actingAs()` membuat testing yang terautentikasi menjadi sederhana.** Satu pemanggilan method mensimulasikan user yang sudah login untuk seluruh request. Dikombinasikan dengan `beforeEach()`, setiap test di dalam file dapat berbagi pengaturan user yang sama.
- **Uji authentication dan authorization secara terpisah.** Test authentication memverifikasi bahwa user yang belum terautentikasi diarahkan. Test authorization memverifikasi bahwa user yang terautentikasi hanya dapat mengakses resource yang mereka miliki. Ini adalah dua hal yang berbeda dan sebaiknya diuji secara independen.
- **Test suite bertumbuh dari 19 menjadi 37 test.** Setiap fitur keamanan baru disertai dengan test yang memverifikasi bahwa ia berfungsi. Ini memberi Anda keyakinan bahwa perubahan di masa depan tidak akan secara tidak sengaja menghapus pemeriksaan keamanan.

Pada tutorial berikutnya, kita akan [Membangun REST API untuk Blog Anda dengan Sanctum Authentication](https://qadrlabs.com/post/laravel-13-build-a-rest-api-for-your-blog-with-sanctum-authentication).
