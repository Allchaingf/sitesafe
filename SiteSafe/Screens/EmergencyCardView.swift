//
//  EmergencyCardView.swift
//  SiteSafe — Feature 10
//
//  The site's emergency reference: assembly point, key contacts (tap to call),
//  first-aid location and nearest help. Fully editable and persisted.
//

import SwiftUI

struct EmergencyCardView: View {
    @EnvironmentObject var store: AppStore
    @State private var info = EmergencyInfo()
    @State private var loaded = false
    @State private var editMode = false
    @State private var toastMessage: String?

    var body: some View {
        ScreenScaffold("Emergency Card", subtitle: "Know it before you need it") {

            ActionButton(title: editMode ? "Done Editing" : "Edit Card",
                         systemImage: editMode ? "checkmark" : "pencil",
                         kind: .secondary) {
                if editMode { saveInfo() }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { editMode.toggle() }
            }

            SectionHeader(title: "Contacts", systemImage: "phone.fill")
            CardView(accent: Theme.incident) {
                VStack(spacing: 12) {
                    if info.contacts.isEmpty {
                        Text("No contacts yet.").font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                    }
                    ForEach(info.contacts.indices, id: \.self) { i in
                        if editMode {
                            VStack(spacing: 8) {
                                LabeledField(label: "Role", text: $info.contacts[i].role, placeholder: "Role")
                                LabeledField(label: "Name", text: $info.contacts[i].name, placeholder: "Name")
                                LabeledField(label: "Phone", text: $info.contacts[i].phone,
                                             placeholder: "Phone", keyboard: .phonePad)
                                Button(action: { info.contacts.remove(at: i) }) {
                                    Label("Remove", systemImage: "trash").font(Theme.caption(12))
                                        .foregroundColor(Theme.incident)
                                }
                            }
                            if i < info.contacts.count - 1 { Divider().background(Theme.stroke) }
                        } else {
                            ContactRow(contact: info.contacts[i]) { call(info.contacts[i].phone) }
                            if i < info.contacts.count - 1 { Divider().background(Theme.stroke) }
                        }
                    }
                    if editMode {
                        Button(action: { info.contacts.append(EmergencyContact(role: "Contact", name: "", phone: "")) }) {
                            Label("Add contact", systemImage: "plus.circle.fill")
                                .font(Theme.body(14)).foregroundColor(Theme.primary)
                        }
                    }
                }
            }

            SectionHeader(title: "Site & assembly", systemImage: "mappin.and.ellipse")
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    field("Site address", text: $info.siteAddress, placeholder: "Address for emergency services")
                    field("Assembly point", text: $info.assemblyPoint, placeholder: "Where to muster")
                    field("Nearest hospital / A&E", text: $info.nearestHospital, placeholder: "Name & route")
                }
            }

            SectionHeader(title: "First aid", systemImage: "cross.case.fill")
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    field("First-aid kit location", text: $info.firstAidKit, placeholder: "Where is the kit")
                    field("First aider", text: $info.firstAiderName, placeholder: "Name")
                    if editMode {
                        LabeledField(label: "First aider phone", text: $info.firstAiderPhone,
                                     placeholder: "Phone", keyboard: .phonePad)
                    } else if !info.firstAiderPhone.isEmpty {
                        Button(action: { call(info.firstAiderPhone) }) {
                            InfoRow(label: "First aider phone", value: info.firstAiderPhone, valueColor: Theme.shiftOn)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            SectionHeader(title: "Notes", systemImage: "note.text")
            CardView {
                if editMode {
                    LabeledEditor(label: "Procedure notes", text: $info.notes,
                                  placeholder: "Emergency procedure…", minHeight: 70)
                } else {
                    Text(info.notes.isEmpty ? "No notes." : info.notes)
                        .font(Theme.body(14)).foregroundColor(Theme.textPrimary)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toast($toastMessage)
        .onAppear { if !loaded { info = store.data.emergency; loaded = true } }
        .onTapGesture { UIApplication.shared.dismissKeyboard() }
    }

    @ViewBuilder private func field(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        if editMode {
            LabeledField(label: label, text: text, placeholder: placeholder)
        } else {
            InfoRow(label: label, value: text.wrappedValue.isEmpty ? "—" : text.wrappedValue)
        }
    }

    private func saveInfo() {
        store.updateEmergency(info)
        toastMessage = "Emergency card saved"
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func call(_ phone: String) {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)"),
              UIApplication.shared.canOpenURL(url) else {
            toastMessage = "No number to call"
            return
        }
        UIApplication.shared.open(url)
    }
}

private struct ContactRow: View {
    let contact: EmergencyContact
    let onCall: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.role.isEmpty ? "Contact" : contact.role)
                    .font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                Text(contact.name.isEmpty ? (contact.phone.isEmpty ? "Not set" : contact.phone) : contact.name)
                    .font(Theme.heading(16)).foregroundColor(Theme.textPrimary)
            }
            Spacer()
            Button(action: onCall) {
                HStack(spacing: 6) {
                    Image(systemName: "phone.fill")
                    Text(contact.phone.isEmpty ? "—" : contact.phone).font(Theme.caption(12))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(Capsule().fill(contact.phone.isEmpty ? Theme.textDisabled : Theme.incident))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(contact.phone.isEmpty)
        }
        .padding(.vertical, 4)
    }
}
