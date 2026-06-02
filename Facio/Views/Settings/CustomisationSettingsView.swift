import ImageIO
import SwiftUI

struct CustomisationSettingsView: View {
    @Environment(DataStore.self) private var dataStore

    private var company: CompanyInfo {
        dataStore.companyInfo
    }

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    @State private var isDropTargeted = false
    @State private var logoValidationMessage: String?
    nonisolated private static let maximumLogoBytes = 2_000_000
    nonisolated private static let maximumLogoDimension = 4_096
    nonisolated private static let maximumLogoPixels = 12_000_000

    // MARK: - Binding Color <-> hex

    private var accentColorBinding: Binding<Color> {
        Binding(
            get: {
                let ns = company.accentNSColor
                return Color(nsColor: ns)
            },
            set: { newColor in
                let ns = NSColor(newColor).usingColorSpace(.sRGB)
                    ?? NSColor(newColor)
                company.couleurAccentHex = ns.toHex()
                dataStore.companyUpdated()
            }
        )
    }

    var body: some View {
        VStack(spacing: FacioLayout.space20) {
            // MARK: - Logo
            SectionPanel(L10n.logo(lang), systemImage: "photo") {
                VStack(alignment: .leading, spacing: FacioLayout.space16) {
                    if let logoData = company.logoData,
                       let nsImage = Self.validatedLogoPreview(from: logoData) {
                        HStack(spacing: FacioLayout.space16) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 100, maxHeight: 80)
                                .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusPanel))

                            VStack(alignment: .leading, spacing: FacioLayout.space8) {
                                Button(L10n.chooseAnotherFile(lang)) {
                                    pickLogoFile()
                                }
                                Button(L10n.deleteLogo(lang), role: .destructive) {
                                    company.logoData = nil
                                    dataStore.companyUpdated()
                                }
                                .foregroundStyle(Color.intentDanger)
                            }
                        }
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: FacioLayout.radiusPanel)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                .foregroundStyle(isDropTargeted ? Color.intentInfo : .secondary.opacity(0.5))
                                .frame(height: 80)

                            VStack(spacing: FacioLayout.space4) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                Text(L10n.dragImageHere(lang))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                            handleDrop(providers: providers)
                        }

                        Button(L10n.chooseFile(lang)) {
                            pickLogoFile()
                        }
                    }

                    if let logoValidationMessage {
                        InlineWarning(text: logoValidationMessage, tone: .warning)
                    }
                }
            }

            // MARK: - Couleur du theme
            SectionPanel(L10n.themeColor(lang), systemImage: "paintpalette") {
                VStack(alignment: .leading, spacing: FacioLayout.space16) {
                    HStack {
                        ColorPicker(L10n.mainColor(lang), selection: accentColorBinding, supportsOpacity: false)

                        Spacer()

                        if company.couleurAccentHex != nil {
                            Button(L10n.resetColor(lang)) {
                                company.couleurAccentHex = nil
                                dataStore.companyUpdated()
                            }
                            .foregroundStyle(.secondary)
                        }
                    }

                    // Apercu
                    VStack(alignment: .leading, spacing: FacioLayout.space6) {
                        Text(L10n.colorPreview(lang))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: FacioLayout.space12) {
                            colorSwatch(L10n.colorHeader(lang), color: Color(nsColor: company.accentNSColor))
                            colorSwatch(L10n.colorSections(lang), color: Color(nsColor: company.accentNSColor.darkened(by: 0.15)))
                            colorSwatch(L10n.colorAlternating(lang), color: Color(nsColor: company.accentNSColor.withAlphaComponent(0.15)))
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(FacioLayout.screenPadding)
    }

    // MARK: - Helpers

    private func colorSwatch(_ label: String, color: Color) -> some View {
        VStack(spacing: FacioLayout.space4) {
            RoundedRectangle(cornerRadius: FacioLayout.radiusField)
                .fill(color)
                .frame(width: 60, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: FacioLayout.radiusField)
                        .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
                )
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func pickLogoFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? Data(contentsOf: url) {
                applyLogoData(data)
            } else {
                logoValidationMessage = L10n.invalidLogoFile(lang)
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  let imageData = try? Data(contentsOf: url) else {
                DispatchQueue.main.async {
                    logoValidationMessage = L10n.invalidLogoFile(lang)
                }
                return
            }

            DispatchQueue.main.async {
                applyLogoData(imageData)
            }
        }
        return true
    }

    private func applyLogoData(_ data: Data) {
        guard Self.isValidLogoData(data) else {
            logoValidationMessage = L10n.invalidLogoFile(lang)
            return
        }
        logoValidationMessage = nil
        company.logoData = data
        dataStore.companyUpdated()
    }

    nonisolated private static func validatedLogoPreview(from data: Data) -> NSImage? {
        guard isValidLogoData(data),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 256
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    nonisolated private static func isValidLogoData(_ data: Data) -> Bool {
        guard data.count <= maximumLogoBytes,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source),
              ["public.png", "public.jpeg", "public.tiff"].contains(type as String),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0,
              height > 0,
              width <= maximumLogoDimension,
              height <= maximumLogoDimension,
              width * height <= maximumLogoPixels
        else { return false }

        return true
    }
}
