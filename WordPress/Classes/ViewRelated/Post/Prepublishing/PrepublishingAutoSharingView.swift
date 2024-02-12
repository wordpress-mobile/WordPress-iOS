import SwiftUI

struct PrepublishingAutoSharingView: View {

    let model: PrepublishingAutoSharingModel

    @Environment(\.sizeCategory) private var sizeCategory

    @ScaledMetric(relativeTo: .subheadline) private var warningIconLength = 16.0

    @ScaledMetric(relativeTo: .body) private var imageLength = 28.0

    var body: some View {
        Group {
            if shouldStackContentVertically {
                VStack(alignment: .leading, spacing: 8.0) { content }
            } else {
                HStack { content }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private var content: some View {
        Group {
            textStack
            if model.services.count > 0 {
                if !shouldStackContentVertically {
                    Spacer(minLength: .zero) // to push the icons to the trailing side in horizontal layout.
                }
                socialIconsView
            }
        }
    }

    private var textStack: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(model.labelText)
                .font(.body)
                .foregroundColor(Color(.label))
            if let text = model.remainingSharesText {
                remainingSharesLabel(text: text, showsWarning: model.showsWarning)
            }
        }
    }

    @ViewBuilder
    private func remainingSharesLabel(text: String, showsWarning: Bool) -> some View {
        Label {
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color(showsWarning ? Constants.warningColor : .secondaryLabel))
        } icon: {
            if showsWarning {
                Image("icon-warning")
                    .resizable()
                    .frame(width: warningIconLength, height: warningIconLength)
                    .accessibilityElement()
                    .accessibilityLabel(Constants.warningIconAccessibilityText)
            }
        }
        .accessibilityLabel(showsWarning ? "\(Constants.warningIconAccessibilityText), \(text)" : text)
    }

    private var socialIconsView: some View {
        HStack(spacing: -2.0) {
            ForEach(model.services, id: \.self) { service in
                iconImage(service.name.localIconImage, opaque: service.usesOpaqueIcon)
            }
        }
    }

    private func iconImage(_ uiImage: UIImage, opaque: Bool) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .frame(width: imageLength, height: imageLength)
            .opacity(opaque ? 1.0 : Constants.disabledSocialIconOpacity)
            .background(Color(.listForeground))
            .clipShape(Circle())
    }
}

// MARK: - View Helpers

private extension PrepublishingAutoSharingView {

    var shouldStackContentVertically: Bool {
        (model.services.count > Constants.maxServicesForHorizontalLayout) || sizeCategory.isAccessibilityCategory
    }

    enum Constants {
        static let maxServicesForHorizontalLayout = 3
        static let disabledSocialIconOpacity: CGFloat = 0.36
        static let warningColor = UIColor.muriel(color: MurielColor(name: .yellow, shade: .shade50))

        static let warningIconAccessibilityText = NSLocalizedString(
            "prepublishing.social.warningIcon.accessibilityHint",
            value: "Warning",
            comment: "a VoiceOver description for the warning icon to hint that the remaining shares are low."
        )
    }
}

// MARK: - PrepublishingAutoSharingModel Private Extensions

private extension PrepublishingAutoSharingModel.Service {
    /// Whether the icon for this service should be opaque or transparent.
    /// If at least one account is enabled, an opaque version should be shown.
    var usesOpaqueIcon: Bool {
        connections.reduce(false) { partialResult, connection in
            return partialResult || connection.enabled
        }
    }

    var enabledConnections: [PrepublishingAutoSharingModel.Connection] {
        connections.filter { $0.enabled }
    }
}

private extension PrepublishingAutoSharingModel {
    var enabledConnectionsCount: Int {
        services.reduce(0) { $0 + $1.enabledConnections.count }
    }

    var totalConnectionsCount: Int {
        services.reduce(0) { $0 + $1.connections.count }
    }

    var showsWarning: Bool {
        guard let remaining = sharingLimit?.remaining else {
            return false
        }
        return totalConnectionsCount > remaining
    }

    var labelText: String {
        switch (enabledConnectionsCount, totalConnectionsCount) {
        case (let enabled, _) where enabled == 0:
            // not sharing to any social media
            return Strings.notSharingText

        case (let enabled, let total) where enabled == total && total == 1:
            // sharing to the one and only connection
            guard let account = services.first?.connections.first?.account else {
                return String()
            }
            return String(format: Strings.singleConnectionTextFormat, account)

        case (let enabled, let total) where enabled == total && total > 1:
            // sharing to all connections
            return String(format: Strings.multipleConnectionsTextFormat, enabled)

        case (let enabled, let total) where enabled < total && total > 1:
            // sharing to some connections
            return String(format: Strings.partialConnectionsTextFormat, enabled, total)

        default:
            return String()
        }
    }

    var remainingSharesText: String? {
        guard let remaining = sharingLimit?.remaining else {
            return nil
        }

        return String(format: Strings.remainingSharesTextFormat, remaining)
    }

    enum Strings {
        static let notSharingText = NSLocalizedString(
            "prepublishing.social.label.notSharing",
            value: "Not sharing to social",
            comment: """
                The primary label for the auto-sharing row on the pre-publishing sheet.
                Indicates the blog post will not be shared to any social accounts.
                """
        )

        static let singleConnectionTextFormat = NSLocalizedString(
            "prepublishing.social.label.singleConnection",
            value: "Sharing to %1$@",
            comment: """
                The primary label for the auto-sharing row on the pre-publishing sheet.
                Indicates the blog post will be shared to a social media account.
                %1$@ is a placeholder for the account name.
                Example: Sharing to @wordpress
                """
        )

        static let multipleConnectionsTextFormat = NSLocalizedString(
            "prepublishing.social.label.multipleConnections",
            value: "Sharing to %1$d accounts",
            comment: """
                The primary label for the auto-sharing row on the pre-publishing sheet.
                Indicates the number of social accounts that will be sharing the blog post.
                %1$d is a placeholder for the number of social network accounts that will be auto-shared.
                Example: Sharing to 3 accounts
                """
        )

        static let partialConnectionsTextFormat = NSLocalizedString(
            "prepublishing.social.label.partialConnections",
            value: "Sharing to %1$d of %2$d accounts",
            comment: """
                The primary label for the auto-sharing row on the pre-publishing sheet.
                Indicates the number of social accounts that will be sharing the blog post.
                This string is displayed when some of the social accounts are turned off for auto-sharing.
                %1$d is a placeholder for the number of social media accounts that will be sharing the blog post.
                %2$d is a placeholder for the total number of social media accounts connected to the user's blog.
                Example: Sharing to 2 of 3 accounts
                """
        )

        static let remainingSharesTextFormat = NSLocalizedString(
            "prepublishing.social.remainingShares.format",
            value: "%1$d social shares remaining",
            comment: """
                A subtext that's shown below the primary label in the auto-sharing row on the pre-publishing sheet.
                Informs the remaining limit for post auto-sharing.
                %1$d is a placeholder for the remaining shares.
                Example: 27 social shares remaining
                """
        )
    }
}
