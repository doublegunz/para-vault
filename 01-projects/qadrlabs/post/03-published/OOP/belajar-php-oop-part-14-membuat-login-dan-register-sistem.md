---
title: "Belajar PHP OOP Part 14 Membuat Login Dan Register Sistem"
slug: "belajar-php-oop-part-14-membuat-login-dan-register-sistem"
category: "OOP"
date: "2016-08-19"
status: "published"
---

Pada edisi [belajar PHP OOP](https://qadrlabs.com/series/belajar-php-oop) kali ini, kita akan mempelajari cara membuat sistem login dan register dengan pendekatan *Object-Oriented Programming* (OOP). Berbeda dari tutorial serupa, panduan ini tidak hanya fokus pada implementasi fungsionalitas, tetapi juga mengajarkan cara menerapkan *class diagram* ke dalam bahasa pemrograman PHP. Dengan langkah-langkah yang sederhana, kita akan membangun aplikasi autentikasi yang ringan namun efektif. Siap untuk mulai belajar? Mari kita lanjutkan!

>  [Baca: [Membuat Simple Login dan Register Menggunakan CodeIgniter](https://qadrlabs.com/post/membuat-simple-login-dan-register-menggunakan-codeigniter)]. 

## Learning Overview{#overview}
Dalam tutorial ini, kita akan membangun sebuah sistem login dan register sederhana dengan pendekatan *Object-Oriented Programming* (OOP) menggunakan PHP. Proyek ini dirancang untuk memberikan pemahaman mendalam tentang konsep OOP dan cara mengintegrasikannya ke dalam aplikasi autentikasi berbasis web.

### **Apa yang Akan Kita Bangun?**
- Sistem autentikasi pengguna dengan fitur:
  - **Register**: Mendaftarkan akun baru.
  - **Login**: Masuk ke dalam sistem.
  - **Logout**: Keluar dari sesi pengguna.
- Struktur kode modular dengan implementasi *class diagram* untuk pengelolaan autentikasi.
- Antarmuka pengguna sederhana untuk login dan registrasi.

### **Apa yang Akan Kita Pelajari?**
- Bagaimana mendesain dan menerapkan *class diagram* ke dalam kode PHP. Class diagram yang digunakan menggambarkan struktur *Auth* class sebagai inti dari sistem autentikasi. Berikut adalah class diagram yang digunakan dalam tutorial ini:

![Class Diagram - Auth](https://1.bp.blogspot.com/-ZhRucPtSQN4/V7cvFHH_wFI/AAAAAAAAAeE/8IvydXZP7Jsf8aWzufINU8ufYF138gMNgCLcB/w400-h296/belajar%2Bphp%2Boop%2B14%2B-%2Bgambar%2B1.png)

- Penggunaan **PDO (PHP Data Objects)** untuk pengelolaan koneksi database yang aman.
- Teknik pengamanan data seperti hashing password menggunakan fungsi `password_hash()` dan verifikasi dengan `password_verify()`.
- Pengelolaan sesi pengguna menggunakan `session_start()`.

### **Apa Tujuan dari Tutorial Ini?**
- Memberikan pemahaman praktis tentang penerapan konsep OOP di dunia nyata.
- Membiasakan diri dengan teknik pengamanan dasar untuk membangun aplikasi web.
- Menghasilkan kerangka kerja dasar yang dapat digunakan untuk pengembangan proyek web yang lebih besar.

Dengan menyelesaikan tutorial ini, Anda tidak hanya memahami teori OOP, tetapi juga dapat langsung mengaplikasikannya dalam proyek autentikasi yang aman dan terstruktur. Mari kita mulai langkah pertama!

## Step 1 - Persiapan{#step-1}
Seperti biasa, Sebelum memulai alangkah baiknya kita berdoa terlebih dahulu, supaya codingnya berjalan dengan lancar. Hihi. :)
Selanjutnya, kita buat dulu folder `Auth` di dalam direktori `document root` kamu atau folder `htdocs` (Asumsi kamu pakai Xampp). Folder `Auth` ini nanti akan kita gunakan untuk menyimpan file-file php dari aplikasi yang kita buat.

## Step 2 - Membuat Database{#step-2}
Langkah selanjutnya adalah membuat database. Buka phpMyadmin, lalu kita buat database dengan nama `belajar_oop`. Yep, kalau kamu sudah mencoba edisi sebelumnya, kamu boleh pakai database di edisi sebelumnya. Soalnya masih pakai database yang sama. 

Langkah selanjutnya adalah membuat table baru yaitu table `users` . Klik menu SQL di phpMyadmin.

![buat tabel - qadrLabs](https://1.bp.blogspot.com/-ZbVcjRnskF0/V7cvKGJTHhI/AAAAAAAAAeI/ccb4jLBQmEYQz-tpnJ2FET46k6XJn8StACLcB/s16000/belajar%2Bphp%2Boop%2B14%2B-%2Bgambar%2B2.png)

Lalu, kamu ketik perintah SQL ini di dalam textarea :
```bash
CREATE TABLE IF NOT EXISTS `users` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(255) NOT NULL,
    `email` varchar(255) NOT NULL,
    `password` varchar(255) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

```
Kalau sudah selesai diketik, kita klik tombol 'Go' untuk eksekusi perintah SQL tersebut.

## Step 3 - Konfigurasi Database{#step-3}
Pada tahapan ini kita akan membuat file yang di dalamnya terdapat kode untuk konfigurasi database. File konfigurasi database ini nanti kita gunakan di beberapa file. Sekarang buka kembali text editor, lalu buat file baru dengan nama `dbconfig.php` di folder `Auth` yang sudah kita buat di bagian persiapan tadi. Lalu kita ketik kode di bawah ini:
```php
<?php

try {
    $con = new PDO('mysql:host=localhost;dbname=db_belajar', 'root', '', array(PDO::ATTR_PERSISTENT => true));
} catch (PDOException $e) {
    echo $e->getMessage();
}

include_once 'Auth.php';

$user = new Auth($con);

```

Ok, kalau sudah kamu ketik langsung disimpan ya! ^^

Pada baris kode di atas, kita akan membuat objek baru dari class `PDO` yang disimpan dalam variabel `$con`. Dan seperti biasa, kita masukkan beberapa parameter saat membuat objek `$con` seperti informasi data source name dan user credential database kita. Selain konfigurasi database, dalam file `dbconfig.php`, kita juga akan memanggil file `Auth.php` menggunakan fungsi `include_once()`.  Di baris terakhir kita buat objek baru dengan `$con` sebagai parameter, yaitu `$user`. `$user` ini merupakan instansiasi dari `Auth` class.

## Step 4 - Membuat file Class Auth{#step-4}
Di file konfigurasi database terdapat kode untuk melampirkan file `Auth.php`. Karena file tersebut belum kita buat, tentu akan ada error ketika file konfigurasi tersebut kita coba run.

Sekarang kita buat file baru dengan nama `Auth.php`, lalu ketik kode berikut ini:
```php
 
<?php

/**
 * Class Auth untuk melakukan login dan registrasi user baru
 */
class Auth
{
    /**
     * @var
     * Menyimpan Koneksi database
     */
    private $db;

    /**
     * @var
     * Menyimpan Error Message
     */
    private $error;

    /**
     * @param $db_conn
     * Contructor untuk class Auth, membutuhkan satu parameter yaitu koneksi ke database
     */
    public function __construct($db_conn)
    {
        $this->db = $db_conn;

        // Mulai session
        session_start();
    }
    /**
     * @param $name
     * @param $email
     * @param $password
     * @return bool
     *
     * Registrasi User baru
     */
    public function register($name, $email, $password)
    {
        try {
            // buat hash dari password yang dimasukkan
            $hashPasswd = password_hash($password, PASSWORD_DEFAULT);

            //Masukkan user baru ke database
            $stmt = $this->db->prepare("INSERT INTO users(name, email, password) VALUES(:name, :email, :pass)");
            $stmt->bindParam(":name", $name);
            $stmt->bindParam(":email", $email);
            $stmt->bindParam(":pass", $hashPasswd);

            $stmt->execute();

            return true;
        } catch (PDOException $e) {
            // Jika terjadi error

            if ($e->errorInfo[0] == 23000) {
                //errorInfor[0] berisi informasi error tentang query sql yg baru dijalankan
                //23000 adalah kode error ketika ada data yg sama pada kolom yg di set unique
                $this->error = "Email sudah digunakan!";

                return false;
            } else {
                echo $e->getMessage();

                return false;
            }
        }
    }

    /**
     * @param $email
     * @param $password
     * @return bool
     *
     * fungsi login user
     */
    public function login($email, $password)
    {
        try {
            // Ambil data dari database
            $stmt = $this->db->prepare("SELECT * FROM users WHERE email = :email");
            $stmt->bindParam(":email", $email);
            $stmt->execute();
            $data = $stmt->fetch();

            // Jika jumlah baris > 0
            if ($stmt->rowCount() > 0) {
                // jika password yang dimasukkan sesuai dengan yg ada di database
                if (password_verify($password, $data['password'])) {
                    $_SESSION['user_session'] = $data['id'];

                    return true;
                } else {
                    $this->error = "Email atau Password Salah";

                    return false;
                }
            } else {
                $this->error = "Email atau Password Salah";

                return false;
            }
        } catch (PDOException $e) {
            echo $e->getMessage();

            return false;
        }
    }

    /**
     * @return true|void
     *
     * fungsi cek login user
     */
    public function isLoggedIn()
    {
        // Apakah user_session sudah ada di session

        if (isset($_SESSION['user_session'])) {
            return true;
        }
    }

    /**
     * @return false
     *
     * fungsi ambil data user yang sudah login
     */
    public function getUser()
    {
        // Cek apakah sudah login
        if (!$this->isLoggedIn()) {
            return false;
        }

        try {
            // Ambil data user dari database
            $stmt = $this->db->prepare("SELECT * FROM users WHERE id = :id");
            $stmt->bindParam(":id", $_SESSION['user_session']);
            $stmt->execute();

            return $stmt->fetch();
        } catch (PDOException $e) {
            echo $e->getMessage();

            return false;
        }
    }

    /**
     * @return true
     *
     * fungsi Logout user
     */
    public function logout()
    {
        // Hapus session
        session_destroy();
        // Hapus user_session
        unset($_SESSION['user_session']);

        return true;
    }

    /**
     * @return mixed
     *
     * fungsi ambil error terakhir yg disimpan di variable error
     */
    public function getLastError()
    {
        return $this->error;
    }
}
```


Setelah kita ketik kode di atas, simpan kembali file `Auth.php` di folder Auth.

> **Note**: sebagai catatan, ketika kita membuat sebuah class, pastikan nama file php dengan nama class nya sama. Pastikan penulisan huruf besar dan kecilnya sama. Selain itu, nama class biasanya diawali dengan huruf besar.

Pada baris kode di atas `Auth` Class ini merupakan penerapan Class Diagram di atas, yang berisi fungsi-fungsi yang berhubungan dengan autentikasi pengguna aplikasi, seperti Register, login dan fungsi lainnya. Pada bagian constructor dari `Auth` class, selain variabel `$db`, kita juga akan menggunakan fungsi `session_start()` untuk memulai session.

> Session adalah tempat untuk menyimpan informasi sementara ketika kamu membuka suatu website. variable session akan hilang ketika dihapus atau menutup broswer.

Selain fungsi `session_start()`, kita juga akan menggunakan fungsi `password_hash()` pada method register dan fungsi `password_verify()` pada method login. (Pembahasan `password_hash()` sama `password_verify()` sudah saya bahas di [postingan](https://qadrlabs.com/post/menggunakan-password-hash-dan-password-verify) beberapa waktu yang lalu) ^^

## Step 5 - Membuat file login.php{#step-5}
Pada tahapan ini kita akan membuat sebuah file yang akan menangani proses login. File ini akan kita gunakan untuk menampilkan form login dan juga prosesnya.

Sekarang buat file `login.php`, lalu ketik kode berikut ini:
```php
<?php

// Lampirkan dbconfig
require_once "dbconfig.php";

// Cek status login user
if ($user->isLoggedIn()) {
    header("location: index.php"); //redirect ke index
}

//jika ada data yg dikirim
if (isset($_POST['kirim'])) {
    $email = $_POST['email'];

    $password = $_POST['password'];

    // Proses login user
    if ($user->login($email, $password)) {
        header("location: index.php");
    } else {
        // Jika login gagal, ambil pesan error
        $error = $user->getLastError();
    }
}

?>

<!DOCTYPE html>
<html>
<head>

    <meta charset="utf-8">

    <title>Login</title>

    <link rel="stylesheet" href="style.css" media="screen" title="no title" charset="utf-8">

</head>
<body>
<div class="login-page">

    <div class="form">

        <form class="login-form" method="post">

            <?php if (isset($error)) : ?>

                <div class="error">

                    <?php echo $error ?>

                </div>

            <?php endif; ?>

            <input type="email" name="email" placeholder="email" required />

            <input type="password" name="password" placeholder="password" required />

            <button type="submit" name="kirim">login</button>

            <p class="message">Not registered? <a href="register.php">Create an account</a></p>

        </form>

    </div>

</div>

</body>
</html>

```

Simpan file `login.php` di folder `Auth`.

## Step 6 - Membuat file register.php{#step-6}
Sudah terlihat di namanya ya.. file ini akan kita gunakan untuk menampilkan form dan juga proses registrasi user. Sekarang yuk kita buat file lagi dengan `register.php`, lalu kita ketik kode di bawah ini ya! ^^
```php
<?php

// Lampirkan dbconfig
require_once "dbconfig.php";

// Cek status login user
if($user->isLoggedIn()) {
    header("location: index.php"); //Redirect ke index
}

//Cek adanya data yang dikirim
if(isset($_POST['kirim'])) {
    $nama = $_POST['nama'];
    $email = $_POST['email'];
    $password = $_POST['password'];

    // Registrasi user baru
    if($user->register($nama, $email, $password)) {
        // Jika berhasil set variable success ke true
        $success = true;
    } else {
        // Jika gagal, ambil pesan error
        $error = $user->getLastError();
    }
}

?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Register</title>
    <link rel="stylesheet" href="style.css" media="screen" title="no title" charset="utf-8">

</head>
<body>
<div class="login-page">
    <div class="form">
        <form class="register-form" method="post">
            <?php if (isset($error)): ?>
                <div class="error">
                    <?php echo $error ?>
                </div>
            <?php endif; ?>

            <?php if (isset($success)): ?>
                <div class="success">
                    Berhasil mendaftar. Silakan <a href="login.php">login</a>.
                </div>
            <?php endif; ?>

            <input type="text" name="nama" placeholder="nama" required/>
            <input type="email" name="email" placeholder="email address" required/>
            <input type="password" name="password" placeholder="password" required/>
            <button type="submit" name="kirim">create</button>
            <p class="message">Already registered? <a href="login.php">Sign In</a></p>

        </form>
    </div>
</div>
</body>
</html>

```

Kalau sudah diketik, kita simpan file `register.php` di folder `Auth` juga.

## Step 7 - Membuat file logout.php{#step-7}
File ini kita gunakan untuk logout dari aplikasi. Sekarang kita buat file baru dengan nama `logout.php` ya!

```php
<?php  
  
// Lampirkan dbconfig  
require_once "dbconfig.php";  
  
// Logout! hapus session user  
$user->logout();  
  
// Redirect ke login  
header('location: login.php');
```

Kalau sudah, kita simpan file `logout.php` di folder yang sama. ^^

## Step 8 - Membuat file index.php{#step-8}
Kalau sudah login, biasanya kita dialihkan ke halaman user. Nah, file `index.php` ini fungsinya untuk menampilkan halaman user tersebut. Sekarang buka kembali text editor kesayanganmu. Buat file baru dengan nama `index.php`, lalu ketik kode di bawah ini ya..
```php
 <?php  
  
// Lampirkan dbconfig  
require_once "dbconfig.php";  
  
// Cek status login user  
if (!$user->isLoggedIn()) {  
    header("location: login.php"); //Redirect ke halaman login  
}  
  
// Ambil data user saat ini  
$currentUser = $user->getUser();  
?>  
  
<!DOCTYPE html>  
<html>  
<head>  
    <meta charset="utf-8">  
    <title>Home</title>  
    <link rel="stylesheet" href="style.css" media="screen" title="no title" charset="utf-8">  
</head>  
<body>  
<div class="container">  
    <div class="info">  
        <h1>Selamat datang <?php echo $currentUser['name'] ?></h1>  
    </div>  
    <a href="logout.php">  
        <button type="button">Logout</button>  
    </a></div>  
</body>  
</html> 
```

Simpan file `index.php` di folder Auth.

Pada baris kode di atas, terdapat kode proteksi halaman dengan mengecek status user, apakah user tersebut sudah login atau belum. Jika belum nanti akan dialihkan ke halaman login. Selain itu, pada baris kode berikutnya terdapat kode yang digunakan untuk mengambil data user, lalu di simpan dalam variabel `$currentUser`. Dan terakhir, di baris kode html, terdapat kode untuk menampilkan nama user dan juga tombol logout pada line berikutnya.

## Step 9 - Membuat file style.css{#step-9}
Daaaan terakhir, yuk kita buat file `style.css` untuk mempercantik tampilan aplikasi yang kita buat. Nah, buka kembali text editor kesayanganmu. Buat file `style.css`, lalu ketik kode di bawah ini ya!
```css
 @import url('https://fonts.googleapis.com/css2?family=Roboto&display=swap');  
  
  
body {  
  
    background: #76b852;  
    /* fallback for old browsers */  
  
    background: -webkit-linear-gradient(right, #76b852, #8DC26F);  
    background: -moz-linear-gradient(right, #76b852, #8DC26F);  
    background: -o-linear-gradient(right, #76b852, #8DC26F);  
    background: linear-gradient(to left, #76b852, #8DC26F);  
    font-family: "Roboto", sans-serif;  
    -webkit-font-smoothing: antialiased;  
    -moz-osx-font-smoothing: grayscale;  
}  
  
.login-page {  
    width: 360px;  
    padding: 8% 0 0;  
    margin: auto;  
}  
  
.form {  
    position: relative;  
    z-index: 1;  
    background: #FFFFFF;  
    max-width: 360px;  
    margin: 0 auto 100px;  
    padding: 45px;  
    text-align: center;  
    box-shadow: 0 0 20px 0 rgba(0, 0, 0, 0.2), 0 5px 5px 0 rgba(0, 0, 0, 0.24);  
}  
  
.form .error {  
    color: #FFFFFF;  
    background: #ef3b3a;  
    border: 0;  
    margin: 0 0 15px;  
    padding: 15px;  
}  
  
.form .success {  
    color: #FFFFFF;  
    background: #30A2A0;  
    border: 0;  
    margin: 0 0 15px;  
    padding: 15px;  
}  
  
.form input {  
    font-family: "Roboto", sans-serif;  
    outline: 0;  
    background: #f2f2f2;  
    width: 100%;  
    border: 0;  
    margin: 0 0 15px;  
    padding: 15px;  
    box-sizing: border-box;  
    font-size: 14px;  
}  
  
button {  
    font-family: "Roboto", sans-serif;  
    text-transform: uppercase;  
    outline: 0;  
    background: #4CAF50;  
    width: 100%;  
    border: 0;  
    padding: 15px;  
    color: #FFFFFF;  
    font-size: 14px;  
    -webkit-transition: all 0.3 ease;  
    transition: all 0.3 ease;  
    cursor: pointer;  
}  
  
button:hover, button:active, button:focus {  
    background: #43A047;  
}  
  
.form .message {  
    margin: 15px 0 0;  
    color: #b3b3b3;  
    font-size: 12px;  
}  
  
.form .message a {  
    color: #4CAF50;  
    text-decoration: none;  
}  
  
.container {  
    position: relative;  
    z-index: 1;  
    max-width: 300px;  
    margin: 0 auto;  
}  
  
.container:before, .container:after {  
    content: "";  
    display: block;  
    clear: both;  
}  
  
.container .info {  
    margin: 50px auto;  
    text-align: center;  
}  
  
.container .info h1 {  
    margin: 0 0 15px;  
    padding: 0;  
    font-size: 36px;  
    font-weight: 300;  
    color: #1a1a1a;  
}  
  
.container .info span {  
    color: #4d4d4d;  
    font-size: 12px;  
}  
  
.container .info span a {  
    color: #000000;  
    text-decoration: none;  
}  
  
.container .info span .fa {  
    color: #EF3B3A;  
}

```

Simpan file `style.css` di folder Auth.

Ya, codingnya sudah selesai. Jadi, di folder Auth ada 7 file (file php dan css).

```
Auth/
├── Auth.php
├── dbconfig.php
├── index.php
├── login.php
├── logout.php
├── register.php
└── style.css
```

## Step 10 - Uji Coba{#step-10}
Selanjutnya, kita coba run program yang kita buat. Buka browser kesayanganmu, lalu ketik di address bar :
```
localhost/auth/
```
Maka, akan tampil halaman login dari aplikasi kita.

![belajar php oop - qadrLabs](https://4.bp.blogspot.com/-O86KQO3sLKY/V7cvipRv7BI/AAAAAAAAAeU/6pNBVA9QlTUrMQQ5Pb3fybo6399alGmkQCLcB/s16000/belajar%2Bphp%2Boop%2B14%2B-%2Bgambar%2B5.png)

Karena kita belum punya akun, yuk kita buat dulu. Klik tautan 'Create an account' untuk membuat akun. Lalu kita isi form registrasi user.

![belajar php oop -qadrLabs](https://3.bp.blogspot.com/-Lj5wtCnIog4/V7cvnMpiJ1I/AAAAAAAAAeY/xeHOkx2DV8U_-JXOeMh4vNqUZqiNS7Y3gCLcB/s16000/belajar%2Bphp%2Boop%2B14%2B-%2Bgambar%2B6.png)

kalau sudah diisi, klik tombol 'Create'. Nanti bakalan tampil pemberitahuan kalau kita sudah berhasi mendaftar.

![belajar php oop - qadrLabs](https://2.bp.blogspot.com/-TTZn3_5Ql9Y/V7cvsQhSOOI/AAAAAAAAAec/Cftw-q0EIvIIUdHt6sfMiwzhLXygCtczgCLcB/s16000/belajar%2Bphp%2Boop%2B14%2B-%2Bgambar%2B7.png)

Nah, selanjutnya kita kembali ke halaman login dengan mengklik tautan login atau Sign In. Isi form login dengan mengisi email dan juga passwordnya, lalu klik tombol 'LOGIN'. 

Voila~~ kita berhasil login dan masuk ke halaman user. Dan untuk logout dari aplikasi kamu pasti sudah tahu mesti ngapain kan? ^^

![belajar php oop -qadrLabs](https://1.bp.blogspot.com/-anDxKzdcdYM/V7cvxSldrZI/AAAAAAAAAek/wcSvT5nF93kX8DbeU97CC8rSee825UiUgCLcB/s16000/belajar%2Bphp%2Boop%2B14%2B-%2Bgambar%2B8.png)

## Penutup {#penutup}
Melalui tutorial ini, kita telah belajar cara membuat sistem login dan register menggunakan pendekatan *Object-Oriented Programming* (OOP) di PHP. Dengan membangun fitur autentikasi seperti register, login, dan logout, kita juga telah mempelajari berbagai konsep penting, termasuk:

- Mendesain dan mengimplementasikan *class diagram* ke dalam kode PHP.
- Menggunakan **PDO** untuk koneksi database yang aman.
- Mengelola hashing dan verifikasi password dengan fungsi bawaan PHP.
- Menangani sesi pengguna menggunakan fungsi `session_start()`.

Tidak hanya itu, struktur kode yang modular dan mudah dipahami ini dapat menjadi dasar untuk mengembangkan proyek aplikasi yang lebih kompleks di masa depan. Anda bisa menambahkan fitur tambahan seperti *forgot password*, otorisasi berbasis peran (role-based access), atau integrasi API untuk meningkatkan fungsionalitas aplikasi.

Jika Anda memiliki pertanyaan atau kesulitan saat mengikuti langkah-langkah di tutorial ini, jangan ragu untuk meninggalkan komentar di bawah. Kami dengan senang hati akan membantu Anda. Jangan lupa untuk membaca artikel lainnya dalam seri [Belajar PHP OOP](https://qadrlabs.com/series/belajar-php-oop) untuk mempelajari lebih lanjut konsep-konsep penting lainnya.

Sampai jumpa di edisi berikutnya, dan seperti biasa: **Selamat belajar dan happy coding!** 🎉