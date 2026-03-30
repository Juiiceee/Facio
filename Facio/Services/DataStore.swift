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
        }
        syncService?.markDirty("documents")
    }

    func saveClients() {
        ensureStorageDirectory()
        if let data = try? encoder.encode(clients) {
            try? data.write(to: clientsFileURL, options: .atomic)
        }
        syncService?.markDirty("clients")
    }

    func saveCompany() {
        ensureStorageDirectory()
        if let data = try? encoder.encode(companyInfo) {
            try? data.write(to: companyFileURL, options: .atomic)
        }
        syncService?.markDirty("company")
    }

    func saveTimesheets() {
        ensureStorageDirectory()
        if let data = try? encoder.encode(timesheets) {
            try? data.write(to: timesheetsFileURL, options: .atomic)
        }
        syncService?.markDirty("timesheets")
    }

    /// Sauvegarde locale uniquement (sans trigger sync — utilise par SyncService apres pull)
    func saveLocal(key: String) {
        ensureStorageDirectory()
        switch key {
        case "documents":
            if let data = try? encoder.encode(documents) { try? data.write(to: documentsFileURL, options: .atomic) }
        case "clients":
            if let data = try? encoder.encode(clients) { try? data.write(to: clientsFileURL, options: .atomic) }
        case "company":
            if let data = try? encoder.encode(companyInfo) { try? data.write(to: companyFileURL, options: .atomic) }
        case "timesheets":
            if let data = try? encoder.encode(timesheets) { try? data.write(to: timesheetsFileURL, options: .atomic) }
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

    // MARK: - Company

    func companyUpdated() {
        saveCompany()
    }

    // MARK: - Reset

    func resetAll() {
        documents = []
        clients = []
        companyInfo = CompanyInfo()
        timesheets = []
        save()
    }
}
