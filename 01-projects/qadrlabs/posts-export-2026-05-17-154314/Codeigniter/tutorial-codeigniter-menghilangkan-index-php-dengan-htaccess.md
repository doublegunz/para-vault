---
title: "Tutorial Codeigniter: Menghilangkan index.php Dengan htaccess"
slug: "tutorial-codeigniter-menghilangkan-index-php-dengan-htaccess"
category: "Codeigniter"
date: "2016-07-29"
status: "published"
---

Dalam pengembangan website modern, struktur URL yang bersih dan mudah dipahami menjadi salah satu faktor penting untuk optimasi mesin pencari (SEO). Salah satu tantangan umum dalam pengembangan aplikasi CodeIgniter adalah adanya text "index.php" dalam URL yang dapat mengurangi efektivitas SEO. Framework CodeIgniter memungkinkan kita untuk mengoptimalkan struktur URL ini menggunakan file `.htaccess`.

File `.htaccess` (hypertext access) berfungsi sebagai file konfigurasi server terdistribusi yang dapat mengatur perilaku server pada direktori tertentu. Dengan memanfaatkan `.htaccess`, kita dapat menciptakan URL yang lebih pendek, mudah dibaca oleh pengguna, dan lebih ramah untuk crawling mesin pencari.

Sebagai contoh, struktur URL default CodeIgniter seperti:
```
http://www.website.com/index.php/controller/function
```

Dapat dioptimalkan menjadi:
```
http://www.website.com/controller/function
```

Perubahan ini memberikan beberapa keuntungan SEO:
- Meningkatkan crawlability website oleh bot mesin pencari
- Memperbaiki user experience dengan URL yang lebih mudah dibaca
- Meningkatkan kemungkinan website muncul di hasil pencarian teratas
- Memudahkan sharing URL di media sosial dan platform lain

Mari kita pelajari cara mengimplementasikan optimasi URL ini menggunakan `.htaccess` di CodeIgniter. *Let's optimize our URLs!*

## Step 1 - Membuat file .htaccess{#step-1}
Pertama kita buat file dengan nama ```.htaccess```, lalu ketik sintaks kode di bawah ini:

```
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php/$1 [L]
```

Simpan di dalam folder `CodeIgniter` (di `direktori root`). 

![direktori CodeIgniter - Tutorial Codeigniter: Menghilangkan index.php Dengan htaccess](https://1.bp.blogspot.com/-olpMJIUNpcw/V5qqBeDArDI/AAAAAAAAAa8/PbAY5BJz5agBr0AXzU6-edxbgJa6jISpwCLcB/w640-h316/gambar%2B2.png)

## Step 2 - edit konfigurasi project{#step-2}
Selanjutnya kita buka file ```config.php``` yang ada pada direktori ```application/config/config.php```.

![config.php](https://1.bp.blogspot.com/-d3XdAXy5jgQ/V5qqFs4aQ6I/AAAAAAAAAbA/BGYfq3AnlfI7RJ0kMBLLRQussGPU-IjSgCLcB/w640-h584/gambar%2B3.png)

Lalu kita cek sekitar line 38, ada baris sintaks seperti di bawah:
```php

$config['index_page'] = 'index.php'; 

```

Kita hapus ```index.php```, sehingga valuenya menjadi: 
```php
$config['index_page'] = ''; 
```

Nah kalau sudah selesai, kita simpan lagi file ```config.php``` dengan menekan tombol ```Ctrl+s```.

## Step 3 - Uji coba{#step-3}
Sekarang kita coba run aplikasi CI di browser. Ketik di address bar alamat ```http://localhost/ci3/welcome/```.

![Run CodeIgniter - Tutorial Codeigniter: Menghilangkan index.php Dengan htaccess](https://3.bp.blogspot.com/-HYukd1LFOvs/V5qqLFEfhLI/AAAAAAAAAbE/-bvTlm_Epzw4Mgn16dKkrilDMonk77TCwCLcB/s16000/gambar%2B4.png)

Seperti yang terlihat pada gambar di atas, aplikasi web bisa kita run tanpa menuliskan ```index.php```.

## Kesimpulan{#kesimpulan}
Optimasi URL melalui penghilangan 'index.php' menggunakan `.htaccess` merupakan langkah penting dalam meningkatkan performa SEO website CodeIgniter Anda. Implementasi yang telah kita lakukan memberikan beberapa keuntungan:
1. URL yang lebih bersih dan profesional, meningkatkan kepercayaan pengunjung terhadap website
2. Peningkatan crawling efficiency karena struktur URL yang lebih sederhana
3. Kemudahan dalam sharing link di berbagai platform dan media sosial
4. Potensi peningkatan ranking di mesin pencari karena URL yang lebih SEO-friendly

Pastikan untuk selalu menerapkan praktik ini di setiap proyek CodeIgniter Anda, karena dampaknya cukup signifikan untuk strategi SEO jangka panjang. Kombinasikan teknik ini dengan optimasi SEO lainnya seperti penerapan meta tags yang tepat, optimasi konten, dan peningkatan kecepatan website untuk hasil yang maksimal.

Semoga tutorial ini bermanfaat dalam upaya Anda meningkatkan visibility website di mesin pencari. Jangan lupa untuk terus mengeksplorasi teknik-teknik optimasi lainnya untuk hasil yang lebih baik. 

Selamat mengoptimasi dan semangat belajar! ^^