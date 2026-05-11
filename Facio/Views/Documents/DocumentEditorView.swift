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
                DocumentLineItemsSection(document: document, company: company, lang: lang) {
                    dataStore.save()
                }
                totauxSection
                DocumentPaymentInfoView(document: document, company: company, lang: lang) {
                    dataStore.save()
                }

                if document.status == .payee {
                    DocumentSignaturesSection(
                        document: document,
                        lang: lang,
                        onAdd: { showAddSignature = true },
                        onDelete: { signature in
                            document.transactionSignatures.removeAll { $0.id == signature.id }
                            dataStore.save()
                        }
                    )
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

    // MARK: - Totaux

    private var totauxSection: some View {
        TotalsView(document: document)
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
