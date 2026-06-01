---
title: "BELAJAR PHP OOP PART 7 MERANGKAI PUZZLE, LATIHAN OOP"
slug: "belajar-php-oop-part-7-merangkai-puzzle-latihan-oop"
category: "OOP"
date: "2016-04-13"
status: "published"
---

Selamat! Kamu sudah bisa buat class Mahasiswa. Kamu sudah belajar tentang OOP di postingan-postingan sebelumnya. Sekarang waktunya kamu rangkai potongan puzzle, menggabungkan semua yang sudah dipelajari sebelumnya. Sekarang waktunya kita latihan! ^^

Try this out ya! ^^

## Latihan: Membuat Class MataKuliah {#latihan-class-matakuliah}
Nah sekarang kita latihan buat class baru. Umm, class apa ya? Misalnya class MataKuliah. Setiap MataKuliah pasti punya public property `$sks`, dan juga punya nama kode mata kuliah yang berbeda-beda. Nah, buat ngasih `$kode` dan `$nama` mata kuliahnya kita pakai __constructor.

Oh iya kita juga perlu beberapa method. Mata kuliah bisa menampilkan info() dan juga bisa tampilkanJadwal(). ^^
Daaan yang terakhir, kita perlu dua mata kuliah! ^^

Let's start! ('-' )9

[a] Kita buat class MataKuliah.
[b] Tambahin public property `$sks`, kita isi dengan value 3.
[c] Kita tambahin lagi public property lain, yaitu `$kode` dan `$nama`. Jangan kasih value dulu.
[d] Tambahin method __construct(), yang nerima parameter `$kode` dan `$nama`.
[e] Di method __construct, tambahin kode untuk nyimpan value `$kode` dan `$nama`.

Nah, dari instruksi di atas, kodenya jadi kaya di bawah ini:
```php
<!DOCTYPE html>  
<html>  
    <head>  
        <title>Membuat Class MataKuliah</title>  
        <style>  
            p {  
                color: grey;  
                font-size: 20px;  
            }  
        </style>  
    </head>  
    <body>  
        <?php  
            class MataKuliah {  
                public $sks = 3;  
                public $kode;  
                public $nama;  
                
                public function __construct($kode, $nama) {  
                    $this->kode = $kode;  
                    $this->nama = $nama;  
                }  
            }  
        ?>  
    </body>  
</html>  
```

Boleh disimpan dulu filenya. Kasih nama apa aja! ^^

Nah, sekarang kita coba tambahin method.
[a] Pertama kita tambahin method ke class MataKuliah, misalnya info(), yang isinya return info lengkap mata kuliah.
[b] Terus tambahin lagi method tampilkanJadwal(), yang isinya return jadwal kuliah.
[c] Sekarang kita buat dua instance dari class MataKuliah. `$mk1` dan `$mk2`.
[d] Ya, kita coba panggil methodnya. `$mk1` tampilkan info(). Terus echo hasilnya.
[e] Yang terakhir, `$mk2` tampilkan jadwal(). Echo juga hasilnya.

Nah, gimana kodenya? Ini dia kodenya: ^^
```php
<!DOCTYPE html>  
<html>  
    <head>  
        <title>Membuat Class MataKuliah</title>  
        <style>  
            p {  
                color: grey;  
                font-size: 20px;  
            }  
        </style>  
    </head>  
    <body>  
        <?php  
            class MataKuliah {  
                public $sks = 3;  
                public $kode;  
                public $nama;  
                
                public function __construct($kode, $nama) {  
                    $this->kode = $kode;  
                    $this->nama = $nama;  
                }  
                
                public function info() {  
                    return "Mata Kuliah " . $this->nama . " (" . $this->kode . ") - " . $this->sks . " SKS";  
                }  
                
                public function tampilkanJadwal() {  
                    return "Jadwal " . $this->nama . " setiap hari Senin jam 08.00";  
                }  
            }  
            
            $mk1 = new MataKuliah("IF001", "Pemrograman Web");  
            $mk2 = new MataKuliah("IF002", "Basis Data");  
            
            echo $mk1->info();  
            echo "<br/>";  
            echo $mk2->tampilkanJadwal();  
        ?>  
    </body>  
</html>  
```

## Hasil Akhir {#hasil-akhir}
Simpan lagi filenya. Nah sekarang kamu coba run di browser kesayanganmu. Yep, hasilnya itu:
> Mata Kuliah Pemrograman Web (IF001) - 3 SKS
> Jadwal Basis Data setiap hari Senin jam 08.00

Semoga bermanfaat. Semangat terus ya belajarnya! ^^

***
Stay tuned untuk artikel selanjutnya dimana kita akan belajar konsep OOP lainnya! ^^