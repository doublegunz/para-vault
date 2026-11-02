# Sisa pekerjaan: pindah sandbox ke ~/sandbox

Isi `sandbox/` sudah dipindah ke `~/sandbox`. Langkah di bawah belum dikerjakan.

## 1. Izinkan agen menulis ke ~/sandbox

Edit `.claude/settings.json` ditolak oleh pengaman Claude Code. Tambahkan manual:

```json
{
  "permissions": {
    "additionalDirectories": [
      "/Users/gungunpriatna/Projects/qadrtech-hq/videos",
      "/Users/gungunpriatna/Projects/qadrlabs/learning-video",
      "/Users/gungunpriatna/sandbox"
    ]
  }
}
```

Atau jalankan `/add-dir ~/sandbox` di sesi Claude Code.

## 2. Perbaiki venv Python `.venv-ml`

`python` masih jalan, tetapi script seperti `pip` punya shebang ke path lama (`~/obsidian-vault/sandbox/.venv-ml/...`).

Pilihan cepat, pakai lewat python:

```bash
~/sandbox/.venv-ml/bin/python -m pip --version
```

Pilihan bersih, buat ulang venv:

```bash
cd ~/sandbox
pip freeze --path .venv-ml/lib/python3.9/site-packages > /tmp/ml-requirements.txt
rm -rf .venv-ml
python3 -m venv .venv-ml
.venv-ml/bin/python -m pip install -r /tmp/ml-requirements.txt
```

## 3. Cek project lain yang memuat path lama

Project Laravel/Node biasanya aman. Cek kalau ada path absolut ke `obsidian-vault/sandbox`:

```bash
grep -rIl 'obsidian-vault/sandbox' ~/sandbox \
  --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=.venv-ml 2>/dev/null
```

Ganti hasilnya (misalnya file `.env`, config, atau script) ke `~/sandbox/...`.

## 4. Commit perubahan di vault

```bash
cd ~/obsidian-vault
git status --short
git add -A
git commit -m "pindahkan sandbox ke luar vault"
```

Perubahan yang akan ikut ter-commit: `.gitignore`, `.obsidian/app.json`, `AGENTS.md`, `.claude/commands/susun-course.md`, dan penghapusan `sandbox/.gitkeep`.

## 5. Verifikasi akhir

- `ls ~/obsidian-vault` tidak menampilkan `sandbox`.
- `ls -a ~/sandbox` memuat semua project lama.
- Obsidian: search dan graph tidak memuat file `node_modules`.

## Catatan

Catatan lama (laporan uji coba, persiapan uji coba, note video, artikel published) masih menyebut `sandbox/...`. Sengaja dibiarkan karena sifatnya historis dan output terminal asli tidak boleh diubah.
