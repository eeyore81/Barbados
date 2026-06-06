import SwiftUI
import AVFoundation
import Combine

struct FrequencyMeditationView: View {
    @EnvironmentObject var store: AttractViewModel
    @StateObject private var tonePlayer = TonePlayer()
    @State private var selectedFrequency: Double = 432
    @State private var rotationAngle: Double = 0
    @State private var showStopOverlay = false
    private let spinTimer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

    // Galaxy stars - generated once with fixed seed for consistency
    private let galaxyStars: [GalaxyStar] = {
        var stars: [GalaxyStar] = []
        var rng = SeededRandom(seed: 777)
        let colors: [Color] = [
            Cosmic.cosmicTeal, Cosmic.cosmicTeal.opacity(0.8),
            Cosmic.twilight, Cosmic.twilight.opacity(0.8),
            Cosmic.iceBlue,
            Cosmic.starlight,
            Cosmic.roseNebula,
            Cosmic.goldDust
        ]
        for _ in 0..<35 {
            let radius = 15 + rng.next() * 125
            let angle = rng.next() * 360
            stars.append(GalaxyStar(
                radius: radius,
                baseAngle: angle,
                size: 1 + rng.next() * 2.5,
                opacity: 0.55 + rng.next() * 0.45,
                speed: 0.3 + rng.next() * 1.4,
                clockwise: rng.next() > 0.5,
                color: colors[Int(rng.next() * CGFloat(colors.count)) % colors.count]
            ))
        }
        return stars
    }()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.02, blue: 0.14),
                    Color(red: 0.08, green: 0.04, blue: 0.2),
                    Color(red: 0.05, green: 0.03, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            PulsingGlowCircle(
                color: Color(red: 0.4, green: 0.2, blue: 0.6),
                size: 300
            )
            .offset(x: -100, y: -200)

            PulsingGlowCircle(
                color: Color(red: 0.2, green: 0.5, blue: 0.7),
                size: 220
            )
            .offset(x: 130, y: 150)

            StarfieldView()
                .opacity(0.5)

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 6) {
                        Text("✨ 주파수 명상")
                            .font(.title2.weight(.bold))
                            .foregroundColor(Cosmic.starlight)
                        Text("우주의 진동과 하나 되는 시간")
                            .font(.subheadline)
                            .foregroundColor(Cosmic.textSecondary)
                    }
                    .padding(.top, 20)

                    // Interactive frequency circle
                    Button(action: {
                        if tonePlayer.isPlaying {
                            if showStopOverlay {
                                tonePlayer.stop()
                                store.stopPlayback()
                                showStopOverlay = false
                                withAnimation(.easeOut(duration: 0.6)) { rotationAngle = 0 }
                            } else {
                                withAnimation(.easeInOut(duration: 0.2)) { showStopOverlay = true }
                            }
                        } else {
                            tonePlayer.start(frequency: selectedFrequency)
                            store.incrementMeditationSession()
                            showStopOverlay = false
                            if tonePlayer.isAffirmationEnabled {
                                store.objectWillChange.send()
                                let text = store.allSelectedAffirmationsText
                                if !text.isEmpty { store.speakText(text, voiceState: .affirmation) }
                            }
                        }
                    }) {
                        ZStack {
                            // Galaxy stars scattered inside the circle
                            ForEach(Array(galaxyStars.enumerated()), id: \.offset) { _, star in
                                Circle()
                                    .fill(star.color)
                                    .frame(width: star.size, height: star.size)
                                    .blur(radius: star.size * 0.2)
                                    .opacity(star.opacity)
                                    .offset(
                                        x: cos(star.baseAngle * .pi / 180) * star.radius,
                                        y: sin(star.baseAngle * .pi / 180) * star.radius
                                    )
                                    .rotationEffect(.degrees(rotationAngle * star.speed * (star.clockwise ? 1 : -1)))
                            }

                            // Inner glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Cosmic.twilight.opacity(0.3),
                                            Cosmic.mysticIndigo.opacity(0.15),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 30,
                                        endRadius: 130
                                    )
                                )
                                .frame(width: 240, height: 240)
                                .shadow(color: Cosmic.twilight.opacity(0.3), radius: 40, x: 0, y: 10)

                            // Frequency display
                            VStack(spacing: 8) {
                                Text("\(Int(selectedFrequency)) Hz")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(Cosmic.starlight)

                                Text(frequencyDescription)
                                    .font(.body)
                                    .foregroundColor(Cosmic.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 200)
                            }

                            // Play overlay (only when not playing)
                            if !tonePlayer.isPlaying {
                                Circle()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(Cosmic.cosmicTeal)
                                            .offset(x: 2)
                                    )
                                    .offset(y: 60)
                            }

                            // Stop overlay (only when tapped during playback)
                            if tonePlayer.isPlaying && showStopOverlay {
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "stop.fill")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.white.opacity(0.9))
                                    )
                                    .offset(y: 60)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    frequencySelector

                    // Audio options
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "music.note")
                                .foregroundColor(Cosmic.cosmicTeal)
                            Toggle("배경음악", isOn: $tonePlayer.isBgMusicEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: Cosmic.cosmicTeal))
                        }
                        .onChange(of: tonePlayer.isBgMusicEnabled) { newValue in
                            tonePlayer.updateBgMusic()
                            store.setMeditationBg(for: store.selectedErudaState, enabled: newValue)
                        }

                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundColor(Cosmic.goldDust)
                            Toggle("확언", isOn: $tonePlayer.isAffirmationEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: Cosmic.goldDust))
                        }
                        .onChange(of: tonePlayer.isAffirmationEnabled) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "meditationAffirmationEnabled")
                            if !newValue { store.stopPlayback() }
                        }
                    }
                    .padding(.horizontal, 6)

                    Text("눈을 감고 천천히 호흡하며\n주파수를 온몸으로 느껴보세요")
                        .font(.subheadline)
                        .foregroundColor(Cosmic.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .onReceive(spinTimer) { _ in
            if tonePlayer.isPlaying {
                rotationAngle += 2.5  // fast visible rotation
            }
        }
        .onAppear {
            tonePlayer.setTheme(store.selectedErudaState)
            let selection = store.getSelection(for: store.selectedErudaState)
            tonePlayer.isBgMusicEnabled = selection.isMeditationBgEnabled
            tonePlayer.isAffirmationEnabled = UserDefaults.standard.bool(forKey: "meditationAffirmationEnabled")
        }
        .onChange(of: store.selectedErudaState) { newState in
            tonePlayer.setTheme(newState)
            let selection = store.getSelection(for: newState)
            tonePlayer.isBgMusicEnabled = selection.isMeditationBgEnabled
        }
    }

    private var frequencySelector: some View {
        HStack(spacing: 10) {
            frequencyButton(174, label: "Release", icon: "wind")
            frequencyButton(432, label: "Harmony", icon: "sparkles")
            frequencyButton(528, label: "Healing", icon: "heart")
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(
                        colors: [Cosmic.cosmicTeal.opacity(0.2), Cosmic.twilight.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .cornerRadius(22)
    }

    private func frequencyButton(_ frequency: Double, label: String, icon: String) -> some View {
        let isSelected = selectedFrequency == frequency
        return Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedFrequency = frequency
                tonePlayer.updateFrequency(frequency)
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? Cosmic.starlight : Cosmic.cosmicTeal.opacity(0.7))
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isSelected ? Cosmic.starlight : Cosmic.textSecondary)
                Text("\(Int(frequency)) Hz")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? Cosmic.starlight.opacity(0.8) : Cosmic.textTertiary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .frame(minWidth: 100)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [Cosmic.twilight, Cosmic.mysticIndigo.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.white.opacity(0.05), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isSelected ? Cosmic.cosmicTeal.opacity(0.5) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? Cosmic.twilight.opacity(0.4) : Color.clear,
                radius: 10, x: 0, y: 4
            )
        }
    }

    private var frequencyDescription: String {
        switch selectedFrequency {
        case 174: return "긴장을 부드럽게 풀어줍니다"
        case 432: return "조화로운 마음을 가져옵니다"
        case 528: return "긍정의 에너지를 채워줍니다"
        default: return "편안하게 주파수를 느껴보세요"
        }
    }
}

// MARK: - Tone Player
final class TonePlayer: ObservableObject {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var backgroundNode: AVAudioSourceNode?
    private var backgroundMP3Node: AVAudioPlayerNode?
    private var tonePhase: Double = 0
    private var backgroundPhase: Double = 0
    private var backgroundLFOPhase: Double = 0
    @Published var isPlaying = false
    @Published var isBgMusicEnabled = true
    @Published var isAffirmationEnabled = false
    private(set) var frequency: Double = 432
    private var themeFrequency: Double = 110.0
    private let engineSampleRate: Double = 44100.0

    init() {
        configureBackgroundAudioSession()
        setupAudioEngine()
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.configureBackgroundAudioSession()
            if !(self?.engine.isRunning ?? true) && self?.isPlaying == true {
                try? self?.engine.start()
            }
        }
    }

    private func configureBackgroundAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("AudioSession error: \(error)")
        }
    }

    /// Update background music playback
    func updateBgMusic() {
        guard engine.isRunning else { return }
        if isBgMusicEnabled {
            playBackgroundMP3()
        } else {
            stopBackgroundMP3()
        }
    }

    private func playBackgroundMP3() {
        if backgroundMP3Node != nil { return }
        guard let mp3URL = loadBackgroundMP3FromAssets() else { return }
        do {
            let audioFile = try AVAudioFile(forReading: mp3URL)
            let engineFormat = engine.mainMixerNode.inputFormat(forBus: 0)
            let format = AVAudioFormat(standardFormatWithSampleRate: engineFormat.sampleRate, channels: audioFile.processingFormat.channelCount) ?? engineFormat
            let playerNode = AVAudioPlayerNode()
            backgroundMP3Node = playerNode
            engine.attach(playerNode)
            engine.connect(playerNode, to: engine.mainMixerNode, format: format)
            playerNode.volume = 0.22
            scheduleAudioLoop(url: mp3URL, for: playerNode)
            playerNode.play()
        } catch {
            print("Background MP3 play error: \(error)")
        }
    }

    private func loadBackgroundMP3FromAssets() -> URL? {
        if let dataAsset = NSDataAsset(name: "background") {
            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("background_tmp.mp3")
            do {
                try dataAsset.data.write(to: tmpURL, options: .atomic)
                return tmpURL
            } catch {
                return nil
            }
        }
        return Bundle.main.url(forResource: "background", withExtension: "mp3")
            ?? Bundle.main.url(forResource: "background", withExtension: "wav")
    }

    private func stopBackgroundMP3() {
        if let node = backgroundMP3Node {
            node.stop()
            engine.detach(node)
            backgroundMP3Node = nil
        }
    }

    private func scheduleAudioLoop(url: URL, for node: AVAudioPlayerNode) {
        do {
            let file = try AVAudioFile(forReading: url)
            node.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.scheduleAudioLoop(url: url, for: node)
                }
            }
        } catch {
            print("⚠️ Failed to reschedule: \(error)")
        }
    }

    private func setupAudioEngine() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("AudioSession setup error: \(error)")
        }
        let sampleRate = 44_100.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)

        sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let increment = 2.0 * Double.pi * self.frequency / sampleRate
            for frame in 0..<Int(frameCount) {
                let sample = sin(self.tonePhase) * 0.04
                self.tonePhase += increment
                if self.tonePhase > 2.0 * Double.pi { self.tonePhase -= 2.0 * Double.pi }
                for buffer in ablPointer {
                    let pointer = buffer.mData!.assumingMemoryBound(to: Float.self)
                    pointer[frame] = Float(sample)
                }
            }
            return noErr
        }

        backgroundNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let baseFrequency = self.themeFrequency
            let increment = 2.0 * Double.pi * baseFrequency / sampleRate
            let lfoIncrement = 2.0 * Double.pi * 0.12 / sampleRate
            let amp = !self.isBgMusicEnabled ? 0.16 : 0.0
            for frame in 0..<Int(frameCount) {
                let lfo = 0.65 + 0.25 * sin(self.backgroundLFOPhase)
                self.backgroundLFOPhase += lfoIncrement
                if self.backgroundLFOPhase > 2.0 * Double.pi { self.backgroundLFOPhase -= 2.0 * Double.pi }
                let fundamental = sin(self.backgroundPhase)
                let second = sin(self.backgroundPhase * 2.0) * 0.45
                let third = sin(self.backgroundPhase * 3.0) * 0.28
                let sample = (fundamental + second + third) * amp * lfo * 0.35
                self.backgroundPhase += increment
                if self.backgroundPhase > 2.0 * Double.pi { self.backgroundPhase -= 2.0 * Double.pi }
                for buffer in ablPointer {
                    let pointer = buffer.mData!.assumingMemoryBound(to: Float.self)
                    pointer[frame] = Float(sample)
                }
            }
            return noErr
        }

        if let sourceNode = sourceNode, let backgroundNode = backgroundNode, let format = format {
            engine.attach(sourceNode)
            engine.attach(backgroundNode)
            engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
            engine.connect(backgroundNode, to: engine.mainMixerNode, format: format)
            engine.mainMixerNode.outputVolume = 0.85
        }
    }

    func updateFrequency(_ frequency: Double) {
        self.frequency = frequency
    }

    func setTheme(_ state: ErudaState) {
        switch state {
        case .wealth: themeFrequency = 120.0
        case .love: themeFrequency = 100.0
        case .calm: themeFrequency = 80.0
        case .confidence: themeFrequency = 140.0
        case .healing: themeFrequency = 110.0
        case .sleep: themeFrequency = 65.0
        }
    }

    func start(frequency: Double) {
        updateFrequency(frequency)
        do {
            engine.prepare()
            if !engine.isRunning { try engine.start() }
            if isBgMusicEnabled { playBackgroundMP3() }
            isPlaying = true
        } catch {
            print("Audio engine start error: \(error)")
        }
    }

    func stop() {
        stopBackgroundMP3()
        engine.pause()
        isPlaying = false
    }
}

// MARK: - Galaxy Star Model
private struct GalaxyStar {
    let radius: CGFloat
    let baseAngle: CGFloat
    let size: CGFloat
    let opacity: CGFloat
    let speed: CGFloat
    let clockwise: Bool
    let color: Color
}
