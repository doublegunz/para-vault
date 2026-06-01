---
title: "Menggunakan Password_hash() Dan Password_verify()"
slug: "menggunakan-password-hash-dan-password-verify"
category: "php"
date: "2016-06-11"
status: "published"
---

Keamanan password selalu menjadi topik hangat dalam pengembangan aplikasi web. Sebagai developer, kita sering menemui pertanyaan tentang cara terbaik menyimpan password di database - haruskah menggunakan MD5, SHA1, atau metode lainnya? Pertanyaan ini sangat relevan mengingat meningkatnya ancaman keamanan di era digital.

Di artikel kali ini, kita akan membahas secara mendalam tentang password hashing di PHP modern. Kita akan menjelajahi evolusi metode hashing, mulai dari MD5 dan SHA1 yang sudah usang, hingga implementasi bcrypt yang menjadi standar industri saat ini. Saya akan menjelaskan mengapa beberapa metode tidak lagi aman digunakan, dan bagaimana mengimplementasikan solusi yang lebih baik menggunakan fungsi-fungsi bawaan PHP modern.

Yang menarik, PHP sudah menyediakan fungsi-fungsi bawaan yang powerful untuk menangani password hashing dengan aman. Kita akan mempelajari penggunaan praktis dari fungsi-fungsi ini, disertai dengan contoh kode yang bisa Anda terapkan langsung dalam project Anda. Mari kita mulai dengan memahami konsep dasarnya terlebih dahulu!

*Note: Tutorial ini ditujukan untuk developer PHP yang ingin meningkatkan keamanan aplikasi mereka, khususnya dalam hal manajemen password. Pastikan Anda menggunakan PHP versi 5.5 ke atas untuk mengikuti tutorial ini.*

## Memahami Password Hashing{#apa-itu-hash}

### Konsep Dasar Hash
Hash adalah fungsi satu arah yang mengubah data input menjadi string karakter acak dengan panjang tetap, yang disebut "hash value" atau "digest". Bayangkan seperti mesin penghancur kertas - sekali dokumen dihancurkan, tidak mungkin mengembalikannya ke bentuk asli.

**Karakteristik Utama Hash:**
- Satu arah (one-way function)
- Output panjang tetap
- Hasil deterministik (input sama = output sama)
- Perubahan kecil pada input menghasilkan hash yang sangat berbeda

### Evolusi Algoritma Hashing{#apa-itu-md5-dan-sha1}

#### 1. MD5 (Message-Digest Algorithm 5)
- Menghasilkan hash 128-bit
- **Status**: Tidak aman untuk password
- **Alasan**: Mudah dipecahkan dengan modern computing power
- Masih bisa digunakan untuk checksum file

#### 2. SHA-1 (Secure Hash Algorithm 1)
- Menghasilkan hash 160-bit
- **Status**: Tidak direkomendasikan untuk password
- **Alasan**: Vulnerable terhadap collision attacks
- Lebih kuat dari MD5, tapi tetap tidak cukup aman

#### 3. Modern Hashing: Bcrypt{#apa-itu-bcrypt}
Bcrypt adalah solusi modern untuk password hashing yang menawarkan:
- Built-in salt generation
- Adjustable work factor (cost)
- Resistant terhadap brute force attacks
- Hasil hash yang unik untuk input yang sama

**Fungsi PHP Modern untuk Password Hashing:**
```php
// 1. password_hash() - Membuat hash password
$hash = password_hash("password123", PASSWORD_DEFAULT);

// 2. password_verify() - Verifikasi password
$valid = password_verify("password123", $hash);

// 3. password_needs_rehash() - Cek perlu rehash
$needs_update = password_needs_rehash($hash, PASSWORD_DEFAULT);

// 4. password_get_info() - Informasi hash
$info = password_get_info($hash);
```

**Mengapa Bcrypt Lebih Aman:**
1. **Adaptive Function**: Bisa disesuaikan dengan peningkatan computing power
2. **Built-in Salt**: Otomatis menambahkan salt unik untuk setiap hash
3. **Slow Hashing**: Sengaja dibuat lambat untuk mencegah brute force
4. **Industry Standard**: Diakui dan digunakan secara luas

**Best Practices:**
- Selalu gunakan algoritma modern (Bcrypt/Argon2)
- Hindari MD5/SHA1 untuk password
- Gunakan cost factor yang sesuai dengan kebutuhan
- Implementasikan rate limiting untuk login attempts
- Regular security audit dan updates

*Note: Meskipun artikel ini fokus pada Bcrypt, Argon2 juga merupakan pilihan excellent untuk password hashing modern. Pilih sesuai kebutuhan aplikasi Anda.*

## Step 1 - Implementasi Password Hash dengan `password_hash()`{#step-1}

Mari kita mulai dengan implementasi dasar password hashing menggunakan fungsi `password_hash()`. Fungsi ini merupakan cara yang direkomendasikan PHP modern untuk mengamankan password.

```php
<?php 
    // Membuat hash dari password
    echo password_hash("mypassword123", PASSWORD_DEFAULT)."\n"; 
?>
```

Ketika kode di atas dijalankan, Anda akan mendapatkan output yang terlihat seperti ini:
```
$2y$10$uYEYjBw.sXE02evtHIsqwO2OE/XEIMYyXMI4FadLbpfhIvsg5dXba
```

**Mari kita pahami hasil hash tersebut:**
1. Awalan `$2y$` menandakan penggunaan algoritma bcrypt
2. Angka `10` adalah cost factor yang menentukan kompleksitas hash
3. Sisa karakter adalah kombinasi dari salt dan hash password

**Penting untuk diketahui:**
- Setiap kali Anda menjalankan fungsi `password_hash()`, hasilnya akan berbeda meskipun passwordnya sama
- Ini karena bcrypt secara otomatis menambahkan salt yang unik setiap kali fungsi dijalankan
- Cost factor dapat disesuaikan berdasarkan kebutuhan keamanan (default: 10)

## Step 2 - Verifikasi Password dengan `password_verify()`{#step-2}

Setelah password di-hash, kita perlu cara untuk memverifikasi saat user login. Di sinilah fungsi `password_verify()` berperan.

```php
<?php 
// Hash yang tersimpan (hasil dari password_hash)
$hash = '$2y$10$uYEYjBw.sXE02evtHIsqwO2OE/XEIMYyXMI4FadLbpfhIvsg5dXba'; 

// Verifikasi password
if (password_verify('mypassword123', $hash)) { 
    echo 'Password valid!'; 
} else { 
    echo 'Password tidak valid!'; 
} 
?>
```

**Cara kerja `password_verify()`:**
1. Fungsi akan mengambil password yang diinput dan hash yang tersimpan
2. Secara otomatis mengekstrak informasi salt dan cost dari hash tersimpan
3. Melakukan proses hashing pada password input menggunakan salt yang sama
4. Membandingkan hasil hash baru dengan hash yang tersimpan
5. Mengembalikan TRUE jika cocok, FALSE jika tidak

**Best Practices:**
- Selalu gunakan `password_verify()` untuk verifikasi, jangan membandingkan hash secara langsung
- Jangan simpan password asli dalam variabel lebih lama dari yang diperlukan
- Pertimbangkan untuk mengimplementasi pembatasan percobaan login
- Gunakan HTTPS untuk melindungi transmisi password

**Implementasi dalam Sistem Login:**
```php
<?php
class PasswordManager {
    public function createHash($password) {
        return password_hash($password, PASSWORD_DEFAULT, [
            'cost' => 12 // Sesuaikan berdasarkan kebutuhan
        ]);
    }
    
    public function verifyPassword($password, $hash) {
        return password_verify($password, $hash);
    }
}

// Contoh penggunaan
$pm = new PasswordManager();

// Saat user registrasi
$hash = $pm->createHash("mypassword123");

// Saat user login
if ($pm->verifyPassword("mypassword123", $hash)) {
    echo "Login berhasil!";
} else {
    echo "Password salah!";
}
?>
```

Dengan menggunakan kombinasi `password_hash()` dan `password_verify()`, Anda telah mengimplementasikan sistem autentikasi password yang aman sesuai dengan standar industri modern. Ingat untuk selalu mengikuti best practices dan secara regular memeriksa apakah ada kebutuhan untuk meningkatkan keamanan password dengan fungsi `password_needs_rehash()`.

## Penutup{#penutup}
Di era digital yang semakin berkembang ini, keamanan data pengguna, terutama password, menjadi tanggung jawab kritis bagi setiap developer. Kita telah mempelajari evolusi metode hashing password, dari yang sudah usang seperti MD5 dan SHA1, hingga solusi modern yang lebih aman seperti bcrypt.

Beberapa poin kunci yang perlu diingat:
1. **Gunakan Metode Modern**: Tinggalkan MD5 dan SHA1, beralih ke bcrypt atau Argon2
2. **Manfaatkan Fungsi Bawaan PHP**: 
   - `password_hash()` untuk membuat hash yang aman
   - `password_verify()` untuk verifikasi password
   - `password_needs_rehash()` untuk mengupgrade keamanan hash
3. **Implementasikan Best Practices**:
   - Selalu gunakan HTTPS untuk transmisi password
   - Terapkan rate limiting pada login attempts
   - Lakukan audit keamanan secara berkala
   - Update sistem secara reguler

Ingat bahwa keamanan adalah proses yang berkelanjutan. Selalu pantau perkembangan terbaru dalam keamanan web dan siap untuk mengadopsi metode yang lebih aman ketika tersedia. Dengan mengimplementasikan praktik-praktik keamanan modern ini, Anda telah mengambil langkah penting dalam melindungi data pengguna aplikasi Anda.

*"Security is not about convenience, it's about protection."*

**Resources Lanjutan:**
- [PHP Password Hashing Documentation](http://php.net/manual/en/book.password.php)
- [OWASP Password Storage Guidelines](https://owasp.org/www-project-password-storage-cheat-sheet/)
- [PHP Security Best Practices](https://phptherightway.com/#security)