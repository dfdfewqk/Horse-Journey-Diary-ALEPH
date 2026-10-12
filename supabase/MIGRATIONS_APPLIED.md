# T07 Supabase 변경 기록

실제 Supabase 프로젝트 `pds-diary-t06`에는 T06 원본 public 테이블을 유지한 채 T07 전용 테이블을 병렬로 추가했다.

## 적용 migration

- `t07_parallel_private_store`
- `t07_secure_functions_and_experiment`
- `t07_experiment_plan_link`
- `t07_experiment_order_guards`
- `t07_atomic_rule_change`

- `t07_server_derived_daily_observation`

- `t07_lock_internal_helpers`

- `t07_move_active_session_check_private`

## 핵심 원칙

- T06 원본 테이블 삭제/초기화 없음
- T07 데이터는 `t07_*` 테이블에 저장
- T07 테이블 anon 권한 제거
- authenticated 사용자도 `user_id = auth.uid()`이고 private 세션 검사에서 현재 `session_id`가 `auth.sessions`에 존재할 때만 접근
- 기존 T06 데이터는 ID를 유지한 복사본으로 만들었으며 현재 owner 연결 전 상태
- owner 연결은 실제 T07 계정이 확인된 뒤 수행
- browser에는 publishable key만 사용
- service role은 Edge Function 환경 변수에서만 사용

- T07 5일 관찰값은 브라우저 입력값을 믿지 않고 서버 RPC가 선택한 목표의 `execution_records.actual_minutes`를 직접 합산한다.
