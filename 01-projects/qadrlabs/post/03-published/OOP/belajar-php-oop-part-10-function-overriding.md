---
title: "BELAJAR PHP OOP PART 10 FUNCTION OVERRIDING"
slug: "belajar-php-oop-part-10-function-overriding"
category: "OOP"
date: "2016-05-06"
status: "published"
---

Seringkali disebutkan, setiap mahasiswa itu unik. Meski sama-sama mahasiswa, mereka memiliki karakteristik tersendiri. Biarpun melakukan kegiatan yang sama seperti kuliah, akan tetapi mereka punya cara sendiri dalam menjalaninya. Misalnya dalam belajar, tiap mahasiswa memiliki cara belajarnya masing-masing. Ada yang belajar di perpustakaan, ada yang belajar di kafe, dan berbagai preferensi lainnya.

## Apa Itu Function Overriding? {#apa-itu-overriding}
Begitu pula dengan class di dalam OOP. Kadang kita ingin sebuah child class (atau subclass) punya properti atau pun method yang namanya sama dengan parent classnya, tapi implementasinya berbeda. Misalnya kita punya parent class Mahasiswa, punya method `getNilai()`. Nah, kemudian kita pengen buat child class MahasiswaInternasional yang mewarisi (inherit) dari class Mahasiswa, tapi dengan method `getNilai()` yang berbeda karena sistem penilaiannya berbeda. Kalau kita tulis, kodenya kaya di bawah:

```php
class Mahasiswa { 
    function getNilai() {
        return $this->nilai;
    }
} 

class MahasiswaInternasional extends Mahasiswa { 
    function getNilai() {
        return $this->konversiNilaiInternasional($this->nilai);
    }
}
```

## Implementasi Lengkap di PHP {#implementasi-lengkap}
Nah sebagai contoh yang lebih lengkap, check this code out ya!

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
    
    class MahasiswaInternasional extends Mahasiswa { 
        var $asalNegara;
        
        /* Override method getNilai untuk konversi nilai */ 
        function getNilai() { 
            $nilaiHuruf = '';
            if ($this->nilai >= 85) $nilaiHuruf = 'A';
            else if ($this->nilai >= 70) $nilaiHuruf = 'B';
            else if ($this->nilai >= 55) $nilaiHuruf = 'C';
            else $nilaiHuruf = 'D';
            
            echo "Grade: " . $nilaiHuruf . "<br/>"; 
        }
        
        function getAsalNegara() { 
            echo "Asal: " . $this->asalNegara . "<br/>"; 
        }
        
        /* Constructor MahasiswaInternasional */ 
        function __construct($nama, $nim, $nilai, $asalNegara) { 
            $this->nama = $nama; 
            $this->nim = $nim;
            $this->nilai = $nilai;
            $this->asalNegara = $asalNegara;
        } 
    } 
    
    /* Buat instance mahasiswa internasional */ 
    $mhsInternasional = new MahasiswaInternasional("John", "12345", 85, "USA"); 
    
    /* Memanggil method */ 
    $mhsInternasional->getNama(); 
    $mhsInternasional->getNilai();  // Menggunakan versi yang sudah di-override
    $mhsInternasional->getAsalNegara(); 
?> 
```

Kalau kamu coba run di browser, hasilnya bakalan kaya gini:
```
Nama: John
Grade: A
Asal: USA
```

Nah, kalau kita perhatiin hasil kode di atas, method `getNilai()` pada class Mahasiswa ketimpa sama method `getNilai()` yang ada di class MahasiswaInternasional. Method di child class mengimplementasikan cara yang berbeda untuk menampilkan nilai, yaitu dalam bentuk huruf alih-alih angka. Ini yang disebut dengan Function Overriding.

Karena itulah seringkali disebutkan, setiap mahasiswa itu unik. Meski sama-sama mahasiswa, mereka punya karakteristik dan cara tersendiri dalam menjalani perkuliahan.

Semoga bermanfaat! ^^

***
Stay tuned untuk artikel OOP PHP selanjutnya! ^^