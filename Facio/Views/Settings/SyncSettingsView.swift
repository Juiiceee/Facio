import SwiftUI

struct SyncSettingsView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var isEnabled = SyncConfig.isEnabled
    @State private var useCustomDB = SyncConfig.useCustomDB
    @State private var customURL = SyncConfig.customURL
    @State private var customAPIKey = SyncConfig.customAPIKey
    @State private var showApiKey = false

    // Auth OTP
    @State private var email = ""
    @State private var otpCode = ""
    @State private var showSQL = false

    var syncService: SyncService
    var authService: AuthService

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Toggle principal
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label(L10n.cloudSync(lang), systemImage: "icloud")
                        .font(.headline)

                    Toggle(L10n.enableOnlineBackup(lang), isOn: $isEnabled)
                        .onChange(of: isEnabled) {
                            SyncConfig.isEnabled = isEnabled
                        }

                    if isEnabled {
                        Text(L10n.syncDescription(lang))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
            }

            // MARK: - Authentification
            if isEnabled {
                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        Label(L10n.account(lang), systemImage: "person.crop.circle")
                            .font(.headline)

                        if authService.isAuthenticated {
                            // Connected state
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)
                                Text(L10n.connected(lang, email: authService.userEmail))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button(L10n.signOut(lang)) { authService.signOut() }
                                    .foregroundStyle(.red)
                                    .buttonStyle(.borderless)
                            }
                        } else if authService.awaitingOTP {
                            // Step 2: Enter OTP code
                            HStack(spacing: 6) {
                                Image(systemName: "envelope.badge")
                                    .foregroundStyle(.blue)
                                Text(L10n.otpSent(lang, email: authService.pendingEmail))
                                    .font(.subheadline)
                            }

                            settingsRow(L10n.verificationCode(lang)) {
                                TextField("123456", text: $otpCode)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 200)
                            }

                            HStack(spacing: 12) {
                                Button(L10n.verify(lang)) {
                                    Task {
                                        await authService.verifyOTP(code: otpCode)
                                        otpCode = ""
                                        if authService.isAuthenticated {
                                            await syncService.fullSync(dataStore: dataStore)
                                        }
                                    }
                                }
                                .disabled(otpCode.count < 6 || authService.isLoading)

                                Button(L10n.resendCode(lang)) {
                                    Task { await authService.sendOTP(email: authService.pendingEmail) }
                                }
                                .buttonStyle(.borderless)
                                .disabled(authService.isLoading)

                                Button(L10n.cancel(lang)) {
                                    authService.cancelOTP()
                                    otpCode = ""
                                }
                                .buttonStyle(.borderless)
                                .foregroundStyle(.secondary)
                            }

                            if authService.isLoading {
                                HStack {
                                    ProgressView().scaleEffect(0.7)
                                    Text(L10n.verifying(lang))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            // Step 1: Enter email
                            Text(L10n.emailLoginPrompt(lang))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            settingsRow(L10n.email(lang)) {
                                TextField("email@exemple.com", text: $email)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Button(L10n.receiveCode(lang)) {
                                Task { await authService.sendOTP(email: email) }
                            }
                            .disabled(email.isEmpty || !email.contains("@") || authService.isLoading)

                            if authService.isLoading {
                                HStack {
                                    ProgressView().scaleEffect(0.7)
                                    Text(L10n.sendingCode(lang))
                                        .foregroundStyle(.secondary)
                                }
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
                    }
                    .padding(12)
                }
            }

            // MARK: - Statut sync
            if isEnabled && authService.isAuthenticated {
                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        Label(L10n.syncStatus(lang), systemImage: "antenna.radiowaves.left.and.right")
                            .font(.headline)

                        if syncService.isSyncing {
                            HStack {
                                ProgressView().scaleEffect(0.7)
                                Text(L10n.syncing(lang))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let lastSync = syncService.lastSyncDate {
                            HStack {
                                Text(L10n.lastSync(lang))
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

                        HStack(spacing: 12) {
                            Button(L10n.synchronize(lang)) {
                                Task { await syncService.fullSync(dataStore: dataStore) }
                            }
                            .disabled(syncService.isSyncing)

                            Button(L10n.pushAll(lang)) {
                                Task {
                                    syncService.markDirty("documents")
                                    syncService.markDirty("clients")
                                    syncService.markDirty("company")
                                    syncService.markDirty("timesheets")
                                    await syncService.pushAllDirty()
                                }
                            }
                            .disabled(syncService.isSyncing)
                        }
                    }
                    .padding(12)
                }
            }

            // MARK: - Mode avance (DB custom)
            if isEnabled {
                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        Label(L10n.advanced(lang), systemImage: "wrench.and.screwdriver")
                            .font(.headline)

                        Toggle(L10n.useOwnSupabase(lang), isOn: $useCustomDB)
                            .onChange(of: useCustomDB) {
                                SyncConfig.useCustomDB = useCustomDB
                                if !useCustomDB {
                                    authService.signOut()
                                }
                            }

                        if useCustomDB {
                            settingsRow(L10n.supabaseURL(lang)) {
                                TextField("https://xxx.supabase.co", text: $customURL)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: customURL) { SyncConfig.customURL = customURL }
                            }

                            settingsRow(L10n.apiKeyAnon(lang)) {
                                HStack {
                                    if showApiKey {
                                        TextField("eyJhbG...", text: $customAPIKey)
                                            .textFieldStyle(.roundedBorder)
                                    } else {
                                        SecureField(L10n.apiKey(lang), text: $customAPIKey)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    Button {
                                        showApiKey.toggle()
                                    } label: {
                                        Image(systemName: showApiKey ? "eye.slash" : "eye")
                                            .frame(width: 28, height: 28)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .onChange(of: customAPIKey) { SyncConfig.customAPIKey = customAPIKey }
                            }

                            Divider()

                            // SQL helper
                            DisclosureGroup(L10n.sqlSchema(lang), isExpanded: $showSQL) {
                                Text(SyncService.sqlSchema)
                                    .font(.system(.caption2, design: .monospaced))
                                    .textSelection(.enabled)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.black.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))

                                Button(L10n.copySQL(lang)) {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(SyncService.sqlSchema, forType: .string)
                                }
                                .buttonStyle(.borderless)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
