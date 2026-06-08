---
title: "Cara Install Multiple Node js Version Menggunakan NVM di Ubuntu 22.04"
slug: "cara-install-multiple-node-js-version-menggunakan-nvm-di-ubuntu-22-04"
category: "How To Install"
date: "2022-05-01"
status: "published"
---

Migrasi ke Ubuntu 22.04 LTS (Jammy Jellyfish) membawa sejumlah peningkatan performa dan fitur keamanan yang signifikan. Sebagai developer yang telah menggunakan Ubuntu selama lebih dari 5 tahun, langkah pertama yang selalu saya lakukan setelah upgrade sistem adalah mengkonfigurasi ulang development environment. Hal ini krusial untuk memastikan workflow development tetap optimal dan konsisten.

Dalam pengembangan aplikasi modern menggunakan Laravel, Node.js telah menjadi komponen vital, terutama untuk proses kompilasi asset menggunakan Node Package Manager (NPM). Namun, tantangan muncul ketika kita perlu menangani multiple projects dengan versi Node.js yang berbeda. Berdasarkan pengalaman pribadi mengelola lebih dari 20 proyek Laravel dengan berbagai versi, Node Version Manager (NVM) menjadi solusi yang sangat reliable untuk mengatasi masalah kompatibilitas.

Tutorial ini akan memandu Anda melalui proses instalasi dan konfigurasi Node.js menggunakan NVM di Ubuntu 22.04 LTS, dengan pendekatan yang telah teruji di lingkungan production. Metode ini tidak hanya memungkinkan pengelolaan multiple versi Node.js dengan efisien, tetapi juga meminimalisir potensi konflik dependency antar proyek.

## Prasyarat {#prasyarat}
Sebelum memulai instalasi, pastikan sistem Anda memenuhi kebutuhan berikut:
- Ubuntu 22.04 LTS (Jammy Jellyfish)
- Koneksi internet stabil
- Terminal/Command Line Access
- Paket dasar: `curl` atau `wget`
- Minimal 1GB disk space

**Keterangan:**
Per tanggal 9 November 2025, tutorial ini diuji coba di ubuntu 25.04.
```
$ lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 25.04
Release:	25.04
Codename:	plucky

```

## Step 1: Install NVM{#install-nvm}
Mari kita mulai proses instalasi NVM dengan mengikuti langkah-langkah berikut secara berurutan. Pastikan setiap langkah berhasil sebelum melanjutkan ke langkah berikutnya.
1. Buka terminal (`Ctrl + Alt + T`)
2. Download dan jalankan script instalasi NVM:
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
```

3. Setelah itu, kita aktifkan NVM di session saat ini:
```bash
source ~/.bashrc
```

4. Selanjutnya kita verifikasi instalasi NVM menggunakan command berikut ini.
```bash
$ nvm --version
0.40.3
```

> **Warning**: Jika command `nvm` tidak ditemukan, restart terminal Anda.

## Step 2: Install Node.js{#install-nodejs}
Dengan menggunakan nvm, kita bisa install Node.js dengan versi yang berbeda-beda sesuai dengan kebutuhan. Kita bisa cek terlebih dahulu, Node.js versi berapa saja yang tersedia untuk diinstall menggunakan command berikut ini.

```bash
nvm ls-remote
```

Outputnya kurang lebih seperti ini...

```bash
	   ... node js versi lainnya
	   
Jod)
       v22.13.0   (LTS: Jod)
       v22.13.1   (LTS: Jod)
       v22.14.0   (LTS: Jod)
       v22.15.0   (LTS: Jod)
       v22.15.1   (LTS: Jod)
       v22.16.0   (LTS: Jod)
       v22.17.0   (LTS: Jod)
       v22.17.1   (LTS: Jod)
       v22.18.0   (LTS: Jod)
       v22.19.0   (LTS: Jod)
       v22.20.0   (LTS: Jod)
       v22.21.0   (LTS: Jod)
       v22.21.1   (Latest LTS: Jod)
        v23.0.0
        v23.1.0
        v23.2.0
        v23.3.0
        v23.4.0
        v23.5.0
        v23.6.0
        v23.6.1
        v23.7.0
        v23.8.0
        v23.9.0
       v23.10.0
       v23.11.0
       v23.11.1
        v24.0.0
        v24.0.1
        v24.0.2
        v24.1.0
        v24.2.0
        v24.3.0
        v24.4.0
        v24.4.1
        v24.5.0
        v24.6.0
        v24.7.0
        v24.8.0
        v24.9.0
       v24.10.0
       v24.11.0   (Latest LTS: Krypton)
        v25.0.0
        v25.1.0

```

Ya, ada banyak versi yang tersedia. Selanjutnya kita bisa coba install node.js mengunakan command dengan format.

```bash
nvm install <version>
```

Sebagai contoh sekarang kita akan mencoba install node.js versi lts, yaitu versi 24.11.0. Sekarang kita install node.js versi 24.11.0 menggunakan nvm.

```bash
nvm install v24.11.0
```

Setelah command di atas, node.js akan didownload dan diinstall. Kita tunggu sampai prosesnya selesai.

Apabila selesai nanti tampil output berikut ini.

```bash
Downloading and installing node v24.11.0...
Downloading https://nodejs.org/dist/v24.11.0/node-v24.11.0-linux-x64.tar.xz...
######################################################################### 100.0%
Computing checksum with sha256sum
Checksums matched!
Now using node v24.11.0 (npm v11.6.1)
Creating default alias: default -> v24.11.0

```

Bisa kita perhatikan, dari output command di atas, nvm langsung setting node.js yang baru terinstall yang bisa kita gunakan. Selain itu, Node Package Manager (NPM) juga sudah otomatis terinstall. Dari output di atas, NPM yang terinstall adalah npm v11.6.1.

Misalkan kita ada kebutuhan untuk menggunakan node js versi lama, misalnya v22.21.1. Kita bisa install menggunakan format command yg sama

```bash
nvm install v22.21.1
```

Seperti sebelumnya, kita tunggu proses download dan install node.js. Dan apabila prosesnya sudah selesai, kita bisa lihat output yang ditampilkan di terminal.
```bash
Downloading and installing node v22.21.1...
Downloading https://nodejs.org/dist/v22.21.1/node-v22.21.1-linux-x64.tar.xz...
######################################################################### 100.0%
Computing checksum with sha256sum
Checksums matched!
Now using node v22.21.1 (npm v10.9.4)

```

Sekarang kita coba cek versi yang sedang digunakan menggunakan command.

```bash
node -v 
```

Kurang lebih output yang ditampilkan seperti berikut ini.

```bash
v22.21.1
```

Output yang ditampilkan di terminal sesuai dengan node.js yang baru saja diinstall. Ya, kadang nvm menggunakan versi yang baru saja diinstall.

Misalkan kita ingin memakai node.js yang sebelumnya kita install, yaitu v24.11.0. Kita bisa menggunakan node.js yang kita inginkan menggunakan command dengan format berikut ini.
```bash
nvm use <version>
```

Di sini kita coba node v24.11.0 sebagai versi yang akan kita gunakan, jadi kita run command berikut ini:

```bash
nvm use v24.11.0
```

Output yang ditampilkan setelah kita run command di atas kurang lebih seperti ini.
```bash
Now using node v24.11.0 (npm v11.6.1)
```

Supaya lebih yakin kita cek versinya.

```bash
node -v 
```
Outputnya:
```
v24.11.0
```

## Step 3: Set Default versi Node js yang digunakan{#set-default-nodejs}
Misalkan kita suda coba install beberapa versi node js, kita bisa lihat daftar node.js yang terinstall menggunakan command `ls`.
```bash
nvm ls
```
Ini adalah output setelah saya coba install beberapa versi.
```bash
$ nvm ls
       v22.21.1
->     v24.11.0
default -> v24.11.0
iojs -> N/A (default)
unstable -> N/A (default)
node -> stable (-> v24.11.0) (default)
stable -> 24.11 (-> v24.11.0) (default)
lts/* -> lts/krypton (-> v24.11.0)
lts/argon -> v4.9.1 (-> N/A)
lts/boron -> v6.17.1 (-> N/A)
lts/carbon -> v8.17.0 (-> N/A)
lts/dubnium -> v10.24.1 (-> N/A)
lts/erbium -> v12.22.12 (-> N/A)
lts/fermium -> v14.21.3 (-> N/A)
lts/gallium -> v16.20.2 (-> N/A)
lts/hydrogen -> v18.20.8 (-> N/A)
lts/iron -> v20.19.5 (-> N/A)
lts/jod -> v22.21.1
lts/krypton -> v24.11.0

```

Misalkan kita ingin salah satu versi node.js yang sudah kita install sebagai default versi yang digunakan. Kita bisa run command berikut ini.

```bash
nvm alias default v22.21.1
```

Output:
```bash
$ nvm alias default v22.21.1
default -> v22.21.1

```

Selanjutnya kita verifikasi kembali menggunakan command `nvm ls`.
```
$ nvm ls
->     v22.21.1
       v24.11.0
default -> v22.21.1
iojs -> N/A (default)
unstable -> N/A (default)
node -> stable (-> v24.11.0) (default)
stable -> 24.11 (-> v24.11.0) (default)
lts/* -> lts/krypton (-> v24.11.0)
lts/argon -> v4.9.1 (-> N/A)
lts/boron -> v6.17.1 (-> N/A)
lts/carbon -> v8.17.0 (-> N/A)
lts/dubnium -> v10.24.1 (-> N/A)
lts/erbium -> v12.22.12 (-> N/A)
lts/fermium -> v14.21.3 (-> N/A)
lts/gallium -> v16.20.2 (-> N/A)
lts/hydrogen -> v18.20.8 (-> N/A)
lts/iron -> v20.19.5 (-> N/A)
lts/jod -> v22.21.1
lts/krypton -> v24.11.0

```

Versi default ini nantinya secara otomatis akan digunakan ketika kita coba sesi baru di laptop atau komputer kita.

Oh iya, kita bisa juga menggunakan node js versi yang disetting default menggunakan command.

```bash
nvm use default
```
Output:
```bash
$ nvm use default
Now using node v22.21.1 (npm v10.9.4)
```

## Step 4: Tes Run NPM{#tes-run-npm}
Karena tujuan awal saya install node.js itu untuk menggunakan NPM, jadi pada step ini kita akan coba tes run NPM. 

Seperti yang sebelumnya disebutkan, setiap versi node.js yang terinstall sudah terinstall Node Package Manager (NPM) sesuai dengan versi node.js nya. Untuk mengecek versi NPM kita bisa run command berikut ini.
```bash
npm --version
```

Sekarang kita coba tes running npm dengan studi kasus untuk install dependensi di project laravel dan build asset project laravel.

Untuk tes npm, kita coba buat project laravel terlebih dahulu.
```
laravel new test-run-npm
```

Setelah project laravel selesai kita install, kemudian kita masuk project laravel.
```
cd test-run-npm
```

Lalu kita install dependensi menggunakan NPM.
```
npm install
```

Output yang ditampilkan di terminal ketika kita run command di atas kurang lebih seperti berikut ini.
```
added 165 packages, and audited 166 packages in 4s

40 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities

```
Selanjutnya kita coba build assets dengan cara run command berikut ini
```
npm run build
```

Output yang ditampilkan di terminal:
```
> build
> vite build

vite v5.4.10 building for production...
✓ 53 modules transformed.
public/build/manifest.json             0.27 kB │ gzip:  0.15 kB
public/build/assets/app-Cixru3vd.css  17.75 kB │ gzip:  4.04 kB
public/build/assets/app-z-Rg4TxU.js   35.05 kB │ gzip: 14.08 kB
✓ built in 694ms

```

Setelah test run npm ini kita bisa pastikan npm berjalan dan dapat digunakan.

## Uninstall Node.js menggunakan NVM{#uninstall-nodejs}
Katakanlah kita sudah menggunakan node.js versi lama untuk melakukan proses maintenance project lama dan kita sudah coba upgrade dependensi project menggunakan package yang baru. Setelah proses maintenance dan upgrade dependensi, node.js versi lama itu tidak akan kita gunakan lagi. Kita bisa hapus atau uninstall node.js versi lama yang tidak akan kita gunakan tersebut. Untuk menghapus atau uninstall node.js, kita bisa run command berikut ini.
```bash
nvm uninstall <version> 
```

Contohnya kita ingin hapus v12.22.12, karena versi ini sudah tidak kita gunakan. Untuk menghapus versi tersebut, run command berikut ini.

```bash
nvm uninstall v12.22.12
```

Output
```bash
Uninstall node v12.22.12
```
Ya, command di atas akan menghapus versi node.js yang kita pilih untuk dihapus.

Misalkan kita ingin menghapus versi yang sedang running di sistem, kita bisa cek terlebih dahulu versi yang sedang running menggunakan command.
```bash
nvm current
```

Kalau versi yang sedang running ini versi yang ingin kita hapus, kita mesti nonaktifkan terlebih dahulu versi tersebut menggunakan command:

```bash
nvm deactivate
```

Setelah command di atas kita run, kita bisa hapus menggunakan command yang sebelumnya kita gunakan.

## Penutup{#penutup}
Setelah mengikuti langkah-langkah dalam tutorial ini, Anda telah berhasil mengimplementasikan sistem manajemen Node.js yang fleksibel dan scalable menggunakan NVM di Ubuntu 22.04 LTS. Setup ini tidak hanya memberikan fleksibilitas dalam mengelola multiple versi Node.js, tetapi juga menciptakan fondasi yang solid untuk pengembangan aplikasi modern.

Berdasarkan pengalaman pribadi mengelola berbagai proyek Laravel dalam production environment, setup menggunakan NVM telah terbukti sangat reliable. Kemampuan untuk beralih antar versi Node.js dengan mudah telah menghemat waktu yang signifikan dalam proses development dan maintenance, terutama saat menangani proyek-proyek legacy yang membutuhkan versi Node.js spesifik.

> **Pro Tips**:
> - Dokumentasikan versi Node.js yang digunakan dalam `package.json` project Anda
> - Pertimbangkan untuk membuat shell script untuk automasi setup environment
> - Lakukan audit berkala terhadap unused Node.js versions untuk mengoptimalkan storage

## Troubleshooting {#troubleshooting}
1. **Command `nvm` not found**
   - Solusi: Restart terminal atau run `source ~/.bashrc`

2. **Permission denied saat install global packages**
   - Solusi: Gunakan `npm install -g <package>` tanpa sudo

3. **Error downloading Node.js**
   - Solusi: Cek koneksi internet dan firewall settings

## FAQ {#faq}

**Q: Apakah perlu uninstall Node.js versi lama sebelum menggunakan NVM?**  
A: Ya, untuk menghindari konflik disarankan uninstall versi yang terinstall via apt.

**Q: Bagaimana cara switch antara versi Node.js?**  
A: Gunakan command `nvm use <version>`, contoh: `nvm use v16.15.0`

**Q: Apakah global packages tersedia di semua versi?**  
A: Tidak, setiap versi Node.js memiliki global packages terpisah.

## Next Steps & Recommendations{#next}
Untuk mengoptimalkan workflow development Anda, berikut beberapa langkah lanjutan yang disarankan:
1. **Version Control & Collaboration**
   - Setup Git repository
   - Konfigurasi `.gitignore` untuk Node.js
   - Dokumentasi environment requirements

2. **Development Tools**
   - Configure IDE/Text Editor
   - Setup debugging tools
   - Install essential NPM packages globally

3. **Performance Optimization**
   - Implement asset bundling
   - Configure caching strategies
   - Setup build automation

4. **Security Best Practices**
   - Regular dependency updates
   - Security audits
   - Environment isolation

## Keep Learning!{#keep-learning}
The world of web development terus berkembang, jangan berhenti di sini! Perdalam pengetahuan Anda tentang:
- Modern build tools (Vite, Webpack)
- JavaScript frameworks
- Testing methodologies
- CI/CD practices

## Referensi{#referensi}

- [Dokumentasi Resmi NVM](https://github.com/nvm-sh/nvm)
- [Node.js Documentation](https://nodejs.org/docs)
- [Ubuntu Documentation](https://help.ubuntu.com)

*Found this helpful? Share it with your fellow developers!*

*Last Updated: November 2025*  
*Tested on: Ubuntu 22.04 LTS, 24.04 LTS, 25.04 LTS*