# Change Request: Pelaksanaan KP secara berkelompok

## 1. Identitas

| Informasi                                   | Nilai                             |
| ------------------------------------------- | --------------------------------- |
| ID CR                                       | CR-2026-001                       |
| Judul                                       | Pelaksanaan KP secara berkelompok |
| Proyek / aplikasi                           | Sistem KP Prodi TI UMMI           |
| Versi dokumen                               | 1                                 |
| Tanggal dibuat                              | 2026-09-19                        |
| Terakhir diperbarui                         | 2026-09-19                        |
| Status                                      | Draft                             |
| Prioritas                                   | Tinggi                            |
| Alasan prioritas                            | Perubahan Kebijakan               |
| Pemohon                                     | Prodi TI                          |
| Penanggung jawab proyek / pemberi keputusan |                                   |
| Developer / tech lead                       |                                   |
| QA / reviewer                               |                                   |
| PIC rilis                                   |                                   |
| Target penyelesaian yang diminta            |                                   |
| Referensi                                   |                                   |

## 2. Latar belakang dan perubahan

### Kondisi saat ini

Pendaftaran KP didesign hanya untuk dilakukan oleh perseorangan, namun saat ini kegiatan kp dilaksanakan secara berkelompok yang disebabkan adanya kebijakan baru di program studi teknik informatika UMMI. Sehingga terdapat beberapa kendala pada saat mengelola kegiatan. Terutama pada saat penjadwalan untuk kegiatan sidang kp, karena harus scroll dan menemukan anggota satu kelompok satu per satu, lalu dijadwalkan satu persatu dengan penguji yang sama, tempat yang sama dan waktu yang sama. sehingga melakukan dua kali pekerjaan yang sama.

Secara garis besar dari mulai pendaftaran sampai akhir itu masih dapat digunakan. Fitur pada project ini masih dapat digunakan dengan baik.

### Perubahan yang diminta
Perlu memperbaharui atau menambahkan dukungan untuk kegiatan pelaksanaan KP secara berkelompok dimulai dari
1. Modul pendaftaran: sebelum masuk ke halaman pendaftaran perlu ada opsi untuk kegiatan secara mandiri/perseorangan atau kelompok. dan apabila memilih kelompok perlu membuat kelompok atau tim terlebih dahulu. di titik ini ada kendala, karena spec server menggunakan shared hosting jadi ada beberapa kendala untuk integrasi secara real time dengan database teknik informatika (untuk pengingat data user yang diambil (data dosen, data mahasiswa) dibuat dengan cara mengambil data pada saat login lalu ditambahkan ke masing-masing table terkait.), sehingga perlu memastikan mahasiswa sudah terdaftar pada database kp. untuk itu kedua mahasiswa atau lebih perlu dipastikan sudah masuk ke sistem supaya terdaftar. Pada saat membuat kelompok atau tim, mahasiswa A dan mahasiswa B sudah login dan akses project. misal mahasiswa A membuat kelompok, mahasiswa A mencari nim mahasiswa B, mahasiswa A menambahkan mahasiswa B dalam kelompoknya, mahasiswa B menerima invite kelompok masuk ke kelompok yang dibuat mahasiswa A (status invitations berubah menjadi diterima). Mahasiswa A melakukan pendaftaran kp (isian form sama) dengan mengisi nim, nama, ipk, judul kegiatan, kategori kegiatan, tempat kegiatan, pimpinan tempat kp, alamat tempat kp (untuk form input field nim, nama, ipk dibuat berdasarkan jumlah mahasiswa dalam kelompok), ketika mahasiswa tekan tombol 'Daftar & Upload Dokumen' untuk submit pendaftaran, maka proses pendaftaran langsung sesuai dengan jumlah mahasiswa pada tim tersebut dan menambahkan relasi ke tim yang mendaftar. ketika sudah mendaftar, anggota tim tidak dapat ditambahkan ke anggota tim yang lainnya dalam periode pendaftaran yang sama. selanjutnya pada upload dokumen, form untuk upload dokumen disesuaikan dengan jumlah mahasiswanya.
2. Managemen Pendaftaran: Perlu ada halaman khusus yang menangani pendaftaran kp secara tim, termasuk untuk penugasan pembimbing. 

### Tujuan dan manfaat

[Jelaskan manfaat dan indikator keberhasilan yang dapat diamati.]

### Cakupan

- [Fitur, proses, atau komponen yang diubah]

### Di luar cakupan

- [Hal yang tidak dikerjakan melalui CR ini]

## 3. Acceptance criteria

Tuliskan hasil yang dapat diuji, termasuk batasan atau kondisi gagal yang relevan. Gunakan ID berikut untuk merujuk hasil pengujian.

| ID | Kondisi / tindakan | Hasil yang diharapkan |
| --- | --- | --- |
| AC-01 | [Kondisi awal dan tindakan pengguna / sistem] | [Hasil spesifik yang dapat diverifikasi] |
| AC-02 | [Kondisi lain atau input tidak valid] | [Respons yang diharapkan] |

## 4. Analisis dampak

Diisi developer atau tech lead sebelum persetujuan. Tuliskan `Tidak berlaku` beserta alasan jika tidak ada dampak pada suatu aspek.

| Aspek | Dampak dan tindakan yang diperlukan |
| --- | --- |
| Pengguna dan proses bisnis | [Kelompok pengguna, perubahan cara kerja, kebutuhan komunikasi] |
| UI / UX | [Halaman, alur, desain, aksesibilitas] |
| API / kontrak antarsistem | [Endpoint, payload, konsumen yang terdampak] |
| Data / database | [Skema, migrasi, data lama, backup dan pemulihan] |
| Integrasi / dependensi | [Layanan, paket, tim, atau pekerjaan terkait] |
| Keamanan / hak akses | [Perizinan, autentikasi, data sensitif yang terdampak] |
| Performa / kapasitas | [Waktu respons, beban, penyimpanan] |
| Kompatibilitas | [Versi lama, konsumen, atau klien yang harus tetap didukung] |
| Operasional / deployment | [Konfigurasi, downtime, observabilitas] |
| Biaya | [Tambahan biaya atau tidak ada dampak] |
| Jadwal dan pekerjaan lain | [Pergeseran milestone atau pekerjaan yang tertunda] |
| Dokumentasi | [Dokumen teknis atau panduan pengguna yang perlu diperbarui] |

**Kesimpulan kelayakan:** [Layak / perlu revisi / tidak layak, beserta alasan dan pendekatan yang disarankan]

## 5. Risiko dan dependensi

| Risiko | Kemungkinan dan dampak | Mitigasi | PIC |
| --- | --- | --- | --- |
| [Risiko] | [Rendah / sedang / tinggi, serta akibatnya] | [Tindakan pencegahan atau penanganan] | [Nama] |

| Dependensi / asumsi | Kondisi yang harus dipenuhi | PIC | Target |
| --- | --- | --- | --- |
| [Tim, layanan, akses, atau asumsi teknis] | [Kebutuhan dan cara konfirmasi] | [Nama] | [Tanggal] |

## 6. Estimasi dan rencana implementasi

| Pekerjaan | PIC | Estimasi usaha | Target / urutan | Referensi task / PR |
| --- | --- | --- | --- | --- |
| [Analisis, implementasi, review, pengujian, atau rilis] | [Nama] | [Jam kerja / hari-orang] | [Tanggal / urutan] | [Tautan] |

- **Total estimasi usaha:** [Nilai dan satuan; bedakan usaha dari durasi kalender]
- **Estimasi biaya tambahan:** [Nilai dan dasar estimasi / tidak berlaku beserta alasan]
- **Jadwal yang diusulkan:** [Mulai, selesai, dan target rilis]
- **Asumsi estimasi:** [Ketersediaan orang, dependensi, ketidakpastian]
- **Pendekatan implementasi:** [Ringkasan solusi dan urutan pekerjaan]

## 7. Keputusan dan persetujuan

Tambahkan baris untuk setiap keputusan; jangan menimpa persetujuan lama. Keputusan mengacu pada cakupan, acceptance criteria, estimasi, dan jadwal pada versi dokumen yang dicantumkan.

| Tanggal | Versi dokumen | Keputusan | Pemberi keputusan | Alasan / catatan | Bukti / tautan |
| --- | --- | --- | --- | --- | --- |
| [YYYY-MM-DD] | [Versi] | [Disetujui / Ditolak / Ditunda / Perlu revisi / Dibatalkan] | [Nama] | [Alasan dan tindak lanjut] | [Tautan atau catatan keputusan langsung] |

Jika ditunda: **PIC tindak lanjut** [Nama]; **tanggal atau kondisi peninjauan** [Isi].

- [ ] Analisis dampak, risiko, dan estimasi sudah ditinjau.
- [ ] Cakupan dan acceptance criteria sudah disepakati.
- [ ] Persetujuan untuk versi dokumen saat ini sudah tercatat sebelum implementasi.

Jika cakupan, acceptance criteria, biaya, atau jadwal yang disepakati berubah, naikkan versi dokumen dan kembalikan status ke `Dalam Analisis` untuk persetujuan ulang.

## 8. Pengujian dan validasi hasil

| ID uji / AC terkait | Skenario dan jenis uji | Hasil yang diharapkan | Hasil aktual / bukti | Status | Penguji / tanggal |
| --- | --- | --- | --- | --- | --- |
| [T-01 / AC-01] | [Langkah uji; fungsional, regresi, atau jenis lain] | [Hasil] | [Belum diuji / hasil dan tautan bukti] | [Belum diuji / Lulus / Gagal] | [Nama / tanggal] |

- **Lingkungan dan versi yang diuji:** [Staging / versi build / commit]
- **Cakupan regresi:** [Fungsi lama yang perlu dipastikan tetap bekerja]
- **Temuan dan tindak lanjut:** [Tautan temuan, PIC, hasil perbaikan dan uji ulang]
- **Validasi pemohon:** [Nama, tanggal, hasil penerimaan, dan bukti]

- [ ] Review kode selesai dan referensinya tersedia.
- [ ] Seluruh acceptance criteria terpenuhi dengan bukti pengujian.
- [ ] Pengujian regresi dan aspek terdampak selesai.
- [ ] Tidak ada temuan yang menghalangi rilis.
- [ ] Pemohon sudah memvalidasi hasil penggunaan.

Jika pengujian gagal, catat temuan dan kembalikan ke `Dalam Implementasi`, kemudian uji ulang.

## 9. Rencana rilis dan pemulihan

| Informasi | Rencana |
| --- | --- |
| Lingkungan tujuan | [Nama lingkungan] |
| Versi / commit rilis | [Versi / commit] |
| Jadwal dan zona waktu | [Tanggal, jam, zona waktu] |
| PIC rilis | [Nama] |
| Prasyarat | [Akses, konfigurasi, dependensi, backup jika relevan] |
| Downtime / dampak sementara | [Durasi dan pihak terdampak / tidak berlaku beserta alasan] |
| Komunikasi rilis | [Siapa yang diberi tahu, oleh siapa, kapan, dan melalui kanal apa] |
| Periode pemantauan | [Durasi atau waktu mulai–selesai] |
| Indikator keberhasilan | [Perilaku, metrik, log, serta ambang yang akan diperiksa] |
| PIC pemantauan | [Nama] |

### Langkah deployment dan verifikasi

1. [Langkah persiapan]
2. [Langkah deployment dan migrasi jika ada]
3. [Smoke test serta verifikasi versi, fungsi utama, dan kondisi data]

### Rollback atau pemulihan

- **Pemicu:** [Kondisi atau ambang yang mengharuskan rollback / pemulihan]
- **PIC keputusan dan pelaksana:** [Nama]
- **Versi atau kondisi tujuan pemulihan:** [Versi / kondisi yang diketahui berfungsi]
- **Penanganan data:** [Cara menangani migrasi dan data baru; potensi kehilangan data bila ada]
- **Langkah:** [Urutan rollback atau pemulihan; bila rollback langsung tidak memungkinkan, tuliskan alternatif pemulihan]
- **Verifikasi pemulihan:** [Cara memastikan layanan dan data kembali dalam kondisi yang dapat digunakan]
- **Komunikasi:** [Pihak yang dihubungi dan PIC komunikasi]

- [ ] Hasil uji dan validasi pemohon tersedia.
- [ ] Jadwal, PIC, prasyarat, dan komunikasi rilis siap.
- [ ] Langkah deployment serta rollback atau pemulihan sudah ditinjau.
- [ ] Indikator keberhasilan dan periode pemantauan sudah ditentukan.

## 10. Hasil rilis dan penutupan

- **Waktu rilis aktual:** [Tanggal, jam, zona waktu]
- **Hasil deployment dan verifikasi:** [Hasil serta bukti]
- **Versi yang aktif setelah tindakan terakhir:** [Versi / commit]
- **Hasil pemantauan:** [Periode aktual, hasil, dan bukti]
- **Insiden / rollback / pemulihan:** [Kejadian, tindakan, waktu, PIC, kondisi akhir; atau tidak ada]
- **Penerimaan hasil setelah rilis:** [Nama pemohon, tanggal, konfirmasi, dan bukti]
- **Dokumentasi yang diperbarui:** [Tautan]
- **Tindak lanjut:** [Task / CR lanjutan, PIC, dan target; atau tidak ada]
- **Tanggal penutupan dan pemberi keputusan:** [Tanggal / nama penanggung jawab proyek]

- [ ] Deployment dan verifikasi berhasil; versi aktif tercatat.
- [ ] Periode pemantauan selesai dan masalah penghalang penutupan terselesaikan.
- [ ] Hasil diterima pemohon dan dokumentasi diperbarui.
- [ ] Tindak lanjut tercatat dengan PIC dan target jika diperlukan.
- [ ] Penanggung jawab proyek menyetujui penutupan.

Jika rilis gagal, lakukan rollback atau pemulihan sesuai rencana, catat kondisi sistem, dan kembali ke `Dalam Implementasi` sebelum pengujian serta rilis ulang. Checklist penutupan hanya digunakan untuk CR yang berhasil diselesaikan; penolakan atau pembatalan dicatat pada bagian keputusan.

## 11. Riwayat perubahan dan status

| Tanggal | Versi dokumen | Status sebelum → sesudah | Perubahan / alasan | Oleh |
| --- | --- | --- | --- | --- |
| [YYYY-MM-DD] | 1 | — → Draft | Pengajuan awal dibuat | [Nama] |

#software-development #change-request
