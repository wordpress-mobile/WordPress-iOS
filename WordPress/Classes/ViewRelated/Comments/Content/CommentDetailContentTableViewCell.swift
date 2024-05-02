import UIKit
import SwiftUI

final class CommentDetailContentTableViewCell: UITableViewCell, Reusable {

    // MARK: - Typealias

    typealias ContentConfiguration = CommentDetailContentView.Configuration
    typealias HeaderConfiguration = CommentContentHeaderView.Configuration

    // MARK: - Views

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = CGFloat.DS.Padding.single
        stackView.alignment = .fill
        return stackView
    }()

    private var authorHostingController: UIHostingController<CommentContentHeaderView>?

    private var commentView = CommentDetailContentView()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        self.stackView.addArrangedSubview(commentView)
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(stackView)
        self.contentView.pinSubviewToAllEdgeMargins(stackView)
        self.selectionStyle = .none
    }

    // MARK: - Updating UI

    func configure(with headerConfig: HeaderConfiguration, contentConfig: ContentConfiguration, parent: UIViewController) {
        self.updateHeader(with: headerConfig, parent: parent)
        self.commentView.configure(with: contentConfig)
    }

    func configure(with contentConfig: ContentConfiguration, parent: UIViewController) {
        self.updateHeader(with: headerConfiguration(from: contentConfig.comment), parent: parent)
        self.commentView.configure(with: contentConfig)
    }
}

// MARK: - Helpers

private extension CommentDetailContentTableViewCell {

    private func updateHeader(with config: CommentContentHeaderView.Configuration, parent: UIViewController) {
        let content = CommentContentHeaderView(config: config)

        if let hostingController = authorHostingController {
            hostingController.rootView = content
        } else {
            let hostingController = UIHostingController<CommentContentHeaderView>(rootView: content)
            hostingController.view.backgroundColor = .clear
            hostingController.willMove(toParent: parent)
            stackView.insertArrangedSubview(hostingController.view, at: 0)
            parent.addChild(hostingController)
            hostingController.didMove(toParent: parent)
            self.authorHostingController = hostingController
        }

        self.authorHostingController?.view?.invalidateIntrinsicContentSize()
    }

    private func headerConfiguration(from comment: Comment) -> CommentContentHeaderView.Configuration {
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
        return config
    }
}
