import Foundation

// MARK: - Periode (mois)

@Observable
final class TimesheetPeriod: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var nom: String = ""
    var mois: Int = 1       // 1-12
    var annee: Int = 2026
    var semaines: [TimesheetWeek] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

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

    // MARK: - Cross-period overtime (heures sup inter-mois)

    /// Total heures travaillées uniquement les jours du mois courant
    func totalHeuresDuMois() -> Decimal {
        semaines.reduce(Decimal(0)) { total, week in
            total + week.jours.filter { $0.mois == mois }.reduce(Decimal(0)) { $0 + $1.heures }
        }
    }

    /// Heures sup cross-période (tenant compte des heures des mois adjacents)
    func totalHeuresSupCrossPeriod(adjacentHours: [String: Decimal]) -> Decimal {
        semaines.reduce(Decimal(0)) { $0 + $1.heuresSupPourMois(moisPeriode: mois, seuil: seuilHebdo, adjacentHours: adjacentHours) }
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

    /// Genere les semaines calendaires pour un mois
    /// Chaque semaine va de lundi a dimanche
    /// La premiere semaine inclut les jours du mois precedent si le 1er n'est pas un lundi
    /// La derniere semaine inclut les jours du mois suivant si le dernier n'est pas un dimanche
    static func genererSemaines(mois: Int, annee: Int) -> [TimesheetWeek] {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Lundi = premier jour
        cal.locale = Locale(identifier: "fr_FR")

        // Premier jour du mois
        guard let premierJour = cal.date(from: DateComponents(year: annee, month: mois, day: 1)) else { return [] }
        // Dernier jour du mois
        guard let dernierJour = cal.date(byAdding: DateComponents(month: 1, day: -1), to: premierJour) else { return [] }

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

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, nom, mois, annee, semaines, createdAt, updatedAt
        case tauxNormal, tauxSupplementaire, coefficientNet, seuilHebdo
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeOrDefault(UUID.self, forKey: .id, default: UUID())
        nom = c.decodeOrDefault(String.self, forKey: .nom, default: "")
        mois = c.decodeOrDefault(Int.self, forKey: .mois, default: Calendar.current.component(.month, from: Date()))
        annee = c.decodeOrDefault(Int.self, forKey: .annee, default: Calendar.current.component(.year, from: Date()))
        semaines = c.decodeOrDefault([TimesheetWeek].self, forKey: .semaines, default: [])
        createdAt = c.decodeOrDefault(Date.self, forKey: .createdAt, default: Date())

        // Reparer les semaines si le timesheet a ete tronque
        let expected = TimesheetPeriod.genererSemaines(mois: mois, annee: annee)
        if semaines.count < expected.count {
            // Creer un index dateString -> heures des jours deja saisis
            var heuresParDate: [String: Decimal] = [:]
            for w in semaines {
                for j in w.jours where j.heures != 0 {
                    heuresParDate[j.dateString] = j.heures
                }
            }
            // Remettre les heures dans les semaines regenerees
            var fixed = expected
            for wi in fixed.indices {
                for ji in fixed[wi].jours.indices {
                    if let h = heuresParDate[fixed[wi].jours[ji].dateString] {
                        fixed[wi].jours[ji].heures = h
                    }
                }
            }
            semaines = fixed
        }
        if nom.isEmpty {
            nom = moisLabel
        }
        updatedAt = c.decodeOrDefault(Date.self, forKey: .updatedAt, default: createdAt)
        tauxNormal = c.decodeOrDefault(Decimal.self, forKey: .tauxNormal, default: 26.39)
        tauxSupplementaire = c.decodeOrDefault(Decimal.self, forKey: .tauxSupplementaire, default: 39.59)
        coefficientNet = c.decodeOrDefault(Decimal.self, forKey: .coefficientNet, default: 0.756)
        seuilHebdo = c.decodeOrDefault(Decimal.self, forKey: .seuilHebdo, default: 35)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(nom, forKey: .nom)
        try c.encode(mois, forKey: .mois)
        try c.encode(annee, forKey: .annee)
        try c.encode(semaines, forKey: .semaines)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(tauxNormal, forKey: .tauxNormal)
        try c.encode(tauxSupplementaire, forKey: .tauxSupplementaire)
        try c.encode(coefficientNet, forKey: .coefficientNet)
        try c.encode(seuilHebdo, forKey: .seuilHebdo)
    }
}
