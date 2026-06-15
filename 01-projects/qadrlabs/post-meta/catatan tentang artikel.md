---
status: draft
created: 2026-06-07
---
Deliverables

  1. Article title (publication-ready):
  Spring Boot 4 File Upload and Download Tutorial: Multipart, Validation, and
  Safe Storage

  2. Short description (156 characters):
  Spring Boot 4 file upload and download tutorial: configure multipart limits,
  validate file type and size, block path traversal, and stream secure
  downloads.

  3. Category and tags:
  - Category: Java / Spring Boot
  - Tags: spring-boot, spring-boot-4, file-upload, file-download, multipart,
  multipartfile, java, validation, file-storage, mockmvc

  ---

Deliverables

  File: 01-projects/qadrlabs/post/01-draft/Spring Boot 4 Authorization Tutorial 
  Post Ownership and Role-Based Access with PreAuthorize.md

  1. Title: Spring Boot 4 Authorization Tutorial: Post Ownership and Role-Based
  Access with @PreAuthorize
  2. Title: Spring Boot 4 Authorization Tutorial: Post Ownership and Role-Based
  Access with @PreAuthorize

  3. Short description (149 chars): Spring Boot 4 authorization tutorial: give
  posts an owner and restrict edit and delete to the author or an admin using
  @PreAuthorize method security.

  4. Category and tags:
  - Category: Java / Spring Boot
  - Tags: spring-boot, spring-boot-4, spring-security, authorization,
  preauthorize, method-security, role-based-access, java, thymeleaf, mockmvc

  The plan file is at
  /home/gun-gun-priatna/.claude/plans/dari-tutorial-ini-apa-crispy-cascade.md.
  Want me to generate social captions for this one, or move either draft to
  02-ready-to-publish?



Deliverables
  
  File: 01-projects/qadrlabs/post/01-draft/Spring Boot 4 Tutorial Attach Files 
  to a Post with a JPA One-to-Many Relationship.md

  1. Title: Spring Boot 4 Tutorial: Attach Files to a Post with a JPA
  One-to-Many Relationship

  2. Short description (149 chars): Spring Boot 4 tutorial: attach files to a
  post with a JPA one-to-many relationship, with inline image previews,
  downloads, and owner-only management.

  3. Category and tags:
  - Category: Java / Spring Boot
  - Tags: spring-boot, spring-boot-4, jpa, one-to-many, file-upload, hibernate,
  thymeleaf, spring-security, preauthorize, java
  
  One limitation the article calls out honestly: deleting a post cascades the
  attachment rows but leaves the files on disk; the per-attachment delete
  handles disk cleanup, and the article points to extending
  PostService.deletePost as the natural next hardening step.

  The series now spans CRUD → Testing → Authentication → Upload → Authorization
  → Attachments-per-Post, with three drafts sitting in 01-draft/. Want me to
  generate social captions for any of them, or move drafts toward
  02-ready-to-publish?



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

1. Full markdown tutorial
  Saved to:
  01-projects/qadrlabs/post/01-draft/testing-time-dependent-code-in-laravel-with
  -pest-travel-freezetime-and-date-assertions.md

  Structure: PAS opening → Overview (Build / Learn / Need) → Step 1–7
  (sequential, runnable, with real output) → three conceptual sections without
  "Step" labels (helper comparison, closure auto-reset, timezone pitfalls) →
  Conclusion with bold-led bullets. No em/en dashes, no --- separators, every H2
  anchored, Laravel 13 conventions (#[Fillable], casts() method, --pest
  --no-boost).

  2. Article title

  ▎ Testing Time-Dependent Code in Laravel with Pest: travel(), freezeTime, and 
  ▎ Date Assertions

  3. Short description (155 characters)
 Stop flaky time-based tests in Laravel 13. Use Pest freezeTime(), travel() and travelTo() with date assertions to test trials, expiry, and token lifetimes.

  4. Category and tags
  - Category: Laravel / Testing
  - Tags: laravel, pest, testing, time-travel, freezetime, carbon, laravel-13,
  flaky-tests
  
  Notes:
  - The demo is a lean single Subscription model with onTrial(), trialExpired(),
  daysLeftOnTrial(), isActive(), exactly the scope you chose, and it opens
  flaky-first per your second choice.
  - I taught both freezeTime() (stop the clock) and freezeSecond()
  (start-of-second, which makes strict equalTo() pass against the DB's
  one-second precision), which turned out to be the cleanest honest explanation
  for the microsecond failure.
  - No Blade views are created (testing-focused), so the footer rule does not
  apply here.
