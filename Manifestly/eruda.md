from pathlib import Path

content = """# 🧙‍♂️ Manifest App — State Switch (TTS Core PRD v2)

## 1. Product Definition

“A voice-based identity switching system using structured affirmation audio loops.”

- AI 없음  
- Apple TTS 기반  
- 루틴 중심 (알람 + 수면)  
- 감정 변화 = 문장 구조로 설계  

---

## 2. Core Concept

Identity is not generated. It is heard repeatedly until accepted.

핵심 구조:
- 입력 ❌ (거의 없음)
- 생성 ❌
- 선택 ✔
- 반복 ✔✔✔

---

## 3. Core Loop

Morning (Activation)
→ Wake → Affirmation Audio → Lock-in → Start day

Night (Deactivation)
→ Wind down → Slow affirmation → Sleep induction → Fade out

---

## 4. State Packs

- Wealth State
- Love State
- Calm State
- Confidence State
- Healing State
- Sleep State

각 State:
- morning / night 버전 분리
- 10~30개 확언

---

## 5. Affirmation Engine (No AI)

- I am already ___
- I live in ___
- I feel ___
- My life is ___

---

## 6. TTS System (Apple Only)

AVSpeechSynthesizer 기반

Rules:
- short sentences
- line breaks = pauses
- punctuation = rhythm

---

## 7. Morning Alarm Mode

Goal: Identity Activation Alarm

Flow:
1. alarm trigger (local notification)
2. ambient sound
3. TTS start (slow → strong)
4. final affirmation peak
5. stop

Audio example:
You are already enough...
You are already successful...
Today belongs to you.

---

## 8. Night Mode (Sleep System)

Goal: Deactivation + sleep induction

Flow:
- 15–30 min playback
- slow speech
- decreasing sentence