# Facio

Application macOS native pour creer et gerer des factures et devis professionnels en PDF.

## Fonctionnalites

- **Factures & Devis** — creation, duplication, conversion devis → facture
- **Multi-devises** — EUR, USD, USDC, USDT, BTC, ETH
- **Paiement flexible** — virement bancaire (IBAN), crypto (wallet multi-chain), ou aucun
- **Export PDF** — rendu professionnel avec apercu integre
- **Prestations favorites** — designations pre-enregistrees en un clic
- **Carnet de clients** — sauvegarde et reutilisation des infos clients
- **Persistance locale** — toutes les donnees restent sur votre Mac
- **Preuves de paiement** — signatures de transactions blockchain avec liens explorateurs

## Installation

### Depuis les releases

Telecharger le `.dmg` depuis la [page Releases](https://github.com/Juiiceee/Facio/releases), ouvrir et glisser Facio dans Applications.

> **Note :** L'app n'est pas signee avec un certificat Apple Developer. Au premier lancement macOS peut la bloquer. Pour l'ouvrir :
> ```bash
> xattr -cr /Applications/Facio.app
> ```
> Ou : clic droit sur Facio.app → **Ouvrir** (au lieu de double-clic).

### Depuis les sources

```bash
git clone https://github.com/Juiiceee/Facio.git
cd Facio
swift run
```

### Construire le .app

```bash
./scripts/build-app.sh 1.0.0
open dist/Facio.app

# Installer dans Applications
cp -r dist/Facio.app /Applications/
```

## Prerequis

- macOS 15+
- Swift 6.0+

## Stack

- **SwiftUI** — interface native macOS
- **CoreText / CoreGraphics** — generation PDF
- **JSON** — persistance locale (`~/Library/Application Support/Facio/`)

## Licence

Tous droits reserves.
