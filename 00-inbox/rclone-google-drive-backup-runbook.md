# Runbook Backup Database ke Google Drive dengan rclone

> **Pemilik sistem:** Gun Gun Priatna  
> **Server user:** `gungun`  
> **Remote rclone:** `gdrive`  
> **Zona waktu:** `Asia/Jakarta` (`WIB`, UTC+7)  
> **Jadwal backup:** setiap hari pukul `18:00 WIB`  
> **Retensi:** 8 hari untuk backup remote dan lokal  
> **Dokumentasi dibuat:** 11 Juli 2026  
> **Status terakhir:** backup, upload, cleanup remote, cleanup lokal, cron, logrotate, dan OAuth refresh token telah berhasil diverifikasi.

---

## Daftar Isi

1. [Tujuan dan ruang lingkup](#1-tujuan-dan-ruang-lingkup)
2. [Arsitektur sistem](#2-arsitektur-sistem)
3. [Struktur direktori dan file](#3-struktur-direktori-dan-file)
4. [Prasyarat](#4-prasyarat)
5. [Konfigurasi MariaDB](#5-konfigurasi-mariadb)
6. [Konfigurasi Google Cloud OAuth](#6-konfigurasi-google-cloud-oauth)
7. [Membuat remote Google Drive di rclone](#7-membuat-remote-google-drive-di-rclone)
8. [Authorization pada server headless tanpa SSH tunnel](#8-authorization-pada-server-headless-tanpa-ssh-tunnel)
9. [Memahami access token dan refresh token](#9-memahami-access-token-dan-refresh-token)
10. [Kasus khusus: refresh token tidak tersedia](#10-kasus-khusus-refresh-token-tidak-tersedia)
11. [Script backup produksi](#11-script-backup-produksi)
12. [Penjelasan alur script](#12-penjelasan-alur-script)
13. [Instalasi ulang script](#13-instalasi-ulang-script)
14. [Pengujian manual](#14-pengujian-manual)
15. [Konfigurasi cron](#15-konfigurasi-cron)
16. [Konfigurasi zona waktu](#16-konfigurasi-zona-waktu)
17. [Konfigurasi logrotate](#17-konfigurasi-logrotate)
18. [Retensi dan perilaku penghapusan](#18-retensi-dan-perilaku-penghapusan)
19. [Verifikasi rutin](#19-verifikasi-rutin)
20. [Restore database](#20-restore-database)
21. [Troubleshooting](#21-troubleshooting)
22. [Keamanan](#22-keamanan)
23. [Hardening opsional](#23-hardening-opsional)
24. [Checklist operasional](#24-checklist-operasional)
25. [Status konfigurasi yang telah diverifikasi](#25-status-konfigurasi-yang-telah-diverifikasi)
26. [Referensi resmi](#26-referensi-resmi)

---

## 1. Tujuan dan ruang lingkup

Sistem ini melakukan empat proses utama:

1. Membuat dump database MariaDB.
2. Mengompres dump menjadi file `.sql.gz`.
3. Mengunggah backup ke Google Drive menggunakan rclone.
4. Menghapus backup lokal dan remote yang lebih lama dari 8 hari.

Sistem juga mencakup:

- OAuth Google Drive dengan refresh token.
- OAuth app berstatus **In production** untuk mencegah grant mode Testing kedaluwarsa setiap 7 hari.
- Eksekusi otomatis dengan cron.
- Rotasi log menggunakan logrotate.
- Penanganan kegagalan dengan exit code dan nomor baris.
- Validasi file gzip sebelum upload.
- Permission file yang ketat.

---

## 2. Arsitektur sistem

```text
MariaDB
   │
   │ mariadb-dump
   ▼
File SQL terkompresi
/home/gungun/backup-system/data/YYYY-MM-DD/
qadrlabs_db_YYYY-MM-DD.sql.gz
   │
   │ rclone copy
   ▼
Google Drive
gdrive:BACKUP/YYYY-MM-DD/
qadrlabs_db_YYYY-MM-DD.sql.gz
```

Alur jadwal:

```text
Cron pukul 18:00 WIB
        │
        ▼
backup-db.sh
        │
        ├── Dump database
        ├── Validasi gzip
        ├── Upload Google Drive
        ├── Cleanup remote > 8 hari
        ├── Cleanup lokal > 8 hari
        └── Tulis status ke backup.log
```

Prinsip kegagalan:

- Script memakai `set -Eeuo pipefail`.
- Jika dump gagal, upload dan cleanup tidak dijalankan.
- Jika upload gagal, cleanup remote dan lokal tidak dijalankan.
- Pesan `BACKUP SUCCESS` hanya ditulis setelah seluruh proses berhasil.
- File sementara `.tmp` dihapus saat script berhenti.

---

## 3. Struktur direktori dan file

```text
/home/gungun/
├── .my.cnf
├── .config/
│   └── rclone/
│       └── rclone.conf
└── backup-system/
    ├── data/
    │   └── YYYY-MM-DD/
    │       └── qadrlabs_db_YYYY-MM-DD.sql.gz
    ├── logs/
    │   ├── backup.log
    │   └── backup.log-YYYY-MM-DD.gz
    └── scripts/
        └── backup-db.sh
```

Path penting:

| Fungsi | Path |
|---|---|
| Script backup | `/home/gungun/backup-system/scripts/backup-db.sh` |
| Data backup lokal | `/home/gungun/backup-system/data` |
| Log aktif | `/home/gungun/backup-system/logs/backup.log` |
| Konfigurasi rclone | `/home/gungun/.config/rclone/rclone.conf` |
| Kredensial MariaDB | `/home/gungun/.my.cnf` |
| Konfigurasi logrotate | `/etc/logrotate.d/qadr-backup` |
| Folder Google Drive | `gdrive:BACKUP` |

---

## 4. Prasyarat

Periksa command yang diperlukan:

```bash
command -v mariadb-dump
command -v gzip
command -v rclone
command -v find
command -v logrotate
command -v crontab
```

Instalasi paket apabila belum tersedia:

```bash
sudo apt update

sudo apt install -y \
    mariadb-client \
    gzip \
    findutils \
    cron \
    logrotate
```

Periksa versi rclone:

```bash
rclone version
```

Periksa lokasi konfigurasi:

```bash
rclone config file
```

Konfigurasi produksi ini memakai:

```text
/home/gungun/.config/rclone/rclone.conf
```

---

## 5. Konfigurasi MariaDB

File kredensial:

```text
/home/gungun/.my.cnf
```

Contoh isi:

```ini
[client]
user=USERNAME_DATABASE
password=PASSWORD_DATABASE
host=127.0.0.1
port=3306
```

Atur permission:

```bash
chown gungun:gungun /home/gungun/.my.cnf
chmod 600 /home/gungun/.my.cnf
```

Tes koneksi:

```bash
mariadb \
  --defaults-file=/home/gungun/.my.cnf \
  -e "SELECT VERSION();"
```

Tes dump tanpa menyimpan:

```bash
mariadb-dump \
  --defaults-file=/home/gungun/.my.cnf \
  --single-transaction \
  --skip-lock-tables \
  demo_app_qadrlabs \
  > /dev/null
```

### Mengapa memakai `--single-transaction`

Untuk tabel transactional seperti InnoDB, opsi ini membuat dump konsisten tanpa mengunci tabel selama proses berlangsung.

### Mengapa memakai `--skip-lock-tables`

Mengurangi kemungkinan kebutuhan privilege tambahan dan mencegah proses dump mencoba mengunci tabel.

---

## 6. Konfigurasi Google Cloud OAuth

### 6.1 Gunakan OAuth client sendiri

Penggunaan client ID sendiri direkomendasikan karena client ID bawaan rclone dipakai bersama oleh banyak pengguna.

Target konfigurasi:

```text
Google Drive API        : Enabled
User type               : External
Publishing status       : In production / Published
Verification status     : Unverified diperbolehkan untuk penggunaan pribadi
OAuth client type       : Desktop app
Remote rclone           : menggunakan client_id dan client_secret milik sendiri
```

### 6.2 Buat atau pilih project

Di Google Cloud Console:

```text
Project selector
→ New project
```

Contoh nama:

```text
Qadr Backup
```

### 6.3 Aktifkan Google Drive API

```text
APIs & Services
→ Library
→ Google Drive API
→ Enable
```

### 6.4 Konfigurasi Branding

```text
Google Auth Platform
→ Branding
```

Isi minimal:

```text
App name           : Qadr Backup
User support email : email Google pemilik
Developer contact  : email Google pemilik
```

Untuk aplikasi pribadi, logo, homepage, privacy policy, terms of service, dan authorized domain dapat dibiarkan kosong jika antarmuka Google mengizinkannya.

### 6.5 Konfigurasi Audience

```text
Google Auth Platform
→ Audience
```

Pilih:

```text
User type: External
```

Tambahkan akun sendiri sebagai test user bila diminta.

Setelah konfigurasi selesai, klik:

```text
Publish app
```

Status yang diharapkan:

```text
Publishing status: In production
```

Aplikasi boleh tetap:

```text
Verification status: Unverified
```

Untuk penggunaan pribadi dengan jumlah pengguna terbatas, aplikasi unverified tetap dapat dipakai. Pada saat authorization, Google dapat menampilkan layar peringatan. Pastikan hanya melanjutkan jika nama app dan project memang milik sendiri.

### 6.6 Mengapa harus In production

OAuth app External yang tetap berstatus `Testing` dapat menerima refresh token dengan masa berlaku 7 hari ketika meminta scope Google Drive.

Dampak mode Testing:

```text
Hari 1 : authorization berhasil
Hari 7 : refresh token dapat kedaluwarsa
Hari 8 : rclone gagal dengan invalid_grant
```

Mode Production menghilangkan batas khusus 7 hari tersebut. Refresh token masih dapat menjadi tidak valid karena pencabutan akses, tidak digunakan dalam waktu lama, batas jumlah token, perubahan kebijakan akun, atau kebijakan administrator Google Workspace.

### 6.7 Konfigurasi Data Access

Untuk operasi backup penuh, scope utama:

```text
https://www.googleapis.com/auth/drive
```

Dokumentasi rclone juga menyebut scope berikut pada pembuatan client:

```text
https://www.googleapis.com/auth/docs
https://www.googleapis.com/auth/drive
https://www.googleapis.com/auth/drive.metadata.readonly
```

Scope `drive` memungkinkan rclone membuat, membaca, memperbarui, dan menghapus file pada Google Drive.

### 6.8 Buat OAuth client

```text
Google Auth Platform
→ Clients
→ Create OAuth client
```

Pilih:

```text
Application type: Desktop app
```

Simpan:

- Client ID
- Client secret

Jangan menyimpan keduanya di dokumentasi publik atau repository Git.

---

## 7. Membuat remote Google Drive di rclone

Jalankan sebagai user `gungun`, bukan root:

```bash
rclone config \
  --config /home/gungun/.config/rclone/rclone.conf
```

Pilihan utama:

```text
n) New remote
name> gdrive
Storage> drive
client_id> CLIENT_ID_MILIK_SENDIRI
client_secret> CLIENT_SECRET_MILIK_SENDIRI
scope> 1
service_account_file>
Edit advanced config? n
```

Scope `1` adalah full access untuk file Google Drive, tidak termasuk Application Data Folder.

Untuk Google Drive pribadi:

```text
Configure this as a Shared Drive? n
```

Simpan remote:

```text
y) Yes this is OK
```

Periksa remote:

```bash
rclone listremotes \
  --config /home/gungun/.config/rclone/rclone.conf
```

Hasil yang diharapkan:

```text
gdrive:
```

Periksa apakah remote memakai custom client tanpa mencetak nilainya:

```bash
python3 - <<'PY'
import configparser

path = "/home/gungun/.config/rclone/rclone.conf"
config = configparser.RawConfigParser()
config.read(path)

client_id = config.get("gdrive", "client_id", fallback="").strip()
client_secret = config.get("gdrive", "client_secret", fallback="").strip()

print("Client ID    :", "CUSTOM" if client_id else "BAWAAN RCLONE")
print("Client secret:", "TERSEDIA" if client_secret else "TIDAK TERSEDIA")
PY
```

Target:

```text
Client ID    : CUSTOM
Client secret: TERSEDIA
```

---

## 8. Authorization pada server headless tanpa SSH tunnel

Kondisi sistem:

- VPS tidak memiliki browser.
- SSH port forwarding/tunnel diblok.
- Authorization dilakukan pada komputer lokal yang memiliki browser.
- Tidak perlu membuka port `53682` pada VPS.

### 8.1 Mulai reconnect di VPS

```bash
rclone config reconnect gdrive: \
  --config /home/gungun/.config/rclone/rclone.conf
```

Saat ditanya apakah token diganti, pilih `y`.

Saat ditanya:

```text
Use web browser to automatically authenticate rclone with remote?
```

Jawab:

```text
n
```

VPS akan menampilkan command seperti:

```bash
rclone authorize "drive" "BASE64_ENCODED_CONFIG"
```

Salin command itu **secara utuh**.

### 8.2 Jalankan authorize di komputer lokal

Komputer lokal harus memiliki rclone. Versi yang sama atau mendekati versi VPS direkomendasikan.

```bash
rclone version
```

Jalankan command persis yang diberikan VPS:

```bash
rclone authorize "drive" "BASE64_ENCODED_CONFIG"
```

Browser lokal akan membuka flow OAuth Google. Setelah selesai, terminal lokal akan menampilkan:

```text
Paste the following into your remote machine --->
TOKEN_HASIL_AUTHORIZATION
<---End paste
```

Salin token tersebut ke prompt `config_token>` di VPS.

### 8.3 Tentang port 53682

Alamat seperti:

```text
http://127.0.0.1:53682/auth?state=...
```

berjalan pada mesin yang menjalankan `rclone authorize`, yaitu komputer lokal.

Fakta penting:

- Port itu tidak perlu dibuka di firewall VPS.
- Port itu hanya listening sementara pada loopback komputer lokal.
- Jangan menempelkan parameter OAuth ke URL localhost tersebut.
- URL localhost bukan endpoint authorization Google.

---

## 9. Memahami access token dan refresh token

Token rclone untuk Google Drive biasanya berbentuk JSON dan disimpan pada field `token` di `rclone.conf`.

Komponen penting:

| Field | Fungsi |
|---|---|
| `access_token` | Dipakai untuk mengakses API Google Drive |
| `refresh_token` | Dipakai untuk meminta access token baru |
| `expiry` | Waktu kedaluwarsa access token |

Access token memang berumur pendek. Ini normal.

Alur otomatis:

```text
Access token aktif
      │
      ▼
Access token kedaluwarsa
      │
      ▼
rclone memakai refresh token
      │
      ▼
Google menerbitkan access token baru
      │
      ▼
Cron tetap berjalan tanpa login manual
```

Tanpa refresh token:

```text
Access token kedaluwarsa
      │
      ▼
rclone tidak dapat memperbarui token
      │
      ▼
backup gagal
```

### Memeriksa token tanpa menampilkan secret

```bash
python3 - <<'PY'
import configparser
import json
import sys

path = "/home/gungun/.config/rclone/rclone.conf"

config = configparser.RawConfigParser()
config.read(path)

try:
    token = json.loads(config["gdrive"]["token"])
except Exception as exc:
    print(f"✘ Gagal membaca token: {exc}")
    sys.exit(1)

for key, label in (
    ("access_token", "Access token"),
    ("refresh_token", "Refresh token"),
    ("expiry", "Expiry"),
):
    value = token.get(key)
    print(
        f"{'✔' if value else '✘'} "
        f"{label} {'tersedia' if value else 'tidak tersedia'}"
    )
PY
```

Hasil produksi yang benar:

```text
✔ Access token tersedia
✔ Refresh token tersedia
✔ Expiry tersedia
```

---

## 10. Kasus khusus: refresh token tidak tersedia

### 10.1 Gejala

Pemeriksaan token:

```text
✔ Access token tersedia
✘ Refresh token tidak tersedia
✔ Expiry tersedia
```

Akses sementara masih dapat berhasil:

```bash
rclone lsd gdrive:
```

Namun ketika access token kedaluwarsa, muncul:

```text
token expired and there's no refresh token
```

### 10.2 Penyebab

Google hanya mengembalikan access token pada flow authorization tersebut, tetapi tidak mengembalikan refresh token.

Kemungkinan penyebab:

1. Consent lama masih tersimpan untuk kombinasi akun dan OAuth client.
2. Flow tidak menghasilkan offline grant.
3. Consent tidak benar-benar diminta ulang.
4. Authorization dilakukan memakai OAuth client yang berbeda.
5. Command `rclone authorize` tidak memakai encoded config yang diberikan VPS.
6. OAuth client tidak dibuat sebagai `Desktop app`.
7. Token dibuat sebelum konfigurasi client atau consent screen diperbaiki.

### 10.3 Kesalahan URL yang pernah terjadi

Menambahkan parameter ini:

```text
&access_type=offline&prompt=consent
```

ke:

```text
http://127.0.0.1:53682/auth?state=...
```

tidak memperbaiki authorization.

Alasannya:

- URL `127.0.0.1` adalah endpoint lokal rclone.
- Itu bukan endpoint Google OAuth.
- Parameter OAuth harus diterima endpoint authorization Google, bukan callback lokal.

### 10.4 Prosedur pemulihan

1. Pastikan OAuth app memakai client sendiri dan bertipe `Desktop app`.
2. Pastikan status app sudah `In production`.
3. Cabut koneksi app lama pada Google Account:
   ```text
   Google Account
   → Security
   → Your connections to third-party apps and services
   → pilih app
   → Remove access
   ```
4. Jalankan kembali:
   ```bash
   rclone config reconnect gdrive: \
     --config /home/gungun/.config/rclone/rclone.conf
   ```
5. Pilih headless authorization.
6. Jalankan command `rclone authorize` lengkap pada komputer lokal.
7. Tempel token ke VPS.
8. Periksa keberadaan refresh token.

### 10.5 Workaround consent yang berhasil pada insiden ini

Pada insiden 11 Juli 2026, refresh token akhirnya berhasil diterbitkan setelah consent dipaksa pada **authorization endpoint Google**, bukan pada URL localhost.

rclone menyediakan opsi advanced `auth_url`, dengan environment variable:

```text
RCLONE_DRIVE_AUTH_URL
```

Jika flow normal tetap tidak mengembalikan refresh token, command authorize pada komputer lokal dapat dijalankan dengan authorization URL yang memaksa consent:

```bash
RCLONE_DRIVE_AUTH_URL='https://accounts.google.com/o/oauth2/auth?prompt=consent' \
rclone authorize "drive" "BASE64_ENCODED_CONFIG"
```

Catatan:

- Gunakan encoded config persis dari VPS.
- Jangan menambahkan `prompt=consent` ke URL `127.0.0.1`.
- Setelah berhasil, pastikan field `refresh_token` benar-benar tersedia.
- Workaround ini hanya diperlukan jika flow standar terus menghasilkan access token tanpa refresh token.

### 10.6 Hasil akhir yang sudah diverifikasi

```text
✔ Access token tersedia
✔ Refresh token tersedia
✔ Expiry tersedia
```

---

## 11. Script backup produksi

Lokasi:

```text
/home/gungun/backup-system/scripts/backup-db.sh
```

Isi:

```bash
#!/usr/bin/env bash

set -Eeuo pipefail
umask 077

# PATH eksplisit agar aman ketika dijalankan melalui cron
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# =========================
# CONFIG
# =========================

readonly HOME_DIR="/home/gungun"
readonly BACKUP_SYSTEM_DIR="$HOME_DIR/backup-system"
readonly DATA_ROOT="$BACKUP_SYSTEM_DIR/data"
readonly LOG_DIR="$BACKUP_SYSTEM_DIR/logs"

readonly DATABASE_NAME="demo_app_qadrlabs"
readonly MYSQL_CONFIG_FILE="$HOME_DIR/.my.cnf"

readonly RCLONE_CONFIG_FILE="$HOME_DIR/.config/rclone/rclone.conf"
readonly RCLONE_REMOTE_ROOT="gdrive:BACKUP"

# 8 hari dalam menit
readonly LOCAL_RETENTION_MINUTES=11520

DATE="$(date +%F)"

BASE_DIR="$DATA_ROOT/$DATE"
LOG_FILE="$LOG_DIR/backup.log"

BACKUP_FILE="$BASE_DIR/qadrlabs_db_${DATE}.sql.gz"
TEMP_BACKUP_FILE="${BACKUP_FILE}.tmp"

REMOTE_DATE="$RCLONE_REMOTE_ROOT/$DATE"

mkdir -p "$BASE_DIR" "$LOG_DIR"

exec >> "$LOG_FILE" 2>&1

# =========================
# ERROR HANDLING
# =========================

cleanup_temp_file() {
    rm -f "$TEMP_BACKUP_FILE"
}

handle_error() {
    local exit_code=$?
    local line_number="$1"

    echo "=============================="
    echo "[$(date)] BACKUP FAILED"
    echo "Exit code : $exit_code"
    echo "Line      : $line_number"
    echo "=============================="

    exit "$exit_code"
}

trap cleanup_temp_file EXIT
trap 'handle_error "$LINENO"' ERR

echo
echo "=============================="
echo "[$(date)] START BACKUP"
echo "=============================="

# =========================
# VALIDATION
# =========================

for command_name in mariadb-dump gzip rclone find; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "ERROR: Command tidak ditemukan: $command_name"
        exit 1
    fi
done

if [[ ! -r "$MYSQL_CONFIG_FILE" ]]; then
    echo "ERROR: File konfigurasi MariaDB tidak ditemukan atau tidak dapat dibaca:"
    echo "$MYSQL_CONFIG_FILE"
    exit 1
fi

if [[ ! -r "$RCLONE_CONFIG_FILE" ]]; then
    echo "ERROR: File konfigurasi rclone tidak ditemukan atau tidak dapat dibaca:"
    echo "$RCLONE_CONFIG_FILE"
    exit 1
fi

# =========================
# 1. DATABASE BACKUP
# =========================

echo "[1/4] Backup database..."

mariadb-dump \
    --defaults-file="$MYSQL_CONFIG_FILE" \
    --single-transaction \
    --skip-lock-tables \
    "$DATABASE_NAME" \
    | gzip > "$TEMP_BACKUP_FILE"

gzip -t "$TEMP_BACKUP_FILE"

mv "$TEMP_BACKUP_FILE" "$BACKUP_FILE"

echo "✔ DATABASE DONE"
echo "File : $BACKUP_FILE"
echo "Size : $(du -h "$BACKUP_FILE" | cut -f1)"

# =========================
# 2. UPLOAD TO GOOGLE DRIVE
# =========================

echo "[2/4] Upload ke Google Drive..."

rclone copy \
    "$BASE_DIR" \
    "$REMOTE_DATE" \
    --config "$RCLONE_CONFIG_FILE" \
    --verbose

echo "✔ UPLOAD DONE"

# =========================
# 3. CLEANUP GOOGLE DRIVE
# =========================

echo "[3/4] Cleanup backup database lama di Google Drive..."

rclone delete \
    "$RCLONE_REMOTE_ROOT" \
    --min-age 8d \
    --include "**/qadrlabs_db_*.sql.gz" \
    --config "$RCLONE_CONFIG_FILE" \
    --verbose

rclone rmdirs \
    "$RCLONE_REMOTE_ROOT" \
    --leave-root \
    --config "$RCLONE_CONFIG_FILE" \
    --verbose

echo "✔ GOOGLE DRIVE CLEANUP DONE"

# =========================
# 4. CLEANUP LOCAL BACKUPS
# =========================

echo "[4/4] Cleanup backup database lokal lebih dari 8 hari..."

find "$DATA_ROOT" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -name '20??-??-??' \
    -mmin +"$LOCAL_RETENTION_MINUTES" \
    ! -path "$BASE_DIR" \
    -print \
    -exec rm -rf -- {} +

echo "✔ LOCAL CLEANUP DONE"

# =========================
# SUCCESS
# =========================

echo "=============================="
echo "[$(date)] BACKUP SUCCESS"
echo "=============================="
```

Permission:

```bash
chown gungun:gungun /home/gungun/backup-system/scripts/backup-db.sh
chmod 700 /home/gungun/backup-system/scripts/backup-db.sh
```

---

## 12. Penjelasan alur script

### 12.1 Strict mode

```bash
set -Eeuo pipefail
```

- `-e`: berhenti jika command gagal.
- `-E`: trap `ERR` diwariskan ke function/subshell yang relevan.
- `-u`: variabel yang belum didefinisikan dianggap error.
- `pipefail`: pipeline dianggap gagal jika salah satu command gagal.

### 12.2 Permission default

```bash
umask 077
```

File baru hanya dapat dibaca dan ditulis oleh pemiliknya.

### 12.3 File sementara

Dump ditulis ke:

```text
qadrlabs_db_YYYY-MM-DD.sql.gz.tmp
```

Setelah lolos:

```bash
gzip -t
```

file dipindahkan menjadi nama final. Ini mencegah file backup rusak dianggap valid.

### 12.4 Upload

```bash
rclone copy "$BASE_DIR" "$REMOTE_DATE"
```

`copy` mengunggah file baru atau berubah tanpa menghapus file lain pada tujuan.

### 12.5 Cleanup remote

```bash
--min-age 8d
```

Hanya file lebih tua dari 8 hari yang cocok dengan filter berikut:

```text
**/qadrlabs_db_*.sql.gz
```

yang dihapus.

### 12.6 Cleanup folder remote kosong

```bash
rclone rmdirs "gdrive:BACKUP" --leave-root
```

Folder tanggal yang sudah kosong dihapus, tetapi folder root `BACKUP` dipertahankan.

### 12.7 Cleanup lokal

```bash
-mmin +11520
```

`11520` menit sama dengan:

```text
8 × 24 × 60
```

Filter nama:

```text
20??-??-??
```

mencegah `find` menghapus folder yang tidak mengikuti format tanggal.

---

## 13. Instalasi ulang script

Perintah berikut menghapus file lama dan membuat script dari awal.

> Sebelum menjalankan, pastikan isi script pada bagian sebelumnya masih sesuai dengan database dan path server.

```bash
cd /home/gungun/backup-system/scripts

rm -f backup-db.sh

nano backup-db.sh
```

Tempel isi script produksi, lalu simpan.

Atur permission:

```bash
chmod 700 /home/gungun/backup-system/scripts/backup-db.sh
```

Validasi sintaks:

```bash
bash -n /home/gungun/backup-system/scripts/backup-db.sh
```

Tidak ada output berarti sintaks valid.

Periksa:

```bash
ls -l /home/gungun/backup-system/scripts/backup-db.sh
```

Target:

```text
-rwx------ 1 gungun gungun ... backup-db.sh
```

---

## 14. Pengujian manual

### 14.1 Tes rclone

```bash
rclone lsd gdrive: \
  --config /home/gungun/.config/rclone/rclone.conf
```

Tes folder backup:

```bash
rclone lsf gdrive:BACKUP \
  --config /home/gungun/.config/rclone/rclone.conf
```

### 14.2 Jalankan backup

```bash
/home/gungun/backup-system/scripts/backup-db.sh
```

Output diarahkan ke log sehingga terminal dapat terlihat kosong.

### 14.3 Periksa log

```bash
tail -n 100 /home/gungun/backup-system/logs/backup.log
```

Target:

```text
[1/4] Backup database...
✔ DATABASE DONE
[2/4] Upload ke Google Drive...
✔ UPLOAD DONE
[3/4] Cleanup backup database lama di Google Drive...
✔ GOOGLE DRIVE CLEANUP DONE
[4/4] Cleanup backup database lokal lebih dari 8 hari...
✔ LOCAL CLEANUP DONE
==============================
[...] BACKUP SUCCESS
==============================
```

### 14.4 Verifikasi remote hari ini

```bash
rclone lsl "gdrive:BACKUP/$(date +%F)" \
  --config /home/gungun/.config/rclone/rclone.conf
```

### 14.5 Verifikasi lokal hari ini

```bash
ls -lh "/home/gungun/backup-system/data/$(date +%F)/"
```

### 14.6 Validasi gzip

```bash
gzip -t \
  "/home/gungun/backup-system/data/$(date +%F)/qadrlabs_db_$(date +%F).sql.gz"

echo $?
```

Exit code `0` berarti file gzip valid.

---

## 15. Konfigurasi cron

Edit crontab milik user `gungun`:

```bash
crontab -e
```

Isi:

```cron
0 18 * * * /home/gungun/backup-system/scripts/backup-db.sh
```

Makna:

```text
Menit       : 0
Jam         : 18
Tanggal     : setiap hari
Bulan       : setiap bulan
Hari pekan  : setiap hari
```

Periksa:

```bash
crontab -l
```

Karena script sudah mengarahkan output ke `backup.log`, redirect tambahan pada crontab tidak diperlukan.

### Catatan user cron

Gunakan:

```bash
crontab -e
```

sebagai user `gungun`.

Jangan memakai:

```bash
sudo crontab -e
```

karena itu mengatur cron milik root dan dapat menghasilkan HOME, permission, serta config path yang berbeda.

---

## 16. Konfigurasi zona waktu

Cron memakai zona waktu sistem.

Status produksi:

```text
Time zone: Asia/Jakarta (WIB, +0700)
```

Periksa:

```bash
timedatectl
```

Atur:

```bash
sudo timedatectl set-timezone Asia/Jakarta
```

Verifikasi:

```bash
date
timedatectl
```

Setelah perubahan, cron:

```cron
0 18 * * *
```

berjalan pukul `18:00 WIB`.

---

## 17. Konfigurasi logrotate

File konfigurasi:

```text
/etc/logrotate.d/qadr-backup
```

Isi:

```conf
/home/gungun/backup-system/logs/backup.log {
    daily
    rotate 30
    maxsize 10M

    compress
    missingok
    notifempty

    dateext
    dateformat -%Y-%m-%d

    create 0600 gungun gungun
    su gungun gungun
}
```

Makna:

| Opsi | Fungsi |
|---|---|
| `daily` | Periksa rotasi setiap hari |
| `rotate 30` | Simpan hingga 30 arsip |
| `maxsize 10M` | Rotasi jika ukuran melebihi 10 MB saat diperiksa |
| `compress` | Kompres arsip menjadi `.gz` |
| `missingok` | Tidak error jika file belum ada |
| `notifempty` | Jangan rotasi file kosong |
| `dateext` | Gunakan tanggal pada nama arsip |
| `create 0600` | Buat log baru dengan permission aman |
| `su gungun gungun` | Operasikan log sebagai user/group gungun |

Buat konfigurasi:

```bash
sudo tee /etc/logrotate.d/qadr-backup > /dev/null <<'EOF'
/home/gungun/backup-system/logs/backup.log {
    daily
    rotate 30
    maxsize 10M

    compress
    missingok
    notifempty

    dateext
    dateformat -%Y-%m-%d

    create 0600 gungun gungun
    su gungun gungun
}
EOF
```

Tes tanpa perubahan:

```bash
sudo logrotate --debug /etc/logrotate.d/qadr-backup
```

Paksa rotasi untuk pengujian:

```bash
sudo logrotate --force /etc/logrotate.d/qadr-backup
```

Periksa:

```bash
ls -lah /home/gungun/backup-system/logs/
```

Contoh:

```text
backup.log
backup.log-2026-07-11.gz
```

Periksa timer:

```bash
systemctl status logrotate.timer --no-pager
```

Status yang diharapkan:

```text
enabled
active (waiting)
```

Warning tentang journal ketika menjalankan `systemctl status` sebagai user biasa tidak menunjukkan kegagalan logrotate.

---

## 18. Retensi dan perilaku penghapusan

### 18.1 Retensi remote

```bash
--min-age 8d
```

File remote lebih lama dari 8 hari dihapus.

### 18.2 Retensi lokal

```bash
-mmin +11520
```

Direktori lokal dengan modification time lebih lama dari 8 hari dihapus.

### 18.3 Google Drive Trash

Secara default, Google Drive backend rclone memakai:

```text
drive-use-trash = true
```

Artinya `rclone delete` memindahkan file ke Trash, bukan langsung menghapus permanen.

Konsekuensi:

- File tidak tampil pada folder `BACKUP`.
- Kapasitas Google Drive belum tentu langsung kembali sampai Trash dikosongkan.

Untuk penghapusan permanen, opsi berikut dapat ditambahkan:

```bash
--drive-use-trash=false
```

Contoh:

```bash
rclone delete \
  "gdrive:BACKUP" \
  --min-age 8d \
  --include "**/qadrlabs_db_*.sql.gz" \
  --drive-use-trash=false \
  --config /home/gungun/.config/rclone/rclone.conf
```

Gunakan hanya jika penghapusan permanen memang diinginkan.

### 18.4 Dry run cleanup remote

Sebelum mengubah filter:

```bash
rclone delete \
  "gdrive:BACKUP" \
  --min-age 8d \
  --include "**/qadrlabs_db_*.sql.gz" \
  --config /home/gungun/.config/rclone/rclone.conf \
  --dry-run \
  --verbose
```

### 18.5 Preview cleanup lokal

```bash
find /home/gungun/backup-system/data \
  -mindepth 1 \
  -maxdepth 1 \
  -type d \
  -name '20??-??-??' \
  -mmin +11520 \
  -print
```

---

## 19. Verifikasi rutin

### Harian

```bash
tail -n 50 /home/gungun/backup-system/logs/backup.log
```

Cari:

```text
BACKUP SUCCESS
```

### Mingguan

```bash
rclone lsl gdrive:BACKUP \
  --config /home/gungun/.config/rclone/rclone.conf
```

Periksa backup lokal:

```bash
find /home/gungun/backup-system/data \
  -mindepth 1 \
  -maxdepth 1 \
  -type d \
  -printf '%f\n' \
  | sort
```

### Bulanan

- Periksa refresh token masih tersedia.
- Lakukan satu restore test.
- Periksa kapasitas lokal.
- Periksa kapasitas Google Drive dan Trash.
- Periksa status cron.
- Periksa status logrotate timer.
- Periksa update rclone.

Command:

```bash
du -sh /home/gungun/backup-system/data
du -sh /home/gungun/backup-system/logs
crontab -l
systemctl is-active cron
systemctl is-active logrotate.timer
rclone version
```

---

## 20. Restore database

Restore sebaiknya diuji secara berkala ke database sementara, bukan langsung ke database produksi.

### 20.1 Download backup remote

```bash
RESTORE_DATE="2026-07-11"
RESTORE_DIR="/home/gungun/backup-system/restore/$RESTORE_DATE"

mkdir -p "$RESTORE_DIR"

rclone copy \
  "gdrive:BACKUP/$RESTORE_DATE" \
  "$RESTORE_DIR" \
  --config /home/gungun/.config/rclone/rclone.conf \
  --verbose
```

### 20.2 Validasi gzip

```bash
gzip -t \
  "$RESTORE_DIR/qadrlabs_db_${RESTORE_DATE}.sql.gz"
```

### 20.3 Lihat header SQL tanpa mengekstrak ke disk

```bash
gzip -cd \
  "$RESTORE_DIR/qadrlabs_db_${RESTORE_DATE}.sql.gz" \
  | head -n 30
```

### 20.4 Buat database test

```bash
mariadb \
  --defaults-file=/home/gungun/.my.cnf \
  -e "CREATE DATABASE IF NOT EXISTS demo_app_qadrlabs_restore_test;"
```

### 20.5 Restore ke database test

```bash
gzip -cd \
  "$RESTORE_DIR/qadrlabs_db_${RESTORE_DATE}.sql.gz" \
  | mariadb \
      --defaults-file=/home/gungun/.my.cnf \
      demo_app_qadrlabs_restore_test
```

### 20.6 Verifikasi tabel

```bash
mariadb \
  --defaults-file=/home/gungun/.my.cnf \
  -e "SHOW TABLES FROM demo_app_qadrlabs_restore_test;"
```

### 20.7 Hapus database test

```bash
mariadb \
  --defaults-file=/home/gungun/.my.cnf \
  -e "DROP DATABASE demo_app_qadrlabs_restore_test;"
```

---

## 21. Troubleshooting

### 21.1 `RCLONE_CONFIG_FILE: unbound variable`

Gejala:

```text
line 61: RCLONE_CONFIG_FILE: unbound variable
```

Penyebab:

- Script memakai `set -u`.
- Variabel dipakai sebelum didefinisikan.

Perbaikan:

```bash
readonly RCLONE_CONFIG_FILE="/home/gungun/.config/rclone/rclone.conf"
```

Gunakan `--config` secara konsisten pada semua command rclone.

---

### 21.2 `invalid_grant: maybe token expired`

Gejala:

```text
couldn't fetch token: invalid_grant
```

Penyebab umum:

- OAuth app masih `Testing`.
- Grant 7 hari kedaluwarsa.
- Akses dicabut.
- Refresh token lama tidak valid.
- Terlalu banyak refresh token aktif.
- Kebijakan admin Google Workspace.

Pemeriksaan:

```bash
python3 - <<'PY'
import configparser
import json

path = "/home/gungun/.config/rclone/rclone.conf"
config = configparser.RawConfigParser()
config.read(path)
token = json.loads(config["gdrive"]["token"])

print("refresh token:", "ADA" if token.get("refresh_token") else "TIDAK ADA")
PY
```

Perbaikan utama:

1. Publish OAuth app ke Production.
2. Re-authorize.
3. Pastikan refresh token tersedia.

---

### 21.3 `token expired and there's no refresh token`

Gejala:

```text
token expired and there's no refresh token
```

Penyebab:

- Config memiliki access token dan expiry, tetapi tidak memiliki refresh token.

Perbaikan:

- Ikuti [Kasus khusus: refresh token tidak tersedia](#10-kasus-khusus-refresh-token-tidak-tersedia).

---

### 21.4 `rclone lsd` berhasil tetapi refresh token kosong

Ini bukan bukti konfigurasi aman untuk cron.

Maknanya:

- Access token saat ini masih aktif.
- Saat access token kedaluwarsa, proses akan gagal.

Indikator produksi yang benar adalah:

```text
✔ Refresh token tersedia
```

---

### 21.5 Upload berhasil tetapi cleanup tidak berjalan

Periksa log setelah baris upload.

Karena strict mode, cleanup hanya berjalan jika upload selesai dengan exit code `0`.

Jalankan:

```bash
tail -n 100 /home/gungun/backup-system/logs/backup.log
```

---

### 21.6 Log masih menampilkan error lama

`backup.log` bersifat append. Error lama tetap terlihat ketika memakai:

```bash
tail -n 100
```

Cari run terbaru berdasarkan timestamp.

Untuk memulai log baru:

```bash
cp /home/gungun/backup-system/logs/backup.log \
   "/home/gungun/backup-system/logs/backup.log.backup-$(date +%F-%H%M%S)"

: > /home/gungun/backup-system/logs/backup.log
```

Logrotate akan menangani rotasi berikutnya secara otomatis.

---

### 21.7 Cron tidak berjalan pukul 18:00 WIB

Periksa timezone:

```bash
timedatectl
```

Target:

```text
Time zone: Asia/Jakarta (WIB, +0700)
```

Periksa cron:

```bash
crontab -l
```

Periksa service:

```bash
systemctl status cron --no-pager
```

---

### 21.8 Permission denied pada `rclone.conf`

Atur:

```bash
chown gungun:gungun /home/gungun/.config/rclone/rclone.conf
chmod 600 /home/gungun/.config/rclone/rclone.conf
```

Jalankan script sebagai user `gungun`.

---

### 21.9 Folder remote kosong tidak terhapus

Gunakan:

```bash
rclone rmdirs \
  "gdrive:BACKUP" \
  --leave-root \
  --config /home/gungun/.config/rclone/rclone.conf \
  --verbose
```

---

### 21.10 Kapasitas Google Drive tidak berkurang

Kemungkinan file berada di Trash.

Periksa Google Drive Trash. Secara default rclone memindahkan file ke Trash.

---

### 21.11 Syntax error script

```bash
bash -n /home/gungun/backup-system/scripts/backup-db.sh
```

Tidak ada output berarti syntax valid.

---

### 21.12 Debug rclone

Gunakan `-vv` hanya saat diagnosis karena log dapat sangat detail:

```bash
rclone lsd gdrive: \
  --config /home/gungun/.config/rclone/rclone.conf \
  -vv
```

Jangan membagikan output debug mentah jika mengandung detail sensitif.

---

## 22. Keamanan

### 22.1 Permission minimum

```bash
chmod 600 /home/gungun/.my.cnf
chmod 600 /home/gungun/.config/rclone/rclone.conf
chmod 700 /home/gungun/backup-system/scripts/backup-db.sh
chmod 700 /home/gungun/backup-system/logs
```

### 22.2 Jangan tampilkan token

Jangan menjalankan:

```bash
cat /home/gungun/.config/rclone/rclone.conf
```

di tempat publik atau menyalin isinya ke issue, chat, screenshot, maupun repository.

### 22.3 Jangan commit file sensitif

Tambahkan ke `.gitignore` jika direktori dikelola Git:

```gitignore
.env
.my.cnf
rclone.conf
backup-system/data/
backup-system/logs/
```

### 22.4 Backup konfigurasi rclone

Sebelum perubahan:

```bash
cp /home/gungun/.config/rclone/rclone.conf \
   "/home/gungun/.config/rclone/rclone.conf.backup-$(date +%F-%H%M%S)"
```

Backup config juga sensitif karena mengandung token.

### 22.5 Batasi scope

Konfigurasi saat ini membutuhkan full Drive access karena sistem melakukan upload dan delete. Jangan memakai scope yang lebih luas dari kebutuhan.

### 22.6 Gunakan user non-root

Authorization, config, cron, dan script dijalankan sebagai user `gungun`.

---

## 23. Hardening opsional

Bagian ini belum wajib diterapkan pada baseline yang telah berhasil.

### 23.1 Cegah dua backup berjalan bersamaan

Tambahkan lock dengan `flock`.

Di crontab:

```cron
0 18 * * * /usr/bin/flock -n /home/gungun/backup-system/backup.lock /home/gungun/backup-system/scripts/backup-db.sh
```

### 23.2 Simpan checksum

Setelah backup:

```bash
sha256sum "$BACKUP_FILE" > "${BACKUP_FILE}.sha256"
```

Upload file checksum bersama backup.

### 23.3 Verifikasi remote setelah upload

```bash
rclone check \
  "$BASE_DIR" \
  "$REMOTE_DATE" \
  --config "$RCLONE_CONFIG_FILE" \
  --one-way
```

Ini menambah waktu proses tetapi meningkatkan validasi.

### 23.4 Notifikasi kegagalan

Trap error dapat dikembangkan untuk mengirim notifikasi Telegram, Slack, atau email.

### 23.5 Backup konfigurasi terenkripsi

Simpan salinan terenkripsi dari:

- `.my.cnf`
- `rclone.conf`
- `backup-db.sh`
- konfigurasi logrotate
- crontab

### 23.6 Uji restore otomatis

Backup belum dianggap sepenuhnya terbukti sampai berhasil direstore. Jadwalkan restore test berkala ke database sementara.

---

## 24. Checklist operasional

### Setelah perubahan OAuth

- [ ] Google Drive API aktif.
- [ ] OAuth client bertipe Desktop app.
- [ ] Remote memakai custom client ID.
- [ ] Audience External.
- [ ] Publishing status In production.
- [ ] Refresh token tersedia.
- [ ] `rclone lsd gdrive:` berhasil.
- [ ] Script backup berhasil penuh.

### Setelah perubahan script

- [ ] `bash -n backup-db.sh` tidak menghasilkan error.
- [ ] Permission script `0700`.
- [ ] Dump database berhasil.
- [ ] `gzip -t` berhasil.
- [ ] Upload berhasil.
- [ ] Cleanup remote hanya menghapus target.
- [ ] Cleanup lokal hanya menghapus folder tanggal lama.
- [ ] Log berakhir dengan `BACKUP SUCCESS`.

### Pemeriksaan bulanan

- [ ] Restore test berhasil.
- [ ] Refresh token tersedia.
- [ ] Cron masih terpasang.
- [ ] Zona waktu masih Asia/Jakarta.
- [ ] Logrotate timer aktif.
- [ ] Kapasitas lokal cukup.
- [ ] Google Drive Trash diperiksa.
- [ ] Tidak ada backup gagal yang terlewat.

---

## 25. Status konfigurasi yang telah diverifikasi

### OAuth

```text
Access token : tersedia
Refresh token: tersedia
Expiry       : tersedia
```

### Backup terbaru

```text
Tanggal      : 2026-07-11
Database     : demo_app_qadrlabs
Nama file    : qadrlabs_db_2026-07-11.sql.gz
Ukuran       : sekitar 3.7 MB
Upload       : berhasil
Remote       : gdrive:BACKUP/2026-07-11
```

### Cleanup

```text
Cleanup remote: berhasil
Cleanup lokal : berhasil
Folder lokal 2026-07-02 telah terhapus karena melewati retensi
```

### Cron

```cron
0 18 * * * /home/gungun/backup-system/scripts/backup-db.sh
```

### Timezone

```text
Asia/Jakarta
WIB
UTC+7
```

### Logrotate

```text
logrotate.timer: enabled dan active
backup.log     : permission 0600
retensi log    : 30 arsip
kompresi       : aktif
```

### Contoh log sukses

```text
[1/4] Backup database...
✔ DATABASE DONE
[2/4] Upload ke Google Drive...
✔ UPLOAD DONE
[3/4] Cleanup backup database lama di Google Drive...
✔ GOOGLE DRIVE CLEANUP DONE
[4/4] Cleanup backup database lokal lebih dari 8 hari...
✔ LOCAL CLEANUP DONE
==============================
BACKUP SUCCESS
==============================
```

---

## 26. Referensi resmi

1. [rclone — Google Drive backend](https://rclone.org/drive/)
2. [rclone — Remote setup untuk server headless](https://rclone.org/remote_setup/)
3. [rclone — `rclone authorize`](https://rclone.org/commands/rclone_authorize/)
4. [rclone — `rclone config reconnect`](https://rclone.org/commands/rclone_config_reconnect/)
5. [Google — Using OAuth 2.0 to Access Google APIs](https://developers.google.com/identity/protocols/oauth2)
6. [Google — OAuth app state overview](https://developers.google.com/identity/protocols/oauth2/production-readiness/overview)
7. Manual lokal:
   ```bash
   man rclone
   man logrotate
   man crontab
   man find
   ```

---

## Ringkasan perintah penting

### Periksa token

```bash
python3 - <<'PY'
import configparser
import json

path = "/home/gungun/.config/rclone/rclone.conf"
config = configparser.RawConfigParser()
config.read(path)
token = json.loads(config["gdrive"]["token"])

print("Access token :", "tersedia" if token.get("access_token") else "tidak tersedia")
print("Refresh token:", "tersedia" if token.get("refresh_token") else "tidak tersedia")
print("Expiry       :", "tersedia" if token.get("expiry") else "tidak tersedia")
PY
```

### Tes remote

```bash
rclone lsd gdrive: \
  --config /home/gungun/.config/rclone/rclone.conf
```

### Jalankan backup

```bash
/home/gungun/backup-system/scripts/backup-db.sh
```

### Lihat log

```bash
tail -n 100 /home/gungun/backup-system/logs/backup.log
```

### Verifikasi backup hari ini

```bash
rclone lsl "gdrive:BACKUP/$(date +%F)" \
  --config /home/gungun/.config/rclone/rclone.conf
```

### Periksa cron

```bash
crontab -l
```

### Periksa timezone

```bash
timedatectl
```

### Periksa logrotate

```bash
systemctl status logrotate.timer --no-pager
```
