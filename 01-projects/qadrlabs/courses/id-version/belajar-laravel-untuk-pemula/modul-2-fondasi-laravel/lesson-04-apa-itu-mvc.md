Pada lesson sebelumnya, kita telah membuat halaman daftar entries yang berfungsi. Namun jika Anda melihat `routes/web.php` sekarang, ada sesuatu yang terasa janggal: file yang seharusnya hanya berisi peta URL malah dipenuhi dengan logika, menyiapkan data, mendefinisikan array, dan menentukan apa yang akan ditampilkan. Untuk satu route, ini masih bisa ditoleransi. Namun Catatku pada akhirnya akan memiliki banyak route, dan jika semuanya mengikuti pola yang sama, `routes/web.php` akan menjadi tempat yang sangat tidak nyaman untuk dikerjakan.

Lesson ini menyelesaikan masalah tersebut. Dan lebih dari sekadar memindahkan kode ke file lain, Anda akan memahami *mengapa* pemisahan ini adalah cara yang tepat untuk mengorganisasikan aplikasi Anda.

## Ikhtisar {#overview}

### What You'll Build

Pada akhir lesson ini, halaman `/entries` akan menampilkan hasil yang persis sama di browser: tiga entries dummy, sama seperti sebelumnya. Perbedaannya tidak akan terlihat oleh pengguna, namun struktur kode di baliknya akan jauh lebih baik. Logika akan berada di controller, presentasi akan tetap di view, dan file route hanya akan berisi peta yang bersih.

### What You'll Learn

- Apa itu pola arsitektur MVC (Model-View-Controller) dan mengapa pola ini ada
- Tanggung jawab spesifik dari setiap bagian: Model, View, dan Controller
- Cara membuat controller menggunakan perintah `php artisan make:controller`
- Cara memindahkan logika dari route closure ke method controller
- Cara memperbarui routes agar menunjuk ke method controller, bukan closure
- Cara memverifikasi route yang terdaftar menggunakan `php artisan route:list`

### What You'll Need

- Project `catatku` terbuka di VS Code
- Development server berjalan dengan `php artisan serve`
- Route `/entries` dan view `entries/index.blade.php` dari Lesson 3

---

## Step 1: Identifikasi Masalahnya {#step-1-identify-the-problem}

Mari kita lihat apa yang telah kita buat di lesson sebelumnya. Buka `routes/web.php` dan periksa route `/entries`:

```php
Route::get('/entries', function () {
    $entries = [
        ['title' => 'Year-end vacation plans...', ...],
        ...
    ];
    return view('entries.index', compact('entries'));
});
```

Untuk satu route, ini masih terlihat wajar. Namun pikirkan ke depan: Catatku pada akhirnya akan membutuhkan route untuk menampilkan daftar entries, menampilkan detail satu entry, menampilkan form untuk membuat entry baru, menyimpan entry tersebut, menampilkan form edit, menyimpan perubahan, dan menghapus entry. Jika semua logika itu ditumpuk ke dalam `routes/web.php`, file tersebut akan menjadi sangat panjang dan menyulitkan untuk dikelola.

Inilah masalah yang diselesaikan oleh pola **MVC**.

---

## Step 2: Membuat EntryController {#step-2-create-the-entrycontroller}

Laravel menyediakan perintah Artisan untuk membuat controller. Jalankan perintah berikut di terminal Anda:

```bash
php artisan make:controller EntryController
```

Output:

```
INFO  Controller [app/Http/Controllers/EntryController.php] created successfully.
```

Buka file yang baru saja dibuat di `app/Http/Controllers/EntryController.php`. Anda akan melihat sebuah class kosong:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class EntryController extends Controller
{
    //
}
```

Ini adalah controller standar Laravel. Ia berada di namespace `App\Http\Controllers` dan extend dari class dasar `Controller`. Saat ini ia belum memiliki method apapun, jadi belum melakukan apa-apa. Mari kita ubah itu.

Tambahkan method `index()` yang menangani halaman daftar entries. Ini adalah logika yang sama dengan yang sebelumnya berada di dalam route closure, sekarang berada di tempat yang seharusnya:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class EntryController extends Controller
{
    public function index()
    {
        $entries = [
            [
                'id'         => 1,
                'title'      => 'Year-end vacation plans',
                'content'    => 'It has been a while since the last vacation. Maybe Yogyakarta or Lombok. Need to research the budget and best timing.',
                'created_at' => '20 February 2026',
            ],
            [
                'id'         => 2,
                'title'      => 'First day learning Laravel',
                'content'    => 'Started learning Laravel today. Turns out it is not as hard as I expected. Routing and views are quite intuitive.',
                'created_at' => '19 February 2026',
            ],
            [
                'id'         => 3,
                'title'      => 'This month\'s resolutions',
                'content'    => 'Want to be more consistent writing entries every day. At least one paragraph before bed.',
                'created_at' => '18 February 2026',
            ],
        ];

        return view('entries.index', compact('entries'));
    }
}

```

Method `index()` adalah fungsi public, yang berarti Laravel dapat memanggilnya dari luar ketika sebuah route menunjuk ke sana. Nama method `index` adalah konvensi di Laravel untuk action yang menampilkan daftar resource. Anda akan melihat pola penamaan ini di sepanjang course: `index` untuk daftar, `show` untuk satu item, `create` untuk form, `store` untuk menyimpan, dan seterusnya.

Perhatikan bahwa kode di dalam `index()` identik dengan yang sebelumnya ada di route closure. Kita tidak mengubah logika apapun. Kita hanya memindahkannya ke lokasi yang lebih tepat.

---

## Step 3: Perbarui Route {#step-3-update-the-route}

Sekarang perbarui `routes/web.php` agar route `/entries` menunjuk ke controller, bukan ke fungsi anonim:

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EntryController; // add this line

Route::get('/', function () {
    return view('home');
});

Route::get('/entries', [EntryController::class, 'index']); // modify `/entries` route
```

Ada dua perubahan di sini. Pertama, kita menambahkan statement `use` di bagian atas untuk mengimpor `EntryController`. Tanpa import ini, Laravel tidak akan tahu class mana yang kita maksud.

Kedua, route `/entries` sekarang menggunakan `[EntryController::class, 'index']` alih-alih closure. Bacalah ini sebagai: "Ketika ada GET request ke `/entries`, panggil method `index` pada `EntryController`." Sintaks `::class` memberikan nama class lengkap kepada Laravel sebagai string, sehingga Laravel dapat menemukan dan menginstansiasi controller secara otomatis.

Lihat betapa bersihnya `routes/web.php` sekarang. File ini hanya berisi pemetaan URL tanpa logika bisnis sama sekali. Setiap route menyatakan *URL apa* yang dipetakan ke *method controller mana*, dan itu saja. Saat kita menambahkan lebih banyak route di lesson-lesson berikutnya, file ini akan tetap mudah dibaca karena setiap route hanya akan berupa satu baris yang ringkas.

---

## Step 4: Verifikasi Hasilnya {#step-4-verify-the-result}

Pertama, mari kita periksa apakah Laravel mengenali route kita dengan benar. Jalankan perintah berikut:

```bash
php artisan route:list
```

Output:

```
php artisan route:list

  GET|HEAD  / ............................................... routes/web.php:6
  GET|HEAD  entries .................................... EntryController@index
  GET|HEAD  storage/{path} storage.local › vendor/laravel/framework/src/Illum…
  PUT       storage/{path} storage.local.upload › vendor/laravel/framework/sr…
  GET|HEAD  up vendor/laravel/framework/src/Illuminate/Foundation/Configurati…

                                                            Showing [5] routes
```

Baris kedua mengonfirmasi bahwa GET request ke `/entries` ditangani oleh method `index` pada `EntryController`. Perintah `route:list` adalah tool debugging yang berguna. Setiap kali Anda menambah atau mengubah route, Anda dapat menjalankannya untuk memverifikasi bahwa Laravel telah mendaftarkannya dengan benar.

Sekarang buka browser Anda dan kunjungi `http://127.0.0.1:8000/entries`. Halaman tersebut harus terlihat persis sama seperti sebelumnya: tiga entry jurnal dengan judul, tanggal, dan cuplikan konten. Pengguna tidak melihat perbedaan apapun, namun di balik layar, kode telah diorganisasikan dengan baik.
![entries page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/03-catatku-entries-page.webp)

---

## Apa itu MVC? {#what-is-mvc}

Setelah Anda mengalami sendiri proses refactoring ini, mari kita pahami pola di baliknya.

MVC adalah singkatan dari **Model - View - Controller**. Ini adalah pola arsitektur yang memisahkan sebuah aplikasi menjadi tiga bagian, masing-masing dengan tanggung jawab yang berbeda:

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    Model     │    │    View     │    │ Controller  │
│              │    │             │    │             │
│ Talks to the │    │ Displays    │    │ Receives    │
│ database     │    │ data to the │    │ requests &  │
│              │    │ user as HTML│    │ coordinates │
│              │    │             │    │ the flow    │
└──────────────┘    └─────────────┘    └─────────────┘
```

**Model** bertanggung jawab atas data. Ia berkomunikasi dengan database untuk mengambil, menyimpan, memperbarui, dan menghapus record. Kita belum membuat model, namun kita akan membuatnya di Lesson 5.

**View** bertanggung jawab atas presentasi. Ia menerima data yang disediakan oleh controller dan merendernya sebagai HTML. File `entries/index.blade.php` kita adalah sebuah view.

**Controller** bertanggung jawab atas alur aplikasi. Ia menerima request yang masuk, meminta data dari model (atau menyiapkannya), dan meneruskan data tersebut ke view yang sesuai. `EntryController` kita adalah sebuah controller.

### Analogi Dapur Restoran {#the-restaurant-kitchen-analogy}

Bayangkan seperti sebuah restoran:

**Model** adalah dapur. Di sinilah bahan-bahan mentah (data) disimpan, disiapkan, dan diolah.

**View** adalah piring dan meja. Inilah cara makanan disajikan kepada tamu.

**Controller** adalah pelayan. Pelayan menerima pesanan dari tamu, mengambil makanan dari dapur, dan menyajikannya di meja.

Pelayan tidak memasak. Dapur tidak berinteraksi dengan tamu. Setiap bagian memiliki satu peran yang jelas, dan sistem ini bekerja karena setiap orang tetap berada di jalurnya. Prinsip yang sama berlaku untuk MVC: controller tidak menulis HTML, view tidak melakukan query ke database, dan model tidak menentukan halaman mana yang ditampilkan.

---

## Alur MVC Secara Lengkap {#the-complete-mvc-flow}

Dengan perubahan yang kita buat di lesson ini, berikut adalah bagaimana sebuah request mengalir melalui aplikasi:

```
Browser: GET /entries
              │
              ▼
        routes/web.php
        Route::get('/entries', [EntryController::class, 'index'])
              │
              ▼
        EntryController@index()
        $entries = [...];              ← will come from a Model later
        return view('entries.index', compact('entries'))
              │
              ▼
        resources/views/entries/index.blade.php
        @foreach ($entries as $entry) ...
              │
              ▼
        HTML sent to the browser
```

Browser mengirim request. Route mengarahkannya ke controller. Controller menyiapkan data dan meneruskannya ke view. View merender HTML dan mengirimkannya kembali ke browser. Setiap web request di Laravel mengikuti pola yang sama ini.

Saat ini, data `$entries` adalah array hardcoded di dalam controller. Di lesson berikutnya, array tersebut akan digantikan oleh query database melalui model Eloquent. Namun sisa alurnya, dari controller ke view ke browser, akan tetap persis sama.

---

## Kesimpulan {#conclusion}

Lesson ini membuat perubahan yang tidak terlihat oleh pengguna namun transformatif bagi developer. Berikut adalah poin-poin pentingnya:

- **MVC** (Model-View-Controller) adalah pola arsitektur yang memisahkan aplikasi Anda menjadi tiga bagian: data (Model), presentasi (View), dan kontrol alur (Controller).
- Setiap bagian memiliki **satu tanggung jawab**: Model berkomunikasi dengan database, View merender HTML, dan Controller mengoordinasikan keduanya.
- `php artisan make:controller EntryController` membuat file controller baru di `app/Http/Controllers/EntryController.php`.
- Method controller seperti `index()` berisi logika yang sebelumnya berada di dalam route closure. Nama method `index` adalah konvensi Laravel untuk menampilkan daftar resource.
- Routes menunjuk ke controller menggunakan sintaks `[ControllerClass::class, 'methodName']`, sehingga `routes/web.php` tetap bersih dan hanya fokus pada pemetaan URL.
- `php artisan route:list` menampilkan semua route yang terdaftar dan berguna untuk memverifikasi bahwa routes telah terhubung dengan benar.
- **Alur request**-nya adalah: Browser mengirim request, route mengarahkannya ke controller, controller menyiapkan data dan mengirimkannya ke view, view merender HTML kembali ke browser.
- Refactoring yang kita lakukan menghasilkan **output yang persis sama** di browser. Manfaatnya sepenuhnya ada pada organisasi kode, keterbacaan, dan kemudahan pemeliharaan.

Di lesson berikutnya, kita akan mengganti array hardcoded dengan data yang sebenarnya. Kita akan membuat tabel database menggunakan **migration** dan berkenalan dengan **Eloquent**, ORM Laravel yang membuat komunikasi dengan database terasa jauh lebih natural daripada yang Anda bayangkan.
