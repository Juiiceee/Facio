import SwiftUI

struct ContentView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var selectedSection: SidebarSection? = .factures
    @State private var selectedDocumentId: UUID?
    @State private var selectedTimesheetId: UUID?

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var selectedDocument: Document? {
        guard let id = selectedDocumentId else { return nil }
        return dataStore.documents.first { $0.id == id }
    }

    private var selectedTimesheet: TimesheetPeriod? {
        guard let id = selectedTimesheetId else { return nil }
        return dataStore.timesheets.first { $0.id == id }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedSection)
        } content: {
            contentForSection
                .navigationSplitViewColumnWidth(min: 300, ideal: 320, max: 400)
        } detail: {
            detailForSection
                .frame(minWidth: 500)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 600)
        .onChange(of: selectedSection) {
            selectedDocumentId = nil
            selectedTimesheetId = nil
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
            ClientListView()
        case .dashboard:
            DashboardView { document in
                selectedSection = document.type == .facture ? .factures : .devis
                selectedDocumentId = document.id
            }
        case .parametres:
            SettingsInlineView()
        case .none:
            Text(L10n.selectSection(lang))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
