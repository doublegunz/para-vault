# Lesson 7 — Menampilkan Daftar dan Detail Catatan

## Tujuan Pembelajaran

Di akhir lesson ini, kamu akan:
- Membuat layout utama yang reusable menggunakan Blade components
- Membangun komponen `EntryCard` untuk menampilkan ringkasan catatan
- Menambahkan halaman detail untuk membaca catatan secara lengkap
- Memiliki tampilan daftar dan detail catatan yang rapi dan terstruktur

---

## Masalah dengan View yang Ada Sekarang

View `entries/index.blade.php` saat ini mencampur banyak hal sekaligus: struktur HTML lengkap, navigasi, dan logika daftar catatan. Ketika nanti kita membuat halaman detail, form tulis catatan, dan halaman login — semuanya perlu navigasi yang sama. Kita akan mengulang kode yang sama berulang kali.

**Blade components** memecahkan masalah ini dengan memungkinkan kita memisahkan bagian-bagian HTML menjadi potongan yang reusable.

---

## Membuat Layout Utama

Buat file `resources/views/components/layout.blade.php`:

```html
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title ?? 'Catatku' }}</title>
    <script src="https://unpkg.com/@tailwindcss/browser@4"></script>
</head>
<body class="bg-gray-50 min-h-screen">

    {{-- Navigasi --}}
    <nav class="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div class="max-w-2xl mx-auto px-4 py-3 flex items-center justify-between">
            <a href="/entries" class="text-xl font-bold text-gray-900 hover:text-gray-700">
                Catatku 📓
            </a>
            <div class="flex items-center gap-4">
                @auth
                    <span class="text-sm text-gray-500">{{ auth()->user()->name }}</span>
                    <form method="POST" action="/logout">
                        @csrf
                        <button type="submit"
                            class="text-sm text-gray-500 hover:text-gray-900 transition-colors">
                            Logout
                        </button>
                    </form>
                @else
                    <a href="/login" class="text-sm text-gray-600 hover:text-gray-900">Masuk</a>
                    <a href="/register"
                        class="text-sm bg-gray-900 text-white px-3 py-1.5 rounded-lg hover:bg-gray-700 transition-colors">
                        Daftar
                    </a>
                @endauth
            </div>
        </div>
    </nav>

    {{-- Konten halaman --}}
    <main class="max-w-2xl mx-auto px-4 py-8">

        {{-- Flash message sukses --}}
        @if (session('success'))
            <div class="mb-6 p-4 bg-green-50 border border-green-200 text-green-800 text-sm rounded-xl">
                {{ session('success') }}
            </div>
        @endif

        {{ $slot }}
    </main>

</body>
</html>
```

Hal penting di layout ini:

**`{{ $title ?? 'Catatku' }}`** — Judul halaman yang bisa diisi dari luar. Jika tidak diisi, default ke 'Catatku'.

**`@auth ... @else ... @endauth`** — Directive Blade untuk mengecek status login. Blok `@auth` ditampilkan jika user sudah login, `@else` jika belum.

**`{{ $slot }}`** — "Lubang" tempat konten dari halaman yang menggunakan layout ini akan disisipkan.

**Flash message** — Pesan sukses dari session akan ditampilkan di sini setiap kali ada. Ini akan berguna setelah menyimpan, memperbarui, atau menghapus catatan.

---

## Membuat Komponen EntryCard

Buat file `resources/views/components/entry-card.blade.php`:

```html
@props(['entry'])

<div class="bg-white rounded-xl border border-gray-200 p-5 hover:border-gray-300 transition-colors">

    {{-- Header: judul dan tanggal --}}
    <div class="flex items-start justify-between gap-3 mb-3">
        <a href="/entries/{{ $entry->id }}"
           class="font-semibold text-gray-900 hover:text-gray-600 leading-snug">
            {{ $entry->title }}
        </a>
        <span class="text-xs text-gray-400 whitespace-nowrap mt-0.5">
            {{ $entry->created_at->format('d M Y') }}
        </span>
    </div>

    {{-- Potongan isi catatan --}}
    <p class="text-sm text-gray-500 line-clamp-2 mb-4">
        {{ $entry->content }}
    </p>

    {{-- Tombol aksi --}}
    <div class="flex items-center gap-3 pt-3 border-t border-gray-100">
        <a href="/entries/{{ $entry->id }}"
           class="text-xs text-blue-600 hover:text-blue-800">
            Baca
        </a>
        <a href="/entries/{{ $entry->id }}/edit"
           class="text-xs text-gray-500 hover:text-gray-800">
            Edit
        </a>
        <form method="POST" action="/entries/{{ $entry->id }}"
              onsubmit="return confirm('Hapus catatan ini?')"
              class="ml-auto">
            @csrf
            @method('DELETE')
            <button type="submit" class="text-xs text-red-400 hover:text-red-600">
                Hapus
            </button>
        </form>
    </div>

</div>
```

**`@props(['entry'])`** — Mendefinisikan properti yang wajib diberikan saat menggunakan komponen ini. Nanti kita gunakan dengan `<x-entry-card :entry="$entry" />`.

---

## Memperbarui View Daftar Catatan

Sekarang perbarui `resources/views/entries/index.blade.php` untuk menggunakan layout dan komponen baru:

```html
<x-layout title="Catatanku — Catatku">

    <div class="flex items-center justify-between mb-6">
        <h2 class="text-lg font-semibold text-gray-900">Catatanku</h2>
        <a href="/entries/create"
           class="bg-gray-900 text-white text-sm px-4 py-2 rounded-lg hover:bg-gray-700 transition-colors">
            + Tulis Catatan Baru
        </a>
    </div>

    <div class="space-y-4">
        @forelse ($entries as $entry)
            <x-entry-card :entry="$entry" />
        @empty
            <div class="text-center py-16">
                <p class="text-5xl mb-4">📓</p>
                <p class="font-medium text-gray-600">Belum ada catatan</p>
                <p class="text-sm text-gray-400 mt-1">
                    Mulai tulis catatan pertamamu!
                </p>
                <a href="/entries/create"
                   class="inline-block mt-4 text-sm text-blue-600 hover:underline">
                    Tulis sekarang →
                </a>
            </div>
        @endforelse
    </div>

</x-layout>
```

Tampilan jauh lebih ringkas — hanya berisi konten inti, bukan lagi HTML boilerplate.

---

## Menambahkan Halaman Detail Catatan

Pengguna perlu bisa membaca catatan secara lengkap. Tambahkan method `show()` di `EntryController`:

```php
public function show(Entry $entry)
{
    // Pastikan hanya pemilik yang bisa membaca
    if ($entry->user_id !== auth()->id()) {
        abort(403);
    }

    return view('entries.show', compact('entry'));
}
```

**Route Model Binding** — Parameter `Entry $entry` membuat Laravel otomatis mengambil catatan berdasarkan ID di URL. Jika tidak ditemukan, otomatis 404.

**`abort(403)`** — Menghentikan eksekusi dan mengembalikan error "Forbidden". Ini memastikan user tidak bisa membaca catatan milik orang lain.

Tambahkan route baru di `routes/web.php`:

```php
Route::get('/entries', [EntryController::class, 'index']);
Route::get('/entries/{entry}', [EntryController::class, 'show']);
```

Buat file `resources/views/entries/show.blade.php`:

```html
<x-layout :title="$entry->title . ' — Catatku'">

    <div class="mb-6">
        <a href="/entries" class="text-sm text-gray-400 hover:text-gray-700">
            ← Kembali ke daftar
        </a>
    </div>

    <article class="bg-white rounded-xl border border-gray-200 p-6">

        {{-- Header --}}
        <div class="mb-6">
            <h1 class="text-2xl font-bold text-gray-900 mb-2">
                {{ $entry->title }}
            </h1>
            <p class="text-sm text-gray-400">
                Ditulis pada {{ $entry->created_at->isoFormat('D MMMM Y') }}
                @if ($entry->updated_at->ne($entry->created_at))
                    · Diperbarui {{ $entry->updated_at->diffForHumans() }}
                @endif
            </p>
        </div>

        {{-- Isi catatan --}}
        <div class="prose prose-gray max-w-none text-gray-700 leading-relaxed whitespace-pre-line">
            {{ $entry->content }}
        </div>

    </article>

    {{-- Tombol aksi --}}
    <div class="flex items-center gap-3 mt-4">
        <a href="/entries/{{ $entry->id }}/edit"
           class="text-sm bg-gray-900 text-white px-4 py-2 rounded-lg hover:bg-gray-700 transition-colors">
            Edit Catatan
        </a>
        <form method="POST" action="/entries/{{ $entry->id }}"
              onsubmit="return confirm('Hapus catatan ini?')">
            @csrf
            @method('DELETE')
            <button type="submit"
                class="text-sm text-red-500 hover:text-red-700 transition-colors">
                Hapus
            </button>
        </form>
    </div>

</x-layout>
```

**`whitespace-pre-line`** — Class Tailwind yang membuat baris baru dalam teks (`\n`) dirender sebagai baris baru di HTML, sehingga catatan berparagraf tampil dengan benar.

**`$entry->updated_at->ne($entry->created_at)`** — Menampilkan "Diperbarui X waktu lalu" hanya jika catatan pernah diedit setelah pertama kali ditulis.

---

## Ringkasan

Kita telah:
- Membuat layout utama dengan navigasi dinamis menggunakan `@auth`
- Membuat komponen `EntryCard` yang reusable dengan `@props`
- Memperbarui view daftar menggunakan `<x-layout>` dan `<x-entry-card>`
- Menambahkan halaman detail catatan dengan method `show()` dan view `entries/show`
- Menerapkan perlindungan sederhana agar user tidak bisa membaca catatan orang lain

Di lesson berikutnya, kita akan mengimplementasikan form untuk menulis catatan baru dan menyimpannya ke database.
