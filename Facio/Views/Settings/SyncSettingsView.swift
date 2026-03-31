import SwiftUI

struct SyncSettingsView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var isEnabled = SyncConfig.isEnabled
    @State private var useCustomDB = SyncConfig.useCustomDB
    @State private var customURL = SyncConfig.customURL
    @State private var customAPIKey = SyncConfig.customAPIKey
    @State private var showApiKey = false

    // Auth email (mode avance)
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false

    var syncService: SyncService
    var authService: AuthService

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Toggle principal
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Synchronisation cloud", systemImage: "icloud")
                        .font(.headline)

                    Toggle("Activer la sauvegarde en ligne", isOn: $isEnabled)
                        .onChange(of: isEnabled) {
                            SyncConfig.isEnabled = isEnabled
                            if isEnabled && !authService.isAuthenticated {
                                Task { await authService.signInAnonymously() }
                            }
                        }

                    if isEnabled {
                        Text("Vos donnees sont sauvegardees automatiquement dans le cloud. Elles sont privees et liees a cet appareil.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
            }

            // MARK: - Statut
            if isEnabled {
                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Statut", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.headline)

                        HStack(spacing: 8) {
                            Circle()
                                .fill(authService.isAuthenticated ? .green : .orange)
                                .frame(width: 8, height: 8)
                            if authService.isAuthenticated {
                                if authService.isAnonymous {
                                    Text("Connecte (automatique)")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Connecte — \(authService.userEmail)")
                                        .foregroundStyle(.secondary)
                                }
                            } else if authService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Connexion en cours...")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Non connecte")
                                    .foregroundStyle(.orange)
                            }
                        }

                        if syncService.isSyncing {
                            HStack {
                                ProgressView().scaleEffect(0.7)
                                Text("Synchronisation...")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let lastSync = syncService.lastSyncDate {
                            HStack {
                                Text("Derniere sync")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(lastSync.frenchFormatted)
                            }
                            .font(.subheadline)
                        }

                        if let error = syncService.lastError {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .foregroundStyle(.red)
                                    .font(.caption)
                            }
                        }

                        if let error = authService.error {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .foregroundStyle(.red)
                                    .font(.caption)
                            }
                        }

                        HStack(spacing: 12) {
                            Button("Synchroniser") {
                                Task { await syncService.fullSync(dataStore: dataStore) }
                            }
                            .disabled(!authService.isAuthenticated || syncService.isSyncing)

                            Button("Tout pousser") {
                                Task {
                                    syncService.markDirty("documents")
                                    syncService.markDirty("clients")
                                    syncService.markDirty("company")
                                    syncService.markDirty("timesheets")
                                    await syncService.pushAllDirty()
                                }
                            }
                            .disabled(!authService.isAuthenticated || syncService.isSyncing)
                        }
                    }
                    .padding(12)
                }
            }

            // MARK: - Mode avance (DB custom)
            if isEnabled {
                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Avance", systemImage: "wrench.and.screwdriver")
                            .font(.headline)

                        Toggle("Utiliser ma propre base Supabase", isOn: $useCustomDB)
                            .onChange(of: useCustomDB) {
                                SyncConfig.useCustomDB = useCustomDB
                                if !useCustomDB {
                                    authService.signOut()
                                    Task { await authService.signInAnonymously() }
                                }
                            }

                        if useCustomDB {
                            settingsRow("URL Supabase") {
                                TextField("https://xxx.supabase.co", text: $customURL)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: customURL) { SyncConfig.customURL = customURL }
                            }

                            settingsRow("Cle API (anon)") {
                                HStack {
                                    if showApiKey {
                                        TextField("eyJhbG...", text: $customAPIKey)
                                            .textFieldStyle(.roundedBorder)
                                    } else {
                                        SecureField("Cle API", text: $customAPIKey)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    Button {
                                        showApiKey.toggle()
                                    } label: {
                                        Image(systemName: showApiKey ? "eye.slash" : "eye")
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .onChange(of: customAPIKey) { SyncConfig.customAPIKey = customAPIKey }
                            }

                            Divider()

                            // Connexion email pour DB custom
                            if authService.isAuthenticated && !authService.isAnonymous {
                                HStack {
                                    Image(systemName: "person.crop.circle.fill")
                                        .foregroundStyle(.green)
                                    Text(authService.userEmail)
                                    Spacer()
                                    Button("Deconnexion") { authService.signOut() }
                                        .foregroundStyle(.red)
                                }
                            } else {
                                Picker("", selection: $isSignUp) {
                                    Text("Connexion").tag(false)
                                    Text("Inscription").tag(true)
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: 250)

                                settingsRow("Email") {
                                    TextField("email@exemple.com", text: $email)
                                        .textFieldStyle(.roundedBorder)
                                }

                                settingsRow("Mot de passe") {
                                    SecureField("Min 6 caracteres", text: $password)
                                        .textFieldStyle(.roundedBorder)
                                }

                                Button(isSignUp ? "Creer le compte" : "Se connecter") {
                                    Task {
                                        if isSignUp {
                                            await authService.signUp(email: email, password: password)
                                        } else {
                                            await authService.signIn(email: email, password: password)
                                        }
                                        if authService.isAuthenticated {
                                            await syncService.fullSync(dataStore: dataStore)
                                        }
                                    }
                                }
                                .disabled(email.isEmpty || password.count < 6 || authService.isLoading)
                            }

                            Divider()

                            // SQL helper
                            Text("Executez ce SQL dans votre Supabase :")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            let sql = """
                            CREATE TABLE IF NOT EXISTS sync_data (
                              id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                              user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
                              key TEXT NOT NULL,
                              data JSONB NOT NULL DEFAULT '{}',
                              updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                              UNIQUE(user_id, key)
                            );
                            CREATE INDEX IF NOT EXISTS idx_sync_data_user_key ON sync_data(user_id, key);
                            ALTER TABLE sync_data ENABLE ROW LEVEL SECURITY;
                            CREATE POLICY "own_data" ON sync_data FOR ALL
                              USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
                            """
                            Text(sql)
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            Button("Copier le SQL") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(sql, forType: .string)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(12)
                }
            }

            Spacer()
        }
        .padding(24)
    }

    private func settingsRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            content()
        }
    }
}
