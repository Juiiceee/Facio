import SwiftUI

struct DocumentEditorView: View {
    var document: Document

    @Environment(DataStore.self) private var dataStore

    @State private var showClientPicker = false
    @State private var showPreview = false
    @State private var showAddSignature = false
    @State private var showPDFGenerationAlert = false
    @State private var showPDFExportAlert = false
    @State private var attachmentCopyFailures = 0
    @State private var showAttachmentCopyAlert = false
    @State private var showEmailUnavailableAlert = false
    @State private var showFacturXAlert = false
    @State private var facturXAlertMessage = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ToastCenter.self) private var toastCenter
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
                // Re-pose le conteneur responsive : quand l'inspecteur latéral est
                // visible, la largeur réelle de la colonne de contenu est plus
                // étroite que la colonne détail mesurée par ContentView.
                documentMainScroll(showInlineInspector: !usesSideInspector)
                    .frame(maxWidth: .infinity)
                    .facioResponsiveContainer()

                if usesSideInspector && hasReadinessIssues {
                    Divider()
                    documentInspector
                }
            }
            // Apparition/masquage de l'inspecteur au franchissement du breakpoint.
            .animation(FacioMotion.respecting(FacioMotion.state, reduceMotion: reduceMotion), value: usesSideInspector)
        }
        .navigationTitle(document.number.isEmpty ? L10n.newDocument(lang) : document.number)
        // L'enregistrement est différé de 500 ms ; si la vue disparaît entre
        // deux (verrouillage de l'app, changement de section), la tâche est
        // annulée et la dernière frappe ne serait jamais écrite sur disque.
        .onDisappear {
            saveTask?.cancel()
            saveDocument()
        }
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
        .alert(L10n.emailUnavailableTitle(lang), isPresented: $showEmailUnavailableAlert) {
            Button(L10n.understood(lang), role: .cancel) {}
        } message: {
            Text(L10n.emailUnavailableMessage(lang))
        }
        .alert(L10n.facturXTitle(lang), isPresented: $showFacturXAlert) {
            Button(L10n.understood(lang), role: .cancel) {}
        } message: {
            Text(facturXAlertMessage)
        }
        .alert(L10n.attachmentsCopyFailedTitle(lang), isPresented: $showAttachmentCopyAlert) {
            Button(L10n.understood(lang), role: .cancel) {}
        } message: {
            Text(L10n.attachmentsCopyFailedMessage(lang, count: attachmentCopyFailures))
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
                totauxSection
                DocumentPaymentInfoView(document: document, company: company, lang: lang) {
                    saveDocument()
                }

                DocumentAttachmentsSection(document: document, lang: lang)

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
        HStack(alignment: .center, spacing: FacioLayout.space16) {
            heroIdentity

            Spacer()

            heroTotal
            heroActions
        }
    }

    private var heroCompact: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space12) {
            heroIdentity

            HStack(alignment: .bottom, spacing: FacioLayout.space16) {
                heroTotal
                Spacer()
                heroActions
            }
        }
    }

    private var heroIdentity: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space8) {
            HStack(spacing: FacioLayout.space8) {
                Text(document.type.label(for: lang))
                    .font(FacioFont.subsectionTitle)
                    .foregroundStyle(Color.appPrimary(from: company))
                StatusBadge(status: document.status, isOverdue: document.isOverdue, paidViaInstallments: document.isPaidViaInstallments)
            }

            TextField(L10n.number(lang), text: Binding(
                get: { document.number },
                set: { document.number = $0; scheduleSave() }
            ))
            .font(FacioFont.heroTitle)
            .textFieldStyle(.plain)
            .lineLimit(1)

            Text(document.clientNom.isEmpty ? L10n.noClient(lang) : document.clientNom)
                .font(FacioFont.screenSubtitle)
                .foregroundStyle(document.clientNom.isEmpty ? .tertiary : .secondary)
                .lineLimit(1)
        }
        .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)
    }

    private var heroTotal: some View {
        VStack(alignment: .trailing, spacing: FacioLayout.space4) {
            Text(L10n.totalTTC(lang))
                .font(FacioFont.caption)
                .foregroundStyle(.secondary)
            MoneyText(amount: document.totalTTC, currency: document.currency, lang: dataStore.companyInfo.formatNombre)
                .font(FacioFont.heroTotal)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(minWidth: 150, alignment: .trailing)
    }

    private var heroActions: some View {
        VStack(alignment: .trailing, spacing: FacioLayout.space8) {
            Button {
                showPreview = true
            } label: {
                Label(L10n.preview(lang), systemImage: "eye")
            }
            .buttonStyle(.facio(.secondary))

            Button {
                exporterPDF()
            } label: {
                Label(L10n.exportPDF(lang), systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.facio(.primary))
        }
    }

    private var documentDetailsSection: some View {
        SectionPanel(L10n.documentDetails(lang), systemImage: "slider.horizontal.3") {
            VStack(alignment: .leading, spacing: FacioLayout.space16) {
                enTeteSection
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: FacioLayout.space16) {
                        datesSection
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        deviseSection
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }

                    VStack(alignment: .leading, spacing: FacioLayout.space16) {
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
                VStack(alignment: .leading, spacing: FacioLayout.space10) {
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
            .help(L10n.duplicate(lang))

            Button {
                showPreview = true
            } label: {
                Label(L10n.preview(lang), systemImage: "eye")
            }
            .help(L10n.preview(lang))

            Button {
                exporterPDF()
            } label: {
                Label(L10n.exportPDF(lang), systemImage: "square.and.arrow.up")
            }
            .help(L10n.exportPDF(lang))

            if document.type == .facture {
                Button {
                    exporterFacturX()
                } label: {
                    Label(L10n.exportFacturX(lang), systemImage: "checkmark.seal")
                }
                .help(L10n.exportFacturXHelp(lang))
            }

            Button {
                envoyerParEmail()
            } label: {
                Label(L10n.sendByEmail(lang), systemImage: "paperplane")
            }
            .help(L10n.sendByEmail(lang))
        }
    }

    // MARK: - En-tete

    private var enTeteSection: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space12) {
            subsectionHeader(L10n.headerSection(lang))
            // Grille adaptative : 4 colonnes en large, wrap auto 4→2→1 en se
            // réduisant. La grille égalise les largeurs, plus de frames figées.
            FormGrid(minimum: 140, maximum: 250) {
                LabeledField(L10n.type(lang)) {
                    Text(document.type.label(for: lang))
                        .font(.headline)
                        .foregroundStyle(Color.appPrimary(from: dataStore.companyInfo))
                }

                LabeledField(L10n.number(lang)) {
                    TextField(L10n.number(lang), text: Binding(
                        get: { document.number },
                        set: { document.number = $0; scheduleSave() }
                    ))
                    .facioField()
                }

                LabeledField(L10n.language(lang)) {
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
                    .frame(maxWidth: .infinity)
                }

                LabeledField(L10n.status(lang)) {
                    Picker(L10n.status(lang), selection: Binding(
                        get: { document.status },
                        set: { newStatus in
                            document.status = newStatus
                            if newStatus == .envoyee {
                                _ = document.freezePaymentSnapshot(from: company)
                            }
                            // Premier versement prêt à saisir dès qu'on passe en partiel.
                            if newStatus == .partiel && document.paiementsPartiels.isEmpty {
                                document.paiementsPartiels.append(PartialPayment())
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
                            HStack(spacing: FacioLayout.space6) {
                                Circle()
                                    .fill(Color.statusColor(for: status))
                                    .frame(width: 8, height: 8)
                                Text(status.label(for: lang))
                            }
                            .tag(status)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    /// En-tête d'une sous-section à l'intérieur d'un `SectionPanel` aplati.
    private func subsectionHeader(_ title: String) -> some View {
        Text(title)
            .font(FacioFont.subsectionTitle)
            .foregroundStyle(.secondary)
    }

    // MARK: - Dates

    private var datesSection: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space12) {
            subsectionHeader(L10n.datesSection(lang))
            HStack(spacing: FacioLayout.space24) {
                DatePicker(L10n.creationDate(lang), selection: Binding(
                    get: { document.dateCreation },
                    set: { document.dateCreation = $0; saveDocument() }
                ), displayedComponents: .date)
                DatePicker(L10n.dueDateLabel(lang), selection: Binding(
                    get: { document.dateEcheance },
                    set: { document.dateEcheance = $0; saveDocument() }
                ), displayedComponents: .date)
            }
            // Date d'encaissement (facture payée en une fois) : rattache le CA au
            // bon mois. Une facture soldée par versements montre son journal.
            if document.status == .payee && document.paiementsPartiels.isEmpty {
                DatePicker(L10n.paymentDate(lang), selection: Binding(
                    get: { document.datePaiement ?? document.dateCreation },
                    set: { document.datePaiement = $0; saveDocument() }
                ), displayedComponents: .date)
                .tint(.intentSuccess)
            }
            // Journal des versements : statut partiel, ou facture soldée par
            // versements successifs.
            if document.status == .partiel || (document.status == .payee && !document.paiementsPartiels.isEmpty) {
                partialPaymentsEditor
            }
        }
    }

    // MARK: - Paiements partiels

    private var partialPaymentsEditor: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space8) {
            subsectionHeader(L10n.partialPayments(lang))

            if document.paiementsPartiels.isEmpty {
                Text(L10n.noPartialPayments(lang))
                    .font(FacioFont.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(document.paiementsPartiels) { payment in
                    HStack(spacing: FacioLayout.space12) {
                        DatePicker("", selection: paymentDateBinding(payment), displayedComponents: .date)
                            .labelsHidden()
                            .tint(.intentInfo)
                        HStack(spacing: FacioLayout.space8) {
                            DecimalField(
                                placeholder: "0",
                                value: paymentAmountBinding(payment),
                                maximumFractionDigits: document.currency.maximumFractionDigits,
                                format: dataStore.companyInfo.formatNombre
                            )
                            .density(.regular)
                            .frame(maxWidth: 140)
                            Text(document.currency.label)
                                .foregroundStyle(.secondary)
                        }
                        Button(role: .destructive) {
                            document.paiementsPartiels.removeAll { $0.id == payment.id }
                            saveAfterLedgerChange()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                        .help(L10n.delete(lang))
                    }
                }
            }

            HStack(spacing: FacioLayout.space16) {
                Button {
                    document.paiementsPartiels.append(PartialPayment())
                    saveDocument()
                } label: {
                    Label(L10n.addPartialPayment(lang), systemImage: "plus.circle")
                }
                .buttonStyle(.borderless)
                .tint(.intentInfo)

                // Raccourci : une fois un premier versement saisi, régler d'un clic
                // tout le solde restant (100 %) comme dernier versement.
                if document.montantEncaisse > 0 && document.resteAPayer > 0 {
                    Button(action: payRemainingBalance) {
                        Label(
                            L10n.payRemainingBalance(
                                lang,
                                amount: document.currency.formatAccounting(document.resteAPayer, lang: dataStore.companyInfo.formatNombre)
                            ),
                            systemImage: "checkmark.circle"
                        )
                    }
                    .buttonStyle(.borderless)
                    .tint(.intentSuccess)
                }
            }

            Divider().padding(.vertical, FacioLayout.space4)

            HStack(spacing: FacioLayout.space24) {
                LabeledField(L10n.amountPaid(lang)) {
                    MoneyText(amount: document.montantEncaisse, currency: document.currency, lang: dataStore.companyInfo.formatNombre)
                }
                LabeledField(L10n.remainingToPay(lang)) {
                    MoneyText(amount: document.resteAPayer, currency: document.currency, lang: dataStore.companyInfo.formatNombre)
                        .foregroundStyle(document.resteAPayer == 0 ? Color.intentSuccess : Color.intentInfo)
                }
            }
        }
    }

    /// Règle tout le solde restant en un versement daté du jour : remplit une
    /// ligne vide si elle existe, sinon en ajoute une.
    private func payRemainingBalance() {
        let reste = document.resteAPayer
        guard reste > 0 else { return }
        if let emptyIndex = document.paiementsPartiels.lastIndex(where: { $0.montant == 0 }) {
            document.paiementsPartiels[emptyIndex].montant = reste
            document.paiementsPartiels[emptyIndex].date = Date()
        } else {
            document.paiementsPartiels.append(PartialPayment(montant: reste, date: Date()))
        }
        saveAfterLedgerChange()
    }

    /// Aligne le statut sur l'encaissement du journal. N'est appelée que depuis
    /// l'édition d'un journal existant (montant, suppression, « Payer le reste »).
    /// Une facture partielle intégralement réglée passe en « Payée » (journal daté
    /// conservé = mémoire du paiement en plusieurs fois) ; à l'inverse, une facture
    /// soldée par versements repassée sous 100 % — ou dont on a supprimé tous les
    /// versements — redevient « Partiel » (sinon elle resterait « Payée » avec un
    /// journal vide et un encaissé qui rebascule au TTC complet).
    private func reconcilePartialStatus() {
        if document.status == .partiel, document.montantEncaisse > 0, document.resteAPayer == 0 {
            document.status = .payee
        } else if document.status == .payee, document.resteAPayer > 0 || document.paiementsPartiels.isEmpty {
            document.status = .partiel
        }
    }

    private func saveAfterLedgerChange() {
        reconcilePartialStatus()
        saveDocument()
    }

    private func paymentDateBinding(_ payment: PartialPayment) -> Binding<Date> {
        Binding(
            get: { document.paiementsPartiels.first(where: { $0.id == payment.id })?.date ?? payment.date },
            set: { newValue in
                guard let index = document.paiementsPartiels.firstIndex(where: { $0.id == payment.id }) else { return }
                document.paiementsPartiels[index].date = newValue
                saveDocument()
            }
        )
    }

    private func paymentAmountBinding(_ payment: PartialPayment) -> Binding<Decimal> {
        Binding(
            get: { document.paiementsPartiels.first(where: { $0.id == payment.id })?.montant ?? payment.montant },
            set: { newValue in
                guard let index = document.paiementsPartiels.firstIndex(where: { $0.id == payment.id }) else { return }
                document.paiementsPartiels[index].montant = newValue
                saveAfterLedgerChange()
            }
        )
    }

    // MARK: - Devise & Mode de paiement

    private var deviseSection: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space12) {
            subsectionHeader(L10n.currencyPayment(lang))
            HStack(spacing: FacioLayout.space24) {
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
                HStack(spacing: FacioLayout.space16) {
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
    }

    @ViewBuilder
    private var accountingConversionSection: some View {
        let referenceCurrency = company.deviseComptable
        if document.type == .facture && document.needsAccountingConversion(referenceCurrency: referenceCurrency) {
            VStack(alignment: .leading, spacing: FacioLayout.space12) {
                subsectionHeader(L10n.accountingConversion(lang))
                // AdaptiveStack (pas ViewThatFits) : le DecimalField est
                // compressible à l'infini. Empile verticalement en compact.
                AdaptiveStack(hSpacing: FacioLayout.space24) {
                    LabeledField(L10n.accountingCurrency(lang)) {
                        Text(referenceCurrency.label)
                            .font(.headline)
                    }

                    LabeledField(L10n.exchangeRate(lang)) {
                        HStack(spacing: FacioLayout.space8) {
                            Text(L10n.exchangeRatePrefix(lang, source: document.currency.label))
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
                            .density(.regular)
                            .frame(maxWidth: 140)
                            Text(referenceCurrency.label)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let total = document.accountingTotal(referenceCurrency: referenceCurrency) {
                        LabeledField(L10n.accountingTotal(lang)) {
                            MoneyText(amount: total, currency: referenceCurrency, lang: dataStore.companyInfo.formatNombre)
                                .font(.headline.monospacedDigit())
                        }
                    }
                }

                if document.accountingTotal(referenceCurrency: referenceCurrency) == nil {
                    Text(L10n.exchangeRateRequiredForDashboard(lang))
                        .font(FacioFont.caption)
                        .foregroundStyle(Color.intentWarning)
                }
            }
        }
    }

    // MARK: - Client (Destinataire)

    private var clientSection: some View {
        SectionPanel(L10n.recipientSection(lang), systemImage: "person.text.rectangle") {
            VStack(alignment: .leading, spacing: FacioLayout.space12) {
                HStack {
                    Text(L10n.clientInfo(lang))
                        .font(FacioFont.fieldLabel)
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
        }
    }

    private var clientFields: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space12) {
            // Nom et adresse restent pleine largeur, hors grille.
            LabeledField(L10n.name(lang)) {
                TextField(L10n.clientName(lang), text: Binding(
                    get: { document.clientNom },
                    set: { document.clientNom = $0; scheduleSave() }
                ))
                .facioField()
            }

            LabeledField(L10n.address(lang)) {
                TextField(L10n.address(lang), text: Binding(
                    get: { document.clientAdresse },
                    set: { document.clientAdresse = $0; scheduleSave() }
                ))
                .facioField()
            }

            // Les 5 petits champs wrappent en grille : 5→3→2→1 colonnes
            // selon la largeur disponible.
            FormGrid(minimum: 150, maximum: 280) {
                LabeledField(L10n.postalCode(lang)) {
                    TextField(L10n.postalCode(lang), text: Binding(
                        get: { document.clientCodePostal },
                        set: { document.clientCodePostal = $0; scheduleSave() }
                    ))
                    .facioField()
                }

                LabeledField(L10n.city(lang)) {
                    TextField(L10n.city(lang), text: Binding(
                        get: { document.clientVille },
                        set: { document.clientVille = $0; scheduleSave() }
                    ))
                    .facioField()
                }

                LabeledField(L10n.siret(lang)) {
                    TextField(L10n.siret(lang), text: Binding(
                        get: { document.clientSiret },
                        set: { document.clientSiret = $0; scheduleSave() }
                    ))
                    .facioField()
                }

                LabeledField(L10n.vatNumber(lang)) {
                    TextField(L10n.vatNumber(lang), text: Binding(
                        get: { document.clientTva },
                        set: { document.clientTva = $0; scheduleSave() }
                    ))
                    .facioField()
                }

                LabeledField(L10n.apeCode(lang)) {
                    TextField(L10n.apeCode(lang), text: Binding(
                        get: { document.clientApe },
                        set: { document.clientApe = $0; scheduleSave() }
                    ))
                    .facioField()
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
        SectionPanel(L10n.notes(lang), systemImage: "note.text") {
            TextEditor(text: Binding(
                get: { document.notes },
                set: { document.notes = $0; scheduleSave() }
            ))
            .frame(minHeight: 60, maxHeight: 120)
            .font(FacioFont.body)
            .padding(FacioLayout.space4)
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
        reportCopyFailures(dataStore.duplicateAttachments(from: document, to: copie))
    }

    private func convertirEnFacture() {
        let facture = document.convertirEnFacture()
        facture.number = DocumentNumberService.nextNumber(
            type: .facture,
            existingDocuments: allDocuments,
            language: lang
        )
        dataStore.addDocument(facture)
        reportCopyFailures(dataStore.duplicateAttachments(from: document, to: facture))
    }

    private func reportCopyFailures(_ result: (copied: Int, failed: Int)) {
        guard result.failed > 0 else { return }
        attachmentCopyFailures = result.failed
        showAttachmentCopyAlert = true
    }

    private func exporterPDF() {
        if document.trustedPaymentSnapshot == nil {
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
            switch result {
            case .success:
                toastCenter.show(L10n.toastPDFExported(lang), icon: "square.and.arrow.up")
            case .failed:
                showPDFExportAlert = true
            case .cancelled:
                break
            }
        }
    }

    private func exporterFacturX() {
        if document.trustedPaymentSnapshot == nil {
            if document.freezePaymentSnapshot(from: company) {
                saveDocument()
            }
        }

        switch FacturXService.generate(document: document, company: company) {
        case .notApplicable(.notAnInvoice):
            facturXAlertMessage = L10n.facturXOnlyInvoices(lang)
            showFacturXAlert = true
        case let .notApplicable(.unsupportedCurrency(currency)):
            facturXAlertMessage = L10n.facturXOnlyEUR(lang, currency: currency)
            showFacturXAlert = true
        case .notApplicable(.incomplete(.noLines)):
            facturXAlertMessage = L10n.facturXIncompleteNoLines(lang)
            showFacturXAlert = true
        case .notApplicable(.incomplete(.missingNumber)):
            facturXAlertMessage = L10n.facturXIncompleteNumber(lang)
            showFacturXAlert = true
        case .notApplicable(.incomplete(.missingClient)):
            facturXAlertMessage = L10n.facturXIncompleteClient(lang)
            showFacturXAlert = true
        case .notApplicable(.incomplete(.missingSellerVAT)):
            facturXAlertMessage = L10n.facturXMissingSellerVAT(lang)
            showFacturXAlert = true
        case .notApplicable(.incomplete(.missingSellerTaxRegistration)):
            facturXAlertMessage = L10n.facturXMissingSellerTaxRegistration(lang)
            showFacturXAlert = true
        case .notApplicable(.unsupportedExemptLine):
            facturXAlertMessage = L10n.facturXUnsupportedExemptLine(lang)
            showFacturXAlert = true
        case .notApplicable(.applicable):
            break // inatteignable
        case .failed:
            facturXAlertMessage = L10n.facturXGenerationFailed(lang)
            showFacturXAlert = true
        case let .success(data):
            Task {
                let result = await ExportService.exportPDF(data: data, defaultFilename: document.number, language: lang)
                switch result {
                case .success:
                    toastCenter.show(L10n.toastFacturXExported(lang), icon: "checkmark.seal")
                case .failed:
                    showPDFExportAlert = true
                case .cancelled:
                    break
                }
            }
        }
    }

    private func envoyerParEmail() {
        if document.trustedPaymentSnapshot == nil {
            if document.freezePaymentSnapshot(from: company) {
                saveDocument()
            }
        }

        let pdfData = PDFGenerator(document: document, company: company).generate()
        guard !pdfData.isEmpty else {
            showPDFGenerationAlert = true
            return
        }

        let attachments = dataStore.emailAttachments(for: document)
        let result = EmailService.composeInvoiceEmail(
            document: document,
            company: company,
            pdfData: pdfData,
            attachments: attachments
        )
        switch result {
        case .composed:
            toastCenter.show(L10n.toastEmailComposed(lang), icon: "paperplane")
        case .unavailable:
            showEmailUnavailableAlert = true
        }
    }
}
