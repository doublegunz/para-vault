---
title: "Formula Gaya Tulisan Personal (qadrlabs klasik)"
created: 2026-06-21
tags:
  - qadrlabs
  - writing
  - style-guide
  - formula
status: active
---

# Formula Gaya Tulisan Personal (qadrlabs klasik)

Dokumen ini adalah hasil bedah (reverse-engineer) suara asli tulisan tutorial qadrlabs yang hangat, bercerita, dan akrab. Tujuannya: jadi cetak biru supaya artikel baru bisa ditulis ulang dengan rasa yang sama, baik dalam **bahasa Indonesia** maupun **bahasa Inggris**.

Pakai dokumen ini kapan pun ingin menulis artikel dengan **suara personal** (bukan suara "skill `generate-artikel`" yang formal dan berbahasa Inggris baku). Suara di sini adalah suara yang dipakai di tutorial CodeIgniter awal.

**Artikel acuan (canonical voice):**
- [[membuat-simple-login-dan-register-menggunakan-codeigniter]]
- [[tutorial-codeigniter-upload-image]]

**Kontras (gaya rewrite/SEO, JANGAN ditiru di sini):**
- [[crud-sederhana-codeigniter]]
- [[mudahnya-membuat-pagination-pada-codeigniter]]

> **Penting:** jangan campur dua gaya. Gaya rewrite memakai "Anda", bullet value-proposition ala marketing, dan nada korporat ("standar industri", "powerful"). Formula ini sebaliknya: santai, "kamu", bercerita.

## 1. Prinsip Suara (Voice DNA)

Bayangkan kamu sedang menemani seorang teman ngoding sambil ngopi. Kamu hangat, suka bercerita, mengajak mengerjakan bersama ("kita"), menyapa akrab ("kamu", "teman-teman", "kawan"), sesekali main-main dan menyemangati, **tapi tetap menuntun langkah demi langkah dengan jelas dan akurat**.

Tiga kata kunci: **hangat, bercerita, mengajak**. Kalau satu kalimat terasa kaku/korporat, kemungkinan besar itu keluar dari suara ini.

## 2. Aturan Bahasa & Register

**Versi Indonesia:**
- Sapaan pembaca: `kamu`, `teman-teman`, `kawan`. Jangan pakai `Anda`.
- Ajakan inklusif: `kita` ("kita akan membuat", "yuk kita ketik kodenya").
- Nada percakapan: boleh kalimat pendek, "Oke", "Nah", "Yep", "Iya, kamu benar".

**Versi Inggris:**
- Sapaan pembaca: `you`, `friends`, `folks`. Hindari nada formal/korporat.
- Ajakan inklusif: `let's`, `we'll` ("we'll build", "let's type the code").
- Nada percakapan: "Okay", "Alright", "Yep", "Yeah, you got it".

**Berlaku untuk dua bahasa:**
- **Tanpa em dash (`—`) dan en dash (`–`)** dalam bentuk apa pun. Pakai koma, titik koma, titik, "yaitu", "to/which" (EN), atau pecah jadi dua kalimat. Lihat [[qadrlabs-no-em-dash]].
- **Jangan** pakai `---` sebagai pemisah antar-section.

## 3. Resep Pembuka Bercerita (Storytelling Hook)

Ini ciri paling khas. Pola alurnya:

> anekdot / observasi kehidupan sehari-hari (awalnya terasa tak berhubungan) -> mengerucut ke pertanyaan teknis ("bagaimana caranya...?") -> "dari ide itu saya eksekusi jadi tutorial" -> sebut series + link tutorial terkait.

Pembuka boleh terasa "jauh" dulu (cerita di kedai kopi, fenomena media sosial), lalu pelan-pelan menukik ke topik. Pertanyaan teknisnya sering ditulis miring sebagai monolog batin.

**Contoh (ID):**
> *"Punya akun Instagram nggak?"* Pertanyaan biasa waktu baru kenalan. Hampir semua teman sekelas saya punya akun media sosial. Daftarnya gampang, cukup klak-klik, isi data diri, dan *voila!~* langsung jadi. Sampai akhirnya terlintas, *"bagaimana ya caranya membuat fitur daftar akun yang langsung bisa login seperti media sosial?"*. Dari ide itu saya eksekusi jadi tutorial. Yep, di [seri Belajar CodeIgniter 3](https://qadrlabs.com/series/belajar-codeigniter-3) kali ini kita akan membahas fitur login dan register.

**Contoh (EN):**
> *"Do you have an Instagram account?"* It is the usual question when you first meet someone. Almost all of my classmates have a social media account. Signing up is easy, just a few clicks, fill in your details, and *voila!~* you are in. Until one day it hit me, *"how do you actually build a sign-up feature that logs you in right away, like social media does?"*. So I turned that idea into a tutorial. Yep, in this [Learn CodeIgniter 3 series](https://qadrlabs.com/series/belajar-codeigniter-3) we'll build a login and register feature.

Kalau artikel adalah lanjutan dari tutorial lain, pembuka boleh juga **menyambung konteks tutorial sebelumnya** secara eksplisit dengan link, sebelum masuk ke cerita.

## 4. Kerangka Struktur Artikel

1. **Frontmatter YAML:** `title`, `slug`, `category`, `date`, `status`.
2. **Pembuka bercerita** (lihat bagian 3).
3. **`## Overview{#overview}`** — paragraf naratif: apa yang akan dibuat, teknologi yang dipakai, link ke tutorial terkait. Tutup dengan ajakan, mis. `*Check this out, ya!*` (ID) atau `*Check this out!*` (EN).
4. **Daftar Isi** (ID) / **Table of Contents** (EN) — list bullet dengan anchor link ke tiap step.
5. **`## Step N - Judul {#anchor}`** untuk langkah sekuensial. Anchor kebab-case. Pola tiap step:
   - instruksi naratif ("Sekarang kita buat file...")
   - snippet kode lengkap
   - penjelasan + ingatkan simpan ("simpan filenya dengan menekan `ctrl+s`")
   - kadang screenshot hasilnya
6. **Step terakhir = Uji Coba / Try It Out** — jalankan project, tampilkan screenshot, narasi gembira saat berhasil ("Tadaaa!!! Kita berhasil login. :D").
7. **`## Penutup{#penutup}`** (ID) / **`## Wrap Up{#wrap-up}`** (EN) — rangkuman **naratif** (bukan bullet) tentang apa yang sudah dipelajari, akui project masih sederhana, beri saran pengembangan, link tutorial lanjutan, link download source code (GitHub), tutup dengan penyemangat.
8. **`## Referensi:{#referensi}`** (ID) / **`## References:{#references}`** (EN) — bullet link dokumentasi resmi.

> Catatan: pada artikel canonical, judul ada di frontmatter (bukan H1 di body). Ikuti kebiasaan repo saat menulis artikel baru.

## 5. Palet Kepribadian (Signature Moves)

Bumbu khas yang boleh ditaburkan. Format `ID | EN`:

- **Emoji:** `:D`, `^^`, `:)` (sama untuk dua bahasa)
- **Interjeksi italic:**
  - `*yeay!*` | `*yay!*`
  - `*voila!~*` | `*voila!~*`
  - `*Tadaaa!!!*` | `*Tadaaa!!!*`
  - `*Check this out, ya!*` | `*Check this out!*`
  - `*Type this syntax ya!*` | `*Type this code!*`
- **Aside main-main:**
  - "Maka, secara ajaib akan muncul tabel users." | "And like magic, the users table appears."
  - "Iya, iya.. maksudnya perintah SQL sudah dieksekusi.. :D" | "Yeah, yeah.. I mean the SQL was executed.. :D"
  - "Iya, kamu benar." | "Yeah, you got it."
- **Pertanyaan retoris pendek:**
  - "Sudah?" / "Oke, selanjutnya..." | "Done?" / "Okay, next..."
- **Doa / penyemangat pembuka:**
  - "Sebelum mulai, alangkah baiknya kita berdoa dulu supaya codingnya lancar. :)" | "Before we start, let's say a little prayer so the coding goes smoothly. :)"
- **Frasa khas:**
  - "teks editor kesayanganmu" | "your favorite text editor"
  - "yuk kita koding lagi" | "let's get coding again"
- **Pemisah antar sub-item:** `\* \* \*` (sama untuk dua bahasa)
- **Penutup khas:**
  - "Semangat terus ya! Selamat belajar.. Semoga menyenangkan.. :D" | "Keep it up! Happy learning.. Hope it's fun.. :D"
- **Catatan/tips:** pakai `**Catatan:**` (ID) / `**Note:**` (EN) atau blockquote `>`.

## 6. Takaran (Jangan Kebablasan)

Otentik bukan berarti berisik. Pedoman:
- **Satu** anekdot pembuka per artikel, secukupnya saja.
- Emoji/interjeksi **ditabur**, bukan diborong. Rule of thumb: jangan tiap paragraf. Pakai di momen yang pas (selesai sebuah step, saat berhasil uji coba, transisi).
- Kode, perintah, versi, dan output **harus tetap akurat**. Kepribadian ada di narasi, bukan di ketelitian teknis.
- Jangan ubah/edit output terminal hasil uji coba nyata. Tampilkan apa adanya.

## 7. Checklist Cepat (Sebelum Publish)

- [ ] Pembuka bercerita (anekdot -> pertanyaan teknis -> link series) ada?
- [ ] Sapaan konsisten (`kamu`/`teman-teman` atau `you`/`friends`), tidak ada "Anda"/nada formal?
- [ ] Ada `## Overview` + Daftar Isi ber-anchor?
- [ ] Step sekuensial pakai format `## Step N - Judul {#anchor}`?
- [ ] Ada step Uji Coba dengan narasi keberhasilan?
- [ ] Penutup naratif + saran pengembangan + link source code + penyemangat?
- [ ] Ada section Referensi?
- [ ] **Tanpa em dash/en dash**, tanpa `---` sebagai pemisah?
- [ ] Emoji/interjeksi secukupnya (tidak tiap paragraf)?

## 8. Anti-pattern (Tanda Keluar dari Suara Ini)

- Memakai sapaan **"Anda"** yang formal (ID) atau nada korporat (EN).
- Bullet **value-proposition ala marketing** ("Fully customizable", "Kinerja optimal", "standar industri", "powerful").
- Pembuka **langsung teknis** tanpa cerita.
- Nada kaku/dingin, tanpa sapaan dan tanpa "kita".
- `---` sebagai pemisah section, atau em/en dash di mana pun.
- Penutup berupa bullet "key takeaways" formal (itu gaya skill `generate-artikel`, bukan gaya personal ini).

## Catatan Lanjutan

Kalau nanti formula ini mau dijadikan skill (mis. `generate-artikel-gaya-saya`) supaya bisa dipanggil langsung, dokumen ini bisa jadi basisnya. Untuk sekarang, ini dipakai sebagai panduan tertulis. Lihat juga aturan teknis yang tetap berlaku lintas-gaya di skill `generate-artikel` (no em dash, heading anchor) dan [[qadrlabs-no-em-dash]].



---
claude --resume b7eed7bc-80cb-4afc-b4ad-3e2be3be4b2a
