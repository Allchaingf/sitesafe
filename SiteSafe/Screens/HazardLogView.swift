//
//  HazardLogView.swift
//  SiteSafe — Feature 04
//
//  The hazard register: type, zone, risk level, photo, mitigation and status.
//  Hazards drive the open-items snapshot and the "high risk" badge.
//

import SwiftUI

struct HazardLogView: View {
    @EnvironmentObject var store: AppStore
    @State private var filter: HazardFilter = .open
    @State private var editing: Hazard?
    @State private var creatingNew = false

    enum HazardFilter: String, CaseIterable, Hashable {
        case all, open, mitigating, closed
        var label: String { rawValue.capitalized }
    }

    private var filtered: [Hazard] {
        let items = store.data.hazards.sorted {
            if $0.risk.weight != $1.risk.weight { return $0.risk.weight > $1.risk.weight }
            return $0.createdAt > $1.createdAt
        }
        switch filter {
        case .all: return items
        case .open: return items.filter { $0.status == .open }
        case .mitigating: return items.filter { $0.status == .mitigating }
        case .closed: return items.filter { $0.status == .closed }
        }
    }

    var body: some View {
        ScreenScaffold("Hazard Log",
                       subtitle: "\(store.openHazardCount) open · \(store.highRiskOpenCount) high risk") {

            ActionButton(title: "Log Hazard", systemImage: "plus.circle.fill") {
                creatingNew = true
            }

            PillSelector(options: HazardFilter.allCases, selection: $filter,
                         label: { $0.label },
                         tint: { _ in Theme.primary })

            if filtered.isEmpty {
                EmptyStateView(systemImage: "exclamationmark.triangle.fill",
                               title: "No hazards here",
                               message: "Log site hazards as you spot them — keep the crew ahead of risk.")
            }

            ForEach(filtered) { hazard in
                Button(action: { editing = hazard }) {
                    HazardRow(hazard: hazard)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $creatingNew) {
            HazardEditorView(hazard: Hazard(), isNew: true).environmentObject(store)
        }
        .sheet(item: $editing) { hazard in
            HazardEditorView(hazard: hazard, isNew: false).environmentObject(store)
        }
    }
}

private struct HazardRow: View {
    let hazard: Hazard
    var body: some View {
        CardView(accent: hazard.risk.color) {
            HStack(spacing: 12) {
                if let img = PhotoStore.shared.loadImage(named: hazard.photo) {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: 54, height: 54).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
                } else {
                    Image(systemName: hazard.kind.icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(hazard.risk.color)
                        .frame(width: 54, height: 54)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Theme.bgSoft))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(hazard.kind.label).font(Theme.heading(16)).foregroundColor(Theme.textPrimary)
                    Text(hazard.zone.isEmpty ? "Site-wide" : hazard.zone)
                        .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                    HStack(spacing: 6) {
                        RiskBadge(risk: hazard.risk)
                        StatusPill(text: hazard.status.label, color: hazard.status.color)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(Theme.textDisabled)
            }
        }
    }
}

// MARK: - Editor

struct HazardEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) private var presentationMode

    @State var hazard: Hazard
    let isNew: Bool
    @State private var showSourceDialog = false
    @State private var imageSource: ImageSource?

    var body: some View {
        NavigationView {
            ScreenScaffold(isNew ? "Log Hazard" : "Edit Hazard") {

                SectionHeader(title: "Hazard type", systemImage: "exclamationmark.triangle.fill")
                CardView {
                    Menu {
                        ForEach(HazardKind.allCases) { kind in
                            Button(action: { hazard.kind = kind }) {
                                Label(kind.label, systemImage: kind.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: hazard.kind.icon).foregroundColor(Theme.hazard)
                            Text(hazard.kind.label).foregroundColor(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down").foregroundColor(Theme.textSecondary)
                        }
                        .font(Theme.body())
                    }
                }

                SectionHeader(title: "Zone", systemImage: "mappin.and.ellipse")
                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledField(label: "Location", text: $hazard.zone, placeholder: "e.g. Scaffold — east")
                        if !store.data.zones.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(store.data.zones) { zone in
                                        Button(action: { hazard.zone = zone.name }) {
                                            Text(zone.name).font(Theme.caption(12))
                                                .foregroundColor(Theme.primary)
                                                .padding(.horizontal, 12).padding(.vertical, 7)
                                                .background(Capsule().fill(Theme.bgSoft))
                                                .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                }

                SectionHeader(title: "Risk level", systemImage: "gauge")
                PillSelector(options: RiskLevel.allCases, selection: $hazard.risk,
                             label: { $0.label }, tint: { $0.color })

                SectionHeader(title: "Details & mitigation", systemImage: "text.alignleft")
                CardView {
                    VStack(spacing: 12) {
                        LabeledEditor(label: "What's the hazard", text: $hazard.detail,
                                      placeholder: "Describe the hazard…", minHeight: 70)
                        LabeledEditor(label: "Control measures", text: $hazard.mitigation,
                                      placeholder: "How will it be controlled / removed…", minHeight: 70)
                    }
                }

                SectionHeader(title: "Photo", systemImage: "camera.fill")
                CardView {
                    PhotoField(filename: hazard.photo,
                               onPick: { showSourceDialog = true },
                               onClear: { clearPhoto() })
                }

                SectionHeader(title: "Status", systemImage: "flag.fill")
                PillSelector(options: HazardStatus.allCases, selection: $hazard.status,
                             label: { $0.label }, tint: { $0.color })

                ActionButton(title: "Save Hazard", systemImage: "tray.and.arrow.down.fill") { save() }

                if !isNew {
                    ActionButton(title: "Delete Hazard", systemImage: "trash.fill", kind: .incident) {
                        store.deleteHazard(hazard)
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
        PhotoStore.shared.delete(named: hazard.photo)
        hazard.photo = PhotoStore.shared.save(image)
    }
    private func clearPhoto() {
        PhotoStore.shared.delete(named: hazard.photo)
        hazard.photo = nil
    }
    private func save() {
        store.saveHazard(hazard)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        presentationMode.wrappedValue.dismiss()
    }
}
