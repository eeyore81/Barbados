import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var store: AttractViewModel

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.02, blue: 0.14),
                        Color(red: 0.07, green: 0.05, blue: 0.2),
                        Color(red: 0.04, green: 0.03, blue: 0.16)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                RadialGradient(gradient: Gradient(colors: [Cosmic.cosmicTeal.opacity(0.12), Color.clear]), center: .topTrailing, startRadius: 10, endRadius: 300).blendMode(.screen)
                RadialGradient(gradient: Gradient(colors: [Cosmic.twilight.opacity(0.15), Color.clear]), center: .bottomLeading, startRadius: 20, endRadius: 350).blendMode(.screen)
                StarfieldView().opacity(0.3)

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 6) {
                            Text("🌌 우주 리포트")
                                .font(.title2.weight(.bold)).foregroundColor(Cosmic.starlight)
                            Text("당신의 에너지가 쌓이는 방식")
                                .font(.subheadline).foregroundColor(Cosmic.textTertiary)
                        }.padding(.top, 16)

                        topRow
                        affirmationSection
                        weeklyHeatmap
                    }.padding()
                }
            }
        }
    }

    private var topRow: some View {
        HStack(spacing: 12) {
            metricCard(icon: "heart.fill", iconColor: Color.pink, value: "\(store.gratitudeStreak)일", label: "감사 연속")
            metricCard(icon: "sparkles", iconColor: Cosmic.goldDust, value: "\(store.gratitudeCount)개", label: "총 감사")
            metricCard(icon: "waveform.path.ecg", iconColor: Cosmic.cosmicTeal, value: "\(store.meditationSessionCount)회", label: "명상")
        }
    }

    private func metricCard(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(iconColor)
            Text(value).font(.title3.weight(.bold)).foregroundColor(Cosmic.starlight)
            Text(label).font(.caption2).foregroundColor(Cosmic.textTertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(LinearGradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
        .cornerRadius(16)
    }

    private var affirmationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "book.fill").foregroundColor(Cosmic.cosmicTeal)
                Text("확언 카테고리").font(.headline).foregroundColor(Cosmic.starlight)
                Spacer()
                Text("\(store.totalSelectedAffirmations)개 선택됨").font(.caption).foregroundColor(Cosmic.cosmicTeal)
            }
            let maxCount = store.affirmationCategoryDistribution.map(\.1).max() ?? 1
            ForEach(store.affirmationCategoryDistribution, id: \.0) { state, count in
                HStack(spacing: 10) {
                    Text(state.emoji).font(.system(size: 14))
                    Text(state.rawValue).font(.caption).foregroundColor(Cosmic.textSecondary).frame(width: 65, alignment: .leading)
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.06)).frame(height: 8)
                        Capsule()
                            .fill(count > 0 ? Cosmic.twilight.opacity(0.7) : Color.white.opacity(0.03))
                            .frame(width: max(CGFloat(count) / CGFloat(max(maxCount, 1)) * 140, count > 0 ? 8 : 0), height: 8)
                    }
                    Text("\(count)").font(.caption2.weight(.bold)).foregroundColor(count > 0 ? Cosmic.starlight : Cosmic.textTertiary).frame(width: 20)
                }
            }
        }
        .padding()
        .background(LinearGradient(colors: [Color.white.opacity(0.05), Cosmic.mysticIndigo.opacity(0.12), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Cosmic.cosmicTeal.opacity(0.15), lineWidth: 1))
        .cornerRadius(18)
    }

    private var weeklyHeatmap: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "calendar").foregroundColor(Cosmic.iceBlue)
                Text("최근 7일 감사").font(.headline).foregroundColor(Cosmic.starlight)
            }
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { daysAgo in
                    let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
                    let dayStart = Calendar.current.startOfDay(for: date)
                    let count = store.logs.filter { $0.type == .gratitude && Calendar.current.startOfDay(for: $0.date) == dayStart }.count
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(count > 0 ? Cosmic.goldDust.opacity(0.3 + Double(min(count, 5)) * 0.14) : Color.white.opacity(0.05))
                                .frame(width: 32, height: 32)
                            if count > 0 {
                                Text("\(count)").font(.caption2.weight(.bold)).foregroundColor(Cosmic.goldDust)
                            }
                        }
                        Text(dayLabel(date)).font(.system(size: 9)).foregroundColor(Cosmic.textTertiary)
                    }.frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(LinearGradient(colors: [Color.white.opacity(0.05), Cosmic.voidBlue.opacity(0.1), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Cosmic.iceBlue.opacity(0.15), lineWidth: 1))
        .cornerRadius(18)
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}
