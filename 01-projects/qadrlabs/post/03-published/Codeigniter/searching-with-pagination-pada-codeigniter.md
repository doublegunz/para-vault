---
title: "Searching With Pagination Pada CodeIgniter"
slug: "searching-with-pagination-pada-codeigniter"
category: "Codeigniter"
date: "2016-10-18"
status: "published"
---

Hello! Masih semangat berkarya, kan? Yuk upgrading skill dulu!

Beberapa postingan saya sebelumnya membahas seputar framework CodeIgniter 3. Dan di antara postingan tersebut, saya membahas tentang [CRUD sederhana CodeIgniter 3](https://qadrlabs.com/post/crud-sederhana-codeigniter). Ya, CRUD (create, read, update, delete).. fitur umum yang sering kita jumpai di dalam aplikasi yang berinteraksi dengan database. Selain untuk memanipulasi data, ada fitur lain yang melengkapi dan harus selalu ada dalam fitur CRUD ini. Diantaranya adalah list data, pagination, validasi form & sanitasi, pencarian (searching), penyaringan (filter) & pengurutan (sortir) dan notifikasi, konfirmasi serta progress state. Karena sebelumnya kita sudah membahas tentang list data dan pagination, di edisi tutorial CodeIgniter 3 kali ini kita akan membahas tentang Searching with pagination pada CodeIgniter 3. Dan seperti biasa, kita akan **membuat project sederhana Searching with pagination pada CodeIgniter 3**. *Ok, let's start!*

Pencarian atau searching biasanya digunakan untuk mencari informasi berdasarkan keyword atau kata kunci tertentu. Hal ini diperlukan untuk memudahkan pengguna untuk menemukan informasi tanpa harus menggunakan waktu yang banyak hanya untuk mencari data yang akan diproses. Misalnya, kita akan mencari data pengguna dengan nama berawalan huruf 'G'. Belum tentu data ini berada di halaman paling depan 'kan? Bisa jadi ada di halaman yang kesekian ratus. Dan bagaimana kalau data dengan nama berawalan huruf G ada ratusan atau lebih? Hal ini tentu akan mengurangi kenyamanan pengguna dalam menggunakan aplikasi yang kita buat. Oleh karena itulah, fitur searching (pencarian) ini termasuk fitur yang penting dalam fitur CRUD.

Lalu apa fungsi pagination dalam proses pencarian? Karena data hasil pencarian yang ditampilkan itu selalu sedikit. Boleh jadi data yang ditampilkan itu banyak, karena jumlah data keseluruhannya yang memang sudah banyak. Atau karena keyword yang digunakan untuk pencarian itu kurang sesuai untuk menampikan data yang diinginkan. Di sinilah pagination diperlukan. Untuk membatasi data yang ditampilkan.

Dan di seri tutorial [Belajar CodeIgniter 3](https://qadrlabs.com/series/belajar-codeigniter-3) kali ini, kita akan coba mengimplementasikan Searching with pagination pada CodeIgniter 3. Di dalam contoh source code-nya, kita akan menampilkan data dari database ke dalam tabel. Kemudian kita akan coba melakukan pencarian data dengan memasukan keyword, lalu setelah diproses, data hasil pencarian akan ditampilkan sesuai dengan keyword. Dan data hasil pencarian tersebut akan dibatasi perhalamannya, sesuai dengan limit yang ditentukan. Lalu, apa saja langkah-langkah membuat fitur searching with pagination pada CodeIgniter? *Try this out, ya!*

## Step 1 - Persiapan{#step-1}
Apa saja sih yang diperlukan untuk mengikuti tutorial kali ini? check this out ya!
- XAMPP versi 5.5.35 (Apache, PHP 5.5.35, dan MariaDB).
- CodeIgniter versi 3.1.0

**Note**: Per tanggal 22 desember 2022, PHP yang digunakan untuk uji coba adalah PHP `7.4` dan codeigniter versi `3.1.13`.

Saya asumsikan kamu sudah paham basic CodeIgniter 3 tentang instalasi framework CodeIgniter 3. Jika belum, kamu boleh baca [Tutorial dasar CodeIgniter 3 untuk Pemula](https://qadrlabs.com/post/tutorial-dasar-codeigniter-untuk-pemula) dulu.

Ok, lanjut... Nah, di tutorial kali ini, framework CodeIgniter yang sudah terinstall (yang disimpan di direktori `C:\xampp\htdocs\`), saya rename menjadi `latihan_ci3`.


## Step 2 - Membuat Database dan table{#step-2}
Karena aplikasi yang akan kita buat untuk project searching with pagination pada CodeIgniter ini berinteraksi dengan database, maka kita perlu membuat database terlebih dahulu. Untuk membuat database, kita bisa menggunakan phpMyAdmmin yang sudah tersedia dalam Xampp. Sekarang kita buka browser, lalu ketik alamat `localhost/phpmyadmin/` untuk membuka phpMyAdmin. Lalu, buat database dengan nama `latihan_ci3`

Setelah database kita buat, berikutnya kita akan membuat sebuah tabel dengan nama `tbl_buku`, sekaligus kita tambahkan sample data. Untuk membuat tabel dan insert sample data, klik database `latihan_ci3` yang sudah dibuat, lalu klik menu SQL. Setelah itu ketik perintah SQL di bawah ini:
```bash
 -- --------------------------------------------------------  
   
 --  
 -- Table structure for table `tbl_buku`  
 --  
   
 CREATE TABLE `tbl_buku` (  
  `id` int(8) NOT NULL AUTO_INCREMENT,  
  `judul` varchar(100) NOT NULL,  
  `penulis` varchar(30) NOT NULL,  
  `isbn` varchar(30) NOT NULL,  
  PRIMARY KEY (`id`)  
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;  
   
 --  
 -- Dumping data for table `tbl_buku`  
 --  
   
 INSERT INTO `tbl_buku` (`id`, `judul`, `penulis`, `isbn`) VALUES  
 (1, 'Learning PHP, MySQL & JavaScript', 'Robin Nixon', 'ISBN-13: 978-1491918661'),  
 (2, 'PHP and MySQL for Dynamic Web Sites', 'Larry Ullman', 'ISBN-13: 978-0321784070'),  
 (3, 'PHP Cookbook', 'David Sklar', 'ISBN-13: 978-1449363758'),  
 (4, 'Programming PHP', 'Kevin Tatroe', 'ISBN-13: 978-1449392772'),  
 (5, 'Modern PHP: New Features and Good Practices', 'Josh Lockhart', 'ISBN-13: 978-1491905012'),  
 (6, 'Modern PHP New Features and Good Practices', 'Josh Lockhart', 'ISBN-13: 978-1491905012'),  
 (7, 'Learning PHP MySQL & JavaScript', 'Robin Nixon', 'ISBN-13: 978-1491918661'),  
 (8, 'PHP and MySQL for Dynamic Web Sites', 'Larry Ullman', 'ISBN-13: 978-0321784070'),  
 (9, 'PHP Cookbook', 'David Sklar', 'ISBN-13: 978-1449363758'),  
 (10, 'Programming PHP', 'Kevin Tatroe', 'ISBN-13: 978-1449392772'),  
 (11, 'Modern PHP New Features and Good Practices', 'Josh Lockhart', 'ISBN-13: 978-1491905012'),  
 (12, 'Learning PHP MySQL & JavaScript', 'Robin Nixon', 'ISBN-13: 978-1491918661'),  
 (13, 'PHP and MySQL for Dynamic Web Sites', 'Larry Ullman', 'ISBN-13: 978-0321784070'),  
 (14, 'PHP Cookbook', 'David Sklar', 'ISBN-13: 978-1449363758'),  
 (15, 'Programming PHP', 'Kevin Tatroe', 'ISBN-13: 978-1449392772'),  
 (16, 'Modern PHP New Features and Good Practices', 'Josh Lockhart', 'ISBN-13: 978-1491905012'),  
 (17, 'Learning PHP MySQL & JavaScript', 'Robin Nixon', 'ISBN-13: 978-1491918661'),  
 (18, 'PHP and MySQL for Dynamic Web Sites', 'Larry Ullman', 'ISBN-13: 978-0321784070'),  
 (19, 'PHP Cookbook', 'David Sklar', 'ISBN-13: 978-1449363758'),  
 (20, 'Programming PHP', 'Kevin Tatroe', 'ISBN-13: 978-1449392772');  
   
```

Iya, iya.. boleh langsung di-copy-paste juga kok!
Nah, kalau sudah, klik tombol 'Go' yang ada di kanan bawah untuk mengeksekusi perintah SQL tersebut. Dan `tbl_buku` berserta sample data-nya berhasil kita buat.

![Membuat database dan tabel](https://4.bp.blogspot.com/-s9npYBDSobo/WAV2Xr0l8tI/AAAAAAAAAjI/ohcC9ZTgS5snuzNtMSbzfSV_FiURgPLbQCEw/s16000/Searching-with-pagination-pada-CodeIgniter-gambar%2B1.jpg)

![tabel buku](https://2.bp.blogspot.com/-7enAmaQg8t8/WAV2YV8NyKI/AAAAAAAAAjU/kLW_RvdwTQ4z2wGC9wLoJrp5hMFJ2cd7QCEw/s16000/Searching-with-pagination-pada-CodeIgniter-gambar%2B2.jpg)


## Step 3 - Konfigurasi Database dan Base Url{#step-3}
Kalau kamu sudah baca [ Mudahnya Membuat Pagination Pada CodeIgniter], pasti kamu sudah paham cara konfigurasi database dan Base URL. Ya, pertama kita atur dulu `base url` project kita. kita buka file `config.php` yang ada di direktori `latihan_ci3/application/config` menggunakan teks editor, lalu kita cek sekitar line 26. Kita isi ```$config['base_url'] dengan http://localhost/latihan_ci3/```, seperti gambar ini.

![konfigurasi](https://2.bp.blogspot.com/-Nqx-Qtq6w9Q/WAV2YYEjBVI/AAAAAAAAAjQ/K6lFw1gxficIuPM-xQQ4URSmbejTP8XdQCEw/s16000/Searching-with-pagination-pada-CodeIgniter-gambar%2B3.jpg)

Setelah itu tekan CTRL+S untuk menyimpan kembali file `config.php`.

Selanjutnya, kita atur konfigurasi database. Buka file `database.php` dengan teks editor. Ya, file ini ada di direktori yang sama seperti file `config.php`, yaitu `latihan_ci3/application/config`. Cek sekitar line 76, lalu atur konfigurasi database seperti di bawah ini:

```php
 $db['default'] = array(
      'dsn'     => '',
      'hostname' => 'localhost',      //nama host
      'username' => 'root',          //isi dengan username, biasanya root
      'password' => '',                //isi password jika menggunakan password, jika tidak cukup dikosongkan
      'database' => 'latihan_ci3',//isi dengan nama database yang kita buat, yaitu latihan_ci3
      'dbdriver' => 'mysqli',      //kita pakai mysqli untuk dbdrivernya
      'dbprefix' => '',
      'pconnect' => FALSE,
      'db_debug' => (ENVIRONMENT !== 'production'),
      'cache_on' => FALSE,
      'cachedir' => '',
      'char_set' => 'utf8',
      'dbcollat' => 'utf8_general_ci',
      'swap_pre' => '',
      'encrypt' => FALSE,
      'compress' => FALSE,
      'stricton' => FALSE,
      'failover' => array(),
      'save_queries' => TRUE
 );
 
```

![konfigurasi database](https://1.bp.blogspot.com/-2-TDU10-9kY/WAV2Y76jR2I/AAAAAAAAAjc/y1y4upB80aETVfdQE1Xpz3m84l_gaDP3ACEw/s16000/Searching-with-pagination-pada-CodeIgniter-gambar%2B4.jpg)

Setelah kita atur, simpan kembali file `database.php` dengan menekan CTRL+S.

Untuk berinteraksi dengan database, kita bisa menggunakan library database CodeIgniter. Sekarang kita buka file `autoload.php` (masih di direktori `latihan_ci3/application/config`). Cek sekitar line 61 (dalam file `autoload.php`), kita isi `$autoload['libraries']` dengan database.

```php
 $autoload['libraries'] = array('database');
```

![autoload](https://2.bp.blogspot.com/-0zESQVdhSYI/WAV2oUoBW-I/AAAAAAAAAjo/6wV8PZfrCXwIOPaOIE-9d2gaYl_FthfzQCEw/s16000/Searching-with-pagination-pada-CodeIgniter-gambar%2B5.jpg)

Simpan kembali file `autoload.php` dengan menekan CTRL+S.

## Step 4 - Membuat Model{#step-4}
Sekarang, waktunya kita coding kawan! Semangat ya! Pertama kita akan membuat file models dengan nama `M_searching.php`. Di dalam file tersebut terdapat class model dengan nama `M_searching`. Sebagai reminder, **nama class dan nama file** di dalam CodeIgniter itu harus sama. Kita akan membuat dua method yang akan kita gunakan untuk membuat fitur searching with pagination, yaitu:
1. `lihat()` :: Mengambil data dari `tbl_buku`, terdapat tiga parameter untuk limit, kondisi (`like`) dan juga `offset`.` `Berbeda dengan tutorial pagination, fitur searching ini menggunakan parameter tambahan yaitu kondisi (ditulis: `$like`) yang diambil dari keyword pencarian.
2. `jumlah()` :: Menghitung jumlah row data yang ada pada `tbl_buku` berdasar keyword yang digunakan dalam pencarian data jika menggunakan fitur searching.

Yuk sekarang buka kembali text editor, lalu kita sama-sama ketik kode di bawah ini ya...

```php
<?php defined('BASEPATH') or exit('No direct script access allowed');

class M_searching extends CI_Model
{
    //ambil data
    public function lihat($sampai, $dari, $like = '')
    {
        if ($like) {
            $this->db->where($like);
        }

        $query = $this->db->get('tbl_buku', $sampai, $dari);
        return $query->result_array();
    }

    //hitung jumlah row
    public function jumlah($like='')
    {
        if ($like) {
            $this->db->where($like);
        }

        $query = $this->db->get('tbl_buku');
        return $query->num_rows();
    }
}
```


Kalau sudah diketik, tekan CTRL+S untuk menyimpan file models kita dengan nama `M_searching.php` di direktori `latihan_ci3/application/models`.

![membuat model class](https://1.bp.blogspot.com/-l22U0F4Tl-E/WAV2oSSLS7I/AAAAAAAAAjk/ZBdFaF7KKhgxQF4ND2anil-vrf-OSx3YQCEw/s16000/Searching-with-pagination-pada-CodeIgniter-gambar%2B6.jpg)

## Step 5 - Membuat View{#step-5}
Pada tahapan ini kita akan membuat dua file views, yaitu `v_paging.php` dan `v_searching.php`. File `v_paging.php` digunakan untuk menampilkan data sebelum menggunakan fitur searching, itu artinya data ditampilkan tanpa menggunakan kondisi. Berbeda dengan file sebelumnya, file `v_searching.php` digunakan untuk menampilkan data saat kita menggunakan fitur searching. Yep, data ditampilkan berdasarkan keyword yang digunakan dalam pencarian.

Ok, sekarang kita coding lagi ya! Kita akan buat `v_paging.php` terlebih dahulu. Buka lagi text editor, lalu kita ketik kode berikut ini:

```php
 <?php
 defined('BASEPATH') OR exit('No direct script access allowed');
 ?><!DOCTYPE html>
  <html>
  <head>
       <title>
            <?php echo $title; ?>
       </title>
       <style>
            body {
                 font-family: 'Raleway', sans-serif;
            }
 
            #gp_head
            {
                 text-align: center;
                 background-color: #61CAFA;
                 height: 66px;
                 margin: 0 0 -29px 0;
                 padding-top: 35px;
                 border-radius: 8px 8px 0 0;
                 color: rgb(255, 255, 255);
            }
 
            #gp_tabel {
                 font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
                 width: 80%;
                 border-collapse: collapse;
            }
 
            #gp_tabel td, #gp_tabel th {
                 font-size: 1em;
                 border: 1px solid #61CAFA;
                 padding: 3px 7px 2px 7px;
            }
 
            #gp_tabel th {
                 font-size: 1.1em;
                 text-align: center;
                 padding-top: 5px;
                 padding-bottom: 4px;
                 background-color: #61CAFA;
                 color: #ffffff;
            }
 
            #gp_tabel tr.alt td {
                 color: #000000;
                 background-color: #61CAFA;
            }
 
            #gp_tabel a {
                 border:solid 1px;
                 -webkit-border-radius:3px;
                 padding:6px 9px 6px 9px;
            }
 
            #gp_tabel a:hover,
            #gp_tabel a.current
            {
                 color:#FFFFFF;
                 box-shadow:0px 1px #EDEDED;
                 -moz-box-shadow:0px 1px #EDEDED;
                 -webkit-box-shadow:0px 1px #EDEDED;
            }
 
            #gp_tabel a:hover,
            #gp_tabel a.current
            {
                 text-shadow:0px 1px #388DBE;
                 border-color:#3390CA;
                 background:#58B0E7;
                 background:-moz-linear-gradient(top, #B4F6FF 1px, #63D0FE 1px, #58B0E7);
                 background:-webkit-gradient(linear, 0 0, 0 100%, color-stop(0.02, #B4F6FF), color-stop(0.02, #63D0FE), color-stop(1, #58B0E7));
            }
 
            #gp_tabel a
            {
                 color:#58B0E7;
                 display:block;
                 text-decoration:none;
                 padding:7px 10px 7px 10px;
            }
 
            #pagination{
                 margin: 40 40 0;
            }
 
            ul.gp_pagination li a
            {
                 border:solid 1px;
                 border-radius:3px;
                 -moz-border-radius:3px;
                 -webkit-border-radius:3px;
                 padding:6px 9px 6px 9px;
            }
            ul.gp_pagination li
            {
                 padding-bottom:1px;
            }
            ul.gp_pagination li a:hover,
            ul.gp_pagination li a.current
            {
                 color:#FFFFFF;
                 box-shadow:0px 1px #EDEDED;
                 -moz-box-shadow:0px 1px #EDEDED;
                 -webkit-box-shadow:0px 1px #EDEDED;
            }
            ul.gp_pagination
            {
                 margin:4px 0;
                 padding:0px;
                 height:100%;
                 overflow:hidden;
                 font:12px 'Tahoma';
                 list-style-type:none;
            }
            ul.gp_pagination li
            {
                 float:left;
                 margin:0px;
                 padding:0px;
                 margin-left:5px;
            }
            ul.gp_pagination li a
            {
                 color:black;
                 display:block;
                 text-decoration:none;
                 padding:7px 10px 7px 10px;
            }
            ul.gp_pagination li a img
            {
                 border:none;
            }
            ul.gp_pagination li a
            {
                 color:#0A7EC5;
                 border-color:#8DC5E6;
                 background:#F8FCFF;
            }
            ul.gp_pagination li a:hover,
            ul.gp_pagination li a.current
            {
                 text-shadow:0px 1px #388DBE;
                 border-color:#3390CA;
                 background:#58B0E7;
                 background:-moz-linear-gradient(top, #B4F6FF 1px, #63D0FE 1px, #58B0E7);
                 background:-webkit-gradient(linear, 0 0, 0 100%, color-stop(0.02, #B4F6FF), color-stop(0.02, #63D0FE), color-stop(1, #58B0E7));
            }
 
            #container {
                 margin: 10px;
                 border: 1px solid #D0D0D0;
                 box-shadow: 0 0 8px #D0D0D0;
            }
 
            #body {
                 margin: 0 15px 0 15px;
            }
            h1 {
                 color: #444;
                 background-color: transparent;
                 border-bottom: 1px solid #D0D0D0;
                 font-size: 19px;
                 font-weight: normal;
                 margin: 0 0 14px 0;
                 padding: 14px 15px 10px 15px;
            }
 
            input[type=submit] {
                 border:solid 1px;
                 border-radius:3px;
                 -moz-border-radius:3px;
                 -webkit-border-radius:3px;
                 padding:6px 9px 6px 9px;
                 color:black;
 
                 color:#0A7EC5;
                 border-color:#8DC5E6;
                 background:#F8FCFF;
                 text-align: center;
                 text-decoration: none;
                 display: inline-block;
                 margin: 4px 2px;
                 cursor: pointer;
            }
 
            input[type=submit]:hover {
                 text-shadow:0px 1px #388DBE;
                 border-color:#3390CA;
                 background:#58B0E7;
                 background:-moz-linear-gradient(top, #B4F6FF 1px, #63D0FE 1px, #58B0E7);
                 background:-webkit-gradient(linear, 0 0, 0 100%, color-stop(0.02, #B4F6FF), color-stop(0.02, #63D0FE), color-stop(1, #58B0E7));
            }
 
            input[type=text] {
                 width: 250px;
                 box-sizing: border-box;
                 border: 2px solid #ccc;
                 border-radius: 4px;
                 padding:6px 9px 6px 9px;
                 font-size: 16px;
                 background-color: white;
                 background-image: url('searchicon.png');
                 background-position: 10px 10px;
                 background-repeat: no-repeat;;
                 -webkit-transition: width 0.4s ease-in-out;
                 transition: width 0.4s ease-in-out;
            }
 
            .gp_btn ul {
                 list-style-type: none;
                 margin: 0;
                 padding: 0;
            }
 
            .gp_btn li {
                 display: inline-block;
            }
 
            .btn2 {
                 border:solid 1px;
                 border-radius:3px;
                 -moz-border-radius:3px;
                 -webkit-border-radius:3px;
                 padding:6px 9px 6px 9px;
                 color:black;
                 display:block;
 
                 color:#0A7EC5;
                 border-color:#8DC5E6;
                 background:#F8FCFF;
                 text-align: center;
                 text-decoration: none;
                 display: inline-block;
                 margin: 4px 2px;
                 cursor: pointer;
            }
 
            .btn2:hover {
                 text-shadow:0px 1px #388DBE;
                 border-color:#3390CA;
                 background:#58B0E7;
                 background:-moz-linear-gradient(top, #B4F6FF 1px, #63D0FE 1px, #58B0E7);
                 background:-webkit-gradient(linear, 0 0, 0 100%, color-stop(0.02, #B4F6FF), color-stop(0.02, #63D0FE), color-stop(1, #58B0E7));
            }
       </style>
  </head>
  <body>
      <div id="container">
           <div id="body">
                 <h1>Data Buku</h1>
 
                 <div class="gp_btn">
                      <ul>
                           <li>
                                <?php echo form_open('C_search/cari');?>
                                     <input type="text" name="key" placeholder="Search..." size="50" required>
                                     <input type="submit" name="search" value="Search">
                                <?php echo form_close();?>
                           </li>
                           <li><a class="btn2" href="<?php echo base_url(); ?>index.php/C_search/">Reload</a></li>
                      </ul>
                 </div>
                 <table id="gp_tabel">
                 <tr>
                 <th>No</th>
                 <th>Judul</th>
                 <th>Penulis</th>
                 <th>ISBN</th>
                 </tr>
                 <?php
                if($this->uri->segment(3)){
                     $no=$this->uri->segment(3);
                }
                else{
                     $no=0;
                }
 
                 
                 foreach ($data_buku as $row)
                 {
                      $no++;
                      ?>
                      <tr align=center>
                           <td><?php echo $no;?></td>
                           <td><?php echo $row['judul'];?></td>
                           <td><?php echo $row['penulis'];?></td>
                           <td><?php echo $row['isbn'];?></td>
                      </tr>
                 <?php
                 }
                 ?>
            </table>
 
            <div id="pagination">
                 <ul class="gp_pagination">
 
                      <!-- Pagination links -->
                      <?php foreach ($links as $link) {
                           echo "<li>". $link."</li>";
                      } ?>
                 </ul>
            </div>
           </div>
       </div>
  </body>
  </html>
 ```


Simpan file views (tekan CTRL+S) dengan nama `v_paging.php` di direktori `latihan_ci3/application/views`.

Selanjutnya, kita buat file `v_searching.php`, ketik lagi kode di bawah ini ya!

```php
 <?php
 defined('BASEPATH') OR exit('No direct script access allowed');
 ?><!DOCTYPE html>
  <html>
  <head>
       <title>
            <?php echo $title; ?>
       </title>
       <style>
            body {
                 font-family: 'Raleway', sans-serif;
            }
 
            #gp_head
            {
                 text-align: center;
                 background-color: #61CAFA;
                 height: 66px;
                 margin: 0 0 -29px 0;
                 padding-top: 35px;
                 border-radius: 8px 8px 0 0;
                 color: rgb(255, 255, 255);
            }
 
            #gp_tabel {
                 font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
                 width: 80%;
                 border-collapse: collapse;
            }
 
            #gp_tabel td, #gp_tabel th {
                 font-size: 1em;
                 border: 1px solid #61CAFA;
                 padding: 3px 7px 2px 7px;
            }
 
            #gp_tabel th {
                 font-size: 1.1em;
                 text-align: center;
                 padding-top: 5px;
                 padding-bottom: 4px;
                 background-color: #61CAFA;
                 color: #ffffff;
            }
 
            #gp_tabel tr.alt td {
                 color: #000000;
                 background-color: #61CAFA;
            }
 
            #gp_tabel a {
                 border:solid 1px;
                 -webkit-border-radius:3px;
                 padding:6px 9px 6px 9px;
            }
 
            #gp_tabel a:hover,
            #gp_tabel a.current
            {
                 color:#FFFFFF;
                 box-shadow:0px 1px #EDEDED;
                 -moz-box-shadow:0px 1px #EDEDED;
                 -webkit-box-shadow:0px 1px #EDEDED;
            }
 
            #gp_tabel a:hover,
            #gp_tabel a.current
            {
                 text-shadow:0px 1px #388DBE;
                 border-color:#3390CA;
                 background:#58B0E7;
                 background:-moz-linear-gradient(top, #B4F6FF 1px, #63D0FE 1px, #58B0E7);
                 background:-webkit-gradient(linear, 0 0, 0 100%, color-stop(0.02, #B4F6FF), color-stop(0.02, #63D0FE), color-stop(1, #58B0E7));
            }
 
            #gp_tabel a
            {
                 color:#58B0E7;
                 display:block;
                 text-decoration:none;
                 padding:7px 10px 7px 10px;
            }
 
            #pagination{
                 margin: 40 40 0;
            }
 
            ul.gp_pagination li a
            {
                 border:solid 1px;
                 border-radius:3px;
                 -moz-border-radius:3px;
                 -webkit-border-radius:3px;
                 padding:6px 9px 6px 9px;
            }
            ul.gp_pagination li
            {
                 padding-bottom:1px;
            }
            ul.gp_pagination li a:hover,
            ul.gp_pagination li a.current
            {
                 color:#FFFFFF;
                 box-shadow:0px 1px #EDEDED;
                 -moz-box-shadow:0px 1px #EDEDED;
                 -webkit-box-shadow:0px 1px #EDEDED;
            }
            ul.gp_pagination
            {
                 margin:4px 0;
                 padding:0px;
                 height:100%;
                 overflow:hidden;
                 font:12px 'Tahoma';
                 list-style-type:none;
            }
            ul.gp_pagination li
            {
                 float:left;
                 margin:0px;
                 padding:0px;
                 margin-left:5px;
            }
            ul.gp_pagination li a
            {
                 color:black;
                 display:block;
                 text-decoration:none;
                 padding:7px 10px 7px 10px;
            }
            ul.gp_pagination li a img
            {
                 border:none;
            }
            ul.gp_pagination li a
            {
                 color:#0A7EC5;
                 border-color:#8DC5E6;
                 background:#F8FCFF;
            }
            ul.gp_pagination li a:hover,
            ul.gp_pagination li a.current
            {
                 text-shadow:0px 1px #388DBE;
                 border-color:#3390CA;
                 background:#58B0E7;
                 background:-moz-linear-gradient(top, #B4F6FF 1px, #63D0FE 1px, #58B0E7);
                 background:-webkit-gradient(linear, 0 0, 0 100%, color-stop(0.02, #B4F6FF), color-stop(0.02, #63D0FE), color-stop(1, #58B0E7));
            }
 
            #container {
                 margin: 10px;
                 border: 1px solid #D0D0D0;
                 box-shadow: 0 0 8px #D0D0D0;
            }
 
            #body {
                 margin: 0 15px 0 15px;
            }
            h1 {
                 color: #444;
                 background-color: transparent;
                 border-bottom: 1px solid #D0D0D0;
                 font-size: 19px;
                 font-weight: normal;
                 margin: 0 0 14px 0;
                 padding: 14px 15px 10px 15px;
            }
 
            input[type=submit] {
                 border:solid 1px;
                 border-radius:3px;
                 -moz-border-radius:3px;
                 -webkit-border-radius:3px;
                 padding:6px 9px 6px 9px;
                 color:black;
 
                 color:#0A7EC5;
                 border-color:#8DC5E6;
                 background:#F8FCFF;
                 text-align: center;
                 text-decoration: none;
                 display: inline-block;
                 margin: 4px 2px;
                 cursor: pointer;
            }
 
            input[type=submit]:hover {
                 text-shadow:0px 1px #388DBE;
                 border-color:#3390CA;
                 background:#58B0E7;
                 background:-moz-linear-gradient(top, #B4F6FF 1px, #63D0FE 1px, #58B0E7);
                 background:-webkit-gradient(linear, 0 0, 0 100%, color-stop(0.02, #B4F6FF), color-stop(0.02, #63D0FE), color-stop(1, #58B0E7));
            }
 
            input[type=text] {
                 width: 250px;
                 box-sizing: border-box;
                 border: 2px solid #ccc;
                 border-radius: 4px;
                 padding:6px 9px 6px 9px;
                 font-size: 16px;
                 background-color: white;
                 background-image: url('searchicon.png');
                 background-position: 10px 10px;
                 background-repeat: no-repeat;;
                 -webkit-transition: width 0.4s ease-in-out;
                 transition: width 0.4s ease-in-out;
            }
 
            .gp_btn ul {
                 list-style-type: none;
                 margin: 0;
                 padding: 0;
            }
 
            .gp_btn li {
                 display: inline-block;
            }
 
            .btn2 {
                 border:solid 1px;
                 border-radius:3px;
                 -moz-border-radius:3px;
                 -webkit-border-radius:3px;
                 padding:6px 9px 6px 9px;
                 color:black;
                 display:block;
 
                 color:#0A7EC5;
                 border-color:#8DC5E6;
                 background:#F8FCFF;
                 text-align: center;
                 text-decoration: none;
                 display: inline-block;
                 margin: 4px 2px;
                 cursor: pointer;
            }
 
            .btn2:hover {
                 text-shadow:0px 1px #388DBE;
                 border-color:#3390CA;
                 background:#58B0E7;
                 background:-moz-linear-gradient(top, #B4F6FF 1px, #63D0FE 1px, #58B0E7);
                 background:-webkit-gradient(linear, 0 0, 0 100%, color-stop(0.02, #B4F6FF), color-stop(0.02, #63D0FE), color-stop(1, #58B0E7));
            }
       </style>
  </head>
  <body>
      <div id="container">
           <div id="body">
                 <h1>Data Buku</h1>
 
                 <div class="gp_btn">
                      <ul>
                           <li>
                                <?php echo form_open('C_search/cari');?>
                                     <input type="text" name="key" placeholder="Search..." size="50" required>
                                     <input type="submit" name="search" value="Search">
                                <?php echo form_close();?>
                           </li>
                           <li><a class="btn2" href="<?php echo base_url(); ?>index.php/C_search/">Reload</a></li>
                      </ul>
                 </div>
 
                 <table id="gp_tabel">
                 <tr>
                 <th>No</th>
                 <th>Judul</th>
                 <th>Penulis</th>
                 <th>ISBN</th>
                 </tr>
                 <?php
                if($this->uri->segment(4)){
                     $no=$this->uri->segment(4);
                }
                else{
                     $no=0;
                }
 
                 
                 foreach ($data_buku as $row)
                 {
                      $no++;
                      ?>
                      <tr align=center>
                           <td><?php echo $no;?></td>
                           <td><?php echo $row['judul'];?></td>
                           <td><?php echo $row['penulis'];?></td>
                           <td><?php echo $row['isbn'];?></td>
                      </tr>
                 <?php
                 }
                 ?>
            </table>
 
            <div id="pagination">
                 <ul class="gp_pagination">
 
                      <!-- Pagination links -->
                      <?php foreach ($links as $link) {
                           echo "<li>". $link."</li>";
                      } ?>
                 </ul>
            </div>
           </div>
       </div>
  </body>
  </html>
 
```

Kalau sudah diketik, simpan file views (tekan CTRL+S) dengan nama `v_searching.php` di direktori `latihan_ci3/application/views`.

Nah, sekarang kita punya dua file views, file `v_paging.php` dan `v_searching.php`.

![Searching with pagination pada codeIgniter](https://4.bp.blogspot.com/-p7z7ede9z0Y/WAV2_8F-5vI/AAAAAAAAAj4/ECAcB0TEUiIFvNIKGfv_liZ3AYVPTQGcACLcB/s16000/Searching-with-pagination-pada-CodeIgniter-gambar%2B7.jpg)

## Step 6 Membuat File Controller{#step-6}
And the last one, kita akan membuat file controller dengan nama `C_search.php`. Di dalamnya terdapat sebuah class controller yang memiliki dua method yaitu `index()` dan `cari()`. Method `index()` digunakan untuk menampilkan data sebelum melakukan searching dan meload file view `v_paging.php` yang digunakan untuk menampilkan data. Sedangkan method `cari()` digunakan untuk memproses fitur searching berdasarkan parameter yang diambil dari form pencarian sebagai keyword dan meload `v_searching.php` untuk menampilkan hasil pencarian.

Sekarang buka kembali text editor, lalu ketik kode di bawah ini ya!
```php

 <?php
 defined('BASEPATH') OR exit('No direct script access allowed');
 
  class C_search extends CI_Controller {
 
       function __construct()
       {
            parent::__construct();
            $this->load->helper(array('html','url','form'));
            $this->load->library('pagination');
            $this->load->model('m_searching');
       }
 
       public function index()
       {
            $dari      = $this->uri->segment('3');
            $sampai = 5;
            $like      = '';
             
            //hitung jumlah row
            $jumlah= $this->m_searching->jumlah();
 
            //inisialisasi array
            $config = array();
 
            //set base_url untuk setiap link page
            $config['base_url'] = base_url().'index.php/C_search/index/';
 
            //hitung jumlah row
           $config['total_rows'] = $jumlah;
 
           //mengatur total data yang tampil per page
           $config['per_page'] = $sampai;
 
           //mengatur jumlah nomor page yang tampil
           $config['num_links'] = $jumlah;
 
           //mengatur tag
           $config['num_tag_open'] = '<li>';
           $config['num_tag_close'] = '</li>';
           $config['next_tag_open'] = "<li>";
           $config['next_tagl_close'] = "</li>";
           $config['prev_tag_open'] = "<li>";
           $config['prev_tagl_close'] = "</li>";
           $config['first_tag_open'] = "<li>";
           $config['first_tagl_close'] = "</li>";
           $config['last_tag_open'] = "<li>";
           $config['last_tagl_close'] = "</li>";
           $config['cur_tag_open'] = '&nbsp;<a class="current">';
           $config['cur_tag_close'] = '</a>';
           $config['next_link'] = 'Next';
           $config['prev_link'] = 'Previous';
 
           //inisialisasi array 'config' dan set ke pagination library
           $this->pagination->initialize($config);
           
           
 
           //inisialisasi array
            $data = array();
 
            //ambil data buku dari database
           $data['data_buku'] = $this->m_searching->lihat($sampai, $dari, $like);
 
           //Membuat link
           $str_links = $this->pagination->create_links();
           $data["links"] = explode('&nbsp;',$str_links );
           $data['title'] = 'Tutorial Pagination CodeIgniter | https://qadrlabs.com';
 
           $this->load->view('v_paging',$data);
      }
 
       public function cari()
       {
 
            //mengambil nilai keyword dari form pencarian
     $search = (trim($this->input->post('key',true)))? trim($this->input->post('key',true)) : '';
 
     //jika uri segmen 3 ada, maka nilai variabel $search akan diganti dengan nilai uri segmen 3
     $search = ($this->uri->segment(3)) ? $this->uri->segment(3) : $search;
 
     //mengambil nilari segmen 4 sebagai offset
            $dari      = $this->uri->segment('4');
 
            //limit data yang ditampilkan
            $sampai = 5;
 
            //inisialisasi variabel $like
            $like      = '';
 
            //mengisi nilai variabel $like dengan variabel $search, digunakan sebagai kondisi untuk menampilkan data
            if($search) $like = "(judul LIKE '%$search%')";
             
            //hitung jumlah row
            $jumlah= $this->m_searching->jumlah($like);
 
            //inisialisasi array
            $config = array();
 
            //set base_url untuk setiap link page
            $config['base_url'] = base_url().'index.php/C_search/cari/'.$search;
 
            //hitung jumlah row
           $config['total_rows'] = $jumlah;
 
           //mengatur total data yang tampil per page
           $config['per_page'] = $sampai;
 
           //mengatur jumlah nomor page yang tampil
           $config['num_links'] = $jumlah;
 
           //mengatur tag
           $config['num_tag_open'] = '<li>';
           $config['num_tag_close'] = '</li>';
           $config['next_tag_open'] = "<li>";
           $config['next_tagl_close'] = "</li>";
           $config['prev_tag_open'] = "<li>";
           $config['prev_tagl_close'] = "</li>";
           $config['first_tag_open'] = "<li>";
           $config['first_tagl_close'] = "</li>";
           $config['last_tag_open'] = "<li>";
           $config['last_tagl_close'] = "</li>";
           $config['cur_tag_open'] = '&nbsp;<a class="current">';
           $config['cur_tag_close'] = '</a>';
           $config['next_link'] = 'Next';
           $config['prev_link'] = 'Previous';
 
           //inisialisasi array 'config' dan set ke pagination library
           $this->pagination->initialize($config);
           
           
 
           //inisialisasi array
            $data = array();
 
            //ambil data buku dari database
           $data['data_buku'] = $this->m_searching->lihat($sampai, $dari, $like);
 
           //Membuat link
           $str_links = $this->pagination->create_links();
           $data["links"] = explode('&nbsp;',$str_links );
           $data['title'] = 'Tutorial Searching with Pagination CodeIgniter | https://qadrlabs.com';
 
           $this->load->view('v_searching',$data);
      }  
 }
 
```

Setelah itu kita simpan file controller (tekan CTRL+S) dengan nama `C_search.php` dan kita simpan di direktori `latihan_ci3/application/controllers`.

![membuat class controller](https://4.bp.blogspot.com/-QMXzDp4AelE/WAV2mhsOX9I/AAAAAAAAAjg/NI2wpB-kqWkN4H6z8ZehMIuvQGq7_dfZQCEw/s16000/Searching-with-pagination-pada-CodeIgniter-gambar%2B8.jpg)

## Step 7 - Uji Coba Project{#step-7}
Finally, semua file sudah kita buat. Jadi, kita punya empat file, yaitu file models `M_searching.php`, file views `v_paging.php` dan `v_searching.php` dan terakhir file controllers `C_search.php`. Nah, sekarang kita coba running project Searching with Pagination pada CodeIgniter yang baru saja kita buat. Buka browser, lalu ketik alamat:
```
 http://localhost/latihan_ci3/index.php/C_search/
```

Voila~, di browser akan tampil seperti gambar di bawah ini!

![uji coba - Searching with pagination pada codeIgniter](https://4.bp.blogspot.com/-iXGLwvVwDLc/WAV2o4gVV-I/AAAAAAAAAjs/Y54KU8Mn1a403akOuCkK2sxZPPOibq9JQCEw/s16000/Searching-with-pagination-pada-CodeIgniter-gambar%2B9.jpg)


Ya, ada tabel yang berisi data buku. Di atas tabel, ada form untuk melakukan proses pencarian atau searching dan juga tombol Reload untuk menampilkan kembali tabel buku. Nah, sekarang kita coba isi teks dengan keyword, lalu kita klik tombol search. Maka, hasil pencarian akan di tampilkan pada tabel.

![Searching with pagination pada codeIgniter](https://3.bp.blogspot.com/-5XCpHlEYqKU/WAV2XuWDvsI/AAAAAAAAAjM/uShTHTHj3t0MWbiz2qSM82JrUKTt5h9XgCEw/s16000/Searching-with-pagination-pada-CodeIgniter-gambar%2B10.jpg)


![searching with pagination pada codeigniter](https://3.bp.blogspot.com/-KNFYxbjyo90/WAV2XoAjUkI/AAAAAAAAAjE/CbRThetxzyUV9UD6FSoCFJdm0kJ2p8ikwCEw/s16000/Searching-with-pagination-pada-CodeIgniter-gambar%2B11.jpg)


Jika, data yang ditampilkan lebih dari 5, maka akan muncul pagination untuk membatasi data yang ditampilkan. Selain itu, kamu bisa juga melihat keyword pencarian ada pada url dan dijadikan sebagai parameter dalam pagination.

![Searching with pagination pada codeIgniter](https://4.bp.blogspot.com/-jd7vLMKRXiw/WAV2YkRaHUI/AAAAAAAAAjY/RzcF5S2J-J8k_EoJ8yZiktz3JdOURpAPwCEw/s16000/Searching-with-pagination-pada-CodeIgniter-gambar%2B12.jpg)


## Penutup{#penutup}
Dengan adanya fitur searching ini dapat memudahkan pengguna aplikasi yang kita bangun untuk menemukan data yang diinginkan dengan cepat, tepat dan efisien. Terima kasih sudah membaca tutorial Searching with Pagination Pada CodeIgniter ini sampai akhir. Apabila ada pertanyaan, kritik, saran, request atau ingin berkontribusi bisa disampaikan melalui kolom komentar.

Semoga bermanfaat. Sampai jumpai di edisi berikutnya. Tetap semangat berkarya ya! Happy coding!

## Referensi:{#referensi}
- Web Official CodeIgniter @ https://codeigniter.com
- Documentasi CodeIgniter @ https://codeigniter.com/user_guide/
- Pagination CodeIgniter @ https://codeigniter.com/user_guide/libraries/pagination.html
- Database Reference @ https://codeigniter.com/user_guide/database/index.html