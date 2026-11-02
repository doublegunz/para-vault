# Membuat Database dan Credential untuk Catatku Symfony

Catatan ini dipakai untuk uji coba course `learn-symfony-for-beginners` di `sandbox/catatku-symfony`. Credential di bawah hanya untuk sandbox lokal.

- Database: `db_catatku`
- User: `catatku_symfony`
- Password: `catatku_secret`

## 1. Buat User dan Hak Akses

Jalankan sebagai user root MySQL (password root akan diminta). User diberi hak penuh atas `db_catatku` (termasuk `CREATE`), supaya perintah `php bin/console doctrine:database:create` di Lesson 5 bisa membuat database sendiri. Database-nya sengaja **tidak** dibuat di sini.

```bash
mysql -u root -p -e "CREATE USER IF NOT EXISTS 'catatku_symfony'@'localhost' IDENTIFIED BY 'catatku_secret'; GRANT ALL PRIVILEGES ON db_catatku.* TO 'catatku_symfony'@'localhost'; FLUSH PRIVILEGES;"
```

## 2. Cek Hasilnya

```bash
mysql -u catatku_symfony -pcatatku_secret -e "SHOW GRANTS;"
```

Harus muncul baris ``GRANT ALL PRIVILEGES ON `db_catatku`.* TO `catatku_symfony`@`localhost` ``.

## 3. DATABASE_URL di Sandbox

Isi `.env.local` di `sandbox/catatku-symfony` (bukan `.env`, supaya `.env` tetap sama dengan isi lesson):

```env
DATABASE_URL="mysql://catatku_symfony:catatku_secret@127.0.0.1:3306/db_catatku?serverVersion=11.8.6-MariaDB&charset=utf8mb4"
```

## 4. Bersihkan Setelah Uji Coba (Opsional)

```bash
mysql -u root -p -e "DROP DATABASE IF EXISTS db_catatku; DROP USER IF EXISTS 'catatku_symfony'@'localhost';"
```
