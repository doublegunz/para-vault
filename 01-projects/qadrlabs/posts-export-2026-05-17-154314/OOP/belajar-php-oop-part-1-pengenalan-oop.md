---
title: "Belajar PHP OOP Part 1 Pengenalan OOP"
slug: "belajar-php-oop-part-1-pengenalan-oop"
category: "OOP"
date: "2016-04-07"
status: "published"
---

Sebagian besar waktu kita digunakan untuk menunggu. Menunggu kereta, menunggu jemputan, menunggu bus, menunggu sekolah, menunggu orang, dan aneka menunggu lainnya. Dan di sini pun aku sedang menunggu, menunggu jam kuliah berikutnya, menunggu dosen yang akan memberikan ilmunya.

Biasanya di waktu seperti ini, ada banyak hal yang biasa dilakukan orang - orang. Ada mahasiswa yang lagi asyik dengan laptopnya, ada mahasiswi yang lagi asyik selfie, ada dosen yang siap - siap mau mengajar di jam kuliah berikutnya dan ada juga mamang petugas kebersihan yang tampak lagi bingung, memikirkan sampah yang tak pernah ada habisnya. Aku duduk memerhatikan sekitar. Menulis apa yang sedang mereka lakukan. Menikmati hidup dengan menulis kehidupan yang selalu menimbulkan pertanyaan sendiri.

Lalu, salah seorang kawanku bertanya apa yang sedang kutulis. Inilah yang kutulis. :)

```php
<?php
// Membuat class  
class Orang
{
    // Membuat properties (variables yang terikat pada object)  
    public $isAlive = true;
    public $firstname;
    public $lastname;
    public $age;
    // Memasukan value  
    public function __construct($firstname, $lastname, $age)
    {
        $this->firstname = $firstname;
        $this->lastname = $lastname;
        $this->age = $age;
    }
    // Membuat method (function yang terikat pada object)  
    public function salam()
    {
        return "Assalamu'alaikum, Namaku " . $this->firstname . " " . $this->lastname . ". Salam kenal! :)";
    }
    public function menulis()
    {
        return "Aku sedang menulis tentang sekitar. :)";
    }
}
// membuat object   
$me = new Orang('Gun Gun', 'Priatna', 24);
// Mencetak method salam dan menulis  
echo $me->salam();
echo "<br/>";
echo $me->menulis();
?>
```


Ya, kawan.. kode di atas itu contoh OOP atau Object Oriented Programming. 

## Apa Itu OOP? {#apa-itu-oop}
Kalau kamu bertanya apa itu OOP? Sama kaya namanya, OOP itu Pemrograman berorientasi objek, yang artinya kamu dapat membuat objek, yang berisi variable dan function.

*Lalu kamu bertanya apa itu objek? *

Saat kita berbicara tentang objek, kita akan menyebut variable pada objek ini sebagai property (atau attribute), dan function akan kita sebut method. Objek ini sangat esensial saat kita menggunakan PHP. Hampir semua yang berhubungan dengan PHP itu termasuk objek lho! Sebuah fungsi atau array pun termasuk objek. Dan ini menunjukkan kenapa kita menggunakan objek, kita bisa mengumpulkan fungsi dan data di satu tempat, dan nantinya kita bisa membuat objek dengan mudah memakai class (sebuah object constructor), sehingga kita bisa membuat banyak instances (sebuah objek yang dibuat melalui class).  

*Lalu kamu bertanya lagi apa hubungan paragraf pembuka di atas dengan objek?*

Kawan, cobalah diam sejenak lalu perhatikan sekitar. Aku, kamu, dosen yang sedang kita tunggu... itu termasuk objek di dalam kehidupan.