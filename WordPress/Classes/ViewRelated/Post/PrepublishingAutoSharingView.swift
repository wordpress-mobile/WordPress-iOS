import SwiftUI

struct PrepublishingAutoSharingView: View {

    // TODO: view model.

    var body: some View {
        HStack {
            textStack
            Spacer()
            iconTrain
        }
    }

    var textStack: some View {
        VStack(alignment: .leading) {
            Text(String(format: Strings.primaryLabelActiveConnectionsFormat, 3))
                .font(.body)
                .foregroundColor(Color(.label))
            Text(String(format: Strings.remainingSharesTextFormat, 27, 30))
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
        }
    }

    // TODO: This will be implemented separately.
    var iconTrain: some View {
        HStack {
            if let uiImage = UIImage(named: "icon-tumblr") {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 32.0, height: 32.0)
                    .background(Color(UIColor.listForeground))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(UIColor.listForeground), lineWidth: 2.0))
            }
        }
    }
}

// MARK: - Helpers

private extension PrepublishingAutoSharingView {

    enum Strings {
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
