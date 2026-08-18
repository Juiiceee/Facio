import Foundation

/// Un mois de la série de revenus.
struct RevenueMonth: Identifiable, Equatable {
    /// Premier jour du mois, dans le calendrier courant.
    let start: Date
    /// Encaissé sur ce mois, converti en devise comptable.
    let collected: Decimal
    /// Le mois en cours — c'est lui qu'on étiquette dans le graphique.
    let isCurrent: Bool

    var id: Date { start }
}

/// La série mensuelle du tableau de bord.
///
/// La donnée existait déjà : chaque versement porte sa date, et
/// `Document.accountingCashEvents` la ventile. Elle n'était simplement jamais
/// montrée — l'écran s'appelait « tableau de bord », son icône était un
/// graphique, et il n'y avait aucun graphique, aucune tendance, aucune
/// comparaison. « CA ce mois : 4 250,00 € » était un nombre sans rien à quoi se
/// comparer.
enum RevenueSeriesService {
    /// Les `count` derniers mois, du plus ancien au plus récent.
    static func monthlySeries(
        for documents: [Document],
        referenceCurrency: CurrencyType,
        endingAt reference: Date = Date(),
        count: Int = 12,
        calendar: Calendar = .current
    ) -> [RevenueMonth] {
        guard count > 0 else { return [] }
        guard let currentMonth = calendar.dateInterval(of: .month, for: reference)?.start else { return [] }

        let starts: [Date] = (0..<count).reversed().compactMap {
            calendar.date(byAdding: .month, value: -$0, to: currentMonth)
        }

        // Une seule passe sur les documents : la vue recalculait chaque agrégat
        // dans son `body`, donc à chaque frame.
        var totals: [Date: Decimal] = [:]
        for document in documents where document.type == .facture {
            for event in document.accountingCashEvents(referenceCurrency: referenceCurrency) {
                guard let amount = event.amount,
                      let bucket = calendar.dateInterval(of: .month, for: event.date)?.start else { continue }
                totals[bucket, default: 0] += amount
            }
        }

        return starts.map { start in
            RevenueMonth(
                start: start,
                collected: totals[start] ?? 0,
                isCurrent: start == currentMonth
            )
        }
    }

    /// Ce qu'un mois de la série agrège : une facture et la part encaissée
    /// CE mois-là, qui n'est pas forcément son total.
    struct MonthlyCollection: Identifiable {
        let document: Document
        let amount: Decimal
        var id: UUID { document.id }
    }

    /// Les encaissements d'un mois donné, du plus gros au plus petit.
    ///
    /// C'est la contrepartie de `monthlySeries` : la barre montrait un total
    /// sans jamais dire de quoi il était fait.
    static func collections(
        for documents: [Document],
        referenceCurrency: CurrencyType,
        in month: Date,
        calendar: Calendar = .current
    ) -> [MonthlyCollection] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }

        var byDocument: [UUID: (document: Document, amount: Decimal)] = [:]
        for document in documents where document.type == .facture {
            for event in document.accountingCashEvents(referenceCurrency: referenceCurrency) {
                guard let amount = event.amount, interval.contains(event.date) else { continue }
                let previous = byDocument[document.id]?.amount ?? 0
                byDocument[document.id] = (document, previous + amount)
            }
        }

        return byDocument.values
            .map { MonthlyCollection(document: $0.document, amount: $0.amount) }
            .sorted { $0.amount > $1.amount }
    }

    /// TVA encaissée sur le trimestre courant.
    ///
    /// Remplace « Devis en cours » — un compteur que le tableau de bord affichait
    /// déjà, à l'identique, dans le groupe « Devis à relancer » juste dessous.
    /// La TVA, elle, a une échéance.
    ///
    /// Chaque versement est proraté par la part de TVA du document : encaisser la
    /// moitié d'une facture, c'est encaisser la moitié de sa TVA.
    static func vatCollectedThisQuarter(
        for documents: [Document],
        referenceCurrency: CurrencyType,
        reference: Date = Date(),
        calendar: Calendar = .current
    ) -> Decimal {
        guard let quarter = quarterInterval(containing: reference, calendar: calendar) else { return 0 }

        var total: Decimal = 0
        for document in documents where document.type == .facture {
            let ttc = document.totalTTC
            guard ttc > 0 else { continue }
            let vat = document.totalTVA

            for event in document.accountingCashEvents(referenceCurrency: referenceCurrency) {
                guard let amount = event.amount, quarter.contains(event.date) else { continue }
                // On MULTIPLIE avant de diviser : passer par le ratio
                // TVA / TTC produit une fraction périodique (200/1200) et un
                // encaissement de 600 donnait 99,999…996 au lieu de 100.
                total += (amount * vat) / ttc
            }
        }
        return total
    }

    /// Le trimestre civil contenant `date`.
    static func quarterInterval(containing date: Date, calendar: Calendar = .current) -> DateInterval? {
        let month = calendar.component(.month, from: date)
        let firstMonth = ((month - 1) / 3) * 3 + 1
        var components = calendar.dateComponents([.year], from: date)
        components.month = firstMonth
        components.day = 1
        guard let start = calendar.date(from: components),
              let end = calendar.date(byAdding: .month, value: 3, to: start) else { return nil }
        return DateInterval(start: start, end: end)
    }

    /// Le numéro du trimestre (1 à 4).
    static func quarterNumber(of date: Date, calendar: Calendar = .current) -> Int {
        (calendar.component(.month, from: date) - 1) / 3 + 1
    }
}
