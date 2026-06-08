---
title: "Tutorial instalasi Apache Web server dan PHP di HP android menggunakan Termux"
slug: "tutorial-instalasi-apache-web-server-dan-php-di-hp-android-menggunakan-termux"
category: "How To Install"
date: "2020-12-18"
status: "published"
---

**Tutorial instalasi Apache Web server dan PHP di HP android menggunakan termux** ini adalah salah satu solusi yang saya gunakan ketika berbagi ilmu seputar programming di kampus tempat saya belajar. Salah satu kendala belajar web programming yang sering kali dihadapi ketika saya berbagi ilmu itu adalah tidak semua peserta memiliki laptop ataupun komputer. Pada kondisi normal, mungkin ada beberapa opsi yang bisa digunakan. Salah satu solusinya itu adalah menggunakan komputer yang ada di lab kampus saya. Karena sekarang itu kita sedang menghadapi pandemi, solusi tersebut tidak bisa lagi digunakan. 

Teringat dua tahun lalu, sekitar tahun 2018, salah seorang kawan komunitas saya di PHPID itu sedang eksplorasi aplikasi Termux dan saya juga sempat install aplikasi tersebut. Dan sempat juga *ngulik* buat program sederhana menggunakan bahasa PHP di termux. Nah setelah ngobrol sama teman-teman yang ikut belajar, hampir semuanya mempunyai HP android. Akhirnya solusi yang saya bisa tawarkan itu adalah memanfaatkan fasilitas yang ada untuk belajar dan berkarya. Tidak mudah memang. Tapi setidaknya masih bisa belajar. Dan setelah semuanya sepakat, mulailah proses instalasi  Apache Web server dan PHP di hp android masing-masing dengan memanfaatkan aplikasi termux ini.

## Prasyarat{#prasyarat}
Untuk mengikuti tutorial instalasi PHP dan Apache Webs server di HP android menggunakan Termux ini, pastikan koneksi internetmu stabil dan ada kuota sekitar 170MB. Dan tentu saja tutorial ini hanya bisa digunakan di hp Android. (*Note: belum sempat coba di hp dengan os yang beda*)

## Step 1 - Install Termux{#step-1}
Karena proses instalasi apache2 dan php itu melalui Termux, tentu hal pertama yang harus kita lakukan adalah menginstall Termux itu sendiri. Untuk menginstall Termux, kita bisa download terlebih dahulu di [web f-droid](https://f-droid.org/en/packages/com.termux/). Kita tidak perlu download dulu aplikasi f-droid, kita bisa langsung download dengan menekan link `Download APK` di masing-masing versi atau bisa klik [ini](https://f-droid.org/repo/com.termux_117.apk) untuk download Version 0.117 (117) . Nah  [Termux](https://github.com/termux/termux-app) karya Om Fredrik Fornwall ini yang akan kita install. Selanjutnya langsung klik apk yang sudah kita download. Apabila ada notifikasi, izinkan instalasi dari source yang berbeda, lalu tunggu sampai proses instalasi selesai.

**Note:** Termux dan pluginnya yang ada di playstore sudah deprecated dan tidak diupdate lagi. Tidak direkomendasikan lagi untuk menginstall dari play store (berdasar statement di repositori resmi termux). Dan sebagai catatan, download dari web F-Droid ini berdasarkan keterangan dari repositori resmi termux juga.

## Step 2 - Install PHP dan Apache{#step-2}
Setelah Termux selesai kita install, selanjutnya buka aplikasi termux. Kita bisa melihat tampilan yang mirip terminal di linux ketika Termux dibuka. 

Langkah selanjutnya adalah instalasi PHP dan Apache2. Untuk instalasi php dan apache2. Ketik command ini:

```bash
pkg install git -y && 
cd ~/ && 
git clone https://github.com/gungunpriatna/termux-php-apache2-setup.git && 
cd ~/termux-php-apache2-setup && 
bash setup && 
cd ~/ && 
rm -rf termux-php-apache2-setup
```

**Keterangan:** baris `command` di atas itu terdiri dari beberapa proses, di mulai dari instalasi `git`, download setup menggunakan `git clone`, bash setup untuk instalasi php, apache2, pengaturan apache2 untuk php 7, dan membuat direktori htdocs, lalu menghapus direktori termux-php-apache2-setup yang sudah didownload sebelumnya.

Selanjutnya tekan enter untuk run command di atas. Pada tahapan ini proses instalasi sudah dimulai. Biasanya ada pertanyaan untuk menginstall packages yang diperlukan, seperti ini:
```bash
Do you want to continue? [Y/n]
```
Ketik Y, lalu enter. Tunggu sampai proses instalasi selesai. Kurang lebih sekitar 162MB, kuota yang diperlukan untuk proses instalasi.

Nah setelah proses instalasi selesai, nanti tampil keterangan seperti di bawah ini.
```bash
 PHP and Apache2 Installed Sucessfully...
 /sdcard/htdocs - is your document directory..
 Place your files in /sdcard/htdocs
 Run apachectl
 ```

## Step 3 - Test Instalasi{#step-3}
Selanjutnya kita uji apakah proses instalasinya berhasil. Pertama kita cek versi php.
```bash
php -v
```
Setelah run command di atas, versi PHP akan ditampilkan di Termux.

![cek versi php](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-php-apache/image-1-cek-php-version.jpg)

Seperti yang tampak pada gambar di atas, PHP yang terinstall adalah versi 8.3.10 (versi php pada saat uji coba pada tanggal 1 Desember 2024).

Selanjutnya kita uji coba apakah apakah PHP bisa  dirunning. Document root website secara default ada di ```sdcard/htdocs``` (kamu bisa cek di internal storage hp kamu, ada folder baru dengan nama ```htdocs```). Selanjutnya kita buat dulu file baru dengan nama index.php di folder htdocs. Ketik command ini di termux, lalu enter ya:
```bash
echo "<?php phpinfo();?>" > storage/shared/htdocs/index.php
```

![buat file index.php](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-php-apache/image-2-create-index-php-file.jpg)

Nah kamu bisa lihat file baru di folder htdocs. File ini nantinya akan menampilkan detail tentang instalasi PHP, seperti versi PHP dan juga lainnya.

Selanjutnya kita start Apache web server. Ketik command ini di termux, lalu enter untuk eksekusi command-nya:
```bash
apachectl
```

Setelah command dieksekusi, secara otomatis hp akan membuka browser dengan url ```http://locahost:8080``` dan memanggil file index.php yang sebelumnya sudah dibuat.

![tes running server](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-php-apache/image-3-test-run-di-browser.jpg)

Bisa kita lihat output yang ditampilkan di browser, PHP berhasil dirunning dan versi php yang terinstall adalah PHP versi 8.3.10 (versi php pada saat diuji coba pada tanggal 1 Desember 2024). Ini tandanya proses instalasinya berhasil.

## Penutup{#penutup}
Akhirnya proses instalasi Apache Web server dan PHP di HP android selesai, berbagi ilmu pun bisa kembali dilanjutkan. Memang benar kata uda Ricky Elson, yang paling penting itu adalah memberikan kesempatan kepada mereka. Memberikan kemerdekaan untuk berkarya pada mereka. Sehingga mereka tak lagi membaca apa yang tak ada. Tak lagi mempermasalahkan Fasilitas. Tapi percaya dengan peralatan yang terbatas sekalipun, Tak membatasi tekad mereka berkarya. Muka yang tadinya tampak redup pun, kembali cerah.