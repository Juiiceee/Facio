import Foundation

/// Les identifiants des éléments de barre d'outils, en un seul endroit.
///
/// Sans identifiant explicite, SwiftUI en génère un et le pont NSToolbar les
/// réattribue d'une vue à l'autre : au changement de section, les éléments de la
/// vue quittée sont encore enregistrés quand ceux de la nouvelle s'insèrent, et
/// `-[NSToolbar _insertNewItemWithItemIdentifier:atIndex:]` lève une exception
/// qui tue l'application. C'était le plantage « Ventes → Clients », confirmé par
/// trois rapports système identiques.
///
/// Les regrouper ici rend l'unicité VÉRIFIABLE — un cas de régression la teste —
/// au lieu de la laisser reposer sur la discipline de celui qui ajoute la vue
/// suivante.
enum FacioToolbarID {
    // Châssis — présents dans toutes les sections.
    static let shellNew = "facio.shell.new"
    static let shellPalette = "facio.shell.palette"
    static let shellPrivacy = "facio.shell.privacy"
    static let shellLock = "facio.shell.lock"

    // Colonne liste — un par section listable.
    static let documentsNew = "facio.documents.new"
    static let clientsNew = "facio.clients.new"
    static let timesheetsNew = "facio.timesheets.new"

    // Colonne détail.
    static let editorActions = "facio.editor.actions"
    static let timesheetInvoice = "facio.timesheet.invoice"

    /// Tous les identifiants déclarés. Toute nouvelle entrée doit figurer ici :
    /// c'est cette liste que la régression contrôle.
    static let all: [String] = [
        shellNew, shellPalette, shellPrivacy, shellLock,
        documentsNew, clientsNew, timesheetsNew,
        editorActions, timesheetInvoice,
    ]
}
