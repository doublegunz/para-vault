## 1. Before You Begin

CodeIgniter 3 does not use Composer (unlike Laravel or CI4). You download a ZIP file, extract it, and it works. This simplicity is one of CI3's strengths: no dependency manager, no CLI setup, no configuration wizard.

### What You'll Build

You will install CI3, configure the base URL, understand the folder structure, and see the welcome page.

### What You'll Learn

- ✅ How to download and install CodeIgniter 3
- ✅ The folder structure: application, system, assets
- ✅ Configuring `base_url` in config.php
- ✅ Removing `index.php` from URLs with .htaccess
- ✅ Running CI3 with Laragon

### What You'll Need

- Laragon installed (or XAMPP/MAMP with Apache and MySQL)
- VS Code

---

## 2. Download and Install

We will download CodeIgniter 3 directly from the official repository or website and extract it into our local development environment.

### Step 1: Download CodeIgniter 3

Go to [codeigniter.com/download](https://codeigniter.com/download) and download CodeIgniter 3.x (not CI4). Make sure you are downloading the version 3.x release and not the CI4 branch, as the two frameworks have significantly different structures. Alternatively, you can download directly from GitHub using this URL: `https://codeload.github.com/bcit-ci/CodeIgniter/zip/3.1.13`.

### Step 2: Extract to Web Root

Once the ZIP file is downloaded, extract it into your local web server's root directory. The folder name will become the URL segment you use to access the project in your browser.

**Laragon:** `C:\laragon\www\ci3-blog`

**XAMPP:** `C:\xampp\htdocs\ci3-blog`

By extracting the folder as `ci3-blog`, your application will be accessible at `http://localhost/ci3-blog`.

### Step 3: Verify the Installation

Start Laragon by clicking **Start All**. Then open your browser and visit `http://localhost/ci3-blog`.

If the installation was successful, you should see the CodeIgniter welcome page: "Welcome to CodeIgniter!" This confirms that CI3 is correctly installed and Apache can serve the project.

---

## 3. Project Structure

Here is the standard directory structure of a CodeIgniter 3 project. Understanding what each folder does is crucial for organizing your application.

```text
ci3-blog/
    application/
        config/
            config.php
            database.php
            routes.php
            autoload.php
        controllers/
        models/
        views/
        helpers/
        libraries/
    system/
    index.php
    .htaccess
```

- **`application/`**: Where your custom code (Controllers, Models, Views) goes.
- **`application/config/`**: Contains configuration files such as `config.php` (Base URL, encryption key), `database.php` (Database credentials), `routes.php` (URL routing rules), and `autoload.php` (Auto-loaded libraries and helpers).
- **`system/`**: The core of CodeIgniter 3. This folder contains the framework's own libraries and classes. You should never edit anything inside it — doing so will break your application when you try to upgrade CI3 in the future.
- **`index.php`**: The single entry point for the entire application. Every web request passes through this file first.
- **`.htaccess`**: Used for URL rewriting. We will configure this shortly to remove `index.php` from all URLs.

**Rule:** Only edit files inside `application/`. Never touch `system/`.

---

## 4. Configure Base URL

The base URL tells CodeIgniter what the root address of your application is. Without this, helpers like `site_url()` and `base_url()` will not generate correct links.

### Step 1: Open config.php

Open `application/config/config.php` in VS Code. This is the main configuration file for the entire CI3 application.

### Step 2: Set base_url

Locate the `$config['base_url']` line and update it to match your local address.

```php
$config['base_url'] = 'http://localhost/ci3-blog/';
```

This tells CI3 that the root of the application is `http://localhost/ci3-blog/`. Notice the trailing slash — it is required. Without it, generated URLs will be incorrect and links will break.

### Step 3: Save the File

Press **Ctrl+S** to save the file. CI3 reads this configuration on every request, so no server restart is necessary.

---

## 5. Remove index.php from URLs

By default, CI3 URLs include `index.php` in the path, like this: `http://localhost/ci3-blog/index.php/controller/method`. This makes URLs look cluttered and is not SEO-friendly. We can remove it using Apache's URL rewriting feature.

### Step 1: Create .htaccess

Create a file named `.htaccess` in the project root directory (`ci3-blog/`). This file instructs Apache to redirect all requests through `index.php` without requiring it to appear in the URL.

```apache
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php/$1 [L]
```

Here is what each directive does:

- `RewriteEngine On` activates Apache's URL rewriting module for this directory.
- `RewriteCond %{REQUEST_FILENAME} !-f` means: only rewrite if the request is NOT a real file. This ensures that requests for actual files like CSS, images, or JavaScript are never intercepted.
- `RewriteCond %{REQUEST_FILENAME} !-d` means: only rewrite if the request is NOT a real directory.
- `RewriteRule ^(.*)$ index.php/$1 [L]` captures the full URL path and passes it to `index.php` as a parameter. The `[L]` flag tells Apache to stop processing further rewrite rules.

### Step 2: Update config.php

Now tell CI3 that `index.php` no longer needs to appear in generated URLs. Open `application/config/config.php` and find the `index_page` setting.

```php
$config['index_page'] = '';
```

By changing this to an empty string, CI3 will stop appending `index.php` to every URL it generates internally.

### Step 3: Test

Visit `http://localhost/ci3-blog/` - the welcome page should load without `index.php` appearing in the URL. If it does not work, verify that Apache's `mod_rewrite` module is enabled.

---

## 6. Configure Autoload

CodeIgniter lets you specify libraries and helpers that should be loaded automatically on every single request, so you do not have to load them manually inside each controller. Open `application/config/autoload.php` and update it as follows.

```php
$autoload['libraries'] = array('session');
$autoload['helper'] = array('url', 'form');
```

Here is what each entry provides:

- **`'session'`**: Loads CI3's session library, making `$this->session` available for storing and reading session data (used for flash messages and authentication).
- **`'url'`**: Loads the URL helper, which provides the `base_url()` and `site_url()` functions for generating links.
- **`'form'`**: Loads the form helper, which provides `form_open()`, `form_close()`, and other HTML form generation functions.

We will add the database library later in Lesson 5, after the database itself and `database.php` are configured. Loading it before that point can make every page show a database connection error.

---

## 7. Fix the Errors in Your Code

If you encounter issues during setup, here are some common errors and how to fix them.

**Error 1: Trailing slash.**
The `base_url` must end with a trailing slash.

```php
$config['base_url'] = 'http://localhost/ci3-blog/';
```

If the trailing slash is missing, CI3's `site_url()` helper will generate broken double-slash links like `http://localhost/ci3-blogposts` instead of `http://localhost/ci3-blog/posts`.

**Error 2: mod_rewrite.**
Ensure Apache has `mod_rewrite` enabled and `AllowOverride All` is set. In Laragon, Apache `mod_rewrite` is enabled by default. In XAMPP, enable it in `httpd.conf` by uncommenting `LoadModule rewrite_module modules/mod_rewrite.so`.

**Error 3: Session save path.**
On some PHP installations, especially custom local runtimes, the default session save path may be empty. If CI3 shows a warning such as `mkdir(): Invalid path` when the session library starts, create a writable session folder and point CI3 to it.

```php
$config['sess_save_path'] = APPPATH.'cache/sessions';
```

Then create the `application/cache/sessions/` folder. Laragon usually has a working PHP session path already, so only apply this fix if you see the warning.

---

## 8. Exercises

Complete the following exercises to test your understanding.

**Exercise 1:** Verify CI3 is installed by visiting `http://localhost/ci3-blog/`. Take note of the PHP version shown on the welcome page.

**Exercise 2:** Open `application/config/config.php`. Find and note the values of: `base_url`, `index_page`, `encryption_key`, `sess_driver`.

**Exercise 3:** Open `application/controllers/Welcome.php`. Read the code. Notice the class extends `CI_Controller` and the `index()` method loads a view.

---

## 9. Solutions

Here are the solutions to the exercises above.

**Solution for Exercise 1:** Open the URL. The welcome page shows PHP version and CI version.

**Solution for Exercise 2:** `base_url` = your configured URL, `index_page` = '' (after our change), `encryption_key` = empty (set it for production), `sess_driver` = 'files'.

**Solution for Exercise 3:** `Welcome.php` contains:

```php
class Welcome extends CI_Controller {
    public function index() {
        $this->load->view('welcome_message');
    }
}
```

This is the default controller that ships with CI3. The `index()` method is called when no method segment is present in the URL. `$this->load->view('welcome_message')` tells CI3 to find and render the file at `application/views/welcome_message.php`. The class extends `CI_Controller`, which gives it access to all of CI3's built-in features via `$this`, such as `$this->load`, `$this->db`, and `$this->session`.

---

## Next Up - Lesson 3

CodeIgniter 3 is installed by extracting a ZIP. The `application/` folder holds your code. `system/` holds the framework core (never edit). `config.php` sets the base URL. `.htaccess` removes `index.php` from URLs. `autoload.php` loads libraries and helpers automatically.

In Lesson 3, you will create your first controller and view.
