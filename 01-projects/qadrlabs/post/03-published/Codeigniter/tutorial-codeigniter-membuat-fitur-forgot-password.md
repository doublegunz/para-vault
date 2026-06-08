---
title: "Tutorial Codeigniter 3: Membuat Fitur Forgot Password"
slug: "tutorial-codeigniter-membuat-fitur-forgot-password"
category: "Codeigniter"
date: "2016-12-18"
status: "published"
---

Hallo, [CodeIgniter Tutorial](https://qadrlabs.com/series/belajar-codeigniter-3) is back! Dan edisi tutorial kali ini ditulis berdasarkan request dari pembaca. Pekan lalu, saya menerima beberapa email yang berisi request untuk membuat tutorial tentang membuat fitur forgot password atau reset password pada CodeIgniter. *And FYI*, edisi kali ini merupakan lanjutan seri tutorial CodeIgniter edisi Membuat Simple Login dan Register Menggunakan CodeIgniter. So, pastikan kamu sudah membaca edisi tersebut sebelum mencoba tutorial ini yaa..

### Daftar Isi
1.  [Overview](#overview)
2. [Step 1 - Persiapan](#step-1)
3. [Step 2 - Membuat table tokens](#step-2)
4. [Step 3 - Modifikasi Model](#step-3)
5. [Step 4 - Membuat View Baru](#step-4)
6. [Step 5 - Membuat File Controller](#step-5)
7. [Step 6 - Uji Coba Project](#step-6)
8. [Penutup](#penutup)

## Overview {#overview}
Pada tutorial kali ini kita akan menambahkan fitur reset password atau forgot pasword di aplikasi web yang sebelumnya sudah kita buat di tutorial [login dan register codeigniter](https://qadrlabs.com/post/membuat-simple-login-dan-register-menggunakan-codeigniter#step-1-persiapan-development). Karena edisi kali ini lanjutan dari edisi tutorial sebelumnya, sudah pasti fitur forgot password atau reset password ini termasuk fitur yang mesti ada dalam sistem autentifikasi atau sistem registrasi dan login. Biasanya dalam sistem autentifikasi ada kebutuhan supaya user bisa menggunakan aplikasi kembali, apabila mereka lupa password mereka. Kita sendiri juga kadang lupa password yang digunakan bukan?

Nah, untuk itu kita perlu fitur forgot password dan inilah alur yang akan kita gunakan pada fitur forgot password ini:
1. User meng-klik link forgot password di halaman login
2. User dialihkan ke halaman forgot password
3. User mengisi email untuk permintaan reset password
4. Sistem akan mengirim link dengan token unik ke email user.
5. User mendapatkan email yang berisi link dengan token unik.
6. User Mengklik link, lalu dialihkan ke halaman reset password.
7. User mengisi password baru.
8. Sistem memperbaharui password user, lalu mengalihkan user ke halaman login.

So, kita akan membutuhkan form untuk melayani permintaan untuk reset password, mekanisme untuk pemberitahuan dengan unique token, lalu, form lain yang digunakan untuk mereset password.

Sudah kebayang 'kan alurnya? Yuk kita mulai!

## Step 1 - Persiapan {#step-1}
Ya, karena edisi kali ini lanjutan seri tutorial CodeIgniter edisi Membuat Simple Login dan Register Menggunakan CodeIgniter, so, kita akan memakai project yang sudah kita buat di edisi tersebut, lalu menambahkan fitur forgot password.

## Step 2 - Membuat Tabel ```tokens``` {#step-2}
Pada tahapan ini kita akan membuat table baru, yaitu table `tokens`. Tabel ini digunakan untuk menyimpan token yang dikirim ke email. Kita akan menambahkan tabel ```tokens``` ke dalam database `dbci3` (database yang kita buat di edisi tutorial sebelumnya).

Untuk membuat tabel `tokens`, kita run command SQL di bawah ini:
```sql
CREATE TABLE IF NOT EXISTS `tokens` (  
    `id` int(11) NOT NULL AUTO_INCREMENT,  
    `token` varchar(255) NOT NULL,  
    `user_id` int(10) NOT NULL,  
    `created` date NOT NULL,  
    PRIMARY KEY (`id`)  
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=0 ;  
```

![Buat tabel tokens - Tutorial Codeigniter: Membuat Fitur Forgot Password](https://2.bp.blogspot.com/-WMqlTynX-sQ/WFYJxc81NiI/AAAAAAAAAqQ/UK4YN1Y7iAY7MWVhJzbTG1WAO4kJSFkkQCEw/w640-h232/reset-password-codeigniter-gambar%2B1.png)

## Step 3 - Memodifikasi Model (M_account.php) {#step-3}
Ada beberapa method yang mesti kita tambahkan dalam class `M_account` di antaranya:

- `getUserInfo()`  →  Method ini digunakan untuk mengambil data user dari tabel `users` berdasarkan id user.
- `getUserInfoByEmail()` → Digunakan untuk mengambil data user dari tabel 'users' berdasarkan email user.
- `insertToken()`  → insert token ke dalam tabel `tokens` untuk kebutuhan reset password.
- `isTokenValid()`  → validasi token, apakah token ada pada tabel `token`? Apakah token masih bisa digunakan atau sudah kadaluarsa.
- `updatePassword()`  → Sudah pasti digunakan untuk memperbaharui password user.


Sekarang buka file model `M_account.php` yang ada di direktori `ci3/application/models` dengan text editor kesayanganmu.

![Buka file model - Tutorial Codeigniter: Membuat Fitur Forgot Password](https://2.bp.blogspot.com/-NavVf1ZyNno/WFYJyjguh5I/AAAAAAAAAq8/NEtDOlkNzrgu5yT61kO8b7obIUVcv_rqQCEw/w349-h400/reset-password-codeigniter-gambar%2B2.png)

Kalau sudah dibuka filenya, kita bisa lihat class `M_account`. Sekarang kita tambahkan beberapa method ke dalam class `M_account`. Yuk kita ketik code ini di dalam class `M_account`:
```php

<?php
defined('BASEPATH') or exit('No direct script access allowed');
class M_Account extends CI_Model
{

    function daftar($data)
    {
        $this->db->insert('users', $data);
    }

    //Start: method tambahan untuk reset code  
    public function getUserInfo($id)
    {
        $q = $this->db->get_where('users', array('id_user' => $id), 1);
        if ($this->db->affected_rows() > 0) {
            $row = $q->row();
            return $row;
        } else {
            error_log('no user found getUserInfo(' . $id . ')');
            return false;
        }
    }

    public function getUserInfoByEmail($email)
    {
        $q = $this->db->get_where('users', array('email' => $email), 1);
        if ($this->db->affected_rows() > 0) {
            $row = $q->row();
            return $row;
        }
    }

    public function insertToken($user_id)
    {
        $token = substr(sha1(rand()), 0, 30);
        $date = date('Y-m-d');

        $string = array(
            'token' => $token,
            'user_id' => $user_id,
            'created' => $date
        );
        $query = $this->db->insert_string('tokens', $string);
        $this->db->query($query);
        return $token . $user_id;
    }

    public function isTokenValid($token)
    {
        $tkn = substr($token, 0, 30);
        $uid = substr($token, 30);

        $q = $this->db->get_where('tokens', array(
            'tokens.token' => $tkn,
            'tokens.user_id' => $uid
        ), 1);

        if ($this->db->affected_rows() > 0) {
            $row = $q->row();

            $created = $row->created;
            $createdTS = strtotime($created);
            $today = date('Y-m-d');
            $todayTS = strtotime($today);

            if ($createdTS != $todayTS) {
                return false;
            }

            $user_info = $this->getUserInfo($row->user_id);
            return $user_info;
        } else {
            return false;
        }
    }

    public function updatePassword($post)
    {
        $this->db->where('id_user', $post['id_user']);
        $this->db->update('users', array('password' => $post['password']));
        return true;
    }
    //End: method tambahan untuk reset code  
}
```

Kalau sudah, jangan lupa save kembali file `M_account.php` dengan menekan tombol ctrl+s.

Ok, next step...

## Step 4 - Membuat View Baru {#step-4}
Biasanya fitur forgot password itu sering kita temukan di halaman login berupa link menuju ke halaman forgot password. Jadi sebelum membuat kedua file `v_lupa_password.php` dan `v_reset_password.php`, kita edit file `v_login.php` terlebih dahulu untuk menambahkan link untuk request forgot password.

Sekarang buka text editor kesayanganmu, lalu buka file `v_login.php` yang ada di direktori `ci3/application/views/account`.

Di file `v_login.php`, kita bisa lihat ada baris code ini:
```php
<p>  
  Kembali ke beranda, Silakan klik <?php echo anchor(site_url().'/beranda','di sini..'); ?>  
</p>  
```

Sekarang kita modifikasi baris code di atas dan kita tambahkan link menuju halaman forgot password.
```html
 <p>
    <?php echo anchor(site_url() . '/beranda', 'Kembali');
    echo ' | ';
    echo anchor(site_url() . '/register', 'Daftar');
    echo ' | ';
    echo anchor(site_url() . '/lupa_password', 'Lupa Password');
    ?>
</p> 
```

Setelah kita tambahkan link menuju halaman untuk fitur forgot password, keseluruhan isi `file v_login.php` jadi seperti baris kode berikut ini:

```html
  <!DOCTYPE html>
 <html>

 <head>
     <meta charset="UTF-8">
     <title>
         Halaman Login | Tutorial Reset Password CodeIgniter @ http://recodeku.blogspot.com
     </title>
 </head>

 <body>
     <h2>Halaman Login</h2>
     <?php
        // Cetak session   
        if ($this->session->flashdata('sukses')) {
            echo '<p class="warning" style="margin: 10px 20px;">' . $this->session->flashdata('sukses') . '</p>';
        }
        ?>
     <?php echo form_open('login'); ?>
     <p>Username:</p>
     <p>
         <input type="text" name="username" value="<?php echo set_value('username'); ?>" />
     </p>
     <p> <?php echo form_error('username'); ?> </p>
     <p>Password:</p>
     <p>
         <input type="password" name="password" value="<?php echo set_value('password'); ?>" />
     </p>
     <p> <?php echo form_error('password'); ?> </p>
     <p>
         <input type="submit" name="btnSubmit" value="Login" />
     </p>
     <p>
         <?php echo anchor(site_url() . '/beranda', 'Kembali');
            echo ' | ';
            echo anchor(site_url() . '/register', 'Daftar');
            echo ' | ';
            echo anchor(site_url() . '/lupa_password', 'Lupa Password');
            ?>
     </p>
 </body>

 </html>
```

Kalau sudah selesai, tekan ctrl+s untuk menyimpan kembali file `v_login.php`.

Langkah selanjutnya adalah membuat file baru. Pertama kita buat file `v_lupa_password.php`. Buka kembali text editor kesayanganmu, lalu ketik kode ini yaa...

```html
 <!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <title>
        <?= $title; ?>
    </title>
</head>

<body>
    <h2>Lupa Password</h2>
    <p>Untuk melakukan reset password, silakan masukkan alamat email anda. </p>
    <?php echo form_open('lupa_password'); ?>
    <p>Email:</p>
    <p>
        <input type="text" name="email" value="<?php echo set_value('email'); ?>" />
    </p>
    <p> <?php echo form_error('email'); ?> </p>
    <p>
        <input type="submit" name="btnSubmit" value="Submit" />
    </p>
</body>

</html>  
```

Ya, simpan dengan nama `v_lupa_password.php` di direktori `ci3/application/views/account`.

Selanjutnya kita buat file `v_reset_password.php`. Yuk ketik lagi kode berikut ini...

```html
 <!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <title>
        <?= $title; ?>
    </title>
</head>

<body>
    <h2>Reset Password</h2>
    <h5>Hello <span><?php echo $nama; ?></span>, Silakan isi password baru anda.</h5>
    <?php echo form_open('lupa_password/reset_password/token/' . $token); ?>
    <p>Password Baru:</p>
    <p>
        <input type="password" name="password" value="<?php echo set_value('password'); ?>" />
    </p>
    <p> <?php echo form_error('password'); ?> </p>
    <p>Konfirmasi Password:</p>
    <p>
        <input type="password" name="passconf" value="<?php echo set_value('passconf'); ?>" />
    </p>
    <p> <?php echo form_error('passconf'); ?> </p>
    <p>
        <input type="submit" name="btnSubmit" value="Reset" />
    </p>
</body>

</html> 
```


Yep, setelah selesai, kita simpan dengan nama `file v_reset_password.php` di direktori yang sama (`ci3/application/views/account`).

Sekarang kita punya dua file baru, yaitu file `v_lupa_password.php` dan `v_reset_password.php` di direktori `ci3/application/views/account`.

![File view baru - Tutorial Codeigniter: Membuat Fitur Forgot Password](https://3.bp.blogspot.com/-wSfSGd6La2w/WFYJ00EayqI/AAAAAAAAAq8/PGQX_1DsSiA9QxyAP_hLSCaIl1g8a-Z0gCEw/w640-h340/reset-password-codeigniter-gambar%2B5.png)

## Step 5 - Membuat File Controller (`Lupa_password.php`) {#step-5}
Selanjutnya kita buat file controller dengan nama `Lupa_password.php`. Di dalam controller ini, terdapat empat method di antaranya:

- `index()` :: Untuk menampilkan form permintaan reset password, melayani permintaan reset password dan mengirim email berisi url dengan token yang digunakan untuk reset password.
- `reset_password()` :: Untuk menampilkan halaman reset password berdasarkan link yang dikirim melalui email, memvalidasi token dan memperbaharui password.
- `base64url_encode()` :: Untuk mengenkripsi token yang dikirim ke email user.
- `base64url_decode()` :: Untuk mendekripsi url yang berisi token dari link reset password.

Sekarang buka kembali text editor kesayanganmu, lalu ketik kode di bawah ini yaa!

```php
<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Lupa_password extends CI_Controller
{
    public function index()
    {

        $this->form_validation->set_rules('email', 'Email', 'required|valid_email');

        if ($this->form_validation->run() == FALSE) {
            $data['title'] = 'Halaman Reset Password | Tutorial reset password CodeIgniter @ https://recodeku.blogspot.com';
            $this->load->view('account/v_lupa_password', $data);
        } else {
            $email = $this->input->post('email');
            $clean = $this->security->xss_clean($email);
            $userInfo = $this->m_account->getUserInfoByEmail($clean);

            if (!$userInfo) {
                $this->session->set_flashdata('sukses', 'email address salah, silakan coba lagi.');
                redirect(site_url('login'), 'refresh');
            }

            //build token   

            $token = $this->m_account->insertToken($userInfo->id_user);
            $qstring = $this->base64url_encode($token);
            $url = site_url() . '/lupa_password/reset_password/token/' . $qstring;
            $link = '<a href="' . $url . '">' . $url . '</a>';

            $message = '';
            $message .= '<strong>Hai, anda menerima email ini karena ada permintaan untuk memperbaharui  
                 password anda.</strong><br>';
            $message .= '<strong>Silakan klik link ini:</strong> ' . $link;

            echo $message; //send this through mail  
            exit;
        }
    }

    public function reset_password()
    {
        $token = $this->base64url_decode($this->uri->segment(4));
        $cleanToken = $this->security->xss_clean($token);

        $user_info = $this->m_account->isTokenValid($cleanToken); //either false or array();          

        if (!$user_info) {
            $this->session->set_flashdata('sukses', 'Token tidak valid atau kadaluarsa');
            redirect(site_url('login'), 'refresh');
        }

        $data = array(
            'title' => 'Halaman Reset Password | Tutorial reset password CodeIgniter @ https://recodeku.blogspot.com',
            'nama' => $user_info->nama,
            'email' => $user_info->email,
            'token' => $this->base64url_encode($token)
        );

        $this->form_validation->set_rules('password', 'Password', 'required|min_length[5]');
        $this->form_validation->set_rules('passconf', 'Password Confirmation', 'required|matches[password]');

        if ($this->form_validation->run() == FALSE) {
            $this->load->view('account/v_reset_password', $data);
        } else {

            $post = $this->input->post(NULL, TRUE);
            $cleanPost = $this->security->xss_clean($post);
            $hashed = md5($cleanPost['password']);
            $cleanPost['password'] = $hashed;
            $cleanPost['id_user'] = $user_info->id_user;
            unset($cleanPost['passconf']);
            if (!$this->m_account->updatePassword($cleanPost)) {
                $this->session->set_flashdata('sukses', 'Update password gagal.');
            } else {
                $this->session->set_flashdata('sukses', 'Password anda sudah  
             diperbaharui. Silakan login.');
            }
            redirect(site_url('login'), 'refresh');
        }
    }

    public function base64url_encode($data)
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    public function base64url_decode($data)
    {
        return base64_decode(str_pad(strtr($data, '-_', '+/'), strlen($data) % 4, '=', STR_PAD_RIGHT));
    }
}
```


Kalau sudah selesai, simpan file controller dengan nama `Lupa_password.php` di direktori `ci3/application/controllers`.

![File controller baru - Tutorial Codeigniter: Membuat Fitur Forgot Password](https://4.bp.blogspot.com/-pUbJH03kN6Y/WFYJ2phtN3I/AAAAAAAAAq8/tcwjgzHcQqE2pZWrwcHZ6AX4CakV7gYswCEw/w640-h336/reset-password-codeigniter-gambar%2B6.png)

## Step 6 - Uji Coba Project {#step-6}
Yuk, sekarang kita coba run project kita! Buka browser lalu buka alamat `http://localhost/ci3/index.php/login`.

![Uji coba - Tutorial Codeigniter: Membuat Fitur Forgot Password](https://3.bp.blogspot.com/-CBD3ma5FA54/WFYJ00ivlGI/AAAAAAAAAq8/piNVjVhPdHgNu0lcou5_aJURN5RdpjWPwCEw/w640-h384/reset-password-codeigniter-gambar%2B7.png)

Ya, tampil halaman untuk login. Sekarang kita coba klik link 'Lupa Password'. Lalu kamu coba masukkan email untuk mencoba fitur forgot password.
![Uji coba - Tutorial Codeigniter: Membuat Fitur Forgot Password](https://3.bp.blogspot.com/-9-dHeOqr9OM/WFYJ2nEQo6I/AAAAAAAAAq8/iy3xZcDDk-IVW4DH0oo69dVFs9Y7LSW0gCEw/w640-h286/reset-password-codeigniter-gambar%2B8.png)

Setelah kita klik tombol 'Submit', kita akan melanjutkan ke halaman yang berisi link untuk melakukan reset code. Di dalam code yang kita buat, kita hanya meng-generate token lalu membuat link dan kemudian kita 'echo' di browser. Perlu kita ingat, link inilah yang nantinya kita kirim ke email user, tapi untuk alasan demo project kita hanya perlu menampilkannya di browser. Link tersebut tampak seperti pada gambar ini:

![Uji coba - Tutorial Codeigniter: Membuat Fitur Forgot Password](https://2.bp.blogspot.com/-G3guR-QKukQ/WFYJ3DrxCTI/AAAAAAAAAq8/p8DGP1YxoIQhwlR9sD4cW7nXaHflXu1QgCEw/w640-h120/reset-password-codeigniter-gambar%2B9.png)

Di dalam link tersebut berisi token yang unik. Saat kita klik link, kita akan masuk ke halaman reset password. Nah, dalam prosesnya, sistem akan memastikan kalau token itu valid dengan menggunakan method `isTokenValid()` dan apabila token tersebut valid, sistem akan me-render halaman `v_reset_password.php`.

Sekarang kita coba klik link dengan token, akan tampil halaman reset password seperti gambar di bawah:
![Uji coba - Tutorial Codeigniter: Membuat Fitur Forgot Password](https://4.bp.blogspot.com/-k2sGXDwc8SE/WFYJwSfqgSI/AAAAAAAAAq8/r6cPLbV55T055QwehD7kek2LBR03KOfUwCEw/w640-h250/reset-password-codeigniter-gambar%2B10.png)

Selanjutnya coba isi password baru sesuka hati, lalu klik tombol reset. Kalau berhasil, kita akan dialihkan ke halaman login. Bisa kita lihat ada notifikasi kalau password kita sudah diperbaharui.

![Uji coba - Tutorial Codeigniter: Membuat Fitur Forgot Password](https://3.bp.blogspot.com/-14PQ76dQFbU/WFYJyOlB3xI/AAAAAAAAAq8/x2fck4atrOYTLaMiDkbefTNYlJ2Nv6ijQCEw/w640-h398/reset-password-codeigniter-gambar%2B11.png)

Nah, sekarang kita bisa login menggunakan password yang baru.

## Penutup {#penutup}
Dalam sistem login dan registrasi atau yang kita ketahui sebagai sistem autentifikasi, terdapat fitur forgot password atau reset password. Fitur ini dibuat karena ada kebutuhan apabila user kita lupa password akun mereka. Di edisi tutorial kali ini kita sudah membahas tentang alur dan pemahaman dasar fitur forgot password. Dan perlu diingat, code dalam tutorial ini tidak ditujukan untuk production code. Ada banyak yang perlu dikembangkan, tapi setidaknya tutorial ini cukup untuk memahami dasarnya.

Semoga bermanfaat. Tetap semangat berkarya ya! Happy coding!