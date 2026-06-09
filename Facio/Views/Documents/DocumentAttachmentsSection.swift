import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Section « Justificatifs » de l'éditeur : import de pièces jointes (PDF /
/// images) par bouton ou glisser-déposer, libellé éditable, ouverture et
/// suppression. Les fichiers sont stockés localement par `DataStore`.
struct DocumentAttachmentsSection: View {
    let document: Document
    let lang: AppLanguage
    @Environment(DataStore.self) private var dataStore

    @State private var isDropTargeted = false
    @State private var importError: String?

    var body: some View {
        SectionPanel(L10n.attachmentsSection(lang), systemImage: "paperclip") {
            VStack(alignment: .leading, spacing: FacioLayout.space12) {
                if document.attachments.isEmpty {
                    Text(L10n.noAttachmentsHint(lang))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(alignment: .leading, spacing: FacioLayout.space4) {
                        ForEach(document.attachments) { attachment in
                            AttachmentRowView(
                                document: document,
                                attachment: attachment,
                                lang: lang,
                                onOpen: { open(attachment) },
                                onDelete: { dataStore.deleteAttachment(attachment, from: document) }
                            )
                            if attachment.id != document.attachments.last?.id {
                                Divider()
                            }
                        }
                    }
                }

                dropZone

                if let importError {
                    InlineWarning(text: importError, tone: .danger)
                }

                Button {
                    pickFiles()
                } label: {
                    Label(L10n.addAttachment(lang), systemImage: "plus.circle")
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FacioLayout.radiusPanel)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                .foregroundStyle(isDropTargeted ? Color.intentInfo : .secondary.opacity(0.4))
                .frame(height: 60)

            VStack(spacing: FacioLayout.space4) {
                Image(systemName: "paperclip.badge.ellipsis")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(L10n.dropAttachmentHere(lang))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
    }

    private func open(_ attachment: DocumentAttachment) {
        NSWorkspace.shared.open(dataStore.attachmentURL(attachment, in: document))
    }

    private func pickFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf, .png, .jpeg, .heic, .tiff]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else { return }
        importError = nil
        for url in panel.urls where dataStore.importAttachment(from: url, to: document) == nil {
            importError = L10n.attachmentImportFailed(lang)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var handledAny = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier("public.file-url") {
            handledAny = true
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                DispatchQueue.main.async {
                    if dataStore.importAttachment(from: url, to: document) == nil {
                        importError = L10n.attachmentImportFailed(lang)
                    } else {
                        importError = nil
                    }
                }
            }
        }
        return handledAny
    }
}

private struct AttachmentRowView: View {
    let document: Document
    let attachment: DocumentAttachment
    let lang: AppLanguage
    let onOpen: () -> Void
    let onDelete: () -> Void

    @Environment(DataStore.self) private var dataStore
    @State private var labelText: String = ""
    @FocusState private var labelFocused: Bool

    var body: some View {
        HStack(spacing: FacioLayout.space10) {
            Image(systemName: attachment.iconName)
                .foregroundStyle(Color.appPrimary(from: dataStore.companyInfo))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: FacioLayout.space2) {
                TextField(L10n.attachmentLabelPlaceholder(lang), text: $labelText)
                    .textFieldStyle(.plain)
                    .font(FacioFont.rowTitle)
                    .focused($labelFocused)
                    .onSubmit { commitLabel() }
                    .onChange(of: labelFocused) { _, focused in
                        if !focused { commitLabel() }
                    }

                HStack(spacing: FacioLayout.space6) {
                    Text(attachment.originalFilename)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text("•")
                    Text(attachment.formattedSize)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            FacioIconButton(systemImage: "arrow.up.right.square", help: L10n.openAttachment(lang)) {
                onOpen()
            }
            FacioIconButton(systemImage: "trash", tone: .intentDanger, help: L10n.delete(lang)) {
                onDelete()
            }
        }
        .padding(.vertical, FacioLayout.space4)
        .onAppear { labelText = attachment.label }
    }

    private func commitLabel() {
        guard labelText != attachment.label else { return }
        dataStore.updateAttachmentLabel(attachment, label: labelText, in: document)
    }
}
