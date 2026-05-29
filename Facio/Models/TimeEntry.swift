import Foundation
import Observation

@Observable
final class TimeEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var dateString: String = TimeEntry.dateString(for: Date())
    var projectName: String = ""
    var taskName: String = ""
    var notes: String = ""
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
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        normalize()
    }

    var isRunning: Bool {
        endedAt == nil
    }

    var displayProject: String {
        projectName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayTask: String {
        taskName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func duration(at referenceDate: Date = Date()) -> TimeInterval {
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

    func normalize() {
        dateString = Self.dateString(for: startedAt)
        projectName = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        taskName = taskName.trimmingCharacters(in: .whitespacesAndNewlines)
        notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if let endedAt, endedAt < startedAt {
            self.endedAt = startedAt
        }
    }

    func secondsByDate(upTo referenceDate: Date = Date()) -> [String: TimeInterval] {
        let end = endedAt ?? referenceDate
        return [dateString: max(0, end.timeIntervalSince(startedAt))]
    }

    static func dateString(for date: Date) -> String {
        TimesheetDay.dateFormatter.string(from: date)
    }

    enum CodingKeys: String, CodingKey {
        case id, dateString, projectName, taskName, notes
        case startedAt, endedAt, createdAt, updatedAt
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeOrDefault(UUID.self, forKey: .id, default: UUID())
        dateString = c.decodeOrDefault(String.self, forKey: .dateString, default: "")
        projectName = c.decodeOrDefault(String.self, forKey: .projectName, default: "")
        taskName = c.decodeOrDefault(String.self, forKey: .taskName, default: "")
        notes = c.decodeOrDefault(String.self, forKey: .notes, default: "")
        startedAt = c.decodeOrDefault(Date.self, forKey: .startedAt, default: Date())
        endedAt = try c.decodeIfPresent(Date.self, forKey: .endedAt)
        createdAt = c.decodeOrDefault(Date.self, forKey: .createdAt, default: startedAt)
        updatedAt = c.decodeOrDefault(Date.self, forKey: .updatedAt, default: createdAt)
        normalize()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(dateString, forKey: .dateString)
        try c.encode(projectName, forKey: .projectName)
        try c.encode(taskName, forKey: .taskName)
        try c.encode(notes, forKey: .notes)
        try c.encode(startedAt, forKey: .startedAt)
        try c.encodeIfPresent(endedAt, forKey: .endedAt)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
    }
}
