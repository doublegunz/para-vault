---
title: Analisis sudo & Review Deployment — Lesson 17
tags: [review, laravel, deployment, security, qadrlabs]
date: 2026-06-14
source: "[[lesson-17-deploying-to-production]]"
---

# Analisis `sudo` & Review Deployment — Lesson 17

Review atas [[lesson-17-deploying-to-production]] (deploy Catatku ke VPS Ubuntu: Nginx, PHP-FPM 8.3, MariaDB, Supervisor, Certbot). Fokus utama: pertanyaan **"apakah perintah saat deploy sebaiknya pakai `sudo`?"**, plus audit deployment menyeluruh.

## 1. Jawaban inti — "apakah pakai `sudo` lebih baik?"

**Tidak biner. Tergantung kategori perintahnya.** Ada tiga kategori:

1. **Perintah sistem** — `apt update/install`, NodeSource, `mkdir`/`chown`/`chmod` di `/var/www`, edit `/etc/nginx/...`, `systemctl`, `supervisorctl`, `mysql_secure_installation`, `certbot`, `crontab`.
   → `sudo` **wajib dan sudah benar**. Semua menyentuh resource milik `root`; tanpa `sudo` akan gagal.

2. **Perintah aplikasi sebagai root (`sudo` polos)** — mis. `sudo git pull`, `sudo composer install`.
   → **Salah / berbahaya.** File baru jadi milik `root:root`, sedangkan PHP-FPM berjalan sebagai `www-data` dan tak bisa membacanya → error 500. Lesson **sudah benar** memperingatkan ini di *Section 8, Error 3*.

3. **Perintah aplikasi sebagai `sudo -u www-data`** — pilihan yang dipakai lesson untuk seluruh alur update.
   → Konsisten secara kepemilikan, **tapi punya dua kelemahan nyata** (lihat Temuan #1 dan #2).

Ringkasnya: jangan tanya "pakai `sudo` atau tidak", tapi "jalan **sebagai user apa**". Untuk perintah sistem → root via `sudo`. Untuk perintah aplikasi → **jangan root**; pilih deploy-user khusus (terbaik) atau `sudo -u www-data` dengan perbaikan di bawah.

## 2. Temuan (diurut berdasarkan severity)

### [Tinggi] Friksi HOME/cache pada `sudo -u www-data composer/npm`

Default sudoers Ubuntu (`env_reset`, tanpa `always_set_home` dan tanpa flag `-H`) **mempertahankan `HOME` milik user SSH pemanggil**, bukan home milik `www-data`. Akibatnya saat `deploy.sh` menjalankan:

```bash
sudo -u www-data composer install --no-dev --optimize-autoloader
sudo -u www-data npm ci
```

- Composer mencoba menulis cache ke `~/.composer` / `~/.config/composer` (= home user SSH) → *permission denied* atau warning "Cannot create cache directory ...".
- `npm ci` butuh `~/.npm` → masalah serupa.

**Perbaikan (minimal):** tambahkan flag `-H` agar `HOME=/var/www` (home `www-data`):

```bash
sudo -u www-data -H composer install --no-dev --optimize-autoloader
sudo -u www-data -H npm ci
```

**Atau** set eksplisit di awal `deploy.sh`:

```bash
export COMPOSER_HOME=/var/www/.composer
export npm_config_cache=/var/www/.npm
```

Catatan: masalah ini **tidak muncul pada deploy pertama** (Section 3) karena di sana perintah dijalankan sebagai `$USER`, bukan `www-data`. Inilah gejala dari inkonsistensi di Temuan #3.

### [Tinggi] Model keamanan — web user punya hak tulis ke kodenya sendiri

Menjalankan deploy *sebagai* `www-data` berarti user yang menghadap internet (`www-data` = user PHP-FPM/Nginx) memiliki **hak tulis ke seluruh tree aplikasi**. Jika ada celah PHP yang dieksploitasi, penyerang bisa **menulis ulang kode aplikasi**, bukan hanya merusak data di `storage/`.

Praktik standar industri (Laravel Forge / Envoyer) justru kebalikannya:

- Kode dimiliki **deploy user khusus non-privileged** (mis. `deploy`).
- `www-data` hanya boleh **membaca** kode, dan hanya boleh **menulis** ke `storage/` + `bootstrap/cache/`.
- PHP-FPM **tidak pernah** perlu hak tulis ke kode aplikasi.

Lihat Opsi B di Rekomendasi.

### [Sedang] Inkonsistensi model kepemilikan: deploy pertama vs update

- **Deploy pertama (Section 3):** `git clone`, `composer install`, `npm` dijalankan sebagai `$USER`; ownership baru di-`chown` ke `www-data` di akhir (Step 4).
- **Update (`deploy.sh`, Section 7):** semua dijalankan sebagai `www-data`.

Dua model berbeda untuk file yang sama membingungkan, dan **inilah akar friksi HOME** di Temuan #1. Rekomendasi: pilih **satu** model konsisten (idealnya model deploy-user di Opsi B), atau jelaskan eksplisit mengapa keduanya berbeda.

### [Sedang] `git pull` sebagai `www-data` — potensi "dubious ownership" & HOME

`www-data` berdefault shell `nologin` dengan home `/var/www`. `sudo -u www-data git pull` umumnya berjalan karena ownership konsisten, tapi bisa terganjal:

- **`safe.directory` / "detected dubious ownership"** bila ownership direktori tidak cocok dengan user yang menjalankan git.
- Gagal membaca git config global bila `HOME` tidak konsisten.

**Mitigasi:** jaga ownership tetap konsisten (`www-data` memiliki seluruh tree), atau bila perlu:

```bash
sudo -u www-data git config --global --add safe.directory /var/www/catatku
```

### [Rendah] `deploy.sh` dijalankan dengan `sudo`, lalu setiap baris `sudo -u www-data`

Script dipanggil `sudo /var/www/catatku/deploy.sh` (jalan sebagai root), lalu setiap perintah turun lagi ke `www-data` via `sudo -u www-data`. **Berfungsi**, tapi double-sudo dan sedikit boros. Alternatif lebih rapi: jalankan blok build sebagai deploy user, dan pakai `sudo` **hanya** untuk langkah yang benar-benar butuh privilege (mis. `supervisorctl`).

### [Rendah] `composer`/`npm` sebenarnya tak perlu jalan sebagai `www-data`

Pola yang lebih bersih: build sebagai deploy user (atau `$USER`), lalu cukup pastikan `storage/` dan `bootstrap/cache/` writable oleh `www-data`. Ini menghindari **seluruh kelas masalah HOME/cache** sekaligus.

### [Info] `composer` dari apt sering usang

Paket `composer` di repo Ubuntu kerap tertinggal versi. Pertimbangkan installer resmi Composer (`getcomposer.org`) agar versi up-to-date dan reprodusibel.

## 3. Rekomendasi (bertingkat)

### Opsi A — Perbaikan minimal (pertahankan gaya tutorial `sudo -u www-data`)

Cocok bila ingin lesson tetap sederhana untuk pemula:

1. Tambahkan `-H` pada semua `sudo -u www-data composer ...` dan `sudo -u www-data npm ...` **ATAU** set `COMPOSER_HOME` & `npm_config_cache` di awal `deploy.sh`.
2. Tambahkan catatan singkat soal `safe.directory` untuk `git pull` (jaga-jaga).
3. Samakan model deploy pertama dengan model update (atau jelaskan mengapa berbeda) agar tidak membingungkan.

### Opsi B — Best practice (model deploy-user; cocok untuk catatan/lesson lanjutan)

Lebih aman, sesuai standar Forge/Envoyer:

1. Buat user `deploy` non-privileged. Kode dimiliki `deploy:www-data`.
2. **Kode:** file `644`, direktori `755`, group `www-data` (read-only).
3. **Writable:** `storage/` dan `bootstrap/cache/` di-set `775` dengan setgid (`chmod g+s`) agar file baru mewarisi group `www-data` dan tetap bisa ditulis PHP-FPM.
4. Semua perintah deploy (`git`/`composer`/`npm`/`artisan`) dijalankan **sebagai `deploy`**, bukan `www-data`. PHP-FPM read-only terhadap kode.
5. `sudo` dipakai **hanya** untuk `supervisorctl`/`systemctl`/konfigurasi sistem.

### Tabel ringkas — "kapan pakai `sudo`?"

| Jenis perintah | Jalankan sebagai | Caranya |
|---|---|---|
| Provisioning & config sistem (apt, nginx, systemctl, supervisorctl, certbot, mariadb) | root | `sudo ...` |
| Operasi kode/aplikasi (git, composer, npm, artisan) | deploy-user **non-privileged** | langsung sebagai user itu (Opsi B) |
| — alternatif minimal bila tetap pakai www-data | www-data | `sudo -u www-data -H ...` (Opsi A) |
| Operasi kode sebagai **root** | ❌ jangan | `sudo git pull` → file `root:root` → 500 |

## 4. Apa yang sudah benar (jangan diubah)

- `sudo` untuk **seluruh** langkah provisioning & konfigurasi sistem — tepat.
- Peringatan *Error 3*: jangan `sudo` polos untuk `git pull` — benar dan penting.
- `migrate --force`, `optimize` / `optimize:clear`, `queue:restart`, serta urutan maintenance `down` → ... → `up` — alur deploy yang sehat.
- `chown www-data` + permission `755` (dir) / `644` (file) + `775` khusus `storage/` & `bootstrap/cache/`, **bukan** `chmod -R 777` — keputusan keamanan yang benar.
- `APP_DEBUG=false`, user MariaDB terbatas per-database `@'localhost'`, root dokumen Nginx menunjuk ke `public/` — semua sudah sesuai praktik baik.

---

**Kesimpulan:** Lesson sudah benar dalam membedakan perintah sistem (butuh `sudo`) vs perintah aplikasi (jangan jalankan sebagai root). Yang perlu diperbaiki adalah detail menjalankan perintah aplikasi sebagai `www-data`: tambahkan `-H`/`COMPOSER_HOME` (Opsi A), dan idealnya beralih ke model **deploy-user non-privileged** dengan PHP-FPM read-only pada kode (Opsi B) agar lebih aman.
