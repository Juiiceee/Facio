import SwiftUI
import AppKit

/// Aperçu intégré d'un justificatif (PDF ou image) — évite d'ouvrir le
/// navigateur / une app externe. Le PDF réutilise `PDFPreviewView` ; les images
/// sont affichées via `NSImage`. Bouton d'ouverture externe conservé en repli.
struct AttachmentPreviewSheet: View {
    let url: URL
    let attachment: DocumentAttachment
    let lang: AppLanguage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(attachment.displayName)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button(L10n.openAttachmentExternally(lang)) {
                    NSWorkspace.shared.open(url)
                }
                Button(L10n.close(lang)) {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            content
        }
        .frame(minWidth: FacioLayout.sheetMinWidth, minHeight: 420)
        .presentationSizing(.page)
    }

    @ViewBuilder
    private var content: some View {
        if attachment.isPDF, let data = try? Data(contentsOf: url) {
            PDFPreviewView(data: data)
        } else if attachment.isImage, let image = NSImage(contentsOf: url) {
            ScrollView([.horizontal, .vertical]) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(FacioLayout.space16)
            }
        } else {
            ContentUnavailableView {
                Label(L10n.attachmentPreviewUnavailable(lang), systemImage: "eye.slash")
            } description: {
                Text(L10n.attachmentPreviewUnavailableHint(lang))
            } actions: {
                Button(L10n.openAttachmentExternally(lang)) {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
