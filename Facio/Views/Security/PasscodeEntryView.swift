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

    @Environment(\.facioAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: FacioLayout.space24) {
            dots
            keypad
        }
        .background(
            // Capture clavier au niveau AppKit. `.focusable()` + `.onKeyPress`
            // ne recevait rien : l'écran de verrouillage se superpose à un
            // NavigationSplitView qui garde le premier répondant, et SwiftUI ne
            // le lui reprend pas. On réclame donc le statut explicitement.
            PasscodeKeyCatcher(
                isActive: !isDisabled,
                onDigit: append,
                onBackspace: backspace
            )
        )
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

    private func append(_ character: Character) {
        guard !isDisabled, character.isNumber, code.count < length else { return }
        code.append(character)
        if code.count == length {
            onComplete(code)
        }
    }

    private func backspace() {
        guard !isDisabled, !code.isEmpty else { return }
        code.removeLast()
    }
}

/// Vue AppKit invisible qui capte les frappes du clavier physique.
///
/// `updateNSView` rafraîchit les fermetures à chaque rendu SwiftUI : elles
/// voient donc toujours l'état courant de la vue parente (longueur attendue,
/// saisie déjà faite), contrairement à une fermeture capturée une fois pour
/// toutes dans un moniteur d'événements.
private struct PasscodeKeyCatcher: NSViewRepresentable {
    let isActive: Bool
    let onDigit: (Character) -> Void
    let onBackspace: () -> Void

    func makeNSView(context: Context) -> KeyCatcherView {
        KeyCatcherView()
    }

    func updateNSView(_ view: KeyCatcherView, context: Context) {
        view.onDigit = onDigit
        view.onBackspace = onBackspace
        view.isActive = isActive
        view.claimFocus()
    }
}

private final class KeyCatcherView: NSView {
    var onDigit: ((Character) -> Void)?
    var onBackspace: (() -> Void)?
    var isActive = true

    private var keyWindowObserver: NSObjectProtocol?

    override var acceptsFirstResponder: Bool { isActive }

    /// Tant que la saisie est ouverte, rien d'autre ne prend le clavier — c'est
    /// précisément ce qu'on attend d'un écran de verrouillage, et ça empêche
    /// SwiftUI de nous reprendre le premier répondant juste après nous l'avoir
    /// donné (sans quoi la frappe cesse silencieusement).
    override func resignFirstResponder() -> Bool { !isActive }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else {
            keyWindowObserver.map(NotificationCenter.default.removeObserver)
            keyWindowObserver = nil
            return
        }
        // Revenir d'une autre app rend la fenêtre clé sans nous rendre le
        // premier répondant : on le reprend à ce moment-là.
        keyWindowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.claimFocus() }
        }
        claimFocus()
    }

    func claimFocus() {
        guard isActive, let window, window.firstResponder !== self else { return }
        // Différé : pendant `updateNSView`, la fenêtre n'a pas toujours fini
        // d'installer sa hiérarchie de vues.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isActive, let window = self.window else { return }
            window.makeFirstResponder(self)
        }
    }

    override func keyDown(with event: NSEvent) {
        // Les raccourcis (⌘, ⌃, ⌥) doivent poursuivre leur chemin.
        let modifiers = event.modifierFlags.intersection([.command, .control, .option])
        guard modifiers.isEmpty else {
            super.keyDown(with: event)
            return
        }
        // Saisie fermée (vérification en cours, attente) : on avale sans bip.
        guard isActive else { return }

        switch event.keyCode {
        case 51, 117: // retour arrière, suppression avant
            onBackspace?()
        case 53: // échap — laissé à la vue parente (fermeture de feuille)
            super.keyDown(with: event)
        default:
            // Une touche maintenue remplirait le code toute seule et brûlerait
            // un essai sur un code que personne n'a voulu saisir.
            guard !event.isARepeat, let characters = event.charactersIgnoringModifiers else { return }
            for character in characters where character.isNumber {
                onDigit?(character)
            }
            // Les autres touches sont avalées sans bip : sur un écran de
            // verrouillage, taper une lettre est une erreur banale.
        }
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
