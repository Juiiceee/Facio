import SwiftUI

struct ClientListView: View {
    @Binding var selectedClientId: UUID?
    var onSelectDocument: (Document) -> Void = { _ in }

    @Environment(DataStore.self) private var dataStore
    @Environment(\.facioWidthClass) private var widthClass
    @State private var searchText = ""
    @State private var clientPendingDeletion: ClientInfo?
    @State private var sortKey = "name"
    @State private var sortAscending = true
    @State private var filter = ClientFilter()

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var sortOptions: [FacioSortOption] {
        [
            FacioSortOption(id: "name", label: L10n.sortName(lang)),
            FacioSortOption(id: "invoiced", label: L10n.sortTotalInvoiced(lang)),
            FacioSortOption(id: "paid", label: L10n.sortTotalPaid(lang)),
            FacioSortOption(id: "recent", label: L10n.sortDateAdded(lang)),
        ]
    }

    /// Factures rattachées à un client (par nom, ou par SIRET / TVA / APE).
    private func invoices(for client: ClientInfo) -> [Document] {
        dataStore.documents.filter { $0.type == .facture && clientMatches(client, $0) }
    }

    private func clientMatches(_ client: ClientInfo, _ doc: Document) -> Bool {
        let cn = client.nom.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let dn = doc.clientNom.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !cn.isEmpty, cn == dn { return true }
        for (c, d) in [(client.siret, doc.clientSiret), (client.tva, doc.clientTva), (client.ape, doc.clientApe)] {
            let lhs = c.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let rhs = d.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !lhs.isEmpty, lhs == rhs { return true }
        }
        return false
    }

    private var filteredClients: [ClientInfo] {
        var result = dataStore.clients

        if !searchText.isEmpty {
            result = result.filter {
                $0.nom.localizedCaseInsensitiveContains(searchText) ||
                $0.ville.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText) ||
                $0.siret.localizedCaseInsensitiveContains(searchText) ||
                $0.tva.localizedCaseInsensitiveContains(searchText) ||
                $0.ape.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Métriques par client précalculées une fois (filtre + tri).
        let ref = dataStore.companyInfo.deviseComptable
        var metrics: [UUID: (invoiced: Decimal, paid: Decimal, hasUnpaid: Bool)] = [:]
        for client in result {
            let inv = invoices(for: client)
            let invoiced = AccountingRevenueService.summary(for: inv, referenceCurrency: ref).total
            let paid = AccountingRevenueService.summary(for: inv.filter { $0.status == .payee }, referenceCurrency: ref).total
            let hasUnpaid = inv.contains { $0.status != .payee && $0.status != .annulee }
            metrics[client.id] = (invoiced, paid, hasUnpaid)
        }

        if filter.activeCount > 0 {
            result = result.filter { client in
                let m = metrics[client.id] ?? (0, 0, false)
                return filter.matches(hasUnpaid: m.hasUnpaid, totalInvoiced: m.invoiced)
            }
        }

        result.sort { a, b in
            let asc = sortAscending
            switch sortKey {
            case "invoiced":
                let av = metrics[a.id]?.invoiced ?? 0, bv = metrics[b.id]?.invoiced ?? 0
                if av != bv { return asc ? av < bv : av > bv }
            case "paid":
                let av = metrics[a.id]?.paid ?? 0, bv = metrics[b.id]?.paid ?? 0
                if av != bv { return asc ? av < bv : av > bv }
            case "recent":
                if a.createdAt != b.createdAt { return asc ? a.createdAt < b.createdAt : a.createdAt > b.createdAt }
            case "name":
                let r = a.displayName.localizedCaseInsensitiveCompare(b.displayName)
                if r != .orderedSame { return asc ? r == .orderedAscending : r == .orderedDescending }
            default:
                break
            }
            return a.displayName.localizedCaseInsensitiveCompare(b.displayName) == .orderedAscending
        }
        return result
    }

    private var selectedClient: ClientInfo? {
        guard let selectedClientId else { return nil }
        return dataStore.clients.first { $0.id == selectedClientId }
    }

    var body: some View {
        Group {
            if widthClass == .compact {
                compactLayout
            } else {
                splitLayout
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

    // MARK: - Layouts

    /// Split 2 colonnes maison pour les largeurs regular/wide.
    private var splitLayout: some View {
        HStack(spacing: 0) {
            clientList
                .frame(minWidth: 260, idealWidth: 340, maxWidth: 480, maxHeight: .infinity)

            Divider()

            detailPane
                .frame(minWidth: 380, maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Navigation empilée en largeur compacte : le détail pleine largeur
    /// (précédé d'un bouton retour) quand un client est sélectionné, sinon la liste.
    @ViewBuilder
    private var compactLayout: some View {
        if let client = selectedClient {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    selectedClientId = nil
                } label: {
                    Label(L10n.back(lang), systemImage: "chevron.left")
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, FacioLayout.screenPadding)
                .padding(.vertical, FacioLayout.space8)

                Divider()

                detailView(for: client)
            }
        } else {
            clientList
        }
    }

    /// Liste des clients, partagée entre les variantes split et empilée.
    private var clientList: some View {
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
        .safeAreaInset(edge: .top, spacing: 0) {
            FacioListControls(
                lang: lang,
                accent: Color.appPrimary(from: dataStore.companyInfo),
                sortOptions: sortOptions,
                sortKey: $sortKey,
                sortAscending: $sortAscending,
                filterActiveCount: filter.activeCount
            ) {
                ClientFilterPanel(
                    filter: $filter,
                    lang: lang,
                    numberFormat: dataStore.companyInfo.formatNombre,
                    accent: Color.appPrimary(from: dataStore.companyInfo),
                    onReset: { filter = ClientFilter() }
                )
            }
        }
        .overlay {
            if filteredClients.isEmpty {
                FacioEmptyState(
                    title: searchText.isEmpty ? L10n.noClientsYet(lang) : L10n.noSearchResults(lang),
                    systemImage: searchText.isEmpty ? "person.2" : "magnifyingglass",
                    message: searchText.isEmpty ? L10n.selectOrCreateClient(lang) : L10n.noSearchResultsHint(lang)
                )
            }
        }
    }

    /// Colonne détail du split : détail du client sélectionné ou état vide.
    @ViewBuilder
    private var detailPane: some View {
        if let client = selectedClient {
            detailView(for: client)
        } else {
            FacioEmptyState(
                title: L10n.noClientSelected(lang),
                systemImage: "person.crop.circle",
                message: L10n.selectOrCreateClient(lang)
            )
        }
    }

    /// Détail d'un client, partagé entre les variantes split et empilée.
    private func detailView(for client: ClientInfo) -> some View {
        ClientDetailView(
            client: client,
            onSelectDocument: onSelectDocument,
            onCreateDocument: createDocument
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        .font(FacioFont.caption)
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
                        .font(FacioFont.captionSmall)
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
                    .font(FacioFont.screenTitle)
                if !client.email.isEmpty {
                    Text(client.email)
                        .font(FacioFont.screenSubtitle)
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
                .buttonStyle(.facio(.primary))

                Button {
                    onCreateDocument(.devis, client)
                } label: {
                    Label(L10n.createQuoteForClient(lang), systemImage: "doc.text.magnifyingglass")
                }
                .buttonStyle(.facio(.secondary))

                Spacer()
            }
        }
    }

    private var informationSection: some View {
        SectionPanel(L10n.information(lang), systemImage: "person.text.rectangle") {
            VStack(alignment: .leading, spacing: FacioLayout.space12) {
                LabeledField(L10n.name(lang)) {
                    TextField(L10n.name(lang), text: Bindable(client).nom)
                        .facioField()
                }
                LabeledField(L10n.address(lang)) {
                    TextField(L10n.address(lang), text: Bindable(client).adresse)
                        .facioField()
                }
                HStack(spacing: FacioLayout.space12) {
                    LabeledField(L10n.postalCode(lang)) {
                        TextField(L10n.postalCode(lang), text: Bindable(client).codePostal)
                            .facioField()
                    }
                    .frame(maxWidth: 140)

                    LabeledField(L10n.city(lang)) {
                        TextField(L10n.city(lang), text: Bindable(client).ville)
                            .facioField()
                    }
                }
                LabeledField(L10n.email(lang)) {
                    TextField(L10n.email(lang), text: Bindable(client).email)
                        .facioField()
                }
                HStack(spacing: FacioLayout.space12) {
                    LabeledField(L10n.siret(lang)) {
                        TextField(L10n.clientSiretPlaceholder(lang), text: Bindable(client).siret)
                            .facioField()
                    }
                    LabeledField(L10n.vatNumber(lang)) {
                        TextField(L10n.clientTvaPlaceholder(lang), text: Bindable(client).tva)
                            .facioField()
                    }
                    LabeledField(L10n.apeCode(lang)) {
                        TextField(L10n.apeCode(lang), text: Bindable(client).ape)
                            .facioField()
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
                        .font(FacioFont.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(document.currency.formatAccounting(document.totalTTC, lang: numberFormat))
                    .font(FacioFont.amount)
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
