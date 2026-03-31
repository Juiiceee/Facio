import SwiftUI

struct CompanySettingsView: View {
    @Environment(DataStore.self) private var dataStore

    private var company: CompanyInfo {
        dataStore.companyInfo
    }

    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Identite
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Identite", systemImage: "building.2")
                        .font(.headline)

                    settingsRow("Nom") {
                        TextField("Nom de l'entreprise", text: Binding(
                            get: { company.nom },
                            set: { company.nom = $0; dataStore.save() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    settingsRow("Adresse") {
                        TextField("Adresse postale", text: Binding(
                            get: { company.adresse },
                            set: { company.adresse = $0; dataStore.save() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    HStack(spacing: 12) {
                        settingsRow("Code postal") {
                            TextField("54000", text: Binding(
                                get: { company.codePostal },
                                set: { company.codePostal = $0; dataStore.save() }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 120)
                        }

                        settingsRow("Ville") {
                            TextField("Ville", text: Binding(
                                get: { company.ville },
                                set: { company.ville = $0; dataStore.save() }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                    }

                    settingsRow("SIRET") {
                        TextField("000 000 000 00000", text: Binding(
                            get: { company.siret },
                            set: { company.siret = $0; dataStore.save() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(12)
            }

            // MARK: - Contact
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Contact", systemImage: "phone")
                        .font(.headline)

                    settingsRow("Telephone") {
                        TextField("06 00 00 00 00", text: Binding(
                            get: { company.telephone },
                            set: { company.telephone = $0; dataStore.save() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    settingsRow("Email") {
                        TextField("contact@entreprise.fr", text: Binding(
                            get: { company.email },
                            set: { company.email = $0; dataStore.save() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(12)
            }

            // MARK: - Logo
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Logo", systemImage: "photo")
                        .font(.headline)

                    if let logoData = company.logoData,
                       let nsImage = NSImage(data: logoData) {
                        HStack(spacing: 16) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 100, maxHeight: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 8) {
                                Button("Choisir un autre fichier...") {
                                    pickLogoFile()
                                }
                                Button("Supprimer le logo", role: .destructive) {
                                    company.logoData = nil
                                    dataStore.save()
                                }
                                .foregroundStyle(.red)
                            }
                        }
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                .foregroundStyle(isDropTargeted ? .blue : .secondary.opacity(0.5))
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

                        Button("Choisir un fichier...") {
                            pickLogoFile()
                        }
                    }
                }
                .padding(12)
            }

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Helpers

    /// Ligne label + champ alignee
    private func settingsRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            content()
        }
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
