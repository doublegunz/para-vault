---
title: "Tutorial Next.js Authentication dengan Next.js dan Go API — PART 4: Membuat Proses Register"
slug: "tutorial-nextjs-authentication-dengan-nextjs-dan-go-api-part-4-membuat-proses-register"
category: "Next.js"
date: "2026-02-21"
status: "published"
---

Pada Part 4 ini, kita akhirnya mulai membangun fitur yang paling nyata bagi pengguna: proses registrasi. Kita akan mengimplementasikan halaman dan form register yang terhubung langsung ke endpoint `/api/v1/auth/register` di backend Go. Tidak hanya sekadar mengirim data, kita juga akan membangun validasi di sisi client agar kesalahan sederhana seperti password yang tidak cocok bisa langsung terdeteksi sebelum request dikirim ke server — pengalaman yang lebih cepat dan lebih ramah bagi pengguna. Di akhir part ini, user yang baru mendaftar akan langsung diarahkan ke dashboard tanpa perlu login ulang.

- [Overview](#overview)
- [Step 1 - Membuat Komponen RegisterForm](#step-1)
- [Step 2 - Memperbarui Halaman Register](#step-2)
- [Step 3 - Uji Coba Proses Register](#step-3)
- [Penutup](#penutup)

## Overview {#overview}
Sebelum kita tulis kode, ada baiknya kita pahami dulu *mengapa* alur yang kita pilih ini dirancang seperti itu.

Proses registrasi yang kita bangun melewati beberapa tahap. Pertama, user mengisi form dengan nama, email, password, dan konfirmasi password. Sebelum satu pun byte dikirim ke server, validasi client-side berjalan terlebih dahulu — mengecek apakah semua field terisi, apakah format email valid, apakah password cukup panjang, dan apakah kedua field password cocok. Ini bukan sekadar kenyamanan; validasi di sisi client mengurangi beban server dan memberikan umpan balik yang jauh lebih cepat kepada pengguna.

Jika validasi lolos, barulah request `POST` dikirim ke `/api/v1/auth/register` di backend Go. Jika backend merespons dengan sukses, kita tidak langsung meminta user untuk pergi ke halaman login dan mengisi form lagi — itu pengalaman yang tidak perlu dipersulit. Sebaliknya, kita langsung memanggil `signIn` dari NextAuth.js menggunakan kredensial yang sama, sehingga user masuk secara otomatis dan diarahkan ke `/dashboard`. Kalau auto-login ini gagal karena suatu alasan, kita masih punya fallback: redirect ke halaman login dengan parameter `?registered=true` yang bisa kita gunakan nanti untuk menampilkan pesan "Akun berhasil dibuat, silakan masuk."

Pendekatan dua langkah ini — register dulu, lalu login otomatis — adalah pola yang umum digunakan di aplikasi modern karena memberikan pengalaman yang mulus tanpa mengorbankan keamanan.

## Step 1 - Membuat Komponen RegisterForm {#step-1}

Buat file `components/auth/RegisterForm.tsx`:

```typescript
// components/auth/RegisterForm.tsx
"use client";

import { useState } from "react";
import { signIn } from "next-auth/react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import Input from "@/components/ui/Input";
import Button from "@/components/ui/Button";

interface FormData {
  name: string;
  email: string;
  password: string;
  confirmPassword: string;
}

interface FormErrors {
  name?: string;
  email?: string;
  password?: string;
  confirmPassword?: string;
}

export default function RegisterForm() {
  const router = useRouter();

  const [formData, setFormData] = useState<FormData>({
    name: "",
    email: "",
    password: "",
    confirmPassword: "",
  });

  const [errors, setErrors] = useState<FormErrors>({});
  const [apiError, setApiError] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    // Hapus error field saat user mengetik ulang
    if (errors[name as keyof FormErrors]) {
      setErrors((prev) => ({ ...prev, [name]: undefined }));
    }
    if (apiError) setApiError("");
  };

  const validateForm = (): boolean => {
    const newErrors: FormErrors = {};

    if (!formData.name.trim()) {
      newErrors.name = "Nama wajib diisi";
    } else if (formData.name.trim().length < 3) {
      newErrors.name = "Nama minimal 3 karakter";
    } else if (formData.name.trim().length > 100) {
      newErrors.name = "Nama maksimal 100 karakter";
    }

    if (!formData.email.trim()) {
      newErrors.email = "Email wajib diisi";
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = "Format email tidak valid";
    }

    if (!formData.password) {
      newErrors.password = "Password wajib diisi";
    } else if (formData.password.length < 6) {
      newErrors.password = "Password minimal 6 karakter";
    }

    if (!formData.confirmPassword) {
      newErrors.confirmPassword = "Konfirmasi password wajib diisi";
    } else if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = "Konfirmasi password tidak cocok";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm()) return;

    setIsLoading(true);
    setApiError("");

    try {
      // Step 1: Panggil endpoint register backend Go
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/auth/register`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            name: formData.name.trim(),
            email: formData.email.trim().toLowerCase(),
            password: formData.password,
          }),
        }
      );

      const data = await response.json();

      if (!response.ok) {
        setApiError(data.message || "Registrasi gagal. Silakan coba lagi.");
        return;
      }

      // Step 2: Register berhasil, langsung login otomatis
      const signInResult = await signIn("credentials", {
        email: formData.email.trim().toLowerCase(),
        password: formData.password,
        redirect: false,
      });

      if (signInResult?.error) {
        // Auto-login gagal, arahkan ke halaman login
        router.push("/login?registered=true");
        return;
      }

      // Step 3: Arahkan ke dashboard
      router.push("/dashboard");
      router.refresh();
    } catch {
      setApiError("Terjadi kesalahan jaringan. Periksa koneksi Anda.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-5" noValidate>
      {/* Header */}
      <div className="text-center mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Buat Akun Baru</h1>
        <p className="text-sm text-gray-500 mt-1">
          Daftarkan diri Anda untuk mulai menggunakan aplikasi
        </p>
      </div>

      {/* API Error */}
      {apiError && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-lg flex items-start gap-3">
          <svg
            className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path
              fillRule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
              clipRule="evenodd"
            />
          </svg>
          <p className="text-sm text-red-700">{apiError}</p>
        </div>
      )}

      {/* Fields */}
      <Input
        label="Nama Lengkap"
        type="text"
        name="name"
        value={formData.name}
        onChange={handleChange}
        placeholder="John Doe"
        error={errors.name}
        autoComplete="name"
        disabled={isLoading}
      />

      <Input
        label="Alamat Email"
        type="email"
        name="email"
        value={formData.email}
        onChange={handleChange}
        placeholder="john@example.com"
        error={errors.email}
        autoComplete="email"
        disabled={isLoading}
      />

      <Input
        label="Password"
        type="password"
        name="password"
        value={formData.password}
        onChange={handleChange}
        placeholder="Minimal 6 karakter"
        error={errors.password}
        helperText={
          !errors.password && formData.password.length > 0
            ? `${formData.password.length} karakter`
            : undefined
        }
        autoComplete="new-password"
        disabled={isLoading}
      />

      <Input
        label="Konfirmasi Password"
        type="password"
        name="confirmPassword"
        value={formData.confirmPassword}
        onChange={handleChange}
        placeholder="Ulangi password Anda"
        error={errors.confirmPassword}
        autoComplete="new-password"
        disabled={isLoading}
      />

      <Button type="submit" isLoading={isLoading} size="lg" className="w-full">
        Buat Akun
      </Button>

      <p className="text-center text-sm text-gray-600">
        Sudah punya akun?{" "}
        <Link
          href="/login"
          className="font-semibold text-primary-600 hover:text-primary-700 hover:underline"
        >
          Masuk sekarang
        </Link>
      </p>
    </form>
  );
}
```

## Step 2 - Memperbarui Halaman Register {#step-2}

Perbarui `app/(auth)/register/page.tsx`:

```typescript
// app/(auth)/register/page.tsx
import type { Metadata } from "next";
import RegisterForm from "@/components/auth/RegisterForm";

export const metadata: Metadata = {
  title: "Daftar Akun Baru",
  description: "Buat akun baru untuk menggunakan aplikasi",
};

export default function RegisterPage() {
  return <RegisterForm />;
}
```

## Step 3 - Uji Coba Proses Register {#step-3}

Pastikan backend Go berjalan di `http://localhost:8080`, lalu jalankan `npm run dev`.

Akses `http://localhost:3000/register` dan lakukan pengujian:

**Uji validasi client-side** — Klik "Buat Akun" tanpa isi apapun. Semua error validasi harus muncul sekaligus tanpa request ke server.

**Uji registrasi berhasil** — Isi semua field:
```
Nama:                 John Doe
Email:                john.doe@example.com
Password:             securepassword123
Konfirmasi Password:  securepassword123
```
Setelah klik "Buat Akun", Anda harus diarahkan ke `/dashboard`.

**Uji email duplikat** — Coba daftarkan email yang sama. Harus muncul pesan error dari backend: "An account with this email already exists".

**Uji password tidak cocok** — Isi password dan konfirmasi berbeda. Error "Konfirmasi password tidak cocok" harus muncul sebelum request dikirim.

## Penutup {#penutup}
Di Part 4 ini, kita telah menyelesaikan satu alur pengguna yang lengkap dari awal hingga akhir. `RegisterForm` yang kita bangun bukan hanya sekadar formulir biasa — ia mengelola tiga lapisan state sekaligus: data yang diketik user, pesan error dari validasi lokal, dan error yang datang dari respons API. Validasi client-side yang kita tulis sengaja diselaraskan dengan constraint yang ada di backend Go, sehingga pesan error di kedua sisi konsisten dan tidak membingungkan pengguna. Terakhir, auto-login setelah register membuat seluruh alur terasa satu kesatuan yang mulus.

Satu hal yang menarik untuk diperhatikan dari kode yang kita tulis: kita menangani kegagalan di setiap titik secara terpisah. Kegagalan validasi lokal ditangani sebelum request dikirim, kegagalan API ditampilkan sebagai pesan error di atas form, dan bahkan kegagalan auto-login pun ditangani dengan fallback yang masuk akal. Pola pertahanan berlapis seperti ini adalah ciri khas kode yang robust.

Di **Part 5**, kita akan melengkapi sisi lain dari autentikasi dengan mengimplementasikan form login menggunakan fungsi `signIn` dari NextAuth.js, beserta penanganan berbagai jenis error yang bisa muncul dalam proses login.