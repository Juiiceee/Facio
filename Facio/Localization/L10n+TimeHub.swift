import Foundation

extension L10n {
    static func sidebarPlanning(_ l: AppLanguage) -> String { l == .fr ? "Hub temps" : "Time Hub" }
    static func timeHubOverview(_ l: AppLanguage) -> String { l == .fr ? "Vue d'ensemble" : "Overview" }
    static func timeHubTasks(_ l: AppLanguage) -> String { l == .fr ? "Tâches" : "Tasks" }
    static func timeHubCalendar(_ l: AppLanguage) -> String { l == .fr ? "Calendrier" : "Calendar" }
    static func timeHubLog(_ l: AppLanguage) -> String { l == .fr ? "Journal" : "Log" }
    static func timeHubOpenPlanning(_ l: AppLanguage) -> String { l == .fr ? "Ouvrir Planning" : "Open Time Hub" }
    static func timeHubOpenCalendar(_ l: AppLanguage) -> String { l == .fr ? "Ouvrir le calendrier du temps" : "Open time calendar" }
    static func timeHubStartTimer(_ l: AppLanguage) -> String { l == .fr ? "Démarrer le compteur" : "Start timer" }
    static func timeHubStopTimer(_ l: AppLanguage) -> String { l == .fr ? "Arrêter le compteur" : "Stop timer" }
    static func timeHubAddManualEntry(_ l: AppLanguage) -> String { l == .fr ? "Ajouter une entrée manuelle" : "Add manual time entry" }
    static func timeHubCreateTask(_ l: AppLanguage) -> String { l == .fr ? "Créer une tâche" : "Create task" }
    static func timeHubInvoiceUninvoiced(_ l: AppLanguage) -> String {
        l == .fr ? "Créer une facture avec les heures non facturées" : "Create invoice from uninvoiced time"
    }
    static func periodDay(_ l: AppLanguage) -> String { l == .fr ? "Jour" : "Day" }
    static func periodWeek(_ l: AppLanguage) -> String { l == .fr ? "Semaine" : "Week" }
    static func periodMonth(_ l: AppLanguage) -> String { l == .fr ? "Mois" : "Month" }
    static func thisMonth(_ l: AppLanguage) -> String { l == .fr ? "Ce mois" : "This month" }
    static func billableTime(_ l: AppLanguage) -> String { l == .fr ? "Temps facturable" : "Billable time" }
    static func nonBillableTime(_ l: AppLanguage) -> String { l == .fr ? "Temps non facturable" : "Non-billable time" }
    static func uninvoicedTime(_ l: AppLanguage) -> String { l == .fr ? "Temps non facturé" : "Uninvoiced time" }
    static func uninvoicedEntries(_ l: AppLanguage) -> String { l == .fr ? "Entrées non facturées" : "Uninvoiced entries" }
    static func activeTasks(_ l: AppLanguage) -> String { l == .fr ? "Tâches en cours" : "Active tasks" }
    static func byClient(_ l: AppLanguage) -> String { l == .fr ? "Par client" : "By client" }
    static func byProject(_ l: AppLanguage) -> String { l == .fr ? "Par projet" : "By project" }
    static func toInvoice(_ l: AppLanguage) -> String { l == .fr ? "À facturer" : "To invoice" }
    static func recentActivity(_ l: AppLanguage) -> String { l == .fr ? "Activité récente" : "Recent activity" }
    static func todayTimeline(_ l: AppLanguage) -> String { l == .fr ? "Aujourd'hui" : "Today" }
    static func openLogToday(_ l: AppLanguage) -> String { l == .fr ? "Voir le journal" : "Open log" }
    static func openCalendarToday(_ l: AppLanguage) -> String { l == .fr ? "Voir le calendrier" : "Open calendar" }
    static func allClients(_ l: AppLanguage) -> String { l == .fr ? "Tous les clients" : "All clients" }
    static func allBillableStates(_ l: AppLanguage) -> String { l == .fr ? "Toutes les entrées" : "All entries" }
    static func allInvoiceStates(_ l: AppLanguage) -> String { l == .fr ? "Tous statuts de facture" : "All invoice states" }
    static func searchTimeHub(_ l: AppLanguage) -> String { l == .fr ? "Rechercher temps, client, projet..." : "Search time, client, project..." }
    static func selectTrackingPeriod(_ l: AppLanguage) -> String { l == .fr ? "Période de suivi" : "Tracking period" }
    static func noTrackingPeriod(_ l: AppLanguage) -> String {
        l == .fr ? "Créez une période de suivi pour démarrer un timer." : "Create a tracking period before starting a timer."
    }
    static func noTimeToday(_ l: AppLanguage) -> String { l == .fr ? "Aucune entrée aujourd'hui." : "No entries today." }
    static func noTimeTodayHint(_ l: AppLanguage) -> String {
        l == .fr ? "Démarrez le compteur ou ajoutez une entrée manuelle." : "Start the timer or add a manual entry."
    }
    static func noBillableTimePending(_ l: AppLanguage) -> String {
        l == .fr ? "Aucune heure facturable en attente." : "No pending billable time."
    }
    static func noTaskYet(_ l: AppLanguage) -> String { l == .fr ? "Aucune tâche pour le moment." : "No tasks yet." }
    static func noTaskYetHint(_ l: AppLanguage) -> String {
        l == .fr ? "Démarrez un timer avec une tâche pour alimenter cette vue." : "Start a timer with a task to feed this view."
    }
    static func noTimeEntriesForPeriod(_ l: AppLanguage) -> String {
        l == .fr ? "Aucune entrée sur cette période." : "No entries in this period."
    }
    static func trackedTime(_ l: AppLanguage) -> String { l == .fr ? "Temps suivi" : "Tracked time" }
    static func estimated(_ l: AppLanguage) -> String { l == .fr ? "Estimé" : "Estimated" }
    static func weekView(_ l: AppLanguage) -> String { l == .fr ? "Semaine" : "Week" }
    static func monthView(_ l: AppLanguage) -> String { l == .fr ? "Mois" : "Month" }
    static func dailyTotal(_ l: AppLanguage) -> String { l == .fr ? "Total jour" : "Daily total" }
    static func entriesCount(_ l: AppLanguage, count: Int) -> String {
        l == .fr ? "\(count) entrée\(count > 1 ? "s" : "")" : "\(count) entr\(count == 1 ? "y" : "ies")"
    }
    static func startThisTask(_ l: AppLanguage) -> String { l == .fr ? "Démarrer cette tâche" : "Start this task" }
    static func markDone(_ l: AppLanguage) -> String { l == .fr ? "Terminer" : "Mark done" }
    static func archive(_ l: AppLanguage) -> String { l == .fr ? "Archiver" : "Archive" }
    static func previousPeriod(_ l: AppLanguage) -> String { l == .fr ? "Période précédente" : "Previous period" }
    static func nextPeriod(_ l: AppLanguage) -> String { l == .fr ? "Période suivante" : "Next period" }
    static func createInvoice(_ l: AppLanguage) -> String { l == .fr ? "Créer une facture" : "Create invoice" }
}
