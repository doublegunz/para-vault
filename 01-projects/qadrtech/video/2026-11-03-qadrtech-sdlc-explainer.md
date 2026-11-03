---
type: video
brand: qadrtech
title: Qadr Tech — How We Work (SDLC Explainer, EN)
date: 2026-11-03
status: rendered
template: qadrtech-promo
project_dir: ~/Projects/qadrtech-hq/videos/qadrtech-sdlc-explainer
generated_by: claude
tags: [qadrtech, video, motion-graphics]
variants:
  - id: sdlc-en
    label: SDLC Explainer (EN, 9:16)
    path: ~/Projects/qadrtech-hq/videos/qadrtech-sdlc-explainer/out/qadrtech-sdlc-en.mp4
    format: 1080x1920 30fps
    duration: 46.0
    status: rendered
    published: []
  - id: sdlc-en-wide
    label: SDLC Explainer (EN, 16:9)
    path: ~/Projects/qadrtech-hq/videos/qadrtech-sdlc-explainer/out/qadrtech-sdlc-en-wide.mp4
    format: 1920x1080 30fps
    duration: 46.0
    status: rendered
    published: []
---

Video edukasi alur kerja sama dengan Qadr Tech Solutions (SDLC): Conversation → Scope → Build & Review → Handover & upkeep. Konsep visual "One message becomes a system": satu pesan chat yang berubah jadi peta proses, lembar scope (IN/OUT + stempel "Approved by you"), aplikasi yang tumbuh v0.1→v0.3 lewat feedback, lalu serah terima (sistem, source code, walkthrough) + garis detak maintenance. Stage tracker 4 segmen tampil sepanjang video dengan checkpoint "✓ You decide" dan label SDLC per tahap. Format 9:16 + 16:9.

- Naskah: ~/Projects/qadrtech-hq/videos/qadrtech-sdlc-explainer/docs/naskah-voice-over.md
- Sumber fakta: qadr.tech (`components/Landing/WorkingProcess.js`, `pages/about.js`)

## Catatan produksi
- VO: 6 klip avatar (`voiceovers/part-1..6.mp4`), semua kata sesuai naskah, tanpa pengulangan. Trim di `vo.config.json` → `public/vo.wav` 42,68 dtk; video 46,0 dtk dengan end card.
- Musik dan SFX procedural (`scripts/audio.mjs`), peak −1,2 dB.
- Perlu dicek user: tonton dengan suara (mix SFX, pelafalan "Koder dot tech").
