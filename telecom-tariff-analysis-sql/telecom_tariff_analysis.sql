-- ============================================================
-- Telecom Tariff Analysis
-- PostgreSQL
-- ============================================================


-- ============================================================
-- 1. DATA QUALITY CHECKS
-- ============================================================

-- Preview customer data
SELECT *
FROM telecom.users
LIMIT 20;


-- Check missing values in customer attributes
SELECT *
FROM telecom.users
WHERE age IS NULL
   OR city IS NULL
   OR first_name IS NULL
   OR last_name IS NULL
   OR reg_date IS NULL
   OR tariff IS NULL;


-- Share of active customers
SELECT
    1 - COUNT(churn_date)::real / COUNT(*) AS active_users_share
FROM telecom.users;


-- Check user_id uniqueness
SELECT
    user_id,
    COUNT(*) AS row_count
FROM telecom.users
GROUP BY user_id
HAVING COUNT(*) > 1;


-- Check missing values in call data
SELECT *
FROM telecom.calls
WHERE duration IS NULL
   OR call_date IS NULL;


-- Check minimum and maximum call duration
SELECT
    MIN(duration) AS min_duration,
    MAX(duration) AS max_duration
FROM telecom.calls;


-- Share of zero-duration calls
SELECT
    COUNT(*) FILTER (WHERE duration = 0)::real / COUNT(*) AS zero_duration_share
FROM telecom.calls;



-- ============================================================
-- 2. MONTHLY CUSTOMER ACTIVITY AND COSTS
-- ============================================================

CREATE OR REPLACE TEMP VIEW users_costs AS

WITH monthly_duration AS (
    SELECT
        user_id,
        DATE_TRUNC('month', call_date::timestamp)::date AS dt_month,
        CEIL(SUM(duration)) AS month_duration
    FROM telecom.calls
    GROUP BY
        user_id,
        DATE_TRUNC('month', call_date::timestamp)::date
),

monthly_internet AS (
    SELECT
        user_id,
        DATE_TRUNC('month', session_date::timestamp)::date AS dt_month,
        SUM(mb_used) AS month_mb_traffic
    FROM telecom.internet
    GROUP BY
        user_id,
        DATE_TRUNC('month', session_date::timestamp)::date
),

monthly_sms AS (
    SELECT
        user_id,
        DATE_TRUNC('month', message_date::timestamp)::date AS dt_month,
        COUNT(id) AS month_sms
    FROM telecom.messages
    GROUP BY
        user_id,
        DATE_TRUNC('month', message_date::timestamp)::date
),

user_activity_months AS (
    SELECT user_id, dt_month
    FROM monthly_duration

    UNION

    SELECT user_id, dt_month
    FROM monthly_internet

    UNION

    SELECT user_id, dt_month
    FROM monthly_sms
),

users_stat AS (
    SELECT
        u.user_id,
        u.dt_month,
        COALESCE(md.month_duration, 0) AS month_duration,
        COALESCE(mi.month_mb_traffic, 0) AS month_mb_traffic,
        COALESCE(ms.month_sms, 0) AS month_sms
    FROM user_activity_months AS u
    LEFT JOIN monthly_duration AS md
        ON u.user_id = md.user_id
       AND u.dt_month = md.dt_month
    LEFT JOIN monthly_internet AS mi
        ON u.user_id = mi.user_id
       AND u.dt_month = mi.dt_month
    LEFT JOIN monthly_sms AS ms
        ON u.user_id = ms.user_id
       AND u.dt_month = ms.dt_month
),

user_over_limits AS (
    SELECT
        us.user_id,
        us.dt_month,
        u.tariff,
        us.month_duration,
        us.month_mb_traffic,
        us.month_sms,
        t.rub_monthly_fee,
        t.rub_per_minute,
        t.rub_per_gb,
        t.rub_per_message,

        CASE
            WHEN us.month_duration >= t.minutes_included
                THEN us.month_duration - t.minutes_included
            ELSE 0
        END AS duration_over,

        CASE
            WHEN us.month_mb_traffic >= t.mb_per_month_included
                THEN (us.month_mb_traffic - t.mb_per_month_included) / 1024::real
            ELSE 0
        END AS gb_traffic_over,

        CASE
            WHEN us.month_sms >= t.messages_included
                THEN us.month_sms - t.messages_included
            ELSE 0
        END AS sms_over

    FROM users_stat AS us
    LEFT JOIN telecom.users AS u
        ON us.user_id = u.user_id
    LEFT JOIN telecom.tariffs AS t
        ON u.tariff = t.tariff_name
)

SELECT
    user_id,
    dt_month,
    tariff,
    month_duration,
    month_mb_traffic,
    month_sms,
    rub_monthly_fee,
    rub_monthly_fee
        + duration_over * rub_per_minute
        + gb_traffic_over * rub_per_gb
        + sms_over * rub_per_message AS total_monthly_cost
FROM user_over_limits;



-- ============================================================
-- 3. ANALYSIS
-- ============================================================


-- 3.1 Monthly customer usage and spending
SELECT *
FROM users_costs
ORDER BY user_id, dt_month;


-- 3.2 Active customers and average monthly spending by tariff
SELECT
    uc.tariff,
    COUNT(DISTINCT uc.user_id) AS active_users,
    ROUND(AVG(uc.total_monthly_cost)::numeric, 2) AS avg_monthly_cost
FROM users_costs AS uc
JOIN telecom.users AS u
    ON uc.user_id = u.user_id
WHERE u.churn_date IS NULL
GROUP BY uc.tariff
ORDER BY uc.tariff;


-- 3.3 Active customers with spending above the monthly tariff fee
SELECT
    uc.tariff,
    COUNT(DISTINCT uc.user_id) AS over_limit_users,
    ROUND(AVG(uc.total_monthly_cost)::numeric, 2) AS avg_monthly_cost,
    ROUND(
        AVG(uc.total_monthly_cost - uc.rub_monthly_fee)::numeric,
        2
    ) AS avg_overpayment
FROM users_costs AS uc
JOIN telecom.users AS u
    ON uc.user_id = u.user_id
WHERE u.churn_date IS NULL
  AND uc.total_monthly_cost > uc.rub_monthly_fee
GROUP BY uc.tariff
ORDER BY uc.tariff;
