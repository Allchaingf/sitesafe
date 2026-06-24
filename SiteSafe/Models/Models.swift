//
//  Models.swift
//  SiteSafe
//
//  Value-type domain models. Everything is Codable + Identifiable (UUID) so the
//  whole graph serializes to one JSON file. Enums carry their own display
//  metadata (label / icon / color) to keep Views declarative.
//

import SwiftUI

// MARK: - Site profile enums

enum SiteType: String, Codable, CaseIterable, Identifiable {
    case residential, commercial, roof, demolition
    var id: String { rawValue }
    var label: String {
        switch self {
        case .residential: return "Residential"
        case .commercial: return "Commercial"
        case .roof: return "Roof"
        case .demolition: return "Demolition"
        }
    }
    var icon: String {
        switch self {
        case .residential: return "house.fill"
        case .commercial: return "building.2.fill"
        case .roof: return "triangle.fill"
        case .demolition: return "hammer.fill"
        }
    }
    var blurb: String {
        switch self {
        case .residential: return "Homes & low-rise builds"
        case .commercial: return "Offices, retail, high-rise"
        case .roof: return "Working at height, edges"
        case .demolition: return "Strip-out & structural"
        }
    }
}

enum HazardKind: String, Codable, CaseIterable, Identifiable {
    case height, electrical, dust, machinery, hotWork
    case slipTrip, manualHandling, noise, fire, chemical, confinedSpace, falling
    var id: String { rawValue }

    /// The five "key hazards" surfaced during onboarding.
    static let keyChoices: [HazardKind] = [.height, .electrical, .dust, .machinery, .hotWork]

    var label: String {
        switch self {
        case .height: return "Working at Height"
        case .electrical: return "Electrical"
        case .dust: return "Dust & Air"
        case .machinery: return "Machinery"
        case .hotWork: return "Hot Work"
        case .slipTrip: return "Slips & Trips"
        case .manualHandling: return "Manual Handling"
        case .noise: return "Noise"
        case .fire: return "Fire"
        case .chemical: return "Chemical"
        case .confinedSpace: return "Confined Space"
        case .falling: return "Falling Objects"
        }
    }
    var icon: String {
        switch self {
        case .height: return "arrow.up.to.line"
        case .electrical: return "bolt.fill"
        case .dust: return "aqi.medium"
        case .machinery: return "gearshape.2.fill"
        case .hotWork: return "flame.fill"
        case .slipTrip: return "figure.fall"
        case .manualHandling: return "shippingbox.fill"
        case .noise: return "ear.fill"
        case .fire: return "flame"
        case .chemical: return "drop.triangle.fill"
        case .confinedSpace: return "square.split.bottomrightquarter.fill"
        case .falling: return "arrow.down.to.line"
        }
    }
}

enum RiskLevel: String, Codable, CaseIterable, Identifiable {
    case low, medium, high
    var id: String { rawValue }
    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    var color: Color {
        switch self {
        case .low: return Theme.safe
        case .medium: return Theme.hazard
        case .high: return Theme.incident
        }
    }
    var weight: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}

enum HazardStatus: String, Codable, CaseIterable, Identifiable {
    case open, mitigating, closed
    var id: String { rawValue }
    var label: String {
        switch self {
        case .open: return "Open"
        case .mitigating: return "Mitigating"
        case .closed: return "Closed"
        }
    }
    var color: Color {
        switch self {
        case .open: return Theme.incident
        case .mitigating: return Theme.hazard
        case .closed: return Theme.safe
        }
    }
}

enum PPEKind: String, Codable, CaseIterable, Identifiable {
    case helmet, vest, boots, gloves, glasses, ears, mask, harness
    var id: String { rawValue }
    var label: String {
        switch self {
        case .helmet: return "Hard Hat"
        case .vest: return "Hi-Vis Vest"
        case .boots: return "Safety Boots"
        case .gloves: return "Gloves"
        case .glasses: return "Eye Protection"
        case .ears: return "Ear Protection"
        case .mask: return "Dust Mask"
        case .harness: return "Harness"
        }
    }
    var icon: String {
        switch self {
        case .helmet: return "hardhat.fill"          // falls back gracefully if unavailable
        case .vest: return "tshirt.fill"
        case .boots: return "shoe.fill"
        case .gloves: return "hand.raised.fill"
        case .glasses: return "eyeglasses"
        case .ears: return "ear.fill"
        case .mask: return "facemask.fill"
        case .harness: return "figure.climbing"
        }
    }
}

enum Severity: String, Codable, CaseIterable, Identifiable {
    case minor, moderate, serious, critical
    var id: String { rawValue }
    var label: String {
        switch self {
        case .minor: return "Minor"
        case .moderate: return "Moderate"
        case .serious: return "Serious"
        case .critical: return "Critical"
        }
    }
    var color: Color {
        switch self {
        case .minor: return Theme.warn
        case .moderate: return Theme.hazard
        case .serious: return Theme.incident
        case .critical: return Color(hex: 0xB91C1C)
        }
    }
}

enum PermitType: String, Codable, CaseIterable, Identifiable {
    case height, hotWork, electrical, confinedSpace, excavation
    var id: String { rawValue }
    var label: String {
        switch self {
        case .height: return "Work at Height"
        case .hotWork: return "Hot Work"
        case .electrical: return "Electrical"
        case .confinedSpace: return "Confined Space"
        case .excavation: return "Excavation"
        }
    }
    var icon: String {
        switch self {
        case .height: return "arrow.up.to.line"
        case .hotWork: return "flame.fill"
        case .electrical: return "bolt.fill"
        case .confinedSpace: return "square.split.bottomrightquarter.fill"
        case .excavation: return "scope"
        }
    }
    /// Default conditions suggested when a permit of this type is created.
    var defaultConditions: [String] {
        switch self {
        case .height:
            return ["Edge protection in place", "Harness inspected & anchored", "Exclusion zone below"]
        case .hotWork:
            return ["Fire extinguisher within 10m", "Combustibles removed", "Fire watch for 60 min after"]
        case .electrical:
            return ["Isolated & locked off", "Proven dead", "Competent person only"]
        case .confinedSpace:
            return ["Atmosphere tested", "Rescue plan briefed", "Top-man stationed"]
        case .excavation:
            return ["Services located (CAT scan)", "Shoring / battering in place", "Edge barriers set"]
        }
    }
}

enum PermitStatus: String, Codable, CaseIterable, Identifiable {
    case active, closed, expired
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .active: return Theme.shiftOn
        case .closed: return Theme.safe
        case .expired: return Theme.incident
        }
    }
}

enum CheckState: String, Codable, CaseIterable, Identifiable {
    case unchecked, pass, fail
    var id: String { rawValue }
    var label: String {
        switch self {
        case .unchecked: return "—"
        case .pass: return "Pass"
        case .fail: return "Fail"
        }
    }
    var color: Color {
        switch self {
        case .unchecked: return Theme.textDisabled
        case .pass: return Theme.safe
        case .fail: return Theme.incident
        }
    }
    var icon: String {
        switch self {
        case .unchecked: return "circle"
        case .pass: return "checkmark.circle.fill"
        case .fail: return "xmark.octagon.fill"
        }
    }
}

// MARK: - Structs

struct SiteProfile: Codable, Equatable {
    var siteName: String = "Main Site"
    var siteType: SiteType = .residential
    var crewSize: Int = 6
    var keyHazards: [HazardKind] = [.height, .electrical]
}

struct PPEItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: PPEKind
    var required: Bool = true
}

struct Attendee: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var present: Bool = true
}

struct ToolboxTalk: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date = Date()
    var topic: String
    var notes: String = ""
    var attendees: [Attendee] = []
    var supervisor: String = ""
    var signaturePhoto: String?      // PhotoStore filename
    var signed: Bool = false

    var presentCount: Int { attendees.filter { $0.present }.count }
}

struct PPELine: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: PPEKind
    var required: Bool
    var ok: Bool = false
    var missingNote: String = ""     // "who is missing what"
}

struct PPECheck: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date = Date()
    var lines: [PPELine] = []

    /// Passes when every required line is OK.
    var passed: Bool { lines.filter { $0.required }.allSatisfy { $0.ok } }
    var blockers: [PPELine] { lines.filter { $0.required && !$0.ok } }
}

struct Hazard: Identifiable, Codable, Equatable {
    var id = UUID()
    var createdAt: Date = Date()
    var kind: HazardKind = .slipTrip
    var zone: String = ""
    var risk: RiskLevel = .medium
    var detail: String = ""
    var mitigation: String = ""
    var photo: String?               // PhotoStore filename
    var status: HazardStatus = .open
    var closedAt: Date?
}

struct NearMiss: Identifiable, Codable, Equatable {
    var id = UUID()
    var createdAt: Date = Date()
    var summary: String = ""
    var lesson: String = ""
    var action: String = ""
    var resolved: Bool = false
}

struct Incident: Identifiable, Codable, Equatable {
    var id = UUID()
    var occurredAt: Date = Date()
    var person: String = ""
    var detail: String = ""
    var severity: Severity = .minor
    var actions: String = ""
    var photo: String?               // PhotoStore filename
    var createdAt: Date = Date()
}

struct Zone: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var risk: RiskLevel = .low
    var note: String = ""
}

struct Permit: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: PermitType = .height
    var location: String = ""
    var issuedTo: String = ""
    var issuedAt: Date = Date()
    var validUntil: Date = Date().addingTimeInterval(60 * 60 * 8)
    var conditions: [PermitCondition] = []
    var status: PermitStatus = .active

    var allConditionsMet: Bool { conditions.allSatisfy { $0.met } }
}

struct PermitCondition: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    var met: Bool = false
}

struct ChecklistItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var category: String
    var state: CheckState = .unchecked
    var note: String = ""
}

struct EmergencyContact: Identifiable, Codable, Equatable {
    var id = UUID()
    var role: String
    var name: String
    var phone: String
}

struct EmergencyInfo: Codable, Equatable {
    var siteAddress: String = ""
    var assemblyPoint: String = "Main gate / car park"
    var nearestHospital: String = ""
    var firstAidKit: String = "Site office, by the door"
    var firstAiderName: String = ""
    var firstAiderPhone: String = ""
    var notes: String = ""
    var contacts: [EmergencyContact] = []
}

// MARK: - Root aggregate

struct AppData: Codable {
    var schemaVersion: Int = 1
    var profile = SiteProfile()
    var ppeSet: [PPEItem] = []
    var crew: [Attendee] = []
    var toolboxTalks: [ToolboxTalk] = []
    var ppeChecks: [PPECheck] = []
    var hazards: [Hazard] = []
    var nearMisses: [NearMiss] = []
    var incidents: [Incident] = []
    var zones: [Zone] = []
    var permits: [Permit] = []
    var checklist: [ChecklistItem] = []
    var emergency = EmergencyInfo()
    var safeStreakStart: Date = Date()
    var openedShiftDays: [String] = []   // Fmt.dayKey values where the shift was opened
}
