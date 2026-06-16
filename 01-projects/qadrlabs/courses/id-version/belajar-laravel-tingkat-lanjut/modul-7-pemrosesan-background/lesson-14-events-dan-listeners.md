## 1. Sebelum Anda Memulai

Ketika seorang user mengirim sebuah komentar di Catatku, beberapa hal seharusnya terjadi: menyimpan komentar, mengirim email ke penulis entri, mungkin memperbarui cache "aktivitas terbaru", mungkin mencatatnya untuk analitik. Menjejalkan semua ini ke dalam controller mencampur tanggung jawab yang tidak berhubungan dan membuat controller lebih sulit dibaca dan dites. Event memungkinkan Anda mengumumkan bahwa sesuatu terjadi, dan listener memungkinkan bagian lain dari sistem bereaksi terhadapnya secara independen. Pemisahan ini menjaga setiap potongan kode tetap fokus pada satu tanggung jawab.

Sistem event Laravel mengimplementasikan observer pattern. Kode Anda men-dispatch event pada momen-momen bermakna (seperti "sebuah komentar dikirim"), dan listener menangani efek samping. Listener bersifat independen: menambahkan listener baru tidak memerlukan perubahan pada kode yang men-dispatch event. Ini memudahkan menambahkan fitur seperti notifikasi, analitik, dan caching tanpa menyentuh logika inti. Di akhir lesson ini, Catatku akan menggunakan event alih-alih pemanggilan efek samping langsung, membuat codebase lebih modular dan lebih mudah dikembangkan.

### What You'll Build

Anda akan membuat sebuah event `CommentPosted`, me-refactor CommentController untuk men-dispatch-nya, dan membuat beberapa listener: satu untuk notifikasi email, satu untuk logging, dan satu untuk memperbarui timestamp last-activity.

### What You'll Learn

- ✅ Membuat event dengan `make:event`
- ✅ Membuat listener dengan `make:listener`
- ✅ Mendaftarkan event dan listener
- ✅ Men-dispatch event
- ✅ Listener yang dapat di-queue
- ✅ Model observer (pola event lainnya)

### What You'll Need

- Lesson 13 sudah selesai dengan queue yang berfungsi

---

## 2. Mengapa Event?

Tanpa event, controller memanggil setiap efek samping secara langsung. Contoh berikut menunjukkan sebuah method store yang menangani pembuatan komentar beserta semua efek sampingnya.

```php
public function store(Request $request, Entry $entry)
{
    $comment = $entry->comments()->create([...]);

    if ($entry->user_id !== $request->user()->id) {
        Mail::to($entry->user)->send(new NewCommentEmail($comment, $entry));
    }
    Log::info("Comment posted", ['comment_id' => $comment->id]);
    Cache::forget("user.{$entry->user_id}.activity");

    return back();
}
```

Setiap kali Anda menambahkan sebuah efek samping baru, Anda memodifikasi controller. Method bertumbuh, mencampur kepentingan yang tidak ada hubungannya dengan aksi inti membuat sebuah komentar. Testing menjadi lebih sulit karena satu file test harus mengetahui setiap efek samping. Perubahan apa pun di masa depan (menambahkan notifikasi Slack, menghapus baris cache) memerlukan modifikasi sebuah controller yang seharusnya hanya bertanggung jawab atas penanganan form dan respons HTTP.

Dengan event, controller menjadi jauh lebih sederhana.

```php
public function store(Request $request, Entry $entry)
{
    $comment = $entry->comments()->create([...]);
    CommentPosted::dispatch($comment);
    return back();
}
```

Controller men-dispatch satu event dan kembali. Listener yang terdaftar di tempat lain menangani setiap efek samping. Menambahkan perilaku baru seperti mengirim ke channel Slack berarti membuat sebuah file listener baru, bukan memodifikasi controller. Inilah Open/Closed Principle beraksi: class terbuka untuk ekstensi (tambahkan listener) tetapi tertutup untuk modifikasi (controller tetap tidak berubah).

---

## 3. Membuat Event

Sebuah class event adalah objek PHP biasa yang membawa data tentang apa yang terjadi. Ia tidak memiliki perilaku sendiri; tugasnya adalah menyimpan informasi yang cukup bagi listener untuk bertindak. Di section ini Anda akan membuat event `CommentPosted` dan mendefinisikan data yang dibawanya.

### Step 1: Membuat Class Event

Jalankan perintah berikut untuk membuat class event.

```bash
php artisan make:event CommentPosted
```

Perintah ini membuat `app/Events/CommentPosted.php` dengan struktur kerangka. Sebuah class event pada dasarnya adalah sebuah kontainer data: ia menyimpan informasi yang dibutuhkan listener untuk bereaksi dengan tepat.

### Step 2: Mendefinisikan Event

Buka `app/Events/CommentPosted.php` dan ganti kontennya dengan berikut.

```php
<?php

namespace App\Events;

use App\Models\Comment;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class CommentPosted
{
    use Dispatchable, SerializesModels;

    public function __construct(public Comment $comment) {}
}
```

Mari kita lihat setiap bagian dari class ini dengan cermat. Namespace `App\Events` cocok dengan direktori. Kedua trait menambahkan fungsionalitas penting. `Dispatchable` menyediakan method statis `dispatch()` sehingga Anda dapat memanggil `CommentPosted::dispatch($comment)` dari mana saja di aplikasi. Di balik layar, `dispatch()` membuat sebuah instance baru dari event dan mengirimnya melalui event dispatcher Laravel ke semua listener yang terdaftar. `SerializesModels` menangani serialisasi dengan benar ketika listener mana pun di-queue: ia menyimpan model Eloquent berdasarkan primary key-nya alih-alih sebagai objek in-memory penuh, dan memuatnya ulang dari database ketika listener berjalan. Ini mencegah data model yang basi ketika ada penundaan antara dispatch dan eksekusi. Constructor menggunakan constructor property promotion (`public Comment $comment`) untuk mendeklarasikan dan menugaskan property dalam satu baris. Event membawa komentar sehingga setiap listener memiliki konteks yang dibutuhkannya untuk memutuskan apakah dan bagaimana bereaksi.

---

## 4. Membuat Listener

Setiap listener bertanggung jawab atas persis satu efek samping. Di section ini Anda akan membuat tiga listener untuk event `CommentPosted`: satu yang mengirim email notifikasi, satu yang mencatat aktivitas, dan satu yang memperbarui timestamp last-activity entri. Masing-masing adalah class terpisah sehingga mereka dapat dites, dimodifikasi, dan dihapus secara independen.

### Step 1: Membuat Listener Notifikasi Email

Jalankan perintah berikut untuk membuat listener, yang sudah terhubung sebelumnya untuk menangani event `CommentPosted`.

```bash
php artisan make:listener SendCommentNotification --event=CommentPosted
```

Perintah ini membuat `app/Listeners/SendCommentNotification.php` dengan method kerangka `handle()` yang sudah bertipe untuk event `CommentPosted`. Buka file dan ganti kontennya dengan berikut.

```php
<?php

namespace App\Listeners;

use App\Events\CommentPosted;
use App\Mail\NewCommentEmail;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Mail;

class SendCommentNotification implements ShouldQueue
{
    public function handle(CommentPosted $event): void
    {
        $comment = $event->comment;
        $entry = $comment->entry;

        if ($comment->user_id === $entry->user_id) {
            return;
        }

        Mail::to($entry->user)->send(new NewCommentEmail($comment, $entry));
    }
}
```

Membaca listener ini secara detail: class mengimplementasikan `ShouldQueue`, yang berarti listener ini berjalan di queue ketika event di-dispatch. User yang mengirim komentar tidak menunggu email terkirim; listener ditunda ke worker background. Method `handle()` menerima event `CommentPosted` sebagai parameter (Laravel menyuntikkannya secara otomatis berdasarkan type hint). Di dalamnya, kita mengekstrak komentar dan entri dari event untuk keterbacaan. Pemeriksaan `if ($comment->user_id === $entry->user_id)` kembali lebih awal ketika pengomentar juga penulis entri, mencegah self-notification. Lalu kita mengirim email. Perhatikan bagaimana listener ini berfokus pada persis satu tanggung jawab: memutuskan apakah akan mengirim notifikasi, lalu mengirimnya. Ia tidak melakukan logging, memperbarui timestamp, atau melakukan hal lain apa pun, yang menjaganya tetap dapat dites secara independen.

### Step 2: Membuat Listener Logging

Buat listener logging dengan perintah berikut.

```bash
php artisan make:listener LogCommentActivity --event=CommentPosted
```

Buka `app/Listeners/LogCommentActivity.php` dan ganti kontennya dengan berikut.

```php
<?php

namespace App\Listeners;

use App\Events\CommentPosted;
use Illuminate\Support\Facades\Log;

class LogCommentActivity
{
    public function handle(CommentPosted $event): void
    {
        Log::info('Comment posted', [
            'comment_id' => $event->comment->id,
            'entry_id' => $event->comment->entry_id,
            'user_id' => $event->comment->user_id,
        ]);
    }
}
```

Listener ini lebih sederhana daripada yang sebelumnya. Ia menulis sebuah entri log terstruktur dengan ID yang relevan untuk debugging dan analitik. Perhatikan bahwa ia tidak mengimplementasikan `ShouldQueue`: logging itu cepat (hanya sebuah penulisan file), sehingga tidak ada manfaat menundanya. Listener sinkron berjalan seketika dalam siklus request yang sama, sementara listener yang di-queue berjalan nanti di worker background. Anda memilih per listener berdasarkan apakah pekerjaannya cukup lambat untuk dibenarkan ditunda.

### Step 3: Membuat Listener Update Activity

Buat listener update activity.

```bash
php artisan make:listener UpdateEntryLastActivity --event=CommentPosted
```

Buka `app/Listeners/UpdateEntryLastActivity.php` dan ganti kontennya dengan berikut.

```php
<?php

namespace App\Listeners;

use App\Events\CommentPosted;

class UpdateEntryLastActivity
{
    public function handle(CommentPosted $event): void
    {
        $event->comment->entry->touch();
    }
}
```

Method `touch()` memperbarui timestamp `updated_at` pada entri tanpa memodifikasi kolom lain apa pun. Ini secara efektif menandai entri sebagai baru aktif. Jika Anda mengurutkan entri berdasarkan `updated_at` di halaman index, entri dengan komentar terbaru akan muncul lebih tinggi di daftar. Mengenkapsulasi ini di listener-nya sendiri berarti comment controller tidak memiliki pengetahuan tentang perilaku ini. Jika nanti Anda ingin menggunakan kolom `last_activity_at` khusus sebagai gantinya, Anda hanya mengubah file listener ini.

---

## 5. Mendaftarkan dan Men-dispatch Event

Dengan event dan listener yang sudah dibuat, langkah yang tersisa adalah mendaftarkan listener sehingga Laravel tahu event mana yang mereka tangani, dan memperbarui controller untuk men-dispatch event menggantikan pemanggilan efek samping langsung sebelumnya.

### Step 1: Auto-Discovery Laravel

Laravel 11+ secara otomatis menemukan listener ketika method `handle()`-nya melakukan type-hint pada class event. Ketiga listener yang kita buat melakukan type-hint pada `CommentPosted $event`, sehingga tidak diperlukan pendaftaran manual di sebuah `EventServiceProvider`. Sistem auto-discovery memindai direktori `app/Listeners` dan menghubungkan listener ke event berdasarkan tipe parameter `handle()`. Ini menyederhanakan setup secara signifikan dibandingkan versi Laravel yang lebih lama.

### Step 2: Men-dispatch dari Controller

Buka `app/Http/Controllers/CommentController.php` dan perbarui method `store` untuk men-dispatch event.

```php
<?php
// ... others lines of code

use App\Events\CommentPosted;

class CommentController extends Controller
{
    public function store(Request $request, Entry $entry)
    {
        $validated = $request->validate([
            'body' => 'required|string|min:2|max:1000',
        ]);

        $comment = $entry->comments()->create([
            ...$validated,
            'user_id' => $request->user()->id,
        ]);

        CommentPosted::dispatch($comment);

        return back()->with('success', 'Comment posted!');
    }
}
```

Controller sekarang lebih kecil dan fokus pada tugas intinya: memvalidasi input, membuat komentar, mengumumkan event, dan melakukan redirect. Baris `CommentPosted::dispatch($comment)` memicu event, dan Laravel memberi tahu setiap listener yang terdaftar dalam urutan yang benar. Ketiga listener semuanya berjalan: `LogCommentActivity` berjalan secara sinkron dalam request, `SendCommentNotification` di-queue untuk worker background, dan `UpdateEntryLastActivity` berjalan secara sinkron juga. Yang krusial, controller tidak tahu berapa banyak listener yang ada atau apa yang mereka lakukan. Inilah inti dari arsitektur event-driven.

---

## 6. Model Observer

Pola event lain di Laravel adalah model observer. Observer mendengarkan event lifecycle model: `creating`, `created`, `updating`, `updated`, `deleting`, `deleted`. Alih-alih men-dispatch event secara manual, Laravel memicunya secara otomatis ketika model berubah. Ini berguna untuk logika yang seharusnya selalu berjalan ketika sebuah model dimodifikasi, terlepas dari bagaimana ia dimodifikasi (controller, Tinker, queue job, apa pun).

### Step 1: Membuat Entry Observer

Buat class observer untuk model Entry.

```bash
php artisan make:observer EntryObserver --model=Entry
```

Buka `app/Observers/EntryObserver.php` dan implementasikan dua method lifecycle.

```php
<?php

namespace App\Observers;

use App\Models\Entry;
use Illuminate\Support\Facades\Log;

class EntryObserver
{
    public function created(Entry $entry): void
    {
        Log::info('New entry created', [
            'entry_id' => $entry->id,
            'user_id'  => $entry->user_id,
            'title'    => $entry->title,
        ]);
    }

    public function deleted(Entry $entry): void
    {
        if ($entry->cover_image) {
            \Storage::disk('public')->delete($entry->cover_image);
        }
    }
}
```

Mari kita lihat setiap method. Method `created` berjalan setelah entri berhasil disimpan ke database (nama dalam bentuk lampau menunjukkan event terpicu setelah statement INSERT selesai). Ini adalah momen yang tepat untuk efek samping yang membutuhkan `id` record baru sudah diatur, seperti logging atau memberi tahu sistem lain. Pemanggilan `Log::info()` menulis sebuah entri terstruktur ke `storage/logs/laravel.log` dengan `id`, penulis, dan title entri baru, memberi Anda jejak audit permanen dari setiap entri yang pernah dibuat, tanpa mengubah model `Entry` atau menambahkan kolom ke database.

Method `deleted` berjalan setelah entri dihapus dari database (nama dalam bentuk lampau menunjukkan event terpicu setelah statement DELETE). Kita menggunakan ini untuk membersihkan file cover image dari disk. Ini adalah pola yang ampuh: tidak peduli bagaimana sebuah entri dihapus (dari controller, dari Tinker, dari queue job, dari seeder), pembersihan cover image selalu berjalan karena observer terpasang ke model itu sendiri, bukan ke caller tertentu.

### Step 2: Mendaftarkan Observer

Buka `app/Providers/AppServiceProvider.php` dan daftarkan observer di method `boot()`.

```php
<?php
// ... others lines of code

use App\Models\Entry;
use App\Observers\EntryObserver;

class AppServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        Entry::observe(EntryObserver::class);
        // ... other code
    }
}
```

Pemanggilan `Entry::observe(EntryObserver::class)` mendaftarkan semua method di `EntryObserver` sebagai callback untuk event lifecycle model yang sesuai. Sekarang setiap create atau delete sebuah Entry di mana pun di aplikasi memicu method observer secara otomatis.

---

## 7. Menjalankan dan Menguji

Mari kita verifikasi setiap listener dan observer bekerja dengan benar.

### Step 1: Menjalankan Queue Worker

Jalankan perintah berikut di terminal terpisah untuk memulai queue worker.

```bash
php artisan queue:work
```

Listener `SendCommentNotification` di-queue, sehingga worker perlu berjalan untuk memprosesnya.

### Step 2: Mengirim Comment

Di browser, kirim sebuah komentar pada entri user lain. Verifikasi empat hasil berikut:

- HTTP request selesai dengan cepat dan mengembalikan pesan sukses
- Terminal worker menampilkan listener `SendCommentNotification` sedang diproses
- `storage/logs/laravel.log` berisi entri log dari `LogCommentActivity`
- `updated_at` entri mencerminkan timestamp baru (periksa di Tinker dengan `Entry::find($id)->updated_at`)

Masing-masing dari ini adalah hasil dari satu listener yang melakukan satu tugasnya, semuanya dipicu dari satu pemanggilan `CommentPosted::dispatch($comment)`.

### Step 3: Menguji Observer

Buka Tinker untuk menguji observer.

```bash
php artisan tinker
```

Buat sebuah entri baru dan konfirmasi observer terpicu.

```php
$user = \App\Models\User::first();
$entry = $user->entries()->create([
    'title'   => 'My Vacation Photos',
    'content' => 'A great trip.',
]);
```

Setelah ini berjalan, buka `storage/logs/laravel.log` dan cari entri log yang ditulis oleh method observer `created`. Anda seharusnya melihat sebuah baris yang berisi `"New entry created"` dengan `id`, `user_id`, dan `title` entri. Sekarang hapus entri dan konfirmasi observer `deleted` terpicu.

```php
$entry->delete();
```

Method `deleted` berjalan. Jika entri memiliki sebuah path `cover_image` yang tersimpan, file akan dihapus dari public disk secara otomatis. Ketik `exit` untuk keluar dari Tinker.

---

## 8. Memperbaiki Error pada Kode Anda

Berikut adalah kesalahan paling umum saat bekerja dengan event, listener, dan observer di Laravel.

**Error 1: Event di-dispatch tetapi tidak terjadi apa-apa karena type hint listener tidak cocok.**

Error ini terjadi ketika auto-discovery mengandalkan type hint method `handle()` untuk menghubungkan listener ke event. Jika class event diubah namanya, atau namespace import salah, type hint tidak cocok dan listener tidak pernah terdaftar.

```php
// Wrong: listener type-hints an old or wrong event class name
use App\Events\CommentCreated; // The actual event is CommentPosted

class SendCommentNotification
{
    public function handle(CommentCreated $event): void { ... }
}

// Correct: listener type-hints the exact event class that is dispatched
use App\Events\CommentPosted;

class SendCommentNotification
{
    public function handle(CommentPosted $event): void { ... }
}
```

Versi yang salah melakukan type-hint pada `CommentCreated`, yang tidak ada atau bukan yang Anda dispatch. Scanner auto-discovery Laravel mencari listener yang tipe parameter `handle()`-nya cocok dengan class event yang di-dispatch. Ketidakcocokan berarti listener sepenuhnya tidak terlihat oleh sistem. Perbaikannya adalah memastikan class yang di-type-hint adalah class persis yang Anda dispatch dengan `CommentPosted::dispatch(...)`.

---

**Error 2: Listener sinkron melemparkan sebuah exception, membuat HTTP request crash.**

Error ini terjadi ketika sebuah listener berjalan secara sinkron (tidak mengimplementasikan `ShouldQueue`) dan melemparkan sebuah exception yang tidak ditangani. Karena listener sinkron berjalan di dalam siklus HTTP request, exception mereka merambat ke user sebagai error 500.

```php
// Wrong: synchronous listener throws an exception during the user's request
class NotifySlack
{
    public function handle(CommentPosted $event): void
    {
        // If the Slack API is down, this throws and the user sees a 500 error
        Http::post('https://hooks.slack.com/...', [...]);
    }
}

// Correct: implement ShouldQueue so exceptions go to failed_jobs, not to the user
class NotifySlack implements ShouldQueue
{
    public function handle(CommentPosted $event): void
    {
        Http::post('https://hooks.slack.com/...', [...]);
    }
}
```

Versi yang salah adalah sebuah listener sinkron yang memanggil sebuah API eksternal. Jika API tersebut tidak tersedia, exception menggelembung naik melalui event dispatcher ke dalam controller dan kembali ke user sebagai halaman 500. Versi yang benar mengimplementasikan `ShouldQueue`, sehingga listener berjalan di queue worker. Jika API Slack mati, job gagal dan masuk ke `failed_jobs`, di mana ia dapat di-retry setelah API pulih, tanpa pernah menampilkan error ke user asli.

---

**Error 3: Model observer tidak terpicu saat menggunakan mass update pada query builder.**

Error ini terjadi ketika Anda memanggil `update()` atau `delete()` pada sebuah query builder (bukan pada instance model individual). Method query-builder melewati lifecycle model sepenuhnya demi performa, yang berarti tidak ada method observer yang terpicu.

```php
// Wrong: mass update on the query builder bypasses model events
Entry::where('draft', true)->update(['published' => true]);
// The "updating" and "updated" observer methods DO NOT fire

// Correct: iterate and update each model instance to trigger observer events
Entry::where('draft', true)->get()->each(function ($entry) {
    $entry->update(['published' => true]);
});
```

Versi yang salah menjalankan satu statement SQL `UPDATE` yang memodifikasi semua baris yang cocok tanpa menginstansiasi objek model Eloquent apa pun. Karena tidak ada objek model yang ada, tidak ada event lifecycle yang terpicu. Versi yang benar mengambil model dengan `get()`, lalu mengiterasinya dengan `each()`, memanggil `update()` pada setiap instance model individual. Ini memicu method observer `updating` dan `updated` untuk setiap entri. Trade-off-nya adalah ini menjalankan satu query per entri alih-alih satu query massal, jadi gunakan ini hanya ketika logika observer secara wajar perlu berjalan.

---

## 9. Latihan

Berlatihlah dengan pola event dan observer secara independen menggunakan pola dari lesson ini sebelum memeriksa solusinya.

**Latihan 1:** Buat sebuah event `EntryCreated` yang di-dispatch ketika sebuah entri baru disimpan. Buat sebuah listener yang mengirim email konfirmasi "Your entry was published" ke penulis.

**Latihan 2:** Tambahkan sebuah method `updating` ke `EntryObserver` yang mencatat title lama dan baru ketika title berubah. Gunakan `$entry->isDirty('title')` dan `$entry->getOriginal('title')` untuk mendeteksi dan membaca nilai lama.

**Latihan 3:** Buat sebuah event `UserRegistered` dan sebuah listener `SendWelcomeEmail`. Dispatch event dari controller registrasi untuk menggantikan pemanggilan `Mail::to($user)->send(...)` langsung dengan versi event-driven.

---

## 10. Solusi

Bandingkan implementasi Anda dengan yang di bawah. Perhatikan listener mana yang mengimplementasikan `ShouldQueue` dan mengapa.

**Solusi untuk Latihan 1:**

Buat event dan listener dengan perintah berikut.

```bash
php artisan make:event EntryCreated --no-interaction
php artisan make:listener SendEntryPublishedEmail --event=EntryCreated --no-interaction
```

Buka `app/Events/EntryCreated.php` dan ganti kontennya dengan berikut.

```php
<?php

namespace App\Events;

use App\Models\Entry;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class EntryCreated
{
    use Dispatchable, SerializesModels;

    public function __construct(public Entry $entry) {}
}
```

Buka `app/Listeners/SendEntryPublishedEmail.php` dan ganti kontennya dengan berikut.

```php
<?php

namespace App\Listeners;

use App\Events\EntryCreated;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Mail;

class SendEntryPublishedEmail implements ShouldQueue
{
    public function handle(EntryCreated $event): void
    {
        Mail::to($event->entry->user)->send(
            new \App\Mail\WelcomeEmail($event->entry->user)
        );
    }
}
```

Buka `app/Http/Controllers/EntryController.php` dan dispatch event di method `store()` setelah membuat entri.

```php
<?php
// ... others lines of code

use App\Events\EntryCreated;

class EntryController extends Controller
{
    // ... other methods

    public function store(Request $request): RedirectResponse
    {
        // ... other code
        $entry = auth()->user()->entries()->create($data);
        $entry->tags()->sync($validated['tags'] ?? []);
        EntryCreated::dispatch($entry);

        return redirect()->route('entries.index');
    }

    // ... other methods
}
```

Listener mengimplementasikan `ShouldQueue` karena pengiriman email adalah operasi jaringan yang seharusnya tidak memblokir HTTP request. Event membawa model `Entry` penuh dengan `SerializesModels`, sehingga `$event->entry->user` dimuat ulang dari database ketika listener yang di-queue berjalan, memberi Anda record penulis saat ini alih-alih salinan in-memory yang basi.

---

**Solusi untuk Latihan 2:**

Tambahkan method berikut ke `app/Observers/EntryObserver.php`.

```php
<?php
// ... others lines of code

class EntryObserver
{
    // ... other methods

    public function updating(Entry $entry): void
    {
        if ($entry->isDirty('title')) {
            \Log::info('Entry title changed', [
                'entry_id' => $entry->id,
                'old' => $entry->getOriginal('title'),
                'new' => $entry->title,
            ]);
        }
    }

    // ... other methods
}
```

Method `isDirty('title')` mengembalikan `true` hanya ketika attribute title diubah sejak model dimuat dari database. Ini mencegah logging ketika sebuah edit menyimpan field lain (seperti content atau tag) tanpa menyentuh title. `getOriginal('title')` mengembalikan title sebagaimana adanya ketika model diambil dari database, sebelum mutasi in-memory apa pun. `$entry->title` adalah nilai baru yang akan dipersistenkan. Kedua nilai dicatat bersama dalam sebuah array terstruktur sehingga Anda dapat melacak setiap perubahan title di `storage/logs/laravel.log` tanpa melakukan query ke database.

---

**Solusi untuk Latihan 3:**

Buat event dan listener dengan perintah berikut.

```bash
php artisan make:event UserRegistered --no-interaction
php artisan make:listener SendWelcomeEmail --event=UserRegistered --no-interaction
```

Buka `app/Events/UserRegistered.php` dan ganti kontennya dengan berikut.

```php
<?php

namespace App\Events;

use App\Models\User;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class UserRegistered
{
    use Dispatchable, SerializesModels;

    public function __construct(public User $user) {}
}
```

Buka `app/Listeners/SendWelcomeEmail.php` dan ganti kontennya dengan berikut.

```php
<?php

namespace App\Listeners;

use App\Events\UserRegistered;
use App\Mail\WelcomeEmail;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Mail;

class SendWelcomeEmail implements ShouldQueue
{
    public function handle(UserRegistered $event): void
    {
        Mail::to($event->user)->send(new WelcomeEmail($event->user));
    }
}
```

Buka `app/Http/Controllers/AuthController.php` dan perbarui method `register()` untuk men-dispatch event menggantikan pemanggilan `Mail::to(...)` langsung.

```php
<?php
// ... others lines of code

use App\Events\UserRegistered;

class AuthController extends Controller
{
    // ... other methods

    public function register(Request $request): RedirectResponse
    {
        // ... other code
        Auth::login($user);
        UserRegistered::dispatch($user);

        return redirect()->route('entries.index');
    }

    // ... other methods
}
```

Pemanggilan `Mail::to(...)` dihapus dari controller sepenuhnya. Controller sekarang tidak memiliki pengetahuan tentang email selamat datang atau efek samping registrasi lainnya. Menambahkan efek samping di masa depan (seperti membuat entri default atau memberi tahu admin) hanya memerlukan sebuah listener baru, bukan perubahan controller. `ShouldQueue` pada listener berarti email selamat datang ditunda ke worker background, menjaga redirect registrasi tetap cepat.

---

## Selanjutnya - Lesson 15

Di lesson ini Anda memisahkan efek samping komentar Catatku menggunakan sistem event Laravel. Anda membuat event `CommentPosted` sebagai kontainer data sederhana yang membawa model komentar, me-refactor `CommentController@store` untuk men-dispatch-nya dengan satu pemanggilan `CommentPosted::dispatch($comment)`, dan mengimplementasikan tiga listener independen: `SendCommentNotification` (di-queue, mengirim email ke penulis entri), `LogCommentActivity` (sinkron, menulis log terstruktur), dan `UpdateEntryLastActivity` (sinkron, men-touch timestamp entri). Anda juga membangun `EntryObserver` untuk secara otomatis mencatat entri baru di hook `created` dan membersihkan cover image di hook `deleted`, yang didaftarkan di `AppServiceProvider`, sehingga perilaku ini berjalan untuk setiap modifikasi entri terlepas dari sumbernya.

Di Lesson 15, Anda akan mempelajari Blade component: mengemas UI yang dapat digunakan kembali ke dalam tag `<x-component>` bernama dengan prop, slot, dan attribute pass-through, sehingga perubahan desain memerlukan pengeditan satu file alih-alih mencari di setiap view.
