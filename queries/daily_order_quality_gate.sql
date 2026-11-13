-- Amazon Redshift portfolio example: pre-load data quality gate for an order batch.
-- Assumed staging table/columns: stg_orders(load_batch_id, order_id, customer_id,
-- order_date, order_amount). Replace the batch placeholder before execution.
-- Read-only diagnostics: this query reports failures; it does not modify or reject data.

WITH batch_rows AS (
    SELECT order_id, customer_id, order_date, order_amount
    FROM stg_orders
    WHERE load_batch_id = 'REPLACE_WITH_BATCH_ID'
),
quality_checks AS (
    SELECT
        'NULL_ORDER_ID' AS check_name,
        COUNT(*) AS failed_rows,
        'BLOCKER' AS severity
    FROM batch_rows
    WHERE order_id IS NULL

    UNION ALL

    SELECT
        'DUPLICATE_ORDER_ID',
        COUNT(*),
        'BLOCKER'
    FROM (
        SELECT order_id
        FROM batch_rows
        WHERE order_id IS NOT NULL
        GROUP BY order_id
        HAVING COUNT(*) > 1
    ) duplicates

    UNION ALL

    SELECT
        'NULL_CUSTOMER_ID',
        COUNT(*),
        'BLOCKER'
    FROM batch_rows
    WHERE customer_id IS NULL

    UNION ALL

    SELECT
        'NULL_ORDER_DATE',
        COUNT(*),
        'BLOCKER'
    FROM batch_rows
    WHERE order_date IS NULL

    UNION ALL

    SELECT
        'NEGATIVE_ORDER_AMOUNT',
        COUNT(*),
        'REVIEW'
    FROM batch_rows
    WHERE order_amount < 0

    UNION ALL

    SELECT
        'FUTURE_ORDER_DATE',
        COUNT(*),
        'REVIEW'
    FROM batch_rows
    WHERE order_date > GETDATE()
)
SELECT
    check_name,
    failed_rows,
    severity,
    CASE
        WHEN failed_rows = 0 THEN 'PASS'
        WHEN severity = 'BLOCKER' THEN 'FAIL - HOLD BATCH'
        ELSE 'REVIEW BEFORE LOAD'
    END AS check_status
FROM quality_checks
ORDER BY
    CASE severity WHEN 'BLOCKER' THEN 1 ELSE 2 END,
    failed_rows DESC,
    check_name;

-- Operational use:
-- 1. Run after staging ingestion and before the target MERGE/INSERT.
-- 2. Treat any BLOCKER failure as a reason to hold the batch for investigation.
-- 3. Review business rules before rejecting negative amounts or future dates.
-- 4. Reconcile source, accepted, quarantined and rejected row counts by batch ID.
-- 5. Make the downstream load idempotent; this diagnostic query alone does not
--    prevent duplicate writes or replace a transactional/operational control.
