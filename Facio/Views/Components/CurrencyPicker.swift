import SwiftUI

struct CurrencyPicker: View {
    @Binding var selection: CurrencyType

    var body: some View {
        Picker("Devise", selection: $selection) {
            ForEach(CurrencyType.allCases) { currency in
                Text("\(currency.label) (\(currency.symbole))")
                    .tag(currency)
            }
        }
        .frame(maxWidth: 200)
    }
}
