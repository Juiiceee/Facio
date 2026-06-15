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
    @State private var failedImportCount = 0
    @State private var dropAddedCount = 0
    @State private var dropToastTask: Task<Void, Never>?
    @State private var attachmentPendingDeletion: DocumentAttachment?
    @State private var attachmentToPreview: DocumentAttachment?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ToastCenter.self) private var toastCenter

    var body: some View {
        SectionPanel(L10n.attachmentsSection(lang), systemImage: "paperclip") {
            VStack(alignment: .leading, spacing: FacioLayout.space12) {
                if document.attachments.isEmpty {
                    Text(L10n.noAttachmentsHint(lang))
                        .font(FacioFont.caption)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(alignment: .leading, spacing: FacioLayout.space4) {
                        ForEach(document.attachments) { attachment in
                            AttachmentRowView(
                                document: document,
                                attachment: attachment,
                                lang: lang,
                                onOpen: { attachmentToPreview = attachment },
                                onDelete: { attachmentPendingDeletion = attachment }
                            )
                            if attachment.id != document.attachments.last?.id {
                                Divider()
                            }
                        }
                    }
                }

                dropZone

                if failedImportCount > 0 {
                    InlineWarning(text: L10n.attachmentImportFailedCount(lang, count: failedImportCount), tone: .danger)
                }

                Button {
                    pickFiles()
                } label: {
                    Label(L10n.addAttachment(lang), systemImage: "plus.circle")
                }
                .buttonStyle(.borderless)
            }
        }
        // Suppression définitive (le fichier disque part avec) : confirmation
        // obligatoire — contrairement aux entrées de temps, pas d'undo possible.
        .alert(
            L10n.deleteAttachmentConfirmTitle(lang),
            isPresented: Binding(
                get: { attachmentPendingDeletion != nil },
                set: { if !$0 { attachmentPendingDeletion = nil } }
            )
        ) {
            Button(L10n.cancel(lang), role: .cancel) {
                attachmentPendingDeletion = nil
            }
            Button(L10n.delete(lang), role: .destructive) {
                if let attachment = attachmentPendingDeletion {
                    dataStore.deleteAttachment(attachment, from: document)
                }
                attachmentPendingDeletion = nil
            }
        } message: {
            Text(L10n.deleteAttachmentConfirmMessage(
                lang,
                name: attachmentPendingDeletion?.originalFilename ?? ""
            ))
        }
        .sheet(item: $attachmentToPreview) { attachment in
            AttachmentPreviewSheet(
                url: dataStore.attachmentURL(attachment, in: document),
                attachment: attachment,
                lang: lang
            )
        }
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: FacioLayout.radiusPanel)
                .fill(isDropTargeted ? Color.appPrimary(from: dataStore.companyInfo).opacity(0.06) : .clear)
            RoundedRectangle(cornerRadius: FacioLayout.radiusPanel)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                .foregroundStyle(isDropTargeted ? Color.intentInfo : .secondary.opacity(0.4))

            VStack(spacing: FacioLayout.space4) {
                Image(systemName: "paperclip.badge.ellipsis")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(L10n.dropAttachmentHere(lang))
                    .font(FacioFont.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 60)
        .scaleEffect(isDropTargeted ? 1.01 : 1.0)
        .animation(FacioMotion.respecting(FacioMotion.state, reduceMotion: reduceMotion), value: isDropTargeted)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
    }

    /// Types acceptés (cohérents entre sélecteur de fichiers et glisser-déposer).
    private static let allowedExtensions: Set<String> = [
        "pdf", "png", "jpg", "jpeg", "heic", "heif", "gif", "tiff", "tif", "bmp"
    ]

    private func pickFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf, .png, .jpeg, .heic, .gif, .tiff, .bmp]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else { return }
        failedImportCount = 0
        var added = 0
        for url in panel.urls {
            if dataStore.importAttachment(from: url, to: document) == nil {
                failedImportCount += 1
            } else {
                added += 1
            }
        }
        if added > 0 {
            toastCenter.show(L10n.toastAttachmentsAdded(lang, count: added), icon: "paperclip")
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        failedImportCount = 0
        var handledAny = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier("public.file-url") {
            handledAny = true
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                DispatchQueue.main.async {
                    guard Self.allowedExtensions.contains(url.pathExtension.lowercased()) else {
                        failedImportCount += 1
                        return
                    }
                    if dataStore.importAttachment(from: url, to: document) == nil {
                        failedImportCount += 1
                    } else {
                        dropAddedCount += 1
                        scheduleDropToast()
                    }
                }
            }
        }
        return handledAny
    }

    /// Les imports d'un glisser-déposer arrivent dans des callbacks asynchrones :
    /// on agrège (debounce 300 ms) avant d'afficher un seul toast pour le lot.
    private func scheduleDropToast() {
        dropToastTask?.cancel()
        dropToastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled, dropAddedCount > 0 else { return }
            toastCenter.show(L10n.toastAttachmentsAdded(lang, count: dropAddedCount), icon: "paperclip")
            dropAddedCount = 0
        }
    }
}

private struct AttachmentRowView: View {
    let document: Document
    let attachment: DocumentAttachment
    let lang: AppLanguage
    let onOpen: () -> Void
    let onDelete: () -> Void

    @Environment(DataStore.self) private var dataStore
    @Environment(ToastCenter.self) private var toastCenter
    @State private var labelText: String = ""
    @FocusState private var labelFocused: Bool

    private static let tvaRates: [Decimal] = [0, 5.5, 10, 20]

    private var numberFormat: AppLanguage { dataStore.companyInfo.formatNombre }
    /// Décalage pour aligner les rangées sous le libellé (icône + espacement).
    private var contentInset: CGFloat { 24 + FacioLayout.space10 }

    var body: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space6) {
            // Niveau 1 : icône + libellé (= nom) + ouvrir / supprimer.
            HStack(spacing: FacioLayout.space10) {
                Image(systemName: attachment.iconName)
                    .foregroundStyle(Color.appPrimary(from: dataStore.companyInfo))
                    .frame(width: 24)

                TextField(L10n.attachmentLabelPlaceholder(lang), text: $labelText)
                    .textFieldStyle(.plain)
                    .font(FacioFont.rowTitle)
                    .focused($labelFocused)
                    .onSubmit { commitLabel() }
                    .onChange(of: labelFocused) { _, focused in
                        if !focused { commitLabel() }
                    }

                Spacer()

                FacioIconButton(systemImage: "arrow.up.right.square", help: L10n.openAttachment(lang)) {
                    onOpen()
                }
                FacioIconButton(systemImage: "trash", tone: .intentDanger, help: L10n.delete(lang)) {
                    onDelete()
                }
            }

            // Niveau 2 : montant (HT/TTC) + TVA + report en ligne de facture.
            HStack(spacing: FacioLayout.space8) {
                DecimalField(
                    placeholder: L10n.attachmentAmount(lang),
                    value: Binding(
                        get: { attachment.montant },
                        set: { newVal in update { $0.montant = newVal } }
                    ),
                    maximumFractionDigits: document.currency.maximumFractionDigits
                )
                .format(numberFormat)
                .frame(width: 110)

                Picker("", selection: Binding(
                    get: { attachment.montantEstTTC },
                    set: { newVal in update { $0.montantEstTTC = newVal } }
                )) {
                    Text(L10n.attachmentAmountHT(lang)).tag(false)
                    Text(L10n.attachmentAmountTTC(lang)).tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 120)

                Picker(L10n.vatLabel(lang), selection: Binding(
                    get: { attachment.tauxTVA },
                    set: { newVal in update { $0.tauxTVA = newVal } }
                )) {
                    ForEach(Self.tvaRates, id: \.self) { rate in
                        Text(L10n.vatRateLabel(numberFormat, rate: rate)).tag(rate)
                    }
                }
                .labelsHidden()
                .frame(width: 90)

                Button {
                    report()
                } label: {
                    Label(L10n.reportToInvoice(lang), systemImage: "arrow.right.doc.on.clipboard")
                }
                .buttonStyle(.borderless)
                .disabled(attachment.montant <= 0)

                Spacer()
            }
            .padding(.leading, contentInset)

            // Méta : nom de fichier d'origine + taille.
            HStack(spacing: FacioLayout.space6) {
                Text(attachment.originalFilename)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("•")
                Text(attachment.formattedSize)
            }
            .font(FacioFont.captionSmall)
            .foregroundStyle(.secondary)
            .padding(.leading, contentInset)
        }
        .padding(.vertical, FacioLayout.space4)
        .onAppear { labelText = attachment.label }
        .onChange(of: attachment.label) { _, newValue in
            if !labelFocused && labelText != newValue { labelText = newValue }
        }
    }

    private func commitLabel() {
        guard labelText != attachment.label else { return }
        dataStore.updateAttachmentLabel(attachment, label: labelText, in: document)
    }

    /// Applique une mutation sur une copie du justificatif et la persiste.
    private func update(_ mutate: (inout DocumentAttachment) -> Void) {
        var copy = attachment
        mutate(&copy)
        dataStore.updateAttachment(copy, in: document)
    }

    /// Crée une ligne de facture à partir du justificatif (montant ramené en HT).
    private func report() {
        let ligne = LineItem(
            designation: attachment.displayName,
            quantite: 1,
            prixUnitaire: attachment.montantHT,
            tauxTVA: attachment.tauxTVA,
            ordre: document.lignes.count
        )
        document.ajouterLigne(ligne)
        dataStore.documentUpdated(document)
        toastCenter.show(L10n.toastLineReported(lang), icon: "list.bullet.rectangle")
    }
}
