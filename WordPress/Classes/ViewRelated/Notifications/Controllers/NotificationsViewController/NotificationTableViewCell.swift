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
                summary: nil,
                link: content.url,
                fromView: self,
                inViewController: parent
            )
        }
        return .init(
            icon: Image.DS.icon(named: .blockShare),
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
        return .init(icon: image, color: color, action: action)
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
        return .init(icon: image, color: color, action: action)
    }

    private func likeInlineActionIcon(filled: Bool) -> (image: Image, color: Color?) {
        let image: Image = Image.DS.icon(named: filled ? .starFill : .starOutline)
        let color: Color? = filled ? AppColor._brand: nil
        return (image: image, color: color)
    }
}
