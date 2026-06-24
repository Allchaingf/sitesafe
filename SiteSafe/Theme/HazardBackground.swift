//
//  HazardBackground.swift
//  SiteSafe
//
//  Signature visual motif: diagonal hi-vis hazard tape + the app's dark
//  screen background. Reused by splash, headers and as the global backdrop.
//

import SwiftUI

// MARK: - Diagonal stripe shape

/// A set of parallel diagonal stripes filling the bounds. `phase` shifts the
/// stripes horizontally for an animated "tape running" effect.
struct DiagonalStripes: Shape {
    var stripeWidth: CGFloat = 26
    var phase: CGFloat = 0

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step = stripeWidth * 2
        let offset = phase.truncatingRemainder(dividingBy: step)
        var x = -rect.height - step + offset
        while x < rect.width + step {
            var p = Path()
            p.move(to: CGPoint(x: x, y: rect.maxY))
            p.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
            p.addLine(to: CGPoint(x: x + rect.height + stripeWidth, y: rect.minY))
            p.addLine(to: CGPoint(x: x + stripeWidth, y: rect.maxY))
            p.closeSubpath()
            path.addPath(p)
            x += step
        }
        return path
    }
}

// MARK: - Hazard tape band

/// A horizontal band of yellow/black diagonal hazard tape.
struct HazardTape: View {
    var height: CGFloat = 16
    var animated: Bool = false
    var phase: CGFloat = 0

    var body: some View {
        ZStack {
            Color(hex: 0x1A1810)
            DiagonalStripes(stripeWidth: height * 0.85, phase: animated ? phase : 0)
                .fill(Theme.primary)
        }
        .frame(height: height)
        .clipped()
        .overlay(
            Rectangle().fill(Theme.stroke).frame(height: 1), alignment: .top
        )
        .overlay(
            Rectangle().fill(Theme.stroke).frame(height: 1), alignment: .bottom
        )
    }
}

// MARK: - Global screen background

struct SiteBackground: View {
    var body: some View {
        ZStack {
            Theme.background
            // Faint hazard stripes anchored to the top-trailing corner.
            DiagonalStripes(stripeWidth: 34)
                .fill(Theme.primary.opacity(0.04))
                .frame(width: 320, height: 320)
                .rotationEffect(.degrees(0))
                .offset(x: 150, y: -260)
            // Soft hazard glow bottom-leading.
            Circle()
                .fill(Theme.hazard.opacity(0.06))
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .offset(x: -150, y: 320)
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Place the standard Site Safe backdrop behind a screen's content.
    func siteBackground() -> some View {
        ZStack {
            SiteBackground()
            self
        }
    }
}
