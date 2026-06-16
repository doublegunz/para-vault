## 1. Sebelum Anda Memulai

Beberapa task memakan waktu. Mengirim sebuah email membuat sebuah network request ke server SMTP. Menghasilkan sebuah PDF melibatkan pemrosesan gambar. Memanggil API pihak ketiga mungkin memakan waktu beberapa detik untuk merespons. Jika ini terjadi selama sebuah HTTP request, user menunggu loading spinner dan mungkin mengira aplikasi Anda lambat. Queue memungkinkan Anda menunda pekerjaan lambat untuk berjalan di background, sehingga request selesai seketika dan user melihat respons yang cepat.

Lesson ini mengajarkan sistem queue Laravel. Anda akan mengonversi email notifikasi komentar dari Lesson 8 menjadi sebuah queued job, menyiapkan sebuah queue worker untuk memproses job, dan memahami cara menggunakan queue driver yang berbeda. Manfaatnya langsung terasa: setelah mengirim sebuah komentar, user tidak lagi menunggu email terkirim. Sebagai gantinya, email di-queue dan user melihat pesan sukses langsung. Sebuah proses worker terpisah menangani pengiriman email yang lambat di background.

### What You'll Build

Anda akan mengonversi email komentar menjadi sebuah queued job, mengonfigurasi queue driver `database`, menjalankan sebuah queue worker, dan memverifikasi email terkirim di background tanpa memblokir HTTP request.

### What You'll Learn

- ✅ Queue driver: `sync`, `database`, `redis`
- ✅ Mailable yang dapat di-queue (interface `ShouldQueue`)
- ✅ Membuat custom job dengan `make:job`
- ✅ Menjalankan queue worker dengan `php artisan queue:work`
- ✅ Failed job dan retry
- ✅ Memonitor queue

### What You'll Need

- Lesson 12 sudah selesai

---

## 2. Mengonfigurasi Queue Driver

Queue driver default di Laravel adalah `sync`, yang berarti job berjalan seketika dan secara sinkron, tidak ditunda sama sekali. Ini baik untuk development lokal ketika Anda tidak menguji perilaku queue, tetapi untuk benar-benar melihat queue beraksi, kita akan beralih ke driver `database`. Driver database menyimpan job yang tertunda di sebuah tabel `jobs`, dan sebuah proses `queue:work` terpisah melakukan polling pada tabel dan memprosesnya.

### Step 1: Memperbarui .env

Buka `.env` dan ubah pengaturan koneksi queue untuk menggunakan driver database.

```env
QUEUE_CONNECTION=database
```

Ini memberi tahu Laravel untuk menggunakan driver database untuk queueing. Driver alternatif termasuk `redis` (cepat, direkomendasikan untuk production), `sqs` (layanan queue terkelola dari Amazon), dan `beanstalkd` (server queue yang ringan). Driver database adalah titik awal yang baik karena ia tidak memerlukan layanan tambahan; Anda hanya membutuhkan sebuah tabel database.

### Step 2: Membuat Tabel Jobs

Sebelum menjalankan perintah migration, periksa apakah migration tabel `jobs` sudah ada di proyek Anda. Laravel 11+ disertai `database/migrations/0001_01_01_000002_create_jobs_table.php` secara default, sehingga menjalankan `php artisan queue:table` dalam kasus itu akan menghasilkan pesan `ERROR Migration already exists.` dan `php artisan migrate` akan melaporkan `Nothing to migrate.`

Jika file tersebut sudah ada di folder `database/migrations/` Anda, lewati perintah `queue:table` dan hanya jalankan migrate:

```bash
php artisan migrate
```

Jika file tidak ada, jalankan kedua perintah untuk menghasilkan dan menerapkan migration:

```bash
php artisan queue:table
php artisan migrate
```

Bagaimanapun caranya, hasilnya sama: sebuah tabel `jobs` di database Anda tempat job yang tertunda disimpan. Setiap baris merepresentasikan satu job yang tertunda, dengan kolom untuk payload job yang diserialisasi, nama queue, jumlah percobaan yang dilakukan sejauh ini, dan timestamp kapan ia menjadi tersedia untuk dijalankan. Laravel juga memiliki sebuah tabel `failed_jobs` (dibuat secara otomatis di Laravel 11+) yang menyimpan job yang gagal secara permanen setelah menghabiskan semua percobaan retry-nya.

---

## 3. Membuat Email Dapat Di-queue

Di Lesson 8, class `NewCommentEmail` sudah menggunakan trait `Queueable`. Tetapi trait itu saja tidak membuatnya di-queue secara otomatis. Anda juga perlu mengimplementasikan `ShouldQueue` pada Mailable, atau memanggil `queue()` alih-alih `send()` dari controller. Menggunakan `ShouldQueue` biasanya lebih disukai karena ia membuat perilaku penundaan menjadi property dari class Mailable itu sendiri, sehingga setiap caller secara otomatis melakukan queue tanpa harus ingat untuk menggunakan method yang berbeda.

### Step 1: Mengimplementasikan ShouldQueue

Buka `app/Mail/NewCommentEmail.php` dan tambahkan interface `ShouldQueue` ke deklarasi class.

```php
<?php
// ... others lines of code

use Illuminate\Contracts\Queue\ShouldQueue;

class NewCommentEmail extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;
    // ... other methods and properties
}
```

Menambahkan `implements ShouldQueue` adalah saklar yang mengubah mail sinkron menjadi yang di-queue. Sekarang setiap kali controller mana pun memanggil `Mail::to(...)->send(new NewCommentEmail(...))`, Laravel secara otomatis menempatkan job di queue alih-alih mengirim seketika. Nama method masih `send()`, tetapi perilakunya berubah secara diam-diam. Ini disengaja: Anda tidak perlu memperbarui setiap caller, hanya class Mailable.

### Step 2: Memverifikasi Controller

Buka `app/Http/Controllers/CommentController.php`. Kode method `store()` dari Lesson 8 tidak perlu berubah. Pemanggilan `send()` yang sama sekarang melakukan queue pada job karena Mailable mengimplementasikan `ShouldQueue`, dan Laravel memeriksa Mailable pada saat dispatch untuk menentukan apakah akan berjalan seketika atau ditunda.

```php
if ($entry->user_id !== $request->user()->id) {
    Mail::to($entry->user)->send(new NewCommentEmail($comment, $entry));
}
```

Laravel memeriksa Mailable dan memilih queueing secara otomatis berdasarkan interface `ShouldQueue`. Ini menjaga kode controller tetap bersih dan tidak menyadari mekanisme penundaan.

---

## 4. Menjalankan Queue Worker

Driver `database` menyimpan job di tabel tetapi tidak memprosesnya sendiri. Sebuah queue worker adalah proses PHP terpisah yang melakukan polling pada tabel `jobs` dan menjalankan job yang tertunda. Pemisahan ini disengaja: web server Anda menangani HTTP request, dan worker menangani background job. Mereka dapat diskalakan secara independen.

### Step 1: Menjalankan Worker

Buka terminal baru (biarkan `php artisan serve` tetap berjalan di yang lain) dan jalankan perintah berikut.

```bash
php artisan queue:work
```

Anda akan melihat output mirip dengan berikut saat job diproses.

```
[2026-04-17 10:30:45] Processing: App\Mail\NewCommentEmail
[2026-04-17 10:30:46] Processed:  App\Mail\NewCommentEmail
```

Proses worker melakukan loop terus-menerus, memeriksa tabel `jobs` setiap beberapa detik. Ketika ia menemukan sebuah job yang tertunda, ia mendeserialisasi dan menjalankannya, mencatat hasilnya, dan beralih ke berikutnya. Biarkan terminal ini tetap terbuka dan berjalan saat Anda menguji queued job.

### Step 2: Memicu Comment

Di browser, kirim sebuah komentar pada entri user lain. Pengiriman form kembali seketika (cepat!) dan menampilkan pesan sukses tanpa penundaan. Beralih ke terminal worker dan Anda seharusnya melihat baris `Processing` dan `Processed` muncul dalam satu atau dua detik, mengonfirmasi email terkirim secara asinkron di background.

### Step 3: Memeriksa Tabel Jobs

Hentikan worker dengan menekan `Ctrl+C`, lalu kirim komentar lain di browser. Buka Tinker untuk memeriksa job yang tertunda di database.

```bash
php artisan tinker
```

Jalankan query berikut untuk melihat baris job.

```php
DB::table('jobs')->count();
DB::table('jobs')->first();
```

`DB::table('jobs')->count()` mengembalikan 1, mengonfirmasi ada satu job yang di-queue tetapi belum diproses. `DB::table('jobs')->first()` menampilkan record lengkap, termasuk sebuah kolom `payload` yang berisi data job yang diserialisasi. Inilah cara queue bertahan dari restart aplikasi: job adalah data yang disimpan di database, bukan kondisi in-memory. Ketik `exit` untuk keluar dari Tinker, lalu jalankan worker lagi dengan `php artisan queue:work`. Ia mengambil dan memproses job yang tertunda seketika.

---

## 5. Membuat Custom Job

Mailable adalah satu jenis queueable job. Custom job adalah jenis lain, berguna untuk pekerjaan background sembarang seperti menghasilkan laporan, memproses upload, atau membersihkan data lama. Custom job lebih fleksibel karena mereka dapat melakukan apa saja, tidak hanya mengirim email.

### Step 1: Membuat Job

Jalankan perintah berikut untuk membuat class job.

```bash
php artisan make:job CleanupOldEntries
```

Perintah ini membuat `app/Jobs/CleanupOldEntries.php` dengan method kerangka `handle()`. Semua job yang dihasilkan oleh `make:job` mengimplementasikan kontrak `ShouldQueue` secara default di versi Laravel yang lebih baru.

### Step 2: Menulis Logika

Buka `app/Jobs/CleanupOldEntries.php` dan perbarui method `handle()` dengan berikut.

```php
<?php

namespace App\Jobs;

use App\Models\Entry;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class CleanupOldEntries implements ShouldQueue
{
    use Queueable;

    public function handle(): void
    {
        $count = Entry::onlyTrashed()
            ->where('deleted_at', '<', now()->subDays(30))
            ->forceDelete();

        \Log::info("Permanently deleted {$count} old entries.");
    }
}
```

Membaca class job ini dengan cermat: `implements ShouldQueue` membuat job ini dapat di-queue, dan trait `Queueable` menyediakan method khusus queue seperti `onQueue()` untuk menentukan queue bernama, `delay()` untuk menjadwalkan job berjalan setelah penundaan, dan `retryUntil()` untuk batas retry berbasis waktu. Method `handle()` adalah entry point dan berisi semua pekerjaan yang sebenarnya. Di dalamnya, `Entry::onlyTrashed()` melingkupi query ke entri yang ter-soft-delete (dari Lesson 4), klausa `where` memfilter entri yang ter-soft-delete lebih dari 30 hari lalu, dan `forceDelete()` menghapusnya secara permanen dari database, melewati soft delete. Nilai return (jumlah baris yang dihapus permanen) dicatat dengan `\Log::info()` sehingga Anda dapat memverifikasi job berjalan dan berapa banyak record yang terpengaruh.

### Step 3: Men-dispatch Job

Buka Tinker dan dispatch job secara manual untuk mengujinya.

```bash
php artisan tinker
```

Jalankan pemanggilan dispatch berikut dari prompt Tinker.

```php
\App\Jobs\CleanupOldEntries::dispatch();
```

Method statis `dispatch()` yang disediakan oleh trait `Queueable` menempatkan job di queue dan kembali seketika. Jika worker berjalan di terminal lain, ia mengambil job dalam beberapa detik dan menjalankan `handle()`. Respons di Tinker adalah `null` karena dispatch bersifat fire-and-forget; ia tidak menunggu job selesai.

### Step 4: Menjadwalkan Job

Job seperti ini sering kali paling baik dijalankan berdasarkan jadwal daripada secara manual. Buka `routes/console.php` dan tambahkan definisi schedule berikut.

```php
use Illuminate\Support\Facades\Schedule;

Schedule::job(new \App\Jobs\CleanupOldEntries)->daily();
```

Untuk menjalankan scheduled job di production, Anda menambahkan satu entri cron yang memanggil `php artisan schedule:run` setiap menit. Scheduler Laravel kemudian memeriksa task mana yang jatuh tempo pada waktu itu (harian, per jam, mingguan, pada hari tertentu) dan men-dispatch-nya. Secara lokal, Anda dapat menjalankan `php artisan schedule:work` untuk menyimulasikan cron runner untuk pengujian tanpa menunggu jam yang sebenarnya.

---

## 6. Menjalankan dan Menguji

Mari kita verifikasi alur queue penuh dari awal hingga akhir.

### Step 1: Menjalankan Worker dengan Output Verbose

Jalankan perintah berikut untuk memulai queue worker dengan detail output tambahan.

```bash
php artisan queue:work --verbose
```

Flag `--verbose` menampilkan detail tambahan tentang setiap job yang diproses, termasuk nama class job dan output apa pun dari `handle()`.

### Step 2: Mengirim Comment

Di browser, kirim sebuah komentar pada entri user lain. Halaman seharusnya melakukan redirect dan menampilkan pesan sukses seketika, sebelum email dikirim.

### Step 3: Mengamati Output Worker

Terminal worker seharusnya menampilkan dua baris konfirmasi.

```
[2026-04-17 10:30:45] Processing: App\Mail\NewCommentEmail
[2026-04-17 10:30:46] Processed:  App\Mail\NewCommentEmail
```

Ini mengonfirmasi email dikirim secara asinkron setelah HTTP request selesai. Periksa `storage/logs/laravel.log` untuk melihat konten email yang dirender dan dikirim oleh driver log.

### Step 4: Menguji Failed Job

Untuk sementara rusak template email dengan sintaks yang tidak valid (misalnya, mereferensikan sebuah variabel yang tidak ada seperti `{{ $nonexistent->foo }}`), kirim sebuah komentar, dan amati worker. Anda seharusnya melihat sebuah pesan error muncul pada setiap percobaan retry. Job di-retry tiga kali secara default, lalu dipindahkan ke tabel `failed_jobs`. Periksa failed job dengan perintah berikut.

```bash
php artisan queue:failed
```

Anda seharusnya melihat daftar failed job dengan ID-nya dan pesan error yang menyebabkan kegagalan. Setelah memperbaiki error template, retry job tertentu berdasarkan ID-nya.

```bash
php artisan queue:retry 1
```

Atau retry semua failed job sekaligus.

```bash
php artisan queue:retry all
```

Perbaiki template sebelum melakukan retry; jika tidak, error yang sama menyebabkan job gagal lagi dan kembali ke tabel failed.

---

## 7. Memperbaiki Error pada Kode Anda

Berikut adalah kesalahan paling umum saat mengimplementasikan queue dan job di Laravel.

**Error 1: Job di-queue tetapi tidak ada yang memprosesnya karena tidak ada worker yang berjalan.**

Error ini terjadi ketika Anda beralih ke queue driver `database` dan men-dispatch job, tetapi lupa bahwa proses worker terpisah diperlukan untuk benar-benar mengeksekusinya. Job menumpuk di tabel `jobs` tanpa batas.

```bash
# Wrong: QUEUE_CONNECTION=database is set, jobs are dispatched, but no worker is running
# Result: jobs pile up in the jobs table, no emails send, no tasks complete

# Correct: run the worker in a separate terminal while testing
php artisan queue:work
```

Tanpa worker yang berjalan, `DB::table('jobs')->count()` bertambah dengan setiap job yang di-dispatch tetapi tidak ada pekerjaan yang dilakukan. Perbaikannya selalu menjalankan `php artisan queue:work` di terminal khusus selama development. Di production, gunakan Supervisor atau systemd untuk menjaga worker tetap berjalan terus-menerus dan me-restart-nya jika crash.

---

**Error 2: Memodifikasi kode job, tetapi worker terus menjalankan versi lama.**

Error ini terjadi ketika Anda mengedit sebuah class job tetapi tidak me-restart worker. Proses worker memuat kode PHP sekali saat startup untuk alasan performa, sehingga ia terus menggunakan versi in-memory dari class lama bahkan setelah Anda menyimpan kode baru ke disk.

```bash
# Wrong: editing CleanupOldEntries.php while the worker is running
# Result: worker processes jobs using the old, unmodified code

# Correct: stop the worker with Ctrl+C after every code change, then restart
php artisan queue:work

# Alternative for development: use queue:listen, which reloads code for every job
php artisan queue:listen
```

Perintah `queue:work` dioptimalkan untuk production (cepat, tanpa reload kode). Perintah `queue:listen` lebih baik untuk development karena ia mem-bootstrap ulang aplikasi untuk setiap job, mengambil perubahan kode secara otomatis. Trade-off-nya adalah `queue:listen` lebih lambat.

---

**Error 3: Men-dispatch job dengan model yang belum disimpan, menyebabkan kegagalan serialisasi.**

Error ini terjadi ketika Anda men-dispatch sebuah job dan meneruskan sebuah model yang tidak pernah disimpan ke database. Trait `SerializesModels` (digunakan oleh trait `Queueable`) menyimpan model berdasarkan primary key-nya dan memuatnya ulang dari database ketika job berjalan. Model yang belum disimpan tidak memiliki primary key, sehingga serialisasi gagal.

```php
// Wrong: dispatching a job with a model that has not been saved yet
$entry = new Entry(['title' => 'Draft', 'content' => 'Not saved']);
CleanupOldEntries::dispatch($entry); // Fails: $entry->id is null

// Correct: always save the model first, then dispatch
$entry = Entry::create(['title' => 'Draft', 'content' => 'Saved']);
CleanupOldEntries::dispatch($entry); // Works: $entry->id is now set
```

Versi yang salah membuat model in-memory tanpa mempersistenkannya. Ketika job diserialisasi untuk queue, `SerializesModels` mencoba menyimpan primary key model, menemukan null, dan entah melemparkan sebuah error atau diam-diam menyimpan referensi null. Ketika worker nanti mencoba memuat ulang model menggunakan ID null itu, ia tidak menemukan apa-apa. Versi yang benar memanggil `create()`, yang menyisipkan baris dan mengatur `id` sebelum dispatch.

---

## 8. Latihan

Terapkan apa yang Anda pelajari dengan mengembangkan setup queue secara independen sebelum memeriksa solusi di bawah.

**Latihan 1:** Buat `WelcomeEmail` dapat di-queue dengan mengimplementasikan `ShouldQueue` padanya. Uji dengan mendaftarkan user baru dan mengonfirmasi HTTP request kembali dengan cepat sementara email diproses di background.

**Latihan 2:** Buat sebuah job `GenerateEntryPDF` yang mengambil sebuah Entry sebagai argumen constructor dan mencatat "PDF generated for entry {title}" di dalam `handle()`. Dispatch ia dari controller store entri setelah membuat sebuah entri.

**Latihan 3:** Gunakan `delay()` untuk menjadwalkan email selamat datang dikirim 1 jam setelah registrasi alih-alih seketika. Gunakan `Mail::to($user)->later(now()->addHour(), new WelcomeEmail($user))`.

---

## 9. Solusi

Bandingkan implementasi Anda dengan yang di bawah. Fokus pada di mana pemanggilan dispatch berada dan bagaimana argumen model diteruskan ke job.

**Solusi untuk Latihan 1:**

Buka `app/Mail/WelcomeEmail.php` dan tambahkan interface `ShouldQueue` ke deklarasi class.

```php
<?php
// ... others lines of code

use Illuminate\Contracts\Queue\ShouldQueue;

class WelcomeEmail extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;
    // ... other methods and properties
}
```

Menambahkan `implements ShouldQueue` adalah satu-satunya perubahan yang diperlukan. Setiap pemanggilan `Mail::to(...)->send(new WelcomeEmail(...))` di alur registrasi sekarang menempatkan email di queue alih-alih mengirim secara sinkron. Untuk mengonfirmasi ia ditunda, daftarkan user baru saat worker berjalan dan amati terminal: respons browser kembali sebelum baris `Processing` muncul, yang membuktikan email tidak memblokir HTTP request.

---

**Solusi untuk Latihan 2:**

Buat class job dengan Artisan.

```bash
php artisan make:job GenerateEntryPDF --no-interaction
```

Buka `app/Jobs/GenerateEntryPDF.php` dan perbarui class dengan sebuah constructor dan statement log di dalam `handle()`.

```php
<?php

namespace App\Jobs;

use App\Models\Entry;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class GenerateEntryPDF implements ShouldQueue
{
    use Queueable;

    public function __construct(public Entry $entry) {}

    public function handle(): void
    {
        \Log::info("PDF generated for entry {$this->entry->title}");
    }
}
```

Lalu buka `app/Http/Controllers/EntryController.php` dan tambahkan pemanggilan dispatch di dalam method `store()`, segera setelah `$entry` dibuat.

```php
<?php
// ... others lines of code

use App\Jobs\GenerateEntryPDF;

class EntryController extends Controller
{
    // ... other methods

    public function store(Request $request): RedirectResponse
    {
        // ... other code
        $entry = auth()->user()->entries()->create($data);
        $entry->tags()->sync($validated['tags'] ?? []);
        GenerateEntryPDF::dispatch($entry);

        return redirect()->route('entries.index');
    }

    // ... other methods
}
```

Constructor menggunakan sintaks promoted property `public` sehingga `$this->entry` tersedia di dalam `handle()` tanpa menulis penugasan terpisah. Perilaku `SerializesModels` (diwarisi dari `Queueable`) menyimpan entri berdasarkan primary key-nya dan memuatnya ulang dari database ketika worker menjalankan job, sehingga `$this->entry` selalu mencerminkan kondisi database saat ini pada waktu eksekusi, bukan kondisi pada waktu dispatch.

---

**Solusi untuk Latihan 3:**

Di controller registrasi, setelah membuat dan login user, ganti pemanggilan `send()` langsung dengan `later()`.

```php
Mail::to($user)->later(now()->addHour(), new WelcomeEmail($user));
```

Method `later()` adalah pembungkus yang nyaman di sekitar `send()` dengan penundaan bawaan. Ia menerima penundaan sebagai argumen pertama (sebuah datetime `Carbon` atau sebuah integer detik) dan Mailable sebagai argumen kedua. Sebagai alternatif, Anda dapat menggunakan sintaks dispatch fluent jika Mailable mengimplementasikan `ShouldQueue`.

```php
dispatch(function () use ($user) {
    Mail::to($user)->send(new WelcomeEmail($user));
})->delay(now()->addHour());
```

Penundaan berarti baris job di tabel `jobs` memiliki timestamp `available_at` di masa depan. Worker memeriksa field ini dan melewati job yang belum tersedia, sehingga email selamat datang tidak dikirim hingga setidaknya satu jam setelah registrasi. Perilaku ini paling andal saat menggunakan driver `database` atau `redis`; driver `sync` mengabaikan penundaan karena ia berjalan secara sinkron dan seketika.

---

## Selanjutnya - Lesson 14

Di lesson ini Anda membangun sebuah alur kerja queue penuh untuk Catatku. Anda beralih dari driver `sync` ke driver `database`, menjalankan `queue:table` dan `migrate` untuk membuat tabel `jobs`, dan mengimplementasikan `ShouldQueue` pada `NewCommentEmail` sehingga notifikasi komentar dikirim secara asinkron tanpa memblokir HTTP request. Anda membuat custom job `CleanupOldEntries`, mempelajari cara men-dispatch-nya dari Tinker dan scheduler, dan menguji alur kerja failed job dengan sengaja merusak template dan menggunakan `queue:failed`, `queue:retry`, serta perbedaan antara `queue:work` (production) dan `queue:listen` (development).

Di Lesson 14, Anda akan mempelajari event dan listener: bagaimana memisahkan efek samping dari controller Anda menggunakan observer pattern Laravel, sehingga menambahkan perilaku baru berarti membuat listener baru alih-alih memodifikasi kode yang sudah ada.
