---
title: "Panduan Lengkap: Cara Integrasi RabbitMQ dengan Laravel sebagai Queue Driver"
slug: "panduan-lengkap-cara-integrasi-rabbitmq-dengan-laravel-sebagai-queue-driver"
category: "Laravel"
date: "2026-02-18"
status: "published"
---

Dalam membangun aplikasi web yang scalable, salah satu tantangan utama adalah menangani proses yang membutuhkan waktu lama seperti pengiriman email, pemrosesan gambar, atau generate report. Jika semua proses ini dijalankan secara synchronous, pengguna harus menunggu hingga semua proses selesai sebelum mendapatkan response. Solusi untuk masalah ini adalah menggunakan **message broker** seperti RabbitMQ untuk memproses tugas-tugas tersebut secara asynchronous di background.

**RabbitMQ** adalah open-source message broker yang menggunakan protokol AMQP (Advanced Message Queuing Protocol). RabbitMQ berperan sebagai perantara antara aplikasi yang mengirim pesan (producer) dan aplikasi yang memproses pesan (consumer). Dengan RabbitMQ, kita bisa:

- **Memproses tugas berat di background** tanpa membuat pengguna menunggu.
- **Mendistribusikan beban kerja** ke beberapa worker secara bersamaan.
- **Menjamin pesan terkirim** meskipun consumer sedang offline, pesan tetap tersimpan di queue.
- **Mendukung arsitektur microservices** dengan memungkinkan komunikasi antar service secara decoupled.

## Overview {#overview}

Pada panduan ini kita akan belajar cara mengintegrasikan RabbitMQ dengan Laravel menggunakan package `vladimir-yuldashev/laravel-queue-rabbitmq`. Package ini memungkinkan kita menggunakan RabbitMQ sebagai queue driver di Laravel, sehingga kita bisa memanfaatkan fitur queue bawaan Laravel seperti Job, dispatch, dan worker tanpa perlu mengubah banyak kode. Panduan ini akan membahas secara detail mulai dari instalasi RabbitMQ, konfigurasi Laravel, membuat Job, hingga menjalankan queue worker.

### Apa yang akan kamu pelajari

1. Instalasi RabbitMQ di Ubuntu 24.04
2. Mengaktifkan RabbitMQ Management Plugin
3. Instalasi Package RabbitMQ di Laravel
4. Konfigurasi Queue Connection RabbitMQ
5. Membuat dan Dispatch Job ke RabbitMQ
6. Menjalankan Queue Worker
7. Monitoring Queue di RabbitMQ Management Dashboard

Setelah kita selesai melakukan semua langkah-langkah integrasi, kita akan uji coba dengan membuat studi kasus pengiriman email notifikasi secara asynchronous menggunakan RabbitMQ.

### Apa yang perlu kamu persiapkan

- VPS atau komputer lokal dengan OS Ubuntu 24.04.
- PHP 8.2+ dan Composer sudah terinstall.
- Laravel 11 atau 12 sudah terinstall.
- Akses pengguna dengan hak sudo.
- Koneksi internet yang stabil.

## Step 1: Instalasi RabbitMQ di Ubuntu 24.04 {#step-1-instalasi-rabbitmq-di-ubuntu-24-04}

Pada langkah pertama ini kita akan install RabbitMQ server. RabbitMQ tersedia di default repository Ubuntu 24.04, sehingga kita bisa install langsung menggunakan `apt`. Sebelum kita mulai, kita perbaharui terlebih dahulu package sistem dengan run command berikut ini.

```bash
sudo apt update
sudo apt upgrade -y
```

Kita tunggu sampai proses pembaharuan package sistem selesai.

Selanjutnya kita install dependency Erlang yang dibutuhkan oleh RabbitMQ, lalu install RabbitMQ server.

```bash
sudo apt install -y erlang
sudo apt install -y rabbitmq-server
```

Ketika tampil prompt, ketik `Y`, lalu tekan `enter` untuk konfirmasi instalasi.

Setelah proses instalasi selesai, RabbitMQ otomatis aktif dan running. Untuk memastikan, kita enable service dan cek statusnya dengan run command berikut ini:

```bash
sudo systemctl enable rabbitmq-server
sudo systemctl start rabbitmq-server
sudo systemctl status rabbitmq-server
```

Output yang ditampilkan:

```
$ sudo systemctl status rabbitmq-server
● rabbitmq-server.service - RabbitMQ Messaging Server
     Loaded: loaded (/usr/lib/systemd/system/rabbitmq-server.service; enabled;>
     Active: active (running) since Wed 2026-02-18 12:10:02 WIB; 5min ago
 Invocation: 1b1e334ffb9b4d8eaa470bca2bf3b9da
   Main PID: 13230 (beam.smp)
      Tasks: 39 (limit: 18140)
     Memory: 87.6M (peak: 106.9M)
        CPU: 2.447s
     CGroup: /system.slice/rabbitmq-server.service
             ├─13230 /usr/lib/erlang/erts-15.2.3/bin/beam.smp -W w -MBas ageff>
             ├─13240 erl_child_setup 65536
             ├─13279 sh -s disksup
             ├─13281 /usr/lib/erlang/lib/os_mon-2.10.1/priv/bin/memsup
             ├─13282 /usr/lib/erlang/lib/os_mon-2.10.1/priv/bin/cpu_sup
             ├─13284 /usr/lib/erlang/erts-15.2.3/bin/inet_gethost 4
             ├─13285 /usr/lib/erlang/erts-15.2.3/bin/inet_gethost 4
             └─13289 /bin/sh -s rabbit_disk_monitor

Feb 18 12:10:00 qadrlabs systemd[1]: Starting rabbitmq-server.service - Rabbit>
Feb 18 12:10:02 qadrlabs systemd[1]: Started rabbitmq-server.service - RabbitM>
~

```

Pada output yang ditampilkan kita bisa melihat status **active (running)**.

Selanjutnya kita verifikasi bahwa RabbitMQ mendengarkan di port default 5672 dengan run command berikut ini:

```bash
sudo ss -tlnp | grep 5672
```

Output yang ditampilkan kurang lebih seperti berikut:

```
LISTEN 0      128    0.0.0.0:5672    0.0.0.0:*    users:(("beam.smp",pid=4122,fd=32))
```

Port 5672 sudah LISTEN, artinya RabbitMQ siap menerima koneksi.

---

**Catatan:** Sebagai alternatif, kamu juga bisa menjalankan RabbitMQ menggunakan Docker tanpa perlu install langsung di server:

```bash
docker run -d --name rabbitmq \
  -p 5672:5672 -p 15672:15672 \
  rabbitmq:3-management
```

Command di atas akan menjalankan RabbitMQ beserta management dashboard di port 15672.

## Step 2: Mengaktifkan RabbitMQ Management Plugin {#step-2-mengaktifkan-rabbitmq-management-plugin}

RabbitMQ menyediakan management plugin yang memberikan antarmuka web untuk memonitor dan mengelola queue, exchange, connection, dan lainnya. Untuk mengaktifkan management plugin, run command berikut ini:

```bash
sudo rabbitmq-plugins enable rabbitmq_management
```

Output yang ditampilkan:

```
Enabling plugins on node rabbit@localhost:
rabbitmq_management
The following plugins have been configured:
  rabbitmq_management
  rabbitmq_management_agent
  rabbitmq_web_dispatch
Applying plugin configuration to rabbit@localhost...
The following plugins have been enabled:
  rabbitmq_management
  rabbitmq_management_agent
  rabbitmq_web_dispatch
started 3 plugins.
```

Selanjutnya kita buat user admin untuk mengakses management dashboard. Secara default, RabbitMQ hanya mengizinkan user `guest` untuk login dari localhost. Untuk keamanan, kita buat user baru dengan run command berikut ini:

```bash
sudo rabbitmqctl add_user admin password_kamu
sudo rabbitmqctl set_user_tags admin administrator
sudo rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
```

**Penjelasan Command:**

- **`add_user admin password_kamu`**: Membuat user baru dengan nama `admin`. Ganti `password_kamu` dengan password yang kuat.
- **`set_user_tags admin administrator`**: Memberikan role administrator kepada user `admin`.
- **`set_permissions`**: Memberikan full permission (configure, write, read) untuk semua resource di virtual host `/`.

Sekarang kita bisa akses RabbitMQ Management Dashboard di browser:

```
http://ip-server-kamu:15672
```
atau apabila dilocal kita bisa akses di browser melalui
```
http://localhost:15672
```

Login menggunakan user `admin` dan password yang sudah kita buat. Di dashboard ini kita bisa melihat overview, connections, channels, exchanges, dan queues.

**Catatan:** Jika menggunakan firewall UFW, pastikan port 15672 diizinkan:

```bash
sudo ufw allow 15672
```

## Step 3: Instalasi Package RabbitMQ di Laravel {#step-3-instalasi-package-rabbitmq-di-laravel}

Setelah RabbitMQ server sudah running, langkah selanjutnya adalah mengintegrasikan RabbitMQ dengan  project laravel kita. Kita akan menggunakan package `vladimir-yuldashev/laravel-queue-rabbitmq` yang merupakan package paling populer dan mendukung Laravel 11 dan 12.

Buka terminal, masuk ke direktori project Laravel, lalu run command berikut untuk install package beserta dependency-nya:

```bash
composer require vladimir-yuldashev/laravel-queue-rabbitmq
```

Kita tunggu sampai proses instalasi selesai.

Output yang ditampilkan kurang lebih seperti berikut:

```
Using version ^14.4 for vladimir-yuldashev/laravel-queue-rabbitmq
./composer.json has been updated
Running composer update vladimir-yuldashev/laravel-queue-rabbitmq
...
Installing vladimir-yuldashev/laravel-queue-rabbitmq (v14.4.0)
...
```

Package ini akan otomatis ter-register di project laravel kita melalui package auto-discovery, sehingga kita tidak perlu mendaftarkan service provider secara manual.

## Step 4: Konfigurasi Queue Connection RabbitMQ {#step-4-konfigurasi-queue-connection-rabbitmq}

Setelah package terinstall, kita perlu mengkonfigurasi connection RabbitMQ di Laravel. Ada dua file yang perlu kita konfigurasi: `.env` dan `config/queue.php`.

### Konfigurasi File .env

Buka file `.env` di root project Laravel, lalu tambahkan konfigurasi berikut:

```
QUEUE_CONNECTION=rabbitmq

RABBITMQ_HOST=127.0.0.1
RABBITMQ_PORT=5672
RABBITMQ_USER=admin
RABBITMQ_PASSWORD=password_kamu
RABBITMQ_VHOST=/
```

**Penjelasan Konfigurasi:**

- **`QUEUE_CONNECTION=rabbitmq`**: Mengubah default queue driver dari `database` atau `sync` ke `rabbitmq`.
- **`RABBITMQ_HOST`**: Alamat server RabbitMQ. Gunakan `127.0.0.1` jika RabbitMQ diinstall di server yang sama.
- **`RABBITMQ_PORT`**: Port default RabbitMQ yaitu 5672.
- **`RABBITMQ_USER` dan `RABBITMQ_PASSWORD`**: Credential user yang sudah kita buat di Step 2.
- **`RABBITMQ_VHOST`**: Virtual host RabbitMQ, default `/`.

### Konfigurasi File config/queue.php

Selanjutnya buka file `config/queue.php`, lalu tambahkan konfigurasi connection `rabbitmq` di dalam array `connections`:

```php
'connections' => [

    // ... connection lainnya

    'rabbitmq' => [
        'driver' => 'rabbitmq',
        'queue' => env('RABBITMQ_QUEUE', 'default'),
        'hosts' => [
            [
                'host' => env('RABBITMQ_HOST', '127.0.0.1'),
                'port' => env('RABBITMQ_PORT', 5672),
                'user' => env('RABBITMQ_USER', 'guest'),
                'password' => env('RABBITMQ_PASSWORD', 'guest'),
                'vhost' => env('RABBITMQ_VHOST', '/'),
            ],
        ],
        'options' => [
            'ssl_options' => [
                'cafile' => env('RABBITMQ_SSL_CAFILE', null),
                'local_cert' => env('RABBITMQ_SSL_LOCALCERT', null),
                'local_key' => env('RABBITMQ_SSL_LOCALKEY', null),
                'verify_peer' => env('RABBITMQ_SSL_VERIFY_PEER', true),
                'passphrase' => env('RABBITMQ_SSL_PASSPHRASE', null),
            ],
            'queue' => [
                'job' => \VladimirYuldashev\LaravelQueueRabbitMQ\Queue\Jobs\RabbitMQJob::class,
            ],
        ],
    ],
		
    // ... connection lainnya
		
],
```

Setelah menambahkan konfigurasi, jalankan command berikut untuk membersihkan cache konfigurasi:

```bash
php artisan config:clear
```

## Step 5: Membuat dan Dispatch Job ke RabbitMQ {#step-5-membuat-dan-dispatch-job-ke-rabbitmq}

Sekarang RabbitMQ sudah terhubung dengan Laravel, kita akan membuat Job sebagai studi kasus. Pada studi kasus ini, kita akan membuat Job untuk mengirim email notifikasi selamat datang secara asynchronous.

### Membuat Job Class

Pertama, kita buat Job class baru dengan run command berikut ini:

```bash
php artisan make:job SendWelcomeEmail
```

Setelah Job berhasil dibuat, buka file `app/Jobs/SendWelcomeEmail.php` lalu update kode-nya menjadi seperti berikut:

```php
<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class SendWelcomeEmail implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 30;

    public function __construct(
        public string $email,
        public string $name
    ) {}

    public function handle(): void
    {
        // Simulasi pengiriman email
        Log::info("Mengirim welcome email ke {$this->email} untuk {$this->name}");

        // Contoh kirim email (uncomment jika sudah setup mailer)
        // Mail::to($this->email)->send(new \App\Mail\WelcomeMail($this->name));

        Log::info("Welcome email berhasil dikirim ke {$this->email}");
    }

    public function failed(\Throwable $exception): void
    {
        Log::error("Gagal mengirim welcome email ke {$this->email}: " . $exception->getMessage());
    }
}
```

**Penjelasan Kode:**

- **`implements ShouldQueue`**: Menandakan Job ini akan diproses secara asynchronous melalui queue, bukan synchronous.
- **`$tries = 3`**: Job akan dicoba ulang maksimal 3 kali jika gagal.
- **`$backoff = 30`**: Jeda 30 detik sebelum mencoba ulang.
- **`handle()`**: Method utama yang berisi logic pengiriman email. Method ini akan dieksekusi oleh queue worker.
- **`failed()`**: Method yang dipanggil jika Job gagal setelah semua percobaan ulang habis.

Pada studi kasus ini, email tidak kita kirim langsung dan kita ganti menjadi pencatatan log.

### Dispatch Job dari Controller

Selanjutnya kita buat route dan controller untuk men-dispatch Job. Buka file `routes/web.php` lalu tambahkan route berikut:

```php
use App\Jobs\SendWelcomeEmail;

Route::get('/test-queue', function () {
    $email = 'user@example.com';
    $name = 'John Doe';

    SendWelcomeEmail::dispatch($email, $name);

    return response()->json([
        'message' => 'Job berhasil di-dispatch ke RabbitMQ!',
        'email' => $email,
        'name' => $name,
    ]);
});
```

Kita juga bisa men-dispatch Job ke queue tertentu atau dengan delay:

```php
// Dispatch ke queue tertentu
SendWelcomeEmail::dispatch($email, $name)->onQueue('emails');

// Dispatch dengan delay 5 menit
SendWelcomeEmail::dispatch($email, $name)->delay(now()->addMinutes(5));
```

## Step 6: Menjalankan Queue Worker {#step-6-menjalankan-queue-worker}

Setelah Job di-dispatch, kita perlu menjalankan queue worker untuk memproses Job tersebut. Laravel menyediakan dua command untuk menjalankan worker dengan RabbitMQ.

### Menggunakan queue:work (Bawaan Laravel)

```bash
php artisan queue:work rabbitmq
```

Command ini menggunakan `basic_get` dan mendukung consume dari multiple queues.

### Menggunakan rabbitmq:consume (Dari Package — Lebih Performant)

```bash
php artisan rabbitmq:consume --queue=default
```

Command ini menggunakan `basic_consume` yang lebih performant sekitar 2x lipat dibanding `basic_get`, namun tidak mendukung multiple queues.

---

**Catatan Penting:** Command `rabbitmq:consume` **tidak otomatis membuat queue** di RabbitMQ. Jika queue belum ada, kamu akan mendapatkan error berikut:

```
PhpAmqpLib\Exception\AMQPProtocolChannelException
NOT_FOUND - no queue 'default' in vhost '/'
```

Untuk mengatasi error ini, pastikan queue sudah dibuat terlebih dahulu dengan salah satu cara berikut:

1. **Jalankan `queue:work` terlebih dahulu** — command ini otomatis membuat queue di RabbitMQ. Setelah queue terbentuk, kamu bisa beralih ke `rabbitmq:consume`.
2. **Dispatch job terlebih dahulu** — akses route `/test-queue` di browser agar Laravel men-dispatch job yang secara otomatis membuat queue-nya.
3. **Buat queue manual via Management Dashboard** — buka `http://ip-server:15672` → tab **Queues and Streams** → **Add a new queue** → isi name `default` → klik **Add queue**.

---

### Menjalankan Worker di Production dengan Supervisor

Untuk production, kita perlu memastikan queue worker berjalan terus-menerus. Kita gunakan **Supervisor** untuk mengatur ini. Panduan tentang supervisor dapat dibaca pada tutorial [Manage Laravel Queue dengan Supervisor](https://qadrlabs.com/member/post/manage-laravel-queue-menggunakan-supervisor).


## Step 7: Uji Coba dan Verifikasi {#step-7-uji-coba-dan-verifikasi}

Setelah semua langkah selesai, kita bisa menguji coba integrasi RabbitMQ dengan Laravel. Pastikan server Laravel dan queue worker sudah berjalan.

Pertama, jalankan Laravel development server:

```bash
php artisan serve
```

Di terminal yang berbeda, jalankan queue worker:

```bash
php artisan queue:work rabbitmq
```

Selanjutnya akses route test di browser:

```
http://127.0.0.1:8000/test-queue
```

Output di browser:

```json
{
    "message": "Job berhasil di-dispatch ke RabbitMQ!",
    "email": "user@example.com",
    "name": "John Doe"
}
```

Di terminal queue worker, kita bisa lihat output berikut:

```
[2024-11-18 08:30:15] Processing: App\Jobs\SendWelcomeEmail
[2024-11-18 08:30:15] Processed:  App\Jobs\SendWelcomeEmail
```

Kita juga bisa verifikasi di file log Laravel:

```bash
tail -f storage/logs/laravel.log
```

Output:

```
[2026-02-18 05:48:10] local.INFO: Mengirim welcome email ke user@example.com untuk John Doe  
[2026-02-18 05:48:10] local.INFO: Welcome email berhasil dikirim ke user@example.com  

```


## Monitoring Queue di RabbitMQ Management Dashboard {#monitoring-queue-di-rabbitmq-management-dashboard}

Salah satu keunggulan RabbitMQ adalah management dashboard yang menyediakan informasi lengkap tentang queue dan message. Akses dashboard di browser:

```
http://ip-server-kamu:15672
```
Apabila masih di localhost, kita bisa akses melalui `http://localhost:15672`.

Di dashboard ini kita bisa memonitor beberapa hal penting:

**Tab Overview** menampilkan ringkasan keseluruhan termasuk jumlah connections, channels, exchanges, dan queues yang aktif beserta rate message per detik.

**Tab Queues** menampilkan daftar semua queue beserta jumlah message yang menunggu (ready), yang sedang diproses (unacked), dan total message. Di sini kita bisa melihat apakah ada message yang menumpuk (backlog).

**Tab Connections** menampilkan daftar koneksi aktif ke RabbitMQ, termasuk koneksi dari Laravel queue worker kita.

## Kesimpulan {#kesimpulan}

Selamat! Kita telah berhasil mengintegrasikan RabbitMQ dengan Laravel. Dengan integrasi ini, aplikasi Laravel kita bisa memproses tugas-tugas berat secara asynchronous di background tanpa membuat pengguna menunggu.

**Takeaway dari panduan ini:**

- **RabbitMQ** adalah message broker yang menjamin pesan terkirim dan terproses, bahkan ketika consumer sedang offline. Ini memberikan reliabilitas yang lebih baik dibanding queue driver default Laravel.
- **Package `laravel-queue-rabbitmq`** memungkinkan integrasi seamless dengan Laravel Queue API, sehingga kita bisa menggunakan fitur Job, dispatch, retry, dan failed job tanpa mengubah cara kerja yang sudah familiar.
- **Supervisor** wajib digunakan di production untuk memastikan queue worker berjalan terus-menerus dan otomatis restart jika terjadi crash.
- **RabbitMQ Management Dashboard** sangat berguna untuk memonitor kesehatan queue, melihat jumlah message yang menumpuk, dan men-debug masalah terkait queue secara visual.
- Selalu gunakan **`$tries` dan `$backoff`** pada Job class untuk menangani kegagalan sementara seperti timeout koneksi atau service yang sedang down.

Jika teman-teman mengalami kendala, jangan ragu untuk memeriksa dokumentasi resmi RabbitMQ atau repository package `laravel-queue-rabbitmq` di GitHub.

---

**FAQ**

1. **Apa perbedaan RabbitMQ dengan queue database di Laravel?**
   Queue database menyimpan job di tabel database yang bisa menjadi bottleneck ketika volume job tinggi. RabbitMQ dirancang khusus sebagai message broker sehingga lebih cepat, lebih reliable, dan mendukung fitur advanced seperti routing, exchange, dan clustering.

2. **Apakah bisa menggunakan RabbitMQ dan queue database secara bersamaan?**
   Ya, Laravel mendukung multiple queue connection. Kita bisa men-dispatch Job tertentu ke RabbitMQ dan Job lainnya ke database dengan menggunakan method `->onConnection('rabbitmq')` atau `->onConnection('database')`.

3. **Berapa jumlah worker yang ideal untuk production?**
   Jumlah worker tergantung pada beban kerja dan resource server. Sebagai panduan awal, mulai dengan 2-4 worker dan monitor penggunaan CPU serta memory. Tambah worker jika message mulai menumpuk di queue.

4. **Apa yang terjadi jika RabbitMQ server down?**
   Jika RabbitMQ down, dispatch Job dari Laravel akan throw exception. Untuk menangani ini, kita bisa menggunakan try-catch saat dispatch atau mengkonfigurasi fallback queue connection di Laravel.

5. **Apakah RabbitMQ mendukung Laravel Horizon?**
   Ya, package `vladimir-yuldashev/laravel-queue-rabbitmq` mendukung Laravel Horizon. Kita bisa memonitor dan mengelola queue RabbitMQ melalui Horizon dashboard.

Semoga panduan ini membantu teman-teman untuk mengoptimalkan performa aplikasi Laravel dengan RabbitMQ!