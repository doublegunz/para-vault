---
title: "Belajar Laravel 8: Kirim Email Dengan Queue"
slug: "belajar-laravel-8-kirim-email-dengan-queue"
category: "Laravel"
date: "2022-02-05"
status: "published"
---

Beberapa waktu yang lalu saya menangani sebuah project, di mana salah satu fitur dalam project ini memerlukan pengiriman informasi melalui email. Setelah membaca dokumentasi resmi Laravel, saya coba membuat aplikasi sederhana dengan fitur mengirimkan email menggunakan Laravel. Dan ternyata mengirimkan email itu amat mudah dan gak ribet, karena Laravel sudah menyediakan API yang mudah digunakan. Akan tetapi ketika saya coba menggabungkan dengan fitur dalam project, ternyata waktu respon aplikasinya menjadi lumayan lama. Untuk mengurangi waktu respon tersebut, saya memilih memecah proses bisnis utama dan menggunakan queue untuk kirim email di *background process*. Untuk mencoba solusi sebelum saya implementasikan dalam project, saya coba rombak kembali aplikasi hasil belajar laravel 8 sebelumnya, mengubah proses untuk mengirimkan email menggunakan queue. Dan hasilnya waktu respon aplikasi menjadi lebih cepat.

Sama halnya seperti membuat fitur untuk mengirim email, Untuk queue proses kirim email pun laravel sudah menyediakan built-in API yang menangani queue. Contoh penggunaannya adalah dengan menggunakan `queue` method di dalam `Mail` facade setelah menuliskan penerima pesan.

```php
Mail::to($request->user())
    ->cc($moreUsers)
    ->bcc($evenMoreUsers)
    ->queue(new OrderShipped($order));
```

Sebagai catatan hasil [belajar Laravel 8](https://qadrlabs.com/series/belajar-laravel-8), saya coba menuliskan kembali dokumentasi hasil belajar dengan contoh aplikasi yang lebih sederhana dan fokus pada `queue` untuk kirim email.

**Catatan:** Per tanggal 30 September 2025, tutorial ini diujicoba juga menggunakan laravel 12 dan hasil dari uji coba tutorial ini masih dapat digunakan. Yang menjadi perbedaan adalah struktur Mailable (kelas email) mengalami perubahan signifikan dibandingkan dengan Laravel 8. Untuk menampilkan file view pesan email pada `app/Mail/SendEmailTest.php` pada laravel 8 terdapat pada method `build()`, sedangkan pada laravel 12 bisa ditambahkan pada method `content()`. Sebagai contoh, berikut kode method `build()` pada laravel 8.
```php
    public function build()
    {
        return $this->view('emails.send');
    }
```
Untuk laravel 12, berikut code method `content()`
```php
    public function content(): Content
    {
        return new Content(
            view: 'emails.send',
        );
    }
```

## Persiapan{#persiapan}
Karena studi kasusnya adalah mengirimkan email, sudah pasti kita perlu email yang digunakan untuk keperluan uji coba. Sewaktu belajar Laravel 8 untuk mengirimkan email, saya pakai SMTP dari hosting provider yang saya gunakan. Sebagai alternatif, kita juga bisa pakai SMTP gmail. Untuk menggunakan SMTP  Gmail kita bisa gunakan email gmail kita dan juga app password gmail. App Password gmail bisa kamu dapatkan dengan membaca tutorial [mengirim email sebelumnya pada Step 1 - Setup App password Gmail](https://qadrlabs.com/post/mengirim-email-via-gmail-smtp-menggunakan-email-library-codeigniter#step-1). 

## Step 1 - Install Project Baru{#step-1}
Pertama kita buat dulu project laravel dengan nama `belajar-queue-email` menggunakan `composer`.
```bash
composer create-project laravel/laravel:^8.0 belajar-queue-email
```

Setelah selesai, masuk ke direktori project.
```bash
cd belajar-queue-email
```

## Step 2 - Setup Konfigurasi Email dan Database{#step-2}
Database dan email diperlukan pada saat queue dan pengiriman email. Sekarang kita edit konfigurasinya di file `.env`, kita tambahkan credential mysql dan email yang akan digunakan.

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_email_queue
DB_USERNAME=root
DB_PASSWORD=password

MAIL_MAILER=smtp
MAIL_DRIVER=smtp
MAIL_HOST=mail.yourdomain.com
MAIL_PORT=465
MAIL_USERNAME=username@yourdomain.com
MAIL_PASSWORD=yoursecretpassword
MAIL_ENCRYPTION=ssl
MAIL_FROM_ADDRESS=no-reply@yourdomain.com
MAIL_FROM_NAME="${APP_NAME}"
```

## Step 3 - Create Mailable class{#step-3}
Berdasarkan dokumentasi resmi Laravel, setiap jenis pengiriman email oleh aplikasi yang dibangun menggunakan Laravel disebut `Mailable` class. Kita akan generate class ini menggunakan `artisan command`. Buka kembali terminal, lalu run command ini untuk generate `Mailable` class.

```shell
php artisan make:mail SendEmailTest
```

Setelah selesai generate, kita bisa temukan file baru `SendEmailTest.php` di direktori `app/Mail`. Buka file `SendEmailTest.php`, lalu kita sesuaikan `view` dengan kebutuhan project sederhana kita.

```php
<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class SendEmailTest extends Mailable
{
    use Queueable, SerializesModels;

    /**
     * Create a new message instance.
     *
     * @return void
     */
    public function __construct()
    {
        //
    }

    /**
     * Build the message.
     *
     * @return $this
     */
    public function build()
    {
        return $this->view('emails.send');
    }
}

```

Di baris kode di atas, di method `build()`, kita gunakan template untuk email yang akan kita kirim. Kita buat folder baru `resources/views` dengan nama `emails`. Selanjutnya kita buat file baru dengan nama `send.blade.php`.

```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Send Email Tutorial @ qadrLabs.com</title>
</head>

<body>
<h2>Test Send Email</h2>
<p>Ini adalah email uji coba</p>

</body>

</html>

```

Karena email uji coba, jadi isinya kita buat sesederhana mungkin.

## Step 4 - Setup Queue{#step-4}
Pada tahapan berikutnya adalah mengatur konfigurasi `queue`. Buka kembali file `.env`, lalu kita atur `database` sebagai `queue` driver.

```
QUEUE_CONNECTION=database
```

Setelah itu, untuk menangani queue, kita generate file migration menggunakan `artisan command`.

```shell
php artisan queue:table
```

Kita bisa lihat ada file migration baru. Selanjutnya kita run migration menggunakan `artisan command`.
```shell
php artisan migrate
```

## Step 5 - Create Queue Job{#step-5}
Langkah selanjutnya adalah membuat class yang akan menangani `queue`.  Buka kembali terminal lalu run command berikut ini.
```shell
php artisan make:job SendEmailJob
```

Setelah command kita run, ada file baru `SendEmailJob.php` di direktori `app/Jobs`. Buka file `SendEmailJob.php`, lalu kita sesuaikan.

```php
<?php

namespace App\Jobs;

use App\Mail\SendEmailTest;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Mail;

class SendEmailJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $sendMail;

    /**
     * Create a new job instance.
     *
     * @return void
     */
    public function __construct($sendMail)
    {
        $this->sendMail = $sendMail;
    }

    /**
     * Execute the job.
     *
     * @return void
     */
    public function handle()
    {
        $email = new SendEmailTest();
        Mail::to($this->sendMail)->send($email);
    }
}

```

Pada baris kode di atas, kita bisa lihat file yang di-generate menggunakan command `make:job` merupakan implementasi dari `Illuminate\Contracts\Queue\ShouldQueue` class, menunjukan pada Laravel, proses yang ada di class ini harus dipush ke `queue` untuk diproses secara asynchronous. Pada method `handle()`, kita definisikan job yang akan diproses di `queue` dan sebagai studi kasus di tulisan ini, kita akan mencoba mengirimkan email.

## Step 6 - Set Route{#step-6}
Langkah selanjutnya adalah mengatur route untuk menghandle proses uji coba `queue`. Buka file `routes/web.php`, lalu kita definisikan route.

```php 
Route::get('test/send-email', function () {
    $sendMail = 'emailtujuan@domain.com';
    dispatch(new \App\Jobs\SendEmailJob($sendMail));

    dd('send email on progress...');
});
```

Di sini kita tidak membuat controller untuk proses menambahkan `queue`, kita definisikan langsung prosesnya di dalam route. Tentu untuk project sebenarnya, kita bisa membuat controller yang menangani proses ini. Pada baris kode di atas, kita menggunakan `dispatch()` untuk push job ke `queue`.


## Step 7 - Uji Coba{#step-7}
Buka kembali terminal, lalu kita run command.
```bash
php artisan serve
```

Untuk run `queue worker` dan mengeksekusi job yang sudah ada atau dipush ke `queue`, kita akan menggunakan `artisan` command. 

```bash
php artisan queue:listen
```

Baik persiapan uji coba sudah selesai, built-in server dan queue worker sudah kita start. Selanjutnya kita coba push job untuk mengirimkan email ke `queue`. Buka browser, lalu buka url yang sudah kita definisikan sebelumnya di route.
``` 
http://127.0.0.1:8000/test/send-email
```

Setelah kita buka url di atas di browser, kita buka kembali terminal. Kita bisa lihat output seperti ini di terminal:
```shell
➜ belajar-queue-email (master) ✗ php artisan queue:listen
[2022-01-02 03:20:44][1] Processing: App\Jobs\SendEmailJob
[2022-01-02 03:20:45][1] Processed:  App\Jobs\SendEmailJob

```

Pada output di atas, kita bisa lihat ada job yang diproses di background yaitu `App\Jobs\SendEmailJob`, yang ada diantrian pertama atau `[1]`. Job ini diproses pada pukul `03:20:44` dan selesai pada pukul `03:20:45` tanda email selesai dikirim. Kalau kita buka kembali urlnya di browser, atau yang tadi kita refresh, kita bisa lihat job yang diproses, urutannya, dan juga waktu diprosesnya secara berurutan.

Setelah selesai proses kirim email di background process, kita bisa cek email yang terkirim, di email yang kita definisikan sebagai email penerima atau variable `$sendEmail` di route.
```php
    $sendMail = 'emailtujuan@domain.com';
    dispatch(new \App\Jobs\SendEmailJob($sendMail));
```

## Penutup{#penutup}
Mengirimkan email dapat mempengaruhi waktu respon aplikasi yang kita kembangkan. Sebagai solusinya kita bisa menggunakan `queue` untuk menangani fitur kirim email untuk diproses di background process. Membuat fitur kirim email maupun `queue` itu lumayan kompleks, kabar baiknya Laravel sudah menyediakan API untuk menangani keduanya. Dan di tulisan ini kita sudah belajar bagaimana cara mengirim email dengan queue, di mana email tersebut akan dikirimkan setelah job dieksekusi di background process.