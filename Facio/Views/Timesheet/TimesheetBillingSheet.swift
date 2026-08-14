import SwiftUI

/// La source des lignes de facture d'une période.
///
/// Les deux existaient déjà, mais dans deux boutons distincts, à deux endroits
/// distincts, sans que rien n'annonce qu'ils ne produisaient pas la même
/// facture : la grille agrège les heures par jour, le minuteur facture ses
/// entrées non encore facturées.
enum TimesheetBillingSource: String, CaseIterable, Identifiable {
    case grid
    case timerEntries

    var id: String { rawValue }

    func label(for lang: AppLanguage) -> String {
        switch self {
        case .grid: return L10n.billingSourceGrid(lang)
        case .timerEntries: return L10n.billingSourceTimer(lang)
        }
    }
}

/// La feuille unique de facturation d'une période : on choisit sa source et sa
/// granularité, on VOIT les lignes et le total, on lit ce que la validation
/// verrouille, puis on décide.
struct TimesheetBillingSheet: View {
    let timesheet: TimesheetPeriod
    var onCreated: (Document) -> Void

    @Environment(DataStore.self) private var dataStore
    @Environment(PrivacyMode.self) private var privacy
    @Environment(\.dismiss) private var dismiss

    @State private var source: TimesheetBillingSource = .grid
    @State private var detailMode: TimesheetInvoiceDetailMode = .summary
    @State private var grouping: TimeEntryInvoiceGrouping = .detailed

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }
    private var numberFormat: AppLanguage { dataStore.companyInfo.formatNombre }

    /// Les lignes réellement produites par la source et la granularité choisies.
    private var previewLines: [LineItem] {
        switch source {
        case .grid:
            return dataStore.invoiceLineItems(for: timesheet, detailMode: detailMode)
        case .timerEntries:
            return dataStore.timeEntryInvoicePreview(for: timesheet, grouping: grouping)
        }
    }

    private var totalHT: Decimal {
        previewLines.reduce(0) { $0 + $1.totalLigne }
    }

    private var totalHours: Decimal {
        previewLines.reduce(0) { $0 + $1.quantite }
    }

    /// La source « minuteur » n'a de sens que s'il reste des entrées à facturer.
    private var timerSourceAvailable: Bool {
        !dataStore.importableTimeEntries(for: timesheet).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: FacioLayout.space16) {
                    sourceSection
                    detailSection
                    previewSection
                    InlineWarning(text: L10n.billingLockNotice(lang), tone: .info)
                }
                .padding(FacioLayout.screenPadding)
            }

            Divider()
            footer
        }
        .frame(
            minWidth: FacioLayout.sheetMinWidth, idealWidth: FacioLayout.sheetIdealWidth,
            minHeight: FacioLayout.sheetMinHeight, idealHeight: FacioLayout.sheetIdealHeight
        )
        .onAppear {
            // On ouvre sur la seule source disponible plutôt que sur une source
            // vide dont l'aperçu afficherait « aucune ligne » sans raison.
            if !timerSourceAvailable { source = .grid }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(L10n.billingSheetTitle(lang, period: timesheet.periodLabel(for: lang)))
                .font(FacioFont.sectionTitle)
            Spacer()
            Text(timesheet.clientDisplayName)
                .font(FacioFont.caption)
                .foregroundStyle(.secondary)
        }
        .padding(FacioLayout.screenPadding)
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space8) {
            Text(L10n.billingSource(lang))
                .font(FacioFont.fieldLabel)
                .foregroundStyle(.secondary)

            Picker("", selection: $source) {
                ForEach(TimesheetBillingSource.allCases) { candidate in
                    Text(candidate.label(for: lang)).tag(candidate)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .disabled(!timerSourceAvailable)
        }
    }

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space8) {
            Text(L10n.billingDetailLevel(lang))
                .font(FacioFont.fieldLabel)
                .foregroundStyle(.secondary)

            switch source {
            case .grid:
                Picker("", selection: $detailMode) {
                    ForEach(TimesheetInvoiceDetailMode.allCases) { mode in
                        Text(mode.label(for: lang)).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            case .timerEntries:
                Picker("", selection: $grouping) {
                    Text(L10n.billingGroupingDetailed(lang)).tag(TimeEntryInvoiceGrouping.detailed)
                    Text(L10n.billingGroupingByProject(lang)).tag(TimeEntryInvoiceGrouping.byProject)
                    Text(L10n.billingGroupingSingleLine(lang)).tag(TimeEntryInvoiceGrouping.singleLine)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
        }
    }

    private var previewSection: some View {
        let lines = previewLines
        return SectionPanel {
            VStack(alignment: .leading, spacing: FacioLayout.space8) {
                HStack {
                    Text(L10n.billingPreview(lang))
                        .font(FacioFont.fieldLabel)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(L10n.billingLineCount(lang, count: lines.count))
                        .font(FacioFont.metaValue)
                        .foregroundStyle(.secondary)
                }

                if lines.isEmpty {
                    Text(L10n.billingNothingToBill(lang))
                        .font(FacioFont.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(lines) { line in
                        HStack(alignment: .firstTextBaseline, spacing: FacioLayout.space12) {
                            Text(line.designation)
                                .font(FacioFont.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer(minLength: FacioLayout.space12)
                            Text("\(line.quantite.formatted2Decimals(for: numberFormat)) h")
                                .font(FacioFont.metaValue)
                                .foregroundStyle(.secondary)
                            Text(privacy.formatNumber(line.totalLigne, lang: numberFormat))
                                .font(FacioFont.rowValue)
                        }
                    }

                    Divider()

                    HStack {
                        Text(L10n.totalHTLabel(lang))
                            .font(FacioFont.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(totalHours.formatted2Decimals(for: numberFormat)) h")
                            .font(FacioFont.metaValue)
                            .foregroundStyle(.secondary)
                        Text(privacy.formatNumber(totalHT, lang: numberFormat))
                            .font(FacioFont.amountEmphasis)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: FacioLayout.space12) {
            Text(L10n.billingDraftNotice(lang))
                .font(FacioFont.captionSmall)
                .foregroundStyle(.secondary)

            Spacer()

            FacioButton(L10n.cancel(lang), role: .secondary) { dismiss() }

            FacioButton(L10n.billingCreate(lang), systemImage: "doc.text") {
                create()
            }
            .disabled(previewLines.isEmpty)
        }
        .padding(FacioLayout.screenPadding)
    }

    private func create() {
        let invoice: Document?
        switch source {
        case .grid:
            invoice = dataStore.generateInvoice(from: timesheet, detailMode: detailMode)
        case .timerEntries:
            invoice = dataStore.generateInvoiceFromUnbilledTimeEntries(from: timesheet, grouping: grouping)
        }
        guard let invoice else { return }
        dismiss()
        onCreated(invoice)
    }
}
