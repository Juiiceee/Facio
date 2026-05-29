import Foundation

// MARK: - Periode (mois)

@Observable
final class TimesheetPeriod: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var nom: String = ""
    var mois: Int = 1       // 1-12
    var annee: Int = 2026
    var customStartDateString: String?
    var customEndDateString: String?
    var semaines: [TimesheetWeek] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var invoiceDocumentId: UUID?
    var billedAt: Date?
    var invoiceDetailModeRawValue: String = TimesheetInvoiceDetailMode.summary.rawValue
    var clientId: UUID?
    var clientNom: String = ""
    var clientAdresse: String = ""
    var clientCodePostal: String = ""
    var clientVille: String = ""
    var clientSiret: String = ""
    var clientTva: String = ""
    var clientApe: String = ""
    var timeEntries: [TimeEntry] = []

    // Parametres de calcul
    var tauxNormal: Decimal = 26.39
    var tauxSupplementaire: Decimal = 39.59
    var coefficientNet: Decimal = 0.756
    var seuilHebdo: Decimal = 35

    // MARK: - Hashable

    static func == (lhs: TimesheetPeriod, rhs: TimesheetPeriod) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    // MARK: - Computed

    var totalHeures: Decimal { semaines.reduce(0) { $0 + $1.totalHeures } }
    var totalHeuresNormales: Decimal { semaines.reduce(0) { $0 + $1.heuresNormales(seuil: seuilHebdo) } }
    var totalHeuresSupplementaires: Decimal { semaines.reduce(0) { $0 + $1.heuresSupplementaires(seuil: seuilHebdo) } }
    var coutNormal: Decimal { totalHeuresNormales * tauxNormal }
    var coutSupplementaire: Decimal { totalHeuresSupplementaires * tauxSupplementaire }
    var totalBrut: Decimal { coutNormal + coutSupplementaire }
    var totalNet: Decimal { totalBrut * coefficientNet }
    var hasGeneratedInvoice: Bool { invoiceDocumentId != nil || billedAt != nil }
    var hasClient: Bool { clientId != nil || !clientNom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var runningTimeEntry: TimeEntry? {
        timeEntries
            .filter(\.isRunning)
            .sorted { $0.startedAt > $1.startedAt }
            .first
    }

    var invoiceDetailMode: TimesheetInvoiceDetailMode {
        get { TimesheetInvoiceDetailMode(rawValue: invoiceDetailModeRawValue) ?? .summary }
        set { invoiceDetailModeRawValue = newValue.rawValue }
    }

    var clientDisplayName: String {
        clientNom.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isCustomRange: Bool {
        customStartDateString != nil && customEndDateString != nil
    }

    var activeStartDateString: String {
        if let customStartDateString, !customStartDateString.isEmpty {
            return customStartDateString
        }
        return TimesheetPeriod.monthStartDateString(mois: mois, annee: annee)
    }

    var activeEndDateString: String {
        if let customEndDateString, !customEndDateString.isEmpty {
            return customEndDateString
        }
        return TimesheetPeriod.monthEndDateString(mois: mois, annee: annee)
    }

    var activeStartDate: Date {
        TimesheetDay.dateFormatter.date(from: activeStartDateString) ?? Date()
    }

    var activeEndDate: Date {
        TimesheetDay.dateFormatter.date(from: activeEndDateString) ?? activeStartDate
    }

    func isBillableDay(_ day: TimesheetDay) -> Bool {
        isBillableDateString(day.dateString)
    }

    func isBillableDateString(_ dateString: String) -> Bool {
        dateString >= activeStartDateString && dateString <= activeEndDateString
    }

    // MARK: - Cross-period overtime (heures sup inter-mois)

    /// Total heures travaillees uniquement dans la plage facturee.
    func totalHeuresDuMois() -> Decimal {
        semaines.reduce(Decimal(0)) { total, week in
            total + week.jours.filter { isBillableDay($0) }.reduce(Decimal(0)) { $0 + $1.heures }
        }
    }

    func totalHeuresPourSemaine(_ week: TimesheetWeek) -> Decimal {
        week.jours.filter { isBillableDay($0) }.reduce(Decimal(0)) { $0 + $1.heures }
    }

    /// Heures sup cross-periode (tenant compte des heures hors plage sur la meme semaine)
    func totalHeuresSupCrossPeriod(adjacentHours: [String: Decimal]) -> Decimal {
        semaines.reduce(Decimal(0)) { $0 + heuresSupPourSemaine($1, adjacentHours: adjacentHours) }
    }

    /// Heures normales cross-période
    func totalHeuresNormalesCrossPeriod(adjacentHours: [String: Decimal]) -> Decimal {
        totalHeuresDuMois() - totalHeuresSupCrossPeriod(adjacentHours: adjacentHours)
    }

    /// Coût brut cross-période
    func totalBrutCrossPeriod(adjacentHours: [String: Decimal]) -> Decimal {
        let normales = totalHeuresNormalesCrossPeriod(adjacentHours: adjacentHours)
        let sup = totalHeuresSupCrossPeriod(adjacentHours: adjacentHours)
        return normales * tauxNormal + sup * tauxSupplementaire
    }

    /// Coût net cross-période
    func totalNetCrossPeriod(adjacentHours: [String: Decimal]) -> Decimal {
        totalBrutCrossPeriod(adjacentHours: adjacentHours) * coefficientNet
    }

    /// Label du mois (ex: "Mars 2026")
    var moisLabel: String {
        moisLabel(for: .fr)
    }

    func moisLabel(for lang: AppLanguage) -> String {
        guard mois >= 1 && mois <= 12 else { return "\(L10n.month(lang)) \(mois) \(annee)" }
        let f = DateFormatter()
        f.locale = Locale(identifier: lang == .fr ? "fr_FR" : "en_US")
        return "\(f.monthSymbols[mois - 1].capitalized) \(annee)"
    }

    func periodLabel(for lang: AppLanguage) -> String {
        guard isCustomRange else { return moisLabel(for: lang) }
        return "\(activeStartDate.formattedDate(for: lang)) - \(activeEndDate.formattedDate(for: lang))"
    }

    func title(for lang: AppLanguage) -> String {
        let period = periodLabel(for: lang)
        guard !clientDisplayName.isEmpty else { return period }
        return "\(period) - \(clientDisplayName)"
    }

    func applyClient(_ client: ClientInfo) {
        clientId = client.id
        clientNom = client.nom
        clientAdresse = client.adresse
        clientCodePostal = client.codePostal
        clientVille = client.ville
        clientSiret = client.siret
        clientTva = client.tva
        clientApe = client.ape
        refreshDefaultName()
    }

    func clearClient() {
        clientId = nil
        clientNom = ""
        clientAdresse = ""
        clientCodePostal = ""
        clientVille = ""
        clientSiret = ""
        clientTva = ""
        clientApe = ""
        refreshDefaultName()
    }

    func applyClient(to document: Document) {
        document.clientNom = clientNom
        document.clientAdresse = clientAdresse
        document.clientCodePostal = clientCodePostal
        document.clientVille = clientVille
        document.clientSiret = clientSiret
        document.clientTva = clientTva
        document.clientApe = clientApe
    }

    func hasSameClientScope(as other: TimesheetPeriod) -> Bool {
        switch (clientId, other.clientId) {
        case let (lhs?, rhs?):
            return lhs == rhs
        case (nil, nil):
            return true
        default:
            return false
        }
    }

    static func periodExists(
        in periods: [TimesheetPeriod],
        mois: Int,
        annee: Int,
        clientId: UUID?,
        excluding excludedId: UUID? = nil
    ) -> Bool {
        periods.contains {
            $0.id != excludedId
                && $0.mois == mois
                && $0.annee == annee
                && $0.clientId == clientId
        }
    }

    static func periodOverlaps(
        in periods: [TimesheetPeriod],
        startDate: Date,
        endDate: Date,
        clientId: UUID?,
        excluding excludedId: UUID? = nil
    ) -> Bool {
        let range = normalizedDateRange(startDate: startDate, endDate: endDate)
        return periodOverlaps(
            in: periods,
            startDateString: range.start,
            endDateString: range.end,
            clientId: clientId,
            excluding: excludedId
        )
    }

    static func periodOverlaps(
        in periods: [TimesheetPeriod],
        startDateString: String,
        endDateString: String,
        clientId: UUID?,
        excluding excludedId: UUID? = nil
    ) -> Bool {
        periods.contains {
            $0.id != excludedId
                && $0.clientId == clientId
                && startDateString <= $0.activeEndDateString
                && endDateString >= $0.activeStartDateString
        }
    }

    // MARK: - Init

    init() {
        self.id = UUID()
    }

    /// Cree une periode pour un mois donne et genere les semaines calendaires
    init(mois: Int, annee: Int) {
        self.id = UUID()
        self.mois = mois
        self.annee = annee
        self.nom = ""
        self.createdAt = Date()
        self.semaines = TimesheetPeriod.genererSemaines(mois: mois, annee: annee)
        self.nom = moisLabel
    }

    convenience init(mois: Int, annee: Int, client: ClientInfo) {
        self.init(mois: mois, annee: annee)
        applyClient(client)
    }

    init(startDate: Date, endDate: Date) {
        self.id = UUID()
        let range = TimesheetPeriod.normalizedDateRange(startDate: startDate, endDate: endDate)
        self.customStartDateString = range.start
        self.customEndDateString = range.end
        self.mois = Calendar(identifier: .gregorian).component(.month, from: range.startDate)
        self.annee = Calendar(identifier: .gregorian).component(.year, from: range.startDate)
        self.nom = ""
        self.createdAt = Date()
        self.semaines = TimesheetPeriod.genererSemaines(startDate: range.startDate, endDate: range.endDate)
        self.nom = periodLabel(for: .fr)
    }

    convenience init(startDate: Date, endDate: Date, client: ClientInfo) {
        self.init(startDate: startDate, endDate: endDate)
        applyClient(client)
    }

    /// Genere les semaines calendaires pour un mois
    /// Chaque semaine va de lundi a dimanche
    /// La premiere semaine inclut les jours du mois precedent si le 1er n'est pas un lundi
    /// La derniere semaine inclut les jours du mois suivant si le dernier n'est pas un dimanche
    static func genererSemaines(mois: Int, annee: Int) -> [TimesheetWeek] {
        let startDate = monthStartDate(mois: mois, annee: annee)
        let endDate = monthEndDate(mois: mois, annee: annee)
        return genererSemaines(startDate: startDate, endDate: endDate)
    }

    /// Genere les semaines calendaires couvrant une plage de dates.
    /// Chaque semaine va de lundi a dimanche.
    static func genererSemaines(startDate: Date, endDate: Date) -> [TimesheetWeek] {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Lundi = premier jour
        cal.locale = Locale(identifier: "fr_FR")

        let range = normalizedDateRange(startDate: startDate, endDate: endDate)
        let premierJour = range.startDate
        let dernierJour = range.endDate

        // Trouver le lundi de la semaine du 1er
        var weekday = cal.component(.weekday, from: premierJour) - 2 // lundi=0
        if weekday < 0 { weekday = 6 }
        guard let lundiDebut = cal.date(byAdding: .day, value: -weekday, to: premierJour) else { return [] }

        // Trouver le dimanche de la semaine du dernier jour
        var lastWeekday = cal.component(.weekday, from: dernierJour) - 2
        if lastWeekday < 0 { lastWeekday = 6 }
        let joursJusquaDimanche = 6 - lastWeekday
        guard let dimancheFin = cal.date(byAdding: .day, value: joursJusquaDimanche, to: dernierJour) else { return [] }

        var semaines: [TimesheetWeek] = []
        var currentDate = lundiDebut
        var weekNum = 1

        while currentDate <= dimancheFin {
            var jours: [TimesheetDay] = []
            for dayOffset in 0..<7 {
                guard let date = cal.date(byAdding: .day, value: dayOffset, to: currentDate) else { continue }
                jours.append(TimesheetDay(date: date))
            }
            var week = TimesheetWeek()
            week.numero = weekNum
            week.jours = jours
            semaines.append(week)

            weekNum += 1
            guard let nextMonday = cal.date(byAdding: .day, value: 7, to: currentDate) else { break }
            currentDate = nextMonday
        }

        return semaines
    }

    /// Restores the canonical calendar shape for the period and merges persisted hours by date.
    @discardableResult
    func normalizeCalendar() -> Bool {
        let expected = TimesheetPeriod.genererSemaines(startDate: activeStartDate, endDate: activeEndDate)
        guard !expected.isEmpty else { return false }

        var daysByDate: [String: TimesheetDay] = [:]
        var weeksByStartDate: [String: TimesheetWeek] = [:]
        var weeksByNumber: [Int: TimesheetWeek] = [:]
        var changed = semaines.count != expected.count

        for week in semaines {
            if let startDate = week.jours.first?.dateString {
                if weeksByStartDate[startDate] == nil {
                    weeksByStartDate[startDate] = week
                } else {
                    changed = true
                }
            }
            if weeksByNumber[week.numero] == nil {
                weeksByNumber[week.numero] = week
            }

            for day in week.jours {
                if let existing = daysByDate[day.dateString] {
                    daysByDate[day.dateString] = TimesheetPeriod.preferredDay(existing: existing, candidate: day)
                    changed = true
                } else {
                    daysByDate[day.dateString] = day
                }
            }
        }

        var normalized = expected
        for weekIndex in normalized.indices {
            let expectedStartDate = normalized[weekIndex].jours.first?.dateString
            let storedWeek = expectedStartDate.flatMap { weeksByStartDate[$0] }
                ?? weeksByNumber[normalized[weekIndex].numero]
            if let storedWeek {
                normalized[weekIndex].id = storedWeek.id
            }

            for dayIndex in normalized[weekIndex].jours.indices {
                let dateString = normalized[weekIndex].jours[dayIndex].dateString
                guard let storedDay = daysByDate[dateString] else { continue }
                normalized[weekIndex].jours[dayIndex].id = storedDay.id
                normalized[weekIndex].jours[dayIndex].heures = storedDay.heures
            }
        }

        if semaines != normalized {
            semaines = normalized
            changed = true
        }
        if nom.isEmpty {
            refreshDefaultName()
            changed = true
        }

        return changed
    }

    private func refreshDefaultName() {
        nom = title(for: .fr)
    }

    func heuresSupPourSemaine(_ week: TimesheetWeek, adjacentHours: [String: Decimal]) -> Decimal {
        var hoursBeforeDay: Decimal = 0
        var overtime: Decimal = 0

        for day in week.jours {
            let dayHours = isBillableDay(day)
                ? day.heures
                : adjacentHours[day.dateString] ?? 0

            defer { hoursBeforeDay += dayHours }
            guard isBillableDay(day), dayHours > 0 else { continue }

            let remainingNormalHours = max(seuilHebdo - hoursBeforeDay, 0)
            let normalHours = min(dayHours, remainingNormalHours)
            overtime += dayHours - normalHours
        }

        return overtime
    }

    func addTimeEntry(_ entry: TimeEntry) {
        entry.normalize()
        timeEntries.append(entry)
    }

    func deleteTimeEntry(_ entry: TimeEntry) {
        timeEntries.removeAll { $0.id == entry.id }
    }

    func hasTimeEntries(on dateString: String) -> Bool {
        timeEntries.contains { $0.dateString == dateString }
    }

    @discardableResult
    func recalculateHoursFromTimeEntries(
        affectedDateStrings: Set<String>? = nil,
        referenceDate: Date = Date()
    ) -> Bool {
        let affectedDates = affectedDateStrings ?? Set(timeEntries.flatMap {
            $0.secondsByDate(upTo: referenceDate).keys
        })
        guard !affectedDates.isEmpty else { return false }

        var secondsByDate: [String: TimeInterval] = [:]
        for entry in timeEntries {
            for (dateString, seconds) in entry.secondsByDate(upTo: referenceDate) {
                guard affectedDates.contains(dateString) else { continue }
                secondsByDate[dateString, default: 0] += seconds
            }
        }

        var changed = false
        for weekIndex in semaines.indices {
            for dayIndex in semaines[weekIndex].jours.indices {
                let dateString = semaines[weekIndex].jours[dayIndex].dateString
                guard affectedDates.contains(dateString), isBillableDateString(dateString) else { continue }
                let hours = Decimal((secondsByDate[dateString] ?? 0) / 3600)
                if semaines[weekIndex].jours[dayIndex].heures != hours {
                    semaines[weekIndex].jours[dayIndex].heures = hours
                    changed = true
                }
            }
        }
        return changed
    }

    static func normalizedDateRange(startDate: Date, endDate: Date) -> (startDate: Date, endDate: Date, start: String, end: String) {
        let cal = Calendar(identifier: .gregorian)
        let start = cal.startOfDay(for: startDate)
        let end = cal.startOfDay(for: endDate)
        let lower = min(start, end)
        let upper = max(start, end)
        return (
            startDate: lower,
            endDate: upper,
            start: TimesheetDay.dateFormatter.string(from: lower),
            end: TimesheetDay.dateFormatter.string(from: upper)
        )
    }

    private static func monthStartDate(mois: Int, annee: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: annee, month: mois, day: 1)) ?? Date()
    }

    private static func monthEndDate(mois: Int, annee: Int) -> Date {
        let start = monthStartDate(mois: mois, annee: annee)
        return Calendar(identifier: .gregorian).date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? start
    }

    private static func monthStartDateString(mois: Int, annee: Int) -> String {
        TimesheetDay.dateFormatter.string(from: monthStartDate(mois: mois, annee: annee))
    }

    private static func monthEndDateString(mois: Int, annee: Int) -> String {
        TimesheetDay.dateFormatter.string(from: monthEndDate(mois: mois, annee: annee))
    }

    private static func preferredDay(existing: TimesheetDay, candidate: TimesheetDay) -> TimesheetDay {
        if existing.heures == 0, candidate.heures != 0 {
            return candidate
        }
        if candidate.heures == 0 {
            return existing
        }
        return candidate
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, nom, mois, annee, customStartDateString, customEndDateString, semaines, createdAt, updatedAt
        case invoiceDocumentId, billedAt, invoiceDetailModeRawValue
        case clientId, clientNom, clientAdresse, clientCodePostal, clientVille
        case clientSiret, clientTva, clientApe
        case timeEntries
        case tauxNormal, tauxSupplementaire, coefficientNet, seuilHebdo
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeOrDefault(UUID.self, forKey: .id, default: UUID())
        nom = c.decodeOrDefault(String.self, forKey: .nom, default: "")
        mois = c.decodeOrDefault(Int.self, forKey: .mois, default: Calendar.current.component(.month, from: Date()))
        annee = c.decodeOrDefault(Int.self, forKey: .annee, default: Calendar.current.component(.year, from: Date()))
        customStartDateString = try c.decodeIfPresent(String.self, forKey: .customStartDateString)
        customEndDateString = try c.decodeIfPresent(String.self, forKey: .customEndDateString)
        semaines = c.decodeOrDefault([TimesheetWeek].self, forKey: .semaines, default: [])
        createdAt = c.decodeOrDefault(Date.self, forKey: .createdAt, default: Date())
        invoiceDocumentId = try? c.decode(UUID.self, forKey: .invoiceDocumentId)
        billedAt = try? c.decode(Date.self, forKey: .billedAt)
        invoiceDetailModeRawValue = c.decodeOrDefault(
            String.self,
            forKey: .invoiceDetailModeRawValue,
            default: TimesheetInvoiceDetailMode.summary.rawValue
        )
        clientId = try? c.decode(UUID.self, forKey: .clientId)
        clientNom = c.decodeOrDefault(String.self, forKey: .clientNom, default: "")
        clientAdresse = c.decodeOrDefault(String.self, forKey: .clientAdresse, default: "")
        clientCodePostal = c.decodeOrDefault(String.self, forKey: .clientCodePostal, default: "")
        clientVille = c.decodeOrDefault(String.self, forKey: .clientVille, default: "")
        clientSiret = c.decodeOrDefault(String.self, forKey: .clientSiret, default: "")
        clientTva = c.decodeOrDefault(String.self, forKey: .clientTva, default: "")
        clientApe = c.decodeOrDefault(String.self, forKey: .clientApe, default: "")
        timeEntries = c.decodeOrDefault([TimeEntry].self, forKey: .timeEntries, default: [])
        updatedAt = c.decodeOrDefault(Date.self, forKey: .updatedAt, default: createdAt)
        tauxNormal = c.decodeOrDefault(Decimal.self, forKey: .tauxNormal, default: 26.39)
        tauxSupplementaire = c.decodeOrDefault(Decimal.self, forKey: .tauxSupplementaire, default: 39.59)
        coefficientNet = c.decodeOrDefault(Decimal.self, forKey: .coefficientNet, default: 0.756)
        seuilHebdo = c.decodeOrDefault(Decimal.self, forKey: .seuilHebdo, default: 35)
        normalizeCalendar()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(nom, forKey: .nom)
        try c.encode(mois, forKey: .mois)
        try c.encode(annee, forKey: .annee)
        try c.encodeIfPresent(customStartDateString, forKey: .customStartDateString)
        try c.encodeIfPresent(customEndDateString, forKey: .customEndDateString)
        try c.encode(semaines, forKey: .semaines)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encodeIfPresent(invoiceDocumentId, forKey: .invoiceDocumentId)
        try c.encodeIfPresent(billedAt, forKey: .billedAt)
        try c.encode(invoiceDetailModeRawValue, forKey: .invoiceDetailModeRawValue)
        try c.encodeIfPresent(clientId, forKey: .clientId)
        try c.encode(clientNom, forKey: .clientNom)
        try c.encode(clientAdresse, forKey: .clientAdresse)
        try c.encode(clientCodePostal, forKey: .clientCodePostal)
        try c.encode(clientVille, forKey: .clientVille)
        try c.encode(clientSiret, forKey: .clientSiret)
        try c.encode(clientTva, forKey: .clientTva)
        try c.encode(clientApe, forKey: .clientApe)
        try c.encode(timeEntries, forKey: .timeEntries)
        try c.encode(tauxNormal, forKey: .tauxNormal)
        try c.encode(tauxSupplementaire, forKey: .tauxSupplementaire)
        try c.encode(coefficientNet, forKey: .coefficientNet)
        try c.encode(seuilHebdo, forKey: .seuilHebdo)
    }
}
