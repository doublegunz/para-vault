---
title: "Menggunakan bun di github action untuk project laravel"
slug: "menggunakan-bun-di-github-action-untuk-project-laravel"
category: "Laravel"
date: "2025-12-15"
status: "published"
---

Setelah saya menulis artikel [Cara menggunakan Bun di Laravel](https://qadrlabs.com/post/cara-menggunakan-bun-di-laravel-package-manager-alternatif-npm), project hasil belajar saya push ke github. Selang beberapa menit tampil notifikasi error di email `tests: All jobs have failed` dan setelah saya akses [halaman github action](https://github.com/qadrLabs/bun-laravel/actions/runs/20193338669) untuk repositori tersebut terkonfirmasi github action failed. Penyebabnya utamanya karena pada file workflow github action masih terdapat penggunaan npm, sedangkan file lock untuk npm sudah dihapus. Pada artikel tersebut memang kita belum sempat membahas tentang github action dan bagaimana cara setup bun di github action untuk project laravel. Oleh karena itu di artikel kali kita akan coba langsung untuk fix error dan setup bun di github action.

## Overview {#overview}
Pada tutorial kali ini kita akan coba gunakan bun di dalam github action untuk project laravel. Project laravel yang akan kita gunakan adalah project dari artikel sebelumnya, yaitu artikel [Cara menggunakan bun di laravel](https://qadrlabs.com/post/cara-menggunakan-bun-di-laravel-package-manager-alternatif-npm). Pada project tersebut secara default terdapat workflow untuk github action yang terdapat pada file `.github/workflows/lint.yml` dan `.github/workflows/tests.yml`. File `lint.yml` digunakan untuk mengecek kualitas / style kode dan file `tests.yml` digunakan untuk menjalankan test otomatis. Secara default kedua file workflow tersebut menggunakan `npm` dan pada artikel kali ini kita coba ganti  menjadi menggunakan `bun`.

Sebelum mengikut artikel ini pastikan:

1. Sudah mengikuti artikel sebelumnya, yaitu artikel Cara menggunakan bun di laravel. Karena project yang akan kita modifikasi adalah project dari artikel tersebut. Jadi pada artikel kali ini kita tidak akan membahas cara setup project laravel dan fokus untuk setup github action menggunakan bun.
2. Sudah membuat repositori project di github khusus untuk studi kasus kita.

Setelah semuanya siap, mari kita mulai setup github action menggunakan bun di project laravel.

## Modifikasi Workflow Testing {#modifikasi-workflow-testing}

Sekarang kita buka file `.github/workflows/tests.yml` di text editor. Pada file tersebut, penggunakan node js terdapat pada step:

1. Setup Node
2. Install Node Dependencies
3. Build Assets

Pada step-step tersebut kita ganti penggunaan npm menjadi menggunakan bun.

```
        [... code lainnya ]
     - name: Setup Bun
        uses: oven-sh/setup-bun@v2
        with:
          bun-version: latest

      - name: Install Node Dependencies
        run: bun install
        
        [... code lainnya ]
        
      - name: Build Assets
        run: bun run build
        
        [... code lainnya ]
```

Sehingga keseluruhan code pada file `.github/workflows/tests.yml` menjadi seperti baris kode berikut ini.

```
name: tests

on:
  push:
    branches:
      - develop
      - main
  pull_request:
    branches:
      - develop
      - main

jobs:
  ci:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: 8.4
          tools: composer:v2
          coverage: xdebug

      - name: Setup Bun
        uses: oven-sh/setup-bun@v2
        with:
          bun-version: latest

      - name: Install Node Dependencies
        run: bun install

      - name: Install Dependencies
        run: composer install --no-interaction --prefer-dist --optimize-autoloader

      - name: Copy Environment File
        run: cp .env.example .env

      - name: Generate Application Key
        run: php artisan key:generate

      - name: Build Assets
        run: bun run build

      - name: Tests
        run: ./vendor/bin/pest

```

Save kembali file `.github/workflows/tests.yml`.

**Perubahan dan fungsinya:**

- `Setup Node` dihapus dan diganti dengan `Setup Bun` menggunakan `oven-sh/setup-bun@v2` untuk meng-install dan men-expose binary Bun di runner Github Actions.
- `npm ci` diganti menjadi `bun install` untuk meng-install dependency dari `package.json` menggunakan package manager Bun.
- `npm run build` diganti menjadi `bun run build` karena bun mengeksekusi script di `package.json` melalui perintah `bun run <script`.

## Modifikasi Workflow Linter {#modifikasi-workflow-linter}

Selanjutnya kita buka file `.github/workflows/lint.yml`. Pada file tersebut penggunaan Node js atau npm terdapat pada step.

1. Install Dependencies
2. Format Frontend
3. Lint Frontend

Kita modifikasi file `.github/workflows/lint.yml` dan kita ubah penggunaan npm ke Bun seperti baris kode berikut

```
name: linter

on:
  push:
    branches:
      - develop
      - main
  pull_request:
    branches:
      - develop
      - main

permissions:
  contents: write

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.4'

      - name: Setup Bun
        uses: oven-sh/setup-bun@v2
        with:
          bun-version: latest

      - name: Install Dependencies
        run: |
          composer install -q --no-ansi --no-interaction --no-scripts --no-progress --prefer-dist
          bun install

      - name: Run Pint
        run: vendor/bin/pint

      - name: Format Frontend
        run: bun run format

      - name: Lint Frontend
        run: bun run lint

      # - name: Commit Changes
      #   uses: stefanzweifel/git-auto-commit-action@v5
      #   with:
      #     commit_message: fix code style
      #     commit_options: '--no-verify'
```

**Perubahan yang dilakukan**

- Menambahkan langkah `Setup Bun` dengan `oven-sh/setup-bun@v2` untuk meng‑install Bun di runner GitHub Actions dan men‑set binary‑nya ke `PATH`.
- Mengganti `npm install` menjadi `bun install` agar instalasi dependency frontend memakai package manager Bun.
- Mengganti `npm run format` dan `npm run lint` menjadi `bun run format` dan `bun run lint`, karena Bun mengeksekusi script di `package.json` menggunakan perintah `bun run <script>`.

## Uji Coba {#uji-coba}

Selanjutnya kita akan uji coba perubahan workflow github action di github. Untuk menguji coba kita tambahkan terlebih dahulu perubahan ke staging area.

```
git add .
```

Lalu kita commit perubahan.

```
git commit -m "Migrate CI workflows from npm to Bun for frontend dependency management and script execution."
```

Selanjutnya kita push perubahan.

```
git push origin main
```

**Keterangan:** karena tujuannya untuk melihat workflow bekerja, jadi pada artikel ini saya push langsung ke branch `main`.

Setelah kita push kita tunggu, apakah masih terdapat error di github action.

Dan hasilnya berjalan dengan baik, kita bisa lihat di laman berikut ini.

1. [Workflow tests](https://github.com/qadrLabs/bun-laravel/actions/runs/20220822291)

2. [Workflow lint](https://github.com/qadrLabs/bun-laravel/actions/runs/20220822295)



## Penutup {#penutup}

Pada artikel ini kita telah berhasil memperbaiki error GitHub Actions dan melakukan migrasi dari npm ke Bun untuk project Laravel. Proses migrasinya cukup sederhana karena hanya perlu memodifikasi dua file workflow, yaitu `tests.yml` dan `lint.yml`.

Beberapa poin penting yang dapat diambil dari artikel ini:

Pertama, untuk setup Bun di GitHub Actions kita menggunakan action `oven-sh/setup-bun@v2` yang akan menginstall Bun dan menambahkan binary-nya ke PATH runner. Kedua, perintah npm perlu disesuaikan ke sintaks Bun, di mana `npm ci` atau `npm install` diganti menjadi `bun install`, sedangkan `npm run <script>` diganti menjadi `bun run <script>`. Ketiga, struktur workflow secara keseluruhan tetap sama, yang berubah hanya bagian yang berkaitan dengan package manager JavaScript.

Dengan menggunakan Bun di GitHub Actions, kita mendapatkan konsistensi antara environment development lokal dan CI/CD pipeline. Selain itu, proses build dan instalasi dependency juga menjadi lebih cepat karena performa Bun yang lebih unggul dibandingkan npm.

Semoga artikel ini bermanfaat dan selamat mencoba!

## Referensi {#referensi}

[1](https://github.com/oven-sh/setup-bun) https://github.com/oven-sh/setup-bun

[2](https://github.com/marketplace/actions/setup-bun) https://github.com/marketplace/actions/setup-bun

[3](https://bun.sh/guides/runtime/cicd) https://bun.sh/guides/runtime/cicd