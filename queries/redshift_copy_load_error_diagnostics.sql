-- Purpose: Diagnose recent Amazon Redshift COPY load failures.
-- Scope: Current database session/cluster visibility depends on system-view permissions.
-- Review the table and time filters before using in a production environment.

SELECT
    starttime,
    filename,
    line_number,
    colname,
    err_code,
    err_reason,
    raw_line,
    raw_field_value
FROM stl_load_errors
WHERE starttime >= DATEADD(day, -1, GETDATE())
ORDER BY starttime DESC
LIMIT 200;

-- Optional summary: identify recurring error types and affected files.
SELECT
    err_code,
    err_reason,
    COUNT(*) AS error_count,
    COUNT(DISTINCT filename) AS affected_file_count,
    MAX(starttime) AS latest_error_time
FROM stl_load_errors
WHERE starttime >= DATEADD(day, -1, GETDATE())
GROUP BY err_code, err_reason
ORDER BY error_count DESC, latest_error_time DESC;

-- Troubleshooting checklist:
-- 1. Check filename and line_number to locate the rejected input record.
-- 2. Compare raw_field_value with the target column type, length and format.
-- 3. Validate delimiter, quote, escape, encoding and timestamp formats in COPY options.
-- 4. Check whether the source file schema changed unexpectedly.
-- 5. Correct the source or load mapping, then rerun only after confirming idempotency.
-- 6. Record the COPY query/load identifier, root cause and recovery evidence.
--
-- Note: STL_LOAD_ERRORS is a provisioned-cluster system table. For Redshift Serverless,
-- use the corresponding SYS_LOAD_ERROR_DETAIL view and adapt column names.
