import UIKit
import SwiftUI

final class CommentContentView: UIView {

    // MARK: - Views

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = CGFloat.DS.Padding.single
        stackView.alignment = .fill
        return stackView
    }()

    private var authorHostingController: UIHostingController<CommentContentHeaderView>?

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)
        self.pinSubviewToAllEdges(stackView)
    }

    // MARK: - Updating UI

    /// Configures the view with a `Comment` object.
    ///
    /// - Parameters:
    ///   - comment: The `Comment` object to display.
    ///   - renderMethod: Specifies how to display the comment body. See `RenderMethod`.
    ///   - onContentLoaded: Callback to be called once the content has been loaded. Provides the new content height as parameter.
    func update(
        with comment: Comment,
        renderMethod: RenderMethod = .web,
        onContentLoaded: ((CGFloat) -> Void)?,
        parent: UIViewController
    ) {
        let menuConfig = CommentContentHeaderView.MenuConfiguration(
            userInfo: true,
            share: true,
            editComment: true,
            changeStatus: true
        ) { option in
        }
        let config = CommentContentHeaderView.Configuration(
            avatarURL: comment.avatarURLForDisplay(),
            username: comment.authorForDisplay(),
            handleAndTimestamp: "@TurnUpAlex • 2h ago",
            menu: menuConfig
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
