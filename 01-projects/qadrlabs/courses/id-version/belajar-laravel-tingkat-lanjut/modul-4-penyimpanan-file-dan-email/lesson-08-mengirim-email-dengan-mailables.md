## 1. Sebelum Anda Memulai

Catatku dapat menjadi lebih menarik dengan memberi tahu user tentang aktivitas. Sebuah email selamat datang ketika mereka mendaftar memberi kesan pertama yang positif. Sebuah notifikasi ketika seseorang berkomentar di entri mereka mendorong keterlibatan. Class Mailable Laravel mengenkapsulasi logika email dengan bersih: subject, penerima, template, dan data semuanya diorganisasi dalam satu class, membuat email mudah ditulis, dites, dan dipelihara.

Lesson ini mengajarkan Anda membuat class Mailable, mendesain template email dengan component Markdown Blade, mengonfigurasi mail driver untuk pengujian, dan mengirim email dari controller. Anda akan membangun sebuah email selamat datang dan sebuah email notifikasi komentar untuk Catatku. Di akhir, Anda akan dapat memicu email dari controller Anda dan melakukan pratinjau di browser saat Anda mengembangkan.

### What You'll Build

Anda akan membuat sebuah Mailable `WelcomeEmail` yang dikirim ketika seorang user mendaftar, dan sebuah Mailable `NewCommentEmail` yang dikirim ketika seseorang berkomentar di entri seorang user.

### What You'll Learn

- ✅ Mengonfigurasi mail driver untuk development
- ✅ Membuat class Mailable dengan `make:mail`
- ✅ Template email Blade Markdown
- ✅ Mengirim mail: `Mail::to($user)->send()`
- ✅ Email yang dapat di-queue untuk pengiriman background
- ✅ Melakukan pratinjau email di browser

### What You'll Need

- Lesson 7 sudah selesai

---

## 2. Mengonfigurasi Mail Driver

Selama development, Anda tidak ingin mengirim email sungguhan. Driver `log` menulis email ke `storage/logs/laravel.log` sehingga Anda dapat memeriksanya tanpa server SMTP, yang sempurna untuk melakukan iterasi pada template dan debugging.

### Step 1: Memperbarui .env

Buka file `.env` dan atur konfigurasi mail.

```env
MAIL_MAILER=log
MAIL_FROM_ADDRESS=noreply@catatku.test
MAIL_FROM_NAME="Catatku"
```

Masing-masing variabel ini penting. `MAIL_MAILER=log` memberi tahu Laravel untuk menggunakan driver log, sehingga setiap email yang "terkirim" muncul sebagai blok teks di `storage/logs/laravel.log` alih-alih pergi ke server mail sungguhan. `MAIL_FROM_ADDRESS` dan `MAIL_FROM_NAME` mengatur pengirim default untuk email, sehingga setiap Mailable tidak perlu menentukan pengirim secara eksplisit. Untuk production, Anda akan mengganti `MAIL_MAILER` menjadi `smtp` dengan layanan mail sungguhan seperti Mailgun, Postmark, atau Amazon SES, tetapi driver log ideal selama development.

---

## 3. Membuat Welcome Email

Email selamat datang dikirim segera setelah seorang user mendaftar. Ia menyapa user berdasarkan nama dan menyediakan tombol call-to-action untuk menulis entri pertama mereka.

### Step 1: Membuat Mailable

Jalankan perintah berikut untuk membuat class Mailable dan template email-nya dalam satu langkah.

```bash
php artisan make:mail WelcomeEmail --markdown=emails.welcome
```

Perintah ini membuat dua file sekaligus. Yang pertama adalah `app/Mail/WelcomeEmail.php`, yaitu class Mailable yang mendefinisikan subject, penerima, dan template email. Yang kedua adalah `resources/views/emails/welcome.blade.php`, yaitu konten email yang sebenarnya menggunakan component mail Markdown Laravel. Flag `--markdown=emails.welcome` memberi tahu Artisan untuk menyiapkan file template di path tersebut.

### Step 2: Mendefinisikan Class Mailable

Buka `app/Mail/WelcomeEmail.php` dan ganti kontennya dengan berikut.

```php
<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class WelcomeEmail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public User $user) {}

    public function envelope(): Envelope
    {
        return new Envelope(subject: 'Welcome to Catatku!');
    }

    public function content(): Content
    {
        return new Content(markdown: 'emails.welcome');
    }
}
```

Mari kita telusuri class Mailable ini secara detail. Class meng-extend `Mailable`, yang menyediakan semua fungsi inti email. `use Queueable, SerializesModels;` mencampurkan dua trait: `Queueable` memungkinkan email di-dispatch ke queue background (dibahas di Lesson 13), dan `SerializesModels` menangani model Eloquent dengan benar ketika email diserialisasi untuk di-queue.

Constructor menggunakan constructor property promotion PHP 8: `public User $user` mendeklarasikan sebuah public property dan menugaskannya dari parameter dalam satu baris. Public property pada sebuah Mailable secara otomatis tersedia di Blade template, itulah sebabnya kita menggunakan `public` alih-alih `private` atau `protected`. Method `envelope()` mengembalikan sebuah objek `Envelope` yang mendefinisikan metadata seperti baris subject. Method `content()` mengembalikan sebuah objek `Content` yang menunjuk ke template markdown di `resources/views/emails/welcome.blade.php`.

### Step 3: Menulis Template Email

Buka `resources/views/emails/welcome.blade.php` dan ganti kontennya dengan berikut.

```
<x-mail::message>
# Welcome to Catatku, {{ $user->name }}!

Thank you for joining Catatku. Your personal journal is ready.

Start capturing your thoughts, memories, and ideas. Every entry is private and only visible to you.

<x-mail::button :url="route('entries.create')">
Write Your First Entry
</x-mail::button>

Happy journaling!<br>
{{ config('app.name') }}
</x-mail::message>
```

Menguraikan template ini: component `<x-mail::message>` terluar menyediakan layout email standar dengan header, area konten, dan footer, serta memberinya style untuk rendering yang baik di berbagai email client. Karakter `#` memulai sebuah Markdown heading yang menjadi `<h1>` yang diberi style. Variabel `$user` tersedia karena ia adalah public property pada Mailable. Component `<x-mail::button>` merender sebuah tombol call-to-action yang besar dan diberi style; prop `:url`-nya mengambil sebuah URL route. Helper `config('app.name')` membaca nama app Anda dari konfigurasi. Pemformatan Markdown standar juga bekerja di dalam template: `**bold**` dan `*italic*` didukung.

### Step 4: Mengirim Email saat Registrasi

Buka `app/Http/Controllers/AuthController.php` dan perbarui method `register`. Tambahkan import `WelcomeEmail` dan `Mail` ke bagian atas file bersama statement `use` yang sudah ada, lalu tambahkan dispatch email setelah pemanggilan `Auth::login()` seperti ditunjukkan di bawah ini.

```php
<?php
// ... others lines of code
use App\Mail\WelcomeEmail;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Mail;

class AuthController extends Controller
{
    // ... other methods

    public function register(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'name'     => $validated['name'],
            'email'    => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        Auth::login($user);

        Mail::to($user)->send(new WelcomeEmail($user));

        return redirect()->route('entries.index')
            ->with('success', 'Welcome to Catatku, ' . $user->name . '!');
    }

    // ... other methods
}
```

Membaca method ini: dua statement `use` baru mengimpor class Mailable dan facade Mail. Sisa method, yaitu validasi, pembuatan user, dan login, tetap persis seperti sebelumnya. Satu baris baru, `Mail::to($user)->send(new WelcomeEmail($user))`, ditempatkan langsung setelah `Auth::login($user)` sehingga email selamat datang hanya dipicu setelah akun user ada dan session terbentuk. Method `to()` menerima sebuah model User (Laravel membaca property `email` secara otomatis), sebuah string alamat email, atau sebuah array penerima. Method `send()` mengirim email secara sinkron, artinya request menunggu email selesai sebelum melakukan redirect. Untuk performa yang lebih baik, gunakan `queue()` sebagai gantinya (dibahas di Lesson 13), tetapi `send()` aman selama development saat menggunakan driver log karena ia selesai hampir seketika.

---

## 4. Membuat Email Notifikasi Comment

Email notifikasi komentar memberi tahu penulis entri ketika seseorang mengirim komentar di entri mereka. Ia menyertakan nama pengomentar, konten komentar, dan tautan langsung ke entri.

### Step 1: Membuat Mailable

Jalankan perintah berikut untuk membuat Mailable kedua dan template-nya.

```bash
php artisan make:mail NewCommentEmail --markdown=emails.new-comment
```

Ini mengikuti pola yang sama seperti sebelumnya, membuat baik file class maupun file template secara bersamaan.

### Step 2: Mendefinisikan Mailable

Buka `app/Mail/NewCommentEmail.php` dan ganti kontennya dengan berikut.

```php
<?php

namespace App\Mail;

use App\Models\Comment;
use App\Models\Entry;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class NewCommentEmail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public Comment $comment,
        public Entry $entry,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: "New comment on \"{$this->entry->title}\"",
        );
    }

    public function content(): Content
    {
        return new Content(markdown: 'emails.new-comment');
    }
}
```

Mailable ini mengikuti pola yang sama seperti `WelcomeEmail` tetapi mengambil dua public property: komentar itu sendiri dan entri tempat ia dikirim. Constructor menggunakan promoted property untuk keduanya. `subject` pada envelope menggunakan string berkutip ganda yang menginterpolasi judul entri melalui `$this->entry->title`, sehingga subject email menjadi seperti "New comment on \"My Vacation\"". Ini membantu penerima mengidentifikasi entri bahkan tanpa membuka email.

### Step 3: Menulis Template

Buka `resources/views/emails/new-comment.blade.php` dan tambahkan konten template berikut.

```
<x-mail::message>
# New Comment on "{{ $entry->title }}"

**{{ $comment->user->name }}** commented on your journal entry:

<x-mail::panel>
{{ $comment->body }}
</x-mail::panel>

<x-mail::button :url="route('entries.show', $entry)">
View Entry
</x-mail::button>

Thanks,<br>
{{ config('app.name') }}
</x-mail::message>
```

Template menggunakan dua component mail yang belum Anda lihat. `<x-mail::panel>` merender sebuah kotak yang disorot yang secara visual membedakan teks komentar dari konten pesan di sekitarnya, memudahkan penerima mengidentifikasi apa yang dikatakan. `<x-mail::button>` menautkan ke halaman detail entri sehingga penerima dapat mengeklik langsung ke thread komentar. Markdown `**bold**` menekankan nama pengomentar. Semua variabel (`$entry`, `$comment`) berasal dari public property Mailable.

### Step 4: Mengirim saat Pembuatan Comment

Buka `app/Http/Controllers/CommentController.php` dan perbarui method `store` untuk mengirim notifikasi setelah membuat komentar. Tambahkan import `NewCommentEmail` dan `Mail` ke bagian atas file bersama statement `use` yang sudah ada.

```php
<?php
// ... others lines of code
use App\Mail\NewCommentEmail;
use Illuminate\Support\Facades\Mail;

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

        if ($entry->user_id !== $request->user()->id) {
            Mail::to($entry->user)->send(new NewCommentEmail($comment, $entry));
        }

        return back()->with('success', 'Comment posted!');
    }
}
```

Tambahan kuncinya adalah pemeriksaan `if ($entry->user_id !== $request->user()->id)`. Ini mencegah pengiriman notifikasi ketika user berkomentar di entri mereka sendiri, yang akan menghasilkan trafik email yang tidak perlu dan terasa seperti spam bagi user. Jika pengomentar adalah orang yang berbeda dari penulis entri, `Mail::to($entry->user)` membaca email penulis entri dari model user dan mengirim notifikasi. Relationship `$entry->user` harus dimuat; jika Anda belum melakukan eager load, Eloquent akan menjalankan sebuah query secara otomatis (yang dapat diterima di sini karena ini berjalan sekali per komentar).

> **Perhatikan: notifikasi ini bersifat forward-looking.** Catatku adalah jurnal *privat*: aturan `EntryPolicy@view` dari Lesson 5 membuat halaman detail entri (tempat form komentar berada) hanya terlihat oleh pemilik entri. Itu berarti user *lain* saat ini tidak dapat membuka entri orang lain untuk berkomentar di dalamnya melalui UI, sehingga dalam penjelajahan normal email lintas-user ini tidak pernah dipicu; satu-satunya orang yang dapat menjangkau form adalah pemilik, dan komentar mereka sendiri ditekan oleh guard di atas. Kode notifikasi sudah benar dan kita mengujinya secara langsung di bawah, tetapi ia baru menjadi user-facing setelah entri dapat dibagikan atau dijadikan publik (sebuah fitur lanjutan yang alami). Kita menyimpannya sekarang agar sistem komentar siap untuk hari itu, dan agar Anda dapat melihat pola Mailable + queue lengkap (Lesson 13) beraksi.

---

## 5. Menjalankan dan Menguji

Mari kita verifikasi kedua email bekerja dengan benar dengan melakukan pratinjau di browser dan memeriksa output log.

### Step 1: Pratinjau Email di Browser

Cara tercepat untuk menguji tampilan email adalah dengan melakukan pratinjau langsung di browser tanpa mengirim apa pun. Tambahkan sebuah route pratinjau sementara di bagian bawah `routes/web.php`, di luar group middleware mana pun.

```php
Route::get('/mail-preview/welcome', function () {
    return new \App\Mail\WelcomeEmail(\App\Models\User::first());
});
```

Kunjungi `http://localhost:8000/mail-preview/welcome`. Anda akan melihat email selamat datang yang dirender penuh dengan styling, nama user, dan tombol. Teknik pratinjau ini berfungsi karena class Mailable mengimplementasikan interface `Renderable`. Ketika router melihat sebuah Mailable dikembalikan dari sebuah route closure, ia secara otomatis memanggil `render()` padanya dan mengirim HTML sebagai respons HTTP. Hapus route pratinjau ini sebelum melakukan deploy ke production.

### Step 2: Menguji Pengiriman Email

Daftarkan user baru melalui form registrasi. Lalu periksa file log untuk output email.

```bash
tail -50 storage/logs/laravel.log
```

Perintah `tail -50` menampilkan 50 baris terakhir dari file log. Anda akan melihat konten email tercatat, termasuk baris subject, alamat penerima, dan body HTML. Jika Anda melihat "Welcome to Catatku!" di output, email berhasil di-dispatch melalui driver log.

### Step 3: Menguji Notifikasi Comment

Karena halaman detail entri hanya untuk pemilik (lihat catatan di atas), Anda belum dapat menjangkau form komentar user lain melalui browser, jadi picu notifikasi secara langsung dengan Tinker:

```bash
php artisan tinker
```

```php
$author = \App\Models\User::first();
$entry = $author->entries()->first();
$commenter = \App\Models\User::skip(1)->first(); // any other user
$comment = $entry->comments()->create([
    'body' => 'Nice entry!',
    'user_id' => $commenter->id,
]);
\Illuminate\Support\Facades\Mail::to($entry->user)
    ->send(new \App\Mail\NewCommentEmail($comment, $entry));
```

Sekarang periksa file log. Anda akan melihat sebuah email "New comment on..." yang ditujukan ke alamat email penulis entri, mengonfirmasi notifikasi dirender dan di-dispatch dengan benar.

### Step 4: Memverifikasi Penekanan Self-Comment

Login sebagai User A dan kirim sebuah komentar di salah satu entri Anda sendiri. Periksa file log segera setelahnya. Tidak ada entri email baru yang seharusnya muncul karena kondisi `if ($entry->user_id !== $request->user()->id)` mencegah dispatch ketika pengomentar dan penulis entri adalah orang yang sama.

---

## 6. Memperbaiki Error pada Kode Anda

Berikut adalah kesalahan paling umum saat bekerja dengan class Mailable dan template email di Laravel.

**Error 1: Property Mailable dideklarasikan sebagai private, membuatnya tidak dapat diakses di template.**

Error ini terjadi ketika Anda mendeklarasikan sebuah property pada Mailable sebagai `private` atau `protected`. Hanya property `public` yang secara otomatis diteruskan ke Blade template. Mengakses property non-public di template menghasilkan error "Undefined variable".

```php
// Wrong: private property is invisible to the Blade template
class WelcomeEmail extends Mailable
{
    private User $user;

    public function __construct(User $user)
    {
        $this->user = $user;
    }
}

// Correct: public property is automatically available in the template
class WelcomeEmail extends Mailable
{
    public function __construct(public User $user) {}
}
```

Dengan versi yang salah, template menerima `$user` sebagai null atau melemparkan "Undefined variable $user" karena Laravel hanya meneruskan public property. Versi yang benar menggunakan constructor property promotion PHP 8 untuk mendeklarasikan `$user` sebagai public dalam satu baris, membuatnya tersedia untuk template secara otomatis tanpa pemanggilan `with()` tambahan.

---

**Error 2: Mengirim email dalam sebuah loop dengan `send()`, memblokir web request.**

Error ini terjadi ketika Anda perlu mengirim email ke banyak user sekaligus dan memanggil `Mail::to($user)->send(...)` di dalam sebuah loop foreach. Setiap pemanggilan `send()` membuat koneksi sinkron ke server mail. Sepuluh penerima berarti sepuluh round trip, dan web request tidak kembali sampai kesepuluhnya selesai.

```php
// Wrong: each send() blocks the request until the email is delivered
foreach ($subscribers as $user) {
    Mail::to($user)->send(new Newsletter($user));
}

// Correct: queue() dispatches each email to a background worker
foreach ($subscribers as $user) {
    Mail::to($user)->queue(new Newsletter($user));
}
```

Versi yang salah memanggil `send()` dalam sebuah loop. Untuk 100 subscriber dan server mail yang membutuhkan 200ms per email, request membutuhkan 20 detik. User melihat timeout atau halaman yang sangat lambat. Versi yang benar memanggil `queue()`, yang menambahkan setiap email ke queue dan kembali seketika. Worker background memproses queue secara independen, dan web request selesai dalam milidetik. Lesson 13 membahas penyiapan queue secara penuh dan detail.

---

**Error 3: Tidak ada mail driver valid yang dikonfigurasi, menyebabkan connection error.**

Error ini terjadi ketika `MAIL_MAILER` tidak diatur di `.env` atau diatur ke `smtp` tanpa kredensial SMTP yang valid. Laravel mencoba terhubung ke server mail yang dikonfigurasi dan gagal dengan error koneksi atau authentication.

```env
# Wrong: MAIL_MAILER=smtp without valid credentials causes connection failure
MAIL_MAILER=smtp
MAIL_HOST=smtp.example.com
MAIL_USERNAME=
MAIL_PASSWORD=

# Correct: use log driver during development, no external server needed
MAIL_MAILER=log
MAIL_FROM_ADDRESS=noreply@catatku.test
MAIL_FROM_NAME="Catatku"
```

Tanpa mail driver yang valid, setiap pemanggilan `Mail::to(...)->send(...)` melemparkan sebuah `TransportException` atau error "Connection refused" yang merusak request user. Mengatur `MAIL_MAILER=log` di `.env` beralih ke driver log bawaan, yang tidak memerlukan konfigurasi eksternal. Setiap email yang "terkirim" ditulis ke `storage/logs/laravel.log` sebagai teks, memudahkan pemeriksaan tanpa infrastruktur mail apa pun.

---

## 7. Latihan

Latihan ini memperkuat alur kerja pengembangan email dari lesson ini. Latihan 1 dan 2 mengembangkan template yang sudah Anda bangun. Latihan 3 menghubungkan Catatku ke inbox email sungguhan sehingga Anda dapat menguji rendering HTML di lingkungan mail client yang sebenarnya.

**Latihan 1:** Buat sebuah route pratinjau mail untuk `NewCommentEmail`. Anda perlu mengambil sebuah komentar dan entrinya untuk diteruskan ke constructor: `new NewCommentEmail(Comment::first(), Entry::first())`.

**Latihan 2:** Tambahkan tautan "View your entries" ke footer email selamat datang menggunakan component `<x-mail::subcopy>`.

**Latihan 3:** Ganti mail driver ke Mailtrap (mailtrap.io). Daftar akun gratis, dapatkan kredensial SMTP, dan konfigurasi `.env`. Kirim email tes dan lihat di inbox Mailtrap dengan rendering HTML penuh.

---

## 8. Solusi

Setiap solusi di bawah ini bersifat mandiri. Latihan 1 dan 2 hanya memerlukan penambahan kecil ke file yang sudah ada. Latihan 3 memerlukan akun Mailtrap, tetapi pendaftarannya gratis dan memakan waktu kurang dari dua menit.

**Solusi untuk Latihan 1:**

Tambahkan route pratinjau ke `routes/web.php` bersama route pratinjau welcome.

```php
Route::get('/mail-preview/comment', function () {
    $comment = \App\Models\Comment::with('user')->first();
    $entry = $comment->entry;
    return new \App\Mail\NewCommentEmail($comment, $entry);
});
```

`with('user')` melakukan eager load pada penulis komentar sehingga referensi `$comment->user->name` di template tidak memicu lazy query saat render. `$comment->entry` mengakses entri melalui relationship `belongsTo` yang Anda definisikan di Lesson 1. Mengunjungi `http://localhost:8000/mail-preview/comment` merender HTML email lengkap di browser, termasuk panel dengan body komentar dan tombol yang menautkan ke entri. Hapus kedua route pratinjau sebelum melakukan deploy ke production, karena mereka mengekspos konten email ke pengunjung mana pun tanpa authentication.

---

**Solusi untuk Latihan 2:**

Buka `resources/views/emails/welcome.blade.php` dan tambahkan blok `<x-mail::subcopy>` di bagian bawah, tepat sebelum tag penutup `</x-mail::message>`.

```
<x-mail::message>
# Welcome to Catatku, {{ $user->name }}!

Thank you for joining Catatku. Your personal journal is ready.

<x-mail::button :url="route('entries.create')">
Write Your First Entry
</x-mail::button>

Happy journaling!<br>
{{ config('app.name') }}

<x-mail::subcopy>
You can view all your journal entries here:
[{{ route('entries.index') }}]({{ route('entries.index') }})
</x-mail::subcopy>
</x-mail::message>
```

Component `<x-mail::subcopy>` merender teks abu-abu kecil di bagian bawah email, biasanya digunakan untuk pemberitahuan hukum, tautan unsubscribe, atau navigasi sekunder. Sintaks tautan Markdown `[text](url)` dirender sebagai hyperlink di dalam area subtext. Ini berguna untuk memberi user fallback teks polos ketika tombol yang diberi style tidak dirender dengan benar di email client mereka.

---

**Solusi untuk Latihan 3:**

Daftar akun gratis di mailtrap.io. Setelah login, navigasikan ke "Email Testing" dan buka inbox default Anda. Klik ikon gerigi untuk "SMTP Settings" untuk melihat kredensial Anda. Buka file `.env` Catatku Anda dan ganti konfigurasi mail yang ada dengan berikut, menggantikan username dan password Mailtrap Anda yang sebenarnya.

```env
MAIL_MAILER=smtp
MAIL_HOST=sandbox.smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=your_mailtrap_username
MAIL_PASSWORD=your_mailtrap_password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@catatku.test
MAIL_FROM_NAME="Catatku"
```

`MAIL_MAILER=smtp` mengganti Laravel dari driver log ke koneksi SMTP sungguhan. `sandbox.smtp.mailtrap.io` adalah host sandbox Mailtrap, yang menerima email di port 2525 dan mengarahkannya ke inbox Anda alih-alih ke penerima sungguhan. `MAIL_ENCRYPTION=tls` mengaktifkan keamanan transport untuk koneksi SMTP. Setelah menyimpan `.env`, bersihkan cache konfigurasi sehingga Laravel mengambil nilai baru.

```bash
php artisan config:clear
```

`php artisan config:clear` menghapus konfigurasi yang di-cache sehingga request berikutnya membaca nilai `.env` yang diperbarui. Tanpa langkah ini, Laravel mungkin terus menggunakan driver `log` lama dari cache sebelumnya. Daftarkan user baru melalui form Catatku lalu buka inbox Mailtrap Anda. Email selamat datang seharusnya muncul dalam beberapa detik, dirender penuh dengan baris subject, layout, tombol, dan konten terformat Anda persis seperti yang akan terlihat oleh user sungguhan.

---

## Selanjutnya - Lesson 9

Di lesson ini Anda membangun dua alur kerja email lengkap untuk Catatku. Anda mengonfigurasi mail driver `log` untuk development sehingga semua email keluar ditangkap di file log untuk pemeriksaan tanpa memerlukan server SMTP. Anda membuat class Mailable `WelcomeEmail` dan `NewCommentEmail`, masing-masing dengan template Blade Markdown yang menggunakan component `<x-mail::message>`, `<x-mail::button>`, dan `<x-mail::panel>`. Anda mempelajari cara melakukan pratinjau email di browser dengan mengembalikan sebuah Mailable dari sebuah route closure, dan Anda menambahkan guard self-comment untuk menghindari spam ke user dengan notifikasi tentang aktivitas mereka sendiri.

Di Lesson 9, Anda akan mempelajari cara membangun REST API untuk Catatku: mendesain endpoint JSON yang mengikuti konvensi REST, mengembalikan kode status HTTP yang tepat, dan menguji API Anda dengan curl.
