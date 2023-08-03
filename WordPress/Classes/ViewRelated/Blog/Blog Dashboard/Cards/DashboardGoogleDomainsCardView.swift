import SwiftUI

struct DashboardGoogleDomainsCardView: View {
    var body: some View {
        VStack(spacing: Length.Padding.double) {
            titleHStack
            descriptionHStack
            transferDomainsButton
        }
        .padding([.leading, .trailing, .bottom], Length.Padding.double)
    }

    private var titleHStack: some View {
        HStack(spacing: Length.Padding.double) {
            Image("wp-domains-icon")
            Text(Strings.contentTitle)
                .font(.headline)
            Spacer()
        }
    }

    private var descriptionHStack: some View {
        HStack(spacing: 0) {
            Text(Strings.contentDescription)
                .foregroundColor(.gray)
                .font(.callout)
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
            value: "Reclaim your Google Domains",
            comment: "Title of the domain focus card on My Site"
        )

        static let contentDescription = NSLocalizedString(
            "mySite.domain.focus.card.description",
            value: "As you may know, Google Domains has been sold to Squarespace. Transfer your domains to WordPress.com now, and we'll pay all transfer fees plus an extra year of your domain registration.",
            comment: "Description of the domain focus card on My Site"
        )

        static let buttonTitle = NSLocalizedString(
            "mySite.domain.focus.card.button.title",
            value: "Transfer your domains",
            comment: "Button title of the domain focus card on My Site"
        )
    }
}
