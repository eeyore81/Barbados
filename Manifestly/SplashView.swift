import SwiftUI

// MARK: - Quote Model
struct SplashQuote: Codable {
    let author: String
    let quotes: [String]
}

struct SplashData: Codable {
    let splashQuotes: [SplashQuote]
}

// MARK: - Splash View
struct SplashView: View {
    @State private var opacity: Double = 0
    @State private var authorOpacity: Double = 0
    @State private var ringRotation: Double = 0

    let onDismiss: () -> Void

    private let quote: (text: String, author: String) = {
        guard let url = Bundle.main.url(forResource: "splash_quotes", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return ("당신의 내면이 곧 우주다.", "Manifestly")
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let splashData = try? decoder.decode(SplashData.self, from: data) else {
            return ("당신의 내면이 곧 우주다.", "Manifestly")
        }
        let allQuotes: [(String, String)] = splashData.splashQuotes.flatMap { author in
            author.quotes.map { ($0, author.author) }
        }
        return allQuotes.randomElement() ?? ("당신의 내면이 곧 우주다.", "Manifestly")
    }()

    var body: some View {
        ZStack {
            // Deep cosmic background
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.01, blue: 0.08),
                    Color(red: 0.05, green: 0.02, blue: 0.15),
                    Color(red: 0.03, green: 0.01, blue: 0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Large nebula glow
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.3, green: 0.15, blue: 0.5).opacity(0.4),
                    Color(red: 0.15, green: 0.05, blue: 0.3).opacity(0.2),
                    Color.clear
                ]),
                center: .init(x: 0.3, y: 0.4),
                startRadius: 30,
                endRadius: 500
            )
            .blendMode(.screen)

            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.6, blue: 0.7).opacity(0.2),
                    Color.clear
                ]),
                center: .init(x: 0.7, y: 0.6),
                startRadius: 20,
                endRadius: 400
            )
            .blendMode(.screen)


            // Rotating mystical ring
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(
                            [Cosmic.starlight.opacity(0.25), Cosmic.cosmicTeal.opacity(0.3), Cosmic.goldDust.opacity(0.25)][i],
                            style: StrokeStyle(lineWidth: 1, dash: [2, 30])
                        )
                        .frame(width: 160 + CGFloat(i) * 60, height: 160 + CGFloat(i) * 60)
                        .rotationEffect(.degrees(ringRotation * [0.8, -0.5, 0.25][i]))
                }
            }
            .opacity(opacity)

            // Central glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Cosmic.twilight.opacity(0.4), Cosmic.mysticIndigo.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 150
                    )
                )
                .frame(width: 200, height: 200)
                .opacity(opacity)

            // Content
            VStack(spacing: 32) {
                Spacer()

                // App icon / symbol
                Text("✨")
                    .font(.system(size: 50))

                // Quote
                Text(quote.text)
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 32)
                    .opacity(opacity)
                    .shadow(color: Cosmic.twilight.opacity(0.5), radius: 15, x: 0, y: 0)

                // Author
                Text("— \(quote.author)")
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .foregroundColor(Cosmic.goldDust.opacity(0.8))
                    .opacity(authorOpacity)

                Spacer()

                // Tap hint
                Text("탭하여 시작하기")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Cosmic.starlight.opacity(0.7))
                    .opacity(opacity)
                    .padding(.bottom, 80)

                Spacer().frame(height: 20)
        }
    }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.easeOut(duration: 1.2).delay(0.6)) { opacity = 1.0 }
            withAnimation(.easeOut(duration: 1.0).delay(1.8)) { authorOpacity = 0.8 }
        }
        .onTapGesture {
            onDismiss()
        }
    }
}
