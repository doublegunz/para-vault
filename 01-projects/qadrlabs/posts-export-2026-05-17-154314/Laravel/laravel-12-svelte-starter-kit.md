---
title: "Laravel 12 Svelte Starter Kit"
slug: "laravel-12-svelte-starter-kit"
category: "Laravel"
date: "2026-02-21"
status: "published"
---

Kabar menarik datang dari Taylor Otwell pada 18 Februari 2026. Di tengah berbagai pembaruan yang dirilis hari itu, ia mengumumkan satu tambahan yang dinanti banyak developer, yaitu **Laravel Svelte Starter Kit**, [starter kit](https://qadrlabs.com/post/laravel-12-starter-kit) resmi Laravel yang dibangun di atas Svelte, Inertia.js, TypeScript, Tailwind CSS, dan shadcn-svelte.

Dengan hadirnya starter kit ini, Laravel kini mendukung empat pilihan frontend secara resmi: React, Vue, Livewire, dan sekarang Svelte. Bagi developer yang selama ini menggemari Svelte karena performa dan sintaksnya yang ringkas, ini adalah berita yang disambut antusias.

Artikel ini akan memandu Anda dari awal hingga akhir: memahami apa itu Laravel Svelte Starter Kit, cara menginstalnya, menjalankannya di browser, dan mengenal struktur serta dependensi yang ada di dalamnya.

## Overview{#overview}

Dalam artikel ini, kita akan membahas:

- Apa itu Laravel Svelte Starter Kit dan teknologi yang ada di dalamnya
- Cara memperbarui Laravel Installer agar starter kit baru ini tersedia
- Langkah-langkah membuat project baru dengan starter kit Svelte
- Cara menjalankan development server dan mengakses aplikasi di browser
- Struktur dependensi frontend yang digunakan

Di akhir artikel, Anda akan memiliki aplikasi Laravel + Svelte yang berjalan di lokal, lengkap dengan halaman registrasi, login, dan dashboard yang siap dijadikan fondasi untuk project Anda berikutnya.

## Apa Itu Laravel Svelte Starter Kit?{#apa-itu-laravel-svelte-starter-kit}

Laravel Svelte Starter Kit adalah template aplikasi resmi yang disediakan oleh tim Laravel untuk memulai project dengan frontend **Svelte** dan backend **Laravel**. Seperti [starter kit](https://qadrlabs.com/post/laravel-12-starter-kit) lainnya di ekosistem Laravel 12, template ini sudah dilengkapi dengan konfigurasi autentikasi pengguna, routing, dan tampilan yang siap digunakan sejak pertama kali dijalankan.

### Teknologi yang Digunakan

Svelte Starter Kit menggabungkan beberapa teknologi modern dalam satu paket:

**Svelte 5** — Versi terbaru Svelte yang membawa perubahan besar pada cara penulisan komponen, termasuk sintaks *runes* (`$state`, `$props`, `$derived`) yang membuat kode lebih eksplisit dan mudah diprediksi.

**Inertia.js** — Jembatan antara backend Laravel dan frontend Svelte. Dengan Inertia, Anda tidak perlu membangun REST API terpisah — data dikirim langsung dari controller Laravel ke komponen Svelte melalui server-side rendering. Hasilnya adalah pengalaman single-page application (SPA) tanpa kompleksitas pengelolaan API.

**TypeScript** — Memberikan keamanan tipe statis ke dalam kode JavaScript/Svelte, mengurangi risiko bug yang sulit dilacak dan membuat IDE bisa memberikan saran kode yang lebih akurat.

**Tailwind CSS 4** — Framework CSS utility-first yang memungkinkan pembuatan tampilan responsif dan modern langsung di markup, tanpa perlu menulis CSS terpisah.

**shadcn-svelte** — Koleksi komponen UI yang dibangun di atas Tailwind CSS, dikhususkan untuk Svelte. Komponen-komponen ini tidak diinstall sebagai dependensi NPM biasa, melainkan disalin langsung ke dalam project sehingga sepenuhnya bisa dikustomisasi.

### Mengapa Memilih Svelte?

Svelte berbeda dari React dan Vue dalam cara yang fundamental: tidak ada virtual DOM. Svelte mengompilasi komponen menjadi JavaScript vanilla saat build time, sehingga menghasilkan bundle yang lebih kecil dan performa runtime yang lebih tinggi.

Bagi developer yang mencari alternatif frontend yang lebih ringan dengan sintaks yang terasa lebih dekat ke HTML, CSS, dan JavaScript standar, Svelte adalah pilihan yang sangat menarik. Dan kini, dengan adanya starter kit resmi, menggunakannya bersama Laravel menjadi jauh lebih mudah.

## Memperbarui Laravel Installer{#memperbarui-laravel-installer}

Svelte Starter Kit membutuhkan **Laravel Installer versi 5.24.6 atau lebih baru**. Installer versi lama hanya menampilkan opsi React, Vue, dan Livewire.

### Cek Versi yang Terinstall

Sebelum memperbarui, cek terlebih dahulu versi Laravel Installer yang ada di sistem kita:

```bash
laravel --version
```

Berikut output yang ditampilkan ketika kami menyusun artikel ini.

```
Laravel Installer 5.24.5
```
Laravel installer yang terinstall adalah `5.24.5`. Untuk menggunakan starter kit baru, kita perlu update laravel installer.

### Update Laravel Installer
Untuk melakukan proses update laravel installer ke versi terbaru, run command berikut ini.

```bash
composer global update laravel/installer
```

Tunggu hingga proses selesai, lalu verifikasi hasilnya:

```bash
laravel --version
```

Output yang ditampilkan ketika selesai proses update:

```
Laravel Installer 5.24.6
```
Versi yang terinstall adalah versi 5.24.6, tanda laravel installer berhasil diperbaharui.

## Membuat Project Baru dengan Svelte Starter Kit{#membuat-project-baru}
Selanjutnya kita akan coba membuat project baru dengan laravel svelte starter kita. Untuk membuat project baru, kita buka kembali terminal dan run command berikut ini.
```bash
laravel new starter-kit-laravel
```

Output yang ditampilkan.

Output:
```
$ laravel new starter-kit-laravel
 
 ██╗       █████╗  ██████╗   █████╗  ██╗   ██╗ ███████╗ ██╗
 ██║      ██╔══██╗ ██╔══██╗ ██╔══██╗ ██║   ██║ ██╔════╝ ██║
 ██║      ███████║ ██████╔╝ ███████║ ██║   ██║ █████╗   ██║
 ██║      ██╔══██║ ██╔══██╗ ██╔══██║ ╚██╗ ██╔╝ ██╔══╝   ██║
 ███████╗ ██║  ██║ ██║  ██║ ██║  ██║  ╚████╔╝  ███████╗ ███████╗
 ╚══════╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝   ╚═══╝   ╚══════╝ ╚══════╝

 ┌ Which starter kit would you like to install? ────────────────┐
 │   ○ None                                                     │
 │   ○ React                                                    │
 │ › ● Svelte                                                   │
 │   ○ Vue                                                      │
 │   ○ Livewire                                                 │
 └──────────────────────────────────────────────────────────────┘


```

Seperti yang terlihat pada output, svelte sudah tersedia sebagai opsi starter kita yang bisa kita pilih. Pada prompt ini, tentu kita pilih opsi **Svelte** sebagai starter kit, lalu tekan enter untuk melanjutkan.

Prompt berikutnya menanyakan provider autentikasi:

```
 ┌ Which authentication provider do you prefer? ────────────────┐
 │ › ● Laravel's built-in authentication                        │
 │   ○ WorkOS (Requires WorkOS account)                         │
 │   ○ No authentication scaffolding                            │
 └──────────────────────────────────────────────────────────────┘
```

Pilih **Laravel's built-in authentication** untuk menggunakan sistem autentikasi bawaan Laravel. 

Selanjutnya akan tampil prompt untuk memilhi testing framework.
```
 ┌ Which testing framework do you prefer? ──────────────────────┐
 │ › ● Pest                                                     │
 │   ○ PHPUnit                                                  │
 └──────────────────────────────────────────────────────────────┘
```

Pilih **Pest** lalu tekan `enter` untuk melanjutkan.

Selanjutnya akan tampil prompt untuk install Laravel Boost.

```
 ┌ Do you want to install Laravel Boost to improve AI assisted coding? ┐
 │ ● Yes / ○ No                                                        │
 └─────────────────────────────────────────────────────────────────────┘
```
Karena tujuan artikel kali ini hanya untuk install svelte starter kit, jadi boleh pilih opsi mana saja, lalu tekan enter untuk melanjutkan.
Selanjutnya kita tunggu proses install sampai tampil prompt untuk run command `npm install` dan `npm run build`.
```
 ┌ Would you like to run npm install and npm run build? ─────────┐
 │ ● Yes                                                        │
 └──────────────────────────────────────────────────────────────┘
```

Pilih **Yes**. Installer akan menjalankan `npm install` untuk mengunduh semua dependensi JavaScript, lalu `npm run build` untuk mengompilasi asset frontend. Proses ini membutuhkan koneksi internet dan mungkin memakan beberapa menit.

Setelah semua prompt diisi, installer akan memproses semuanya dan menampilkan pesan seperti ini:

```
   INFO  Application ready in [starter-kit-laravel]. You can start your local development using:

➜ cd starter-kit-laravel
➜ composer run dev

  New to Laravel? Check out our documentation. Build something amazing!
```

Project Svelte Starter Kit kita sudah siap.

## Menjalankan Development Server{#menjalankan-development-server}
Pada tahapan ini kita akan uji coba hasil buat project laravel dengan svelte starter kit. Sebelum run project ,kita pindah dulu ke direktori project menggunakan command berikut ini.

```bash
cd starter-kit-laravel
```

Selanjutnya kita run command berikut ini untuk menjalankan beberapa proses sekaligus.
```bash
composer run dev
```
Output yang ditampilkan:
```
$ composer run dev
> Composer\Config::disableProcessTimeout
> npx concurrently -c "#93c5fd,#c4b5fd,#fb7185,#fdba74" "php artisan serve" "php artisan queue:listen --tries=1 --timeout=0" "php artisan pail --timeout=0" "npm run dev" --names=server,queue,logs,vite --kill-others
[vite] 
[vite] > dev
[vite] > vite
[vite] 
[logs] 
[logs]    INFO  Tailing application logs.                        Press Ctrl+C to exit  
[logs]                                                Use -v|-vv to show more details  
[queue] 
[queue]    INFO  Processing jobs from the [default] queue.  
[queue] 
[vite] 8:55:46 PM [vite-plugin-svelte] no Svelte config found at /home/gun-gun-priatna/learning-lab/laravel/starter-kit-laravel - using default configuration.
[server] 
[server]    INFO  Server running on [http://127.0.0.1:8000].  
[server] 
[server]   Press Ctrl+C to stop the server
[server] 
[vite] 8:55:46 PM [vite] (client) info: Types generated for actions, routes, form variants
[vite]   Plugin: @laravel/vite-plugin-wayfinder
[vite] 8:55:46 PM [vite] (client) Forced re-optimization of dependencies
[vite] 
[vite]   VITE v7.3.1  ready in 784 ms
[vite] 
[vite]   ➜  Local:   http://localhost:5173/
[vite]   ➜  Network: use --host to expose
[vite] 
[vite]   LARAVEL v12.52.0  plugin v2.1.0
[vite] 
[vite]   ➜  APP_URL: http://localhost:8000
```

Bisa kita perhatikan pada output terminal di atas, `composer run dev` menjalankan beberapa proses sekaligus, seperti PHP development server di port 8000 dan Vite dev server untuk hot-reload asset frontend. Kita tidak perlu menjalankan keduanya secara terpisah. Pembahasan tentang command tersebut sudah pernah kita bahas pada artikel [Cara menggunakan composer run dev di laravel 11](https://qadrlabs.com/post/cara-menggunakan-composer-run-dev-di-laravel-11).

Setelah server berjalan, buka browser dan akses url berikut ini.

```
http://localhost:8000
```

Kita akan melihat halaman awal aplikasi Laravel + Svelte Starter Kit.

> Jika menggunakan **Laragon** atau **Laravel Herd** di Windows, aplikasi bisa diakses melalui `http://starter-kit-laravel.test` sesuai dengan nama folder project.

## Menjelajahi Aplikasi{#menjelajahi-aplikasi}
Sama seperti starter kit resmi laravel lainnya, pada svelte laravel kit terdapat beberapa fitur yang sudah tersedia, seperti fitur autentikasi, halaman dashboard yang siap pakai, halaman settings atau pengaturan akun. 

### Halaman Utama
Halaman pertama yang muncul menampilkan landing page sederhana dengan dua link navigasi: **Log in** dan **Register**. Tampilannya bersih dan modern — hasil dari kombinasi Tailwind CSS dan komponen shadcn-svelte.

### Halaman Register
Klik **Register** untuk mengakses halaman pendaftaran akun baru. Form registrasi sudah lengkap dengan field nama, email, password, dan konfirmasi password di mana semua divalidasi baik di sisi client maupun server.

Coba daftarkan akun baru dengan mengisi form dan klik tombol **Register**.

### Halaman Dashboard
Setelah registrasi berhasil, kita akan diarahkan ke halaman **Dashboard**, area yang hanya bisa diakses pengguna yang sudah login. Ini adalah titik awal untuk membangun fitur-fitur utama aplikasi kita.

Di bagian atas terdapat navigasi dengan nama pengguna dan menu dropdown. Klik nama pengguna untuk melihat opsi yang tersedia.

### Halaman Settings
Dari navigasi, akses halaman **Settings** untuk melihat fitur pengaturan akun yang sudah disertakan dalam starter kit:

- **Profile** — Mengubah nama dan alamat email akun
- **Password** — Mengubah password
- **Appearance** — Mengaktifkan dark mode atau light mode

Semua halaman ini sudah berfungsi penuh dan siap digunakan tanpa konfigurasi tambahan.

### Halaman Login
Klik **Log out** di navigasi, lalu akses halaman **Log in**. Form login memiliki field email dan password, dengan tautan ke halaman lupa password yang juga sudah disertakan.

## Mengenal Dependensi Frontend{#dependensi-frontend}
Untuk memastikan dependensi yang terinstall apakah svelte atau bukan, kita bisa cek file `package.json`. Buka file `package.json` di root project untuk melihat semua dependensi JavaScript yang digunakan:

```json
"dependencies": {
    "@inertiajs/svelte": "^2.0.0",
    "@sveltejs/vite-plugin-svelte": "^6.0.0",
    "bits-ui": "^2.15.0",
    "class-variance-authority": "^0.7.1",
    "clsx": "^2.1.1",
    "laravel-vite-plugin": "^2.0.0",
    "lucide-svelte": "^0.468.0",
    "svelte": "^5.16.0",
    "tailwind-merge": "^3.2.0",
    "tailwindcss": "^4.1.1",
    "tw-animate-css": "^1.2.5"
}
```

Ya, pada dependensi terdapat svelte dan berikut penjelasan setiap dependensi:

**`@inertiajs/svelte`** — Adapter Inertia.js untuk Svelte. Paket inilah yang menghubungkan routing Laravel di backend dengan komponen Svelte di frontend, menghasilkan pengalaman navigasi SPA tanpa perlu REST API.

**`@sveltejs/vite-plugin-svelte`** — Plugin Vite resmi untuk Svelte. Memungkinkan Vite memahami dan mengompilasi file `.svelte` selama proses build.

**`bits-ui`** — Library komponen UI headless (tanpa styling bawaan) khusus Svelte. Menjadi fondasi bagi komponen-komponen shadcn-svelte seperti dialog, dropdown, dan tooltip.

**`class-variance-authority`** dan **`tailwind-merge`** — Dua utility untuk mengelola class Tailwind secara programatik. `cva` membantu membuat komponen dengan varian style yang berbeda, sementara `tailwind-merge` mencegah konflik class Tailwind saat digabungkan secara dinamis.

**`clsx`** — Utility kecil untuk menggabungkan class CSS secara kondisional. Umumnya digunakan bersama `tailwind-merge` dalam helper `cn()`.

**`laravel-vite-plugin`** — Plugin resmi Laravel untuk Vite, yang mengurus integrasi antara Vite dan sistem asset Laravel termasuk hot-reload dan versioning.

**`lucide-svelte`** — Koleksi ikon SVG yang dioptimalkan untuk Svelte. Digunakan secara luas di komponen-komponen bawaan starter kit.

**`svelte`** — Framework frontend utama, versi 5. Fitur *runes* di Svelte 5 membawa perubahan besar dalam cara mengelola reaktivitas komponen.

**`tailwindcss`** — Framework CSS utility-first, versi 4 yang lebih cepat dan menggunakan konfigurasi berbasis CSS (bukan `tailwind.config.js`).

**`tw-animate-css`** — Kumpulan animasi Tailwind yang siap pakai, digunakan oleh komponen-komponen UI untuk efek transisi yang halus.


## Kesimpulan{#kesimpulan}
Laravel Svelte Starter Kit hadir sebagai pilihan frontend resmi keempat di ekosistem Laravel, melengkapi React, Vue, dan Livewire. Dengan menggabungkan Svelte 5, Inertia.js, TypeScript, Tailwind CSS 4, dan shadcn-svelte dalam satu paket yang siap pakai, starter kit ini memberikan fondasi yang solid untuk membangun aplikasi web modern.

Bagi developer yang menyukai pendekatan Svelte, kompilasi ke JavaScript vanilla, tidak ada virtual DOM, dan sintaks yang dekat dengan standar web, menggunakan starter kit ini adalah cara paling cepat untuk memulai project Laravel dengan Svelte tanpa perlu mengkonfigurasi semua integrasi secara manual.

Langkah selanjutnya setelah menjalankan starter kit ini adalah mulai membangun fitur-fitur spesifik aplikasi kita di atas fondasi yang sudah tersedia. Semua infrastruktur autentikasi, routing, dan komponen UI sudah siap memungkinkan kita untuk fokus pada apa yang membuat aplikasi kita unik.