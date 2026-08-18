import Foundation

/// Formatage centralisé des durées et horloges de timer.
///
/// Source de vérité unique : remplace les copies privées de `formatClock`
/// disséminées dans les vues Time (TimeHubView, barre de minuteur) et garantit
/// une représentation humaine cohérente.
enum DurationFormatter {
    /// Horloge `HH:MM:SS` à partir de secondes.
    static func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    /// Horloge `HH:MM:SS` à partir de secondes entières.
    static func clock(_ seconds: Int) -> String {
        clock(TimeInterval(seconds))
    }

    /// Compte à rebours court : `45 s` sous la minute, `4:32` au-delà.
    /// Arrondi au supérieur — afficher « 0 s » alors qu'il reste à patienter
    /// donnerait l'impression que l'app est bloquée.
    static func countdown(_ seconds: TimeInterval, lang: AppLanguage) -> String {
        let total = max(0, Int(seconds.rounded(.up)))
        if total < 60 {
            return lang == .fr ? "\(total) s" : "\(total)s"
        }
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    /// Durée lisible `Xh YYm` (ex. `6h 30m`, `45m`) à partir d'heures décimales.
    static func hoursMinutes(fromDecimalHours hours: Decimal, lang: AppLanguage) -> String {
        let totalMinutes = max(0, Int((NSDecimalNumber(decimal: hours).doubleValue * 60).rounded()))
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(String(format: "%02d", m))m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
