# Prompt: Video Motion Graphics dari Voice Over MP4

Dokumentasi untuk membuat ulang video promo motion graphics (seperti `video/promo/out/qadrlabs-promo.mp4`) dengan **voice over dari file MP4** sebagai acuan timing.

---

## 1. Persiapan

1. Simpan rekaman voice over (MP4 / M4A / WAV) di folder proyek, misalnya `video/voiceover.mp4`.
2. Siapkan naskah dialog (teks yang diucapkan di rekaman). Tidak harus 100% sama — transkripsi otomatis akan mengoreksi timing.
3. Pastikan tersedia: Node.js ≥ 20, `ffmpeg`, koneksi internet (untuk install Remotion & model whisper sekali saja).

---

## 2. Prompt Siap Pakai

Salin prompt di bawah ke Claude Code, lalu ganti bagian `<...>`.

```text
Buat video motion graphics yang dinamis dan berkualitas showcase (tunjukkan skill motion designer terbaikmu)
tentang <NAMA PRODUK / WEBSITE, mis. qadrlabs.com>.

Voice over:
- Gunakan audio dari file <PATH FILE, mis. video/voiceover.mp4> sebagai voice over.
- Ekstrak audionya dengan ffmpeg, lalu transkripsi dengan whisper.cpp
  (@remotion/install-whisper-cpp) untuk mendapatkan timestamp per kata.
- Sinkronkan setiap scene dan animasi tepat pada kata yang diucapkan.
- Durasi video = durasi voice over + ±2 detik end card logo.
- Catatan pelafalan: "<cara diucapkan, mis. Koderlabs dot com>" = "<ejaan benar, mis. qadrlabs.com>".
  Tulis ejaan yang benar di layar.

Naskah dialog (acuan):
"<PARAGRAF 1>"
"<PARAGRAF 2>"
"<PARAGRAF 3>"
"<PARAGRAF 4>"

Riset konten:
- Pelajari produk dulu dari codebase ini (views, logo di public/img/logo, warna brand di resources/sass)
  dan data nyata dari database (jumlah post, series, tag populer) agar konten akurat — jangan mengarang angka.
- <ATAU: kunjungi halaman <URL> untuk mempelajari produk.>

Spesifikasi output:
- Format: MP4 via Remotion, <vertical 1080x1920 | horizontal 1920x1080>, 30fps, H.264 (crf 18).
- Buat proyek Remotion terpisah di <PATH, mis. video/promo/> — jangan ubah dependency aplikasi utama.
- Semua timing di satu file `src/timing.ts` supaya mudah disesuaikan.
- Caption kinetik per kata (highlight kata yang sedang diucapkan); sembunyikan caption saat kalimat
  yang sama sudah tampil sebagai tipografi besar di layar.
- Gunakan logo dan warna brand asli; font <mis. Poppins + JetBrains Mono>.
- Setiap scene punya konsep visual sendiri (bukan sekadar teks), transisi yang mengalir, easing konsisten,
  spring physics, background hidup (grid, glow, grain).

Verifikasi:
- Render beberapa still frame per scene dan periksa layout/keterbacaan sebelum render final.
- Cek hasil dengan ffprobe (resolusi, fps, durasi, ada stream audio).

Mulai dengan plan mode: tanyakan hal yang belum jelas (format, durasi, orientasi) sebelum eksekusi.
```

### Variasi singkat

Jika proyek Remotion `video/promo/` sudah ada dan hanya ingin **mengganti voice over / naskah**:

```text
Di proyek video/promo, ganti voice over dengan <PATH FILE BARU>.
Transkripsi ulang dengan scripts/transcribe.mjs, perbarui src/timing.ts (SCENES, PHRASES, SILENT_PHRASES)
sesuai timestamp kata yang baru, sesuaikan cue animasi di tiap scene, lalu render ulang ke out/.
Naskah baru: "<NASKAH>"
```

---

## 3. Keputusan yang Akan Ditanyakan Claude

Siapkan jawabannya agar proses lebih cepat:

| Pertanyaan | Pilihan | Rekomendasi |
|---|---|---|
| Format output | MP4 (Remotion) / HTML animasi | MP4 (Remotion) |
| Durasi | Ikuti panjang VO / paksa durasi tertentu | Ikuti VO + 2 detik end card |
| Orientasi | Vertical 1080×1920 / Horizontal 1920×1080 | Ikuti orientasi rekaman / platform tujuan |
| Sumber suara | VO dari MP4 / TTS macOS `say` / tanpa audio | VO dari MP4 |

> Jika durasi target lebih panjang dari VO (mis. diminta 48 detik tapi VO 34 detik), pilih salah satu: ikuti VO (paling rapi), tambah intro/outro + musik, atau beri jeda antar kalimat.

---

## 4. Alur Kerja yang Terjadi (Referensi Teknis)

1. **Ekstrak audio**
   ```bash
   ffmpeg -i ../voiceover.mp4 -vn -c:a aac -b:a 192k public/vo.m4a           # untuk video
   ffmpeg -i ../voiceover.mp4 -vn -ar 16000 -ac 1 -c:a pcm_s16le scripts/vo16k.wav  # untuk whisper
   ```
2. **Deteksi jeda (opsional, cek cepat)**
   ```bash
   ffmpeg -i ../voiceover.mp4 -af silencedetect=noise=-35dB:d=0.35 -f null - 2>&1 | grep silence_
   ```
3. **Transkripsi per kata** — `node scripts/transcribe.mjs` → `scripts/captions.json`
   (install whisper.cpp + model `base.en` otomatis; untuk VO bahasa Indonesia gunakan model `base`/`small` tanpa `.en`).
4. **Timing** — isi `src/timing.ts`: batas scene (`SCENES`), kata per frasa (`PHRASES`), frasa tanpa caption (`SILENT_PHRASES`).
5. **Scene** — satu komponen per scene di `src/scenes/`, cue animasi memakai detik lokal (`pop()`, `ramp()` di `src/theme.tsx`).
6. **Preview & render**
   ```bash
   npm run studio                                    # scrub interaktif di browser
   npx remotion still Promo out/f.jpg --frame=300 --scale=0.5
   npm run render                                    # → out/qadrlabs-promo.mp4
   ffprobe out/qadrlabs-promo.mp4
   ```

---

## 5. Tips Agar Hasil Maksimal

- **Rekaman bersih** (tanpa musik latar) → timestamp whisper lebih akurat.
- **Sebutkan pelafalan nama brand** di prompt; whisper akan menulis sesuai bunyi (mis. "coderlabs").
- **Minta data nyata**: angka dari database/website membuat video lebih kredibel.
- **Satu file timing**: geser sinkronisasi cukup dengan mengedit `src/timing.ts`, lalu render ulang.
- **Musik latar** sebaiknya ditambahkan terpisah (mis. di editor video) atau minta Claude menambahkan `<Audio>` kedua dengan volume rendah.
