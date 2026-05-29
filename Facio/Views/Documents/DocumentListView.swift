import SwiftUI

struct DocumentListView: View {
    let documentType: DocumentType
    @Binding var selectedDocumentId: UUID?
    var onOpenDocument: (Document) -> Void = { _ in }

    @Environment(DataStore.self) private var dataStore
    @State private var searchText = ""
    @State private var documentPendingDeletion: Document?

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var allDocuments: [Document] {
        dataStore.documents.sorted { $0.dateCreation > $1.dateCreation }
    }

    private var documents: [Document] {
        let filtered = allDocuments.filter { $0.type == documentType }
        guard !searchText.isEmpty else { return filtered }
        let query = searchText.lowercased()
        return filtered.filter { doc in
            doc.number.lowercased().contains(query) ||
            doc.clientNom.lowercased().contains(query) ||
            doc.clientSiret.lowercased().contains(query) ||
            doc.clientTva.lowercased().contains(query) ||
            doc.clientApe.lowercased().contains(query)
        }
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
                ContentUnavailableView(
                    searchText.isEmpty
                        ? L10n.noDocuments(lang, type: documentType.label(for: lang).lowercased())
                        : L10n.noSearchResults(lang),
                    systemImage: searchText.isEmpty
                        ? (documentType == .facture ? "doc.text" : "doc.text.magnifyingglass")
                        : "magnifyingglass",
                    description: Text(searchText.isEmpty
                        ? L10n.clickToCreate(lang, type: documentType.label(for: lang).lowercased())
                        : L10n.noSearchResultsHint(lang))
                )
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
    }

    // MARK: - Actions

    private func creerDocument() {
        let company = dataStore.companyInfo
        let creationDate = Date()
        let currency = company.deviseParDefaut
        let number = DocumentNumberService.nextNumber(
            type: documentType,
            existingDocuments: allDocuments,
            language: company.langueParDefaut
        )
        let document = Document(
            type: documentType,
            number: number,
            dateCreation: creationDate,
            dateEcheance: dueDate(from: creationDate),
            currency: currency,
            blockchain: defaultBlockchain(for: currency)
        )
        document.langue = company.langueParDefaut
        dataStore.addDocument(document)
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
            existingDocuments: allDocuments,
            language: lang
        )
        dataStore.addDocument(copie)
        selectedDocumentId = copie.id
    }

    private func convertirEnFacture(_ document: Document) {
        let facture = document.convertirEnFacture()
        facture.number = DocumentNumberService.nextNumber(
            type: .facture,
            existingDocuments: allDocuments,
            language: lang
        )
        dataStore.addDocument(facture)
        onOpenDocument(facture)
    }

    private func dueDate(from creationDate: Date) -> Date {
        Calendar.current.date(
            byAdding: .day,
            value: dataStore.companyInfo.delaiPaiementJours,
            to: creationDate
        ) ?? creationDate
    }

    private func defaultBlockchain(for currency: CurrencyType) -> Blockchain? {
        guard currency.requiresBlockchain else { return nil }
        let compatible = Blockchain.compatibleBlockchains(for: currency)
        guard !compatible.isEmpty else { return nil }
        if let defaultBlockchain = dataStore.companyInfo.blockchainParDefaut,
           compatible.contains(defaultBlockchain) {
            return defaultBlockchain
        }
        return compatible.first
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
        document.isOverdue ? .red : Color.statusColor(for: document.status)
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
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            Text(document.currency.formatAccounting(document.totalTTC, lang: numberFormat))
                .font(.body.monospacedDigit())
                .fontWeight(.medium)
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
