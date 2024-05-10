import Foundation
import SwiftUI

class NoteBlockUserTableViewCell: NoteBlockTableViewCell {
    private var controller: UIHostingController<NotificationDetailUserView>?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        shouldSetSeparators = false
    }

    func configure(
        userBlock: FormattableUserContent,
        onUserClicked: @escaping () -> Void,
        onFollowClicked: @escaping (Bool) -> Void,
        parent: UIViewController
    ) {
        let isFollowEnabled = userBlock.isActionEnabled(id: FollowAction.actionIdentifier())
        let hasHomeTitle = userBlock.metaTitlesHome?.isEmpty == false

        if isFollowEnabled {
            configure(
                avatarURL: userBlock.media.first?.mediaURL,
                username: userBlock.text,
                blog: hasHomeTitle ? userBlock.metaTitlesHome : userBlock.metaLinksHome?.host,
                isFollowed: userBlock.isActionOn(id: FollowAction.actionIdentifier()),
                onUserClicked: onUserClicked,
                onFollowClicked: onFollowClicked,
                parent: parent
            )
        } else {
            configure(
                avatarURL: userBlock.media.first?.mediaURL,
                username: userBlock.text,
                blog: hasHomeTitle ? userBlock.metaTitlesHome : userBlock.metaLinksHome?.host,
                onUserClicked: onUserClicked,
                parent: parent
            )
        }
    }

    func configure(
        avatarURL: URL?,
        username: String?,
        blog: String?,
        isFollowed: Bool? = nil,
        onUserClicked: @escaping () -> Void,
        onFollowClicked: @escaping (Bool) -> Void = { _ in },
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
