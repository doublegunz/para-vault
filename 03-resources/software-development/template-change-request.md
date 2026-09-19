# Change Request: [Judul perubahan]

> Salin template ini ke folder proyek dan beri nama `cr-yyyy-nnn-ringkasan-perubahan.md`. Panduan: [[alur-change-request|Alur Change Request]]. Isi bertahap; gunakan `Belum diisi` untuk bagian yang masih menunggu dan `Tidak berlaku — [alasan]` untuk bagian yang tidak relevan. Ganti semua placeholder sebelum tahap terkait diselesaikan.

## 1. Identitas

| Informasi | Nilai |
| --- | --- |
| ID CR | CR-YYYY-NNN |
| Judul | [Ringkasan perubahan] |
| Proyek / aplikasi | [Nama proyek dan aplikasi] |
| Versi dokumen | 1 |
| Tanggal dibuat | YYYY-MM-DD |
| Terakhir diperbarui | YYYY-MM-DD |
| Status | Draft |
| Prioritas | [Rendah / Sedang / Tinggi / Kritis — pilih satu] |
| Alasan prioritas | [Dampak, urgensi, dan akibat jika ditunda] |
| Pemohon | [Nama / tim] |
| Penanggung jawab proyek / pemberi keputusan | [Nama] |
| Developer / tech lead | [Nama] |
| QA / reviewer | [Nama] |
| PIC rilis | [Nama] |
| Target penyelesaian yang diminta | [Tanggal dan alasan tenggat] |
| Referensi | [Tautan kebutuhan, issue, desain, atau CR terkait] |

Pilihan status: `Draft`, `Diajukan`, `Dalam Analisis`, `Disetujui`, `Dalam Implementasi`, `Dalam Pengujian`, `Siap Rilis`, `Dirilis`, `Ditutup`, `Ditolak`, `Ditunda`, `Dibatalkan`.

## 2. Latar belakang dan perubahan

### Kondisi saat ini

[Jelaskan perilaku saat ini, masalah, pengguna yang terdampak, dan bukti atau contoh kejadian.]

### Perubahan yang diminta

[Jelaskan perilaku yang diharapkan. Sertakan contoh sebelum dan sesudah bila membantu.]

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
