---
title: "Tutorial Next.js Authentication dengan Next.js dan Go API — PART 6: Menampilkan User di Halaman Dashboard"
slug: "tutorial-nextjs-authentication-dengan-nextjs-dan-go-api-part-6-menampilkan-user-di-halaman-dashboard"
category: "Next.js"
date: "2026-02-21"
status: "published"
---

Pada Part 6 ini, kita akan membangun halaman yang paling "terlihat" oleh pengguna sejauh ini: dashboard. Setelah semua infrastruktur autentikasi yang kita bangun di part-part sebelumnya, sekarang saatnya kita memanfaatkan semua itu untuk menampilkan data yang nyata. Halaman dashboard kita akan menjadi Server Component yang mengambil data dari dua sumber sekaligus — session NextAuth.js untuk data yang sudah tersimpan sejak login, dan endpoint `/api/v1/profile` di backend Go untuk data yang selalu segar dari database. Kita juga akan belajar bagaimana merancang strategi fallback yang elegan ketika salah satu sumber data tidak tersedia.


- [Overview](#overview)
- [Step 1 - Membuat Komponen StatsCard](#step-1)
- [Step 2 - Membuat Komponen UserProfileCard](#step-2)
- [Step 3 - Membuat Halaman Dashboard](#step-3)
- [Step 4 - Uji Coba Halaman Dashboard](#step-4)
- [Penutup](#penutup)

## Overview {#overview}

Sebelum kita tulis satu baris kode pun, ada pertanyaan desain yang perlu kita jawab terlebih dahulu: dari mana seharusnya data user kita ambil?

Jawabannya tidak sesederhana "selalu ambil dari API" atau "selalu pakai session." Keduanya memiliki karakteristik yang berbeda, dan memahami perbedaan ini akan membantu kita membuat keputusan yang lebih baik tidak hanya di sini, tetapi di seluruh bagian aplikasi yang akan kita bangun.

Data dari session NextAuth.js tersedia secara instan tanpa perlu request tambahan ke server mana pun — data ini sudah ada di dalam token JWT yang disimpan di cookie. Keunggulannya jelas: sangat cepat. Kelemahannya: data ini adalah "foto" kondisi user saat login. Jika nama atau email user berubah setelah login, session tidak akan mencerminkan perubahan itu sampai user login ulang.

Data dari backend API, di sisi lain, selalu mencerminkan kondisi terkini di database. Setiap kali kita memanggil `/api/v1/profile`, kita mendapatkan data yang paling mutakhir. Kelemahannya: setiap pemanggilan membutuhkan network request, dan request itu bisa gagal karena berbagai alasan — backend sedang down, jaringan bermasalah, token kedaluwarsa, dan sebagainya.

Strategi yang kita pilih menggabungkan keduanya dengan cara yang pragmatis: kita utamakan data dari backend API karena lebih akurat, tetapi jika pemanggilan API gagal karena alasan apapun, kita tidak langsung menampilkan halaman error — kita *gracefully* jatuh kembali ke data session yang sudah ada. Pengguna tetap bisa melihat dashboardnya meskipun backend sedang bermasalah sesaat.

Satu hal lagi yang perlu dipahami adalah pilihan kita menggunakan **Server Component** untuk halaman dashboard ini. Di Next.js App Router, Server Component dirender di server sebelum HTML dikirim ke browser. Ini berarti kita bisa langsung memanggil `auth()` dan melakukan `fetch` ke backend tanpa perlu memikirkan loading state, tanpa useEffect, dan tanpa data yang "terlambat muncul" di layar. Data sudah siap saat HTML pertama kali tiba di browser pengguna. Untuk Client Component yang membutuhkan akses session — misalnya komponen yang merespons interaksi pengguna — kita akan menggunakan hook `useSession()` dari `next-auth/react`. Tapi untuk halaman statis seperti dashboard ini, Server Component adalah pilihan yang lebih efisien.

## Step 1 - Membuat Komponen StatsCard {#step-1}

Buat file `components/dashboard/StatsCard.tsx`:

```typescript
// components/dashboard/StatsCard.tsx
interface StatsCardProps {
  title: string;
  value: string;
  description: string;
  icon: React.ReactNode;
  color: "green" | "blue" | "purple";
}

const colorMap = {
  green: {
    wrapper: "bg-green-50 border border-green-100",
    icon: "bg-green-100 text-green-600",
    value: "text-green-700",
  },
  blue: {
    wrapper: "bg-blue-50 border border-blue-100",
    icon: "bg-blue-100 text-blue-600",
    value: "text-blue-700",
  },
  purple: {
    wrapper: "bg-purple-50 border border-purple-100",
    icon: "bg-purple-100 text-purple-600",
    value: "text-purple-700",
  },
};

export default function StatsCard({
  title,
  value,
  description,
  icon,
  color,
}: StatsCardProps) {
  const colors = colorMap[color];

  return (
    <div className={`${colors.wrapper} rounded-xl p-5 shadow-sm`}>
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-gray-600 font-medium">{title}</p>
          <p className={`text-2xl font-bold mt-1 ${colors.value}`}>{value}</p>
          <p className="text-xs text-gray-500 mt-1">{description}</p>
        </div>
        <div className={`${colors.icon} p-2.5 rounded-lg`}>{icon}</div>
      </div>
    </div>
  );
}
```

## Step 2 - Membuat Komponen UserProfileCard {#step-2}

Buat file `components/dashboard/UserProfileCard.tsx`:

```typescript
// components/dashboard/UserProfileCard.tsx
import { formatDate } from "@/lib/utils";

interface UserProfile {
  id: number;
  name: string;
  email: string;
  created_at: string;
}

export default function UserProfileCard({ profile }: { profile: UserProfile }) {
  const getInitials = (name: string) =>
    name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2);

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
      {/* Header gradient */}
      <div className="h-24 bg-gradient-to-r from-primary-500 to-primary-700" />

      <div className="px-6 pb-6">
        {/* Avatar */}
        <div className="-mt-12 mb-4">
          <div className="w-20 h-20 rounded-2xl bg-white shadow-md border-4 border-white flex items-center justify-center">
            <span className="text-2xl font-bold text-primary-600">
              {getInitials(profile.name)}
            </span>
          </div>
        </div>

        {/* Nama & Email */}
        <div className="mb-4">
          <h2 className="text-xl font-bold text-gray-900">{profile.name}</h2>
          <p className="text-sm text-gray-500">{profile.email}</p>
        </div>

        {/* Detail */}
        <div className="border-t border-gray-100 pt-4">
          <dl className="space-y-3">
            <InfoRow label="User ID" value={`#${profile.id}`} />
            <InfoRow label="Email" value={profile.email} />
            <InfoRow label="Bergabung" value={formatDate(profile.created_at)} />
          </dl>
        </div>

        {/* Badge */}
        <div className="mt-4 flex items-center gap-2">
          <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-green-100 text-green-700 text-xs font-medium">
            <span className="w-1.5 h-1.5 rounded-full bg-green-500" />
            Akun Aktif
          </span>
          <span className="inline-flex items-center px-3 py-1 rounded-full bg-blue-100 text-blue-700 text-xs font-medium">
            User
          </span>
        </div>
      </div>
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between py-2 border-b border-gray-50 last:border-0">
      <dt className="text-sm text-gray-500">{label}</dt>
      <dd className="text-sm font-medium text-gray-900 truncate ml-2 max-w-[180px]">
        {value}
      </dd>
    </div>
  );
}
```

## Step 3 - Membuat Halaman Dashboard {#step-3}

Perbarui `app/(dashboard)/dashboard/page.tsx`:

```typescript
// app/(dashboard)/dashboard/page.tsx
import type { Metadata } from "next";
import { auth } from "@/auth";
import { redirect } from "next/navigation";
import UserProfileCard from "@/components/dashboard/UserProfileCard";
import StatsCard from "@/components/dashboard/StatsCard";

export const metadata: Metadata = {
  title: "Dashboard",
};

// Tipe data profil dari backend
interface UserProfileData {
  id: number;
  name: string;
  email: string;
  created_at: string;
}

// Fetch data profil dari backend Go menggunakan JWT token
async function fetchUserProfile(accessToken: string): Promise<UserProfileData | null> {
  try {
    const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/profile`, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      // Tidak di-cache karena data profil bisa berubah
      cache: "no-store",
    });

    if (!response.ok) return null;

    const data = await response.json();
    return data.user;
  } catch {
    return null;
  }
}

export default async function DashboardPage() {
  const session = await auth();

  if (!session) redirect("/login");

  // Ambil data terbaru dari backend
  const userProfile = await fetchUserProfile(session.accessToken);

  // Fallback ke data session jika API call gagal
  const profile = userProfile ?? {
    id: parseInt(session.user.id),
    name: session.user.name ?? "",
    email: session.user.email ?? "",
    created_at: new Date().toISOString(),
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">
          Selamat Datang, {session.user.name?.split(" ")[0]}! 👋
        </h1>
        <p className="text-gray-500 mt-1">Berikut adalah ringkasan akun Anda.</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatsCard
          title="Status Akun"
          value="Aktif"
          description="Akun Anda dalam kondisi baik"
          color="green"
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
        />
        <StatsCard
          title="User ID"
          value={`#${profile.id}`}
          description="Identifikasi unik akun Anda"
          color="blue"
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2" />
            </svg>
          }
        />
        <StatsCard
          title="Session"
          value="JWT"
          description="Token aktif selama 24 jam"
          color="purple"
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
            </svg>
          }
        />
      </div>

      {/* Main Content */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Profil Card */}
        <div className="lg:col-span-1">
          <UserProfileCard profile={profile} />
        </div>

        {/* Info Panel */}
        <div className="lg:col-span-2 space-y-4">
          {/* Session Info */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
            <h3 className="text-base font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <svg className="w-5 h-5 text-primary-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Informasi Session
            </h3>
            <div className="space-y-3">
              <SessionRow label="Nama" value={session.user.name ?? "-"} />
              <SessionRow label="Email" value={session.user.email ?? "-"} />
              <SessionRow label="User ID" value={session.user.id} />
              <SessionRow
                label="Status Token"
                value={
                  <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-green-100 text-green-700 text-xs font-medium">
                    <span className="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse" />
                    Valid
                  </span>
                }
              />
            </div>
          </div>

          {/* Tech Stack */}
          <div className="bg-gradient-to-br from-primary-50 to-blue-50 rounded-2xl border border-primary-100 p-6">
            <h3 className="text-base font-semibold text-gray-900 mb-3">
              🛠️ Tech Stack yang Digunakan
            </h3>
            <div className="grid grid-cols-2 gap-2">
              {[
                { name: "Next.js 16", desc: "Frontend Framework" },
                { name: "React 19", desc: "UI Library" },
                { name: "NextAuth.js v5", desc: "Authentication" },
                { name: "Tailwind CSS v4", desc: "Styling" },
                { name: "Go + Gin", desc: "Backend API" },
                { name: "JWT", desc: "Token Management" },
              ].map((tech) => (
                <div key={tech.name} className="bg-white rounded-lg p-3 border border-primary-100">
                  <p className="text-sm font-semibold text-gray-800">{tech.name}</p>
                  <p className="text-xs text-gray-500">{tech.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// Helper komponen untuk baris info session
function SessionRow({
  label,
  value,
}: {
  label: string;
  value: React.ReactNode;
}) {
  return (
    <div className="flex items-center justify-between py-2 border-b border-gray-50 last:border-0">
      <span className="text-sm text-gray-500">{label}</span>
      <span className="text-sm font-medium text-gray-900">{value}</span>
    </div>
  );
}
```

## Step 4 - Uji Coba Halaman Dashboard {#step-4}

Login dengan akun yang sudah dibuat, lalu akses `http://localhost:3000/dashboard`.

Anda seharusnya melihat:
- **Greeting** dengan nama depan user
- **3 Stats Cards** (Status Akun, User ID, Session)
- **UserProfileCard** dengan avatar inisial, detail profil, dan badge status
- **Session Info Panel** dengan data dari NextAuth.js
- **Tech Stack Panel** dengan daftar teknologi

Untuk memverifikasi data berasal dari backend Go, buka DevTools → Network. Saat halaman di-load, Anda akan melihat request ke `http://localhost:8080/api/v1/profile` dengan header `Authorization: Bearer <token>`.

## Penutup {#penutup}

Di Part 6 ini, kita telah menyatukan banyak konsep yang sudah kita bangun sebelumnya menjadi satu halaman yang fungsional. Server Component dashboard menunjukkan bagaimana Next.js memungkinkan kita melakukan data fetching langsung di server — memanggil `auth()` untuk mendapatkan session, lalu menggunakan token dari session itu untuk memanggil backend Go, semuanya sebelum HTML dikirim ke browser.

Yang menarik untuk direnungkan adalah pola fallback yang kita terapkan. Kita tidak hanya menulis "ambil dari API, selesai" — kita berpikir tentang apa yang terjadi ketika sesuatu tidak berjalan sempurna, dan kita menyiapkan jalan keluarnya. `UserProfileCard` dan `StatsCard` yang kita buat juga dirancang sebagai komponen yang benar-benar reusable, bukan sekadar blok kode yang ditulis satu kali untuk satu tujuan.

Di **Part 7**, kita akan menutup seluruh siklus autentikasi dengan mengimplementasikan proses logout lengkap dengan modal konfirmasi, lalu melakukan pengujian end-to-end dari awal hingga akhir untuk memastikan semua alur — register, login, akses dashboard, hingga logout — bekerja sebagaimana mestinya.