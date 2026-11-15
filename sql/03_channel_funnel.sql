-- 기간: 2020-11-11 ~ 2021-01-31. 11/1~11/10은 transaction_id가 단일값으로 기록된 측정 오류 구간이라 팀 정제 기준에 따라 제외한다.
-- 유입 채널(traffic_source.medium, 유저 최초 유입 기준)별 유저 수, 신규/재방문 구성, 구매 유저 수.
-- 신규 유저: 기간 내 최대 ga_session_number = 1 / 재방문 유저: >= 2
WITH events AS (
  SELECT
    user_pseudo_id,
    event_name,
    traffic_source.medium AS medium,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') AS session_number
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201111' AND '20210131'
),
users AS (
  SELECT
    user_pseudo_id,
    ANY_VALUE(medium)                    AS medium,
    MAX(session_number)                  AS max_session,
    LOGICAL_OR(event_name = 'purchase')  AS purchased
  FROM events
  GROUP BY user_pseudo_id
)
SELECT
  CASE medium
    WHEN 'cpc' THEN 'CPC'
    WHEN 'organic' THEN 'Organic'
    WHEN '(none)' THEN 'Direct'
    WHEN 'referral' THEN 'Referral'
  END AS channel,
  COUNT(*)                                  AS users,
  COUNTIF(max_session = 1)                  AS new_users,
  COUNTIF(max_session >= 2)                 AS returning_users,
  COUNTIF(purchased)                        AS purchasers,
  COUNTIF(max_session = 1 AND purchased)    AS new_purchasers,
  COUNTIF(max_session >= 2 AND purchased)   AS returning_purchasers
FROM users
WHERE medium IN ('cpc', 'organic', '(none)', 'referral')   -- '<Other>', '(data deleted)' 제외
GROUP BY channel
ORDER BY channel
