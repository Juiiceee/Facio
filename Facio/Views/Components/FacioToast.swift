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
}

@MainActor
@Observable
final class ToastCenter {
    private(set) var current: FacioToastData?
    private var dismissTask: Task<Void, Never>?

    /// Affiche un toast 3 s ; un nouveau toast remplace le précédent.
    func show(_ message: String, tone: InlineTone = .success, icon: String? = nil) {
        let toast = FacioToastData(message: message, tone: tone, icon: icon)
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
}

private struct FacioToastHost: ViewModifier {
    @Environment(ToastCenter.self) private var toastCenter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let toast = toastCenter.current {
                HStack(spacing: FacioLayout.space8) {
                    Image(systemName: toast.icon ?? toast.tone.icon)
                        .foregroundStyle(toast.tone.color)
                    Text(toast.message)
                        .font(FacioFont.rowTitle)
                }
                .padding(.horizontal, FacioLayout.space16)
                .padding(.vertical, FacioLayout.space10)
                .background(Color.surfacePanel, in: Capsule())
                .overlay(Capsule().strokeBorder(toast.tone.color.opacity(0.35), lineWidth: 1))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                .padding(.bottom, FacioLayout.space20)
                .allowsHitTesting(false)
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
