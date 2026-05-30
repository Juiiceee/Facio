import Foundation

// MARK: - Semaine calendaire

struct TimesheetWeek: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var numero: Int = 1
    /// 7 jours (lundi a dimanche) avec leurs vraies dates
    var jours: [TimesheetDay] = []

    init() {}

    init(id: UUID = UUID(), numero: Int = 1, jours: [TimesheetDay] = []) {
        self.id = id
        self.numero = numero
        self.jours = jours
    }

    /// Total heures de la semaine
    var totalHeures: Decimal {
        jours.reduce(0) { $0 + $1.heures }
    }

    func heuresNormales(seuil: Decimal = 35) -> Decimal {
        min(totalHeures, seuil)
    }

    func heuresSupplementaires(seuil: Decimal = 35) -> Decimal {
        max(totalHeures - seuil, 0)
    }

    /// Calcule les heures sup attribuables au mois courant dans cette semaine,
    /// en tenant compte des heures des jours d'un mois adjacent (chronologiquement).
    /// Les jours sont ordonnés lun→dim. Les premières `seuil` heures sont normales,
    /// le reste est overtime, réparti par mois selon l'ordre chronologique.
    func heuresSupPourMois(moisPeriode: Int, seuil: Decimal = 35, adjacentHours: [String: Decimal]) -> Decimal {
        var heuresPrecedentes: Decimal = 0
        var heuresMoisCourant: Decimal = 0
        var moisCourantCommence = false

        for jour in jours {
            let h: Decimal
            if jour.mois == moisPeriode {
                h = jour.heures
                heuresMoisCourant += h
                moisCourantCommence = true
            } else {
                h = adjacentHours[jour.dateString] ?? 0
                if !moisCourantCommence {
                    // Jours d'un autre mois avant le mois courant
                    heuresPrecedentes += h
                }
                // Jours après le mois courant n'affectent pas l'overtime de CE mois
            }
        }
        return max(0, heuresPrecedentes + heuresMoisCourant - seuil) - max(0, heuresPrecedentes - seuil)
    }

    /// Heures normales du mois courant dans cette semaine (cross-période)
    func heuresNormalesPourMois(moisPeriode: Int, seuil: Decimal = 35, adjacentHours: [String: Decimal]) -> Decimal {
        let heuresMois = jours.filter { $0.mois == moisPeriode }.reduce(Decimal(0)) { $0 + $1.heures }
        let sup = heuresSupPourMois(moisPeriode: moisPeriode, seuil: seuil, adjacentHours: adjacentHours)
        return heuresMois - sup
    }

    /// Le lundi de cette semaine
    var dateDebut: Date? {
        jours.first?.date
    }

    /// Label : "26 fev - 02 mar"
    var label: String {
        guard let first = jours.first, let last = jours.last else { return L10n.week(.fr, number: numero) }
        let f = DateFormatter()
        f.dateFormat = "dd MMM"
        f.locale = Locale(identifier: "fr_FR")
        return "\(f.string(from: first.date)) — \(f.string(from: last.date))"
    }

    func label(for lang: AppLanguage) -> String {
        guard let first = jours.first, let last = jours.last else { return L10n.week(lang, number: numero) }
        let f = DateFormatter()
        f.dateFormat = "dd MMM"
        f.locale = Locale(identifier: lang == .fr ? "fr_FR" : "en_US")
        return "\(f.string(from: first.date)) — \(f.string(from: last.date))"
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, numero, jours
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        numero = try container.decodeOrDefault(Int.self, forKey: .numero, default: 1)
        jours = try container.decodeOrDefault([TimesheetDay].self, forKey: .jours, default: [])
    }
}
