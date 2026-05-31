# aws-redshift-sql-optimization
Reduced Redshift query runtime from 30 mins to 2 mins in a production-like scenario
aws-redshift-sql-optimization/
│
├── README.md
├── datasets/
│   └── sales_data.csv
├── ddl/
│   └── create_tables.sql
├── queries/
│   ├── slow_query.sql
│   ├── optimized_query.sql
│   └── window_functions.sql
├── explain_plan/
│   └── explain_analysis.md
├── performance_tuning/
│   ├── dist_sort_keys.md
│   ├── vacuum_analyze.md
│   └── compression.md
└── real_scenarios/
    └── reduce_runtime_30min_to_2min.md
