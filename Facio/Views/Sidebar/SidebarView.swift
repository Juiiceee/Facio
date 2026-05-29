import SwiftUI

// MARK: - Navigation State

enum SidebarSection: String, Hashable, Identifiable {
    case factures
    case devis
    case clients
    case heures
    case planning
    case dashboard
    case parametres

    var id: String { rawValue }

    var label: String {
        label(for: .fr)
    }

    func label(for lang: AppLanguage) -> String {
        switch self {
        case .factures: return L10n.sidebarInvoices(lang)
        case .devis: return L10n.sidebarQuotes(lang)
        case .clients: return L10n.sidebarClients(lang)
        case .heures: return L10n.sidebarTimeTracking(lang)
        case .planning: return L10n.sidebarPlanning(lang)
        case .dashboard: return L10n.sidebarDashboard(lang)
        case .parametres: return L10n.sidebarSettings(lang)
        }
    }

    var icon: String {
        switch self {
        case .factures: return "doc.text"
        case .devis: return "doc.text.magnifyingglass"
        case .clients: return "person.2"
        case .heures: return "clock"
        case .planning: return "calendar.badge.clock"
        case .dashboard: return "chart.bar"
        case .parametres: return "gearshape"
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Binding var selection: SidebarSection?
    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var companyName: String {
        let trimmed = dataStore.companyInfo.nom.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Facio" : trimmed
    }

    var body: some View {
        List(selection: $selection) {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "building.2")
                            .foregroundStyle(Color.appPrimary(from: dataStore.companyInfo))
                        Text(companyName)
                            .font(.headline)
                            .lineLimit(1)
                    }

                    if let running = dataStore.runningTimeEntryContext {
                        Label(running.timesheet.clientDisplayName.isEmpty ? L10n.timerRunning(lang) : running.timesheet.clientDisplayName, systemImage: "timer")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 6)
            }

            Section {
                Label(SidebarSection.dashboard.label(for: lang), systemImage: SidebarSection.dashboard.icon)
                    .tag(SidebarSection.dashboard)
            }

            Section(L10n.sidebarDocuments(lang)) {
                Label(SidebarSection.factures.label(for: lang), systemImage: SidebarSection.factures.icon)
                    .tag(SidebarSection.factures)

                Label(SidebarSection.devis.label(for: lang), systemImage: SidebarSection.devis.icon)
                    .tag(SidebarSection.devis)
            }

            Section(L10n.sidebarManagement(lang)) {
                Label(SidebarSection.clients.label(for: lang), systemImage: SidebarSection.clients.icon)
                    .tag(SidebarSection.clients)

                Label(SidebarSection.heures.label(for: lang), systemImage: SidebarSection.heures.icon)
                    .tag(SidebarSection.heures)

                Label(SidebarSection.planning.label(for: lang), systemImage: SidebarSection.planning.icon)
                    .tag(SidebarSection.planning)
            }

            Section {
                Label(SidebarSection.parametres.label(for: lang), systemImage: SidebarSection.parametres.icon)
                    .tag(SidebarSection.parametres)
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
    }
}
