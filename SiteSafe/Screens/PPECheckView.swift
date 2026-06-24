//
//  PPECheckView.swift
//  SiteSafe — Feature 03
//
//  Pre-start PPE check against the configured set. Required items must all be
//  OK for the check to pass; anything missing is logged ("who is without
//  what") and blocks the shift until resolved.
//

import SwiftUI

struct PPECheckView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) private var presentationMode

    @State private var check: PPECheck = PPECheck()
    @State private var loaded = false
    @State private var toastMessage: String?

    var body: some View {
        ScreenScaffold("PPE Check", subtitle: "Tick off the kit before the crew starts") {

            statusBanner

            if check.lines.isEmpty {
                EmptyStateView(systemImage: "tshirt.fill", title: "No PPE configured",
                               message: "Add a PPE set in Settings to run the check.")
            }

            ForEach(check.lines.indices, id: \.self) { i in
                CardView(accent: lineAccent(check.lines[i])) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            Image(systemName: check.lines[i].kind.icon)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Theme.primary)
                                .frame(width: 34)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(check.lines[i].kind.label).font(Theme.heading(16))
                                    .foregroundColor(Theme.textPrimary)
                                Text(check.lines[i].required ? "Required" : "Optional")
                                    .font(Theme.caption(11))
                                    .foregroundColor(check.lines[i].required ? Theme.hazard : Theme.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { check.lines[i].ok },
                                set: { newVal in
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    check.lines[i].ok = newVal
                                }))
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle(tint: Theme.safe))
                        }
                        if !check.lines[i].ok {
                            LabeledField(label: "Who's missing it / action",
                                         text: $check.lines[i].missingNote,
                                         placeholder: "e.g. 2 operatives — gloves on order")
                        }
                    }
                }
            }

            if !check.lines.isEmpty {
                ActionButton(title: "Save PPE Check", systemImage: "tray.and.arrow.down.fill") {
                    save()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toast($toastMessage)
        .onAppear(perform: loadIfNeeded)
        .onTapGesture { UIApplication.shared.dismissKeyboard() }
    }

    private var statusBanner: some View {
        let passed = check.passed && !check.lines.isEmpty
        let blockers = check.blockers
        return CardView(accent: passed ? Theme.safe : Theme.incident) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: passed ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .foregroundColor(passed ? Theme.safe : Theme.incident)
                    Text(passed ? "PPE Check Passed" : "Check Incomplete")
                        .font(Theme.heading(17)).foregroundColor(Theme.textPrimary)
                    Spacer()
                }
                if !passed {
                    Text(blockers.isEmpty ? "Toggle each required item to confirm it's worn."
                                          : "Blocking: \(blockers.map { $0.kind.label }.joined(separator: ", "))")
                        .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                } else {
                    Text("All required PPE confirmed — shift can be opened.")
                        .font(Theme.caption(12)).foregroundColor(Theme.safe)
                }
            }
        }
    }

    private func lineAccent(_ line: PPELine) -> Color {
        if line.ok { return Theme.safe }
        return line.required ? Theme.incident : Theme.stroke
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        check = store.makeTodayPPECheck()
        loaded = true
    }

    private func save() {
        check.date = Date()
        store.savePPECheck(check)
        toastMessage = check.passed ? "PPE check passed" : "PPE check saved"
        UINotificationFeedbackGenerator().notificationOccurred(check.passed ? .success : .warning)
    }
}
