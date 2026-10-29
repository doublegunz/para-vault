---
type: video
brand: qadrlabs
title: Promo Reels Learn Rust for Beginners (23 detik)
date: 2026-10-12
status: published
tags:
  - qadrlabs
  - video
  - motion-graphics
  - gsap
  - rust
project_dir: /home/gun-gun-priatna/obsidian-vault/sandbox/learning-video
template: custom-html-gsap
variants:
  - id: reels-en
    label: Reels (EN)
    path: sandbox/learning-video/videos/rust-beginners-promo/out/rust-beginners-promo.mp4
    format: 1080x1920 60fps
    status: published
    published: []
---

# Promo Reels Learn Rust for Beginners (23 detik)

Video promosi Instagram Reels untuk course *Learn Rust for Beginners: Programming Fundamentals from Zero*. Bahasa Inggris, gaya **isometric 3D**, 1080×1920, 60fps, dengan musik latar dan sound effect yang disintesis langsung dengan kode (bebas masalah hak cipta).

Hasil: `sandbox/learning-video/videos/rust-beginners-promo/out/rust-beginners-promo.mp4`

Terkait: [[2026-09-30-motion-graphics-intro-qadrlabs]], [[PROMPT_MOTION_VIDEO_by-claude]]

> [!note] Folder `sandbox/` di-ignore Git
> Project ini tidak ikut ter-commit. Kalau ingin disimpan permanen, pindahkan ke `~/Projects/qadrlabs/`.

---

## Script / storyboard

Tempo musik 120 BPM (1 ketukan = 0.5 detik), jadi setiap pergantian scene jatuh tepat di ketukan.

| Waktu | Scene | Isi |
|---|---|---|
| 0–2.5s | Hook | Lantai grid isometric, 36 kubus muncul bergelombang. "Never written **code** before?" |
| 2.5–5.5s | Start | Balok oranye "Rust" jatuh dan memantul (impact + ripple). Terminal: `cargo new hello`, `cargo run`, `Hello, world!`. "Start from zero. With Rust." |
| 5.5–9s | Compiler | Kartu error asli `error[E0382]: borrow of moved value: 'original'` bergetar (glitch), muncul `help`, lalu kartu berputar ke sisi hijau berisi perbaikan `.clone()` dan output. "A compiler that teaches you." |
| 9–14s | Modules | 9 slab modul jatuh satu per ketukan membentuk menara, counter naik sampai "9 modules. 18 lessons." |
| 14–18.5s | Final project | Menara terbang ke atas, terminal to-do list di atas platform: `add`, `done 2`, `list`, lalu pill `test result: ok. 5 passed`. "Build a real command-line to-do app." |
| 18.5–23s | End card | Wipe berbentuk diamond (mengikuti bentuk logo), logo qadrlabs, judul course, chip "No experience needed · 9 modules · 18 lessons · Standard library only", CTA "Start learning at qadrlabs.com". |

Semua teks di layar diambil dari materi course (`tentang-course.md`, lesson 9, lesson 18). Pesan error E0382 dan teks `help` dicek dengan `rustc` asli.

---

## Struktur project

Sejak 2026-10-12 project ini **multi-video**: engine bersama + satu folder per video. Untuk video baru tidak perlu project baru, cukup `npm run new -- <slug>`. Panduan lengkap ada di `sandbox/learning-video/README.md` (manusia) dan `AGENTS.md` (AI agent).

```
sandbox/learning-video/
├── AGENTS.md, README.md, package.json
├── engine/          # render.mjs, build.sh, sheet.sh, new-video.sh, iso.js, player.js, base.css, synth.mjs
├── shared/assets/   # logo.png
└── videos/rust-beginners-promo/
    ├── cues.js      # SATU sumber timing (dibaca timeline.js dan audio.mjs)
    ├── index.html, styles.css, timeline.js
    ├── audio.mjs    # aransemen musik + SFX
    └── out/         # rust-beginners-promo.mp4
```

## Cara pakai

```bash
cd ~/obsidian-vault/sandbox/learning-video
npm run preview                                   # http://localhost:5173/videos/rust-beginners-promo/
npm run stills -- rust-beginners-promo 170,450    # still (detik x 60)
npm run sheet -- rust-beginners-promo             # contact sheet
npm run audio -- rust-beginners-promo             # soundtrack saja
npm run build -- rust-beginners-promo             # render penuh + audio + mux (±10 menit)
npm run new -- promo-baru                         # video baru di project yang sama
```

## Cara mengedit

- **Timing**: `cues.js`. Visual dan audio sama-sama membaca file ini, jadi SFX otomatis ikut bergeser.
- **Teks**: `index.html`; teks yang diketik di `TYPERS` (`cues.js`).
- **Musik**: `CHORDS`/`ROOTS` dan pola drum di `audio.mjs`; instrumen dan efek di `engine/synth.mjs`.
- **SFX**: entri `{ t, type, gain }` di `SFX`. Tipe: riser, pop, whoosh, impact, thud, tick, ding, ping, chime, shimmer, block, glitch.
- **Balok isometric**: `block({ w, d, h, color, south, west })` dari `engine/iso.js`.

## Catatan teknis

- Jangan pasang `opacity` atau `filter` pada elemen 3D (`.blk`, `#tilt`, `#spin`): Chromium akan meratakan (flatten) balok. Pakai `visibility`, atau animasikan opacity di face-nya.
- Teks overlay sudah dijaga di atas dunia 3D (wrapper `#world` + `will-change` di `engine/base.css`). Yang perlu dihindari adalah warna sama yang lewat di belakang headline (slab cyan di belakang angka cyan membuat angka hilang): jauhkan gerakan 3D dari area headline.
- `logo.png` berlatar putih (bukan transparan), jadi hanya dipakai di end card yang berlatar putih, dengan `mix-blend-mode: multiply`.
- Plan asli: `~/.claude/plans/pasted-content-id-9fe3-create-a-velvety-puzzle.md`
