# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
swift build                    # Debug build
swift run                      # Build + run the app
./scripts/build-app.sh 1.0.0  # Build release .app bundle in dist/
```

No test suite is configured. No linter is configured.

## Architecture

macOS SwiftUI app (Swift 6.0, macOS 15+) built with Swift Package Manager. Generates professional invoices (factures) and quotes (devis) as PDF, with multi-currency support (EUR, USD, USDC, USDT, BTC, ETH) and blockchain payment tracking. Includes a timesheet system for tracking weekly hours.

### Data Flow

`FacioApp` creates a `DataStore` (singleton `@Observable`), `SyncService`, `AuthService`, and `NetworkMonitor`, injected via `.environment()`. All views read/write through `DataStore`. Persistence is JSON files in `~/Library/Application Support/Facio/` (documents.json, clients.json, company.json, timesheets.json). Optional Supabase sync with anonymous auth.

### Key Architectural Decisions

- **`@Observable` + Environment** — no SwiftData. DataStore manages all CRUD and serialization manually via JSON Codable.
- **PDF via CoreText/CoreGraphics** — `PDFGenerator` draws directly to `CGContext`. Coordinate system is top-down (y=0 = top of page), converted to CG bottom-up via `cgY()`. Text rendered with `CTLineCreateWithAttributedString` + `CTLineDraw`.
- **Frozen client data** — client info is copied into each Document (not referenced). Old invoices retain original client data even if the client is updated later.
- **Safe array access pattern** — all `ForEach` + `Binding` combos access items by UUID lookup (`first(where: { $0.id == id })`), never by captured index. This prevents crashes when items are deleted while SwiftUI still holds stale Bindings.
- **PaymentMode enum** — documents have a `paymentMode` (aucun/virement/crypto) independent of currency. "Aucun" hides all payment info from both UI and PDF.
- **DesignationPreset** — favorite line items stored in CompanyInfo, insertable with one click in the editor.
- **Offline-first sync** — local JSON is always the source of truth. SyncService pushes to Supabase via REST (UPSERT). Anonymous auth via Keychain-stored tokens.
- **Timesheet hours conversion** — input `6.30` (6h30min) is auto-converted to `6.5` decimal hours. Minutes part (after dot) is divided by 60.

### Module Layout

- `Models/` — Document, LineItem, ClientInfo, CompanyInfo, Currency, Blockchain, Enums, TransactionSignature, Timesheet. All are Codable.
- `Services/DataStore.swift` — JSON persistence, CRUD operations, per-key save methods
- `Services/SyncService.swift` — Supabase REST sync (UPSERT/pull), dirty tracking, sync state
- `Services/AuthService.swift` — Supabase anonymous + email auth, Keychain token storage
- `Services/NetworkMonitor.swift` — NWPathMonitor wrapper for connectivity detection
- `Services/DocumentNumberService.swift` — auto-numbering: `Facture_2026_03`, `Devis_2026_01`
- `Services/ExportService.swift` — NSSavePanel wrapper for PDF export
- `Views/ContentView.swift` — three-column NavigationSplitView (sidebar → list → detail)
- `Views/Documents/DocumentEditorView.swift` — main editor with all sections
- `Views/Timesheet/` — TimesheetListView, TimesheetEditorView for weekly hour tracking
- `Views/Settings/` — Company, Payment, Defaults, Prestations, Sync, About
- `PDF/PDFGenerator.swift` — full A4 PDF rendering. Olive green theme (#6B8E3A). Abstract circle logo fallback.
- `PDF/PDFLayout.swift` — all constants (fonts, colors, margins, column widths)
- `Extensions/` — Date and Decimal French formatting helpers, Color theme

### UI Language

All labels, placeholders, and PDF content are in **French**. Keep this consistent.

## Conventional Commits

Release Please on push to `main`. Conventional Commits required. **Prefer `fix:` for small changes and improvements.** Reserve `feat:` for significant new features only.

- `feat:` — **big features only** (new major section, new module, new integration). Triggers **minor** bump (1.3.0 → 1.4.0).
- `fix:` — bug fixes, corrections. Triggers **patch** bump (1.3.0 → 1.3.1). **Always include at least one `fix:` per batch to trigger a release.**
- `impr:` — small improvements, UI tweaks, polish. **No version bump alone** — shows in changelog under "Ameliorations".
- `refactor:` — code refactoring. **No version bump alone** — shows in changelog under "Refactorings".
- `chore:` — CI, config, dependencies, docs. No version bump. Hidden from changelog.

**Important :** `impr:` et `refactor:` apparaissent dans le changelog mais ne declenchent PAS de release. Toujours inclure au moins un `fix:` dans le batch pour bumper la version.

On release PR merge: builds .app + .dmg on macOS 15 runner, uploads to GitHub Release.

## Adding a New Codable Field

When adding a field to Document or CompanyInfo:
1. Add the property with a default value
2. Add to `CodingKeys` enum
3. In `init(from decoder:)`, use `(try? container.decode(...)) ?? defaultValue` for backwards compatibility
4. Add to `encode(to:)`
