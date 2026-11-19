---
tags: [blender, mmd, 3d, claude-code, mcp]
---

# Blender + MMD: Cara Membuka, Mengedit, dan Ganti Model

Catatan ini merangkum setup Blender yang dikerjakan bersama Claude Code pada 2026-11-15, dengan model **Vesna** (`.pmx`, format MMD) sebagai contoh. Semua file kerja ada di `~/sandbox/blender-assets/` (di luar vault, sesuai aturan vault).

## 1. Lokasi penting

| Apa | Lokasi |
|---|---|
| Blender 5.3.0 (tarball, tanpa instalasi) | `~/Downloads/blender-5.3.0-linux-x64/blender` |
| Folder kerja model | `~/sandbox/blender-assets/vesna/` |
| Model asli (salinan, jangan diubah) | `~/sandbox/blender-assets/vesna/src/` |
| Model asli (unduhan) | `~/Downloads/薇斯纳_by_原神_0576ff5aa94fad52f3d88c00e2702390/` |
| Hasil render (PNG dan MP4) | `~/sandbox/blender-assets/vesna/out/` |
| Skrip Python (`*.py`) | `~/sandbox/blender-assets/vesna/` |
| Add-on MMD | MMD Tools, terpasang lewat Edit > Preferences > Get Extensions |
| MCP Blender | `~/.local/bin/blender-mcp` (dipasang dengan pipx), terdaftar global |

## 2. File `.blend` dan urutan pembuatannya

Setiap file dibuat dari file sebelumnya. Kalau mau mengedit, **pilih file di ujung rantai yang paling sesuai**.

```text
vesna.blend            hasil impor PMX (mentah, objek fisika masih tampak)
  └─ vesna_clean.blend    fisika disembunyikan, kamera dan lampu dipasang
       ├─ vesna_anim.blend    animasi Idle (60 frame)
       │    └─ vesna_toon.blend   cel shading, outline berwarna, ekspresi, latar cerah
       │         └─ vesna_pose.blend   pose dinamis (action PoseDynamic)  <- paling baru
       └─ vesna_walk.blend    animasi jalan (40 frame, in-place)
```

File `*.blend1` adalah cadangan otomatis Blender. Boleh dihapus kalau disk menipis.

## 3. Membuka dan mengedit secara manual (GUI)

1. Jalankan Blender:
   ```bash
   ~/Downloads/blender-5.3.0-linux-x64/blender ~/sandbox/blender-assets/vesna/vesna_pose.blend
   ```
   Atau buka Blender dari menu aplikasi, lalu **File > Open**.
2. Tekan **Z** di viewport dan pilih **Material Preview** supaya tekstur terlihat.
3. Mengubah pose:
   - Pilih objek `薇斯纳_arm` di Outliner (kalau tidak terlihat, klik ikon mata di sebelahnya).
   - Masuk **Pose Mode** (Ctrl+Tab), pilih bone, tekan **R** untuk memutar, **G** untuk menggeser.
   - Tekan **I** untuk menyimpan keyframe di frame yang aktif.
4. Mengubah ekspresi wajah: pilih `薇斯纳_mesh`, buka tab Object Data (ikon segitiga hijau), bagian **Shape Keys**. Geser nilai `口角上げ` (senyum), `にこり`, `なごみ`, dan lainnya.
5. Mengubah warna: pilih `薇斯纳_mesh`, buka tab **Shading**, lalu pilih material (misalnya `肌` untuk kulit, `髮` untuk rambut). Sisipkan node **Hue/Saturation/Value** setelah node tekstur.
6. Render satu gambar: **Render > Render Image** (F12). Animasi: **Render > Render Animation** (Ctrl+F12).
7. Simpan dengan **Ctrl+S**. Untuk menyimpan versi baru tanpa menimpa, pakai **File > Save As**.

Objek fisika (447 rigid body dan 631 joint) disembunyikan lewat `hide_viewport`. Biarkan tetap tersembunyi, kecuali Anda mau mem-bake fisika rambut dan rok.

## 4. Menjalankan skrip lagi (tanpa membuka Blender)

Pola umum:

```bash
cd ~/sandbox/blender-assets/vesna
~/Downloads/blender-5.3.0-linux-x64/blender -b <file.blend> -P <skrip.py>
```

Skrip yang ada, urut sesuai fungsinya:

| Skrip | Fungsi | Dijalankan pada |
|---|---|---|
| `import_pmx.py` | Impor `.pmx`, simpan `vesna.blend` | scene kosong |
| `clean_render.py` | Sembunyikan fisika, pasang kamera dan lampu | `vesna.blend` |
| `adjust.py` | Tone mapping Standard, latar gelap, cahaya | `vesna_clean.blend` |
| `anim.py` / `render_anim.py` | Animasi Idle dan render | `vesna_clean.blend` / `vesna_anim.blend` |
| `walk.py` / `render_walk.py` | Animasi jalan dan render | `vesna_clean.blend` / `vesna_walk.blend` |
| `toon.py` | Cel shading, outline, latar | `vesna_anim.blend` |
| `toon_tweak.py` | Setel ambient dan ambang bayangan | `vesna_toon.blend` |
| `expr.py` | Senyum dan semu merah pipi | `vesna_toon.blend` |
| `illus.py` | Outline berwarna, bayangan lembut, kilau rambut, latar cerah | `vesna_toon.blend` |
| `pose.py`, `palm_final.py` | Pose dinamis dan tangan terbuka | `vesna_toon.blend` / `vesna_pose.blend` |
| `inspect.py`, `inspect2.py`, `bones.py`, `mats.py`, `morphs.py` | Hanya membaca (daftar objek, bone, material, morph) | bebas |

Video dibuat dengan menyatukan urutan PNG memakai ffmpeg, karena Blender 5.x memindahkan pilihan format video:

```bash
ffmpeg -y -framerate 30 -i out/frames/f_%04d.png -c:v libx264 -pix_fmt yuv420p -crf 18 out/video.mp4
```

## 5. Blender MCP (Claude Code mengontrol Blender langsung)

Alurnya: `Claude Code <-stdio-> blender-mcp <-TCP localhost:9876-> add-on MCP di Blender`.

Status saat ini:
- Add-on **MCP 1.0.3** dari repositori Blender Lab sudah terpasang dan **Auto Start** aktif.
- Paket `blender-mcp` terpasang dengan pipx dan terdaftar di scope **user** (berlaku di semua folder).

Syarat supaya tersambung:
1. Blender sedang terbuka.
2. **Edit > Preferences > System > Network > Allow Online Access** aktif (add-on menolak start kalau mati).
3. Di **Preferences > Add-ons > MCP** statusnya "Server is running". Kalau belum, klik **Start MCP Bridge Server**.
4. Sesi Claude Code baru (tool MCP termuat saat sesi dimulai). Cek dengan:
   ```bash
   claude mcp list | grep blender
   ```

Memasang ulang dari nol kalau perlu:

```bash
pipx install "git+https://projects.blender.org/lab/blender_mcp.git#subdirectory=mcp"
claude mcp add -s user blender -- blender-mcp
```

Peringatan: server ini bisa menjalankan kode Python bebas di Blender. Jangan membuka file `.blend` yang tidak dipercaya saat server menyala.

## 6. Ganti model

Langkah umum untuk model `.pmx` baru, misalnya `nama-model`:

1. Unduh model, baca readme-nya, lalu salin ke folder kerja baru:
   ```bash
   mkdir -p ~/sandbox/blender-assets/nama-model
   cp -r ~/Downloads/<folder-model> ~/sandbox/blender-assets/nama-model/src
   cp ~/sandbox/blender-assets/vesna/*.py ~/sandbox/blender-assets/nama-model/
   ```
2. Edit `import_pmx.py`: ubah `src` ke jalur `.pmx` baru dan jalur `filepath` simpan. Skala `0.08` membuat tinggi karakter sekitar 1,6 m. Sesuaikan kalau modelnya lebih besar atau kecil.
3. Jalankan `import_pmx.py`. Setelah itu jalankan `inspect2.py`, `bones.py`, `mats.py`, dan `morphs.py` untuk mencatat nama objek, bone, material, dan morph model baru.
4. Sesuaikan skrip lain berdasarkan hasil langkah 3. Hal yang spesifik model:

   | Skrip | Yang harus diganti |
   |---|---|
   | `clean_render.py`, `toon.py`, `expr.py` | Nama objek `薇斯纳_mesh` dan `薇斯纳_arm` (ikut nama model) |
   | `toon.py`, `illus.py` | Daftar `TOON`, `SKIN`, `HAIR`: nama material (`肌`, `髮`, dan seterusnya) |
   | `anim.py`, `walk.py`, `pose.py` | Nama bone (`腕.L`, `センター`, dan lainnya). Sebagian besar model MMD memakai nama standar yang sama, jadi sering tidak perlu diubah |
   | `expr.py`, `pose.py` | Nama shape key ekspresi (`口角上げ`, `にこり`, `なごみ`) dan material blush (`照れ`) |
   | `clean_render.py`, `toon.py` | Kamera: tinggi target (`0.85`, `0.95`) dan jarak (`4.6`) diukur dari tinggi Vesna |

5. Jalankan urutan skrip dari bagian 4 dan cek hasilnya dengan render pratinjau setiap langkah.

Cara tercepat: minta Claude Code mengerjakannya. Contoh perintah:

> Impor model baru dari `~/Downloads/<folder>` ke `~/sandbox/blender-assets/<nama>`, ikuti catatan `03-resources/blender-mmd-workflow.md`, lalu terapkan gaya toon yang sama seperti Vesna.

## 7. Gerakan idle/jalan/lari dan game uji Three.js

Dibuat 2026-11-15. Gerakan ditulis dengan keyframe lewat skrip (tanpa mocap), diekspor ke glTF, lalu diuji di game kecil.

| Apa | Lokasi |
|---|---|
| Helper animasi (aim, foot roll, lengan, jari) | `~/sandbox/blender-assets/vesna/anim_lib.py` |
| Definisi klip Idle, Walk, Run | `~/sandbox/blender-assets/vesna/make_clips.py` |
| Ekspor ke glTF | `~/sandbox/blender-assets/vesna/export_glb.py` |
| Cek hasil ekspor | `~/sandbox/blender-assets/vesna/verify_glb.py` |
| Game uji (Vite + three) | `~/sandbox/vesna-game/` |

Putaran penyetelan gerakan:

```bash
cd ~/sandbox/blender-assets/vesna
B=~/Downloads/blender-5.3.0-linux-x64/blender
$B -b vesna_clean.blend -P make_clips.py     # buat klip, ukur selip kaki, contact sheet di out/
$B -b vesna_motion.blend -P export_glb.py    # tulis vesna.glb dan salin ke game
$B -b -P verify_glb.py                       # opsional: bandingkan pose glb dengan sumber
```

Menjalankan game:

```bash
cd ~/sandbox/vesna-game
npm run dev        # buka http://localhost:5173
```

Kontrol: WASD atau panah untuk gerak, Shift untuk lari, seret mouse untuk memutar kamera, scroll untuk zoom. Panel Debug bisa memaksa satu klip, memperlambat putaran, dan menyalakan atau mematikan spring bone dan outline.

Parameter URL untuk pengecekan: `?state=Walk&phase=0.25&yaw=270&nogui` membekukan klip pada fase tertentu.

Hal yang perlu diingat:
- Klip dibuat di tempat (in-place). Kecepatan maju tiap klip ada di `clips.json` (jalan 0,95 m/dtk, lari 2,35 m/dtk), dan game memakainya supaya kaki tidak tergelincir.
- Kaki dideformasi bone `足D / ひざD / 足首D` yang mengikuti IK lewat constraint, jadi ekspor harus memakai sampling (bake). `export_glb.py` sudah mengaturnya.
- Rambut, rok, dan sayap digerakkan spring bone di `src/springbones.js`, bukan fisika MMD. Track animasi bone itu dibuang saat klip dimuat.
- Ekspor hanya membawa 6 morph wajah dan tekstur dasar. Efek sphere map MMD tidak ikut.
- Klip `SitType` (duduk mengetik, 6 detik) memakai ukuran di `SIT` pada `make_clips.py`: dudukan 0,42 m, meja 0,63 m. Properti di `src/props.js` harus memakai ukuran yang sama. Di game, tekan E dalam jarak 3 m dari meja: karakter berjalan ke titik berdiri, berputar, memutar klip `SitDown`, lalu `SitType`. E lagi memutar `StandUp`. Klip duduk dibuat di sekitar titik asal bangku, sedangkan posisi berdiri 12 cm di depannya, jadi `character.js` menggeser root mengikuti bobot klip duduk supaya badan tidak meluncur saat crossfade.
- Uji urutan duduk tanpa keyboard: `?auto&warm=900&standAt=600` menekan E secara simulasi, dan judul halaman mencatat perpindahan mode.
- Parameter URL tambahan: `?state=SitType`, `?idle=0.25` (bekukan fase idle), `?warm=150` (simulasikan spring bone dulu sebelum screenshot).

## 8. Catatan dan masalah yang diketahui

- **Disk terbatas.** Saat catatan ini ditulis sisa disk sekitar 6 GB (partisi 97% terpakai). Folder `vesna` memakai 271 MB, dan tiap `.blend` sekitar 14 MB. Hapus `*.blend1` dan `out/frames` kalau perlu ruang.
- **Fisika rambut dan rok belum aktif.** Objek rigid body disembunyikan, sehingga rambut dan rok hanya ikut gerakan rig. Aktifkan dan bake kalau mau mengibar.
- **Shader asli MMD tidak terbawa ke Blender** (file `.fx`). Tampilan toon di sini dibuat ulang dengan node shader sendiri.
- **Cel shading memakai `Shader to RGB`**, jadi hanya bekerja di render **EEVEE**, bukan Cycles.
- **Blender 5.x:** struktur action berubah (tidak ada `action.fcurves`), dan format video di `image_settings` dipindah. Skrip lama dari tutorial Blender 3 atau 4 bisa gagal.
- **Material mata, sayap, dan kristal** sengaja tidak dibuat toon supaya kilau pelanginya tetap ada.
- Animasi **Idle** sudah ikut di `vesna_toon.blend`, jadi bisa dirender dengan gaya toon lewat `render_anim.py`. Animasi **Walk** hanya ada di `vesna_walk.blend` (tanpa gaya toon). Untuk jalan dengan gaya toon, jalankan `toon.py` dan `illus.py` pada file walk. Keduanya belum saya uji. Pose di `vesna_pose.blend` menghapus action Idle dari rig, dan ekspresi (shape key) tidak ikut dianimasikan.
