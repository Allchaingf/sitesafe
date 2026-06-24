//
//  AppStore.swift
//  SiteSafe
//
//  Single source of truth. Holds the whole AppData graph in one @Published
//  property, exposes typed CRUD (generic upsert/remove) and the derived state
//  that powers the daily safety gate and the "days without incident" counter.
//

import SwiftUI
import Combine

// MARK: - History feed

enum HistoryKind {
    case briefing, hazard, nearMiss, incident, permit
    var icon: String {
        switch self {
        case .briefing: return "megaphone.fill"
        case .hazard: return "exclamationmark.triangle.fill"
        case .nearMiss: return "exclamationmark.bubble.fill"
        case .incident: return "cross.case.fill"
        case .permit: return "doc.text.fill"
        }
    }
    var tint: Color {
        switch self {
        case .briefing: return Theme.primary
        case .hazard: return Theme.hazard
        case .nearMiss: return Theme.warn
        case .incident: return Theme.incident
        case .permit: return Theme.shiftOn
        }
    }
}

struct HistoryEntry: Identifiable {
    let id: UUID
    let date: Date
    let kind: HistoryKind
    let title: String
    let subtitle: String
}

// MARK: - Store

final class AppStore: ObservableObject {
    @Published var data: AppData

    private let persistence = PersistenceManager.shared
    private let photos = PhotoStore.shared

    init() {
        self.data = persistence.load()
    }

    // MARK: Generic helpers

    private func upsert<T: Identifiable>(_ item: T, into keyPath: WritableKeyPath<AppData, [T]>)
    where T.ID == UUID {
        if let i = data[keyPath: keyPath].firstIndex(where: { $0.id == item.id }) {
            data[keyPath: keyPath][i] = item
        } else {
            data[keyPath: keyPath].append(item)
        }
        save()
    }

    private func remove<T: Identifiable>(_ item: T, from keyPath: WritableKeyPath<AppData, [T]>)
    where T.ID == UUID {
        data[keyPath: keyPath].removeAll { $0.id == item.id }
        save()
    }

    private func save() { persistence.save(data) }
    func flush() { persistence.flush(data) }

    // MARK: - Profile & setup

    func updateProfile(_ p: SiteProfile) { data.profile = p; save() }

    // MARK: PPE set

    func addPPE(_ kind: PPEKind) {
        guard !data.ppeSet.contains(where: { $0.kind == kind }) else { return }
        data.ppeSet.append(PPEItem(kind: kind, required: true)); save()
    }
    func togglePPERequired(_ item: PPEItem) {
        guard let i = data.ppeSet.firstIndex(where: { $0.id == item.id }) else { return }
        data.ppeSet[i].required.toggle(); save()
    }
    func removePPE(_ item: PPEItem) { remove(item, from: \.ppeSet) }
    func setPPESet(_ kinds: Set<PPEKind>, required: Set<PPEKind>) {
        data.ppeSet = kinds.map { PPEItem(kind: $0, required: required.contains($0)) }
            .sorted { $0.kind.rawValue < $1.kind.rawValue }
        save()
    }

    // MARK: Crew

    func addCrew(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        data.crew.append(Attendee(name: trimmed, present: true)); save()
    }
    func removeCrew(_ a: Attendee) { remove(a, from: \.crew) }

    /// Sets the crew size on the profile and grows/shrinks the named crew list
    /// to match (preserving existing names).
    func setCrewSize(_ n: Int) {
        let count = max(1, n)
        data.profile.crewSize = count
        if data.crew.count < count {
            for i in data.crew.count..<count {
                data.crew.append(Attendee(name: "Operative \(i + 1)", present: true))
            }
        } else if data.crew.count > count {
            data.crew = Array(data.crew.prefix(count))
        }
        save()
    }

    // MARK: - Toolbox talk

    var todayTalk: ToolboxTalk? {
        data.toolboxTalks.first { Calendar.current.isDateInToday($0.date) && $0.signed }
    }
    var todayBriefingDone: Bool { todayTalk != nil }

    /// A draft for today's talk (existing in-progress one, or a fresh template).
    func makeTodayTalk() -> ToolboxTalk {
        if let existing = data.toolboxTalks.first(where: { Calendar.current.isDateInToday($0.date) }) {
            return existing
        }
        return ToolboxTalk(
            date: Date(),
            topic: SampleData.topic(for: Date()),
            attendees: data.crew.map { Attendee(name: $0.name, present: true) },
            supervisor: data.profile.siteName
        )
    }
    func saveTalk(_ talk: ToolboxTalk) { upsert(talk, into: \.toolboxTalks) }
    func deleteTalk(_ talk: ToolboxTalk) {
        photos.delete(named: talk.signaturePhoto)
        remove(talk, from: \.toolboxTalks)
    }

    // MARK: - PPE check

    var todayPPECheck: PPECheck? {
        data.ppeChecks.first { Calendar.current.isDateInToday($0.date) }
    }
    var todayPPEPassed: Bool { todayPPECheck?.passed ?? false }

    func makeTodayPPECheck() -> PPECheck {
        if let existing = todayPPECheck { return existing }
        let lines = data.ppeSet.map { PPELine(kind: $0.kind, required: $0.required, ok: false) }
        return PPECheck(date: Date(), lines: lines)
    }
    func savePPECheck(_ check: PPECheck) { upsert(check, into: \.ppeChecks) }

    // MARK: - Daily gate

    var isShiftOpen: Bool { data.openedShiftDays.contains(Fmt.dayKey(Date())) }
    var canOpenShift: Bool { todayBriefingDone && todayPPEPassed && !isShiftOpen }

    func openShift() {
        let key = Fmt.dayKey(Date())
        guard canOpenShift, !data.openedShiftDays.contains(key) else { return }
        data.openedShiftDays.append(key)
        save()
    }

    // MARK: - Days without incident

    var daysWithoutIncident: Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: data.safeStreakStart)
        let today = cal.startOfDay(for: Date())
        return max(0, cal.dateComponents([.day], from: start, to: today).day ?? 0)
    }

    // MARK: - Hazards

    func saveHazard(_ h: Hazard) {
        var copy = h
        if copy.status == .closed && copy.closedAt == nil { copy.closedAt = Date() }
        if copy.status != .closed { copy.closedAt = nil }
        upsert(copy, into: \.hazards)
    }
    func deleteHazard(_ h: Hazard) {
        photos.delete(named: h.photo)
        remove(h, from: \.hazards)
    }
    var openHazards: [Hazard] { data.hazards.filter { $0.status != .closed } }
    var openHazardCount: Int { openHazards.count }
    var highRiskOpenCount: Int { openHazards.filter { $0.risk == .high }.count }

    // MARK: - Near-miss

    func saveNearMiss(_ n: NearMiss) { upsert(n, into: \.nearMisses) }
    func deleteNearMiss(_ n: NearMiss) { remove(n, from: \.nearMisses) }
    var unresolvedNearMisses: Int { data.nearMisses.filter { !$0.resolved }.count }

    // MARK: - Incidents (reset the streak)

    func saveIncident(_ inc: Incident, isNew: Bool) {
        if let i = data.incidents.firstIndex(where: { $0.id == inc.id }) {
            data.incidents[i] = inc
        } else {
            data.incidents.append(inc)
        }
        if isNew {
            data.safeStreakStart = Calendar.current.startOfDay(for: Date())
        }
        save()
    }
    func deleteIncident(_ inc: Incident) {
        photos.delete(named: inc.photo)
        remove(inc, from: \.incidents)
    }

    // MARK: - Zones

    func saveZone(_ z: Zone) { upsert(z, into: \.zones) }
    func deleteZone(_ z: Zone) { remove(z, from: \.zones) }

    // MARK: - Permits

    func savePermit(_ p: Permit) { upsert(p, into: \.permits) }
    func deletePermit(_ p: Permit) { remove(p, from: \.permits) }
    func closePermit(_ p: Permit) {
        var copy = p; copy.status = .closed; upsert(copy, into: \.permits)
    }
    var activePermits: [Permit] { data.permits.filter { $0.status == .active } }

    // MARK: - Checklist

    func setChecklistState(_ item: ChecklistItem, _ state: CheckState) {
        guard let i = data.checklist.firstIndex(where: { $0.id == item.id }) else { return }
        data.checklist[i].state = state; save()
    }
    func setChecklistNote(_ item: ChecklistItem, _ note: String) {
        guard let i = data.checklist.firstIndex(where: { $0.id == item.id }) else { return }
        data.checklist[i].note = note; save()
    }
    func addChecklistItem(_ title: String, category: String) {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        data.checklist.append(ChecklistItem(title: t, category: category.isEmpty ? "General" : category))
        save()
    }
    func deleteChecklistItem(_ item: ChecklistItem) { remove(item, from: \.checklist) }
    func resetChecklist() {
        for i in data.checklist.indices {
            data.checklist[i].state = .unchecked
            data.checklist[i].note = ""
        }
        save()
    }
    var checklistProgress: Double {
        guard !data.checklist.isEmpty else { return 0 }
        let done = data.checklist.filter { $0.state != .unchecked }.count
        return Double(done) / Double(data.checklist.count)
    }
    var checklistFailures: Int { data.checklist.filter { $0.state == .fail }.count }

    // MARK: - Emergency

    func updateEmergency(_ e: EmergencyInfo) { data.emergency = e; save() }
    func addEmergencyContact() {
        data.emergency.contacts.append(EmergencyContact(role: "Contact", name: "", phone: ""))
        save()
    }
    func updateEmergencyContact(_ c: EmergencyContact) {
        guard let i = data.emergency.contacts.firstIndex(where: { $0.id == c.id }) else { return }
        data.emergency.contacts[i] = c; save()
    }
    func removeEmergencyContact(_ c: EmergencyContact) {
        data.emergency.contacts.removeAll { $0.id == c.id }; save()
    }

    // MARK: - History feed

    var history: [HistoryEntry] {
        var entries: [HistoryEntry] = []
        for t in data.toolboxTalks {
            entries.append(HistoryEntry(id: t.id, date: t.date, kind: .briefing,
                                        title: "Toolbox talk", subtitle: t.topic))
        }
        for h in data.hazards {
            entries.append(HistoryEntry(id: h.id, date: h.createdAt, kind: .hazard,
                                        title: "Hazard — \(h.kind.label)",
                                        subtitle: "\(h.risk.label) risk· \(h.zone.isEmpty ? "site" : h.zone)"))
        }
        for n in data.nearMisses {
            entries.append(HistoryEntry(id: n.id, date: n.createdAt, kind: .nearMiss,
                                        title: "Near-miss",
                                        subtitle: n.summary.isEmpty ? "Logged" : n.summary))
        }
        for i in data.incidents {
            entries.append(HistoryEntry(id: i.id, date: i.occurredAt, kind: .incident,
                                        title: "Incident — \(i.severity.label)",
                                        subtitle: i.detail.isEmpty ? "Reported" : i.detail))
        }
        for p in data.permits {
            entries.append(HistoryEntry(id: p.id, date: p.issuedAt, kind: .permit,
                                        title: "Permit — \(p.type.label)",
                                        subtitle: p.location.isEmpty ? p.status.label : p.location))
        }
        return entries.sorted { $0.date > $1.date }
    }

    // MARK: - Reset

    func resetAllData() {
        photos.wipe()
        data = SampleData.seed()
        persistence.saveNow(data)
    }
}
