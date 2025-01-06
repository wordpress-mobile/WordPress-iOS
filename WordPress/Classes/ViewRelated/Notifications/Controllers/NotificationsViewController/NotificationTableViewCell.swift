import UIKit
import SwiftUI

final class NotificationTableViewCell: HostingTableViewCell<NotificationsTableViewCellContent> {

    static let reuseIdentifier = String(describing: NotificationTableViewCell.self)

    // MARK: - API

    func configure(with notification: Notification, deletionRequest: NotificationDeletionRequest, parent: NotificationsViewController, onDeletionRequestCanceled: @escaping () -> Void) {
        let style = NotificationsTableViewCellContent.Style.altered(.init(text: deletionRequest.kind.legendText, action: onDeletionRequestCanceled))
        self.host(.init(style: style), parent: parent)
    }

    func configure(with viewModel: NotificationsViewModel, notification: Notification, parent: NotificationsViewController) {
        let title: AttributedString? = {
            guard let attributedSubject = notification.renderSubject() else {
                return nil
            }
            return AttributedString(attributedSubject)
        }()
        let description = notification.renderSnippet()?.string
        let inlineAction = inlineAction(viewModel: viewModel, notification: notification, parent: parent)
        let avatarStyle = AvatarView<Circle>.Style(urls: notification.allAvatarURLs) ?? .single(notification.iconURL)
        let style = NotificationsTableViewCellContent.Style.regular(
            .init(
                title: title,
                description: description,
                shouldShowIndicator: !notification.read,
                avatarStyle: avatarStyle,
                inlineAction: inlineAction
            )
        )
        self.host(.init(style: style), parent: parent)
    }

    // MARK: - Private Methods

    private func inlineAction(viewModel: NotificationsViewModel, notification: Notification, parent: NotificationsViewController) -> NotificationsTableViewCellContent.InlineAction.Configuration? {
        let notification = notification.parsed()
        switch notification {
        case .comment(let notification):
            return commentLikeInlineAction(viewModel: viewModel, notification: notification, parent: parent)
        case .newPost(let notification):
            return postLikeInlineAction(viewModel: viewModel, notification: notification, parent: parent)
        case .other(let notification):
            guard notification.kind == .like else {
                return nil
            }
            return shareInlineAction(viewModel: viewModel, notification: notification, parent: parent)
        }
    }

    private func shareInlineAction(viewModel: NotificationsViewModel, notification: Notification, parent: UIViewController) -> NotificationsTableViewCellContent.InlineAction.Configuration {
        let action: () -> Void = { [weak self] in
            guard let self, let content = viewModel.sharePostActionTapped(with: notification) else {
                return
            }
            let sharingController = PostSharingController()
            sharingController.sharePost(
                content.title,
                link: content.url,
                fromView: self,
                inViewController: parent
            )
        }
        return NotificationsTableViewCellContent.InlineAction.Configuration(
            icon: Image.DS.icon(named: .blockShare),
            accessibilityLabel: SharedStrings.Button.share,
            accessibilityHint: Strings.tapToShareThisPost,
            action: action
        )
    }

    private func postLikeInlineAction(viewModel: NotificationsViewModel,
                                      notification: NewPostNotification,
                                      parent: NotificationsViewController) -> NotificationsTableViewCellContent.InlineAction.Configuration {
        let action: () -> Void = { [weak self, weak parent] in
            guard let self,
                  let parent,
                  let content = self.content,
                  case let .regular(style) = content.style,
                  let config = style.inlineAction
            else {
                return
            }
            parent.cancelNextUpdateAnimation()
            viewModel.likeActionTapped(with: notification, action: .postLike) { liked in
                let (image, color) = self.likeInlineActionIcon(filled: liked)
                config.icon = image
                config.color = color
            }
        }
        let (image, color) = self.likeInlineActionIcon(filled: notification.liked)
        return NotificationsTableViewCellContent.InlineAction.Configuration(
            icon: image,
            color: color,
            accessibilityLabel: notification.liked ? Strings.postLikeButtonOnAccessibilityLabel : Strings.likeButtonOffAccessibilityLabel,
            accessibilityHint: notification.liked ? Strings.tapToUnlikeThisPost : Strings.tapToLikeThisPost,
            action: action
        )
    }

    private func commentLikeInlineAction(viewModel: NotificationsViewModel,
                                         notification: CommentNotification,
                                         parent: NotificationsViewController) -> NotificationsTableViewCellContent.InlineAction.Configuration {
        let action: () -> Void = { [weak self, weak parent] in
            guard let self,
                  let parent,
                  let content = self.content,
                  case let .regular(style) = content.style,
                  let config = style.inlineAction else {
                return
            }
            parent.cancelNextUpdateAnimation()
            viewModel.likeActionTapped(with: notification, action: .commentLike) { liked in
                let (image, color) = self.likeInlineActionIcon(filled: liked)
                config.icon = image
                config.color = color
            }
        }
        let (image, color) = self.likeInlineActionIcon(filled: notification.liked)
        return NotificationsTableViewCellContent.InlineAction.Configuration(
            icon: image,
            color: color,
            accessibilityLabel: notification.liked ? Strings.commentLikeButtonOnAccessibilityLabel : Strings.likeButtonOffAccessibilityLabel,
            accessibilityHint: notification.liked ? Strings.tapToUnlikeThisComment : Strings.tapToLikeThisComment,
            action: action
        )
    }

    private func likeInlineActionIcon(filled: Bool) -> (image: Image, color: Color?) {
        let image: Image = Image.DS.icon(named: filled ? .starFill : .starOutline)
        let color: Color? = filled ? AppColor.primary: nil
        return (image: image, color: color)
    }

    enum Strings {
        static let postLikeButtonOnAccessibilityLabel = NSLocalizedString(
            "notifications.accessibility-post-like-button-on",
            value: "You've Liked this post",
            comment: "The user has previously tapped 'Like' on this post"
        )

        static let commentLikeButtonOnAccessibilityLabel = NSLocalizedString(
            "notifications.accessibility-comment-like-button-on",
            value: "You've Liked this comment",
            comment: "The user has previously tapped 'Like' on this comment"
        )

        static let likeButtonOffAccessibilityLabel = NSLocalizedString(
            "notifications.accessibility-like-button-off",
            value: "Not liked",
            comment: "The user has not previously tapped 'Like' on this post or comment"
        )

        static let tapToLikeThisPost = NSLocalizedString(
            "notifications.accessibility-tap-to-like-this-post",
            value: "Double Tap to Like this Post",
            comment: "A label for screenreader users"
        )

        static let tapToUnlikeThisPost = NSLocalizedString(
            "notifications.accessibility-tap-to-unlike-this-post",
            value: "Double Tap to Unlike this Post",
            comment: "A label for screenreader users"
        )

        static let tapToLikeThisComment = NSLocalizedString(
            "notifications.accessibility-tap-to-like-this-comment",
            value: "Double Tap to Like this Comment",
            comment: "A label for screenreader users"
        )

        static let tapToUnlikeThisComment = NSLocalizedString(
            "notifications.accessibility-tap-to-unlike-this-comment",
            value: "Double Tap to Unlike this Comment",
            comment: "A label for screenreader users"
        )

        static let tapToShareThisPost = NSLocalizedString(
            "notifications.accessibility-tap-to-share-this-post",
            value: "Double Tap to Share this Post",
            comment: "A label for screenreader users"
        )
    }
}
