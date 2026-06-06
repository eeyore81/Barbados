# 📘 Human-like TTS Reader 설계 (v1)

## 1. 목표

기존 TTS의 문제:
- 단조로운 억양
- 감정 없음
- 문장 경계 부정확
- 빠른 속도 or 기계적 끊김

해결 목표:
- “읽어주는 사람”처럼 들리게 만들기
- 감정/상황별 톤 변화
- 자연스러운 호흡(phrasing)
- 문장 의미 기반 리듬 생성

---

## 2. 전체 구조

```
Text Input
   ↓
Preprocessor (문장 분석)
   ↓
Prosody Engine (억양/속도/감정)
   ↓
SSML Generator (또는 Apple AVSpeechUtterance)
   ↓
TTS Engine (Apple / ElevenLabs / etc)
   ↓
Audio Output
```

---

## 3. 핵심 아이디어

### ✔ 1) 문장을 “그냥 텍스트”가 아니라 “호흡 단위”로 쪼갠다

기존:
나는 오늘 성공했다. 그리고 모든 일이 잘 풀린다.

변환:
[나는 오늘 성공했다] / (짧은 정적)
[그리고] / [모든 일이 잘 풀린다]

---

### ✔ 2) 감정 상태(State Machine)

```ts
enum VoiceState {
  NORMAL = "normal",
  AFFIRMATION = "affirmation",
  SLEEP = "sleep",
  ALARM = "alarm",
  FOCUS = "focus"
}
```

| 상태 | 속도 | 톤 | pause |
|------|------|----|-------|
| NORMAL | 0.95 | neutral | 300ms |
| AFFIRMATION | 0.85 | warm | 500ms |
| SLEEP | 0.6 | soft | 800ms |
| ALARM | 1.2 | sharp | 150ms |
| FOCUS | 0.9 | flat | 250ms |

---

## 4. Apple TTS (AVSpeechSynthesizer) 구현

```swift
import AVFoundation

class TTSManager {
    let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String, state: VoiceState) {
        let utterance = AVSpeechUtterance(string: text)

        switch state {
        case .AFFIRMATION:
            utterance.rate = 0.45
            utterance.pitchMultiplier = 1.1
            utterance.volume = 1.0

        case .SLEEP:
            utterance.rate = 0.35
            utterance.pitchMultiplier = 0.9

        case .ALARM:
            utterance.rate = 0.55
            utterance.pitchMultiplier = 1.4

        default:
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
        }

        utterance.postUtteranceDelay = 0.4

        synthesizer.speak(utterance)
    }
}
```

---

## 5. 자연스럽게 만드는 핵심 로직

### 문장 분리

```ts
function preprocess(text: string): string[] {
  return text
    .split(/[.!?]/)
    .map(s => s.trim())
    .filter(Boolean)
}
```

---

### 호흡 삽입

```ts
function injectPauses(sentences: string[]): string[] {
  const result = []

  for (const s of sentences) {
    result.push(s)

    if (s.length > 20) {
      result.push("<break time='500ms'/>")
    }
  }

  return result
}
```

---

### 확언 강조

```ts
function emphasizeAffirmation(text: string): string {
  return text
    .replace(/나는/g, "나는,")
    .replace(/이미/g, "이미...")
}
```

---

## 6. SSML 버전

```xml
<speak>
  <prosody rate="slow" pitch="+2st">
    나는 이미 성공한 사람이다
  </prosody>

  <break time="700ms"/>

  <prosody rate="medium">
    모든 일이 자연스럽게 풀리고 있다
  </prosody>
</speak>
```

---

## 7. 알람 / 자장가

### Alarm
- 속도 증가
- pitch 상승
- 반복

```ts
function alarmWave(text: string) {
  return {
    rate: [0.7, 0.9, 1.1],
    pitch: [1.0, 1.2, 1.4],
    repeat: 2
  }
}
```

---

### Sleep

```ts
function sleepify(text: string) {
  return text
    .split(".")
    .map(s => `${s}...`)
    .join(" <break time='900ms'/> ")
}
```

---

## 8. 구조 핵심

❌ text → TTS 바로 전달  
✅ text → 의미 분석 → 감정 → 리듬 → TTS

---

## 9. 핵심 요약

- 문장은 의미 단위로 쪼갠다
- 감정 상태에 따라 voice 바뀐다
- pause가 절반이다
