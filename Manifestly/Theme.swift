import SwiftUI

// MARK: - Cosmic Color Palette
struct Cosmic {
    static let deepSpace = Color(red: 0.04, green: 0.02, blue: 0.12)
    static let nebula = Color(red: 0.15, green: 0.05, blue: 0.25)
    static let starlight = Color(red: 0.92, green: 0.88, blue: 0.95)
    static let goldDust = Color(red: 0.95, green: 0.82, blue: 0.55)
    static let cosmicTeal = Color(red: 0.25, green: 0.78, blue: 0.82)
    static let twilight = Color(red: 0.35, green: 0.18, blue: 0.55)
    static let voidBlue = Color(red: 0.08, green: 0.08, blue: 0.22)
    static let roseNebula = Color(red: 0.55, green: 0.22, blue: 0.45)
    static let iceBlue = Color(red: 0.55, green: 0.75, blue: 0.92)
    static let warmGold = Color(red: 0.98, green: 0.72, blue: 0.35)
    static let mysticIndigo = Color(red: 0.18, green: 0.12, blue: 0.35)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.78)
    static let textTertiary = Color.white.opacity(0.55)
    static let textAccent = Color(red: 0.72, green: 0.82, blue: 1.0)
    static let textWarm = Color(red: 1.0, green: 0.88, blue: 0.72)
    static let cardBg = LinearGradient(
        colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let cardBgStrong = LinearGradient(
        colors: [Color.white.opacity(0.12), Color(red: 0.25, green: 0.15, blue: 0.45).opacity(0.25), Color.white.opacity(0.04)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Starfield Effect
struct StarfieldView: View {
    @State private var twinkle: Bool = false
    let starCount = 60
    let sizes: [CGFloat] = [1, 1.5, 2, 2.5, 3]

    var body: some View {
        Canvas { context, size in
            var rng = SeededRandom(seed: 42)
            for _ in 0..<starCount {
                let x = rng.next() * size.width
                let y = rng.next() * size.height
                let starSize = sizes[Int(rng.next() * CGFloat(sizes.count)) % sizes.count]
                let brightness = 0.3 + rng.next() * 0.7
                let opacity = twinkle ? brightness * 0.7 : brightness * 1.0
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: starSize, height: starSize)),
                    with: .color(.white.opacity(opacity))
                )
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                twinkle = true
            }
        }
    }
}

struct SeededRandom {
    var seed: UInt64
    mutating func next() -> CGFloat {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat(seed % 10000) / 10000.0
    }
}

// MARK: - Pulsing Glow Circle
struct PulsingGlowCircle: View {
    let color: Color
    let size: CGFloat
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.6

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: size * 0.4)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    scale = 1.2
                    opacity = 0.25
                }
            }
    }
}

// MARK: - Cosmic Section Header
struct CosmicSectionHeader: View {
    let title: String
    let icon: String?

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Cosmic.goldDust)
            }
            Text(title)
                .font(.headline)
                .foregroundColor(Cosmic.starlight)
        }
    }
}

// MARK: - Shared Cosmic Background
extension View {
    @ViewBuilder
    func cosmicPanelBackground() -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.02, blue: 0.12),
                    Color(red: 0.06, green: 0.03, blue: 0.18),
                    Color(red: 0.08, green: 0.05, blue: 0.22),
                    Color(red: 0.04, green: 0.02, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.35, green: 0.15, blue: 0.55).opacity(0.35),
                    Color(red: 0.2, green: 0.1, blue: 0.4).opacity(0.2),
                    Color.clear
                ]),
                center: .topLeading,
                startRadius: 20,
                endRadius: 380
            )
            .blendMode(.screen)

            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.7, blue: 0.75).opacity(0.13),
                    Color.clear
                ]),
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 400
            )
            .blendMode(.screen)

            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.06),
                    Color.clear
                ]),
                center: .top,
                startRadius: 1,
                endRadius: 350
            )
            .blendMode(.screen)
        }
    }
}
