---
title: "Mudahnya Membuat Pagination Pada CodeIgniter"
slug: "mudahnya-membuat-pagination-pada-codeigniter"
category: "Codeigniter"
date: "2016-02-10"
status: "published"
---

Pernahkah Anda mengalami situasi di mana aplikasi web yang Anda kembangkan harus menampilkan ratusan, bahkan ribuan data dalam satu halaman? Situasi ini kerap kali menjadi tantangan serius bagi para developer, terutama ketika berhadapan dengan database yang besar.

Bayangkan skenario berikut: Anda memiliki e-commerce dengan katalog produk mencapai ribuan item. Tanpa sistem navigasi yang tepat, pengunjung website Anda akan menghadapi:
- Waktu loading yang sangat lambat
- Scrolling yang tidak berkesudahan
- Pengalaman pengguna yang buruk
- Potensi kehilangan pelanggan akibat frustasi

Namun, ada kabar menggembirakan. CodeIgniter, framework PHP yang powerful, hadir dengan solusi elegannya: Pagination Class. Library bawaan ini memungkinkan Anda mengimplementasikan sistem navigasi halaman yang:
- Mudah diimplementasikan
- Fully customizable
- Kinerja optimal
- User-friendly

Pagination sendiri adalah sistem navigasi yang memungkinkan pembagian konten ke dalam beberapa halaman, mirip dengan yang Anda lihat di mesin pencari Google:

```
« First < 1 2 3 4 5 > Last »
```

Dalam tutorial ketiga dari seri tutorial [Belajar CodeIgniter 3](https://qadrlabs.com/series/belajar-codeigniter-3) ini, saya akan memandu Anda langkah demi langkah dalam mengimplementasikan sistem pagination yang profesional. Kita akan membangun sebuah project praktis yang mendemonstrasikan bagaimana:
1. Mengintegrasikan Pagination Class dengan aplikasi Anda
2. Mengkustomisasi tampilan sesuai kebutuhan
3. Mengoptimalkan performa loading data

Project ini akan memberikan Anda pemahaman mendalam tentang bagaimana memanfaatkan kekuatan CodeIgniter untuk menciptakan pengalaman pengguna yang superior melalui implementasi pagination yang efektif.

Siap untuk memulai perjalanan menuju aplikasi web yang lebih profesional? Mari kita mulai dengan langkah pertama...

## Step 1- Persiapan Development{#step-1}
Ok, sebelum memulai kita persiapkan dulu lab untuk project kita ya! Kita cek dulu apa saja yang kita gunakan dalam tutorial pagination CodeIgniter. Berikut ini adalah minimum spesifikasi yang saya gunakan:

  [a] PHP 5.5.35

  [b] MySQL / MariaDB

  [c] Webserver Apache

  [d] CodeIgniter versi 3.1.0

Yep, masih sama seperti di tutorial sebelumnya, saya menggunakan XAMPP versi 5.5.35, so, semua yang diperlukan sudah ada di dalam paket XAMPP tersebut, selain CodeIgniter tentunya.

Nah, untuk CodeIgniter, kalau kamu mengikuti tutorial sebelumnya, sudah pasti kamu sudah men-download framework CodeIgniter. Untuk kamu yang belum punya, kamu bisa langsung download di web official CodeIgniter [di sini](https://codeigniter.com/download). Pada halaman download terdapat dua versi codeigniter, yaitu codeigniter 4 dan codeigniter 3. Sekarang kita tekan tombol download untuk codeigniter 3. 

Setelah proses download selesai, kita extract CodeIgniter, lalu pindahkan folder CodeIgniter (hasil extract) ke document root (di folder `xampp/htdocs`). Kemudian, rename folder CodeIgniter (hasil extract) jadi `ci3`. FYI, nama folder ini nanti kita gunakan di dalam konfigurasi `base_url`.

Ok, lab sudah kita siapkan!

## Step 2 - Membuat Database{#step-2}

Ya, pagination itu sudah pasti berhubungan dengan menampilkan data dari database. Oleh karena itu, sekarang kita buat dulu databasenya. Kita akan buat database menggunakan phpMyAdmin. Sekarang kita buka phpMyAdmin di browser, lalu kita buat database dengan nama `dbci3`. Selanjutnya, kita buat tabel dengan nama `tbl_buku` dengan struktur tabel seperti gambar di bawah ini:

![Membuat database](https://3.bp.blogspot.com/-Ob17J2qJx4k/V_f_rOQuNmI/AAAAAAAAAhE/rbXcPrG6u-UTyAMtOZiPqX1WIZ9Bgl_7QCEw/s1600/Mudahnya-membuat-pagination-pada-CodeIgniter-gambar%2B1.jpg)

Sekarang klik menu SQL di phpMyAdmin, lalu run perintah SQL di bawah ini:


```sql
 -- --------------------------------------------------------
 
 --
 -- Table structure for table `tbl_buku`
 --
 
 CREATE TABLE `tbl_buku` (
  `id_buku` int(11) NOT NULL,
  `judul` text COLLATE utf8_unicode_ci NOT NULL,
  `penulis` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `penerbit` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tahun_terbit` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL
 ) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
 
 --
 -- Dumping data for table `tbl_buku`
 --
 
 INSERT INTO `tbl_buku` (`id_buku`, `judul`, `penulis`, `penerbit`, `tahun_terbit`) VALUES
 (1, 'PHP 5 for dummies', 'Janet Valade', 'Wiley Publishing, Inc', '2004'),
 (2, 'Linux In a Nutshell', 'Ellen Siever dkk', 'OReilly Media', '2005'),
 (3, 'The Definitive Guide to MySQL 5', 'Michael Kofler', 'Apress', '2005'),
 (4, 'Cathedral and the Bazaar: Musings on Linux and Open Source by an Accidental Revolutionary', 'Eric S. Raymond', 'O’Reilly Media, Inc', '2001'),
 (5, 'Producing open source software : how to run a successful free software project', 'Karl Fogel', '-', '2005'),
 (6, 'PostgreSQL : a comprehensive guide to building, programming, and administering PostgreSQL databases', 'Korry Douglas', 'Sams Publishing', '2003'),
 (7, 'Web application architecture : principles, protocols, and practices', 'Leon Shklar', 'Wiley Publishing, Inc', '2003'),
 (8, 'Ajax : creating Web pages with asynchronous JavaScript and XML ', 'Edmond Woychowsky', 'Prentice Hall', '2007'),
 (9, 'The organization of information', 'Arlene G. Taylor', 'Libraries Unlimited', '2004'),
 (10, 'Library and Information Center Management', 'Robert D. Stueart', 'Libraries Unlimited', '2007'), 
 (11, 'Information Architecture for the World Wide Web: Designing Large-Scale Web Sites', 'Peter Morville', 'O’Reilly Media, Inc', '2002'),
 (12, 'Corruption and development', 'Sarah Bracking', 'Palgrave Macmillan', '1998'),
 (13, 'Corruption and development : the anti-corruption campaigns', 'Sarah Bracking', 'Palgrave Macmillan', '2007'),
 (14, 'Pigs at the trough : how corporate greed and political corruption are undermining America', '-', '-', '2003'),
 (15, 'Lords of poverty : the power, prestige, and corruption of the international aid business', '-', '-', '1994');
 
 --
 -- Indexes for dumped tables
 --
 
 --
 -- Indexes for table `tbl_buku`
 --
 ALTER TABLE `tbl_buku`
  ADD PRIMARY KEY (`id_buku`);
 
 --
 -- AUTO_INCREMENT for dumped tables
 --
 
 --
 -- AUTO_INCREMENT for table `tbl_buku`
 --
 ALTER TABLE `tbl_buku`
  MODIFY `id_buku` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

```
Kita copy `sql` di atas, lalu paste di textarea, kemudian klik tombol Go yang ada di kanan bawah.



![Membuat tabel](https://4.bp.blogspot.com/-rLZFc0HCvZ4/V_f_ruXKhHI/AAAAAAAAAhI/E458ZF9ALC0r0gTaVYM8JufU-zPV5WLSQCEw/s1600/Mudahnya-membuat-pagination-pada-CodeIgniter-gambar%2B2.jpg)

Kita bisa lihat tabelnya setelah perintah SQL dieksekusi. Selain itu kita bisa lihat juga ada sample data yang nanti kita gunakan untuk pagination.

## Step 3 - Konfigurasi Database dan Base Url{#step-3}

Sebagai pengingat, ada beberapa konfigurasi yang harus dilakukan dalam membangun aplikasi menggunakan framework CodeIgniter, yaitu mengatur konfigurasi `database` dan `base_url`. Nah, pertama kita atur konfigurasi database dulu ya! Untuk mengatur konfigurasi database, kita harus mengedit file `database.php` yang ada di direktori ```ci3/application/config```. Sekarang buka file ```database.php``` dengan teks editor kesayanganmu, lalu cek sekitar line 76, kemudian kita atur konfigurasinya seperti pada gambar:


![Konfigurasi](https://1.bp.blogspot.com/-ap8eOiv4zf8/V_f_r6eHgjI/AAAAAAAAAhM/61FzrSLwu9c9uidktTXl8sv-i8QlAohywCEw/s1600/Mudahnya-membuat-pagination-pada-CodeIgniter-gambar%2B3.jpg)

Kalau sudah, save lagi file ```database.php```.

Untuk menggunakan database, kita harus mengaktifkan library database punya CodeIgniter. Nah, sekarang kita buka file ```autoload.php``` yang ada di direktori ```ci3/application/config```. Cek line ke 61, lalu isi array dengan database, seperti gambar di bawah:

![Konfigurasi](https://4.bp.blogspot.com/-yQjXVOODD8Y/V_f_sWYre3I/AAAAAAAAAhQ/3Es69zWYw3EbsGlfFJprqQ3HR0bWGk5awCEw/s1600/Mudahnya-membuat-pagination-pada-CodeIgniter-gambar%2B4.jpg)

Ya, save lagi file ```autoload.php``` kalau sudah diedit.

Berikutnya kita atur konfigurasi base url. Untuk mengatur base_url kita buka file ```config.php```. Yep, kamu benar.. filenya ada di direktori ```ci3/application/config```. Sekarang kita edit line ke 26, kita isi dengan ```http://localhost/ci3/``` seperti gambar di bawah:

![Konfigurasi Base Url](https://2.bp.blogspot.com/-P2JSdaD2QCk/V_f_sltV6TI/AAAAAAAAAhY/MFqime-ZWYw-F6rJJtSCNpy0zOehsB7CACEw/s1600/Mudahnya-membuat-pagination-pada-CodeIgniter-gambar%2B5.jpg)

Ya, disave lagi ya file ```config.php``` nya.

## Step 4 - Membuat Model{#step-4}
Model Di dalam konsep MVC digunakan untuk menangani aneka aktifitas yang berhubungan dengan manipulasi data dalam database. Sekarang kita akan membuat file model dengan nama ```M_buku.php```. Di dalam file tersebut terdapat class model dengan nama ```M_buku```. Ya, nama class dan nama file di dalam CodeIgniter itu harus sama. Kawan, di dalam class ```M_buku``` ini, kita akan membuat 2 method yang akan kita gunakan untuk membuat pagination, yaitu:
1. `lihat()` :: Mengambil data dari tbl_buku, terdapat dua parameter untuk limit dan juga offset.
2. `jumlah()` :: Menghitung jumlah row data yang ada pada `tbl_buku`

Ok, sekarang kita buka lagi teks editor, lalu buat file models dengan nama ```M_buku.php``` dan simpan di direktori ```application/model/```, berikut ini adalah script-nya:

```php

<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class M_buku extends CI_Model{

    //ambil data
    function lihat($sampai,$dari){
        $query = $this->db->get('tbl_buku',$sampai,$dari);
        return $query->result_array();
    }

    //hitung jumlah row
    function jumlah(){
        $query = $this->db->get('tbl_buku');
        return $query->num_rows();
    }
}

```

Setelah selesai, jangan lupa save file ```M_buku.php``` di direktori ```application/models```.

## Step 5 - Membuat View{#step-5}

Ya, file view ini digunakan untuk menampilkan data dari ```tbl_buku```. Sekarang buka lagi teks editor kesayanganmu lalu ketik script di bawah ini:
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
    </style>
</head>
<body>
    <div id="container">
        <div id="body">
                <h1>Data Buku</h1>
                <table id="gp_tabel">
                <tr>
                <th>No</th>
                <th>Judul</th>
                <th>Penulis</th>
                <th>Penerbit</th>
                <th>Tahun Terbit</th>
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
                        <td><?php echo $row['penerbit'];?></td>
                        <td><?php echo $row['tahun_terbit'];?></td>
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

Kalau sudah, save file dengan nama ```vw_paging.php``` di folder views.

## Step 6 - Membuat File Controller{#step-6}
Selanjutnya kita akan membuat file controller dengan nama ```Paging_controller.php```. Sama seperti file model, file controller memiliki sebuah class dengan nama yang sama, yaitu class ```Paging_controller```. Untuk penjelasan scriptnya bisa dilihat langsung pada scriptnya. Dan berikut ini script ```Paging_controller.php```:
```php
<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Paging_controller extends CI_Controller {

    function __construct()
    {
        parent::__construct();
        $this->load->helper(array('html','url'));
        $this->load->library('pagination');
        $this->load->model('m_buku');
    }

    public function index()
    {
        //hitung jumlah row
        $jumlah= $this->m_buku->jumlah();

        //inisialisasi array
        $config = array();

        //set base_url untuk setiap link page
        $config['base_url'] = base_url().'index.php/paging_controller/index/';

        //hitung jumlah row
        $config['total_rows'] = $jumlah;

        //mengatur total data yang tampil per page
        $config['per_page'] = 5;

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
        
        $dari = $this->uri->segment('3');

        //inisialisasi array
        $data = array();

        //ambil data buku dari database
        $data['data_buku'] = $this->m_buku->lihat($config['per_page'],$dari);

        //Membuat link
        $str_links = $this->pagination->create_links();
        $data["links"] = explode('&nbsp;',$str_links );
        $data['title'] = 'Tutorial Pagination CodeIgniter | https://recodeku.blogspot.com';

        $this->load->view('vw_paging',$data);
    }
}
```

Save file dengan nama ```Paging_controller.php``` di direktori ```application/controller```.

## Step 7 - Uji Coba Project{#step-7}

Ya, finally, semua file sudah kita ketik dan sekarang waktunya kita mencoba project membuat pagination dengan CodeIgniter. Sekarang buka browser lalu akses project dengan link berikut di browser:

```
http://localhost/ci3/index.php/paging_controller
```

*Tadaa~*, project kita berhasi diakses seperti gambar di bawah:

![Uji coba](https://2.bp.blogspot.com/-k-4C2bzRunY/V_f_trMin2I/AAAAAAAAAho/SL5F79NDyF006Mxo9EZNlx1SgpAE04VAgCEw/s1600/Mudahnya-membuat-pagination-pada-CodeIgniter-gambar%2B9.jpg)

Kita coba klik page berikutnya. Voila~ kita pindah ke halaman berikutnya.


![Uji coba pindah page](https://2.bp.blogspot.com/-cmPMwt3sQG8/V_f_rLc9TyI/AAAAAAAAAhA/kfzNzjlh_6sdVra0Z12Fkn2310IZ6WaJACEw/s1600/Mudahnya-membuat-pagination-pada-CodeIgniter-gambar%2B10.jpg)


.
.
.

## Penutup
Gimana? Mudah bukan? Membuat pagination memang bisa dilakukan dengan berbagai cara, tetapi dengan memanfaatkan library pagination pada framework CodeIgniter, kita bisa menghemat banyak waktu dan usaha. Hanya dengan sedikit pengaturan pada opsi konfigurasi, pagination dapat langsung diimplementasikan dengan mudah. Selain itu, kita juga memiliki fleksibilitas untuk menyesuaikan tampilan link pagination sesuai dengan kebutuhan aplikasi kita, memberikan kontrol penuh terhadap desain dan pengalaman pengguna.

Jika Anda membutuhkan informasi lebih mendalam, jangan ragu untuk merujuk pada user guide resmi dari CodeIgniter. Panduan tersebut menyediakan semua detail yang diperlukan untuk menyesuaikan pagination lebih lanjut dan memastikan pengguna mendapatkan pengalaman terbaik.

Terima kasih telah mengikuti tutorial Membuat Pagination Pada CodeIgniter hingga akhir. Jika Anda memiliki pertanyaan, kritik, saran, atau bahkan ide untuk kontribusi di masa depan, jangan ragu untuk menuliskannya di kolom komentar.

Semoga tutorial ini bermanfaat dan dapat membantu Anda dalam pengembangan proyek. Selamat coding, dan semoga sukses selalu!