import SwiftUI

struct ContentView: View {
    @Environment(DataStore.self) private var dataStore
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
                }
            } else {
                NavigationSplitView {
                    SidebarView(selection: $selectedSection)
                } detail: {
                    detailForSection
                        .frame(minWidth: FacioLayout.detailMin)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showCommandPalette) {
            CommandPaletteView(
                selectedSection: $selectedSection,
                selectedDocumentId: $selectedDocumentId,
                selectedTimesheetId: $selectedTimesheetId,
                selectedClientId: $selectedClientId,
                selectedSettingsTab: $selectedSettingsTab
            )
            .frame(width: 560, height: 520)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
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
                ContentUnavailableView(
                    L10n.noDocumentSelected(lang),
                    systemImage: "doc.text",
                    description: Text(L10n.selectDocumentHint(lang))
                )
            }
        case .heures:
            if let ts = selectedTimesheet {
                TimesheetEditorView(timesheet: ts) { invoice in
                    openInvoice(invoice)
                }
            } else {
                ContentUnavailableView(
                    L10n.noPeriodSelected(lang),
                    systemImage: "clock",
                    description: Text(L10n.selectPeriodHint(lang))
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
}
