# ALEPH 7 — 플랜두씨 다이어리 2

T06 최종본을 기준으로 인증·권한 검증을 추가하는 T07 저장소입니다.

- T06 upstream repository: https://github.com/dfdfewqk/Horse-Journey-Diary-ALEPH
- T06 fixed commit: `6949cabd358e0290332172c7be9604200ac7fcb7`
- T07 auth: Supabase Auth + PostgreSQL RLS
- Supabase JS SDK: `@supabase/supabase-js@2.117.3`

> 이 저장소는 T06 소스의 고정 commit을 기준으로 복사해 시작했습니다.

## T07 result URL

- Public login screen: https://bcwzllejypavwgsfqfbm.supabase.co/functions/v1/t07-app
- Source: https://github.com/dfdfewqk/ALEPH-7-

GitHub Pages workflow is also included, but the Supabase Edge URL above is the immediately deployed result URL.


## Canonical submission source

T07 작업은 이 저장소에서 진행하지만, T06 commit ancestry 요구사항을 만족하기 위해 최종 제출용 소스 이력은 다음 브랜치에 미러링한다.

- Repository: `dfdfewqk/Horse-Journey-Diary-ALEPH`
- Branch: `t07-aleph7`
- T06 ancestor: `6949cabd358e0290332172c7be9604200ac7fcb7`

Git compare 결과에서 `t07-aleph7`는 위 T06 commit을 merge-base로 가지며 ahead 상태다.
