# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
swift build                          # Debug build
swift run                            # Build + run the app
swift run Facio --run-regressions    # Run the compiled-in regression suite
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/build-app.sh 1.0.0
ALLOW_AD_HOC_SIGNING=1 ./scripts/build-app.sh 1.0.0  # Local-only unsigned distribution build
```

No linter is configured. There is no SPM test target; instead, regression tests live in `Facio/Diagnostics/RegressionSuite.swift`, compiled only in debug builds (`FACIO_REGRESSION_TESTS` define in Package.swift) and triggered by the `--run-regressions` flag. To add a test, append a `RegressionCase` to the `cases` array — the suite always runs all cases. CI (`.github/workflows/ci.yml`) runs build + regression suite + a packaging smoke test on every PR and push to main.

### Supabase secrets

`Facio/Config/Secrets.swift` resolves `SUPABASE_URL` / `SUPABASE_ANON_KEY` from `SecretsGenerated.swift` (injected at CI build time) with a fallback to a `.env` file at the project root for local dev. Without either, sync is simply unconfigured — the app still runs.

## Architecture

macOS SwiftUI app (Swift 6.0, macOS 15+) built with Swift Package Manager. Generates professional invoices (factures) and quotes (devis) as PDF, with multi-currency support (EUR, USD, USDC, USDT, BTC, ETH), blockchain payment tracking (Solana Pay via the SolKit dependency), time tracking (timesheets + timer + TimeHub aggregation), and a revenue dashboard.

### Data Flow

`FacioApp` creates a `DataStore` (singleton `@Observable`), `SyncService`, `AuthService`, and `NetworkMonitor`, injected via `.environment()`. All views read/write through `DataStore`. Persistence is JSON files in `~/Library/Application Support/Facio/` (documents.json, clients.json, company.json, timesheets.json). Optional Supabase sync with anonymous auth.

### Key Architectural Decisions

- **`@Observable` + Environment** — no SwiftData. DataStore manages all CRUD and serialization manually via JSON Codable.
- **PDF via CoreText/CoreGraphics** — `PDFGenerator` draws directly to `CGContext`. Coordinate system is top-down (y=0 = top of page), converted to CG bottom-up via `cgY()`. Text rendered with `CTLineCreateWithAttributedString` + `CTLineDraw`.
- **Frozen client data** — client info is copied into each Document (not referenced). Old invoices retain original client data even if the client is updated later.
- **Safe array access pattern** — all `ForEach` + `Binding` combos access items by UUID lookup (`first(where: { $0.id == id })`), never by captured index. This prevents crashes when items are deleted while SwiftUI still holds stale Bindings.
- **PaymentMode enum** — documents have a `paymentMode` (aucun/virement/crypto) independent of currency. "Aucun" hides all payment info from both UI and PDF.
- **DesignationPreset** — favorite line items stored in CompanyInfo, insertable with one click in the editor.
- **Offline-first sync** — local JSON is always the source of truth. SyncService pushes to Supabase via REST (UPSERT). Anonymous auth via Keychain-stored tokens. Document attachments stay local (not synced).
- **Timesheet hours conversion** — input `6.30` (6h30min) is auto-converted to `6.5` decimal hours. Minutes part (after dot) is divided by 60. Parsing lives in `TimesheetHourInputParser` and is covered by regression tests.

### Design System (Views/Components/)

All UI chrome is tokenized — no magic values in views:

- **`FacioLayout`** (`DesignSystem.swift`) — spacing (4 pt grid), named radii, field/column widths, window minimums (960×640), and responsive breakpoints.
- **`FacioFont`** (`FacioTypography.swift`) — typography tokens.
- **Colors** (`Extensions/Color+Theme.swift`) — single source of truth for dark mode: views NEVER read `colorScheme`; every color goes through dynamic tokens built with `dynamic(light, dark)`. Semantic statuses use the intent palette (`intentSuccess`, `intentWarning`, `intentDanger`, `intentInfo`) — never raw `.green`/`.orange`/`.red`.
- **`FacioMotion`** — closed animation vocabulary (`hover`, `state`, `emphasis` + `slideIn`/`slideUp` transitions). No bare `.animation()` or magic durations; always bind to a `value:`, and respect reduce-motion via `FacioMotion.respecting(_:reduceMotion:)`.
- **Controls** — text fields get chrome via `.facioField(error:density:)` on native `TextField`s; buttons use `.buttonStyle(.facio(.primary))` (roles: primary/secondary/etc.).
- **Toasts** — `ToastCenter` (`@Observable`, in environment): `toastCenter.show(message, tone:)`.
- **Responsive layout** (`ResponsiveLayout.swift`) — views read `@Environment(\.facioWidthClass)` (compact/regular/wide, derived from `FacioLayout` breakpoints) instead of measuring geometry themselves.

### Module Layout

- `Models/` — Document, LineItem, ClientInfo, CompanyInfo, Currency, Blockchain, Enums, TransactionSignature, DocumentAttachment, Timesheet/TimesheetWeek/TimesheetDay, TimeEntry. All are Codable.
- `Services/DataStore.swift` — JSON persistence, CRUD operations, per-key save methods, corrupt-file quarantine
- `Services/SyncService.swift` — Supabase REST sync (UPSERT/pull), dirty tracking, sync state
- `Services/AuthService.swift` — Supabase anonymous + email auth, Keychain token storage
- `Services/DocumentNumberService.swift` — auto-numbering: `Facture_2026_03` / `Invoice_2026_03`
- `Services/` (other) — ExportService (NSSavePanel PDF export), EmailService, SolanaPayService, AccountingRevenueService (multi-currency revenue conversion), TimeTrackingService + TimeHubAggregationService + TimesheetInvoiceService (timer → timesheet → invoice flow), UpdateService, NetworkMonitor, KeychainService/SecurePersistence
- `Views/ContentView.swift` — three-column NavigationSplitView (sidebar → list → detail) + command palette (`CommandPaletteView`)
- `Views/Sidebar/` — sections: factures, devis, clients, heures, planning, dashboard, parametres
- `Views/Documents/DocumentEditorView.swift` — main editor, with sections split into sibling files (line items, payment info, signatures, attachments)
- `Views/TimeHub/`, `Views/Timesheet/` — time tracking UI (timer panel, weekly timesheets, aggregation hub)
- `Views/Dashboard/DashboardView.swift` — revenue/KPI dashboard
- `Views/Settings/` — Company, Payment, Defaults, Prestations, Customisation, Email, Language, Sync, About
- `PDF/PDFGenerator.swift` — full A4 PDF rendering. Olive green theme (#6B8E3A). Abstract circle logo fallback.
- `PDF/PDFLayout.swift` — all constants (fonts, colors, margins, column widths)
- `Extensions/` — Date and Decimal French formatting helpers, Color theme, NSColor hex
- `Config/` — Supabase secrets resolution
- `Diagnostics/RegressionSuite.swift` — debug-only regression tests

### Internationalization (i18n)

The app supports **French** (default) and **English**. All user-facing strings are centralized in `Localization/` — `L10n.swift` plus per-domain extensions (`L10n+Documents.swift`, `L10n+Settings.swift`, etc.).

- **Language per document** — each `Document` has a `langue` field (FR/EN). The PDF and document number (`Facture_` vs `Invoice_`) adapt to the document's language.
- **Global UI language** — controlled by `CompanyInfo.langueParDefaut`. All views use `private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }` to access it.
- **Date/number formats** — configurable globally via `CompanyInfo.formatDate` / `CompanyInfo.formatNombre` in Settings > Langue & Format.
- **Pattern** — `L10n.someKey(lang)` returns the translated string. Never hardcode French strings in views or PDF.

**IMPORTANT : Whenever you add or modify any UI element that displays text (labels, placeholders, buttons, alerts, section titles, PDF text, etc.), you MUST add the translation in `L10n.swift` for both FR and EN, and use `L10n.xxx(lang)` instead of a hardcoded string.**

## Git Workflow

**Never commit directly to `main`** — except for truly minor changes (e.g. editing this `CLAUDE.md`, fixing a typo in the docs). For those small cases, a direct commit to `main` is fine.

For any real change (code, feature, bug fix):
1. Create a **GitHub issue in English** describing the need/problem.
2. Create a dedicated **branch**.
3. Open a **PR** (referencing the issue) once the work is ready.

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

When changing Codable fields or persistence, add a regression case covering old-payload decoding (see existing cases like "document decodes old payloads without accounting conversion").
