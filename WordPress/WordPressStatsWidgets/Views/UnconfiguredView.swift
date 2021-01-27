import SwiftUI

struct UnconfiguredView: View {
    var body: some View {
        Text(Self.unconfiguredMessage)
            .font(.footnote)
            .foregroundColor(Color(.secondaryLabel))
            .multilineTextAlignment(.center)
            .padding()
    }

    static let unconfiguredMessage = LocalizableStrings.unconfiguredViewTitle
}

struct PlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        UnconfiguredView()
    }
}
