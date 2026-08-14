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

/// Pourquoi une liste filtrable est vide. La réponse gouverne le message ET
/// l'action proposée : suggérer « créez-en un » à quelqu'un dont la liste est
/// simplement filtrée est faux, et le laisse sans issue.
///
/// Partagé par toutes les listes pour que les trois cas ne puissent pas
/// diverger d'un écran à l'autre.
enum FacioListEmptyReason: Equatable {
    /// La collection est réellement vide : proposer de créer.
    case noData
    /// La recherche texte ne renvoie rien : proposer un autre mot-clé.
    case noSearchResults
    /// Les filtres actifs ne laissent rien passer : proposer de les lever.
    case noFilterResults

    /// L'ordre compte : une recherche en cours explique le vide même si des
    /// filtres sont actifs, parce que c'est le dernier geste de l'utilisateur.
    init(searchText: String, activeFilterCount: Int) {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self = .noSearchResults
        } else if activeFilterCount > 0 {
            self = .noFilterResults
        } else {
            self = .noData
        }
    }
}
