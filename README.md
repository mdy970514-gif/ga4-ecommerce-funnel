# GA4 이커머스 구매 퍼널 분석

Google Merchandise Store의 GA4 이벤트 로그로 **구매 전환이 어디서 막히는지** 찾은 분석입니다.

> INNER CIRCLE 9기 팀 프로젝트(2026.07)의 분석을 다시 구현한 저장소입니다. 원본 노트북을 보관하지 못해, 팀 최종 보고서에 정리된 분석 정의(퍼널 단계, 신규/재방문 구분, 채널 분류, 매출 추정 방식)를 기준으로 2026년 11월에 코드를 새로 작성했습니다. 수치는 이 저장소의 노트북을 실행한 결과를 기준으로 합니다.

## 분석 질문
1. **H1.** 전환율이 가장 낮은 광고 채널(CPC)은 채널 자체가 비효율적인가, 신규 유저 비중 때문인가?
2. **H3.** 신규와 재방문 유저는 6단계 퍼널의 어느 구간에서 가장 크게 차이 나는가?
3. 그 구간을 개선하면 추가 구매와 매출은 얼마나 늘어날 수 있는가?

## 데이터
- `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
- 기간: 2020-11-01 ~ 2021-01-31 (3개월)
- 구글이 공개한 비식별 샘플이라 개인정보 이슈가 없습니다.

## 방법
| 단계 | 내용 | 파일 |
|---|---|---|
| 정제 | `event_params` 배열에서 필요한 키만 서브쿼리로 UNNEST (`event_params`와 `items`를 동시에 UNNEST하면 행이 불어나므로 분리) | `sql/00_base_events.sql` |
| 규모 확인 | 이벤트별 건수와 유저 수 | `sql/01_event_counts.sql` |
| 퍼널 | 세션 → 상품 조회 → 장바구니 → 결제 진입 → 결제정보 입력 → 구매 완료, 신규(`ga_session_number = 1`)와 재방문(`>= 2`)으로 분리 | `sql/02_segment_funnel.sql` |
| 채널 | `traffic_source.medium` 기준 CPC, Organic, Direct, Referral의 전환율과 신규 비중 | `sql/03_channel_funnel.sql` |
| 검정 | 최대 격차 구간의 신규 vs 재방문 통과율 차이를 2-표본 비율검정 | `ga4_analysis.py` |
| 임팩트 | 신규 결제완료율을 재방문 수준까지 올렸을 때 추가 구매와 매출 추정 | `sql/04_order_value.sql`, `ga4_analysis.py` |

## 실행 방법
1. `ga4_funnel_analysis.ipynb`를 Google Colab에서 엽니다.
2. 첫 셀의 `PROJECT_ID`에 본인 Google Cloud 프로젝트 ID를 넣습니다. BigQuery 무료 샌드박스로 실행할 수 있습니다.
3. 모든 셀을 실행합니다.

## 한계
- 공개 샘플은 일부 필드가 비식별 처리돼 있어 광고비와 결제 화면(UX) 데이터가 없습니다. 그래서 ROI는 계산하지 않았고, 매출 추정은 결제 진입 유저 수가 그대로라는 가정의 상한값입니다.
- 신규/재방문 구분과 유저 단위 집계 방식에 따라 수치가 팀 보고서와 조금 다를 수 있습니다.

## 기술
BigQuery SQL (UNNEST, LOGICAL_OR, COUNTIF), Python (pandas, statsmodels, matplotlib), Google Colab
