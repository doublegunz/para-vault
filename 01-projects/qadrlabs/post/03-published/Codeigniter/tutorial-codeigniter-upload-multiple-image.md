---
title: "TUTORIAL CODEIGNITER: UPLOAD MULTIPLE IMAGE"
slug: "tutorial-codeigniter-upload-multiple-image"
category: "Codeigniter"
date: "2016-02-16"
status: "published"
---

Terkait postingan saya sebelumnya mengenai fungsi [upload gambar](https://qadrlabs.com/post/tutorial-codeigniter-upload-image) dengan framework CodeIgniter, ada yang bertanya, *"Gimana sih caranya upload beberapa gambar sekaligus sekali submit?”*. Karena itu pada edisi tutorial codeigniter 3 kali ini saya akan coba share bagaimana cara mengunggah beberapa gambar sekaligus dalam sekali submit atau biasanya disebut upload multiple image.

Berikut ini adalah spesifikasi peralatan yang saya gunakan pada saat tutorial ini ditulis, yaitu:
1. Xampp 1.8.0 (PHP 5.4)
2. CodeIgniter 3.0.1
3. MYSQL (Optional)

> Pertanggal 10 Desember 2024, tutorial ini diuji coba menggunakan laravel herd dengan PHP versi 8.1 dan CodeIgniter 3.1.13

## Overview{#overview}
Pada edisi tutorial codeigniter 3 kali ini kita akan membuat project sederhana dengan fitur upload multiple image. Pada project ini terdapat dua halaman, yaitu halaman form untuk upload image dan yang kedua halaman untuk menampilkan keterangan sukses upload. Pada halaman upload nanti terdapat beberapa input dengan tipe file, di mana ketika tombol `upload` kita tekan, terdapat proses untuk upload file dari masing-masing input. Untuk proses upload image pada project ini kita akan coba gunakan kembali library upload dari codeigniter. 

## Step 1 - Atur Konfigurasi Base Url{#step-1}
Pertama kita sesuaikan base url project kita terlebih dahulu. Buka file `application/config/config.php`, lalu temukan baris kode berikut ini.

```php
$config['base_url'] = '';
```

Setelah itu kita tambahkan base url dengan format, `http://localhost/[nama folder CI]/`. Karena di sini nama folder ci saya `latihan_ci`, jadi saya tambahkan base url nya menjadi.

```php
$config['base_url'] = 'http://localhost/latihan_ci';
```

Setelah selesai, save kembali file `config.php`.

## Step 2 - Membuat File Controller{#step-2}
Pada step 2 ini saya akan buat 1 file controller yang akan menangani untuk menampilkan halaman form upload dan proses upload.

Seperti biasa, buka teks editor kesayanganmu, setelah itu buat file controller dengan nama `C_upload.php` lalu simpan di folder controllers. Sekarang kita ketik sintaks berikut ini:

```php
<?php if (!defined('BASEPATH')) exit('No direct script access allowed');  
  
class C_upload extends CI_Controller  
{  
   public function __construct()  
   {  
      parent::__construct();  
      $this->load->helper(array('url', 'html', 'form'));  
   }  
  
   function index()  
   {  
      $this->load->view('v_upload');  
   }  
  
   function upload()  
   {  
      if ($this->input->post('upload')) {  
         $number_of_files = sizeof($_FILES['userfiles']['tmp_name']);  
         $files = $_FILES['userfiles'];  
         $config = array(  
            'upload_path' => './assets/uploads/img/', //direktori untuk menyimpan gambar  
            'allowed_types' => 'jpg|jpeg|png|gif',  
            'max_size' => '2000',  
            'max_width' => '2000',  
            'max_height' => '2000'  
         );  
         for ($i = 0; $i < $number_of_files; $i++) {  
            $_FILES['userfile']['name'] = $files['name'][$i];  
            $_FILES['userfile']['type'] = $files['type'][$i];  
            $_FILES['userfile']['tmp_name'] = $files['tmp_name'][$i];  
            $_FILES['userfile']['error'] = $files['error'][$i];  
            $_FILES['userfile']['size'] = $files['size'][$i];  
            $this->load->library('upload', $config);  
   
            if (!$this->upload->do_upload('userfile')) {  
               $error = $this->upload->display_errors();  
               echo $error;  
            }  
         }  
      }  
      $this->load->view('v_sukses');  
   }  
  
}

```

Pada baris kode di atas, di dalam class C_upload terdapat dua method, yaitu method `index()` dan method `upload()`. Pada method `index()`, terdapat kode untuk menampilkan halaman untuk upload image dengan nama file view `v_upload.php`. Sedangkan method `upload()` digunakan untuk mengupload file gambar ke server. Method ini akan dijalankan jika ada input dari form dengan nama `upload`. Kemudian, variabel `$number_of_files` akan diinisialisasi dengan jumlah file yang diupload, dan variabel `$files` akan diinisialisasi dengan informasi mengenai file-file tersebut.

Setelah itu, dilakukan inisialisasi variabel `$config` yang merupakan array yang berisi konfigurasi untuk proses upload file. Konfigurasi tersebut meliputi:

-   `upload_path`: merupakan direktori di server tempat file akan disimpan.
-   `allowed_types`: merupakan tipe file yang diizinkan untuk diupload, yaitu file gambar dengan ekstensi `jpg`, `jpeg`, `png`, atau `gif`.
-   `max_size`: merupakan ukuran maksimal file yang diizinkan untuk diupload, dalam kilobyte.
-   `max_width`: merupakan lebar maksimal gambar yang diizinkan untuk diupload, dalam pixel.
-   `max_height`: merupakan tinggi maksimal gambar yang diizinkan untuk diupload, dalam pixel.

Setelah itu, terdapat perulangan `for` yang akan mengiterasi sebanyak `$number_of_files` kali. Dalam perulangan tersebut, dilakukan inisialisasi kembali beberapa elemen dari array `$_FILES` dengan informasi mengenai file yang sedang diupload pada iterasi tersebut. Kemudian, dilakukan pemanggilan library `upload` dengan menggunakan konfigurasi yang telah ditentukan di variabel `$config`. Library tersebut akan menjalankan proses upload file ke server.

Jika proses upload berhasil, maka akan ditampilkan halaman `v_sukses`. Jika terjadi error saat proses upload, maka error tersebut akan ditampilkan di layar.

## Step 3 - Buat file view{#step-3}

Selanjutnya kita buat file view dengan nama `v_upload.php` dan simpan di folder `views`. Setelah itu kita ketik sintaks di bawah ini:

```html
<!DOCTYPE html>
<html>

<head>
    <title>Tutorial CodeIgniter UPLOAD MULTIPLE IMAGE @ qadrlabs.com </title>
</head>

<body>
    <h2>Upload Gambar</h2>
    <?php echo form_open_multipart('c_upload/upload'); ?>
    <table>
        <tr>
            <td><input type="file" name="userfiles[]" /></td>
            <td><input type="file" name="userfiles[]" /></td>
            <td><input type="file" name="userfiles[]" /></td>
        </tr>
        <tr>
            <td><input type="submit" name="upload" value="upload"></td>
        </tr>
    </table>
    <?php echo form_close(); ?>
</body>

</html>
```

Simpan kembali file `v_upload.php`.

Pada baris pertama setelah elemen `<body>`, terdapat elemen `<h2>` yang berisi judul form. Kemudian, pada baris berikutnya terdapat fungsi `form_open_multipart` yang akan menampilkan tag `<form>` dengan atribut `enctype` yang diisi dengan `"multipart/form-data"`. Fungsi ini akan menentukan bahwa form tersebut digunakan untuk mengirim file. Selanjutnya, pada atribut `action` akan diisi dengan `"c_upload/upload"`, yang merupakan alamat URL ke controller `c_upload` dengan fungsi `upload`.

Setelah itu, terdapat elemen `<table>` yang berisi elemen `<tr>` (table row) dan elemen `<td>` (table data). Elemen `<td>` tersebut berisi input dengan tipe `file` yang memiliki nama `userfiles[]`. Input tersebut akan menampilkan tombol "Choose File" yang bisa digunakan untuk memilih file yang akan diupload. Input tersebut juga memiliki atribut `name` dengan nilai `userfiles[]`, yang akan menentukan bahwa input tersebut merupakan bagian dari array `userfiles`.

Setelah itu, terdapat elemen `<tr>` yang berisi elemen `<td>` yang berisi tombol submit dengan nama `upload` yang akan mengirimkan form tersebut ke server saat diklik. Kemudian, pada baris terakhir terdapat fungsi `form_close` yang akan menampilkan tag `</form>`, yang menandakan bahwa form tersebut telah selesai dibuat.

Dan yang terakhir buat file untuk menampilkan pemberitahuan kalau gambar yang diupload sudah berhasil. Buka kembali teks editor, lalu buat file view baru dengan nama file `v_sukses.php` dan ketik sintaks berikut ini:

```html
<!DOCTYPE html>
<html lang="en">

<head>
    <title>Tutorial CodeIgniter UPLOAD MULTIPLE IMAGE @ qadrlabs.com </title>
</head>

<body>
    <h3>Your file was successfully uploaded!</h3>
    <p><?php echo anchor('c_upload', 'Upload Another File!'); ?></p>
</body>

</html>
```

Simpan kembali file `v_sukses.php`.

## Step 4 - Buat folder untuk hasil upload{#step-4}
Selanjutnya kita siapkan folder tujuan untuk hasil upload sesuai dengan `upload_path` yang kita tentukan di konfigurasi library `upload`.

```php
$config = array(  
   'upload_path' => './assets/uploads/img/', //direktori untuk menyimpan gambar  
   'allowed_types' => 'jpg|jpeg|png|gif',  
   'max_size' => '2000',  
   'max_width' => '2000',  
   'max_height' => '2000'  
);
```

Pada konfigurasi library `upload`, sebagai contoh target atau upload path yang kita tentukan di sini adalah `assets/uploads/img/`. Sekarang kita buat folder `assets/uploads/img/`, seperti di gambar ini.

![direktori untuk image](https://3.bp.blogspot.com/-TTcEl_PNoE4/VrvmIdRb0mI/AAAAAAAAAHY/r2L3iJh5W1E/s1600/direktori.png)

## Step 5 - Uji Coba Project{#step-5}
Pada tahapan ini kita akan uji coba project yang sudah kita buat. Sekarang kita buka browser, lalu ketik alamat di browser dengan pola:
```
localhost/nama_folderCI/index.php/nama_class/nama_method
```

Sama seperti di tutorial – tutorial sebelumnya, nama folder CI saya itu `latihan_ci`, jadi saya ketik alamat seperti di bawah ini:
```
localhost/latihan_ci/index.php/c_upload/index
```

Jika tidak ada error, maka akan muncul tampilan seperti di bawah ini:
![first run](https://3.bp.blogspot.com/-ez2jNicKG8g/VsJgn_C9VJI/AAAAAAAAAKc/mYgoH0eTgKM/s1600/tampilan%2Bindex.png)

Sekarang kita coba klik tombol “Choose File” untuk memilih gambar yang akan diupload, lalu klik tombol **Open**.

![choose file](https://3.bp.blogspot.com/-yU8RmQnA-vg/VsJgv451iyI/AAAAAAAAAKg/gAzWqSJ_Ppo/s1600/choose%2Bfile.png)

Setelah gambar yang akan diupload sudah siap, klik tombol `Upload` untuk mengupload gambar. Jika tidak ada error, maka akan muncul tampilan dari halaman `v_sukses.php` dan kita bisa lihat terdapat file yang kita upload di direktori `assets/uploads/img/`.

![sukses](https://1.bp.blogspot.com/-6ntvMCVJeFo/VsJg3re50vI/AAAAAAAAAKk/92mWzXBgYsc/s1600/view%2Bsukses.png)

Untuk mengupload file yang lain, silakan klik link “Upload Another File!”.

## Penutup{#penutup}
Pada tutorial upload multiple image codeigniter 3 ini kita belajar bagaimana cara upload di mana file yang diupload ini lebih dari satu dengan satu kali klik tombol upload. Pada tutorial ini kita kembali menggunakan library `upload` untuk menangani proses upload file. Berdasarkan percobaan kita kali ini, logika untuk upload file masih sama, yang berbeda adalah jumlah input tipe file lebih satu dan nama field input file kita samakan, yaitu `userfiles[]` di mana ketika diproses di controller `userfiles` berupa array, sehingga untuk melakukan proses upload kita gunakan looping untuk upload masing-masing input.

Sama seperti project upload di tutorial sebelumnya, pada tutorial kali ini pun masih berupa project sederhana dengan tujuan supaya lebih mudah memahami logika untuk proses upload file lebih dari satu. Dan tentu dari project sederhana ini bisa kita kembangkan lebih baik lagi. Semoga bermanfaat dan sampai jumpa di seri belajar codeigniter 3 berikutnya.