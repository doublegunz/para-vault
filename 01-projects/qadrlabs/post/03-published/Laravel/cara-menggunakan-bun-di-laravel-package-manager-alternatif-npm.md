---
title: "Cara Menggunakan Bun di Laravel: Package Manager Alternatif NPM"
slug: "cara-menggunakan-bun-di-laravel-package-manager-alternatif-npm"
category: "Laravel"
date: "2025-12-12"
status: "published"
---

Halo, setelah kita bahas [Bun](https://qadrlabs.com/post/mengenal-bun-sebuah-all-in-one-javascript-runtime-yang-cepat) pada artikel sebelumnya, sekarang kita akan coba gunakan bun dalam project yang dibangun menggunakan framework laravel. Umumnya ketika kita mengembangkan software menggunakan laravel, kita gunakan NPM sebagai package manager. Pada artikel ini kita akan coba gunakan Bun sebagai package manager untuk menginstall dependensi, run vite deveploment server dan juga build assets frontend.

## Overview {#overview}

Pada tutorial ini kita akan coba gunakan bun sebagai package manager yang menangani sisi frontend. Beberapa use case yang akan kita coba pada tutorial ini adalah sebagai berikut.

1. Install Dependensi Project menggunakan Bun
2. Run Vite Development Server
3. Build Assets Frontend
4. Menggunakan `bunx`  `dev` Script di `composer.json`

Karena kita perlu sisi frontend yang akan diproses oleh Bun, kita akan coba gunakan salah satu laravel starter kit, yaitu [React Starter Kit](https://qadrlabs.com/post/tutorial-crud-laravel-12-with-react-starter-kit).

Karena proses install bun, sudah kita bahas pada artikel sebelumnya, jadi pada artikel sekarang kita tidak bahas lagi. Apabila teman-teman belum install Bun, bisa cek bagian [Instalasi dan Setup Bun](https://qadrlabs.com/post/mengenal-bun-sebuah-all-in-one-javascript-runtime-yang-cepat#instalasi-dan-setup) pada artikel sebelumnya. Selain itu pastikan juga, teman-teman sudah menginstall Laravel Installer.

Karena kita ingin tahu kecepatan menggunakan bun saat build assets, kita akan coba setup dua project menggunakan laravel. Yang pertama kita akan gunakan Bun untuk package manager dengan nama `bun-laravel` dan yang kedua kita akan gunakan NPM dengan nama `npm-laravel`. Kita gunakan react starter kit untuk kedua project.

##  Setup Project {#setup-project}

Pertama kita akan coba setup dua project menggunakan laravel. Yang pertama kita akan gunakan Bun untuk package manager dengan nama `bun-laravel` dan yang kedua kita akan gunakan NPM dengan nama `npm-laravel`. Kita gunakan react starter kit untuk kedua project.

Sekarang kita setup dulu project pertama untuk Bun. Buka terminal lalu run command berikut ini.

```
laravel new bun-laravel
```

Output yang ditampilkan di terminal:

```
laravel new bun-laravel

   _                               _
  | |                             | |
  | |     __ _ _ __ __ ___   _____| |
  | |    / _` |  __/ _` \ \ / / _ \ |
  | |___| (_| | | | (_| |\ V /  __/ |
  |______\__,_|_|  \__,_| \_/ \___|_|


 ┌ Which starter kit would you like to install? ────────────────┐
 │ › ● None                                                     │
 │   ○ React                                                    │
 │   ○ Vue                                                      │
 │   ○ Livewire                                                 │
 └──────────────────────────────────────────────────────────────┘
```

Seperti yang sudah kita sebutkan sebelumnya kita gunakan React starter kit, jadi kita pilih opsi `React` untuk starter kit, lalu `enter` untuk melanjutkan.

```
➜  laravel laravel new bun-laravel

   _                               _
  | |                             | |
  | |     __ _ _ __ __ ___   _____| |
  | |    / _` |  __/ _` \ \ / / _ \ |
  | |___| (_| | | | (_| |\ V /  __/ |
  |______\__,_|_|  \__,_| \_/ \___|_|


 ┌ Which starter kit would you like to install? ────────────────┐
 │ React                                                        │
 └──────────────────────────────────────────────────────────────┘

 ┌ Which authentication provider do you prefer? ────────────────┐
 │   ○ Laravel's built-in authentication                        │
 │   ○ WorkOS (Requires WorkOS account)                         │
 │ › ● No authentication scaffolding                            │
 └──────────────────────────────────────────────────────────────┘
```

Untuk prompt authentication provider, kita pilih `No authentication scaffolding`, lalu `enter` untuk melanjutkan.

```
laravel new bun-laravel

   _                               _
  | |                             | |
  | |     __ _ _ __ __ ___   _____| |
  | |    / _` |  __/ _` \ \ / / _ \ |
  | |___| (_| | | | (_| |\ V /  __/ |
  |______\__,_|_|  \__,_| \_/ \___|_|


 ┌ Which starter kit would you like to install? ────────────────┐
 │ React                                                        │
 └──────────────────────────────────────────────────────────────┘

 ┌ Which authentication provider do you prefer? ────────────────┐
 │ No authentication scaffolding                                │
 └──────────────────────────────────────────────────────────────┘

 ┌ Which testing framework do you prefer? ──────────────────────┐
 │ › ● Pest                                                     │
 │   ○ PHPUnit                                                  │
 └──────────────────────────────────────────────────────────────┘
```

Kemudian kita pilih `pest` sebagai testing framework, lalu tekan `enter` untuk melanjutkan.

```
➜  laravel laravel new bun-laravel

   _                               _
  | |                             | |
  | |     __ _ _ __ __ ___   _____| |
  | |    / _` |  __/ _` \ \ / / _ \ |
  | |___| (_| | | | (_| |\ V /  __/ |
  |______\__,_|_|  \__,_| \_/ \___|_|


 ┌ Which starter kit would you like to install? ────────────────┐
 │ React                                                        │
 └──────────────────────────────────────────────────────────────┘

 ┌ Which authentication provider do you prefer? ────────────────┐
 │ No authentication scaffolding                                │
 └──────────────────────────────────────────────────────────────┘

 ┌ Which testing framework do you prefer? ──────────────────────┐
 │ Pest                                                         │
 └──────────────────────────────────────────────────────────────┘

 ┌ Do you want to install Laravel Boost to improve AI assisted coding? ┐
 │ ○ Yes / ● No                                                        │
 └─────────────────────────────────────────────────────────────────────┘

```

Selanjutnya untuk install Laravel Boost, kita pilih `No` lalu tekan `enter` untuk melanjutkan. Setelah itu kita tunggu sampai tampil prompt selanjutnya.

Apabila tampil prompt untuk remove VCS kita ketik `Y`, lalu `enter` untuk melanjutkan.

```
Do you want to remove the existing VCS (.git, .svn..) history? [Y,n]? Y
```

Karena kita akan coba menggunakan `bun`, ketika tampil apakah kita akan run `npm install` kita pilih `No`.

```
 ┌ Would you like to run npm install and npm … ───┐
 │ ○ Yes / ● No                                                 │
 └──────────────────────────────────────────────────────────────┘
```

Project pertama sudah kita setup, selanjutnya kita buka terminal baru lalu run command berikut.

```
laravel new npm-laravel
```

Untuk opsi prompt kita samakan seperti project pertama:

```
laravel new npm-laravel

   _                               _
  | |                             | |
  | |     __ _ _ __ __ ___   _____| |
  | |    / _` |  __/ _` \ \ / / _ \ |
  | |___| (_| | | | (_| |\ V /  __/ |
  |______\__,_|_|  \__,_| \_/ \___|_|


 ┌ Which starter kit would you like to install? ────────────────┐
 │ React                                                        │
 └──────────────────────────────────────────────────────────────┘

 ┌ Which authentication provider do you prefer? ────────────────┐
 │ No authentication scaffolding                                │
 └──────────────────────────────────────────────────────────────┘

 ┌ Which testing framework do you prefer? ──────────────────────┐
 │ Pest                                                         │
 └──────────────────────────────────────────────────────────────┘

 ┌ Do you want to install Laravel Boost to improve AI assisted coding? ┐
 │ No                                                                  │
 └─────────────────────────────────────────────────────────────────────┘
```

Untuk prompt install dependensi pun sementara kita samakan.

```
 ┌ Would you like to run npm install and npm… ────┐
 │ No                                                           │
 └──────────────────────────────────────────────────────────────┘
```

## Menggunakan Bun Untuk Install Dependensi {#install-dependencies-with-bun}

Sekarang kita kembali ke terminal untuk project `bun-laravel`, lalu masuk ke direktori project.

```
cd bun-laravel
```

Selanjutnya kita coba run `ls`:

```
➜  bun-laravel ls
app               config            phpunit.xml       storage
artisan           database          public            tests
bootstrap         eslint.config.js  README.md         tsconfig.json
composer.json     package-lock.json resources         vendor
composer.lock     package.json      routes            vite.config.ts
```

Bisa kita lihat pada output yang ditampilkan pada terminal, secara default di direktori project terdapat `package-lock.json`. Untuk migrasi dari NPM ke bun kita perlu menghapus file lock yang digunakan NPM. Untuk menghapus file lock, pada terminal kita run command berikut ini:

```
rm package-lock.json
```

Sebagai catatan, apabila kita menggunakan `yarn` atau `pnpm`, kita juga perlu menghapus file lock untuk package manager tersebut.

Setelah menghapus file lock lama, kita bisa memulai instalasi dependensi menggunakan Bun. Untuk install dependensi menggunakan bun, buka kembali terminal lalu run command berikut.

```
bun install
```

Output yang ditampilkan.

```
bun install v1.3.4 (5eb2145b)

+ @eslint/js@9.39.1
+ @laravel/vite-plugin-wayfinder@0.1.7
+ @types/node@22.19.2 (v25.0.1 available)
+ babel-plugin-react-compiler@1.0.0
+ eslint@9.39.1
+ eslint-config-prettier@10.1.8
+ eslint-plugin-react@7.37.5
+ eslint-plugin-react-hooks@5.2.0 (v7.0.1 available)
+ prettier@3.7.4
+ prettier-plugin-organize-imports@4.3.0
+ prettier-plugin-tailwindcss@0.6.14 (v0.7.2 available)
+ typescript-eslint@8.49.0
+ @inertiajs/react@2.3.0
+ @tailwindcss/vite@4.1.18
+ @types/react@19.2.7
+ @types/react-dom@19.2.3
+ @vitejs/plugin-react@5.1.2
+ class-variance-authority@0.7.1
+ clsx@2.1.1
+ concurrently@9.2.1
+ globals@15.15.0 (v16.5.0 available)
+ laravel-vite-plugin@2.0.1
+ react@19.2.3
+ react-dom@19.2.3
+ tailwind-merge@3.4.0
+ tailwindcss@4.1.18
+ typescript@5.9.3
+ vite@7.2.7

343 packages installed [13.54s]
```

Pada saat command tersebut dieksekusi, Bun akan secara otomatis membaca file `package.json` dan menginstal semua dependensi. Setelah proses install selesai, terdapat file baru `bun.lock`.

Sebagai perbandingan, kita coba buka terminal project `npm-laravel` dan pindah ke direktori project menggunakan command:

```
cd npm-laravel
```

Selanjutnya kita coba install dependensi dengan run command:

```
npm install
```

Output yang ditampilkan:

```
npm install

added 368 packages, and audited 369 packages in 5s

140 packages are looking for funding
  run `npm fund` for details

2 moderate severity vulnerabilities

To address all issues, run:
  npm audit fix

Run `npm audit` for details.
```

Pada proses install ini Bun selesai dengan waktu 13.54 detik dan npm selesai dengan waktu 5 detik.

## Run Vite Development Server Menggunakan Bun {#run-dev-server-with-bun}

Selain untuk menginstall dependensi, kita juga bisa run vite deveploment server. Untuk menjalankan vite develoment server, kita run command berikut:

```
bun run dev
```

Output yang ditampilkan:

```
8:19:35 AM [vite] (client) info: Types generated for actions, routes, form variants
  Plugin: @laravel/vite-plugin-wayfinder

  VITE v7.2.7  ready in 2218 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  press h + enter to show help

  LARAVEL v12.42.0  plugin v2.0.1

  ➜  APP_URL: http://localhost:8000

```



Kita stop vite development server dengan menekan `CTRL` + `c`.

Sebagai perbandingan, kita kembali buka terminal project `npm-laravel`, lalu kita run vite development server menggunakan command:

```
npm run dev
```

Output yang ditampilkan:

```
npm run dev

> dev
> vite

8:52:38 PM [vite] (client) info: Types generated for actions, routes, form variants
  Plugin: @laravel/vite-plugin-wayfinder

  VITE v7.0.6  ready in 2054 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  press h + enter to show help

  LARAVEL v12.42.0  plugin v2.0.0

  ➜  APP_URL: http://localhost:8000


```

Saat run vite development server, bun ready di 2218 detik dan npm ready di 2054 detik.

## Build Assets Frontend Menggunakan Bun {#build-assets-with-bun}

Selanjutnya kita coba build asset untuk production dengan run command berikut:

```
bun run build
```

Output yang ditampilkan:

```
➜  bun-laravel bun run build
$ vite build
vite v7.2.7 building client environment for production...
[plugin @laravel/vite-plugin-wayfinder] Types generated for actions, routes, form variants
✓ 779 modules transformed.
public/build/manifest.json                 0.74 kB │ gzip:   0.25 kB
public/build/assets/app-Dzxa7y8w.css      18.79 kB │ gzip:   4.55 kB
public/build/assets/welcome-CZSYV9ei.js   49.18 kB │ gzip:   9.37 kB
public/build/assets/app-rT9lqYFk.js      379.42 kB │ gzip: 124.30 kB
✓ built in 1.82s
```



Dan berikut output yang ditampilkan ketika menggunakan `npm`.

```
➜  npm-laravel npm run build

> build
> vite build

vite v7.0.6 building for production...
[plugin @laravel/vite-plugin-wayfinder] Types generated for actions, routes, form variants
✓ 775 modules transformed.
public/build/manifest.json                 0.72 kB │ gzip:   0.25 kB
public/build/assets/app-CnMpbn42.css      18.83 kB │ gzip:   4.58 kB
public/build/assets/welcome-d-yLtohD.js   49.43 kB │ gzip:   9.55 kB
public/build/assets/app-BTeZWzrT.js      362.96 kB │ gzip: 118.29 kB
✓ built in 1.71s
```

Ketika build assets menggunakan bun selesai dalam waktu 1.82 detik dan menggunakan npm selesai dalam waktu 1.71 detik.

## Menggunakan bunx command di Dev Script Composer {#dev-script-with-bunx}

Ketika kita ingin run beberapa command sekaligus, kita gunakan command [composer run dev](https://qadrlabs.com/post/cara-menggunakan-composer-run-dev-di-laravel-11) di mana di dalam `dev` script ini secara default menggunakan NPX (Node Package eXecute). Karena di artikel ini kita menggunakan bun, kita akan gunakan **bunx**. 

Bunx adalah alias untuk bun x. bunx CLI akan diinstal secara otomatis saat kita menginstal bun. bunx dapat kita gunakan untuk menginstal dan menjalankan paket dari npm secara otomatis. bunx ini merupakan versi Bun dari npx atau yarn dlx.

Sekarang kita akan ganti npx di `dev` script composer. Buka file `composer.json`, lalu temukan `dev` script berikut ini.

```
        "dev": [
            "Composer\\Config::disableProcessTimeout",
            "npx concurrently -c \"#93c5fd,#c4b5fd,#fb7185,#fdba74\" \"php artisan serve\" \"php artisan queue:listen --tries=1\" \"php artisan pail --timeout=0\" \"npm run dev\" --names=server,queue,logs,vite --kill-others"
        ],
```

Selanjutnya kita ganti `npx` dan kita gunakan `bunx` dan `bun` di `dev` script.

```
        "dev": [
            "Composer\\Config::disableProcessTimeout",
            "bunx concurrently -c \"#93c5fd,#c4b5fd,#fb7185,#fdba74\" \"php artisan serve\" \"php artisan queue:listen --tries=1\" \"php artisan pail --timeout=0\" \"bun run dev\" --names=server,queue,logs,vite --kill-others"
        ],
```

Selanjutnya kita uji coba dengan run command:

```
composer run dev
```

Dan berikut output yang ditampilkan di terminal:

```
➜  bun-laravel composer run dev
> Composer\Config::disableProcessTimeout
> bunx concurrently -c "#93c5fd,#c4b5fd,#fb7185,#fdba74" "php artisan serve" "php artisan queue:listen --tries=1" "php artisan pail --timeout=0" "bun run dev" --names=server,queue,logs,vite --kill-others
[vite] $ vite
[queue]
[queue]    INFO  Processing jobs from the [default] queue.
[queue]
[logs]
[logs]    INFO  Tailing application logs.                        Press Ctrl+C to exit
[logs]                                                Use -v|-vv to show more details
[vite] 9:40:30 AM [vite] (client) info: Types generated for actions, routes, form variants
[vite]   Plugin: @laravel/vite-plugin-wayfinder
[vite]
[vite]   VITE v7.2.7  ready in 611 ms
[vite]
[vite]   ➜  Local:   http://localhost:5173/
[vite]   ➜  Network: use --host to expose
[vite]
[vite]   LARAVEL v12.42.0  plugin v2.0.1
[vite]
[vite]   ➜  APP_URL: http://localhost:8000
[server]
[server]    INFO  Server running on [http://127.0.0.1:8000].
[server]
[server]   Press Ctrl+C to stop the server
[server]

```



## Penutup {#penutup}

Pada tutorial ini kita sudah berhasil menggunakan Bun sebagai package manager untuk project Laravel dengan React starter kit. Dari percobaan yang dilakukan dengan konfigurasi yang sama, berikut ringkasan perbandingan performa antara Bun dan NPM:

| Proses                | Bun    | NPM    |
| --------------------- | ------ | ------ |
| Install Dependensi    | 13.54s | 5s     |
| Vite Dev Server Ready | 2218ms | 2054ms |
| Build Assets          | 1.82s  | 1.71s  |

Hasil benchmark menunjukkan bahwa NPM memiliki performa yang lebih baik di semua skenario pengujian pada project Laravel dengan React starter kit ini. Hal ini berbeda dari ekspektasi umum bahwa Bun selalu lebih cepat. Perbedaan ini kemungkinan disebabkan oleh karakteristik JavaScriptCore engine yang memiliki cold start overhead lebih tinggi, serta ukuran project yang relatif kecil sehingga keunggulan Bun belum terlihat signifikan.

## Key Takeaways

**Migrasi dari NPM ke Bun cukup sederhana** — kita hanya perlu menghapus file `package-lock.json` terlebih dahulu, kemudian jalankan `bun install` untuk menginstall ulang semua dependensi. Bun akan membuat file `bun.lock` sebagai pengganti.

**Command yang digunakan mirip dengan NPM** — untuk menjalankan script, kita tetap menggunakan pola yang sama seperti `bun run dev` dan `bun run build`, sehingga kurva pembelajaran relatif rendah bagi developer yang sudah terbiasa dengan NPM.

**Performa bervariasi tergantung skala project** — pada project Laravel dengan React starter kit tanpa authentication, NPM menunjukkan performa yang lebih baik. Keunggulan Bun biasanya lebih terlihat pada project yang lebih besar dengan ratusan dependensi dan task komputasi yang lebih kompleks.

**bunx sebagai pengganti npx** — untuk menjalankan package secara langsung tanpa instalasi global, kita bisa menggunakan `bunx` yang merupakan equivalent dari `npx` di ekosistem NPM.

**Integrasi dengan composer dev script** — kita bisa dengan mudah mengintegrasikan Bun ke dalam workflow Laravel dengan mengganti `npx` menjadi `bunx` dan `npm run dev` menjadi `bun run dev` di file `composer.json`.

**Kapan sebaiknya mempertimbangkan Bun?** Meskipun hasil benchmark pada project ini menunjukkan NPM lebih cepat, Bun tetap menjadi alternatif yang layak jika Anda menginginkan all-in-one toolkit (runtime, package manager, bundler, test runner dalam satu executable), native TypeScript support tanpa konfigurasi tambahan, atau jika project Anda berkembang menjadi lebih besar di mana keunggulan Bun bisa lebih terasa.

### Referensi{#referensi}
Dokumentasi Resmi Bun tentang Runtime - https://bun.com/docs