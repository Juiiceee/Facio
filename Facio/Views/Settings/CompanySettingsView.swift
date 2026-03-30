import SwiftUI

struct CompanySettingsView: View {
    @Environment(DataStore.self) private var dataStore

    private var company: CompanyInfo {
        dataStore.companyInfo
    }

    @State private var isDropTargeted = false

    var body: some View {
        Form {
            Section("Identite") {
                TextField("Nom", text: Binding(
                    get: { company.nom },
                    set: { company.nom = $0; dataStore.save() }
                ))
                TextField("Adresse", text: Binding(
                    get: { company.adresse },
                    set: { company.adresse = $0; dataStore.save() }
                ))
                HStack {
                    TextField("Code postal", text: Binding(
                        get: { company.codePostal },
                        set: { company.codePostal = $0; dataStore.save() }
                    ))
                    .frame(width: 120)
                    TextField("Ville", text: Binding(
                        get: { company.ville },
                        set: { company.ville = $0; dataStore.save() }
                    ))
                }
                TextField("SIRET", text: Binding(
                    get: { company.siret },
                    set: { company.siret = $0; dataStore.save() }
                ))
            }

            Section("Contact") {
                TextField("Telephone", text: Binding(
                    get: { company.telephone },
                    set: { company.telephone = $0; dataStore.save() }
                ))
                TextField("Email", text: Binding(
                    get: { company.email },
                    set: { company.email = $0; dataStore.save() }
                ))
            }

            Section("Logo") {
                VStack(spacing: 12) {
                    if let logoData = company.logoData,
                       let nsImage = NSImage(data: logoData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 80)
                            .cornerRadius(8)

                        Button("Supprimer le logo", role: .destructive) {
                            company.logoData = nil
                            dataStore.save()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.red)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                .foregroundStyle(isDropTargeted ? .blue : .secondary)
                                .frame(height: 80)

                            VStack(spacing: 4) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                Text("Glissez une image ici")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                            handleDrop(providers: providers)
                        }
                    }

                    Button("Choisir un fichier...") {
                        pickLogoFile()
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
    }

    private func pickLogoFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? Data(contentsOf: url) {
                company.logoData = data
                dataStore.save()
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  let imageData = try? Data(contentsOf: url),
                  NSImage(data: imageData) != nil else { return }

            DispatchQueue.main.async {
                company.logoData = imageData
                dataStore.save()
            }
        }
        return true
    }
}
