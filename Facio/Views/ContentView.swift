import SwiftUI

struct ContentView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var selectedSection: SidebarSection? = .factures
    @State private var selectedDocumentId: UUID?
    @State private var selectedTimesheetId: UUID?

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
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } detail: {
            detailForSection
                .frame(minWidth: 600)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 1200, minHeight: 700)
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
            Text("")
                .navigationSplitViewColumnWidth(0)
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
                    "Aucun document selectionne",
                    systemImage: "doc.text",
                    description: Text("Selectionnez un document dans la liste ou creez-en un nouveau avec +")
                )
            }
        case .heures:
            if let ts = selectedTimesheet {
                TimesheetEditorView(timesheet: ts)
            } else {
                ContentUnavailableView(
                    "Aucune periode selectionnee",
                    systemImage: "clock",
                    description: Text("Selectionnez une periode ou creez-en une avec +")
                )
            }
        case .clients:
            ClientListView()
        case .dashboard:
            DashboardView()
        case .parametres:
            SettingsInlineView()
        case .none:
            Text("Selectionnez une section")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
