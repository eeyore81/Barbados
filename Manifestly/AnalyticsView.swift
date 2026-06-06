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
                            Text("📊 데이터 리포트").font(.title2.weight(.bold)).foregroundColor(Cosmic.starlight)
                            Text("행동과 기록이 모여 운의 패턴을 만듭니다").font(.subheadline).foregroundColor(Cosmic.textTertiary)
                        }.padding(.top, 16)

                        levelCard
                        analyticsCards
                        correlationSection()
                        trendCard
                    }.padding()
                }
            }
        }
    }

    private var levelCard: some View {
        let snapshot = store.analyticsSnapshot()
        return HStack(spacing: 16) {
            ZStack {
                Circle().stroke(AngularGradient(colors: [Cosmic.cosmicTeal, Cosmic.twilight, Cosmic.goldDust, Cosmic.cosmicTeal], center: .center), lineWidth: 3).frame(width: 70, height: 70)
                VStack(spacing: 2) {
                    Text("Lv.").font(.system(size: 10, weight: .bold)).foregroundColor(Cosmic.textTertiary)
                    Text(store.currentLevel()).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(Cosmic.starlight)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("현재 운 레벨").font(.subheadline.weight(.semibold)).foregroundColor(Cosmic.starlight)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("자신감").font(.caption).foregroundColor(Cosmic.textSecondary)
                        Spacer()
                        Text("\(snapshot.confidenceScore)%").font(.caption.weight(.bold)).foregroundColor(Cosmic.cosmicTeal)
                    }
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1)).frame(height: 6)
                        Capsule().fill(LinearGradient(colors: [Cosmic.cosmicTeal, Cosmic.twilight], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(4, CGFloat(snapshot.confidenceScore) * 1.8), height: 6)
                            .animation(.easeOut(duration: 0.6), value: snapshot.confidenceScore)
                    }
                }
            }
        }
        .padding()
        .background(LinearGradient(colors: [Color.white.opacity(0.06), Cosmic.mysticIndigo.opacity(0.2), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(LinearGradient(colors: [Cosmic.cosmicTeal.opacity(0.25), Cosmic.twilight.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        .cornerRadius(20)
        .shadow(color: Cosmic.cosmicTeal.opacity(0.1), radius: 12, x: 0, y: 6)
    }

    private var analyticsCards: some View {
        let snapshot = store.analyticsSnapshot()
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            analyticsCard(icon: "checkmark.circle.fill", iconColor: Cosmic.cosmicTeal, title: "완료된 행동", value: "\(snapshot.completedActions)회")
            analyticsCard(icon: "heart.fill", iconColor: Color.pink.opacity(0.9), title: "긍정 기록", value: "\(snapshot.positiveLogs)회")
            analyticsCard(icon: "sparkles", iconColor: Cosmic.goldDust, title: "기회 감지", value: "\(snapshot.opportunityLogs)회")
            analyticsCard(icon: "flame.fill", iconColor: Color.orange, title: "연속 성공", value: "\(snapshot.streakDays)일")
        }
    }

    private func analyticsCard(icon: String, iconColor: Color, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(iconColor)
            Text(title).font(.caption).foregroundColor(Cosmic.textSecondary)
            Text(value).font(.title3.weight(.bold)).foregroundColor(Cosmic.starlight)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding()
        .background(LinearGradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .cornerRadius(16).shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 4)
    }

    private func correlationSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill").foregroundColor(Cosmic.cosmicTeal)
                Text("확률 시각화").font(.headline).foregroundColor(Cosmic.starlight)
            }
            Text("오늘의 행동 패턴과 결과 상관 관계").font(.subheadline).foregroundColor(Cosmic.textTertiary)
            HStack(spacing: 20) {
                barStat(title: "실행력", value: Int(store.progressScore() * 100), color: Cosmic.cosmicTeal)
                barStat(title: "자신감", value: min(100, store.currentConfidence), color: Cosmic.twilight)
            }
        }
        .padding()
        .background(LinearGradient(colors: [Color.white.opacity(0.05), Cosmic.mysticIndigo.opacity(0.15), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(LinearGradient(colors: [Cosmic.cosmicTeal.opacity(0.2), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        .cornerRadius(18)
    }

    private func barStat(title: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.semibold)).foregroundColor(Cosmic.textSecondary)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1)).frame(height: 14)
                Capsule().fill(LinearGradient(colors: [color.opacity(0.8), color], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(6, CGFloat(value) * 2.2), height: 14)
                    .animation(.easeOut(duration: 0.8), value: value)
            }
            Text("\(value)%").font(.caption.weight(.bold)).foregroundColor(color)
        }.frame(maxWidth: .infinity)
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb.fill").foregroundColor(Cosmic.goldDust)
                Text("인사이트").font(.headline).foregroundColor(Cosmic.starlight)
            }
            Text(store.chanceTrendText()).font(.subheadline).foregroundColor(Cosmic.textSecondary).lineSpacing(4)
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color.white.opacity(0.05), Cosmic.goldDust.opacity(0.08), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Cosmic.goldDust.opacity(0.2), lineWidth: 1))
        .cornerRadius(16)
    }
}
