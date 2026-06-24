//
//  SafetyChecklistView.swift
//  SiteSafe — Feature 09
//
//  The site walkaround: barriers, walkways, lighting, electrics and more.
//  Each item is pass / fail, with a live progress ring and a reset for the
//  next round. Items can be added or removed.
//

import SwiftUI

struct SafetyChecklistView: View {
    @EnvironmentObject var store: AppStore
    @State private var newTitle = ""
    @State private var newCategory = "General"
    @State private var toastMessage: String?

    private var categories: [String] {
        var seen: [String] = []
        for item in store.data.checklist where !seen.contains(item.category) { seen.append(item.category) }
        return seen
    }

    var body: some View {
        ScreenScaffold("Safety Checklist", subtitle: "Walk the site by the rules") {

            // Progress
            CardView(accent: store.checklistFailures > 0 ? Theme.incident : Theme.safe) {
                HStack(spacing: 16) {
                    ProgressCircle(progress: store.checklistProgress,
                                   tint: store.checklistFailures > 0 ? Theme.hazard : Theme.safe)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(Int(store.checklistProgress * 100))% checked")
                            .font(Theme.heading(17)).foregroundColor(Theme.textPrimary)
                        Text(store.checklistFailures > 0
                             ? "\(store.checklistFailures) item(s) failing"
                             : "No failures recorded")
                            .font(Theme.caption(12))
                            .foregroundColor(store.checklistFailures > 0 ? Theme.incident : Theme.safe)
                    }
                    Spacer()
                }
            }

            ActionButton(title: "Reset Checklist", systemImage: "arrow.counterclockwise", kind: .secondary) {
                store.resetChecklist()
                toastMessage = "Checklist reset"
            }

            ForEach(categories, id: \.self) { category in
                SectionHeader(title: category, systemImage: "checklist")
                CardView {
                    VStack(spacing: 0) {
                        let items = store.data.checklist.filter { $0.category == category }
                        ForEach(items) { item in
                            ChecklistRow(
                                item: item,
                                onPass: { store.setChecklistState(item, item.state == .pass ? .unchecked : .pass) },
                                onFail: { store.setChecklistState(item, item.state == .fail ? .unchecked : .fail) },
                                onDelete: { store.deleteChecklistItem(item) }
                            )
                            if item.id != items.last?.id { Divider().background(Theme.stroke) }
                        }
                    }
                }
            }

            SectionHeader(title: "Add item", systemImage: "plus")
            CardView {
                VStack(spacing: 12) {
                    LabeledField(label: "Check item", text: $newTitle, placeholder: "e.g. Scaffold tags current")
                    HStack {
                        Text("Category").font(Theme.caption(11)).tracking(0.8).foregroundColor(Theme.textSecondary)
                        Spacer()
                        Menu {
                            ForEach(defaultCategories, id: \.self) { c in
                                Button(c) { newCategory = c }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(newCategory).foregroundColor(Theme.primary)
                                Image(systemName: "chevron.up.chevron.down").foregroundColor(Theme.textSecondary)
                            }
                            .font(Theme.body(14))
                        }
                    }
                    ActionButton(title: "Add to Checklist", systemImage: "plus.circle.fill",
                                 enabled: !newTitle.trimmingCharacters(in: .whitespaces).isEmpty) {
                        store.addChecklistItem(newTitle, category: newCategory)
                        newTitle = ""
                        toastMessage = "Item added"
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toast($toastMessage)
        .onTapGesture { UIApplication.shared.dismissKeyboard() }
    }

    private var defaultCategories: [String] {
        ["Barriers", "Walkways", "Lighting", "Electrical", "Housekeeping", "Signage", "Fire", "General"]
    }
}

private struct ChecklistRow: View {
    let item: ChecklistItem
    let onPass: () -> Void
    let onFail: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.state.icon).foregroundColor(item.state.color)
            Text(item.title).font(Theme.body(14)).foregroundColor(Theme.textPrimary)
            Spacer()
            stateButton("Pass", color: Theme.safe, active: item.state == .pass, action: onPass)
            stateButton("Fail", color: Theme.incident, active: item.state == .fail, action: onFail)
            Button(action: onDelete) {
                Image(systemName: "trash").font(.system(size: 13)).foregroundColor(Theme.textDisabled)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 9)
    }

    private func stateButton(_ title: String, color: Color, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            UISelectionFeedbackGenerator().selectionChanged()
            action()
        }) {
            Text(title)
                .font(Theme.caption(11))
                .foregroundColor(active ? .white : color)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(active ? color : color.opacity(0.14)))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct ProgressCircle: View {
    let progress: Double
    let tint: Color
    var body: some View {
        ZStack {
            Circle().stroke(Theme.stroke.opacity(0.5), lineWidth: 7)
            Circle().trim(from: 0, to: CGFloat(progress))
                .stroke(tint, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))").font(Theme.heading(15)).foregroundColor(Theme.textPrimary)
        }
        .frame(width: 56, height: 56)
        .animation(.easeOut(duration: 0.4), value: progress)
    }
}
