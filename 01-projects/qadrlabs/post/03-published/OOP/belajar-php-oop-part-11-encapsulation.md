---
title: "BELAJAR PHP OOP PART 11 ENCAPSULATION"
slug: "belajar-php-oop-part-11-encapsulation"
category: "OOP"
date: "2016-05-07"
status: "published"
---

Saya akan menyesuaikan artikel tersebut untuk melanjutkan konsep perkuliahan yang telah dibahas sebelumnya, dengan tetap mempertahankan gaya penulisan dan mengubah konteksnya ke sistem akademik perkuliahan.

---

Terkadang, di dalam sistem akademik, tidak semua informasi mahasiswa bisa diakses oleh semua orang. Misalnya nilai mahasiswa yang hanya bisa diakses oleh dosen dan mahasiswa yang bersangkutan, atau data pribadi mahasiswa yang perlu dijaga kerahasiaannya.

Sama halnya dalam OOP, kita bisa mengatur siapa saja yang bisa mengakses method ataupun properti yang ada di dalam class. Apakah bisa diakses oleh siapapun? Apakah hanya bisa diakses di dalam class saja? Atau hanya bisa diakses di dalam class dan class turunannya saja? Kawan, inilah yang disebut dengan Encapsulation.

## Apa itu Encapsulation? {#apa-itu-encapsulation}
Encapsulation adalah istilah yang terkait dengan aksesbilitas properti dan method dalam suatu class. Di dalam encapsulation ini terbagi menjadi 3 Access Modifier, yaitu:
1. Public : Properti atau method bisa diakses di mana saja, seperti NIM mahasiswa yang bisa dilihat oleh siapa saja
2. Private : Properti atau method hanya bisa diakses di dalam class saja, seperti password mahasiswa
3. Protected : Properti atau method hanya bisa diakses di dalam class dan class turunannya saja, seperti nilai mahasiswa

Belum paham? Mari kita lihat contoh kodenya:

```php
<?php
class Mahasiswa {
    public $nim;           // Bisa diakses siapa saja
    private $password;     // Hanya bisa diakses dalam class
    protected $nilai;      // Bisa diakses class turunan juga

    public function __construct($nim, $password, $nilai) {
        $this->nim = $nim;
        $this->password = $password;
        $this->nilai = $nilai;
    }

    private function cekPassword() {
        return password_verify($this->password, 'hash_password');
    }
    
    public function getNilai() {
        if ($this->cekPassword()) {
            return $this->nilai;
        }
        return "Akses ditolak";
    }
}

$mahasiswa = new Mahasiswa("12345", "rahasia123", 85);
echo "NIM: " . $mahasiswa->nim . "<br/>";            // Bisa diakses
echo "Password: " . $mahasiswa->password . "<br/>";   // Error! Tidak bisa diakses
echo "Nilai: " . $mahasiswa->nilai . "<br/>";        // Error! Tidak bisa diakses
```

## Solusi dengan Access Modifier {#solusi-access-modifier}
Jika kode di atas dijalankan, akan muncul error karena mencoba mengakses properti private dan protected secara langsung. Bagaimana cara mengaksesnya? Mari kita perbaiki kodenya:

```php
<?php
class Mahasiswa {
    public $nim;
    private $password;
    protected $nilai;

    public function __construct($nim, $password, $nilai) {
        $this->nim = $nim;
        $this->password = $password;
        $this->nilai = $nilai;
    }

    private function cekPassword() {
        return true; // Simulasi pengecekan password
    }

    public function getNilai() {
        if ($this->cekPassword()) {
            return $this->nilai;
        }
        return "Akses ditolak";
    }
}

class MahasiswaInternasional extends Mahasiswa {
    public function getNilaiKonversi() {
        // Bisa mengakses $nilai karena protected
        return $this->nilai * 4 / 100; // Konversi ke sistem GPA
    }
}

$mhs = new Mahasiswa("12345", "rahasia123", 85);
echo "NIM: " . $mhs->nim . "<br/>";
echo "Nilai: " . $mhs->getNilai() . "<br/>";

$mhsInternasional = new MahasiswaInternasional("12346", "rahasia123", 85);
echo "Nilai GPA: " . $mhsInternasional->getNilaiKonversi() . "<br/>";
```

Sekarang kode sudah berjalan dengan baik! Property password tetap aman karena private, nilai bisa diakses melalui method public, dan MahasiswaInternasional bisa mengakses nilai untuk dikonversi karena properti nilai bersifat protected.

Semoga bermanfaat.. Semangat terus belajarnya yaa~! ^^

***
Stay tuned untuk artikel OOP PHP selanjutnya! ^^