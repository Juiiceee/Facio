import SwiftUI

struct CurrencyPicker: View {
    @Binding var selection: CurrencyType
    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        Picker(L10n.currency(lang), selection: $selection) {
            ForEach(CurrencyType.allCases) { currency in
                Text("\(currency.label) (\(currency.symbole))")
                    .tag(currency)
            }
        }
        .frame(maxWidth: 200)
    }
}
