---
title: "Laravel 13 Filament 5 CRUD Tutorial: Build a Blog Admin Panel Step by Step"
slug: "laravel-13-filament-5-crud-tutorial-build-a-blog-admin-panel-step-by-step"
category: "Laravel"
date: "2026-03-24"
status: "published"
---

Building an admin panel from scratch takes a lot of time. You need to create forms, tables, pagination, filters, validation, and file uploads before you can even start working on your actual business logic. For many projects, that effort is hard to justify when the admin panel is not the core product.

Filament solves this problem. It is a full-featured admin panel framework for Laravel that generates beautiful, functional CRUD interfaces with minimal code. And with Filament 5, the developer experience has improved significantly, including a cleaner file structure and auto-generated form and table schemas.

We previously published a [Filament tutorial](https://qadrlabs.com/post/panduan-lengkap-laravel-filament-untuk-pemula-studi-kasus-crud-product) using Filament 3. However, since Filament 5 introduces structural changes in how resources are generated, the command outputs and file organization are different. This tutorial is a fresh walkthrough using Filament 5 on Laravel 13.


## Overview {#overview}

In this tutorial, we will build a blog admin panel using Laravel 13 and Filament 5. The admin panel will allow you to manage blog posts with full CRUD functionality, including image uploads and automatic slug generation.

![app preview](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-filament-5/00-app-preview.webp)

### What You'll Build

A complete admin panel with the following features:

- An admin login page with authentication.
- A post listing table with pagination and bulk actions.
- A create form with title, slug (auto-generated), content, image upload, and status fields.
- A detail view page to inspect a single post.
- An edit form to update existing posts.
- A delete function with confirmation, including bulk delete support.

### What You'll Learn

By following this tutorial, you will learn how to:

- Set up a new Laravel 13 project and configure the database.
- Create models and migrations using Artisan commands.
- Install and configure Filament 5 with the panels builder.
- Create an admin user for the Filament dashboard.
- Generate CRUD resources with auto-generated form, table, and infolist schemas.
- Customize form behavior, including auto slug generation and unique validation.
- Link public storage for image uploads.

### What You'll Need

Before getting started, make sure you have:

- PHP 8.3 or higher
- Composer installed globally
- MySQL (or another supported database)
- Node.js and NPM (required by Filament's asset compilation)
- A code editor (Visual Studio Code recommended)
- Basic familiarity with Laravel


## Step 1: Create a Laravel Project {#step-1-create-laravel-project}

Start by creating a fresh Laravel project. We will name it `filament_blog`:

```
composer create-project laravel/laravel --prefer-dist filament_blog
```

```
$ composer create-project laravel/laravel --prefer-dist filament_blog
Creating a "laravel/laravel" project at "./filament_blog"
Installing laravel/laravel (v13.1.0)
  - Installing laravel/laravel (v13.1.0): Extracting archive

.
.
.
```

Wait for Composer to finish downloading and installing all dependencies. The output confirms that Laravel v13.1.0 is being installed.

Once complete, navigate into the project directory:

```
cd filament_blog
```

If you are using Visual Studio Code, you can open the project directly from the terminal:

```
code .
```


## Step 2: Set Up Database Configuration {#step-2-setup-database-configuration}

Before we can store any data, we need to configure the database connection. Open the `.env` file in your project root and update the database settings:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_filament_blog
DB_USERNAME=root
DB_PASSWORD=password
```

**Note:** Adjust the `DB_USERNAME` and `DB_PASSWORD` values to match your local MySQL credentials. You do not need to create the database manually, as Laravel will offer to create it when you run the migration command later.

Save the `.env` file.


## Step 3: Create Model and Migration {#step-3-create-model-and-migration}

Use the Artisan command to generate both the `Post` model and its migration file at once:

```
php artisan make:model Post -m
```

```
$ php artisan make:model Post -m

   INFO  Model [app/Models/Post.php] created successfully.  

   INFO  Migration [database/migrations/2026_03_24_004811_create_posts_table.php] created successfully.  

```

The `-m` flag tells Artisan to create a migration alongside the model, saving you from running two separate commands.

### Define the Database Schema

Open the generated migration file at `database/migrations/xxxx_xx_xx_xxxxxx_create_posts_table.php` and replace its content with:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('posts', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('slug')->unique();
            $table->text('content');
            $table->string('image');
            $table->enum('status', ['draft', 'publish'])->default('draft');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('posts');
    }
};
```

This schema defines the following columns:

- `id()` creates an auto-incrementing primary key.
- `string('title')` stores the post title.
- `string('slug')->unique()` stores a URL-friendly version of the title with a uniqueness constraint.
- `text('content')` stores the post body.
- `string('image')` stores the file path of the uploaded image.
- `enum('status', ['draft', 'publish'])->default('draft')` restricts the status to two values and defaults to "draft."
- `timestamps()` adds `created_at` and `updated_at` columns managed automatically by Laravel.

Save the migration file.

### Configure the Model

Open `app/Models/Post.php` and replace its content with:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable(['title', 'slug', 'content', 'status', 'image'])]
class Post extends Model
{
    use HasFactory;
}
```

The `#[Fillable]` attribute is a Laravel 13 feature that uses PHP's native attribute syntax to declare mass-assignable fields. In earlier versions, you would define a `$fillable` array property inside the class. The attribute approach is more declarative and keeps the configuration colocated with the class definition. Notice that `image` is included in the list since Filament will handle file uploads and store the path in this column.

Save the model file.

### Run the Migration

Execute the migration to create the `posts` table:

```
php artisan migrate
```

```
$ php artisan migrate

   WARN  The database 'db_filament_blog' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘

```

Since the database does not exist yet, Laravel asks if you want to create it. Select **Yes** and press Enter. Laravel will create the database and run all pending migrations.


## Step 4: Install Filament {#step-4-install-filament}

Now let's add Filament 5 to the project. Run the following Composer command to install the package:

```
composer require filament/filament:"^5.0"
```

The `"^5.0"` constraint tells Composer to install the latest Filament 5.x release. Once the package is downloaded, run the panels installation command:

```
php artisan filament:install --panels
```

```
$ php artisan filament:install --panels

 ┌ What is the panel's ID? ─────────────────────────────────────┐
 │ admin                                                        │
 └──────────────────────────────────────────────────────────────┘
  It must be unique to any others you have, and is used to reference the pa…

```

Enter `admin` as the panel ID and press Enter to continue. The panel ID determines the URL prefix for your admin panel (e.g., `/admin`).

```
$ php artisan filament:install --panels

 ┌ What is the panel's ID? ─────────────────────────────────────┐
 │ admin                                                        │
 └──────────────────────────────────────────────────────────────┘

   INFO  Filament panel [app/Providers/Filament/AdminPanelProvider.php] created successfully.  

   WARN  We've attempted to register the AdminPanelProvider in your [bootstrap/providers.php] file. If you get an error while trying to access your panel then this process has probably failed. You can manually register the service provider by adding it to the array.  
.
.
.
```

Wait for the process to complete. Filament creates a panel provider at `app/Providers/Filament/AdminPanelProvider.php` and attempts to register it automatically. If you encounter issues accessing the panel later, you may need to manually add the provider to `bootstrap/providers.php`.


## Step 5: Create an Admin User {#step-5-create-admin-user}

Filament requires an authenticated user to access the admin panel. Run the following command to create one:

```
php artisan make:filament-user
```

Fill in the name, email, and password when prompted:

```
$ php artisan make:filament-user

 ┌ Name ────────────────────────────────────────────────────────┐
 │ Admin                                                        │
 └──────────────────────────────────────────────────────────────┘

 ┌ Email address ───────────────────────────────────────────────┐
 │ admin@qadrlabs.com                                           │
 └──────────────────────────────────────────────────────────────┘

 ┌ Password ────────────────────────────────────────────────────┐
 │ ••••••••                                                     │
 └──────────────────────────────────────────────────────────────┘

   INFO  Success! admin@qadrlabs.com may now log in at http://localhost/admin/login.  

```

The command inserts a new user record into the `users` table with the credentials you provided.

To verify that everything works, start the development server:

```
php artisan serve
```

Open your browser and navigate to `http://127.0.0.1:8000/admin/login`.
![test login](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-filament-5/01-login.webp)

Enter the email and password you just created. After a successful login, you should see the Filament dashboard.
![access filament dashboard](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-filament-5/02-access-dashboard.webp)

## Step 6: Generate CRUD Resources {#step-6-generate-crud-resources}

This is where Filament really shines. Instead of manually building controllers, views, forms, and tables, Filament can generate all of them from your model with a single command:

```
php artisan make:filament-resource Post --generate --view
```

```
$ php artisan make:filament-resource Post --generate --view

 The "title attribute" is used to label each record in the UI.

 You can leave this blank if records do not have a title.

 ┌ What is the title attribute for this model? ─────────────────┐
 │                                                              │
 └──────────────────────────────────────────────────────────────┘

   INFO  Filament resource [App\Filament\Resources\Posts\PostResource] created successfully.  

```

Here is what each flag does:

- `--generate` tells Filament to inspect the `Post` model's database columns and automatically create form fields and table columns that match your schema.
- `--view` adds a dedicated view page (read-only detail page) in addition to the standard list, create, and edit pages.

### Understanding the Generated File Structure

Filament 5 generates a well-organized set of files. This is one of the structural changes compared to earlier versions:

```
app/Filament/Resources/Posts/PostResource.php

app/Filament/Resources/Posts/Pages/CreatePost.php
app/Filament/Resources/Posts/Pages/EditPost.php
app/Filament/Resources/Posts/Pages/ListPosts.php
app/Filament/Resources/Posts/Pages/ViewPost.php

app/Filament/Resources/Posts/Schemas/PostForm.php
app/Filament/Resources/Posts/Schemas/PostInfolist.php

app/Filament/Resources/Posts/Tables/PostsTable.php
```

In previous versions of Filament, you had to define form and table schemas directly inside the resource class. In Filament 5, these are separated into dedicated files under `Schemas/` and `Tables/` directories. This keeps each file focused on a single responsibility and makes larger resources much easier to maintain.

The `PostForm.php` file defines the create and edit form fields. The `PostInfolist.php` file defines the read-only view layout. The `PostsTable.php` file defines the table columns, filters, and actions for the listing page.

### Create the Storage Symlink

Since our posts include image uploads, we need to link the `storage` directory to the `public` directory so uploaded files are accessible from the browser:

```
php artisan storage:link
```

```
$ php artisan storage:link

   INFO  The [public/storage] link has been connected to [storage/app/public]. 
```

This creates a symbolic link from `public/storage` to `storage/app/public`. Without this step, uploaded images would not be accessible via URL.


## Step 7: Add Auto Slug Generation {#step-7-auto-slug-generation}

By default, the generated form requires you to manually type the slug. Let's improve this by making the slug auto-generate from the title as the user types.

Open `app/Filament/Resources/Posts/Schemas/PostForm.php` and replace its content with:

```php
<?php

namespace App\Filament\Resources\Posts\Schemas;

use App\Models\Post;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Schemas\Components\Utilities\Get;
use Filament\Schemas\Components\Utilities\Set;
use Filament\Forms\Components\TextInput;
use Illuminate\Support\Str;
use Filament\Forms\Components\Textarea;
use Filament\Schemas\Schema;

class PostForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('title')
                    ->required()
                    ->live(onBlur: true)
                    ->afterStateUpdated(function (Get $get, Set $set, ?string $old, ?string $state) {
                        if (($get('slug') ?? '') !== Str::slug($old)) {
                            return;
                        }

                        $set('slug', Str::slug($state));
                    }),
                TextInput::make('slug')
                    ->required()
                    ->maxLength(255)
                    ->unique(Post::class, 'slug', fn ($record) => $record)
                    ->disabled(fn (?string $operation, ?Post $record) => $operation == 'edit'),
                Textarea::make('content')
                    ->required()
                    ->columnSpanFull(),
                FileUpload::make('image')
                    ->image()
                    ->required(),
                Select::make('status')
                    ->options(['draft' => 'Draft', 'publish' => 'Publish'])
                    ->default('draft')
                    ->required(),
            ]);
    }
}
```

Let's break down the key changes to the `title` and `slug` fields:

**Title field:**

- `->live(onBlur: true)` makes the field reactive. Every time the user leaves the title field (on blur), Filament triggers the callback.
- `->afterStateUpdated(...)` runs after the title value changes. Inside the callback, it first checks if the current slug still matches the previous title's slug. If the user has manually edited the slug to something custom, the auto-generation is skipped. Otherwise, it generates a new slug from the updated title using `Str::slug()`.

**Slug field:**

- `->unique(Post::class, 'slug', fn ($record) => $record)` adds a unique validation rule. The third parameter `fn ($record) => $record` excludes the current record during updates, so editing a post without changing its title does not trigger a "slug already taken" error.
- `->disabled(fn (?string $operation, ?Post $record) => $operation == 'edit')` disables the slug field on the edit form. This prevents accidental slug changes that could break existing URLs. On the create form, the field remains enabled so users can review or adjust the auto-generated slug before saving.

Save the file.


## Step 8: Test the Application {#step-8-test-the-application}

With everything in place, start the development server:

```
php artisan serve
```

Open your browser and navigate to `http://127.0.0.1:8000/admin`. Log in with the admin credentials you created in Step 5. You should see "Posts" in the sidebar navigation. Click **Posts** in the sidebar, to view manage posts page.

![Manage post page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-filament-5/03-view-post-list.webp)

### Test Creating a Post

 Click **New Post**. Fill in the title field and notice how the slug is automatically generated as you type. Add some content, upload an image, select a status, and click **Create**. You should be redirected to view detail post page.
 
 ![test create new post](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-filament-5/04-test-create-new-post.webp)
 
 ![post created](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-filament-5/05-post-created.webp)
 
  When we access the post list page, we can see that a new post is displayed in the post list table.
	![new post at post list page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-filament-5/10-post-list.webp)

### Test Viewing a Post

Click the **View** action (eye icon) on any post in the table. You should see a read-only detail page showing all the post fields, including the uploaded image.
![view post detail page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-filament-5/06-view-post-detail.webp)

### Test Editing a Post

Click the **Edit** action (pencil icon) on any post. The form should be pre-filled with the current data. Notice that the slug field is disabled to prevent accidental changes. 
![view edit post page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-filament-5/07-view-edit-post-form.webp)

Modify the title or content and click **Save**. 
![test edit post](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-filament-5/08-test-edit-post.webp)

The changes should be reflected in the table and detail post page.
![post updated](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-filament-5/09-post-updated.webp)

### Test Deleting a Post

To delete a single post, click the delete action on the row. To delete multiple posts at once, select the checkboxes next to each post you want to remove, click the **Bulk actions** dropdown, select **Delete selected**, and confirm the deletion in the popup dialog.
![test delete post](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-filament-5/11-test-delete-post.webp)

![pop up dialog to confirm](https://github.com/gungunpriatna/tes-repositori/blob/master/laravel/laravel-13/crud-filament-5/12-confirm-delete-post.webp)

![post deleted](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-filament-5/13-post-deleted.webp)

## Conclusion {#conclusion}

In this tutorial, we built a fully functional blog admin panel using Laravel 13 and Filament 5. Starting from a fresh project, we set up the database, created a model with the `#[Fillable]` attribute, installed Filament, generated CRUD resources, and customized the form with auto slug generation.

Here are the key takeaways:

- **Filament 5 generates more than before.** The `make:filament-resource --generate --view` command creates dedicated files for forms, tables, and infolists. You no longer need to define everything inside a single resource class.
- **The file structure is cleaner.** Schemas, tables, and pages are separated into their own directories (`Schemas/`, `Tables/`, `Pages/`), making each file easier to read and maintain.
- **Auto slug generation requires minimal code.** By combining `live(onBlur: true)` and `afterStateUpdated()`, you can build reactive form behavior with just a few lines.
- **The `#[Fillable]` attribute works seamlessly with Filament.** Laravel 13's new attribute syntax for mass assignment integrates naturally with Filament's form handling and `create()`/`update()` calls.
- **Image uploads work out of the box.** Filament's `FileUpload` component handles file storage automatically. Just make sure to run `php artisan storage:link` so uploaded files are publicly accessible.
- **Bulk actions come for free.** The generated table includes checkbox selection and bulk delete without any additional configuration.

Compared to our previous Filament 3 tutorial, the upgrade to Filament 5 brings a noticeably improved developer experience with better code organization and more auto-generated boilerplate. If you have been using an older version, the migration is worth considering.