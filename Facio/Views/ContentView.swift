import SwiftUI

struct ContentView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var selectedSection: SidebarSection? = .factures
    @State private var selectedDocumentId: UUID?
    @State private var selectedTimesheetId: UUID?
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
        case .clients, .dashboard, .parametres, .none:
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
                        .navigationSplitViewColumnWidth(min: 300, ideal: 320, max: 400)
                } detail: {
                    detailForSection
                        .frame(minWidth: 500)
                }
            } else {
                NavigationSplitView {
                    SidebarView(selection: $selectedSection)
                } detail: {
                    detailForSection
                        .frame(minWidth: 700)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $showCommandPalette) {
            CommandPaletteView(
                selectedSection: $selectedSection,
                selectedDocumentId: $selectedDocumentId,
                selectedTimesheetId: $selectedTimesheetId,
                selectedSettingsTab: $selectedSettingsTab
            )
            .frame(width: 560, height: 520)
        }
        .background(
            Button {
                showCommandPalette = true
            } label: {
                EmptyView()
            }
            .keyboardShortcut("k", modifiers: .command)
            .opacity(0)
            .frame(width: 0, height: 0)
        )
        .onChange(of: selectedSection) { _, newSection in
            switch newSection {
            case .factures:
                if selectedDocument?.type != .facture {
                    selectedDocumentId = nil
                }
                selectedTimesheetId = nil
            case .devis:
                if selectedDocument?.type != .devis {
                    selectedDocumentId = nil
                }
                selectedTimesheetId = nil
            case .heures:
                selectedDocumentId = nil
            case .clients, .dashboard, .parametres, .none:
                selectedDocumentId = nil
                selectedTimesheetId = nil
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
            )
        case .devis:
            DocumentListView(
                documentType: .devis,
                selectedDocumentId: $selectedDocumentId
            )
        case .heures:
            TimesheetListView(selectedTimesheetId: $selectedTimesheetId)
        case .clients, .dashboard, .parametres, .none:
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
                TimesheetEditorView(timesheet: ts)
            } else {
                ContentUnavailableView(
                    L10n.noPeriodSelected(lang),
                    systemImage: "clock",
                    description: Text(L10n.selectPeriodHint(lang))
                )
            }
        case .clients:
            ClientListView { document in
                selectedSection = document.type == .facture ? .factures : .devis
                selectedDocumentId = document.id
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
}
