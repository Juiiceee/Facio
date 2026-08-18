import SwiftUI

/// Le minuteur, promu au niveau de la fenêtre.
///
/// Il existait en **trois exemplaires** pour un seul minuteur global : la barre
/// du Hub temps, le panneau « Compteur » de chaque période, et un libellé vert
/// non cliquable dans la barre latérale. L'utilisateur ne savait jamais laquelle
/// était « la » barre, les deux premières formataient les durées différemment,
/// et la troisième — la seule visible en permanence — ne faisait rien.
///
/// Un seul composant canonique, en bas de la barre latérale : visible et
/// pilotable depuis Ventes comme depuis Clients, ce qui est le point même d'un
/// minuteur.
///
/// **Il ne tique que lorsqu'il tourne.** L'ancienne barre vivait dans une
/// `TimelineView` à la seconde qui recalculait toute la page en permanence,
/// minuteur arrêté compris.
struct FacioTimerControl: View {
    /// Rejoindre la saisie en cours.
    var onOpen: () -> Void

    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        Group {
            if let context = dataStore.runningTimeEntryContext {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    running(context: context, now: timeline.date)
                }
            } else {
                idle
            }
        }
        .padding(.horizontal, FacioLayout.space12)
        .padding(.vertical, FacioLayout.space8)
    }

    // MARK: Au repos

    /// Une invitation sobre — pas « 00:00:00 » en 28 pt, qui faisait du zéro
    /// l'élément le plus fort de l'écran.
    private var idle: some View {
        Button(action: onOpen) {
            HStack(spacing: FacioLayout.space8) {
                Image(systemName: "timer")
                    .font(FacioFont.label)
                    .foregroundStyle(Color.textTertiary)
                Text(L10n.timerIdleInvitation(lang))
                    .font(FacioFont.label)
                    .foregroundStyle(Color.textTertiary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.timerIdleInvitation(lang))
    }

    // MARK: En cours

    private func running(context: RunningTimeEntryContext, now: Date) -> some View {
        HStack(spacing: FacioLayout.space8) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(DurationFormatter.clock(now.timeIntervalSince(context.entry.startedAt)))
                        .font(FacioFont.amount)
                        .foregroundStyle(Color.textPrimary)
                        .monospacedDigit()
                    Text(subtitle(for: context))
                        .font(FacioFont.label)
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.timerRunningAccessibility(lang, subject: subtitle(for: context)))

            FacioIconButton(
                systemImage: "stop.fill",
                label: L10n.timeHubStopTimer(lang),
                tone: FacioIntent.danger.glyph
            ) {
                dataStore.stopRunningTimeEntry()
            }
        }
        .padding(.horizontal, FacioLayout.space8)
        .padding(.vertical, FacioLayout.space4)
        .background(FacioIntent.success.tint)
        .clipShape(RoundedRectangle(cornerRadius: FacioLayout.radiusSmall))
    }

    private func subtitle(for context: RunningTimeEntryContext) -> String {
        let client = context.timesheet.clientDisplayName
        let notes = context.entry.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !notes.isEmpty { return notes }
        return client.isEmpty ? context.timesheet.periodLabel(for: lang) : client
    }
}
