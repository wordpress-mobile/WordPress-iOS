import UIKit
import SwiftUI
import DesignSystem

final class CommentHeaderTableViewCell: HostingTableViewCell<ContentPreview>, Reusable {

    // MARK: Typealias

    typealias Constants = ContentPreview.Constants
    typealias Avatar = ContentPreview.ImageConfiguration.Avatar

    // MARK: Initialization

    required init() {
        super.init(style: .subtitle, reuseIdentifier: Self.defaultReuseID)
        self.selectionStyle = .none
        self.contentView.directionalLayoutMargins = .init(
            top: CGFloat.DS.Padding.double,
            leading: 0,
            bottom: CGFloat.DS.Padding.double,
            trailing: 0
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(post: String, action: @escaping () -> Void, parent: UIViewController) {
        let content = ContentPreview(text: post, action: action)
        self.host(content, parent: parent)
    }

    func configure(avatar: Avatar, comment: String, action: @escaping () -> Void, parent: UIViewController) {
        let content = ContentPreview(image: .init(avatar: avatar), text: comment, action: action)
        self.host(content, parent: parent)
    }

    // MARK: - Layout

    override func layout(hostingView view: UIView) {
        self.contentView.pinSubviewToAllEdgeMargins(view)
    }
}
