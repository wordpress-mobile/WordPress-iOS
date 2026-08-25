import SwiftUI
import WordPressData
import WordPressUI

/// SwiftUI port of `LikeUserTableViewCell`: a 46pt circular avatar, the display name,
/// the `@username`, and a hairline bottom divider. Used in both the compact (single
/// column) and regular (multi-column) layouts of ``LikesListView``.
struct LikeUserRowView: View {
    let user: LikeUser

    /// Whether to draw the hairline bottom divider. The multi-column grid layout hides it
    /// so cells don't carry stray separators; the single-column layout keeps it to match
    /// the table it replaces.
    var showsDivider = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Metrics.avatarSpacing) {
                // The avatar sizes itself (it scales with Dynamic Type via an internal
                // @ScaledMetric), so it must not be pinned to a fixed frame here or it
                // would overflow and overlap the text at large accessibility sizes.
                AvatarView(
                    style: .single(URL(string: user.avatarUrl)),
                    diameter: Metrics.avatarDiameter,
                    placeholderImage: Image("gravatar").resizable()
                )
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Metrics.labelSpacing) {
                    Text(user.displayName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(String(format: Strings.usernameFormat, user.username))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.vertical, Metrics.verticalPadding)

            if showsDivider {
                Divider()
                    .padding(.leading, Metrics.horizontalPadding)
            }
        }
    }

    private enum Metrics {
        static let avatarDiameter: CGFloat = 46
        static let avatarSpacing: CGFloat = 12
        static let labelSpacing: CGFloat = 2
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 12
    }

    private enum Strings {
        static let usernameFormat = NSLocalizedString(
            "@%1$@",
            comment:
                "Label displaying the user's username preceded by an '@' symbol. %1$@ is a placeholder for the username."
        )
    }
}
