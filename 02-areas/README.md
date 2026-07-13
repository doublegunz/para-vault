# Areas

Tempat untuk tanggung jawab yang berkelanjutan (tidak punya deadline), termasuk **catatan harian / jurnal**.

## Catatan Harian (Daily Notes)

### Lokasi & penamaan
- Simpan di `02-areas/jurnal/`
- Satu file per hari, nama file = tanggal ISO: `YYYY-MM-DD.md` (contoh: `2026-07-13.md`)
- Format tanggal ISO memastikan file otomatis tersusun urut secara kronologis di file explorer

### Template entri harian
Gunakan struktur konsisten supaya mudah di-scan dan di-review nanti:

```markdown
---
tags: [jurnal]
---

## Fokus hari ini
-

## Catatan / kejadian
-

## Ide & insight
-

## Terhubung ke
-
```

Isi bagian **Terhubung ke** dengan wikilink `[[Nama Project]]` atau `[[Nama Area]]` setiap kali entri harian menyinggung pekerjaan yang sedang berjalan. Ini membuat backlink otomatis muncul di halaman project/area terkait, jadi jurnal bukan hanya arsip pasif tapi ikut memperkaya konteks project.

### Alur kerja harian
1. **Tulis bebas** — tidak perlu rapi, tujuannya menangkap apa yang terjadi/dipikirkan hari itu
2. **Link saat menulis** — begitu menyebut project/area/resource tertentu, langsung buat wikilink-nya, jangan ditunda
3. **Tag isu penting** — tambahkan `#tindak-lanjut` atau `#ide` pada baris yang perlu diproses lebih lanjut

### Alur review (memaksimalkan jurnal, bukan cuma menumpuk)
- **Mingguan**: baca ulang 7 entri terakhir, pindahkan tugas konkret yang masih relevan ke `01-projects/`, dan insight yang cukup matang jadi catatan reference di `03-resources/`
- **Bulanan**: buat satu MOC (Map of Content) ringkas, misal `02-areas/jurnal/2026-07.md`, berisi link ke entri-entri bulan itu dan ringkasan pola/tema yang muncul
- **Arsip**: jurnal tidak perlu dipindah ke `04-archives/` — biarkan tetap di `02-areas/jurnal/` sebagai catatan historis, karena aktivitas menjurnal itu sendiri adalah area yang terus berjalan

### Kenapa di Areas, bukan Inbox atau Projects
Menulis jurnal adalah kebiasaan tanpa tanggal selesai (ongoing), bukan tugas dengan deadline — itu sebabnya masuk `02-areas/`, bukan `01-projects/`. Berbeda dari `00-inbox/` yang isinya catatan mentah menunggu diproses, entri jurnal sudah punya "rumah" tetap begitu ditulis.
