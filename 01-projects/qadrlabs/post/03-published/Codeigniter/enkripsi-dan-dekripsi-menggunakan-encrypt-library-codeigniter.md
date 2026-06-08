---
title: "Enkripsi Dan Dekripsi Menggunakan Encrypt Library CodeIgniter"
slug: "enkripsi-dan-dekripsi-menggunakan-encrypt-library-codeigniter"
category: "Codeigniter"
date: "2016-04-11"
status: "published"
---

Keamanan data itu sangatlah penting dalam sebuah aplikasi. Kabar baiknya di dalam CodeIgniter sudah tersedia library khusus untuk mengamankan data dengan teknik enkripsi, yaitu `Encrypt Class`. Library ini bisa melakukan enkripsi dua arah (two-way encryption) dan untuk prosesnya menggunakan ekstensi `Mcrypt` PHP yang memang wajib ada untuk menggunakan Encrypt Class.

Gimana sih caranya pakai encrypt class di aplikasi CodeIgniter kita?
*Let's try it out!*

## Overview {#overview}
Di tutorial ini kita akan bikin program sederhana untuk mencoba library encrypt CodeIgniter. Nanti programnya akan menampilkan 3 bagian output: pertama pesan asli yang belum dienkripsi, kedua pesan yang sudah dienkripsi, dan ketiga pesan yang sudah didekripsi balik ke bentuk aslinya.

## Step 1 - Setting Key {#step-1}
Hal yang penting dalam proses enkripsi dan dekripsi adalah key. Tanpa key, kita mungkin bisa mengenkripsi suatu pesan, tapi nanti kita tidak bisa mendekripsi atau ngembaliin lagi pesan yang sudah kita enkripsi. Jadi, penting sekali untuk kita memilih key, di mana key ini  nanti  akan kita pakai untuk proses enkripsi dan juga dekripsi. Tanpa perlu diingatkan juga kita pasti tahu, kita mesti hati-hati buat jagain key kita. Karena bisa saja disalahgunakan oleh orang yang tidak bertanggung jawab untuk mengakses data supaya bisa didekripsi. 

Berdasarkan rekomendasi dari dokumentasi codeigniter, supaya optimal dalam proses enkripsinya, panjang key kita kurang lebih 32 karakter (256 bit). Tentu key yang kita pakai untuk enkripsi dan dekripsi ini mesti random juga lho, kombinasi huruf dan angka kaya bahasa alay itu mungkin recommended buat dijadiin key.  

Sebagai contoh di sini saya sudah menyiapkan key menggunakan nama blog lama saya, yaitu `recodeku.blospot.com123456789123`. 

Untuk kemudahan ngetik di tutorial ini, key di contoh ini masih bisa ditebak dan juga sederhana, jadi untuk di environment **production**, pastikan key yang kita pakai sesuai best practice.
  
## Step 2 - Buat controller proses encrypt dan decrypt {#step-2}
Pada tahapan ini kita akan membuat controller baru yang akan menangani proses enkripsi dan dekripsi. Di dalam controller yang akan kita buat terdapat method `index()` yang akan menangani program sederhana enkripsi dan dekripsi. 

Sekarang kita buat controller baru dengan nama `Tes_enkripsi.php`. Setelah itu kita deklarasikan class `Tes_enkripsi` dan method `index()`.

```php  
 <?php 
 defined('BASEPATH') OR exit('No direct script access allowed'); 
 class Tes_enkripsi extends CI_Controller { 
      function __construct(){ 
           parent::__construct(); 
           $this->load->library('encrypt'); 
      } 
      function index(){ 
           $msg = 'Ini Pesan rahasia lho! Jangan bilang siapa-siapa ya!'; //Plain text 
           $key = 'recodeku.blospot.com123456789123'; //Key 32 character 
           //default menggunakan MCRYPT_RIJNDAEL_256 
           $hasil_enkripsi = $this->encrypt->encode($msg, $key);  
           $hasil_dekripsi = $this->encrypt->decode($hasil_enkripsi, $key); 
           echo "Pesan yang mau dienkripsi: ".$msg."<br/><br/>"; 
           echo "Hasil enkripsi: ".$hasil_enkripsi."<br/><br/>"; 
           echo "Hasil dekripsi: ".$hasil_dekripsi."<br/><br/>"; 
      } 
 } 
```

Simpan file di folder controller application/controllers/, kita kasih nama filenya `Tes_enkripsi.php` di sesuaikan dengan nama classnya.


Inisialisasi `Encrypt Class` sama seperti umumnya inisialisasi kelas di CodeIgniter, `Encrypt Class` juga dipanggil di controller menggunakan method `$this->load->library()`. Ini contoh pemanggilan `class`: 

```php
 $this->load->library(‘encrypt’);   
```

Setelah dipanggil, objek Encrypt library bisa kita gunakan seperti contoh kode di bawah ini:
```php 
  $this->encrypt   
```

## Step 3 - Uji Coba {#step-3}
Sekarang kita coba run di browser. Output yang akan muncul kurang lebih seperti screenshot di bawah ini:

![Run controller](https://4.bp.blogspot.com/-TjOyQOls3dg/VwrXRZRZ2DI/AAAAAAAAATw/QOpoTClMjng_JXMpYkhCZedrPxoYdgvSw/w640-h78/tampilan%2Bprogram.png)

 Lho kok hasil enkripsinya beda ya!
 Iya, sebagai info hasil dari enkripsinya beda-beda... Tapi, tenang aja... selama key yang kita pakai sama, hasil enkripsinya masih bisa didekripsi kok. ^^

## Penutup {#penutup}
 
Di dalam aplikasi yang kita kembangkan, keamanan data itu sangatlah penting. Kabar baiknya di dalam CodeIgniter terdapat library yang dapat digunakan untuk mengamankan data dengan teknik enkripsi, yaitu `Encrypt Class`. Penggunaan library ini adalah salah satu upaya untuk mengamankan data di aplikasi yang kita kembangkan. Tidak seratus persen aman memang. Setidaknya ini mengurangi celah keamanan.

Semoga bermanfaat... ^^
Semangat terus yaaaaa~!
 
***Note**: Library ini cuman digunain di CodeIgniter versi lama dan sekarang udah DEPRECATED. Dipostingan berikutnya kita coba bahas Encryption library CodeIgniter.*