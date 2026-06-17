You have just decided to learn CodeIgniter, one of the most lightweight and beginner-friendly PHP frameworks available. You are excited, motivated, and ready to build something real. But then you open your laptop and realize... you do not even know where to start. What do you install first? How do you make PHP, Composer, and CodeIgniter all work together? This confusion is exactly what stops most beginners before they even write their first line of code. In this lesson, we will eliminate that friction entirely. By the end, you will have a fully working CodeIgniter 4 project running on your machine, and you will understand every piece of the setup.

## Overview {#overview}

### What You'll Build

You will set up a complete local development environment and create a fresh CodeIgniter 4 project called **Catatku**, which we will build upon throughout this course. By the end of this lesson, you will see the CodeIgniter welcome page running in your browser.

### What You'll Learn

- How to install and configure Visual Studio Code as your code editor
- How to install Laragon as your local server environment
- How to upgrade PHP to version 8.3
- How to create a new CodeIgniter 4 project using Composer
- How to navigate the CodeIgniter folder structure
- How to run the development server using Spark

### What You'll Need

- A computer running Windows (this guide uses Windows as the primary OS)
- An internet connection for downloading tools and packages
- About 30 to 45 minutes of your time

---






## Step 1: Install Visual Studio Code {#step-1-install-visual-studio-code}

### Download Visual Studio Code {#download-visual-studio-code}

Visual Studio Code (VS Code) is a free, lightweight code editor built by Microsoft. It has become the go-to editor for web developers thanks to its excellent extension ecosystem, built-in terminal, and first-class support for PHP and JavaScript.

Go to the [official Visual Studio Code website](https://code.visualstudio.com/) and click the **Download** button for Windows.

![download visual studio code](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/01-download.png)

Wait for the download to complete before moving on.

### Installation Process {#installation-process}

Once the installer file `VSCodeUserSetup-x64-1.82.2` has been downloaded, double-click it to begin the installation.

1. On the first page, you will be asked to accept the **License Agreement**. Select **I accept the agreement** and click **Next**.

    ![start install](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/03-%20setup.png)

2. Choose the directory where you want to install VS Code. The default location is `C:\Program Files\Microsoft VS Code`. You can keep the default or customize it to your preference. Click **Next**.

    ![setup directory vscode](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/04-setup%20direktori.png)

3. On the **Select Additional Tasks** page, check the **Create a desktop icon** option if you want a shortcut on your desktop. Then click **Next**.

    ![select additional task](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/06%20-%20select%20additional%20task.png)

4. On the **Ready to Install** page, click **Install** and wait for the process to finish.

    ![ready to install](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/07%20-%20ready%20to%20install.png)

Once the installation is complete, click **Finish** to close the installer.

![finish install visual studio code](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/vscode/09%20-%20finish.png)

### Running Visual Studio Code {#running-visual-studio-code}

After installation, you can open VS Code from the desktop icon or through the Windows Start menu. Take a moment to familiarize yourself with the interface. We will be spending a lot of time here throughout this course.



## Step 2: Install Laragon {#step-2-install-laragon}

### Download Laragon {#download-laragon}

Laragon is an all-in-one local development environment for Windows. It bundles Apache/Nginx, MySQL, PHP, Node.js, and Composer into a single, lightweight package. Unlike heavier alternatives like XAMPP or WAMP, Laragon is fast to start, easy to configure, and designed with modern PHP development in mind.

You can download Laragon from the [official Laragon website](https://laragon.org/index.html). Click the **Download** menu and select the **Laragon - Full** version.

![download laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/01-download.png)

**Important Note:**
- Since Laragon version 7 was released, the download page now serves Laragon version 7. Based on a [discussion in the Laragon repository](https://github.com/leokhoa/laragon/discussions/960), Laragon version 7 **is no longer free** and uses a **Paid Licensing model**.
- If you want to use the **free version of Laragon**, you can download it directly from GitHub: 
 
```
https://github.com/leokhoa/laragon/releases/download/6.0.0/laragon-wamp.exe
```

### Laragon Installation Process {#laragon-installation-process}

Once the `laragon-wamp.exe` file has been downloaded, double-click it to start the installation. Follow these steps:

1. Select the installation language (for example, **English**), then click **Next**.

    ![select language](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/02-pilih-bahasa.png)

2. Choose the installation directory for Laragon. The default is `C:\Laragon`. Click **Next** to continue.

    ![select install location](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/03-pilih-lokasi-install.png)

3. You will see configuration options such as autostart when Windows starts and adding Notepad++ and terminal to Laragon. Choose the options that suit your preference, then click **Next**.

    ![configure laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/04-atur-konfigurasi-laragon.png)

4. On the **Ready to Install** page, click **Install** to begin the Laragon installation process.

    ![ready install](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/05-ready-install.png)

5. Wait for the installation to complete. After that, click **Finish** to close the installer and open Laragon.

    ![finish install laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/07-selesai-install.png)

### Running Laragon {#running-laragon}

After Laragon opens, you will see its intuitive and user-friendly interface.

![laragon main screen](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/08-tampilan-laragon.png)

To start services like Apache and MySQL, simply click **Start All**. Laragon will launch all the services needed for web application development, including Apache, MySQL, and PHP.

### Opening a Project Folder in Visual Studio Code {#opening-a-project-folder-in-visual-studio-code}

Now that both VS Code and Laragon are installed, the next step is to connect them so you can work smoothly in a single development environment. Here is a simple way to open a project directory in Visual Studio Code:

1. Open Laragon and click **Root**. This will open the `root` directory where your projects live, which is `C:\laragon\www`. For now, create a new directory called `sample-app` inside it. In real projects later, we will use Composer commands to scaffold Laravel, CodeIgniter, or other PHP framework projects directly.
2. Open Visual Studio Code, click **File > Open Folder**, and select the folder you just created in the Laragon root directory: `C:\laragon\www\sample-app`.



## Step 3: Initial Configuration {#step-3-initial-configuration}

Before we can use commands like `php`, `node`, and `composer` from any terminal window, we need to add Laragon to the system's environment PATH. This step ensures that Windows knows where to find these tools regardless of which terminal you open.

First, open Laragon, then right-click or click the **Menu** button to open the Laragon menu.

![open laragon menu](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/09%20menu%20laragon.png)

Next, add Laragon to the system PATH by clicking **Tools** > **Path** > **Add Laragon to Path**.

![add laragon to path](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/10%20set%20environment%20variable.png)

Now let us verify that Laragon has been added to the PATH successfully. Open a terminal by clicking the **Terminal** button in the Laragon interface.

![open terminal](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/11%20akses%20terminal%20via%20laragon.png)

Once the terminal is open, run the following command to check the installed PHP version:

```bash
php -v
```

You should see output showing the PHP version installed in Laragon:

![check php version](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/12%20check%20php.png)

As shown in the image above, the installed PHP version is PHP 8.1.

Next, check the Node.js version by running:

```bash
node -v
```

![check nodejs version](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/13%20check%20node%20js.png)

The output shows that the Node.js version installed in Laragon is 18.8.0.

Finally, verify that Composer is working by running:

```bash
composer
```

![test composer command](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/14%20check%20composer.png)

You should see the Composer help output, confirming that Composer is ready to use.



## Step 4: Upgrade PHP to 8.3 {#step-4-upgrade-php-to-83}

Laravel 13 requires PHP 8.3 or higher. The default Laragon installation comes with PHP 8.1, so we need to upgrade. This process involves downloading a newer PHP build and telling Laragon to use it.

### Download PHP 8.3 {#download-php-83}

1. Go to the official PHP downloads page for Windows: <a href="https://www.php.net/downloads.php?os=windows&version=8.3" target="_blank">https://www.php.net/downloads.php?os=windows&version=8.3</a>.
2. Download the latest **PHP 8.3 x64 Non Thread Safe (NTS)** ZIP build.

   ![download php 8.3](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/1%20download%20php%208.2.png)

The exact patch version may be different by the time you read this lesson. That is fine. As long as the file starts with `php-8.3` and uses the x64 NTS build, it is suitable for this course.

We are downloading the NTS (Non Thread Safe) version because Laragon uses it by default. The NTS build is optimized for single-threaded environments like Nginx with PHP-FPM, which is the setup we will configure next.

### Extract the PHP Files to Laragon {#extract-the-php-files-to-laragon}

Once the download is complete, follow these steps:

1. Move the downloaded `php-8.3.x-nts-Win32-vs16-x64.zip` file to `C:\laragon\bin\php`.

   ![move zip file to laragon php directory](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/2%20pindahkan%20ke%20direktori%20php%20di%20laragon.png)

2. Right-click the ZIP file and select **Extract All**. Click the **Extract** button to begin the extraction process. When it finishes, you will see a new folder with a name similar to `php-8.3.x-nts-Win32-vs16-x64`.

   ![extract all](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/3%20Extract%20all.png)

   ![extracted folder](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/4%20folder%20hasil%20extract.png)

### Select PHP 8.3 in Laragon {#select-php-83-in-laragon}

1. Open Laragon.
2. Go to **Menu** > **PHP** > **Version** > your extracted PHP 8.3 folder, such as `php-8.3.x-nts-Win32-vs16-x64`, to activate PHP 8.3 as the primary PHP version.

   ![switch php version](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/5%20switch%20php%20version.png)

This tells Laragon to use the new PHP 8.3 build for both the web server and the CLI. No restart is needed; Laragon picks up the change immediately.

### Configure Nginx as the Web Server {#configure-nginx-as-the-web-server}

For better performance and compatibility with modern PHP applications, we will switch from Apache to Nginx:

1. In Laragon, open the **Preferences** menu.

   ![click preferences menu](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/6%20klik%20menu%20preferences.png)

2. Go to the **Services & Ports** tab. Uncheck **Apache** and enable **Nginx** by checking its checkbox. Set the Nginx port to **80**.

   ![enable nginx](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/7%20enable%20nginx.png)

3. Go back to the main Laragon interface and click **Start All** to launch Nginx and the other services.

   ![start all services](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/8%20start%20all%20services.png)



## Step 5: Verify the PHP 8.3 Installation {#step-5-verify-the-php-83-installation}

After configuring everything, we need to confirm that PHP 8.3 is properly set up and recognized by both the web server and the command line.

### Verify PHP in the Browser {#verify-php-in-the-browser}

1. In Laragon, click the **Web** button to open `localhost` in your browser.

   ![open localhost in browser](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/9%20buka%20localhost%20di%20browser.png)

2. The localhost page should display a PHP 8.3 version, such as `PHP version: 8.3.x`, confirming that the web server is using the correct PHP version.

   ![localhost page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/10%20halaman%20localhost.png)

3. Click the **info** link on the localhost page to view the full PHP configuration through `phpinfo()`.

   ![phpinfo page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/12%20halaman%20info%20menampilkan%20php%20versi%208.3.png)

### Verify PHP in the CLI {#verify-php-in-the-cli}

1. Go back to Laragon and click **Terminal** to open Cmder or the built-in terminal.

   ![click terminal in laragon](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/13%20klik%20menu%20terminal%20di%20ui%20laragon.png)

2. Run the following command to check the PHP version in the CLI:

   ```bash
   php -v
   ```

   The output should show the updated PHP version. It will look similar to this:

   ```bash
   PHP 8.3.x (cli) (built: ...) (NTS Visual C++ 2019 x64)
   ```

   ![check php version in cmder](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/how-to/install-tools/laragon/update-php-version/14%20cek%20versi%20php%20di%20cmder%20-%202.png)

Both the browser and the CLI now confirm that PHP 8.3 is active. We are ready to create our Laravel project.



## Step 6: Create the Catatku Project {#step-6-create-the-catatku-project}

With the development environment ready, create the CodeIgniter 4 project. Open the Laragon terminal and navigate to the web root:

```bash
cd C:\laragon\www
```

Run the following command:

```bash
composer create-project codeigniter4/appstarter catatku
```

This command tells Composer to download CodeIgniter 4 and set up the entire project structure inside a folder called `catatku`. The process requires an internet connection and may take a few minutes.

Once the installation finishes, navigate into the project directory and open it in VS Code:

```bash
cd catatku
code .
```

---

## Step 7: Configure the Environment {#step-7-configure-the-environment}

CodeIgniter 4 ships with an `env` file (without the dot prefix) in the project root. We need to rename it and configure it for development.

1. In VS Code, find the file named `env` in the project root.
2. Copy the `env` file and rename the copy to `.env`.
3. Open `.env` and find the line `# CI_ENVIRONMENT = production`. Change it to:

```
CI_ENVIRONMENT = development
```

This enables detailed error messages during development. In production, you would leave this as `production` to hide error details from users.

---

## Step 8: Run the Development Server {#step-8-run-the-development-server}

CodeIgniter provides a built-in development server through Spark, its command-line tool. From inside the `catatku` folder, run:

```bash
php spark serve
```

Output:

```
CodeIgniter v4.x.x Command Line Tool - Server Time: 2026-02-20 10:00:00 UTC+07:00

CodeIgniter development server started on http://localhost:8080
Press Control-C to stop.
```

Open your browser and go to `http://localhost:8080`. You will see the CodeIgniter welcome page, confirming that the project is set up correctly.

> **Tip**: Keep this terminal running during development. Open a new terminal for other Spark commands.

---

## Understanding the CodeIgniter Folder Structure {#understanding-the-codeigniter-folder-structure}

When the project opens in VS Code, you will see many folders and files. Here are the ones we will use most frequently:

```
catatku/
├── app/
│   ├── Config/
│   │   └── Routes.php          ← All application routes
│   ├── Controllers/             ← Where controllers live
│   ├── Database/
│   │   └── Migrations/         ← Database table definitions
│   ├── Filters/                 ← Middleware-like route protection
│   ├── Models/                  ← Where models live
│   └── Views/                   ← PHP template files (HTML)
├── public/
│   └── index.php               ← Application entry point
├── .env                         ← Environment configuration
└── spark                        ← CodeIgniter's CLI tool
```

**`app/Controllers/`** is where your application logic lives. Controllers receive requests, process data, and decide what response to send back.

**`app/Models/`** contains PHP classes that interact with the database. Each model corresponds to a database table.

**`app/Database/Migrations/`** contains PHP files that define table structures programmatically, so database changes can be tracked and replicated consistently.

**`app/Views/`** is where all template files live. CodeIgniter uses plain PHP files for views, enhanced with a layout system for reusability.

**`app/Config/Routes.php`** is the "map" of your application. Every URL is defined here and connected to the appropriate controller.

**`app/Filters/`** contains filter classes that act like middleware, running before or after controller methods to check authentication, permissions, etc.

**`.env`** stores environment-specific configuration such as database credentials. This file should not be committed to Git.

---

## Getting to Know Spark {#getting-to-know-spark}

Spark is CodeIgniter's built-in command-line interface, similar to Laravel's Artisan. Here is a quick overview of the commands we will encounter:

```bash
php spark serve                  # Start the development server
php spark make:controller        # Create a new controller
php spark make:model             # Create a new model
php spark make:migration         # Create a new migration file
php spark migrate                # Run all pending migrations
php spark routes                 # Display all registered routes
php spark db:seed                   # Run a database seeder
```

You do not need to memorize these now. Each command will be reintroduced when we need it.

---

## Conclusion {#conclusion}

In this lesson, you built a complete local development environment from scratch and created your first CodeIgniter 4 project. Here are the key takeaways:

- **Visual Studio Code** is your code editor with an integrated terminal and a rich extension ecosystem for PHP development.
- **Laragon** bundles everything you need for local PHP development: a web server, MySQL, PHP, and Composer.
- **PHP 8.3** is recommended for CodeIgniter 4. You can upgrade PHP in Laragon by downloading a new build and selecting it in the menu.
- The `composer create-project codeigniter4/appstarter catatku` command scaffolds a complete CodeIgniter project.
- Rename the `env` file to `.env` and set `CI_ENVIRONMENT = development` to enable detailed error messages.
- The **CodeIgniter folder structure** follows clear conventions: `Controllers/` for logic, `Models/` for data, `Migrations/` for database schemas, `Views/` for templates, and `Routes.php` for URL mapping.
- **Spark** is CodeIgniter's CLI tool for generating files, running migrations, starting the dev server, and more.

In the next lesson, we will create our first routes and views, and you will see your own content appear in the browser for the first time.