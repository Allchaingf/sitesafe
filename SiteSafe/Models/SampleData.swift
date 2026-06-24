//
//  SampleData.swift
//  SiteSafe
//
//  Default content used the first time the app launches (or after a reset).
//  Gives the foreman a usable PPE set, walkaround checklist, zones and an
//  emergency card without forcing data entry up front.
//

import Foundation

enum SampleData {

    static func seed() -> AppData {
        var data = AppData()
        data.ppeSet = defaultPPESet
        data.crew = defaultCrew
        data.zones = defaultZones
        data.checklist = defaultChecklist
        data.emergency = defaultEmergency
        data.safeStreakStart = Calendar.current.startOfDay(for: Date())
        return data
    }

    static var defaultPPESet: [PPEItem] {
        [
            PPEItem(kind: .helmet, required: true),
            PPEItem(kind: .vest, required: true),
            PPEItem(kind: .boots, required: true),
            PPEItem(kind: .gloves, required: true),
            PPEItem(kind: .glasses, required: false),
            PPEItem(kind: .ears, required: false),
            PPEItem(kind: .mask, required: false),
            PPEItem(kind: .harness, required: false)
        ]
    }

    static var defaultCrew: [Attendee] {
        ["Site foreman", "Operative 1", "Operative 2", "Operative 3"]
            .map { Attendee(name: $0, present: true) }
    }

    static var defaultZones: [Zone] {
        [
            Zone(name: "Main entrance", risk: .low, note: "Keep walkways clear"),
            Zone(name: "Scaffold — east", risk: .high, note: "Working at height"),
            Zone(name: "Material store", risk: .medium, note: "Manual handling"),
            Zone(name: "Welfare cabin", risk: .low, note: "")
        ]
    }

    static var defaultChecklist: [ChecklistItem] {
        [
            ChecklistItem(title: "Edge protection / guardrails secure", category: "Barriers"),
            ChecklistItem(title: "Exclusion zones barriered off", category: "Barriers"),
            ChecklistItem(title: "Walkways clear of trip hazards", category: "Walkways"),
            ChecklistItem(title: "Access routes lit", category: "Lighting"),
            ChecklistItem(title: "Task lighting adequate", category: "Lighting"),
            ChecklistItem(title: "Cables protected / off the ground", category: "Electrical"),
            ChecklistItem(title: "Distribution boards locked", category: "Electrical"),
            ChecklistItem(title: "Materials stored & stacked safely", category: "Housekeeping"),
            ChecklistItem(title: "Waste / debris cleared", category: "Housekeeping"),
            ChecklistItem(title: "Safety signage in place", category: "Signage"),
            ChecklistItem(title: "Fire points / extinguishers accessible", category: "Fire")
        ]
    }

    static var defaultEmergency: EmergencyInfo {
        var info = EmergencyInfo()
        info.assemblyPoint = "Main gate car park"
        info.firstAidKit = "Site office, by the door"
        info.firstAiderName = "Site foreman"
        info.notes = "In an emergency call 911, then notify the site manager."
        info.contacts = [
            EmergencyContact(role: "Emergency services", name: "Ambulance / Fire / Police", phone: "911"),
            EmergencyContact(role: "Site manager", name: "", phone: ""),
            EmergencyContact(role: "First aider", name: "", phone: "")
        ]
        return info
    }

    /// Topics rotated for the daily toolbox talk suggestion.
    static let toolboxTopics: [String] = [
        "Working at height & edge protection",
        "Manual handling — lift smart",
        "Housekeeping & slips/trips",
        "Electrical safety & cable management",
        "Hot work & fire precautions",
        "PPE — wear it right, every time",
        "Plant & pedestrian segregation",
        "Dust control & respiratory health",
        "Permit to work discipline",
        "Reporting near-misses early"
    ]

    /// Deterministic topic suggestion for a given day.
    static func topic(for date: Date) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return toolboxTopics[day % toolboxTopics.count]
    }
}
