# Lesson 4 — Apa itu MVC?

## Tujuan Pembelajaran

Di akhir lesson ini, kamu akan:
- Memahami pola arsitektur MVC dan mengapa itu penting
- Membuat `EntryController` pertama
- Memindahkan logika dari route ke controller
- Melihat bagaimana kode menjadi lebih rapi dengan pemisahan tanggung jawab

---

## Masalah dengan Pendekatan Saat Ini

Di lesson sebelumnya, kita meletakkan semua logika langsung di dalam route:

```php
Route::get('/entries', function () {
    $entries = [
        ['title' => 'Rencana liburan...', ...],
        ...
    ];
    return view('entries.index', compact('entries'));
});
```

Untuk satu route, ini masih terlihat wajar. Tapi aplikasi Catatku nantinya punya banyak route: tampilkan daftar, tampilkan detail, form buat catatan baru, simpan catatan, form edit, simpan perubahan, hapus. Kalau semua logika itu ditumpuk di `routes/web.php`, file itu akan menjadi sangat panjang dan susah dipelihara.

Inilah masalah yang diselesaikan oleh pola **MVC**.

---

## Apa itu MVC?

MVC adalah singkatan dari **Model - View - Controller**. Pola ini memisahkan aplikasi menjadi tiga bagian dengan tanggung jawab yang berbeda:

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    Model    │    │    View     │    │ Controller  │
│             │    │             │    │             │
│ Berinteraksi│    │ Menampilkan │    │ Menerima    │
│ dengan      │    │ data kepada │    │ request &   │
│ database    │    │ pengguna    │    │ mengatur    │
│             │    │ sebagai HTML│    │ alur data   │
└─────────────┘    └─────────────┘    └─────────────┘
```

**Model** — Bertanggung jawab atas data. Model berkomunikasi dengan database: mengambil, menyimpan, memperbarui, dan menghapus data.

**View** — Bertanggung jawab atas tampilan. View mengambil data yang diberikan oleh controller dan merender HTML.

**Controller** — Bertanggung jawab atas alur aplikasi. Controller menerima request, meminta data dari model, lalu memberikannya ke view yang tepat.

### Analogi Dapur Restoran

- **Model** adalah dapur — tempat bahan makanan (data) diproses
- **View** adalah piring dan meja — cara makanan disajikan ke tamu
- **Controller** adalah pelayan — menerima pesanan, mengambil dari dapur, menyajikan ke tamu

Pelayan tidak memasak. Dapur tidak berhadapan dengan tamu. Setiap bagian punya satu peran yang jelas.

---

## Membuat EntryController

Jalankan perintah artisan berikut untuk membuat controller:

```bash
php artisan make:controller EntryController
```

Output:
```
INFO  Controller [app/Http/Controllers/EntryController.php] created successfully.
```

Buka file yang baru dibuat di `app/Http/Controllers/EntryController.php`. Isinya adalah class kosong:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class EntryController extends Controller
{
    //
}
```

Sekarang tambahkan method `index()` yang menangani halaman daftar catatan:

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
                'title'      => 'Rencana liburan akhir tahun',
                'content'    => 'Sudah lama tidak liburan. Mungkin bisa ke Yogyakarta atau Lombok. Perlu riset dulu soal budget dan waktu yang tepat.',
                'created_at' => '20 Februari 2026',
            ],
            [
                'id'         => 2,
                'title'      => 'Belajar Laravel hari pertama',
                'content'    => 'Hari ini mulai belajar Laravel. Ternyata tidak sesulit yang dibayangkan. Routing dan view cukup intuitif.',
                'created_at' => '19 Februari 2026',
            ],
            [
                'id'         => 3,
                'title'      => 'Resolusi bulan ini',
                'content'    => 'Ingin lebih konsisten menulis catatan setiap hari. Minimal satu paragraf sebelum tidur.',
                'created_at' => '18 Februari 2026',
            ],
        ];

        return view('entries.index', compact('entries'));
    }
}
```

---

## Memperbarui Route

Sekarang perbarui `routes/web.php` agar route `/entries` menunjuk ke controller, bukan ke anonymous function:

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EntryController;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/entries', [EntryController::class, 'index']);
```

Baca baris terakhir sebagai: "Ketika ada request GET ke `/entries`, panggil method `index` di `EntryController`."

File `routes/web.php` sekarang hanya berisi peta route — bersih dari logika bisnis.

---

## Alur MVC yang Lengkap

Dengan perubahan ini, alur request menjadi:

```
Browser → GET /entries
              │
              ▼
        routes/web.php
        Route::get('/entries', [EntryController::class, 'index'])
              │
              ▼
        EntryController@index()
        $entries = [...];          ← nanti dari Model
        return view('entries.index', ...)
              │
              ▼
        resources/views/entries/index.blade.php
        @foreach ($entries as $entry) ...
              │
              ▼
        HTML dikirim ke browser
```

---

## Verifikasi dengan Route List

Jalankan perintah ini untuk melihat semua route yang terdaftar:

```bash
php artisan route:list
```

Output:
```
GET|HEAD  /          ·
GET|HEAD  /entries   EntryController@index
```

Buka browser dan akses `http://127.0.0.1:8000/entries`. Hasilnya harus sama persis seperti sebelumnya — tiga catatan palsu tampil. Perbedaannya tidak terlihat oleh pengguna, tapi struktur kode kita kini jauh lebih baik.

---

## Ringkasan

Kita telah:
- Memahami pola MVC dan manfaat pemisahan tanggung jawab
- Membuat `EntryController` dengan method `index()`
- Memindahkan data dan logika dari route ke controller
- Memverifikasi route dengan `php artisan route:list`

Route bersih, controller punya logikanya sendiri, view fokus pada tampilan. Di lesson berikutnya, kita akan mengganti array palsu dengan data sungguhan dari database — dimulai dengan membuat tabel menggunakan **migration**.
