Laravel **13.27.0** dirilis pada **25 Agustus 2026**. Kalau dipilah dari seluruh changelog, ada sekitar **6 perubahan yang paling menarik untuk developer aplikasi**, bukan sekadar internal test/CI fixes. ([GitHub](https://github.com/laravel/framework/releases/tag/v13.27.0 "Release v13.27.0 · laravel/framework · GitHub"))

### 1. `refreshForUpdate()` di Eloquent — paling menarik

Ini menurut saya fitur paling berguna di release ini.

Masalah klasiknya: model sering sudah di-resolve sebelum transaction dimulai, misalnya lewat route model binding. Saat kita butuh pessimistic locking, biasanya harus query ulang:

```php
DB::transaction(function () use ($product) {
    $product = Product::query()
        ->lockForUpdate()
        ->findOrFail($product->getKey());

    if ($product->stock === 0) {
        throw new RuntimeException('Out of stock.');
    }

    $product->decrement('stock');
});
```

Sekarang cukup:

```php
DB::transaction(function () use ($product) {
    $product->refreshForUpdate();

    if ($product->stock === 0) {
        throw new RuntimeException('Out of stock.');
    }

    $product->decrement('stock');
});
```

`refreshForUpdate()` bekerja seperti `refresh()`, tetapi query refresh-nya menggunakan `lockForUpdate()`. Instance model yang sama diperbarui dengan state database terbaru sekaligus dikunci selama transaction. ([GitHub](https://github.com/laravel/framework/pull/61247 "[13.x] Add `refreshForUpdate()` method to Eloquent models by stevebauman · Pull Request #61247 · laravel/framework · GitHub"))

Ini sangat relevan untuk:

```text
stock inventory
wallet balance
ticket availability
coupon quota
seat booking
order processing
```

Secara konten, ini kandidat tutorial terbaik karena problem concurrency-nya nyata dan mudah didemonstrasikan.

---

### 2. MariaDB sekarang mendukung Vector Similarity Query Laravel

Ini menurut saya fitur kedua paling menarik, khususnya karena ekosistem AI.

Sebelumnya API vector Laravel seperti:

```php
whereVectorSimilarTo()
whereVectorDistanceLessThan()
orderByVectorDistance()
selectVectorDistance()
```

praktis diarahkan untuk PostgreSQL/pgvector.

Laravel 13.27 menambahkan dukungan native untuk **MariaDB vector distance**. MariaDB menggunakan fungsi native seperti `VEC_DISTANCE_COSINE`, sementara PostgreSQL tetap memakai mekanisme pgvector. ([GitHub](https://github.com/laravel/framework/pull/61250 "Add MariaDB support for vector distance queries by Rhaima96 · Pull Request #61250 · laravel/framework · GitHub"))

Artinya aplikasi Laravel dengan MariaDB sekarang dapat melakukan pola seperti:

```php
Document::query()
    ->orderByVectorDistance('embedding', $embedding)
    ->limit(10)
    ->get();
```

Use case:

```text
Semantic search
        ↓
Embeddings
        ↓
MariaDB VECTOR
        ↓
Laravel Query Builder
        ↓
Most similar documents
```

Ini menarik karena penggunaan vector database tidak selalu membutuhkan PostgreSQL + pgvector lagi.

Catatan penting: dukungan ini ditujukan untuk MariaDB yang memiliki native `VECTOR` support; plain MySQL standar masih belum mendapat dukungan vector distance yang sama melalui API tersebut. ([GitHub](https://github.com/laravel/framework/pull/61250 "Add MariaDB support for vector distance queries by Rhaima96 · Pull Request #61250 · laravel/framework · GitHub"))

Untuk topik LinkedIn, ini mungkin yang paling menarik secara headline:

**Laravel 13.27 brings native MariaDB vector similarity queries.**

---

### 3. Queue mendapatkan `totalXSize()` methods

Laravel sekarang punya cara yang lebih efisien untuk menghitung total job dari banyak queue.

Sebelumnya:

```php
$total = Queue::reservedSize('queue1')
    + Queue::reservedSize('queue2')
    + Queue::reservedSize('queue3');
```

Sekarang:

```php
$total = Queue::totalReservedSize();
```

Ada mekanisme serupa untuk pending dan delayed queue. ([GitHub](https://github.com/laravel/framework/pull/61231 "[13.x] Add Queue `totalXSize` methods by jackbayliss · Pull Request #61231 · laravel/framework · GitHub"))

Yang menarik bukan cuma syntax lebih pendek.

Implementasinya dibuat sebagai lightweight counterpart dari API yang mengambil seluruh job. Kalau kita cuma membutuhkan jumlah job:

```text
10 queues
500,000 jobs

↓
Need only count
```

Laravel tidak perlu mengambil dan decode seluruh payload job. ([GitHub](https://github.com/laravel/framework/pull/61231 "[13.x] Add Queue `totalXSize` methods by jackbayliss · Pull Request #61231 · laravel/framework · GitHub"))

Bagus untuk:

```text
Queue monitoring
Admin dashboard
Autoscaling
Worker metrics
Health checks
Capacity planning
```

Contohnya bisa menjadi:

```php
$metrics = [
    'pending' => Queue::totalPendingSize(),
    'reserved' => Queue::totalReservedSize(),
    'delayed' => Queue::totalDelayedSize(),
];
```

Ini sangat relevan untuk aplikasi production.

---

### 4. `whereBinary()` di Query Builder

Laravel 13.27 menambahkan:

```php
whereBinary()
orWhereBinary()
whereNotBinary()
orWhereNotBinary()
```

Tujuannya untuk melakukan **byte-exact / case-sensitive comparison** pada MySQL dan MariaDB tanpa `whereRaw()`. ([GitHub](https://github.com/laravel/framework/pull/61261 "[13.x] Add `whereBinary()` to the query builder by xiCO2k · Pull Request #61261 · laravel/framework · GitHub"))

Sebelumnya:

```php
DB::table('queues')
    ->whereRaw('name = BINARY ?', [$queueName])
    ->first();
```

Sekarang:

```php
DB::table('queues')
    ->whereBinary('name', $queueName)
    ->first();
```

Misalnya:

```text
Laravel
laravel
LARAVEL
```

Dengan collation MySQL tertentu, comparison biasa bisa dianggap sama.

`whereBinary()` memungkinkan kita meminta comparison yang benar-benar case-sensitive / byte-exact.

Ini berguna untuk:

```text
tokens
identifiers
external IDs
case-sensitive codes
hash-like values
queue identifiers
```

dan jauh lebih bersih daripada menulis raw SQL. ([GitHub](https://github.com/laravel/framework/pull/61261 "[13.x] Add `whereBinary()` to the query builder by xiCO2k · Pull Request #61261 · laravel/framework · GitHub"))

---

### 5. Laravel sekarang punya `Cloud` facade

Ini menarik dari sisi arah framework ke Laravel Cloud.

Sekarang tersedia:

```php
use Illuminate\Support\Facades\Cloud;
```

Kemudian:

```php
Cloud::hosted();
Cloud::usesManagedQueues();
Cloud::queue();
```

Misalnya:

```php
if (Cloud::hosted()) {
    // application runs on Laravel Cloud
}
```

Atau:

```php
$total = Cloud::queue()->totalReservedSize();
```

Tujuannya adalah memberikan satu API untuk mengetahui hubungan aplikasi dengan Laravel Cloud daripada menggabungkan berbagai driver check, helper, dan feature flag sendiri. ([GitHub](https://github.com/laravel/framework/pull/61275 "[13.x] Introduce a Cloud facade by jackbayliss · Pull Request #61275 · laravel/framework · GitHub"))

Secara arsitektur arahnya menarik:

```text
Laravel Application
        ↓
      Cloud
     Facade
   ↙        ↘
Hosted?    Managed Queue
```

Kemungkinan facade ini nantinya bisa berkembang ke resource Cloud lain juga; PR awalnya memang menyebut ruang ekspansi lebih lanjut. ([GitHub](https://github.com/laravel/framework/pull/61275 "[13.x] Introduce a Cloud facade by jackbayliss · Pull Request #61275 · laravel/framework · GitHub"))

---

### 6. Read-through Filesystem makin matang

Fitur read-through filesystem yang muncul di **13.26.0** langsung mendapat penyempurnaan penting di 13.27.0.

Sebelumnya kondisi ini bermasalah:

```text
PRIMARY
file belum ada

FALLBACK
source.txt ada
```

Read bekerja:

```php
Storage::disk('read-through')->get('source.txt');
```

tetapi `move()` dan `copy()` dapat gagal karena operasi tersebut hanya melihat primary disk.

Sekarang Laravel dapat melakukan:

```php
Storage::disk('read-through')
    ->copy('source.txt', 'archive/source.txt');
```

atau:

```php
Storage::disk('read-through')
    ->move('source.txt', 'archive/source.txt');
```

meskipun `source.txt` hanya ada di fallback disk. Laravel akan stream source dari fallback langsung ke destination di primary. Untuk `move()`, source fallback kemudian dihapus. ([GitHub](https://github.com/laravel/framework/pull/61272 "[13.x] Move and copy files that only exist on a read-through disk's fallback by sulimanbenhalim · Pull Request #61272 · laravel/framework · GitHub"))

Ini membuat use case seperti:

```text
Legacy S3
   ↓
read-through disk
   ↓
Cloudflare R2
```

semakin usable untuk migration storage bertahap.

---

Ada juga sejumlah improvement lain yang cukup bagus:

`orWhereKey()` dan `orWhereKeyNot()` diperkenalkan kembali dengan implementasi yang tidak merusak subclass custom Builder; process fake mendapatkan `stop()` dan `ensureNotTimedOut()`; PostgreSQL mendapat keepalive DSN options; SQS sekarang bisa share cached AWS credentials antar-process; Redis `mget()`/`hmget()` lebih aman terhadap return `false`; dan ada beberapa hardening pada validation serta request input handling. ([GitHub](https://github.com/laravel/framework/releases/tag/v13.27.0 "Release v13.27.0 · laravel/framework · GitHub"))

Kalau saya ranking berdasarkan **nilai untuk developer + potensi konten**, urutannya:

|Fitur|Nilai|
|---|--:|
|`refreshForUpdate()`|⭐⭐⭐⭐⭐|
|MariaDB Vector Search|⭐⭐⭐⭐⭐|
|Queue `totalXSize()`|⭐⭐⭐⭐½|
|`whereBinary()`|⭐⭐⭐⭐|
|`Cloud` facade|⭐⭐⭐⭐|
|Read-through filesystem improvements|⭐⭐⭐⭐|
|PostgreSQL/SQS/Redis improvements|⭐⭐⭐|

Untuk **post LinkedIn Laravel 13.27.0**, saya akan menjadikan visual utamanya bukan generic “Laravel update”, tetapi kombinasi konsep:

```text
              Laravel 13.27.0

                  Laravel
                     │
       ┌─────────────┼─────────────┐
       ↓             ↓             ↓
  Locked DB      Vector DB       Queue
 transaction      search       monitoring

       │             │             │
 refreshForUpdate  MariaDB      totalXSize

                     │
              Laravel Cloud
```

Jadi secara visual bisa ada **database row yang terkunci/refresh**, **vector nodes/embedding**, **queue pipeline**, **cloud infrastructure**, serta **storage migration**, dengan logo Laravel di tengah. Itu akan jauh lebih representatif terhadap isi 13.27.0 dibanding ilustrasi server generik. ([GitHub](https://github.com/laravel/framework/pull/61247 "[13.x] Add `refreshForUpdate()` method to Eloquent models by stevebauman · Pull Request #61247 · laravel/framework · GitHub"))

**Q1:** Buatkan ilustrasi LinkedIn 16:9 untuk Laravel 13.27.0 dengan konsep fitur-fitur ini, tanpa teks kecuali logo Laravel dan versi 13.27.0.

**Q2:** Buatkan caption LinkedIn untuk membahas fitur-fitur paling menarik Laravel 13.27.0 ini.

**Q3:** Jelaskan `refreshForUpdate()` lebih dalam dengan contoh race condition sebelum dan sesudah Laravel 13.27.0.