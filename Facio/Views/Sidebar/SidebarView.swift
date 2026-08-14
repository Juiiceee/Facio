import SwiftUI

// MARK: - Navigation State

/// Les cinq destinations de Facio.
///
/// Les groupes « Documents » et « Gestion » ont disparu : un client n'est pas
/// plus de la « gestion » qu'une facture n'est un « document », et « Gestion »
/// ne veut rien dire pour l'utilisateur. Le rythme devient régulier — identité,
/// cinq items, filet, minuteur, sync.
///
/// **Ventes** réunit factures et devis : ils partagent le même éditeur, le même
/// modèle et les mêmes statuts, donc ils deviennent un segment en tête de liste
/// et non deux entrées. **Temps** réunit les périodes et l'agrégation, qui
/// lisaient exactement la même donnée depuis deux sections différentes.
enum SidebarSection: String, Hashable, Identifiable, CaseIterable {
    case dashboard
    case ventes
    case clients
    case temps
    case parametres

    var id: String { rawValue }

    func label(for lang: AppLanguage) -> String {
        switch self {
        case .dashboard: return L10n.sidebarDashboard(lang)
        case .ventes: return L10n.sidebarSales(lang)
        case .clients: return L10n.sidebarClients(lang)
        case .temps: return L10n.sidebarTime(lang)
        case .parametres: return L10n.sidebarSettings(lang)
        }
    }

    func help(for lang: AppLanguage) -> String? {
        switch self {
        case .ventes: return L10n.sidebarSalesHelp(lang)
        case .temps: return L10n.sidebarTimeHelp(lang)
        default: return nil
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .ventes: return "doc.text"
        case .clients: return "person.2"
        case .temps: return "clock"
        case .parametres: return "gearshape"
        }
    }

    /// Les seules sections qui ont une colonne liste. Ailleurs, la colonne se
    /// replie en rail — elle ne disparaît pas, sinon le châssis se reconstruit.
    var hasList: Bool {
        self == .ventes || self == .temps
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selection: SidebarSection?
    /// Rejoindre la saisie en cours depuis le minuteur de fenêtre.
    var onOpenRunningEntry: () -> Void = {}

    @Environment(DataStore.self) private var dataStore
    @Environment(SyncService.self) private var syncService

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var companyName: String {
        let trimmed = dataStore.companyInfo.nom.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Facio" : trimmed
    }

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                Section {
                    identityHeader
                }

                Section {
                    ForEach(SidebarSection.allCases) { section in
                        row(for: section)
                            .tag(section)
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()
            FacioTimerControl(onOpen: onOpenRunningEntry)
            Divider()
            syncRow
        }
        .navigationSplitViewColumnWidth(
            min: FacioLayout.sidebarMin,
            ideal: FacioLayout.sidebarIdeal,
            max: FacioLayout.sidebarMax
        )
    }

    // MARK: Identité

    private var identityHeader: some View {
        HStack(spacing: FacioLayout.space8) {
            Text(initials)
                .font(FacioFont.label)
                .foregroundStyle(Color.textOnAccent)
                .frame(width: 26, height: 26)
                .background(Color.accent)
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Text(companyName)
                    .font(FacioFont.titlePanel)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Text(dataStore.companyInfo.deviseComptable.rawValue)
                    .font(FacioFont.label)
                    .foregroundStyle(Color.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, FacioLayout.space4)
        .help(companyName)
    }

    private var initials: String {
        let words = companyName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
        return words.joined().uppercased()
    }

    // MARK: Items

    @ViewBuilder
    private func row(for section: SidebarSection) -> some View {
        HStack(spacing: FacioLayout.space8) {
            Label(section.label(for: lang), systemImage: section.icon)
            Spacer(minLength: FacioLayout.space4)
            if let badge = badge(for: section) {
                SidebarBadge(count: badge.count, intent: badge.intent, label: badge.label)
            }
        }
        .help(section.help(for: lang) ?? "")
    }

    /// Trois compteurs, pas plus — chacun rattaché à une action réelle.
    /// Il fallait auparavant ouvrir le tableau de bord pour savoir s'il y avait
    /// quelque chose à faire, alors que la barre latérale est visible en
    /// permanence.
    private func badge(for section: SidebarSection) -> (count: Int, intent: FacioIntent, label: String)? {
        switch section {
        case .ventes:
            let count = dataStore.documents.filter { $0.type == .facture && $0.isOverdue }.count
            guard count > 0 else { return nil }
            return (count, .danger, L10n.sidebarOverdueBadge(lang, count: count))
        case .temps:
            let count = dataStore.timesheets.filter { $0.hasClient && !$0.hasGeneratedInvoice && $0.totalHeures > 0 }.count
            guard count > 0 else { return nil }
            return (count, .info, L10n.sidebarToBillBadge(lang, count: count))
        case .parametres:
            let count = missingLegalDetails
            guard count > 0 else { return nil }
            return (count, .warning, L10n.sidebarSettingsBadge(lang, count: count))
        case .dashboard, .clients:
            return nil
        }
    }

    /// Mentions sans lesquelles une facture française n'est pas valide — et sans
    /// lesquelles l'export Factur-X est refusé, aujourd'hui seulement au moment
    /// de l'export, par une alerte.
    private var missingLegalDetails: Int {
        let company = dataStore.companyInfo
        return [company.nom, company.adresse, company.siret]
            .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .count
    }

    // MARK: Sync

    private var syncRow: some View {
        HStack(spacing: FacioLayout.space8) {
            Image(systemName: syncGlyph)
                .font(FacioFont.label)
                .foregroundStyle(syncTone)
            Text(syncLabel)
                .font(FacioFont.label)
                .foregroundStyle(Color.textTertiary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, FacioLayout.space12)
        .padding(.vertical, FacioLayout.space8)
        .accessibilityElement(children: .combine)
    }

    private var syncGlyph: String {
        guard SyncConfig.isEnabled else { return "icloud.slash" }
        if syncService.isSyncing { return "arrow.triangle.2.circlepath" }
        return syncService.lastSyncDate == nil ? "icloud" : "checkmark.icloud"
    }

    private var syncTone: Color {
        guard SyncConfig.isEnabled else { return .textTertiary }
        return syncService.lastSyncDate == nil ? Color.textTertiary : FacioIntent.success.glyph
    }

    /// Horodaté à la minute : « Synchronisé » sans heure ne permet pas de
    /// distinguer « il y a trente secondes » de « ce matin ».
    private var syncLabel: String {
        guard SyncConfig.isEnabled else { return L10n.sidebarSyncOff(lang) }
        if syncService.isSyncing { return L10n.sidebarSyncing(lang) }
        guard let date = syncService.lastSyncDate else { return L10n.sidebarSyncNever(lang) }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return L10n.sidebarSyncedAt(lang, time: formatter.string(from: date))
    }
}

// MARK: - Badge

/// Compteur de la barre latérale. Capsule teintée : le chiffre porte le sens,
/// la couleur n'est qu'un accélérateur de lecture.
private struct SidebarBadge: View {
    let count: Int
    let intent: FacioIntent
    let label: String

    var body: some View {
        Text("\(count)")
            .font(FacioFont.label)
            .foregroundStyle(intent.onTint)
            .padding(.horizontal, FacioLayout.space8)
            .frame(minHeight: FacioLayout.density.badgeHeight - FacioLayout.space4)
            .background(intent.tint)
            .clipShape(Capsule())
            .accessibilityLabel(label)
    }
}
