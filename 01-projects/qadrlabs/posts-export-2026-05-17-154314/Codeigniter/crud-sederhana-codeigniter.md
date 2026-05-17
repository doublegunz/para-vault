---
title: "CRUD Sederhana CodeIgniter"
slug: "crud-sederhana-codeigniter"
category: "Codeigniter"
date: "2016-02-07"
status: "published"
---

Dalam perjalanan pengembangan aplikasi web modern, salah satu konsep fundamental yang selalu menjadi pondasi adalah CRUD (Create, Read, Update, Delete). Setelah memahami [dasar-dasar CodeIgniter](https://qadrlabs.com/post/tutorial-dasar-codeigniter-untuk-pemula) di tutorial sebelumnya, saatnya kita melangkah lebih jauh dengan mengimplementasikan operasi database yang esensial ini.

Tutorial ini merupakan bagian kedua dari [series Belajar CodeIgniter 3](https://qadrlabs.com/series/belajar-codeigniter-3), di mana kita akan fokus pada pengembangan sistem manajemen data mahasiswa. Pengalaman saya mengajar di berbagai institusi menunjukkan bahwa memahami CRUD melalui studi kasus nyata seperti ini dapat mempercepat proses pembelajaran secara signifikan.

Bayangkan CRUD seperti empat operasi dasar dalam mengelola informasi - layaknya cara kita mengelola catatan dalam kehidupan sehari-hari: mencatat (Create), membaca (Read), memperbarui (Update), dan menghapus (Delete). Dalam konteks pengembangan web dengan CodeIgniter, kita akan melihat bagaimana konsep sederhana ini dapat diimplementasikan menjadi sistem yang robust dan terstruktur.

Tutorial ini dirancang dengan pendekatan step-by-step yang sistematis, cocok untuk pemula yang ingin memahami implementasi CRUD dalam CodeIgniter 3. Kita akan membahas mulai dari persiapan environment, konfigurasi database, hingga implementasi setiap komponen CRUD dengan best practices yang sesuai standar industri.

Melalui studi kasus sistem manajemen data mahasiswa, Anda akan mempelajari:
- Implementasi pola MVC dalam konteks nyata
- Pengelolaan database dengan Query Builder
- Form handling dan validasi
- Best practices dalam pengembangan aplikasi CRUD

Mari kita mulai perjalanan membangun aplikasi web yang lebih dinamis dengan CodeIgniter 3!

## Persiapan Development Environment {#persiapan}
Sebelum memulai pengembangan aplikasi CRUD dengan CodeIgniter 3, kita perlu memastikan environment development yang tepat. Persiapan yang baik akan menghindarkan kita dari masalah teknis yang mungkin muncul di tengah pengembangan.

### Requirements Dasar
Berikut adalah spesifikasi minimum yang diperlukan untuk tutorial ini:

* **Web Server**: Apache 2.4+
* **PHP**: Versi 5.5.35 atau lebih tinggi
* **Database**: MySQL/MariaDB
* **Framework**: CodeIgniter 3.1.0

Cara termudah untuk memenuhi kebutuhan server di atas adalah dengan menginstal XAMPP versi 5.5.35, yang sudah mencakup Apache, PHP, dan MySQL dalam satu paket instalasi.

### Instalasi CodeIgniter

1. Download CodeIgniter 3
   - Kunjungi [website resmi CodeIgniter](https://codeigniter.com/)
   - Pilih versi 3.1.0 (pastikan bukan versi 4)

2. Setup Project
   ```bash
   # Ekstrak file CodeIgniter
   # Pindahkan ke webroot
   C:\xampp\htdocs\
   
   # Rename folder menjadi
   crud_ci
   ```

### Verifikasi Instalasi

Pastikan semua komponen berjalan dengan baik:
- XAMPP Control Panel menunjukkan Apache dan MySQL running
- Folder project sudah berada di lokasi yang tepat
- Permission folder sudah sesuai

Dengan environment yang sudah siap, kita bisa melanjutkan ke tahap berikutnya yaitu konfigurasi database dan implementasi fitur CRUD.


## Membuat Database{#membuat-database}
Nah, sekarang buka phpMyAdmin, lalu kita buat database dengan nama ```dbci3```. Selanjutnya, kita buat tabel dengan nama ```tabel_mahasiswa```.  Nah, untuk membuat tabel, klik menu SQL di phpMyAdmin, lalu run perintah SQL di bawah ini:

```sql
CREATE TABLE `tabel_mahasiswa` ( 
    `id` int(10) NOT NULL AUTO_INCREMENT,  
    `nim` varchar(15) NOT NULL,  
    `nama` varchar(30) NOT NULL,  
    `jenis_kelamin` enum('PRIA','WANITA') NOT NULL,  
    `tempat_lahir` varchar(50) NOT NULL,  
    `tanggal_lahir` date NOT NULL,  
    `alamat` varchar(100) NOT NULL,  
    PRIMARY KEY (`id`) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
```
![Eksekusi perintah](https://2.bp.blogspot.com/-2co9LoGFjho/V_LCWKaifoI/AAAAAAAAAgA/DqSZxr56beAhDdX6r9lojkTZqQxjpCZ_wCEw/s1600/Simple-CRUD-CodeIgniter-gambar%2B1.jpg)

Klik tombol 'go' di kanan bawah untuk running perintah SQL di atas. Nah, kita berhasil membuat tabel_mahasiswa dan di bawah ini adalah struktur tabelnya:

![Struktur tabel_mahasiswa](https://1.bp.blogspot.com/-OAqpxBbqs5k/V_LCXsglbDI/AAAAAAAAAgQ/bKe1imwbqV4slTQQzjHJnJ0UpJWO0ZtQACEw/s1600/Simple-CRUD-CodeIgniter-gambar%2B2.jpg)

## Konfigurasi Database dan Base Url{#konfigurasi-db}
Langkah Selanjutnya adalah konfigurasi base_url dari aplikasi web yang sedang dibangun. Di dalam contoh ini digunakan localhost, dalam aplikasi sesungguhnya, nanti diubah menjadi alamat website (Misalkan ```https://gungunpriatna.com```).

Nah, sekarang buka text editor kesayanganmu. Lalu buka file ```config.php``` yang ada di direktori ```crud_ci/application/config```.

Cek line ke 26, ubah:

```php
$config['base_url'] = '';
```

menjadi:

```php
$config['base_url'] = 'http://localhost/crud_ci';
```

Save kembali file ```config.php```.

Setelah konfigurasi base url, selanjutnya adalah mengatur konfigurasi database. Nah, sekarang buka kembali teks editor kesayanganmu, lalu buka file ```database.php```, masih di direktori yang sama kaya file ```config.php```, yaitu ```crud_ci/application/config```. Cek line 76, lalu isi konfigurasi database seperti gambar di bawah ini:

```php
$db['default'] = array(
	'dsn'	=> '',
	'hostname' => 'localhost',
	'username' => 'root',
	'password' => '',
	'database' => 'dbci3',
	'dbdriver' => 'mysqli',
	'dbprefix' => '',
	'pconnect' => FALSE,
	'db_debug' => (ENVIRONMENT !== 'production'),
	'cache_on' => FALSE,
	'cachedir' => '',
	'char_set' => 'utf8',
	'dbcollat' => 'utf8_general_ci',
	'swap_pre' => '',
	'encrypt' => FALSE,
	'compress' => FALSE,
	'stricton' => FALSE,
	'failover' => array(),
	'save_queries' => TRUE
);
```


Kalau sudah selesai, save kembali file ```database.php```.

Langkah berikutnya adalah menghubungkan database yang sudah kita atur konfigurasinya dengan cara mengaktifkan library database. Library database ini yang nantinya digunakan untuk menangani segala aktifitas yang berhubungan dengan database dalam Framework CodeIgniter.

Untuk mengaktifkan library database, buka file ```autoload.php``` di dalam direktori ```crud_ci/application/config```. Cek line ke 61, lalu isi array dengan database.

```php
$autoload['libraries'] = array('database');
```


## Read Data Mahasiswa{#read-data}
Baik setelah persiapan development selesai, sekarang kita mulai masuk ke studi kasusnya teman-teman. Pada tahapan ini, kita akan ngoding untuk fitur menampilkan data mahasiswa. Sesuai dengan konsep MVC, kita akan membuat beberapa file, yaitu:
* File Model dengan nama ```Mahasiswa_model.php```
* File Views dengan nama ```mahasiswa/index.php```,  (yep, nanti kita buat folder baru di dalam direktori ```crud_ci/application/views``` dengan nama ```mahasiswa```).
* File Controller dengan nama ```Mahasiswa.php```.


Sekarang kita buat dulu file model dengan nama ```Mahasiswa_model.php```. Buka kembali teks editor kesayanganmu lalu ketik script di bawah ini.

```php
<?php
defined('BASEPATH') or exit('No direct script access allowed');
class Mahasiswa_model extends CI_Model
{
	function get()
	{
		//SELECT * FROM tabel_mahasiswa
		return $this->db->get('tabel_mahasiswa');
	}

}
```

Kalau sudah diketik, save file dengan nama ```Mahasiswa_model.php``` di direktori ```crud_ci/application/models```.

Selanjutnya kita buat dulu folder baru dengan nama ```mahasiswa``` didalam direktori ```crud_ci/application/views```.

Langkah selanjutnya kita buat file view untuk menampilkan data mahasiswa dengan nama ```index.php```, nanti kita simpan file tersebut di dalam folder ```mahasiswa``` yang sudah kita buat. Nah sekarang silakan ketik kode di bawah ini.

```php
<?php defined('BASEPATH') or exit('No direct script access allowed'); ?>

<!DOCTYPE html>
<html>

<head>
	<title>Tampil Data Mahasiswa</title>
</head>

<body>

	<H3>Data Mahasiswa</H3>
	<table border=1 width=80% cellpadding=2 cellspacing=0>
		<tr bgcolor=silver align=center>
			<td>Nim</td>
			<td>Nama</td>
			<td>Jenis Kelamin</td>
			<td>Tempat Lahir</td>
			<td>Tanggal Lahir</td>
			<td>Alamat</td>
			<td colspan=2>AKSI</td>
		</tr>
		<?php
		if ($jumlah_data > 0) {


			foreach ($mahasiswa as $row) { ?>
				<tr align=center>
					<td><?php echo $row['nim']; ?></td>
					<td><?php echo $row['nama']; ?></td>
					<td><?php echo $row['jenis_kelamin']; ?></td>
					<td><?php echo $row['tempat_lahir']; ?></td>
					<td><?php echo $row['tanggal_lahir']; ?></td>
					<td><?php echo $row['alamat']; ?></td>
					<td><a href="<?php echo base_url(); ?>index.php/mahasiswa/edit/<?php echo $row['nim']; ?>">Edit</a></td>
					<td><a href="<?php echo base_url(); ?>index.php/mahasiswa/hapus/<?php echo $row['nim']; ?>" onclick="return confirm('Apakah anda yakin ingin menghapus data ini?');">Delete</a></td>
				</tr>
			<?php
			}
		} else { ?>
			<tr align='center'>
				<td colspan=7>Data Mahasiswa kosong</td>
			</tr>
		<?php } ?>

	</table>
	<p>Jumlah data : <?php echo $jumlah_data; ?> [<a href="<?php echo base_url(); ?>index.php/mahasiswa/create">Tambah Data</a>] </p>
</body>

</html>
```

Kalau sudah diketik, save file dengan nama ```index.php``` di direktori ```crud_ci/application/views/mahasiswa```.



Oke, selanjutnya kita buat file Controller dengan nama ```Mahasiswa.php```. Sekarang buka kembali teks editor kesayanganmu, lalu ketik script di bawah ini ya~...

```php
<?php
defined('BASEPATH') or exit('No direct script access allowed');
class Mahasiswa extends CI_Controller
{
	function __construct()
	{
		parent::__construct();
		//load helper
		$this->load->helper('url');
		$this->load->helper('form');
		//load library  
		$this->load->library('form_validation');
		//load model 
		$this->load->model('mahasiswa_model');
	}
	
	public function index()
	{
		//ambil data dari database
		$getData = $this->mahasiswa_model->get();

		$data = [
			'mahasiswa' => $getData->result_array(),
			'jumlah_data' => $getData->num_rows()
		];
		
		//menampilkan view
		$this->load->view('mahasiswa/index', $data);
	}

}
```
Okee, kita save file Controller kita dengan nama ```Mahasiswa.php``` di direktori ```crud_ci/application/controllers```.


## Create Data Mahasiswa{#create-data}
Fitur selanjutnya adalah fitur untuk menambahkan data mahasiswa ke dalam tabel di dalam database. Dalam membuat fitur ini ada beberapa tahapan, yaitu:
1. Menambahkan *method* untuk insert data di dalam file Model ```Mahasiswa_model.php```.
2. Membuat dua file view baru dengan nama ```add.php``` dan ```notifikasi.php``` di dalam direktori ```crud_ci/application/views/mahasiswa```.
3. Menambahkan *method* untuk menampilkan form insert data di dalam file controller ```Mahasiswa.php```
   
Baik, sekarang kita buka kembali file model ```Mahasiswa_model.php```. Lalu tambahkan method ```insert()``` di dalam Class ```Mahasiswa_model```. 

```php
	
	function insert($data)
	{
		//insert data ke dalam tabel
		$this->db->insert('tabel_mahasiswa', $data);
	}

```

Sehingga file ```Mahasiswa_model.php``` menjadi seperti di bawah ini.

```php
<?php
defined('BASEPATH') or exit('No direct script access allowed');
class Mahasiswa_model extends CI_Model
{
	function get()
	{
		//SELECT * FROM tabel_mahasiswa
		return $this->db->get('tabel_mahasiswa');
	}

	function insert($data)
	{
		//insert data ke dalam tabel
		$this->db->insert('tabel_mahasiswa', $data);
	}

}
```

Save kembali file ```Mahasiswa_model.php```.

Langkah selanjutnya kita buat file baru untuk menampilkan form insert data mahasiswa di dalam direktori ```application/views/mahasiswa``` dengan nama ```add.php```. Buka kembali teks editor kesayanganmu, lalu ketik script di bawah ini yaa~..

```php
<?php defined('BASEPATH') or exit('No direct script access allowed'); ?>
<!DOCTYPE html>
<html>

<head>
	<title>TAMBAH DATA MAHASISWA</title>
</head>

<body>
	<?php echo form_open('mahasiswa/create'); ?>
	<table border=0 width="45%" cellpadding="5" cellspacing="0">
		<tr bgcolor="silver">
			<td Colspan="3" align="center">
				<H3>DATA MAHASISWA</H3>
			</td>
		</tr>
		<tr>
			<td>NIM</td>
			<td>:</td>
			<td><input type="text" name="nim" value="<?php echo set_value('nim'); ?>" size="50"><?php echo form_error('nim'); ?></td>
		</tr>
		<tr>
			<td>Nama</td>
			<td>:</td>
			<td><input type="text" name="nama" value="<?php echo set_value('nama'); ?>" size="50"><?php echo form_error('nama'); ?></td>
		</tr>
		<tr>
			<td>Jenis Kelamin</td>
			<td>:</td>
			<td>
				<input type="radio" name="jeniskelamin" checked value="PRIA">PRIA
				<input type="radio" name="jeniskelamin" value="WANITA">WANITA
			</td><?php echo form_error('jeniskelamin'); ?>
		</tr>
		<tr>
			<td>Tempat Lahir</td>
			<td>:</td>
			<td><input type="text" name="tempat_lahir" value="<?php echo set_value('tempat_lahir'); ?>" size="50"><?php echo form_error('tempat_lahir'); ?></td>
		</tr>
		<tr>
			<td>Tanggal lahir</td>
			<td>:</td>
			<td><input type="text" name="tanggal_lahir" value="<?php echo set_value('tanggal_lahir'); ?>" size="50"><?php echo form_error('tanggal_lahir'); ?></td>
		</tr>
		<tr>
			<td></td>
			<td></td>
			<td><em>Format tanggal yyyy-mm-dd contoh: 1996-12-15</em></td>
		</tr>
		<tr>
			<td>Alamat</td>
			<td>:</td>
			<td><textarea name="alamat" rows="2" value="<?php echo set_value('alamat'); ?>" cols="52"></textarea><?php echo form_error('alamat'); ?></td>
		</tr>
		<tr align="center">
			<td colspan="3">
				<input type="submit" value="TAMBAH">
				<input type="reset" value="BATAL">
				[<a href="<?php echo base_url(); ?>index.php/mahasiswa">Lihat Data Mahasiswa</a>]
			</td>
		</tr>
	</table>
	<?php echo form_close(); ?>

</body>

</html>
```
Kalau sudah selesai, jangan lupa simpan file ```add.php```.

Selanjutnya kita buat file view dengan nama ```notifikasi.php```. Lalu ketik script di bawah ini.

```php
<?php defined('BASEPATH') or exit('No direct script access allowed'); ?>
<!doctype html>
<html>

<head>
	<title>DATA MAHASISWA</title>
</head>

<body>
	<p><?php echo $msg; ?></p>
	<p><?php echo anchor('mahasiswa', 'Kembali'); ?></p>

</body>

</html>

```
Yep, simpan file ```notifikasi.php``` di direktori yang sama kaya file ```add.php``` yaitu, direktori ```application/views/mahasiswa``` ya..

Okee, selanjutnya kita akan menambahkan *method* baru untuk memproses penyimpanan data mahasiswa di dalam file controller ```Mahasiswa.php```. Sekarang buka kembali file ```Mahasiswa.php``` dengan teks editor kesayanganmu, lalu tambahkan *method* ```create()``` di dalam *class* ```Mahasiswa```.

```php
	public function create()
	{
		//rule validasi
		$validation_rules = [
			[
				'field' => 'nim',
				'label' => 'NIM',
				'rules' => 'required'
			],
			[
				'field' => 'nama',
				'label' => 'Nama',
				'rules' => 'required'
			],
			[
				'field' => 'jeniskelamin',
				'label' => 'Jenis Kelamin',
				'rules' => 'required'
			],
			[
				'field' => 'tempat_lahir',
				'label' => 'Tempat Lahir',
				'rules' => 'required'
			],
			[
				'field' => 'tanggal_lahir',
				'label' => 'Tanggal Lahir',
				'rules' => 'required'
			],
			[
				'field' => 'alamat',
				'label' => 'Alamat',
				'rules' => 'required'
			]
		];
		
		//set rule validasi
		$this->form_validation->set_rules($validation_rules);

		if ($this->form_validation->run() === FALSE) {
			$this->load->view('mahasiswa/add');
		} else {

			//data mahasiswa
			$mahasiswa = [
				'nim' => $this->input->post('nim'),
				'nama' => $this->input->post('nama'),
				'tempat_lahir' => $this->input->post('tempat_lahir'),
				'tanggal_lahir' => $this->input->post('tanggal_lahir'),
				'jenis_kelamin' => $this->input->post('jeniskelamin'),
				'alamat' => $this->input->post('alamat')
			];
			
			$this->mahasiswa_model->insert($mahasiswa);

			$data['msg']  =  'Data berhasil disimpan';

			$this->load->view('mahasiswa/notifikasi', $data);
		}
	}

```

Sehingga, nanti isi file controller ```Mahasiswa.php``` menjadi:

```php
<?php
defined('BASEPATH') or exit('No direct script access allowed');
class Mahasiswa extends CI_Controller
{
	function __construct()
	{
		parent::__construct();
		//load helper
		$this->load->helper('url');
		$this->load->helper('form');
		//load library  
		$this->load->library('form_validation');
		//load model 
		$this->load->model('mahasiswa_model');
	}
	public function index()
	{
		//ambil data dari database
		$getData = $this->mahasiswa_model->get();

		$data = [
			'mahasiswa' => $getData->result_array(),
			'jumlah_data' => $getData->num_rows()
		];
		
		//menampilkan view
		$this->load->view('mahasiswa/index', $data);
	}

	public function create()
	{
		//rule validasi
		$validation_rules = [
			[
				'field' => 'nim',
				'label' => 'NIM',
				'rules' => 'required'
			],
			[
				'field' => 'nama',
				'label' => 'Nama',
				'rules' => 'required'
			],
			[
				'field' => 'jeniskelamin',
				'label' => 'Jenis Kelamin',
				'rules' => 'required'
			],
			[
				'field' => 'tempat_lahir',
				'label' => 'Tempat Lahir',
				'rules' => 'required'
			],
			[
				'field' => 'tanggal_lahir',
				'label' => 'Tanggal Lahir',
				'rules' => 'required'
			],
			[
				'field' => 'alamat',
				'label' => 'Alamat',
				'rules' => 'required'
			]
		];
		
		//set rule validasi
		$this->form_validation->set_rules($validation_rules);

		if ($this->form_validation->run() === FALSE) {
			$this->load->view('mahasiswa/add');
		} else {

			//data mahasiswa
			$mahasiswa = [
				'nim' => $this->input->post('nim'),
				'nama' => $this->input->post('nama'),
				'tempat_lahir' => $this->input->post('tempat_lahir'),
				'tanggal_lahir' => $this->input->post('tanggal_lahir'),
				'jenis_kelamin' => $this->input->post('jeniskelamin'),
				'alamat' => $this->input->post('alamat')
			];
			
			$this->mahasiswa_model->insert($mahasiswa);

			$data['msg']  =  'Data berhasil disimpan';

			$this->load->view('mahasiswa/notifikasi', $data);
		}
	}

}

```

Jangan lupa save kembali file ```Mahasiswa.php``` yaaa..

Ok, next ...

## Update Data Mahasiswa{#update-data}
Fitur selanjutnya adalah fitur untuk memperbaharui data mahasiswa. Tahapan dalam membuat fitur ini adalah:
1. Menambahkan *method* di dalam model ```Mahasiswa_model.php``` yaitu *method* ```get_by_nim()``` untuk mengambil data mahasiswa berdasarkan nim dan *method* ```update()``` untuk memperbaharui data mahasiswa.
2. Membuat file view baru dengan nama ```edit.php``` di dalam direktori ```crud_ci/application/views/mahasiswa```.
3. Menambahkan *method* di dalam controller ```Mahasiswa.php```

Nah, sekarang kita buka kembali file model kita, yaitu ```Mahasiswa_model.php```. Lalu tambahkan *method* ```get_by_nim()``` dan method ```update()``` di dalam class ```Mahasiswa_model```.

```php
	function get_by_nim($nim)
	{
		//SELECT * FROM tabel_mahasiswa WHERE nim=$nim
		$this->db->where('nim', $nim);
		$this->db->from('tabel_mahasiswa');
		return $this->db->get();
	}

	function update($data, $where)
	{
		$this->db->where($where);
		$this->db->update('tabel_mahasiswa', $data);
	}
```

sehingga file model kita pada tahapan ini menjadi seperti script di bawah ini...
```php
<?php
defined('BASEPATH') or exit('No direct script access allowed');
class Mahasiswa_model extends CI_Model
{
	function get()
	{
		//SELECT * FROM tabel_mahasiswa
		return $this->db->get('tabel_mahasiswa');
	}

	function get_by_nim($nim)
	{
		//SELECT * FROM tabel_mahasiswa WHERE nim=$nim
		$this->db->where('nim', $nim);
		$this->db->from('tabel_mahasiswa');
		return $this->db->get();
	}

	function insert($data)
	{
		//insert data ke dalam tabel
		$this->db->insert('tabel_mahasiswa', $data);
	}
	
	function update($data, $where)
	{
		$this->db->where($where);
		$this->db->update('tabel_mahasiswa', $data);
	}
}
```
Kalau sudah diketik, jangan lupa save lagi file ```Mahasiswa_model.php``` nya yaa.

Nah selanjutnya buat file view untuk menampilkan form edit data mahasiswa.

Buat file baru dengan nama ```edit.php``` di dalam direktori ```crud_ci/application/views/mahasiswa```. Lalu ketik script di bawah ini.
```php
<?php defined('BASEPATH') or exit('No direct script access allowed'); ?>

<!DOCTYPE html>
<html>

<head>
	<title>edit Data Mahasiswa</title>
</head>

<body>

	<?php echo form_open('mahasiswa/update'); ?>
	<table border=0 width="45%" cellpadding="5" cellspacing="0">
		<tr bgcolor="silver">
			<td Colspan="3" align="center">
				<H3>DATA MAHASISWA</H3>
			</td>
		</tr>
		<tr>
			<td>NIM</td>
			<td>:</td>
			<td><input type="text" name="nim" value="<?php echo $mahasiswa['nim']; ?>" size="50"><?php echo form_error('nim'); ?></td>
		</tr>
		<tr>
			<td>Nama</td>
			<td>:</td>
			<td><input type="text" name="nama" value="<?php echo $mahasiswa['nama']; ?>" size="50"><?php echo form_error('nama'); ?></td>
		</tr>
		<tr>
			<td>Jenis Kelamin</td>
			<td>:</td>
			<td>
				<input type="radio" name="jeniskelamin" <?php if ($mahasiswa['jenis_kelamin'] == 'PRIA') {
															echo 'checked';
														} ?> value="PRIA">PRIA
				<input type="radio" name="jeniskelamin" <?php if ($mahasiswa['jenis_kelamin'] == 'WANITA') {
															echo 'checked';
														} ?> value="WANITA">WANITA
			</td><?php echo form_error('jeniskelamin'); ?>
		</tr>
		<tr>
			<td>Tempat Lahir</td>
			<td>:</td>
			<td><input type="text" name="tempat_lahir" value="<?php echo $mahasiswa['tempat_lahir']; ?>" size="50"><?php echo form_error('tempat_lahir'); ?></td>
		</tr>
		<tr>
			<td>Tanggal lahir</td>
			<td>:</td>
			<td><input type="text" name="tanggal_lahir" value="<?php echo $mahasiswa['tanggal_lahir']; ?>" size="50"><?php echo form_error('tanggal_lahir'); ?></td>
		</tr>
		<tr>
			<td></td>
			<td></td>
			<td>Format tanggal yyyy-mm-dd contoh: 1996-12-15</td>
		</tr>
		<tr>
			<td>Alamat</td>
			<td>:</td>
			<td><textarea name="alamat" rows="2" cols="52"><?php echo $mahasiswa['alamat']; ?></textarea><?php echo form_error('alamat'); ?></td>
		</tr>
		<tr align="center">
			<td colspan="3">
				<button type="submit" value="update" name="update">Update</button>
				<button type="reset">Reset</button>
				[<a href="<?php echo base_url(); ?>index.php/mahasiswa">Lihat Data Mahasiswa</a>]
			</td>
		</tr>
	</table>
	<?php echo form_close(); ?>

</body>

</html>

```
Save file ```edit.php```.

Selanjutnya, kita buka kembali file controller ```Mahasiswa.php``` dengan teks editor. Lalu tambahkan *method* ```edit()``` dan ```update()``` di dalam *class ```Mahasiswa```
```php
public function edit($nim = '')
	{
		//Cek apakah ada parameter $nim
		if ('' == $nim) {
			//jika tidak ada, maka alihkan ke halaman daftar mahasiswa
			redirect('mahasiswa');
		}
		//ambil data mahasisa berdasarkan nim
		$data['mahasiswa'] =  $this->mahasiswa_model->get_by_nim($nim)->row_array();
		//load form edit
		$this->load->view('mahasiswa/edit', $data);
	}

	public function update()
	{
		//cek apakah tombol update ditekan
		if ($this->input->post('update')) {
			$nim = $this->input->post('nim');

			//rule validasi
			$validation_rules = [
				[
					'field' => 'nim',
					'label' => 'NIM',
					'rules' => 'required'
				],
				[
					'field' => 'nama',
					'label' => 'Nama',
					'rules' => 'required'
				],
				[
					'field' => 'jeniskelamin',
					'label' => 'Jenis Kelamin',
					'rules' => 'required'
				],
				[
					'field' => 'tempat_lahir',
					'label' => 'Tempat Lahir',
					'rules' => 'required'
				],
				[
					'field' => 'tanggal_lahir',
					'label' => 'Tanggal Lahir',
					'rules' => 'required'
				],
				[
					'field' => 'alamat',
					'label' => 'Alamat',
					'rules' => 'required'
				]
			];

			//set rule validasi
			$this->form_validation->set_rules($validation_rules);

			if ($this->form_validation->run() === false) {
				redirect('mahasiswa/edit/' . $nim);
			}

			$where['nim'] = $nim;

			//data mahasiswa
			$mahasiswa = [
				'nim' => $this->input->post('nim'),
				'nama' => $this->input->post('nama'),
				'tempat_lahir' => $this->input->post('tempat_lahir'),
				'tanggal_lahir' => $this->input->post('tanggal_lahir'),
				'jenis_kelamin' => $this->input->post('jeniskelamin'),
				'alamat' => $this->input->post('alamat')
			];

			//update data
			$this->mahasiswa_model->update($mahasiswa, $where);

			$data['msg'] = 'Data berhasil diperbaharui';
			$this->load->view('mahasiswa/notifikasi', $data);
		} else {
			echo "<h3 style='color:red;'>Forbidden access</h3>";
		}
	}
```

Sehingga file controller kita akan jadi:
```php
<?php
defined('BASEPATH') or exit('No direct script access allowed');
class Mahasiswa extends CI_Controller
{
	function __construct()
	{
		parent::__construct();
		//load helper
		$this->load->helper('url');
		$this->load->helper('form');
		//load library  
		$this->load->library('form_validation');
		//load model 
		$this->load->model('mahasiswa_model');
	}
	public function index()
	{
		//ambil data dari database
		$getData = $this->mahasiswa_model->get();

		$data = [
			'mahasiswa' => $getData->result_array(),
			'jumlah_data' => $getData->num_rows()
		];
		
		//menampilkan view
		$this->load->view('mahasiswa/index', $data);
	}
	
	public function create()
	{
		//rule validasi
		$validation_rules = [
			[
				'field' => 'nim',
				'label' => 'NIM',
				'rules' => 'required'
			],
			[
				'field' => 'nama',
				'label' => 'Nama',
				'rules' => 'required'
			],
			[
				'field' => 'jeniskelamin',
				'label' => 'Jenis Kelamin',
				'rules' => 'required'
			],
			[
				'field' => 'tempat_lahir',
				'label' => 'Tempat Lahir',
				'rules' => 'required'
			],
			[
				'field' => 'tanggal_lahir',
				'label' => 'Tanggal Lahir',
				'rules' => 'required'
			],
			[
				'field' => 'alamat',
				'label' => 'Alamat',
				'rules' => 'required'
			]
		];
		
		//set rule validasi
		$this->form_validation->set_rules($validation_rules);

		if ($this->form_validation->run() === FALSE) {
			$this->load->view('mahasiswa/add');
		} else {

			//data mahasiswa
			$mahasiswa = [
				'nim' => $this->input->post('nim'),
				'nama' => $this->input->post('nama'),
				'tempat_lahir' => $this->input->post('tempat_lahir'),
				'tanggal_lahir' => $this->input->post('tanggal_lahir'),
				'jenis_kelamin' => $this->input->post('jeniskelamin'),
				'alamat' => $this->input->post('alamat')
			];
			
			$this->mahasiswa_model->insert($mahasiswa);

			$data['msg']  =  'Data berhasil disimpan';

			$this->load->view('mahasiswa/notifikasi', $data);
		}
	}

	public function edit($nim = '')
	{
		//Cek apakah ada parameter $nim
		if ('' == $nim) {
			//jika tidak ada, maka alihkan ke halaman daftar mahasiswa
			redirect('mahasiswa');
		}
		//ambil data mahasisa berdasarkan nim
		$data['mahasiswa'] =  $this->mahasiswa_model->get_by_nim($nim)->row_array();
		//load form edit
		$this->load->view('mahasiswa/edit', $data);
	}

	public function update()
	{
		//cek apakah tombol update ditekan
		if ($this->input->post('update')) {
			$nim = $this->input->post('nim');

			//rule validasi
			$validation_rules = [
				[
					'field' => 'nim',
					'label' => 'NIM',
					'rules' => 'required'
				],
				[
					'field' => 'nama',
					'label' => 'Nama',
					'rules' => 'required'
				],
				[
					'field' => 'jeniskelamin',
					'label' => 'Jenis Kelamin',
					'rules' => 'required'
				],
				[
					'field' => 'tempat_lahir',
					'label' => 'Tempat Lahir',
					'rules' => 'required'
				],
				[
					'field' => 'tanggal_lahir',
					'label' => 'Tanggal Lahir',
					'rules' => 'required'
				],
				[
					'field' => 'alamat',
					'label' => 'Alamat',
					'rules' => 'required'
				]
			];

			//set rule validasi
			$this->form_validation->set_rules($validation_rules);

			if ($this->form_validation->run() === false) {
				redirect('mahasiswa/edit/' . $nim);
			}

			$where['nim'] = $nim;

			//data mahasiswa
			$mahasiswa = [
				'nim' => $this->input->post('nim'),
				'nama' => $this->input->post('nama'),
				'tempat_lahir' => $this->input->post('tempat_lahir'),
				'tanggal_lahir' => $this->input->post('tanggal_lahir'),
				'jenis_kelamin' => $this->input->post('jeniskelamin'),
				'alamat' => $this->input->post('alamat')
			];

			//update data
			$this->mahasiswa_model->update($mahasiswa, $where);

			$data['msg'] = 'Data berhasil diperbaharui';
			$this->load->view('mahasiswa/notifikasi', $data);
		} else {
			echo "<h3 style='color:red;'>Forbidden access</h3>";
		}
	}
}

```
Dan seperti biasa, setelah selesai ngetiknya jangan lupa save lagi filenya yaa.

## Delete Data Mahasiswa{#delete-data}
Dan fitur terakhir dalam project CRUD sederhana CodeIgniter ini adalah fitur untuk menghapus data mahasiswa. Tahapannya adalah:
1. Menambahkan *method* ```delete()``` di dalam model ```Mahasiswa_model.php```
2. Menambahkan *method* ```hapus``` di dalam controller ```Mahasiswa.php```

Oke, kita lanjutkan project kita.

Buka kembali file model ```Mahasiswa_model.php```, lalu tambahkan *method* ```delete()``` di dalam *class* ```Mahasiswa_model```.

```php
function delete($nim)
	{
		//delete data berdasarkan nim
		$this->db->where('nim', $nim);
		$this->db->delete('tabel_mahasiswa');
	}
```

Sehingga code keseluruhan file ```Mahasiswa_model.php``` menjadi:
```php
<?php
defined('BASEPATH') or exit('No direct script access allowed');
class Mahasiswa_model extends CI_Model
{
	function get()
	{
		//SELECT * FROM tabel_mahasiswa
		return $this->db->get('tabel_mahasiswa');
	}

	function get_by_nim($nim)
	{
		//SELECT * FROM tabel_mahasiswa WHERE nim=$nim
		$this->db->where('nim', $nim);
		$this->db->from('tabel_mahasiswa');
		return $this->db->get();
	}

	function insert($data)
	{
		//insert data ke dalam tabel
		$this->db->insert('tabel_mahasiswa', $data);
	}
	
	function delete($nim)
	{
		//delete data berdasarkan nim
		$this->db->where('nim', $nim);
		$this->db->delete('tabel_mahasiswa');
	}
	
	function update($data, $where)
	{
		$this->db->where($where);
		$this->db->update('tabel_mahasiswa', $data);
	}
}
```
Save kembali file ```Mahasiswa_model.php```

Selanjutnya buka kembali file controller ```Mahasiswa.php```. Lalu tambahkan *method* ```hapus()``` di dalam class ```Mahasiswa```

```php
	public function hapus($nim = '')
	{
		//cek apakah parameter nim ada
		if ('' == $nim) {
			//jika tidak, tampilkan error
			return show_404();
		}
		//hapus data
		$this->mahasiswa_model->delete($nim);

		$data['msg']  =  'Data berhasil dihapus';
		$this->load->view('mahasiswa/notifikasi', $data);
	}
```

Sehingga script keseluruhan *class* ```Mahasiswa``` menjadi seperti script di bawah ini.
```php
<?php
defined('BASEPATH') or exit('No direct script access allowed');
class Mahasiswa extends CI_Controller
{
	function __construct()
	{
		parent::__construct();
		//load helper
		$this->load->helper('url');
		$this->load->helper('form');
		//load library  
		$this->load->library('form_validation');
		//load model 
		$this->load->model('mahasiswa_model');
	}
	public function index()
	{
		//ambil data dari database
		$getData = $this->mahasiswa_model->get();

		$data = [
			'mahasiswa' => $getData->result_array(),
			'jumlah_data' => $getData->num_rows()
		];
		
		//menampilkan view
		$this->load->view('mahasiswa/index', $data);
	}
	
	public function create()
	{
		//rule validasi
		$validation_rules = [
			[
				'field' => 'nim',
				'label' => 'NIM',
				'rules' => 'required'
			],
			[
				'field' => 'nama',
				'label' => 'Nama',
				'rules' => 'required'
			],
			[
				'field' => 'jeniskelamin',
				'label' => 'Jenis Kelamin',
				'rules' => 'required'
			],
			[
				'field' => 'tempat_lahir',
				'label' => 'Tempat Lahir',
				'rules' => 'required'
			],
			[
				'field' => 'tanggal_lahir',
				'label' => 'Tanggal Lahir',
				'rules' => 'required'
			],
			[
				'field' => 'alamat',
				'label' => 'Alamat',
				'rules' => 'required'
			]
		];
		
		//set rule validasi
		$this->form_validation->set_rules($validation_rules);

		if ($this->form_validation->run() === FALSE) {
			$this->load->view('mahasiswa/add');
		} else {

			//data mahasiswa
			$mahasiswa = [
				'nim' => $this->input->post('nim'),
				'nama' => $this->input->post('nama'),
				'tempat_lahir' => $this->input->post('tempat_lahir'),
				'tanggal_lahir' => $this->input->post('tanggal_lahir'),
				'jenis_kelamin' => $this->input->post('jeniskelamin'),
				'alamat' => $this->input->post('alamat')
			];
			
			$this->mahasiswa_model->insert($mahasiswa);

			$data['msg']  =  'Data berhasil disimpan';

			$this->load->view('mahasiswa/notifikasi', $data);
		}
	}

	public function edit($nim = '')
	{
		//Cek apakah ada parameter $nim
		if ('' == $nim) {
			//jika tidak ada, maka alihkan ke halaman daftar mahasiswa
			redirect('mahasiswa');
		}
		//ambil data mahasisa berdasarkan nim
		$data['mahasiswa'] =  $this->mahasiswa_model->get_by_nim($nim)->row_array();
		//load form edit
		$this->load->view('mahasiswa/edit', $data);
	}

	public function update()
	{
		//cek apakah tombol update ditekan
		if ($this->input->post('update')) {
			$nim = $this->input->post('nim');

			//rule validasi
			$validation_rules = [
				[
					'field' => 'nim',
					'label' => 'NIM',
					'rules' => 'required'
				],
				[
					'field' => 'nama',
					'label' => 'Nama',
					'rules' => 'required'
				],
				[
					'field' => 'jeniskelamin',
					'label' => 'Jenis Kelamin',
					'rules' => 'required'
				],
				[
					'field' => 'tempat_lahir',
					'label' => 'Tempat Lahir',
					'rules' => 'required'
				],
				[
					'field' => 'tanggal_lahir',
					'label' => 'Tanggal Lahir',
					'rules' => 'required'
				],
				[
					'field' => 'alamat',
					'label' => 'Alamat',
					'rules' => 'required'
				]
			];

			//set rule validasi
			$this->form_validation->set_rules($validation_rules);

			if ($this->form_validation->run() === false) {
				redirect('mahasiswa/edit/' . $nim);
			}

			$where['nim'] = $nim;

			//data mahasiswa
			$mahasiswa = [
				'nim' => $this->input->post('nim'),
				'nama' => $this->input->post('nama'),
				'tempat_lahir' => $this->input->post('tempat_lahir'),
				'tanggal_lahir' => $this->input->post('tanggal_lahir'),
				'jenis_kelamin' => $this->input->post('jeniskelamin'),
				'alamat' => $this->input->post('alamat')
			];

			//update data
			$this->mahasiswa_model->update($mahasiswa, $where);

			$data['msg'] = 'Data berhasil diperbaharui';
			$this->load->view('mahasiswa/notifikasi', $data);
		} else {
			echo "<h3 style='color:red;'>Forbidden access</h3>";
		}
	}
	
	public function hapus($nim = '')
	{
		//cek apakah parameter nim ada
		if ('' == $nim) {
			//jika tidak, tampilkan error
			return show_404();
		}
		//hapus data
		$this->mahasiswa_model->delete($nim);

		$data['msg']  =  'Data berhasil dihapus';
		$this->load->view('mahasiswa/notifikasi', $data);
	}
}

```
Setelah selesai ngetiknya, jangan lupa save kembali file controller ```Mahasiswa.php```.

Nah, sebelum uji coba aplikasi, sekarang kita cek dulu yang sudah kita buat. Sekarang kita punya folder dengan struktur folder adalah seperti di bawah ini (folder CI yang lain tidak ditampilkan):
```
 crud_ci  
 -application  
 --controllers  
 ---Mahasiswa.php  
 --models  
 ---Mahasiswa_model.php  
 --views  
 ---mahasiswa  
 ----add.php    
 ----edit.php  
 ----index.php
 ----notifikasi.php 
```

Di folder ```models``` ada file ```Mahasiswa_model.php```. Folder ```views``` ada folder baru ```mahasiswa``` dengan empat file views, yaitu ```add.php```, ```edit.php```, ```index.php``` dan ```notifikasi.php```. Dan folder ```controllers``` ada file controller dengan nama ```Mahasiswa.php```.

## Uji Coba Project{#uji-coba}
Di langkah terakhir ini, kita akan mencoba project Simple CRUD CodeIgniter yang baru saja kita buat. Sebagai pengingat, project yang dibangun dengan framework CodeIgniter dapat diakses dengan mengetik link dengan pola: 
    example.com/class/function/ID
Jadi untuk mengakses project yang kita buat, kita ketik link berikut di browser:
```
http://localhost/crud_ci/index.php/mahasiwa
```

Kalau berhasil, akan muncul daftar mahasiswa seperti pada gambar di bawah ini:

![Uji Coba Project - buka daftar mahasiswa](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/94b1d54b/codeigniter/codeigniter-3/crud/step_1.png)


Kok, belum ada daftar mahasiswanya? iya, kan belum kita isi.. 
Untuk menambahkan data, klik link 'Tambah Data' untuk membuka form data mahasiswa.

![Uji Coba Project - form data mahasiswa](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/94b1d54b/codeigniter/codeigniter-3/crud/step_2.png)

Coba klik tombol ‘TAMBAH’ untuk menguji form validation program. Jika form dikosongkan, maka akan muncul pesan error seperti di gambar di bawah ini.

![Uji Coba Project - tes validasi](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/94b1d54b/codeigniter/codeigniter-3/crud/step_3.png)

Selanjutnya kita coba isi data mahasiswa di dalam form. Apabila sudah diisi, klik tombol ‘TAMBAH’.

![Uji Coba Project - isi form data mahasiswa](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/94b1d54b/codeigniter/codeigniter-3/crud/step_4.png)

Akan muncul pemberitahuan kalau data yang kamu isi itu sudah berhasil disimpan.

![Uji Coba Project - notifikasi berhasil menyimpan data](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/94b1d54b/codeigniter/codeigniter-3/crud/step_5.png)


Setelah itu coba klik ‘kembali’ untuk kembali ke halaman awal. Data yang sudah ditambahkan ke dalam database akan tampil di tabel daftar Mahasiswa.

![Uji Coba Project - daftar mahasiswa](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/94b1d54b/codeigniter/codeigniter-3/crud/step_6.png)


Untuk memperbaharui data mahasiswa, klik 'edit' di kolom AKSI. Browser akan meload halaman form untuk memperbaharui data. 

![Uji Coba Project - perbaharui data mahasiswa](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/94b1d54b/codeigniter/codeigniter-3/crud/step_7.png)

Kita coba ubah datanya, lalu klik tombol ‘Update’. Sehingga muncul tampilan pemberitahuan data berhasil di perbaharui.

![Uji Coba Project - notifikasi berhasil memperbaharui data mahasiswa](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/94b1d54b/codeigniter/codeigniter-3/crud/step_8.png)

Klik link ‘Kembali’ untuk kembali ke halaman awal. Dapat terlihat data yang sudah diubah.

![Uji Coba Project - daftar mahasiswa](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/94b1d54b/codeigniter/codeigniter-3/crud/step_9.png)

Dan terakhir, untuk menghapus data coba klik 'delete' di kolom AKSI. Maka, akan muncul tampilan pilihan untuk menghapus data. 

![Uji Coba Project - hapus data mahasiswa](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/94b1d54b/codeigniter/codeigniter-3/crud/step_10.png)

Klik ok dan selanjutnya akan tampil halaman pemberitahuan data berhasil dihapus.

![Uji Coba Project - notifikasi berhasil menghapus data mahasiswa](https://cdn.statically.io/gh/gungunpriatna/tes-repositori/94b1d54b/codeigniter/codeigniter-3/crud/step_11.png)

<em><b>***</b></em>

Ya, semoga tutorial Simple CRUD CodeIgniter ini bisa memudahkanmu untuk memahami dasar-dasar membuat aplikasi dengan fitur CRUD menggunakan framework CodeIgniter. Memberikan gambaran tentang basic design pattern dalam CodeIgniter, sehingga dapat kamu kembangkan menjadi aplikasi yang lebih baik. 

Sebagai bahan referensi , source code tutorial ini dapat teman-teman unduh [di sini](https://github.com/doublegunz/recode-tutorial-crud-ci).

Terima kasih sudah ikut menyimak tutorial di blog saya. Sampai berjumpa lagi di edisi tutorial berikutnya. Apabila ada pertanyaan, kritik, saran, request atau ingin berkontribusi bisa disampaikan melalui kolom komentar. 



Boleh dishare, apabila bermanfaat. Happy coding!

<em><b>***</b></em>

* Web Official CodeIgniter @ [https://codeigniter.com](https://codeigniter.com)
* Documentasi CodeIgniter @ [https://codeigniter.com/user_guide/](https://codeigniter.com/user_guide/)
* Tentang validasi @ [https://codeigniter.com/user_guide/libraries/form_validation.html](https://codeigniter.com/user_guide/libraries/form_validation.html)
* Tentang query builder [https://codeigniter.com/user_guide/database/query_builder.html](https://codeigniter.com/user_guide/database/query_builder.html)


### <em><b>---</b></em>

Serial Tutorial CodeIgniter [Edisi Revisi] ini berisi tentang tutorial pengembangan aplikasi menggunakan framework CodeIgniter. Selain untuk mengikat ilmu, serial ini juga dibuat agar saya dan teman-teman bisa sama-sama belajar.

Tulisan ini dipublikasikan ulang dibawah lisensi [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-nc-sa/4.0/)