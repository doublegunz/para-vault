# Prompt untuk Claude di laptop ROG: pindahkan sandbox keluar vault

Tugas ini sudah dikerjakan di Mac. Sekarang lakukan hal yang sama di laptop ROG (Ubuntu). Baca seluruh file ini, lalu kerjakan langkah demi langkah. Jawab dalam bahasa Indonesia.

## Konteks

- Vault: `~/obsidian-vault` (home di ROG: `/home/gun-gun-priatna`; konfirmasi dulu dengan `echo $HOME`).
- Dulu uji coba (tutorial, course, artikel) ada di `~/obsidian-vault/sandbox/`. Sekarang tempat uji coba pindah ke `~/sandbox` (di luar vault), supaya vault hanya berisi catatan.
- Perubahan di repo sudah di-commit dari Mac: `AGENTS.md`, `.gitignore`, `.obsidian/app.json`, `.claude/commands/susun-course.md`, `.codex/skills/susun-course.md`, dan penghapusan `sandbox/.gitkeep`. Semuanya ikut `git pull`.
- Yang tidak ikut Git dan harus disesuaikan di ROG: isi sandbox lama, venv, izin Claude Code lokal, konfigurasi Codex, dan skill Codex di `~/.codex/skills`.
- Panduan rinci ada di `00-inbox/panduan-pindah-sandbox-laptop-rog-ubuntu.md` setelah `git pull`.

## Aturan kerja

- Jangan hapus file apa pun sebelum kamu melihat isinya dan melaporkannya.
- Jangan ubah catatan lama yang menyebut `sandbox/...` (laporan uji coba, note video, artikel published). Itu catatan historis.
- Jangan ubah `.obsidian/workspace.json`.
- Jangan commit atau push sebelum aku minta.
- Jangan unduh apa pun tanpa konfirmasi.
- Kalau ada langkah yang ditolak oleh izin Claude Code (misalnya mengedit file pengaturan), berhenti di langkah itu, jelaskan, dan lanjutkan ke langkah lain. Aku yang memutuskan.

## Langkah

1. **Cek kondisi awal.**
   ```bash
   echo $HOME
   cd ~/obsidian-vault && git status --short && git log --oneline -3
   ls -a ~/obsidian-vault/sandbox 2>&1; du -sh ~/obsidian-vault/sandbox 2>/dev/null
   ls -d ~/sandbox 2>&1
   ```
   Laporkan hasilnya. Kalau `git status` tidak bersih, berhenti dan tanyakan.

2. **Pull perubahan.** `git pull` di `~/obsidian-vault`. Laporkan file yang berubah.

3. **Pindahkan isi sandbox lama** (jika ada) ke `~/sandbox`, termasuk dotfile. Lewati `.DS_Store`.
   ```bash
   mkdir -p ~/sandbox
   cd ~/obsidian-vault
   for f in sandbox/* sandbox/.[!.]*; do
     [ -e "$f" ] || continue
     [ "$(basename "$f")" = ".DS_Store" ] && continue
     mv "$f" ~/sandbox/
   done
   ```
   Setelah `sandbox/` di vault kosong (hanya sisa `.gitkeep` atau tidak ada isi), hapus folder `sandbox/` dari vault. Tampilkan `ls -a ~/sandbox` sebagai bukti.

4. **Venv dan path absolut.**
   - Venv dari Mac tidak dipakai di ROG. Untuk setiap `.venv*` di `~/sandbox` yang rusak setelah dipindah, tanyakan dulu apakah dibuat ulang (`python3 -m venv`), karena instal paket butuh unduhan.
   - Cari path lama:
     ```bash
     grep -rIl 'obsidian-vault/sandbox' ~/sandbox \
       --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=.venv-ml 2>/dev/null
     ```
     Tampilkan hasilnya, lalu ganti ke `~/sandbox/...` setelah aku setuju.

5. **Izin Claude Code (lokal).** Jangan edit `.claude/settings.json` (ikut Git, berisi path Mac). Tambahkan di `~/obsidian-vault/.claude/settings.local.json`:
   ```json
   {
     "permissions": {
       "allow": ["WebSearch"],
       "additionalDirectories": ["/home/gun-gun-priatna/sandbox"]
     }
   }
   ```
   Pertahankan isi `allow` yang sudah ada. Kalau file ini sudah punya isi lain, gabungkan, jangan timpa. Jika edit ditolak, berikan isinya padaku untuk ditempel manual.

6. **Konfigurasi Codex** (`~/.codex/config.toml`, jika ada). Tambahkan, tanpa menghapus isi lain:
   ```toml
   [sandbox_workspace_write]
   writable_roots = [
     "/home/gun-gun-priatna/obsidian-vault",
     "/home/gun-gun-priatna/sandbox",
   ]
   ```
   Kalau blok `[sandbox_workspace_write]` sudah ada, tambahkan path ke `writable_roots` yang ada. Pastikan juga ada trust untuk `/home/gun-gun-priatna/obsidian-vault`. Jika Codex tidak terpasang di ROG, lewati langkah ini.

7. **Skill Codex yang masih menyebut `sandbox/`** (di luar vault, tidak ikut Git). Cek dulu apakah file ada, lalu ubah:
   - `~/.codex/skills/susun-course/SKILL.md` baris ~20: `sandbox/` menjadi `~/sandbox/`
   - `~/.codex/skills/susun-course/references/qadrlabs-course-guide.md` baris ~22: `sandbox/qadrlabs-laravel` menjadi `~/sandbox/qadrlabs-laravel`
   Tampilkan baris sebelum dan sesudah. Skill lain tidak menyebut sandbox milik vault.

8. **Cache Obsidian.** Setelah ribuan file dipindah, Obsidian akan membangun ulang indeks. Tutup Obsidian, lalu (jika kuminta) hapus cache:
   ```bash
   rm -rf ~/.config/obsidian/IndexedDB ~/.config/obsidian/Cache ~/.config/obsidian/"Code Cache"
   ```
   Tanyakan dulu sebelum menghapus. Detail ada di `00-inbox/petunjuk-percepat-loading-obsidian.md`.

9. **Cek folder besar lain di dalam vault** (opsional, hanya laporan):
   ```bash
   cd ~/obsidian-vault
   du -sh .[!.]* * 2>/dev/null | sort -h | tail -8
   find . -maxdepth 6 \( -name node_modules -o -name vendor -o -name .venv \) 2>/dev/null | grep -v '^./.git' | head
   ```

## Verifikasi akhir

Jalankan dan laporkan hasilnya:

```bash
ls ~/obsidian-vault | grep -c '^sandbox$'      # harus 0
ls -a ~/sandbox
git -C ~/obsidian-vault status --short          # hanya perubahan lokal yang disengaja
grep -rn 'sandbox/' ~/obsidian-vault/AGENTS.md ~/obsidian-vault/.claude ~/obsidian-vault/.codex
```

Akhiri dengan ringkasan: langkah yang selesai, yang dilewati, yang butuh keputusanku, dan file apa saja yang berubah. Jangan commit.
