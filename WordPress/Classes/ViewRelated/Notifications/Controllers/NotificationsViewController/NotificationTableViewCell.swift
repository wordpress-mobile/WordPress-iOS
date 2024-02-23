import UIKit
import SwiftUI

final class NotificationTableViewCell: HostingTableViewCell<NotificationsTableViewCellContent> {

    static let reuseIdentifier = String(describing: NotificationTableViewCell.self)

    // MARK: - API

    func configure(with notification: Notification, deletionRequest: NotificationDeletionRequest, parent: UIViewController, onDeletionRequestCanceled: @escaping () -> Void) {
        let style = NotificationsTableViewCellContent.Style.altered(.init(text: deletionRequest.kind.legendText, action: onDeletionRequestCanceled))
        self.host(.init(style: style), parent: parent)
    }

    func configure(with viewModel: NotificationsViewModel, notification: Notification, parent: UIViewController) {
        let title: AttributedString? = {
            guard let attributedSubject = notification.renderSubject() else {
                return nil
            }
            return AttributedString(attributedSubject)
        }()
        let description = notification.renderSnippet()?.string
        let inlineAction = inlineAction(viewModel: viewModel, notification: notification, parent: parent)
        let avatarStyle = AvatarsView.Style(urls: notification.allAvatarURLs) ?? .single(notification.iconURL)
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

    private func inlineAction(viewModel: NotificationsViewModel, notification: Notification, parent: UIViewController) -> NotificationsTableViewCellContent.InlineAction.Configuration? {
        let notification = notification.parsed()
        switch notification {
        case .newPost(let notification):
            return postLikeInlineAction(viewModel: viewModel, notification: notification)
        case .other(let notification):
            guard notification.kind == .like || notification.kind == .reblog else {
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

    private func postLikeInlineAction(viewModel: NotificationsViewModel, notification: NewPostNotification) -> NotificationsTableViewCellContent.InlineAction.Configuration {
        let action: () -> Void = { [weak self] in
            guard let self, let content = self.content, case let .regular(style) = content.style, let config = style.inlineAction else {
                return
            }
            viewModel.postLikeActionTapped(with: notification) { liked in
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
        let color: Color? = filled ? Color.DS.Foreground.brand(isJetpack: true) : nil
        return (image: image, color: color)
    }
}
