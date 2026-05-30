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
        let documentDeletes = container.decodeSyncStateStringArray(forKey: .pendingDocumentDeleteIds)
        let clientDeletes = container.decodeSyncStateStringArray(forKey: .pendingClientDeleteIds)
        let timesheetDeletes = container.decodeSyncStateStringArray(forKey: .pendingTimesheetDeleteIds)

        documentsDirty = container.decodeSyncStateValue(
            Bool.self,
            forKey: .documentsDirty,
            missingDefault: false,
            malformedDefault: true
        ) || documentDeletes.wasMalformed
        clientsDirty = container.decodeSyncStateValue(
            Bool.self,
            forKey: .clientsDirty,
            missingDefault: false,
            malformedDefault: true
        ) || clientDeletes.wasMalformed
        companyDirty = container.decodeSyncStateValue(
            Bool.self,
            forKey: .companyDirty,
            missingDefault: false,
            malformedDefault: true
        )
        timesheetsDirty = container.decodeSyncStateValue(
            Bool.self,
            forKey: .timesheetsDirty,
            missingDefault: false,
            malformedDefault: true
        ) || timesheetDeletes.wasMalformed
        lastFullSyncAt = container.decodeSyncStateOptionalValue(Date.self, forKey: .lastFullSyncAt)
        migrationCompleted = container.decodeSyncStateValue(
            Bool.self,
            forKey: .migrationCompleted,
            missingDefault: false,
            malformedDefault: false
        )
        pendingDocumentDeleteIds = documentDeletes.values
        pendingClientDeleteIds = clientDeletes.values
        pendingTimesheetDeleteIds = timesheetDeletes.values
    }
}

private struct SyncStateLossyStringArray: Decodable {
    let values: [String]
    let wasMalformed: Bool

    init(from decoder: Decoder) throws {
        let items = try [SyncStateLossyString](from: decoder)
        values = items.compactMap(\.value)
        wasMalformed = items.contains { $0.wasMalformed }
    }
}

private struct SyncStateLossyString: Decodable {
    let value: String?
    let wasMalformed: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            wasMalformed = true
        } else if let decoded = try? container.decode(String.self) {
            value = decoded
            wasMalformed = false
        } else {
            value = nil
            wasMalformed = true
        }
    }
}

private extension KeyedDecodingContainer {
    func decodeSyncStateValue<T: Decodable>(
        _ type: T.Type,
        forKey key: Key,
        missingDefault: @autoclosure () -> T,
        malformedDefault: @autoclosure () -> T
    ) -> T {
        guard contains(key) else {
            return missingDefault()
        }

        do {
            if try decodeNil(forKey: key) {
                return missingDefault()
            }
            return try decode(type, forKey: key)
        } catch {
            return malformedDefault()
        }
    }

    func decodeSyncStateOptionalValue<T: Decodable>(_ type: T.Type, forKey key: Key) -> T? {
        guard contains(key) else {
            return nil
        }

        do {
            if try decodeNil(forKey: key) {
                return nil
            }
            return try decode(type, forKey: key)
        } catch {
            return nil
        }
    }

    func decodeSyncStateStringArray(forKey key: Key) -> (values: [String], wasMalformed: Bool) {
        guard contains(key) else {
            return ([], false)
        }

        do {
            if try decodeNil(forKey: key) {
                return ([], false)
            }
            let decoded = try decode(SyncStateLossyStringArray.self, forKey: key)
            return (decoded.values, decoded.wasMalformed)
        } catch {
            return ([], true)
        }
    }
}
