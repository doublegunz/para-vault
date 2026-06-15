


```
/home/linuxbrew/.linuxbrew/opt/php@8.3/bin/php $(which composer) install
```



```
/home/linuxbrew/.linuxbrew/opt/php@8.3/bin/php $(which composer) run dev
```



link php ke php brew
Untuk kembali memakai PHP dari Homebrew, link lagi package PHP yang ingin dipakai.

Misalnya ingin pakai `php@8.4`:

```bash
brew link php@8.4 --force --overwrite
hash -r
php -v
```

Kalau masih belum terbaca, tambahkan path Homebrew ke shell config:

```bash
echo 'export PATH="/home/linuxbrew/.linuxbrew/opt/php@8.4/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="/home/linuxbrew/.linuxbrew/opt/php@8.4/sbin:$PATH"' >> ~/.bashrc
source ~/.bashrc
hash -r
php -v
```

Cek hasilnya:

```bash
which php
php -v
```

Seharusnya mengarah ke:

```bash
/home/linuxbrew/.linuxbrew/bin/php
```

atau:

```bash
/home/linuxbrew/.linuxbrew/opt/php@8.4/bin/php
```

Kalau ingin ganti ke versi lain, misalnya `php@8.3`:

```bash
brew unlink php@8.4
brew link php@8.3 --force --overwrite
hash -r
php -v
```


Tidak perlu `brew link` untuk PHP bawaan sistem. Masalahnya kemungkinan **bash masih menyimpan cache path lama** ke Homebrew PHP.

Jalankan:

```bash
hash -r
php -v
```

Atau reload shell:

```bash
exec $SHELL -l
```

Cek detailnya:

```bash
type -a php
which php
/usr/bin/php -v
```

Kalau ingin memastikan memakai PHP bawaan sistem:

```bash
/usr/bin/php -v
```

Kalau setelah `hash -r` masih mengarah ke Homebrew, cek apakah ada alias:

```bash
alias php
```

Jika ada, hapus sementara:

```bash
unalias php
```

Jadi command utamanya:

```bash
hash -r
php -v
```