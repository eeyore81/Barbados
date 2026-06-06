# 끌어당김 iOS SwiftUI 앱

이 폴더에는 iOS용 SwiftUI 앱의 핵심 코드가 들어 있습니다. Xcode에서 새로운 SwiftUI App 프로젝트를 만든 뒤, 아래 파일을 프로젝트에 추가하면 됩니다.

## 포함된 파일
- `ManifestlyApp.swift` — 앱 진입점
- `Models.swift` — 목표, 로그, 확언, 행동 트리거 모델
- `ViewModels.swift` — 앱 상태 관리와 데이터 분석 로직
- `Views.swift` — 주파수 명상, 목표, 확언, 로그, 분석 화면

## 구현 기능
- 목표 자동 분해: 마인드 / 행동 / 환경
- 행동 트리거 + 완료 스트릭
- 끌어당김 로그 작성 + 감사 일기 기록
- 주파수 명상: 432Hz 중심의 끌어당김 에너지
- 확언 문장 AI 개선
- 데이터 기반 피드백 화면
- 게임화 UX: 운 레벨, 실행력 점수

## 실행 방법
1. Xcode 열기
2. "Create a new Xcode project" → App → Interface: SwiftUI → Language: Swift
3. 새 프로젝트에 이 파일들을 추가
4. `ManifestlyApp.swift`가 앱의 진입점이 되는지 확인

## 다음 단계
- Audio 녹음/재생 기능 추가
- Persistence(CoreData 또는 로컬 저장) 통합
- 실제 그래프 라이브러리 또는 Swift Charts 추가
- 서버 기반 AI 문장 개선 연결
fbc1cg9503
