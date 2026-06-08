---
title: "Tutorial Setup dan Menggunakan Multiple version PHP di Ubuntu"
slug: "tutorial-setup-dan-menggunakan-multiple-version-php-di-ubuntu"
category: "How To Install"
date: "2022-03-06"
status: "published"
---

Berapa waktu yang lalu PHP versi baru telah rilis, yaitu PHP versi 8.1 dan tidak lama kemudian Laravel juga merilis versi 9 yang support untuk menggunakan PHP 8.1. Karena rilisnya Laravel versi 9 ini, sudah ada banyak yang pertanyaan yang masuk dari kawan-kawan pengunjung apakah seri [belajar laravel 8](https://qadrlabs.com/series/belajar-laravel-8) masih bisa digunakan atau tidak. Untuk menjawab pertanyaan ini saya coba untuk eksplore Laravel 9. Daaan, Laravel 9 pun gagal terinstall. Ya, penyebabnya karena versi PHP yang saya gunakan masih versi lama, sedangkan Laravel versi 9 menggunakan PHP 8. Tadinya saya mau coba menulis tentang Laravel 9, tapi karena perlu persiapan jadi postingan kali ini share tentang pendekatan solusi yang saya gunakan ketika perlu menginstall dan menggunakan PHP dengan versi yang berbeda-beda.

Berhubung ada project yang masih menggunakan PHP versi lama dan penasaran sama yang baru, biasanya saya coba install langsung PHP versi baru di ubuntu yang saya gunakan. Jadi sekarang ada beberapa versi PHP yang terinstall di OS yang saya gunakan. Setiap mau belajar ataupun eksplore pindah ke PHP versi terbaru, terus sewaktu saya mau mulai project, pindah lagi ke PHP versi yang lama. Ya pindah-pindah versi PHP dengan cara mengetikan beberapa command yang sama, berulang-berulang. Dari ini saya kepikiran ide, hei gimana kalau tulis saja script untuk pindah-pindah versi PHP yang mau digunakan. Dan ternyata sudah ada yang nulis scriptnya duluan. Jadi saya coba fork dan gunakan scriptnya, lalu saya tambahkan PHP versi terbaru yang mau saya coba eksplore. 

Nah, ini adalah catatan step step untuk menggunakan scriptnya, dimulai dari persiapan sampai contoh penggunaan script untuk pindah-pindah versi PHP yang dipakai. Yuk kita mulai!

## Persyaratan{#Persyaratan}
Karena script yang saya gunakan untuk ubuntu, tentu teman-teman juga perlu menggunakan Ubuntu (atau keluarganya) untuk mengikuti tutorial ini ya. Dan jangan lupa `apache` juga mesti sudah terinstall. Kita bisa coba cek dulu menggunakan command.

```bash
lsb_release -a | grep Ubuntu && apache2 -v | grep Apache
```

Nanti muncul output, kurang lebih seperti ini.
```bash
$ lsb_release -a | grep Ubuntu && apache2 -v | grep Apache
Distributor ID:	Ubuntu
Description:	Ubuntu 25.04
Server version: Apache/2.4.63 (Ubuntu)

```

## Step 1 - Setup{#step-1}
Pertama kita `clone` terlebih dahulu script nya dari repositori yang sudah saya sediakan sebelumnya.
```
git clone https://github.com/doublegunz/apache-php-switcher.git
```

Lalu setelah itu pindah ke direktori dari repositori yang baru saja kita clone, yaitu `php-switch-scripts`.
```
cd apache-php-switcher
```

Nah, sekarang kita cek isi dari repositorinya menggunakan `command`.
```
ls
```

Kurang lebih outputnya seperti ini.
```
$ ls
assets     switch-to-php-5.6.sh  switch-to-php-7.3.sh  switch-to-php-8.2.sh
LICENSE    switch-to-php-7.0.sh  switch-to-php-7.4.sh  switch-to-php-8.3.sh
README.md  switch-to-php-7.1.sh  switch-to-php-8.0.sh  switch-to-php-8.4.sh
setup.sh   switch-to-php-7.2.sh  switch-to-php-8.1.sh

```

Ada dua script utama di dalam repositori ini, yaitu `setup.sh` untuk proses setup php yang digunakan dan script untuk ganti versi PHP dengan format `switch-to-php-[versi phpnya].sh`.

Selanjutnya kita install PHP yang disupport dan ekstensi PHP yang biasa digunakan dengan cara run `command`:
```
./setup.sh
```

Kita tunggu sampai proses instalasinya selesai. Kalau kita buka di text editor, file `setup.sh` ini isinya command untuk menginstall php dan juga ekstensinya.

Apabila proses instalasi sudah selesai, nanti ada keterangan yang ditampilkan di output terminal:
```
* Setup complete. You may now use the 'switch-to-php-*.*.sh' scripts.
```

## Step 2 - Penggunaan{#step-2}
Setelah semua setup selesai, kita bisa coba gunakan versi PHP berbeda. Seperti yang tertulis di keterangan setelah proses instalasi. Kita tinggal run saja scriptnya. Sebagai contoh, misalnya sebelumnya menggunakan versi lama, kita mau coba pakai PHP versi 8.1. Untuk menggunakan PHP versi 8.1, kita run script yang sesuai dengan versi-nya.
```
./switch-to-php-8.1.sh
```

Nanti tampil output di terminal.
```
* Disabling Apache PHP 5.6 module...
* Disabling Apache PHP 7.0 module...
* Disabling Apache PHP 7.1 module...
* Disabling Apache PHP 7.2 module...
* Disabling Apache PHP 7.3 module...
* Disabling Apache PHP 7.4 module...
* Disabling Apache PHP 8.0 module...
* Enabling Apache PHP 8.1 module...
* Restarting Apache...
* Switching CLI PHP to 8.1...
* Switch to PHP 8.1 complete.
```

Ya, PHP versi 8.1 yang digunakan. 

Apa benar berhasil? Kita bisa cek apakah versi yang digunakan sesuai atau tidak. Buka kembali terminal, lalu run command.
```
php -v | grep PHP
```

Nanti kita bisa lihat output di terminal, kurang lebih seperti ini outputnya.
```
PHP 8.1.33 (cli) (built: Jul  3 2025 16:16:18) (NTS)
Copyright (c) The PHP Group
```

Ya, versi yang digunakan adalah PHP versi 8.1.33. Berarti scriptnya sudah berjalan dengan baik.

Misalkan kita sudah puas nih belajar PHP versi terbaru, terus mau lanjutin projek lagi. Kita mesti pindah versi PHP ke versi yang lama lagi. Sebagai contoh di sini kita mau pindah pakai PHP versi yang 7.4. 
Kita buka lagi terminal, lalu run command.
```
./switch-to-php-7.4.sh
```

Dan output yang ditampilkan.
```
* Disabling Apache PHP 5.6 module...
* Disabling Apache PHP 7.0 module...
* Disabling Apache PHP 7.1 module...
* Disabling Apache PHP 7.2 module...
* Disabling Apache PHP 7.3 module...
* Disabling Apache PHP 8.0 module...
* Disabling Apache PHP 8.1 module...
* Enabling Apache PHP 7.4 module...
* Restarting Apache...
* Switching CLI PHP to 7.4...
* Switch to PHP 7.4 complete.
```

Kita cek lagi, menggunakan command.
```
php -v | grep PHP
```

Outputnya kurang lebih seperti ini.
```
PHP 7.4.33 (cli) (built: Jul  3 2025 16:41:49) ( NTS )
Copyright (c) The PHP Group

```

## Penutup{#penutup}
Pada tutorial ini kita sudah coba install beberapa versi PHP dan kita juga sudah bisa menggunakan PHP dengan versi yang berbeda menggunakan script. Dengan menggunakan script ini, kita tidak perlu mengetikan beberapa comand yang sama secara berulang. Jadi kita tinggal run saja script sesuai dengan versi PHP yang mau digunakan.