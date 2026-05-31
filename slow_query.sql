SELECT c.customer_name, SUM(s.amount)
FROM sales s
JOIN customers c
ON s.customer_id = c.customer_id
WHERE DATE_PART(year, s.sale_date) = 2023
GROUP BY c.customer_name;
