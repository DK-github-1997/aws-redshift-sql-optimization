CREATE TABLE customers (
    customer_id INT,
    customer_name VARCHAR(100),
    region VARCHAR(50)
)
DISTSTYLE ALL;

CREATE TABLE sales (
    sale_id INT,
    customer_id INT,
    amount DECIMAL(10,2),
    sale_date DATE
)
DISTKEY(customer_id)
SORTKEY(sale_date);
