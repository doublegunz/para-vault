---
title: "Deploy Website Menggunakan Git FTP"
slug: "deploy-website-menggunakan-git-ftp"
category: "Web Development"
date: "2021-05-21"
status: "published"
---

Developer website sering dihadapkan dengan situasi hosting yang hanya menyediakan akses FTP untuk deployment, tanpa dukungan git atau CI/CD. Meski deployment awal via FTP cukup sederhana, proses update website menjadi sangat melelahkan dan tidak efisien:
- Harus memilih file yang diubah satu per satu
- Upload manual setiap kali ada perubahan
- Waktu terbuang untuk proses repetitif
- Resiko human error saat memilih file
- Tidak ada version control seperti di git
- Workflow menjadi terhambat bagi tim yang terbiasa dengan git

Git FTP hadir sebagai jembatan antara kenyamanan git dan keterbatasan akses FTP. Tool ini memungkinkan developer untuk:
- Mendeploy website dengan workflow mirip git
- Otomatisasi proses upload file yang berubah
- Tetap bisa menggunakan version control
- Efisiensi waktu dan tenaga dalam proses deployment

Repository Git FTP dapat diakses di [https://github.com/git-ftp/git-ftp](https://github.com/git-ftp/git-ftp) untuk implementasi solusi ini. Tool ini menjadi jawaban bagi developer yang ingin mempertahankan efisiensi workflow git meski terbatas pada akses FTP.

Pada tutorial ini, kita akan belajar bagaimana cara menggunakan git ftp untuk deploy website sederhana. Dimulai dari proses instalasi git-ftp sampai deploy website. Yuk kita mulai!

## Prasyarat{#prasyarat}
Ada beberapa hal yang perlu diperhatikan sebelum mengikuti tutorial ini.
1. OS yang digunakan pada saat tutorial ini disusun adalah Ubuntu. Jadi karena ada keterbatasan dalam sisi OS, saya belum mencoba di OS lain.
2. Git. Karena git-ftp ini ftp client yang menggunakan git, pastikan git sudah terinstall ya. Jikalau belum, kamu bisa baca [Tutorial install git](https://qadrlabs.com/post/tutorial-github-untuk-pemula-install-dan-menggunakan-github-di-ubuntu) sampai langkah 1 saja.
3. Koneksi Internet. Dari proses instalasi git ftp sampai tahapan deploy, kita akan menggunakan koneksi internet.

## Step 1: Instalasi Git FTP{#step-1}
Langkah pertama adalah menginstall git-ftp. Buka terminal lalu run `command` di bawah ini:
```bash
sudo apt install git-ftp
```

Tunggu sampai proses instalasi git-ftp selesai.

Untuk yang menggunakan OS selain ubuntu, cara instalasinya dapat dibaca di [sini](https://github.com/git-ftp/git-ftp/blob/master/INSTALL.md)

## Step 2: Persiapan project sederhana{#step-2}
Langkah selanjutnya adalah membuat project sederhana. Kita buat direktori project menggunakan `command` 

```bash
mkdir tes-deploy
```

Selanjutnya kita masuk ke direktori project yang baru saja kita buat.
```bash
cd tes-deploy
```

Setelah masuk ke direktori project, kita buat satu file `index.php`.

```bash
echo "<?php echo 'hello world';?>" > index.php
```

Ya, kita akan menggunakan project legendaris `Hello World` untuk percobaan deploy menggunakan git ftp.

Selanjutnya kita init local repositori dan kita commit file yang baru saja kita buat.
```bash
git init

git add .

git commit -m "add index.php"

```

Baik project sederhana kita siap untuk kita deploy.

## Step 3: Deploy menggunakan git-ftp{#step-3}
Untuk mendeploy menggunakan git-ftp, tentu kita perlu akun FTP. Kalau kita menggunakan shared hosting yang memakai cpanel, biasanya akun ftp ini ada di dalam menu `FTP Account`. Sebagai contoh, misalkan kita punya akun ftp dengan detail seperti ini.
```bash

FTP Account:
FTP Username: 			ftp-user
FTP Password :			secr3t
FTP Hostname: 			ftp.example.net
FTP Port (optional): 	21
```
Nah username, password ,hostname dan port ini kita gunakan untuk pengaturan konfigurasi git-ftp. Selain itu kita juga tentukan target direktori untuk deploy, misalnya target direktori kita itu `public_html`.

Selanjutnya kita atur konfigurasi git-ftp, kita sesuaikan dengan ftp akun kita. Buka kembali terminal, lalu kita run `command` ini.

```bash
# Setup
git config git-ftp.url ftp.example.net/public_html
git config git-ftp.user ftp-user
git config git-ftp.password secr3t
```

Ya, konfigurasinya kita sesuaikan dengan akun FTP kita. Untuk `url`, kita arahkan ke target direktori `hostname/target-direktori` yang ada di web kita, yaitu ` ftp.example.net/public_html`. Pada tahapan ini Semua konfigurasi git-ftp sudah selesai.

Sekarang kita coba inisialisasi git-ftp dan deploy project kita untuk pertama kali, buka kembali terminal lalu run `command` ini.
```bash
git ftp init
```

`Command` di atas akan mengupload semua file yang sudah dicommit sebelumnya. Oleh karena itu lama deploynya itu tentu akan bergantung kepada jumlah filenya, semakin banyak filenya akan semakin lama waktu yang diperlukan untuk proses deploy semua filenya.

## Step 4: Update dan deploy{#step-4}
Kawan, selanjutnya kita coba menambahkan file baru di project sederhana kita. Buka terminal lalu run `command` ini.
```bash
echo "<?php echo 'ini file baru';?>" > new.php
```

Selanjutnya kita commit file yang baru saja kita buat.
```bash
git init

git add new.php

git commit -m "add new.php"

```

Setelah perubahan di project kita sudah kita `commit`, kita bisa deploy kembali project kita. Buka kembali terminal lalu run `command` di bawah ini.
```bash
git ftp push
```

Nah setelah kita run `command` di atas, project kita kembali dideploy menggunakan git-ftp. Kita bisa lihat hanya file baru saja yang diupload ke server. Jadi untuk ke depannya, ketika kita akan memperbaharui project kita, kita bisa upload file yang diperbaharui saja menggunakan git ftp. 

Untuk alur proses deploynya, setiap kita akan melakukan deploy, kita tambahkan file yang ditambahkan ataupun yang diperbaharui menggunakan command `git add`, lalu kita commit menggunakan `git commit`, setelah itu kita push  menggunakan `git ftp push`. Rangkaian proses ini akan selalu kita jalankan.

## Fix error{#fix-error}
Beberapa waktu setelah saya mencoba git ftp, ternyata ada error. Error ini tidak terjadi ketika pertama kali saya menggunakan `git-ftp`. Ketika `push` menggunakan command `git ftp push` terdapat error seperti ini.
```
Unknown SHA1 object, make sure you are deploying the right branch and it is up-to-date.
Do you want to ignore and upload all files again? [y/N]: y
fatal: empty string is not a valid pathspec. please use . instead if you meant to match all paths
There are no files to sync.

```

Cara fix error di atas adalah menambahkan pengaturan untuk git ftp. Buka terminal lalu run `command`.
```bash
git config git-ftp.syncroot .
```

## Kesimpulan{#kesimpulan}
Kesimpulannya, Git FTP terbukti menjadi solusi yang tepat untuk mengatasi keterbatasan deployment via FTP konvensional. Tool ini tidak hanya menyelesaikan masalah upload manual yang melelahkan, tetapi juga memungkinkan developer untuk:
- Mempertahankan workflow berbasis git yang sudah familiar
- Mengotomatisasi proses upload file yang diperbarui
- Menghemat waktu dan tenaga dalam proses deployment

Bagi developer yang menghadapi kendala hosting yang hanya menyediakan akses FTP tanpa SSH, Git FTP menjadi jembatan yang efektif antara kebutuhan version control modern dan keterbatasan infrastruktur hosting. Tool ini membuktikan bahwa keterbatasan akses FTP tidak harus mengorbankan efisiensi workflow development yang sudah terbangun.

Dengan demikian, Git FTP tidak hanya sekadar alternatif, tetapi solusi cerdas yang menggabungkan kelebihan git dengan aksesibilitas FTP. Implementasi tool ini bisa menjadi game-changer dalam proses deployment website Anda.

## Referensi{#referensi}
- Repositori git-ftp: https://github.com/git-ftp/git-ftp
- install git-ftp: https://github.com/git-ftp/git-ftp/blob/master/INSTALL.md