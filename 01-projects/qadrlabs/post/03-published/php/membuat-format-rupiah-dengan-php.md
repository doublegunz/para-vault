---
title: "Membuat Format Rupiah Dengan PHP"
slug: "membuat-format-rupiah-dengan-php"
category: "php"
date: "2016-02-19"
status: "published"
---

Postingan tentang membuat format rupiah dengan PHP ini terinspirasi ketika mengunjungi toko online. Seringkali saat kita mengunjungi sebuah web e-commerce atau toko online, kita melihat deretan harga di barang yang mereka jual. *ya iyalah namanya juga jualan, pasti ada harganya..* ^^ Nah, apa jadinya kalau harganya itu ga pakai pemisah titik dan koma, misalnya 10000000000 (ini berapa ya? saya asal ketik aja). Pasti ga nyaman ‘kan lihatnya? Apalagi buat mereka – mereka yang alergi matematika.. pasti langsung kabur waktu lihat angka baris – berbaris. Biasanya untuk membuat pengunjung web nyaman, programmer suka ngakalin angka – angka yang hobi baris berbaris ini menggunakan number format atau fungsi format rupiah. 

## Overview{#overview}
Pada tutorial ini kita akan mencoba menampilkan angka untuk harga dengan format rupiah. Untuk menampilkan angka dalam format rupiah, kita akan coba dua cara. Cara pertama menampilkan langsung dan cara kedua kita akan membuat fungsi format rupiah terlebih dahulu, lalu menampilkan outputnya.

Output program sederhana ini akan menampilkan nilai rupiah, sebagai contoh menampilkan text `Rp 9.500.00,00`. Percobaan pertama kita akan menampilkan rupiah tanpa menggunakan fungsi dan percobaan kedua kita buat fungsi untuk menampilkan format rupiah.  *Check this out ya!*

## Percobaan Pertama - Menampilkan format rupiah tanpa fungsi{#percobaan-pertama}
Untuk percobaan yang pertama ini, program sederhana kita itu akan memiliki output yang menampilkan format rupiah tanpa menggunakan fungsi. Pertama kita buat file PHP dengan nama ```formatrupiah.php```, lalu ketik sintaks berikut ini:

```php
 <html>

 <head>
     <title>
         Format Rupiah
     </title>
 </head>

 <body>
     <?php
        //contoh 1 menampilkan 2 angka desimal di belakang nominal uang, pemisah desimal tanda koma  
        //ribuan titik  
        $angka = "9500000";
        $jumlahdesimal = "2";
        $pemisahdesimal = ",";
        $pemisahribuan = ".";
        echo "Rp " . number_format($angka, $jumlahdesimal, $pemisahdesimal, $pemisahribuan);
        ?>
 </body>

 </html>
 ```

Setelah selesai ketik kode di atas, save kembali file ```formatrupiah.php```.

Sekarang kita coba run file ```formatrupiah.php``` di browser. Ketika kita run program ini akan menampilkan output seperti gambar  di bawah ini:

![Run program](https://2.bp.blogspot.com/-gcvX3KAInBw/VsZtTQghRYI/AAAAAAAAALU/5nyQTZJrnbk/s1600/contoh%2B1.png)

Oke, output di browser sudah sesuai dengan spesifikasi program yang dibuat di awal.

Sekarang kita buat contoh yang kedua, untuk menampilkan tanda minus di belakang nominal uang. Tambahkan sintaks berikut ini di bawah sintaks sebelumnya di file  formatrupiah.php :

```php
echo "<br>";
//contoh 2 menampilkan tanda (-) di belakang nominal uang, pemisah desimal tanda koma
//ribuan titik
$angka = "9500000";
$jumlahdesimal = "0";
$pemisahdesimal = ",";
$pemisahribuan = ".";
echo "Rp " . number_format($angka, $jumlahdesimal, $pemisahdesimal, $pemisahribuan) . "-";

```


sehingga keseluruhan file PHP kita menjadi baris kode berikut ini:

 ```php
 <html>

<head>
    <title>
        Format Rupiah
    </title>
</head>

<body>
    <?php
    //contoh 1 menampilkan 2 angka desimal di belakang nominal uang, pemisah desimal tanda koma  
    //ribuan titik  
    $angka = "9500000";
    $jumlahdesimal = "2";
    $pemisahdesimal = ",";
    $pemisahribuan = ".";
    echo "Rp " . number_format($angka, $jumlahdesimal, $pemisahdesimal, $pemisahribuan);
    echo "<br>";
    //contoh 2 menampilkan tanda (-) di belakang nominal uang, pemisah desimal tanda koma  
    //ribuan titik  
    $angka = "9500000";
    $jumlahdesimal = "0";
    $pemisahdesimal = ",";
    $pemisahribuan = ".";
    echo "Rp " . number_format($angka, $jumlahdesimal, $pemisahdesimal, $pemisahribuan) . "-";
    ?>
</body>

</html>
```

simpan kembali file ```formatrupiah.php```, lalu coba run di browser. Maka akan muncul tampilan seperti gambar di bawah ini:

![Run program](https://2.bp.blogspot.com/-1hxopzq4C-Y/VsZtTbhfBcI/AAAAAAAAALc/FTIhAskMkuc/s1600/contoh%2B2.png)

## Percobaan Kedua: Menampilkan format rupiah menggunakan fungsi{#percobaan-kedua}
Di percobaan pertama kita sudah bisa menampilkan output dengan format rupiah. Ada dua contoh yang sudah kita coba. Ada satu pertanyaan, gimana kalau ternyata harga yang ingin ditampilkan di browser itu banyak? Kalau gitu kita bakalan nulis kodenya berulang – ulang dong? Tenang – tenang, supaya lebih efisien, kita bisa buat fungsi untuk format rupiah ini. Jadi nanti kita hanya perlu memanggil fungsinya aja. 

Buka kembali file ```formatrupiah.php```, lalu ketik sintaks berikut ini tepat di bawah tag ```</head>```:

```php
 </head>
 <?php
    function rp($rupiah)
    {
        $jadi = "Rp " . number_format($rupiah, 2, ",", ".");
        return $jadi;
    }
    ?>

 <body>
 ```

Selanjutnya kita coba panggil fungsi rp() itu di bawah sintaks contoh kedua:

```php
echo "<br>";
$harga = "9500000";
echo rp($harga); 
```

Simpan kembali file ```formatrupiah.php```.

Selanjutnya kita coba run file ```formatrupiah.php``` di browser. Maka output yang ditampilkan di browser itu seperti gambar di bawah ini:

![Run program 3](https://1.bp.blogspot.com/-TO1jCyjtdoE/VsZtTT3tlOI/AAAAAAAAALY/HtMJODD_n0o/s1600/contoh%2Bke%2B3.png)

Nah, output programnya sudah sesuai sama kaya output sebelum menggunakan fungsi.

Dan ini keseluruhan kode dari file ```formatrupiah.php``` yang barusan kita buat.
```php
<html>

<head>
    <title>
        Format Rupiah
    </title>
</head>
<?php
function rp($rupiah)
{
    $jadi = "Rp " . number_format($rupiah, 2, ",", ".");
    return $jadi;
}
?>

<body>
    <?php
    //contoh 1 menampilkan 2 angka desimal di belakang nominal uang, pemisah desimal tanda koma  
    //ribuan titik  
    $angka = "9500000";
    $jumlahdesimal = "2";
    $pemisahdesimal = ",";
    $pemisahribuan = ".";
    echo "Rp " . number_format($angka, $jumlahdesimal, $pemisahdesimal, $pemisahribuan);
    echo "<br>";
    //contoh 2 menampilkan tanda (-) di belakang nominal uang, pemisah desimal tanda koma  
    //ribuan titik  
    $angka = "9500000";
    $jumlahdesimal = "0";
    $pemisahdesimal = ",";
    $pemisahribuan = ".";
    echo "Rp " . number_format($angka, $jumlahdesimal, $pemisahdesimal, $pemisahribuan) . "-";
    echo "<br>";
    //menggunakan fungsi  
    $harga = "9500000";
    echo rp($harga);
    ?>
</body>

</html>
``` 


## Penutup{#penutup}
Dalam artikel ini, kita telah mempelajari dua cara efektif untuk menampilkan format rupiah dalam aplikasi PHP. Pertama, dengan menggunakan fungsi `number_format()` secara langsung yang memberikan fleksibilitas untuk menyesuaikan jumlah desimal, pemisah desimal, dan pemisah ribuan. Kedua, dengan membuat fungsi reusable `rp()` yang lebih praktis untuk penggunaan berulang di berbagai bagian aplikasi.

Dengan menerapkan format rupiah yang baik, tampilan harga di website e-commerce atau aplikasi keuangan kita akan lebih profesional dan mudah dibaca oleh pengguna. Hal ini meningkatkan pengalaman pengguna dan mengurangi kemungkinan kesalahpahaman saat membaca nominal uang.

Jangan ragu untuk mengembangkan fungsi ini sesuai kebutuhan aplikasi kita, misalnya dengan menambahkan parameter opsional untuk mengatur jumlah desimal atau menangani nilai negatif.

Semoga artikel ini bermanfaat bagi Anda. Selamat mencoba dan teruslah berkarya!