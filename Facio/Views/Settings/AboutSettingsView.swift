import SwiftUI

struct AboutSettingsView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var showResetAlert = false
    @State private var showUninstallAlert = false
    @State private var resetDone = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.3.0"
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

                        Text("Version \(appVersion)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Factures & devis professionnels")
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
                    Label("Liens", systemImage: "link")
                        .font(.headline)

                    HStack(spacing: 10) {
                        linkButton(
                            title: "Code source",
                            icon: "chevron.left.forwardslash.chevron.right",
                            url: "https://github.com/Juiiceee/Facio"
                        )

                        linkButton(
                            title: "Releases",
                            icon: "arrow.down.circle",
                            url: "https://github.com/Juiiceee/Facio/releases"
                        )

                        linkButton(
                            title: "Signaler un bug",
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
                    Label("Zone dangereuse", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                        .foregroundStyle(.red)

                    HStack(spacing: 10) {
                        Button {
                            showResetAlert = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reinitialiser")
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .help("Supprime toutes les donnees et remet Facio a zero")

                        Button {
                            showUninstallAlert = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text("Desinstaller")
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .help("Supprime toutes les donnees et ferme l'application")
                    }

                    if resetDone {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Reinitialisation effectuee. Relancez Facio.")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    Text("Ces actions sont irreversibles. Assurez-vous d'avoir exporte vos documents importants.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
            }

            Spacer()
        }
        .padding(24)
        .alert("Reinitialiser Facio ?", isPresented: $showResetAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Reinitialiser", role: .destructive) { resetApp() }
        } message: {
            Text("Toutes vos donnees seront supprimees (factures, devis, clients, parametres). Cette action est irreversible.")
        }
        .alert("Desinstaller Facio ?", isPresented: $showUninstallAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Desinstaller", role: .destructive) { uninstallApp() }
        } message: {
            Text("L'application sera fermee et toutes les donnees locales seront supprimees. Vous devrez supprimer Facio.app manuellement.")
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
            "timesheets.json", "sync_state.json"
        ]

        for file in filesToDelete {
            let url = supportDir.appendingPathComponent(file)
            try? FileManager.default.removeItem(at: url)
        }

        let defaults = UserDefaults.standard
        for key in ["facio_sync_enabled", "facio_user_id", "facio_user_email", "facio_is_anonymous"] {
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
