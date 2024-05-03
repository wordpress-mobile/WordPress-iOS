import SwiftUI
import DesignSystem

struct CommentContentHeaderView: View {

    let config: Configuration
    var menu: MenuConfiguration {
        return config.menu
    }

    private var shouldShowMenu: Bool {
        return [menu.userInfo, menu.share, menu.editComment, menu.changeStatus].reduce(false) { $0 || $1 }
    }

    var body: some View {
        HStack(spacing: .DS.Padding.split) {
            AvatarsView(style: .single(config.avatarURL))
            VStack(alignment: .leading) {
                Text(config.username)
                    .style(.bodySmall(.regular))
                    .foregroundStyle(Color.DS.Foreground.primary)
                    .lineLimit(1)
                Text(config.handleAndTimestamp)
                    .style(.bodySmall(.regular))
                    .foregroundStyle(Color.DS.Foreground.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if shouldShowMenu {
                CommentContentHeaderMenu(config: config.menu)
            }
        }
    }

    struct Configuration {
        let avatarURL: URL?
        let username: String
        let handleAndTimestamp: String
        let menu: MenuConfiguration

        init(avatarURL: URL?, username: String, handleAndTimestamp: String, menu: MenuConfiguration) {
            self.avatarURL = avatarURL
            self.username = username
            self.handleAndTimestamp = handleAndTimestamp
            self.menu = menu
        }
    }

    struct MenuConfiguration {
        let userInfo: Bool
        let share: Bool
        let editComment: Bool
        let changeStatus: Bool
        let onOptionSelected: (Option) -> Void

        enum Option {
            case userInfo, share, editComment, changeStatus(Status)
        }

        enum Status {
            case approve, pending, spam, trash
        }
    }
}

// MARK: - Menu

private struct CommentContentHeaderMenu: View {

    typealias Configuration = CommentContentHeaderView.MenuConfiguration

    private let config: Configuration

    init(config: Configuration) {
        self.config = config
    }

    private var shouldShowDivider: Bool {
        return config.editComment || config.changeStatus
    }

    var body: some View {
        Menu {
            if config.userInfo {
                button(title: Strings.userInfo, icon: .avatar) { config.onOptionSelected(.userInfo) }
            }
            if config.share {
                button(title: Strings.share, icon: .blockShare) { config.onOptionSelected(.share) }
            }
            if shouldShowDivider {
                Divider()
            }
            if config.editComment {
                button(title: Strings.editComment, icon: .edit) { config.onOptionSelected(.editComment) }
            }
            if config.changeStatus {
                Menu(Strings.changeStatus) {
                    button(title: Strings.approve) { config.onOptionSelected(.changeStatus(.approve)) }
                    button(title: Strings.pending) { config.onOptionSelected(.changeStatus(.pending)) }
                    button(title: Strings.spam) { config.onOptionSelected(.changeStatus(.spam)) }
                    button(title: Strings.trash) { config.onOptionSelected(.changeStatus(.trash)) }
                }
            }
        } label: {
            Image.DS.icon(named: .ellipsisHorizontal)
                .imageScale(.small)
                .frame(width: .DS.Padding.medium, height: .DS.Padding.medium)
                .foregroundStyle(Color.DS.Foreground.secondary)
        }
    }

    @ViewBuilder
    private func button(title: String, icon: IconName? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label {
                Text(title)
            } icon: {
                if let icon {
                    Image.DS.icon(named: icon)
                }
            }

        }
    }
}

private extension CommentContentHeaderMenu {

    enum Strings {
        static let userInfo = NSLocalizedString(
            "comment.moderation.content.menu.userInfo.title",
            value: "User info",
            comment: "User info option title for the comment moderation content menu."
        )
        static let share = NSLocalizedString(
            "comment.moderation.content.menu.share.title",
            value: "Share",
            comment: "Share option title for the comment moderation content menu."
        )
        static let editComment = NSLocalizedString(
            "comment.moderation.content.menu.editComment.title",
            value: "Edit comment",
            comment: "Edit comment option title for the comment moderation content menu."
        )
        static let changeStatus = NSLocalizedString(
            "comment.moderation.content.menu.changeStatus.title",
            value: "Change status",
            comment: "Change status option title for the comment moderation content menu."
        )
        static let approve = NSLocalizedString(
            "comment.moderation.content.menu.approve.title",
            value: "Approve",
            comment: "Approve option title for the comment moderation content menu."
        )
        static let pending = NSLocalizedString(
            "comment.moderation.content.menu.pending.title",
            value: "Pending",
            comment: "Pending option title for the comment moderation content menu."
        )
        static let trash = NSLocalizedString(
            "comment.moderation.content.menu.trash.title",
            value: "Trash",
            comment: "Trash option title for the comment moderation content menu."
        )
        static let spam = NSLocalizedString(
            "comment.moderation.content.menu.spam.title",
            value: "Spam",
            comment: "Spam option title for the comment moderation content menu."
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading) {
        CommentContentHeaderView(
            config: .init(
                avatarURL: URL(string: "https://i.pravatar.cc/300"),
                username: "Alex Turner",
                handleAndTimestamp: "@TurnUpAlex • 2h ago",
                menu: .init(userInfo: true, share: true, editComment: true, changeStatus: true) { _ in }
            )
        )
        CommentContentHeaderView(
            config: .init(
                avatarURL: URL(string: "invalid-url"),
                username: "Jordan Fisher",
                handleAndTimestamp: "@FishyJord • 4h ago",
                menu: .init(userInfo: true, share: true, editComment: false, changeStatus: false) { _ in }
            )
        )
        CommentContentHeaderView(
            config: .init(
                avatarURL: URL(string: "https://i.pravatar.cc/400"),
                username: "Casey Hart",
                handleAndTimestamp: "@HartOfTheMatter • 9h ago",
                menu: .init(userInfo: true, share: true, editComment: true, changeStatus: true) { _ in }
            )
        )
        CommentContentHeaderView(
            config: .init(
                avatarURL: URL(string: "https://i.pravatar.cc/600"),
                username: " Emily Stanton",
                handleAndTimestamp: "@StarryEm • 8h ago",
                menu: .init(userInfo: false, share: false, editComment: false, changeStatus: false) { _ in }
            )
        )
    }
    .padding(.horizontal, .DS.Padding.double)
}
