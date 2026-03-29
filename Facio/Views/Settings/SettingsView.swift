import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            CompanySettingsView()
                .tabItem {
                    Label("Entreprise", systemImage: "building.2")
                }

            PaymentSettingsView()
                .tabItem {
                    Label("Paiement", systemImage: "creditcard")
                }

            DefaultsSettingsView()
                .tabItem {
                    Label("Valeurs par defaut", systemImage: "slider.horizontal.3")
                }
        }
        .frame(width: 500, height: 480)
    }
}
