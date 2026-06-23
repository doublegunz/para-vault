# Laporan Uji Coba: Learn JavaScript Basics (Lesson 2-13)

Tanggal uji: 2026-06-23. Diuji di
`sandbox/learn-javascript-basics-test/learn-javascript` dengan Node.js dan
Google Chrome headless. Lesson 1 ("What Is JavaScript?") dan Lesson 14
("What's Next") tidak diuji karena berupa pengantar/review dan tidak berisi
langkah build aplikasi utama.

Status perbaikan (2026-06-23): temuan Lesson 13 sudah diperbaiki langsung di
materi. Render task sekarang memakai `createElement()` dan `textContent`, bukan
menyisipkan `task.text` ke `innerHTML`.

## Ringkasan

| Lesson | Materi | Status |
|--------|--------|--------|
| L2 | Console, inline script, external script | PASS |
| L3 | Variables, data types, operators, coercion | PASS |
| L4 | if/else, truthy/falsy, switch, ternary | PASS |
| L5 | Functions, arrow functions, scope, callbacks | PASS |
| L6 | for, while, for...of, break/continue | PASS |
| L7 | Arrays, array methods, spread, destructuring | PASS |
| L8 | Objects, methods, JSON, arrays of objects | PASS |
| L9 | DOM selection, text/HTML/style/class/attributes | PASS |
| L10 | Creating, modifying, and removing elements | PASS |
| L11 | Events, event object, delegation, preventDefault | PASS |
| L12 | Forms, realtime validation, submit handling | PASS |
| L13 | Interactive to-do list mini-project | PASS |

Semua file JavaScript utama yang terbentuk dari snippet course lolos syntax
check. Fitur inti Lesson 13 berjalan: tambah task via button dan Enter, toggle
complete, filter All/Active/Completed, delete, Clear Completed, active counter,
persistensi `localStorage`, dan input HTML user dirender sebagai teks.

## Lingkungan uji

| Komponen | Versi / Nilai |
|----------|---------------|
| Node.js | v25.9.0 |
| Browser | Google Chrome 149.0.7827.155 headless |
| Web server uji | Node.js HTTP server lokal |
| Lokasi project | `sandbox/learn-javascript-basics-test/learn-javascript` |
| OS/context | Linux workspace |

Course ditulis untuk VS Code + Chrome + Live Server. Uji ini dijalankan dengan
CLI setara: file dibuat di sandbox, script console-only dijalankan dengan
Node.js, dan halaman DOM/interaktif dijalankan di Chrome headless melalui Chrome
DevTools Protocol.

## Verifikasi teknis

### Syntax check

Semua file `.js` utama Lesson 2 sampai 13 berhasil melewati:

```bash
find sandbox/learn-javascript-basics-test/learn-javascript -name '*.js' -print0 | xargs -0 -n1 node --check
```

Hasil: tidak ada syntax error.

### Lesson 3-8: JavaScript dasar

Script utama Lesson 3-8 dijalankan dengan Node.js. Output console muncul sesuai
materi dan tidak ada runtime error.

| Lesson | Verifikasi | Hasil |
|--------|------------|-------|
| L3 | Variables, tipe data, operator, coercion | PASS |
| L4 | Branching, switch, ternary | PASS |
| L5 | Function declaration/expression, arrow, callback | PASS |
| L6 | Looping dan kontrol loop | PASS |
| L7 | Array basics, `map`, `filter`, `reduce`, spread | PASS |
| L8 | Object, method, JSON, array of objects | PASS |

### Lesson 2 dan 9-12: browser/DOM

Halaman dijalankan di Chrome headless. Setiap halaman diuji lewat DOM assertion
dan event sintetis.

| Lesson | Skenario | Hasil |
|--------|----------|-------|
| L2 | `index.html` mengubah `#output`; `external.html` memuat `script.js` dan mengubah `#demo` | PASS |
| L9 | DOM selection, `textContent`, `innerHTML`, style, class, dan attribute `target="_blank"` | PASS |
| L10 | Render 3 product card, tambah item baru, hapus card via tombol | PASS |
| L11 | Click counter, input event, keydown handler, event delegation pada `<li>` | PASS |
| L12 | Invalid form menampilkan error dan disable submit; valid form submit menampilkan pesan sukses | PASS |

### Lesson 13: mini-project to-do list

Skenario utama yang diuji:

| Skenario | Hasil |
|----------|-------|
| Tambah task dengan tombol Add | PASS |
| Tambah task dengan Enter | PASS |
| Toggle complete via checkbox | PASS |
| Filter Completed hanya menampilkan task completed | PASS |
| Filter Active hanya menampilkan task aktif | PASS |
| Active counter berubah menjadi `1 task remaining` | PASS |
| Clear Completed menghapus task completed | PASS |
| Data tersimpan di `localStorage` dan tetap muncul setelah reload | PASS |
| Input HTML seperti `<img src=x onerror="window.__xss=1">` tampil sebagai teks | PASS |

Data akhir setelah skenario utama: satu task aktif (`Review lesson`) tersimpan
di `localStorage` dan muncul kembali setelah reload.

## Temuan yang sudah diperbaiki di materi

### 1. Lesson 13 sebelumnya merender input task dengan `innerHTML`

Versi awal `app.js` membuat task dengan template literal:

```javascript
li.innerHTML = `
    <input type="checkbox" ${task.completed ? "checked" : ""}>
    <span class="task-text">${task.text}</span>
    <button class="delete-btn">&times;</button>
`;
```

Saat diuji dengan task text:

```text
<img src=x onerror="window.__xss=1">
```

DOM yang terbentuk berisi elemen `<img>` di dalam `.task-text`, bukan teks
literal. Ini adalah pola XSS yang sebaiknya tidak diajarkan di project final,
terutama karena Lesson 8/12 sudah mengenalkan data user dan form.

Perbaikan yang diterapkan: elemen task sekarang dibuat secara eksplisit dengan
`document.createElement()`, teks task diset memakai `span.textContent =
task.text`, dan event listener dipasang langsung ke variabel elemen. Retest
payload HTML menunjukkan tidak ada elemen HTML yang dibuat di dalam
`.task-text`.

## Catatan akurasi minor

- Lesson 12 sengaja memakai bitwise `&` pada `checkForm()` agar semua validator
  tetap berjalan dan semua error field muncul sekaligus. Secara runtime ini
  berjalan sesuai penjelasan materi.
- Lesson 10 bagian render products mengosongkan daftar item sebelumnya dengan
  `container.innerHTML = ""`, sehingga 3 item awal dari contoh pertama diganti
  oleh 3 product card. Ini konsisten dengan snippet kedua sebagai eksperimen
  render data array, bukan bug yang menghambat.
- Lesson 2 bagian console expression diverifikasi sebagai materi eksperimen
  console, bukan file aplikasi utama.

## Yang tidak diuji

- Lesson 1, karena berisi pengantar konsep dan roadmap.
- Lesson 14, karena berisi review dan langkah selanjutnya.
- Exercises dan Solutions, sesuai cakupan uji: hanya alur utama yang diuji
  kecuali bila alur utama bergantung pada exercise. Pada course ini tidak
  ditemukan ketergantungan seperti itu.
- Visual rendering manual di browser desktop. Tampilan dicek lewat DOM dan
  runtime browser headless, bukan inspeksi visual pixel-by-pixel.

## Kesimpulan

Course **layak dipublikasikan dari sisi teknis untuk Lesson 2-13**. Semua lesson utama
berhasil dibuat di sandbox, file JavaScript valid secara syntax, dan fitur DOM,
event, form, serta mini-project to-do list berjalan sesuai tujuan.

Temuan Lesson 13 sudah diperbaiki sehingga project final tidak lagi mengajarkan
pola menyisipkan input user ke `innerHTML`.


codex resume 019ef4df-c369-78a3-a418-324507fbbc6e
