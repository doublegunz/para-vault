---
title: "Tutorial Next.js Authentication dengan Next.js dan Go API — PART 5: Membuat Proses Login"
slug: "tutorial-nextjs-authentication-dengan-nextjs-dan-go-api-part-5-membuat-proses-login"
category: "Next.js"
date: "2026-02-21"
status: "published"
---

Pada Part 5 ini, kita melengkapi sisi lain dari sistem autentikasi yang sudah kita bangun: proses login. Berbeda dengan register yang memanggil endpoint backend secara langsung, login di sini sepenuhnya dikelola melalui fungsi `signIn` dari NextAuth.js yang kemudian secara internal menjalankan fungsi `authorize` di `auth.ts` kita, memanggil backend Go, dan menyimpan hasilnya ke dalam session. Selain alur utama ini, kita juga akan membangun dua komponen pendukung yang sering diabaikan namun penting: sistem pemetaan pesan error agar feedback ke pengguna lebih bermakna, dan validasi callback URL untuk mencegah celah keamanan open redirect.

- [Overview](#overview)
- [Step 1 - Membuat Error Helpers](#step-1)
- [Step 2 - Membuat Safe Redirect Helper](#step-2)
- [Step 3 - Membuat Komponen LoginForm](#step-3)
- [Step 4 - Memperbarui Halaman Login](#step-4)
- [Step 5 - Uji Coba Proses Login](#step-5)
- [Penutup](#penutup)

## Overview {#overview}

Ada satu perbedaan mendasar antara form login di Part ini dengan form register di Part sebelumnya yang perlu kita pahami sebelum menulis kode.

Di Part 4, kita memanggil endpoint backend Go secara langsung dari komponen React menggunakan `fetch`. Hasilnya kemudian kita gunakan untuk memanggil `signIn`. Di Part ini, kita tidak melakukan itu, kita menyerahkan seluruh proses ke `signIn("credentials", ...)` sejak awal. NextAuth.js yang kemudian akan memanggil fungsi `authorize` di `auth.ts`, yang di dalamnya sudah ada logika untuk memanggil backend. Kita menambahkan `redirect: false` agar proses ini tidak langsung melempar pengguna ke halaman lain, melainkan mengembalikan objek hasil yang bisa kita periksa dan tampilkan errornya di form.

Alur lengkapnya berjalan seperti ini: user mengisi email dan password lalu menekan tombol masuk → validasi client-side berjalan terlebih dahulu → `signIn` dipanggil dengan `redirect: false` → NextAuth.js menjalankan `authorize` di `auth.ts` → `authorize` memanggil `POST /api/v1/auth/login` di backend Go → jika berhasil, JWT token dari backend disimpan di dalam session → user diarahkan ke `callbackUrl` atau `/dashboard` sebagai fallback.

Satu hal lain yang perlu diperhatikan adalah callback URL. Ketika pengguna mencoba mengakses `/dashboard` tanpa login, middleware kita dari Part 2 akan menyimpan tujuan asal itu sebagai parameter `?callbackUrl=/dashboard` di URL login. Setelah login berhasil, kita harus mengembalikan pengguna ke halaman yang semula ingin mereka kunjungi — bukan selalu ke `/dashboard`. Tapi kita juga tidak bisa begitu saja mempercayai nilai `callbackUrl` dari URL, karena seorang penyerang bisa memanipulasinya untuk mengarahkan user ke situs berbahaya. Itulah mengapa kita perlu helper `getSafeCallbackUrl` yang memastikan redirect hanya boleh menuju path internal aplikasi kita.

## Step 1 - Membuat Error Helpers {#step-1}

Buat file `lib/auth-errors.ts` untuk memetakan kode error NextAuth.js ke pesan yang mudah dipahami:

```typescript
// lib/auth-errors.ts

/**
 * Memetakan kode error NextAuth.js ke pesan user-friendly dalam bahasa Indonesia.
 * 
 * NextAuth.js melempar error dalam format kode string tertentu.
 * Error kustom dari fungsi authorize() di auth.ts diteruskan langsung.
 */
export function getErrorMessage(error: string): string {
  const errorMessages: Record<string, string> = {
    Configuration: "Terjadi kesalahan konfigurasi sistem. Hubungi administrator.",
    AccessDenied: "Akses ditolak.",
    Verification: "Token verifikasi tidak valid atau sudah kedaluwarsa.",
    // Error ini muncul saat credentials tidak valid
    CredentialsSignin: "Email atau password yang Anda masukkan salah.",
    Default: "Terjadi kesalahan saat login. Silakan coba lagi.",
  };

  // Jika error adalah pesan kustom dari fungsi authorize (bukan kode error standar),
  // gunakan langsung sebagai pesan
  if (!Object.keys(errorMessages).includes(error)) {
    return error;
  }

  return errorMessages[error] ?? errorMessages.Default;
}
```

## Step 2 - Membuat Safe Redirect Helper {#step-2}

Buat file `lib/safe-redirect.ts` untuk mencegah **open redirect vulnerability** — di mana attacker bisa mengarahkan user ke situs berbahaya via parameter URL:

```typescript
// lib/safe-redirect.ts

/**
 * Memvalidasi callbackUrl agar tidak ada open redirect ke domain eksternal.
 * Hanya mengizinkan URL yang diawali dengan "/" (path relatif).
 */
export function getSafeCallbackUrl(
  callbackUrl: string | null,
  defaultUrl = "/dashboard"
): string {
  if (!callbackUrl) return defaultUrl;

  // Tolak URL yang tidak diawali dengan "/" (bisa jadi URL eksternal)
  if (!callbackUrl.startsWith("/")) return defaultUrl;

  // Tolak URL auth agar tidak terjadi loop redirect
  const blocked = ["/login", "/register", "/api/auth"];
  if (blocked.some((url) => callbackUrl.startsWith(url))) return defaultUrl;

  return callbackUrl;
}
```

## Step 3 - Membuat Komponen LoginForm {#step-3}

Buat file `components/auth/LoginForm.tsx`:

```typescript
// components/auth/LoginForm.tsx
"use client";

import { useState, useEffect } from "react";
import { signIn } from "next-auth/react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import Input from "@/components/ui/Input";
import Button from "@/components/ui/Button";
import { getErrorMessage } from "@/lib/auth-errors";
import { getSafeCallbackUrl } from "@/lib/safe-redirect";

interface FormData {
  email: string;
  password: string;
}

interface FormErrors {
  email?: string;
  password?: string;
}

export default function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();

  // Ambil callbackUrl dari query params (disimpan oleh middleware)
  const callbackUrl = getSafeCallbackUrl(
    searchParams.get("callbackUrl"),
    "/dashboard"
  );

  // Cek apakah user baru saja selesai register
  const justRegistered = searchParams.get("registered") === "true";

  const [formData, setFormData] = useState<FormData>({ email: "", password: "" });
  const [errors, setErrors] = useState<FormErrors>({});
  const [authError, setAuthError] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  // Bersihkan query param "registered" dari URL tanpa reload halaman
  useEffect(() => {
    if (justRegistered) {
      const url = new URL(window.location.href);
      url.searchParams.delete("registered");
      window.history.replaceState({}, "", url.toString());
    }
  }, [justRegistered]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    if (errors[name as keyof FormErrors]) {
      setErrors((prev) => ({ ...prev, [name]: undefined }));
    }
    if (authError) setAuthError("");
  };

  const validateForm = (): boolean => {
    const newErrors: FormErrors = {};

    if (!formData.email.trim()) {
      newErrors.email = "Email wajib diisi";
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = "Format email tidak valid";
    }

    if (!formData.password) {
      newErrors.password = "Password wajib diisi";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm()) return;

    setIsLoading(true);
    setAuthError("");

    try {
      const result = await signIn("credentials", {
        email: formData.email.trim().toLowerCase(),
        password: formData.password,
        redirect: false,
      });

      if (result?.error) {
        setAuthError(getErrorMessage(result.error));
        return;
      }

      if (result?.ok) {
        router.push(callbackUrl);
        router.refresh();
      }
    } catch {
      setAuthError("Terjadi kesalahan yang tidak terduga. Silakan coba lagi.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-5" noValidate>
      {/* Header */}
      <div className="text-center mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Masuk ke Akun</h1>
        <p className="text-sm text-gray-500 mt-1">
          Selamat datang kembali! Silakan masuk untuk melanjutkan.
        </p>
      </div>

      {/* Notifikasi post-register */}
      {justRegistered && !authError && (
        <div className="p-4 bg-green-50 border border-green-200 rounded-lg flex items-start gap-3">
          <svg className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
          </svg>
          <p className="text-sm text-green-700">
            Akun berhasil dibuat! Silakan masuk dengan email dan password Anda.
          </p>
        </div>
      )}

      {/* Auth Error */}
      {authError && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-lg flex items-start gap-3">
          <svg className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
          </svg>
          <p className="text-sm text-red-700">{authError}</p>
        </div>
      )}

      {/* Fields */}
      <Input
        label="Alamat Email"
        type="email"
        name="email"
        value={formData.email}
        onChange={handleChange}
        placeholder="john@example.com"
        error={errors.email}
        autoComplete="email"
        autoFocus
        disabled={isLoading}
      />

      <Input
        label="Password"
        type="password"
        name="password"
        value={formData.password}
        onChange={handleChange}
        placeholder="Masukkan password Anda"
        error={errors.password}
        autoComplete="current-password"
        disabled={isLoading}
      />

      <Button type="submit" isLoading={isLoading} size="lg" className="w-full">
        Masuk
      </Button>

      <p className="text-center text-sm text-gray-600">
        Belum punya akun?{" "}
        <Link
          href="/register"
          className="font-semibold text-primary-600 hover:text-primary-700 hover:underline"
        >
          Daftar sekarang
        </Link>
      </p>
    </form>
  );
}
```

## Step 4 - Memperbarui Halaman Login {#step-4}

`LoginForm` menggunakan `useSearchParams` yang memerlukan `Suspense` boundary. Perbarui `app/(auth)/login/page.tsx`:

```typescript
// app/(auth)/login/page.tsx
import type { Metadata } from "next";
import { Suspense } from "react";
import LoginForm from "@/components/auth/LoginForm";

export const metadata: Metadata = {
  title: "Masuk ke Akun",
  description: "Masuk ke akun Anda untuk menggunakan aplikasi",
};

// Skeleton loading saat LoginForm di-load
function LoginFormSkeleton() {
  return (
    <div className="space-y-5 animate-pulse">
      <div className="text-center mb-6 space-y-2">
        <div className="h-8 bg-gray-200 rounded w-48 mx-auto" />
        <div className="h-4 bg-gray-100 rounded w-64 mx-auto" />
      </div>
      <div className="space-y-1">
        <div className="h-4 bg-gray-200 rounded w-24" />
        <div className="h-10 bg-gray-100 rounded-lg" />
      </div>
      <div className="space-y-1">
        <div className="h-4 bg-gray-200 rounded w-20" />
        <div className="h-10 bg-gray-100 rounded-lg" />
      </div>
      <div className="h-11 bg-primary-200 rounded-lg" />
    </div>
  );
}

export default function LoginPage() {
  return (
    // Suspense wajib karena LoginForm menggunakan useSearchParams
    <Suspense fallback={<LoginFormSkeleton />}>
      <LoginForm />
    </Suspense>
  );
}
```

## Step 5 - Uji Coba Proses Login {#step-5}

Pastikan backend berjalan, lalu jalankan `npm run dev`.

**Uji validasi** — Klik "Masuk" tanpa isi apapun, error harus muncul.

**Uji login berhasil** — Gunakan akun dari Part 4:
```
Email:    john.doe@example.com
Password: securepassword123
```
Setelah login, harus diarahkan ke `/dashboard`.

**Uji password salah** — Masukkan password yang salah. Harus muncul: "Email atau password yang Anda masukkan salah."

**Uji callback URL** — Akses `http://localhost:3000/dashboard` tanpa login, akan diarahkan ke `/login?callbackUrl=/dashboard`. Setelah login, harus kembali ke `/dashboard`.

**Uji halaman auth saat sudah login** — Saat sudah login, coba akses `/login`. Harus diarahkan ke `/dashboard` oleh middleware.

## Penutup {#penutup}

Di Part 5 ini, kita telah menyelesaikan sistem login yang lebih dari sekadar "form yang mengirim data." `LoginForm` yang kita bangun menangani tiga lapisan sekaligus: validasi lokal sebelum request dikirim, error yang dikembalikan oleh NextAuth.js dari proses autentikasi, dan error jaringan yang tidak terduga. Masing-masing lapisan ditangani secara eksplisit sehingga pengguna selalu mendapatkan pesan yang relevan,  bukan pesan generik yang tidak membantu.