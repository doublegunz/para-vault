# Laporan Uji Coba Course "Learn Python for Beginners" (Lesson 1-14)

**Tanggal uji:** 2026-07-06
**Penguji:** Codex
**Hasil keseluruhan:** ✅ Seluruh snippet Python runnable berhasil dijalankan di sandbox, termasuk file handling, CSV, error handling, Pandas, dan Matplotlib. Temuan awal pada Lesson 11 dan house style sudah ditindaklanjuti.
**Status perbaikan:** ✅ Temuan Lesson 11, Top Month solution Lesson 13, dan pelanggaran em dash/en dash sudah ditindaklanjuti pada 2026-07-06. Validasi ulang menghasilkan `failures=0` dan scan dash terlarang bersih.

## Cakupan & metode

Course diuji di `sandbox/learn-python-validation` (gitignored). Uji dilakukan dengan menjalankan snippet Python dari lesson secara bertahap di folder kerja `sandbox/learn-python-validation/python-basics`, membuat file pendukung seperti `data/sales.csv`, `helpers.py`, `summary.csv`, dan chart PNG sesuai alur course.

Lesson 1 dan Lesson 14 bersifat konseptual, jadi tidak memiliki command coding utama untuk divalidasi. Blok yang memang sengaja salah di section "Fix the Errors", prompt REPL `>>>`, dan contoh interaktif `input()` dilewati dari automated run.

## Environment

| Komponen | Versi / Nilai |
|----------|---------------|
| Python | 3.14.3 |
| Virtualenv | `sandbox/learn-python-validation/.venv` |
| Pandas | 3.0.3 |
| Matplotlib | 3.11.0 |
| Matplotlib backend | `Agg` |
| Lokasi project uji | `sandbox/learn-python-validation/python-basics` |
| Course source | `01-projects/qadrlabs/courses/learn-python-for-beginners` |

Dependency `pandas` dan `matplotlib` dipasang ke virtualenv lokal sandbox, bukan ke Python global.

## Verifikasi per lesson

| Lesson | Yang diuji | Hasil |
|--------|-----------|-------|
| 1 | Course orientation, manfaat Python, arah belajar | ✅ Konseptual, tidak perlu command validation |
| 2 | `python --version`, interpreter examples, `hello.py`, exercise solutions | ✅ Snippet runnable lulus |
| 3 | Variables, strings, arithmetic, conversion, booleans, exercise solutions | ✅ Snippet runnable lulus |
| 4 | `if`/`elif`/`else`, comparison, logical operators, nested conditionals | ✅ Snippet runnable lulus |
| 5 | `for`, `range`, `while`, `break`, `continue`, nested loops, loop aggregation | ✅ Snippet runnable lulus |
| 6 | Lists, list methods, sorting, comprehensions, tuples, unpacking | ✅ Snippet runnable lulus |
| 7 | Dictionaries, nested dictionaries, looping dictionary data, sets | ✅ Snippet runnable lulus |
| 8 | Functions, parameters, return values, defaults, scope, reusable validators | ✅ Snippet runnable lulus |
| 9 | Standard library imports, custom `helpers.py`, JSON write/read, pip concept | ✅ Snippet runnable lulus setelah `helpers.py` dibuat sesuai instruksi lesson |
| 10 | String cleaning, splitting, joining, searching, replacing, f-string formatting | ✅ Snippet runnable lulus |
| 11 | Text files, `csv.DictReader`, revenue aggregation, `csv.DictWriter` | ✅ Kode berjalan, expected output revenue sudah dikoreksi |
| 12 | `try`/`except`, missing file handling, malformed CSV rows, `finally`, logging | ✅ Snippet runnable lulus |
| 13 | Pure Python sales analyzer, Pandas analyzer, Matplotlib chart export | ✅ Kode berjalan dan `data/revenue_chart.png` dibuat |
| 14 | Roadmap setelah course | ✅ Konseptual, tidak perlu command validation |

## Detail uji otomatis

Command utama:

```bash
sandbox/learn-python-validation/.venv/bin/python sandbox/learn-python-validation/validate_course.py
```

Output akhir:

```text
python=3.14.3
workdir=sandbox/learn-python-validation/python-basics
runnable_python_blocks=116
skipped_expected_or_interactive_blocks=35
failures=0
summary.csv rows=4 header=category,revenue,units_sold
revenue_chart.png bytes=40633
```

## Temuan penting

1. **Expected output Lesson 11 tidak cocok dengan `data/sales.csv` saat uji awal.** Dari 10 baris data yang diberikan, total revenue aktual adalah `Rp 25,255,000`, bukan `Rp 26,255,000`. Status: sudah dikoreksi di lesson.

2. **Revenue per category Lesson 11 juga salah saat uji awal.** Perhitungan aktual dari CSV:

```text
Electronics: Rp 22,350,000
Fashion:     Rp  1,340,000
Food:        Rp  1,310,000
Books:       Rp    255,000
```

Status: expected output di lesson sudah diperbarui mengikuti urutan revenue descending.

3. **Contoh `summary` Lesson 11 hardcoded tidak konsisten dengan data saat uji awal.** Nilai `revenue` untuk Electronics tertulis `19050000`, padahal hasil dari CSV adalah `22350000`. Kolom `transactions` juga membingungkan: beberapa nilainya tampak seperti jumlah quantity, bukan jumlah transaksi/baris. Status: contoh summary sudah diperbarui memakai `units_sold`.

4. **Pandas dan Matplotlib flow Lesson 13 valid.** Setelah dependency terpasang, kode Pandas membaca `data/sales.csv`, menghitung revenue, membuat grouped category revenue, dan Matplotlib berhasil menyimpan `data/revenue_chart.png`.

## Catatan akurasi minor

- Lesson 13 exercise solution untuk "Top Month" awalnya hanya memberikan potongan yang harus ditambahkan ke `analyze()` dan `display_report()`. Status: solution sudah diperjelas agar key `top_month` dan `top_month_revenue` dimasukkan ke dictionary return.
- `tentang-course.md` dan beberapa lesson awalnya memakai em dash atau en dash. Status: semua karakter tersebut sudah dibersihkan dari folder course.
- Lesson 12 dan Lesson 13 awalnya memakai em dash di string output warning. Status: output warning sudah diganti menjadi format colon.
- Folder dan file generated saat uji berada di `sandbox/`, sehingga tidak menjadi source material yang perlu dipublish.

## Yang tidak diuji

- Instalasi Python, VS Code, dan extension secara GUI tidak diuji. Validasi dilakukan di Linux dengan Python sistem dan virtualenv.
- `pip install pandas matplotlib` diuji di virtualenv lokal, bukan di Windows, macOS, atau Laragon.
- `plt.show()` tidak diuji sebagai jendela GUI. Matplotlib dijalankan memakai backend `Agg` agar chart bisa dibuat di environment headless.

## Kesimpulan

Course secara teknis dapat diikuti dari Lesson 1 sampai 14. Kode utama, latihan runnable, file handling, CSV processing, module import, error handling, Pandas, dan Matplotlib berhasil berjalan di Python 3.14.3.

Lesson 11, Top Month solution Lesson 13, dan karakter em dash/en dash sudah diperbaiki. Course ini layak dipublikasikan dari sisi teknis berdasarkan validasi ulang.
