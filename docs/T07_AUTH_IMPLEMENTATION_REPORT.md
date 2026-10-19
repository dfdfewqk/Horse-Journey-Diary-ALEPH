# T07 인증 구현 설명서

> 기준 T06: `dfdfewqk/Horse-Journey-Diary-ALEPH`  
> 고정 commit: `6949cabd358e0290332172c7be9604200ac7fcb7`  
> T07 repository: `dfdfewqk/ALEPH-7-`

## ① 무엇으로 붙였나

- 인증 서비스: **Supabase Auth**
- 로그인 방식: **Email + Password**
- 브라우저 클라이언트: **@supabase/supabase-js 2.117.3**
- 데이터 권한: **PostgreSQL Row Level Security(RLS)**
- 비밀번호 저장: **Supabase Auth의 bcrypt + 계정별 무작위 salt** (해시는 `auth.users.encrypted_password`에 저장)
- 사용자 식별: Supabase Auth access token의 JWT `sub` / `session_id`
- 로그아웃 세션 추가 검증: private 스키마의 `private.t07_is_active_session()`이 `auth.sessions`에 현재 `session_id`가 실제로 존재하는지 확인하고, 공개 API에는 security-invoker 래퍼 `t07_session_status()`만 노출

브라우저에는 Supabase publishable key만 두며 service role key, DB password, JWT signing secret은 두지 않는다.

## ② 왜 그걸 골랐나

기존 T06이 이미 Supabase PostgreSQL을 사용하고 있어 Supabase Auth의 사용자 ID와 PostgreSQL RLS를 직접 연결할 수 있다는 점을 우선했다. 비밀번호 저장과 검증을 직접 구현하지 않고 인증 서비스에 맡겨 직접 구현에서 생길 수 있는 보안 오류를 줄였다. Supabase Auth는 비밀번호 원문이 아니라 bcrypt 해시와 무작위 salt를 저장한다.

함께 검토한 방법은 직접 세션 서버와 비밀번호 해시를 구현하는 방식이다. 이 방식은 비밀번호 저장, 세션 발급·폐기, 쿠키/토큰 보안까지 직접 책임져야 하므로 이번 과제에서는 기존 Supabase 구조와 바로 연결되는 Supabase Auth를 선택했다.

## ③ 어디를 어떻게 고쳤나

### GitHub `index.html` (2026-10-19 추가 안정화: 중복 완료 가드, 이전 T06 연결 버튼 복구, 서버 로그아웃 오류 처리, 로그인 후 데이터 로드 분리, 사후 증거 내보내기)

- 로그인/회원가입 첫 화면 추가
- 로그인 전에는 다이어리 `load()`를 실행하지 않음
- `signUp()`, `signInWithPassword()`, `signOut()` 연결
- 모든 T07 데이터 요청에 로그인 access token 사용
- 기존 T06 REST 경로를 T07 보호 테이블(`t07_*`)로 라우팅
- 로그아웃 시 화면 상태와 메모리의 다이어리 데이터를 비움
- 기존 T06 자료 연결 요청 버튼 추가
- 내 데이터 내보내기에 T07 5일 실험 데이터 추가
- 계정 삭제 버튼 추가
- T07 5일 사용 기록 UI 추가
- `t07_record_today_observation()`으로 5일 지표를 실제 실행 기록에서 서버 계산

### Supabase migrations

2026-10-19 추가: `t07_guard_daily_goal_sync_when_plan_cascades_on_delete`를 적용해 자신의 계획 삭제 중 하위 기록 트리거의 `PLAN_NOT_FOUND` 오류를 수정했다. 대응 SQL은 `supabase/migrations/20261019_t07_safe_cascade_daily_goal.sql`에 보존했다.

적용한 migration:

1. `t07_parallel_private_store`
   - T06 테이블을 건드리지 않고 T07 전용 `t07_*` 테이블을 별도로 생성
   - 기존 T06 row ID를 유지한 복사본 생성
   - `user_id` 추가
   - anon 권한 제거
   - authenticated + owner 조건의 RLS 적용
   - `t07_is_active_session()` 추가

2. `t07_secure_functions_and_experiment`
   - owner 강제 trigger
   - T07용 완료/완료취소 RPC
   - 하루 목표 동기화 RPC/trigger
   - 5일 실험용 setup / observation / rule change 테이블

3. `t07_experiment_plan_link`
   - 5일 실험과 실제 목표를 연결

4. `t07_experiment_order_guards`
   - Asia/Seoul 기준 같은 날짜 중복 기록 방지
   - Day 순서 강제
   - Day 2 뒤 규칙 변경 없이 Day 3 저장 불가
   - Day 1 이후 실험 기준 변경 제한

5. `t07_atomic_rule_change`
   - 목표의 하루 시간 변경과 규칙 변경 기록을 한 transaction 안에서 처리

6. `t07_server_derived_daily_observation`
   - Day 값은 브라우저가 보내는 숫자를 저장하지 않고 서버가 선택한 목표의 `execution_records.actual_minutes`를 합산
   - 같은 날짜 중복, Day 순서, Day 3 전 규칙 변경 조건을 서버에서 검증

7. `t07_lock_internal_helpers`
   - trigger 전용 함수의 직접 EXECUTE 권한 제거

8. `t07_move_active_session_check_private`
   - 활성 session 검사 함수를 private schema로 이동
   - RLS와 보호 RPC가 private 함수를 사용하도록 변경

### Edge Functions

`t07-protected`의 관리 권한 API가 원본 patch를 그대로 전달하지 않게 수정 허용 필드를 검증 전용으로 제한했다. 위 수정은 소스 보안 점검이며 A/B 실제 HTTP 실험을 대신하지 않는다.

- `supabase/functions/t07-protected/index.ts`
  - 로그인/활성 세션 확인
  - 요청 body/header의 다른 user_id를 신뢰하지 않음
  - 실제 소유자는 인증된 사용자에서 결정
  - 남의 단일 자료에는 404 반환
  - 목록은 로그인 사용자의 자료만 반환

- `supabase/functions/t07-delete-account/index.ts`
  - 현재 로그인 사용자만 삭제
  - service role key는 Edge Function 환경에서만 사용
  - T07 자료는 auth.users FK의 ON DELETE CASCADE로 함께 삭제

## ④ 인증·권한 테스트 결과 (2026-10-19 검증)

**DB 실제 시험 완료:** 유효한 활성 세션의 소유자 읽기 3건, 다른 사용자 ID에 현재 세션 ID를 붙여 위장한 읽기 0건, 누락 JWT claims로 읽기 0건. 비소유자의 소유자 목표 수정/삭제 각각 0건, 본인의 목표 수정 1건(실행 뒤 롤백), 본인의 소유자 ID를 타인으로 바꾸려는 수정은 서버 트리거에 의해 소유자가 그대로 유지됨. 모두 DB 역할/JWT claims를 사용해 PostgreSQL RLS 경로를 시험함. 테스트용 변경은 되돌려 사용자 데이터를 보존함.

**추가 확인 필요:** 다른 계정에 유효한 활성 세션이 없어 실제 A↔B 양방향 HTTP 테스트까지 완료한 것은 아님. 로그인·로그아웃 이후의 동일 HTTP 요청, 무인증 401 상태코드, URL/Header/Body 변경의 실제 HTTP 상태코드는 미검증이다. 본인 목표 DELETE 시험에서는 처음에 `PLAN_NOT_FOUND`가 발생했으나, 원인을 하위 데이터 집계 트리거의 부모 계획 삭제 재조회로 확인해 수정했다. 수정 후 유효한 계정 역할로 소유한 계획 1건 삭제 가능함을 검증한 뒤 되돌려 원본을 보존했다. 브라우저 클릭 테스트까지 검증했다는 뜻은 아니다.

**실제 5일 사용:** T07 로그인 계정에서 10/15~19 매일 실제 할 일 생성·완료한 서버 기록이 있으며, 같은 근거로 10/19에 사후 확인 5건 등록. 10/19에는 60분 중심의 기존 목표와 별개로 30문제 기준의 새 학습 목표를 만들고 달성함. 이는 **5일차의 실제 학습 방식 변경 증거**이지, Day 2~3 사이의 공식 규칙 변경 수행 증거는 아니다. `t07_daily_observations` 0건, `t07_rule_changes` 0건은 그대로 명시함.

자세한 날짜별 근거와 검증 표는 `docs/T07_EVIDENCE.md`를 참고한다. 비밀번호, access token, refresh token 원문은 저장하지 않는다.

## ⑤ AI와 나

- AI에게 맡긴 일: T06 구조를 복사한 뒤 Supabase Auth, T07 전용 RLS, 세션 검증 함수, 보호 API, 5일 기록 DB 구조와 화면을 구현하고 코드 정합성을 점검하게 했다.
- 내가 직접 판단한 일: 기존 T06 결과물을 깨지 않도록 별도의 ALEPH-7 저장소를 만들고, T07은 T06 기능을 유지한 채 인증을 추가하는 방향으로 정했다.
- AI 제안을 따르지 않은 일: 실제 5일 사용 기록을 과거 T06 기록으로 대신하지 않고, 인증이 적용된 T07에서 새로 남겨야 한다는 과제 조건을 유지한다.

## ⑥ 아직 못 막은 것

- **무차별 로그인 시도 전용 rate limiting UI/정책을 별도로 구현하지 않았다.** 반복적인 비밀번호 추측 시도를 더 적극적으로 제한하지 못한다는 위험이 있다.
- **MFA(두 번째 인증 수단)를 구현하지 않았다.** 비밀번호가 노출되면 추가 인증 단계가 없다.
- **비밀번호 재설정 전용 사용자 화면을 아직 구현하지 않았다.** 비밀번호를 잊은 사용자의 복구 흐름이 완전하지 않다.
- **보안 이벤트 전용 감사 로그 화면을 구현하지 않았다.** 누가 언제 실패한 접근을 시도했는지를 앱 안에서 장기 추적하기 어렵다.
- **Supabase의 leaked-password protection은 현재 프로젝트에서 꺼져 있다.** 2026-10-12 보안 Advisor 재검사에서 남은 유일한 경고이며, 이미 유출된 비밀번호를 추가로 차단하는 보호가 적용되지 않은 상태다.


### 2026-10-19 추가 증거: 실제 공부 할 일 계획 시간 변경

T07 로그인 계정의 실제 할 일 생성·완료 시각과 `t07_tasks.estimated_minutes`를 대조해 10/15~16 예정 60분, 10/17~18 예정 120분을 확인했다. Day 2 완료 후 Day 3 공부 전에 120분 예정 할 일을 만든 사실을 2026-10-19에 `t07_retro_rule_evidence`에 별도 기록했다. 원래 상위 계획의 하루 목표 60분은 수정되지 않았고 공식 `t07_rule_changes`는 0건이므로 **할 일의 계획 시간 변경 근거**로만 제출한다.


### 2026-10-19 신규 계정 로그인 실패 원인 및 개선

- Supabase auth.users 점검에서 최신 회원가입 계정은 비밀번호 해시는 있으나 `email_confirmed_at`가 비어 있고 성공 로그인 이력이 없는 것으로 확인했다. 비밀번호 틀림이라고 추정해서는 안 된다.
- 종전 로그인 UI는 `email_not_confirmed`도 '이메일 또는 비밀번호가 올바르지 않습니다'로 오안내했다. `error.code`에 따라 이메일 미인증, 잘못된 인증 정보, 시도 제한, 네트워크 오류를 분리해 표시한다.
- 회원가입에서 이메일 확인이 필요한 경우 로그인 탭 전환 전에 이메일을 복사해 두고, **탭 전환 후** 명확한 인증 메일 안내를 표시하도록 변경한다.
- 사용자 스스로 본인 주소로 `supabase.auth.resend({type:'signup',email})`를 호출하는 **인증 메일 다시 보내기** 버튼을 제공한다. 인증되지 않은 계정을 임의로 확인 완료 표시하지 않는다.
- 새로 생성한 계정이나 기존 공부 기록, 인증 설정 변경 없음. 이메일 확인은 메일 소유자가 링크를 클릭해야 하고, 브라우저 실로그인 테스트는 사용자 인증 정보 없이 검증하지 않았다.
