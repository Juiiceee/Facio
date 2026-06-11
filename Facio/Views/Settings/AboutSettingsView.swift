import SwiftUI

struct AboutSettingsView: View {
    @Environment(DataStore.self) private var dataStore
    @Environment(AuthService.self) private var authService
    @State private var updateService = UpdateService()
    @State private var showResetAlert = false
    @State private var showUninstallAlert = false
    @State private var resetDone = false

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    var body: some View {
        VStack(spacing: FacioLayout.space20) {
            // MARK: - Header
            SectionPanel {
                HStack(spacing: FacioLayout.space16) {
                    Group {
                        if let icon = NSApp.applicationIconImage {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 64, height: 64)
                        } else {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.appPrimary.gradient)
                                .frame(width: 64, height: 64)
                                .overlay {
                                    Text("F")
                                        // Taille décorative unique (logo de repli) : hors échelle FacioFont, volontairement.
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                        }
                    }

                    VStack(alignment: .leading, spacing: FacioLayout.space4) {
                        Text("Facio")
                            .font(FacioFont.screenTitle)

                        Text(L10n.version(lang, value: appVersion))
                            .font(FacioFont.screenSubtitle)
                            .foregroundStyle(.secondary)

                        Text(L10n.professionalInvoices(lang))
                            .font(FacioFont.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()
                }
            }

            // MARK: - Liens
            SectionPanel(L10n.links(lang), systemImage: "link") {
                VStack(alignment: .leading, spacing: FacioLayout.space16) {
                    HStack(spacing: FacioLayout.space10) {
                        linkButton(
                            title: L10n.sourceCode(lang),
                            icon: "chevron.left.forwardslash.chevron.right",
                            url: "https://github.com/Juiiceee/Facio"
                        )

                        linkButton(
                            title: L10n.releases(lang),
                            icon: "arrow.down.circle",
                            url: "https://github.com/Juiiceee/Facio/releases"
                        )
                    }

                    Divider()

                    HStack(spacing: FacioLayout.space10) {
                        Button {
                            Task {
                                await updateService.checkForUpdates()
                            }
                        } label: {
                            HStack(spacing: FacioLayout.space6) {
                                if updateService.isChecking {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.trianglehead.2.clockwise")
                                }
                                Text(L10n.checkForUpdates(lang))
                            }
                            .font(.subheadline)
                            .padding(.horizontal, FacioLayout.space12)
                            .padding(.vertical, FacioLayout.space8)
                            .contentShape(RoundedRectangle(cornerRadius: FacioLayout.radiusPanel))
                            .facioCardChrome(surface: .surfaceTile)
                        }
                        .buttonStyle(.plain)
                        .disabled(updateService.isChecking)

                        updateStatusView
                    }

                    HStack(spacing: FacioLayout.space10) {

                        linkButton(
                            title: L10n.reportBug(lang),
                            icon: "ladybug",
                            url: "https://github.com/Juiiceee/Facio/issues/new"
                        )
                    }
                }
            }

            // MARK: - Zone dangereuse
            SectionPanel {
                VStack(alignment: .leading, spacing: FacioLayout.space16) {
                    Label(L10n.dangerZone(lang), systemImage: "exclamationmark.triangle")
                        .font(FacioFont.sectionTitle)
                        .foregroundStyle(Color.intentDanger)

                    HStack(spacing: FacioLayout.space10) {
                        Button {
                            showResetAlert = true
                        } label: {
                            HStack(spacing: FacioLayout.space6) {
                                Image(systemName: "arrow.counterclockwise")
                                Text(L10n.reset(lang))
                            }
                            .font(.subheadline)
                            .padding(.horizontal, FacioLayout.space12)
                            .padding(.vertical, FacioLayout.space8)
                            .foregroundStyle(Color.intentDanger)
                            .contentShape(RoundedRectangle(cornerRadius: FacioLayout.radiusPanel))
                            // Surface teintée danger conservée (affordance destructive), chrome standardisé.
                            .facioCardChrome(surface: Color.intentDanger.opacity(0.1))
                        }
                        .buttonStyle(.plain)
                        .help(L10n.resetHelp(lang))

                        Button {
                            showUninstallAlert = true
                        } label: {
                            HStack(spacing: FacioLayout.space6) {
                                Image(systemName: "trash")
                                Text(L10n.uninstall(lang))
                            }
                            .font(.subheadline)
                            .padding(.horizontal, FacioLayout.space12)
                            .padding(.vertical, FacioLayout.space8)
                            .foregroundStyle(Color.intentDanger)
                            .contentShape(RoundedRectangle(cornerRadius: FacioLayout.radiusPanel))
                            // Surface teintée danger conservée (affordance destructive), chrome standardisé.
                            .facioCardChrome(surface: Color.intentDanger.opacity(0.1))
                        }
                        .buttonStyle(.plain)
                        .help(L10n.uninstallHelp(lang))
                    }

                    if resetDone {
                        HStack(spacing: FacioLayout.space6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.intentSuccess)
                            Text(L10n.resetDone(lang))
                                .font(FacioFont.caption)
                                .foregroundStyle(Color.intentSuccess)
                        }
                    }

                    Text(L10n.irreversibleWarning(lang))
                        .font(FacioFont.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(FacioLayout.screenPadding)
        .alert(L10n.resetConfirmTitle(lang), isPresented: $showResetAlert) {
            Button(L10n.cancel(lang), role: .cancel) {}
            Button(L10n.reset(lang), role: .destructive) { resetApp() }
        } message: {
            Text(L10n.resetConfirmMessage(lang))
        }
        .alert(L10n.uninstallConfirmTitle(lang), isPresented: $showUninstallAlert) {
            Button(L10n.cancel(lang), role: .cancel) {}
            Button(L10n.uninstall(lang), role: .destructive) { uninstallApp() }
        } message: {
            Text(L10n.uninstallConfirmMessage(lang))
        }
    }

    // MARK: - Helpers

    private func linkButton(title: String, icon: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: FacioLayout.space6) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, FacioLayout.space12)
            .padding(.vertical, FacioLayout.space8)
            .contentShape(RoundedRectangle(cornerRadius: FacioLayout.radiusPanel))
            .facioCardChrome(surface: .surfaceTile)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var updateStatusView: some View {
        switch updateService.checkResult {
        case .notChecked, .checking:
            EmptyView()
        case .updateAvailable:
            if let url = updateService.releaseURL {
                Link(destination: url) {
                    updateStatusLabel(
                        icon: "arrow.down.circle.fill",
                        color: .intentSuccess,
                        text: L10n.updateAvailable(lang, version: updateService.latestVersion ?? "")
                    )
                }
                .buttonStyle(.plain)
            } else {
                updateStatusLabel(
                    icon: "arrow.down.circle.fill",
                    color: .intentSuccess,
                    text: L10n.updateAvailable(lang, version: updateService.latestVersion ?? "")
                )
            }
        case .upToDate:
            updateStatusLabel(
                icon: "checkmark.circle.fill",
                color: .intentSuccess,
                text: L10n.upToDate(lang)
            )
        case .unavailable:
            updateStatusLabel(
                icon: "questionmark.circle.fill",
                color: .intentWarning,
                text: L10n.updateCheckUnavailable(lang)
            )
        case .failed:
            updateStatusLabel(
                icon: "exclamationmark.triangle.fill",
                color: .intentDanger,
                text: L10n.updateCheckFailed(lang)
            )
        }
    }

    private func updateStatusLabel(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: FacioLayout.space4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(color)
        }
        .font(.subheadline)
    }

    // MARK: - Actions

    private func resetApp() {
        Task { @MainActor in
            await authService.signOutAndWait()
            resetLocalAppState()
            resetDone = true
        }
    }

    private func resetLocalAppState() {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Facio", isDirectory: true)

        let filesToDelete = [
            "documents.json", "clients.json", "company.json",
            "timesheets.json", "sync_state.json", "auth_session.json"
        ]

        for file in filesToDelete {
            let url = supportDir.appendingPathComponent(file)
            try? FileManager.default.removeItem(at: url)
        }

        SyncConfig.resetStoredState()

        let defaults = UserDefaults.standard
        for key in ["facio_user_id", "facio_user_email"] {
            defaults.removeObject(forKey: key)
        }

        dataStore.resetAll()
    }

    private func uninstallApp() {
        Task { @MainActor in
            await authService.signOutAndWait()
            SyncConfig.resetStoredState()

            let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("Facio", isDirectory: true)
            try? FileManager.default.removeItem(at: supportDir)

            if let bundleId = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleId)
            }

            NSApplication.shared.terminate(nil)
        }
    }
}
