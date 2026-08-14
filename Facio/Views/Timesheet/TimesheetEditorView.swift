import SwiftUI

struct TimesheetEditorView: View {
    let timesheet: TimesheetPeriod
    var onOpenInvoice: (Document) -> Void = { _ in }

    @Environment(DataStore.self) private var dataStore
    @Environment(PrivacyMode.self) private var privacy
    @Environment(\.facioContainerWidth) private var containerWidth
    @State private var hourInputMode: TimesheetHourInputMode = .decimal
    @State private var showClientPicker = false
    @State private var showBillingSheet = false
    @State private var showClientOverlapAlert = false
    @State private var editedStartDate = Date()
    @State private var editedEndDate = Date()
    @State private var showRangeLossAlert = false
    @State private var hourFieldFocusRequest: TimeFieldFocusRequest?
    @State private var hourFieldFocusNonce = 0

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    /// Colonnes de la grille des jours : 7 colonnes égales si la largeur le
    /// permet (7 × 64 + paddings ≈ 552 pt de conteneur), sinon 4 (rangées 4+3).
    private var dayGridColumns: [GridItem] {
        let count = containerWidth < 560 ? 4 : 7
        return Array(
            repeating: GridItem(.flexible(minimum: 64), spacing: FacioLayout.space4),
            count: count
        )
    }
    private var numberFormat: AppLanguage { dataStore.companyInfo.formatNombre }

    /// Heures des jours hors-mois depuis les périodes adjacentes
    private var adjHours: [String: Decimal] { dataStore.adjacentHours(for: timesheet) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FacioLayout.sectionSpacing) {
                // LA GRILLE D'ABORD. Tout l'intérêt de l'écran est d'y taper des
                // heures, et elle était le 7ᵉ bloc : on franchissait le hero, les
                // dates, un panneau « Compteur » complet, le client, sept tuiles
                // et un sélecteur de mode avant d'atteindre « Semaine 1 » — soit
                // plusieurs écrans de défilement à la largeur minimale.
                timesheetHeroBar
                hourInputModeControl

                ForEach(Array(timesheet.semaines.enumerated()), id: \.element.id) { weekIndex, week in
                    weekSection(weekIndex: weekIndex, week: week)
                }

                // Ce qui se consulte, après ce qui se saisit.
                resumeSection
                clientSection
                periodRangeSection
                parametresSection
            }
            .padding(FacioLayout.screenPadding)
        }
        .navigationTitle(timesheet.title(for: lang))
        .onAppear {
            resetRangeDraft()
        }
        .onChange(of: timesheet.id) { _, _ in
            resetRangeDraft()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let invoice = dataStore.existingBillableHoursInvoice(for: timesheet) {
                    Button {
                        onOpenInvoice(invoice)
                    } label: {
                        Label(L10n.openInvoice(lang), systemImage: "doc.text.magnifyingglass")
                    }
                } else {
                    // UN seul bouton, qui ouvre un aperçu. Il y en avait trois
                    // ici (un par granularité, en dialogue de confirmation), un
                    // dans la liste et un dans le panneau du compteur — aux
                    // résultats différents, tous sans aperçu.
                    Button {
                        showBillingSheet = true
                    } label: {
                        Label(L10n.billingAction(lang), systemImage: "doc.text")
                    }
                    .disabled(!canBill)
                }
            }
        }
        .sheet(isPresented: $showClientPicker) {
            ClientPickerSheet(clients: dataStore.clients) { client in
                guard !dataStore.timesheetOverlaps(
                    timesheet,
                    clientId: client.id,
                    excluding: timesheet.id
                ) else {
                    showClientOverlapAlert = true
                    return
                }
                timesheet.applyClient(client)
                dataStore.timesheetUpdated(timesheet, syncSharedWeeks: true)
                showClientPicker = false
            }
        }
        .sheet(isPresented: $showBillingSheet) {
            TimesheetBillingSheet(timesheet: timesheet, onCreated: onOpenInvoice)
        }
        .alert(L10n.cannotSelectClient(lang), isPresented: $showClientOverlapAlert) {
            Button(L10n.understood(lang), role: .cancel) {}
        } message: {
            Text(L10n.periodOverlapsForClient(lang))
        }
        .alert(L10n.periodRangeLossTitle(lang), isPresented: $showRangeLossAlert) {
            Button(L10n.cancel(lang), role: .cancel) {}
            Button(L10n.updatePeriodAndDeleteValues(lang), role: .destructive) {
                applyRangeUpdate()
            }
        } message: {
            let loss = rangeLossSummary
            Text(L10n.periodRangeLossMessage(
                lang,
                days: loss.dayCount,
                hours: loss.hours.formatted2Decimals(for: numberFormat)
            ))
        }
    }

    private var timesheetHeroBar: some View {
        let adj = adjHours
        let heures = timesheet.totalHeuresDuMois()
        let brut = timesheet.totalBrutCrossPeriod(adjacentHours: adj)
        let net = timesheet.totalNetCrossPeriod(adjacentHours: adj)

        // Contenu 100% intrinsèque (Texts uniquement) → ViewThatFits autorisé.
        return SectionPanel {
            ViewThatFits(in: .horizontal) {
                // Variante large : titre à gauche, stats et badge à droite
                HStack(alignment: .center, spacing: FacioLayout.space16) {
                    heroTitleBlock
                    Spacer()
                    heroStatsRow(heures: heures, brut: brut, net: net)
                    heroInvoiceBadge
                }

                // Variante empilée : titre puis rangée stats + badge
                VStack(alignment: .leading, spacing: FacioLayout.space10) {
                    heroTitleBlock
                    HStack(alignment: .center, spacing: FacioLayout.space16) {
                        heroStatsRow(heures: heures, brut: brut, net: net)
                        heroInvoiceBadge
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// Bloc titre du hero (période + client), partagé par les variantes ViewThatFits.
    private var heroTitleBlock: some View {
        VStack(alignment: .leading, spacing: FacioLayout.space6) {
            Text(timesheet.periodLabel(for: lang))
                .font(FacioFont.heroTitle)
            Text(timesheet.clientDisplayName.isEmpty ? L10n.noClient(lang) : timesheet.clientDisplayName)
                .font(FacioFont.screenSubtitle)
                .foregroundStyle(timesheet.clientDisplayName.isEmpty ? .tertiary : .secondary)
        }
    }

    /// Rangée des trois statistiques du hero, partagée par les variantes ViewThatFits.
    private func heroStatsRow(heures: Decimal, brut: Decimal, net: Decimal) -> some View {
        HStack(alignment: .center, spacing: FacioLayout.space16) {
            heroStat(L10n.totalHours(lang), value: "\(heures.formatted2Decimals(for: numberFormat))h")
            heroStat(L10n.grossTotal(lang), value: privacy.formatNumber(brut, lang: numberFormat))
            heroStat(L10n.netTotal(lang), value: privacy.formatNumber(net, lang: numberFormat))
        }
    }

    /// Une statistique du hero (libellé + valeur).
    private func heroStat(_ title: String, value: String) -> some View {
        VStack(alignment: .trailing, spacing: FacioLayout.space4) {
            Text(title)
                .font(FacioFont.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(FacioFont.amountEmphasis)
        }
    }

    /// Badge facturé / non facturé du hero.
    private var heroInvoiceBadge: some View {
        let invoiceTone: Color = timesheet.hasGeneratedInvoice ? .intentSuccess : .intentWarning
        return Text(timesheet.hasGeneratedInvoice ? L10n.invoiced(lang) : L10n.notInvoiced(lang))
            .font(FacioFont.caption)
            .fontWeight(.medium)
            .padding(.horizontal, FacioLayout.space8)
            .padding(.vertical, FacioLayout.space4)
            .background(invoiceTone.opacity(0.14))
            .foregroundStyle(invoiceTone)
            .clipShape(Capsule())
    }

    private var periodRangeSection: some View {
        SectionPanel(L10n.periodDates(lang), systemImage: "calendar") {
            VStack(alignment: .leading, spacing: FacioLayout.space10) {
                HStack(alignment: .center, spacing: FacioLayout.space12) {
                    DatePicker(
                        L10n.startDate(lang),
                        selection: $editedStartDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)

                    DatePicker(
                        L10n.endDate(lang),
                        selection: $editedEndDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)

                    Spacer()

                    Button {
                        requestRangeUpdate()
                    } label: {
                        Label(L10n.updatePeriodDates(lang), systemImage: "calendar.badge.clock")
                    }
                    .buttonStyle(.facio(.primary))
                    .disabled(!rangeDraftHasChanges || rangeDraftOverlaps)
                }

                if rangeDraftOverlaps {
                    InlineWarning(text: L10n.periodOverlapsForClient(lang), tone: .warning)
                } else if rangeDraftHasChanges, rangeLossSummary.hasLoss {
                    let loss = rangeLossSummary
                    InlineWarning(
                        text: L10n.periodRangeLossPreview(
                            lang,
                            days: loss.dayCount,
                            hours: loss.hours.formatted2Decimals(for: numberFormat)
                        ),
                        tone: .warning
                    )
                }
            }
            .onChange(of: editedStartDate) { _, startDate in
                if editedEndDate < startDate {
                    editedEndDate = startDate
                }
            }
            .onChange(of: editedEndDate) { _, endDate in
                if endDate < editedStartDate {
                    editedStartDate = endDate
                }
            }
        }
    }

    private var rangeDraft: (start: String, end: String) {
        let range = TimesheetPeriod.normalizedDateRange(startDate: editedStartDate, endDate: editedEndDate)
        return (range.start, range.end)
    }

    private var rangeDraftHasChanges: Bool {
        rangeDraft.start != timesheet.activeStartDateString || rangeDraft.end != timesheet.activeEndDateString
    }

    private var rangeDraftOverlaps: Bool {
        guard rangeDraftHasChanges else { return false }
        return dataStore.timesheetOverlaps(
            startDate: editedStartDate,
            endDate: editedEndDate,
            clientId: timesheet.clientId,
            excluding: timesheet.id
        )
    }

    private var rangeLossSummary: TimesheetDateRangeLossSummary {
        dataStore.timesheetDateRangeLoss(
            for: timesheet,
            startDate: editedStartDate,
            endDate: editedEndDate
        )
    }

    // MARK: - Resume

    private var clientSection: some View {
        SectionPanel(L10n.selectClientForPeriod(lang), systemImage: "person.crop.circle") {
            Button {
                showClientPicker = true
            } label: {
                HStack(spacing: FacioLayout.space12) {
                    Label(
                        timesheet.clientDisplayName.isEmpty ? L10n.noClient(lang) : timesheet.clientDisplayName,
                        systemImage: "person.crop.circle"
                    )
                    .foregroundStyle(timesheet.clientDisplayName.isEmpty ? .secondary : .primary)

                    Spacer()

                    if timesheet.hasGeneratedInvoice {
                        Text(L10n.invoiced(lang))
                            .foregroundStyle(Color.intentSuccess)
                    }

                    Label(
                        timesheet.hasClient ? L10n.changeClient(lang) : L10n.selectClientForPeriod(lang),
                        systemImage: "person.crop.circle.badge.plus"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var resumeSection: some View {
        let adj = adjHours
        let heuresMois = timesheet.totalHeuresDuMois()
        let heuresSup = timesheet.totalHeuresSupCrossPeriod(adjacentHours: adj)
        let heuresNorm = heuresMois - heuresSup
        let coutNorm = heuresNorm * timesheet.tauxNormal
        let coutSup = heuresSup * timesheet.tauxSupplementaire
        let brut = coutNorm + coutSup
        let net = brut * timesheet.coefficientNet

        return SectionPanel("\(L10n.summary(lang)) — \(timesheet.periodLabel(for: lang))", systemImage: "sum") {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 150, maximum: 230))
            ], spacing: FacioLayout.space12) {
                MetricTile(
                    title: L10n.totalHours(lang),
                    value: "\(heuresMois.formatted2Decimals(for: numberFormat))h",
                    systemImage: "clock",
                    intent: .accent(from: dataStore.companyInfo)
                )
                MetricTile(
                    title: L10n.normalHours(lang),
                    value: "\(heuresNorm.formatted2Decimals(for: numberFormat))h",
                    systemImage: "clock.badge.checkmark",
                    intent: .info
                )
                MetricTile(
                    title: L10n.overtimeHours(lang),
                    value: "\(heuresSup.formatted2Decimals(for: numberFormat))h",
                    systemImage: "clock.badge.exclamationmark",
                    intent: heuresSup > 0 ? .warning : .neutral
                )
                MetricTile(
                    title: L10n.normalCost(lang),
                    value: privacy.formatNumber(coutNorm, lang: numberFormat),
                    systemImage: "banknote",
                    intent: .neutral
                )
                MetricTile(
                    title: L10n.overtimeCost(lang),
                    value: privacy.formatNumber(coutSup, lang: numberFormat),
                    systemImage: "banknote",
                    intent: .neutral
                )
                MetricTile(
                    title: L10n.grossTotal(lang),
                    value: privacy.formatNumber(brut, lang: numberFormat),
                    systemImage: "sum",
                    intent: .success
                )
                MetricTile(
                    title: L10n.netTotal(lang),
                    value: privacy.formatNumber(net, lang: numberFormat),
                    systemImage: "checkmark.seal",
                    intent: .success
                )
            }
        }
    }

    private var hourInputModeControl: some View {
        HStack(spacing: FacioLayout.space12) {
            Label(L10n.hourInputMode(lang), systemImage: "clock.badge")
                .font(FacioFont.fieldLabel)
                .foregroundStyle(.secondary)

            Picker("", selection: $hourInputMode) {
                Text(L10n.hourInputDecimalMode(lang)).tag(TimesheetHourInputMode.decimal)
                Text(L10n.hourInputTimeMode(lang)).tag(TimesheetHourInputMode.time)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 220)
            .help(L10n.hourInputHelp(lang, mode: hourInputMode))

            Spacer()
        }
    }

    // MARK: - Semaine

    private func weekSection(weekIndex: Int, week: TimesheetWeek) -> some View {
        let adj = adjHours

        // Heures de la plage facturee dans cette semaine
        let heuresMoisSemaine = timesheet.totalHeuresPourSemaine(week)
        let supSemaine = timesheet.heuresSupPourSemaine(week, adjacentHours: adj)
        let normSemaine = heuresMoisSemaine - supSemaine

        return SectionPanel {
            VStack(spacing: FacioLayout.space10) {
                // En-tete : contenu 100% intrinsèque (Texts/Labels) → ViewThatFits autorisé.
                ViewThatFits(in: .horizontal) {
                    // Variante large : titre à gauche, stats à droite
                    HStack {
                        weekTitleBlock(week)
                        Spacer()
                        weekStatsRow(heuresMois: heuresMoisSemaine, norm: normSemaine, sup: supSemaine)
                    }

                    // Variante empilée : titre puis rangée de stats
                    VStack(alignment: .leading, spacing: FacioLayout.space8) {
                        weekTitleBlock(week)
                        weekStatsRow(heuresMois: heuresMoisSemaine, norm: normSemaine, sup: supSemaine)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                // Grille des jours : 7 colonnes égales remplissant la largeur en
                // confortable, 4 colonnes (rangées 4+3) en étroit. Compte fixe
                // plutôt que .adaptive : l'adaptatif crée des colonnes vides à
                // droite dès que la largeur dépasse 8 × minimum.
                LazyVGrid(
                    columns: dayGridColumns,
                    spacing: FacioLayout.space8
                ) {
                    ForEach(Array(week.jours.enumerated()), id: \.offset) { dayIndex, jour in
                        let estDansMois = timesheet.isBillableDay(jour)
                        let hasTimerEntries = timesheet.hasTimeEntries(on: jour.dateString)
                        VStack(spacing: FacioLayout.space4) {
                            HStack(spacing: FacioLayout.space4) {
                                Text(jour.jourSemaine.shortLabel(for: lang))
                                    .font(FacioFont.captionSmall)
                                    .foregroundStyle(.secondary)
                                // Le jour piloté par le minuteur porte son glyphe :
                                // il était seulement grisé, donc impossible à
                                // distinguer d'un champ désactivé par erreur — et
                                // invisible pour VoiceOver comme pour un daltonien.
                                if hasTimerEntries {
                                    Image(systemName: "bolt.fill")
                                        .font(FacioFont.captionSmall)
                                        .foregroundStyle(Color.intentInfo)
                                        .accessibilityLabel(L10n.timerDrivenDay(lang))
                                }
                            }
                            Text("\(jour.jourDuMois)")
                                .font(FacioFont.monoCaption)
                                .foregroundStyle(estDansMois ? .primary : .tertiary)
                            TimeField(
                                placeholder: L10n.hourInputPlaceholder(lang, mode: hourInputMode),
                                value: Binding(
                                    get: {
                                        guard weekIndex < timesheet.semaines.count,
                                              dayIndex < timesheet.semaines[weekIndex].jours.count
                                        else { return 0 }
                                        return timesheet.semaines[weekIndex].jours[dayIndex].heures
                                    },
                                    set: { newVal in
                                        guard weekIndex < timesheet.semaines.count,
                                              dayIndex < timesheet.semaines[weekIndex].jours.count
                                        else { return }
                                        timesheet.semaines[weekIndex].jours[dayIndex].heures = newVal
                                        dataStore.timesheetUpdated(timesheet, syncSharedWeeks: true)
                                    }
                                ),
                                mode: hourInputMode,
                                lang: lang,
                                focusID: jour.id,
                                focusRequest: hourFieldFocusRequest
                            )
                            .disabled(hasTimerEntries)
                            .help(hasTimerEntries ? L10n.hoursManagedByTimer(lang) : L10n.hourInputHelp(lang, mode: hourInputMode))
                            .opacity(estDansMois ? 1.0 : 0.5)
                        }
                        .padding(.vertical, FacioLayout.space4)
                        .frame(maxWidth: .infinity)
                        // Fond distinct plutôt que grisé : c'est une source de
                        // données différente, pas un contrôle indisponible.
                        .background(
                            RoundedRectangle(cornerRadius: FacioLayout.radiusField)
                                .fill(hasTimerEntries ? Color.intentInfo.opacity(0.10) : Color.clear)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            hourFieldFocusNonce += 1
                            hourFieldFocusRequest = TimeFieldFocusRequest(id: jour.id, nonce: hourFieldFocusNonce)
                        }
                    }
                }

                // La note n'apparaît que si la semaine contient effectivement un
                // jour piloté par le minuteur — sinon elle est du bruit permanent.
                if week.jours.contains(where: { timesheet.hasTimeEntries(on: $0.dateString) }) {
                    HStack(spacing: FacioLayout.space4) {
                        Image(systemName: "bolt.fill")
                        Text(L10n.timerDrivenLegend(lang))
                    }
                    .font(FacioFont.captionSmall)
                    .foregroundStyle(Color.intentInfo)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    /// Bloc titre d'une semaine (numéro + plage), partagé par les variantes ViewThatFits.
    private func weekTitleBlock(_ week: TimesheetWeek) -> some View {
        VStack(alignment: .leading, spacing: FacioLayout.space2) {
            Text(
                week.isoWeekNumber.map { L10n.weekISO(lang, number: $0) }
                    ?? L10n.week(lang, number: week.numero)
            )
            .font(FacioFont.sectionTitle)
            Text(week.label(for: lang))
                .font(FacioFont.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Rangée de stats d'une semaine (total, normales, sup, coût), partagée par les variantes ViewThatFits.
    private func weekStatsRow(heuresMois: Decimal, norm: Decimal, sup: Decimal) -> some View {
        HStack(spacing: FacioLayout.space16) {
            Label("\(heuresMois.formatted2Decimals(for: numberFormat))h", systemImage: "clock")
                .font(FacioFont.rowValue)
                .fontWeight(.medium)
            Text(L10n.normalHoursShort(lang, value: norm.formatted2Decimals(for: numberFormat)))
                .font(FacioFont.metaValue)
                .foregroundStyle(Color.intentInfo)
            if sup > 0 {
                Text(L10n.overtimeHoursShort(lang, value: sup.formatted2Decimals(for: numberFormat)))
                    .font(FacioFont.metaValue)
                    .foregroundStyle(Color.intentWarning)
                    .fontWeight(.medium)
            }
            Divider().frame(height: 14)
            let coutSemaine = norm * timesheet.tauxNormal + sup * timesheet.tauxSupplementaire
            Text(privacy.formatNumber(coutSemaine, lang: numberFormat))
                .font(FacioFont.rowValue)
                .fontWeight(.semibold)
                .foregroundStyle(Color.intentSuccess)
        }
    }

    // MARK: - Parametres

    private var parametresSection: some View {
        SectionPanel(L10n.calculationParams(lang), systemImage: "slider.horizontal.3") {
            VStack(alignment: .leading, spacing: FacioLayout.space12) {
                // La reprise des taux se faisait en silence : augmenter son tarif
                // puis créer la période suivante refacturait à l'ancien sans
                // qu'aucun écran ne le dise.
                if let repriseDe = timesheet.tauxRepriseDe {
                    InlineWarning(text: L10n.ratesCarriedOver(lang, from: repriseDe), tone: .info)
                }

                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 150, maximum: 250))
                ], spacing: FacioLayout.space12) {
                    settingsField(
                        L10n.weeklyThreshold(lang),
                        placeholder: "35",
                        hint: L10n.weeklyThresholdHint(lang),
                        value: rateBinding(\.seuilHebdo)
                    )
                    settingsField(
                        L10n.normalRate(lang),
                        placeholder: "26,39",
                        value: rateBinding(\.tauxNormal)
                    )
                    settingsField(
                        L10n.overtimeRate(lang),
                        placeholder: "39,59",
                        value: rateBinding(\.tauxSupplementaire)
                    )
                    settingsField(
                        L10n.netCoeff(lang),
                        placeholder: "0,756",
                        hint: L10n.netCoeffHint(lang),
                        // Le coefficient reste stocké tel quel — c'est lui qui
                        // multiplie le brut — mais il se LIT en pourcentage.
                        caption: netSharePercentage,
                        value: rateBinding(\.coefficientNet)
                    )
                }
            }
        }
    }

    /// « 75,6 % » à partir du coefficient 0,756.
    private var netSharePercentage: String {
        (timesheet.coefficientNet * 100).formatted2Decimals(for: numberFormat) + " %"
    }

    /// Écrire un paramètre efface la mention de reprise : à partir du moment où
    /// l'utilisateur l'a ajusté lui-même, la valeur ne vient plus d'ailleurs.
    private func rateBinding(_ keyPath: ReferenceWritableKeyPath<TimesheetPeriod, Decimal>) -> Binding<Decimal> {
        Binding(
            get: { timesheet[keyPath: keyPath] },
            set: { newValue in
                guard timesheet[keyPath: keyPath] != newValue else { return }
                timesheet[keyPath: keyPath] = newValue
                timesheet.tauxRepriseDe = nil
                dataStore.timesheetUpdated(timesheet)
            }
        )
    }

    private func settingsField(
        _ label: String,
        placeholder: String,
        hint: String? = nil,
        caption: String? = nil,
        value: Binding<Decimal>
    ) -> some View {
        VStack(alignment: .leading, spacing: FacioLayout.space4) {
            Text(label)
                .font(FacioFont.fieldLabel)
                .foregroundStyle(.secondary)
            DecimalField(placeholder: placeholder, value: value)
                .density(.regular)
                .help(hint ?? "")
            if let caption {
                Text(caption)
                    .font(FacioFont.metaValue)
                    .foregroundStyle(.secondary)
            }
            if let hint {
                Text(hint)
                    .font(FacioFont.captionSmall)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// Facturable depuis l'une OU l'autre source — la grille pouvait être vide
    /// alors que des entrées de minuteur attendaient, et le bouton restait mort.
    private var canBill: Bool {
        dataStore.canGenerateInvoice(for: timesheet)
            || dataStore.canGenerateInvoiceFromTimeEntries(for: timesheet)
    }

    private func resetRangeDraft() {
        editedStartDate = timesheet.activeStartDate
        editedEndDate = timesheet.activeEndDate
    }

    private func requestRangeUpdate() {
        guard rangeDraftHasChanges, !rangeDraftOverlaps else { return }
        if rangeLossSummary.hasLoss {
            showRangeLossAlert = true
        } else {
            applyRangeUpdate()
        }
    }

    private func applyRangeUpdate() {
        dataStore.updateTimesheetDateRange(
            timesheet,
            startDate: editedStartDate,
            endDate: editedEndDate
        )
        resetRangeDraft()
    }
}
