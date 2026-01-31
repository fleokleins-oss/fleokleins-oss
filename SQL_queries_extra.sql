-- Extras: SQL Queries para Métricas de Produto e Qualidade de Dados

-- 1. Receita diária e média móvel de 7 dias
WITH revenue_daily AS (
    SELECT DATE(purchase_date) AS day, SUM(amount) AS revenue
    FROM purchases
    WHERE purchase_date >= CURRENT_DATE - INTERVAL '60 days'
    GROUP BY 1
)
SELECT
    day,
    revenue,
    AVG(revenue) OVER (ORDER BY day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS revenue_moving_avg_7d
FROM revenue_daily
ORDER BY day;

-- 2. Conversão de cadastro para compra (Signup → Purchase)
WITH signup AS (
    SELECT user_id, MIN(event_time) AS signup_time
    FROM events
    WHERE event_name = 'signup_completed'
    GROUP BY 1
),
first_purchase AS (
    SELECT user_id, MIN(event_time) AS purchase_time
    FROM events
    WHERE event_name = 'purchase'
    GROUP BY 1
)
SELECT
    COUNT(*) AS total_signups,
    COUNT(fp.user_id) AS converted_to_purchase,
    ROUND(100.0 * COUNT(fp.user_id) / COUNT(*), 2) AS conversion_rate_pct
FROM signup s
LEFT JOIN first_purchase fp ON s.user_id = fp.user_id;

-- 3. Detectar usuários com atividade irregular (churn risk)
SELECT
    user_id,
    MAX(event_time) AS last_activity,
    CURRENT_DATE - DATE(MAX(event_time)) AS days_since_last_activity
FROM events
GROUP BY 1
HAVING CURRENT_DATE - DATE(MAX(event_time)) > 30
ORDER BY days_since_last_activity DESC;

-- 4. Checar distribuição de valores de compra (quartis)
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY amount) AS q1,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY amount) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY amount) AS q3
FROM purchases
WHERE amount IS NOT NULL;

-- 5. Validar integridade referencial entre usuários e eventos
SELECT
    COUNT(*) AS total_events,
    COUNT(*) FILTER (WHERE u.user_id IS NULL) AS events_without_user
FROM events e
LEFT JOIN users u ON e.user_id = u.user_id;