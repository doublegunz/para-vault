---
title: "Tutorial CodeIgniter 4: Upload dan Download File"
slug: "tutorial-codeigniter-4-upload-dan-download-file"
category: "CodeIgniter 4"
date: "2025-09-17"
status: "published"
---

Selamat datang di tutorial CodeIgniter 4 edisi kali ini! Pada kesempatan ini kita akan mempelajari bagaimana cara mengembangkan fitur upload file dan download file yang lengkap menggunakan framework CodeIgniter 4. Tutorial ini akan membahas implementasi sistem manajemen dokumen sederhana yang bisa menjadi dasar untuk pengembangan aplikasi yang lebih kompleks.

## Overview {#overview}
Dalam tutorial ini, kita akan mengembangkan sistem manajemen dokumen sederhana yang memiliki fitur-fitur berikut:
1. **Upload berbagai jenis file** (PDF, DOC, XLSX, ZIP, dll) dengan validasi yang ketat
2. **Menyimpan metadata file** ke database untuk tracking yang lebih baik
3. **Menampilkan daftar file** yang sudah diupload dengan informasi lengkap
4. **Download file** dengan sistem keamanan yang tepat
5. **Hapus file** dari sistem dan database
6. **Preview file** untuk tipe file tertentu

Dari studi kasus ini, Anda akan mempelajari:

- Cara mengkonfigurasi upload file untuk berbagai tipe file
- Implementasi validasi file yang komprehensif (ukuran, tipe, ekstensi)
- Teknik menyimpan file dengan nama yang aman dan unik
- Cara membuat sistem download file yang secure
- Pengelolaan file di server dan database secara bersamaan
- Best practices dalam handling file di aplikasi web

Dalam tutorial ini, kita akan menggunakan beberapa teknologi dan tools berikut:
- **CodeIgniter 4.5.x** - Framework PHP modern dengan arsitektur MVC
- **MySQL/MariaDB** - Sistem database untuk menyimpan informasi file
- **Bootstrap 5** - Framework CSS untuk tampilan yang responsif
- **PHP 8.1+** - Versi PHP yang direkomendasikan untuk CodeIgniter 4
- **Composer** - Dependency manager untuk PHP

Mari kita mulai membangun aplikasi ini langkah demi langkah!

**Daftar Isi**
1. [Overview](#overview)
2. [Step 1: Instalasi dan Setup Project](#step-1-instalasi)
3. [Step 2: Konfigurasi Environment](#step-2-konfigurasi)
4. [Step 3: Membuat Database dan Table](#step-3-database)
5. [Step 4: Membuat Migration untuk Table Documents](#step-4-migration)
6. [Step 5: Membuat Model Document](#step-5-model)
7. [Step 6: Membuat Template Layout](#step-6-template)
8. [Step 7: Membuat Controller Document](#step-7-controller)
9. [Step 8: Membuat View untuk List Document](#step-8-view-list)
10. [Step 9: Membuat View Form Upload](#step-9-upload)
11. [Step 10: Membuat View Detail Dokumen](#step-10-view-detail-dokumen)
12. [Step 11: Definisikan Route](#step-11-definisikan-route)
13. [Step 12: Testing](#step-12-testing)
14. [Kesimpulan dan Key Takeaway](#kesimpulan)

## Step 1: Instalasi dan Setup Project {#step-1-instalasi}

Langkah pertama adalah membuat project CodeIgniter 4 baru. Buka terminal atau command prompt, kemudian jalankan perintah berikut:

```bash
composer create-project codeigniter4/appstarter document-management
```

Perintah di atas akan membuat project baru dengan nama `document-management`. Tunggu hingga proses instalasi selesai, biasanya memakan waktu beberapa menit tergantung koneksi internet.

Setelah instalasi selesai, masuk ke direktori project:

```bash
cd document-management
```

## Step 2: Konfigurasi Environment {#step-2-konfigurasi}

Pada tahap ini kita akan mengkonfigurasi environment aplikasi. Pertama, copy file `env` menjadi `.env`:

```bash
cp env .env
```

Atau jika menggunakan Windows:

```bash
copy env .env
```

Selanjutnya buka file `.env` menggunakan text editor favorit Anda. Jika menggunakan Visual Studio Code, jalankan command berikut untuk membuka project di visual studio code:

```bash
code .
```

Edit file `.env` dan sesuaikan konfigurasi berikut:

```php
# Environment
CI_ENVIRONMENT = development

# App
app.baseURL = 'http://localhost:8080/'
app.indexPage = ''

# Database
database.default.hostname = localhost
database.default.database = db_document_management
database.default.username = root
database.default.password = 
database.default.DBDriver = MySQLi
database.default.port = 3306
```

Konfigurasi di atas mengatur aplikasi dalam mode development, setting base URL, dan konfigurasi database. Sesuaikan username dan password database dengan konfigurasi MySQL di komputer Anda.

## Step 3: Membuat Database dan Table {#step-3-database}

Sekarang kita buat database untuk project kita. Buka phpMyAdmin atau tool database management lainnya, kemudian buat database baru:

```sql
CREATE DATABASE db_document_management;
```

Atau Anda bisa membuat database langsung dari terminal MySQL:

```bash
mysql -u root -p
```

Kemudian jalankan:

```sql
CREATE DATABASE db_document_management;
USE db_document_management;
EXIT;
```

Database sudah berhasil dibuat. Selanjutnya kita akan membuat table menggunakan fitur migration CodeIgniter 4.

## Step 4: Membuat Migration untuk Table Documents {#step-4-migration}

Kita akan membuat table `documents` untuk menyimpan informasi file yang diupload. Jalankan command berikut:

```bash
php spark make:migration Documents
```

Output yang muncul akan seperti ini:

```
$ php spark make:migration Documents

CodeIgniter v4.6.3 Command Line Tool - Server Time: 2025-09-17 00:20:02 UTC+00:00

File created: APPPATH/Database/Migrations/2025-09-17-002002_Documents.php

```

Buka file migration yang baru dibuat di folder `app/Database/Migrations/`, kemudian edit dengan kode berikut:

```php
<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class Documents extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id' => [
                'type'           => 'INT',
                'constraint'     => 11,
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'title' => [
                'type'       => 'VARCHAR',
                'constraint' => '255',
                'null'       => false,
            ],
            'description' => [
                'type' => 'TEXT',
                'null' => true,
            ],
            'file_name' => [
                'type'       => 'VARCHAR',
                'constraint' => '255',
                'null'       => false,
            ],
            'file_original_name' => [
                'type'       => 'VARCHAR',
                'constraint' => '255',
                'null'       => false,
            ],
            'file_type' => [
                'type'       => 'VARCHAR',
                'constraint' => '100',
                'null'       => false,
            ],
            'file_size' => [
                'type'       => 'INT',
                'constraint' => 11,
                'null'       => false,
            ],
            'file_extension' => [
                'type'       => 'VARCHAR',
                'constraint' => '10',
                'null'       => false,
            ],
            'uploaded_by' => [
                'type'       => 'VARCHAR',
                'constraint' => '100',
                'null'       => true,
            ],
            'created_at' => [
                'type' => 'DATETIME',
                'null' => true,
            ],
            'updated_at' => [
                'type' => 'DATETIME',
                'null' => true,
            ],
        ]);

        $this->forge->addKey('id', true);
        $this->forge->addKey('file_name');
        $this->forge->createTable('documents');
    }

    public function down()
    {
        $this->forge->dropTable('documents');
    }
}
```

Migration ini akan membuat table dengan struktur yang lengkap untuk menyimpan informasi dokumen. Field-field yang dibuat mencakup informasi dasar dokumen (title, description), informasi file (nama, tipe, ukuran, ekstensi), dan metadata (uploaded_by, timestamps).

Jalankan migration dengan command:

```bash
php spark migrate
```

Output yang muncul:

```
$ php spark migrate

CodeIgniter v4.6.3 Command Line Tool - Server Time: 2025-09-17 00:21:51 UTC+00:00

Running all new migrations...
	Running: (App) 2025-09-17-002002_App\Database\Migrations\Documents
Migrations complete.

```

## Step 5: Membuat Model Document {#step-5-model}

Sekarang kita buat model untuk mengelola data documents. Jalankan command:

```bash
php spark make:model DocumentModel
```

Output:

```
$ php spark make:model DocumentModel

CodeIgniter v4.6.3 Command Line Tool - Server Time: 2025-09-17 00:20:31 UTC+00:00

File created: APPPATH/Models/DocumentModel.php

```

Buka file `app/Models/DocumentModel.php` dan edit dengan kode berikut:

```php
<?php

namespace App\Models;

use CodeIgniter\Model;

class DocumentModel extends Model
{
    protected $table            = 'documents';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = false;
    protected $protectFields    = true;
    protected $allowedFields    = [
        'title',
        'description',
        'file_name',
        'file_original_name',
        'file_type',
        'file_size',
        'file_extension',
        'uploaded_by'
    ];

    // Dates
    protected $useTimestamps = true;
    protected $dateFormat    = 'datetime';
    protected $createdField  = 'created_at';
    protected $updatedField  = 'updated_at';

    // Validation
    protected $validationRules = [
        'title' => 'required|min_length[3]|max_length[255]',
        'file_name' => 'required|max_length[255]',
        'file_original_name' => 'required|max_length[255]',
        'file_type' => 'required|max_length[100]',
        'file_size' => 'required|integer',
        'file_extension' => 'required|max_length[10]'
    ];
    
    protected $validationMessages = [
        'title' => [
            'required' => 'Judul dokumen harus diisi',
            'min_length' => 'Judul minimal 3 karakter',
            'max_length' => 'Judul maksimal 255 karakter'
        ]
    ];

    protected $skipValidation = false;

    /**
     * Get formatted file size
     */
    public function getFormattedSize($size)
    {
        $units = ['B', 'KB', 'MB', 'GB'];
        $i = 0;
        
        while ($size >= 1024 && $i < count($units) - 1) {
            $size /= 1024;
            $i++;
        }
        
        return round($size, 2) . ' ' . $units[$i];
    }
}
```

Model ini sudah dilengkapi dengan konfigurasi lengkap termasuk validation rules dan method helper untuk format ukuran file. Validation rules memastikan data yang disimpan ke database selalu valid.

## Step 6: Membuat Template Layout {#step-6-template}

Kita akan membuat template layout untuk tampilan aplikasi. Buat folder baru `layouts` di direktori `app/Views` atau bisa juga buat folder menggunakan command berikut ini.

```bash
mkdir app/Views/layouts
```

Kemudian buat file `app/Views/layouts/main.php`:

```html
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta name="<?= csrf_token() ?>" content="<?= csrf_hash() ?>">
    <title><?= $title ?? 'Document Management System'; ?></title>
    
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <!-- Custom CSS -->
    <style>
        .file-icon {
            font-size: 2.5rem;
        }
        .table-hover tbody tr:hover {
            background-color: rgba(0,0,0,.075);
        }
        .upload-zone {
            border: 2px dashed #dee2e6;
            border-radius: 0.5rem;
            padding: 2rem;
            text-align: center;
            transition: all 0.3s;
        }
        .upload-zone:hover {
            border-color: #0d6efd;
            background-color: #f8f9fa;
        }
    </style>
</head>
<body>
    <!-- Navigation -->
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
        <div class="container">
            <a class="navbar-brand" href="<?= base_url('/') ?>">
                <i class="bi bi-folder2-open"></i> Document Management
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="<?= base_url('/') ?>">
                            <i class="bi bi-house"></i> Home
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<?= base_url('documents') ?>">
                            <i class="bi bi-file-earmark-text"></i> Documents
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<?= base_url('documents/upload') ?>">
                            <i class="bi bi-cloud-upload"></i> Upload
                        </a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <!-- Main Content -->
    <main class="py-4">
        <?= $this->renderSection('content') ?>
    </main>

    <!-- Footer -->
    <footer class="bg-light py-4 mt-5">
        <div class="container text-center">
            <p class="text-muted mb-0">
                <small>Document Management System © <?= date('Y') ?> - Tutorial CodeIgniter 4: part of <a href="https://qadrlabs.com">qadrlabs</a>'s tutorial series </small>
            </p>
        </div>
    </footer>

    <!-- Bootstrap 5 JS Bundle -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    <!-- Custom JS Section -->
    <?= $this->renderSection('scripts') ?>
</body>
</html>
```

Template ini menggunakan Bootstrap 5 untuk styling dan Bootstrap Icons untuk ikon. Layout ini akan menjadi wrapper untuk semua halaman dalam aplikasi.

## Step 7: Membuat Controller Document {#step-7-controller}

Sekarang kita buat controller untuk mengelola semua logic aplikasi. Jalankan command:

```bash
php spark make:controller DocumentController
```

Output:

```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-XX-XX XX:XX:XX UTC+00:00

File created: APPPATH/Controllers/DocumentController.php
```

Edit file `app/Controllers/DocumentController.php`:

```php
<?php

namespace App\Controllers;

use App\Models\DocumentModel;
use CodeIgniter\Files\File;

class DocumentController extends BaseController
{
    protected $documentModel;
    protected $helpers = ['form', 'url', 'filesystem'];

    public function __construct()
    {
        $this->documentModel = new DocumentModel();
    }

    /**
     * Display list of documents
     */
    public function index()
    {
        $data = [
            'title' => 'Daftar Dokumen',
            'documents' => $this->documentModel->orderBy('created_at', 'DESC')->paginate(10),
            'pager' => $this->documentModel->pager
        ];

        return view('documents/index', $data);
    }

    /**
     * Show upload form
     */
    public function upload()
    {
        $data = [
            'title' => 'Upload Dokumen Baru',
            'validation' => \Config\Services::validation()
        ];

        return view('documents/upload', $data);
    }

    /**
     * Handle file upload
     */
    public function store()
    {
        // Validation rules untuk upload
        $validationRules = [
            'title' => [
                'rules' => 'required|min_length[3]|max_length[255]',
                'errors' => [
                    'required' => 'Judul dokumen harus diisi',
                    'min_length' => 'Judul minimal 3 karakter',
                    'max_length' => 'Judul maksimal 255 karakter'
                ]
            ],
            'document_file' => [
                'rules' => 'uploaded[document_file]'
                    . '|max_size[document_file,10240]' // Max 10MB
                    . '|ext_in[document_file,pdf,doc,docx,xls,xlsx,ppt,pptx,zip,rar,txt,jpg,jpeg,png,gif]',
                'errors' => [
                    'uploaded' => 'Pilih file yang akan diupload',
                    'max_size' => 'Ukuran file maksimal 10MB',
                    'ext_in' => 'Format file tidak didukung'
                ]
            ]
        ];

        if (!$this->validate($validationRules)) {
            return redirect()->back()->withInput()->with('errors', $this->validator->getErrors());
        }

        $file = $this->request->getFile('document_file');
        
        if ($file->isValid() && !$file->hasMoved()) {
            // Generate nama file unik
            $newName = $file->getRandomName();
            
            // Pindahkan file ke folder uploads
            $file->move(ROOTPATH . 'public/uploads', $newName);

            // Siapkan data untuk disimpan ke database
            $data = [
                'title' => $this->request->getPost('title'),
                'description' => $this->request->getPost('description'),
                'file_name' => $newName,
                'file_original_name' => $file->getClientName(),
                'file_type' => $file->getClientMimeType(),
                'file_size' => $file->getSize(),
                'file_extension' => $file->getClientExtension(),
                'uploaded_by' => $this->request->getPost('uploaded_by') ?? 'System'
            ];

            // Simpan ke database
            if ($this->documentModel->save($data)) {
                return redirect()->to('/documents')->with('success', 'Dokumen berhasil diupload!');
            } else {
                // Hapus file jika gagal simpan ke database
                unlink(ROOTPATH . 'public/uploads/' . $newName);
                return redirect()->back()->withInput()->with('error', 'Gagal menyimpan informasi dokumen');
            }
        }

        return redirect()->back()->withInput()->with('error', 'Terjadi kesalahan saat upload file');
    }

    /**
     * Download document
     */
    public function download($id)
    {
        $document = $this->documentModel->find($id);

        if (!$document) {
            return redirect()->to('/documents')->with('error', 'Dokumen tidak ditemukan');
        }

        $filepath = ROOTPATH . 'public/uploads/' . $document['file_name'];

        if (!file_exists($filepath)) {
            return redirect()->to('/documents')->with('error', 'File tidak ditemukan di server');
        }

        return $this->response->download($filepath, null)->setFileName($document['file_original_name']);
    }

    /**
     * Delete document
     */
    public function delete($id)
    {
        $document = $this->documentModel->find($id);

        if (!$document) {
            return redirect()->to('/documents')->with('error', 'Dokumen tidak ditemukan');
        }

        $filepath = ROOTPATH . 'public/uploads/' . $document['file_name'];

        // Hapus dari database
        if ($this->documentModel->delete($id)) {
            // Hapus file dari server
            if (file_exists($filepath)) {
                unlink($filepath);
            }
            return redirect()->to('/documents')->with('success', 'Dokumen berhasil dihapus');
        }

        return redirect()->to('/documents')->with('error', 'Gagal menghapus dokumen');
    }

    /**
     * View document details
     */
    public function view($id)
    {
        $document = $this->documentModel->find($id);

        if (!$document) {
            return redirect()->to('/documents')->with('error', 'Dokumen tidak ditemukan');
        }

        $data = [
            'title' => 'Detail Dokumen',
            'document' => $document,
            'formatted_size' => $this->documentModel->getFormattedSize($document['file_size'])
        ];

        return view('documents/view', $data);
    }
}
```

Controller ini memiliki method-method lengkap untuk mengelola dokumen: index (list), upload (form), store (proses upload), download, delete, dan view (detail).

## Step 8: Membuat View untuk List Document {#step-8-view-list}

Buat folder `documents` di `app/Views`:

```bash
mkdir app/Views/documents
```

Kemudian buat file `app/Views/documents/index.php`:

```php
<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>
<div class="container">
    <div class="row">
        <div class="col-12">
            <div class="card shadow-sm">
                <div class="card-header bg-primary text-white d-flex justify-content-between align-items-center">
                    <h4 class="mb-0">
                        <i class="bi bi-folder2-open"></i> Daftar Dokumen
                    </h4>
                    <a href="<?= base_url('documents/upload') ?>" class="btn btn-light btn-sm">
                        <i class="bi bi-cloud-upload"></i> Upload Dokumen
                    </a>
                </div>
                <div class="card-body">
                    <!-- Alert Messages -->
                    <?php if (session()->getFlashdata('success')): ?>
                        <div class="alert alert-success alert-dismissible fade show" role="alert">
                            <i class="bi bi-check-circle"></i> <?= session()->getFlashdata('success') ?>
                            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                        </div>
                    <?php endif; ?>

                    <?php if (session()->getFlashdata('error')): ?>
                        <div class="alert alert-danger alert-dismissible fade show" role="alert">
                            <i class="bi bi-exclamation-triangle"></i> <?= session()->getFlashdata('error') ?>
                            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                        </div>
                    <?php endif; ?>

                    <?php if (!empty($documents) && is_array($documents)): ?>
                        <div class="table-responsive">
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th width="50">#</th>
                                        <th width="60">Icon</th>
                                        <th>Judul</th>
                                        <th>Nama File</th>
                                        <th>Ukuran</th>
                                        <th>Tipe</th>
                                        <th>Tanggal Upload</th>
                                        <th width="150">Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php 
                                    $no = 1;
                                    foreach ($documents as $doc): 
                                        $model = new \App\Models\DocumentModel();
                                        $formattedSize = $model->getFormattedSize($doc['file_size']);
                                        
                                        // Determine icon based on file extension
                                        $icon = 'bi-file-earmark';
                                        $iconColor = 'text-secondary';
                                        switch(strtolower($doc['file_extension'])) {
                                            case 'pdf':
                                                $icon = 'bi-file-earmark-pdf-fill';
                                                $iconColor = 'text-danger';
                                                break;
                                            case 'doc':
                                            case 'docx':
                                                $icon = 'bi-file-earmark-word-fill';
                                                $iconColor = 'text-primary';
                                                break;
                                            case 'xls':
                                            case 'xlsx':
                                                $icon = 'bi-file-earmark-excel-fill';
                                                $iconColor = 'text-success';
                                                break;
                                            case 'ppt':
                                            case 'pptx':
                                                $icon = 'bi-file-earmark-ppt-fill';
                                                $iconColor = 'text-warning';
                                                break;
                                            case 'zip':
                                            case 'rar':
                                                $icon = 'bi-file-earmark-zip-fill';
                                                $iconColor = 'text-info';
                                                break;
                                            case 'jpg':
                                            case 'jpeg':
                                            case 'png':
                                            case 'gif':
                                                $icon = 'bi-file-earmark-image-fill';
                                                $iconColor = 'text-success';
                                                break;
                                            case 'txt':
                                                $icon = 'bi-file-earmark-text-fill';
                                                $iconColor = 'text-secondary';
                                                break;
                                        }
                                    ?>
                                    <tr>
                                        <td><?= $no++ ?></td>
                                        <td class="text-center">
                                            <i class="bi <?= $icon ?> <?= $iconColor ?> file-icon"></i>
                                        </td>
                                        <td>
                                            <strong><?= esc($doc['title']) ?></strong>
                                            <?php if ($doc['description']): ?>
                                                <br><small class="text-muted"><?= esc(substr($doc['description'], 0, 50)) ?>...</small>
                                            <?php endif; ?>
                                        </td>
                                        <td>
                                            <small><?= esc($doc['file_original_name']) ?></small>
                                        </td>
                                        <td><?= $formattedSize ?></td>
                                        <td>
                                            <span class="badge bg-secondary"><?= strtoupper($doc['file_extension']) ?></span>
                                        </td>
                                        <td>
                                            <small><?= date('d/m/Y H:i', strtotime($doc['created_at'])) ?></small>
                                        </td>
                                        <td>
                                            <div class="btn-group btn-group-sm" role="group">
                                                <a href="<?= base_url('documents/view/' . $doc['id']) ?>" 
                                                   class="btn btn-info" title="Lihat Detail">
                                                    <i class="bi bi-eye"></i>
                                                </a>
                                                <a href="<?= base_url('documents/download/' . $doc['id']) ?>" 
                                                   class="btn btn-success" title="Download">
                                                    <i class="bi bi-download"></i>
                                                </a>
                                                <a href="<?= base_url('documents/delete/' . $doc['id']) ?>" 
                                                   class="btn btn-danger" 
                                                   onclick="return confirm('Apakah Anda yakin ingin menghapus dokumen ini?')"
                                                   title="Hapus">
                                                    <i class="bi bi-trash"></i>
                                                </a>
                                            </div>
                                        </td>
                                    </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>

                        <!-- Pagination -->
                        <div class="mt-3">
                            <?= $pager->links('default', 'bootstrap_pagination') ?>
                        </div>
                    <?php else: ?>
                        <div class="text-center py-5">
                            <i class="bi bi-folder2-open text-muted" style="font-size: 5rem;"></i>
                            <h5 class="mt-3 text-muted">Belum ada dokumen</h5>
                            <p class="text-muted">Mulai upload dokumen pertama Anda</p>
                            <a href="<?= base_url('documents/upload') ?>" class="btn btn-primary">
                                <i class="bi bi-cloud-upload"></i> Upload Dokumen
                            </a>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
    </div>
</div>
<?= $this->endSection() ?>
```

View ini menampilkan daftar dokumen dalam format tabel dengan ikon yang sesuai untuk setiap tipe file. Terdapat juga tombol aksi untuk view, download, dan delete.

Pada view di atas terdapat baris kode berikut:

```
<?= $pager->links('default', 'bootstrap_pagination') ?>
```

Kita coba gunakan custom pagination untuk tampilan paginasi pada halaman menampilkan daftar dokumen. Untuk menambahkan custom pagination, buka file `app/Config/Pager.php`, lalu kita tambahkan baris kode berikut:

```php
<?php

namespace Config;

use CodeIgniter\Config\BaseConfig;

class Pager extends BaseConfig
{
    public $templates = [
        'default_full'   => 'CodeIgniter\Pager\Views\default_full',
        'default_simple' => 'CodeIgniter\Pager\Views\default_simple',
        'default_head'   => 'CodeIgniter\Pager\Views\default_head',
        'bootstrap_pagination' => 'App\Views\Pagers\bootstrap_pagination', // tambahkan custom pagination
    ];

    public $perPage = 20;
}
```

Selanjutnya kita buat file pagination template di `app/Views/Pagers/bootstrap_pagination.php`:

```php
<?php $pager->setSurroundCount(2) ?>

<nav aria-label="Page navigation">
    <ul class="pagination justify-content-center">
        <?php if ($pager->hasPrevious()) : ?>
            <li class="page-item">
                <a class="page-link" href="<?= $pager->getFirst() ?>" aria-label="First">
                    <span aria-hidden="true">First</span>
                </a>
            </li>
            <li class="page-item">
                <a class="page-link" href="<?= $pager->getPrevious() ?>" aria-label="Previous">
                    <span aria-hidden="true">&laquo;</span>
                </a>
            </li>
        <?php endif ?>

        <?php foreach ($pager->links() as $link) : ?>
            <li class="page-item <?= $link['active'] ? 'active' : '' ?>">
                <a class="page-link" href="<?= $link['uri'] ?>">
                    <?= $link['title'] ?>
                </a>
            </li>
        <?php endforeach ?>

        <?php if ($pager->hasNext()) : ?>
            <li class="page-item">
                <a class="page-link" href="<?= $pager->getNext() ?>" aria-label="Next">
                    <span aria-hidden="true">&raquo;</span>
                </a>
            </li>
            <li class="page-item">
                <a class="page-link" href="<?= $pager->getLast() ?>" aria-label="Last">
                    <span aria-hidden="true">Last</span>
                </a>
            </li>
        <?php endif ?>
    </ul>
</nav>
```



## Step 9: Membuat View Form Upload {#step-9-upload}

Buat file `app/Views/documents/upload.php`:

```php
<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card shadow-sm">
                <div class="card-header bg-primary text-white">
                    <h4 class="mb-0">
                        <i class="bi bi-cloud-upload"></i> Upload Dokumen Baru
                    </h4>
                </div>
                <div class="card-body">
                    <!-- Error Messages -->
                    <?php if (session()->getFlashdata('errors')): ?>
                        <div class="alert alert-danger">
                            <h6 class="alert-heading">Terdapat kesalahan:</h6>
                            <ul class="mb-0">
                                <?php foreach (session()->getFlashdata('errors') as $error): ?>
                                    <li><?= esc($error) ?></li>
                                <?php endforeach ?>
                            </ul>
                        </div>
                    <?php endif; ?>

                    <?php if (session()->getFlashdata('error')): ?>
                        <div class="alert alert-danger">
                            <?= session()->getFlashdata('error') ?>
                        </div>
                    <?php endif; ?>

                    <!-- Upload Form -->
                    <?= form_open_multipart('documents/store') ?>
                        
                        <div class="mb-3">
                            <label for="title" class="form-label">
                                Judul Dokumen <span class="text-danger">*</span>
                            </label>
                            <input type="text" 
                                   class="form-control <?= (session()->getFlashdata('errors.title')) ? 'is-invalid' : '' ?>" 
                                   id="title" 
                                   name="title" 
                                   value="<?= old('title') ?>" 
                                   placeholder="Masukkan judul dokumen"
                                   required>
                            <small class="text-muted">Judul yang deskriptif memudahkan pencarian dokumen</small>
                        </div>

                        <div class="mb-3">
                            <label for="description" class="form-label">Deskripsi</label>
                            <textarea class="form-control" 
                                      id="description" 
                                      name="description" 
                                      rows="3" 
                                      placeholder="Tambahkan deskripsi dokumen (opsional)"><?= old('description') ?></textarea>
                        </div>

                        <div class="mb-3">
                            <label for="document_file" class="form-label">
                                File Dokumen <span class="text-danger">*</span>
                            </label>
                            <div class="upload-zone" id="uploadZone">
                                <i class="bi bi-cloud-arrow-up" style="font-size: 3rem; color: #6c757d;"></i>
                                <p class="mt-2 mb-1">Drag & drop file di sini atau klik untuk memilih</p>
                                <input type="file" 
                                       class="form-control <?= (session()->getFlashdata('errors.document_file')) ? 'is-invalid' : '' ?>" 
                                       id="document_file" 
                                       name="document_file" 
                                       required
                                       accept=".pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.zip,.rar,.txt,.jpg,.jpeg,.png,.gif"
                                       style="display: none;">
                                <small class="text-muted">
                                    Format yang didukung: PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX, ZIP, RAR, TXT, JPG, PNG, GIF<br>
                                    Ukuran maksimal: 10MB
                                </small>
                                <div id="fileInfo" class="mt-3" style="display: none;">
                                    <div class="alert alert-info mb-0">
                                        <i class="bi bi-file-earmark"></i> 
                                        <span id="fileName"></span> 
                                        (<span id="fileSize"></span>)
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="mb-3">
                            <label for="uploaded_by" class="form-label">Diupload Oleh</label>
                            <input type="text" 
                                   class="form-control" 
                                   id="uploaded_by" 
                                   name="uploaded_by" 
                                   value="<?= old('uploaded_by') ?>" 
                                   placeholder="Nama pengupload (opsional)">
                        </div>

                        <div class="d-grid gap-2 d-md-flex justify-content-md-end">
                            <a href="<?= base_url('documents') ?>" class="btn btn-secondary">
                                <i class="bi bi-arrow-left"></i> Kembali
                            </a>
                            <button type="submit" class="btn btn-primary" id="uploadBtn">
                                <i class="bi bi-cloud-upload"></i> Upload Dokumen
                            </button>
                        </div>

                    <?= form_close() ?>
                </div>
            </div>
        </div>
    </div>
</div>
<?= $this->endSection() ?>

<?= $this->section('scripts') ?>
<script>
// Interactive upload zone
document.addEventListener('DOMContentLoaded', function() {
    const uploadZone = document.getElementById('uploadZone');
    const fileInput = document.getElementById('document_file');
    const fileInfo = document.getElementById('fileInfo');
    const fileName = document.getElementById('fileName');
    const fileSize = document.getElementById('fileSize');

    // Click to select file
    uploadZone.addEventListener('click', function() {
        fileInput.click();
    });

    // Drag and drop functionality
    uploadZone.addEventListener('dragover', function(e) {
        e.preventDefault();
        this.style.borderColor = '#0d6efd';
        this.style.backgroundColor = '#e7f1ff';
    });

    uploadZone.addEventListener('dragleave', function(e) {
        e.preventDefault();
        this.style.borderColor = '#dee2e6';
        this.style.backgroundColor = 'transparent';
    });

    uploadZone.addEventListener('drop', function(e) {
        e.preventDefault();
        this.style.borderColor = '#dee2e6';
        this.style.backgroundColor = 'transparent';
        
        const files = e.dataTransfer.files;
        if (files.length > 0) {
            fileInput.files = files;
            displayFileInfo(files[0]);
        }
    });

    // Display file info when selected
    fileInput.addEventListener('change', function() {
        if (this.files && this.files[0]) {
            displayFileInfo(this.files[0]);
        }
    });

    function displayFileInfo(file) {
        fileName.textContent = file.name;
        fileSize.textContent = formatFileSize(file.size);
        fileInfo.style.display = 'block';
    }

    function formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
    }
});
</script>
<?= $this->endSection() ?>
```

Form upload ini memiliki fitur drag & drop yang interaktif dan menampilkan informasi file yang dipilih sebelum diupload.

Sekarang kita perlu membuat folder uploads. Buat folder uploads:

```bash
mkdir public/uploads
```

Kemudian buat file `.gitkeep` di dalam folder uploads agar folder tetap ada di repository:

```bash
touch public/uploads/.gitkeep
```



## Step 10: Membuat View Detail Dokumen {#step-10-view-detail-dokumen}

Fitur download sudah diimplementasikan di controller pada method `download()`. Fitur ini tersedia di halaman list dokumen dan juga halaman detail dokumen. Sekarang kita akan menambahkan view detail dokumen, buat file `app/Views/documents/view.php`:

```php
<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card shadow-sm">
                <div class="card-header bg-primary text-white">
                    <h4 class="mb-0">
                        <i class="bi bi-file-earmark-text"></i> Detail Dokumen
                    </h4>
                </div>
                <div class="card-body">
                    <?php 
                    // Determine icon
                    $icon = 'bi-file-earmark';
                    $iconColor = 'text-secondary';
                    switch(strtolower($document['file_extension'])) {
                        case 'pdf':
                            $icon = 'bi-file-earmark-pdf-fill';
                            $iconColor = 'text-danger';
                            break;
                        case 'doc':
                        case 'docx':
                            $icon = 'bi-file-earmark-word-fill';
                            $iconColor = 'text-primary';
                            break;
                        case 'xls':
                        case 'xlsx':
                            $icon = 'bi-file-earmark-excel-fill';
                            $iconColor = 'text-success';
                            break;
                        case 'ppt':
                        case 'pptx':
                            $icon = 'bi-file-earmark-ppt-fill';
                            $iconColor = 'text-warning';
                            break;
                        case 'zip':
                        case 'rar':
                            $icon = 'bi-file-earmark-zip-fill';
                            $iconColor = 'text-info';
                            break;
                        case 'jpg':
                        case 'jpeg':
                        case 'png':
                        case 'gif':
                            $icon = 'bi-file-earmark-image-fill';
                            $iconColor = 'text-success';
                            break;
                        case 'txt':
                            $icon = 'bi-file-earmark-text-fill';
                            $iconColor = 'text-secondary';
                            break;
                    }
                    ?>
                    
                    <div class="text-center mb-4">
                        <i class="bi <?= $icon ?> <?= $iconColor ?>" style="font-size: 5rem;"></i>
                    </div>

                    <table class="table table-borderless">
                        <tr>
                            <th width="200">Judul:</th>
                            <td><?= esc($document['title']) ?></td>
                        </tr>
                        <?php if ($document['description']): ?>
                        <tr>
                            <th>Deskripsi:</th>
                            <td><?= esc($document['description']) ?></td>
                        </tr>
                        <?php endif; ?>
                        <tr>
                            <th>Nama File Original:</th>
                            <td><?= esc($document['file_original_name']) ?></td>
                        </tr>
                        <tr>
                            <th>Nama File Sistem:</th>
                            <td><code><?= esc($document['file_name']) ?></code></td>
                        </tr>
                        <tr>
                            <th>Tipe File:</th>
                            <td><?= esc($document['file_type']) ?></td>
                        </tr>
                        <tr>
                            <th>Ekstensi:</th>
                            <td><span class="badge bg-secondary"><?= strtoupper($document['file_extension']) ?></span></td>
                        </tr>
                        <tr>
                            <th>Ukuran File:</th>
                            <td><?= $formatted_size ?> (<?= number_format($document['file_size']) ?> bytes)</td>
                        </tr>
                        <?php if ($document['uploaded_by']): ?>
                        <tr>
                            <th>Diupload Oleh:</th>
                            <td><?= esc($document['uploaded_by']) ?></td>
                        </tr>
                        <?php endif; ?>
                        <tr>
                            <th>Tanggal Upload:</th>
                            <td><?= date('d F Y H:i:s', strtotime($document['created_at'])) ?></td>
                        </tr>
                        <?php if ($document['updated_at'] && $document['updated_at'] != $document['created_at']): ?>
                        <tr>
                            <th>Terakhir Diperbarui:</th>
                            <td><?= date('d F Y H:i:s', strtotime($document['updated_at'])) ?></td>
                        </tr>
                        <?php endif; ?>
                    </table>

                    <!-- Preview for Images -->
                    <?php if (in_array(strtolower($document['file_extension']), ['jpg', 'jpeg', 'png', 'gif'])): ?>
                        <div class="mt-4">
                            <h5>Preview:</h5>
                            <div class="text-center">
                                <img src="<?= base_url('uploads/' . $document['file_name']) ?>" 
                                     alt="<?= esc($document['title']) ?>" 
                                     class="img-fluid rounded" 
                                     style="max-height: 400px;">
                            </div>
                        </div>
                    <?php endif; ?>

                    <div class="d-grid gap-2 d-md-flex justify-content-md-end mt-4">
                        <a href="<?= base_url('documents') ?>" class="btn btn-secondary">
                            <i class="bi bi-arrow-left"></i> Kembali
                        </a>
                        <a href="<?= base_url('documents/download/' . $document['id']) ?>" class="btn btn-success">
                            <i class="bi bi-download"></i> Download
                        </a>
                        <a href="<?= base_url('documents/delete/' . $document['id']) ?>" 
                           class="btn btn-danger"
                           onclick="return confirm('Apakah Anda yakin ingin menghapus dokumen ini?')">
                            <i class="bi bi-trash"></i> Hapus
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<?= $this->endSection() ?>
```

View detail ini menampilkan semua informasi dokumen dan preview untuk file gambar.

## Step 11: Definisikan Route {#step-11-definisikan-route}

Sekarang atur routing di file `app/Config/Routes.php`:

```php
<?php

use CodeIgniter\Router\RouteCollection;

/**
 * @var RouteCollection $routes
 */
$routes->get('/', 'DocumentController::index');

// Document routes
$routes->group('documents', function($routes) {
    $routes->get('/', 'DocumentController::index');
    $routes->get('upload', 'DocumentController::upload');
    $routes->post('store', 'DocumentController::store');
    $routes->get('view/(:num)', 'DocumentController::view/$1');
    $routes->get('download/(:num)', 'DocumentController::download/$1');
    $routes->get('delete/(:num)', 'DocumentController::delete/$1');
});
```

Routing ini mengatur semua URL pattern untuk aplikasi kita.

## Step 12: Testing dan Optimasi {#step-12-testing}

Sekarang jalankan aplikasi untuk testing:

```bash
php spark serve
```

Buka browser dan akses `http://localhost:8080`. Aplikasi Document Management System sudah siap digunakan!

### Testing Checklist

Lakukan testing untuk memastikan semua fitur berjalan dengan baik:

1. **Upload File**:
   - Coba upload berbagai jenis file (PDF, DOC, gambar)
   - Test validasi ukuran file (coba upload file > 10MB)
   - Test validasi format file (coba upload file dengan ekstensi yang tidak diizinkan)
2. **List Dokumen**:
   - Pastikan semua dokumen tampil dengan benar
   - Check icon sesuai dengan tipe file
   - Pagination berfungsi jika dokumen > 10
3. **Download File**:
   - Test download berbagai jenis file
   - Pastikan nama file yang didownload sesuai dengan nama original
4. **Delete File**:
   - Test hapus dokumen
   - Pastikan file terhapus dari server dan database
5. **View Detail**:
   - Check semua informasi tampil dengan benar
   - Preview gambar berfungsi untuk file gambar

## Kesimpulan dan Key Takeaway {#kesimpulan}

Selamat! Anda telah berhasil membuat sistem Document Management lengkap dengan CodeIgniter 4. Aplikasi ini memiliki semua fitur dasar yang diperlukan untuk mengelola dokumen dalam aplikasi web.

### Key Takeaway dari Tutorial Ini:

1. **File Upload Best Practices**
   - Selalu validasi file sebelum menyimpan (tipe, ukuran, ekstensi)
   - Gunakan nama file random untuk menghindari konflik dan masalah keamanan
   - Simpan file di luar web root jika memungkinkan untuk keamanan ekstra
2. **Database Integration**
   - Simpan metadata file di database untuk tracking yang lebih baik
   - Gunakan migration untuk version control struktur database
   - Manfaatkan Model validation untuk data integrity
3. **User Experience**
   - Implementasi drag & drop membuat upload lebih intuitif
   - Visual feedback (icon, progress) meningkatkan user experience
   - Konfirmasi sebelum delete mencegah kehilangan data tidak sengaja
4. **Security Considerations**
   - Validasi MIME type, bukan hanya ekstensi file
   - Batasi ukuran file untuk mencegah DOS attack
   - Gunakan CSRF protection untuk form submission
   - Sanitasi nama file untuk mencegah directory traversal
5. **Code Organization**
   - Pisahkan logic di Controller, data handling di Model, dan presentation di View
   - Gunakan helper method untuk formatting (seperti ukuran file)
   - Manfaatkan template layout untuk konsistensi UI

### Pengembangan Lebih Lanjut

Anda dapat mengembangkan aplikasi ini dengan menambahkan fitur:

- **User authentication** untuk tracking siapa yang upload
- **Kategori dokumen** untuk organisasi yang lebih baik
- **Search functionality** untuk mencari dokumen
- **File versioning** untuk track perubahan dokumen
- **Share links** untuk berbagi dokumen dengan expiry date
- **Bulk upload** untuk upload multiple files sekaligus
- **File compression** untuk menghemat storage
- **Preview PDF** menggunakan library seperti PDF.js
- **Access control** untuk membatasi akses dokumen tertentu

Tutorial ini memberikan fondasi yang kuat untuk membangun sistem manajemen dokumen yang lebih kompleks. Kode yang telah dibuat modular dan mudah untuk dikembangkan lebih lanjut sesuai kebutuhan proyek Anda.

Semoga tutorial ini bermanfaat dan selamat mengembangkan aplikasi Anda! Jangan lupa untuk selalu memperhatikan aspek keamanan dan user experience dalam setiap pengembangan fitur.

------

*Tutorial CodeIgniter 4: Upload dan Download File - Sebuah panduan lengkap untuk membangun sistem manajemen dokumen dengan CodeIgniter 4*