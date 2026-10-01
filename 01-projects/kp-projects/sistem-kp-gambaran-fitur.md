---
title: Sistem KP — Gambaran Fitur per Role
date: 2026-09-30
tags:
  - kp-projects
  - dokumentasi
project_dir: /home/gun-gun-priatna/Projects/kp-project
local_url: https://kp-project.test
---

# Sistem KP — Gambaran Fitur per Role

Sistem KP adalah platform online untuk **Kerja Praktik, Magang, dan Penelitian** di Program Studi Teknik Informatika UMMI. Cakupannya dari pendaftaran dan bimbingan hingga sidang dan laporan akhir.

Catatan ini disusun **dari codebase**, tanpa login ke aplikasi. Sumbernya:
- `routes/web.php`
- `resources/views/welcome.blade.php`
- `resources/views/layouts/panel/sidebar.blade.php`
- `resources/views/layouts/civitas/sidebar.blade.php`
- `resources/views/panel/*`
- `AGENTS.md`, `DESIGN.md`, `about-id.md`

Terkait: [[2026-09-30-video-promosi-sistem-kp]] · [[cr-2026-001-support-pelaksanaan-kp-tim]]

---

## Stack singkat

- Laravel 13, PHP ^8.4, Blade, Vite 8, Tailwind CSS 4 (panel baru). Halaman lama Bootstrap/CoreUI masih ada selama masa migrasi.
- Spatie Permission (role), Yajra DataTables, Laravel Filemanager, Snappy/wkhtmltopdf (PDF).
- Pest 4 untuk testing.
- Admin memakai layout `layouts.panel`, sedangkan dosen dan mahasiswa memakai `layouts.civitas`.

## Login (SSO lewat portal Informatika)

Pengguna **tidak login langsung** di Sistem KP. Alurnya:

1. Login di portal Informatika (lokal: `https://informatika-project.test`), lalu pilih **E-KP** di bagian "Aplikasi Terintegrasi".
2. Portal mengarahkan ke Sistem KP dengan token bertanda tangan. Sistem KP memverifikasinya di route `authorization.gate` (`GateController`).
3. Kalau user belum ada, akun dibuat otomatis dengan role sesuai data dari portal (admin, dosen, atau peserta KP).
4. Admin diarahkan ke `/dashboard`, sedangkan dosen dan mahasiswa ke `/home`.

Tombol di landing page bertuliskan **"Login Portal"**.

## Role

Role didefinisikan di `App\Models\User`:
- `superadmin`, `admin`
- `lecturer`, `supervisor` (pembimbing), `examiner` (penguji)
- `student`, `kp_participant`, `trial_participant`

## Alur bisnis (4 tahap, versi landing page)

| # | Tahap | Peran |
|---|---|---|
| 01 | Registrasi & Verifikasi | Mahasiswa · Admin |
| 02 | Bimbingan & Logbook | Mahasiswa · Pembimbing |
| 03 | Pendaftaran & Pelaksanaan Sidang | Mahasiswa · Penguji |
| 04 | Revisi & Laporan Akhir | Mahasiswa · Pembimbing |

KP bisa dilaksanakan **Mandiri** atau **Kelompok**. Versi kelompok punya tim, undangan anggota, pendaftaran tim, dan sidang tim. Lihat [[cr-2026-001-support-pelaksanaan-kp-tim]].

---

## Fitur per role

### Mahasiswa (`layouts.civitas`)

Menu sidebar: Home · Kerja Praktik (Daftar KP, Progress Pendaftaran, Pembimbingan) · Sidang & Laporan (Daftar Sidang, Progress Pendaftaran, Jadwal Sidang, Hasil Sidang, Revisi & Laporan) · Dokumen · Informasi · Notifikasi

| Fitur | Route utama |
|---|---|
| Pendaftaran KP/Magang (mandiri), unggah dokumen, revisi pendaftaran | `registration.program.*` |
| Pendaftaran KP kelompok: buat tim, undang anggota, keluar tim | `registration.team.*` |
| Pembimbingan | `supervisory.index` |
| Logbook kegiatan (buat, edit, revisi, unduh lampiran) | `logbook.*` |
| Laporan kegiatan / activity report | `activity-report.*` |
| Permintaan perubahan judul KP | `/program-title-change-request/*` |
| Pendaftaran sidang (mandiri dan tim), unggah persyaratan | `registration.trial.*` |
| Jadwal dan hasil sidang | `trial.schedule.*`, `trial.result.*` |
| Revisi & laporan akhir (6 dokumen) | `final-report.*` |

Home mahasiswa berisi kartu **Pendaftaran KP** (empty state "Belum ada data pendaftaran." dengan tombol "Daftar Sekarang") dan **Pembimbingan KP**.

### Dosen: pembimbing & penguji (`layouts.civitas`)

Menu sidebar: Home · Kerja Praktik (Pembimbingan) · Sidang (Jadwal Sidang, Peserta Sidang)

| Fitur | Route utama |
|---|---|
| Memeriksa dan menyetujui logbook | `logbook.approvement` |
| Memeriksa dan menyetujui laporan kegiatan | `activity-report.approvement` |
| Penilaian pembimbingan | `supervisory.assessment.*` |
| Menguji sidang dan mengisi nilai (kriteria 60–100) | `trial.examination` |

Home dosen berisi stat **Mahasiswa Bimbingan**, **Logbook Belum Diperiksa**, **Total Pembimbingan**, serta daftar **Logbook yang Perlu Diperiksa** dan **Aktivitas Bimbingan Terakhir**.

### Admin (`layouts.panel`, prefix `administrator`)

Menu sidebar: Dashboard · Kerja Praktik (Pendaftaran, Daftar Peserta, Pembimbingan) · Sidang & Laporan (Pendaftaran, Peserta Sidang, Jadwal Sidang, Hasil Sidang, Revisi Laporan) · Laporan Kegiatan · Informasi · Dokumen · Notifikasi · Management (Master Data: Kategori, Data Dosen, Data Mahasiswa; Akses Pengguna: User, Role, Permission) · Developer Tools · Pengaturan Akun

| Fitur | Route utama |
|---|---|
| Buka/tutup periode pendaftaran KP dan sidang | `program.registration.*`, `trial.registration.*` |
| Verifikasi pendaftaran (mandiri dan tim), minta revisi | `manage.program-registration.*`, `manage.registration.team.*` |
| Penunjukan/penggantian pembimbing, unggah SK | `manage.supervisory.*`, `manage.program.*` |
| Verifikasi perubahan judul KP | `/manage/program-title-change-request/*` |
| Verifikasi pendaftaran sidang, atur dan publikasikan jadwal | `manage.trial-registration.*`, `manage.schedule.*` |
| Hasil sidang dan laporan akhir | `manage.trial.result.*`, `manage.final-report.*` |
| Informasi/pengumuman dan dokumen (publik/privat) | `manage.information`, `manage.file.*` |
| Master data dosen/mahasiswa, user, role, permission | `manage.lecturer.*`, `manage.student.*`, `user`, `role`, `permission` |
| Rekap laporan | `report.index` |

Dashboard admin: "Ringkasan KP & sidang periode berjalan." Isinya:
- Stat card: Pendaftaran KP, Pendaftaran Sidang, Jadwal Sidang, Revisi Laporan. Masing-masing diberi badge "Perlu tindakan" atau "Beres".
- Pendaftaran Terbaru dan Pendaftaran Sidang Terbaru.
- Periode Aktif.
- Tahapan Peserta KP.
- Tingkat Kelulusan Sidang.

---

## Design system (ringkas)

Acuan lengkapnya ada di `DESIGN.md`:
- **Font:** Inter. **Aksen:** biru (`blue-600`). **Netral:** Tailwind gray.
- **Status:** hijau = Beres, amber = Perlu tindakan, biru = proses, merah = ditolak.
- **Sudut:** kartu `rounded-2xl`, tombol `rounded-lg`, badge `rounded-full`.
- Mendukung dark mode. Semua copy UI dalam Bahasa Indonesia.
- Komponen ada di `resources/views/components/panel/` (`x-panel.*`).

## Akun demo lokal

Untuk eksplorasi lokal ada `database/seeders/DemoAccountSeeder.php`. Seeder ini membuat 3 akun dummy di `db_kp`: `admin.demo@demo.test`, `dosen.demo@demo.test`, dan `mahasiswa.demo@demo.test`, dengan `informatika_id` 990001–990003. Seeder ini **belum di-commit** dan tidak dipakai di video.

Seeder aman dijalankan berulang dan tidak menghapus data lain:
```bash
php artisan db:seed --class=DemoAccountSeeder --no-interaction
```

> [!warning]
> Jangan jalankan `php artisan db:seed` biasa di DB yang sudah terisi. `RoleSeeder` akan melakukan truncate pada users, roles, dan permissions.
