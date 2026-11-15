-- 기간: 2020-11-11 ~ 2021-01-31. 11/1~11/10은 transaction_id가 단일값으로 기록된 측정 오류 구간이라 팀 정제 기준에 따라 제외한다.
-- 매출 임팩트 추정에 쓸 구매 1건당 평균 매출(USD), 신규/재방문 세그먼트별
WITH events AS (
  SELECT
    event_name,
    ecommerce.purchase_revenue_in_usd AS revenue,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') AS session_number
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201111' AND '20210131'
)
SELECT
  IF(session_number = 1, 'new', 'returning') AS segment,
  COUNT(*)      AS purchase_events,
  AVG(revenue)  AS avg_order_value_usd
FROM events
WHERE event_name = 'purchase' AND revenue > 0 AND session_number IS NOT NULL
GROUP BY segment
ORDER BY segment
