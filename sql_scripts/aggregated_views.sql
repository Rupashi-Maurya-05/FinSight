-- 1. Monthly spend trends (for time-series charts)
CREATE VIEW agg_monthly_trends AS
SELECT
    DATE_TRUNC('month', transaction_date) AS month,
    COUNT(*) AS txn_count,
    ROUND(SUM(amount_clean), 2) AS total_amount,
    ROUND(AVG(amount_clean), 2) AS avg_amount,
    SUM(CASE WHEN f.is_fraud = 'Yes' THEN 1 ELSE 0 END) AS fraud_count,
    COUNT(f.transaction_id) AS labeled_count
FROM transactions_data t
LEFT JOIN fraud_labels f ON t.id = f.transaction_id
GROUP BY month
ORDER BY month;

-- 2. Spend and fraud by card type
CREATE VIEW agg_card_type AS
SELECT
    c.card_type,
    c.card_brand,
    COUNT(t.id) AS txn_count,
    ROUND(SUM(t.amount_clean), 2) AS total_spend,
    SUM(CASE WHEN f.is_fraud = 'Yes' THEN 1 ELSE 0 END) AS fraud_count,
    ROUND(100.0 * SUM(CASE WHEN f.is_fraud = 'Yes' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(f.transaction_id), 0), 3) AS fraud_rate_pct
FROM transactions_data t
JOIN cards_data c ON t.card_id = c.id
LEFT JOIN fraud_labels f ON t.id = f.transaction_id
GROUP BY c.card_type, c.card_brand;

-- 3. Spend and fraud by US state (for map visual in Power BI)
CREATE VIEW agg_state AS
SELECT
    merchant_state,
    COUNT(*) AS txn_count,
    ROUND(SUM(amount_clean), 2) AS total_amount,
    SUM(CASE WHEN f.is_fraud = 'Yes' THEN 1 ELSE 0 END) AS fraud_count,
    ROUND(100.0 * SUM(CASE WHEN f.is_fraud = 'Yes' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(f.transaction_id), 0), 3) AS fraud_rate_pct
FROM transactions_data t
LEFT JOIN fraud_labels f ON t.id = f.transaction_id
WHERE merchant_state NOT IN ('', 'ONLINE')
GROUP BY merchant_state;

-- 4. Single-row KPI summary
CREATE VIEW kpi_summary AS
SELECT
    COUNT(*) AS total_transactions,
    ROUND(SUM(t.amount_clean), 2) AS total_revenue,
    COUNT(DISTINCT t.client_id) AS total_customers,
    ROUND(100.0 * SUM(CASE WHEN f.is_fraud = 'Yes' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(f.transaction_id), 0), 3) AS fraud_rate_pct,
    COUNT(DISTINCT t.merchant_id) AS total_merchants,
    SUM(CASE WHEN f.is_fraud = 'Yes' THEN 1 ELSE 0 END) AS total_fraud_count
FROM transactions_data t
LEFT JOIN fraud_labels f ON t.id = f.transaction_id;


SELECT * FROM agg_monthly_trends LIMIT 5;
SELECT * FROM agg_card_type;
SELECT * FROM agg_state ORDER BY total_amount DESC LIMIT 10;
SELECT * FROM kpi_summary;


-- Check what raw dates look like
SELECT date FROM transactions_data LIMIT 5;

-- If dates look like '2010-01-01' in raw data, check transaction_date
SELECT transaction_date FROM transactions_data LIMIT 5;

SELECT * FROM agg_monthly_trends;
-- save as: agg_monthly_trends.csv

SELECT * FROM agg_card_type;
-- save as: agg_card_type.csv

SELECT * FROM agg_state;
-- save as: agg_state.csv

SELECT * FROM kpi_summary;
-- save as: kpi_summary.csv
