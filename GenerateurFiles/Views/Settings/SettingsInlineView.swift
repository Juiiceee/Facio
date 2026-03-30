import SwiftUI

/// Vue parametres integree dans la fenetre principale (pas une fenetre separee)
struct SettingsInlineView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Parametres")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 10)

            // Tab picker
            Picker("", selection: $selectedTab) {
                Label("Entreprise", systemImage: "building.2").tag(0)
                Label("Paiement", systemImage: "creditcard").tag(1)
                Label("Valeurs par defaut", systemImage: "slider.horizontal.3").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            Divider()

            // Content
            ScrollView {
                switch selectedTab {
                case 0:
                    CompanySettingsView()
                case 1:
                    PaymentSettingsView()
                case 2:
                    DefaultsSettingsView()
                default:
                    EmptyView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
