import Foundation
import SwiftUI
import Combine
import AVFoundation
import UserNotifications

// MARK: - Speech Synthesizer Delegate
final class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onDidFinish: (() -> Void)?
    var onDidCancel: (() -> Void)?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onDidFinish?()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onDidCancel?()
    }
}

final class AttractViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var affirmations: [Affirmation] = []
    @Published var actions: [ActionTrigger] = []
    @Published var logs: [LogEntry] = []
    @Published var selectedTab: Tab = .meditation
    @Published var goalsSplit: [GoalCategory: [String]] = [:]
    @Published var currentStreak = 0
    @Published var currentConfidence = 60
    @Published var erudaStateSets: [ErudaStateSet] = []
    @Published var customErudaSets: [CustomErudaSet] = []
    @Published var notificationAffirmations: [NotificationAffirmation] = []
    @Published var currentPlayingStateId: UUID?
    @Published var isPlayingCustom: Bool = false
    @Published var selectedErudaState: ErudaState = .wealth
    @Published var meditationSessionCount: Int = 0
    @Published var affirmationSelections: [ErudaState: AffirmationSelection] = [:]
    @Published var isRandomPlay: Bool = false
    @Published var userAffirmations: [ErudaState: [String]] = [:] {
        didSet { saveUserAffirmations() }
    }

    private var speechSynthesizer = AVSpeechSynthesizer()
    private var speechSynthesizerDelegate: SpeechSynthesizerDelegate?
    private var isSynthesizerReady = true
    private var pendingUtterances: [AVSpeechUtterance] = []
    private var isSpeakingCancelled = false
    private var synthesizer: AVSpeechSynthesizer?
    
    // 루프 재생용 상태
    private var loopText: String?
    private var loopVoiceState: VoiceState?
    private var isLoopEnabled = true
    private var pendingChunkCount: Int = 0
    private var finishedChunkCount: Int = 0
    enum Tab {
        case meditation, affirmations, gratitude, logs, eruda, analysis, more
    }

    enum VoiceState {
        case normal, affirmation, sleep, alarm, focus

        var rate: Float {
            switch self {
            case .normal: return 0.50
            case .affirmation: return 0.45
            case .sleep: return 0.35
            case .alarm: return 0.55
            case .focus: return 0.48
            }
        }

        var pitch: Float {
            switch self {
            case .normal: return 1.0
            case .affirmation: return 1.2
            case .sleep: return 0.9
            case .alarm: return 1.4
            case .focus: return 1.0
            }
        }

        var postDelay: TimeInterval {
            switch self {
            case .normal: return 0.30
            case .affirmation: return 2.0
            case .sleep: return 0.75
            case .alarm: return 0.15
            case .focus: return 0.25
            }
        }
    }

    init() {
        setupSpeechSynthesizer()
        requestNotificationAuthorization()
        loadSavedData()
    }

    private func setupSpeechSynthesizer() {
        // Configure audio session for TTS playback
        configureAudioSessionForTTS()

        let delegate = SpeechSynthesizerDelegate()
        delegate.onDidCancel = { [weak self] in
            DispatchQueue.main.async {
                self?.isSynthesizerReady = true
                self?.isSpeakingCancelled = false
                self?.pendingUtterances.removeAll()
            }
        }
        delegate.onDidFinish = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self, self.isLoopEnabled, !self.isSpeakingCancelled else {
                    self?.isSynthesizerReady = true
                    return
                }
                self.finishedChunkCount += 1
                // 모든 청크가 끝나야만 루프 재생
                if self.finishedChunkCount >= self.pendingChunkCount {
                    self.finishedChunkCount = 0
                    self.pendingChunkCount = 0
                    self.isSynthesizerReady = true
                    if let text = self.loopText, let voiceState = self.loopVoiceState {
                        self.speakText(text, voiceState: voiceState)
                    }
                }
            }
        }
        speechSynthesizerDelegate = delegate
        speechSynthesizer.delegate = delegate
        isSynthesizerReady = true
        isSpeakingCancelled = false
        pendingUtterances.removeAll()
    }

    private func configureAudioSessionForTTS() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session for TTS: \(error)")
        }
    }

    private func activateAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session activation failed: \(error)")
        }
    }

    private func resetSynthesizer() {
        isSpeakingCancelled = true
        speechSynthesizer.stopSpeaking(at: .immediate)
        pendingUtterances.removeAll()
        // Create a brand new synthesizer to fully reset the state
        speechSynthesizer = AVSpeechSynthesizer()
        setupSpeechSynthesizer()
        // Re-activate audio session after reset
        activateAudioSession()
    }

    // MARK: - Persistence (UserDefaults)
    private func saveUserAffirmations() {
        if let encoded = try? JSONEncoder().encode(userAffirmations) {
            UserDefaults.standard.set(encoded, forKey: "userAffirmations")
        }
    }
    
    private func loadUserAffirmations() -> [ErudaState: [String]] {
        guard let data = UserDefaults.standard.data(forKey: "userAffirmations"),
              let decoded = try? JSONDecoder().decode([ErudaState: [String]].self, from: data) else {
            return [:]
        }
        return decoded
    }
    
    private func saveCustomErudaSets() {
        if let encoded = try? JSONEncoder().encode(customErudaSets) {
            UserDefaults.standard.set(encoded, forKey: "customErudaSets")
        }
    }

    private func loadCustomErudaSets() -> [CustomErudaSet] {
        guard let data = UserDefaults.standard.data(forKey: "customErudaSets"),
              let decoded = try? JSONDecoder().decode([CustomErudaSet].self, from: data) else {
            return []
        }
        return decoded
    }

    private func saveNotificationAffirmations() {
        if let encoded = try? JSONEncoder().encode(notificationAffirmations) {
            UserDefaults.standard.set(encoded, forKey: "notificationAffirmations")
        }
    }

    private func loadNotificationAffirmations() -> [NotificationAffirmation] {
        guard let data = UserDefaults.standard.data(forKey: "notificationAffirmations"),
              let decoded = try? JSONDecoder().decode([NotificationAffirmation].self, from: data) else {
            return []
        }
        return decoded
    }

    private func saveAffirmationSelections() {
        let selectionsArray = Array(affirmationSelections.values)
        if let encoded = try? JSONEncoder().encode(selectionsArray) {
            UserDefaults.standard.set(encoded, forKey: "affirmationSelections")
        }
    }

    private func loadAffirmationSelections() -> [ErudaState: AffirmationSelection] {
        guard let data = UserDefaults.standard.data(forKey: "affirmationSelections"),
              let decoded = try? JSONDecoder().decode([AffirmationSelection].self, from: data) else {
            return [:]
        }
        var dict: [ErudaState: AffirmationSelection] = [:]
        for selection in decoded {
            dict[selection.state] = selection
        }
        return dict
    }

    private func loadSavedData() {
        // Load saved custom sets
        let savedCustomSets = loadCustomErudaSets()
        customErudaSets = savedCustomSets
        
        // Load saved notification affirmations
        notificationAffirmations = loadNotificationAffirmations()
        
        // Load saved affirmation selections
        affirmationSelections = loadAffirmationSelections()
        
        // Load saved user affirmations
        userAffirmations = loadUserAffirmations()
        
        // Always load eruda state sets (built-in)
        erudaStateSets = createErudaData()
        
        // Load saved logs
        logs = loadLogs()
        
        // Load meditation count
        meditationSessionCount = UserDefaults.standard.integer(forKey: "meditationSessionCount")
        
        // Load sample data for other features (only if no saved logs exist)
        loadSampleData()
    }

    // MARK: - Log Persistence
    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(encoded, forKey: "savedLogs")
        }
    }
    
    private func loadLogs() -> [LogEntry] {
        guard let data = UserDefaults.standard.data(forKey: "savedLogs"),
              let decoded = try? JSONDecoder().decode([LogEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    private func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error:", error)
            }
            print("Notification authorization granted:", granted)
        }
    }

    func loadSampleData() {
        goals = [
            Goal(title: "월 500만원 만들기", target: "6개월 내 월 500만원", deadline: Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date(), mode: "콘텐츠+네트워크", categories: [.mindset, .action, .environment])
        ]

        affirmations = [
            Affirmation(original: "나는 성공할 것이다", improved: "나는 이미 매일 고객과 연결하고 있다", recordedAt: nil, audioAssetName: nil)
        ]

        actions = [
            ActionTrigger(title: "오늘 1명에게 연락하기", detail: "잠재 고객 또는 멘토에게 DM 보내기", dueDate: Date(), isComplete: false, rewardText: "도파민 +1", points: 15),
            ActionTrigger(title: "지원서 1개 제출하기", detail: "오늘 마감 지원서 점검", dueDate: Date(), isComplete: false, rewardText: "실행력 +2", points: 20),
            ActionTrigger(title: "콘텐츠 1개 업로드", detail: "오늘 1개 영상 또는 글 업로드", dueDate: Date(), isComplete: false, rewardText: "운 레벨 상승", points: 25)
        ]

        // Only set sample logs if no saved logs exist
        if logs.isEmpty {
            logs = [
                LogEntry(date: Date(), type: .positive, title: "새로운 콜라보 제안", description: "예상치 못한 DM으로 파트너 제안이 들어옴", emotion: .confident, tags: ["기회", "네트워크"]),
                LogEntry(date: Date(), type: .gratitude, title: "감사한 사람에게 메시지", description: "오늘 도와준 친구에게 감사 메시지를 보냈다", emotion: .calm, tags: ["감사"]),
                LogEntry(date: Date(), type: .emotion, title: "기대감 상승", description: "시도할 때 불안하지만 집중감이 좋음", emotion: .motivated, tags: ["심리", "집중"])
            ]
        }

        // Initialize Eruda State Sets
        erudaStateSets = createErudaData()

        splitCurrentGoals()
    }

    func createErudaData() -> [ErudaStateSet] {
        let wealthSet = ErudaStateSet(
            state: .wealth,
            morningAffirmations: [
                "나는 이미 모든 형태의 풍요를 누리고 있다.",
                "나는 무한한 기회 속에서 살아간다.",
                "풍요의 에너지가 내 안으로 흐른다.",
                "나는 이미 부유함을 경험하고 있다.",
                "나는 매일 풍요로움을 받는다.",
                "돈이 내게 자연스럽게 흘러온다."
            ],
            nightAffirmations: [
                "받은 모든 것에 감사한다.",
                "풍요가 나에게 흘러온다는 것을 알고 평화롭게 쉰다.",
                "내 무의식은 쉬는 동안 부를 끌어당긴다.",
                "나는 받은 모든 것에 감사한다.",
                "나는 부유함 속에서 편안히 잔다.",
                "나의 무의식이 풍요를 끌어당긴다."
            ]
        )

        let loveSet = ErudaStateSet(
            state: .love,
            morningAffirmations: [
                "나는 이미 깊이 사랑받고 있다.",
                "나는 다른 사람들과 깊이 연결되어 있다.",
                "사랑의 따뜻함이 나를 감싼다.",
                "나는 이미 사랑받고 있다.",
                "나는 깊은 연결을 경험한다.",
                "사랑이 내 삶 속에 있다."
            ],
            nightAffirmations: [
                "나는 사랑과 애정을 받을 자격이 있다.",
                "나는 자연스럽게 사랑받는 관계를 끌어당긴다.",
                "잠드는 동안 사랑이 나를 통해 흐른다.",
                "나는 사랑받을 자격이 있다.",
                "사랑하는 관계가 내게 온다.",
                "사랑이 나를 통해 흐른다."
            ]
        )

        let calmSet = ErudaStateSet(
            state: .calm,
            morningAffirmations: [
                "나는 이미 평화롭다.",
                "나는 고요한 확신 속에서 살아간다.",
                "나는 차분하고 중심을 잡고 있다.",
                "나는 이미 평온하다.",
                "나는 고요한 가운데 산다.",
                "나는 안정적이고 중심잡혀있다."
            ],
            nightAffirmations: [
                "나는 몸의 모든 긴장을 풀어준다.",
                "내 마음은 평화롭고 고요하다.",
                "나는 깊고 편안한 잠으로 흐른다.",
                "나는 모든 긴장을 놓는다.",
                "내 마음은 고요하다.",
                "나는 깊은 수면으로 빠져든다."
            ]
        )

        let confidenceSet = ErudaStateSet(
            state: .confidence,
            morningAffirmations: [
                "나는 이미 자신감 있고 유능하다.",
                "나는 내 모든 힘 안에서 살아간다.",
                "나는 강하고 확신에 차 있다.",
                "나는 이미 자신감이 넘친다.",
                "나는 내 능력 안에 산다.",
                "나는 강하고 확실하다."
            ],
            nightAffirmations: [
                "나는 오늘 이룬 모든 것을 자랑스럽게 생각한다.",
                "나의 자신감은 밤마다 더 강해진다.",
                "나는 충분한 나로 편안히 쉰다.",
                "나는 오늘의 성취를 자랑한다.",
                "내 자신감은 매일 커진다.",
                "나는 충분한 내가 된다."
            ]
        )

        let healingSet = ErudaStateSet(
            state: .healing,
            morningAffirmations: [
                "나는 이미 온전하고 치유되어 있다.",
                "나는 활기찬 건강 속에서 살아간다.",
                "나는 에너지와 새로움을 느낀다.",
                "나는 이미 온전하고 치유되었다.",
                "나는 활발한 건강 속에 산다.",
                "나는 새롭고 생생하다."
            ],
            nightAffirmations: [
                "내 몸은 쉬는 동안 스스로 치유된다.",
                "나는 모든 고통과 상처를 놓는다.",
                "치유의 빛이 나를 통해 흐른다.",
                "내 몸은 쉬는 동안 치유된다.",
                "나는 모든 상처를 놓는다.",
                "치유의 빛이 나를 통해 흐른다."
            ]
        )

        let sleepSet = ErudaStateSet(
            state: .sleep,
            morningAffirmations: [
                "나는 이미 충분히 쉬었고 상쾌하다.",
                "나는 완벽한 수면 주기를 가진다.",
                "나는 깊은 잠에서 에너지를 얻는다.",
                "나는 이미 잘 쉬었다.",
                "나는 완벽한 수면을 한다.",
                "나는 깊은 휴식을 느낀다."
            ],
            nightAffirmations: [
                "내 눈은 무겁고 고요해진다.",
                "나는 평화롭게 잠으로 빠져든다.",
                "내 수면은 깊고 회복적이며 꿈이 없다.",
                "나는 천천히 잠으로 빠져든다.",
                "나는 평온하게 잔다.",
                "내 수면은 깊고 회복된다."
            ]
        )

        return [wealthSet, loveSet, calmSet, confidenceSet, healingSet, sleepSet]
    }

    func splitGoal(_ text: String) -> [GoalCategory: [String]] {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count > 5 else {
            return [.mindset: ["긍정적이고 현실적인 기대 유지"], .action: ["작은 실행 목표 설계"], .environment: ["성공을 지원하는 주변 환경 만들기"]]
        }

        let basicMindset = "나는 이미 목표를 향해 움직이고 있다"
        let basicAction = "오늘 한 가지 구체적 실행을 완료한다"
        let basicEnvironment = "내가 생산적인 상태가 될 수 있는 환경을 만든다"

        return [
            .mindset: [basicMindset, "매일 결과를 상상하며 집중한다"],
            .action: ["작은 실행을 지금 바로 계획한다", "매주 3개 작업 완료를 목표로 한다"],
            .environment: ["작업 환경을 집중에 맞게 정리한다", "지원 네트워크를 리스트로 만든다"]
        ]
    }

    func splitCurrentGoals() {
        guard let first = goals.first else { return }
        goalsSplit = splitGoal(first.title)
    }

    func improveAffirmation(_ raw: String) -> String {
        let lower = raw.lowercased()
        if lower.contains("나는 성공할 것이다") || lower.contains("될 것이다") {
            return raw.replacingOccurrences(of: "나는 성공할 것이다", with: "나는 이미 성공을 향해 행동하고 있다").replacingOccurrences(of: "될 것이다", with: "하고 있다")
        }
        if lower.contains("나는 할 수 있다") {
            return "나는 이미 오늘 한 가지 중요한 행동을 완료했다"
        }
        return "나는 이미 목표를 향해 지금 행동하고 있다"
    }

    func addGoal(title: String, target: String, deadline: Date, mode: String) {
        let categories: [GoalCategory] = [.mindset, .action, .environment]
        let newGoal = Goal(title: title, target: target, deadline: deadline, mode: mode, categories: categories)
        goals.append(newGoal)
        splitCurrentGoals()
    }

    func addAffirmation(rawText: String) {
        let improved = improveAffirmation(rawText)
        let affirmation = Affirmation(original: rawText, improved: improved, recordedAt: nil, audioAssetName: nil)
        affirmations.insert(affirmation, at: 0)
    }

    func addLog(type: LogType, title: String, description: String, emotion: EmotionType?) {
        let entry = LogEntry(date: Date(), type: type, title: title, description: description, emotion: emotion, tags: [])
        logs.insert(entry, at: 0)
        saveLogs()
    }

    func toggleActionCompletion(_ action: ActionTrigger) {
        guard let index = actions.firstIndex(where: { $0.id == action.id }) else { return }
        actions[index].isComplete.toggle()
        if actions[index].isComplete {
            currentStreak += 1
            currentConfidence = min(100, currentConfidence + 3)
        } else {
            currentStreak = max(0, currentStreak - 1)
            currentConfidence = max(0, currentConfidence - 2)
        }
    }

    func progressScore() -> Double {
        let completed = actions.filter { $0.isComplete }.count
        let total = max(1, actions.count)
        return Double(completed) / Double(total)
    }

    func currentLevel() -> String {
        switch currentConfidence {
        case 0..<30: return "Seed"
        case 30..<55: return "Awakening"
        case 55..<75: return "Momentum"
        default: return "Flow"
        }
    }

    func analyticsSnapshot() -> AnalyticsSnapshot {
        let positive = logs.filter { $0.type == .positive || $0.type == .gratitude }.count
        let opportunity = logs.filter { $0.type == .opportunity }.count
        let confidence = currentConfidence
        return AnalyticsSnapshot(completedActions: actions.filter { $0.isComplete }.count, positiveLogs: positive, opportunityLogs: opportunity, confidenceScore: confidence, streakDays: currentStreak)
    }

    func chanceTrendText() -> String {
        let snapshot = analyticsSnapshot()
        if snapshot.completedActions > 2 && snapshot.opportunityLogs > 1 {
            return "행동을 늘리면 기회가 더 자주 생기는 패턴입니다."
        }
        if snapshot.positiveLogs > 1 {
            return "긍정 사건 기록이 많을수록 자신감이 상승합니다."
        }
        return "오늘 실행을 추가하면 운 레벨이 빠르게 올라갑니다."
    }

    // MARK: - Meditation Session
    func incrementMeditationSession() {
        meditationSessionCount += 1
        UserDefaults.standard.set(meditationSessionCount, forKey: "meditationSessionCount")
        objectWillChange.send()
    }

    // MARK: - Analytics
    var gratitudeCount: Int {
        logs.filter { $0.type == .gratitude }.count
    }

    var gratitudeStreak: Int {
        let gratitudeDates = Set(logs.filter { $0.type == .gratitude }.map { Calendar.current.startOfDay(for: $0.date) })
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())
        while gratitudeDates.contains(currentDate) {
            streak += 1
            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        return streak
    }

    var thisWeekGratitudeCount: Int {
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return logs.filter { $0.type == .gratitude && $0.date >= startOfWeek }.count
    }

    var thisWeekLogCount: Int {
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return logs.filter { $0.type != .gratitude && $0.date >= startOfWeek }.count
    }

    var emotionDistribution: [(EmotionType, Int)] {
        var counts: [EmotionType: Int] = [:]
        for log in logs {
            if let emotion = log.emotion {
                counts[emotion, default: 0] += 1
            }
        }
        return EmotionType.allCases.map { ($0, counts[$0] ?? 0) }.sorted { $0.1 > $1.1 }
    }

    var mostFrequentEmotion: EmotionType? {
        emotionDistribution.first(where: { $0.1 > 0 })?.0
    }

    var affirmationCategoryDistribution: [(ErudaState, Int)] {
        ErudaState.allCases.map { state in
            (state, affirmationSelections[state]?.selectedAffirmations.count ?? 0)
        }.sorted { $0.1 > $1.1 }
    }

    var totalSelectedAffirmations: Int {
        affirmationSelections.values.reduce(0) { $0 + $1.selectedAffirmations.count }
    }

    var recentActivityDays: [Date] {
        let sorted = logs.map { Calendar.current.startOfDay(for: $0.date) }
        return Array(Set(sorted)).sorted(by: >)
    }

    // MARK: - Eruda (이루다) Methods
    func playAffirmations(stateSet: ErudaStateSet, mode: ErudaMode) {
        currentPlayingStateId = stateSet.id
        let affirmations = mode == .morning ? stateSet.morningAffirmations : stateSet.nightAffirmations
        let voiceState = voiceState(for: stateSet, mode: mode)
        let text = affirmations.joined(separator: "\n")
        speakText(text, voiceState: voiceState)
    }

    func playSelectedAffirmations() {
        // 모든 선택된 확언을 ErudaState 순서대로 수집
        var allTexts: [String] = []
        for state in ErudaState.allCases {
            if let selection = affirmationSelections[state] {
                allTexts.append(contentsOf: selection.selectedAffirmations)
            }
        }
        
        guard !allTexts.isEmpty else { return }
        
        // 랜덤 재생 옵션
        if isRandomPlay {
            allTexts.shuffle()
        }
        
        // 각 확언을 온점+공백으로 연결 (이미 .로 끝나면 중복 . 방지)
        let cleanedTexts = allTexts.map { $0.hasSuffix(".") ? String($0.dropLast()) : $0 }
        let text = cleanedTexts.joined(separator: ". ")
        speakText(text, voiceState: .affirmation)
        isPlayingCustom = true
        objectWillChange.send()
    }

    func toggleAffirmationSelection(state: ErudaState, affirmation: String) {
        var selection = affirmationSelections[state] ?? AffirmationSelection(state: state)
        
        if selection.selectedAffirmations.contains(affirmation) {
            selection.selectedAffirmations.removeAll { $0 == affirmation }
        } else {
            selection.selectedAffirmations.append(affirmation)
        }
        
        affirmationSelections[state] = selection
        saveAffirmationSelections()
        objectWillChange.send()
    }

    func selectAllAffirmations(for state: ErudaState) {
        guard let stateSet = erudaStateSets.first(where: { $0.state == state }) else { return }
        let all = stateSet.morningAffirmations + stateSet.nightAffirmations
        var selection = affirmationSelections[state] ?? AffirmationSelection(state: state)
        selection.selectedAffirmations = all
        affirmationSelections[state] = selection
        saveAffirmationSelections()
        objectWillChange.send()
    }

    func deselectAllAffirmations(for state: ErudaState) {
        var selection = affirmationSelections[state] ?? AffirmationSelection(state: state)
        selection.selectedAffirmations = []
        affirmationSelections[state] = selection
        saveAffirmationSelections()
        objectWillChange.send()
    }

    func toggleMeditationBg(for state: ErudaState) {
        var selection = affirmationSelections[state] ?? AffirmationSelection(state: state)
        selection.isMeditationBgEnabled.toggle()
        affirmationSelections[state] = selection
        saveAffirmationSelections()
        objectWillChange.send()
    }
    
    func setMeditationBg(for state: ErudaState, enabled: Bool) {
        var selection = affirmationSelections[state] ?? AffirmationSelection(state: state)
        selection.isMeditationBgEnabled = enabled
        affirmationSelections[state] = selection
        saveAffirmationSelections()
        objectWillChange.send()
    }

    func isAffirmationSelected(state: ErudaState, affirmation: String) -> Bool {
        affirmationSelections[state]?.selectedAffirmations.contains(affirmation) ?? false
    }
    
    func addUserAffirmation(state: ErudaState, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var current = userAffirmations[state] ?? []
        current.append(trimmed)
        userAffirmations[state] = current
        objectWillChange.send()
    }

    func getSelection(for state: ErudaState) -> AffirmationSelection {
        affirmationSelections[state] ?? AffirmationSelection(state: state)
    }

    // MARK: - TTS → Audio File Export (모든 선택된 확언 통합 저장)

    /// 리스트에 표시된 순서(유저 확언 → 내장 확언)대로 선택된 확언을 반환
    private func selectedAffirmationsInListOrder(for state: ErudaState) -> [String] {
        let userAdded = userAffirmations[state] ?? []
        let builtIn = erudaStateSets.first(where: { $0.state == state }).map { $0.morningAffirmations + $0.nightAffirmations } ?? []
        let fullList = userAdded + builtIn
        return fullList.filter { affirmationSelections[state]?.selectedAffirmations.contains($0) ?? false }
    }
    
    /// 현재 UserDefaults에 저장된 모든 확언 중 selectedAffirmations 전부를 리스트 순서대로 모아 텍스트 반환
    var allSelectedAffirmationsText: String {
        var allTexts: [String] = []
        for state in ErudaState.allCases {
            allTexts.append(contentsOf: selectedAffirmationsInListOrder(for: state))
        }
        // 중복 점 방지: 이미 .로 끝나는 경우去掉尾部 점
        let cleaned = allTexts.map { $0.hasSuffix(".") ? String($0.dropLast()) : $0 }
        let raw = cleaned.joined(separator: ". ")
        let chunks = speakingChunks(from: raw)
        return chunks.joined(separator: ". ")
    }
    
    /// 모든 카테고리에서 선택된 확언들을 하나의 WAV 파일로 저장
    private var savedAudioFileName: String? {
        get { UserDefaults.standard.string(forKey: "savedAudioFileName") }
        set { UserDefaults.standard.set(newValue, forKey: "savedAudioFileName") }
    }
    
    func exportAllSelectedAffirmationsToAudio(completion: @escaping (Bool) -> Void) {
        let fullText = allSelectedAffirmationsText
        guard !fullText.isEmpty else {
            completion(false)
            return
        }
        
        // 파일명
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let fileName = "Eruda_All_\(timestamp).wav"
        
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            completion(false)
            return
        }
        
        let fileURL = documentsDir.appendingPathComponent(fileName)
        
        // 기존 저장된 파일 삭제
        if let oldFileName = savedAudioFileName {
            let oldFileURL = documentsDir.appendingPathComponent(oldFileName)
            try? FileManager.default.removeItem(at: oldFileURL)
        }
        
        // async Task로 TTS 생성 및 저장
        Task {
            let success = await exportTTS(text: fullText, to: fileURL)
            
            if success {
                DispatchQueue.main.async {
                    self.savedAudioFileName = fileName
                    self.objectWillChange.send()
                    completion(true)
                }
            } else {
                DispatchQueue.main.async { completion(false) }
            }
        }
    }
    
    func getSavedAudioURL() -> URL? {
        guard let fileName = savedAudioFileName,
              let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let fileURL = documentsDir.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    func deleteSavedAudio() {
        guard let fileName = savedAudioFileName,
              let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let fileURL = documentsDir.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
        savedAudioFileName = nil
        objectWillChange.send()
    }
    
    private func exportTTS(text: String, to url: URL) async -> Bool {
        // 오디오 세션 활성화
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.mixWithOthers, .defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("AudioSession: \(error)")
        }
        
        // 한국어 음성 확인
        guard AVSpeechSynthesisVoice(language: "ko-KR") != nil else {
            print("❌ 한국어 음성 없음")
            return false
        }
        
        return await withCheckedContinuation { [self] continuation in
            // 클래스 변수 synthesizer 사용 (write() 콜백 중 메모리 해제 방지)
            synthesizer = AVSpeechSynthesizer()
            guard let exportSynth = synthesizer else {
                continuation.resume(returning: false)
                return
            }
            
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
            utterance.rate = 0.45
            utterance.pitchMultiplier = 1.2
            utterance.volume = 1.0
            
            // 표준 WAV 포맷: 16-bit Integer PCM
            // ※ 실제 TTS 엔진 샘플레이트를 사용 (고정 44100이 아님)
            var sampleRate: Double = 44100.0  // 기본값
            let numChannels: UInt32 = 1
            let bitsPerSample: UInt32 = 16
            
            var allFloatSamples = [Float]()
            var isFinished = false
            var writeError: Error?
            
            // 타임아웃 60초 (TTS가 길 경우 대비)
            let timeoutWork = DispatchWorkItem {
                guard !isFinished else { return }
                isFinished = true
                print("⚠️ TTS write timeout")
                continuation.resume(returning: false)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: timeoutWork)
            
            exportSynth.write(utterance) { buffer in
                guard !isFinished else { return }
                
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
                    print("⚠️ Buffer is not AVAudioPCMBuffer: \(type(of: buffer))")
                    return
                }
                
                let frameLength = pcmBuffer.frameLength
                
                // 첫 버퍼에서 실제 샘플레이트를 읽어옴
                if sampleRate == 44100.0 && frameLength > 0 {
                    sampleRate = pcmBuffer.format.sampleRate
                    print("📢 Actual TTS sampleRate: \(sampleRate)")
                }
                
                // frameLength == 0 → 종료 신호
                guard frameLength > 0 else {
                    isFinished = true
                    timeoutWork.cancel()
                    
                    if let error = writeError {
                        print("❌ TTS write error: \(error)")
                        continuation.resume(returning: false)
                        return
                    }
                    
                    guard !allFloatSamples.isEmpty else {
                        print("❌ No audio samples collected")
                        continuation.resume(returning: false)
                        return
                    }
                    
                    // Float samples를 Int16으로 변환하여 표준 WAV 파일 작성
                    do {
                        try self.writeStandardWAV(
                            to: url,
                            samples: allFloatSamples,
                            sampleRate: sampleRate,
                            numChannels: numChannels,
                            bitsPerSample: bitsPerSample
                        )
                        print("✅ WAV file written successfully: \(url.lastPathComponent)")
                        continuation.resume(returning: true)
                    } catch {
                        print("❌ WAV write error: \(error)")
                        continuation.resume(returning: false)
                    }
                    return
                }
                
                // Float PCM 데이터 수집
                if let floatData = pcmBuffer.floatChannelData {
                    let channelData = floatData[0]
                    for i in 0..<Int(frameLength) {
                        allFloatSamples.append(channelData[i])
                    }
                }
            }
        }
    }
    
    /// 표준 WAV 파일 (16-bit Integer PCM)을 직접 작성합니다.
    private func writeStandardWAV(to url: URL, samples: [Float], sampleRate: Double, numChannels: UInt32, bitsPerSample: UInt32) throws {
        let numSamples = samples.count
        let bytesPerSample = bitsPerSample / 8
        let blockAlign = numChannels * bytesPerSample
        let byteRate = UInt32(sampleRate) * blockAlign
        let dataSize = UInt32(numSamples) * blockAlign
        let fileSize = 36 + dataSize // 4(Riff) + 4(size) + 8(WAVE + fmt ) + 16(fmt) + 8(data + size)
        
        // Int16으로 변환 (clamping)
        var intSamples = [Int16]()
        intSamples.reserveCapacity(numSamples)
        for sample in samples {
            // Float [-1.0, 1.0] → Int16 [-32768, 32767]
            var clamped = sample
            if clamped > 1.0 { clamped = 1.0 }
            if clamped < -1.0 { clamped = -1.0 }
            let intVal = Int16(clamped * Float(Int16.max))
            intSamples.append(intVal)
        }
        
        let data = Data(bytes: intSamples, count: intSamples.count * MemoryLayout<Int16>.size)
        
        guard let fileHandle = try? FileHandle(forWritingTo: url) else {
            // 파일이 없으면 생성
            FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
            guard let fileHandle = try? FileHandle(forWritingTo: url) else {
                throw NSError(domain: "WAVWriter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot create file"])
            }
            defer { fileHandle.closeFile() }
            
            try writeWAVHeader(to: fileHandle, fileSize: fileSize, sampleRate: UInt32(sampleRate), numChannels: numChannels, bitsPerSample: bitsPerSample, dataSize: dataSize)
            fileHandle.write(data)
            return
        }
        
        defer { fileHandle.closeFile() }
        
        // 기존 파일 덮어쓰기
        fileHandle.truncateFile(atOffset: 0)
        try writeWAVHeader(to: fileHandle, fileSize: fileSize, sampleRate: UInt32(sampleRate), numChannels: numChannels, bitsPerSample: bitsPerSample, dataSize: dataSize)
        fileHandle.write(data)
    }
    
    private func writeWAVHeader(to fileHandle: FileHandle, fileSize: UInt32, sampleRate: UInt32, numChannels: UInt32, bitsPerSample: UInt32, dataSize: UInt32) throws {
        let blockAlign = numChannels * (bitsPerSample / 8)
        let byteRate = sampleRate * blockAlign
        
        var header = Data()
        
        // RIFF header
        header.append("RIFF".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: fileSize.littleEndian) { Data($0) })
        header.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        header.append("fmt ".data(using: .ascii)!)
        let fmtSize: UInt32 = 16
        header.append(withUnsafeBytes(of: fmtSize.littleEndian) { Data($0) })
        let audioFormat: UInt16 = 1 // PCM
        header.append(withUnsafeBytes(of: audioFormat.littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: UInt16(numChannels).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: sampleRate.littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: UInt16(blockAlign).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: UInt16(bitsPerSample).littleEndian) { Data($0) })
        
        // data chunk
        header.append("data".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })
        
        fileHandle.write(header)
    }
    
    func playCustomAffirmations(customSet: CustomErudaSet) {
        isPlayingCustom = true
        let text = customSet.affirmations.joined(separator: "\n")
        speakText(text, voiceState: .affirmation)
    }

    private func voiceState(for stateSet: ErudaStateSet, mode: ErudaMode) -> VoiceState {
        if stateSet.state == .sleep {
            return .sleep
        }
        return mode == .morning ? .affirmation : .focus
    }

    private func speakingChunks(from text: String) -> [String] {
        var result = text
        
        // 1. 특수문자 제거
        result = result.replacingOccurrences(of: "[^가-힣a-zA-Z0-9,.?! ]",
                                             with: "",
                                             options: .regularExpression)
        
        // 2. 쉼표 강화 (호흡 추가)
//        result = result.replacingOccurrences(of: " ", with: ", ")
        
//        // 3. 강조 단어 쉼표 삽입
//        let emphasisWords = ["반드시", "무조건", "이미", "지금"]
//        for word in emphasisWords {
//            result = result.replacingOccurrences(of: word, with: ", \(word), ")
//        }
        
        // 4. 문장 분리
        let sentences = result.components(separatedBy: CharacterSet(charactersIn: ".?!"))
        
        // 5. 짧게 쪼개기
        var finalChunks: [String] = []
        
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            if trimmed.count > 20 {
                let parts = trimmed.split(separator: ",")
                for part in parts {
                    finalChunks.append(String(part))
                }
            } else {
                finalChunks.append(trimmed)
            }
        }
        
        return finalChunks
    }

    func speakText(_ text: String, voiceState: VoiceState) {
        // 루프 재생을 위해 상태 저장
        self.loopText = text
        self.loopVoiceState = voiceState
        self.isLoopEnabled = true
        
        // Always reset synthesizer to fresh state before speaking
        resetSynthesizer()
        isSynthesizerReady = false

        let segments = speakingChunks(from: text)
        guard !segments.isEmpty else {
            isSynthesizerReady = true
            return
        }

        // Track chunk count for loop detection
        self.pendingChunkCount = segments.count
        self.finishedChunkCount = 0

        // Activate audio session explicitly before speaking
        activateAudioSession()

        var utteranceArray: [AVSpeechUtterance] = []
        for (index, segment) in segments.enumerated() {
            let utterance = AVSpeechUtterance(string: segment)
            utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
            utterance.rate = voiceState.rate
            utterance.pitchMultiplier = voiceState.pitch
            utterance.volume = 0.9
            utterance.postUtteranceDelay = voiceState.postDelay
            if index == segments.count - 1 {
                utterance.postUtteranceDelay = voiceState.postDelay + 0.1
            }
            utteranceArray.append(utterance)
        }

        // Queue all utterances at once for seamless playback
        for utterance in utteranceArray {
            speechSynthesizer.speak(utterance)
        }
    }

    func stopPlayback() {
        // Disable loop BEFORE reset, otherwise resetSynthesizer re-enables it
        isLoopEnabled = false
        loopText = nil
        loopVoiceState = nil
        resetSynthesizer()
        currentPlayingStateId = nil
        isPlayingCustom = false
        objectWillChange.send()
    }

    func addCustomErudaSet(title: String, state: ErudaState, affirmations: [String]) {
        let customSet = CustomErudaSet(title: title, selectedState: state, affirmations: affirmations)
        customErudaSets.insert(customSet, at: 0)
        saveCustomErudaSets()
        objectWillChange.send()
    }
    
    func deleteCustomErudaSet(_ set: CustomErudaSet) {
        customErudaSets.removeAll { $0.id == set.id }
        saveCustomErudaSets()
        objectWillChange.send()
    }

    // MARK: - Alarm (모든 선택된 확언 통합 알람)
    func setAlarmForAllSelected(hour: Int, minute: Int) {
        let allText = allSelectedAffirmationsText
        guard !allText.isEmpty else { return }
        
        // 기존 알람 삭제 후 새로 설정
        for alarm in notificationAffirmations {
            deleteAffirmationAlarm(alarm)
        }
        
        let title = "🧘 이루다 확언"
        setAffirmationAlarm(title: title, affirmations: [allText], hour: hour, minute: minute)
    }

    func removeAllAlarms() {
        for alarm in notificationAffirmations {
            deleteAffirmationAlarm(alarm)
        }
    }
    
    func setAffirmationAlarm(title: String, affirmations: [String], hour: Int, minute: Int) {
        let notification = NotificationAffirmation(
            title: title,
            affirmations: affirmations,
            hour: hour,
            minute: minute,
            isEnabled: true
        )
        notificationAffirmations.insert(notification, at: 0)
        saveNotificationAffirmations()
        scheduleLocalNotification(notification)
    }

    func scheduleLocalNotification(_ notification: NotificationAffirmation) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.affirmations.prefix(1).joined(separator: "")
        content.sound = .default
        content.userInfo = ["affirmations": notification.affirmations.joined(separator: "\n")]

        var dateComponents = DateComponents()
        dateComponents.hour = notification.hour
        dateComponents.minute = notification.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: notification.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("알람 설정 실패: \(error)")
            } else {
                print("알람 설정 성공: \(notification.title)")
            }
        }
    }

    func deleteAffirmationAlarm(_ notification: NotificationAffirmation) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notification.id.uuidString])
        notificationAffirmations.removeAll { $0.id == notification.id }
        saveNotificationAffirmations()
        objectWillChange.send()
    }
}
