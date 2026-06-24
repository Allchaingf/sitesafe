//
//  RootTabView.swift
//  SiteSafe
//
//  Main app shell: switches the active tab's screen and overlays the custom
//  tab bar. Each tab is wrapped in its own NavigationView (stack style).
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var store: AppStore
    @State private var tab: AppTab = .today

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bgDeep.ignoresSafeArea()

            Group {
                switch tab {
                case .today:     stack { DailyGateView() }
                case .hazards:   stack { HazardLogView() }
                case .incidents: stack { IncidentReportView() }
                case .reports:   stack { ReportsView() }
                case .more:      stack { MoreView(tab: $tab) }
                }
            }

            CustomTabBar(
                selection: $tab,
                hazardBadge: store.openHazardCount,
                incidentBadge: store.data.incidents.isEmpty ? 0 : 0,
                moreBadge: store.unresolvedNearMisses
            )
        }
    }

    private func stack<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        NavigationView { content() }
            .navigationViewStyle(StackNavigationViewStyle())
    }
}
