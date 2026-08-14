import SwiftUI

/// Écran de verrouillage : recouvre entièrement l'app tant que le code n'a pas
/// été saisi. Opaque par construction — rien du contenu (montants, clients) ne
/// doit transparaître derrière.
struct AppLockView: View {
    @Environment(AppLock.self) private var lock
    @Environment(DataStore.self) private var dataStore
    @Environment(\.facioAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var code = ""
    @State private var showsError = false
    @State private var shakeToken = 0
    @State private var showsRecovery = false
    /// Horloge locale, qui ne tourne que pendant une temporisation : sert à
    /// décompter et à réactiver la saisie à l'échéance.
    @State private var now = Date()

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var digits: Int { lock.credential?.length ?? AppLockCode.defaultLength }
    private var remainingLockout: TimeInterval { lock.remainingLockout(at: now) }
    private var isRateLimited: Bool { remainingLockout > 0 }

    var body: some View {
        VStack(spacing: FacioLayout.space24) {
            header

            PasscodeEntryView(
                length: digits,
                lang: lang,
                code: $code,
                isDisabled: lock.isVerifying || isRateLimited,
                shakeToken: shakeToken,
                onComplete: { entered in
                    Task { await submit(entered) }
                }
            )

            status

            if lock.canUseBiometrics {
                Button {
                    Task { await unlockWithBiometrics() }
                } label: {
                    Label(L10n.unlockWithBiometrics(lang), systemImage: "touchid")
                }
                .buttonStyle(.facio(.secondary))
                .disabled(lock.isVerifying || isRateLimited)
            }

            recovery
        }
        .frame(width: FacioLayout.lockPanelWidth)
        .padding(FacioLayout.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceInspector)
        .task(id: lock.failedAttempts) {
            // Tourne uniquement tant qu'il reste une temporisation à décompter.
            while !Task.isCancelled, lock.remainingLockout(at: Date()) > 0 {
                now = Date()
                try? await Task.sleep(for: .seconds(1))
            }
            now = Date()
        }
    }

    private var header: some View {
        VStack(spacing: FacioLayout.space12) {
            Image(systemName: "lock.fill")
                .font(.title)
                .foregroundStyle(accent)
                .frame(width: FacioLayout.lockBadgeSize, height: FacioLayout.lockBadgeSize)
                .background(accent.opacity(0.12))
                .clipShape(Circle())

            Text(L10n.appLockedTitle(lang))
                .font(FacioFont.screenTitle)

            Text(L10n.appLockedSubtitle(lang, digits: digits))
                .font(FacioFont.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var status: some View {
        if isRateLimited {
            Text(L10n.lockedOutRetryIn(lang, delay: DurationFormatter.countdown(remainingLockout, lang: lang)))
                .font(FacioFont.caption)
                .foregroundStyle(Color.intentDanger)
                .multilineTextAlignment(.center)
                .monospacedDigit()
        } else if lock.isVerifying {
            HStack(spacing: FacioLayout.space8) {
                ProgressView().scaleEffect(0.6)
                Text(L10n.verifying(lang))
                    .font(FacioFont.caption)
                    .foregroundStyle(.secondary)
            }
        } else if showsError {
            VStack(spacing: FacioLayout.space4) {
                Text(L10n.wrongCode(lang))
                    .font(FacioFont.caption)
                    .foregroundStyle(Color.intentDanger)
                let left = AppLockPolicy.remainingAttempts(failedAttempts: lock.failedAttempts)
                if left > 0 {
                    Text(L10n.attemptsRemaining(lang, count: left))
                        .font(FacioFont.captionSmall)
                        .foregroundStyle(.secondary)
                }
            }
            .transition(FacioMotion.slideIn)
        } else {
            // Réserve la hauteur du message pour que le panneau ne saute pas.
            Text(" ").font(FacioFont.caption).hidden()
        }
    }

    private var recovery: some View {
        VStack(spacing: FacioLayout.space8) {
            Button(L10n.forgotCode(lang)) {
                withAnimation(FacioMotion.respecting(FacioMotion.state, reduceMotion: reduceMotion)) {
                    showsRecovery.toggle()
                }
            }
            .buttonStyle(.borderless)
            .font(FacioFont.caption)
            .foregroundStyle(.secondary)

            if showsRecovery {
                InlineWarning(text: L10n.forgotCodeExplanation(lang), tone: .info)
                    .transition(FacioMotion.slideIn)
            }
        }
    }

    // MARK: - Actions

    private func submit(_ entered: String) async {
        let unlocked = await lock.unlock(with: entered)
        guard !unlocked else {
            code = ""
            showsError = false
            return
        }
        showsError = true
        shakeToken += 1
        now = Date()
        // Laisse la secousse se jouer avant de vider les cases.
        try? await Task.sleep(for: .milliseconds(350))
        code = ""
    }

    private func unlockWithBiometrics() async {
        let unlocked = await lock.unlockWithBiometrics(reason: L10n.biometricsReason(lang))
        if unlocked {
            code = ""
            showsError = false
        }
    }
}
