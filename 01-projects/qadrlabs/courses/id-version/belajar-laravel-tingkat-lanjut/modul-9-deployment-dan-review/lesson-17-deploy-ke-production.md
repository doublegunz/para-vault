## 1. Sebelum Anda Memulai

Anda telah membangun sebuah aplikasi lengkap di mesin lokal Anda. Lesson 16 menghasilkan sebuah build Vite yang dioptimalkan yang membundel CSS dan JavaScript yang dibutuhkan Catatku di production. Langkah terakhir adalah membuat semuanya tersedia di internet publik sehingga user nyata dapat menjangkaunya. Deployment lebih dari sekadar menyalin file: Anda menyediakan sebuah server, menginstal software yang tepat, mengonfigurasi database nyata, mengamankan trafik dengan HTTPS, mengunci permission file, dan menjaga background worker tetap hidup setelah setiap reboot.

Lesson ini memandu deployment Catatku yang nyata dan end-to-end ke sebuah VPS Ubuntu yang baru menggunakan Nginx, PHP-FPM 8.3, MariaDB, dan Supervisor. Anda akan men-deploy ke sebuah domain yang Anda miliki sendiri, jadi siapkan satu sebelum memulai: domain apa pun dari registrar mana pun (Niagahoster, Namecheap, Cloudflare, dan lainnya) berfungsi, dan sebuah subdomain dari domain yang sudah Anda miliki juga tidak masalah. Karena domain setiap pembaca berbeda, lesson ini menggunakan `catatku.example.com` sebagai placeholder; setiap kali ia muncul di sebuah perintah atau file konfigurasi, ganti dengan domain Anda sendiri. Aplikasi ditarik dari `https://github.com/qadrLabs/catatku-deploy-demo`, sebuah versi Catatku yang siap-deploy yang sudah menyertakan setup build Vite dari Lesson 16; jika Anda telah mengikuti dan mendorong Catatku Anda sendiri ke GitHub, clone repository pribadi Anda sebagai gantinya. Anda akan memperoleh sebuah sertifikat SSL gratis dari Let's Encrypt, mengonfigurasi `.env` production, menyiapkan sebuah model ownership yang aman di mana deploy user Anda sendiri memiliki kode dan `www-data` hanya membacanya (dengan akses tulis ACL pada dua direktori yang dapat ditulis), menjalankan queue worker sebagai service yang terkelola, dan mempelajari alur kerja `git pull` sederhana untuk mengirim pembaruan di masa depan. Di akhir Anda akan memiliki sebuah site HTTPS, sebuah queue worker yang sehat, dan sebuah skrip deployment yang dapat diulang.

### What You'll Build

Anda akan men-deploy Catatku ke sebuah VPS Ubuntu sehingga ia dapat dijangkau melalui HTTPS di domain Anda sendiri. Dua queue worker akan berjalan secara permanen di bawah Supervisor, file aplikasi akan dimiliki oleh deploy user Anda sendiri (user SSH yang Anda gunakan untuk login) sementara `www-data` mendapatkan akses read-only ke kode ditambah akses tulis ACL ke dua direktori yang harus ditulis Laravel, dan Anda akan menyimpan sebuah skrip shell pendek yang melakukan seluruh alur pembaruan dengan satu perintah.

![preview app](https://cdn.jsdelivr.net/gh/qadrLabs/catatku-deploy-demo@main/docs/screenshot/01-preview-app.png)

### What You'll Learn

- ✅ Menyiapkan VPS Ubuntu untuk Laravel (Nginx, PHP 8.3, MariaDB, Supervisor, Certbot)
- ✅ Mengarahkan DNS dan memperoleh sertifikat SSL melalui Let's Encrypt
- ✅ Konfigurasi `.env` production dengan `APP_DEBUG=false`, MariaDB, dan database driver
- ✅ Model ownership yang aman: deploy user Anda memiliki kode, `www-data` read-only padanya, dengan ACL yang memberikan akses tulis hanya ke `storage/` dan `bootstrap/cache/`
- ✅ Mengoptimalkan Laravel dengan `php artisan optimize`
- ✅ Menjalankan queue worker secara permanen dengan Supervisor (driver `database`)
- ✅ Memperbarui aplikasi dengan alur kerja `git pull` sederhana

### What You'll Need

- Lesson 16 sudah selesai
- Sebuah VPS Ubuntu 24.04 dengan akses SSH dan `sudo`
- Sebuah domain (atau subdomain) yang Anda miliki, dengan akses ke panel manajemen DNS-nya; Anda akan mengarahkannya ke VPS di Section 2, dan lesson ini menggunakan `catatku.example.com` sebagai placeholder untuknya
- Sebuah akun GitHub yang dapat meng-clone `https://github.com/qadrLabs/catatku-deploy-demo` (atau repository Catatku Anda sendiri)

---

## 2. Menyiapkan Server

Sebuah VPS Ubuntu yang bersih tidak memiliki software apa pun yang dibutuhkan Catatku. Sebelum Anda dapat menjalankan satu perintah artisan pun, Anda harus menginstal web server, database, runtime PHP dengan ekstensi yang tepat, dan tool pendukung. Setelah software terinstal, arahkan domain ke server sehingga Anda dapat memperoleh sertifikat SSL nanti. Section ini mencakup kedua langkah secara berurutan.

### Step 1: Menginstal Software yang Diperlukan

SSH ke VPS dan perbarui daftar package terlebih dahulu. Lalu instal Nginx, MariaDB, PHP 8.3 dengan ekstensi yang dibutuhkan Laravel, Composer, Git, Supervisor, dan Certbot dalam satu perintah. Lesson ini menargetkan Ubuntu 24.04 secara khusus karena repository default-nya menyertakan PHP 8.3, versi yang dibutuhkan Catatku; rilis Ubuntu yang lebih lama menyertakan versi PHP yang lebih lama, sehingga package `php8.3-*` di bawah tidak akan ditemukan di sana tanpa menambahkan repository pihak ketiga.

```bash
sudo apt update
sudo apt install -y nginx mariadb-server php8.3-fpm php8.3-cli \
    php8.3-mysql php8.3-mbstring php8.3-xml php8.3-curl php8.3-zip \
    php8.3-bcmath php8.3-gd php8.3-intl php8.3-tokenizer php8.3-fileinfo \
    composer git unzip supervisor certbot python3-certbot-nginx acl
```

Setiap package memainkan peran spesifik. `nginx` adalah web server yang menerima request HTTPS dari internet. `mariadb-server` adalah database production; ia adalah fork yang kompatibel drop-in dari MySQL yang dikelola oleh penulis MySQL asli. `php8.3-fpm` adalah FastCGI Process Manager yang menjalankan kode PHP Anda di belakang Nginx, dan `php8.3-cli` adalah binary PHP command-line yang digunakan Artisan. `php8.3-mysql` adalah driver PDO yang digunakan Laravel untuk berkomunikasi dengan MariaDB (package mempertahankan nama legacy `mysql` meskipun ia juga menjalankan MariaDB). Package `php8.3-*` yang tersisa mengaktifkan ekstensi yang dibutuhkan Laravel untuk penanganan string, XML, HTTP, file arsip, matematika, generasi gambar, internasionalisasi, tokenizing, dan metadata file. `composer` menginstal dependensi PHP, `git` menarik kode Anda dari GitHub, `unzip` dibutuhkan oleh Composer untuk package arsip, `supervisor` menjaga queue worker tetap berjalan, dan dua package Certbot memperoleh dan memperbarui otomatis sertifikat SSL Let's Encrypt. `acl` menyediakan perintah `setfacl` yang akan Anda gunakan di Section 3 untuk memberikan akses tulis `www-data` ke `storage/` dan `bootstrap/cache/` tanpa menjadikannya pemilik kode Anda.

Repository default Ubuntu sering menyertakan versi Node.js yang usang, tetapi Vite 8 (bundler yang Anda konfigurasi di Lesson 16) membutuhkan Node 20.19 atau yang lebih baru, atau 22.12 atau yang lebih baru. Node 20 mencapai akhir masa hidupnya pada April 2026 dan tidak lagi menerima pembaruan keamanan, sehingga server baru seharusnya menjalankan Node 22 LTS. Instal dari repository NodeSource resmi.

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
```

Perintah pertama menambahkan repository NodeSource yang ditandatangani untuk Node.js 22 LTS ke apt. Perintah kedua menginstal package `nodejs` dari repository tersebut, yang membundel `npm`. Verifikasi versi dengan `node -v` (seharusnya mencetak `v22.x.x`) dan konfirmasi PHP pada 8.3 dengan `php -v`. Dengan versi Node yang terlalu lama, `npm run build` akan gagal dengan error kriptik jauh di dalam Vite atau plugin-nya.

```
gungun@qadrlabs:$ node -v
v22.22.3
gungun@qadrlabs:$ php -v
PHP 8.3.6 (cli) (built: May 25 2026 13:12:06) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.3.6, Copyright (c) Zend Technologies
    with Zend OPcache v8.3.6, Copyright (c), by Zend Technologies
```

Nomor patch Anda mungkin sedikit berbeda, tetapi versi major harus terbaca `v22` untuk Node dan `8.3` untuk PHP. Jika `node -v` masih menampilkan versi major yang lebih lama, langkah NodeSource tidak berlaku; jalankan ulang dua perintah di atas sebelum melanjutkan.

### Step 2: Mengarahkan Domain ke Server

Tanpa sebuah DNS record yang berfungsi, Certbot tidak dapat membuktikan Anda memiliki domain dan akan menolak menerbitkan sertifikat. Login ke panel DNS dari penyedia tempat Anda mendaftarkan domain Anda (Cloudflare, Niagahoster, Namecheap, dll.) dan buat sebuah A record yang memetakan domain Anda ke IP publik VPS Anda.

| Type | Name      | Value                |
|------|-----------|----------------------|
| A    | `catatku` | IP publik VPS        |

Field `Name` hanya berisi bagian subdomain, bukan domain lengkap: untuk placeholder `catatku.example.com`, bagian itu adalah `catatku`. Jika Anda men-deploy pada subdomain Anda sendiri (misalnya `app.mydomain.com`), masukkan subdomain tersebut (`app`) sebagai gantinya. Jika Anda men-deploy pada root domain itu sendiri (misalnya `mydomain.com` tanpa subdomain), sebagian besar penyedia menggunakan `@` sebagai nama.

Setelah menyimpan record, verifikasi ia telah dipropagasi dengan menjalankan `dig` dari VPS itu sendiri. Ingat untuk mengganti placeholder dengan domain Anda sendiri.

```bash
dig +short catatku.example.com
```

Output harus cocok dengan IP publik VPS Anda secara persis. Jika output kosong atau menampilkan alamat yang berbeda, tunggu beberapa menit untuk propagasi DNS, lalu jalankan perintah lagi. Jangan lanjut ke langkah SSL sampai `dig` mengembalikan IP yang benar, jika tidak Certbot akan gagal dan Anda akan menghabiskan waktu mengejar masalah yang sebenarnya terkait DNS.

---

## 3. Men-deploy Kode Aplikasi

Server sekarang memiliki software yang tepat dan domain meresolusi ke IP-nya, jadi Anda dapat menarik kode aplikasi ke disk. Section ini meng-clone repository, menginstal dependensi, membuat `.env` production, dan mengunci ownership serta permission file.

### Step 1: Meng-clone Repository

Lokasi konvensional untuk aplikasi web di Ubuntu adalah `/var/www`. Buat direktori proyek dan berikan ownership ke user SSH Anda sehingga Anda dapat menjalankan `git clone`, `composer install`, dan `npm install` tanpa `sudo` pada setiap perintah. User SSH Anda mempertahankan ownership secara permanen di lesson ini: ia adalah *deploy user* Anda, akun yang Anda gunakan untuk mengirim kode. Di Step 4 Anda akan memberikan `www-data` akses baca ke kode melalui keanggotaan group dan akses tulis ke hanya dua direktori melalui ACL, sehingga web server tidak pernah perlu memiliki kode Anda.

```bash
sudo mkdir -p /var/www/catatku
sudo chown -R $USER:$USER /var/www/catatku
git clone https://github.com/qadrLabs/catatku-deploy-demo.git /var/www/catatku
cd /var/www/catatku
```

Lesson ini meng-clone `qadrLabs/catatku-deploy-demo`, sebuah versi lengkap Catatku yang sudah menyertakan konfigurasi build Vite yang Anda siapkan di Lesson 16. Jika Anda telah mengikuti course dan mendorong Catatku Anda sendiri ke GitHub, ganti URL di atas dengan repository pribadi Anda sehingga Anda men-deploy kode yang sebenarnya Anda tulis. **Jangan** clone repository course pemula di sini: ia berhenti sebelum langkah build frontend, sehingga `npm run build` nanti di section ini akan gagal dengan error karena setup Vite belum ada.

`sudo mkdir -p` membuat `/var/www/catatku` dan direktori parent yang hilang. `chown -R $USER:$USER` mentransfer ownership ke user shell Anda saat ini; `$USER` berkembang menjadi siapa pun yang login, sehingga Anda tidak perlu mengetik username Anda secara manual. `git clone` lalu menyalin repository ke dalam direktori. `cd` terakhir berpindah ke root proyek sehingga setiap perintah berikutnya berjalan dari sana. Deploy user Anda mempertahankan ownership kode mulai dari sini; Step 4 hanya menyesuaikan group dan menambahkan ACL sehingga `www-data` dapat membaca kode dan menulis ke dua direktori yang dibutuhkan Laravel.

### Step 2: Menginstal Dependensi PHP dan Node

Dependensi production diinstal tanpa package dev (Pest, Pint, debug tool) dan dengan autoloader yang dioptimalkan. Bundle frontend dikompilasi sekali ke dalam `public/build/` dan dilayani sebagai file statis dari sana.

```bash
composer install --no-dev --optimize-autoloader
npm ci
npm run build
```

`--no-dev` melewati package yang terdaftar di bawah `require-dev` di `composer.json`, yang menjaga instalasi production tetap lebih kecil dan bebas dari tooling development. `--optimize-autoloader` membangun sebuah classmap statis yang digunakan Composer untuk autoloading, yang mempercepat setiap request sekitar 2x dibandingkan traversal PSR-4 default. `npm ci` menginstal package Node dari `package-lock.json` secara deterministik, sehingga dua server yang menjalankan perintah ini selalu berakhir dengan pohon `node_modules/` yang persis sama. `npm run build` memanggil Vite, yang mengompilasi CSS dan JavaScript Anda ke dalam file yang ber-hash dan diminifikasi di dalam `public/build/`. Setelah langkah ini, Node dan dependensinya tidak lagi dibutuhkan saat runtime, tetapi Anda dapat tetap menginstalnya untuk rebuild di masa depan.

### Step 3: Membuat File `.env` Production

Environment lokal dan production tidak boleh berbagi file `.env`. Production membutuhkan `APP_KEY`-nya sendiri, kredensial database-nya sendiri, dan `APP_DEBUG=false`. Mulai dengan menyalin file contoh dan menghasilkan application key yang baru.

```bash
cp .env.example .env
php artisan key:generate
```

`cp .env.example .env` membuat `.env` kerja dari template yang disertakan repository. `php artisan key:generate` menimpa baris `APP_KEY` dengan sebuah string base64 32-byte yang baru dihasilkan. Key ini digunakan untuk mengenkripsi session dan cookie, sehingga setiap environment harus memiliki miliknya sendiri; menggunakan kembali key lokal di production adalah kesalahan keamanan.

Buka `/var/www/catatku/.env` di sebuah editor terminal. Lesson ini menggunakan `nano`, yang terinstal secara default di Ubuntu dan merupakan pilihan paling ramah jika Anda belum pernah mengedit file melalui SSH sebelumnya.

```bash
nano /var/www/catatku/.env
```

Di dalam nano, gunakan tombol panah untuk bergerak dan ketik secara normal. Ketika Anda selesai, simpan dengan `Ctrl+O` lalu `Enter`, dan keluar dengan `Ctrl+X`. Petunjuk shortcut di bagian bawah layar menulis `^` untuk tombol `Ctrl`. Anda akan menggunakan `nano` lagi nanti untuk file Nginx, Supervisor, dan deploy-script, sehingga shortcut yang sama berlaku di sepanjang lesson ini.

Ganti konten file dengan konfigurasi production berikut. Dua nilai membutuhkan perhatian Anda sebelum menyimpan: ganti setiap kemunculan `catatku.example.com` dengan domain Anda sendiri, dan pertahankan baris `APP_KEY` yang baru saja ditulis `key:generate` (placeholder `THE_VALUE_FROM_KEY_GENERATE` di bawah mewakili nilai yang dihasilkan itu, jadi jangan menimpanya).

```env
APP_NAME=Catatku
APP_ENV=production
APP_KEY=base64:THE_VALUE_FROM_KEY_GENERATE
APP_DEBUG=false
APP_URL=https://catatku.example.com

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=mariadb
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=catatku_production
DB_USERNAME=catatku_user
DB_PASSWORD=REPLACE_WITH_A_STRONG_PASSWORD

BROADCAST_CONNECTION=log
CACHE_STORE=database
QUEUE_CONNECTION=database
SESSION_DRIVER=database
SESSION_LIFETIME=120

MAIL_MAILER=smtp
MAIL_HOST=smtp.mailgun.org
MAIL_PORT=587
MAIL_USERNAME=postmaster@mg.catatku.example.com
MAIL_PASSWORD=REPLACE_WITH_SMTP_PASSWORD
MAIL_FROM_ADDRESS=hello@catatku.example.com
MAIL_FROM_NAME="${APP_NAME}"
```

Telusuri nilai-nilai yang paling penting. `APP_ENV=production` membalik Laravel ke perilaku production: ia menyembunyikan stack trace dari output browser, menyederhanakan halaman error, dan mengaktifkan beberapa pemeriksaan keamanan. `APP_DEBUG=false` adalah satu pengaturan production yang paling penting; jika dibiarkan `true`, setiap halaman exception mengekspos nilai `.env`, path file, dan stack trace Anda ke siapa pun di internet yang memicu sebuah error. `APP_URL` harus cocok dengan domain yang dilayani Nginx, jika tidak URL yang dihasilkan (email reset password, redirect, path aset dalam beberapa skenario) akan menunjuk ke tempat yang salah. `DB_CONNECTION=mariadb` memberi tahu Laravel untuk menggunakan blok `mariadb` di `config/database.php` alih-alih blok `mysql` yang lebih lama; keduanya berfungsi terhadap server MariaDB, tetapi blok khusus menggunakan dialect dan opsi default yang benar. `CACHE_STORE`, `QUEUE_CONNECTION`, dan `SESSION_DRIVER` semuanya diatur ke `database` sehingga semuanya disimpan di MariaDB: tidak ada service tambahan untuk diinstal, tidak ada port tambahan untuk di-firewall, dan kapasitas yang lebih dari cukup untuk site kecil hingga menengah. Akhirnya, `MAIL_MAILER=smtp` ditambah penyedia nyata (Mailgun ditampilkan di sini, tetapi layanan SMTP apa pun berfungsi) memastikan email benar-benar mencapai user; jangan pernah membiarkan `MAIL_MAILER=log` di production karena email akan diam-diam menumpuk di file log alih-alih dikirim. Perhatikan bahwa tidak ada baris `MAIL_SCHEME`: pada port 587, Laravel men-default scheme ke `smtp` dan koneksi ditingkatkan menjadi yang terenkripsi secara otomatis melalui STARTTLS, sehingga enkripsi tetap terjadi tanpa pengaturan ekstra. Hanya atur `MAIL_SCHEME=smtps` jika penyedia Anda membutuhkan port 465. Nilai lain apa pun (seperti `tls`) ditolak oleh mailer dengan sebuah exception "unsupported scheme" pertama kali aplikasi mencoba mengirim sebuah email.

### Step 4: Mengatur Permission File

Permission yang salah adalah kegagalan deploy-pertama yang paling umum. Model yang aman memiliki tiga aturan. Pertama, deploy user Anda (`$USER`) memiliki setiap file dan group diatur ke `www-data`, sehingga web server dapat *membaca* kode tetapi tidak memodifikasinya. Kedua, direktori menggunakan `755` dan file menggunakan `644`, yang memberi group (dan karena itu `www-data`) akses baca dan traverse tetapi tidak ada akses tulis ke kode. Ketiga, satu-satunya dua direktori yang harus ditulis Laravel saat runtime, `storage/` dan `bootstrap/cache/`, mendapatkan `775` ditambah sebuah ACL yang memberikan `www-data` akses tulis, termasuk pada file yang dibuat nanti.

```bash
sudo chown -R $USER:www-data /var/www/catatku
sudo find /var/www/catatku -type d -exec chmod 755 {} \;
sudo find /var/www/catatku -type f -exec chmod 644 {} \;

sudo chmod 640 /var/www/catatku/.env

sudo chmod -R 775 /var/www/catatku/storage /var/www/catatku/bootstrap/cache
sudo setfacl -R  -m u:www-data:rwX,g:www-data:rwX /var/www/catatku/storage /var/www/catatku/bootstrap/cache
sudo setfacl -dR -m u:www-data:rwX,g:www-data:rwX /var/www/catatku/storage /var/www/catatku/bootstrap/cache
```

`chown -R $USER:www-data` mempertahankan deploy user Anda sebagai pemilik dan mengatur group ke `www-data`. Ini adalah inti dari model yang aman: karena `www-data` (user yang menjalankan PHP-FPM) tidak memiliki kode dan file tidak dapat ditulis oleh group, sebuah proses PHP yang dikompromikan tidak dapat menulis ulang source aplikasi Anda. Dua perintah `find` menormalisasi permission di seluruh pohon: direktori mendapatkan `755` (`rwxr-xr-x`) sehingga group dapat masuk ke dalamnya, file mendapatkan `644` (`rw-r--r--`) sehingga group dapat membaca tetapi tidak menulisnya. `chmod 640 .env` lebih ketat lagi: `.env` menyimpan password database dan `APP_KEY` Anda, sehingga ia hanya dapat dibaca oleh Anda (pemilik) dan `www-data` (group), dan tidak terlihat oleh setiap akun lain di box.

Jangan gunakan `chmod -R 777` di mana pun; ia memberikan akses tulis ke setiap user di sistem, termasuk proses apa pun yang berhasil dijalankan seorang penyerang. Sebagai gantinya, dua direktori yang dapat ditulis mendapatkan `775` *dan* sebuah ACL. `setfacl -R` pertama memberikan user dan group `www-data` `rwX` (`X` menambahkan execute bit hanya ke direktori, tidak pernah ke file biasa) pada semua yang saat ini berada di bawah `storage/` dan `bootstrap/cache/`. `setfacl -dR` kedua mengatur sebuah ACL *default*, yang diwarisi secara otomatis oleh setiap file dan direktori baru yang dibuat di dalam pohon tersebut. Ini adalah bagian yang tidak dapat dilakukan `chmod` biasa: selama deploy *Anda* menulis ke `bootstrap/cache/` (melalui `php artisan optimize`), sementara saat runtime *`www-data`* menulis ke `storage/logs/` dan `storage/framework/`. Dengan dua user berbeda menulis direktori yang sama, sebuah umask default akan membiarkan file baru satu sama lain tidak dapat ditulis; ACL default menjamin `www-data` selalu mendapatkan akses tulis terlepas dari siapa yang membuat file. Jika ada langkah deployment nanti mengeluh tentang permission di `storage/logs/laravel.log` atau `bootstrap/cache/config.php`, jalankan ulang tiga perintah `chmod`/`setfacl` di atas.

---

## 4. Menyiapkan MariaDB

MariaDB diinstal di Section 2 tetapi ia masih memiliki kondisi default-nya: tidak ada database production, tidak ada user khusus, dan akun root dikonfigurasi untuk authentication socket lokal saja. Section ini mengamankan server, membuat database `catatku_production` dengan user yang terbatas, dan menjalankan migration aplikasi.

### Step 1: Mengamankan MariaDB

Tepat setelah instalasi, jalankan skrip keamanan resmi. Ia mengatur password root, menghapus user anonim, menghapus database test, dan menonaktifkan login root jarak jauh.

```bash
sudo mysql_secure_installation
```

Skrip menanyakan beberapa pertanyaan secara interaktif. Jawab dalam urutan ini:

1. **Enter current password for root**: tekan Enter (kosong pada instalasi baru).
2. **Switch to unix_socket authentication**: ketik `Y`. Ini adalah default Ubuntu dan memungkinkan root login melalui `sudo mariadb` tanpa password, sementara login jarak jauh tetap dinonaktifkan.
3. **Change the root password**: ketik `Y`, lalu ketik sebuah password yang kuat dua kali. (Tidak ada yang muncul di layar saat Anda mengetik password; itu normal.)
4. **Remove anonymous users**: ketik `Y`.
5. **Disallow root login remotely**: ketik `Y`.
6. **Remove test database and access to it**: ketik `Y`.
7. **Reload privilege tables now**: ketik `Y`.

Default-default ini aman dan direkomendasikan untuk server production mana pun. Sesi Anda seharusnya terlihat seperti contoh di bawah, di mana setiap prompt dijawab dengan `Y` (entri password disembunyikan saat Anda mengetik).

```
gungun@qadrlabs:$ sudo mysql_secure_installation

Enter current password for root (enter for none):
OK, successfully used password, moving on...

Switch to unix_socket authentication [Y/n] y
Enabled successfully!
Reloading privilege tables..
 ... Success!

Change the root password? [Y/n] y
New password:
Re-enter new password:
Password updated successfully!
Reloading privilege tables..
 ... Success!

Remove anonymous users? [Y/n] y
 ... Success!

Disallow root login remotely? [Y/n] y
 ... Success!

Remove test database and access to it? [Y/n] y
 - Dropping test database...
 ... Success!
 - Removing privileges on test database...
 ... Success!

Reload privilege tables now? [Y/n] y
 ... Success!

Cleaning up...

All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!
```

### Step 2: Membuat Database dan User Production

Login ke MariaDB sebagai root menggunakan authentication socket, lalu buat sebuah database khusus dan sebuah user yang hanya dapat mengakses satu database itu.

```bash
sudo mariadb
```

Setelah di prompt `MariaDB [(none)]>`, jalankan SQL berikut.

```sql
CREATE DATABASE catatku_production
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER 'catatku_user'@'localhost' IDENTIFIED BY 'REPLACE_WITH_A_STRONG_PASSWORD';
GRANT ALL PRIVILEGES ON catatku_production.* TO 'catatku_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

`utf8mb4` adalah character set yang mendukung rentang Unicode penuh, termasuk emoji; menggunakan `utf8` yang lebih lama (yang sebenarnya `utf8mb3` di MariaDB) akan merusak karakter 4-byte secara diam-diam. `utf8mb4_unicode_ci` adalah sebuah collation case-insensitive yang menangani pengurutan non-Inggris dengan benar. Akhiran `@'localhost'` pada `CREATE USER` membatasi akun ke koneksi socket dan TCP lokal, sehingga user tidak dapat dijangkau dari IP eksternal mana pun. `GRANT ALL PRIVILEGES ON catatku_production.*` memberi user kendali penuh atas database Catatku, tetapi tidak ada database lain di server, yang membatasi blast radius jika aplikasi dikompromikan. Password harus merupakan nilai persis yang Anda atur sebagai `DB_PASSWORD` di file `.env` dari Section 3 Step 3.

### Step 3: Menjalankan Migration

Dengan database dibuat, jalankan migration dari direktori proyek sebagai deploy user Anda. Tidak ada `sudo` di sini: Anda memiliki kode, sehingga perintah berjalan sebagai diri Anda sendiri, dan file apa pun yang ditulis Laravel selama migration mendarat di direktori yang sudah dibuat dapat ditulis oleh Anda dan `www-data` oleh ACL dari Section 3.

```bash
cd /var/www/catatku
php artisan migrate --force
```

`--force` dibutuhkan di production karena Laravel meminta konfirmasi interaktif secara default, dan prompt itu akan menggantung di shell non-interaktif atau gagal di sebuah skrip. Setelah perintah selesai, verifikasi kondisi migration dengan `php artisan migrate:status`; setiap migration harus terdaftar sebagai `Ran`. Ini juga mengonfirmasi aplikasi benar-benar dapat terhubung ke MariaDB menggunakan kredensial di `.env`.

### Step 4: Symlink Storage dan Optimize

Dua perintah terakhir menyelesaikan setup aplikasi: mengekspos upload user ke web server, lalu melakukan cache konfigurasi untuk performa.

```bash
php artisan storage:link
php artisan optimize
```

Jalankan keduanya sebagai deploy user Anda, tidak perlu `sudo`. `storage:link` membuat sebuah symbolic link dari `public/storage` ke `storage/app/public`. Tanpa link ini, cover image yang diupload di Lesson 7 tidak dapat dijangkau dari browser karena apa pun di luar `public/` disembunyikan dari Nginx secara desain. `php artisan optimize` adalah satu perintah kenyamanan Laravel 13 yang mengompilasi konfigurasi, route, Blade template, dan pemetaan event yang ditemukan otomatis ke dalam file PHP yang dioptimalkan di `bootstrap/cache/`. Ia menggantikan urutan lama `config:cache`, `route:cache`, `view:cache`, dan `event:cache`, dan biasanya mengurangi waktu request sebesar 15 hingga 30 persen karena Laravel tidak lagi mengurai ulang file-file tersebut pada setiap request. Jika Anda perlu membersihkan semua cache ini sekaligus, jalankan `php artisan optimize:clear`.

---

## 5. Mengonfigurasi Nginx dan HTTPS

Catatku terinstal tetapi Nginx belum mengetahuinya, dan belum ada sertifikat SSL. Section ini memperoleh sebuah sertifikat gratis dari Let's Encrypt dan menulis Nginx server block yang menterminasi HTTPS, meneruskan request PHP ke PHP-FPM, dan mengarahkan HTTP biasa ke HTTPS.

### Step 1: Memperoleh Sertifikat SSL

Let's Encrypt memverifikasi kepemilikan domain dengan membuat sebuah HTTP request ke sebuah path khusus pada port 80. Karena package Nginx default mulai pada port 80 segera setelah instalasi, Anda harus menghentikannya sebentar sehingga Certbot dapat mengikat ke port itu sendiri.

```bash
sudo systemctl stop nginx
sudo certbot certonly --standalone -d catatku.example.com \
    --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx"
```

`systemctl stop nginx` mematikan service Nginx default sehingga port 80 bebas. `certbot certonly` meminta sebuah sertifikat tanpa mencoba mengedit konfigurasi Nginx apa pun. `--standalone` memberi tahu Certbot untuk menjalankan sebuah web server sementara kecil pada port 80 untuk menjawab challenge HTTP ACME. Flag `-d` menamai domain yang sertifikatnya diterbitkan, jadi teruskan domain Anda sendiri di sini, persis seperti yang Anda konfigurasi di DNS. Setelah Let's Encrypt memvalidasi challenge, Certbot menyimpan sertifikat di `/etc/letsencrypt/live/catatku.example.com/fullchain.pem` dan private key di `/etc/letsencrypt/live/catatku.example.com/privkey.pem`; direktori di bawah `/etc/letsencrypt/live/` selalu dinamai menurut domain Anda yang sebenarnya.

Flag `--pre-hook` dan `--post-hook` menyelesaikan sebuah masalah yang seharusnya Anda alami dalam 90 hari. Sertifikat hanya valid selama itu, dan Certbot menginstal sebuah systemd timer yang memperbaruinya secara otomatis; verifikasi timer dengan `systemctl list-timers | grep certbot`. Tetapi pembaruan menjalankan challenge standalone yang sama, yang membutuhkan port 80, dan pada saat itu Nginx akan berjalan dan menempati port itu. Certbot menyimpan kedua hook ke dalam konfigurasi pembaruan di bawah `/etc/letsencrypt/renewal/`, sehingga setiap pembaruan otomatis menghentikan Nginx selama beberapa detik dan memulainya lagi setelahnya. Tanpa hook, setiap upaya pembaruan akan gagal karena port sibuk, dan sertifikat akan diam-diam kedaluwarsa setelah 90 hari. Setelah Nginx berjalan (setelah Step 3 di bawah), uji alur pembaruan penuh dengan `sudo certbot renew --dry-run`; ia harus melaporkan sukses untuk domain Anda.

### Step 2: Membuat Nginx Server Block

Buat sebuah file server block baru yang dikhususkan untuk Catatku. Biarkan site default tetap dinonaktifkan sehingga ia tidak mencuri port 80 dari domain Anda.

```bash
sudo nano /etc/nginx/sites-available/catatku
```

Tempel konten berikut ke dalam editor. Seperti pada file `.env`, ganti setiap `catatku.example.com` dengan domain Anda sendiri: ia muncul di kedua directive `server_name` dan di dua path sertifikat.

```nginx
server {
    listen 443 ssl http2;
    server_name catatku.example.com;

    ssl_certificate /etc/letsencrypt/live/catatku.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/catatku.example.com/privkey.pem;

    root /var/www/catatku/public;
    index index.php;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    charset utf-8;
    client_max_body_size 10M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ ^/index\.php(/|$) {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}

server {
    listen 80;
    server_name catatku.example.com;
    return 301 https://$server_name$request_uri;
}
```

Telusuri setiap bagian. `listen 443 ssl http2` menerima koneksi HTTPS pada port 443 dan mengaktifkan HTTP/2 untuk request yang di-multiplex, yang membuat halaman dengan banyak aset dimuat lebih cepat. Dua baris `ssl_certificate` menunjuk ke file Certbot yang ditulis di Step 1; jika path tersebut salah, Nginx gagal start. `root /var/www/catatku/public` adalah baris yang kritis untuk keamanan: Nginx hanya melayani file di dalam `public/`, sehingga file `.env`, source code Anda, dan pohon vendor composer Anda secara fisik berada di luar document root dan tidak dapat dijangkau melalui URL. Header `X-Frame-Options` dan `X-Content-Type-Options` melindungi terhadap serangan clickjacking dan MIME-sniffing. `client_max_body_size 10M` cocok dengan batas upload cover image yang diperkenalkan di Lesson 7; naikkan jika aplikasi Anda menerima upload yang lebih besar. Directive `try_files $uri $uri/ /index.php?$query_string` adalah fallback routing Laravel standar: coba file yang diminta, lalu sebuah index direktori, jika tidak serahkan request ke `index.php` sehingga router Laravel dapat meresolusinya. Blok location PHP meneruskan request `.php` ke PHP-FPM melalui Unix socket-nya, yang lebih cepat daripada koneksi TCP di mesin yang sama. Blok hidden-files (`location ~ /\.(?!well-known).*`) menolak akses ke path apa pun yang dimulai dengan titik (`.env`, `.git`, dll.) kecuali `/.well-known/`, yang digunakan Certbot untuk challenge pembaruan. Server block kedua (port 80) merespons setiap request HTTP biasa dengan sebuah redirect permanen `301` ke versi HTTPS.

### Step 3: Mengaktifkan Site

Mengaktifkan sebuah site di Nginx berarti melakukan symlink config-nya dari `sites-available/` ke `sites-enabled/`. Hapus site default untuk menghindari konflik pada port 80.

```bash
sudo ln -s /etc/nginx/sites-available/catatku /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

Symlink mengaktifkan server block baru. `rm -f /etc/nginx/sites-enabled/default` menghapus halaman welcome Nginx default sehingga ia tidak berebut port 80. `nginx -t` melakukan pemeriksaan sintaks; selalu jalankan sebelum reload atau restart, karena sebuah typo akan menolak menjalankan service untuk setiap site di server ini, bukan hanya Catatku. `systemctl restart nginx` (bukan `reload`) dibutuhkan di sini karena Nginx dihentikan di Step 1; dalam operasi normal, gunakan `systemctl reload nginx` untuk menerapkan perubahan config tanpa memutus koneksi yang ada.

### Step 4: Memverifikasi di Browser

Buka `https://` diikuti oleh domain Anda sendiri di sebuah browser. Halaman home Catatku seharusnya dimuat dengan ikon gembok yang menunjukkan sertifikat yang valid.

![preview app](https://cdn.jsdelivr.net/gh/qadrLabs/catatku-deploy-demo@main/docs/screenshot/01-preview-app.png)

Jika Anda melihat "502 Bad Gateway", periksa `sudo systemctl status php8.3-fpm` karena Nginx tidak dapat menjangkau socket PHP-FPM. Jika Anda melihat "404 Not Found" pada setiap route kecuali `/`, directive `root` di config Nginx menunjuk ke direktori yang salah. Jika Anda melihat sebuah error Let's Encrypt atau browser memperingatkan tentang sertifikat yang tidak valid, periksa ulang bahwa `dig +short catatku.example.com` mengembalikan IP yang benar dan jalankan ulang Certbot.

---

## 6. Menjalankan Queue Worker sebagai Service

Di Lesson 13 Anda menjalankan `php artisan queue:work` di sebuah terminal development dan menghentikannya saat Anda menutup laptop. Pendekatan itu tidak bertahan dari pemutusan SSH, reboot server, atau crash worker. Di production Anda membutuhkan sebuah process manager yang menjalankan worker saat boot, me-restart-nya saat crash, dan menjaganya tetap berjalan 24/7. Supervisor adalah pilihan Linux standar dan diinstal kembali di Section 2 Step 1.

### Step 1: Membuat Konfigurasi Supervisor

Setiap proses yang dikelola Supervisor dideskripsikan oleh sebuah file `.conf` di `/etc/supervisor/conf.d/`. Buat satu untuk worker Catatku.

```bash
sudo nano /etc/supervisor/conf.d/catatku-worker.conf
```

Tempel berikut.

```ini
[program:catatku-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/catatku/artisan queue:work database --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/catatku/storage/logs/worker.log
stopwaitsecs=3600
```

Setiap directive memiliki tempatnya. `[program:catatku-worker]` menamai program; Anda akan menggunakan nama ini dengan `supervisorctl` untuk start, stop, atau memeriksa status. Template `process_name` memformat nama instance seperti `catatku-worker_00` dan `catatku-worker_01` ketika beberapa worker paralel berjalan. `command` adalah perintah shell sebenarnya yang dieksekusi Supervisor: `queue:work database` cocok dengan `QUEUE_CONNECTION=database` dari `.env` Anda dan memberi tahu worker untuk membaca job dari tabel `jobs` di MariaDB. `--sleep=3` menunggu tiga detik antar polling ketika tidak ada job yang tertunda, yang menjaga penggunaan CPU idle mendekati nol. `--tries=3` mengizinkan setiap job hingga tiga percobaan sebelum dipindahkan ke `failed_jobs`. `--max-time=3600` mendaur ulang worker setelah satu jam untuk melepaskan memori apa pun yang diakumulasinya. `autostart=true` menjalankan worker ketika Supervisor itu sendiri start (yang terjadi saat boot). `autorestart=true` membawa worker kembali secara otomatis jika ia keluar secara tak terduga. `user=www-data` menjalankan worker sebagai user yang sama dengan PHP-FPM; ini disengaja. Worker mengeksekusi kode aplikasi Anda untuk memproses job, sehingga menjalankannya sebagai `www-data` (bukan deploy user Anda) berarti sebuah job yang dikompromikan tidak dapat memodifikasi source di disk, persis batas keamanan yang Anda siapkan di Section 3. Worker masih dapat membaca kode melalui keanggotaan group-nya dan menulis `worker.log` ke `storage/logs/` melalui ACL yang Anda terapkan sebelumnya. `numprocs=2` menjalankan dua instance worker paralel; naikkan angka ini jika Anda mengamati backlog queue dan server Anda memiliki CPU cadangan. `redirect_stderr=true` menggabungkan stderr ke stdout sehingga satu file log menangkap semuanya. `stdout_logfile` mengarahkan output gabungan itu ke `storage/logs/worker.log`. `stopwaitsecs=3600` memberi worker hingga satu jam untuk menyelesaikan job-nya saat ini dengan mulus ketika Supervisor diminta untuk menghentikannya, yang mencegah kehilangan pekerjaan di tengah eksekusi.

### Step 2: Menjalankan Worker

Beri tahu Supervisor untuk memuat file baru dan menjalankan worker.

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start catatku-worker:*
sudo supervisorctl status
```

Output terlihat seperti ini:

```
gungun@qadrlabs:/var/www/catatku$ sudo supervisorctl reread
catatku-worker: available
gungun@qadrlabs:/var/www/catatku$ sudo supervisorctl update
catatku-worker: added process group
gungun@qadrlabs:/var/www/catatku$ sudo supervisorctl start catatku-worker:*
gungun@qadrlabs:/var/www/catatku$ sudo supervisorctl status
catatku-worker:catatku-worker_00   STARTING
catatku-worker:catatku-worker_01   STARTING
```

`reread` memindai ulang `/etc/supervisor/conf.d/` untuk konfigurasi baru atau yang berubah. `update` menerapkan perubahan dengan menghentikan atau menjalankan program apa pun yang terpengaruh oleh pemindaian ulang. `start catatku-worker:*` menjalankan setiap instance yang dicakup oleh program (wildcard `:*` berkembang menjadi `catatku-worker_00` dan `catatku-worker_01`). `status` mendaftar setiap proses yang dikelola Supervisor. Tepat setelah `start`, kedua entri mungkin sebentar menampilkan `STARTING` seperti pada contoh di atas; tunggu beberapa detik dan jalankan `sudo supervisorctl status` lagi, dan kedua entri worker harus menampilkan `RUNNING`. Mulai saat ini, worker memproses queued job (email, pemrosesan gambar, notifikasi, apa pun yang di-dispatch melalui `dispatch()` di aplikasi Anda) dan akan restart secara otomatis melintasi reboot dan crash.

---

## 7. Memperbarui Aplikasi dengan Git Pull

Setelah Catatku live, setiap perubahan kode yang didorong ke GitHub perlu di-deploy ke server. Section ini menggunakan alur kerja andal yang paling sederhana: masukkan aplikasi ke maintenance mode, tarik kode baru, instal ulang dependensi, build ulang aset, jalankan migration, segarkan cache, restart worker, dan bawa aplikasi kembali. Ini menghabiskan beberapa detik downtime per deploy, yang dapat diterima untuk site kecil-hingga-menengah seperti Catatku.

### Step 1: Masuk ke Maintenance Mode

Alihkan aplikasi ke maintenance mode sehingga pengunjung menerima halaman "Be right back" alih-alih kondisi yang setengah ter-deploy.

```bash
cd /var/www/catatku
php artisan down
```

`php artisan down` menulis sebuah file flag di `storage/framework/maintenance.php`. Selama file itu ada, setiap HTTP request mengembalikan `HTTP 503 Service Unavailable` dengan halaman maintenance default Laravel. Anda menjalankan ini (dan setiap perintah lain di section ini) sebagai deploy user Anda, tanpa `sudo`. File flag mendarat di `storage/framework/`, yang dijaga ACL dari Section 3 tetap dapat dibaca oleh PHP-FPM, sehingga halaman maintenance ditampilkan dengan benar.

![maintenance mode](https://cdn.jsdelivr.net/gh/qadrLabs/catatku-deploy-demo@main/docs/screenshot/02-maintenance-mode.png)

### Step 2: Menarik Kode Terbaru

Tarik commit terbaru dari `origin/main` sebagai deploy user Anda, akun yang sama yang memiliki kode.

```bash
git pull origin main
```

Karena deploy user Anda memiliki setiap file di bawah `/var/www/catatku`, sebuah `git pull` biasa langsung berfungsi dan setiap file yang dibuatnya tetap dimiliki oleh Anda dengan group diatur ke `www-data`. Jangan menambahkan prefix `sudo` pada ini: berjalan sebagai `root` akan membuat file yang dimiliki `root` yang tidak dapat dibaca PHP-FPM (error `500` yang membingungkan setelah deploy), dan berjalan sebagai `www-data` akan memberi user yang menghadap web akses tulis ke kode Anda, mengalahkan model keamanan. Selalu jalankan perintah yang memperbarui kode sebagai deploy user Anda sendiri.

### Step 3: Menginstal Dependensi yang Diperbarui

`composer.lock` dan `package-lock.json` mungkin telah berubah di commit baru. Instal ulang keduanya dan build ulang bundle frontend.

```bash
composer install --no-dev --optimize-autoloader
npm ci
npm run build
```

Ini persis tiga perintah yang sama yang Anda jalankan selama deploy pertama, dijalankan oleh deploy user yang sama, sehingga alur pembaruan dan alur awal tetap konsisten. Menjalankannya sebagai akun Anda sendiri (yang memiliki direktori home normal) juga berarti Composer dan npm menemukan cache mereka di `~/.composer` dan `~/.npm` tanpa juggling HOME apa pun. `composer install` bersifat inkremental: ia hanya mengunduh package yang berubah di `composer.lock`. `npm ci` menghapus `node_modules/` dan menginstal ulang pohon yang persis dari `package-lock.json`, yang lebih cepat dan lebih andal daripada `npm install` selama deploy. `npm run build` mengompilasi ulang aset Vite ke `public/build/` dengan content hash baru sehingga browser mengunduh file baru alih-alih melayani yang basi dari cache.

### Step 4: Menjalankan Migration Baru

Terapkan migration baru apa pun yang datang bersama pull. Perintah ini adalah no-op jika tidak ada yang baru untuk dijalankan, sehingga aman untuk disertakan di setiap deploy.

```bash
php artisan migrate --force
```

`migrate --force` hanya menjalankan migration yang belum dicatat di tabel `migrations`, lalu mencatatnya. Melewati langkah ini adalah penyebab paling umum dari error `500` tepat setelah deploy: kode baru mereferensikan sebuah kolom yang tidak dimiliki database, dan setiap request yang menyentuh kolom itu gagal.

### Step 5: Menyegarkan Cache

Config, route, dan view yang di-cache dari deploy sebelumnya masih mendeskripsikan kode lama. Bersihkan dan build ulang.

```bash
php artisan optimize:clear
php artisan optimize
```

`optimize:clear` menghapus setiap file yang dikompilasi di bawah `bootstrap/cache/`. `optimize` mengompilasinya ulang berdasarkan kode baru. Melakukan keduanya memastikan Laravel tidak dapat secara tidak sengaja melayani sebuah route yang di-cache yang basi atau sebuah Blade view yang mereferensikan method yang dihapus di deploy ini.

### Step 6: Me-restart Queue Worker

Proses worker PHP yang berjalan masih menyimpan kode lama di memori. Sinyalkan mereka untuk keluar sehingga Supervisor dapat menjalankan worker baru dengan kode baru.

```bash
php artisan queue:restart
```

`queue:restart` menulis sebuah timestamp ke cache. Setiap worker memeriksa timestamp ini di antara job; ketika ia melihat sebuah nilai yang lebih baru, worker menyelesaikan job-nya saat ini lalu keluar dengan mulus. Supervisor memperhatikan proses sudah tiada dan menjalankan yang baru (karena `autorestart=true`), dan proses baru itu memuat kode baru. Tanpa langkah ini, job akan terus berjalan terhadap kode lama sampai worker kebetulan mendaur ulang pada batas `--max-time` mereka.

### Step 7: Keluar dari Maintenance Mode

Keluarkan aplikasi dari maintenance mode sehingga trafik nyata kembali.

```bash
php artisan up
```

`php artisan up` menghapus file flag `storage/framework/maintenance.php`. HTTP request berikutnya diproses secara normal dan user Anda melihat site yang diperbarui. Downtime end-to-end untuk seluruh urutan biasanya di bawah satu menit.

![preview app](https://cdn.jsdelivr.net/gh/qadrLabs/catatku-deploy-demo@main/docs/screenshot/01-preview-app.png)

### Step 8: Menyimpan sebagai Deploy Script

Menjalankan tujuh perintah dengan tangan setiap kali itu melelahkan dan rawan kesalahan. Simpan mereka sebagai sebuah skrip shell sehingga Anda dapat men-deploy dengan satu perintah.

```bash
nano /var/www/catatku/deploy.sh
```

Tidak ada `sudo` di sini juga: deploy user Anda memiliki direktori, sehingga skrip dibuat dimiliki oleh Anda dan tetap dapat dijalankan tanpa elevasi. Tempel berikut.

```bash
#!/bin/bash
set -e
cd /var/www/catatku
php artisan down
git pull origin main
composer install --no-dev --optimize-autoloader
npm ci
npm run build
php artisan migrate --force
php artisan optimize:clear
php artisan optimize
php artisan queue:restart
php artisan up
echo "Deploy finished."
```

Buat ia dapat dieksekusi. Anda memiliki file, sehingga tidak perlu `sudo`.

```bash
chmod +x /var/www/catatku/deploy.sh
```

`set -e` membuat skrip dibatalkan segera pada perintah pertama yang gagal, sehingga sebuah migration yang rusak tidak diam-diam meninggalkan aplikasi setengah ter-deploy. Jalankan ia sebagai deploy user Anda dengan `/var/www/catatku/deploy.sh` (bukan `sudo`) mulai sekarang, dan ia melakukan seluruh pembaruan secara berurutan. Jika ada langkah yang gagal, aplikasi tetap di maintenance mode sampai Anda memperbaiki masalah dan menyelesaikan skrip secara manual dengan `php artisan up`.

Sebuah run yang berhasil mencetak setiap langkah saat terjadi dan berakhir dengan `Deploy finished.`:

```
gungun@qadrlabs:/var/www/catatku$ ./deploy.sh

   INFO  Application is now in maintenance mode.

From https://github.com/qadrLabs/catatku-deploy-demo
 * branch            main       -> FETCH_HEAD
Already up to date.
Installing dependencies from lock file
Verifying lock file contents can be installed on current platform.
Nothing to install, update or remove
Generating optimized autoload files
> Illuminate\Foundation\ComposerScripts::postAutoloadDump
> @php artisan package:discover --ansi

   INFO  Discovering packages.

  laravel/sanctum ....................................................... DONE
  laravel/tinker ........................................................ DONE
  nesbot/carbon ......................................................... DONE
  nunomaduro/termwind ................................................... DONE

added 63 packages, and audited 64 packages in 4s

> build
> vite build

vite v8.0.16 building client environment for production...
✓ 3 modules transformed.
computing gzip size...
public/build/manifest.json                  2.51 kB │ gzip:  0.43 kB
public/build/assets/app-BK4ejP5Q.css        45.51 kB │ gzip: 10.49 kB
public/build/assets/app-BvRk9kiK.js          0.00 kB │ gzip:  0.02 kB

✓ built in 550ms

   INFO  Nothing to migrate.


   INFO  Clearing cached bootstrap files.

  config ......................................................... 1.99ms DONE
  cache ......................................................... 30.13ms DONE
  compiled ....................................................... 1.28ms DONE
  events ......................................................... 0.84ms DONE
  routes ......................................................... 0.89ms DONE
  views ......................................................... 77.70ms DONE


   INFO  Caching framework bootstrap, configuration, and metadata.

  config ........................................................ 16.78ms DONE
  events ......................................................... 1.86ms DONE
  routes ........................................................ 22.02ms DONE
  views ......................................................... 49.00ms DONE


   INFO  Broadcasting queue restart signal.


   INFO  Application is now live.

Deploy finished.
```

Pada deploy pertama Anda akan melihat output nyata untuk `git pull`, instalasi dependensi, dan migration alih-alih "Already up to date" dan "Nothing to migrate"; pada deploy selanjutnya tanpa perubahan baru output tetap sependek ini. Baris `From https://github.com/qadrLabs/catatku-deploy-demo` mencerminkan repository mana pun yang Anda clone di Section 3, sehingga ia akan menampilkan URL repository Anda sendiri jika Anda menggunakan yang pribadi.

---

## 8. Memperbaiki Error pada Kode Anda

Ini adalah tiga error yang menggigit hampir setiap deployer pertama kali.

**Error 1: Membiarkan `APP_DEBUG=true` di environment production.**

Ini adalah sebuah kerentanan keamanan. Dengan debug mode aktif, setiap halaman exception mengekspos nilai `.env`, path file, dan stack trace penuh ke siapa pun yang memicu error, termasuk penyerang yang menyelidiki site.

```env
// Wrong:
APP_DEBUG=true

// Correct:
APP_DEBUG=false
```

Dengan `APP_DEBUG=true`, browser menampilkan kredensial database dan API key setiap kali sesuatu melemparkan sebuah exception. Dengan `APP_DEBUG=false`, browser menampilkan halaman "Server Error" generik dan detail sebenarnya pergi ke `storage/logs/laravel.log` di mana hanya Anda yang dapat membacanya. Setelah mengubah nilai, jalankan `php artisan optimize:clear && php artisan optimize` (sebagai deploy user Anda) sehingga config yang di-cache mengambil nilai baru.

---

**Error 2: Lupa menjalankan migration setelah menarik kode baru.**

Kode baru sering mereferensikan kolom atau tabel baru. Jika migration belum dijalankan, setiap request yang menyentuh model yang terpengaruh mengembalikan `500` dan user melihat halaman error generik.

```bash
// Wrong:
git pull origin main
php artisan up

// Correct:
git pull origin main
php artisan migrate --force
php artisan up
```

Pada versi yang salah, kode sekarang mengharapkan sebuah kolom `cover_image` yang belum ada di production, dan query SQL gagal pada request pertama. Versi yang benar selalu menjalankan `migrate --force` setelah `git pull`, sehingga skema mengejar sebelum user melihat kode baru. Jika sebuah migration pernah merusak production, `php artisan migrate:rollback` mengembalikan batch terakhir sementara Anda menyelidiki.

---

**Error 3: Menjalankan perintah deploy sebagai user yang salah.**

Perintah yang memperbarui kode harus berjalan sebagai deploy user Anda, akun yang memiliki `/var/www/catatku`. Berjalan sebagai `root` (`sudo` biasa) membuat file yang dimiliki `root` yang tidak dapat dibaca PHP-FPM, yang muncul sebagai error `500` pada route yang menyentuh file baru. Berjalan sebagai `www-data` "berfungsi" tetapi memberi user yang menghadap web akses tulis ke source code Anda, mengalahkan model yang aman dari Section 3.

```bash
// Wrong (root-owned files):
sudo git pull origin main

// Also wrong (web user can now write your code):
sudo -u www-data git pull origin main

// Correct (your deploy user owns the code):
git pull origin main
```

Versi yang benar berjalan sebagai deploy user Anda sendiri, sehingga file tetap dimiliki oleh Anda dengan group diatur ke `www-data`, batas keamanan tetap terjaga, dan PHP-FPM masih membaca kode melalui keanggotaan group-nya. Jika Anda pernah secara tidak sengaja menjalankan sebuah perintah tulis sebagai `root`, pulihkan ownership dan ACL sebelum membawa site kembali:

```bash
sudo chown -R $USER:www-data /var/www/catatku
sudo chmod -R 775 /var/www/catatku/storage /var/www/catatku/bootstrap/cache
sudo setfacl -R  -m u:www-data:rwX,g:www-data:rwX /var/www/catatku/storage /var/www/catatku/bootstrap/cache
sudo setfacl -dR -m u:www-data:rwX,g:www-data:rwX /var/www/catatku/storage /var/www/catatku/bootstrap/cache
```

---

## 9. Latihan

Setiap latihan mengembangkan setup production dengan satu kepentingan realistis: backup, scheduling, dan monitoring uptime. Selesaikan Section 7 terlebih dahulu sehingga Anda memiliki deploy script yang berfungsi sebelum mencoba ini.

**Latihan 1:** Tulis sebuah skrip backup MariaDB harian yang menggunakan `mariadb-dump` untuk men-dump `catatku_production` ke `/var/backups/catatku/`, mengompresi file dengan `gzip`, dan hanya menyimpan backup 7 hari terakhir. Jadwalkan melalui cron untuk berjalan pada 02:00 setiap hari.

**Latihan 2:** Task scheduler Laravel berjalan dari `routes/console.php`, tetapi ia membutuhkan satu tick cron setiap menit untuk terpicu. Tambahkan entri yang diperlukan ke crontab `www-data` dan verifikasi dengan menjadwalkan sebuah pesan log satu kali yang berjalan setiap menit, lalu mengamati `storage/logs/laravel.log`.

**Latihan 3:** Verifikasi route health `/up` bawaan berfungsi di `https://catatku.example.com/up` (dengan domain Anda sendiri menggantikan placeholder), lalu daftar di UptimeRobot (gratis) dan konfigurasikan ia untuk mem-ping URL itu setiap 5 menit dan mengirim email kepada Anda ketika status keluar dari rentang 200.

---

## 10. Solusi

Bandingkan pekerjaan Anda dengan referensi di bawah. Setiap solusi menyoroti keputusan kunci alih-alih setiap detail.

**Solusi untuk Latihan 1:**

Buat `/usr/local/bin/catatku-backup.sh` dengan konten berikut.

```bash
#!/bin/bash
set -e

BACKUP_DIR=/var/backups/catatku
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_NAME=catatku_production
DB_USER=catatku_user
DB_PASSWORD=REPLACE_WITH_A_STRONG_PASSWORD

mkdir -p "$BACKUP_DIR"

mariadb-dump --single-transaction --quick \
    -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" \
    | gzip > "$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql.gz"

find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime +7 -delete
```

Buat ia dapat dieksekusi dan jadwalkan.

```bash
sudo chmod +x /usr/local/bin/catatku-backup.sh
sudo crontab -e
```

Tambahkan baris crontab berikut.

```
0 2 * * * /usr/local/bin/catatku-backup.sh >> /var/log/catatku-backup.log 2>&1
```

`mariadb-dump --single-transaction --quick` menghasilkan sebuah dump yang konsisten tanpa mengunci seluruh database, yang menjaga site tetap responsif selama backup. `gzip` mengompresi dump (biasanya 5-10x lebih kecil untuk SQL yang berat teks). `find ... -mtime +7 -delete` menghapus backup apa pun yang lebih lama dari 7 hari, sehingga disk tidak terisi penuh seiring waktu. Entri cron menjalankan skrip pada 02:00 harian dan menambahkan baik stdout maupun stderr ke `/var/log/catatku-backup.log` sehingga Anda memiliki jejak audit. Jalankan skrip sekali secara manual dengan `sudo /usr/local/bin/catatku-backup.sh` untuk mengonfirmasi backup pertama berhasil sebelum mengandalkan jadwal.

---

**Solusi untuk Latihan 2:**

Buka crontab dari `www-data`.

```bash
sudo crontab -u www-data -e
```

Tambahkan baris berikut.

```
* * * * * cd /var/www/catatku && php artisan schedule:run >> /dev/null 2>&1
```

Satu entri cron ini terpicu sekali per menit. Setiap pemanggilan memanggil `php artisan schedule:run`, yang memeriksa `routes/console.php` untuk task apa pun yang jadwalnya cocok dengan menit saat ini dan men-dispatch task yang cocok. `>> /dev/null 2>&1` membuang output karena `schedule:run` senyap saat sukses; jika Anda ingin menangkap kegagalan, arahkan ke sebuah file log nyata sebagai gantinya. Untuk memverifikasi scheduler bekerja, untuk sementara tambahkan berikut ke `routes/console.php`.

```php
use Illuminate\Support\Facades\Schedule;
use Illuminate\Support\Facades\Log;

Schedule::call(fn () => Log::info('Scheduler tick'))->everyMinute();
```

Tunggu satu menit, lalu periksa `storage/logs/laravel.log` untuk entri `Scheduler tick`. Hapus jadwal test setelahnya.

---

**Solusi untuk Latihan 3:**

Laravel 13 mendaftarkan route `/up` secara otomatis. Anda dapat memeriksa atau mengubah URI-nya di `bootstrap/app.php`.

```php
->withRouting(
    web: __DIR__.'/../routes/web.php',
    commands: __DIR__.'/../routes/console.php',
    health: '/up',
)
```

Kunjungi `https://catatku.example.com/up` (dengan domain Anda sendiri) di sebuah browser. Sebuah respons `200 OK` mengonfirmasi aplikasi boot tanpa exception; sebuah respons `500` berarti sesuatu rusak dalam proses boot dan body respons akan mendaftar kegagalannya.

Untuk memonitornya secara eksternal, daftar di uptimerobot.com (tier gratis mengizinkan 50 monitor pada interval 5 menit), klik "Add New Monitor", pilih "HTTP(s)" sebagai tipe, masukkan URL `/up` Anda sendiri, atur interval monitoring ke 5 menit, dan tambahkan email Anda sebagai alert contact. UptimeRobot sekarang mem-ping route health setiap lima menit dari beberapa lokasi geografis. Jika dua pemeriksaan berturut-turut mengembalikan status non-200, Anda menerima sebuah email dalam hitungan detik. Ini adalah monitoring "apakah site saya hidup?" yang paling murah dan ia seharusnya menjadi observability pertama yang Anda tambahkan ke deployment production mana pun.

---

## Selanjutnya - Lesson 18

Di lesson ini Anda membawa Catatku dari sebuah VPS Ubuntu yang bersih ke sebuah aplikasi HTTPS yang live di domain Anda sendiri. Anda menginstal Nginx, PHP 8.3, MariaDB, Supervisor, dan Certbot; mengarahkan domain ke server; meng-clone `https://github.com/qadrLabs/catatku-deploy-demo` (atau repository Anda sendiri) ke `/var/www/catatku`; membuat sebuah `.env` production dengan `APP_DEBUG=false` dan driver `database` untuk cache, queue, dan session; menyiapkan sebuah model ownership yang aman di mana deploy user Anda memiliki kode dan `www-data` hanya membacanya, dengan ACL yang memberikan akses tulis ke `storage/` dan `bootstrap/cache/`; memperoleh sertifikat SSL gratis dari Let's Encrypt; menulis sebuah Nginx server block dengan redirect HTTP-ke-HTTPS; menjalankan dua queue worker yang dikelola Supervisor; dan menyimpan sebuah skrip `deploy.sh` yang memperbarui site dengan satu perintah menggunakan `git pull`.

Di Lesson 18, Anda akan melangkah mundur dan meninjau jalur penuh yang telah Anda lalui di course ini: ringkasan dari semua 17 fitur yang Anda tambahkan di atas aplikasi Catatku dasar, perbandingan keterampilan Laravel pemula versus menengah, dan peta jalan topik lanjutan termasuk Livewire, Inertia.js, Scout, Horizon, dan Cashier yang dapat Anda eksplorasi selanjutnya.
