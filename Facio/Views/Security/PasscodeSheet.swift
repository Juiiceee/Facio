import SwiftUI

/// Ce que la feuille de saisie est en train de faire.
enum PasscodeSheetMode: Identifiable {
    case create
    case change
    case remove

    var id: Int {
        switch self {
        case .create: return 0
        case .change: return 1
        case .remove: return 2
        }
    }

    func title(for l: AppLanguage) -> String {
        switch self {
        case .create: return L10n.createCode(l)
        case .change: return L10n.changeCode(l)
        case .remove: return L10n.removeCode(l)
        }
    }
}

/// Une étape de la feuille de code.
enum PasscodeStep {
    case current
    case newCode
    case confirmation
}

/// L'enchaînement des étapes, extrait de la vue pour être vérifiable.
///
/// La feuille enchaînait jusqu'à trois saisies de six chiffres sans dire
/// combien il en restait, et sans permettre de revenir en arrière : se tromper
/// de nouveau code obligeait à tout annuler et à ressaisir le code actuel.
enum PasscodeFlow {
    /// Suppression = vérifier le code ; création = nouveau + confirmation ;
    /// modification = les trois.
    static func totalSteps(for mode: PasscodeSheetMode) -> Int {
        switch mode {
        case .remove: return 1
        case .create: return 2
        case .change: return 3
        }
    }

    /// L'étape par laquelle le mode commence.
    static func firstStep(for mode: PasscodeSheetMode) -> PasscodeStep {
        mode == .create ? .newCode : .current
    }

    /// Rang de l'étape, à partir de 1.
    static func index(of step: PasscodeStep, in mode: PasscodeSheetMode) -> Int {
        switch (mode, step) {
        case (.change, .current): return 1
        case (.change, .newCode): return 2
        case (.change, .confirmation): return 3
        case (.create, .newCode): return 1
        case (.create, .confirmation): return 2
        default: return 1
        }
    }

    /// L'étape précédente, ou `nil` quand il n'y a nulle part où revenir.
    static func previous(of step: PasscodeStep, in mode: PasscodeSheetMode) -> PasscodeStep? {
        switch (mode, step) {
        case (.change, .newCode): return .current
        case (.create, .confirmation), (.change, .confirmation): return .newCode
        default: return nil
        }
    }
}

/// Création, modification et suppression du code — un seul écran, piloté par
/// une petite machine à états (code actuel → nouveau code → confirmation).
/// Chaque étape se valide toute seule dès que le nombre de chiffres est atteint.
struct PasscodeSheet: View {
    let mode: PasscodeSheetMode

    @Environment(AppLock.self) private var lock
    @Environment(DataStore.self) private var dataStore
    @Environment(ToastCenter.self) private var toastCenter
    @Environment(\.dismiss) private var dismiss

    @State private var step: PasscodeStep
    @State private var length: Int
    @State private var currentCode = ""
    @State private var newCode = ""
    @State private var confirmationCode = ""
    @State private var errorMessage: String?
    @State private var shakeToken = 0
    @State private var isWorking = false
    /// Horloge locale, qui ne tourne que pendant une temporisation.
    @State private var now = Date()

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var remainingLockout: TimeInterval { lock.remainingLockout(at: now) }
    private var isRateLimited: Bool { remainingLockout > 0 }

    init(mode: PasscodeSheetMode, currentLength: Int) {
        self.mode = mode
        _step = State(initialValue: PasscodeFlow.firstStep(for: mode))
        _length = State(initialValue: mode == .create ? AppLockCode.defaultLength : currentLength)
    }

    var body: some View {
        VStack(spacing: FacioLayout.space20) {
            header

            if mode == .remove {
                InlineWarning(text: L10n.removeCodeConfirmMessage(lang), tone: .warning)
            }

            if step == .newCode {
                lengthPicker
            }

            PasscodeEntryView(
                length: expectedLength,
                lang: lang,
                code: entryBinding,
                isDisabled: isWorking || isRateLimited,
                shakeToken: shakeToken,
                onComplete: { entered in
                    Task { await advance(with: entered) }
                }
            )

            status

            HStack(spacing: FacioLayout.space8) {
                Button(L10n.cancel(lang)) { dismiss() }
                    .buttonStyle(.facio(.secondary))
                    .keyboardShortcut(.cancelAction)

                if let previousStep {
                    Button(L10n.back(lang)) { goBack(to: previousStep) }
                        .buttonStyle(.facio(.tertiary))
                        .disabled(isWorking || isRateLimited)
                }

                Spacer()
            }
        }
        .padding(FacioLayout.screenPadding)
        .frame(width: FacioLayout.sheetMinWidth)
        .task(id: lock.failedAttempts) {
            while !Task.isCancelled, lock.remainingLockout(at: Date()) > 0 {
                now = Date()
                try? await Task.sleep(for: .seconds(1))
            }
            now = Date()
        }
    }

    // MARK: - Sous-vues

    private var header: some View {
        VStack(spacing: FacioLayout.space6) {
            Text(mode.title(for: lang))
                .font(FacioFont.screenTitle)
            Text(stepTitle)
                .font(FacioFont.caption)
                .foregroundStyle(.secondary)
            // « Étape 2 sur 3 » : la feuille enchaînait jusqu'à trois saisies
            // de six chiffres sans jamais dire combien il en restait, et une
            // erreur pouvait renvoyer en arrière sans que ça se voie.
            if totalSteps > 1 {
                Text(L10n.codeStepProgress(lang, step: stepIndex, total: totalSteps))
                    .font(FacioFont.label)
                    .foregroundStyle(.tertiary)
                    .accessibilityLabel(L10n.codeStepProgress(lang, step: stepIndex, total: totalSteps))
            }
        }
    }

    private var totalSteps: Int { PasscodeFlow.totalSteps(for: mode) }
    private var stepIndex: Int { PasscodeFlow.index(of: step, in: mode) }
    private var previousStep: PasscodeStep? { PasscodeFlow.previous(of: step, in: mode) }

    private var lengthPicker: some View {
        Picker(L10n.codeLengthLabel(lang), selection: $length) {
            ForEach(AppLockCode.allowedLengths, id: \.self) { value in
                Text(L10n.codeLengthDigits(lang, digits: value)).tag(value)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(maxWidth: FacioLayout.fieldWidth)
        .onChange(of: length) { _, _ in
            // Changer de longueur en cours de saisie invaliderait les cases.
            newCode = ""
            confirmationCode = ""
            errorMessage = nil
        }
    }

    @ViewBuilder
    private var status: some View {
        if isRateLimited {
            InlineWarning(
                text: L10n.lockedOutRetryIn(lang, delay: DurationFormatter.countdown(remainingLockout, lang: lang)),
                tone: .danger
            )
        } else if isWorking {
            HStack(spacing: FacioLayout.space8) {
                ProgressView().scaleEffect(0.6)
                Text(L10n.verifying(lang))
                    .font(FacioFont.caption)
                    .foregroundStyle(.secondary)
            }
        } else if let errorMessage {
            InlineWarning(text: errorMessage, tone: .danger)
        } else if step == .confirmation, AppLockCode.isWeak(newCode) {
            InlineWarning(text: L10n.codeWeakWarning(lang), tone: .warning)
        } else {
            Text(" ").font(FacioFont.caption).hidden()
        }
    }

    // MARK: - État courant

    private var expectedLength: Int {
        step == .current ? (lock.credential?.length ?? AppLockCode.defaultLength) : length
    }

    private var entryBinding: Binding<String> {
        switch step {
        case .current: return $currentCode
        case .newCode: return $newCode
        case .confirmation: return $confirmationCode
        }
    }

    private var stepTitle: String {
        switch step {
        case .current: return L10n.codeStepCurrent(lang)
        case .newCode: return L10n.codeStepNew(lang)
        case .confirmation: return L10n.codeStepConfirm(lang)
        }
    }

    /// Revenir en arrière efface la saisie de l'étape quittée : la laisser en
    /// place ferait revalider automatiquement dès le premier chiffre tapé.
    private func goBack(to target: PasscodeStep) {
        errorMessage = nil
        switch step {
        case .confirmation: confirmationCode = ""
        case .newCode: newCode = ""
        case .current: currentCode = ""
        }
        step = target
    }

    // MARK: - Machine à états

    private func advance(with entered: String) async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }

        switch step {
        case .current:
            guard await lock.matchesCurrentCode(entered) else {
                fail(L10n.codeWrongCurrent(lang)) { currentCode = "" }
                return
            }
            if mode == .remove {
                await removeCode()
            } else {
                step = .newCode
            }

        case .newCode:
            do {
                try AppLockCode.validate(entered)
                step = .confirmation
            } catch {
                fail(message(for: error)) { newCode = "" }
            }

        case .confirmation:
            guard entered == newCode else {
                fail(L10n.codeMismatch(lang)) { confirmationCode = "" }
                return
            }
            await commitNewCode()
        }
    }

    private func commitNewCode() async {
        do {
            switch mode {
            case .create:
                try await lock.setCode(newCode, confirmation: confirmationCode)
                toastCenter.show(L10n.toastCodeCreated(lang), tone: .success)
            case .change:
                try await lock.changeCode(current: currentCode, new: newCode, confirmation: confirmationCode)
                toastCenter.show(L10n.toastCodeChanged(lang), tone: .success)
            case .remove:
                return
            }
            dismiss()
        } catch {
            fail(message(for: error)) {
                confirmationCode = ""
                newCode = ""
                step = .newCode
            }
        }
    }

    private func removeCode() async {
        do {
            try await lock.removeCode(current: currentCode)
            toastCenter.show(L10n.toastCodeRemoved(lang), tone: .success)
            dismiss()
        } catch {
            fail(message(for: error)) { currentCode = "" }
        }
    }

    private func fail(_ text: String, reset: () -> Void) {
        errorMessage = text
        shakeToken += 1
        // Réveille l'horloge : un échec vient peut-être d'ouvrir une attente,
        // que la bannière doit annoncer tout de suite.
        now = Date()
        reset()
    }

    private func message(for error: Error) -> String {
        switch error as? AppLockCodeError {
        case .mismatch: return L10n.codeMismatch(lang)
        case .wrongCurrentCode: return L10n.codeWrongCurrent(lang)
        case .invalidLength: return L10n.codeInvalidLength(lang)
        case .nonDigit: return L10n.codeNonDigit(lang)
        case .storageFailed, .none: return L10n.codeStorageFailed(lang)
        }
    }
}
