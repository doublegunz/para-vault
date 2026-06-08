---
title: "Tutorial CRUD Laravel 12 with Livewire Starter Kit"
slug: "tutorial-crud-laravel-12-with-livewire-starter-kit"
category: "Laravel"
date: "2025-03-11"
status: "published"
---

Pada artikel sebelumnya kita sudah membahasa tentang Starter Kit baru di Laravel 12. Salah satu stack yang digunakan adalah menggunakan [Livewire](https://qadrlabs.com/post/laravel-12-starter-kit#livewire-starter-kit). Biasanya ketika muncul starter kit baru selalu muncul kekhawatiran. Diantaranya adalah bagaimana cara menambahkan fitur baru setelah kita install starter kit tersebut. Terutama ketika kita belum terbiasa dalam menggunakan stack baru. Oleh karena itu pada tutorial ini kita akan coba menambahkan fitur baru project dengan Livewire Starter Kit.

## Overview{#overview}

Pada tutorial ini kita akan belajar menambahkan fitur baru ke dalam project yang dibangun menggunakan Livewire Starter Kit dari Laravel 12. Sebagai studi kasus, kita akan tambahkan fitur untuk mengelola tugas atau Task Management. Kita akan memulai dengan menyiapkan project baru menggunakan Livewire Starter Kit, kemudian secara bertahap membangun setiap komponen sistem pengelolaan tugas termasuk model database, komponen Livewire, route, dan view. Di akhir tutorial ini, Anda akan memiliki sistem pengelolaan tugas yang fungsional yang terintegrasi dengan sistem autentikasi Laravel 12 dan memahami cara memperluas project Livewire Starter Kit dengan fitur kustom Anda sendiri.

> Per tanggal 15 April 2025, Tim qadrlabs telah melakukan pengujian ulang pada Laravel 13 dan Livewire v4, dan kami mengonfirmasi bahwa seluruh langkah dalam tutorial ini masih berjalan. 

## Step 1: Setup Livewire Starter Kit {#step-1-setup-livewire-starter-kit}

Pertama kita akan setup livewire starter kit untuk project crud kita.

```
laravel new crud-livewire-starter-kit
```

Setelah kita run laravel installer untuk membuat project baru, tampil prompt untuk memilih starter kit.

```
$ laravel new crud-livewire-starter-kit

 ██╗       █████╗  ██████╗   █████╗  ██╗   ██╗ ███████╗ ██╗
 ██║      ██╔══██╗ ██╔══██╗ ██╔══██╗ ██║   ██║ ██╔════╝ ██║
 ██║      ███████║ ██████╔╝ ███████║ ██║   ██║ █████╗   ██║
 ██║      ██╔══██║ ██╔══██╗ ██╔══██║ ╚██╗ ██╔╝ ██╔══╝   ██║
 ███████╗ ██║  ██║ ██║  ██║ ██║  ██║  ╚████╔╝  ███████╗ ███████╗
 ╚══════╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝   ╚═══╝   ╚══════╝ ╚══════╝

 ┌ Which starter kit would you like to install? ────────────────┐
 │   ○ None                                                     │
 │   ○ React                                                    │
 │   ○ Svelte                                                   │
 │   ○ Vue                                                      │
 │ › ● Livewire                                                 │
 └──────────────────────────────────────────────────────────────┘



```

Pilih `livewire`, lalu tekan `enter` untuk melanjutkan. Selanjutnya akan tampil prompt untuk memilih authentication provider. Di sini kita pilih laravel's built-in authentication, lalu tekan `enter` untuk melanjutkan.

```

 ┌ Which authentication provider do you prefer? ────────────────┐
 │ › ● Laravel's built-in authentication                        │
 │   ○ WorkOS (Requires WorkOS account)                         │
 │   ○ No authentication scaffolding                            │
 └──────────────────────────────────────────────────────────────┘



```

Selanjutnya akan tampil prompt apakah kita akan menggunakan `single-file Livewire components`. pilih `no`, lalu tekan `enter` untuk melanjutkan.

```

 ┌ Would you like to use single-file Livewire components? ──────┐
 │ ○ Yes / ● No                                                 │
 └──────────────────────────────────────────────────────────────┘



```

Setelah itu pilih `pest` untuk testing framework, lalu tekan `enter` untuk melanjutkan.

```
 ┌ Which testing framework do you prefer? ──────────────────────┐
 │ › ● Pest                                                     │
 │   ○ PHPUnit                                                  │
 └──────────────────────────────────────────────────────────────┘


```

Kita tunggu sampai proses buat project baru dengan livewire starter kit selesai.

Selanjutnya akan tampil prompt build asset.

```
 ┌ Would you like to run npm install and npm … ───┐
 │ Yes                                                          │
 └──────────────────────────────────────────────────────────────┘


```

Pilih `yes`, lalu tekan `enter` untuk memulai proses install dependensi dan build assets frontend.



## Step 2: Atur Konfigurasi {#step-2-atur-konfigurasi}

Selanjutnya kita masuk ke direktori project.

```
cd crud-livewire-starter-kit
```

Buka project di code editor, lalu buka file `.env`. Pada file `.env`, kita atur konfigurasi database dan app url.

```
APP_URL=http://127.0.0.1:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_crud_livewire
DB_USERNAME=root
DB_PASSWORD=password
```

Save kembali `.env`.

Selanjutnya kita run migrate command untuk membuat database dan juga table.

```
php artisan migrate
```

Ketika tampil prompt untuk membuat database, pilih `yes`, lalu tekan `enter` untuk melanjutkan proses migrate.

```
$ php artisan migrate

   WARN  The database 'db_crud_livewire' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘


```

Output:

```
$ php artisan migrate

   WARN  The database 'db_crud_livewire' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ Yes                                                          │
 └──────────────────────────────────────────────────────────────┘

   INFO  Preparing database.  

  Creating migration table ...................................... 23.64ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table ......................... 121.12ms DONE
  0001_01_01_000001_create_cache_table .......................... 50.46ms DONE
  0001_01_01_000002_create_jobs_table .......................... 128.24ms DONE


```



## Step 3: Buat Model dan Migration {#step-3-buat-model-dan-migration}

Selanjutnya kita buat file mode dan migration untuk table `tasks`.

```
php artisan make:model Task -m
```

Output:

```
$ php artisan make:model Task -m

   INFO  Model [app/Models/Task.php] created successfully.  

   INFO  Migration [database/migrations/2025_03_11_143942_create_tasks_table.php] created successfully.  
```



Buka file `app/Models/Task.php`, lalu kita tambahkan method `$fillable`.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Task extends Model
{
    protected $fillable = [
        'title',
        'description',
    ];
}

```



Setelah itu kita buka file migration `database/migrations/xxxx_xx_xx_xxxxxx_create_tasks_table.php`, lalu kita sesuaikan method `up()`.

```php
public function up(): void
{
    Schema::create('tasks', function (Blueprint $table) {
        $table->id();
        $table->string('title');
        $table->text('description');
        $table->timestamps();
    });
}
```

Save kembali file migration.

Selanjutnya kita run kembali migrate command.

```
php artisan migrate
```

Output:

```
$ php artisan migrate

   INFO  Running migrations.  

  2025_03_11_143942_create_tasks_table .......................... 37.90ms DONE

```



## Step 4: Buat Livewire Component {#step-4-buat-livewire-component}

Selanjutnya kita akan buat livewire component untuk view data.

```
php artisan make:livewire Tasks/Index --class
```

Output:

```
$ php artisan make:livewire Tasks/Index --class

   INFO  Livewire component [app/Livewire/Tasks/Index.php] created successfully.
```

Lalu kita buat component kedua untuk create data.

```
php artisan make:livewire Tasks/Create --class
```

Output:

```
$ php artisan make:livewire Tasks/Create --class

   INFO  Livewire component [app/Livewire/Tasks/Create.php] created successfully.

```

Dan selanjutnya kita buat component ketiga untuk update data.

```
php artisan make:livewire Tasks/Edit --class
```

Output:

```
$ php artisan make:livewire Tasks/Edit --class

   INFO  Livewire component [app/Livewire/Tasks/Edit.php] created successfully.

```



## Step 5: Definisikan Route{#step-5-definisikan-route}

Selanjutnya kita akan definisikan route yang akan menangani proses view data, create data dan update data. Untuk mendefinisikan route buka file `routes/web.php`.

```php
// baris kode lainnya

Route::middleware(['auth'])->group(function () {
    // baris kode lainnya
    
    // tambahkan route
    Route::get('tasks', \App\Livewire\Tasks\Index::class)->name('tasks.index');
    Route::get('tasks/create', \App\Livewire\Tasks\Create::class)->name('tasks.create');
    Route::get('tasks/edit/{task}', \App\Livewire\Tasks\Edit::class)->name('tasks.edit');
});
```



## Step 6: Coding Fitur Menampilkan Data {#step-6-coding-fitur-view-data}

Sekarang kita akan coding fitur crud yang pertama yaitu fitur menampilkan data. Fitur untuk menampilkan data ini akan ditangani oleh komponen livewire `app/Livewire/Tasks/Index.php`. 

Buka kembali komponen livewire `app/Livewire/Tasks/Index.php`, lalu kita sesuaikan isi cari class `Index`.

```php
<?php

namespace App\Livewire\Tasks;

use App\Models\Task;
use Livewire\Component;
use Illuminate\View\View;
use Livewire\WithPagination;

class Index extends Component
{
    use WithPagination;
    public function render(): View
    {
        return view('livewire.tasks.index', [
            'tasks' => Task::paginate(10),
        ]);
    }
}
```

Pada method `render()`, kita akan tampilkan data di file view `resources/views/livewire/tasks/index.blade.php`. Sekarang kita modifikasi file `resources/views/livewire/tasks/index.blade.php`.

```
<div class="h-full w-full flex-1">

    <flux:button :href="route('tasks.create')" class="mb-4">
        Create
    </flux:button>

    <div class="overflow-x-auto">
        <table class="table-auto w-full border-collapse border border-gray-200">
            <thead>
            <tr class="bg-gray-50">
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider border border-gray-200">
                    Title
                </th>
                <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider border border-gray-200">
                    Actions
                </th>
            </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
            @forelse($tasks as $task)
                <tr class="hover:bg-gray-50">
                    <td class="px-4 py-4 whitespace-nowrap text-sm text-gray-900 align-middle border border-gray-200">
                        {{ $task->title }}
                    </td>
                    <td class="px-4 py-4 text-sm text-gray-900 text-center align-middle space-x-2 border border-gray-200">
                        <flux:button :href="route('tasks.edit', $task)" class="inline-block">Edit</flux:button>
                        <flux:button variant="danger" wire:click="delete({{ $task->id }})" wire:confirm="Are you sure?" class="inline-block">Delete</flux:button>
                    </td>
                </tr>
            @empty
                <tr>
                    <td class="text-center" colspan="2">Data empty</td>
                </tr>
            @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-2">
        {{ $tasks->links() }}
    </div>

</div>

```

Setelah selesai, simpan kembali file view.

Selanjutnya kita akan tambahkan menu di sidebar supaya memudahkan pengguna untuk mengakses halaman daftar task. Untuk menambahkan menu baru di sidebar, kita buka file view `resources/views/layouts/app/sidebar.blade.php`. Pada file tersebut temukan baris kode berikut ini.

```
<flux:sidebar.nav>
    <flux:sidebar.group :heading="__('Platform')" class="grid">
        <flux:sidebar.item icon="home" :href="route('dashboard')" :current="request()->routeIs('dashboard')" wire:navigate>
            {{ __('Dashboard') }}
        </flux:sidebar.item>
    </flux:sidebar.group>
</flux:sidebar.nav>
```

Lalu kita tambahkan menu baru di sidebar yang mengarah ka route `tasks.index`.

```
<flux:sidebar.nav>
    <flux:sidebar.group :heading="__('Platform')" class="grid">
        <flux:sidebar.item icon="home" :href="route('dashboard')" :current="request()->routeIs('dashboard')" wire:navigate>
            {{ __('Dashboard') }}
        </flux:sidebar.item>
				
        <!-- TAMBAHKAN BARIS KODE BERIKUT -->
				
        <flux:sidebar.item icon="folder-git-2" :href="route('tasks.index')" :current="request()->routeIs('tasks.*')" wire:navigate>
            {{ __('Tasks') }}
        </flux:sidebar.item>
				<!-- SELESAI -->
    </flux:sidebar.group>
</flux:sidebar.nav>
```

Setelah selesai save kembali file `resources/views/layouts/app/sidebar.blade.php`.

Pada baris kode di atas terdapat code icon `<flux:sidebar.item icon="folder-git-2"`. Icon `folder-git-2` ini merujuk ke file `resources/views/flux/icon/folder-git-2.blade.php`. Teman-teman boleh menyesuaikan untuk iconnya.

Sekarang kita sudah selesai coding fitur untuk menampilkan data.

## Step 7: Coding Fitur Menambahkan Data {#step-7-coding-fitur-create-data}

Sekarang kita akan coding fitur crud yang kedua, yaitu fitur untuk menambahkan data. Fitur tersebut akan ditangani oleh komponen livewire `app/Livewire/Tasks/Create.php`. Buka kembali file `app/Livewire/Tasks/Create.php`, lalu kita modifikasi class `Create`.

```php
<?php

namespace App\Livewire\Tasks;

use App\Models\Task;
use Livewire\Component;
use Illuminate\View\View;
use Livewire\Attributes\Validate;

class Create extends Component
{
    #[Validate('required|string|min:3')]
    public string $title = '';

    #[Validate('required|string|min:3')]
    public string $description = '';

    public function save(): void
    {
        $data = $this->validate();

        Task::create($data);

        $this->redirectRoute('tasks.index');
    }

    public function render(): View
    {
        return view('livewire.tasks.create');
    }

}

```

Selanjutnya kita buka file view `resources/views/livewire/tasks/create.blade.php`, lalu kita tambahkan baris kode berikut ini.

```
<div>
    <form wire:submit="save" class="flex flex-col gap-6">
        <flux:input
            wire:model="title"
            label="{{ __('Title') }}"
            type="text"
            name="title"
            required
            autofocus
        />

        <flux:textarea
            wire:model="description"
            label="{{ __('Description') }}"
            name="description"
            required
        />

        <div>
            <flux:button variant="primary" type="submit">{{ __('Save') }}</flux:button>
        </div>
    </form>
</div>
```

Pada baris kode di atas terdapat kode `<form wire:submit="save"`. Pada form tersebut kita gunakan event `wire:submit` dari livewire untuk memanggil methode `save()` dari class `Create`.



## Step 8: Coding Fitur Update Data {#step-8-fitur-update-data}

Sekarang kita akan menambahkan fitur crud ketiga yaitu fitur update data. Fitur ini akan ditangani oleh komponen livewire `app/Livewire/Tasks/Edit.php`. Buka kembali file `app/Livewire/Tasks/Edit.php`, lalu kita sesuaikan class `Edit`.

```php
<?php

namespace App\Livewire\Tasks;

use App\Models\Task;
use Livewire\Component;
use Illuminate\View\View;
use Livewire\Attributes\Validate;

class Edit extends Component
{
    #[Validate('required|string')]
    public string $title = '';

    #[Validate('required|string')]
    public string $description = '';

    public Task $task;

    public function mount(Task $task): void
    {
        $this->task = $task;
        $this->title = $task->title;
        $this->description = $task->description;
    }

    public function save(): void
    {
        $data = $this->validate();

        $this->task->update($data);

        $this->redirectRoute('tasks.index');
    }

    public function render(): View
    {
        return view('livewire.tasks.edit');
    }
}

```

Selanjutnya buka file view `resources/views/livewire/tasks/edit.blade.php`. Pada file tersebut kita tambahkan form untuk mengedit data.

```
<div>
    <form wire:submit="save" class="flex flex-col gap-6">
        <flux:input
            wire:model="title"
            label="{{ __('Title') }}"
            type="text"
            name="title"
            required
        />

        <flux:textarea
            wire:model="description"
            label="{{ __('Description') }}"
            name="description"
            required
        />

        <div>
            <flux:button variant="primary" type="submit">{{ __('Save') }}</flux:button>
        </div>
    </form>
</div>
```

Save kembali file `resources/views/livewire/tasks/edit.blade.php`.



## Step 9: Coding Fitur Hapus Data {#step-9-coding-fitur-hapus-data}

Untuk menambahkan fitur hapus data kita akan menggunakan komponen livewire `app/Livewire/Tasks/Index.php`. Kenapa kita tidak membuat komponen livewire khusus fitur hapus data? Karena kita akan coba menggunakan salah satu event dari livewire, yaitu event `wire:click`. Untuk lebih jelasnya, kita buka kembali file view `resources/views/livewire/tasks/index.blade.php`. Pada row data, terdapat button berikut ini.

```
<flux:button variant="danger" wire:click="delete({{ $task->id }})" wire:confirm="Are you sure?" class="inline-block">Delete</flux:button>
```

Pada baris kode di atas, kita menggunakan event `wire:click` yang akan memanggil method `delete()` di class `Index` yang ada di komponen livewire `app/Livewire/Tasks/Index.php`.

Sekarang kita buka kembali file `app/Livewire/Tasks/Index.php`, lalu kita tambahkan method `delete()` yang akan menangani proses hapus data.

```php
<?php

// .. baris kode lainnya

class Index extends Component
{
    // .. baris kode lainnya
    
    public function delete(int $id): void
    {
        Task::where('id', $id)->delete();
    }
}

```

Save kembali file komponen livewire `app/Livewire/Tasks/Index.php`.



## Step 10: Uji Coba Project {#step-10-uji-coba-project}

Semua fitur crud sudah kita coding, sekarang kita coba run project kita. Untuk uji coba kali ini, kita akan gunakan `composer` untuk run project supaya kita bisa run beberapa command sekaligus.

```
composer run dev
```

Output:

```
$ composer run dev
> Composer\Config::disableProcessTimeout
> npx concurrently -c "#93c5fd,#c4b5fd,#fb7185,#fdba74" "php artisan serve" "php artisan queue:listen --tries=1" "php artisan pail --timeout=0" "npm run dev" --names=server,queue,logs,vite
[logs] 
[logs]    INFO  Tailing application logs.                        Press Ctrl+C to exit  
[logs]                                                Use -v|-vv to show more details  
[queue] 
[queue]    INFO  Processing jobs from the [default] queue.  
[queue] 
[vite] 
[vite] > dev
[vite] > vite
[vite] 
[vite] 
[vite]   VITE v6.2.0  ready in 398 ms
[vite] 
[vite]   ➜  Local:   http://localhost:5173/
[vite]   ➜  Network: use --host to expose
[server] 
[server]    INFO  Server running on [http://127.0.0.1:8000].  
[server] 
[server]   Press Ctrl+C to stop the server
[server] 
[vite] 
[vite]   LARAVEL v12.1.1  plugin v1.2.0
[vite] 
[vite]   ➜  APP_URL: http://127.0.0.1:8000

```

Selanjutnya kita akses `http://127.0.0.1:8000` di browser. 

![1 halaman awal](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-12-with-livewire-starter-kit/1-halaman-awal-project.png)

Selanjutnya kita coba akses langsung halaman untuk menampilkan data, yaitu dengan akses `http://127.0.0.1:8000/tasks` langsung di browser.

![2 redirect ke halaman login](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-12-with-livewire-starter-kit/2-redirect-ke-halaman-login.png)

Karena halaman tersebut kita proteksi menggunakan middleware `auth`, jadi kita tidak bisa akses langsung dan halaman akan dialihkan ke halaman login.

```
Route::middleware(['auth'])->group(function () { 
	// baris kode lainnya
    Route::get('tasks', \App\Livewire\Tasks\Index::class)->name('tasks.index');
    
    // baris kode lainnya
});
```

Selanjutnya kita bisa coba buat akun terlebih dahulu dengan mengakses halaman register dengan klik link `Sign up`, lalu isi form untuk membuat akun. Setelah berhasil mendaftar, halaman akan dialihkan ke halaman dashboard user dari livewire starter kit.

![3 halaman dashboard](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-12-with-livewire-starter-kit/3-halaman-dashboard.png)

Pada gambar di atas, kita bisa lihat terdapat menu `Tasks` pada sidebar menu. Klik menu `Tasks` untuk membuka halaman daftar Task.

![4 halaman daftar task](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-12-with-livewire-starter-kit/4-halaman-daftar-task.png)

Pada halaman daftar task, kita bisa melihat table dan belum ada datanya. Untuk menambahkan data, klik button `Create` untuk membuka halaman form tambah data.

![5 halaman form tambah data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-12-with-livewire-starter-kit/5-halaman-form-tambah-data.png)

Kita bisa tes validasi form dengan mengisi 2 karakter di form input `title` dan `description`.

![6 tes validasi form](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-12-with-livewire-starter-kit/6-tes-validasi-form-tambah-data.png)

Bisa kita lihat kita terdapat notifikasi error ketika kita isi form input kurang dari 3 karakter seperti yang sudah kita coding di komponen livewire `Create`.

```php
<?php

// baris kode lainnya

class Create extends Component
{
    #[Validate('required|string|min:3')]
    public string $title = '';

    #[Validate('required|string|min:3')]
    public string $description = '';


    // baris kode lainnya

}

```



Selanjutnya kita coba isi form dan pastikan isian untuk field `title` dan `description` lebih dari dua karakter. 

![7 isi form tambah data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-12-with-livewire-starter-kit/7-isi-form-tambah-data.png)

Setelah selesai isi, klik button Save untuk menambahkan data tasks. Kita bisa lihat halaman akan dialihkan ke halaman daftar tasks dan terdapat tasks baru di halaman daftar task.

![8 halaman daftar task](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-12-with-livewire-starter-kit/8-redirect-setelah-save-data.png)

Selanjutnya kita coba update data. Untuk mengupdate data, kita akses halaman form update data dengan menekan button Edit pada baris data.

![9 halaman edit task](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-12-with-livewire-starter-kit/9-halaman-form-edit-data.png)

Kita bisa lihat data tasks ditampilkan di field `title` dan `description`. Karena pada komponen livewire `app/Livewire/Tasks/Edit.php` terdapat method `mount()` yang menginisialisasi data dari instance model `Task`.

```php
<?php

// baris kode lainnya

class Edit extends Component
{
    #[Validate('required|string')]
    public string $title = '';

    #[Validate('required|string')]
    public string $description = '';

    public Task $task;

    public function mount(Task $task): void
    {
        $this->task = $task;
        $this->title = $task->title;
        $this->description = $task->description;
    }

    // baris kode lainnya
}

```

Data dari model `Task` di-assign ke properti `$title` dan `$description` yang mengisi nilai awal form edit data. 

Pada form `resources/views/livewire/tasks/edit.blade.php`, `wire:model` untuk `title` dan `description` akan menghubungkan input form ke properti kompone `$title` dan `$description`.

Selanjutnya kita bisa coba update data, lalu klik button Save untuk memperbaharui data.

![10 tes isi form edit data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-12-with-livewire-starter-kit/10-tes-edit-data.png)

Kita bisa lihat data berhasil diperbaharui pada halaman daftar task.

![11 halaman daftar task](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-12-with-livewire-starter-kit/11-redirect-setelah-update-data.png)

Selanjutnya kita uji coba fitur terakhir yaitu fitur hapus data. Untuk menghapus data, kita bisa klik button Delete.

![12 tes delete data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-12-with-livewire-starter-kit/12-tes-delete-data.png)

Setelah kita tekan kita bisa lihat popup konfirmasi hapus data. Untuk menghapus data, klik OK dan kita bisa lihat data langsung terhapus.

## Penutup {#penutup}

Pada tutorial ini, kita telah berhasil menambahkan fitur baru ke dalam project yang dibangun menggunakan Livewire Starter Kit dari Laravel 12. Kita telah mempelajari proses lengkap pengembangan fitur CRUD untuk Task Management yang terdiri dari menampilkan data, menambahkan data, mengupdate data, dan menghapus data.

Beberapa key takeaway yang bisa kita ambil dari tutorial ini:

1. **Livewire Starter Kit** menyediakan struktur dasar yang solid untuk memulai pengembangan aplikasi Laravel dengan fitur autentikasi yang sudah terintegrasi.

2. **Livewire Components** memudahkan kita dalam membangun fitur-fitur interaktif tanpa perlu menulis banyak kode JavaScript.

3. **Route Protection** dengan middleware `auth` memastikan bahwa fitur-fitur sensitif hanya bisa diakses oleh pengguna yang sudah login.

4. **Data Validation** bisa diimplementasikan dengan mudah menggunakan attribute `#[Validate]` pada property komponen Livewire.

5. **Event Handling** seperti `wire:submit`, `wire:click`, dan `wire:confirm` mempermudah kita dalam menangani interaksi pengguna.

6. **Flux Components** yang disediakan oleh Laravel 12 seperti `flux:button`, `flux:input`, dan `flux:textarea` membantu kita membangun UI yang konsisten dan modern.

7. **Pagination** bisa diimplementasikan dengan mudah menggunakan trait `WithPagination` pada komponen Livewire.

Dengan pemahaman yang kita peroleh dari tutorial ini, Anda sekarang dapat mengembangkan fitur-fitur lain pada aplikasi Laravel 12 menggunakan Livewire Starter Kit. Selamat mencoba!