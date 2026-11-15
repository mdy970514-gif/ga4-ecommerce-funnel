"""GA4 퍼널 분석 함수 모음. BigQuery 집계 결과(DataFrame)를 받아 지표를 계산한다."""
import pandas as pd
from statsmodels.stats.proportion import proportions_ztest

STEPS = ["s1_session", "s2_view_item", "s3_add_to_cart",
         "s4_begin_checkout", "s5_add_payment_info", "s6_purchase"]
STEP_LABELS = {"s1_session": "세션", "s2_view_item": "상품 조회", "s3_add_to_cart": "장바구니",
               "s4_begin_checkout": "결제 진입", "s5_add_payment_info": "결제정보 입력",
               "s6_purchase": "구매 완료"}


def step_pass_rates(seg: pd.DataFrame) -> pd.DataFrame:
    """세그먼트별 직전 단계 대비 통과율(%)과 재방문-신규 격차(%p)."""
    s = seg.set_index("segment")[STEPS]
    rows = []
    for prev, nxt in zip(STEPS[:-1], STEPS[1:]):
        r = {"구간": f"{STEP_LABELS[prev]} → {STEP_LABELS[nxt]}"}
        for g in s.index:
            r[g] = round(100 * s.loc[g, nxt] / s.loc[g, prev], 1) if s.loc[g, prev] else None
        rows.append(r)
    out = pd.DataFrame(rows)
    if {"new", "returning"} <= set(out.columns):
        out["격차(%p)"] = (out["returning"] - out["new"]).round(1)
    return out


def checkout_completion(seg: pd.DataFrame) -> pd.Series:
    """결제 진입 유저 중 구매 완료 비율(%)."""
    s = seg.set_index("segment")
    return (100 * s["s6_purchase"] / s["s4_begin_checkout"]).round(1)


def ztest_step(seg: pd.DataFrame, prev: str, nxt: str):
    """재방문 vs 신규의 특정 구간 통과율 차이에 대한 2-표본 비율검정."""
    s = seg.set_index("segment")
    counts = [s.loc["returning", nxt], s.loc["new", nxt]]
    nobs = [s.loc["returning", prev], s.loc["new", prev]]
    z, p = proportions_ztest(counts, nobs)
    return z, p


def channel_summary(ch: pd.DataFrame) -> pd.DataFrame:
    """채널별 구매 전환율, 신규 비중, 신규/재방문 전환율(%)."""
    t = ch.copy()
    t["구매전환율(%)"] = (100 * t.purchasers / t.users).round(2)
    t["신규비중(%)"] = (100 * t.new_users / t.users).round(1)
    t["신규 전환율(%)"] = (100 * t.new_purchasers / t.new_users).round(2)
    t["재방문 전환율(%)"] = (100 * t.returning_purchasers / t.returning_users).round(2)
    return t.sort_values("구매전환율(%)")


def impact_scenarios(seg: pd.DataFrame, aov_new: float) -> pd.DataFrame:
    """신규 결제완료율을 끌어올렸을 때의 추가 구매 건수와 매출(USD) 추정."""
    s = seg.set_index("segment")
    comp = checkout_completion(seg)
    base, target = comp["new"], comp["returning"]
    n_checkout = s.loc["new", "s4_begin_checkout"]
    rows = [("현재", base)]
    if base + 10 < target:
        rows.append(("+10%p 개선", base + 10))
    rows.append(("재방문 수준까지", target))
    out = []
    for name, rate in rows:
        extra = round(n_checkout * (rate - base) / 100)
        out.append({"시나리오": name, "신규 결제완료율(%)": round(rate, 1),
                    "추가 구매(건)": extra, "추가 매출(USD)": round(extra * aov_new)})
    return pd.DataFrame(out)
