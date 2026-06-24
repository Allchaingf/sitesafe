//
//  SettingsView.swift
//  SiteSafe — Feature 14
//
//  Every control is live: theme (drives preferredColorScheme app-wide), site
//  profile, key hazards, PPE set, crew, JSON backup, PDF export and reset.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("appearance") private var appearanceRaw = AppAppearance.dark.rawValue

    @State private var newCrewName = ""
    @State private var shareItem: ShareURL?
    @State private var showResetAlert = false
    @State private var toastMessage: String?

    struct ShareURL: Identifiable { let id = UUID(); let url: URL }

    private var appearance: AppAppearance {
        get { AppAppearance(rawValue: appearanceRaw) ?? .system }
    }

    var body: some View {
        ScreenScaffold("Settings", subtitle: "Tune the app to your site") {

            // Appearance
            SectionHeader(title: "Appearance", systemImage: "paintbrush.fill")
            CardView {
                HStack(spacing: 10) {
                    ForEach(AppAppearance.allCases) { mode in
                        Button(action: {
                            UISelectionFeedbackGenerator().selectionChanged()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                appearanceRaw = mode.rawValue
                            }
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: mode.icon).font(.system(size: 20, weight: .bold))
                                Text(mode.label).font(Theme.caption(12))
                            }
                            .foregroundColor(appearance == mode ? Theme.onPrimary : Theme.textSecondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: Theme.Radius.s)
                                .fill(appearance == mode ? Theme.primary : Theme.bgSoft))
                            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s)
                                .stroke(appearance == mode ? Color.clear : Theme.stroke, lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            // Site profile
            SectionHeader(title: "Site profile", systemImage: "building.2.fill")
            CardView {
                VStack(alignment: .leading, spacing: 14) {
                    LabeledField(label: "Site name", text: siteNameBinding, placeholder: "Site name")

                    Text("SITE TYPE").font(Theme.caption(11)).tracking(0.8).foregroundColor(Theme.textSecondary)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(SiteType.allCases) { type in
                            Button(action: { setSiteType(type) }) {
                                HStack(spacing: 8) {
                                    Image(systemName: type.icon)
                                    Text(type.label).font(Theme.caption(13))
                                    Spacer()
                                }
                                .foregroundColor(store.data.profile.siteType == type ? Theme.onPrimary : Theme.textPrimary)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: Theme.Radius.s)
                                    .fill(store.data.profile.siteType == type ? Theme.primary : Theme.bgSoft))
                                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s)
                                    .stroke(store.data.profile.siteType == type ? Color.clear : Theme.stroke, lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    CounterField(label: "Crew size", value: crewSizeBinding, range: 1...60)
                }
            }

            // Key hazards
            SectionHeader(title: "Key hazards", systemImage: "exclamationmark.triangle.fill")
            CardView {
                FlowChips(items: HazardKind.allCases,
                          isSelected: { store.data.profile.keyHazards.contains($0) },
                          label: { $0.label }, icon: { $0.icon },
                          onTap: { toggleHazard($0) })
            }

            // PPE set
            SectionHeader(title: "PPE set", systemImage: "checkmark.shield.fill")
            CardView {
                VStack(spacing: 0) {
                    ForEach(PPEKind.allCases) { kind in
                        PPESettingRow(
                            kind: kind,
                            item: store.data.ppeSet.first(where: { $0.kind == kind }),
                            onToggleInclude: { togglePPE(kind) },
                            onToggleRequired: { toggleRequired(kind) }
                        )
                        if kind != PPEKind.allCases.last { Divider().background(Theme.stroke) }
                    }
                }
            }

            // Crew
            SectionHeader(title: "Crew (\(store.data.crew.count))", systemImage: "person.3.fill")
            CardView {
                VStack(spacing: 10) {
                    ForEach(store.data.crew) { member in
                        HStack {
                            Image(systemName: "person.fill").foregroundColor(Theme.primary)
                            Text(member.name).font(Theme.body(14)).foregroundColor(Theme.textPrimary)
                            Spacer()
                            Button(action: { store.removeCrew(member) }) {
                                Image(systemName: "minus.circle.fill").foregroundColor(Theme.incident.opacity(0.8))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    HStack {
                        TextField("Add crew member…", text: $newCrewName)
                            .font(Theme.body(14)).foregroundColor(Theme.textPrimary)
                        Button(action: addCrew) {
                            Image(systemName: "plus.circle.fill").foregroundColor(Theme.primary)
                        }
                        .disabled(newCrewName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }

            // Data
            SectionHeader(title: "Data", systemImage: "externaldrive.fill")
            VStack(spacing: 10) {
                ActionButton(title: "Export Backup (JSON)", systemImage: "arrow.up.doc.fill", kind: .secondary) {
                    exportBackup()
                }
                ActionButton(title: "Export PDF Report", systemImage: "doc.richtext.fill", kind: .secondary) {
                    exportPDF()
                }
                ActionButton(title: "Reset All Data", systemImage: "trash.fill", kind: .incident) {
                    showResetAlert = true
                }
            }

            Text("Site Safe · v1.0 · All data stays on this device.")
                .font(Theme.caption(11)).foregroundColor(Theme.textDisabled)
                .frame(maxWidth: .infinity).padding(.top, 6)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toast($toastMessage)
        .onTapGesture { UIApplication.shared.dismissKeyboard() }
        .sheet(item: $shareItem) { item in ShareSheet(items: [item.url]) }
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text("Reset all data?"),
                message: Text("This permanently deletes all briefings, hazards, near-misses, incidents and photos, and restores defaults."),
                primaryButton: .destructive(Text("Reset")) {
                    store.resetAllData()
                    toastMessage = "All data reset"
                },
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: Bindings

    private var siteNameBinding: Binding<String> {
        Binding(get: { store.data.profile.siteName },
                set: { var p = store.data.profile; p.siteName = $0; store.updateProfile(p) })
    }
    private var crewSizeBinding: Binding<Int> {
        Binding(get: { store.data.profile.crewSize },
                set: { store.setCrewSize($0) })
    }

    private func setSiteType(_ type: SiteType) {
        UISelectionFeedbackGenerator().selectionChanged()
        var p = store.data.profile; p.siteType = type; store.updateProfile(p)
    }
    private func toggleHazard(_ h: HazardKind) {
        UISelectionFeedbackGenerator().selectionChanged()
        var p = store.data.profile
        if let idx = p.keyHazards.firstIndex(of: h) { p.keyHazards.remove(at: idx) } else { p.keyHazards.append(h) }
        store.updateProfile(p)
    }
    private func togglePPE(_ kind: PPEKind) {
        if let item = store.data.ppeSet.first(where: { $0.kind == kind }) {
            store.removePPE(item)
        } else {
            store.addPPE(kind)
        }
    }
    private func toggleRequired(_ kind: PPEKind) {
        guard let item = store.data.ppeSet.first(where: { $0.kind == kind }) else {
            store.addPPE(kind); return
        }
        store.togglePPERequired(item)
    }
    private func addCrew() {
        store.addCrew(newCrewName)
        newCrewName = ""
        toastMessage = "Crew updated"
    }

    private func exportBackup() {
        if let url = PersistenceManager.shared.exportBackup(store.data) {
            shareItem = ShareURL(url: url)
        } else { toastMessage = "Backup failed" }
    }
    private func exportPDF() {
        if let url = ReportsViewModel().makePDF(store) {
            shareItem = ShareURL(url: url)
        } else { toastMessage = "PDF failed" }
    }
}

// MARK: - PPE setting row

private struct PPESettingRow: View {
    let kind: PPEKind
    let item: PPEItem?
    let onToggleInclude: () -> Void
    let onToggleRequired: () -> Void

    private var included: Bool { item != nil }
    private var required: Bool { item?.required ?? false }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: kind.icon)
                .foregroundColor(included ? Theme.primary : Theme.textDisabled).frame(width: 26)
            Text(kind.label).font(Theme.body(14)).foregroundColor(Theme.textPrimary)
            Spacer()
            if included {
                Button(action: onToggleRequired) {
                    Text(required ? "MANDATORY" : "OPTIONAL")
                        .font(.system(size: 9, weight: .heavy)).tracking(0.8)
                        .foregroundColor(required ? .white : Theme.textSecondary)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(Capsule().fill(required ? Theme.hazard : Theme.bgSoft))
                        .overlay(Capsule().stroke(required ? Color.clear : Theme.stroke, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
            Button(action: onToggleInclude) {
                Image(systemName: included ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22)).foregroundColor(included ? Theme.safe : Theme.textDisabled)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 9)
    }
}

// MARK: - Flow chips (wrapping multi-select)

private struct FlowChips<T: Hashable>: View {
    let items: [T]
    let isSelected: (T) -> Bool
    let label: (T) -> String
    let icon: (T) -> String
    let onTap: (T) -> Void

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(items, id: \.self) { item in
                let sel = isSelected(item)
                Button(action: { onTap(item) }) {
                    HStack(spacing: 6) {
                        Image(systemName: icon(item)).font(.system(size: 12, weight: .bold))
                        Text(label(item)).font(Theme.caption(12)).lineLimit(1)
                    }
                    .foregroundColor(sel ? Theme.onPrimary : Theme.textSecondary)
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .background(Capsule().fill(sel ? Theme.hazard : Theme.bgSoft))
                    .overlay(Capsule().stroke(sel ? Color.clear : Theme.stroke, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}
