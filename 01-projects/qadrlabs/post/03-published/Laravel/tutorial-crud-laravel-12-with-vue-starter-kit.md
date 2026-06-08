---
title: "Tutorial CRUD Laravel 12 with Vue Starter Kit"
slug: "tutorial-crud-laravel-12-with-vue-starter-kit"
category: "Laravel"
date: "2025-04-20"
status: "published"
---

Tutorial ini adalah tutorial terakhir dalam seri contoh penambahan fitur di Laravel 12 Starter Kit. Setelah membahas cara menambahkan fitur baru di Livewire dan React Starter Kit pada dua tutorial sebelumnya, kali ini kita akan mengeksplorasi cara menambahkan fitur lengkap dengan operasi CRUD di Vue Starter Kit. Mari kita mulai!

> **Catatan**: Tutorial ini telah diuji coba kembali pada tanggal 17 April 2026 menggunakan Laravel versi 13 dan Inertia versi 3 (secara default terinstall per tanggal 17 april 2026) dan telah disesuaikan dengan versi terbaru.

## Overview{#overview}

Pada tutorial CRUD with Vue Starter Kit ini, kita akan mengembangkan fitur dengan operasi CRUD lengkap pada project Laravel yang menggunakan Vue Stack sebagai starter kit-nya. Seperti pada tutorial CRUD sebelumnya, kita akan kembali membangun aplikasi Task Management sederhana untuk konsistensi dan perbandingan antar stack.

Seperti yang telah kita bahas pada artikel [Laravel 12 Starter Kit](https://qadrlabs.com/post/laravel-12-starter-kit#vue-starter-kit), Vue Starter Kit menyediakan starting point yang sempurna untuk membangun aplikasi Laravel dengan frontend Vue dan Inertia. Dengan memanfaatkan Inertia, kita bisa mengembangkan single-page Vue application sambil tetap menggunakan server-side routing dan controller Laravel yang sudah familiar. Pendekatan ini memberikan pengalaman pengembangan yang menyenangkan dengan kelebihan dari kedua dunia.

Project Task Management yang akan kita bangun akan memungkinkan pengguna untuk:

1. Melihat daftar task dengan status dan tanggal batas waktu
2. Menambahkan task baru
3. Mengubah detail task
4. Menghapus task

Dalam tutorial ini, kita akan membahas langkah-langkah implementasi secara bertahap. Selain aspek backend Laravel, kita akan membuat beberapa komponen Vue yang meningkatkan user experience, termasuk komponen untuk tabel, pagination, popover, dan kalender. Pendekatan komponen ini memungkinkan kita membangun interface yang modular dan reusable untuk pengelolaan task.

## Step 1: Setup Laravel Project {#step-1-setup-laravel-project}

Seperti biasa langkah pertama kita adalah membuat project baru menggunakan laravel installer. Buka terminal lalu run command berikut ini untuk membuat project baru.

```
laravel new crud-with-vue-starter-kit
```

Pada prompt yang ditampilkan ketika run command di atas, kita pilih `vue` sebagai starter kit yang akan kita install.

```
$ laravel new crud-with-vue-starter-kit

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
 │ › ● Vue                                                      │
 │   ○ Livewire                                                 │
 └──────────────────────────────────────────────────────────────┘


```

Selanjutnya kita pilih `Laravel's built-in authentication` sebagai authentication provider.

```
 ┌ Which authentication provider do you prefer? ────────────────┐
 │ › ● Laravel's built-in authentication                        │
 │   ○ WorkOS (Requires WorkOS account)                         │
 │   ○ No authentication scaffolding                            │
 └──────────────────────────────────────────────────────────────┘


```

Selanjutnya akan tampil prompt baru untuk menambahkan [team support](https://qadrlabs.com/post/laravel-starter-kit-now-ships-with-team-support) pada aplikasi. Kita pilih `no`, lalu tekan `enter` untuk melanjutkan.
```

 ┌ Would you like to add teams support to your application? ────┐
 │ ○ Yes / ● No                                                 │
 └──────────────────────────────────────────────────────────────┘
 ```

Lalu pilih `Pest` untuk testing framework.

```
 ┌ Which testing framework do you prefer? ──────────────────────┐
 │ › ● Pest                                                     │
 │   ○ PHPUnit                                                  │
 └──────────────────────────────────────────────────────────────┘


```

Selanjutnya tampil prompt untuk install Laravel Boost, pilih `yes`, lalu tekan enter untuk melanjutkan.

```
 ┌ Do you want to install Laravel Boost to improve AI assisted coding? ┐
 │ ● Yes / ○ No                                                        │
 └─────────────────────────────────────────────────────────────────────┘

```

Kita tunggu sampai proses buat project selesai. Setelah proses selesai, tampil kembali prompt untuk install dependensi dan build asset frontend.

```
No security vulnerability advisories found.


 ┌ Would you like to run npm install --ignore-scripts and <… ───┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘


```

Kita pilih opsi `yes`, lalu tunggu sampai semua proses selesai.

```
✓ built in 4.57s
   INFO  Application ready in [crud-with-vue-starter-kit]. You can start your local development using:

➜ cd crud-with-vue-starter-kit
➜ composer run dev

```



## Step 2: Setup Konfigurasi {#step-2-setup-konfigurasi}

Setelah proses setup project selesai, selanjutnya kita setup konfigurasi app url dan database untuk project kita. Untuk proses setup konfigurasi, kita buka kembali terminal, lalu kita pindah direktori terlebih dahulu.

```
cd crud-with-vue-starter-kit
```

Selanjutnya kita buka direktori project di code editor menggunakan command berikut ini.

```
code .
```

Setelah direktori project terbuka di code editor, buka file `.env` lalu sesuaikan konfigurasi seperti berikut ini.

```
APP_URL=http://127.0.0.1:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_crud_with_vue
DB_USERNAME=root
DB_PASSWORD=password
```

Save kembali file `.env`.

Selanjutnya buka kembali terminal, lalu run command berikut ini untuk memulai proses migrate.

```
php artisan migrate
```

Pada output di terminal akan tampil prompt berikut apabila database belum kita buat.

```
$ php artisan migrate

   WARN  The database 'db_crud_with_vue' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘


```

Pilih `yes` untuk melanjutkan.



Output:

```
   WARN  The database 'db_crud_with_vue' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ Yes                                                          │
 └──────────────────────────────────────────────────────────────┘

   INFO  Preparing database.  

  Creating migration table ...................................... 18.36ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table .......................... 86.17ms DONE
  0001_01_01_000001_create_cache_table .......................... 32.82ms DONE
  0001_01_01_000002_create_jobs_table ........................... 71.41ms DONE


```



## Step 3: Definisikan Model dan Migration{#step-3-definisikan-model-dan-migration}

Setup konfigurasi database sudah selesai, sekarang kita akan definisikan model dan migration untuk fitur Task management. Kita buat terlebih dahulu model dan migration untuk table `tasks` menggunakan command berikut.

```
php artisan make:model Task -m
```

Ouput yang ditampilkan.

```
   INFO  Model [app/Models/Task.php] created successfully.  

   INFO  Migration [database/migrations/2025_04_18_022741_create_tasks_table.php] created successfully.  
```

Selanjutnya buka file `app/Models/Task.php`, lalu kita tambahkan attribut `$fillable` untuk mengijinkan mass-assigment ke table `tasks`.

```
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Task extends Model
{
    protected $fillable = ['name', 'is_completed', 'due_date'];
}

```

Setelah kita tambahkan save kembali file model.



Selanjutnya kita definisikan field untuk table `tasks`. Buka file `database/migrations/20xx_xx_xx_xxxxx_create_tasks_table.php`, lalu kita modifikasi method `up()`.

```
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

Sama seperti di tutorial sebelumnya, kita tambahkan field `name`, `is_completed` dan `due_date` untuk table `tasks`. Setelah selesai, save kembali file migration.

Sekarang kita run kembali `migrate` command untuk menambahkan table `tasks`.

```
php artisan migrate
```



## Step 4: Coding Fitur View Daftar Task{#step-4-coding-fitur-view-daftar-task}

Setelah setup project selesai, sekarang kita akan mulai masuk ke proses coding fitur yang pertama, yaitu fitur view daftar task. Pada step ini kita akan membuat controller baru yang akan menangani proses menampilkan halaman daftar task dan juga komponen vue dari sisi frontend.

Sekarang kita buat controller terlebih dahulu. Untuk membuat controller, buka terminal dan run command berikut ini.

```
php artisan make:controller TaskController
```

Output:

```
$ php artisan make:controller TaskController

   INFO  Controller [app/Http/Controllers/TaskController.php] created successfully.  


```

Selanjutnya buka file `app/Http/Controllers/TaskController.php`, lalu kita tambahkan method `index()` untuk menampilkan daftar task.

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
        return Inertia::render('Tasks/Index',[
            'tasks' => Task::latest()->paginate(10),
        ]);
    }
}

```

Jangan lupa, di sini kita gunakan statement use:

```php
use App\Models\Task;
use Inertia\Inertia;
```

Pada baris kode di atas, kita hubungkan backend dengan frontend (Vue.js) menggunakan Inertia. Pada function `Inertia::render()`, kita render komponen `Tasks/Index` yang merujuk ke file  `resources/js/pages/Tasks/Index.vue`. 



Jadi sekarang kita buat file baru `resources/js/pages/Tasks/Index.vue`. Pada file tersebut kita coding baris kode berikut ini.
```
<script setup lang="ts">
import { Button, buttonVariants } from '@/components/ui/button';
import { Table, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { type PaginatedResponse, type Task } from '@/types';
import { Head, Link, router } from '@inertiajs/vue3';
import { destroy } from '@/actions/App/Http/Controllers/TaskController';
import Pagination from '@/components/Pagination.vue';
import { DateFormatter } from '@internationalized/date';

defineOptions({
    layout: {
        breadcrumbs: [
            { title: 'Dashboard', href: '/dashboard' },
            { title: 'Tasks', href: '/tasks' },
        ],
    },
});

const df = new DateFormatter('en-US', { dateStyle: 'long' });

interface Props {
    tasks: PaginatedResponse<Task>;
}

const props = defineProps<Props>();

const deleteTask = (id: number) => {
    if (confirm('Are you sure you want to delete this task?')) {
        router.delete(destroy(id));
    }
};
</script>

<template>
    <Head title="Tasks" />
    <div class="flex h-full flex-1 flex-col gap-4 p-4">
        <div class="flex items-center justify-between">
            <Link :class="buttonVariants({ variant: 'default' })" href="/tasks/create">Create Task</Link>
        </div>

        <div class="rounded-md border">
            <Table>
                <TableHeader>
                    <TableRow>
                        <TableHead>Task</TableHead>
                        <TableHead class="w-[200px]">Status</TableHead>
                        <TableHead class="w-[200px]">Due Date</TableHead>
                        <TableHead class="w-[200px] text-right">Actions</TableHead>
                    </TableRow>
                </TableHeader>

                <TableRow v-for="task in tasks.data" :key="task.id">
                    <TableCell>{{ task.name }}</TableCell>
                    <TableCell :class="{ 'text-green-600': task.is_completed, 'text-red-700': !task.is_completed }">
                        {{ task.is_completed ? 'Completed' : 'In Progress' }}
                    </TableCell>
                    <TableCell>{{ task.due_date ? df.format(new Date(task.due_date)) : '' }}</TableCell>
                    <TableCell class="flex gap-x-2 justify-end">
                        <Link :class="buttonVariants({ variant: 'outline', size: 'sm' })" :href="`/tasks/${task.id}/edit`">Edit</Link>
                        <Button variant="destructive" size="sm" @click="deleteTask(task.id)">Delete</Button>
                    </TableCell>
                </TableRow>
            </Table>
        </div>

        <Pagination :resource="tasks" />
    </div>
</template>

```
Save kembali file `resources/js/pages/Tasks/Index.vue`.

Pada baris kode di atas terdapat kode untuk import komponen dan tipe

```
import { type PaginatedResponse, type Task } from '@/types';
```

Selanjutnya kita buat file baru `resources/js/types/task.ts`, lalu kita coding baris kode berikut ini.
```
export interface Task {
    id: number;
    name: string;
    is_completed: boolean;
    due_date?: string | null;
    created_at: string;
    updated_at: string;
}

```
Save kembali file `resources/js/types/task.ts`.

Setelah itu kita buat file `resources/js/types/paginated-response.ts`, lalu kita coding baris kode berikut ini.
```

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

Apabila selesai, save kembali file `resources/js/types/paginated-response.ts`.

Setelah kita buat kedua file tersebut (file `resources/js/types/task.ts` dan `resources/js/types/paginated-response.ts`), selanjutnya kita export pada file `resources/js/types/index.ts`.
```
export * from './auth';
export * from './navigation';
export * from './ui';

// tambahkan baris kode berikut
export type * from './task';
export type * from './paginated-response';

```


Selain type ada komponen pendukung lainnya yang kita import untuk menampilkan daftar Task. Jadi selain membuat komponen `Tasks/Index` kita juga akan membuat komponen untuk table dan pagination. 

Dan untuk table kita buat komponen berikut:

```
index.ts          TableCell.vue    TableHeader.vue  Table.vue
TableBody.vue     TableEmpty.vue   TableHead.vue   
TableCaption.vue  TableFooter.vue  TableRow.vue

```

Untuk pagination kita buat komponen berikut ini.
```
index.ts                PaginationFirst.vue  PaginationNext.vue
PaginationContent.vue   PaginationItem.vue   PaginationPrevious.vue
PaginationEllipsis.vue  PaginationLast.vue   Pagination.vue
```


Sekarang kita buat komponen untuk table terlebih dahulu.

Buka kembali code editor, lalu buat `resources/js/components/ui/table/index.ts` yang berfungsi sebagai central export point untuk komponen-komponen table. Pada file tersebut kita tambahkan baris kode berikut ini.

```
export { default as Table } from './Table.vue'
export { default as TableBody } from './TableBody.vue'
export { default as TableCaption } from './TableCaption.vue'
export { default as TableCell } from './TableCell.vue'
export { default as TableEmpty } from './TableEmpty.vue'
export { default as TableFooter } from './TableFooter.vue'
export { default as TableHead } from './TableHead.vue'
export { default as TableHeader } from './TableHeader.vue'
export { default as TableRow } from './TableRow.vue'

```

Save kembali  `resources/js/components/ui/table/index.ts`.

Selanjutnya buat file `resources/js/components/ui/table/Table.vue` dan tambahkan kode berikut ini.

```
<script setup lang="ts">
import type { HTMLAttributes } from 'vue'
import { cn } from '@/lib/utils'

const props = defineProps<{
  class?: HTMLAttributes['class']
}>()
</script>

<template>
  <div data-slot="table-container" class="relative w-full overflow-auto">
    <table data-slot="table" :class="cn('w-full caption-bottom text-sm', props.class)">
      <slot />
    </table>
  </div>
</template>

```

Save kembali file `resources/js/components/ui/table/Table.vue`.



Setelah itu buat file `resources/js/components/ui/table/TableBody.vue` yang berfungsi sebagai komponen utama pembungkus table. Pada file tersebut kita tambahkan baris kode berikut ini.

```
<script setup lang="ts">
import type { HTMLAttributes } from 'vue'
import { cn } from '@/lib/utils'

const props = defineProps<{
  class?: HTMLAttributes['class']
}>()
</script>

<template>
  <tbody
    data-slot="table-body"
    :class="cn('[&_tr:last-child]:border-0', props.class)"
  >
    <slot />
  </tbody>
</template>

```

Save kembali file  `resources/js/components/ui/table/TableBody.vue`.

Selanjutnya buat file `resources/js/components/ui/table/TableCaption.vue` sebagai komponen untuk menampilkan caption atau keterangan untuk table. Pada file tersebut kita tambahkan baris kode berikut ini. 

```
<script setup lang="ts">
import type { HTMLAttributes } from 'vue'
import { cn } from '@/lib/utils'

const props = defineProps<{
  class?: HTMLAttributes['class']
}>()
</script>

<template>
  <caption
    data-slot="table-caption"
    :class="cn('text-muted-foreground mt-4 text-sm', props.class)"
  >
    <slot />
  </caption>
</template>

```

Save kembali file `resources/js/components/ui/table/TableCaption.vue`.

Setelah komponen caption, buat file untuk table cell yaitu `resources/js/components/ui/table/TableCell.vue`. Pada file tersebut coding baris kode berikut ini.

```
<script setup lang="ts">
import type { HTMLAttributes } from 'vue'
import { cn } from '@/lib/utils'

const props = defineProps<{
  class?: HTMLAttributes['class']
}>()
</script>

<template>
  <td
    data-slot="table-cell"
    :class="
      cn(
        'p-2 align-middle whitespace-nowrap [&:has([role=checkbox])]:pr-0 [&>[role=checkbox]]:translate-y-[2px]',
        props.class,
      )
    "
  >
    <slot />
  </td>
</template>

```

Save kembali `resources/js/components/ui/table/TableCell.vue`.

Selanjutnya buat file `resources/js/components/ui/table/TableEmpty.vue` untuk menangani ketika data kosong. Pada file tersebut tambahkan baris kode berikut ini.

```
<script setup lang="ts">
import { cn } from '@/lib/utils'
import { computed, type HTMLAttributes } from 'vue'
import TableCell from './TableCell.vue'
import TableRow from './TableRow.vue'

const props = withDefaults(defineProps<{
  class?: HTMLAttributes['class']
  colspan?: number
}>(), {
  colspan: 1,
})

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})
</script>

<template>
  <TableRow>
    <TableCell
      :class="
        cn(
          'p-4 whitespace-nowrap align-middle text-sm text-foreground',
          props.class,
        )
      "
      v-bind="delegatedProps"
    >
      <div class="flex items-center justify-center py-10">
        <slot />
      </div>
    </TableCell>
  </TableRow>
</template>

```



Selanjutnya buat file untuk table footer, yaitu `resources/js/components/ui/table/TableFooter.vue`.

```
<script setup lang="ts">
import type { HTMLAttributes } from 'vue'
import { cn } from '@/lib/utils'

const props = defineProps<{
  class?: HTMLAttributes['class']
}>()
</script>

<template>
  <tfoot
    data-slot="table-footer"
    :class="cn('bg-muted/50 border-t font-medium [&>tr]:last:border-b-0', props.class)"
  >
    <slot />
  </tfoot>
</template>

```

Save kembali `resources/js/components/ui/table/TableFooter.vue`.



Selanjutnya buat komponen untuk table head, yaitu `resources/js/components/ui/table/TableHead.vue`.

```
<script setup lang="ts">
import type { HTMLAttributes } from 'vue'
import { cn } from '@/lib/utils'

const props = defineProps<{
  class?: HTMLAttributes['class']
}>()
</script>

<template>
  <th
    data-slot="table-head"
    :class="cn('text-muted-foreground h-10 px-2 text-left align-middle font-medium whitespace-nowrap [&:has([role=checkbox])]:pr-0 [&>[role=checkbox]]:translate-y-[2px]', props.class)"
  >
    <slot />
  </th>
</template>

```

Save kembali file  `resources/js/components/ui/table/TableHead.vue`.



Selanjutnya buat file komponen untuk table header yaitu `resources/js/components/ui/table/TableHeader.vue`.

```
<script setup lang="ts">
import type { HTMLAttributes } from 'vue'
import { cn } from '@/lib/utils'

const props = defineProps<{
  class?: HTMLAttributes['class']
}>()
</script>

<template>
  <thead
    data-slot="table-header"
    :class="cn('[&_tr]:border-b', props.class)"
  >
    <slot />
  </thead>
</template>

```

Save kembali `resources/js/components/ui/table/TableHeader.vue`.



Selanjutnya kita buat file untuk komponen table row, yaitu `resources/js/components/ui/table/TableRow.vue`, lalu kita tambahkan baris kode berikut ini.

```
<script setup lang="ts">
import type { HTMLAttributes } from 'vue'
import { cn } from '@/lib/utils'

const props = defineProps<{
  class?: HTMLAttributes['class']
}>()
</script>

<template>
  <tr
    data-slot="table-row"
    :class="cn('hover:bg-muted/50 data-[state=selected]:bg-muted border-b transition-colors', props.class)"
  >
    <slot />
  </tr>
</template>

```

Save kembali file `resources/js/components/ui/table/TableRow.vue`.

.
.
.


Sekarang kita akan membuat komponen-komponen yang menangani UI pagination. Kita buat file pertama yang menangani semua komponen pagination agar mudah diekspor yaitu file `resources/js/components/ui/pagination/index.ts`. Pada file tersebut tambahkan baris kode berikut ini.

```
export { default as Pagination } from './Pagination.vue';
export { default as PaginationContent } from './PaginationContent.vue';
export { default as PaginationEllipsis } from './PaginationEllipsis.vue';
export { default as PaginationFirst } from './PaginationFirst.vue';
export { default as PaginationItem } from './PaginationItem.vue';
export { default as PaginationLast } from './PaginationLast.vue';
export { default as PaginationNext } from './PaginationNext.vue';
export { default as PaginationPrevious } from './PaginationPrevious.vue';
export {
    PaginationList,
    PaginationListItem
} from 'reka-ui';
```

Save kembali file `resources/js/components/ui/pagination/index.ts`.

Selanjutnya kita buat komponen untuk wrapper sistem pagination  yaitu file `resources/js/components/ui/pagination/Pagination.vue`.  Pada file tersebut kita tambahkan baris kode berikut ini.

```
<script setup lang="ts">
import type { HTMLAttributes } from 'vue'
import { cn } from '@/lib/utils'
import { reactiveOmit } from '@vueuse/core'
import { PaginationRoot, type PaginationRootEmits, type PaginationRootProps, useForwardPropsEmits } from 'reka-ui'

const props = defineProps<PaginationRootProps & {
  class?: HTMLAttributes['class']
}>()
const emits = defineEmits<PaginationRootEmits>()

const delegatedProps = reactiveOmit(props, 'class')
const forwarded = useForwardPropsEmits(delegatedProps, emits)
</script>

<template>
  <PaginationRoot
    v-slot="slotProps"
    data-slot="pagination"
    v-bind="forwarded"
    :class="cn('mx-auto flex w-full justify-center', props.class)"
  >
    <slot v-bind="slotProps" />
  </PaginationRoot>
</template>

```

Save kembali file `resources/js/components/ui/pagination/Pagination.vue`.



Selanjutnya buat komponen yang digunakan untuk mengatur layout konten pagination, yaitu file `resources/js/components/ui/pagination/PaginationContent.vue`. Pada file tersebut kita tambahkan baris kode berikut ini.

```
<script setup lang="ts">
import { cn } from '@/lib/utils'
import { PaginationList, type PaginationListProps } from 'reka-ui'
import { computed, type HTMLAttributes } from 'vue'

const props = defineProps<PaginationListProps & { class?: HTMLAttributes['class'] }>()

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})
</script>

<template>
  <PaginationList
    v-slot="slotProps"
    data-slot="pagination-content"
    v-bind="delegatedProps"
    :class="cn('flex flex-row items-center gap-1', props.class)"
  >
    <slot v-bind="slotProps" />
  </PaginationList>
</template>

```

Apabila kita selesai, save kembali `resources/js/components/ui/pagination/PaginationContent.vue`.



Setelah itu kita buat komponen penanda pemisah halaman, yaitu  `resources/js/components/ui/pagination/PaginationEllipsis.vue`, lalu kita tambahkan baris kode berikut ini

```
<script setup lang="ts">
import { cn } from '@/lib/utils'
import { MoreHorizontal } from 'lucide-vue-next'
import { PaginationEllipsis, type PaginationEllipsisProps } from 'reka-ui'
import { computed, type HTMLAttributes } from 'vue'

const props = defineProps<PaginationEllipsisProps & { class?: HTMLAttributes['class'] }>()

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})
</script>

<template>
  <PaginationEllipsis
    data-slot="pagination-ellipsis"
    v-bind="delegatedProps"
    :class="cn('flex size-9 items-center justify-center', props.class)"
  >
    <slot>
      <MoreHorizontal class="size-4" />
      <span class="sr-only">More pages</span>
    </slot>
  </PaginationEllipsis>
</template>

```

Save `resources/js/components/ui/pagination/PaginationEllipsis.vue`.



Selanjutnya kita buat komponen navigasi yang menuju halaman pertama, yaitu `resources/js/components/ui/pagination/PaginationFirst.vue`, lalu kita tambahkan baris kode berikut ini.

```
<script setup lang="ts">
import type { PaginationFirstProps } from 'reka-ui'
import type { HTMLAttributes } from 'vue'
import { cn } from '@/lib/utils'
import { buttonVariants, type ButtonVariants } from '@/components/ui/button'
import { reactiveOmit } from '@vueuse/core'
import { ChevronLeftIcon } from 'lucide-vue-next'
import { PaginationFirst, useForwardProps } from 'reka-ui'

const props = withDefaults(defineProps<PaginationFirstProps & {
  size?: ButtonVariants['size']
  class?: HTMLAttributes['class']
}>(), {
  size: 'default',
})

const delegatedProps = reactiveOmit(props, 'class', 'size')
const forwarded = useForwardProps(delegatedProps)
</script>

<template>
  <PaginationFirst
    data-slot="pagination-first"
    :class="cn(buttonVariants({ variant: 'ghost', size }), 'gap-1 px-2.5 sm:pr-2.5', props.class)"
    v-bind="forwarded"
  >
    <slot>
      <ChevronLeftIcon />
      <span class="hidden sm:block">First</span>
    </slot>
  </PaginationFirst>
</template>

```

Save kembali file `resources/js/components/ui/pagination/PaginationFirst.vue`.

Sekarang kita buat komponen untuk item paginasi yang menampilkan angka, yaitu file `resources/js/components/ui/pagination/PaginationItem.vue`. Setelah itu kita tambahkan baris kode berikut ini.

```
<script setup lang="ts">
import type { HTMLAttributes } from 'vue'
import { cn } from '@/lib/utils'
import { buttonVariants, type ButtonVariants } from '@/components/ui/button'
import { reactiveOmit } from '@vueuse/core'
import { PaginationListItem, type PaginationListItemProps } from 'reka-ui'

const props = withDefaults(defineProps<PaginationListItemProps & {
  size?: ButtonVariants['size']
  class?: HTMLAttributes['class']
  isActive?: boolean
}>(), {
  size: 'icon',
})

const delegatedProps = reactiveOmit(props, 'class', 'size', 'isActive')
</script>

<template>
  <PaginationListItem
    data-slot="pagination-item"
    v-bind="delegatedProps"
    :class="cn(
      buttonVariants({
        variant: isActive ? 'outline' : 'ghost',
        size,
      }),
      props.class)"
  >
    <slot />
  </PaginationListItem>
</template>

```

Save kembali file `resources/js/components/ui/pagination/PaginationItem.vue`.

Setelah komponen item paginasi, selanjutnya kita buat komponen untuk mengarah ke halaman terakhir, yaitu  `resources/js/components/ui/pagination/PaginationLast.vue`. Pada file tersebut, tambahkan baris kode berikut ini.

```
<script setup lang="ts">
import type { PaginationLastProps } from 'reka-ui'
import type { HTMLAttributes } from 'vue'
import { cn } from '@/lib/utils'
import { buttonVariants, type ButtonVariants } from '@/components/ui/button'
import { reactiveOmit } from '@vueuse/core'
import { ChevronRightIcon } from 'lucide-vue-next'
import { PaginationLast, useForwardProps } from 'reka-ui'

const props = withDefaults(defineProps<PaginationLastProps & {
  size?: ButtonVariants['size']
  class?: HTMLAttributes['class']
}>(), {
  size: 'default',
})

const delegatedProps = reactiveOmit(props, 'class', 'size')
const forwarded = useForwardProps(delegatedProps)
</script>

<template>
  <PaginationLast
    data-slot="pagination-last"
    :class="cn(buttonVariants({ variant: 'ghost', size }), 'gap-1 px-2.5 sm:pr-2.5', props.class)"
    v-bind="forwarded"
  >
    <slot>
      <span class="hidden sm:block">Last</span>
      <ChevronRightIcon />
    </slot>
  </PaginationLast>
</template>

```

Save kembali file  `resources/js/components/ui/pagination/PaginationLast.vue`.



Selanjutnya kita buat komponen untuk tombol next pada paginasi, yaitu file `resources/js/components/ui/pagination/PaginationNext.vue`.

```
<script setup lang="ts">
import type { PaginationNextProps } from 'reka-ui'
import type { HTMLAttributes } from 'vue'
import { cn } from '@/lib/utils'
import { buttonVariants, type ButtonVariants } from '@/components/ui/button'
import { reactiveOmit } from '@vueuse/core'
import { ChevronRightIcon } from 'lucide-vue-next'
import { PaginationNext, useForwardProps } from 'reka-ui'

const props = withDefaults(defineProps<PaginationNextProps & {
  size?: ButtonVariants['size']
  class?: HTMLAttributes['class']
}>(), {
  size: 'default',
})

const delegatedProps = reactiveOmit(props, 'class', 'size')
const forwarded = useForwardProps(delegatedProps)
</script>

<template>
  <PaginationNext
    data-slot="pagination-next"
    :class="cn(buttonVariants({ variant: 'ghost', size }), 'gap-1 px-2.5 sm:pr-2.5', props.class)"
    v-bind="forwarded"
  >
    <slot>
      <span class="hidden sm:block">Next</span>
      <ChevronRightIcon />
    </slot>
  </PaginationNext>
</template>

```

Save kembali file `resources/js/components/ui/pagination/PaginationNext.vue`.

Selanjutnya buat file komponen untuk berpindah ke halaman sebelumnya, yaitu file `resources/js/components/ui/pagination/PaginationPrevious.vue`.

```
<script setup lang="ts">
import type { PaginationPrevProps } from 'reka-ui'
import type { HTMLAttributes } from 'vue'
import { cn } from '@/lib/utils'
import { buttonVariants, type ButtonVariants } from '@/components/ui/button'
import { reactiveOmit } from '@vueuse/core'
import { ChevronLeftIcon } from 'lucide-vue-next'
import { PaginationPrev, useForwardProps } from 'reka-ui'

const props = withDefaults(defineProps<PaginationPrevProps & {
  size?: ButtonVariants['size']
  class?: HTMLAttributes['class']
}>(), {
  size: 'default',
})

const delegatedProps = reactiveOmit(props, 'class', 'size')
const forwarded = useForwardProps(delegatedProps)
</script>

<template>
  <PaginationPrev
    data-slot="pagination-previous"
    :class="cn(buttonVariants({ variant: 'ghost', size }), 'gap-1 px-2.5 sm:pr-2.5', props.class)"
    v-bind="forwarded"
  >
    <slot>
      <ChevronLeftIcon />
      <span class="hidden sm:block">Previous</span>
    </slot>
  </PaginationPrev>
</template>

```

Save kembali file `resources/js/components/ui/pagination/PaginationPrevious.vue`.



Dan komponen terakhir untuk pagination adalah file `resources/js/components/Pagination.vue`. Komponen ini adalah komponen pagination lengkap yang digunakan untuk menampilkan navigasi halaman berbasis data paginasi dari laravel inertia. Komponen ini menggabungkan logika, tampilan dan interaktivitas untuk penggunaan yang fleksibel. Sekarang kita tambahkan baris kode berikut ini pada file `resources/js/components/Pagination.vue`.

```
<script setup lang="ts">
import { Button } from '@/components/ui/button';
import {
    Pagination,
    PaginationEllipsis,
    PaginationFirst,
    PaginationLast,
    PaginationList,
    PaginationListItem,
    PaginationNext,
    PaginationPrevious,
} from '@/components/ui/pagination';
import type { PaginatedResponse } from '@/types';
import { router } from '@inertiajs/vue3';

interface Props {
    resource: PaginatedResponse;
}

const props = withDefaults(defineProps<Props>(), {
    resource: null,
});
</script>

<template>
    <Pagination
        :items-per-page="props.resource.per_page"
        :total="props.resource.total"
        :sibling-count="1"
        show-edges
        :default-page="props.resource.current_page"
        class="mx-auto"
    >
        <PaginationList v-slot="{ items }" class="flex items-center gap-1">
            <div v-if="props.resource.last_page === 1">
                <div class="mt-4 text-center text-gray-500">No more items to show.</div>
            </div>
            <div v-if="props.resource.last_page !== 1">
                <PaginationFirst v-on:click="() => router.visit(props.resource.first_page_url)" />
                <PaginationPrevious v-on:click="() => router.visit(props.resource.prev_page_url)" v-if="props.resource.prev_page_url" />

                <template v-for="(item, index) in items">
                    <PaginationListItem v-if="item.type === 'page'" :key="index" :value="item.value" as-child>
                        <Button
                            class="h-10 w-10 p-0"
                            :variant="item.value === props.resource.current_page ? 'default' : 'outline'"
                            v-on:click="() => router.visit(props.resource.links.find((link) => link.label == item.value).url)"
                        >
                            {{ item.value }}
                        </Button>
                    </PaginationListItem>
                    <PaginationEllipsis v-else :key="item.type" :index="index" />
                </template>

                <PaginationNext v-on:click="() => router.visit(props.resource.next_page_url)" v-if="props.resource.next_page_url" />
                <PaginationLast v-on:click="() => router.visit(props.resource.last_page_url)" />
            </div>
        </PaginationList>
    </Pagination>
</template>

```

Apabila selesai, save file `resources/js/components/Pagination.vue`.

Komponen-komponen pelengkap untuk table dan pagination yang akan kita gunakan untuk menampilkan daftar tasks sudah selesai. Selanjutnya kita akan tambahkan menu pada sidebar Vue Starter kit untuk mengakses halaman tersebut. Untuk menambahkan menu buka file  `resources/js/components/AppSidebar.vue`. Pada file `resources/js/components/AppSidebar.vue` temukan baris kode berikut ini.

```
const mainNavItems: NavItem[] = [
    {
        title: 'Dashboard',
        href: '/dashboard',
        icon: LayoutGrid,
    },
];
```

Kemudian kita tambahkan menu untuk mengakses halaman daftar tasks.

```
const mainNavItems: NavItem[] = [
    {
        title: 'Dashboard',
        href: '/dashboard',
        icon: LayoutGrid,
    },
    {
        title: 'Tasks',
        href: '/tasks',
        icon: LayoutGrid,
    },
];
```

Save kembali `resources/js/components/AppSidebar.vue`. 

Pada baris kode di atas, kita tambahkan menu yang mengarah ke url `tasks`. Jadi sekarang kita akan definisikan route baru yang akan menangani semua proses operasi crud untuk tasks.

Untuk mendefinisikan route baru, buka file `routes/web.php`, lalu kita tambahkan baris kode berikut ini.

```
Route::resource('tasks', App\Http\Controllers\TaskController::class)->middleware(['auth', 'verified']);
```

Save kembali file `routes/web.php`.

Pada tahapan ini kita sudah selesai menambahkan fitur untuk menampilkan daftar tasks.



## Step 5: Coding Fitur Create New Task {#step-5-coding-fitur-create-new-task}

Pada step sebelumnya kita sudah menambahkan fiturn untuk menampilkan daftar task, selanjutnya kita akan menambahkan fitur kedua, yaitu fitur untuk menambahkan task baru. Untuk menambahkan task baru, kita buka kembali file `app/Http/Controllers/TaskController.php` dan tambahkan method `create()` untuk menampilkan halaman form untuk menambahkan task baru dan method `store()` yang menangani proses insert data baru.

```
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

Save kembali file `app/Http/Controllers/TaskController.php`.

Selanjutnya kita buat komponen untuk menangani proses menampilkan form untuk menambahkan task baru, yaitu file `resources/js/pages/Tasks/Create.vue`. Pada file `resources/js/pages/Tasks/Create.vue` kita coding baris kode berikut ini.

```
<script setup lang="ts">
import InputError from '@/components/InputError.vue';
import { Button } from '@/components/ui/button';
import { Calendar } from '@/components/ui/calendar';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { cn } from '@/lib/utils';
import { Head, useForm } from '@inertiajs/vue3';
import { store } from '@/actions/App/Http/Controllers/TaskController';
import { DateFormatter, getLocalTimeZone } from '@internationalized/date';
import { CalendarIcon } from 'lucide-vue-next';
import { Card, CardContent, CardFooter } from '@/components/ui/card';

const df = new DateFormatter('en-US', {
    dateStyle: 'long',
});

defineOptions({
    layout: {
        breadcrumbs: [
            { title: 'Dashboard', href: '/dashboard' },
            { title: 'Tasks', href: '/tasks' },
            { title: 'Create', href: '/tasks/create' },
        ],
    },
});

const form = useForm({
    name: '',
    due_date: null,
});

const submitForm = () => {
    form.transform((data) => ({
        ...data,
        due_date: data.due_date
            ? data.due_date.toDate(getLocalTimeZone()).toISOString().slice(0, 10)
            : null,
    })).post(store(), {
        preserveScroll: true,
    });
};
</script>

<template>
    <Head title="Create Task" />
    <div class="flex h-full flex-1 flex-col gap-4 p-4">
        <form class="space-y-6" @submit.prevent="submitForm">
            <Card class="py-6 border-0 shadow-none">
                <CardContent class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="grid gap-2">
                        <Label htmlFor="name">Task Name *</Label>
                        <Input id="name" v-model="form.name" class="mt-1 block w-full" />
                        <InputError :message="form.errors.name" />
                    </div>

                    <div class="grid gap-2">
                        <Label htmlFor="due_date">Due Date</Label>
                        <Popover>
                            <PopoverTrigger as-child>
                                <Button
                                    variant="outline"
                                    :class="cn('w-full justify-start text-left font-normal', !form.due_date && 'text-muted-foreground')"
                                >
                                    <CalendarIcon class="mr-2 h-4 w-4" />
                                    {{ form.due_date ? df.format(form.due_date.toDate(getLocalTimeZone())) : 'Pick a date' }}
                                </Button>
                            </PopoverTrigger>
                            <PopoverContent class="w-auto p-0">
                                <Calendar v-model="form.due_date" initial-focus />
                            </PopoverContent>
                        </Popover>
                        <InputError :message="form.errors.due_date" />
                    </div>
                </CardContent>

                <CardFooter>
                    <Button :disabled="form.processing" variant="default">Create Task</Button>
                </CardFooter>
            </Card>
        </form>
    </div>
</template>


```

Save kembali file `resources/js/pages/Tasks/Create.vue`.

Pada komponen `Tasks/Create`, terdapat kode untuk mengimpor beberapa komponen pendukung, seperti calendar dan popover.

```
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
```

Kedua komponen ini belum tersedia di Vue Starter kit, jadi kita harus tambahkan komponen tersebut.



Sekarang kita buat beberapa komponen untuk calendar, yaitu

1.  `resources/js/components/ui/calendar/index.ts`

```
export { default as Calendar } from './Calendar.vue'
export { default as CalendarCell } from './CalendarCell.vue'
export { default as CalendarCellTrigger } from './CalendarCellTrigger.vue'
export { default as CalendarGrid } from './CalendarGrid.vue'
export { default as CalendarGridBody } from './CalendarGridBody.vue'
export { default as CalendarGridHead } from './CalendarGridHead.vue'
export { default as CalendarGridRow } from './CalendarGridRow.vue'
export { default as CalendarHeadCell } from './CalendarHeadCell.vue'
export { default as CalendarHeader } from './CalendarHeader.vue'
export { default as CalendarHeading } from './CalendarHeading.vue'
export { default as CalendarNextButton } from './CalendarNextButton.vue'
export { default as CalendarPrevButton } from './CalendarPrevButton.vue'

```

2. `resources/js/components/ui/calendar/Calendar.vue`

```
<script lang="ts" setup>
import { cn } from '@/lib/utils'
import { CalendarRoot, type CalendarRootEmits, type CalendarRootProps, useForwardPropsEmits } from 'reka-ui'
import { computed, type HTMLAttributes } from 'vue'
import { CalendarCell, CalendarCellTrigger, CalendarGrid, CalendarGridBody, CalendarGridHead, CalendarGridRow, CalendarHeadCell, CalendarHeader, CalendarHeading, CalendarNextButton, CalendarPrevButton } from '.'

const props = defineProps<CalendarRootProps & { class?: HTMLAttributes['class'] }>()
const emits = defineEmits<CalendarRootEmits>()

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})

const forwarded = useForwardPropsEmits(delegatedProps, emits)
</script>

<template>
  <CalendarRoot
    v-slot="{ grid, weekDays }"
    data-slot="calendar"
    :class="cn('p-3', props.class)"
    v-bind="forwarded"
  >
    <CalendarHeader>
      <CalendarHeading />

      <div class="flex items-center gap-1">
        <CalendarPrevButton />
        <CalendarNextButton />
      </div>
    </CalendarHeader>

    <div class="flex flex-col gap-y-4 mt-4 sm:flex-row sm:gap-x-4 sm:gap-y-0">
      <CalendarGrid v-for="month in grid" :key="month.value.toString()">
        <CalendarGridHead>
          <CalendarGridRow>
            <CalendarHeadCell
              v-for="day in weekDays" :key="day"
            >
              {{ day }}
            </CalendarHeadCell>
          </CalendarGridRow>
        </CalendarGridHead>
        <CalendarGridBody>
          <CalendarGridRow v-for="(weekDates, index) in month.rows" :key="`weekDate-${index}`" class="mt-2 w-full">
            <CalendarCell
              v-for="weekDate in weekDates"
              :key="weekDate.toString()"
              :date="weekDate"
            >
              <CalendarCellTrigger
                :day="weekDate"
                :month="month.value"
              />
            </CalendarCell>
          </CalendarGridRow>
        </CalendarGridBody>
      </CalendarGrid>
    </div>
  </CalendarRoot>
</template>

```



3. `resources/js/components/ui/calendar/CalendarCell.vue`

```
<script lang="ts" setup>
import { cn } from '@/lib/utils'
import { CalendarCell, type CalendarCellProps, useForwardProps } from 'reka-ui'
import { computed, type HTMLAttributes } from 'vue'

const props = defineProps<CalendarCellProps & { class?: HTMLAttributes['class'] }>()

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})

const forwardedProps = useForwardProps(delegatedProps)
</script>

<template>
  <CalendarCell
    data-slot="calendar-cell"
    :class="cn('relative p-0 text-center text-sm focus-within:relative focus-within:z-20 [&:has([data-selected])]:rounded-md [&:has([data-selected])]:bg-accent', props.class)"
    v-bind="forwardedProps"
  >
    <slot />
  </CalendarCell>
</template>

```



4. `resources/js/components/ui/calendar/CalendarCellTrigger.vue`

```
<script lang="ts" setup>
import { cn } from '@/lib/utils'
import { buttonVariants } from '@/components/ui/button'
import { CalendarCellTrigger, type CalendarCellTriggerProps, useForwardProps } from 'reka-ui'
import { computed, type HTMLAttributes } from 'vue'

const props = withDefaults(defineProps<CalendarCellTriggerProps & { class?: HTMLAttributes['class'] }>(), {
  as: 'button',
})

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})

const forwardedProps = useForwardProps(delegatedProps)
</script>

<template>
  <CalendarCellTrigger
    data-slot="calendar-cell-trigger"
    :class="cn(
      buttonVariants({ variant: 'ghost' }),
      'size-8 p-0 font-normal aria-selected:opacity-100 cursor-default',
      '[&[data-today]:not([data-selected])]:bg-accent [&[data-today]:not([data-selected])]:text-accent-foreground',
      // Selected
      'data-[selected]:bg-primary data-[selected]:text-primary-foreground data-[selected]:opacity-100 data-[selected]:hover:bg-primary data-[selected]:hover:text-primary-foreground data-[selected]:focus:bg-primary data-[selected]:focus:text-primary-foreground',
      // Disabled
      'data-[disabled]:text-muted-foreground data-[disabled]:opacity-50',
      // Unavailable
      'data-[unavailable]:text-destructive-foreground data-[unavailable]:line-through',
      // Outside months
      'data-[outside-view]:text-muted-foreground',
      props.class,
    )"
    v-bind="forwardedProps"
  >
    <slot />
  </CalendarCellTrigger>
</template>

```



5. `resources/js/components/ui/calendar/CalendarGrid.vue`

```
<script lang="ts" setup>
import { cn } from '@/lib/utils'
import { CalendarGrid, type CalendarGridProps, useForwardProps } from 'reka-ui'
import { computed, type HTMLAttributes } from 'vue'

const props = defineProps<CalendarGridProps & { class?: HTMLAttributes['class'] }>()

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})

const forwardedProps = useForwardProps(delegatedProps)
</script>

<template>
  <CalendarGrid
    data-slot="calendar-grid"
    :class="cn('w-full border-collapse space-x-1', props.class)"
    v-bind="forwardedProps"
  >
    <slot />
  </CalendarGrid>
</template>

```



6. `resources/js/components/ui/calendar/CalendarGridBody.vue`

```
<script lang="ts" setup>
import { CalendarGridBody, type CalendarGridBodyProps } from 'reka-ui'

const props = defineProps<CalendarGridBodyProps>()
</script>

<template>
  <CalendarGridBody
    data-slot="calendar-grid-body"
    v-bind="props"
  >
    <slot />
  </CalendarGridBody>
</template>

```



7. `resources/js/components/ui/calendar/CalendarGridHead.vue`

```
<script lang="ts" setup>
import type { HTMLAttributes } from 'vue'
import { CalendarGridHead, type CalendarGridHeadProps } from 'reka-ui'

const props = defineProps<CalendarGridHeadProps & { class?: HTMLAttributes['class'] }>()
</script>

<template>
  <CalendarGridHead
    data-slot="calendar-grid-head"
    v-bind="props"
  >
    <slot />
  </CalendarGridHead>
</template>

```



8. `resources/js/components/ui/calendar/CalendarGridRow.vue`

```
<script lang="ts" setup>
import { cn } from '@/lib/utils'
import { CalendarGridRow, type CalendarGridRowProps, useForwardProps } from 'reka-ui'
import { computed, type HTMLAttributes } from 'vue'

const props = defineProps<CalendarGridRowProps & { class?: HTMLAttributes['class'] }>()

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})

const forwardedProps = useForwardProps(delegatedProps)
</script>

<template>
  <CalendarGridRow
    data-slot="calendar-grid-row"
    :class="cn('flex', props.class)" v-bind="forwardedProps"
  >
    <slot />
  </CalendarGridRow>
</template>

```



9. `resources/js/components/ui/calendar/CalendarHeadCell.vue`

```
<script lang="ts" setup>
import { cn } from '@/lib/utils'
import { CalendarHeadCell, type CalendarHeadCellProps, useForwardProps } from 'reka-ui'
import { computed, type HTMLAttributes } from 'vue'

const props = defineProps<CalendarHeadCellProps & { class?: HTMLAttributes['class'] }>()

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})

const forwardedProps = useForwardProps(delegatedProps)
</script>

<template>
  <CalendarHeadCell
    data-slot="calendar-head-cell"
    :class="cn('text-muted-foreground rounded-md w-8 font-normal text-[0.8rem]', props.class)"
    v-bind="forwardedProps"
  >
    <slot />
  </CalendarHeadCell>
</template>

```



10. `resources/js/components/ui/calendar/CalendarHeader.vue`

```
<script lang="ts" setup>
import { cn } from '@/lib/utils'
import { CalendarHeader, type CalendarHeaderProps, useForwardProps } from 'reka-ui'
import { computed, type HTMLAttributes } from 'vue'

const props = defineProps<CalendarHeaderProps & { class?: HTMLAttributes['class'] }>()

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})

const forwardedProps = useForwardProps(delegatedProps)
</script>

<template>
  <CalendarHeader
    data-slot="calendar-header"
    :class="cn('flex justify-center pt-1 relative items-center w-full', props.class)"
    v-bind="forwardedProps"
  >
    <slot />
  </CalendarHeader>
</template>

```



11. `resources/js/components/ui/calendar/CalendarHeading.vue`

```
<script lang="ts" setup>
import { cn } from '@/lib/utils'
import { CalendarHeading, type CalendarHeadingProps, useForwardProps } from 'reka-ui'
import { computed, type HTMLAttributes } from 'vue'

const props = defineProps<CalendarHeadingProps & { class?: HTMLAttributes['class'] }>()

defineSlots<{
  default: (props: { headingValue: string }) => any
}>()

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})

const forwardedProps = useForwardProps(delegatedProps)
</script>

<template>
  <CalendarHeading
    v-slot="{ headingValue }"
    data-slot="calendar-heading"
    :class="cn('text-sm font-medium', props.class)"
    v-bind="forwardedProps"
  >
    <slot :heading-value>
      {{ headingValue }}
    </slot>
  </CalendarHeading>
</template>

```



12. `resources/js/components/ui/calendar/CalendarNextButton.vue`

```
<script lang="ts" setup>
import { cn } from '@/lib/utils'
import { buttonVariants } from '@/components/ui/button'
import { ChevronRight } from 'lucide-vue-next'
import { CalendarNext, type CalendarNextProps, useForwardProps } from 'reka-ui'
import { computed, type HTMLAttributes } from 'vue'

const props = defineProps<CalendarNextProps & { class?: HTMLAttributes['class'] }>()

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})

const forwardedProps = useForwardProps(delegatedProps)
</script>

<template>
  <CalendarNext
    data-slot="calendar-next-button"
    :class="cn(
      buttonVariants({ variant: 'outline' }),
      'absolute right-1',
      'size-7 bg-transparent p-0 opacity-50 hover:opacity-100',
      props.class,
    )"
    v-bind="forwardedProps"
  >
    <slot>
      <ChevronRight class="size-4" />
    </slot>
  </CalendarNext>
</template>

```



13. `resources/js/components/ui/calendar/CalendarPrevButton.vue`

```
<script lang="ts" setup>
import { cn } from '@/lib/utils'
import { buttonVariants } from '@/components/ui/button'
import { ChevronLeft } from 'lucide-vue-next'
import { CalendarPrev, type CalendarPrevProps, useForwardProps } from 'reka-ui'
import { computed, type HTMLAttributes } from 'vue'

const props = defineProps<CalendarPrevProps & { class?: HTMLAttributes['class'] }>()

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})

const forwardedProps = useForwardProps(delegatedProps)
</script>

<template>
  <CalendarPrev
    data-slot="calendar-prev-button"
    :class="cn(
      buttonVariants({ variant: 'outline' }),
      'absolute left-1',
      'size-7 bg-transparent p-0 opacity-50 hover:opacity-100',
      props.class,
    )"
    v-bind="forwardedProps"
  >
    <slot>
      <ChevronLeft class="size-4" />
    </slot>
  </CalendarPrev>
</template>

```

.
.
.

Setelah selesai menambahkan komponen calendar, selanjutnya kita tambahkan beberapa komponen untuk interaksi popover untuk menampilkan calendar.

1. `resources/js/components/ui/popover/index.ts`

```
export { default as Popover } from './Popover.vue'
export { default as PopoverAnchor } from './PopoverAnchor.vue'
export { default as PopoverContent } from './PopoverContent.vue'
export { default as PopoverTrigger } from './PopoverTrigger.vue'

```



2. `resources/js/components/ui/popover/Popover.vue`

```
<script setup lang="ts">
import type { PopoverRootEmits, PopoverRootProps } from 'reka-ui'
import { PopoverRoot, useForwardPropsEmits } from 'reka-ui'

const props = defineProps<PopoverRootProps>()
const emits = defineEmits<PopoverRootEmits>()

const forwarded = useForwardPropsEmits(props, emits)
</script>

<template>
  <PopoverRoot
    data-slot="popover"
    v-bind="forwarded"
  >
    <slot />
  </PopoverRoot>
</template>

```



3. `resources/js/components/ui/popover/PopoverAnchor.vue`

```
<script setup lang="ts">
import type { PopoverAnchorProps } from 'reka-ui'
import { PopoverAnchor } from 'reka-ui'

const props = defineProps<PopoverAnchorProps>()
</script>

<template>
  <PopoverAnchor
    data-slot="popover-anchor"
    v-bind="props"
  >
    <slot />
  </PopoverAnchor>
</template>

```



4. `resources/js/components/ui/popover/PopoverContent.vue`

```
<script setup lang="ts">
import { cn } from '@/lib/utils'
import {
  PopoverContent,
  type PopoverContentEmits,
  type PopoverContentProps,
  PopoverPortal,
  useForwardPropsEmits,
} from 'reka-ui'
import { computed, type HTMLAttributes } from 'vue'

defineOptions({
  inheritAttrs: false,
})

const props = withDefaults(
  defineProps<PopoverContentProps & { class?: HTMLAttributes['class'] }>(),
  {
    align: 'center',
    sideOffset: 4,
  },
)
const emits = defineEmits<PopoverContentEmits>()

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})

const forwarded = useForwardPropsEmits(delegatedProps, emits)
</script>

<template>
  <PopoverPortal>
    <PopoverContent
      data-slot="popover-content"
      v-bind="{ ...forwarded, ...$attrs }"
      :class="
        cn(
          'bg-popover text-popover-foreground data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 z-50 w-72 rounded-md border p-4 shadow-md origin-(--reka-popover-content-transform-origin) outline-hidden',
          props.class,
        )
      "
    >
      <slot />
    </PopoverContent>
  </PopoverPortal>
</template>

```



5. `resources/js/components/ui/popover/PopoverTrigger.vue`

```
<script setup lang="ts">
import { PopoverTrigger, type PopoverTriggerProps } from 'reka-ui'

const props = defineProps<PopoverTriggerProps>()
</script>

<template>
  <PopoverTrigger
    data-slot="popover-trigger"
    v-bind="props"
  >
    <slot />
  </PopoverTrigger>
</template>

```

Setelah kita koding controller dan komponen vue, fitur untuk menambahkan tasks baru berhasil kita tambahkan ke project kita.



## Step 6: Coding Fitur Update Existing Task {#step-6-coding-fitur-update-existing-tasks}

Pada step ini kita akan coding fitur yang ketiga, yaitu fitur untuk memperbaharui data task yang ada. Untuk menambahkan fitur tersebut, kita buka kembali file `app/Http/Controllers/TaskController.php`. Pada controller tersebut, kita tambahkan dua method baru, yaitu `edit()` yang menangani proses untuk menampilkan halaman form edit data task dan `update()` yang menangani proses update data task.

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

Save kembali file `app/Http/Controllers/TaskController.php`.

Selanjutnya kita buat komponen `Tasks/Edit`, yaitu file `resources/js/pages/Tasks/Edit.vue`. Pada file `resources/js/pages/Tasks/Edit.vue`, kita tambahkan baris kode berikut ini.

```
<script setup lang="ts">
import InputError from '@/components/InputError.vue';
import { Button } from '@/components/ui/button';
import { Calendar } from '@/components/ui/calendar';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Switch } from '@/components/ui/switch';
import { cn } from '@/lib/utils';
import { type Task } from '@/types';
import { Head, router, useForm } from '@inertiajs/vue3';
import { update } from '@/actions/App/Http/Controllers/TaskController';
import { DateFormatter, fromDate, getLocalTimeZone } from '@internationalized/date';
import { CalendarIcon } from 'lucide-vue-next';
import { Card, CardContent, CardFooter } from '@/components/ui/card';

const df = new DateFormatter('en-US', {
    dateStyle: 'long',
});

defineOptions({
    layout: {
        breadcrumbs: [
            { title: 'Dashboard', href: '/dashboard' },
            { title: 'Tasks', href: '/tasks' },
            { title: 'Edit', href: '' },
        ],
    },
});

interface Props {
    task: Task;
}

const props = defineProps<Props>();

const form = useForm({
    name: props.task.name,
    is_completed: props.task.is_completed,
    due_date: props.task.due_date ? fromDate(new Date(props.task.due_date)) : null,
});

const submitForm = () => {
    router.post(
        update(props.task),
        {
            ...form.data(),
            due_date: form.data().due_date
                ? form.data().due_date.toDate(getLocalTimeZone()).toISOString().slice(0, 10)
                : null,
            _method: 'PUT',
        },
        {
            preserveScroll: true,
        },
    );
};
</script>

<template>
    <Head title="Edit Task" />
    <div class="flex h-full flex-1 flex-col gap-4 p-4">
        <form class="space-y-6" @submit.prevent="submitForm">
            <Card class="py-6 border-0 shadow-none">
                <CardContent class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <!-- Task Name -->
                    <div class="grid gap-2">
                        <Label htmlFor="name">Task Name *</Label>
                        <Input id="name" v-model="form.name" class="mt-1 block w-full" />
                        <InputError :message="form.errors.name" />
                    </div>

                    <!-- Due Date -->
                    <div class="grid gap-2">
                        <Label htmlFor="due_date">Due Date</Label>
                        <Popover>
                            <PopoverTrigger as-child>
                                <Button
                                    variant="outline"
                                    :class="cn('w-full justify-start text-left font-normal', !form.due_date && 'text-muted-foreground')"
                                >
                                    <CalendarIcon class="mr-2 h-4 w-4" />
                                    {{ form.due_date
                                    ? df.format(form.due_date.toDate(getLocalTimeZone()))
                                    : 'Pick a date' }}
                                </Button>
                            </PopoverTrigger>
                            <PopoverContent class="w-auto p-0">
                                <Calendar v-model="form.due_date" initial-focus />
                            </PopoverContent>
                        </Popover>
                        <InputError :message="form.errors.due_date" />
                    </div>

                    <!-- Completed -->
                    <div class="grid gap-2">
                        <Label htmlFor="is_completed">Completed?</Label>
                        <Switch id="is_completed" v-model="form.is_completed" class="mt-1" />
                        <InputError :message="form.errors.is_completed" />
                    </div>
                </CardContent>

                <CardFooter>
                    <Button :disabled="form.processing" variant="default">Update Task</Button>
                </CardFooter>
            </Card>
        </form>
    </div>
</template>

```

Save kembali file `resources/js/pages/Tasks/Edit.vue`.

Untuk memperbaharui status apakah task sudah selesai, kita akan gunakan switch. Jadi sekarang kita akan buat komponen baru, yaitu switch. Untuk menambahkan komponen switch, kita buat beberapa file baru, yaitu:

1. `resources/js/components/ui/switch/index.ts`

```
export { default as Switch } from './Switch.vue'
```

2. `resources/js/components/ui/switch/Switch.vue`

```
<script setup lang="ts">
import { cn } from '@/lib/utils'
import {
  SwitchRoot,
  type SwitchRootEmits,
  type SwitchRootProps,
  SwitchThumb,
  useForwardPropsEmits,
} from 'reka-ui'
import { computed, type HTMLAttributes } from 'vue'

const props = defineProps<SwitchRootProps & { class?: HTMLAttributes['class'] }>()

const emits = defineEmits<SwitchRootEmits>()

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})

const forwarded = useForwardPropsEmits(delegatedProps, emits)
</script>

<template>
  <SwitchRoot
    data-slot="switch"
    v-bind="forwarded"
    :class="cn(
      'peer data-[state=checked]:bg-primary data-[state=unchecked]:bg-input focus-visible:border-ring focus-visible:ring-ring/50 dark:data-[state=unchecked]:bg-input/80 inline-flex h-[1.15rem] w-8 shrink-0 items-center rounded-full border border-transparent shadow-xs transition-all outline-none focus-visible:ring-[3px] disabled:cursor-not-allowed disabled:opacity-50',
      props.class,
    )"
  >
    <SwitchThumb
      data-slot="switch-thumb"
      :class="cn('bg-background dark:data-[state=unchecked]:bg-foreground dark:data-[state=checked]:bg-primary-foreground pointer-events-none block size-4 rounded-full ring-0 transition-transform data-[state=checked]:translate-x-[calc(100%-2px)] data-[state=unchecked]:translate-x-0')"
    >
      <slot name="thumb" />
    </SwitchThumb>
  </SwitchRoot>
</template>

```

Sekarang kita sudah sudah selesai menambahkan fitur untuk memperbaharui data tasks yang tersedia.



## Step 7: Coding Fitur Delete Existing Task {#step-7-coding-fitur-delete-existing-task}

Sekarang kita akan menambahkan fitur terakhir dari operasi CRUD task, yaitu fitur untuk menghapus data task yang tidak diperlukan. Untuk menambahkan fitur untuk menghapus data, buka kembali file `app/Http/Controllers/TaskController.php`. Pada controller tersebut kita tambahkan method untuk menangani proses menghapus data, yaitu method `destroy()`.

```
public function destroy(Task $task)
{
    $task->delete();

    return redirect()->route('tasks.index');
}
```

Save kembali `app/Http/Controllers/TaskController.php`.

Pada tahapan ini kita sudah menyelesaikan semua fitur untuk mengelola tasks.



## Step 8: Uji Coba {#step-8-uji-coba}

Sekarang kita sudah menyelesaikan semua proses coding untuk fitur CRUD Task Management menggunakan Vue Starter Kit. Selanjutnya kita akan mencoba menjalankan aplikasi untuk mengecek apakah semua fitur berfungsi dengan baik. Pastikan kita sudah menyimpan semua file yang kita modifikasi.

Pertama, kita jalankan server development Laravel dan build asset frontend sekaligus dengan menjalankan command berikut di terminal:

```
composer run dev
```

Setelah kedua proses berjalan, kita bisa membuka alamat `http://127.0.0.1:8000` di browser. Setelah aplikasi terbuka, kita perlu login terlebih dahulu menggunakan akun yang sudah terdaftar. Jika belum ada akun, kita bisa membuat akun baru dengan mengklik link "Register".

Setelah login, kita akan diarahkan ke halaman Dashboard. Pada sidebar kiri, sekarang sudah tersedia menu "Tasks" yang sudah kita tambahkan sebelumnya. Klik menu tersebut untuk menuju ke halaman daftar tasks.

Pada halaman daftar tasks, karena kita belum menambahkan task apapun, tampilannya akan kosong dengan tabel yang hanya berisi header. Untuk menambahkan task baru, klik tombol "Create Task" yang tersedia di bagian atas halaman.

Pada halaman Create Task, kita bisa mengisi nama task pada field "Task Name" dan menentukan tenggat waktu (due date) dengan mengklik tombol "Pick a date" yang akan memunculkan kalender. Setelah form terisi, klik tombol "Create Task" untuk menyimpan data.

Setelah berhasil membuat task baru, kita akan diarahkan kembali ke halaman daftar tasks. Sekarang tabel sudah menampilkan task yang baru saja kita buat, dengan informasi nama task, status (default "In Progress"), tanggal tenggat waktu, dan tombol aksi "Edit" dan "Delete".

Mari kita uji fitur edit dengan mengklik tombol "Edit" pada task yang ingin diubah. Pada halaman edit, kita bisa mengubah nama task, tanggal tenggat waktu, dan juga status task menggunakan switch "Completed?". Jika kita mengubah status menjadi completed, maka pada daftar task nantinya statusnya akan berubah menjadi "Completed" dengan warna hijau. Setelah selesai melakukan perubahan, klik tombol "Update Task" untuk menyimpan perubahan.

Untuk menguji fitur delete, kita bisa kembali ke halaman daftar tasks, lalu klik tombol "Delete" pada task yang ingin dihapus. Sistem akan menampilkan konfirmasi sebelum benar-benar menghapus data. Jika kita klik "OK", maka task akan dihapus dari database dan tidak akan ditampilkan lagi di daftar.

Dengan demikian, kita sudah berhasil menguji semua fitur CRUD (Create, Read, Update, Delete) pada aplikasi Task Management yang kita bangun menggunakan Vue Starter Kit.

## Penutup{#penutup}
Dalam tutorial ini, kita telah berhasil mengimplementasikan fitur CRUD (Create, Read, Update, Delete) pada aplikasi Task Management menggunakan Laravel 12 dengan Vue Starter Kit. Kita telah memanfaatkan kekuatan Inertia.js untuk menghubungkan backend Laravel dengan frontend Vue.js.

Beberapa komponen yang telah kita buat untuk mendukung fitur ini antara lain:

1. Komponen tabel untuk menampilkan daftar task
2. Komponen pagination untuk memfasilitasi navigasi halaman
3. Komponen calendar untuk memilih tanggal
4. Komponen popover untuk menampilkan calendar
5. Komponen switch untuk mengubah status task

### Key Takeaways

- **Inertia.js sebagai Jembatan**: Inertia.js mempermudah integrasi antara backend Laravel dengan frontend Vue.js tanpa perlu membangun API terpisah.
- **Komponensasi Modular**: Pendekatan berbasis komponen pada Vue.js memungkinkan kita membangun UI yang modular dan reusable.
- **Kekuatan Laravel + Vue**: Kombinasi routing dan controller Laravel dengan reaktivitas Vue.js menciptakan pengalaman pengembangan full-stack yang optimal.
- **Fleksibilitas Form**: Dengan bantuan komponen seperti calendar dan switch, kita dapat membangun form yang user-friendly dan interaktif.
- **Efisiensi Development**: Vue Starter Kit menyediakan struktur dasar yang memungkinkan kita fokus pada pengembangan fitur tanpa perlu mengatur setup awal yang rumit.

Keseluruhan proses ini menunjukkan bagaimana Vue Starter Kit memberikan fondasi yang solid untuk membangun aplikasi Laravel dengan frontend Vue.js yang responsif dan interaktif. Dengan menggunakan Inertia.js, kita bisa mempertahankan pengalaman pengembangan full-stack yang menyenangkan, dimana kita menggunakan routing dan controller Laravel tradisional sembari memanfaatkan kekuatan komponensasi dan reaktivitas Vue.js.

Tutorial ini melengkapi seri tutorial tentang cara menambahkan fitur CRUD pada ketiga Starter Kit Laravel 12 (Livewire, React, dan Vue). Dengan pemahaman terhadap ketiganya, kita memiliki pilihan untuk menggunakan stack yang paling sesuai dengan kebutuhan proyek kita di masa depan.

Semoga tutorial ini bermanfaat dan dapat membantu kamu mengembangkan aplikasi menggunakan Laravel 12 Vue Starter Kit!