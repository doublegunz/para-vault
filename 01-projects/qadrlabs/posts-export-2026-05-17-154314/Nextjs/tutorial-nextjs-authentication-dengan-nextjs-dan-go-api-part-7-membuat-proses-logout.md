---
title: "Tutorial Next.js Authentication dengan Next.js dan Go API — PART 7: Membuat Proses Logout"
slug: "tutorial-nextjs-authentication-dengan-nextjs-dan-go-api-part-7-membuat-proses-logout"
category: "Next.js"
date: "2026-02-21"
status: "published"
---

Pada Part 7 ini, kita menutup siklus autentikasi yang sudah kita bangun sejak Part 1 dengan mengimplementasikan satu fitur terakhir: proses logout. Meskipun terdengar sederhana, logout yang dirancang dengan baik melibatkan beberapa lapisan pertimbangan, dari pengalaman pengguna (modal konfirmasi agar tidak ada logout yang tidak disengaja), hingga alur navigasi yang mulus setelah sesi berakhir. Setelah logout selesai, kita akan melakukan pengujian end-to-end untuk memverifikasi bahwa seluruh alur autentikasi dari register, login, proteksi route, hingga logout bekerja sebagaimana mestinya sebagai satu kesatuan yang utuh.

- [Overview](#overview)
- [Step 1 - Membuat Modal Konfirmasi](#step-1)
- [Step 2 - Memperbarui Navbar dengan Modal](#step-2)
- [Step 3 - Membuat Halaman Sukses Logout](#step-3)
- [Step 4 - Pengujian End-to-End](#step-4)
- [Step 5 - Checklist Sebelum Production](#step-5)
- [Penutup Series](#penutup)

## Overview {#overview}
Sebelum kita tulis kode logout, ada satu hal penting yang perlu kita pahami tentang cara kerja `signOut` di NextAuth.js — dan mengapa pemahaman ini relevan untuk keamanan aplikasi kita.

Ketika `signOut()` dipanggil, NextAuth.js melakukan dua hal: menghapus cookie session dari browser dan menginvalidasi JWT token milik NextAuth.js itu sendiri. Setelah ini, middleware kita akan mendeteksi bahwa tidak ada session yang valid dan secara otomatis menolak akses ke route-route yang dilindungi. Dari sudut pandang pengguna dan dari sudut pandang frontend, logout sudah selesai dan bekerja sempurna.

Namun ada nuansa penting yang perlu disadari: `signOut` *tidak* menginvalidasi JWT token yang dikeluarkan oleh backend Go kita. Ingat, di Part 2 kita menyimpan `accessToken` dari backend Go ke dalam session NextAuth.js. Token Go itu bersifat *stateless* — begitu dikeluarkan, backend tidak menyimpan daftarnya di mana pun dan tidak bisa "mencabutnya" dari jarak jauh. Token itu akan tetap valid hingga masa kedaluwarsanya (24 jam) meskipun pengguna sudah logout dari frontend. Dalam praktiknya untuk aplikasi ini, ini bukan masalah besar karena token itu disimpan hanya di dalam session NextAuth.js yang sudah kita hapus. Tapi untuk aplikasi dengan kebutuhan keamanan yang lebih tinggi di production, solusinya adalah mengimplementasikan *token blacklist* di sisi backend — sebuah daftar token yang sudah dinonaktifkan yang dicek setiap kali ada request masuk.

Adapun cara memanggil `signOut` berbeda tergantung di mana kita berada. Di Client Component, kita mengimport dari `next-auth/react`. Di Server Action, kita mengimport dari file `auth.ts` kita sendiri. Dalam implementasi kita, logout dipicu dari Navbar yang merupakan Client Component, sehingga kita akan menggunakan versi pertama.

## Step 1 - Membuat Modal Konfirmasi {#step-1}

Buat file `components/ui/ConfirmModal.tsx`:

```typescript
// components/ui/ConfirmModal.tsx
"use client";

import { useEffect } from "react";
import Button from "./Button";

interface ConfirmModalProps {
  isOpen: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  onConfirm: () => void;
  onCancel: () => void;
  isLoading?: boolean;
  variant?: "danger" | "warning";
}

export default function ConfirmModal({
  isOpen,
  title,
  message,
  confirmLabel = "Konfirmasi",
  cancelLabel = "Batal",
  onConfirm,
  onCancel,
  isLoading = false,
  variant = "danger",
}: ConfirmModalProps) {
  // Tutup modal dengan tombol Escape
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === "Escape" && isOpen && !isLoading) onCancel();
    };
    document.addEventListener("keydown", handleEscape);
    return () => document.removeEventListener("keydown", handleEscape);
  }, [isOpen, isLoading, onCancel]);

  // Cegah scroll saat modal terbuka
  useEffect(() => {
    document.body.style.overflow = isOpen ? "hidden" : "";
    return () => {
      document.body.style.overflow = "";
    };
  }, [isOpen]);

  if (!isOpen) return null;

  const iconColors = {
    danger: { bg: "bg-red-100", text: "text-red-600" },
    warning: { bg: "bg-yellow-100", text: "text-yellow-600" },
  };
  const colors = iconColors[variant];

  return (
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50"
        onClick={!isLoading ? onCancel : undefined}
        aria-hidden="true"
      />

      {/* Modal */}
      <div
        className="fixed inset-0 z-50 flex items-center justify-center p-4"
        role="dialog"
        aria-modal="true"
        aria-labelledby="modal-title"
      >
        <div className="bg-white rounded-2xl shadow-2xl max-w-sm w-full p-6">
          {/* Icon */}
          <div className="flex justify-center mb-4">
            <div className={`w-14 h-14 ${colors.bg} rounded-full flex items-center justify-center`}>
              <svg
                className={`w-7 h-7 ${colors.text}`}
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
                />
              </svg>
            </div>
          </div>

          {/* Content */}
          <div className="text-center mb-6">
            <h3 id="modal-title" className="text-lg font-bold text-gray-900 mb-2">
              {title}
            </h3>
            <p className="text-sm text-gray-600">{message}</p>
          </div>

          {/* Actions */}
          <div className="flex gap-3">
            <Button
              variant="secondary"
              onClick={onCancel}
              disabled={isLoading}
              className="flex-1"
            >
              {cancelLabel}
            </Button>
            <Button
              variant="danger"
              onClick={onConfirm}
              isLoading={isLoading}
              className="flex-1"
            >
              {confirmLabel}
            </Button>
          </div>
        </div>
      </div>
    </>
  );
}
```

## Step 2 - Memperbarui Navbar dengan Modal {#step-2}

Perbarui `components/Navbar.tsx` untuk menggunakan modal konfirmasi sebelum logout:

```typescript
// components/Navbar.tsx
"use client";

import { signOut } from "next-auth/react";
import Link from "next/link";
import { useState } from "react";
import ConfirmModal from "@/components/ui/ConfirmModal";

interface NavbarProps {
  user: {
    name?: string | null;
    email?: string | null;
  };
}

export default function Navbar({ user }: NavbarProps) {
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [isLogoutModalOpen, setIsLogoutModalOpen] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);

  const getInitials = (name: string | null | undefined) => {
    if (!name) return "?";
    return name.split(" ").map((n) => n[0]).join("").toUpperCase().slice(0, 2);
  };

  // Buka modal — jangan langsung logout
  const handleLogoutClick = () => {
    setIsDropdownOpen(false);
    setIsLogoutModalOpen(true);
  };

  // Eksekusi logout setelah dikonfirmasi
  const handleLogoutConfirm = async () => {
    setIsLoggingOut(true);
    try {
      await signOut({ callbackUrl: "/login" });
    } catch {
      setIsLoggingOut(false);
      setIsLogoutModalOpen(false);
    }
  };

  return (
    <>
      <nav className="bg-white border-b border-gray-200 shadow-sm sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            {/* Logo */}
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
                <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              </div>
              <Link href="/dashboard" className="text-lg font-semibold text-gray-900 hover:text-primary-600 transition-colors">
                Auth App
              </Link>
            </div>

            {/* Nav */}
            <div className="hidden md:flex items-center gap-1">
              <Link href="/dashboard" className="px-3 py-2 text-sm font-medium text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors">
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
                <svg className={`w-4 h-4 text-gray-500 transition-transform ${isDropdownOpen ? "rotate-180" : ""}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                </svg>
              </button>

              {isDropdownOpen && (
                <>
                  <div className="fixed inset-0 z-10" onClick={() => setIsDropdownOpen(false)} />
                  <div className="absolute right-0 mt-2 w-56 bg-white rounded-xl shadow-lg border border-gray-100 z-20 overflow-hidden">
                    <div className="px-4 py-3 bg-gray-50 border-b border-gray-100">
                      <p className="text-sm font-semibold text-gray-900 truncate">{user.name}</p>
                      <p className="text-xs text-gray-500 truncate">{user.email}</p>
                    </div>
                    <div className="py-1">
                      <Link href="/dashboard" className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition-colors" onClick={() => setIsDropdownOpen(false)}>
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                        </svg>
                        Dashboard
                      </Link>
                    </div>
                    <div className="border-t border-gray-100 py-1">
                      {/* Sekarang membuka modal, bukan langsung logout */}
                      <button
                        onClick={handleLogoutClick}
                        className="w-full flex items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50 transition-colors"
                      >
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                        </svg>
                        Keluar
                      </button>
                    </div>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      </nav>

      {/* Modal Konfirmasi Logout */}
      <ConfirmModal
        isOpen={isLogoutModalOpen}
        title="Konfirmasi Keluar"
        message="Apakah Anda yakin ingin keluar? Sesi Anda akan berakhir dan Anda perlu masuk kembali untuk mengakses aplikasi."
        confirmLabel="Ya, Keluar"
        cancelLabel="Batal"
        onConfirm={handleLogoutConfirm}
        onCancel={() => setIsLogoutModalOpen(false)}
        isLoading={isLoggingOut}
        variant="danger"
      />
    </>
  );
}
```

## Step 3 - Membuat Halaman Sukses Logout {#step-3}

Buat file `app/(auth)/logout/page.tsx` sebagai halaman yang ditampilkan setelah logout, sebelum redirect ke login:

```typescript
// app/(auth)/logout/page.tsx
"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";

export default function LogoutSuccessPage() {
  const router = useRouter();

  // Auto redirect ke login setelah 3 detik
  useEffect(() => {
    const timer = setTimeout(() => router.push("/login"), 3000);
    return () => clearTimeout(timer);
  }, [router]);

  return (
    <div className="text-center space-y-4">
      {/* Success Icon */}
      <div className="flex justify-center">
        <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center">
          <svg className="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
          </svg>
        </div>
      </div>

      <div>
        <h2 className="text-xl font-bold text-gray-900">Berhasil Keluar</h2>
        <p className="text-sm text-gray-500 mt-1">Anda telah keluar dari akun.</p>
        <p className="text-xs text-gray-400 mt-1">
          Mengalihkan ke halaman login...
        </p>
      </div>

      {/* Loading dots */}
      <div className="flex justify-center gap-1">
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            className="w-2 h-2 bg-primary-400 rounded-full animate-bounce"
            style={{ animationDelay: `${i * 0.15}s` }}
          />
        ))}
      </div>

      <p className="text-sm text-gray-500">
        Tidak diarahkan otomatis?{" "}
        <Link href="/login" className="text-primary-600 font-semibold hover:underline">
          Klik di sini
        </Link>
      </p>
    </div>
  );
}
```

Perbarui `handleLogoutConfirm` di Navbar untuk mengarahkan ke halaman sukses logout terlebih dahulu:

```typescript
const handleLogoutConfirm = async () => {
  setIsLoggingOut(true);
  try {
    // Arahkan ke halaman sukses logout, bukan langsung ke /login
    await signOut({ callbackUrl: "/logout" });
  } catch {
    setIsLoggingOut(false);
    setIsLogoutModalOpen(false);
  }
};
```

## Step 4 - Pengujian End-to-End {#step-4}

Jalankan backend Go dan `npm run dev`, kemudian lakukan pengujian berikut secara berurutan:

**Skenario 1 — Register → Dashboard**

1. Akses `/register`, isi data baru, klik "Buat Akun"
2. Verifikasi redirect otomatis ke `/dashboard`
3. Verifikasi nama muncul di Navbar dan profil tampil di halaman

**Skenario 2 — Login → Dashboard**

1. Logout terlebih dahulu, lalu akses `/login`
2. Masukkan email dan password yang valid, klik "Masuk"
3. Verifikasi redirect ke `/dashboard` dengan data user yang benar

**Skenario 3 — Proteksi Route**

1. Akses `/dashboard` saat belum login
2. Verifikasi redirect ke `/login?callbackUrl=/dashboard`
3. Login, verifikasi kembali ke `/dashboard` (bukan `/login` default)

**Skenario 4 — Logout dengan Konfirmasi**

1. Klik avatar di Navbar → klik "Keluar"
2. Verifikasi modal konfirmasi muncul
3. Klik "Batal" → modal tertutup, tetap di dashboard
4. Buka modal lagi → klik "Ya, Keluar"
5. Verifikasi halaman sukses logout muncul
6. Verifikasi auto-redirect ke `/login` setelah 3 detik
7. Coba akses `/dashboard` → harus diarahkan ke `/login`

**Skenario 5 — Error Handling**

1. Register dengan email yang sudah terdaftar → verifikasi pesan error
2. Login dengan password salah → verifikasi pesan error
3. Submit form kosong → verifikasi semua error validasi muncul

## Step 5 - Checklist Sebelum Production {#step-5}

Sebelum deploy ke production, pastikan semua poin ini sudah diperhatikan:

**Environment Variables** — Ganti semua nilai di `.env.local` dengan nilai production. `NEXTAUTH_SECRET` harus string acak yang panjang dan berbeda dari development.

**`NEXTAUTH_URL`** — Ganti dari `http://localhost:3000` ke domain production Anda. Tanpa ini, callback URL authentication tidak bekerja.

**HTTPS** — Pastikan aplikasi berjalan di HTTPS. Cookie session NextAuth.js memerlukan koneksi terenkripsi.

**CORS Backend** — Pastikan domain production sudah ditambahkan ke `allowedOrigins` di backend Go (`routes/routes.go`).

**`NEXT_PUBLIC_API_URL`** — Ganti dari `http://localhost:8080/api/v1` ke URL production backend Anda.

## Penutup Series {#penutup}

Selamat~ kita telah menyelesaikan series **Tutorial Next.js Auth** dari awal hingga akhir.

Kalau kita melihat ke belakang, ada perjalanan yang cukup panjang yang sudah kita tempuh. Kita mulai dari nol: menyiapkan project, memahami App Router, mengkonfigurasi Tailwind CSS v4 dengan pendekatan baru yang berbasis `@theme {}`. Kemudian kita membangun infrastruktur autentikasi dengan NextAuth.js  Credentials Provider, JWT callbacks, middleware proteksi route yang semuanya terhubung ke backend Go yang sudah kita bangun di series sebelumnya. Di atas fondasi itu, kita membangun sistem layout dengan Route Groups, lalu satu per satu mengimplementasikan alur register, login, tampilan dashboard, dan akhirnya logout.

Yang menarik untuk direfleksikan adalah bagaimana setiap part tidak berdiri sendiri. Middleware dari Part 2 melindungi dashboard yang kita buat di Part 6. Komponen Button dan Input dari Part 3 digunakan di form register Part 4 dan form login Part 5. Session yang dikonfigurasi di Part 2 menjadi sumber data utama di Part 6. Sistem yang baik selalu terasa seperti ini: setiap bagian saling mendukung, dan perubahan di satu titik terasa natural karena fondasinya dirancang dengan baik sejak awal.

Dari sini, ada banyak arah pengembangan yang bisa kamu eksplorasi. Menambahkan halaman edit profil adalah langkah yang paling natural. Jika kamu ingin memahami lebih dalam tentang OAuth, mencoba Social Provider seperti Google atau GitHub akan membuka wawasan baru tentang bagaimana NextAuth.js sesungguhnya bekerja. Dan jika keamanan menjadi prioritas, mengimplementasikan token blacklist di backend Go akan menjadi latihan yang sangat berharga sekaligus melengkapi celah kecil yang kita bahas di overview Part 7 ini.

Fondasi yang kita bangun di series ini bukan hanya untuk aplikasi autentikasi. Pola-pola yang kita pelajari Server Components untuk data fetching, middleware untuk proteksi route, fallback strategy untuk ketahanan terhadap kegagalan, pemisahan antara validasi client-side dan server-side adalah pola yang akan terus relevan di hampir semua aplikasi Next.js yang kamu bangun ke depannya.