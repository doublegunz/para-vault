# Arsip Session Chat — Qadrlabs Visual Content Workflow

Tanggal arsip: 2026-06-13  
Topik utama: pembuatan caption, prompt storyboard, prompt video, dan master prompt untuk konten edukasi teknis Qadrlabs.

---

## 1. Konteks Umum

Session ini berisi pengembangan workflow konten visual edukasi untuk artikel-artikel teknis Qadrlabs, terutama untuk format:

- Instagram Reels
- TikTok
- YouTube Shorts
- LinkedIn post
- Threads post
- Storyboard visual 9:16
- Prompt video 10 detik + 10 detik
- Caption edukatif untuk social media

Style utama yang digunakan:

- Premium SaaS coding education
- Qadrlabs purple-to-blue branding
- Deep navy background
- Electric blue, violet purple, cyan glow
- Clean futuristic backend engineering style
- No human faces
- No clutter
- No watermark
- No random text
- Clean UI cards
- Terminal panels
- Architecture diagrams
- Motion arrows
- Production notes
- Educational annotations

---

## 2. Ketentuan Tetap untuk Storyboard

Jika membuat storyboard, format yang digunakan adalah dua storyboard terpisah.

### Storyboard Video 1

- Durasi 10 detik
- Vertical 9:16
- 5 panel
- 1 column x 5 rows atau vertical stacked storyboard layout
- Tidak menampilkan teks: “Part 1”, “Video 1”, “Continue”, “Continue Part 2”, atau split marker
- Ending harus open transition agar bisa digabung ke video 2

### Storyboard Video 2

- Durasi 10 detik
- Vertical 9:16
- 5 panel
- 1 column x 5 rows atau vertical stacked storyboard layout
- Tidak menampilkan teks: “Part 2”, “Video 2”, “Continue”, atau split marker
- Tidak mengulang opening logo
- Langsung terasa sebagai lanjutan dari video 1
- Berakhir dengan brand closing Qadrlabs

### Setiap Panel Storyboard Harus Memuat

- Panel number
- Timestamp
- Main visual composition
- Short on-screen text
- Micro text maksimal 2 baris
- Motion direction arrows
- Transition notes
- Small handwritten-style production notes
- Camera movement notes
- Clean educational annotations

---

## 3. Ketentuan Tetap untuk Prompt Video

Jika membuat prompt video, format yang digunakan adalah dua prompt video terpisah.

### Video Prompt 1

- 10 seconds
- Vertical 9:16
- No voiceover
- No narration
- No dialogue
- No background music
- No BGM
- Sound effects only
- Optimized animation version
- No part marker
- Tidak menampilkan “Part 1”, “Video 1”, “Continue”, atau split marker
- Final frame harus open transition agar bisa digabung ke video 2

### Video Prompt 2

- 10 seconds
- Vertical 9:16
- No voiceover
- No narration
- No dialogue
- No background music
- No BGM
- Sound effects only
- Optimized animation version
- No part marker
- Tidak menampilkan “Part 2”, “Video 2”, “Continue”, atau split marker
- Jangan ulangi opening logo animation
- Mulai langsung dari visual lanjutan video 1
- Berakhir dengan brand closing Qadrlabs

### Audio Rule untuk Video

Gunakan sound effect saja:

- Soft digital whoosh
- Gentle UI clicks
- Terminal typing sounds
- Data-flow sounds
- Dashboard scan sounds
- Confirmation chime
- Soft glitch hanya untuk problem/error scene
- Warning beep hanya untuk failure/error scene
- Logo shimmer pada closing
- Tidak boleh ada musik
- Tidak boleh ada cinematic hit yang agresif
- Tidak boleh ada dramatic trailer sound

### Text Style untuk Video

Karena tidak ada narasi, teks harus singkat dan mudah dibaca.

Setiap scene maksimal:

- 1 main text line
- 2 supporting micro text lines

---

## 4. Struktur Prompt Video yang Disepakati

Untuk setiap prompt video, gunakan struktur:

1. Title
2. Duration
3. Aspect Ratio
4. Main Topic
5. Main Goal
6. Core Message
7. Brand Reference
8. Visual Style
9. Color Palette
10. Audio Rule
11. Sound Effect Style
12. Text Style
13. Animation Priority
14. Scene-by-scene breakdown, 5 scenes, masing-masing 2 detik
15. Important Visual Rules

### Setiap Scene Video Harus Memuat

- Scene title
- Duration
- Visual
- Text on screen
- Supporting micro text
- Visual details
- Animation
- Camera
- Sound effects
- Transition

---

## 5. Important Visual Rules yang Selalu Dipakai

- No voiceover
- No narration
- No dialogue
- No background music
- Use sound effects only
- No part marker
- No characters
- No human faces
- No random text
- No cluttered background
- No watermark
- Keep text readable
- Avoid excessive code
- Use simple readable snippets only where necessary
- Avoid real private URLs, secret keys, tokens, or credentials
- Do not show real user data
- Maintain Qadrlabs purple-to-blue brand identity
- Suitable for Instagram Reels, TikTok, YouTube Shorts, and coding educational promo videos

---

## 6. Caption Style yang Disepakati

Jika membuat caption Reels/Instagram:

- Gunakan bahasa Inggris
- Ringkas tetapi tetap berisi insight
- Jangan memaksa pembaca mengunjungi artikel
- Gunakan “we” atau gaya brand Qadrlabs jika konteksnya untuk page Qadrlabs
- Boleh gunakan emoji secukupnya
- Gunakan hashtag relevan
- Fokus pada nilai praktis materi

---

## 7. Artikel dan Konten yang Dibahas

### 7.1 Queue Rate Limiting and Batching in Laravel

Artikel awal:

> Queue Rate Limiting and Batching in Laravel: Send Thousands of Bulk Emails Without Getting Banned by Your SMTP Provider

Konten yang dibuat:

- Redaksi post LinkedIn bahasa Inggris
- Versi Instagram tanpa URL
- Versi Threads maksimal 500 karakter per post
- Prompt video ilustrasi
- Prompt storyboard
- Caption video Instagram

Konsep utama:

- Bulk email tidak boleh dikirim sekaligus
- Gunakan queue job
- Gunakan rate limiting
- Gunakan batching
- Gunakan retry strategy seperti `retryUntil()`
- Lindungi reputasi SMTP

---

### 7.2 SOLID Principles

Konten yang dibuat:

- Prompt storyboard 20 detik
- Prompt video 1 dan 2
- Versi tanpa narasi
- Versi tanpa BGM
- Caption video IG

Konsep utama:

- SOLID bukan untuk membuat kode rumit
- SOLID membantu kode siap berubah
- S — Single Responsibility
- O — Open/Closed
- L — Liskov Substitution
- I — Interface Segregation
- D — Dependency Inversion

Caption ringkas:

```text
Messy code is not just hard to read.
It is hard to change 😅

That is why SOLID matters.

SOLID helps developers design code that is easier to maintain, easier to test, and safer to extend.

S — Single Responsibility
One class, one clear reason to change.

O — Open/Closed
Add new behavior without breaking existing code.

L — Liskov Substitution
Every implementation should behave correctly when swapped.

I — Interface Segregation
Keep interfaces small and focused.

D — Dependency Inversion
Depend on abstractions, not concrete details.

The goal is not to make code more complicated.
The goal is to make code ready for change.

Design code that can change safely 🚀
```

---

### 7.3 Laravel 13 Feature Overview

Konten yang dibuat:

- Prompt storyboard 20 detik
- Prompt video 1 dan 2
- Versi tanpa voiceover
- Versi tanpa BGM
- Hanya sound effect
- Caption video IG

Konsep utama:

- Laravel 13 release overview
- PHP 8.3+ requirement
- Minimal breaking changes
- Laravel AI SDK
- Native vector search
- JSON:API resources
- PreventRequestForgery
- Queue routing
- PHP attributes
- Cache::touch()
- Installation workflow

Caption ringkas:

```text
Laravel 13 is here 🚀

A modern release focused on AI-native workflows, expressive APIs, stronger defaults, and smoother developer experience.

What’s new?

✅ Laravel AI SDK
Build AI agents, generate text, images, audio, and embeddings with a Laravel-native API.

✅ Native vector search
Create meaning-based search experiences using embeddings and pgvector support.

✅ JSON:API resources
Build standard-compliant API responses without extra packages.

✅ Stronger request protection
PreventRequestForgery adds origin-aware verification while keeping CSRF compatibility.

✅ Cleaner configuration
Use Queue::route() and expanded PHP attributes for more declarative code.

✅ Small but useful APIs
Cache::touch() lets you extend cache TTL without re-storing the value.

✅ Lightweight upgrade
Laravel 13 brings powerful new features with minimal breaking changes.

Laravel 13 is not just a version update.
It is a step toward modern, AI-ready, and cleaner backend development.

Explore modern Laravel with clarity ✨
```

---

### 7.4 Laravel Soft Deletes + Database Transactions

Konten yang dibuat:

- Prompt storyboard 20 detik
- Dua prompt storyboard terpisah
- Prompt video 1
- Prompt video 2
- Caption video Reels

Konsep utama:

- SoftDeletes
- `softDeletes()` migration column
- `deleted_at`
- Half-archived data problem
- Project → Tasks cascade
- `DB::transaction`
- Automatic rollback
- Restore atomically
- `withTrashed()`
- `onlyTrashed()`
- Pest tests
- Safe, atomic, recoverable, testable data flows

Caption ringkas:

```text
Soft delete is useful, but it is not always enough.

Imagine archiving a project, but only half of its tasks are archived because the process fails in the middle 😬

Now your database has a hidden project with active tasks still pointing to it.

That is why multi-step archive operations need a transaction.

In Laravel, a safer pattern is:

✅ Use SoftDeletes to mark records with deleted_at
✅ Wrap the cascade inside DB::transaction
✅ Archive related records as one unit
✅ Restore parent and children together
✅ Use withTrashed() and onlyTrashed() intentionally
✅ Test rollback behavior with Pest

The goal is simple:

Either everything is archived together, or nothing changes at all.

Soft deletes hide records.
Transactions protect consistency.

Build safer Laravel data flows 🚀
```

---

### 7.5 Laravel Health Checks + Readiness Monitoring

Konten yang dibuat:

- Dua prompt storyboard terpisah
- Prompt video 1 dan 2
- Caption Reels
- Saran keamanan untuk endpoint `/health`

Konsep utama:

- Liveness vs readiness
- Laravel `/up`
- Custom `/health`
- Database readiness check
- Cache roundtrip check
- JSON response
- HTTP status code `200 OK` dan `503 Service Unavailable`
- Pest tests
- Simulated database failure
- Simulated cache failure
- Independent dependency checks
- Uptime Robot keyword monitor
- Alerting before users complain

Caption ringkas:

```text
Your app can be “up” but still not ready to serve users.

A homepage check may return 200 OK, while the database is down and real user actions keep failing with 500 😬

That is the difference between liveness and readiness.

/up tells you the process is alive.
/health should tell you whether the app can actually work.

A better Laravel health endpoint should:

✅ Check the database connection
✅ Test cache write and read
✅ Return JSON health status
✅ Send 200 OK when healthy
✅ Send 503 Service Unavailable when degraded
✅ Be tested with Pest
✅ Be monitored externally with Uptime Robot

The goal is simple:

Do not wait for angry customer emails.
Let your monitoring detect real dependency failures first.

Ready. Observable. Reliable. 🚀
```

#### Catatan Keamanan Endpoint Health

Saran keamanan yang dibahas:

- Jangan tampilkan error detail di production
- Pisahkan public health dan private health detail
- Tetap gunakan status code yang benar
- Jangan taruh di middleware web biasa
- Tambahkan rate limiting ringan
- Jangan jalankan check yang berat
- Gunakan HTTPS
- Hindari endpoint lokal terbuka terlalu lama
- Pakai keyword monitoring yang spesifik, misalnya `"status":"healthy"`
- Jangan hanya keyword `healthy`, karena bisa match dengan `unhealthy`

Rekomendasi final:

```text
Buat /health publik dengan response minimal dan status code benar,
lalu simpan detail dependency untuk log atau endpoint internal.
Dengan begitu monitor tetap bisa mendeteksi outage,
tetapi attacker tidak mendapatkan peta detail infrastruktur aplikasi.
```

---

### 7.6 Upgrade Laravel 12 ke Laravel 13

Artikel yang dipastekan membahas:

- Laravel 13 release date
- AI SDK
- Native vector search
- JSON:API resources
- Minimal breaking changes
- Upgrade Laravel 12 ke Laravel 13
- Clone dummy project
- Run baseline tests
- Verify PHP version
- Update dependencies
- Run Composer update
- Verify Laravel version
- Run tests again
- Conclusion

Konten yang dibuat:

- Dua prompt storyboard terpisah
- Prompt video 1 dan video 2
- Caption video Reels

Konsep utama:

- Start from Laravel 12 baseline
- Run tests before upgrade
- Check PHP 8.3+
- Update composer.json:
  - `php` → `^8.3`
  - `laravel/framework` → `^13.0`
  - `laravel/tinker` → `^3.0`
  - `phpunit/phpunit` → `^12.0`
- Run `composer update`
- Verify with `php artisan --version`
- Run tests again
- Confirm no regression

Caption ringkas:

```text
Upgrading Laravel 12 to Laravel 13 does not have to feel risky 🚀

The key is not just changing versions.
The key is upgrading with a clear safety flow.

Before upgrading:

✅ Start from a working Laravel 12 app
✅ Run your test suite first
✅ Make sure you have a green baseline
✅ Check PHP version, Laravel 13 requires PHP 8.3+

Then update your dependencies:

✅ laravel/framework → ^13.0
✅ laravel/tinker → ^3.0
✅ phpunit/phpunit → ^12.0
✅ Run composer update

After that, verify everything:

✅ Check the installed version with php artisan --version
✅ Run your tests again
✅ Confirm there is no regression

Upgrade rule:

Do not guess.
Check, update, verify, and test.

Laravel 13 brings modern features like AI SDK, vector search, JSON:API resources, and more, while keeping the upgrade process lightweight for most projects.

Upgrade Laravel with confidence ✨
```

---

## 8. Master Prompt untuk Session Baru

Prompt berikut dibuat agar bisa dipaste di chat session baru supaya workflow tetap konsisten.

```text
Saya ingin membuat konten visual edukasi untuk artikel teknis Qadrlabs.

Tugas Anda:
Bantu saya membuat:
1. Prompt storyboard
2. Prompt video
3. Caption Reels/Instagram jika diminta

Gunakan gaya dan ketentuan tetap berikut.

BRAND STYLE:
Gunakan identitas visual Qadrlabs:
- premium SaaS coding education
- clean futuristic backend engineering style
- purple-to-blue gradient branding
- deep navy background
- electric blue, violet purple, cyan glow
- rounded modern typography
- clean UI cards
- terminal panels
- architecture diagrams
- glowing connection lines
- no clutter
- no watermark
- no human faces
- no random text

Jika saya upload logo Qadrlabs, gunakan logo tersebut sebagai strict brand identity reference.

FORMAT STORYBOARD:
Jika saya meminta storyboard, buat 2 prompt storyboard terpisah:

STORYBOARD VIDEO 1:
- durasi 10 detik
- vertical 9:16
- 5 panel
- 1 column x 5 rows atau vertical stacked storyboard layout
- tidak boleh menampilkan teks “Part 1”, “Video 1”, “Continue”, “Continue Part 2”, atau split marker
- harus terasa sebagai bagian pertama dari video 20 detik
- ending harus open transition agar bisa digabung ke video 2

STORYBOARD VIDEO 2:
- durasi 10 detik
- vertical 9:16
- 5 panel
- 1 column x 5 rows atau vertical stacked storyboard layout
- tidak boleh menampilkan teks “Part 2”, “Video 2”, “Continue”, atau split marker
- tidak boleh mengulang opening logo
- harus langsung terasa sebagai lanjutan dari video 1
- harus berakhir dengan brand closing Qadrlabs

SETIAP PANEL STORYBOARD HARUS MEMUAT:
- panel number
- timestamp
- main visual composition
- short on-screen text
- micro text maksimal 2 baris
- motion direction arrows
- transition notes
- small handwritten-style production notes
- camera movement notes
- clean educational annotations

STYLE STORYBOARD:
Gunakan gaya:
- clean digital illustration storyboard
- premium SaaS promo planning board
- modern coding education visual
- polished technical explainer layout
- futuristic backend workspace
- floating UI panels
- terminal cards
- dependency cards
- dashboard cards
- architecture blocks
- subtle grid lines
- soft neon glow
- minimal, clean, premium

FORMAT VIDEO PROMPT:
Jika saya meminta prompt video, buat 2 prompt video terpisah:

VIDEO PROMPT 1:
- 10 seconds
- vertical 9:16
- no voiceover
- no narration
- no dialogue
- no background music
- no BGM
- sound effects only
- optimized animation version
- no part marker
- tidak boleh menampilkan “Part 1”, “Video 1”, “Continue”, atau split marker
- final frame harus open transition agar bisa digabung ke video 2

VIDEO PROMPT 2:
- 10 seconds
- vertical 9:16
- no voiceover
- no narration
- no dialogue
- no background music
- no BGM
- sound effects only
- optimized animation version
- no part marker
- tidak boleh menampilkan “Part 2”, “Video 2”, “Continue”, atau split marker
- jangan ulangi opening logo animation
- mulai langsung dari visual lanjutan video 1
- berakhir dengan brand closing Qadrlabs

AUDIO RULE UNTUK VIDEO:
Gunakan sound effect saja:
- soft digital whoosh
- gentle UI clicks
- terminal typing sounds
- data-flow sounds
- dashboard scan sounds
- confirmation chime
- soft glitch hanya untuk problem/error scene
- warning beep hanya untuk failure/error scene
- logo shimmer pada closing
- tidak boleh ada musik
- tidak boleh ada cinematic hit yang agresif
- tidak boleh ada dramatic trailer sound

TEXT STYLE UNTUK VIDEO:
Karena tidak ada narasi, teks harus singkat dan mudah dibaca.
Setiap scene maksimal:
- 1 main text line
- 2 supporting micro text lines

ANIMATION PRIORITY:
Optimalkan animasi:
- smooth object transitions
- parallax floating UI cards
- terminal typing motion
- glowing connection lines
- dashboard card morphing
- package/data flow animation
- green check reveal
- red warning pulse only when needed
- clean snap-to-grid movement
- final brand convergence animation

STRUKTUR VIDEO PROMPT:
Untuk setiap video prompt, gunakan struktur:
1. Title
2. Duration
3. Aspect Ratio
4. Main Topic
5. Main Goal
6. Core Message
7. Brand Reference
8. Visual Style
9. Color Palette
10. Audio Rule
11. Sound Effect Style
12. Text Style
13. Animation Priority
14. Scene-by-scene breakdown, 5 scenes, masing-masing 2 detik
15. Important Visual Rules

SETIAP SCENE VIDEO HARUS MEMUAT:
- scene title
- duration
- visual
- text on screen
- supporting micro text
- visual details
- animation
- camera
- sound effects
- transition

IMPORTANT VISUAL RULES:
Selalu cantumkan:
- No voiceover
- No narration
- No dialogue
- No background music
- Use sound effects only
- No part marker
- No characters
- No human faces
- No random text
- No cluttered background
- No watermark
- Keep text readable
- Avoid excessive code
- Use simple readable snippets only where necessary
- Avoid real private URLs, secret keys, tokens, or credentials
- Do not show real user data
- Maintain Qadrlabs purple-to-blue brand identity
- Suitable for Instagram Reels, TikTok, YouTube Shorts, and coding educational promo videos

CAPTION STYLE:
Jika saya meminta caption Reels/Instagram:
- gunakan bahasa Inggris
- ringkas tetapi tetap berisi insight
- jangan memaksa pembaca mengunjungi artikel
- gunakan “we” atau gaya brand Qadrlabs jika konteksnya untuk page Qadrlabs
- boleh gunakan emoji secukupnya
- gunakan hashtag relevan
- fokus pada nilai praktis materi

OUTPUT LANGUAGE:
Kecuali saya minta bahasa lain, jelaskan instruksi kepada saya dalam bahasa Indonesia, tetapi prompt storyboard, prompt video, dan caption Qadrlabs dibuat dalam bahasa Inggris.

Jika saya paste artikel, baca artikelnya lalu ringkas menjadi alur visual 20 detik:
- Video 1: problem, context, baseline, or setup
- Video 2: solution, verification, monitoring, testing, or closing
```

---

## 9. Catatan Praktis untuk Melanjutkan di Session Baru

Gunakan format perintah berikut:

```text
Gunakan master prompt Qadrlabs berikut.
Buatkan dua prompt storyboard untuk artikel ini:
[paste artikel]
```

Atau:

```text
Gunakan ketentuan Qadrlabs visual education workflow.
Buatkan prompt video 1 dan video 2 untuk artikel berikut:
[paste artikel]
```

Atau:

```text
Buatkan caption Reels IG untuk artikel berikut.
Gunakan gaya Qadrlabs, bahasa Inggris, ringkas, edukatif, dan berisi insight:
[paste artikel]
```

---

## 10. Ringkasan Workflow Paling Penting

Alur kerja tetap:

1. User paste artikel teknis
2. Assistant membaca dan meringkas materi
3. Buat alur visual 20 detik
4. Pecah menjadi 2 video:
   - Video 1: problem, context, baseline, setup
   - Video 2: solution, verification, monitoring, testing, closing
5. Buat 2 prompt storyboard terpisah
6. Generate storyboard jika diminta
7. Buat 2 prompt video terpisah
8. Buat caption Reels/Instagram jika diminta

---

## 11. File Ini

File ini dibuat sebagai arsip percakapan session chat untuk membantu melanjutkan workflow Qadrlabs di session berikutnya.
