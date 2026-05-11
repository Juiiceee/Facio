import Foundation

enum SyncDataKey: String, CaseIterable, Codable {
    case documents
    case clients
    case company
    case timesheets
}

struct SyncState: Codable {
    var documentsDirty: Bool = false
    var clientsDirty: Bool = false
    var companyDirty: Bool = false
    var timesheetsDirty: Bool = false
    var lastFullSyncAt: Date?
    var migrationCompleted: Bool = false

    var hasDirtyData: Bool {
        documentsDirty || clientsDirty || companyDirty || timesheetsDirty
    }

    func isDirty(_ key: SyncDataKey) -> Bool {
        switch key {
        case .documents: return documentsDirty
        case .clients: return clientsDirty
        case .company: return companyDirty
        case .timesheets: return timesheetsDirty
        }
    }

    mutating func setDirty(_ dirty: Bool, for key: SyncDataKey) {
        switch key {
        case .documents: documentsDirty = dirty
        case .clients: clientsDirty = dirty
        case .company: companyDirty = dirty
        case .timesheets: timesheetsDirty = dirty
        }
    }

    enum CodingKeys: String, CodingKey {
        case documentsDirty, clientsDirty, companyDirty, timesheetsDirty, lastFullSyncAt, migrationCompleted
    }

    init(
        documentsDirty: Bool = false,
        clientsDirty: Bool = false,
        companyDirty: Bool = false,
        timesheetsDirty: Bool = false,
        lastFullSyncAt: Date? = nil,
        migrationCompleted: Bool = false
    ) {
        self.documentsDirty = documentsDirty
        self.clientsDirty = clientsDirty
        self.companyDirty = companyDirty
        self.timesheetsDirty = timesheetsDirty
        self.lastFullSyncAt = lastFullSyncAt
        self.migrationCompleted = migrationCompleted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        documentsDirty = container.decodeOrDefault(Bool.self, forKey: .documentsDirty, default: false)
        clientsDirty = container.decodeOrDefault(Bool.self, forKey: .clientsDirty, default: false)
        companyDirty = container.decodeOrDefault(Bool.self, forKey: .companyDirty, default: false)
        timesheetsDirty = container.decodeOrDefault(Bool.self, forKey: .timesheetsDirty, default: false)
        lastFullSyncAt = try container.decodeIfPresent(Date.self, forKey: .lastFullSyncAt)
        migrationCompleted = container.decodeOrDefault(Bool.self, forKey: .migrationCompleted, default: false)
    }
}
