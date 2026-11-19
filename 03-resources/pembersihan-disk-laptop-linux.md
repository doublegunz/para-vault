---
tags: [linux, maintenance, disk]
date: 2026-11-19
---

# Pembersihan Disk Laptop Linux

Catatan pembersihan disk root (`/dev/nvme0n1p3`, 201G) pada 19 November 2026, saat sisa ruang tinggal 1.7G (100% terpakai). Bisa dipakai lagi sebagai panduan kalau disk mulai penuh.

> [!summary] Hasil
> | | Sebelum | Sesudah |
> | --- | --- | --- |
> | Terpakai | 189G (100%) | 130G (69%) |
> | Kosong | 1.7G | **61G** |

## 1. Cari penyebabnya

```bash
df -h -x tmpfs -x devtmpfs -x squashfs              # ruang tiap partisi
du -xh --max-depth=1 ~ | sort -rh | head -20        # folder terbesar di home
du -xh --max-depth=1 ~/.cache | sort -rh | head     # drill ke folder yang besar
journalctl --disk-usage                             # ukuran log sistem
```

Penyebab terbesar saat itu:

| Lokasi | Ukuran | Isi |
| --- | --- | --- |
| `~/.npm` | 12G | cache npm |
| Docker (`/var/lib/docker`) | ~15G | image, volume database lama |
| `~/.cache/google-chrome` | 7.8G | cache browser, 7 profil |
| `~/.android/avd` + `~/Android/Sdk` | 13.2G | emulator dan Android SDK |
| `~/Downloads/app` | 6G | Android Studio dan PhpStorm (aplikasi dijalankan dari sini) |
| Log journal | 3.5G | log sistem |
| `~/.cache/uv`, `pip`, `tracker3` | ~3.8G | cache Python dan index GNOME |

## 2. Bersihkan cache (aman, bisa diulang kapan saja)

```bash
npm cache clean --force
uv cache clean
pip cache purge
rm -rf ~/.cache/tracker3                 # index GNOME, dibuat ulang otomatis
sudo journalctl --vacuum-size=200M       # perlu password, jalankan di terminal biasa
```

### Cache Chrome

Tutup Chrome dulu, lalu:

```bash
rm -rf ~/.cache/google-chrome
```

> [!important] Login tetap aman
> Login, cookie, password, bookmark, dan history ada di `~/.config/google-chrome`, **bukan** di `~/.cache`. Menghapus folder cache tidak membuat logout dari sosial media. Efeknya hanya website sedikit lebih lambat saat pertama dibuka lagi.
>
> Jangan pakai menu **Clear browsing data** di Chrome dengan opsi *Cookies and other site data* dicentang, karena itu yang membuat logout.

## 3. Hapus Docker sepenuhnya

Docker sudah tidak dipakai, jadi dihapus total. Volume database (Devilbox MariaDB/PostgreSQL/MongoDB, MySQL laravel-frankenphp) ikut terhapus setelah dipastikan tidak ada data penting.

> [!warning] Cek volume dulu
> `docker system prune -a` **tidak** menghapus volume bernama. Sebelum menghapus volume, lihat isinya dengan `docker system df -v` dan dump database penting ke file `.sql` kalau masih dibutuhkan. Volume yang sudah dihapus tidak bisa dikembalikan.

```bash
docker ps -aq | xargs -r docker rm -f
docker system prune -a -f --volumes
docker volume ls -q | xargs -r docker volume rm
rm -rf ~/.docker
```

Bagian yang perlu sudo (jalankan di terminal biasa):

```bash
sudo systemctl disable --now docker.service docker.socket containerd.service
sudo apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo apt autoremove -y
sudo rm -rf /var/lib/docker /var/lib/containerd /etc/docker /opt/containerd
```

Sisa `/etc/apt/sources.list.d/docker.list.save` tidak dibaca apt, jadi dibiarkan.

## 4. Hapus Android Studio, PhpStorm, emulator, SDK

Isi `~/Downloads/app` ternyata bukan installer, tetapi aplikasi yang dijalankan langsung dari folder itu (ikon menu dan `/usr/local/bin/studio` mengarah ke sana). Karena sedang tidak dipakai, semuanya dihapus.

```bash
rm -rf ~/Downloads/app ~/Android ~/.android/avd
rm -rf ~/.cache/Google/AndroidStudio* ~/.config/Google/AndroidStudio*
rm -rf ~/.cache/JetBrains/PhpStorm* ~/.local/share/JetBrains/PhpStorm*
rm -f ~/.local/share/applications/jetbrains-phpstorm.desktop ~/.local/share/applications/jetbrains-studio.desktop
sudo rm /usr/local/bin/studio
```

## Yang sengaja disimpan

- `~/Downloads/iso`: masih dipakai uji coba virtual server.
- `~/.gradle` (2.3G): masih dipakai tutorial Java.
- `~/.config/JetBrains` (25M): setting dan lisensi PhpStorm, berguna kalau install lagi.
- `~/.android` (3.6M): kunci adb.

## Kandidat berikutnya kalau penuh lagi

- Ulangi langkah 2 (cache npm, uv, pip, Chrome, journal). Cache ini akan terisi lagi pelan-pelan.
- `~/.codex/packages` (6.5G): kemungkinan ada versi lama yang menumpuk, perlu dicek dulu.
- `~/.gemini/antigravity-backup` (1.8G): backup Antigravity.
- `~/sandbox/*`: hapus `node_modules` dan venv yang tidak dipakai (misalnya `sandbox/todo-web` 3.2G).
- `~/VirtualBox VMs` (4.5G) dan ISO: pindahkan ke partisi `nvme0n1p2` yang masih kosong sekitar 52G.

## Catatan sudo

Perintah dengan awalan `!` di Claude Code tidak bisa meminta password, sehingga sudo gagal dengan pesan `sudo: A terminal is required to authenticate`. Jalankan perintah sudo di jendela terminal biasa.
