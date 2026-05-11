import Foundation
import Observation

// MARK: - Sync Service

@Observable
@MainActor
final class SyncService: Sendable {
    var isSyncing: Bool = false
    var lastSyncDate: Date?
    var lastError: String?
    var syncState: SyncState = SyncState()
    var authService: AuthService?

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var debounceTask: Task<Void, Never>?
    private var isPushingDirty = false
    private var dirtyGeneration = 0
    private let syncStateURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Facio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        syncStateURL = dir.appendingPathComponent("sync_state.json")
        loadSyncState()
    }

    // MARK: - Sync State Persistence

    private func loadSyncState() {
        guard let data = try? Data(contentsOf: syncStateURL),
              let state = try? decoder.decode(SyncState.self, from: data)
        else { return }
        syncState = state
    }

    private func saveSyncState() {
        guard let data = try? encoder.encode(syncState) else { return }
        try? data.write(to: syncStateURL, options: .atomic)
    }

    // MARK: - Mark Dirty

    func markDirty(_ key: String) {
        guard let dataKey = SyncDataKey(rawValue: key) else { return }
        markDirty(dataKey)
    }

    func markDirty(_ key: SyncDataKey) {
        syncState.setDirty(true, for: key)
        dirtyGeneration += 1
        saveSyncState()

        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled {
                await pushAllDirty()
            }
        }
    }

    // MARK: - Push All Dirty

    func pushAllDirty() async {
        guard SyncConfig.isEnabled, SyncConfig.isConfigured,
              authService?.isAuthenticated == true else { return }
        guard !isPushingDirty else { return }

        isPushingDirty = true
        let generation = dirtyGeneration
        defer { isPushingDirty = false }

        let storageDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Facio", isDirectory: true)

        if syncState.documentsDirty {
            if let data = try? Data(contentsOf: storageDir.appendingPathComponent("documents.json")),
               let docs = try? decoder.decode([Document].self, from: data) {
                if await pushDocuments(docs), dirtyGeneration == generation {
                    syncState.setDirty(false, for: .documents)
                }
            } else {
                lastError = "Lecture locale impossible: documents.json"
            }
        }

        if syncState.clientsDirty {
            if let data = try? Data(contentsOf: storageDir.appendingPathComponent("clients.json")),
               let clients = try? decoder.decode([ClientInfo].self, from: data) {
                if await pushClients(clients), dirtyGeneration == generation {
                    syncState.setDirty(false, for: .clients)
                }
            } else {
                lastError = "Lecture locale impossible: clients.json"
            }
        }

        if syncState.companyDirty {
            if let data = try? Data(contentsOf: storageDir.appendingPathComponent("company.json")),
               let company = try? decoder.decode(CompanyInfo.self, from: data) {
                if await pushCompany(company), dirtyGeneration == generation {
                    syncState.setDirty(false, for: .company)
                }
            } else {
                lastError = "Lecture locale impossible: company.json"
            }
        }

        if syncState.timesheetsDirty {
            if let data = try? Data(contentsOf: storageDir.appendingPathComponent("timesheets.json")),
               let timesheets = try? decoder.decode([TimesheetPeriod].self, from: data) {
                if await pushTimesheets(timesheets), dirtyGeneration == generation {
                    syncState.setDirty(false, for: .timesheets)
                }
            } else {
                lastError = "Lecture locale impossible: timesheets.json"
            }
        }

        saveSyncState()
        if dirtyGeneration != generation && syncState.hasDirtyData {
            debounceTask?.cancel()
            debounceTask = Task { await pushAllDirty() }
        }
    }

    // MARK: - Push Documents

    private func pushDocuments(_ docs: [Document]) async -> Bool {
        guard let userId = authService?.userId, !userId.isEmpty else { return false }

        // Parent rows are never deleted from a whole-collection dirty push.
        // Cross-device deletes need explicit tombstones to avoid erasing newer remote rows.
        for doc in docs {
            let body: [String: Any] = [
                "id": doc.id.uuidString,
                "user_id": userId,
                "type_raw_value": doc.typeRawValue,
                "number": doc.number,
                "date_creation": syncDateString(doc.dateCreation),
                "date_echeance": syncDateString(doc.dateEcheance),
                "status_raw_value": doc.statusRawValue,
                "payment_mode_raw_value": doc.paymentModeRawValue,
                "currency_raw_value": doc.currencyRawValue,
                "blockchain_raw_value": doc.blockchainRawValue ?? "",
                "client_nom": doc.clientNom,
                "client_adresse": doc.clientAdresse,
                "client_code_postal": doc.clientCodePostal,
                "client_ville": doc.clientVille,
                "notes": doc.notes,
                "selected_wallet_id": doc.selectedWalletId?.uuidString ?? NSNull(),
                "langue_raw_value": doc.langueRawValue,
                "created_at": syncDateString(doc.createdAt),
                "updated_at": syncDateString(doc.updatedAt),
            ]
            guard await supabaseUpsert(table: "documents", body: body, onConflict: "id") else { return false }

            // Upsert first, then delete stale children so a partial failure does not wipe existing rows.
            if !doc.lignes.isEmpty {
                let lineItems: [[String: Any]] = doc.lignes.map { li in
                    [
                        "id": li.id.uuidString,
                        "user_id": userId,
                        "document_id": doc.id.uuidString,
                        "designation": li.designation,
                        "quantite": decimalPayload(li.quantite),
                        "prix_unitaire": decimalPayload(li.prixUnitaire),
                        "taux_tva": decimalPayload(li.tauxTVA),
                        "ordre": li.ordre,
                    ]
                }
                guard await supabaseBatchUpsert(table: "line_items", rows: lineItems, onConflict: "id") else { return false }
            }
            let localLineItemIds = Set(doc.lignes.map { $0.id.uuidString })
            guard let remoteLineItemIds = await fetchRemoteIdsOrFail(
                table: "line_items",
                query: "select=id&document_id=eq.\(doc.id.uuidString)"
            ) else { return false }
            for id in remoteLineItemIds.subtracting(localLineItemIds) {
                guard await supabaseDelete(table: "line_items", filter: "id=eq.\(id)") else { return false }
            }

            if !doc.transactionSignatures.isEmpty {
                let sigs: [[String: Any]] = doc.transactionSignatures.map { ts in
                    [
                        "id": ts.id.uuidString,
                        "user_id": userId,
                        "document_id": doc.id.uuidString,
                        "signature": ts.signature,
                        "date": syncDateString(ts.date),
                        "montant": decimalPayload(ts.montant),
                        "blockchain_raw_value": ts.blockchainRawValue,
                    ]
                }
                guard await supabaseBatchUpsert(table: "transaction_signatures", rows: sigs, onConflict: "id") else { return false }
            }
            let localSignatureIds = Set(doc.transactionSignatures.map { $0.id.uuidString })
            guard let remoteSignatureIds = await fetchRemoteIdsOrFail(
                table: "transaction_signatures",
                query: "select=id&document_id=eq.\(doc.id.uuidString)"
            ) else { return false }
            for id in remoteSignatureIds.subtracting(localSignatureIds) {
                guard await supabaseDelete(table: "transaction_signatures", filter: "id=eq.\(id)") else { return false }
            }
        }

        lastSyncDate = Date()
        lastError = nil
        return true
    }

    // MARK: - Push Clients

    private func pushClients(_ clients: [ClientInfo]) async -> Bool {
        guard let userId = authService?.userId, !userId.isEmpty else { return false }

        for client in clients {
            let body: [String: Any] = [
                "id": client.id.uuidString,
                "user_id": userId,
                "nom": client.nom,
                "adresse": client.adresse,
                "code_postal": client.codePostal,
                "ville": client.ville,
                "email": client.email,
                "created_at": syncDateString(client.createdAt),
                "updated_at": syncDateString(client.updatedAt),
            ]
            guard await supabaseUpsert(table: "clients", body: body, onConflict: "id") else { return false }
        }

        lastSyncDate = Date()
        lastError = nil
        return true
    }

    // MARK: - Push Company

    private func pushCompany(_ company: CompanyInfo) async -> Bool {
        guard let userId = authService?.userId, !userId.isEmpty else { return false }
        if companyLooksRecoveredBlank(company),
           let remote = await pullCompany(),
           !companyLooksRecoveredBlank(remote) {
            return true
        }

        let logoBase64 = company.logoData?.base64EncodedString() ?? ""
        let body: [String: Any] = [
            "id": company.id.uuidString,
            "user_id": userId,
            "nom": company.nom,
            "adresse": company.adresse,
            "code_postal": company.codePostal,
            "ville": company.ville,
            "siret": company.siret,
            "telephone": company.telephone,
            "email": company.email,
            "logo_data": logoBase64,
            "nom_banque": company.nomBanque,
            "iban": company.iban,
            "bic": company.bic,
            "titulaire_compte": company.titulaireCompte,
            "taux_tva_par_defaut": decimalPayload(company.tauxTVAParDefaut),
            "delai_paiement_jours": company.delaiPaiementJours,
            "devise_par_defaut_raw_value": company.deviseParDefautRawValue,
            "blockchain_par_defaut_raw_value": company.blockchainParDefautRawValue ?? "",
            "langue_par_defaut_raw_value": company.langueParDefautRawValue,
            "format_date_raw_value": company.formatDateRawValue,
            "format_nombre_raw_value": company.formatNombreRawValue,
            "couleur_accent_hex": company.couleurAccentHex ?? NSNull(),
            "updated_at": syncDateString(company.updatedAt),
        ]
        guard await supabaseUpsert(table: "company_info", body: body, onConflict: "id") else { return false }

        if !company.wallets.isEmpty {
            let wallets: [[String: Any]] = company.wallets.map { w in
                [
                    "id": w.id.uuidString,
                    "user_id": userId,
                    "company_id": company.id.uuidString,
                    "blockchain_raw_value": w.blockchainRawValue,
                    "address": w.address,
                    "label": w.label,
                ]
            }
            guard await supabaseBatchUpsert(table: "wallets", rows: wallets, onConflict: "id") else { return false }
        }
        let localWalletIds = Set(company.wallets.map { $0.id.uuidString })
        guard let remoteWalletIds = await fetchRemoteIdsOrFail(
            table: "wallets",
            query: "select=id&company_id=eq.\(company.id.uuidString)"
        ) else { return false }
        for id in remoteWalletIds.subtracting(localWalletIds) {
            guard await supabaseDelete(table: "wallets", filter: "id=eq.\(id)") else { return false }
        }

        if !company.prestations.isEmpty {
            let presets: [[String: Any]] = company.prestations.map { p in
                [
                    "id": p.id.uuidString,
                    "user_id": userId,
                    "company_id": company.id.uuidString,
                    "designation": p.designation,
                    "prix_unitaire": decimalPayload(p.prixUnitaire),
                    "taux_tva": decimalPayload(p.tauxTVA),
                ]
            }
            guard await supabaseBatchUpsert(table: "prestation_presets", rows: presets, onConflict: "id") else { return false }
        }
        let localPresetIds = Set(company.prestations.map { $0.id.uuidString })
        guard let remotePresetIds = await fetchRemoteIdsOrFail(
            table: "prestation_presets",
            query: "select=id&company_id=eq.\(company.id.uuidString)"
        ) else { return false }
        for id in remotePresetIds.subtracting(localPresetIds) {
            guard await supabaseDelete(table: "prestation_presets", filter: "id=eq.\(id)") else { return false }
        }

        lastSyncDate = Date()
        lastError = nil
        return true
    }

    // MARK: - Push Timesheets

    private func pushTimesheets(_ timesheets: [TimesheetPeriod]) async -> Bool {
        guard let userId = authService?.userId, !userId.isEmpty else { return false }

        for ts in timesheets {
            let body: [String: Any] = [
                "id": ts.id.uuidString,
                "user_id": userId,
                "nom": ts.nom,
                "mois": ts.mois,
                "annee": ts.annee,
                "taux_normal": decimalPayload(ts.tauxNormal),
                "taux_supplementaire": decimalPayload(ts.tauxSupplementaire),
                "coefficient_net": decimalPayload(ts.coefficientNet),
                "seuil_hebdo": decimalPayload(ts.seuilHebdo),
                "created_at": syncDateString(ts.createdAt),
                "updated_at": syncDateString(ts.updatedAt),
            ]
            guard await supabaseUpsert(table: "timesheet_periods", body: body, onConflict: "id") else { return false }

            for week in ts.semaines {
                let weekBody: [String: Any] = [
                    "id": week.id.uuidString,
                    "user_id": userId,
                    "period_id": ts.id.uuidString,
                    "numero": week.numero,
                ]
                guard await supabaseUpsert(table: "timesheet_weeks", body: weekBody, onConflict: "id") else { return false }

                let localDayIds = Set(week.jours.map { $0.id.uuidString })
                if !week.jours.isEmpty {
                    let days: [[String: Any]] = week.jours.map { day in
                        [
                            "id": day.id.uuidString,
                            "user_id": userId,
                            "week_id": week.id.uuidString,
                            "date_string": day.dateString,
                            "heures": decimalPayload(day.heures),
                        ]
                    }
                    guard await supabaseBatchUpsert(table: "timesheet_days", rows: days, onConflict: "id") else { return false }
                }
                guard let remoteDayIds = await fetchRemoteIdsOrFail(
                    table: "timesheet_days",
                    query: "select=id&week_id=eq.\(week.id.uuidString)"
                ) else { return false }
                for id in remoteDayIds.subtracting(localDayIds) {
                    guard await supabaseDelete(table: "timesheet_days", filter: "id=eq.\(id)") else { return false }
                }
            }

            let localWeekIds = Set(ts.semaines.map { $0.id.uuidString })
            guard let remoteWeekIds = await fetchRemoteIdsOrFail(
                table: "timesheet_weeks",
                query: "select=id&period_id=eq.\(ts.id.uuidString)"
            ) else { return false }
            for id in remoteWeekIds.subtracting(localWeekIds) {
                guard await supabaseDelete(table: "timesheet_weeks", filter: "id=eq.\(id)") else { return false }
            }
        }

        lastSyncDate = Date()
        lastError = nil
        return true
    }

    // MARK: - Pull

    func pullDocuments() async -> [Document]? {
        // Fetch documents with embedded line_items and transaction_signatures
        guard let jsonArray = await supabaseGet(
            table: "documents",
            query: "select=*,line_items(*),transaction_signatures(*)"
        ) else { return nil }

        var docs: [Document] = []
        for json in jsonArray {
            guard let id = (json["id"] as? String).flatMap({ UUID(uuidString: $0) }) else { continue }
            let doc = Document()
            doc.id = id
            doc.typeRawValue = json["type_raw_value"] as? String ?? "Facture"
            doc.number = json["number"] as? String ?? ""
            doc.dateCreation = parseDate(json["date_creation"]) ?? doc.dateCreation
            doc.dateEcheance = parseDate(json["date_echeance"])
                ?? Calendar.current.date(byAdding: .day, value: 30, to: doc.dateCreation)
                ?? doc.dateCreation
            doc.statusRawValue = json["status_raw_value"] as? String ?? "Brouillon"
            doc.paymentModeRawValue = json["payment_mode_raw_value"] as? String ?? "Aucun"
            doc.currencyRawValue = json["currency_raw_value"] as? String ?? "EUR"
            let blockchainRaw = json["blockchain_raw_value"] as? String ?? ""
            doc.blockchainRawValue = blockchainRaw.isEmpty ? nil : blockchainRaw
            doc.clientNom = json["client_nom"] as? String ?? ""
            doc.clientAdresse = json["client_adresse"] as? String ?? ""
            doc.clientCodePostal = json["client_code_postal"] as? String ?? ""
            doc.clientVille = json["client_ville"] as? String ?? ""
            doc.notes = json["notes"] as? String ?? ""
            doc.selectedWalletId = (json["selected_wallet_id"] as? String).flatMap { UUID(uuidString: $0) }
            doc.langueRawValue = json["langue_raw_value"] as? String ?? "fr"
            doc.createdAt = parseDate(json["created_at"]) ?? doc.dateCreation
            doc.updatedAt = parseDate(json["updated_at"]) ?? doc.createdAt

            // Parse line_items
            if let lineItemsJson = json["line_items"] as? [[String: Any]] {
                doc.lignes = lineItemsJson.compactMap { li in
                    guard (li["id"] as? String).flatMap({ UUID(uuidString: $0) }) != nil else { return nil }
                    return LineItem(
                        designation: li["designation"] as? String ?? "",
                        quantite: decimalValue(li["quantite"]),
                        prixUnitaire: decimalValue(li["prix_unitaire"]),
                        tauxTVA: decimalValue(li["taux_tva"]),
                        ordre: li["ordre"] as? Int ?? 0
                    )
                }
                // Restore IDs from remote
                for (i, li) in (json["line_items"] as? [[String: Any]] ?? []).enumerated() {
                    if i < doc.lignes.count, let liId = (li["id"] as? String).flatMap({ UUID(uuidString: $0) }) {
                        doc.lignes[i].id = liId
                    }
                }
            }

            // Parse transaction_signatures
            if let sigsJson = json["transaction_signatures"] as? [[String: Any]] {
                doc.transactionSignatures = sigsJson.compactMap { sig in
                    guard let sigId = (sig["id"] as? String).flatMap({ UUID(uuidString: $0) }) else { return nil }
                    var ts = TransactionSignature(
                        signature: sig["signature"] as? String ?? "",
                        date: parseDate(sig["date"]) ?? doc.dateCreation,
                        montant: decimalValue(sig["montant"]),
                        blockchain: Blockchain(rawValue: sig["blockchain_raw_value"] as? String ?? "Solana") ?? .solana
                    )
                    ts.id = sigId
                    return ts
                }
            }

            docs.append(doc)
        }
        return docs
    }

    func pullClients() async -> [ClientInfo]? {
        guard let jsonArray = await supabaseGet(table: "clients", query: "select=*") else { return nil }

        var clients: [ClientInfo] = []
        for json in jsonArray {
            guard let id = (json["id"] as? String).flatMap({ UUID(uuidString: $0) }) else { continue }
            let client = ClientInfo()
            client.id = id
            client.nom = json["nom"] as? String ?? ""
            client.adresse = json["adresse"] as? String ?? ""
            client.codePostal = json["code_postal"] as? String ?? ""
            client.ville = json["ville"] as? String ?? ""
            client.email = json["email"] as? String ?? ""
            client.createdAt = parseDate(json["created_at"]) ?? client.createdAt
            client.updatedAt = parseDate(json["updated_at"]) ?? client.createdAt
            clients.append(client)
        }
        return clients
    }

    func pullCompany() async -> CompanyInfo? {
        guard let jsonArray = await supabaseGet(
            table: "company_info",
            query: "select=*,wallets(*),prestation_presets(*)"
        ), let json = jsonArray.first else { return nil }

        guard let id = (json["id"] as? String).flatMap({ UUID(uuidString: $0) }) else { return nil }
        let company = CompanyInfo()
        company.id = id
        company.nom = json["nom"] as? String ?? ""
        company.adresse = json["adresse"] as? String ?? ""
        company.codePostal = json["code_postal"] as? String ?? ""
        company.ville = json["ville"] as? String ?? ""
        company.siret = json["siret"] as? String ?? ""
        company.telephone = json["telephone"] as? String ?? ""
        company.email = json["email"] as? String ?? ""
        if let logoB64 = json["logo_data"] as? String, !logoB64.isEmpty {
            company.logoData = Data(base64Encoded: logoB64)
        }
        company.nomBanque = json["nom_banque"] as? String ?? ""
        company.iban = json["iban"] as? String ?? ""
        company.bic = json["bic"] as? String ?? ""
        company.titulaireCompte = json["titulaire_compte"] as? String ?? ""
        company.tauxTVAParDefaut = decimalValue(json["taux_tva_par_defaut"])
        company.delaiPaiementJours = json["delai_paiement_jours"] as? Int ?? 30
        company.deviseParDefautRawValue = json["devise_par_defaut_raw_value"] as? String ?? "USDC"
        let blockRaw = json["blockchain_par_defaut_raw_value"] as? String ?? ""
        company.blockchainParDefautRawValue = blockRaw.isEmpty ? Blockchain.solana.rawValue : blockRaw
        company.langueParDefautRawValue = json["langue_par_defaut_raw_value"] as? String ?? "fr"
        company.formatDateRawValue = json["format_date_raw_value"] as? String ?? "fr"
        company.formatNombreRawValue = json["format_nombre_raw_value"] as? String ?? "fr"
        company.couleurAccentHex = json["couleur_accent_hex"] as? String
        company.updatedAt = parseDate(json["updated_at"]) ?? company.updatedAt

        // Wallets
        if let walletsJson = json["wallets"] as? [[String: Any]] {
            company.wallets = walletsJson.compactMap { w in
                guard let wId = (w["id"] as? String).flatMap({ UUID(uuidString: $0) }) else { return nil }
                var wallet = WalletEntry(
                    blockchain: Blockchain(rawValue: w["blockchain_raw_value"] as? String ?? "Solana") ?? .solana,
                    address: w["address"] as? String ?? "",
                    label: w["label"] as? String ?? ""
                )
                wallet.id = wId
                return wallet
            }
        }

        // Presets
        if let presetsJson = json["prestation_presets"] as? [[String: Any]] {
            company.prestations = presetsJson.compactMap { p in
                guard let pId = (p["id"] as? String).flatMap({ UUID(uuidString: $0) }) else { return nil }
                var preset = DesignationPreset(
                    designation: p["designation"] as? String ?? "",
                    prixUnitaire: decimalValue(p["prix_unitaire"]),
                    tauxTVA: decimalValue(p["taux_tva"])
                )
                preset.id = pId
                return preset
            }
        }

        return company
    }

    func pullTimesheets() async -> [TimesheetPeriod]? {
        guard let periodsJson = await supabaseGet(
            table: "timesheet_periods",
            query: "select=*,timesheet_weeks(*,timesheet_days(*))"
        ) else { return nil }

        var periods: [TimesheetPeriod] = []
        for json in periodsJson {
            guard let id = (json["id"] as? String).flatMap({ UUID(uuidString: $0) }) else { continue }
            let period = TimesheetPeriod()
            period.id = id
            period.nom = json["nom"] as? String ?? ""
            period.mois = json["mois"] as? Int ?? 1
            period.annee = json["annee"] as? Int ?? 2026
            period.tauxNormal = decimalValue(json["taux_normal"], default: 26.39)
            period.tauxSupplementaire = decimalValue(json["taux_supplementaire"], default: 39.59)
            period.coefficientNet = decimalValue(json["coefficient_net"], default: 0.756)
            period.seuilHebdo = decimalValue(json["seuil_hebdo"], default: 35)
            period.createdAt = parseDate(json["created_at"]) ?? period.createdAt
            period.updatedAt = parseDate(json["updated_at"]) ?? period.createdAt

            // Weeks
            if let weeksJson = json["timesheet_weeks"] as? [[String: Any]] {
                period.semaines = weeksJson.compactMap { w in
                    guard let wId = (w["id"] as? String).flatMap({ UUID(uuidString: $0) }) else { return nil }
                    var week = TimesheetWeek()
                    week.id = wId
                    week.numero = w["numero"] as? Int ?? 1

                    // Days
                    if let daysJson = w["timesheet_days"] as? [[String: Any]] {
                        week.jours = daysJson.compactMap { d in
                            let dateStr = d["date_string"] as? String ?? ""
                            guard let date = TimesheetDay.dateFormatter.date(from: dateStr) else { return nil }
                            var day = TimesheetDay(date: date, heures: decimalValue(d["heures"]))
                            if let dId = (d["id"] as? String).flatMap({ UUID(uuidString: $0) }) {
                                day.id = dId
                            }
                            return day
                        }.sorted { $0.dateString < $1.dateString }
                    }

                    return week
                }.sorted { $0.numero < $1.numero }
            }

            periods.append(period)
        }
        return periods
    }

    // MARK: - Full Sync

    /// Reinitialise le sync state (apres un reset app)
    func resetSyncState() {
        syncState = SyncState()
        dirtyGeneration += 1
        saveSyncState()
    }

    func fullSync(dataStore: DataStore) async {
        guard SyncConfig.isEnabled, SyncConfig.isConfigured,
              authService?.isAuthenticated == true else { return }
        guard !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        // Push local changes first. If a collection is still dirty after push,
        // keep local data authoritative and skip the remote pull for that key.
        await pushAllDirty()
        let dirtyAfterPush = syncState

        // Pull remote data
        let pullGeneration = dirtyGeneration
        var skippedPulledData = false
        var localSaveFailed = false

        if shouldPull(.documents, dirtySnapshot: dirtyAfterPush, generation: pullGeneration),
           let docs = await pullDocuments() {
            if shouldApplyPull(.documents, dirtySnapshot: dirtyAfterPush, generation: pullGeneration) {
                localSaveFailed = !dataStore.applyPulledDocuments(docs) || localSaveFailed
            } else {
                skippedPulledData = true
            }
        }
        if shouldPull(.clients, dirtySnapshot: dirtyAfterPush, generation: pullGeneration),
           let clients = await pullClients() {
            if shouldApplyPull(.clients, dirtySnapshot: dirtyAfterPush, generation: pullGeneration) {
                localSaveFailed = !dataStore.applyPulledClients(clients) || localSaveFailed
            } else {
                skippedPulledData = true
            }
        }
        if shouldPull(.company, dirtySnapshot: dirtyAfterPush, generation: pullGeneration),
           let company = await pullCompany() {
            if !companyLooksRecoveredBlank(company) || companyLooksRecoveredBlank(dataStore.companyInfo) {
                if shouldApplyPull(.company, dirtySnapshot: dirtyAfterPush, generation: pullGeneration) {
                    localSaveFailed = !dataStore.applyPulledCompany(company) || localSaveFailed
                } else {
                    skippedPulledData = true
                }
            }
        }
        if shouldPull(.timesheets, dirtySnapshot: dirtyAfterPush, generation: pullGeneration),
           let timesheets = await pullTimesheets() {
            if shouldApplyPull(.timesheets, dirtySnapshot: dirtyAfterPush, generation: pullGeneration) {
                localSaveFailed = !dataStore.applyPulledTimesheets(timesheets) || localSaveFailed
            } else {
                skippedPulledData = true
            }
        }
        if dirtyAfterPush.hasDirtyData || skippedPulledData || dirtyGeneration != pullGeneration {
            lastError = "Synchronisation partielle: des donnees locales restent a envoyer."
        } else if localSaveFailed {
            lastError = "Synchronisation partielle: sauvegarde locale impossible."
        }

        syncState.lastFullSyncAt = Date()
        lastSyncDate = Date()
        saveSyncState()
    }

    // MARK: - Supabase REST Helpers

    private func supabaseUpsert(table: String, body: [String: Any], onConflict: String) async -> Bool {
        guard let url = buildURL(path: "/rest/v1/\(table)?on_conflict=\(onConflict)") else { return false }
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        addHeaders(&request, token: authService?.accessToken)
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")

        return await executeRequest(request)
    }

    private func supabaseBatchInsert(table: String, rows: [[String: Any]]) async -> Bool {
        guard !rows.isEmpty else { return true }
        guard let url = buildURL(path: "/rest/v1/\(table)") else { return false }
        guard let bodyData = try? JSONSerialization.data(withJSONObject: rows) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        addHeaders(&request, token: authService?.accessToken)
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        return await executeRequest(request)
    }

    private func supabaseBatchUpsert(table: String, rows: [[String: Any]], onConflict: String) async -> Bool {
        guard !rows.isEmpty else { return true }
        guard let url = buildURL(path: "/rest/v1/\(table)?on_conflict=\(onConflict)") else { return false }
        guard let bodyData = try? JSONSerialization.data(withJSONObject: rows) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        addHeaders(&request, token: authService?.accessToken)
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")

        return await executeRequest(request)
    }

    private func supabaseDelete(table: String, filter: String) async -> Bool {
        guard let url = buildURL(path: "/rest/v1/\(table)?\(filter)") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        addHeaders(&request, token: authService?.accessToken)

        return await executeRequest(request)
    }

    private func supabaseGet(table: String, query: String, retryOn401: Bool = true) async -> [[String: Any]]? {
        guard let url = buildURL(path: "/rest/v1/\(table)?\(query)") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addHeaders(&request, token: authService?.accessToken)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return nil }

            if httpResponse.statusCode == 401 && retryOn401 {
                await authService?.refreshSession()
                guard authService?.isAuthenticated == true else { return nil }
                return await supabaseGet(table: table, query: query, retryOn401: false)
            }

            guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = json["message"] as? String {
                    lastError = msg
                }
                return nil
            }
            return try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    private func fetchRemoteIds(table: String) async throws -> Set<String> {
        try await fetchRemoteIds(table: table, query: "select=id")
    }

    private func fetchRemoteIdsOrFail(table: String, query: String) async -> Set<String>? {
        do {
            return try await fetchRemoteIds(table: table, query: query)
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    private func fetchRemoteIds(table: String, query: String, retryOn401: Bool = true) async throws -> Set<String> {
        guard let url = buildURL(path: "/rest/v1/\(table)?\(query)") else {
            throw RemoteIdFetchError.invalidURL(table: table)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addHeaders(&request, token: authService?.accessToken)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RemoteIdFetchError.invalidResponse(table: table)
            }

            if httpResponse.statusCode == 401 && retryOn401 {
                await authService?.refreshSession()
                guard authService?.isAuthenticated == true else {
                    throw RemoteIdFetchError.httpStatus(table: table, statusCode: httpResponse.statusCode, message: nil)
                }
                return try await fetchRemoteIds(table: table, query: query, retryOn401: false)
            }

            guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                throw RemoteIdFetchError.httpStatus(
                    table: table,
                    statusCode: httpResponse.statusCode,
                    message: errorMessage(from: data)
                )
            }

            guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                throw RemoteIdFetchError.invalidPayload(table: table)
            }
            return Set(jsonArray.compactMap { $0["id"] as? String })
        } catch let error as RemoteIdFetchError {
            throw error
        } catch {
            throw RemoteIdFetchError.requestFailed(table: table, error: error)
        }
    }

    private func executeRequest(_ request: URLRequest, retryOn401: Bool = true) async -> Bool {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    lastError = nil
                    return true
                }
                // Token expire : tenter un refresh et reessayer une fois
                if httpResponse.statusCode == 401 && retryOn401 {
                    await authService?.refreshSession()
                    guard authService?.isAuthenticated == true else { return false }
                    var retried = request
                    retried.setValue("Bearer \(authService?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
                    return await executeRequest(retried, retryOn401: false)
                }
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = json["message"] as? String ?? json["msg"] as? String {
                    lastError = msg
                } else {
                    lastError = "Erreur HTTP \(httpResponse.statusCode)"
                }
            }
            return false
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    // MARK: - Helpers

    private func buildURL(path: String) -> URL? {
        let base = SyncConfig.url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)\(path)"), url.scheme == "https" else { return nil }
        return url
    }

    private func addHeaders(_ request: inout URLRequest, token: String? = nil) {
        request.addValue(SyncConfig.apiKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(token ?? SyncConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    private func syncDateString(_ date: Date) -> String {
        Self.iso8601Formatter.string(from: date)
    }

    private func parseDate(_ value: Any?) -> Date? {
        guard let str = value as? String else { return nil }
        return Self.iso8601FractionalFormatter.date(from: str)
            ?? Self.iso8601Formatter.date(from: str)
    }

    private func decimalPayload(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }

    private func decimalValue(_ value: Any?, default defaultValue: Decimal = 0) -> Decimal {
        if let decimal = value as? Decimal {
            return decimal
        }
        if let number = value as? NSDecimalNumber {
            return number.decimalValue
        }
        if let number = value as? NSNumber {
            return number.decimalValue
        }
        if let string = value as? String {
            let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return Decimal(string: normalized, locale: Self.decimalLocale) ?? defaultValue
        }
        return defaultValue
    }

    private func shouldPull(_ key: SyncDataKey, dirtySnapshot: SyncState, generation: Int) -> Bool {
        shouldApplyPull(key, dirtySnapshot: dirtySnapshot, generation: generation)
    }

    private func shouldApplyPull(_ key: SyncDataKey, dirtySnapshot: SyncState, generation: Int) -> Bool {
        !dirtySnapshot.isDirty(key)
            && !syncState.isDirty(key)
            && dirtyGeneration == generation
    }

    private func errorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["message"] as? String ?? json["msg"] as? String
    }

    private func companyLooksRecoveredBlank(_ company: CompanyInfo) -> Bool {
        let textFields = [
            company.nom,
            company.adresse,
            company.codePostal,
            company.ville,
            company.siret,
            company.telephone,
            company.email,
            company.nomBanque,
            company.iban,
            company.bic,
            company.titulaireCompte,
            company.couleurAccentHex ?? "",
        ]
        return textFields.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            && company.logoData == nil
            && company.wallets.isEmpty
            && company.prestations.isEmpty
            && company.tauxTVAParDefaut == 0
            && company.delaiPaiementJours == 30
            && company.deviseParDefautRawValue == "USDC"
            && (company.blockchainParDefautRawValue ?? "Solana") == "Solana"
            && company.langueParDefautRawValue == "fr"
            && company.formatDateRawValue == "fr"
            && company.formatNombreRawValue == "fr"
    }

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let iso8601FractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let decimalLocale = Locale(identifier: "en_US_POSIX")

    private enum RemoteIdFetchError: LocalizedError {
        case invalidURL(table: String)
        case invalidResponse(table: String)
        case httpStatus(table: String, statusCode: Int, message: String?)
        case invalidPayload(table: String)
        case requestFailed(table: String, error: Error)

        var errorDescription: String? {
            switch self {
            case .invalidURL(let table):
                return "URL Supabase invalide pour \(table)."
            case .invalidResponse(let table):
                return "Reponse Supabase invalide pendant la lecture des IDs \(table)."
            case .httpStatus(let table, let statusCode, let message):
                if let message, !message.isEmpty {
                    return "Lecture des IDs \(table) impossible: HTTP \(statusCode) - \(message)"
                } else {
                    return "Lecture des IDs \(table) impossible: HTTP \(statusCode)"
                }
            case .invalidPayload(let table):
                return "Payload Supabase invalide pendant la lecture des IDs \(table)."
            case .requestFailed(let table, let error):
                return "Lecture des IDs \(table) impossible: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - SQL Schema (shown in settings for custom DB setup)

    static let sqlSchema = """
    -- Facio: Schema pour base de donnees custom
    -- Executez ce SQL dans l'editeur SQL de votre projet Supabase

    -- 1. Documents (factures et devis)
    CREATE TABLE documents (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      type_raw_value TEXT NOT NULL DEFAULT 'Facture',
      number TEXT NOT NULL DEFAULT '',
      date_creation TIMESTAMPTZ NOT NULL DEFAULT now(),
      date_echeance TIMESTAMPTZ NOT NULL DEFAULT now(),
      status_raw_value TEXT NOT NULL DEFAULT 'Brouillon',
      payment_mode_raw_value TEXT NOT NULL DEFAULT 'Aucun',
      currency_raw_value TEXT NOT NULL DEFAULT 'EUR',
      blockchain_raw_value TEXT NOT NULL DEFAULT '',
      client_nom TEXT NOT NULL DEFAULT '',
      client_adresse TEXT NOT NULL DEFAULT '',
      client_code_postal TEXT NOT NULL DEFAULT '',
      client_ville TEXT NOT NULL DEFAULT '',
      notes TEXT NOT NULL DEFAULT '',
      selected_wallet_id UUID,
      langue_raw_value TEXT NOT NULL DEFAULT 'fr',
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );

    -- 2. Lignes de facturation
    CREATE TABLE line_items (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
      designation TEXT NOT NULL DEFAULT '',
      quantite NUMERIC NOT NULL DEFAULT 0,
      prix_unitaire NUMERIC NOT NULL DEFAULT 0,
      taux_tva NUMERIC NOT NULL DEFAULT 0,
      ordre INT NOT NULL DEFAULT 0
    );

    -- 3. Signatures de transactions blockchain
    CREATE TABLE transaction_signatures (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
      signature TEXT NOT NULL DEFAULT '',
      date TIMESTAMPTZ NOT NULL DEFAULT now(),
      montant NUMERIC NOT NULL DEFAULT 0,
      blockchain_raw_value TEXT NOT NULL DEFAULT 'Solana'
    );

    -- 4. Clients
    CREATE TABLE clients (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      nom TEXT NOT NULL DEFAULT '',
      adresse TEXT NOT NULL DEFAULT '',
      code_postal TEXT NOT NULL DEFAULT '',
      ville TEXT NOT NULL DEFAULT '',
      email TEXT NOT NULL DEFAULT '',
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );

    -- 5. Informations entreprise (une ligne par utilisateur)
    CREATE TABLE company_info (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      nom TEXT NOT NULL DEFAULT '',
      adresse TEXT NOT NULL DEFAULT '',
      code_postal TEXT NOT NULL DEFAULT '',
      ville TEXT NOT NULL DEFAULT '',
      siret TEXT NOT NULL DEFAULT '',
      telephone TEXT NOT NULL DEFAULT '',
      email TEXT NOT NULL DEFAULT '',
      logo_data TEXT,
      nom_banque TEXT NOT NULL DEFAULT '',
      iban TEXT NOT NULL DEFAULT '',
      bic TEXT NOT NULL DEFAULT '',
      titulaire_compte TEXT NOT NULL DEFAULT '',
      taux_tva_par_defaut NUMERIC NOT NULL DEFAULT 0,
      delai_paiement_jours INT NOT NULL DEFAULT 30,
      devise_par_defaut_raw_value TEXT NOT NULL DEFAULT 'USDC',
      blockchain_par_defaut_raw_value TEXT NOT NULL DEFAULT '',
      langue_par_defaut_raw_value TEXT NOT NULL DEFAULT 'fr',
      format_date_raw_value TEXT NOT NULL DEFAULT 'fr',
      format_nombre_raw_value TEXT NOT NULL DEFAULT 'fr',
      couleur_accent_hex TEXT,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      UNIQUE(user_id)
    );

    -- 6. Wallets crypto
    CREATE TABLE wallets (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      company_id UUID NOT NULL REFERENCES company_info(id) ON DELETE CASCADE,
      blockchain_raw_value TEXT NOT NULL DEFAULT 'Solana',
      address TEXT NOT NULL DEFAULT '',
      label TEXT NOT NULL DEFAULT ''
    );

    -- 7. Prestations favorites
    CREATE TABLE prestation_presets (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      company_id UUID NOT NULL REFERENCES company_info(id) ON DELETE CASCADE,
      designation TEXT NOT NULL DEFAULT '',
      prix_unitaire NUMERIC NOT NULL DEFAULT 0,
      taux_tva NUMERIC NOT NULL DEFAULT 0
    );

    -- 8. Periodes de timesheet (mois)
    CREATE TABLE timesheet_periods (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      nom TEXT NOT NULL DEFAULT '',
      mois INT NOT NULL DEFAULT 1,
      annee INT NOT NULL DEFAULT 2026,
      taux_normal NUMERIC NOT NULL DEFAULT 26.39,
      taux_supplementaire NUMERIC NOT NULL DEFAULT 39.59,
      coefficient_net NUMERIC NOT NULL DEFAULT 0.756,
      seuil_hebdo NUMERIC NOT NULL DEFAULT 35,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );

    -- 9. Semaines de timesheet
    CREATE TABLE timesheet_weeks (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      period_id UUID NOT NULL REFERENCES timesheet_periods(id) ON DELETE CASCADE,
      numero INT NOT NULL DEFAULT 1
    );

    -- 10. Jours de timesheet
    CREATE TABLE timesheet_days (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      week_id UUID NOT NULL REFERENCES timesheet_weeks(id) ON DELETE CASCADE,
      date_string TEXT NOT NULL,
      heures NUMERIC NOT NULL DEFAULT 0
    );

    -- RLS (Row Level Security)
    ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
    ALTER TABLE line_items ENABLE ROW LEVEL SECURITY;
    ALTER TABLE transaction_signatures ENABLE ROW LEVEL SECURITY;
    ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
    ALTER TABLE company_info ENABLE ROW LEVEL SECURITY;
    ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
    ALTER TABLE prestation_presets ENABLE ROW LEVEL SECURITY;
    ALTER TABLE timesheet_periods ENABLE ROW LEVEL SECURITY;
    ALTER TABLE timesheet_weeks ENABLE ROW LEVEL SECURITY;
    ALTER TABLE timesheet_days ENABLE ROW LEVEL SECURITY;

    CREATE POLICY "own_data" ON documents FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "own_data" ON line_items FOR ALL
      USING (
        auth.uid() = user_id
        AND EXISTS (SELECT 1 FROM documents WHERE documents.id = line_items.document_id AND documents.user_id = auth.uid())
      )
      WITH CHECK (
        auth.uid() = user_id
        AND EXISTS (SELECT 1 FROM documents WHERE documents.id = line_items.document_id AND documents.user_id = auth.uid())
      );

    CREATE POLICY "own_data" ON transaction_signatures FOR ALL
      USING (
        auth.uid() = user_id
        AND EXISTS (SELECT 1 FROM documents WHERE documents.id = transaction_signatures.document_id AND documents.user_id = auth.uid())
      )
      WITH CHECK (
        auth.uid() = user_id
        AND EXISTS (SELECT 1 FROM documents WHERE documents.id = transaction_signatures.document_id AND documents.user_id = auth.uid())
      );

    CREATE POLICY "own_data" ON clients FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "own_data" ON company_info FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "own_data" ON wallets FOR ALL
      USING (
        auth.uid() = user_id
        AND EXISTS (SELECT 1 FROM company_info WHERE company_info.id = wallets.company_id AND company_info.user_id = auth.uid())
      )
      WITH CHECK (
        auth.uid() = user_id
        AND EXISTS (SELECT 1 FROM company_info WHERE company_info.id = wallets.company_id AND company_info.user_id = auth.uid())
      );

    CREATE POLICY "own_data" ON prestation_presets FOR ALL
      USING (
        auth.uid() = user_id
        AND EXISTS (SELECT 1 FROM company_info WHERE company_info.id = prestation_presets.company_id AND company_info.user_id = auth.uid())
      )
      WITH CHECK (
        auth.uid() = user_id
        AND EXISTS (SELECT 1 FROM company_info WHERE company_info.id = prestation_presets.company_id AND company_info.user_id = auth.uid())
      );

    CREATE POLICY "own_data" ON timesheet_periods FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "own_data" ON timesheet_weeks FOR ALL
      USING (
        auth.uid() = user_id
        AND EXISTS (SELECT 1 FROM timesheet_periods WHERE timesheet_periods.id = timesheet_weeks.period_id AND timesheet_periods.user_id = auth.uid())
      )
      WITH CHECK (
        auth.uid() = user_id
        AND EXISTS (SELECT 1 FROM timesheet_periods WHERE timesheet_periods.id = timesheet_weeks.period_id AND timesheet_periods.user_id = auth.uid())
      );

    CREATE POLICY "own_data" ON timesheet_days FOR ALL
      USING (
        auth.uid() = user_id
        AND EXISTS (
          SELECT 1
          FROM timesheet_weeks
          JOIN timesheet_periods ON timesheet_periods.id = timesheet_weeks.period_id
          WHERE timesheet_weeks.id = timesheet_days.week_id
            AND timesheet_weeks.user_id = auth.uid()
            AND timesheet_periods.user_id = auth.uid()
        )
      )
      WITH CHECK (
        auth.uid() = user_id
        AND EXISTS (
          SELECT 1
          FROM timesheet_weeks
          JOIN timesheet_periods ON timesheet_periods.id = timesheet_weeks.period_id
          WHERE timesheet_weeks.id = timesheet_days.week_id
            AND timesheet_weeks.user_id = auth.uid()
            AND timesheet_periods.user_id = auth.uid()
        )
      );

    -- Index sur les cles etrangeres
    CREATE INDEX idx_line_items_document ON line_items(document_id);
    CREATE INDEX idx_tx_sigs_document ON transaction_signatures(document_id);
    CREATE INDEX idx_wallets_company ON wallets(company_id);
    CREATE INDEX idx_presets_company ON prestation_presets(company_id);
    CREATE INDEX idx_weeks_period ON timesheet_weeks(period_id);
    CREATE INDEX idx_days_week ON timesheet_days(week_id);
    """
}
