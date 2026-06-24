# Site Safe — iOS (SwiftUI, iOS 14+)

Daily construction-site safety for the foreman: morning toolbox talk, pre-start
PPE check, hazard & near-miss logging, incident reporting with photos, permits,
zone risk map, safety walkaround and an emergency card — **all local, no
accounts, no network**.

The defining feature is the **daily safety gate**: a shift cannot be opened
until today's toolbox talk is signed off *and* the PPE check passes, with a live
**days-without-incident** counter that any filed incident resets to zero.

---

## 1. App Overview

**Entry flow (strict):** `Splash → Onboarding (first launch only) → Main`.
No login / welcome / sign-in / profile screens anywhere.

**Architecture — MVVM**
- **Models** (`Models/`) — pure `Codable` value types (`AppData` root aggregate).
- **Store / ViewModels** (`Stores/`) — `AppStore` (`ObservableObject`, single
  `@Published var data`) is the single source of truth and exposes derived gate
  state. Screen-specific view models (`ReportsViewModel`, `RemindersViewModel`)
  back the data-driven screens.
- **Persistence** (`Persistence/`) — `PersistenceManager` (debounced JSON write +
  synchronous flush on backgrounding) and `PhotoStore` (images on disk, cached).
- **Views** (`Screens/`, `Components/`, `Navigation/`, `Splash/`, `Onboarding/`).

**Data flow:** Views read state from `@EnvironmentObject AppStore` and mutate it
through typed methods → `AppStore` writes to `PersistenceManager` → on next
launch `AppStore.init` reloads it. Photos/signatures are stored by filename via
`PhotoStore`. Theme lives in `@AppStorage("appearance")` and drives
`preferredColorScheme` app-wide.

**Features:** Daily Gate · Toolbox Talk · PPE Check · Hazard Log · Near-Miss ·
Incident Report · Zone Risk Map · Permit to Work · Safety Checklist · Emergency
Card · Reports (PDF export) · History · Reminders (local notifications) · Settings.

---

## 2. Design System

**Palette (dark, hi-vis — the hero look)**
| Role | Hex |
|---|---|
| Background / deep / soft / card / hover / border | `#15140E` / `#0F0E09` / `#1E1C12` / `#262414` / `#322E18` / `#46401F` |
| Primary hi-vis / active / highlight | `#FACC15` / `#EAB308` / `#FDE047` |
| Hazard accent / highlight | `#F97316` / `#FB923C` |
| Status: safe / shift-on / hazard / incident | `#22C55E` / `#38BDF8` / `#FACC15` / `#EF4444` |
| Text: primary / secondary / disabled | `#FEF9E7` / `#CDBF96` / `#837A5C` |

All colours are defined as adaptive `Color.dynamic(light:dark:)` in `Theme.swift`,
so the **Settings → Appearance** switch (System / Light / Dark) re-skins the whole
app immediately and persists. Default is Dark.

**Typography:** SF Rounded via `Theme.title/heading/body/caption` weights; SF Mono
for counters. **Tokens:** `Theme.Space`, `Theme.Radius`. **Motifs:** diagonal
hazard-tape stripes (`DiagonalStripes`/`HazardTape`), hard-hat badge, glow shadows.

**Components** (`Components/Components.swift`): `ActionButton`/`ActionButtonStyle`
(primary/secondary/incident/ghost), `CardView`, `StatTile`, `RiskBadge`,
`StatusPill`, `LabeledField`, `LabeledEditor`, `CounterField`, `PillSelector`,
`DaysSafeRing`, `PhotoField`, `ToggleRow`, `ScreenScaffold`, toast modifier.
UIKit bridges (`SystemPickers.swift`): camera & PHPicker, share sheet, blur,
finger `SignaturePad`.

---

## 3–8. Source layout

```
SiteSafe/
  SiteSafeApp.swift        @main — stores, theme, scenePhase flush, UIKit appearance
  RootView.swift           Splash → Onboarding → Main phase machine
  ContentView.swift        thin wrapper → RootView
  Theme/                   Theme.swift, HazardBackground.swift
  Models/                  Models.swift, SampleData.swift
  Stores/                  AppStore.swift, NotificationManager.swift
  Persistence/             PersistenceManager.swift, PhotoStore.swift
  Components/              Components.swift, SystemPickers.swift
  Navigation/              CustomTabBar.swift, RootTabView.swift
  Splash/                  SplashView.swift
  Onboarding/              OnboardingView.swift  (O1 tap-burst, O2 drag, O3 scroll, O4 long-press)
  Screens/                 DailyGate, ToolboxTalk, PPECheck, HazardLog, NearMiss,
                           IncidentReport, ZoneRiskMap, PermitToWork, SafetyChecklist,
                           EmergencyCard, Reports, History, Reminders, Settings, More
```

---

## 9. Build Instructions

- **Xcode:** 16.x. **Min deployment target:** iOS 14.0. **Devices:** iPhone / iPad.
- **No Swift Package Manager / CocoaPods / Carthage** — zero third-party dependencies.
  Only Apple frameworks (`SwiftUI`, `UIKit`, `PhotosUI`, `UserNotifications`, `PDFKit`/Core Graphics).
- **Open & run:** open `SiteSafe.xcodeproj`, select the `SiteSafe` scheme and any
  iOS 14+ simulator/device, press ⌘R.
- **Permissions:** camera & photo-library usage strings and notification
  authorization are requested on demand. Reminders use local notifications.
- **Data:** stored in the app sandbox (`Documents/sitesafe.json` + `Documents/Photos/`).
  Reset everything in **Settings → Reset All Data**; export a JSON backup or a PDF report
  from Settings / Reports.

*Start safe. Stay safe.*
