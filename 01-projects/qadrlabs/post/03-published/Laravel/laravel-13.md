---
title: "Laravel 13"
slug: "laravel-13"
category: "Laravel"
date: "2026-02-09"
status: "published"
---

## Overview {#overview}

Laravel 13 adalah rilis besar berikutnya dari framework PHP Laravel yang direncanakan hadir pada kuartal pertama 2026. Berbeda dengan beberapa rilis sebelumnya yang membawa fitur “headline” yang cukup mencolok, Laravel 13 lebih menekankan pada modernisasi fondasi, penyederhanaan kode inti, serta peningkatan stabilitas dan pengalaman pengembangan. Bagi tim yang membangun dan memelihara aplikasi skala menengah hingga besar, fokus semacam ini biasanya jauh lebih berdampak daripada sekadar penambahan fitur baru di permukaan.

> **Catatan:** Per tanggal 17 Maret 2026, laravel 13 sudah resmi dirilis. Detail tentang rilisnya versi ini kita bahas pada artikel  [Laravel 13 Is Here](https://qadrlabs.com/post/laravel-13-is-here-ai-native-features-semantic-search-and-more).

Salah satu perubahan paling signifikan adalah peningkatan minimum requirement ke PHP 8.3. Dengan batas bawah ini, Laravel 13 dapat menyingkirkan banyak lapisan kompatibilitas lama, menghapus polyfill yang tidak lagi diperlukan, serta memanfaatkan fitur-fitur modern PHP secara lebih agresif. Selain itu, Laravel 13 disejajarkan dengan komponen Symfony terbaru (7.4 dan 8.0), yang menjadi fondasi HTTP, Console, Routing, dan berbagai bagian lain dari framework.

Di sisi fitur, Laravel 13 membawa sejumlah perbaikan praktis yang menyentuh area seperti cache (`Cache::touch()`), routing subdomain yang lebih deterministik, perbaikan grammar MySQL untuk query kompleks (`DELETE … JOIN` dengan `ORDER BY` dan `LIMIT`), hingga pengetatan perilaku Eloquent pada fase `boot()` model. Masing-masing terlihat kecil, namun jika digabung, memberikan pengalaman pengembangan yang lebih konsisten dan meminimalkan bug “aneh” yang sulit direproduksi.

Artikel ini akan membahas gambaran umum rilis Laravel 13, siklus support, persyaratan sistem, fitur teknis yang penting dipahami, serta implikasinya terhadap arsitektur aplikasi. Selain itu, akan dibahas juga praktik terbaik migrasi dan beberapa contoh konkret penggunaan fitur baru dalam konteks dunia nyata. Di bagian akhir, terdapat ringkasan kapan waktu terbaik untuk melakukan upgrade, terutama jika kita mengelola aplikasi produksi yang sensitif terhadap perubahan.


- [Overview](#overview)
- [Rilis dan Siklus Support Laravel 13](#rilis-dan-siklus-support-laravel-13)
- [Persyaratan Sistem dan Kompatibilitas](#persyaratan-sistem-dan-kompatibilitas)
- [Fokus Utama dan Filosofi Rilis](#fokus-utama-dan-filosofi-rilis)
- [Fitur dan Perubahan Teknis Penting](#fitur-dan-perubahan-teknis-penting)
- [Dampak Laravel 13 Terhadap Arsitektur Aplikasi](#dampak-terhadap-arsitektur-aplikasi)
- [Praktik Terbaik Migrasi ke Laravel 13](#praktik-terbaik-migrasi-ke-laravel-13)
- [Contoh Kasus Penggunaan Fitur Baru](#contoh-kasus-penggunaan-fitur-baru)
- [Kapan Sebaiknya Upgrade ke Laravel 13?](#kapan-sebaiknya-upgrade-ke-laravel-13)
- [Penutup](#penutup)
- [Referensi](#referensi)


## Rilis dan Siklus Support Laravel 13 {#rilis-dan-siklus-support-laravel-13}

Sebelum membahas detail teknis, penting untuk memahami posisi Laravel 13 di dalam roadmap versi Laravel secara keseluruhan. Informasi ini krusial untuk perencanaan jangka panjang, baik dari sisi budgeting, roadmap fitur, maupun manajemen risiko teknis.

Laravel mengikuti siklus rilis tahunan: setiap tahun biasanya ada satu rilis mayor (misalnya 11, 12, 13) dengan pola support yang konsisten. Untuk rilis non-LTS, Laravel memberikan dukungan bug fix selama 18 bulan dan security fix selama 2 tahun sejak rilis. Laravel 13 diproyeksikan rilis pada Q1 2026 (antara Januari–Maret 2026), dan akan mendapatkan bug fix hingga sekitar Q3 2027 serta security fix hingga sekitar Q1 2028.

Dalam praktiknya, ini berarti jika kita meng-upgrade ke Laravel 13 pada tahun 2026, kita memiliki jendela nyaman sekitar dua tahun untuk menjalankan aplikasi di versi ini sebelum benar-benar perlu memikirkan migrasi mayor berikutnya. Bagi organisasi yang membutuhkan siklus upgrade terencana (misalnya 12–18 bulan sekali), pola seperti ini mendukung strategi “rolling upgrade” yang berkelanjutan.

Perlu dicatat bahwa hingga saat artikel ini ditulis, Laravel 13 tidak diumumkan sebagai rilis LTS (Long-Term Support). Dengan demikian, aturan support yang berlaku adalah pola standar (18 bulan bug fix + 24 bulan security fix), bukan pola LTS yang lebih panjang. Ini bukan hal negatif; justru mayoritas aplikasi web modern cenderung diuntungkan dengan rilis yang lebih sering, agar dapat mengikuti perkembangan PHP dan ekosistem yang juga bergerak cepat.

## Persyaratan Sistem dan Kompatibilitas {#persyaratan-sistem-dan-kompatibilitas}

Laravel 13 membawa perubahan penting terkait kompatibilitas runtime dan dependency. Hal ini berpengaruh langsung pada kesiapan infrastruktur (server, container, CI/CD) dan kompatibilitas dengan paket-paket pihak ketiga yang kita gunakan.

### PHP 8.3 sebagai Minimum Requirement

Perubahan paling mencolok adalah peningkatan minimum PHP ke versi 8.3. Pull request di repositori Laravel 13.x secara eksplisit menetapkan PHP 8.3 sebagai requirement, sekaligus membersihkan banyak code path yang sebelumnya diperlukan untuk kompatibilitas dengan versi PHP yang lebih lama.

Dampak praktisnya:

- **Server dan lingkungan deploy** (VPS, bare-metal, Docker image) harus sudah menggunakan PHP 8.3 atau lebih tinggi.
- **CI/CD pipeline** yang menjalankan test suite Laravel perlu di-update agar tidak lagi menggunakan image PHP 8.1/8.2.
- **Paket pihak ketiga** yang belum kompatibel dengan PHP 8.3 berpotensi menjadi penghalang upgrade; kita perlu mengecek dukungan versi masing-masing paket.

Di sisi positif, PHP 8.3 membawa peningkatan performa, perbaikan type system, dan berbagai optimasi internal yang secara kumulatif membuat aplikasi Laravel lebih efisien. Penghapusan backward-compatibility layer juga mengurangi kompleksitas dan potensi bug di dalam framework itu sendiri.

### Dukungan Symfony 7.4 dan 8.0

Laravel dibangun di atas komponen Symfony untuk banyak hal penting seperti HTTP Foundation, Console, Routing, dan lain-lain. Pada Laravel 13, komponen ini diselaraskan dengan Symfony 7.4 dan 8.0, yang merupakan generasi terbaru dari ekosistem Symfony.

Keuntungan dari langkah ini antara lain:

- **Keamanan lebih baik** karena mendapatkan patch dan perbaikan dari versi Symfony terbaru.
- **Kompatibilitas jangka panjang** untuk aplikasi yang ingin hidup beberapa tahun ke depan tanpa harus refactor besar.
- **Perilaku yang lebih konsisten** dengan ekosistem PHP modern (misalnya perilaku `Request::get()` yang disejajarkan dengan perubahan di Symfony).

Namun konsekuensinya, paket yang bergantung pada perilaku lama komponen Symfony (atau mem-pinning versi komponen terlalu ketat) mungkin membutuhkan penyesuaian. Upgrade path yang baik harus selalu menyertakan pengecekan versi dependency melalui `composer outdated` dan membaca changelog paket-paket kritikal.

### Dampak ke Ekosistem Paket

Modernisasi dependency dan peningkatan requirement PHP membuat Laravel 13 sangat “future-oriented”, tetapi juga berarti ada langkah ekstra bagi maintainer paket untuk menyesuaikan diri. Beberapa hal yang perlu diantisipasi:

- Paket yang belum mengklaim dukungan PHP 8.3 bisa menyebabkan error saat instalasi atau runtime.
- Perubahan interface internal (misalnya pada manager, event, atau contract tertentu) bisa memengaruhi paket yang melakukan integrasi pada level yang cukup dalam.
- Sebaliknya, paket yang cepat mendukung Laravel 13 umumnya akan lebih mudah menarik pengguna baru karena banyak tim akan menjadikan “compat dengan 13” sebagai salah satu kriteria pemilihan.

Strategi yang bijak adalah menunggu beberapa minggu setelah rilis stabil, sambil memantau ekosistem paket yang kita gunakan, sebelum benar-benar memigrasikan aplikasi produksi yang sangat kritikal.

## Fokus Utama dan Filosofi Rilis {#fokus-utama-dan-filosofi-rilis}

Setiap rilis mayor Laravel biasanya memiliki “tema” atau fokus tertentu. Pada Laravel 13, berbagai pihak yang mengikuti development branch 13.x secara konsisten melaporkan bahwa fokus utamanya bukan pada “fitur marketing” yang mencolok, melainkan pada kualitas dan modernisasi internal.

Artinya, kita mungkin tidak menemukan fitur besar semisal “Jetstream baru”, “starter kit baru”, atau “satu abstraction layer baru yang mengubah segalanya”. Sebaliknya, kita akan melihat serangkaian pull request yang:

- Membersihkan kode lama yang tidak lagi relevan.
- Menyederhanakan kontrak dan perilaku yang selama ini membingungkan.
- Memperbaiki bug edge-case yang sulit dideteksi.
- Menguatkan integrasi dengan dependency utama seperti Symfony dan driver database.

Bagi tim engineering, filosofi ini sangat menguntungkan karena:

- Mengurangi **technical debt** yang selama ini diam-diam menumpuk.
- Membuat upgrade jangka panjang lebih mudah, karena semakin sedikit “beban masa lalu”.
- Menjadikan perilaku framework lebih “tebakable”, sehingga debugging dan observability menjadi lebih efektif.

Dengan kata lain, Laravel 13 adalah rilis yang sangat menarik untuk tim yang memprioritaskan stabilitas, maintainability, dan lifespan aplikasi yang panjang.

## Fitur dan Perubahan Teknis Penting {#fitur-dan-perubahan-teknis-penting}

Meskipun secara umum berfokus pada modernisasi dan stabilitas, Laravel 13 tetap membawa sejumlah perubahan teknis yang relevan untuk pengembangan sehari-hari. Bagian ini membahas beberapa highlight yang paling sering dibahas di komunitas.

### Perubahan pada Cache: `Cache::touch()` dan Store::touch()

Salah satu penambahan kecil tetapi praktis di Laravel 13 adalah hadirnya method `Cache::touch()` dan `Store::touch()` untuk memperpanjang TTL (time-to-live) sebuah cache key tanpa perlu membaca atau menulis ulang nilainya.

Sebelumnya, jika kita ingin memperpanjang masa berlaku cache, kita perlu melakukan pola seperti ini:

```php
$value = Cache::get('user:123');

if ($value !== null) {
    Cache::put('user:123', $value, now()->addMinutes(10));
}
```

Di Laravel 13, kita cukup menulis:

```php
Cache::touch('user:123', now()->addMinutes(10));
```

Perubahan ini tampak sederhana, namun:

- Mengurangi I/O ke store cache (khususnya jika nilai cache besar).
- Lebih mudah dibaca dan tidak memaksa kita memikirkan kembali logic serialisasi.
- Sangat berguna di aplikasi high-traffic yang heavily cached, misalnya aplikasi e-commerce atau SaaS multi-tenant.

### Peningkatan Routing Subdomain

Laravel 13 memperbaiki urutan registrasi routing untuk subdomain: rute yang terkait dengan domain/subdomain spesifik sekarang didaftarkan lebih dulu dibanding rute yang tidak terikat domain.

Secara praktis, hal ini mencegah situasi di mana:

- Kita memiliki rute `Route::domain('admin.example.com')->group(...);`
- Sekaligus rute generik `Route::get('/dashboard', ...)` tanpa domain.
- Framework memilih rute yang “salah” karena urutan registrasi yang kurang deterministik.

Dengan perubahan ini, rute yang lebih spesifik (mengikat domain/subdomain) akan memiliki prioritas yang lebih jelas. Bagi aplikasi multi-domain atau SaaS berbasis subdomain (tenant subdomain), peningkatan ini membantu menghindari bug routing yang sulit direproduksi di lingkungan tertentu.

### Restriksi Boot Time pada Model Eloquent

Laravel 13 memperkenalkan pembatasan penting di fase `boot()` Eloquent model. Intinya, framework mencegah pembuatan instance model baru di dalam method `boot()` model lain.

Contoh pola yang bermasalah:

```php
class Order extends Model
{
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($order) {
            // Di versi lama kadang ada yang memanggil model lain di sini
            $profile = UserProfile::firstOrCreate([...]);
            $order->profile_id = $profile->id;
        });
    }
}
```

Pola seperti ini dapat menyebabkan:

- Boot loop atau side effect yang sulit diprediksi.
- Query yang “diam-diam” berjalan saat model lain sedang di-booting.
- Ketergantungan siklik antar-model yang susah diurai.

Dengan pengetatan di Laravel 13, framework mendorong pemisahan concern: logic yang menyentuh beberapa model sekaligus sebaiknya dipindahkan ke service layer, observer, atau domain layer terpisah, bukan di dalam `boot()`. Hal ini sangat sejalan dengan prinsip clean architecture dan domain-driven design.

### Peningkatan HTTP Client dan Concurrency Pool

HTTP client di Laravel (berbasis `Http::`) juga mendapatkan penyesuaian default yang lebih aman. Pada Laravel 13, `PendingRequest::pool()` kini memiliki default concurrency bernilai `2`, bukan `null` (yang sebelumnya dapat menyebabkan request berjalan sekuensial walaupun tampak seperti concurrent).

Contoh sebelumnya:

```php
Http::pool(function ($pool) {
    return [
        $pool->get('https://service-a/api'),
        $pool->get('https://service-b/api'),
    ];
});
```

Jika concurrency `null`, ada risiko request dieksekusi tidak benar-benar paralel, sehingga developer salah mengasumsikan performa. Dengan default `2`, larik request di atas akan berjalan dengan concurrency minimal yang masuk akal, kecuali kita override secara eksplisit.

Ini meningkatkan:

- Kejelasan ekspektasi performa ketika menggunakan request pool.
- Pengalaman tuning API-aggregation layer dalam arsitektur microservices.

### Perbaikan Query Builder dan MySQL Grammar

Perubahan menarik lain ada pada dukungan query yang lebih kompleks di MySQL. Laravel 13 menyempurnakan grammar untuk `DELETE … JOIN` agar dapat meng-compile query dengan `ORDER BY` dan `LIMIT` secara benar.

Sebelumnya, query seperti:

```php
DB::table('orders')
    ->join('order_items', 'orders.id', '=', 'order_items.order_id')
    ->where('orders.status', 'canceled')
    ->orderBy('orders.created_at')
    ->limit(100)
    ->delete();
```

Bisa saja mengabaikan `ORDER BY` atau `LIMIT` di tingkat SQL yang dihasilkan, sehingga menghapus lebih banyak data dari yang diharapkan. Di Laravel 13, grammar ini diperbaiki agar `ORDER BY` dan `LIMIT` benar-benar diterapkan di query DELETE JOIN, membuat operasi batch delete menjadi lebih dapat diprediksi.

Untuk operasi maintenance, housekeeping, atau batch-processing di data besar, perbaikan ini sangat penting demi keamanan data.

### Perubahan pada Manager, Event, dan Notifikasi

Sejumlah perubahan kecil namun signifikan juga terjadi pada level manager, event, dan notifikasi:

- **Manager extend callback** kini selalu menerima instance manager yang sudah di-bind, sehingga konsisten di seluruh manager Laravel (cache, queue, filesystem, dsb). Ini memudahkan saat membuat custom driver.
- Event **`JobAttempted`** sekarang meneruskan objek exception sebenarnya, bukan sekadar informasi minimal. Ini memudahkan logging, observability, dan integrasi dengan sistem error tracking.
- Notifikasi email (verifikasi & reset password) mendapatkan penyelarasan subject line dan beberapa polish kecil untuk konsistensi UX.

Walaupun terlihat minor, perubahan ini membantu menjaga kualitas pengalaman pengguna dan integrasi internal dalam aplikasi besar yang heavily event-driven.

### Penyesuaian Pagination dan Naming Konvensi

Laravel 13 juga membawa perbaikan pada penamaan view pagination dan konvensi penamaan pivot table polymorphic:

- View pagination menggunakan nama yang lebih jelas dan konsisten, mengurangi kebingungan ketika kita mengoverride tampilan default.
- Penamaan tabel pivot polymorphic kini mengikuti bentuk plural secara konsisten, sehingga lebih seragam dengan dokumentasi dan best practice konvensi database Laravel.

Bagi tim yang mengandalkan konvensi untuk scaffolding otomatis dan pembacaan schema oleh developer baru, konsistensi seperti ini bisa mengurangi “cognitive overhead” saat membaca dan memahami struktur database.

## Dampak Laravel 13 Terhadap Arsitektur Aplikasi {#dampak-terhadap-arsitektur-aplikasi}

Setelah melihat fitur-fitur teknis, penting untuk menarik garis bagaimana Laravel 13 memengaruhi desain dan arsitektur aplikasi, terutama di skala menengah dan besar.

Pertama, **penghapusan kode legacy dan polyfill** membuat core Laravel menjadi lebih ramping. Dengan berkurangnya branch code untuk mendukung PHP versi lama dan edge case tertentu, perilaku framework menjadi lebih deterministik. Ini membantu dalam:

- Mengurangi kemungkinan bug yang hanya muncul di kondisi sangat spesifik.
- Mempermudah reasoning terhadap flow eksekusi, terutama di area seperti routing, middleware, dan event.

Kedua, **restriksi pada `boot()` model** mendorong pemisahan concern yang lebih tegas antara lapisan domain, persistence, dan infrastruktur. Praktik “segala sesuatu di taruh di model” yang dulunya umum di Laravel generasi awal, kini semakin nyata dinarasikan sebagai anti-pattern. Dengan pengetatan framework, developer didorong untuk menempatkan logic kompleks di:

- Service class atau domain service.
- Observer yang terisolasi dan memiliki tanggung jawab jelas.
- Job dan event listener yang decoupled.

Ketiga, **peningkatan pada routing subdomain dan HTTP client** membuat arsitektur layanan multi-tenant dan integrasi antar-service menjadi lebih andal. Routing yang deterministik dan pooling HTTP yang lebih jelas perilakunya memberikan fondasi yang baik untuk:

- API gateway atau BFF (Backend for Frontend) yang dibangun dengan Laravel.
- Arsitektur microservices atau service-oriented yang mengandalkan Laravel sebagai “orchestrator”.

Singkatnya, Laravel 13 mendorong gaya arsitektur yang lebih bersih, modular, dan selaras dengan praktik rekayasa perangkat lunak modern.

## Praktik Terbaik Migrasi ke Laravel 13 {#praktik-terbaik-migrasi-ke-laravel-13}

Migrasi ke versi mayor selalu mengandung risiko, meskipun Laravel terkenal cukup ramah upgrade. Bagian ini merangkum beberapa praktik terbaik yang dapat membantu transisi lebih mulus.

### Mempersiapkan Lingkungan dan Dependency

Langkah pertama yang realistis adalah memastikan seluruh rantai infrastruktur kita siap untuk PHP 8.3 dan dependency terbaru:

1. **Upgrade runtime** di environment non-produksi terlebih dahulu (local & staging).
2. Pastikan image Docker, konfigurasi server (Nginx/Apache), dan extension PHP sudah kompatibel dengan 8.3.
3. Jalankan `composer outdated` untuk melihat paket yang belum mendukung Laravel 13 atau PHP 8.3, dan cek dokumentasi mereka.
4. Jika memungkinkan, pisahkan dependency menjadi:
   - Paket inti (auth, queue, cache, database).
   - Paket opsional (UI components, admin panel, dsb).
   agar kita dapat meng-upgrade bagian inti terlebih dahulu.

### Strategi Upgrade Bertahap

Jika aplikasi kita masih di Laravel 10 atau lebih lama, sangat disarankan melakukan upgrade bertahap (misalnya 10 → 11 → 12 → 13) mengikuti panduan resmi upgrade di setiap rilis. Meskipun kadang mungkin secara teknis bisa “loncat” dua versi sekaligus, namun:

- Langkah kecil memudahkan isolasi bug jika ada perubahan perilaku.
- Dokumentasi upgrade tiap versi biasanya sudah cukup rinci dan memandu kita menyelesaikan breaking change yang umum.

Untuk aplikasi yang sudah di Laravel 12 dan PHP 8.2, migrasi ke 13 utamanya akan berputar di:

- Naik ke PHP 8.3.
- Memastikan tidak ada ketergantungan pada behavior lama yang telah diperketat (misalnya create model di `boot()`).
- Menyesuaikan area-area yang disebutkan di changelog 13.x (cache, routing, HTTP client, dsb).

### Pengujian, Observabilitas, dan Rollback Plan

Migrasi mayor tanpa test suite yang memadai adalah taruhan berisiko. Sebelum upgrade, idealnya:

- Minimal memiliki **test otomatis** untuk flow bisnis kritikal (auth, checkout, payment, proses order, dll).
- Menyiapkan **logging dan monitoring** (misalnya Laravel Telescope, Sentry, atau tool observability lain) untuk mendeteksi error yang lolos dari test.
- Menerapkan **blue-green deployment** atau paling tidak rollback plan yang jelas, sehingga kita dapat kembali ke versi lama jika ada bug serius yang hanya terdeteksi di fase awal produksi.

Dengan kombinasi test, observability, dan strategi deployment yang hati-hati, risiko migrasi ke Laravel 13 dapat ditekan secara signifikan.

## Contoh Kasus Penggunaan Fitur Baru {#contoh-kasus-penggunaan-fitur-baru}

Agar perubahan di Laravel 13 terasa lebih konkret, bagian ini menyajikan beberapa contoh kasus yang memanfaatkan fitur dan perbaikan baru.

### Memperpanjang Masa Berlaku Session Kustom dengan `Cache::touch()`

Bayangkan kita memiliki mekanisme session kustom berbasis cache (misalnya Redis). Kita ingin setiap kali user aktif, masa berlaku session diperpanjang tanpa harus menulis ulang seluruh data session.

```php
class SessionActivityMiddleware
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);

        if ($user = $request->user()) {
            $cacheKey = "session:user:{$user->id}";

            // Perpanjang TTL 30 menit ke depan jika key ada
            Cache::touch($cacheKey, now()->addMinutes(30));
        }

        return $response;
    }
}
```

Dengan pola ini, kita dapat menjaga session tetap ringan (tidak perlu serialize/deserialize setiap request) sekaligus memperbarui masa berlaku berdasarkan aktivitas user.

### Multi-Tenant Berbasis Subdomain yang Lebih Andal

Untuk aplikasi SaaS multi-tenant dengan pola `tenant_slug.example.com`, kita biasanya mengandalkan routing subdomain dan middleware tenant resolver. Di Laravel 13, prioritas rute domain-spesifik yang lebih jelas membantu mencegah konflik rute.

```php
Route::domain('{account}.example.com')
    ->middleware('resolve.tenant')
    ->group(function () {
        Route::get('/dashboard', [TenantDashboardController::class, 'index']);
    });

// Rute generik untuk non-tenant
Route::get('/dashboard', [PublicDashboardController::class, 'index']);
```

Dengan urutan registrasi yang dioptimalkan, request ke `acme.example.com/dashboard` akan lebih konsisten diarahkan ke rute tenant, sedangkan `example.com/dashboard` ke dashboard publik, tanpa konflik ambigu.

### Batch Delete Aman dengan `DELETE … JOIN` + `ORDER BY` + `LIMIT`

Misalkan kita ingin menghapus batch order yang sudah lama dibatalkan, bersama data terkait di tabel `order_items`, namun dengan batasan per batch untuk menghindari lock terlalu lama.

```php
DB::table('orders')
    ->join('order_items', 'orders.id', '=', 'order_items.order_id')
    ->where('orders.status', 'canceled')
    ->orderBy('orders.canceled_at')
    ->limit(1000)
    ->delete();
```

Dengan perbaikan grammar MySQL di Laravel 13, `ORDER BY` dan `LIMIT` dieksekusi sesuai ekspektasi, sehingga batch cleanup menjadi lebih aman dan terkontrol.

Contoh-contoh ini menunjukkan bagaimana peningkatan yang tampak minor justru berdampak besar dalam skenario real-world.

## Kapan Sebaiknya Upgrade ke Laravel 13? {#kapan-sebaiknya-upgrade-ke-laravel-13}

Keputusan kapan harus upgrade tidak bisa dijawab satu dimensi; ia bergantung pada konteks bisnis, ukuran tim, kompleksitas aplikasi, dan posisi kita di siklus rilis Laravel saat ini.

Secara umum, beberapa panduan praktis:

1. **Kita di Laravel 12, PHP 8.2, dan aplikasi cukup stabil**  
   - Pertimbangkan upgrade ke Laravel 13 dalam 3–6 bulan setelah rilis stabil.
   - Gunakan waktu tersebut untuk:
     - Menyiapkan PHP 8.3 di seluruh environment.
     - Menunggu ekosistem paket menyusul dukungan resmi akan Laravel 13.

2. **Kita di Laravel 11 atau lebih lama**  
   - Susun roadmap upgrade bertahap (11 → 12 → 13) dengan target paling lambat sebelum masa support security berakhir untuk versi kita.
   - Jangan menunda terlalu lama; semakin besar gap versi, semakin besar lompatan perubahan yang harus ditangani di satu waktu.

3. **Kita sedang mengerjakan proyek baru dengan timeline rilis fleksibel**  
   - Jika rilis proyek berada dekat atau setelah rilis stabil Laravel 13, masuk akal untuk memulai langsung di 13 agar lifespan proyek lebih panjang sebelum perlu upgrade mayor.
   - Namun jika dependencies kritikal kita belum siap untuk 13, kita bisa memulai di 12 dengan memastikan struktur kode didesain agar mudah di-upgrade.

4. **Aplikasi mission-critical dengan SLA ketat**  
   - Prioritaskan stabilitas: tunggu sampai Laravel 13 menerima beberapa patch minor (misalnya 13.1, 13.2) dan ekosistem paket yang kita gunakan menyatakan dukungan resmi.
   - Lakukan proof-of-concept atau branch eksperimen dengan 13.x-dev di environment terpisah terlebih dahulu, seperti yang dianjurkan banyak praktisi.

Secara ringkas, Laravel 13 adalah rilis yang layak ditargetkan sebagai baseline baru untuk aplikasi jangka panjang, tetapi waktu upgrade ideal sangat bergantung pada kesiapan ekosistem kita.

## Penutup {#penutup}

Laravel 13 menandai langkah penting dalam evolusi Laravel sebagai framework PHP modern. Alih-alih memperkenalkan fitur spektakuler yang mengubah cara kerja developer secara drastis, rilis ini memilih fokus pada modernisasi fondasi: mensyaratkan PHP 8.3, memperbarui dependency inti seperti Symfony, membersihkan kode legacy, serta menguatkan perilaku di area-area rawan seperti routing, cache, Eloquent, dan grammar database.

Bagi tim engineering, pendekatan ini menghasilkan framework yang lebih ramping, stabil, dan mudah dirawat dalam jangka panjang. Fitur-fitur baru seperti `Cache::touch()`, perbaikan routing subdomain, HTTP client pooling yang lebih jelas, serta pengetatan fase `boot()` Eloquent mungkin tampak kecil secara individu, tetapi akumulasi efeknya sangat terasa di aplikasi berskala sedang hingga besar. Ditambah dengan siklus support yang jelas (18 bulan bug fix + 24 bulan security fix), Laravel 13 memberi fondasi yang solid untuk membangun dan mengembangkan produk digital beberapa tahun ke depan.

**Key takeaway:**

- Laravel 13 adalah rilis yang berorientasi pada kualitas dan modernisasi, bukan sekadar penambahan fitur permukaan.
- PHP 8.3 sebagai minimum requirement dan dukungan Symfony 7.4/8.0 menjadikan Laravel 13 lebih siap menghadapi masa depan ekosistem PHP.
- Sejumlah perbaikan praktis di cache, routing, Eloquent, HTTP client, dan grammar MySQL secara langsung meningkatkan keandalan dan prediktabilitas aplikasi.
- Migrasi ke Laravel 13 sebaiknya direncanakan dengan matang: siapkan runtime, cek ekosistem paket, gunakan test dan observability yang memadai, dan lakukan upgrade bertahap bila perlu.
- Untuk aplikasi baru dengan horizon jangka panjang, Laravel 13 layak dipertimbangkan sebagai baseline, sementara aplikasi produksi yang sudah stabil dapat merencanakan upgrade dalam jendela 3–12 bulan setelah rilis, menyesuaikan konteks dan tingkat kritikalitasnya.

Dengan memahami konteks, fitur, dan implikasi arsitektural Laravel 13, tim pengembang dapat mengambil keputusan upgrade yang lebih terinformasi sekaligus memaksimalkan manfaat dari rilis mayor ini.

## Referensi {#referensi}

- Laravel Documentation – Release Notes & Support Policy (Laravel 11.x dan seterusnya).  
  https://laravel.com/docs/releases

- Pegotec. “What’s New in Laravel 13 — A Fresh Look Post-July 2025.” (2025).  
  `https://pegotec.net/whats-new-in-laravel-13-a-fresh-look-post-july-2025/`

- Pegotec. “Shortly Before the Laravel 13 Release: What Businesses Must Know Now.” (2025).  
  `https://pegotec.net/shortly-before-the-laravel-13-release-what-businesses-must-know-now/`

- Benjamin Crozat. “An Early Look at Laravel 13’s Features and Changes.” (2025).  
  `https://benjamincrozat.com/laravel-13`

- Cube. “Laravel 13: Key Updates & What’s New.” (2025).  
  `https://cube.nl/en/blog/laravel13`

- Nabil Hassen. “Laravel 13: New Features, Release Date, Install Now.” (2025).  
  `https://nabilhassen.com/laravel-13-new-features-release-date-install-now`

- LaravelUpdates. “Laravel Versions and Timelines of Security Fixes and Bug Fixes.” (2025).  
  `https://laravelupdates.com`

- Stack Developers (YouTube). “Laravel 13 Release Date & New Features | Laravel 13 Project Ideas.” (2026).  
  `https://www.youtube.com/watch?v=JXV_4iAhGD0`

- WpExperts. “Laravel Version History: Latest Releases.” (2025).  
  `https://wpexperts.io/blog/laravel-version-history/`