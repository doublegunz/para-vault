---
title: "Memahami Laravel Policy: Dari Konsep Dasar hingga Implementasi Lanjutan"
slug: "memahami-laravel-policy-dari-konsep-dasar-hingga-implementasi-lanjutan"
category: "Laravel"
date: "2025-05-22"
status: "published"
---

## Memulai Perjalanan Otorisasi di Laravel {#memulai-perjalanan-otorisasi-di-laravel}

Dalam artikel sebelumnya tentang "[Using Spatie Laravel Permission in Laravel 11: A Step-by-Step Tutorial](https://qadrlabs.com/post/using-spatie-laravel-permission-in-laravel-11-a-step-by-step-tutorial)", kita telah mempelajari bagaimana mengimplementasikan sistem role dan permission yang powerful menggunakan package Spatie. Package tersebut memberikan solusi yang sangat robust untuk aplikasi dengan kebutuhan otorisasi yang kompleks, seperti sistem manajemen user dengan berbagai tingkat akses dan permission yang dapat dikelola secara dinamis.

Namun, Laravel sebenarnya sudah menyediakan sistem otorisasi built-in yang sangat elegant dan powerful, yaitu Laravel Policy. Jika pada tutorial Spatie kita belajar tentang pendekatan yang lebih "heavyweight" dengan database-driven roles dan permissions, maka Laravel Policy menawarkan pendekatan yang lebih "lightweight" namun tetap sangat fleksibel.

Pertanyaan yang sering muncul adalah: kapan kita sebaiknya menggunakan Laravel Policy, dan kapan lebih baik menggunakan package seperti Spatie Laravel Permission? Setelah memahami kedua pendekatan ini, Anda akan dapat membuat keputusan yang tepat berdasarkan kebutuhan spesifik aplikasi yang sedang Anda bangun.

Laravel Policy cocok digunakan ketika logika otorisasi aplikasi Anda relatif straightforward dan terkait erat dengan model-model dalam aplikasi. Misalnya, dalam aplikasi blog sederhana di mana penulis hanya boleh mengedit artikel mereka sendiri, atau aplikasi manajemen proyek di mana anggota tim hanya bisa mengakses proyek yang mereka ikuti. Policy memberikan cara yang sangat natural untuk mengekspresikan aturan-aturan seperti "user ini boleh mengakses resource ini jika kondisi tertentu terpenuhi."

## Memahami Filosofi Laravel Policy{#memahami-filosofi-laravel-policy}

Sebelum kita menyelami detail teknis, mari kita pahami filosofi di balik Laravel Policy. Laravel Policy dibangun dengan prinsip bahwa setiap model atau resource dalam aplikasi Anda memiliki aturan akses yang spesifik. Aturan-aturan ini biasanya berkaitan dengan hubungan antara user yang sedang login dengan resource yang ingin diakses.

Bayangkan Anda memiliki sebuah perpustakaan digital. Dalam perpustakaan ini, ada berbagai jenis buku dengan aturan akses yang berbeda. Buku umum bisa dibaca siapa saja, buku premium hanya bisa dibaca member premium, dan buku yang masih dalam tahap review hanya bisa dibaca oleh penulisnya atau editor. Laravel Policy seperti sistem katalog yang cerdas, yang tahu persis siapa boleh mengakses buku apa berdasarkan status mereka dan hubungan mereka dengan buku tersebut.

Keunggulan utama dari pendekatan ini adalah code organization yang sangat baik. Alih-alih menyebar logika otorisasi di berbagai controller atau middleware, semua aturan untuk satu model dikumpulkan dalam satu class Policy. Ini membuat code lebih mudah dibaca, di-maintain, dan di-test.

## Membangun Policy Pertama Anda: Pendekatan Step-by-Step{#membangun-policy-pertama-anda-pendekatan-step-by-step}

Mari kita mulai dengan contoh praktis yang akan membantu Anda memahami konsep dasar sebelum beralih ke implementasi yang lebih kompleks. Kita akan membangun sistem blog sederhana dengan aturan otorisasi yang realistis.

### Langkah Pertama: Menyiapkan Struktur Dasar

Pertama-tama, kita akan membuat Policy untuk model Post. Laravel menyediakan command Artisan yang memudahkan proses ini:

```bash
php artisan make:policy PostPolicy --model=Post
```

Command ini akan membuat file `app/Policies/PostPolicy.php` dengan struktur method yang standar. Parameter `--model=Post` memberitahu Laravel untuk membuat method-method yang umum digunakan untuk CRUD operations pada model Post.

Ketika Anda membuka file yang baru dibuat, Anda akan melihat struktur seperti ini. Mari kita pahami setiap bagian dengan detail:

```php
<?php

namespace App\Policies;

use App\Models\Post;
use App\Models\User;

class PostPolicy
{
    /**
     * Menentukan apakah user bisa melihat daftar semua post
     * Method ini dipanggil untuk action 'viewAny'
     */
    public function viewAny(User $user): bool
    {
        // Untuk saat ini, semua user yang sudah login bisa melihat daftar post
        // Nanti kita bisa tambahkan logika lebih kompleks di sini
        return true;
    }

    /**
     * Menentukan apakah user bisa melihat post tertentu
     * Method ini dipanggil untuk action 'view'
     */
    public function view(User $user, Post $post): bool
    {
        // User bisa melihat post jika:
        // 1. Post sudah dipublish (untuk semua user), ATAU
        // 2. User adalah pemilik post (bisa lihat draft sendiri)
        return $post->is_published || $user->id === $post->user_id;
    }

    /**
     * Menentukan apakah user bisa membuat post baru
     * Method ini dipanggil untuk action 'create'
     */
    public function create(User $user): bool
    {
        // Hanya user dengan role tertentu yang bisa membuat post
        // Kita asumsikan ada field 'role' di table users
        return in_array($user->role, ['author', 'editor', 'admin']);
    }

    /**
     * Menentukan apakah user bisa mengupdate post tertentu
     * Method ini dipanggil untuk action 'update'
     */
    public function update(User $user, Post $post): bool
    {
        // User bisa update post jika:
        // 1. User adalah pemilik post, ATAU
        // 2. User adalah admin (punya akses universal)
        return $user->id === $post->user_id || $user->role === 'admin';
    }

    /**
     * Menentukan apakah user bisa menghapus post tertentu
     * Method ini dipanggil untuk action 'delete'
     */
    public function delete(User $user, Post $post): bool
    {
        // Logika yang sama dengan update
        // Tapi kita bisa tambahkan aturan tambahan, misalnya:
        // post yang sudah dipublish tidak bisa dihapus kecuali oleh admin
        if ($post->is_published && $user->role !== 'admin') {
            return false;
        }
        
        return $user->id === $post->user_id || $user->role === 'admin';
    }
}
```

Perhatikan bagaimana setiap method menerima instance `User` sebagai parameter pertama. Ini adalah user yang sedang mencoba melakukan action. Method seperti `view`, `update`, dan `delete` juga menerima instance `Post` sebagai parameter kedua, karena mereka perlu mengecek otorisasi terhadap resource spesifik.

### Langkah Kedua: Memahami Auto-Discovery Laravel

Salah satu keunggulan Laravel adalah sistem auto-discovery yang cerdas. Laravel secara otomatis akan mengenali Policy Anda jika Anda mengikuti konvensi penamaan yang standar:

- Model: `App\Models\Post`
- Policy: `App\Policies\PostPolicy`

Laravel akan mencari Policy di lokasi berikut secara berurutan: pertama di `app/Models/Policies`, kemudian di `app/Policies`. Sistem ini sangat memudahkan development karena Anda tidak perlu melakukan konfigurasi tambahan untuk Policy sederhana.

Namun, jika Anda memiliki struktur yang berbeda atau ingin kontrol yang lebih eksplisit, Anda bisa mendaftarkan Policy secara manual. Meskipun di Laravel 12 tidak ada AuthServiceProvider terpisah, Anda bisa mendefinisikan pemetaan Policy di AppServiceProvider jika diperlukan.

## Mengimplementasikan Policy dalam Controller{#mengimplementasikan-policy-dalam-controller}

Setelah Policy kita siap, langkah selanjutnya adalah menggunakannya dalam controller. Laravel menyediakan beberapa cara untuk melakukan ini, masing-masing dengan kelebihan dan situasi penggunaan yang berbeda.

### Menggunakan Method authorize(): Pendekatan yang Paling Umum

Method `authorize()` adalah cara yang paling straightforward dan paling sering digunakan. Method ini tersedia di semua controller Laravel dan akan secara otomatis mengembalikan HTTP 403 error jika otorisasi gagal:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;

class PostController extends Controller
{
    /**
     * Menampilkan post tertentu
     * Di sini kita periksa apakah user boleh melihat post ini
     */
    public function show(Post $post)
    {
        // Laravel akan otomatis memanggil method 'view' di PostPolicy
        // Jika return false, Laravel akan throw 403 error
        $this->authorize('view', $post);
        
        // Jika sampai di sini, berarti user punya akses
        return view('posts.show', compact('post'));
    }

    /**
     * Menampilkan form untuk edit post
     */
    public function edit(Post $post)
    {
        // Periksa permission sebelum menampilkan form
        $this->authorize('update', $post);
        
        return view('posts.edit', compact('post'));
    }

    /**
     * Update post yang sudah ada
     */
    public function update(Request $request, Post $post)
    {
        // Selalu lakukan authorization check di awal
        $this->authorize('update', $post);
        
        // Validasi input
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'is_published' => 'boolean'
        ]);
        
        // Update post
        $post->update($validated);
        
        return redirect()->route('posts.show', $post)
            ->with('success', 'Post berhasil diupdate!');
    }

    /**
     * Hapus post
     */
    public function destroy(Post $post)
    {
        $this->authorize('delete', $post);
        
        $post->delete();
        
        return redirect()->route('posts.index')
            ->with('success', 'Post berhasil dihapus!');
    }
}
```

Yang menarik dari pendekatan ini adalah kesederhanaannya. Anda hanya perlu memanggil `$this->authorize()` dengan nama action dan model instance, dan Laravel akan menangani sisanya. Jika user tidak punya akses, Laravel akan secara otomatis mengembalikan response 403 Forbidden.

### Menggunakan Gate Facade: Untuk Kontrol yang Lebih Detail

Kadang-kadang Anda membutuhkan kontrol yang lebih detail atas apa yang terjadi ketika otorisasi gagal. Dalam kasus seperti ini, Anda bisa menggunakan Gate facade:

```php
use Illuminate\Support\Facades\Gate;

public function destroy(Post $post)
{
    // Dengan Gate, kita bisa handle sendiri apa yang terjadi jika akses ditolak
    if (Gate::denies('delete', $post)) {
        return redirect()->route('posts.index')
            ->with('error', 'Anda tidak memiliki izin untuk menghapus post ini.');
    }
    
    $post->delete();
    
    return redirect()->route('posts.index')
        ->with('success', 'Post berhasil dihapus!');
}
```

Pendekatan ini memberikan fleksibilitas lebih besar dalam menangani kasus ketika akses ditolak. Anda bisa memberikan pesan error yang lebih user-friendly atau melakukan redirect ke halaman yang lebih sesuai.

### Conditional Logic dengan User Model

Laravel juga menyediakan method `can()` dan `cannot()` langsung di model User, yang sangat berguna untuk conditional logic:

```php
public function index(Request $request)
{
    $query = Post::query();
    
    // Jika user bukan admin, filter hanya post yang bisa mereka lihat
    if ($request->user()->cannot('viewAny', Post::class)) {
        $query->where(function ($q) use ($request) {
            $q->where('is_published', true)
              ->orWhere('user_id', $request->user()->id);
        });
    }
    
    $posts = $query->latest()->paginate(10);
    
    return view('posts.index', compact('posts'));
}
```

Pendekatan ini sangat berguna ketika Anda perlu melakukan filtering data berdasarkan permission user, bukan hanya allow atau deny access.

## Mengintegrasikan Policy dengan Blade Templates{#mengintegrasikan-policy-dengan-blade-templates}

Salah satu kekuatan besar Laravel Policy adalah integrasinya yang seamless dengan Blade templates. Anda bisa dengan mudah menampilkan atau menyembunyikan elemen UI berdasarkan permission user.

### Directive Dasar: @can dan @cannot

Mari kita lihat bagaimana menggunakan directive Blade untuk mengontrol tampilan:

```
{{-- resources/views/posts/show.blade.php --}}
<div class="post-container">
    <h1>{{ $post->title }}</h1>
    
    <div class="post-meta">
        <p>Ditulis oleh: {{ $post->author->name }}</p>
        <p>Tanggal: {{ $post->created_at->format('d M Y') }}</p>
    </div>
    
    <div class="post-content">
        {!! nl2br(e($post->content)) !!}
    </div>
    
    {{-- Action buttons hanya muncul jika user punya permission --}}
    <div class="post-actions">
        @can('update', $post)
            <a href="{{ route('posts.edit', $post) }}" class="btn btn-primary">
                Edit Post
            </a>
        @endcan
        
        @can('delete', $post)
            <form action="{{ route('posts.destroy', $post) }}" method="POST" 
                  style="display: inline;" 
                  onsubmit="return confirm('Yakin ingin menghapus post ini?')">
                @csrf
                @method('DELETE')
                <button type="submit" class="btn btn-danger">
                    Hapus Post
                </button>
            </form>
        @endcan
    </div>
    
    {{-- Pesan untuk user yang tidak punya akses --}}
    @cannot('update', $post)
        @cannot('delete', $post)
            <div class="alert alert-info">
                Anda hanya bisa melihat post ini. Untuk mengedit atau menghapus, 
                Anda harus menjadi pemilik post atau memiliki role admin.
            </div>
        @endcannot
    @endcannot
</div>
```

### Directive untuk Actions Tanpa Model Instance

Untuk actions yang tidak memerlukan model instance tertentu, seperti `create`, Anda bisa menggunakan class name:

```
{{-- resources/views/posts/index.blade.php --}}
<div class="posts-header">
    <h1>Semua Post</h1>
    
    {{-- Tombol create hanya muncul untuk user yang punya permission --}}
    @can('create', App\Models\Post::class)
        <a href="{{ route('posts.create') }}" class="btn btn-success">
            Buat Post Baru
        </a>
    @endcan
</div>

<div class="posts-grid">
    @foreach($posts as $post)
        <div class="post-card">
            <h3>{{ $post->title }}</h3>
            <p>{{ Str::limit($post->content, 100) }}</p>
            
            <div class="post-card-actions">
                {{-- Link view selalu ada jika user bisa akses halaman ini --}}
                <a href="{{ route('posts.show', $post) }}" class="btn btn-outline">
                    Baca Selengkapnya
                </a>
                
                {{-- Edit link hanya untuk yang punya permission --}}
                @can('update', $post)
                    <a href="{{ route('posts.edit', $post) }}" class="btn btn-small">
                        Edit
                    </a>
                @endcan
            </div>
        </div>
    @endforeach
</div>
```

### Directive Kombinasi: @canany

Laravel juga menyediakan directive `@canany` yang berguna ketika Anda ingin menampilkan sesuatu jika user memiliki salah satu dari beberapa permission:

```
{{-- Tampilkan panel admin jika user punya salah satu permission ini --}}
@canany(['update', 'delete'], $post)
    <div class="admin-panel">
        <h4>Panel Manajemen</h4>
        
        @can('update', $post)
            <a href="{{ route('posts.edit', $post) }}" class="btn btn-primary">Edit</a>
        @endcan
        
        @can('delete', $post)
            <button class="btn btn-danger" onclick="deletePost({{ $post->id }})">
                Hapus
            </button>
        @endcan
    </div>
@endcanany
```

## Menangani Guest Users dalam Policy{#menangani-guest-users-dalam-policy}

Dalam aplikasi nyata, Anda sering perlu menangani user yang belum login (guest users). Secara default, Laravel Policy akan mengembalikan `false` untuk guest users, tetapi ada kalanya Anda ingin memberikan akses terbatas kepada mereka.

### Policy untuk Guest Users

Mari kita modifikasi PostPolicy untuk menangani guest users dengan elegant:

```php
<?php

namespace App\Policies;

use App\Models\Post;
use App\Models\User;

class PostPolicy
{
    /**
     * Menentukan apakah user (termasuk guest) bisa melihat post tertentu
     * Perhatikan tanda tanya (?) sebelum User - ini memungkinkan null value
     */
    public function view(?User $user, Post $post): bool
    {
        // Jika post tidak dipublish
        if (!$post->is_published) {
            // Guest user tidak bisa lihat draft
            if (!$user) {
                return false;
            }
            
            // User yang login hanya bisa lihat draft milik sendiri
            return $user->id === $post->user_id;
        }
        
        // Jika post sudah dipublish, semua orang (termasuk guest) bisa lihat
        return true;
    }

    /**
     * Guest user tidak bisa melihat daftar semua post
     * Hanya user yang login yang bisa akses halaman index
     */
    public function viewAny(?User $user): bool
    {
        // Guest tidak bisa akses halaman index
        return $user !== null;
    }

    /**
     * Hanya user yang login yang bisa membuat post
     */
    public function create(?User $user): bool
    {
        if (!$user) {
            return false;
        }
        
        return in_array($user->role, ['author', 'editor', 'admin']);
    }

    /**
     * Method untuk actions lain tetap memerlukan user yang login
     */
    public function update(User $user, Post $post): bool
    {
        return $user->id === $post->user_id || $user->role === 'admin';
    }

    public function delete(User $user, Post $post): bool
    {
        return $user->id === $post->user_id || $user->role === 'admin';
    }
}
```

Perhatikan penggunaan nullable type hint (`?User $user`) pada beberapa method. Ini memberitahu PHP bahwa parameter `$user` bisa berupa instance User atau `null` (untuk guest users).

### Menggunakan Policy dengan Guest Users di Controller

Ketika menggunakan Policy dengan guest users, Anda perlu sedikit lebih hati-hati dalam implementasinya:

```php
public function show(Post $post)
{
    // authorize() akan otomatis handle guest users
    // Jika guest tidak punya akses, akan mendapat 403 error
    $this->authorize('view', $post);
    
    return view('posts.show', compact('post'));
}

public function index(Request $request)
{
    // Untuk halaman yang memerlukan login, cek dulu
    if (!$request->user()) {
        return redirect()->route('login')
            ->with('message', 'Silakan login untuk melihat daftar post.');
    }
    
    $this->authorize('viewAny', Post::class);
    
    $posts = Post::latest()->paginate(10);
    return view('posts.index', compact('posts'));
}
```

## Policy Filters: Before Method untuk Rules Global{#policy-filters-before-method-untuk-rules-global}

Dalam aplikasi yang lebih kompleks, Anda mungkin memiliki user dengan akses khusus yang bisa melakukan semua action, seperti super admin. Alih-alih menuliskan logic "jika super admin" di setiap method Policy, Laravel menyediakan `before` method yang elegant:

```php
<?php

namespace App\Policies;

use App\Models\Post;
use App\Models\User;

class PostPolicy
{
    /**
     * Method ini dijalankan SEBELUM method Policy lainnya
     * Jika return true: user langsung diberi akses, method lain tidak dijalankan
     * Jika return false: user langsung ditolak, method lain tidak dijalankan  
     * Jika return null: proses berlanjut ke method yang sesuai
     */
    public function before(User $user, string $ability): ?bool
    {
        // Super admin bisa melakukan semua action
        if ($user->role === 'super-admin') {
            return true;
        }
        
        // Jika user di-suspend, tolak semua access
        if ($user->status === 'suspended') {
            return false;
        }
        
        // Untuk user lain, lanjutkan ke method yang sesuai
        return null;
    }

    /**
     * Method-method ini hanya akan dipanggil jika before() return null
     */
    public function view(?User $user, Post $post): bool
    {
        // Logic seperti sebelumnya
        if (!$post->is_published) {
            return $user && $user->id === $post->user_id;
        }
        
        return true;
    }

    public function update(User $user, Post $post): bool
    {
        // Method ini tidak akan dipanggil untuk super-admin
        // karena before() sudah return true
        return $user->id === $post->user_id;
    }

    // Method lainnya...
}
```

Method `before` sangat powerful karena memberikan central control point untuk aturan-aturan global. Ini sangat berguna untuk implementasi role-based access yang sederhana tanpa perlu package eksternal.

## Policy Responses: Memberikan Feedback yang Bermakna{#policy-responses-memberikan-feedback-yang-bermakna}

Secara default, Policy method hanya mengembalikan `true` atau `false`. Namun, Laravel memungkinkan Anda memberikan response yang lebih informatif menggunakan Response class:

```php
use Illuminate\Auth\Access\Response;

public function update(User $user, Post $post): Response
{
    // Cek ownership
    if ($user->id !== $post->user_id && $user->role !== 'admin') {
        return Response::deny('Anda hanya bisa mengedit post yang Anda buat sendiri.');
    }
    
    // Cek apakah post masih bisa diedit (misalnya dalam 24 jam)
    if ($post->created_at->diffInHours(now()) > 24 && $user->role !== 'admin') {
        return Response::deny('Post hanya bisa diedit dalam 24 jam setelah dibuat.');
    }
    
    // Cek apakah post sudah dipublish
    if ($post->is_published && $user->role === 'author') {
        return Response::deny('Post yang sudah dipublish tidak bisa diedit oleh author. Hubungi editor untuk perubahan.');
    }
    
    return Response::allow();
}

public function delete(User $user, Post $post): Response
{
    if ($user->id !== $post->user_id && $user->role !== 'admin') {
        return Response::deny('Anda tidak bisa menghapus post orang lain.');
    }
    
    // Post dengan banyak komentar tidak bisa dihapus
    if ($post->comments()->count() > 10) {
        return Response::deny('Post dengan lebih dari 10 komentar tidak bisa dihapus untuk menjaga diskusi.');
    }
    
    return Response::allow();
}
```

Dengan menggunakan Response class, pesan error yang Anda definisikan akan ditampilkan kepada user ketika akses ditolak. Ini memberikan user feedback yang lebih baik daripada sekadar "403 Forbidden".

### Custom HTTP Status Codes

Anda bahkan bisa mengembalikan HTTP status code yang berbeda:

```php
public function view(?User $user, Post $post): Response
{
    if (!$post->is_published) {
        if (!$user) {
            // Redirect ke login daripada 403
            return Response::denyWithStatus(401);
        }
        
        if ($user->id !== $post->user_id) {
            // Sembunyikan eksistensi post dengan 404
            return Response::denyAsNotFound();
        }
    }
    
    return Response::allow();
}
```

## Testing Policy: Memastikan Logic Otorisasi Bekerja Dengan Benar{#testing-policy-memastikan-logic-otorisasi-bekerja-dengan-benar}

Testing adalah aspek yang sangat penting dalam development, terutama untuk logic otorisasi yang critical. Laravel menyediakan tools yang excellent untuk testing Policy:

### Unit Testing Policy Classes

```php
<?php

namespace Tests\Unit;

use App\Models\Post;
use App\Models\User;
use App\Policies\PostPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PostPolicyTest extends TestCase
{
    use RefreshDatabase;

    protected PostPolicy $policy;

    protected function setUp(): void
    {
        parent::setUp();
        $this->policy = new PostPolicy();
    }

    public function test_user_can_view_published_post()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create(['is_published' => true]);
        
        $this->assertTrue($this->policy->view($user, $post));
    }

    public function test_guest_can_view_published_post()
    {
        $post = Post::factory()->create(['is_published' => true]);
        
        // Test dengan null user (guest)
        $this->assertTrue($this->policy->view(null, $post));
    }

    public function test_user_can_view_own_draft()
    {
        $user = User::factory()->create();
        $post = Post::factory()->create([
            'user_id' => $user->id,
            'is_published' => false
        ]);
        
        $this->assertTrue($this->policy->view($user, $post));
    }

    public function test_user_cannot_view_others_draft()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        $post = Post::factory()->create([
            'user_id' => $user2->id,
            'is_published' => false
        ]);
        
        $this->assertFalse($this->policy->view($user1, $post));
    }

    public function test_admin_can_update_any_post()
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $regularUser = User::factory()->create(['role' => 'author']);
        $post = Post::factory()->create(['user_id' => $regularUser->id]);
        
        $this->assertTrue($this->policy->update($admin, $post));
    }

    public function test_super_admin_bypasses_all_checks()
    {
        $superAdmin = User::factory()->create(['role' => 'super-admin']);
        $post = Post::factory()->create();
        
        // Super admin harus bisa melakukan semua action
        $this->assertTrue($this->policy->before($superAdmin, 'any-ability'));
    }
}
```

### Feature Testing dengan Policy Integration

```php
<?php

namespace Tests\Feature;

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PostControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_author_can_edit_own_post()
    {
        $user = User::factory()->create(['role' => 'author']);
        $post = Post::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user)
            ->get(route('posts.edit', $post));

        $response->assertStatus(200);
        $response->assertViewIs('posts.edit');
        $response->assertViewHas('post', $post);
    }

    public function test_user_cannot_edit_others_post()
    {
        $user1 = User::factory()->create(['role' => 'author']);
        $user2 = User::factory()->create(['role' => 'author']);
        $post = Post::factory()->create(['user_id' => $user2->id]);

        $response = $this->actingAs($user1)
            ->get(route('posts.edit', $post));

        $response->assertStatus(403);
    }

    public function test_guest_cannot_access_post_index()
    {
        $response = $this->get(route('posts.index'));

        // Should redirect to login
        $response->assertRedirect(route('login'));
    }

    public function test_suspended_user_cannot_access_any_post()
    {
        $user = User::factory()->create([
            'role' => 'author',
            'status' => 'suspended'
        ]);
        $post = Post::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user)
            ->get(route('posts.show', $post));

        $response->assertStatus(403);
    }
}
```

## Advanced Patterns dan Best Practices{#advanced-patterns-dan-best-practices}

### Pattern: Conditional Policy Logic

Kadang-kadang Anda memerlukan logic yang lebih kompleks yang bergantung pada multiple conditions:

```php
public function publish(User $user, Post $post): Response
{
    // Hanya draft yang bisa dipublish
    if ($post->is_published) {
        return Response::deny('Post sudah dipublish.');
    }
    
    // Author hanya bisa publish post sendiri
    if ($user->role === 'author' && $user->id !== $post->user_id) {
        return Response::deny('Anda hanya bisa publish post sendiri.');
    }
    
    // Editor dan admin bisa publish post siapa saja
    if (!in_array($user->role, ['author', 'editor', 'admin'])) {
        return Response::deny('Role Anda tidak diizinkan untuk publish post.');
    }
    
    // Cek apakah post memenuhi syarat publikasi
    if (strlen($post->content) < 100) {
        return Response::deny('Post harus memiliki minimal 100 karakter untuk dipublish.');
    }
    
    if (!$post->featured_image) {
        return Response::deny('Post harus memiliki featured image sebelum dipublish.');
    }
    
    return Response::allow();
}
```

### Pattern: Policy dengan Additional Context

Laravel Policy memungkinkan Anda mengirim additional context yang bisa berguna untuk decision making:

```php
public function transfer(User $user, Post $post, User $newOwner): Response
{
    // Hanya pemilik atau admin yang bisa transfer
    if ($user->id !== $post->user_id && $user->role !== 'admin') {
        return Response::deny('Hanya pemilik post atau admin yang bisa melakukan transfer.');
    }
    
    // Post yang sudah dipublish tidak bisa ditransfer
    if ($post->is_published) {
        return Response::deny('Post yang sudah dipublish tidak bisa ditransfer untuk menjaga konsistensi authorship.');
    }
    
    // User tujuan harus memiliki role yang sesuai
    if (!in_array($newOwner->role, ['author', 'editor'])) {
        return Response::deny('Post hanya bisa ditransfer ke user dengan role author atau editor.');
    }
    
    // User tujuan tidak boleh memiliki terlalu banyak draft posts
    if ($newOwner->posts()->where('is_published', false)->count() >= 10) {
        return Response::deny('User tujuan sudah memiliki terlalu banyak draft posts.');
    }
    
    return Response::allow();
}
```

Untuk menggunakan Policy dengan additional context di controller:

```php
public function transfer(Request $request, Post $post)
{
    $newOwner = User::findOrFail($request->new_owner_id);
    
    // Pass additional context sebagai array
    $this->authorize('transfer', [$post, $newOwner]);
    
    $post->update(['user_id' => $newOwner->id]);
    
    return response()->json(['message' => 'Post berhasil ditransfer']);
}
```

### Best Practice: Consistent Method Naming

Gunakan naming convention yang konsisten untuk method Policy Anda:

```php
class PostPolicy
{
    // Standard CRUD operations
    public function viewAny(User $user): bool { }
    public function view(?User $user, Post $post): bool { }
    public function create(User $user): bool { }
    public function update(User $user, Post $post): bool { }
    public function delete(User $user, Post $post): bool { }
    
    // Custom operations - gunakan verb yang jelas
    public function publish(User $user, Post $post): bool { }
    public function unpublish(User $user, Post $post): bool { }
    public function archive(User $user, Post $post): bool { }
    public function restore(User $user, Post $post): bool { }
    public function transfer(User $user, Post $post, User $newOwner): bool { }
    
    // Operations yang tidak memerlukan instance
    public function viewTrashed(User $user): bool { }
    public function viewAnalytics(User $user): bool { }
}
```

### Best Practice: Documentation dan Comments

Selalu dokumentasikan logic Policy yang kompleks:

```php
/**
 * Menentukan apakah user bisa mendownload post sebagai PDF
 * 
 * Aturan:
 * - Post harus sudah dipublish
 * - User harus login (tidak boleh guest)
 * - Untuk post premium, user harus memiliki subscription aktif
 * - Author dan editor bisa download post apapun untuk preview
 * 
 * @param User $user User yang ingin download
 * @param Post $post Post yang ingin didownload
 * @return Response
 */
public function downloadPdf(User $user, Post $post): Response
{
    if (!$post->is_published) {
        // Author dan editor bisa download draft untuk preview
        if (in_array($user->role, ['author', 'editor']) && 
            ($user->id === $post->user_id || $user->role === 'editor')) {
            return Response::allow();
        }
        
        return Response::deny('Hanya post yang sudah dipublish yang bisa didownload.');
    }
    
    // Cek premium content
    if ($post->is_premium && !$user->hasActiveSubscription()) {
        return Response::deny('Post premium memerlukan subscription aktif.');
    }
    
    return Response::allow();
}
```

## Memilih Antara Laravel Policy dan Package External{#memilih-antara-laravel-policy-dan-package-external}

Setelah memahami Laravel Policy secara mendalam, mari kita kembali ke pertanyaan awal: kapan menggunakan Laravel Policy, dan kapan lebih baik menggunakan package seperti Spatie Laravel Permission?

### Gunakan Laravel Policy Ketika:

Laravel Policy adalah pilihan yang tepat untuk aplikasi dengan karakteristik berikut. Pertama, ketika logika otorisasi Anda terkait erat dengan model-model dalam aplikasi dan dapat diekspresikan sebagai hubungan antara user dan resource. Kedua, ketika Anda tidak memerlukan sistem role dan permission yang dapat dikelola secara dinamis melalui database. Ketiga, ketika tim development relatif kecil dan tidak memerlukan interface untuk mengelola user permissions. Keempat, ketika Anda ingin kontrol penuh atas logic otorisasi tanpa dependencies eksternal.

Contoh skenario yang cocok untuk Policy adalah aplikasi blog personal, sistem manajemen dokumen sederhana, aplikasi e-commerce kecil dengan aturan akses yang straightforward, atau aplikasi internal dengan business logic yang sangat spesifik.

### Gunakan Package seperti Spatie Laravel Permission Ketika:

Di sisi lain, package seperti Spatie Laravel Permission lebih cocok untuk aplikasi yang memerlukan sistem otorisasi yang kompleks dan fleksibel. Ini termasuk aplikasi dengan multiple roles yang memiliki permission berbeda-beda, kebutuhan untuk memberikan dan mencabut permission secara dinamis tanpa deploy ulang, keperluan admin panel untuk mengelola user permissions, atau aplikasi yang akan berkembang dan membutuhkan sistem yang scalable.

Skenario yang cocok untuk Spatie meliputi aplikasi enterprise dengan banyak level user, sistem manajemen konten dengan workflow approval yang kompleks, aplikasi SaaS dengan different tiers of access, atau platform e-learning dengan berbagai jenis user (student, instructor, admin, moderator).

### Pendekatan Hybrid: Menggabungkan Keduanya

Dalam aplikasi yang sangat kompleks, Anda bahkan bisa menggabungkan kedua pendekatan untuk mendapatkan benefits dari keduanya:

```php
<?php

namespace App\Policies;

use App\Models\Post;
use App\Models\User;
use Illuminate\Auth\Access\Response;

class PostPolicy
{
    public function before(User $user, string $ability): ?bool
    {
        // Gunakan Spatie untuk role-based checks
        if ($user->hasRole('super-admin')) {
            return true;
        }
        
        // Cek permission umum menggunakan Spatie
        if ($user->hasPermissionTo("posts.{$ability}")) {
            // Jika punya permission umum, lanjut ke specific checks
            return null;
        }
        
        // Jika tidak punya permission sama sekali, tolak
        return false;
    }

    public function update(User $user, Post $post): Response
    {
        // Di sini kita sudah yakin user punya permission 'posts.update'
        // Sekarang kita cek business logic spesifik
        
        // Cek ownership
        if ($user->id !== $post->user_id && !$user->hasRole(['editor', 'admin'])) {
            return Response::deny('Anda hanya bisa edit post sendiri.');
        }
        
        // Business logic khusus: post tidak bisa diedit setelah 24 jam
        if ($post->created_at->diffInHours(now()) > 24 && 
            !$user->hasRole(['editor', 'admin'])) {
            return Response::deny('Post hanya bisa diedit dalam 24 jam setelah dibuat.');
        }
        
        // Logic tambahan berdasarkan status post
        if ($post->status === 'under_review' && 
            !$user->hasRole('editor')) {
            return Response::deny('Post yang sedang direview hanya bisa diedit oleh editor.');
        }
        
        return Response::allow();
    }
}
```

Pendekatan hybrid ini memberikan fleksibilitas maksimal: Anda mendapatkan kemudahan management dari Spatie untuk role dan permission dasar, namun tetap memiliki kontrol granular melalui Policy untuk business logic yang spesifik.

## Kesimpulan dan Langkah Selanjutnya{#kesimpulan-dan-langkah-selanjutnya}

Laravel Policy adalah sistem otorisasi yang powerful dan elegant yang memungkinkan Anda mengorganisir logic otorisasi dengan sangat baik. Setelah mempelajari semua aspek Policy dari dasar hingga advanced patterns, Anda sekarang memiliki foundation yang solid untuk membuat keputusan arsitektural yang tepat.

Kunci sukses dalam menggunakan Laravel Policy adalah memahami kapan ia merupakan tool yang tepat untuk masalah yang Anda hadapi. Policy excel dalam situasi di mana otorisasi terkait erat dengan business logic aplikasi dan hubungan antar models. Ia memberikan code organization yang excellent dan testing yang mudah.

Namun, jangan ragu untuk beralih ke solutions yang lebih robust seperti Spatie Laravel Permission ketika aplikasi Anda berkembang dan memerlukan sistem role-permission yang lebih dinamis. Seperti yang telah kita bahas dalam artikel sebelumnya tentang Spatie Laravel Permission, package tersebut menyediakan solutions yang sangat mature untuk kebutuhan enterprise-level.

Yang paling penting adalah memulai dengan approach yang sesuai dengan kompleksitas current requirements Anda, namun tetap mempertimbangkan future scalability. Laravel Policy memberikan starting point yang excellent yang bisa di-evolve seiring pertumbuhan aplikasi.

Mulailah dengan implement Policy sederhana untuk features core aplikasi Anda, kemudian expand sesuai kebutuhan. Dengan pemahaman yang solid tentang kedua approaches ini, Anda akan dapat membuat sistem otorisasi yang tidak hanya secure dan functional, tetapi juga maintainable dan scalable dalam jangka panjang.