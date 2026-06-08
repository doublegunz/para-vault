---
title: "BELAJAR PHP OOP PART 9 INHERITANCE"
slug: "belajar-php-oop-part-9-inheritance"
category: "OOP"
date: "2016-05-05"
status: "published"
---

## Inheritance dalam Konteks Perkuliahan {#inheritance-konteks}
Kalau kita berfikir tentang class dan objek dalam konteks perkuliahan, mungkin kita bisa sadar kalau satu class itu boleh jadi termasuk salah satu tipe dari class lainnya. Sebagai contoh, misalnya ini ya, kita punya class Mahasiswa dan juga class MahasiswaBaru. Bakalan lebih mudah kalau sewaktu kita buat objek baru dari class MahasiswaBaru, secara otomatis punya properti dan method yang sama kaya objek dari class Mahasiswa. Kayanya enak banget ya, ga perlu nulis ulang lagi kalau kodenya sama.

Nah, kabar baiknya, kawan, kita bisa buat kode kita jadi kaya gitu. Gimana caranya? Kita buat melalui proses yang disebut Inheritance. Nah, inheritance ini tuh cara supaya satu class bisa pakai properti dan juga method dari class lain. Kaya sifat anak yang ga jauh beda dari orang tuanya gitu. Contohnya, misalkan MahasiswaBaru itu termasuk Mahasiswa, jadi dia bisa inherit (mewarisi) dari class Mahasiswa. Nah, gimana kalau ada class MahasiswaTransfer. Dia juga bisa inherit dari class Mahasiswa karena sama-sama mahasiswa.

Lalu, gimana caranya satu class PHP bisa mewarisi properti dan method dari class yang lain? Check this code out ya!

## Implementasi Inheritance di PHP {#implementasi-inheritance}

```php
<?php 
    class Mahasiswa { 
        /* Property dasar mahasiswa */ 
        var $nama; 
        var $nim;
        var $nilai;
        
        /* Method dasar mahasiswa */ 
        function getNilai() { 
            echo "Nilai: " . $this->nilai . "<br/>"; 
        } 
        
        function getNama() { 
            echo "Nama: " . $this->nama . "<br/>"; 
        }
        
        /* Constructor Mahasiswa */ 
        function __construct($nama, $nim, $nilai) { 
            $this->nama = $nama; 
            $this->nim = $nim;
            $this->nilai = $nilai;
        } 
    } 
    
    class MahasiswaBaru extends Mahasiswa { 
        var $jalurMasuk;
        
        function setJalurMasuk($jalur) { 
            $this->jalurMasuk = $jalur; 
        } 
        
        function getJalurMasuk() { 
            echo "Jalur Masuk: " . $this->jalurMasuk . "<br/>"; 
        } 
        
        /* Constructor MahasiswaBaru */ 
        function __construct($nama, $nim, $nilai, $jalur) { 
            $this->nama = $nama; 
            $this->nim = $nim;
            $this->nilai = $nilai;
            $this->jalurMasuk = $jalur;
        } 
    } 
    
    /* Buat instance mahasiswa baru */ 
    $mhsBaru = new MahasiswaBaru("Budi", "12345", 85, "SNMPTN"); 
    
    /* Memanggil method yang diwarisi dari class Mahasiswa */ 
    $mhsBaru->getNama(); 
    $mhsBaru->getNilai(); 
    $mhsBaru->getJalurMasuk(); 
?> 
```

Bisa dilihat di kode di atas, ada dua class yaitu class Mahasiswa sama class MahasiswaBaru.

Lho kok yang class MahasiswaBaru agak beda kodenya? Yep, di situ ada keyword extends di class MahasiswaBaru. Yang artinya class MahasiswaBaru itu mewarisi semua properti dan method yang ada pada class Mahasiswa.

Coba kamu perhatiin di kode di atas. Class MahasiswaBaru ga perlu nulis ulang properti $nama, $nim, dan $nilai, tapi dia bisa pakai propertinya. Sama halnya dengan method, di class MahasiswaBaru ga ada method getNilai sama getNama, tapi class MahasiswaBaru bisa pakai methodnya. Kenapa ya? Di kode di atas class Mahasiswa itu jadi Parent Class dan MahasiswaBaru jadi Child Class. Nah, proses ini yang di sebut inheritance. Child class bisa pakai method sama properti yang ada di Parent class.

Gimana? Bisa kebayang kan apa itu inheritance dalam konteks perkuliahan?

Semoga bermanfaat.. semangat terus belajarnya yaaa~! ^^

***
Stay tuned untuk artikel OOP PHP selanjutnya! ^^