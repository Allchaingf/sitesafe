//
//  HistoryView.swift
//  SiteSafe — Feature 12
//
//  One chronological feed of everything logged: briefings, hazards,
//  near-misses, incidents and permits. Filterable by type.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: AppStore
    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable, Hashable {
        case all, briefings, hazards, nearMiss, incidents
        var label: String {
            switch self {
            case .all: return "All"
            case .briefings: return "Briefings"
            case .hazards: return "Hazards"
            case .nearMiss: return "Near-miss"
            case .incidents: return "Incidents"
            }
        }
        func matches(_ kind: HistoryKind) -> Bool {
            switch self {
            case .all: return true
            case .briefings: return kind == .briefing
            case .hazards: return kind == .hazard || kind == .permit
            case .nearMiss: return kind == .nearMiss
            case .incidents: return kind == .incident
            }
        }
    }

    private var entries: [HistoryEntry] { store.history.filter { filter.matches($0.kind) } }

    var body: some View {
        ScreenScaffold("History", subtitle: "\(store.history.count) events logged") {

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Filter.allCases, id: \.self) { f in
                        Button(action: {
                            UISelectionFeedbackGenerator().selectionChanged()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { filter = f }
                        }) {
                            Text(f.label).font(Theme.caption(13))
                                .foregroundColor(filter == f ? Theme.onPrimary : Theme.textSecondary)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Capsule().fill(filter == f ? Theme.primary : Theme.bgSoft))
                                .overlay(Capsule().stroke(filter == f ? Color.clear : Theme.stroke, lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            if entries.isEmpty {
                EmptyStateView(systemImage: "clock.arrow.circlepath", title: "Nothing here yet",
                               message: "Briefings, hazards, near-misses and incidents will appear here.")
            }

            ForEach(entries) { entry in
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(entry.kind.tint.opacity(0.18)).frame(width: 42, height: 42)
                        Image(systemName: entry.kind.icon).foregroundColor(entry.kind.tint)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.title).font(Theme.heading(15)).foregroundColor(Theme.textPrimary)
                        if !entry.subtitle.isEmpty {
                            Text(entry.subtitle).font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    Text(Fmt.relativeDay(entry.date))
                        .font(Theme.caption(10)).foregroundColor(Theme.textDisabled)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.card))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(Theme.stroke, lineWidth: 1))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
