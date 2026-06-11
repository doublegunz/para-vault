Anda baru saja memutuskan untuk belajar Laravel, framework PHP paling populer di dunia. Anda bersemangat, termotivasi, dan siap untuk membangun sesuatu yang nyata. Namun kemudian Anda membuka laptop dan menyadari... Anda bahkan tidak tahu harus mulai dari mana. Apa yang harus diinstal terlebih dahulu? Bagaimana cara membuat PHP, Composer, dan Laravel bekerja sama? Kebingungan ini adalah hal yang menghentikan sebagian besar pemula bahkan sebelum mereka menulis baris kode pertama mereka. Pada lesson ini, kita akan menghilangkan hambatan tersebut sepenuhnya. Di akhir lesson, Anda akan memiliki proyek Laravel 13 yang berjalan sepenuhnya di komputer Anda, dan Anda akan memahami setiap bagian dari proses setup-nya.

## Ikhtisar {#overview}

Pada lesson ini, kita akan fokus pada tools dan proyek Laravel pertama. Tujuannya bukan untuk menghafal setiap opsi konfigurasi saat ini, tetapi untuk memastikan Anda dapat membuat, membuka, menjalankan, dan memeriksa sebuah aplikasi Laravel yang baru.

### What You'll Build

Anda akan mengatur lingkungan pengembangan lokal yang lengkap dan membuat proyek Laravel 13 baru bernama **Catatku** (dalam Bahasa Indonesia berarti "My Notes"), yang akan kita kembangkan sepanjang course ini. Di akhir lesson ini, Anda akan melihat halaman selamat datang Laravel berjalan di browser Anda.

### What You'll Learn

- Cara menginstal dan mengonfigurasi Visual Studio Code sebagai code editor Anda
- Cara menginstal Laragon sebagai lingkungan server lokal Anda
- Cara meng-upgrade PHP ke versi 8.3 (diperlukan untuk Laravel 13)
- Cara membuat proyek Laravel 13 baru menggunakan Composer
- Cara menavigasi struktur folder Laravel
- Cara menjalankan development server Laravel menggunakan Artisan

### What You'll Need

- Komputer yang menjalankan Windows (panduan ini menggunakan Windows sebagai OS utama)
- Koneksi internet untuk mengunduh tools dan package
- Sekitar 30 hingga 45 menit waktu Anda



## Step 1: Instal Visual Studio Code {#step-1-install-visual-studio-code}

### Unduh Visual Studio Code {#download-visual-studio-code}

Visual Studio Code (VS Code) adalah code editor gratis dan ringan yang dibuat oleh Microsoft. Editor ini telah menjadi pilihan utama bagi web developer berkat ekosistem ekstensinya yang sangat baik, terminal bawaan, dan dukungan kelas satu untuk PHP dan JavaScript.

Kunjungi [situs resmi Visual Studio Code](https://code.visualstudio.com/) dan klik tombol **Download** untuk Windows.

![download visual studio code](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/01-download.png)

Tunggu hingga proses download selesai sebelum melanjutkan.

### Proses Instalasi {#installation-process}

Setelah file installer `VSCodeUserSetup-x64-1.82.2` selesai diunduh, klik dua kali file tersebut untuk memulai instalasi.

1. Pada halaman pertama, Anda akan diminta untuk menyetujui **License Agreement**. Pilih **I accept the agreement** dan klik **Next**.

    ![start install](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/03-%20setup.png)

2. Pilih direktori tempat Anda ingin menginstal VS Code. Lokasi default adalah `C:\Program Files\Microsoft VS Code`. Anda dapat mempertahankan default tersebut atau menyesuaikannya sesuai preferensi Anda. Klik **Next**.

    ![setup directory vscode](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/04-setup%20direktori.png)

3. Pada halaman **Select Additional Tasks**, centang opsi **Create a desktop icon** jika Anda menginginkan shortcut di desktop Anda. Kemudian klik **Next**.

    ![select additional task](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/06%20-%20select%20additional%20task.png)

4. Pada halaman **Ready to Install**, klik **Install** dan tunggu hingga proses selesai.

    ![ready to install](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/07%20-%20ready%20to%20install.png)

Setelah instalasi selesai, klik **Finish** untuk menutup installer.

![finish install visual studio code](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/09%20-%20finish.png)

### Menjalankan Visual Studio Code {#running-visual-studio-code}

Setelah instalasi, Anda dapat membuka VS Code dari ikon desktop atau melalui menu Start Windows. Luangkan waktu sejenak untuk membiasakan diri dengan antarmukanya. Kita akan menghabiskan banyak waktu di sini sepanjang course ini.



## Step 2: Instal Laragon {#step-2-install-laragon}

### Unduh Laragon {#download-laragon}

Laragon adalah lingkungan pengembangan lokal all-in-one untuk Windows. Ia menggabungkan Apache/Nginx, MySQL, PHP, Node.js, dan Composer ke dalam satu paket yang ringan. Berbeda dengan alternatif yang lebih berat seperti XAMPP atau WAMP, Laragon cepat untuk dijalankan, mudah dikonfigurasi, dan dirancang dengan mempertimbangkan pengembangan PHP modern.

Anda dapat mengunduh Laragon dari [situs resmi Laragon](https://laragon.org/index.html). Klik menu **Download** dan pilih versi **Laragon - Full**.

![download laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/01-download.png)

**Important Note:**
- Sejak Laragon versi 7 dirilis, halaman download sekarang menyajikan Laragon versi 7. Berdasarkan [diskusi di repository Laragon](https://github.com/leokhoa/laragon/discussions/960), Laragon versi 7 **tidak lagi gratis** dan menggunakan model **Paid Licensing**.
- Jika Anda ingin menggunakan **versi gratis Laragon**, Anda dapat mengunduhnya langsung dari GitHub: [https://github.com/leokhoa/laragon/releases/download/6.0.0/laragon-wamp.exe](https://github.com/leokhoa/laragon/releases/download/6.0.0/laragon-wamp.exe)

### Proses Instalasi Laragon {#laragon-installation-process}

Setelah file `laragon-wamp.exe` selesai diunduh, klik dua kali file tersebut untuk memulai instalasi. Ikuti langkah-langkah berikut:

1. Pilih bahasa instalasi (misalnya, **English**), lalu klik **Next**.

    ![select language](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/02-pilih-bahasa.png)

2. Pilih direktori instalasi untuk Laragon. Defaultnya adalah `C:\Laragon`. Klik **Next** untuk melanjutkan.

    ![select install location](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/03-pilih-lokasi-install.png)

3. Anda akan melihat opsi konfigurasi seperti autostart saat Windows dimulai dan menambahkan Notepad++ serta terminal ke Laragon. Pilih opsi yang sesuai dengan preferensi Anda, lalu klik **Next**.

    ![configure laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/04-atur-konfigurasi-laragon.png)

4. Pada halaman **Ready to Install**, klik **Install** untuk memulai proses instalasi Laragon.

    ![ready install](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/05-ready-install.png)

5. Tunggu hingga instalasi selesai. Setelah itu, klik **Finish** untuk menutup installer dan membuka Laragon.

    ![finish install laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/07-selesai-install.png)

### Menjalankan Laragon {#running-laragon}

Setelah Laragon terbuka, Anda akan melihat antarmukanya yang intuitif dan ramah pengguna.

![laragon main screen](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/08-tampilan-laragon.png)

Untuk memulai layanan seperti Apache dan MySQL, cukup klik **Start All**. Laragon akan menjalankan semua layanan yang dibutuhkan untuk pengembangan aplikasi web, termasuk Apache, MySQL, dan PHP.

### Membuka Folder Proyek di Visual Studio Code {#opening-a-project-folder-in-visual-studio-code}

Sekarang setelah VS Code dan Laragon terinstal, langkah selanjutnya adalah menghubungkan keduanya sehingga Anda dapat bekerja dengan lancar dalam satu lingkungan pengembangan. Berikut cara sederhana untuk membuka direktori proyek di Visual Studio Code:

1. Buka Laragon dan klik **Root**. Ini akan membuka direktori `root` tempat proyek-proyek Anda berada, yaitu `C:\laragon\www`. Untuk saat ini, buat direktori baru bernama `sample-app` di dalamnya. Pada proyek nyata nanti, kita akan menggunakan perintah Composer untuk men-scaffold proyek Laravel, CodeIgniter, atau framework PHP lainnya secara langsung.
2. Buka Visual Studio Code, klik **File > Open Folder**, dan pilih folder yang baru saja Anda buat di direktori root Laragon: `C:\laragon\www\sample-app`.



## Step 3: Konfigurasi Awal {#step-3-initial-configuration}

Sebelum kita dapat menggunakan perintah seperti `php`, `node`, dan `composer` dari terminal manapun, kita perlu menambahkan Laragon ke environment PATH sistem. Langkah ini memastikan Windows mengetahui di mana harus mencari tools tersebut, terlepas dari terminal mana yang Anda buka.

Pertama, buka Laragon, lalu klik kanan atau klik tombol **Menu** untuk membuka menu Laragon.

![open laragon menu](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/09%20menu%20laragon.png)

Selanjutnya, tambahkan Laragon ke PATH sistem dengan mengklik **Tools** > **Path** > **Add Laragon to Path**.

![add laragon to path](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/10%20set%20environment%20variable.png)

Sekarang mari kita verifikasi bahwa Laragon telah berhasil ditambahkan ke PATH. Buka terminal dengan mengklik tombol **Terminal** pada antarmuka Laragon.

![open terminal](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/11%20akses%20terminal%20via%20laragon.png)

Setelah terminal terbuka, jalankan perintah berikut untuk memeriksa versi PHP yang terinstal:

```bash
php -v
```

Anda akan melihat output yang menunjukkan versi PHP yang terinstal di Laragon:

![check php version](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/12%20check%20php.png)

Seperti yang ditunjukkan pada gambar di atas, versi PHP yang terinstal adalah PHP 8.1.

Selanjutnya, periksa versi Node.js dengan menjalankan:

```bash
node -v
```

![check nodejs version](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/13%20check%20node%20js.png)

Output menunjukkan bahwa versi Node.js yang terinstal di Laragon adalah 18.8.0.

Terakhir, verifikasi bahwa Composer berfungsi dengan menjalankan:

```bash
composer
```

![test composer command](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/14%20check%20composer.png)

Anda akan melihat output bantuan Composer, yang mengonfirmasi bahwa Composer siap digunakan.



## Step 4: Upgrade PHP ke 8.3 {#step-4-upgrade-php-to-83}

Laravel 13 membutuhkan PHP 8.3 atau lebih tinggi. Instalasi default Laragon hadir dengan PHP 8.1, jadi kita perlu meng-upgrade-nya. Proses ini melibatkan pengunduhan build PHP yang lebih baru dan memberi tahu Laragon untuk menggunakannya.

### Unduh PHP 8.3 {#download-php-83}

1. Kunjungi halaman download resmi PHP untuk Windows: [https://www.php.net/downloads.php?os=windows&version=8.3](https://www.php.net/downloads.php?os=windows&version=8.3).
2. Unduh build ZIP **PHP 8.3 x64 Non Thread Safe (NTS)** terbaru.

   ![download php 8.3](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/1%20download%20php%208.2.png)

Versi patch yang tepat mungkin berbeda saat Anda membaca lesson ini. Itu tidak masalah. Selama file tersebut diawali dengan `php-8.3` dan menggunakan build x64 NTS, file tersebut cocok untuk course ini.

Kita mengunduh versi NTS (Non Thread Safe) karena Laragon menggunakannya secara default. Build NTS dioptimalkan untuk lingkungan single-threaded seperti Nginx dengan PHP-FPM, yang merupakan setup yang akan kita konfigurasi selanjutnya.

### Ekstrak File PHP ke Laragon {#extract-the-php-files-to-laragon}

Setelah download selesai, ikuti langkah-langkah berikut:

1. Pindahkan file `php-8.3.x-nts-Win32-vs16-x64.zip` yang sudah diunduh ke `C:\laragon\bin\php`.

   ![move zip file to laragon php directory](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/2%20pindahkan%20ke%20direktori%20php%20di%20laragon.png)

2. Klik kanan file ZIP tersebut dan pilih **Extract All**. Klik tombol **Extract** untuk memulai proses ekstraksi. Setelah selesai, Anda akan melihat folder baru dengan nama yang mirip dengan `php-8.3.x-nts-Win32-vs16-x64`.

   ![extract all](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/3%20Extract%20all.png)

   ![extracted folder](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/4%20folder%20hasil%20extract.png)

### Pilih PHP 8.3 di Laragon {#select-php-83-in-laragon}

1. Buka Laragon.
2. Buka **Menu** > **PHP** > **Version** > folder PHP 8.3 hasil ekstraksi Anda, seperti `php-8.3.x-nts-Win32-vs16-x64`, untuk mengaktifkan PHP 8.3 sebagai versi PHP utama.

   ![switch php version](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/5%20switch%20php%20version.png)

Ini memberi tahu Laragon untuk menggunakan build PHP 8.3 yang baru, baik untuk web server maupun CLI. Tidak diperlukan restart; Laragon akan menerapkan perubahan tersebut secara langsung.

### Konfigurasi Nginx sebagai Web Server {#configure-nginx-as-the-web-server}

Untuk performa yang lebih baik dan kompatibilitas dengan aplikasi PHP modern, kita akan beralih dari Apache ke Nginx:

1. Di Laragon, buka menu **Preferences**.

   ![click preferences menu](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/6%20klik%20menu%20preferences.png)

2. Buka tab **Services & Ports**. Hilangkan centang pada **Apache** dan aktifkan **Nginx** dengan mencentang checkbox-nya. Atur port Nginx ke **80**.

   ![enable nginx](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/7%20enable%20nginx.png)

3. Kembali ke antarmuka utama Laragon dan klik **Start All** untuk menjalankan Nginx dan layanan lainnya.

   ![start all services](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/8%20start%20all%20services.png)



## Step 5: Verifikasi Instalasi PHP 8.3 {#step-5-verify-the-php-83-installation}

Setelah semuanya dikonfigurasi, kita perlu memastikan bahwa PHP 8.3 sudah diatur dengan benar dan dikenali baik oleh web server maupun command line.

### Verifikasi PHP di Browser {#verify-php-in-the-browser}

1. Di Laragon, klik tombol **Web** untuk membuka `localhost` di browser Anda.

   ![open localhost in browser](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/9%20buka%20localhost%20di%20browser.png)

2. Halaman localhost seharusnya menampilkan versi PHP 8.3, seperti `PHP version: 8.3.x`, yang mengonfirmasi bahwa web server menggunakan versi PHP yang benar.

   ![localhost page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/10%20halaman%20localhost.png)

3. Klik link **info** pada halaman localhost untuk melihat konfigurasi PHP lengkap melalui `phpinfo()`.

   ![phpinfo page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/12%20halaman%20info%20menampilkan%20php%20versi%208.3.png)

### Verifikasi PHP di CLI {#verify-php-in-the-cli}

1. Kembali ke Laragon dan klik **Terminal** untuk membuka Cmder atau terminal bawaan.

   ![click terminal in laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/13%20klik%20menu%20terminal%20di%20ui%20laragon.png)

2. Jalankan perintah berikut untuk memeriksa versi PHP di CLI:

   ```bash
   php -v
   ```

   Output seharusnya menunjukkan versi PHP yang sudah diperbarui. Tampilannya akan mirip seperti ini:

   ```bash
   PHP 8.3.x (cli) (built: ...) (NTS Visual C++ 2019 x64)
   ```

   ![check php version in cmder](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/14%20cek%20versi%20php%20di%20cmder%20-%202.png)

Baik browser maupun CLI sekarang mengonfirmasi bahwa PHP 8.3 telah aktif. Kita siap untuk membuat proyek Laravel kita.



## Step 6: Membuat Proyek Catatku {#step-6-create-the-catatku-project}

Dengan lingkungan pengembangan yang sudah dikonfigurasi sepenuhnya, kita sekarang dapat membuat proyek Laravel kita. Buka terminal Laragon dan jalankan perintah berikut:

```bash
composer create-project --prefer-dist laravel/laravel catatku
```

Perintah ini memberi tahu Composer untuk mengunduh versi Laravel terbaru dan mengatur seluruh struktur proyek di dalam folder bernama `catatku`. Proses ini membutuhkan koneksi internet dan mungkin memerlukan waktu beberapa menit tergantung pada kecepatan koneksi Anda.

Pada proyek Laravel 13 saat ini, perintah ini juga dapat membuat file database SQLite lokal dan menjalankan migration default Laravel secara otomatis. Itu adalah hal yang wajar. Pada course ini, kita tetap akan menggunakan MySQL untuk Catatku agar Anda dapat berlatih bekerja dengan database server. Kita akan beralih dari setup SQLite default Laravel ke MySQL pada lesson berikutnya.

Setelah instalasi selesai, navigasikan ke direktori proyek dan buka di VS Code:

```bash
cd catatku
code .
```

Perintah `cd catatku` memindahkan Anda ke folder proyek yang baru dibuat. Perintah `code .` membuka direktori saat ini di Visual Studio Code, sehingga Anda dapat langsung mulai menjelajahi file proyek.



## Step 7: Menjalankan Development Server {#step-7-run-the-development-server}

Laravel hadir dengan development server bawaan yang didukung oleh Artisan. Dari dalam folder `catatku`, jalankan:

```bash
php artisan serve
```

Anda akan melihat output yang mirip dengan ini:

```
INFO  Server running on [http://127.0.0.1:8000].

Press Ctrl+C to stop the server
```

Buka browser Anda dan kunjungi `http://127.0.0.1:8000`. Anda akan melihat halaman selamat datang Laravel, yang mengonfirmasi bahwa proyek Anda telah berhasil dibuat dan berjalan dengan benar.

![Laravel 13 Welcome page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/courses/learn-laravel/01-laravel-welcome-page.webp)

> **Tip**: Biarkan terminal ini tetap berjalan selama pengembangan. Buka tab atau jendela terminal baru setiap kali Anda perlu menjalankan perintah Artisan lainnya.



## Memahami Struktur Folder Laravel {#understanding-the-laravel-folder-structure}

Saat proyek terbuka di VS Code, Anda akan melihat banyak folder dan file. Jangan khawatir untuk memahami semuanya saat ini. Yang penting adalah mengenali folder-folder yang akan paling sering kita gunakan sepanjang course ini:

```
catatku/
├── app/
│   ├── Http/
│   │   └── Controllers/    ← Where controllers live
│   └── Models/             ← Where Eloquent models live
├── database/
│   ├── database.sqlite     ← Local SQLite database created by Laravel by default
│   └── migrations/         ← Database table definitions
├── resources/
│   └── views/              ← Blade template files (HTML)
├── routes/
│   └── web.php             ← All application routes
├── .env                    ← Environment configuration (database, etc.)
└── artisan                 ← Laravel's CLI tool
```

**`app/Http/Controllers/`** adalah tempat logika aplikasi Anda berada. Controller menerima request dari pengguna, memproses data, dan menentukan response apa yang akan dikirim kembali.

**`app/Models/`** berisi representasi PHP dari tabel-tabel database Anda. Model `Entry` yang akan kita buat nanti berhubungan langsung dengan tabel `entries` di database. Pada Laravel 13, model menggunakan attribute `#[Fillable([...])]` alih-alih properti tradisional `protected $fillable`, yang merupakan pendekatan yang lebih bersih dan modern.

**`database/migrations/`** berisi file PHP yang mendefinisikan struktur tabel secara programatis. Ini berarti perubahan database dapat dilacak dan direplikasi secara konsisten di berbagai environment.

**`database/database.sqlite`** adalah file database SQLite lokal yang dibuat Laravel secara default. Kita akan mengingatnya, tetapi Catatku akan menggunakan MySQL nanti dalam course ini.

**`resources/views/`** adalah tempat semua file template Blade berada. Blade adalah template engine Laravel untuk menghasilkan HTML dinamis.

**`routes/web.php`** adalah "peta" aplikasi Anda. Setiap URL didefinisikan di sini dan dihubungkan ke controller yang sesuai.

**`.env`** menyimpan konfigurasi spesifik environment seperti kredensial database. File ini tidak boleh pernah di-commit ke Git karena berisi informasi sensitif.

Setelah Anda menghafal peta ini, Anda tidak akan pernah merasa tersesat saat menavigasi proyek Laravel manapun, karena konvensinya selalu konsisten.



## Berkenalan dengan Artisan {#getting-to-know-artisan}

Artisan adalah command-line interface bawaan Laravel. Kita akan sering menggunakannya sepanjang course ini. Anda tidak perlu menghafal perintah-perintah ini sekarang. Setiap perintah akan diperkenalkan kembali ketika kita benar-benar membutuhkannya. Namun berikut adalah gambaran singkat tentang perintah-perintah yang akan kita temui:

```bash
php artisan serve              # Start the development server
php artisan make:model         # Create a new model
php artisan make:controller    # Create a new controller
php artisan make:migration     # Create a new migration file
php artisan migrate            # Run all pending migrations
php artisan route:list         # Display all registered routes
php artisan tinker             # Open Laravel's interactive REPL
```

Anggap Artisan sebagai asisten proyek Anda. Alih-alih membuat file secara manual dan menulis boilerplate code, Artisan membuatkannya untuk Anda dengan struktur dan konvensi penamaan yang sudah benar.



## Kesimpulan {#conclusion}

Pada lesson ini, Anda telah membangun lingkungan pengembangan lokal yang lengkap dari awal dan membuat proyek Laravel 13 pertama Anda. Berikut adalah poin-poin pentingnya:

- **Visual Studio Code** adalah code editor Anda. Editor ini menyediakan syntax highlighting, terminal terintegrasi, dan ekosistem ekstensi yang kaya untuk pengembangan PHP.
- **Laragon** menggabungkan semua yang Anda butuhkan untuk pengembangan PHP lokal: web server (Nginx), database (MySQL), PHP, Node.js, dan Composer.
- **PHP 8.3 atau lebih tinggi** diperlukan untuk Laravel 13. Anda dapat meng-upgrade PHP di Laragon dengan mengunduh build PHP baru, mengekstraknya ke `C:\laragon\bin\php`, dan memilihnya di menu Laragon.
- **Nginx** adalah web server yang direkomendasikan untuk aplikasi PHP modern, menawarkan performa yang lebih baik dibandingkan Apache untuk sebagian besar use case.
- Perintah `composer create-project` men-scaffold proyek Laravel lengkap dengan semua dependensi yang sudah diinstal dan dikonfigurasi.
- **Struktur folder Laravel** mengikuti konvensi yang konsisten: `Controllers/` untuk logika, `Models/` untuk data, `migrations/` untuk skema database, `views/` untuk template, dan `web.php` untuk route.
- **Artisan** adalah tool CLI Laravel yang menghasilkan file, menjalankan migration, memulai dev server, dan masih banyak lagi.
- File **`.env`** menyimpan konfigurasi environment Anda dan tidak boleh pernah dibagikan atau di-commit ke version control.

Pada lesson selanjutnya, kita akan mengganti setup SQLite default Laravel dengan MySQL, kemudian membuat migration spesifik aplikasi pertama untuk Catatku. Anda akan mempelajari bagaimana Laravel mengelola skema database melalui migration dan cara mendefinisikan model Eloquent pertama Anda.
