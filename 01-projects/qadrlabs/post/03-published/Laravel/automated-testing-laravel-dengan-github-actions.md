---
title: "Automated Testing Laravel dengan GitHub Actions"
slug: "automated-testing-laravel-dengan-github-actions"
category: "Laravel"
date: "2024-09-16"
status: "published"
---

## Introduction{#introduction}

Pengembangan aplikasi web sering kali melibatkan banyak proses, salah satunya adalah pengujian. Seiring dengan semakin banyaknya fitur yang ditambahkan ke aplikasi, pengujian manual menjadi tidak efisien. Maka dari itu, di sinilah Continuous Integration (CI) dan Continuous Deployment (CD) memainkan peran penting untuk mempermudah pengembang melakukan pengujian otomatis sebelum perubahan diterapkan di lingkungan produksi.

Pada tutorial kali ini, kita akan membahas bagaimana cara membuat workflow GitHub Action untuk mengotomatisasi pengujian Laravel. GitHub Actions adalah platform yang memungkinkan kita membuat alur kerja otomatis langsung dari repositori kita. Dengan GitHub Actions, kita bisa menjalankan pengujian unit dan fitur Laravel secara otomatis setiap kali ada perubahan yang didorong ke repositori.

---

## Overview{#overview}

Tutorial ini akan memandu Anda melalui proses pengaturan GitHub Actions di proyek Laravel. Kita akan membuat sebuah project Laravel baru, menginisialisasi repositori Git, membuat file workflow untuk pengujian otomatis, dan melihat hasil dari pengujian yang dijalankan.

### Apa yang akan kita lakukan?
- Membuat project Laravel baru.
- Menginisialisasi Git di repositori lokal dan menyambungkannya ke GitHub.
- Menulis file workflow untuk menjalankan pengujian otomatis menggunakan GitHub Actions.
- Melihat hasil pengujian di tab Actions pada repositori GitHub.

### Apa tujuan dari tutorial ini?
Setelah menyelesaikan tutorial ini, Anda akan mampu:
1. Mengatur pengujian otomatis untuk project Laravel menggunakan GitHub Actions.
2. Menjalankan tes unit dan fitur Laravel secara otomatis setiap kali ada perubahan kode.
3. Memahami konsep dasar CI/CD dalam konteks Laravel dan GitHub Actions.

---

## Table of Content{#table-of-content}

- [Introduction](#introduction)
- [Overview](#overview)
- [Step 1: Buat Project Laravel Baru](#step-1-buat-project-laravel-baru)
- [Step 2: Init Repositori Git](#step-2-init-repositori-git)
- [Step 3: Buat Workflow File](#step-3-buat-workflow-file)
- [Step 4: Melihat Hasil Workflow](#step-4-melihat-hasil-workflow)
- [Conclusion](#conclusion)

---

## Step 1: Buat Project Laravel Baru{#step-1-buat-project-laravel-baru}

Pertama-tama, kita akan membuat project Laravel baru. Pastikan Anda sudah menginstal Composer dan PHP versi terbaru. Di terminal, jalankan perintah berikut untuk membuat project Laravel:

```bash
composer create-project --prefer-dist laravel/laravel belajar-github-action
```

Proses ini akan mengunduh dan menginstal Laravel beserta dependensinya. Setelah proses selesai, kita bisa mulai bekerja dengan project baru ini.

---

## Step 2: Init Repositori Git{#step-2-init-repositori-git}

Setelah project Laravel siap, langkah selanjutnya adalah menginisialisasi repositori Git di direktori project. Git akan melacak semua perubahan kode yang kita buat, dan memungkinkan kita untuk mendorongnya ke repositori GitHub.

### Inisialisasi Git
Jalankan perintah berikut untuk menginisialisasi repositori Git di direktori project:

```bash
git init
```

Setelah itu, tambahkan semua file ke staging area dengan perintah berikut:

```bash
git add .
```

Kemudian, lakukan commit awal untuk menyimpan snapshot dari project kita:

```bash
git commit -m "init repositori belajar github action"
```

### Tambahkan Repositori Remote
Kita perlu menambahkan repositori GitHub sebagai remote agar bisa push kode kita ke GitHub. Pastikan Anda sudah membuat repositori di GitHub sebelumnya.

Jalankan perintah berikut untuk menambahkan remote:

```bash
git remote add origin https://github.com/repositori-kamu/belajar-ci-cd-github-action.git
git branch -M main
git push -u origin main
```

Perintah di atas menambahkan remote dengan nama `origin`, menetapkan branch utama sebagai `main`, dan push kode ke repositori GitHub.

Sebagai contoh saya sudah membuat repositori baru, yaitu [https://github.com/gungunpriatna/belajar-github-action](https://github.com/gungunpriatna/belajar-github-action). Selanjutnya saya tambahkan remote repositori.
```
git remote add origin https://github.com/gungunpriatna/belajar-github-action.git
```

Selanjutnya kita jadikan `main` sebagai branch utama
```
git branch -M main
```

Lalu kita coba push kode ke repositori ke github.
```
git push -u origin main
```

---

## Step 3: Buat Workflow File{#step-3-buat-workflow-file}

Untuk mengatur GitHub Actions, kita perlu membuat file workflow di dalam direktori `.github/workflows`. File ini akan berisi instruksi tentang apa yang harus dilakukan oleh GitHub setiap kali ada perubahan yang di-push ke repositori.

### Buat File Workflow
Buat direktori `.github/workflows` di dalam repositori project kita. Di dalam direktori tersebut, buat file baru bernama `laravel-test.yml`. Gunakan ekstensi `.yml` atau `.yaml` karena GitHub Actions menggunakan format YAML untuk file konfigurasi.

Tambahkan kode berikut ke dalam file `laravel-test.yml`:

```yaml
name: Laravel Test

on: [push]

jobs:
  laravel-tests:

    runs-on: ubuntu-latest

    steps:
    - name: Setup PHP
      uses: shivammathur/setup-php@v2
      with:
        php-version: '8.4'
        extensions: dom, curl, libxml, mbstring, zip, pcntl, pdo, sqlite, pdo_sqlite, bcmath, soap, intl, gd, exif, iconv
        coverage: none

    - uses: actions/checkout@v4
    - name: Copy .env
      run: php -r "file_exists('.env') || copy('.env.example', '.env');"

    - name: Install Dependencies
      run: composer install -q --no-ansi --no-interaction --no-scripts --no-progress --prefer-dist

    - name: Generate key
      run: php artisan key:generate

    - name: Directory Permissions
      run: chmod -R 777 storage bootstrap/cache

    - name: Create Database
      run: |
        mkdir -p database
        touch database/database.sqlite

    - name: Execute tests (Unit and Feature tests) via PHPUnit/Pest
      env:
        DB_CONNECTION: sqlite
        DB_DATABASE: database/database.sqlite
      run: php artisan test
```

### Penjelasan File Workflow:
- **`on: [push]`**: Setiap kali ada perubahan yang di-push ke repositori, workflow akan berjalan.
- **`jobs: laravel-tests`**: Definisikan job bernama `laravel-tests` yang akan dijalankan di Ubuntu (runs-on: ubuntu-latest).
- **Setup PHP**: Menginstal PHP versi 8.3 beserta beberapa ekstensi yang diperlukan untuk Laravel.
- **Install Dependencies**: Menginstal semua dependensi menggunakan Composer.
- **Generate Key**: Menjalankan perintah artisan untuk menghasilkan kunci aplikasi.
- **Create Database**: Membuat file database SQLite untuk pengujian.
- **Execute Tests**: Menjalankan pengujian unit dan fitur menggunakan PHPUnit atau Pest.

### Simpan dan Push Workflow
Setelah kita menambahkan file workflow, tambahkan dan commit perubahan:

```bash
git add .github/workflows/laravel-test.yml
git commit -m "menambahkan file workflow github action"
```

Push perubahan ke GitHub:

```bash
git push origin main
```

Setiap kali kita push perubahan ke repositori, GitHub Actions akan menjalankan workflow ini secara otomatis.

---

## Step 4: Melihat Hasil Workflow{#step-4-melihat-hasil-workflow}

Setelah push kode ke GitHub, kita bisa melihat status workflow di halaman repositori GitHub kita. 

1. Buka repositori di GitHub.
2. Klik tab **Actions** di bagian atas halaman repositori.
	![Akses github action page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/git/github-action-laravel/1-akses-github-action-page.png)
3. Di halaman **Actions**, Anda akan melihat daftar workflow yang telah dijalankan. Jika workflow berjalan dengan sukses, kita akan melihat tanda centang hijau di sebelahnya. Jika terjadi kesalahan, kita akan melihat tanda silang merah.

![akses halaman workflow github action](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/git/github-action-laravel/2-view-all-workflow.png)

![akses detail workflow github action](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/git/github-action-laravel/3-view-detail-workflow.png)

GitHub menyediakan detail lengkap dari setiap langkah yang dijalankan di dalam workflow. kita bisa melihat log dari setiap langkah untuk mengetahui apakah ada kesalahan atau tidak.

![detail langkah-langkah dalam workflow](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/git/github-action-laravel/4-testing-success.png)

---

## Conclusion{#conclusion}

Dengan mengikuti tutorial ini, kita telah mempelajari cara mengatur GitHub Actions untuk menjalankan pengujian otomatis di aplikasi Laravel. Penggunaan CI/CD seperti ini sangat membantu untuk memastikan bahwa setiap perubahan yang kita buat telah diuji dan tidak akan menyebabkan kerusakan pada sistem secara keseluruhan. 

Dengan workflow yang sudah kita buat, pengujian aplikasi Laravel kita akan berjalan secara otomatis setiap kali ada perubahan yang di-push ke repositori. Ini memastikan bahwa aplikasi selalu dalam kondisi baik sebelum di-deploy ke server produksi.

Jadi, apakah Anda sudah siap untuk mulai menggunakan GitHub Actions di project Laravel Anda?