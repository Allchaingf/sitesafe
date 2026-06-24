//
//  IncidentReportView.swift
//  SiteSafe — Feature 06
//
//  Record incidents (time, person, what happened, severity, photo, actions).
//  Filing a new incident resets the "days without incident" counter.
//

import SwiftUI

struct IncidentReportView: View {
    @EnvironmentObject var store: AppStore
    @State private var editing: Incident?
    @State private var creatingNew = false

    private var items: [Incident] { store.data.incidents.sorted { $0.occurredAt > $1.occurredAt } }

    var body: some View {
        ScreenScaffold("Incidents", subtitle: "\(store.daysWithoutIncident) days without incident") {

            CardView(accent: store.daysWithoutIncident == 0 ? Theme.incident : Theme.safe) {
                HStack(spacing: 14) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 26)).foregroundColor(store.daysWithoutIncident == 0 ? Theme.incident : Theme.safe)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(store.daysWithoutIncident) days safe")
                            .font(Theme.heading(18)).foregroundColor(Theme.textPrimary)
                        Text(store.data.incidents.isEmpty ? "No incidents recorded"
                                                          : "\(store.data.incidents.count) on record")
                            .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                }
            }

            ActionButton(title: "Report Incident", systemImage: "exclamationmark.octagon.fill",
                         kind: .incident) { creatingNew = true }

            if items.isEmpty {
                EmptyStateView(systemImage: "checkmark.shield.fill",
                               title: "No incidents — keep it up",
                               message: "Every incident filed here resets the counter and logs the actions taken.")
            }

            ForEach(items) { inc in
                Button(action: { editing = inc }) {
                    CardView(accent: inc.severity.color) {
                        HStack(spacing: 12) {
                            if let img = PhotoStore.shared.loadImage(named: inc.photo) {
                                Image(uiImage: img).resizable().scaledToFill()
                                    .frame(width: 54, height: 54).clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
                            } else {
                                Image(systemName: "cross.case.fill")
                                    .font(.system(size: 20, weight: .bold)).foregroundColor(inc.severity.color)
                                    .frame(width: 54, height: 54)
                                    .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Theme.bgSoft))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(inc.person.isEmpty ? "Incident" : inc.person)
                                    .font(Theme.heading(16)).foregroundColor(Theme.textPrimary)
                                Text(inc.detail.isEmpty ? "No description" : inc.detail)
                                    .font(Theme.caption(12)).foregroundColor(Theme.textSecondary).lineLimit(1)
                                HStack(spacing: 6) {
                                    StatusPill(text: inc.severity.label, color: inc.severity.color, filled: true)
                                    Text(Fmt.dateTimeString(inc.occurredAt))
                                        .font(Theme.caption(11)).foregroundColor(Theme.textDisabled)
                                }
                            }
                            Spacer()
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $creatingNew) {
            IncidentEditorView(incident: Incident(), isNew: true).environmentObject(store)
        }
        .sheet(item: $editing) { inc in
            IncidentEditorView(incident: inc, isNew: false).environmentObject(store)
        }
    }
}

struct IncidentEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    @State var incident: Incident
    let isNew: Bool
    @State private var showSourceDialog = false
    @State private var imageSource: ImageSource?

    var body: some View {
        NavigationView {
            ScreenScaffold(isNew ? "Report Incident" : "Edit Incident") {

                if isNew {
                    CardView(accent: Theme.incident) {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(Theme.incident)
                            Text("Filing this incident resets the days-without-incident counter to 0.")
                                .font(Theme.caption(12)).foregroundColor(Theme.textPrimary)
                        }
                    }
                }

                SectionHeader(title: "When", systemImage: "clock.fill")
                CardView {
                    DatePicker("Occurred at", selection: $incident.occurredAt,
                               in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                        .accentColor(Theme.primary)
                        .foregroundColor(Theme.textPrimary)
                        .font(Theme.body())
                }

                SectionHeader(title: "Who & what", systemImage: "person.fill")
                CardView {
                    VStack(spacing: 12) {
                        LabeledField(label: "Person involved", text: $incident.person, placeholder: "Name / role")
                        LabeledEditor(label: "What happened", text: $incident.detail,
                                      placeholder: "Describe the incident…", minHeight: 80)
                    }
                }

                SectionHeader(title: "Severity", systemImage: "gauge.high")
                PillSelector(options: Severity.allCases, selection: $incident.severity,
                             label: { $0.label }, tint: { $0.color })

                SectionHeader(title: "Photo", systemImage: "camera.fill")
                CardView {
                    PhotoField(filename: incident.photo,
                               onPick: { showSourceDialog = true },
                               onClear: { clearPhoto() })
                }

                SectionHeader(title: "Actions taken", systemImage: "checklist")
                CardView {
                    LabeledEditor(label: "Immediate & follow-up actions", text: $incident.actions,
                                  placeholder: "First aid given, area secured, reported to…", minHeight: 80)
                }

                ActionButton(title: isNew ? "File Incident" : "Save Changes",
                             systemImage: "tray.and.arrow.down.fill",
                             kind: isNew ? .incident : .primary) { save() }

                if !isNew {
                    ActionButton(title: "Delete", systemImage: "trash.fill", kind: .incident) {
                        store.deleteIncident(incident)
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
            .actionSheet(isPresented: $showSourceDialog) {
                ActionSheet(title: Text("Add photo"), buttons: [
                    .default(Text("Camera")) { imageSource = .camera },
                    .default(Text("Photo Library")) { imageSource = .library },
                    .cancel()
                ])
            }
            .sheet(item: $imageSource) { source in
                switch source {
                case .camera: CameraPicker { handlePicked($0) }
                case .library: PhotoLibraryPicker { handlePicked($0) }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func handlePicked(_ image: UIImage) {
        PhotoStore.shared.delete(named: incident.photo)
        incident.photo = PhotoStore.shared.save(image)
    }
    private func clearPhoto() {
        PhotoStore.shared.delete(named: incident.photo)
        incident.photo = nil
    }
    private func save() {
        if isNew { incident.createdAt = Date() }
        store.saveIncident(incident, isNew: isNew)
        UINotificationFeedbackGenerator().notificationOccurred(isNew ? .warning : .success)
        presentationMode.wrappedValue.dismiss()
    }
}
