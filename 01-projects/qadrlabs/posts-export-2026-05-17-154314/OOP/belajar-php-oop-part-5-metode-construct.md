---
title: "BELAJAR PHP OOP PART 5 METODE CONSTRUCT"
slug: "belajar-php-oop-part-5-metode-construct"
category: "OOP"
date: "2016-04-09"
status: "published"
---

Saya akan menyesuaikan artikel lanjutan tersebut untuk melanjutkan pembahasan class Mahasiswa dari artikel sebelumnya.

## Masalah Tanpa Constructor {#masalah-tanpa-constructor}
Jadi, kita sudah belajar tentang menambahkan property ke class Mahasiswa. Tapi gimana ya sekarang objek `$mhs1` sama `$mhs2` isinya sama? cuma beda nama objek doang? Masa tiap bikin objek mahasiswa baru harus isi nama dan NIM satu-satu?

Nah, ada solusinya lho, kawan! Kita mesti buat semacam constructor untuk membuat objek dengan data yang berbeda. Constructor ini juga termasuk method, tapi kamu ga perlu khawatirin tentang ini dulu. Terus gimana caranya bikin constructor ini? Check this out ya!

## Apa Itu Constructor? {#apa-itu-constructor}
Seperti yang sudah saya sebutkan sebelumnya, constructor ini termasuk method. Jadi cara penulisan sintaksnya pun sama kaya membuat function. Di bawah ini penulisan sintaksnya:
```php
public function __construct($prop1, $prop2) {  
    $this->prop1 = $prop1;  
    $this->prop2 = $prop2;  
}  
```

Nah, sekarang kita mempelajari beberapa hal baru dari sintaks di atas, yaitu:
[a] Kamu membuat sebuah fungsi yang terikat ke dalam sebuah class.
[b] Method constructor ini dipanggil `__construct()`.
[c] And finally, cara buat masukin value:
`$this->prop1 = $prop1`
`$this` di sintaks di atas itu merujuk kepada objek yang kita buat dan sintaks `->prop1` adalah property dari objek.

Dengan membuat objek baru menggunakan keyword new, sebenarnya kamu manggil method `__construct()` ini, yang artinya membentuk objek. Jadi, saat objek dibuat kita mesti menambahkan argumen untuk mengisi property-nya.

Mari kita langsung coba ya! Kita lanjutin class Mahasiswa dari postingan sebelumnya. ^^

## Praktik: Constructor di Class Mahasiswa {#praktik-constructor}
[a] Pertama kita bikin constructor di class Mahasiswa dengan dua parameter, yaitu `$nama` dan `$nim`.
[b] Di constructor kita, pakai dua parameter ini untuk set public property `$nama` dan `$nim`.
[c] Kita juga bisa kasih nilai awal 0 untuk property `$nilai`.
[d] Terakhir, kita buat dua instance mahasiswa dengan data yang berbeda.

Nah, di bawah ini sintaks kodenya:
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
                }  
                
                $mhs1 = new Mahasiswa("Budi", "12345");  
                $mhs2 = new Mahasiswa("Ana", "12346");  
                
                echo $mhs1->nama; // tampil: Budi
                echo "<br>";
                echo $mhs2->nama; // tampil: Ana
            ?>  
        </p>  
    </body>  
</html>  
```

Simpan filenya, lalu coba kamu run di browser. Apa hasilnya? Yep, muncul nama "Budi" dan "Ana".. Sesuai dengan argumen yang kita masukan saat membuat objek. ^^

Di artikel berikutnya kita akan belajar cara membuat method untuk menambahkan fungsionalitas ke class Mahasiswa kita! Semangat terus ya belajarnya! ^^

***
Stay tuned untuk artikel selanjutnya! ^^