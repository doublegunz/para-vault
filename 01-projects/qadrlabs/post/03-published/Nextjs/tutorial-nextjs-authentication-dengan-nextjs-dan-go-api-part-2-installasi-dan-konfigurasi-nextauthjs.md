---
title: "Tutorial Next.js Authentication dengan Next.js dan Go API — PART 2: Installasi dan Konfigurasi NextAuth.js"
slug: "tutorial-nextjs-authentication-dengan-nextjs-dan-go-api-part-2-installasi-dan-konfigurasi-nextauthjs"
category: "Next.js"
date: "2026-02-20"
status: "published"
---

Pada Part 2 ini, kita akan membangun inti dari seluruh sistem autentikasi, infrastruktur yang menghubungkan frontend Next.js kita dengan backend Go API yang sudah ada. Kita akan menginstall dan mengkonfigurasi **NextAuth.js v5 (Auth.js)**, menggunakan **Credentials Provider** sebagai jembatan antara form login di frontend dengan endpoint `/api/v1/auth/login` di backend. Setelah part ini selesai, kita akan memiliki fondasi autentikasi yang solid, token dari backend tersimpan aman di session, routes terlindungi secara otomatis, dan komponen di seluruh aplikasi bisa mengakses data user tanpa kerumitan tambahan.

- [Overview](#overview)
- [Step 1 - Install NextAuth.js dan Dependencies](#step-1)
- [Step 2 - Membuat Konfigurasi Auth](#step-2)
- [Step 3 - Membuat Route Handler](#step-3)
- [Step 4 - Konfigurasi TypeScript Types](#step-4)
- [Step 5 - Setup Proxy Route Protection](#step-5)
- [Step 6 - Menambahkan SessionProvider](#step-6)
- [Step 7 - Verifikasi Konfigurasi](#step-7)
- [Penutup](#penutup)

## Overview {#overview}
Sebelum mulai menulis kode, penting untuk memahami *mengapa* kita perlu NextAuth.js dan apa yang sebetulnya terjadi di balik layar ketika user melakukan login.

Tantangan utama dalam autentikasi berbasis JWT adalah token dari backend perlu disimpan di suatu tempat yang aman, dan setiap request ke API berikutnya harus menyertakan token tersebut. Jika kita melakukan semua ini secara manual, kita perlu menangani penyimpanan token, pengecekan kedaluwarsa, pengelolaan session, hingga proteksi route, semuanya dari nol. NextAuth.js v5 menangani semua kerumitan itu, sehingga kita bisa fokus pada logika bisnis aplikasi.

Versi 5 ini (yang resmi bernama **Auth.js**) membawa beberapa perubahan penting dibanding v4. Pertama, seluruh konfigurasi kini dipusatkan di satu file `auth.ts` di root project, tidak ada lagi konfigurasi yang tersebar di berbagai tempat. Kedua, ada dukungan Edge Runtime, yang berarti middleware proteksi route bisa berjalan lebih cepat di CDN edge sebelum request bahkan sampai ke server. Ketiga, Credentials Provider memungkinkan kita menghubungkan proses autentikasi ke REST API kustom mana pun, dalam kasus kita, backend Go yang sudah kita bangun sebelumnya.

Alur lengkapnya bekerja seperti ini: user mengisi form login dan menekan tombol masuk → NextAuth.js memanggil fungsi `authorize` di Credentials Provider → fungsi tersebut memanggil endpoint `/api/v1/auth/login` di backend Go → jika berhasil, JWT token dari backend dikembalikan bersama data user → token disimpan di dalam session NextAuth.js → dan mulai saat itu, setiap kali komponen atau middleware perlu memverifikasi identitas user, mereka cukup membaca session tanpa perlu memanggil backend lagi.

## Step 1 - Install NextAuth.js dan Dependencies {#step-1}

Install NextAuth.js v5 dan package tambahan yang dibutuhkan:

```bash
# NextAuth.js v5 (masih beta, sudah stabil untuk production)
npm install next-auth@beta

# Utility untuk menggabungkan class names Tailwind
npm install clsx tailwind-merge
```

Verifikasi instalasi berhasil:

```bash
npm list next-auth
# Harus menampilkan: next-auth@5.0.0-beta.x
```

## Step 2 - Membuat Konfigurasi Auth {#step-2}

Buat file `auth.ts` di root project (sejajar dengan `package.json`):

```typescript
// auth.ts
import NextAuth from "next-auth";
import Credentials from "next-auth/providers/credentials";

// Tipe untuk response login dari backend Go
interface BackendUser {
  id: number;
  name: string;
  email: string;
  created_at: string;
}

interface LoginResponse {
  message: string;
  user: BackendUser;
  token: string;
}

export const { handlers, signIn, signOut, auth } = NextAuth({
  providers: [
    Credentials({
      name: "credentials",
      credentials: {
        email: {
          label: "Email",
          type: "email",
          placeholder: "john@example.com",
        },
        password: {
          label: "Password",
          type: "password",
        },
      },

      // Fungsi ini dipanggil setiap kali user mencoba login
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          throw new Error("Email dan password wajib diisi");
        }

        try {
          // Panggil endpoint login backend Go
          const response = await fetch(
            `${process.env.NEXT_PUBLIC_API_URL}/auth/login`,
            {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                email: credentials.email,
                password: credentials.password,
              }),
            }
          );

          if (!response.ok) {
            const errorData = await response.json();
            throw new Error(
              errorData.message || "Email atau password tidak valid"
            );
          }

          const data: LoginResponse = await response.json();

          // Kembalikan user object yang akan disimpan di session
          return {
            id: String(data.user.id),
            name: data.user.name,
            email: data.user.email,
            // Simpan JWT token backend agar bisa dipakai untuk request API
            accessToken: data.token,
          };
        } catch (error) {
          if (error instanceof Error) {
            throw new Error(error.message);
          }
          throw new Error("Terjadi kesalahan saat login");
        }
      },
    }),
  ],

  // Gunakan JWT strategy untuk menyimpan session
  session: {
    strategy: "jwt",
    maxAge: 24 * 60 * 60, // 24 jam, sesuai JWT backend
  },

  callbacks: {
    // Dipanggil saat JWT token dibuat/diperbarui
    // Simpan accessToken dari backend ke dalam JWT NextAuth
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id;
        token.accessToken = (user as any).accessToken;
      }
      return token;
    },

    // Dipanggil saat session diakses dari komponen
    // Expose data JWT ke session object
    async session({ session, token }) {
      if (token) {
        session.user.id = token.id as string;
        session.accessToken = token.accessToken as string;
      }
      return session;
    },
  },

  // Arahkan ke halaman login kustom kita
  pages: {
    signIn: "/login",
    error: "/login",
  },
});
```

## Step 3 - Membuat Route Handler {#step-3}

Buat folder `app/api/auth/[...nextauth]` dan file `app/api/auth/[...nextauth]/route.ts`:

```typescript
// app/api/auth/[...nextauth]/route.ts
import { handlers } from "@/auth";

export const { GET, POST } = handlers;
```

File ini menangani semua request ke `/api/auth/*` seperti `/api/auth/session`, `/api/auth/csrf`, dan callback setelah login.

## Step 4 - Konfigurasi TypeScript Types {#step-4}

Buat folder `types` dan file `types/next-auth.d.ts`:

```typescript
// types/next-auth.d.ts
import "next-auth";

// Tambahkan field kustom ke Session agar TypeScript tidak error
declare module "next-auth" {
  interface Session {
    user: {
      id: string;
      name?: string | null;
      email?: string | null;
      image?: string | null;
    };
    // JWT token dari backend Go
    accessToken: string;
  }

  interface User {
    accessToken?: string;
  }
}

// Tambahkan field kustom ke JWT
declare module "next-auth/jwt" {
  interface JWT {
    id?: string;
    accessToken?: string;
  }
}
```

Tambahkan path `types` ke `tsconfig.json` agar TypeScript menemukan deklarasi ini:

```json
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts",
    "types/**/*.d.ts"
  ],
  "exclude": ["node_modules"]
}
```

## Step 5 - Setup Proxy Route Protection {#step-5}

Di Next.js 16, route protection ditangani oleh file `proxy.ts` di root project. File ini berjalan di depan setiap request yang masuk dan memungkinkan kita melindungi routes secara otomatis berdasarkan status authentication.

Buat file `proxy.ts` di root project:

```typescript
// proxy.ts
import { auth } from "@/auth";
import { NextResponse } from "next/server";

export default auth((req) => {
  const { pathname } = req.nextUrl;
  const isAuthenticated = !!req.auth;

  // Routes yang memerlukan login
  const protectedRoutes = ["/dashboard"];

  // Routes yang hanya bisa diakses tanpa login
  const authRoutes = ["/login", "/register"];

  const isProtectedRoute = protectedRoutes.some((route) =>
    pathname.startsWith(route)
  );
  const isAuthRoute = authRoutes.some((route) =>
    pathname.startsWith(route)
  );

  // Belum login + akses halaman protected → redirect ke login
  if (isProtectedRoute && !isAuthenticated) {
    const loginUrl = new URL("/login", req.url);
    loginUrl.searchParams.set("callbackUrl", pathname);
    return NextResponse.redirect(loginUrl);
  }

  // Sudah login + akses halaman auth → redirect ke dashboard
  if (isAuthRoute && isAuthenticated) {
    return NextResponse.redirect(new URL("/dashboard", req.url));
  }

  return NextResponse.next();
});

// Tentukan routes mana saja yang dijalankan proxy ini
export const config = {
  matcher: [
    "/((?!api/auth|_next/static|_next/image|favicon.ico).*)",
  ],
};
```

## Step 6 - Menambahkan SessionProvider {#step-6}

`SessionProvider` adalah client component, jadi kita perlu membuat wrapper khusus. Buat file `components/providers/SessionProvider.tsx`:

```typescript
// components/providers/SessionProvider.tsx
"use client";

import { SessionProvider } from "next-auth/react";

export default function AuthProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  return <SessionProvider>{children}</SessionProvider>;
}
```

Perbarui `app/layout.tsx` untuk menggunakan provider ini:

```typescript
// app/layout.tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import AuthProvider from "@/components/providers/SessionProvider";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
});

export const metadata: Metadata = {
  title: {
    default: "Next.js Auth App",
    template: "%s | Next.js Auth App",
  },
  description: "Aplikasi authentication dengan Next.js dan NextAuth.js",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="id" className={inter.variable}>
      <body>
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
```

## Step 7 - Verifikasi Konfigurasi {#step-7}

Jalankan development server:

```bash
npm run dev
```

Pastikan tidak ada error di terminal. Kemudian buka browser dan akses:

**`http://localhost:3000/api/auth/providers`** — Harus menampilkan JSON:

```json
{
  "credentials": {
    "id": "credentials",
    "name": "credentials",
    "type": "credentials",
    "signinUrl": "http://localhost:3000/api/auth/signin/credentials",
    "callbackUrl": "http://localhost:3000/api/auth/callback/credentials"
  }
}
```

**`http://localhost:3000/api/auth/session`** — Harus menampilkan `{}` karena belum login.

**`http://localhost:3000/dashboard`** — Harus redirect ke `/login` karena proxy aktif.

Pastikan struktur file sudah sesuai:

```
nextjs-auth-app/
├── auth.ts                              ✓
├── proxy.ts                              ✓
├── app/
│   ├── api/auth/[...nextauth]/route.ts  ✓
│   └── layout.tsx                       ✓ (sudah ada AuthProvider)
├── components/providers/
│   └── SessionProvider.tsx              ✓
└── types/
    └── next-auth.d.ts                   ✓
```

## Penutup {#penutup}


Di Part 2 ini, kita telah membangun seluruh tulang punggung sistem autentikasi. Dimulai dari konfigurasi `auth.ts` yang menghubungkan Credentials Provider ke backend Go, lalu JWT callbacks yang memastikan token dari backend tersimpan dengan benar di dalam session NextAuth.js. Kita juga membuat route handler agar semua permintaan ke `/api/auth/*` ditangani dengan benar, TypeScript declarations agar field kustom seperti `accessToken` dikenali oleh compiler, middleware yang secara otomatis melindungi routes tanpa perlu pengecekan manual di setiap halaman, dan terakhir SessionProvider agar komponen client bisa mengakses data session di mana saja.

Yang menarik untuk direnungkan adalah bagaimana semua bagian ini bekerja sebagai satu kesatuan: middleware berjalan paling awal untuk menjaga akses, `auth.ts` menjadi sumber kebenaran tunggal untuk seluruh konfigurasi, dan SessionProvider menjadi jembatan antara dunia server (session JWT) dengan dunia client (React components).

Di **Part 3**, kita akan beralih ke tampilan — membangun **sistem layout** dengan Auth Layout untuk halaman login dan register, serta Dashboard Layout lengkap dengan Navbar untuk halaman-halaman yang memerlukan login.