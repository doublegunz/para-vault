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



```
claude --resume 5d15eff2-4616-4d16-8a21-f10d258942df

```


resume claude
```
claude --resume 5345377f-4b60-4214-bb1c-915ad8989a38

```

