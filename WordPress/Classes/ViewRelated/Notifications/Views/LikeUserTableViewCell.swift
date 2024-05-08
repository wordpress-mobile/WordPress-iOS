import Foundation
import SwiftUI

class LikeUserTableViewCell: UITableViewCell, NibReusable {
    static let estimatedRowHeight: CGFloat = 80

    private var controller: UIHostingController<NotificationDetailUserView>?

    func configure(avatarURL: URL?, username: String?, blog: String?, onUserClicked: @escaping () -> Void, parent: UIViewController) {
        let view = NotificationDetailUserView(avatarURL: avatarURL, username: username, blog: blog, onUserClicked: onUserClicked)
        host(view, parent: parent)
    }

    func configure(
        avatarURL: URL?,
        username: String?,
        blog: String?,
        isFollowed: Bool,
        onUserClicked: @escaping () -> Void,
        onFollowClicked: @escaping (Bool) -> Void,
        parent: UIViewController
    ) {
        let view = NotificationDetailUserView(
            avatarURL: avatarURL,
            username: username,
            blog: blog,
            isFollowed: isFollowed,
            onUserClicked: onUserClicked,
            onFollowClicked: onFollowClicked
        )
        host(view, parent: parent)
    }

    private func host(_ content: NotificationDetailUserView, parent: UIViewController) {
        if let controller = controller {
            controller.rootView = content
            controller.view.layoutIfNeeded()
        } else {
            let cellViewController = UIHostingController(rootView: content)
            controller = cellViewController

            parent.addChild(cellViewController)
            contentView.addSubview(cellViewController.view)
            cellViewController.view.translatesAutoresizingMaskIntoConstraints = false
            layout(hostingView: cellViewController.view)

            cellViewController.didMove(toParent: parent)
        }
    }

    func layout(hostingView view: UIView) {
        self.contentView.pinSubviewToAllEdges(view)
    }
}
