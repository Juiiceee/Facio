import Foundation

// MARK: - Suivi des heures (timesheet)

extension L10n {

    // Jours de la semaine
    static func weekdayLabel(_ day: Int, _ l: AppLanguage) -> String {
        let fr = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
        let en = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return l == .fr ? fr[day] : en[day]
    }

    static func weekdayShort(_ day: Int, _ l: AppLanguage) -> String {
        let fr = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
        let en = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return l == .fr ? fr[day] : en[day]
    }

    // Resume
    static func summary(_ l: AppLanguage) -> String { l == .fr ? "Resume" : "Summary" }
    static func totalHours(_ l: AppLanguage) -> String { l == .fr ? "Total heures" : "Total hours" }
    static func normalHours(_ l: AppLanguage) -> String { l == .fr ? "Normales" : "Normal" }
    static func overtimeHours(_ l: AppLanguage) -> String { l == .fr ? "Supplementaires" : "Overtime" }
    static func normalHoursShort(_ l: AppLanguage, value: String) -> String { l == .fr ? "N: \(value)h" : "N: \(value)h" }
    static func overtimeHoursShort(_ l: AppLanguage, value: String) -> String { l == .fr ? "S: +\(value)h" : "OT: +\(value)h" }
    static func normalCost(_ l: AppLanguage) -> String { l == .fr ? "Cout normal" : "Normal cost" }
    static func overtimeCost(_ l: AppLanguage) -> String { l == .fr ? "Cout sup." : "Overtime cost" }
    static func grossTotal(_ l: AppLanguage) -> String { l == .fr ? "Total brut" : "Gross total" }
    static func netTotal(_ l: AppLanguage) -> String { l == .fr ? "Total net" : "Net total" }

    // Saisie des heures
    static func hourInputMode(_ l: AppLanguage) -> String { l == .fr ? "Saisie des heures" : "Hour input" }
    static func hourInputDecimalMode(_ l: AppLanguage) -> String { l == .fr ? "Decimal" : "Decimal" }
    static func hourInputTimeMode(_ l: AppLanguage) -> String { l == .fr ? "Horaire" : "Time" }
    static func hourInputPlaceholder(_ l: AppLanguage, mode: TimesheetHourInputMode) -> String {
        ""
    }
    static func hourInputHelp(_ l: AppLanguage, mode: TimesheetHourInputMode) -> String {
        switch mode {
        case .decimal:
            return l == .fr ? "6,5 ou 6.5 = 6,5 heures" : "6.5 or 6,5 = 6.5 hours"
        case .time:
            return l == .fr ? "Utilisez 6:30 ou 6h30 pour 6 heures 30" : "Use 6:30 or 6h30 for 6 hours 30"
        }
    }
    static func hourInputInvalidDecimal(_ l: AppLanguage) -> String {
        l == .fr ? "Nombre decimal invalide" : "Invalid decimal number"
    }
    static func hourInputInvalidTime(_ l: AppLanguage) -> String {
        l == .fr ? "Format horaire invalide : utilisez 6:30 ou 6h30" : "Invalid time format: use 6:30 or 6h30"
    }

    // Semaine
    static func week(_ l: AppLanguage, number: Int) -> String { l == .fr ? "Semaine \(number)" : "Week \(number)" }

    // Parametres de calcul
    static func calculationParams(_ l: AppLanguage) -> String { l == .fr ? "Parametres de calcul" : "Calculation parameters" }
    static func weeklyThreshold(_ l: AppLanguage) -> String { l == .fr ? "Seuil hebdo (h)" : "Weekly threshold (h)" }
    static func normalRate(_ l: AppLanguage) -> String { l == .fr ? "Taux normal" : "Normal rate" }
    static func overtimeRate(_ l: AppLanguage) -> String { l == .fr ? "Taux sup." : "Overtime rate" }
    static func netCoeff(_ l: AppLanguage) -> String { l == .fr ? "Coeff. net" : "Net coeff." }

    // Liste periodes
    static func newPeriod(_ l: AppLanguage) -> String { l == .fr ? "Nouvelle periode" : "New period" }
    static func month(_ l: AppLanguage) -> String { l == .fr ? "Mois" : "Month" }
    static func year(_ l: AppLanguage) -> String { l == .fr ? "Annee" : "Year" }
    static func periodExists(_ l: AppLanguage) -> String { l == .fr ? "Cette periode existe deja" : "This period already exists" }
    static func noPeriod(_ l: AppLanguage) -> String { l == .fr ? "Aucune periode" : "No period" }
    static func clickToCreatePeriod(_ l: AppLanguage) -> String { l == .fr ? "Cliquez sur + pour creer une nouvelle periode de suivi." : "Click + to create a new tracking period." }
    static func generateInvoice(_ l: AppLanguage) -> String { l == .fr ? "Generer une facture" : "Generate invoice" }
    static func invoiceDetailMode(_ l: AppLanguage) -> String { l == .fr ? "Detail de facturation" : "Invoice detail" }
    static func invoiceSummaryMode(_ l: AppLanguage) -> String { l == .fr ? "Resume" : "Summary" }
    static func invoiceDailyMode(_ l: AppLanguage) -> String { l == .fr ? "Detail par date" : "By date" }
    static func chooseInvoiceDetail(_ l: AppLanguage) -> String {
        l == .fr ? "Choisissez le niveau de detail de la facture." : "Choose the invoice detail level."
    }
    static func selectClientForPeriod(_ l: AppLanguage) -> String { l == .fr ? "Selectionner un client" : "Select client" }
    static func changeClient(_ l: AppLanguage) -> String { l == .fr ? "Changer de client" : "Change client" }
    static func clientRequired(_ l: AppLanguage) -> String { l == .fr ? "Selectionnez un client" : "Select a client" }
    static func periodExistsForClient(_ l: AppLanguage) -> String {
        l == .fr ? "Cette periode existe deja pour ce client" : "This period already exists for this client"
    }
    static func invoiced(_ l: AppLanguage) -> String { l == .fr ? "Facturee" : "Invoiced" }
    static func notInvoiced(_ l: AppLanguage) -> String { l == .fr ? "Non facturee" : "Not invoiced" }
    static func workHours(_ l: AppLanguage) -> String { l == .fr ? "Heures de travail" : "Work hours" }
    static func overtimeLabel(_ l: AppLanguage) -> String { l == .fr ? "Heures supplementaires" : "Overtime hours" }
    static func workHoursOnDate(_ l: AppLanguage, date: String) -> String {
        l == .fr ? "Heures de travail - \(date)" : "Work hours - \(date)"
    }
    static func overtimeHoursOnDate(_ l: AppLanguage, date: String) -> String {
        l == .fr ? "Heures supplementaires - \(date)" : "Overtime hours - \(date)"
    }
}
