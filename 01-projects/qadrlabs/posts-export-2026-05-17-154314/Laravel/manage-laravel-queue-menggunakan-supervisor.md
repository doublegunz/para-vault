---
title: "Manage Laravel Queue menggunakan Supervisor"
slug: "manage-laravel-queue-menggunakan-supervisor"
category: "Laravel"
date: "2023-12-31"
status: "published"
---

Pernahkah Anda mengalami kendala saat job queue Laravel tiba-tiba terhenti tanpa ada notifikasi? Pada [tutorial sebelumnya](https://qadrlabs.com/post/belajar-laravel-8-kirim-email-dengan-queue), kita telah membahas implementasi Laravel queue untuk mengoptimalkan proses bisnis aplikasi. Meski Laravel queue sangat membantu dalam meningkatkan efisiensi waktu eksekusi, namun ada tantangan yang sering kita hadapi - queue worker yang tiba-tiba mati atau terhenti tanpa kita sadari. Biasanya masalah ini baru terdeteksi ketika ada laporan dari user atau saat beberapa proses tidak berjalan sebagaimana mestinya. Meski kita bisa memonitor dan me-restart queue worker secara manual, tentu cara ini tidak efisien untuk jangka panjang. Kabar gembiranya, ada solusi yang bisa mengatasi masalah ini secara otomatis: Supervisor.

[Supervisor](http://supervisord.org/#supervisor-a-process-control-system) hadir sebagai solusi process control system yang powerful untuk lingkungan UNIX-like. Bayangkan Supervisor sebagai "manajer" yang dapat diandalkan untuk mengawasi dan mengelola berbagai proses aplikasi Anda secara real-time. Berbeda dengan tools sejenis seperti launchd, daemontools, atau runit, Supervisor tidak didesain untuk menggantikan init system sebagai "process ID 1". Sebaliknya, Supervisor berperan sebagai tool manajemen yang fokus pada monitoring dan kontrol proses-proses spesifik dalam project Anda, dengan kemampuan auto-start saat system boot layaknya aplikasi normal lainnya.

## Overview{#overview}
Tutorial kali ini akan memandu Anda langkah demi langkah dalam mengimplementasikan Supervisor untuk monitoring Laravel queue. Kita akan membahas tiga tahapan kunci yang akan mengubah cara Anda mengelola queue worker:

1. Step 1 - Instalasi dan Konfigurasi Supervisor
2. Step 2 - Setup Queue Worker untuk Aplikasi Laravel
3. Step 3 - Monitoring Status Queue Worker dan Troubleshooting

## Prasyarat{#prasyarat}
Sebelum kita mulai, pastikan environment development Anda memenuhi kriteria berikut:

1. Operating System: Linux (Tutorial ini menggunakan Ubuntu, namun bisa diadaptasi untuk distro Linux lainnya)
2. Aplikasi Laravel yang sudah mengimplementasikan queue system

 **Tips**: Jika Anda belum mengimplementasikan Laravel queue, Anda bisa mengikuti [tutorial sebelumnya](https://qadrlabs.com/post/belajar-laravel-8-kirim-email-dengan-queue) tentang setup dasar Laravel queue terlebih dahulu.

## Step 1 — Install Supervisor{#step-1}
Pertama kita install dulu supervisor. Buka terminal lalu run command berikut ini.
```bash
sudo apt update && sudo apt install supervisor
```

Tunggu sampai proses instalasi selesai.

Ketika proses instalasi selesai, service supervisor sudah running secara otomatis. Kita bisa cek status service supervisor menggunakan command berikut ini.

```bash
sudo systemctl status supervisor
```

Selain melalui terminal, kita juga bisa melihat proses supervisor melalui web interface. Untuk mengaktifkan web interface, kita modifikasi terlebih dahulu file konfigurasi supervisor.

```
sudo nano /etc/supervisor/supervisord.conf
```

Selanjutnya kita tambahkan konfigurasi berikut ini di awal file.
```
[inet_http_server]
port=127.0.0.1:9001
username=admin
password=admin
```

Save dan close file, lalu restart supervisor service.

```
suod systemctl restart supervisor
```

Untuk mengakses web interface supervisor, buka `http://127.0.0.1:9001/` di web browser.

## Step 2 — Create Queue Worker{#step-2}
Setelah supervisor berhasil kita install di step sebelumnya, sekarang kita akan buat queue worker untuk aplikasi web yang kita develop menggunakan laravel.  

Sebagai contoh, Lokasi laravel web app yang kita bangun ada di lokasi berikut ini.
```
/var/www/html/laravel-queue
```

Sekarang kita buat file konfigurasi supervisor untuk web app kita. 
```
sudo nano /etc/supervisor/conf.d/laravel-worker.conf
```

Kita ketika konfigurasi berikut ini.
```
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/laravel-queue/artisan queue:work --sleep=3 --tries=3 
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=root
numprocs=8
redirect_stderr=true
stdout_logfile=/var/www/html/laravel-queue/worker.log
stopwaitsecs=3600
```

Mari kita bahas setiap bagian dari konfigurasi ini:

1. **[program:laravel-worker]**
   - Ini adalah bagian yang mendefinisikan program untuk diawasi oleh Supervisor. Nama program yang diawasi adalah `laravel-worker`.

2. **process_name=%(program_name)s_%(process_num)02d**
   - Ini mendefinisikan format nama proses yang akan dihasilkan oleh Supervisor. `%(program_name)s` akan diganti dengan nama program (`laravel-worker`), dan `%(process_num)02d` akan diganti dengan nomor proses dua digit.

3. **command=php /var/www/html/laravel-queue/artisan queue:work --sleep=3 --tries=3 --max-time=3600**
   - Ini adalah perintah yang akan dijalankan oleh Supervisor ketika memulai program. Parameter seperti `--sleep`, `--tries`, dan `--max-time` menentukan perilaku queue worker.

4. **autostart=true**
   - Ini menunjukkan bahwa program (`laravel-worker`) akan secara otomatis dijalankan saat Supervisor mulai.

5. **autorestart=true**
   - Ini menunjukkan bahwa Supervisor akan mencoba untuk secara otomatis memulai ulang program jika program berhenti atau berhenti bekerja.

6. **stopasgroup=true**
   - Ini akan menghentikan grup child process sebagai unit, artinya ketika kita memberhentikan program, Supervisor akan mencoba menghentikan semua child process yang terkait.

7. **killasgroup=true**
   - Ini akan kill semua child process ketika program dihentikan atau direstart.

8. **user=root**
   - Ini menentukan pengguna yang akan menjalankan program.

9. **numprocs=8**
   - Ini menentukan jumlah proses yang akan dibuat. Dalam hal ini, ada 8 proses queue worker.

10. **redirect_stderr=true**
    - Ini mengarahkan keluaran error standar ke output standar sehingga dapat ditangkap oleh Supervisor.

11. **stdout_logfile=/var/www/html/laravel-queue/worker.log**
    - Ini menentukan file di mana output standar dari program akan ditulis.

12. **stopwaitsecs=3600**
    - Ini menentukan waktu maksimum dalam detik yang Supervisor akan menunggu sebelum menghentikan program. Dalam hal ini, Supervisor akan menunggu 3600 detik (1 jam) sebelum memberhentikan program.

Selanjutnya kita run command berikut ini, supaya supervisor membaca file konfigurasi yang baru saja kita buat.
```
sudo supervisorctl reread
```

Output
```
laravel-worker: available
```

Selanjutnya kita run command ini supaya supervisor menerapkan perubahan konfigurasi yang sudah dibaca. 
```
sudo supervisorctl update
```
Output:
```
laravel-worker: added process group
```

Setelah itu kita start laravel worker menggunakan command berikut ini.
```
sudo supervisorctl start "laravel-worker:*"
```

## Step 3 — Cek Status Queue Worker{#step-3}

Untuk mengetahui apakah laravel worker berjalan atau tidak, kita bisa pakai command berikut ini.
```
sudo supervisorctl status
```

Output:
```
laravel-worker:laravel-worker_00   RUNNING   pid 65354, uptime 0:04:31
laravel-worker:laravel-worker_01   RUNNING   pid 65355, uptime 0:04:31
laravel-worker:laravel-worker_02   RUNNING   pid 65356, uptime 0:04:31
laravel-worker:laravel-worker_03   RUNNING   pid 65357, uptime 0:04:31
laravel-worker:laravel-worker_04   RUNNING   pid 65358, uptime 0:04:31
laravel-worker:laravel-worker_05   RUNNING   pid 65359, uptime 0:04:31
laravel-worker:laravel-worker_06   RUNNING   pid 65360, uptime 0:04:31
laravel-worker:laravel-worker_07   RUNNING   pid 65361, uptime 0:04:31
```

## Penutup{#penutup}

Selamat! Anda telah berhasil mengimplementasikan Supervisor untuk mengelola Laravel queue worker. Dari status output yang kita lihat, seluruh worker berjalan dengan optimal - ditandai dengan status RUNNING pada setiap proses, lengkap dengan informasi PID dan uptime masing-masing worker. 

Dengan Supervisor, Anda tidak perlu lagi khawatir tentang queue worker yang terhenti tanpa pengawasan. System akan secara otomatis me-restart worker yang mati dan memberikan visibility penuh melalui log dan status monitoring. Untuk memastikan performa optimal, lakukan pengecekan berkala melalui command `sudo supervisorctl status` atau manfaatkan web interface Supervisor yang telah kita setup.

**Best Practice**: 
- Monitor log file worker secara regular untuk mendeteksi potential issues
- Setup alert notification jika terjadi kegagalan pada worker
- Sesuaikan jumlah worker (`numprocs`) dengan kebutuhan dan kapasitas server Anda

Pertanyaan atau kendala seputar implementasi Supervisor untuk Laravel queue? Jangan ragu untuk bertanya di kolom komentar di bawah!