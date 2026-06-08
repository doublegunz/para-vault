---
title: "BELAJAR PHP OOP PART 6 MEMBUAT METHOD"
slug: "belajar-php-oop-part-6-membuat-method"
category: "OOP"
date: "2016-04-11"
status: "published"
---

## Apa Itu Method? {#apa-itu-method}
Ya, akhirnya bagian tentang property dan constructor sudah kita bahas. Nah sekarang kita masuk ke bagian pembahasan tentang method. Seperti yang sudah kita lihat sekilas di artikel sebelumnya, method adalah function yang dikumpulkan ke dalam sebuah class. Dan cara buat method itu pakai penulisan sintaks kaya di bawah:

```php
public function namaFunction($parameterOpsional) {  
    // tulis code di sini  
}  
```

Dan sekarang kita tahu kalau fungsi `__construct` itu berbeda. Dia dipanggil saat kita buat objek baru, kaya yang kita bahas di postingan sebelumnya. Selain itu, kita juga sudah belajar tentang keyword `$this`. Kita pakai `$this` kalau kita mau mengakses property yang ada di dalam class. Jadi kalau kita ingin method kita me-return sebuah pernyataan yang mengandung property nama, kita mesti pakai `$this->nama`.

Nah kawan, manggil method juga sama kaya kita mau akses property lho! Kamu cukup panggil:
```php
$nama_objek->namaMethod();  
```

## Praktik: Tambahkan Method ke Class Mahasiswa {#praktik-method}
Sekarang kita coba lanjutin class Mahasiswa yang kita buat di postingan sebelumnya!
Try this out ya!

Pertama, kita tambahin dua method: method `ikutKuliah()` dan `setNilai()` ke dalam class kita. Method `ikutKuliah()` akan return informasi bahwa mahasiswa sedang kuliah, dan method `setNilai()` untuk mengubah nilai mahasiswa.

Nah, berikut ini kodenya:
```php
<!DOCTYPE html>  
<html>  
    <head>  
        <title>Membuat Class Mahasiswa</title>  
        <style>  
            p {  
                color: grey;  
                font-size: 20px;  
            }  
        </style>  
    </head>  
    <body>  
        <p>  
            <?php  
                class Mahasiswa {  
                    public $statusAktif = true;  
                    public $nama;  
                    public $nim;  
                    public $nilai;  
                    
                    public function __construct($nama, $nim) {  
                        $this->nama = $nama;  
                        $this->nim = $nim;  
                        $this->nilai = 0;  
                    }  
                    
                    public function ikutKuliah() {  
                        return "Mahasiswa " . $this->nama . " sedang mengikuti kuliah<br/>";  
                    }
                    
                    public function setNilai($nilai) {  
                        $this->nilai = $nilai;
                        return "Nilai " . $this->nama . " adalah " . $this->nilai . "<br/>";  
                    }  
                }  
                
                $mhs1 = new Mahasiswa("Budi", "12345");  
                $mhs2 = new Mahasiswa("Ana", "12346");  
                
                echo $mhs1->ikutKuliah();  
                echo $mhs1->setNilai(85);  
                echo $mhs2->ikutKuliah();  
                echo $mhs2->setNilai(90);  
            ?>  
        </p>  
    </body>  
</html>  
```

Simpan filenya, lalu coba kamu run di browser kesayangan kamu. :)
Nah, sekarang kita sudah punya class Mahasiswa yang lengkap dengan property dan method-nya!

Selamat! Kamu sudah berhasil membuat class dengan property dan method! :D
Semoga bermanfaat... Semangat terus ya belajarnya! :D

***
Stay tuned untuk artikel selanjutnya dimana kita akan belajar konsep OOP lainnya! ^^