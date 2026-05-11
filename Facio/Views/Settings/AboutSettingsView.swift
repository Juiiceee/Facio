import SwiftUI

struct AboutSettingsView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var updateService = UpdateService()
    @State private var showResetAlert = false
    @State private var showUninstallAlert = false
    @State private var resetDone = false
    @State private var updateChecked = false

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Header
            GroupBox {
                HStack(spacing: 16) {
                    Group {
                        if let icon = NSApp.applicationIconImage {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 64, height: 64)
                        } else {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.purple.gradient)
                                .frame(width: 64, height: 64)
                                .overlay {
                                    Text("F")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Facio")
                            .font(.title)
                            .fontWeight(.bold)

                        Text(L10n.version(lang, value: appVersion))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(L10n.professionalInvoices(lang))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()
                }
                .padding(12)
            }

            // MARK: - Liens
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label(L10n.links(lang), systemImage: "link")
                        .font(.headline)

                    HStack(spacing: 10) {
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

                    HStack(spacing: 10) {
                        Button {
                            updateChecked = false
                            Task {
                                await updateService.checkForUpdates()
                                updateChecked = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                if updateService.isChecking {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.trianglehead.2.clockwise")
                                }
                                Text(L10n.checkForUpdates(lang))
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .disabled(updateService.isChecking)

                        if updateChecked {
                            if updateService.isUpdateAvailable, let url = updateService.releaseURL {
                                Link(destination: url) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .foregroundStyle(.green)
                                        Text(L10n.updateAvailable(lang, version: updateService.latestVersion ?? ""))
                                            .foregroundStyle(.green)
                                    }
                                    .font(.subheadline)
                                }
                                .buttonStyle(.plain)
                            } else if !updateService.isChecking {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text(L10n.upToDate(lang))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    HStack(spacing: 10) {

                        linkButton(
                            title: L10n.reportBug(lang),
                            icon: "ladybug",
                            url: "https://github.com/Juiiceee/Facio/issues/new"
                        )
                    }
                }
                .padding(12)
            }

            // MARK: - Zone dangereuse
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label(L10n.dangerZone(lang), systemImage: "exclamationmark.triangle")
                        .font(.headline)
                        .foregroundStyle(.red)

                    HStack(spacing: 10) {
                        Button {
                            showResetAlert = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                Text(L10n.reset(lang))
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .help(L10n.resetHelp(lang))

                        Button {
                            showUninstallAlert = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text(L10n.uninstall(lang))
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .help(L10n.uninstallHelp(lang))
                    }

                    if resetDone {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(L10n.resetDone(lang))
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    Text(L10n.irreversibleWarning(lang))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
            }

            Spacer()
        }
        .padding(24)
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
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func resetApp() {
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

        let defaults = UserDefaults.standard
        for key in ["facio_sync_enabled", "facio_user_id", "facio_user_email",
                    "supabase_custom_url", "supabase_custom_api_key", "supabase_use_custom"] {
            defaults.removeObject(forKey: key)
        }

        dataStore.resetAll()
        resetDone = true
    }

    private func uninstallApp() {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Facio", isDirectory: true)
        try? FileManager.default.removeItem(at: supportDir)

        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }

        NSApplication.shared.terminate(nil)
    }
}
