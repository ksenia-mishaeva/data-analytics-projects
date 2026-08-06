-- Data exploration and quality checks

-- List all tables in the fantasy schema
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'fantasy'
ORDER BY table_name;


-- Inspect the structure of the users table
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'fantasy'
  AND table_name = 'users'
ORDER BY ordinal_position;


-- Preview user data
SELECT *
FROM fantasy.users
LIMIT 5;


-- Count registered players
SELECT COUNT(*) AS registered_users
FROM fantasy.users;


-- Check player ID uniqueness
SELECT
    id,
    COUNT(*) AS row_count
FROM fantasy.users
GROUP BY id
HAVING COUNT(*) > 1;


-- Check missing values in key user attributes
SELECT
    COUNT(*) FILTER (WHERE class_id IS NULL) AS missing_class_id,
    COUNT(*) FILTER (WHERE ch_id IS NULL) AS missing_characteristic_id,
    COUNT(*) FILTER (WHERE pers_gender IS NULL) AS missing_gender,
    COUNT(*) FILTER (WHERE server IS NULL) AS missing_server,
    COUNT(*) FILTER (WHERE race_id IS NULL) AS missing_race_id,
    COUNT(*) FILTER (WHERE payer IS NULL) AS missing_payer,
    COUNT(*) FILTER (WHERE loc_id IS NULL) AS missing_location_id
FROM fantasy.users;


-- Player distribution across servers
SELECT
    server,
    COUNT(*) AS users
FROM fantasy.users
GROUP BY server
ORDER BY users DESC;


-- Inspect the structure of the events table
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'fantasy'
  AND table_name = 'events'
ORDER BY ordinal_position;


-- Preview transaction data
SELECT *
FROM fantasy.events
LIMIT 5;


-- Count transactions
SELECT COUNT(*) AS transactions
FROM fantasy.events;


-- Check missing values in key transaction fields
SELECT
    COUNT(*) FILTER (WHERE date IS NULL) AS missing_date,
    COUNT(*) FILTER (WHERE time IS NULL) AS missing_time,
    COUNT(*) FILTER (WHERE amount IS NULL) AS missing_amount,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS missing_seller_id
FROM fantasy.events;


-- Payer analysis

-- payer = 1 indicates that a player purchased premium currency
-- with real money; payer = 0 indicates that they did not

-- Overall payer share among registered players
SELECT
    COUNT(id) AS registered_users,
    SUM(payer) AS payers,
    ROUND(
        SUM(payer)::NUMERIC / COUNT(id),
        4
    ) AS payer_share
FROM fantasy.users;


-- Payer share by character race
SELECT
    r.race,
    COUNT(u.id) AS registered_users,
    SUM(u.payer) AS payers,
    ROUND(
        SUM(u.payer)::NUMERIC / COUNT(u.id),
        4
    ) AS payer_share
FROM fantasy.users AS u
JOIN fantasy.race AS r
    ON u.race_id = r.race_id
GROUP BY r.race
ORDER BY payer_share DESC;


-- In-game purchase analysis

-- The events table contains purchases of epic items made
-- with premium in-game currency

-- Purchase amount statistics
SELECT
    COUNT(*) AS total_purchases,
    SUM(amount) AS total_currency_spent,
    MIN(amount) AS min_purchase_amount,
    MAX(amount) AS max_purchase_amount,
    ROUND(AVG(amount)::NUMERIC, 2) AS avg_purchase_amount,
    PERCENTILE_DISC(0.5)
        WITHIN GROUP (ORDER BY amount) AS median_purchase_amount,
    ROUND(STDDEV(amount)::NUMERIC, 2) AS stddev_purchase_amount
FROM fantasy.events;


-- Number and share of zero-value transactions
SELECT
    COUNT(*) FILTER (WHERE amount = 0) AS zero_value_purchases,
    ROUND(
        COUNT(*) FILTER (WHERE amount = 0)::NUMERIC
        / COUNT(*),
        4
    ) AS zero_value_purchase_share
FROM fantasy.events;


-- Items associated with zero-value transactions
SELECT
    i.game_items,
    COUNT(*) AS zero_value_purchases
FROM fantasy.events AS e
JOIN fantasy.items AS i
    ON e.item_code = i.item_code
WHERE e.amount = 0
GROUP BY i.game_items
ORDER BY zero_value_purchases DESC;


-- Players with zero-value transactions
SELECT
    id AS player_id,
    COUNT(*) AS zero_value_purchases,
    MIN(date::DATE) AS first_zero_value_purchase,
    MAX(date::DATE) AS last_zero_value_purchase
FROM fantasy.events
WHERE amount = 0
GROUP BY id
ORDER BY zero_value_purchases DESC;


-- Payer vs non-payer purchase behavior

-- Compare players who purchased premium currency with real money
-- with players who did not
-- Zero-value transactions are excluded from purchase metrics
SELECT
    CASE
        WHEN u.payer = 1 THEN 'Payer'
        WHEN u.payer = 0 THEN 'Non-payer'
    END AS player_type,
    COUNT(DISTINCT e.id) AS buyers,
    ROUND(
        COUNT(*)::NUMERIC / COUNT(DISTINCT e.id),
        2
    ) AS avg_purchases_per_buyer,
    ROUND(
        SUM(e.amount)::NUMERIC / COUNT(DISTINCT e.id),
        2
    ) AS avg_total_currency_spent_per_buyer
FROM fantasy.events AS e
JOIN fantasy.users AS u
    ON e.id = u.id
WHERE e.amount != 0
GROUP BY player_type
ORDER BY player_type;


-- Item popularity

-- Compare epic items by share of purchases
-- and share of buyers who purchased each item
SELECT
    i.game_items,
    COUNT(*) AS purchases,
    ROUND(
        COUNT(*)::NUMERIC
        / (
            SELECT COUNT(*)
            FROM fantasy.events
            WHERE amount != 0
        ),
        4
    ) AS purchase_share,
    COUNT(DISTINCT e.id) AS buyers,
    ROUND(
        COUNT(DISTINCT e.id)::NUMERIC
        / (
            SELECT COUNT(DISTINCT id)
            FROM fantasy.events
            WHERE amount != 0
        ),
        4
    ) AS buyer_share
FROM fantasy.events AS e
JOIN fantasy.items AS i
    ON e.item_code = i.item_code
WHERE e.amount != 0
GROUP BY i.game_items
ORDER BY purchases DESC;


-- Identify items with very low purchase activity
SELECT
    i.game_items,
    COUNT(*) AS purchases
FROM fantasy.events AS e
JOIN fantasy.items AS i
    ON e.item_code = i.item_code
WHERE e.amount != 0
GROUP BY i.game_items
HAVING COUNT(*) < 10
ORDER BY purchases;


-- Purchase behavior by character race

-- Calculate purchase metrics for each registered player
WITH user_purchase_stats AS (
    SELECT
        u.id AS player_id,
        r.race AS race_name,
        u.payer AS payer_status,
        COUNT(e.transaction_id) AS purchases,
        COALESCE(SUM(e.amount), 0) AS total_currency_spent
    FROM fantasy.users AS u
    JOIN fantasy.race AS r
        ON u.race_id = r.race_id
    LEFT JOIN fantasy.events AS e
        ON u.id = e.id
        AND e.amount != 0
    GROUP BY
        u.id,
        r.race,
        u.payer
)

SELECT
    race_name,
    COUNT(player_id) AS registered_users,
    COUNT(
        CASE
            WHEN purchases > 0 THEN player_id
        END
    ) AS buyers,
    ROUND(
        COUNT(
            CASE
                WHEN purchases > 0 THEN player_id
            END
        )::NUMERIC
        / COUNT(player_id),
        3
    ) AS buyer_share,
    ROUND(
        SUM(
            CASE
                WHEN purchases > 0 THEN payer_status
            END
        )::NUMERIC
        / COUNT(
            CASE
                WHEN purchases > 0 THEN player_id
            END
        ),
        3
    ) AS payer_share_among_buyers,
    ROUND(
        SUM(total_currency_spent)::NUMERIC
        / NULLIF(
            COUNT(
                CASE
                    WHEN purchases > 0 THEN player_id
                END
            ),
            0
        ),
        2
    ) AS avg_total_currency_spent_per_buyer,
    ROUND(
        SUM(total_currency_spent)::NUMERIC
        / NULLIF(SUM(purchases), 0),
        2
    ) AS avg_purchase_amount,
    ROUND(
        SUM(purchases)::NUMERIC
        / NULLIF(
            COUNT(
                CASE
                    WHEN purchases > 0 THEN player_id
                END
            ),
            0
        ),
        2
    ) AS avg_purchases_per_buyer
FROM user_purchase_stats
GROUP BY race_name
ORDER BY race_name;


-- Purchase frequency segmentation

-- Calculate purchase frequency for players
-- with more than 25 non-zero purchases
WITH user_purchase_stats AS (
    SELECT
        e.id AS player_id,
        u.payer AS payer_status,
        COUNT(e.transaction_id) AS purchases,
        ROUND(
            (
                MAX(e.date::DATE) - MIN(e.date::DATE)
            )::NUMERIC
            / NULLIF(COUNT(e.transaction_id) - 1, 0),
            2
        ) AS avg_days_between_purchases
    FROM fantasy.events AS e
    JOIN fantasy.users AS u
        ON e.id = u.id
    WHERE e.amount != 0
    GROUP BY
        e.id,
        u.payer
    HAVING COUNT(e.transaction_id) > 25
),

frequency_groups AS (
    SELECT
        player_id,
        payer_status,
        purchases,
        avg_days_between_purchases,
        NTILE(3) OVER (
            ORDER BY avg_days_between_purchases
        ) AS frequency_group
    FROM user_purchase_stats
),

frequency_segments AS (
    SELECT
        player_id,
        payer_status,
        purchases,
        avg_days_between_purchases,
        frequency_group,
        CASE
            WHEN frequency_group = 1 THEN 'High frequency'
            WHEN frequency_group = 2 THEN 'Medium frequency'
            WHEN frequency_group = 3 THEN 'Low frequency'
        END AS frequency_segment
    FROM frequency_groups
)

SELECT
    frequency_segment,
    COUNT(player_id) AS players,
    SUM(payer_status) AS payers,
    ROUND(
        SUM(payer_status)::NUMERIC / COUNT(player_id),
        3
    ) AS payer_share,
    ROUND(
        AVG(purchases),
        2
    ) AS avg_purchases_per_player,
    ROUND(
        AVG(avg_days_between_purchases),
        2
    ) AS avg_days_between_purchases
FROM frequency_segments
GROUP BY
    frequency_group,
    frequency_segment
ORDER BY frequency_group;
