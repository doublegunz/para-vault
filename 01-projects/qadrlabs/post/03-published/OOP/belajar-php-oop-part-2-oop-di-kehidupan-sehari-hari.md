---
title: "Belajar PHP OOP Part 2 OOP Di Kehidupan Sehari Hari"
slug: "belajar-php-oop-part-2-oop-di-kehidupan-sehari-hari"
category: "OOP"
date: "2016-04-07"
status: "published"
---

## OOP dalam Kehidupan Perkuliahan {#oop-kehidupan}
Kawan, pemrograman berorientasi objek itu sangat erat kaitannya dengan kehidupan kita sehari - hari. Misalnya di kehidupan perkuliahan, setiap mahasiswa (`object`) memiliki hak yang sama. Dia bisa masuk dan mengikuti kegiatan perkuliahan (`method`), yang nantinya dia mendapatkan hasil berupa nilai (`property`). Dan mahasiswa juga memiliki data mahasiswa masing - masing, sehingga tidak akan ada data mahasiswa yang tertukar. Nama dan NIM misalnya (contoh `property` lainnya).

## Mahasiswa sebagai Object {#mahasiswa-sebagai-object}
Setiap mahasiswa memiliki data mahasiswa. Misalnya saat daftar menjadi mahasiswa baru, secara tidak langsung kamu akan terdaftar sebagai mahasiswa baru (`New instance` dari class `Mahasiswa`). Dan pada saat mendaftar, kamu akan mengisi data diri kamu, misalnya nama lengkap, jenis kelamin dan lain sebagainya. Nama dan jenis kelamin inilah yang di sebut `property`. Lalu kalau kamu sudah terdaftar, barulah kamu bisa mengikuti perkuliahan (`method`).

## Implementasi dalam PHP {#implementasi-php}
Di bawah ini adalah contohnya, ada class `Mahasiswa`, dan di setiap objek `Mahasiswa` yang baru nantinya punya beberapa property, seperti `$nama`, `$nim`, `$nilai` dan juga method `ikutKuliah()` dan `setNilai()`.
  
```php
<?php
// Membuat class Mahasiswa
class Mahasiswa {
    // Properties (data mahasiswa)
    public $nama;
    public $nim;
    public $nilai;
    // Constructor (untuk mengisi data saat mendaftar)
    public function __construct($nama, $nim) {
        $this->nama = $nama;
        $this->nim = $nim;
        $this->nilai = 0; // nilai awal
    }
    // Method (kegiatan yang bisa dilakukan)
    public function ikutKuliah() {
        return "Mahasiswa " . $this->nama . " sedang mengikuti kuliah";
    }
    public function setNilai($nilai) {
        $this->nilai = $nilai;
        return "Nilai " . $this->nama . " adalah " . $this->nilai;
    }
}
// Membuat mahasiswa baru (membuat object/instance)
$mahasiswa1 = new Mahasiswa("Budi", "12345");
// Menggunakan method
echo $mahasiswa1->ikutKuliah();
echo "<br>";
echo $mahasiswa1->setNilai(85);
// Membuat mahasiswa baru lainnya
$mahasiswa2 = new Mahasiswa("Ana", "12346");
echo "<br>";
echo $mahasiswa2->ikutKuliah();
echo "<br>";
echo $mahasiswa2->setNilai(90);
?>
```
 
 ## Dua Instance, Satu Class {#dua-instance}
Nah, kawan untuk sekarang sudah ada dua instance dari class `Mahasiswa`, yaitu object `$mahasiswa1` dan `$mahasiswa2`. Dari contoh di atas kita bisa lihat bahwa setiap mahasiswa memiliki data sendiri dan bisa melakukan kegiatan perkuliahan. Kamu juga bisa membuat instance baru lainnya dengan namamu sendiri!

Semoga Bermanfaat! ^^
***
Di postingan berikutnya kita akan coba buat beberapa class lainnya. ^^