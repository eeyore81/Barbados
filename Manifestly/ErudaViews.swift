import SwiftUI
import AVFoundation

// MARK: - ErudaView (이루다 탭)
struct ErudaView: View {
    @EnvironmentObject var store: AttractViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.02, blue: 0.14),
                    Color(red: 0.07, green: 0.04, blue: 0.2),
                    Color(red: 0.04, green: 0.03, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                gradient: Gradient(colors: [
                    Cosmic.twilight.opacity(0.2),
                    Color.clear
                ]),
                center: .top,
                startRadius: 20,
                endRadius: 350
            )
            .blendMode(.screen)

            StarfieldView()
                .opacity(0.3)

            VStack(spacing: 0) {
                ErudaBrowseView()
                    .environmentObject(store)
            }
        }
    }
}

// MARK: - Eruda Browse View
struct ErudaBrowseView: View {
    @EnvironmentObject var store: AttractViewModel
    @State private var selectedState: ErudaState = .wealth
    @State private var showInlineAdd: Bool = false
    @State private var inlineNewText: String = ""
    @State private var playWithBg: Bool = false
    @State private var bgPlayer: AVAudioPlayer?
    
    var currentStateSet: ErudaStateSet? {
        store.erudaStateSets.first { $0.state == selectedState }
    }
    
    var allAffirmations: [String] {
        let builtIn: [String] = {
            guard let stateSet = currentStateSet else { return [] }
            return stateSet.morningAffirmations + stateSet.nightAffirmations
        }()
        let userAdded = store.userAffirmations[selectedState] ?? []
        return userAdded + builtIn
    }
    
    var selectedCount: Int {
        store.getSelection(for: selectedState).selectedAffirmations.count
    }
    
    var isPlaying: Bool {
        store.isPlayingCustom
    }
    
    private func affirmationRow(for affirmation: String) -> some View {
        let isSelected = store.isAffirmationSelected(state: selectedState, affirmation: affirmation)
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundColor(isSelected ? Cosmic.cosmicTeal : Cosmic.textTertiary)
                .padding(.top, 3)
            
            Text(affirmation)
                .font(.body)
                .foregroundColor(Cosmic.starlight.opacity(0.9))
                .lineLimit(nil)
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Cosmic.cosmicTeal.opacity(0.12) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? Cosmic.cosmicTeal.opacity(0.5) : Color.white.opacity(0.06),
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                store.toggleAffirmationSelection(state: selectedState, affirmation: affirmation)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("🧙‍♂️ 이루다")
                    .font(.title2.weight(.bold))
                    .foregroundColor(Cosmic.starlight)
                
                Text("확언을 선택하고 듣거나 명상 배경으로 설정하세요")
                    .font(.subheadline)
                    .foregroundColor(Cosmic.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 16)
            .padding(.bottom, 10)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ErudaState.allCases) { state in
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedState = state
                                store.selectedErudaState = state
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text(state.emoji).font(.system(size: 22))
                                Text(state.rawValue).font(.system(size: 10, weight: .semibold))
                                let count = store.getSelection(for: state).selectedAffirmations.count
                                if count > 0 {
                                    Text("\(count)개")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Cosmic.goldDust)
                                }
                            }
                            .frame(width: 68, height: 78)
                            .background(
                                selectedState == state
                                ? LinearGradient(colors: [Cosmic.twilight, Cosmic.mysticIndigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedState == state ? Cosmic.cosmicTeal.opacity(0.6) : Color.white.opacity(0.12), lineWidth: 1.5)
                            )
                            .shadow(color: selectedState == state ? Cosmic.twilight.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                        }
                        .foregroundColor(selectedState == state ? .white : Cosmic.textSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            
            HStack(spacing: 10) {
                Button(action: { store.selectAllAffirmations(for: selectedState) }) {
                    Label("모두 선택", systemImage: "checklist")
                        .font(.caption).padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Cosmic.cosmicTeal.opacity(0.15)).cornerRadius(8)
                        .foregroundColor(Cosmic.cosmicTeal)
                }
                Button(action: { store.deselectAllAffirmations(for: selectedState) }) {
                    Label("선택 해제", systemImage: "xmark")
                        .font(.caption).padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.white.opacity(0.06)).cornerRadius(8)
                        .foregroundColor(Cosmic.textSecondary)
                }
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        inlineNewText = ""; showInlineAdd.toggle()
                    }
                }) {
                    Image(systemName: showInlineAdd ? "xmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(showInlineAdd ? Color.red.opacity(0.8) : Cosmic.goldDust)
                }
                Button(action: { withAnimation { store.isRandomPlay.toggle() } }) {
                    Image(systemName: store.isRandomPlay ? "shuffle.circle.fill" : "shuffle.circle")
                        .font(.system(size: 22))
                        .foregroundColor(store.isRandomPlay ? Cosmic.cosmicTeal : Cosmic.textTertiary)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 6)
            
            if showInlineAdd {
                HStack(spacing: 10) {
                    TextField("새 확언 입력...", text: $inlineNewText)
                        .textFieldStyle(.plain).padding(10)
                        .background(Color.white.opacity(0.08)).cornerRadius(10)
                        .foregroundColor(Cosmic.starlight)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Cosmic.cosmicTeal.opacity(0.4), lineWidth: 1))
                    Button(action: {
                        let trimmed = inlineNewText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            store.addUserAffirmation(state: selectedState, text: trimmed)
                            store.toggleAffirmationSelection(state: selectedState, affirmation: trimmed)
                            inlineNewText = ""
                            withAnimation { showInlineAdd = false }
                        }
                    }) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 28))
                            .foregroundColor(inlineNewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : Cosmic.cosmicTeal)
                    }
                    .disabled(inlineNewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 16).padding(.vertical, 6)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(allAffirmations, id: \.self) { affirmation in
                        affirmationRow(for: affirmation)
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 100)
            }
            
            // Floating bottom bar
            VStack(spacing: 10) {
                // 배경이랑 같이 듣기 toggle
                HStack {
                    Image(systemName: "music.note")
                        .foregroundColor(Cosmic.cosmicTeal)
                    Toggle("배경과 함께 듣기", isOn: $playWithBg)
                        .toggleStyle(SwitchToggleStyle(tint: Cosmic.cosmicTeal))
                        .font(.subheadline)
                }
                .padding(.horizontal, 4)
                .foregroundColor(Cosmic.starlight)
                .onChange(of: playWithBg) { newValue in
                    guard store.isPlayingCustom else { return }
                    if newValue { startBgMusic() } else { stopBgMusic() }
                }
                
                Button(action: {
                    if store.isPlayingCustom {
                        store.stopPlayback()
                        stopBgMusic()
                    } else if store.allSelectedAffirmationsText.count > 0 {
                        store.playSelectedAffirmations()
                        if playWithBg { startBgMusic() }
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: store.isPlayingCustom ? "stop.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text(store.isPlayingCustom ? "멈추기" : "선택한 확언 듣기").font(.headline)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: store.isPlayingCustom ? [Color.red.opacity(0.8), Color.orange.opacity(0.8)] : [Cosmic.twilight, Cosmic.cosmicTeal.opacity(0.8)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white).cornerRadius(20)
                    .shadow(color: store.isPlayingCustom ? Color.red.opacity(0.3) : Cosmic.twilight.opacity(0.3), radius: 12, x: 0, y: 4)
                }
                .padding(.horizontal, 16)
                .disabled(store.allSelectedAffirmationsText.isEmpty)
                .opacity(store.allSelectedAffirmationsText.isEmpty ? 0.5 : 1.0)
            }
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.04, green: 0.02, blue: 0.14).opacity(0.95), Color(red: 0.06, green: 0.03, blue: 0.18).opacity(0.95)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay(
                Rectangle()
                    .fill(LinearGradient(colors: [Cosmic.cosmicTeal.opacity(0.3), Color.clear], startPoint: .top, endPoint: .bottom))
                    .frame(height: 1),
                alignment: .top
            )
        }
        .onDisappear { stopBgMusic() }
    }
    
    // MARK: - Background Music
    private func startBgMusic() {
        guard let url = Bundle.main.url(forResource: "background", withExtension: "mp3")
                ?? Bundle.main.url(forResource: "background", withExtension: "wav")
        else { return }
        do {
            bgPlayer = try AVAudioPlayer(contentsOf: url)
            bgPlayer?.numberOfLoops = -1
            bgPlayer?.volume = 0.22
            bgPlayer?.play()
        } catch {
            print("Eruda bg music error: \(error)")
        }
    }
    
    private func stopBgMusic() {
        bgPlayer?.stop()
        bgPlayer = nil
    }
}

// MARK: - Eruda Wizard View
struct ErudaWizardView: View {
    @EnvironmentObject var store: AttractViewModel
    @State private var step: Int = 1
    @State private var customTitle: String = ""
    @State private var selectedState: ErudaState = .wealth
    @State private var affirmationInput: String = ""
    @State private var affirmations: [String] = []
    @State private var isPlayingCustom: Bool = false
    @State private var showConfirm: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                ForEach(1...3, id: \.self) { i in
                    VStack {
                        Circle()
                            .fill(i <= step ? Cosmic.cosmicTeal : Color.white.opacity(0.15))
                            .frame(width: 40, height: 40)
                            .overlay(Text("\(i)").font(.headline).foregroundColor(i <= step ? .white : Cosmic.textTertiary))
                        Text(stepTitle(i)).font(.caption.weight(.semibold))
                            .foregroundColor(i <= step ? Cosmic.starlight : Cosmic.textTertiary).multilineTextAlignment(.center)
                    }
                    if i < 3 { Spacer() }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 20)

            ScrollView {
                if step == 1 { Step1View(title: $customTitle, state: $selectedState) }
                else if step == 2 { Step2View(affirmationInput: $affirmationInput, affirmations: $affirmations) }
                else { Step3View(customTitle: customTitle, selectedState: selectedState, affirmations: affirmations, isPlaying: $isPlayingCustom).environmentObject(store) }
            }
            Spacer()

            HStack(spacing: 12) {
                if step > 1 {
                    Button(action: { step -= 1 }) {
                        Text("이전").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Color.white.opacity(0.08)).foregroundColor(Cosmic.textSecondary).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                }
                Button(action: { if step < 3 { step += 1 } else { showConfirm = true } }) {
                    Text(step == 3 ? "완료" : "다음").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(LinearGradient(colors: [Cosmic.twilight, Cosmic.cosmicTeal.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .foregroundColor(.white).cornerRadius(12)
                        .shadow(color: Cosmic.twilight.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(step == 3 && (customTitle.isEmpty || affirmations.isEmpty))
            }
            .padding(.horizontal, 16).padding(.bottom, 20)
        }
        .padding(.top, 20)
        .alert("확언 저장", isPresented: $showConfirm) {
            Button("저장") {
                store.addCustomErudaSet(title: customTitle, state: selectedState, affirmations: affirmations)
                step = 1; customTitle = ""; selectedState = .wealth; affirmationInput = ""; affirmations = []
            }
            Button("취소", role: .cancel) { }
        } message: { Text("'\(customTitle)'를 저장하시겠습니까?") }
    }

    func stepTitle(_ step: Int) -> String {
        switch step {
        case 1: return "카테고리"
        case 2: return "확언 작성"
        case 3: return "검수"
        default: return ""
        }
    }
}

// MARK: - Wizard Step Views
struct Step1View: View {
    @Binding var title: String
    @Binding var state: ErudaState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("나만의 확언에 이름 붙여주세요").font(.headline).foregroundColor(Cosmic.starlight)
            TextField("예: 성공의 아침", text: $title).padding(12)
                .background(Color.white.opacity(0.08)).foregroundColor(Cosmic.starlight).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Cosmic.cosmicTeal.opacity(0.4), lineWidth: 1))
            Text("카테고리 선택").font(.headline).foregroundColor(Cosmic.starlight).padding(.top, 16)
            VStack(spacing: 10) {
                ForEach(ErudaState.allCases) { s in
                    Button(action: { state = s }) {
                        HStack {
                            Text(s.emoji).font(.system(size: 20))
                            Text(s.rawValue).font(.body)
                            Spacer()
                            if state == s { Image(systemName: "checkmark.circle.fill").foregroundColor(Cosmic.cosmicTeal) }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                        .background(state == s ? Cosmic.cosmicTeal.opacity(0.15) : Color.white.opacity(0.04))
                        .foregroundColor(Cosmic.starlight).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(state == s ? Cosmic.cosmicTeal : Color.white.opacity(0.08), lineWidth: 1))
                    }
                }
            }
            Spacer()
        }.padding(16)
    }
}

struct Step2View: View {
    @Binding var affirmationInput: String
    @Binding var affirmations: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("확언들을 입력하세요 (Enter로 구분)").font(.headline).foregroundColor(Cosmic.starlight)
            TextEditor(text: $affirmationInput).frame(minHeight: 200).padding(12)
                .scrollContentBackground(.hidden).background(Color.white.opacity(0.06))
                .foregroundColor(Cosmic.starlight).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Cosmic.cosmicTeal.opacity(0.25), lineWidth: 1))
                .onChange(of: affirmationInput) { _ in
                    affirmations = affirmationInput.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                }
            VStack(alignment: .leading, spacing: 10) {
                Text("미리보기 (\(affirmations.count)개)").font(.subheadline.weight(.semibold)).foregroundColor(Cosmic.cosmicTeal)
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(affirmations, id: \.self) { aff in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "quote.bubble.fill").font(.caption).foregroundColor(Cosmic.cosmicTeal.opacity(0.6))
                                Text(aff).font(.subheadline).foregroundColor(Cosmic.starlight.opacity(0.85)).lineLimit(2)
                                Spacer()
                            }.padding(8).background(Color.white.opacity(0.03)).cornerRadius(8)
                        }
                    }
                }.frame(maxHeight: 150)
            }
            Spacer()
        }.padding(16)
    }
}

struct Step3View: View {
    @EnvironmentObject var store: AttractViewModel
    @Environment(\.dismiss) var dismiss
    let customTitle: String
    let selectedState: ErudaState
    let affirmations: [String]
    @Binding var isPlaying: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("최종 확인").font(.title2.weight(.bold)).foregroundColor(Cosmic.starlight)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("제목:").font(.subheadline.weight(.semibold)).foregroundColor(Cosmic.textSecondary)
                    Text(customTitle).font(.subheadline).foregroundColor(Cosmic.cosmicTeal)
                    Spacer()
                }
                HStack {
                    Text("카테고리:").font(.subheadline.weight(.semibold)).foregroundColor(Cosmic.textSecondary)
                    Text("\(selectedState.emoji) \(selectedState.rawValue)").font(.subheadline).foregroundColor(Cosmic.starlight)
                    Spacer()
                }
                HStack {
                    Text("확언 수:").font(.subheadline.weight(.semibold)).foregroundColor(Cosmic.textSecondary)
                    Text("\(affirmations.count)개").font(.subheadline).foregroundColor(Cosmic.cosmicTeal)
                    Spacer()
                }
            }.padding(12).background(Color.white.opacity(0.04)).cornerRadius(12)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(affirmations, id: \.self) { aff in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "quote.bubble").font(.caption).foregroundColor(Cosmic.cosmicTeal).padding(.top, 2)
                            Text(aff).font(.body).foregroundColor(Cosmic.starlight.opacity(0.9)).lineLimit(nil)
                            Spacer()
                        }.padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                }
            }.frame(maxHeight: 200)

            Button(action: {
                if isPlaying { store.stopPlayback(); isPlaying = false }
                else {
                    let set = CustomErudaSet(title: customTitle, selectedState: selectedState, affirmations: affirmations)
                    store.playCustomAffirmations(customSet: set); isPlaying = true
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill").font(.system(size: 18, weight: .bold))
                    Text(isPlaying ? "멈추기" : "듣기").font(.headline)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(LinearGradient(colors: isPlaying ? [Color.red.opacity(0.8), Color.orange.opacity(0.8)] : [Cosmic.twilight, Cosmic.cosmicTeal.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .foregroundColor(.white).cornerRadius(12)
                .shadow(color: isPlaying ? Color.red.opacity(0.3) : Cosmic.twilight.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            Button(action: { store.addCustomErudaSet(title: customTitle, state: selectedState, affirmations: affirmations); dismiss() }) {
                Text("저장하기 ✓").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(LinearGradient(colors: [Cosmic.cosmicTeal, Cosmic.twilight], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .foregroundColor(.white).cornerRadius(12)
                    .shadow(color: Cosmic.cosmicTeal.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            Spacer()
        }.padding(16)
    }
}
