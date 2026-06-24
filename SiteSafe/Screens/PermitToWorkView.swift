//
//  PermitToWorkView.swift
//  SiteSafe — Feature 08
//
//  Permits to work for high-risk activities (work at height, hot work, etc.)
//  with a conditions checklist that must be met before work proceeds.
//

import SwiftUI

struct PermitToWorkView: View {
    @EnvironmentObject var store: AppStore
    @State private var editing: Permit?
    @State private var creatingNew = false

    private var items: [Permit] {
        store.data.permits.sorted {
            if ($0.status == .active) != ($1.status == .active) { return $0.status == .active }
            return $0.issuedAt > $1.issuedAt
        }
    }

    var body: some View {
        ScreenScaffold("Permit to Work", subtitle: "\(store.activePermits.count) active permits") {

            ActionButton(title: "Issue Permit", systemImage: "plus.circle.fill") { creatingNew = true }

            if items.isEmpty {
                EmptyStateView(systemImage: "doc.text.fill", title: "No permits issued",
                               message: "Issue a permit for any high-risk task and track its conditions.")
            }

            ForEach(items) { permit in
                Button(action: { editing = permit }) {
                    CardView(accent: permit.status.color) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Image(systemName: permit.type.icon)
                                    .font(.system(size: 20, weight: .bold)).foregroundColor(Theme.primary)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(permit.type.label).font(Theme.heading(16)).foregroundColor(Theme.textPrimary)
                                    Text(permit.location.isEmpty ? "No location" : permit.location)
                                        .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                                }
                                Spacer()
                                StatusPill(text: permit.status.label, color: permit.status.color, filled: true)
                            }
                            HStack(spacing: 10) {
                                Label("\(permit.conditions.filter { $0.met }.count)/\(permit.conditions.count) conditions",
                                      systemImage: permit.allConditionsMet ? "checkmark.seal.fill" : "seal")
                                    .font(Theme.caption(11))
                                    .foregroundColor(permit.allConditionsMet ? Theme.safe : Theme.hazard)
                                Spacer()
                                Text("Valid to \(Fmt.time(permit.validUntil))")
                                    .font(Theme.caption(11)).foregroundColor(Theme.textDisabled)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $creatingNew) {
            PermitEditorView(permit: freshPermit(), isNew: true).environmentObject(store)
        }
        .sheet(item: $editing) { permit in
            PermitEditorView(permit: permit, isNew: false).environmentObject(store)
        }
    }

    private func freshPermit() -> Permit {
        var p = Permit()
        p.conditions = p.type.defaultConditions.map { PermitCondition(text: $0) }
        return p
    }
}

struct PermitEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    @State var permit: Permit
    let isNew: Bool
    @State private var newCondition = ""

    var body: some View {
        NavigationView {
            ScreenScaffold(isNew ? "Issue Permit" : "Edit Permit") {

                SectionHeader(title: "Type", systemImage: "doc.text.fill")
                CardView {
                    Menu {
                        ForEach(PermitType.allCases) { type in
                            Button(action: { changeType(type) }) {
                                Label(type.label, systemImage: type.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: permit.type.icon).foregroundColor(Theme.primary)
                            Text(permit.type.label).foregroundColor(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down").foregroundColor(Theme.textSecondary)
                        }
                        .font(Theme.body())
                    }
                }

                CardView {
                    VStack(spacing: 12) {
                        LabeledField(label: "Location", text: $permit.location, placeholder: "Where is the work?")
                        LabeledField(label: "Issued to", text: $permit.issuedTo, placeholder: "Name / gang")
                        DatePicker("Valid until", selection: $permit.validUntil,
                                   displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                            .accentColor(Theme.primary).font(Theme.body()).foregroundColor(Theme.textPrimary)
                    }
                }

                SectionHeader(title: "Conditions", systemImage: "checklist")
                CardView {
                    VStack(spacing: 0) {
                        if permit.conditions.isEmpty {
                            Text("No conditions yet — add the controls required.")
                                .font(Theme.caption(12)).foregroundColor(Theme.textSecondary).padding(.vertical, 6)
                        }
                        ForEach(permit.conditions.indices, id: \.self) { i in
                            HStack(spacing: 10) {
                                Button(action: { toggleCondition(i) }) {
                                    Image(systemName: permit.conditions[i].met ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(permit.conditions[i].met ? Theme.safe : Theme.textDisabled)
                                }
                                .buttonStyle(PlainButtonStyle())
                                Text(permit.conditions[i].text).font(Theme.body(14)).foregroundColor(Theme.textPrimary)
                                Spacer()
                                Button(action: { permit.conditions.remove(at: i) }) {
                                    Image(systemName: "minus.circle.fill").foregroundColor(Theme.incident.opacity(0.8))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 8)
                            if i < permit.conditions.count - 1 { Divider().background(Theme.stroke) }
                        }
                        HStack {
                            TextField("Add condition…", text: $newCondition)
                                .font(Theme.body(14)).foregroundColor(Theme.textPrimary)
                            Button(action: addCondition) {
                                Image(systemName: "plus.circle.fill").foregroundColor(Theme.primary)
                            }
                            .disabled(newCondition.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.top, 8)
                    }
                }

                SectionHeader(title: "Status", systemImage: "flag.fill")
                PillSelector(options: PermitStatus.allCases, selection: $permit.status,
                             label: { $0.label }, tint: { $0.color })

                ActionButton(title: "Save Permit", systemImage: "tray.and.arrow.down.fill") {
                    store.savePermit(permit)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    presentationMode.wrappedValue.dismiss()
                }
                if !isNew && permit.status == .active {
                    ActionButton(title: "Close Permit", systemImage: "checkmark.seal.fill", kind: .secondary) {
                        store.closePermit(permit)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                if !isNew {
                    ActionButton(title: "Delete", systemImage: "trash.fill", kind: .incident) {
                        store.deletePermit(permit)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .onTapGesture { UIApplication.shared.dismissKeyboard() }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func changeType(_ type: PermitType) {
        permit.type = type
        // Offer the standard conditions for this type if none have been added.
        if permit.conditions.isEmpty {
            permit.conditions = type.defaultConditions.map { PermitCondition(text: $0) }
        }
    }
    private func toggleCondition(_ i: Int) {
        UISelectionFeedbackGenerator().selectionChanged()
        permit.conditions[i].met.toggle()
    }
    private func addCondition() {
        let t = newCondition.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        permit.conditions.append(PermitCondition(text: t))
        newCondition = ""
    }
}
