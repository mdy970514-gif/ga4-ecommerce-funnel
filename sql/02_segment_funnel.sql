-- 6단계 퍼널을 신규(ga_session_number = 1)와 재방문(>= 2)으로 나눠 단계별 도달 유저 수를 센다.
-- 분석 단위: user_pseudo_id x 세그먼트 (같은 유저가 신규와 재방문 양쪽에 나타날 수 있음)
WITH events AS (
  SELECT
    user_pseudo_id,
    event_name,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') AS session_number
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),
flags AS (
  SELECT
    IF(session_number = 1, 'new', 'returning') AS segment,
    user_pseudo_id,
    LOGICAL_OR(event_name = 'session_start')    AS s1_session,
    LOGICAL_OR(event_name = 'view_item')        AS s2_view_item,
    LOGICAL_OR(event_name = 'add_to_cart')      AS s3_add_to_cart,
    LOGICAL_OR(event_name = 'begin_checkout')   AS s4_begin_checkout,
    LOGICAL_OR(event_name = 'add_payment_info') AS s5_add_payment_info,
    LOGICAL_OR(event_name = 'purchase')         AS s6_purchase
  FROM events
  WHERE session_number IS NOT NULL
  GROUP BY segment, user_pseudo_id
)
SELECT
  segment,
  COUNTIF(s1_session)          AS s1_session,
  COUNTIF(s2_view_item)        AS s2_view_item,
  COUNTIF(s3_add_to_cart)      AS s3_add_to_cart,
  COUNTIF(s4_begin_checkout)   AS s4_begin_checkout,
  COUNTIF(s5_add_payment_info) AS s5_add_payment_info,
  COUNTIF(s6_purchase)         AS s6_purchase
FROM flags
GROUP BY segment
ORDER BY segment
