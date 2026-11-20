---
tags: [blender, mmd, 3d, claude-code, prompt, panduan]
---

# Panduan Lanjut: Eksplorasi Blender dan Prompt AI untuk Mengedit Karakter

Catatan ini melanjutkan [[blender-mmd-workflow]]. Catatan itu berisi letak file, skrip, dan cara ekspor. Catatan ini berisi dua hal: apa yang bisa dipelajari berikutnya, dan cara menulis prompt supaya AI (Claude Code) mengedit karakter dengan hasil yang bisa diandalkan.

Kondisi per 2026-11-15: karakter Vesna punya klip `Idle`, `Walk`, `Run`, `SitType`, `SitDown`, dan `StandUp`, dan bisa diuji di game `~/sandbox/vesna-game/`.

## Bagian 1: Melanjutkan eksplorasi Blender

### Dua cara bekerja dengan AI

| Cara | Kapan dipakai | Catatan |
|---|---|---|
| **Skrip headless** (AI menulis Python, lalu menjalankan `blender -b file.blend -P skrip.py`) | Pekerjaan yang harus bisa diulang: animasi, ekspor, material | Semua pekerjaan sejauh ini memakai cara ini. Skripnya tersimpan, jadi hasilnya bisa dibuat ulang |
| **Blender MCP** (AI mengontrol Blender yang sedang terbuka) | Eksplorasi interaktif: bertanya isi scene, mencoba perubahan kecil sambil melihat viewport | Dipakai untuk membuat pakaian Ellie (2026-11-19): AI membuka file, membangun mesh, dan merender pratinjau, lalu hasil akhirnya ditulis sebagai skrip. Butuh Blender terbuka dan server MCP berjalan |

Saran: pakai MCP untuk bertanya dan mencoba, lalu minta AI menuliskan hasil akhirnya sebagai skrip. Perubahan yang hanya dilakukan lewat MCP hilang kalau file tidak disimpan, dan tidak bisa diulang untuk model lain.

### Urutan belajar yang disarankan

Urutan ini dari yang paling dekat dengan pekerjaan yang sudah ada.

1. **Navigasi dan Pose Mode.** Buka `vesna_motion.blend`, pilih `薇斯纳_arm`, masuk Pose Mode (Ctrl+Tab), putar bone dengan R. Tujuannya mengenali nama bone, supaya bisa menyebutnya di prompt.
2. **Timeline dan NLA.** Tiap klip adalah satu track di NLA Editor. Bunyikan satu track (solo) untuk memutar satu klip. Ini cara melihat hasil `make_clips.py` langsung di Blender.
3. **Graph Editor.** Lihat kurva satu bone, misalnya `センター` saat jalan. Ini membantu memahami kenapa gerakan terasa kaku atau memantul.
4. **Shape key.** Model ini punya 64 ekspresi wajah (`まばたき` kedip, `笑い` senyum mata, `あ` mulut terbuka, dan seterusnya). Hanya 6 yang diekspor ke game.
5. **Shader Editor.** Bandingkan material asli (`vesna_clean.blend`) dengan versi toon (`vesna_toon.blend`).
6. **Fisika MMD.** Objek rigid body dan joint masih ada tetapi disembunyikan. Di game, fisika diganti spring bone.
7. **Pemodelan dasar.** Properti di game (bangku, meja, laptop) dibuat dari bentuk dasar di kode. Membuat properti yang lebih bagus di Blender adalah latihan pemodelan yang ukurannya pas.

### Ide proyek berikutnya

| Ide | Tingkat kesulitan | Catatan |
|---|---|---|
| Klip baru: melambai, melompat, menunduk hormat | Rendah | Pola yang sama dengan klip yang ada |
| Ekspresi wajah di dalam klip (senyum saat melambai) | Rendah | Ekspor morph animation saat ini dimatikan di `export_glb.py` |
| Senjata di tangan (`法杖.pmx`, `魔法剑1.pmx`) | Sedang | Belum pernah diimpor. Perlu ditempelkan ke bone tangan |
| Terbang dengan sayap | Sedang | Bone `上翼親` dan `下翼親` sudah dipakai untuk kepakan kecil |
| Mocap dari Mixamo | Tinggi | Paling natural, tetapi retarget ke rig MMD belum pernah dicoba |
| Model kedua | Sedang | Ikuti bagian "Ganti model" di [[blender-mmd-workflow]]. Langkah itu belum pernah diuji pada model lain |

### Hal yang perlu dijaga

- **Disk.** Per 2026-11-19 sisa ruang sekitar 59 GB. Folder `out/` (render dan frame) dan file `*.blend1` adalah yang paling aman dihapus.
- **Jangan menimpa file sumber.** `vesna.blend` dan `vesna_clean.blend` adalah dasar semua file lain. Hasil eksperimen disimpan dengan nama baru.
- **Blender 5.3.** Banyak tutorial dan jawaban AI memakai API Blender 3 atau 4. Yang sudah terbukti berubah: `action.fcurves` tidak ada lagi, dan format video tidak lagi dipilih lewat `image_settings.file_format = 'FFMPEG'`.

## Bagian 2: Menulis prompt untuk mengedit karakter

### Prinsip yang terbukti dari pengerjaan ini

1. **Sebut bagian badan dan klipnya.** "Lari masih aneh" memaksa AI menebak. "Saat lari, tangan depan menembus perut" langsung bisa dikerjakan.
2. **Beri gambar referensi.** Tiga gambar referensi lari menyelesaikan apa yang dua kali riset web tidak bisa. Screenshot masalah (tangan menembus rok, rok tersingkap) juga jauh lebih jelas daripada deskripsi.
3. **Sebut gaya dan tujuannya, bukan hanya gerakannya.** "Jalan catwalk, kepala tidak goyang, lebih kalem" memberi arah yang bisa diukur. "Lebih natural" tidak.
4. **Minta diukur, bukan hanya dilihat.** AI hanya melihat gambar diam, jadi tidak bisa menilai kehalusan gerak. Yang bisa diukurnya: selip kaki, kestabilan kepala, getaran rok, sambungan loop. Kedipan rok saat duduk baru ketemu penyebabnya setelah diukur (69 mm per langkah).
5. **Satu masalah per putaran.** Perbaiki jalan dulu, nilai, baru lari. Kalau tiga hal diubah sekaligus dan hasilnya memburuk, sulit tahu yang mana penyebabnya.
6. **Minta riset kalau AI terlihat menebak.** Riset catwalk mengubah arah (kepala diam, pinggul tidak dilebih-lebihkan). Tetapi riset juga bisa menyesatkan: riset lari perempuan pertama menghasilkan pose "tangan sayap" yang tidak cocok.
7. **Nilai sendiri saat bergerak.** Setelah tiap perubahan, muat ulang game dan beri tahu AI apa yang terlihat. Itu masukan yang tidak bisa didapat AI sendiri.

### Kerangka prompt

```text
[Klip atau bagian] : klip apa, atau bagian karakter mana
[Masalah]          : apa yang terlihat salah, di momen apa, dari sudut mana
[Yang diinginkan]  : gaya atau hasil akhir, kalau bisa dengan gambar referensi
[Batasan]          : apa yang tidak boleh berubah
[Cek]              : apa yang harus diukur atau di-screenshot sebelum melapor
```

Tidak semua baris wajib. Untuk perbaikan kecil, masalah dan yang diinginkan sudah cukup.

### Contoh prompt siap pakai

Memulai sesi baru (AI tidak ingat sesi sebelumnya):

```text
Baca 03-resources/blender-mmd-workflow.md dan 03-resources/blender-eksplorasi-dan-prompt-ai.md,
lalu lihat ~/sandbox/blender-assets/vesna/make_clips.py. Saya mau melanjutkan animasi karakter Vesna.
Jalankan game di ~/sandbox/vesna-game dengan npm run dev.
```

Memperbaiki gerakan yang ada:

```text
Di klip Walk, ayunan lengan terasa terlalu kecil dan kaku. Saya mau lengan berayun sedikit lebih
lebar dengan siku yang lebih lentur, tapi kepala dan bahu tetap tenang seperti sekarang.
Jangan ubah langkah kaki. Ukur selip kaki dan kestabilan kepala sesudahnya, dan beri saya
screenshot tampak depan dan samping di empat fase.
```

Membuat klip baru:

```text
Buat klip baru "Wave": karakter berdiri dan melambaikan tangan kanan setinggi kepala selama
sekitar 2 detik, lalu kembali ke pose idle. Tangan kiri tetap rileks di samping dan tidak boleh
menembus rok. Tambahkan ke make_clips.py dengan pola yang sama, ekspor, dan pasang di game
dengan tombol Q. Referensi pose terlampir.
```

Mengubah warna atau material:

```text
Ubah warna rambut menjadi merah muda pastel dan gaun menjadi ungu, tanpa mengubah file tekstur
asli (pakai node Hue/Saturation per material). Simpan sebagai file .blend baru. Material mata,
sayap, dan kristal jangan diubah. Render perbandingan sebelum dan sesudah dari depan.
```

Menangani tembus (clipping):

```text
Saat klip Run, tangan kiri menembus cape di bahu pada waktu lengan terayun ke belakang
(screenshot terlampir). Perbaiki dengan membuka siku sedikit ke luar, bukan dengan mengubah
bentuk cape. Cek dari tampak belakang dan tampak atas di enam fase.
```

Memperbaiki spring bone (rambut, rok, sayap):

```text
Rambut terasa terlalu kaku saat berhenti mendadak dari lari. Saya mau rambut berayun ke depan
sebentar lalu tenang. Ukur dulu getaran ruas rambut saat diam supaya perubahan ini tidak
menimbulkan getaran baru.
```

Bertanya lewat MCP (Blender harus terbuka):

```text
Lewat Blender MCP, sebutkan bone mana saja yang menggerakkan sayap dan tunjukkan hierarkinya.
Jangan ubah apa pun.
```

Meminta riset:

```text
Sebelum mengubah apa pun, riset dulu bagaimana animator membuat gerakan melompat yang terasa
berbobot (antisipasi, squash, landing). Rangkum poin-poinnya, lalu usulkan rencana untuk klip Jump.
```

### Kosakata yang membantu

Nama bone dan material di model ini berbahasa Jepang dan Mandarin. Tidak perlu hafal, tetapi menyebutnya membuat prompt lebih tepat.

| Bagian | Nama di rig |
|---|---|
| Pusat badan (naik-turun, geser) | `センター` |
| Panggul | `下半身` |
| Punggung bawah dan dada | `上半身`, `上半身2` |
| Leher dan kepala | `首`, `頭` |
| Bahu, lengan atas, siku, pergelangan | `肩`, `腕`, `ひじ`, `手首` (akhiran `.L` atau `.R`) |
| Target IK kaki | `足ＩＫ.L`, `足ＩＫ.R` |
| Sayap | `上翼親`, `下翼親` |
| Rok (spring bone) | `Q_baris_kolom` |
| Rambut (spring bone) | `髮_n`, `Bone_Hair...` |

| Bagian | Material |
|---|---|
| Kulit | `肌`, `肌2`, `颜` (wajah) |
| Rambut | `髮`, `前髪` |
| Mata | `目`, `瞳` |
| Gaun dan rok | `体`, `体2`, `裙`, `裙内` |
| Stoking | `袜`, `袜s`, `袜s2` |
| Sayap dan kristal | `翼`, `翼2`, `结晶` |

Istilah gerakan yang dipakai di skrip: *stance* (kaki menapak), *swing* (kaki mengayun), *heel strike* (tumit mendarat), *toe-off* (dorongan jari kaki), *foot roll* (telapak menggulung), *hip list* (pinggul miring), *lean* (condong), *phase* (posisi dalam siklus, 0 sampai 1).

### Yang AI tidak bisa lakukan di alur ini

- **Menilai gerakan saat diputar.** AI hanya melihat gambar diam dan angka.
- **Menguji keyboard dan mouse.** Browser headless tidak menerima input. Tombol E diuji lewat simulasi (`?auto&warm=900&standAt=600`).
- **Membaca halaman blender.org.** Situsnya memblokir akses otomatis. Kalau butuh dokumentasi dari sana, salin teksnya ke percakapan.
- **Menjamin tidak ada tembus dari semua sudut.** Pengecekan dilakukan dari beberapa sudut dan fase saja.

### Kebiasaan yang layak dipertahankan

- Minta AI melaporkan apa yang **belum** dicek, bukan hanya yang sudah.
- Kalau hasilnya memburuk, katakan terus terang dan lampirkan screenshot. Dua versi lari dibuang sebelum yang ketiga cocok.
- Setelah perubahan besar, minta AI memperbarui [[blender-mmd-workflow]] supaya sesi berikutnya bisa melanjutkan.
