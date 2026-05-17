---
title: "Tutorial Lengkap CRUD Symfony: Membangun Sistem Manajemen Produk"
slug: "tutorial-lengkap-crud-symfony-membangun-sistem-manajemen-produk"
category: "Symfony"
date: "2025-06-09"
status: "published"
---

Symfony adalah salah satu framework PHP yang paling populer dan powerful untuk membangun aplikasi web modern. Framework ini menyediakan struktur yang solid dan tools yang lengkap untuk pengembangan aplikasi yang scalable dan maintainable. Bagi developer yang baru mengenal Symfony, seringkali muncul pertanyaan bagaimana cara membangun fitur CRUD (Create, Read, Update, Delete) yang merupakan operasi fundamental dalam aplikasi web. Oleh karena itu, pada tutorial ini kita akan belajar membangun sistem CRUD lengkap menggunakan Symfony.

## Overview{#overview}

Pada tutorial ini kita akan belajar membangun sistem manajemen produk menggunakan Symfony framework. Sebagai studi kasus, kita akan membuat aplikasi untuk mengelola data produk dengan fitur lengkap CRUD. Kita akan memulai dengan setup project Symfony baru, konfigurasi database, membuat entity dan migration, kemudian secara bertahap membangun setiap komponen sistem termasuk controller, form, template, dan styling. Di akhir tutorial ini, Anda akan memiliki aplikasi manajemen produk yang fungsional dengan interface yang user-friendly dan memahami konsep dasar pengembangan aplikasi web menggunakan Symfony framework.

## Step 1: Setup Project Symfony{#step-1-setup-project-symfony}

Pertama kita akan setup project Symfony baru untuk aplikasi manajemen produk kita.

Pastikan Anda sudah menginstall Symfony CLI. Jika belum, install terlebih dahulu dengan perintah:

```bash
curl -sS https://get.symfony.com/cli/installer | bash
```

Setelah Symfony CLI terinstall, buat project baru dengan perintah:

```bash
symfony new crud-symfony-app --webapp
```

Perintah di atas akan membuat project Symfony baru dengan nama `crud-symfony-app` menggunakan template `webapp` yang sudah include Doctrine ORM, Twig, form component, dan security component.

Output:

```bash
$ symfony new crud-symfony-app --webapp

 [OK] Your project is now ready in crud-symfony-app

 * Run cd crud-symfony-app && symfony serve
 * Read the documentation at https://symfony.com/doc
```

Selanjutnya masuk ke direktori project:

```bash
cd crud-symfony-app
```

Untuk memastikan semua dependency terinstall dengan benar, jalankan perintah:

```bash
composer install
```

## Step 2: Konfigurasi Database dan Environment{#step-2-konfigurasi-database-environment}

Selanjutnya kita akan konfigurasi database dan environment. Buka project di code editor, lalu buka file `.env`.

Pada file `.env`, cari baris konfigurasi database dan sesuaikan dengan konfigurasi database Anda:

```
# .env

APP_ENV=dev
APP_SECRET=your-secret-key

# Database Configuration
DATABASE_URL="mysql://root:password@127.0.0.1:3306/db_crud_symfony?serverVersion=8.0&charset=utf8mb4"
```

Sesuaikan username, password, host, port, dan nama database dengan konfigurasi database MySQL Anda.

Setelah konfigurasi database, jalankan perintah untuk membuat database:

```bash
php bin/console doctrine:database:create
```

Output:

```bash
$ php bin/console doctrine:database:create

 [OK] Created database `db_crud_symfony` for connection named default
```

## Step 3: Buat Entity dan Migration{#step-3-buat-entity-migration}

Sekarang kita akan membuat Entity Product untuk merepresentasikan data produk di database.

Jalankan perintah untuk membuat entity:

```bash
php bin/console make:entity Product
```

Symfony akan menanyakan properties yang ingin ditambahkan. Tambahkan properties berikut:

```bash
$ php bin/console make:entity Product

 created: src/Entity/Product.php
 created: src/Repository/ProductRepository.php

 Entity generated! Now let's add some fields!
 You can always add more fields later manually or by re-running this command.

 New property name (press <return> to stop adding fields):
 > name

 Field type (enter ? to see all types) [string]:
 > string

 Field length [255]:
 > 255

 Can this field be null in the database (nullable) [no]:
 > no

 New property name (press <return> to stop adding fields):
 > description

 Field type (enter ? to see all types) [string]:
 > text

 Can this field be null in the database (nullable) [no]:
 > yes

 New property name (press <return> to stop adding fields):
 > price

 Field type (enter ? to see all types) [string]:
 > decimal

 Precision (total number of digits stored: 100) [10]:
 > 10

 Scale (number of digits after the decimal point: 0) [2]:
 > 2

 Can this field be null in the database (nullable) [no]:
 > no

 New property name (press <return> to stop adding fields):
 > stock

 Field type (enter ? to see all types) [string]:
 > integer

 Can this field be null in the database (nullable) [no]:
 > no

 New property name (press <return> to stop adding fields):
 >

 [OK] Your entity is ready! Next: When you're ready, create a migration with php bin/console make:migration
```

Buka file `src/Entity/Product.php` untuk melihat entity yang telah dibuat:

```php
<?php

namespace App\Entity;

use App\Repository\ProductRepository;
use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: ProductRepository::class)]
class Product
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\Column(length: 255)]
    private ?string $name = null;

    #[ORM\Column(type: Types::TEXT, nullable: true)]
    private ?string $description = null;

    #[ORM\Column(type: Types::DECIMAL, precision: 10, scale: 2)]
    private ?string $price = null;

    #[ORM\Column]
    private ?int $stock = null;

    // Getter dan setter methods akan di-generate otomatis
    public function getId(): ?int
    {
        return $this->id;
    }

    public function getName(): ?string
    {
        return $this->name;
    }

    public function setName(string $name): static
    {
        $this->name = $name;
        return $this;
    }

    public function getDescription(): ?string
    {
        return $this->description;
    }

    public function setDescription(?string $description): static
    {
        $this->description = $description;
        return $this;
    }

    public function getPrice(): ?string
    {
        return $this->price;
    }

    public function setPrice(string $price): static
    {
        $this->price = $price;
        return $this;
    }

    public function getStock(): ?int
    {
        return $this->stock;
    }

    public function setStock(int $stock): static
    {
        $this->stock = $stock;
        return $this;
    }
}
```

Selanjutnya buat migration untuk membuat tabel di database:

```bash
php bin/console make:migration
```

Output:

```bash
$ php bin/console make:migration

 [OK] Migration generated: migrations/Version20250609000000.php
```

Jalankan migration untuk membuat tabel:

```bash
php bin/console doctrine:migrations:migrate
```

Output:

```bash
$ php bin/console doctrine:migrations:migrate

 [notice] Migrating up to Version20250609000000
 [notice] finished in 234.5ms, used 18M memory, 1 migration executed, 1 sql query
```

## Step 4: Buat Controller{#step-4-buat-controller}

Sekarang kita akan membuat controller untuk menangani operasi CRUD produk.

Jalankan perintah untuk membuat controller:

```bash
php bin/console make:controller ProductController
```

Output:

```bash
$ php bin/console make:controller ProductController

 created: src/Controller/ProductController.php
 created: templates/product/index.html.twig

 [OK] Your controller is ready!
```

Buka file `src/Controller/ProductController.php` dan modifikasi dengan kode berikut:

```php
<?php

namespace App\Controller;

use App\Entity\Product;
use App\Form\ProductType;
use App\Repository\ProductRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/product')]
class ProductController extends AbstractController
{
    #[Route('/', name: 'app_product_index', methods: ['GET'])]
    public function index(ProductRepository $productRepository): Response
    {
        return $this->render('product/index.html.twig', [
            'products' => $productRepository->findAll(),
        ]);
    }

    #[Route('/new', name: 'app_product_new', methods: ['GET', 'POST'])]
    public function new(Request $request, EntityManagerInterface $entityManager): Response
    {
        $product = new Product();
        $form = $this->createForm(ProductType::class, $product);
        $form->handleRequest($request);

        if ($form->isSubmitted() && $form->isValid()) {
            $entityManager->persist($product);
            $entityManager->flush();

            $this->addFlash('success', 'Product created successfully!');
            return $this->redirectToRoute('app_product_index');
        }

        return $this->render('product/new.html.twig', [
            'product' => $product,
            'form' => $form,
        ]);
    }

    #[Route('/{id}', name: 'app_product_show', methods: ['GET'])]
    public function show(Product $product): Response
    {
        return $this->render('product/show.html.twig', [
            'product' => $product,
        ]);
    }

    #[Route('/{id}/edit', name: 'app_product_edit', methods: ['GET', 'POST'])]
    public function edit(Request $request, Product $product, EntityManagerInterface $entityManager): Response
    {
        $form = $this->createForm(ProductType::class, $product);
        $form->handleRequest($request);

        if ($form->isSubmitted() && $form->isValid()) {
            $entityManager->flush();

            $this->addFlash('success', 'Product updated successfully!');
            return $this->redirectToRoute('app_product_index');
        }

        return $this->render('product/edit.html.twig', [
            'product' => $product,
            'form' => $form,
        ]);
    }

    #[Route('/{id}', name: 'app_product_delete', methods: ['POST'])]
    public function delete(Request $request, Product $product, EntityManagerInterface $entityManager): Response
    {
        if ($this->isCsrfTokenValid('delete'.$product->getId(), $request->getPayload()->getString('_token'))) {
            $entityManager->remove($product);
            $entityManager->flush();
            $this->addFlash('success', 'Product deleted successfully!');
        }

        return $this->redirectToRoute('app_product_index');
    }
}
```

## Step 5: Buat Form Class{#step-5-buat-form-class}

Selanjutnya kita akan membuat form class untuk menangani form input produk.

Jalankan perintah untuk membuat form:

```bash
php bin/console make:form ProductType Product
```

Output:

```bash
$ php bin/console make:form ProductType Product

 created: src/Form/ProductType.php

 [OK] Your form is ready!
```

Buka file `src/Form/ProductType.php` dan modifikasi dengan kode berikut:

```php
<?php

namespace App\Form;

use App\Entity\Product;
use Symfony\Component\Form\AbstractType;
use Symfony\Component\Form\Extension\Core\Type\IntegerType;
use Symfony\Component\Form\Extension\Core\Type\MoneyType;
use Symfony\Component\Form\Extension\Core\Type\TextareaType;
use Symfony\Component\Form\Extension\Core\Type\TextType;
use Symfony\Component\Form\FormBuilderInterface;
use Symfony\Component\OptionsResolver\OptionsResolver;
use Symfony\Component\Validator\Constraints\NotBlank;
use Symfony\Component\Validator\Constraints\Positive;

class ProductType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options): void
    {
        $builder
            ->add('name', TextType::class, [
                'label' => 'Product Name',
                'attr' => [
                    'class' => 'form-control',
                    'placeholder' => 'Enter product name'
                ],
                'constraints' => [
                    new NotBlank(['message' => 'Product name is required'])
                ]
            ])
            ->add('description', TextareaType::class, [
                'label' => 'Description',
                'required' => false,
                'attr' => [
                    'class' => 'form-control',
                    'placeholder' => 'Enter product description',
                    'rows' => 4
                ]
            ])
            ->add('price', MoneyType::class, [
                'label' => 'Price',
                'currency' => 'USD',
                'attr' => [
                    'class' => 'form-control',
                    'placeholder' => '0.00'
                ],
                'constraints' => [
                    new NotBlank(['message' => 'Price is required']),
                    new Positive(['message' => 'Price must be positive'])
                ]
            ])
            ->add('stock', IntegerType::class, [
                'label' => 'Stock Quantity',
                'attr' => [
                    'class' => 'form-control',
                    'placeholder' => 'Enter stock quantity'
                ],
                'constraints' => [
                    new NotBlank(['message' => 'Stock quantity is required']),
                    new Positive(['message' => 'Stock must be positive'])
                ]
            ]);
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'data_class' => Product::class,
        ]);
    }
}
```

## Step 6: Setup Template dan Layout{#step-6-setup-template-layout}

Sekarang kita akan setup template dan layout untuk aplikasi. Pertama, kita modifikasi base template.

Buka file `templates/base.html.twig` dan sesuaikan dengan kode berikut:

```
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>{% block title %}Product Management{% endblock %}</title>
        <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 128 128%22><text y=%221.2em%22 font-size=%2296%22>⚫️</text></svg>">
        
        <!-- Bootstrap CSS -->
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
        <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.2/font/bootstrap-icons.css" rel="stylesheet">
        
        {% block stylesheets %}
        {% endblock %}

        {% block javascripts %}
            <!-- Bootstrap JS -->
            <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
        {% endblock %}
    </head>
    <body>
        <!-- Navigation -->
        <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
            <div class="container">
                <a class="navbar-brand" href="{{ path('app_product_index') }}">
                    <i class="bi bi-box-seam"></i> Product Management
                </a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbarNav">
                    <ul class="navbar-nav ms-auto">
                        <li class="nav-item">
                            <a class="nav-link" href="{{ path('app_product_index') }}">
                                <i class="bi bi-list-ul"></i> All Products
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="{{ path('app_product_new') }}">
                                <i class="bi bi-plus-circle"></i> Add Product
                            </a>
                        </li>
                    </ul>
                </div>
            </div>
        </nav>

        <!-- Main Content -->
        <div class="container my-4">
            <!-- Flash Messages -->
            {% for type, messages in app.flashes %}
                {% for message in messages %}
                    <div class="alert alert-{{ type == 'error' ? 'danger' : type }} alert-dismissible fade show" role="alert">
                        {{ message }}
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                {% endfor %}
            {% endfor %}

            {% block body %}{% endblock %}
        </div>
    </body>
</html>
```

## Step 7: Implementasi Fitur Read (Menampilkan Data){#step-7-implementasi-fitur-read}

Sekarang kita akan membuat template untuk menampilkan daftar produk. Buka file `templates/product/index.html.twig` dan sesuaikan dengan kode berikut:

```
{% extends 'base.html.twig' %}

{% block title %}All Products{% endblock %}

{% block body %}
<div class="d-flex justify-content-between align-items-center mb-4">
    <h1><i class="bi bi-box-seam"></i> Product Management</h1>
    <a href="{{ path('app_product_new') }}" class="btn btn-primary">
        <i class="bi bi-plus-circle"></i> Add New Product
    </a>
</div>

{% if products|length > 0 %}
    <div class="card">
        <div class="card-body">
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead class="table-dark">
                        <tr>
                            <th>ID</th>
                            <th>Name</th>
                            <th>Description</th>
                            <th>Price</th>
                            <th>Stock</th>
                            <th width="200">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {% for product in products %}
                        <tr>
                            <td>{{ product.id }}</td>
                            <td>
                                <strong>{{ product.name }}</strong>
                            </td>
                            <td>
                                {% if product.description %}
                                    {{ product.description|length > 50 ? product.description|slice(0, 50) ~ '...' : product.description }}
                                {% else %}
                                    <em class="text-muted">No description</em>
                                {% endif %}
                            </td>
                            <td>
                                <span class="fw-bold text-success">${{ product.price }}</span>
                            </td>
                            <td>
                                {% if product.stock > 0 %}
                                    <span class="badge bg-success">{{ product.stock }} in stock</span>
                                {% else %}
                                    <span class="badge bg-danger">Out of stock</span>
                                {% endif %}
                            </td>
                            <td>
                                <div class="btn-group btn-group-sm" role="group">
                                    <a href="{{ path('app_product_show', {'id': product.id}) }}" 
                                       class="btn btn-outline-info" title="View">
                                        <i class="bi bi-eye"></i>
                                    </a>
                                    <a href="{{ path('app_product_edit', {'id': product.id}) }}" 
                                       class="btn btn-outline-warning" title="Edit">
                                        <i class="bi bi-pencil"></i>
                                    </a>
                                    <form method="post" action="{{ path('app_product_delete', {'id': product.id}) }}" 
                                          style="display: inline;"
                                          onsubmit="return confirm('Are you sure you want to delete this product?')">
                                        <input type="hidden" name="_token" value="{{ csrf_token('delete' ~ product.id) }}">
                                        <button class="btn btn-outline-danger btn-sm" title="Delete">
                                            <i class="bi bi-trash"></i>
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                        {% endfor %}
                    </tbody>
                </table>
            </div>
        </div>
    </div>
{% else %}
    <div class="text-center py-5">
        <i class="bi bi-box display-1 text-muted"></i>
        <h3 class="mt-3 text-muted">No Products Found</h3>
        <p class="text-muted">Start by adding your first product to the inventory.</p>
        <a href="{{ path('app_product_new') }}" class="btn btn-primary">
            <i class="bi bi-plus-circle"></i> Add First Product
        </a>
    </div>
{% endif %}
{% endblock %}
```

## Step 8: Implementasi Fitur Create (Menambah Data){#step-8-implementasi-fitur-create}

Sekarang kita akan membuat template untuk form menambah produk baru. Buat file `templates/product/new.html.twig`:

```
{% extends 'base.html.twig' %}

{% block title %}Add New Product{% endblock %}

{% block body %}
<div class="row justify-content-center">
    <div class="col-md-8">
        <div class="card">
            <div class="card-header">
                <h4 class="mb-0">
                    <i class="bi bi-plus-circle"></i> Add New Product
                </h4>
            </div>
            <div class="card-body">
                {{ form_start(form) }}
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            {{ form_label(form.name) }}
                            {{ form_widget(form.name) }}
                            {{ form_errors(form.name) }}
                        </div>
                        <div class="col-md-3 mb-3">
                            {{ form_label(form.price) }}
                            {{ form_widget(form.price) }}
                            {{ form_errors(form.price) }}
                        </div>
                        <div class="col-md-3 mb-3">
                            {{ form_label(form.stock) }}
                            {{ form_widget(form.stock) }}
                            {{ form_errors(form.stock) }}
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        {{ form_label(form.description) }}
                        {{ form_widget(form.description) }}
                        {{ form_errors(form.description) }}
                    </div>

                    <div class="d-flex justify-content-between">
                        <a href="{{ path('app_product_index') }}" class="btn btn-secondary">
                            <i class="bi bi-arrow-left"></i> Back to List
                        </a>
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-check-circle"></i> Save Product
                        </button>
                    </div>
                {{ form_end(form) }}
            </div>
        </div>
    </div>
</div>
{% endblock %}
```

## Step 9: Implementasi Fitur Update (Edit Data){#step-9-implementasi-fitur-update}

Buat file `templates/product/edit.html.twig` untuk template form edit produk:

```
{% extends 'base.html.twig' %}

{% block title %}Edit Product: {{ product.name }}{% endblock %}

{% block body %}
<div class="row justify-content-center">
    <div class="col-md-8">
        <div class="card">
            <div class="card-header">
                <h4 class="mb-0">
                    <i class="bi bi-pencil"></i> Edit Product: {{ product.name }}
                </h4>
            </div>
            <div class="card-body">
                {{ form_start(form) }}
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            {{ form_label(form.name) }}
                            {{ form_widget(form.name) }}
                            {{ form_errors(form.name) }}
                        </div>
                        <div class="col-md-3 mb-3">
                            {{ form_label(form.price) }}
                            {{ form_widget(form.price) }}
                            {{ form_errors(form.price) }}
                        </div>
                        <div class="col-md-3 mb-3">
                            {{ form_label(form.stock) }}
                            {{ form_widget(form.stock) }}
                            {{ form_errors(form.stock) }}
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        {{ form_label(form.description) }}
                        {{ form_widget(form.description) }}
                        {{ form_errors(form.description) }}
                    </div>

                    <div class="d-flex justify-content-between">
                        <a href="{{ path('app_product_index') }}" class="btn btn-secondary">
                            <i class="bi bi-arrow-left"></i> Back to List
                        </a>
                        <div>
                            <a href="{{ path('app_product_show', {'id': product.id}) }}" class="btn btn-info me-2">
                                <i class="bi bi-eye"></i> View Product
                            </a>
                            <button type="submit" class="btn btn-warning">
                                <i class="bi bi-check-circle"></i> Update Product
                            </button>
                        </div>
                    </div>
                {{ form_end(form) }}
            </div>
        </div>
    </div>
</div>
{% endblock %}
```

## Step 10: Implementasi Fitur Show (Detail Data){#step-10-implementasi-fitur-show}

Buat file `templates/product/show.html.twig` untuk menampilkan detail produk:

```
{% extends 'base.html.twig' %}

{% block title %}{{ product.name }}{% endblock %}

{% block body %}
<div class="row justify-content-center">
    <div class="col-md-8">
        <div class="card">
            <div class="card-header">
                <h4 class="mb-0">
                    <i class="bi bi-eye"></i> Product Details
                </h4>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-6">
                        <h5 class="card-title">{{ product.name }}</h5>
                        <p class="card-text">
                            {% if product.description %}
                                {{ product.description }}
                            {% else %}
                                <em class="text-muted">No description available</em>
                            {% endif %}
                        </p>
                    </div>
                    <div class="col-md-6">
                        <div class="row">
                            <div class="col-6">
                                <strong>Price:</strong><br>
                                <span class="h4 text-success">${{ product.price }}</span>
                            </div>
                            <div class="col-6">
                                <strong>Stock:</strong><br>
                                {% if product.stock > 0 %}
                                    <span class="badge bg-success fs-6">{{ product.stock }} available</span>
                                {% else %}
                                    <span class="badge bg-danger fs-6">Out of stock</span>
                                {% endif %}
                            </div>
                        </div>
                    </div>
                </div>
                
                <hr>
                
                <div class="d-flex justify-content-between">
                    <a href="{{ path('app_product_index') }}" class="btn btn-secondary">
                        <i class="bi bi-arrow-left"></i> Back to List
                    </a>
                    <div>
                        <a href="{{ path('app_product_edit', {'id': product.id}) }}" class="btn btn-warning me-2">
                            <i class="bi bi-pencil"></i> Edit Product
                        </a>
                        <form method="post" action="{{ path('app_product_delete', {'id': product.id}) }}" 
                              style="display: inline;"
                              onsubmit="return confirm('Are you sure you want to delete this product?')">
                            <input type="hidden" name="_token" value="{{ csrf_token('delete' ~ product.id) }}">
                            <button class="btn btn-danger">
                                <i class="bi bi-trash"></i> Delete Product
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
{% endblock %}
```

## Step 11: Uji Coba Project{#step-11-uji-coba-project}

Sekarang semua fitur CRUD sudah selesai dibuat. Saatnya menguji coba aplikasi kita.

Jalankan development server dengan perintah:

```bash
symfony serve
```

Output:

```bash
$ symfony serve

 [OK] Web server listening
      The Web server is using PHP CLI 8.2.15

[Web Server ] Feb  9, 2024 | 15:30:45 | INFO  | PHP    | listening path="/usr/bin/php" php="8.2.15" port=61738
[Web Server ] Feb  9, 2024 | 15:30:45 | INFO  | PHP    | 127.0.0.1:61738

                                                                                                                        
  [OK] Web server listening on http://127.0.0.1:8000                                                                   
                                                                                                                        

  [WARNING] run "composer require symfony/runtime" to have the new web server with better performances               
                                                                                                                        

 [Web Server ] Feb  9, 2024 | 15:30:45 | INFO  | SERVER | Quit the server with CONTROL-C.
```

Sekarang akses `http://127.0.0.1:8000/product` di browser untuk melihat halaman daftar produk.

**Halaman Daftar Produk (Kosong)**

Karena belum ada data, halaman akan menampilkan pesan "No Products Found" dengan tombol untuk menambah produk pertama.

**Testing Fitur Create**

1. Klik tombol "Add New Product" atau akses `http://127.0.0.1:8000/product/new`
2. Isi form dengan data berikut:
   - Name: "Laptop Gaming ASUS"
   - Description: "Laptop gaming dengan spesifikasi tinggi untuk para gamer"
   - Price: "1299.99"
   - Stock: "10"
3. Klik tombol "Save Product"

Setelah berhasil menyimpan, halaman akan redirect ke daftar produk dan menampilkan flash message sukses.

**Testing Fitur Read**

Sekarang di halaman daftar produk akan terlihat data produk yang baru saja ditambahkan dengan informasi lengkap dalam bentuk tabel.

**Testing Fitur Update**

1. Klik tombol "Edit" (ikon pensil) pada salah satu produk
2. Ubah beberapa field, misalnya ubah price menjadi "1199.99" dan stock menjadi "8"
3. Klik tombol "Update Product"

Data akan ter-update dan muncul flash message sukses.

**Testing Fitur Show**

1. Klik tombol "View" (ikon mata) pada salah satu produk
2. Akan menampilkan halaman detail produk dengan layout yang rapi

**Testing Fitur Delete**

1. Klik tombol "Delete" (ikon sampah) pada salah satu produk
2. Akan muncul konfirmasi "Are you sure you want to delete this product?"
3. Klik "OK" untuk menghapus

Data akan terhapus dan muncul flash message sukses.

**Testing Validasi Form**

1. Coba buat produk baru tapi kosongkan field "Name" dan "Price"
2. Akan muncul error message validasi
3. Coba isi price dengan nilai negatif, akan muncul error "Price must be positive"

## Penutup{#penutup}

Pada tutorial ini, kita telah berhasil membangun aplikasi manajemen produk lengkap dengan fitur CRUD menggunakan Symfony framework. Kita telah mempelajari proses pengembangan aplikasi Symfony dari awal hingga akhir, mulai dari setup project, konfigurasi database, pembuatan entity dan migration, controller, form, hingga template yang user-friendly.

Beberapa key takeaway yang bisa kita ambil dari tutorial ini:

1. **Symfony Framework** menyediakan struktur yang solid dan tools yang lengkap untuk pengembangan aplikasi web modern dengan arsitektur MVC yang jelas.

2. **Doctrine ORM** memudahkan kita dalam berinteraksi dengan database melalui entity dan repository pattern tanpa perlu menulis SQL query secara manual.

3. **Symfony Form Component** menyediakan cara yang elegant untuk menangani form processing, validation, dan rendering dengan type-safe approach.

4. **Twig Template Engine** memungkinkan kita membangun template yang bersih, reusable, dan maintainable dengan syntax yang mudah dipahami.

5. **Route Attributes** pada PHP 8+ memberikan cara yang modern dan deklaratif untuk mendefinisikan routing langsung di controller.

6. **Flash Messages** dan **CSRF Protection** menunjukkan bahwa Symfony memperhatikan aspek security dan user experience secara default.

7. **Bootstrap Integration** membantu kita membangun UI yang responsive dan modern dengan minimal effort.

8. **Validation Constraints** memastikan data integrity dan memberikan feedback yang jelas kepada user ketika terjadi error.

Dengan pemahaman yang diperoleh dari tutorial ini, Anda sekarang dapat mengembangkan aplikasi web yang lebih kompleks menggunakan Symfony framework. Beberapa fitur lanjutan yang bisa Anda eksplorasi selanjutnya adalah authentication & authorization, pagination, search & filtering, file upload, email integration, dan API development. Selamat mengembangkan aplikasi Symfony Anda!