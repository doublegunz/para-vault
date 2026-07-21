# Mengatur Warna GNOME Terminal dengan Tema Monokai

Teks biru pada palet terminal bawaan kadang terlalu gelap saat dipakai di latar gelap. Panduan ini mengganti palet warna profil **GNOME Terminal** dengan nuansa **Sublime Text Monokai**, terutama menggunakan biru muda agar nama folder dan file lebih mudah dibaca.

> [!tip] Aman dicoba
> Buat salinan profil terlebih dahulu. Pengaturan warna hanya berlaku untuk profil GNOME Terminal dan tidak mengubah Bash, Git, maupun file proyek.

## Buat profil Monokai

1. Buka GNOME Terminal.
2. Klik menu tiga garis di kanan atas, lalu pilih **Preferences**.
3. Pada bagian **Profiles**, pilih profil yang sedang digunakan, misalnya **Unnamed** atau **Default**.
4. Klik panah di samping nama profil, lalu pilih **Clone…**.
5. Isi nama profil dengan `Monokai`, kemudian klik **Clone**.
6. Pilih profil `Monokai`, lalu buka bagian **Colors**.

## Atur warna dasar

1. Nonaktifkan **Use colors from system theme**.
2. Pada pilihan skema warna bawaan, pilih **Custom**.
3. Atur warna berikut dengan mengklik contoh warna lalu memasukkan kode hex-nya:

| Pengaturan | Kode warna | Keterangan |
| --- | --- | --- |
| Background color | `#272822` | Latar gelap khas Monokai |
| Text color | `#F8F8F2` | Teks utama putih lembut |
| Bold color | `#F8F8F2` | Teks tebal tetap mudah dibaca |
| Cursor color | `#F8F8F2` | Kursor terang |
| Highlight background color | `#49483E` | Latar teks yang diseleksi |
| Highlight text color | `#F8F8F2` | Teks yang diseleksi |

Jika tersedia, aktifkan **Show bold text in bright colors** agar keluaran perintah yang memakai warna terang lebih terlihat.

## Atur palet 16 warna

Masih di bagian **Colors**, ubah **Palette** menjadi nilai berikut. Urutan warnanya adalah: hitam, merah, hijau, kuning, biru, magenta, cyan, putih; lalu versi terang dengan urutan yang sama.

| Warna | Normal | Terang |
| --- | --- | --- |
| Hitam | `#272822` | `#75715E` |
| Merah | `#F92672` | `#F92672` |
| Hijau | `#A6E22E` | `#A6E22E` |
| Kuning | `#E6DB74` | `#E6DB74` |
| Biru | `#66D9EF` | `#66D9EF` |
| Magenta | `#AE81FF` | `#AE81FF` |
| Cyan | `#A1EFE4` | `#A1EFE4` |
| Putih | `#F8F8F2` | `#F8F8F0` |

Warna **Biru** memakai `#66D9EF`, yaitu biru-cyan terang. Ini yang membuat nama direktori dari perintah seperti `ls` lebih kontras dibanding biru gelap pada palet sebelumnya.

## Gunakan dan uji profil

1. Tutup jendela Preferences; perubahan disimpan otomatis.
2. Buka menu tiga garis, pilih **Change Profile**, lalu pilih `Monokai` untuk tab saat ini.
3. Jika ingin dipakai setiap kali membuka terminal, kembali ke **Preferences**, klik panah di samping profil `Monokai`, lalu pilih **Set as default**.
4. Jalankan perintah berikut untuk memastikan warna nama file dan folder terlihat jelas:

```bash
ls --color=always
```

## Mengembalikan warna semula

Pilih profil lama melalui menu **Change Profile**. Jika tidak lagi diperlukan, buka **Preferences**, pilih profil `Monokai`, klik panah di samping namanya, lalu pilih **Delete**. Profil awal tetap tidak berubah karena yang diedit adalah salinannya.

## Referensi

- [GNOME Help: Color schemes](https://help.gnome.org/users/gnome-terminal/3.20/app-colors.html.en)
- [GNOME Help: Manage profiles](https://help.gnome.org/gnome-terminal/pref-profiles.html)
