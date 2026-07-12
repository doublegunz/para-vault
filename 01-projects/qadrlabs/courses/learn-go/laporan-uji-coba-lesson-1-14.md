# Laporan Uji Coba Course "Learn Go" (Lesson 1-14)

**Tanggal uji:** 2026-07-12  
**Penguji:** Codex  
**Hasil keseluruhan:** ✅ Seluruh badan utama Lesson 1-14 berhasil divalidasi. Semua snippet program inti dapat dikompilasi dan dijalankan, project package/file I/O/concurrency berfungsi, dan mini project TaskMan menyelesaikan seluruh skenario course.

## Cakupan dan Metode

Project pengujian dibuat di `sandbox/learn-go-courses`, sebuah repository Git terpisah yang diabaikan oleh repository vault. Setiap lesson memiliki direktori dan module sendiri. Source dibuat mengikuti badan utama lesson; bagian Exercises, Solutions, dan snippet yang sengaja salah pada "Fix the Errors" tidak diuji.

Snippet inti Lesson 2-10 dijalankan satu per satu dengan input deterministik untuk program interaktif. Lesson 11-14 diuji melalui struktur project finalnya. Pemeriksaan tambahan memakai `gofmt`, `go test`, dan `go vet`. Untuk lesson yang berisi beberapa program `package main` mandiri, `go run` dan `go vet` dijalankan per file karena semua file tersebut memang tidak dimaksudkan dibangun menjadi satu binary.

Setiap lesson direkam dalam commit Git berurutan pada branch `master`. Repository berisi 14 commit lesson dan satu commit tindak lanjut untuk memformat source Lesson 2, total 15 commit. Working tree bersih pada akhir pengujian.

## Environment

| Komponen | Versi / Nilai |
|----------|---------------|
| Go | go1.26.0 linux/amd64 |
| OS | Linux amd64 |
| Lokasi project | `sandbox/learn-go-courses` |
| Branch Git | `master` |
| Go module | Satu module per direktori lesson |
| Dependency Lesson 11 | `github.com/fatih/color` v1.19.0 |
| Go build cache | `/tmp/learn-go-cache` |

Go sudah terpasang, sehingga langkah download dan instalasi Go/VS Code pada Lesson 2 tidak diulang. Pengujian memakai toolchain sistem yang lebih baru daripada contoh course.

## Verifikasi per Lesson

| Lesson | Yang diuji | Hasil |
|--------|------------|-------|
| 1 | Materi konseptual dan struktur workspace course | ✅ Dicatat melalui `README.md` dan commit awal |
| 2 | Module pertama, `go run`, `go build -o hello`, dan binary | ✅ Output salam, nama, umur, dan tiga karakteristik Go sesuai course |
| 3 | Variabel, tipe, konversi, formatting, dan receipt | ✅ Total Rp18.870.000 termasuk pajak 11% |
| 4 | Input, operator, `if`, dan `switch` | ✅ Input `3` dan `25` menghasilkan `Wednesday` dan `Warm` |
| 5 | Array, slice, loop, dan score analyzer | ✅ 10 nilai, rata-rata 76.3, min 55, max 92, lulus 7/10 |
| 6 | Map, frequency counter, dan map of slices | ✅ 7 siswa dikelompokkan ke empat kota |
| 7 | Function, multiple return values, closure, sort, dan filter | ✅ Perhitungan, counter, sorting, dan filter berjalan |
| 8 | Error values dan custom error type | ✅ Kasus valid dan validation error menghasilkan output yang benar |
| 9 | Struct, method, embedding, dan collection | ✅ Empat program mandiri berjalan dan `go vet` lulus |
| 10 | Interface, `Stringer`, type switch, dan `any` | ✅ Seluruh empat snippet inti berjalan; tiga file project utama disimpan |
| 11 | Package lokal, exported/unexported identifiers, multi-file package, `init()`, dan `go get` | ✅ Tiga package terkompilasi; dependency dan checksum tercatat |
| 12 | Text file, JSON encode/decode, dan penyimpanan persisten | ✅ `output.txt` dan `tasks.json` dibuat; run kedua memuat data lama |
| 13 | Goroutine, channel, range, `select`, dan timeout | ✅ Concurrent run lebih cepat; channel dan timeout berfungsi |
| 14 | Build dan skenario lengkap CLI TaskMan | ✅ Add, list, done, delete, help, dan persistence berhasil |

## Detail Pengujian Fungsional

### Lesson 11: Packages dan Modules

Program memanggil package `mathutil` dan `greeting`. Fungsi `init()` berjalan sebelum `main`, operasi matematika menghasilkan nilai yang benar, dan greeting/farewell tampil. `go test ./...` dan `go vet ./...` lulus untuk root module beserta kedua package lokal. `go get github.com/fatih/color` menghasilkan `go.mod` dan `go.sum` dengan dependency langsung dan transitif.

### Lesson 12: File dan JSON Persistence

`files.go` membuat, membaca, memindai per baris, dan menambahkan isi ke `output.txt`. `json_demo.go` berhasil melakukan marshal compact/pretty dan unmarshal satu contact serta list contact. `storage.go` membuat tiga task, menyimpan JSON, memuatnya kembali pada run kedua, dan mempertahankan status selesai.

### Lesson 13: Concurrency

Run sequential memerlukan sekitar 1.00 detik, sedangkan run concurrent sekitar 0.50 detik. Channel mengirim hasil dari goroutine, tiga simulasi fetch selesai dalam sekitar 0.85 detik, range menghasilkan `1 4 9 16 25`, dan cabang timeout pada `select` terpicu sesuai desain.

Urutan baris dari goroutine dapat berubah antar-run. Pengujian memeriksa kelengkapan hasil, bukan urutan yang tidak dijamin scheduler.

### Lesson 14: TaskMan

Binary `taskman` berhasil dibangun. Empat task ditambahkan, task 1 dan 2 ditandai selesai, task 3 dihapus, lalu data dimuat ulang dari `tasks.json`. Status akhir adalah tiga task, dua selesai dan satu pending.

## Temuan Penting

1. **Snippet `init()` Lesson 11 harus ditambahkan, bukan menggantikan seluruh file.** Snippet pada section tersebut hanya menampilkan `Hello` dan tidak menyertakan `Farewell`, sedangkan `main.go` masih memanggil `greeting.Farewell`. Instruksi teks sudah mengatakan "Add the following to the top", sehingga implementasi yang benar adalah mempertahankan `Farewell` sambil menambahkan `init()`. Course sebaiknya menegaskan hal ini atau menampilkan file lengkap agar pembaca tidak mengganti isi file secara tidak sengaja.

2. **Beberapa lesson sengaja memiliki beberapa program `main` mandiri.** Lesson 9, 10, 12, dan 13 meminta beberapa file yang masing-masing mendefinisikan `func main()`. Perintah `go test ./...` pada direktori tersebut akan melihat redeklarasi jika semua file dikompilasi sekaligus. Cara yang sesuai course adalah `go run <nama-file>.go` dan `go vet <nama-file>.go` per demonstrasi.

3. **Gunakan cache yang writable pada environment terbatas.** Cache default mengarah ke `/home/gun-gun-priatna/.cache/go-build`, yang read-only pada sesi pengujian. Menetapkan `GOCACHE=/tmp/learn-go-cache` menyelesaikan masalah. Ini kendala environment penguji, bukan masalah source course.

4. **Versi dependency berbeda dari contoh.** Course menampilkan `github.com/fatih/color v1.16.0`; `go get` pada 2026-07-12 mengambil v1.19.0. API yang dibahas tetap kompatibel. Contoh versi sebaiknya diperlakukan sebagai ilustrasi, bukan nilai yang harus identik.

## Yang Tidak Diuji

- Instalasi Go, VS Code, Go extension, dan tool editor pada Lesson 2 karena environment sudah siap.
- Exercises dan Solutions pada setiap lesson.
- Snippet "Fix the Errors" yang memang dimaksudkan sebagai contoh salah/benar.
- Warna terminal dari `fatih/color`; dependency diunduh dan dicatat sesuai badan lesson, tetapi contoh import ringkas tidak menggantikan aplikasi package utama.

## Ringkasan Git

Riwayat dimulai dari `test lesson 01: why go` dan berlanjut satu commit untuk setiap lesson sampai `test lesson 14: cli task manager`. Commit terakhir `format lesson 02 source` mencatat hasil `gofmt` pada contoh awal pengguna. Total riwayat adalah 15 commit dan tidak ada perubahan yang belum dicatat.

## Kesimpulan

Course **layak dipublikasikan dari sisi teknis**. Seluruh konsep dan project utama Lesson 1-14 dapat diikuti menggunakan Go 1.26.0. File yang diminta course berhasil dibuat, semua program inti berjalan, package dan dependency dapat diselesaikan, persistence bekerja, concurrency menunjukkan perilaku yang diharapkan, dan CLI TaskMan berfungsi penuh. Temuan Lesson 11 tentang cara menambahkan `init()` sebaiknya diperjelas agar pembaca tidak menghapus fungsi yang masih digunakan.
