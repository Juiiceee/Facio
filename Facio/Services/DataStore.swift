import Foundation
import Observation

@Observable
@MainActor
final class DataStore: Sendable {
    var documents: [Document] = []
    var clients: [ClientInfo] = []
    var companyInfo: CompanyInfo = CompanyInfo()
    var timesheets: [TimesheetPeriod] = []

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

    init() {
        ensureStorageDirectory()
        load()
    }

    private func ensureStorageDirectory() {
        if !fileManager.fileExists(atPath: storageDirectory.path) {
            try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Load

    func load() {
        if let data = try? Data(contentsOf: documentsFileURL) {
            documents = (try? decoder.decode([Document].self, from: data)) ?? []
        }
        if let data = try? Data(contentsOf: clientsFileURL) {
            clients = (try? decoder.decode([ClientInfo].self, from: data)) ?? []
        }
        if let data = try? Data(contentsOf: companyFileURL) {
            companyInfo = (try? decoder.decode(CompanyInfo.self, from: data)) ?? CompanyInfo()
        }
        if let data = try? Data(contentsOf: timesheetsFileURL) {
            timesheets = (try? decoder.decode([TimesheetPeriod].self, from: data)) ?? []
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
        ensureStorageDirectory()
        if let data = try? encoder.encode(documents) {
            try? data.write(to: documentsFileURL, options: .atomic)
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: documentsFileURL.path)
        }
        syncService?.markDirty("documents")
    }

    func saveClients() {
        ensureStorageDirectory()
        if let data = try? encoder.encode(clients) {
            try? data.write(to: clientsFileURL, options: .atomic)
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: clientsFileURL.path)
        }
        syncService?.markDirty("clients")
    }

    func saveCompany() {
        ensureStorageDirectory()
        if let data = try? encoder.encode(companyInfo) {
            try? data.write(to: companyFileURL, options: .atomic)
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: companyFileURL.path)
        }
        syncService?.markDirty("company")
    }

    func saveTimesheets() {
        ensureStorageDirectory()
        if let data = try? encoder.encode(timesheets) {
            try? data.write(to: timesheetsFileURL, options: .atomic)
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: timesheetsFileURL.path)
        }
        syncService?.markDirty("timesheets")
    }

    /// Sauvegarde locale uniquement (sans trigger sync — utilise par SyncService apres pull)
    func saveLocal(key: String) {
        ensureStorageDirectory()
        switch key {
        case "documents":
            if let data = try? encoder.encode(documents) {
                try? data.write(to: documentsFileURL, options: .atomic)
                try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: documentsFileURL.path)
            }
        case "clients":
            if let data = try? encoder.encode(clients) {
                try? data.write(to: clientsFileURL, options: .atomic)
                try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: clientsFileURL.path)
            }
        case "company":
            if let data = try? encoder.encode(companyInfo) {
                try? data.write(to: companyFileURL, options: .atomic)
                try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: companyFileURL.path)
            }
        case "timesheets":
            if let data = try? encoder.encode(timesheets) {
                try? data.write(to: timesheetsFileURL, options: .atomic)
                try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: timesheetsFileURL.path)
            }
        default: break
        }
    }

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
