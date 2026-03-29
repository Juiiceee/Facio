import SwiftUI

// MARK: - Navigation State

enum SidebarSection: String, Hashable, Identifiable {
    case factures
    case devis
    case clients
    case dashboard
    case parametres

    var id: String { rawValue }

    var label: String {
        switch self {
        case .factures: return "Factures"
        case .devis: return "Devis"
        case .clients: return "Clients"
        case .dashboard: return "Tableau de bord"
        case .parametres: return "Parametres"
        }
    }

    var icon: String {
        switch self {
        case .factures: return "doc.text"
        case .devis: return "doc.text.magnifyingglass"
        case .clients: return "person.2"
        case .dashboard: return "chart.bar"
        case .parametres: return "gearshape"
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Binding var selection: SidebarSection?

    var body: some View {
        List(selection: $selection) {
            Section("Documents") {
                Label(SidebarSection.factures.label, systemImage: SidebarSection.factures.icon)
                    .tag(SidebarSection.factures)

                Label(SidebarSection.devis.label, systemImage: SidebarSection.devis.icon)
                    .tag(SidebarSection.devis)
            }

            Section("Gestion") {
                Label(SidebarSection.clients.label, systemImage: SidebarSection.clients.icon)
                    .tag(SidebarSection.clients)

                Label(SidebarSection.dashboard.label, systemImage: SidebarSection.dashboard.icon)
                    .tag(SidebarSection.dashboard)
            }

            Section {
                Label(SidebarSection.parametres.label, systemImage: SidebarSection.parametres.icon)
                    .tag(SidebarSection.parametres)
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
    }
}
