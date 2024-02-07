import SwiftUI
import DesignSystem

extension NotificationsTableViewCell {
    struct Content: View {
        private let title: String
        private let description: String?
        private let shouldShowIndicator: Bool
        private let avatarStyle: AvatarsView.Style

        init(
            title: String,
            description: String?,
            shouldShowIndicator: Bool,
            avatarStyle: AvatarsView.Style
        ) {
            self.title = title
            self.description = description
            self.shouldShowIndicator = shouldShowIndicator
            self.avatarStyle = avatarStyle
        }

        var body: some View {
            HStack(alignment: .top, spacing: 0) {
                avatarHStack
                textsVStack
                    .offset(x: -avatarStyle.leadingOffset*2)
                    .padding(.horizontal, Length.Padding.split)
            }
        }

        private var avatarHStack: some View {
            HStack(spacing: 0) {
                if shouldShowIndicator {
                    indicator
                        .padding(.horizontal, Length.Padding.single)
                    AvatarsView(style: avatarStyle)
                        .offset(x: -avatarStyle.leadingOffset)
                } else {
                    AvatarsView(style: avatarStyle)
                        .offset(x: -avatarStyle.leadingOffset)
                        .padding(.leading, Length.Padding.medium)
                }
            }
        }

        private var indicator: some View {
            Circle()
                .fill(Color.DS.Background.brand(isJetpack: AppConfiguration.isJetpack))
                .frame(width: Length.Padding.single)
        }

        private var textsVStack: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .style(.bodySmall(.regular))
                    .foregroundStyle(Color.DS.Foreground.primary)
                    .lineLimit(2)

                if let description {
                    Text(description)
                        .style(.bodySmall(.regular))
                        .foregroundStyle(Color.DS.Foreground.secondary)
                        .lineLimit(2)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    VStack(alignment: .leading, spacing: Length.Padding.medium) {
        NotificationsTableViewCell.Content(
            title: "John Smith liked your comment more than all other comments as asdf",
            description: "Here is what I think of all this: Lorem ipsum dolor sit amet, consectetur adipiscing elit",
            shouldShowIndicator: true,
            avatarStyle: .single(
                URL(string: "https://i.pickadummy.com/index.php?imgsize=40x40")!
            )
        )

        NotificationsTableViewCell.Content(
            title: "Albert Einstein and Marie Curie liked your comment on Quantum Mechanical solution for Hydrogen",
            description: "Mary Carpenter • marycarpenter.com",
            shouldShowIndicator: true,
            avatarStyle: .double(
                URL(string: "https://i.pickadummy.com/index.php?imgsize=34x34")!,
                URL(string: "https://i.pickadummy.com/index.php?imgsize=34x34")!
            )
        )

        NotificationsTableViewCell.Content(
            title: "New likes on Night Time in Tokyo",
            description: "Sarah, Céline and Amit",
            shouldShowIndicator: true,
            avatarStyle: .triple(
                URL(string: "https://i.pickadummy.com/index.php?imgsize=28x28")!,
                URL(string: "https://i.pickadummy.com/index.php?imgsize=28x28")!,
                URL(string: "https://i.pickadummy.com/index.php?imgsize=28x28")!
            )
        )
    }
}
#endif
