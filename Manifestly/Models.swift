import Foundation
import SwiftUI

enum GoalCategory: String, CaseIterable, Identifiable {
    case mindset = "Mindset"
    case action = "Action"
    case environment = "Environment"

    var id: String { rawValue }
    var color: Color {
        switch self {
        case .mindset: return .purple
        case .action: return .blue
        case .environment: return .green
        }
    }
}

enum LogType: String, CaseIterable, Identifiable, Codable {
    case positive = "Positive"
    case opportunity = "Opportunity"
    case gratitude = "Gratitude"
    case emotion = "Emotion"

    var id: String { rawValue }
}

enum EmotionType: String, CaseIterable, Identifiable, Codable {
    case calm = "Calm"
    case confident = "Confident"
    case anxious = "Anxious"
    case motivated = "Motivated"
    case tired = "Tired"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .calm: return "leaf"
        case .confident: return "star"
        case .anxious: return "flame"
        case .motivated: return "bolt"
        case .tired: return "moon"
        }
    }
}

struct Goal: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var target: String
    var deadline: Date
    var mode: String
    var categories: [GoalCategory]
    var createdAt: Date = Date()
    var isComplete: Bool = false
}

struct Affirmation: Identifiable, Hashable {
    let id = UUID()
    var original: String
    var improved: String
    var recordedAt: Date?
    var audioAssetName: String?
}

struct ActionTrigger: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var detail: String
    var dueDate: Date
    var isComplete: Bool = false
    var rewardText: String
    var points: Int
}

struct LogEntry: Identifiable, Hashable, Codable {
    let id = UUID()
    var date: Date
    var type: LogType
    var title: String
    var description: String
    var emotion: EmotionType?
    var tags: [String]
}

struct AnalyticsSnapshot {
    var completedActions: Int
    var positiveLogs: Int
    var opportunityLogs: Int
    var confidenceScore: Int
    var streakDays: Int
}

// MARK: - Eruda (이루다) Models
enum ErudaState: String, CaseIterable, Identifiable, Codable {
    case wealth = "Wealth"
    case love = "Love"
    case calm = "Calm"
    case confidence = "Confidence"
    case healing = "Healing"
    case sleep = "Sleep"

    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .wealth: return "💰"
        case .love: return "💕"
        case .calm: return "🧘"
        case .confidence: return "⭐"
        case .healing: return "🌿"
        case .sleep: return "😴"
        }
    }
}

enum ErudaMode: String, Codable {
    case morning = "Morning"
    case night = "Night"
}

struct ErudaAffirmation: Identifiable, Hashable {
    let id = UUID()
    var state: ErudaState
    var mode: ErudaMode
    var affirmations: [String]
    var createdAt: Date = Date()
    var isPlaying: Bool = false
}

struct ErudaStateSet: Identifiable, Hashable {
    let id = UUID()
    var state: ErudaState
    var morningAffirmations: [String]
    var nightAffirmations: [String]
}

struct CustomErudaSet: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var selectedState: ErudaState
    var affirmations: [String]
    var createdAt: Date

    init(id: UUID = UUID(), title: String, selectedState: ErudaState, affirmations: [String], createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.selectedState = selectedState
        self.affirmations = affirmations
        self.createdAt = createdAt
    }
}

// MARK: - Affirmation Selection (UserDefaults 저장용)
struct AffirmationSelection: Codable, Hashable {
    var state: ErudaState
    var selectedAffirmations: [String]
    var isAlarmEnabled: Bool
    var alarmHour: Int
    var alarmMinute: Int
    var isMeditationBgEnabled: Bool
    var savedAudioFileName: String?
    
    init(state: ErudaState, selectedAffirmations: [String] = [], isAlarmEnabled: Bool = false, alarmHour: Int = 7, alarmMinute: Int = 0, isMeditationBgEnabled: Bool = false, savedAudioFileName: String? = nil) {
        self.state = state
        self.selectedAffirmations = selectedAffirmations
        self.isAlarmEnabled = isAlarmEnabled
        self.alarmHour = alarmHour
        self.alarmMinute = alarmMinute
        self.isMeditationBgEnabled = isMeditationBgEnabled
        self.savedAudioFileName = savedAudioFileName
    }
}

struct NotificationAffirmation: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var affirmations: [String]
    var state: ErudaState?
    var hour: Int
    var minute: Int
    var isEnabled: Bool = true
    var createdAt: Date = Date()

    init(id: UUID = UUID(), title: String, affirmations: [String], state: ErudaState? = nil, hour: Int, minute: Int, isEnabled: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.affirmations = affirmations
        self.state = state
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}

