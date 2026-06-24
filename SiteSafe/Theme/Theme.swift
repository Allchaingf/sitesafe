//
//  Theme.swift
//  SiteSafe
//
//  Central design system: hi-vis dark palette, adaptive colors, gradients,
//  typography, spacing/radius tokens and cached formatters. iOS 14 safe.
//

import SwiftUI
import UIKit

// MARK: - Color / UIColor hex helpers

extension UIColor {
    /// Create a UIColor from a 0xRRGGBB integer.
    convenience init(hex: UInt, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(hex & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self = Color(UIColor(hex: hex, alpha: CGFloat(alpha)))
    }

    /// Adaptive color that resolves differently for light / dark interface styles.
    static func dynamic(light: UInt, dark: UInt) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

// MARK: - App appearance (theme switcher)

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

// MARK: - Theme tokens

enum Theme {

    // Surfaces (dark = hero, light = legible counterpart)
    static let bg        = Color.dynamic(light: 0xFBF7E4, dark: 0x15140E)
    static let bgDeep    = Color.dynamic(light: 0xF2ECD2, dark: 0x0F0E09)
    static let bgSoft    = Color.dynamic(light: 0xFFFDF2, dark: 0x1E1C12)
    static let card      = Color.dynamic(light: 0xFFFFFF, dark: 0x262414)
    static let cardHover = Color.dynamic(light: 0xFBF3D2, dark: 0x322E18)
    static let stroke    = Color.dynamic(light: 0xE3D9A6, dark: 0x46401F)

    // Hi-vis primary (yellow)
    static let primary   = Color(hex: 0xFACC15)
    static let primaryActive = Color(hex: 0xEAB308)
    static let primaryHi = Color(hex: 0xFDE047)

    // Hazard accent (orange)
    static let hazard    = Color(hex: 0xF97316)
    static let hazardHi  = Color(hex: 0xFB923C)

    // Status colors
    static let safe      = Color(hex: 0x22C55E)
    static let shiftOn   = Color(hex: 0x38BDF8)
    static let warn      = Color(hex: 0xFACC15)
    static let incident  = Color(hex: 0xEF4444)

    // Text
    static let textPrimary   = Color.dynamic(light: 0x2A2710, dark: 0xFEF9E7)
    static let textSecondary = Color.dynamic(light: 0x6B6340, dark: 0xCDBF96)
    static let textDisabled  = Color.dynamic(light: 0xA59C74, dark: 0x837A5C)

    // Button text
    static let onPrimary   = Color(hex: 0x15140E)
    static let onSecondary = Color.dynamic(light: 0x6B5A12, dark: 0xFEF3C7)
    static let onIncident  = Color.white

    // MARK: Gradients

    static var background: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [bgDeep, bg, bgSoft]),
            startPoint: .top, endPoint: .bottom
        )
    }

    static var primaryGradient: LinearGradient {
        LinearGradient(colors: [primaryHi, primary, primaryActive],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var hazardGradient: LinearGradient {
        LinearGradient(colors: [hazardHi, hazard],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var incidentGradient: LinearGradient {
        LinearGradient(colors: [Color(hex: 0xF87171), incident],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: Glows (use as .shadow)
    static let glowPrimary  = Color(hex: 0xFACC15, alpha: 0.38)
    static let glowHazard   = Color(hex: 0xF97316, alpha: 0.30)
    static let glowIncident = Color(hex: 0xEF4444, alpha: 0.35)
    static let shadowSoft   = Color.black.opacity(0.72)

    // MARK: Typography
    static func title(_ size: CGFloat = 27) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func heading(_ size: CGFloat = 19) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func body(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .medium, design: .rounded) }
    static func caption(_ size: CGFloat = 12) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func mono(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .bold, design: .monospaced) }

    // MARK: Spacing
    enum Space {
        static let xs: CGFloat = 6
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 22
        static let xl: CGFloat = 30
    }

    // MARK: Corner radius
    enum Radius {
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 22
        static let pill: CGFloat = 999
    }
}

// MARK: - Cached formatters (no .formatted() on iOS 14)

enum Fmt {
    private static let dateMed: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()
    private static let timeShort: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .none; f.timeStyle = .short; return f
    }()
    private static let dateTime: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f
    }()
    private static let dayKeyFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()
    private static let weekdayFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEEE, d MMM"; return f
    }()

    static func date(_ d: Date) -> String { dateMed.string(from: d) }
    static func time(_ d: Date) -> String { timeShort.string(from: d) }
    static func dateTimeString(_ d: Date) -> String { dateTime.string(from: d) }
    static func dayKey(_ d: Date) -> String { dayKeyFmt.string(from: d) }
    static func weekday(_ d: Date) -> String { weekdayFmt.string(from: d) }

    static func relativeDay(_ d: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(d) { return "Today" }
        if cal.isDateInYesterday(d) { return "Yesterday" }
        if cal.isDateInTomorrow(d) { return "Tomorrow" }
        return dateMed.string(from: d)
    }
}

// MARK: - Keyboard dismissal (no @FocusState on iOS 14)

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
