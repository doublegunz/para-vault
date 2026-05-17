---
title: "Tutorial CRUD Laravel 12 with React Starter Kit"
slug: "tutorial-crud-laravel-12-with-react-starter-kit"
category: "Laravel"
date: "2025-04-15"
status: "published"
---

Pada tutorial kali ini, kita akan mengeksplorasi pengembangan aplikasi CRUD dengan menggunakan React Starter Kit di Laravel 12. Sejak dirilisnya Laravel 12 dengan tiga starter kit baru (React, Vue, dan Livewire), banyak pengembang yang merasa khawatir tentang bagaimana cara mengintegrasikan fitur-fitur baru ke dalam aplikasi mereka, terutama ketika memilih React Starter Kit. Tutorial ini hadir sebagai jawaban atas kekhawatiran tersebut, dengan memberikan panduan langkah demi langkah tentang bagaimana menambahkan fungsionalitas CRUD lengkap pada aplikasi task management. Pada tutorial sebelumnya, kita sudah mencoba menambahkan fitur CRUD dengan Livewire Starter Kit, dan kini kita akan mengimplementasikan pendekatan serupa menggunakan React Starter Kit. Dengan menyajikan kedua pendekatan ini, diharapkan pengembang dapat memilih starter kit yang paling sesuai dengan kebutuhan proyek mereka tanpa khawatir tentang kompleksitas implementasi fitur-fitur dasar.

> **Catatan**: Tutorial ini telah diuji coba kembali pada tanggal 17 April 2026 menggunakan Laravel versi 13 dan Inertia versi 3 (secara default terinstall per tanggal 17 april 2026) dan telah disesuaikan dengan versi terbaru.

## Overview{#overview}

Pada tutorial ini, kita akan membangun aplikasi manajemen task (task management) sederhana dengan fitur CRUD lengkap menggunakan Laravel 12 dan React Starter Kit. Aplikasi ini akan memungkinkan pengguna untuk:

- Melihat daftar task dengan status dan tanggal batas waktu (due date)
- Menambahkan task baru
- Mengubah detail task termasuk status penyelesaian
- Menghapus task yang tidak diperlukan

Melalui tutorial ini, kita akan mempelajari:

1. Cara menginstal dan mengkonfigurasi React Starter Kit di Laravel 12
2. Implementasi routing di Laravel untuk mendukung operasi CRUD
3. Penggunaan Inertia.js sebagai jembatan antara Laravel dan React
4. Pembuatan komponen React modular untuk UI yang interaktif
5. Penanganan form dan validasi data di sisi frontend dan backend
6. Implementasi pagination untuk menampilkan data dalam jumlah besar
7. Penggunaan TypeScript untuk type safety dalam pengembangan React
8. Integrasi UI modern dengan Tailwind CSS dan komponen custom

Dengan mengikuti tutorial ini, kita akan memiliki pemahaman yang lebih luas tentang pilihan starter kit di Laravel 12 dan cara mengembangkan aplikasi web full-stack modern menggunakan kombinasi Laravel dan React melalui React Starter Kit.



## Step 1: Setup Laravel Project {#setup-laravel-project}

Pertama kita coba buat project baru menggunakan laravel installer. Untuk membuat project baru, kita run command berikut.

```
laravel new crud-with-react-starter-kit
```

Selanjutnya kita pilih opsi `React` ketika tampil prompt untuk memilih starter kit.

```
laravel new crud-with-react-starter-kit

 ██╗       █████╗  ██████╗   █████╗  ██╗   ██╗ ███████╗ ██╗
 ██║      ██╔══██╗ ██╔══██╗ ██╔══██╗ ██║   ██║ ██╔════╝ ██║
 ██║      ███████║ ██████╔╝ ███████║ ██║   ██║ █████╗   ██║
 ██║      ██╔══██║ ██╔══██╗ ██╔══██║ ╚██╗ ██╔╝ ██╔══╝   ██║
 ███████╗ ██║  ██║ ██║  ██║ ██║  ██║  ╚████╔╝  ███████╗ ███████╗
 ╚══════╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝   ╚═══╝   ╚══════╝ ╚══════╝

 ┌ Which starter kit would you like to install? ────────────────┐
 │   ○ None                                                     │
 │ › ● React                                                    │
 │   ○ Svelte                                                   │
 │   ○ Vue                                                      │
 │   ○ Livewire                                                 │
 └──────────────────────────────────────────────────────────────┘

```

Setelah kita enter, selanjutnya kita akan memilih authentication provider. Di prompt ini kita pilih `Laravel's buit'in authenticaion`.

```
 ┌ Which authentication provider do you prefer? ────────────────┐
 │ › ● Laravel's built-in authentication                        │
 │   ○ WorkOS (Requires WorkOS account)                         │
 │   ○ No authentication scaffolding                            │
 └──────────────────────────────────────────────────────────────┘

```

Setelah memilih authentication provider, selanjutnya akan tampil prompt untuk menambahkan [teams support](https://qadrlabs.com/post/laravel-starter-kit-now-ships-with-team-support) ke aplikasi. Untuk sementara kita pilih `no`, lalu tekan `enter` untuk melanjutkan.
```
 ┌ Would you like to add teams support to your application? ────┐
 │ ○ Yes / ● No                                                 │
 └──────────────────────────────────────────────────────────────┘
```


Pada prompt berikutnya kita akan memilih testing framework. Di sini kita pilih opsi `Pest`.

```
 ┌ Which testing framework do you prefer? ──────────────────────┐
 │ › ● Pest                                                     │
 │   ○ PHPUnit                                                  │
 └──────────────────────────────────────────────────────────────┘

```

Setelah kita enter, akan tampil prompt untuk install Laravel Boost. Bagian ini opsional, karena kita sedang belajar laravel jadi boleh pilih opsi apa saja. Selanjutnya kita tunggu sampai proses setup project selesai.

Selanjutnya akan tampil kembali prompt apakah kita akan run command untuk install dependensi frontend dan build assets.

```
87 packages you are using are looking for funding.
Use the `composer fund` command to find out more!
> @php artisan vendor:publish --tag=laravel-assets --ansi --force

   INFO  No publishable resources for tag [laravel-assets].  

No security vulnerability advisories found.

 ┌ Would you like to run npm install --ignore-scripts and … ───┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘


```

Kita pilih opsi `yes`, lalu tekan enter untuk melanjutkan. Kita tunggu sampai proses install dependensi frontend dan build assets selesai.

```
   INFO  Application ready in [crud-with-react-starter-kit]. You can start your local development using:

➜ cd crud-with-react-starter-kit
➜ composer run dev


```



## Step 2: Atur Konfigurasi {#step-2-atur-konfigurasi}

Pada tahapan ini kita akan sesuaikan konfigurasi project, seperti app url dan konfigurasi database. Untuk mengatur konfigurasi, kita pindah ke direktori project.

```
cd crud-with-react-starter-kit
```

Lalu kita buka project di code editor menggunakan command berikut.

```
code .
```

> **Keterangan:** command di atas akan membuka project menggunakan visual studio code. Apabila menggunakan code editor lain, kita bisa langsung buka project dengan memilih menu **File > Open Folder**, lalu pilih direktori project.



Selanjutnya buka file `.env`, lalu kita sesuaikan app url dan juga konfigurasi database.

```
APP_URL=http://127.0.0.1:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_crud_with_react
DB_USERNAME=root
DB_PASSWORD=password
```

Save kembali file `.env`.

Selanjutnya kita run migration command.

```
php artisan migrate
```

Apabila database belum kita buat, akan tampil prompt untuk membuat database baru.

```
$ php artisan migrate

   WARN  The database 'db_crud_with_react' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘



```

Pilih opsi `yes`, lalu tekan `enter` untuk melanjutkan.

```
$ php artisan migrate

   WARN  The database 'db_crud_with_react' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ Yes                                                          │
 └──────────────────────────────────────────────────────────────┘

   INFO  Preparing database.  

  Creating migration table ...................................... 14.16ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table .......................... 48.65ms DONE
  0001_01_01_000001_create_cache_table .......................... 30.51ms DONE
  0001_01_01_000002_create_jobs_table ........................... 36.90ms DONE
  2025_08_14_170933_add_two_factor_columns_to_users_table ....... 28.58ms DONE

```



## Step 3: Define Model and Migration {#step-3-define-model-migration}

Selanjutnya kita buat file model dan migration untuk table `tasks`. Buka kembali terminal, lalu run command berikut ini untuk membuat file model dan migration.

```
php artisan make:model Task -m
```

Output yang ditampilkan.

```
$ php artisan make:model Task -m

   INFO  Model [app/Models/Task.php] created successfully.  

   INFO  Migration [database/migrations/2025_04_12_064237_create_tasks_table.php] created successfully.  


```



Sekarang buka file `app/Models/Task.php` yang sudah berhasil digenerate. Pada `Task` kita tambahkan attribute `$fillable` untuk mengijinkan mass-assignment ketika proses menambahkan data.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Task extends Model
{
    protected $fillable = ['name', 'is_completed', 'due_date'];
}

```

Setelah selesai, save kembali file model.



Selanjutnya kita buka file migration `database/migrations/xxxx_xx_xx_xxxxxx_create_tasks_table.php`, lalu kita definisikan field `id`, `name`, `is_completed`, `due_date` untuk table `tasks` pada method `up()`.

```php
    public function up(): void
    {
        Schema::create('tasks', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->boolean('is_completed')->default(false);
            $table->date('due_date')->nullable();
            $table->timestamps();
        });
    }
```

Save kembali file migration.

Setelah itu kita run kembali migration command untuk menambahkan table `tasks` pada database `db_crud_with_react`.

```
php artisan migrate
```

Ouput yang ditampilkan:

```
$ php artisan migrate

   INFO  Running migrations.  

  2025_04_12_064237_create_tasks_table ........................... 4.62ms DONE

```



## Step 4: Coding Fitur View Daftar Task {#step-4-coding-fitur-view-daftar-task}

Pada tahapan ini kita akan membuat fitur pertama yaitu menampilkan daftar task. Untuk menambahkan fitur tersebut, kita buat controller baru yang akan menangani semua operasi crud untuk mengelol task.

```
php artisan make:controller TaskController
```

Output yang ditampilkan.

```
php artisan make:controller TaskController

   INFO  Controller [app/Http/Controllers/TaskController.php] created successfully.  

```



Selanjutnya kita buka file `app/Http/Controllers/TaskController.php`. Lalu pada `TaskController` class, kita tambahkan method `index()` yang akan menangani proses untuk menampilkan halaman daftar task.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Task;
use Illuminate\Http\Request;
use Inertia\Inertia;

class TaskController extends Controller
{
    public function index()
    {
        return Inertia::render('Tasks/Index', [
            'tasks' => Task::latest()->paginate(10),
        ]);
    }
}

```



Berikut adalah penjelasan baris kode di atas.

| **Baris Kode**                                  | **Penjelasan**                                               |
| ----------------------------------------------- | ------------------------------------------------------------ |
| `<?php`                                         | Menandakan awal file PHP.                                    |
| `namespace App\Http\Controllers;`               | Menentukan namespace dari controller ini agar dapat digunakan secara terstruktur dalam aplikasi Laravel. |
| `use App\Models\Task;`                          | Mengimpor model `Task` agar bisa digunakan di dalam controller ini. |
| `use Illuminate\Http\Request;`                  | Mengimpor class `Request` dari Laravel untuk menangani HTTP request (meskipun belum digunakan dalam method ini). |
| `use Inertia\Inertia;`                          | Mengimpor facade `Inertia` untuk merender komponen frontend menggunakan Inertia.js. |
| `class TaskController extends Controller`       | Mendeklarasikan class `TaskController` yang merupakan turunan dari class `Controller` Laravel. |
| `public function index()`                       | Mendefinisikan method `index()` yang akan dijalankan saat route `/tasks` dipanggil. Biasanya digunakan untuk menampilkan daftar data. |
| `return Inertia::render('Tasks/Index', [...]);` | Merender halaman React `Tasks/Index` melalui Inertia dan mengirimkan data props ke halaman tersebut. |
| `'tasks' => Task::latest()->paginate()`         | Mengambil data dari model `Task`, mengurutkan berdasarkan waktu terbaru, dan melakukan paginasi, kemudian mengirimkannya ke view sebagai prop bernama `tasks`. |



Pada baris kode di atas  terdapat kode untuk merender halaman react.

```php
return Inertia::render('Tasks/Index', [...]);
```

`'Tasks/Index'` yang menjadi paramater pada method `Inertia::render()` merujuk ke file `resources/js/pages/Tasks/Index.tsx`. 

Jadi sekarang kita buat file baru, yaitu `resources/js/pages/Tasks/Index.tsx`. Pada file tersebut kita coding baris kode berikut ini.

```
import { Head, Link, router } from '@inertiajs/react';
import { destroy } from '@/actions/App/Http/Controllers/TaskController';
import {
  type BreadcrumbItem,
  type PaginatedResponse,
  type Task,
} from '@/types';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Button, buttonVariants } from '@/components/ui/button';
import { TablePagination } from '@/components/table-pagination';



export default function Index({ tasks }: { tasks: PaginatedResponse<Task> }) {
  const deleteTask = (id: number) => {
    if (confirm('Are you sure?')) {
      router.delete(destroy.url(id));
      // Alert sudah ditangani oleh Inertia/Laravel flash messages
    }
  };

  return (
    <>
      <Head title="Tasks List" />
      <div className="flex h-full flex-1 flex-col gap-4 rounded-xl p-4">
        <div className={'flex flex-row gap-x-4'}>
          <Link
            className={buttonVariants({ variant: 'default' })}
            href="/tasks/create"
          >
            Create Task
          </Link>
        </div>

        <Table className={'mt-4'}>
          <TableHeader>
            <TableRow>
              <TableHead>Task</TableHead>
              <TableHead className="w-[100px]">Status</TableHead>
              <TableHead className="w-[100px]">
                Due Date
              </TableHead>
              <TableHead className="w-[150px] text-right">
                Actions
              </TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {tasks.data.map((task: Task) => (
              <TableRow key={task.id}>
                <TableCell>{task.name}</TableCell>
                <TableCell
                  className={
                    task.is_completed
                      ? 'text-green-600'
                      : 'text-red-700'
                  }
                >
                  {task.is_completed
                    ? 'Completed'
                    : 'In Progress'}
                </TableCell>
                <TableCell>
                  {task.due_date
                    ? new Date(
                      task.due_date,
                    ).toLocaleDateString()
                    : ''}
                </TableCell>
                <TableCell className="flex flex-row justify-end gap-x-2">
                  <Link
                    className={buttonVariants({
                      variant: 'default',
                    })}
                    href={`/tasks/${task.id}/edit`}
                  >
                    Edit
                  </Link>
                  <Button
                    variant={'destructive'}
                    className={'cursor-pointer'}
                    onClick={() => deleteTask(task.id)}
                  >
                    Delete
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>

        <TablePagination resource={tasks} />
      </div>
    </>
  );
}

Index.layout = {
  breadcrumbs: [
    { title: 'Dashboard', href: '/dashboard' },
    { title: 'Tasks', href: '/tasks' },
  ],
};


```

Komponen `Index.tsx` ini berfungsi untuk menampilkan **daftar task** dalam bentuk **tabel interaktif** dengan fitur-fitur:

- **CRUD** (Create, Edit, Delete) melalui Inertia.
- **Status visual** berdasarkan `is_completed`.
- **Paginated data** dari backend Laravel.
- **UI yang konsisten dan modern** menggunakan Tailwind CSS dan komponen UI.

Selain itu terdapat import berikut ini.

```
import { type BreadcrumbItem, type PaginatedResponse, type Task } from '@/types';
```

Selanjutnya kita buat file baru, yaitu `resources/js/types/task.ts`. Pada file `resources/js/types/task.ts`, kita coding baris kode berikut ini.

```javascript
export interface Task {
    id: number;
    name: string;
    is_completed: boolean;
    due_date?: string;
    created_at: string;
    updated_at: string;
}

```

Save kembali file  `resources/js/types/task.ts`.

**Penjelasan Kode:**

- `Task`: untuk mewakili struktur satu entitas task dalam frontend React.



Selanjutnya kita buat file `resources/js/types/paginated-response.ts`, lalu tambahkan baris kode berikut ini.

```javascript
import { Task } from './task';

export interface PaginatedResponse<T = Task | null> {
    current_page: number;
    data: T[];
    first_page_url: string;
    from: number;
    last_page: number;
    last_page_url: string;
    links: {
        url: string | null;
        label: string;
        active: boolean;
    }[];
    next_page_url: string | null;
    path: string;
    per_page: number;
    prev_page_url: string | null;
    to: number;
    total: number;
}

```

Save kembali file `resources/js/types/paginated-response.ts`.

**Penjelasan Kode:**

- `PaginatedResponse<Task>`: digunakan untuk menyimpan dan menangani respons daftar task yang dipaginasi dari Laravel (misalnya hasil dari `Task::paginate()`), sehingga bisa digunakan langsung untuk menampilkan data dan navigasi halaman.



Setelah kita buat kedua file tersebut (`resources/js/types/task.ts` dan `resources/js/types/paginated-response.ts`), selanjutnya kita export pada file `resources/js/types/index.ts`.

```
export type * from './auth';
export type * from './navigation';
export type * from './ui';

// tambahkan baris kode berikut
export type * from './task';
export type * from './paginated-response';

```

Save kembali file `resources/js/types/index.ts`.

Sekarang kita buka kembali file `resources/js/pages/Tasks/Index.tsx`. Pada komponen `Index.tsx`, terdapat baris kode berikut. 

```
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table";
import { TablePagination } from '@/components/table-pagination';
```

Kalau teman-teman cek, di starter kita belum tersedia komponen-komponen tersebut. Jadi kita akan buat komponen-komponen pendukung untuk table, dan pagination. 

1. `resources/js/components/table-pagination.tsx`.
2. `resources/js/components/ui/pagination.tsx`
3. `resources/js/components/ui/table.tsx`
4. `resources/js/lib/generate-pagination-links.tsx`



Buka kembali code editor, lalu buat komponen baru, yaitu `resources/js/components/ui/table.tsx`.

```
import * as React from "react"

import { cn } from "@/lib/utils"

function Table({ className, ...props }: React.ComponentProps<"table">) {
    return (
        <div
            data-slot="table-container"
            className="relative w-full overflow-x-auto"
        >
            <table
                data-slot="table"
                className={cn("w-full caption-bottom text-sm", className)}
                {...props}
            />
        </div>
    )
}

function TableHeader({ className, ...props }: React.ComponentProps<"thead">) {
    return (
        <thead
            data-slot="table-header"
            className={cn("[&_tr]:border-b", className)}
            {...props}
        />
    )
}

function TableBody({ className, ...props }: React.ComponentProps<"tbody">) {
    return (
        <tbody
            data-slot="table-body"
            className={cn("[&_tr:last-child]:border-0", className)}
            {...props}
        />
    )
}

function TableFooter({ className, ...props }: React.ComponentProps<"tfoot">) {
    return (
        <tfoot
            data-slot="table-footer"
            className={cn(
                "bg-muted/50 border-t font-medium [&>tr]:last:border-b-0",
                className
            )}
            {...props}
        />
    )
}

function TableRow({ className, ...props }: React.ComponentProps<"tr">) {
    return (
        <tr
            data-slot="table-row"
            className={cn(
                "hover:bg-muted/50 data-[state=selected]:bg-muted border-b transition-colors",
                className
            )}
            {...props}
        />
    )
}

function TableHead({ className, ...props }: React.ComponentProps<"th">) {
    return (
        <th
            data-slot="table-head"
            className={cn(
                "text-muted-foreground h-10 px-2 text-left align-middle font-medium whitespace-nowrap [&:has([role=checkbox])]:pr-0 [&>[role=checkbox]]:translate-y-[2px]",
                className
            )}
            {...props}
        />
    )
}

function TableCell({ className, ...props }: React.ComponentProps<"td">) {
    return (
        <td
            data-slot="table-cell"
            className={cn(
                "p-2 align-middle whitespace-nowrap [&:has([role=checkbox])]:pr-0 [&>[role=checkbox]]:translate-y-[2px]",
                className
            )}
            {...props}
        />
    )
}

function TableCaption({
                          className,
                          ...props
                      }: React.ComponentProps<"caption">) {
    return (
        <caption
            data-slot="table-caption"
            className={cn("text-muted-foreground mt-4 text-sm", className)}
            {...props}
        />
    )
}

export {
    Table,
    TableHeader,
    TableBody,
    TableFooter,
    TableHead,
    TableRow,
    TableCell,
    TableCaption,
}

```

Save kembali file  `resources/js/components/ui/table.tsx`.

Selanjutnya kita buat komponen untuk table pagination, yaitu `resources/js/components/table-pagination.tsx`. Pada file tersebut, coding baris kode berikut ini.

```
import { Pagination, PaginationContent, PaginationItem, PaginationNext, PaginationPrevious } from '@/components/ui/pagination';
import { type PaginatedResponse } from '@/types';
import { generatePaginationLinks } from '@/lib/generate-pagination-links';

export function TablePagination({ resource }: { resource: PaginatedResponse }) {
    if (resource.last_page === 1) {
        return (
            <div className={'mt-4 text-center text-gray-500'}>
                No more items to show.
            </div>
        );
    }

    return (
        <Pagination className='mt-4'>
            <PaginationContent>
                <PaginationItem>
                    {resource.prev_page_url
                        ? <PaginationPrevious href={resource.prev_page_url} />
                        : null
                    }
                </PaginationItem>

                {generatePaginationLinks(resource.current_page, resource.last_page, resource.path)}

                <PaginationItem>
                    {resource.next_page_url
                        ? <PaginationNext href={resource.next_page_url} />
                        : null
                    }
                </PaginationItem>
            </PaginationContent>
        </Pagination>
    );
}

```

Save kembali file `resources/js/components/table-pagination.tsx`.



Selanjutnya kita buat komponen yang akan menangani proses generate pagination link, yaitu file `resources/js/lib/generate-pagination-links.tsx`. Lalu kita tambahkan kode berikut ini.

```
import { PaginationEllipsis, PaginationItem, PaginationLink } from '@/components/ui/pagination';
import { JSX } from 'react';

export const generatePaginationLinks = (currentPage: number, totalPages: number, path: string, pageQuery: string = '?page=') => {
    const pages: JSX.Element[] = [];
    if (totalPages <= 6) {
        for (let i = 1; i <= totalPages; i++) {
            pages.push(
                <PaginationItem key={i}>
                    <PaginationLink href={path + pageQuery + i} isActive={i === currentPage}>
                        {i}
                    </PaginationLink>
                </PaginationItem>,
            );
        }
    } else {
        for (let i = 1; i <= 2; i++) {
            pages.push(
                <PaginationItem key={i}>
                    <PaginationLink href={path + pageQuery + i} isActive={i === currentPage}>
                        {i}
                    </PaginationLink>
                </PaginationItem>,
            );
        }
        if (2 < currentPage && currentPage < totalPages - 1) {
            pages.push(<PaginationEllipsis />);
            pages.push(
                <PaginationItem key={currentPage}>
                    <PaginationLink href="" isActive={true}>
                        {currentPage}
                    </PaginationLink>
                </PaginationItem>,
            );
        }
        pages.push(<PaginationEllipsis />);
        for (let i = totalPages - 1; i <= totalPages; i++) {
            pages.push(
                <PaginationItem key={i}>
                    <PaginationLink href={path + pageQuery + i} isActive={i === currentPage}>
                        {i}
                    </PaginationLink>
                </PaginationItem>,
            );
        }
    }
    return pages;
};

```

Save kembali file `resources/js/lib/generate-pagination-links.tsx`. 



Selanjutnya kita buat komponen UI untuk pagination, yaitu `resources/js/components/ui/pagination.tsx`. Pada file tersebut tambahkan baris kode berikut ini.

```
import * as React from "react"
import {
    ChevronLeftIcon,
    ChevronRightIcon,
    MoreHorizontalIcon,
} from "lucide-react"

import { cn } from "@/lib/utils"
import { Button, buttonVariants } from "@/components/ui/button"

function Pagination({ className, ...props }: React.ComponentProps<"nav">) {
    return (
        <nav
            role="navigation"
            aria-label="pagination"
            data-slot="pagination"
            className={cn("mx-auto flex w-full justify-center", className)}
            {...props}
        />
    )
}

function PaginationContent({
                               className,
                               ...props
                           }: React.ComponentProps<"ul">) {
    return (
        <ul
            data-slot="pagination-content"
            className={cn("flex flex-row items-center gap-1", className)}
            {...props}
        />
    )
}

function PaginationItem({ ...props }: React.ComponentProps<"li">) {
    return <li data-slot="pagination-item" {...props} />
}

type PaginationLinkProps = {
    isActive?: boolean
} & Pick<React.ComponentProps<typeof Button>, "size"> &
    React.ComponentProps<"a">

function PaginationLink({
                            className,
                            isActive,
                            size = "icon",
                            ...props
                        }: PaginationLinkProps) {
    return (
        <a
            aria-current={isActive ? "page" : undefined}
            data-slot="pagination-link"
            data-active={isActive}
            className={cn(
                buttonVariants({
                    variant: isActive ? "outline" : "ghost",
                    size,
                }),
                className
            )}
            {...props}
        />
    )
}

function PaginationPrevious({
                                className,
                                ...props
                            }: React.ComponentProps<typeof PaginationLink>) {
    return (
        <PaginationLink
            aria-label="Go to previous page"
            size="default"
            className={cn("gap-1 px-2.5 sm:pl-2.5", className)}
            {...props}
        >
            <ChevronLeftIcon />
            <span className="hidden sm:block">Previous</span>
        </PaginationLink>
    )
}

function PaginationNext({
                            className,
                            ...props
                        }: React.ComponentProps<typeof PaginationLink>) {
    return (
        <PaginationLink
            aria-label="Go to next page"
            size="default"
            className={cn("gap-1 px-2.5 sm:pr-2.5", className)}
            {...props}
        >
            <span className="hidden sm:block">Next</span>
            <ChevronRightIcon />
        </PaginationLink>
    )
}

function PaginationEllipsis({
                                className,
                                ...props
                            }: React.ComponentProps<"span">) {
    return (
        <span
            aria-hidden
            data-slot="pagination-ellipsis"
            className={cn("flex size-9 items-center justify-center", className)}
            {...props}
        >
      <MoreHorizontalIcon className="size-4" />
      <span className="sr-only">More pages</span>
    </span>
    )
}

export {
    Pagination,
    PaginationContent,
    PaginationLink,
    PaginationItem,
    PaginationPrevious,
    PaginationNext,
    PaginationEllipsis,
}

```

Save kembali file `resources/js/components/ui/pagination.tsx`.

Pada tahapan ini kita sudah menambahkan komponen tambahan.

```
resources/js/components/table-pagination.tsx
resources/js/components/ui/pagination.tsx
resources/js/components/ui/table.tsx
resources/js/lib/generate-pagination-links.tsx

```



Setelah kita tambahkan komponen untuk menampilkan daftar Task, selanjutnya kita tambahkan juga menu navigasi untuk mengakses halaman daftar task pada komponen sidebar pada React Starter Kit.  Untuk menambahkan menu navigasi, buka file `resources/js/components/app-sidebar.tsx`.  Pada file tersebut temukan baris kode berikut ini.

```
const mainNavItems: NavItem[] = [
    {
        title: 'Dashboard',
        href: '/dashboard',
        icon: LayoutGrid,
    },
];
```

Lalu kita tambahkan menu navigasi untuk mengakses halaman daftar tasks.

```
const mainNavItems: NavItem[] = [
    {
        title: 'Dashboard',
        href: '/dashboard',
        icon: LayoutGrid,
    },{
        title: 'Tasks',
        href: '/tasks',
        icon: LayoutGrid,
    },
];
```



Langkah terakhir untuk membuat fitur view daftar task adalah mendefinisikan route yang menangani semua operasi crud task. Sekarang kita buka file `routes/web.php`, lalu kita definisikan route baru.

```php
Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('dashboard', function () {
        return Inertia::render('dashboard');
    })->name('dashboard');

    // definisikan route untuk task
    Route::resource('tasks', \App\Http\Controllers\TaskController::class);
});
```

Save kembali file `routes/web.php`.

Setelah kita definisikan route, fitur view daftar task sudah kita selesaikan. Selanjutnya kita lanjutkan coding untuk fitur create data baru.



## Step 5: Coding Fitur Create Data {#step-5-coding-fitur-create-data}

Untuk menambahkan fitur create data, kita akan tambahkan method `create()` dan `store()` di controller kita. Buka kembali file `app/Http/Controllers/TaskController.php`, lalu kita tambahkan method `create()` yang menangani proses menampilkan halaman form tambah data dan method `store()` yang menangani proses menambahkan data task baru ke database.

```php
public function create()
{
    return Inertia::render('Tasks/Create');
}

public function store(Request $request)
{
    $request->validate([
        'name' => 'required',
        'due_date' => 'nullable|date',
    ]);

    $task = Task::create([
        'name' => $request->name,
        'due_date' => $request->due_date,
        'is_completed' => false,
    ]);

    return redirect()->route('tasks.index');
}
```

Apabila kita sudah selesai coding, save kembali file `app/Http/Controllers/TaskController.php`.

Pada baris kode di atas, di method `create()` kita gunakan inertia untuk menampilkan halaman form tambah data. Sekarang kita buat file baru untuk halaman form tersebut, yaitu `resources/js/pages/Tasks/Create.tsx`.

```javascript
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

import { Head, useForm } from '@inertiajs/react';
import { FormEventHandler, useRef } from 'react';
import { type BreadcrumbItem } from '@/types';
import { Card, CardContent, CardFooter } from '@/components/ui/card';
import { store } from '@/actions/App/Http/Controllers/TaskController';

type CreateTaskForm = {
  name: string;
  due_date?: string;
};



export default function Create() {
  const taskName = useRef<HTMLInputElement>(null);

  const { data, setData, errors, post, reset, processing } =
    useForm<CreateTaskForm>({
      name: '',
      due_date: '',
    });

  const createTask: FormEventHandler = (e) => {
    e.preventDefault();

    post(store.url(), {
      preserveScroll: true,
      onSuccess: () => {
        reset();
      },
      onError: (errors) => {
        if (errors.name) {
          reset('name');
          taskName.current?.focus();
        }
      },
    });
  };

  return (
    <>
      <Head title="Create Task" />
      <div className="flex h-full flex-1 flex-col gap-4 rounded-xl p-4">
        <form onSubmit={createTask} className="space-y-6">
          <Card>
            <CardContent className="space-y-6 pt-6">
              <div className="grid gap-2">
                <Label htmlFor="name">Task Name *</Label>

                <Input
                  id="name"
                  ref={taskName}
                  value={data.name}
                  onChange={(e) =>
                    setData('name', e.target.value)
                  }
                  className="mt-1 block w-full"
                />

                <InputError message={errors.name} />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="due_date">Due Date</Label>

                <Input
                  id="due_date"
                  value={data.due_date}
                  onChange={(e) =>
                    setData('due_date', e.target.value)
                  }
                  className="mt-1 block w-full"
                  type="date"
                />

                <InputError message={errors.due_date} />
              </div>
            </CardContent>

            <CardFooter>
              <Button disabled={processing}>Create Task</Button>
            </CardFooter>
          </Card>
        </form>
      </div>
    </>
  );
}

Create.layout = {
  breadcrumbs: [
    { title: 'Dashboard', href: '/dashboard' },
    { title: 'Tasks', href: '/tasks' },
    { title: 'Create', href: '/tasks/create' },
  ],
};

```

Save kembali file `resources/js/pages/Tasks/Create.tsx`. Pada baris kode di atas, kita menggunakan component react yang sudah tersedia pada React Starter Kit. Jadi kita tidak perlu menambahkan komponen baru.



## Step 6: Coding Fitur Update Data{#step-6-coding-fitur-update-data}

Selanjutnya kita akan tambahkan fitur untuk memperbaharui data. Buka kembali file `app/Http/Controllers/TaskController.php`, lalu kita tambahkan method `edit()` yang akan menampilkan form update data dan method `update()` yang menangani proses update data.

```
public function edit(Task $task)
{
    return Inertia::render('Tasks/Edit', [
        'task' => $task,
    ]);
}

public function update(Request $request, Task $task)
{
    $request->validate([
        'name' => 'required',
        'due_date' => 'nullable|date',
        'is_completed' => 'nullable|boolean',
    ]);

    $task->update([
        'name' => $request->name,
        'due_date' => $request->due_date,
        'is_completed' => $request->is_completed,
    ]);

    return redirect()->route('tasks.index');
}
```

Selanjutnya kita buat komponen react baru untuk menampilkan form update data, yaitu `resources/js/pages/Tasks/Edit.tsx`.

```
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

import { type BreadcrumbItem, type Task } from '@/types';
import { Head, router, useForm } from '@inertiajs/react';
import { FormEventHandler, useRef } from 'react';
import { Card, CardContent, CardFooter } from '@/components/ui/card';
import { update } from '@/actions/App/Http/Controllers/TaskController';

type EditTaskForm = {
  name: string;
  is_completed: boolean;
  due_date?: string;
};



export default function Edit({ task }: { task: Task }) {
  const taskName = useRef<HTMLInputElement>(null);

  const { data, setData, errors, reset, processing } = useForm<EditTaskForm>({
    name: task.name,
    is_completed: task.is_completed,
    due_date: task.due_date,
  });

  const editTask: FormEventHandler = (e) => {
    e.preventDefault();

    router.post(
      update.url(task.id),
      { ...data, _method: 'PUT' },
      {
        preserveScroll: true,
        onSuccess: () => {
          reset();
        },
        onError: (errors) => {
          if (errors.name) {
            reset('name');
            taskName.current?.focus();
          }
        },
      },
    );
  };

  return (
    <>
      <Head title="Edit Task" />
      <div className="flex h-full flex-1 flex-col gap-4 rounded-xl p-4">
        <form onSubmit={editTask} className="space-y-6">
          <Card>
            <CardContent className="space-y-6 pt-6">
              <div className="grid gap-2">
                <Label htmlFor="name">Task Name</Label>

                <Input
                  id="name"
                  ref={taskName}
                  value={data.name}
                  onChange={(e) =>
                    setData('name', e.target.value)
                  }
                  className="mt-1 block w-full"
                />

                <InputError message={errors.name} />
              </div>

              <div className="grid gap-2">
                <Label
                  htmlFor="is_completed"
                  className="flex items-center gap-2"
                >
                  <Checkbox
                    id="is_completed"
                    checked={data.is_completed}
                    onCheckedChange={(checked) =>
                      setData(
                        'is_completed',
                        checked === true,
                      )
                    }
                  />
                  Completed?
                </Label>

                <InputError message={errors.is_completed} />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="due_date">Due Date</Label>

                <Input
                  id="due_date"
                  value={data.due_date || ''}
                  onChange={(e) =>
                    setData('due_date', e.target.value)
                  }
                  className="mt-1 block w-full"
                  type="date"
                />

                <InputError message={errors.due_date} />
              </div>
            </CardContent>

            <CardFooter>
              <Button disabled={processing}>Update Task</Button>
            </CardFooter>
          </Card>
        </form>
      </div>
    </>
  );
}

Edit.layout = {
  breadcrumbs: [
    { title: 'Dashboard', href: '/dashboard' },
    { title: 'Tasks', href: '/tasks' },
    { title: 'Edit', href: '' },
  ],
};

```

Save kembali file `resources/js/pages/Tasks/Edit.tsx`.



## Step 7: Coding Fitur Delete Data {#step-7-coding-fitur-delete-data}

Sekarang kita akan coding fitur terakhir di project ini yaitu fitur untuk menghapus data. Buka kembali file `app/Http/Controllers/TaskController.php`, lalu kita tambahkan method `destroy()` yang akan menangani proses menghapus data.

```
public function destroy(Task $task)
{
    $task->delete();

    return redirect()->route('tasks.index');
}
```

Save kembali file controller.

Pada tahapan ini kita sudah menyelesaikan semua fitur untuk project kita.

## Step 8: Uji Coba Project {#step-8-uji-coba-project}

Setelah kita menyelesaikan semua fitur CRUD untuk aplikasi task management kita, saatnya untuk menguji coba project secara keseluruhan. Mari kita pastikan semua komponen bekerja dengan baik.

Pertama, jalankan project dengan command:

```
composer run dev
```

Command ini akan menjalankan Laravel, queue listener, dan Vite development server secara bersamaan. kita akan melihat output yang mirip dengan berikut:

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
[vite]   VITE v6.2.0  ready in 406 ms
[vite] 
[vite]   ➜  Local:   http://localhost:5173/
[vite]   ➜  Network: use --host to expose
[server] 
[server]    INFO  Server running on [http://127.0.0.1:8000].  
[server] 
[server]   Press Ctrl+C to stop the server
[server] 
[vite] 
[vite]   LARAVEL v12.8.1  plugin v1.2.0
[vite] 
[vite]   ➜  APP_URL: http://127.0.0.1:8000
```

Sekarang, buka browser dan akses URL http://127.0.0.1:8000. kita perlu melakukan registrasi terlebih dahulu jika belum memiliki akun. Setelah login, kita akan diarahkan ke dashboard.

### Tahapan Pengujian

#### 1. Akses Halaman Tasks

- Klik menu "Tasks" pada sidebar di sebelah kiri
- kita akan melihat halaman daftar task yang saat ini masih kosong
- Perhatikan bahwa halaman ini sudah dilengkapi dengan tabel dan sistem pagination

#### 2. Tambah Task Baru

- Klik tombol "Create Task" di bagian atas halaman
- kita akan diarahkan ke form pembuatan task baru
- Isi field "Task Name" dengan nama task, misalnya "Belajar Laravel 12"
- Opsional: pilih tanggal pada field "Due Date"
- Klik tombol "Create Task"
- kita akan diarahkan kembali ke halaman daftar task dan melihat task baru yang sudah dibuat

#### 3. Edit Task

- Pada halaman daftar task, klik tombol "Edit" pada baris task yang ingin diubah
- Form edit task akan ditampilkan dengan data yang sudah ada
- Ubah nama task atau tanggal due date
- Centang checkbox "Completed?" jika task sudah selesai
- Klik tombol "Update Task"
- kita akan diarahkan kembali ke halaman daftar task dan melihat perubahan yang sudah dibuat
- Perhatikan bahwa status task yang sudah selesai akan ditampilkan dengan teks "Completed" berwarna hijau

#### 4. Hapus Task

- Pada halaman daftar task, klik tombol "Delete" pada baris task yang ingin dihapus
- Konfirmasi dialog akan muncul, klik "OK" untuk melanjutkan
- Task akan dihapus dan tidak lagi muncul pada daftar

#### 5. Coba Fitur Pagination

- Tambahkan beberapa task baru hingga jumlahnya lebih dari 15 task
- Perhatikan bahwa sistem pagination akan otomatis aktif
- Uji navigasi antar halaman menggunakan tombol pagination di bagian bawah tabel

### Verifikasi Responsivitas

Coba akses aplikasi dari perangkat dengan ukuran layar berbeda atau gunakan DevTools browser untuk mensimulasikan berbagai ukuran layar. Pastikan tampilan aplikasi tetap baik di berbagai ukuran layar.

### Verifikasi Validasi

- Coba kirim form dengan field nama task yang kosong
- Pastikan validasi berjalan dengan baik dan pesan error ditampilkan
- Coba masukkan format tanggal yang salah dan pastikan validasi berfungsi

Dengan menyelesaikan semua tahapan pengujian di atas, kita telah memastikan bahwa aplikasi CRUD task management yang kita bangun dengan Laravel 12 dan React Starter Kit berfungsi dengan baik. Aplikasi ini dapat dijadikan sebagai dasar untuk pengembangan aplikasi yang lebih kompleks di masa mendatang.



## Kesimpulan {#kesimpulan}

Melalui tutorial ini, kita telah membuktikan bahwa kekhawatiran seputar implementasi fitur pada React Starter Kit di Laravel 12 sebenarnya tidak beralasan. Dengan panduan yang tepat, menambahkan fitur CRUD lengkap pada aplikasi berbasis React Starter Kit dapat dilakukan dengan sistematis dan efisien. Tutorial ini menunjukkan bagaimana kita dapat memanfaatkan kekuatan Laravel pada backend dan React pada frontend, dengan Inertia.js sebagai jembatan yang menghubungkan keduanya tanpa perlu membuat API terpisah.

Dengan pemahaman yang didapat dari tutorial ini, pengembang dapat lebih percaya diri dalam mengadopsi React Starter Kit untuk proyek-proyek Laravel 12 mereka. Starter kit ini menawarkan fleksibilitas tinggi dengan state management yang powerful, cocok untuk aplikasi yang kompleks dan skalabel. Dibandingkan dengan Livewire yang mungkin lebih sederhana untuk aplikasi yang tidak terlalu kompleks, React memberikan kontrol lebih besar terhadap pengalaman pengguna dan interaktivitas frontend.

Kami berharap tutorial ini dapat menjawab kekhawatiran yang muncul saat Laravel 12 merilis starter kit baru, dan dapat menjadi referensi ketika Anda perlu menambahkan fitur-fitur baru pada aplikasi berbasis React Starter Kit. Dengan semakin banyaknya pilihan teknologi yang tersedia di ekosistem Laravel, pengembang dapat memilih solusi yang paling sesuai dengan kebutuhan proyek dan preferensi tim mereka.

Selamat mengembangkan aplikasi Laravel dengan React Starter Kit, dan semoga tutorial ini membantu Anda membuat transisi yang lancar ke teknologi baru ini!