import SwiftUI

struct UnconfiguredView: View {
    var body: some View {
        Text(Self.unconfiguredMessage)
            .font(.footnote)
            .foregroundColor(Color(.secondaryLabel))
            .multilineTextAlignment(.center)
            .padding()
    }

    static let unconfiguredMessage = LocalizedStringKey("widget.today.unconfigured.view.title", defaultValue: "Log in to WordPress to see today's stats.", comment: "Title of the unconfigured view in today widget")
}

struct PlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        UnconfiguredView()
    }
}
