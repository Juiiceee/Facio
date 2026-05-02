# Facio

Native macOS app to create and manage professional invoices and quotes as PDF.

## Features

- **Invoices & Quotes** — create, duplicate, convert quote to invoice
- **Multi-currency** — EUR, USD, USDC, USDT, BTC, ETH
- **Flexible payment** — bank transfer (IBAN), crypto (multi-chain wallet), or none
- **PDF export** — professional rendering with built-in preview
- **Favorite line items** — pre-saved designations insertable in one click
- **Client directory** — save and reuse client info
- **Timesheet** — weekly hour tracking with overtime calculation (35h threshold)
- **Local persistence** — all data stays on your Mac
- **Payment proofs** — blockchain transaction signatures with explorer links

## Installation

### Download the .dmg

1. Go to the [Releases page](https://github.com/Juiiceee/Facio/releases)
2. Download the latest `.dmg` file
3. Open the `.dmg` and drag **Facio.app** into your **Applications** folder

### Authorize the app

Release downloads are signed and notarized for macOS. If macOS blocks Facio, download the latest release again from the official GitHub Releases page and compare the file against the published SHA-256 checksum before opening an issue.

**Verify a download:**

```bash
shasum -a 256 Facio-<version>.dmg
cat Facio-<version>.dmg.sha256
```

The two hashes should match exactly.

### From source

```bash
git clone https://github.com/Juiiceee/Facio.git
cd Facio
swift run
```

### Build the .app

```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/build-app.sh 1.0.0
open dist/Facio.app

# Install to Applications
cp -r dist/Facio.app /Applications/
```

For local-only development builds without a Developer ID certificate:

```bash
ALLOW_AD_HOC_SIGNING=1 ./scripts/build-app.sh 1.0.0
```

## Requirements

- macOS 15+
- Swift 6.0+

## Stack

- **SwiftUI** — native macOS interface
- **CoreText / CoreGraphics** — PDF generation
- **JSON** — local persistence (`~/Library/Application Support/Facio/`)

## License

All rights reserved.
