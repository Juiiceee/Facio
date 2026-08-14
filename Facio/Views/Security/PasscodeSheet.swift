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

/// Création, modification et suppression du code — un seul écran, piloté par
/// une petite machine à états (code actuel → nouveau code → confirmation).
/// Chaque étape se valide toute seule dès que le nombre de chiffres est atteint.
struct PasscodeSheet: View {
    let mode: PasscodeSheetMode

    @Environment(AppLock.self) private var lock
    @Environment(DataStore.self) private var dataStore
    @Environment(ToastCenter.self) private var toastCenter
    @Environment(\.dismiss) private var dismiss

    private enum Step {
        case current
        case newCode
        case confirmation
    }

    @State private var step: Step
    @State private var length: Int
    @State private var currentCode = ""
    @State private var newCode = ""
    @State private var confirmationCode = ""
    @State private var errorMessage: String?
    @State private var shakeToken = 0
    @State private var isWorking = false

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    init(mode: PasscodeSheetMode, currentLength: Int) {
        self.mode = mode
        _step = State(initialValue: mode == .create ? .newCode : .current)
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
                isDisabled: isWorking,
                shakeToken: shakeToken,
                onComplete: { entered in
                    Task { await advance(with: entered) }
                }
            )

            status

            HStack {
                Button(L10n.cancel(lang)) { dismiss() }
                    .buttonStyle(.facio(.secondary))
                    .keyboardShortcut(.cancelAction)
                Spacer()
            }
        }
        .padding(FacioLayout.screenPadding)
        .frame(width: FacioLayout.sheetMinWidth)
    }

    // MARK: - Sous-vues

    private var header: some View {
        VStack(spacing: FacioLayout.space6) {
            Text(mode.title(for: lang))
                .font(FacioFont.screenTitle)
            Text(stepTitle)
                .font(FacioFont.caption)
                .foregroundStyle(.secondary)
        }
    }

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
        if isWorking {
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
