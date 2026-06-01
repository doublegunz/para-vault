---
title: "Tutorial Nuxt 4 Auth #7: Membuat Proses Logout"
slug: "tutorial-nuxt-4-auth-7-membuat-proses-logout"
category: "Nuxt"
date: "2026-02-19"
status: "published"
---

Pada [bagian keenam](#), kita sudah membuat halaman dashboard yang menampilkan data user. Sekarang pada bagian terakhir ini, kita akan mengimplementasikan proses logout untuk mengakhiri session user. Selain itu, kita juga akan membahas beberapa penyempurnaan akhir untuk memastikan semua alur authentication berjalan dengan baik.

## Overview {#overview}

Pada bagian ketujuh (terakhir) ini, kita akan mengimplementasikan proses logout, menambahkan feedback visual, dan melakukan uji coba menyeluruh terhadap seluruh alur authentication.

### Apa yang akan kamu pelajari

1. Implementasi proses logout
2. Menambahkan konfirmasi logout
3. Uji coba menyeluruh alur authentication
4. Menangani edge case (token expired)

## Step 1: Implementasi Proses Logout {#step-1-implementasi-proses-logout}

Pada Part 2, kita sudah mengkonfigurasi `signOut: false` di endpoints karena REST API Go + Gin kita tidak memiliki endpoint logout khusus. Dengan konfigurasi ini, proses logout ditangani sepenuhnya di sisi client dengan menghapus token dari cookie.

Sebenarnya, logika logout sudah kita tulis di `app/layouts/default.vue` pada Part 3:

```javascript
const handleLogout = async () => {
  await signOut({ callbackUrl: '/login' })
}
```

Sekarang kita akan menyempurnakan proses logout dengan menambahkan dialog konfirmasi. Update file `app/layouts/default.vue` menjadi seperti berikut:

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
              @click="confirmLogout"
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

    <!-- Modal Konfirmasi Logout -->
    <Teleport to="body">
      <div
        v-if="showLogoutModal"
        class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
        @click.self="showLogoutModal = false"
      >
        <div class="bg-white rounded-xl shadow-lg p-6 max-w-sm w-full mx-4">
          <h3 class="text-lg font-semibold text-gray-800 mb-2">Konfirmasi Logout</h3>
          <p class="text-gray-600 text-sm mb-6">
            Apakah kamu yakin ingin keluar dari aplikasi?
          </p>
          <div class="flex space-x-3">
            <button
              @click="showLogoutModal = false"
              class="flex-1 py-2 px-4 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition text-sm font-medium"
            >
              Batal
            </button>
            <button
              @click="handleLogout"
              :disabled="isLoggingOut"
              class="flex-1 py-2 px-4 bg-red-600 text-white rounded-lg hover:bg-red-700 transition text-sm font-medium disabled:opacity-50"
            >
              {{ isLoggingOut ? 'Keluar...' : 'Ya, Logout' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
const { data, signOut } = useAuth()

const showLogoutModal = ref(false)
const isLoggingOut = ref(false)

const confirmLogout = () => {
  showLogoutModal.value = true
}

const handleLogout = async () => {
  isLoggingOut.value = true

  try {
    await signOut({ callbackUrl: '/login' })
  } catch (error) {
    console.error('Logout error:', error)
    // Fallback: redirect manual jika signOut gagal
    navigateTo('/login')
  } finally {
    isLoggingOut.value = false
    showLogoutModal.value = false
  }
}
</script>
```

## Penjelasan Kode {#penjelasan-kode}

### Method signOut

```javascript
await signOut({ callbackUrl: '/login' })
```

Karena kita mengkonfigurasi `signOut: false` di endpoints, method `signOut` melakukan hal berikut di sisi client:

1. Menghapus token JWT dari cookie.
2. Menghapus data session (data user).
3. Redirect ke `callbackUrl` yaitu `/login`.

Tidak ada request ke backend karena REST API kita mengandalkan stateless JWT. Token hanya perlu dihapus dari sisi client dan otomatis expire sesuai waktu yang ditentukan.

### Modal Konfirmasi

Dialog konfirmasi mencegah user melakukan logout secara tidak sengaja. `<Teleport to="body">` digunakan untuk me-render modal di luar hierarki DOM komponen, sehingga tidak terpengaruh oleh styling parent.

### Fallback Error Handling

```javascript
catch (error) {
  console.error('Logout error:', error)
  navigateTo('/login')
}
```

Jika terjadi error saat proses logout, kita tetap melakukan redirect manual ke halaman login sebagai fallback.

## Step 2: Menangani Token Expired {#step-2-menangani-token-expired}

Salah satu edge case yang perlu ditangani adalah ketika JWT token sudah expired. Token yang kita konfigurasi memiliki masa berlaku 24 jam. Ketika token expired, request ke `getSession` akan gagal dan user perlu login ulang.

`@sidebase/nuxt-auth` sudah menangani ini secara otomatis. Ketika `getSession` mengembalikan response error (401 Unauthorized), module akan menghapus token dan redirect user ke halaman login.

Untuk penanganan tambahan, kita bisa membuat error handler global. Buat file `plugins/auth-error.client.ts`:

```ts
export default defineNuxtPlugin((nuxtApp) => {
  const { signOut } = useAuth()

  // Watch for auth errors
  nuxtApp.hook('app:error', async (error) => {
    // Jika error 401, redirect ke login
    if (error.statusCode === 401) {
      await signOut({ callbackUrl: '/login' })
    }
  })
})
```

## Step 3: Uji Coba Menyeluruh {#step-3-uji-coba-menyeluruh}

Sekarang kita akan menguji seluruh alur authentication dari awal hingga akhir. Pastikan REST API Go + Gin sudah berjalan di `http://localhost:8080`, lalu jalankan Nuxt development server:

```bash
npm run dev
```

Berikut skenario uji coba yang perlu dilakukan:

**1. Akses halaman tanpa login**

Buka `http://localhost:3000/dashboard` di browser. Kita akan otomatis di-redirect ke `/login` karena belum authenticated.

**2. Register user baru**

Akses `/register`, isi form, lalu klik **Daftar**. Setelah berhasil, kita otomatis login dan di-redirect ke `/dashboard`.

**3. Logout**

Klik tombol **Logout** di navbar. Dialog konfirmasi akan muncul. Klik **Ya, Logout**. Kita akan di-redirect ke `/login`.

**4. Login kembali**

Akses `/login`, masukkan email dan password yang sudah terdaftar, lalu klik **Masuk**. Kita akan di-redirect ke `/dashboard` dan data user ditampilkan.

**5. Akses halaman login saat sudah authenticated**

Saat masih login, coba akses `/login` atau `/register`. Kita akan otomatis di-redirect ke `/dashboard` karena halaman tersebut dikonfigurasi dengan `unauthenticatedOnly: true`.

**6. Register dengan email yang sudah terdaftar**

Logout terlebih dahulu, lalu coba register dengan email yang sama. Pesan error "An account with this email already exists" akan ditampilkan.

**7. Login dengan password salah**

Coba login dengan password yang salah. Pesan error "Invalid email or password" akan ditampilkan.

## Struktur Akhir Project {#struktur-akhir-project}

Setelah menyelesaikan semua bagian tutorial, berikut adalah struktur akhir project kita:

```
nuxt-auth-app/
├── app/
│   ├── components/
│   ├── layouts/
│   │   ├── auth.vue                # Layout untuk halaman publik
│   │   └── default.vue             # Layout untuk halaman authenticated
│   ├── middleware/
│   ├── pages/
│   │   ├── dashboard.vue           # Halaman dashboard (protected)
│   │   ├── index.vue               # Halaman index (redirect)
│   │   ├── login.vue               # Halaman login (public)
│   │   └── register.vue            # Halaman register (public)
│   ├── plugins/
│   │   └── auth-error.client.ts    # Plugin error handler
│   └── app.vue                     # Root component
├── public/
├── server/
├── .env                            # Environment variables
├── nuxt.config.ts                  # Konfigurasi Nuxt + Auth
├── package.json
├── tailwind.config.js
└── tsconfig.json
```

## Penutup {#penutup}

Selamat! Kita telah menyelesaikan seluruh seri tutorial Nuxt 3 Auth. Dari 7 bagian tutorial ini, kita telah berhasil membangun sistem authentication frontend yang lengkap dan terintegrasi dengan REST API Go + Gin.

**Takeaway dari seri tutorial ini:**

- **`@sidebase/nuxt-auth`** dengan Local Provider sangat cocok untuk aplikasi yang memiliki backend terpisah dengan JWT authentication. Konfigurasi cukup dilakukan di `nuxt.config.ts` dan module menangani sisanya secara otomatis.
- **Layout system** di Nuxt 3 memudahkan kita memisahkan tampilan untuk halaman publik dan halaman yang memerlukan authentication.
- **`definePageMeta`** dengan opsi `auth` memberikan kontrol granular untuk menentukan akses halaman, apakah hanya untuk user yang belum login (`unauthenticatedOnly`) atau memerlukan authentication.
- **Composable `useAuth()`** menyediakan akses ke data session, token, dan method authentication (`signIn`, `signUp`, `signOut`) yang bisa digunakan di seluruh komponen aplikasi.
- **Error handling** yang baik di setiap halaman memberikan pengalaman user yang lebih baik dengan pesan error yang informatif dari API.

Beberapa enhancement yang bisa ditambahkan untuk pengembangan lebih lanjut:
- Implementasi refresh token untuk memperpanjang session tanpa login ulang
- Menambahkan halaman edit profile
- Implementasi "Remember Me" di halaman login
- Menambahkan validasi form yang lebih ketat dengan library seperti Vuelidate atau Zod
- Implementasi rate limiting di sisi frontend