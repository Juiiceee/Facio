import SwiftUI

/// État vide unifié de Facio : icône + titre + message + action optionnelle.
///
/// Remplace les `ContentUnavailableView` divergents pour un rendu cohérent
/// sur tous les écrans.
struct FacioEmptyState<Action: View>: View {
    let title: String
    let systemImage: String
    var message: String?
    @ViewBuilder let action: Action

    init(
        title: String,
        systemImage: String,
        message: String? = nil,
        @ViewBuilder action: () -> Action
    ) {
        self.title = title
        self.systemImage = systemImage
        self.message = message
        self.action = action()
    }

    var body: some View {
        VStack(spacing: FacioLayout.space12) {
            Image(systemName: systemImage)
                .font(.system(size: 38, weight: .regular))
                .foregroundStyle(.tertiary)

            VStack(spacing: FacioLayout.space4) {
                Text(title)
                    .font(FacioFont.sectionTitle)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                if let message, !message.isEmpty {
                    Text(message)
                        .font(FacioFont.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            action
                .padding(.top, FacioLayout.space2)
        }
        .frame(maxWidth: 360)
        .padding(FacioLayout.space24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension FacioEmptyState where Action == EmptyView {
    init(title: String, systemImage: String, message: String? = nil) {
        self.init(title: title, systemImage: systemImage, message: message) { EmptyView() }
    }
}
