---
title: "Tutorial Laravel: Kirim Email Menggunakan SMTP Gmail"
slug: "tutorial-laravel-kirim-email-menggunakan-smtp-gmail"
category: "Laravel"
date: "2024-04-24"
status: "published"
---

Ketika scrolling di salah satu grup framework laravel yang saya ikuti terdapat pertanyaan dari salah satu member mengenai error ketika mengirim email menggunakan SMTP Gmail. Dan poin inti dari pertanyaan tersebut adalah apakah SMTP Gmail masih dapat digunakan untuk mengirim email atau tidak. Mengingat sering kali pertanyaan ini ditanyakan di grup cukup membuat saya penasaran. Jadi, di edisi tutorial laravel kali ini kita akan coba membuat fitur kirim email menggunakan SMTP Gmail.

## Overview{#overview}
Pada tutorial laravel kali ini kita akan coba membuat fitur untuk mengirim email menggunakan SMTP Gmail. Untuk menggunakan SMTP Gmail, nanti teman-teman akan belajar bagaimana cara setup akun gmail supaya dapat digunakan untuk mengirim email. Selanjutnya kita setup project laravel baru dan coding fitur kirim email. Setelah itu kita uji coba kirim email menggunakan SMTP Gmail.

## Persiapan{#persiapan}
Selain persiapan umum untuk develop project menggunakan laravel, untuk mengikuti tutorial ini teman-teman perlu menyediakan:
1. Akun Gmail
2. nomor hp aktif yang akan kita gunakan untuk proses 2-step verification. 2-Step verification ini adalah syarat untuk mengaktifkan App Password Gmail.

## Step 1 - Setup App password Gmail{#step-1}
Pada step 1 ini kita coba atur konfigurasi gmail supaya dapat kita gunakan untuk mengirim email. Berikut ini adalah langkah-langkahnya:

1. Login ke dalam akun Google kita
2. Setelah itu, masuk ke halaman [My Account](https://myaccount.google.com/). Kemudian kita pilih menu [Security](https://myaccount.google.com/security). 
3. Pada halaman ini terdapat panel `How you sign in to Google` yang memiliki beberapa pilihan yaitu 2-Step Verification, passkeys and security keys dan pengaturan lainnya. Di sini kita harus aktifkan 2-Step Verification untuk mendapatkan App Password yang nanti akan kita gunakan untuk mengirim email.

![Menu Security di akun google](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/send-email-via-gmail-smtp/1-halaman-security-gmail-en.png)

4. Klik 2-Step Verification untuk mengaktifkan fitur ini. Lalu ikuti langkah-langkahnya dimulai dari klik Get Started, setelah itu kita akan diminta memasukan password untuk melanjutkan. Pada halaman berikutnya kita akan diminta memasukan nomer telepon hp yang masih aktif. Di sini kita masukan nomer hp aktif, setelah itu kita pilih sms atau telepon untuk menerima kode pin dari google. Sebagai contoh di sini saya coba pilih sms dan langsung mendapat sms berisi kode pin. Setelah kita dapat sms berisi kode pin, kita coba konfirmasi bahwa nomer masih aktif dengan memasukan kode PIN yang dikirimkan google melalui sms ataupun telepon.
5. Setelah konfirmasi nomer hp berhasil, selanjutnya aktifkan 2-Step Verification dengan klik link AKTIFKAN. 
6. Sekarang kita kembali lagi ke halaman pengaturan [Security](https://myaccount.google.com/security). Lalu klik 2-Step Verification.
7. Pada halaman 2-step verification, kita bisa lihat pengaturan App passwords. Kita klik tanda `>` di App Passwords untuk menambahkan App Passwords baru.
![Halaman 2-step verification](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/send-email-via-gmail-smtp/2-halaman-2-step-verification.png)

	**Catatan:** apabila menu tersebut tidak ditemukan, bisa akses langsung [https://myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)

8. Sekarang kita coba generate password baru untuk project kirim email laravel 11. Di bagian form create new app specific password, kita coba isi dengan value `Tutorial Kirim Email qadrLabs`. Setelah itu klik tombol `Create` untuk memulai proses generate password yang baru. 
![Buat app password baru](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/send-email-via-gmail-smtp/3-create-app-specific-password.png)

9. Setelah itu kita bisa lihat ada password hasil generate.

```
Your app password for your device
xxxjxxkxxlnxxnn
```

Passwordnya kita catat dulu karena kalau di close nanti password hasil generatenya di-hidden, seperti yang terlihat di gambar berikut ini.
![App Password berhasil dibuat](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/send-email-via-gmail-smtp/4-password-berhasil-dibuat.png)

Password yang bisa kita gunakan untuk projek kirim email sudah kita dapatkan, sekarang kita sudah bisa pakai Gmail SMTP untuk mengirim email dari aplikasi laravel kita.

## Step 2 - Buat Project laravel{#step-2}
Sekarang kita buat project laravel baru menggunakan composer.
```
composer create-project --prefer-dist laravel/laravel laravel-send-mail
```

Tunggu sampai proses buat project laravel selesai.

## Step 3 - Atur Konfigurasi Project{#step-3}
Selanjutnya kita masuk ke direktori project

```
cd laravel-send-mail
```

Lalu, kita buka file `.env` di code editor, kemudian kita sesuaikan konfigurasi emailnya.

```
MAIL_MAILER=smtp
MAIL_HOST=smtp.googlemail.com
MAIL_PORT=587
MAIL_USERNAME=email_gmail_kamu@gmail.com
MAIL_PASSWORD=app_password_hasil_generate_tanpa_space
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="qadrlabs Tutorial"
```

Pada bagian `MAIL_PASSWORD`, kita masukkan password yang sudah kita buat di step sebelumnya tanpa ada spasi.

Setelah selesai kita save kembali file `.env`.

## Step 4 - Generate dan Modifikasi Mailable Class{#step-4}
Mailable class adalah istilah untuk setiap email yang dikirim melalui aplikasi laravel kita. Sekarang kita generate mailable class baru dengan nama `SendEmail`. Buka terminal, lalu kita run command berikut ini.

```
php artisan make:mail SendEmail
```

Output di terminal:
```
  INFO  Mailable [app/Mail/SendEmail.php] created successfully. 
```

Sekarang kita buka file `app/Mail/SendEmail.php`, lalu kita modifikasi menjadi baris kode berikut ini.

```php
<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class SendEmail extends Mailable
{
    use Queueable;
    use SerializesModels;
    public $data; // tambahkan ini

    /**
     * Create a new message instance.
     */
    public function __construct($data)
    {
        $this->data = $data; // tambahkan ini
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        return new Envelope(
            subject: $this->data['subject'], // tambahkan ini
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            view: 'emails.send_email', // tambahkan ini
        );
    }

    /**
     * Get the attachments for the message.
     *
     * @return array<int, \Illuminate\Mail\Mailables\Attachment>
     */
    public function attachments(): array
    {
        return [];
    }
}

```

Keterangan:
- `public $data;`: attribute ini kita gunakan untuk menampilkan data di konten email.
- Pada bagian method `__construct()` kita tambahkan parameter `$data` sebagai value untuk atribute `$data` pada saat inisiasi objek kelas. 
- Pada method `envelope()`, kita isi value subjek dari atribute `$data`.
- Pada method `content()`, kita gunakan file blade `emails.send_email` sebagai template untuk konten email yang nanti akan dikirim.


## Step 5 - Membuat view untuk content email{#step-5}
Sekarang kita buat file baru `resources/views/emails/send_email.blade.php`, lalu kita ketik baris kode berikut ini.

```
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tutorial Laravel: Send Email Via SMTP GMAIL @ qadrLabs.com</title>
</head>

<body>
<h2>{{ $data['title'] }}</h2>

<div>
    {{ $data['body'] }}
</div>


</body>

</html>

```

Save kembali file `resources/views/emails/send_email.blade.php`.

## Step 6 - Buat Route untuk kirim email{#step-6}
Sekarang kita buka file `routes/web.php`, lalu kita tambahkan baris kode berikut ini.

```php
<?php

use Illuminate\Support\Facades\Mail; // tambahkan ini
use App\Mail\SendEmail; // tambahkan ini
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});


// tambahkan route baru
Route::get('/mail/send', function () {
    $data = [
        'subject' => 'Testing Kirim Email',
        'title' => 'Testing Kirim Email',
        'body' => 'Ini adalah email uji coba dari Tutorial Laravel: Send Email Via SMTP GMAIL @ qadrLabs.com'
    ];

    Mail::to('email_tujuan@gmail.com')->send(new SendEmail($data));

});


```

Save kembali file `routes/web.php`.

Pada baris kode di atas, terdapat kode.
```php
Mail::to('email_tujuan@gmail.com')->send(new SendEmail($data));
```
Untuk mengirim email kita gunakan `Mail` Facade, di mana alamat email tujuan kita tuliskan sebagai parameter di method `to()` (untuk proses uji coba, pastikan email aktif ditulis sebagai email tujuan ya). 

Untuk proses kirim email sendiri, kita tambahkan instansiasi mailable class `SendEmail` sebagai parameter di method `send()`.


## Step 7 - Uji Coba Kirim Email{#step-7}
Untuk uji coba kirim email, kita run terlebih dahulu project kita. Buka terminal, lalu run command berikut ini.
```
php artisan serve
```

Selanjutnya kita buka browser, lalu akses url `http://127.0.0.1:8000/mail/send` untuk mengirim email menggunakan SMTP Gmail.

Apabila proses kirim email berhasil, kita bisa lihat email baru diinbox email yang kita gunakan sebagai email tujuan.
![Email berhasil dikirim](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/send-email-via-gmail-smtp/5-inbox-email.png)

### Catatan Uji Coba
Per tanggal 12 Desember 2024, ketika dirun tampil error **Connection could not be established with host "ssl://smtp.googlemail.com:587": stream_socket_client(): SSL operation failed with code 1. OpenSSL Error messages: error:0A00010B:SSL routines::wrong version number**, bisa cek catatan [Cara Fix OpenSSL Error messages: error:0A00010B:SSL routines::wrong version number](https://qadrlabs.com/note/cara-fix-openssl-error-messages-error0a00010bssl-routineswrong-version-number/view) atau singkatnya mengubah konfigurasi `.env`:
```
MAIL_ENCRYPTION=starttls
```

## Penutup{#penutup}
Di edisi tutorial laravel kali ini kita sudah membuat coba mengirim email menggunakan SMTP Gmail. Kita sudah coba setup akun gmail, coding fitur kirim email sampai dengan proses uji coba kirim email. Dan setelah proses uji coba, ternyata SMTP Gmail masih dapat kita gunakan untuk mengirim email dan email yang dikirim berhasil sampai di inbox email tujuan.