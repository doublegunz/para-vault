---
type: video
brand: qadrtech
title: Insight — Recover Knowledge from Code (EN)
date: 2026-11-06
status: rendered
template: qadrtech-insight-tts
project_dir: ~/Projects/qadrtech-hq/videos/qadrtech-insight/lessons/recover-knowledge
generated_by: claude
tags: [qadrtech, video, motion-graphics, edukasi]
variants:
  - id: en
    label: Recover Knowledge (EN, 9:16)
    path: ~/Projects/qadrtech-hq/videos/qadrtech-insight/out/recover-knowledge-en.mp4
    format: 1080x1920 30fps
    duration: 71.0
    status: rendered
    published: []
---

# Insight — Recover Knowledge from Code

Video edukasi Instagram qadr.tech (±60 detik, bahasa Inggris, voice Gemini TTS Sulafat), diangkat dari artikel *Your Developer Left and the Documentation Is Gone: How to Recover Knowledge from Code* (terbit 2026-11-06). Targetnya calon klien dan publik. URL artikel tidak ditampilkan di video; CTA-nya hanya `qadr.tech`.

Pola cerita: masalah (developer pergi / aplikasi dibuat dengan AI tanpa dokumentasi) → twist 1 (kodenya masih "mengingat") → metode baca per lapisan → twist 2 (kode tidak bisa menjelaskan *kenapa*) → kesimpulan.

- Sumber artikel: `~/Projects/qadrtech-hq/qadr-tech/data/blog/recover-knowledge-from-code.mdx`
- Naskah: `~/Projects/qadrtech-hq/videos/qadrtech-insight/lessons/recover-knowledge/docs/naskah-voice-over.md`
- Teks TTS: `~/Projects/qadrtech-hq/videos/qadrtech-insight/lessons/recover-knowledge/docs/tts.json`

Episode pertama dari project baru `qadrtech-insight` (template `qadrtech-insight-tts`), yang akan dipakai lagi untuk artikel insight berikutnya.

## Status produksi

- 2026-11-06: project dibuat, naskah draft menunggu review.
- 2026-11-06: naskah disetujui. VO dibuat dengan `gemini-3.8-flash-tts` (Sulafat, 7 part); transkrip cocok dengan naskah. Durasi video 71 detik. Render `out/recover-knowledge-en.mp4`.
- Scene: dashboard yang tetap berjalan sementara developer pergi dan dokumen tersobek → kotak hitam dengan pertanyaan → case file klien (anonim) yang di-zoom masuk ke kode → kaca pembesar dan lapisan (routes → fitur, database → domain model) → roles/status/job malam + cap "Not a security control" → WHAT vs WHY dan open questions → folder `docs/` terisi 8 dokumen → end card qadr.tech.
- Caption Instagram: `~/Projects/qadrtech-hq/videos/qadrtech-insight/lessons/recover-knowledge/caption-instagram-en.md`
- Perlu dicek dengan telinga: pelafalan "Koder dot tech" dan "lost system" di part 7 (whisper mendengar "loss"), serta keseimbangan musik.
