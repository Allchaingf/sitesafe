//
//  MoreView.swift
//  SiteSafe
//
//  Hub linking to every feature not on the main tab bar. Secondary screens are
//  pushed (with a back button); the 🔥 tab features jump to their tab.
//

import SwiftUI

struct MoreView: View {
    @EnvironmentObject var store: AppStore
    @Binding var tab: AppTab

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScreenScaffold("More", subtitle: store.data.profile.siteName) {

            SectionHeader(title: "Daily safety gate", systemImage: "shield.fill")
            LazyVGrid(columns: columns, spacing: 12) {
                NavigationLink(destination: ToolboxTalkView()) {
                    MoreTile(title: "Toolbox Talk", subtitle: store.todayBriefingDone ? "Signed today" : "Run briefing",
                             icon: "megaphone.fill", tint: Theme.primary)
                }.buttonStyle(PlainButtonStyle())
                NavigationLink(destination: PPECheckView()) {
                    MoreTile(title: "PPE Check", subtitle: store.todayPPEPassed ? "Passed today" : "Run check",
                             icon: "checkmark.shield.fill", tint: Theme.primary)
                }.buttonStyle(PlainButtonStyle())
            }

            SectionHeader(title: "Logs", systemImage: "tray.full.fill")
            LazyVGrid(columns: columns, spacing: 12) {
                Button(action: { switchTo(.hazards) }) {
                    MoreTile(title: "Hazard Log", subtitle: "\(store.openHazardCount) open",
                             icon: "exclamationmark.triangle.fill", tint: Theme.hazard)
                }.buttonStyle(PlainButtonStyle())
                NavigationLink(destination: NearMissView()) {
                    MoreTile(title: "Near-Miss", subtitle: "\(store.unresolvedNearMisses) open",
                             icon: "exclamationmark.bubble.fill", tint: Theme.warn)
                }.buttonStyle(PlainButtonStyle())
                Button(action: { switchTo(.incidents) }) {
                    MoreTile(title: "Incidents", subtitle: "\(store.data.incidents.count) on record",
                             icon: "cross.case.fill", tint: Theme.incident)
                }.buttonStyle(PlainButtonStyle())
                NavigationLink(destination: HistoryView()) {
                    MoreTile(title: "History", subtitle: "\(store.history.count) events",
                             icon: "clock.arrow.circlepath", tint: Theme.shiftOn)
                }.buttonStyle(PlainButtonStyle())
            }

            SectionHeader(title: "Site", systemImage: "map.fill")
            LazyVGrid(columns: columns, spacing: 12) {
                NavigationLink(destination: ZoneRiskMapView()) {
                    MoreTile(title: "Zone Risk Map", subtitle: "\(store.data.zones.count) zones",
                             icon: "map.fill", tint: Theme.hazard)
                }.buttonStyle(PlainButtonStyle())
                NavigationLink(destination: PermitToWorkView()) {
                    MoreTile(title: "Permits", subtitle: "\(store.activePermits.count) active",
                             icon: "doc.text.fill", tint: Theme.shiftOn)
                }.buttonStyle(PlainButtonStyle())
                NavigationLink(destination: SafetyChecklistView()) {
                    MoreTile(title: "Safety Checklist", subtitle: "\(Int(store.checklistProgress * 100))% done",
                             icon: "checklist", tint: Theme.primary)
                }.buttonStyle(PlainButtonStyle())
                NavigationLink(destination: EmergencyCardView()) {
                    MoreTile(title: "Emergency Card", subtitle: "Contacts & assembly",
                             icon: "cross.circle.fill", tint: Theme.incident)
                }.buttonStyle(PlainButtonStyle())
            }

            SectionHeader(title: "Utility", systemImage: "gearshape.fill")
            LazyVGrid(columns: columns, spacing: 12) {
                Button(action: { switchTo(.reports) }) {
                    MoreTile(title: "Reports", subtitle: "Export PDF",
                             icon: "chart.bar.doc.horizontal.fill", tint: Theme.primary)
                }.buttonStyle(PlainButtonStyle())
                NavigationLink(destination: RemindersView()) {
                    MoreTile(title: "Reminders", subtitle: "Daily nudges",
                             icon: "bell.fill", tint: Theme.warn)
                }.buttonStyle(PlainButtonStyle())
                NavigationLink(destination: SettingsView()) {
                    MoreTile(title: "Settings", subtitle: "Theme, profile, data",
                             icon: "gearshape.fill", tint: Theme.textSecondary)
                }.buttonStyle(PlainButtonStyle())
            }
        }
        .navigationBarHidden(true)
    }

    private func switchTo(_ destination: AppTab) {
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { tab = destination }
    }
}

private struct MoreTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle().fill(tint.opacity(0.18)).frame(width: 44, height: 44)
                Image(systemName: icon).font(.system(size: 19, weight: .bold)).foregroundColor(tint)
            }
            Text(title).font(Theme.heading(15)).foregroundColor(Theme.textPrimary).lineLimit(1)
            Text(subtitle).font(Theme.caption(11)).foregroundColor(Theme.textSecondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(Theme.stroke, lineWidth: 1))
    }
}
