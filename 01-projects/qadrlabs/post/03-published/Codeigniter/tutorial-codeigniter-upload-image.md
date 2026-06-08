---
title: "Tutorial CodeIgniter: Upload Image"
slug: "tutorial-codeigniter-upload-image"
category: "Codeigniter"
date: "2016-02-11"
status: "published"
---

Salah satu perbedaan besar dalam perjalanan hidup di era yang serba canggih ini adalah adanya kebebasan dan kemudahan dalam berinteraksi satu sama lain. Dan di masyarakat kita masa kini, berinteraksi melalui media sosial adalah hal yang sangat umum dan sudah menjadi kebiasaan. Tidak hanya untuk saling menyapa, media sosial pun bisa digunakan untuk berbagi foto. Melalui Facebook, Twitter, Instagram ataupun media sosial lainnya. Saat ada momen menarik dan instagram-able, biasanya orang akan langsung cekrek, cekrek lalu upload ke media sosial masing-masing.

Memperhatikan fenomena yang marak di lakukan oleh kebanyakan orang, saya pun berpikir, “bagaimana caranya upload gambar ke media sosial?”. Karena penasaran saya, coba explore untuk membuat fungsi sederhana untuk mengupload gambar. Untuk implementasi fitur tersebut saya coba gunakan framework codeigniter 3. Jadi, pada postingan kali ini saya akan membahas cara mengunggah atau upload gambar menggunakan framework CodeIgniter 3.

Spesifikasi peralatan yang saya gunakan ketika tutorial ini pertama kali ini ditulis adalah sebagai berikut:
1. Xampp 1.8.0 (PHP 5.4)
2. Codeigniter 3.0.1
3. MYSQL

Berikut ini adalah langkah – langkahnya:

## Step 1 - Membuat Controller Baru{#step-1}
Pertama kita akan membuat controller yang akan menangani halaman untuk upload dan juga proses upload. Buat file controller dengan nama `Upload_controller.php`, lalu simpan di folder `controller`. Selanjutnya kita deklarasikan class `Upload_controller` dan tambahkan dua method `index()` dan `upload()`.

```php
<?php if (!defined('BASEPATH')) exit('No direct script access allowed');
class Upload_controller extends CI_Controller
{
    public function __construct()
    {
        parent::__construct();
        $this->load->helper(array('url', 'html', 'form'));
    }

    function index()
    {
        $this->load->view('view_upload');
    }

    function upload()
    {
        $config = array(
            'upload_path' => './assets/uploads/img/', //lokasi gambar akan di simpan  
            'allowed_types' => 'jpg|jpeg|png|gif', //ekstensi gambar yang boleh di uanggah  
            'max_size' => '2000', //batas maksimal ukuran gambar  
            'max_width' => '600', //batas maksimal lebar gambar  
            'max_height' => '600', //batas maksimal tinggi gambar  
            'file_name' => url_title($this->input->post('userfile')) //nama gambar  
        );

        $this->load->library('upload', $config);

        if (!$this->upload->do_upload()) {
            $error = $this->upload->display_errors();
            echo $error;
        } else {
            //sintak untuk menyimpan di database  
            /**
            *
            *
            $file = $this->upload->file_name;
            $ket = $this->input->post('ket');
            $tgl = date('Y-m-d');

            $data_gambar = array(
                'img' => $file,
                'ket' => $ket,
                'tgl' => $tgl
            );
	        $this->latihan_model->upload_gambar($data_gambar);
	        **/

            $data = array('upload_data' => $this->upload->data());
            
            $this->load->view('sukses', $data);
        }
    }
}


```

Apabila selesai coding untuk class controller, jangan lupa save kembali file `Upload_controller.php`.

### Penjelasan Kode:

1. **`<?php if (!defined('BASEPATH')) exit('No direct script access allowed');`**
   - Baris ini adalah pengamanan untuk memastikan file ini hanya bisa diakses melalui framework **CodeIgniter**. Jika seseorang mencoba mengakses file ini langsung melalui URL (misalnya, `http://localhost/upload_controller`), maka aplikasi akan berhenti dan tidak akan dieksekusi, karena `BASEPATH` tidak terdefinisi jika file ini diakses langsung.

2. **`class Upload_controller extends CI_Controller`**
   - Mendeklarasikan kelas `Upload_controller` yang merupakan turunan dari kelas **CI_Controller**. `CI_Controller` adalah kelas dasar untuk semua controller dalam CodeIgniter.

3. **`public function __construct()`**
   - Merupakan konstruktor dari kelas ini yang akan dipanggil saat objek kelas ini dibuat.
   - Pada konstruktor ini, **helper** `url`, `html`, dan `form` dimuat menggunakan `$this->load->helper()`. Helper ini berguna untuk mempermudah pembuatan URL, pengelolaan form, dan manipulasi HTML dalam aplikasi.

4. **`function index()`**
   - Fungsi ini digunakan untuk menangani request yang masuk ke halaman utama dari controller ini.
   - Di dalamnya, **view** `view_upload` dimuat menggunakan `$this->load->view()`, yang mengarahkan pengguna ke halaman upload.

5. **`function upload()`**
   - Fungsi ini akan menangani proses unggah file gambar. Berikut rincian proses dalam fungsi ini:
     - **Konfigurasi Upload:**
       - `$config` adalah array yang berisi pengaturan untuk proses upload gambar:
         - `'upload_path' => './assets/uploads/img/'`: Lokasi di mana gambar yang di-upload akan disimpan.
         - `'allowed_types' => 'jpg|jpeg|png|gif'`: Menentukan ekstensi file gambar yang diizinkan untuk di-upload, yaitu `.jpg`, `.jpeg`, `.png`, dan `.gif`.
         - `'max_size' => '2000'`: Menentukan ukuran maksimal file yang dapat di-upload, dalam satuan kilobyte (KB), yaitu 2000 KB atau sekitar 2 MB.
         - `'max_width' => '600'`: Menentukan lebar maksimal gambar, yaitu 600 piksel.
         - `'max_height' => '600'`: Menentukan tinggi maksimal gambar, yaitu 600 piksel.
         - `'file_name' => url_title($this->input->post('userfile'))`: Menentukan nama file gambar yang akan disimpan, yang dihasilkan berdasarkan input pengguna yang dikirim dengan nama `userfile`. Nama file akan diubah menjadi format URL-friendly dengan menggunakan fungsi `url_title()`.

     - **Membuat Library Upload:**
       - `$this->load->library('upload', $config);`: Memuat library **upload** dengan konfigurasi yang telah ditentukan sebelumnya.

     - **Proses Upload:**
       - `if (!$this->upload->do_upload()) { ... }`: Fungsi `do_upload()` digunakan untuk melakukan upload file. Jika upload gagal, maka akan menampilkan pesan kesalahan melalui `$this->upload->display_errors()`.
       - Jika upload berhasil, maka data file yang di-upload akan disimpan dalam variabel `$data` dengan menggunakan `$this->upload->data()`, yang berisi informasi tentang file yang di-upload.
       - Setelah itu, view `sukses` akan dimuat dan data file yang di-upload akan diteruskan ke view tersebut.

6. **Komentar untuk Menyimpan Gambar ke Database:**
   - Ada bagian yang dikomentari, yang berfungsi untuk menyimpan data gambar yang di-upload ke dalam database.
   - Variabel `$file` akan berisi nama file gambar yang di-upload, dan `$ket` berisi keterangan yang diambil dari input pengguna.
   - Data gambar (termasuk nama file, keterangan, dan tanggal) akan disimpan dalam array `$data_gambar`, yang kemudian dapat dimasukkan ke dalam database dengan menggunakan model `latihan_model`. Karena kita fokus ke fitur upload, jadi untuk bagian save data bisa teman-teman eksplore lebih jauh setelah selesai mengikuti tutorial ini.

## Step 2 - Buat file view{#step-2}
Selanjutnya kita buat file view dengan nama file `view_upload.php`, lalu simpan file tersebut di folder `views`. Setelah itu ketik sintaks di bawah ini:

```html
 <!DOCTYPE html>
<html>
<head>
    <title>Tutorial CodeIgniter with Gun Gun Priatna</title>
</head>
<body>
    <h2>Upload Gambar</h2>
    <?php echo form_open_multipart('upload_controller/upload'); ?>
    <table>
        <tr>
            <td><input type="file" name="userfile"></td>
        </tr>
        <tr>
            <td><textarea name="ket" placeholder="Keterangan (Optional)"></textarea></td>
        </tr>
        <tr>
            <td><input type="submit" name="upload" value="upload"></td>
        </tr>
    </table>
    <?php echo form_close(); ?>
</body>
</html>
```

Berikut adalah penjelasan tentang bagian-bagian dari kode ini:
1. **Formulir untuk Mengunggah Gambar:**
```php
<?php echo form_open_multipart('upload_controller/upload'); ?>
```
- **`form_open_multipart()`**: Fungsi ini digunakan untuk membuka tag form dalam **CodeIgniter**. 
  - **`'upload_controller/upload'`** adalah URL target di mana form akan dikirimkan setelah pengguna mengklik tombol submit. URL ini mengarah ke metode `upload()` dalam controller `Upload_controller`, yang akan menangani proses upload gambar.
  - `form_open_multipart()` digunakan karena form ini akan mengirimkan file, dan file membutuhkan tipe encoding `multipart/form-data`.

2. **Input File untuk Mengunggah Gambar:**
```html
<table>
    <tr>
        <td><input type="file" name="userfile"></td>
    </tr>
```
- **`<input type="file" name="userfile">`**: Ini adalah elemen input yang memungkinkan pengguna untuk memilih file dari komputer mereka untuk diunggah. Atribut `name="userfile"` digunakan untuk memberikan nama kepada input ini yang akan digunakan untuk menangani file di server melalui PHP.

3. **Penutupan Formulir:**
```php
<?php echo form_close(); ?>
```
- **`form_close()`**: Fungsi ini digunakan untuk menutup tag form dalam CodeIgniter. Ini menandakan bahwa form telah selesai dan siap untuk dikirimkan saat tombol submit ditekan.



Dan yang terakhir, buat file untuk menampilkan keterangan sukses. Ketik sintaks di bawah ini, lalu simpan di folder `views` dengan nama `sukses.php`.

```html
<!DOCTYPE html>
<html>
<head>
    <title>Tutorial CodeIgniter with Gun Gun Priatna</title>
</head>
<body>
    <h3>Your file was successfully uploaded!</h3>
    <ul>
        <?php foreach ($upload_data as $item => $value) : ?>
            <li><?php echo $item; ?>: <?php echo $value; ?></li>
        <?php endforeach; ?>
    </ul>
    <p><?php echo anchor('upload_controller', 'Upload Another File!'); ?></p>
</body>
</html>
```

## Step 3 - Buat direktori untuk upload{#step-3}
Pada tahapan ini kita akan buat folder khusus untuk menyimpan file hasil upload. Kita buka kembali file controller yang sudah kita buat, lalu perhatikan method `upload()`. Pada method `upload()` terdapat konfigurasi library upload.

```php
        $config = array(
            'upload_path' => './assets/uploads/img/', //lokasi gambar akan di simpan  
            'allowed_types' => 'jpg|jpeg|png|gif', //ekstensi gambar yang boleh di uanggah  
            'max_size' => '2000', //batas maksimal ukuran gambar  
            'max_width' => '600', //batas maksimal lebar gambar  
            'max_height' => '600', //batas maksimal tinggi gambar  
            'file_name' => url_title($this->input->post('userfile')) //nama gambar  
        );
        
```
Pada baris kode di atas terdapat konfigurasi untuk `upload_path`. Sekarang kita buat folder sesuai dengan yang ada di `upload_path` yaitu `assets/uploads/img`.


![direktori untuk image](https://3.bp.blogspot.com/-TTcEl_PNoE4/VrvmIdRb0mI/AAAAAAAAAHY/r2L3iJh5W1E/s1600/direktori.png)

## Step 4 - Uji Coba{#step-4}
Sekarang kita uji coba projek sederhana kita. Buka browser, lalu coba run project untuk mengunggah gambar dengan mengetikkan alamat dengan format:

```
localhost/nama_folder_ci/index.php/nama_class/nama_method
```
Karena nama folder CI saya latihan_ci, saya ketik alamat seperti di bawah ini:

```
localhost/latihan_ci/index.php/upload_controller/index

```

Jika tidak ada error, akan muncul tampilan seperti di bawah ini:

![first run](https://4.bp.blogspot.com/-T8LrdWF8Yas/VrvmIfrsMcI/AAAAAAAAAHY/OTJ8AmWBZRg/s1600/tampilan%2Bawal.png)

Selanjutnya, Klik tombol Choose File untuk memilih gambar yang akan diupload, lalu klik tombol Open. Isi keterangan (untuk deskripsi gambar), setelah itu coba kamu klik tombol upload.  Kalau berhasil akan muncul tampilan seperti di bawah ini:

![hasil upload](https://3.bp.blogspot.com/-yeqcUv3GYQo/VrvmIfG-O9I/AAAAAAAAAHY/LFFuMJ-wrvQ/s1600/sukses.png)

Klik link ‘Upload Another File’ untuk mengunggah file lainnya. :)

## Penutup{#penutup}
Pada tutorial ini kita sudah belajar bagaimana cara upload gambar menggunakan framework codeigniter. Dimulai dari membuat controller, membuat file view dan membuat direktori untuk hasil upload. Selain itu kita sudah uji coba project kita dan gambar berhasil diupload ketika kita uji coba. 

Seperti yang sudah kita coba, project ini masih sederhana dan masih bisa dikembangkan. Kita masih bisa kembangkan project ini dengan menambahkan fungsi untuk menyimpan data hasil upload di database misalnya. Selamat mencoba!