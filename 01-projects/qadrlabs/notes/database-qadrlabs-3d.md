# Database & Credentials QadrLabs 3D

Persiapan awal untuk project QadrLabs versi 3D. Format mengikuti [[membuat credentials untuk database mysql]].

> Password di bawah hanya placeholder. Ganti dengan password asli, simpan di `.env` (jangan di-commit, jangan ditulis di vault).

## Ringkasan

| Item | Nilai |
| --- | --- |
| Database | `db_qadrlabs_3d` |
| Username | `qadrlabs_3d_user` |
| Password | `password_yang_kuat` (placeholder) |
| Host | `localhost` |
| Charset | `utf8mb4` / `utf8mb4_unicode_ci` |

## 1. Masuk ke MySQL

```bash
mysql -u root -p
```

## 2. Buat database, user, dan hak akses

```sql
CREATE DATABASE db_qadrlabs_3d CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'qadrlabs_3d_user'@'localhost' IDENTIFIED BY 'password_yang_kuat';

GRANT SELECT, INSERT, UPDATE, DELETE ON db_qadrlabs_3d.* TO 'qadrlabs_3d_user'@'localhost';

GRANT CREATE, ALTER, DROP, INDEX ON db_qadrlabs_3d.* TO 'qadrlabs_3d_user'@'localhost';

GRANT REFERENCES ON db_qadrlabs_3d.* TO 'qadrlabs_3d_user'@'localhost';

FLUSH PRIVILEGES;
```

## 3. Verifikasi

```bash
mysql -u qadrlabs_3d_user -p db_qadrlabs_3d -e "SHOW GRANTS; SELECT DATABASE();"
```

## 4. Generate password yang kuat (opsional)

```bash
openssl rand -base64 24
```

Lalu ganti password user:

```sql
ALTER USER 'qadrlabs_3d_user'@'localhost' IDENTIFIED BY 'password_baru';
FLUSH PRIVILEGES;
```

## 5. Contoh `.env`

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_qadrlabs_3d
DB_USERNAME=qadrlabs_3d_user
DB_PASSWORD=isi_password_asli_di_sini
```

## Database testing (opsional)

```sql
CREATE DATABASE db_qadrlabs_3d_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'qadrlabs_3d_test_user'@'localhost' IDENTIFIED BY 'password_yang_kuat';

GRANT SELECT, INSERT, UPDATE, DELETE ON db_qadrlabs_3d_test.* TO 'qadrlabs_3d_test_user'@'localhost';

GRANT CREATE, ALTER, DROP, INDEX ON db_qadrlabs_3d_test.* TO 'qadrlabs_3d_test_user'@'localhost';

GRANT REFERENCES ON db_qadrlabs_3d_test.* TO 'qadrlabs_3d_test_user'@'localhost';

FLUSH PRIVILEGES;
```

## Rollback (hapus semuanya)

```sql
DROP DATABASE IF EXISTS db_qadrlabs_3d;
DROP USER IF EXISTS 'qadrlabs_3d_user'@'localhost';
```
