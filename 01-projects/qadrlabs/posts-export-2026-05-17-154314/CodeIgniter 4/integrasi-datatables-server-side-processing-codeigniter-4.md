---
title: "Integrasi DataTables Server Side processing CodeIgniter 4"
slug: "integrasi-datatables-server-side-processing-codeigniter-4"
category: "CodeIgniter 4"
date: "2021-02-27"
status: "published"
---

Salah satu plug-in jquery yang sering saya gunakan untuk menampilkan data di dalam table adalah DataTables. Plug-in ini biasa saya gunakan di framework CodeIgniter versi sebelumnya. Dan tentu ini menjadi salah satu pertanyaan saya ketika belajar framework CodeIgniter 4, Bagaimana cara integrasi DataTables server side processing di CodeIgniter 4? Dan seperti biasa tutorial ini adalah dokumentasi ketika berhasil mengintegrasikan DataTables di project CodeIgniter 4.

Seperti yang sudah disebutkan sebelumnya, DataTables ini plug-in untuk jquery. Plug-in ini sering digunakan untuk menambahkan fitur ke dalam table HTML, seperti pagination, searching, sorting data berdasarkan kolom dan lain-lain. Untuk penggunaan DataTables sendiri sebetulnya cukup mudah. Sebagai contoh, katakanlah kita punya table dengan id `user-table` dan di dalam tabel ini sudah terdapat data yang ditampilkan secara langsung atau client side. Kita bisa langsung menginisiasi DataTables[^1] seperti ini.

```javascript
 $('#user-table').DataTable();
```

Setelah inisiasi DataTables, secara default, semua fitur DataTables seperti searching, ordering dan paging secara otomatis langsung ditambahkan ke table hanya dengan satu baris kode di atas. 

Menggunakan DataTables secara langsung dengan jumlah data sedikit itu mungkin tidak akan terlihat masalah. Namun masalah itu akan muncul ketika jumlah data yang ditampilkan banyak. Sebagai solusi dari masalah ini, kita bisa menggunakan DataTables dengan opsi server side processing. 

Dengan mengaktifkan server-side processing[^2], semua paging, searching dan ordering yang dilakukan DataTables ditangani oleh server di mana SQL engine dapat melakukan operasi tersebut terhadap data set dengan jumlah yang besar. Setiap memproses pengambilan data di table akan menghasilkan request ajax yang baru untuk mengambil data yang diperlukan.

Di tutorial Integrasi DataTables server side processing di framework CodeIgniter 4 ini kita akan mempelajari cara membuat class model yang khusus menangani proses pengambilan data yang digunakan di DataTables, bagaimana cara instalasi DataTables melalui CDN, bagaimana cara menyiapkan data source untuk ditampilkan di dalam DataTables.

## Web App Overview {#overview}

Pada seri tutorial **[Belajar CodeIgniter 4](https://qadrlabs.com/series/belajar-codeigniter-4)** kali ini, kita akan membahas cara mengintegrasikan DataTables ke dalam aplikasi web menggunakan framework CodeIgniter 4. Dalam tutorial ini, kita akan mempelajari langkah-langkah untuk menerapkan *server-side processing* dengan DataTables, yang memungkinkan pengolahan data secara efisien di sisi server. 

Untuk mempermudah pemahaman, kita akan membuat sebuah proyek sederhana yang menampilkan daftar data pengguna (*user*). Pada halaman ini, Anda dapat menjelajahi berbagai fitur unggulan DataTables, seperti pencarian data (*searching*), pengurutan data berdasarkan kolom tertentu (*ordering*), serta menampilkan data sesuai dengan jumlah yang ditentukan melalui filter. Tutorial ini dirancang agar mudah dipraktikkan, bahkan bagi pemula sekalipun.

![web app overview](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/datatables/Selection_001.png)

Dengan mengikuti panduan ini, Anda tidak hanya akan memahami cara kerja DataTables, tetapi juga bagaimana mengoptimalkannya dalam aplikasi berbasis CodeIgniter 4. Yuk, mulai eksplorasi dan tingkatkan kemampuan Anda dalam membangun aplikasi web dinamis! 


## Persiapan{#persiapan}

Persiapan untuk mengikuti tutorial ini dapat kawan-kawan baca di [edisi tutorial sebelumnya](https://qadrlabs.com/post/database-seeder-codeigniter-4). Di mulai tahapan instalasi CodeIgniter 4 sampai menyiapkan sample data yang diperlukan di tutorial ini sudah dibahas di tutorial tersebut. Kalau belum coba tutorialnya, boleh dicoba dulu ya. 

Selain itu kawan-kawan perlu menyiapkan koneksi internet karena terdapat beberapa source js dan css seperti DataTables di akses melalui CDN.

## Step 1 - Membuat Model UserDatatable{#step-1}

Di task pertama ini kita akan membuat sebuah class Models yang akan menangani data untuk DataTables. Buka terminal, lalu kita generate file model kita menggunakan `spark` command.

```bash
php spark make:model UserDatatable
```

Output ketika command di atas kita run.

```bash
$ php spark make:model UserDatatable

CodeIgniter v4.3.7 Command Line Tool - Server Time: 2023-08-15 07:58:20 UTC+00:00

File created: APPPATH/Models/UserDatatable.php

```


Selanjutnya buka file `Models/UserDatatable.php`, lalu kita modifikasi dan tambahkan beberapa atribute untuk class `UserDatatable`.

```php
<?php

namespace App\Models;

use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\Model;

class UserDatatable extends Model
{
    protected $table = 'users';
    protected $column_order = ['id', 'name', 'email'];
    protected $column_search = ['name', 'email'];
    protected $order = ['id' => 'DESC'];
    protected $request;
    protected $db;
    protected $dt;

}
```

Karena di DataTables ada kebutuhan untuk menghandle Http request, seperti proses searching maupun sorting, kita akan menggunakan `RequestInterface` sebagai dependensi untuk class model `UserDatatable`. Tambahkan `RequestInterface` sebagai parameter di method `constructor`.

```php
<?php

namespace App\Models;

use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\Model;

class UserDatatable extends Model
{
    
    // [..baris kode sebelumnya...]

    public function __construct(RequestInterface $request)
    {
        parent::__construct();
        $this->db = db_connect();
        $this->request = $request;
        $this->dt = $this->db->table($this->table);
        
    }
}
```

Di DataTables, selain menampilkan data, juga menampilkan jumlah data keseluruhan dan jumlah data yang difilter. Selanjutnya kita tambahkan beberapa method yang akan menangani kebutuhan untuk DataTables.

```php
<?php

namespace App\Models;

use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\Model;

class UserDatatable extends Model
{
    
    // [ ... baris kode sebelumnya...]

    private function getDatatablesQuery()
    {
        $i = 0;
        foreach ($this->column_search as $item) {
            if ($this->request->getPost('search')['value']) {
                if ($i === 0) {
                    $this->dt->groupStart();
                    $this->dt->like($item, $this->request->getPost('search')['value']);
                } else {
                    $this->dt->orLike($item, $this->request->getPost('search')['value']);
                }
                if (count($this->column_search) - 1 == $i)
                    $this->dt->groupEnd();
            }
            $i++;
        }

        if ($this->request->getPost('order')) {
            $this->dt->orderBy($this->column_order[$this->request->getPost('order')['0']['column']], $this->request->getPost('order')['0']['dir']);
        } else if (isset($this->order)) {
            $order = $this->order;
            $this->dt->orderBy(key($order), $order[key($order)]);
        }
    }

    public function getDatatables()
    {
        $this->getDatatablesQuery();
        if ($this->request->getPost('length') != -1)
            $this->dt->limit($this->request->getPost('length'), $this->request->getPost('start'));
        $query = $this->dt->get();
        return $query->getResult();
    }

    public function countFiltered()
    {
        $this->getDatatablesQuery();
        return $this->dt->countAllResults();
    }

    public function countAll()
    {
        $tbl_storage = $this->db->table($this->table);
        return $tbl_storage->countAllResults();
    }
}
```

Jadi keseluruhan class `UserDatatable` seperti baris kode di bawah ini.

```php
<?php

namespace App\Models;

use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\Model;

class UserDatatable extends Model
{
    protected $table = 'users';
    protected $column_order = ['id', 'name', 'email'];
    protected $column_search = ['name', 'email'];
    protected $order = ['id' => 'DESC'];
    protected $request;
    protected $db;
    protected $dt;

    public function __construct(RequestInterface $request)
    {
        parent::__construct();
        $this->db = db_connect();
        $this->request = $request;
        $this->dt = $this->db->table($this->table);
        
    }

    private function getDatatablesQuery()
    {
        $i = 0;
        foreach ($this->column_search as $item) {
            if ($this->request->getPost('search')['value']) {
                if ($i === 0) {
                    $this->dt->groupStart();
                    $this->dt->like($item, $this->request->getPost('search')['value']);
                } else {
                    $this->dt->orLike($item, $this->request->getPost('search')['value']);
                }
                if (count($this->column_search) - 1 == $i)
                    $this->dt->groupEnd();
            }
            $i++;
        }

        if ($this->request->getPost('order')) {
            $this->dt->orderBy($this->column_order[$this->request->getPost('order')['0']['column']], $this->request->getPost('order')['0']['dir']);
        } else if (isset($this->order)) {
            $order = $this->order;
            $this->dt->orderBy(key($order), $order[key($order)]);
        }
    }

    public function getDatatables()
    {
        $this->getDatatablesQuery();
        if ($this->request->getPost('length') != -1)
            $this->dt->limit($this->request->getPost('length'), $this->request->getPost('start'));
        $query = $this->dt->get();
        return $query->getResult();
    }

    public function countFiltered()
    {
        $this->getDatatablesQuery();
        return $this->dt->countAllResults();
    }

    public function countAll()
    {
        $tbl_storage = $this->db->table($this->table);
        return $tbl_storage->countAllResults();
    }
}
```

Jangan lupa save filenya.

## Step 2 - Membuat Controller User{#step-2}

Tahapan selanjutnya adalah membuat class Controller. Buka kembali terminal lalu run `spark` command berikut ini.

```bash
php spark make:controller User 
```

Output ketika command di atas selesai dirun.

```bash
$ php spark make:controller User          

CodeIgniter v4.3.7 Command Line Tool - Server Time: 2023-08-15 08:00:28 UTC+00:00

File created: APPPATH/Controllers/User.php

```

Buka file `Controllers/User.php`. Pada class `User` kita akan menggunakan class `UserDatatable` dan juga `Config\Services` untuk menangani http request.

Selanjutnya kita modifikasi method `index()` yang digunakan untuk menampilkan halaman daftar user.

```php
<?php namespace App\Controllers;

use App\Models\UserDatatable;
use Config\Services;

class User extends BaseController
{
    public function index()
    {
        $data = [
            'title' => 'User List'
        ];

        return view('index', $data);
    }
}
```

Save file kembali file `Controllers/User.php`

## Step 3 - Membuat View{#step-3}

Kalau kita perhatikan kembali method `index()` di Controller `User` terdapat baris kode.

```php
return view('index', $data);
```

Itu artinya nama file viewnya itu `index.php`.

Kita buat file baru di `app\Views` namanya `index.php`. Lengkapi kode untuk file `index.php` menjadi seperti di bawah ini.

```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta name="<?= csrf_token() ?>" content="<?= csrf_hash() ?>">
    <title><?= $title; ?></title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css" integrity="sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh" crossorigin="anonymous">

    <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/v/bs4/dt-1.10.23/datatables.min.css" />
</head>

<body>

    <!-- Content -->
    <div class="container mt-5">
        <div class="row">
            <div class="col-md-12">
                <div class="card">
                    <div class="card-header">
                        User
                        <a href="" class="btn btn-primary btn-sm float-right">New Record</a>
                    </div>
                    <div class="card-body">

                        <table id="user-table" class="table table-striped table-bordered table-hover">
                            <thead>
                                <tr>
                                    <td>No</td>
                                    <td>Nama</td>
                                    <td>Email</td>
                                </tr>
                            </thead>
                            <tbody>
                            </tbody>
                        </table>

                    </div>

                </div>
            </div>
        </div>
    </div>


    <!-- /.Content -->

    <footer class="text-center mt-5">
        <p><em><small>Seri Tutorial CodeIgniter 4: Integrasi Datatable CodeIgniter @ <a href="https://qadrlabs.com/">qadrLabs</a></small></em></p>
    </footer>

    <script type="text/javascript" language="javascript" src="https://code.jquery.com/jquery-3.5.1.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js" integrity="sha384-Q6E9RHvbIyZFJoft+2mJbHaEWldlvI9IOYy5n3zV9zzTtmI3UksdQRVvoxMfooAo" crossorigin="anonymous"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js" integrity="sha384-wfSDF2E50Y2D1uUdj0O3uMBJnjuUD4Ih7YwaYd1iqfktj0Uod8GCExl3Og8ifwB6" crossorigin="anonymous"></script>
    <script type="text/javascript" src="https://cdn.datatables.net/v/bs4/dt-1.10.23/datatables.min.js"></script>

    <script type="text/javascript">
        $(document).ready(function() {
            var table = $('#user-table').DataTable({
                "processing": true,
                "serverSide": true,
                "order": [],
                "ajax": {
                    "url": "<?php echo site_url('user/ajaxList') ?>",
                    "type": "POST"
                },
                "columnDefs": [{
                    "targets": [],
                    "orderable": false,
                }, ],
            });
        });
    </script>

</body>
</html>
```

Kalau sudah selesai, jangan lupa save filenya.

## Step 4 - Menyiapkan data source{#step-4}

Tahapan terakhir adalah membuat method untuk meng-handle proses mengambil data `user` sebagai data source untuk DataTables.

Buka kembali file `Controllers/User.php`. Di dalam class `User`, tambahkan method baru dengan nama `ajaxList()` lalu tambahkan kode berikut ini.

```php
<?php namespace App\Controllers;

use App\Models\UserDatatable;
use Config\Services;

class User extends BaseController
{
    // [ ... baris kode sebelumnya ]

    public function ajaxList()
    {
        $request = Services::request();
        $datatable = new UserDatatable($request);

        if ($request->getMethod(true) === 'POST') {
            $lists = $datatable->getDatatables();
            $data = [];
            $no = $request->getPost('start');

            foreach ($lists as $list) {
                $no++;
                $row = [];
                $row[] = $no;
                $row[] = $list->name;
                $row[] = $list->email;
                $data[] = $row;
            }

            $output = [
                'draw' => $request->getPost('draw'),
                'recordsTotal' => $datatable->countAll(),
                'recordsFiltered' => $datatable->countFiltered(),
                'data' => $data
            ];

            echo json_encode($output);
        }
    }
}
```

Save kembali file `Controllers/User.php`.

Nah semua task sudah kita selesaikan, langkah selanjutnya adalah menguji coba.

## Step 5 - Definisikan Route{#step-5}

Sekarang kita definisikan route untuk menampilkan halaman daftar user dan untuk resourse ajax nya. Buka file `app/Config/Routes.php`, lalu temukan baris kode berikut ini.

```php
$routes->get('/', 'Home::index');
```

Tepat di bawah route di atas, kita definisikan dua route baru.

```php
$routes->get('/user', 'User::index');
$routes->post('user/ajaxList', 'User::ajaxList');
```

Save kembali file `Routes.php`.

## Uji Coba{#uji-coba}

Ada beberapa fitur DataTables yang akan kita uji coba, yaitu menampilkan, pagination, searching, dan sorting. Apakah Integrasi Datatables Server Side processing bisa berjalan baik? Yuk kita mulai.

Seperti biasa, sebelum menguji coba tentu kita harus running dulu web yang sudah kita buat. Buka terminal lalu kita running web menggunakan command:

```bash
php spark serve
```

Selanjutnya buka browser, ketik url di addressbar. Di browser bisa kita lihat DataTables bisa berjalan dengan baik.

```
http://localhost:8080/user
```

![Uji coba](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/datatables/Selection_001.png)

Pengujian Selanjutnya adalah kita tes paginationnya. Untuk menguji pagination, di sini kita coba buka halaman ke dua. Kita tekan nomer 2 di paging-nya.

![uji coba pagination](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/datatables/Selection_002.png)

Yep, di gambar di atas, bisa kita lihat paginationnya juga berjalan baik. Kawan, kamu bisa coba buka halaman lain juga.

Selanjutnya kita coba searching, karena di data ada nama `raisa`, di sini kita coba isi dengan nama `raisa`.

![uji coba searching](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/datatables/Selection_003.png)

Nah bisa kita lihat tampil (satu) data dengan nama `raisa` (abaikan emailnya ya, soalnya memang random kalau pakai library faker).

Selanjutnya kita coba ubah jumlah data yang ditampilkan, misalkan jadi 25.

![uji coba limit](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/datatables/Selection_004.png)

![uji coba limit](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/datatables/Selection_005.png)

Kawan, bisa dilihat di dua gambar di atas, data yang ditampilkan menjadi 25.

Nah tes selanjutnya kita coba sorting data berdasarkan nama. Di sini kita coba sorting secara ascending dan descending. Dan hasilnya...

![uji coba sorting](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/datatables/Selection_006.png)

![uji coba sorting](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/datatables/Selection_007.png)

Ya, bisa kita lihat di dua gambar di atas, order berdasarkan nama untuk ascending dan descending juga berjalan baik.

Di tutorial ini kita sudah belajar bagaimana cara mengintegrasikan DataTables untuk pemrosesan dari sisi server atau server side processing di CodeIgniter 4. Setelah pengujian, fitur DataTables seperti pagination, searching dan sorting data juga dapat berjalan dengan baik di CodeIgniter 4. 

Salah satu poin yang dapat dikembangkan adalah bagian method di model class untuk DataTables. Method yang digunakan di model untuk menangani proses mengambil data dan menangani fitur seperti searching dan sorting itu relatif lumayan panjang. Bagian ini bisa kita buat class terpisah khusus DataTables atau bisa juga dibuat sebagai library supaya dapat dipakai secara berulang. Hmmm, menarik bukan?

Sampai jumpa lagi di edisi tutorial berikutnya... Semoga bermanfaat dan tetap semangat berkarya ya! ^^

---

Serial Tutorial [Belajar CodeIgniter 4](https://qadrlabs.com/series/belajar-codeigniter-4) ini berisi tentang tutorial pengembangan aplikasi menggunakan framework CodeIgniter 4. Selain untuk mengikat ilmu, serial ini juga dibuat agar saya dan teman-teman bisa sama-sama belajar.




### Referensi{#referensi}

[^1]: Manual DataTables tentang instalasi @ [Installation](https://datatables.net/manual/installation)
[^2]: Manual DataTables tentang Server-side processing @ [Server-side processing](https://datatables.net/examples/server_side/)