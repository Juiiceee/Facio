import Foundation
import Observation

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

    private var storageDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Facio", isDirectory: true)
    }

    private var documentsFileURL: URL { storageDirectory.appendingPathComponent("documents.json") }
    private var clientsFileURL: URL { storageDirectory.appendingPathComponent("clients.json") }
    private var companyFileURL: URL { storageDirectory.appendingPathComponent("company.json") }
    private var timesheetsFileURL: URL { storageDirectory.appendingPathComponent("timesheets.json") }
    private var writeBlockedKeys: Set<String> = []

    init() {
        ensureStorageDirectory()
        load()
    }

    private func ensureStorageDirectory() {
        if !fileManager.fileExists(atPath: storageDirectory.path) {
            do {
                try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
                persistenceErrors.removeValue(forKey: "storage")
            } catch {
                persistenceErrors["storage"] = "Impossible de creer le dossier de stockage: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Load

    func load() {
        load([Document].self, key: "documents", from: documentsFileURL) { documents = $0 }
        load([ClientInfo].self, key: "clients", from: clientsFileURL) { clients = $0 }
        load(CompanyInfo.self, key: "company", from: companyFileURL) { companyInfo = $0 }
        load([TimesheetPeriod].self, key: "timesheets", from: timesheetsFileURL) { timesheets = $0 }
    }

    private func load<T: Decodable>(_ type: T.Type, key: String, from url: URL, assign: (T) -> Void) {
        guard fileManager.fileExists(atPath: url.path) else {
            persistenceErrors.removeValue(forKey: key)
            corruptBackupURLs.removeValue(forKey: key)
            writeBlockedKeys.remove(key)
            return
        }

        do {
            let data = try Data(contentsOf: url)
            assign(try decoder.decode(type, from: data))
            persistenceErrors.removeValue(forKey: key)
            corruptBackupURLs.removeValue(forKey: key)
            writeBlockedKeys.remove(key)
        } catch {
            writeBlockedKeys.insert(key)
            let backupURL = backupCorruptFile(at: url, key: key)
            corruptBackupURLs[key] = backupURL
            let backupPath = backupURL?.lastPathComponent ?? "backup indisponible"
            persistenceErrors[key] = "Lecture impossible de \(url.lastPathComponent): \(error.localizedDescription). Fichier preserve: \(backupPath)"
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
        if write([Document].self, documents, key: "documents", to: documentsFileURL, allowBlockedWrite: false) {
            syncService?.markDirty("documents")
        }
    }

    func saveClients() {
        if write([ClientInfo].self, clients, key: "clients", to: clientsFileURL, allowBlockedWrite: false) {
            syncService?.markDirty("clients")
        }
    }

    func saveCompany() {
        if write(CompanyInfo.self, companyInfo, key: "company", to: companyFileURL, allowBlockedWrite: false) {
            syncService?.markDirty("company")
        }
    }

    func saveTimesheets() {
        if write([TimesheetPeriod].self, timesheets, key: "timesheets", to: timesheetsFileURL, allowBlockedWrite: false) {
            syncService?.markDirty("timesheets")
        }
    }

    /// Sauvegarde locale uniquement (sans trigger sync — utilise par SyncService apres pull)
    func saveLocal(key: String) {
        switch key {
        case "documents":
            _ = write([Document].self, documents, key: key, to: documentsFileURL, allowBlockedWrite: true)
        case "clients":
            _ = write([ClientInfo].self, clients, key: key, to: clientsFileURL, allowBlockedWrite: true)
        case "company":
            _ = write(CompanyInfo.self, companyInfo, key: key, to: companyFileURL, allowBlockedWrite: true)
        case "timesheets":
            _ = write([TimesheetPeriod].self, timesheets, key: key, to: timesheetsFileURL, allowBlockedWrite: true)
        default: break
        }
    }

    private func write<T: Encodable>(
        _ type: T.Type,
        _ value: T,
        key: String,
        to url: URL,
        allowBlockedWrite: Bool
    ) -> Bool {
        ensureStorageDirectory()

        guard allowBlockedWrite || !writeBlockedKeys.contains(key) else {
            persistenceErrors[key] = "Sauvegarde bloquee pour \(url.lastPathComponent): le fichier local n'a pas pu etre decode au chargement."
            return false
        }

        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
            try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
            persistenceErrors.removeValue(forKey: key)
            corruptBackupURLs.removeValue(forKey: key)
            writeBlockedKeys.remove(key)
            return true
        } catch {
            persistenceErrors[key] = "Sauvegarde impossible de \(url.lastPathComponent): \(error.localizedDescription)"
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
            persistenceErrors["\(key).backup"] = "Backup impossible de \(url.lastPathComponent): \(error.localizedDescription)"
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

    func deleteDocument(_ doc: Document) {
        documents.removeAll { $0.id == doc.id }
        saveDocuments()
    }

    func documentUpdated() {
        saveDocuments()
    }

    // MARK: - Client CRUD

    func addClient(_ client: ClientInfo) {
        clients.append(client)
        saveClients()
    }

    func deleteClient(_ client: ClientInfo) {
        clients.removeAll { $0.id == client.id }
        saveClients()
    }

    func clientUpdated() {
        saveClients()
    }

    // MARK: - Timesheet CRUD

    func addTimesheet(_ ts: TimesheetPeriod) {
        timesheets.append(ts)
        saveTimesheets()
    }

    func deleteTimesheet(_ ts: TimesheetPeriod) {
        timesheets.removeAll { $0.id == ts.id }
        saveTimesheets()
    }

    // MARK: - Cross-period sync

    /// Synchronise les jours partagés entre périodes adjacentes.
    /// Pour chaque jour hors-mois dans la période, tire les heures depuis la période adjacente.
    /// Pour chaque jour du mois courant dans une semaine partagée, pousse les heures vers la période adjacente.
    func syncSharedWeeks(for period: TimesheetPeriod) {
        let cal = Calendar(identifier: .gregorian)
        var didChange = false

        for wi in period.semaines.indices {
            let week = period.semaines[wi]
            // Vérifier si c'est une semaine partagée
            let hasOutOfMonthDays = week.jours.contains { $0.mois != period.mois }
            guard hasOutOfMonthDays else { continue }

            for ji in week.jours.indices {
                let jour = week.jours[ji]
                let jourMois = jour.mois
                let jourAnnee = cal.component(.year, from: jour.date)

                if jourMois == period.mois {
                    // Jour du mois courant → pousser vers les périodes adjacentes qui ont ce jour
                    for adj in timesheets where adj.id != period.id {
                        for awi in adj.semaines.indices {
                            for aji in adj.semaines[awi].jours.indices {
                                if adj.semaines[awi].jours[aji].dateString == jour.dateString
                                    && adj.semaines[awi].jours[aji].heures != jour.heures {
                                    adj.semaines[awi].jours[aji].heures = jour.heures
                                    didChange = true
                                }
                            }
                        }
                    }
                } else {
                    // Jour hors-mois → tirer depuis la période adjacente
                    if let adj = timesheets.first(where: { $0.id != period.id && $0.mois == jourMois && $0.annee == jourAnnee }) {
                        for aw in adj.semaines {
                            if let day = aw.jours.first(where: { $0.dateString == jour.dateString }) {
                                if period.semaines[wi].jours[ji].heures != day.heures {
                                    period.semaines[wi].jours[ji].heures = day.heures
                                    didChange = true
                                }
                            }
                        }
                    }
                }
            }
        }

        if didChange {
            saveTimesheets()
        }
    }

    /// Retourne les heures des jours hors-mois depuis les périodes adjacentes.
    /// Clé = dateString, Valeur = heures de la période qui possède ce jour.
    func adjacentHours(for period: TimesheetPeriod) -> [String: Decimal] {
        let cal = Calendar(identifier: .gregorian)
        var result: [String: Decimal] = [:]

        for week in period.semaines {
            for jour in week.jours where jour.mois != period.mois {
                let jourAnnee = cal.component(.year, from: jour.date)
                if let adj = timesheets.first(where: { $0.id != period.id && $0.mois == jour.mois && $0.annee == jourAnnee }) {
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
