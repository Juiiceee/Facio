import SwiftUI

struct ClientPickerSheet: View {
    let clients: [ClientInfo]
    let onSelect: (ClientInfo) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @State private var searchText = ""
    @State private var showNewClient = false
    @State private var newNom = ""
    @State private var newAdresse = ""
    @State private var newCodePostal = ""
    @State private var newVille = ""
    @State private var newEmail = ""

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var allClients: [ClientInfo] {
        dataStore.clients.sorted { $0.nom < $1.nom }
    }

    private var filteredClients: [ClientInfo] {
        guard !searchText.isEmpty else { return allClients }
        let query = searchText.lowercased()
        return allClients.filter {
            $0.nom.lowercased().contains(query) ||
            $0.ville.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            newClientForm
            clientList
        }
        .frame(minWidth: 450, minHeight: 400)
    }

    private var toolbar: some View {
        HStack {
            Text(L10n.selectClient(lang))
                .font(.headline)
            Spacer()
            Button {
                showNewClient.toggle()
            } label: {
                Label(L10n.new(lang), systemImage: "plus")
            }
            Button(L10n.close(lang)) { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding()
    }

    @ViewBuilder
    private var newClientForm: some View {
        if showNewClient {
            GroupBox(L10n.newClient(lang)) {
                VStack(spacing: 8) {
                    TextField(L10n.name(lang), text: $newNom)
                        .textFieldStyle(.roundedBorder)
                    TextField(L10n.address(lang), text: $newAdresse)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        TextField(L10n.postalCode(lang), text: $newCodePostal)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 120)
                        TextField(L10n.city(lang), text: $newVille)
                            .textFieldStyle(.roundedBorder)
                    }
                    TextField(L10n.email(lang), text: $newEmail)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        Spacer()
                        Button(L10n.createAndSelect(lang)) {
                            let client = ClientInfo(
                                nom: newNom,
                                adresse: newAdresse,
                                codePostal: newCodePostal,
                                ville: newVille,
                                email: newEmail
                            )
                            dataStore.addClient(client)
                            onSelect(client)
                        }
                        .disabled(newNom.isEmpty)
                    }
                }
                .padding(4)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private var clientList: some View {
        List(filteredClients) { client in
            Button {
                onSelect(client)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(client.nom)
                        .font(.body)
                    if !client.ville.isEmpty {
                        Text("\(client.adresse.isEmpty ? "" : "\(client.adresse), ")\(client.codePostal) \(client.ville)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .searchable(text: $searchText, prompt: L10n.searchClient(lang))
    }
}
