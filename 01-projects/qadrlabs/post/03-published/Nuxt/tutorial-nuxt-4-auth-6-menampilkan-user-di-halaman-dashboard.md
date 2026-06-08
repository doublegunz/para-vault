---
title: "Tutorial Nuxt 4 Auth #6: Menampilkan User di Halaman Dashboard"
slug: "tutorial-nuxt-4-auth-6-menampilkan-user-di-halaman-dashboard"
category: "Nuxt"
date: "2026-02-19"
status: "published"
---

Pada [bagian kelima](#), kita sudah membuat halaman login. Sekarang kita akan membuat halaman dashboard yang menampilkan data user yang sedang login. Halaman ini merupakan contoh **protected route** yang hanya bisa diakses oleh user yang sudah terautentikasi.

## Overview {#overview}

Pada bagian keenam ini, kita akan membuat halaman dashboard yang menampilkan informasi user dari session data. Kita juga akan memahami bagaimana `@sidebase/nuxt-auth` mengelola session dan bagaimana cara mengakses data user di berbagai komponen.

### Apa yang akan kamu pelajari

1. Membuat halaman dashboard (protected route)
2. Mengakses data user dari session
3. Menampilkan informasi user
4. Memahami alur getSession

## Step 1: Membuat Halaman Dashboard {#step-1-membuat-halaman-dashboard}

Buat file `app/pages/dashboard.vue` lalu tambahkan kode berikut:

```javascript
<template>
  <div>
    <h1 class="text-2xl font-bold text-gray-800 mb-6">Dashboard</h1>

    <!-- Loading State -->
    <div v-if="status === 'loading'" class="text-gray-500">
      Memuat data...
    </div>

    <!-- User Info Card -->
    <div v-else-if="data" class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <!-- Profile Card -->
      <div class="bg-white rounded-xl shadow-sm p-6">
        <h2 class="text-lg font-semibold text-gray-800 mb-4">Informasi Profil</h2>

        <div class="space-y-4">
          <div>
            <label class="text-sm text-gray-500">Nama</label>
            <p class="text-gray-800 font-medium">{{ data.name }}</p>
          </div>

          <div>
            <label class="text-sm text-gray-500">Email</label>
            <p class="text-gray-800 font-medium">{{ data.email }}</p>
          </div>

          <div>
            <label class="text-sm text-gray-500">User ID</label>
            <p class="text-gray-800 font-medium">{{ data.id }}</p>
          </div>

          <div>
            <label class="text-sm text-gray-500">Terdaftar Sejak</label>
            <p class="text-gray-800 font-medium">{{ formatDate(data.created_at) }}</p>
          </div>
        </div>
      </div>

      <!-- Session Info Card -->
      <div class="bg-white rounded-xl shadow-sm p-6">
        <h2 class="text-lg font-semibold text-gray-800 mb-4">Informasi Session</h2>

        <div class="space-y-4">
          <div>
            <label class="text-sm text-gray-500">Status</label>
            <p class="text-green-600 font-medium flex items-center">
              <span class="w-2 h-2 bg-green-500 rounded-full mr-2"></span>
              Authenticated
            </p>
          </div>

          <div>
            <label class="text-sm text-gray-500">Token</label>
            <p class="text-gray-800 font-mono text-xs bg-gray-50 p-3 rounded-lg break-all">
              {{ token ? token.substring(0, 50) + '...' : '-' }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const { data, status, token } = useAuth()

const formatDate = (dateString) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleDateString('id-ID', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}
</script>
```

## Penjelasan Kode {#penjelasan-kode}

### Mengakses Data User

```javascript
const { data, status, token } = useAuth()
```

Composable `useAuth()` menyediakan beberapa properti reactive:

- **`data`**: Objek berisi data user yang didapatkan dari endpoint `getSession` (`GET /api/v1/profile`). Berisi `id`, `name`, `email`, dan `created_at` sesuai konfigurasi `dataResponsePointer: '/user'` yang kita set di Part 2.
- **`status`**: Status authentication, bisa bernilai `'authenticated'`, `'unauthenticated'`, atau `'loading'`.
- **`token`**: JWT token yang sedang aktif. Berguna untuk debugging atau jika perlu digunakan untuk request API custom.

### Protected Route

Halaman dashboard ini tidak perlu menambahkan `definePageMeta` khusus karena kita sudah mengaktifkan `globalAppMiddleware` di `nuxt.config.ts`. Artinya halaman ini secara default memerlukan authentication. Jika user belum login dan mengakses `/dashboard`, mereka akan otomatis di-redirect ke `/login`.

### Alur getSession

Ketika user mengakses halaman dashboard, berikut alur yang terjadi di balik layar:

1. Nuxt Auth middleware memeriksa apakah ada token di cookie.
2. Jika ada token, Nuxt Auth memanggil `GET /api/v1/profile` dengan header `Authorization: Bearer <token>`.
3. REST API memvalidasi token dan mengembalikan data user.
4. Data user disimpan di `data` dan bisa diakses di semua komponen.
5. Jika token expired atau invalid, user di-redirect ke halaman login.

## Step 2: Verifikasi Halaman Dashboard {#step-2-verifikasi-halaman-dashboard}

Pastikan REST API Go + Gin sudah berjalan, lalu akses `http://localhost:3000/dashboard`. Jika belum login, kita akan di-redirect ke `/login`. Setelah login berhasil, kita akan melihat halaman dashboard dengan informasi profil dan session.

Data yang ditampilkan diambil langsung dari REST API, sehingga selalu up-to-date dengan data di database.

## Penutup {#penutup}

Pada bagian keenam ini kita telah berhasil membuat halaman dashboard yang menampilkan data user dari session. Kita juga sudah memahami bagaimana Nuxt Auth mengelola session dan bagaimana protected route bekerja.

**Selanjutnya:** Pada [Tutorial Nuxt 3 Auth #7](#), kita akan membuat proses logout untuk mengakhiri session user.