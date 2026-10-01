---
title: Video Promosi Sistem KP (20 detik)
date: 2026-09-30
status: selesai
tags:
  - kp-projects
  - video
  - motion-graphics
  - gsap
project_dir: /home/gun-gun-priatna/Projects/kp-promo-video
---

# Video Promosi Sistem KP (20 detik)

Video promosi Sistem KP berdurasi 20 detik. Pembuatannya memakai kode (HTML + CSS + GSAP), lalu dirender per frame menjadi MP4. Polanya sama dengan [[2026-09-30-motion-graphics-intro-qadrlabs]].

| Versi | File | Resolusi |
|---|---|---|
| Landscape 16:9 | `kp-promo.mp4` | 1920×1080, 60fps, ±5.3 MB |
| Vertical 9:16 | `kp-promo-vertical.mp4` | 1080×1920, 60fps, ±5.7 MB |

Lokasi: `~/Projects/kp-promo-video/`. Videonya **tanpa audio**.

Terkait: [[sistem-kp-gambaran-fitur]]

---

## Tahapan yang dilakukan

1. **Mencoba eksplorasi dengan login (tidak jadi).** Aplikasi hanya bisa diakses lewat SSO portal Informatika. Rencana login otomatis memakai akun demo diblokir oleh pengaman otomatis Claude Code, karena menyangkut data user asli dan pembuatan token login. Akhirnya dipilih **opsi tanpa login**.
2. **Riset dari codebase `kp-project`:**
   - Copy landing page dari `welcome.blade.php`: hero, tiga jalur, alur 4 tahap, peran, dan CTA.
   - Menu sidebar admin dan civitas.
   - Label dashboard per role dari `panel/dashboard` dan `panel/home`.
   - Tombol "Login Portal" dari `partials/welcome-cta`.
   - Path ikon dari `components/panel/icon.blade.php`.
   - Token warna, font, dan radius dari `DESIGN.md`.
   - URL `e-kp.ummi.ac.id` dari `about-id.md`.
3. **Membangun scene** di `index.html`, `styles.css`, dan `timeline.js`. Semuanya elemen HTML/SVG, bukan screenshot.
4. **Render** dengan `render.mjs` (Playwright Chromium, satu frame per langkah, lalu ffmpeg H.264 CRF 16).
5. **Verifikasi** lewat still frame dan contact sheet. Yang ditemukan dan diperbaiki:
   - `seekTo()` mengembalikan objek timeline GSAP sehingga render macet. Solusinya: fungsi itu tidak mengembalikan apa pun.
   - Di versi vertical, headline dan "Sistem KP." melebar, dan konten scene 3–5 terlalu kecil. Solusinya: ukuran diperbesar dan panel diberi `zoom: 1.45`.

---

## Storyboard

| Waktu | Scene | Isi |
|---|---|---|
| 0–3.5s | Hook | Badge "Ruang tumbuh, langkah baru" dan headline "Langkah praktikmu, **lebih terarah.**" dengan garis bawah biru. Kartu melayang "Logbook kegiatan" dan "Bimbingan terhubung". |
| 3.5–6.4s | Brand | Ikon toga dan "Sistem KP." dengan sub "Teknik Informatika UMMI". |
| 6.4–9.9s | Tiga jalur | "Tiga jalur. Banyak kesempatan." Kartu Kerja Praktik, Magang, dan Penelitian. |
| 9.9–13.4s | Alur | "Alur yang jelas, sejak awal hingga selesai." Empat tahap dicentang berurutan. |
| 13.4–17.3s | Peran | "Peran berbeda. Tujuan yang sama." Panel beralih antara Mahasiswa, Pembimbing, dan Admin. |
| 17.3–20s | CTA | "Siap memulai perjalanan praktikmu?" dengan tombol **Login Portal** dan `e-kp.ummi.ac.id`. |

> [!note] Data ilustrasi
> Angka di mockup panel (8, 3, 12, 5, 2, 4, 0) dan beberapa baris daftar (misalnya "Logbook minggu ke-3") adalah **contoh**, bukan data asli. Karena itu ada caption "Ilustrasi tampilan". Label menu, judul kartu, dan badge diambil dari view asli.

---

## Struktur project

```
kp-promo-video/
├── index.html      # elemen semua scene (teks ada di sini)
├── styles.css      # tampilan; override 9:16 di blok "VERTICAL" paling bawah
├── timeline.js     # animasi GSAP + ikon (ICONS)
├── render.mjs      # render frame → MP4
├── package.json    # preview, render, render:vertical
├── stills/         # frame cek (boleh dihapus)
├── kp-promo.mp4
└── kp-promo-vertical.mp4
```

---

## Cara mengedit

### Alur kerja
```bash
cd ~/Projects/kp-promo-video
npm run preview                             # buka http://localhost:5174 (tambah ?v untuk 9:16)
FRAMES=300,900 node render.mjs              # cek frame tertentu (detik × 60) → stills/f0300.png
ORIENT=vertical FRAMES=300,900 node render.mjs   # → stills/v0300.png
npm run render && npm run render:vertical   # render final (±8 menit per versi)
```

### Mengganti teks
Semua teks ada di `index.html`, dikelompokkan dengan komentar `SCENE 1 · HOOK` sampai `SCENE 6 · CTA`.
- Angka ilustrasi ada di elemen `.stat b`.
- Baris daftar ada di elemen `.row`.

Setelah teks diganti, cek versi vertical dengan still frame. Teks panjang mudah meluber di layar sempit.

### Mengubah timing
Timing ada di `timeline.js`. Angka terakhir di setiap `tl.to/from/fromTo(...)` adalah **detik mulainya**. Contoh:
```js
tl.to('#s3', { autoAlpha: 0, y: -40, duration: 0.4 }, 9.55); // scene 3 keluar di detik 9.55
```
Beberapa pengaturan yang sering diubah:
- **Pergantian role di panel** diatur oleh `switchRole(indeks, ..., detik)`, saat ini di detik 14.85 dan 16.0.
- **Centang tahap alur** mulai di detik `10.8 + i * 0.55`.
- **Durasi total** diatur di `const DURATION = 20;`.

Kalau satu scene digeser, geser juga scene sesudahnya.

### Mengganti warna / font / radius
- Variabel `:root` di `styles.css` mengikuti `DESIGN.md` (gray + blue). Kalau `DESIGN.md` berubah, sesuaikan juga di sini.
- Font Inter di-load dari Google Fonts di `<head>` `index.html`.

### Menambah ikon
Tambahkan path SVG ke objek `ICONS` di `timeline.js`. Path-nya bisa disalin dari `kp-project/resources/views/components/panel/icon.blade.php`. Lalu pakai ikon itu dengan `data-icon="nama"` di HTML.

### Layout vertical
Semua override ada di blok `body.vertical ...` paling bawah `styles.css`. Perubahan di situ tidak memengaruhi versi 16:9. Panel diperbesar dengan `body.vertical .main { zoom: 1.45; }`.

### Menambahkan musik
```bash
ffmpeg -i kp-promo.mp4 -i musik.mp3 -c:v copy -c:a aac -shortest \
  -af "afade=t=out:st=18.5:d=1.5" kp-promo-music.mp4
```

---

## Troubleshooting

| Masalah | Solusi |
|---|---|
| Render macet atau timeout | Pastikan `window.seekTo` tidak mengembalikan nilai (`{ tl.seek(t, false); }`). |
| Font tampil default | Google Fonts butuh internet saat render. |
| Chromium tidak ditemukan | `CHROME=/path/ke/chrome node render.mjs` |
