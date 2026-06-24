//
//  OnboardingView.swift
//  SiteSafe
//
//  Four interactive setup screens (O1–O4). Each builds an illustrated scene
//  from SF Symbols + Shapes + gradients and carries one distinct interaction:
//   O1 tap-to-burst, O2 drag slider, O3 scroll-driven scaling, O4 long-press.
//  Choices write the site profile / PPE set into the store, then the flow is
//  gated off forever via @AppStorage("hasCompletedOnboarding").
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: AppStore
    let onComplete: () -> Void

    @State private var page = 0
    @State private var siteType: SiteType = .residential
    @State private var crewSize: Int = 6
    @State private var hazards: Set<HazardKind> = [.height, .electrical]
    @State private var ppeSelected: Set<PPEKind> = [.helmet, .vest, .boots, .gloves, .glasses]
    @State private var ppeRequired: Set<PPEKind> = [.helmet, .vest, .boots, .gloves]

    private let titles = ["Set Site", "Set Crew", "Set Hazards", "Open Site"]

    var body: some View {
        ZStack {
            SiteBackground()
            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button(action: finish) {
                        Text("Skip").font(Theme.caption(14)).foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(.horizontal, Theme.Space.l)
                .padding(.top, Theme.Space.m)

                TabView(selection: $page) {
                    SiteTypePage(selection: $siteType).tag(0)
                    CrewSizePage(crewSize: $crewSize).tag(1)
                    HazardsPage(selected: $hazards).tag(2)
                    PPEPage(selected: $ppeSelected, required: $ppeRequired).tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<4) { i in
                        Capsule()
                            .fill(i == page ? Theme.primary : Theme.stroke)
                            .frame(width: i == page ? 26 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                    }
                }
                .padding(.vertical, 14)

                ActionButton(title: titles[page],
                             systemImage: page == 3 ? "arrow.right.circle.fill" : nil) {
                    advance()
                }
                .disabled(page == 2 && hazards.isEmpty)
                .opacity(page == 2 && hazards.isEmpty ? 0.5 : 1)
                .padding(.horizontal, Theme.Space.l)
                .padding(.bottom, Theme.Space.l)
            }
        }
    }

    private func advance() {
        if page < 3 {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        var profile = store.data.profile
        profile.siteType = siteType
        profile.crewSize = crewSize
        profile.keyHazards = Array(hazards).sorted { $0.rawValue < $1.rawValue }
        store.updateProfile(profile)
        store.setCrewSize(crewSize)
        if !ppeSelected.isEmpty {
            store.setPPESet(ppeSelected, required: ppeRequired.intersection(ppeSelected))
        }
        onComplete()
    }
}

// MARK: - O1 Site Type — tap to burst

private struct Particle: Identifiable {
    let id = UUID()
    let angle: Double
    let distance: CGFloat
    var go = false
}

private struct SiteTypePage: View {
    @Binding var selection: SiteType
    @State private var particles: [Particle] = []
    @State private var pulse = false
    @State private var isVisible = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Space.l) {
                // Scene: tappable icon with pulsing ring + burst
                ZStack {
                    Circle()
                        .stroke(Theme.primary.opacity(0.35), lineWidth: 2)
                        .frame(width: 150, height: 150)
                        .scaleEffect(pulse ? 1.12 : 0.94)
                    ForEach(particles) { p in
                        Circle()
                            .fill(Theme.hazard)
                            .frame(width: 8, height: 8)
                            .offset(x: p.go ? cos(p.angle) * p.distance : 0,
                                    y: p.go ? sin(p.angle) * p.distance : 0)
                            .opacity(p.go ? 0 : 1)
                    }
                    Circle()
                        .fill(Theme.primaryGradient)
                        .frame(width: 108, height: 108)
                        .shadow(color: Theme.glowPrimary, radius: 18)
                    Image(systemName: selection.icon)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(Theme.onPrimary)
                }
                .frame(height: 170)
                .contentShape(Circle())
                .onTapGesture { burst() }

                VStack(spacing: 6) {
                    Text("Site Type").font(Theme.title(26)).foregroundColor(Theme.textPrimary)
                    Text("Tap the hat, then pick your site. This tunes risk profiles & PPE.")
                        .font(Theme.body(14)).foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                VStack(spacing: 10) {
                    ForEach(SiteType.allCases) { type in
                        SelectRow(icon: type.icon, title: type.label, subtitle: type.blurb,
                                  selected: selection == type) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selection = type }
                            burst()
                        }
                    }
                }
                .padding(.horizontal, Theme.Space.l)
            }
            .padding(.top, 10)
        }
        .onAppear {
            isVisible = true
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) { pulse = true }
        }
        .onDisappear {
            isVisible = false
            pulse = false
            particles.removeAll()
        }
    }

    private func burst() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        particles = (0..<14).map { i in
            Particle(angle: Double(i) / 14 * 2 * .pi, distance: CGFloat.random(in: 70...110))
        }
        withAnimation(.easeOut(duration: 0.7)) {
            for i in particles.indices { particles[i].go = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            if isVisible { particles.removeAll() }
        }
    }
}

// MARK: - O2 Crew Size — drag slider

private struct CrewSizePage: View {
    @Binding var crewSize: Int
    @State private var dragX: CGFloat = 0
    private let maxCrew = 30
    private let trackHeight: CGFloat = 60

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Space.l) {
                // Scene: helmet count grows with crew size
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.l).fill(Theme.card)
                        .frame(height: 150)
                        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.l).stroke(Theme.stroke, lineWidth: 1))
                    HStack(spacing: 4) {
                        ForEach(0..<min(crewSize, 12), id: \.self) { i in
                            Image(systemName: "person.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(i % 2 == 0 ? Theme.primary : Theme.hazard)
                                .transition(.scale)
                        }
                        if crewSize > 12 {
                            Text("+\(crewSize - 12)").font(Theme.caption(13)).foregroundColor(Theme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, Theme.Space.l)

                VStack(spacing: 6) {
                    Text("Crew Size").font(Theme.title(26)).foregroundColor(Theme.textPrimary)
                    Text("Drag to set who's on site. This builds the toolbox-talk sign-in list.")
                        .font(Theme.body(14)).foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 20)
                }

                Text("\(crewSize)")
                    .font(.system(size: 54, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.primary)

                // Drag track
                GeometryReader { geo in
                    let w = geo.size.width
                    let knob: CGFloat = 54
                    let usable = w - knob
                    let pos = usable * CGFloat(crewSize - 1) / CGFloat(maxCrew - 1)
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.bgSoft)
                            .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                            .frame(height: trackHeight)
                        Capsule().fill(Theme.primaryGradient)
                            .frame(width: pos + knob, height: trackHeight)
                        Circle().fill(Theme.card)
                            .overlay(Circle().stroke(Theme.primary, lineWidth: 3))
                            .frame(width: knob, height: knob)
                            .overlay(Image(systemName: "hand.draw.fill").foregroundColor(Theme.primary))
                            .offset(x: pos)
                            .shadow(color: Theme.glowPrimary, radius: 8)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                let ratio = max(0, min(1, (v.location.x - knob / 2) / usable))
                                let newVal = Int(round(ratio * CGFloat(maxCrew - 1))) + 1
                                if newVal != crewSize {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        crewSize = max(1, min(maxCrew, newVal))
                                    }
                                }
                            }
                    )
                }
                .frame(height: trackHeight)
                .padding(.horizontal, Theme.Space.l)
            }
            .padding(.top, 10)
        }
    }
}

// MARK: - O3 Key Hazards — scroll-driven scaling, multi-select

private struct HazardsPage: View {
    @Binding var selected: Set<HazardKind>

    var body: some View {
        VStack(spacing: Theme.Space.m) {
            VStack(spacing: 6) {
                Text("Key Hazards").font(Theme.title(26)).foregroundColor(Theme.textPrimary)
                Text("Scroll & tap the risks present. These drive your hazard checklists.")
                    .font(Theme.body(14)).foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 20)
            }
            .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(HazardKind.keyChoices) { hazard in
                        GeometryReader { geo in
                            let midY = geo.frame(in: .global).midY
                            let screen = UIScreen.main.bounds.height
                            // Scale toward 1 as the row nears vertical center.
                            let dist = abs(midY - screen * 0.55)
                            let scale = max(0.86, 1 - dist / 1400)
                            HazardChoiceCard(hazard: hazard, selected: selected.contains(hazard)) {
                                toggle(hazard)
                            }
                            .scaleEffect(scale)
                            .opacity(Double(max(0.5, scale)))
                        }
                        .frame(height: 84)
                    }
                }
                .padding(.horizontal, Theme.Space.l)
                .padding(.vertical, 8)
            }
        }
    }

    private func toggle(_ h: HazardKind) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            if selected.contains(h) { selected.remove(h) } else { selected.insert(h) }
        }
    }
}

private struct HazardChoiceCard: View {
    let hazard: HazardKind
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: hazard.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(selected ? Theme.onPrimary : Theme.hazard)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(selected ? Theme.hazard : Theme.bgSoft))
                Text(hazard.label).font(Theme.heading(17)).foregroundColor(Theme.textPrimary)
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(selected ? Theme.primary : Theme.textDisabled)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m)
                .stroke(selected ? Theme.primary : Theme.stroke, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - O4 PPE Set — tap to include, long-press to mark required

private struct PPEPage: View {
    @Binding var selected: Set<PPEKind>
    @Binding var required: Set<PPEKind>

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Space.m) {
                VStack(spacing: 6) {
                    Text("PPE Set").font(Theme.title(26)).foregroundColor(Theme.textPrimary)
                    Text("Tap to include. Long-press to mark it MANDATORY for the daily PPE check.")
                        .font(Theme.body(14)).foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 20)
                }
                .padding(.top, 10)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(PPEKind.allCases) { kind in
                        PPETile(kind: kind,
                                included: selected.contains(kind),
                                required: required.contains(kind),
                                onTap: { toggleInclude(kind) },
                                onLong: { toggleRequired(kind) })
                    }
                }
                .padding(.horizontal, Theme.Space.l)

                HStack(spacing: 16) {
                    Label("Included", systemImage: "circle.fill").foregroundColor(Theme.primary)
                    Label("Mandatory", systemImage: "exclamationmark.circle.fill").foregroundColor(Theme.hazard)
                }
                .font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
            }
            .padding(.bottom, 10)
        }
    }

    private func toggleInclude(_ k: PPEKind) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selected.contains(k) {
                selected.remove(k); required.remove(k)
            } else {
                selected.insert(k)
            }
        }
    }
    private func toggleRequired(_ k: PPEKind) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selected.insert(k)
            if required.contains(k) { required.remove(k) } else { required.insert(k) }
        }
    }
}

private struct PPETile: View {
    let kind: PPEKind
    let included: Bool
    let required: Bool
    let onTap: () -> Void
    let onLong: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: kind.icon)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(included ? (required ? Theme.hazard : Theme.primary) : Theme.textDisabled)
            Text(kind.label).font(Theme.caption(12)).foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
            if required {
                Text("MANDATORY").font(.system(size: 8, weight: .heavy)).tracking(1)
                    .foregroundColor(Theme.hazard)
            } else if included {
                Text("INCLUDED").font(.system(size: 8, weight: .heavy)).tracking(1)
                    .foregroundColor(Theme.primary)
            } else {
                Text("OFF").font(.system(size: 8, weight: .heavy)).tracking(1)
                    .foregroundColor(Theme.textDisabled)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m)
            .stroke(included ? (required ? Theme.hazard : Theme.primary) : Theme.stroke,
                    lineWidth: included ? 2 : 1))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onLongPressGesture { onLong() }
    }
}

// MARK: - Shared select row

private struct SelectRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(selected ? Theme.onPrimary : Theme.primary)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(selected ? Theme.primary : Theme.bgSoft))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.heading(17)).foregroundColor(Theme.textPrimary)
                    Text(subtitle).font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(selected ? Theme.primary : Theme.textDisabled)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m)
                .stroke(selected ? Theme.primary : Theme.stroke, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
