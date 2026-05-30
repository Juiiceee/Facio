import Foundation

// MARK: - Entree journaliere

struct TimesheetDay: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    /// Date du jour (sans heure)
    var dateString: String  // "2026-03-01" — stocke comme string pour serialisation fiable
    var heures: Decimal = 0

    var date: Date {
        TimesheetDay.dateFormatter.date(from: dateString) ?? Date()
    }

    var jourSemaine: JourSemaine {
        let cal = Calendar(identifier: .gregorian)
        var weekday = cal.component(.weekday, from: date) - 2  // dimanche=1 en Calendar, on veut lundi=0
        if weekday < 0 { weekday = 6 }
        return JourSemaine(rawValue: weekday) ?? .lundi
    }

    /// Jour du mois (ex: "26", "1", "15")
    var jourDuMois: Int {
        Calendar(identifier: .gregorian).component(.day, from: date)
    }

    /// Mois (1-12)
    var mois: Int {
        Calendar(identifier: .gregorian).component(.month, from: date)
    }

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "fr_FR")
        return f
    }()

    init(date: Date, heures: Decimal = 0) {
        self.id = UUID()
        self.dateString = TimesheetDay.dateFormatter.string(from: date)
        self.heures = heures
    }

    // MARK: - Codable (backwards-compatible)

    enum CodingKeys: String, CodingKey {
        case id, dateString, date, heures
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeOrDefault(UUID.self, forKey: .id, default: UUID())
        if let persistedDateString = try container.decodeIfPresent(String.self, forKey: .dateString),
           !persistedDateString.isEmpty {
            dateString = persistedDateString
        } else if let persistedDate = try container.decodeIfPresent(Date.self, forKey: .date) {
            dateString = TimesheetDay.dateFormatter.string(from: persistedDate)
        } else {
            dateString = TimesheetDay.dateFormatter.string(from: Date())
        }
        heures = try container.decodeOrDefault(Decimal.self, forKey: .heures, default: 0)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(dateString, forKey: .dateString)
        try container.encode(heures, forKey: .heures)
    }
}
