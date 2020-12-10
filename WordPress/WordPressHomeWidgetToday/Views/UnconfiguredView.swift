import SwiftUI

struct UnconfiguredView: View {
    var body: some View {
        Text(Self.unconfiguredMessage)
            .font(.footnote)
            .foregroundColor(Color(.secondaryLabel))
            .multilineTextAlignment(.center)
            .padding()
    }
    // TODO - TODAYWIDGET: may need review
    static let unconfiguredMessage: LocalizedStringKey = "Log in to WordPress to see today's stats."
}

struct PlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        UnconfiguredView()
    }
}
