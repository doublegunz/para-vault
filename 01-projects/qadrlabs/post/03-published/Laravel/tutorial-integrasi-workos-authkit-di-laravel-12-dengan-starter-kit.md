---
title: "Tutorial Integrasi WorkOS AuthKit di Laravel 12 dengan Starter Kit"
slug: "tutorial-integrasi-workos-authkit-di-laravel-12-dengan-starter-kit"
category: "Laravel"
date: "2025-03-07"
status: "published"
---

Salah satu fitur yang ditawarkan ketika rilis Laravel 12 adalah Starter Kit baru untuk laravel. Sebagai tambahan dalam rilisnya [Laravel 12 Starter Kit](https://qadrlabs.com/post/laravel-12-starter-kit) adalah pengenalan opsi authentication provider menggunakan WorkOS AuthKit.

## Overview {#overview}
Pada artikel [Laravel 12](https://qadrlabs.com/post/laravel-12) ini kita akan coba menggunakan WorkOS AuthKit sebagai authentication provider untuk project laravel. Untuk menggunakan provider tersebut, kita perlu mempersiapkan akun WorkOS dan juga mempersiapkan `Client ID`, `Secret Keys`, redirect URI. Setelah persiapakan, kita akan coba install project baru dengan memilih opsi WorkOS sebagai authentication provider. Selanjutnya kita akan uji coba provider tersebut dengan mengakses fitur yang tersedia.

![Authentication menggunakan WorkOS AuthKIT](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-workos-authkit/1-akses-halaman-login.PNG)

## Persiapan {#persiapan}
1. Untuk menggunakan workos, kita perlu membuat akun terlebih dahulu di `https://dashboard.workos.com`. Buat akun untuk dapat mengakses Dashboard WorkOS.
	![akses dashboard WorkOS](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-workos-authkit/0-persiapan-environment.PNG)
2. Akses dashboard workos, lalu masuk ke menu **API Keys**. Pada halaman API Keys, catat `Client ID` dan juga `Secret Key`. Apabila bila belum tersedia, kita bisa buat Secret Keys dengan menekan tombol `Create Keys`.
	![akses halaman api keys WorkOS](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-workos-authkit/0-persiapan-api-keys.PNG)
3. Selanjutnya akses menu **Redirects**, lalu kita atur **Sign-in callback** dengan menekan button `Edit Redirect URIs`. Kita masukan `http://127.0.0.1:8000/authenticate` sebagai Redirect URI. Redirect URI ini digunakan untuk menentukan URI tujuan setelah user melengkapi langkah autentikasi menggunakan workos AuthKIT.
	![akses halaman redirect URI WorkOS](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-workos-authkit/0-persiapan-redirect-uri.PNG)

Setelah proses persiapan, kita sudah setup `Client ID`, `Secret Key` dan juga `Redirect URI` di dashboard WorkOS untuk penggunaan AuthKit WorkOS.


## Step 1: Buat Project{#step-1-buat-project}
Pertama kita buat dulu project baru menggunakan laravel installer.
```
laravel new my-app
```
Selanjutnya tampil prompt untuk memilih starter kit. Sebagai contoh saya coba pilih `livewire`.
```
$ laravel new my-app

   _                               _
  | |                             | |
  | |     __ _ _ __ __ ___   _____| |
  | |    / _` |  __/ _` \ \ / / _ \ |
  | |___| (_| | | | (_| |\ V /  __/ |
  |______\__,_|_|  \__,_| \_/ \___|_|


 Which starter kit would you like to install? [None]:
  [none    ] None
  [react   ] React
  [vue     ] Vue
  [livewire] Livewire
 > livewire
livewire
```

Selanjutnya apabila tampil prompt authentication provider, kita pilih `workos`.
```
 Which authentication provider do you prefer? [Laravel's built-in authentication]:
  [laravel] Laravel's built-in authentication
  [workos ] WorkOS (Requires WorkOS account)
 > workos
workos
```

Selanjutnya kita pilih testing framework. Ketik `0`, lalu `enter` untuk melanjutkan.
```

 Which testing framework do you prefer? [Pest]:
  [0] Pest
  [1] PHPUnit
 > 0
0
```

Apabila tampil prompt untuk build asset.
```
 Would you like to run npm install and npm run build? (yes/no) [yes]:
 > yes

```
ketik `yes`, tekan `enter` untuk melanjutkan.

## Step 2: Atur Konfigurasi Project {#step-2-atur-konfigurasi}
Selanjutnya kita akan atur konfigurasi project. Untuk mengatur konfigurasi, kita masuk ke direktori project.
```
cd my-app
```
Lalu kita buka project di code editor.
```
code .
```

Selanjutnya buka file `.env` di code editor. Pada file `.env`, kita atur konfigurasi database dan konfigurasi AuthKit WorkOS.

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_belajar_laravel
DB_USERNAME=root
DB_PASSWORD=password


WORKOS_CLIENT_ID=client_xxxxxxxxxxxxxxxxxxxxxxxxxx
WORKOS_API_KEY=sk_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
WORKOS_REDIRECT_URL="http://127.0.0.1:8000/authenticate"
```

Keterangan: Konfigurasi Authkit WorkOS ada di bagian paling bawah di file `.env`. `WORKOS_CLIENT_ID` diisi dengan `Client ID` dan `WORKOS_API_KEY` diisi dengan `SecretKey`.

Selanjutnya kita run migrate command.
```
php artisan migrate
```

Apabila tampil prompt database belum tersedia, ketik `yes`, lalu tekan `enter` untuk melanjutkan.
```
$ php artisan migrate                                                                                 
                                                                                                      
   WARN  The database 'db_belajar_laravel' does not exist on the 'mysql' connection.                  
                                                                                                      
  Would you like to create it? (yes/no) [yes]                                                         
❯ yes                                                                                                 
                                                                                                      
   INFO  Preparing database.                                                                          
                                                                                                      
  Creating migration table ............................................................ 122.67ms DONE 
                                                                                                      
   INFO  Running migrations.                                                                          
                                                                                                      
  0001_01_01_000000_create_users_table ................................................ 279.33ms DONE 
  0001_01_01_000001_create_cache_table ................................................ 101.38ms DONE 
  0001_01_01_000002_create_jobs_table ................................................. 291.60ms DONE 

```

## Step 3: Uji Coba{#step-3-uji-coba}
Sekarang kita coba login menggunakan AuthKit WorkOS. Run project menggunakan command berikut.
```
php artisan serve
```

Selanjutnya buka project di browser melalui `http://127.0.0.1:8000`. Pada halaman awal project tekan link `login` untuk masuk ke halaman login.

![akses halaman login](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-workos-authkit/1-akses-halaman-login.PNG)

Karena kita belum punya akun, kita bisa coba login menggunakan akun google, microsoft, github dan apple.

Sekarang kita coba akses halaman register dengan klik link `Sign up`. Kita bisa coba daftar dengan mengisi isian pada form dan juga menggunakan akun google, microsoft, github dan apple.

![akses halaman register](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-workos-authkit/2-akses-halaman-login.PNG)

![uji coba daftar](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-workos-authkit/3-tes-daftar.PNG)

Apabila kita sudah berhasil daftar, selanjutnya kita akan dialihkan ke halaman dashboard (`http://127.0.0.1:8000/dashboard`).

![akses halaman dashboard setelah daftar](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-workos-authkit/4-halaman-dashboard.PNG)

## Kendala yang ditemui {#kendala-yang-ditemui}
Ketika kita coba login, tampil error `Invalid redirect URI`.

![Error redirect uri](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-workos-authkit/5-error-invalid-redirect-uri.PNG)

Error ini disebabkan karena value `WORKOS_REDIRECT_URL` tidak sesuai. Solusinya kita sesuaikan value `WORKOS_REDIRECT_URL` dengan pengaturan di halaman Redirects pada dashboard WorkOS (`https://dashboard.workos.com/`).



## Penutup {#penutup} 
Artikel ini telah membahas langkah-langkah integrasi WorkOS AuthKit sebagai authentication provider pada proyek Laravel 12 menggunakan Starter Kit terbaru. Dengan memanfaatkan fitur ini, pengembang dapat mempercepat implementasi sistem login/register yang mendukung berbagai penyedia layanan seperti Google, Microsoft, GitHub, dan Apple, tanpa perlu mengonfigurasi OAuth secara manual.  

Proses integrasi melibatkan beberapa tahap kritis:  
1. **Persiapan akun WorkOS** untuk mendapatkan `Client ID`, `Secret Key`, dan pengaturan Redirect URI.  
2. **Pembuatan proyek Laravel** dengan memilih opsi WorkOS saat inisialisasi Starter Kit.  
3. **Konfigurasi `.env`** untuk menyimpan kredensial WorkOS dan migrasi database.  
4. **Pengujian autentikasi** melalui halaman login dan register yang telah terintegrasi.  

Kendala seperti *invalid redirect URI* dapat diatasi dengan memastikan konfigurasi URL di dashboard WorkOS sesuai dengan nilai `WORKOS_REDIRECT_URL` pada aplikasi. Hal ini menegaskan pentingnya keselarasan antara pengaturan lokal dan konfigurasi layanan pihak ketiga.  

Dengan dukungan WorkOS AuthKit, Laravel 12 tidak hanya menyederhanakan proses autentikasi tetapi juga meningkatkan keamanan dan fleksibilitas pengembangan aplikasi. Bagi pengembang yang ingin fokus pada logika bisnis tanpa repot mengurus kompleksitas autentikasi, kombinasi Laravel 12 dan WorkOS menjadi solusi yang layak untuk diadopsi.