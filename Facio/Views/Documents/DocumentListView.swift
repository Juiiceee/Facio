import SwiftUI

struct DocumentListView: View {
    let documentType: DocumentType
    @Binding var selectedDocumentId: UUID?

    @Environment(DataStore.self) private var dataStore
    @State private var searchText = ""

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
            doc.clientNom.lowercased().contains(query)
        }
    }

    var body: some View {
        List(documents, selection: $selectedDocumentId) { document in
            DocumentRowView(document: document)
                .tag(document.id)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        supprimerDocument(document)
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
                        supprimerDocument(document)
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
                    L10n.noDocuments(lang, type: documentType.label(for: lang).lowercased()),
                    systemImage: documentType == .facture ? "doc.text" : "doc.text.magnifyingglass",
                    description: Text(L10n.clickToCreate(lang, type: documentType.label(for: lang).lowercased()))
                )
            }
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

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(document.number)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    StatusBadge(status: document.status)
                }

                HStack {
                    Text(document.clientNom.isEmpty ? L10n.noClient(lang) : document.clientNom)
                        .font(.subheadline)
                        .foregroundStyle(document.clientNom.isEmpty ? .tertiary : .secondary)
                        .lineLimit(1)
                    Spacer()
                    Text(document.dateCreation.formattedDate(for: dateFormat))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Text(document.currency.formatAccounting(document.totalTTC, lang: numberFormat))
                .font(.body.monospacedDigit())
                .fontWeight(.medium)
                .lineLimit(1)
                .frame(minWidth: 80, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}
