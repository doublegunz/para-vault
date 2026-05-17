---
title: "Cara Install PHP 8.5 Menggunakan PPA Ondrej PHP di Ubuntu 25.04"
slug: "cara-install-php-85-menggunakan-ppa-ondrej-php-di-ubuntu-2504"
category: "php"
date: "2025-12-02"
status: "published"
---

Halo, pada artikel ini kita akan membahas cara menginstall PHP 8.5 menggunakan PPA Ondrej PHP di Ubuntu 25.04. PPA ini sudah sering saya gunakan karena saya menangani beberapa project yang menggunakan PHP versi lama dan juga PHP  versi baru secara bersamaan seperti yang sudah sering saya sebutkan di beberapa artikel dan tutorial sebelumnya. Karena kebetulan beberapa waktu yang lalu saya install ulang OS di laptop dan menggunakan Ubuntu 25.04, saya coba untuk install kembali PPA Ondrej PHP dan ternyata saya tidak menginstall versi PHP lama maupun PHP 8.5 yang terbaru karena tidak file yang dirilis PPA tersebut untuk Ubuntu 25.04. Sebagai catatan, sebelumnya saya juga menggunakan Ubuntu 25.04 dengan cara mengupgrade langsung dari Ubuntu 24.04 dan masih bisa menggunakan PPA Ondrej PHP.

## Percobaan Install PPA Ondrej PHP {#percobaan-install-ppa-ondrej-php}
Setelah install ulang dan menggunakan Ubuntu 25.04, saya coba menambahkan PPA ke sistem dengan run command berikut ini.
```
sudo add-apt-repository ppa:ondrej/php
```

Output yang ditampilkan:
```
$ sudo add-apt-repository ppa:ondrej/php
PPA publishes dbgsym, you may need to include 'main/debug' component
Repository: 'Types: deb
URIs: https://ppa.launchpadcontent.net/ondrej/php/ubuntu/
Suites: plucky
Components: main
'
Description:
Co-installable PHP versions: PHP 5.6, PHP 7.x, PHP 8.x and most requested extensions are included. Packages are provided for *Current* Ubuntu *LTS* releases (https://wiki.ubuntu.com/Releases).  Expanded Security Maintenance releases ARE NOT supported.

Debian stable, oldstable and Debian LTS packages are provided from a separate repository: https://deb.sury.org/#debian-dpa

You can get more information about the packages at https://deb.sury.org

BUGS&FEATURES: This PPA has a issue tracker:
https://deb.sury.org/#bug-reporting

Issues reported in a private email don't scale and most likely will be ignored.  I simply don't have capacity to answer questions privately.

CAVEATS:
1. If you are using apache2, you are advised to add ppa:ondrej/apache2
2. If you are using nginx, you are advised to add ppa:ondrej/nginx

DONATION: If you like my work and you want to show appreciation, please consider donating regularly: https://donate.sury.org/

COMMERCIAL SUPPORT: Support for PHP packages for older Debian and Ubuntu release can be bought from https://www.freexian.com/lts/php/
More info: https://launchpad.net/~ondrej/+archive/ubuntu/php
Adding repository.
Press [ENTER] to continue or Ctrl-c to cancel.
```

Tekan `enter` untuk melanjutkan.

Selanjutnya saya coba refresh package list dengan run command berikut:
```
sudo apt update
```
Ketika command di atas saya run ternyata tampil error seperti berikut ini.
```
...
Err:13 https://ppa.launchpadcontent.net/ondrej/php/ubuntu plucky Release
  404  Not Found [IP: 185.125.190.80 443]
Reading package lists... Done
E: The repository 'https://ppa.launchpadcontent.net/ondrej/php/ubuntu plucky Release' does not have a Release file.
...

```

Terdapat error PPA `ppa:ondrej/php` tidak terdapat file yang dirilis untuk Ubuntu 25.04.

Selanjutnya saya coba install php 8.5.
```
sudo apt install php8.5
```

Output yang ditampilkan:
```
gun-gun-priatna@qadrlabs:~$ sudo apt install php8.5
Error: Unable to locate package php8.5
Error: Couldn't find any package by glob 'php8.5'
```
Seperti yang terlihat PHP 8.5 tidak dapat diinstall.

Selanjutnya saya coba install PHP 8.2 menggunakan command berikut:
```
sudo apt-get install php8.2
```

Output yang ditampilkan
```
gun-gun-priatna@qadrlabs:~$ sudo apt-get install php8.2
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Note, selecting 'php8.2-common' for regex 'php8.2'
Solving dependencies... Done
0 upgraded, 0 newly installed, 0 to remove and 2 not upgraded.

```
Untuk PHP 8.2 pun tidak dapat diinstall.

## Ubuntu non-LTS no longer supported {#ubuntu-non-lts-no-longer-supported}
Setelah error install PPA dan juga install PHP, selanjutnya saya coba konfirmasi dengan mengakses url [PPA Ondrej PHP](https://launchpad.net/~ondrej/+archive/ubuntu/php) dan PPA ini memang hanya support Ubuntu 24.04 dan Ubuntu 22.04.
![OS yang disupport PPA Ondrej PHP](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/php/php-8-5/ppa-ondrey-php-2025-12-02.png). Setelah googling lebih lanjut, ternyata memang ada statement berikut:
> "After some thought, these repositories will not support the non-LTS Ubuntu versions. It requires an extra effort to add all the packages to the new Ubuntu release, and it does consume computing cycles every time there's a new PHP (or any other package updates).

The release cycle on non-LTS Ubuntu release is just 9 months this feels like a waste of just everything. There also doesn't seem to be a very high demand for these packages - only a handful of people wrote here, to mail or on Twitter asking for Ubuntu Impish support.

Ubuntu 21.10 Impish Indri will be the last non-LTS release supported." 

Baiklah dari sini sudah jelas penyebabnya itu karena memang Ubuntu Non LTS sudah tidak disupport lagi. Sebagai catatan Ubuntu 25.04 juga termasuk versi Non LTS. Sebagai referensi, diskusi terkait statement tersebut dapat diakses di [sini](https://github.com/oerdnj/deb.sury.org/issues/1662#issuecomment-2823699313)

## Percobaan Implementasi Solusi {#solusi}
Karena setelah rilis dan menulis artikel tentang [PHP 8.5](https://qadrlabs.com/post/php-85-panduan-lengkap-fitur-baru-migration-guide-dan-best-practices), saya coba beberapa solusi supaya dapat [running beberapa versi PHP secara bersamaan](https://qadrlabs.com/post/running-beberapa-versi-php-secara-bersamaan-di-ubuntu-22-04). Sebelum memulai implementasi solusi, mari kita review terlebih dahulu. Sebelumnya kita sudah menambahkan PPA Ondrej PHP dan install PHP. Ketika menambahkan PPA Ondrej PHP tampil error berikut:

```
E: The repository 'https://ppa.launchpadcontent.net/ondrej/php/ubuntu plucky Release' does not have a Release file.
```
Dan ketika install php, tampil error berikut.
```
gun-gun-priatna@qadrlabs:~$ sudo apt install php8.5
Error: Unable to locate package php8.5
Error: Couldn't find any package by glob 'php8.5'
```

Dan ketika kita cek laman resmi PPA [PPA Ondrej PHP](https://launchpad.net/~ondrej/+archive/ubuntu/php) terdapat rilis untuk Ubuntu 24.04 (Noble) dan Ubuntu 22.04 (Jammy).

Dari sini kita bisa tahu tidak ada rilis file untuk Ubuntu 25.04 dengan codename `plucky`, akan tetapi terdapat rilis untuk Ubuntu 24.04 dengan codename `noble`. Jadi bagaimana kalau kita ubah PPA nya supaya menggunakan `noble`?

Untuk percobaan ini saya coba ganti ke user sudo.
```
sudo su
```
Lalu buka APT sources file untuk PPA Ondřej Surý PHP di ubuntu menggunakan nano.
```
nano /etc/apt/sources.list.d/ondrej-ubuntu-php-plucky.sources
```

Selanjutnya temukan bagian ini.
```
Suites: plucky
```
Ubah menjadi `noble`.
```
Suites: noble
```
Save kembali file `CTRL+O`, kemudian exit `CTRL+X`.

![Edit Source File PPA Ondrej PHP](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/php/php-8-5/edit-ppa-ondrej-php-source-list.png)

Selanjutnya kita refresh dahulu package list menggunakan command berikut ini.
```
root@qadrlabs:/home/gun-gun-priatna# apt-get update
```
Output yang ditampilkan:
```
...
Get:12 https://ppa.launchpadcontent.net/ondrej/php/ubuntu noble InRelease [24.3 kB]
Get:13 https://ppa.launchpadcontent.net/ondrej/php/ubuntu noble/main amd64 Packages [140 kB]
Get:14 https://ppa.launchpadcontent.net/ondrej/php/ubuntu noble/main Translation-en [43.1 kB]

...
```
Seperti yang terlihat pada output di atas, sudah tidak ada error lagi karena memang tersedia untuk codename `noble` atau Ubuntu 24.04.

Selanjutnya saya coba install PHP menggunakan command berikut ini:
```
sudo apt-get install php8.5
```
Output yang ditampilkan:
```
$ sudo apt-get install php8.5
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Solving dependencies... Done
The following additional packages will be installed:
  libapache2-mod-php8.5 php8.5-cli php8.5-common php8.5-readline
Suggested packages:
  php-pear
The following NEW packages will be installed:
  libapache2-mod-php8.5 php8.5 php8.5-cli php8.5-common php8.5-readline
0 upgraded, 5 newly installed, 0 to remove and 23 not upgraded.
Need to get 6,936 kB of archives.
After this operation, 32.4 MB of additional disk space will be used.
Do you want to continue? [Y/n] y

```
Tekan `y`, lalu `enter` untuk melanjutkan proses install.

Setelah proses install selesai, selanjutnya kita verifikasi php yang terinstall menggunakan command:
```
php -v
```

Output yang ditampilkan.
```
$ php -v
PHP 8.5.0 (cli) (built: Nov 20 2025 19:17:11) (NTS)
Copyright (c) The PHP Group
Built by Debian
Zend Engine v4.5.0, Copyright (c) Zend Technologies
    with Zend OPcache v8.5.0, Copyright (c), by Zend Technologies
```
Dari output tersebut, kita bisa lihat PHP 8.5 berhasil diinstall.

## Penutup{#penutup}
Dengan mengubah suite dari `plucky` ke `noble` pada konfigurasi PPA, kita berhasil menginstall PHP 8.5 di Ubuntu 25.04 meskipun versi Ubuntu ini tidak officially supported. Solusi ini dapat digunakan untuk development environment, namun untuk production server sangat disarankan menggunakan Ubuntu LTS (22.04 atau 24.04) yang mendapatkan dukungan penuh dari PPA Ondrej PHP. Semoga tutorial ini bermanfaat dan dapat membantu dalam mengelola multiple versi PHP di sistem Ubuntu Anda.