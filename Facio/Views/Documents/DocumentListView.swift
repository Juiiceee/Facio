import SwiftUI

struct DocumentListView: View {
    let documentType: DocumentType
    @Binding var selectedDocumentId: UUID?
    var onOpenDocument: (Document) -> Void = { _ in }

    @Environment(DataStore.self) private var dataStore
    @State private var searchText = ""
    @State private var documentPendingDeletion: Document?
    @State private var attachmentCopyFailures = 0
    @State private var showAttachmentCopyAlert = false
    @State private var sortKey = "date"
    @State private var sortAscending = false
    @State private var activeFilters: Set<String> = []

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var sortOptions: [FacioSortOption] {
        [
            FacioSortOption(id: "date", label: L10n.sortDate(lang)),
            FacioSortOption(id: "amount", label: L10n.sortAmount(lang)),
            FacioSortOption(id: "client", label: L10n.sortClient(lang)),
            FacioSortOption(id: "status", label: L10n.sortStatus(lang)),
            FacioSortOption(id: "number", label: L10n.sortNumber(lang)),
        ]
    }

    private var filterChips: [FacioFilterChip] {
        [
            FacioFilterChip(id: "payee", label: L10n.filterPaid(lang), tone: .intentSuccess),
            FacioFilterChip(id: "impaye", label: L10n.filterUnpaid(lang), tone: .intentWarning),
            FacioFilterChip(id: "envoyee", label: L10n.filterSent(lang), tone: .intentInfo),
            FacioFilterChip(id: "overdue", label: L10n.filterOverdue(lang), tone: .intentDanger),
            FacioFilterChip(id: "brouillon", label: L10n.filterDraft(lang), tone: .intentNeutral),
        ]
    }

    private var documents: [Document] {
        var result = dataStore.documents.filter { $0.type == documentType }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { doc in
                doc.number.lowercased().contains(query) ||
                doc.clientNom.lowercased().contains(query) ||
                doc.clientSiret.lowercased().contains(query) ||
                doc.clientTva.lowercased().contains(query) ||
                doc.clientApe.lowercased().contains(query)
            }
        }

        if !activeFilters.isEmpty {
            result = result.filter { doc in activeFilters.contains { matchesFilter($0, doc) } }
        }

        result.sort(by: documentIsOrderedBefore)
        return result
    }

    private func matchesFilter(_ id: String, _ d: Document) -> Bool {
        switch id {
        case "payee": return d.status == .payee
        case "impaye": return d.status != .payee && d.status != .annulee
        case "envoyee": return d.status == .envoyee
        case "overdue": return d.isOverdue
        case "brouillon": return d.status == .brouillon
        default: return false
        }
    }

    /// Montant comparable : total converti dans la devise comptable si un taux
    /// est défini, sinon le TTC brut (cohérent pour le mono-devise).
    private func documentAmount(_ d: Document) -> Decimal {
        d.accountingTotal(referenceCurrency: dataStore.companyInfo.deviseComptable) ?? d.totalTTC
    }

    private func statusOrder(_ s: DocumentStatus) -> Int {
        switch s {
        case .brouillon: return 0
        case .envoyee: return 1
        case .payee: return 2
        case .annulee: return 3
        }
    }

    private func documentIsOrderedBefore(_ a: Document, _ b: Document) -> Bool {
        let asc = sortAscending
        switch sortKey {
        case "amount":
            let av = documentAmount(a), bv = documentAmount(b)
            if av != bv { return asc ? av < bv : av > bv }
        case "client":
            let r = a.clientNom.localizedCaseInsensitiveCompare(b.clientNom)
            if r != .orderedSame { return asc ? r == .orderedAscending : r == .orderedDescending }
        case "status":
            let av = statusOrder(a.status), bv = statusOrder(b.status)
            if av != bv { return asc ? av < bv : av > bv }
        case "number":
            let r = a.number.localizedStandardCompare(b.number)
            if r != .orderedSame { return asc ? r == .orderedAscending : r == .orderedDescending }
        default:
            if a.dateCreation != b.dateCreation { return asc ? a.dateCreation < b.dateCreation : a.dateCreation > b.dateCreation }
        }
        // Départage stable : plus récent d'abord.
        return a.dateCreation > b.dateCreation
    }

    var body: some View {
        List(documents, selection: $selectedDocumentId) { document in
            DocumentRowView(document: document)
                .tag(document.id)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        documentPendingDeletion = document
                    } label: {
                        Label(L10n.delete(lang), systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button {
                        dupliquerDocument(document)
                    } label: {
                        Label(L10n.duplicate(lang), systemImage: "doc.on.doc")
                    }

                    if document.type == .devis {
                        Button {
                            convertirEnFacture(document)
                        } label: {
                            Label(L10n.convertToInvoice(lang), systemImage: "arrow.right.doc.on.clipboard")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        documentPendingDeletion = document
                    } label: {
                        Label(L10n.delete(lang), systemImage: "trash")
                    }
                }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            FacioListControls(
                lang: lang,
                accent: Color.appPrimary(from: dataStore.companyInfo),
                sortOptions: sortOptions,
                sortKey: $sortKey,
                sortAscending: $sortAscending,
                filterChips: filterChips,
                activeFilters: $activeFilters
            )
        }
        .navigationTitle(documentType == .devis ? L10n.sidebarQuotes(lang) : L10n.sidebarInvoices(lang))
        .searchable(text: $searchText, prompt: L10n.searchByNumberOrClient(lang))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    creerDocument()
                } label: {
                    Label(L10n.new(lang), systemImage: "plus")
                }
            }
        }
        .overlay {
            if documents.isEmpty {
                FacioEmptyState(
                    title: searchText.isEmpty
                        ? L10n.noDocuments(lang, type: documentType.label(for: lang).lowercased())
                        : L10n.noSearchResults(lang),
                    systemImage: searchText.isEmpty
                        ? (documentType == .facture ? "doc.text" : "doc.text.magnifyingglass")
                        : "magnifyingglass",
                    message: searchText.isEmpty
                        ? L10n.clickToCreate(lang, type: documentType.label(for: lang).lowercased())
                        : L10n.noSearchResultsHint(lang)
                ) {
                    if searchText.isEmpty {
                        FacioButton(
                            documentType == .devis ? L10n.quickCreateQuote(lang) : L10n.quickCreateInvoice(lang),
                            systemImage: "plus"
                        ) {
                            creerDocument()
                        }
                    }
                }
            }
        }
        .alert(L10n.deleteDocumentConfirmTitle(lang), isPresented: Binding(
            get: { documentPendingDeletion != nil },
            set: { if !$0 { documentPendingDeletion = nil } }
        )) {
            Button(L10n.cancel(lang), role: .cancel) {
                documentPendingDeletion = nil
            }
            Button(L10n.delete(lang), role: .destructive) {
                if let document = documentPendingDeletion {
                    supprimerDocument(document)
                }
                documentPendingDeletion = nil
            }
        } message: {
            Text(L10n.deleteDocumentConfirmMessage(
                lang,
                number: documentPendingDeletion?.number ?? ""
            ))
        }
        .alert(L10n.attachmentsCopyFailedTitle(lang), isPresented: $showAttachmentCopyAlert) {
            Button(L10n.understood(lang), role: .cancel) {}
        } message: {
            Text(L10n.attachmentsCopyFailedMessage(lang, count: attachmentCopyFailures))
        }
    }

    // MARK: - Actions

    private func creerDocument() {
        let document = dataStore.createDocument(type: documentType)
        selectedDocumentId = document.id
    }

    private func supprimerDocument(_ document: Document) {
        if selectedDocumentId == document.id {
            selectedDocumentId = nil
        }
        dataStore.deleteDocument(document)
    }

    private func dupliquerDocument(_ document: Document) {
        let copie = document.dupliquer()
        copie.number = DocumentNumberService.nextNumber(
            type: copie.type,
            existingDocuments: dataStore.documents,
            language: lang
        )
        dataStore.addDocument(copie)
        reportCopyFailures(dataStore.duplicateAttachments(from: document, to: copie))
        selectedDocumentId = copie.id
    }

    private func convertirEnFacture(_ document: Document) {
        let facture = document.convertirEnFacture()
        facture.number = DocumentNumberService.nextNumber(
            type: .facture,
            existingDocuments: dataStore.documents,
            language: lang
        )
        dataStore.addDocument(facture)
        reportCopyFailures(dataStore.duplicateAttachments(from: document, to: facture))
        onOpenDocument(facture)
    }

    private func reportCopyFailures(_ result: (copied: Int, failed: Int)) {
        guard result.failed > 0 else { return }
        attachmentCopyFailures = result.failed
        showAttachmentCopyAlert = true
    }

}

// MARK: - Document Row

struct DocumentRowView: View {
    let document: Document
    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var dateFormat: AppLanguage { dataStore.companyInfo.formatDate }
    private var numberFormat: AppLanguage { dataStore.companyInfo.formatNombre }
    private var rowTone: Color {
        document.isOverdue ? Color.intentDanger : Color.statusColor(for: document.status)
    }

    var body: some View {
        FacioListRow(tone: rowTone) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(document.number)
                        .font(.headline)
                        .lineLimit(1)
                    StatusBadge(status: document.status, isOverdue: document.isOverdue)
                }

                HStack(spacing: 6) {
                    Text(document.clientNom.isEmpty ? L10n.noClient(lang) : document.clientNom)
                        .font(.subheadline)
                        .foregroundStyle(document.clientNom.isEmpty ? .tertiary : .secondary)
                        .lineLimit(1)
                    Text("•")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(dateSummary)
                        .font(FacioFont.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            Text(document.currency.formatAccounting(document.totalTTC, lang: numberFormat))
                .font(FacioFont.amount)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(minWidth: 86, maxWidth: 120, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dateSummary: String {
        if document.type == .facture && (document.status == .envoyee || document.isOverdue) {
            return "\(L10n.dueDateLabel(lang)): \(document.dateEcheance.formattedDate(for: dateFormat))"
        }
        return document.dateCreation.formattedDate(for: dateFormat)
    }
}
