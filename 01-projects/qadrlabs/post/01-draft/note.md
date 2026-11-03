sebelumnya saya menulis https://qadrlabs.com/post/cara-install-php-85-menggunakan-ppa-ondrej-php-di-ubuntu-2504 atau `/home/gun-gun-priatna/obsidian-vault/01-projects/qadrlabs/post/03-published/php/cara-install-php-85-menggunakan-ppa-ondrej-php-di-ubuntu-2504.md`.

karena saat itu ppa tidak tersedia untuk ubuntu 25.04 (bukan lts).

sekarang laptop saya dengan os ubuntu 26.04 saya coba install ppa ondrej.
alasan saya ingin install itu karena saya memerlukan project dengan versi php yang berbeda beda sama seperti alasan yang pernah saya tullis ketika saya menyusun artikel tentang ppa tersebut.

ketika saya akses https://launchpad.net/~ondrej/+archive/ubuntu/php terdapat notifikasi

```
This repository is in process of being merged into [https://packages.sury.org/php/](https://packages.sury.org/php/);

For Ubuntu Resolute, [https://packages.sury.org/php/](https://packages.sury.org/php/) is the canonical way of getting PHP packages, for previous releases, I will provide a simple way how to migrate to the new repositories in upcoming weeks, you can still use this repository for Ubuntu Jammy and Ubuntu Noble.
```

saya cek https://packages.sury.org/php/README.txt dan ada isi nya
```
#!/bin/sh
# To add this repository please do:

if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi

${SUDO} apt-get update
${SUDO} apt-get -y install lsb-release ca-certificates curl
${SUDO} curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
${SUDO} dpkg -i /tmp/debsuryorg-archive-keyring.deb
${SUDO} sh -c 'echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
${SUDO} apt-get update
```

saya ingin uji coba install php 8.5 dan php fpm dan lainnya untuk development laravel dengan nginx sebagai servernya (note nginx sudah diinstall). 

namun saat ini sudah terinstall 
```
$ php -v
PHP 8.5.9 (cli) (built: Jul 28 2026 13:06:52) (NTS)
Copyright (c) The PHP Group
Built by Shivam Mathur
Zend Engine v4.5.9, Copyright (c) Zend Technologies
    with Zend OPcache v8.5.9, Copyright (c), by Zend Technologies

```

jadi perlu hapus terlebih dahulu dengan aman.