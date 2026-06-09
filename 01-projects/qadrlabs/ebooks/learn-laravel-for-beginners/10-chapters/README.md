<!--
Chapter assembly manifest. Internal working file, not part of the ebook.
-->

# Chapters: Assembly Manifest

The twelve teaching chapters are adapted from the existing qadrlabs course. To keep a single source of truth and avoid drift, the chapter **body** is not duplicated here. Instead, each chapter is assembled at build time from two pieces:

1. The **lesson body** from the published course (the source of truth for the prose and code).
2. A **chapter addendum** in this folder, which holds the ebook-only additions: a Key Takeaways box, a Checkpoint, and Exercises.

When the book is converted to PDF/EPUB, each chapter file is produced by concatenating the lesson body followed by its addendum.

## Mapping {#mapping}

| Ch | Title | Source lesson | Addendum |
|----|-------|---------------|----------|
| 1 | What We Will Build | `module-1.../lesson-1-what-we-will-build-4.md` | `part-1-getting-to-know-catatku/ch01-addendum.md` |
| 2 | Setting Up Your Laravel Project | `module-1.../lesson-2-setting-up-your-laravel-project.md` | `part-1-getting-to-know-catatku/ch02-addendum.md` |
| 3 | Your First Route and View | `module-2.../lesson-3-your-first-route-and-view-1.md` | `part-2-laravel-foundations/ch03-addendum.md` |
| 4 | What is MVC? | `module-2.../lesson-4-what-is-mvc-1.md` | `part-2-laravel-foundations/ch04-addendum.md` |
| 5 | Working with the Database | `module-3.../lesson-5-working-with-the-database-1.md` | `part-3-database-and-model/ch05-addendum.md` |
| 6 | Your First Model | `module-3.../lesson-6-your-first-model-1.md` | `part-3-database-and-model/ch06-addendum.md` |
| 7 | Displaying Entries List and Detail | `module-4.../lesson-7-displaying-entries-list-and-detail-1.md` | `part-4-core-features/ch07-addendum.md` |
| 8 | Writing and Saving Entries | `module-4.../lesson-8-writing-and-saving-entries-1.md` | `part-4-core-features/ch08-addendum.md` |
| 9 | Edit and Delete Entries | `module-4.../lesson-9-edit-and-delete-entries-1.md` | `part-4-core-features/ch09-addendum.md` |
| 10 | Basic Authentication: Registration | `module-5.../lesson-10-basic-authentication-registration-1.md` | `part-5-user-authentication/ch10-addendum.md` |
| 11 | Basic Authentication: Login and Logout | `module-5.../lesson-11-basic-authentication-login-and-logout-1.md` | `part-5-user-authentication/ch11-addendum.md` |
| 12 | What's Next | `module-6.../lesson-12-whats-next-1.md` | `part-6-whats-next/ch12-addendum.md` |

Source lessons live under `../../courses/learn-laravel-for-beginners/`.

## Notes for the Build {#notes-for-the-build}

- Chapters 1-11 each add Key Takeaways, Checkpoint, and Exercises.
- Chapter 12 is already a reflection chapter, so its addendum adds Key Takeaways only.
- Exercise solutions for every chapter are collected in `../90-back-matter/20-exercise-solutions.md`.
- Before building, apply the style fixes noted in the course `course-review-notes.md` (remove em dashes, emoji, and `---` separators; add anchors) to the lesson bodies so the book is consistent.
