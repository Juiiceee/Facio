import SwiftUI

struct DocumentEditorView: View {
    var document: Document

    @Environment(DataStore.self) private var dataStore

    @State private var showClientPicker = false
    @State private var showPreview = false
    @State private var showAddSignature = false

    // Debounce timer for auto-save
    @State private var saveTask: Task<Void, Never>?

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
            VStack(alignment: .leading, spacing: 24) {
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
        .navigationTitle(document.number.isEmpty ? "Nouveau document" : document.number)
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
                Label("Dupliquer", systemImage: "doc.on.doc")
            }

            Button {
                showPreview = true
            } label: {
                Label("Apercu", systemImage: "eye")
            }

            Button {
                exporterPDF()
            } label: {
                Label("Exporter PDF", systemImage: "square.and.arrow.up")
            }
        }
    }

    // MARK: - En-tete

    private var enTeteSection: some View {
        GroupBox("En-tete") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    LabeledContent("Type") {
                        Text(document.type.label)
                            .font(.headline)
                            .foregroundStyle(Color.appPrimary)
                    }

                    LabeledContent("Numero") {
                        TextField("Numero", text: Binding(
                            get: { document.number },
                            set: { document.number = $0; scheduleSave() }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 250)
                    }

                    LabeledContent("Statut") {
                        Picker("Statut", selection: Binding(
                            get: { document.status },
                            set: { newStatus in
                                document.status = newStatus
                                dataStore.save()
                                // Si on passe en Payee et crypto, proposer d'ajouter une signature
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
                                    Text(status.label)
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
        GroupBox("Dates") {
            HStack(spacing: 24) {
                DatePicker("Date de creation", selection: Binding(
                    get: { document.dateCreation },
                    set: { document.dateCreation = $0; dataStore.save() }
                ), displayedComponents: .date)
                DatePicker("Date d'echeance", selection: Binding(
                    get: { document.dateEcheance },
                    set: { document.dateEcheance = $0; dataStore.save() }
                ), displayedComponents: .date)
            }
            .padding(8)
        }
    }

    // MARK: - Devise

    private var deviseSection: some View {
        GroupBox("Devise") {
            HStack(spacing: 24) {
                CurrencyPicker(selection: Binding(
                    get: { document.currency },
                    set: { document.currency = $0; dataStore.save() }
                ))

                if document.currency.requiresBlockchain {
                    let compatibles = Blockchain.compatibleBlockchains(for: document.currency)
                    Picker("Blockchain", selection: Binding(
                        get: { document.blockchain },
                        set: { document.blockchain = $0; dataStore.save() }
                    )) {
                        Text("Aucune").tag(Blockchain?.none)
                        ForEach(compatibles) { chain in
                            Text(chain.label).tag(Blockchain?.some(chain))
                        }
                    }
                    .frame(maxWidth: 200)
                }
            }
            .padding(8)
        }
    }

    // MARK: - Client (Destinataire)

    private var clientSection: some View {
        GroupBox("DESTINATAIRE") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Informations client")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        showClientPicker = true
                    } label: {
                        Label("Carnet de clients", systemImage: "person.crop.rectangle.stack")
                    }
                }

                clientFields
            }
            .padding(8)
        }
    }

    private var clientFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                LabeledContent("Nom") {
                    TextField("Nom du client", text: Binding(
                        get: { document.clientNom },
                        set: { document.clientNom = $0; scheduleSave() }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
            }

            LabeledContent("Adresse") {
                TextField("Adresse", text: Binding(
                    get: { document.clientAdresse },
                    set: { document.clientAdresse = $0; scheduleSave() }
                ))
                .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 16) {
                LabeledContent("Code postal") {
                    TextField("Code postal", text: Binding(
                        get: { document.clientCodePostal },
                        set: { document.clientCodePostal = $0; scheduleSave() }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 120)
                }

                LabeledContent("Ville") {
                    TextField("Ville", text: Binding(
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
        GroupBox("Lignes") {
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
            Text("Designation")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Quantite")
                .frame(width: 80, alignment: .trailing)
            Text("Prix unitaire")
                .frame(width: 110, alignment: .trailing)
            Text("TVA")
                .frame(width: 80, alignment: .center)
            Text("Total HT")
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
                Text("Aucune ligne. Ajoutez-en une ci-dessous.")
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            }
        }
    }

    private var ajouterLigneButton: some View {
        Button {
            let ligne = LineItem(
                designation: "",
                quantite: 1,
                prixUnitaire: 0,
                tauxTVA: 20,
                ordre: document.lignes.count
            )
            document.ajouterLigne(ligne)
            dataStore.save()
        } label: {
            Label("Ajouter une ligne", systemImage: "plus.circle")
        }
        .buttonStyle(.borderless)
    }

    // MARK: - Totaux

    private var totauxSection: some View {
        TotalsView(document: document)
    }

    // MARK: - Info paiement (IBAN ou wallet selon devise)

    private var paiementInfoSection: some View {
        GroupBox("Mode de paiement") {
            VStack(alignment: .leading, spacing: 8) {
                if document.currency.isCrypto {
                    // Crypto
                    if let chain = document.blockchain {
                        HStack {
                            Label("Reseau", systemImage: "link")
                                .foregroundStyle(.secondary)
                            Text(chain.label)
                                .fontWeight(.medium)
                        }
                        if let wallet = company.wallet(pour: chain) {
                            HStack {
                                Label("Wallet", systemImage: "wallet.pass")
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
                                Text("Aucun wallet configure pour \(chain.label)")
                                    .foregroundStyle(.orange)
                                Text("(voir Parametres)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                .font(.caption)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Text("Selectionnez un reseau dans la section Devise")
                                .foregroundStyle(.orange)
                        }
                    }
                } else {
                    // Fiat (EUR / USD)
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
                                Label("Titulaire", systemImage: "person")
                                    .foregroundStyle(.secondary)
                                Text(company.titulaireCompte)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Text("Aucun IBAN configure")
                                .foregroundStyle(.orange)
                            Button("Configurer") {
                                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            .padding(8)
        }
    }

    // MARK: - Signatures

    private var signaturesSection: some View {
        GroupBox("Preuves de paiement") {
            VStack(alignment: .leading, spacing: 8) {
                signaturesContent
                Button {
                    showAddSignature = true
                } label: {
                    Label("Ajouter une signature", systemImage: "plus.circle")
                }
                .buttonStyle(.borderless)
            }
            .padding(8)
        }
    }

    private var signaturesContent: some View {
        Group {
            if document.transactionSignatures.isEmpty {
                Text("Aucune signature enregistree.")
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(document.transactionSignatures) { sig in
                    SignatureRowView(document: document, signature: sig) {
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
        GroupBox("Notes") {
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
            existingDocuments: allDocuments
        )
        dataStore.addDocument(copie)
    }

    private func exporterPDF() {
        let pdfData = PDFGenerator(document: document, company: company).generate()
        guard !pdfData.isEmpty else { return }
        Task {
            _ = await ExportService.exportPDF(data: pdfData, defaultFilename: document.number)
        }
    }
}

// MARK: - Signature Row View

private struct SignatureRowView: View {
    let document: Document
    let signature: TransactionSignature
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
                    Label("Voir sur \(signature.explorerName)", systemImage: "arrow.up.right.square")
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
                Text("Selectionner un client")
                    .font(.headline)
                Spacer()
                Button {
                    showNewClient.toggle()
                } label: {
                    Label("Nouveau", systemImage: "plus")
                }
                Button("Fermer") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            if showNewClient {
                GroupBox("Nouveau client") {
                    VStack(spacing: 8) {
                        TextField("Nom", text: $newNom)
                            .textFieldStyle(.roundedBorder)
                        TextField("Adresse", text: $newAdresse)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            TextField("Code postal", text: $newCodePostal)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                            TextField("Ville", text: $newVille)
                                .textFieldStyle(.roundedBorder)
                        }
                        TextField("Email", text: $newEmail)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            Spacer()
                            Button("Creer et selectionner") {
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
            .searchable(text: $searchText, prompt: "Rechercher un client")
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

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Ajouter une preuve de paiement")
                    .font(.headline)
                Spacer()
                Button("Annuler") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            Form {
                Picker("Blockchain", selection: $selectedBlockchain) {
                    ForEach(Blockchain.allCases) { chain in
                        Text(chain.label).tag(chain)
                    }
                }

                TextField("Signature / Hash de transaction", text: $signature)
                    .font(.system(.body, design: .monospaced))

                TextField("Montant", value: $montant, format: .number)

                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            .formStyle(.grouped)
            .padding(.horizontal)

            HStack {
                Spacer()
                Button("Ajouter") {
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
