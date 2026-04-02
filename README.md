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

Facio is not signed with an Apple Developer certificate. macOS will block it on first launch — this is normal.

**To authorize it:**

1. Try to open Facio — macOS will show a warning and prevent it from launching
2. Open **System Settings** → **Privacy & Security**
3. Scroll down to the **Security** section
4. You will see a message saying Facio was blocked — click **Open Anyway**
5. Confirm by clicking **Open** in the dialog that appears

**Alternative (Terminal):**

```bash
xattr -cr /Applications/Facio.app
```

Then launch Facio normally.

### From source

```bash
git clone https://github.com/Juiiceee/Facio.git
cd Facio
swift run
```

### Build the .app

```bash
./scripts/build-app.sh 1.0.0
open dist/Facio.app

# Install to Applications
cp -r dist/Facio.app /Applications/
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
