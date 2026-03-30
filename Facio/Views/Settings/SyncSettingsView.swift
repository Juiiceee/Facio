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
        Form {
            // MARK: - Toggle principal
            Section("Synchronisation cloud") {
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

            // MARK: - Statut
            if isEnabled {
                Section("Statut") {
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
                        LabeledContent("Derniere sync") {
                            Text(lastSync.frenchFormatted)
                        }
                    }

                    if let error = syncService.lastError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }

                    if let error = authService.error {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }

                    HStack {
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
            }

            // MARK: - Mode avance (DB custom)
            if isEnabled {
                Section("Avance") {
                    Toggle("Utiliser ma propre base Supabase", isOn: $useCustomDB)
                        .onChange(of: useCustomDB) {
                            SyncConfig.useCustomDB = useCustomDB
                            if !useCustomDB {
                                // Retour au mode par defaut — re-auth anonyme
                                authService.signOut()
                                Task { await authService.signInAnonymously() }
                            }
                        }

                    if useCustomDB {
                        TextField("URL Supabase", text: $customURL)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: customURL) { SyncConfig.customURL = customURL }

                        HStack {
                            if showApiKey {
                                TextField("Cle API (anon)", text: $customAPIKey)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                SecureField("Cle API (anon)", text: $customAPIKey)
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

                        // Connexion email pour DB custom
                        Divider()

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

                            TextField("Email", text: $email)
                                .textFieldStyle(.roundedBorder)
                            SecureField("Mot de passe (min 6 car.)", text: $password)
                                .textFieldStyle(.roundedBorder)

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

                        // SQL helper
                        Divider()
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
                            .padding(4)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(4)

                        Button("Copier le SQL") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(sql, forType: .string)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
