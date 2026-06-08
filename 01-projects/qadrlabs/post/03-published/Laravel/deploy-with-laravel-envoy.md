---
title: "Deploy with Laravel Envoy"
slug: "deploy-with-laravel-envoy"
category: "Laravel"
date: "2025-02-17"
status: "published"
---

## Introduction {#introduction}

Proses deployment aplikasi Laravel sering kali menjadi tantangan tersendiri bagi para developer. Di era pengembangan yang serba cepat seperti sekarang, efisiensi dan keandalan dalam proses deployment menjadi kunci utama dalam mempertahankan kualitas aplikasi. Sementara banyak developer masih menghadapi kesulitan dengan proses deployment manual yang rentan terhadap kesalahan, Laravel Envoy hadir sebagai solusi yang menyederhanakan dan mengotomatisasi seluruh alur kerja deployment.

Bayangkan situasi ini: Anda telah menghabiskan waktu berjam-jam untuk menulis kode, melakukan debugging, dan menjalankan testing aplikasi. Namun ketika tiba saatnya deployment, berbagai kendala teknis muncul yang mengharuskan Anda mengulang proses dari awal. Situasi seperti ini tidak hanya menghabiskan waktu, tetapi juga berpotensi menghambat produktivitas tim Anda. Justru di sinilah Laravel Envoy berperan penting - mengubah proses deployment yang kompleks menjadi alur kerja yang terstruktur, efisien, dan terotomatisasi.

Baik Anda seorang developer Laravel berpengalaman maupun baru memulai dengan otomatisasi deployment, panduan lengkap ini akan membantu Anda memahami segala hal yang perlu diketahui tentang Laravel Envoy. Mulai dari setup dasar hingga strategi deployment tingkat lanjut, kita akan menjelajahi bagaimana tool yang elegan ini dapat merevolusi alur kerja deployment Anda dan menghemat waktu yang biasanya terbuang untuk pekerjaan manual.

Siap untuk mengetahui bagaimana Laravel Envoy dapat membuat proses deployment Anda lebih efisien, andal, dan terstruktur? Mari kita mulai petualangan menguasai teknik deployment otomatis dengan Laravel Envoy.

## Overview{#overview}  

Sebelum kita masuk ke tutorial lengkapnya, mari kita bahas dulu apa yang akan Anda pelajari di artikel ini. Pertama-tama, kita akan mulai dengan pengenalan singkat tentang Laravel Envoy dan mengapa alat ini begitu penting dalam dunia development. Setelah itu, kita akan membahas cara instalasi dan konfigurasi Envoy, serta bagaimana menulis script deployment pertama Anda.  

Selain itu, kita juga akan melihat beberapa fitur canggih dari Envoy, seperti penggunaan variabel, task chaining, dan integrasi dengan SSH. Tidak hanya itu, kita juga akan membahas beberapa tips dan trik untuk memastikan deployment Anda berjalan lancar tanpa kendala.  

Di akhir artikel, Anda akan memiliki pemahaman yang solid tentang cara menggunakan Laravel Envoy untuk deployment aplikasi. Dengan kata lain, Anda akan siap untuk mengambil alih proses deployment dan menjadikannya lebih otomatis, cepat, dan bebas stres.  

Jadi, apakah Anda penasaran bagaimana Laravel Envoy bisa membantu Anda? 

Mari kita mulai dengan pembahasan pertama: **Apa Itu Laravel Envoy?**  

## Apa Itu Laravel Envoy?{#apa-itu-laravel-envoy}  

Laravel Envoy adalah sebuah alat bantu (tool) yang dirancang khusus untuk mempermudah proses deployment aplikasi. Dibuat oleh Taylor Otwell, pencipta Laravel, Envoy memungkinkan Anda untuk menulis script deployment dalam format yang sederhana dan mudah dipahami.  

Envoy sendiri menggunakan sintaks Blade, yang mungkin sudah tidak asing lagi bagi Anda jika pernah bekerja dengan Laravel. Dengan sintaks ini, Anda bisa menulis task-task deployment dalam file bernama `Envoy.blade.php`. File ini nantinya akan dieksekusi di server remote melalui SSH.  

Bayangkan saja, alih-alih harus login ke server dan menjalankan perintah-perintah manual satu per satu, Anda cukup menjalankan satu perintah di terminal lokal Anda. Envoy akan mengurus sisanya. Praktis, bukan?  

Tapi tunggu dulu, apa sebenarnya yang membuat Envoy begitu istimewa dibandingkan alat deployment lainnya? Untuk menjawab pertanyaan itu, mari kita lanjutkan ke bagian berikutnya: **Mengapa Harus Menggunakan Laravel Envoy?**  

## Mengapa Harus Menggunakan Laravel Envoy?{#mengapa-harus-menggunakan-laravel-envoy}  

Jika Anda bertanya-tanya mengapa harus menggunakan Laravel Envoy dibandingkan alat deployment lainnya, jawabannya cukup sederhana: Envoy menawarkan kombinasi antara kemudahan penggunaan dan fleksibilitas. Di dunia development yang serba cepat ini, efisiensi adalah segalanya. Nah, Envoy hadir untuk memastikan bahwa proses deployment Anda tidak hanya cepat, tetapi juga bebas dari kerumitan.

### 1. **Sintaks yang Sederhana dan Familiar**  
Salah satu keunggulan utama Envoy adalah sintaksnya yang sangat mudah dipahami, terutama jika Anda sudah familiar dengan Laravel. Dengan menggunakan format Blade, Anda bisa menulis task-task deployment dalam cara yang mirip dengan menulis view di Laravel. Tidak perlu belajar bahasa baru atau sintaks rumit. Cukup tulis apa yang ingin Anda lakukan, dan Envoy akan menjalankannya.

Misalnya, jika Anda ingin melakukan pull dari repository Git, membersihkan cache aplikasi, dan merestart server web, Anda cukup menuliskannya dalam beberapa baris kode saja. Mudah, kan?

### 2. **Integrasi SSH yang Seamless**  
Envoy dirancang untuk bekerja langsung dengan server remote melalui SSH. Ini berarti Anda tidak perlu lagi login manual ke server setiap kali ingin melakukan deployment. Cukup konfigurasi koneksi SSH sekali, dan Envoy akan mengurus sisanya. Anda bahkan bisa menjalankan task di beberapa server sekaligus tanpa ribet.

### 3. **Task Chaining yang Praktis**  
Salah satu fitur unggulan Envoy adalah kemampuannya untuk "merantai" (chain) beberapa task menjadi satu alur kerja. Misalnya, Anda bisa membuat sebuah task yang secara otomatis melakukan pull kode, menjalankan migrasi database, membersihkan cache, dan merestart server web dalam satu perintah. Bayangkan betapa banyak waktu yang bisa Anda hemat!

### 4. **Fleksibilitas dalam Penggunaan Variabel**  
Envoy juga mendukung penggunaan variabel, yang membuatnya sangat fleksibel. Anda bisa menentukan variabel seperti nama branch Git, direktori aplikasi, atau bahkan kredensial SSH langsung di file `Envoy.blade.php`. Dengan cara ini, Anda bisa menggunakan satu file Envoy untuk beberapa proyek atau lingkungan (development, staging, production) tanpa harus menulis ulang semuanya.

### 5. **Dokumentasi yang Lengkap**  
Laravel dikenal dengan dokumentasi yang sangat baik, dan Envoy tidak terkecuali. Semua fitur Envoy dijelaskan dengan detail di dokumentasi resmi Laravel. Jadi, jika Anda pernah merasa bingung atau butuh referensi, dokumentasi tersebut selalu siap membantu.

### 6. **Komunitas yang Aktif**  
Sebagai bagian dari ekosistem Laravel, Envoy didukung oleh komunitas developer yang sangat aktif. Jika Anda menemui kendala atau butuh ide baru, Anda bisa bergabung dengan forum-forum Laravel atau grup diskusi untuk mendapatkan bantuan. Komunitas ini juga sering berbagi tips dan trik tentang cara memaksimalkan penggunaan Envoy.

---

## Instalasi Laravel Envoy{#instalasi-laravel-envoy}  

Nah, sekarang kita sudah tahu apa itu Laravel Envoy dan mengapa alat ini begitu istimewa. Langkah berikutnya adalah instalasi. Untungnya, instalasi Envoy sangat mudah dilakukan, bahkan untuk pemula sekalipun. Mari kita mulai!

### 1. **Prasyarat**  
Sebelum menginstal Envoy, pastikan Anda sudah memenuhi beberapa prasyarat berikut:
- PHP sudah terinstal di sistem Anda (minimal versi 8.1).
- Composer sudah terinstal dan dapat diakses melalui terminal.
- Akses SSH ke server remote tempat Anda ingin melakukan deployment.

### 2. **Instalasi via Composer**  
Untuk menginstal Envoy, Anda cukup menjalankan perintah berikut di terminal:

```bash
composer global require laravel/envoy
```

Perintah ini akan menginstal Envoy sebagai package global di sistem Anda. Setelah instalasi selesai, pastikan bahwa direktori global Composer sudah ada di PATH Anda. Biasanya, direktori ini berada di `~/.composer/vendor/bin`. Jika belum, tambahkan baris berikut ke file `.bashrc` atau `.zshrc` Anda:

```bash
export PATH="$HOME/.composer/vendor/bin:$PATH"
```

Setelah itu, jalankan perintah berikut untuk memastikan Envoy sudah terinstal dengan benar:

```bash
envoy --version
```

Jika instalasi berhasil, Anda akan melihat versi Envoy yang terinstal di terminal.

### 3. **Verifikasi Instalasi**  
Untuk memastikan bahwa Envoy berfungsi dengan baik, coba buat file `Envoy.blade.php` kosong di direktori proyek Anda:

```bash
touch Envoy.blade.php
```

Kemudian, jalankan perintah berikut:

```bash
envoy run
```

Jika Envoy terinstal dengan benar, Anda akan melihat pesan error yang menyatakan bahwa tidak ada task yang didefinisikan. Jangan khawatir, ini normal karena kita belum menulis task apa pun.

---

## Konfigurasi Dasar Laravel Envoy{#konfigurasi-dasar-laravel-envoy}  

Setelah instalasi selesai, langkah berikutnya adalah melakukan konfigurasi dasar. File `Envoy.blade.php` adalah jantung dari Envoy, karena di sinilah Anda akan menulis semua task deployment Anda. Mari kita lihat bagaimana cara mengonfigurasinya.

### 1. **Struktur Dasar File Envoy**  
File `Envoy.blade.php` memiliki struktur dasar yang sederhana. Berikut adalah contoh file Envoy paling dasar:

```php
@servers(['web' => 'user@192.168.1.1'])

@task('deploy', ['on' => 'web'])
    echo "Deploying the application..."
    cd /var/www/html
    git pull origin main
    php artisan migrate --force
    php artisan cache:clear
@endtask
```

Mari kita bahas satu per satu:
- **`@servers`**: Bagian ini digunakan untuk mendefinisikan server remote yang akan digunakan. Dalam contoh di atas, kita mendefinisikan server dengan nama `web` dan alamat SSH `user@192.168.1.1`.
- **`@task`**: Bagian ini digunakan untuk mendefinisikan task yang akan dijalankan. Dalam contoh di atas, kita mendefinisikan task bernama `deploy` yang akan dijalankan di server `web`.
- **Command Shell**: Di dalam task, Anda bisa menuliskan perintah-perintah shell yang ingin dijalankan, seperti `git pull`, `php artisan`, dan lain-lain.

### 2. **Menjalankan Task**  
Setelah file `Envoy.blade.php` siap, Anda bisa menjalankan task dengan perintah berikut:

```bash
envoy run deploy
```

Perintah ini akan menjalankan task `deploy` yang sudah kita definisikan di file Envoy. Envoy akan terhubung ke server remote melalui SSH dan menjalankan semua perintah yang ada di dalam task tersebut.

### 3. **Menggunakan Variabel**  
Salah satu fitur canggih Envoy adalah kemampuannya untuk menggunakan variabel. Misalnya, jika Anda ingin menggunakan branch Git yang berbeda untuk setiap deployment, Anda bisa mendefinisikan variabel seperti ini:

```php
@setup
    $branch = isset($branch) ? $branch : 'main';
@endsetup

@servers(['web' => 'user@192.168.1.1'])

@task('deploy', ['on' => 'web'])
    echo "Deploying branch {{ $branch }}..."
    cd /var/www/html
    git pull origin {{ $branch }}
    php artisan migrate --force
    php artisan cache:clear
@endtask
```

Kemudian, Anda bisa menjalankan task dengan variabel tertentu seperti ini:

```bash
envoy run deploy --branch=develop
```
## Menulis Script Deployment Pertama Anda{#menulis-script-deployment-pertama-anda}  

Setelah memahami dasar-dasar konfigurasi Laravel Envoy, sekarang saatnya untuk menulis script deployment pertama Anda. Jangan khawatir, kita akan melakukannya langkah demi langkah agar semuanya terasa lebih mudah dan menyenangkan.

### 1. **Persiapan Awal**  
Sebelum mulai menulis script, pastikan Anda sudah memiliki beberapa hal berikut:
- **Repository Git**: Aplikasi yang ingin Anda deploy harus tersedia di repository Git (misalnya GitHub, GitLab, atau Bitbucket).
- **Server Remote**: Pastikan server remote sudah siap dengan semua dependensi yang diperlukan, seperti PHP, Composer, dan web server (Apache/Nginx).
- **Koneksi SSH**: Anda harus memiliki akses SSH ke server remote dengan kredensial yang benar.

### 2. **Langkah-Langkah Deployment Dasar**  
Proses deployment biasanya melibatkan beberapa langkah umum, seperti pull kode dari repository, menjalankan migrasi database, membersihkan cache, dan merestart server web. Berikut adalah contoh script Envoy yang mencakup semua langkah tersebut:

```php
@servers(['web' => 'user@your-server-ip'])

@setup
    $repository = 'https://github.com/username/repo.git';
    $branch = isset($branch) ? $branch : 'main';
    $releaseDir = '/var/www/html';
@endsetup

@task('deploy', ['on' => 'web'])
    echo "Starting deployment..."

    # Pull the latest code from the repository
    echo "Pulling code from {{ $repository }}..."
    cd {{ $releaseDir }}
    git pull origin {{ $branch }}

    # Install dependencies using Composer
    echo "Installing dependencies..."
    composer install --no-dev --optimize-autoloader

    # Run database migrations
    echo "Running database migrations..."
    php artisan migrate --force

    # Clear application cache
    echo "Clearing cache..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache

    # Restart the web server
    echo "Restarting web server..."
    sudo systemctl restart apache2

    echo "Deployment completed successfully!"
@endtask
```

Mari kita bahas setiap bagian dari script ini:
- **`@setup`**: Bagian ini digunakan untuk mendefinisikan variabel yang akan digunakan dalam task. Dalam contoh ini, kita mendefinisikan URL repository Git, branch default (`main`), dan direktori aplikasi.
- **`git pull`**: Perintah ini digunakan untuk mengambil kode terbaru dari repository Git.
- **`composer install`**: Menginstal dependensi PHP menggunakan Composer. Opsi `--no-dev` memastikan bahwa paket development tidak diinstal di lingkungan production.
- **`php artisan migrate`**: Menjalankan migrasi database untuk memperbarui skema database.
- **`php artisan cache:clear`**: Membersihkan cache aplikasi untuk memastikan perubahan terbaru diterapkan.
- **`sudo systemctl restart apache2`**: Merestart server web Apache untuk menerapkan perubahan.

### 3. **Menjalankan Script Deployment**  
Setelah script siap, Anda bisa menjalankannya dengan perintah berikut:

```bash
envoy run deploy
```

Jika Anda ingin menggunakan branch lain (misalnya `develop`), Anda bisa menambahkan parameter `--branch` seperti ini:

```bash
envoy run deploy --branch=develop
```

Perintah ini akan menjalankan task `deploy` dengan branch `develop` sebagai target.

---

## Fitur Canggih Laravel Envoy{#fitur-canggih-laravel-envoy}  

Selain fitur dasar yang sudah kita bahas, Laravel Envoy juga dilengkapi dengan beberapa fitur canggih yang bisa membuat proses deployment Anda jadi lebih fleksibel dan efisien. Mari kita lihat beberapa di antaranya.

### 1. **Penggunaan Variabel**  
Seperti yang sudah disinggung sebelumnya, Envoy mendukung penggunaan variabel. Ini sangat berguna jika Anda ingin membuat script yang bisa digunakan di berbagai lingkungan (development, staging, production). Misalnya, Anda bisa mendefinisikan variabel untuk nama branch, direktori aplikasi, atau bahkan kredensial SSH.

Berikut adalah contoh penggunaan variabel dalam file Envoy:

```php
@setup
    $branch = isset($branch) ? $branch : 'main';
    $releaseDir = '/var/www/html';
@endsetup

@task('deploy', ['on' => 'web'])
    echo "Deploying branch {{ $branch }} to {{ $releaseDir }}..."
    cd {{ $releaseDir }}
    git pull origin {{ $branch }}
@endtask
```

Anda bisa menjalankan task ini dengan nilai variabel tertentu seperti ini:

```bash
envoy run deploy --branch=feature/new-feature
```

### 2. **Task Chaining**  
Envoy memungkinkan Anda untuk "merantai" (chain) beberapa task menjadi satu alur kerja. Misalnya, Anda bisa membuat task `prepare` untuk mempersiapkan lingkungan, task `deploy` untuk melakukan deployment, dan task `cleanup` untuk membersihkan file-file sementara. Kemudian, Anda bisa menjalankan semuanya dalam satu perintah.

Berikut adalah contoh task chaining:

```php
@task('prepare', ['on' => 'web'])
    echo "Preparing environment..."
    cd /var/www/html
    git fetch --all
@endtask

@task('deploy', ['on' => 'web'])
    echo "Deploying application..."
    cd /var/www/html
    git pull origin main
    composer install --no-dev --optimize-autoloader
@endtask

@task('cleanup', ['on' => 'web'])
    echo "Cleaning up temporary files..."
    rm -rf /var/www/html/storage/framework/cache/*
@endtask

@story('full-deploy')
    prepare
    deploy
    cleanup
@endstory
```

Dengan menggunakan story `full-deploy`, Anda bisa menjalankan ketiga task tersebut dalam satu perintah:

```bash
envoy run full-deploy
```

### 3. **Integrasi dengan SSH**  
Salah satu keunggulan utama Envoy adalah kemampuannya untuk terhubung langsung ke server remote melalui SSH. Anda bisa mendefinisikan beberapa server dalam file Envoy dan menjalankan task di semua server tersebut secara bersamaan.

Berikut adalah contoh penggunaan multi-server:

```php
@servers(['web-1' => 'user@192.168.1.1', 'web-2' => 'user@192.168.1.2'])

@task('deploy', ['on' => ['web-1', 'web-2']])
    echo "Deploying to {{ $server }}..."
    cd /var/www/html
    git pull origin main
@endtask
```

Dengan konfigurasi ini, task `deploy` akan dijalankan di kedua server (`web-1` dan `web-2`) secara paralel.

## Tips dan Trik untuk Deployment yang Lancar{#tips-dan-trik-untuk-deployment-yang-lancar}  

Meskipun Laravel Envoy dirancang untuk mempermudah proses deployment, ada beberapa tips dan trik tambahan yang bisa Anda terapkan untuk memastikan bahwa deployment berjalan lancar tanpa kendala. Berikut adalah beberapa di antaranya:

### 1. **Selalu Gunakan Branch yang Tepat**  
Salah satu kesalahan umum dalam deployment adalah menggunakan branch yang salah. Misalnya, Anda mungkin tidak sengaja mendeploy branch `develop` ke server production. Untuk menghindari hal ini, pastikan Anda selalu menentukan branch yang benar saat menjalankan task Envoy. Anda juga bisa menambahkan validasi di script Envoy untuk memastikan bahwa hanya branch tertentu (misalnya `main`) yang bisa dideploy ke production.

Contoh validasi branch:

```php
@setup
    $branch = isset($branch) ? $branch : 'main';
    if ($branch !== 'main') {
        die("Error: Deployment is only allowed for the 'main' branch.");
    }
@endsetup
```

### 2. **Backup Database Sebelum Migrasi**  
Sebelum menjalankan migrasi database, selalu lakukan backup terlebih dahulu. Ini adalah langkah penting untuk memastikan bahwa data Anda aman jika terjadi kesalahan selama migrasi. Anda bisa menambahkan perintah backup ke dalam task Envoy seperti ini:

```php
@task('backup', ['on' => 'web'])
    echo "Backing up database..."
    mysqldump -u username -p password database_name > /path/to/backup.sql
@endtask

@story('safe-deploy')
    backup
    deploy
@endstory
```

Dengan cara ini, Anda bisa menjalankan backup sebelum melakukan deployment dengan perintah:

```bash
envoy run safe-deploy
```

### 3. **Gunakan Environment Variables untuk Kredensial Sensitif**  
Jangan pernah menyimpan kredensial sensitif (seperti password database atau API keys) langsung di file Envoy. Sebagai gantinya, gunakan environment variables. Anda bisa mendefinisikan variabel tersebut di server remote atau menggunakan file `.env` di proyek Anda.

Contoh penggunaan environment variables:

```php
@task('deploy', ['on' => 'web'])
    echo "Deploying application..."
    cd /var/www/html
    git pull origin main
    composer install --no-dev --optimize-autoloader
    php artisan migrate --force
    php artisan config:cache
@endtask
```

Pastikan file `.env` di server sudah diperbarui dengan kredensial yang benar sebelum menjalankan deployment.

### 4. **Uji Script Lokal Sebelum Digunakan di Production**  
Sebelum menggunakan script Envoy di server production, selalu uji terlebih dahulu di lingkungan lokal atau staging. Ini akan membantu Anda mengidentifikasi potensi masalah sebelum deployment ke production. Anda bisa menggunakan tools seperti Docker untuk mensimulasikan lingkungan production di lokal.

### 5. **Gunakan Logging untuk Debugging**  
Untuk mempermudah debugging, tambahkan logging ke dalam script Envoy. Anda bisa mengarahkan output dari setiap perintah ke file log agar lebih mudah dilacak jika terjadi error.

Contoh logging:

```php
@task('deploy', ['on' => 'web'])
    echo "Deploying application..." >> /var/log/deploy.log
    cd /var/www/html
    git pull origin main >> /var/log/deploy.log 2>&1
    composer install --no-dev --optimize-autoloader >> /var/log/deploy.log 2>&1
    php artisan migrate --force >> /var/log/deploy.log 2>&1
    php artisan config:cache >> /var/log/deploy.log 2>&1
@endtask
```

File `/var/log/deploy.log` akan berisi semua output dari proses deployment, sehingga Anda bisa melihat apa yang terjadi jika ada masalah.

### 6. **Optimalkan Cache untuk Performa Lebih Baik**  
Setelah deployment selesai, pastikan Anda membersihkan dan mengoptimalkan cache aplikasi. Ini termasuk cache konfigurasi, route, dan view. Dengan cara ini, aplikasi Anda akan berjalan lebih cepat karena tidak perlu memuat ulang data dari file atau database.

Contoh optimasi cache:

```php
@task('optimize', ['on' => 'web'])
    echo "Optimizing application..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
@endtask
```

Tambahkan task `optimize` ke dalam story deployment Anda untuk memastikan bahwa cache selalu dioptimalkan setelah deployment.

---

## Kesimpulan{#kesimpulan}  

Deployment aplikasi sering kali menjadi bagian yang paling menegangkan dalam siklus hidup pengembangan software. Namun, dengan alat seperti Laravel Envoy, proses ini bisa menjadi jauh lebih mudah, cepat, dan bebas stres. Dalam artikel ini, kita telah membahas secara mendalam tentang cara menggunakan Laravel Envoy untuk deployment aplikasi.

Mulai dari instalasi hingga penulisan script deployment pertama Anda, kita juga telah melihat fitur-fitur canggih seperti penggunaan variabel, task chaining, dan integrasi SSH. Selain itu, kami juga memberikan beberapa tips dan trik untuk memastikan bahwa deployment Anda berjalan lancar tanpa kendala.

Jadi, apakah Anda siap untuk mencoba *Deploy with Laravel Envoy*? Dengan alat ini, Anda tidak hanya akan menghemat waktu, tetapi juga meningkatkan efisiensi dan akurasi dalam proses deployment. Ingatlah untuk selalu menguji script Anda sebelum digunakan di production, dan jangan ragu untuk bereksperimen dengan fitur-fitur baru yang ditawarkan oleh Envoy.

Semoga artikel ini bermanfaat bagi Anda, dan selamat mencoba! 😊