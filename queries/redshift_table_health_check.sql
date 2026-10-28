-- Amazon Redshift table health review
-- Purpose: shortlist tables that may need statistics, sort-order, or distribution review.
-- Run with a role that can see the relevant rows in SVV_TABLE_INFO.
-- Thresholds below are investigation heuristics; tune them for workload and table size.

SELECT
    "schema" AS schema_name,
    "table"  AS table_name,
    size     AS size_mb,
    tbl_rows AS estimated_row_count,
    unsorted AS unsorted_pct,
    stats_off AS statistics_staleness_pct,
    skew_rows AS row_distribution_skew,
    CASE WHEN unsorted >= 20 THEN 'CHECK' ELSE 'OK' END AS sort_order_review,
    CASE WHEN stats_off >= 10 THEN 'CHECK' ELSE 'OK' END AS statistics_review,
    CASE WHEN skew_rows >= 4 THEN 'CHECK' ELSE 'OK' END AS distribution_review
FROM svv_table_info
WHERE size > 0
  AND (
      unsorted >= 20
      OR stats_off >= 10
      OR skew_rows >= 4
  )
ORDER BY
    size DESC,
    stats_off DESC,
    unsorted DESC;

-- How to use the results:
-- 1. Review large tables first; confirm whether they are used by important queries.
-- 2. For stale statistics, evaluate ANALYZE after validating load completion.
-- 3. For unsorted data, inspect sort-key design and query filters before considering VACUUM.
-- 4. For row skew, inspect the distribution key and join patterns before changing it.
-- 5. Compare query plans and runtime before/after any maintenance or design change.
-- Do not run VACUUM, ANALYZE, or alter distribution keys automatically from this report.
