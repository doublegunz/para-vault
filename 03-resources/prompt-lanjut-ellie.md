---
tags: [blender, mmd, 3d, claude-code, prompt, ellie]
---

# Prompt Melanjutkan Karakter Ellie

Prompt siap tempel untuk sesi Claude Code berikutnya. Isi catatan teknisnya ada di [[blender-mmd-workflow]] bagian 9, dan cara menulis prompt ada di [[blender-eksplorasi-dan-prompt-ai]].

Kondisi per 2026-11-20:
- **Sudah jadi:** rambut pink, mata ungu, kemeja + kerah Vesna, pita kotak-kotak, ikat pinggang, rantai emas dengan liontin sakura, rok lipit kotak-kotak + rumbai, kardigan (lengan kanan dicerminkan dari kiri), tangan polos, kaus kaki, dan sneaker.
- **Ditunda:** tas bahu. Skripnya ada, tapi masih tembus ke badan saat Idle.
- **Belum dibuat:** rambut lurus panjang, ahoge, telinga putih. Paha juga masih menampakkan pola renda samar dari stoking Vesna.

## Cara memakai

1. Buka terminal di vault: `cd ~/obsidian-vault && claude`.
2. Kalau mau memakai MCP, buka Blender dulu dan pastikan **Preferences > Add-ons > MCP** menunjukkan "Server is running". Kalau Blender tidak dibuka, hapus kalimat "Blender sudah terbuka dengan MCP aktif" dari prompt. Semua pekerjaan tetap bisa jalan lewat skrip headless.
3. Tempel **prompt pembuka**, lalu tambahkan **satu** tugas dari daftar di bawahnya. Satu tugas per putaran.

## Prompt pembuka

```text
Baca 03-resources/blender-mmd-workflow.md (terutama bagian 9 "Karakter Ellie") dan
03-resources/blender-eksplorasi-dan-prompt-ai.md. Saya mau melanjutkan karakter Ellie
(turunan Vesna) di ~/sandbox/blender-assets/vesna. Desain: ~/Pictures/ellie.png.
Jalankan game di ~/sandbox/vesna-game dengan npm run dev. Blender sudah terbuka dengan MCP aktif.

Aturan:
- Pakaian dan bagian baru harus menempel ke badan, bukan menggelembung.
- Cek dulu apakah bagian Vesna yang sudah ada bisa diwarnai ulang, dibentuk ulang, atau dipakai ulang
  (termasuk ornamen yang dihapus make_ellie.py) sebelum membuat geometri baru.
- Semua perubahan akhir ditulis ke skrip ellie_*.py / make_ellie.py, lalu jalankan ulang
  make_ellie.py -> export_glb.py -> verify_glb.py. Jangan menimpa vesna_*.blend.
- Jangan simpan file .blend dari Blender GUI kecuali saya minta.
- Sebelum melapor, cek di game: depan, belakang, samping, Walk, Run, dan SitType. Kirim
  screenshot-nya, dan sebutkan apa yang BELUM dicek.
- Setelah selesai, perbarui bagian 9 di blender-mmd-workflow.md.

Tugas:
```

## Pilihan tugas

Tempel salah satu blok ini di bawah baris `Tugas:`.

### Paha polos (sisa pola stoking)

```text
Paha masih menampakkan pola renda samar dari stoking Vesna (袜 diwarnai jadi kulit dengan keep=0.35
di make_ellie.py). Buat kulit kaki polos seperti di desain, tapi jangan mengubah kaus kaki dan
sneaker. Bandingkan screenshot paha sebelum dan sesudah dari depan dan samping.
```

### Rambut lurus panjang

```text
Di desain, rambut Ellie lurus, panjang sampai bawah lutut, dengan poni samping. Rambut Vesna sekarang
ikal dan diikat ponytail. Sebelum mengubah apa pun, jelaskan pilihan yang realistis (bentuk ulang
rambut Vesna, atau rambut baru di atas bone spring rambut yang ada) beserta risikonya terhadap spring
bone dan klip Run. Tunggu persetujuan saya sebelum mengerjakan.
```

### Ahoge

```text
Tambahkan ahoge (sejumput rambut berdiri di atas kepala) seperti di desain, warna sama dengan rambut.
Ikut kepala (bone 頭), boleh sedikit bergoyang dengan spring. Cek tidak tembus pita rambut putih.
```

### Telinga putih

```text
Di desain ada telinga putih panjang terkulai di sisi kepala, dan telinga lancip Vesna tidak ada.
Cek dulu apakah telinga lancip atau pita rambut Vesna bisa dibentuk ulang jadi telinga itu.
Tunjukkan render pratinjau dari depan dan samping sebelum dipasang di game.
```

### Mencoba tas lagi (ditunda)

```text
Tas bahu (ellie_bag.py, ELLIE_BAG=1) ditunda karena masih tembus ke badan saat Idle, dan cek
sebelumnya tidak mengukur tali terhadap badan, rambut, atau rok yang bergerak dengan spring.
Sebelum mengubah apa pun, ukur di mana persisnya tali dan tas menembus badan saat Idle (Blender dan
game), dan usulkan pendekatan yang lebih sederhana. Saya lampirkan screenshot masalahnya.
```

### Masalah yang terlihat di game

```text
[Lampirkan screenshot]
Di klip [Idle/Walk/Run/SitType], [bagian] terlihat [masalahnya] dari sudut [depan/samping/belakang].
Yang saya mau: [hasil yang diinginkan, kalau bisa dengan potongan desain].
Cari penyebabnya dulu dan jelaskan sebelum memperbaiki.
```

## Tips dari sesi sebelumnya

- **Lampirkan screenshot.** "Tasnya nempel ke telinga" dengan gambar langsung menunjukkan penyebabnya, sedangkan cek otomatis AI sempat melewatkannya.
- **Tunjukkan potongan desain** untuk detail kecil (manset lengan, rantai, tas). Potongan tangan dan manset dari `ellie.png` yang membuat masalah lengan kanan cepat ketemu.
- **Minta AI menyebutkan apa yang tidak ia cek.** Cek di Blender tidak memakai rambut dan rok yang bergerak dengan spring, jadi tembus karena spring hanya terlihat di game.
- **Kalau hasilnya tetap buruk setelah dua putaran, tunda saja**, seperti tas. Lebih baik lanjut ke bagian lain daripada menumpuk perbaikan.
