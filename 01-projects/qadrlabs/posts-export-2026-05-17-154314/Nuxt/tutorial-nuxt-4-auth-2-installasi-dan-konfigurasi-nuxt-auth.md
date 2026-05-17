---
title: "Tutorial Nuxt 4 Auth #2: Installasi dan Konfigurasi Nuxt Auth"
slug: "tutorial-nuxt-4-auth-2-installasi-dan-konfigurasi-nuxt-auth"
category: "Nuxt"
date: "2026-02-19"
status: "published"
---

Pada [bagian pertama](#), kita sudah berhasil membuat project Nuxt 3 dan melakukan konfigurasi awal. Sekarang kita akan menginstall dan mengkonfigurasi module `@sidebase/nuxt-auth` yang akan menangani seluruh proses authentication di aplikasi kita.

`@sidebase/nuxt-auth` adalah module authentication yang dibangun khusus untuk Nuxt 3. Module ini menyediakan **Local Provider** yang sangat cocok untuk aplikasi yang menggunakan backend terpisah dengan credential-based authentication (email + password) seperti REST API Go + Gin yang sudah kita buat.

## Overview {#overview}

Pada bagian kedua ini, kita akan menginstall module `@sidebase/nuxt-auth`, mengkonfigurasi Local Provider agar terhubung dengan REST API Go + Gin, dan memahami bagaimana module ini mengelola token JWT secara otomatis.

### Apa yang akan kamu pelajari

1. Installasi module `@sidebase/nuxt-auth`
2. Konfigurasi Local Provider di `nuxt.config.ts`
3. Memahami endpoint mapping antara Nuxt Auth dan REST API
4. Konfigurasi token management

## Step 1: Installasi @sidebase/nuxt-auth {#step-1-installasi-sidebase-nuxt-auth}

Buka terminal di direktori project, lalu run command berikut ini untuk menginstall module:

```bash
npm install @sidebase/nuxt-auth
```

Kita tunggu sampai proses instalasi selesai.

## Step 2: Konfigurasi Local Provider {#step-2-konfigurasi-local-provider}

Setelah module terinstall, kita perlu mengkonfigurasi `@sidebase/nuxt-auth` dengan Local Provider agar terhubung dengan REST API Go + Gin kita. Buka file `nuxt.config.ts` lalu update menjadi seperti berikut:

```ts
// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2024-11-01',
  devtools: { enabled: true },

  modules: [
    '@nuxtjs/tailwindcss',
    '@sidebase/nuxt-auth',
  ],

  auth: {
    baseURL: process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:8080/api/v1',
    provider: {
      type: 'local',
      endpoints: {
        signIn: { path: '/auth/login', method: 'post' },
        signUp: { path: '/auth/register', method: 'post' },
        getSession: { path: '/profile', method: 'get' },
        signOut: false,
      },
      pages: {
        login: '/login',
      },
      token: {
        signInResponseTokenPointer: '/token',
        type: 'Bearer',
        cookieName: 'auth.token',
        headerName: 'Authorization',
        maxAgeInSeconds: 86400, // 24 jam (sesuai JWT expiry di backend)
        sameSiteAttribute: 'lax',
      },
      session: {
        dataType: {
          id: 'number',
          name: 'string',
          email: 'string',
          created_at: 'string',
        },
        dataResponsePointer: '/user',
      },
    },
    globalAppMiddleware: {
      isEnabled: true,
    },
  },

  runtimeConfig: {
    public: {
      apiBase: process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:8080/api/v1',
    },
  },
})
```

## Penjelasan Konfigurasi {#penjelasan-konfigurasi}

Konfigurasi di atas cukup panjang, mari kita bahas setiap bagiannya secara detail.

### Endpoints

```ts
endpoints: {
  signIn: { path: '/auth/login', method: 'post' },
  signUp: { path: '/auth/register', method: 'post' },
  getSession: { path: '/profile', method: 'get' },
  signOut: false,
},
```

Konfigurasi `endpoints` memetakan fungsi Nuxt Auth ke endpoint REST API kita:

- **`signIn`**: Dipanggil ketika user login. Dimap ke `POST /api/v1/auth/login`.
- **`signUp`**: Dipanggil ketika user register. Dimap ke `POST /api/v1/auth/register`.
- **`getSession`**: Dipanggil untuk mendapatkan data user yang sedang login. Dimap ke `GET /api/v1/profile`.
- **`signOut`**: Diset `false` karena REST API kita tidak memiliki endpoint logout. Proses logout akan ditangani di sisi client dengan menghapus token.

### Token

```ts
token: {
  signInResponseTokenPointer: '/token',
  type: 'Bearer',
  headerName: 'Authorization',
  maxAgeInSeconds: 86400,
},
```

Konfigurasi `token` mengatur bagaimana Nuxt Auth mengelola JWT token:

- **`signInResponseTokenPointer`**: Menunjukkan lokasi token di response JSON. REST API kita mengembalikan `{ "token": "eyJ..." }`, maka pointer-nya adalah `/token`.
- **`type`**: Tipe token yang akan dikirim di header. Diset `Bearer` sesuai standar JWT.
- **`headerName`**: Nama header untuk mengirim token. Diset `Authorization` sesuai konfigurasi middleware di backend.
- **`maxAgeInSeconds`**: Masa berlaku token di sisi client, yaitu 86400 detik (24 jam), disesuaikan dengan expiry JWT yang kita set di backend Go.

### Session

```ts
session: {
  dataType: {
    id: 'number',
    name: 'string',
    email: 'string',
    created_at: 'string',
  },
  dataResponsePointer: '/user',
},
```

Konfigurasi `session` mengatur bagaimana data user disimpan:

- **`dataType`**: Mendefinisikan tipe data untuk TypeScript autocompletion.
- **`dataResponsePointer`**: Menunjukkan lokasi data user di response JSON. Endpoint `/profile` kita mengembalikan `{ "user": { ... } }`, maka pointer-nya adalah `/user`.

### Global Middleware

```ts
globalAppMiddleware: {
  isEnabled: true,
},
```

Mengaktifkan middleware authentication secara global. Artinya semua halaman secara default memerlukan authentication, kecuali halaman yang secara eksplisit kita tandai sebagai publik.

## Step 3: Verifikasi Konfigurasi {#step-3-verifikasi-konfigurasi}

Untuk memastikan konfigurasi sudah benar, jalankan development server:

```bash
npm run dev
```

Jika tidak ada error di terminal, berarti konfigurasi `@sidebase/nuxt-auth` sudah benar. Saat mengakses `http://localhost:3000`, kita akan otomatis di-redirect ke `/login` karena global middleware sudah aktif dan kita belum authenticated. Halaman login masih kosong karena akan kita buat di Part 5.

## Penutup {#penutup}

Pada bagian kedua ini kita telah berhasil menginstall dan mengkonfigurasi `@sidebase/nuxt-auth` dengan Local Provider. Module ini sekarang terhubung dengan REST API Go + Gin dan siap menangani proses authentication.

**Selanjutnya:** Pada [Tutorial Nuxt 3 Auth #3](#), kita akan membuat layouts untuk memisahkan tampilan halaman publik (login, register) dengan halaman yang memerlukan authentication (dashboard).