-- Amazon Redshift: triage the 20 slowest queries started in the last 24 hours.
-- Source: SYS_QUERY_HISTORY. Elapsed, queue and execution times are in microseconds.
-- Read-only monitoring example; adjust the 60-second queue and 5-minute execution
-- thresholds to match the workload's service-level objectives.

WITH recent_queries AS (
    SELECT
        query_id,
        query_type,
        status,
        start_time,
        elapsed_time,
        queue_time,
        execution_time,
        result_cache_hit,
        returned_rows,
        returned_bytes
    FROM sys_query_history
    WHERE start_time >= DATEADD(hour, -24, GETDATE())
      AND query_id > 0
)
SELECT
    query_id,
    query_type,
    status,
    start_time,
    ROUND(elapsed_time / 1000000.0, 2) AS elapsed_seconds,
    ROUND(queue_time / 1000000.0, 2) AS queue_seconds,
    ROUND(execution_time / 1000000.0, 2) AS execution_seconds,
    ROUND(
        100.0 * queue_time / NULLIF(elapsed_time, 0),
        1
    ) AS queue_share_pct,
    result_cache_hit,
    returned_rows,
    returned_bytes,
    CASE
        WHEN status <> 'success' THEN 'INVESTIGATE QUERY STATUS'
        WHEN queue_time >= 60000000
         AND queue_time > execution_time THEN 'REVIEW WLM QUEUE'
        WHEN execution_time >= 300000000 THEN 'REVIEW EXECUTION PLAN'
        WHEN result_cache_hit THEN 'RESULT CACHE HIT'
        ELSE 'NO IMMEDIATE ALERT'
    END AS triage_hint
FROM recent_queries
ORDER BY elapsed_time DESC
LIMIT 20;

-- Follow-up:
-- 1. High queue time: inspect WLM queueing, concurrency and workload priorities.
-- 2. High execution time: inspect EXPLAIN and step-level metrics in SVL_QUERY_SUMMARY.
-- 3. Failed/cancelled status: review the query error and relevant load/application logs.
-- 4. A result-cache hit can hide the underlying execution cost; compare with a cache miss.
