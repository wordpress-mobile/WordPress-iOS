import UIKit
import CoreData

@objc protocol CommentDetailsDelegate: AnyObject {
    func nextCommentSelected()
}

class CommentDetailViewController: UITableViewController {

    // MARK: Properties

    @objc weak var delegate: CommentDetailsDelegate?
    private var comment: Comment
    private var isLastInList: Bool
    private var managedObjectContext: NSManagedObjectContext
    private var rows = [RowType]()
    private var moderationBar: CommentModerationBar?

    private var viewIsVisible: Bool {
        return navigationController?.visibleViewController == self
    }

    // MARK: Views

    private var headerCell = CommentHeaderTableViewCell()

    private lazy var replyIndicatorCell: UITableViewCell = {
        let cell = UITableViewCell()

        // display the replied icon using attributed string instead of using the default image view.
        // this is because the default image view is displayed beyond the separator line (within the layout margin area).
        let iconAttachment = NSTextAttachment()
        iconAttachment.image = Style.ReplyIndicator.iconImage

        let attributedString = NSMutableAttributedString()
        attributedString.append(.init(attachment: iconAttachment, attributes: Style.ReplyIndicator.textAttributes))
        attributedString.append(.init(string: " " + .replyIndicatorLabelText, attributes: Style.ReplyIndicator.textAttributes))

        // reverse the attributed strings in RTL direction.
        if view.effectiveUserInterfaceLayoutDirection == .rightToLeft {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.baseWritingDirection = .rightToLeft
            attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: .init(location: 0, length: attributedString.length))
        }

        cell.textLabel?.attributedText = attributedString
        cell.textLabel?.numberOfLines = 0

        // setup constraints for textLabel to match the spacing specified in the design.
        if let textLabel = cell.textLabel {
            textLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textLabel.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                textLabel.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                textLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: Constants.replyIndicatorVerticalSpacing),
                textLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -Constants.replyIndicatorVerticalSpacing)
            ])
        }

        return cell
    }()

    private lazy var deleteButton: UIButton = {
        let button = UIButton()
        let buttonColor = UIColor(light: .error, dark: .muriel(name: .red, .shade40))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(.deleteButtonText, for: .normal)
        button.setTitleColor(buttonColor, for: .normal)
        button.setTitleColor(.white, for: .highlighted)
        button.setBackgroundImage(UIImage.renderBackgroundImage(fill: .clear, border: buttonColor), for: .normal)
        button.setBackgroundImage(.renderBackgroundImage(fill: buttonColor, border: buttonColor), for: .highlighted)

        button.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0

        // add constraints to the title label, so the button can contain it properly in multi-line cases.
        if let label = button.titleLabel {
            button.pinSubviewToAllEdgeMargins(label)
        }

        button.on(.touchUpInside) { [weak self] _ in
            self?.deleteButtonTapped()
        }

        return button
    }()

    private lazy var deleteButtonCell: UITableViewCell = {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.accessibilityTraits = .button

        cell.contentView.addSubview(deleteButton)
        cell.contentView.pinSubviewToAllEdges(deleteButton, insets: Constants.deleteButtonInsets)

        return cell
    }()

    private lazy var commentService: CommentService = {
        return .init(managedObjectContext: managedObjectContext)
    }()

    /// Ideally, this property should be configurable as one of the initialization parameters (to make this testable).
    /// However, since this class is still initialized in Objective-C files, it cannot declare `ContentCoordinator` as the init parameter, unless the protocol
    /// is `@objc`-ified. Let's move this to the init parameter once the caller has been converted to Swift.
    private lazy var contentCoordinator: ContentCoordinator = {
        return DefaultContentCoordinator(controller: self, context: managedObjectContext)
    }()

    private lazy var parentComment: Comment? = {
        guard comment.hasParentComment(),
              let blog = comment.blog,
              let parentComment = commentService.findComment(withID: NSNumber(value: comment.parentID), in: blog) else {
                  return nil
              }

        return parentComment
    }()

    // transparent navigation bar style with visual blur effect.
    private lazy var blurredBarAppearance: UINavigationBarAppearance = {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        return appearance
    }()

    /// opaque navigation bar style.
    /// this is used for iOS 14 and below, since scrollEdgeAppearance only applies for large title bars, except on iOS 15 where it applies for all navbars.
    private lazy var opaqueBarAppearance: UINavigationBarAppearance = {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        return appearance
    }()

    /// Convenience property that keeps track of whether the content has scrolled.
    private var isContentScrolled: Bool = false {
        didSet {
            if isContentScrolled == oldValue {
                return
            }

            // show blurred navigation bar when content is scrolled, or opaque style when the scroll position is at the top.
            updateNavigationBarAppearance(isBlurred: isContentScrolled)
        }
    }

    // MARK: Initialization

    @objc required init(comment: Comment,
                        isLastInList: Bool,
                        managedObjectContext: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {
        self.comment = comment
        self.isLastInList = isLastInList
        self.managedObjectContext = managedObjectContext
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureTable()
        configureRows()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // when an orientation change is triggered, recalculate the content cell's height.
        guard let contentRowIndex = rows.firstIndex(of: .content) else {
            return
        }

        tableView.reloadRows(at: [.init(row: contentRowIndex, section: .zero)], with: .fade)
    }

    @objc func displayComment(_ comment: Comment, isLastInList: Bool) {
        self.comment = comment
        self.isLastInList = isLastInList
        refreshData()
    }

    // MARK: Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell: UITableViewCell = {
            switch row {
            case .header:
                configureHeaderCell()
                return headerCell

            case .content:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentContentTableViewCell.defaultReuseID) as? CommentContentTableViewCell else {
                    return .init()
                }

                configureContentCell(cell, comment: comment)
                cell.moderationBar.delegate = self
                moderationBar = cell.moderationBar
                return cell

            case .replyIndicator:
                return replyIndicatorCell

            case .text:
                return configuredTextCell(for: row)

            case .deleteComment:
                return deleteButtonCell
            }
        }()

        // hide cell separator if it's positioned before the delete button cell.
        cell.separatorInset = shouldHideCellSeparator(for: indexPath) ? insetsForHiddenCellSeparator : tableView.separatorInset

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rows[indexPath.row] {
        case .header:
            comment.hasParentComment() ? navigateToParentComment() : navigateToPost()

        case .replyIndicator:
            // TODO: Navigate to the comment reply.
            break

        case .text(let title, _, _) where title == .webAddressLabelText:
            visitAuthorURL()

        default:
            break
        }
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // keep track of whether the content has scrolled or not. This is used to update the navigation bar style in iOS 14 and below.
        // in iOS 15, we don't need to do this since it's been handled automatically; hence the early return.
        if #available(iOS 15, *) {
            return
        }

        isContentScrolled = scrollView.contentOffset.y > contentScrollThreshold
    }
}

// MARK: - Private Helpers

private extension CommentDetailViewController {

    typealias Style = WPStyleGuide.CommentDetail

    enum RowType: Equatable {
        case header
        case content
        case replyIndicator
        case text(title: String, detail: String, image: UIImage? = nil)
        case deleteComment
    }

    struct Constants {
        static let tableLeadingInset: CGFloat = 20.0
        static let tableBottomMargin: CGFloat = 40.0
        static let replyIndicatorVerticalSpacing: CGFloat = 14.0

        static let deleteButtonInsets = UIEdgeInsets(top: 4, left: 20, bottom: 4, right: 20)
    }

    /// Convenience computed variable for an inset setting that hides a cell's separator by pushing it off the edge of the screen.
    /// This needs to be computed because the frame size changes on orientation change.
    var insetsForHiddenCellSeparator: UIEdgeInsets {
        return .init(top: 0, left: tableView.frame.size.width, bottom: 0, right: 0).flippedForRightToLeftLayoutDirection()
    }

    /// returns the height of the navigation bar + the status bar.
    var topBarHeight: CGFloat {
        return (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
            (navigationController?.navigationBar.frame.height ?? 0.0)
    }

    /// determines the threshold for the content offset on whether the content has scrolled.
    /// for translucent navigation bars, the content view spans behind the status bar and navigation bar so we'd have to account for that.
    var contentScrollThreshold: CGFloat {
        (navigationController?.navigationBar.isTranslucent ?? false) ? -topBarHeight : 0
    }

    func configureNavigationBar() {
        if #available(iOS 15, *) {
            // In iOS 15, to apply visual blur only when content is scrolled, keep the scrollEdgeAppearance unchanged as it applies to ALL navigation bars.
            navigationItem.standardAppearance = blurredBarAppearance
        } else {
            // For iOS 14 and below, scrollEdgeAppearance only affects large title navigation bars. Therefore we need to manually detect if the content
            // has been scrolled and change the appearance accordingly.
            updateNavigationBarAppearance()
        }

        navigationController?.navigationBar.isTranslucent = true

        configureEditButtonItem()
    }

    /// Updates the navigation bar style based on the `isBlurred` boolean parameter. The intent is to show a visual blur effect when the content is scrolled,
    /// but reverts to opaque style when the scroll position is at the top. This method may be called multiple times since it's triggered by the `didSet`
    /// property observer on the `isContentScrolled` property.
    func updateNavigationBarAppearance(isBlurred: Bool = false) {
        navigationItem.standardAppearance = isBlurred ? blurredBarAppearance : opaqueBarAppearance
    }

    func configureEditButtonItem() {
        navigationItem.rightBarButtonItem = comment.canModerate ? UIBarButtonItem(barButtonSystemItem: .edit,
                                                                                  target: self,
                                                                                  action: #selector(editButtonTapped)) : nil
    }

    func configureTable() {
        // get rid of the separator line for the last cell.
        tableView.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: tableView.frame.size.width, height: Constants.tableBottomMargin))

        // assign 20pt leading inset to the table view, as per the design.
        // note that by default, the system assigns 16pt inset for .phone, and 20pt for .pad idioms.
        if UIDevice.current.userInterfaceIdiom == .phone {
            tableView.directionalLayoutMargins.leading = Constants.tableLeadingInset
        }

        tableView.register(CommentContentTableViewCell.defaultNib, forCellReuseIdentifier: CommentContentTableViewCell.defaultReuseID)
    }

    func configureRows() {
        // Header and content cells should always be visible, regardless of user roles.
        var rows: [RowType] = [.header, .content]

        // TODO: Detect if the comment has been replied.
        rows.append(.replyIndicator)

        // Author URL is publicly visible, but let's hide the row if it's empty or contains invalid URL.
        if comment.authorURL() != nil {
            rows.append(.text(title: .webAddressLabelText, detail: comment.authorUrlForDisplay(), image: Style.externalIconImage))
        }

        // Email address and IP address fields are only visible for Editor or Administrator roles, i.e. when `canModerate` is true.
        if comment.canModerate {
            // If the comment is submitted anonymously, the email field may be empty. In this case, let's hide it. Ref: https://git.io/JzKIt
            if !comment.author_email.isEmpty {
                rows.append(.text(title: .emailAddressLabelText, detail: comment.author_email))
            }

            rows.append(.text(title: .ipAddressLabelText, detail: comment.author_ip))

            if comment.deleteWillBePermanent() {
                rows.append(.deleteComment)
            }
        }

        self.rows = rows
    }

    /// Performs a complete refresh on the table and the row configuration, since some rows may be hidden due to changes to the Comment object.
    /// Use this method instead of directly calling the `reloadData` on the table view property.
    func refreshData() {
        configureEditButtonItem()
        configureRows()
        tableView.reloadData()
    }


    /// Checks if the index path is positioned before the delete button cell.
    func shouldHideCellSeparator(for indexPath: IndexPath) -> Bool {
        guard let deleteCellIndex = rows.firstIndex(of: .deleteComment) else {
            return false
        }

        return indexPath.row == deleteCellIndex - 1
    }

    // MARK: Cell configuration

    func configureHeaderCell() {
        // if the comment is a reply, show the author of the parent comment.
        if let parentComment = self.parentComment {
            headerCell.textLabel?.text = String(format: .replyCommentTitleFormat, parentComment.authorForDisplay())
            headerCell.detailTextLabel?.text = parentComment.contentPreviewForDisplay().trimmingCharacters(in: .whitespacesAndNewlines)
            return
        }

        // otherwise, if this is a comment to a post, show the post title instead.
        headerCell.textLabel?.text = .postCommentTitleText
        headerCell.detailTextLabel?.text = comment.titleForDisplay()
    }

    func configureContentCell(_ cell: CommentContentTableViewCell, comment: Comment) {
        cell.configure(with: comment) { _ in
            self.tableView.performBatchUpdates({})
        }

        cell.contentLinkTapAction = { url in
            // open all tapped links in web view.
            // TODO: Explore reusing URL handling logic from ReaderDetailCoordinator.
            self.openWebView(for: url)
        }

        cell.accessoryButtonAction = { senderView in
            self.shareCommentURL(senderView)
        }

        cell.likeButtonAction = {
            self.toggleCommentLike()
        }
    }

    func configuredTextCell(for row: RowType) -> UITableViewCell {
        guard case let .text(title, detail, image) = row else {
            return .init()
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: .textCellIdentifier) ?? .init(style: .subtitle, reuseIdentifier: .textCellIdentifier)

        cell.tintColor = Style.tintColor

        cell.textLabel?.font = Style.secondaryTextFont
        cell.textLabel?.textColor = Style.secondaryTextColor
        cell.textLabel?.text = title

        cell.detailTextLabel?.font = Style.textFont
        cell.detailTextLabel?.textColor = Style.textColor
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = detail.isEmpty ? " " : detail // prevent the cell from collapsing due to empty label text.

        cell.accessoryView = {
            guard let image = image else {
                return nil
            }
            return UIImageView(image: image)
        }()

        return cell
    }

    // MARK: Actions and navigations

    // Shows the comment thread with the parent comment highlighted.
    func navigateToParentComment() {
        guard let parentComment = parentComment,
              let blog = comment.blog else {
                  navigateToPost()
                  return
              }

        try? contentCoordinator.displayCommentsWithPostId(NSNumber(value: comment.postID),
                                                          siteID: blog.dotComID,
                                                          commentID: NSNumber(value: parentComment.commentID))
    }

    func navigateToPost() {
        guard let blog = comment.blog,
              let siteID = blog.dotComID,
              blog.supports(.wpComRESTAPI) else {
            let postPermalinkURL = URL(string: comment.post?.permaLink ?? "")
            openWebView(for: postPermalinkURL)
            return
        }

        let readerViewController = ReaderDetailViewController.controllerWithPostID(NSNumber(value: comment.postID), siteID: siteID, isFeed: false)
        navigationController?.pushFullscreenViewController(readerViewController, animated: true)
    }

    func openWebView(for url: URL?) {
        guard let url = url else {
            DDLogError("\(Self.classNameWithoutNamespaces()): Attempted to open an invalid URL [\(url?.absoluteString ?? "")]")
            return
        }

        let viewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url)
        let navigationControllerToPresent = UINavigationController(rootViewController: viewController)

        present(navigationControllerToPresent, animated: true, completion: nil)
    }

    @objc func editButtonTapped() {
        let editCommentTableViewController = EditCommentTableViewController(comment: comment, completion: { [weak self] comment, commentChanged in
            guard commentChanged else {
                return
            }

            self?.comment = comment
            self?.refreshData()
            self?.updateComment()
        })

        let navigationControllerToPresent = UINavigationController(rootViewController: editCommentTableViewController)
        navigationControllerToPresent.modalPresentationStyle = .fullScreen
        present(navigationControllerToPresent, animated: true)
    }

    func deleteButtonTapped() {
        deleteComment() { [weak self] success in
            if success {
                // Dismiss the view since the Comment no longer exists.
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }

    func updateComment() {
        // Regardless of success or failure track the user's intent to save a change.
        CommentAnalytics.trackCommentEdited(comment: comment)

        commentService.uploadComment(comment,
                                     success: { [weak self] in
                                        // The comment might have changed its approval status
                                        self?.refreshData()
                                     },
                                     failure: { [weak self] error in
                                        let message = NSLocalizedString("There has been an unexpected error while editing your comment",
                                                                        comment: "Error displayed if a comment fails to get updated")
                                        self?.displayNotice(title: message)
                                     })
    }

    func toggleCommentLike() {
        guard let siteID = comment.blog?.dotComID else {
            refreshData() // revert the like button state.
            return
        }

        if comment.isLiked {
            CommentAnalytics.trackCommentUnLiked(comment: comment)
        } else {
            CommentAnalytics.trackCommentLiked(comment: comment)
        }

        commentService.toggleLikeStatus(for: comment, siteID: siteID, success: {}, failure: { _ in
            self.refreshData() // revert the like button state.
        })
    }

    func visitAuthorURL() {
        guard let authorURL = comment.authorURL() else {
            return
        }

        openWebView(for: authorURL)
    }

    func shareCommentURL(_ senderView: UIView) {
        guard let commentURL = comment.commentURL() else {
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [commentURL as Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = senderView
        present(activityViewController, animated: true, completion: nil)
    }

}

// MARK: - Strings

private extension String {
    // MARK: Constants
    static let replyIndicatorCellIdentifier = "replyIndicatorCell"
    static let textCellIdentifier = "textCell"

    // MARK: Localization
    static let postCommentTitleText = NSLocalizedString("Comment on", comment: "Provides hint that the current screen displays a comment on a post. "
                                                            + "The title of the post will displayed below this string. "
                                                            + "Example: Comment on \n My First Post")
    static let replyCommentTitleFormat = NSLocalizedString("Reply to %1$@", comment: "Provides hint that the screen displays a reply to a comment."
                                                           + "%1$@ is a placeholder for the comment author that's been replied to."
                                                           + "Example: Reply to Pamela Nguyen")
    static let replyIndicatorLabelText = NSLocalizedString("You replied to this comment.", comment: "Informs that the user has replied to this comment.")
    static let webAddressLabelText = NSLocalizedString("Web address", comment: "Describes the web address section in the comment detail screen.")
    static let emailAddressLabelText = NSLocalizedString("Email address", comment: "Describes the email address section in the comment detail screen.")
    static let ipAddressLabelText = NSLocalizedString("IP address", comment: "Describes the IP address section in the comment detail screen.")
    static let deleteButtonText = NSLocalizedString("Delete Permanently", comment: "Title for button on the comment details page that deletes the comment when tapped.")
}


// MARK: - CommentModerationBarDelegate

extension CommentDetailViewController: CommentModerationBarDelegate {
    func statusChangedTo(_ commentStatus: CommentStatusType) {

        switch commentStatus {
        case .pending:
            unapproveComment()
        case .approved:
            approveComment()
        case .spam:
            spamComment()
        case .unapproved:
            trashComment()
        default:
            break
        }
    }
}

// MARK: - Comment Moderation Actions

private extension CommentDetailViewController {

    func unapproveComment() {
        CommentAnalytics.trackCommentUnApproved(comment: comment)

        commentService.unapproveComment(comment, success: { [weak self] in
            self?.showActionableNotice(title: ModerationMessages.pendingSuccess)
        }, failure: { [weak self] error in
            self?.displayNotice(title: ModerationMessages.pendingFail)
            self?.moderationBar?.commentStatus = CommentStatusType.typeForStatus(self?.comment.status)
        })
    }

    func approveComment() {
        CommentAnalytics.trackCommentApproved(comment: comment)

        commentService.approve(comment, success: { [weak self] in
            self?.showActionableNotice(title: ModerationMessages.approveSuccess)
        }, failure: { [weak self] error in
            self?.displayNotice(title: ModerationMessages.approveFail)
            self?.moderationBar?.commentStatus = CommentStatusType.typeForStatus(self?.comment.status)
        })
    }

    func spamComment() {
        CommentAnalytics.trackCommentSpammed(comment: comment)

        commentService.spamComment(comment, success: { [weak self] in
            self?.showActionableNotice(title: ModerationMessages.spamSuccess)
        }, failure: { [weak self] error in
            self?.displayNotice(title: ModerationMessages.spamFail)
            self?.moderationBar?.commentStatus = CommentStatusType.typeForStatus(self?.comment.status)
        })
    }

    func trashComment() {
        CommentAnalytics.trackCommentTrashed(comment: comment)

        commentService.trashComment(comment, success: { [weak self] in
            self?.showActionableNotice(title: ModerationMessages.trashSuccess)
        }, failure: { [weak self] error in
            self?.displayNotice(title: ModerationMessages.trashFail)
            self?.moderationBar?.commentStatus = CommentStatusType.typeForStatus(self?.comment.status)
        })
    }

    func deleteComment(completion: ((Bool) -> Void)? = nil) {
        CommentAnalytics.trackCommentTrashed(comment: comment)

        commentService.delete(comment, success: { [weak self] in
            self?.showActionableNotice(title: ModerationMessages.deleteSuccess)
            completion?(true)
        }, failure: { [weak self] error in
            self?.displayNotice(title: ModerationMessages.deleteFail)
            self?.moderationBar?.commentStatus = CommentStatusType.typeForStatus(self?.comment.status)
            completion?(false)
        })
    }

    func showActionableNotice(title: String) {
        guard viewIsVisible, !isLastInList else {
            displayNotice(title: title)
            return
        }

        displayActionableNotice(title: title, actionTitle: ModerationMessages.next, actionHandler: { [weak self] _ in
            self?.showNextComment()
        })
    }

    func showNextComment() {
        guard viewIsVisible else {
            return
        }

        delegate?.nextCommentSelected()
    }

    struct ModerationMessages {
        static let pendingSuccess = NSLocalizedString("Comment set to pending.", comment: "Message displayed when pending a comment succeeds.")
        static let pendingFail = NSLocalizedString("Error setting comment to pending.", comment: "Message displayed when pending a comment fails.")
        static let approveSuccess = NSLocalizedString("Comment approved.", comment: "Message displayed when approving a comment succeeds.")
        static let approveFail = NSLocalizedString("Error approving comment.", comment: "Message displayed when approving a comment fails.")
        static let spamSuccess = NSLocalizedString("Comment marked as spam.", comment: "Message displayed when spamming a comment succeeds.")
        static let spamFail = NSLocalizedString("Error marking comment as spam.", comment: "Message displayed when spamming a comment fails.")
        static let trashSuccess = NSLocalizedString("Comment moved to trash.", comment: "Message displayed when trashing a comment succeeds.")
        static let trashFail = NSLocalizedString("Error moving comment to trash.", comment: "Message displayed when trashing a comment fails.")
        static let deleteSuccess = NSLocalizedString("Comment deleted.", comment: "Message displayed when deleting a comment succeeds.")
        static let deleteFail = NSLocalizedString("Error deleting comment.", comment: "Message displayed when deleting a comment fails.")
        static let next = NSLocalizedString("Next", comment: "Next action on comment moderation snackbar.")
    }

}
