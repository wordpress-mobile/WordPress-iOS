import SwiftUI
import DesignSystem

struct CommentContentHeaderView: View {

    let config: Configuration

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
            CommentContentHeaderMenu(menu: config.menu)
        }
    }

    struct Configuration {
        let avatarURL: URL?
        let username: String
        let handleAndTimestamp: String
        let menu: [[MenuItem]]
    }

    typealias MenuItem = CommentContentHeaderMenu.Item
}

extension CommentContentHeaderView.Configuration {

     init(avatarURL: URL?, username: String, handleAndTimestamp: String, menu: [CommentContentHeaderView.MenuItem]) {
        self.init(
            avatarURL: avatarURL,
            username: username,
            handleAndTimestamp: handleAndTimestamp,
            menu: [menu]
        )
    }
}

struct CommentContentHeaderMenu: View {
   let menu: [[Item]]

   var body: some View {
       Menu {
           ForEach(Array(menu.enumerated()), id: \.offset) { sectionIndex, section in
               if !section.isEmpty {
                   Section {
                       ForEach(Array(section.enumerated()), id: \.offset) { itemIndex, menuItem in
                           button(for: menuItem)
                       }
                   }
                   if sectionIndex < menu.count - 1 && !menu[sectionIndex + 1].isEmpty {
                       Divider()
                   }
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
   func button(for menuItem: Item) -> some View {
       switch menuItem {
       case .userInfo(let action):
           Button(action: action) {
               Label {
                   Text(Strings.userInfo)
               } icon: {
                   Image.DS.icon(named: .avatar)
               }
           }
       case .share(let action):
           Button(action: action) {
               Label {
                   Text(Strings.share)
               } icon: {
                   Image.DS.icon(named: .blockShare)
               }
           }
       case .editComment(let action):
           Button(action: action) {
               Label {
                   Text(Strings.editComment)
               } icon: {
                   Image.DS.icon(named: .edit)
               }
           }
       case .changeStatus(let action):
           Menu(Strings.changeStatus) {
               Button(Strings.approve, action: { action(.approve) })
               Button(Strings.pending, action: { action(.pending) })
               Button(Strings.trash, action: { action(.trash) })
               Button(Strings.spam, action: { action(.spam) })
           }
       }
   }

   enum Item {
       case userInfo(() -> Void)
       case share(() -> Void)
       case editComment(() -> Void)
       case changeStatus((Status) -> Void)

       enum Status {
           case approve, trash, spam, pending
       }
   }

    private enum Strings {
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

#if DEBUG
#Preview {
    VStack(alignment: .leading) {
        CommentContentHeaderView(
            config: .init(
                avatarURL: URL(string: "https://i.pravatar.cc/300"),
                username: "Alex Turner",
                handleAndTimestamp: "@TurnUpAlex • 2h ago",
                menu: [[.userInfo({}), .share({})], [.editComment({}), .changeStatus({ _ in })]]
            )
        )
        CommentContentHeaderView(
            config: .init(
                avatarURL: URL(string: "invalid-url"),
                username: "Jordan Fisher",
                handleAndTimestamp: "@FishyJord • 4h ago",
                menu: [.userInfo({}), .share({})]
            )
        )
        CommentContentHeaderView(
            config: .init(
                avatarURL: URL(string: "https://i.pravatar.cc/400"),
                username: "Casey Hart",
                handleAndTimestamp: "@HartOfTheMatter • 9h ago",
                menu: [[.userInfo({}), .share({})], [.editComment({}), .changeStatus({ _ in })]]
            )
        )
    }
    .padding(.horizontal, .DS.Padding.double)
}
#endif
