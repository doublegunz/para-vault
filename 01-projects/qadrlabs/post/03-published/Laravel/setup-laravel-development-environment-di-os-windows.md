---
title: "Setup Laravel Development Environment di OS Windows"
slug: "setup-laravel-development-environment-di-os-windows"
category: "Laravel"
date: "2023-08-04"
status: "published"
---

Beberapa waktu yang lalu saya mengisi pelatihan web programming menggunakan framework Laravel. Kebetulan peserta yang mengikuti pelatihan belum terbiasa menggunakan Linux. Jadi supaya menyesuaikan dengan kebiasaan peserta, saya mencoba untuk install OS Windows dan setup laravel development environment.

Ada beberapa tools yang saya persiapkan supaya kebiasaan saya menggunakan linux bisa dipakai di Windows juga, terutama ketika berhubungan dengan terminal atau cmd di windows, kebutuhan penggunaan git dan lain-lain. Setelah saya coba-coba, berikut ini adalah tools yang saya gunakan.

## 1. Cmder + Git{#tools-1}
Cmder ini adalah tools yang saya gunakan untuk menggantikan `Command Prompt` windows. Kenapa saya gunakan Cmder dibandingkan menggunakan `Command Prompt`? Alasan menggunakan Cmder adalah karena kita bisa running `command` yang biasa digunakan di Linux ketika kita gunakan Cmder. Selain karena saya lebih terbiasa dengan command linux, alasan lainnya adalah memperkenalkan `command` linux ke peserta pelatihan, sehingga peserta pelatihan terbiasa menggunakan `command` linux ketika belajar deploy ke server yang notabene banyak menggunakan OS linux.

Untuk proses install, kita bisa download dulu cmder di [web resminya](https://cmder.app/). Ketika download, pastikan pilih **Download Full**, karena sudah satu paket dengan Git for Windows, jadi nanti kita tidak perlu install git secara terpisah. Setelah cmder kita download, selanjutnya kita unzip file zip cmder yang kita download. Setelah itu kita run **Cmder** (Cmder.exe). Pada saat run kita bisa lihat proses setup cmder secara otomatis.
![First run Cmder](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/dev-environment/laravel-environment-windows/setup-cmder.png)

Berikut ini screenshot test command linux seperti `ls`, `cd`, `mkdir` dan `rm`.
![Test command linux](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/dev-environment/laravel-environment-windows/test%20run%20command.png)

Berikut penjelasan beberapa command dasar Linux seperti `ls`, `cd`, `mkdir`, dan `rm`:

1. **`ls` (List Directory Contents)**:
   - Fungsi: Menampilkan daftar file dan direktori dalam direktori saat ini.
   - Contoh penggunaan:
     - `ls` → Menampilkan semua file dan folder dalam direktori saat ini.
     - `ls -l` → Menampilkan daftar dalam format detail, termasuk izin, ukuran, dan tanggal modifikasi.
     - `ls -a` → Menampilkan file tersembunyi (file yang namanya diawali dengan titik `.`).

2. **`cd` (Change Directory)**:
   - Fungsi: Berpindah ke direktori lain.
   - Contoh penggunaan:
     - `cd /home/user` → Berpindah ke direktori `/home/user`.
     - `cd ..` → Berpindah satu tingkat ke direktori induk.
     - `cd ~` atau hanya `cd` → Berpindah ke direktori home pengguna saat ini.

3. **`mkdir` (Make Directory)**:
   - Fungsi: Membuat direktori baru.
   - Contoh penggunaan:
     - `mkdir project` → Membuat direktori bernama `project` dalam direktori saat ini.
     - `mkdir -p /home/user/documents/new_folder` → Membuat direktori beserta subdirektori yang diperlukan (misalnya, jika `documents` atau `new_folder` belum ada).

4. **`rm` (Remove Files or Directories)**:
   - Fungsi: Menghapus file atau direktori.
   - Contoh penggunaan:
     - `rm file.txt` → Menghapus file bernama `file.txt`.
     - `rm -r folder_name` → Menghapus direktori `folder_name` beserta semua isinya.
     - `rm -rf folder_name` → Menghapus direktori `folder_name` secara paksa tanpa meminta konfirmasi, termasuk isinya (berbahaya jika tidak digunakan dengan hati-hati).

Command-command ini sering digunakan dalam operasi sehari-hari di terminal Linux untuk navigasi dan manajemen file serta direktori.

Selain Cmder, saya juga memperkenalkan Git ke peserta pelatihan. Sebagai pengingat, **Git** adalah sistem kontrol versi yang digunakan untuk melacak perubahan pada file komputer dan mengkoordinasikan pekerjaan pada file-file tersebut di antara beberapa orang. Ini adalah alat penting dalam pengembangan perangkat lunak, tetapi dapat digunakan untuk melacak perubahan pada set file apa pun.

Beberapa fitur utama Git:
1. Pelacakan perubahan: Git mencatat semua perubahan yang dibuat pada file, memungkinkan Anda untuk melihat riwayat lengkap dan kembali ke versi sebelumnya jika diperlukan.
2. Branching dan merging: Anda dapat membuat "cabang" yang terpisah dari kode utama untuk mengembangkan fitur baru tanpa mengganggu kode yang stabil, kemudian menggabungkannya kembali ketika sudah siap.
3. Kolaborasi: Memungkinkan beberapa pengembang untuk bekerja pada proyek yang sama secara bersamaan tanpa menimpa pekerjaan satu sama lain.
4. Penyimpanan terdistribusi: Setiap pengembang memiliki salinan lengkap dari repositori, termasuk seluruh riwayat, sehingga mereka dapat bekerja secara offline.

Kita tidak perlu menginstal Git lagi, karena kita sudah terinstall ketika kita install Cmder yang versi full. Jadi kita bisa langsung menggunakannya.

## 2. Laragon{#tools-2}
Dalam rangka memenuhi kebutuhan konfigurasi web server, database, dan PHP, pilihan saya jatuh pada [Laragon](https://laragon.org/). Mengacu pada informasi yang tersedia di situs resminya, Laragon menawarkan solusi pengembangan yang komprehensif dan fleksibel. Platform ini dikenal dengan karakteristiknya yang universal, mudah dipindahkan, dan mampu berjalan secara terisolasi.

Laragon tidak hanya unggul dalam hal portabilitas, tetapi juga menawarkan kinerja dan kecepatan yang optimal. Keunggulan ini berlaku untuk berbagai bahasa pemrograman, termasuk namun tidak terbatas pada PHP, Node.js, Python, Java, Go, dan Ruby. 

Desain Laragon menitikberatkan pada empat aspek utama: kecepatan eksekusi, penggunaan sumber daya yang efisien, kemudahan pengoperasian, serta fleksibilitas untuk pengembangan lebih lanjut. Kombinasi fitur-fitur ini menjadikan Laragon sebagai pilihan yang menarik bagi para pengembang yang menginginkan lingkungan kerja yang efisien dan mudah disesuaikan.

[Dokumentasi resmi](https://laragon.org/docs/) menunjukkan bahwa Laragon menawarkan kemudahan dalam penggunaan dan pemasangan. Prosesnya sangat sederhana, hanya memerlukan beberapa klik untuk menyelesaikan instalasi. Keunggulan Laragon tidak berhenti di situ; ia juga menyertakan berbagai alat pengembangan penting seperti Composer dan NPM. Hal ini menghemat waktu dan tenaga karena kita tidak perlu menginstal setiap alat secara terpisah untuk keperluan pelatihan.

Lebih jauh lagi, Laragon dikenal dengan stabilitasnya. Pengguna jarang mengalami masalah seperti crash atau konflik versi antar tools. Keandalan ini sangat berharga dalam konteks pelatihan, karena memungkinkan peserta dan instruktur untuk berkonsentrasi penuh pada materi yang disampaikan, tanpa terganggu oleh masalah teknis yang tidak perlu.

Berikut ini screenshot tampilan UI laragon.

![laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/dev-environment/laravel-environment-windows/run%20laragon.png)

Untuk web server, terdapat tools alternative yang dapat kita gunakan, yaitu [Laravel Herd](https://qadrlabs.com/post/panduan-install-laravel-herd-dan-mysql-di-windows). Karena belum saya explore, jadi sementara ini saya gunakan laragon terlebih dahulu.

**Update:** Setelah saya coba eksplore laravel Herd dan rilis laravel 12, tampaknya saya lebih memilih menggunakan laravel herd. Salah satu alasannya adalah karena kita bisa [running multiple php version](https://qadrlabs.com/post/running-multiple-php-versions-simultaneously-on-windows).

## 3. Code Editor (Visual Studio Code){#tools-3}
Terlepas dari platform yang digunakan, baik itu MacOS, Linux, atau sistem operasi lainnya, **Visual Studio Code** selalu menjadi pilihan utama saya sebagai editor kode sebelum beralih ke **PHPStorm**. Visual Studio Code, yang dapat diakses melalui situs resminya, menawarkan dukungan yang sangat baik untuk pengembangan Laravel. Hal ini dimungkinkan berkat adanya ekstensi khusus yang dirancang untuk memfasilitasi pengembangan aplikasi Laravel.

Keunggulan Visual Studio Code tidak hanya terbatas pada dukungannya terhadap Laravel. Editor ini juga menyediakan integrasi yang mulus dengan berbagai alat pengembangan penting lainnya. Pengguna dapat dengan mudah menggunakan Git untuk manajemen versi, Composer untuk pengelolaan dependensi PHP, serta terminal terintegrasi untuk berbagai tugas pengembangan. Kombinasi fitur-fitur ini menjadikan Visual Studio Code sebagai lingkungan pengembangan yang komprehensif dan efisien untuk berbagai jenis proyek, termasuk aplikasi Laravel.

Untuk proses instalasi laragon dan visual studio code, teman-teman dapat membaca panduannya pada artikel [Panduan Lengkap Menggunakan Visual Studio Code dan Laragon untuk Web Development](https://qadrlabs.com/post/panduan-lengkap-menggunakan-visual-studio-code-dan-laragon-untuk-web-development)

## 4. Web Browser (Mozilla Firefox) {#tools-4}
Pemilihan Web Browser sebenarnya bersifat fleksibel dan sangat tergantung pada preferensi individual. Namun, dalam konteks pengembangan web, Mozilla Firefox menjadi pilihan pribadi saya. Alasan utama pemilihan ini terletak pada ketersediaan beberapa ekstensi khusus yang hanya dapat ditemukan di Firefox.

Ekstensi-ekstensi ini dirancang secara spesifik untuk mendukung dan mempermudah proses pengembangan web. Salah satu contoh yang menonjol adalah Multi-Account Containers, sebuah fitur yang sangat berguna bagi para pengembang web. Selain itu, masih banyak ekstensi lain yang menjadikan Firefox sebagai alat yang powerful dalam ekosistem pengembangan web.

Meskipun demikian, penting untuk diingat bahwa pilihan Web Browser tetap menjadi keputusan personal yang dapat disesuaikan dengan kebutuhan dan kenyamanan masing-masing pengembang.

## Uji Coba Install Laravel{#uji-coba}
Setelah kita siapkan tools di atas, sekarang kita coba install laravel. Ada dua cara install laravel menggunakan setup yang sekarang ini:
**Cara Pertama** adalah install melalui menu Quick App, lalu pilih Laravel untuk menginstall Laravel.
![install melalui quick app](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/dev-environment/laravel-environment-windows/install%20laravel%20melalui%20menu%20Quick%20App.png)

Lalu kita atur nama project laravel.
![set nama project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/dev-environment/laravel-environment-windows/setup%20nama%20project.png)

Setelah itu kita tunggu proses install selesai.
![proses install dimulai](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/dev-environment/laravel-environment-windows/proses%20install%20laravel.png)

**Cara kedua** install melalui cmder langsung menggunakan composer. Kita run terlebih dahulu Cmder dengan klik menu Terminal di UI Laragon.

![laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/dev-environment/laravel-environment-windows/run%20laragon.png)

Setelah itu kita ketik command berikut ini di cmder.

```
composer create-project --prefer-dist laravel/laravel sample-app
```

![run command composer untuk install laravel](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/dev-environment/laravel-environment-windows/install%20laravel%20melalui%20cmder.png)

Setelah itu tunggu sampai proses install selesai. 

Selanjutnya kita bisa run project dengan run command `php artisan serve`, lalu buka `http://127.0.0.1:8000` di browser.
![run project melalui url 127.0.0.1:8000](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/dev-environment/laravel-environment-windows/run%20project%201.png)

Alternatifnya kita bisa akses project dengan membuka `http://nama-project.test`.
![run project melalui virtual host](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/dev-environment/laravel-environment-windows/run%20project%202.png).

Berikut adalah parafrase dari kalimat tersebut:

## Kesimpulan {#kesimpulan}
Dalam artikel ini, saya telah berbagi pengalaman saya mengenai perangkat lunak yang saya manfaatkan untuk menyiapkan lingkungan pengembangan di sistem operasi Windows. Setelah melakukan uji coba dan evaluasi, saya menemukan bahwa kombinasi dari empat aplikasi - Cmder, Laragon, Visual Studio Code, dan Mozilla Firefox - mampu memenuhi semua kebutuhan untuk menyelenggarakan pelatihan pemrograman web menggunakan framework Laravel.

Namun, saya juga menyadari bahwa setiap pengembang mungkin memiliki preferensi dan kebutuhan yang berbeda. Oleh karena itu, saya sangat tertarik untuk mendengar pengalaman Anda. Alat apa saja yang Anda andalkan dalam perjalanan belajar pemrograman? Jika Anda memiliki rekomendasi tambahan atau pengalaman unik dengan alat-alat pengembangan tertentu, saya mengundang Anda untuk berbagi di bagian komentar. Kontribusi Anda akan sangat berharga dalam memperkaya diskusi dan membantu pembaca lain dalam memilih alat yang tepat untuk kebutuhan mereka.