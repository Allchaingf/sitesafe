//
//  NearMissView.swift
//  SiteSafe — Feature 05
//
//  Capture "it nearly happened" events with the lesson learned and the
//  corrective action, so they can be closed out before they become incidents.
//

import SwiftUI

struct NearMissView: View {
    @EnvironmentObject var store: AppStore
    @State private var editing: NearMiss?
    @State private var creatingNew = false

    private var items: [NearMiss] { store.data.nearMisses.sorted { $0.createdAt > $1.createdAt } }

    var body: some View {
        ScreenScaffold("Near-Miss Log",
                       subtitle: "\(store.unresolvedNearMisses) open · \(store.data.nearMisses.count) total") {

            ActionButton(title: "Log Near-Miss", systemImage: "plus.circle.fill") { creatingNew = true }

            if items.isEmpty {
                EmptyStateView(systemImage: "exclamationmark.bubble.fill",
                               title: "Nothing logged yet",
                               message: "Recording near-misses early stops the next one becoming an incident.")
            }

            ForEach(items) { item in
                Button(action: { editing = item }) {
                    CardView(accent: item.resolved ? Theme.safe : Theme.warn) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.summary.isEmpty ? "Near-miss" : item.summary)
                                    .font(Theme.heading(16)).foregroundColor(Theme.textPrimary)
                                    .lineLimit(2)
                                Spacer()
                                StatusPill(text: item.resolved ? "Closed" : "Open",
                                           color: item.resolved ? Theme.safe : Theme.warn)
                            }
                            if !item.lesson.isEmpty {
                                Text("Lesson: \(item.lesson)").font(Theme.caption(12))
                                    .foregroundColor(Theme.textSecondary).lineLimit(2)
                            }
                            Text(Fmt.dateTimeString(item.createdAt))
                                .font(Theme.caption(11)).foregroundColor(Theme.textDisabled)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $creatingNew) {
            NearMissEditorView(item: NearMiss(), isNew: true).environmentObject(store)
        }
        .sheet(item: $editing) { item in
            NearMissEditorView(item: item, isNew: false).environmentObject(store)
        }
    }
}

struct NearMissEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) private var presentationMode
    @State var item: NearMiss
    let isNew: Bool

    var body: some View {
        NavigationView {
            ScreenScaffold(isNew ? "Log Near-Miss" : "Edit Near-Miss") {
                CardView {
                    VStack(spacing: 12) {
                        LabeledEditor(label: "What nearly happened", text: $item.summary,
                                      placeholder: "Describe the near-miss…", minHeight: 70)
                        LabeledEditor(label: "Lesson learned", text: $item.lesson,
                                      placeholder: "What did we learn…", minHeight: 60)
                        LabeledEditor(label: "Corrective action", text: $item.action,
                                      placeholder: "Action to prevent recurrence…", minHeight: 60)
                    }
                }
                CardView {
                    ToggleRow(title: "Resolved", subtitle: "Corrective action complete",
                              systemImage: "checkmark.circle.fill", isOn: $item.resolved)
                }
                ActionButton(title: "Save Near-Miss", systemImage: "tray.and.arrow.down.fill") {
                    store.saveNearMiss(item)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    presentationMode.wrappedValue.dismiss()
                }
                if !isNew {
                    ActionButton(title: "Delete", systemImage: "trash.fill", kind: .incident) {
                        store.deleteNearMiss(item)
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
