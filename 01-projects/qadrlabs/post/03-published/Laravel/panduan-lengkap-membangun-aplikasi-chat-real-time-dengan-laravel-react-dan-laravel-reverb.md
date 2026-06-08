---
title: "Panduan Lengkap: Membangun Aplikasi Chat Real-Time dengan Laravel, React, dan Laravel Reverb"
slug: "panduan-lengkap-membangun-aplikasi-chat-real-time-dengan-laravel-react-dan-laravel-reverb"
category: "Laravel"
date: "2024-11-10"
status: "published"
---

Beberapa waktu yang lalu terdapat permintaan untuk development aplikasi web menggunakan framework laravel dan salah satu fitur yang diperlukan dalam aplikasi tersebut adalah fitur chat secara realtime. Untuk mengembangkan fitur realtime, salah satu solusinya adalah memanfaatkan WebSocket. Namun untuk menggunakan WebSocket itu perlu pengaturan yang kompleks dan juga learning curve yang challenging. Kabar baiknya, di dalam ekosistem laravel terdapat package yang menangani masalah tersebut, yaitu **Laravel Reverb**.

Laravel Reverb adalah server WebSocket resmi yang dirancang khusus untuk aplikasi Laravel, menawarkan berbagai keunggulan yang membuatnya menjadi pilihan utama bagi developer yang membutuhkan komunikasi real-time antara klien dan server. Berikut beberapa alasan utama untuk menggunakan Laravel Reverb:

1. **Integrasi Mulus dengan Laravel:**
   Sebagai produk resmi dari tim Laravel, Reverb terintegrasi secara langsung dengan ekosistem Laravel. Hal ini memudahkan pengembang dalam mengimplementasikan fitur broadcasting tanpa perlu konfigurasi yang rumit. 

2. **Performa Tinggi:**
   Reverb dirancang untuk menangani ribuan koneksi secara simultan dengan efisiensi tinggi, mengurangi latensi dan meningkatkan responsivitas aplikasi. Ini sangat penting untuk aplikasi yang memerlukan komunikasi real-time, seperti aplikasi obrolan atau dashboard live. 

3. **Skalabilitas:**
   Dengan dukungan untuk skala horizontal melalui Redis, Reverb memungkinkan pengelolaan koneksi dan channel di berbagai server, memastikan aplikasi dapat menangani peningkatan beban dengan lancar. 

4. **Kompatibilitas dengan Laravel Echo:**
   Reverb menggunakan protokol Pusher untuk WebSocket, menjadikannya kompatibel dengan Laravel broadcasting dan Laravel Echo. Ini memudahkan pengembang dalam mengimplementasikan fitur real-time tanpa perlu mempelajari alat baru. 

5. **Penghematan Biaya:**
   Dengan Reverb, pengembang dapat menghindari biaya berlangganan layanan pihak ketiga untuk fitur broadcasting, karena Reverb adalah solusi open-source yang dapat di-hosting sendiri. 

6. **Kemudahan Penggunaan:**
   Reverb dapat diinstal dan dijalankan dengan perintah Artisan sederhana, memudahkan pengembang dalam memulai dan mengelola server WebSocket tanpa perlu konfigurasi yang kompleks. 

Dengan berbagai keunggulan tersebut, Laravel Reverb menjadi solusi ideal bagi kita sebagai developer yang ingin menambahkan fitur chat real-time ke dalam aplikasi Laravel kita dengan efisien dan efektif. 

Sebelum mengimplementasikan ke dalam real project, saya coba menggunakan laravel reverb dengan studi kasus yang sama, yaitu develop aplikasi chat realtime. Dan hasil explore laravel reverb ini akan saya bahas pada tutorial laravel ini.

## Overview {#overview}
Dalam tutorial ini, kita akan membangun aplikasi chat real-time yang sepenuhnya berfungsi menggunakan **Laravel**, **React**, dan **Laravel Reverb** sebagai solusi broadcasting. Studi kasus yang kita bahas adalah bagaimana membuat aplikasi chat sederhana di mana pengguna bisa mengirim dan menerima pesan secara langsung tanpa perlu melakukan refresh halaman. 

Di sini kita akan belajar:
1. **Menggunakan Laravel dan React** untuk membangun aplikasi full-stack.
2. **Menerapkan Laravel Reverb** untuk broadcast pesan secara real-time.
3. **Mengelola Queue Job** di Laravel untuk memproses pengiriman pesan di background.
4. **Membuat antarmuka interaktif** menggunakan React dengan integrasi WebSocket.

Pada akhir tutorial ini, kita akan memiliki aplikasi chat yang siap digunakan dan dapat dikembangkan lebih lanjut sesuai kebutuhan kita.

<video width="600" controls>
  <source src="https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-reverb-chat-app/demo-aplikasi-chat-tutorial%20laravel%20reverb.webm" type="video/webm">
  Demo Aplikasi Chat
</video>

---

## Persiapan {#persiapan}

Sebelum memulai, pastikan kita telah menginstal beberapa tools berikut di sistem kita:
- **PHP 8.2 atau lebih baru**
- **Composer**
- **Node.js dan npm**
- **MySQL atau MariaDB**
- **Laravel CLI**

---

## Step 1: Membuat Proyek Laravel {#step-1-create-laravel-project}
Langkah pertama adalah membuat proyek Laravel baru. Buka terminal dan jalankan perintah berikut:

```bash
composer create-project --prefer-dist laravel/laravel chat-app
```

Setelah proyek berhasil dibuat, pindah ke direktori `chat-app`:

```bash
cd chat-app
```

Jalankan server development Laravel untuk memastikan semuanya berjalan dengan baik:

```bash
php artisan serve
```

---

## Step 2: Atur Konfigurasi Database {#step-2-atur-konfigurasi-database}
Sekarang, kita perlu menghubungkan aplikasi Laravel dengan database. Buka file `.env` dan sesuaikan konfigurasi berikut:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_chat_app
DB_USERNAME=root
DB_PASSWORD=password
```

Save kembali file `.env`.

---

## Step 3: Instalasi Laravel UI {#step-3-install-laravel-ui}

Laravel UI menyediakan interface frontend yang bisa kita gunakan untuk otentikasi pengguna. Jalankan perintah berikut untuk menginstal Laravel UI:

```bash
composer require laravel/ui
```

Setelah itu, gunakan scaffolding React dengan otentikasi:

```bash
php artisan ui react --auth
```

Apabila tampil prompt berikut ini:
```
  The [Controller.php] file already exists. Do you want to replace it? (yes/no) [yes]
❯ yes

```
Pilih `yes`, lalu tekan `enter` untuk melanjutkan.

Selanjutnya, jalankan perintah berikut untuk menginstal dependensi frontend:

```bash
npm install
```

Kita tunggu sampai proses install selesai.

---

## Step 4: Membuat Model dan Migrasi untuk Pesan {#step-4-create-message-model-and-migration}

Kita akan membuat model `Message` dan file migrasi untuk menyimpan pesan di database:

```bash
php artisan make:model Message -m
```

Output:
```

   INFO  Model [app/Models/Message.php] created successfully.  

   INFO  Migration [database/migrations/2024_11_09_031348_create_messages_table.php] created successfully.  

```

Buka file `database/migrations/20xx_xx_xx_xxxxxx_create_messages_table.php` dan tambahkan kode berikut:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained();
            $table->text('text')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('messages');
    }
};
```

Selanjutnya kita buka file `app/Models/Message.php`, lalu kita sesuaikan seperti baris kode berikut ini.

```
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Message extends Model
{
    protected $fillable = [
        'user_id',
        'text',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function getTimeAttribute(): string
    {
        return date("d M Y, H:i:s", strtotime($this->attributes['created_at']));
    }

    public function getSenderAttribute(): string
    {
        return $this->user ? $this->user->name : '';
    }
}

```

Selanjutnya kita run `migrate` command untuk memulai proses migrasi database:

```bash
php artisan migrate
```

Kalau kita belum buat database `db_chat_app`, pada output terminal akan tampil prompt untuk membuat database baru

```
$ php artisan migrate

   WARN  The database 'db_chat_app' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘


```

Pilih `yes`, lalu tekan `enter` untuk melanjutkan.

---

## Step 5: Membuat Event `GotMessage` {#step-5-create-gotmessage-event}

Event digunakan untuk menangani broadcast pesan ketika ada pesan baru yang dikirim. Jalankan perintah berikut untuk membuat event:

```bash
php artisan make:event GotMessage
```

Output:
```
$ php artisan make:event GotMessage

   INFO  Event [app/Events/GotMessage.php] created successfully. 
```

Kemudian, buka file `app/Events/GotMessage.php` dan tambahkan kode berikut:

```php
<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class GotMessage
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    /**
     * Create a new event instance.
     */
    public function __construct(public array $message)
    {
        //
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('message_channel'),
        ];
    }
}

```

Save kembali file `app/Events/GotMessage.php`.

---

## Step 6: Membuat Queue Job `SendMessage` {#step-6-create-sendmessage-queue-job}

Kita akan membuat Queue Job untuk menangani pengiriman pesan di background:

```bash
php artisan make:job SendMessage
```

Output:
```
$ php artisan make:job SendMessage

   INFO  Job [app/Jobs/SendMessage.php] created successfully. 
```

Selanjutnya kita buka file `app/Jobs/SendMessage.php` dan tulis kode berikut:

```php
<?php

namespace App\Jobs;

use App\Events\GotMessage;
use App\Models\Message;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendMessage implements ShouldQueue
{
    use Queueable, Dispatchable, InteractsWithQueue, SerializesModels;

    /**
     * Create a new job instance.
     */
    public function __construct(public Message $message)
    {
        //
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        GotMessage::dispatch([
            'id' => $this->message->id,
            'user_id' => $this->message->user_id,
            'text' => $this->message->text,
            'time' => $this->message->time,
        ]);
    }
}

```

Apabila sudah selesai menuliskan code, save kembali  file `app/Jobs/SendMessage.php`.

---

## Step 7: Membuat `MessageController` {#step-7-create-messagecontroller}

Sekarang, kita akan membuat `MessageController` untuk menangani request HTTP yang terkait dengan pesan. Run command berikut ini untuk membuat `MessageController`.

```bash
php artisan make:controller MessageController
```

Output:
```
   INFO  Controller [app/Http/Controllers/MessageController.php] created successfully. 
```

Kemudian, buka file `app/Http/Controllers/MessageController.php` dan tambahkan kode berikut:

```php
<?php

namespace App\Http\Controllers;

use App\Jobs\SendMessage;
use App\Models\Message;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class MessageController extends Controller
{
    public function index(): JsonResponse
    {
        $messages = Message::get()->append(['time', 'sender']);
        return response()->json($messages);
    }

    public function store(Request $request): JsonResponse
    {
        $message = Message::create([
            'user_id' => Auth::user()->id,
            'text' => $request->get('text'),
        ]);
        
        SendMessage::dispatch($message);
        
        return response()->json([
            'success' => true,
            'message' => 'Message created and job dispatched'
        ]);
    }
}

```

Jangan lupa save kembali `app/Http/Controllers/MessageController.php` .

Setelah itu kita sesuaikan halaman home dengan passing data user ke view. Buka `app/Http/Controllers/HomeController.php`, lalu sesuaikan isi method `index()`.

```
    public function index()
    {
        $user = auth()->user();
        return view('home', compact('user'));
    }
```
Save kembali `app/Http/Controllers/HomeController.php`.

---

## Step 8: Mendaftarkan Route {#step-8-register-route}
Setelah membuat controller, kita perlu mendaftarkan route untuk mengakses endpoint terkait pesan. Buka file `routes/web.php` dan tambahkan baris berikut:

```php
Route::group(['middleware' => 'auth'], function () {
    Route::get('messages', [App\Http\Controllers\MessageController::class, 'index'])->name('messages.index');
    Route::post('message/send', [App\Http\Controllers\MessageController::class, 'store'])->name('messages.store');
});
```

Dengan menggunakan middleware `auth`, kita memastikan bahwa hanya pengguna yang sudah login yang dapat mengirim dan menerima pesan.

---

## Step 9: Instalasi Laravel Reverb {#step-9-install-laravel-reverb}

Sekarang, kita akan menginstal **Laravel Reverb**, sebuah package yang memungkinkan broadcast real-time menggunakan WebSocket tanpa memerlukan Pusher atau Ably.

Untuk memulainya, jalankan:

```bash
php artisan install:broadcasting
```

Output:

```
INFO  Published 'broadcasting' configuration file.
INFO  Published 'channels' route file.

 ┌ Would you like to install Laravel Reverb? ───────────────────┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘
```

Pilih `yes`, kemudian tekan `enter`. Setelah itu, Anda akan diminta untuk menginstal dependensi Node yang dibutuhkan:

```
┌ Would you like to install and build the Node dependencies required for br… ┐
│ ● Yes / ○ No                                                              │
└────────────────────────────────────────────────────────────────────────────
```

Pilih `yes` lagi dan tekan `enter` untuk melanjutkan.

Setelah selesai, kita bisa lihat terdapat konfigurasi baru untuk laravel reverb yang ditambahkan ke file `.env`:

```env
BROADCAST_CONNECTION=reverb

REVERB_APP_ID=816280
REVERB_APP_KEY=s4wrxlykchxmqolubxgt
REVERB_APP_SECRET=dizgzi9iv2e0r0wqm7mr
REVERB_HOST="localhost"
REVERB_PORT=8080
REVERB_SCHEME=http

VITE_REVERB_APP_KEY="${REVERB_APP_KEY}"
VITE_REVERB_HOST="${REVERB_HOST}"
VITE_REVERB_PORT="${REVERB_PORT}"
VITE_REVERB_SCHEME="${REVERB_SCHEME}"
```

**Catatan:**
- `REVERB_APP_ID`, `REVERB_APP_KEY`, dan `REVERB_APP_SECRET` dihasilkan otomatis oleh package Laravel Reverb. Value pada konfigurasi di atas adalah hasil generate ketika install laravel reverb, jadi value yang ditampilkan boleh jadi random.
- Terdapat file konfigurasi baru, yaitu `config/reverb.php` dan `config/broadcasting.php`.

---

## Step 10: Membuat Channel untuk Broadcast {#step-10-create-new-channel}

Untuk memungkinkan broadcast pesan ke semua pengguna yang terhubung, kita perlu membuat channel baru. Buka file `routes/channels.php` dan tambahkan baris berikut:

```php
Broadcast::channel('message_channel', function ($user) {
    return true;
});
```

Channel `message_channel` akan menjadi jalur komunikasi antara server dan frontend. Setiap kali event `GotMessage` di-trigger, pesan akan disiarkan ke semua klien yang diset `listen` ke channel ini.

---

## Step 11: Modifikasi File View {#step-11-modifikasi-file-view}

Agar pengguna dapat mengirim dan menerima pesan, kita perlu menyesuaikan tampilan (views). Buka file `resources/views/home.blade.php` dan tambahkan kode berikut:

```blade
@extends('layouts.app')

@section('content')
    <div class="container">
        <div id="main" data-user="{{ json_encode($user) }}"></div>
    </div>
@endsection
```



Kemudian, buka file `resources/views/welcome.blade.php`. Temukan tautan menuju dashboard dan ubah menjadi:

```blade
<a href="{{ url('/home') }}"
   class="rounded-md px-3 py-2 text-black ring-1 ring-transparent transition hover:text-black/70 focus:outline-none focus-visible:ring-[#FF2D20] dark:text-white dark:hover:text-white/80 dark:focus-visible:ring-white">
    Home
</a>
```

**Fix Error Tailwind**
Karena kita menggunakan Tailwind CSS, pastikan file `vite.config.js` diatur dengan benar untuk membangun semua asset. Ubah `vite.config.js` seperti berikut:

```javascript
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import react from '@vitejs/plugin-react';

export default defineConfig({
    plugins: [
        laravel({
            input: [
                'resources/sass/app.scss',
                'resources/js/app.js',
                'resources/css/app.css', // tambahkan ini
            ],
            refresh: true,
        }),
        react(),
    ],
});
```

---

## Step 12: Membuat Komponen React {#step-12-create-react-component}

Selanjutnya, kita akan membuat komponen React untuk menangani input pesan dan menampilkan pesan yang diterima.

### 1. Membuat Komponen `MessageInput.jsx`
Kita buat komponen pertama untuk input pesan. Buat file `resources/js/components/MessageInput.jsx`, lalu kita ketik baris kode berikut ini.

```javascript
import React, { useState } from "react";

const MessageInput = ({ rootUrl }) => {
    const [message, setMessage] = useState("");

    const messageRequest = async (text) => {
        try {
            await axios.post(`${rootUrl}/message/send`, { text });
        } catch (err) {
            console.error(err.message);
        }
    };

    const sendMessage = (e) => {
        e.preventDefault();
        if (message.trim() === "") {
            alert("Please enter a message!");
            return;
        }
        messageRequest(message);
        setMessage("");
    };

    return (
        <div className="input-group">
            <input 
                onChange={(e) => setMessage(e.target.value)}
                type="text"
                className="form-control"
                placeholder="Message..."
                value={message}
            />
            <div className="input-group-append">
                <button onClick={sendMessage} className="btn btn-primary">Send</button>
            </div>
        </div>
    );
};

export default MessageInput;
```

Penjelasan:
- Pada komponen di atas, kita gunakan `useState` untuk menyimpan pesan.
- Fungsi `sendMessage()` digunakan untuk mengirim pesan ke server melalui endpoint `message/send` dengan menggunakan `axios.post()`.
- Setelah pesan terkirim, input dikosongkan (`setMessage("")`).


### 2. Membuat Komponen `Message.jsx`

Selanjutnya kita buat komponen untuk menampilkan pesan. Buat file `resources/js/components/Message.jsx`, lalu ketik baris kode berikut ini.

```javascript
import React from "react";

const Message = ({ userId, message }) => {
    const isCurrentUser = userId === message.user_id;

    return (
        <div className={`row ${isCurrentUser ? "justify-content-end" : ""}`}>
            <div className="col-md-6">
                <small className="text-muted">
                    {isCurrentUser ? message.time : message.sender}
                </small>
                <div className={isCurrentUser ? "alert alert-primary" : "alert alert-secondary"}>
                    {message.text}
                </div>
            </div>
        </div>
    );
};

export default Message;
```

Penjelasan:
- Pada komponen di atas, kita periksa apakah pesan dikirim oleh pengguna saat ini (`isCurrentUser`).
- Pada komponen di atas, kita tampilkan pesan dan informasi tambahan, seperti waktu atau pengirim, dengan tampilan yang berbeda untuk pengguna saat ini dan pengguna lain.

### 3. Membuat Komponen `ChatBox.jsx`
Komponen ini adalah komponen utama untuk chatting. Sekarang kita buat file `resources/js/components/ChatBox.jsx`, pada file ini kita gunakan komponen `Message` dan `MessageInput` yang sudah kita buat sebelumnya.

```javascript
import React, { useEffect, useRef, useState } from "react";
import Message from "./Message";
import MessageInput from "./MessageInput";

const ChatBox = ({ rootUrl }) => {
    const userData = document.getElementById('main').getAttribute('data-user');
    const user = JSON.parse(userData);
    const webSocketChannel = `message_channel`;

    const [messages, setMessages] = useState([]);
    const scroll = useRef();

    const scrollToBottom = () => {
        scroll.current.scrollIntoView({ behavior: "smooth" });
    };

    const connectWebSocket = () => {
        window.Echo.private(webSocketChannel)
            .listen('GotMessage', async () => {
                await getMessages();
            });
    };

    const getMessages = async () => {
        try {
            const response = await axios.get(`${rootUrl}/messages`);
            setMessages(response.data);
            scrollToBottom();
        } catch (err) {
            console.error(err.message);
        }
    };

    useEffect(() => {
        getMessages();
        connectWebSocket();

        return () => {
            window.Echo.leave(webSocketChannel);
        };
    }, []);

    return (
        <div className="card">
            <div className="card-header">Chat Box</div>
            <div className="card-body" style={{ height: "500px", overflowY: "auto" }}>
                {messages.map((msg) => (
                    <Message key={msg.id} userId={user.id} message={msg} />
                ))}
                <span ref={scroll}></span>
            </div>
            <div className="card-footer">
                <MessageInput rootUrl={rootUrl} />
            </div>
        </div>
    );
};

export default ChatBox;
```

Penjelasan:
- Mengambil data pengguna dari atribut HTML dan menggunakan `useState` untuk menyimpan pesan.
- Menggunakan `useEffect()` untuk melakukan koneksi WebSocket melalui `window.Echo` ke channel `message_channel` dan mendengarkan event `GotMessage`.
- Fungsi `getMessages()` mengambil daftar pesan dari server melalui endpoint `messages` dan menyimpannya di dalam state.
- Menggunakan referensi (`useRef`) untuk scroll otomatis ke pesan terbaru saat ada pesan baru.

### 4. Buat file `Main.jsx`
File ini adalah file utama untuk merender `ChatBox`. Sekarang kita buat file `resources/js/components/Main.jsx`.

```
import React from 'react';
import ReactDOM from 'react-dom/client';
import '../../css/app.css';
import ChatBox from "./ChatBox.jsx";

if (document.getElementById('main')) {
    const rootUrl = "http://127.0.0.1:8000";

    ReactDOM.createRoot(document.getElementById('main')).render(
        <React.StrictMode>
            <ChatBox rootUrl={rootUrl} />
        </React.StrictMode>
    );
}
```

Penjelasan:
- Menggunakan `ReactDOM.createRoot()` untuk merender `ChatBox` ke elemen DOM dengan ID `main`.
- Variabel `rootUrl` diinisialisasi dengan nilai URL `http://127.0.0.1:8000`, yang digunakan dalam `ChatBox` untuk akses endpoint.

Pada tahapan ini kita akan import file dan komponen yang sudah kita coding di dalam file `resources/js/app.js`. Buka file `resources/js/app.js`, lalu kita sesuaikan seperti berikut ini.

```
/**
 * First we will load all of this project's JavaScript dependencies which
 * includes React and other helpers. It's a great starting point while
 * building robust, powerful web applications using React + Laravel.
 */

import './bootstrap';

/**
 * Next, we will create a fresh React component instance and attach it to
 * the page. Then, you may begin adding components to this application
 * or customize the JavaScript scaffolding to fit your unique needs.
 */

import './components/Main.jsx'; // ubah bagian ini
```

Selanjutnya buka file `resources/js/bootstrap.js`. Pastikan terdapat baris kode berikut ini

```
import './echo';
```

File `resources/js/echo.js` ini berisi konfigurasi `Laravel Echo` dan juga konfigurasi `Laravel Reverb`.

```
import Echo from 'laravel-echo';

import Pusher from 'pusher-js';
window.Pusher = Pusher;

window.Echo = new Echo({
    broadcaster: 'reverb',
    key: import.meta.env.VITE_REVERB_APP_KEY,
    wsHost: import.meta.env.VITE_REVERB_HOST,
    wsPort: import.meta.env.VITE_REVERB_PORT ?? 80,
    wssPort: import.meta.env.VITE_REVERB_PORT ?? 443,
    forceTLS: (import.meta.env.VITE_REVERB_SCHEME ?? 'https') === 'https',
    enabledTransports: ['ws', 'wss'],
});

```



---
## Step 13: Modifikasi Composer Script {#step-13-modifikasi-composer-script}

Pada tahap ini, kita perlu memodifikasi script di file `composer.json` agar server dapat menjalankan berbagai task secara bersamaan, termasuk WebSocket server, queue listener, dan kompilasi asset frontend.

Buka file `composer.json` dan cari bagian yang berisi script `dev`. Ubah kode yang ada menjadi seperti berikut:

```json
"dev": [
    "Composer\\Config::disableProcessTimeout",
    "npx concurrently -c \"#93c5fd,#c4b5fd,#fb7185,#fdba74\" \"php artisan serve\" \"php artisan queue:listen --tries=1\" \"php artisan pail --timeout=0\" \"npm run dev\" --names=server,queue,logs,vite"
]
```

Selanjutnya kita sesuaikan menjadi seperti berikut ini.
```json
"dev": [
    "Composer\\Config::disableProcessTimeout",
    "npx concurrently -c \"#93c5fd,#c4b5fd,#fb7185,#fdba74\" \"php artisan serve\" \"php artisan queue:listen --tries=1\" \"php artisan pail --timeout=0\" \"npm run dev\" \"php artisan reverb:start\" --names=server,queue,logs,vite,reverb"
]
```

Penjelasan:
- Kita menambahkan `"php artisan reverb:start"` untuk menjalankan server Reverb secara otomatis setiap kali kita menjalankan `composer run dev`.
- Script ini memastikan semua layanan (server, queue, WebSocket, dan frontend) berjalan secara bersamaan.

---

## Step 14: Build Frontend Asset {#step-14-build-frontend-asset}

Setelah menyelesaikan konfigurasi backend dan frontend, kita perlu memastikan bahwa semua asset frontend sudah terkompilasi dengan benar. Jalankan perintah berikut:

```bash
npm run dev
```

Jika Anda ingin membangun untuk environment produksi, gunakan perintah berikut:

```bash
npm run build
```

Dengan langkah ini, file `app.js` dan `app.css` akan dikompilasi dan siap digunakan di aplikasi Laravel Anda.

---

## Step 15: Uji Coba Aplikasi Chat {#step-15-uji-coba-aplikasi-chat}

Selamat! Anda sudah hampir menyelesaikan semua langkah. Sekarang saatnya menguji aplikasi chat yang telah kita buat.

### Cara Uji Coba:
1. **Run Server, queue, websocket, dan npm**:
Untuk run service secara bersamaan, jalankan command berikut ini.
```bash
composer run dev
```

Terminal akan menampilkan beberapa proses berjalan secara paralel, seperti server Laravel, queue listener, WebSocket server, dan kompilasi asset dengan Vite.

2. **Akses Aplikasi di Browser**:
   Buka browser dan akses URL:
   ```
   http://127.0.0.1:8000
   ```

### Uji Fungsi Chat:
- Buat dua akun di halaman register.
- Login ke aplikasi dengan akun yang sudah Anda buat.
- Buka beberapa tab browser (atau gunakan perangkat berbeda) dan login dengan akun yang berbeda.
- Coba kirim pesan dari satu akun, pesan tersebut seharusnya muncul secara otomatis di semua tab yang terbuka tanpa perlu me-refresh halaman.

Jika semua berjalan dengan baik, Anda akan melihat pesan dikirim dan diterima secara real-time, berkat integrasi Laravel Reverb dan sistem queue.

<video width="600" controls>
  <source src="https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-reverb-chat-app/demo-aplikasi-chat-tutorial%20laravel%20reverb.webm" type="video/webm">
  Demo Aplikasi Chat
</video>

---

## Penjelasan Alur Kerja {#penjelasan-alur-kerja}
Dalam tutorial ini, kita membangun aplikasi obrolan real-time menggunakan **Laravel**, **React**, dan **Laravel Reverb** sebagai *broadcasting* service. Berikut adalah penjelasan lengkap tentang bagaimana **Laravel Reverb** berperan dalam alur kerja aplikasi ini.

### 1. **User Mengirim Pesan**
   - Ketika pengguna mengetik pesan di *chatbox* dan menekan tombol **Send**, *frontend* React akan mengirimkan *request* HTTP ke server Laravel melalui `axios`.
   - *Request* ini dikirim ke *endpoint* `/message/send` yang telah didefinisikan dalam file `routes/web.php`.

### 2. **Controller Menerima dan Memproses Pesan**
   - Request dari *frontend* diterima oleh `MessageController` pada metode `store`.
   - Di dalam metode `store`, aplikasi akan:
     - Membuat *record* baru di tabel `messages` menggunakan `Message::create()`.
     - Menyimpan data pesan berikut informasi *user* ke dalam database.
   - Setelah pesan berhasil disimpan, sebuah *job* bernama `SendMessage` akan didispatch ke dalam queue menggunakan `SendMessage::dispatch($message)`.

### 3. **SendMessage Job Diproses**
   - Ketika *job* `SendMessage` dijalankan oleh *queue worker*, tugas ini akan:
     - Mengambil data pesan yang baru saja disimpan.
     - Membuat sebuah event bernama `GotMessage` menggunakan `GotMessage::dispatch()`.
     - Event ini membawa informasi tentang pesan (seperti `user_id`, `text`, dan `time`) yang akan dikirim ke semua *clients* yang terhubung melalui Laravel Reverb.

### 4. **Laravel Reverb Mengirimkan Broadcast**
   - Pada bagian ini, **Laravel Reverb** berperan sebagai *broadcasting server* yang memungkinkan pesan dikirim secara real-time ke semua *clients* yang sedang terhubung ke *channel* yang sesuai.
   - Event `GotMessage` dikirim melalui *channel* bernama `message_channel`, yang telah didefinisikan di file `routes/channels.php`.
   - Laravel Reverb memastikan bahwa semua *clients* yang berlangganan ke *channel* `message_channel` akan menerima pesan baru secara real-time tanpa perlu *refresh* halaman.

### 5. **Frontend Menerima Pesan melalui WebSocket**
   - Di *frontend*, React menggunakan Laravel Echo (yang dikonfigurasi untuk menggunakan Laravel Reverb) untuk berlangganan ke *channel* `message_channel`.
   - Ketika event `GotMessage` diterima oleh *frontend*, aplikasi akan:
     - Memperbarui *state* React dengan pesan baru yang diterima.
     - Menampilkan pesan tersebut di *chatbox* tanpa harus melakukan *refresh* halaman.

### 6. **Pesan Ditampilkan pada Chatbox**
   - Setelah pesan diterima oleh React, *component* `ChatBox` akan secara otomatis menambahkan pesan baru ke daftar obrolan.
   - *Scroll* otomatis ke bagian bawah *chatbox* dilakukan setiap kali pesan baru masuk, sehingga pengguna dapat melihat pesan terbaru dengan mudah.

### Rangkuman Alur
Secara singkat, berikut adalah alur kerja aplikasi chat ini:
1. Pengguna mengetik pesan dan mengirimkannya.
2. Pesan dikirim ke *backend* Laravel dan disimpan di database.
3. Sebuah *job* dijalankan untuk memicu event `GotMessage`.
4. Laravel Reverb melakukan *broadcast* pesan ke semua *clients* yang berlangganan.
5. *Frontend* React menerima pesan melalui WebSocket dan memperbarui tampilan secara real-time.

---

## Kesimpulan {#kesimpulan}
Dalam tutorial ini, kita telah mempelajari cara membangun aplikasi chat real-time menggunakan Laravel 11, React, dan Laravel Reverb. Dengan memanfaatkan WebSocket, sistem queue, dan komponen frontend berbasis React, kita berhasil menciptakan pengalaman chat yang interaktif dan responsif.

Selain memberikan pemahaman mendalam tentang integrasi Laravel dan React, tutorial ini juga membuka wawasan tentang cara memanfaatkan teknologi modern seperti Laravel Reverb untuk menangani komunikasi real-time. Anda sekarang memiliki fondasi yang kuat untuk membangun aplikasi yang lebih kompleks dan skalabel.

Selamat bereksperimen dan semoga proyek ini menjadi inspirasi bagi pengembangan aplikasi Anda selanjutnya!

--- 

Terima kasih telah mengikuti tutorial ini. Jangan ragu untuk membagikan pengalaman Anda di komentar atau bertanya jika ada kesulitan. Selamat coding!

## References {#references}
Untuk panduan lebih lanjut, Anda dapat merujuk ke dokumentasi resmi:
- Laravel UI: [GitHub Repository](https://github.com/laravel/ui)
- Laravel Reverb: [Laravel Documentation](https://laravel.com/docs/11.x/reverb#installation)