---
title: "Belajar Kontribusi di Project Open Source"
slug: "belajar-kontribusi-di-project-open-source"
category: "Git"
date: "2021-10-08"
status: "published"
---

Tidak terasa kita sudah memasuki bulan Oktober dan seperti biasa sudah ada banyak programmer yang share info terkait kontribusi ke open source, tanda event [Hacktoberfest](https://qadrlabs.com/post/hacktoberfest-dimulai-yuk-ikutan-kontribusi) kembali dimulai. Sebagai pemula di dunia open source, hal yang pertama yang saya rasakan itu adalah ragu untuk memulai berkontribusi. Untuk itu saya mencoba untuk belajar kontribusi terlebih dahulu sebelum ikut dalam project open source. Kamu juga mengalami hal yang sama? Kalau begitu, yuk kita sama-sama belajar kontribusi di open source.

Dari postingan belajar cara berkontribusi ke open source ini, kita akan simulasikan alur untuk melakukan kontribusi ke open source, sehingga kita bisa sama-sama belajar, dimulai dari fork repositori sampai dengan melakukan pull request. Di sini juga kita sudah menyiapkan [repositori](https://github.com/qadrLabs/belajar-kontribusi) khusus untuk belajar, jadi kita tidak harus cari repositori mana yang mau kita gunakan untuk belajar.

Dan untuk lebih jelasnya, di bawah ini adalah langkah-langkah untuk kontribusi di repositori belajar kontribusi.
1. Fork repositori belajar kontribusi
2. Clone repositori hasil fork
3. Buat branch baru
4. Modifikasi dan commit
5. Push ke GitHub
6. Pull Request

## 1. Fork Repositori{#fork-repositori}
Fork repositori [ini](https://github.com/qadrLabs/belajar-kontribusi) dengan cara menekan tombol fork di sebelah kanan atas. 

![fork repositori](https://cdn.jsdelivr.net/gh/qadrLabs/belajar-kontribusi@main/screenshot/image-1.png)

Tunggu sampai proses fork repositori selesai. Setelah selesai kita masuk ke halaman repositori hasil fork tadi dan biasanya ada keterangan `forked from qadrLabs/belajar-kontribusi` di bawah nama repositori kita.

## 2. Clone repositori hasil fork{#clone-repositori}
Selanjutnya, clone repo hasil fork yang ada di akun kamu ke komputer local. Tekan tombol Code, lalu tekan icon *copy to clipboard* .
![clone repositori](https://cdn.jsdelivr.net/gh/qadrLabs/belajar-kontribusi@main/screenshot/image-2.png)

![copy link untuk clone repository](https://cdn.jsdelivr.net/gh/qadrLabs/belajar-kontribusi@main/screenshot/image-3.png)

Selanjutnya buka terminal, lalu run `git command` di bawah ini:
```
git clone "url yang udah dicopy"
```

Contohnya:
```
git clone https://github.com/username-kamu/belajar-kontribusi.git
```

Di mana `username-kamu` diisi sama username akun GitHub kamu.

## 3. Buat branch baru{#create-branch}
Setelah repositori di-clone, selanjutnya kita masuk ke folder repositori dengan run `command`:
```
cd belajar-kontribusi
```

Ketika kita ingin melakukan perubahan ada baiknya kita buat `branch` baru. Nah sekarang kita buat branch baru menggunakan command `git checkout`:

```
git checkout -b <add-nama-kamu>
```

Contohnya:
```
git checkout -b add-gun-gun
```

Nama branch-nya bebas. Nah umumnya disesuaikan sama tujuan branch dibuat ya. Setelah run `command` di atas ada output seperti ini.
```bash
Switched to a new branch 'add-gun-gun'
```

Ini artinya kita sudah ada di branch yang baru saja kita buat.

## 4. Modifikasi dan Commit{#modif-and-commit}
Pada tahapan ini kita akan melakukan perubahan pada repositori, bisa dengan menambahkan kode, mengubah dokumentasi dan lain-lain.

Di tutorial belajar kontribusi kali ini, kita coba menambahkan file baru di dalam folder `Contributors`.

Buat file baru di dalam folder `Contributors` dengan format `nama-kamu.md` contohnya (`gun-gun-priatna.md`) menggunakan text editor favorit kamu. Di sini kita akan menggunakan Markdown. Tentang markdown bisa kamu baca-baca cheatsheet-nya [di sini yaa.](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet).

Sekarang di file `nama-kamu.md`, kita coba tuliskan nama dan deskripsi tentang kita. 

```
Name: [nama-kamu](url-akun-github) 
About: [Deskripsi tentang kamu]
```

Contohnya:
```
Name: [Gun Gun Priatna](https://github.com/gungunpriatna) 
About: Saya seorang web developer
```

Kamu boleh menuliskan asal untuk nama dan deskripsinya ya, karena ini tujuannya untuk belajar, bukan untuk mengumpulkan data.

Sekarang run command `git status` buat lihat modifikasi apa saja yang udah kamu lakukan. 
Selanjutnya tambahkan dengan menggunakan command `git add`:

```
git add Contributors/nama-kamu.md
```

Lalu commit modifikasi yang udah kamu buat menggunakan command: `git commit`:
```
git commit -m "Add <nama-kamu> ke daftar kontributor"
```

Ubah `<nama-kamu>` sama nama kamu ya.

## 5. Push ke GitHub{#push}
Kita sudah menambahkan perubahan ke repositori belajar. Langkah selanjutnya adalah push branch repositori local ke github dengan command `git push`:
```
git push origin <add-nama-kamu>
```

Ubah `<add-nama-kamu>` dengan nama branch yang sebelumnya sudah dibuat.

## 6. Pull Request{#pull-request}
Kalau kamu buka repositori kamu di GitHub, kamu bisa lihat tombol `Compare & pull request` button.  Tekan tombol tersebut.

![Coba untuk pull request](https://cdn.jsdelivr.net/gh/qadrLabs/belajar-kontribusi@main/screenshot/image-4.png)

Nah selanjutnya tekan tombol Create pull request.

![Create pull request](https://cdn.jsdelivr.net/gh/qadrLabs/belajar-kontribusi@main/screenshot/image-5.png)

Ya, selesai. Kalau kita sudah coba sampai tahap ini, kita tinggal menunggu hasil kontribusi kita direview dan diterima sama maintainer repositori.

## Sinkronisasi Fork{#sinkronisasi-fork}

Jika repositori asli mengalami perubahan setelah kamu melakukan fork, kamu bisa menyinkronkan fork kamu dengan langkah-langkah berikut:

### 1. Tambahkan remote upstream
Pastikan kamu menambahkan repositori asli sebagai `upstream` di fork kamu. Jalankan perintah berikut di terminal:

```
git remote add upstream https://github.com/qadrLabs/belajar-kontribusi.git
```

Perintah ini akan menambahkan repositori asli sebagai referensi `upstream`, yang memungkinkan kamu untuk menarik perubahan dari sana.

### 2. Cek remote yang sudah ditambahkan
Untuk memastikan bahwa remote `upstream` sudah ditambahkan dengan benar, gunakan perintah berikut:

```
git remote -v
```

Perintah ini akan menampilkan daftar semua remote yang terhubung ke fork kamu, baik `origin` (fork kamu) maupun `upstream` (repositori asli).

### 3. Tarik perubahan dari upstream
Untuk menarik perubahan terbaru dari repositori asli (upstream), jalankan perintah berikut:

```
git fetch upstream
```

Perintah ini akan mengambil (fetch) semua perubahan dari repositori asli tanpa menggabungkannya ke dalam fork kamu.

### 4. Gabungkan perubahan dari upstream ke branch lokal
Setelah menarik perubahan, kamu bisa menggabungkannya ke branch `main` lokal kamu:

```
git merge upstream/main
```

Ini akan menggabungkan semua perubahan dari branch `main` di upstream ke branch `main` lokal kamu.

### 5. Push ke Fork kamu
Terakhir, setelah branch lokal kamu diperbarui, kamu bisa mendorong perubahan ini ke fork kamu di GitHub dengan perintah berikut:

```
git push origin main
```

Setelah melakukan ini, fork kamu sudah sinkron dengan repositori asli.

## Kesimpulan{#kesimpulan}
Di tutorial ini, kita sudah belajar bagaimana cara berkontribusi ke project open source. Kita sudah coba simulasikan dari mulai fork repositori sampai dengan melakukan pull request. Setelah belajar di sini, kamu bisa coba ikut kontribusi langsung di GitHub ataupun GitLab. Biasanya ada banyak [repositori](https://github.com/topics/good-first-issue) yang bisa kamu coba untuk ikut berkontribusi.

Semoga bermanfaat dan semoga semakin semangat berkontribusi.