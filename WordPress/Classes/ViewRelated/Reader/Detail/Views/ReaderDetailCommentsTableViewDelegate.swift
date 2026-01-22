import UIKit
import WordPressData
import WordPressReader
import WordPressShared

/// Table View delegate to handle the Comments table displayed in Reader Post details.
///
class ReaderDetailCommentsTableViewDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Private Properties

    private(set) var totalComments = 0
    private var post: ReaderPost?
    private weak var presentingViewController: UIViewController?
    private weak var buttonDelegate: BorderedButtonTableViewCellDelegate?
    private(set) var headerView: ReaderDetailCommentsHeader?
    private let helper = ReaderCommentsHelper()
    var followButtonTappedClosure: (() ->Void)?
    var buttonLeaveCommentTapped: ((Comment?) -> Void)?

    var displaySetting: ReaderDisplaySettings

    private var items: [Item] = []

    private enum Item {
        case addCommentButton
        case comment(Comment)
        case emptyState(title: String)
        case viewAllButton
    }

    // MARK: - Public Methods

    init(displaySetting: ReaderDisplaySettings = .standard) {
        self.displaySetting = displaySetting
    }

    func configure(
        post: ReaderPost,
        comments: [Comment] = [],
        totalComments: Int = 0,
        presentingViewController: UIViewController,
        buttonDelegate: BorderedButtonTableViewCellDelegate? = nil
    ) {
        self.post = post
        self.totalComments = totalComments
        self.presentingViewController = presentingViewController
        self.buttonDelegate = buttonDelegate

        var items: [Item] = []
        if post.commentsOpen {
            items.append(.addCommentButton)
        }
        if comments.isEmpty {
            let title = post.commentsOpen ? Constants.emptyStateTitle : Constants.closedComments
            items.append(.emptyState(title: title))
        } else {
            items.append(contentsOf: comments.map { .comment($0) })
        }
        if !comments.isEmpty {
            items.append(.viewAllButton)
        }
        self.items = items
    }

    func updateFollowButtonState(post: ReaderPost) {
        self.post = post
        headerView?.updateFollowButtonState(post: post)
    }

    // MARK: - Table Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case .addCommentButton:
            return makeAddCommentButtonCell()
        case .comment(let comment):
            return makeCommentCell(for: comment, in: tableView)
        case .emptyState(let title):
            return makeEmptyStateCell(title: title, in: tableView)
        case .viewAllButton:
            return makeViewAllButtonCell()
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReaderDetailCommentsHeader.defaultReuseID) as? ReaderDetailCommentsHeader,
              let post,
              let presentingViewController else {
            return nil
        }

        header.displaySetting = displaySetting
        header.contentView.backgroundColor = .clear
        header.configure(
            post: post,
            totalComments: totalComments,
            presentingViewController: presentingViewController,
            followButtonTappedClosure: followButtonTappedClosure
        )

        headerView = header
        return header
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        /// We used this method to show the Jetpack badge rather than setting `tableFooterView` because it scaled better with Dynamic type.
        guard section == 0, JetpackBrandingVisibility.all.enabled else {
            return nil
        }
        let textProvider = JetpackBrandingTextProvider(screen: JetpackBadgeScreen.readerDetail)
        return JetpackButton.makeBadgeView(title: textProvider.brandingText(),
                                           bottomPadding: Constants.jetpackBadgeBottomPadding,
                                           target: self,
                                           selector: #selector(jetpackButtonTapped))
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return ReaderDetailCommentsHeader.estimatedHeight
    }

    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return ReaderDetailCommentsHeader.estimatedHeight
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section == 0, JetpackBrandingVisibility.all.enabled else {
            return 0
        }
        return UITableView.automaticDimension
    }
}

private extension ReaderDetailCommentsTableViewDelegate {

    func makeAddCommentButtonCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        let leaveCommentView = LeaveCommentView()
        leaveCommentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(leaveCommentCellTapped)))

        cell.contentView.addSubview(leaveCommentView)
        leaveCommentView.pinEdges(insets: UIEdgeInsets(top: 16, left: 0, bottom: 8, right: 0))

        return cell
    }

    func makeCommentCell(for comment: Comment, in tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentContentTableViewCell.defaultReuseID) as? CommentContentTableViewCell else {
            return UITableViewCell()
        }

        cell.displaySetting = displaySetting
        cell.configureForPostDetails(with: comment, helper: helper) { _ in
            do {
                try WPException.objcTry {
                    tableView.performBatchUpdates({})
                }
            } catch {
                WordPressAppDelegate.crashLogging?.logError(error)
            }
        }

        cell.accessoryButtonAction = { [weak self] sourceView in
            self?.shareComment(comment, sourceView: sourceView)
        }
        cell.replyButtonAction = { [weak self] in
            self?.buttonLeaveCommentTapped?(comment)
        }

        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear

        return cell
    }

    func makeEmptyStateCell(title: String, in tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReaderDetailNoCommentCell.defaultReuseID) as? ReaderDetailNoCommentCell else {
            return UITableViewCell()
        }

        cell.titleLabel.text = title
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear

        if ReaderDisplaySettings.customizationEnabled {
            cell.titleLabel.font = displaySetting.font(with: .body)
            cell.titleLabel.textColor = displaySetting.color.secondaryForeground
        }
        return cell
    }

    func makeViewAllButtonCell() -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        var configuration = UIButton.Configuration.bordered()
        configuration.title = Constants.viewAllButtonTitle.localizedCapitalized + "   \(totalComments)"
        configuration.image = UIImage(systemName: "chevron.right")
        configuration.imagePlacement = .trailing
        configuration.titleTextAttributesTransformer = .init {
            var container = $0
            container.font = UIFont.preferredFont(forTextStyle: .headline).withWeight(.medium)
            return container
        }
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(paletteColors: [.tertiaryLabel])
            .applying(UIImage.SymbolConfiguration(font: UIFont.preferredFont(forTextStyle: .caption2).withWeight(.bold)))
        configuration.imagePadding = 4
        configuration.contentInsets = .init(top: 9, leading: 12, bottom: 9, trailing: 12)

        let button = UIButton(configuration: configuration, primaryAction: .init { [weak self] _ in
            self?.buttonDelegate?.buttonTapped()
        })

        cell.contentView.addSubview(button)

        button.pinEdges([.leading, .vertical], insets: UIEdgeInsets(horizontal: 0, vertical: 16))
        button.pinEdges(.trailing, relation: .lessThanOrEqual)

        return cell
    }

    // MARK: - Actions

    private func shareComment(_ comment: Comment, sourceView: UIView?) {
        guard let commentURL = comment.commentURL() else {
            return
        }
        WPAnalytics.track(.readerArticleCommentShared)

        let activityViewController = UIActivityViewController(activityItems: [commentURL as Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sourceView
        UIViewController.topViewController?.present(activityViewController, animated: true, completion: nil)
    }

    @objc private func leaveCommentCellTapped() {
        WPAnalytics.track(.readerArticleLeaveCommentTapped)
        buttonLeaveCommentTapped?(nil)
    }

    @objc func jetpackButtonTapped() {
        guard let presentingViewController else {
            return
        }
        JetpackBrandingCoordinator.presentOverlay(from: presentingViewController)
        JetpackBrandingAnalyticsHelper.trackJetpackPoweredBadgeTapped(screen: .readerDetail)
    }

    struct Constants {
        static let closedComments = NSLocalizedString("Comments are closed", comment: "Displayed on the post details page when there are no post comments and commenting is closed.")
        static let viewAllButtonTitle = NSLocalizedString("View all comments", comment: "Title for button on the post details page to show all comments when tapped.")
        static let emptyStateTitle = NSLocalizedString("Be the first to comment", comment: "Title for button on the post details page when there are no comments.")
        static let jetpackBadgeBottomPadding: CGFloat = 10
    }
}
