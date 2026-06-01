---
title: "Belajar PHP OOP Part 12 Implementasi Class Diagram Dalam PHP"
slug: "belajar-php-oop-part-12-implementasi-class-diagram-dalam-php"
category: "OOP"
date: "2016-08-08"
status: "published"
---

Hallo, Belajar PHP OOP kembali! Kali ini kita akan membahas bagaimana cara menerjemahkan konsep sistem akademik yang sudah kita bahas ke dalam bentuk Class Diagram dan implementasinya dalam PHP.

## Apa itu Class Diagram? {#apa-itu-class-diagram}
Dalam analisis dan desain sistem berorientasi objek, Class Diagram memiliki peran penting dalam memodelkan suatu sistem. Class diagram merupakan bagian dari Unified Modeling Language (UML) yang digunakan untuk menggambarkan struktur sistem berorientasi objek.

Class Diagram sangat berguna untuk mendeskripsikan struktur sistem yang akan kita kembangkan dengan menjabarkan class-class yang ada, seperti atribut, method dan relasi antar objek. Dalam konteks sistem akademik kita, ini sangat membantu untuk memetakan hubungan antara berbagai entitas seperti Mahasiswa, MataKuliah, dan Nilai.

## Learning Overview{#overview}
Pada edisi Belajar PHP OOP kali ini kita akan membuat class diagram sederhana untuk sistem nilai mahasiswa. Kita akan menggunakan contoh class Mahasiswa yang sudah kita pelajari sebelumnya dan mengembangkannya lebih lanjut.

## Step 1 - Membuat Class Diagram Sederhana{#step-1}
Mari kita buat class diagram untuk class `Mahasiswa` dengan properti dan method yang sudah kita pelajari:

```
+------------------------+
|       Mahasiswa       |
+------------------------+
| - nama: string        |
| - nim: string         |
| # nilai: integer      |
+------------------------+
| + getNama(): string   |
| + getNim(): string    |
| + setNilai(n: int)    |
| + getNilai(): integer |
+------------------------+
```

## Step 2 - Implementasi Class Diagram di PHP {#step-2}
Dari class diagram di atas, kita bisa melihat beberapa poin penting:
1. Ada private properti (`nama` dan `nim`)
2. Ada protected properti (`nilai`)
3. Ada beberapa public method (getter dan setter)

Mari kita implementasikan dalam PHP:

```php
<?php
/**
 * Class Mahasiswa memodelkan data dan perilaku mahasiswa
 */
class Mahasiswa {
    private $nama;    // nama mahasiswa
    private $nim;     // nomor induk mahasiswa
    protected $nilai; // nilai mahasiswa

    /**
     * Constructor untuk inisialisasi data mahasiswa
     * @param string $nama: nama mahasiswa
     * @param string $nim: nomor induk mahasiswa
     */
    public function __construct($nama, $nim) {
        $this->nama = $nama;
        $this->nim = $nim;
        $this->nilai = 0;  // nilai default
        echo "Membuat data mahasiswa: " . $this->nama . " (" . $this->nim . ")<br/>";
    }

    public function getNama() {
        return $this->nama;
    }

    public function getNim() {
        return $this->nim;
    }

    public function setNilai($nilai) {
        $this->nilai = $nilai;
    }

    public function getNilai() {
        return $this->nilai;
    }

    public function __toString() {
        return "Mahasiswa[nama=" . $this->nama . 
               ", nim=" . $this->nim . 
               ", nilai=" . $this->nilai . "]";
    }
}
```

Mari kita buat file test untuk mencoba class ini:

```php
<?php
require_once 'Mahasiswa.php';

// Membuat instance mahasiswa
$mhs1 = new Mahasiswa("Budi Santoso", "12345");

// Mencoba method-method yang ada
echo "Nama: " . $mhs1->getNama() . "<br/>";
echo "NIM: " . $mhs1->getNim() . "<br/>";

// Set dan get nilai
$mhs1->setNilai(85);
echo "Nilai: " . $mhs1->getNilai() . "<br/>";

// Menggunakan method toString
echo $mhs1 . "<br/>";

// Membuat mahasiswa baru
$mhs2 = new Mahasiswa("Ana Wijaya", "12346");
$mhs2->setNilai(90);
echo $mhs2 . "<br/>";
?>
```

## Step 3 - Uji Coba{#step-3}
Ketika kode di atas dijalankan, akan menghasilkan output seperti:
```
Membuat data mahasiswa: Budi Santoso (12345)
Nama: Budi Santoso
NIM: 12345
Nilai: 85
Mahasiswa[nama=Budi Santoso, nim=12345, nilai=85]
Membuat data mahasiswa: Ana Wijaya (12346)
Mahasiswa[nama=Ana Wijaya, nim=12346, nilai=90]
```

## Penutup{#penutup}
Class Diagram sangat membantu dalam merancang sistem berorientasi objek. Dengan class diagram, kita bisa lebih mudah memvisualisasikan struktur class dan hubungan antar class sebelum mengimplementasikannya dalam kode. Ini sangat berguna terutama untuk sistem yang kompleks seperti sistem akademik.

Semoga bermanfaat.. Semangat terus ya belajarnya! ^^

***
Stay tuned untuk artikel OOP PHP selanjutnya! ^^