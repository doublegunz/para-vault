---
title: "Tutorial Nuxt 4 Auth #4: Membuat Proses Register"
slug: "tutorial-nuxt-4-auth-4-membuat-proses-register"
category: "Nuxt"
date: "2026-02-19"
status: "published"
---

Pada [bagian ketiga](#), kita sudah membuat layouts untuk aplikasi. Sekarang kita akan membuat halaman register yang memungkinkan user baru mendaftar ke aplikasi. Halaman ini akan mengirim data registrasi ke REST API Go + Gin melalui `@sidebase/nuxt-auth`.

## Overview {#overview}

Pada bagian keempat ini, kita akan membuat halaman register lengkap dengan form validation, error handling, dan feedback visual. Setelah registrasi berhasil, user akan otomatis login dan di-redirect ke halaman dashboard.

### Apa yang akan kamu pelajari

1. Membuat halaman register dengan form
2. Menggunakan method `signUp` dari `@sidebase/nuxt-auth`
3. Menangani error dari API
4. Auto-login setelah registrasi berhasil

## Step 1: Membuat Halaman Register {#step-1-membuat-halaman-register}

Buat file `app/pages/register.vue` lalu tambahkan kode berikut:

```javascript
<template>
  <div class="bg-white rounded-xl shadow-sm p-8">
    <h2 class="text-2xl font-bold text-gray-800 mb-6">Buat Akun Baru</h2>

    <!-- Alert Error -->
    <div
      v-if="errorMessage"
      class="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg text-sm"
    >
      {{ errorMessage }}
    </div>

    <!-- Alert Success -->
    <div
      v-if="successMessage"
      class="mb-4 p-4 bg-green-50 border border-green-200 text-green-700 rounded-lg text-sm"
    >
      {{ successMessage }}
    </div>

    <!-- Form Register -->
    <form @submit.prevent="handleRegister" class="space-y-5">
      <!-- Name -->
      <div>
        <label for="name" class="block text-sm font-medium text-gray-700 mb-1">
          Nama Lengkap
        </label>
        <input
          id="name"
          v-model="form.name"
          type="text"
          placeholder="Masukkan nama lengkap"
          required
          minlength="3"
          class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
        />
      </div>

      <!-- Email -->
      <div>
        <label for="email" class="block text-sm font-medium text-gray-700 mb-1">
          Email
        </label>
        <input
          id="email"
          v-model="form.email"
          type="email"
          placeholder="Masukkan email"
          required
          class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
        />
      </div>

      <!-- Password -->
      <div>
        <label for="password" class="block text-sm font-medium text-gray-700 mb-1">
          Password
        </label>
        <input
          id="password"
          v-model="form.password"
          type="password"
          placeholder="Masukkan password (min. 6 karakter)"
          required
          minlength="6"
          class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
        />
      </div>

      <!-- Submit Button -->
      <button
        type="submit"
        :disabled="isLoading"
        class="w-full py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {{ isLoading ? 'Mendaftar...' : 'Daftar' }}
      </button>
    </form>

    <!-- Link ke Login -->
    <p class="mt-6 text-center text-sm text-gray-600">
      Sudah punya akun?
      <NuxtLink to="/login" class="text-blue-600 hover:underline font-medium">
        Login di sini
      </NuxtLink>
    </p>
  </div>
</template>

<script setup>
definePageMeta({
  layout: 'auth',
  auth: {
    unauthenticatedOnly: true,
    navigateAuthenticatedTo: '/dashboard',
  },
})

const { signUp, signIn } = useAuth()

const form = reactive({
  name: '',
  email: '',
  password: '',
})

const isLoading = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

const handleRegister = async () => {
  isLoading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    // Kirim data register ke API melalui signUp
    await signUp(
      {
        name: form.name,
        email: form.email,
        password: form.password,
      },
      {
        // Prevent auto redirect setelah signUp
        preventLoginFlow: true,
      }
    )

    successMessage.value = 'Registrasi berhasil! Sedang login...'

    // Auto-login setelah register berhasil
    await signIn(
      {
        email: form.email,
        password: form.password,
      },
      {
        redirect: false,
        callbackUrl: '/dashboard',
      }
    )

    // Redirect manual ke dashboard
    await navigateTo('/dashboard')
  } catch (error) {
    // Tangani error dari API
    if (error?.data?.message) {
      errorMessage.value = error.data.message
    } else if (error?.data?.error) {
      errorMessage.value = error.data.error
    } else if (error?.message) {
      errorMessage.value = error.message
    } else {
      errorMessage.value = 'Terjadi kesalahan saat mendaftar. Silakan coba lagi.'
    }
  } finally {
    isLoading.value = false
  }
}
</script>
```

## Penjelasan Kode {#penjelasan-kode}

### definePageMeta

```js
definePageMeta({
  layout: 'auth',
  auth: {
    unauthenticatedOnly: true,
    navigateAuthenticatedTo: '/dashboard',
  },
})
```

Halaman register menggunakan `auth` layout dan hanya bisa diakses oleh user yang belum login. Jika user yang sudah login mengakses halaman ini, mereka akan di-redirect ke `/dashboard`.

### Method signUp

```js
await signUp(
  { name: form.name, email: form.email, password: form.password },
  { preventLoginFlow: true }
)
```

Method `signUp` dari `useAuth()` mengirim data registrasi ke endpoint yang sudah kita konfigurasi di `nuxt.config.ts` yaitu `POST /api/v1/auth/register`. Parameter `preventLoginFlow: true` (yang sekarang berada di argumen kedua) mencegah Nuxt Auth melakukan login otomatis karena response register dan login kita memiliki format yang sama.

### Auto-login setelah Register

```js
await signIn(
  { email: form.email, password: form.password },
  { redirect: false, callbackUrl: '/dashboard' }
)

await navigateTo('/dashboard')
```

Setelah registrasi berhasil, kita langsung memanggil `signIn` untuk login menggunakan credential yang baru didaftarkan. Kita set `redirect: false` agar `signIn` tidak melakukan redirect otomatis (yang bisa menyebabkan error "navigation cancelled" di beberapa kondisi), lalu kita melakukan redirect manual menggunakan `navigateTo`. Ini memberikan pengalaman yang lebih stabil dan seamless.

### Error Handling

```js
if (error.data?.message) {
  errorMessage.value = error.data.message
} else if (error.data?.error) {
  errorMessage.value = error.data.error
}
```

Error dari REST API kita memiliki format `{ "error": "...", "message": "..." }`. Kita menampilkan pesan error yang sesuai dari response API, misalnya "An account with this email already exists" ketika email sudah terdaftar.

## Step 2: Verifikasi Halaman Register {#step-2-verifikasi-halaman-register}

Pastikan REST API Go + Gin sudah berjalan di `http://localhost:8080`, lalu jalankan development server Nuxt:

```bash
npm run dev
```

Akses `http://localhost:3000/register` di browser. Coba isi form dengan data berikut:

- Nama: `John Doe`
- Email: `john@example.com`
- Password: `password123`

Klik tombol **Daftar**. Jika registrasi berhasil, kita akan melihat pesan sukses dan otomatis di-redirect ke halaman dashboard (yang akan kita buat di Part 6).

## Penutup {#penutup}

Pada bagian keempat ini kita telah berhasil membuat halaman register yang terintegrasi dengan REST API. Halaman ini sudah dilengkapi dengan form validation, error handling, dan auto-login setelah registrasi berhasil.

**Selanjutnya:** Pada [Tutorial Nuxt 3 Auth #5](#), kita akan membuat halaman login.