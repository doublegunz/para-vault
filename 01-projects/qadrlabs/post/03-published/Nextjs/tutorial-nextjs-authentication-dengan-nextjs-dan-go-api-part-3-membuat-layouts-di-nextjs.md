---
title: "Tutorial Next.js Authentication dengan Next.js dan Go API — PART 3: Membuat Layouts di Next.js"
slug: "tutorial-nextjs-authentication-dengan-nextjs-dan-go-api-part-3-membuat-layouts-di-nextjs"
category: "Next.js"
date: "2026-02-21"
status: "published"
---

Pada Part 3 ini, kita akan membangun fondasi visual aplikasi — yakni sistem layout yang akan menjadi "kerangka" dari setiap halaman. Sebelum kita bisa membuat fitur login, register, atau dashboard, kita perlu menyiapkan struktur yang konsisten: tampilan seperti apa yang muncul di halaman autentikasi, dan tampilan seperti apa yang muncul setelah pengguna berhasil masuk. Kita juga akan membuat komponen UI yang dapat digunakan ulang (reusable), seperti Button dan Input, sehingga kita tidak perlu menulis ulang kode yang sama setiap kali membutuhkannya.

- [Overview](#overview)
- [Step 1 - Membuat Utility Function](#step-1)
- [Step 2 - Membuat Komponen UI Reusable](#step-2)
- [Step 3 - Membuat Auth Layout](#step-3)
- [Step 4 - Membuat Dashboard Layout](#step-4)
- [Step 5 - Membuat Komponen Navbar](#step-5)
- [Step 6 - Membuat Halaman Placeholder](#step-6)
- [Step 7 - Verifikasi Layout System](#step-7)
- [Penutup](#penutup)

## Overview {#overview}


Sebelum masuk ke kode, penting untuk memahami cara kerja layout di Next.js App Router, karena konsepnya sedikit berbeda dari pendekatan tradisional.

Di App Router, layout bekerja berdasarkan struktur folder. Setiap `layout.tsx` yang kamu buat secara otomatis akan membungkus semua halaman yang berada di dalam folder yang sama — dan ini terjadi secara hierarkis. Artinya, `app/layout.tsx` akan membungkus seluruh aplikasi, sementara layout yang lebih dalam hanya akan membungkus bagian tertentu saja.

Nah, ada satu konsep penting yang perlu dipahami di sini: **Route Groups**, yaitu folder yang namanya ditulis dalam tanda kurung, seperti `(auth)` atau `(dashboard)`. Route groups memungkinkan kita mengelompokkan halaman-halaman yang berbagi layout yang sama, *tanpa* memengaruhi struktur URL. Jadi, meskipun file login kita berada di dalam folder `(auth)`, URL-nya tetap `/login` — bukan `/auth/login`. Tanda kurung itu hanya penanda internal untuk Next.js, tidak ikut terbaca sebagai segmen URL.

Dengan pendekatan ini, struktur folder aplikasi kita akan terlihat seperti berikut:

```
app/
├── (auth)/
│   ├── layout.tsx      ← Auth Layout (untuk /login dan /register)
│   ├── login/page.tsx
│   └── register/page.tsx
├── (dashboard)/
│   ├── layout.tsx      ← Dashboard Layout (untuk /dashboard)
│   └── dashboard/page.tsx
└── layout.tsx          ← Root Layout (untuk semua halaman)
```

Setiap kelompok halaman mendapatkan "bungkusnya" sendiri: halaman login dan register akan tampil di dalam kartu minimalis di tengah layar, sementara halaman dashboard akan memiliki navbar di bagian atas dan area konten di bawahnya.

## Step 1 - Membuat Utility Function {#step-1}

Buat file `lib/utils.ts` untuk fungsi-fungsi helper yang akan digunakan di seluruh aplikasi:

```typescript
// lib/utils.ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

/**
 * Menggabungkan class names Tailwind dengan benar.
 * Mencegah konflik seperti 'p-2' dan 'p-4' muncul bersamaan.
 * 
 * Contoh penggunaan:
 * cn("p-4", isActive && "bg-blue-500", className)
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/**
 * Format tanggal ke format Indonesia.
 * Contoh: "12 Maret 2024"
 */
export function formatDate(dateString: string): string {
  try {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat("id-ID", {
      year: "numeric",
      month: "long",
      day: "numeric",
    }).format(date);
  } catch {
    return dateString;
  }
}
```

## Step 2 - Membuat Komponen UI Reusable {#step-2}

### Komponen Button

Buat file `components/ui/Button.tsx`:

```typescript
// components/ui/Button.tsx
import { ButtonHTMLAttributes, forwardRef } from "react";
import { cn } from "@/lib/utils";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "ghost" | "danger";
  size?: "sm" | "md" | "lg";
  isLoading?: boolean;
}

const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      children,
      variant = "primary",
      size = "md",
      isLoading = false,
      className,
      disabled,
      ...props
    },
    ref
  ) => {
    const base =
      "inline-flex items-center justify-center font-medium rounded-lg transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed";

    const variants = {
      primary:
        "bg-primary-600 text-white hover:bg-primary-700 focus:ring-primary-500",
      secondary:
        "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50 focus:ring-primary-500",
      ghost:
        "text-gray-600 hover:bg-gray-100 hover:text-gray-900 focus:ring-gray-500",
      danger:
        "bg-red-600 text-white hover:bg-red-700 focus:ring-red-500",
    };

    const sizes = {
      sm: "px-3 py-1.5 text-sm",
      md: "px-4 py-2 text-sm",
      lg: "px-6 py-3 text-base",
    };

    return (
      <button
        ref={ref}
        className={cn(base, variants[variant], sizes[size], className)}
        disabled={isLoading || disabled}
        {...props}
      >
        {isLoading ? (
          <>
            <svg
              className="animate-spin -ml-1 mr-2 h-4 w-4"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle
                className="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                strokeWidth="4"
              />
              <path
                className="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              />
            </svg>
            Memproses...
          </>
        ) : (
          children
        )}
      </button>
    );
  }
);

Button.displayName = "Button";
export default Button;
```

### Komponen Input

Buat file `components/ui/Input.tsx`:

```typescript
// components/ui/Input.tsx
import { InputHTMLAttributes, forwardRef } from "react";
import { cn } from "@/lib/utils";

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
}

const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, helperText, className, id, ...props }, ref) => {
    const inputId = id || label?.toLowerCase().replace(/\s+/g, "-");

    return (
      <div className="space-y-1">
        {label && (
          <label
            htmlFor={inputId}
            className="block text-sm font-medium text-gray-700"
          >
            {label}
          </label>
        )}
        <input
          ref={ref}
          id={inputId}
          className={cn(
            "w-full px-3 py-2 border rounded-lg shadow-sm text-sm",
            "focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent",
            "disabled:bg-gray-50 disabled:text-gray-500 disabled:cursor-not-allowed",
            "transition-colors duration-200",
            error ? "border-red-400 focus:ring-red-400" : "border-gray-300",
            className
          )}
          {...props}
        />
        {error && (
          <p className="text-sm text-red-600 flex items-center gap-1">
            <svg
              className="w-4 h-4 flex-shrink-0"
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path
                fillRule="evenodd"
                d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z"
                clipRule="evenodd"
              />
            </svg>
            {error}
          </p>
        )}
        {helperText && !error && (
          <p className="text-sm text-gray-500">{helperText}</p>
        )}
      </div>
    );
  }
);

Input.displayName = "Input";
export default Input;
```

## Step 3 - Membuat Auth Layout {#step-3}

Buat folder `app/(auth)/` dan file `app/(auth)/layout.tsx`:

```typescript
// app/(auth)/layout.tsx
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: {
    template: "%s | Next.js Auth App",
    default: "Authentication",
  },
};

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-50 via-white to-blue-50 flex items-center justify-center p-4">
      {/* Background decorative blobs */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-primary-100 rounded-full opacity-40 blur-3xl" />
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-blue-100 rounded-full opacity-40 blur-3xl" />
      </div>

      <div className="relative w-full max-w-md">
        {/* Brand */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-14 h-14 bg-primary-600 rounded-2xl shadow-lg mb-4">
            <svg
              className="w-7 h-7 text-white"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
              />
            </svg>
          </div>
          <h2 className="text-2xl font-bold text-gray-900">Next.js Auth App</h2>
          <p className="text-sm text-gray-500 mt-1">
            Next.js 16 + Go API
          </p>
        </div>

        {/* Card */}
        <div className="bg-white rounded-2xl shadow-xl border border-gray-100 p-8">
          {children}
        </div>

        <p className="text-center text-xs text-gray-400 mt-6">
          © 2024 Next.js Auth App
        </p>
      </div>
    </div>
  );
}
```

## Step 4 - Membuat Dashboard Layout {#step-4}

Buat folder `app/(dashboard)/` dan file `app/(dashboard)/layout.tsx`:

```typescript
// app/(dashboard)/layout.tsx
import { auth } from "@/auth";
import { redirect } from "next/navigation";
import Navbar from "@/components/Navbar";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Cek session di server sebagai lapisan keamanan tambahan
  const session = await auth();

  if (!session) {
    redirect("/login");
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar user={session.user} />
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {children}
      </main>
    </div>
  );
}
```

## Step 5 - Membuat Komponen Navbar {#step-5}

Buat file `components/Navbar.tsx`:

```typescript
// components/Navbar.tsx
"use client";

import { signOut } from "next-auth/react";
import Link from "next/link";
import { useState } from "react";

interface NavbarProps {
  user: {
    name?: string | null;
    email?: string | null;
  };
}

export default function Navbar({ user }: NavbarProps) {
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);

  const getInitials = (name: string | null | undefined) => {
    if (!name) return "?";
    return name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2);
  };

  const handleLogout = async () => {
    setIsLoggingOut(true);
    try {
      await signOut({ callbackUrl: "/login" });
    } catch {
      setIsLoggingOut(false);
    }
  };

  return (
    <nav className="bg-white border-b border-gray-200 shadow-sm sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
              <svg
                className="w-5 h-5 text-white"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                />
              </svg>
            </div>
            <Link
              href="/dashboard"
              className="text-lg font-semibold text-gray-900 hover:text-primary-600 transition-colors"
            >
              Auth App
            </Link>
          </div>

          {/* Nav Links */}
          <div className="hidden md:flex items-center gap-1">
            <Link
              href="/dashboard"
              className="px-3 py-2 text-sm font-medium text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
            >
              Dashboard
            </Link>
          </div>

          {/* User Dropdown */}
          <div className="relative">
            <button
              onClick={() => setIsDropdownOpen(!isDropdownOpen)}
              className="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-gray-100 transition-colors focus:outline-none focus:ring-2 focus:ring-primary-500"
            >
              <div className="w-8 h-8 bg-primary-100 text-primary-700 rounded-full flex items-center justify-center text-sm font-semibold">
                {getInitials(user.name)}
              </div>
              <span className="hidden md:block text-sm font-medium text-gray-700">
                {user.name || user.email}
              </span>
              <svg
                className={`w-4 h-4 text-gray-500 transition-transform ${
                  isDropdownOpen ? "rotate-180" : ""
                }`}
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </button>

            {isDropdownOpen && (
              <>
                <div
                  className="fixed inset-0 z-10"
                  onClick={() => setIsDropdownOpen(false)}
                />
                <div className="absolute right-0 mt-2 w-56 bg-white rounded-xl shadow-lg border border-gray-100 z-20 overflow-hidden">
                  <div className="px-4 py-3 bg-gray-50 border-b border-gray-100">
                    <p className="text-sm font-semibold text-gray-900 truncate">{user.name}</p>
                    <p className="text-xs text-gray-500 truncate">{user.email}</p>
                  </div>
                  <div className="py-1">
                    <Link
                      href="/dashboard"
                      className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                      onClick={() => setIsDropdownOpen(false)}
                    >
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                      </svg>
                      Dashboard
                    </Link>
                  </div>
                  <div className="border-t border-gray-100 py-1">
                    <button
                      onClick={handleLogout}
                      disabled={isLoggingOut}
                      className="w-full flex items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50 transition-colors disabled:opacity-50"
                    >
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                      </svg>
                      {isLoggingOut ? "Keluar..." : "Keluar"}
                    </button>
                  </div>
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}
```

## Step 6 - Membuat Halaman Placeholder {#step-6}

Buat halaman sementara agar routing dapat diverifikasi sebelum implementasi penuh di Part berikutnya.

`app/(auth)/login/page.tsx`:

```typescript
// app/(auth)/login/page.tsx
import type { Metadata } from "next";

export const metadata: Metadata = { title: "Masuk" };

export default function LoginPage() {
  return (
    <div className="text-center">
      <h1 className="text-2xl font-bold text-gray-900 mb-2">Masuk ke Akun</h1>
      <p className="text-gray-500 text-sm">Akan diimplementasikan di Part 5</p>
    </div>
  );
}
```

`app/(auth)/register/page.tsx`:

```typescript
// app/(auth)/register/page.tsx
import type { Metadata } from "next";

export const metadata: Metadata = { title: "Daftar" };

export default function RegisterPage() {
  return (
    <div className="text-center">
      <h1 className="text-2xl font-bold text-gray-900 mb-2">Buat Akun Baru</h1>
      <p className="text-gray-500 text-sm">Akan diimplementasikan di Part 4</p>
    </div>
  );
}
```

`app/(dashboard)/dashboard/page.tsx`:

```typescript
// app/(dashboard)/dashboard/page.tsx
import type { Metadata } from "next";

export const metadata: Metadata = { title: "Dashboard" };

export default function DashboardPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
      <p className="text-gray-500 mt-1">Akan diimplementasikan di Part 6</p>
    </div>
  );
}
```

## Step 7 - Verifikasi Layout System {#step-7}

Jalankan `npm run dev` dan kunjungi:

- `http://localhost:3000/login` → Tampilkan **Auth Layout** (card putih di tengah, background gradient)
- `http://localhost:3000/register` → Auth Layout yang sama
- `http://localhost:3000/dashboard` → Redirect ke `/login` (middleware aktif)

Jika semua routing berperilaku seperti yang diharapkan, layout system sudah bekerja dengan benar.

## Penutup {#penutup}
Di Part 3 ini, kita telah membangun sistem layout yang menjadi tulang punggung visual aplikasi. Dimulai dari utility function `cn()` yang membantu kita menggabungkan class Tailwind tanpa konflik, lalu komponen Button dan Input yang dirancang fleksibel dengan berbagai varian dan state. Di atas itu semua, kita membangun dua layout utama: Auth Layout dengan tampilan kartu minimalis untuk halaman login dan register, serta Dashboard Layout lengkap dengan Navbar yang memiliki dropdown menu dan tombol logout.

Yang menarik untuk diperhatikan adalah bagaimana semua ini bekerja bersama secara otomatis hanya dari struktur folder — kita tidak perlu menulis logika routing secara manual. Next.js App Router menangani semuanya berdasarkan hierarki file yang kita buat.

Di **Part 4**, kita akan mulai mengisi salah satu halaman placeholder ini dengan fungsionalitas nyata: form register yang terhubung langsung ke endpoint `/api/v1/auth/register` di backend Go. Ini adalah langkah pertama di mana frontend dan backend kita akan mulai "berbicara" satu sama lain.