--   12 total SQL queries
--   Joins: Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11, Q12
--   Window functions: Q6, Q7, Q8, Q12
--   Group By: Q2, Q3, Q5, Q8, Q9, Q10, Q11, Q12
--   Subqueries: Q9, Q10, Q11

-- Q1: Check the current air-quality table row count and AQI range.
-- Why we ran this: Confirms the current AQI dataset loaded correctly and gives a quick validity check.
SELECT
    COUNT(*) AS city_count,
    MIN(current_aqius) AS min_current_aqi,
    MAX(current_aqius) AS max_current_aqi,
    AVG(current_aqius) AS avg_current_aqi
FROM current_aq;

-- Q2: Count cities by current AQI category.
-- Why we ran this: Helps translate the numeric AQI values into categories relevant for a non-technical audience.
SELECT
    current_aqi_category,
    COUNT(*) AS city_count,
    AVG(current_aqius) AS avg_current_aqi
FROM current_aq
GROUP BY current_aqi_category
ORDER BY avg_current_aqi DESC;

-- Q3: Summarize long-run weather risk by city.
-- Why we ran this: Identifies cities with the highest historical heat exposure and precipitation patterns.
SELECT
    city,
    country,
    AVG(temperature_2m_max) AS avg_max_temp_c,
    MAX(temperature_2m_max) AS hottest_day_c,
    AVG(CASE WHEN hot_day = 1 THEN 1.0 ELSE 0.0 END) AS hot_day_share,
    AVG(CASE WHEN very_hot_day = 1 THEN 1.0 ELSE 0.0 END) AS very_hot_day_share,
    AVG(CASE WHEN rainy_day = 1 THEN 1.0 ELSE 0.0 END) AS rainy_day_share,
    AVG(precipitation_sum) AS avg_daily_precipitation
FROM daily_weather
GROUP BY city, country
ORDER BY hot_day_share DESC;

-- Q4: Join current AQI to long-run weather summary.
-- Why we ran this: Creates the combined view used to compare short-term air quality and long-term heat exposure.
SELECT
    aq.city,
    aq.country,
    aq.current_aqius,
    aq.current_aqi_category,
    w.avg_max_temp_c,
    w.hot_day_share,
    w.very_hot_day_share
FROM current_aq AS aq
JOIN (
    SELECT
        city,
        country,
        AVG(temperature_2m_max) AS avg_max_temp_c,
        AVG(CASE WHEN hot_day = 1 THEN 1.0 ELSE 0.0 END) AS hot_day_share,
        AVG(CASE WHEN very_hot_day = 1 THEN 1.0 ELSE 0.0 END) AS very_hot_day_share
    FROM daily_weather
    GROUP BY city, country
) AS w
    ON aq.city = w.city AND aq.country = w.country
ORDER BY aq.current_aqius DESC;

-- Q5: Join city context to weather to compare heat exposure by region and coastal status.
-- Why we ran this: Adds a second analytical lens beyond city-by-city comparisons.
SELECT
    c.region,
    c.coastal_city,
    COUNT(DISTINCT w.city) AS cities,
    AVG(CASE WHEN w.hot_day = 1 THEN 1.0 ELSE 0.0 END) AS avg_hot_day_share,
    AVG(w.temperature_2m_max) AS avg_max_temp_c
FROM daily_weather AS w
JOIN city_context AS c
    ON w.city = c.city AND w.country = c.country
GROUP BY c.region, c.coastal_city
ORDER BY avg_hot_day_share DESC;

-- Q6: Window function ranking cities by current AQI.
-- Why we ran this: Makes it easy to identify the highest- and lowest-current AQI cities in one query.
SELECT
    aq.city,
    aq.country,
    aq.current_aqius,
    aq.current_aqi_category,
    RANK() OVER (ORDER BY aq.current_aqius DESC) AS current_aqi_rank_desc,
    RANK() OVER (ORDER BY aq.current_aqius ASC) AS current_aqi_rank_asc
FROM current_aq AS aq
ORDER BY current_aqi_rank_desc;

-- Q7: Window function calculating annual hot-day rank within each year.
-- Why we ran this: Shows which city had the most hot days in each year and supports trend discussion.
SELECT
    city,
    country,
    year,
    hot_days,
    RANK() OVER (PARTITION BY year ORDER BY hot_days DESC) AS annual_hot_day_rank
FROM (
    SELECT
        city,
        country,
        year,
        SUM(hot_day) AS hot_days
    FROM daily_weather
    GROUP BY city, country, year
) AS annual
ORDER BY year, annual_hot_day_rank;

-- Q8: Window function comparing annual hot days to each city's own long-run average.
-- Why we ran this: Highlights unusually hot years within each city, not just differences between cities.
SELECT
    city,
    country,
    year,
    hot_days,
    AVG(hot_days) OVER (PARTITION BY city) AS city_avg_hot_days,
    hot_days - AVG(hot_days) OVER (PARTITION BY city) AS hot_days_above_city_average
FROM (
    SELECT
        city,
        country,
        year,
        SUM(hot_day) AS hot_days
    FROM daily_weather
    GROUP BY city, country, year
) AS annual
ORDER BY hot_days_above_city_average DESC;

-- Q9: Subquery finding cities with above-average current AQI.
-- Why we ran this: Flags cities whose current air quality is worse than the sample average.
SELECT
    city,
    country,
    current_aqius,
    current_aqi_category
FROM current_aq
WHERE current_aqius > (
    SELECT AVG(current_aqius)
    FROM current_aq
)
ORDER BY current_aqius DESC;

-- Q10: Subquery finding cities with above-average long-run hot-day exposure.
-- Why we ran this: Flags cities with unusually high heat exposure relative to this city sample.
SELECT
    city,
    country,
    hot_day_share
FROM (
    SELECT
        city,
        country,
        AVG(CASE WHEN hot_day = 1 THEN 1.0 ELSE 0.0 END) AS hot_day_share
    FROM daily_weather
    GROUP BY city, country
) AS city_heat
WHERE hot_day_share > (
    SELECT AVG(city_hot_share)
    FROM (
        SELECT
            city,
            AVG(CASE WHEN hot_day = 1 THEN 1.0 ELSE 0.0 END) AS city_hot_share
        FROM daily_weather
        GROUP BY city
    ) AS all_city_heat
)
ORDER BY hot_day_share DESC;

-- Q11: Join plus subquery to identify cities with both above-average AQI and above-average heat.
-- Why we ran this: This is the most decision-relevant SQL query for the health-risk target audience.
SELECT
    aq.city,
    aq.country,
    aq.current_aqius,
    heat.hot_day_share,
    c.region,
    c.coastal_city
FROM current_aq AS aq
JOIN (
    SELECT
        city,
        country,
        AVG(CASE WHEN hot_day = 1 THEN 1.0 ELSE 0.0 END) AS hot_day_share
    FROM daily_weather
    GROUP BY city, country
) AS heat
    ON aq.city = heat.city AND aq.country = heat.country
JOIN city_context AS c
    ON aq.city = c.city AND aq.country = c.country
WHERE aq.current_aqius > (SELECT AVG(current_aqius) FROM current_aq)
  AND heat.hot_day_share > (
      SELECT AVG(city_hot_share)
      FROM (
          SELECT city, AVG(CASE WHEN hot_day = 1 THEN 1.0 ELSE 0.0 END) AS city_hot_share
          FROM daily_weather
          GROUP BY city
      ) AS avg_heat
  )
ORDER BY aq.current_aqius DESC;

-- Q12: Annual trend table with moving average of hot days by city.
-- Why we ran this: Supports discussion of whether hot days are becoming more common over time.
SELECT
    city,
    country,
    year,
    hot_days,
    AVG(hot_days) OVER (
        PARTITION BY city
        ORDER BY year
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS trailing_3yr_avg_hot_days
FROM (
    SELECT
        city,
        country,
        year,
        SUM(hot_day) AS hot_days
    FROM daily_weather
    GROUP BY city, country, year
) AS annual
ORDER BY city, year;
