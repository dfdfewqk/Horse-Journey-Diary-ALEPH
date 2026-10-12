# T07 증거 기록

> 비밀번호·토큰·비밀키 원문을 이 파일에 넣지 않는다.  
> password: `[REDACTED]`  
> Authorization: `Bearer eyJ...생략`

## 테스트 환경

- Result URL: 배포 완료 후 기입
- Source: https://github.com/dfdfewqk/ALEPH-7-
- Timezone: Asia/Seoul
- Auth: Supabase Auth / Email + Password
- SDK: @supabase/supabase-js 2.117.3

## 카드 1 — 가입·로그인·로그아웃

### 회원가입
- 시각:
- 결과:
- 판정: 대기

### 로그인
- 시각:
- 결과:
- 판정: 대기

### 로그아웃
- 시각:
- 결과:
- 판정: 대기

### 비로그인 상태 직접 접속
- 요청:
- 응답:
- 판정: 대기

## 카드 2 — 비밀번호 저장

- 테스트 계정 A encrypted_password: `[캡처 시 일부 가림]`
- 테스트 계정 B encrypted_password: `[캡처 시 일부 가림]`
- 두 저장값 비교:
- 로그인 요청 password: `[REDACTED]`
- 판정: 대기

## 카드 3 — 세션/JWT

### 로그인 상태 보호 요청
- Method:
- URL:
- Authorization: `Bearer eyJ...생략`
- Status:
- Response:
- 판정: 대기

### 로그아웃 뒤 같은 요청
- Method:
- URL:
- Authorization: `Bearer eyJ...생략`
- Status:
- Response:
- 판정: 대기

## 카드 4 — 다른 사람 자료 차단

| 테스트 | 요청 | HTTP | 결과 | 판정 |
|---|---|---:|---|---|
| A → B READ |  |  |  | 대기 |
| A → B UPDATE |  |  |  | 대기 |
| A → B DELETE |  |  |  | 대기 |
| B → A READ |  |  |  | 대기 |
| B → A UPDATE |  |  |  | 대기 |
| B → A DELETE |  |  |  | 대기 |
| URL user_id 조작 |  |  |  | 대기 |
| Header user_id 조작 |  |  |  | 대기 |
| Body user_id 조작 |  |  |  | 대기 |
| 로그아웃 직접 요청 |  |  |  | 대기 |

### 공격 전후 건수
- 공격 전:
- 공격 후:
- 판정: 대기

### 목록 분리
- A 목록의 B 자료: 대기
- B 목록의 A 자료: 대기

## 카드 5 — 5일 실제 사용

| Day | 실제 날짜 | 지표 값 | 단위 | 비고 |
|---|---|---:|---|---|
| 1 |  |  |  |  |
| 2 |  |  |  |  |
| 규칙 변경 |  |  |  | Day 2 뒤 / Day 3 전 |
| 3 |  |  |  |  |
| 4 |  |  |  |  |
| 5 |  |  |  |  |

- 고정 질문:
- 지표:
- 단위:
- 계산 규칙:
- 누락값:
- 중복값:
- 이상치:
- 반올림:
- 주 시작 요일:
- 변경 전 평균:
- 변경 후 평균:
- 전체 합계:
- 전체 평균:
- 손 계산 대조:
