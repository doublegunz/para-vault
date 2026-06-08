---
title: "Belajar Laravel 8: Deploy Project ke Heroku"
slug: "belajar-laravel-8-deploy-project-ke-heroku"
category: "Laravel"
date: "2021-10-09"
status: "published"
---

Ketika belajar web programming, saya selalu membuat target kalau web yang saya buat pada saat belajar itu harus bisa di-deploy. Tentu saja pada saat belajar laravel 8 pun saya mencoba untuk men-deploy project belajar saya ke server production. Ada banyak hosting yang bisa kita gunakan secara gratis (*free tier*) untuk keperluan belajar deploy, salah satunya adalah heroku.

[Heroku](https://www.heroku.com/what) adalah sebuah cloud platform yang mendukung beberapa bahasa pemrograman, seperti PHP, Node.js, Ruby, Java, Python, Go, Scala dan Clojure. Heroku ini termasuk sebuah *Platform As A Service* (PaaS), sehingga kita tidak perlu bingung dengan masalah infrastruktur ketika ingin men-deploy aplikasi. Kita hanya perlu push menggunakan git, setting konfigurasi aplikasi dan project pun bisa langsung kita akses. Ini sangat cocok untuk belajar deploy project laravel kita dan kabar baiknya heroku juga menyediakan *free tier* yang bisa kita gunakan untuk uji coba.

**Keterangan**
Berdasarkan email dari heroku, per tanggal 28 November 2022 *free tier* heroku sudah tidak tersedia.

Di edisi [belajar laravel 8](https://qadrlabs.com/series/belajar-laravel-8) ini, kita akan sama-sama belajar,
1. Cara deploy project laravel 8 ke heroku.
2. Cara mengatur konfigurasi untuk project.
3. Cara mengatur konfigurasi database di heroku.

Dan ini langkah-langkah yang akan kita coba di edisi belajar laravel 8 ini,
1. Persiapan
2. Buat Project Demo
3. Deploy Project
4. Setting Konfigurasi Project di Heroku
5. Setting Database
6. Menambahkan fitur login dan register

Yuk, kita mulai.

## 1. Persiapan{#persiapan}
Di edisi belajar laravel 8 kali ini, kita akan coba deploy projek laravel 8 ke heroku. Untuk mengikuti tutorial ini, asumsinya kamu sudah punya:
1. Akun heroku. Kalau belum ada, boleh [daftar](https://signup.heroku.com/dc) dulu,
2. [Composer](https://qadrlabs.com/post/cara-installasi-dan-penggunaan-composer-pada-ubuntu-16-04).
3. Git
4. Heroku CLI. Untuk instalasi bisa cek di [sini](https://devcenter.heroku.com/articles/heroku-cli)
5. PHP yang terinstall di komputer kamu.

Sebelum memulai, kita bisa cek terlebih dahulu PHP dengan run `command`.
```bash
php -v
```

Selanjutnya kita cek apakah `composer` sudah terinstall.
```bash
composer -V
```

Lalu kita cek juga apakah `git` sudah terinstall.
```bash
git --version
```

Dan terakhir kita coba login ke heroku melalui heroku cli.
```
heroku login
```

Setelah run command di atas, browser akan membuka halaman login heroku. Kalau kita sudah login terlebih dahulu, nanti kita tinggal klik saja tombol `Log in` yang ada di halaman tersebut. Ini output di terminal ketika kita berhasil login.

```bash
$ heroku login
heroku: Press any key to open up the browser to login or q to exit: 
Opening browser to https://cli-auth.heroku.com/auth/cli/browser/ada-token-random-di-sini
Logging in... done
Logged in as gungun@qadrlabs.com
```

Nah persiapan kita sudah siap selanjutnya kita sudah bisa mulai belajar untuk deploy project laravel 8.


## 2. Buat Project Demo{#buat-project}
Sekarang kita buat terlebih dahulu sample project yang akan kita deploy ke heroku.
```bash
composer create-project --prefer-dist laravel/laravel deploy-demo-app
```

Tunggu sampai proses create project selesai, lalu masuk ke folder project
```
cd deploy-demo-app
```

Selanjutnya kita buat file `Procfile` untuk mendeklarasikan `command` apa yang akan dieksekusi untuk memulai aplikasi atau project yang di-deploy.
```bash
echo web: vendor/bin/heroku-php-apache2 public/ > Procfile
```


## 3. Deploy Project{#deploy-project}
Pada tahapan ini kita akan coba deploy project yang sudah kita siapkan ditahapan sebelumnya.

Di dalam root folder project, kita inisiasikan repositori baru menggunakan `git` command di bawah ini.
```bash
git init
git add .
git commit -m "init project deploy ke heroku"
```

Selanjutnya kita buat project baru di heroku, yang nantinya heroku akan menerima source code kita.
```bash
heroku create
```

Setelah kita run command di atas, kita bisa lihat ada project baru di [dashboard heroku](https://dashboard.heroku.com/apps) kita. Oh iya nama aplikasi yang dibuat itu di-generate secara acak. Jadi nanti namanya beda.

Sebelum kita deploy project, kita cek terlebih dahulu remote repositori di heroku menggunakan `git` command.
```bash
git remote -v
```

Contoh output dari command di atas kurang lebih seperti ini.
```bash
➜ deploy-demo-app (master) ✔ git remote -v
heroku  https://git.heroku.com/limitless-headland-58272.git (fetch)
heroku  https://git.heroku.com/limitless-headland-58272.git (push)
```

Ya, remote repositori kita beda. Namanya disesuaikan dengan nama aplikasi yang di-generate secara acak tadi.

Selanjutnya kita push project `deploy-demo-app` ke heroku.
```bash
git push heroku master
```

Kita tunggu sampai project kita selesai di-deploy.

Di terminal kita bisa lihat output `remote: Verifying deploy... done.` tanda project kita berhasil kita deploy. Sekarang kita coba cek project kita menggunakan command.
```bash
heroku open
```

Yap, ada error. Baik setidaknya kita bisa lihat url dari project kita dan URLnya sesuai dengan nama project kita. Ini contoh URLnya.
```
https://limitless-headland-58272.herokuapp.com/
```


## 4. Setting Konfigurasi Project di Heroku{#setting-config}
Penyebab utama project error ketika kita akses di browser adalah belum diaturnya konfigurasi project. Kalau di local biasanya kita mengatur konfigurasi itu di file `.env`. Di heroku kita bisa atur konfigurasi project melalui command di bawah ini.

```bash
heroku config:add APP_NAME=Laravel
heroku config:add APP_ENV=production
heroku config:add APP_KEY=base64:0vuqOjqFa2JTbm73jkxCnDBR8wmSDtJHtj1i9Uz7xxk=
heroku config:add APP_DEBUG=true
heroku config:add APP_URL=https://limitless-headland-58272.herokuapp.com/
```

Setelah kita atur konfigurasi project, kita cek kembali web dengan mengakses URL project kita. Sekarang kita bisa lihat halaman utama laravel.


## 5. Setting Database{#setting-db}
Setelah eksplore heroku, ternyata kita bisa memakai database secara gratis. Di sini kita coba menggunakan Postgresql ke project kita.

Buka kembali terminal, lalu kita tambahkan Postgresql menggunakan `heroku` command.
```bash
heroku addons:create heroku-postgresql:hobby-dev
```

Setelah database kita tambahkan. Kita perlu mengatur konfigurasi database ke project kita. Untuk itu kita perlu mengetahui pengaturan database. Nah di sini kita coba cek melalui `heroku` command.
```bash
heroku pg:credentials:url
```

Output command di atas kurang lebih seperti ini:
```bash
$ heroku pg:credentials:url
Connection information for default credential.
Connection info string:
   "dbname=df2oga2lb9t5d host=ec2-54-161-189-150.compute-1.amazonaws.com port=5432 user=zabeebowwlhgnx password=ea4513b2b73275f2f9ea621c151dc852c1152a599f350a133d05bce387c67ad1 sslmode=require"
Connection URL:
   postgres://zabeebowwlhgnx:ea4513b2b73275f2f9ea621c151dc852c1152a599f350a133d05bce387c67ad1@ec2-54-161-189-150.compute-1.amazonaws.com:5432/df2oga2lb9t5d
```

**Note:** Ini contoh untuk keperluan tutorial, jadi teman-teman tidak direkomendasikan untuk sharing credential database ke orang lain ya.

Nah dari command di atas, kita bisa mengetahui info seputar pengaturan database seperti nama database, port, username dan password. Sekarang kita bisa tambahkan konfigurasi untuk database ke project kita menggunakan `heroku` command.
```bash
heroku config:add DB_CONNECTION=pgsql
heroku config:add DB_HOST=ec2-54-161-189-150.compute-1.amazonaws.com
heroku config:add DB_PORT=5432
heroku config:add DB_DATABASE=df2oga2lb9t5d 
heroku config:add DB_USERNAME=zabeebowwlhgnx
heroku config:add DB_PASSWORD=ea4513b2b73275f2f9ea621c151dc852c1152a599f350a133d05bce387c67ad1
```

Jangan lupa sesuaikan dengan credentials database teman-teman.

Selanjutnya kita coba tes database kita. Kita run `artisan migrate` command untuk melakukan proses migration database.
```bash
heroku run php artisan migrate
```

Ketika ada pertanyaan seperti di bawah ini, ketik `yes` lalu enter untuk melanjutkan proses migrate
```bash
 Do you really wish to run this command? (yes/no) [no]:
 > yes
```

Contoh output di terminal:
```bash
$ heroku run php artisan migrate
Running php artisan migrate on ⬢ limitless-headland-58272... up, run.6475 (Free)
**************************************
*     Application In Production!     *
**************************************

 Do you really wish to run this command? (yes/no) [no]:
 > yes

Migration table created successfully.
Migrating: 2014_10_12_000000_create_users_table
Migrated:  2014_10_12_000000_create_users_table (44.08ms)
Migrating: 2014_10_12_100000_create_password_resets_table
Migrated:  2014_10_12_100000_create_password_resets_table (39.89ms)
Migrating: 2019_08_19_000000_create_failed_jobs_table
Migrated:  2019_08_19_000000_create_failed_jobs_table (50.78ms)
Migrating: 2019_12_14_000001_create_personal_access_tokens_table
Migrated:  2019_12_14_000001_create_personal_access_tokens_table (60.01ms)

```


## 6. Menambahkan fitur login dan register{#add-login-register-feature}
Project kita sudah bisa kita akses dan database kita sudah terhubung ke project, tetapi kita belum tahu apakah operasi yang memerlukan interaksi database bisa berjalan dengan lancar. Untuk itu sekarang kita aka, coba menambahkan fitur login dan register di project kita.

Kita install terlebih dahulu package `laravel/ui` melalui `composer`.
```bash
composer require laravel/ui
```

Setelah itu, kita install frontend scaffolding bootstrap menggunakan `ui artisan` command.
```bash
php artisan ui bootstrap --auth
```

Selanjutnya kita run command di bawah ini untuk menginstall dependensi dan compile assets.
```bash
npm install && npm run dev
```

Setelah auth scaffolding sudah kita tambahkan, kita coba push dan deploy ke heroku.
```bash
git add .
git commit -m "feat: add auth"
git push heroku master
```

Selanjutnya kita coba cek kembali project kita.
```bash
heroku open
```

Setelah project kita akses melalui browser, kita bisa coba melakukan register dan login ke project kita.


## Kesimpulan{#kesimpulan}
Di edisi [Belajar Laravel 8](https://qadrlabs.com/posts/category/laravel) kali ini, kita sudah mencoba untuk melakukan deploy project laravel ke sebuah cloud platform heroku. Kita sudah belajar bagaimana cara deploy project sampai project bisa kita akses melalui browser. Ada banyak hal yang bisa kita eksplore lagi, ketika kita sudah bisa deploy project laravel 8 kita, misalnya bagaimana kalau proses registernya mesti ada verifikasi email atau bagaimana caranya kalau kita menggunakan `queue` ketika mengirimkan email dan lainnya. Jikalau ada waktu dan kesempatan, mungkin akan saya coba bahas di edisi berikutnya.

Sampai jumpa di edisi berikutnya.
Semoga bermanfaat.