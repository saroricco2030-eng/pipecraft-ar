# SECURITY MASTER KNOWLEDGE BASE v4.0
# Flutter × Firebase 모바일 앱 보안 — 범용 참조 파일
# v2.0 → v3.0: PART 11(데이터 거버넌스) + PART 12(RBAC 설계) 추가
# v3.0 → v4.0: ① PART 10 중복 제거 (구버전 삭제, 업데이트 버전 통합)
#               ② 파일 순서 재정렬 (PART 9 → 10 → 11 → 12 → 13 → 부록)
#               ③ PART 13 도메인 특화 보안 템플릿으로 범용화
#
# ┌─ 3파일 지식베이스에서 이 파일의 위치 ────────────────────────────────────┐
# │  CLAUDE.md          → 프로젝트 정보 · Phase · 디자인 시스템 (Source of Truth) │
# │  DESIGN_MASTER      → UI/UX 비주얼 철칙                                  │
# │  이 파일            → 보안 전체 (Source of Truth)                        │
# │                                                                          │
# │  보안 관련 코딩 전 확인 순서:                                              │
# │    1. CLAUDE.md "특이사항 > RBAC 역할" 확인                              │
# │    2. CLAUDE.md "외부 서비스" 확인 (Firebase vs Supabase 등)             │
# │    3. 이 파일 PART 13 (프로젝트 특화 보안) 확인                          │
# │    4. 필요한 PART 상세 참조                                               │
# └──────────────────────────────────────────────────────────────────────────┘
#
# ┌─ Phase별 참조 분기 — AI 컨텍스트 효율화 ──────────────────────────────┐
# │  Phase 1: PART 2(저장소) + PART 7(Firebase) + PART 9(권한) 만 확인   │
# │  Phase 2: + PART 3(인증) + PART 5(WebView — 사용 시)                 │
# │  Phase 3: + PART 11(거버넌스) + PART 12(RBAC) + PART 13-5(결제)     │
# │  Phase 4: 전체 PART 확인 + PART 10 배포 전 전수 검사                 │
# │  ※ PART 1(위협 모델)은 프로젝트 설정 시 1회 읽으면 충분              │
# └──────────────────────────────────────────────────────────────────────┘
#
# ┌─ ★ SOURCE OF TRUTH 선언 ★ ─────────────────────────────────────────────┐
# │  보안·RBAC·CLIENT_VIEW·데이터 거버넌스에 관한 모든 규칙의 최종 기준은    │
# │  이 파일(SECURITY_MASTER_v4.md)이다.                                     │
# │                                                                          │
# │  프로젝트별 FEATURE_UNIVERSE에도 관련 내용이 있으나 그것은 요약 참조용이다. │
# │  두 파일 내용이 충돌할 경우 반드시 이 파일을 따른다.                    │
# │                                                                          │
# │  특히 CLIENT_VIEW 계정 정책은 PART 12-3이 유일한 구현 기준이다.          │
# │  FEATURE_UNIVERSE의 CLIENT_VIEW 항목은 요약본이며                        │
# │  구현 시 이 파일 PART 12-3을 직접 참조할 것.                            │
# └──────────────────────────────────────────────────────────────────────────┘
#
# ┌─ 보안 레이어 구조 (바깥 → 안) ──────────────────────────────────────┐
# │  PART 1  위협 모델      — 공격자가 노리는 것 먼저 이해               │
# │  PART 2  데이터 보안    — 저장/전송/클립보드/키보드 캐시             │
# │  PART 3  인증 & 인가    — 기본 인증 + OAuth PKCE                    │
# │  PART 4  네트워크 보안  — SSL/TLS + Certificate Pinning             │
# │  PART 5  앱 내부 보안   — WebView + 딥링크/Intent                   │
# │  PART 6  앱 무결성      — 난독화 + 루트감지 + 스크린샷 방지          │
# │  PART 7  Firebase 보안  — Rules + Auth + App Check                  │
# │  PART 8  공급망 보안    — 의존성 + 빌드 + 서명                       │
# │  PART 9  개인정보 보호  — GDPR/PIPA + 최소 권한                     │
# │  PART 10 보안 체크리스트 — 배포 전 전수 검사 (통합)                  │
# │  PART 11 데이터 거버넌스 — 데이터 분류/소유권/보존기간               │
# │  PART 12 RBAC 설계      — 역할 기반 접근 제어 상세 ★CLIENT_VIEW 포함│
# │  PART 13 도메인 특화 보안 — 프로젝트별 작성 (템플릿 제공)            │
# │  부록    보안 도구 & 리소스                                          │
# └──────────────────────────────────────────────────────────────────────┘
#
# 준거: OWASP Mobile Top 10 (2024) · OWASP MASVS v2.0 · MASTG
#       NIST SP 800-63B · GDPR · PIPA · Google Android Security
#       Apple Keychain/ATS · Flutter 공식 문서 · Very Good Ventures

---

## ▌PART 1. 위협 모델 — OWASP Mobile Top 10 (2024)

*공격자가 노리는 10가지 — 이걸 모르고 만들면 열린 문을 만드는 것*

### M1. Improper Credential Usage ← 신규 1위
```
공격 패턴: 소스코드/설정 파일에 API 키·비밀번호 하드코딩
           Git 히스토리에 시크릿 노출 (삭제해도 히스토리에 남음)
           SharedPreferences 등 평문 저장소에 토큰 보관
실사례:    2017 Uber 해킹 — GitHub private repo에 AWS S3 키 하드코딩
           → 5700만 사용자 정보 유출
방어:      PART 2 (안전 저장소 + API 키 관리 전략)
```

### M2. Inadequate Supply Chain Security ← 신규
```
공격 패턴: 취약한 서드파티 라이브러리/SDK 사용
           악성 코드 삽입된 패키지 의존성
실사례:    2020 EventBot Android 악성코드 — 서드파티 라이브러리 통해 배포
방어:      PART 8 (공급망 보안)
```

### M3. Insecure Authentication/Authorization
```
공격 패턴: 약한 비밀번호 정책, MFA 미적용
           클라이언트 사이드 인증 로직 (우회 가능)
           권한 검증을 앱에서만 수행
실사례:    2014 Starbucks 앱 — 사용자 자격증명 기기에 평문 저장
방어:      PART 3 (인증/인가)
```

### M4. Insufficient Input/Output Validation
```
공격 패턴: SQL/Command Injection
           XSS (WebView 사용 앱)
           서버 응답값 무검증 처리
방어:      PART 5 (WebView 보안) + Firestore Rules 유효성 검증 (PART 7)
```

### M5. Insecure Communication
```
공격 패턴: HTTP 사용 (HTTPS 미적용)
           인증서 검증 우회 (badCertificateCallback: (_,_,_) => true)
           TLS 1.0/1.1 허용 → POODLE, BEAST 취약점
           MITM(중간자) 공격
방어:      PART 4 (네트워크 보안)
```

### M6. Inadequate Privacy Controls
```
공격 패턴: 불필요한 개인정보 수집
           과도한 앱 권한 요청
           로그에 PII(개인식별정보) 출력
방어:      PART 9 (개인정보보호)
```

### M7. Insufficient Binary Protections
```
공격 패턴: 코드 난독화 미적용 → 역공학 노출
           디버그 모드 릴리즈 배포
           루트/탈옥 기기 감지 없음
방어:      PART 6 (앱 무결성)
```

### M8. Security Misconfiguration
```
공격 패턴: 개발용 설정(debug flag)을 프로덕션에 포함
           Firebase 보안 규칙 미설정 (공개 읽기/쓰기)
           AndroidManifest.xml 잘못된 권한 설정
           WebView JavaScript 허용 + URL 무검증
방어:      PART 5 (WebView/딥링크) + PART 7 (Firebase 보안)
```

### M9. Insecure Data Storage
```
공격 패턴: SharedPreferences/UserDefaults 평문 저장
           SQLite 암호화 없이 민감정보 저장
           로그 파일·백업에 민감정보 포함
방어:      PART 2 (데이터 보안)
```

### M10. Insufficient Cryptography
```
공격 패턴: DES, MD5, SHA-1 등 구식 알고리즘 사용
           약한 키 길이, 하드코딩된 암호화 키
           ECB 모드 사용 (패턴 노출 위험)
방어:      PART 2 (암호화) + PART 8 (빌드 보안)
```

---

## ▌PART 2. 데이터 보안

### 2-1. 민감 데이터 분류
*[OWASP MASVS-STORAGE, NIST SP 800-57]*

```
저장 자체를 피해야 할 것:
  비밀번호 (해시만 서버에 보관)
  카드 전체 번호 (PCI DSS)
  주민번호

암호화 저장 필수:
  인증 토큰 (JWT, OAuth access token, Refresh token)
  API 키
  사용자 PII (이름, 연락처, 위치)
  생체인식 데이터 레퍼런스

평문 저장 가능 (비민감):
  앱 설정값 (다크모드, 언어)
  캐시 데이터 (개인정보 미포함)
  마지막 방문 화면
```

---

### 2-2. Flutter 안전 저장소
*[flutter_secure_storage 공식 문서, OWASP MASVS-STORAGE, Google Android Keystore, Apple Keychain]*

**저장소 선택 기준**
```
민감 데이터    → flutter_secure_storage  (Keychain/Keystore 하드웨어 보호)
일반 설정      → shared_preferences      (평문, 민감정보 절대 금지)
대용량 로컬 DB → sqflite + sqlcipher     (AES-256 암호화 DB)
```

**flutter_secure_storage 구현**
```dart
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true, // Android API 23+
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  ),
);

// 저장
await storage.write(key: 'access_token', value: token);
// 읽기
final token = await storage.read(key: 'access_token');
// 로그아웃 시 전체 삭제 필수
await storage.deleteAll();
```

**절대 금지 패턴**
```dart
// ❌ SharedPreferences에 토큰 저장 — 평문 노출
final prefs = await SharedPreferences.getInstance();
prefs.setString('token', accessToken);

// ❌ 소스코드에 API 키 하드코딩
const apiKey = 'sk-1234567890abcdef';

// ❌ flutter_dotenv — assets 폴더에 포함되어 APK 압축 해제로 노출

// ❌ 전역 변수/싱글톤에 토큰 저장 — 메모리 덤프 공격에 노출
// (OWASP MASTG: 토큰을 메모리에 장시간 평문으로 올려두는 패턴)
class AuthService {
  static String? accessToken; // ← 절대 금지
}
```
> ⚠️ 토큰을 전역 변수나 static 필드에 보관하면 메모리 덤프 분석으로 추출 가능.
> flutter_secure_storage에서 필요 시에만 읽고, 메모리 내 캐시 시간을 최소화한다.

**Android 백업에서 민감 파일 제외**
```xml
<!-- AndroidManifest.xml -->
<application android:fullBackupContent="@xml/backup_rules">

<!-- res/xml/backup_rules.xml -->
<full-backup-content>
  <exclude domain="sharedpref" path="FlutterSecureStorage"/>
</full-backup-content>
```

---

### 2-3. API 키 관리 전략
*[CodeWithAndrea(Andrea Bizzotto), Very Good Ventures, OWASP M1]*

```
Level 1 (기본): ENVied 패키지 + obfuscate: true
  → Git 노출은 막지만 역공학에는 취약
  → Frida / 메모리 덤프로 런타임 추출 가능
  → 낮은 중요도 키에만 사용 (예: 지도 API, 공개 읽기전용 키)

Level 2 (권장): 백엔드 프록시 서버 경유
  → 앱에는 키가 존재하지 않음
  → 클라이언트 → 자체 백엔드(Cloud Functions) → 외부 API
  → 대부분의 앱에 권장하는 아키텍처

Level 3 (최고): Firebase Remote Config + AES + 기기 고유값 조합
  → 키를 원격에서 동적으로 로드 후 기기 식별자로 암호화 저장
  → 고가치 키 (결제, 의료 데이터)에 적용
```

**⚠️ 반드시 Level 2 이상 (Cloud Functions 프록시) 적용해야 하는 케이스**
```
결제 API 키 (TossPayments, Stripe Secret Key)
AI API 키 (OpenAI, Anthropic — 비용 폭탄 위험)
SMS/알림 API 키 (Twilio, Kakao)
내부 DB 직접 접근 자격증명

→ 위 케이스에서 ENVied만 쓰는 건 '잠그지 않은 것'과 같다.
```

**ENVied 구현 (Level 1)**
```dart
@EnviedField(varName: 'API_KEY', obfuscate: true)
static final String apiKey = _Env.apiKey;
// 컴파일 타임에 코드로 삽입 → assets 노출 없음
```

**배포 전 Git 히스토리 스캔**
```bash
gitleaks detect --source . --verbose
```

---

### 2-4. 전송 중 데이터 보안
*[OWASP MASVS-NETWORK, NIST SP 800-175B]*

```dart
// ❌ 절대 금지 — 인증서 검증 완전 해제
SecurityContext context = SecurityContext();
HttpClient client = HttpClient(context: context)
  ..badCertificateCallback = (_, __, ___) => true; // ← 공격자 환영

// ✅ 모든 API 통신 HTTPS 강제
```

**Android TLS 강제 설정**
```xml
<!-- res/xml/network_security_config.xml -->
<network-security-config>
  <base-config cleartextTrafficPermitted="false">
    <trust-anchors>
      <certificates src="system"/>
    </trust-anchors>
  </base-config>
</network-security-config>
```

**로그 보안**
```dart
// ❌ 프로덕션 로그에 민감정보 출력 금지
debugPrint('User: ${user.email}, token: $token');

// ✅ 디버그 빌드에서만 출력
if (kDebugMode) {
  debugPrint('Auth flow completed');
}
```

---

### 2-5. 클립보드 보안
*[OWASP Flutter App Security Checklist, ostorlab.co]*

> 비밀번호·토큰이 클립보드에 복사되면 다른 앱이 읽어갈 수 있음.
> Android 클립보드는 동일 기기 앱들이 접근 가능.

```dart
// ✅ 비밀번호 필드 — 복사 차단
TextField(
  obscureText: true,          // 입력값 마스킹
  enableInteractiveSelection: false, // 선택/복사 비활성화
  // Flutter 3.19+ contextMenuBuilder로 커스텀 메뉴 제어
  contextMenuBuilder: (context, editableTextState) {
    return const SizedBox.shrink(); // 메뉴 완전 차단
  },
)

// ✅ 민감 작업 완료 후 클립보드 자동 초기화
Future<void> clearClipboardAfterDelay() async {
  await Future.delayed(const Duration(seconds: 30));
  await Clipboard.setData(const ClipboardData(text: ''));
}
```

**규칙**
```
❌ 비밀번호, 토큰, 리셋 링크를 클립보드에 절대 저장 금지
❌ "복사" 버튼으로 민감정보 클립보드 저장 금지
✅ 불가피하게 복사가 필요하면 30초 후 자동 초기화
✅ 복사 완료 토스트에 "30초 후 자동 삭제됩니다" 안내
```

---

### 2-6. 키보드 캐시 방지
*[OWASP MASVS-STORAGE, Google Android Security Docs]*

> 키보드는 자동완성·학습 기능으로 입력값을 기기에 캐시함.
> 비밀번호 입력 필드에서 키보드가 학습하면 자동완성 제안에 노출될 수 있음.

```dart
// ✅ 민감 입력 필드 — 키보드 캐시 및 자동완성 비활성화
TextField(
  obscureText: true,
  autocorrect: false,
  enableSuggestions: false,  // ← 핵심: 키보드 학습/자동완성 차단
  keyboardType: TextInputType.visiblePassword, // iOS 자동완성 방지
  autofillHints: null,       // autofill 힌트 제거
)

// ✅ 이메일 필드 — 자동완성은 허용하되 민감 데이터 제외
TextField(
  keyboardType: TextInputType.emailAddress,
  autofillHints: const [AutofillHints.email], // 허용
)
```

**적용 대상**
```
반드시 enableSuggestions: false 적용:
  - 비밀번호 입력
  - PIN/OTP 입력
  - 카드번호 입력
  - 주민번호 입력

선택적 적용:
  - 이메일 (자동완성 편의성 vs 보안 트레이드오프)
```

---

## ▌PART 3. 인증 & 인가

### 3-1. 인증 설계 원칙
*[OWASP MASVS-AUTH, OWASP MASTG, OWASP Authentication Cheat Sheet]*

```
핵심 원칙:
  - 인증/권한 검증은 반드시 서버에서 수행 (클라이언트만으론 보안 불가)
  - 클라이언트의 role 값 신뢰 금지 → 매 요청마다 서버 재검증
  - 저장: bcrypt/Argon2/scrypt (서버) — MD5/SHA-1 절대 금지

비밀번호 정책 (NIST SP 800-63B 최신 기준):
  ✅ 최소 길이: 8자 이상 (권장 12자+)
  ✅ 최대 길이: 64자 이상 허용 (짧게 자르지 말 것)
  ✅ 유출된 비밀번호 DB와 대조 차단 (HaveIBeenPwned API 등)
  ❌ 대문자+숫자+특수문자 조합 강제 — NIST 비권장 (사용자가 예측 가능한 패턴으로 우회)
  ❌ 주기적 강제 변경 — NIST 비권장 (침해 증거 없는 경우)
  ❌ 비밀번호 힌트 / 보안 질문 — NIST 금지

토큰 관리:
  - Access Token: 15분~1시간 (짧을수록 안전)
  - Refresh Token: Rotation 방식 (사용 시 새 토큰, 이전 토큰 무효화)
  - 로그아웃: flutter_secure_storage 전체 삭제 + 서버 토큰 무효화
```

---

### 3-2. JWT 보안
*[OWASP MASTG, OWASP JWT Cheat Sheet]*

**검증 필수 항목**
```
알고리즘:  RS256 또는 ES256 (HS256은 서버 키 공유로 위험)
alg:none:  서버에서 강제 검증 (알고리즘 필드 조작 공격 방어)
exp:       만료 클레임 항상 포함 + 서버 검증
jti:       Replay attack 방어용 JWT ID
aud:       Cross-service relay attack 방어용 대상 서비스 명시
```

```dart
// ✅ JWT는 반드시 flutter_secure_storage에 저장
await storage.write(key: 'access_token', value: jwtToken);

// ⚠️ JWT payload는 Base64 디코딩만 해도 내용 열람 가능
// → 민감 정보를 payload에 절대 넣지 않기
// → 암호화 필요 시 JWE(JSON Web Encryption) 사용
```

---

### 3-3. OAuth 2.0 + PKCE — 소셜 로그인 보안
*[RFC 7636, OWASP Mobile Security Testing Guide, flutter_appauth, Auth0]*

> **PKCE(Proof Key for Code Exchange)는 모바일 앱 OAuth의 필수 흐름.**
> 딥링크를 통한 authorization code 탈취 공격을 방어함.

**왜 PKCE가 필요한가**
```
일반 OAuth Authorization Code Flow의 취약점:
  1. 앱이 인증 서버에 authorization_code 요청
  2. 인증 서버가 딥링크(myapp://callback?code=XYZ)로 code 전달
  3. ← 악성 앱이 동일한 URL Scheme을 등록해 code 가로채기 가능
  4. 탈취한 code로 access_token 교환 → 계정 탈취

PKCE 해결책:
  1. 앱이 code_verifier(랜덤 문자열) 생성
  2. code_challenge = SHA256(code_verifier) 를 요청에 포함
  3. 인증 서버가 code와 함께 challenge 저장
  4. code 교환 시 code_verifier 제출 → 서버가 SHA256 검증
  5. → code를 탈취해도 verifier 없이는 토큰 교환 불가
```

**flutter_appauth 구현**
```dart
// pubspec.yaml: flutter_appauth: ^x.x.x
import 'package:flutter_appauth/flutter_appauth.dart';

final FlutterAppAuth appAuth = FlutterAppAuth();

// ✅ PKCE 자동 처리 + 시스템 브라우저 사용
Future<void> loginWithOAuth() async {
  try {
    final AuthorizationTokenResponse? result =
        await appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        'YOUR_CLIENT_ID',
        'myapp://oauth/callback',        // 딥링크 callback URL
        serviceConfiguration: AuthorizationServiceConfiguration(
          authorizationEndpoint: 'https://auth.example.com/authorize',
          tokenEndpoint: 'https://auth.example.com/token',
        ),
        scopes: ['openid', 'profile', 'email'],
        // PKCE는 flutter_appauth가 자동으로 code_verifier/challenge 생성
      ),
    );

    if (result != null) {
      // ✅ 토큰을 반드시 secure storage에 저장
      await storage.write(key: 'access_token', value: result.accessToken);
      await storage.write(key: 'refresh_token', value: result.refreshToken);
    }
  } catch (e) {
    // 에러 처리
  }
}
```

**핵심 규칙**
```
✅ 시스템 브라우저(Chrome Custom Tabs / SFSafariViewController) 사용 필수
   → WebView 내 로그인은 URL 조작/피싱에 취약 → 금지
✅ flutter_appauth 패키지가 PKCE 자동 처리
✅ client_secret은 앱에 절대 포함 금지 (역공학 노출)
✅ 토큰은 반드시 flutter_secure_storage에 저장
✅ 딥링크 URL Scheme은 충돌 방지를 위해 유니크하게 설정

❌ WebView 안에서 OAuth 로그인 처리 금지
❌ Implicit Flow 사용 금지 (토큰이 URL에 노출됨)
❌ code를 SharedPreferences에 임시 저장 금지
```

---

### 3-4. 생체인증 보안
*[OWASP MASVS-AUTH-2, Apple Local Authentication, Android BiometricPrompt]*

```dart
final LocalAuthentication auth = LocalAuthentication();

final bool authenticated = await auth.authenticate(
  localizedReason: '앱에 접근하려면 인증이 필요합니다',
  options: const AuthenticationOptions(
    biometricOnly: false, // false = 생체 실패 시 PIN 폴백
    stickyAuth: true,
  ),
);
```

**보안 주의사항**
```
⚠️ 생체인증 결과값(true/false)만 믿고 민감 작업 수행 금지
   → Frida로 return 값 조작 가능 → 서버 검증 병행 필수
⚠️ 생체인증 = 기기 잠금 해제의 대리 수단일 뿐
   → 결제 등 중요 트랜잭션: 생체인증 + 서버 OTP 이중 확인 권장
```

---

## ▌PART 4. 네트워크 보안 — SSL/TLS & Certificate Pinning

### 4-1. SSL Pinning 원칙
*[OWASP MASVS-NETWORK, The Droids on Roids, IMQ Minded Security]*

**Pinning이 막는 것**
```
- MITM 공격 (신뢰할 수 있는 CA에서 가짜 인증서 발급해도 차단)
- Burp Suite / Charles Proxy 트래픽 인터셉트 차단
- 루트 저장소 침해 시에도 보호
```

**Pinning 방식 비교**
```
Certificate Pinning:       인증서 전체 고정
  → 인증서 갱신 시 앱 업데이트 필요 (Let's Encrypt: 90일)
  → 관리 부담 높음, 비권장

Public Key Pinning (SPKI) ← 권장
  → 공개키만 고정 → 인증서 갱신해도 공개키 같으면 유효
  → 관리 부담 낮음

동적 Pinning (Remote Config)
  → 핀을 서버에서 동적 로드 → 앱 업데이트 없이 교체 가능
  → 복잡도 높음, 대규모 서비스에 적합
```

**구현**
```dart
final ByteData certData = await rootBundle.load('assets/cert/api_cert.pem');
final SecurityContext context = SecurityContext();
context.setTrustedCertificatesBytes(certData.buffer.asUint8List());
final HttpClient client = HttpClient(context: context);
```

**인증서 핑거프린트 추출**
```bash
openssl s_client -connect your-api.com:443 -showcerts </dev/null 2>/dev/null \
  | openssl x509 -fingerprint -sha256 -noout
```

**운영 주의사항**
```
- 백업 핀 최소 1개 유지 (주 인증서 교체 시 앱 불통 방지)
- 백엔드 팀과 인증서 교체 일정 반드시 공유
- 금융/의료 앱만 Pinning 권장 — 일반 앱은 유지보수 비용 대비 효과 검토
- Frida로 ssl_crypto_x509_session_verify_cert_chain 훅 가능
  → RASP(PART 6)와 병행 적용
```

---

### 4-2. Dio HTTP 클라이언트 보안 설정

```dart
Dio createSecureDio() {
  final dio = Dio();

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read(key: 'access_token');
      options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        await refreshToken();
        handler.resolve(await _retry(error.requestOptions));
      }
      handler.next(error);
    },
  ));

  return dio;
}
```

---

## ▌PART 5. 앱 내부 보안 — WebView & 딥링크/Intent

### 5-1. WebView 보안
*[OWASP MASVS-PLATFORM, Google Android Docs, Flutter Minds, IJCTT 2024 WebView Security Best Practices]*

> WebView는 앱 안의 브라우저. JS 브릿지가 열리면 웹 페이지가 앱의 네이티브 코드를 실행할 수 있음.
> 2022 TikTok Android 취약점도 WebView URL 탈취를 통한 계정 하이재킹.

**핵심 취약점**
```
① JavaScript Bridge Injection
   - 악성 웹 페이지가 addJavaScriptChannel로 등록된 Dart 함수 호출
   - → 네이티브 코드 실행, 데이터 유출, 계정 탈취 가능

② 무분별한 URL 탐색 허용
   - 악성 URL로 리디렉션 → 피싱 페이지 표시
   - javascript: scheme으로 임의 JS 실행

③ HTTP 혼용
   - HTTPS → HTTP 리디렉션 시 트래픽 탈취 가능
```

**안전한 WebView 구현**
```dart
late final WebViewController _controller;

@override
void initState() {
  super.initState();

  _controller = WebViewController()
    // ── JS 설정 ─────────────────────────────────────
    // ✅ 신뢰할 수 없는 외부 URL 로드 시 JS 비활성화
    ..setJavaScriptMode(JavaScriptMode.disabled)

    // ✅ 자체 도메인만 JS 활성화가 필요한 경우
    // ..setJavaScriptMode(JavaScriptMode.unrestricted)

    // ── URL 탐색 허용 목록 ────────────────────────────
    ..setNavigationDelegate(NavigationDelegate(
      onNavigationRequest: (NavigationRequest request) {
        final uri = Uri.parse(request.url);

        // ✅ HTTPS만 허용
        if (uri.scheme != 'https') {
          return NavigationDecision.prevent;
        }

        // ✅ 허용 도메인 화이트리스트
        const allowedDomains = [
          'yourapp.com',
          'api.yourapp.com',
          'cdn.yourapp.com',
        ];

        if (!allowedDomains.contains(uri.host)) {
          // 외부 URL은 시스템 브라우저로 열기
          launchUrl(uri, mode: LaunchMode.externalApplication);
          return NavigationDecision.prevent;
        }

        return NavigationDecision.navigate;
      },
    ));
}
```

**JavaScript Channel (브릿지) 보안 규칙**
```dart
// ✅ 브릿지 사용 시 반드시 메시지 검증
_controller.addJavaScriptChannel(
  'AppBridge',
  onMessageReceived: (JavaScriptMessage message) {
    // ① JSON 파싱 후 타입/필드 검증 필수
    try {
      final Map<String, dynamic> data = jsonDecode(message.message);

      // ② 허용된 action만 처리 (화이트리스트)
      const allowedActions = ['navigate', 'closeWebView', 'openCamera'];
      if (!allowedActions.contains(data['action'])) {
        return; // 허용되지 않은 action 무시
      }

      // ③ 민감 기능(결제, 권한 요청 등)은 브릿지로 노출 금지
      _handleBridgeAction(data);
    } catch (e) {
      // 파싱 실패 → 무시 (악성 메시지 방어)
    }
  },
);
```

**금지 패턴**
```dart
// ❌ JS 브릿지로 민감 기능 노출 금지
_controller.addJavaScriptChannel('AppBridge', onMessageReceived: (msg) {
  if (msg.message == 'logout') await auth.signOut(); // ← 웹 페이지가 강제 로그아웃 가능
  if (msg.message == 'getToken') return storage.read('access_token'); // ← 토큰 탈취 가능
});

// ❌ 사용자 입력 URL 직접 로드 금지
_controller.loadRequest(Uri.parse(userInputUrl)); // ← javascript: scheme 등 주입 가능

// ❌ HTTP URL 허용 금지
if (url.startsWith('http://')) _controller.loadRequest(Uri.parse(url)); // ← 트래픽 탈취
```

**OAuth 로그인에 WebView 사용 금지**
```
❌ WebView 안에서 OAuth/소셜 로그인 처리 금지
   → 앱이 사용자 자격증명에 접근 가능 (키로깅 가능)
   → 피싱 페이지와 구분 불가

✅ 반드시 시스템 브라우저 사용
   → flutter_appauth (Chrome Custom Tabs / SFSafariViewController)
   → PART 3 (OAuth PKCE) 참조
```

**민감 작업 후 WebView 데이터 초기화**
```dart
// 결제/로그인 완료 후 WebView 캐시 초기화
await _controller.clearCache();
await _controller.clearLocalStorage();
```

---

### 5-2. 딥링크 & Intent 보안
*[OWASP MASVS-PLATFORM, Android Developers, RFC 7636]*

> 딥링크는 외부에서 앱을 열 수 있는 입구.
> 잘못 구성되면 악성 앱이 같은 URL Scheme을 등록해 데이터를 가로챌 수 있음.

**URL Scheme 탈취 공격**
```
공격 흐름:
  1. 앱이 OAuth 후 myapp://callback?code=XYZ 로 리디렉션
  2. 악성 앱이 동일한 URL Scheme (myapp://) 등록
  3. OS가 어떤 앱을 열지 선택 다이얼로그 표시 or 악성 앱이 선점
  4. 악성 앱이 authorization_code 탈취
  → PKCE로 방어 (PART 3 참조)

추가 방어책:
  - App Links (Android) / Universal Links (iOS) 사용
    → HTTPS 기반 → 도메인 소유자만 등록 가능 → URL Scheme보다 안전
```

**App Links 설정 (Android)**
```xml
<!-- AndroidManifest.xml -->
<activity android:name=".MainActivity">
  <intent-filter android:autoVerify="true">  <!-- autoVerify: true 필수 -->
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <!-- URL Scheme 대신 HTTPS 도메인 사용 -->
    <data android:scheme="https" android:host="yourapp.com"/>
  </intent-filter>
</activity>
```

**딥링크 데이터 검증**
```dart
// ✅ 딥링크로 받은 데이터는 반드시 검증 후 사용
void handleDeepLink(Uri uri) {
  // ① 스킴/호스트 검증
  if (uri.scheme != 'https' || uri.host != 'yourapp.com') {
    return; // 예상치 않은 출처 거부
  }

  // ② 경로 검증 — 허용된 경로만 처리
  const allowedPaths = ['/product', '/order', '/profile'];
  if (!allowedPaths.any((path) => uri.path.startsWith(path))) {
    return;
  }

  // ③ 파라미터 검증 — 타입 + 범위 확인
  final productId = uri.queryParameters['id'];
  if (productId == null || !RegExp(r'^\d+$').hasMatch(productId)) {
    return; // 숫자가 아닌 ID 거부
  }

  // ④ 검증된 데이터만 사용
  navigateToProduct(productId);
}
```

**Android Intent 보안**
```dart
// ❌ 암묵적 Intent로 민감 데이터 전달 금지
// → 다른 앱이 동일한 Intent를 등록해 스니핑 가능

// ✅ 명시적 Intent 사용 (패키지명 직접 지정)
// → kotlin/java 코드에서 ComponentName으로 직접 지정

// ✅ PendingIntent에 FLAG_IMMUTABLE 설정
// Android 12+ 필수
```

**URL Scheme vs App Links 비교**
```
URL Scheme (myapp://):
  ❌ 누구나 동일한 scheme 등록 가능 → 탈취 위험
  ✅ 설정 간단
  → OAuth callback에는 사용 금지, 단순 네비게이션에만 사용

App Links / Universal Links (https://yourapp.com/):
  ✅ 도메인 소유자만 등록 가능 → 탈취 불가
  ✅ OAuth callback에 안전
  → 서버에 assetlinks.json (Android) / apple-app-site-association (iOS) 배포 필요
```

---

## ▌PART 6. 앱 무결성 보호

### 6-1. 코드 난독화
*[Flutter 공식 문서, Guardsquare, Talsec Security]*

**빌드 명령어**
```bash
# Android
flutter build appbundle --obfuscate --split-debug-info=./debug_info

# iOS
flutter build ipa --obfuscate --split-debug-info=./debug_info
```

**난독화 한계 명확히 이해하기**
```
하는 것:
  ✅ 클래스/함수/변수 이름을 무의미한 기호로 대체
  ✅ 역공학 시 코드 이해 난이도 증가

못 하는 것:
  ❌ 런타임 동적 공격 (Frida) 차단
  ❌ 리소스 파일 암호화
  ❌ 네이티브 코드(Kotlin/Swift) 난독화
  ❌ 앱 로직의 완전한 보호

→ 난독화는 필요조건, 충분조건이 아님 — RASP와 병행
```

---

### 6-2. 루트/탈옥 & RASP
*[flutter_jailbreak_detection, Talsec Free-RASP-Flutter, Guardsquare, Rayhan Hanaputra 펜테스트 사례]*

**기본 감지**
```dart
final bool isJailbroken = await FlutterJailbreakDetection.jailbroken;
if (isJailbroken) showSecurityAlert();
```

**주의: flutter_jailbreak_detection은 Frida로 쉽게 우회됨**
→ 금융/결제 앱이라면 Free-RASP-Flutter 권장

**RASP 적용 (Free-RASP-Flutter)**
```dart
final TalsecConfig config = TalsecConfig(
  androidConfig: AndroidConfig(
    packageName: 'com.example.app',
    signingCertHashes: ['your_cert_hash'],
    supportedAlternativeStores: [],
  ),
  iosConfig: IOSConfig(
    bundleIds: ['com.example.app'],
    teamId: 'YOURTEAMID',
  ),
  watcherMail: 'security@yourapp.com',
  isProd: true,
);
```

**RASP 탐지 범위**
```
✅ Root/Jailbreak (Magisk Shadow 포함)
✅ Frida/Objection 동적 분석 도구
✅ 에뮬레이터/가상 기기
✅ 앱 서명 변조 (리패키징)
✅ 디버거 연결
✅ 앱 무결성 (APK 변조)
```

---

### 6-3. 스크린샷 / 화면 녹화 방지
*[Android FLAG_SECURE, OWASP MASVS-PLATFORM]*

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
override fun onCreate(savedInstanceState: Bundle?) {
  super.onCreate(savedInstanceState)
  window.setFlags(
    WindowManager.LayoutParams.FLAG_SECURE,
    WindowManager.LayoutParams.FLAG_SECURE
  )
}
```

**적용 권장 화면**
```
- 로그인/비밀번호 입력
- 결제 정보
- 개인 의료/금융 정보
- 잔액/거래 내역
```

---

## ▌PART 7. Firebase 보안 — 프로젝트 특화

> Firebase를 백엔드로 사용하는 프로젝트에 적용한다.
> Firebase는 클라이언트가 DB에 직접 접근하는 구조 → **Security Rules가 유일한 방어선**.
> 규칙이 잘못되면 서버 코드 없이도 전체 DB가 노출됨.

### 7-1. Firebase 보안의 핵심 구조

```
일반 백엔드:  클라이언트 → 서버(API) → DB
                          ↑ 서버가 인증/권한 검사

Firebase:     클라이언트 → Security Rules → DB
                          ↑ 규칙이 유일한 방어선
```

**Firebase 보안 3대 축**
```
① Security Rules    Firestore / Storage 접근 제어
② Firebase Auth     신원 확인 — request.auth.uid 기반 권한 분기
③ App Check         정품 앱에서만 Firebase 접근 허용 (봇/스크래핑 차단)
```

---

### 7-2. Firestore 보안 규칙 — 실전 패턴

**❌ 절대 금지 패턴 (테스트 모드 기본값)**
```javascript
match /{document=**} {
  allow read, write: if true;  // 전 세계 누구나 읽기/쓰기 가능
}
// 시간 제한도 위험 — 기한 지나면 서비스 중단
allow read, write: if request.time < timestamp.date(2024, 12, 31);
```

**✅ 기본 인증 기반 규칙**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    function isAdmin() {
      return isSignedIn() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid))
          .data.role == 'admin';
    }

    // ── 사용자 문서 ──────────────────────────────────
    match /users/{userId} {
      allow read:   if isSignedIn();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId)
        // role 필드는 본인 수정 불가 (어드민만)
        && !request.resource.data.diff(resource.data)
             .affectedKeys().hasAny(['role']);
      allow delete: if isAdmin();
    }

    // ── 데이터 문서 ────────────────────────────────────
    match /products/{productId} {
      allow read:   if true;
      allow write:  if isAdmin();
    }

    match /orders/{orderId} {
      allow read:   if isOwner(resource.data.userId);
      allow create: if isSignedIn()
        && request.resource.data.userId == request.auth.uid
        && isValidOrder();
      allow update, delete: if false;
    }
  }
}
```

**✅ 데이터 유효성 검증 (Rules 레벨 이중 방어)**
```javascript
function isValidOrder() {
  let data = request.resource.data;
  return data.keys().hasAll(['userId', 'items', 'totalAmount', 'createdAt'])
    && data.userId is string
    && data.items is list
    && data.items.size() > 0
    && data.totalAmount is number
    && data.totalAmount > 0
    && data.createdAt == request.time;  // 서버 타임스탬프 강제
}

// 문자열 길이 제한 (XSS/인젝션 방어)
function isValidPost() {
  let data = request.resource.data;
  return data.title is string
    && data.title.size() > 0
    && data.title.size() <= 200
    && data.content.size() <= 10000;
}
```

**✅ 서브컬렉션 — 부모 권한 자동 상속 없음, 별도 선언 필수**
```javascript
match /posts/{postId} {
  allow read: if true;
  allow write: if isOwner(resource.data.authorId);

  match /comments/{commentId} {
    allow read: if true;
    allow create: if isSignedIn()
      && request.resource.data.authorId == request.auth.uid;
    allow update, delete: if isOwner(resource.data.authorId);
  }
}
```

---

### 7-3. Cloud Storage 보안 규칙

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    match /users/{userId}/profile/{fileName} {
      allow read:  if request.auth != null;
      allow write: if request.auth != null
        && request.auth.uid == userId
        && request.resource.size < 5 * 1024 * 1024    // 5MB 이하
        && request.resource.contentType.matches('image/.*');
    }

    match /posts/{postId}/{fileName} {
      allow read:  if request.auth != null;
      allow write: if request.auth != null
        && request.resource.size < 20 * 1024 * 1024   // 20MB 이하
        && (request.resource.contentType.matches('image/.*')
          || request.resource.contentType.matches('application/pdf'));
      allow delete: if request.auth != null
        && firestore.get(/databases/(default)/documents/posts/$(postId))
             .data.authorId == request.auth.uid;
    }

    match /public/{fileName} {
      allow read:  if true;
      allow write: if false;  // 앱에서는 쓰기 불가 (어드민만)
    }
  }
}
```

---

### 7-4. Firebase Authentication 보안

```dart
// 이메일 인증 강제
if (user != null && !user.emailVerified) {
  await user.sendEmailVerification();
  await FirebaseAuth.instance.signOut();
}

// Firestore Rules에서도 이중 차단
function isVerified() {
  return isSignedIn() && request.auth.token.email_verified == true;
}

// 민감 작업 전 재인증 강제
final credential = EmailAuthProvider.credential(
  email: user.email!, password: password
);
await user.reauthenticateWithCredential(credential);

// 로그아웃 시 FCM 토큰 삭제
await db.collection('users').doc(uid)
    .update({'fcmToken': FieldValue.delete()});
await FirebaseAuth.instance.signOut();
```

**Custom Claims (RBAC) — 서버에서만 설정 가능**
```
// Cloud Functions 또는 Admin SDK (서버)에서만 설정
await admin.auth().setCustomUserClaims(uid, { role: 'admin' });

// Firestore Rules에서 사용
function isAdmin() {
  return request.auth.token.role == 'admin';
}
```

---

### 7-5. App Check — 정품 앱 인증

```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,  // 프로덕션
  appleProvider: AppleProvider.deviceCheck,        // 프로덕션
);
// Firebase Console → Build → App Check → 각 서비스 적용 활성화
```

---

### 7-6. 비용 폭탄 방지 (보안 연계)

```javascript
// 비인증 대량 읽기 차단
match /posts/{postId} {
  allow list: if isSignedIn();   // 비인증 스크래핑 차단
  allow get:  if true;           // 단건 공개 읽기 허용
}
```

```dart
// 반드시 limit() 적용 — 없으면 전체 컬렉션 읽기 = 비용 폭탄
db.collection('posts').orderBy('createdAt', descending: true).limit(20).snapshots();
```

---

### 7-7. Rules 배포 & 테스트

```bash
firebase deploy --only firestore:rules,storage:rules

# 배포 전 에뮬레이터 테스트 필수
firebase emulators:start --only firestore,auth,storage
# → http://localhost:4000 Rules 시뮬레이터 UI

# Flutter 에뮬레이터 연결
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
```

---

## ▌PART 8. 공급망 보안

### 8-1. 의존성 관리
*[OWASP Mobile Top 10 M2, GitHub Dependabot, OWASP MASVS-CODE]*

```bash
# 업데이트 필요 패키지 확인
flutter pub outdated

# 미사용 의존성 탐지
dart pub global activate dependency_validator
```

**패키지 선택 기준**
```
✅ pub.dev 공식 검증 마크
✅ 최근 커밋 활성화 + 이슈 트래커 존재
✅ 유명 조직/개발자 (Google, Firebase팀, Very Good Ventures)
❌ 6개월+ 업데이트 없는 방치 패키지
❌ 출처 불명 GitHub 직접 의존성
```

---

### 8-2. 빌드 & 서명 보안

```bash
# 반드시 --release + --obfuscate 조합으로 빌드
flutter build appbundle --release --obfuscate --split-debug-info=./debug_info

# 배포 전 Git 히스토리 시크릿 스캔
gitleaks detect --source . --verbose --redact
```

```
- Android keystore: 버전 관리에 포함 금지 → .gitignore 설정
- iOS Distribution Certificate: Keychain에만 보관
- 서명 키 분실 = 앱 업데이트 불가 → 안전한 오프라인 백업 필수
- CI/CD: API 키는 반드시 환경변수(Secrets)로 주입
```

---

## ▌PART 9. 개인정보 보호

### 9-1. 최소 권한 원칙
*[OWASP MASVS-PRIVACY, GDPR Article 5(1)(c), PIPA 제16조]*

```dart
// 기능 사용 직전에 권한 요청 (앱 시작 시 일괄 요청 금지)
final status = await Permission.camera.request();
if (status.isDenied) {
  // 기능 비활성화 (앱 강제 종료 금지)
}
if (status.isPermanentlyDenied) {
  await openAppSettings(); // 강요 금지, 안내만
}
```

---

### 9-2. 데이터 최소화 & 로그 보안

```
- 서비스에 필요한 최소 개인정보만 수집
- 수집 목적 달성 후 즉시 삭제
- 로그에 PII 포함 금지: 이름, 이메일, 전화번호, IP 주소

앱 출시 필수:
  개인정보처리방침 앱 내 접근 링크
  계정/데이터 삭제 기능 (Google Play 2024 정책 필수)
  Firebase Analytics: 개인식별 불가 형태로만 전송
```

---


## ▌PART 10. 보안 체크리스트 — 배포 전 전수 검사

> 조건부 항목 표기:
> `[공통]` — 모든 프로젝트 필수
> `[RBAC]` — 다중 역할 앱만
> `[멀티테넌트]` — 조직별 데이터 격리가 필요한 앱만
> `[사진업로드]` — 사진/파일 업로드 기능 있는 앱만
> `[AI연동]` — AI API에 사용자 데이터 전송하는 앱만
> `[위치]` — 위치 데이터 수집하는 앱만
> 프로젝트 특화 보안 항목 → PART 13에 별도 기재

### [ 데이터 보안 ]
- [ ] `[공통]` 민감 데이터 flutter_secure_storage에 저장 (SharedPreferences 금지)
- [ ] `[공통]` 평문 API 키 소스코드 내 없음
- [ ] `[공통]` HTTPS 강제 적용 (HTTP 차단)
- [ ] `[선택]` Certificate Pinning 적용 (금융/의료/결제 앱 권장 — PART 4 참조)
- [ ] `[공통]` 클립보드 자동 클리어 30초 적용
- [ ] `[공통]` 키보드 캐시 비활성화 (민감 필드)

### [ 인증 & 인가 ]
- [ ] `[공통]` JWT 만료 시간 설정됨 (Access 15분, Refresh 7일)
- [ ] `[공통]` Refresh Token Rotation 적용
- [ ] `[공통]` OAuth PKCE 플로우 적용 (소셜 로그인 사용 시)
- [ ] `[공통]` 생체인증 fallback 처리됨
- [ ] `[RBAC]` RBAC 역할 매트릭스 Rules에 구현됨 (PART 12)
- [ ] `[RBAC]` 역할 변경 Cloud Function 서버사이드 처리됨
- [ ] `[RBAC]` 신규 사용자 기본 역할이 최소 권한으로 설정됨 (CLAUDE.md RBAC 역할 확인)

### [ 네트워크 ]
- [ ] `[공통]` TLS 1.2 미만 차단
- [ ] `[선택]` 인증서 핀닝 (금융/의료/결제 앱 권장 — PART 4 참조)
- [ ] `[선택]` 핀 교체 메커니즘 구현됨 (인증서 핀닝 적용 시 필수)

### [ WebView & 딥링크 ]
- [ ] `[공통]` JavaScript Bridge 화이트리스트 적용 (WebView 사용 시)
- [ ] `[공통]` 딥링크 파라미터 검증됨

### [ 앱 무결성 ]
- [ ] `[공통]` ProGuard/R8 난독화 활성화
- [ ] `[공통]` 루트/탈옥 감지 + 경고 처리
- [ ] `[공통]` 스크린샷 방지 (민감 화면)
- [ ] `[공통]` Firebase App Check 활성화 (Firebase 사용 시)

### [ 데이터 거버넌스 ]
- [ ] `[멀티테넌트]` 테넌트 격리 DB 경로 구조 적용됨 (PART 11-4)
- [ ] `[멀티테넌트]` 크로스 테넌트 쿼리 Rules에서 차단됨
- [ ] `[사진업로드]` 사진 EXIF GPS 자동 제거 적용됨
- [ ] `[사진업로드]` 보고서/공유 파일 서명 URL(시간 제한) 사용 (영구 URL 금지)
- [ ] `[AI연동]` AI 전송 데이터 처리 후 서버 즉시 삭제됨
- [ ] `[AI연동]` AI 학습 데이터 활용 별도 동의 플로우 구현됨
- [ ] `[위치]` 위치 로그 보존 기간 정책 구현됨 (PART 11-3 기준)
- [ ] `[공통]` 데이터 보존 기간 정책 앱 내 구현됨 (PART 11-3)
- [ ] `[공통]` 사용자 삭제 요청 시 법적 보존 데이터 익명화 처리됨

### [ 공급망 ]
- [ ] `[공통]` 의존성 취약점 스캔 완료 (flutter pub audit)
- [ ] `[공통]` 서명 키 안전한 오프라인 백업 있음
- [ ] `[공통]` 시크릿 Git 히스토리에 없음 확인

---


## ▌PART 11. 데이터 거버넌스 & 소유권

*[GDPR Art.5(보관 기간 최소화), PIPA 제21조(파기), 전자상거래법(거래 기록 보존)]*
*[NIST SP 800-53 AC-3(Access Enforcement), SC-28(저장 데이터 보호)]*

### 11-1. 데이터 분류 4단계

앱 내 데이터를 민감도와 소유권에 따라 4단계로 분류하고,
각 단계별 저장 위치·암호화·보존 기간·삭제 정책을 다르게 적용한다.

**TIER A — 고객·사용자 핵심 데이터 (최고 민감)**
```
종류:   사용자 생성 콘텐츠, 보고서/결과물, 고객 기업 정보
        (프로젝트별 — 예: 진단 결과, 주문 내역, 계약서 등)
저장:   Firebase Firestore — 테넌트/사용자 단위 격리 (별도 컬렉션 경로)
경로:   /tenants/{tenantId}/... 또는 /users/{uid}/... (교차 접근 절대 불가)
암호화: AES-256 전송 중 (TLS 1.3) + 저장 시 (Firebase 기본 적용)
접근:   해당 소유자 + 명시적 공유 대상만
보존:   법적 의무 기간 이후 사용자 요청 시 삭제 가능 (하단 11-3 참조)
백업:   일 1회 자동 백업, 보존 기간 + 30일 유지
이전:   고객 요청 시 JSON/CSV 내보내기 제공 (데이터 이식성 — GDPR Art.20)
```

**TIER B — 운용 데이터 (중간 민감)**
```
종류:   작업 이력, 알람 이력, 스케줄, 활동 로그
        (프로젝트별 — 예: 주문 처리 이력, 예약 내역, 이벤트 로그 등)
저장:   Firebase Firestore — 조직/사용자 단위 격리
접근:   역할 기반 (PART 12 RBAC 참조)
보존:   2년 (운영 분석용), 이후 익명화 집계 데이터만 유지
위치 로그: 사용자 동의 범위 내만 기록, 필요 최소 보존 후 자동 삭제
```

**TIER C — 공용 레퍼런스 DB (비민감)**
```
종류:   앱 콘텐츠 DB, 카테고리 목록, 코드 테이블, 규제 정보
        (프로젝트별 — 예: 상품 카탈로그, 에러코드 DB, 체크리스트 템플릿 등)
저장:   Firebase CDN + 앱 번들 (오프라인 포함)
접근:   인증 불필요 (공개)
암호화: 전송 시 TLS만 (저장 암호화 불필요)
갱신:   OTA 배포 — 앱 재설치 없이 업데이트
```

**TIER D — 로컬 임시 데이터 (기기 한정)**
```
종류:   오프라인 큐, 세션 캐시, 생체인증 키
저장:   flutter_secure_storage (iOS Keychain / Android Keystore)
        오프라인 큐: SQLite (기기 내)
접근:   기기 소유자만 (생체인증 잠금 옵션)
보존:   온라인 동기화 완료 후 자동 삭제 (오프라인 큐)
        세션 만료 시 캐시 자동 클리어
```

---

### 11-2. 사진/파일 업로드 개인정보 처리

*[GDPR Art.4(개인정보 정의 — 식별 가능 위치 포함), PIPA 제23조]*

```dart
// 사진 업로드 전 EXIF GPS 자동 제거 (필수)
import 'package:exif/exif.dart';

Future<Uint8List> stripExifGps(Uint8List imageBytes) async {
  // EXIF GPS 태그 제거 후 반환
  // GPS 정보 보존이 필요한 경우: 사용자 명시적 동의 후만 허용
}
```

**사진 처리 정책**
```
일반 업로드 사진:
  - EXIF GPS 자동 제거 (기본값)
  - 사용자 요청 시 위치 보존 옵션 선택 가능
  - 저장: TIER A 소유자 격리 스토리지

AI 분석 전송 사진:
  - 서버 전송 → 분석 완료 즉시 서버에서 삭제
  - 로컬 원본은 사용자가 명시 삭제 전까지 보관
  - AI 학습 데이터 활용: 별도 명시적 동의 필수 (거부 시 서비스 불이익 없음)

공유/발행 파일:
  - TIER A 격리 스토리지 저장
  - 다운로드 URL: 서명된 URL (24시간 유효) 사용
    → 영구 공개 URL 절대 금지 (링크 유출 시 무단 접근 방지)
```

**서명된 URL 생성 패턴 (Firebase Storage)**
```dart
// 영구 공개 URL 대신 시간 제한 서명 URL 사용
final ref = FirebaseStorage.instance.ref('[프로젝트 경로]/$userId/files/$fileId');
final signedUrl = await ref.getDownloadURL(); // Firebase = 기본 인증 필요
// 또는 Cloud Functions에서 서명 URL (1시간 유효) 생성
```

---

### 11-3. 법적 데이터 보존 기간 매핑

*앱이 법적 보존 기간 내 사용자 삭제 요청을 거부할 수 있는 근거*

```
규정                      보존 기간    적용 데이터
──────────────────────────────────────────────────────────────────
GDPR (EU)                 처리 목적 달성 후 삭제 (계약 이행 = 계약 기간)
PIPA (한국)               서비스 탈퇴 후 즉시 또는 최대 1년
전자상거래법 (한국)        계약·청약 철회: 5년 / 대금 결제: 5년 / 소비자 불만: 3년
통신비밀보호법 (한국)      로그기록: 3개월
[프로젝트 특화 규정]       → SECURITY_MASTER PART 13에 추가 기재
──────────────────────────────────────────────────────────────────
앱 내 통합 정책: 해당 앱 적용 규정 중 최장 기간 일괄 적용
```

**삭제 요청 처리 플로우**
```
사용자 계정 삭제 요청
      ↓
법적 보존 의무 데이터 확인
      ├─ 의무 없음 → 즉시 삭제 + 삭제 확인 이메일
      └─ 의무 있음 → 개인식별정보만 익명화 처리 + 안내
                      "[관련 법령]에 따라 [데이터 유형]은
                       최소 N년 보존 의무가 있습니다.
                       YYYY.MM 이후 자동 삭제됩니다."

익명화 처리 범위:
  이름, 이메일, 전화번호 → 삭제
  업무 기록, 측정값 → 익명 ID로 유지 (법적 의무 기간까지)
```

---

### 11-4. 멀티테넌트 데이터 격리

*[OWASP MASVS v2.0: MSTG-STORAGE-14 — 데이터 격리]*

**Firebase Firestore 테넌트 격리 구조**
```
/tenants/{tenantId}/
  ├─ [컬렉션A]/        (프로젝트별 정의)
  ├─ [컬렉션B]/        (프로젝트별 정의)
  ├─ [컬렉션C]/        (프로젝트별 정의)
  └─ users/            소속 사용자 (uid 목록만, 개인정보 최소화)

/users/{uid}/          개인 프로필 (테넌트 외부)
  ├─ role
  ├─ tenantId
  └─ [추가 필드]/      (프로젝트별 정의)
```

**크로스 테넌트 쿼리 방지 (Firebase Rules)**
```javascript
// PART 7 Firebase Rules와 연계
// 테넌트 격리 핵심 규칙
match /tenants/{tenantId}/{document=**} {
  allow read, write: if request.auth != null
    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.tenantId == tenantId;
    // 요청자의 tenantId가 문서의 tenantId와 일치할 때만 접근
}
```

---


## ▌PART 12. RBAC (역할 기반 접근 제어) 설계

*[NIST SP 800-53 AC-2(계정 관리), AC-3(접근 집행)]*
*[OWASP MASVS v2.0: MSTG-AUTH-1 — 서버사이드 인가]*

### 12-1. 역할 정의 & 권한 매트릭스

> **⚠️ 아래는 다중 역할 B2B 앱 기준 예시다.**
> 프로젝트에 맞는 역할명으로 대체하고, CLAUDE.md "특이사항 > RBAC 역할" 섹션에 매핑을 기재한다.
> 역할 수가 적은 앱(예: USER / ADMIN)은 단순화해서 사용한다.

```
역할 코드          설명 (예시 — 프로젝트별 재정의)
────────────────────────────────────────────────────
USER               일반 사용자 — 자신의 데이터만 접근
MEMBER             팀 구성원 — 팀 공유 데이터 읽기
MANAGER            관리자 — 팀 전체 + 성과/비용 데이터
ADMIN              최고 관리자 — 전체 + 사용자 관리
CLIENT_VIEW        외부 뷰어 — 공유된 완료 항목 읽기 전용
```

**권한 매트릭스 (예시 — 프로젝트별 항목 교체)**
```
데이터/액션              USER  MEMBER  MGR   ADMIN  CLIENT
──────────────────────────────────────────────────────────────────
내 항목 조회/수정          ●                   ●
팀 항목 조회               ○      ●      ●     ●
팀 항목 수정                             ●     ●
데이터 기록                ●      ●      ●     ●
데이터 조회                ●      ●      ●     ●       ○
공식 발행(publish)                        ○    ●
외부 공유 항목 조회                                     ●
팀원 현황 조회                            ●    ●
사용자 관리                                    ●

● 전체 접근  ○ 제한적 접근 (읽기 전용 또는 일부 조건)
```

---

### 12-2. Firebase Rules — RBAC 구현

*PART 7 Firebase 규칙 기반 확장*

```javascript
// 역할 헬퍼 함수
function getUserData(uid) {
  return get(/databases/$(database)/documents/users/$(uid)).data;
}

function hasRole(uid, role) {
  return getUserData(uid).role == role;
}

function hasAnyRole(uid, roles) {
  return getUserData(uid).role in roles;
}

function isSameTenant(uid, tenantId) {
  return getUserData(uid).tenantId == tenantId;
}

// ── 패턴 1: 본인 소유 항목만 접근 ──────────────────────────────
// USER는 자신이 만든 것만, MANAGER/ADMIN은 전체
match /tenants/{tenantId}/[컬렉션A]/{itemId} {
  allow read: if request.auth != null
    && isSameTenant(request.auth.uid, tenantId)
    && (
      hasAnyRole(request.auth.uid, ['MANAGER', 'ADMIN'])
      || resource.data.ownerId == request.auth.uid
    );

  allow write: if request.auth != null
    && isSameTenant(request.auth.uid, tenantId)
    && hasAnyRole(request.auth.uid, ['MANAGER', 'ADMIN']);
}

// ── 패턴 2: 발행(publish) 권한 분리 ───────────────────────────
// 작성은 MEMBER 이상, 공식 발행은 MANAGER/ADMIN만
match /tenants/{tenantId}/[컬렉션B]/{itemId} {
  allow read: if request.auth != null && isSameTenant(request.auth.uid, tenantId);

  allow create, update: if request.auth != null
    && isSameTenant(request.auth.uid, tenantId)
    && hasAnyRole(request.auth.uid, ['MEMBER', 'MANAGER', 'ADMIN']);

  // published=true 변경은 MANAGER, ADMIN만
  allow update: if request.auth != null
    && request.resource.data.published == true
    && hasAnyRole(request.auth.uid, ['MANAGER', 'ADMIN']);
}

// ── 패턴 3: 외부 뷰어 — 공유된 완료 항목만 ────────────────────
match /tenants/{tenantId}/[컬렉션B]/{itemId} {
  allow read: if request.auth != null
    && hasRole(request.auth.uid, 'CLIENT_VIEW')
    && resource.data.published == true
    && resource.data.sharedWithClient == true;
}
```

> ⚠️ 위 패턴의 `[컬렉션A]`, `[컬렉션B]`, 역할명은 프로젝트별로 교체한다.
> 실제 경로와 역할은 CLAUDE.md "특이사항 > RBAC 역할" 섹션에 기재한다.

---

### 12-3. 역할 관리 보안 원칙

> ★ SOURCE OF TRUTH: CLIENT_VIEW 계정 정책의 구현 기준은 이 섹션이 유일하다.
> FEATURE_UNIVERSE에 요약 내용이 있으나 참조용이며, 충돌 시 이 파일이 우선한다.

**CLIENT_VIEW 계정 생성 정책 (외부 뷰어)**
```
만료일 지정 필수: 만료 없는 CLIENT_VIEW 계정 생성 금지
  - 기본값: 30일
  - 최대값: 1년 (365일)
  - 만료 후: 자동 접근 차단 + 담당 ADMIN에게 갱신 알림
만료일 선택 UI: PRO+ 화면에서 DatePicker로 제공
접근 범위: 공유된 완료 항목 읽기 전용 — 수정·삭제 불가
생성 권한: ADMIN 이상만 가능
```

**역할 변경 보안**
```
역할 변경: ADMIN만 가능 (자기 자신의 역할 변경 불가)
역할 상승 (privilege escalation): Cloud Functions 서버사이드에서만 처리
  → 클라이언트에서 직접 Firestore users/{uid}/role 쓰기 금지

// Cloud Function — 역할 변경 (ADMIN 인증 필수)
exports.updateUserRole = functions.https.onCall(async (data, context) => {
  // context.auth.token으로 호출자 ADMIN 역할 검증
  if (!context.auth || context.auth.token.role !== 'ADMIN') {
    throw new functions.https.HttpsError('permission-denied', 'ADMIN only');
  }
  // 자기 자신 변경 금지
  if (data.targetUid === context.auth.uid) {
    throw new functions.https.HttpsError('invalid-argument', 'Cannot change own role');
  }
  await admin.firestore().doc(`users/${data.targetUid}`).update({ role: data.newRole });
});
```

**최소 권한 원칙 적용** *(NIST SP 800-53 AC-6)*
```
신규 사용자 기본 역할: 최소 권한 역할 (CLAUDE.md RBAC 역할 섹션 확인)
역할 승격: 관리자의 명시적 승인 후만 적용
만료 없는 CLIENT_VIEW 링크 생성 금지 → 공유 시 만료일 필수 지정
```

**역할 감사 로그 (Audit Log)**
```dart
// 역할 변경, 민감 데이터 접근 시 감사 로그 기록
await FirebaseFirestore.instance
  .collection('audit_logs')
  .add({
    'action': 'ROLE_CHANGE',
    'actorUid': currentUser.uid,
    'targetUid': targetUid,
    'fromRole': oldRole,
    'toRole': newRole,
    'timestamp': FieldValue.serverTimestamp(),
    'ipAddress': requestIp,  // Cloud Function에서 기록
  });
```

---

## ▌PART 13. 도메인 특화 보안 (프로젝트별 작성)

*이 섹션은 프로젝트마다 고유한 보안 요구사항을 기재하는 공간이다.*
*범용 파일에는 빈 템플릿만 제공한다. 프로젝트 시작 시 아래 구조로 채운다.*

> **작성 지침**
> - 이 PART는 CLAUDE.md의 "프로젝트 정보"와 함께 읽는다
> - 법적 의무가 있는 데이터(계약서, 결제기록, 의료기록 등)는 반드시 명시
> - RBAC 역할은 PART 12를 기준으로 프로젝트 역할명에 매핑하여 기재
> - Phase별 보안 적용 타이밍은 CLAUDE.md 0-1의 Phase 계획과 연동

---

### 13-0. 이 프로젝트의 도메인 특화 위협

```
<!-- 프로젝트 시작 시 작성 -->
도메인:      (예: 의료, 금융, 법무, 현장관리, B2B SaaS 등)
핵심 위협:   (예: 민감데이터 유출, 기록 위변조, 무단 접근 등)
법적 근거:   (예: 개인정보보호법, 의료법, 전자금융거래법 등)
```

---

### 13-1. 법적 효력이 있는 데이터 무결성 보호

```
<!-- 생성 후 수정·삭제가 법적으로 금지되는 데이터가 있는 경우 기재 -->
<!-- 해당 없으면 "N/A — 이 프로젝트에는 법적 불변 기록 없음" 기재 -->

대상 데이터: (예: 결제기록, 계약서, 진단기록 등)
보호 방법:   Firestore Rules create만 허용, update/delete 차단
서버 타임스탬프: FieldValue.serverTimestamp() 강제 (클라이언트 DateTime 금지)
해시 체인:   (법적 분쟁 우려 시 적용 — 선택)
```

**Firestore Rules 패턴 (불변 데이터용)**
```javascript
match /[collection]/{docId} {
  allow create: if request.auth != null
    && [역할 검증 조건];
  allow read:   if request.auth != null
    && [읽기 권한 조건];
  // ❌ update, delete 절대 금지
  allow update: if false;
  allow delete: if false;
}
```

---

### 13-2. 발행(Published) 문서 수정 차단

```
<!-- 초안→발행 워크플로우가 있는 경우 기재 (보고서, 견적서, 계약서 등) -->
<!-- 해당 없으면 "N/A" 기재 -->

발행 대상:    (예: 보고서, 견적서, 영수증 등)
발행 후 허용: (예: 공유 링크 추가만 허용)
발행 후 금지: 내용 수정 전면 차단
```

---

### 13-3. 민감한 개인정보 처리

```
<!-- 이 앱에서 수집하는 민감정보 목록 -->
<!-- 민감정보: 건강, 자격증, 위치, 재무, 생체 등 -->

수집 항목:   (예: 위치, 자격증 번호, 프로필 사진 등)
저장 위치:   (Firestore 경로 명시)
접근 권한:   (누가 읽을 수 있는지)
보존 기간:   (법적 의무 또는 사업 정책)
파기 방법:   (Cloud Functions 자동 삭제 또는 수동)
```

**사진/파일 업로드 보안 체크리스트**
```
- [ ] EXIF GPS 메타데이터 업로드 전 제거 (privacy_scraper 또는 flutter_exif 패키지)
- [ ] 파일 Magic Bytes 검증 (MIME 스푸핑 방지)
- [ ] Storage Rules — 업로더 본인 + 관리자만 읽기
- [ ] 파일 크기 제한 적용
- [ ] 바이러스/악성코드 스캔 (고위험 앱의 경우)
```

---

### 13-4. 오프라인 환경 보안

```
<!-- 인터넷 없는 환경에서도 동작하는 기능이 있는 경우 기재 -->
<!-- 해당 없으면 "N/A" 기재 -->

오프라인 저장소:   (Hive / SQLite / SharedPreferences 등)
암호화 여부:       (민감데이터는 flutter_secure_storage 또는 SQLCipher)
동기화 충돌 처리:  (Last-write-wins / 서버 우선 / 수동 해결 중 선택)
```

---

### 13-5. 서드파티 연동 보안

```
<!-- 외부 서비스(결제, AI API, 소셜로그인 등) 연동 시 기재 -->

연동 서비스:  (예: TossPayments, Kakao, OpenAI 등)
API 키 관리:  ENVied(Level 1) 또는 Cloud Functions 프록시(Level 2+) — PART 2-3 기준 적용
              ※ flutter_dotenv 사용 금지 (PART 2-3 참조 — APK 해체 시 노출)
Webhook 검증: 서명 헤더 검증 (예: TossPayments X-TOSS-SIGNATURE)
데이터 전달:  개인식별정보 최소 전달 원칙
```

**인앱구매(IAP) 영수증 검증** *(구독/유료 기능 있는 앱만 해당)*
```
✅ 서버 사이드 영수증 검증 필수 (클라이언트 검증만은 우회 가능)
   Apple:  App Store Server API v2 (서버 간 통신)
   Google: google.androidpublisher API (서버 간 통신)
✅ 구독 상태 판단은 서버에서 수행 후 클라이언트에 전달
✅ 영수증 위변조 방지: 서버에서 서명 검증 후 DB 기록
❌ 클라이언트에서 구독 상태 판단 후 기능 해제 금지 (변수 조작으로 우회 가능)
❌ 영수증을 SharedPreferences에 저장 금지
```

---

### 13-6. Phase별 보안 적용 타이밍

```
<!-- CLAUDE.md 0-1의 Phase 계획과 연동하여 작성 -->

PHASE 1 — [코어 기능] — 최소 보안 구축
  ✅ flutter_secure_storage 적용 (인증 토큰)
  ✅ Firestore Rules 기본 인증 + RBAC
  ✅ HTTPS + 입력값 기본 검증

PHASE 2 — [확장 기능] — 데이터 보안 강화
  ✅ 파일 업로드 보안 (13-3)
  ✅ 오프라인 암호화 저장 (13-4)
  ✅ Firestore Rules 역할별 세분화

PHASE 3 — [수익화] — 결제 보안 추가
  ✅ 결제 서비스 Webhook 검증 (13-5)
  ✅ 법적 문서 불변성 적용 (13-1, 13-2)
  ✅ 감사 로그 활성화 (PART 12-3)

PHASE 4 — [고급 기능] — 전체 보안 완성
  ✅ SSL Pinning 적용 (PART 4)
  ✅ 루트/탈옥 감지 RASP (PART 6)
  ✅ Firebase App Check 활성화 (PART 7-5)
  ✅ 배포 전 체크리스트 전수 검사 (PART 10)
```

---

## ▌부록. 보안 도구 & 리소스

### Flutter 보안 패키지
```
flutter_secure_storage      민감 데이터 암호화 저장 (Keychain/Keystore)
flutter_jailbreak_detection 루트/탈옥 기기 감지 (기본)
freerasp                    RASP — Frida/루트/에뮬레이터/변조 통합 감지
local_auth                  생체인증 (FaceID, 지문)
flutter_appauth             OAuth 2.0 + PKCE 구현 (시스템 브라우저)
permission_handler          런타임 권한 관리
envied                      API 키 컴파일타임 삽입 + 난독화
webview_flutter             공식 WebView (보안 설정 가능)
```

### 취약점 점검 도구
```
Burp Suite    HTTPS 트래픽 인터셉트/분석 (SSL Pinning 우회 테스트)
MobSF         모바일 앱 자동 정적/동적 분석
Frida         런타임 동적 분석 (공격자 도구 — 방어 이해용)
Gitleaks      Git 히스토리 시크릿 스캔
apktool       Android APK 역분석
```

### 참조 표준 문서
```
OWASP Mobile Top 10 (2024):  https://owasp.org/www-project-mobile-top-10/
OWASP MASVS v2.0:            https://mas.owasp.org/MASVS/
OWASP MASTG:                 https://mas.owasp.org/MASTG/
NIST SP 800-63B (인증):       https://pages.nist.gov/800-63-3/
OAuth 2.0 + PKCE (RFC 7636): https://oauth.net/2/pkce/
Flutter 보안 문서:             https://docs.flutter.dev/security
Flutter App Security Check:  https://docs.ostorlab.co/security/flutter_app_security_checklist.html
```

---


*출처: OWASP Foundation (Mobile Top 10 2024, MASVS v2.0, MASTG, JWT Cheat Sheet) /
NIST SP 800-57 · SP 800-63B · SP 800-175B / RFC 7636 (PKCE) /
Apple Keychain Services · ATS · Local Authentication /
Google Android Security (Keystore, BiometricPrompt, network_security_config, App Links) /
Flutter 공식 문서 (Obfuscation, Security, WebView, Deployment) /
Very Good Ventures (Flutter 보안) / CodeWithAndrea (API Key 관리) /
flutter_secure_storage · freerasp (Talsec) · flutter_appauth /
IMQ Minded Security (Flutter SSL Pinning 역분석) /
The Droids on Roids (SSL Pinning 구현) /
Flutter Minds (WebView JS Bridge Injection) /
Guardsquare (Flutter 난독화 한계) /
ostorlab.co (Flutter App Security Checklist) /
Sheshananda Reddy Kandula, IJCTT 2024 (WebView Security Best Practices) /
GDPR(EU 2016/679) · PIPA(개인정보보호법, 한국)*
