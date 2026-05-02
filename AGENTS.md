# Repository Guidelines

## Project Structure & Module Organization

Facio is a Swift 6.0 Swift Package Manager macOS 15+ app. The executable target lives in `Facio/`.

- `Facio/Models/`: Codable domain types such as `Document`, `ClientInfo`, `CompanyInfo`, `Timesheet`, and payment enums.
- `Facio/Services/`: persistence, sync, authentication, export, update, networking, and numbering services.
- `Facio/Views/`: SwiftUI screens grouped by feature (`Documents`, `Timesheet`, `Settings`, `Clients`, `Dashboard`).
- `Facio/PDF/`: CoreText/CoreGraphics PDF rendering and layout constants.
- `Facio/Localization/`: bilingual FR/EN localization helpers. Do not hardcode user-facing strings.
- `Facio/Resources/`: bundled image assets.
- `scripts/`: release packaging, DMG creation, icon generation, and entitlements.
- `docs/`: GitHub Pages landing page assets.

## Build, Test, and Development Commands

```bash
swift build
```
Builds the debug executable.

```bash
swift run
```
Builds and launches the macOS app locally.

```bash
./scripts/build-app.sh 1.0.0
```
Builds a release `.app` bundle in `dist/Facio.app` and signs it ad hoc unless `CODESIGN_IDENTITY` is set.

```bash
./scripts/create-dmg.sh 1.0.0
```
Creates `dist/Facio-1.0.0.dmg`; run after building the app bundle.

## Coding Style & Naming Conventions

Use standard Swift style with 4-space indentation. Keep types in PascalCase, properties and functions in lowerCamelCase, and feature files named after their primary type, such as `DocumentEditorView.swift`. Prefer existing SwiftUI patterns: `DataStore` is injected through the environment, views use `@Observable` state, and JSON persistence stays in service/model layers. When adding UI, PDF, button, alert, or placeholder text, add both French and English entries in `Facio/Localization/` and call `L10n.*(lang)`.

## Testing Guidelines

No automated test target is currently configured. Before opening a PR, run `swift build` and manually exercise affected workflows with `swift run`, especially document editing, PDF export, sync settings, and timesheet behavior. If adding tests later, create an SPM test target and use descriptive names like `testDocumentTotalIncludesVAT()`.

## Commit & Pull Request Guidelines

This repo uses Conventional Commits with Release Please. Prefer `fix:` for small user-facing fixes, reserve `feat:` for significant features, and use `impr:`, `refactor:`, `chore:`, or `docs:` where appropriate. Examples: `fix(pdf): render notes section in PDF output`, `feat(web): add GitHub Pages landing page`.

PRs should include a short summary, linked issue when applicable, manual test notes, and screenshots or screen recordings for UI changes. Mention release or migration risks, especially when changing Codable fields or local JSON persistence.

## Data & Configuration Notes

Local app data is stored under `~/Library/Application Support/Facio/`. When adding Codable fields, provide defaults in `init(from:)` for backward compatibility and update `CodingKeys` plus `encode(to:)`.
