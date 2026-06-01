---
title: "Membangun Aplikasi Payment Sederhana menggunakan PHP dan Midtrans"
slug: "membangun-aplikasi-payment-sederhana-menggunakan-php-dan-midtrans"
category: "php"
date: "2021-11-28"
status: "published"
---

Melihat judul postingan ini, boleh jadi teman-teman sudah bisa membaca apa isi dari postingan kali ini. Ya, percobaan saya kali ini adalah integrasi midtrans di aplikasi yang dibangun menggunakan PHP.  [Midtrans](https://midtrans.com/) ini saya gunakan sebagai payment gateway untuk menangani proses pembayaran. Karena tujuan awalnya itu untuk mempelajari cara kerja integrasi midtrans, jadi aplikasi yang saya jadikan studi kasus itu sederhana. Selain itu, di sini saya hanya menggunakan PHP native dan belum menggunakan framework apapun. Untuk integrasi midtrans dengan framework bisa kita bahas di lain waktu.

Studi kasus postingan kali ini cukup sederhana. Hanya ada tampilan daftar item yang dibeli dan tombol checkout, lalu ada proses pembayaran, lalu menerima notifikasi dari midtrans dan selesai. Ya, sesuai dengan judulnya aplikasi payment sederhana menggunakan PHP dan midtrans.

Ada beberapa tahapan untuk membangun aplikasi payment sederhana menggunakan PHP dan midtrans:

- Step 1. Persiapan
- Step 2. Create Halaman Checkout
- Step 3. Create Checkut Process
- Step 4. Create Notification Handler
- Step 5. Uji Coba

Teman-teman ingin coba juga? Yuk, kita mulai.

## Step 1: Persiapan{#persiapan}
Sebelum mengikuti tutorial ini, ada beberapa hal yang harus kita persiapkan:

### Cek Versi PHP

Pada saat tutorial ini diperbaharui, saya menggunakan PHP versi 8.2. Saya coba run command berikut ini untuk cek versi php.

```
php -v
```

Output:

```
PHP 8.2.20 (cli) (built: Jun  8 2024 21:38:01) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.2.20, Copyright (c) Zend Technologies
    with Zend OPcache v8.2.20, Copyright (c), by Zend Technologies

```



### Download dan Setup NGROK

Untuk keperluan uji coba menggunakan midtrans, aplikasi kita itu harus terhubung ke internet. Kabar baiknya kita bisa menggunakan [NGROK](https://ngrok.com) untuk mengatasi problem tersebut. Teman-teman bisa coba mendaftar dulu untuk masuk ke dashboard NGROK. 

Selanjutnya kita install terlebih dahulu ngrok. Kita bisa masuk ke halaman [Setup & Installation untuk os linux](https://dashboard.ngrok.com/get-started/setup/linux) dan kita bisa lihat ada petunjuk setup.

Untuk install ngrok, kita buka terminal lalu run `command` di bawah ini.

```bash
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
	| sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
	&& echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
	| sudo tee /etc/apt/sources.list.d/ngrok.list \
	&& sudo apt update \
	&& sudo apt install ngrok
```



**Catatan:** 

untuk Os Windows bisa coba akses halaman [Setup & Installation untuk os windows](https://dashboard.ngrok.com/get-started/setup/windows), lalu pilih Menu [Download](https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip) untuk download ngrok, kemudian unzip file hasil download.



Sekarang kita masuk ke halaman [Your Authtoken](https://dashboard.ngrok.com/get-started/your-authtoken) untuk mendapatkan authtoken. Setelah itu kita run `ngrok`, lalu kita hubungkan ke akun kita menggunakan authtoken.

```bash
ngrok config add-authtoken AUTHTOKEN_KAMU
```

Output:

```
Authtoken saved to configuration file: /home/namauser/.config/ngrok/ngrok.yml
```



Sampai tahapan ini pengaturan `ngrok` sudah selesai, nanti kita coba gunakan untuk keperluan uji coba aplikasi.



### Mendapatkan Midtrans API Access Key

Teman-teman harus punya API access key midtrans terlebih dahulu. Untuk mendapatkan key tersebut, teman-teman daftar terlebih dahulu dan selesaikan pendaftaran. Setelah itu masuk ke halaman dashboard dengan environtment `sandbox` (bisa lihat di sidebar ada opsi untuk mengubah environment). Di dalam halaman dashboard, masuk ke menu Settings (atau Pengaturan) lalu pilih sub menu [Access Key](https://dashboard.sandbox.midtrans.com/settings/config_info).

Di halaman Access Key, terdapat Merchant ID, Client Key dan Server Key. Nanti kita akan pakai ketiganya, untuk client key nanti kita gunakan untuk authorization di front end, sedangkan Server Key untuk authorization di bagian backend.

**Keterangan:** Ada baiknya key ini tidak dibagikan kesiapapun, terutama **Server Key**.

### Setup Codelab

Codelab ini kita gunakan untuk project payment sederhana menggunakan PHP dan midtrans. Sekarang kita akan buat folder khusus project kita. Buka terminal lalu buat folder baru.

```bash
mkdir payment-php-midtrans
```

lalu masuk folder yang baru saja kita buat.

```bash
cd payment-php-midtrans
```

Selanjutnya kita install package yang meng-handle integrasi dengan midtrans.

```bash
composer require midtrans/midtrans-php
```

Untuk menggunakan api key yang sudah kita dapatkan di tahapan sebelumnya, kita akan menggunakan file `.env` untuk menyimpan key. Jadi kita coba install terlebih dahulu package untuk membaca variable dari `.env`.

```bash
composer require vlucas/phpdotenv
```

Setelah package selesai terinstall, buat file baru dengan nama `.env`. Lalu kita masukan merchant id dan juga kedua api key midtrans.

```php
MIDTRANS_MERCHANT_ID=isi-dengan-merchant-id
MIDTRANS_CLIENT_KEY=SB-Mid-client-isi-dengan-key-nya
MIDTRANS_SERVER_KEY=SB-Mid-server-isi-dengan-key-nya
```

**Keterangan:** Api Key yang kita pakai untuk environment sandbox ya.. bukan untuk production.

Ini tahapan opsional, jaga-jaga kalau aplikasinya diupload ke github. Buat file baru dengan nama `.gitignore`, lalu kita ketik beberapa file yang akan kita ignore apabila menggunakan `git`.

```php
.env
log/*
vendor
```

Oke, codelab untuk aplikasi payment sederhana sudah selesai.

## Step-2: Create Halaman Checkout{#create-halaman-checkout}

Halaman ini akan menampilkan halaman untuk checkout ketika kita belanja di online store atau pun market place. Untuk membuat halaman checkout, buat file baru dengan nama `index.php`, lalu kita ketik baris kode berikut ini.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Integrasi midtrans di aplikasi payment sederhana - qadrlabs.com</title>
</head>
<body>
  <?php $base = $_SERVER['REQUEST_URI']; ?>

  <h3>Cart:</h3>
  <ul>
      <li>Ebook Belajar PHP OOP at qadrLabs x @100000</li>
      <li>Ebook Belajar Laravel 8 at qadrLabs x @180000</li>
  </ul>

  <h4>Total: Rp 280.000,00</h4>

  <form action="<?php echo $base ?>checkout-process.php" method="POST">
      <input type="hidden" name="amount" value="280000"/>
      <button type="submit">Checkout</button>
  </form>

</body>
</html>
```

Seperti yang terlihat pada baris kode di atas, halaman ini menampilkan daftar barang yang dibeli dan juga terdapat form untuk melakukan aksi checkout. Pada form tersebut, terdapat input yang disembunyikan yang berisi value total yang akan dibayarkan melalui payment gateway. Selain itu untuk prosesnya akan ditangani oleh file `checkout-process.php` yang akan kita buat di tahapan selanjutnya.


## Step-3: Create Checkout Process{#create-checkout-process}

Langkah selanjutnya adalah membuat file untuk menangani proses input dari halaman checkout. Buat file baru dengan nama `checkout-process.php`. Lalu kita ketik baris kode berikut ini.

```php
<?php

require_once 'vendor/autoload.php';

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

//Set Your server key
Midtrans\Config::$serverKey = $_ENV['MIDTRANS_SERVER_KEY'];
$clientKey = $_ENV['MIDTRANS_CLIENT_KEY'];

// Uncomment for production environment
// Midtrans\Config::$isProduction = true;

// Enable sanitization
Midtrans\Config::$isSanitized = true;

// Enable 3D-Secure
Midtrans\Config::$is3ds = true;

// Uncomment for append and override notification URL
// Midtrans\Config::$appendNotifUrl = "https://example.com";
// Midtrans\Config::$overrideNotifUrl = "https://example.com";

// Required
$transaction_details = array(
    'order_id' => rand(),
    'gross_amount' => 94000, // no decimal allowed for creditcard
);

// Optional
$item1_details = array(
    'id' => 'a1',
    'price' => 100000,
    'quantity' => 1,
    'name' => "Ebook Belajar PHP OOP at qadrLabs"
);

// Optional
$item2_details = array(
    'id' => 'a2',
    'price' => 180000,
    'quantity' => 1,
    'name' => "Ebook Belajar Laravel 8 at qadrLabs"
);

// Optional
$item_details = array($item1_details, $item2_details);

// Optional
$billing_address = array(
    'first_name'    => "Nadia",
    'last_name'     => "Rizky",
    'address'       => "Mangga 20",
    'city'          => "Sukabumi",
    'postal_code'   => "143115",
    'phone'         => "081122334455",
    'country_code'  => 'IDN'
);

// Optional
$shipping_address = array(
    'first_name'    => "Nadia",
    'last_name'     => "Rizky",
    'address'       => "Mangga 20",
    'city'          => "Sukabumi",
    'postal_code'   => "143115",
    'phone'         => "08113366345",
    'country_code'  => 'IDN'
);

// Optional
$customer_details = array(
    'first_name'    => "Nadia",
    'last_name'     => "Rizky",
    'email'         => "nadia@gmail.com",
    'phone'         => "081122334455",
    'billing_address'  => $billing_address,
    'shipping_address' => $shipping_address
);

// Optional, remove this to display all available payment methods
$enable_payments = array('credit_card','cimb_clicks','mandiri_clickpay','echannel');

// Fill transaction details
$transaction = array(
    'enabled_payments' => $enable_payments,
    'transaction_details' => $transaction_details,
    'customer_details' => $customer_details,
    'item_details' => $item_details,
);

$snapToken = Midtrans\Snap::getSnapToken($transaction);
echo "snapToken = ".$snapToken;
$base = $_SERVER['REQUEST_URI'];

?>


<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Checkout | Integrasi midtrans di aplikasi payment sederhana - qadrlabs.com</title>
</head>
<body>
<br>
<br>
<button id="pay-button">Pay!</button>
<pre><div id="result-json">JSON result will appear here after payment:<br></div></pre> 

    <!-- TODO: Remove ".sandbox" from script src URL for production environment. Also input your client key in "data-client-key" -->
    <script src="https://app.sandbox.midtrans.com/snap/snap.js" data-client-key="<?php echo $clientKey; ?>"></script>
    <script type="text/javascript">
        document.getElementById('pay-button').onclick = function(){
            // SnapToken acquired from previous step
            snap.pay('<?php echo $snapToken?>', {
                // Optional
                onSuccess: function(result){
                    /* You may add your own js here, this is just example */ 
                    document.getElementById('result-json').innerHTML += JSON.stringify(result, null, 2);
                },
                // Optional
                onPending: function(result){
                    /* You may add your own js here, this is just example */ 
                    document.getElementById('result-json').innerHTML += JSON.stringify(result, null, 2);
                },
                // Optional
                onError: function(result){
                    /* You may add your own js here, this is just example */ 
                    document.getElementById('result-json').innerHTML += JSON.stringify(result, null, 2);
                }
            });
        };
    </script>  
</body>
</html>
```


## Step-4: Create Notification Handler{#create-notification-handler}

Setelah pengguna menyelesaikan proses pendaftaran melalui interface dari midtrans ataupun terdapat perubahan status transaksi, notifikasi via HTTP(S) POST / webhooks akan dikirimkan ke server. Nah untuk menangani notifikasi ini kita buat handler-nya. Kita buat file baru dengan nama `notification-handler.php` dan kita ketik baris kode berikut ini.

```php
<?php

require_once 'vendor/autoload.php';

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

Midtrans\Config::$isProduction = false;
Midtrans\Config::$serverKey = $_ENV['MIDTRANS_SERVER_KEY'];

$notif = new Midtrans\Notification();

$transaction = $notif->transaction_status;
$type = $notif->payment_type;
$order_id = $notif->order_id;
$fraud = $notif->fraud_status;

$message = 'ok';

if ($transaction == 'capture') {
    // For credit card transaction, we need to check whether transaction is challenge by FDS or not
    if ($type == 'credit_card') {
        if ($fraud == 'challenge') {
            // TODO set payment status in merchant's database to 'Challenge by FDS'
            // TODO merchant should decide whether this transaction is authorized or not in MAP
            $message = "Transaction order_id: " . $order_id ." is challenged by FDS";
        } else {
            // TODO set payment status in merchant's database to 'Success'
            $message = "Transaction order_id: " . $order_id ." successfully captured using " . $type;
        }
    }
} elseif ($transaction == 'settlement') {
    // TODO set payment status in merchant's database to 'Settlement'
    $message = "Transaction order_id: " . $order_id ." successfully transfered using " . $type;
} elseif ($transaction == 'pending') {
    // TODO set payment status in merchant's database to 'Pending'
    $message = "Waiting customer to finish transaction order_id: " . $order_id . " using " . $type;
} elseif ($transaction == 'deny') {
    // TODO set payment status in merchant's database to 'Denied'
    $message = "Payment using " . $type . " for transaction order_id: " . $order_id . " is denied.";
} elseif ($transaction == 'expire') {
    // TODO set payment status in merchant's database to 'expire'
    $message = "Payment using " . $type . " for transaction order_id: " . $order_id . " is expired.";
} elseif ($transaction == 'cancel') {
    // TODO set payment status in merchant's database to 'Denied'
    $message = "Payment using " . $type . " for transaction order_id: " . $order_id . " is canceled.";
}

$filename = $order_id . ".txt";
$dirpath = 'log';
is_dir($dirpath) || mkdir($dirpath, 0777, true);

echo file_put_contents($dirpath . "/" . $filename, $message);
```

Dari baris kode di atas, ketika terdapat notifikasi via webhook ataupun HTTP(S), handler akan membaca notifikasi lalu membaca status transaksi. Setiap ada perubahan transaksi, keterangannya akan ditulis di dalam variable `$message`. Karena di sini kita belum menggunakan database apapun, jadi kita coba tulis keterangan dari setiap prosesnya ke dalam `log file` dengan ekstensi `.txt`.

## Step-5: Uji Coba{#uji-coba}

Untuk melakukan uji coba aplikasi payment sederhana ini, kita perlu mendaftarkan terlebih dahulu URL yang digunakan sebagai notification handler. Buka kembali dashboard midtrans, lalu masuk ke menu PENGATURAN, lalu pilih sub menu KONFIGURASI. Pada halaman ini terdapat form untuk mendaftarkan URL yang diperlukan seperti `Payment notification URL`, `Recurring Notification URL`, `Finish Redirect URL` dan lain-lain. 

Untuk menangani webhook atau HTTP(S) POST notification, isi `payment notification URL` dengan url `notification-handler.php`, misalnya `https://your-web.com/notification-handler.php` ditulis menggunakan URL protocol prefix `https`. Ya, notikasinya mesti terhubung dengan internet. Midtrans tidak bisa mengirim **notifikasi ke localhost**, jadi kita coba pakai ngrok yang sudah kita siapkan sebelumnya.

Sekarang kita coba run dulu aplikasi payment, buka terminal lalu run command berikut ini.

```bash
php -S localhost:8080
```

Output:

```
`[Wed Jul  3 08:46:19 2024] PHP 8.2.20 Development Server (http://localhost:8080) started
```



Setelah itu kita buka terminal baru untuk running ngrok untuk http dengan port 8080.

```bash
ngrok http 8080
```

Setelah kita run, nanti terdapat keterangan link aplikasi kita dengan format: `https://xxxx-xxx-xx-xx-xxx.ngrok-free.app`. Ya, linknya beda beda. Nah dengan menggunakan link ini kita sudah terhubung ke internet. Jadi kita bisa mendaftarkan link untuk `Payment notification URL` dengan URL `https://xxxx-xxx-xx-xx-xxx.ngrok-free.app/notification-handler.php`.

Buka kembali halaman [INTEGRATIONS](https://dashboard.sandbox.midtrans.com/integrations/introductions) di dahsboard midtrans. Kita akan masuk ke halaman tersebut dengan text `Welcome to Website Integration Page` dan juga button **Next**. Klik button Next untuk melanjutkan.

![Halaman welcome to website integration page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/php/payment-sederhana-with-midtrans/1-setup-handler-halaman-konfigurasi.png)



Pada halaman berikutnya, kita masuk ke halaman [choose plugin](https://dashboard.sandbox.midtrans.com/integrations/plugins). Pilih opsi **Build Yourself**, lalu tekan button next untuk melanjutkan. 

![halaman choose plugin](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/php/payment-sederhana-with-midtrans/2-setup-handler-choose-plugin.png)



Selanjutnya kita akan masuk ke halaman [Api Configuration keys](https://dashboard.sandbox.midtrans.com/integrations/configurations), di bagian `Payment notification URL` isi dengan link ketika kita run ngrok `https://xxxx-xxx-xx-xx-xxx.ngrok-free.app/notification-handler.php`, setelah itu tekan button **Save and next**.

![set payment notification url](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/php/payment-sederhana-with-midtrans/3-a-setup-notification-handler-set-url.png)

Persiapan uji coba sudah selesai, selanjutnya kita bisa coba langsung buka aplikasi dengan menggunakan url dari ngrok yaitu `https://xxxx-xxx-xx-xx-xxx.ngrok-free.app`. 

![run project - buka project di browser](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/php/payment-sederhana-with-midtrans/4-run-project-buka-di-browser.png)

Di halaman awal tampil daftar item yang dibeli dan terdapat button checkout. Klik button **checkout** untuk masuk ke halaman `checkout-process.php`. Ketika membuka halaman ini, kita bisa lihat ada snapToken. 

![halaman checkout](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/php/payment-sederhana-with-midtrans/5-run-project-buka-halaman-checkout.png)

SnapToken ini kita dapatkan setelah mengirim request menggunakan server key dan function `getSnapToken()` dari package midtrans.

```php
$snapToken = Midtrans\Snap::getSnapToken($transaction);
```

Nah snapToken ini kita gunakan untuk memanggil built-in interface (snap) dari midtrans. Bisa kita lihat di bagian kode javascript.

```php
snap.pay('<?php echo $snapToken?>',
	... kode lainnya
)

```

Selanjutnya coba klik button `Pay!`. Kita bisa lihat ada interface snap midtrans untuk melakukan pembayaran. 

![klik tombol pay](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/php/payment-sederhana-with-midtrans/6-run-project-klik-tombol-pay.png)

Pilih Continue, lalu pilih metode pembayaran (misalnya Mandiri), lalu klik SEE ACCOUNT NUMBER. Setelah itu kita bisa lihat `Company Code` dan juga `Payment Code`.

![klik pembayaran](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/php/payment-sederhana-with-midtrans/10-run-project-klik-mandiri-untuk-pembayaran.png)

 **Keterangan:** ini hanya uji coba jadi tidak perlu mengirim uang betulan, sekali lagi mengingatkan jangan coba mengirim uang betulan ya.

Nah ketika selesai proses di atas dan kita klik tombol x, midtrans akan mengirimkan HTTP(S) POST notification dan kita bisa lihat di folder `log` terdapat file `.txt`, tanda notication handler kita berjalan dengan baik.

![output ketika close snap midtrans](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/php/payment-sederhana-with-midtrans/8-run-project-close-snap.png)



![Output di file log](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/php/payment-sederhana-with-midtrans/9-run-project-isi-file-log.png)



## Penutup{#penutup}
Pada tutorial kali ini, yaitu membuat aplikasi payment sederhana menggunakan PHP dan midtrans, ada beberapa hal yang kita pelajari. Dimulai dari proses instalasi API Client dari midtrans sampai dengan uji coba proses pembayaran menggunakan built-in interface atau snap. 

Berbeda dengan tutorial sebelumnya, aplikasi kita harus terhubung ke internet ketika proses uji coba, karena harus menerima notifikasi via HTTP(S) POST atau webhook dari midtrans. Di sini kita sudah coba menggunakan ngrok untuk tunneling, supaya aplikasi dapat diakses lewat internet dan supaya HTTP(S) POST dapat dihandle langsung oleh notification-handler. Selain itu, untuk mengetahui apakah proses pembayaran melalui midtrans berhasil atau gagal, kita sudah coba untuk menuliskannya ke dalam file `.txt` dan setelah uji coba kita bisa lihat beberapa file `.txt` setiap proses pembayaran atau terjadinya perubahan status transaksi.

Tertarik untuk eksplorasi lebih jauh? Selamat bereksperimen dan tetap semangat berkarya.