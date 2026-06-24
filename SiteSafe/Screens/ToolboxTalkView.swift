//
//  ToolboxTalkView.swift
//  SiteSafe — Feature 02
//
//  The morning briefing: topic of the day, attendee sign-in, supervisor
//  signature and notes. Signing off marks today's briefing complete, which is
//  one half of the daily gate.
//

import SwiftUI

struct ToolboxTalkView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) private var presentationMode

    @State private var talk: ToolboxTalk = ToolboxTalk(topic: "")
    @State private var strokes: [[CGPoint]] = []
    @State private var canvasSize: CGSize = .zero
    @State private var loaded = false
    @State private var toastMessage: String?

    private var canSign: Bool {
        !talk.topic.trimmingCharacters(in: .whitespaces).isEmpty
            && (!strokes.isEmpty || talk.signaturePhoto != nil)
    }

    var body: some View {
        ScreenScaffold("Toolbox Talk", subtitle: Fmt.weekday(Date())) {

            if talk.signed {
                CardView(accent: Theme.safe) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.safe)
                        Text("Signed off for today").font(Theme.heading(16)).foregroundColor(Theme.textPrimary)
                        Spacer()
                    }
                }
            }

            SectionHeader(title: "Topic of the day", systemImage: "lightbulb.fill")
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    LabeledField(label: "Topic", text: $talk.topic, placeholder: "e.g. Working at height")
                    LabeledField(label: "Supervisor", text: $talk.supervisor, placeholder: "Name")
                }
            }

            SectionHeader(title: "Attendance · \(talk.presentCount)/\(talk.attendees.count)",
                          systemImage: "person.3.fill")
            CardView {
                VStack(spacing: 0) {
                    if talk.attendees.isEmpty {
                        Text("No crew set. Add crew in Settings.")
                            .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                            .padding(.vertical, 8)
                    }
                    ForEach(talk.attendees.indices, id: \.self) { i in
                        Button(action: { toggleAttendee(i) }) {
                            HStack {
                                Image(systemName: talk.attendees[i].present ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(talk.attendees[i].present ? Theme.safe : Theme.textDisabled)
                                Text(talk.attendees[i].name).font(Theme.body())
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Text(talk.attendees[i].present ? "Present" : "Absent")
                                    .font(Theme.caption(11))
                                    .foregroundColor(talk.attendees[i].present ? Theme.safe : Theme.textSecondary)
                            }
                            .padding(.vertical, 9)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        if i < talk.attendees.count - 1 { Divider().background(Theme.stroke) }
                    }
                }
            }

            SectionHeader(title: "Notes", systemImage: "note.text")
            CardView { LabeledEditor(label: "Briefing notes", text: $talk.notes,
                                     placeholder: "Key points, questions raised, actions…") }

            SectionHeader(title: "Supervisor signature", systemImage: "signature")
            CardView {
                VStack(spacing: 10) {
                    if let existing = PhotoStore.shared.loadImage(named: talk.signaturePhoto), strokes.isEmpty {
                        Image(uiImage: existing).resizable().scaledToFit()
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
                    }
                    SignaturePad(strokes: $strokes, canvasSize: $canvasSize)
                    Button(action: clearSignature) {
                        Label("Clear", systemImage: "eraser.fill")
                            .font(Theme.caption(13)).foregroundColor(Theme.hazard)
                    }
                }
            }

            ActionButton(title: talk.signed ? "Update & Re-sign" : "Save & Sign Off",
                         systemImage: "checkmark.seal.fill", enabled: canSign) {
                signOff()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toast($toastMessage)
        .onAppear(perform: loadIfNeeded)
        .onTapGesture { UIApplication.shared.dismissKeyboard() }
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        talk = store.makeTodayTalk()
        loaded = true
    }

    private func toggleAttendee(_ i: Int) {
        UISelectionFeedbackGenerator().selectionChanged()
        talk.attendees[i].present.toggle()
    }

    private func clearSignature() {
        strokes = []
        if talk.signaturePhoto != nil {
            PhotoStore.shared.delete(named: talk.signaturePhoto)
            talk.signaturePhoto = nil
        }
    }

    private func signOff() {
        if !strokes.isEmpty, let image = renderSignatureImage(strokes: strokes, size: canvasSize) {
            PhotoStore.shared.delete(named: talk.signaturePhoto)
            talk.signaturePhoto = PhotoStore.shared.save(image)
            strokes = []
        }
        talk.signed = true
        talk.date = Date()
        store.saveTalk(talk)
        toastMessage = "Briefing signed off"
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
