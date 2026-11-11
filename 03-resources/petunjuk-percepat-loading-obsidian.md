# Petunjuk: percepat loading cache Obsidian

Penyebab umum: ribuan file (`node_modules`, `vendor`) baru dihapus atau dipindah dari vault, jadi Obsidian membangun ulang indeks dan cache. Biasanya hanya lambat sekali.

## 1. Tunggu indexing, lalu restart

Tunggu indexing selesai, tutup Obsidian (Cmd+Q di Mac), lalu buka lagi.

## 2. Reload dari command palette

Buka command palette (Cmd+P / Ctrl+P), lalu jalankan **Reload app without saving**.

## 3. Hapus cache lokal

Aman dihapus. Cache dibuat ulang dan catatan tidak tersentuh. Tutup Obsidian dulu. Pembukaan berikutnya akan lebih lama sekali karena indeks dibangun ulang.

macOS:

```bash
rm -rf ~/Library/Application\ Support/obsidian/IndexedDB
rm -rf ~/Library/Application\ Support/obsidian/Cache ~/Library/Application\ Support/obsidian/Code\ Cache
```

Ubuntu (ROG):

```bash
rm -rf ~/.config/obsidian/IndexedDB ~/.config/obsidian/Cache ~/.config/obsidian/"Code Cache"
```

## 4. Cek folder besar di dalam vault

Obsidian mengindeks semua file di vault. Folder dependency di dalamnya memperlambat load.

```bash
cd ~/obsidian-vault
du -sh .[!.]* * 2>/dev/null | sort -h | tail -8
find . -maxdepth 6 \( -name node_modules -o -name vendor -o -name .venv \) 2>/dev/null | grep -v '^./.git' | head
```

Kalau ada hasilnya, pindahkan ke `~/sandbox`.
