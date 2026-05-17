---
title: "Tutorial Next.js Authentication dengan Next.js dan Go API — PART 1:  Membuat Project Next.js"
slug: "tutorial-nextjs-authentication-dengan-nextjs-dan-go-api-part-1-membuat-project-nextjs"
category: "Next.js"
date: "2026-02-20"
status: "published"
---

Selamat datang di series tutorial **Next.js Auth** — panduan lengkap membangun sistem autentikasi frontend menggunakan Next.js yang terintegrasi dengan REST API Go dan Gin framework. Series ini merupakan kelanjutan langsung dari series [Membangun REST API dengan Go dan Gin Framework](https://qadrlabs.com/member/series/membangun-rest-api-dengan-go-dan-gin-framework), sehingga backend API yang sudah kita bangun sebelumnya akan menjadi fondasi yang kita sambungkan dari sisi frontend.

Kita memilih Next.js bukan tanpa alasan. Framework ini hadir dengan fitur-fitur modern seperti App Router, Server Components, dan file-based routing yang membuat pengelolaan halaman menjadi lebih terstruktur. Ditambah dengan **NextAuth.js v5**, urusan seperti JWT token, session management, dan proteksi route bisa diselesaikan dengan cara yang jauh lebih ringkas dibandingkan menulis semuanya dari nol.

Di Part 1 ini, kita tidak langsung melompat ke fitur autentikasi. Kita mulai dari hal yang lebih mendasar: menyiapkan project dari awal, memahami bagaimana App Router mengorganisasi file dan folder, lalu memastikan semua konfigurasi berjalan dengan benar sebelum kita mulai membangun fitur sesungguhnya.

- [Overview Series](#overview)
- [Persiapan](#persiapan)
- [Step 1 - Membuat Project Next.js](#step-1)
- [Step 2 - Memahami Struktur Folder App Router](#step-2)
- [Step 3 - Konfigurasi Environment Variables](#step-3)
- [Step 4 - Memahami dan Mengkonfigurasi Tailwind CSS v4](#step-4)
- [Step 5 - Membuat Halaman Home Sederhana](#step-5)
- [Step 6 - Menjalankan Development Server](#step-6)
- [Penutup](#penutup)

## Overview Series {#overview}
Sebelum masuk ke kode, ada baiknya kita melihat gambaran besar dari apa yang akan kita bangun selama series ini. Memahami keseluruhan peta perjalanan di awal akan membantu kita memahami *mengapa* setiap langkah itu penting, bukan sekadar mengikuti instruksi.

Series ini terbagi menjadi tujuh part yang saling berkesinambungan. **Part 1** (artikel ini) berfokus pada setup project, konfigurasi Tailwind CSS v4, dan memastikan aplikasi bisa berjalan. **Part 2** adalah saat kita mulai menyentuh autentikasi — kita akan menginstall NextAuth.js v5 dengan Credentials Provider dan menghubungkannya ke backend Go API yang sudah ada. **Part 3** membahas sistem layout: bagaimana kita memisahkan tampilan untuk halaman autentikasi (login, register) dengan tampilan untuk halaman yang memerlukan login (dashboard), menggunakan fitur Route Groups dari App Router.

Memasuki **Part 4 dan 5**, kita akan mengimplementasikan dua alur utama: proses register dengan validasi form dan integrasi ke endpoint backend, serta proses login menggunakan fungsi `signIn` dari NextAuth.js beserta penanganan error-nya. Di **Part 6**, kita akan menampilkan data profil user yang diambil dari session dan backend API di halaman dashboard. Terakhir, **Part 7** menutup seluruh siklus dengan implementasi logout dan pengujian end-to-end dari awal hingga akhir.

Adapun teknologi yang akan kita gunakan sepanjang series ini adalah Next.js 16 sebagai React meta-framework, React 19, NextAuth.js v5 untuk manajemen autentikasi, Tailwind CSS v4 dengan pendekatan CSS-first configuration yang baru, TypeScript, serta REST API Go + Gin yang sudah kita bangun di series sebelumnya.

## Persiapan {#persiapan}

Sebelum memulai, pastikan tools berikut sudah terinstall:

1. **Node.js versi 18.17 atau lebih baru** — Verifikasi dengan perintah `node -v` di terminal.

2. **npm** — Sudah terinstall otomatis bersama Node.js. Verifikasi dengan `npm -v`.

3. **VS Code** — Dengan extension [Tailwind CSS IntelliSense](https://marketplace.visualstudio.com/items?itemName=bradlc.vscode-tailwindcss) dan [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint).

4. **Backend Go API** — Pastikan [REST API dari series sebelumnya](https://qadrlabs.com/member/post/rest-api-authentication-dengan-go-dan-gin-part-1) sudah berjalan di `http://localhost:8080`.

```bash
node -v   # v20.x.x atau lebih baru
npm -v    # 10.x.x atau lebih baru
```

## Step 1 - Membuat Project Next.js {#step-1}
Pada tahapan ini kita akan membuat project next js baru. Untuk membuat project baru, buka terminal, lalu kita run command berikut ini:

```bash
npx create-next-app@latest nextjs-auth-app
```
Setelah kita run command di atas, akan tampil prompt. Saat tampil prompt `Would you like to use the recommended Next.js defaults`, pilih `Yes, use recommended defaults`, lalu tekan `enter` untuk melanjutkan.

```
$ npx create-next-app@latest nextjs-auth-app
Need to install the following packages:
create-next-app@16.1.6
Ok to proceed? (y) y

✔ Would you like to use the recommended Next.js defaults? › Yes, use recommended defaults
Creating a new Next.js app in /home/gun-gun-priatna/learning-lab/nextjs/nextjs-auth-app.

Using npm.

Initializing project with template: app-tw 

.
.
.

Initialized a git repository.

Success! Created nextjs-auth-app at /home/gun-gun-priatna/learning-lab/nextjs/nextjs-auth-app

```

Setelah proses create project baru selesai, selanjutnya kita masuk ke direktori project menggunakan command berikut:

```bash
cd nextjs-auth-app
```

Lalu, kita verifikasi versi yang terinstall:

```bash
npm list next react tailwindcss
```

Output yang ditampilkan:
```
nextjs-auth-app
├── next@16.x.x
├── react@19.x.x
└── tailwindcss@4.x.x
```

Sebelum kita lanjutkan kita bahas terlebih dahulu struktur project kita. App Router Next.js menggunakan struktur folder di dalam direktori `app/`. Berikut struktur lengkap yang akan kita bangun selama series ini:

```
nextjs-auth-app/
├── app/
│   ├── (auth)/                  # Route group untuk halaman auth
│   │   ├── login/
│   │   │   └── page.tsx         # Halaman /login
│   │   ├── register/
│   │   │   └── page.tsx         # Halaman /register
│   │   └── layout.tsx           # Layout khusus auth
│   ├── (dashboard)/             # Route group untuk halaman protected
│   │   ├── dashboard/
│   │   │   └── page.tsx         # Halaman /dashboard
│   │   └── layout.tsx           # Layout khusus dashboard
│   ├── api/
│   │   └── auth/
│   │       └── [...nextauth]/
│   │           └── route.ts     # Handler NextAuth.js
│   ├── globals.css              # Global CSS dengan Tailwind v4
│   ├── layout.tsx               # Root layout
│   └── page.tsx                 # Halaman /
├── components/
│   ├── auth/
│   │   ├── LoginForm.tsx
│   │   └── RegisterForm.tsx
│   ├── dashboard/
│   │   ├── UserProfileCard.tsx
│   │   └── StatsCard.tsx
│   ├── providers/
│   │   └── SessionProvider.tsx
│   └── ui/
│       ├── Button.tsx
│       ├── Input.tsx
│       └── ConfirmModal.tsx
├── lib/
│   ├── auth.ts                  # Konfigurasi NextAuth.js
│   ├── api.ts                   # Helper fungsi API
│   ├── utils.ts                 # Utility functions
│   ├── auth-errors.ts           # Error message mapping
│   └── safe-redirect.ts         # Keamanan redirect
├── middleware.ts                 # Route protection
├── types/
│   └── next-auth.d.ts           # TypeScript declarations
└── .env.local                   # Environment variables
```

**Catatan:**
Pada struktur folder di atas terdapat **Konsep Route Groups** atau folder dengan nama dalam tanda kurung seperti `(auth)` dan `(dashboard)` tidak memengaruhi URL path. Folder ini hanya digunakan untuk mengelompokkan halaman yang berbagi layout yang sama.

## Step 2 - Konfigurasi Environment Variables {#step-2}
Pada tahapan ini kita akan atur konfigurasi project kita pada file dotenv. Buka kembali code editor, lalu kita buat file `.env.local` di root project, setelah itu kita tambahkan beberapa environment variable.

```bash
# Backend API URL - sesuaikan dengan port backend Go Anda
NEXT_PUBLIC_API_URL=http://localhost:8080/api/v1

# NextAuth.js Configuration
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-super-secret-nextauth-key-change-this-in-production

# Mode (development/production)
NODE_ENV=development
```

Untuk value `NEXTAUTH_SECRET`, kita bisa generate menggunakan command:

```bash
openssl rand -base64 32
```

Selanjutnya kita tambahkan file dotenv ini ke `.gitignore` menggunakan command.

```bash
echo ".env.local" >> .gitignore
```

## Step 3 - Mengkonfigurasi Tailwind CSS {#step-3}

Tailwind CSS bekerja dengan cara membaca file CSS utama project kita, lalu meng-generate semua utility classes yang dibutuhkan. Seluruh konfigurasi — mulai dari warna, font, hingga tema kustom — didefinisikan langsung di dalam file CSS menggunakan **CSS custom properties** di dalam blok `@theme {}`.

### Verifikasi postcss.config.mjs

Buka file `postcss.config.mjs` di root project dan pastikan isinya adalah:

```javascript
// postcss.config.mjs
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};

export default config;
```

File ini biasanya sudah dikonfigurasi dengan benar oleh `create-next-app`, jadi kita tidak perlu mengubahnya.

### Konfigurasi globals.css

Buka `app/globals.css` dan ganti seluruh isinya dengan konfigurasi berikut:

```css
/* app/globals.css */

/* Mengaktifkan semua utilities Tailwind CSS */
@import "tailwindcss";

/* ============================================
   THEME CUSTOMIZATION
   Warna dan tema kustom didefinisikan di sini
   menggunakan CSS custom properties.
   
   Setelah blok ini, class seperti bg-primary-600,
   text-primary-500, border-primary-300 akan
   tersedia di seluruh komponen.
   ============================================ */
@theme {
  --color-primary-50: oklch(97% 0.01 250);
  --color-primary-100: oklch(93% 0.03 250);
  --color-primary-200: oklch(87% 0.06 250);
  --color-primary-300: oklch(79% 0.10 250);
  --color-primary-400: oklch(70% 0.15 250);
  --color-primary-500: oklch(60% 0.20 250);
  --color-primary-600: oklch(52% 0.22 250);
  --color-primary-700: oklch(44% 0.20 250);
  --color-primary-800: oklch(37% 0.17 250);
  --color-primary-900: oklch(30% 0.13 250);

  --font-sans: var(--font-inter), ui-sans-serif, system-ui, sans-serif;
}

/* ============================================
   BASE STYLES
   Diaplikasikan ke semua elemen HTML
   ============================================ */
@layer base {
  body {
    @apply bg-gray-50 text-gray-900 antialiased;
  }

  * {
    @apply box-border;
  }
}

/* ============================================
   COMPONENT STYLES
   Class reusable untuk elemen yang sering dipakai
   ============================================ */
@layer components {
  .form-input {
    @apply w-full px-3 py-2 border border-gray-300 rounded-lg shadow-sm text-sm
           focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent
           disabled:bg-gray-50 disabled:text-gray-500 disabled:cursor-not-allowed
           transition-colors duration-200;
  }

  .btn-primary {
    @apply w-full flex justify-center py-2.5 px-4 border border-transparent
           rounded-lg shadow-sm text-sm font-medium text-white bg-primary-600
           hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2
           focus:ring-primary-500 disabled:opacity-50 disabled:cursor-not-allowed
           transition-colors duration-200;
  }
}
```

Setelah menyimpan file ini, semua class Tailwind standar seperti `text-gray-900`, `rounded-lg`, `flex`, dan class kustom kita seperti `bg-primary-600` sudah siap digunakan di seluruh komponen.

## Step 4 - Membuat Halaman Home Sederhana {#step-4}
Selanjutnya kita akan membuat halaman home sederhana. Sekarang buka file `app/layout.tsx`, lalu kita sesuaikan untuk setup font Inter:

```typescript
// app/layout.tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

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
      <body>{children}</body>
    </html>
  );
}
```
Save kembali file `app/layout.tsx`.

Selanjutnya kita buka file `app/page.tsx` dan kita sesuaikan menjadi baris kode berikut ini.

```typescript
// app/page.tsx
import Link from "next/link";

export default function HomePage() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-primary-50 to-white px-4">
      <div className="max-w-md w-full text-center space-y-8">
        {/* Icon */}
        <div className="flex justify-center">
          <div className="w-20 h-20 bg-primary-600 rounded-2xl flex items-center justify-center shadow-lg">
            <svg
              className="w-10 h-10 text-white"
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
        </div>

        {/* Heading */}
        <div className="space-y-3">
          <h1 className="text-4xl font-bold text-gray-900">
            Next.js Auth App
          </h1>
          <p className="text-lg text-gray-600">
            Sistem authentication modern dengan Next.js 16, NextAuth.js v5,
            dan REST API Go + Gin.
          </p>
        </div>

        {/* CTA Buttons */}
        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <Link
            href="/login"
            className="px-6 py-3 bg-primary-600 text-white font-semibold rounded-lg
                       hover:bg-primary-700 transition-colors duration-200 shadow-sm"
          >
            Masuk ke Akun
          </Link>
          <Link
            href="/register"
            className="px-6 py-3 bg-white text-primary-600 font-semibold rounded-lg
                       border-2 border-primary-600 hover:bg-primary-50
                       transition-colors duration-200"
          >
            Buat Akun Baru
          </Link>
        </div>

        {/* Tech Stack */}
        <div className="pt-8 border-t border-gray-200">
          <p className="text-sm text-gray-500 mb-3">Built with</p>
          <div className="flex flex-wrap justify-center gap-2">
            {[
              "Next.js 16",
              "React 19",
              "NextAuth.js v5",
              "Tailwind CSS v4",
              "Go + Gin API",
            ].map((tech) => (
              <span
                key={tech}
                className="px-3 py-1 bg-gray-100 text-gray-700 text-xs font-medium rounded-full"
              >
                {tech}
              </span>
            ))}
          </div>
        </div>
      </div>
    </main>
  );
}
```
Apabila sudah selesai, jangan lupa save kembali file `app/page.tsx` .

## Step 5 - Menjalankan Development Server {#step-5}
Sekarang kita akan coba run project kita. Buka kembali terminal, lalu run command berikut ini untuk menjalankan development server.
```bash
npm run dev
```

Output yang ditampilkan:

```
$ npm run dev

> nextjs-auth-app@0.1.0 dev
> next dev

▲ Next.js 16.1.6 (Turbopack)
- Local:         http://localhost:3000
- Network:       http://172.20.10.10:3000
- Environments: .env.local

✓ Starting...
✓ Ready in 682ms

```

Buka browser dan akses `http://localhost:3000`. Anda akan melihat halaman home dengan background gradient biru muda, icon kunci, heading, dan dua tombol navigasi ke halaman login dan register.

Beberapa hal yang berguna saat development:

**Hot Module Replacement (HMR)** — Setiap kali menyimpan perubahan pada file, Next.js secara otomatis me-reload hanya bagian yang berubah tanpa full page reload.

**Fast Refresh** — React state dipertahankan saat komponen di-refresh, sehingga Anda tidak perlu mengisi ulang form saat mengubah styling.

**TypeScript Error Overlay** — Jika ada error TypeScript, Next.js menampilkannya langsung di browser dengan pesan yang jelas.

## Penutup {#penutup}

Di Part 1 ini, kita telah meletakkan fondasi yang solid untuk keseluruhan project. Dimulai dari pembuatan project dengan `create-next-app`, kita memahami bagaimana App Router mengorganisasi aplikasi melalui struktur folder — termasuk konsep Route Groups yang akan sangat berguna di Part 3 nanti. Kita juga mengkonfigurasi `.env.local` untuk menyimpan URL backend API dan secret key NextAuth.js secara aman, lalu menyesuaikan Tailwind CSS v4 dengan pendekatan `@theme {}` yang memungkinkan kita mendefinisikan warna kustom seperti `bg-primary-600` langsung dari file CSS. Semua itu ditutup dengan halaman home sederhana sebagai titik masuk aplikasi.

Yang paling penting dari Part 1 ini bukan hanya "aplikasi bisa jalan", melainkan kita sudah memiliki pemahaman tentang *mengapa* setiap konfigurasi itu ada. Fondasi yang dipahami dengan baik akan membuat langkah-langkah berikutnya terasa jauh lebih masuk akal.

Di **Part 2**, kita akan mulai menyentuh inti dari series ini: menginstall dan mengkonfigurasi **NextAuth.js v5** dengan Credentials Provider, lalu menghubungkannya ke backend Go API sehingga proses autentikasi benar-benar berfungsi dari ujung ke ujung.