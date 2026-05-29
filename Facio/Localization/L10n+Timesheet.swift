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
    static func summary(_ l: AppLanguage) -> String { l == .fr ? "Résumé" : "Summary" }
    static func totalHours(_ l: AppLanguage) -> String { l == .fr ? "Total heures" : "Total hours" }
    static func normalHours(_ l: AppLanguage) -> String { l == .fr ? "Normales" : "Normal" }
    static func overtimeHours(_ l: AppLanguage) -> String { l == .fr ? "Supplémentaires" : "Overtime" }
    static func normalHoursShort(_ l: AppLanguage, value: String) -> String { l == .fr ? "N: \(value)h" : "N: \(value)h" }
    static func overtimeHoursShort(_ l: AppLanguage, value: String) -> String { l == .fr ? "S: +\(value)h" : "OT: +\(value)h" }
    static func normalCost(_ l: AppLanguage) -> String { l == .fr ? "Coût normal" : "Normal cost" }
    static func overtimeCost(_ l: AppLanguage) -> String { l == .fr ? "Cout sup." : "Overtime cost" }
    static func grossTotal(_ l: AppLanguage) -> String { l == .fr ? "Total brut" : "Gross total" }
    static func netTotal(_ l: AppLanguage) -> String { l == .fr ? "Total net" : "Net total" }

    // Saisie des heures
    static func hourInputMode(_ l: AppLanguage) -> String { l == .fr ? "Saisie des heures" : "Hour input" }
    static func hourInputDecimalMode(_ l: AppLanguage) -> String { l == .fr ? "Décimal" : "Decimal" }
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
        l == .fr ? "Nombre décimal invalide" : "Invalid decimal number"
    }
    static func hourInputInvalidTime(_ l: AppLanguage) -> String {
        l == .fr ? "Format horaire invalide : utilisez 6:30 ou 6h30" : "Invalid time format: use 6:30 or 6h30"
    }

    // Semaine
    static func week(_ l: AppLanguage, number: Int) -> String { l == .fr ? "Semaine \(number)" : "Week \(number)" }

    // Parametres de calcul
    static func calculationParams(_ l: AppLanguage) -> String { l == .fr ? "Paramètres de calcul" : "Calculation parameters" }
    static func weeklyThreshold(_ l: AppLanguage) -> String { l == .fr ? "Seuil hebdo (h)" : "Weekly threshold (h)" }
    static func normalRate(_ l: AppLanguage) -> String { l == .fr ? "Taux normal" : "Normal rate" }
    static func overtimeRate(_ l: AppLanguage) -> String { l == .fr ? "Taux sup." : "Overtime rate" }
    static func netCoeff(_ l: AppLanguage) -> String { l == .fr ? "Coeff. net" : "Net coeff." }

    // Liste periodes
    static func newPeriod(_ l: AppLanguage) -> String { l == .fr ? "Nouvelle période" : "New period" }
    static func monthlyPeriod(_ l: AppLanguage) -> String { l == .fr ? "Mois" : "Month" }
    static func customPeriod(_ l: AppLanguage) -> String { l == .fr ? "Personnalisée" : "Custom" }
    static func startDate(_ l: AppLanguage) -> String { l == .fr ? "Début" : "Start" }
    static func endDate(_ l: AppLanguage) -> String { l == .fr ? "Fin" : "End" }
    static func month(_ l: AppLanguage) -> String { l == .fr ? "Mois" : "Month" }
    static func year(_ l: AppLanguage) -> String { l == .fr ? "Année" : "Year" }
    static func periodExists(_ l: AppLanguage) -> String { l == .fr ? "Cette période existe déjà" : "This period already exists" }
    static func noPeriod(_ l: AppLanguage) -> String { l == .fr ? "Aucune période" : "No period" }
    static func clickToCreatePeriod(_ l: AppLanguage) -> String { l == .fr ? "Cliquez sur + pour créer une nouvelle période de suivi." : "Click + to create a new tracking period." }
    static func generateInvoice(_ l: AppLanguage) -> String { l == .fr ? "Générer une facture" : "Generate invoice" }
    static func openInvoice(_ l: AppLanguage) -> String { l == .fr ? "Ouvrir la facture" : "Open invoice" }
    static func invoiceDetailMode(_ l: AppLanguage) -> String { l == .fr ? "Détail de facturation" : "Invoice detail" }
    static func invoiceSummaryMode(_ l: AppLanguage) -> String { l == .fr ? "Résumé" : "Summary" }
    static func invoiceDailyMode(_ l: AppLanguage) -> String { l == .fr ? "Détail par date" : "By date" }
    static func invoiceDailyActivityMode(_ l: AppLanguage) -> String {
        l == .fr ? "Détail par date et activité" : "By date and activity"
    }
    static func chooseInvoiceDetail(_ l: AppLanguage) -> String {
        l == .fr ? "Choisissez le niveau de détail de la facture." : "Choose the invoice detail level."
    }
    static func selectClientForPeriod(_ l: AppLanguage) -> String { l == .fr ? "Sélectionner un client" : "Select client" }
    static func changeClient(_ l: AppLanguage) -> String { l == .fr ? "Changer de client" : "Change client" }
    static func clientRequired(_ l: AppLanguage) -> String { l == .fr ? "Sélectionnez un client" : "Select a client" }
    static func periodExistsForClient(_ l: AppLanguage) -> String {
        l == .fr ? "Cette période existe déjà pour ce client" : "This period already exists for this client"
    }
    static func periodOverlapsForClient(_ l: AppLanguage) -> String {
        l == .fr ? "Cette plage chevauche déjà une période pour ce client" : "This range already overlaps a period for this client"
    }
    static func cannotSelectClient(_ l: AppLanguage) -> String {
        l == .fr ? "Client non sélectionné" : "Client not selected"
    }
    static func invoiced(_ l: AppLanguage) -> String { l == .fr ? "Facturée" : "Invoiced" }
    static func notInvoiced(_ l: AppLanguage) -> String { l == .fr ? "Non facturée" : "Not invoiced" }
    static func workHours(_ l: AppLanguage) -> String { l == .fr ? "Heures de travail" : "Work hours" }
    static func overtimeLabel(_ l: AppLanguage) -> String { l == .fr ? "Heures supplémentaires" : "Overtime hours" }
    static func workHoursForPeriod(_ l: AppLanguage, period: String) -> String {
        l == .fr ? "Heures de travail - \(period)" : "Work hours - \(period)"
    }
    static func overtimeForPeriod(_ l: AppLanguage, period: String) -> String {
        l == .fr ? "Heures supplémentaires - \(period)" : "Overtime hours - \(period)"
    }
    static func workHoursOnDate(_ l: AppLanguage, date: String) -> String {
        l == .fr ? "Heures de travail - \(date)" : "Work hours - \(date)"
    }
    static func workHoursOnDateWithActivity(_ l: AppLanguage, date: String, activity: String) -> String {
        l == .fr ? "Heures de travail - \(date) - \(activity)" : "Work hours - \(date) - \(activity)"
    }
    static func overtimeHoursOnDate(_ l: AppLanguage, date: String) -> String {
        l == .fr ? "Heures supplémentaires - \(date)" : "Overtime hours - \(date)"
    }
    static func overtimeHoursOnDateWithActivity(_ l: AppLanguage, date: String, activity: String) -> String {
        l == .fr ? "Heures supplémentaires - \(date) - \(activity)" : "Overtime hours - \(date) - \(activity)"
    }
    static func overtimeHoursForWeek(_ l: AppLanguage, dateRange: String) -> String {
        l == .fr ? "Heures supplémentaires - \(dateRange)" : "Overtime hours - \(dateRange)"
    }

    // Compteur
    static func timeTracker(_ l: AppLanguage) -> String { l == .fr ? "Compteur" : "Timer" }
    static func startTimer(_ l: AppLanguage) -> String { l == .fr ? "Démarrer" : "Start" }
    static func stopTimer(_ l: AppLanguage) -> String { l == .fr ? "Arrêter" : "Stop" }
    static func continueTimer(_ l: AppLanguage) -> String { l == .fr ? "Continuer" : "Continue" }
    static func timerRunning(_ l: AppLanguage) -> String { l == .fr ? "Compteur en cours" : "Timer running" }
    static func editStartTime(_ l: AppLanguage) -> String {
        l == .fr ? "Modifier l'heure de début" : "Edit start time"
    }
    static func readyToTrack(_ l: AppLanguage) -> String {
        l == .fr ? "Prêt à chronométrer cette période" : "Ready to track this period"
    }
    static func timerRunningElsewhere(_ l: AppLanguage, period: String) -> String {
        l == .fr ? "Un compteur tourne déjà sur \(period). Arrêtez-le avant d'en démarrer un autre." :
        "A timer is already running on \(period). Stop it before starting another one."
    }
    static func timerOutsidePeriod(_ l: AppLanguage) -> String {
        l == .fr ? "Le compteur live est disponible uniquement si aujourd'hui est dans cette période." :
        "The live timer is available only when today is inside this period."
    }
    static func project(_ l: AppLanguage) -> String { l == .fr ? "Projet" : "Project" }
    static func task(_ l: AppLanguage) -> String { l == .fr ? "Tâche" : "Task" }
    static func timeEntryDescription(_ l: AppLanguage) -> String { l == .fr ? "Description" : "Description" }
    static func tags(_ l: AppLanguage) -> String { l == .fr ? "Tags" : "Tags" }
    static func billable(_ l: AppLanguage) -> String { l == .fr ? "Facturable" : "Billable" }
    static func nonBillable(_ l: AppLanguage) -> String { l == .fr ? "Non facturable" : "Non-billable" }
    static func manualMode(_ l: AppLanguage) -> String { l == .fr ? "Manuel" : "Manual" }
    static func timerMode(_ l: AppLanguage) -> String { l == .fr ? "Timer" : "Timer" }
    static func duration(_ l: AppLanguage) -> String { l == .fr ? "Durée" : "Duration" }
    static func durationExamples(_ l: AppLanguage) -> String {
        l == .fr ? "Exemples: 2h, 1h30m, 2:45, .5" : "Examples: 2h, 1h30m, 2:45, .5"
    }
    static func addTimeEntry(_ l: AppLanguage) -> String { l == .fr ? "Ajouter" : "Add" }
    static func exportCSV(_ l: AppLanguage) -> String { l == .fr ? "Exporter CSV" : "Export CSV" }
    static func invoiceTimeEntries(_ l: AppLanguage) -> String { l == .fr ? "Facturer les heures" : "Invoice time" }
    static func estimatedAmount(_ l: AppLanguage) -> String { l == .fr ? "Montant estimé" : "Estimated amount" }
    static func entryDeleted(_ l: AppLanguage) -> String { l == .fr ? "Entrée supprimée." : "Entry deleted." }
    static func undo(_ l: AppLanguage) -> String { l == .fr ? "Annuler" : "Undo" }
    static func invalidDuration(_ l: AppLanguage) -> String { l == .fr ? "Durée invalide" : "Invalid duration" }
    static func invalidTimeRange(_ l: AppLanguage) -> String {
        l == .fr ? "L'heure de fin doit être après l'heure de début." :
        "End time must be after start time."
    }
    static func activeTimerExists(_ l: AppLanguage) -> String {
        l == .fr ? "Un timer est déjà en cours. Arrêtez-le avant d'en démarrer un autre." :
        "A timer is already running. Stop it before starting another one."
    }
    static func saved(_ l: AppLanguage) -> String { l == .fr ? "Enregistré" : "Saved" }
    static func notSaved(_ l: AppLanguage) -> String { l == .fr ? "Non enregistré" : "Not saved" }
    static func startedEarlier(_ l: AppLanguage) -> String { l == .fr ? "Commencé avant" : "Started earlier" }
    static func startedEarlierHint(_ l: AppLanguage) -> String {
        l == .fr ? "Ajuste le timer en cours sans créer une nouvelle entrée." :
        "Adjusts the running timer without creating a new entry."
    }
    static func untitledTask(_ l: AppLanguage) -> String { l == .fr ? "Tâche sans titre" : "Untitled task" }
    static func entries(_ l: AppLanguage) -> String { l == .fr ? "Entrées" : "Entries" }
    static func newTimeEntry(_ l: AppLanguage) -> String { l == .fr ? "Nouvelle entrée" : "New entry" }
    static func editTimeEntry(_ l: AppLanguage) -> String { l == .fr ? "Modifier l'entrée" : "Edit entry" }
    static func noTimeEntries(_ l: AppLanguage) -> String { l == .fr ? "Aucune entrée" : "No entries" }
    static func noTimeEntriesHint(_ l: AppLanguage) -> String {
        l == .fr ? "Démarrez le compteur ou ajoutez une entrée." : "Start the timer or add an entry."
    }
    static func searchTimeEntries(_ l: AppLanguage) -> String {
        l == .fr ? "Rechercher une tâche ou un projet" : "Search a task or project"
    }
    static func hoursManagedByTimer(_ l: AppLanguage) -> String {
        l == .fr ? "Ces heures sont calculées depuis les entrées du compteur." :
        "These hours are calculated from timer entries."
    }
    static func today(_ l: AppLanguage) -> String { l == .fr ? "Aujourd'hui" : "Today" }
    static func thisWeek(_ l: AppLanguage) -> String { l == .fr ? "Cette semaine" : "This week" }
    static func period(_ l: AppLanguage) -> String { l == .fr ? "Période" : "Period" }
    static func now(_ l: AppLanguage) -> String { l == .fr ? "maintenant" : "now" }
}
