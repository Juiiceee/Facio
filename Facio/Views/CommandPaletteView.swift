import SwiftUI

private struct PaletteAction: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let run: () -> Void
}

struct CommandPaletteView: View {
    @Binding var selectedSection: SidebarSection?
    @Binding var selectedDocumentId: UUID?
    @Binding var selectedTimesheetId: UUID?
    @Binding var selectedSettingsTab: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore

    @State private var searchText = ""

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var currentDocument: Document? {
        guard let selectedDocumentId else { return nil }
        return dataStore.documents.first { $0.id == selectedDocumentId }
    }

    private var currentTimesheet: TimesheetPeriod? {
        guard let selectedTimesheetId else { return nil }
        return dataStore.timesheets.first { $0.id == selectedTimesheetId }
    }

    private var actions: [PaletteAction] {
        var items: [PaletteAction] = [
            PaletteAction(
                id: "new-invoice",
                title: L10n.quickCreateInvoice(lang),
                subtitle: L10n.sidebarInvoices(lang),
                systemImage: "doc.text"
            ) {
                createDocument(type: .facture)
            },
            PaletteAction(
                id: "new-quote",
                title: L10n.quickCreateQuote(lang),
                subtitle: L10n.sidebarQuotes(lang),
                systemImage: "doc.text.magnifyingglass"
            ) {
                createDocument(type: .devis)
            },
            PaletteAction(
                id: "new-client",
                title: L10n.quickCreateClient(lang),
                subtitle: L10n.sidebarClients(lang),
                systemImage: "person.crop.circle.badge.plus"
            ) {
                createClient()
            },
            PaletteAction(
                id: "settings-payment",
                title: L10n.openSettingsPayment(lang),
                subtitle: L10n.settings(lang),
                systemImage: "creditcard"
            ) {
                selectedSettingsTab = 2
                selectedSection = .parametres
                selectedDocumentId = nil
                selectedTimesheetId = nil
                dismiss()
            }
        ]

        if let currentDocument {
            items.append(
                PaletteAction(
                    id: "export-current",
                    title: L10n.exportPDF(lang),
                    subtitle: currentDocument.number,
                    systemImage: "square.and.arrow.up"
                ) {
                    exportPDF(currentDocument)
                }
            )
        }

        if let currentTimesheet, dataStore.canGenerateInvoice(for: currentTimesheet) {
            items.append(
                PaletteAction(
                    id: "invoice-timesheet",
                    title: L10n.generateInvoice(lang),
                    subtitle: currentTimesheet.periodLabel(for: lang),
                    systemImage: "doc.text"
                ) {
                    if let invoice = dataStore.generateInvoice(from: currentTimesheet, detailMode: .summary) {
                        selectedSection = .factures
                        selectedDocumentId = invoice.id
                        selectedTimesheetId = nil
                    }
                    dismiss()
                }
            )
        }

        return items
    }

    private var filteredActions: [PaletteAction] {
        guard !searchText.isEmpty else { return actions }
        return actions.filter { action in
            action.title.localizedCaseInsensitiveContains(searchText)
                || action.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredDocuments: [Document] {
        guard !searchText.isEmpty else { return [] }
        return dataStore.documents
            .filter {
                $0.number.localizedCaseInsensitiveContains(searchText)
                    || $0.clientNom.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.dateCreation > $1.dateCreation }
    }

    private var filteredClients: [ClientInfo] {
        guard !searchText.isEmpty else { return [] }
        return dataStore.clients
            .filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText)
                    || $0.email.localizedCaseInsensitiveContains(searchText)
                    || $0.siret.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.displayName < $1.displayName }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(L10n.commandPaletteTitle(lang), systemImage: "command")
                        .font(.headline)
                    Spacer()
                    Button(L10n.close(lang)) { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }

                TextField(L10n.commandPalettePlaceholder(lang), text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(18)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    actionSection
                    documentSection
                    clientSection
                }
                .padding(18)
            }
        }
    }

    private var actionSection: some View {
        paletteSection(title: L10n.businessActions(lang)) {
            if filteredActions.isEmpty {
                emptyRow
            } else {
                ForEach(filteredActions) { action in
                    Button {
                        action.run()
                    } label: {
                        paletteRow(title: action.title, subtitle: action.subtitle, systemImage: action.systemImage)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var documentSection: some View {
        if !filteredDocuments.isEmpty {
            paletteSection(title: L10n.searchDocumentsAndClients(lang)) {
                ForEach(filteredDocuments.prefix(8)) { document in
                    Button {
                        selectedSection = document.type == .facture ? .factures : .devis
                        selectedDocumentId = document.id
                        selectedTimesheetId = nil
                        dismiss()
                    } label: {
                        paletteRow(
                            title: document.number,
                            subtitle: document.clientNom.isEmpty ? document.type.label(for: lang) : document.clientNom,
                            systemImage: document.type == .facture ? "doc.text" : "doc.text.magnifyingglass"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var clientSection: some View {
        if !filteredClients.isEmpty {
            paletteSection(title: L10n.sidebarClients(lang)) {
                ForEach(filteredClients.prefix(8)) { client in
                    Button {
                        selectedSection = .clients
                        selectedDocumentId = nil
                        selectedTimesheetId = nil
                        dismiss()
                    } label: {
                        paletteRow(
                            title: client.displayName.isEmpty ? L10n.noClient(lang) : client.displayName,
                            subtitle: client.email,
                            systemImage: "person.crop.circle"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyRow: some View {
        Text(L10n.noCommandResults(lang))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }

    private func paletteSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
    }

    private func paletteRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.appPrimary(from: dataStore.companyInfo))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.panelRadius))
        .contentShape(Rectangle())
    }

    private func createDocument(type: DocumentType) {
        let company = dataStore.companyInfo
        let creationDate = Date()
        let currency = company.deviseParDefaut
        let document = Document(
            type: type,
            number: DocumentNumberService.nextNumber(
                type: type,
                existingDocuments: dataStore.documents,
                language: company.langueParDefaut
            ),
            dateCreation: creationDate,
            dateEcheance: Calendar.current.date(
                byAdding: .day,
                value: company.delaiPaiementJours,
                to: creationDate
            ) ?? creationDate,
            currency: currency,
            blockchain: defaultBlockchain(for: currency)
        )
        document.langue = company.langueParDefaut
        dataStore.addDocument(document)
        selectedSection = type == .facture ? .factures : .devis
        selectedDocumentId = document.id
        selectedTimesheetId = nil
        dismiss()
    }

    private func createClient() {
        let client = ClientInfo(nom: L10n.newClient(lang))
        dataStore.addClient(client)
        selectedSection = .clients
        selectedDocumentId = nil
        selectedTimesheetId = nil
        dismiss()
    }

    private func exportPDF(_ document: Document) {
        let pdfData = PDFGenerator(document: document, company: dataStore.companyInfo).generate()
        Task {
            _ = await ExportService.exportPDF(data: pdfData, defaultFilename: document.number, language: lang)
        }
        dismiss()
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

