Jika Anda membaca ini, kemungkinan besar Anda sudah pernah mendengar tentang Laravel sebelumnya, mungkin sudah mencoba beberapa tutorial, dan sekarang Anda ingin membangun sesuatu yang nyata. Bukan sekadar mengikuti contoh yang sudah jadi, tetapi benar-benar memahami bagaimana sebuah aplikasi web disusun dari nol. Course ini dirancang untuk tujuan tersebut.

## Apa yang Akan Anda Bangun {#what-you-will-build}

Sepanjang course ini, Anda akan membangun **Catatku**, sebuah aplikasi jurnal pribadi. Namanya berarti "My Notes" dalam Bahasa Indonesia, dan konsepnya sengaja dibuat sederhana: pengguna dapat menulis, membaca, mengedit, dan menghapus entri jurnal pribadi mereka. Tidak ada orang lain yang dapat melihatnya.

Dari luar, Catatku terlihat sederhana. Namun di baliknya, Anda akan mengimplementasikan semua yang membuat sebuah aplikasi web nyata bekerja:

- **Routing** - bagaimana Laravel memetakan URL ke kode yang tepat
- **MVC pattern** - bagaimana controller, view, dan model membagi tanggung jawab
- **Database migrations** - mendefinisikan struktur tabel menggunakan PHP, bukan SQL mentah
- **Eloquent ORM** - membaca dan menulis ke database dengan sintaks yang bersih dan ekspresif
- **Full CRUD** - membuat, membaca, memperbarui, dan menghapus entri jurnal dengan validasi yang tepat
- **Authentication** - registrasi, login, dan logout, dibangun dari nol
- **Ownership-based authorization** - memastikan pengguna hanya dapat mengakses data mereka sendiri

Di akhir course ini, Anda akan memiliki aplikasi yang berfungsi penuh beserta gambaran mental yang jelas tentang bagaimana setiap bagian terhubung satu sama lain.

### Why a Journal App?

Sebuah jurnal pribadi adalah proyek pengajaran yang ideal karena dua alasan yang melampaui kesederhanaannya.

Pertama, **authorization terasa intuitif**. Tentu saja Anda tidak seharusnya bisa membaca jurnal orang lain. Aturan ini langsung terasa masuk akal tanpa perlu penjelasan panjang, yang berarti kita dapat fokus pada *bagaimana* menerapkannya, bukan pada *mengapa* hal itu penting.

Kedua, **pola data scope bersifat universal**. Mengambil entri yang hanya dimiliki oleh pengguna yang sedang login, bukan semua entri di database, adalah salah satu pola yang paling umum dalam aplikasi dunia nyata. Mempelajarinya di sini, dalam konteks yang masuk akal, berarti Anda akan langsung mengenalinya ketika menemukannya lagi di proyek Anda sendiri.

## Untuk Siapa Course Ini {#who-this-course-is-for}

Course ini ditujukan untuk developer yang sudah memiliki pengetahuan dasar tentang PHP. Anda harus merasa nyaman dengan variabel, fungsi, array, dan conditional. Anda tidak memerlukan pengalaman sebelumnya dengan Laravel atau framework lainnya.

Akan sangat membantu jika Anda sudah pernah membangun halaman web sederhana dan memiliki pemahaman dasar tentang cara kerja HTML. Course ini tidak akan meluangkan waktu untuk menjelaskan sintaks PHP dasar, karena fokusnya sepenuhnya pada Laravel dan alasan di balik cara kerjanya.

Jika Anda sama sekali baru dalam PHP, ada baiknya mempelajari dasarnya terlebih dahulu sebelum melanjutkan ke sini.

## Yang Anda Butuhkan {#what-you-will-need}

Sebelum mulai membangun, pastikan Anda memiliki tools berikut:

**PHP 8.3 atau lebih tinggi.** Laravel 13 membutuhkan setidaknya PHP 8.3.

**Composer.** Package manager untuk PHP. Laravel dan semua dependensinya diinstal melalui Composer.

**MySQL.** Database yang akan kita gunakan untuk menyimpan akun pengguna dan entri jurnal.

**Code editor.** VS Code adalah pilihan yang paling populer dan memiliki ekstensi yang sangat baik untuk pengembangan PHP dan Laravel.

Ada beberapa cara untuk mengatur PHP, Composer, dan MySQL di komputer Anda. Anda dapat menginstal masing-masing secara terpisah, atau menggunakan paket yang menggabungkan semuanya. Beberapa pilihan populer antara lain [Laravel Herd](https://herd.laravel.com), [XAMPP](https://www.apachefriends.org), dan [Laragon](https://laragon.org). Beberapa di antaranya memiliki tier berbayar atau versi berbayar, jadi ada baiknya memeriksanya sebelum mengunduh.

Dalam course ini, kita akan menggunakan **Laragon versi 6**, yang sepenuhnya gratis dan tidak memerlukan pembelian lisensi. Ia menggabungkan PHP, MySQL, dan server lokal dalam satu installer, menjadikannya pilihan yang paling mudah untuk memulai di Windows.

Jangan khawatir jika Anda belum mengatur semua ini. Lesson 2 mencakup seluruh proses instalasi secara langkah demi langkah.

## Peta Jalan Course {#course-roadmap}

Course ini disusun dalam 12 lesson yang progresif. Setiap kelompok dibangun langsung berdasarkan apa yang telah dipelajari sebelumnya.

**Lesson 1-2: Orientasi dan Persiapan.**
Sebelum menulis satu baris kode pun, Anda akan mengetahui ke mana perjalanan ini menuju dan memiliki lingkungan pengembangan yang berfungsi. Di akhir Lesson 2, sebuah proyek Laravel baru akan berjalan di browser Anda.

**Lesson 3-4: Routing dan MVC.**
Anda akan mempelajari bagaimana Laravel memproses sebuah request dari saat URL dimasukkan hingga saat response dikirim kembali. Memahami alur ini sejak awal membuat segalanya menjadi jelas, karena Anda akan mengetahui *mengapa* kode diorganisasikan seperti itu, bukan hanya *apa* yang harus diketik.

**Lesson 5-6: Database dan Eloquent.**
Anda akan mempelajari migration, yang mendefinisikan struktur tabel menggunakan kode PHP, dan Eloquent ORM, yang memungkinkan Anda berinteraksi dengan database tanpa menulis SQL mentah. Alih-alih `SELECT * FROM entries WHERE user_id = 1`, Anda cukup menulis `auth()->user()->entries()`.

**Lesson 7-9: Full CRUD.**
Di sinilah Catatku benar-benar hidup. Anda akan membangun rangkaian operasi yang lengkap: menampilkan daftar entri, membaca detail, membuat entri baru dengan validasi form, mengedit yang sudah ada, dan menghapus dengan konfirmasi yang tepat. Setelah ketiga lesson ini, Anda akan memiliki intuisi yang kuat tentang bagaimana data mengalir dari sebuah browser form hingga ke database dan kembali lagi.

**Lesson 10-11: Authentication dan Authorization.**
Anda akan menambahkan registrasi pengguna, login, dan logout. Anda juga akan mengunci setiap entri sehingga hanya pemiliknya yang dapat membaca, mengedit, atau menghapusnya. Pola kepemilikan ini adalah sesuatu yang akan Anda temui di hampir setiap aplikasi dunia nyata yang Anda bangun.

**Lesson 12: Refleksi dan Langkah Selanjutnya.**
Lesson terakhir bukan tentang menulis kode baru. Ini adalah kesempatan untuk melihat kembali semua yang telah Anda bangun, menjelajahi fitur-fitur yang bisa Anda tambahkan sendiri ke Catatku, dan memetakan topik-topik Laravel lanjutan mana yang layak dijelajahi berikutnya.

## Sebelum Anda Melanjutkan

Setiap konsep dalam course ini diperkenalkan pada saat dibutuhkan, bukan sebagai teori abstrak yang terlepas dari konteks. Anda akan selalu memahami alasan *mengapa* di balik kode sebelum menulisnya.

Ambil waktu Anda. Satu lesson yang dipahami sepenuhnya lebih berharga dari tiga lesson yang diselesaikan dengan terburu-buru.

Lanjutkan ke **Lesson 2** untuk mengatur lingkungan pengembangan Anda dan menjalankan proyek Laravel pertama Anda.
