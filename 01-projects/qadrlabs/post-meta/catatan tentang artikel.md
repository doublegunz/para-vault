---
status: draft
created: 2026-06-07
---

# Catatan Meta Artikel

## Building a Safe Soft Delete Feature with Database Transactions in Laravel 13

- **Draft file:** [[safe-soft-delete-database-transactions-laravel-13]]
- **Status:** draft
- **Tanggal:** 2026-06-07

### Title

Building a Safe Soft Delete Feature with Database Transactions in Laravel 13

### Short Description (151 / 160)

Build a safe soft delete in Laravel 13 by cascading deletes to related records inside a database transaction, so a partial failure never corrupts data.

### Category

Laravel

### Tags

`laravel-13`, `eloquent`, `soft-delete`, `database-transactions`, `php`, `pest-testing`, `data-integrity`

### Tipe Artikel

Sequential coding tutorial (Step 1 sampai Step 8) dengan tiga reference section setelah testing.

### Catatan

- Cascade memakai manual cascade di dedicated `ProjectArchiver` service.
- Eloquent model events hanya disinggung di reference section sebagai topik artikel lanjutan.
- Sudah diuji coba di `sandbox/soft-delete-demo` dengan Laravel 13.14.0, PHP 8.5.4, Pest 4.7.2.
- Semua 7 tes lulus (18 assertions); output Tinker dan `php artisan test` di artikel diambil dari hasil run nyata.
- Catatan: package `laravel/pao` (agent-optimized output) perlu di-remove agar output Pest tampil normal, bukan JSON ringkas.
