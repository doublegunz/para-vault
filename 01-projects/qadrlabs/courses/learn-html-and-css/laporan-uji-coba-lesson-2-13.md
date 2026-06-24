# Laporan Uji Coba: Learn HTML and CSS (Lesson 2-13)

Tanggal uji: 2026-06-24. Diuji di
`sandbox/learn-html-and-css-test/learn-html-css` dengan HTML Tidy, local static
server, dan Google Chrome headless. Lesson 1 ("How the Web Works") dan Lesson 14
("What's Next") tidak diuji karena berupa pengantar/review dan tidak berisi
langkah build project utama.

## Ringkasan

| Lesson | Materi | Status |
|--------|--------|--------|
| L2 | First HTML page, comments, multi-page links | PASS |
| L3 | Text, headings, paragraphs, formatting | PASS |
| L4 | Links, images, ordered/unordered lists | PASS |
| L5 | Tables, colspan/rowspan, forms, labels, required fields | PASS |
| L6 | Semantic page structure | PASS |
| L7 | CSS methods, selectors, properties, external stylesheet | PASS |
| L8 | Box model, box sizing, display basics | PASS |
| L9 | Flexbox layout | PASS |
| L10 | CSS Grid layout | PASS |
| L11 | Typography, color variables, backgrounds, cards | PASS |
| L12 | Responsive design with media queries | PASS |
| L13 | LaunchPad landing page mini-project | PASS |

Semua file HTML utama Lesson 2 sampai 13 lolos validasi Tidy tanpa error.
Semua stylesheet lokal yang dirujuk HTML ditemukan. Browser headless berhasil
memuat halaman utama dan memverifikasi struktur, stylesheet, layout Flexbox/Grid,
form, semantic landmarks, dan responsivitas mobile/desktop.

## Lingkungan uji

| Komponen | Versi / Nilai |
|----------|---------------|
| Node.js | v25.9.0 |
| Browser | Google Chrome 149.0.7827.155 headless |
| HTML validator | HTML Tidy 5.8.0 |
| Web server uji | Node.js HTTP server lokal |
| Lokasi project | `sandbox/learn-html-and-css-test/learn-html-css` |
| Jumlah file uji | 32 file |
| OS/context | Linux workspace |

Course ditulis untuk VS Code + Chrome + Live Server. Uji ini dijalankan dengan
CLI setara: file dibuat di sandbox, HTML divalidasi dengan Tidy, lalu halaman
dimuat lewat local static server dan Chrome headless.

## Verifikasi teknis

### Validasi HTML dan asset lokal

Semua file `.html` utama yang dibuat dari snippet course diperiksa dengan:

```bash
tidy -q -e <file.html>
```

Hasil:

- 22 file HTML diperiksa.
- 0 error Tidy.
- 0 referensi stylesheet lokal yang hilang.

### Verifikasi browser headless

Halaman dijalankan melalui local static server dan diuji di Chrome headless.
Total 16 assertion browser lulus.

| Area | Skenario | Hasil |
|------|----------|-------|
| L2 | `index.html` memiliki viewport meta, heading, dan link ke `about.html` | PASS |
| L3 | Elemen formatting seperti `strong`, `em`, `mark`, dan `small` tampil | PASS |
| L4 | Ordered list dan unordered list dirender dengan item yang benar | PASS |
| L5 | Tabel memiliki struktur, `colspan`, dan `rowspan` | PASS |
| L5 | Form memiliki required fields dan semua `label[for]` terhubung ke input | PASS |
| L6 | `header`, `nav`, `main`, `article`, `aside`, dan `footer` tersedia | PASS |
| L7 | External CSS pada `.external` benar-benar diterapkan | PASS |
| L8 | Demo box model dan `box-sizing: border-box` berjalan | PASS |
| L9 | Container Flexbox dan cards memakai `display: flex` | PASS |
| L10 | Grid utama dan responsive gallery memakai `display: grid` | PASS |
| L11 | Hero background dan card layout dari stylesheet aktif | PASS |
| L12 | Mobile viewport memakai stacked navbar dan 1-column cards | PASS |
| L12 | Desktop viewport memakai horizontal navbar dan 3-column cards | PASS |
| L13 | Landing page memiliki features, pricing, contact, form, dan footer | PASS |
| L13 | Mobile viewport tidak overflow horizontal dan pricing jadi 1 kolom | PASS |
| L13 | Desktop viewport memakai 3-column pricing grid dan sticky navbar | PASS |

## Detail Lesson 13: LaunchPad landing page

Mini-project final berhasil dirender sebagai landing page multi-section:

- Navbar sticky dengan anchor ke Features, Pricing, dan Contact.
- Hero section dengan CTA buttons.
- Features grid berisi 6 feature cards.
- Pricing grid berisi 3 pricing cards, termasuk card populer.
- Contact form dengan label, input required, textarea, dan submit button.
- Footer multi-column.
- Layout mobile tidak menyebabkan horizontal overflow pada viewport 375px.
- Layout desktop menampilkan pricing sebagai 3 kolom pada viewport 1280px.

## Catatan akurasi minor

- Lesson 11 HTML merujuk `typography.css`; pada sandbox file CSS disimpan dengan
  nama tersebut agar sesuai materi. Tidak ada mismatch di alur course yang diuji.
- Lesson 11 dan Lesson 13 memakai Google Fonts. Uji ini tidak menjadikan koneksi
  eksternal sebagai syarat kelulusan; yang diverifikasi adalah struktur halaman,
  stylesheet lokal, dan computed layout.
- Beberapa contoh memakai image placeholder eksternal seperti `placehold.co`.
  Kegagalan mengambil gambar eksternal tidak memengaruhi validasi HTML/CSS lokal.

## Yang tidak diuji

- Lesson 1, karena berisi pengantar konsep web.
- Lesson 14, karena berisi review dan langkah selanjutnya.
- Semua exercise/solution tambahan. Cakupan uji difokuskan pada alur utama tiap
  lesson dan mini-project final.
- Inspeksi visual manual pixel-by-pixel. Tampilan diverifikasi melalui DOM,
  computed styles, dan responsivitas di Chrome headless.

## Kesimpulan

Course **layak dipublikasikan dari sisi teknis untuk Lesson 2-13**. Semua alur
utama berhasil dibuat di sandbox, HTML valid tanpa error, stylesheet lokal
termuat, dan project final LaunchPad berjalan responsif di mobile dan desktop.


codex resume 019ef815-ebe0-7961-ad6b-dcdc6e3d447b
