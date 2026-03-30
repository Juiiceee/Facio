import Foundation
import Observation

@Observable
final class DataStore {
    var documents: [Document] = []
    var clients: [ClientInfo] = []
    var companyInfo: CompanyInfo = CompanyInfo()
    var timesheets: [TimesheetPeriod] = []

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

    private var documentsFileURL: URL {
        storageDirectory.appendingPathComponent("documents.json")
    }

    private var clientsFileURL: URL {
        storageDirectory.appendingPathComponent("clients.json")
    }

    private var companyFileURL: URL {
        storageDirectory.appendingPathComponent("company.json")
    }

    private var timesheetsFileURL: URL {
        storageDirectory.appendingPathComponent("timesheets.json")
    }

    init() {
        ensureStorageDirectory()
        load()
    }

    // MARK: - Directory

    private func ensureStorageDirectory() {
        if !fileManager.fileExists(atPath: storageDirectory.path) {
            try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Load

    func load() {
        // Documents
        if let data = try? Data(contentsOf: documentsFileURL) {
            documents = (try? decoder.decode([Document].self, from: data)) ?? []
        }

        // Clients
        if let data = try? Data(contentsOf: clientsFileURL) {
            clients = (try? decoder.decode([ClientInfo].self, from: data)) ?? []
        }

        // Company
        if let data = try? Data(contentsOf: companyFileURL) {
            companyInfo = (try? decoder.decode(CompanyInfo.self, from: data)) ?? CompanyInfo()
        }

        // Timesheets
        if let data = try? Data(contentsOf: timesheetsFileURL) {
            timesheets = (try? decoder.decode([TimesheetPeriod].self, from: data)) ?? []
        }
    }

    // MARK: - Save

    func save() {
        ensureStorageDirectory()

        // Documents
        if let data = try? encoder.encode(documents) {
            try? data.write(to: documentsFileURL, options: .atomic)
        }

        // Clients
        if let data = try? encoder.encode(clients) {
            try? data.write(to: clientsFileURL, options: .atomic)
        }

        // Company
        if let data = try? encoder.encode(companyInfo) {
            try? data.write(to: companyFileURL, options: .atomic)
        }

        // Timesheets
        if let data = try? encoder.encode(timesheets) {
            try? data.write(to: timesheetsFileURL, options: .atomic)
        }
    }

    // MARK: - Document CRUD

    func addDocument(_ doc: Document) {
        documents.append(doc)
        save()
    }

    func deleteDocument(_ doc: Document) {
        documents.removeAll { $0.id == doc.id }
        save()
    }

    /// Call after modifying a document's properties to persist changes
    func documentUpdated() {
        save()
    }

    // MARK: - Client CRUD

    func addClient(_ client: ClientInfo) {
        clients.append(client)
        save()
    }

    func deleteClient(_ client: ClientInfo) {
        clients.removeAll { $0.id == client.id }
        save()
    }

    /// Call after modifying a client's properties to persist changes
    func clientUpdated() {
        save()
    }

    // MARK: - Timesheet CRUD

    func addTimesheet(_ ts: TimesheetPeriod) {
        timesheets.append(ts)
        save()
    }

    func deleteTimesheet(_ ts: TimesheetPeriod) {
        timesheets.removeAll { $0.id == ts.id }
        save()
    }

    // MARK: - Company

    /// Call after modifying company info to persist changes
    func companyUpdated() {
        save()
    }
}
