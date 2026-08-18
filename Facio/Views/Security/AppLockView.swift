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
    /// Le pavé est REPLIÉ par défaut : sur Mac, la frappe clavier est le geste
    /// réel de tout le monde, et le pavé occupait 234 pt au centre de l'écran.
    @State private var showsKeypad = false
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

            // Trousseau illisible : il n'y a aucune empreinte à comparer, donc
            // pas de saisie à proposer — seulement une relecture.
            if lock.storeUnavailable {
                storeUnavailablePanel
            } else {
                // Touch ID D'ABORD : bouton primaire pleine largeur, en tête.
                // Il était un bouton secondaire discret, posé APRÈS le pavé et
                // la ligne de statut — le chemin le plus rapide était le
                // dernier de la page.
                biometricsButton

                HStack(spacing: FacioLayout.space8) {
                    Rectangle().fill(Color.borderDivider).frame(height: 1)
                    Text(L10n.orEnterCode(lang))
                        .font(FacioFont.label)
                        .foregroundStyle(Color.textTertiary)
                        .fixedSize()
                    Rectangle().fill(Color.borderDivider).frame(height: 1)
                }

                PasscodeEntryView(
                    length: digits,
                    lang: lang,
                    code: $code,
                    isDisabled: lock.isVerifying || isRateLimited,
                    shakeToken: shakeToken,
                    showsKeypad: showsKeypad,
                    onComplete: { entered in
                        Task { await submit(entered) }
                    }
                )

                status
                    .accessibilityAddTraits(.updatesFrequently)

                Button(showsKeypad ? L10n.hideKeypad(lang) : L10n.showKeypad(lang)) {
                    withAnimation(FacioMotion.respecting(FacioMotion.state, reduceMotion: reduceMotion)) {
                        showsKeypad.toggle()
                    }
                }
                .buttonStyle(.facio(.tertiary))
            }

            recovery
        }
        .frame(width: FacioLayout.lockPanelWidth)
        .padding(FacioLayout.space24)
        // Une CARTE, posée sur un canvas assombri. L'écran flottait auparavant
        // sur exactement le même fond que l'app déverrouillée : le passage à
        // l'état verrouillé se lisait par disparition du contenu, pas comme un
        // changement de contexte.
        .facioElevation(.e3, radius: FacioLayout.radiusMedium, surface: .surfaceFloat)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceCanvas)
        // Touch ID est sollicité à l'APPARITION : c'est le geste le plus rapide
        // et le plus sûr, il était enterré sous le pavé et la ligne de statut.
        .task {
            guard lock.canUseBiometrics, !lock.storeUnavailable, !isRateLimited else { return }
            await unlockWithBiometrics()
        }
        .task(id: lock.failedAttempts) {
            // Tourne uniquement tant qu'il reste une temporisation à décompter.
            while !Task.isCancelled, lock.remainingLockout(at: Date()) > 0 {
                now = Date()
                try? await Task.sleep(for: .seconds(1))
            }
            now = Date()
        }
    }

    private var storeUnavailablePanel: some View {
        VStack(spacing: FacioLayout.space16) {
            InlineWarning(text: L10n.lockStoreUnavailableMessage(lang), tone: .danger)

            if let storageError = lock.storageError {
                Text(storageError)
                    .font(FacioFont.captionSmall)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(L10n.retry(lang)) { lock.retryLoadingCredential() }
                .buttonStyle(.facio(.primary))
        }
    }

    /// Une identité, pas seulement un cadenas : l'écran vu à chaque lancement
    /// n'affichait ni logo, ni nom, rien qui dise de quelle app ni de quel
    /// compte il s'agissait.
    private var header: some View {
        VStack(spacing: FacioLayout.space12) {
            Text(initials)
                .font(FacioFont.titleHero)
                .foregroundStyle(Color.textOnAccent)
                .frame(width: FacioLayout.lockBadgeSize, height: FacioLayout.lockBadgeSize)
                .background(accent)
                .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusMedium))
                .accessibilityHidden(true)

            VStack(spacing: FacioLayout.space4) {
                Text(companyName)
                    .font(FacioFont.titleHero)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Text(lock.storeUnavailable ? L10n.lockStoreUnavailableTitle(lang) : L10n.lockedSubtitle(lang))
                    .font(FacioFont.secondary)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var companyName: String {
        let trimmed = dataStore.companyInfo.nom.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Facio" : trimmed
    }

    private var initials: String {
        companyName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
            .uppercased()
    }

    /// Touch ID reste VISIBLE quand il est indisponible, avec sa raison écrite :
    /// il disparaissait purement et simplement, sans que rien n'explique
    /// pourquoi.
    @ViewBuilder
    private var biometricsButton: some View {
        if lock.canUseBiometrics {
            FacioButton(
                L10n.unlockWithBiometrics(lang),
                systemImage: "touchid",
                role: .primary
            ) {
                Task { await unlockWithBiometrics() }
            }
            .frame(maxWidth: .infinity)
            .disabled(lock.isVerifying || isRateLimited)
        } else {
            Label(L10n.biometricsUnavailableShort(lang), systemImage: "touchid")
                .font(FacioFont.label)
                .foregroundStyle(Color.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, FacioLayout.space8)
                .background(Color.surfaceSunken)
                .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusSmall))
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
                Text(left > 0 ? L10n.attemptsRemaining(lang, count: left) : lockoutRuleText)
                    .font(FacioFont.label)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .transition(FacioMotion.slideIn)
        } else {
            // Deux lignes réservées : l'état d'erreur en fait deux (message +
            // essais restants), donc réserver une seule ligne laissait le
            // panneau sauter malgré la précaution.
            VStack(spacing: FacioLayout.space4) {
                Text(L10n.codeProgress(lang, entered: code.count, total: digits))
                    .font(FacioFont.secondary)
                    .foregroundStyle(Color.textSecondary)
                Text(L10n.typeOnKeyboard(lang))
                    .font(FacioFont.label)
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }

    /// La règle d'attente, en toutes lettres — « 10 s, 1 min, 5 min, 15 min »,
    /// lue depuis la politique elle-même pour qu'elle ne puisse pas diverger.
    private var lockoutRuleText: String {
        let steps = AppLockPolicy.lockoutSchedule
            .map { DurationFormatter.countdown($0, lang: lang) }
            .joined(separator: ", ")
        return L10n.lockoutRule(lang, steps: steps)
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
