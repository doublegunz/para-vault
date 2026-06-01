---
title: "Tutorial Nuxt 4 Auth #3: Membuat Layouts di Nuxt"
slug: "tutorial-nuxt-4-auth-3-membuat-layouts-di-nuxt"
category: "Nuxt"
date: "2026-02-19"
status: "published"
---

Pada [bagian kedua](#), kita sudah menginstall dan mengkonfigurasi `@sidebase/nuxt-auth`. Sekarang kita akan membuat layouts yang akan membungkus halaman-halaman di aplikasi kita. Layout memungkinkan kita mendefinisikan struktur tampilan yang berbeda untuk halaman publik dan halaman yang memerlukan authentication.

## Overview {#overview}

Pada bagian ketiga ini, kita akan membuat dua layout: `default` layout untuk halaman yang memerlukan authentication (seperti dashboard) dan `auth` layout untuk halaman publik (seperti login dan register).

### Apa yang akan kamu pelajari

1. Membuat default layout dengan navbar
2. Membuat auth layout untuk halaman login dan register
3. Menggunakan layout di halaman

## Step 1: Membuat Default Layout {#step-1-membuat-default-layout}

Default layout akan digunakan untuk halaman-halaman yang memerlukan authentication seperti dashboard. Layout ini akan menampilkan navbar dengan informasi user dan tombol logout.

Buat file `app/layouts/default.vue`:

```javascript
<template>
  <div class="min-h-screen bg-gray-100">
    <!-- Navbar -->
    <nav class="bg-white shadow-sm">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16 items-center">
          <!-- Logo / Brand -->
          <div class="flex items-center">
            <NuxtLink to="/dashboard" class="text-xl font-bold text-blue-600">
              NuxtAuth
            </NuxtLink>
          </div>

          <!-- User Menu -->
          <div class="flex items-center space-x-4">
            <span v-if="data" class="text-sm text-gray-700">
              Halo, <span class="font-semibold">{{ data.name }}</span>
            </span>
            <button
              @click="handleLogout"
              class="px-4 py-2 text-sm text-red-600 hover:bg-red-50 rounded-lg transition"
            >
              Logout
            </button>
          </div>
        </div>
      </div>
    </nav>

    <!-- Page Content -->
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <slot />
    </main>
  </div>
</template>

<script setup>
const { data, signOut } = useAuth()

const handleLogout = async () => {
  await signOut({ callbackUrl: '/login' })
}
</script>
```

**Penjelasan Kode:**

- **`useAuth()`**: Composable dari `@sidebase/nuxt-auth` yang menyediakan akses ke data session (`data`), status authentication, dan method seperti `signOut`.
- **`data`**: Berisi data user yang didapatkan dari endpoint `getSession` (`/profile`). Objek ini berisi `name`, `email`, `id`, dan `created_at`.
- **`signOut()`**: Method untuk melakukan logout. Karena kita set `signOut: false` di konfigurasi endpoint, method ini akan menghapus token di sisi client dan redirect ke halaman login.
- **`<slot />`**: Tempat di mana konten halaman akan di-render.

## Step 2: Membuat Auth Layout {#step-2-membuat-auth-layout}

Auth layout akan digunakan untuk halaman-halaman publik seperti login dan register. Layout ini lebih sederhana karena tidak memerlukan navbar.

Buat file `app/layouts/auth.vue`:

```javascript
<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-100">
    <div class="w-full max-w-md px-4">
      <!-- Logo -->
      <div class="text-center mb-8">
        <h1 class="text-3xl font-bold text-blue-600">NuxtAuth</h1>
        <p class="text-gray-500 mt-2">Sistem Authentication dengan Nuxt 3</p>
      </div>

      <!-- Page Content -->
      <slot />
    </div>
  </div>
</template>
```

Layout ini menampilkan logo di tengah halaman dengan area konten di bawahnya. Halaman login dan register akan di-render di area `<slot />`.

## Step 3: Menggunakan Layout di Halaman {#step-3-menggunakan-layout-di-halaman}

Secara default, semua halaman di Nuxt 3 menggunakan layout `default`. Untuk menggunakan layout yang berbeda, kita gunakan `definePageMeta`. Sebagai contoh, kita update halaman `app/pages/index.vue` untuk redirect ke dashboard:

```javascript
<template>
  <div></div>
</template>

<script setup>
definePageMeta({
  auth: {
    unauthenticatedOnly: false,
  },
})

navigateTo('/dashboard')
</script>
```

Nantinya di Part 4 dan Part 5, halaman register dan login akan menggunakan auth layout seperti ini:

```javascript
<script setup>
definePageMeta({
  layout: 'auth',
  auth: {
    unauthenticatedOnly: true,
    navigateAuthenticatedTo: '/dashboard',
  },
})
</script>
```

**Penjelasan `definePageMeta`:**

- **`layout: 'auth'`**: Menggunakan layout `auth` (bukan `default`).
- **`auth.unauthenticatedOnly: true`**: Halaman ini hanya bisa diakses oleh user yang belum login. Jika user sudah login, akan di-redirect.
- **`auth.navigateAuthenticatedTo`**: URL tujuan redirect jika user sudah login.

## Penutup {#penutup}

Pada bagian ketiga ini kita telah berhasil membuat dua layout: `default` layout untuk halaman authenticated dan `auth` layout untuk halaman publik. Layout ini akan digunakan di halaman-halaman yang akan kita buat di bagian selanjutnya.

**Selanjutnya:** Pada [Tutorial Nuxt 3 Auth #4](#), kita akan membuat halaman register untuk mendaftarkan user baru.