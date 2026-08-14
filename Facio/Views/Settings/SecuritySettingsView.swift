import SwiftUI

/// Réglages du verrouillage par code : création / modification / suppression du
/// code, délai de re-verrouillage automatique et Touch ID.
struct SecuritySettingsView: View {
    @Environment(DataStore.self) private var dataStore
    @Environment(AppLock.self) private var lock

    @State private var sheetMode: PasscodeSheetMode?

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        @Bindable var lock = lock

        return VStack(spacing: FacioLayout.space20) {
            SectionPanel(L10n.appLockSection(lang), systemImage: "lock.shield") {
                VStack(alignment: .leading, spacing: FacioLayout.space16) {
                    HStack(spacing: FacioLayout.space8) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: FacioLayout.space8, height: FacioLayout.space8)
                        Text(statusLabel)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    Text(L10n.appLockDescription(lang))
                        .font(FacioFont.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: FacioLayout.space12) {
                        if lock.storeUnavailable {
                            // Trousseau illisible : un code existe peut-être
                            // encore. Proposer « créer » ici inviterait à
                            // l'écraser, on ne propose que de relire.
                            Button(L10n.retry(lang)) { lock.retryLoadingCredential() }
                                .buttonStyle(.facio(.secondary))
                        } else if lock.isEnabled {
                            Button(L10n.changeCode(lang)) { sheetMode = .change }
                                .buttonStyle(.facio(.primary))
                            Button(L10n.lockNow(lang)) { lock.lockNow() }
                                .buttonStyle(.facio(.secondary))
                            Button(L10n.removeCode(lang)) { sheetMode = .remove }
                                .buttonStyle(.borderless)
                                .foregroundStyle(Color.intentDanger)
                        } else {
                            Button(L10n.createCode(lang)) { sheetMode = .create }
                                .buttonStyle(.facio(.primary))
                        }
                        Spacer()
                    }

                    if lock.storeUnavailable {
                        InlineWarning(text: L10n.lockStoreUnavailableMessage(lang), tone: .danger)
                    } else if let storageError = lock.storageError {
                        InlineWarning(text: "\(L10n.codeStorageFailed(lang)) \(storageError)", tone: .danger)
                    }

                    Text(L10n.appLockSecurityNote(lang))
                        .font(FacioFont.captionSmall)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Les réglages ci-dessous n'ont de sens qu'avec un code configuré.
            if lock.isEnabled {
                SectionPanel(L10n.autoLockSection(lang), systemImage: "timer") {
                    VStack(alignment: .leading, spacing: FacioLayout.space16) {
                        LabeledField(L10n.autoLockDelayLabel(lang)) {
                            Picker("", selection: $lock.autoLockDelay) {
                                ForEach(AutoLockDelay.allCases) { delay in
                                    Text(delay.label(for: lang)).tag(delay)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: FacioLayout.fieldWidth)
                        }

                        Text(L10n.autoLockHint(lang))
                            .font(FacioFont.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Divider()

                        Toggle(L10n.lockOnBackgroundLabel(lang), isOn: $lock.lockOnBackground)
                        Text(L10n.lockOnBackgroundHint(lang))
                            .font(FacioFont.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                SectionPanel(L10n.bruteForceSection(lang), systemImage: "exclamationmark.shield") {
                    VStack(alignment: .leading, spacing: FacioLayout.space16) {
                        Text(L10n.bruteForceExplanation(lang, attempts: AppLockPolicy.attemptsBeforeLockout))
                            .font(FacioFont.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        // Barème dérivé de la politique elle-même : impossible
                        // d'afficher autre chose que ce qui est réellement appliqué.
                        VStack(spacing: FacioLayout.space6) {
                            ForEach(Array(AppLockPolicy.lockoutSchedule.enumerated()), id: \.offset) { index, delay in
                                HStack {
                                    Text(scheduleLabel(at: index))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(DurationFormatter.countdown(delay, lang: lang))
                                        .monospacedDigit()
                                }
                                .font(FacioFont.caption)
                            }
                        }

                        Divider()

                        Text(bruteForceStatus)
                            .font(FacioFont.caption)
                            .foregroundStyle(lock.failedAttempts > 0 ? Color.intentWarning : .secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                SectionPanel(L10n.biometricsSection(lang), systemImage: "touchid") {
                    VStack(alignment: .leading, spacing: FacioLayout.space16) {
                        if AppLock.biometricsAvailable {
                            Toggle(L10n.biometricsToggle(lang), isOn: $lock.useBiometrics)
                        } else {
                            Text(L10n.biometricsUnavailable(lang))
                                .font(FacioFont.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(FacioLayout.screenPadding)
        .sheet(item: $sheetMode) { mode in
            PasscodeSheet(mode: mode, currentLength: lock.credential?.length ?? AppLockCode.defaultLength)
        }
    }

    private var statusColor: Color {
        if lock.storeUnavailable { return .intentDanger }
        return lock.isEnabled ? .intentSuccess : .intentNeutral
    }

    private var statusLabel: String {
        if lock.storeUnavailable { return L10n.lockStoreUnavailableTitle(lang) }
        return lock.isEnabled ? L10n.appLockOn(lang) : L10n.appLockOff(lang)
    }

    /// Rang d'échec correspondant à la `index`-ième marche du barème ; la
    /// dernière marche vaut pour tous les échecs suivants.
    private func scheduleLabel(at index: Int) -> String {
        let number = AppLockPolicy.attemptsBeforeLockout + index
        return index == AppLockPolicy.lockoutSchedule.count - 1
            ? L10n.bruteForceFailureNumberAndBeyond(lang, number: number)
            : L10n.bruteForceFailureNumber(lang, number: number)
    }

    private var bruteForceStatus: String {
        let waiting = lock.remainingLockout()
        if waiting > 0 {
            return L10n.bruteForceStatusWaiting(lang, delay: DurationFormatter.countdown(waiting, lang: lang))
        }
        guard lock.failedAttempts > 0 else { return L10n.bruteForceStatusClear(lang) }
        return L10n.bruteForceStatusFailures(
            lang,
            failures: lock.failedAttempts,
            remaining: AppLockPolicy.remainingAttempts(failedAttempts: lock.failedAttempts)
        )
    }
}
