import SwiftUI
import DesignSystem

struct DashboardGoogleDomainsCardView: View {
    private var buttonAction: () -> ()

    init(buttonAction: @escaping () -> ()) {
        self.buttonAction = buttonAction
    }

    var body: some View {
        VStack(spacing: Length.Padding.double) {
            titleHStack
            descriptionHStack
            transferDomainsButton
        }
        .padding([.leading, .trailing, .bottom], Length.Padding.double)
        .onAppear {
            WPAnalytics.track(.domainTransferShown)
        }
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
                buttonAction()
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
            "mySite.domain.focus.cardView.title",
            value: "Reclaim your Google Domains",
            comment: "Title of the domain focus card on My Site"
        )

        static let contentDescription = NSLocalizedString(
            "mySite.domain.focus.cardView.description",
            value: "As you may know, Google Domains has been sold to Squarespace. Transfer your domains to WordPress.com now, and we'll pay all transfer fees plus an extra year of your domain registration.",
            comment: "Description of the domain focus card on My Site"
        )

        static let buttonTitle = NSLocalizedString(
            "mySite.domain.focus.cardView.button.title",
            value: "Transfer your domains",
            comment: "Button title of the domain focus card on My Site"
        )
    }
}
