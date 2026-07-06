-- Q1: Price range and trading days per stock
SELECT
  Ticker,
  ROUND(MIN(Close), 2) AS min_price,
  ROUND(MAX(Close), 2) AS max_price,
  COUNT(*) AS trading_days
FROM stock_data
GROUP BY Ticker
ORDER BY max_price DESC;


-- Q2: Average daily return and best/worst day by stock
SELECT
  Ticker,
  ROUND(AVG(Daily_Return) * 100, 4) AS avg_daily_return_pct,
  ROUND(MIN(Daily_Return) * 100, 2) AS worst_day_pct,
  ROUND(MAX(Daily_Return) * 100, 2) AS best_day_pct
FROM stock_data
WHERE Daily_Return IS NOT NULL
GROUP BY Ticker
ORDER BY avg_daily_return_pct DESC;


-- Q3: Monthly average return by stock
SELECT
  Ticker,
  SUBSTR(Date, 1, 7) AS month,
  ROUND(AVG(Daily_Return) * 100, 3) AS avg_monthly_return_pct,
  COUNT(*) AS trading_days
FROM stock_data
WHERE Daily_Return IS NOT NULL
GROUP BY Ticker, month
ORDER BY Ticker, month;


-- Q4: Best and worst performing month per stock (window function)
WITH monthly_returns AS (
  SELECT
    Ticker,
    SUBSTR(Date, 1, 7) AS month,
    ROUND(AVG(Daily_Return) * 100, 3) AS avg_monthly_return_pct
  FROM stock_data
  WHERE Daily_Return IS NOT NULL
  GROUP BY Ticker, month
),
ranked AS (
  SELECT *,
    RANK() OVER (PARTITION BY Ticker ORDER BY avg_monthly_return_pct DESC) AS best_rank,
    RANK() OVER (PARTITION BY Ticker ORDER BY avg_monthly_return_pct ASC) AS worst_rank
  FROM monthly_returns
)
SELECT Ticker, month, avg_monthly_return_pct,
  CASE WHEN best_rank = 1 THEN 'Best Month'
       WHEN worst_rank = 1 THEN 'Worst Month'
  END AS label
FROM ranked
WHERE best_rank = 1 OR worst_rank = 1
ORDER BY Ticker, label;


-- Q5: Return range as a simple volatility proxy
SELECT
  Ticker,
  ROUND(AVG(Daily_Return) * 100, 4) AS avg_return_pct,
  ROUND(MIN(Daily_Return) * 100, 2) AS worst_day_pct,
  ROUND(MAX(Daily_Return) * 100, 2) AS best_day_pct,
  ROUND((MAX(Daily_Return) - MIN(Daily_Return)) * 100, 2) AS return_range_pct
FROM stock_data
WHERE Daily_Return IS NOT NULL
GROUP BY Ticker
ORDER BY return_range_pct DESC;


-- Q6: Months where two stocks both rallied together (self-join)
WITH monthly_returns AS (
  SELECT
    Ticker,
    SUBSTR(Date, 1, 7) AS month,
    ROUND(AVG(Daily_Return) * 100, 3) AS avg_monthly_return_pct
  FROM stock_data
  WHERE Daily_Return IS NOT NULL
  GROUP BY Ticker, month
)
SELECT
  a.month,
  a.Ticker AS stock_a,
  a.avg_monthly_return_pct AS return_a,
  b.Ticker AS stock_b,
  b.avg_monthly_return_pct AS return_b
FROM monthly_returns a
JOIN monthly_returns b
  ON a.month = b.month
  AND a.Ticker < b.Ticker
WHERE a.avg_monthly_return_pct > 5
  AND b.avg_monthly_return_pct > 5
ORDER BY a.month;