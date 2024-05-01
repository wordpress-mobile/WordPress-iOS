import UIKit
import SwiftUI

final class CommentDetailContentTableViewCell: UITableViewCell, Reusable {

    // MARK: - Views

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = CGFloat.DS.Padding.single
        stackView.alignment = .fill
        return stackView
    }()

    private var authorHostingController: UIHostingController<CommentContentHeaderView>?

    // MARK: - Callbacks

    // Callback to be called once the content has been loaded. Provides the new content height as parameter.
    var onContentLoaded: ((CGFloat) -> Void)?

    //
    var contentLinkTapAction: ((URL) -> Void)? = nil

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(stackView)
        self.contentView.pinSubviewToAllEdgeMargins(stackView)
        self.selectionStyle = .none
    }

    // MARK: - Updating UI

    /// Configures the view with a `Comment` object.
    ///
    /// - Parameters:
    ///   - comment: The `Comment` object to display.
    ///   - renderMethod: Specifies how to display the comment body. See `RenderMethod`.
    func configure(
        with comment: Comment,
        renderMethod: RenderMethod = .web,
        parent: UIViewController
    ) {
        let menu: CommentContentHeaderView.MenuList = {
            let firstSection: CommentContentHeaderView.MenuSection = [.userInfo({}), .share({})]
            let secondSection: CommentContentHeaderView.MenuSection = comment.allowsModeration() ? [.editComment({}), .changeStatus({ _ in })] : []
            return [firstSection, secondSection]
        }()
        let config = CommentContentHeaderView.Configuration(
            avatarURL: comment.avatarURLForDisplay(),
            username: comment.authorForDisplay(),
            handleAndTimestamp: comment.dateForDisplay()?.toMediumString() ?? "",
            menu: menu
        )
        self.updateHeader(with: config, parent: parent)
    }

    private func updateHeader(with config: CommentContentHeaderView.Configuration, parent: UIViewController) {
        let content = CommentContentHeaderView(config: config)

        if let hostingController = authorHostingController {
            hostingController.rootView = content
        } else {
            let hostingController = UIHostingController<CommentContentHeaderView>(rootView: content)
            hostingController.view.backgroundColor = .clear
            hostingController.willMove(toParent: parent)
            stackView.addArrangedSubview(hostingController.view)
            parent.addChild(hostingController)
            hostingController.didMove(toParent: parent)
            self.authorHostingController = hostingController
        }

        self.authorHostingController?.view?.invalidateIntrinsicContentSize()
    }

    // MARK: - Types

    enum RenderMethod: Equatable {
        /// Uses WebKit to render the comment body.
        case web

        /// Uses WPRichContent to render the comment body.
        case richContent(NSAttributedString)
    }
}
