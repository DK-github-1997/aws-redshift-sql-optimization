# Amazon Redshift distribution and sort key tuning

Distribution and sort keys solve different performance problems:

- **Distribution** decides where table rows are stored across compute slices. Good distribution can reduce data movement during joins.
- **Sort keys** determine the on-disk sort order. They can improve block pruning when queries filter or join on sorted columns.

## 1. Choose a distribution style

| Style | Typical use | Trade-off |
| --- | --- | --- |
| `AUTO` | Good default when workload patterns may change | Redshift can adjust the strategy as the table evolves |
| `KEY` | Large tables frequently joined on the same high-cardinality key | Can colocate matching rows, but a skewed key can create uneven slice workloads |
| `ALL` | Small, relatively static dimension tables joined frequently to large facts | Replicates the table to nodes, increasing storage and load/maintenance work |
| `EVEN` | Tables without a suitable join key or with no clear key-based access pattern | Spreads rows evenly, but does not colocate joins |

For the sample schema in `create_tables.sql`, `sales` and `customers` both use `customer_id` in the join. The current example uses `DISTKEY(customer_id)` on `sales` and `DISTSTYLE ALL` on the small customer table. This is an illustrative design, not a universal recommendation: validate dimension size, key skew, and actual join frequency before adopting it.

## 2. Choose a sort key

- **Compound sort key:** useful when queries commonly filter on the leading column, optionally followed by additional columns. Column order matters.
- **Interleaved sort key:** can help when several columns are filtered independently with similar importance, but has additional maintenance considerations. Evaluate it against the current workload rather than choosing it by default.
- **AUTO:** allow Redshift to manage sort-key selection when manual tuning is not justified.

Example for date-range reporting:

```sql
CREATE TABLE sales_by_date (
    sale_id      BIGINT,
    customer_id  BIGINT,
    sale_date    DATE,
    amount       DECIMAL(12,2)
)
DISTSTYLE KEY
DISTKEY(customer_id)
SORTKEY(sale_date);
```

A date-leading sort key can help queries such as:

```sql
SELECT customer_id, SUM(amount) AS total_amount
FROM sales_by_date
WHERE sale_date >= DATE '2026-01-01'
  AND sale_date <  DATE '2026-02-01'
GROUP BY customer_id;
```

## 3. Read redistribution indicators in EXPLAIN

Run `EXPLAIN` before executing a representative join and inspect the distribution annotation on the plan:

| Plan annotation | Interpretation | What to investigate |
| --- | --- | --- |
| `DS_DIST_NONE` | Rows are already colocated for the join | Usually a favorable sign; still review scan and join costs |
| `DS_BCAST_INNER` | Inner input is broadcast to the other nodes | Check whether the inner relation is genuinely small and filtered early |
| `DS_DIST_BOTH` | Both inputs are redistributed | Review join keys, distribution styles, and data skew |
| `DS_DIST_ALL_NONE` | Inner input is already available on all nodes | Often expected when joining to a table distributed with ALL |

A redistribution marker is a diagnostic clue, not proof that a query is slow. Compare the full plan, table sizes, runtime, queue time, and workload concurrency.

## 4. Practical tuning workflow

1. Select representative high-frequency and long-running joins from workload history.
2. Check table size, row skew, unsorted percentage, and statistics in `SVV_TABLE_INFO`.
3. Review join predicates and filter selectivity; avoid choosing a key from column names alone.
4. Capture the baseline `EXPLAIN` plan and query runtime.
5. Test one physical-design change at a time on representative data.
6. Compare runtime, data movement, skew, storage, and load/maintenance overhead.
7. Keep the change only when the workload-level trade-off improves.

**Interview point:** I would not say that a KEY distribution or a date sort key always makes a query faster. I would explain the join/filter pattern, inspect the plan for redistribution, measure the baseline, and validate the change against representative workloads.

This guide is a design reference. It has not been executed against a live Redshift cluster; confirm syntax and behavior in the target provisioned or Serverless environment before production use.
