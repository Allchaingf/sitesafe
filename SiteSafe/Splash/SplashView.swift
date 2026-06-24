//
//  SplashView.swift
//  SiteSafe
//
//  Self-contained launch animation. Three simultaneous layers:
//   1. background  — shifting hi-vis gradient glow
//   2. midground   — running diagonal hazard tape + a hard hat that settles in
//   3. foreground  — "days safe" counter coming alive + title spring entrance
//  A single coordinator Timer stages the sequence; every looping animation is
//  reset in onDisappear so nothing leaks into the main app.
//

import SwiftUI

struct SplashView: View {
    var safeDays: Int = 0
    let onFinish: () -> Void

    // Teardown guard
    @State private var isVisible = true

    // Looping layers
    @State private var tapePhase: CGFloat = 0
    @State private var glowShift = false
    @State private var hatBob = false

    // Staged reveals
    @State private var showBG = false
    @State private var showHat = false
    @State private var hatDrop: CGFloat = -160
    @State private var showLogo = false
    @State private var displayDays = 0
    @State private var exiting = false

    // Coordinator
    @State private var timer: Timer?
    @State private var elapsed: Double = 0

    var body: some View {
        ZStack {
            // ---- Layer 1: background gradient + drifting glow ----
            Theme.background.ignoresSafeArea()
            RadialGradient(gradient: Gradient(colors: [Theme.primary.opacity(0.22), .clear]),
                           center: .center, startRadius: 5, endRadius: 320)
                .scaleEffect(glowShift ? 1.15 : 0.8)
                .offset(y: glowShift ? -30 : 30)
                .opacity(showBG ? 1 : 0)
                .ignoresSafeArea()

            // ---- Layer 2: hazard tape sweep + hard hat ----
            VStack {
                Spacer()
                ZStack {
                    // Running hazard tape band behind the hat
                    DiagonalStripes(stripeWidth: 30, phase: tapePhase)
                        .fill(Theme.primary.opacity(0.16))
                        .frame(height: 150)
                        .clipped()

                    HardHatBadge()
                        .frame(width: 150, height: 120)
                        .offset(y: hatDrop)
                        .rotationEffect(.degrees(hatBob ? 2.5 : -2.5), anchor: .bottom)
                        .opacity(showHat ? 1 : 0)
                        .scaleEffect(exiting ? 1.6 : 1)
                }
                .frame(height: 160)
                .opacity(exiting ? 0 : 1)
                Spacer()
            }

            // ---- Layer 3: counter + title ----
            VStack(spacing: 26) {
                Spacer()
                Spacer()

                VStack(spacing: 4) {
                    Text("\(displayDays)")
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.primary)
                        .shadow(color: Theme.glowPrimary, radius: 18)
                    Text(displayDays == 1 ? "DAY WITHOUT INCIDENT" : "DAYS WITHOUT INCIDENT")
                        .font(Theme.caption(11)).tracking(2)
                        .foregroundColor(Theme.textSecondary)
                }
                .opacity(showLogo ? (exiting ? 0 : 1) : 0)
                .scaleEffect(showLogo ? (exiting ? 1.3 : 1) : 0.6)

                VStack(spacing: 6) {
                    Text("SITE SAFE")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundColor(Theme.textPrimary)
                    Text("Start safe. Stay safe.")
                        .font(Theme.body(15))
                        .foregroundColor(Theme.hazardHi)
                }
                .opacity(showLogo ? (exiting ? 0 : 1) : 0)
                .offset(y: showLogo ? 0 : 24)

                Spacer()
            }
            .padding(.bottom, 30)
        }
        .onAppear { start() }
        .onDisappear { teardown() }
    }

    // MARK: Sequence

    private func start() {
        isVisible = true

        // Looping layers
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            tapePhase = 120
        }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            glowShift = true
        }
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            hatBob = true
        }

        elapsed = 0
        let t = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        guard isVisible else { return }
        elapsed += 0.05

        if elapsed >= 0.1 && !showBG {
            withAnimation(.easeOut(duration: 0.6)) { showBG = true }
        }
        if elapsed >= 0.6 && !showHat {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                showHat = true
                hatDrop = 0
            }
        }
        if elapsed >= 1.4 && !showLogo {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) { showLogo = true }
        }
        // Counter comes alive between 1.4s and 2.2s
        if elapsed >= 1.4 && elapsed <= 2.25 {
            let progress = min(1, (elapsed - 1.4) / 0.8)
            displayDays = Int((Double(safeDays) * progress).rounded())
        } else if elapsed > 2.25 {
            displayDays = safeDays
        }
        if elapsed >= 2.6 && !exiting {
            withAnimation(.easeIn(duration: 0.45)) { exiting = true }
        }
        if elapsed >= 3.0 {
            timer?.invalidate(); timer = nil
            onFinish()
        }
    }

    private func teardown() {
        isVisible = false
        timer?.invalidate(); timer = nil
        tapePhase = 0
        glowShift = false
        hatBob = false
        showBG = false
        showHat = false
        hatDrop = -160
        showLogo = false
        displayDays = 0
        exiting = false
    }
}

// MARK: - Hard hat badge (custom shape, renders on every iOS version)

private struct HardHatBadge: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.bgSoft)
                .overlay(Circle().stroke(Theme.primary.opacity(0.4), lineWidth: 2))
                .shadow(color: Theme.glowPrimary, radius: 20)
            HardHatShape()
                .fill(Theme.primaryGradient)
                .overlay(
                    HardHatShape().stroke(Theme.onPrimary.opacity(0.25), lineWidth: 2)
                )
                .frame(width: 92, height: 70)
                .offset(y: 4)
        }
    }
}

private struct HardHatShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Brim — wide flat ellipse at the bottom
        p.addEllipse(in: CGRect(x: 0, y: h * 0.62, width: w, height: h * 0.26))
        // Dome — arch sitting on the brim
        let baseY = h * 0.70
        p.move(to: CGPoint(x: w * 0.16, y: baseY))
        p.addCurve(to: CGPoint(x: w * 0.84, y: baseY),
                   control1: CGPoint(x: w * 0.10, y: -h * 0.05),
                   control2: CGPoint(x: w * 0.90, y: -h * 0.05))
        p.closeSubpath()
        return p
    }
}
