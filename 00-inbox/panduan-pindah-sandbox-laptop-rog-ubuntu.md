# Panduan: sesuaikan laptop ROG (Ubuntu) setelah sandbox pindah ke ~/sandbox

Di Mac, `sandbox/` sudah dipindah keluar vault ke `~/sandbox`. Perubahan di repo (AGENTS.md, `.gitignore`, `.obsidian/app.json`, command/skill `susun-course`) ikut lewat `git pull`. Konfigurasi lokal dan isi sandbox **tidak** ikut, jadi perlu disesuaikan manual di ROG.

Home di ROG: `/home/gun-gun-priatna` (berbeda dengan Mac: `/Users/gungunpriatna`).

## 1. Pull perubahan vault

```bash
cd ~/obsidian-vault
git status --short   # pastikan bersih
git pull
```

`sandbox/.gitkeep` ikut terhapus. Isi `sandbox/` lama di ROG tidak hilang karena sebelumnya diabaikan Git; foldernya tetap ada selama masih berisi file.

## 2. Pindahkan isi sandbox lama di ROG

```bash
mkdir -p ~/sandbox
cd ~/obsidian-vault/sandbox 2>/dev/null && ls -a
```

Pindahkan semuanya, termasuk dotfile:

```bash
cd ~/obsidian-vault
for f in sandbox/* sandbox/.[!.]*; do
  [ -e "$f" ] || continue
  [ "$(basename "$f")" = ".DS_Store" ] && continue
  mv "$f" ~/sandbox/
done
rmdir sandbox 2>/dev/null || rm -rf sandbox
```

Kalau sandbox di ROG kosong atau belum ada, cukup `mkdir -p ~/sandbox`.

## 3. Perbaiki venv dan path absolut

Venv menyimpan path absolut. Hapus dan buat ulang setiap venv yang dipindah (venv dari Mac tidak dipakai di ROG):

```bash
cd ~/sandbox
rm -rf .venv-ml
python3 -m venv .venv-ml
```

Cari file yang masih menyebut path lama:

```bash
grep -rIl 'obsidian-vault/sandbox' ~/sandbox \
  --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=.venv-ml 2>/dev/null
```

Ganti hasilnya (`.env`, config, script) ke `~/sandbox/...`. Untuk project Laravel/Node, jalankan ulang `composer install` / `npm install` bila ada error setelah dipindah.

## 4. Claude Code

`.claude/settings.json` ikut Git dan berisi path Mac. Jangan taruh path ROG di sana. Tambahkan di file lokal yang tidak ikut Git:

```bash
nano ~/obsidian-vault/.claude/settings.local.json
```

```json
{
  "permissions": {
    "allow": ["WebSearch"],
    "additionalDirectories": [
      "/home/gun-gun-priatna/sandbox"
    ]
  }
}
```

Atau sekali pakai: `claude --add-dir ~/sandbox`. Folder video bisa ditambah dengan cara yang sama bila path-nya di ROG berbeda.

## 5. Codex

`~/.codex/config.toml` (lokal, tidak ikut Git). Tambahkan `~/sandbox` ke folder yang boleh ditulis agent:

```toml
[sandbox_workspace_write]
writable_roots = [
  "/home/gun-gun-priatna/obsidian-vault",
  "/home/gun-gun-priatna/sandbox",
]
```

Sesuaikan juga blok trust project bila belum ada:

```toml
[projects."/home/gun-gun-priatna/obsidian-vault"]
trust_level = "trusted"
```

Cara manual: `codex --add-dir ~/sandbox`.

### Skill Codex yang masih menyebut `sandbox/`

Dua file ini ada di `~/.codex/skills/` (di luar vault, tidak ikut Git), jadi ubah manual di setiap mesin:

| File | Baris | Ubah |
|---|---|---|
| `~/.codex/skills/susun-course/SKILL.md` | 20 | `Test lesson code in sandbox/` menjadi `Test lesson code in ~/sandbox/` |
| `~/.codex/skills/susun-course/references/qadrlabs-course-guide.md` | 22 | `sandbox/qadrlabs-laravel` menjadi `~/sandbox/qadrlabs-laravel` |

Sekali jalan (GNU sed di Ubuntu):

```bash
sed -i 's#`sandbox/#`~/sandbox/#; s#in `sandbox/`#in `~/sandbox/`#' \
  ~/.codex/skills/susun-course/SKILL.md \
  ~/.codex/skills/susun-course/references/qadrlabs-course-guide.md
grep -n 'sandbox' ~/.codex/skills/susun-course/SKILL.md ~/.codex/skills/susun-course/references/qadrlabs-course-guide.md
```

Skill lain (`generate-artikel`, `terjemahkan-artikel`, `terjemahkan-course`, hyperframes, media-use) tidak menyebut sandbox milik vault. Salinan di vault (`.codex/skills/susun-course.md`) sudah diperbarui di Mac dan ikut `git pull`.

## 6. Obsidian di ROG

`.obsidian/app.json` sudah tidak memuat `userIgnoreFilters` untuk `sandbox/`, jadi tidak ada yang perlu diubah. Restart Obsidian dan pastikan search/graph tidak memuat file `node_modules`. Jika sandbox masih ada di dalam vault, pindahkan dulu (langkah 2).

## 7. Verifikasi

```bash
ls ~/obsidian-vault | grep -c '^sandbox$'    # harus 0
ls -a ~/sandbox
git -C ~/obsidian-vault status --short       # bersih
grep -rn 'sandbox/' ~/obsidian-vault/AGENTS.md ~/obsidian-vault/.claude ~/obsidian-vault/.codex
```

Sisa `sandbox/` di catatan historis (laporan uji coba, note video, artikel published) sengaja dibiarkan.
