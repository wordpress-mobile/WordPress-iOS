import SwiftUI
import DesignSystem

extension NotificationsTableViewCell {
    struct Content: View {
        enum Style {
            struct Regular {
                let title: String
                let description: String?
                let shouldShowIndicator: Bool
                let avatarStyle: AvatarsView.Style
                let actionIconName: String? // TODO: Will be refactored to contain the action.
            }

            struct Altered {
                let text: String
                let actionTitle: String
                let action: (() -> Void)?
            }

            case regular(Regular)
            case altered(Altered)
        }

        private let style: Style

        init(style: Style) {
            self.style = style
        }

        var body: some View {
            switch style {
            case .regular(let regular):
                Regular(info: regular)
            case .altered(let altered):
                Altered(info: altered)
            }
        }
    }
}

// MARK: - Regular Style
fileprivate extension NotificationsTableViewCell.Content {
    struct Regular: View {
        private let info: Style.Regular

        fileprivate init(info: Style.Regular) {
            self.info = info
        }

        var body: some View {
            HStack(alignment: .top, spacing: 0) {
                avatarHStack
                textsVStack
                    .offset(x: -info.avatarStyle.leadingOffset*2)
                    .padding(.horizontal, Length.Padding.split)
                if let actionIconName = info.actionIconName {
                    actionIcon(withName: actionIconName)
                }
            }
            .padding(.trailing, Length.Padding.double)
        }

        private var avatarHStack: some View {
            HStack(spacing: 0) {
                if info.shouldShowIndicator {
                    indicator
                        .padding(.horizontal, Length.Padding.single)
                    AvatarsView(style: info.avatarStyle)
                        .offset(x: -info.avatarStyle.leadingOffset)
                } else {
                    AvatarsView(style: info.avatarStyle)
                        .offset(x: -info.avatarStyle.leadingOffset)
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
                Text(info.title)
                    .style(.bodySmall(.regular))
                    .foregroundStyle(Color.DS.Foreground.primary)
                    .lineLimit(2)

                if let description = info.description {
                    Text(description)
                        .style(.bodySmall(.regular))
                        .foregroundStyle(Color.DS.Foreground.secondary)
                        .lineLimit(2)
                }
            }
        }

        private func actionIcon(withName iconName: String) -> some View {
            Image(systemName: iconName)
                .imageScale(.small)
                .foregroundStyle(Color.DS.Foreground.secondary)
                .frame(width: Length.Padding.medium, height: Length.Padding.medium)
        }
    }
}

// MARK: - Regular Style
fileprivate extension NotificationsTableViewCell.Content {
    struct Altered: View {
        private let info: Style.Altered

        fileprivate init(info: Style.Altered) {
            self.info = info
        }

        var body: some View {
            // To not pollute the init too much, colors are uncustomizable
            // If a need arises, they can be added to the `Altered.Info` struct.
            HStack(spacing: 0) {
                Group {
                    Text(info.text)
                        .style(.bodySmall(.regular))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .padding(.leading, Length.Padding.medium)

                    Spacer()

                    Button(action: {
                        info.action?()
                    }, label: {
                        Text(info.actionTitle)
                            .style(.bodySmall(.regular))
                            .foregroundStyle(Color.white)
                        .padding(.trailing, Length.Padding.medium)
                    })
                }
            }
            .frame(height: 60)
            .background(Color.DS.Foreground.error)
        }
    }
}

#if DEBUG
#Preview {
    VStack(alignment: .leading, spacing: Length.Padding.medium) {
        NotificationsTableViewCell.Content(
            style: .regular(
                .init(
                    title: "John Smith liked your comment more than all other comments as asdf",
                    description: "Here is what I think of all this: Lorem ipsum dolor sit amet, consectetur adipiscing elit",
                    shouldShowIndicator: true,
                    avatarStyle: .single(
                        URL(string: "https://i.pickadummy.com/index.php?imgsize=40x40")!
                    ),
                    actionIconName: "star"
                )
            )
        )

        NotificationsTableViewCell.Content(
            style: .regular(
                .init(
                    title: "Albert Einstein and Marie Curie liked your comment on Quantum Mechanical solution for Hydrogen",
                    description: "Mary Carpenter • marycarpenter.com",
                    shouldShowIndicator: true,
                    avatarStyle: .double(
                        URL(string: "https://i.pickadummy.com/index.php?imgsize=34x34")!,
                        URL(string: "https://i.pickadummy.com/index.php?imgsize=34x34")!
                    ),
                    actionIconName: "plus"
                )
            )
        )
        NotificationsTableViewCell.Content(
            style: .regular(
                .init(
                    title: "New likes on Night Time in Tokyo",
                    description: "Sarah, Céline and Amit",
                    shouldShowIndicator: true,
                    avatarStyle: .triple(
                        URL(string: "https://i.pickadummy.com/index.php?imgsize=28x28")!,
                        URL(string: "https://i.pickadummy.com/index.php?imgsize=28x28")!,
                        URL(string: "https://i.pickadummy.com/index.php?imgsize=28x28")!
                    ),
                    actionIconName: nil
                )
            )
        )

        NotificationsTableViewCell.Content(
            style: .altered(
                .init(
                    text: "Comment has been marked as Spam",
                    actionTitle: "Undo",
                    action: nil
                )
            )
        )
    }
}
#endif
