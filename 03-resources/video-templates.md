---
tags: [video, template, workflow]
---

# Template Video Motion Graphics

Daftar template video dan alur pencatatannya ke vault. Aturan lengkap untuk AI agent ada di `AGENTS.md` vault, bagian **Video Tracking**. Status dan lokasi semua video bisa dicek di Vault Hub (`~/Sites/vault-hub`, halaman **Video**).

## Daftar template

| Key | Brand | Untuk | Path template | Hasil MP4 |
| --- | --- | --- | --- | --- |
| `qadrtech-promo` | qadrtech | Video promo/portofolio produk (VO avatar 5 part, ±40 dtk, 30fps) | `~/Projects/qadrtech-hq/videos/_template` | `~/Projects/qadrtech-hq/videos/<project>/out/*.mp4` |
| `qadrlabs-lesson-tts` | qadrlabs | Video pembelajaran dengan narasi Gemini TTS (45–90 dtk, 30fps) | `~/Projects/qadrtech-hq/videos/learning-video-qadrlabs/algorithm` | `~/Projects/qadrtech-hq/videos/learning-video-qadrlabs/<materi>/out/*.mp4` |
| `qadrlabs-php-basics` | qadrlabs | Seri dasar programming PHP tanpa narator (15–30 dtk, 60fps), satu repo untuk semua episode | `~/Projects/qadrlabs/learning-video` | `~/Projects/qadrlabs/learning-video/output/*.mp4` |

## Memulai video baru

### qadrtech-promo

```bash
cd ~/Projects/qadrtech-hq/videos
sh _template/scripts/new-video.sh <nama-project>
cd <nama-project>
claude        # atau: codex
```

> Buat video portfolio untuk project di `<path>`. Ikuti AGENTS.md. Mulai dari riset dan naskah.

### qadrlabs-lesson-tts

```bash
cd ~/Projects/qadrtech-hq/videos/learning-video-qadrlabs
sh algorithm/scripts/new-lesson.sh <nama-materi>
cd <nama-materi>
claude        # atau: codex
```

> Buat video pembelajaran tentang `<topik>` untuk qadrlabs.com. Ikuti AGENTS.md. Mulai dari riset dan naskah.

### qadrlabs-php-basics

```bash
cd ~/Projects/qadrlabs/learning-video
codex         # atau: claude
```

> Buat episode baru tentang `<topik>`. Ikuti AGENTS.md dan katalog di README.

### Dari vault

Prompt juga bisa dijalankan dari folder vault (`cd ~/obsidian-vault && claude`). Agent akan membaca catatan ini untuk memilih template.

> Buat video `<promo/portfolio/pembelajaran>` tentang `<project/topik>` dengan template `<key>` (lihat `03-resources/video-templates.md`). Catat di vault, lalu ikuti AGENTS.md template tersebut. Mulai dari riset dan naskah.

Untuk produksi yang panjang, lebih baik memulai dari folder project. Di sana `AGENTS.md` template langsung terbaca otomatis, sedangkan kalau dimulai dari vault agent harus membacanya sendiri.

## Alur kerja

1. Jalankan `claude` atau `codex` di folder template/project atau di vault, lalu tulis prompt.
2. Agent membuat folder project dan langsung membuat catatan di `01-projects/<brand>/video/` dengan status `in-progress`.
3. Agent mengikuti `AGENTS.md` template sampai video selesai dirender.
4. Agent mengisi `variants` (path MP4 per versi) dengan status `rendered`.
5. Cek video, status, dan path-nya di Vault Hub → **Video** (filter **Belum dipublish**).
6. Setelah upload, buka kartu video, pilih versinya, lalu klik **+ Catat publikasi** (platform + URL). Status versi itu otomatis menjadi `published`.
7. Selesai. Status project menjadi `published` setelah semua versinya dipublish.

## Izin akses agent

- **Claude Code:** setiap template punya `.claude/settings.json` dengan `additionalDirectories` ke vault. File ini ikut tersalin ke project baru. Vault juga punya `.claude/settings.json` yang memberi akses ke folder-folder template. Kalau ada project lama tanpa file itu, jalankan `claude --add-dir ~/obsidian-vault`.
- **Codex:** `~/.codex/config.toml` → `[sandbox_workspace_write] writable_roots` berisi vault dan folder template. Bisa juga dengan cara manual: `codex --add-dir ~/obsidian-vault`.

## Menambah template baru

1. Tambahkan baris di tabel di atas (key, brand, path, lokasi hasil).
2. Tambahkan bagian **Vault tracking** di `AGENTS.md` template (contohnya ada di `_template/AGENTS.md`) dan `.claude/settings.json`.
3. Tambahkan folder hasilnya ke `VIDEO_ROOTS` di `~/Sites/vault-hub/.env` supaya videonya bisa diputar di Vault Hub.
4. Tambahkan folder template ke `writable_roots` Codex dan ke `.claude/settings.json` vault.
