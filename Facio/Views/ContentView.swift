import SwiftUI

struct ContentView: View {
    @Environment(DataStore.self) private var dataStore
    @Environment(ToastCenter.self) private var toastCenter
    @State private var selectedSection: SidebarSection? = .dashboard
    @State private var selectedDocumentId: UUID?
    @State private var selectedTimesheetId: UUID?
    @State private var selectedClientId: UUID?
    @State private var selectedSettingsTab = 0
    @State private var showCommandPalette = false

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var selectedDocument: Document? {
        guard let id = selectedDocumentId else { return nil }
        return dataStore.documents.first { $0.id == id }
    }

    private var selectedTimesheet: TimesheetPeriod? {
        guard let id = selectedTimesheetId else { return nil }
        return dataStore.timesheets.first { $0.id == id }
    }

    private var usesContentColumn: Bool {
        switch selectedSection {
        case .factures, .devis, .heures:
            return true
        case .clients, .planning, .dashboard, .parametres, .none:
            return false
        }
    }

    var body: some View {
        Group {
            if usesContentColumn {
                NavigationSplitView {
                    SidebarView(selection: $selectedSection)
                } content: {
                    contentForSection
                        .navigationSplitViewColumnWidth(
                            min: FacioLayout.contentColumnMin,
                            ideal: FacioLayout.contentColumnIdeal,
                            max: FacioLayout.contentColumnMax
                        )
                } detail: {
                    detailForSection
                        .frame(minWidth: FacioLayout.detailMin)
                        .facioResponsiveContainer()
                }
            } else {
                NavigationSplitView {
                    SidebarView(selection: $selectedSection)
                } detail: {
                    detailForSection
                        .frame(minWidth: FacioLayout.detailMin)
                        .facioResponsiveContainer()
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .facioToastHost()
        // Les erreurs de persistance étaient remplies par DataStore mais
        // jamais affichées : on les fait remonter en toast non bloquant.
        .onChange(of: dataStore.persistenceErrors) { _, errors in
            if let message = errors.values.first {
                toastCenter.show(message, tone: .danger)
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
                Menu {
                    Button {
                        newDocument(.facture)
                    } label: {
                        Label(L10n.quickCreateInvoice(lang), systemImage: SidebarSection.factures.icon)
                    }
                    Button {
                        newDocument(.devis)
                    } label: {
                        Label(L10n.quickCreateQuote(lang), systemImage: SidebarSection.devis.icon)
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
                    Label(L10n.commandPaletteTitle(lang), systemImage: "command")
                }
                .keyboardShortcut("k", modifiers: .command)
                .help(L10n.commandPaletteTitle(lang))
            }
        }
        .onChange(of: selectedSection) { _, newSection in
            switch newSection {
            case .factures:
                if selectedDocument?.type != .facture {
                    selectedDocumentId = nil
                }
                selectedTimesheetId = nil
                selectedClientId = nil
            case .devis:
                if selectedDocument?.type != .devis {
                    selectedDocumentId = nil
                }
                selectedTimesheetId = nil
                selectedClientId = nil
            case .heures:
                selectedDocumentId = nil
                selectedClientId = nil
            case .clients:
                selectedDocumentId = nil
                selectedTimesheetId = nil
            case .planning, .dashboard, .parametres, .none:
                selectedDocumentId = nil
                selectedTimesheetId = nil
                selectedClientId = nil
            }
        }
    }

    // MARK: - Content column (middle)

    @ViewBuilder
    private var contentForSection: some View {
        switch selectedSection {
        case .factures:
            DocumentListView(
                documentType: .facture,
                selectedDocumentId: $selectedDocumentId
            ) { document in
                selectedSection = document.type == .facture ? .factures : .devis
                selectedDocumentId = document.id
            }
        case .devis:
            DocumentListView(
                documentType: .devis,
                selectedDocumentId: $selectedDocumentId
            ) { document in
                selectedSection = document.type == .facture ? .factures : .devis
                selectedDocumentId = document.id
            }
        case .heures:
            TimesheetListView(selectedTimesheetId: $selectedTimesheetId) { invoice in
                openInvoice(invoice)
            }
        case .clients, .planning, .dashboard, .parametres, .none:
            EmptyView()
        }
    }

    // MARK: - Detail column (right)

    @ViewBuilder
    private var detailForSection: some View {
        switch selectedSection {
        case .factures, .devis:
            if let doc = selectedDocument {
                DocumentEditorView(document: doc)
            } else {
                FacioEmptyState(
                    title: L10n.noDocumentSelected(lang),
                    systemImage: "doc.text",
                    message: L10n.selectDocumentHint(lang)
                ) {
                    FacioButton(
                        selectedSection == .devis ? L10n.quickCreateQuote(lang) : L10n.quickCreateInvoice(lang),
                        systemImage: "plus"
                    ) {
                        newDocument(selectedSection == .devis ? .devis : .facture)
                    }
                }
            }
        case .heures:
            if let ts = selectedTimesheet {
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
                selectedSection = document.type == .facture ? .factures : .devis
                selectedDocumentId = document.id
            }
        case .planning:
            TimeHubView { invoice in
                openInvoice(invoice)
            }
        case .dashboard:
            DashboardView { document in
                selectedSection = document.type == .facture ? .factures : .devis
                selectedDocumentId = document.id
            } onSelectTimesheet: { timesheet in
                selectedSection = .heures
                selectedTimesheetId = timesheet.id
            }
        case .parametres:
            SettingsInlineView(selectedTab: $selectedSettingsTab)
        case .none:
            Text(L10n.selectSection(lang))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func openInvoice(_ invoice: Document) {
        selectedSection = .factures
        selectedDocumentId = invoice.id
        selectedTimesheetId = nil
        selectedClientId = nil
    }

    // MARK: - Toolbar

    private func newDocument(_ type: DocumentType) {
        let document = dataStore.createDocument(type: type)
        selectedSection = type == .facture ? .factures : .devis
        selectedDocumentId = document.id
        selectedTimesheetId = nil
        selectedClientId = nil
    }

    private func newClient() {
        let client = dataStore.createClient(name: L10n.newClient(lang))
        selectedSection = .clients
        selectedClientId = client.id
        selectedDocumentId = nil
        selectedTimesheetId = nil
    }
}
