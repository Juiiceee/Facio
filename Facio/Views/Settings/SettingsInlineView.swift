import SwiftUI

/// Vue parametres integree dans la fenetre principale
struct SettingsInlineView: View {
    @Environment(DataStore.self) private var dataStore
    @Environment(SyncService.self) private var syncService
    @Environment(AuthService.self) private var authService
    @Binding var selectedTab: Int

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var tabs: [(label: String, icon: String, help: String)] {
        [
            (L10n.settingsCompany(lang), "building.2", L10n.settingsCompanyHelp(lang)),
            (L10n.settingsCustomisation(lang), "paintpalette", L10n.settingsCustomisationHelp(lang)),
            (L10n.settingsPayment(lang), "creditcard", L10n.settingsPaymentHelp(lang)),
            (L10n.settingsEmail(lang), "paperplane", L10n.settingsEmailHelp(lang)),
            (L10n.settingsDefaults(lang), "slider.horizontal.3", L10n.settingsDefaultsHelp(lang)),
            (L10n.settingsServices(lang), "star", L10n.settingsServicesHelp(lang)),
            (L10n.settingsLanguage(lang), "globe", L10n.settingsLanguageHelp(lang)),
            (L10n.settingsSync(lang), "arrow.triangle.2.circlepath", L10n.settingsSyncHelp(lang)),
            (L10n.settingsSecurity(lang), "lock.shield", L10n.settingsSecurityHelp(lang)),
            (L10n.settingsAbout(lang), "info.circle", L10n.settingsAboutHelp(lang))
        ]
    }

    private var selectedTabInfo: (label: String, icon: String, help: String) {
        tabs.indices.contains(selectedTab) ? tabs[selectedTab] : tabs[0]
    }

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebarColumn(
                title: L10n.settings(lang),
                tabs: tabs,
                selectedTab: $selectedTab
            )

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    settingsHeader
                    selectedSettingsView
                }
                .frame(maxWidth: FacioLayout.contentMaxWidth, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Seul écran avec sa propre sidebar interne : on re-pose le conteneur
        // responsive sur le HStack racine (indispensable aussi pour la scène
        // Réglages native, qui n'hérite pas du conteneur de ContentView).
        .facioResponsiveContainer()
    }

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space6) {
            Label(selectedTabInfo.label, systemImage: selectedTabInfo.icon)
                .font(FacioFont.screenTitle)
            Text(selectedTabInfo.help)
                .font(FacioFont.screenSubtitle)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, FacioLayout.space24)
        .padding(.top, FacioLayout.space24)
        .padding(.bottom, FacioLayout.space4)
    }

    @ViewBuilder
    private var selectedSettingsView: some View {
        switch selectedTab {
        case 0: CompanySettingsView()
        case 1: CustomisationSettingsView()
        case 2: PaymentSettingsView()
        case 3: EmailSettingsView()
        case 4: DefaultsSettingsView()
        case 5: PrestationsSettingsView()
        case 6: LanguageSettingsView()
        case 7: SyncSettingsView(syncService: syncService, authService: authService)
        case 8: SecuritySettingsView()
        case 9: AboutSettingsView()
        default: EmptyView()
        }
    }
}

/// Sidebar interne des réglages : repliée en icônes seules sous le breakpoint
/// compact. Sous-vue séparée pour lire la classe de largeur RE-posée par le
/// conteneur responsive du HStack racine (un `@Environment` lu directement
/// dans `SettingsInlineView` verrait celui du parent).
private struct SettingsSidebarColumn: View {
    let title: String
    let tabs: [(label: String, icon: String, help: String)]
    @Binding var selectedTab: Int

    @Environment(\.facioWidthClass) private var widthClass

    private var isCompact: Bool { widthClass == .compact }

    var body: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space16) {
            // En compact, le titre de colonne est masqué (la sidebar réduite
            // aux icônes ne peut pas l'afficher) — mais il reste PRÉSENT dans
            // l'arbre, replié à zéro.
            //
            // Un `if !isCompact` insérait et retirait la vue, donc changeait la
            // structure de l'arbre. Or `isCompact` vient d'une largeur mesurée
            // qui balaye le seuil de 640 pt pendant l'animation de la colonne du
            // milieu : SwiftUI restructurait l'arbre à l'intérieur de la passe
            // de layout d'AppKit, ce qui lève une exception fatale. Ici seule la
            // MISE EN PAGE change, jamais l'identité.
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, FacioLayout.space16)
                .padding(.top, isCompact ? 0 : FacioLayout.space16)
                .frame(height: isCompact ? 0 : nil)
                .opacity(isCompact ? 0 : 1)
                .clipped()
                .accessibilityHidden(isCompact)

            List(selection: Binding<Int?>(
                get: { selectedTab },
                set: { selectedTab = $0 ?? selectedTab }
            )) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    tabLabel(tab)
                        .tag(index)
                }
            }
            .listStyle(.sidebar)
        }
        .frame(width: isCompact ? FacioLayout.settingsSidebarCompactWidth : FacioLayout.settingsSidebarWidth)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    /// Libellé d'un onglet : icône seule + infobulle en compact.
    ///
    /// Un style de libellé porté par une VALEUR et non par une branche `if` :
    /// deux `labelStyle` différents produisent deux types de vue différents,
    /// donc un changement d'identité au franchissement du seuil — exactement ce
    /// qui plantait.
    private func tabLabel(_ tab: (label: String, icon: String, help: String)) -> some View {
        Label(tab.label, systemImage: tab.icon)
            .labelStyle(SettingsTabLabelStyle(iconOnly: isCompact))
            .help(tab.label)
    }
}

/// Icône seule ou icône + titre, sans changer le type de la vue.
private struct SettingsTabLabelStyle: LabelStyle {
    let iconOnly: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: iconOnly ? 0 : FacioLayout.space8) {
            configuration.icon
            configuration.title
                .frame(maxWidth: iconOnly ? 0 : .infinity, alignment: .leading)
                .opacity(iconOnly ? 0 : 1)
                .clipped()
        }
    }
}
