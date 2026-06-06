import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: AttractViewModel

    var body: some View {
        TabView(selection: $store.selectedTab) {
            FrequencyMeditationView()
                .tabItem {
                    Label("명상", systemImage: "waveform.path.ecg")
                }
                .tag(AttractViewModel.Tab.meditation)

            ErudaView()
                .tabItem {
                    Label("이루다", systemImage: "book")
                }
                .tag(AttractViewModel.Tab.eruda)

            GratitudeView()
                .tabItem {
                    Label("감사", systemImage: "heart.text.square")
                }
                .tag(AttractViewModel.Tab.gratitude)

            AnalyticsView()
                .tabItem {
                    Label("분석", systemImage: "ellipsis.circle")
                }
                .tag(AttractViewModel.Tab.analysis)
        }
        .tint(Cosmic.cosmicTeal)
    }
}

struct Views_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AttractViewModel())
    }
}
