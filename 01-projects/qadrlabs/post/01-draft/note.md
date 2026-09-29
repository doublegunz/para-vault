sekarang untuk rilis berikut [https://github.com/laravel/framework/releases/tag/v13.34.0](https://github.com/laravel/framework/releases/tag/v13.34.0) 



- [13.x] Include duration in JobProcessed event by [**@jackbayliss**](https://github.com/jackbayliss) in [#61672](https://github.com/laravel/framework/pull/61672)
- [13.x] Notify job when a timeout is going to occur by [**@jackbayliss**](https://github.com/jackbayliss) in [#61651](https://github.com/laravel/framework/pull/61651)
- [13.x] Add --queue option to queue:flush by [**@jackbayliss**](https://github.com/jackbayliss) in [#61630](https://github.com/laravel/framework/pull/61630)
- Allow null in docblocks to match existing code by [**@miclf**](https://github.com/miclf) in [#61679](https://github.com/laravel/framework/pull/61679)
- [13.x] Support LazyCollection values in between clauses by [**@vikas-kushwaha-dev**](https://github.com/vikas-kushwaha-dev) in [#61678](https://github.com/laravel/framework/pull/61678)
- [13.x] Sync refreshed attributes to original state after increment / decrement by [**@ilhammmaulana**](https://github.com/ilhammmaulana) in [#61680](https://github.com/laravel/framework/pull/61680)
- [13.x] Fix `Number::parseInt()` returning false for values above 32-bit range by [**@sumaiazaman**](https://github.com/sumaiazaman) in [#61691](https://github.com/laravel/framework/pull/61691)
- [13.x] Fix `PhpRedisLock::refresh()` when phpredis serialization is enabled by [**@sumaiazaman**](https://github.com/sumaiazaman) in [#61690](https://github.com/laravel/framework/pull/61690)
- [13.x] Fix Collection::mode() returning values not present in the data when nulls exist by [**@MoZayedSaeid**](https://github.com/MoZayedSaeid) in [#61686](https://github.com/laravel/framework/pull/61686)
- [13.x] Adjust some worker docblocks by [**@jackbayliss**](https://github.com/jackbayliss) in [#61683](https://github.com/laravel/framework/pull/61683)
- [13.x] Respect the relation's owner key in whereMorphedTo / whereNotMorphedTo by [**@axlon**](https://github.com/axlon) in [#61712](https://github.com/laravel/framework/pull/61712)
- Enforce morph map on read side of polymorphic relations by [**@paulinevos**](https://github.com/paulinevos) in [#61711](https://github.com/laravel/framework/pull/61711)
- [13.x] Display error in `queue:restart` when worker isn't restartable by [**@jackbayliss**](https://github.com/jackbayliss) in [#61706](https://github.com/laravel/framework/pull/61706)
- [13.x] Test Improvements by [**@crynobone**](https://github.com/crynobone) in [#61697](https://github.com/laravel/framework/pull/61697)
- [13.x] Throw ValueError in LazyCollection::combine() on mismatched lengths by [**@mrjavadseydi**](https://github.com/mrjavadseydi) in [#61696](https://github.com/laravel/framework/pull/61696)
- [13.x] Fix `trans_choice()` picking the wrong plural form for negative numbers by [**@sumaiazaman**](https://github.com/sumaiazaman) in [#61700](https://github.com/laravel/framework/pull/61700)
- [13.x] Don't swallow deadlocks in `DatabaseLock` inside a transaction by [**@lazerg**](https://github.com/lazerg) in [#61708](https://github.com/laravel/framework/pull/61708)
- [13.x] Fix `sortBy()` with multiple columns and `SORT_NUMERIC` truncating fractional values by [**@sumaiazaman**](https://github.com/sumaiazaman) in [#61699](https://github.com/laravel/framework/pull/61699)
- [13.x] Fix Number::format(), percentage() and currency() returning "-0" by [**@mrjavadseydi**](https://github.com/mrjavadseydi) in [#61716](https://github.com/laravel/framework/pull/61716)
- [13.x] Allow assertDatabaseCount to accept an array by [**@jackbayliss**](https://github.com/jackbayliss) in [#61727](https://github.com/laravel/framework/pull/61727)
- [13.x] Fix multipart requests losing attached stream contents on retry by [**@mehdishakki**](https://github.com/mehdishakki) in [#61728](https://github.com/laravel/framework/pull/61728)
- [13.x] Allow enums in Queue::isPaused() by [**@jackbayliss**](https://github.com/jackbayliss) in [#61725](https://github.com/laravel/framework/pull/61725)
- [13.x] Fix double negation in Eloquent `whereNot()` with array conditions by [**@Nejcc**](https://github.com/Nejcc) in [#61721](https://github.com/laravel/framework/pull/61721)
- [13.x] Allow enums in environment checks by [**@Taldres**](https://github.com/Taldres) in [#61730](https://github.com/laravel/framework/pull/61730)
- [13.x] Return an empty collection from `shift($count)` on an empty collection by [**@Nejcc**](https://github.com/Nejcc) in [#61723](https://github.com/laravel/framework/pull/61723)
- [13.x] Test with real objects by [**@jasonmccreary**](https://github.com/jasonmccreary) in [#61663](https://github.com/laravel/framework/pull/61663)
- [13.x] Cloud exceptions by [**@timacdonald**](https://github.com/timacdonald) in [#61704](https://github.com/laravel/framework/pull/61704)
- [13.x] Run workflows on Windows 2025 by [**@jnoordsij**](https://github.com/jnoordsij) in [#61718](https://github.com/laravel/framework/pull/61718)
- [13.x] Use constant time lookups for validator exclusions by [**@owenconti**](https://github.com/owenconti) in [#61698](https://github.com/laravel/framework/pull/61698)
- [13.x] Preserve existing PDO options when forcing emulated prepares for pooled Cloud Postgres by [**@laurenschristian**](https://github.com/laurenschristian) in [#61735](https://github.com/laravel/framework/pull/61735)
- [13.x] Fix using elsePushIf blade directive with complex conditions by [**@mrjavadseydi**](https://github.com/mrjavadseydi) in [#61741](https://github.com/laravel/framework/pull/61741)
- [13.x] Fix Memcached locks longer than 30 days expiring immediately by [**@sumaiazaman**](https://github.com/sumaiazaman) in [#61742](https://github.com/laravel/framework/pull/61742)
- [13.x] Allow jobs to count worker crashes towards maxExceptions by [**@williamjulianvicary**](https://github.com/williamjulianvicary) in [#61737](https://github.com/laravel/framework/pull/61737)
- [13.x] Fix Redis throttle returning a timestamp as the remaining attempts by [**@sumaiazaman**](https://github.com/sumaiazaman) in [#61748](https://github.com/laravel/framework/pull/61748)
- Fix typos for Markdown files by [**@peter279k**](https://github.com/peter279k) in [#61746](https://github.com/laravel/framework/pull/61746)
- [13.x] Support named S3 credential providers and Cloud IAM disks by [**@kieranbrown**](https://github.com/kieranbrown) in [#61676](https://github.com/laravel/framework/pull/61676)
- [13.x] Supports `phpstan/phpstan:2.2.15` by [**@crynobone**](https://github.com/crynobone) in [#61719](https://github.com/laravel/framework/pull/61719)
- [13.x] feat: add the new 'Database\Schema\Builder::getColumn' method by [**@fgaroby**](https://github.com/fgaroby) in [#61759](https://github.com/laravel/framework/pull/61759)
- Apply fixes from StyleCI by [**@taylorotwell**](https://github.com/taylorotwell) in [#61763](https://github.com/laravel/framework/pull/61763)
- [13.x] Fix through() returning HasOneThrough for MorphMany relations by [**@mrjavadseydi**](https://github.com/mrjavadseydi) in [#61760](https://github.com/laravel/framework/pull/61760)
- [13.x] Exclude refreshed attributes when replicating models by [**@ilhammmaulana**](https://github.com/ilhammmaulana) in [#61751](https://github.com/laravel/framework/pull/61751)
- [13.x] Fix `wherePivotBetween()` being ignored by `sync()`, `detach()` and `updateExistingPivot()` by [**@sumaiazaman**](https://github.com/sumaiazaman) in [#61747](https://github.com/laravel/framework/pull/61747)
- [13.x] Fix flaky scheduling test on Windows by [**@jasonmccreary**](https://github.com/jasonmccreary) in [#61768](https://github.com/laravel/framework/pull/61768)
- [13.x] Fix findOrFail() with an array of enum ids by [**@jabysa**](https://github.com/jabysa) in [#61765](https://github.com/laravel/framework/pull/61765)
- [13.x] Fix `Builder::with()` when a null callback is passed explicitly by [**@lazerg**](https://github.com/lazerg) in [#61769](https://github.com/laravel/framework/pull/61769)
- Final Mockery cleanup by [**@jasonmccreary**](https://github.com/jasonmccreary) in [#61739](https://github.com/laravel/framework/pull/61739)
- [13.x] Treat dotted keys literally in ArrayStore::touch() by [**@Button99**](https://github.com/Button99) in [#61777](https://github.com/laravel/framework/pull/61777)
- [13.x] Fix memoized tagged cache `many()` returning null for numeric keys by [**@sajjadhossainshohag**](https://github.com/sajjadhossainshohag) in [#61780](https://github.com/laravel/framework/pull/61780)
- [13.x] Add regression test for createPayloadUsing on the queue manager by [**@fajarwz**](https://github.com/fajarwz) in [#61773](https://github.com/laravel/framework/pull/61773)
- [13.x] Add mime type to the files reportable details by [**@sbourouis**](https://github.com/sbourouis) in [#61772](https://github.com/laravel/framework/pull/61772)
- [13.x] Explicitly enable imagick extension for CI tests by [**@jnoordsij**](https://github.com/jnoordsij) in [#61756](https://github.com/laravel/framework/pull/61756)

Laravel **13.34.0** dirilis **29 September 2026**. Dari changelog-nya, rilis ini cukup kuat di area **queue observability**, **job resilience**, **cloud storage/IAM**, **schema introspection**, dan beberapa perbaikan Eloquent yang penting untuk aplikasi production. :chatgpt-content-reference{index="0"}

Yang menurut saya paling menarik:

1. **`JobProcessed` sekarang punya `duration`**
   
   Ini salah satu improvement paling berguna untuk observability queue. Sebelumnya kalau ingin tahu berapa lama job berjalan, kita perlu mencatat waktu saat `JobProcessing` lalu menghitung selisih saat `JobProcessed`. Sekarang event `JobProcessed` membawa properti `duration` dalam milidetik. :chatgpt-content-reference{index="1"}

   Contoh:

   ```php
   Event::listen(function (JobProcessed $event) {
       Log::info(
           "{$event->job->resolveName()} took {$event->duration}ms"
       );
   });
   ```

   Ini langsung berguna untuk:
   - mendeteksi job yang makin lambat
   - queue performance monitoring
   - alert regression
   - profiling background workloads

   Buat saya, ini salah satu fitur paling layak dijadikan konten.

2. **Job sekarang bisa diberi tahu sebelum timeout**
   
   Untuk job yang interruptible, Laravel sekarang meneruskan `SIGALRM` sebelum worker dimatikan akibat timeout. Artinya job punya kesempatan untuk bereaksi sebelum proses benar-benar berhenti. :chatgpt-content-reference{index="2"}

   Misalnya:

   ```php
   public function interrupted(int $signal): void
   {
       $this->saveProgress($this->progress);
   }
   ```

   Ini sangat menarik untuk pekerjaan panjang seperti:

   ```text
   AI inference
   video processing
   large imports
   report generation
   batch processing
   crawling
   ```

   Kalau job hampir timeout, state/progress bisa disimpan dulu sehingga pekerjaan tidak harus benar-benar dimulai dari nol.

3. **`queue:flush` sekarang bisa spesifik queue**
   
   Sebelumnya:

   ```bash
   php artisan queue:flush
   ```

   menghapus semua failed jobs.

   Sekarang bisa:

   ```bash
   php artisan queue:flush --queue=sftp-sync
   ```

   Jadi hanya failed jobs dari queue tertentu yang dibersihkan. :chatgpt-content-reference{index="3"}

   Ini sangat berguna saat satu integration bermasalah, misalnya third-party API down:

   ```text
   emails         ✓
   payments       ✓
   sftp-sync      ✗ 500 failed jobs
   reports        ✓
   ```

   Kita tidak perlu ikut menghapus failed jobs queue lain.

4. **S3 mendukung named credential providers + Cloud IAM disks**
   
   Ini improvement infrastructure yang cukup besar.

   Laravel sekarang mendukung credential provider seperti:

   ```php
   'credentials' => 'ecs'
   ```

   atau:

   ```php
   'credentials' => 'instance'
   ```

   termasuk scenario Cloud dengan IAM / Pod Identity. :chatgpt-content-reference{index="4"}

   Artinya deployment bisa lebih dekat ke pattern cloud-native:

   ```text
   Laravel App
       ↓
   IAM / Pod Identity
       ↓
      S3
   ```

   tanpa menyimpan:

   ```text
   AWS_ACCESS_KEY_ID
   AWS_SECRET_ACCESS_KEY
   ```

   secara statis di environment untuk setiap disk.

   Ini penting dari sisi:
   - security
   - credential rotation
   - Kubernetes/ECS environments
   - Laravel Cloud

5. **`Schema::getColumn()`**
   
   Laravel sekarang punya API yang lebih langsung untuk mengambil metadata satu column:

   ```php
   Schema::getColumn('users', 'email');
   ```

   Implementasinya mengambil data dari `getColumns()` lalu mengembalikan informasi column yang diminta. :chatgpt-content-reference{index="5"}

   Sebelumnya developer biasanya melakukan:

   ```php
   collect(Schema::getColumns('users'))
       ->firstWhere('name', 'email');
   ```

   Sekarang lebih bersih:

   ```php
   $column = Schema::getColumn('users', 'email');
   ```

   Berguna untuk:
   - database inspection tools
   - migration utilities
   - admin tooling
   - schema comparison
   - dynamic data importers

6. **Morph map sekarang lebih konsisten di read side**
   
   Laravel memperketat polymorphic relationship agar enforced morph map juga berlaku saat membaca relationship. :chatgpt-content-reference{index="6"}

   Ini penting kalau aplikasi menggunakan:

   ```php
   Relation::enforceMorphMap([
       'post' => Post::class,
       'video' => Video::class,
   ]);
   ```

   Tujuannya menjaga agar aplikasi tidak diam-diam kembali menggunakan fully-qualified class name ketika membaca polymorphic data.

   Ini bagus untuk stabilitas data model jangka panjang.

7. **`whereMorphedTo()` sekarang menghormati custom owner key**
   
   `whereMorphedTo()` dan `whereNotMorphedTo()` sekarang menggunakan owner key relationship dengan benar. :chatgpt-content-reference{index="7"}

   Ini relevan jika polymorphic relation tidak menggunakan default primary key `id`, misalnya:

   ```text
   uuid
   public_id
   external_id
   ```

8. **Worker crash bisa dihitung ke `maxExceptions`**
   
   Laravel sekarang mengizinkan worker crashes ikut dihitung terhadap batas `maxExceptions`. :chatgpt-content-reference{index="8"}

   Ini penting karena crash level process sebelumnya tidak selalu diperlakukan sama seperti exception dari kode job.

   Untuk job berat:

   ```text
   Out of memory
   segmentation/process crash
   unexpected worker termination
   ```

   sistem retry sekarang bisa lebih realistis dan tidak terus mengulang workload yang memang bermasalah.

9. **Database deadlock tidak lagi “ditelan” oleh `DatabaseLock`**
   
   Ketika `DatabaseLock` dipakai di dalam transaction, deadlock sekarang tidak lagi disembunyikan. :chatgpt-content-reference{index="9"}

   Ini penting untuk concurrency karena deadlock adalah error database yang seharusnya terlihat dan bisa diretry/ditangani dengan benar.

10. **Multipart HTTP retry sekarang mempertahankan stream**
    
    Ada bugfix penting untuk:

    ```text
    Http client
        ↓
    multipart upload
        ↓
    retry()
    ```

    Sebelumnya attached stream bisa kehilangan content saat request di-retry. Sekarang stream tersebut dipertahankan. :chatgpt-content-reference{index="10"}

    Ini relevan untuk:
    - file uploads
    - API integration
    - S3-compatible services
    - media processing APIs

11. **Enum support makin luas**
    
    Laravel 13.34 melanjutkan tren penggunaan enum dengan menambahkan support pada:

    ```php
    Queue::isPaused()
    ```

    dan environment checks. :chatgpt-content-reference{index="11"}

    Ini membantu mengurangi magic strings:

    ```php
    enum QueueName: string
    {
        case Emails = 'emails';
        case Reports = 'reports';
    }
    ```

    lalu:

    ```php
    Queue::isPaused(QueueName::Emails);
    ```

12. **Testing: `assertDatabaseCount()` menerima array**
    
    Ini improvement kecil tapi ergonomis:

    ```php
    $this->assertDatabaseCount([
        'users' => 10,
        'orders' => 25,
    ]);
    ```

    daripada assertion terpisah satu per satu. :chatgpt-content-reference{index="12"}

Ada juga beberapa bugfix production-grade yang cukup bagus: fix Redis throttle remaining attempts, Memcached lock >30 hari, `Number::parseInt()` untuk nilai besar, fractional sorting pada `sortBy()`, `wherePivotBetween()` pada `sync()` / `detach()`, memoized tagged cache, dan berbagai polymorphic/Eloquent edge case. :chatgpt-content-reference{index="13"}

Kalau saya pilih **fitur terbaik untuk konten LinkedIn**, urutannya:

| Fitur | Potensi |
|---|---:|
| Job timeout notification / interruptible job | ⭐⭐⭐⭐⭐ |
| `JobProcessed::$duration` | ⭐⭐⭐⭐⭐ |
| S3 IAM credential providers | ⭐⭐⭐⭐⭐ |
| `queue:flush --queue=` | ⭐⭐⭐⭐½ |
| `Schema::getColumn()` | ⭐⭐⭐⭐ |
| Morph map improvements | ⭐⭐⭐⭐ |
| Worker crashes → `maxExceptions` | ⭐⭐⭐⭐ |
| Multipart retry fix | ⭐⭐⭐½ |
