//
//  DailyGateView.swift
//  SiteSafe — Feature 01 (home)
//
//  The daily safety gate. The shift cannot be opened until today's toolbox
//  talk is run and the PPE check passes. Shows the live "days without
//  incident" counter and a snapshot of the site's open safety items.
//

import SwiftUI

struct DailyGateView: View {
    @EnvironmentObject var store: AppStore
    @State private var toastMessage: String?

    private var briefingDone: Bool { store.todayBriefingDone }
    private var ppePassed: Bool { store.todayPPEPassed }
    private var shiftOpen: Bool { store.isShiftOpen }

    var body: some View {
        ScreenScaffold("Daily Gate", subtitle: Fmt.weekday(Date())) {

            // Days without incident
            HStack {
                Spacer()
                DaysSafeRing(days: store.daysWithoutIncident)
                Spacer()
            }
            .padding(.vertical, 4)

            // Gate status
            CardView(accent: shiftOpen ? Theme.shiftOn : (canOpen ? Theme.safe : Theme.hazard)) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: shiftOpen ? "lock.open.fill" : "lock.fill")
                            .foregroundColor(shiftOpen ? Theme.shiftOn : Theme.hazard)
                        Text(shiftOpen ? "Shift Open" : "Shift Locked")
                            .font(Theme.heading(18)).foregroundColor(Theme.textPrimary)
                        Spacer()
                        if shiftOpen {
                            StatusPill(text: "On Site", color: Theme.shiftOn, filled: true)
                        }
                    }

                    GateStep(title: "Toolbox talk", detail: briefingDone ? "Completed & signed" : "Not run yet",
                             done: briefingDone)
                    GateStep(title: "PPE check", detail: ppeStatusDetail, done: ppePassed)

                    if !shiftOpen {
                        Text(canOpen ? "All checks complete — you can open the shift."
                                     : "Complete both checks to unlock the shift.")
                            .font(Theme.caption(12))
                            .foregroundColor(canOpen ? Theme.safe : Theme.textSecondary)
                    }
                }
            }

            // Actions
            VStack(spacing: 10) {
                NavigationLink(destination: ToolboxTalkView()) {
                    GateActionLabel(title: "Run Briefing", icon: "megaphone.fill",
                                    done: briefingDone, kind: .secondary)
                }
                NavigationLink(destination: PPECheckView()) {
                    GateActionLabel(title: "PPE Check", icon: "checkmark.shield.fill",
                                    done: ppePassed, kind: .secondary)
                }

                if shiftOpen {
                    ActionButton(title: "Shift Is Open", systemImage: "checkmark.circle.fill",
                                 kind: .primary, enabled: false) {}
                } else {
                    ActionButton(title: "Open Shift", systemImage: "lock.open.fill",
                                 kind: .primary, enabled: canOpen) {
                        store.openShift()
                        toastMessage = "Shift opened — work safe"
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
            }

            // Site snapshot
            SectionHeader(title: "Site snapshot", systemImage: "chart.bar.fill")
            HStack(spacing: 10) {
                StatTile(value: "\(store.openHazardCount)", label: "Open hazards",
                         systemImage: "exclamationmark.triangle.fill", tint: Theme.hazard)
                StatTile(value: "\(store.highRiskOpenCount)", label: "High risk",
                         systemImage: "flame.fill", tint: Theme.incident)
            }
            HStack(spacing: 10) {
                StatTile(value: "\(store.activePermits.count)", label: "Active permits",
                         systemImage: "doc.text.fill", tint: Theme.shiftOn)
                StatTile(value: "\(store.unresolvedNearMisses)", label: "Open near-miss",
                         systemImage: "exclamationmark.bubble.fill", tint: Theme.warn)
            }
        }
        .navigationBarHidden(true)
        .toast($toastMessage)
    }

    private var canOpen: Bool { briefingDone && ppePassed && !shiftOpen }

    private var ppeStatusDetail: String {
        if ppePassed { return "All required PPE present" }
        if let check = store.todayPPECheck {
            let n = check.blockers.count
            return n > 0 ? "\(n) item(s) blocking" : "Not completed"
        }
        return "Not run yet"
    }
}

private struct GateStep: View {
    let title: String
    let detail: String
    let done: Bool
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(done ? Theme.safe : Theme.textDisabled)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(Theme.body(15)).foregroundColor(Theme.textPrimary)
                Text(detail).font(Theme.caption(11)).foregroundColor(done ? Theme.safe : Theme.textSecondary)
            }
            Spacer()
        }
    }
}

private struct GateActionLabel: View {
    let title: String
    let icon: String
    let done: Bool
    let kind: ActionButtonStyle.Kind
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
            Text(title)
            Spacer()
            Image(systemName: done ? "checkmark.seal.fill" : "chevron.right")
                .foregroundColor(done ? Theme.safe : Theme.textSecondary)
        }
        .font(Theme.heading(16))
        .foregroundColor(Theme.onSecondary)
        .padding(.vertical, 15).padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m)
            .stroke(done ? Theme.safe.opacity(0.5) : Theme.stroke, lineWidth: 1))
    }
}
