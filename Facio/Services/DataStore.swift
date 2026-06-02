import Foundation
import Observation

struct RunningTimeEntryContext: Identifiable {
    let timesheet: TimesheetPeriod
    let entry: TimeEntry

    var id: UUID { entry.id }
}

struct TimesheetDateRangeLossSummary: Equatable {
    var dayCount: Int = 0
    var hours: Decimal = 0

    var hasLoss: Bool {
        dayCount > 0 || hours > 0
    }
}

@Observable
@MainActor
final class DataStore: Sendable {
    var documents: [Document] = []
    var clients: [ClientInfo] = []
    var companyInfo: CompanyInfo = CompanyInfo()
    var timesheets: [TimesheetPeriod] = []
    var persistenceErrors: [String: String] = [:]
    var corruptBackupURLs: [String: URL] = [:]

    /// Reference au SyncService (injectee depuis l'app)
    var syncService: SyncService?

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    private let storageDirectoryOverride: URL?

    private var storageDirectory: URL {
        if let storageDirectoryOverride {
            return storageDirectoryOverride
        }
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Facio", isDirectory: true)
    }

    private var documentsFileURL: URL { storageDirectory.appendingPathComponent("documents.json") }
    private var clientsFileURL: URL { storageDirectory.appendingPathComponent("clients.json") }
    private var companyFileURL: URL { storageDirectory.appendingPathComponent("company.json") }
    private var timesheetsFileURL: URL { storageDirectory.appendingPathComponent("timesheets.json") }
    private var writeBlockedKeys: Set<SyncDataKey> = []

    init(storageDirectory: URL? = nil) {
        self.storageDirectoryOverride = storageDirectory
        ensureStorageDirectory()
        load()
    }

    private func ensureStorageDirectory() {
        if !fileManager.fileExists(atPath: storageDirectory.path) {
            do {
                try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
                persistenceErrors.removeValue(forKey: "storage")
            } catch {
                persistenceErrors["storage"] = L10n.storageFolderCreationFailed(
                    companyInfo.langueParDefaut,
                    error: error.localizedDescription
                )
            }
        }
    }

    // MARK: - Load

    func load() {
        load([Document].self, key: .documents, from: documentsFileURL) { documents = $0 }
        load([ClientInfo].self, key: .clients, from: clientsFileURL) { clients = normalizedClients($0) }
        load(CompanyInfo.self, key: .company, from: companyFileURL) { companyInfo = $0 }
        load([TimesheetPeriod].self, key: .timesheets, from: timesheetsFileURL) { timesheets = normalizedTimesheets($0) }
    }

    private func load<T: Decodable>(_ type: T.Type, key: SyncDataKey, from url: URL, assign: (T) -> Void) {
        guard fileManager.fileExists(atPath: url.path) else {
            persistenceErrors.removeValue(forKey: key.rawValue)
            corruptBackupURLs.removeValue(forKey: key.rawValue)
            writeBlockedKeys.remove(key)
            return
        }

        do {
            let data = try Data(contentsOf: url)
            assign(try decoder.decode(type, from: data))
            persistenceErrors.removeValue(forKey: key.rawValue)
            corruptBackupURLs.removeValue(forKey: key.rawValue)
            writeBlockedKeys.remove(key)
        } catch {
            writeBlockedKeys.insert(key)
            let backupURL = backupCorruptFile(at: url, key: key.rawValue)
            corruptBackupURLs[key.rawValue] = backupURL
            let lang = companyInfo.langueParDefaut
            let backupPath = backupURL?.lastPathComponent ?? L10n.backupUnavailable(lang)
            persistenceErrors[key.rawValue] = L10n.persistenceReadFailed(
                lang,
                fileName: url.lastPathComponent,
                error: error.localizedDescription,
                backupPath: backupPath
            )
        }
    }

    // MARK: - Save (global — sauvegarde tout)

    func save() {
        saveDocuments()
        saveClients()
        saveCompany()
        saveTimesheets()
    }

    // MARK: - Save par cle (local + notify sync)

    func saveDocuments() {
        if persist(.documents, allowBlockedWrite: false) {
            syncService?.markDirty(.documents)
        }
    }

    func saveClients() {
        if persist(.clients, allowBlockedWrite: false) {
            syncService?.markDirty(.clients)
        }
    }

    func saveCompany() {
        companyInfo.normalizeBankAccountsFromLegacyFields()
        if persist(.company, allowBlockedWrite: false) {
            syncService?.markDirty(.company)
        }
    }

    func saveTimesheets() {
        if persist(.timesheets, allowBlockedWrite: false) {
            syncService?.markDirty(.timesheets)
        }
    }

    /// Sauvegarde locale uniquement (sans trigger sync — utilise par SyncService apres pull)
    @discardableResult
    func saveLocal(key: String) -> Bool {
        guard let dataKey = SyncDataKey(rawValue: key) else { return false }
        return saveLocal(dataKey)
    }

    /// Sauvegarde locale uniquement (sans trigger sync — utilise par SyncService apres pull)
    @discardableResult
    func saveLocal(_ key: SyncDataKey) -> Bool {
        persist(key, allowBlockedWrite: false)
    }

    /// Chemin explicite de recuperation apres inspection/restauration d'un fichier corrompu.
    @discardableResult
    func saveLocalAfterCorruptionRecovery(key: String) -> Bool {
        guard let dataKey = SyncDataKey(rawValue: key) else { return false }
        return persist(dataKey, allowBlockedWrite: true)
    }

    @discardableResult
    func applyPulledDocuments(_ pulledDocuments: [Document]) -> Bool {
        guard write(
            [Document].self,
            pulledDocuments,
            key: .documents,
            to: documentsFileURL,
            allowBlockedWrite: false
        ) else { return false }
        documents = pulledDocuments
        return true
    }

    @discardableResult
    func applyPulledClients(_ pulledClients: [ClientInfo]) -> Bool {
        let normalized = normalizedClients(pulledClients)
        guard write(
            [ClientInfo].self,
            normalized,
            key: .clients,
            to: clientsFileURL,
            allowBlockedWrite: false
        ) else { return false }
        clients = normalized
        return true
    }

    @discardableResult
    func applyPulledCompany(_ pulledCompany: CompanyInfo) -> Bool {
        guard write(
            CompanyInfo.self,
            pulledCompany,
            key: .company,
            to: companyFileURL,
            allowBlockedWrite: false
        ) else { return false }
        companyInfo = pulledCompany
        return true
    }

    @discardableResult
    func applyPulledTimesheets(_ pulledTimesheets: [TimesheetPeriod]) -> Bool {
        let normalized = normalizedTimesheets(pulledTimesheets)
        guard write(
            [TimesheetPeriod].self,
            normalized,
            key: .timesheets,
            to: timesheetsFileURL,
            allowBlockedWrite: false
        ) else { return false }
        timesheets = normalized
        return true
    }

    @discardableResult
    private func persist(_ key: SyncDataKey, allowBlockedWrite: Bool) -> Bool {
        switch key {
        case .documents:
            return write(
                [Document].self,
                documents,
                key: key,
                to: documentsFileURL,
                allowBlockedWrite: allowBlockedWrite
            )
        case .clients:
            return write(
                [ClientInfo].self,
                clients,
                key: key,
                to: clientsFileURL,
                allowBlockedWrite: allowBlockedWrite
            )
        case .company:
            return write(
                CompanyInfo.self,
                companyInfo,
                key: key,
                to: companyFileURL,
                allowBlockedWrite: allowBlockedWrite
            )
        case .timesheets:
            timesheets = normalizedTimesheets(timesheets)
            return write(
                [TimesheetPeriod].self,
                timesheets,
                key: key,
                to: timesheetsFileURL,
                allowBlockedWrite: allowBlockedWrite
            )
        }
    }

    private func write<T: Encodable>(
        _ type: T.Type,
        _ value: T,
        key: SyncDataKey,
        to url: URL,
        allowBlockedWrite: Bool
    ) -> Bool {
        ensureStorageDirectory()

        guard allowBlockedWrite || !writeBlockedKeys.contains(key) else {
            persistenceErrors[key.rawValue] = L10n.persistenceSaveBlocked(
                companyInfo.langueParDefaut,
                fileName: url.lastPathComponent
            )
            return false
        }

        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
            try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
            persistenceErrors.removeValue(forKey: key.rawValue)
            corruptBackupURLs.removeValue(forKey: key.rawValue)
            writeBlockedKeys.remove(key)
            return true
        } catch {
            persistenceErrors[key.rawValue] = L10n.persistenceSaveFailed(
                companyInfo.langueParDefaut,
                fileName: url.lastPathComponent,
                error: error.localizedDescription
            )
            return false
        }
    }

    private func backupCorruptFile(at url: URL, key: String) -> URL? {
        let timestamp = Self.backupTimestampFormatter.string(from: Date())
        let backupURL = url.deletingLastPathComponent()
            .appendingPathComponent("\(key).corrupt-\(timestamp).json")

        do {
            let targetURL: URL
            if fileManager.fileExists(atPath: backupURL.path) {
                targetURL = url.deletingLastPathComponent()
                    .appendingPathComponent("\(key).corrupt-\(timestamp)-\(UUID().uuidString).json")
            } else {
                targetURL = backupURL
            }
            try fileManager.copyItem(at: url, to: targetURL)
            return targetURL
        } catch {
            persistenceErrors["\(key).backup"] = L10n.persistenceBackupFailed(
                companyInfo.langueParDefaut,
                fileName: url.lastPathComponent,
                error: error.localizedDescription
            )
            return nil
        }
    }

    private static let backupTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()

    // MARK: - Document CRUD

    func addDocument(_ doc: Document) {
        documents.append(doc)
        saveDocuments()
    }

    /// Crée un document (facture/devis) pré-rempli — numérotation automatique,
    /// échéance selon le délai de paiement, devise et blockchain par défaut —,
    /// l'ajoute au store et le retourne. Source unique de la création de document.
    @discardableResult
    func createDocument(type: DocumentType) -> Document {
        let company = companyInfo
        let creationDate = Date()
        let currency = company.deviseParDefaut
        let document = Document(
            type: type,
            number: DocumentNumberService.nextNumber(
                type: type,
                existingDocuments: documents,
                language: company.langueParDefaut
            ),
            dateCreation: creationDate,
            dateEcheance: dueDate(from: creationDate),
            currency: currency,
            blockchain: defaultBlockchain(for: currency)
        )
        document.langue = company.langueParDefaut
        addDocument(document)
        return document
    }

    func deleteDocument(_ doc: Document) {
        guard documents.contains(where: { $0.id == doc.id }) else { return }
        let previousDocuments = documents
        let affectedTimesheets = timesheets.filter {
            $0.invoiceDocumentId == doc.id || doc.sourceTimesheetId == $0.id
        }
        let previousInvoiceMarkers = affectedTimesheets.map { ($0, $0.invoiceDocumentId, $0.billedAt, $0.updatedAt) }
        let affectedTimeEntries = timesheets.flatMap { timesheet in
            timesheet.timeEntries
                .filter { $0.invoiceDocumentId == doc.id }
                .map { (timesheet: timesheet, entry: $0, lineItemId: $0.invoiceLineItemId, invoicedAt: $0.invoicedAt, updatedAt: $0.updatedAt) }
        }
        documents.removeAll { $0.id == doc.id }
        for timesheet in affectedTimesheets {
            timesheet.invoiceDocumentId = nil
            timesheet.billedAt = nil
            timesheet.updatedAt = Date()
        }
        for marker in affectedTimeEntries {
            marker.entry.clearInvoiceMarkers()
            marker.timesheet.updatedAt = Date()
        }
        if persist(.documents, allowBlockedWrite: false) {
            syncService?.markDeleted(doc.id, for: .documents)
            if !affectedTimesheets.isEmpty || !affectedTimeEntries.isEmpty {
                saveTimesheets()
            }
        } else {
            documents = previousDocuments
            for (timesheet, invoiceDocumentId, billedAt, updatedAt) in previousInvoiceMarkers {
                timesheet.invoiceDocumentId = invoiceDocumentId
                timesheet.billedAt = billedAt
                timesheet.updatedAt = updatedAt
            }
            for marker in affectedTimeEntries {
                marker.entry.invoiceDocumentId = doc.id
                marker.entry.invoiceLineItemId = marker.lineItemId
                marker.entry.invoicedAt = marker.invoicedAt
                marker.entry.updatedAt = marker.updatedAt
            }
        }
    }

    func documentUpdated(_ document: Document) {
        document.updatedAt = Date()
        saveDocuments()
    }

    func documentUpdated() {
        saveDocuments()
    }

    // MARK: - Client CRUD

    func addClient(_ client: ClientInfo) {
        guard !client.isEmptyRecord else { return }
        clients.append(client)
        saveClients()
    }

    /// Crée un client portant `name`, l'ajoute au store et le retourne.
    @discardableResult
    func createClient(name: String) -> ClientInfo {
        let client = ClientInfo(nom: name)
        addClient(client)
        return client
    }

    func deleteClient(_ client: ClientInfo) {
        guard clients.contains(where: { $0.id == client.id }) else { return }
        let previousClients = clients
        clients.removeAll { $0.id == client.id }
        if persist(.clients, allowBlockedWrite: false) {
            syncService?.markDeleted(client.id, for: .clients)
        } else {
            clients = previousClients
        }
    }

    @discardableResult
    func clientUpdated(_ client: ClientInfo) -> Bool {
        client.updatedAt = Date()
        saveClients()
        return true
    }

    func clientUpdated() {
        saveClients()
    }

    // MARK: - Timesheet CRUD

    func addTimesheet(_ ts: TimesheetPeriod) {
        ts.normalizeCalendar()
        timesheets.append(ts)
        saveTimesheets()
    }

    func deleteTimesheet(_ ts: TimesheetPeriod) {
        guard timesheets.contains(where: { $0.id == ts.id }) else { return }
        let previousTimesheets = timesheets
        let previousDocuments = documents
        let now = Date()
        timesheets.removeAll { $0.id == ts.id }
        _ = syncAllSharedWeeks(updatedAt: now)
        let documentsChanged = refreshLinkedInvoices(for: timesheets, updatedAt: now)
        if persist(.timesheets, allowBlockedWrite: false) {
            syncService?.markDeleted(ts.id, for: .timesheets)
            if documentsChanged {
                saveDocuments()
            }
        } else {
            timesheets = previousTimesheets
            documents = previousDocuments
        }
    }

    func timesheetUpdated(_ timesheet: TimesheetPeriod, syncSharedWeeks shouldSyncSharedWeeks: Bool = false) {
        let now = Date()
        timesheet.updatedAt = now
        if shouldSyncSharedWeeks {
            _ = syncAllSharedWeeks(updatedAt: now)
        }
        let refreshCandidates = shouldSyncSharedWeeks ? timesheets : [timesheet]
        if refreshLinkedInvoices(for: refreshCandidates, updatedAt: now) {
            saveDocuments()
        }
        saveTimesheets()
    }

    // MARK: - Time Entry CRUD

    var runningTimeEntryContext: RunningTimeEntryContext? {
        timesheets
            .compactMap { timesheet -> RunningTimeEntryContext? in
                guard let entry = timesheet.runningTimeEntry else { return nil }
                return RunningTimeEntryContext(timesheet: timesheet, entry: entry)
            }
            .sorted { $0.entry.startedAt > $1.entry.startedAt }
            .first
    }

    var runningTimeEntry: TimeEntry? {
        runningTimeEntryContext?.entry
    }

    func startTimeEntry(
        in timesheet: TimesheetPeriod,
        projectName: String,
        taskName: String,
        notes: String,
        tagsText: String = "",
        isBillable: Bool = true,
        at startDate: Date = Date()
    ) -> TimeEntry? {
        guard timesheet.isBillableDateString(TimeEntry.dateString(for: startDate)) else { return nil }
        guard runningTimeEntryContext == nil else { return nil }

        let trimmedProject = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = TimeEntry(
            projectName: trimmedProject.isEmpty ? timesheet.clientDisplayName : trimmedProject,
            taskName: taskName,
            notes: notes,
            tagsText: tagsText,
            isBillable: isBillable,
            rateSnapshot: isBillable ? timesheet.tauxNormal : nil,
            currencySnapshot: isBillable ? companyInfo.deviseParDefaut : nil,
            source: .timer,
            startedAt: startDate,
            endedAt: nil,
            createdAt: startDate,
            updatedAt: startDate
        )
        timesheet.addTimeEntry(entry)
        timesheetUpdated(timesheet)
        return entry
    }

    func continueTimeEntry(_ entry: TimeEntry, in timesheet: TimesheetPeriod, at startDate: Date = Date()) -> TimeEntry? {
        startTimeEntry(
            in: timesheet,
            projectName: entry.projectName,
            taskName: entry.taskName,
            notes: entry.notes,
            tagsText: entry.tagsText,
            isBillable: entry.isBillable,
            at: startDate
        )
    }

    func addTimeEntry(_ entry: TimeEntry, to timesheet: TimesheetPeriod) {
        entry.normalize()
        entry.applyBillingSnapshotIfNeeded(defaultRate: timesheet.tauxNormal, currency: companyInfo.deviseParDefaut)
        timesheet.addTimeEntry(entry)
        let affectedDates = Set(entry.secondsByDate(upTo: entry.endedAt ?? Date()).keys)
        timesheet.recalculateHoursFromTimeEntries(affectedDateStrings: affectedDates)
        timesheetUpdated(timesheet, syncSharedWeeks: true)
    }

    func deleteTimeEntry(_ entry: TimeEntry, from timesheet: TimesheetPeriod) {
        guard timesheet.timeEntries.contains(where: { $0.id == entry.id }) else { return }
        let affectedDates = Set(entry.secondsByDate().keys)
        entry.softDelete()
        entry.normalize()
        timesheet.recalculateHoursFromTimeEntries(affectedDateStrings: affectedDates)
        timesheetUpdated(timesheet, syncSharedWeeks: true)
    }

    func restoreTimeEntry(_ entry: TimeEntry, in timesheet: TimesheetPeriod) {
        guard timesheet.timeEntries.contains(where: { $0.id == entry.id }), entry.isDeleted else { return }
        entry.restore()
        entry.normalize()
        let affectedDates = Set(entry.secondsByDate().keys)
        timesheet.recalculateHoursFromTimeEntries(affectedDateStrings: affectedDates)
        timesheetUpdated(timesheet, syncSharedWeeks: true)
    }

    func timeEntryUpdated(
        _ entry: TimeEntry,
        in timesheet: TimesheetPeriod,
        previousAffectedDateStrings: Set<String> = []
    ) {
        entry.normalize()
        entry.applyBillingSnapshotIfNeeded(defaultRate: timesheet.tauxNormal, currency: companyInfo.deviseParDefaut)
        entry.updatedAt = Date()
        let affectedDates = previousAffectedDateStrings.union(Set(entry.secondsByDate().keys))
        timesheet.recalculateHoursFromTimeEntries(affectedDateStrings: affectedDates)
        timesheetUpdated(timesheet, syncSharedWeeks: true)
    }

    func updateRunningTimeEntryStart(_ entry: TimeEntry, in timesheet: TimesheetPeriod, startedAt: Date) {
        guard entry.isRunning else { return }
        let previousAffectedDates = Set(entry.secondsByDate().keys)
        entry.startedAt = startedAt
        timeEntryUpdated(entry, in: timesheet, previousAffectedDateStrings: previousAffectedDates)
    }

    func stopRunningTimeEntry(at endDate: Date = Date()) {
        guard let context = runningTimeEntryContext else { return }
        stopTimeEntry(context.entry, in: context.timesheet, at: endDate)
    }

    func stopTimeEntry(_ entry: TimeEntry, in timesheet: TimesheetPeriod, at endDate: Date = Date()) {
        guard entry.isRunning else { return }
        guard endDate > entry.startedAt else { return }
        let affectedDates = Set(entry.secondsByDate(upTo: endDate).keys)
        entry.stop(at: endDate)
        entry.normalize()
        timesheet.recalculateHoursFromTimeEntries(affectedDateStrings: affectedDates, referenceDate: endDate)
        timesheetUpdated(timesheet, syncSharedWeeks: true)
    }

    func importableTimeEntries(for timesheet: TimesheetPeriod) -> [TimeEntry] {
        timesheet.timeEntries
            .filter { entry in
                !entry.isDeleted
                    && !entry.isRunning
                    && entry.isBillable
                    && !entry.isInvoiced
                    && entry.endedAt != nil
                    && entry.duration() > 0
            }
            .sorted { $0.startedAt < $1.startedAt }
    }

    func canGenerateInvoiceFromTimeEntries(for timesheet: TimesheetPeriod) -> Bool {
        timesheet.hasClient
            && existingInvoice(for: timesheet) == nil
            && !importableTimeEntries(for: timesheet).isEmpty
    }

    func generateInvoiceFromUnbilledTimeEntries(
        from timesheet: TimesheetPeriod,
        grouping: TimeEntryInvoiceGrouping = .detailed
    ) -> Document? {
        generateInvoiceFromTimeEntries(
            importableTimeEntries(for: timesheet),
            from: timesheet,
            grouping: grouping
        )
    }

    func generateInvoiceFromTimeEntries(
        _ selectedEntries: [TimeEntry],
        from timesheet: TimesheetPeriod,
        grouping: TimeEntryInvoiceGrouping = .detailed
    ) -> Document? {
        guard timesheet.hasClient else { return nil }
        if let existingInvoice = existingBillableHoursInvoice(for: timesheet) {
            let now = Date()
            let markerChanges = markTimesheet(timesheet, invoicedBy: existingInvoice, at: existingInvoice.dateCreation)
            let documentsChanged = refreshLinkedInvoice(for: timesheet, updatedAt: now)
            if markerChanges.documentChanged || documentsChanged {
                saveDocuments()
            }
            if markerChanges.timesheetChanged || documentsChanged {
                saveTimesheets()
            }
            return existingInvoice
        }

        let importableEntries = importableTimeEntries(for: timesheet)
        let importableIds = Set(importableEntries.map(\.id))
        let entries = selectedEntries
            .filter { importableIds.contains($0.id) }
            .sorted { $0.startedAt < $1.startedAt }
        guard !entries.isEmpty else { return nil }
        let coversAllOpenTimeEntries = entries.count == importableEntries.count

        let company = companyInfo
        let invoiceLanguage = company.langueParDefaut
        let creationDate = Date()
        let currency = entries.first?.currencySnapshot ?? company.deviseParDefaut
        let number = DocumentNumberService.nextNumber(
            type: .facture,
            existingDocuments: documents,
            language: invoiceLanguage
        )
        let document = Document(
            type: .facture,
            number: number,
            dateCreation: creationDate,
            dateEcheance: dueDate(from: creationDate),
            currency: currency,
            blockchain: defaultBlockchain(for: currency)
        )
        document.langue = invoiceLanguage
        timesheet.applyClient(to: document)
        if coversAllOpenTimeEntries {
            document.sourceTimesheetId = timesheet.id
        }

        let generated = timeEntryInvoiceLineItems(for: entries, timesheet: timesheet, grouping: grouping)
        guard !generated.isEmpty else { return nil }
        document.lignes = generated.map(\.line)

        addDocument(document)

        for item in generated {
            for entry in item.entries {
                entry.markInvoiced(documentId: document.id, lineItemId: item.line.id, at: creationDate)
            }
        }
        if coversAllOpenTimeEntries {
            let markerChanges = markTimesheet(timesheet, invoicedBy: document, at: creationDate)
            if markerChanges.documentChanged {
                saveDocuments()
            }
        } else {
            timesheet.updatedAt = creationDate
        }
        saveTimesheets()
        return document
    }

    func timesheetExists(mois: Int, annee: Int, clientId: UUID?, excluding excludedId: UUID? = nil) -> Bool {
        TimesheetPeriod.periodExists(
            in: timesheets,
            mois: mois,
            annee: annee,
            clientId: clientId,
            excluding: excludedId
        )
    }

    func timesheetOverlaps(startDate: Date, endDate: Date, clientId: UUID?, excluding excludedId: UUID? = nil) -> Bool {
        TimesheetPeriod.periodOverlaps(
            in: timesheets,
            startDate: startDate,
            endDate: endDate,
            clientId: clientId,
            excluding: excludedId
        )
    }

    func timesheetOverlaps(_ timesheet: TimesheetPeriod, clientId: UUID?, excluding excludedId: UUID? = nil) -> Bool {
        TimesheetPeriod.periodOverlaps(
            in: timesheets,
            startDateString: timesheet.activeStartDateString,
            endDateString: timesheet.activeEndDateString,
            clientId: clientId,
            excluding: excludedId
        )
    }

    func timesheetDateRangeLoss(
        for timesheet: TimesheetPeriod,
        startDate: Date,
        endDate: Date
    ) -> TimesheetDateRangeLossSummary {
        let range = TimesheetPeriod.normalizedDateRange(startDate: startDate, endDate: endDate)
        var summary = TimesheetDateRangeLossSummary()

        for week in timesheet.semaines {
            for day in week.jours where day.heures > 0 {
                guard timesheet.isBillableDay(day) else { continue }
                guard day.dateString < range.start || day.dateString > range.end else { continue }
                summary.dayCount += 1
                summary.hours += day.heures
            }
        }

        return summary
    }

    func updateTimesheetDateRange(
        _ timesheet: TimesheetPeriod,
        startDate: Date,
        endDate: Date
    ) {
        let range = TimesheetPeriod.normalizedDateRange(startDate: startDate, endDate: endDate)
        let calendar = Calendar(identifier: .gregorian)
        timesheet.customStartDateString = range.start
        timesheet.customEndDateString = range.end
        timesheet.mois = calendar.component(.month, from: range.startDate)
        timesheet.annee = calendar.component(.year, from: range.startDate)
        timesheet.nom = timesheet.periodLabel(for: .fr)

        _ = timesheet.normalizeCalendar()
        clearHoursOutsideActiveRange(for: timesheet)
        timesheetUpdated(timesheet, syncSharedWeeks: true)
    }

    private func clearHoursOutsideActiveRange(for timesheet: TimesheetPeriod) {
        for weekIndex in timesheet.semaines.indices {
            for dayIndex in timesheet.semaines[weekIndex].jours.indices {
                let day = timesheet.semaines[weekIndex].jours[dayIndex]
                if !timesheet.isBillableDateString(day.dateString), day.heures != 0 {
                    timesheet.semaines[weekIndex].jours[dayIndex].heures = 0
                }
            }
        }
    }

    func canGenerateInvoice(for timesheet: TimesheetPeriod) -> Bool {
        guard timesheet.hasClient else { return false }
        guard !timesheet.hasGeneratedInvoice, existingBillableHoursInvoice(for: timesheet) == nil else { return false }
        return !invoiceLineItems(for: timesheet, detailMode: .summary).isEmpty
    }

    func generateInvoice(
        from timesheet: TimesheetPeriod,
        detailMode: TimesheetInvoiceDetailMode
    ) -> Document? {
        if let existingInvoice = existingBillableHoursInvoice(for: timesheet) {
            let now = Date()
            let markerChanges = markTimesheet(timesheet, invoicedBy: existingInvoice, at: existingInvoice.dateCreation)
            let documentsChanged = refreshLinkedInvoice(for: timesheet, updatedAt: now)
            if markerChanges.documentChanged || documentsChanged {
                saveDocuments()
            }
            if markerChanges.timesheetChanged || documentsChanged {
                saveTimesheets()
            }
            return existingInvoice
        }
        guard timesheet.hasClient else { return nil }

        let company = companyInfo
        let invoiceLanguage = company.langueParDefaut
        let lineItems = invoiceLineItems(for: timesheet, detailMode: detailMode)
        guard !lineItems.isEmpty else { return nil }

        let creationDate = Date()
        let currency = company.deviseParDefaut
        let number = DocumentNumberService.nextNumber(
            type: .facture,
            existingDocuments: documents,
            language: invoiceLanguage
        )
        let document = Document(
            type: .facture,
            number: number,
            dateCreation: creationDate,
            dateEcheance: dueDate(from: creationDate),
            currency: currency,
            blockchain: defaultBlockchain(for: currency)
        )
        document.langue = invoiceLanguage
        document.sourceTimesheetId = timesheet.id
        timesheet.applyClient(to: document)
        document.lignes = lineItems
        document.timesheetAutoSyncSignature = timesheetAutoSyncSignature(for: document)
        timesheet.invoiceDetailMode = detailMode

        addDocument(document)
        let markerChanges = markTimesheet(timesheet, invoicedBy: document, at: creationDate)
        let entriesChanged = markTimeEntriesCoveredByPeriodInvoice(timesheet, document: document, at: creationDate)
        if markerChanges.timesheetChanged || entriesChanged {
            saveTimesheets()
        }
        return document
    }

    func existingInvoice(for timesheet: TimesheetPeriod) -> Document? {
        if let invoiceDocumentId = timesheet.invoiceDocumentId,
           let document = documents.first(where: { $0.id == invoiceDocumentId && $0.type == .facture }) {
            return document
        }
        return documents.first { $0.type == .facture && $0.sourceTimesheetId == timesheet.id }
    }

    func existingBillableHoursInvoice(for timesheet: TimesheetPeriod) -> Document? {
        existingInvoice(for: timesheet) ?? existingTimeEntryInvoice(for: timesheet)
    }

    private func existingTimeEntryInvoice(for timesheet: TimesheetPeriod) -> Document? {
        guard importableTimeEntries(for: timesheet).isEmpty else { return nil }
        let invoiceIds = Set(timesheet.timeEntries.compactMap { entry -> UUID? in
            guard !entry.isDeleted,
                  entry.isBillable,
                  entry.isInvoiced,
                  timesheet.isBillableDateString(entry.dateString) else {
                return nil
            }
            return entry.invoiceDocumentId
        })
        guard invoiceIds.count == 1, let invoiceId = invoiceIds.first else { return nil }
        return documents.first { $0.id == invoiceId && $0.type == .facture }
    }

    func invoiceLineItems(
        for timesheet: TimesheetPeriod,
        detailMode: TimesheetInvoiceDetailMode
    ) -> [LineItem] {
        TimesheetInvoiceService.lineItems(
            for: timesheet,
            company: companyInfo,
            invoiceLanguage: companyInfo.langueParDefaut,
            detailMode: detailMode,
            adjacentHours: adjacentHours(for: timesheet)
        )
    }

    private func markTimesheet(
        _ timesheet: TimesheetPeriod,
        invoicedBy document: Document,
        at date: Date
    ) -> (timesheetChanged: Bool, documentChanged: Bool) {
        var timesheetChanged = false
        if timesheet.invoiceDocumentId != document.id {
            timesheet.invoiceDocumentId = document.id
            timesheetChanged = true
        }
        if timesheet.billedAt == nil {
            timesheet.billedAt = date
            timesheetChanged = true
        }
        if timesheetChanged {
            timesheet.updatedAt = date
        }

        var documentChanged = false
        if document.sourceTimesheetId != timesheet.id {
            document.sourceTimesheetId = timesheet.id
            document.updatedAt = date
            documentChanged = true
        }
        return (timesheetChanged, documentChanged)
    }

    @discardableResult
    private func refreshLinkedInvoices(for periods: [TimesheetPeriod], updatedAt now: Date) -> Bool {
        periods.reduce(false) { didChange, period in
            refreshLinkedInvoice(for: period, updatedAt: now) || didChange
        }
    }

    @discardableResult
    private func refreshLinkedInvoice(for timesheet: TimesheetPeriod, updatedAt now: Date) -> Bool {
        guard let invoice = existingInvoice(for: timesheet) else { return false }

        let generatedLineItems = TimesheetInvoiceService.lineItems(
            for: timesheet,
            company: companyInfo,
            invoiceLanguage: invoice.langue,
            detailMode: timesheet.invoiceDetailMode,
            adjacentHours: adjacentHours(for: timesheet)
        )
        let refreshedLineItems = preservingLineItemIds(generatedLineItems, from: invoice.lignes)

        var changed = false

        if invoice.sourceTimesheetId != timesheet.id {
            invoice.sourceTimesheetId = timesheet.id
            changed = true
        }

        guard invoice.status == .brouillon else {
            if changed {
                invoice.updatedAt = now
            }
            return changed
        }

        if invoice.timesheetAutoSyncSignature == nil {
            if lineItemsMatch(invoice.lignes, refreshedLineItems), !invoiceClientSnapshotDiffers(from: timesheet) {
                invoice.timesheetAutoSyncSignature = timesheetAutoSyncSignature(for: invoice)
                changed = true
            } else {
                if changed {
                    invoice.updatedAt = now
                }
                return changed
            }
        }

        guard invoice.timesheetAutoSyncSignature == timesheetAutoSyncSignature(for: invoice) else {
            if changed {
                invoice.updatedAt = now
            }
            return changed
        }

        if !lineItemsMatch(invoice.lignes, refreshedLineItems) {
            invoice.lignes = refreshedLineItems
            changed = true
        }

        if invoiceClientSnapshotDiffers(from: timesheet) {
            timesheet.applyClient(to: invoice)
            changed = true
        }

        let refreshedSignature = timesheetAutoSyncSignature(for: invoice)
        if invoice.timesheetAutoSyncSignature != refreshedSignature {
            invoice.timesheetAutoSyncSignature = refreshedSignature
            changed = true
        }

        if changed {
            _ = markTimeEntriesCoveredByPeriodInvoice(timesheet, document: invoice, at: now)
            invoice.updatedAt = now
        }
        return changed
    }

    private func preservingLineItemIds(_ newItems: [LineItem], from existingItems: [LineItem]) -> [LineItem] {
        var items = newItems
        let existingSorted = existingItems.sorted { $0.ordre < $1.ordre }
        for index in items.indices where index < existingSorted.count {
            items[index].id = existingSorted[index].id
        }
        return items
    }

    private func lineItemsMatch(_ lhs: [LineItem], _ rhs: [LineItem]) -> Bool {
        let lhsSorted = lhs.sorted { $0.ordre < $1.ordre }
        let rhsSorted = rhs.sorted { $0.ordre < $1.ordre }
        guard lhsSorted.count == rhsSorted.count else { return false }

        for (left, right) in zip(lhsSorted, rhsSorted) {
            if left.id != right.id
                || left.designation != right.designation
                || left.quantite != right.quantite
                || left.prixUnitaire != right.prixUnitaire
                || left.tauxTVA != right.tauxTVA
                || left.ordre != right.ordre {
                return false
            }
        }
        return true
    }

    private func timesheetAutoSyncSignature(for document: Document) -> String {
        var parts: [String] = [
            "client",
            document.clientNom,
            document.clientAdresse,
            document.clientCodePostal,
            document.clientVille,
            document.clientSiret,
            document.clientTva,
            document.clientApe,
            "lines",
            String(document.lignes.count)
        ]

        for line in document.lignes.sorted(by: { $0.ordre < $1.ordre }) {
            parts.append(contentsOf: [
                line.id.uuidString,
                line.designation,
                decimalSignature(line.quantite),
                decimalSignature(line.prixUnitaire),
                decimalSignature(line.tauxTVA),
                String(line.ordre)
            ])
        }

        return parts.map(signaturePart).joined()
    }

    private func signaturePart(_ value: String) -> String {
        "\(value.count):\(value)"
    }

    private func decimalSignature(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }

    @discardableResult
    private func markTimeEntriesCoveredByPeriodInvoice(
        _ timesheet: TimesheetPeriod,
        document: Document,
        at date: Date
    ) -> Bool {
        var changed = false
        for entry in timesheet.timeEntries where shouldMarkTimeEntryInvoicedByPeriod(entry, in: timesheet) {
            entry.markInvoiced(documentId: document.id, lineItemId: nil, at: date)
            changed = true
        }
        if changed {
            timesheet.updatedAt = date
        }
        return changed
    }

    private func shouldMarkTimeEntryInvoicedByPeriod(_ entry: TimeEntry, in timesheet: TimesheetPeriod) -> Bool {
        !entry.isDeleted
            && !entry.isRunning
            && entry.isBillable
            && !entry.isInvoiced
            && entry.endedAt != nil
            && timesheet.isBillableDateString(entry.dateString)
            && entry.duration() > 0
    }

    private func timeEntryInvoiceLineItems(
        for entries: [TimeEntry],
        timesheet: TimesheetPeriod,
        grouping: TimeEntryInvoiceGrouping
    ) -> [(line: LineItem, entries: [TimeEntry])] {
        switch grouping {
        case .detailed:
            return entries.enumerated().map { index, entry in
                (
                    line: LineItem(
                        designation: timeEntryDetailedInvoiceLabel(entry, lang: companyInfo.langueParDefaut),
                        quantite: entryBillableHours(entry),
                        prixUnitaire: entry.rateSnapshot ?? timesheet.tauxNormal,
                        tauxTVA: 0,
                        ordre: index
                    ),
                    entries: [entry]
                )
            }

        case .byProject:
            let grouped = Dictionary(grouping: entries) { entry in
                let project = entry.displayProject.isEmpty ? timesheet.clientDisplayName : entry.displayProject
                let rate = entry.rateSnapshot ?? timesheet.tauxNormal
                return "\(project)|\(rate.description)"
            }
            return grouped
                .sorted { $0.key < $1.key }
                .enumerated()
                .map { index, group in
                    let groupEntries = group.value.sorted { $0.startedAt < $1.startedAt }
                    let first = groupEntries[0]
                    let project = first.displayProject.isEmpty ? timesheet.clientDisplayName : first.displayProject
                    let hours = groupEntries.reduce(Decimal(0)) { $0 + entryBillableHours($1) }
                    return (
                        line: LineItem(
                            designation: project.isEmpty ? L10n.workHours(companyInfo.langueParDefaut) : project,
                            quantite: hours,
                            prixUnitaire: first.rateSnapshot ?? timesheet.tauxNormal,
                            tauxTVA: 0,
                            ordre: index
                        ),
                        entries: groupEntries
                    )
                }

        case .singleLine:
            let hours = entries.reduce(Decimal(0)) { $0 + entryBillableHours($1) }
            let rate = entries.first?.rateSnapshot ?? timesheet.tauxNormal
            return [(
                line: LineItem(
                    designation: L10n.workHoursForPeriod(companyInfo.langueParDefaut, period: timesheet.periodLabel(for: companyInfo.langueParDefaut)),
                    quantite: hours,
                    prixUnitaire: rate,
                    tauxTVA: 0,
                    ordre: 0
                ),
                entries: entries
            )]
        }
    }

    private func timeEntryDetailedInvoiceLabel(_ entry: TimeEntry, lang: AppLanguage) -> String {
        let title = [entry.notes, entry.displayProject, entry.displayTask]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " - ")
        let duration = entry.durationHours().formattedDecimal(maxFractionDigits: 2, for: lang)
        let detail = title.isEmpty ? L10n.workHours(lang) : title
        return "\(entry.dateString) - \(detail) - \(duration)h"
    }

    private func entryBillableHours(_ entry: TimeEntry) -> Decimal {
        Decimal(entry.duration() / 3600)
    }

    private func invoiceClientSnapshotDiffers(from timesheet: TimesheetPeriod) -> Bool {
        guard let invoice = existingInvoice(for: timesheet) else { return false }
        return invoice.clientNom != timesheet.clientNom
            || invoice.clientAdresse != timesheet.clientAdresse
            || invoice.clientCodePostal != timesheet.clientCodePostal
            || invoice.clientVille != timesheet.clientVille
            || invoice.clientSiret != timesheet.clientSiret
            || invoice.clientTva != timesheet.clientTva
            || invoice.clientApe != timesheet.clientApe
    }

    private func dueDate(from creationDate: Date) -> Date {
        Calendar.current.date(
            byAdding: .day,
            value: companyInfo.delaiPaiementJours,
            to: creationDate
        ) ?? creationDate
    }

    private func defaultBlockchain(for currency: CurrencyType) -> Blockchain? {
        guard currency.requiresBlockchain else { return nil }
        let compatible = Blockchain.compatibleBlockchains(for: currency)
        guard !compatible.isEmpty else { return nil }
        if let defaultBlockchain = companyInfo.blockchainParDefaut,
           compatible.contains(defaultBlockchain) {
            return defaultBlockchain
        }
        return compatible.first
    }

    private func normalizedTimesheets(_ periods: [TimesheetPeriod]) -> [TimesheetPeriod] {
        for period in periods {
            period.normalizeCalendar()
        }
        return periods
    }

    private func normalizedClients(_ clients: [ClientInfo]) -> [ClientInfo] {
        clients
    }

    // MARK: - Cross-period sync

    /// Synchronise les jours partagés entre périodes adjacentes.
    /// Pour chaque jour hors-mois dans la période, tire les heures depuis la période adjacente.
    /// Pour chaque jour du mois courant dans une semaine partagée, pousse les heures vers la période adjacente.
    func syncSharedWeeks(for period: TimesheetPeriod) {
        let now = Date()
        let didSync = syncSharedWeeks(for: period, updatedAt: now)
        let documentsChanged = refreshLinkedInvoices(for: timesheets, updatedAt: now)
        if documentsChanged {
            saveDocuments()
        }
        if didSync {
            saveTimesheets()
        }
    }

    @discardableResult
    private func syncAllSharedWeeks(updatedAt now: Date) -> Bool {
        timesheets.reduce(false) { didChange, period in
            syncSharedWeeks(for: period, updatedAt: now) || didChange
        }
    }

    @discardableResult
    private func syncSharedWeeks(for period: TimesheetPeriod, updatedAt now: Date) -> Bool {
        var didChange = false

        for wi in period.semaines.indices {
            let week = period.semaines[wi]
            let hasContextDays = week.jours.contains { !period.isBillableDay($0) }
            guard hasContextDays else { continue }

            for ji in week.jours.indices {
                let jour = week.jours[ji]

                if period.isBillableDay(jour) {
                    // Jour facture dans cette periode -> pousser vers les autres periodes qui affichent ce jour en contexte.
                    for adj in timesheets where adj.id != period.id && period.hasSameClientScope(as: adj) {
                        for awi in adj.semaines.indices {
                            for aji in adj.semaines[awi].jours.indices {
                                if adj.semaines[awi].jours[aji].dateString == jour.dateString
                                    && adj.semaines[awi].jours[aji].heures != jour.heures {
                                    adj.semaines[awi].jours[aji].heures = jour.heures
                                    adj.updatedAt = now
                                    didChange = true
                                }
                            }
                        }
                    }
                } else {
                    // Jour hors plage -> tirer depuis la periode qui facture cette date.
                    if let adj = timesheets.first(where: {
                        $0.id != period.id
                            && $0.isBillableDateString(jour.dateString)
                            && period.hasSameClientScope(as: $0)
                    }) {
                        for aw in adj.semaines {
                            if let day = aw.jours.first(where: { $0.dateString == jour.dateString }) {
                                if period.semaines[wi].jours[ji].heures != day.heures {
                                    period.semaines[wi].jours[ji].heures = day.heures
                                    period.updatedAt = now
                                    didChange = true
                                }
                            }
                        }
                    } else if period.semaines[wi].jours[ji].heures != 0 {
                        period.semaines[wi].jours[ji].heures = 0
                        period.updatedAt = now
                        didChange = true
                    }
                }
            }
        }

        return didChange
    }

    /// Retourne les heures des jours hors-mois depuis les périodes adjacentes.
    /// Clé = dateString, Valeur = heures de la période qui possède ce jour.
    func adjacentHours(for period: TimesheetPeriod) -> [String: Decimal] {
        var result: [String: Decimal] = [:]

        for week in period.semaines {
            for jour in week.jours where !period.isBillableDay(jour) {
                if let adj = timesheets.first(where: {
                    $0.id != period.id
                        && $0.isBillableDateString(jour.dateString)
                        && period.hasSameClientScope(as: $0)
                }) {
                    for w in adj.semaines {
                        if let d = w.jours.first(where: { $0.dateString == jour.dateString }) {
                            result[jour.dateString] = d.heures
                        }
                    }
                }
            }
        }

        return result
    }

    // MARK: - Company

    func companyUpdated() {
        companyInfo.updatedAt = Date()
        saveCompany()
    }

    // MARK: - Reset

    func resetAll() {
        // Detach sync to avoid marking empty data as dirty
        // (which would delete all remote data on next sync)
        let sync = syncService
        syncService = nil

        documents = []
        clients = []
        companyInfo = CompanyInfo()
        timesheets = []
        save()

        // Reset sync state so nothing is dirty after reset
        sync?.resetSyncState()
        syncService = sync
    }
}
