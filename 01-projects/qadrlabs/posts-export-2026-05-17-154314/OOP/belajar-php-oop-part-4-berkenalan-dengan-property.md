---
title: "Belajar PHP OOP Part 4 Berkenalan Dengan Property"
slug: "belajar-php-oop-part-4-berkenalan-dengan-property"
category: "OOP"
date: "2016-04-08"
status: "published"
---

Selamat yaaa, kamu sudah bisa bikin class dasar Mahasiswa di postingan sebelumnya!

## Apa Itu Property? {#apa-itu-property}
Nah, sekarang kita bisa menambahkan beberapa property ke dalam class kita. Masih ingat apa itu property? Ya, kamu benar kawan... Property itu kumpulan data yang terikat dengan sebuah objek. Di artikel sebelumnya kita sudah lihat contoh property mahasiswa seperti nama dan NIM.

## Cara Menambahkan Property ke Class {#menambahkan-property}

Sekarang coba kamu perhatiin kode dibawah ini ya...
```php
class Mahasiswa {  
    public $statusAktif = true;  
    public $nama;  
    public $nim;  
}  
$mhs1 = new Mahasiswa();  
$mhs1->nama = "Budi";  
$mhs1->nim = "12345";  
echo $mhs1->statusAktif; // 1  
echo $mhs1->nama;        // Budi  
echo $mhs1->nim;         // 12345  
```

Di contoh di atas, pertama kita membuat class Mahasiswa. Lalu, kita tambahin sebuah property, `$statusAktif`, dan set valuenya menjadi true. Abis itu, kita tambahin property `$nama` dan `$nim`, tapi belum kita isi valuenya.

Setelah pendefinisian class, kita buat sebuah instance baru dari class Mahasiswa dan kita simpan di variabel `$mhs1`. Nah, di sini kita isi property `$nama` dengan "Budi" dan `$nim` dengan "12345". Finally, kita cetak ketiga property dari `$mhs1`.

## Praktik: Lengkapi Class Mahasiswa {#praktik-lengkapi-class}
Nah, sekarang kita coba coding lagi yuk!^^ Mari kita lengkapi class Mahasiswa kita dengan property-property dasar. Let's try this out ya! :D

Di bawah ini full source codenya:
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
                }  
                $mhs1 = new Mahasiswa();  
                $mhs2 = new Mahasiswa();  
                echo $mhs1->statusAktif; //tampil 1  
            ?>  
        </p>  
    </body>  
</html>  
```

Kalau kita coba run di browser, kira-kira apa ya yang bakalan muncul?
Iya, kamu benar.. muncul angka 1 aja karena property `$statusAktif` bernilai true. ^^

Di artikel berikutnya kita akan belajar cara mengisi nilai property menggunakan constructor, seperti yang sudah kita lihat di artikel sebelumnya ya! Semangat terus! ^^

***
Stay tuned untuk artikel berikutnya! ^^