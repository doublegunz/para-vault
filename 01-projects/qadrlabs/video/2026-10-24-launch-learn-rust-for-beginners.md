---
type: video
brand: qadrlabs
title: Video Launching Learn Rust for Beginners (40 detik)
date: 2026-10-24
status: published
tags:
  - qadrlabs
  - video
  - motion-graphics
  - gsap
  - rust
project_dir: /home/gun-gun-priatna/obsidian-vault/sandbox/learning-video
caption_path: sandbox/learning-video/caption/rust-course-launch.md
template: custom-html-gsap
variants:
  - id: reels-en
    label: Reels (EN)
    path: sandbox/learning-video/videos/rust-course-launch/out/rust-course-launch.mp4
    format: 1080x1920 60fps
    status: published
    published: []
---

# Video Launching Learn Rust for Beginners (40 detik)

Video launching Instagram Reels untuk course *Learn Rust for Beginners: Programming Fundamentals from Zero*, yang sudah publish di <https://qadrlabs.com/course/learn-rust-for-beginners-programming-fundamentals-from-zero>. Bahasa Inggris, 1080×1920, 60fps, musik dan sound effect disintesis dengan kode (bebas masalah hak cipta).

Hasil: `sandbox/learning-video/videos/rust-course-launch/out/rust-course-launch.mp4`
Caption: `sandbox/learning-video/caption/rust-course-launch.md`

Terkait: [[2026-10-12-promo-learn-rust-for-beginners]] (video promo sebelumnya), [[2026-09-30-motion-graphics-intro-qadrlabs]]

> [!note] Folder `sandbox/` di-ignore Git
> Kalau ingin disimpan permanen, salin MP4 ke luar `sandbox/`.

## Konsep visual

Sengaja berbeda dari video promo sebelumnya (isometric 3D). Flat 2D dengan tipografi kinetik besar (Poppins 900), mengikuti palet brand di `01-projects/qadrlabs/images/guidelines.md`: latar off-white / biru keabuan muda dengan dot grid seperti editor, teks indigo #281845, aksen biru / cyan / violet, oranye hanya untuk kata "Rust". Partikel berupa simbol kode (`{ } ; < > / !`) dan kotak kecil berwarna brand (digambar di canvas, deterministik), kamera bergetar + RGB split tipis saat impact, punch di setiap ketukan, slat wipe, iris wipe. Logo memakai `vertical-logo.svg` apa adanya (warna asli tidak diubah, hanya dianimasikan muncul).

> [!note] Revisi 2026-10-25
> Versi pertama memakai palet gelap oranye ("forge") dan logo yang diwarnai ulang. Feedback: kartu 04 meloncat ke atas, warna kurang terasa programming, logo harus asli. Diganti ke palet terang brand, logo asli, dan posisi kartu diperbaiki.

## Script / storyboard

Tempo 120 BPM D minor (1 ketukan = 0.5 detik), semua pergantian scene jatuh di ketukan.

| Waktu | Scene | Isi |
|---|---|---|
| 0-2.5s | Countdown | "STATUS: COMING SOON" diketik lalu dicoret, angka 3 · 2 · 1 menghantam di tiap ketukan |
| 2.5-6.5s | Launch | Drop: ledakan percikan, shockwave, "NOW LIVE", status berubah jadi "LIVE", judul course + "Programming fundamentals from zero" |
| 6.5-10.5s | Audience | "Never written code?" lalu stempel "PERFECT.", "Start from zero." + "No programming experience needed" |
| 10.5-16.5s | Journey | Jalur bercahaya melewati 9 modul (label bahasa awam), kamera mengikuti, lalu zoom out memperlihatkan seluruh jalur |
| 16.5-22.5s | Cara belajar | Breakdown musik. 4 kartu: One new idea at a time / A small program you run yourself / Fix the common mistakes / Practice with exercises |
| 22.5-28.5s | Program pertama | Drop kedua. Kode `println("Hello, world!");` (tanpa `!`) dijalankan, muncul error asli E0423 + `help: use `!` to invoke the macro`, `!` ditambahkan, jalan lagi, "Hello, world!" meledak dengan percikan |
| 28.5-33.5s | Angka | 9 modules, 18 lessons, 0 experience needed, FREE lifetime access, Certificate of completion, lalu semua tersedot ke satu titik |
| 33.5-40s | End card | Logo qadrlabs tersusun, judul course, chip Now live / Free / 9 modules · 18 lessons, CTA "Start learning at qadrlabs.com" |

Sumber klaim: `courses/learn-rust-for-beginners/tentang-course.md` (metode lesson, prasyarat, daftar modul, Hello World dari lesson 2) dan halaman course yang sudah publish (gratis, akses selamanya, sertifikat). Pesan error dicek dengan `rustc` asli.

## Cara pakai

```bash
cd ~/obsidian-vault/sandbox/learning-video
npm run preview                                  # http://localhost:5173/videos/rust-course-launch/
npm run stills -- rust-course-launch 170,480     # still (detik x 60)
npm run audio -- rust-course-launch              # soundtrack saja
npm run build -- rust-course-launch              # render penuh + audio + mux (±17 menit)
```

## Catatan teknis

- `.card:nth-of-type(n)` ikut menghitung `div` header di scene yang sama (penyebab kartu 04 meloncat). Pakai class eksplisit (`.c1`..`.c4`).
- `engine/base.css` memberi `#cam` `width:0` (untuk dunia isometric). Video flat 2D yang memakai id `#cam` harus menimpa `width/height: auto`, kalau tidak semua teks rata tengah bergeser ke kiri.
- Scene di-toggle dengan `display`, bukan `visibility`: anak yang di-set `visibility: visible` tetap tampil walau parent-nya hidden.
- SFX khusus video ini (rise, swipe, spark, stamp, sub, roll) ada di `audio.mjs`, engine tidak diubah.
- Plan: `~/.claude/plans/pasted-content-id-923e-kita-akan-nifty-pudding.md`
