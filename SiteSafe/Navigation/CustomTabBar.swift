//
//  CustomTabBar.swift
//  SiteSafe
//
//  Themed bottom tab bar with hi-vis active state, spring scale and badges.
//

import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case today, hazards, incidents, reports, more
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .hazards: return "Hazards"
        case .incidents: return "Incidents"
        case .reports: return "Reports"
        case .more: return "More"
        }
    }
    var icon: String {
        switch self {
        case .today: return "shield.fill"
        case .hazards: return "exclamationmark.triangle.fill"
        case .incidents: return "cross.case.fill"
        case .reports: return "doc.text.fill"
        case .more: return "square.grid.2x2.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selection: AppTab
    var hazardBadge: Int = 0
    var incidentBadge: Int = 0
    var moreBadge: Int = 0

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            ZStack {
                BlurView(style: .systemChromeMaterialDark)
                Theme.bgDeep.opacity(0.75)
            }
            .overlay(HazardTape(height: 3), alignment: .top)
            .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func badge(for tab: AppTab) -> Int {
        switch tab {
        case .hazards: return hazardBadge
        case .incidents: return incidentBadge
        case .more: return moreBadge
        default: return 0
        }
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSel = selection == tab
        return Button(action: {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selection = tab }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    Image(systemName: tab.icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(isSel ? Theme.primary : Theme.textDisabled)
                        .scaleEffect(isSel ? 1.14 : 1)
                    let count = badge(for: tab)
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(tab == .incidents ? Theme.incident : Theme.hazard))
                            .offset(x: 13, y: -10)
                    }
                }
                Text(tab.title)
                    .font(.system(size: 10, weight: isSel ? .bold : .medium, design: .rounded))
                    .foregroundColor(isSel ? Theme.primary : Theme.textDisabled)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
