//
//  ReportsView.swift
//  SiteSafe — Feature 11
//
//  Roll-up of safety activity with a selectable PDF export (briefings,
//  hazards, near-misses, incidents, days-safe). Built with UIGraphicsPDFRenderer
//  + NSAttributedString (iOS 14 safe) and shared via the system share sheet.
//

import SwiftUI

enum ReportSection: String, CaseIterable, Identifiable {
    case summary, toolboxTalks, hazards, nearMisses, incidents, permits, checklist
    var id: String { rawValue }
    var label: String {
        switch self {
        case .summary: return "Summary"
        case .toolboxTalks: return "Toolbox talks"
        case .hazards: return "Hazards"
        case .nearMisses: return "Near-misses"
        case .incidents: return "Incidents"
        case .permits: return "Permits"
        case .checklist: return "Checklist"
        }
    }
    var icon: String {
        switch self {
        case .summary: return "chart.pie.fill"
        case .toolboxTalks: return "megaphone.fill"
        case .hazards: return "exclamationmark.triangle.fill"
        case .nearMisses: return "exclamationmark.bubble.fill"
        case .incidents: return "cross.case.fill"
        case .permits: return "doc.text.fill"
        case .checklist: return "checklist"
        }
    }
}

final class ReportsViewModel: ObservableObject {
    @Published var selected: Set<ReportSection> = Set(ReportSection.allCases)

    func toggle(_ section: ReportSection) {
        if selected.contains(section) { selected.remove(section) } else { selected.insert(section) }
    }

    func makePDF(_ store: AppStore) -> URL? {
        let pageW: CGFloat = 595, pageH: CGFloat = 842, margin: CGFloat = 42
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("SiteSafe-Report.pdf")

        let title: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .heavy),
            .foregroundColor: UIColor(hex: 0x1A1810)
        ]
        let h2: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .bold),
            .foregroundColor: UIColor(hex: 0x8A6D08)
        ]
        let body: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor(hex: 0x222222)
        ]
        let muted: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor(hex: 0x888888)
        ]

        do {
            try renderer.writePDF(to: url) { ctx in
                var y: CGFloat = margin
                ctx.beginPage()

                func ensure(_ h: CGFloat) {
                    if y + h > pageH - margin { ctx.beginPage(); y = margin }
                }
                func draw(_ text: String, _ attr: [NSAttributedString.Key: Any], _ height: CGFloat, indent: CGFloat = 0) {
                    ensure(height)
                    (text as NSString).draw(in: CGRect(x: margin + indent, y: y,
                                                       width: pageW - margin * 2 - indent, height: height),
                                            withAttributes: attr)
                    y += height
                }
                func gap(_ h: CGFloat) { y += h }
                func heading(_ text: String) {
                    gap(8); ensure(22)
                    draw(text.uppercased(), h2, 20)
                    UIColor(hex: 0xFACC15).setFill()
                    ctx.fill(CGRect(x: margin, y: y, width: pageW - margin * 2, height: 1.5))
                    gap(8)
                }

                draw("Site Safe — Safety Report", title, 32)
                draw("\(store.data.profile.siteName) · \(store.data.profile.siteType.label) site", body, 16)
                draw("Generated \(Fmt.dateTimeString(Date()))", muted, 16)
                gap(6)

                if selected.contains(.summary) {
                    heading("Summary")
                    draw("Days without incident: \(store.daysWithoutIncident)", body, 16)
                    draw("Crew size: \(store.data.profile.crewSize)", body, 16)
                    draw("Toolbox talks logged: \(store.data.toolboxTalks.count)", body, 16)
                    draw("Open hazards: \(store.openHazardCount) (high risk: \(store.highRiskOpenCount))", body, 16)
                    draw("Near-misses: \(store.data.nearMisses.count) (\(store.unresolvedNearMisses) open)", body, 16)
                    draw("Incidents on record: \(store.data.incidents.count)", body, 16)
                    draw("Active permits: \(store.activePermits.count)", body, 16)
                }

                if selected.contains(.toolboxTalks) {
                    heading("Toolbox talks")
                    if store.data.toolboxTalks.isEmpty { draw("None recorded.", muted, 14) }
                    for t in store.data.toolboxTalks.sorted(by: { $0.date > $1.date }) {
                        draw("• \(Fmt.date(t.date)) — \(t.topic)", body, 15)
                        draw("Attendance: \(t.presentCount)/\(t.attendees.count) · Signed: \(t.signed ? "Yes" : "No")", muted, 13, indent: 12)
                    }
                }

                if selected.contains(.hazards) {
                    heading("Hazards")
                    if store.data.hazards.isEmpty { draw("None recorded.", muted, 14) }
                    for h in store.data.hazards.sorted(by: { $0.risk.weight > $1.risk.weight }) {
                        draw("• [\(h.risk.label)] \(h.kind.label) — \(h.zone.isEmpty ? "site" : h.zone) (\(h.status.label))", body, 15)
                        if !h.mitigation.isEmpty { draw("Control: \(h.mitigation)", muted, 13, indent: 12) }
                    }
                }

                if selected.contains(.nearMisses) {
                    heading("Near-misses")
                    if store.data.nearMisses.isEmpty { draw("None recorded.", muted, 14) }
                    for n in store.data.nearMisses.sorted(by: { $0.createdAt > $1.createdAt }) {
                        draw("• \(Fmt.date(n.createdAt)) — \(n.summary)", body, 15)
                        if !n.action.isEmpty { draw("Action: \(n.action)", muted, 13, indent: 12) }
                    }
                }

                if selected.contains(.incidents) {
                    heading("Incidents")
                    if store.data.incidents.isEmpty { draw("None recorded.", muted, 14) }
                    for i in store.data.incidents.sorted(by: { $0.occurredAt > $1.occurredAt }) {
                        draw("• [\(i.severity.label)] \(Fmt.dateTimeString(i.occurredAt)) — \(i.person)", body, 15)
                        if !i.detail.isEmpty { draw(i.detail, muted, 13, indent: 12) }
                        if !i.actions.isEmpty { draw("Actions: \(i.actions)", muted, 13, indent: 12) }
                    }
                }

                if selected.contains(.permits) {
                    heading("Permits to work")
                    if store.data.permits.isEmpty { draw("None recorded.", muted, 14) }
                    for p in store.data.permits.sorted(by: { $0.issuedAt > $1.issuedAt }) {
                        draw("• \(p.type.label) — \(p.location) (\(p.status.label))", body, 15)
                        draw("Conditions met: \(p.conditions.filter { $0.met }.count)/\(p.conditions.count)", muted, 13, indent: 12)
                    }
                }

                if selected.contains(.checklist) {
                    heading("Safety checklist")
                    if store.data.checklist.isEmpty { draw("Empty.", muted, 14) }
                    for c in store.data.checklist {
                        draw("• [\(c.state.label)] \(c.title) (\(c.category))", body, 15)
                    }
                }

                gap(14)
                draw("Generated by Site Safe — Start safe. Stay safe.", muted, 16)
            }
            return url
        } catch { return nil }
    }
}

struct ReportsView: View {
    @EnvironmentObject var store: AppStore
    @StateObject private var vm = ReportsViewModel()
    @State private var shareItem: ShareURL?
    @State private var toastMessage: String?

    struct ShareURL: Identifiable { let id = UUID(); let url: URL }

    var body: some View {
        ScreenScaffold("Reports", subtitle: "Roll-up & PDF export") {

            HStack(spacing: 10) {
                StatTile(value: "\(store.daysWithoutIncident)", label: "Days safe",
                         systemImage: "shield.fill", tint: Theme.safe)
                StatTile(value: "\(store.data.toolboxTalks.count)", label: "Briefings",
                         systemImage: "megaphone.fill", tint: Theme.primary)
            }
            HStack(spacing: 10) {
                StatTile(value: "\(store.data.hazards.count)", label: "Hazards",
                         systemImage: "exclamationmark.triangle.fill", tint: Theme.hazard)
                StatTile(value: "\(store.data.incidents.count)", label: "Incidents",
                         systemImage: "cross.case.fill", tint: Theme.incident)
            }

            SectionHeader(title: "Include in PDF", systemImage: "doc.text.fill")
            CardView {
                VStack(spacing: 0) {
                    ForEach(ReportSection.allCases) { section in
                        Button(action: { vm.toggle(section) }) {
                            HStack(spacing: 12) {
                                Image(systemName: section.icon).foregroundColor(Theme.primary).frame(width: 24)
                                Text(section.label).font(Theme.body()).foregroundColor(Theme.textPrimary)
                                Spacer()
                                Image(systemName: vm.selected.contains(section) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(vm.selected.contains(section) ? Theme.safe : Theme.textDisabled)
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        if section != ReportSection.allCases.last { Divider().background(Theme.stroke) }
                    }
                }
            }

            ActionButton(title: "Export PDF", systemImage: "square.and.arrow.up.fill",
                         enabled: !vm.selected.isEmpty) { exportPDF() }
        }
        .navigationBarHidden(true)
        .toast($toastMessage)
        .sheet(item: $shareItem) { item in ShareSheet(items: [item.url]) }
    }

    private func exportPDF() {
        if let url = vm.makePDF(store) {
            shareItem = ShareURL(url: url)
        } else {
            toastMessage = "Could not build PDF"
        }
    }
}
