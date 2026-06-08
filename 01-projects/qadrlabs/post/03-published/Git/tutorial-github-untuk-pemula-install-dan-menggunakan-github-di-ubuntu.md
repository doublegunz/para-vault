---
title: "Tutorial Git Untuk Pemula: Install dan Menggunakan Git di Ubuntu"
slug: "tutorial-github-untuk-pemula-install-dan-menggunakan-github-di-ubuntu"
category: "Git"
date: "2016-05-11"
status: "published"
---

Semester 6 pada saat saya kuliah adalah kali pertama saya menangani project aplikasi web untuk kampus saya. Setelah proses development selesai, project tersebut berhasil dideploy ke server dan aplikasi mulai digunakan oleh user. Setelah beberapa lama aplikasi digunakan, terdapat permintaan beberapa perubahan fitur baru. Karena ini kali pertama saya menangani project, saya coba backup folder project dan menamai sesuai dengan versi saat itu. Lalu ketika saya berhasil develop fitur baru, saya copy folder project, lalu menimpa file ke file yang ada di server. Demikian seterusnya, sampai ada waktu di mana saya lupa mana file-file terbaru dari aplikasi tersebut. Kendala lain muncul ketika saya berkolaborasi dengan adik tingkat di kampus untuk develop project yang lain. Selain kendala yang pertama terulang, terdapat kendala ketika melakukan proses untuk menyatukan hasil kerja kami. Setelah mengalami beberapa kendala dalam project, saya coba untuk riset dan menyimak beberapa diskusi di forum programmer. Dan solusi dari kendala-kendala tersebut adalah menggunakan tools **git** dan **GitHub**.

Setelah mendapatkan jawaban dari segala pertanyaan terkait kendala-kendala yang saya hadapi, pada tutorial ini saya akan coba install git di Ubuntu. Selain install git, saya juga akan coba menggunakan GitHub. Sebelum memulai, yuk kita bahas terlebih dahulu apa itu Git dan Github.

## Apa itu Git? {#apa-itu-git}

[Git](https://git-scm.com/) adalah sistem kontrol versi yang digunakan untuk melacak perubahan dalam file dan mengkoordinasikan pekerjaan pada project yang dilakukan oleh banyak orang. Git ini dikembangkan oleh Linus Torvalds pada tahun 2005 untuk pengembangan kernel Linux, dan selanjutnya Git menjadi tools yang sangat penting bagi software developer di seluruh dunia. Dengan Git, developer dapat bekerja secara bersamaan pada project yang sama tanpa mengganggu pekerjaan satu sama lain, mengelola versi dari semua file, dan memutar kembali ke versi sebelumnya jika terjadi kesalahan.

### Manfaat Menggunakan Git

Beberapa manfaat utama menggunakan Git adalah:

- **Distribusi Penuh**: Setiap klien Git tidak hanya mengunduh snapshot terbaru dari file proyek, tetapi juga sejarah penuh dari proyek tersebut.
- **Kecepatan dan Efisiensi**: Git sangat cepat dalam melakukan operasi commit, branch, merge, dan lainnya.
- **Penelusuran Sejarah yang Baik**: Git menyediakan sejarah lengkap dari semua perubahan yang dilakukan, siapa yang melakukan perubahan, dan kapan perubahan tersebut dilakukan.
- **Kolaborasi yang Lebih Baik**: Dengan Git, beberapa pengembang dapat bekerja pada cabang (branch) yang berbeda dari proyek yang sama dan kemudian menggabungkan perubahan mereka.



## Apa itu GitHub?{#apa-itu-github}

Pernahkah kamu sewaktu kebingungan mencari ide untuk membuat program, terus kamu googling untuk mencari source code program yang sudah jadi? Pasti pernah dong ya. Terus, biasanya setiap kali kamu download source code itu kamu dialihkan ke halaman GitHub (bukan yang penuh jebakan betmennya lho ya!). Pun misalnya sewaktu mau download Bootstrap ada yang dialihkan ke GitHub. Jadi, **GitHub** itu apa sih? Kok banyak program keren yang bisa kita download di GitHub?

GitHub adalah platform berbasis cloud tempat kita dapat menyimpan, berbagi, dan bekerja sama dengan orang lain untuk menulis kode.

Menyimpan kode kita dalam "repositori" di GitHub memungkinkan kita untuk:

- **Showcase** atau **share** karya kita.
- **Melacak** dan **mengelola** perubahan pada kode kita dari waktu ke waktu.
- Memungkinkan orang lain **mereview** kode kita, dan memberikan saran untuk memperbaikinya.
- **Berkolaborasi** dalam proyek bersama, tanpa khawatir perubahan kita akan memengaruhi pekerjaan kolaborator kita sebelum kita siap mengintegrasikannya.

Kerja kolaboratif, salah satu fitur fundamental GitHub, dimungkinkan oleh perangkat lunak sumber terbuka, [**Git**](#apa-itu-git), yang menjadi dasar pembuatan GitHub.

GitHub ini pun sangat bermanfaat untuk setiap individu yang tertarik untuk membangun maupun mengembangkan sesuatu yang nantinya bisa dijadikan sebagai kontribusi dan diakui oleh komunitas Open Source. Oh iya setiap bulan Oktober, ada [event keren](https://qadrlabs.com/post/hacktoberfest-dimulai-yuk-ikutan-kontribusi) yang bisa kita ikuti lho. 

## Bagaimana cara kerja Git dan GitHub?{#bagaimana-cara-kerja-git-dan-github}

Ketika kita mengunggah file ke GitHub, kita akan menyimpannya di "repositori Git". Ini berarti bahwa ketika kita membuat perubahan (atau "commit") pada file kita di GitHub, Git akan secara otomatis mulai melacak dan mengelola perubahan kita.

Ada banyak action terkait Git yang bisa kita selesaikan di GitHub secara langsung di browser kita, seperti membuat repositori Git, membuat branch, dan mengunggah serta mengedit file.

Namun, kebanyakan orang mengerjakan file mereka secara lokal (di komputer mereka sendiri), kemudian secara terus-menerus menyinkronkan perubahan lokal ini - dan semua data Git yang terkait - dengan repositori "remote di GitHub. 

Setelah kita mulai berkolaborasi dengan orang lain dan semuanya perlu bekerja di repositori yang sama pada waktu yang sama, kita akan terus melakukannya:

- **Pull** semua perubahan terbaru yang dibuat oleh kolaborator kita dari repositori remote di GitHub.
- **Push** kembali perubahan kita sendiri ke repositori remote yang sama di GitHub.

Git mengetahui cara menggabungkan flow perubahan ini secara cerdas, dan GitHub membantu kita mengelola aliran tersebut melalui fitur seperti "pull requests."

.

.

.

Setelah coba menuliskan apa itu git, github dan bagaimana cara kerjanya, apakah teman-teman sudah paham? Belum? Sama... karena baru pertama kali coba.. 

Sekarang yuk kita coba sama-sama belajar git.

## Overview{#overview}

Seperti yang sudah disebutkan sebelumnya, di tutorial kali ini kita akan sama-sama belajar bagaimana **cara menginstall dan menggunakan Git di Ubuntu**. Selain menggunakan git, kita juga akan coba membuat repositori git di github lalu kita coba push repositori local ke repositori git di github.



## Persiapan{#persiapan}

Untuk mengikuti tutorial ini, pastikan sistem teman-teman memenuhi persyaratan berikut:

- **Sistem Operasi**: Ubuntu.
- **RAM**: Minimal 512 MB.
- **Penyimpanan**: Minimal 100 MB ruang disk untuk instalasi Git.

Selain itu, kita perlu akun GitHub terlebih dahulu. Apabila teman-teman belum punya akun github, silakan kunjungi website github, yaitu [https://github.com](https://github.com), lalu buat akun baru dengan menekan button `Sign up` dan ikuti langkah-langkahnya sampai selesai.



## Step 1: Menginstall Git untuk Linux{#step-1}

Sebelum menginstal software baru, sangat penting untuk memastikan bahwa sistem kita up-to-date. Ini membantu menghindari masalah kompatibilitas dan memastikan bahwa kita mendapatkan versi terbaru dari perangkat lunak.

```
sudo apt-get update
sudo apt-get upgrade
```



Selanjutnya untuk menginstall Git untuk Ubuntu, kita hanya perlu run perintah ini di terminal:

```bash
 sudo apt-get install git 
```

Setelah mengetik perintah di atas, yang bisa kita lakukan hanya perlu bersabar menunggu sampai proses instalasi git selesai. :)

Setelah instalasi selesai, kita dapat memverifikasi bahwa Git telah terinstal dengan benar dengan memeriksa versinya:

```
git --version
```

Jika Git telah terinstal dengan benar, Anda akan melihat output yang menunjukkan versi Git yang terinstal.



## Step 2: Atur Konfigurasi Git{#step-2-atur-konfigurasi-git}

Langkah pertama dalam mengkonfigurasi Git adalah mengatur nama pengguna dan email. Informasi ini akan disertakan dalam setiap commit yang Anda buat. Untuk mengatur nama pengguna dan email, kita bisa run command berikut ini.

```bash
git config --global user.name "Nama kamu"
git config --global user.email "email.kamu@domain.com"
```



## Step 3: Membuat Repositori Baru{#step-3-membuat-repositori-baru}

Repositori Git adalah direktori tempat Git menyimpan sejarah lengkap dari semua perubahan pada proyek.

Sekarang kita buat folder baru di sistem kita. Nantinya folder ini bakalan kita gunakan sebagal local repository yang nantinya kita push ke repositor remote di GitHub. Untuk membuat repositori baru, kita ketik perintah ini di terminal:

```bash
 git init latihanku 
```

Kalau repository-nya berhasil dibuat, tampil notifikasi di output terminal.

```
 Initialized empty Git repository in /home/namauser/latihanku/.git/ 
```

Folder `latihanku` itu adalah folder yang dibuat secara bersamaan dengan inisialiasi repositori git dengan menggunakan perintah `git init`. Nah, sekarang kita pindah direktori ke folder yang baru kita buat. Run perintah berikut ini di terminal:

```bash
 cd latihanku 
```

## Step 4: Membuat file README untuk deskripsi repository{#step-4-mebuat-file-readme}

Selanjutnya di dalam folder `latihanku`, kita buat file `README` dan tulis teks, misalnya "ini adalah sebuah git repository". Fungsi file README ini biasanya digunakan untuk mendeskripsikan repositori yang kita buat ini isinya apa sih atau project apa sih yang kita buat. Untuk membuat file `README`, kita run perintah ini di terminal:

```bash
 nano README 
```

Sebagai catatan kamu bisa pakai teks editor yang lain. Di sini saya coba pakai nano. Nah, untuk isi file `README`, kita ketik text berikut ini sebagai contoh:

```bash
 ini adalah sebuah git repository 
```

Kalau sudah diketik, kita simpan kembali file `README` nya dengan menekan `ctrl+o`, lalu kita tekan `enter` setelah tampil keterangan `File Name to Write: README`. Selanjutnya kita tekan `ctrl+x` untuk keluar dari nano.

## Step 5: Add file baru ke repositori{#step-5-add-file-baru-ke-repositori}

Langkah ini adalah langkah yang penting dan merupakan salah satu alur penggunaan git. Di sini kita akan coba menambahkan atau `add` file apa aja yang nantinya kita `push` ke repositori remote. Yang kita tambah itu bisa text file atau pun program yang boleh jadi kita tambahkan untuk pertama kalinya ke dalam repositori, atau boleh jadi kita tambahkan file yang sudah ada dengan beberapa perubahan (atau sudah diedit).

Di langkah sebelumnya kita sudah punya file README. Selanjutnya kita akan coba untuk membuat file lainnya, misalnya kita buat file legendaris PHP yaitu `hello.php`. Sekarang kita ketik perintah ini di terminal:

```bash
 nano hello.php 
```

Apa isi filenya? Iya, kamu benar.. ^^ berikut adalah isi file `hello.php`:

```php
<?php 
echo "hello world!"; 
?> 
```

Setelah selesai, kita save filenya dengan menekan `ctrl+o`, lalu kita tekan `enter` setelah tampil keterangan `File Name to Write: hello.php`. ^^

Jadi sekarang kita sudah punya dua file yaitu file `README` dan `hello.php`. Sekarang kita add ke dalam staging area git dengan run dua perintah ini di terminal:

```bash
 git add README 

 git add hello.php 
```

Sebagai catatan, `git add` itu perintah yang digunakan untuk add file dan folder ke dalam staging area. 

## Step 6: Commiting perubahan yang sudah dilakukan ke staging area{#step-6-commit}

Setelah menambahkan file ke staging area, kita bisa menyimpan perubahan dengan membuat commit. Commit adalah snapshot dari semua perubahan yang ada di staging area. Nah, untuk commit kita gunakan perintah berikut ini di terminal:

```bash
 git commit -m "commit-ku yang pertama" 
```

Pesan `commit-ku yang pertama` itu bisa kamu ganti sesuka kamu lho! Itu cuma contoh aja. 

Untuk melihat status dari repositori kita, termasuk file yang telah diubah, ditambahkan ke staging area, atau belum di-tracked oleh Git, gunakan perintah berikut:

```
git status
```



## Step 7: Membuat repositori remote di GitHub{#step-7-membuat-repositori-di-github}

Sekarang kita akan coba push perubahan dari repositori lokal ke remote repository. Untuk itu kita perlu membuat repositori baru di GitHub. Sebelumnya kita mesti login ke akun kita terlebih dahulu di https://github.com. Kemudian klik simbol "tambah (+)" yang ada di ujung kanan atas kaya gambar di bawah:

![login ke github](https://3.bp.blogspot.com/-XKcKYhV4U2g/VzNKBMjBq9I/AAAAAAAAAYI/-aCvCqjypsgBORjzV8vNGPykcNMepwIJACLcB/w640-h282/git2.png)

Selanjutnya kita akan masuk ke halaman `Create a new repository` . Isi Repository name dengan value `latihanku`, dan klik tombol `create repository` untuk melanjutkan.

![Buat repositori baru](https://1.bp.blogspot.com/-WD1WQ4Sm_fg/VzNKFbgoReI/AAAAAAAAAYM/aHGpL8slowIKsJzUMIBFSBvK7AHFm8q9QCLcB/w640-h330/git3.png)

Setelah repositori git berhasil kita buat, kita bisa push konten dari repositori local ke repositori remote di GitHub. Sekarang kita hubungkan dulu repository di GitHub pakai perintah ini di terminal.

```
git remote add origin https://github.com/username/nama-repo.git
```



**CATATAN PENTING**: Pastikan kita ganti `username` jadi username teman-teman dan sama nama repositori git di GitHub sebelum perintahnya di enter!

Contohnya di bawah ini pakai `username` saya:

```bash
 git remote add origin https://github.com/doublegunz/latihanku.git 
```

## Step 8: Push konten dari repositori local ke repositori remote di Github{#step-8-push-konten-ke-repositori-remote}

*Finally*, kita masuk ke step terakhir. Di sini kita akan push konten dari repositori local kita (folder `latihanku` yang kita buat) ke repositori remote (repositori `latihanku` yang ada di GitHub). Untuk push konten, kita ketik perintah ini di terminal.

```bash
 git push origin master 
```

lalu, masukkan login credential (username kamu sama password kamu).

**Catatan:** Di pengaturan github yang terbaru, kita tidak bisa menggunakan password untuk push repositori. Sebagai gantinya, kita harus gunakan personal access token. Untuk membuat personal access token, silakan akses halaman [personal access token](https://github.com/settings/personal-access-tokens), lalu tekan tombol [**Generate token**](https://github.com/settings/personal-access-tokens/new) untuk generate token baru.

Selesai. ^^

Gambar di bawah ini, perintah yang kita ketik di terminal dari step 4 ke step 8.
![Step 4 sampai step 8](https://1.bp.blogspot.com/-bfPqA5ykdtg/VzNKKdyKLII/AAAAAAAAAYQ/X_-0D1XPq8sFaX056KfMUcFaQN2lezAogCLcB/w640-h350/git4.png)

Seperti itulah cara add konten dari folder `latihanku` (local repository) ke repositori remote di GitHub. Misalkan nantinya kita mau buat project baru atau buat repository, kamu bisa mulai langsung dari step 3. 



## Penutup{#penutup}

Demikian tutorial instalasi Git di ubuntu dan cara menggunakan git dan juga Github. Pada tutorial ini kita masih belajar hal dasar penggunaan git, yang di kemudian hari menjadi solusi untuk kendala-kendala yang dapat dihadapi ketika kita mengembangkan software. 



## Selanjutnya...

Untuk melatih kita dalam mempelajari git, selanjutnya teman-teman dapat mencoba [Belajar Kontribusi di Project Open Source](https://qadrlabs.com/post/belajar-kontribusi-di-project-open-source) atau bahkan dapat mengikuti [event hacktoberfest](https://qadrlabs.com/post/hacktoberfest-dimulai-yuk-ikutan-kontribusi).



***

Link Referensi: 

- [Dokumentasi Github](https://docs.github.com/en/free-pro-team@latest/github/getting-started-with-github)
- [Instalasi Git](https://git-scm.com/download/linux)