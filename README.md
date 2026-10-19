# ALEPH 7 — 플랜두씨 다이어리 2

T06 최종 상태를 보존하고 Supabase Auth와 RLS를 추가한 T07 제출 소스.

**실행 URL:** https://dfdfewqk.github.io/ALEPH-7/

**대체 배포 URL:** https://dfdfewqk.github.io/Horse-Journey-Diary-ALEPH/t07/

기존 Supabase Edge HTML 주소에서는 브라우저에 코드가 표시될 수 있으므로 위의 GitHub Pages 주소를 사용합니다.

## 제출 경로

- 작업 저장소: https://github.com/dfdfewqk/ALEPH-7-
- T06 고정 커밋: `6949cabd358e0290332172c7be9604200ac7fcb7`
- **T06 커밋이 조상으로 유지되는 제출용 브랜치:** `dfdfewqk/Horse-Journey-Diary-ALEPH:t07-aleph7`
- T06 원본: https://dfdfewqk.github.io/Horse-Journey-Diary-ALEPH/
- 증거: `docs/T07_EVIDENCE.md`
- 구현 설명: `docs/T07_AUTH_IMPLEMENTATION_REPORT.md`

## 확인 방법 4줄

**어디로 가나요:** 위 실행 URL에서 회원가입 또는 로그인합니다.

**무엇을 하나요:** ① 로그인 ② 개인 목표·할 일 확인 ③ 보안 확인 ④ 잠긴 앱 5일 사용 기록과 내보내기.

**무엇이 보이면 통과:** 로그인 전 일기 자료 숨김, 로그인 후 본인 자료 표시, 10/15~19 서버 인증 활동 사후 확인 5/5일.

**안 될 때:** 새로고침 또는 GitHub Pages 대체 URL 이용. Supabase Edge Function HTML 링크는 사용하지 않습니다.

## 중요한 미충족 항목

2026-10-15~19 인증 계정의 실제 활동이 5일 존재하지만 공식 `t07_daily_observations`는 0건이고 `t07_rule_changes` 역시 0건입니다. 10월 19일 새로 만든 30문제 목표는 5일째의 학습 방식 변경이며, 원래 과제의 Day 2와 Day 3 사이 규칙 변경과 구분합니다.

실제 HTTP A/B 양방향 공격 전수 테스트는 아직 확인되지 않았습니다. DB 역할/JWT simulated RLS 조회·수정·삭제 경계 검증은 수행했습니다. 비밀번호와 토큰은 증거에 기록하지 않습니다.

기존 T06 공개 데이터의 사용자는 증명되지 않았으므로 임의의 T07 계정에 배정하지 않았습니다. 사용자가 인증 상태에서 T06 연결 요청을 제출할 수 있도록 했습니다.

## 사후 실험 등록(2026-10-19)

인증된 T07의 10월 15~19일 실제 5일 활동을 별도 실험 Day 1~5로 **사후 등록 완료**. 등록일 10월 19일 10:34:51 KST, 합계 497분·평균 99.4분, Day5 시간 미측정(0분) + 별도 30문제 달성. UI 상태는 `5/5일 완료 · 사후 등록`이며 공식 당시 Day 저장 또는 Day2~3 규칙 변경 이력으로 오인하지 않도록 구분한다.

### Day 2 이후 공부 계획 시간 변경 증거

Day 1~2(10/15~16)는 공부 할 일 예정 60분, Day 3~4(10/17~18)는 예정 120분으로 실제 생성·완료된 자료를 확인하고 `t07_retro_rule_evidence`에 사후 등록했다. 실제 새 120분 할 일 생성은 **10/17 16:43:29 KST**, 증거 사후 등록은 **10/19 10:54:44 KST**다. 이는 공부 할 일의 예정 시간 변경이며, 상위 목표 `daily_target_minutes`는 여전히 60분이므로 두 항목을 혼동하지 않는다. 전후 공부 평균: 변경 전 68.5분/일, 변경 후 120분/일(Day 5 미측정=0분 포함).
