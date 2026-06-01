---
title: "Send Email dengan Queue di CodeIgniter 4"
slug: "send-email-dengan-queue-di-codeigniter-4"
category: "CodeIgniter 4"
date: "2024-11-04"
status: "published"
---

## Introduction{#introduction}
Masih ingat masa-masa mengembangkan aplikasi dengan CodeIgniter 3? Saat itu, setiap kali aplikasi perlu mengirim email - entah itu notifikasi pendaftaran, reset password, atau konfirmasi pesanan - server kita seakan "tertidur" beberapa detik. Pengguna harus menunggu dengan sabar sampai email terkirim sebelum bisa melanjutkan aktivitasnya. Di project e-commerce yang saya tangani dulu, proses checkout bisa memakan waktu hingga 7-8 detik hanya karena menunggu email konfirmasi terkirim!

Tentu saja, ini bukan pengalaman yang menyenangkan bagi pengguna. Beberapa mencoba mengimplementasikan sistem queue sendiri sebagai solusi, tapi prosesnya sangat kompleks. Kita harus membuat worker custom, mengatur cronjob, dan kadang hasil akhirnya masih kurang reliable. Saya sendiri pernah menghabiskan hampir seminggu penuh hanya untuk membuat sistem queue yang berfungsi dengan baik di CodeIgniter 3.

Kabar baiknya, CodeIgniter 4 hadir dengan solusi yang jauh lebih elegan. Melalui package queue resmi (https://queue.codeigniter.com/), kita bisa mengimplementasikan sistem antrian email dalam hitungan menit, bukan hari. Bayangkan: pengguna mengklik tombol checkout, dan boom! - halaman konfirmasi langsung muncul tanpa delay. Email? Biarkan berjalan di background dengan tenang. Tidak ada lagi keluhan tentang aplikasi yang lambat, tidak ada lagi pengguna yang meninggalkan proses checkout karena kesal menunggu.

Dalam tutorial ini, saya akan membagikan langkah demi langkah bagaimana mengintegrasikan sistem queue email di CodeIgniter 4. Kita akan melihat bagaimana sesuatu yang dulu memakan waktu berhari-hari, kini bisa diselesaikan dalam waktu singkat. Dan yang terbaik? Semua ini bisa Anda implementasikan bahkan jika Anda baru mengenal CodeIgniter 4.

## Overview{#overview}
Dalam tutorial ini, kita akan mempelajari implementasi Queue System di CodeIgniter 4 dengan studi kasus yang sederhana namun praktis - pengiriman email asinkron. Kita akan fokus pada penggunaan library resmi CodeIgniter Queue (https://queue.codeigniter.com/) untuk menangani proses background tasks.

### Apa yang akan kita pelajari:
- Instalasi dan konfigurasi package CodeIgniter Queue
- Setup SMTP untuk pengiriman email
- Pembuatan Job Class untuk menangani email queue
- Implementasi queue worker untuk memproses email
- Best practices dalam menangani background tasks

### Apa yang akan kita kembangkan:
Kita akan membuat sistem sederhana yang terdiri dari:
- Sebuah endpoint di controller untuk mentrigger pengiriman email
- Job handler untuk memproses email dalam queue
- Konfigurasi queue yang optimal untuk pengiriman email
- Worker process untuk mengeksekusi job dalam queue

### Uji Coba dan Validasi:
Setelah semua setup selesai, kita akan menguji sistem dengan:
1. Mengirim email melalui endpoint controller
2. Melihat bagaimana queue worker memproses email di background
3. Memverifikasi pengiriman dengan mengecek inbox email tujuan (misalnya, jika Anda menggunakan email pribadi seperti `johndoe@gmail.com`)
4. Mengamati bahwa response time aplikasi tetap cepat meski sedang mengirim email

Tutorial ini sengaja dibuat sederhana agar Anda bisa fokus pada konsep utama queue system. Setelah memahami fundamental ini, Anda bisa mengembangkannya lebih lanjut sesuai kebutuhan project Anda, seperti mengirim email batch, newsletter, atau notifikasi sistem yang lebih kompleks.

## Table of Content{#table-of-content}

- [Introduction](#introduction)
- [Overview](#overview)
- [Persiapan](#persiapan)
- [Step 1: Install Package Queue](#step-1-install-package-queue)
- [Step 2: Konfigurasi Email](#step-2-konfigurasi-email)
- [Step 3: Buat Job Class untuk Pengiriman Email](#step-3-buat-job-class)
- [Step 4: Konfigurasi Queue](#step-4-konfigurasi-queue)
- [Step 5: Edit Controller](#step-5-edit-controller)
- [Uji Coba](#uji-coba)
- [Kesimpulan](#kesimpulan)


## Persiapan{#persiapan}
Sebelum kita mulai mengimplementasi queue system untuk email, pastikan Anda sudah menyiapkan beberapa hal berikut:

### 1. Aplikasi CodeIgniter 4
Pastikan Anda sudah memiliki aplikasi CodeIgniter 4 yang berjalan dengan baik di environment development Anda. Jika belum, Anda bisa mengikuti panduan instalasi di dokumentasi resmi CodeIgniter 4.

### 2. SMTP Gmail
Untuk tutorial ini, kita akan menggunakan SMTP Gmail sebagai mail server. Anda memerlukan:
- Akun Gmail aktif
- App Password untuk autentikasi SMTP

>  **Catatan Penting**: 
> Untuk setup App Password Gmail, Anda bisa mengikuti tutorial lengkap di artikel "[Mengirim Email via Gmail SMTP menggunakan Email Library CodeIgniter](https://qadrlabs.com/post/mengirim-email-via-gmail-smtp-menggunakan-email-library-codeigniter#step-1)". Di sana dijelaskan step-by-step cara:
> - Mengaktifkan 2-Step Verification di akun Google
> - Membuat App Password khusus untuk aplikasi
> - Mengamankan kredensial SMTP

Setelah kedua komponen di atas siap, kita bisa melanjutkan ke tahap implementasi queue system. Pastikan untuk menyimpan App Password Gmail Anda dengan aman, karena kita akan membutuhkannya saat mengkonfigurasi email nanti.


## Step 1: Install Package Queue{#step-1-install-package-queue}

Pertama, kita perlu menginstall package queue yang akan membantu kita dalam proses ini. Buka terminal dan jalankan perintah berikut:

```bash
composer config minimum-stability dev
composer config prefer-stable true
composer require codeigniter4/queue
```

Setelah proses instalasi selesai, jalankan migrasi untuk membuat tabel-tabel yang diperlukan oleh sistem Queue:

```bash
php spark migrate --all
```

## Step 2: Konfigurasi Email{#step-2-konfigurasi-email}

Sekarang, kita perlu mengonfigurasi pengaturan email untuk mengirimkan pesan melalui queue. Pertama, buat file konfigurasi email dengan perintah:

```bash
php spark queue:publish
```

Kemudian, buka file `app/Config/Email.php` dan atur parameter berikut:

```php
public string $fromEmail  = 'tes@example.com';
public string $fromName   = 'Admin';
public string $recipients = 'tes recipients';
public string $protocol = 'smtp';
public string $SMTPHost = 'smtp.gmail.com';
public string $SMTPUser = 'email-gmail-kamu@gmail.com';
public string $SMTPPass = 'app-password-hasil-generate';
public int $SMTPPort = 465;
public string $SMTPCrypto = 'ssl';
public string $mailType = 'html';
public string $charset = 'UTF-8';
```

Pastikan `SMTPUser` dan `SMTPPass` sesuai dengan akun email Anda.

## Step 3: Buat Job Class untuk Pengiriman Email{#step-3-buat-job-class}

Langkah berikutnya adalah membuat Job Class yang bertugas mengirimkan email melalui queue. Jalankan perintah berikut:

```bash
php spark queue:job Email
```

Setelah itu, buka file `app/Jobs/Email.php` dan tambahkan kode berikut untuk menangani pengiriman email:

```php
<?php
namespace App\Jobs;

use Exception;
use CodeIgniter\Queue\BaseJob;
use CodeIgniter\Queue\Interfaces\JobInterface;

class Email extends BaseJob implements JobInterface
{
    /**
     * @throws Exception
     */
    public function process()
    {
        $email  = service('email', null, false);
        $result = $email
            ->setTo($this->data['recipient_email'])
            ->setSubject('Tes kirim email')
            ->setMessage($this->data['message'])
            ->send();
        
        if (! $result) {
            throw new Exception($email->printDebugger('headers'));
        }
        return $result;
    }
}
```

Class ini akan mengambil data email dan mengirimkannya. Jika terjadi error, class ini akan melempar exception dengan debug informasi.

## Step 4: Konfigurasi Queue{#step-4-konfigurasi-queue}

Selanjutnya, kita perlu mengonfigurasi Queue agar mengenali job yang baru saja kita buat. Buka file `app/Config/Queue.php` dan tambahkan job handler untuk `Email`:

```php
<?php
declare(strict_types=1);
namespace Config;

use App\Jobs\Email;

class Queue extends BaseQueue
{    
    public array $jobHandlers = [
        'email' => Email::class,
    ];
}
```

Pengaturan ini mendaftarkan job `Email` ke dalam sistem Queue.

## Step 5: Edit Controller untuk Pengiriman Email{#step-5-edit-controller}

Untuk menguji pengiriman email melalui queue, buatlah sebuah controller. Buka file `app/Controllers/Home.php` dan tambahkan kode berikut:

```php
<?php
namespace App\Controllers;

class Home extends BaseController
{
    public function index(): string
    {
        service('queue')->push('emails', 'email', [
            'recipient_email' => 'email-tujuan@example.com',
            'message' => 'Halo Kak! Ini adalah email percobaan untuk Tutorial CodeIgniter 4: Mengirim Email dengan queue CodeIgniter 4 @ qadrlabs.com'
        ]);
        return 'ok';
    }
}
```

Controller ini akan mengirimkan job email ke queue, yang kemudian akan dieksekusi oleh worker.

## Uji Coba{#uji-coba}
Saatnya untuk menguji implementasi queue untuk pengiriman email.
1. Pertama kita run terlebih dahulu project kita di terminal pertama:
    ```bash
    php spark serve
    ```

2. Selanjutnya di terminal kedua kita jalankan worker queue:
    ```bash
    php spark queue:work emails
    ```
		
		![run queue worker](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/send-email-with-queue/1-run-queue.png)

3. Buka browser dan akses `http://localhost:8080/`. Jika konfigurasi sudah benar, worker akan mengambil job pengiriman email dan mengirimkan email ke alamat tujuan. 
	![job mulai diproses](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/send-email-with-queue/2-proses-yang-ditampilkan-di-terminal.png)
	Dan apabila berhasil, maka di terminal akan menampilkan notifikasi `The processing of this job was successful`.
	![job successfull](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/send-email-with-queue/3-queue-job-success.png)

4. Selanjutnya kita bisa cek apakah email berhasil terkirim di inbox email tujuan. Karena pada saat uji coba, saya menggunakan email pribadi, saya bisa langsung lihat hasilnya. Dan kita bisa lihat email seperti berikut ini.
	![email terkirim](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/send-email-with-queue/4-email-terkirim.png)

## Kesimpulan{#kesimpulan}

Dalam tutorial ini, kita telah berhasil mengimplementasikan sistem pengiriman email asinkron menggunakan Queue System di CodeIgniter 4. Melalui praktik langsung, kita bisa melihat betapa mudahnya mengintegrasikan fitur ini berkat package resmi CodeIgniter Queue (https://queue.codeigniter.com/).

Dari hasil uji coba yang kita lakukan:
- Response time endpoint sangat cepat karena proses pengiriman email berjalan di background
- Worker queue berhasil memproses dan mengirimkan email ke alamat tujuan
- Email diterima dengan baik di inbox tujuan tanpa ada masalah
- Sistem tetap responsif meskipun ada multiple request pengiriman email

Beberapa keunggulan menggunakan CodeIgniter Queue dibandingkan implementasi manual:
1. **Kemudahan Implementasi**: Cukup install package, buat job class, dan sistem queue sudah siap digunakan
2. **Reliable**: Package ini menangani retry mechanism dan error handling secara otomatis
3. **Fleksibel**: Bisa digunakan tidak hanya untuk email, tapi juga untuk berbagai background task lainnya
4. **Terintegrasi**: Sebagai package resmi, integrasi dengan CodeIgniter 4 sangat mulus dan dokumentasinya lengkap

Untuk pengembangan lebih lanjut, Anda bisa:
- Menambahkan monitoring untuk queue jobs
- Mengimplementasikan sistem notifikasi jika ada email gagal terkirim
- Mengoptimalkan jumlah worker sesuai kebutuhan aplikasi
- Menggunakan berbagai driver queue (database, redis, dll) sesuai kebutuhan

Library CodeIgniter Queue terbukti menjadi solusi yang tepat untuk mengatasi masalah bottleneck pada pengiriman email. Dibandingkan dengan pengalaman di CodeIgniter 3 yang membutuhkan implementasi manual, package ini memberikan developer modern tools yang dibutuhkan untuk membangun aplikasi yang scalable dengan effort minimal.

>  **Pro Tips**: 
> Untuk production environment, pastikan untuk:
> - Mengatur jumlah retry dan timeout yang sesuai
> - Memonitor queue size dan processing time
> - Mengimplementasikan error logging yang komprehensif
> - Menggunakan supervisor atau process manager untuk menjalankan worker

Dengan mengikuti tutorial ini, Anda telah memiliki fondasi yang solid untuk mengimplementasikan sistem queue di aplikasi CodeIgniter 4 Anda. Selamat mencoba dan selamat mengembangkan aplikasi yang lebih responsif!