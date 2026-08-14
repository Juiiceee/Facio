import SwiftUI

struct ContentView: View {
    @Environment(DataStore.self) private var dataStore
    @Environment(PrivacyMode.self) private var privacy
    @Environment(AppLock.self) private var appLock

    @State private var selectedSection: SidebarSection? = .dashboard
    @State private var selectedDocumentId: UUID?
    @State private var selectedTimesheetId: UUID?
    @State private var selectedClientId: UUID?
    @State private var selectedSettingsTab = 0
    @State private var showCommandPalette = false

    /// Segment en tête de la liste « Ventes ». Factures et devis partagent le
    /// même éditeur et le même modèle : deux entrées de barre latérale pour un
    /// seul `DocumentType` étaient un coût de navigation pur.
    @State private var salesType: DocumentType = .facture
    /// Entrée « Toute l'activité » en tête de la liste des périodes : c'est
    /// l'agrégation qui vivait dans une seconde section de la barre latérale.
    @State private var timeShowsAllActivity = false

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var selectedDocument: Document? {
        guard let id = selectedDocumentId else { return nil }
        return dataStore.documents.first { $0.id == id }
    }

    private var selectedTimesheet: TimesheetPeriod? {
        guard let id = selectedTimesheetId else { return nil }
        return dataStore.timesheets.first { $0.id == id }
    }

    private var hasList: Bool { selectedSection?.hasList == true }

    var body: some View {
        // UN SEUL NavigationSplitView, quelle que soit la section.
        //
        // Le châssis instanciait deux structures différentes selon la section :
        // passer de Ventes (3 colonnes) au Tableau de bord (2 colonnes)
        // détruisait et recréait toute la fenêtre, donc les largeurs de colonnes
        // redimensionnées et l'état de repli de la barre latérale étaient perdus,
        // sans animation. C'était le défaut structurel le plus visible du produit.
        //
        // La colonne liste ne disparaît plus : elle se replie en rail.
        NavigationSplitView {
            SidebarView(selection: $selectedSection) { openRunningEntry() }
        } content: {
            contentColumn
                .navigationSplitViewColumnWidth(
                    min: hasList ? FacioLayout.contentColumnMin : FacioLayout.contentRailWidth,
                    ideal: hasList ? FacioLayout.contentColumnIdeal : FacioLayout.contentRailWidth,
                    max: hasList ? FacioLayout.contentColumnMax : FacioLayout.contentRailWidth
                )
        } detail: {
            detailForSection
                .frame(minWidth: FacioLayout.detailMin)
                .facioResponsiveContainer()
        }
        .navigationSplitViewStyle(.balanced)
        .facioToastHost()
        // Les erreurs de persistance (risque de perte de données, chemin de
        // backup à noter) sont persistantes : bannière pilotée par l'état —
        // visible dès le lancement et tant que l'erreur n'est pas résolue —
        // et non un toast éphémère (hiérarchie documentée dans FacioToast).
        .overlay(alignment: .top) {
            if !dataStore.persistenceErrors.isEmpty {
                VStack(alignment: .leading, spacing: FacioLayout.space4) {
                    ForEach(dataStore.persistenceErrors.sorted(by: { $0.key < $1.key }), id: \.key) { _, message in
                        InlineWarning(text: message, tone: .danger)
                    }
                }
                .frame(maxWidth: 560)
                .padding(.top, FacioLayout.space8)
            }
        }
        .sheet(isPresented: $showCommandPalette) {
            CommandPaletteView(
                selectedSection: $selectedSection,
                selectedDocumentId: $selectedDocumentId,
                selectedTimesheetId: $selectedTimesheetId,
                selectedClientId: $selectedClientId,
                selectedSettingsTab: $selectedSettingsTab
            )
            .frame(
                minWidth: FacioLayout.sheetMinWidth, idealWidth: FacioLayout.sheetIdealWidth, maxWidth: 760,
                minHeight: FacioLayout.sheetMinHeight, idealHeight: FacioLayout.sheetIdealHeight, maxHeight: 720
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Plus de garde sur le verrouillage ici : `FacioApp` ne monte
                // plus du tout cette vue quand l'app est verrouillée, donc ni
                // ces actions ni leurs raccourcis n'existent à ce moment-là.
                toolbarActions
            }
        }
        .onChange(of: selectedSection) { _, newSection in
            switch newSection {
            case .ventes:
                selectedTimesheetId = nil
                selectedClientId = nil
            case .temps:
                selectedDocumentId = nil
                selectedClientId = nil
            case .clients:
                selectedDocumentId = nil
                selectedTimesheetId = nil
            case .dashboard, .parametres, .none:
                selectedDocumentId = nil
                selectedTimesheetId = nil
                selectedClientId = nil
            }
        }
        .onChange(of: salesType) { _, newType in
            // Le segment change de type : on ne garde pas un document de l'autre.
            if selectedDocument?.type != newType { selectedDocumentId = nil }
        }
    }

    // MARK: - Barre d'outils

    @ViewBuilder
    private var toolbarActions: some View {
        Menu {
            Button {
                newDocument(.facture)
            } label: {
                Label(L10n.quickCreateInvoice(lang), systemImage: "doc.text")
            }
            Button {
                newDocument(.devis)
            } label: {
                Label(L10n.quickCreateQuote(lang), systemImage: "doc.text.magnifyingglass")
            }
            Divider()
            Button {
                newClient()
            } label: {
                Label(L10n.quickCreateClient(lang), systemImage: "person.crop.circle.badge.plus")
            }
        } label: {
            Label(L10n.new(lang), systemImage: "plus")
        }
        .help(L10n.new(lang))

        Button {
            showCommandPalette = true
        } label: {
            Label(L10n.commandPaletteTitle(lang), systemImage: "magnifyingglass")
        }
        .keyboardShortcut("k", modifiers: .command)
        .help(L10n.commandPaletteTitle(lang))

        // Le libellé suit l'état : il proposait « Masquer les montants » alors
        // qu'ils étaient déjà masqués, donc l'infobulle et VoiceOver annonçaient
        // l'inverse de ce qui allait se produire.
        Button {
            privacy.toggle()
        } label: {
            Label(
                privacy.hideAmounts ? L10n.privacyShow(lang) : L10n.privacyHide(lang),
                systemImage: privacy.hideAmounts ? "eye.slash" : "eye"
            )
        }
        .keyboardShortcut("h", modifiers: [.command, .shift])
        .help(privacy.hideAmounts ? L10n.privacyShow(lang) : L10n.privacyHide(lang))

        // Verrouillage manuel — visible seulement si un code est configuré.
        if appLock.isEnabled {
            Button {
                appLock.lockNow()
            } label: {
                Label(L10n.lockNow(lang), systemImage: "lock")
            }
            // Le raccourci ⌃⌘L est porté par la commande du menu de l'app
            // (FacioApp) — le dupliquer ici le rendrait ambigu.
            .help(L10n.lockNow(lang))
        }
    }

    // MARK: - Colonne liste

    @ViewBuilder
    private var contentColumn: some View {
        switch selectedSection {
        case .ventes:
            salesList
        case .temps:
            timeList
        case .clients, .dashboard, .parametres, .none:
            // Rail : la colonne reste en place, réduite. C'est ce qui évite de
            // reconstruire le châssis à chaque changement de section.
            ContentRail(lang: lang) { selectedSection = .ventes }
        }
    }

    private var salesList: some View {
        VStack(spacing: 0) {
            Picker("", selection: $salesType) {
                Text(L10n.sidebarInvoices(lang)).tag(DocumentType.facture)
                Text(L10n.sidebarQuotes(lang)).tag(DocumentType.devis)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .padding(.horizontal, FacioLayout.space12)
            .padding(.vertical, FacioLayout.space8)

            Divider()

            DocumentListView(
                documentType: salesType,
                selectedDocumentId: $selectedDocumentId
            ) { document in
                openDocument(document)
            }
        }
    }

    private var timeList: some View {
        VStack(spacing: 0) {
            Button {
                timeShowsAllActivity = true
                selectedTimesheetId = nil
            } label: {
                HStack(spacing: FacioLayout.space8) {
                    Image(systemName: "chart.bar")
                    Text(L10n.allActivity(lang))
                    Spacer()
                }
                .font(FacioFont.rowTitle)
                .foregroundStyle(timeShowsAllActivity ? Color.accentText : Color.textPrimary)
                .padding(.horizontal, FacioLayout.space12)
                .padding(.vertical, FacioLayout.space8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(timeShowsAllActivity ? Color.surfaceSelected : Color.clear)

            Divider()

            TimesheetListView(selectedTimesheetId: $selectedTimesheetId) { invoice in
                openInvoice(invoice)
            }
        }
        .onChange(of: selectedTimesheetId) { _, newValue in
            if newValue != nil { timeShowsAllActivity = false }
        }
    }

    // MARK: - Colonne détail

    @ViewBuilder
    private var detailForSection: some View {
        switch selectedSection {
        case .ventes:
            if let doc = selectedDocument {
                DocumentEditorView(document: doc)
            } else {
                FacioEmptyState(
                    title: L10n.noDocumentSelected(lang),
                    systemImage: "doc.text",
                    message: L10n.selectDocumentHint(lang)
                ) {
                    FacioButton(
                        salesType == .devis ? L10n.quickCreateQuote(lang) : L10n.quickCreateInvoice(lang),
                        systemImage: "plus"
                    ) {
                        newDocument(salesType)
                    }
                }
            }
        case .temps:
            if timeShowsAllActivity {
                TimeHubView { invoice in
                    openInvoice(invoice)
                }
            } else if let ts = selectedTimesheet {
                TimesheetEditorView(timesheet: ts) { invoice in
                    openInvoice(invoice)
                }
            } else {
                FacioEmptyState(
                    title: L10n.noPeriodSelected(lang),
                    systemImage: "clock",
                    message: L10n.selectPeriodHint(lang)
                )
            }
        case .clients:
            ClientListView(selectedClientId: $selectedClientId) { document in
                openDocument(document)
            }
        case .dashboard:
            DashboardView { document in
                openDocument(document)
            } onSelectTimesheet: { timesheet in
                selectedSection = .temps
                timeShowsAllActivity = false
                selectedTimesheetId = timesheet.id
            }
        case .parametres:
            SettingsInlineView(selectedTab: $selectedSettingsTab)
        case .none:
            FacioEmptyState(
                title: L10n.selectSection(lang),
                systemImage: "square.grid.2x2"
            )
        }
    }

    // MARK: - Navigation

    private func openDocument(_ document: Document) {
        selectedSection = .ventes
        salesType = document.type
        selectedDocumentId = document.id
        selectedTimesheetId = nil
        selectedClientId = nil
    }

    private func openInvoice(_ invoice: Document) {
        openDocument(invoice)
    }

    /// Le minuteur est pilotable de partout : le clic ramène à la période qu'il
    /// alimente, quelle que soit la section où on se trouvait.
    private func openRunningEntry() {
        selectedSection = .temps
        timeShowsAllActivity = false
        selectedTimesheetId = dataStore.runningTimeEntryContext?.timesheet.id
    }

    private func newDocument(_ type: DocumentType) {
        let document = dataStore.createDocument(type: type)
        openDocument(document)
    }

    private func newClient() {
        let client = dataStore.createClient(name: L10n.newClient(lang))
        selectedSection = .clients
        selectedClientId = client.id
        selectedDocumentId = nil
        selectedTimesheetId = nil
    }
}

// MARK: - Rail

/// La colonne liste, repliée.
///
/// Les sections sans liste (Tableau de bord, Clients, Paramètres) ne font plus
/// disparaître la colonne : elle se réduit à un rail. Le châssis garde ainsi la
/// même structure d'un bout à l'autre de l'application, et le chevron ramène à
/// la dernière liste.
private struct ContentRail: View {
    let lang: AppLanguage
    let onExpand: () -> Void

    var body: some View {
        VStack {
            FacioIconButton(
                systemImage: "chevron.right",
                label: L10n.sidebarSales(lang),
                action: onExpand
            )
            .padding(.top, FacioLayout.space8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceCanvas)
    }
}
