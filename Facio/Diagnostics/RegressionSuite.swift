#if FACIO_REGRESSION_TESTS
import CoreGraphics
import Darwin
import Foundation
import PDFKit
import SwiftUI

@MainActor
enum FacioRegressionSuite {
    private static let trigger = "--run-regressions"

    static func runIfRequested() {
        guard CommandLine.arguments.contains(trigger) else { return }

        let results = runAll()
        let failures = results.filter { !$0.passed }

        print("Facio regression suite")
        for result in results {
            if result.passed {
                print("PASS \(result.name)")
            } else {
                print("FAIL \(result.name): \(result.message ?? "unknown failure")")
            }
        }
        print("Summary: \(results.count - failures.count) passed, \(failures.count) failed")

        Darwin.exit(failures.isEmpty ? EXIT_SUCCESS : EXIT_FAILURE)
    }

    private static func runAll() -> [RegressionResult] {
        cases.map { testCase in
            do {
                try testCase.run()
                return RegressionResult(name: testCase.name, passed: true, message: nil)
            } catch let failure as RegressionFailure {
                return RegressionResult(name: testCase.name, passed: false, message: failure.message)
            } catch {
                return RegressionResult(name: testCase.name, passed: false, message: String(describing: error))
            }
        }
    }

    private static let cases: [RegressionCase] = [
        RegressionCase(name: "decimal hour input keeps decimal fractions", run: decimalHourInputKeepsDecimalFractions),
        RegressionCase(name: "time hour input requires explicit time syntax for minutes", run: timeHourInputRequiresExplicitTimeSyntaxForMinutes),
        RegressionCase(name: "hour input formatting matches selected mode and language", run: hourInputFormattingMatchesSelectedModeAndLanguage),
        RegressionCase(name: "hour input placeholder stays empty", run: hourInputPlaceholderStaysEmpty),
        RegressionCase(name: "time tracking duration parser supports clockify-like inputs", run: timeTrackingDurationParserSupportsClockifyLikeInputs),
        RegressionCase(name: "time tracking time parser supports flexible inputs", run: timeTrackingTimeParserSupportsFlexibleInputs),
        RegressionCase(name: "time tracking rounding keeps raw durations separate", run: timeTrackingRoundingKeepsRawDurationsSeparate),
        RegressionCase(name: "currency precision keeps crypto amounts", run: currencyPrecisionKeepsCryptoAmounts),
        RegressionCase(name: "accounting currency format keeps document totals readable", run: accountingCurrencyFormatKeepsDocumentTotalsReadable),
        RegressionCase(name: "document totals include VAT and line ordering", run: documentTotalsIncludeVATAndLineOrdering),
        RegressionCase(name: "document decodes old payloads without accounting conversion", run: documentDecodesOldPayloadsWithoutAccountingConversion),
        RegressionCase(name: "company decodes old payloads without intracom vat", run: companyDecodesOldPayloadsWithoutIntracomVAT),
        RegressionCase(name: "facturx applicability gates non invoices", run: facturXApplicabilityGatesNonInvoices),
        RegressionCase(name: "facturx xml maps invoice fields and totals", run: facturXXMLMapsInvoiceFieldsAndTotals),
        RegressionCase(name: "facturx xml franchise en base uses category E", run: facturXXMLFranchiseEnBaseUsesCategoryE),
        RegressionCase(name: "facturx embeds retrievable xml in pdf", run: facturXEmbedsRetrievableXMLInPDF),
        RegressionCase(name: "sent invoices become overdue after due date", run: sentInvoicesBecomeOverdueAfterDueDate),
        RegressionCase(name: "client empty record detection trims all fields", run: clientEmptyRecordDetectionTrimsAllFields),
        RegressionCase(name: "data store keeps clients while editing empty fields", run: dataStoreKeepsClientsWhileEditingEmptyFields),
        RegressionCase(name: "company migrates legacy bank fields into bank accounts", run: companyMigratesLegacyBankFieldsIntoBankAccounts),
        RegressionCase(name: "accounting revenue converts known rates and reports missing ones", run: accountingRevenueConvertsKnownRatesAndReportsMissingOnes),
        RegressionCase(name: "fiat document drops crypto payment configuration", run: fiatDocumentDropsCryptoPaymentConfiguration),
        RegressionCase(name: "bank transfer selects only usable bank accounts", run: bankTransferSelectsOnlyUsableBankAccounts),
        RegressionCase(name: "crypto payment selects only compatible non-blank wallets", run: cryptoPaymentSelectsOnlyCompatibleNonBlankWallets),
        RegressionCase(name: "payment snapshot freezes exported bank account", run: paymentSnapshotFreezesExportedBankAccount),
        RegressionCase(name: "payment snapshot survives codable round trip", run: paymentSnapshotSurvivesCodableRoundTrip),
        RegressionCase(name: "untrusted payment snapshots do not override configured payments", run: untrustedPaymentSnapshotsDoNotOverrideConfiguredPayments),
        RegressionCase(name: "paid invoices do not expose Solana Pay request", run: paidInvoicesDoNotExposeSolanaPayRequest),
        RegressionCase(name: "bitcoin payment is crypto but not Solana Pay eligible", run: bitcoinPaymentIsCryptoButNotSolanaPayEligible),
        RegressionCase(name: "document duplication keeps payment and line data without reusing identity", run: documentDuplicationKeepsPaymentAndLineDataWithoutReusingIdentity),
        RegressionCase(name: "sync state tracks pending deletes as dirty data", run: syncStateTracksPendingDeletesAsDirtyData),
        RegressionCase(name: "sync state decodes old payloads without pending delete arrays", run: syncStateDecodesOldPayloadsWithoutPendingDeleteArrays),
        RegressionCase(name: "sync state decodes malformed fields without dropping valid state", run: syncStateDecodesMalformedFieldsWithoutDroppingValidState),
        RegressionCase(name: "timesheet calendar generation uses whole weeks", run: timesheetCalendarGenerationUsesWholeWeeks),
        RegressionCase(name: "timesheet custom range generation uses whole weeks", run: timesheetCustomRangeGenerationUsesWholeWeeks),
        RegressionCase(name: "timesheet normalize calendar restores shape and keeps stored hours", run: timesheetNormalizeCalendarRestoresShapeAndKeepsStoredHours),
        RegressionCase(name: "timesheet period decodes old payloads and normalizes calendar", run: timesheetPeriodDecodesOldPayloadsAndNormalizesCalendar),
        RegressionCase(name: "timesheet invoice detail mode survives codable round trip", run: timesheetInvoiceDetailModeSurvivesCodableRoundTrip),
        RegressionCase(name: "timesheet invoice markers set generated invoice state", run: timesheetInvoiceMarkersSetGeneratedInvoiceState),
        RegressionCase(name: "timesheet periods are unique per client and month", run: timesheetPeriodsAreUniquePerClientAndMonth),
        RegressionCase(name: "timesheet custom ranges overlap by client", run: timesheetCustomRangesOverlapByClient),
        RegressionCase(name: "timesheet date range update preserves overlapping hours", run: timesheetDateRangeUpdatePreservesOverlappingHours),
        RegressionCase(name: "timesheet date range update clears excluded hours", run: timesheetDateRangeUpdateClearsExcludedHours),
        RegressionCase(name: "timesheet date range loss ignores adjacent context", run: timesheetDateRangeLossIgnoresAdjacentContext),
        RegressionCase(name: "timesheet shared weeks are scoped by client", run: timesheetSharedWeeksAreScopedByClient),
        RegressionCase(name: "data store updates linked invoice when timesheet changes", run: dataStoreUpdatesLinkedInvoiceWhenTimesheetChanges),
        RegressionCase(name: "data store keeps existing invoice stable when requested again", run: dataStoreKeepsExistingInvoiceStableWhenRequestedAgain),
        RegressionCase(name: "data store does not update sent linked invoice", run: dataStoreDoesNotUpdateSentLinkedInvoice),
        RegressionCase(name: "data store does not update manually edited linked invoice", run: dataStoreDoesNotUpdateManuallyEditedLinkedInvoice),
        RegressionCase(name: "period invoice marks covered time entries invoiced", run: periodInvoiceMarksCoveredTimeEntries),
        RegressionCase(name: "data store reuses legacy time entry invoice for period", run: dataStoreReusesLegacyTimeEntryInvoiceForPeriod),
        RegressionCase(name: "deleting linked invoice clears timesheet markers", run: deletingLinkedInvoiceClearsTimesheetMarkers),
        RegressionCase(name: "shared week sync clears context after adjacent delete", run: sharedWeekSyncClearsContextAfterAdjacentDelete),
        RegressionCase(name: "shared week sync clears context after client change", run: sharedWeekSyncClearsContextAfterClientChange),
        RegressionCase(name: "timesheet invoice summary applies client snapshot", run: timesheetInvoiceSummaryAppliesClientSnapshot),
        RegressionCase(name: "timesheet stale context hours are ignored without adjacent owner", run: timesheetStaleContextHoursAreIgnoredWithoutAdjacentOwner),
        RegressionCase(name: "timesheet custom range counts previous weekly context", run: timesheetCustomRangeCountsPreviousWeeklyContext),
        RegressionCase(name: "timesheet custom range daily invoice bills only active dates", run: timesheetCustomRangeDailyInvoiceBillsOnlyActiveDates),
        RegressionCase(name: "timesheet invoice daily lines group overtime by week", run: timesheetInvoiceDailyLinesGroupOvertimeByWeek),
        RegressionCase(name: "timesheet invoice daily lines do not split equal rates", run: timesheetInvoiceDailyLinesDoNotSplitEqualRates),
        RegressionCase(name: "timesheet invoice daily activity lines include entry names", run: timesheetInvoiceDailyActivityLinesIncludeEntryNames),
        RegressionCase(name: "timesheet invoice daily activity drops rounding residue", run: timesheetInvoiceDailyActivityDropsRoundingResidue),
        RegressionCase(name: "timesheet cross-period overtime assigns overflow to current month", run: timesheetCrossPeriodOvertimeAssignsOverflowToCurrentMonth),
        RegressionCase(name: "time entry decodes old payloads with defaults", run: timeEntryDecodesOldPayloadsWithDefaults),
        RegressionCase(name: "time entry billing snapshot survives codable round trip", run: timeEntryBillingSnapshotSurvivesCodableRoundTrip),
        RegressionCase(name: "time entries recalculate billable day hours", run: timeEntriesRecalculateBillableDayHours),
        RegressionCase(name: "soft deleted time entries stop contributing hours", run: softDeletedTimeEntriesStopContributingHours),
        RegressionCase(name: "time entry crossing midnight stays on start day", run: timeEntryCrossingMidnightStaysOnStartDay),
        RegressionCase(name: "data store keeps one active timer across periods", run: dataStoreKeepsOneActiveTimerAcrossPeriods),
        RegressionCase(name: "data store continues entry with copied details", run: dataStoreContinuesEntryWithCopiedDetails),
        RegressionCase(name: "data store adjusts running timer start without new entry", run: dataStoreAdjustsRunningTimerStartWithoutNewEntry),
        RegressionCase(name: "data store imports unbilled time entries into invoice", run: dataStoreImportsUnbilledTimeEntriesIntoInvoice),
        RegressionCase(name: "time entry csv report includes billable columns", run: timeEntryCSVReportIncludesBillableColumns),
        RegressionCase(name: "time hub stats exclude deleted entries", run: timeHubStatsExcludeDeletedEntries),
        RegressionCase(name: "time hub groups entries by client and project", run: timeHubGroupsEntriesByClientAndProject),
        RegressionCase(name: "date and decimal formatting are stable across languages", run: dateAndDecimalFormattingAreStableAcrossLanguages),
        RegressionCase(name: "email template resolves placeholders and attachments line", run: emailTemplateResolvesPlaceholdersAndAttachmentsLine),
        RegressionCase(name: "email safe filename strips unsafe characters", run: emailSafeFilenameStripsUnsafeCharacters),
        RegressionCase(name: "attachment import copies file and records metadata", run: attachmentImportCopiesFileAndRecordsMetadata),
        RegressionCase(name: "attachment duplication reports missing source files", run: attachmentDuplicationReportsMissingSourceFiles),
        RegressionCase(name: "attachment urls expose only existing files", run: attachmentURLsExposeOnlyExistingFiles),
        RegressionCase(name: "email attachment filenames use labels and dedupe", run: emailAttachmentFilenamesUseLabelsAndDedupe),
        RegressionCase(name: "pdf generation paginates long invoices", run: pdfGenerationPaginatesLongInvoices),
        RegressionCase(name: "responsive width class maps breakpoints", run: responsiveWidthClassMapsBreakpoints),
        RegressionCase(name: "window minimum fits split view columns", run: windowMinimumFitsSplitViewColumns),
        RegressionCase(name: "sheet minimums fit inside minimum window", run: sheetMinimumsFitInsideMinimumWindow),
        RegressionCase(name: "color tokens resolve differently in dark mode", run: colorTokensResolveDifferentlyInDarkMode)
    ]

    /// Garde-fou dark mode : les tokens doivent se résoudre différemment selon
    /// le colorScheme via le chemin de rendu SwiftUI (Color.resolve(in:)) —
    /// attrape les couleurs figées par une résolution prématurée.
    private static func colorTokensResolveDifferentlyInDarkMode() throws {
        var lightEnv = EnvironmentValues()
        lightEnv.colorScheme = .light
        var darkEnv = EnvironmentValues()
        darkEnv.colorScheme = .dark

        func components(_ color: Color, _ env: EnvironmentValues) -> String {
            let r = color.resolve(in: env)
            return "\(r.red) \(r.green) \(r.blue) \(r.opacity)"
        }

        let tokens: [(String, Color)] = [
            ("surfacePanel", .surfacePanel),
            ("surfaceField", .surfaceField),
            ("borderSubtle", .borderSubtle),
            ("appPrimary", .appPrimary)
        ]
        for (name, token) in tokens {
            try expect(
                components(token, lightEnv) != components(token, darkEnv),
                "\(name) should resolve to different colors in light and dark mode"
            )
        }
    }

    private static func responsiveWidthClassMapsBreakpoints() throws {
        try expectEqual(FacioWidthClass(width: FacioLayout.breakpointCompact - 1), .compact)
        try expectEqual(FacioWidthClass(width: FacioLayout.breakpointCompact), .regular)
        try expectEqual(FacioWidthClass(width: FacioLayout.breakpointWide - 1), .regular)
        try expectEqual(FacioWidthClass(width: FacioLayout.breakpointWide), .wide)
    }

    private static func windowMinimumFitsSplitViewColumns() throws {
        try expect(
            FacioLayout.sidebarMin + FacioLayout.contentColumnMin + FacioLayout.detailMin <= FacioLayout.windowMinWidth,
            "sidebar + content + detail minimums must fit in the minimum window width"
        )
    }

    private static func sheetMinimumsFitInsideMinimumWindow() throws {
        try expect(
            FacioLayout.sheetMinWidth <= FacioLayout.windowMinWidth - 80,
            "sheet minimum width must fit inside the minimum window"
        )
        try expect(
            FacioLayout.sheetMinHeight <= FacioLayout.windowMinHeight - 80,
            "sheet minimum height must fit inside the minimum window"
        )
        let fixedColumns = LineItemColumns.qty + LineItemColumns.unitPrice + LineItemColumns.vat
            + LineItemColumns.totalHT + LineItemColumns.actions
        try expect(
            FacioLayout.lineItemsCompactBreakpoint > fixedColumns + FacioLayout.fieldMinWidth,
            "compact breakpoint must trigger before the fixed line columns overflow"
        )
    }

    private static func pdfGenerationPaginatesLongInvoices() throws {
        let company = try JSONDecoder().decode(CompanyInfo.self, from: Data(#"{"nom":"Facio SAS"}"#.utf8))

        let short = Document(type: .facture, number: "Facture_2026_01")
        short.ajouterLigne(LineItem(designation: "Dev", quantite: 1, prixUnitaire: 100, tauxTVA: 20))
        let shortData = PDFGenerator(document: short, company: company).generate()
        try expect(!shortData.isEmpty, "short invoice should produce PDF data")
        let shortDoc = try require(PDFDocument(data: shortData), "short invoice PDF should parse")
        try expectEqual(shortDoc.pageCount, 1)

        let long = Document(type: .facture, number: "Facture_2026_02")
        for i in 1...60 {
            long.ajouterLigne(LineItem(designation: "Prestation \(i)", quantite: 1, prixUnitaire: 100, tauxTVA: 20))
        }
        let longData = PDFGenerator(document: long, company: company).generate()
        let longDoc = try require(PDFDocument(data: longData), "long invoice PDF should parse")
        try expect(longDoc.pageCount >= 2, "a 60-line invoice should span at least 2 pages, got \(longDoc.pageCount)")
    }

    private static func decimalHourInputKeepsDecimalFractions() throws {
        try expectDecimal(TimesheetHourInputParser.parse("6,5", mode: .decimal), equals: "6.5")
        try expectDecimal(TimesheetHourInputParser.parse("6.5", mode: .decimal), equals: "6.5")
        try expectDecimal(TimesheetHourInputParser.parse(".5", mode: .decimal), equals: "0.5")
        try expectDecimal(TimesheetHourInputParser.parse(" 1 234,25 ", mode: .decimal), equals: "1234.25")
        try expectDecimal(TimesheetHourInputParser.parse("", mode: .decimal), equals: "0")

        try expect(TimesheetHourInputParser.parse("6:30", mode: .decimal) == nil, "6:30 must be rejected in decimal mode")
        try expect(TimesheetHourInputParser.parse("6h30", mode: .decimal) == nil, "6h30 must be rejected in decimal mode")
        try expect(TimesheetHourInputParser.parse("6,5,1", mode: .decimal) == nil, "multiple separators must be rejected")
    }

    private static func timeHourInputRequiresExplicitTimeSyntaxForMinutes() throws {
        try expectDecimal(TimesheetHourInputParser.parse("6:30", mode: .time), equals: "6.5")
        try expectDecimal(TimesheetHourInputParser.parse("6h30", mode: .time), equals: "6.5")
        try expectDecimal(TimesheetHourInputParser.parse("6h", mode: .time), equals: "6")
        try expectDecimal(TimesheetHourInputParser.parse("6", mode: .time), equals: "6")

        try expect(TimesheetHourInputParser.parse("6,5", mode: .time) == nil, "decimal comma must be rejected in time mode")
        try expect(TimesheetHourInputParser.parse("6.5", mode: .time) == nil, "decimal dot must be rejected in time mode")
        try expect(TimesheetHourInputParser.parse("6:70", mode: .time) == nil, "minutes over 59 must be rejected")
        try expect(TimesheetHourInputParser.parse(":30", mode: .time) == nil, "missing hours must be rejected")
    }

    private static func hourInputFormattingMatchesSelectedModeAndLanguage() throws {
        let sixAndAHalf = decimal("6.5")

        try expectEqual(TimesheetHourInputParser.format(sixAndAHalf, mode: .decimal, lang: .fr), "6,5")
        try expectEqual(TimesheetHourInputParser.format(sixAndAHalf, mode: .decimal, lang: .en), "6.5")
        try expectEqual(TimesheetHourInputParser.format(sixAndAHalf, mode: .time, lang: .fr), "6h30")
        try expectEqual(TimesheetHourInputParser.format(sixAndAHalf, mode: .time, lang: .en), "6:30")
        try expectEqual(TimesheetHourInputParser.format(decimal("6"), mode: .time, lang: .fr), "6")
    }

    private static func hourInputPlaceholderStaysEmpty() throws {
        try expectEqual(L10n.hourInputPlaceholder(.fr, mode: .decimal), "")
        try expectEqual(L10n.hourInputPlaceholder(.fr, mode: .time), "")
        try expectEqual(L10n.hourInputPlaceholder(.en, mode: .decimal), "")
        try expectEqual(L10n.hourInputPlaceholder(.en, mode: .time), "")
    }

    private static func timeTrackingDurationParserSupportsClockifyLikeInputs() throws {
        let compactCases: [(String, Int)] = [
            ("2h", 7200),
            ("30m", 1800),
            ("1s", 1),
            ("1h30m", 5400),
            ("1h30m1s", 5401),
            ("2:45", 9900),
            ("1:1", 3660),
            ("1:61", 7260),
            ("1:1:1", 3661),
            (":30", 1800),
            (".5", 1800),
            (".25", 900),
            ("2.75", 9900),
            ("1,5", 5400),
            ("123", 4980),
            ("1234", 45240),
            ("2", 120),
        ]

        for (input, expected) in compactCases {
            let actual = try TimeTrackingService.parseDurationInput(input)
            try expectEqual(actual, expected)
        }
        let decimalTwo = try TimeTrackingService.parseDurationInput("2", format: .decimal)
        try expectEqual(decimalTwo, 7200)

        try expectThrows(try TimeTrackingService.parseDurationInput(""), "empty duration should be rejected")
        try expectThrows(try TimeTrackingService.parseDurationInput("abc"), "text duration should be rejected")
        try expectThrows(try TimeTrackingService.parseDurationInput("-1h"), "negative duration should be rejected")
        try expectThrows(try TimeTrackingService.parseDurationInput("0m"), "zero duration should be rejected")
    }

    private static func timeTrackingTimeParserSupportsFlexibleInputs() throws {
        let cases: [(String, TimeOfDay)] = [
            ("0345", TimeOfDay(hour: 3, minute: 45)),
            ("9.45", TimeOfDay(hour: 9, minute: 45)),
            ("1pm", TimeOfDay(hour: 13, minute: 0)),
            ("1 am", TimeOfDay(hour: 1, minute: 0)),
            ("13", TimeOfDay(hour: 13, minute: 0)),
            ("130", TimeOfDay(hour: 1, minute: 30)),
        ]

        for (input, expected) in cases {
            let actual = try TimeTrackingService.parseTimeOfDayInput(input)
            try expectEqual(actual, expected)
        }

        try expectThrows(try TimeTrackingService.parseTimeOfDayInput("25:00"), "hour over 23 should be rejected")
        try expectThrows(try TimeTrackingService.parseTimeOfDayInput("12:99"), "minute over 59 should be rejected")
        try expectThrows(try TimeTrackingService.parseTimeOfDayInput("9999"), "four digit invalid time should be rejected")
        try expectThrows(try TimeTrackingService.parseTimeOfDayInput("abc"), "text time should be rejected")
        try expectThrows(try TimeTrackingService.parseTimeOfDayInput("-1"), "negative time should be rejected")
    }

    private static func timeTrackingRoundingKeepsRawDurationsSeparate() throws {
        try expectEqual(TimeTrackingService.roundDurationSeconds(65, mode: .nearest, intervalMinutes: 1), 60)
        try expectEqual(TimeTrackingService.roundDurationSeconds(90, mode: .nearest, intervalMinutes: 1), 120)
        try expectEqual(TimeTrackingService.roundDurationSeconds(61, mode: .up, intervalMinutes: 1), 120)
        try expectEqual(TimeTrackingService.roundDurationSeconds(119, mode: .down, intervalMinutes: 1), 60)
        try expectEqual(TimeTrackingService.roundDurationSeconds(7 * 60, mode: .up, intervalMinutes: 15), 15 * 60)

        let roundedSeparately = [
            TimeTrackingService.roundDurationSeconds(7 * 60, mode: .up, intervalMinutes: 15),
            TimeTrackingService.roundDurationSeconds(7 * 60, mode: .up, intervalMinutes: 15),
        ].reduce(0, +)
        try expectEqual(roundedSeparately, 30 * 60)
    }

    private static func currencyPrecisionKeepsCryptoAmounts() throws {
        try expectEqual(CurrencyType.eur.maximumFractionDigits, 2)
        try expectEqual(CurrencyType.usd.maximumFractionDigits, 2)
        try expectEqual(CurrencyType.usdc.maximumFractionDigits, 6)
        try expectEqual(CurrencyType.usdt.maximumFractionDigits, 6)
        try expectEqual(CurrencyType.btc.maximumFractionDigits, 8)
        try expectEqual(CurrencyType.eth.maximumFractionDigits, 8)

        try expect(CurrencyType.usdc.supportsSolanaPay, "USDC should support Solana Pay")
        try expect(CurrencyType.usdt.supportsSolanaPay, "USDT should support Solana Pay")
        try expect(!CurrencyType.btc.supportsSolanaPay, "BTC should not support Solana Pay")
        try expect(!CurrencyType.eth.supportsSolanaPay, "ETH should not support Solana Pay")

        try expectEqual(CurrencyType.btc.formatNumber(decimal("0.00000001"), lang: .en, usesGroupingSeparator: false), "0.00000001")
        try expectEqual(CurrencyType.usdc.formatNumber(decimal("1.234567"), lang: .en, usesGroupingSeparator: false), "1.234567")
        try expectEqual(CurrencyType.eur.formatNumber(decimal("1234.5"), lang: .fr, usesGroupingSeparator: false), "1234,50")
    }

    private static func accountingCurrencyFormatKeepsDocumentTotalsReadable() throws {
        try expectEqual(CurrencyType.usdc.accountingMaximumFractionDigits, 2)
        try expectEqual(CurrencyType.usdt.accountingMaximumFractionDigits, 2)
        try expectEqual(CurrencyType.btc.accountingMaximumFractionDigits, 8)

        try expectEqual(CurrencyType.usdc.formatAccounting(decimal("1221.225667"), lang: .fr), "1\u{202F}221,23 USDC")
        try expectEqual(CurrencyType.usdc.formatAccounting(decimal("1221.225667"), lang: .en), "1,221.23 USDC")
        try expectEqual(CurrencyType.btc.formatAccounting(decimal("0.00000001"), lang: .en), "0.00000001 ₿")
    }

    private static func documentTotalsIncludeVATAndLineOrdering() throws {
        let document = Document(type: .facture, number: "F-001")
        let first = LineItem(
            designation: "Development",
            quantite: decimal("2"),
            prixUnitaire: decimal("100"),
            tauxTVA: decimal("20")
        )
        let second = LineItem(
            designation: "Support",
            quantite: decimal("3"),
            prixUnitaire: decimal("50"),
            tauxTVA: decimal("10")
        )

        document.ajouterLigne(first)
        document.ajouterLigne(second)

        try expectDecimal(document.totalHT, equals: "350")
        try expectDecimal(document.totalTVA, equals: "55")
        try expectDecimal(document.totalTTC, equals: "405")
        try expectEqual(document.lignesTriees.map(\.designation), ["Development", "Support"])

        let lineToDelete = try require(document.lignes.first, "expected a line to delete")
        document.supprimerLigne(lineToDelete)

        try expectEqual(document.lignes.count, 1)
        try expectEqual(document.lignes[0].ordre, 0)
        try expectDecimal(document.totalTTC, equals: "165")
    }

    private static func documentDecodesOldPayloadsWithoutAccountingConversion() throws {
        let data = Data(#"{"typeRawValue":"Facture","currencyRawValue":"USDC"}"#.utf8)

        let document = try JSONDecoder().decode(Document.self, from: data)

        try expectEqual(document.currency, .usdc)
        try expect(document.accountingCurrency == nil, "old payload should not invent accounting currency")
        try expect(document.accountingExchangeRate == nil, "old payload should not invent exchange rate")
        try expect(document.accountingExchangeRateDate == nil, "old payload should not invent exchange rate date")
        try expect(document.paymentSnapshot == nil, "old payload should not invent payment snapshot")
        try expectEqual(document.clientSiret, "")
        try expectEqual(document.clientTva, "")
        try expectEqual(document.clientApe, "")
        try expect(document.accountingTotal(referenceCurrency: .eur) == nil, "cross-currency old payload should need a rate")
    }

    private static func sentInvoicesBecomeOverdueAfterDueDate() throws {
        let overdue = Document(type: .facture, dateCreation: date("2026-01-01"), dateEcheance: date("2000-01-01"))
        overdue.status = .envoyee

        let paid = Document(type: .facture, dateCreation: date("2026-01-01"), dateEcheance: date("2000-01-01"))
        paid.status = .payee

        let future = Document(type: .facture, dateCreation: date("2026-01-01"), dateEcheance: date("2999-01-01"))
        future.status = .envoyee

        let quote = Document(type: .devis, dateCreation: date("2026-01-01"), dateEcheance: date("2000-01-01"))
        quote.status = .envoyee

        try expect(overdue.isOverdue, "sent invoice with past due date should be overdue")
        try expect(!paid.isOverdue, "paid invoice should not be overdue")
        try expect(!future.isOverdue, "future due date should not be overdue")
        try expect(!quote.isOverdue, "quotes should not be overdue")
    }

    private static func clientEmptyRecordDetectionTrimsAllFields() throws {
        let empty = ClientInfo(nom: " ", adresse: "\n", codePostal: "\t", ville: "", email: "", siret: "", tva: "", ape: "")
        try expect(empty.isEmptyRecord, "whitespace-only client should be considered empty")

        let withSiret = ClientInfo(siret: "82501500100027")
        try expect(!withSiret.isEmptyRecord, "client with any identifier should be kept")
    }

    private static func dataStoreKeepsClientsWhileEditingEmptyFields() throws {
        try withTemporaryDataStore { store in
            let client = ClientInfo(nom: "Client A")
            store.addClient(client)

            client.nom = ""
            try expect(client.isEmptyRecord, "blanked client should be considered empty by the model")
            try expect(store.clientUpdated(client), "editing a client empty should still save instead of deleting")
            try expect(store.clients.contains { $0.id == client.id }, "client should remain until explicit delete")
        }
    }

    private static func companyMigratesLegacyBankFieldsIntoBankAccounts() throws {
        let data = Data(#"{"nomBanque":"Wise","iban":"FR761234","bic":"TRWIBEB1","titulaireCompte":"Facio SAS"}"#.utf8)

        let company = try JSONDecoder().decode(CompanyInfo.self, from: data)
        let account = try require(company.bankAccounts.first, "legacy bank fields should create a bank account")

        try expectEqual(company.bankAccounts.count, 1)
        try expectEqual(account.label, "Wise")
        try expectEqual(account.bankName, "Wise")
        try expectEqual(account.iban, "FR761234")
        try expectEqual(account.bic, "TRWIBEB1")
        try expectEqual(account.accountHolder, "Facio SAS")
    }

    private static func accountingRevenueConvertsKnownRatesAndReportsMissingOnes() throws {
        let eurInvoice = Document(type: .facture, currency: .eur)
        eurInvoice.ajouterLigne(LineItem(quantite: decimal("1000"), prixUnitaire: decimal("1")))

        let usdcInvoice = Document(type: .facture, currency: .usdc)
        usdcInvoice.ajouterLigne(LineItem(quantite: decimal("1000"), prixUnitaire: decimal("1")))
        usdcInvoice.setAccountingExchangeRate(decimal("0.92"), referenceCurrency: .eur)

        let btcInvoice = Document(type: .facture, currency: .btc)
        btcInvoice.ajouterLigne(LineItem(quantite: decimal("1"), prixUnitaire: decimal("1")))

        let summary = AccountingRevenueService.summary(
            for: [eurInvoice, usdcInvoice, btcInvoice],
            referenceCurrency: .eur
        )

        try expectDecimal(summary.total, equals: "1920")
        try expectEqual(summary.convertedCount, 2)
        try expectEqual(summary.missingConversionCount, 1)
    }

    private static func fiatDocumentDropsCryptoPaymentConfiguration() throws {
        let document = Document(type: .facture, number: "F-002", currency: .eur, blockchain: .solana)

        try expect(document.blockchain == nil, "fiat currency should clear blockchain")

        document.paymentMode = .crypto

        try expectEqual(document.paymentMode, .aucun)
        try expect(document.blockchain == nil, "fiat crypto mode should clear blockchain")
        try expect(document.selectedWalletId == nil, "fiat crypto mode should clear selected wallet")
        try expect(!document.isSolanaPayEligible, "fiat document must not be Solana Pay eligible")
    }

    private static func bankTransferSelectsOnlyUsableBankAccounts() throws {
        let blank = BankAccountEntry(label: "Blank", iban: "  ")
        let main = BankAccountEntry(label: "EUR", bankName: "Wise", iban: " FR761234 ", bic: "BIC1", accountHolder: "Facio")
        let secondary = BankAccountEntry(label: "USD", bankName: "Revolut", iban: "FR765678")
        let accounts = [blank, main, secondary]

        let document = Document(type: .facture, number: "F-BANK", currency: .eur)
        document.paymentMode = .virement
        document.selectedBankAccountId = blank.id
        document.normalizePaymentConfiguration(availableBankAccounts: accounts)

        try expect(document.selectedBankAccountId == nil, "blank selected bank account should be cleared")
        try expectEqual(document.paymentBankAccounts(from: accounts).map(\.id), [main.id, secondary.id])
        try expectEqual(document.selectedPaymentBankAccount(from: accounts)?.id, main.id)

        document.selectedBankAccountId = secondary.id
        document.normalizePaymentConfiguration(availableBankAccounts: accounts)
        try expectEqual(document.selectedPaymentBankAccount(from: accounts)?.id, secondary.id)

        document.paymentMode = .aucun
        try expect(document.selectedBankAccountId == nil, "non-bank payment mode should clear selected bank account")
    }

    private static func cryptoPaymentSelectsOnlyCompatibleNonBlankWallets() throws {
        let blankSolana = WalletEntry(blockchain: .solana, address: "   ", label: "Blank")
        let solana = WalletEntry(blockchain: .solana, address: " SolAddr ", label: "Solana")
        let ethereum = WalletEntry(blockchain: .ethereum, address: "0xabc", label: "Ethereum")
        let wallets = [blankSolana, solana, ethereum]

        let document = Document(type: .facture, number: "F-003", currency: .usdc, blockchain: .solana)
        document.paymentMode = .crypto
        document.selectedWalletId = blankSolana.id
        document.ajouterLigne(LineItem(quantite: decimal("1"), prixUnitaire: decimal("10")))
        document.normalizePaymentConfiguration(availableWallets: wallets)

        try expect(document.selectedWalletId == nil, "blank selected wallet should be cleared")
        try expectEqual(document.paymentWallets(from: wallets).map(\.id), [solana.id])
        try expectEqual(document.selectedPaymentWallet(from: wallets)?.id, solana.id)
        try expectEqual(document.selectedPaymentWalletAddress(from: wallets), "SolAddr")
        try expect(document.isSolanaPayEligible, "USDC on Solana should be Solana Pay eligible")
        try expectEqual(document.solanaPayWalletAddress(from: wallets), "SolAddr")
    }

    private static func paymentSnapshotFreezesExportedBankAccount() throws {
        let account = BankAccountEntry(
            label: "Main",
            bankName: "Wise",
            iban: "FR761234",
            bic: "TRWIBEB1",
            accountHolder: "Facio"
        )
        let company = CompanyInfo()
        company.bankAccounts = [account]

        let document = Document(type: .facture, currency: .eur)
        document.paymentMode = .virement
        document.selectedBankAccountId = account.id

        try expect(document.freezePaymentSnapshot(from: company), "first freeze should create a snapshot")

        company.bankAccounts[0].iban = "FR769999"
        company.bankAccounts[0].bic = "NEWBIC"

        try expectEqual(document.paymentSnapshot?.iban, "FR761234")
        try expectEqual(document.paymentSnapshot?.bic, "TRWIBEB1")
        try expectEqual(document.selectedPaymentBankAccount(from: company.bankAccounts)?.trimmedIBAN, "FR769999")
    }

    private static func paymentSnapshotSurvivesCodableRoundTrip() throws {
        let wallet = WalletEntry(blockchain: .solana, address: "SolAddr", label: "Main")
        let company = CompanyInfo()
        company.wallets = [wallet]

        let document = Document(type: .facture, number: "F-SNAP", currency: .usdc, blockchain: .solana)
        document.paymentMode = .crypto
        document.selectedWalletId = wallet.id
        document.ajouterLigne(LineItem(quantite: decimal("1"), prixUnitaire: decimal("10")))
        document.normalizePaymentConfiguration(availableWallets: company.wallets)
        try expect(document.freezePaymentSnapshot(from: company), "crypto snapshot should be created")

        let data = try JSONEncoder().encode(document)
        let decoded = try JSONDecoder().decode(Document.self, from: data)

        try expectEqual(decoded.paymentSnapshot?.paymentMode, .crypto)
        try expectEqual(decoded.paymentSnapshot?.blockchain, .solana)
        try expectEqual(decoded.paymentSnapshot?.walletAddress, "SolAddr")
        try expectEqual(decoded.solanaPayWalletAddress(from: []), "SolAddr")

        decoded.currency = .eur
        try expect(decoded.paymentSnapshot == nil, "changing currency should clear stale payment snapshot")
    }

    private static func untrustedPaymentSnapshotsDoNotOverrideConfiguredPayments() throws {
        let wallet = WalletEntry(blockchain: .solana, address: "LegitSolAddr", label: "Main")
        let company = CompanyInfo()
        company.wallets = [wallet]

        let document = Document(type: .facture, number: "F-REMOTE", currency: .usdc, blockchain: .solana)
        document.paymentMode = .crypto
        document.selectedWalletId = wallet.id
        document.ajouterLigne(LineItem(quantite: decimal("1"), prixUnitaire: decimal("10")))
        document.normalizePaymentConfiguration(availableWallets: company.wallets)
        document.paymentSnapshot = DocumentPaymentSnapshot(
            paymentModeRawValue: PaymentMode.crypto.rawValue,
            blockchainRawValue: Blockchain.solana.rawValue,
            walletAddress: "AttackerSolAddr",
            isTrustedForExport: false
        )

        try expect(document.trustedPaymentSnapshot == nil, "remote sync snapshots should not be trusted for export")
        try expectEqual(document.solanaPayWalletAddress(from: company.wallets), "LegitSolAddr")
    }

    private static func paidInvoicesDoNotExposeSolanaPayRequest() throws {
        let wallet = WalletEntry(blockchain: .solana, address: "SolAddr", label: "Main")
        let document = Document(type: .facture, number: "F-PAID", currency: .usdc, blockchain: .solana)

        document.paymentMode = .crypto
        document.selectedWalletId = wallet.id
        document.ajouterLigne(LineItem(quantite: decimal("1"), prixUnitaire: decimal("10")))
        document.normalizePaymentConfiguration(availableWallets: [wallet])

        document.status = .envoyee
        try expectEqual(document.solanaPayWalletAddress(from: [wallet]), "SolAddr")

        document.status = .payee
        try expect(document.solanaPayWalletAddress(from: [wallet]) == nil, "paid invoice should not expose payment QR data")

        let zeroAmount = Document(type: .facture, number: "F-ZERO", currency: .usdc, blockchain: .solana)
        zeroAmount.paymentMode = .crypto
        zeroAmount.selectedWalletId = wallet.id
        zeroAmount.normalizePaymentConfiguration(availableWallets: [wallet])
        try expect(zeroAmount.solanaPayWalletAddress(from: [wallet]) == nil, "zero amount invoice should not expose payment QR data")
    }

    private static func bitcoinPaymentIsCryptoButNotSolanaPayEligible() throws {
        let wallet = WalletEntry(blockchain: .bitcoin, address: "bc1test", label: "BTC")
        let document = Document(type: .facture, number: "F-004", currency: .btc, blockchain: .bitcoin)

        document.paymentMode = .crypto
        document.selectedWalletId = wallet.id
        document.normalizePaymentConfiguration(availableWallets: [wallet])

        try expectEqual(document.paymentMode, .crypto)
        try expectEqual(document.blockchain, .bitcoin)
        try expectEqual(document.selectedPaymentWalletAddress(from: [wallet]), "bc1test")
        try expect(!document.isSolanaPayEligible, "BTC should not be Solana Pay eligible")
        try expect(document.solanaPayWalletAddress(from: [wallet]) == nil, "BTC should not expose Solana Pay address")
    }

    private static func documentDuplicationKeepsPaymentAndLineDataWithoutReusingIdentity() throws {
        let wallet = WalletEntry(blockchain: .solana, address: "SolAddr", label: "Main")
        let document = Document(type: .devis, number: "D-001", currency: .usdc, blockchain: .solana)
        document.clientNom = "Client"
        document.clientSiret = "82501500100027"
        document.clientTva = "FR96825015001"
        document.clientApe = "7112P"
        document.notes = "Notes"
        document.langue = .en
        document.paymentMode = .crypto
        document.selectedWalletId = wallet.id
        document.setAccountingExchangeRate(decimal("0.92"), referenceCurrency: .eur)
        document.ajouterLigne(LineItem(designation: "Task", quantite: decimal("1.5"), prixUnitaire: decimal("80"), tauxTVA: decimal("20")))

        let copy = document.dupliquer()

        try expect(copy.id != document.id, "copy should get a new id")
        try expectEqual(copy.type, .devis)
        try expectEqual(copy.number, "")
        try expectEqual(copy.clientNom, "Client")
        try expectEqual(copy.clientSiret, "82501500100027")
        try expectEqual(copy.clientTva, "FR96825015001")
        try expectEqual(copy.clientApe, "7112P")
        try expectEqual(copy.notes, "Notes")
        try expectEqual(copy.langue, .en)
        try expectEqual(copy.currency, .usdc)
        try expectEqual(copy.blockchain, .solana)
        try expectEqual(copy.paymentMode, .crypto)
        try expectEqual(copy.selectedWalletId, wallet.id)
        try expect(copy.accountingExchangeRate == nil, "duplicated document should not reuse accounting exchange rate")
        try expect(copy.paymentSnapshot == nil, "duplicated document should not reuse payment snapshot")
        try expectEqual(copy.lignes.count, 1)
        try expect(copy.lignes[0].id != document.lignes[0].id, "duplicated line should get a new id")
        try expectDecimal(copy.totalTTC, equals: "144")

        let bankAccount = BankAccountEntry(label: "Main", iban: "FR761234")
        let bankDocument = Document(type: .facture, currency: .eur)
        bankDocument.paymentMode = .virement
        bankDocument.selectedBankAccountId = bankAccount.id

        let bankCopy = bankDocument.dupliquer()

        try expectEqual(bankCopy.paymentMode, .virement)
        try expectEqual(bankCopy.selectedBankAccountId, bankAccount.id)
    }

    private static func syncStateTracksPendingDeletesAsDirtyData() throws {
        let documentId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let clientId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        var state = SyncState()

        state.enqueueDelete(id: documentId, for: .documents)
        state.enqueueDelete(id: documentId, for: .documents)
        state.enqueueDelete(id: clientId, for: .clients)
        state.enqueueDelete(id: UUID(), for: .company)

        try expectEqual(state.pendingDeleteIds(for: .documents), [documentId.uuidString])
        try expectEqual(state.pendingDeleteIds(for: .clients), [clientId.uuidString])
        try expectEqual(state.pendingDeleteIds(for: .company), [])
        try expect(state.isDirty(.documents), "document pending delete should mark documents dirty")
        try expect(state.isDirty(.clients), "client pending delete should mark clients dirty")
        try expect(state.hasDirtyData, "pending deletes should count as dirty data")

        state.setPendingDeleteIds([], for: .documents)
        try expect(!state.isDirty(.documents), "cleared document pending deletes should not remain dirty")
        try expect(state.isDirty(.clients), "client pending delete should remain dirty")
    }

    private static func syncStateDecodesOldPayloadsWithoutPendingDeleteArrays() throws {
        let data = Data(#"{"documentsDirty":true,"migrationCompleted":true}"#.utf8)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let state = try decoder.decode(SyncState.self, from: data)

        try expect(state.documentsDirty, "old dirty flag should decode")
        try expect(state.migrationCompleted, "old migration flag should decode")
        try expectEqual(state.pendingDeleteIds(for: .documents), [])
        try expectEqual(state.pendingDeleteIds(for: .clients), [])
        try expectEqual(state.pendingDeleteIds(for: .timesheets), [])
        try expect(state.isDirty(.documents), "documents should remain dirty")
        try expect(!state.isDirty(.clients), "clients should remain clean")
    }

    private static func syncStateDecodesMalformedFieldsWithoutDroppingValidState() throws {
        let documentId = "11111111-1111-1111-1111-111111111111"
        let clientId = "22222222-2222-2222-2222-222222222222"
        let data = Data(
            """
            {
              "documentsDirty": "malformed",
              "clientsDirty": false,
              "companyDirty": true,
              "timesheetsDirty": false,
              "lastFullSyncAt": "malformed",
              "migrationCompleted": "malformed",
              "pendingDocumentDeleteIds": ["\(documentId)", 42, null],
              "pendingClientDeleteIds": ["\(clientId)"],
              "pendingTimesheetDeleteIds": 42
            }
            """.utf8
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let state = try decoder.decode(SyncState.self, from: data)

        try expect(state.documentsDirty, "malformed document state should decode conservatively")
        try expect(!state.clientsDirty, "valid clean client flag should remain clean")
        try expect(state.companyDirty, "valid company dirty flag should be preserved")
        try expect(state.timesheetsDirty, "malformed timesheet delete queue should decode conservatively")
        try expect(!state.migrationCompleted, "malformed migration flag should not be treated as complete")
        try expectEqual(state.pendingDeleteIds(for: .documents), [documentId])
        try expectEqual(state.pendingDeleteIds(for: .clients), [clientId])
        try expectEqual(state.pendingDeleteIds(for: .timesheets), [])
    }

    private static func timesheetCalendarGenerationUsesWholeWeeks() throws {
        let weeks = TimesheetPeriod.genererSemaines(mois: 3, annee: 2026)

        try expectEqual(weeks.count, 6)
        try expect(weeks.allSatisfy { $0.jours.count == 7 }, "every generated week should contain seven days")
        try expectEqual(weeks.first?.jours.first?.dateString, "2026-02-23")
        try expectEqual(weeks.first?.jours.last?.dateString, "2026-03-01")
        try expectEqual(weeks.last?.jours.first?.dateString, "2026-03-30")
        try expectEqual(weeks.last?.jours.last?.dateString, "2026-04-05")
    }

    private static func timesheetCustomRangeGenerationUsesWholeWeeks() throws {
        let period = TimesheetPeriod(startDate: date("2026-04-24"), endDate: date("2026-05-12"))

        try expect(period.isCustomRange, "custom date range should be marked custom")
        try expectEqual(period.activeStartDateString, "2026-04-24")
        try expectEqual(period.activeEndDateString, "2026-05-12")
        try expectEqual(period.semaines.count, 4)
        try expectEqual(period.semaines.first?.jours.first?.dateString, "2026-04-20")
        try expectEqual(period.semaines.last?.jours.last?.dateString, "2026-05-17")
        try expect(!period.isBillableDateString("2026-04-23"), "day before range should be context only")
        try expect(period.isBillableDateString("2026-05-12"), "range end should be billable")
    }

    private static func timesheetNormalizeCalendarRestoresShapeAndKeepsStoredHours() throws {
        let period = TimesheetPeriod(mois: 3, annee: 2026)
        let expectedWeekCount = period.semaines.count
        var preservedDay = period.semaines[1].jours[2]
        preservedDay.heures = decimal("7.5")
        let storedDayId = preservedDay.id
        let storedDate = preservedDay.dateString
        let storedWeekId = UUID()

        period.nom = ""
        period.semaines = [
            TimesheetWeek(id: storedWeekId, numero: 99, jours: [preservedDay]),
            TimesheetWeek(id: UUID(), numero: 99, jours: [preservedDay])
        ]

        try expect(period.normalizeCalendar(), "normalization should report a change")
        try expectEqual(period.semaines.count, expectedWeekCount)
        try expectEqual(period.nom, "Mars 2026")

        let restoredDay = try require(period.semaines.flatMap(\.jours).first { $0.dateString == storedDate }, "stored day should be restored")
        try expectEqual(restoredDay.id, storedDayId)
        try expectDecimal(restoredDay.heures, equals: "7.5")
    }

    private static func timesheetPeriodDecodesOldPayloadsAndNormalizesCalendar() throws {
        let data = Data(#"{"mois":3,"annee":2026,"semaines":[]}"#.utf8)

        let period = try JSONDecoder().decode(TimesheetPeriod.self, from: data)

        try expectEqual(period.mois, 3)
        try expectEqual(period.annee, 2026)
        try expectEqual(period.semaines.count, TimesheetPeriod.genererSemaines(mois: 3, annee: 2026).count)
        try expect(period.invoiceDocumentId == nil, "old payload should not invent invoice id")
        try expect(period.billedAt == nil, "old payload should not invent billed date")
        try expect(period.clientId == nil, "old payload should not invent client id")
        try expectEqual(period.clientNom, "")
        try expectEqual(period.clientSiret, "")
        try expectEqual(period.clientTva, "")
        try expectEqual(period.clientApe, "")
        try expect(!period.hasClient, "old payload should not be marked with a client")
        try expect(!period.hasGeneratedInvoice, "old payload should not be marked invoiced")
        try expectEqual(period.invoiceDetailMode, .summary)
        try expectEqual(period.nom, "Mars 2026")
    }

    private static func timesheetInvoiceDetailModeSurvivesCodableRoundTrip() throws {
        let period = TimesheetPeriod(mois: 4, annee: 2026)
        period.invoiceDetailMode = .dailyActivity
        period.invoiceDocumentId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")
        period.billedAt = date("2026-04-30")

        let data = try JSONEncoder().encode(period)
        let decoded = try JSONDecoder().decode(TimesheetPeriod.self, from: data)

        try expectEqual(decoded.invoiceDetailMode, .dailyActivity)
        try expectEqual(decoded.invoiceDocumentId, period.invoiceDocumentId)
        try expect(decoded.billedAt != nil, "billed date should round-trip")
    }

    private static func timesheetInvoiceMarkersSetGeneratedInvoiceState() throws {
        let period = TimesheetPeriod(mois: 4, annee: 2026)

        try expect(!period.hasGeneratedInvoice, "new period should not be marked invoiced")

        period.invoiceDocumentId = UUID()
        try expect(period.hasGeneratedInvoice, "invoice id should mark period invoiced")

        period.invoiceDocumentId = nil
        period.billedAt = Date()
        try expect(period.hasGeneratedInvoice, "billed date should mark period invoiced")
    }

    private static func timesheetPeriodsAreUniquePerClientAndMonth() throws {
        let clientA = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let clientB = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let period = TimesheetPeriod(mois: 5, annee: 2026)
        period.clientId = clientA
        period.clientNom = "Client A"

        try expect(
            TimesheetPeriod.periodExists(in: [period], mois: 5, annee: 2026, clientId: clientA),
            "same client and month should be detected as duplicate"
        )
        try expect(
            !TimesheetPeriod.periodExists(in: [period], mois: 5, annee: 2026, clientId: clientB),
            "different client should be allowed in same month"
        )
        try expect(
            !TimesheetPeriod.periodExists(in: [period], mois: 5, annee: 2026, clientId: clientA, excluding: period.id),
            "current period should be excluded when changing its own client"
        )
    }

    private static func timesheetCustomRangesOverlapByClient() throws {
        let clientA = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let clientB = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let april = TimesheetPeriod(mois: 4, annee: 2026)
        april.clientId = clientA

        try expect(
            TimesheetPeriod.periodOverlaps(
                in: [april],
                startDate: date("2026-04-24"),
                endDate: date("2026-05-12"),
                clientId: clientA
            ),
            "custom range should overlap same client's monthly period"
        )
        try expect(
            !TimesheetPeriod.periodOverlaps(
                in: [april],
                startDate: date("2026-04-24"),
                endDate: date("2026-05-12"),
                clientId: clientB
            ),
            "different client should be allowed on overlapping dates"
        )
        try expect(
            !TimesheetPeriod.periodOverlaps(
                in: [april],
                startDate: date("2026-05-01"),
                endDate: date("2026-05-12"),
                clientId: clientA
            ),
            "non-overlapping range should be allowed for same client"
        )
    }

    private static func timesheetDateRangeUpdatePreservesOverlappingHours() throws {
        try withTemporaryDataStore { store in
            let client = ClientInfo(nom: "Client A")
            let period = TimesheetPeriod(
                startDate: date("2025-05-05"),
                endDate: date("2025-05-10"),
                client: client
            )
            try setHours(period, dateString: "2025-05-05", hours: decimal("8"))
            try setHours(period, dateString: "2025-05-10", hours: decimal("4"))

            store.addTimesheet(period)
            store.updateTimesheetDateRange(
                period,
                startDate: date("2025-05-03"),
                endDate: date("2025-05-12")
            )

            try expectEqual(period.activeStartDateString, "2025-05-03")
            try expectEqual(period.activeEndDateString, "2025-05-12")
            try expectDecimal(hours(in: period, dateString: "2025-05-05"), equals: "8")
            try expectDecimal(hours(in: period, dateString: "2025-05-10"), equals: "4")
            try expectDecimal(hours(in: period, dateString: "2025-05-12"), equals: "0")
        }
    }

    private static func timesheetDateRangeUpdateClearsExcludedHours() throws {
        try withTemporaryDataStore { store in
            let client = ClientInfo(nom: "Client A")
            let period = TimesheetPeriod(
                startDate: date("2025-05-05"),
                endDate: date("2025-05-10"),
                client: client
            )
            try setHours(period, dateString: "2025-05-05", hours: decimal("8"))
            try setHours(period, dateString: "2025-05-07", hours: decimal("6"))
            try setHours(period, dateString: "2025-05-10", hours: decimal("4"))
            store.addTimesheet(period)

            let loss = store.timesheetDateRangeLoss(
                for: period,
                startDate: date("2025-05-06"),
                endDate: date("2025-05-09")
            )
            try expectEqual(loss.dayCount, 2)
            try expectDecimal(loss.hours, equals: "12")

            store.updateTimesheetDateRange(
                period,
                startDate: date("2025-05-06"),
                endDate: date("2025-05-09")
            )

            try expectEqual(period.activeStartDateString, "2025-05-06")
            try expectEqual(period.activeEndDateString, "2025-05-09")
            try expectDecimal(hours(in: period, dateString: "2025-05-05"), equals: "0")
            try expectDecimal(hours(in: period, dateString: "2025-05-07"), equals: "6")
            try expectDecimal(hours(in: period, dateString: "2025-05-10"), equals: "0")
        }
    }

    private static func timesheetDateRangeLossIgnoresAdjacentContext() throws {
        try withTemporaryDataStore { store in
            let client = ClientInfo(nom: "Client A")
            let previous = TimesheetPeriod(
                startDate: date("2026-04-27"),
                endDate: date("2026-05-12"),
                client: client
            )
            let current = TimesheetPeriod(
                startDate: date("2026-05-13"),
                endDate: date("2026-06-06"),
                client: client
            )

            try setHours(previous, dateString: "2026-05-11", hours: decimal("10.95"))
            try setHours(previous, dateString: "2026-05-12", hours: decimal("7.25"))
            try setHours(current, dateString: "2026-05-29", hours: decimal("2"))

            store.addTimesheet(previous)
            store.addTimesheet(current)
            store.syncSharedWeeks(for: current)

            try expectDecimal(hours(in: current, dateString: "2026-05-11"), equals: "10.95")
            try expectDecimal(hours(in: current, dateString: "2026-05-12"), equals: "7.25")

            let loss = store.timesheetDateRangeLoss(
                for: current,
                startDate: date("2026-05-13"),
                endDate: date("2026-06-18")
            )

            try expectEqual(loss.dayCount, 0)
            try expectDecimal(loss.hours, equals: "0")
        }
    }

    private static func timesheetSharedWeeksAreScopedByClient() throws {
        let clientA = ClientInfo(nom: "Client A")
        let clientB = ClientInfo(nom: "Client B")
        let marchA = TimesheetPeriod(mois: 3, annee: 2026, client: clientA)
        let aprilA = TimesheetPeriod(mois: 4, annee: 2026, client: clientA)
        let aprilB = TimesheetPeriod(mois: 4, annee: 2026, client: clientB)
        let legacyMarch = TimesheetPeriod(mois: 3, annee: 2026)
        let legacyApril = TimesheetPeriod(mois: 4, annee: 2026)

        try expect(marchA.hasSameClientScope(as: aprilA), "same client should share adjacent weeks")
        try expect(!marchA.hasSameClientScope(as: aprilB), "different clients must not share adjacent weeks")
        try expect(!marchA.hasSameClientScope(as: legacyMarch), "client-scoped period must not share with legacy period")
        try expect(legacyMarch.hasSameClientScope(as: legacyApril), "legacy periods should keep previous adjacent behavior")
    }

    private static func dataStoreUpdatesLinkedInvoiceWhenTimesheetChanges() throws {
        try withTemporaryDataStore { store in
            store.companyInfo.deviseParDefaut = .eur
            store.companyInfo.tauxTVAParDefaut = 0

            let clientA = ClientInfo(nom: "Client A", adresse: "1 rue A", codePostal: "75001", ville: "Paris")
            let clientB = ClientInfo(nom: "Client B", adresse: "2 rue B", codePostal: "69000", ville: "Lyon")
            let period = TimesheetPeriod(mois: 4, annee: 2026, client: clientA)
            period.tauxNormal = decimal("10")
            period.tauxSupplementaire = decimal("20")
            try setHours(period, dateString: "2026-04-01", hours: decimal("8"))

            store.addTimesheet(period)
            let invoice = try require(store.generateInvoice(from: period, detailMode: .summary), "expected invoice to be generated")
            let invoiceId = invoice.id
            let lineId = try require(invoice.lignes.first?.id, "expected generated invoice line id")
            let originalSignature = try require(invoice.timesheetAutoSyncSignature, "expected generated invoice signature")

            try expectEqual(store.documents.count, 1)
            try expectDecimal(invoice.lignes.first?.quantite, equals: "8")
            try expectDecimal(invoice.lignes.first?.prixUnitaire, equals: "10")
            try expect(!store.canGenerateInvoice(for: period), "linked period should not be invoiceable again")

            period.applyClient(clientB)
            period.tauxNormal = decimal("12")
            try setHours(period, dateString: "2026-04-01", hours: decimal("10"))
            store.timesheetUpdated(period)

            let refreshed = try require(store.existingInvoice(for: period), "expected linked invoice to remain attached")
            try expectEqual(store.documents.count, 1)
            try expectEqual(refreshed.id, invoiceId)
            try expectEqual(refreshed.clientNom, "Client B")
            try expectEqual(refreshed.clientVille, "Lyon")
            try expectEqual(refreshed.lignes.first?.id, lineId)
            try expectDecimal(refreshed.lignes.first?.quantite, equals: "10")
            try expectDecimal(refreshed.lignes.first?.prixUnitaire, equals: "12")
            try expect(refreshed.timesheetAutoSyncSignature != originalSignature, "auto-sync signature should move with generated content")
        }
    }

    private static func dataStoreKeepsExistingInvoiceStableWhenRequestedAgain() throws {
        try withTemporaryDataStore { store in
            store.companyInfo.deviseParDefaut = .eur
            store.companyInfo.tauxTVAParDefaut = 0

            let client = ClientInfo(nom: "Client A")
            let period = TimesheetPeriod(mois: 4, annee: 2026, client: client)
            try setHours(period, dateString: "2026-04-01", hours: decimal("8"))

            store.addTimesheet(period)
            let invoice = try require(store.generateInvoice(from: period, detailMode: .summary), "expected summary invoice")
            let invoiceId = invoice.id

            try expectEqual(invoice.lignes.first?.designation, "Heures de travail")
            try expectEqual(period.invoiceDetailMode, .summary)

            let reused = try require(store.generateInvoice(from: period, detailMode: .daily), "expected existing invoice to be reused")

            try expectEqual(reused.id, invoiceId)
            try expectEqual(store.documents.count, 1)
            try expectEqual(period.invoiceDetailMode, .summary)
            try expectEqual(reused.lignes.first?.designation, "Heures de travail")
            try expect(!store.canGenerateInvoice(for: period), "already linked period should not offer generation")
        }
    }

    private static func dataStoreDoesNotUpdateSentLinkedInvoice() throws {
        try withTemporaryDataStore { store in
            store.companyInfo.deviseParDefaut = .eur
            store.companyInfo.tauxTVAParDefaut = 0

            let client = ClientInfo(nom: "Client A")
            let period = TimesheetPeriod(mois: 4, annee: 2026, client: client)
            period.tauxNormal = decimal("10")
            try setHours(period, dateString: "2026-04-01", hours: decimal("8"))

            store.addTimesheet(period)
            let invoice = try require(store.generateInvoice(from: period, detailMode: .summary), "expected invoice")
            invoice.status = .envoyee
            store.documentUpdated(invoice)

            period.tauxNormal = decimal("12")
            try setHours(period, dateString: "2026-04-01", hours: decimal("10"))
            store.timesheetUpdated(period)

            let refreshed = try require(store.existingInvoice(for: period), "expected linked invoice")
            try expectEqual(refreshed.status, .envoyee)
            try expectDecimal(refreshed.lignes.first?.quantite, equals: "8")
            try expectDecimal(refreshed.lignes.first?.prixUnitaire, equals: "10")
        }
    }

    private static func dataStoreDoesNotUpdateManuallyEditedLinkedInvoice() throws {
        try withTemporaryDataStore { store in
            store.companyInfo.deviseParDefaut = .eur
            store.companyInfo.tauxTVAParDefaut = 0

            let client = ClientInfo(nom: "Client A")
            let period = TimesheetPeriod(mois: 4, annee: 2026, client: client)
            period.tauxNormal = decimal("10")
            try setHours(period, dateString: "2026-04-01", hours: decimal("8"))

            store.addTimesheet(period)
            let invoice = try require(store.generateInvoice(from: period, detailMode: .summary), "expected invoice")
            invoice.lignes[0].designation = "Prestation ajustee"
            store.documentUpdated(invoice)

            period.tauxNormal = decimal("12")
            try setHours(period, dateString: "2026-04-01", hours: decimal("10"))
            store.timesheetUpdated(period)

            let refreshed = try require(store.existingInvoice(for: period), "expected linked invoice")
            try expectEqual(refreshed.lignes.first?.designation, "Prestation ajustee")
            try expectDecimal(refreshed.lignes.first?.quantite, equals: "8")
            try expectDecimal(refreshed.lignes.first?.prixUnitaire, equals: "10")
        }
    }

    private static func periodInvoiceMarksCoveredTimeEntries() throws {
        try withTemporaryDataStore { store in
            store.companyInfo.deviseParDefaut = .eur
            store.companyInfo.tauxTVAParDefaut = 0

            let client = ClientInfo(nom: "Client A")
            let period = TimesheetPeriod(mois: 4, annee: 2026, client: client)
            let billable = TimeEntry(
                projectName: "Facio",
                taskName: "Dev",
                isBillable: true,
                startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 9),
                endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 11)
            )
            let nonBillable = TimeEntry(
                projectName: "Facio",
                taskName: "Admin",
                isBillable: false,
                startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 12),
                endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 13)
            )

            store.addTimesheet(period)
            store.addTimeEntry(billable, to: period)
            store.addTimeEntry(nonBillable, to: period)

            try expect(store.canGenerateInvoiceFromTimeEntries(for: period), "unbilled entry should be invoiceable before period invoice")
            let invoice = try require(store.generateInvoice(from: period, detailMode: .summary), "expected invoice")

            try expect(billable.invoiceDocumentId == invoice.id, "billable entry should point to period invoice")
            try expect(billable.invoiceLineItemId == nil, "period invoice does not map entries to a specific line")
            try expect(billable.invoicedAt != nil, "billable entry should have an invoiced timestamp")
            try expect(nonBillable.invoiceDocumentId == nil, "non-billable entry should remain uninvoiced")
            try expect(!store.canGenerateInvoiceFromTimeEntries(for: period), "period invoice should remove time entry invoice action")
        }
    }

    private static func dataStoreReusesLegacyTimeEntryInvoiceForPeriod() throws {
        try withTemporaryDataStore { store in
            store.companyInfo.deviseParDefaut = .eur
            store.companyInfo.tauxTVAParDefaut = 0

            let client = ClientInfo(nom: "Client A")
            let period = TimesheetPeriod(mois: 4, annee: 2026, client: client)
            let entry = TimeEntry(
                projectName: "Facio",
                taskName: "Dev",
                isBillable: true,
                startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 9),
                endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 11)
            )
            let legacyInvoice = Document(type: .facture, number: "Facture_2026_legacy")
            legacyInvoice.lignes = [
                LineItem(designation: "Legacy time", quantite: decimal("2"), prixUnitaire: decimal("100"), tauxTVA: 0)
            ]

            store.addTimesheet(period)
            store.addTimeEntry(entry, to: period)
            store.addDocument(legacyInvoice)
            entry.markInvoiced(documentId: legacyInvoice.id, lineItemId: legacyInvoice.lignes[0].id, at: date("2026-04-30"))

            try expect(store.existingInvoice(for: period) == nil, "legacy entry invoice should start unlinked")
            try expect(store.existingBillableHoursInvoice(for: period)?.id == legacyInvoice.id, "legacy entry invoice should be discovered")
            try expect(!store.canGenerateInvoice(for: period), "legacy entry invoice should block duplicate period generation")

            let reused = try require(store.generateInvoice(from: period, detailMode: .summary), "expected legacy invoice to be reused")
            try expectEqual(reused.id, legacyInvoice.id)
            try expectEqual(store.documents.count, 1)
            try expect(period.invoiceDocumentId == legacyInvoice.id, "period should be linked to reused invoice")
            try expect(legacyInvoice.sourceTimesheetId == period.id, "reused invoice should get period source link")
            try expectEqual(legacyInvoice.lignes.first?.designation, "Legacy time")
        }
    }

    private static func deletingLinkedInvoiceClearsTimesheetMarkers() throws {
        try withTemporaryDataStore { store in
            store.companyInfo.deviseParDefaut = .eur

            let client = ClientInfo(nom: "Client A")
            let period = TimesheetPeriod(mois: 4, annee: 2026, client: client)
            let entry = TimeEntry(
                projectName: "Facio",
                taskName: "Dev",
                isBillable: true,
                startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 9),
                endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 17)
            )

            store.addTimesheet(period)
            store.addTimeEntry(entry, to: period)
            let invoice = try require(store.generateInvoice(from: period, detailMode: .summary), "expected invoice")

            try expect(period.hasGeneratedInvoice, "period should be marked invoiced")
            try expect(entry.isInvoiced, "covered entry should be marked invoiced")
            store.deleteDocument(invoice)

            try expect(store.documents.isEmpty, "linked invoice should be deleted")
            try expect(period.invoiceDocumentId == nil, "deleting invoice should clear invoice id")
            try expect(period.billedAt == nil, "deleting invoice should clear billed date")
            try expect(entry.invoiceDocumentId == nil, "deleting invoice should clear entry invoice id")
            try expect(entry.invoicedAt == nil, "deleting invoice should clear entry invoice timestamp")
            try expect(store.canGenerateInvoice(for: period), "period should be invoiceable again")
        }
    }

    private static func sharedWeekSyncClearsContextAfterAdjacentDelete() throws {
        try withTemporaryDataStore { store in
            let client = ClientInfo(nom: "Client A")
            let march = TimesheetPeriod(mois: 3, annee: 2026, client: client)
            let april = TimesheetPeriod(mois: 4, annee: 2026, client: client)
            try setHours(march, dateString: "2026-03-30", hours: decimal("8"))
            try setHours(march, dateString: "2026-03-31", hours: decimal("7"))

            store.addTimesheet(march)
            store.addTimesheet(april)
            store.syncSharedWeeks(for: march)

            try expectDecimal(hours(in: april, dateString: "2026-03-30"), equals: "8")
            try expectDecimal(store.adjacentHours(for: april)["2026-03-30"], equals: "8")

            store.deleteTimesheet(march)

            try expectDecimal(hours(in: april, dateString: "2026-03-30"), equals: "0")
            try expect(store.adjacentHours(for: april)["2026-03-30"] == nil, "deleted adjacent period should remove context source")
        }
    }

    private static func sharedWeekSyncClearsContextAfterClientChange() throws {
        try withTemporaryDataStore { store in
            let clientA = ClientInfo(nom: "Client A")
            let clientB = ClientInfo(nom: "Client B")
            let marchA = TimesheetPeriod(mois: 3, annee: 2026, client: clientA)
            let april = TimesheetPeriod(mois: 4, annee: 2026, client: clientA)
            try setHours(marchA, dateString: "2026-03-30", hours: decimal("8"))
            try setHours(marchA, dateString: "2026-03-31", hours: decimal("8"))

            store.addTimesheet(marchA)
            store.addTimesheet(april)
            store.syncSharedWeeks(for: marchA)

            try expectDecimal(hours(in: april, dateString: "2026-03-30"), equals: "8")

            april.applyClient(clientB)
            store.timesheetUpdated(april, syncSharedWeeks: true)

            try expectDecimal(hours(in: april, dateString: "2026-03-30"), equals: "0")
            try expect(store.adjacentHours(for: april).isEmpty, "client change should clear previous client's context hours")
            try expectDecimal(hours(in: marchA, dateString: "2026-03-30"), equals: "8")
        }
    }

    private static func timesheetInvoiceSummaryAppliesClientSnapshot() throws {
        let company = CompanyInfo()
        company.tauxTVAParDefaut = decimal("20")
        let client = ClientInfo(nom: "Client A", adresse: "1 rue A", codePostal: "75001", ville: "Paris")
        client.siret = "82501500100027"
        client.tva = "FR96825015001"
        client.ape = "7112P"
        let period = TimesheetPeriod(mois: 4, annee: 2026, client: client)
        period.semaines[0].jours[2].heures = decimal("7")

        let lineItems = TimesheetInvoiceService.lineItems(
            for: period,
            company: company,
            invoiceLanguage: .fr,
            detailMode: .summary,
            adjacentHours: [:]
        )
        let document = Document(type: .facture, number: "Facture_2026_01")
        document.sourceTimesheetId = period.id
        period.applyClient(to: document)

        try expectEqual(lineItems.count, 1)
        try expectEqual(lineItems[0].designation, "Heures de travail")
        try expectDecimal(lineItems[0].quantite, equals: "7")
        try expectEqual(document.clientNom, "Client A")
        try expectEqual(document.clientAdresse, "1 rue A")
        try expectEqual(document.clientSiret, "82501500100027")
        try expectEqual(document.clientTva, "FR96825015001")
        try expectEqual(document.clientApe, "7112P")
        try expectEqual(document.sourceTimesheetId, period.id)
    }

    private static func timesheetStaleContextHoursAreIgnoredWithoutAdjacentOwner() throws {
        let company = CompanyInfo()
        let period = TimesheetPeriod(startDate: date("2026-04-10"), endDate: date("2026-04-10"))

        for dayIndex in 0..<4 {
            period.semaines[0].jours[dayIndex].heures = decimal("8")
        }
        period.semaines[0].jours[4].heures = decimal("8")

        let allocations = TimesheetInvoiceService.dailyAllocations(for: period, adjacentHours: [:])
        let lineItems = TimesheetInvoiceService.lineItems(
            for: period,
            company: company,
            invoiceLanguage: .fr,
            detailMode: .summary,
            adjacentHours: [:]
        )

        try expectEqual(allocations.count, 1)
        try expectDecimal(allocations[0].normalHours, equals: "8")
        try expectDecimal(allocations[0].overtimeHours, equals: "0")
        try expectEqual(lineItems.count, 1)
        try expectDecimal(lineItems[0].quantite, equals: "8")
    }

    private static func timesheetCustomRangeCountsPreviousWeeklyContext() throws {
        let company = CompanyInfo()
        let period = TimesheetPeriod(startDate: date("2026-04-10"), endDate: date("2026-04-20"))
        period.tauxNormal = decimal("10")
        period.tauxSupplementaire = decimal("20")
        var adjacentHours: [String: Decimal] = [:]

        let firstWeek = try require(period.semaines.first, "expected first custom week")
        for day in firstWeek.jours.prefix(4) {
            adjacentHours[day.dateString] = decimal("8")
        }
        for weekIndex in period.semaines.indices {
            for dayIndex in period.semaines[weekIndex].jours.indices
                where period.semaines[weekIndex].jours[dayIndex].dateString == "2026-04-10" {
                period.semaines[weekIndex].jours[dayIndex].heures = decimal("8")
            }
        }

        let allocations = TimesheetInvoiceService.dailyAllocations(for: period, adjacentHours: adjacentHours)
        let lineItems = TimesheetInvoiceService.lineItems(
            for: period,
            company: company,
            invoiceLanguage: .fr,
            detailMode: .summary,
            adjacentHours: adjacentHours
        )

        try expectEqual(allocations.count, 1)
        try expectDecimal(allocations[0].normalHours, equals: "3")
        try expectDecimal(allocations[0].overtimeHours, equals: "5")
        try expectEqual(lineItems.count, 2)
        try expectEqual(lineItems[0].designation, "Heures de travail - 10/04/2026 - 20/04/2026")
        try expectDecimal(lineItems[0].quantite, equals: "3")
        try expectDecimal(lineItems[1].quantite, equals: "5")
    }

    private static func timesheetCustomRangeDailyInvoiceBillsOnlyActiveDates() throws {
        let company = CompanyInfo()
        let period = TimesheetPeriod(startDate: date("2026-04-10"), endDate: date("2026-04-10"))
        period.tauxNormal = decimal("10")
        period.tauxSupplementaire = decimal("20")
        var adjacentHours: [String: Decimal] = [:]

        for day in try require(period.semaines.first, "expected first custom week").jours.prefix(4) {
            adjacentHours[day.dateString] = decimal("8")
            try setHours(period, dateString: day.dateString, hours: decimal("8"))
        }
        try setHours(period, dateString: "2026-04-10", hours: decimal("8"))

        let lineItems = TimesheetInvoiceService.lineItems(
            for: period,
            company: company,
            invoiceLanguage: .fr,
            detailMode: .daily,
            adjacentHours: adjacentHours
        )
        let designations = lineItems.map(\.designation)

        try expectEqual(lineItems.count, 2)
        try expect(designations.contains("Heures de travail - 10/04/2026"), "daily invoice should bill the active date")
        try expect(designations.contains("Heures supplémentaires - 06/04/2026 - 12/04/2026"), "overtime should be grouped by week")
        try expect(!designations.contains { $0.contains("06/04/2026") && $0.contains("travail") }, "context dates must not create work lines")
        try expect(!designations.contains { $0.contains("09/04/2026") && $0.contains("travail") }, "context dates must not create work lines")
    }

    private static func timesheetInvoiceDailyLinesGroupOvertimeByWeek() throws {
        let company = CompanyInfo()
        let period = TimesheetPeriod(mois: 4, annee: 2026)
        period.tauxNormal = decimal("26.39")
        period.tauxSupplementaire = decimal("39.59")
        var adjacentHours: [String: Decimal] = [:]

        adjacentHours[period.semaines[0].jours[0].dateString] = decimal("15")
        adjacentHours[period.semaines[0].jours[1].dateString] = decimal("15")
        period.semaines[0].jours[2].heures = decimal("10")

        let allocations = TimesheetInvoiceService.dailyAllocations(for: period, adjacentHours: adjacentHours)
        let lineItems = TimesheetInvoiceService.lineItems(
            for: period,
            company: company,
            invoiceLanguage: .fr,
            detailMode: .daily,
            adjacentHours: adjacentHours
        )

        try expectEqual(allocations.count, 1)
        try expectDecimal(allocations[0].normalHours, equals: "5")
        try expectDecimal(allocations[0].overtimeHours, equals: "5")
        try expectEqual(lineItems.count, 2)
        try expectEqual(lineItems[0].designation, "Heures de travail - 01/04/2026")
        try expectEqual(lineItems[1].designation, "Heures supplémentaires - 30/03/2026 - 05/04/2026")
        try expectDecimal(lineItems[0].prixUnitaire, equals: "26.39")
        try expectDecimal(lineItems[1].prixUnitaire, equals: "39.59")
    }

    private static func timesheetInvoiceDailyLinesDoNotSplitEqualRates() throws {
        let company = CompanyInfo()
        let period = TimesheetPeriod(mois: 4, annee: 2026)
        period.tauxNormal = decimal("50")
        period.tauxSupplementaire = decimal("50")
        var adjacentHours: [String: Decimal] = [:]

        adjacentHours[period.semaines[0].jours[0].dateString] = decimal("15")
        adjacentHours[period.semaines[0].jours[1].dateString] = decimal("15")
        period.semaines[0].jours[2].heures = decimal("10")

        let lineItems = TimesheetInvoiceService.lineItems(
            for: period,
            company: company,
            invoiceLanguage: .fr,
            detailMode: .daily,
            adjacentHours: adjacentHours
        )

        try expectEqual(lineItems.count, 1)
        try expectEqual(lineItems[0].designation, "Heures de travail - 01/04/2026")
        try expectDecimal(lineItems[0].quantite, equals: "10")
        try expectDecimal(lineItems[0].prixUnitaire, equals: "50")
    }

    private static func timesheetInvoiceDailyActivityLinesIncludeEntryNames() throws {
        let company = CompanyInfo()
        let period = TimesheetPeriod(mois: 4, annee: 2026)
        period.tauxNormal = decimal("50")
        period.tauxSupplementaire = decimal("50")
        period.addTimeEntry(TimeEntry(
            projectName: "Facio",
            taskName: "UI",
            notes: "Maquette",
            startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 9),
            endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 11)
        ))
        period.addTimeEntry(TimeEntry(
            projectName: "Facio",
            taskName: "Tests",
            notes: "Validation",
            startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 11),
            endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 12)
        ))
        period.recalculateHoursFromTimeEntries(affectedDateStrings: ["2026-04-01"])

        let lineItems = TimesheetInvoiceService.lineItems(
            for: period,
            company: company,
            invoiceLanguage: .fr,
            detailMode: .dailyActivity,
            adjacentHours: [:]
        )

        try expectEqual(lineItems.count, 2)
        try expectEqual(lineItems[0].designation, "Heures de travail - 01/04/2026 - Maquette - Facio - UI")
        try expectEqual(lineItems[1].designation, "Heures de travail - 01/04/2026 - Validation - Facio - Tests")
        try expectDecimal(lineItems[0].quantite, equals: "2")
        try expectDecimal(lineItems[1].quantite, equals: "1")
    }

    private static func timesheetInvoiceDailyActivityDropsRoundingResidue() throws {
        let company = CompanyInfo()
        let period = TimesheetPeriod(mois: 4, annee: 2026)
        period.tauxNormal = decimal("56.25")
        period.tauxSupplementaire = decimal("56.25")
        period.addTimeEntry(TimeEntry(
            projectName: "Veintree SAS",
            taskName: "pull/39",
            notes: "Heures de travail",
            startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 9),
            endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 10, minute: 6)
        ))
        try setHours(period, dateString: "2026-04-01", hours: decimal("1.1003"))

        let lineItems = TimesheetInvoiceService.lineItems(
            for: period,
            company: company,
            invoiceLanguage: .fr,
            detailMode: .dailyActivity,
            adjacentHours: [:]
        )

        try expectEqual(lineItems.count, 1)
        try expectEqual(lineItems[0].designation, "Heures de travail - 01/04/2026 - Heures de travail - Veintree SAS - pull/39")
    }

    private static func timesheetCrossPeriodOvertimeAssignsOverflowToCurrentMonth() throws {
        var firstWeek = try require(TimesheetPeriod.genererSemaines(mois: 3, annee: 2026).first, "expected first week")
        var adjacentHours: [String: Decimal] = [:]

        for day in firstWeek.jours.prefix(6) {
            adjacentHours[day.dateString] = decimal("7")
        }
        firstWeek.jours[6].heures = decimal("4")

        try expectDecimal(
            firstWeek.heuresSupPourMois(moisPeriode: 3, seuil: decimal("35"), adjacentHours: adjacentHours),
            equals: "4"
        )
        try expectDecimal(
            firstWeek.heuresNormalesPourMois(moisPeriode: 3, seuil: decimal("35"), adjacentHours: adjacentHours),
            equals: "0"
        )
    }

    private static func timeEntryDecodesOldPayloadsWithDefaults() throws {
        let startedAt = dateTime(year: 2026, month: 4, day: 1, hour: 9)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let startedAtData = try encoder.encode(startedAt)
        let startedAtJSON = String(data: startedAtData, encoding: .utf8) ?? #""2026-04-01T09:00:00Z""#
        let data = Data(#"{"startedAt":\#(startedAtJSON),"projectName":"Client work"}"#.utf8)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entry = try decoder.decode(TimeEntry.self, from: data)

        try expectEqual(entry.projectName, "Client work")
        try expectEqual(entry.taskName, "")
        try expectEqual(entry.notes, "")
        try expectEqual(entry.tagsText, "")
        try expect(entry.isBillable, "old payload should default to billable")
        try expect(entry.rateSnapshot == nil, "old payload should not invent a rate snapshot")
        try expect(!entry.isDeleted, "old payload should not decode as deleted")
        try expectEqual(entry.dateString, "2026-04-01")
        try expect(entry.endedAt == nil, "old payload without end date should decode as running")
    }

    private static func timeEntryBillingSnapshotSurvivesCodableRoundTrip() throws {
        let entry = TimeEntry(
            projectName: "Facio",
            taskName: "Billing",
            notes: "Snapshot",
            tagsText: "dev, billing, dev",
            isBillable: true,
            rateSnapshot: decimal("80"),
            currencySnapshot: .eur,
            invoiceDocumentId: UUID(uuidString: "00000000-0000-0000-0000-000000000111"),
            invoiceLineItemId: UUID(uuidString: "00000000-0000-0000-0000-000000000222"),
            invoicedAt: dateTime(year: 2026, month: 4, day: 2, hour: 9),
            source: .manual,
            startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 9),
            endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 10)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(TimeEntry.self, from: encoder.encode(entry))
        try expectEqual(decoded.tagsText, "dev, billing")
        try expect(decoded.isBillable, "billable flag should survive")
        try expectDecimal(decoded.rateSnapshot, equals: "80")
        try expectEqual(decoded.currencySnapshot, .eur)
        try expectEqual(decoded.invoiceDocumentId, entry.invoiceDocumentId)
        try expectEqual(decoded.invoiceLineItemId, entry.invoiceLineItemId)
        try expectEqual(decoded.source, .manual)
    }

    private static func timeEntriesRecalculateBillableDayHours() throws {
        let period = TimesheetPeriod(startDate: date("2026-04-01"), endDate: date("2026-04-03"))
        let entry = TimeEntry(
            projectName: "Facio",
            taskName: "Timer",
            startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 9),
            endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 11, minute: 30)
        )

        period.addTimeEntry(entry)
        try expect(period.recalculateHoursFromTimeEntries(), "recalculation should update the day")

        try expectDecimal(hours(in: period, dateString: "2026-04-01"), equals: "2.5")
        try expectDecimal(hours(in: period, dateString: "2026-04-02"), equals: "0")
    }

    private static func softDeletedTimeEntriesStopContributingHours() throws {
        try withTemporaryDataStore { store in
            let period = TimesheetPeriod(startDate: date("2026-04-01"), endDate: date("2026-04-03"))
            store.addTimesheet(period)
            let entry = TimeEntry(
                projectName: "Facio",
                taskName: "Timer",
                startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 9),
                endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 11)
            )
            store.addTimeEntry(entry, to: period)
            try expectDecimal(hours(in: period, dateString: "2026-04-01"), equals: "2")

            store.deleteTimeEntry(entry, from: period)
            try expect(entry.isDeleted, "delete should soft-delete the entry")
            try expectDecimal(hours(in: period, dateString: "2026-04-01"), equals: "0")

            store.restoreTimeEntry(entry, in: period)
            try expect(!entry.isDeleted, "restore should clear deletedAt")
            try expectDecimal(hours(in: period, dateString: "2026-04-01"), equals: "2")
        }
    }

    private static func timeEntryCrossingMidnightStaysOnStartDay() throws {
        let period = TimesheetPeriod(mois: 4, annee: 2026)
        let entry = TimeEntry(
            projectName: "Facio",
            taskName: "Late work",
            startedAt: localDateTime(year: 2026, month: 4, day: 30, hour: 23),
            endedAt: localDateTime(year: 2026, month: 5, day: 1, hour: 1)
        )

        period.addTimeEntry(entry)
        period.recalculateHoursFromTimeEntries()

        try expectDecimal(hours(in: period, dateString: "2026-04-30"), equals: "2")
    }

    private static func dataStoreKeepsOneActiveTimerAcrossPeriods() throws {
        try withTemporaryDataStore { store in
            let clientA = ClientInfo(nom: "Client A")
            let clientB = ClientInfo(nom: "Client B")
            let periodA = TimesheetPeriod(startDate: date("2026-04-01"), endDate: date("2026-04-03"), client: clientA)
            let periodB = TimesheetPeriod(startDate: date("2026-04-01"), endDate: date("2026-04-03"), client: clientB)
            store.addTimesheet(periodA)
            store.addTimesheet(periodB)

            _ = store.startTimeEntry(
                in: periodA,
                projectName: "Project A",
                taskName: "Build",
                notes: "",
                at: dateTime(year: 2026, month: 4, day: 1, hour: 9)
            )
            try expect(periodA.runningTimeEntry != nil, "first timer should be active")

            let rejected = store.startTimeEntry(
                in: periodB,
                projectName: "Project B",
                taskName: "Review",
                notes: "",
                at: dateTime(year: 2026, month: 4, day: 1, hour: 10)
            )

            try expect(rejected == nil, "starting a second timer should be rejected")
            try expect(periodA.runningTimeEntry != nil, "first timer should keep running")
            try expect(periodB.runningTimeEntry == nil, "second period should not get an active timer")
            try expectDecimal(hours(in: periodA, dateString: "2026-04-01"), equals: "0")
        }
    }

    private static func dataStoreContinuesEntryWithCopiedDetails() throws {
        try withTemporaryDataStore { store in
            let period = TimesheetPeriod(startDate: date("2026-04-01"), endDate: date("2026-04-03"))
            store.addTimesheet(period)
            let original = TimeEntry(
                projectName: "Facio",
                taskName: "Timer UX",
                notes: "Continue",
                tagsText: "dev, ux",
                isBillable: true,
                rateSnapshot: decimal("120"),
                currencySnapshot: .usd,
                invoiceDocumentId: UUID(),
                invoiceLineItemId: UUID(),
                invoicedAt: dateTime(year: 2026, month: 4, day: 1, hour: 10),
                startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 9),
                endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 10)
            )
            store.addTimeEntry(original, to: period)

            let continued = try require(
                store.continueTimeEntry(
                    original,
                    in: period,
                    at: dateTime(year: 2026, month: 4, day: 1, hour: 11)
                ),
                "continuing an entry should create a running entry"
            )

            try expect(continued.id != original.id, "continued timer should be a new entry")
            try expectEqual(continued.projectName, "Facio")
            try expectEqual(continued.taskName, "Timer UX")
            try expectEqual(continued.notes, "Continue")
            try expectEqual(continued.tagsText, "dev, ux")
            try expect(continued.isBillable, "continued entry should copy billable flag")
            try expectDecimal(continued.rateSnapshot, equals: "26.39")
            try expect(continued.invoiceDocumentId == nil, "continued entry must not copy invoice id")
            try expect(continued.invoiceLineItemId == nil, "continued entry must not copy invoice line id")
            try expect(continued.invoicedAt == nil, "continued entry must not copy invoiced timestamp")
            try expect(continued.isRunning, "continued entry should be running")
            try expectDecimal(hours(in: period, dateString: "2026-04-01"), equals: "1")
        }
    }

    private static func dataStoreAdjustsRunningTimerStartWithoutNewEntry() throws {
        try withTemporaryDataStore { store in
            let period = TimesheetPeriod(startDate: date("2026-04-01"), endDate: date("2026-04-03"))
            store.addTimesheet(period)
            let entry = try require(
                store.startTimeEntry(
                    in: period,
                    projectName: "Facio",
                    taskName: "Timer",
                    notes: "",
                    at: dateTime(year: 2026, month: 4, day: 1, hour: 13, minute: 59)
                ),
                "timer should start"
            )

            store.updateRunningTimeEntryStart(
                entry,
                in: period,
                startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 12)
            )

            try expectEqual(period.timeEntries.count, 1)
            try expect(period.runningTimeEntry?.id == entry.id, "same entry should remain active")
            try expectDecimal(
                entry.durationHours(at: dateTime(year: 2026, month: 4, day: 1, hour: 14, minute: 0)),
                equals: "2"
            )
        }
    }

    private static func dataStoreImportsUnbilledTimeEntriesIntoInvoice() throws {
        try withTemporaryDataStore { store in
            let client = ClientInfo(nom: "Client A", adresse: "1 rue A", codePostal: "75001", ville: "Paris")
            let period = TimesheetPeriod(startDate: date("2026-04-01"), endDate: date("2026-04-30"), client: client)
            period.tauxNormal = decimal("100")
            store.addTimesheet(period)

            let billable = TimeEntry(
                projectName: "Project",
                taskName: "Build",
                notes: "Feature",
                isBillable: true,
                rateSnapshot: decimal("120"),
                currencySnapshot: .eur,
                startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 9),
                endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 11)
            )
            let nonBillable = TimeEntry(
                projectName: "Internal",
                taskName: "Admin",
                isBillable: false,
                startedAt: dateTime(year: 2026, month: 4, day: 2, hour: 9),
                endedAt: dateTime(year: 2026, month: 4, day: 2, hour: 10)
            )
            store.addTimeEntry(billable, to: period)
            store.addTimeEntry(nonBillable, to: period)

            let invoice = try require(
                store.generateInvoiceFromUnbilledTimeEntries(from: period, grouping: .detailed),
                "invoice import should create a document"
            )

            try expectEqual(invoice.lignes.count, 1)
            try expectDecimal(invoice.lignes[0].quantite, equals: "2")
            try expectDecimal(invoice.lignes[0].prixUnitaire, equals: "120")
            try expectEqual(billable.invoiceDocumentId, invoice.id)
            try expectEqual(billable.invoiceLineItemId, invoice.lignes[0].id)
            try expect(billable.invoicedAt != nil, "imported entry should be marked invoiced")
            try expect(invoice.sourceTimesheetId == period.id, "full time entry import should link invoice to period")
            try expect(period.invoiceDocumentId == invoice.id, "full time entry import should mark period invoiced")
            try expect(nonBillable.invoiceDocumentId == nil, "non-billable entry should not be imported")
            try expect(!store.canGenerateInvoiceFromTimeEntries(for: period), "already invoiced entry should not be proposed again")

            store.deleteDocument(invoice)
            try expect(period.invoiceDocumentId == nil, "deleting invoice should clear period invoice id")
            try expect(period.billedAt == nil, "deleting invoice should clear period billed timestamp")
            try expect(billable.invoiceDocumentId == nil, "deleting invoice should clear entry invoice id")
            try expect(billable.invoiceLineItemId == nil, "deleting invoice should clear entry line id")
            try expect(billable.invoicedAt == nil, "deleting invoice should clear entry invoiced timestamp")
        }
    }

    private static func timeEntryCSVReportIncludesBillableColumns() throws {
        let client = ClientInfo(nom: "Client CSV")
        let period = TimesheetPeriod(startDate: date("2026-04-01"), endDate: date("2026-04-30"), client: client)
        period.tauxNormal = decimal("90")
        let entry = TimeEntry(
            projectName: "Project",
            taskName: "Build",
            notes: "Feature, CSV",
            tagsText: "dev, export",
            isBillable: true,
            rateSnapshot: decimal("110"),
            currencySnapshot: .eur,
            startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 9),
            endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 10, minute: 30)
        )
        period.addTimeEntry(entry)

        let csv = TimeTrackingService.csv(for: [entry], timesheet: period, lang: .en)
        try expect(csv.contains("date,description,client,project,task,tags,start,end,duration_raw"), "CSV header should include report columns")
        try expect(csv.contains("\"Feature, CSV\""), "CSV should escape commas")
        try expect(csv.contains("true"), "CSV should include billable status")
        try expect(csv.contains("5400"), "CSV should include raw duration seconds")
        try expect(csv.contains("110"), "CSV should include hourly rate snapshot")
    }

    private static func timeHubStatsExcludeDeletedEntries() throws {
        let period = TimesheetPeriod(startDate: date("2026-04-01"), endDate: date("2026-04-30"), client: ClientInfo(nom: "Client A"))
        period.tauxNormal = decimal("100")
        let kept = TimeEntry(
            projectName: "Project",
            taskName: "Build",
            isBillable: true,
            rateSnapshot: decimal("100"),
            startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 9),
            endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 11)
        )
        let deleted = TimeEntry(
            projectName: "Project",
            taskName: "Deleted",
            isBillable: true,
            rateSnapshot: decimal("100"),
            deletedAt: dateTime(year: 2026, month: 4, day: 1, hour: 12),
            startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 12),
            endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 13)
        )
        period.addTimeEntry(kept)
        period.addTimeEntry(deleted)

        let interval = TimeHubPeriodMode.day.interval(containing: date("2026-04-01"))
        let contexts = TimeHubAggregationService.contexts(
            from: [period],
            in: interval,
            filters: TimeTrackingFilters(),
            now: dateTime(year: 2026, month: 4, day: 1, hour: 14)
        )
        let stats = TimeHubAggregationService.stats(
            for: contexts,
            now: dateTime(year: 2026, month: 4, day: 1, hour: 14)
        )

        try expectEqual(contexts.count, 1)
        try expectEqual(stats.totalSeconds, 7200)
        try expectEqual(stats.billableSeconds, 7200)
        try expectEqual(stats.uninvoicedSeconds, 7200)
        try expectDecimal(stats.estimatedAmount, equals: "200")
    }

    private static func timeHubGroupsEntriesByClientAndProject() throws {
        let clientA = ClientInfo(nom: "Client A")
        let clientB = ClientInfo(nom: "Client B")
        let periodA = TimesheetPeriod(startDate: date("2026-04-01"), endDate: date("2026-04-30"), client: clientA)
        let periodB = TimesheetPeriod(startDate: date("2026-04-01"), endDate: date("2026-04-30"), client: clientB)
        periodA.addTimeEntry(TimeEntry(
            projectName: "Project A",
            taskName: "Build",
            startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 9),
            endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 10)
        ))
        periodB.addTimeEntry(TimeEntry(
            projectName: "Project B",
            taskName: "Review",
            startedAt: dateTime(year: 2026, month: 4, day: 1, hour: 10),
            endedAt: dateTime(year: 2026, month: 4, day: 1, hour: 12)
        ))

        let interval = TimeHubPeriodMode.day.interval(containing: date("2026-04-01"))
        let contexts = TimeHubAggregationService.contexts(
            from: [periodA, periodB],
            in: interval,
            filters: TimeTrackingFilters(),
            now: dateTime(year: 2026, month: 4, day: 1, hour: 13)
        )
        let clientGroups = TimeHubAggregationService.clientGroups(for: contexts, now: dateTime(year: 2026, month: 4, day: 1, hour: 13))
        let projectGroups = TimeHubAggregationService.projectGroups(for: contexts, now: dateTime(year: 2026, month: 4, day: 1, hour: 13))

        try expectEqual(clientGroups.count, 2)
        try expectEqual(clientGroups[0].clientName, "Client B")
        try expectEqual(clientGroups[0].stats.totalSeconds, 7200)
        try expectEqual(projectGroups.map(\.projectName).sorted(), ["Project A", "Project B"])
    }

    private static func dateAndDecimalFormattingAreStableAcrossLanguages() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 2, hour: 12))!
        let amount = decimal("1234.5")

        try expectEqual(date.formattedDate(for: .fr), "02/03/2026")
        try expectEqual(date.formattedDate(for: .en), "03/02/2026")
        try expectEqual(date.yearMonthFormatted, "2026_03")
        try expectEqual(amount.formatted2Decimals(for: .fr), "1 234,50")
        try expectEqual(amount.formatted2Decimals(for: .en), "1,234.50")
        try expectEqual(decimal("1234.6").formattedNoDecimals(for: .en), "1,235")
    }

    private static func emailTemplateResolvesPlaceholdersAndAttachmentsLine() throws {
        let company = try JSONDecoder().decode(CompanyInfo.self, from: Data(#"{"nom":"Facio SAS"}"#.utf8))
        let document = Document(type: .facture, number: "Facture_2026_07")
        document.clientNom = "ACME Corp"

        let template = """
        Bonjour {client},

        Facture {number} de {amount} avant le {due_date}.

        {attachments}

        Cordialement,
        {company}
        """

        let withoutAttachments = EmailService.resolveTemplate(template, document: document, company: company)
        try expect(withoutAttachments.contains("ACME Corp"), "client placeholder should be substituted")
        try expect(withoutAttachments.contains("Facture_2026_07"), "number placeholder should be substituted")
        try expect(withoutAttachments.contains("Facio SAS"), "company placeholder should be substituted")
        try expect(!withoutAttachments.contains("{"), "no placeholder should remain unresolved")
        try expect(!withoutAttachments.contains("\n\n\n"), "blank lines left by the empty attachments placeholder should collapse")

        document.attachments = [
            DocumentAttachment(originalFilename: "ticket.pdf", fileExtension: "pdf", label: "", fileSize: 10)
        ]
        let withAttachments = EmailService.resolveTemplate(template, document: document, company: company)
        try expect(
            withAttachments.contains(L10n.emailAttachmentsLine(document.langue)),
            "attachments line should be inserted when the document has attachments"
        )
    }

    private static func emailSafeFilenameStripsUnsafeCharacters() throws {
        try expectEqual(EmailService.safeFilename("Facture/2026:03"), "Facture-2026-03")
        try expectEqual(EmailService.safeFilename("  Devis 2026_04  "), "Devis 2026_04")
        try expectEqual(EmailService.safeFilename("///"), "document")
        try expectEqual(EmailService.safeFilename(""), "document")
        try expectEqual(EmailService.safeFilename(String(repeating: "a", count: 200)).count, 120)
    }

    private static func attachmentImportCopiesFileAndRecordsMetadata() throws {
        try withTemporaryDataStore { store in
            let document = store.createDocument(type: .facture)
            let source = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent("facio-attachment-\(UUID().uuidString).pdf")
            try Data("pdf".utf8).write(to: source)
            defer { try? FileManager.default.removeItem(at: source) }

            let attachment = try require(
                store.importAttachment(from: source, to: document, label: "Ticket"),
                "importing an existing file should succeed"
            )
            try expectEqual(document.attachments.count, 1)
            try expectEqual(attachment.originalFilename, source.lastPathComponent)
            try expect(
                FileManager.default.fileExists(atPath: store.attachmentURL(attachment, in: document).path),
                "imported attachment file should exist in the document directory"
            )

            let missing = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent("facio-missing-\(UUID().uuidString).pdf")
            try expect(store.importAttachment(from: missing, to: document) == nil, "importing a missing file should fail")
            try expectEqual(document.attachments.count, 1)
        }
    }

    private static func attachmentDuplicationReportsMissingSourceFiles() throws {
        try withTemporaryDataStore { store in
            let source = store.createDocument(type: .facture)
            let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let fileA = dir.appendingPathComponent("facio-kept-\(UUID().uuidString).pdf")
            let fileB = dir.appendingPathComponent("facio-lost-\(UUID().uuidString).pdf")
            try Data("a".utf8).write(to: fileA)
            try Data("b".utf8).write(to: fileB)
            defer {
                try? FileManager.default.removeItem(at: fileA)
                try? FileManager.default.removeItem(at: fileB)
            }

            let kept = try require(store.importAttachment(from: fileA, to: source), "first import should succeed")
            let lost = try require(store.importAttachment(from: fileB, to: source), "second import should succeed")
            try FileManager.default.removeItem(at: store.attachmentURL(lost, in: source))

            let destination = source.dupliquer()
            store.addDocument(destination)
            let result = store.duplicateAttachments(from: source, to: destination)

            try expectEqual(result.copied, 1)
            try expectEqual(result.failed, 1)
            try expectEqual(destination.attachments.count, 1)
            try expectEqual(destination.attachments.first?.originalFilename, kept.originalFilename)
            try expect(destination.attachments.first?.id != kept.id, "duplicated attachment should get a new identity")
        }
    }

    private static func attachmentURLsExposeOnlyExistingFiles() throws {
        try withTemporaryDataStore { store in
            let document = store.createDocument(type: .facture)
            let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let fileA = dir.appendingPathComponent("facio-a-\(UUID().uuidString).pdf")
            let fileB = dir.appendingPathComponent("facio-b-\(UUID().uuidString).pdf")
            try Data("a".utf8).write(to: fileA)
            try Data("b".utf8).write(to: fileB)
            defer {
                try? FileManager.default.removeItem(at: fileA)
                try? FileManager.default.removeItem(at: fileB)
            }

            let stays = try require(store.importAttachment(from: fileA, to: document), "first import should succeed")
            let removed = try require(store.importAttachment(from: fileB, to: document), "second import should succeed")
            try FileManager.default.removeItem(at: store.attachmentURL(removed, in: document))

            let urls = store.attachmentURLs(for: document)
            try expectEqual(urls.count, 1)
            try expectEqual(urls.first, store.attachmentURL(stays, in: document))
            try expectEqual(document.attachments.count, 2)
        }
    }

    private static func companyDecodesOldPayloadsWithoutIntracomVAT() throws {
        // Ancien payload (avant l'ajout de tvaIntracom pour la facture électronique) :
        // le champ doit retomber sur "" et survivre à un aller-retour Codable.
        let legacy = try JSONDecoder().decode(CompanyInfo.self, from: Data(#"{"nom":"Facio SAS","siret":"12345678900012"}"#.utf8))
        try expectEqual(legacy.tvaIntracom, "")
        try expectEqual(legacy.siret, "12345678900012")

        legacy.tvaIntracom = "FR12345678900"
        let reencoded = try JSONEncoder().encode(legacy)
        let decoded = try JSONDecoder().decode(CompanyInfo.self, from: reencoded)
        try expectEqual(decoded.tvaIntracom, "FR12345678900")
    }

    private static func facturXApplicabilityGatesNonInvoices() throws {
        let devis = Document(type: .devis, number: "Devis_2026_01", currency: .eur)
        try expectEqual(FacturXXMLBuilder.applicability(for: devis), .notAnInvoice)

        let crypto = Document(type: .facture, number: "F1", currency: .usdc)
        try expectEqual(FacturXXMLBuilder.applicability(for: crypto), .unsupportedCurrency("USDC"))

        let eur = Document(type: .facture, number: "F2", currency: .eur)
        try expectEqual(FacturXXMLBuilder.applicability(for: eur), .applicable)
    }

    private static func facturXXMLMapsInvoiceFieldsAndTotals() throws {
        let company = CompanyInfo()
        company.nom = "Facio SAS"
        company.siret = "12345678900012"
        company.tvaIntracom = "FR12345678900"
        company.adresse = "1 rue Test"
        company.codePostal = "54000"
        company.ville = "Nancy"

        let doc = Document(type: .facture, number: "Facture_2026_03", currency: .eur)
        doc.clientNom = "Client SARL"
        doc.clientSiret = "98765432100019"
        doc.clientTva = "FR98765432100"
        doc.clientAdresse = "2 av Client"
        doc.clientCodePostal = "75001"
        doc.clientVille = "Paris"
        doc.ajouterLigne(LineItem(designation: "Dev", quantite: 2, prixUnitaire: 100, tauxTVA: 20)) // net 200, TVA 40
        doc.ajouterLigne(LineItem(designation: "Conseil", quantite: 1, prixUnitaire: 100, tauxTVA: 10)) // net 100, TVA 10

        let xml = FacturXXMLBuilder.buildXML(document: doc, company: company)

        // Profil, type, date
        try expect(xml.contains("<ram:ID>urn:cen.eu:en16931:2017</ram:ID>"), "profile URN present")
        try expect(xml.contains("<ram:TypeCode>380</ram:TypeCode>"), "invoice type code 380")
        let expectedIssue = FacturXXMLBuilder.date102(doc.dateCreation)
        try expect(xml.contains("<udt:DateTimeString format=\"102\">\(expectedIssue)</udt:DateTimeString>"), "issue date in 102 format")

        // Parties
        try expect(xml.contains("<ram:ID schemeID=\"0002\">12345678900012</ram:ID>"), "seller SIRET")
        try expect(xml.contains("<ram:ID schemeID=\"VA\">FR12345678900</ram:ID>"), "seller intracom VAT")
        try expect(xml.contains("<ram:Name>Client SARL</ram:Name>"), "buyer name")

        // Ventilation TVA multi-taux
        try expect(xml.contains("<ram:CategoryCode>S</ram:CategoryCode>"), "standard category S")
        try expect(xml.contains("<ram:BasisAmount>200.00</ram:BasisAmount>"), "20% group basis")
        try expect(xml.contains("<ram:CalculatedAmount>40.00</ram:CalculatedAmount>"), "20% group VAT")
        try expect(xml.contains("<ram:BasisAmount>100.00</ram:BasisAmount>"), "10% group basis")
        try expect(xml.contains("<ram:CalculatedAmount>10.00</ram:CalculatedAmount>"), "10% group VAT")
        try expect(xml.contains("<ram:RateApplicablePercent>20.00</ram:RateApplicablePercent>"), "20% rate")

        // Sommation monétaire (arithmétique BR-CO)
        try expect(xml.contains("<ram:LineTotalAmount>300.00</ram:LineTotalAmount>"), "sum of line nets")
        try expect(xml.contains("<ram:TaxBasisTotalAmount>300.00</ram:TaxBasisTotalAmount>"), "tax basis total")
        try expect(xml.contains("<ram:TaxTotalAmount currencyID=\"EUR\">50.00</ram:TaxTotalAmount>"), "tax total")
        try expect(xml.contains("<ram:GrandTotalAmount>350.00</ram:GrandTotalAmount>"), "grand total")
        try expect(xml.contains("<ram:DuePayableAmount>350.00</ram:DuePayableAmount>"), "due payable")

        // Format décimal indépendant de la locale (jamais de virgule)
        try expect(!xml.contains(",00"), "amounts use dot decimal separator")

        // Bonne formation XML (valide aussi l'échappement)
        try expect(XMLParser(data: Data(xml.utf8)).parse(), "generated XML must be well-formed")
    }

    private static func facturXXMLFranchiseEnBaseUsesCategoryE() throws {
        let company = CompanyInfo()
        company.nom = "Micro EI"
        company.siret = "11122233300014" // pas de tvaIntracom → franchise en base
        let doc = Document(type: .facture, number: "Facture_2026_05", currency: .eur)
        doc.clientNom = "Client"
        doc.ajouterLigne(LineItem(designation: "Prestation", quantite: 1, prixUnitaire: 500, tauxTVA: 0))

        let xml = FacturXXMLBuilder.buildXML(document: doc, company: company)

        try expect(xml.contains("<ram:CategoryCode>E</ram:CategoryCode>"), "exempt category E for 0% rate")
        try expect(
            xml.contains("<ram:ExemptionReason>TVA non applicable, art. 293 B du CGI</ram:ExemptionReason>"),
            "franchise exemption reason"
        )
        try expect(!xml.contains("schemeID=\"VA\""), "no VAT registration block when franchise (no intracom VAT)")
        try expect(xml.contains("<ram:TaxTotalAmount currencyID=\"EUR\">0.00</ram:TaxTotalAmount>"), "no VAT amount")
        try expect(xml.contains("<ram:GrandTotalAmount>500.00</ram:GrandTotalAmount>"), "grand total equals net")
        try expect(XMLParser(data: Data(xml.utf8)).parse(), "franchise XML must be well-formed")
    }

    private static func facturXEmbedsRetrievableXMLInPDF() throws {
        let company = CompanyInfo()
        company.nom = "Facio SAS"
        company.siret = "12345678900012"
        company.tvaIntracom = "FR12345678900"
        let doc = Document(type: .facture, number: "Facture_2026_07", currency: .eur)
        doc.clientNom = "Client SARL"
        doc.ajouterLigne(LineItem(designation: "Dev", quantite: 1, prixUnitaire: 1000, tauxTVA: 20))

        let xml = FacturXXMLBuilder.buildXML(document: doc, company: company)
        let basePDF = PDFGenerator(document: doc, company: company).generate()
        try expect(!basePDF.isEmpty, "base PDF should be generated")

        let embedded = try require(
            FacturXPDFWriter.embed(xml: xml, into: basePDF, invoiceNumber: doc.number, modDate: doc.dateCreation),
            "embedding should succeed"
        )

        // 1. Le PDF reste lisible après la mise à jour incrémentale.
        let pdfDoc = try require(PDFDocument(data: embedded), "embedded PDF should parse")
        try expect(pdfDoc.pageCount >= 1, "embedded PDF should have at least one page")

        // 2. Le XML embarqué est atteignable et byte-identique (valide la chirurgie xref).
        let extracted = try require(firstEmbeddedFile(in: embedded), "factur-x.xml should be retrievable")
        try expectEqual(extracted, Data(xml.utf8))

        // 3. Le catalogue expose /AF, /Metadata et /OutputIntents.
        try expect(facturXContainerKeysPresent(in: embedded), "catalog must expose AF + Metadata + OutputIntents")
    }

    /// Extrait les octets du premier fichier embarqué via l'API CGPDF (round-trip).
    private static func firstEmbeddedFile(in pdf: Data) -> Data? {
        guard let provider = CGDataProvider(data: pdf as CFData),
              let doc = CGPDFDocument(provider),
              let catalog = doc.catalog else { return nil }
        var names: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(catalog, "Names", &names), let names else { return nil }
        var embeddedFiles: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(names, "EmbeddedFiles", &embeddedFiles), let embeddedFiles else { return nil }
        var array: CGPDFArrayRef?
        guard CGPDFDictionaryGetArray(embeddedFiles, "Names", &array), let array else { return nil }

        let count = CGPDFArrayGetCount(array)
        var i = 0
        while i + 1 < count {
            var filespec: CGPDFDictionaryRef?
            if CGPDFArrayGetDictionary(array, i + 1, &filespec), let filespec {
                var ef: CGPDFDictionaryRef?
                if CGPDFDictionaryGetDictionary(filespec, "EF", &ef), let ef {
                    var stream: CGPDFStreamRef?
                    if CGPDFDictionaryGetStream(ef, "F", &stream), let stream {
                        var format = CGPDFDataFormat.raw
                        if let data = CGPDFStreamCopyData(stream, &format) {
                            return data as Data
                        }
                    }
                }
            }
            i += 2
        }
        return nil
    }

    private static func facturXContainerKeysPresent(in pdf: Data) -> Bool {
        guard let provider = CGDataProvider(data: pdf as CFData),
              let doc = CGPDFDocument(provider),
              let catalog = doc.catalog else { return false }
        var af: CGPDFArrayRef?
        var metadata: CGPDFStreamRef?
        var outputIntents: CGPDFArrayRef?
        let hasAF = CGPDFDictionaryGetArray(catalog, "AF", &af)
        let hasMetadata = CGPDFDictionaryGetStream(catalog, "Metadata", &metadata)
        let hasOutputIntents = CGPDFDictionaryGetArray(catalog, "OutputIntents", &outputIntents)
        return hasAF && hasMetadata && hasOutputIntents
    }

    private static func emailAttachmentFilenamesUseLabelsAndDedupe() throws {
        let url = URL(fileURLWithPath: "/tmp/x")
        let attachments = [
            // Libellé renseigné → nom = libellé + extension.
            EmailService.EmailAttachment(sourceURL: url, displayName: "Train Nancy-Paris", fileExtension: "pdf"),
            // Sans libellé : displayName retombe sur le nom d'origine.
            EmailService.EmailAttachment(sourceURL: url, displayName: "recu.jpg", fileExtension: "jpg"),
            // Même libellé qu'un précédent → dédoublonné en `-2`.
            EmailService.EmailAttachment(sourceURL: url, displayName: "Train Nancy-Paris", fileExtension: "pdf"),
        ]
        let names = EmailService.uniqueFilenames(for: attachments)
        try expectEqual(names, ["Train Nancy-Paris.pdf", "recu.jpg", "Train Nancy-Paris-2.pdf"])
    }

    private static func withTemporaryDataStore(_ body: (DataStore) throws -> Void) throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("facio-regression-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try body(DataStore(storageDirectory: root))
    }

    private static func setHours(_ period: TimesheetPeriod, dateString: String, hours: Decimal) throws {
        for weekIndex in period.semaines.indices {
            for dayIndex in period.semaines[weekIndex].jours.indices
                where period.semaines[weekIndex].jours[dayIndex].dateString == dateString {
                period.semaines[weekIndex].jours[dayIndex].heures = hours
                return
            }
        }
        throw RegressionFailure(message: "date \(dateString) not found in period \(period.periodLabel(for: .fr))")
    }

    private static func hours(in period: TimesheetPeriod, dateString: String) throws -> Decimal {
        for week in period.semaines {
            if let day = week.jours.first(where: { $0.dateString == dateString }) {
                return day.heures
            }
        }
        throw RegressionFailure(message: "date \(dateString) not found in period \(period.periodLabel(for: .fr))")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw RegressionFailure(message: message) }
    }

    private static func expectThrows<T>(_ expression: @autoclosure () throws -> T, _ message: String) throws {
        do {
            _ = try expression()
            throw RegressionFailure(message: message)
        } catch is RegressionFailure {
            throw RegressionFailure(message: message)
        } catch {
            return
        }
    }

    private static func expectEqual<T: Equatable>(_ actual: @autoclosure () -> T, _ expected: @autoclosure () -> T) throws {
        let actualValue = actual()
        let expectedValue = expected()
        guard actualValue == expectedValue else {
            throw RegressionFailure(message: "expected \(expectedValue), got \(actualValue)")
        }
    }

    private static func expectDecimal(_ actual: Decimal?, equals expected: String) throws {
        try expectEqual(actual, decimal(expected))
    }

    private static func expectDecimal(_ actual: Decimal, equals expected: String) throws {
        try expectEqual(actual, decimal(expected))
    }

    private static func require<T>(_ value: T?, _ message: String) throws -> T {
        guard let value else { throw RegressionFailure(message: message) }
        return value
    }

    private static func date(_ string: String) -> Date {
        TimesheetDay.dateFormatter.date(from: string)!
    }

    private static func dateTime(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private static func localDateTime(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0) -> Date {
        Calendar(identifier: .gregorian).date(
            from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        )!
    }

    private static func decimal(_ string: String) -> Decimal {
        Decimal(string: string, locale: Locale(identifier: "en_US_POSIX"))!
    }
}

private struct RegressionCase: Sendable {
    let name: String
    let run: @MainActor @Sendable () throws -> Void
}

private struct RegressionResult {
    let name: String
    let passed: Bool
    let message: String?
}

private struct RegressionFailure: Error {
    let message: String
}
#endif
