---
title: "How to Install Laravel on Android via Termux"
slug: "how-to-install-laravel-on-android-via-termux"
category: "How To Install"
date: "2024-12-02"
status: "draft"
id_version: "tutorial-install-laravel-di-hp-android-via-termux"
---

After installing composer in the [previous tutorial](https://qadrlabs.com/post/tutorial-install-dan-setup-composer-di-hp-android-menggunakan-termux), we can install various packages and frameworks. One of the frameworks we can install through composer is laravel. The question is, can we install laravel on an android phone using termux? In this tutorial, we will try to install laravel using composer and termux on an android phone.

## Overview{#overview}
What we will try in this tutorial is installing laravel on an android phone. Besides installing it, we will also set up the database configuration and run the laravel project in the browser. Here are a few things you need to prepare before following this tutorial:
1. Termux
2. PHP
3. MariaDB
4. Composer
You can prepare everything above by following the previous editions of the [Persiapan Belajar Coding di HP](https://qadrlabs.com/series/persiapan-belajar-coding-di-hp) tutorial series.

Next, let's first check the installed php version. Open **termux**, then run the following command.
```
php -v
```
At the time this tutorial was written, the installed php version was 8.3.10.

Next, let's start the mariadb service by running the following command.
```
mariadbd-safe -u root &
```
When we run the command above, the output `Starting mariadbd daemon with databases` appears, which means the mariadb service has started successfully.

Next, let's verify that composer is installed by running the following command.
```
composer -Version
```
The output displayed in termux is the installed composer version, and at the time this tutorial was written, it showed `Composer version 2.8.3`.

Once everything is verified, we can move on to the first step to create a laravel project using composer.

## Step 1 - Create a New Laravel Project {#step-1-buat-project-laravel-baru}
In this first step, we go straight to creating a new project using composer. Now run the following command in termux.
```
composer create-project --prefer-dist laravel/laravel crud-app-example
```

![step 1 - buat project laravel baru menggunakan composer](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-laravel/1-buat-project-laravel.jpg)

Wait until the project creation process finishes. Once it is done, you can see in the terminal output that there is a `migrate` command process running against the database, as shown in the following image.

![project selesai dibuat](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-laravel/2-project-created.jpg)

Next, let's move into the project directory.
```
crud-app-example
```
Next, we can check the installed laravel version using the `nano` text editor. Open the `composer.json` file using the nano text editor.
```
nano composer.json
```
At the time this tutorial was written, the installed laravel version was `^11.31`. Next, we can exit the nano text editor by pressing `CTRL`+x.

## Step 2 - Set Up the Database Configuration {#step-2-atur-konfigurasi-database}
In step 1 we successfully installed laravel, and if we look at the output displayed in termux, there is a migrate process. By default, laravel 11 uses `sqlite` as its database. Now we will try to use the mariaDB we installed earlier, including its credentials. To set up the database configuration, open the `.env` file using the nano text editor.
```
nano .env
```

Next, adjust the database configuration section of the `.env` file.
```
DB_CONNECTION=mariadb
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_belajar
DB_USERNAME=root
DB_PASSWORD=1234
```

In the `.env` file, we use `db_belajar` as the project database, and we also add the mariadb credentials with the username `root` and the password `1234`, matching what we set in the [create a password for root](https://qadrlabs.com/post/tutorial-install-mysql-di-hp-android-menggunakan-termux#step-3) section of the previous tutorial.

Once you are done, press `CTRL`+o to save the `.env` file and `CTRL`+x to exit the nano text editor.

![isi dari file .env](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-laravel/3-edit-file-dotenv.jpg)

## Step 3 - Run the Migrate Command {#step-3-run-migrate-command}
After setting up the database configuration, we can now run the `migrate` command.
```
php artisan migrate
```

![Run migrate command](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-laravel/4-run-migrate-command.jpg)

Since we have not created the `db_belajar` database yet, the output shown in the image above will appear. Choose `yes`, then press `enter` to continue.
![proses run migrate command](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-laravel/5-run-migrate-command-selesai.jpg)

At this stage, we have successfully run the migrate command with the database configuration from the previous tutorial.

## Step 4 - Test Running the Project {#step-4-uji-coba-run-project}
Now we will try to access our project in the browser. To access the project in the browser, we of course need to run the project first using the following command.
```
php artisan serve
```

![run php artisan serve](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-laravel/6-run-artisan-server-command.jpg)

Next, access the project through the url `http://127.0.0.1:8000` in the browser. When opening the project in the browser, you can see the default laravel 11 page as shown in the following image.

![akses project di browser](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-laravel/7-tes-run-di-browser.jpg)

## Closing {#penutup}
In this tutorial, we tried installing laravel on an android phone using the composer installed in termux. As we have seen, we can install laravel using the php and composer we installed earlier. During the laravel installation process, we were able to install it right away without any issues. In addition, we were able to set up the database configuration using the mariadb credentials we set in the previous tutorial. And when we ran the migrate command, the migrate process went smoothly and it also created the database automatically according to the database name we set in the `.env` file. And after all the steps were completed, we were able to run the laravel project in the browser.

At the end of this tutorial, we have set up a laravel project and can run it in the browser. Next, you can go straight into learning laravel with the materials available. Happy Coding!
