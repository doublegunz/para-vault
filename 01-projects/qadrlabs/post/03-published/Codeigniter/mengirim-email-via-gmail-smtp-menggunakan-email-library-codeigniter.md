---
title: "Mengirim Email via Gmail SMTP menggunakan Email Library CodeIgniter"
slug: "mengirim-email-via-gmail-smtp-menggunakan-email-library-codeigniter"
category: "Codeigniter"
date: "2017-05-27"
status: "published"
---

Pernahkah kamu mendapat email pada saat mendaftar di sebuah website? atau pada saat kamu ingin mengunduh ebook gratis yang ada di sebuah website? atau mungkin email promosi pada saat kamu mengunjungi website e-commerce? Mengirim email memang salah satu fitur yang bermanfaat yang biasa kita jumpai ketika mengunjungi website. Dan untuk memudahkan dalam pembuatan fitur mengirim email ini, CodeIgniter menyediakan email library yang dapat kita gunakan untuk mengirim email dalam aplikasi yang akan kita kembangkan. Nah, di edisi tutorial kali ini, kita akan membahas **cara mengirim email menggunakan Email Library CodeIgniter**.

Mengirim Email menggunakan Email Library CodeIgniter itu mudah dan kita bisa set preference sesuai dengan kebutuhan kita. Selain itu, terdapat beberapa fitur yang disediakan Email library CodeIgniter, yaitu:
1. Multiple Protocols: Mail, Sendmail, and SMTP
2. Multiple recipients
3. CC dan BCC
4. HTML atau Email berupa plaintext
5. Attachment
6. Word wrapping
7. Priority
8. BCC Batch Mode
9. Email Debugging tools

Mengirim email menggunakan library codeigniter ini saya gunakan di salah satu project web yang saya kerjakan untuk membuat fitur verifikasi pendaftaran. Ada kendala ketika uji coba mengirim email di fitur tersebut. Kendalanya itu belum ada mail server yang bisa digunakan. Dan solusi yang saya gunakan adalah menggunakan SMTP GMAIL. Setelah saya coba di server production, solusi ini bisa digunakan.

Nah, di edisi tutorial kali ini, kita akan mencoba salah satu fitur Email Library CodeIgniter, yaitu mengirim email via SMTP GMAIL. Selain untuk mengikat ilmu, tutorial ini dibuat agar saya dan teman-teman bisa sama-sama belajar. Yuk, kita mulai!

## Persiapan{#persiapan}
Ada beberapa hal yang pelu kita siapkan sebelum mencoba tutorial kirim email codeigniter 3:
1. Pertama, pastikan kamu sudah menginstall CodeIgniter di document Root kamu (di folder htdocs, jika menggunakan xampp) dan rename folder CodeIgniter kamu menjadi ci3.
2. Kedua, karena kita akan mengirim email, jadi kita memerlukan koneksi internet. So, pastikan kamu sudah terhubung dengan internet ya.
3. Ketiga, kita perlu siapkan nomer hp untuk proses aktivasi 2 Step Verification untuk akun gmail. Fitur 2 Step Verification ini kita perlukan untuk setup app password gmail.

## Step 1 - Setup App password Gmail{#step-1}
Karena kita akan menggunakan SMTP punya Gmail untuk mengirim email, kita harus membuat beberapa perubahan di pengaturan akun Google kita. Ada beberapa tahapan yang harus kita lakukan, yaitu:
1. Login ke dalam akun Google kita
2. Setelah itu, masuk ke halaman [My Account](https://myaccount.google.com/). Setelah itu pilih menu [Security](https://myaccount.google.com/security). Pada halaman ini terdapat panel `Signing in to Google` yang memiliki dua pilihan yaitu Password dan 2 Step Verification. Di sini kita harus aktifkan 2-Step Verification untuk mendapatkan App Password yang nanti akan kita gunakan untuk mengirim email.
![Menu Security di akun google](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter-3/send-email/image-1.png)

3. klik 2 Step Verification untuk mengaktifkan fitur ini. Lalu ikuti langkah-langkahnya dimulai dari klik Get Started, setelah itu kita akan diminta memasukan password untuk melanjutkan. Pada halaman berikutnya kita akan diminta memasukan nomer telepon hp yang masih aktif. Kita coba masukan nomer hp, setelah itu kita pilih sms atau telepon untuk menerima kode pin dari google, di sini saya coba pilih sms dan langsung dapat sms berisi kode pin. Setelah kita dapat sms berisi kode pin, kita coba konfirmasi bahwa nomer masih aktif dengan memasukan kode PIN yang dikirimkan google melalui sms ataupun telepon.
![masukan kode pin untuk mengaktifkan 2 step verification](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter-3/send-email/image-2.png)

4. Setelah konfirmasi nomer hp berhasil, selanjutnya aktifkan 2 Step Verification dengan klik link AKTIFKAN. 
![Aktifkan 2 Step Verification](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter-3/send-email/image-3.png)

5. Sekarang kita kembali lagi ke halaman pengaturan [Security](https://myaccount.google.com/security). Sekarang kita bisa lihat ada opsi baru di bagian `Signing in to Google`, yaitu `App password`.
![Menu App Password](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter-3/send-email/image-4.png)

6. Apabila menunya tidak ada, kita bisa akses [https://myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords) untuk masuk ke halaman App Passwords. Selanjutnya kita akan diminta untuk memasukan password gmail untuk melanjutkan ke halaman App passwords. Karena kita baru buat, kita bisa lihat di halaman App password kita masih kosong.
![halaman App password google](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter-3/send-email/image-5.png)

7. Sekarang kita coba generate password baru untuk project kirim email codeigniter 3. Di bagian Select app, kita pilih Other (custome name), lalu kita coba isi dengan value `Tutorial Kirim Email qadrLabs`. Setelah itu klik tombol `Generate` untuk memulai proses generate password yang baru. 
![Atur app password](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter-3/send-email/image-6.png)

![Generate Password](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter-3/send-email/image-7.png)

8. Setelah itu kita bisa lihat ada password hasil generate.

```
Your app password for your device
xxxjxxkxxlnxxnn
```

Passwordnya kita catat dulu karena kalau di close nanti password hasil generatenya di-hidden.

Nah, password yang bisa kita gunakan untuk projek kirim email sudah kita dapatkan, sekarang kita sudah bisa pakai Gmail SMTP untuk mengirim email dari aplikasi CodeIgniter kita.

## Step 2 - Membuat Controller (Email.php){#step-2}
Kita akan membuat sebuah controller dengan nama class ```Email``` dengan method untuk mengirim email, yaitu ```send()```. Sekarang buka teks editor kesayanganmu, lalu ketik kode di bawah ini ya:
```php
<?php 
defined('BASEPATH') or exit('No direct script access allowed');

class Email extends CI_Controller
{
    public function send()
    {
    	// set konfigurasi email library
        $config = array(
            'protocol' => 'smtp',
            'smtp_host' => 'ssl://smtp.googlemail.com',
            'smtp_port' => 465,
            'smtp_user' => 'email_kamu@gmail.com',
            'smtp_pass' => 'app_password_hasil_generate',
            'mailtype' => 'html',
            'charset' => 'iso-8859-1'
        );

        // load library email
        $this->load->library('email', $config);

        // set email yang akan dikirim
        $this->email->set_newline("\r\n");
        $this->email->from('adminnyaqadrlabs@gmail.com', 'Adminnya qadrLabs');
        $this->email->to('emailtujuanmu@gmail.com');
        $this->email->subject('Percobaan email');
        $this->email->message('Halo Kak! Ini adalah email percobaan untuk Tutorial CodeIgniter: Mengirim Email via Gmail SMTP menggunakan Email Library CodeIgniter @ qadrlabs.com');

        // proses kirim email
        if (!$this->email->send()) {
        	// tampilkan error, ketika gagal kirim email
            show_error($this->email->print_debugger());
        } else {
        	// tampilkan keterangan sukses kirim email
            echo 'Success to send email';
        }
    }
}
```

Kalau sudah, jangan lupa save file dengan nama ```Email.php``` di directori ```ci3/application/controllers```.

Pada method `send()`, kita bisa lihat di baris kode untuk konfigurasi. Pada bagian ini kita isi smtp user dengan akun email kita dan smtp password kita isi dengan password hasil generate yang sebelumnya kita dapat di step 1. 

Pada bagian selanjutnya, di bagian set email, kita isi dengan email from, email tujuan, subjek dan isi email. Lalu selanjutnya kita kirim email menggunakan method `send()` dari library email codeigniter 3. Ketika proses kirim email berhasil, output di browser akan menampilkan keterangan berhasil kirim email. Dan sebaliknya apabila gagal, di browser akan menampilkan keterangan error dari debugger library email.

## Step 3 - Uji Coba Kirim Email{#step-3}
Sekarang kita coba run project kita. Untuk run project, kita bisa langsung buka browser, lalu akses url ```http://localhost/ci3/index.php/email/send```. Kalau berhasil kirim email, akan tampil pemberitahuan `Success to send email`. Untuk verifikasi apakah email terkirim atau tidak, kita bisa cek inbox email yang kita jadikan tujuan atau kita set di baris kode ` $this->email->to('emailtujuanmu@gmail.com');`. Karena email yang saya gunakan sebagai alamat tujuan adalah email saya sendiri, ketika saya cek ternyata email berhasil terkirim dan sudah masuk ke inbox gmail! :D

![hasil uji coba kirim email](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter-3/send-email/tes-kirim-email.png)

***

Gimana mudah bukan? Mengirim email memang salah satu fitur yang bermanfaat dalam aplikasi web yang kita kembangkan. Dan Email Library CodeIgniter dapat kita manfaatkan untuk membuat fitur mengirim email. Selain fitur email library yang sudah kita coba, terdapat fitur lain yang bisa kamu eksplore dan kembangkan untuk aplikasimu lho!

Oh iya, kamu juga bisa coba mengembangkan aplikasi di edisi tutorial Membuat Fitur Forgot Password Pada CodeIgniter  untuk mengirim email berisi link untuk reset password.

Selamat mencoba. semoga belajarnya menyenangkan! Happy Coding! ^^

***

### Referensi:
- Web Official CodeIgniter @ [https://codeigniter.com](https://codeigniter.com)
- Email Library CodeIgniter @ [https://www.codeigniter.com/user_guide/libraries/email.html](https://www.codeigniter.com/user_guide/libraries/email.html)

### FAQ
Ada beberapa pertanyaan yang sering ditanyakan mengenai tutorial ini:

- Q: Apakah cara mengirim email ini sudah digunakan dalam project sebenarnya?
- A: Ya, cara mengirim email ini sudah saya gunakan di beberapa project web saya (sebagai solusi alternatif karena belum ada mail server). Dan kebetulan server yang digunakan itu dedicated server, bukan shared hosting.

- Q: kalau dilocal berhasil, tapi klo udah dihosting gagal, apa ga berlaku kalau dihosting ya?
- A: Dulu sempat coba testing di shared hosting, ada yang berhasil dan ada juga yang enggak. Kemungkinan portnya ditutup, IPnya diblockir atau malah difilter sama firewall. Sebagai alternatif kirim email bisa pakai layanan smtp seperti mailgun, sendgrid, dll atau bisa juga pakai smtp penyedia hostingan.

- Q: ada error seperti ini ```php Message: fsockopen(): SSL operation failed with code 1. OpenSSL Error messages: error:14090086:SSL routines:ssl3_get_server_certificate:certificate verify failed ```
- A: Sebelum migrasi ke linux, sempat coba di windows dan ada error seperti itu. setelah ditelusuri, penyebabnya itu karena diblok sama antivirus. Jadi solusinya itu masukan whitelist localhost di settingan antivirusnya. atau bisa juga disable antivirusnya (ini kurang saya rekomendasikan. referensi tentang error ini bisa baca  [di sini](https://stackoverflow.com/questions/34570064/gmail-fsockopen-ssl-operation-failed-error-with-codeigniter-and-xampp)