---
title: "Panduan Lengkap: Cara Install Jupyter Notebook di Ubuntu 25.04"
slug: "panduan-lengkap-cara-install-jupyter-notebook-di-ubuntu-2504"
category: "How To Install"
date: "2026-02-17"
status: "published"
---

Jupyter Notebook merupakan salah satu tools yang sangat populer di kalangan data scientist, researcher, dan developer untuk menulis dan menjalankan kode secara interaktif. Dengan Jupyter Notebook, kita bisa menulis kode Python, menampilkan visualisasi data, serta mendokumentasikan proses analisis dalam satu tempat. **Jupyter Notebook** menyediakan antarmuka berbasis web yang memudahkan kita untuk:

- **Menulis dan menjalankan kode** secara interaktif dalam sel-sel (cells).
- **Menampilkan visualisasi** seperti grafik dan chart langsung di notebook.
- **Mendokumentasikan** proses kerja dengan Markdown di antara kode.
- **Berbagi hasil analisis** dalam format `.ipynb` yang dapat dibuka oleh siapa saja.

## Overview {#overview}

Pada panduan ini kita akan belajar cara install Jupyter Notebook di VPS atau komputer lokal dengan sistem operasi Ubuntu 25.04. Cara paling aman dan direkomendasikan untuk install Jupyter adalah menggunakan **virtual environment (venv)**, bukan langsung ke sistem. Dengan menggunakan venv, dependensi Jupyter tidak akan bercampur dengan paket sistem sehingga lebih bersih dan mudah dikelola. Panduan ini akan membahas secara detail setiap langkah mulai dari persiapan Python hingga menjalankan Jupyter Notebook.

### Apa yang akan kamu pelajari

1. Persiapan Python, pip, dan venv
2. Membuat virtual environment
3. Instalasi Jupyter Notebook
4. Menjalankan Jupyter Notebook

Setelah kita selesai melakukan semua langkah-langkah instalasi, kita akan uji coba menjalankan Jupyter Notebook dan mengakses antarmuka web-nya melalui browser.

### Apa yang perlu kamu persiapkan

- Komputer atau VPS dengan OS Ubuntu 25.04 yang sudah terinstall.
- Akses pengguna dengan hak sudo.
- Koneksi internet yang stabil.
- Akses server melalui SSH (jika menggunakan VPS).

## Step 1: Siapkan Python, pip, dan venv {#step-1-siapkan-python-pip-dan-venv}

Pada langkah pertama ini kita akan memastikan Python dan paket pendukungnya sudah terinstall. Di Ubuntu 25.04 sudah tersedia Python 3.13 secara default, tapi kita perlu memastikan paket `pip` dan `venv` juga ter-install. Sebelum kita mulai, kita perbaharui terlebih dahulu package sistem dengan run command berikut ini.

```bash
sudo apt update
```

Setelah proses update selesai, kita install Python beserta paket pendukungnya menggunakan command berikut.

```bash
sudo apt install python3 python3-pip python3-venv
```

Ketika tampil prompt, ketik `Y`, lalu tekan `enter` untuk konfirmasi instalasi.

Selanjutnya kita verifikasi Python dan pip yang terinstall dengan run command berikut.

```bash
python3 --version
pip3 --version
```

Output yang ditampilkan:

```
Python 3.13.3
pip 25.0 from /usr/lib/python3/dist-packages/pip (python 3.13)
```

Pada output yang ditampilkan, kita bisa melihat Python versi 3.13.3 dan pip versi 25.0 sudah terinstall pada saat panduan ini diujicoba di Ubuntu 25.04.

## Step 2: Buat Virtual Environment {#step-2-buat-virtual-environment}

Setelah Python dan paket pendukungnya sudah terinstall, langkah selanjutnya adalah membuat virtual environment. Virtual environment berfungsi untuk mengisolasi dependensi Jupyter agar tidak bercampur dengan paket sistem. Dengan cara ini, kita bisa mengelola paket Jupyter secara terpisah dan menghindari konflik dependensi.

Untuk membuat virtual environment, kita run command berikut ini:

```bash
mkdir -p ~/envs
cd ~/envs
python3 -m venv jupyter-env
```

**Penjelasan Command:**

- **`mkdir -p ~/envs`**: Membuat direktori `envs` di home directory sebagai tempat menyimpan virtual environment.
- **`cd ~/envs`**: Berpindah ke direktori `envs`.
- **`python3 -m venv jupyter-env`**: Membuat virtual environment baru dengan nama `jupyter-env`.

Setelah virtual environment berhasil dibuat, kita aktifkan dengan run command berikut ini:

```bash
source jupyter-env/bin/activate
```

Prompt terminal akan berubah menandakan venv sudah aktif seperti output yang ditampilkan berikut ini.

```
(jupyter-env) gun-gun-priatna@qadrlabs:~/envs$
```

Tanda `(jupyter-env)` di awal prompt menunjukkan bahwa virtual environment sudah aktif dan siap digunakan.

## Step 3: Install Jupyter Notebook {#step-3-install-jupyter-notebook}

Sekarang virtual environment sudah aktif, kita bisa mulai install Jupyter Notebook. Sebelum install Jupyter, sebaiknya kita upgrade pip terlebih dahulu ke versi terbaru untuk memastikan proses instalasi berjalan lancar.

Untuk upgrade pip, run command berikut ini:

```bash
pip install --upgrade pip
```

Output yang ditampilkan:

```
(jupyter-env) gun-gun-priatna@qadrlabs:~/envs$ pip install --upgrade pip
Requirement already satisfied: pip in ./jupyter-env/lib/python3.13/site-packages (25.0)
Collecting pip
  Downloading pip-26.0.1-py3-none-any.whl.metadata (4.7 kB)
Downloading pip-26.0.1-py3-none-any.whl (1.8 MB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 1.8/1.8 MB 1.8 MB/s eta 0:00:00
Installing collected packages: pip
  Attempting uninstall: pip
    Found existing installation: pip 25.0
    Uninstalling pip-25.0:
      Successfully uninstalled pip-25.0
Successfully installed pip-26.0.1
```

Selanjutnya kita install Jupyter Notebook dengan run command berikut ini:

```bash
pip install jupyter
```

Output yang ditampilkan:

```
(jupyter-env) gun-gun-priatna@qadrlabs:~/envs$ pip install jupyter
Collecting jupyter
  Downloading jupyter-1.1.1-py2.py3-none-any.whl.metadata (2.0 kB)
  ...
  ...
```

Kita tunggu sampai proses install selesai.

Setelah proses instalasi selesai, kita verifikasi dengan mengecek versi Jupyter Notebook yang terinstall. Untuk cek versi Jupyter, kita bisa run command berikut ini:

```bash
jupyter notebook --version
```

Output yang ditampilkan:

```
(jupyter-env) gun-gun-priatna@qadrlabs:~/envs$ jupyter notebook --version
7.5.3
```

Pada saat panduan ini diuji coba, versi Jupyter Notebook yang terinstall adalah versi 7.5.3.

## Step 4: Menjalankan Jupyter Notebook {#step-4-menjalankan-jupyter-notebook}

Setelah proses instalasi selesai, kita bisa langsung menjalankan Jupyter Notebook. Pastikan virtual environment masih aktif (ditandai dengan `(jupyter-env)` di prompt terminal), lalu run command berikut ini:

```bash
jupyter notebook
```

Output yang ditampilkan:

```
(jupyter-env) gun-gun-priatna@qadrlabs:~/envs$ jupyter notebook
[I 2026-02-17 08:56:12.555 ServerApp] jupyter_lsp | extension was successfully linked.
.
.
.
[I 2026-02-17 08:56:12.778 ServerApp] Jupyter Server 2.17.0 is running at:
[I 2026-02-17 08:56:12.778 ServerApp] http://localhost:8888/tree?token=7xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
[I 2026-02-17 08:56:12.778 ServerApp]     http://127.0.0.1:8888/tree?token=7xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
[I 2026-02-17 08:56:12.778 ServerApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
[C 2026-02-17 08:56:12.790 ServerApp] 
```

Setelah Jupyter Notebook berjalan, akan terbuka tab di browser secara otomatis di `http://127.0.0.1:8888` (atau URL yang muncul di terminal). Dari antarmuka web ini, kita bisa mulai membuat notebook baru, menulis kode Python, dan menjalankannya secara interaktif.

### Menghentikan Jupyter Notebook

Untuk menghentikan Jupyter Notebook, tekan `Ctrl + C` di terminal, lalu ketik `y` untuk konfirmasi.

Output:

```
Shut down this Jupyter server (y/[n])? y
[C 2026-02-17 09:28:43.695 ServerApp] Shutdown confirmed
[I 2026-02-17 09:28:43.696 ServerApp] Shutting down 5 extensions
```

### Keluar dari Virtual Environment

Setelah selesai menggunakan Jupyter Notebook, kita bisa keluar dari virtual environment dengan run command berikut ini:

```bash
deactivate
```

Output:

```
(jupyter-env) gun-gun-priatna@qadrlabs:~/envs$ deactivate
gun-gun-priatna@qadrlabs:~/envs$
```

Prompt terminal akan kembali normal tanpa tanda `(jupyter-env)`, menandakan kita sudah keluar dari virtual environment.

### Menjalankan Jupyter Notebook Kembali

Setiap kali ingin menggunakan Jupyter Notebook lagi, kita perlu mengaktifkan virtual environment terlebih dahulu dengan run command berikut ini:

```bash
cd ~/envs
source jupyter-env/bin/activate
jupyter notebook
```

## Kesimpulan {#kesimpulan}

Selamat! Kita telah berhasil menginstal Jupyter Notebook di Ubuntu 25.04 menggunakan virtual environment. Dengan mengikuti langkah-langkah di atas, kita sekarang memiliki environment yang bersih dan terisolasi untuk menjalankan Jupyter Notebook.

**Takeaway dari panduan ini:**

- Menggunakan **virtual environment** adalah cara yang paling aman dan direkomendasikan untuk install Jupyter Notebook di Ubuntu, karena dependensi tidak bercampur dengan paket sistem.
- **Python 3.13** sudah tersedia secara default di Ubuntu 25.04, sehingga kita hanya perlu memastikan `pip` dan `venv` sudah terinstall.
- **Jupyter Notebook** berjalan sebagai server lokal yang bisa diakses melalui browser, sehingga memudahkan kita untuk menulis dan menjalankan kode secara interaktif.
- Setiap kali ingin menggunakan Jupyter, jangan lupa untuk **mengaktifkan virtual environment** terlebih dahulu.

Jika teman-teman mengalami kendala, jangan ragu untuk memeriksa dokumentasi resmi Jupyter atau meninggalkan pertanyaan di kolom komentar.

---

**FAQ**

1. **Mengapa harus menggunakan virtual environment?**
   Virtual environment mengisolasi dependensi Jupyter dari paket sistem. Ini mencegah konflik antar paket dan membuat pengelolaan dependensi lebih mudah.

2. **Apakah Jupyter Notebook bisa diakses dari komputer lain?**
   Secara default, Jupyter Notebook hanya bisa diakses dari localhost. Untuk mengaksesnya dari komputer lain, kita perlu menjalankan Jupyter dengan parameter `--ip=0.0.0.0` dan mengatur firewall untuk mengizinkan akses ke port 8888.

3. **Apa perbedaan Jupyter Notebook dan JupyterLab?**
   Jupyter Notebook adalah antarmuka klasik yang fokus pada dokumen notebook. JupyterLab adalah antarmuka generasi berikutnya yang lebih lengkap dengan fitur file browser, terminal, dan editor teks terintegrasi. Keduanya bisa diinstall menggunakan pip.

4. **Bagaimana cara menginstall library tambahan di virtual environment?**
   Pastikan virtual environment sudah aktif, lalu install library menggunakan pip. Contoh: `pip install numpy pandas matplotlib`.

Semoga panduan ini membantu teman-teman untuk memulai menggunakan Jupyter Notebook di Ubuntu 25.04!