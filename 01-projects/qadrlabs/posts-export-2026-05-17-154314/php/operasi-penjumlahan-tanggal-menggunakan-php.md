---
title: "Operasi Penjumlahan Tanggal Menggunakan PHP"
slug: "operasi-penjumlahan-tanggal-menggunakan-php"
category: "php"
date: "2016-02-19"
status: "published"
---

Operasi penjumlahan pada tanggal ini saya gunakan ketika saya membuat aplikasi perpustakaan yang dibangun menggunakan bahasa pemrograman PHP. Pada aplikasi perpustakaan tersebut mencakup proses peminjaman buku dan pengembalian buku. Pada proses peminjaman buku, untuk meminjam buku di perpustakaan itu kita harus menyerahkan terlebih dahulu kartu anggota perpustakaan dan buku yang akan dipinjam. Setelah itu biasanya pustakawan akan mencatat tanggal pengembalian buku. Umumnya buku dapat kita pinjam selama satu minggu dan pustakawan cukup melihat kalendar untuk  menentukan tanggal pengembalian. Dari alur peminjaman buku inilah muncul pertanyaan, bagaimana caranya menentukan tanggal pengembalian buku menggunakan PHP?

Berdasarkan pertanyaan tersebut, pada postingan kali ini kita akan coba belajar hal yang benar-benar dasar, yaitu belajar membuat program sederhana untuk menentukan tanggal pengembalian buku. Di sini kita tidak langsung coding memakai bahasa pemrograman, tetapi kita  akan belajar bagaimana menuliskan solusinya terlebih dahulu. Setelah kita buat solusinya, baru kita coba implementasikan atau coding dalam bahasa pemrograman PHP.

## Overview{#overview}
Seperti yang sudah disebutkan sebelumnya, sekarang kita akan coba membuat program sederhana untuk menentukan tanggal pengembalian buku menggunakan PHP. Di sini kita coba untuk menuliskan algoritmanya terlebih dahulu. Setelah itu kita implementasikan algoritma untuk menentukan tanggal pengembalian di bahasa pemrograman PHP.

Sebagai contoh untuk studi kasus penjumlahan tanggal, kita akan menghitung tanggal pengembalian buku dengan aturan buku itu harus dikembalikan **satu minggu** dari sekarang. Setelah ketemu tanggal pengembalian, **output** dari program ini adalah menampilkan tanggal pengembalian buku.

## Step 1 - Menuliskan Algoritma untuk menentukan tanggal pengembalian{#step-1}
Pada tahapan ini kita coba jabarkan algoritma untuk menentukan tanggal pengembalian. Kita coba tuliskan dulu sebelum kita implementasikan menggunakan bahasa pemrograman PHP. Misalkan tanggal hari ini adalah 19 Februari 2016, maka algoritma untuk menentukan tanggal pengembaliannya adalah:
```
START

tanggal hari ini <- "19 feb 2016"
tanggal pengembalian <- tanggal hari ini + 7 hari
cetak tanggal pengembalian

END
```
Kurang lebih seperti itu penulisan untuk algoritmanya. Seperti yang terlihat, kita menggunakan operasi penjumlahan pada tanggal untuk menentukan tanggal pengembalian. Nah sekarang kita coba implementasikan menggunakan bahasa pemrograman PHP.

## Step 2 - Implementasi menggunakan PHP{#step-2}
Pertama kita buat file ```penjumlahan_tanggal.php```, lalu ketik sintaks berikut ini:

```php
 <?php  
  $todayDate = "19 feb 2016"; //pendefinisian tanggal awal  
  $returnDate = date('d-m-Y',strtotime('+7 day',strtotime($todayDate))); //operasi penjumlahan tanggal sebanyak 7 hari  
  echo $returnDate; //cetak tanggal pengembalian
  ?>  
```

Pada baris kode di atas, kita coba pakai operasi penjumlahan tanggal dengan menggunakan function ```strtotime()```. Kita tulis jumlah hari pada parameter pertama, di parameter kedua kita isi dengan tanggal hari ini.

Save file ```penjumlahan_tanggal.php```.


## Step 3 - Uji Coba Program{#step-3}
Pada tahapan ini kita akan coba uji program operasi penjumlahan tanggal untuk menentukan tanggal pengembalian buku. Buka browser, lalu kita coba run programnya tersebut di browser. Maka akan muncul tanggal seminggu dari sekarang.

![run program - Operasi Penjumlahan Tanggal Menggunakan PHP](https://3.bp.blogspot.com/-jCtOkf8L0bQ/VsZwxVvmlKI/AAAAAAAAALo/KLCNWU4bPRw/s1600/penjumlahan%2Btanggal.png)

Ya outputnya sesuai dengan spesifikasi program yang sudah kita tuliskan.

Sekarang kita coba bereksperimen.

Kita coba buka lagi file ```penjumlahan_tanggal.php```. Setelah itu kita cek di file PHP yang kita buat, terdapat kode `+7 day`. 

![cek file- Operasi Penjumlahan Tanggal Menggunakan PHP](https://1.bp.blogspot.com/-pjOTB6rdyyE/VsZw47IxPYI/AAAAAAAAALs/L9MB0sAbjmc/s1600/tanda.png)

Sekarang kita coba modifikasi menjadi `+1 week`. 

```php
 <?php  
  $todayDate = "19 feb 2016"; //pendefinisian tanggal awal  
  $returnDate = date('d-m-Y',strtotime('+1 week',strtotime($todayDate))); //operasi penjumlahan tanggal sebanyak 7 hari  
  echo $returnDate; //cetak tanggal  
  ?>  
```

Save kembali file ```penjumlahan_tanggal.php```. Selanjutnya kita coba lagi run di browser. Daaan ternyata hasilnya sama.

![run program - Operasi Penjumlahan Tanggal Menggunakan PHP](https://3.bp.blogspot.com/-jCtOkf8L0bQ/VsZwxVvmlKI/AAAAAAAAALo/KLCNWU4bPRw/s1600/penjumlahan%2Btanggal.png)

Karena pada dasarnya masih sama-sama tujuh hari, jadi output programnya pun sama.
.  .  .

## Penutup{#penutup}
Dalam praktik pemrograman, aplikasi yang berurusan dengan data tanggal seringkali membutuhkan lebih dari sekadar menampilkan tanggal. Terkadang kita perlu melakukan operasi matematika pada tanggal, seperti yang kita lihat pada kasus menentukan tanggal pengembalian buku perpustakaan.

Pada tutorial ini, kita telah mempelajari pendekatan sistematis untuk menyelesaikan masalah tersebut. Alih-alih langsung menulis kode, kita mulai dengan merumuskan algoritma yang jelas, kemudian menerjemahkannya ke dalam bahasa pemrograman PHP. Pendekatan ini sangat membantu terutama ketika menghadapi masalah yang lebih kompleks.

Fungsi strtotime() PHP terbukti sangat berguna untuk operasi tanggal, memungkinkan kita menambahkan interval waktu dengan cara yang mudah dibaca. Kita juga melihat bahwa PHP menyediakan fleksibilitas dalam menentukan interval, baik menggunakan '+7 day' maupun '+1 week' untuk hasil yang sama.

Kemampuan mengelola dan memanipulasi tanggal merupakan keterampilan penting yang akan sering digunakan dalam berbagai jenis aplikasi, dari sistem perpustakaan hingga aplikasi penjadwalan, perencanaan proyek, dan banyak lagi.

Semoga tutorial ini bermanfaat. Selamat mencoba dan mengembangkan aplikasi Anda sendiri!