import Foundation

/// Une transition du cycle de vie d'un document.
///
/// Le statut était un `Picker` enterré en quatrième cellule d'une grille de
/// formulaire, au même poids visuel que « Langue » — alors que c'est le
/// contrôle le plus lourd de conséquence de l'application : il pilote le chiffre
/// d'affaires, le montant en attente, le retard, et déclenchait au passage le
/// gel d'un instantané de paiement, la création d'un versement vide et
/// l'ouverture d'une feuille modale, le tout en effet de bord d'un menu
/// déroulant.
///
/// Chaque transition devient un **bouton nommé**, avec sa conséquence écrite,
/// annulable, et confirmé par un toast.
enum DocumentTransition: String, Identifiable, CaseIterable {
    /// Brouillon → Envoyée.
    case send
    /// Envoyée / Partiel → Payée.
    case markPaid
    /// Ouvre la saisie d'un acompte. Ne crée AUCUN versement de lui-même :
    /// basculer en « Partiel » ajoutait un versement à 0 daté du jour, donc
    /// l'utilisateur voyait un paiement qui n'existait pas.
    case recordDeposit
    /// Facture en retard : relancer le client. Ce n'est pas un changement
    /// d'état, c'est l'action qu'appelle cet état.
    case remind
    /// → Annulée.
    case cancelDocument
    /// Annulée → Brouillon.
    case reopen

    var id: String { rawValue }

    /// L'état d'arrivée, ou `nil` quand le geste n'est pas un changement
    /// d'état mais une action que cet état appelle.
    var target: DocumentStatus? {
        switch self {
        case .send: return .envoyee
        case .markPaid: return .payee
        // PAS de cible : « Enregistrer un acompte » ouvre une saisie. Le
        // passage en « Partiel » n'en est qu'une conséquence, et depuis
        // « Partiel » l'action garde tout son sens — enregistrer le suivant.
        case .recordDeposit: return nil
        case .cancelDocument: return .annulee
        case .reopen: return .brouillon
        case .remind: return nil
        }
    }

    var systemImage: String {
        switch self {
        case .send: return "paperplane"
        case .markPaid: return "checkmark.circle"
        case .recordDeposit: return "circle.lefthalf.filled"
        case .remind: return "bell"
        case .cancelDocument: return "xmark.circle"
        case .reopen: return "arrow.uturn.backward"
        }
    }

    var isDestructive: Bool { self == .cancelDocument }

    func label(for lang: AppLanguage) -> String {
        switch self {
        case .send: return L10n.actionSend(lang)
        case .markPaid: return L10n.actionMarkPaid(lang)
        case .recordDeposit: return L10n.actionRecordDeposit(lang)
        case .remind: return L10n.actionRemind(lang)
        case .cancelDocument: return L10n.actionCancelDocument(lang)
        case .reopen: return L10n.actionReopen(lang)
        }
    }
}

/// Ce que l'état d'un document rend possible.
///
/// Une seule action primaire par état — c'est elle qui remplace les cinq
/// glyphes de poids égal de la barre d'outils, dont aucun ne portait le geste
/// réellement attendu.
enum DocumentStatusFlow {
    /// L'action attendue dans cet état. Elle donne son libellé au bandeau.
    static func primary(for status: DocumentStatus, isOverdue: Bool) -> DocumentTransition? {
        switch status {
        case .brouillon: return .send
        // Une facture en retard n'appelle pas « marquer payée » : elle appelle
        // une relance. L'état le plus urgent portait pourtant la même action
        // que l'état nominal.
        case .envoyee: return isOverdue ? .remind : .markPaid
        case .partiel: return .markPaid
        case .payee, .annulee: return nil
        }
    }

    /// Les autres gestes possibles, dans l'ordre où on les propose.
    static func secondary(for status: DocumentStatus, isOverdue: Bool) -> [DocumentTransition] {
        switch status {
        case .brouillon:
            return [.cancelDocument]
        case .envoyee:
            return isOverdue
                ? [.markPaid, .recordDeposit, .cancelDocument]
                : [.recordDeposit, .remind, .cancelDocument]
        case .partiel:
            return [.recordDeposit, .remind, .cancelDocument]
        case .payee:
            return [.reopen]
        case .annulee:
            return [.reopen]
        }
    }

    /// Toutes les transitions offertes dans cet état, primaire comprise.
    static func all(for status: DocumentStatus, isOverdue: Bool) -> [DocumentTransition] {
        var result: [DocumentTransition] = []
        if let primary = primary(for: status, isOverdue: isOverdue) { result.append(primary) }
        result.append(contentsOf: secondary(for: status, isOverdue: isOverdue).filter { !result.contains($0) })
        return result
    }
}
