---
title: "Belajar PHP OOP Part 13 CRUD Dengan PDO"
slug: "belajar-php-oop-part-13-crud-dengan-pdo"
category: "OOP"
date: "2016-08-16"
status: "published"
---

Selamat datang di tutorial PHP OOP! Di artikel ke-13 dari serial [Belajar PHP OOP](https://qadrlabs.com/series/belajar-php-oop) ini, kita akan mempelajari cara membuat aplikasi CRUD menggunakan PDO (PHP Data Objects). Tutorial ini akan memadukan konsep Object-Oriented Programming (OOP) yang telah kita pelajari sebelumnya dengan implementasi praktis menggunakan PDO untuk operasi database.

CRUD - singkatan dari Create, Read, Update, Delete - adalah operasi dasar yang akan kita temui di hampir semua aplikasi web. Dalam tutorial ini, kita akan membuat aplikasi pengelolaan data barang yang mencakup semua operasi tersebut. Dengan menggunakan PDO, kita tidak hanya belajar cara modern dalam menangani database di PHP, tetapi juga memastikan aplikasi kita aman dari SQL injection dan mudah dikembangkan di masa depan.
Mari kita mulai dengan memahami apa itu PDO dan mengapa teknologi ini menjadi pilihan utama para developer PHP modern.

## Apa itu PDO?{#apa-itu-pdo}
PDO (PHP Data Objects) adalah interface database yang powerful di PHP, dirancang untuk membuat kode database kita lebih aman, portable, dan mudah dikelola. Bayangkan PDO sebagai jembatan universal yang menghubungkan aplikasi PHP kita dengan berbagai jenis database tanpa perlu mengubah kode aplikasi kita secara signifikan.

### Keunggulan Menggunakan PDO:

1. **Fleksibilitas Database yang Luar Biasa**
   - Bekerja dengan MySQL? PostgreSQL? SQLite? PDO menangani semuanya
   - Cukup ubah string koneksi, kode kita tetap sama
   - Migrasi antar database menjadi lebih mudah

2. **Keamanan yang Terjamin**
   - Prepared statements mencegah SQL injection secara efektif
   - Parameter binding yang aman dan mudah digunakan
   - Mengelola koneksi database dengan lebih aman

3. **Penanganan Error yang Lebih Baik**
   - Exception handling yang konsisten
   - Debugging yang lebih mudah dengan pesan error yang jelas
   - Mode error yang dapat dikonfigurasi

4. **Performa yang Optimal**
   - Prepared statements yang dapat digunakan ulang
   - Manajemen koneksi yang efisien
   - Dukungan untuk transaksi database

### Contoh Penggunaan Dasar PDO:

```php
try {
    // Membuat koneksi database
    $pdo = new PDO(
        'mysql:host=localhost;dbname=toko;charset=utf8',
        'username',
        'password',
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
        ]
    );
    
    // Menggunakan prepared statement
    $stmt = $pdo->prepare('SELECT * FROM products WHERE kategori = ?');
    $stmt->execute(['elektronik']);
    
    // Mengambil data
    $products = $stmt->fetchAll();
    
} catch(PDOException $e) {
    // Menangani error dengan aman
    error_log($e->getMessage());
    throw new Exception('Database error: silakan coba beberapa saat lagi');
}
```

### Best Practices Menggunakan PDO:

1. Selalu gunakan prepared statements untuk query yang memiliki parameter
2. Aktifkan error mode PDO::ERRMODE_EXCEPTION untuk debugging yang lebih baik
3. Gunakan try-catch untuk menangani error dengan elegan
4. Tutup koneksi database setelah selesai digunakan
5. Manfaatkan fitur transaksi untuk operasi database yang kompleks

PDO telah menjadi standar de facto untuk koneksi database di PHP modern, menggantikan ekstensi mysql yang sudah usang. Dengan menggunakan PDO, kita tidak hanya membuat aplikasi yang lebih aman, tetapi juga lebih mudah dimaintain dan dikembangkan di masa depan.

## Overview{#overview}
Pada tutorial kali ini kita akan membuat aplikasi crud menggunakan PDO dengan studi kasus membuat fitur untuk mengelola data barang pada aplikasi kasir. 

### Apa yang Akan Kita Bangun
Dalam tutorial ini, kita akan membuat aplikasi pengelolaan data barang untuk sistem kasir dengan fitur-fitur:
- Manajemen data barang (Create, Read, Update, Delete)
- Interface yang responsif menggunakan Bootstrap
- Sistem paging untuk menampilkan data
- Form validasi untuk input data
- Penanganan error yang baik
- Keamanan database dengan PDO

### Teknologi yang Digunakan
- PHP (dengan pendekatan OOP)
- PDO untuk koneksi database
- MySQL sebagai database
- Bootstrap untuk frontend
- HTML5 & CSS3

### Konsep yang Akan Dipelajari
1. **Object-Oriented Programming di PHP**
   - Class dan Object
   - Constructor dan Properties
   - Methods dan Visibility
   - Error Handling

2. **Database Handling dengan PDO**
   - Koneksi database yang aman
   - Prepared Statements
   - Query Execution
   - Result Handling

3. **Modern Web Development**
   - Responsive Design
   - Form Handling
   - Data Validation
   - Pagination System

### Goals Tutorial
Setelah menyelesaikan tutorial ini, Anda akan mampu:
1. Memahami implementasi praktis OOP di PHP
2. Menggunakan PDO untuk operasi database yang aman
3. Membuat sistem CRUD yang terstruktur
4. Menerapkan best practices dalam pengembangan web
5. Membangun dasar yang kuat untuk aplikasi PHP yang lebih kompleks

### Prerequisites
- Pemahaman dasar PHP
- Familiar dengan konsep database
- Web server (XAMPP/WAMP) terinstall
- Text editor/IDE
- Koneksi internet untuk mengakses Bootstrap CDN

### Struktur Project
```
aplikasi_kasir/
├── dbconfig.php        # Konfigurasi database
├── barang_class.php    # Class utama aplikasi
├── index.php          # Halaman utama/listing
├── add.php           # Form tambah data
├── edit.php          # Form edit data
└── hapus.php         # Proses hapus data
```

Tutorial ini dirancang dengan pendekatan step-by-step yang sistematis, memungkinkan Anda untuk memahami setiap konsep secara mendalam sambil membangun aplikasi yang fungsional. Mari kita mulai coding!

## Step 1 - Persiapan direktori project{#step-1}
Sebelum memulai coding, pertama kita harus menyiapkan direktori project kita. Kita buat folder baru di dalam folder `htdocs` (asumsi kita sama-sama pakai Xampp) kita kasih nama `aplikasi_kasir`. Ini contoh saja, kamu boleh kasih nama apa aja, bebas kok..

Nanti folder `aplikasi_kasir` ini akan kita gunakan untuk menyimpan file-file php. FYI, Karena User Interfacenya saya menggunakan Bootsrap yang diload melalui CDN, mungkin kamu perlu juga siapin koneksi internet. Atau kamu bisa download Bootstrapnya terlebih dahulu di [tautan](https://getbootstrap.com/) ini.

Selanjutnya buka folder `aplikasi_kasir` di code editor. Kalau menggunakan visual studio code, buka menu **File** lalu pilih sub menu **Open Folder** lalu pilih folder `C:/xampp/htdocs/aplikasi_kasir`, lalu klik tombol **Open** untuk membuka folder di visual studio code.

## Step 2 - Membuat Database dan Table{#step-2}
Selanjutnya kita akan buat database. Karena aplikasi yang akan kita buat itu berhubungan dengan manipulasi data atau CRUD, tentu saja kita harus buat database terlebih dahulu. 

Sekarang kita buat database baru menggunakan phpMyAdmin. Sebagai contoh, database ini kita beri nama `belajar_oop`. Setelah itu, kita buat table di dalam database yang baru saja kita buat, saya kasih nama `barang` dengan struktur tabel seperti gambar berikut:

![struktur table untuk studi kasus membuat crud php oop pdo](https://4.bp.blogspot.com/-LAP0ZeBTspM/V7M-3ri1sUI/AAAAAAAAAdA/eV74dPSfQ5YjGF_s83c48xh4ytrPt2oXACLcB/s16000/Belajar%2BPHP%2BOOP%2Bgambar%2B1.png)

Oh iya, kita juga bisa buat table pakai perintah SQL di bawah ini lho! Di phpmyadmin, di database `belajar_oop`, kita klik menu SQL, lalu copy-paste, perintah sql di bawah ini.
```bash
 CREATE TABLE `barang` (

  `id_barang` varchar(10) NOT NULL,
  `nama` varchar(50) NOT NULL,
  `stok` int(10) NOT NULL,
  `harga` int(25) NOT NULL,
  PRIMARY KEY (`id_barang`)

 ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
```

## Step 3 - Coding Konfigurasi Database{#step-3}
Setelah database dan tabel kita buat, selanjutnya kita buat file untuk mengkonfigurasi database. 

Pada tahapan ini kita sudah mulai masuk ke coding.

Buka text editor kesayanganmu, lalu ketik sintaks di bawah ini:
```php
<?php

try {

    $con = new PDO('mysql:host=localhost;dbname=belajar_oop', 'root', '', array(PDO::ATTR_PERSISTENT => true));
} catch (PDOException $e) {

    echo $e->getMessage();
}

include_once 'barang_class.php';

$brg = new barang($con);

?>
```

Simpan filenya di folder `aplikasi_kasir` dengan nama `dbconfig.php`.

Bisa kita lihat, pada baris ke 5, kita akan membuat object `$con` menggunakan Class PDO, bersamaan dengan informasi data source name dan user credential pada parameternya, yaitu localhost untuk hostnya, belajar_oop untuk databasenya, root untuk username dan password (isi password kalau mysql kamu pakai password).

Selain konfigurasi database, kita juga akan memanggil file `barang_class.php` menggunakan fungsi include_once pada baris ke 12. Lalu kita buat sebuah object dengan `$brg`. Nanti kita bakalan pakai object ini di file lainnya.

## Step 4 - Coding Class dan Halaman User Interface{#step-4}
Ya, it's coding time! Langkah selanjutnya kita akan membuat beberapa file php, yaitu `barang_class.php`, `index.php`, `add.php`, `edit.php`, dan `hapus.php`. File-file php tersebut dan `file dbconfig.php` kita simpan dalam folder `aplikasi_kasir`. 

Sekarang kita buat file `barang_class.php`. Buka kembali text kesayanganmu, lalu ketik sintaks di bawah ini:
```php
<?php

class barang
{
    private $db;


    public function __construct($con)
    {
        $this->db = $con;
    }

    ### Start : fungsi insert data ke database ###

    public function insertData($id_barang, $nama, $stok, $harga)
    {
        try {
            $stmt = $this->db->prepare("INSERT INTO barang(id_barang,nama,stok,harga) VALUES(:id_barang, :nama, :stok, :harga)");

            $stmt->bindparam(":id_barang", $id_barang);

            $stmt->bindparam(":nama", $nama);

            $stmt->bindparam(":stok", $stok);

            $stmt->bindparam(":harga", $harga);

            $stmt->execute();

            return true;
        } catch (PDOException $e) {
            echo $e->getMessage();

            return false;
        }
    }

    ### End : fungsi insert data ke database ###

    ### Start : fungsi ambil data dari database ###

    public function getID($id_barang)
    {
        $stmt = $this->db->prepare("SELECT * FROM barang WHERE id_barang=:id_barang");

        $stmt->execute(array(":id_barang" => $id_barang));

        $data = $stmt->fetch(PDO::FETCH_ASSOC);

        return $data;
    }

    ### End: fungsi ambil data dari database ###

    ### Start : fungsi untuk menampilkan data dari database ###

    public function viewData($query)
    {
        $stmt = $this->db->prepare($query);

        $stmt->execute();

        if ($stmt->rowCount() > 0) {
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                ?>

                <tr>

                    <td><?php echo($row['id_barang']); ?></td>

                    <td><?php echo($row['nama']); ?></td>

                    <td><?php echo($row['stok']); ?></td>

                    <td><?php echo($row['harga']); ?></td>

                    <td align="center">

                        <a href="edit.php?edit_id=<?php echo($row['id_barang']); ?>">

                            <i class="glyphicon glyphicon-edit"></i></a>

                    </td>

                    <td align="center">

                        <a href="hapus.php?delete_id=<?php echo($row['id_barang']); ?>">

                            <i class="glyphicon glyphicon-remove-circle"></i></a>

                    </td>

                </tr>

                <?php
            }
        } else {
            ?>

            <tr>

                <td>Data tidak ditemukan...</td>

            </tr>

            <?php
        }
    }

    ### End : fungsi untuk menampilkan data dari database ###

    ### Start : fungsi untuk memperbaharui data###

    public function updateData($id_barang, $nama, $stok, $harga)
    {
        try {
            $stmt = $this->db->prepare("UPDATE barang SET nama=:nama,

                                                                    stok=:stok,

                                                                    harga=:harga

                                                                WHERE id_barang=:id_barang ");

            $stmt->bindparam(":id_barang", $id_barang);

            $stmt->bindparam(":nama", $nama);

            $stmt->bindparam(":stok", $stok);

            $stmt->bindparam(":harga", $harga);

            $stmt->execute();

            return true;
        } catch (PDOException $e) {
            echo $e->getMessage();

            return false;
        }
    }

    ### End : fungsi untuk memperbaharui data###

    ### Start : fungsi untuk menghapus data###

    public function deleteData($id_barang)
    {
        $stmt = $this->db->prepare("DELETE FROM barang WHERE id_barang=:id_barang");

        $stmt->bindparam(":id_barang", $id_barang);

        $stmt->execute();

        return true;
    }

    ### End : fungsi untuk menghapus data###

    ### Start : fungsi paging###

    public function paging($query, $records_per_page)
    {
        $starting_position = 0;

        if (isset($_GET["page_no"])) {
            $starting_position = ($_GET["page_no"] - 1) * $records_per_page;
        }

        $query2 = $query . " limit $starting_position,$records_per_page";

        return $query2;
    }

    ### End : fungsi paging###

    ### Start : fungsi pindah page###

    public function paginglink($query, $records_per_page)
    {
        $self = $_SERVER['PHP_SELF'];

        $stmt = $this->db->prepare($query);

        $stmt->execute();

        $total_no_of_records = $stmt->rowCount();

        if ($total_no_of_records > 0) {
            ?>
            <ul class="pagination"><?php

            $total_no_of_pages = ceil($total_no_of_records / $records_per_page);

            $current_page = 1;

            if (isset($_GET["page_no"])) {
                $current_page = $_GET["page_no"];
            }

            if ($current_page != 1) {
                $previous = $current_page - 1;

                echo "<li><a href='" . $self . "?page_no=1'>First</a></li>";

                echo "<li><a href='" . $self . "?page_no=" . $previous . "'>Previous</a></li>";
            }

            for ($i = 1; $i <= $total_no_of_pages; $i++) {
                if ($i == $current_page) {
                    echo "<li><a href='" . $self . "?page_no=" . $i . "' style='color:red;'>" . $i . "</a></li>";
                } else {
                    echo "<li><a href='" . $self . "?page_no=" . $i . "'>" . $i . "</a></li>";
                }
            }

            if ($current_page != $total_no_of_pages) {
                $next = $current_page + 1;

                echo "<li><a href='" . $self . "?page_no=" . $next . "'>Next</a></li>";

                echo "<li><a href='" . $self . "?page_no=" . $total_no_of_pages . "'>Last</a></li>";
            } ?></ul><?php
        }
    }

    ### End : fungsi pindah page###
}
```

Simpan kembali file `barang_class.php`.

Selanjutnya, kita buat file `index.php` yang digunakan untuk menampilkan data barang dalam tabel. Buka kembali teks editor lalu ketik sintaks di bawah ini:
```php
 <?php

include_once 'dbconfig.php';

?>

<!DOCTYPE html>

<html lang="en">

<head>

    <title>Aplikasi CRUD Sederhana Dengan PHP OOP PDO</title>

    <meta charset="utf-8">

    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!--Bootstrap-->

    <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" rel="stylesheet"
          integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">

</head>

<body>

<div class="container">

    <div class="panel panel-primary">

        <div class="panel-heading">Data Barang</div>

        <div class="panel-body">

            <a href="add.php" class="btn btn-large btn-default">

                <i class="glyphicon glyphicon-plus"></i>

                &nbsp; Tambah Data</a>

            <br/><br/>

            <table class='table table-bordered table-responsive'>

                <tr>

                    <th>ID Barang</th>

                    <th>Nama Barang</th>

                    <th>Stok</th>

                    <th>Harga</th>

                    <th colspan="2" align="center">Actions</th>

                </tr>

                <?php

                $query = "SELECT * FROM barang";

                $records_per_page = 5;

                $newquery = $brg->paging($query, $records_per_page);

                $brg->viewData($newquery);

                ?>

                <tr>

                    <td colspan="7" align="center">

                        <div class="pagination-wrap">

                            <?php $brg->paginglink($query, $records_per_page); ?>

                        </div>

                    </td>

                </tr>

            </table>

        </div>
        <!--End: Panel-body-->

    </div>
    <!--End: Panel-->

</div>

<div class="container">

    <div class="alert alert-success">

        <p><strong>Selamat Belajar :) </strong></p>

        <p>If you have question, feel free to ask me <a href="http://facebook.com/gungunpriatna002">here</a>!</p>

    </div>

</div>

<!--Bootstrap-->

<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"
        integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa"
        crossorigin="anonymous"></script>

</body>

</html>
```

Simpan kembali file `index.php`.

Nah, untuk menambahkan data kita akan buat file `add.php`. Ketik lagi sintaks di bawah ini ya! ^^
```php
<?php

include_once 'dbconfig.php';

if (isset($_POST['btn-save'])) {
    $id_barang      = strtoupper($_POST['id_barang']);

    $nama           = $_POST['nama'];

    $stok          = $_POST['stok'];

    $harga           = $_POST['harga'];

    if ($brg->insertData($id_barang, $nama, $stok, $harga)) {
        header("Location: add.php?inserted");
    } else {
        header("Location: add.php?failure");
    }
}

?>

<!DOCTYPE html>

<html lang="en">

<head>

    <title>Aplikasi CRUD Sederhana Dengan PHP OOP PDO</title>

    <meta charset="utf-8">

    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!--Bootstrap-->

    <!--Bootstrap-->

    <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">

</head>

<body>

<div class="container">

    <div class="panel panel-primary">

        <div class="panel-heading">Form Tambah Data</div>

        <div class="panel-body">

            <?php

            if (isset($_GET['inserted'])) {
                ?>

                <div class="container">

                    <div class="alert alert-info">

                        <strong>Info!</strong> Data berhasil tersimpan! Silakan klik di <a href="index.php">sini</a> untuk kembali ke beranda.

                    </div>

                </div>

                <?php
            } elseif (isset($_GET['failure'])) {
                ?>

                <div class="container">

                    <div class="alert alert-warning">

                        <strong>Warning!</strong> Data gagal disimpan !

                    </div>

                </div>

                <?php
            }

            ?>

            <div class="clearfix"></div><br />

            <form method='post'>

                <table class='table table-bordered'>

                    <tr>

                        <td>Id Barang</td>

                        <td><input type='text' name='id_barang' class='form-control' required maxlength="10" autofocus></td>

                    </tr>

                    <tr>

                        <td>Nama Barang</td>

                        <td><input type='text' name='nama' class='form-control' required maxlength="50"></td>

                    </tr>

                    <tr>

                        <td>Stok</td>

                        <td><input type='text' name='stok' class='form-control' required></td>

                    </tr>

                    <tr>

                        <td>Harga</td>

                        <td><input type='text' name='harga' class='form-control' required></td>

                    </tr>

                    <tr>

                        <td colspan="2">

                            <button type="submit" class="btn btn-primary" name="btn-save">Simpan

                            </button>

                            <button type="reset" class="btn btn-primary" name="btn-reset">Reset

                            </button> <br /><br />

                            <a href="index.php" class="btn btn-large btn-success">

                                <i class="glyphicon glyphicon-backward"></i> &nbsp; Kembali ke halaman utama</a>

                        </td>

                    </tr>

                </table>

            </form>

        </div>
        <!--End: Panel-body-->

    </div>
    <!--End: Panel-->

</div>

<div class="container">

    <div class="alert alert-success">

        <p><strong>Selamat Belajar :) </strong></p>

        <p>If you have question, feel free to ask me <a href="http://facebook.com/gungunpriatna002">here</a>!</p>

    </div>

</div>

<!--Bootstrap-->

<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous"></script>

</body>

</html>
```

Setelah selesai diketik, simpan kembali file `add.php`.

Berikutnya, kita buat file `edit.php`. Ya, buka kembali text editor kesayanganmu, lalu ketik sintaks di bawah ini:
```php
<?php

include_once 'dbconfig.php';

$id_barang = $_GET['edit_id'];

if (isset($_POST['btn-update'])) {
    $nama = $_POST['nama'];

    $stok = $_POST['stok'];

    $harga = $_POST['harga'];

    if ($brg->updateData($id_barang, $nama, $stok, $harga)) {
        $msg = "<div class='alert alert-info'>

                          <strong>Info</strong> Data berhasil diubah! Silakan klik di <a href='index.php'>sini</a> untuk kembali ke beranda.

                          </div>";
    } else {
        $msg = "<div class='alert alert-warning'>

                          <strong>Warning!</strong> Update Data Gagal !

                          </div>";
    }
}

if (isset($id_barang)) {
    extract($brg->getID($id_barang));
}

?>

<!DOCTYPE html>

<html lang="en">

<head>

    <title>Aplikasi CRUD Sederhana Dengan PHP OOP PDO</title>

    <meta charset="utf-8">

    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!--Bootstrap-->

    <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" rel="stylesheet"
          integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">

</head>

<body>

<div class="container">

    <div class="panel panel-primary">

        <div class="panel-heading">Form Edit Data</div>

        <div class="panel-body">

            <?php

            if (isset($msg)) {
                echo $msg;
            }

            ?>

        </div>

        <div class="clearfix"></div>
        <br/>

        <form method='post'>

            <table class='table table-bordered'>

                <tr>

                    <td>Id Barang</td>

                    <td><input type='text' name='id_barang' class='form-control' required maxlength="10"
                               value="<?php echo $id_barang; ?>" readonly></td>

                </tr>

                <tr>

                    <td>Nama Barang</td>

                    <td><input type='text' name='nama' class='form-control' required maxlength="50"
                               value="<?php echo $nama; ?>" autofocus></td>

                </tr>

                <tr>

                    <td>Stok</td>

                    <td><input type='text' name='stok' class='form-control' value="<?php echo $stok; ?>" required></td>

                </tr>

                <tr>

                    <td>Harga</td>

                    <td><input type='text' name='harga' class='form-control' value="<?php echo $harga; ?>" required>
                    </td>

                </tr>

                <tr>

                    <td colspan="2">

                        <button type="submit" class="btn btn-primary" name="btn-update">Simpan

                        </button>

                        <button type="reset" class="btn btn-primary" name="btn-reset">Reset

                        </button>
                        <br/><br/>

                        <a href="index.php" class="btn btn-large btn-success">

                            <i class="glyphicon glyphicon-backward"></i> &nbsp; Kembali ke halaman utama</a>

                    </td>

                </tr>

            </table>

        </form>

    </div>
    <!--End: Panel-body-->

</div>
<!--End: Panel-->

</div>

<div class="container">

    <div class="alert alert-success">

        <p><strong>Selamat Belajar :) </strong></p>

        <p>If you have question, feel free to ask me <a href="http://facebook.com/gungunpriatna002">here</a>!</p>

    </div>

</div>

<!--Bootstrap-->

<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"
        integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa"
        crossorigin="anonymous"></script>

</body>

</html> 
```

Yep, simpan file `edit.php`.

Dan yang terakhir, kita buat file `hapus.php`. Ok, ketik kembali sintaks di bawah ini:
```php
<?php

include_once 'dbconfig.php';

if (isset($_POST['btn-del'])) {
    $id_barang = $_GET['delete_id'];

    $brg->deleteData($id_barang);

    header("Location: hapus.php?deleted");
}

?>

<!DOCTYPE html>

<html lang="en">

<head>

    <title>Contoh Implementasi Class Diagram</title>

    <meta charset="utf-8">

    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!--Bootstrap-->

    <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" rel="stylesheet"
          integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">

</head>

<body>

<div class="container">

    <div class="panel panel-primary">

        <div class="panel-heading">Halaman Hapus Data</div>

        <div class="panel-body">

            <?php

            if (isset($_GET['deleted'])) {
                ?>

                <div class="alert alert-success">

                    <strong>Info!</strong> Data berhasil dihapus...

                </div>

                <?php
            } else {
                ?>

                <div class="alert alert-danger">

                    <strong>Warning!</strong> apa anda yakin ingin menghapusnya ?

                </div>

                <?php
            }

            ?>

        </div>

        <div class="container">

            <?php

            if (isset($_GET['delete_id'])) {
                $id_barang = $_GET['delete_id']; ?>

                <table class='table table-bordered'>

                    <tr>

                        <th>#</th>

                        <th>Nama</th>

                        <th>Stok</th>

                        <th>Harga</th>

                    </tr>

                    <?php

                    extract($brg->getID($id_barang)); ?>

                    <tr>

                        <td><?php echo $id_barang; ?></td>

                        <td><?php echo $nama; ?></td>

                        <td><?php echo $stok; ?></td>

                        <td><?php echo $harga; ?></td>

                    </tr>

                </table>

                <?php
            }

            ?>

        </div>

        <div class="container">

            <p>

                <?php

                if (isset($id_barang)) {
                ?>

            <form method="post">

                <input type="hidden" name="id" value="<?php echo $id_barang; ?>"/>

                <button class="btn btn-large btn-primary" type="submit" name="btn-del">

                    <i class="glyphicon glyphicon-trash"></i> &nbsp; YES
                </button>

                <a href="index.php" class="btn btn-large btn-success">

                    <i class="glyphicon glyphicon-backward"></i> &nbsp; NO</a>

            </form>

            <?php
            } else {
                ?>

                <a href="index.php" class="btn btn-large btn-success">

                    <i class="glyphicon glyphicon-backward"></i> &nbsp; Back to index</a>

                <?php
            }

            ?>

            </p>

        </div>

    </div>
    <!--End: Panel-body-->

</div>
<!--End: Panel-->

</div>

<div class="container">

    <div class="alert alert-success">

        <p><strong>Selamat Belajar :) </strong></p>

        <p>If you have question, feel free to ask me <a href="http://facebook.com/gungunpriatna002">here</a>!</p>

    </div>

</div>

<!--Bootstrap-->

<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"
        integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa"
        crossorigin="anonymous"></script>

</body>

</html>
```

Simpan file `hapus.php` dan selesai. :D

Setelah proses coding selesai, kita bisa lihat ada enam file php yang sudah kita simpan di direktori project crud kita, yaitu `aplikasi kasir`.

![struktur direktori project crud php oop pdo](https://1.bp.blogspot.com/-dNhnWzptmas/V7M_MUDrqAI/AAAAAAAAAdI/dCLtpANjgdQ2CsOvScKSFVfbZddlK0mNwCLcB/w640-h477/Belajar%2BPHP%2BOOP%2Bgambar%2B3.png)

## Step 5 - Uji Coba Project{#step-5}
Sekarang kita coba run project di browser, buka url `localhost/aplikasi_kasir`. Pada browser kita bisa lihat tampilan project kita seperti gambar berikut ini.

![uji coba run - tampilan daftar barang](https://2.bp.blogspot.com/-1M0_VoWGlZI/V7M_RaK983I/AAAAAAAAAdM/wfOByKydq8cSbeSktn4o4CFkzm5cUK7jQCLcB/s16000/Belajar%2BPHP%2BOOP%2Bgambar%2B4.png)

Pada gambar di atas adalah tampilan ketika table `barang` sudah kita tambahkan data. Untuk menambah data barang, sekarang kita coba klik tombol 'Tambah Data', nanti browser akan membuka halaman `add.php`. Di halaman ini ada form untuk menambah data barang. Sekarang kita coba isi formnya, misalnya kaya gini.

![uji coba menambahkan data barang](https://4.bp.blogspot.com/-IlM3Fl5jNds/V7M_c5F_hjI/AAAAAAAAAdQ/FthY25VfuXYu9T98SqsvphKol2iieOQEwCLcB/s16000/Belajar%2BPHP%2BOOP%2Bgambar%2B5.png)

Setelah kita isi formnya, klik tombol 'Simpan' untuk menyimpan data barang. Nah, untuk mengecek apakah data berhasil disimpan atau belum kita bisa klik tombol 'Kembali ke halaman utama'. Sekarang kita bisa lihat datanya sudah tersimpan.

![jumlah data pada daftar barang bertambah](https://1.bp.blogspot.com/-FGCAbrZQGXQ/V7M_ha8k3TI/AAAAAAAAAdU/dCN2ZY8OHVYENKNQES38HA5SygiZRnsfQCLcB/s16000/Belajar%2BPHP%2BOOP%2Bgambar%2B6.png)

Pada gambar di atas, saya sudah coba menambah beberapa barang. Kalau data melebihi 5, nanti bakalan nambah halamannya kaya gambar di atas. Untuk mengatur jumlah data yang ditampilkan di dalam tabel, cek halaman `index.php` line 35.

![code pagination di fitur menampilkan daftar barang](https://4.bp.blogspot.com/-pFBQc7bHSc8/V7M_m6e2x3I/AAAAAAAAAdY/k3iICWdWQUcLmrutmIvMbYa2JDHGQ-DTQCLcB/s16000/Belajar%2BPHP%2BOOP%2Bgambar%2B7.png)

Di line 35 ada variabel `$records_per_page`, valuenya disetting 5 untuk menampilkan 5 data perhalamannya. Untuk mengatur data yang ditampilkan perhalamannya, kita bisa mengganti value variabel tersebut.

Selanjutnya, bisa kita lihat di tabel ada kolom `Actions` yang berisi dua icon, icon edit sama icon delete. Untuk mengedit data barang, kita coba klik icon edit.

![Uji coba akses halaman edit data barang](https://1.bp.blogspot.com/-Duz0rX_vehM/V7M_rVj3zqI/AAAAAAAAAdw/8d2_WQdCKBo6qeyUeFcN1uMmzyUKbBsIACEw/s16000/Belajar%2BPHP%2BOOP%2Bgambar%2B8.png)

Kita bisa lihat form edit dan juga data barangnya. Sekarang kita coba edit datanya, lalu klik tombol 'Simpan'. Selanjutnya akan ditampilkan notifikasi atau pemberitahuan kalau data berhasil diubah. 

Sekarang klik tombol ke 'Kembali ke halaman utama', kita bisa lihat di tabel kalau datanya sudah berhasil kita ubah.

![edit data bagian 2 - php oop crud - qadrLabs](https://3.bp.blogspot.com/-2HzuNLJPovk/V7M_xZoJTmI/AAAAAAAAAdw/7NYrr-pNdvUY5eqX6r59w4zniOrqb9lrQCEw/s16000/Belajar%2BPHP%2BOOP%2Bgambar%2B9.png)

![edit data bagian 3 - php oop crud - qadrLabs](https://4.bp.blogspot.com/-ylAS6hb6r44/V7M_6VJq7xI/AAAAAAAAAdw/bH6yjEXDiQgeVTCwRESwxfrXo7bKaxAzgCEw/s16000/Belajar%2BPHP%2BOOP%2Bgambar%2B10.png)

Lalu, bagaimana kalau kita mau hapus data barang? 

Yep, kamu benar.^^ 

Kita tinggal klik icon 'delete' di kolom actions. Sebagai contoh di sini kita coba hapus data barang dengan id `B0001`, selanjutnya kita klik icon delete. Setelah itu muncul pertanyaan untuk konfirmasi hapus data. Kita tinggal Klik 'Yes' untuk menghapus data.

![uji coba hapus data - php oop crud](https://3.bp.blogspot.com/-oFRRkbliH4g/V7NAH1PEU5I/AAAAAAAAAdw/Cz6ou-LydbwtZLFIo9oKqrQ0Ryn9ydikQCEw/s16000/Belajar%2BPHP%2BOOP%2Bgambar%2B11.png)

Ketika kita akses kembali halaman daftar barang, kita bisa lihat pada daftar barang sudah tidak ada lagi barang dengan id `B0001`.

## Penutup: Langkah Selanjutnya dalam Perjalanan PHP OOP Anda{#penutup}
Selamat! Anda telah berhasil membuat aplikasi CRUD menggunakan PHP OOP dan PDO. Ini adalah langkah penting dalam perjalanan Anda sebagai PHP developer. Mari kita refleksikan apa yang sudah kita pelajari dan lihat ke mana kita bisa melangkah selanjutnya.

### Apa yang Sudah Kita Capai
- Membuat aplikasi CRUD yang fungsional dengan PHP OOP
- Mengimplementasikan PDO untuk operasi database yang aman
- Membangun interface responsif dengan Bootstrap
- Menerapkan konsep pagination
- Membuat sistem validasi data sederhana

### Potensi Pengembangan Aplikasi
Aplikasi ini masih memiliki banyak ruang untuk pengembangan. Berikut beberapa ide yang bisa Anda implementasikan:

1. **Peningkatan Keamanan**
   - Implementasi sistem autentikasi
   - Validasi input yang lebih ketat
   - CSRF protection
   - XSS prevention

2. **Penambahan Fitur**
   - Pencarian dan filter data
   - Export data ke PDF/Excel
   - Image upload untuk produk
   - Riwayat perubahan data

3. **Optimasi Performa**
   - Implementasi caching
   - Query optimization
   - Asset minification
   - AJAX implementation

4. **UX Improvements**
   - Datatable integration
   - Form validation yang lebih interaktif
   - Sweet Alert untuk notifikasi
   - Loading indicators

### Resources untuk Belajar Lebih Lanjut
1. **PHP & OOP**
   - PHP Documentation: php.net/manual/en/language.oop5.php
   - PHP The Right Way: phptherightway.com
   - Clean Code in PHP: github.com/php-fig/fig-standards

2. **PDO & Database**
   - PDO Documentation: php.net/manual/en/book.pdo.php
   - Database Design: sql-pattern.com
   - MySQL Performance: mysql.com/why-mysql/presentations/

3. **Modern PHP Development**
   - Composer: getcomposer.org
   - PHP Standards: php-fig.org
   - Testing with PHPUnit: phpunit.de

### Tips untuk Developer
1. Selalu ikuti prinsip SOLID dalam pengembangan OOP
2. Gunakan version control (Git) untuk track perubahan kode
3. Tulis dokumentasi yang jelas untuk setiap class dan method
4. Terapkan error logging untuk debugging
5. Buat unit test untuk fitur-fitur penting

### Kesimpulan
Aplikasi CRUD yang kita buat memang masih sederhana, namun konsep-konsep yang dipelajari merupakan fondasi penting dalam pengembangan aplikasi PHP modern. Teruslah bereksperimen, jangan takut untuk mencoba hal-hal baru, dan yang terpenting, teruslah belajar dan berkembang.

### Feedback & Kontribusi
Saya sangat menghargai feedback dari Anda untuk meningkatkan kualitas tutorial ini. Jika Anda menemukan bug atau memiliki saran perbaikan, silakan:
- Diskusikan di kolom komentar
- Hubungi kami melalui email atau sosial media

Mari kita sama-sama berkembang dalam komunitas PHP Indonesia!

---
*Tutorial ini adalah bagian dari serial [Belajar PHP OOP](https://qadrlabs.com/series/belajar-php-oop). Pantau terus tutorial-tutorial selanjutnya untuk materi yang lebih mendalam tentang PHP modern development.