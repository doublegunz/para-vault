---
title: Motion Graphics Intro qadrLabs (20 detik)
date: 2026-09-30
status: selesai
tags:
  - qadrlabs
  - video
  - motion-graphics
  - gsap
project_dir: /home/gun-gun-priatna/Projects/qadrlabs/qadrlabs-intro-video
---

# Motion Graphics Intro qadrLabs (20 detik)

Video perkenalan qadrlabs.com berdurasi 20 detik, bergaya *developer-tech brand*. Videonya dibuat dengan kode (HTML + CSS + GSAP), tidak memakai editor video, lalu dirender per frame menjadi MP4.

Ada dua versi:

| Versi | File | Resolusi |
|---|---|---|
| Landscape 16:9 | `qadrlabs-intro.mp4` | 1920×1080, 60fps, ±9.4 MB |
| Vertical 9:16 | `qadrlabs-intro-vertical.mp4` | 1080×1920, 60fps, ±9.8 MB |

Semuanya ada di `~/Projects/qadrlabs/qadrlabs-intro-video/`. Videonya **tanpa audio**; musik bisa ditambahkan belakangan (lihat [[#Menambahkan musik]]).

Terkait: [[prompt promosi qadrlabs]]

---

## Tahapan yang dilakukan

### 1. Riset website & brand
- Membuka qadrlabs.com dan mencatat teks aslinya: tagline, hero, navigasi, daftar course, artikel, short notes, dan tech yang dibahas.
- Membuka artikel *Laravel 13 CRUD Tutorial: Build a Simple Blog Step by Step* untuk mengambil struktur Step 1–9 dan potongan kode aslinya.
- Membaca repo `qadrlabs-frontend` untuk identitas visual:
  - `resources/views/frontend/component/hero.blade.php`: tagline, hero line, tombol "Start Learning", dan SVG wave.
  - `resources/sass/*.scss` dan `home.blade.php`: palet warna dan font (Poppins, Nunito).
  - `public/img/logo/logov3.png` dan `logov3-white.png`: logo resmi.
- **Temuan penting:** `public/img/logo/new/logo.svg` ternyata **bukan** logo qadrLabs, melainkan wordmark "SUPERNOVA DEVELOPER". File ini jangan dipakai.

Aturannya: **tidak ada fitur, statistik, atau klaim karangan**. Semua copy di video diambil dari website.

### 2. Plan (storyboard)
Plan dibuat dulu di plan mode, lalu disetujui sebelum coding. Storyboard-nya ada di [[#Storyboard]].

### 3. Membangun ulang logo sebagai SVG
Logo PNG diukur secara piksel, lalu mark diamond "q" digambar ulang sebagai SVG (`assets/mark.svg`). Dengan begitu kanal putih "q" bisa dianimasikan seperti sedang digambar (stroke-draw).

Wordmark "qadrLabs" dipotong dari PNG asli (`assets/wordmark.png` dan `wordmark-white.png`). Batas tiap huruf juga diukur, supaya hurufnya bisa muncul satu per satu lewat CSS mask.

### 4. Membangun scene
- `index.html`: semua elemen scene (terminal, card course, browser, editor, end card). Tidak ada screenshot; semuanya elemen HTML/SVG asli.
- `styles.css`: tampilan. Blok paling bawah (`body.vertical ...`) berisi override layout untuk versi 9:16.
- `timeline.js`: satu timeline GSAP yang mengatur seluruh animasi berdasarkan detik.

### 5. Render
`render.mjs` melakukan langkah berikut:
1. Menyalakan server lokal kecil.
2. Membuka halaman di Chromium milik Playwright (sudah terpasang di `~/.cache/ms-playwright`).
3. Memanggil `seekTo(t)` untuk setiap frame (1200 frame = 20 detik × 60fps).
4. Mengambil screenshot tiap frame, lalu mengirimkannya ke ffmpeg (H.264, CRF 16).

Hasilnya *deterministik*: render ulang selalu identik dan tidak ada frame yang drop.

### 6. Verifikasi
- `ffprobe` untuk mengecek durasi 20.0 detik, resolusi, dan 60fps.
- Merender still di detik-detik penting, lalu membuat *contact sheet* untuk mengecek teks yang terpotong, elemen yang bertumpuk, dan transisi.
- Bug yang ditemukan dan diperbaiki lewat cara ini:
  - Perintah terminal terpotong.
  - Editor menutupi daftar Step.
  - Chip teknologi menimpa headline.
  - Posisi logo di end card salah.
  - Teks "experiencesfrom" menempel di versi vertical.

### 7. Versi vertical 9:16
Scene dan timing tetap sama, hanya layout-nya yang disusun ulang untuk portrait. Cara kerjanya: parameter URL `?v` menambahkan class `vertical` ke `<body>`, lalu:
- CSS override mengatur ukuran stage 1080×1920, lockup bertumpuk, card 2×2, serta browser dan editor bertumpuk.
- `timeline.js` menyesuaikan titik tengah, target zoom, bentuk diamond wipe, dan posisi chip.

---

## Storyboard

| Waktu | Scene | Isi |
|---|---|---|
| 0–3.5s | Hook | Terminal mengetik `composer create-project laravel/laravel --prefer-dist blog`. Headline "Don't just ~~read~~ code." berubah menjadi "**Build** it." |
| 3.5–7s | Intro brand | Terminal melipat menjadi diamond, kanal "q" tergambar, wordmark muncul per huruf, lalu tagline "CRAFTED BY CODER FOR CODER". |
| 7–11.5s | Apa yang dipelajari | Headline "From your first `<html>` page to full Laravel apps." dan 4 card course asli. Chip teknologi melayang. Card Laravel for Beginners di-spotlight, lalu kamera zoom masuk. |
| 11.5–16.5s | Hands-on | Headline "Step by step. Line by line." Browser menampilkan artikel CRUD dengan Step 1–9 yang tercentang bergantian. Editor `.env` dan terminal mengetik `php artisan make:model Post -m`. Muncul pill nav Explore · Series · Courses · Short Notes. |
| 16.5–20s | Brand reveal | Diamond wipe membuka latar terang dengan wave. Logo mendarat, hero line tampil, URL bar mengetik `qadrlabs.com`, dan tombol "Start Learning" berdenyut. |

---

## Struktur project

```
qadrlabs-intro-video/
├── index.html          # elemen semua scene
├── styles.css          # tampilan (+ override vertical di bagian bawah)
├── timeline.js         # animasi (GSAP) + efek mengetik
├── render.mjs          # render frame → MP4
├── package.json        # script: preview, render, render:vertical
├── assets/
│   ├── mark.svg              # mark diamond (dibangun ulang dari logov3.png)
│   ├── wordmark.png          # wordmark warna (crop logov3.png)
│   └── wordmark-white.png    # wordmark putih (dipakai sebagai mask)
├── stills/             # frame cek (boleh dihapus)
├── qadrlabs-intro.mp4
└── qadrlabs-intro-vertical.mp4
```

---

## Cara mengedit

### Alur kerja edit (disarankan)
1. **Preview live** di browser:
   ```bash
   cd ~/Projects/qadrlabs/qadrlabs-intro-video
   npm run preview
   ```
   Perintah ini membuka `http://localhost:5173`, dan animasinya berputar terus. Untuk versi vertical, buka `http://localhost:5173/?v`. Setelah mengedit file, cukup refresh browser.
2. **Cek frame tertentu** tanpa render penuh (cepat, beberapa detik). Nilai `FRAMES` adalah nomor frame, yaitu detik × 60:
   ```bash
   FRAMES=120,300,600 node render.mjs                    # 16:9 → stills/f0120.png ...
   ORIENT=vertical FRAMES=120,300,600 node render.mjs    # 9:16 → stills/v0120.png ...
   ```
3. **Render final** (±8–9 menit per versi):
   ```bash
   npm run render            # → qadrlabs-intro.mp4
   npm run render:vertical   # → qadrlabs-intro-vertical.mp4
   ```

### Mengganti teks / copy
- Teks statis (headline, judul card, judul artikel, Step, tagline, tombol) ada di **`index.html`**. Cari teksnya lalu ganti.
- Teks yang **diketik** (perintah terminal dan URL) ada di **`timeline.js`**, di array `typers`:
  ```js
  { el: $('#cmd1'), text: 'composer create-project ...', start: 0.6, cps: 50, ... },
  { el: $('#cmd2'), text: 'php artisan make:model Post -m', start: 13.35, cps: 30, ... },
  { el: $('#urlText'), text: 'qadrlabs.com', start: 18.05, cps: 24, ... },
  ```
  `start` = detik mulai mengetik, `cps` = karakter per detik.
- Setelah copy diganti, cek dengan still frame supaya tidak ada teks yang meluber, terutama di versi vertical.

### Mengubah timing
Semua animasi ada di `timeline.js`. Angka terakhir di setiap baris `tl.to(...)`, `tl.from(...)`, atau `tl.fromTo(...)` adalah **detik mulainya**, dan `duration` adalah lamanya. Contoh:
```js
tl.to('#hook1', { y: -60, autoAlpha: 0, duration: 0.4 }, 2.3);  // mulai di detik 2.3
```
Kode di file itu sudah dikelompokkan per scene dengan komentar `SCENE 1 · HOOK`, `SCENE 2 · INTRODUCE`, dan seterusnya. Kalau timing satu scene digeser, geser juga scene sesudahnya supaya transisinya tetap nyambung.

Durasi total diatur di `const DURATION = 20;`.

### Mengganti warna / font
- Warna ada di bagian atas `styles.css` sebagai variabel `:root`: `--blue`, `--primary`, `--ink`, `--tint`, dan seterusnya.
- Font di-load dari Google Fonts di `<head>` `index.html` (Poppins, Nunito, JetBrains Mono).
- Radius sudut `12px` (`--radius`) mengikuti guideline UI qadrLabs.

### Mengubah layout / posisi
- Landscape: ubah posisi `left`/`top`/`width` di bagian utama `styles.css`.
- Vertical: ubah di blok `body.vertical ...` di bagian bawah `styles.css`. Perubahan di sini **tidak** memengaruhi versi 16:9.
- Beberapa posisi juga ada di `timeline.js`, jadi harus ikut disesuaikan kalau elemennya dipindah:
  - `zoomTo(...)`: titik zoom ke card Laravel. Nilainya berbeda untuk 16:9 dan 9:16.
  - Pergeseran logo `#mark` (`x: -330` untuk landscape, `y: -150` untuk vertical).
  - `spots`: posisi chip teknologi di versi vertical.

### Mengganti course / artikel
Card course ada di `index.html`, di dalam `<div id="cards">`. Satu `<article class="card">` sama dengan satu course, jadi judul, badge Free/Premium, dan meta modul/lesson bisa langsung diganti. Artikel tutorial (judul dan Step) ada di `<div id="browser">`.

> [!warning] Jangan mengarang data
> Kalau course atau artikel di website berubah, perbarui dari data asli qadrlabs.com.

### Menambah atau menghapus scene
1. Tambahkan `<section id="sX" class="scene">` di `index.html`, di dalam `#camera` (supaya ikut gerakan kamera).
2. Sembunyikan di awal: tambahkan `#sX` ke `gsap.set([...], { autoAlpha: 0 })`.
3. Di `timeline.js`, tampilkan dengan `tl.set('#sX', { autoAlpha: 1 }, detik)`, animasikan isinya, lalu sembunyikan scene sebelumnya.
4. Kalau total durasi berubah, ubah `DURATION`.

### Menambahkan musik
```bash
ffmpeg -i qadrlabs-intro.mp4 -i musik.mp3 -c:v copy -c:a aac -shortest \
  -af "afade=t=out:st=18.5:d=1.5" qadrlabs-intro-music.mp4
```

### Mengubah kualitas / resolusi
Pengaturannya ada di `render.mjs`:
- `FPS = 60`: ganti ke 30 supaya render dua kali lebih cepat.
- `-crf 16`: angka lebih kecil = kualitas lebih tinggi dan file lebih besar.

---

## Troubleshooting

| Masalah | Penyebab / solusi |
|---|---|
| Wordmark tidak muncul saat `index.html` dibuka langsung (`file://`) | CSS mask butuh server. Pakai `npm run preview`. |
| Font tampil default di hasil render | Google Fonts butuh internet saat render. |
| Chromium tidak ditemukan | Set path-nya manual: `CHROME=/path/ke/chrome node render.mjs`. |
| Teks mengetik tidak muncul di preview | Refresh halaman. Efek mengetik dihitung dari waktu timeline di `applyTypers()`. |

---

## Catatan
- Tidak ada perubahan di repo `qadrlabs-frontend`; project video ini berdiri sendiri.
- Dependency project video: `gsap` dan `playwright-core` (lokal di `node_modules`).
- Plan asli: `~/.claude/plans/pasted-content-id-478c-create-a-cached-wozniak.md`
