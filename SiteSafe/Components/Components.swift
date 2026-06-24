//
//  Components.swift
//  SiteSafe
//
//  The shared component library: every screen is built from these so the
//  hi-vis dark look stays consistent. All custom-styled (no plain SwiftUI),
//  with spring micro-animations and iOS 14-safe APIs.
//

import SwiftUI

// MARK: - Buttons

struct ActionButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, incident, ghost }
    var kind: Kind = .primary
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.heading(16))
            .foregroundColor(foreground)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .stroke(strokeColor, lineWidth: kind == .ghost ? 1.4 : 0)
            )
            .shadow(color: glow, radius: configuration.isPressed ? 4 : 12, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch kind {
        case .primary: return Theme.onPrimary
        case .secondary: return Theme.onSecondary
        case .incident: return Theme.onIncident
        case .ghost: return Theme.textPrimary
        }
    }
    @ViewBuilder private var background: some View {
        switch kind {
        case .primary: Theme.primaryGradient
        case .secondary: Theme.card
        case .incident: Theme.incidentGradient
        case .ghost: Color.clear
        }
    }
    private var strokeColor: Color { kind == .ghost ? Theme.stroke : .clear }
    private var glow: Color {
        switch kind {
        case .primary: return Theme.glowPrimary
        case .incident: return Theme.glowIncident
        default: return .clear
        }
    }
}

struct ActionButton: View {
    let title: String
    var systemImage: String? = nil
    var kind: ActionButtonStyle.Kind = .primary
    var fullWidth: Bool = true
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if let img = systemImage { Image(systemName: img) }
                Text(title)
            }
        }
        .buttonStyle(ActionButtonStyle(kind: kind, fullWidth: fullWidth))
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
    }
}

// MARK: - Card

struct CardView<Content: View>: View {
    var accent: Color? = nil
    var padding: CGFloat = Theme.Space.m
    let content: () -> Content

    init(accent: Color? = nil, padding: CGFloat = Theme.Space.m, @ViewBuilder content: @escaping () -> Content) {
        self.accent = accent
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .stroke(accent?.opacity(0.5) ?? Theme.stroke, lineWidth: 1)
            )
            .overlay(accentStripe, alignment: .leading)
            .shadow(color: Theme.shadowSoft.opacity(0.4), radius: 10, x: 0, y: 6)
    }

    @ViewBuilder private var accentStripe: some View {
        if let accent = accent {
            RoundedRectangle(cornerRadius: 2)
                .fill(accent)
                .frame(width: 4)
                .padding(.vertical, 10)
                .padding(.leading, 3)
        }
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil
    var accent: Color = Theme.primary

    var body: some View {
        HStack(spacing: 8) {
            if let img = systemImage {
                Image(systemName: img).foregroundColor(accent).font(.system(size: 14, weight: .bold))
            }
            Text(title.uppercased())
                .font(Theme.caption(12))
                .tracking(1.2)
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
    }
}

// MARK: - Stat tile

struct StatTile: View {
    let value: String
    let label: String
    var systemImage: String
    var tint: Color = Theme.primary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage).foregroundColor(tint).font(.system(size: 18, weight: .bold))
                Spacer()
            }
            Text(value).font(Theme.title(24)).foregroundColor(Theme.textPrimary)
            Text(label).font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                .lineLimit(2)
        }
        .padding(Theme.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous).stroke(tint.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Badges & pills

struct RiskBadge: View {
    let risk: RiskLevel
    var body: some View {
        Text(risk.label.uppercased())
            .font(Theme.caption(10))
            .tracking(0.8)
            .foregroundColor(risk.color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(risk.color.opacity(0.16)))
            .overlay(Capsule().stroke(risk.color.opacity(0.5), lineWidth: 1))
    }
}

struct StatusPill: View {
    let text: String
    let color: Color
    var filled: Bool = false
    var body: some View {
        Text(text.uppercased())
            .font(Theme.caption(10))
            .tracking(0.8)
            .foregroundColor(filled ? Theme.onPrimary : color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(filled ? color : color.opacity(0.16)))
            .overlay(Capsule().stroke(color.opacity(0.5), lineWidth: filled ? 0 : 1))
    }
}

// MARK: - Inputs

struct LabeledField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased()).font(Theme.caption(11)).tracking(0.8)
                .foregroundColor(Theme.textSecondary)
            TextField(placeholder, text: $text)
                .font(Theme.body())
                .foregroundColor(Theme.textPrimary)
                .keyboardType(keyboard)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Theme.bgSoft))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s).stroke(Theme.stroke, lineWidth: 1))
        }
    }
}

struct LabeledEditor: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 90

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased()).font(Theme.caption(11)).tracking(0.8)
                .foregroundColor(Theme.textSecondary)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(Theme.body())
                        .foregroundColor(Theme.textDisabled)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                }
                TextEditor(text: $text)
                    .font(Theme.body())
                    .foregroundColor(Theme.textPrimary)
                    .padding(8)
                    .frame(minHeight: minHeight)
            }
            .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Theme.bgSoft))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s).stroke(Theme.stroke, lineWidth: 1))
        }
    }
}

/// Stepper-style counter used for crew size etc.
struct CounterField: View {
    let label: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...200

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(Theme.body()).foregroundColor(Theme.textPrimary)
            }
            Spacer()
            HStack(spacing: 0) {
                stepButton(system: "minus") {
                    if value > range.lowerBound { value -= 1 }
                }
                Text("\(value)")
                    .font(Theme.heading(18))
                    .foregroundColor(Theme.textPrimary)
                    .frame(minWidth: 44)
                stepButton(system: "plus") {
                    if value < range.upperBound { value += 1 }
                }
            }
            .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Theme.bgSoft))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s).stroke(Theme.stroke, lineWidth: 1))
        }
    }

    private func stepButton(system: String, _ action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { action() }
        }) {
            Image(systemName: system)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Theme.primary)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Generic pill selector (risk / severity / status etc.)

struct PillSelector<T: Hashable>: View {
    let options: [T]
    @Binding var selection: T
    let label: (T) -> String
    var tint: (T) -> Color = { _ in Theme.primary }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isSel = option == selection
                Button(action: {
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selection = option }
                }) {
                    Text(label(option))
                        .font(Theme.caption(13))
                        .foregroundColor(isSel ? Theme.onPrimary : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.s)
                                .fill(isSel ? tint(option) : Theme.bgSoft)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.s)
                                .stroke(isSel ? Color.clear : Theme.stroke, lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    var systemImage: String = "tray"
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .light))
                .foregroundColor(Theme.primary.opacity(0.8))
            Text(title).font(Theme.heading(17)).foregroundColor(Theme.textPrimary)
            Text(message).font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Screen scaffold

struct ScreenScaffold<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    let content: () -> Content

    init(_ title: String, subtitle: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(Theme.title(28)).foregroundColor(Theme.textPrimary)
                    if let s = subtitle {
                        Text(s).font(Theme.caption(13)).foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(.top, 4)
                content()
            }
            .padding(Theme.Space.m)
            .padding(.bottom, 120) // clear the custom tab bar
        }
        .siteBackground()
    }
}

// MARK: - Days-safe ring

struct DaysSafeRing: View {
    let days: Int
    var size: CGFloat = 180
    var animated: Bool = true
    @State private var trim: CGFloat = 0

    private var safetyColor: Color {
        switch days {
        case 0: return Theme.incident
        case 1..<7: return Theme.hazard
        default: return Theme.safe
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.stroke.opacity(0.4), lineWidth: 14)
            Circle()
                .trim(from: 0, to: trim)
                .stroke(
                    AngularGradient(gradient: Gradient(colors: [safetyColor.opacity(0.5), safetyColor]),
                                    center: .center),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: safetyColor.opacity(0.5), radius: 10)
            VStack(spacing: 2) {
                Text("\(days)")
                    .font(.system(size: size * 0.34, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text(days == 1 ? "DAY SAFE" : "DAYS SAFE")
                    .font(Theme.caption(11)).tracking(1.5)
                    .foregroundColor(safetyColor)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            let target: CGFloat = min(1, 0.08 + CGFloat(min(days, 30)) / 33.0)
            if animated {
                withAnimation(.easeOut(duration: 1.0)) { trim = target }
            } else { trim = target }
        }
    }
}

// MARK: - Photo picker button + thumbnail

struct PhotoField: View {
    var filename: String?
    let onPick: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PHOTO").font(Theme.caption(11)).tracking(0.8).foregroundColor(Theme.textSecondary)
            if let image = PhotoStore.shared.loadImage(named: filename) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(8)
                }
            } else {
                Button(action: onPick) {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill").font(.system(size: 26))
                        Text("Add photo").font(Theme.caption(12))
                    }
                    .foregroundColor(Theme.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Theme.bgSoft))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.s)
                            .stroke(style: StrokeStyle(lineWidth: 1.4, dash: [6]))
                            .foregroundColor(Theme.stroke)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Info row

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = Theme.textPrimary
    var body: some View {
        HStack {
            Text(label).font(Theme.body(14)).foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value).font(Theme.body(14)).foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Toggle row (custom styled)

struct ToggleRow: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            if let img = systemImage {
                Image(systemName: img).foregroundColor(Theme.primary).frame(width: 24)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.body()).foregroundColor(Theme.textPrimary)
                if let s = subtitle {
                    Text(s).font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Theme.primary))
        }
    }
}

// MARK: - Save confirmation toast

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            if let msg = message {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.safe)
                    Text(msg).font(Theme.body(14)).foregroundColor(Theme.textPrimary)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Capsule().fill(Theme.card))
                .overlay(Capsule().stroke(Theme.safe.opacity(0.6), lineWidth: 1))
                .shadow(color: Theme.shadowSoft, radius: 10, y: 4)
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { message = nil }
                    }
                }
            }
        }
    }
}

extension View {
    func toast(_ message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}
