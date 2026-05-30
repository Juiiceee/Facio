import Foundation
import Observation

@Observable
final class TimeEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var dateString: String = TimeEntry.dateString(for: Date())
    var projectName: String = ""
    var taskName: String = ""
    var notes: String = ""
    var tagsText: String = ""
    var isBillable: Bool = true
    var rateSnapshot: Decimal?
    var currencySnapshotRawValue: String?
    var invoiceDocumentId: UUID?
    var invoiceLineItemId: UUID?
    var invoicedAt: Date?
    var sourceRawValue: String = TimeEntrySource.timer.rawValue
    var deletedAt: Date?
    var startedAt: Date = Date()
    var endedAt: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    static func == (lhs: TimeEntry, rhs: TimeEntry) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    init(
        id: UUID = UUID(),
        dateString: String? = nil,
        projectName: String = "",
        taskName: String = "",
        notes: String = "",
        tagsText: String = "",
        isBillable: Bool = true,
        rateSnapshot: Decimal? = nil,
        currencySnapshot: CurrencyType? = nil,
        invoiceDocumentId: UUID? = nil,
        invoiceLineItemId: UUID? = nil,
        invoicedAt: Date? = nil,
        source: TimeEntrySource = .timer,
        deletedAt: Date? = nil,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.dateString = dateString ?? Self.dateString(for: startedAt)
        self.projectName = projectName
        self.taskName = taskName
        self.notes = notes
        self.tagsText = tagsText
        self.isBillable = isBillable
        self.rateSnapshot = rateSnapshot
        self.currencySnapshotRawValue = currencySnapshot?.rawValue
        self.invoiceDocumentId = invoiceDocumentId
        self.invoiceLineItemId = invoiceLineItemId
        self.invoicedAt = invoicedAt
        self.sourceRawValue = source.rawValue
        self.deletedAt = deletedAt
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        normalize()
    }

    var isRunning: Bool {
        endedAt == nil && !isDeleted
    }

    var isDeleted: Bool {
        deletedAt != nil
    }

    var isInvoiced: Bool {
        invoiceDocumentId != nil || invoicedAt != nil
    }

    var source: TimeEntrySource {
        get { TimeEntrySource(rawValue: sourceRawValue) ?? .timer }
        set { sourceRawValue = newValue.rawValue }
    }

    var currencySnapshot: CurrencyType? {
        get {
            guard let currencySnapshotRawValue else { return nil }
            return CurrencyType(rawValue: currencySnapshotRawValue)
        }
        set {
            currencySnapshotRawValue = newValue?.rawValue
        }
    }

    var tags: [String] {
        tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var displayProject: String {
        projectName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayTask: String {
        taskName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func duration(at referenceDate: Date = Date()) -> TimeInterval {
        guard !isDeleted else { return 0 }
        let end = endedAt ?? referenceDate
        return max(0, end.timeIntervalSince(startedAt))
    }

    func durationHours(at referenceDate: Date = Date()) -> Decimal {
        Decimal(duration(at: referenceDate) / 3600)
    }

    func stop(at date: Date = Date()) {
        endedAt = max(startedAt, date)
        updatedAt = Date()
    }

    func applyBillingSnapshotIfNeeded(defaultRate: Decimal, currency: CurrencyType) {
        guard isBillable else { return }
        if rateSnapshot == nil {
            rateSnapshot = defaultRate
        }
        if currencySnapshot == nil {
            currencySnapshot = currency
        }
    }

    func clearInvoiceMarkers() {
        invoiceDocumentId = nil
        invoiceLineItemId = nil
        invoicedAt = nil
        updatedAt = Date()
    }

    func markInvoiced(documentId: UUID, lineItemId: UUID?, at date: Date) {
        invoiceDocumentId = documentId
        invoiceLineItemId = lineItemId
        invoicedAt = date
        updatedAt = date
    }

    func softDelete(at date: Date = Date()) {
        let wasRunning = endedAt == nil
        if wasRunning {
            endedAt = date
        }
        deletedAt = date
        updatedAt = date
    }

    func restore(at date: Date = Date()) {
        deletedAt = nil
        updatedAt = date
    }

    func normalize() {
        dateString = Self.dateString(for: startedAt)
        projectName = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        taskName = taskName.trimmingCharacters(in: .whitespacesAndNewlines)
        notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        tagsText = normalizedTagsText(tagsText)
        if CurrencyType(rawValue: currencySnapshotRawValue ?? "") == nil {
            currencySnapshotRawValue = nil
        }
        if TimeEntrySource(rawValue: sourceRawValue) == nil {
            sourceRawValue = TimeEntrySource.timer.rawValue
        }
        if let endedAt, endedAt < startedAt {
            self.endedAt = startedAt
        }
    }

    func secondsByDate(upTo referenceDate: Date = Date()) -> [String: TimeInterval] {
        guard !isDeleted else { return [:] }
        let end = endedAt ?? referenceDate
        return [dateString: max(0, end.timeIntervalSince(startedAt))]
    }

    static func dateString(for date: Date) -> String {
        TimesheetDay.dateFormatter.string(from: date)
    }

    private func normalizedTagsText(_ value: String) -> String {
        var seen: Set<String> = []
        let tags = value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { tag in
                let key = tag.lowercased()
                if seen.contains(key) { return false }
                seen.insert(key)
                return true
            }
        return tags.joined(separator: ", ")
    }

    enum CodingKeys: String, CodingKey {
        case id, dateString, projectName, taskName, notes, tagsText, isBillable
        case rateSnapshot, currencySnapshotRawValue, invoiceDocumentId, invoiceLineItemId, invoicedAt
        case sourceRawValue, deletedAt
        case startedAt, endedAt, createdAt, updatedAt
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        dateString = try c.decodeOrDefault(String.self, forKey: .dateString, default: "")
        projectName = try c.decodeOrDefault(String.self, forKey: .projectName, default: "")
        taskName = try c.decodeOrDefault(String.self, forKey: .taskName, default: "")
        notes = try c.decodeOrDefault(String.self, forKey: .notes, default: "")
        tagsText = try c.decodeOrDefault(String.self, forKey: .tagsText, default: "")
        isBillable = try c.decodeOrDefault(Bool.self, forKey: .isBillable, default: true)
        rateSnapshot = try c.decodeIfPresent(Decimal.self, forKey: .rateSnapshot)
        currencySnapshotRawValue = try c.decodeIfPresent(String.self, forKey: .currencySnapshotRawValue)
        invoiceDocumentId = try c.decodeIfPresent(UUID.self, forKey: .invoiceDocumentId)
        invoiceLineItemId = try c.decodeIfPresent(UUID.self, forKey: .invoiceLineItemId)
        invoicedAt = try c.decodeIfPresent(Date.self, forKey: .invoicedAt)
        sourceRawValue = try c.decodeOrDefault(String.self, forKey: .sourceRawValue, default: TimeEntrySource.timer.rawValue)
        deletedAt = try c.decodeIfPresent(Date.self, forKey: .deletedAt)
        startedAt = try c.decodeOrDefault(Date.self, forKey: .startedAt, default: Date())
        endedAt = try c.decodeIfPresent(Date.self, forKey: .endedAt)
        createdAt = try c.decodeOrDefault(Date.self, forKey: .createdAt, default: startedAt)
        updatedAt = try c.decodeOrDefault(Date.self, forKey: .updatedAt, default: createdAt)
        normalize()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(dateString, forKey: .dateString)
        try c.encode(projectName, forKey: .projectName)
        try c.encode(taskName, forKey: .taskName)
        try c.encode(notes, forKey: .notes)
        try c.encode(tagsText, forKey: .tagsText)
        try c.encode(isBillable, forKey: .isBillable)
        try c.encodeIfPresent(rateSnapshot, forKey: .rateSnapshot)
        try c.encodeIfPresent(currencySnapshotRawValue, forKey: .currencySnapshotRawValue)
        try c.encodeIfPresent(invoiceDocumentId, forKey: .invoiceDocumentId)
        try c.encodeIfPresent(invoiceLineItemId, forKey: .invoiceLineItemId)
        try c.encodeIfPresent(invoicedAt, forKey: .invoicedAt)
        try c.encode(sourceRawValue, forKey: .sourceRawValue)
        try c.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try c.encode(startedAt, forKey: .startedAt)
        try c.encodeIfPresent(endedAt, forKey: .endedAt)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
    }
}
