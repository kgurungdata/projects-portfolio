-- ============================================================
-- Delta Flight On-Time Performance Analysis
-- Practice SQL project modeled on airline operational reporting.
-- Data is simulated for practice purposes only.
-- Tables: flights (raw flight records), airports (lookup table)
-- ============================================================

-- 1. Total flights, cancellations, and overall cancellation rate
SELECT
    COUNT(*) AS total_flights,
    SUM(CASE WHEN cancelled = 'Y' THEN 1 ELSE 0 END) AS cancelled_flights,
    ROUND(100.0 * SUM(CASE WHEN cancelled = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS cancellation_rate_pct
FROM flights;

-- 2. On-time performance by route (JOIN to airports for readable city names)
SELECT
    o.city || ' (' || f.origin || ')' AS origin_city,
    d.city || ' (' || f.destination || ')' AS destination_city,
    COUNT(*) AS total_flights,
    SUM(CASE WHEN f.delay_minutes > 0 THEN 1 ELSE 0 END) AS delayed_flights,
    ROUND(100.0 * SUM(CASE WHEN f.delay_minutes > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS delay_rate_pct,
    ROUND(AVG(f.delay_minutes), 1) AS avg_delay_minutes
FROM flights f
JOIN airports o ON f.origin = o.airport_code
JOIN airports d ON f.destination = d.airport_code
GROUP BY f.origin, f.destination
ORDER BY delay_rate_pct DESC;

-- 3. Delay reason breakdown (excludes on-time and cancelled flights)
SELECT
    delay_reason,
    COUNT(*) AS num_flights,
    ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM flights WHERE delay_minutes > 0), 1) AS pct_of_delays
FROM flights
WHERE delay_minutes > 0
GROUP BY delay_reason
ORDER BY num_flights DESC;

-- 4. Monthly delay trend
SELECT
    substr(flight_date, 1, 7) AS month,
    COUNT(*) AS total_flights,
    ROUND(100.0 * SUM(CASE WHEN delay_minutes > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS delay_rate_pct,
    ROUND(AVG(CASE WHEN delay_minutes > 0 THEN delay_minutes END), 1) AS avg_delay_when_delayed
FROM flights
GROUP BY month
ORDER BY month;

-- 5. Delay severity categories using CASE
SELECT
    CASE
        WHEN delay_minutes = 0 THEN 'On Time'
        WHEN delay_minutes <= 30 THEN 'Minor Delay (<=30 min)'
        WHEN delay_minutes <= 60 THEN 'Moderate Delay (31-60 min)'
        ELSE 'Major Delay (60+ min)'
    END AS delay_category,
    COUNT(*) AS num_flights,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM flights), 1) AS pct_of_all_flights
FROM flights
GROUP BY delay_category
ORDER BY num_flights DESC;

-- 6. Regional performance (JOIN + GROUP BY on destination region)
SELECT
    d.region AS destination_region,
    COUNT(*) AS total_flights,
    ROUND(AVG(f.passengers), 0) AS avg_passengers,
    ROUND(100.0 * SUM(CASE WHEN f.delay_minutes > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS delay_rate_pct
FROM flights f
JOIN airports d ON f.destination = d.airport_code
GROUP BY d.region
ORDER BY delay_rate_pct DESC;

-- 7. Ranking routes by average delay using a window function
SELECT
    origin,
    destination,
    ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes,
    RANK() OVER (ORDER BY AVG(delay_minutes) DESC) AS delay_rank
FROM flights
GROUP BY origin, destination
ORDER BY delay_rank;

-- 8. Aircraft type reliability comparison
SELECT
    aircraft_type,
    COUNT(*) AS total_flights,
    ROUND(100.0 * SUM(CASE WHEN delay_minutes > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS delay_rate_pct,
    SUM(CASE WHEN cancelled = 'Y' THEN 1 ELSE 0 END) AS cancellations
FROM flights
GROUP BY aircraft_type
ORDER BY delay_rate_pct DESC;
