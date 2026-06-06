import SwiftUI

// MARK: - Remaining Views (Goal, Affirmation, Log, More, Action)

struct GoalSetupView: View {
    @EnvironmentObject var store: AttractViewModel
    @State private var title = ""
    @State private var target = ""
    @State private var mode = ""
    @State private var deadline = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()

    var body: some View {
        NavigationView {
            ZStack {
                cosmicPanelBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        goalForm
                        goalSplitSection
                        goalList
                    }
                    .padding()
                }
                .background(Color.clear)
            }
            .navigationTitle("목표 시스템")
        }
    }

    private var goalForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("목표 등록")
                .font(.headline)
                .foregroundColor(Cosmic.starlight)
            TextField("예: 월 500만원 만들기", text: $title)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
                .foregroundColor(Cosmic.starlight)
            TextField("세부 목표 입력", text: $target)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
                .foregroundColor(Cosmic.starlight)
            TextField("실행 방식 입력", text: $mode)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
                .foregroundColor(Cosmic.starlight)
            DatePicker("기한", selection: $deadline, displayedComponents: .date)
                .colorScheme(.dark)
            Button(action: addGoal) {
                Text("목표 생성")
                    .font(.callout.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Cosmic.cosmicTeal, Cosmic.twilight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(color: Cosmic.cosmicTeal.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.05), Cosmic.mysticIndigo.opacity(0.2), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Cosmic.cosmicTeal.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: Cosmic.cosmicTeal.opacity(0.08), radius: 10, x: 0, y: 8)
    }

    private var goalSplitSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("자동 분해")
                .font(.headline)
                .foregroundColor(Cosmic.starlight)
            ForEach(GoalCategory.allCases) { category in
                if let rows = store.goalsSplit[category] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.rawValue)
                            .font(.subheadline.bold())
                            .foregroundColor(category.color)
                        ForEach(rows, id: \.self) { row in
                            HStack(alignment: .top) {
                                Circle()
                                    .frame(width: 6, height: 6)
                                    .foregroundColor(category.color)
                                Text(row)
                                    .font(.caption)
                                    .foregroundColor(Cosmic.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.05), Cosmic.mysticIndigo.opacity(0.15), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Cosmic.cosmicTeal.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: Cosmic.cosmicTeal.opacity(0.06), radius: 14, x: 0, y: 12)
    }

    private var goalList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("현재 목표")
                .font(.headline)
                .foregroundColor(Cosmic.starlight)
            ForEach(store.goals) { goal in
                VStack(alignment: .leading, spacing: 8) {
                    Text(goal.title)
                        .font(.subheadline.bold())
                        .foregroundColor(Cosmic.starlight)
                    Text(goal.target)
                        .font(.caption)
                        .foregroundColor(Cosmic.textSecondary)
                    Text("기한: \(goal.deadline, format: .dateTime.month().day())")
                        .font(.caption2)
                        .foregroundColor(Cosmic.textTertiary)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0.05), Cosmic.mysticIndigo.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Cosmic.cosmicTeal.opacity(0.15), lineWidth: 1)
                )
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.05), Cosmic.twilight.opacity(0.12), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Cosmic.cosmicTeal.opacity(0.12), lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: Cosmic.cosmicTeal.opacity(0.06), radius: 14, x: 0, y: 12)
    }

    private func addGoal() {
        guard !title.isEmpty, !target.isEmpty, !mode.isEmpty else { return }
        store.addGoal(title: title, target: target, deadline: deadline, mode: mode)
        title = ""
        target = ""
        mode = ""
    }
}

// MARK: - Affirmation View
struct AffirmationView: View {
    @EnvironmentObject var store: AttractViewModel
    @State private var newAffirmation = ""

    var body: some View {
        NavigationView {
            ZStack {
                cosmicPanelBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        affirmationInput
                        affirmationList
                    }
                    .padding()
                }
                .background(Color.clear)
            }
            .navigationTitle("확언 쓰기")
        }
    }

    private var affirmationInput: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("확언 작성")
                .font(.headline)
                .foregroundColor(Cosmic.starlight)
            TextField("예: 나는 성공할 것이다", text: $newAffirmation)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
                .foregroundColor(Cosmic.starlight)
            Text(store.improveAffirmation(newAffirmation.isEmpty ? "나는 성공할 것이다" : newAffirmation))
                .font(.caption)
                .foregroundColor(Cosmic.textSecondary)
            HStack {
                Spacer()
                Button(action: addAffirmation) {
                    Text("기록")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 22)
                        .background(
                            LinearGradient(
                                colors: [Cosmic.cosmicTeal, Cosmic.twilight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(18)
                        .shadow(color: Cosmic.cosmicTeal.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.05), Cosmic.mysticIndigo.opacity(0.2), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Cosmic.cosmicTeal.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: Cosmic.cosmicTeal.opacity(0.1), radius: 14, x: 0, y: 12)
    }

    private var affirmationList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("저장된 확언")
                .font(.title3.bold())
                .foregroundColor(Cosmic.starlight)
            ForEach(store.affirmations) { affirmation in
                affirmationCard(for: affirmation)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.05), Cosmic.mysticIndigo.opacity(0.18), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: Cosmic.cosmicTeal.opacity(0.08), radius: 16, x: 0, y: 12)
    }

    private func affirmationCard(for affirmation: Affirmation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(affirmation.original)
                .font(.headline)
                .foregroundColor(Cosmic.starlight)
            Text(affirmation.improved)
                .font(.body)
                .foregroundColor(Cosmic.textSecondary)
        }
        .padding()
        .background(Cosmic.cosmicTeal.opacity(0.1))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
    }

    private func addAffirmation() {
        guard !newAffirmation.isEmpty else { return }
        store.addAffirmation(rawText: newAffirmation)
        newAffirmation = ""
    }
}

// MARK: - Log View
struct LogView: View {
    @EnvironmentObject var store: AttractViewModel
    @State private var selectedType: LogType = .positive
    @State private var title = ""
    @State private var description = ""
    @State private var emotion: EmotionType = .calm
    
    var body: some View {
        NavigationView {
            ZStack {
                cosmicPanelBackground()
                VStack(spacing: 20) {
                    List {
                        ForEach(store.logs.filter { $0.type != .gratitude }) { entry in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .top) {
                                    Text(entry.type.rawValue)
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Cosmic.cosmicTeal.opacity(0.15))
                                        .foregroundColor(Cosmic.cosmicTeal)
                                        .cornerRadius(10)
                                    Spacer()
                                    if let emotion = entry.emotion {
                                        Label(emotion.rawValue, systemImage: emotion.icon)
                                            .font(.caption)
                                            .foregroundColor(Cosmic.textAccent)
                                    }
                                }
                                Text(entry.title)
                                    .font(.title3.weight(.semibold))
                                    .foregroundColor(Cosmic.starlight)
                                Text(entry.description)
                                    .font(.body)
                                    .foregroundColor(Cosmic.textSecondary)
                                    .lineLimit(3)
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.04), Cosmic.mysticIndigo.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                .padding()
            }
            .navigationTitle("끌어당김 로그")
        }
    }
}

// MARK: - More View
struct MoreView: View {
    @EnvironmentObject var store: AttractViewModel

    var body: some View {
        NavigationView {
            ZStack {
                cosmicPanelBackground()
                List {
                    NavigationLink(destination: GoalSetupView()) {
                        Label("목표 시스템", systemImage: "target")
                            .foregroundColor(Cosmic.starlight)
                    }
                    NavigationLink(destination: AnalyticsView()) {
                        Label("Analytics", systemImage: "chart.bar")
                            .foregroundColor(Cosmic.starlight)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
    }
}

// MARK: - Action Trigger List
struct ActionTriggerListView: View {
    @EnvironmentObject var store: AttractViewModel

    var body: some View {
        ZStack {
            cosmicPanelBackground()
            List {
                ForEach(store.actions) { action in
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(action.title)
                                .font(.body.bold())
                                .foregroundColor(Cosmic.starlight)
                            Text(action.detail)
                                .font(.caption)
                                .foregroundColor(Cosmic.textSecondary)
                        }
                        Spacer()
                        if action.isComplete {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Cosmic.cosmicTeal)
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(
                        LinearGradient(
                            colors: [Color.white.opacity(0.04), Cosmic.mysticIndigo.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("행동 트리거")
    }
}
