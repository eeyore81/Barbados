import SwiftUI

struct GratitudeView: View {
    @EnvironmentObject var store: AttractViewModel
    @State private var title = ""
    @State private var description = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case title, description
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.02, blue: 0.14),
                        Color(red: 0.06, green: 0.04, blue: 0.2),
                        Color(red: 0.05, green: 0.03, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.6, green: 0.35, blue: 0.2).opacity(0.2), Color.clear
                    ]),
                    center: .topTrailing, startRadius: 20, endRadius: 350
                )
                .blendMode(.screen)

                RadialGradient(
                    gradient: Gradient(colors: [Cosmic.goldDust.opacity(0.1), Color.clear]),
                    center: .bottomLeading, startRadius: 10, endRadius: 300
                )
                .blendMode(.screen)

                StarfieldView().opacity(0.35)

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 6) {
                            Text("💫 감사 일기").font(.title2.weight(.bold)).foregroundColor(Cosmic.starlight)
                            Text("작은 감사가 우주의 큰 선물을 불러옵니다").font(.subheadline).foregroundColor(Cosmic.textTertiary)
                        }.padding(.top, 16)

                        gratitudeInput

                        HStack {
                            CosmicSectionHeader("기록된 감사", icon: "heart.text.square")
                            Spacer()
                            Text("\(store.logs.filter { $0.type == .gratitude }.count)개")
                                .font(.caption).foregroundColor(Cosmic.goldDust)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Cosmic.goldDust.opacity(0.12)).cornerRadius(8)
                        }.padding(.horizontal, 4)

                        gratitudeList
                    }.padding()
                }
                .onTapGesture { focusedField = nil }
            }
        }
    }

    private var gratitudeInput: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "sparkle").foregroundColor(Cosmic.goldDust)
                Text("오늘 감사한 일을 적어보세요").font(.headline).foregroundColor(Cosmic.starlight)
            }
            Text("작은 감사도 마음을 바꾸는 큰 힘이 됩니다").font(.caption).foregroundColor(Cosmic.textTertiary)

            TextField("감사 제목", text: $title)
                .focused($focusedField, equals: .title)
                .textFieldStyle(.plain).padding(12)
                .background(Color.white.opacity(0.08)).cornerRadius(10)
                .foregroundColor(Cosmic.starlight)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Cosmic.goldDust.opacity(0.25), lineWidth: 1))
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("완료") { focusedField = nil }
                    }
                }

            ZStack(alignment: .topLeading) {
                if description.isEmpty {
                    Text("오늘 어떤 일에 감사했나요? 구체적으로 적어보세요...")
                        .foregroundColor(Cosmic.textTertiary).padding(.horizontal, 12).padding(.vertical, 14)
                }
                TextEditor(text: $description)
                    .focused($focusedField, equals: .description)
                    .frame(minHeight: 120).padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.06)).cornerRadius(10)
                    .foregroundColor(Cosmic.starlight)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Cosmic.goldDust.opacity(0.2), lineWidth: 1))
            }

            HStack {
                Spacer()
                Button(action: addGratitude) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill").font(.system(size: 14))
                        Text("감사 기록하기").font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 12).padding(.horizontal, 20)
                    .background(LinearGradient(colors: [Cosmic.warmGold, Color.orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .foregroundColor(.white).cornerRadius(16)
                    .shadow(color: Cosmic.warmGold.opacity(0.3), radius: 10, x: 0, y: 4)
                }
                .disabled(title.isEmpty || description.isEmpty)
                .opacity(title.isEmpty || description.isEmpty ? 0.5 : 1.0)
            }
        }
        .padding()
        .background(LinearGradient(colors: [Color.white.opacity(0.06), Color(red: 0.3, green: 0.15, blue: 0.1).opacity(0.15), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(LinearGradient(colors: [Cosmic.goldDust.opacity(0.3), Cosmic.warmGold.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        .cornerRadius(20)
        .shadow(color: Cosmic.warmGold.opacity(0.1), radius: 16, x: 0, y: 8)
    }

    private var gratitudeList: some View {
        let gratitudes = store.logs.filter { $0.type == .gratitude }
        return VStack(spacing: 12) {
            if gratitudes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart.text.square").font(.system(size: 40)).foregroundColor(Cosmic.textTertiary)
                    Text("아직 기록된 감사가 없어요\n첫 감사를 기록해보세요 ✨").font(.subheadline).foregroundColor(Cosmic.textTertiary).multilineTextAlignment(.center)
                }.padding(.vertical, 40).frame(maxWidth: .infinity)
            } else {
                ForEach(gratitudes) { entry in gratitudeCard(for: entry) }
            }
        }
    }

    private func gratitudeCard(for entry: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.date, format: Date.FormatStyle().year().month(.twoDigits).day(.twoDigits))
                    .font(.caption).foregroundColor(Cosmic.goldDust)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Cosmic.goldDust.opacity(0.12)).cornerRadius(6)
                Spacer()
                if let emotion = entry.emotion {
                    Label(emotion.rawValue, systemImage: emotion.icon).font(.caption).foregroundColor(Cosmic.textAccent)
                }
            }
            Text(entry.title).font(.headline).foregroundColor(Cosmic.starlight)
            Text(entry.description).font(.body).foregroundColor(Cosmic.textSecondary).lineLimit(4)
        }
        .padding()
        .background(LinearGradient(colors: [Color.white.opacity(0.05), Color(red: 0.3, green: 0.18, blue: 0.1).opacity(0.12), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(LinearGradient(colors: [Cosmic.goldDust.opacity(0.2), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    private func addGratitude() {
        guard !title.isEmpty, !description.isEmpty else { return }
        store.addLog(type: .gratitude, title: title, description: description, emotion: nil)
        title = ""
        description = ""
    }
}
