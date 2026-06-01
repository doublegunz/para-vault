---
title: "Cara installasi dan penggunaan Composer pada Ubuntu 16.04"
slug: "cara-installasi-dan-penggunaan-composer-pada-ubuntu-16-04"
category: "How To Install"
date: "2016-12-10"
status: "published"
---

Berawal dari diskusi santai di grup telegram yang menyebutkan tentang **`Composer`** sukses menarik rasa penasaran saya untuk mencari tahu tentang Composer ini. Dan setelah membaca beberapa artikel di beberapa blog dan website membuat saya ingin mencoba Composer ini. Tutorial instalasi Composer ini adalah hasil dari rasa penasaran saya dan merupakan dokumentasi setelah mencoba instalasi composer. Dan karena OS yang saya gunakan adalah Ubuntu 16.04, jadi tutorial kali ini akan membahas Cara instalasi Composer pada Ubuntu 16.04 dan juga cara penggunaannya.

Mungkin ada sebagian dari kita yang belum berkenalan dengan **Composer**, lalu bertanya apa itu **Composer**? **Composer** adalah dependensi manager khusus untuk bahasa pemrograman PHP yang berfungsi untuk memfasilitasi proses instalasi dan update dependensi projek. Composer ini akan mengecek package yang digunakan sebagai dependensi dan menginstallnya, menggunakan versi yang sesuai dengan requirement projek. Composer ini merupakan project open source yang dimotori oleh Nils Adermann dan Jordi Boggiano. Project Composer ini dihost di [Github](https://github.com/composer/composer) tercatat sejak tanggal 3 April 2011 dan masih aktif sampai sekarang.

## Prasyarat{#prasyarat}
Ada dua hal yang kamu perlukan untuk mengikuti tutorial instalasi Composer pada Ubuntu 16.04 ini:
1. Server atau komputer dengan OS Ubuntu 16.04
2. Akses ke server sebagai user biasa dengan sudo permission.

Lalu, apa saja langkah-langkah dalam Instalasi dan penggunaan Composer pada Ubuntu 16.04? *Try this out ya!*

## Step 1 - Install Dependensi{#step-1}
Sebelum mengunduh dan install Composer, kita perlu memastikan server kita sudah menginstall semua dependensi yang diperlukan.

Pertama, kita update package manager cache dengan menjalankan perintah ini di terminal:
```bash
 sudo apt-get update
```

Sekarang, kita install dependensi. Kita akan membutuhkan curl untuk mengunduh Composer dan php7.0-cli untuk installasi dan menjalankan perintah tersebut. git juga digunakan oleh Composer untuk mengunduh dependensi projek. Nah, sekarang kita coba install dengan menjalankan perintah:
```bash 
sudo apt-get install curl php7.0-cli
```

Sudah?

Sekarang kita lanjut ke langkah berikutnya. ^^

## Step 2 - Download dan Installasi Composer{#step-2}
Installasi Composer itu sangat mudah lho! Kita hanya perlu mengeksekusi perintah di bawah ini:
```bash
 curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
```

Ya, setelah mengeksekusi perintah di atas, Composer sudah terunduh dan terinstall sebagai perintah sistem dengan nama 'composer', dalam direktori /usr/local/bin. Nah, setelah composer terinstall, terdapat notifikasi seperti ini:
```bash
All settings correct for using Composer
 Downloading 1.2.4...
 Composer successfully installed to: /usr/local/bin/composer
 Use it: php /usr/local/bin/composer
```

![install sukses](https://4.bp.blogspot.com/-GbcW8HLNOT4/WEtqlwzhhQI/AAAAAAAAAm0/eOMZ3bOgoCE52aiQ1dZjqFYQl9QpGzezgCLcB/s16000/Cara%2Binstalasi%2Bdan%2Bpenggunaan%2BComposer%2Bpada%2BUbuntu%2B16-04-gambar%2B1.png)

Sekarang kita coba tes, dengan mengeksekusi perintah ini di terminal:
 ```bash
 composer
```

Ya, kalau tampil seperti gambar di bawah ini, itu artinya Composer sudah berhasil kita install! Selamat! ^^
 
![tes composer](https://2.bp.blogspot.com/-OR-PruuadBs/WEtqmqsEx2I/AAAAAAAAAm4/qgh_U0W00UIKrzroWNQG4FYBqKUnj13XwCLcB/s16000/Cara%2Binstalasi%2Bdan%2Bpenggunaan%2BComposer%2Bpada%2BUbuntu%2B16-04-gambar%2B2.png)

Oh iya, kamu juga bisa install Composer di masing-masing projek secara terpisah juga lho! Metode ini berguna ketika pengguna sistem tidak punya ijin untuk menginstall software system-wide. Dalam kasus ini, proses installasi bisa dilakukan dengan mengeksekusi perintah:
```bash
 curl -sS https://getcomposer.org/installer | php
 ```
Dengan perintah tersebut, akan meng-generate sebuah file composer.phar di dalam direktori projekmu dan bisa dieksekusi menggunakan perintah:
```bash
php composer.phar [command]
```

## Step 3 - Uji Coba Penggunaan Composer{#step-3}
Untuk menggunakan Composer di dalam project kita, kita akan memerlukan sebuah file `composer.json`. Nah file `composer.json` ini secara sederhananya akan memberitahu Composer dependensi mana yang perlu diunduh untuk projek kita dan versi dari setiap package yang diijinkan untuk diinstall. Hal ini amat sangat penting untuk menjaga kekonsistenan projek kita dan untuk menghindari installasi versi yang tidak stabil (unstable verison) yang berpontensi menyebabkan isu backward compatibility.

Kita tidak perlu buat file ini secara manual. lho emang kenapa? Soalnya akan mudah muncul syntax error kalau kita buat secara manual. Terus gimana dong? Kabar baiknya, Composer bisa auto-generate file `composer.json` ketika kita menambahkan sebuah dependensi ke dalam projek kita menggunakan perintah `require`. Penambahan dependensi dapat juga dilakukan dengan cara yang sama, tanpa perlu mengeditnya secara manual. Wuiih, tampaknya gak terlalu ribet ya! ^^

Proses penggunaan Composer untuk menginstall sebuah package sebagai dependensi dalam sebuah projek biasanya melibatkan beberapa langkah berikut:
1. Identifikasi jenis library yang diperlukan dalam aplikasi.
2. Riset library open source yang cocok di Packagist.org, repository resmi untuk Composer.
3. Pilih package yang ingin dijadikan sebagai dependensi.
4. Jalankan 'composer require' untuk melampirkan dependensi dalam file composer.json dan instalasi package.

Sekarang kita coba dengan membuat aplikasi demo sederhana.

### 3.1 Uji coba install Package
Misal, kita ingin membuat aplikasi untuk mengubah kalimat menjadi sebuah URL-friendly (sebuah slug). Slug ini bisa digunakan untuk meng-convert judul halaman menjadi path URL.

Sekarang kita coba buat direktori untuk projek sederhana kita. Kita namakan 'slugify'.
```bash
cd ~ mkdir slugify cd slugify
```
![change direktori](https://2.bp.blogspot.com/-wgArnAEvSUw/WEtqlPbsQUI/AAAAAAAAAmw/W5L9Xc1zF_Y4cy2nWGmN1kaCO2PvH57fwCLcB/w640-h58/Cara%2Binstalasi%2Bdan%2Bpenggunaan%2BComposer%2Bpada%2BUbuntu%2B16-04-gambar%2B3.png)

Selanjutnya, kita coba cari package yang dapat memudahkan dalam generate sebuah slugs di Packagist.org. Kita coba cari dengan keyword 'slug' di Packagist, maka akan tampil hasil pencarian.

![cari package](https://2.bp.blogspot.com/-UwERbO2DlSU/WEtqn4MjDRI/AAAAAAAAAm8/de-aFYamB0Yj0l5LjlSRGjXCCdrDL6iRQCLcB/s16000/Cara%2Binstalasi%2Bdan%2Bpenggunaan%2BComposer%2Bpada%2BUbuntu%2B16-04-gambar%2B4.png)
 
Kita bisa lihat nomor di bagian kanan di setiap package dalam hasil pencarian di atas. Nomor ini menunjukkan seberapa banyak package tersebut diinstall dan nomor di bawahnya menunjukan seberapa banyak package tersebut starred di GitHub. Hasil pencarian tersebut bisa diatur kembali berdasarkan jumlah terbanyak atau bintang. Nah, biasanya package yang sering diinstal dan banyak bintang itu lebih stabil, mengingat banyak orang yang menggunakannya. Penting juga untuk mengecek deskripsi package untuk relevansi, apa package ini cocok untuk projek kita atau tidak.

Nah, yang kita perlukan adalah string to slug converter yang sederhana. Dari hasil pencarian, package `cocur/slugify` tampaknya cocok nih, ada banyak orang yang install dan juga bintang. (Package ini ada di bawah banget lho, jadi ga ikut ke-screenshot di atas).

Mungkin kamu bisa lihat package di Packagis itu memiliki nama vendor dan nama package. Setiap package ini memiliki pengenal yang unik (sebuah namespace), sama dengan format yang digunakan Github untuk repositorinya.
```bash
require Package
```

Sekarang kita sudah tahu betul package mana yang ingin kita install. Kita dapat mengeksekusi perintah 'composer require' untuk menambahkannya sebagai dependensi dan juga generate composer.json untuk projek. Nah, sekarang kita jalankan perintah di bawah ini:
```bash
composer require cocur/slugify
```

Ya, kita bisa lihat notifikasi seperti gambar di bawah:
![install package](https://2.bp.blogspot.com/-mzZjYh7d2-w/WEtqpDpelII/AAAAAAAAAnA/m8iNY05T698wFwUpuBFUj19oB73dMI_NQCLcB/w640-h152/Cara%2Binstalasi%2Bdan%2Bpenggunaan%2BComposer%2Bpada%2BUbuntu%2B16-04-gambar%2B5.png) 

Seperti yang bisa kita lihat di gambar, Composer secara otomatis memutuskan versi package mana yang seharusnya digunakan. Jika kamu cek direktori projek sekarang, kamu bisa lihat file baru, yaitu `composer.json` dan `composer.lock` dan juga direktori vendor.

Kamu bisa cek direktori dengan menjalankan perintah:
```bash
ls -l
```

![cek direktori](https://1.bp.blogspot.com/-JsNbZ4-mpQo/WEtqs4zFsQI/AAAAAAAAAnE/Q5KZqiT3MVktTUMD2X-4i2hxYF3TolamgCLcB/w640-h84/Cara%2Binstalasi%2Bdan%2Bpenggunaan%2BComposer%2Bpada%2BUbuntu%2B16-04-gambar%2B6.png)

Keterangan:
1. File `composer.lock` digunakan untuk menyimpan informasi tentang versi setiap package yang diinstall dan memastikan versi sama digunakan jika ada orang lain yang meng-clone projek kita dan menginstal dependensinya. 
2. Direktori `vendor` merupakan tempat dependensi projek disimpan. Folder vendor tidak harus dicommit ke dalam version control, kamu hanya perlu melampirkan file `composer.json` dan `composer.lock`.

**Note**: Ketika menginstal sebuah projek yang sudah memiliki sebuah file composer.json, kamu perlu run perintah 'composer install' untuk mengunduh dependensi projek tersebut.

### 3.2 Memahami Version Constraint.
Sekarang kita coba lihat isi composer.json dengan perintah ini di terminal:
 ```bash
 cat composer.json
```

Kita bisa lihat isinya seperti ini:
```
 {     "require": {         "cocur/slugify": "^1.3"     } }
```

Kamu bisa lihat ada karakter spesial `^` sebelum nomor versi pada composer.json. Composer support beberapa constrain dan format yang beda untuk mendefinisikan versi package yang dibutuhkan, untuk menjaga fleksibitas dan juga kestabilan projek tentunya. Simbol caret (^) digunakan auto-generated composer.json untuk merekomendasikan interoperabilitas, mengikuti semantice versioning. Dalam kasus ini, itu mendefinisikan 1.3 sebagai versi compatible minimum dan mengijinkan update ke versi terbaru di bawah 2.0.

Biasanya, kamu tidak perlu mengubah constrain versi dalam file composer.json. Akan tetapi, beberapa situasi mungkin memerlukan mengeditnya secara manual. Contohnya, ketika versi baru pada library yang digunakan sudah dirilis dan kamu ingin mengupgrade, atau ketika library yang diinginkan tidak mengikuti semantic versioning.

Untuk mengetahui lebih lanjut tentang Composer version constraint, bisa kamu cek di Dokumentasi resmi.

### 3.3 Include Script Autoload 
Composer juga menyediakan script autoload yang dapat kamu include di dalam project. Hal memudahkan untuk bekerja dengan dependensi dan mendefinisikan `namespace`.

Hal yang kamu perlukan adalah include `vendor/autoload.php` ke dalam script PHP kamu, sebelum instansiasi class.

Sekarang kita coba ke contoh projek slugify kita yang tadi. Kita akan buat script test.php di mana kita akan menggunakan library cocur/slugify. Sekarang buka teks editor kesayanganmu lalu ketik script di bawah ini ya..

```php
<?php
require __DIR__ . '/vendor/autoload.php';
use Cocur\Slugify\Slugify;
$slugify = new Slugify();
echo $slugify->slugify('Hello World, ini adalah contoh kalimat yang ingin dijadikan sebagai slug!');
```

Sekarang kita coba run dengan perintah di bawah ini:
```bash
php test.php
```

Ya, kita bisa lihat hasilnya,
```bash
hello-world-ini-adalah-contoh-kalimat-yang-ingin-dijadikan-sebagai-slug
```

### 3.4 Update Dependensi Projek
Kapanpun kamu ingin mengupdate dependensi projekmu, kamu hanya perlu run perintah update:
```bash
composer update
```

Dengan perintah tersebut, composer akan mengecek versi terbaru dari library yang digunakan dalam projek kamu lho! Nah, kalau versi terbaru ketemu dan itu compatible dengan version constraint yang didefinisikan pada file composer.json, itu akan me-replace versi sebelumnya yang terinstall. File composer.lock akan diupdate berdasarkan perubahan tersebut.

Kamu juga bisa update satu atau lebih library dengan menjalankan perintah:
```bash
composer update vendor/package vendor2/package2
```

## Penutup{#penutup}

Banyak programmer terbiasa dengan bahasa pemrograman yang terstruktur, ketika pindah ke php menemukan banyak hal yang rancu. Terutama dalam mengelola struktur projek. Sehingga membutuhkan usaha lebih untuk menerapkan konsep OOP yang baik dalam php. Dengan menyediakan kemudahan dan cara yang menarik untuk mengelola dependensi projek, Kehadiran **composer** membuat ngoding php jadi lebih terstruktur dan lebih rapi. Selain itu, kita memiliki akses yang luas dan mudah untuk mendapatkan banyak package. Tentunya ini bisa meningkatkan tingkat keproduktifitasan kita serta meningkatkan efektifitas kerja. Sangat menarik bukan?

Semoga bermanfaat.. Semoga belajarnya semakin menyenangkan.. :D