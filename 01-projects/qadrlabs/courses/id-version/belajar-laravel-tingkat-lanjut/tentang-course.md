---
title: "Belajar Laravel Tingkat Lanjut"
slug: "belajar-laravel-tingkat-lanjut"
original_title: "Learn Laravel: Beyond the Basics"
original_slug: "learn-laravel-beyond-the-basics"
status: "draft"
---

# Belajar Laravel Tingkat Lanjut

## Deskripsi
Tingkatkan kemampuan Laravel Anda. Kembangkan Catatku dengan relationship, authorization, file upload, REST API, testing dengan Pest, queue, event, dan deployment.

## Konten
Anda telah membangun Catatku, sebuah aplikasi jurnal pribadi, di course pemula. Anda mempelajari route, controller, model Entry, Blade component, operasi CRUD, dan authentication dasar. Sekarang saatnya menyelam lebih dalam.

Course ini mengembangkan Catatku dengan fitur-fitur yang dibutuhkan oleh setiap aplikasi Laravel production. Anda akan menambahkan komentar pada entri (relationship one-to-many), tag (many-to-many), authorization sehingga pengguna hanya dapat memodifikasi entri milik mereka sendiri, file upload untuk gambar sampul, notifikasi email, sebuah REST API dengan authentication Sanctum, automated testing dengan Pest, pemrosesan background job dengan queue, dan deployment ke production.

Setiap lesson dibangun di atas lesson sebelumnya, menambahkan satu fitur atau konsep dalam satu waktu. Model Entry, component x-layout, dan sistem authentication dari course pemula menjadi fondasi untuk segala sesuatu di course ini.

**Prasyarat:**
- Telah menyelesaikan course "[Learn Laravel for Beginners](https://qadrlabs.com/course/learn-laravel-for-beginners)" (Catatku dengan model Entry)
- Nyaman dengan: routing, controller, dasar Eloquent, Blade template (x-layout, x-entry-card), CRUD, auth dasar
- Environment pengembangan Laravel 13

**Di akhir course ini, Anda akan memiliki:**
- Relationship Eloquent: one-to-many (Entry memiliki Comment), many-to-many (Entry memiliki Tag)
- Query scope, accessor, mutator, eager loading, soft delete, pagination
- Authorization dengan Gate dan Policy
- File upload dengan facade Storage
- Notifikasi email dengan Mailable
- Sebuah REST API dengan authentication token Sanctum
- Automated test dengan Pest
- Background job dengan queue, event dan listener
- Blade component dan integrasi Tailwind CSS
- Pengetahuan deployment production

## Daftar Modul

### 1. Modul 1 - Relasi Database
- Lesson 1 - Relasi One-to-Many
- Lesson 2 - Relasi Many-to-Many

### 2. Modul 2 - Eloquent Lanjutan
- Lesson 3 - Scope, Accessor, dan Mutator
- Lesson 4 - Eager Loading, Soft Delete, dan Pagination

### 3. Modul 3 - Otorisasi
- Lesson 5 - Gate dan Policy
- Lesson 6 - Middleware dan Proteksi Route

### 4. Modul 4 - Penyimpanan File dan Email
- Lesson 7 - File Upload dan Storage
- Lesson 8 - Mengirim Email dengan Mailable

### 5. Modul 5 - Pengembangan REST API
- Lesson 9 - Membangun REST API
- Lesson 10 - API Resource dan Authentication Sanctum

### 6. Modul 6 - Testing dengan Pest
- Lesson 11 - Feature Testing dengan Pest
- Lesson 12 - Unit Testing dan Database Testing

### 7. Modul 7 - Pemrosesan Background
- Lesson 13 - Queue dan Job
- Lesson 14 - Event dan Listener

### 8. Modul 8 - Blade Lanjutan dan Frontend
- Lesson 15 - Blade Component dan Layout
- Lesson 16 - Integrasi Vite dan Tailwind CSS

### 9. Modul 9 - Deployment dan Review
- Lesson 17 - Deploy ke Production
- Lesson 18 - Langkah Selanjutnya
