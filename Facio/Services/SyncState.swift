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
    var pendingDocumentDeleteIds: [String] = []
    var pendingClientDeleteIds: [String] = []
    var pendingTimesheetDeleteIds: [String] = []

    var hasDirtyData: Bool {
        isDirty(.documents) || isDirty(.clients) || isDirty(.company) || isDirty(.timesheets)
    }

    func isDirty(_ key: SyncDataKey) -> Bool {
        switch key {
        case .documents: return documentsDirty || !pendingDocumentDeleteIds.isEmpty
        case .clients: return clientsDirty || !pendingClientDeleteIds.isEmpty
        case .company: return companyDirty
        case .timesheets: return timesheetsDirty || !pendingTimesheetDeleteIds.isEmpty
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

    mutating func enqueueDelete(id: UUID, for key: SyncDataKey) {
        let value = id.uuidString
        switch key {
        case .documents:
            Self.appendUnique(value, to: &pendingDocumentDeleteIds)
        case .clients:
            Self.appendUnique(value, to: &pendingClientDeleteIds)
        case .timesheets:
            Self.appendUnique(value, to: &pendingTimesheetDeleteIds)
        case .company:
            break
        }
    }

    func pendingDeleteIds(for key: SyncDataKey) -> [String] {
        switch key {
        case .documents: return pendingDocumentDeleteIds
        case .clients: return pendingClientDeleteIds
        case .timesheets: return pendingTimesheetDeleteIds
        case .company: return []
        }
    }

    mutating func setPendingDeleteIds(_ ids: [String], for key: SyncDataKey) {
        switch key {
        case .documents:
            pendingDocumentDeleteIds = ids
        case .clients:
            pendingClientDeleteIds = ids
        case .timesheets:
            pendingTimesheetDeleteIds = ids
        case .company:
            break
        }
    }

    private static func appendUnique(_ value: String, to values: inout [String]) {
        if !values.contains(value) {
            values.append(value)
        }
    }

    enum CodingKeys: String, CodingKey {
        case documentsDirty, clientsDirty, companyDirty, timesheetsDirty, lastFullSyncAt, migrationCompleted
        case pendingDocumentDeleteIds, pendingClientDeleteIds, pendingTimesheetDeleteIds
    }

    init(
        documentsDirty: Bool = false,
        clientsDirty: Bool = false,
        companyDirty: Bool = false,
        timesheetsDirty: Bool = false,
        lastFullSyncAt: Date? = nil,
        migrationCompleted: Bool = false,
        pendingDocumentDeleteIds: [String] = [],
        pendingClientDeleteIds: [String] = [],
        pendingTimesheetDeleteIds: [String] = []
    ) {
        self.documentsDirty = documentsDirty
        self.clientsDirty = clientsDirty
        self.companyDirty = companyDirty
        self.timesheetsDirty = timesheetsDirty
        self.lastFullSyncAt = lastFullSyncAt
        self.migrationCompleted = migrationCompleted
        self.pendingDocumentDeleteIds = pendingDocumentDeleteIds
        self.pendingClientDeleteIds = pendingClientDeleteIds
        self.pendingTimesheetDeleteIds = pendingTimesheetDeleteIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        documentsDirty = try container.decodeOrDefault(Bool.self, forKey: .documentsDirty, default: false)
        clientsDirty = try container.decodeOrDefault(Bool.self, forKey: .clientsDirty, default: false)
        companyDirty = try container.decodeOrDefault(Bool.self, forKey: .companyDirty, default: false)
        timesheetsDirty = try container.decodeOrDefault(Bool.self, forKey: .timesheetsDirty, default: false)
        lastFullSyncAt = try container.decodeIfPresent(Date.self, forKey: .lastFullSyncAt)
        migrationCompleted = try container.decodeOrDefault(Bool.self, forKey: .migrationCompleted, default: false)
        pendingDocumentDeleteIds = try container.decodeOrDefault([String].self, forKey: .pendingDocumentDeleteIds, default: [])
        pendingClientDeleteIds = try container.decodeOrDefault([String].self, forKey: .pendingClientDeleteIds, default: [])
        pendingTimesheetDeleteIds = try container.decodeOrDefault([String].self, forKey: .pendingTimesheetDeleteIds, default: [])
    }
}
