//
//  ManifestlyApp.swift
//  Manifestly
//
//  Created by margarine on 6/2/26.
//

import SwiftUI

@main
struct ManifestlyApp: App {
    @StateObject private var store = AttractViewModel()

    init() {
        #if canImport(UIKit)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(red: 0.04, green: 0.02, blue: 0.14, alpha: 0.92)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.92, green: 0.88, blue: 0.95, alpha: 1.0)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(red: 0.92, green: 0.88, blue: 0.95, alpha: 1.0)
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(red: 0.25, green: 0.78, blue: 0.82, alpha: 1.0)

        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundColor = UIColor(red: 0.04, green: 0.02, blue: 0.14, alpha: 0.92)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
        }
    }
}
