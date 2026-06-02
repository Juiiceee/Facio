import SwiftUI

struct ClientListView: View {
    @Binding var selectedClientId: UUID?
    var onSelectDocument: (Document) -> Void = { _ in }

    @Environment(DataStore.self) private var dataStore
    @State private var searchText = ""
    @State private var clientPendingDeletion: ClientInfo?

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var clients: [ClientInfo] {
        dataStore.clients.sorted { $0.displayName < $1.displayName }
    }

    private var filteredClients: [ClientInfo] {
        if searchText.isEmpty { return clients }
        return clients.filter {
            $0.nom.localizedCaseInsensitiveContains(searchText) ||
            $0.ville.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText) ||
            $0.siret.localizedCaseInsensitiveContains(searchText) ||
            $0.tva.localizedCaseInsensitiveContains(searchText) ||
            $0.ape.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var selectedClient: ClientInfo? {
        guard let selectedClientId else { return nil }
        return dataStore.clients.first { $0.id == selectedClientId }
    }

    var body: some View {
        HStack(spacing: 0) {
            List(filteredClients, selection: $selectedClientId) { client in
                ClientRow(client: client)
                    .tag(client.id)
                    .contextMenu {
                        Button(L10n.delete(lang), role: .destructive) {
                            clientPendingDeletion = client
                        }
                    }
            }
            .searchable(text: $searchText, prompt: L10n.searchClientPrompt(lang))
            .overlay {
                if filteredClients.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? L10n.noClientsYet(lang) : L10n.noSearchResults(lang),
                        systemImage: searchText.isEmpty ? "person.2" : "magnifyingglass",
                        description: Text(searchText.isEmpty ? L10n.selectOrCreateClient(lang) : L10n.noSearchResultsHint(lang))
                    )
                }
            }
            .frame(minWidth: 280, idealWidth: 360, maxWidth: 520, maxHeight: .infinity)

            Divider()

            if let client = selectedClient {
                ClientDetailView(
                    client: client,
                    onSelectDocument: onSelectDocument,
                    onCreateDocument: createDocument
                )
                    .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    L10n.noClientSelected(lang),
                    systemImage: "person.crop.circle",
                    description: Text(L10n.selectOrCreateClient(lang))
                )
                .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem {
                Button(action: createClient) {
                    Label(L10n.newClient(lang), systemImage: "plus")
                }
            }
        }
        .navigationTitle(L10n.sidebarClients(lang))
        .alert(L10n.deleteClientConfirmTitle(lang), isPresented: Binding(
            get: { clientPendingDeletion != nil },
            set: { if !$0 { clientPendingDeletion = nil } }
        )) {
            Button(L10n.cancel(lang), role: .cancel) {
                clientPendingDeletion = nil
            }
            Button(L10n.delete(lang), role: .destructive) {
                if let client = clientPendingDeletion {
                    confirmDeleteClient(client)
                }
                clientPendingDeletion = nil
            }
        } message: {
            Text(L10n.deleteClientConfirmMessage(
                lang,
                name: clientPendingDeletion?.displayName ?? L10n.noClient(lang)
            ))
        }
        .onChange(of: dataStore.clients.map(\.id)) { _, ids in
            if let selectedClientId, !ids.contains(selectedClientId) {
                self.selectedClientId = nil
            }
        }
    }

    private func createClient() {
        let client = dataStore.createClient(name: L10n.newClient(lang))
        selectedClientId = client.id
    }

    private func confirmDeleteClient(_ client: ClientInfo) {
        if selectedClientId == client.id {
            selectedClientId = nil
        }
        dataStore.deleteClient(client)
    }

    private func createDocument(type: DocumentType, client: ClientInfo) {
        let company = dataStore.companyInfo
        let creationDate = Date()
        let currency = company.deviseParDefaut
        let document = Document(
            type: type,
            number: DocumentNumberService.nextNumber(
                type: type,
                existingDocuments: dataStore.documents.sorted { $0.dateCreation > $1.dateCreation },
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
        client.appliquer(sur: document)
        dataStore.addDocument(document)
        onSelectDocument(document)
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

// MARK: - Row

struct ClientRow: View {
    let client: ClientInfo
    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        FacioListRow(tone: Color.appPrimary(from: dataStore.companyInfo)) {
            VStack(alignment: .leading, spacing: FacioLayout.space2) {
                Text(client.displayName.isEmpty ? L10n.noClient(lang) : client.displayName)
                    .fontWeight(.medium)
                    .lineLimit(1)
                let address = [client.codePostal, client.ville]
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                if !address.isEmpty {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                let identifiers = [
                    client.siret.isEmpty ? nil : "\(L10n.siret(lang)): \(client.siret)",
                    client.tva.isEmpty ? nil : "\(L10n.vatNumber(lang)): \(client.tva)",
                    client.ape.isEmpty ? nil : "\(L10n.apeCode(lang)): \(client.ape)"
                ].compactMap { $0 }
                if !identifiers.isEmpty {
                    Text(identifiers.joined(separator: " - "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Detail

struct ClientDetailView: View {
    var client: ClientInfo
    var onSelectDocument: (Document) -> Void
    var onCreateDocument: (DocumentType, ClientInfo) -> Void

    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var numberFormat: AppLanguage { dataStore.companyInfo.formatNombre }

    private var relatedDocuments: [Document] {
        dataStore.documents
            .filter(documentMatchesClient)
            .sorted { $0.dateCreation > $1.dateCreation }
    }

    private var relatedInvoices: [Document] {
        relatedDocuments.filter { $0.type == .facture }
    }

    private var totalInvoiced: Decimal {
        AccountingRevenueService.summary(
            for: relatedInvoices,
            referenceCurrency: dataStore.companyInfo.deviseComptable
        ).total
    }

    private var totalPaid: Decimal {
        AccountingRevenueService.summary(
            for: relatedInvoices.filter { $0.status == .payee },
            referenceCurrency: dataStore.companyInfo.deviseComptable
        ).total
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FacioLayout.sectionSpacing) {
                clientHeader
                clientMetrics
                quickActions
                informationSection
                timelineSection
            }
            .frame(maxWidth: FacioLayout.formMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(FacioLayout.screenPadding)
        }
        .onChange(of: client.nom) { dataStore.clientUpdated(client) }
        .onChange(of: client.adresse) { dataStore.clientUpdated(client) }
        .onChange(of: client.codePostal) { dataStore.clientUpdated(client) }
        .onChange(of: client.ville) { dataStore.clientUpdated(client) }
        .onChange(of: client.email) { dataStore.clientUpdated(client) }
        .onChange(of: client.siret) { dataStore.clientUpdated(client) }
        .onChange(of: client.tva) { dataStore.clientUpdated(client) }
        .onChange(of: client.ape) { dataStore.clientUpdated(client) }
    }

    private var clientHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: FacioLayout.space4) {
                Text(client.displayName.isEmpty ? L10n.noClient(lang) : client.displayName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                if !client.email.isEmpty {
                    Text(client.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            Spacer()
        }
    }

    private var clientMetrics: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 160, maximum: 260))
        ], spacing: FacioLayout.space12) {
            MetricTile(
                title: L10n.clientRevenue(lang),
                value: dataStore.companyInfo.deviseComptable.formatAccounting(totalInvoiced, lang: numberFormat),
                systemImage: "doc.text",
                color: .appRevenue
            )
            MetricTile(
                title: L10n.clientPaid(lang),
                value: dataStore.companyInfo.deviseComptable.formatAccounting(totalPaid, lang: numberFormat),
                systemImage: "checkmark.circle",
                color: .intentSuccess
            )
            MetricTile(
                title: L10n.recentWork(lang),
                value: "\(relatedDocuments.count)",
                systemImage: "clock.arrow.circlepath",
                color: .intentWarning
            )
        }
    }

    private var quickActions: some View {
        SectionPanel(L10n.businessActions(lang), systemImage: "bolt") {
            HStack(spacing: FacioLayout.space12) {
                Button {
                    onCreateDocument(.facture, client)
                } label: {
                    Label(L10n.createInvoiceForClient(lang), systemImage: "doc.text")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    onCreateDocument(.devis, client)
                } label: {
                    Label(L10n.createQuoteForClient(lang), systemImage: "doc.text.magnifyingglass")
                }
                .buttonStyle(.bordered)

                Spacer()
            }
        }
    }

    private var informationSection: some View {
        SectionPanel(L10n.information(lang), systemImage: "person.text.rectangle") {
            VStack(alignment: .leading, spacing: FacioLayout.space12) {
                LabeledField(L10n.name(lang)) {
                    TextField(L10n.name(lang), text: Bindable(client).nom)
                        .textFieldStyle(.roundedBorder)
                }
                LabeledField(L10n.address(lang)) {
                    TextField(L10n.address(lang), text: Bindable(client).adresse)
                        .textFieldStyle(.roundedBorder)
                }
                HStack(spacing: FacioLayout.space12) {
                    LabeledField(L10n.postalCode(lang)) {
                        TextField(L10n.postalCode(lang), text: Bindable(client).codePostal)
                            .textFieldStyle(.roundedBorder)
                    }
                    .frame(maxWidth: 140)

                    LabeledField(L10n.city(lang)) {
                        TextField(L10n.city(lang), text: Bindable(client).ville)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                LabeledField(L10n.email(lang)) {
                    TextField(L10n.email(lang), text: Bindable(client).email)
                        .textFieldStyle(.roundedBorder)
                }
                HStack(spacing: FacioLayout.space12) {
                    LabeledField(L10n.siret(lang)) {
                        TextField(L10n.clientSiretPlaceholder(lang), text: Bindable(client).siret)
                            .textFieldStyle(.roundedBorder)
                    }
                    LabeledField(L10n.vatNumber(lang)) {
                        TextField(L10n.clientTvaPlaceholder(lang), text: Bindable(client).tva)
                            .textFieldStyle(.roundedBorder)
                    }
                    LabeledField(L10n.apeCode(lang)) {
                        TextField(L10n.apeCode(lang), text: Bindable(client).ape)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
        }
    }

    private var timelineSection: some View {
        SectionPanel(L10n.clientTimeline(lang), systemImage: "timeline.selection") {
            if relatedDocuments.isEmpty {
                Text(L10n.noClientActivity(lang))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: FacioLayout.space8) {
                    ForEach(relatedDocuments.prefix(8)) { document in
                        Button {
                            onSelectDocument(document)
                        } label: {
                            documentTimelineRow(document)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func documentTimelineRow(_ document: Document) -> some View {
        FacioListRow(tone: timelineRowTone(for: document)) {
            HStack(spacing: FacioLayout.space12) {
                Image(systemName: document.type == .facture ? "doc.text" : "doc.text.magnifyingglass")
                    .foregroundStyle(Color.appPrimary(from: dataStore.companyInfo))
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: FacioLayout.space2) {
                    Text(document.number)
                        .fontWeight(.medium)
                    Text(document.dateCreation.formattedDate(for: dataStore.companyInfo.formatDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(document.currency.formatAccounting(document.totalTTC, lang: numberFormat))
                    .font(.body.monospacedDigit())
                    .fontWeight(.medium)
                StatusBadge(status: document.status, isOverdue: document.isOverdue)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func timelineRowTone(for document: Document) -> Color {
        document.isOverdue ? .intentDanger : Color.statusColor(for: document.status)
    }

    private func documentMatchesClient(_ document: Document) -> Bool {
        let clientName = client.nom.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let docName = document.clientNom.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !clientName.isEmpty, clientName == docName { return true }

        let identifiers = [
            (client.siret, document.clientSiret),
            (client.tva, document.clientTva),
            (client.ape, document.clientApe)
        ]
        return identifiers.contains { clientValue, documentValue in
            let lhs = clientValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let rhs = documentValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return !lhs.isEmpty && lhs == rhs
        }
    }

}
