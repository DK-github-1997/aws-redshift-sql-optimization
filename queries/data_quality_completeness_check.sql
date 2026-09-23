-- Redshift data-quality pattern: daily completeness check
-- Identifies expected business dates with no loaded rows.
-- Replace table and date column names with project-specific objects.

WITH calendar_dates AS (
    SELECT DATEADD(day, seq, DATE '2026-01-01')::date AS business_date
    FROM (
        SELECT ROW_NUMBER() OVER () - 1 AS seq
        FROM information_schema.columns
        LIMIT 365
    ) numbers
),
loaded_dates AS (
    SELECT business_date,
           COUNT(*) AS row_count
    FROM analytics.fact_transactions
    WHERE business_date BETWEEN DATE '2026-01-01' AND DATE '2026-12-31'
    GROUP BY business_date
)
SELECT c.business_date,
       COALESCE(l.row_count, 0) AS row_count,
       CASE
           WHEN COALESCE(l.row_count, 0) = 0 THEN 'FAIL'
           ELSE 'PASS'
       END AS completeness_status
FROM calendar_dates c
LEFT JOIN loaded_dates l
  ON l.business_date = c.business_date
ORDER BY c.business_date;
