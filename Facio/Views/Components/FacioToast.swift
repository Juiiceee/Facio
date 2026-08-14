import SwiftUI

/// Toast non bloquant affiché en bas de la fenêtre principale.
///
/// Hiérarchie des retours visuels de Facio :
/// - **toast** : succès / information non bloquante (export, envoi, import) ;
/// - **InlineWarning** : erreur contextuelle persistante dans un panneau ;
/// - **alert** : erreur bloquante nécessitant une décision.
///
/// L'hôte est posé une seule fois sur la racine de `ContentView` — les toasts
/// n'apparaissent pas au-dessus des sheets (assumé : les sheets gardent leurs
/// retours inline).
struct FacioToastData: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let tone: InlineTone
    var icon: String?
    /// Libellé de l'action portée par le toast (« Rétablir », « Révéler dans le
    /// Finder »). Sans action, le toast reste purement informatif.
    var actionTitle: String?
    /// L'action elle-même. Exclue de l'égalité : deux closures ne se comparent pas.
    var action: (() -> Void)?

    static func == (lhs: FacioToastData, rhs: FacioToastData) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
@Observable
final class ToastCenter {
    private(set) var current: FacioToastData?
    private var dismissTask: Task<Void, Never>?

    /// Affiche un toast 3 s ; un nouveau toast remplace le précédent.
    ///
    /// Un toast peut porter UNE action. Sans elle, « Entrée supprimée » ne
    /// laissait aucune issue : le geste pour défaire vivait dans une barre
    /// séparée, posée en haut de page alors que le bouton qui l'avait déclenchée
    /// pouvait se trouver deux mille pixels plus bas.
    func show(
        _ message: String,
        tone: InlineTone = .success,
        icon: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        let toast = FacioToastData(
            message: message,
            tone: tone,
            icon: icon,
            actionTitle: actionTitle,
            action: action
        )
        withAnimation(FacioMotion.emphasis) {
            current = toast
        }
        // Message transitoire et non focusable : annoncé à VoiceOver.
        AccessibilityNotification.Announcement(message).post()
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard let self, self.current?.id == toast.id, !Task.isCancelled else { return }
            withAnimation(FacioMotion.emphasis) {
                self.current = nil
            }
        }
    }

    /// Retire le toast courant — appelé quand son action a été utilisée.
    func dismiss() {
        dismissTask?.cancel()
        withAnimation(FacioMotion.emphasis) {
            current = nil
        }
    }
}

private struct FacioToastHost: ViewModifier {
    @Environment(ToastCenter.self) private var toastCenter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let toast = toastCenter.current {
                HStack(spacing: FacioLayout.space8) {
                    Image(systemName: toast.icon ?? toast.tone.icon)
                        .foregroundStyle(toast.tone.intent.glyph)
                    Text(toast.message)
                        .font(FacioFont.rowTitle)
                        .foregroundStyle(Color.textPrimary)

                    if let actionTitle = toast.actionTitle, let action = toast.action {
                        Button(actionTitle) {
                            action()
                            toastCenter.dismiss()
                        }
                        .buttonStyle(.facio(.tertiary))
                    }
                }
                .padding(.horizontal, FacioLayout.space16)
                .padding(.vertical, FacioLayout.space12)
                // Le toast flotte : c'est le plan e3. Il portait la seule ombre
                // de l'app, écrite à la main avec un noir à 12 %.
                .background(Color.surfaceFloat, in: Capsule())
                .overlay(Capsule().strokeBorder(toast.tone.intent.glyph.opacity(0.35), lineWidth: 1))
                .shadow(color: FacioElevation.e3.shadowColor, radius: FacioElevation.e3.shadowRadius, y: FacioElevation.e3.shadowY)
                .padding(.bottom, FacioLayout.space24)
                // Cliquable UNIQUEMENT quand il porte une action : un toast
                // informatif ne doit pas intercepter les clics du contenu.
                .allowsHitTesting(toast.action != nil)
                .transition(FacioMotion.slideUp)
                .transaction { transaction in
                    if reduceMotion { transaction.animation = nil }
                }
            }
        }
    }
}

extension View {
    /// Pose l'hôte des toasts. À appliquer une seule fois, sur la racine de la
    /// fenêtre principale.
    func facioToastHost() -> some View {
        modifier(FacioToastHost())
    }
}
