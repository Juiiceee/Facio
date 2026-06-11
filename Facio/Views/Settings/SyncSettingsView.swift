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
        VStack(spacing: FacioLayout.space20) {
            // MARK: - Toggle principal
            SectionPanel(L10n.cloudSync(lang), systemImage: "icloud") {
                VStack(alignment: .leading, spacing: FacioLayout.space16) {
                    Toggle(L10n.enableOnlineBackup(lang), isOn: $isEnabled)
                        .onChange(of: isEnabled) {
                            SyncConfig.isEnabled = isEnabled
                        }

                    if isEnabled {
                        Text(L10n.syncDescription(lang))
                            .font(FacioFont.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // MARK: - Authentification
            if isEnabled {
                SectionPanel(L10n.account(lang), systemImage: "person.crop.circle") {
                    VStack(alignment: .leading, spacing: FacioLayout.space16) {
                        if authService.isAuthenticated {
                            // Connected state
                            HStack(spacing: FacioLayout.space8) {
                                Circle()
                                    .fill(Color.intentSuccess)
                                    .frame(width: 8, height: 8)
                                Text(L10n.connected(lang, email: authService.userEmail))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button(L10n.signOut(lang)) { authService.signOut() }
                                    .foregroundStyle(Color.intentDanger)
                                    .buttonStyle(.borderless)
                            }
                        } else if authService.awaitingOTP {
                            // Step 2: Enter OTP code
                            HStack(spacing: FacioLayout.space6) {
                                Image(systemName: "envelope.badge")
                                    .foregroundStyle(Color.intentInfo)
                                Text(L10n.otpSent(lang, email: authService.pendingEmail))
                                    .font(.subheadline)
                            }

                            LabeledField(L10n.verificationCode(lang)) {
                                TextField(L10n.otpCodePlaceholder(lang), text: $otpCode)
                                    .facioField()
                                    .frame(maxWidth: 200)
                            }

                            HStack(spacing: FacioLayout.space12) {
                                Button(L10n.verify(lang)) {
                                    Task {
                                        await authService.verifyOTP(code: otpCode)
                                        otpCode = ""
                                        if authService.isAuthenticated {
                                            await syncService.fullSync(dataStore: dataStore)
                                        }
                                    }
                                }
                                .buttonStyle(.facio(.primary))
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
                                .font(FacioFont.caption)
                                .foregroundStyle(.secondary)

                            LabeledField(L10n.email(lang)) {
                                TextField(L10n.emailPlaceholder(lang), text: $email)
                                    .facioField()
                            }

                            Button(L10n.receiveCode(lang)) {
                                Task { await authService.sendOTP(email: email) }
                            }
                            .buttonStyle(.facio(.primary))
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
                            InlineWarning(text: "\(L10n.authenticationError(lang)): \(error)", tone: .danger)
                        }
                    }
                }
            }

            // MARK: - Statut sync
            if isEnabled && authService.isAuthenticated {
                SectionPanel(L10n.syncStatus(lang), systemImage: "antenna.radiowaves.left.and.right") {
                    VStack(alignment: .leading, spacing: FacioLayout.space16) {
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
                                Text(lastSync.formattedDate(for: lang))
                            }
                            .font(.subheadline)
                        }

                        if let error = syncService.lastError {
                            InlineWarning(text: "\(L10n.synchronizationError(lang)): \(error)", tone: .danger)
                        }

                        HStack(spacing: FacioLayout.space12) {
                            Button(L10n.synchronize(lang)) {
                                Task { await syncService.fullSync(dataStore: dataStore) }
                            }
                            .buttonStyle(.facio(.primary))
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
                            .buttonStyle(.facio(.secondary))
                            .disabled(syncService.isSyncing)
                        }
                    }
                }
            }

            // MARK: - Mode avance (DB custom)
            if isEnabled {
                SectionPanel(L10n.advanced(lang), systemImage: "wrench.and.screwdriver") {
                    VStack(alignment: .leading, spacing: FacioLayout.space16) {
                        Toggle(L10n.useOwnSupabase(lang), isOn: $useCustomDB)
                            .onChange(of: useCustomDB) {
                                SyncConfig.useCustomDB = useCustomDB
                                if !useCustomDB {
                                    authService.signOut()
                                }
                            }

                        if useCustomDB {
                            LabeledField(L10n.supabaseURL(lang)) {
                                TextField(L10n.supabaseURLPlaceholder(lang), text: $customURL)
                                    .facioField()
                                    .onChange(of: customURL) { SyncConfig.customURL = customURL }
                            }

                            LabeledField(L10n.apiKeyAnon(lang)) {
                                HStack {
                                    if showApiKey {
                                        TextField(L10n.apiKeyPlaceholder(lang), text: $customAPIKey)
                                            .facioField()
                                    } else {
                                        SecureField(L10n.apiKey(lang), text: $customAPIKey)
                                            .facioField()
                                    }
                                    Button {
                                        showApiKey.toggle()
                                    } label: {
                                        Image(systemName: showApiKey ? "eye.slash" : "eye")
                                            .frame(width: 28, height: 28)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.borderless)
                                    .help(showApiKey ? L10n.hideApiKey(lang) : L10n.showApiKey(lang))
                                    .accessibilityLabel(showApiKey ? L10n.hideApiKey(lang) : L10n.showApiKey(lang))
                                }
                                .onChange(of: customAPIKey) { SyncConfig.customAPIKey = customAPIKey }
                            }

                            Divider()

                            // SQL helper
                            DisclosureGroup(L10n.sqlSchema(lang), isExpanded: $showSQL) {
                                Text(SyncService.sqlSchema)
                                    .font(FacioFont.monoCaption)
                                    .textSelection(.enabled)
                                    .padding(FacioLayout.space8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.surfaceField)
                                    .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusField))

                                Button(L10n.copySQL(lang)) {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(SyncService.sqlSchema, forType: .string)
                                }
                                .buttonStyle(.borderless)
                            }
                            .font(FacioFont.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(FacioLayout.screenPadding)
        .onAppear(perform: updateServiceLanguages)
        .onChange(of: lang) { _, _ in updateServiceLanguages() }
    }

    private func updateServiceLanguages() {
        authService.language = lang
        syncService.language = lang
    }

}
