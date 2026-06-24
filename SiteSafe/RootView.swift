//
//  RootView.swift
//  SiteSafe
//
//  Top-level phase machine that gates the entry flow:
//  Splash → (first launch ? Onboarding : Main) → Main.
//

import SwiftUI

enum AppPhase { case splash, onboarding, main }

struct RootView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var phase: AppPhase = .splash

    var body: some View {
        ZStack {
            Theme.bgDeep.ignoresSafeArea()

            switch phase {
            case .splash:
                SplashView(safeDays: store.daysWithoutIncident) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        phase = hasCompletedOnboarding ? .main : .onboarding
                    }
                }
                .transition(.opacity)

            case .onboarding:
                OnboardingView {
                    hasCompletedOnboarding = true
                    withAnimation(.easeInOut(duration: 0.5)) { phase = .main }
                }
                .transition(.opacity)

            case .main:
                RootTabView()
                    .transition(.opacity)
            }
        }
    }
}
