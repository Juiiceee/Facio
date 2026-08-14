import SwiftUI

private struct PaletteAction: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let run: () -> Void
}

struct CommandPaletteView: View {
    @Binding var selectedSection: SidebarSection?
    @Binding var selectedDocumentId: UUID?
    @Binding var selectedTimesheetId: UUID?
    @Binding var selectedClientId: UUID?
    @Binding var selectedSettingsTab: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @Environment(AppLock.self) private var appLock

    @State private var searchText = ""
    @State private var selectedIndex = 0
    @FocusState private var searchFocused: Bool

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var currentDocument: Document? {
        guard let selectedDocumentId else { return nil }
        return dataStore.documents.first { $0.id == selectedDocumentId }
    }

    private var currentTimesheet: TimesheetPeriod? {
        guard let selectedTimesheetId else { return nil }
        return dataStore.timesheets.first { $0.id == selectedTimesheetId }
    }

    private var actions: [PaletteAction] {
        var items: [PaletteAction] = [
            PaletteAction(
                id: "new-invoice",
                title: L10n.quickCreateInvoice(lang),
                subtitle: L10n.sidebarInvoices(lang),
                systemImage: "doc.text"
            ) {
                createDocument(type: .facture)
            },
            PaletteAction(
                id: "new-quote",
                title: L10n.quickCreateQuote(lang),
                subtitle: L10n.sidebarQuotes(lang),
                systemImage: "doc.text.magnifyingglass"
            ) {
                createDocument(type: .devis)
            },
            PaletteAction(
                id: "new-client",
                title: L10n.quickCreateClient(lang),
                subtitle: L10n.sidebarClients(lang),
                systemImage: "person.crop.circle.badge.plus"
            ) {
                createClient()
            },
            PaletteAction(
                id: "open-planning",
                title: L10n.timeHubOpenPlanning(lang),
                subtitle: L10n.sidebarPlanning(lang),
                systemImage: "calendar.badge.clock"
            ) {
                goTo(.planning)
            },
            PaletteAction(
                id: "open-time-calendar",
                title: L10n.timeHubOpenCalendar(lang),
                subtitle: L10n.sidebarPlanning(lang),
                systemImage: "calendar"
            ) {
                goTo(.planning)
            },
            PaletteAction(
                id: "settings-payment",
                title: L10n.openSettingsPayment(lang),
                subtitle: L10n.settings(lang),
                systemImage: "creditcard"
            ) {
                selectedSettingsTab = 2
                goTo(.parametres)
            },
            PaletteAction(
                id: "settings-security",
                title: L10n.settingsSecurity(lang),
                subtitle: L10n.settings(lang),
                systemImage: "lock.shield"
            ) {
                selectedSettingsTab = 8
                goTo(.parametres)
            }
        ]

        if appLock.isEnabled {
            items.append(
                PaletteAction(
                    id: "lock-now",
                    title: L10n.lockNow(lang),
                    subtitle: L10n.appLockSection(lang),
                    systemImage: "lock"
                ) {
                    appLock.lockNow()
                    dismiss()
                }
            )
        }

        if let running = dataStore.runningTimeEntryContext {
            items.append(
                PaletteAction(
                    id: "stop-timer",
                    title: L10n.timeHubStopTimer(lang),
                    subtitle: running.timesheet.title(for: lang),
                    systemImage: "stop.fill"
                ) {
                    dataStore.stopTimeEntry(running.entry, in: running.timesheet)
                    dismiss()
                }
            )
        } else {
            items.append(
                PaletteAction(
                    id: "start-timer",
                    title: L10n.timeHubStartTimer(lang),
                    subtitle: L10n.sidebarPlanning(lang),
                    systemImage: "play.fill"
                ) {
                    goTo(.planning)
                }
            )
        }

        if let currentDocument {
            items.append(
                PaletteAction(
                    id: "export-current",
                    title: L10n.exportPDF(lang),
                    subtitle: currentDocument.number,
                    systemImage: "square.and.arrow.up"
                ) {
                    exportPDF(currentDocument)
                }
            )
        }

        if let currentTimesheet, let invoice = dataStore.existingBillableHoursInvoice(for: currentTimesheet) {
            items.append(
                PaletteAction(
                    id: "open-timesheet-invoice",
                    title: L10n.openInvoice(lang),
                    subtitle: invoice.number,
                    systemImage: "doc.text.magnifyingglass"
                ) {
                    openInvoice(invoice)
                }
            )
        } else if let currentTimesheet, dataStore.canGenerateInvoice(for: currentTimesheet) {
            items.append(
                PaletteAction(
                    id: "invoice-timesheet",
                    title: L10n.generateInvoice(lang),
                    subtitle: currentTimesheet.periodLabel(for: lang),
                    systemImage: "doc.text"
                ) {
                    if let invoice = dataStore.generateInvoice(from: currentTimesheet, detailMode: .summary) {
                        openInvoice(invoice)
                    } else {
                        dismiss()
                    }
                }
            )
        }

        return items
    }

    private var filteredActions: [PaletteAction] {
        guard !searchText.isEmpty else { return actions }
        return actions.filter { action in
            action.title.localizedCaseInsensitiveContains(searchText)
                || action.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredDocuments: [Document] {
        guard !searchText.isEmpty else { return [] }
        return dataStore.documents
            .filter {
                $0.number.localizedCaseInsensitiveContains(searchText)
                    || $0.clientNom.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.dateCreation > $1.dateCreation }
    }

    private var filteredClients: [ClientInfo] {
        guard !searchText.isEmpty else { return [] }
        return dataStore.clients
            .filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText)
                    || $0.email.localizedCaseInsensitiveContains(searchText)
                    || $0.siret.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.displayName < $1.displayName }
    }

    private var documentActions: [PaletteAction] {
        filteredDocuments.prefix(8).map { document in
            PaletteAction(
                id: "doc-\(document.id)",
                title: document.number,
                subtitle: document.clientNom.isEmpty ? document.type.label(for: lang) : document.clientNom,
                systemImage: document.type == .facture ? "doc.text" : "doc.text.magnifyingglass"
            ) {
                selectedSection = document.type == .facture ? .factures : .devis
                selectedDocumentId = document.id
                selectedTimesheetId = nil
                selectedClientId = nil
                dismiss()
            }
        }
    }

    private var clientActions: [PaletteAction] {
        filteredClients.prefix(8).map { client in
            PaletteAction(
                id: "cli-\(client.id)",
                title: client.displayName.isEmpty ? L10n.noClient(lang) : client.displayName,
                subtitle: client.email,
                systemImage: "person.crop.circle"
            ) {
                selectedSection = .clients
                selectedDocumentId = nil
                selectedTimesheetId = nil
                selectedClientId = client.id
                dismiss()
            }
        }
    }

    /// Tous les résultats visibles, à plat et dans l'ordre d'affichage — base de la navigation clavier.
    private var allItems: [PaletteAction] {
        filteredActions + documentActions + clientActions
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: FacioLayout.space12) {
                HStack {
                    Label(L10n.commandPaletteTitle(lang), systemImage: "command")
                        .font(FacioFont.sectionTitle)
                    Spacer()
                    Button(L10n.close(lang)) { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }

                TextField(L10n.commandPalettePlaceholder(lang), text: $searchText)
                    .focused($searchFocused)
                    .onSubmit { runSelected() }
                    .facioField()
            }
            .padding(18)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: FacioLayout.space16) {
                    actionSection
                    documentSection
                    clientSection
                }
                .padding(18)
            }
        }
        .onAppear { searchFocused = true }
        .onChange(of: searchText) { selectedIndex = 0 }
        .onKeyPress(.downArrow) { moveSelection(1); return .handled }
        .onKeyPress(.upArrow) { moveSelection(-1); return .handled }
    }

    private var actionSection: some View {
        paletteSection(title: L10n.businessActions(lang)) {
            if filteredActions.isEmpty {
                emptyRow
            } else {
                ForEach(Array(filteredActions.enumerated()), id: \.element.id) { index, action in
                    itemButton(action, globalIndex: index)
                }
            }
        }
    }

    @ViewBuilder
    private var documentSection: some View {
        if !documentActions.isEmpty {
            paletteSection(title: L10n.searchDocumentsAndClients(lang)) {
                ForEach(Array(documentActions.enumerated()), id: \.element.id) { index, action in
                    itemButton(action, globalIndex: filteredActions.count + index)
                }
            }
        }
    }

    @ViewBuilder
    private var clientSection: some View {
        if !clientActions.isEmpty {
            paletteSection(title: L10n.sidebarClients(lang)) {
                ForEach(Array(clientActions.enumerated()), id: \.element.id) { index, action in
                    itemButton(action, globalIndex: filteredActions.count + documentActions.count + index)
                }
            }
        }
    }

    private func itemButton(_ action: PaletteAction, globalIndex: Int) -> some View {
        Button {
            action.run()
        } label: {
            paletteRow(
                title: action.title,
                subtitle: action.subtitle,
                systemImage: action.systemImage,
                isSelected: globalIndex == selectedIndex
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyRow: some View {
        Text(L10n.noCommandResults(lang))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, FacioLayout.space8)
    }

    private func paletteSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FacioLayout.space8) {
            Text(title)
                .font(FacioFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
    }

    private func paletteRow(title: String, subtitle: String, systemImage: String, isSelected: Bool) -> some View {
        let accent = Color.appPrimary(from: dataStore.companyInfo)
        return HStack(spacing: FacioLayout.space12) {
            Image(systemName: systemImage)
                .foregroundStyle(accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: FacioLayout.space2) {
                Text(title)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(FacioFont.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(FacioLayout.rowPadding)
        .background(isSelected ? accent.opacity(0.16) : Color.surfaceRow)
        .overlay(
            RoundedRectangle(cornerRadius: FacioLayout.radiusRow)
                .strokeBorder(isSelected ? accent.opacity(0.5) : Color.borderHairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusRow))
        .contentShape(Rectangle())
    }

    // MARK: - Navigation clavier

    private func moveSelection(_ delta: Int) {
        let count = allItems.count
        guard count > 0 else { return }
        selectedIndex = max(0, min(count - 1, selectedIndex + delta))
    }

    private func runSelected() {
        guard allItems.indices.contains(selectedIndex) else {
            allItems.first?.run()
            return
        }
        allItems[selectedIndex].run()
    }

    // MARK: - Actions

    private func goTo(_ section: SidebarSection) {
        selectedSection = section
        selectedDocumentId = nil
        selectedTimesheetId = nil
        selectedClientId = nil
        dismiss()
    }

    private func openInvoice(_ invoice: Document) {
        selectedSection = .factures
        selectedDocumentId = invoice.id
        selectedTimesheetId = nil
        selectedClientId = nil
        dismiss()
    }

    private func createDocument(type: DocumentType) {
        let document = dataStore.createDocument(type: type)
        selectedSection = type == .facture ? .factures : .devis
        selectedDocumentId = document.id
        selectedTimesheetId = nil
        selectedClientId = nil
        dismiss()
    }

    private func createClient() {
        let client = dataStore.createClient(name: L10n.newClient(lang))
        selectedSection = .clients
        selectedDocumentId = nil
        selectedTimesheetId = nil
        selectedClientId = client.id
        dismiss()
    }

    private func exportPDF(_ document: Document) {
        let pdfData = PDFGenerator(document: document, company: dataStore.companyInfo).generate()
        Task {
            _ = await ExportService.exportPDF(data: pdfData, defaultFilename: document.number, language: lang)
        }
        dismiss()
    }
}
