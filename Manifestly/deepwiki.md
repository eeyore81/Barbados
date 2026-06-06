# Manifestly App — 전체 구조 분석 (DeepWiki)

> 끌어당김 법칙 기반 SwiftUI iOS 앱  
> 확언(TTS) + 주파수 명상 + 목표 관리 + 감사 일기 + 행동 트리거

---

## 📁 파일 구성

| 파일 | 역할 |
|------|------|
| `ManifestlyApp.swift` | 앱 진입점, 전역 Appearance 설정, 환경 객체 주입 |
| `Models.swift` | 모든 데이터 모델 (Goal, Affirmation, Log, Eruda 등) |
| `ViewModels.swift` | 비즈니스 로직, 상태 관리, TTS 제어, 알람 설정 |
| `Views.swift` | 모든 UI 화면 (약 1800줄) |
| `ContentView.swift` | 기본 템플릿 (사용 안 함) |
| `eruda.md` | Eruda TTS 핵심 기획 문서 (State Switch 개념) |
| `📘 Human-like TTS Reader 설계 (v1).md` | TTS 음성 엔진 설계 문서 |

---

## 🏛️ 앱 아키텍처

### 패턴: MVVM (Model-View-ViewModel)

```
Models.swift (데이터 구조체)
    ↕
ViewModels.swift (ObservableObject 상태 관리)
    ↕
Views.swift (SwiftUI View)
```

- `AttractViewModel`이 **전역 상태 저장소** 역할 (EnvironmentObject로 주입)
- 별도의 Persistence 계층 없음 (메모리 내 데이터만 유지)
- 모든 데이터는 앱 실행마다 `loadSampleData()`로 초기화

---

## 🌐 앱 진입점 (`ManifestlyApp.swift`)

```swift
@main
struct ManifestlyApp: App {
    @StateObject private var store = AttractViewModel()

    init() {
        // UINavigationBar 투명 스타일 전역 설정
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
        }
    }
}
```

- `AttractViewModel`을 `@StateObject`로 생성
- 모든 하위 뷰에 `@EnvironmentObject`로 주입

---

## 📦 데이터 모델 (`Models.swift`)

### 핵심 도메인 모델

| 모델 | 설명 |
|------|------|
| `Goal` | 목표 (제목, 대상, 마감일, 모드, 카테고리) |
| `Affirmation` | 확언 (원문, 개선문) |
| `ActionTrigger` | 행동 트리거 (할 일, 보상, 포인트) |
| `LogEntry` | 로그/일기 (긍정, 기회, 감사, 감정) |
| `AnalyticsSnapshot` | 분석 스냅샷 (완료 수, 점수, 스트릭) |

### Eruda (이루다) 전용 모델

| 모델 | 설명 |
|------|------|
| `ErudaState` | 6가지 상태 (Wealth, Love, Calm, Confidence, Healing, Sleep) |
| `ErudaMode` | Morning / Night |
| `ErudaAffirmation` | 상태별 확언 (isPlaying 포함) |
| `ErudaStateSet` | 한 State의 아침/저녁 확언 세트 |
| `CustomErudaSet` | 사용자 정의 확언 세트 |
| `NotificationAffirmation` | 알람 (시간, 확언, 활성화) |

### 열거형

| 열거형 | 설명 |
|--------|------|
| `GoalCategory` | mindset / action / environment (각각 색상 있음) |
| `LogType` | positive / opportunity / gratitude / emotion |
| `EmotionType` | calm / confident / anxious / motivated / tired (각각 아이콘 있음) |

---

## ⚙️ ViewModel (`ViewModels.swift`)

### `AttractViewModel` — 전역 상태 관리자

**프로퍼티**

```swift
@Published var goals: [Goal]
@Published var affirmations: [Affirmation]
@Published var actions: [ActionTrigger]
@Published var logs: [LogEntry]
@Published var selectedTab: Tab
@Published var goalsSplit: [GoalCategory: [String]]
@Published var currentStreak: Int
@Published var currentConfidence: Int
@Published var erudaStateSets: [ErudaStateSet]
@Published var customErudaSets: [CustomErudaSet]
@Published var notificationAffirmations: [NotificationAffirmation]
@Published var currentPlayingStateId: UUID?
@Published var isPlayingCustom: Bool
@Published var selectedErudaState: ErudaState
```

**주요 메서드**

| 메서드 | 기능 |
|--------|------|
| `loadSampleData()` | 샘플 데이터 로드 (goal 1개, affirmation 1개, action 3개, log 3개) |
| `createErudaData()` | 6개 State × 6개 확언 × 2모드 = 72개 확언 데이터 생성 |
| `splitGoal(_:)` | 목표를 mindset/action/environment로 자동 분해 |
| `improveAffirmation(_:)` | 확언 문장 개선 ("될 것이다" → "하고 있다") |
| `toggleActionCompletion(_:)` | 행동 완료 토글 + 스트릭/자신감 업데이트 |
| `analyticsSnapshot()` | 현재 분석 스냅샷 생성 |

### TTS 시스템 (핵심)

**VoiceState — 음성 상태 머신**

| 상태 | rate | pitch | pause |
|------|------|-------|-------|
| normal | 0.50 | 1.0 | 0.30s |
| affirmation | 0.45 | 1.2 | 0.45s |
| sleep | 0.35 | 0.9 | 0.75s |
| alarm | 0.55 | 1.4 | 0.15s |
| focus | 0.48 | 1.0 | 0.25s |

**TTS 관련 메서드**

| 메서드 | 기능 |
|--------|------|
| `playAffirmations(stateSet:mode:)` | Eruda 상태 세트 재생 (아침/저녁) |
| `playCustomAffirmations(customSet:)` | 사용자 정의 확언 재생 |
| `speakText(_:voiceState:)` | **핵심 TTS 함수** — 텍스트 → chunk 분할 → AVSpeechSynthesizer |
| `speakingChunks(from:)` | 텍스트를 의미 단위 chunk로 분할 (문장 → 쉼표 단위) |
| `stopPlayback()` | TTS 정지 + 상태 리셋 |

**TTS 처리 파이프라인**

```
Text Input
  ↓
speakingChunks(from:) 
  - "나는 이미" → "나는 이미..."
  - "나는" → "나는,"
  - 문장부호 기준 분할 → 쉼표 기준 분할
  ↓
각 chunk → AVSpeechUtterance 생성
  - voice = ko-KR
  - rate/pitch/volume/postDelay = VoiceState 기반
  ↓
AVSpeechSynthesizer.speak(utterance) — 큐에 순차 추가
```

**TTS 안정성 문제 해결 ([v2] 최신 수정)**

- `SpeechSynthesizerDelegate` — Delegate 패턴으로 완료/취소 콜백 수신
- `resetSynthesizer()` — `AVSpeechSynthesizer` 인스턴스를 **매번 새로 생성**하여 내부 상태 완전 리셋
- `configureAudioSessionForTTS()` — `AVAudioSession`을 `.playback` + `.spokenAudio` + `.mixWithOthers`로 설정
- 기존 문제: `stopSpeaking(at:)` 후 `speak()`가 먹통되는 iOS 버그 해결

### 알람 시스템

| 메서드 | 기능 |
|--------|------|
| `setAffirmationAlarm(title:affirmations:state:hour:minute:)` | 확언 알람 생성 |
| `scheduleLocalNotification(_:)` | UNUserNotificationCenter에 알람 등록 |
| `deleteAffirmationAlarm(_:)` | 알람 삭제 |

---

## 🖼️ 화면 구조 (`Views.swift`)

### 탭 구성 (MainTabView)

| 탭 | 화면 | 아이콘 |
|----|------|--------|
| Meditation | `FrequencyMeditationView` | waveform.path.ecg |
| 확언 | `AffirmationView` | mic |
| Gratitude | `GratitudeView` | heart.text.square |
| Eruda | `ErudaView` | book |
| More | `MoreView` | ellipsis.circle |

### 화면별 상세

#### 1. `FrequencyMeditationView` — 주파수 명상
- **TonePlayer** (ObservableObject): `AVAudioEngine` 기반 사인파 생성
- 주파수 선택: 174Hz (Release) / 432Hz (Harmony) / 528Hz (Healing)
- 배경음악: `background.mp3` 에셋 루프 재생
- 테마 연동: `selectedErudaState`에 따라 배경음 베이스 주파수 변경
  - Wealth: 120Hz, Love: 100Hz, Calm: 80Hz, Confidence: 140Hz, Healing: 110Hz, Sleep: 65Hz

#### 2. `AffirmationView` — 확언 작성
- 확언 입력 → AI 개선된 문장 미리보기 → 저장
- 저장된 확언 리스트

#### 3. `LogView` — 끌어당김 로그
- 유형별 Picker (positive/opportunity/emotion)
- 제목 + 설명 + 감정 선택 → 로그 추가
- 저장된 로그 리스트

#### 4. `GratitudeView` — 감사 일기
- 감사 제목 + 내용 입력
- 저장된 감사 일기 리스트

#### 5. `ErudaView` — 이루다 (핵심 기능)
- **탭 1: ErudaBrowseView** — 확언 탐색 + 재생 + 알람
  - 6개 State 선택 (💰💕🧘⭐🌿😴)
  - 각 State의 확언 리스트 표시
  - 확언 선택 → 알람 시간 설정 → 알람 등록
  - "듣기" 버튼 → TTS로 확언 재생
  - 저장된 Custom 세트 목록 (탭하여 재생)

- **탭 2: ErudaWizardView** — 나만의 확언 생성 (3단계)
  - Step 1: 카테고리 선택 + 제목 입력
  - Step 2: 확언 텍스트 입력 (줄바꿈 구분)
  - Step 3: 최종 확인 + 미리듣기 + 저장

#### 6. `GoalSetupView` — 목표 시스템 (More 탭)
- 목표 등록 폼 (제목, 대상, 모드, 마감일)
- 자동 분해 결과 (mindset/action/environment)
- 현재 목표 리스트

#### 7. `AnalyticsView` — 분석 (More 탭)
- 완료된 행동, 긍정 감정 기록, 기회 감지, 실행력 점수, 연속 성공
- 상관 관계 시각화 (행동/감정 bar)

#### 8. `ActionTriggerListView` — 행동 트리거 목록
- 각 Action의 완료 상태 토글

### 공통 디자인: `cosmicPanelBackground()`
- 모든 화면에 동일한 우주 테마 그라디언트 배경
  - 검정 → 인디고 → 퍼플 리니어 그라디언트
  - Radial 그라디언트 오버레이 2개 (화면 효과)
- 카드 스타일: 투명도 + 테두리 라인 + 섀도우

---

## 🎵 오디오 시스템

### TTS (Text-To-Speech)
- **엔진**: `AVSpeechSynthesizer` (Apple 내장)
- **언어**: ko-KR (한국어)
- **처리**: 텍스트 → chunk 분할 → utterance 큐잉
- **특징**: 속도/피치/볼륨/딜레이를 VoiceState로 제어

### 주파수 명상 (TonePlayer)
- **엔진**: `AVAudioEngine` + `AVAudioSourceNode`
- **방식**: 실시간 사인파 합성
- **배경음**: `background.mp3` 루프 (AVAudioPlayer)
- **특징**: LFO(저주파 발진)로 배경음에 변조 효과

---

## 📐 데이터 흐름

```
사용자 입력
  ↓
View (SwiftUI) — @State / @Binding
  ↓
ViewModel (AttractViewModel) — @Published 프로퍼티 업데이트
  ↓
Model (struct) — 불변 데이터
  ↓
View 자동 리렌더링 — SwiftUI 선언형 UI
```

**특이사항**:
- 별도의 Repository/Service 계층 없음
- 모든 로직이 ViewModel에 집중됨 (Fat ViewModel 패턴)
- Persistence 없음 (앱 재실행 시 샘플 데이터로 초기화)

---

## 🔮 Eruda (이루다) 시스템 — Identity State Switch

### 개념
> "Identity is not generated. It is heard repeatedly until accepted."

- 6가지 정체성 상태(State) 전환
- 각 상태는 아침(Morning = Activation) / 저녁(Night = Deactivation) 루틴
- 확언 반복 청취로 정체성 체화

### State 목록

| 상태 | 이모지 | 아침 컨셉 | 저녁 컨셉 |
|------|--------|-----------|-----------|
| Wealth | 💰 | 풍요 흐름 | 감사 + 무의식 유도 |
| Love | 💕 | 사랑 연결 | 관계 끌어당김 |
| Calm | 🧘 | 평화/고요 | 긴장 해제 |
| Confidence | ⭐ | 자신감/유능함 | 성취 자랑 |
| Healing | 🌿 | 온전함/치유 | 신체 치유 유도 |
| Sleep | 😴 | 충분한 휴식 | 깊은 수면 유도 |

---

## 🚨 알려진 이슈 및 개선 필요 사항

### 해결됨 (v2)
| 이슈 | 해결 |
|------|------|
| TTS 재생 멈춤 후 재생 불가 | Synthesizer 인스턴스 완전 교체 |
| 주파수 명상과 TTS 오디오 충돌 | AVAudioSession mixWithOthers 설정 |
| Synthesizer 상태 추적 불가 | Delegate 콜백 도입 |

### 미해결
| 이슈 | 설명 |
|------|------|
| 데이터 영구 저장 없음 | 앱 재시작 시 모든 데이터 소실 |
| AI 연동 없음 | 확언 개선이 단순 문자열 치환 수준 |
| 네트워크 기능 없음 | 서버 동기화, 백업 불가 |
| 큰 화면 최적화 미흡 | iPad 레이아웃 대응 필요 |
| 배경음 mp3 에셋 필요 | `background.mp3` 파일이 번들에 포함되어야 함 |

---

## 📝 코딩 컨벤션

- 모든 UI는 **SwiftUI** (UIKit 최소 사용)
- `cosmicPanelBackground()` — 모든 화면 공통 배경 (View extension)
- 카드 디자인 패턴 — `ViewModifier` 없이 인라인 그라디언트 + 오버레이 + 섀도우
- NavigationView 기반 내비게이션 (More 탭)
- 색상 시스템: `Color.cyan`, `Color.purple`, `Color.indigo` 위주
