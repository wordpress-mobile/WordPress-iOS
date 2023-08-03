import SwiftUI

struct DashboardGoogleDomainsCardView: View {
    var body: some View {
        VStack(spacing: Length.Padding.double) {
            contentTitleHStack
            Text(Strings.contentDescription)
                .foregroundColor(.gray)
                .font(.callout)
            transferDomainsButton
        }
        .padding()
    }

    private var contentTitleHStack: some View {
        HStack(spacing: Length.Padding.double) {
            Image("wp-domains-icon")
            Text(Strings.contentTitle)
                .font(.headline)
            Spacer()
        }
    }

    private var transferDomainsButton: some View {
        HStack {
            Button {
                print("Transfer your domains tapped")
            } label: {
                Text(Strings.buttonTitle)
                    .foregroundColor(Color(UIColor.primary))
                    .font(.callout)
            }
            Spacer()
        }
    }
}

private extension DashboardGoogleDomainsCardView {
    enum Strings {

        static let contentTitle = NSLocalizedString(
            "mySite.domain.focus.card.title",
            value: "Move your Google Domains to WordPress.com",
            comment: "Title of the domain focus card on My Site"
        )

        static let contentDescription = NSLocalizedString(
            "mySite.domain.focus.card.description",
            value: "Bring your Google domains to WordPress.com, and we'll cover the transfer fees and throw in an extra year of registration on us.",
            comment: "Description of the domain focus card on My Site"
        )

        static let buttonTitle = NSLocalizedString(
            "mySite.domain.focus.card.button.title",
            value: "Transfer your domains",
            comment: "Button title of the domain focus card on My Site"
        )
    }
}
