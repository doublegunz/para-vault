---
title: "Belajar PHP OOP Part 3 Membuat Class Pertamamu."
slug: "belajar-php-oop-part-3-membuat-class-pertamamu"
category: "OOP"
date: "2016-04-07"
status: "published"
---

Kawan, di postingan sebelumnya kita sudah membahas tentang class Mahasiswa dengan property dan method-nya! Nah, sekarang ayo kita mulai dari dasar dulu cara pembuatan class. :D

## Sintaks Dasar Membuat Class {#sintaks-dasar-class}
Buat bikin sebuah class di dalam PHP, ada bentuk penulisan dasar sintaksnya lho! Nah, bentuk penulisan sintaksnya itu kaya gini:
```php
class NamaClass {  
}  
```

Class di dalam sintaks di atas itu artinya kamu lagi buat class yang baru. Penulisan sintaks nya mirip kaya penulisan sintaks function ya! ^^ Nah abis bikin class kita bisa buat instances baru dari class ini pakai sintaks di bawah ini:
```php
$objek1 = new NamaClass();  
```

## Membuat Instance dari Class {#membuat-instance}
Sintaks di atas itu artinya kamu lagi bikin objek yang baru lho! Nantinya kita bisa nambahin argumen sebagai sebuah property ke dalam objek yang baru kita buat. Di artikel sebelumnya kita udah lihat contohnya waktu bikin instance mahasiswa dengan nama dan NIM. Tapi untuk sekarang, kita coba dulu yang paling dasar ya!

## Praktik: Class Mahasiswa Pertamamu {#praktik-class-mahasiswa}
Nah buat sekarang, kita coba buat class yang baru, kita kasih nama class Mahasiswa tapi masih kosong (belum ada property dan method). Terus kita buat dua instance dari class Mahasiswa yang kita buat. 

Berikut ini sintaks codenya:
```php
<!DOCTYPE html>  
<html>  
    <head>  
        <title>Membuat Class Mahasiswa</title>  
    </head>  
    <body>  
        <p>  
            <?php  
                class Mahasiswa {  
                }  
                $mahasiswa1 = new Mahasiswa();  
                $mahasiswa2 = new Mahasiswa();  
            ?>  
        </p>  
    </body>  
</html>  
```

Selamaaaaat~, kamu berhasil membuat class dasar pertamamu! :)
***
Di postingan berikutnya, kita akan coba menambahkan property seperti nama dan NIM ya.. ^^