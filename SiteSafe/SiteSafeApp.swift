//
//  SiteSafeApp.swift
//  SiteSafe
//
//  App entry point. Injects the global stores, applies the persisted theme and
//  flushes data to disk on backgrounding. Flow: Splash → Onboarding (first
//  launch only) → Main. No auth / welcome / profile screens anywhere.
//

import SwiftUI

@main
struct SiteSafeApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var notifications = NotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appearance") private var appearanceRaw = AppAppearance.dark.rawValue

    init() { SiteSafeApp.configureGlobalAppearance() }

    private var appearance: AppAppearance { AppAppearance(rawValue: appearanceRaw) ?? .system }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(notifications)
                .preferredColorScheme(appearance.colorScheme)
                .onAppear { notifications.refreshStatus() }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active { store.flush() }
        }
    }

    /// Make UIKit-backed surfaces (List/Form, TextEditor, NavigationBar) match
    /// the dark hi-vis theme so nothing shows a default white background.
    private static func configureGlobalAppearance() {
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
        UITextView.appearance().backgroundColor = .clear

        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.titleTextAttributes = [.foregroundColor: UIColor(hex: 0xFEF9E7)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(hex: 0xFEF9E7)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(hex: 0xFACC15)
    }
}
