# Instruksi Uji Coba Manual File-Based

Gunakan instruksi ini saat menguji ulang course `learn-python-for-beginners`.

## Prinsip Utama

Uji course seperti pembaca nyata. Semua kode yang diajarkan sebagai file harus benar-benar ditulis sebagai file di `sandbox/`, diedit bertahap sesuai instruksi lesson, lalu dijalankan langsung dari terminal.

Jangan mengganti file-based workflow dengan `python -c`, kecuali lesson memang secara eksplisit mengajarkan one-liner atau interpreter prompt.

## Folder Kerja

Gunakan folder berikut sebagai workspace uji:

```text
sandbox/learn-python-for-beginners-manual/python-basics
```

Semua file praktik, dependency lokal, data contoh, output CSV, chart PNG, dan artefak hasil uji disimpan di dalam folder tersebut.

## Cara Menguji Setiap Lesson

Untuk setiap lesson:

1. Baca instruksi lesson dari awal sampai akhir.
2. Buat file yang diminta lesson secara nyata di folder sandbox.
3. Jika lesson berkata "add the following to `variables.py`", edit file sandbox yang sama, jangan membuat snippet sementara.
4. Jalankan file dengan command yang sama seperti instruksi course, misalnya:

```bash
python variables.py
```

5. Jika lesson meminta folder atau file data, buat file tersebut secara nyata. Contoh:

```text
data/sales.csv
data/summary.csv
data/revenue_chart.png
```

6. Jika lesson meminta edit lanjutan pada file yang sama, lakukan edit langsung pada file sandbox tersebut.
7. Catat command yang dijalankan, output penting, error yang muncul, dan koreksi yang dilakukan.
8. Jangan mengubah output terminal hasil uji nyata saat menuliskannya ke report.

## Aturan Khusus

- Gunakan `python -c` hanya untuk verifikasi tambahan kecil, bukan sebagai pengganti file yang diminta lesson.
- Gunakan virtualenv lokal di dalam `sandbox/` jika perlu memasang package seperti Pandas dan Matplotlib.
- Jika perlu mengunduh dependency atau package, konfirmasi dulu sebelum download.
- Exercises boleh dilewati, kecuali solution-nya menjadi dependency lesson berikutnya atau ada risiko akurasi yang perlu dibuktikan.
- File generated di `sandbox/` tidak perlu dipindahkan ke source course kecuali diminta.

## Report yang Diharapkan

Setelah uji selesai, update atau buat report di folder course.

Report harus mencakup:

- Tanggal uji
- Environment dan versi tool
- Lokasi project sandbox
- Verifikasi per lesson
- Command penting yang dijalankan
- Output penting
- File yang berhasil dibuat
- Error dan koreksi yang dilakukan
- Temuan akurasi teknis
- Hal yang tidak diuji
- Kesimpulan publish-ready atau belum

## Kalimat Instruksi Singkat

Jika ingin memberi instruksi ringkas ke agent, gunakan:

```text
Uji course ini seperti pembaca nyata. Untuk setiap lesson, buat file di sandbox sesuai instruksi course, misalnya `variables.py`, `loops.py`, `helpers.py`, dan file data yang diminta. Jalankan file tersebut langsung dari terminal. Jika lesson meminta edit file yang sama, edit file sandbox itu, jangan hanya menjalankan snippet dengan `python -c`. Catat command, output, error, dan perbaikan yang dilakukan ke report.
```
