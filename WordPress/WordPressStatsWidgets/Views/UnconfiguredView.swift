import SwiftUI

struct UnconfiguredView: View {

    let message: LocalizedStringKey

    var body: some View {
        Text(message)
            .font(.footnote)
            .foregroundColor(Color(.secondaryLabel))
            .multilineTextAlignment(.center)
            .padding()
    }

    static let unconfiguredMessage = LocalizableStrings.unconfiguredViewTitle
}

struct PlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        UnconfiguredView(message: LocalizableStrings.unconfiguredViewTitle)
    }
}
