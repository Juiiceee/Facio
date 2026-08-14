import SwiftUI

/// Saisie d'un code de verrouillage : cases de progression + pavé numérique.
///
/// Deux chemins de saisie volontairement redondants — le clavier physique
/// (chiffres, retour arrière) **et** le pavé à l'écran. L'écran de verrouillage
/// est le seul point d'entrée de l'app : si la capture clavier échoue, il faut
/// une porte de sortie visible, sinon l'utilisateur est enfermé dehors.
///
/// La vue ne connaît ni le code attendu ni la vérification : elle remonte le
/// code complet via `onComplete`, le parent décide.
struct PasscodeEntryView: View {
    /// Nombre de chiffres attendus (dessine autant de cases).
    let length: Int
    let lang: AppLanguage
    @Binding var code: String
    /// Bloque toute saisie (vérification en cours, temporisation anti-force-brute).
    var isDisabled: Bool = false
    /// Incrémenté par le parent pour déclencher la secousse d'erreur.
    var shakeToken: Int = 0
    let onComplete: (String) -> Void

    @FocusState private var isFocused: Bool
    @Environment(\.facioAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: FacioLayout.space24) {
            dots
            keypad
        }
        .focusable(!isDisabled)
        .focusEffectDisabled()
        .focused($isFocused)
        .onKeyPress(phases: .down) { press in handle(press) }
        .onAppear { isFocused = true }
        .onChange(of: isDisabled) { _, disabled in
            if !disabled { isFocused = true }
        }
    }

    // MARK: - Cases

    private var dots: some View {
        HStack(spacing: FacioLayout.space12) {
            ForEach(0 ..< length, id: \.self) { index in
                Circle()
                    .strokeBorder(Color.borderSubtle, lineWidth: 1)
                    .background(Circle().fill(index < code.count ? accent : Color.surfaceField))
                    .frame(width: FacioLayout.passcodeDotSize, height: FacioLayout.passcodeDotSize)
            }
        }
        .animation(FacioMotion.respecting(FacioMotion.state, reduceMotion: reduceMotion), value: code.count)
        .modifier(PasscodeShake(progress: CGFloat(shakeToken), enabled: !reduceMotion))
        .animation(FacioMotion.respecting(FacioMotion.emphasis, reduceMotion: reduceMotion), value: shakeToken)
        .accessibilityElement()
        .accessibilityLabel(L10n.appLockSection(lang))
        .accessibilityValue("\(code.count)/\(length)")
    }

    // MARK: - Pavé numérique

    private var keypad: some View {
        Grid(horizontalSpacing: FacioLayout.space12, verticalSpacing: FacioLayout.space12) {
            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.self) { digit in
                        key(digit)
                    }
                }
            }
            GridRow {
                Color.clear.frame(width: FacioLayout.passcodeKeySize, height: FacioLayout.passcodeKeySize)
                key(0)
                backspaceKey
            }
        }
        .disabled(isDisabled)
    }

    private func key(_ digit: Int) -> some View {
        Button {
            append(Character("\(digit)"))
        } label: {
            Text("\(digit)")
                .font(FacioFont.metricValue)
                .frame(width: FacioLayout.passcodeKeySize, height: FacioLayout.passcodeKeySize)
                .contentShape(Circle())
        }
        .buttonStyle(PasscodeKeyStyle())
    }

    private var backspaceKey: some View {
        Button(action: backspace) {
            Image(systemName: "delete.left")
                .font(.title3)
                .frame(width: FacioLayout.passcodeKeySize, height: FacioLayout.passcodeKeySize)
                .contentShape(Circle())
        }
        .buttonStyle(PasscodeKeyStyle())
        .accessibilityLabel(L10n.deleteDigit(lang))
    }

    // MARK: - Saisie

    private func handle(_ press: KeyPress) -> KeyPress.Result {
        guard !isDisabled else { return .ignored }
        switch press.key {
        case .delete, .deleteForward:
            backspace()
            return .handled
        case .space:
            // Sinon l'espace « clique » la touche du pavé qui a le focus.
            return .handled
        default:
            guard let character = press.characters.first, character.isNumber else { return .ignored }
            append(character)
            return .handled
        }
    }

    private func append(_ character: Character) {
        guard !isDisabled, code.count < length else { return }
        isFocused = true
        code.append(character)
        if code.count == length {
            onComplete(code)
        }
    }

    private func backspace() {
        guard !isDisabled, !code.isEmpty else { return }
        isFocused = true
        code.removeLast()
    }
}

/// Chrome d'une touche du pavé : cercle discret, plein au survol et à l'appui.
private struct PasscodeKeyStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .background(fill(pressed: configuration.isPressed))
            .overlay(Circle().strokeBorder(isHovering ? Color.borderHover : Color.borderSubtle, lineWidth: 1))
            .clipShape(Circle())
            .opacity(isEnabled ? 1 : 0.4)
            .animation(FacioMotion.respecting(FacioMotion.hover, reduceMotion: reduceMotion), value: isHovering)
            .animation(FacioMotion.respecting(FacioMotion.hover, reduceMotion: reduceMotion), value: configuration.isPressed)
            .onHover { isHovering = $0 }
    }

    private func fill(pressed: Bool) -> Color {
        if pressed { return .surfaceRowHover }
        return isHovering ? .surfaceRow : .surfaceTile
    }
}

/// Secousse horizontale amortie sur code refusé. `progress` est un compteur
/// entier : chaque incrément joue une secousse complète.
private struct PasscodeShake: GeometryEffect {
    var progress: CGFloat
    let enabled: Bool

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        guard enabled else { return ProjectionTransform() }
        let offset = sin(progress * .pi * 6) * 8
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}
