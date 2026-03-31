import Foundation
import Observation

// MARK: - Sync State

struct SyncState: Codable {
    var documentsDirty: Bool = false
    var clientsDirty: Bool = false
    var companyDirty: Bool = false
    var timesheetsDirty: Bool = false
    var lastFullSyncAt: Date?
    var migrationCompleted: Bool = false
}

// MARK: - Sync Config

struct SyncConfig {
    // DB partagee par defaut — lue depuis ~/.facio_config
    static var defaultURL: String { Secrets.supabaseURL }
    static var defaultAPIKey: String { Secrets.supabaseAnonKey }

    // Cles UserDefaults
    private static let customURLKey = "supabase_custom_url"
    private static let customAPIKeyKey = "supabase_custom_api_key"
    private static let useCustomKey = "supabase_use_custom"
    private static let enabledKey = "sync_enabled"

    /// Sync activee
    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    /// Utiliser une DB custom au lieu de la DB partagee
    static var useCustomDB: Bool {
        get { UserDefaults.standard.bool(forKey: useCustomKey) }
        set { UserDefaults.standard.set(newValue, forKey: useCustomKey) }
    }

    /// URL custom
    static var customURL: String {
        get { UserDefaults.standard.string(forKey: customURLKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: customURLKey) }
    }

    /// API key custom
    static var customAPIKey: String {
        get { UserDefaults.standard.string(forKey: customAPIKeyKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: customAPIKeyKey) }
    }

    /// URL effective (custom ou par defaut)
    static var url: String {
        useCustomDB && !customURL.isEmpty ? customURL : defaultURL
    }

    /// API key effective
    static var apiKey: String {
        useCustomDB && !customAPIKey.isEmpty ? customAPIKey : defaultAPIKey
    }

    static var isConfigured: Bool {
        !url.isEmpty && !apiKey.isEmpty
    }
}

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
        switch key {
        case "documents": syncState.documentsDirty = true
        case "clients": syncState.clientsDirty = true
        case "company": syncState.companyDirty = true
        case "timesheets": syncState.timesheetsDirty = true
        default: break
        }
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

        let storageDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Facio", isDirectory: true)

        if syncState.documentsDirty {
            if let data = try? Data(contentsOf: storageDir.appendingPathComponent("documents.json")),
               let docs = try? decoder.decode([Document].self, from: data) {
                if await pushDocuments(docs) { syncState.documentsDirty = false }
            }
        }

        if syncState.clientsDirty {
            if let data = try? Data(contentsOf: storageDir.appendingPathComponent("clients.json")),
               let clients = try? decoder.decode([ClientInfo].self, from: data) {
                if await pushClients(clients) { syncState.clientsDirty = false }
            }
        }

        if syncState.companyDirty {
            if let data = try? Data(contentsOf: storageDir.appendingPathComponent("company.json")),
               let company = try? decoder.decode(CompanyInfo.self, from: data) {
                if await pushCompany(company) { syncState.companyDirty = false }
            }
        }

        if syncState.timesheetsDirty {
            if let data = try? Data(contentsOf: storageDir.appendingPathComponent("timesheets.json")),
               let timesheets = try? decoder.decode([TimesheetPeriod].self, from: data) {
                if await pushTimesheets(timesheets) { syncState.timesheetsDirty = false }
            }
        }

        saveSyncState()
    }

    // MARK: - Push Documents

    private func pushDocuments(_ docs: [Document]) async -> Bool {
        guard let userId = authService?.userId, !userId.isEmpty else { return false }

        // 1. Get remote document IDs to detect deletions
        let remoteIds = await fetchRemoteIds(table: "documents")

        // 2. Delete remote docs that don't exist locally
        let localIds = Set(docs.map { $0.id.uuidString })
        let toDelete = remoteIds.subtracting(localIds)
        for id in toDelete {
            _ = await supabaseDelete(table: "documents", filter: "id=eq.\(id)")
        }

        // 3. Upsert each document
        for doc in docs {
            let body: [String: Any] = [
                "id": doc.id.uuidString,
                "user_id": userId,
                "type_raw_value": doc.typeRawValue,
                "number": doc.number,
                "date_creation": ISO8601DateFormatter().string(from: doc.dateCreation),
                "date_echeance": ISO8601DateFormatter().string(from: doc.dateEcheance),
                "status_raw_value": doc.statusRawValue,
                "payment_mode_raw_value": doc.paymentModeRawValue,
                "currency_raw_value": doc.currencyRawValue,
                "blockchain_raw_value": doc.blockchainRawValue ?? "",
                "client_nom": doc.clientNom,
                "client_adresse": doc.clientAdresse,
                "client_code_postal": doc.clientCodePostal,
                "client_ville": doc.clientVille,
                "notes": doc.notes,
                "selected_wallet_id": doc.selectedWalletId?.uuidString as Any,
                "created_at": ISO8601DateFormatter().string(from: doc.createdAt),
                "updated_at": ISO8601DateFormatter().string(from: doc.updatedAt),
            ]
            guard await supabaseUpsert(table: "documents", body: body, onConflict: "id") else { return false }

            // Delete + reinsert line_items
            _ = await supabaseDelete(table: "line_items", filter: "document_id=eq.\(doc.id.uuidString)")
            if !doc.lignes.isEmpty {
                let lineItems: [[String: Any]] = doc.lignes.map { li in
                    [
                        "id": li.id.uuidString,
                        "user_id": userId,
                        "document_id": doc.id.uuidString,
                        "designation": li.designation,
                        "quantite": NSDecimalNumber(decimal: li.quantite).doubleValue,
                        "prix_unitaire": NSDecimalNumber(decimal: li.prixUnitaire).doubleValue,
                        "taux_tva": NSDecimalNumber(decimal: li.tauxTVA).doubleValue,
                        "ordre": li.ordre,
                    ]
                }
                guard await supabaseBatchInsert(table: "line_items", rows: lineItems) else { return false }
            }

            // Delete + reinsert transaction_signatures
            _ = await supabaseDelete(table: "transaction_signatures", filter: "document_id=eq.\(doc.id.uuidString)")
            if !doc.transactionSignatures.isEmpty {
                let sigs: [[String: Any]] = doc.transactionSignatures.map { ts in
                    [
                        "id": ts.id.uuidString,
                        "user_id": userId,
                        "document_id": doc.id.uuidString,
                        "signature": ts.signature,
                        "date": ISO8601DateFormatter().string(from: ts.date),
                        "montant": NSDecimalNumber(decimal: ts.montant).doubleValue,
                        "blockchain_raw_value": ts.blockchainRawValue,
                    ]
                }
                guard await supabaseBatchInsert(table: "transaction_signatures", rows: sigs) else { return false }
            }
        }

        lastSyncDate = Date()
        lastError = nil
        return true
    }

    // MARK: - Push Clients

    private func pushClients(_ clients: [ClientInfo]) async -> Bool {
        guard let userId = authService?.userId, !userId.isEmpty else { return false }

        let remoteIds = await fetchRemoteIds(table: "clients")
        let localIds = Set(clients.map { $0.id.uuidString })
        for id in remoteIds.subtracting(localIds) {
            _ = await supabaseDelete(table: "clients", filter: "id=eq.\(id)")
        }

        for client in clients {
            let body: [String: Any] = [
                "id": client.id.uuidString,
                "user_id": userId,
                "nom": client.nom,
                "adresse": client.adresse,
                "code_postal": client.codePostal,
                "ville": client.ville,
                "email": client.email,
                "created_at": ISO8601DateFormatter().string(from: client.createdAt),
                "updated_at": ISO8601DateFormatter().string(from: client.updatedAt),
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
            "taux_tva_par_defaut": NSDecimalNumber(decimal: company.tauxTVAParDefaut).doubleValue,
            "delai_paiement_jours": company.delaiPaiementJours,
            "devise_par_defaut_raw_value": company.deviseParDefautRawValue,
            "blockchain_par_defaut_raw_value": company.blockchainParDefautRawValue ?? "",
            "updated_at": ISO8601DateFormatter().string(from: company.updatedAt),
        ]
        guard await supabaseUpsert(table: "company_info", body: body, onConflict: "id") else { return false }

        // Wallets: delete + reinsert
        _ = await supabaseDelete(table: "wallets", filter: "company_id=eq.\(company.id.uuidString)")
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
            guard await supabaseBatchInsert(table: "wallets", rows: wallets) else { return false }
        }

        // Presets: delete + reinsert
        _ = await supabaseDelete(table: "prestation_presets", filter: "company_id=eq.\(company.id.uuidString)")
        if !company.prestations.isEmpty {
            let presets: [[String: Any]] = company.prestations.map { p in
                [
                    "id": p.id.uuidString,
                    "user_id": userId,
                    "company_id": company.id.uuidString,
                    "designation": p.designation,
                    "prix_unitaire": NSDecimalNumber(decimal: p.prixUnitaire).doubleValue,
                    "taux_tva": NSDecimalNumber(decimal: p.tauxTVA).doubleValue,
                ]
            }
            guard await supabaseBatchInsert(table: "prestation_presets", rows: presets) else { return false }
        }

        lastSyncDate = Date()
        lastError = nil
        return true
    }

    // MARK: - Push Timesheets

    private func pushTimesheets(_ timesheets: [TimesheetPeriod]) async -> Bool {
        guard let userId = authService?.userId, !userId.isEmpty else { return false }

        let remoteIds = await fetchRemoteIds(table: "timesheet_periods")
        let localIds = Set(timesheets.map { $0.id.uuidString })
        for id in remoteIds.subtracting(localIds) {
            _ = await supabaseDelete(table: "timesheet_periods", filter: "id=eq.\(id)")
        }

        for ts in timesheets {
            let body: [String: Any] = [
                "id": ts.id.uuidString,
                "user_id": userId,
                "nom": ts.nom,
                "mois": ts.mois,
                "annee": ts.annee,
                "taux_normal": NSDecimalNumber(decimal: ts.tauxNormal).doubleValue,
                "taux_supplementaire": NSDecimalNumber(decimal: ts.tauxSupplementaire).doubleValue,
                "coefficient_net": NSDecimalNumber(decimal: ts.coefficientNet).doubleValue,
                "seuil_hebdo": NSDecimalNumber(decimal: ts.seuilHebdo).doubleValue,
                "created_at": ISO8601DateFormatter().string(from: ts.createdAt),
                "updated_at": ISO8601DateFormatter().string(from: ts.updatedAt),
            ]
            guard await supabaseUpsert(table: "timesheet_periods", body: body, onConflict: "id") else { return false }

            // Delete all weeks (cascade deletes days) + reinsert
            _ = await supabaseDelete(table: "timesheet_weeks", filter: "period_id=eq.\(ts.id.uuidString)")

            for week in ts.semaines {
                let weekBody: [String: Any] = [
                    "id": week.id.uuidString,
                    "user_id": userId,
                    "period_id": ts.id.uuidString,
                    "numero": week.numero,
                ]
                guard await supabaseUpsert(table: "timesheet_weeks", body: weekBody, onConflict: "id") else { return false }

                if !week.jours.isEmpty {
                    let days: [[String: Any]] = week.jours.map { day in
                        [
                            "id": day.id.uuidString,
                            "user_id": userId,
                            "week_id": week.id.uuidString,
                            "date_string": day.dateString,
                            "heures": NSDecimalNumber(decimal: day.heures).doubleValue,
                        ]
                    }
                    guard await supabaseBatchInsert(table: "timesheet_days", rows: days) else { return false }
                }
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
            doc.dateCreation = parseDate(json["date_creation"]) ?? Date()
            doc.dateEcheance = parseDate(json["date_echeance"]) ?? Date()
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
            doc.createdAt = parseDate(json["created_at"]) ?? Date()
            doc.updatedAt = parseDate(json["updated_at"]) ?? Date()

            // Parse line_items
            if let lineItemsJson = json["line_items"] as? [[String: Any]] {
                doc.lignes = lineItemsJson.compactMap { li in
                    guard let liId = (li["id"] as? String).flatMap({ UUID(uuidString: $0) }) else { return nil }
                    return LineItem(
                        designation: li["designation"] as? String ?? "",
                        quantite: Decimal(li["quantite"] as? Double ?? 0),
                        prixUnitaire: Decimal(li["prix_unitaire"] as? Double ?? 0),
                        tauxTVA: Decimal(li["taux_tva"] as? Double ?? 0),
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
                        date: parseDate(sig["date"]) ?? Date(),
                        montant: Decimal(sig["montant"] as? Double ?? 0),
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
            client.createdAt = parseDate(json["created_at"]) ?? Date()
            client.updatedAt = parseDate(json["updated_at"]) ?? Date()
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
        company.tauxTVAParDefaut = Decimal(json["taux_tva_par_defaut"] as? Double ?? 0)
        company.delaiPaiementJours = json["delai_paiement_jours"] as? Int ?? 30
        company.deviseParDefautRawValue = json["devise_par_defaut_raw_value"] as? String ?? "USDC"
        let blockRaw = json["blockchain_par_defaut_raw_value"] as? String ?? ""
        company.blockchainParDefautRawValue = blockRaw.isEmpty ? nil : blockRaw
        company.updatedAt = parseDate(json["updated_at"]) ?? Date()

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
                    prixUnitaire: Decimal(p["prix_unitaire"] as? Double ?? 0),
                    tauxTVA: Decimal(p["taux_tva"] as? Double ?? 0)
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
            period.tauxNormal = Decimal(json["taux_normal"] as? Double ?? 26.39)
            period.tauxSupplementaire = Decimal(json["taux_supplementaire"] as? Double ?? 39.59)
            period.coefficientNet = Decimal(json["coefficient_net"] as? Double ?? 0.756)
            period.seuilHebdo = Decimal(json["seuil_hebdo"] as? Double ?? 35)
            period.createdAt = parseDate(json["created_at"]) ?? Date()
            period.updatedAt = parseDate(json["updated_at"]) ?? Date()

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
                            var day = TimesheetDay(date: date, heures: Decimal(d["heures"] as? Double ?? 0))
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

    func fullSync(dataStore: DataStore) async {
        guard SyncConfig.isEnabled, SyncConfig.isConfigured,
              authService?.isAuthenticated == true else { return }

        isSyncing = true

        // Push local changes first
        await pushAllDirty()

        // Pull remote data
        if let docs = await pullDocuments() {
            dataStore.documents = docs
            dataStore.saveLocal(key: "documents")
        }
        if let clients = await pullClients() {
            dataStore.clients = clients
            dataStore.saveLocal(key: "clients")
        }
        if let company = await pullCompany() {
            dataStore.companyInfo = company
            dataStore.saveLocal(key: "company")
        }
        if let timesheets = await pullTimesheets() {
            dataStore.timesheets = timesheets
            dataStore.saveLocal(key: "timesheets")
        }

        syncState.lastFullSyncAt = Date()
        lastSyncDate = Date()
        isSyncing = false
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

    private func supabaseDelete(table: String, filter: String) async -> Bool {
        guard let url = buildURL(path: "/rest/v1/\(table)?\(filter)") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        addHeaders(&request, token: authService?.accessToken)

        return await executeRequest(request)
    }

    private func supabaseGet(table: String, query: String) async -> [[String: Any]]? {
        guard let url = buildURL(path: "/rest/v1/\(table)?\(query)") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addHeaders(&request, token: authService?.accessToken)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                if let httpResponse = response as? HTTPURLResponse,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
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

    private func fetchRemoteIds(table: String) async -> Set<String> {
        guard let url = buildURL(path: "/rest/v1/\(table)?select=id") else { return [] }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addHeaders(&request, token: authService?.accessToken)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode >= 200 && httpResponse.statusCode < 300,
                  let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            else { return [] }
            return Set(jsonArray.compactMap { $0["id"] as? String })
        } catch {
            return []
        }
    }

    private func executeRequest(_ request: URLRequest) async -> Bool {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    return true
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

    private func parseDate(_ value: Any?) -> Date? {
        guard let str = value as? String else { return nil }
        return ISO8601DateFormatter().date(from: str)
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

    CREATE POLICY "own_data" ON documents FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "own_data" ON line_items FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "own_data" ON transaction_signatures FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "own_data" ON clients FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "own_data" ON company_info FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "own_data" ON wallets FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "own_data" ON prestation_presets FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "own_data" ON timesheet_periods FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "own_data" ON timesheet_weeks FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "own_data" ON timesheet_days FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

    -- Index sur les cles etrangeres
    CREATE INDEX idx_line_items_document ON line_items(document_id);
    CREATE INDEX idx_tx_sigs_document ON transaction_signatures(document_id);
    CREATE INDEX idx_wallets_company ON wallets(company_id);
    CREATE INDEX idx_presets_company ON prestation_presets(company_id);
    CREATE INDEX idx_weeks_period ON timesheet_weeks(period_id);
    CREATE INDEX idx_days_week ON timesheet_days(week_id);
    """
}
