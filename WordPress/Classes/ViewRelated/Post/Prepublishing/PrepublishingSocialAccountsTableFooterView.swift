import SwiftUI

class PrepublishingSocialAccountsTableFooterView: UITableViewHeaderFooterView, Reusable {

    init(remaining: Int,
         showsWarning: Bool,
         onButtonTap: (() -> Void)?,
         reuseIdentifier: String? = PrepublishingSocialAccountsTableFooterView.defaultReuseID) {
        super.init(reuseIdentifier: reuseIdentifier)

        let footerView = PrepublishingSocialAccountsFooterView(remaining: remaining,
                                                               showsWarning: showsWarning,
                                                               onButtonTap: onButtonTap)
        let viewToEmbed = UIView.embedSwiftUIView(footerView)
        contentView.addSubview(viewToEmbed)
        contentView.pinSubviewToAllEdges(viewToEmbed)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - SwiftUI View

struct PrepublishingSocialAccountsFooterView: View {

    @State var remaining: Int
    @State var showsWarning: Bool
    var onButtonTap: (() -> Void)?

    var body: some View {
        VStack(spacing: 16.0) {
            remainingSharesText
            subscribeButton
        }
        .padding(EdgeInsets(top: 24.0, leading: 0, bottom: 0, trailing: 0))
    }

    var remainingSharesText: some View {
        HStack(alignment: .top, spacing: 6.0) {
            if showsWarning {
                Image("icon-warning")
                    .resizable()
                    .frame(width: 16.0, height: 16.0)
                    .padding(2.0)
                    .accessibilityElement()
                    .accessibilityLabel(Constants.warningIconAccessibilityText)
            }
            Text(String(format: Constants.remainingSharesLabelTextFormat, remaining))
                .font(.callout)
                .foregroundColor(Color(showsWarning ? Constants.warningColor : .label))
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }

    var subscribeButton: some View {
        Button {
            onButtonTap?()
        } label: {
            Text(Constants.subscribeButtonText)
                .padding(12.0)
                .frame(maxWidth: .infinity) // needs to be set here to make the button stretch full-width.
        }
        .buttonStyle(SubscribeButtonStyle())
    }

    private struct SubscribeButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Constants.buttonLabelFont)
                .foregroundColor(.white)
                .background(Color(configuration.isPressed ? Constants.buttonHighlightedColor : Constants.buttonColor))
                .clipShape(RoundedRectangle(cornerRadius: 8.0))
        }
    }

    private enum Constants {
        static let buttonLabelFont = Font(WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold))
        static let buttonColor = UIColor.primary
        static let buttonHighlightedColor = UIColor.muriel(color: .jetpackGreen, .shade70)
        static let warningColor = UIColor.muriel(color: MurielColor(name: .yellow, shade: .shade50))

        static let remainingSharesLabelTextFormat = NSLocalizedString(
            "prepublishing.socialAccounts.footer.remainingShares.text",
            value: "%1$d social shares remaining in the next 30 days",
            comment: """
                Text shown below the list of social accounts to indicate how many social shares available for the site.
                Note that the '30 days' part is intended to be a static value.
                %1$d is a placeholder for the amount of remaining shares.
                Example: 27 social shares remaining in the next 30 days
                """
        )

        static let subscribeButtonText = NSLocalizedString(
            "prepublishing.socialAccounts.footer.button.text",
            value: "Subscribe to share more",
            comment: "The label for a call-to-action button in the social accounts' footer section."
        )

        static let warningIconAccessibilityText = NSLocalizedString(
            "prepublishing.socialAccounts.footer.warningIcon.accessibilityHint",
            value: "Warning",
            comment: "a VoiceOver description for the warning icon to hint that the remaining shares are low."
        )
    }
}
