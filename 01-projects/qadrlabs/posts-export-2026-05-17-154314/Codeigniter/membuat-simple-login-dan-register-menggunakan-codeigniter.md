---
title: "Membuat Simple Login dan Register Menggunakan CodeIgniter"
slug: "membuat-simple-login-dan-register-menggunakan-codeigniter"
category: "Codeigniter"
date: "2016-03-01"
status: "published"
---

1 botol Green tea ukuran sedang dan secangkir kopi miliknya. Di suatu sore yang tak terasa berganti malam. Siang tadi kami bertemu, di antara ketidak sengajaan atau mungkin pertemuan ini sudah diatur sedemikian rupa oleh kuasa kasat mata di sebuah kedai kopi tua di pojok kota. Bertukar cerita, ngalor ngidul membicarakan banyak hal.

Di akhir pertemuan, dia bertanya.

*“Punya akun line ga? twitter? Atau Facebook?"*

Hal biasa yang sering ditanyakan saat baru berkenalan. Menanyakan akun media sosial. Kalau kata teman saya, salah satu ciri orang yang ‘kekinian’ adalah memiliki akun media sosial. Dan bisa dipastikan, berdasar hasil observasi saya sendiri, hampir semua teman di kelas saya memiliki akun media sosial. Entah itu akun Facebook, X, LinkedIn, Instagram ataupun media sosial lainnya. Memang sebagai generasi yang hidup, berkembang dan mendewasa di era digital, kita dapat dengan mudah berinteraksi dan saling sapa. Salah satunya dengan media sosial. Kita bisa dengan mudah memiliki akun media sosial hanya dengan klak – klik saja. Belum lagi ponsel canggih yang mendukung kemudahan – kemudahan lainnya. Kita cukup mendaftar, masukan data diri, dan...

*voila!~* Kita sudah dapat akun media sosial!

Dan, karena informasi perkuliahan itu adanya di grup facebook, mau ga mau¸ saya juga harus punya akun facebook. Bukan kok. Bukan karena pengen ikut – ikutan kekinian! Seperti biasa, sewaktu mendaftar akun facebook..

*“Bagaimana ya caranya membuat sebuah fitur untuk mendaftar akun dan kita bisa langsung login setelah mendaftar, seperti media sosial?”*. Tetiba saja terlintas di pikiran saya, bagaimana ya caranya?

Dan dari ide itu saya eksekusi menjadi sebuah tutorial. Ya, [seri tutorial CodeIgniter 3](https://qadrlabs.com/series/belajar-codeigniter-3) edisi kali ini kita akan membahas tentang fitur login dan register dalam aplikasi codeigniter 3. 

## Overview{#overview}
Pada tutorial ini kita akan membuat project sederhana dengan fitur **Login dan Register dalam aplikasi CodeIgniter 3**. Di dalam project ini, kita akan membuat sebuah fitur yang digunakan untuk proses registrasi akun atau pendaftaran dan login ke dalam aplikasi CodeIgniter 3 yang kita bangun. Kita coba terapkan penggunaan `library session` untuk menyimpan data login user, dan penggunaan `query builder` yang sebelumnya sudah kita bahas di tutorial codeigniter 3 tentang [CRUD](http://qadr-labs.test/post/crud-sederhana-codeigniter). Selain itu, kita juga akan mencoba membuat sebuah library CodeIgniter sederhana yang menangani proses login dan logout.

Lalu, apa saja langkah-langkah dalam membuat project Simple Login Register CodeIgniter? *Check this out, ya!*

**Daftar Isi**
- [Overview](#overview)
- [Step 1 - Persiapan development](#step-1-persiapan-development)
- [Step 2 - Membuat database](#step-2-membuat-database)
- [Step 3 - Mengatur Konfigurasi](#step-3-mengatur-konfigurasi)
- [Step 4 - Membuat file view](#step-4-coding-view)
- [Step 5 - Membuat Model](#step-5-coding-model)
- [Step 6 - Membuat library untuk login](#step-6-coding-library)
- [Step 7 - Membuat Controller](#step-7-coding-controller)
- [Step 8 - Uji Coba Project](#step-8-uji-coba)
- [Penutup](#penutup)
- [Referensi](#referensi)

## Step 1 - Persiapan Development {#step-1-persiapan-development}
Sebelum memulai alangkah baiknya kita berdoa terlebih dahulu, supaya codingnya berjalan dengan lancar. :)

Sudah?

Baik, selanjutnya kita cek apa saja yang kita gunakan. Dan spesifikasi peralatan yang saya gunakan saat tutorial ini ditulis adalah sebagai berikut:
1. PHP Version 5.5.35 (dan masih bisa digunakan di php versi 7 juga) 
2. MariaDB
3. CodeIgniter versi 3.1.0

Kamu bisa download CodeIgniter di web official CodeIgniter [di halaman download](https://codeigniter.com/download). Klik link 'Download' untuk download CodeIgniter versi 3.

Kalau sudah kita download, extract zip file (misalkan `bcit-ci-CodeIgniter-3.1.13-0-gbcb17eb.zip`), dan di dalam folder hasil extract misalkan `bcit-ci-CodeIgniter-3.1.13-0-gbcb17eb` , terdapat folder `bcit-ci-CodeIgniter-bcb17eb`. Folder `bcit-ci-CodeIgniter-bcb17eb` kita rename menjadi `ci3`. Setelah itu pindahkan folder project kita (`ci3`) ke direktori webroot, yaitu `C:\xampp\htdocs\`.

## Step 2 - Membuat Database {#step-2-membuat-database}
Setelah semua persiapan sudah siap, langkah berikutnya adalah membuat database untuk project login dan register codeigniter 3. Untuk proses pembuatan database, kita bisa menggunakan  `PHPMyadmin` atau lainnya. Di sini kita coba gunakan PHPMyadmin.

Sekarang kita buka `PHPMyadmin` di browser, buka url `localhost/phpmyadmin`. Lalu selanjutnya kita buat database baru dengan nama `dbci3`. 

Kalau databasenya sudah kita buat, langkah selanjutnya kita akan membuat tabel. Klik menu `SQL` di PHPMyadmin.

![halaman sql untuk membuat table di phpmyadmin](https://1.bp.blogspot.com/-nT5pHPYoHIA/WAwQZECH8NI/AAAAAAAAAks/AaDZPfYq-xM50QqUQ-aWAIPcRQNF_nd4ACEw/s1600/Simple-Login-Register-CodeIgniter-gambar%2B2.jpg)


Lalu, ketik script SQL berikut ini di dalam textarea.

```sql
CREATE TABLE IF NOT EXISTS `users` (   
    `id_user` int(11) NOT NULL AUTO_INCREMENT,   
    `nama` varchar(100) NOT NULL,   
    `email` varchar(255) NOT NULL,   
    `username` varchar(32) NOT NULL,   
    `password` varchar(64) NOT NULL,   
    PRIMARY KEY (`id_user`),   
    UNIQUE KEY `email` (`email`)   
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;   
```

![membuat table menggunakan phpmyadmin](https://4.bp.blogspot.com/-G5k3DgSrGA8/WAwQZG_370I/AAAAAAAAAkw/rJdLLCWkOMgOh9PKPOaZmrw-fAlAWoG-QCEw/s1600/Simple-Login-Register-CodeIgniter-gambar%2B3.jpg)

Kemudian, klik tombol `Go`.

Maka, secara ajaib akan muncul tabel users di dalam database kita. 

Iya, iya.. maksudnya perintah SQL sudah dieksekusi.. :D

Oke, selanjutnya...

## Step 3 - Mengatur Konfigurasi {#step-3-mengatur-konfigurasi}
Langkah selanjutnya adalah mengatur konfigurasi untuk project login dan register codeigniter 3 kita. Buka ```config.php``` di direktori ```application/config/``` di dalam folder ci kita. :D

Cek line ke 26 di dalam file ```config.php``` untuk mengatur konfigurasi `base_url` project kita. kita atur ```base_url``` sesuai dengan nama folder ci yang kita buat. Karena nama folder ci saya ```ci3```, saya atur base_url seperti di bawah ini:

```php
$config['base_url'] = 'http://localhost/ci3/';
```

**Catatan:** Apabila teman-teman menggunakan virtual host setelah menggunakan tools seperti laravel herd atau laragon, teman-teman bisa langsung menuliskan virtual hostnya misalnya `$config['base_url'] = 'http://belajar_ci3.test`

![Mengatur Konfigurasi base url di aplikasi codeigniter 3](https://4.bp.blogspot.com/-3HQ7CesN6gw/WAwQZDxuijI/AAAAAAAAAk0/qWwRZUu5ZBQ1Ywc6fQK6crIEfsiyS4kMQCEw/s1600/Simple-Login-Register-CodeIgniter-gambar%2B4.jpg)

Simpan kembali file config.php dengan menekan tombol ctrl+s.

Selanjutnya, kita tambahkan pengaturan autoload. Di project yang akan kita buat ini, kita akan menggunakan beberapa library yang disediakan CodeIgniter (```form_validation```, ```session```, ```database```) dan library yang nanti kita buat sendiri (nanti kita kasih nama library ```simple_login```).

Supaya secara otomatis library-nya terpanggil, kita atur dulu di pengaturan ```autoload``-nya punya CodeIgniter.

Sekarang kita buka ```autoload.php``` masih di direktori yang sama, yaitu direktori ```application/config/```. Cek line ke 61 untuk mengatur autoload library. Temukan kode di bawah ini:

```php
$autoload['libraries'] = array(); 
```

Lalu kita sesuaikan dengan library yang akan kita load secara otomatis. Kita ubah menjadi:

```php
$autoload['libraries'] = array('form_validation','session','database','simple_login'); 
```

![Pengaturan autoload di codeigniter 3](https://4.bp.blogspot.com/-C5J_iYUNlR0/WAwQZsFREhI/AAAAAAAAAk4/xoSFOYGd7uMctqYcigKYSKACYeqIDhhmACEw/s1600/Simple-Login-Register-CodeIgniter-gambar%2B5.jpg)


Selain library kita juga akan menggunakan beberapa helper punya CodeIgniter nih teman-teman. Masih di file ```autoload.php```, kita cek line ke (kira-kira) 92 untuk mengatur autoload helper. Kita bakal nemuin kode ini:
```php
$autoload['helper'] = array(); 
```

Kita sesuaikan dengan helper yang akan kita gunakan di project:
```php
$autoload['helper'] = array('url','form','html'); 
```

Selanjutnya, kita atur juga autoload model. Cek line ke (kira-kira line) 135. Temukan baris kode untuk pengaturan autoload model seperti kode ini.

```php
$autoload['model'] = array(); 
```

Ubah menjadi:

```php
$autoload['model'] = array('m_account'); 
```

Simpan kembali file autoload.php dengan menekan tombol ctrl+s.

> **Sebagai catatan: ** kamu bisa juga load masing-masing helper, library, dan model di controller.

Nah, selanjutnya kita akan mengatur konfigurasi database. Buka file ```database.php```, masih di direktori yang sama yaitu ```application/config/```. Cek kira-kira line ke 76. Kamu dapat melihat sintaks seperti sintaks kode di bawah ini:
```php
 $db['default'] = array(
      'dsn'     => '',
      'hostname' => 'localhost',
      'username' => '',
      'password' => '',
      'database' => '',
      'dbdriver' => 'mysqli',
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

lalu atur konfigurasi database seperti di bawah ini:
```php
 $db['default'] = array(
      'dsn'     => '',
      'hostname' => 'localhost',
      'username' => 'root',
      'password' => '',
      'database' => 'dbci3',
      'dbdriver' => 'mysqli',
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

**catatan:** default credential database di xampp usernamenya ```root``` dan passwordnya kosong. Misalkan kamu pakai password untuk akses database. Isi password di atas dengan password kamu ya..

Kalau sudah, seperti biasa jangan lupa simpan kembali file database.php dengan menekan tombol ctrl+s.

Yang terakhir, buka file ```routes.php```. Iya, iya kamu bener. Itu masih di direktori ```application/config/``` :D

Cek di paliiiiing ujung, yaitu line 52. Kita ubah default controller menjadi :
```php
$route['default_controller'] = 'beranda';
```

Yep, nanti kita akan buat file Controller dengan nama ```Beranda.php``` dan kita jadikan sebagai controller yang pertama kali diakses pada saat pengguna mengakses web kita.

Oke selanjutnya simpan kembali filenya. Dan semua konfigurasi sudah selesai. :D

## Step 4 - Membuat file View {#step-4-coding-view}
Dan, langkah selanjutnya adalah coding, *Yeay!* :D

Sekarang kita akan buat beberapa file PHP. Yaitu file controller, library untuk login, model, dan juga view.

Sekarang kita akan membuat file views dulu teman-teman. Nah, sebelumnya kita buat folder baru dengan nama ```account``` di direktori ```application/views/```. Kamu bisa lihat di gambar ini.

![membuat folder untuk view](https://1.bp.blogspot.com/-llIWuSeNE6s/WAwQaIvHSKI/AAAAAAAAAlE/5epDA9hwz8gxSJroSYt2CAQn3rnrmAv2wCEw/s1600/Simple-Login-Register-CodeIgniter-gambar%2B8.jpg)

Lalu, selanjutnya kita akan buat beberapa file views di dalam folder 'account' tersebut.

**Pertama** kita buat file views dengan nama ```beranda.php```. File ini digunakan sebagai halaman utama project **Simple Login Register CodeIgnter** yang sedang kita bangun lho! Nah, sekarang buka teks editor kesayanganmu, lalu ketik kode berikut ini ya...

```php
<?php
defined('BASEPATH') OR exit('No direct script access allowed');
?><!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>
      Beranda | Tutorial Simple Login Register CodeIgniter @ http://recodeku.blogspot.com
  </title>
</head>
<body>
  <h1>Selamat Datang di Situs kami.</h1>
  <p>  
  Silakan klik link
  <?php echo anchor('login','Masuk'); ?>
  untuk masuk ke dalam sistem atau
  <?php echo anchor('register','Daftar'); ?>
  untuk mendaftar.
  </p>      
</body>
</html>
```

Ya tampilannya kita buat sederhana dulu saja, supaya tidak terlalu banyak kodenya. Setelah itu, simpan (tekan ctrl+s) file beranda.php di dalam folder ```account``` yang sudah kita buat tadi.

Selanjutnya kita buat file ```v_register.php```. Iya, teman-teman.. file ini digunakan sebagai halaman untuk pendaftaran atau registrasi akun. Sekarang ayo kita buka kembali teks editor kesayangan, lalu kita ketik sintaks kode di bawah ini ya.. ^^

```php
<?php defined('BASEPATH') OR exit('No direct script access allowed');
?><!DOCTYPE html>  
<head>
<meta charset="UTF-8">
<title>
  Pendaftaran Akun | Tutorial Simple Login Register CodeIgniter @ http://recodeku.blogspot.com
</title>
</head>
<body>
  <h2>Pendaftaran Akun</h2>

  <?php echo form_open('register');?>
  <p>Nama:</p>
  <p>
  <input type="text" name="name" value="<?php echo set_value('name'); ?>"/>
  </p>
  <p> <?php echo form_error('name'); ?> </p>

  <p>Username:</p>
  <p>
  <input type="text" name="username" value="<?php echo set_value('username'); ?>"/> 
  </p>
  <p> <?php echo form_error('username'); ?> </p>

  <p>Email:</p>
  <p>
  <input type="text" name="email" value="<?php echo set_value('email'); ?>"/>
  </p>
  <p> <?php echo form_error('email'); ?> </p>

  <p>Password:</p>
  <p>
  <input type="password" name="password" value="<?php echo set_value('password'); ?>"/>
  </p>
  <p> <?php echo form_error('password'); ?> </p>

  <p>Password Confirm:</p>
  <p>
  <input type="password" name="password_conf" value="<?php echo set_value('password_conf'); ?>"/>
  </p>
  <p> <?php echo form_error('password_conf'); ?> </p>

  <p>
  <input type="submit" name="btnSubmit" value="Daftar" />
  </p>

  <?php echo form_close();?>

  <p>
  Kembali ke beranda, Silakan klik <?php echo anchor(site_url().'/beranda','di sini..'); ?>
  </p>
</body>
</html>
```

Simpan file ```v_register.php``` di folder ```account```.

Dan selanjutnya, buat file views dengan nama ```v_success.php```. File ```v_success.php``` ini digunakan untuk menampilkan notifikasi jika proses registrasi berhasil. Ok, kita buka lagi teks editor kesayangan dan lalu kita ketik sintaks di bawah ini ya!

```php
<?php
defined('BASEPATH') OR exit('No direct script access allowed');
?><!DOCTYPE html>  
<head>
<meta charset="UTF-8">
<title>
  Notifikasi | Tutorial Simple Login Register CodeIgniter @ http://recodeku.blogspot.com
</title>
</head>
<body>
<h3><?php echo $message; ?></h3>
 <p><?php echo anchor('beranda','Kembali ke beranda'); ?></p>
</body>
</html>

```

Simpan filenya di folder ```account```.

Langkah berikutnya, kita akan membuat halaman untuk login dengan nama ```v_login.php```. Sekarang ayo kita ketik kode berikut ini!

```php
<?php
defined('BASEPATH') OR exit('No direct script access allowed');
?><!DOCTYPE html>  
<head>
<meta charset="UTF-8">
<title>
  Halaman Login | Tutorial Simple Login Register CodeIgniter @ http://recodeku.blogspot.com
</title>
</head>
<body>
   <h2>Halaman Login</h2>
   <?php
// Cetak jika ada notifikasi
   if($this->session->flashdata('sukses')) {
        echo '<p class="warning" style="margin: 10px 20px;">'.$this->session->flashdata('sukses').'</p>';
   }
   ?>

   <?php echo form_open('login');?>
   <p>Username:</p>
   <p>
        <input type="text" name="username" value="<?php echo set_value('username'); ?>"/>
   </p>
   <p> <?php echo form_error('username'); ?> </p>

   <p>Password:</p>
   <p>
        <input type="password" name="password" value="<?php echo set_value('password'); ?>"/>
   </p>
   <p> <?php echo form_error('password'); ?> </p>

   <p>
        <input type="submit" name="btnSubmit" value="Login" />
   </p>

   <?php echo form_close();?>

   <p>
        Kembali ke beranda, Silakan klik <?php echo anchor(site_url().'/beranda','di sini..'); ?>
   </p>
</body>
</html>
```

Yep, simpan file ```v_login.php``` di folder ```account```.

Berikutnya, kita buat file dengan nama ```v_dashboard.php```. Iya, kamu benar. Ketik lagi sintaks kode di bawah ini. :D

```php
<?php
defined('BASEPATH') OR exit('No direct script access allowed');
?><!DOCTYPE html>  
<head>
<meta charset="UTF-8">
<title>
  Dashboard | Tutorial Simple Login Register CodeIgniter @ http://recodeku.blogspot.com
</title>
</head>
<body>
   <h3>Dashboard</h3>
   <p>
        Selamat datang di halaman dashboard, <?php echo ucfirst($this->session->userdata('username')); ?>!
        Untuk logout dari sistem, silakan klik <?php echo anchor('login/logout','di sini...'); ?>
   </p>
</body>
</html>
```

Yep, simpan filenya. Tetap di folder yang sama, yaitu folder ```account```.

Nah, jadi setelah kita coding viewnya,  di folder ```account``` ada 5 file views, yaitu file ```beranda.php```, ```v_dashboard.php```, ```v_login.php```, ```v_register.php``` dan ```v_success.php```.

## Step 5 - Membuat Model {#step-5-coding-model}
Kawan, selanjutnya kita akan membuat file model dengan nama ```M_account.php```. Di dalam file ```M_account.php``` terdapat sebuah class model dengan nama ```M_account``` yang memiliki satu method yaitu method ```daftar()```. Fungsi method ```daftar()``` ini untuk menambah (insert) data akun baru ke dalam tabel ```users```.

Sekarang kamu buka kembali teks editor kesayanganmu. Yuk kita ketik kode untuk file ```M_account.php```!

```php

<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class M_account extends CI_Model{

    function daftar($data)
    {
         $this->db->insert('users',$data);
    }
}

```


Setelah kamu ketik kodenya, jangan lupa simpan file model ```M_account.php``` di direktori ```application/models/```.

## Step 6 - Membuat library untuk login {#step-6-coding-library}
Setelah membuat file model, kita akan membuat sebuah library sederhana yang nantinya digunakan untuk login, proteksi halaman dan juga logout dengan nama file ```Simple_login.php```. Di dalam library ini terdapat tiga method, yaitu:
1. `login()` :: Digunakan untuk cek ketersediaan username dan password pada table users, jika tersedia, set session berdasar data user dari table users.
2. `cek_login()` :: Digunakan untuk proteksi halaman dengan cara mengecek data session login, apabila tidak ada, maka pengguna akan dialihkan ke halaman login.
3. `logout()` :: Untuk keluar dari halaman dashboard. Hapus session, lalu set notifikasi dalam flashdata session kemudian alihkan ke halaman login.

Nah, sekarang yuk kita koding lagi. Buka teks editor kesayanganmu, lalu ketik kode di bawah ini.
```php
<?php
defined('BASEPATH') OR exit('No direct script access allowed');

/*
* Simple_login Class
* Class ini digunakan untuk fitur login, proteksi halaman dan logout
* @author  Gun Gun Priatna
* @url    https://recodeku.blogspot.com
*/

class Simple_login {

  // SET SUPER GLOBAL
  var $CI = NULL;

  /**
   * Class constructor
   *
   * @return   void
   */
  public function __construct() {
      $this->CI =& get_instance();
  }

  /*
  * cek username dan password pada table users, jika ada set session berdasar data user dari
  * table users.
  * @param string username dari input form
  * @param string password dari input form
  */
  public function login($username, $password) {
      
      //cek username dan password
      $query = $this->CI->db->get_where('users',array('username'=>$username,'password' => md5($password)));

      if($query->num_rows() == 1) {
          //ambil data user berdasar username
          $row  = $this->CI->db->query('SELECT id_user FROM users where username = "'.$username.'"');
          $admin     = $row->row();
          $id   = $admin->id_user;

          //set session user
          $this->CI->session->set_userdata('username', $username);
          $this->CI->session->set_userdata('id_login', uniqid(rand()));
          $this->CI->session->set_userdata('id', $id);

          //redirect ke halaman dashboard
          redirect(site_url('dashboard'));
      }else{

          //jika tidak ada, set notifikasi dalam flashdata.
          $this->CI->session->set_flashdata('sukses','Username atau password anda salah, silakan coba lagi.. ');

          //redirect ke halaman login
          redirect(site_url('login'));
      }
       return false;
   }
  
  /**
   * Cek session login, jika tidak ada, set notifikasi dalam flashdata, lalu dialihkan ke halaman
   * login
   */
  public function cek_login() {

      //cek session username
      if($this->CI->session->userdata('username') == '') {

          //set notifikasi
          $this->CI->session->set_flashdata('sukses','Anda belum login');

          //alihkan ke halaman login
          redirect(site_url('login'));
      }
  }

  /**
   * Hapus session, lalu set notifikasi kemudian di alihkan
   * ke halaman login
   */
  public function logout() {
      $this->CI->session->unset_userdata('username');
      $this->CI->session->unset_userdata('id_login');
      $this->CI->session->unset_userdata('id');
      $this->CI->session->set_flashdata('sukses','Anda berhasil logout');
      redirect(site_url('login'));
  }
}
```

Setelah selesai, kita simpan file library ```Simple_login.php``` di direktori ```application/libraries/```.

## Step 7 - Membuat Controller {#step-7-coding-controller}
Langkah berikutnya adalah membuat file controller. Ada 4 file controller yang akan kita buat yaitu ```Beranda.php```, ```Register.php```, ```Login.php``` dan ```Dashboard.php```.

Nah, sekarang kita buat file controllers yang pertama yaitu ```Beranda.php```. Controller `Beranda.php` ini akan menangani halaman beranda atau halaman utama dari project kita. Di halaman ini nanti ada link yang menuju ke halaman login dan juga halaman register.

Buka kembali text editor, lalu di dalam file `Beranda.php` kita deklarasikan class `Beranda`.

```php
<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Beranda extends CI_Controller {

    public function index()
    {
         $this->load->view('account/beranda');
    }
}

```

Simpan file  controller ```Beranda.php``` di direktori ```application/controllers/```.

\* \* \*

File controller berikutnya adalah ```Register.php```, controller ini yang akan menangani proses pendaftaran akun. Yuk kita ketik lagi kodenya. Ini sintaks kodenya:

```php

<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Register extends CI_Controller {
   
   function __construct(){
       parent::__construct();
       $this->load->library(array('form_validation'));
       $this->load->helper(array('url','form'));
       $this->load->model('m_account'); //call model
   }

   public function index() {

       $this->form_validation->set_rules('name', 'NAME','required');
       $this->form_validation->set_rules('username', 'USERNAME','required');
       $this->form_validation->set_rules('email','EMAIL','required|valid_email');
       $this->form_validation->set_rules('password','PASSWORD','required');
       $this->form_validation->set_rules('password_conf','PASSWORD','required|matches[password]');
       if($this->form_validation->run() == FALSE) {
           $this->load->view('account/v_register');
       }else{

           $data['nama']   =    $this->input->post('name');
           $data['username'] =    $this->input->post('username');
           $data['email']  =    $this->input->post('email');
           $data['password'] =    md5($this->input->post('password'));

           $this->m_account->daftar($data);
           
           $pesan['message'] =    "Pendaftaran berhasil";
           
           $this->load->view('account/v_success',$pesan);
       }
   }
}

```

Sama, file ```Register.php``` ini kita simpan di direktori ```application/controllers/``` juga.

\* \* \*

Sekarang kita buat file controller yang ketiga, ```Login.php```, berikut ini adalah sintaks kodenya:

```php

<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Login extends CI_Controller {

   public function index() {

       // Fungsi Login
       $valid = $this->form_validation;
       $username = $this->input->post('username');
       $password = $this->input->post('password');
       $valid->set_rules('username','Username','required');
       $valid->set_rules('password','Password','required');

       if($valid->run()) {
           $this->simple_login->login($username,$password, base_url('dashboard'), base_url('login'));
       }
       // End fungsi login
       $this->load->view('account/v_login');
   }

   public function logout(){
       $this->simple_login->logout();
   }        
}
```

Simpan di direktori ```application/controllers/``` dengan nama file ```Login.php```.

\* \* \*

Dan controller yang terakhir adalah ```Dashboard.php```. *Type this syntax ya!* :D

```php
<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Dashboard extends CI_Controller {
   function __construct(){
       parent::__construct();
       $this->simple_login->cek_login();
   }

   //Load Halaman dashboard
   public function index() {
       $this->load->view('account/v_dashboard');
   }
}
```

Simpan di direktori yang sama yaitu ```application/controllers/``` dengan nama ```Dashboard.php```.

\* \* \*

Jadi, kita punya empat file controller, yaitu ```Beranda.php```, ```Dashboard.php```, ```Login.php``` dan ```Register.php```.

## Step 8 - Uji Coba Project {#step-8-uji-coba}
Nah setelah proses pengembangan project login register codeigniter selesai, langkah selanjutnya adalah menguji coba project kita. Buka browser, lalu kita run project kita dengan mengetikan url ini di addressbar.
```
http://localhost/ci3/
```

Nah kalau tidak ada kendala atau error, halaman yang ditampilkan ketika pertama kali project kita dirun itu tampak seperti gambar di bawah ini.

![run project codeigniter 3 di browser](https://4.bp.blogspot.com/-t8whRB4-jfA/WAwQX_tfWTI/AAAAAAAAAlQ/h3Isgzo__EsribYYOYRLZYWcgNjQZX_7wCEw/s1600/Simple-Login-Register-CodeIgniter-gambar%2B13.jpg)

Karena kita belum punya akun untuk login, sekarang kita harus daftar terlebih dahulu.. Sekarang kita coba klik link ```daftar``` untuk mendaftar.

![uji coba fitur register](https://1.bp.blogspot.com/-kzwo5zDVtSM/WAwQX5LvY7I/AAAAAAAAAlQ/CGfHetoVp8wEuae2AymOwpojaoqQDMwBgCEw/s1600/Simple-Login-Register-CodeIgniter-gambar%2B14.jpg)

Coba kamu isi formnya. Saya juga coba isi. :D

![Uji coba register dengan mengisi form](https://2.bp.blogspot.com/-EfEm75GYhgw/WAwQX8z1rCI/AAAAAAAAAlQ/e_Ys9aTBCRcz-NGwe6WlXoL8lu1mFEdUwCEw/s1600/Simple-Login-Register-CodeIgniter-gambar%2B15.jpg)

Lalu klik tombol daftar, maka akan muncul pemberitahuan pendaftaran sudah berhasil.  *yeay!* :D

![Berhasil uji coba register](https://2.bp.blogspot.com/-WhEDaF1iFRc/WAwQYYEkYpI/AAAAAAAAAlQ/QoIV86PyiHQaWwhtWnjlRmwbSk3k_TZ5gCEw/s640/Simple-Login-Register-CodeIgniter-gambar%2B16.jpg)

Nah selanjutnya, kita klik link Kembali ke beranda. Lalu kita coba login dengan mengklik link masuk.

Coba kamu isi username dan password yang kamu isi di form login. :D
![Mengisi username dan password untuk login](https://2.bp.blogspot.com/-HJrFIWOmyvw/WAwQYgAPDaI/AAAAAAAAAlQ/JoUD0Hcv_jE1Jc1qj4uDZa2tDyFXxQdmACEw/s1600/Simple-Login-Register-CodeIgniter-gambar%2B17.jpg)

Lalu klik tombol Login.

Tadaaa!!! Kita berhasil login menggunakan akun kita. :D


![proses login berhasil dan menampilkan halaman dashboard](https://1.bp.blogspot.com/-XMOJ4PqiBSw/WAwQYnWANKI/AAAAAAAAAlQ/d-sfGQ6ATDEXyEC_NX4BDP52XvJuHegbwCEw/s640/Simple-Login-Register-CodeIgniter-gambar%2B18.jpg)

Untuk logout, klik link 'di sini'. Maka kita akan kembali ke halaman login. :D

\* \* \*

## Penutup {#penutup}
Di tutorial edisi kali ini kita sudah coba membuat sebuah project sederhana untuk proses login dan register di aplikasi yang dibangun menggunakan codeigniter 3. Dari fitur login dan register ini, kita sudah belajar menerapkan validasi untuk form, menggunakan query builder, session dan juga membuat library sederhana.

Tentu project sederhana ini jauh dari sempurna. Ada banyak ruang yang bisa kita kembangkan, salah satunya menambahkan fitur forgot password. Nah cara membuat [fitur forgot password](https://qadrlabs.com/post/tutorial-codeigniter-membuat-fitur-forgot-password) ini akan kita bahas di tutorial selanjutnya.

Oh iya kamu juga bisa mendownload full source codenya di [sini](https://github.com/doublegunz/simple-login-register-using-codeigniter/archive/master.zip).

Semangat terus ya! Selamat belajar.. Semoga menyenangkan.. :D

## Referensi:  {#referensi}
* [Web Official CodeIgniter](https://codeigniter.com)
* [Dokumentasi CodeIgniter 3](https://codeigniter.com/userguide3/index.html)
* [Tentang validasi](https://codeigniter.com/userguide3/libraries/form_validation.html?highlight=validation)
* [query builder](https://codeigniter.com/userguide3/database/query_builder.html)
* [membuat library](https://codeigniter.com/userguide3/general/creating_libraries.html?highlight=creating%20library)