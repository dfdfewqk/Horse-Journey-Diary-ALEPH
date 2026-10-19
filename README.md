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
