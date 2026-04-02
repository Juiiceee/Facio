import SwiftUI

struct DocumentEditorView: View {
    var document: Document

    @Environment(DataStore.self) private var dataStore

    @State private var showClientPicker = false
    @State private var showPreview = false
    @State private var showAddSignature = false

    // Debounce timer for auto-save
    @State private var saveTask: Task<Void, Never>?

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var allDocuments: [Document] {
        dataStore.documents.sorted { $0.dateCreation > $1.dateCreation }
    }

    private var clients: [ClientInfo] {
        dataStore.clients.sorted { $0.nom < $1.nom }
    }

    private var company: CompanyInfo {
        dataStore.companyInfo
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            if !Task.isCancelled {
                dataStore.save()
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                enTeteSection
                datesSection
                deviseSection
                clientSection
                lignesSection
                totauxSection
                paiementInfoSection

                if document.status == .payee {
                    signaturesSection
                }

                notesSection
            }
            .padding(24)
        }
        .navigationTitle(document.number.isEmpty ? L10n.newDocument(lang) : document.number)
        .toolbar {
            editorToolbar
        }
        .sheet(isPresented: $showClientPicker) {
            ClientPickerSheet(clients: clients) { client in
                client.appliquer(sur: document)
                dataStore.save()
                showClientPicker = false
            }
        }
        .sheet(isPresented: $showPreview) {
            PDFPreviewSheet(document: document, company: company)
        }
        .sheet(isPresented: $showAddSignature) {
            AddSignatureSheet(document: document)
        }
    }

    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                dupliquer()
            } label: {
                Label(L10n.duplicate(lang), systemImage: "doc.on.doc")
            }

            Button {
                showPreview = true
            } label: {
                Label(L10n.preview(lang), systemImage: "eye")
            }

            Button {
                exporterPDF()
            } label: {
                Label(L10n.exportPDF(lang), systemImage: "square.and.arrow.up")
            }
        }
    }

    // MARK: - En-tete

    private var enTeteSection: some View {
        GroupBox(L10n.headerSection(lang)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.type(lang))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(document.type.label(for: lang))
                            .font(.headline)
                            .foregroundStyle(Color.appPrimary(from: dataStore.companyInfo))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.number(lang))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField(L10n.number(lang), text: Binding(
                            get: { document.number },
                            set: { document.number = $0; scheduleSave() }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 250)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.language(lang))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Picker("", selection: Binding(
                            get: { document.langue },
                            set: { newLang in
                                document.langue = newLang
                                dataStore.save()
                            }
                        )) {
                            ForEach(AppLanguage.allCases) { l in
                                Text(l.label).tag(l)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 120)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.status(lang))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Picker(L10n.status(lang), selection: Binding(
                            get: { document.status },
                            set: { newStatus in
                                document.status = newStatus
                                dataStore.save()
                                if newStatus == .payee && document.currency.isCrypto
                                    && document.transactionSignatures.isEmpty {
                                    showAddSignature = true
                                }
                            }
                        )) {
                            ForEach(DocumentStatus.allCases) { status in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.statusColor(for: status))
                                        .frame(width: 8, height: 8)
                                    Text(status.label(for: lang))
                                }
                                .tag(status)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 160)
                    }
                }
            }
            .padding(8)
        }
    }

    // MARK: - Dates

    private var datesSection: some View {
        GroupBox(L10n.datesSection(lang)) {
            HStack(spacing: 24) {
                DatePicker(L10n.creationDate(lang), selection: Binding(
                    get: { document.dateCreation },
                    set: { document.dateCreation = $0; dataStore.save() }
                ), displayedComponents: .date)
                DatePicker(L10n.dueDateLabel(lang), selection: Binding(
                    get: { document.dateEcheance },
                    set: { document.dateEcheance = $0; dataStore.save() }
                ), displayedComponents: .date)
            }
            .padding(8)
        }
    }

    // MARK: - Devise & Mode de paiement

    private var deviseSection: some View {
        GroupBox(L10n.currencyPayment(lang)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 24) {
                    CurrencyPicker(selection: Binding(
                        get: { document.currency },
                        set: { document.currency = $0; dataStore.save() }
                    ))

                    Picker(L10n.payment(lang), selection: Binding(
                        get: { document.paymentMode },
                        set: { document.paymentMode = $0; dataStore.save() }
                    )) {
                        ForEach(PaymentMode.allCases) { mode in
                            Text(mode.label(for: lang)).tag(mode)
                        }
                    }
                    .frame(maxWidth: 150)
                }

                if document.paymentMode == .crypto {
                    HStack(spacing: 16) {
                        let compatibles = Blockchain.compatibleBlockchains(for: document.currency)
                        Picker(L10n.blockchain(lang), selection: Binding(
                            get: { document.blockchain },
                            set: { document.blockchain = $0; dataStore.save() }
                        )) {
                            Text(L10n.blockchainNone(lang)).tag(Blockchain?.none)
                            ForEach(compatibles) { chain in
                                Text(chain.label).tag(Blockchain?.some(chain))
                            }
                        }
                        .frame(maxWidth: 200)
                    }
                }
            }
            .padding(8)
        }
    }

    // MARK: - Client (Destinataire)

    private var clientSection: some View {
        GroupBox(L10n.recipientSection(lang)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(L10n.clientInfo(lang))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        showClientPicker = true
                    } label: {
                        Label(L10n.clientBook(lang), systemImage: "person.crop.rectangle.stack")
                    }
                }

                clientFields
            }
            .padding(8)
        }
    }

    private var clientFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.name(lang))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField(L10n.clientName(lang), text: Binding(
                    get: { document.clientNom },
                    set: { document.clientNom = $0; scheduleSave() }
                ))
                .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.address(lang))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField(L10n.address(lang), text: Binding(
                    get: { document.clientAdresse },
                    set: { document.clientAdresse = $0; scheduleSave() }
                ))
                .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.postalCode(lang))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField(L10n.postalCode(lang), text: Binding(
                        get: { document.clientCodePostal },
                        set: { document.clientCodePostal = $0; scheduleSave() }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 120)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.city(lang))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField(L10n.city(lang), text: Binding(
                        get: { document.clientVille },
                        set: { document.clientVille = $0; scheduleSave() }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    // MARK: - Lignes

    private var lignesSection: some View {
        GroupBox(L10n.linesSection(lang)) {
            VStack(alignment: .leading, spacing: 8) {
                lignesHeader
                Divider()
                lignesContent
                Divider()
                ajouterLigneButton
            }
            .padding(8)
        }
    }

    private var lignesHeader: some View {
        HStack(spacing: 8) {
            Text(L10n.designationLabel(lang))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(L10n.quantityLabel(lang))
                .frame(width: 80, alignment: .trailing)
            Text(L10n.unitPrice(lang))
                .frame(width: 110, alignment: .trailing)
            Text(L10n.vatLabel(lang))
                .frame(width: 80, alignment: .center)
            Text(L10n.totalHTLabel(lang))
                .frame(width: 110, alignment: .trailing)
            Spacer().frame(width: 32)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
    }

    private var lignesContent: some View {
        Group {
            ForEach(document.lignesTriees) { ligne in
                LineItemRowView(
                    document: document,
                    ligneId: ligne.id,
                    onDelete: {
                        document.supprimerLigne(ligne)
                        dataStore.save()
                    },
                    onUpdate: {
                        dataStore.save()
                    }
                )
            }

            if document.lignes.isEmpty {
                Text(L10n.noLines(lang))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            }
        }
    }

    private var ajouterLigneButton: some View {
        HStack(spacing: 12) {
            Button {
                let ligne = LineItem(
                    designation: "",
                    quantite: 1,
                    prixUnitaire: 0,
                    tauxTVA: company.tauxTVAParDefaut,
                    ordre: document.lignes.count
                )
                document.ajouterLigne(ligne)
                dataStore.save()
            } label: {
                Label(L10n.addEmptyLine(lang), systemImage: "plus.circle")
            }
            .buttonStyle(.borderless)

            if !company.prestations.isEmpty {
                Menu {
                    ForEach(company.prestations) { preset in
                        Button {
                            ajouterPrestation(preset)
                        } label: {
                            HStack {
                                Text(preset.designation)
                                Spacer()
                                Text("\(NSDecimalNumber(decimal: preset.prixUnitaire))€/u")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } label: {
                    Label(L10n.favoriteService(lang), systemImage: "star.fill")
                }
                .menuStyle(.borderlessButton)
            }
        }
    }

    private func ajouterPrestation(_ preset: DesignationPreset) {
        let ligne = LineItem(
            designation: preset.designation,
            quantite: 1,
            prixUnitaire: preset.prixUnitaire,
            tauxTVA: preset.tauxTVA,
            ordre: document.lignes.count
        )
        document.ajouterLigne(ligne)
        dataStore.save()
    }

    // MARK: - Totaux

    private var totauxSection: some View {
        TotalsView(document: document)
    }

    // MARK: - Info paiement

    @ViewBuilder
    private var paiementInfoSection: some View {
        switch document.paymentMode {
        case .aucun:
            EmptyView()

        case .virement:
            GroupBox(L10n.paymentBankSection(lang)) {
                VStack(alignment: .leading, spacing: 8) {
                    if !company.iban.isEmpty {
                        HStack {
                            Label("IBAN", systemImage: "building.columns")
                                .foregroundStyle(.secondary)
                            Text(company.iban)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                        if !company.bic.isEmpty {
                            HStack {
                                Label("BIC", systemImage: "building.columns.fill")
                                    .foregroundStyle(.secondary)
                                Text(company.bic)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                        if !company.titulaireCompte.isEmpty {
                            HStack {
                                Label(L10n.accountHolderLabel(lang), systemImage: "person")
                                    .foregroundStyle(.secondary)
                                Text(company.titulaireCompte)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Text(L10n.noIBANConfigured(lang))
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(8)
            }

        case .crypto:
            GroupBox(L10n.paymentCryptoSection(lang)) {
                VStack(alignment: .leading, spacing: 8) {
                    if let chain = document.blockchain {
                        let walletsForChain = company.wallets.filter { $0.blockchain == chain }

                        HStack {
                            Label(L10n.network(lang), systemImage: "link")
                                .foregroundStyle(.secondary)
                            Text(chain.label)
                                .fontWeight(.medium)
                        }

                        if walletsForChain.count > 1 {
                            // Plusieurs wallets — Picker
                            HStack {
                                Label(L10n.wallet(lang), systemImage: "wallet.pass")
                                    .foregroundStyle(.secondary)
                                Picker("", selection: Binding(
                                    get: {
                                        document.selectedWalletId ?? walletsForChain.first?.id ?? UUID()
                                    },
                                    set: {
                                        document.selectedWalletId = $0
                                        dataStore.save()
                                    }
                                )) {
                                    ForEach(walletsForChain) { w in
                                        Text(w.label.isEmpty ? w.address.prefix(12) + "..." : w.label)
                                            .tag(w.id)
                                    }
                                }
                                .labelsHidden()
                            }
                            // Afficher l'adresse du wallet selectionne
                            if let selected = walletsForChain.first(where: { $0.id == (document.selectedWalletId ?? walletsForChain.first?.id) }) {
                                Text(selected.address)
                                    .font(.system(.caption, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .textSelection(.enabled)
                                    .foregroundStyle(.secondary)
                            }
                        } else if let wallet = walletsForChain.first {
                            // Un seul wallet — affichage simple
                            HStack {
                                Label(wallet.label.isEmpty ? L10n.wallet(lang) : wallet.label, systemImage: "wallet.pass")
                                    .foregroundStyle(.secondary)
                                Text(wallet.address)
                                    .font(.system(.caption, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .textSelection(.enabled)
                            }
                        } else {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                                Text(L10n.noWalletConfigured(lang, chain: chain.label))
                                    .foregroundStyle(.orange)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Text(L10n.selectNetwork(lang))
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(8)
            }
        }
    }

    // MARK: - Signatures

    private var signaturesSection: some View {
        GroupBox(L10n.paymentProofsSection(lang)) {
            VStack(alignment: .leading, spacing: 8) {
                signaturesContent
                Button {
                    showAddSignature = true
                } label: {
                    Label(L10n.addSignature(lang), systemImage: "plus.circle")
                }
                .buttonStyle(.borderless)
            }
            .padding(8)
        }
    }

    private var signaturesContent: some View {
        Group {
            if document.transactionSignatures.isEmpty {
                Text(L10n.noSignatures(lang))
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(document.transactionSignatures) { sig in
                    SignatureRowView(document: document, signature: sig, lang: lang) {
                        document.transactionSignatures.removeAll { $0.id == sig.id }
                        dataStore.save()
                    }
                    Divider()
                }
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        GroupBox(L10n.notes(lang)) {
            TextEditor(text: Binding(
                get: { document.notes },
                set: { document.notes = $0; scheduleSave() }
            ))
            .frame(minHeight: 60, maxHeight: 120)
            .font(.body)
            .padding(4)
        }
    }

    // MARK: - Actions

    private func dupliquer() {
        let copie = document.dupliquer()
        copie.number = DocumentNumberService.nextNumber(
            type: copie.type,
            existingDocuments: allDocuments,
            language: lang
        )
        dataStore.addDocument(copie)
    }

    private func exporterPDF() {
        let pdfData = PDFGenerator(document: document, company: company).generate()
        guard !pdfData.isEmpty else { return }
        Task {
            _ = await ExportService.exportPDF(data: pdfData, defaultFilename: document.number, language: lang)
        }
    }
}

// MARK: - Signature Row View

private struct SignatureRowView: View {
    let document: Document
    let signature: TransactionSignature
    let lang: AppLanguage
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(signature.signature)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 8) {
                    Text(signature.blockchain.label)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.appPrimary.opacity(0.1))
                        .clipShape(Capsule())
                    Text(signature.date.frenchFormatted)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(document.currency.format(signature.montant))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let url = signature.explorerURL {
                Link(destination: url) {
                    Label(L10n.viewOn(lang, explorer: signature.explorerName), systemImage: "arrow.up.right.square")
                        .font(.caption)
                }
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Client Picker Sheet

private struct ClientPickerSheet: View {
    let clients: [ClientInfo]
    let onSelect: (ClientInfo) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @State private var searchText = ""
    @State private var showNewClient = false
    @State private var newNom = ""
    @State private var newAdresse = ""
    @State private var newCodePostal = ""
    @State private var newVille = ""
    @State private var newEmail = ""

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var allClients: [ClientInfo] {
        dataStore.clients.sorted { $0.nom < $1.nom }
    }

    private var filteredClients: [ClientInfo] {
        guard !searchText.isEmpty else { return allClients }
        let query = searchText.lowercased()
        return allClients.filter {
            $0.nom.lowercased().contains(query) ||
            $0.ville.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.selectClient(lang))
                    .font(.headline)
                Spacer()
                Button {
                    showNewClient.toggle()
                } label: {
                    Label(L10n.new(lang), systemImage: "plus")
                }
                Button(L10n.close(lang)) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            if showNewClient {
                GroupBox(L10n.newClient(lang)) {
                    VStack(spacing: 8) {
                        TextField(L10n.name(lang), text: $newNom)
                            .textFieldStyle(.roundedBorder)
                        TextField(L10n.address(lang), text: $newAdresse)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            TextField(L10n.postalCode(lang), text: $newCodePostal)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 120)
                            TextField(L10n.city(lang), text: $newVille)
                                .textFieldStyle(.roundedBorder)
                        }
                        TextField(L10n.email(lang), text: $newEmail)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            Spacer()
                            Button(L10n.createAndSelect(lang)) {
                                let client = ClientInfo(
                                    nom: newNom,
                                    adresse: newAdresse,
                                    codePostal: newCodePostal,
                                    ville: newVille,
                                    email: newEmail
                                )
                                dataStore.addClient(client)
                                onSelect(client)
                            }
                            .disabled(newNom.isEmpty)
                        }
                    }
                    .padding(4)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            List(filteredClients) { client in
                Button {
                    onSelect(client)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(client.nom)
                            .font(.body)
                        if !client.ville.isEmpty {
                            Text("\(client.adresse.isEmpty ? "" : "\(client.adresse), ")\(client.codePostal) \(client.ville)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText, prompt: L10n.searchClient(lang))
        }
        .frame(minWidth: 450, minHeight: 400)
    }
}

// MARK: - Add Signature Sheet

private struct AddSignatureSheet: View {
    let document: Document
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore

    @State private var signature = ""
    @State private var montant: Decimal = 0
    @State private var selectedBlockchain: Blockchain = .solana
    @State private var date = Date()

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.addPaymentProof(lang))
                    .font(.headline)
                Spacer()
                Button(L10n.cancel(lang)) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            Form {
                Picker("Blockchain", selection: $selectedBlockchain) {
                    ForEach(Blockchain.allCases) { chain in
                        Text(chain.label).tag(chain)
                    }
                }

                TextField(L10n.txHash(lang), text: $signature)
                    .font(.system(.body, design: .monospaced))

                TextField(L10n.amount(lang), value: $montant, format: .number)

                DatePicker(L10n.date(lang), selection: $date, displayedComponents: .date)
            }
            .formStyle(.grouped)
            .padding(.horizontal)

            HStack {
                Spacer()
                Button(L10n.add(lang)) {
                    let tx = TransactionSignature(
                        signature: signature,
                        date: date,
                        montant: montant,
                        blockchain: selectedBlockchain
                    )
                    document.transactionSignatures.append(tx)
                    dataStore.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(signature.isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 300)
        .onAppear {
            if let chain = document.blockchain {
                selectedBlockchain = chain
            }
            montant = document.totalTTC
        }
    }
}
