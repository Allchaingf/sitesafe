//
//  ZoneRiskMapView.swift
//  SiteSafe — Feature 07
//
//  A simple visual map of site zones colour-coded by risk level, with the
//  number of open hazards in each. Tap a zone to edit; add new zones.
//

import SwiftUI

struct ZoneRiskMapView: View {
    @EnvironmentObject var store: AppStore
    @State private var editing: Zone?
    @State private var creatingNew = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private func openHazards(in zone: Zone) -> Int {
        store.data.hazards.filter { $0.status != .closed && $0.zone == zone.name }.count
    }

    var body: some View {
        ScreenScaffold("Zone Risk Map", subtitle: "\(store.data.zones.count) zones mapped") {

            ActionButton(title: "Add Zone", systemImage: "plus.circle.fill") { creatingNew = true }

            // Legend
            HStack(spacing: 14) {
                ForEach(RiskLevel.allCases) { level in
                    HStack(spacing: 5) {
                        Circle().fill(level.color).frame(width: 10, height: 10)
                        Text(level.label).font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                    }
                }
                Spacer()
            }

            if store.data.zones.isEmpty {
                EmptyStateView(systemImage: "map.fill", title: "No zones yet",
                               message: "Map your site into zones and flag the high-risk areas.")
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(store.data.zones) { zone in
                    Button(action: { editing = zone }) {
                        ZoneTile(zone: zone, openHazards: openHazards(in: zone))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $creatingNew) {
            ZoneEditorView(zone: Zone(name: ""), isNew: true).environmentObject(store)
        }
        .sheet(item: $editing) { zone in
            ZoneEditorView(zone: zone, isNew: false).environmentObject(store)
        }
    }
}

private struct ZoneTile: View {
    let zone: Zone
    let openHazards: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(zone.risk.color).frame(width: 14, height: 14)
                    .shadow(color: zone.risk.color.opacity(0.6), radius: 5)
                Spacer()
                if openHazards > 0 {
                    Text("\(openHazards)")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                        .padding(5).background(Circle().fill(Theme.hazard))
                }
            }
            Text(zone.name).font(Theme.heading(16)).foregroundColor(Theme.textPrimary).lineLimit(1)
            Text(zone.note.isEmpty ? zone.risk.label + " risk" : zone.note)
                .font(Theme.caption(11)).foregroundColor(Theme.textSecondary).lineLimit(2)
            RiskBadge(risk: zone.risk)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(zone.risk.color.opacity(0.45), lineWidth: 1.4))
    }
}

struct ZoneEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    @State var zone: Zone
    let isNew: Bool

    private var canSave: Bool { !zone.name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationView {
            ScreenScaffold(isNew ? "Add Zone" : "Edit Zone") {
                CardView {
                    VStack(spacing: 12) {
                        LabeledField(label: "Zone name", text: $zone.name, placeholder: "e.g. Scaffold — east")
                        LabeledEditor(label: "Note", text: $zone.note,
                                      placeholder: "Specific risks / access notes…", minHeight: 60)
                    }
                }
                SectionHeader(title: "Risk level", systemImage: "gauge")
                PillSelector(options: RiskLevel.allCases, selection: $zone.risk,
                             label: { $0.label }, tint: { $0.color })

                ActionButton(title: "Save Zone", systemImage: "tray.and.arrow.down.fill", enabled: canSave) {
                    store.saveZone(zone)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    presentationMode.wrappedValue.dismiss()
                }
                if !isNew {
                    ActionButton(title: "Delete Zone", systemImage: "trash.fill", kind: .incident) {
                        store.deleteZone(zone)
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
}
