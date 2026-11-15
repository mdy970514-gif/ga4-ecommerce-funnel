-- 이벤트별 발생 건수와 유저 수 (데이터 규모 확인용)
WITH events AS (
  SELECT user_pseudo_id, event_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)
SELECT event_name, COUNT(*) AS events, COUNT(DISTINCT user_pseudo_id) AS users
FROM events
GROUP BY event_name
ORDER BY events DESC
