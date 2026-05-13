#if FACIO_REGRESSION_TESTS
import Darwin
import Foundation

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
        RegressionCase(name: "currency precision keeps crypto amounts", run: currencyPrecisionKeepsCryptoAmounts),
        RegressionCase(name: "accounting currency format keeps document totals readable", run: accountingCurrencyFormatKeepsDocumentTotalsReadable),
        RegressionCase(name: "document totals include VAT and line ordering", run: documentTotalsIncludeVATAndLineOrdering),
        RegressionCase(name: "document decodes old payloads without accounting conversion", run: documentDecodesOldPayloadsWithoutAccountingConversion),
        RegressionCase(name: "sent invoices become overdue after due date", run: sentInvoicesBecomeOverdueAfterDueDate),
        RegressionCase(name: "client empty record detection trims all fields", run: clientEmptyRecordDetectionTrimsAllFields),
        RegressionCase(name: "company migrates legacy bank fields into bank accounts", run: companyMigratesLegacyBankFieldsIntoBankAccounts),
        RegressionCase(name: "accounting revenue converts known rates and reports missing ones", run: accountingRevenueConvertsKnownRatesAndReportsMissingOnes),
        RegressionCase(name: "fiat document drops crypto payment configuration", run: fiatDocumentDropsCryptoPaymentConfiguration),
        RegressionCase(name: "bank transfer selects only usable bank accounts", run: bankTransferSelectsOnlyUsableBankAccounts),
        RegressionCase(name: "crypto payment selects only compatible non-blank wallets", run: cryptoPaymentSelectsOnlyCompatibleNonBlankWallets),
        RegressionCase(name: "payment snapshot freezes exported bank account", run: paymentSnapshotFreezesExportedBankAccount),
        RegressionCase(name: "payment snapshot survives codable round trip", run: paymentSnapshotSurvivesCodableRoundTrip),
        RegressionCase(name: "paid invoices do not expose Solana Pay request", run: paidInvoicesDoNotExposeSolanaPayRequest),
        RegressionCase(name: "bitcoin payment is crypto but not Solana Pay eligible", run: bitcoinPaymentIsCryptoButNotSolanaPayEligible),
        RegressionCase(name: "document duplication keeps payment and line data without reusing identity", run: documentDuplicationKeepsPaymentAndLineDataWithoutReusingIdentity),
        RegressionCase(name: "sync state tracks pending deletes as dirty data", run: syncStateTracksPendingDeletesAsDirtyData),
        RegressionCase(name: "sync state decodes old payloads without pending delete arrays", run: syncStateDecodesOldPayloadsWithoutPendingDeleteArrays),
        RegressionCase(name: "timesheet calendar generation uses whole weeks", run: timesheetCalendarGenerationUsesWholeWeeks),
        RegressionCase(name: "timesheet custom range generation uses whole weeks", run: timesheetCustomRangeGenerationUsesWholeWeeks),
        RegressionCase(name: "timesheet normalize calendar restores shape and keeps stored hours", run: timesheetNormalizeCalendarRestoresShapeAndKeepsStoredHours),
        RegressionCase(name: "timesheet period decodes old payloads and normalizes calendar", run: timesheetPeriodDecodesOldPayloadsAndNormalizesCalendar),
        RegressionCase(name: "timesheet invoice detail mode survives codable round trip", run: timesheetInvoiceDetailModeSurvivesCodableRoundTrip),
        RegressionCase(name: "timesheet invoice markers set generated invoice state", run: timesheetInvoiceMarkersSetGeneratedInvoiceState),
        RegressionCase(name: "timesheet periods are unique per client and month", run: timesheetPeriodsAreUniquePerClientAndMonth),
        RegressionCase(name: "timesheet custom ranges overlap by client", run: timesheetCustomRangesOverlapByClient),
        RegressionCase(name: "timesheet shared weeks are scoped by client", run: timesheetSharedWeeksAreScopedByClient),
        RegressionCase(name: "data store updates linked invoice when timesheet changes", run: dataStoreUpdatesLinkedInvoiceWhenTimesheetChanges),
        RegressionCase(name: "data store reuses existing invoice when detail mode changes", run: dataStoreReusesExistingInvoiceWhenDetailModeChanges),
        RegressionCase(name: "deleting linked invoice clears timesheet markers", run: deletingLinkedInvoiceClearsTimesheetMarkers),
        RegressionCase(name: "shared week sync clears context after adjacent delete", run: sharedWeekSyncClearsContextAfterAdjacentDelete),
        RegressionCase(name: "shared week sync clears context after client change", run: sharedWeekSyncClearsContextAfterClientChange),
        RegressionCase(name: "timesheet invoice summary applies client snapshot", run: timesheetInvoiceSummaryAppliesClientSnapshot),
        RegressionCase(name: "timesheet stale context hours are ignored without adjacent owner", run: timesheetStaleContextHoursAreIgnoredWithoutAdjacentOwner),
        RegressionCase(name: "timesheet custom range counts previous weekly context", run: timesheetCustomRangeCountsPreviousWeeklyContext),
        RegressionCase(name: "timesheet custom range daily invoice bills only active dates", run: timesheetCustomRangeDailyInvoiceBillsOnlyActiveDates),
        RegressionCase(name: "timesheet invoice daily lines group overtime by week", run: timesheetInvoiceDailyLinesGroupOvertimeByWeek),
        RegressionCase(name: "timesheet invoice daily lines do not split equal rates", run: timesheetInvoiceDailyLinesDoNotSplitEqualRates),
        RegressionCase(name: "timesheet cross-period overtime assigns overflow to current month", run: timesheetCrossPeriodOvertimeAssignsOverflowToCurrentMonth),
        RegressionCase(name: "date and decimal formatting are stable across languages", run: dateAndDecimalFormattingAreStableAcrossLanguages)
    ]

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

        let state = try JSONDecoder().decode(SyncState.self, from: data)

        try expect(state.documentsDirty, "old dirty flag should decode")
        try expect(state.migrationCompleted, "old migration flag should decode")
        try expectEqual(state.pendingDeleteIds(for: .documents), [])
        try expectEqual(state.pendingDeleteIds(for: .clients), [])
        try expectEqual(state.pendingDeleteIds(for: .timesheets), [])
        try expect(state.isDirty(.documents), "documents should remain dirty")
        try expect(!state.isDirty(.clients), "clients should remain clean")
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
        period.invoiceDetailMode = .daily
        period.invoiceDocumentId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")
        period.billedAt = date("2026-04-30")

        let data = try JSONEncoder().encode(period)
        let decoded = try JSONDecoder().decode(TimesheetPeriod.self, from: data)

        try expectEqual(decoded.invoiceDetailMode, .daily)
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

            try expectEqual(store.documents.count, 1)
            try expectDecimal(invoice.lignes.first?.quantite, equals: "8")
            try expectDecimal(invoice.lignes.first?.prixUnitaire, equals: "10")

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
        }
    }

    private static func dataStoreReusesExistingInvoiceWhenDetailModeChanges() throws {
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
            try expectEqual(period.invoiceDetailMode, .daily)
            try expectEqual(reused.lignes.first?.designation, "Heures de travail - 01/04/2026")
        }
    }

    private static func deletingLinkedInvoiceClearsTimesheetMarkers() throws {
        try withTemporaryDataStore { store in
            store.companyInfo.deviseParDefaut = .eur

            let client = ClientInfo(nom: "Client A")
            let period = TimesheetPeriod(mois: 4, annee: 2026, client: client)
            try setHours(period, dateString: "2026-04-01", hours: decimal("8"))

            store.addTimesheet(period)
            let invoice = try require(store.generateInvoice(from: period, detailMode: .summary), "expected invoice")

            try expect(period.hasGeneratedInvoice, "period should be marked invoiced")
            store.deleteDocument(invoice)

            try expect(store.documents.isEmpty, "linked invoice should be deleted")
            try expect(period.invoiceDocumentId == nil, "deleting invoice should clear invoice id")
            try expect(period.billedAt == nil, "deleting invoice should clear billed date")
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
        try expect(designations.contains("Heures supplementaires - 06/04/2026 - 12/04/2026"), "overtime should be grouped by week")
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
        try expectEqual(lineItems[1].designation, "Heures supplementaires - 30/03/2026 - 05/04/2026")
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
