---
title: "Tutorial Nuxt 4 Auth #5: Membuat Proses Login"
slug: "tutorial-nuxt-4-auth-5-membuat-proses-login"
category: "Nuxt"
date: "2026-02-19"
status: "published"
---

Pada [bagian keempat](#), kita sudah membuat halaman register. Sekarang kita akan membuat halaman login yang memungkinkan user masuk ke aplikasi menggunakan email dan password yang sudah terdaftar.

## Overview {#overview}

Pada bagian kelima ini, kita akan membuat halaman login yang mengirim credential ke REST API melalui method `signIn` dari `@sidebase/nuxt-auth`. Setelah login berhasil, token JWT akan otomatis disimpan dan user di-redirect ke halaman dashboard.

### Apa yang akan kamu pelajari

1. Membuat halaman login dengan form
2. Menggunakan method `signIn` dari `@sidebase/nuxt-auth`
3. Menangani error authentication
4. Redirect setelah login berhasil

## Step 1: Membuat Halaman Login {#step-1-membuat-halaman-login}

Buat file `app/pages/login.vue` lalu tambahkan kode berikut:

```javascript
<template>
  <div class="bg-white rounded-xl shadow-sm p-8">
    <h2 class="text-2xl font-bold text-gray-800 mb-6">Login</h2>

    <!-- Alert Error -->
    <div
      v-if="errorMessage"
      class="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg text-sm"
    >
      {{ errorMessage }}
    </div>

    <!-- Form Login -->
    <form @submit.prevent="handleLogin" class="space-y-5">
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
          placeholder="Masukkan password"
          required
          class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition"
        />
      </div>

      <!-- Submit Button -->
      <button
        type="submit"
        :disabled="isLoading"
        class="w-full py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {{ isLoading ? 'Masuk...' : 'Masuk' }}
      </button>
    </form>

    <!-- Link ke Register -->
    <p class="mt-6 text-center text-sm text-gray-600">
      Belum punya akun?
      <NuxtLink to="/register" class="text-blue-600 hover:underline font-medium">
        Daftar di sini
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

const { signIn } = useAuth()

const form = reactive({
  email: '',
  password: '',
})

const isLoading = ref(false)
const errorMessage = ref('')

const handleLogin = async () => {
  isLoading.value = true
  errorMessage.value = ''

  try {
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

    // Jika login berhasil, redirect manual ke dashboard
    await navigateTo('/dashboard')
  } catch (error) {
    if (error?.data?.message) {
      errorMessage.value = error.data.message
    } else if (error?.data?.error) {
      errorMessage.value = error.data.error
    } else if (error?.message) {
      errorMessage.value = error.message
    } else {
      errorMessage.value = 'Email atau password salah. Silakan coba lagi.'
    }
  } finally {
    isLoading.value = false
  }
}
</script>
```

## Penjelasan Kode {#penjelasan-kode}

### Method signIn

```javascript
await signIn(
  { email: form.email, password: form.password },
  { redirect: false, callbackUrl: '/dashboard' }
)

await navigateTo('/dashboard')

```

Method `signIn` mengirim data login ke endpoint `POST /api/v1/auth/login`. Ketika API mengembalikan response yang berisi token:

```json
{
  "message": "Login successful",
  "user": { "id": 1, "name": "John Doe", "email": "john@example.com" },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

Nuxt Auth otomatis:
1. Mengambil token dari response berdasarkan `signInResponseTokenPointer: '/token'`.
2. Menyimpan token di cookie.
3. Memanggil `getSession` (`GET /api/v1/profile`) dengan token untuk mendapatkan data user.

Karena kita menggunakan `redirect: false`, `signIn` tidak akan melakukan redirect otomatis. Kita melakukan redirect manual menggunakan `navigateTo('/dashboard')` setelah login berhasil untuk memastikan navigasi berjalan mulus.

### Error Handling

REST API kita mengembalikan response yang sama untuk email tidak ditemukan dan password salah:

```json
{
  "error": "Authentication failed",
  "message": "Invalid email or password"
}
```

Ini merupakan best practice keamanan agar penyerang tidak bisa mengetahui apakah email terdaftar atau tidak.

## Step 2: Verifikasi Halaman Login {#step-2-verifikasi-halaman-login}

Pastikan REST API Go + Gin sudah berjalan, lalu akses `http://localhost:3000/login`. Masukkan email dan password user yang sudah terdaftar di Part 4, lalu klik **Masuk**. Jika login berhasil, kita akan di-redirect ke halaman dashboard.

Coba juga masukkan password yang salah untuk memastikan error handling berjalan dengan baik.

## Penutup {#penutup}

Pada bagian kelima ini kita telah berhasil membuat halaman login yang terintegrasi dengan REST API. Token JWT otomatis disimpan oleh Nuxt Auth setelah login berhasil.

**Selanjutnya:** Pada [Tutorial Nuxt 3 Auth #6](#), kita akan membuat halaman dashboard yang menampilkan data user yang sedang login.