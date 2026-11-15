-- 공통 기반: 2020-11-01 ~ 2021-01-31 GA4 이벤트에서 분석에 필요한 필드만 꺼낸다.
-- event_params 배열은 필요한 키(ga_session_number)만 서브쿼리로 UNNEST 한다.
-- (event_params와 items를 한 쿼리에서 동시에 UNNEST하면 CROSS JOIN처럼 행이 불어나므로 피한다.)
SELECT
  user_pseudo_id,
  event_name,
  traffic_source.medium AS medium,
  (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') AS session_number,
  ecommerce.purchase_revenue_in_usd AS revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
