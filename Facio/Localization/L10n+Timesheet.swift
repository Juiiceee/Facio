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
    static func overtimeCost(_ l: AppLanguage) -> String { l == .fr ? "Coût sup." : "Overtime cost" }
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
    /// Le numéro que porte l'agenda du client, pas le rang interne à la période.
    static func weekISO(_ l: AppLanguage, number: Int) -> String {
        l == .fr ? "Semaine ISO \(number)" : "ISO week \(number)"
    }

    // Parametres de calcul
    static func calculationParams(_ l: AppLanguage) -> String { l == .fr ? "Paramètres de calcul" : "Calculation parameters" }
    static func weeklyThreshold(_ l: AppLanguage) -> String { l == .fr ? "Seuil hebdo (h)" : "Weekly threshold (h)" }
    static func normalRate(_ l: AppLanguage) -> String { l == .fr ? "Taux normal" : "Normal rate" }
    static func overtimeRate(_ l: AppLanguage) -> String { l == .fr ? "Taux sup." : "Overtime rate" }
    /// « Coeff. net 0,756 » était du jargon comptable brut, sans unité, sans
    /// infobulle et sans aide — au dernier rang d'une page dont il pilotait
    /// pourtant tous les chiffres.
    static func netCoeff(_ l: AppLanguage) -> String { l == .fr ? "Part nette" : "Net share" }
    static func netCoeffHint(_ l: AppLanguage) -> String {
        l == .fr
            ? "Part du brut qui vous reste une fois les cotisations déduites. 0,756 = 75,6 %."
            : "Share of the gross amount left after contributions. 0.756 = 75.6%."
    }
    static func weeklyThresholdHint(_ l: AppLanguage) -> String {
        l == .fr
            ? "Au-delà de ce nombre d'heures par semaine, les heures passent au taux majoré."
            : "Beyond this many hours a week, hours are billed at the higher rate."
    }
    /// Les taux sont recopiés de la période précédente du même client, en
    /// silence : qui a changé son tarif facturera à l'ancien sans s'en apercevoir.
    static func ratesCarriedOver(_ l: AppLanguage, from: String) -> String {
        l == .fr ? "Taux repris de \(from)." : "Rates carried over from \(from)."
    }

    // Liste periodes
    static func newPeriod(_ l: AppLanguage) -> String { l == .fr ? "Nouvelle période" : "New period" }
    static func monthlyPeriod(_ l: AppLanguage) -> String { l == .fr ? "Mois" : "Month" }
    static func customPeriod(_ l: AppLanguage) -> String { l == .fr ? "Personnalisée" : "Custom" }
    static func startDate(_ l: AppLanguage) -> String { l == .fr ? "Début" : "Start" }
    static func endDate(_ l: AppLanguage) -> String { l == .fr ? "Fin" : "End" }
    static func periodDates(_ l: AppLanguage) -> String { l == .fr ? "Dates de la période" : "Period dates" }
    static func updatePeriodDates(_ l: AppLanguage) -> String { l == .fr ? "Mettre à jour" : "Update" }
    static func periodRangeLossPreview(_ l: AppLanguage, days: Int, hours: String) -> String {
        l == .fr ? "\(days) jour(s) avec \(hours)h sortiront de la période." :
        "\(days) day(s) with \(hours)h will leave the period."
    }
    static func periodRangeLossTitle(_ l: AppLanguage) -> String {
        l == .fr ? "Des heures vont être supprimées" : "Some hours will be removed"
    }
    static func periodRangeLossMessage(_ l: AppLanguage, days: Int, hours: String) -> String {
        l == .fr ? "La nouvelle plage exclut \(days) jour(s) avec \(hours)h. Ces valeurs seront remises à zéro." :
        "The new range excludes \(days) day(s) with \(hours)h. Those values will be reset to zero."
    }
    /// « Modifier et supprimer » ne disait pas ce qui serait supprimé — sur un
    /// bouton destructif, c'est le seul mot qui compte.
    static func updatePeriodAndDeleteValues(_ l: AppLanguage) -> String {
        l == .fr ? "Remettre ces heures à zéro" : "Reset those hours to zero"
    }
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
    static func continueTimer(_ l: AppLanguage) -> String { l == .fr ? "Continuer" : "Continue" }
    static func timerRunning(_ l: AppLanguage) -> String { l == .fr ? "Compteur en cours" : "Timer running" }
    static func editStartTime(_ l: AppLanguage) -> String {
        l == .fr ? "Modifier l'heure de début" : "Edit start time"
    }
    static func readyToTrack(_ l: AppLanguage) -> String {
        l == .fr ? "Prêt à chronométrer cette période" : "Ready to track this period"
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
    static func durationExamples(_ l: AppLanguage) -> String {
        l == .fr ? "Exemples: 2h, 1h30m, 2:45, .5" : "Examples: 2h, 1h30m, 2:45, .5"
    }
    static func addTimeEntry(_ l: AppLanguage) -> String { l == .fr ? "Ajouter" : "Add" }
    static func estimatedAmount(_ l: AppLanguage) -> String { l == .fr ? "Montant estimé" : "Estimated amount" }
    static func entryDeleted(_ l: AppLanguage) -> String { l == .fr ? "Entrée supprimée." : "Entry deleted." }
    /// « Rétablir », pas « Annuler ».
    ///
    /// En français, `undo` et `cancel` se traduisaient tous les deux par
    /// « Annuler » — et les deux apparaissaient sur le même écran, avec des sens
    /// opposés : la barre d'annulation *défait* une suppression, le pied d'un
    /// éditeur *abandonne* une saisie.
    static func undo(_ l: AppLanguage) -> String { l == .fr ? "Rétablir" : "Undo" }
    static func invalidDuration(_ l: AppLanguage) -> String { l == .fr ? "Durée invalide" : "Invalid duration" }
    static func invalidTimeRange(_ l: AppLanguage) -> String {
        l == .fr ? "L'heure de fin doit être après l'heure de début." :
        "End time must be after start time."
    }
    static func notSaved(_ l: AppLanguage) -> String { l == .fr ? "Non enregistré" : "Not saved" }
    static func untitledTask(_ l: AppLanguage) -> String { l == .fr ? "Tâche sans titre" : "Untitled task" }
    static func entries(_ l: AppLanguage) -> String { l == .fr ? "Entrées" : "Entries" }
    static func editTimeEntry(_ l: AppLanguage) -> String { l == .fr ? "Modifier l'entrée" : "Edit entry" }
    static func hoursManagedByTimer(_ l: AppLanguage) -> String {
        l == .fr ? "Ces heures sont calculées depuis les entrées du compteur." :
        "These hours are calculated from timer entries."
    }
    /// Légende de la grille : un jour piloté par le minuteur n'était que grisé,
    /// donc indiscernable d'un champ désactivé par erreur.
    static func timerDrivenLegend(_ l: AppLanguage) -> String {
        l == .fr ? "piloté par le minuteur, en lecture seule" : "driven by the timer, read-only"
    }
    static func timerDrivenDay(_ l: AppLanguage) -> String {
        l == .fr ? "Minuteur" : "Timer"
    }
    // MARK: - Feuille « Facturer »

    /// Cinq points d'entrée produisaient cinq factures différentes de la même
    /// période, sans qu'aucun ne montre ce qu'il allait produire.
    static func billingSheetTitle(_ l: AppLanguage, period: String) -> String {
        l == .fr ? "Facturer \(period)" : "Bill \(period)"
    }
    static func billingSource(_ l: AppLanguage) -> String { l == .fr ? "Source" : "Source" }
    static func billingSourceGrid(_ l: AppLanguage) -> String { l == .fr ? "Grille horaire" : "Hour grid" }
    static func billingSourceTimer(_ l: AppLanguage) -> String { l == .fr ? "Entrées du minuteur" : "Timer entries" }
    static func billingDetailLevel(_ l: AppLanguage) -> String { l == .fr ? "Niveau de détail" : "Detail level" }
    static func billingPreview(_ l: AppLanguage) -> String { l == .fr ? "Aperçu des lignes" : "Line preview" }
    static func billingLineCount(_ l: AppLanguage, count: Int) -> String {
        l == .fr ? "\(count) ligne\(count > 1 ? "s" : "")" : "\(count) line\(count > 1 ? "s" : "")"
    }
    static func billingGroupingDetailed(_ l: AppLanguage) -> String { l == .fr ? "Par entrée" : "Per entry" }
    static func billingGroupingByProject(_ l: AppLanguage) -> String { l == .fr ? "Par projet" : "Per project" }
    static func billingGroupingSingleLine(_ l: AppLanguage) -> String { l == .fr ? "Une seule ligne" : "Single line" }
    static func billingLockNotice(_ l: AppLanguage) -> String {
        l == .fr
            ? "La période sera marquée « Facturée » et verrouillée. Les heures et les taux resteront consultables mais non modifiables."
            : "The period will be marked “Invoiced” and locked. Hours and rates stay readable but can no longer be edited."
    }
    static func billingDraftNotice(_ l: AppLanguage) -> String {
        l == .fr ? "Brouillon créé, éditable avant envoi." : "Draft created, editable before sending."
    }
    static func billingCreate(_ l: AppLanguage) -> String { l == .fr ? "Créer la facture" : "Create the invoice" }
    static func billingNothingToBill(_ l: AppLanguage) -> String {
        l == .fr ? "Aucune ligne à facturer avec cette source." : "Nothing to bill from this source."
    }
    static func billingAction(_ l: AppLanguage) -> String { l == .fr ? "Facturer…" : "Bill…" }

    static func today(_ l: AppLanguage) -> String { l == .fr ? "Aujourd'hui" : "Today" }
    static func period(_ l: AppLanguage) -> String { l == .fr ? "Période" : "Period" }
    static func now(_ l: AppLanguage) -> String { l == .fr ? "maintenant" : "now" }
}
