---
title: "Build AI App dengan Laravel AI SDK"
slug: "build-ai-app-dengan-laravel-ai-sdk"
category: "Laravel"
date: "2026-02-09"
status: "published"
---

## Overview {#overview}

Laravel AI SDK adalah paket resmi dari Laravel yang menyediakan API terpadu dan idiomatik untuk berinteraksi dengan berbagai penyedia AI modern seperti OpenAI, Anthropic, Gemini, dan lainnya. Dengan SDK ini, pengembang PHP dapat membangun agent AI, melakukan structured output, menjalankan tools (function calling), melakukan streaming respons, membuat embeddings, bekerja dengan file dan dokumen, hingga mengelola percakapan yang tersimpan di database — semuanya dengan gaya kode ala Laravel.

Artikel ini akan membahas konsep dasar Laravel AI SDK, arsitektur dan komponennya (providers, agents, tools, responses), cara instalasi dan konfigurasi, hingga contoh implementasi nyata seperti sales coach, dokument analyzer, dan chatbot support. Selain itu, akan dibahas juga bagaimana mengintegrasikan Laravel AI SDK dengan fitur-fitur inti Laravel seperti jobs, events, validation, serta bagaimana memikirkan arsitektur aplikasi AI-native yang scalable dan maintainable.

Di bagian akhir, akan dibahas tantangan, limitasi, serta beberapa best practice terkait keamanan, biaya, dan observabilitas. Artikel ini ditujukan untuk pengembang Laravel yang sudah familiar dengan konsep dasar framework dan ingin melangkah lebih jauh ke dunia aplikasi berbasis AI dengan fondasi yang kuat.

## Daftar Isi

- [Overview](#overview)  
- [Apa itu Laravel AI SDK](#apa-itu-laravel-ai-sdk)  
- [Mengapa Menggunakan Laravel AI SDK](#mengapa-menggunakan-laravel-ai-sdk)  
- [Arsitektur dan Konsep Dasar](#arsitektur-dan-konsep-dasar)  
- [Instalasi dan Konfigurasi Dasar](#instalasi-dan-konfigurasi-dasar)  
- [Konfigurasi Provider AI](#konfigurasi-provider-ai)  
- [Membangun Agent dengan Laravel AI SDK](#membangun-agent-dengan-laravel-ai-sdk)  
- [Tools, Structured Output, dan Function Calling](#tools-structured-output-dan-function-calling)  
- [Streaming, Antrian, dan Skalabilitas](#streaming-antrian-dan-skalabilitas)  
- [Bekerja dengan File, Dokumen, dan Embeddings](#bekerja-dengan-file-dokumen-dan-embeddings)  
- [Integrasi dengan Ekosistem Laravel](#integrasi-dengan-ekosistem-laravel)  
- [Use Case dan Contoh Implementasi](#use-case-dan-contoh-implementasi)  
- [Tantangan, Keamanan, dan Limitasi](#tantangan-keamanan-dan-limitasi)  
- [Penutup](#penutup)  
- [Referensi](#referensi)  

## Apa itu Laravel AI SDK {#apa-itu-laravel-ai-sdk}

Sebelum masuk ke detail teknis, penting untuk memahami apa sebenarnya Laravel AI SDK itu. Secara singkat, Laravel AI SDK adalah lapisan abstraksi di atas berbagai API penyedia AI yang mengemas kompleksitas integrasi menjadi API yang konsisten dan mudah digunakan di dalam aplikasi Laravel. Jika sebelumnya kita harus memanggil masing-masing provider (OpenAI, Anthropic, Gemini, dsb) dengan SDK atau HTTP client berbeda, kini kita bisa menggunakan satu API Laravel untuk mengakses semuanya.

Laravel AI SDK menyediakan beberapa kemampuan utama:

- API terpadu untuk berbagai penyedia AI (OpenAI, Anthropic, Gemini, dan lainnya).  
- Konsep *Agent* sebagai representasi "asisten" khusus (misalnya sales coach, document analyzer).  
- Dukungan structured output (menghasilkan array/DTO terstruktur, bukan hanya string).  
- Tools / function calling untuk mengizinkan model memanggil fungsi PHP kita.  
- Streaming respons untuk pengalaman real-time di UI atau CLI.  
- Integrasi dengan queue Laravel untuk pemrosesan async dan tahan lama.  
- Penyimpanan percakapan (conversation history) di database, siap dipakai ulang.

Dengan cara ini, Laravel AI SDK tidak hanya "membungkus" panggilan API AI, tetapi mendorong pola desain yang lebih bersih, terukur, dan Laravel-native untuk membangun aplikasi AI.


## Mengapa Menggunakan Laravel AI SDK {#mengapa-menggunakan-laravel-ai-sdk}

Ketika berbicara integrasi AI di Laravel, sebenarnya sudah ada banyak paket pihak ketiga seperti Prism, Laravel AI Toolkit, AI Orchestrator, dan integrasi khusus untuk Ollama. Pertanyaannya: apa nilai tambah menggunakan Laravel AI SDK resmi?

Alasan pertama adalah konsistensi API dan pengalaman pengembangan. Karena dikembangkan oleh tim Laravel, AI SDK mengikuti pola dan konvensi yang sama dengan komponen core lainnya: service provider, config terstruktur, artisan command, serta integrasi mendalam dengan container dan pipeline Laravel. Hal ini mengurangi friksi ketika tim besar mengadopsi atau memelihara kode dalam jangka panjang.

Alasan kedua adalah abstraksi yang berorientasi pada *agent*. Daripada menulis kode ad-hoc di controller atau service, kita didorong untuk membuat kelas agent khusus yang berisi instruksi, tools, serta skema output. Ini sangat sejalan dengan praktik domain-driven design (DDD) dan clean architecture, karena perilaku cerdas ditempatkan dalam komponen yang eksplisit dan dapat dites.

Alasan ketiga adalah *future-proofing*. Dunia AI bergerak cepat; provider dan model berubah, pricing berubah, fitur baru terus muncul. Dengan menggunakan API terpadu, kita dapat mengurangi kelekatan (coupling) langsung dengan satu vendor tertentu. Jika suatu saat perlu beralih dari OpenAI ke Anthropic atau menambahkan fallback ke Gemini, kita cukup menyesuaikan konfigurasi provider atau sedikit kode di agent alih-alih merombak seluruh aplikasi.


## Arsitektur dan Konsep Dasar {#arsitektur-dan-konsep-dasar}

Memahami arsitektur Laravel AI SDK akan membantu kita merancang aplikasi yang lebih rapi sejak awal. Di tingkat tinggi, ada beberapa konsep kunci: *providers*, *agents*, *messages/conversations*, *tools*, dan *responses*.

Secara garis besar, *provider* merepresentasikan penyedia layanan AI (OpenAI, Anthropic, Gemini, dan lain-lain). Setiap provider dikonfigurasi di file config, lengkap dengan API key, base URL, dan model default. Di atas provider, Laravel AI SDK memperkenalkan konsep *agent* sebagai kelas PHP yang mengenkapsulasi satu jenis "peran" atau "asisten". Agent inilah yang akan di-prompt dari berbagai bagian aplikasi (controller, job, listener).

*Messages* dan *conversations* menangani konteks dialog antara pengguna dan agent. Laravel AI SDK dapat menyimpan percakapan di database sehingga agent dapat memiliki *memory* yang persisten antar permintaan. Sementara itu, *tools* merupakan jembatan antara model AI dan kode PHP kita. Model Ai dapat melakukan permintaan untuk menjalankan fungsi tertentu, dan Laravel akan mengeksekusinya sesuai definisi kita.

Terakhir, *responses* mewakili hasil interaksi dengan model, baik berupa teks sederhana, output terstruktur (array/DTO), stream token demi token, hingga informasi penggunaan token. Semua ini dibungkus dalam kelas response yang konsisten sehingga mudah diolah di layer aplikasi kita.

## Instalasi dan Konfigurasi Dasar {#instalasi-dan-konfigurasi-dasar}

Sebuah fondasi yang baik dimulai dari instalasi dan konfigurasi yang benar. Laravel AI SDK didistribusikan sebagai paket composer resmi `laravel/ai`, sehingga proses instalasinya terasa sangat familiar bagi pengguna Laravel.

Untuk menginstall paket Laravel AI SDK, buka terminal lalu run command berikut ini:

```bash
composer require laravel/ai
```

Setelah paket terpasang, kita biasanya akan diminta untuk mem-publish konfigurasi dan migrasi yang dibutuhkan. Laravel AI SDK menggunakan tabel database untuk menyimpan percakapan agent, sehingga migrasi perlu dijalankan.

```bash
php artisan vendor:publish --provider="Laravel\Ai\AiServiceProvider"
```
Output yang ditampilkan:
```
php artisan vendor:publish --provider="Laravel\Ai\AiServiceProvider"

   INFO  Publishing assets.

  Copying file [vendor/laravel/ai/config/ai.php] to [config/ai.php] ..... DONE
  Copying file [vendor/laravel/ai/stubs/agent.stub] to [stubs/agent.stub]  DONE
  Copying file [vendor/laravel/ai/stubs/structured-agent.stub] to [stubs/structured-agent.stub]  DONE
  Copying file [vendor/laravel/ai/stubs/tool.stub] to [stubs/tool.stub] . DONE
  Copying directory [vendor/laravel/ai/database/migrations] to [database/migrations]  DONE
```

Selanjutnya kita run migrate command
```
php artisan migrate
```
Output yang ditampilkan:
```
php artisan migrate

   INFO  Running migrations.

  2026_02_09_095921_create_agent_conversations_table ............ 75.39ms DONE

```

Perintah `vendor:publish` akan menghasilkan file konfigurasi (misalnya `config/ai.php`) beserta migrasi untuk tabel seperti `agent_conversations` dan `agent_conversation_messages` yang digunakan untuk menyimpan riwayat interaksi. Dengan demikian, agent kita dapat menyimpan dan mengambil kembali konteks percakapan dengan cara yang idiomatik di Laravel.

Pada tahap ini, kita sudah memiliki kerangka dasar untuk menggunakan Laravel AI SDK. Langkah berikutnya adalah mengatur provider tertentu yang ingin digunakan dan menambahkan API key ke file `.env`.


## Konfigurasi Provider AI {#konfigurasi-provider-ai}

Setelah instalasi dasar, fokus utama berikutnya adalah konfigurasi provider. Laravel AI SDK mendukung beberapa provider populer seperti OpenAI, Anthropic, dan Gemini melalui konfigurasi yang konsisten. Konfigurasi ini umumnya ditempatkan di `config/ai.php` atau bagian serupa yang dihasilkan oleh proses `vendor:publish`.

Secara konseptual, konfigurasi provider dapat berbentuk seperti berikut:

```php
// config/ai.php (contoh ilustratif)
return [
    'providers' => [
        'openai' => [
            'driver' => 'openai',
            'key'    => env('OPENAI_API_KEY'),
            'url'    => env('OPENAI_BASE_URL', 'https://api.openai.com'),
            'model'  => env('OPENAI_MODEL', 'gpt-4o'),
        ],

        'anthropic' => [
            'driver' => 'anthropic',
            'key'    => env('ANTHROPIC_API_KEY'),
            'url'    => env('ANTHROPIC_BASE_URL', 'https://api.anthropic.com'),
            'model'  => env('ANTHROPIC_MODEL', 'claude-3-5-sonnet'),
        ],

        'gemini' => [
            'driver' => 'gemini',
            'key'    => env('GEMINI_API_KEY'),
            'url'    => env('GEMINI_BASE_URL'),
            'model'  => env('GEMINI_MODEL', 'gemini-1.5-pro'),
        ],
    ],

    'default' => env('AI_DEFAULT_PROVIDER', 'openai'),
];
```

Di sisi `.env`, kita cukup mendefinisikan API key dan model:

```dotenv
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini

ANTHROPIC_API_KEY=...
ANTHROPIC_MODEL=claude-3-haiku

GEMINI_API_KEY=...
GEMINI_MODEL=gemini-1.5-flash
```

Pola konfigurasi semacam ini serupa dengan pendekatan *driver-based* di banyak paket Laravel lain (misalnya mail, cache, queue), sehingga mudah dipahami. Keuntungan utamanya adalah kita bisa mengganti provider default atau menambahkan provider baru tanpa mengubah terlalu banyak kode di tempat lain.

Sebagai tambahan, beberapa provider self-hosted (misalnya Ollama) umumnya dapat diintegrasikan baik melalui driver khusus di Laravel AI SDK maupun lewat paket pihak ketiga seperti `cloudstudio/ollama-laravel` jika kita membutuhkan kendali penuh terhadap cluster lokal. Pada level arsitektur, menempatkan konfigurasi provider di satu tempat membuat manajemen kredensial dan pemantauan penggunaan menjadi jauh lebih terstruktur.


## Membangun Agent dengan Laravel AI SDK {#membangun-agent-dengan-laravel-ai-sdk}

Konsep *agent* adalah jantung dari Laravel AI SDK. Alih-alih memanggil model secara langsung dari controller atau service, kita didorong untuk mengekspresikan "peran" AI dalam bentuk kelas agent yang mandiri. Setiap agent dapat memiliki instruksi, tools, model default, provider default, dan logika khusus lain yang sesuai dengan domain aplikasi kita.

Untuk membuat agent baru, Laravel AI SDK menyediakan artisan command khusus:

```bash
php artisan make:agent SalesCoach
```

Perintah ini akan menghasilkan kelas agent, misalnya di `app/Ai/Agents/SalesCoach.php`. Struktur kelasnya akan tampak seperti ini (disederhanakan):

```php
namespace App\Ai\Agents;

use Laravel\Ai\Agents\Agent;
use Laravel\Ai\Attributes\Model;
use Laravel\Ai\Attributes\Provider;
use Laravel\Ai\Attributes\MaxTokens;

#[Provider('anthropic')]
#[Model('claude-3-5-sonnet')]
#[MaxTokens(2000)]
class SalesCoach extends Agent
{
    public function instructions(): string
    {
        return <<<'PROMPT'
Anda adalah asisten penjualan yang membantu menganalisis transkrip percakapan
antara sales dan calon pelanggan. Berikan masukan yang spesifik, actionable,
dan fokus pada peningkatan closing rate.
PROMPT;
    }
}
```

Atribut seperti `#[Provider]`, `#[Model]`, dan `#[MaxTokens]` digunakan untuk mengatur default behavior agent ini tanpa harus mengulang konfigurasi di setiap pemanggilan. Pendekatan berbasis atribut ini sangat idiomatik dengan ekosistem modern PHP dan menjaga kelas agent tetap deklaratif.

Untuk menggunakan agent ini di dalam aplikasi, kita dapat memanggilnya dari controller:

```php
use App\Ai\Agents\SalesCoach;
use Illuminate\Http\Request;

class SalesController
{
    public function analyze(Request $request)
    {
        $transcript = $request->input('transcript');

        /** @var \Laravel\Ai\Responses\AgentResponse $response */
        $response = (new SalesCoach)->prompt(
            "Analisis percakapan berikut dan berikan 5 rekomendasi konkret:\n\n" . $transcript
        );

        return response()->json([
            'analysis' => (string) $response,
        ]);
    }
}
```

Dalam contoh di atas, pemanggilan `prompt()` adalah cara paling sederhana untuk meminta respons sinkron dari agent. kita juga bisa mengganti provider, model, atau timeout secara ad-hoc dengan argumen tambahan jika diperlukan:

```php
$response = (new SalesCoach)->prompt(
    $transcript,
    provider: 'openai',
    model: 'gpt-4o-mini',
    timeout: 60,
);
```

Dengan pola ini, agent kita menjadi komponen yang mudah dites, dapat di-*mock*, dan dapat berkembang seiring domain bisnis tanpa mencemari controller dengan detail teknis AI.


## Tools, Structured Output, dan Function Calling {#tools-structured-output-dan-function-calling}

Salah satu kemampuan paling penting dari Laravel AI SDK adalah dukungannya terhadap *tools* (function calling) dan *structured output*. Keduanya memungkinkan AI tidak hanya menghasilkan teks bebas, tetapi juga berinteraksi dengan fungsi PHP kita dan mengembalikan data dalam bentuk terstruktur yang dapat diolah secara deterministik.

### Structured Output

Tanpa structured output, kita biasanya menerima string panjang yang kemudian harus di-*parse* secara manual (misalnya dari JSON atau format lain). Laravel AI SDK menyediakan cara untuk mendefinisikan skema output langsung di agent, sehingga model diarahkan untuk mengembalikan data yang sesuai.

Contoh membuat agent dengan output terstruktur:

```bash
php artisan make:agent SalesSummary --structured
```

Kelas yang dihasilkan (disederhanakan):

```php
namespace App\Ai\Agents;

use Laravel\Ai\Agents\StructuredAgent;
use Laravel\Ai\Attributes\Schema;

#[Schema([
    'total_calls'    => 'integer',
    'successful'     => 'integer',
    'conversionRate' => 'float',
    'insights'       => 'array',
])]
class SalesSummary extends StructuredAgent
{
    public function instructions(): string
    {
        return <<<'PROMPT'
Analisis dataset penjualan dan ringkas dalam bentuk:
- total_calls
- successful
- conversionRate (0-1)
- insights: daftar poin penting
PROMPT;
    }
}
```

Kemudian pemanggilannya:

```php
/** @var \Laravel\Ai\Responses\StructuredAgentResponse $response */
$response = (new SalesSummary)->prompt($csvContent);

$data = $response->toArray();

// $data['conversionRate'] sudah float
// $data['insights'] sudah berupa array string
```

Dengan pendekatan ini, kita bisa menjembatani dunia "teks bebas" AI ke struktur data PHP yang konsisten, sehingga logika bisnis di layer berikutnya lebih mudah diimplementasikan dan diuji.

### Tools (Function Calling)

Tools adalah mekanisme bagi model untuk meminta eksekusi fungsi tertentu yang kita sediakan. Laravel AI SDK memudahkan definisi tools di dalam agent, misalnya untuk mengambil data dari database, memanggil API internal, atau melakukan kalkulasi khusus.

Contoh sederhana tools di dalam agent:

```php
use Laravel\Ai\Attributes\Tool;
use Laravel\Ai\Agents\Agent;

class TravelPlanner extends Agent
{
    public function instructions(): string
    {
        return 'Anda adalah asisten travel yang dapat mengecek harga tiket dan rekomendasi hotel.';
    }

    #[Tool('get_flight_price')]
    public function getFlightPrice(string $from, string $to, string $date): array
    {
        // Di sini Anda bisa akses database atau API internal
        return [
            'from'  => $from,
            'to'    => $to,
            'date'  => $date,
            'price' => 1500000,
            'currency' => 'IDR',
        ];
    }

    #[Tool('get_hotel_recommendations')]
    public function getHotelRecommendations(string $city): array
    {
        // Logic rekomendasi hotel
        return [
            ['name' => 'Hotel A', 'price' => 700000],
            ['name' => 'Hotel B', 'price' => 550000],
        ];
    }
}
```

Ketika agent ini dipanggil, model dapat memutuskan untuk menggunakan salah satu tools untuk mendapatkan data real-time yang dibutuhkan, lalu menggabungkannya dalam respons akhir. Laravel AI SDK menangani orkestrasi panggilan tools tersebut dan mengembalikan hasil yang sudah disintesis.

Pendekatan tools dan structured output ini selaras dengan tren *agentic AI*, di mana model tidak hanya menjawab, tetapi juga dapat mengambil tindakan terkontrol di dalam sistem kita.

## Streaming, Antrian, dan Skalabilitas {#streaming-antrian-dan-skalabilitas}

Saat membangun aplikasi AI untuk produksi, aspek performa dan pengalaman pengguna menjadi sangat penting. Laravel AI SDK menyediakan dukungan bawaan untuk streaming respons dan integrasi dengan queue Laravel untuk pemrosesan asynchronous dan skala besar.

### Streaming Respons

Streaming sangat berguna untuk UI chat di mana pengguna ingin melihat jawaban muncul secara bertahap, mirip pengalaman ChatGPT atau Claude. Laravel AI SDK menyediakan API `stream()` yang mengembalikan objek `StreamedAgentResponse` yang dapat diiterasi atau dipetakan ke SSE/WebSocket.

Contoh sederhana penggunaan streaming di route:

```php
use App\Ai\Agents\SalesCoach;
use Laravel\Ai\Responses\StreamedAgentResponse;

Route::get('/coach/stream', function () {
    return (new SalesCoach)
        ->stream('Analisis transkrip berikut...')
        ->then(function (StreamedAgentResponse $response) {
            // $response->text (hasil akhir)
            // $response->events (token/segment)
            // $response->usage (token usage)
        });
});
```

Di sisi frontend, kita bisa menghubungkan stream ini lewat SSE atau WebSocket untuk menampilkan teks secara bertahap kepada pengguna, memberikan feedback instan meski proses komputasi di belakang cukup berat.

### Queue dan Pemrosesan Asynchronous

Untuk tugas yang lebih berat atau jangka panjang (misalnya analisis dokumen besar, batch generasi konten), pemrosesan sinkron akan memperburuk UX dan membebani server. Laravel AI SDK terintegrasi dengan queue Laravel sehingga kita bisa mengantrikan prompt sebagai job yang akan diproses di background.

Contoh pola `queue()`:

```php
use App\Ai\Agents\SalesCoach;
use Laravel\Ai\Responses\AgentResponse;
use Throwable;

Route::post('/coach/async', function (Request $request) {
    (new SalesCoach)
        ->queue($request->input('transcript'))
        ->then(function (AgentResponse $response) {
            // Simpan hasil ke database atau kirim notifikasi ke user
        })
        ->catch(function (Throwable $e) {
            // Logging dan error handling
        });

    return back()->with('status', 'Analisis sedang diproses di background.');
});
```

Dengan pendekatan ini, kita memanfaatkan penuh infrastruktur queue Laravel (Redis, database, SQS, dsb) untuk menskalakan workload AI. Hal ini penting ketika aplikasi kita berkembang dan mulai memproses ratusan atau ribuan permintaan AI per jam.


## Bekerja dengan File, Dokumen, dan Embeddings {#bekerja-dengan-file-dokumen-dan-embeddings}

Banyak use case AI modern melibatkan dokumen: PDF, markdown, transkrip audio, dan sebagainya. Laravel AI SDK menyediakan API untuk meng-attach file ke prompt dan memanfaatkan kemampuan *document intelligence* dari provider seperti OpenAI dan Anthropic.

### Attach Dokumen ke Agent

Contoh agent yang menganalisis dokumen:

```php
use App\Ai\Agents\SalesCoach;
use Laravel\Ai\Files;
use Illuminate\Http\Request;

Route::post('/coach/upload', function (Request $request) {
    $file = $request->file('transcript');

    $response = (new SalesCoach)->prompt(
        'Analisis transkrip yang terlampir dan berikan 10 poin perbaikan.',
        attachments: [
            Files\Document::fromUploadedFile($file),
        ],
    );

    return [
        'analysis' => (string) $response,
    ];
});
```

Laravel AI SDK menyediakan helper seperti `Files\Document::fromStorage()`, `Files\Document::fromPath()`, dan integrasi dengan uploaded file dari request sehingga kita tidak perlu menangani encoding dan format file secara manual.

### Embeddings untuk Pencarian Semantik

Selain analisis dokumen langsung, use case penting lainnya adalah embeddings: merepresentasikan teks sebagai vektor numerik sehingga bisa digunakan untuk pencarian semantik, rekomendasi, dan retrieval-augmented generation (RAG). Laravel AI SDK menyediakan API untuk membuat embeddings menggunakan provider yang mendukung fitur tersebut.

Secara konseptual, flow-nya seperti ini:

1. Kita mengekstrak teks dari dokumen (misalnya setiap paragraf atau chunk).  
2. Kita mengirim teks tersebut ke endpoint embeddings provider via Laravel AI SDK.  
3. Kita menyimpan vektornya di database atau vector store (PostgreSQL + pgvector, Redis, layanan khusus, dsb).  
4. Ketika user bertanya, kita embed pertanyaan user, cari tetangga terdekat (nearest neighbors), lalu berikan konteks tersebut ke agent.

Meski detail API embeddings di Laravel AI SDK dapat berubah seiring rilis, pola umum ini sudah mapan dan digunakan di berbagai paket lain seperti Prism dan AI Orchestrator. Laravel AI SDK mempermudah bagian integrasi dengan provider, sementara desain penyimpanan dan retrieval bisa kita sesuaikan dengan kebutuhan arsitektur.


## Integrasi dengan Ekosistem Laravel {#integrasi-dengan-ekosistem-laravel}

Kekuatan terbesar Laravel AI SDK bukan hanya fiturnya, tetapi juga integrasinya yang mendalam dengan ekosistem Laravel secara keseluruhan. Mulai dari controller, job, event listener, hingga fitur seperti Laravel Boost dan AI Assisted Development.

### Controller dan Route

Integrasi paling dasar adalah memanggil agent dari controller atau closure route. Hal ini sudah dicontohkan sebelumnya, dan cara kerjanya sama seperti service lain di Laravel:

```php
use App\Ai\Agents\SalesCoach;
use Illuminate\Support\Facades\Route;

Route::post('/coach', function (Request $request) {
    $response = (new SalesCoach)->prompt($request->input('transcript'));

    return [
        'analysis' => (string) $response,
    ];
});
```

Kita juga bisa meng-inject agent via container jika ingin mengikuti pola dependency injection yang lebih eksplisit.

### Jobs, Events, dan Scheduler

Karena AI sering kali digunakan untuk tugas komputasi berat atau asynchronous, menempatkan pemanggilan agent di dalam job adalah pola yang sangat umum. Misalnya:

```php
use App\Ai\Agents\DocumentAnalyzer;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;

class AnalyzeDocumentJob implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public int $documentId,
    ) {}

    public function handle(DocumentAnalyzer $analyzer): void
    {
        $document = Document::findOrFail($this->documentId);

        $response = $analyzer->prompt($document->content);

        $document->update([
            'analysis' => (string) $response,
        ]);
    }
}
```

Job tersebut kemudian bisa dipicu oleh event (misalnya `DocumentUploaded`) atau scheduler (misalnya analisis berkala). Dengan cara ini, integrasi AI menjadi bagian natural dari pipeline bisnis kita, bukan sesuatu yang ditempel di pinggir.

### AI Assisted Development dan Laravel Boost

Laravel Boost adalah MCP server dan serangkaian tools yang dirancang untuk mempercepat pengembangan dengan bantuan AI, memberikan konteks aplikasi (schema database, route, artisan command, dsb) ke AI assistant di editor kita. Meski Boost lebih fokus ke "AI untuk developer" dan Laravel AI SDK fokus ke "AI di dalam aplikasi kita", keduanya saling melengkapi.

Dengan kombinasi Boost dan AI SDK, workflow-nya bisa seperti ini:

- Gunakan Boost + AI assistant di editor untuk menghasilkan skeleton agent, schema structured output, dan contoh tools.  
- Refinement manual di kode, pengujian, dan integrasi ke route/job.  
- Deploy agent ke production dengan confidence yang lebih tinggi karena banyak boilerplate sudah dihasilkan dengan konteks aplikasi.



## Use Case dan Contoh Implementasi {#use-case-dan-contoh-implementasi}

Setelah memahami konsep dan API, bagian ini akan membahas beberapa use case praktis untuk memberi gambaran bagaimana Laravel AI SDK bisa diterapkan di proyek nyata.

### 1. Sales Coach Berbasis Transkrip

Use case ini sempat disinggung di contoh sebelumnya dan juga dijadikan ilustrasi di dokumentasi resmi Laravel AI SDK. Idem-potensi: agent membantu menganalisis transkrip call center atau meeting sales dan memberikan insight actionable.

Pola implementasi:

- Endpoint upload transkrip (teks atau file audio yang sudah di-transcribe).  
- Job background yang memanggil `SalesCoach` agent dengan transkrip tersebut.  
- Menyimpan insight di tabel `sales_call_analysis` dan menampilkannya di dashboard.

Keuntungan utama adalah scaling: kita hanya perlu memastikan queue worker memadai, dan AI SDK mengurus detail panggilan ke model.

### 2. Dokument Analyzer untuk Tim Legal atau Compliance

Skenario lain adalah analisis kontrak dan kebijakan untuk tim legal. Agent `ContractAnalyzer` dapat:

- Mengambil teks kontrak (upload PDF → ekstraksi → teks).  
- Menggunakan structured output untuk mengembalikan: pihak terlibat, durasi kontrak, klausul penting, risiko, dsb.  
- Menggunakan tools untuk mengecek database internal (misalnya daftar blacklist vendor atau limit risiko).

Dengan Laravel AI SDK:

- Structured output menjaga hasil tetap konsisten antar dokumen.  
- Tools mengizinkan AI untuk terhubung ke data internal yang tidak ter-embed di model.  
- Queue memastikan analisis kontrak besar tidak membebani permintaan HTTP user secara langsung.

### 3. Chatbot Support Multi-Provider

Kita dapat membangun chatbot customer support yang fleksibel dengan memanfaatkan beberapa provider AI:

- OpenAI untuk jawaban generik dan conversation flow.  
- Anthropic untuk tugas reasoning yang lebih kompleks.  
- Gemini untuk integrasi kuat dengan konteks dari Google Workspace (jika diperlukan di masa depan).

Laravel AI SDK memudahkan penggantian provider secara dinamis:

```php
$response = (new SupportBot)->prompt(
    $message,
    provider: $this->decideProvider($message)
);
```

Fungsi `decideProvider()` dapat menggunakan heuristik tertentu (panjang pesan, jenis pertanyaan, jam sibuk) atau bahkan model lain untuk memilih provider optimal. Pola multi-provider semacam ini sudah umum di paket seperti AI Orchestrator dan Prism, dan sekarang bisa diimplementasikan dengan API resmi Laravel.

### 4. AI-Assisted Content Generation di CMS

Jika kita mengembangkan CMS berbasis Laravel, Laravel AI SDK bisa digunakan sebagai "writer assistant" untuk:

- Menyusun draft artikel dari poin-poin yang diberikan editor.  
- Menghasilkan variasi judul, meta description, dan excerpt.  
- Mengoreksi grammar atau menyesuaikan tone (formal, kasual, teknis).

Di level implementasi:

- Kita bisa membuat agent `ContentWriter` dengan instruksi spesifik brand.  
- Menggunakan structured output untuk memisahkan `title`, `meta_description`, `excerpt`, dan `body`.  
- Menyimpan hasil sebagai draft di database sambil tetap memberikan kendali penuh bagi editor untuk review.

### 5. AI untuk Internal Tools dan Dashboard

Banyak organisasi menggunakan Laravel untuk aplikasi internal: dashboard monitoring, back-office, dan internal tooling. Dengan Laravel AI SDK, kita dapat menambahkan fitur seperti:

- Natural language query ke dashboard ("tampilkan penjualan bulan lalu per negara").  
- Ringkasan otomatis dari laporan harian atau weekly.  
- Rekomendasi tindakan berdasarkan metrik tertentu (misalnya alert yang sudah dianalisis AI).

Di sisi teknis, kita bisa menggabungkan:

- Agent untuk interpretasi natural language menjadi query atau action.  
- Tools untuk eksekusi query database atau API internal.  
- Structured output untuk memastikan hasil dalam format yang bisa langsung dirender di UI.


## Tantangan, Keamanan, dan Limitasi {#tantangan-keamanan-dan-limitasi}

Sehebat apa pun sebuah tooling, selalu ada tantangan dan batasan yang perlu diperhatikan. Laravel AI SDK mengurangi banyak friksi integrasi, tetapi tidak secara otomatis menyelesaikan semua isu terkait AI di production.

### Keamanan Data dan Privasi

Ketika mengirimkan data ke provider AI eksternal, kita harus memperhatikan:

- **Jenis data**: Apakah mengandung PII, data sensitif, atau rahasia bisnis?  
- **Kebijakan provider**: Bagaimana penyimpanan, penggunaan untuk training, dan retensi data?  
- **Regulasi**: Apakah ada regulasi lokal (misalnya PDPA, GDPR) yang memengaruhi cara data boleh diproses?

Secara arsitektural, kita bisa mengurangi risiko dengan:

- Meng-anonimkan data sebelum dikirim ke provider.  
- Menggunakan provider lokal atau self-hosted seperti Ollama untuk data sangat sensitif.  
- Membatasi tools yang tersedia bagi agent sehingga AI tidak bisa mengakses fungsi atau data yang tidak seharusnya.

### Biaya dan Observabilitas

Panggilan ke API AI berbayar berdasarkan token atau durasi. Tanpa pemantauan yang baik, biaya bisa membengkak secara tak terduga. Laravel AI SDK dan paket ekosistem lain (misalnya AI Orchestrator) mulai mengadopsi fitur seperti tracking penggunaan token per user atau per provider.

Beberapa praktik yang bisa diterapkan:

- Menyimpan metrik penggunaan (token, waktu respons) di tabel khusus.  
- Menerapkan limit per user atau per organisasi (quota).  
- Menggunakan model yang lebih murah (misalnya gpt-4o-mini atau model kecil lainnya) untuk tugas ringan, dan model besar hanya untuk use case tertentu.

### Kualitas Respons dan Hallucination

AI model bisa *berhalusinasi* — memberikan jawaban yang terdengar meyakinkan tetapi salah. Laravel AI SDK tidak bisa menghilangkan risiko ini, tapi tooling-nya mendukung pola mitigasi seperti:

- Structured output dan validation (misalnya memvalidasi skema di PHP).  
- Membatasi domain tugas agent sejelas mungkin di `instructions()`.  
- Menggabungkan AI dengan aturan deterministic (misalnya validasi business rule di PHP setelah menerima output).

### Evolusi API Provider

Provider AI sering memperbarui API, menambah/menghapus model, atau mengubah kebijakan. Laravel AI SDK sebagai lapisan abstraksi membantu menyerap banyak perubahan ini, tetapi sebagai pengembang kita tetap perlu:

- Memantau pengumuman resmi provider.  
- Menguji agent setelah mengganti model atau versi API.  
- Menjaga konfigurasi provider tetap up to date (misalnya URL base, nama model, parameter baru).


## Penutup {#penutup}

Laravel AI SDK membawa paradigma baru dalam pengembangan aplikasi Laravel yang terintegrasi dengan AI. Alih-alih sekadar menjadi "klien HTTP yang membungkus API LLM", SDK ini memperkenalkan model mental yang lebih tinggi: agent, tools, structured output, streaming, dan integrasi mendalam dengan ekosistem Laravel. Dengan pendekatan ini, pengembang dapat membangun fitur AI yang lebih terstruktur, dapat dipelihara, dan sejalan dengan prinsip-prinsip rekayasa perangkat lunak yang baik.

Dalam artikel ini telah dibahas konsep dasar Laravel AI SDK, arsitektur dan komponennya, cara instalasi dan konfigurasi, hingga contoh implementasi praktis seperti sales coach, document analyzer, chatbot support, content generator, dan internal tools. Selain itu, dibahas pula tantangan di dunia nyata: keamanan data, biaya, kualitas respons, serta perubahan cepat di landscape AI. Semua itu menunjukkan bahwa Laravel AI SDK bukan solusi instan, tetapi fondasi kuat yang tetap membutuhkan desain arsitektur dan praktik terbaik yang matang.

**Key takeaway**:

- Gunakan *agent* sebagai unit utama perilaku AI, bukan sekadar panggilan API ad-hoc.  
- Manfaatkan *structured output* dan *tools* untuk menjembatani dunia AI yang probabilistik dengan logika bisnis yang deterministik.  
- Integrasikan Laravel AI SDK dengan queue, event, dan komponen lain untuk membuat solusi AI yang benar-benar production-ready.  
- Pertimbangkan aspek keamanan, privasi, dan biaya sejak awal desain arsitektur.  
- Anggap Laravel AI SDK sebagai bagian inti dari ekosistem Laravel yang terus berkembang, dan bangun aplikasi AI-native dengan cara yang tetap Laravel-esque: ekspresif, elegan, dan terukur.

---

## Referensi {#referensi}

- Dokumentasi resmi Laravel AI SDK (Laravel 12.x):  
  https://laravel.com/docs/12.x/ai-sdk

- Halaman resmi Laravel AI SDK (marketing & overview):  
  https://laravel.com/ai

- Laravel Boost & AI Assisted Development:  
  https://laravel.com/ai/boost  
  https://laravel.com/docs/12.x/ai

- Paket integrasi Ollama untuk Laravel (self-hosted models):  
  https://github.com/cloudstudio/ollama-laravel

- Laravel AI Toolkit (pihak ketiga, integrasi OpenAI & AWS Claude):  
  https://github.com/endritvs/laravel-ai-toolkit

- Laravel AI Orchestrator (driver-based, multi-provider):  
  https://github.com/sumeetghimire/Laravel-AI-Orchestrator

- Prism: paket AI untuk Laravel dengan driver Anthropic, OpenAI, Ollama:  
  https://laravel-news.com/prism-ai-laravel