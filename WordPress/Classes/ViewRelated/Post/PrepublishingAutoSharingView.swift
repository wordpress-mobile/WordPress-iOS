import SwiftUI

struct PrepublishingAutoSharingView: View {

    let model: PrepublishingAutoSharingViewModel

    var body: some View {
        HStack {
            textStack
            Spacer()
            if model.connections.count > 0 {
                socialIconsView
            }
        }
    }

    private var textStack: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(String(format: Constants.primaryLabelActiveConnectionsFormat, 3))
                .font(.body)
                .foregroundColor(Color(.label))
            if let sharingLimit = model.sharingLimit {
                remainingSharesView(sharingLimit: sharingLimit, showsWarning: model.showsWarning)
            }
        }
    }

    private func remainingSharesView(sharingLimit: PublicizeInfo.SharingLimit, showsWarning: Bool) -> some View {
        HStack(spacing: 4.0) {
            if showsWarning {
                Image("icon-warning")
                    .resizable()
                    .frame(width: 16.0, height: 16.0)
                    .padding(4.0)
            }
            Text(String(format: Constants.remainingSharesTextFormat, sharingLimit.remaining, sharingLimit.limit))
                .font(.subheadline)
                .foregroundColor(Color(showsWarning ? Constants.warningColor : .secondaryLabel))
        }
    }

    private var socialIconsView: some View {
        HStack(spacing: -2.0) {
            ForEach(model.connections, id: \.self) { connection in
                iconImage(connection.serviceName.localIconImage, opaque: connection.enabled)
            }
        }
    }

    private func iconImage(_ uiImage: UIImage, opaque: Bool) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .frame(width: 28.0, height: 28.0)
            .opacity(opaque ? 1.0 : Constants.disabledSocialIconOpacity)
            .background(Color(.listForeground))
            .clipShape(Circle())
    }
}

// MARK: - View Helpers

private extension PrepublishingAutoSharingView {

    enum Constants {
        static let disabledSocialIconOpacity: CGFloat = 0.36
        static let warningColor = UIColor.muriel(color: MurielColor(name: .yellow, shade: .shade50))

        static let primaryLabelActiveConnectionsFormat = NSLocalizedString(
            "prepublishing.social.text.activeConnections",
            value: "Sharing to %1$d accounts",
            comment: """
                The primary label for the auto-sharing row on the pre-publishing sheet.
                Indicates the number of social accounts that will be auto-sharing the blog post.
                %1$d is a placeholder for the number of social network accounts that will be auto-shared.
                Example: Sharing to 3 accounts
                """
        )

        // TODO: More text variations.

        static let remainingSharesTextFormat = NSLocalizedString(
            "prepublishing.social.remainingShares",
            value: "%1$d/%2$d social shares remaining",
            comment: """
                A subtext that's shown below the primary label in the auto-sharing row on the pre-publishing sheet.
                Informs the remaining limit for post auto-sharing.
                %1$d is a placeholder for the remaining shares.
                %2$d is a placeholder for the maximum shares allowed for the user's blog.
                Example: 27/30 social shares remaining
                """
        )
    }
}

// MARK: - View Model

/// The value-type data model that drives the `PrepublishingAutoSharingView`.
struct PrepublishingAutoSharingViewModel {

    struct Connection: Hashable {
        let serviceName: PublicizeService.ServiceName
        let account: String
        let enabled: Bool
    }

    // TODO: Default values are for temporary testing purposes. Will be removed later.
    let connections: [Connection] = [.init(serviceName: .facebook, account: "foo", enabled: true),
                                     .init(serviceName: .twitter, account: "bar", enabled: false),
                                     .init(serviceName: .tumblr, account: "baz", enabled: true)]

    // TODO: Default values are for temporary testing purposes. Will be removed later.
    let sharingLimit: PublicizeInfo.SharingLimit? = .init(remaining: 1, limit: 30)

    var enabledConnectionsCount: Int {
        connections.filter({ $0.enabled }).count
    }

    var showsWarning: Bool {
        guard let remaining = sharingLimit?.remaining else {
            return false
        }
        return enabledConnectionsCount > remaining
    }
}
