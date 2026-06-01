---
title: "BELAJAR PHP OOP PART 8 REVIEW OOP"
slug: "belajar-php-oop-part-8-review-oop"
category: "OOP"
date: "2016-04-13"
status: "published"
---

Hai kawan!
Tidak terasa sudah masuk ke part 8 postingan saya edisi Belajar PHP OOP. Nah, Supaya memudahkan buat belajar (lagi), saya buatkan daftar belajarnya, ini dia:

1. Belajar PHP OOP Part 1 Pengenalan OOP 
2. Belajar PHP OOP Part 2 Pengenalan OOP Di Kehidupan Sehari-hari dengan contoh Mahasiswa
3. Belajar PHP OOP Part 3 Membuat Class Mahasiswa Pertamamu
4. Belajar PHP OOP Part 4 Berkenalan Dengan Property Mahasiswa
5. Belajar PHP OOP Part 5 Constructor di Class Mahasiswa
6. Belajar PHP OOP Part 6 Membuat Method untuk Class Mahasiswa
7. Belajar PHP OOP Part 7 Latihan OOP dengan Class MataKuliah


## Perjalanan Belajar PHP OOP Kita {#perjalanan-belajar}
Kawan, makasih sudah ikut belajar di blog saya ini. Dari postingan-postingan sebelumnya, kita sudah belajar basic dari OOP (Object Oriented Programming), yaitu:

* Kamu tahu apa itu class dan sudah bisa buat class Mahasiswa
* Kamu tahu apa itu objek dan cara membuatnya
* Kamu tahu cara buat objek dengan membuat instance dari class Mahasiswa
* Kamu tahu cara nambahin property seperti nama, nim, dan nilai
* Kamu tahu cara nambahin method seperti ikutKuliah() dan setNilai()
* Kamu tahu cara pakai method `__construct()`
* Kamu tahu cara pakai notasi panah (->) untuk akses property dan method

Ternyata sudah lumayan cukup banyak juga ya! ^^

Nah ini ada kode ucapan terima kasih:
```php
<!DOCTYPE html>  
<html>  
    <head>  
        <title>Pengenalan OOP PHP</title>  
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
                        return "Mahasiswa " . $this->nama . " sedang mengikuti kuliah";  
                    }
                    
                    public function setNilai($nilai) {
                        $this->nilai = $nilai;
                        return "Nilai " . $this->nama . " adalah " . $this->nilai;
                    }
                    
                    public function terimakasih() {  
                        return "Terima kasih sudah belajar OOP PHP bersama!";  
                    }  
                }  
                
                $mhs = new Mahasiswa("Budi", "12345");  
                echo $mhs->ikutKuliah();      
                echo "<br/>";  
                echo $mhs->terimakasih();  
            ?>  
        </p>  
    </body>  
</html>  
```

## Selanjutnya {#selanjutnya}
Di postingan selanjutnya, insya Allah kita bakalan bahas lebih dalam tentang OOP dan kamu bakalan belajar konsep yang bagus kaya inheritance dan lainnya. ^^

Semoga dimudahkan untuk mempelajarinya.
Semoga bermanfaat.
Semangat terus ya belajarnya! ^^

***
Stay tuned untuk seri artikel OOP PHP selanjutnya! ^^