# Laporan Uji Coba Course "Learn Git" (Lesson 1-18)

**Tanggal uji:** 2026-07-12  
**Penguji:** Codex  
**Hasil keseluruhan:** ✅ Seluruh alur Git yang dapat dijalankan secara lokal berhasil, dengan 231 pemeriksaan lulus dan 0 gagal.

## Environment

| Komponen | Versi / Nilai |
|----------|---------------|
| Sistem operasi | Linux 7.0.0-27-generic x86_64 |
| Shell | GNU Bash 5.3.9 |
| Git | 2.53.0 |
| Default branch | `main` |
| Lokasi project | `sandbox/learn-git-test/work/portfolio` (gitignored) |
| Remote utama | Bare repository lokal `portfolio-origin.git` |
| Remote fork | Bare repository lokal `fork-origin.git` |
| Remote upstream | Bare repository lokal `original-upstream.git` |
| Hasil assertion | 231 PASS, 0 FAIL |

> Catatan: Lesson 10-14 dan command remote pada lesson berikutnya diuji dengan bare Git repositories lokal. Mekanisme Git seperti push, pull, fetch, clone, origin, upstream, tracking branch, rejected push, dan integrasi branch tetap dijalankan langsung. Pembuatan akun, SSH/PAT, fork melalui UI, pull request, review, branch protection, dan GitHub Releases tidak diuji terhadap layanan GitHub sungguhan.

## Verifikasi per Lesson

| Lesson | Yang diuji | Hasil |
|--------|------------|-------|
| 1 | Instalasi Git tersedia dan konsep local version control | ✅ `git version 2.53.0` |
| 2 | Konfigurasi identitas, default branch, editor, dan `git init` | ✅ Konfigurasi bekerja dalam HOME terisolasi; branch awal `main` |
| 3 | Repository pertama, add, commit, status, dan log | ✅ Commit awal dan commit lanjutan berhasil |
| 4 | Staging beberapa file, commit terpisah, dan `restore --staged` | ✅ Perubahan tetap ada di working tree setelah unstage |
| 5 | Log, graph, diff unstaged/staged, show, dan invalid hash | ✅ Output sesuai state; invalid hash gagal sebagaimana dijelaskan |
| 6 | Daftar branch dan model branch konseptual | ✅ Branch `main` terverifikasi |
| 7 | Create, switch, isolasi file antar-branch, dan duplicate branch error | ✅ Semua skenario berhasil |
| 8 | Fast-forward merge, three-way merge, safe delete, dan force delete | ✅ Merge commit memiliki dua parent; delete guard bekerja |
| 9 | Konflik pada file yang sama, unmerged index, resolusi, dan merge commit | ✅ Konflik muncul dan berhasil diselesaikan |
| 10 | Remote add/set-url, first push, upstream tracking, duplicate origin | ✅ Diuji dengan bare remote lokal |
| 11 | Push, fetch tanpa merge, inspect, pull, rejected push, dan konflik pull | ✅ Dua working copy berhasil mensimulasikan kolaborator |
| 12 | Clone, fork remote, origin/upstream, feature contribution | ✅ Diuji dengan tiga bare/working repositories lokal |
| 13 | Feature branch, push, merge PR, pull hasil merge, delete branch | ✅ Lifecycle PR disimulasikan dengan merge `--no-ff` dari clone kedua |
| 14 | GitHub Flow dan Gitflow: feature, develop, release, tracking remote | ✅ Semua branch dan push berhasil |
| 15 | Stash, stash pop, hotfix terisolasi, dan cherry-pick hash aktual | ✅ Working changes pulih dan hotfix tersalin ke `main` |
| 16 | Amend, rebase, fast-forward integration, soft/mixed/hard reset | ✅ Perubahan hash dan state index/working tree sesuai jenis reset |
| 17 | Annotated tags, push tags, `.gitignore`, tracked file, `rm --cached` | ✅ Tag remote dan seluruh ignore behavior terverifikasi |
| 18 | Workflow harian: pull, feature branch, commit, push tracking, cleanup | ✅ Workflow selesai dengan working tree bersih |

## Detail Pengujian Penting

### Lesson 2: instalasi dan konfigurasi terisolasi

Konfigurasi global course tidak diterapkan ke HOME pengguna asli. Pengujian memakai HOME khusus di sandbox dan menghasilkan:

```text
user.name=Budi Santoso
user.email=budi@example.com
init.defaultbranch=main
core.editor=true
Initialized empty Git repository in /home/gun-gun-priatna/obsidian-vault/sandbox/learn-git-test/work/git-test/.git/
```

Command instalasi Windows, Homebrew/macOS, dan `sudo apt` tidak dijalankan karena environment Linux sudah memiliki Git 2.53.0. Command tersebut bersifat alternatif per platform, bukan langkah yang harus dijalankan semuanya pada satu mesin.

### Lesson 8: fast-forward dan three-way merge

Fast-forward merge memasukkan `contact.html`, sedangkan perubahan terpisah pada `main` dan `feature/footer` menghasilkan merge commit nyata:

```text
Merge made by the 'ort' strategy.
 index.html | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

Safe deletion terhadap branch yang benar-benar belum terintegrasi juga ditolak:

```text
error: the branch 'experiment/dark-theme' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D experiment/dark-theme'
```

### Lesson 9: merge conflict

Perubahan heading berbeda pada `main` dan `feature/hero-text` menghasilkan konflik aktual:

```text
Auto-merging index.html
CONFLICT (content): Merge conflict in index.html
Automatic merge failed; fix conflicts and then commit the result.
```

File kemudian diselesaikan, ditambahkan kembali ke staging area, dan merge commit berhasil dibuat.

### Lesson 10-12: remote dan kolaborasi lokal

Push pertama membuat tracking relationship yang sama seperti remote GitHub:

```text
To /home/gun-gun-priatna/obsidian-vault/sandbox/learn-git-test/work/portfolio-origin.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

Clone kedua membuat commit sebagai `Siti Collaborator`. Setelah remote bergerak lebih dulu, push dari repository utama ditolak secara nyata:

```text
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '/home/gun-gun-priatna/obsidian-vault/sandbox/learn-git-test/work/portfolio-origin.git'
```

`git fetch` memperbarui `origin/main` tanpa mengubah `main`. Commit pending terlihat melalui `git log --oneline main..origin/main`, lalu dapat diperiksa dengan `git show origin/main` dan diintegrasikan.

### Lesson 13: simulasi pull request

Branch `feature/projects-page` didorong ke origin. Clone kolaborator mengambil branch tersebut dan menjalankan merge `--no-ff` ke `main`, lalu mendorong merge commit ke origin. Repository utama menjalankan pull dan memperoleh `projects.html`. Ini memvalidasi data flow Git di balik pull request, tetapi tidak memvalidasi form, review comments, approval, atau tombol merge GitHub.

### Lesson 15: stash dan cherry-pick

Perubahan gallery yang belum siap disimpan dengan stash, working tree kembali bersih, lalu `git stash pop` memulihkan kedua file:

```text
Saved working directory and index state On feature/gallery: gallery work in progress
Dropped refs/stash@{0}
```

Hotfix dibuat pada branch terpisah. Hash aktual hasil commit digunakan untuk `git cherry-pick`, dan commit yang sama muncul pada `main`.

### Lesson 16: rewrite dan reset

- `git commit --amend` menghasilkan hash commit baru.
- `git rebase main` memutar ulang commit feature di atas tip `main` dan dapat diintegrasikan dengan fast-forward.
- `git reset --soft HEAD~1` mempertahankan perubahan di staging area.
- `git reset HEAD~1` mempertahankan perubahan sebagai unstaged.
- `git reset --hard HEAD~1` memindahkan HEAD dan membersihkan working tree; hash sebelumnya dipulihkan kembali dalam repository uji terisolasi.

### Lesson 17: tags dan `.gitignore`

Annotated tags `v0.1` dan `v1.0` berhasil dibuat dan dikirim ke bare remote. Pengujian juga membuktikan bahwa menambahkan pattern ignore tidak otomatis menghentikan tracking file yang sudah committed. Setelah `git rm --cached secrets.txt`, file tetap ada di disk dan tidak lagi muncul pada status karena sudah di-ignore.

## Temuan Penting

1. **Alur lokal course akurat.** Init, staging, commits, diff, branch, merge, conflict resolution, stash, cherry-pick, rebase, reset, tags, dan ignore rules semuanya bekerja pada Git 2.53.0.

2. **Materi remote dapat disimulasikan sepenuhnya dengan Git lokal.** Push, pull, fetch, clone, origin, upstream, tracking relationship, non-fast-forward rejection, dan sinkronisasi antar-kontributor tidak bergantung pada UI GitHub.

3. **Konflik saat pull adalah skenario nyata.** Ketika local dan remote mengubah baris README yang sama, `git pull --no-rebase` menghasilkan conflict dan harus diselesaikan dengan alur yang sama seperti Lesson 9.

4. **Hash contoh harus diganti hash aktual.** Placeholder seperti `a1b2c3d`, `d4e5f6a`, `<hash1>`, `<first-hash>`, dan `<middle-hash>` memang tidak dapat dijalankan literal. Saat praktik, hash diambil dari `git log --oneline`, sesuai maksud penjelasan course.

5. **Git 2.53 memperbolehkan satu safe-delete yang patut diperhatikan.** Pada Lesson 18, setelah feature branch dipush dan memiliki upstream, `git branch -d feature/my-task` berhasil walaupun commit belum ada di local `main`. Git memberi warning bahwa branch sudah merged ke `refs/remotes/origin/feature/my-task`, tetapi belum ke `HEAD`. Ini perilaku aktual versi yang diuji, bukan kegagalan course.

## Batasan Pengujian

- Pembuatan akun dan repository melalui website GitHub tidak dijalankan.
- `ssh-keygen`, penambahan public key ke akun, `ssh -T git@github.com`, dan autentikasi PAT tidak dijalankan agar tidak membuat atau mengubah kredensial pengguna.
- Fork button, form pull request, review/approval, merge strategies melalui UI, branch protection, dan GitHub Releases tidak diuji.
- Command instalasi Git lintas OS tidak dijalankan pada Linux yang sudah memiliki Git.
- Command contoh yang berisi username, URL, path home, atau hash placeholder dijalankan dengan nilai sandbox/runtime yang ekuivalen.

## Kesimpulan

Course **layak dipublikasikan dari sisi mekanisme Git lokal dan remote protocol**. Semua command inti dan latihan aman yang dapat diuji tanpa layanan eksternal berhasil dengan 231 pemeriksaan lulus dan 0 gagal. Materi GitHub UI dan autentikasi masih memerlukan smoke test manual dengan akun GitHub sungguhan bila dibutuhkan sebelum publikasi, tetapi alur Git yang mendasarinya sudah tervalidasi.

Log terminal lengkap tersedia di `sandbox/learn-git-test/course-test.log`. Harness yang dapat dijalankan ulang tersedia di `sandbox/learn-git-test/run-course-test.sh`; keduanya berada di folder gitignored.
