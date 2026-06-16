## 1. Sebelum Anda Memulai

Feature test menjalankan seluruh aplikasi, yang berharga tetapi lambat. Beberapa logika cukup mandiri sehingga Anda tidak membutuhkan database, routing, atau view untuk mengujinya. Unit test berfokus pada potongan kode yang kecil dan terisolasi: satu method, satu accessor, satu perhitungan. Mereka berjalan dalam milidetik karena tidak menyentuh resource eksternal, yang mendorong Anda menulis banyak dari mereka dan menjalankannya sering.

Lesson ini mengajarkan unit testing di Laravel menggunakan Pest. Anda akan menguji accessor model Entry (excerpt, reading time) dan scope (search, recent) tanpa melibatkan database. Anda juga akan mempelajari kapan memilih unit test versus feature test, karena masing-masing jenis memiliki tempatnya. Di akhir, Anda akan memiliki sebuah unit test suite kecil bersama feature test, memberi Anda dua lapisan cakupan test: test fokus yang cepat untuk logika individual dan test yang lebih luas untuk alur end-to-end.

### What You'll Build

Anda akan menulis unit test untuk accessor excerpt, accessor reading time, mutator title, dan method `scopeSearch`.

### What You'll Learn

- ✅ Unit test vs. feature test: kapan menggunakan masing-masing
- ✅ Menguji accessor tanpa database
- ✅ Menguji mutator
- ✅ Menguji scope dengan setup database minimal
- ✅ Helper `dataset()` untuk pengujian dengan beberapa input
- ✅ Menjalankan hanya unit test dengan `--testsuite=Unit`

### What You'll Need

- Lesson 11 sudah selesai dengan Pest terinstal

---

## 2. Feature Test vs. Unit Test

Sebelum menulis unit test, Anda perlu memahami kapan harus memilihnya. Feature test lebih luas tetapi lebih lambat. Unit test lebih sempit tetapi lebih cepat. Test suite yang baik menggunakan keduanya: banyak unit test untuk logika individual, lebih sedikit feature test untuk alur user yang penting.

Pertimbangkan accessor `excerpt` dari Lesson 3. Sebuah feature test akan membuat user, membuat entri, mengunjungi halaman index, dan memeriksa HTML untuk teks yang dipotong. Itu bekerja, tetapi memerlukan database, HTTP routing, dan rendering Blade. Sebuah unit test hanya membuat sebuah Entry di memori, mengatur content-nya, dan memeriksa output excerpt. Logika yang sama diuji, tetapi unit test berjalan dalam kurang dari 1 ms sementara feature test memakan 50 ms atau lebih.

Aturan praktisnya adalah: tulis unit test untuk logika murni yang tidak membutuhkan HTTP atau database, dan tulis feature test untuk alur user-facing (login, CRUD, authorization). Scope, accessor, mutator, dan class helper adalah kandidat unit test yang sempurna karena mereka stateless atau beroperasi sepenuhnya pada data in-memory.

---

## 3. Unit Test Pertama Anda

Model Entry memiliki beberapa accessor dan sebuah mutator yang merupakan logika PHP murni: mereka beroperasi pada property in-memory dan tidak menyentuh database. Ini adalah kandidat unit test yang ideal. Di section ini Anda akan membuat file unit test dan menulis test untuk accessor `excerpt`, accessor `reading_time`, dan mutator `title`.

### Step 1: Membuat Unit Test

Jalankan perintah Artisan berikut untuk membuat sebuah file unit test.

```bash
php artisan make:test EntryUnitTest --unit
```

Flag `--unit` menempatkan test di `tests/Unit/` alih-alih `tests/Feature/`, dan kerangkanya tidak menyertakan helper HTTP secara default, yang menjaga unit test tetap fokus pada logika PHP murni.

### Step 2: Menguji Accessor Excerpt

Buka `tests/Unit/EntryUnitTest.php` dan ganti kontennya dengan dua test berikut.

```php
<?php

use App\Models\Entry;

test('excerpt truncates content to 100 characters', function () {
    $entry = new Entry([
        'content' => str_repeat('A', 200),
    ]);

    expect($entry->excerpt)->toHaveLength(103);
});

test('excerpt keeps short content as-is', function () {
    $entry = new Entry(['content' => 'Short content']);

    expect($entry->excerpt)->toBe('Short content');
});
```

Memeriksa test ini dengan cermat: kita menggunakan `new Entry([...])` untuk membuat sebuah model Entry di memori tanpa menyimpannya ke database. Mass assignment melalui constructor bekerja karena `content` terdaftar di attribute `#[Fillable]`. Wawasan kuncinya adalah kita tidak memanggil `->save()`, sehingga tidak ada query database yang terjadi sama sekali. Kita menguji logika accessor dalam PHP murni.

Test pertama membuat content sepanjang 200 karakter menggunakan fungsi `str_repeat` PHP dan mengharapkan excerpt menjadi 103 karakter total: 100 karakter pertama ditambah ellipsis "..." tiga karakter default yang ditambahkan oleh helper `str()->limit()` Laravel. Test kedua menggunakan content yang lebih pendek dari 100 karakter, sehingga tidak ada pemotongan yang seharusnya terjadi dan output `excerpt` seharusnya cocok dengan content asli secara persis.

### Step 3: Menguji Accessor Reading Time

Tambahkan dua test lagi ke file yang sama, di bawah test excerpt.

```php
test('reading time is at least 1 minute for short content', function () {
    $entry = new Entry(['content' => 'Just a few words.']);

    expect($entry->reading_time)->toBe(1);
});

test('reading time calculates based on 200 words per minute', function () {
    $entry = new Entry([
        'content' => str_repeat('word ', 400),
    ]);

    expect($entry->reading_time)->toBe(2);
});
```

Setiap test menjalankan sebuah edge case tertentu dari accessor. Yang pertama mengonfirmasi batas minimum `max(1, ...)`: bahkan dengan kurang dari 200 kata, `reading_time` tidak pernah kurang dari 1 menit. Yang kedua mengonfirmasi formula pembagian: 400 kata dibagi 200 kata-per-menit sama dengan persis 2 menit. Kedua test ini memberi Anda keyakinan bahwa formula benar, dan refactoring di masa depan apa pun yang merusak perhitungan akan langsung tertangkap.

### Step 4: Menguji Mutator Title

Tambahkan satu test lagi untuk mutator title.

```php
test('title mutator capitalizes and trims', function () {
    $entry = new Entry();
    $entry->title = '  hello world  ';

    expect($entry->title)->toBe('Hello world');
});
```

Menugaskan ke `$entry->title` memicu callback `set` dari mutator, yang memangkas whitespace dan membuat huruf pertama menjadi kapital. Setelah penugasan, membaca `$entry->title` mengembalikan nilai yang sudah ditransformasi. Tidak diperlukan interaksi database karena mutator berjalan pada objek model itu sendiri selama penugasan property; hasilnya mencerminkan apa yang akan disimpan jika Anda memanggil `save()`.

---

## 4. Menguji Scope dengan Database Minimal

Beberapa test membutuhkan database, seperti test scope yang benar-benar mengeksekusi query SQL. Gunakan `RefreshDatabase` secara selektif di unit test untuk kasus-kasus ini. Beberapa puris berpendapat bahwa test scope termasuk dalam feature test karena mereka menyentuh database, tetapi mereka tetap sempit dan cukup cepat untuk masuk dengan nyaman ke dalam folder unit test.

### Step 1: Menguji Scope Search

Buka `tests/Unit/EntryUnitTest.php` dan tambahkan import `User` serta konfigurasi `uses()`, lalu tambahkan test scope berikut.

```php
use App\Models\User;

uses(Tests\TestCase::class, \Illuminate\Foundation\Testing\RefreshDatabase::class);

test('search scope finds entries by title', function () {
    $user = User::factory()->create();
    Entry::factory()->for($user)->create(['title' => 'Vacation Diary']);
    Entry::factory()->for($user)->create(['title' => 'Work Notes']);

    $results = Entry::search('vacation')->get();

    expect($results)->toHaveCount(1);
    expect($results->first()->title)->toBe('Vacation Diary');
});

test('search scope finds entries by content', function () {
    $user = User::factory()->create();
    Entry::factory()->for($user)->create([
        'title' => 'Random title',
        'content' => 'I went on vacation yesterday.',
    ]);

    $results = Entry::search('vacation')->get();

    expect($results)->toHaveCount(1);
});

test('search scope is case insensitive', function () {
    $user = User::factory()->create();
    Entry::factory()->for($user)->create(['title' => 'Vacation Diary']);

    expect(Entry::search('VACATION')->count())->toBe(1);
    expect(Entry::search('vacation')->count())->toBe(1);
    expect(Entry::search('VaCaTiOn')->count())->toBe(1);
});
```

Mari kita lihat test scope ini dengan cermat. Pemanggilan `uses(...)` mengambil dua argumen: `Tests\TestCase::class` mem-bootstrap aplikasi Laravel penuh (service container, koneksi database, facade) sehingga factory Eloquent dan query scope bekerja dengan benar di dalam unit test. Tanpanya, memanggil `User::factory()->create()` melemparkan error "facade root has not been set" karena tidak ada application container yang berjalan. `\Illuminate\Foundation\Testing\RefreshDatabase::class` memastikan setiap test dimulai dengan database yang bersih. Di test pertama, kita membuat dua entri dengan title yang berbeda, lalu memanggil scope dan mengharapkan persis satu hasil yang cocok dengan "vacation". Assertion `expect(...)->toHaveCount(1)` mengonfirmasi ukuran Collection, dan `toBe(...)` pada `title` mengonfirmasi entri yang benar dicocokkan.

Test kedua mengonfirmasi bahwa scope juga mencari field content, bukan hanya title. Test ketiga memverifikasi case insensitivity dengan menjalankan search yang sama dengan tiga kapitalisasi berbeda dan mengharapkan jumlah yang sama setiap kali. Ini penting karena SQL LIKE bersifat case-insensitive secara default di MySQL tetapi case-sensitive di beberapa database seperti PostgreSQL dengan collation tertentu, sehingga test eksplisit menangkap perbedaan halus saat berpindah database.

### Step 2: Menguji Beberapa Input dengan Dataset

Pest memungkinkan Anda menjalankan test yang sama dengan beberapa input menggunakan `->with(...)`. Tambahkan test berbasis dataset berikut untuk menggantikan tiga test case sensitivity terpisah dengan satu test terparametrisasi.

```php
test('search scope matches various capitalizations', function (string $query) {
    $user = User::factory()->create();
    Entry::factory()->for($user)->create(['title' => 'Vacation Diary']);

    expect(Entry::search($query)->count())->toBe(1);
})->with([
    'lowercase' => 'vacation',
    'uppercase' => 'VACATION',
    'mixed case' => 'VaCaTiOn',
    'partial match' => 'acat',
]);
```

Test tunggal ini berjalan empat kali, sekali per entri dataset. Key associative array menjadi label test di output Pest, membuat kegagalan mudah diidentifikasi karena label "uppercase" atau "partial match" muncul di samping kegagalan. Pola ini lebih bersih daripada menulis empat test terpisah karena logika setup dan assertion didefinisikan sekali. Menggunakan `->with()` sangat berharga untuk test validasi dengan banyak input valid dan tidak valid, atau test boundary dengan nilai batas.

---

## 5. Menjalankan Unit Test

Dengan test accessor, mutator, dan scope sudah berada di tempatnya, Anda sekarang dapat menjalankan suite untuk mengonfirmasi semuanya lulus. Pest menyediakan beberapa flag untuk mengendalikan test mana yang berjalan dan seberapa banyak detail yang ditampilkan. Perintah di bawah ini membawa Anda dari run penuh hingga ke run khusus unit yang tertarget dengan profiling.

### Step 1: Menjalankan Semua Test

Jalankan perintah berikut untuk mengeksekusi test suite penuh.

```bash
php artisan test
```

Anda akan melihat unit test terdaftar bersama feature test, dengan Pest dengan jelas memberi label setiap grup. Perhatikan kolom durasi; unit test seharusnya jauh lebih cepat daripada feature test.

### Step 2: Menjalankan Hanya Unit Test

Jalankan perintah berikut untuk mengeksekusi hanya unit test suite.

```bash
php artisan test --testsuite=Unit
```

Flag `--testsuite` hanya menjalankan test di suite yang ditentukan. Ini berguna selama development ketika Anda melakukan iterasi pada potongan logika tertentu; menjalankan unit test yang cepat saja memberi feedback yang ketat tanpa menunggu feature test yang lebih lambat.

### Step 3: Melihat Timing

Jalankan perintah berikut untuk melihat berapa lama setiap test berjalan.

```bash
php artisan test --profile
```

Flag `--profile` menampilkan test yang paling lambat sehingga Anda dapat mengidentifikasi kandidat untuk optimasi. Test yang memakan lebih dari 500 ms biasanya kandidat yang baik: ekstrak logika ke unit yang lebih kecil, mock dependensi yang mahal, atau hindari pemanggilan database jika memungkinkan.

### Step 4: Memeriksa Test Coverage (Opsional)

Jika Xdebug terinstal, Anda dapat mengukur cakupan kode dengan menjalankan perintah berikut.

```bash
php artisan test --coverage
```

Ini melaporkan berapa persen kode Anda yang dijalankan oleh test. Skor 100% tidak selalu menjadi tujuan (beberapa kode seperti file konfigurasi atau perintah CLI sulit untuk diuji), tetapi melihat file mana yang memiliki cakupan 0% sering mengungkap jalur kritis yang belum diuji yang membutuhkan perhatian.

---

## 6. Memperbaiki Error pada Kode Anda

Berikut adalah kesalahan paling umum saat menulis unit test untuk accessor, mutator, dan scope model.

**Error 1: Memanggil `->save()` di dalam sebuah unit test untuk pengujian accessor, secara tidak perlu menyentuh database.**

Error ini terjadi ketika seorang developer menyimpan model ke database hanya untuk menguji sebuah accessor, meskipun accessor bekerja sepenuhnya pada instance model in-memory tanpa persistensi apa pun.

```php
// Wrong: save() queries the database, requires a connection, and slows the test
test('excerpt works', function () {
    $entry = new Entry(['content' => str_repeat('A', 200)]);
    $entry->save();
    expect($entry->excerpt)->toHaveLength(103);
});

// Correct: accessors work on unsaved models, no database needed
test('excerpt works', function () {
    $entry = new Entry(['content' => str_repeat('A', 200)]);
    expect($entry->excerpt)->toHaveLength(103);
});
```

Versi yang salah memanggil `save()` sebelum menguji accessor. Ini memerlukan koneksi database, memicu migration (jika `RefreshDatabase` digunakan), dan membuat test menjadi satu orde lebih lambat dari yang diperlukan. Versi yang benar melewati `save()` sepenuhnya karena accessor `excerpt` membaca `$this->content`, yang tersedia saat model diinstansiasi dengan constructor array.

---

**Error 2: Menggunakan `Entry::factory()` tanpa trait `HasFactory` pada model Entry.**

Error ini terjadi ketika Anda mencoba menggunakan helper factory pada sebuah model yang tidak menyertakan trait `HasFactory`. Laravel tidak dapat menemukan method statis `factory()` dan melemparkan sebuah BadMethodCallException.

```php
// Wrong: HasFactory trait not present on the Entry model
class Entry extends Model
{
    use SoftDeletes;
    // HasFactory is missing
}

Entry::factory()->create(); // Throws BadMethodCallException: factory method not found

// Correct: include HasFactory so the factory() method is available
class Entry extends Model
{
    use HasFactory, SoftDeletes;
}

Entry::factory()->create(); // Works correctly
```

Versi yang salah menghilangkan `HasFactory` dari daftar trait model Entry. Setiap pemanggilan `Entry::factory()` di test kemudian melemparkan sebuah exception, merusak semua test yang menggunakan factory. Versi yang benar menambahkan `use HasFactory, SoftDeletes;` ke model. Sebagian besar model Laravel memiliki `HasFactory` secara default ketika dihasilkan dengan `make:model --factory`, tetapi model yang dibuat secara manual mungkin tidak.

---

**Error 3: Test berbagi kondisi database tanpa `RefreshDatabase`, menyebabkan assertion jumlah gagal secara tidak terduga.**

Error ini terjadi ketika beberapa test menulis ke database dan `RefreshDatabase` tidak diterapkan. Test yang lebih awal meninggalkan record, dan test yang lebih akhir melihatnya, menyebabkan assertion tentang jumlah record lulus atau gagal tergantung pada urutan eksekusi test.

```php
// Wrong: no database reset, tests contaminate each other
test('first test creates one entry', function () {
    $user = User::factory()->create();
    Entry::factory()->for($user)->create(['title' => 'A']);
    expect(Entry::count())->toBe(1); // Passes only if this runs before other entry-creating tests
});

test('second test expects empty database', function () {
    expect(Entry::count())->toBe(0); // Fails if first test already ran
});

// Correct: RefreshDatabase resets the database before each test
uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

test('first test creates one entry', function () {
    $user = User::factory()->create();
    Entry::factory()->for($user)->create(['title' => 'A']);
    expect(Entry::count())->toBe(1); // Always passes because database is clean
});

test('second test expects empty database', function () {
    expect(Entry::count())->toBe(0); // Always passes because database was reset
});
```

Tanpa `RefreshDatabase`, `Entry::count()` di test kedua menyertakan entri dari test pertama, menyebabkan kegagalan palsu. Dengan `RefreshDatabase`, setiap test dimulai dengan database yang benar-benar kosong, sehingga assertion jumlah selalu benar terlepas dari urutan eksekusi.

---

## 7. Latihan

Berlatihlah menulis unit test secara independen sebelum melihat solusinya. Setiap latihan mengembangkan file `EntryUnitTest.php` yang Anda bangun di lesson ini.

**Latihan 1:** Tulis unit test untuk method `scopeRecent`. Buat entri dengan timestamp `created_at` yang berbeda dan verifikasi scope mengembalikan hanya yang berasal dari dalam 7 hari terakhir.

**Latihan 2:** Tulis unit test untuk method `scopeByUser`. Buat dua user, masing-masing dengan dua entri, dan tegaskan bahwa `Entry::byUser($user1->id)->count()` mengembalikan persis 2.

**Latihan 3:** Tulis sebuah test dataset untuk accessor reading time dengan beberapa panjang content: 50 kata, 200 kata, 400 kata, dan 500 kata, masing-masing dengan reading time yang diharapkan dalam menit.

---

## 8. Solusi

Bandingkan solusi Anda dengan yang di bawah ini. Perhatikan pemanggilan factory dan gaya assertion, bukan hanya struktur kode.

**Solusi untuk Latihan 1:**

Tambahkan test berikut ke `tests/Unit/EntryUnitTest.php`.

```php
test('recent scope returns only entries from the last 7 days', function () {
    $user = User::factory()->create();

    Entry::factory()->for($user)->create(['created_at' => now()->subDays(3)]);
    Entry::factory()->for($user)->create(['created_at' => now()->subDays(10)]);

    expect(Entry::recent()->count())->toBe(1);
});
```

Kita membuat dua entri dengan nilai `created_at` eksplisit: satu dari 3 hari lalu (di dalam jendela 7 hari) dan satu dari 10 hari lalu (di luar jendela). Key array `created_at` pada factory menimpa timestamp default. `scopeRecent` menambahkan constraint `WHERE created_at >= ?` menggunakan `now()->subDays(7)`, sehingga hanya entri berusia 3 hari yang cocok. Assertion `toBe(1)` memverifikasi persis satu entri ditemukan.

---

**Solusi untuk Latihan 2:**

Tambahkan test berikut ke `tests/Unit/EntryUnitTest.php`.

```php
test('byUser scope returns only entries belonging to the given user', function () {
    $user1 = User::factory()->create();
    $user2 = User::factory()->create();

    Entry::factory()->for($user1)->count(2)->create();
    Entry::factory()->for($user2)->count(2)->create();

    expect(Entry::byUser($user1->id)->count())->toBe(2);
    expect(Entry::byUser($user2->id)->count())->toBe(2);
});
```

Kita membuat dua user dengan masing-masing dua entri, total empat entri di database. `scopeByUser` menambahkan constraint `WHERE user_id = ?`, sehingga setiap pemanggilan mengembalikan persis 2 entri milik user tersebut. Menjalankan assertion untuk kedua user mengonfirmasi scope tidak meluap melintasi batas user: entri `$user2` tidak terlihat saat memfilter berdasarkan `$user1->id`, dan sebaliknya. `RefreshDatabase` memastikan keempat entri adalah satu-satunya record yang ada, membuat assertion jumlah menjadi andal.

---

**Solusi untuk Latihan 3:**

Tambahkan test dataset berikut ke `tests/Unit/EntryUnitTest.php`.

```php
test('reading time calculates correctly for various word counts', function (int $wordCount, int $expectedMinutes) {
    $content = str_repeat('word ', $wordCount);
    $entry = new Entry(['content' => $content]);

    expect($entry->reading_time)->toBe($expectedMinutes);
})->with([
    [50, 1],
    [200, 1],
    [400, 2],
    [500, 3],
]);
```

Setiap baris dataset adalah sebuah array `[$wordCount, $expectedMinutes]`. Fungsi test menerimanya sebagai parameter bertipe. Baris pertama (50 kata) mengonfirmasi batas minimum 1 menit. Yang kedua (200 kata) memverifikasi bahwa batas tepat satu menit-baca tetap dibulatkan menjadi 1. Yang ketiga (400 kata) memverifikasi 400 / 200 = persis 2 menit. Yang keempat (500 kata) memverifikasi bahwa 500 / 200 = 2,5, yang dibulatkan ke atas oleh `ceil()` menjadi 3, mengonfirmasi bahwa menit parsial selalu dibulatkan ke atas. Pola ini menangkap error off-by-one dan bug pembulatan yang akan terlewat oleh satu test case tunggal.

---

## Selanjutnya - Lesson 13

Di lesson ini Anda membangun sebuah unit test suite yang fokus untuk logika model Catatku. Anda menguji accessor `excerpt` dengan menginstansiasi model Entry di memori tanpa menyimpan ke database, memverifikasi baik kasus pemotongan (103 karakter termasuk "...") maupun kasus content pendek (dikembalikan tanpa perubahan). Anda menguji accessor `reading_time` pada batas minimumnya dan pada batas formula yang tepat. Anda menguji mutator title dengan menugaskan secara langsung dan membaca hasil yang ditransformasi. Untuk test scope yang memerlukan SQL, Anda menerapkan `RefreshDatabase`, menggunakan factory Entry untuk membuat record dengan timestamp yang terkontrol, dan menggunakan dataset `->with([...])` untuk menguji beberapa query search dalam satu test terparametrisasi.

Di Lesson 13, Anda akan mempelajari queue dan job: bagaimana menunda operasi lambat seperti mengirim email ke worker background, menjaga web request tetap cepat dan responsif bahkan saat memicu task yang mahal.
