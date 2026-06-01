---
title: "Tutorial Nuxt 4 Auth #1: Membuat Project Nuxt"
slug: "tutorial-nuxt-4-auth-1-membuat-project-nuxt"
category: "Nuxt"
date: "2026-02-19"
status: "published"
---

Pada seri tutorial sebelumnya, kita sudah berhasil membangun [REST API Authentication menggunakan Go dan Gin](https://qadrlabs.com/member/post/rest-api-authentication-dengan-go-dan-gin-part-1) framework. REST API tersebut menyediakan endpoint untuk register, login, dan get profile dengan JWT authentication. Sekarang saatnya kita membangun frontend-nya menggunakan **Nuxt**.

**Nuxt** adalah meta-framework berbasis Vue.js yang menyediakan fitur-fitur powerful seperti server-side rendering (SSR), auto-import, file-based routing, dan developer experience yang sangat baik. Dengan Nuxt, kita bisa membangun aplikasi web modern dengan cepat dan terstruktur.

> **Catatan:** Tutorial ini menggunakan **Nuxt 4** (versi terbaru saat panduan ini ditulis). Nuxt 4 memperkenalkan perubahan struktur folder di mana semua file aplikasi (`pages/`, `layouts/`, `components/`, `middleware/`) diletakkan di dalam folder `app/`. Jika kamu menggunakan Nuxt 3, struktur foldernya sedikit berbeda.

Seri tutorial ini terdiri dari 7 bagian:

1. **Membuat Project Nuxt** (bagian ini)
2. Installasi dan Konfigurasi Nuxt Auth
3. Membuat Layouts di Nuxt
4. Membuat Proses Register
5. Membuat Proses Login
6. Menampilkan User di Halaman Dashboard
7. Membuat Proses Logout

Setiap bagian akan membahas satu topik secara fokus dan detail, sehingga mudah diikuti langkah demi langkah.

## Overview {#overview}

Pada bagian pertama ini, kita akan membuat project Nuxt dari awal, memahami struktur folder yang dihasilkan, dan memastikan project berjalan dengan baik. Kita juga akan menginstall Tailwind CSS untuk styling dan melakukan konfigurasi awal yang dibutuhkan untuk bagian-bagian selanjutnya.

### Tech Stack

Berikut adalah teknologi yang digunakan dalam seri tutorial ini:

- **Backend:** Go (Golang) + Gin Framework
- **Database:** MySQL
- **Frontend:** Nuxt 4 (Vue.js Framework)
- **Styling:** Tailwind CSS v3
- **Authentication:** @sidebase/nuxt-auth v0.9+ (Local Provider)

### Apa yang akan kamu pelajari

1. Membuat project Nuxt baru
2. Memahami struktur folder Nuxt 4
3. Installasi dan konfigurasi Tailwind CSS
4. Konfigurasi awal `nuxt.config.ts`
5. Menjalankan project di development mode

### Apa yang perlu kamu persiapkan

- Node.js versi 18 atau lebih baru sudah terinstall.
- Package manager (npm, yarn, atau pnpm).
- Text editor atau IDE (disarankan VS Code dengan extension Vue - Official).
- REST API Go + Gin yang sudah kita buat pada [tutorial sebelumnya](https://qadrlabs.com/member/post/rest-api-authentication-dengan-go-dan-gin-part-1) sudah berjalan di `http://localhost:8080`.

## Step 1: Membuat Project Nuxt {#step-1-membuat-project-nuxt}

Pada langkah pertama ini kita akan membuat project Nuxt baru. Buka terminal, lalu run command berikut ini.

```bash
npx nuxi@latest init nuxt-auth-app
```

Ketika tampil prompt, pilih opsi sesuai kebutuhan. Pada saat panduan ini diuji coba, kita memilih `npm` sebagai package manager.
```
$ npx nuxi@latest init nuxt-auth-app

        .d$b.
       i$$A$$L  .d$b
     .$$F` `$$L.$$A$$.
    j$$'    `4$$:` `$$.
   j$$'     .4$:    `$$.
  j$$`     .$$:      `4$L
 :$$:____.d$$:  _____.:$$:
 `4$$$$$$$$P` .i$$$$$$$$P`

┌  Welcome to Nuxt!
│
◇  Templates loaded
│
◆  Which template would you like to use?
│  ○ content – Content-driven website
│  ● minimal – Minimal setup for Nuxt 4 (recommended)  ← pilih ini
│  ○ module – Nuxt module
│  ○ ui – App using Nuxt UI
└


```

output:
```
◆  Which package manager would you like to use?
│  ● npm (current)
│  ○ pnpm
│  ○ yarn
│  ○ bun
│  ○ deno
└



```

output
```
◆  Initialize git repository?
│  ● Yes / ○ No
└


```


Kita tunggu sampai proses pembuatan project selesai.
```
└  ✨ Nuxt project has been created with the minimal template.

╭── 👉 Next steps ───────╮
│                        │
│   › cd nuxt-auth-app   │
│   › npm run dev        │
│                        │
╰────────────────────────╯

```

Setelah selesai, masuk ke direktori project:

```bash
cd nuxt-auth-app
```

Selanjutnya kita verifikasi project berjalan dengan baik dengan run command berikut ini:

```bash
npm run dev
```

Output yang ditampilkan seperti berikut:

```
$ npm run dev

> dev
> nuxt dev

[10:24:53 PM] │
●  Nuxt 4.3.1 (with Nitro 2.13.1, Vite 7.3.1 and Vue 3.5.28)
[10:24:53 PM] 
  ➜ Local:    http://localhost:3000/
  ➜ Network:  use --host to expose


```

Akses `http://localhost:3000` di browser. Jika tampil halaman welcome Nuxt, berarti project sudah berhasil dibuat dan berjalan dengan baik. Tekan `Ctrl + C` di terminal untuk menghentikan development server.

## Step 2: Memahami Struktur Folder {#step-2-memahami-struktur-folder}

Sebelum melanjutkan, penting untuk memahami struktur folder Nuxt 4 yang akan kita gunakan sepanjang tutorial ini.

Nuxt 4 memperkenalkan **`app/` directory** sebagai tempat utama untuk semua file aplikasi. Buat folder-folder berikut di dalam direktori `app/`:

```bash
mkdir -p app/pages app/layouts app/components app/middleware
```

Setelah selesai, struktur folder project kita akan terlihat seperti ini:

```
nuxt-auth-app/
├── app/
│   ├── app.vue          # Root component
│   ├── components/      # Komponen Vue yang reusable
│   ├── layouts/         # Layout templates untuk halaman
│   ├── middleware/      # Route middleware
│   └── pages/           # Halaman berbasis file routing
├── public/              # Aset statis
├── server/              # Server API routes (Nitro)
├── nuxt.config.ts       # Konfigurasi Nuxt
├── package.json         # Dependencies dan scripts
└── tsconfig.json        # Konfigurasi TypeScript
```

**Penjelasan Folder:**

- **`app/pages/`**: Setiap file `.vue` di folder ini otomatis menjadi route. Misalnya `app/pages/login.vue` menjadi route `/login`.
- **`app/layouts/`**: Template layout yang membungkus halaman. Berguna untuk mendefinisikan struktur umum seperti navbar dan footer.
- **`app/components/`**: Komponen Vue yang bisa digunakan ulang di berbagai halaman. Nuxt melakukan auto-import untuk semua komponen di folder ini.
- **`app/middleware/`**: Fungsi yang dijalankan sebelum navigasi ke halaman tertentu. Berguna untuk pengecekan authentication.
- **`app/app.vue`**: Root component yang menjadi entry point aplikasi.

## Step 3: Installasi Tailwind CSS {#step-3-installasi-tailwind-css}

Untuk styling, kita akan menggunakan Tailwind CSS melalui module `@nuxtjs/tailwindcss`. Run command berikut ini untuk menginstall module:

```bash
npx nuxi@latest module add tailwindcss
```

Command di atas otomatis menginstall package `@nuxtjs/tailwindcss` dan mendaftarkannya di `nuxt.config.ts`.

Selanjutnya kita buat file konfigurasi Tailwind CSS. Buat file `tailwind.config.js` di root project:

```js
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './app/components/**/*.{js,vue,ts}',
    './app/layouts/**/*.vue',
    './app/pages/**/*.vue',
    './app/app.vue',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

> **Penting:** Perhatikan prefix `./app/` pada setiap path. Ini diperlukan karena Nuxt 4 meletakkan semua file aplikasi di dalam folder `app/`.

## Step 4: Konfigurasi Awal nuxt.config.ts {#step-4-konfigurasi-awal-nuxt-config-ts}

Buka file `nuxt.config.ts` lalu update konfigurasinya menjadi seperti berikut:

```ts
// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2024-11-01',
  devtools: { enabled: true },

  modules: [
    '@nuxtjs/tailwindcss',
  ],

  runtimeConfig: {
    public: {
      apiBase: process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:8080/api/v1',
    },
  },
})
```

**Penjelasan Konfigurasi:**

- **`modules`**: Daftar module yang digunakan. Saat ini baru Tailwind CSS, nanti di Part 2 kita akan menambahkan `@sidebase/nuxt-auth`.
- **`runtimeConfig.public.apiBase`**: Base URL dari REST API Go + Gin yang sudah kita buat sebelumnya. Nilai ini bisa di-override melalui environment variable.

Selanjutnya buat file `.env` di root project:

```
NUXT_PUBLIC_API_BASE=http://localhost:8080/api/v1
```

## Step 5: Setup Halaman Awal {#step-5-setup-halaman-awal}

Sekarang kita update file `app/app.vue` untuk menggunakan sistem routing berbasis halaman. Buka file `app/app.vue` lalu ubah isinya menjadi:

```javascript
<template>
  <div>
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </div>
</template>
```

**Penjelasan Kode:**

- **`<NuxtLayout>`**: Komponen yang me-render layout aktif. Secara default menggunakan layout `default` dari folder `app/layouts/`.
- **`<NuxtPage>`**: Komponen yang me-render halaman aktif dari folder `app/pages/` berdasarkan URL saat ini.

Selanjutnya buat halaman index sebagai landing page. Buat file `app/pages/index.vue`:

```javascript
<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-100">
    <div class="text-center">
      <h1 class="text-4xl font-bold text-gray-800 mb-4">
        Nuxt 3 Auth Tutorial
      </h1>
      <p class="text-gray-600 mb-8">
        Sistem authentication dengan Nuxt 3 dan REST API Go + Gin
      </p>
      <div class="space-x-4">
        <NuxtLink
          to="/login"
          class="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
        >
          Login
        </NuxtLink>
        <NuxtLink
          to="/register"
          class="px-6 py-3 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition"
        >
          Register
        </NuxtLink>
      </div>
    </div>
  </div>
</template>
```

## Step 6: Verifikasi Project {#step-6-verifikasi-project}

Setelah semua konfigurasi selesai, kita jalankan kembali development server untuk memastikan semuanya berjalan dengan baik:

```bash
npm run dev
```

Akses `http://localhost:3000` di browser. Kita akan melihat halaman landing page dengan judul "Nuxt 3 Auth Tutorial" beserta tombol Login dan Register. Tombol-tombol tersebut belum berfungsi karena halaman login dan register akan kita buat di bagian selanjutnya.

## Penutup {#penutup}

Pada bagian pertama ini kita telah berhasil membuat project Nuxt 4, menginstall Tailwind CSS untuk styling, dan melakukan konfigurasi awal yang dibutuhkan. Poin penting yang perlu diingat adalah bahwa Nuxt 4 menggunakan folder `app/` sebagai direktori utama untuk semua file aplikasi. Project ini akan menjadi fondasi untuk bagian-bagian selanjutnya.

**Selanjutnya:** Pada [Tutorial Nuxt Auth #2](#), kita akan menginstall dan mengkonfigurasi module `@sidebase/nuxt-auth` untuk menangani authentication di Nuxt.