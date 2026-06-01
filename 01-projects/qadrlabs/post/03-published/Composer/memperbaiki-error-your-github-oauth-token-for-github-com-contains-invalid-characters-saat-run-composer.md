---
title: "Memperbaiki Error Your GitHub OAuth token for github.com contains invalid characters saat run composer"
slug: "memperbaiki-error-your-github-oauth-token-for-github-com-contains-invalid-characters-saat-run-composer"
category: "Composer"
date: "2022-04-26"
status: "published"
---

Pernahkah Anda mengalami kendala saat menggunakan Composer untuk mengelola dependensi project PHP karena masalah token GitHub? Masalah ini cukup umum terjadi, terutama setelah GitHub mengubah format token aksesnya. Banyak developer PHP yang tiba-tiba menemukan error yang membingungkan setelah melakukan clone project dari GitHub dan Composer meminta personal access token. 

Dalam artikel ini, kita akan membahas penyebab error token GitHub pada Composer dan memberikan beberapa solusi praktis yang dapat Anda terapkan untuk mengatasi masalah tersebut. Dari update Composer hingga konfigurasi manual file auth.json, semua solusi akan dibahas secara detail dengan langkah-langkah yang mudah diikuti. Mari kita mulai!

## Prerequisites{#prerequisites}
Sebelum mencoba solusi di bawah, pastikan Anda:
- Memiliki akses internet yang stabil
- Memiliki akun Github
- Sudah menginstall PHP dan Git

## Kendala yang ditemukan {#kendala-yang-ditemukan}
Ketika bekerja dengan Composer dan Git untuk mengelola project PHP, kita mungkin akan menemui situasi di mana Composer meminta token akses GitHub. Proses ini sebenarnya merupakan bagian dari mekanisme autentikasi yang memungkinkan Composer mengakses repositori private atau meningkatkan batas rate limit API GitHub kita.

Pada awalnya, Composer akan menampilkan pesan yang mengarahkan kita untuk membuat personal access token GitHub seperti contoh berikut:

```bash
Head to https://github.com/settings/tokens/new?scopes=repo&description=Composer+on+nama-komputer+2022-04-26+1315
to retrieve a token. It will be stored in "/home/user/.config/composer/auth.json" for future use by Composer.
Token (hidden): 
```

Setelah Anda mengikuti petunjuk, membuat token, dan memasukkannya ke Composer, instalasi package biasanya akan berjalan dengan lancar. Namun, masalah yang membingungkan muncul pada penggunaan Composer berikutnya. Tiba-tiba Anda mendapatkan pesan error:

```bash
[UnexpectedValueException]                                                   
Your github oauth token for github.com contains invalid characters: "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"                                  
```

Error ini terjadi karena adanya ketidakcocokan antara format token baru GitHub (yang dimulai dengan "ghp_") dan versi Composer yang Anda gunakan. GitHub telah memperbarui format token aksesnya, sementara versi Composer yang lebih lama belum diperbarui untuk mendukung format token baru tersebut. Inilah yang menyebabkan Composer menganggap token Anda mengandung karakter yang tidak valid, padahal sebenarnya format token tersebut sudah benar menurut standar GitHub saat ini.

## Solusi 1 - Update Composer (Recommended){#solusi-1}
Solusi paling disarankan adalah mengupdate composer ke versi terbaru yang sudah mendukung format token Github yang baru.

1. Download installer composer terbaru:
```bash
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
```

2. Verifikasi installer:
```bash
php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
```

3. Install composer:
```bash
php composer-setup.php
```

4. Hapus installer:
```bash
php -r "unlink('composer-setup.php');"
```

5. Pindahkan ke direktori global:
```bash
sudo mv composer.phar /usr/local/bin/composer
```

> **Tips:** Pastikan untuk selalu menggunakan versi composer terbaru untuk menghindari masalah kompatibilitas.

## Solusi 2 - Fix Manual auth.json{#solusi-2}
Jika update composer tidak menyelesaikan masalah, Anda bisa mencoba fix manual file `auth.json`. Namun perlu diingat cara ini **tidak direkomendasikan** untuk jangka panjang.

1. Buka file auth.json di:
```bash
/home/user/.config/composer/auth.json
```

2. Format lama (yang error):

```
    "github-oauth": {
        "github.com": "ghp_[PERSONAL-TOKEN-GITHUB-KAMU]"
    }

```

3. Ubah menjadi format baru:

```
    "http-basic": {
        "github.com": {
            "username": "[USERNAME-GITHUB-KAMU]",
            "password": "ghp_[PERSONAL-TOKEN-GITHUB-KAMU]"
        }
    }

```

## Solusi 3 - Reinstall via Homebrew{#solusi-3}
Untuk pengguna macOS atau Linux dengan Homebrew, bisa mencoba reinstall composer:

Install baru:
```bash
brew install composer
```

Atau reinstall jika sudah ada:
```bash
brew reinstall composer
```

## Uji Coba{#uji-coba}
Setelah menerapkan salah satu solusi di atas, mari kita uji apakah composer sudah berfungsi normal. Kita akan mencoba membuat project Laravel baru:

```bash
composer create-project --prefer-dist laravel/laravel blog
```

Output yang diharapkan:
```bash
Creating a "laravel/laravel" project at "./blog"
Installing laravel/laravel (v10.2.6)
  - Installing laravel/laravel (v10.2.6): Extracting archive
Created project in /home/user/projects/blog
> @php -r "file_exists('.env') || copy('.env.example', '.env');"
Loading composer repositories with package information
Installing dependencies (including require-dev)...

[... proses instalasi package ...]

Application ready! Build something amazing.
```

## Resources{#resources}
- [Dokumentasi Composer](https://getcomposer.org/doc/)
- [Github Personal Access Tokens](https://github.com/settings/tokens)
- [Laravel Installation Guide](https://laravel.com/docs/installation)

## Kesimpulan{#kesimpulan}
Error token GitHub pada Composer memang bisa menjadi kendala yang mengganggu proses development. Namun seperti yang telah kita bahas, ada beberapa solusi efektif yang dapat diterapkan. Mengupdate Composer ke versi terbaru tetap menjadi rekomendasi utama karena mendukung format token GitHub yang baru. Alternatif lainnya seperti perbaikan manual file auth.json atau reinstall via Homebrew juga dapat dicoba jika metode pertama belum berhasil.

Penting untuk selalu mengikuti perkembangan terbaru dari GitHub dan Composer karena kedua platform ini terus melakukan pembaruan keamanan yang dapat memengaruhi cara autentikasi.

Jika Anda masih mengalami kesulitan setelah mencoba ketiga solusi di atas, jangan ragu untuk mencari bantuan di komunitas developer, bertanya di forum seperti Stack Overflow, atau membuka issue di repositori GitHub Composer. Berbagi pengalaman dan solusi dengan komunitas juga membantu developer lain yang mungkin menghadapi masalah serupa.

Terima kasih telah membaca artikel ini. Semoga informasi yang disampaikan dapat membantu Anda menyelesaikan masalah token GitHub di Composer dan membuat proses development Anda kembali lancar. Selamat coding!