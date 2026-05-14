import SwiftUI

struct DocumentEditorView: View {
    var document: Document

    @Environment(DataStore.self) private var dataStore

    @State private var showClientPicker = false
    @State private var showPreview = false
    @State private var showAddSignature = false
    @State private var showPDFGenerationAlert = false
    @State private var showPDFExportAlert = false
    @State private var signatureCountBeforeSheet = 0

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

    private var availablePaymentModes: [PaymentMode] {
        document.currency.isCrypto ? PaymentMode.allCases : [.aucun, .virement]
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            if !Task.isCancelled {
                saveDocument()
            }
        }
    }

    private func saveDocument() {
        dataStore.documentUpdated(document)
    }

    private func prepareAccountingConversionIfNeeded() {
        let referenceCurrency = company.deviseComptable
        if document.currency == referenceCurrency {
            document.clearAccountingConversion()
        } else if document.accountingCurrency == nil {
            document.accountingCurrency = referenceCurrency
        }
    }

    private func presentAddSignatureSheet() {
        signatureCountBeforeSheet = document.transactionSignatures.count
        showAddSignature = true
    }

    var body: some View {
        GeometryReader { geometry in
            let usesSideInspector = geometry.size.width >= FacioLayout.documentInspectorBreakpoint

            HStack(spacing: 0) {
                documentMainScroll(showInlineInspector: !usesSideInspector)
                    .frame(maxWidth: .infinity)

                if usesSideInspector && hasReadinessIssues {
                    Divider()
                    documentInspector
                }
            }
        }
        .navigationTitle(document.number.isEmpty ? L10n.newDocument(lang) : document.number)
        .toolbar {
            editorToolbar
        }
        .sheet(isPresented: $showClientPicker) {
            ClientPickerSheet(clients: clients) { client in
                client.appliquer(sur: document)
                saveDocument()
                showClientPicker = false
            }
        }
        .sheet(isPresented: $showPreview) {
            PDFPreviewSheet(document: document, company: company)
        }
        .sheet(isPresented: $showAddSignature, onDismiss: {
            if document.transactionSignatures.count != signatureCountBeforeSheet {
                saveDocument()
            }
        }) {
            AddSignatureSheet(document: document)
        }
        .alert(L10n.pdfGenerationError(lang), isPresented: $showPDFGenerationAlert) {
            Button(L10n.understood(lang), role: .cancel) {}
        } message: {
            Text(L10n.cannotGeneratePDF(lang))
        }
        .alert(L10n.pdfExportError(lang), isPresented: $showPDFExportAlert) {
            Button(L10n.understood(lang), role: .cancel) {}
        } message: {
            Text(L10n.cannotExportPDF(lang))
        }
    }

    private func documentMainScroll(showInlineInspector: Bool) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FacioLayout.sectionSpacing) {
                documentHeroBar
                documentDetailsSection

                if showInlineInspector {
                    documentInspectorContent
                }

                clientSection
                DocumentLineItemsSection(document: document, company: company, lang: lang) {
                    saveDocument()
                }
                DocumentPaymentInfoView(document: document, company: company, lang: lang) {
                    saveDocument()
                }

                if document.status == .payee {
                    DocumentSignaturesSection(
                        document: document,
                        lang: lang,
                        onAdd: presentAddSignatureSheet,
                        onDelete: { signature in
                            document.transactionSignatures.removeAll { $0.id == signature.id }
                            saveDocument()
                        }
                    )
                }

                notesSection
            }
            .padding(FacioLayout.screenPadding)
        }
    }

    private var documentHeroBar: some View {
        SectionPanel {
            ViewThatFits(in: .horizontal) {
                heroHorizontal
                heroCompact
            }
        }
    }

    private var heroHorizontal: some View {
        HStack(alignment: .center, spacing: 18) {
            heroIdentity

            Spacer()

            heroTotal
            heroActions
        }
    }

    private var heroCompact: some View {
        VStack(alignment: .leading, spacing: 14) {
            heroIdentity

            HStack(alignment: .bottom, spacing: 16) {
                heroTotal
                Spacer()
                heroActions
            }
        }
    }

    private var heroIdentity: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(document.type.label(for: lang))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appPrimary(from: company))
                StatusBadge(status: document.status, isOverdue: document.isOverdue)
            }

            TextField(L10n.number(lang), text: Binding(
                get: { document.number },
                set: { document.number = $0; scheduleSave() }
            ))
            .font(.title2.weight(.semibold))
            .textFieldStyle(.plain)
            .lineLimit(1)

            Text(document.clientNom.isEmpty ? L10n.noClient(lang) : document.clientNom)
                .font(.subheadline)
                .foregroundStyle(document.clientNom.isEmpty ? .tertiary : .secondary)
                .lineLimit(1)
        }
        .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)
    }

    private var heroTotal: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(L10n.totalTTC(lang))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(document.currency.formatAccounting(document.totalTTC, lang: dataStore.companyInfo.formatNombre))
                .font(.title.monospacedDigit())
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(minWidth: 150, alignment: .trailing)
    }

    private var heroActions: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Button {
                showPreview = true
            } label: {
                Label(L10n.preview(lang), systemImage: "eye")
            }
            .buttonStyle(.bordered)

            Button {
                exporterPDF()
            } label: {
                Label(L10n.exportPDF(lang), systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var documentDetailsSection: some View {
        SectionPanel(L10n.documentDetails(lang), systemImage: "slider.horizontal.3") {
            VStack(alignment: .leading, spacing: 16) {
                enTeteSection
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        datesSection
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        deviseSection
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        datesSection
                        deviseSection
                    }
                }
                accountingConversionSection
            }
        }
    }

    private var documentInspector: some View {
        InspectorPanel {
            documentInspectorContent
        }
    }

    private var documentInspectorContent: some View {
        Group {
            documentReadinessSection
        }
    }

    @ViewBuilder
    private var documentReadinessSection: some View {
        if hasReadinessIssues {
            SectionPanel(L10n.documentReadiness(lang), systemImage: "exclamationmark.triangle") {
                VStack(alignment: .leading, spacing: 10) {
                    if !clientIsReady {
                        ChecklistRow(
                            title: L10n.clientReady(lang),
                            detail: L10n.missingClientHint(lang),
                            isComplete: false
                        )
                    }

                    if !linesAreReady {
                        ChecklistRow(
                            title: L10n.linesReady(lang),
                            detail: L10n.missingLinesHint(lang),
                            isComplete: false
                        )
                    }

                    if !amountIsReady {
                        ChecklistRow(
                            title: L10n.amountReady(lang),
                            detail: L10n.missingAmountHint(lang),
                            isComplete: false
                        )
                    }

                    if !paymentIsReady {
                        ChecklistRow(
                            title: L10n.paymentReady(lang),
                            detail: L10n.missingPaymentHint(lang),
                            isComplete: false
                        )
                    }

                    if !conversionIsReady {
                        ChecklistRow(
                            title: L10n.conversionReady(lang),
                            detail: L10n.missingConversionHint(lang),
                            isComplete: false
                        )
                    }
                }
            }
        }
    }

    private var hasReadinessIssues: Bool {
        !clientIsReady || !linesAreReady || !amountIsReady || !paymentIsReady || !conversionIsReady
    }

    private var clientIsReady: Bool {
        !document.clientNom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var linesAreReady: Bool {
        document.lignes.contains {
            !$0.designation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && $0.quantite > 0
        }
    }

    private var amountIsReady: Bool {
        document.totalTTC > 0
    }

    private var paymentIsReady: Bool {
        switch document.paymentMode {
        case .aucun:
            return true
        case .virement:
            return document.selectedPaymentBankAccount(from: company.bankAccounts) != nil
        case .crypto:
            return document.selectedPaymentWallet(from: company.wallets) != nil
        }
    }

    private var conversionIsReady: Bool {
        guard document.type == .facture else { return true }
        guard document.needsAccountingConversion(referenceCurrency: company.deviseComptable) else { return true }
        return document.accountingTotal(referenceCurrency: company.deviseComptable) != nil
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
                                saveDocument()
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
                                if newStatus == .envoyee {
                                    _ = document.freezePaymentSnapshot(from: company)
                                }
                                prepareAccountingConversionIfNeeded()
                                saveDocument()
                                if newStatus == .payee && document.currency.isCrypto
                                    && document.transactionSignatures.isEmpty {
                                    presentAddSignatureSheet()
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
                    set: { document.dateCreation = $0; saveDocument() }
                ), displayedComponents: .date)
                DatePicker(L10n.dueDateLabel(lang), selection: Binding(
                    get: { document.dateEcheance },
                    set: { document.dateEcheance = $0; saveDocument() }
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
                        set: {
                            document.currency = $0
                            prepareAccountingConversionIfNeeded()
                            saveDocument()
                        }
                    ))

                    Picker(L10n.payment(lang), selection: Binding(
                        get: { document.paymentMode },
                        set: { document.paymentMode = $0; saveDocument() }
                    )) {
                        ForEach(availablePaymentModes) { mode in
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
                            set: { document.blockchain = $0; saveDocument() }
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

    @ViewBuilder
    private var accountingConversionSection: some View {
        let referenceCurrency = company.deviseComptable
        if document.type == .facture && document.needsAccountingConversion(referenceCurrency: referenceCurrency) {
            GroupBox(L10n.accountingConversion(lang)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.accountingCurrency(lang))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(referenceCurrency.label)
                                .font(.headline)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.exchangeRate(lang))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 8) {
                                Text("1 \(document.currency.label) =")
                                    .foregroundStyle(.secondary)
                                DecimalField(
                                    placeholder: L10n.exchangeRateHint(
                                        lang,
                                        source: document.currency.label,
                                        target: referenceCurrency.label
                                    ),
                                    value: Binding(
                                        get: {
                                            document.accountingCurrency == referenceCurrency
                                                ? document.accountingExchangeRate ?? 0
                                                : 0
                                        },
                                        set: { newValue in
                                            document.setAccountingExchangeRate(
                                                newValue > 0 ? newValue : nil,
                                                referenceCurrency: referenceCurrency
                                            )
                                            saveDocument()
                                        }
                                    ),
                                    maximumFractionDigits: 8
                                )
                                .frame(maxWidth: 140)
                                Text(referenceCurrency.label)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let total = document.accountingTotal(referenceCurrency: referenceCurrency) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.accountingTotal(lang))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(referenceCurrency.formatAccounting(total, lang: dataStore.companyInfo.formatNombre))
                                    .font(.headline.monospacedDigit())
                            }
                        }

                        Spacer()
                    }

                    if document.accountingTotal(referenceCurrency: referenceCurrency) == nil {
                        Text(L10n.exchangeRateRequiredForDashboard(lang))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(8)
            }
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

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.siret(lang))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField(L10n.siret(lang), text: Binding(
                        get: { document.clientSiret },
                        set: { document.clientSiret = $0; scheduleSave() }
                    ))
                    .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.vatNumber(lang))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField(L10n.vatNumber(lang), text: Binding(
                        get: { document.clientTva },
                        set: { document.clientTva = $0; scheduleSave() }
                    ))
                    .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.apeCode(lang))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField(L10n.apeCode(lang), text: Binding(
                        get: { document.clientApe },
                        set: { document.clientApe = $0; scheduleSave() }
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

    private func convertirEnFacture() {
        let facture = document.convertirEnFacture()
        facture.number = DocumentNumberService.nextNumber(
            type: .facture,
            existingDocuments: allDocuments,
            language: lang
        )
        dataStore.addDocument(facture)
    }

    private func exporterPDF() {
        if document.paymentSnapshot == nil {
            if document.freezePaymentSnapshot(from: company) {
                saveDocument()
            }
        }

        let pdfData = PDFGenerator(document: document, company: company).generate()
        guard !pdfData.isEmpty else {
            showPDFGenerationAlert = true
            return
        }

        Task {
            let result = await ExportService.exportPDF(data: pdfData, defaultFilename: document.number, language: lang)
            if result == .failed {
                showPDFExportAlert = true
            }
        }
    }
}
