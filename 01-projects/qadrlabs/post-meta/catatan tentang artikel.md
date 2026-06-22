---
status: draft
created: 2026-06-07
---
The sequel article is written and verified, saved to 01-projects/qadrlabs/post
  /01-draft/mysql-indexing-201-joins-sorting-grouping-pagination.md. Every
  EXPLAIN and EXPLAIN ANALYZE output is real, captured from a live MySQL 8.4
  container against a 50k-customer / 500k-order dataset, and reproduced unedited
  (I fixed three transcription typos in table borders to match the actual
  output). The container is torn down and temp files cleaned up.

  Answer to your question: what would the follow-up cover?

  Article 1 (Indexing 101) handled single-table filtering. The natural sequel
  tackles the four query shapes that dominate real apps but were left untouched:

  1. JOINs — MySQL runs joins as a nested loop, so a missing index on the join
  column forces a full scan per matched row. The demo goes from 107ms to 0.048ms
  just by indexing the foreign key.
  2. ORDER BY / Using filesort — an index that already stores the sort order
  eliminates the sort (154ms to 0.24ms), and a composite (filter, sort) index
  serves WHERE + ORDER BY at once (137ms to 3ms).
  3. GROUP BY / Using temporary — an index on the grouping column streams the
  aggregation instead of building a temp table (216ms to 134ms).
  4. Pagination — deep OFFSET reads everything it skips (200,020 rows, 38ms),
  while keyset/seek pagination stays constant (0.24ms, same as page 1).

  Deliverables

  1. Article Title

  ▎ MySQL Indexing 201: Speeding Up JOINs, ORDER BY, GROUP BY, and Pagination

  2. Short Description

  ▎ The sequel to Indexing 101: use EXPLAIN to speed up JOINs, kill Using 
  ▎ filesort and Using temporary, and replace slow deep OFFSET with keyset 
  ▎ pagination.

  Character count: 157 (within 160).

  3. Category and Tags

  - Category: Database
  - Tags: mysql, database, indexing, performance, query-optimization, joins,
  pagination, explain-analyze

  Want me to proceed with the Indonesian translation, generate social media
  captions, or adjust anything in the draft?



---
Implemented the full draft here:

  01-projects/qadrlabs/post/01-draft/processing-huge-csv-files-in-php-with-
  generators.md:1

  I also validated the sample PHP scripts in sandbox/huge-csv-generators,
  checked the article for forbidden em dash/en dash/---, and confirmed the draft
  is 2,689 words. The sandbox files are ignored by Git, so the committed source
  change is only the new draft file.

  Title: Processing Huge CSV Files in PHP with Generators: Millions of Rows
  Without Running Out of Memory

  Short description: Learn how to process huge CSV files in native PHP with
  generators, fgetcsv(), and streaming exports without exhausting memory.
  Character count: 126

  Category: PHP

  Tags: PHP, Generators, CSV, Performance, Memory Optimization


---

1. File markdown

  01-projects/qadrlabs/post/01-draft/secure-file-uploads-in-laravel-mime-validat
  ion-path-traversal-and-image-bombs.md

  Struktur: PAS opening (link ke artikel image-upload) → Overview
  (Build/Learn/Need) → Step 1-10 berurutan → section konseptual Understanding 
  the Three Attacks (tanpa label Step, setelah testing) → Conclusion. Tanpa
  em/en dash, tanpa ---, semua H2 ada anchor {#slug} dan narasi sebelum H3.

  Sesuai catatanmu yang sudah diterapkan:
  - Setiap make:model / make:controller / make:request dibuat sebelum file-nya
  diedit. Tidak ada edit file yang belum di-generate.
  - Setiap edit menyebut nama file + alasannya. Step 7 menampilkan kode lama 
  (Step 6) → kode baru secara eksplisit saat re-encode diperkenalkan.

  Yang diverifikasi nyata di sandbox (Laravel 13.16.1, PHP 8.5, Intervention
  Image 4.1.4): output php artisan migrate, make:*, route:list, pesan validasi
  disguised-PHP, dan output php artisan test (8 passed, 24 assertions) semuanya
  diambil apa adanya. Catatan: paket intervention/image v4 memakai decode() +
  WebpEncoder (bukan read()/toWebp() gaya v3); kode di artikel sudah pakai API
  yang benar dan terbukti jalan.

  2. Title

  Secure File Uploads in Laravel: MIME Validation, Path Traversal, and Image 
  Bombs

  3. Short description (158 karakter)

  ▎ Harden Laravel 13 image uploads: validate real MIME and dimensions, store 
  ▎ privately with random names, re-encode to strip payloads, and serve via 
  ▎ signed URLs.

  4. Category & Tags

  - Category: Security / Laravel
  - Tags: laravel, laravel-13, security, file-upload, mime-validation,
  path-traversal, image-bomb, signed-url, intervention-image, pest

---

1. File path (Obsidian)

  01-projects/qadrlabs/post/01-draft/introduction-to-artificial-intelligence.md

  Artikel konseptual pembuka untuk series machine learning / deep learning. Tanpa praktik/kode, tanpa label "Step N", tanpa em/en dash, tanpa ---. Overview memakai What You'll Take Away / Learn / Need (mengikuti pola SOLID intro). ~3.307 kata.

2. Title

  Introduction to Artificial Intelligence: A Plain-Language Foundation Before You Build

3. Short description (157 karakter)

  Confused by AI, machine learning, and deep learning? Build a clear, honest mental model of what AI is and how its pieces fit before you write any code.

4. Category & Tags

  - Category: Artificial Intelligence
  - Tags: artificial-intelligence, machine-learning, deep-learning, generative-ai, large-language-models, ai-agents, ai-for-beginners, ai-concepts

5. Referensi riset

  - IBM, AI vs ML vs Deep Learning vs Neural Networks: https://www.ibm.com/think/topics/ai-vs-machine-learning-vs-deep-learning-vs-neural-networks
  - IBM, What Are Large Language Models (LLMs): https://www.ibm.com/think/topics/large-language-models
  - Archielabs, The 3 Types of AI: Narrow, General & Superintelligence: https://www.archielabs.com/blog/3-types-of-ai/
  - Media and the Machine, The Top 20 Milestones in AI (1943 to Present): https://mediaandthemachine.substack.com/p/the-top-20-milestones-in-ai-1943
  - NovelVista, Real-World Applications of Agentic AI: 2026 Guide: https://www.novelvista.com/blogs/ai-and-ml/real-world-applications-agentic-ai

```
claude --resume 5d15eff2-4616-4d16-8a21-f10d258942df

```


resume claude
```
claude --resume 5345377f-4b60-4214-bb1c-915ad8989a38

```

