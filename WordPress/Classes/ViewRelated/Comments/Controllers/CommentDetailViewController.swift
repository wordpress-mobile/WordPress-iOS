import UIKit
import CoreData
import WordPressUI
import Aztec

// Notification sent when a Comment is permanently deleted so the Notifications list (NotificationsViewController) is immediately updated.
extension NSNotification.Name {
    static let NotificationCommentDeletedNotification = NSNotification.Name(rawValue: "NotificationCommentDeletedNotification")
}
let userInfoCommentIdKey = "commentID"

@objc protocol CommentDetailsDelegate: AnyObject {
    func nextCommentSelected()
}

class CommentDetailViewController: UIViewController, NoResultsViewHost {

    // MARK: Properties

    private let containerStackView = UIStackView()
    private let tableView = UITableView(frame: .zero, style: .plain)

    // Reply properties
    private var addCommentButton: CommentLargeButton?

    @objc weak var commentDelegate: CommentDetailsDelegate?
    private weak var notificationDelegate: CommentDetailsNotificationDelegate?

    private var comment: Comment
    private var isLastInList = true
    private var managedObjectContext: NSManagedObjectContext
    private var sections = [SectionType] ()
    private var rows = [RowType]()
    private var commentStatus: CommentStatusType? {
        didSet {
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
    private var notification: Notification?
    private let helper = ReaderCommentsHelper()

    private var isNotificationComment: Bool {
        notification != nil
    }

    private var viewIsVisible: Bool {
        return navigationController?.visibleViewController == self
    }

    private var siteID: NSNumber? {
        return comment.blog?.dotComID ?? notification?.metaSiteID
    }

    private var replyID: Int32 {
        return comment.replyID
    }

    private var isCommentReplied: Bool {
        replyID > 0
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
        attributedString.append(NSAttributedString(attachment: iconAttachment))
        attributedString.append(.init(string: " " + .replyIndicatorLabelText))
        attributedString.addAttributes(Style.ReplyIndicator.textAttributes, range: NSMakeRange(0, attributedString.length))

        // reverse the attributed strings in RTL direction.
        if view.effectiveUserInterfaceLayoutDirection == .rightToLeft {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.baseWritingDirection = .rightToLeft
            attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: .init(location: 0, length: attributedString.length))
        }

        cell.textLabel?.attributedText = attributedString
        cell.textLabel?.numberOfLines = 0
        cell.accessibilityIdentifier = .replyIndicatorCellIdentifier

        // setup constraints for textLabel to match the spacing specified in the design.
        if let textLabel = cell.textLabel {
            textLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textLabel.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                textLabel.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                textLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: Constants.replyIndicatorVerticalSpacing),
                textLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -Constants.replyIndicatorVerticalSpacing)
            ])
            textLabel.accessibilityIdentifier = .replyIndicatorTextIdentifier
        }

        return cell
    }()

    private lazy var deleteButtonCell: BorderedButtonTableViewCell = {
        let cell = BorderedButtonTableViewCell()
        cell.configure(buttonTitle: .deleteButtonText,
                       titleFont: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular),
                       normalColor: Constants.deleteButtonNormalColor,
                       highlightedColor: Constants.deleteButtonHighlightColor,
                       buttonInsets: Constants.deleteButtonInsets)
        cell.accessibilityIdentifier = .deleteButtonAccessibilityId
        cell.delegate = self
        return cell
    }()

    private lazy var trashButtonCell: BorderedButtonTableViewCell = {
        let cell = BorderedButtonTableViewCell()
        cell.configure(buttonTitle: .trashButtonText,
                       titleFont: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular),
                       normalColor: Constants.deleteButtonNormalColor,
                       highlightedColor: Constants.trashButtonHighlightColor,
                       borderColor: .clear,
                       buttonInsets: Constants.deleteButtonInsets,
                       backgroundColor: Constants.trashButtonBackgroundColor)
        cell.accessibilityIdentifier = .trashButtonAccessibilityId
        cell.delegate = self
        return cell
    }()

    private lazy var commentService: CommentService = {
        return .init(coreDataStack: ContextManager.shared)
    }()

    /// Ideally, this property should be configurable as one of the initialization parameters (to make this testable).
    /// However, since this class is still initialized in Objective-C files, it cannot declare `ContentCoordinator` as the init parameter, unless the protocol
    /// is `@objc`-ified. Let's move this to the init parameter once the caller has been converted to Swift.
    private lazy var contentCoordinator: ContentCoordinator = {
        return DefaultContentCoordinator(controller: self, context: managedObjectContext)
    }()

    // Sometimes the parent information of a comment reply notification is in the meta block.
    private var notificationParentComment: Comment? {
        guard let parentID = notification?.metaParentID,
              let siteID = notification?.metaSiteID,
              let blog = Blog.lookup(withID: siteID, in: managedObjectContext),
              let parentComment = blog.comment(withID: parentID) else {
                  return nil
              }

        return parentComment
    }

    private var parentComment: Comment? {
        guard comment.hasParentComment() else {
            return nil
        }

        if let blog = comment.blog {
            return blog.comment(withID: comment.parentID)

        }

        if let post = comment.post as? ReaderPost {
            return post.comment(withID: comment.parentID)
        }

        return nil
    }

    // MARK: Nav Bar Buttons

    private(set) lazy var editBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .edit,
                               target: self,
                               action: #selector(editButtonTapped))
        button.accessibilityLabel = NSLocalizedString("Edit comment", comment: "Accessibility label for button to edit a comment from a notification")
        return button
    }()

    private(set) lazy var shareBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: comment.allowsModeration()
            ? UIImage(systemName: "ellipsis")
            : UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareCommentURL)
        )
        button.accessibilityLabel = NSLocalizedString("Share comment", comment: "Accessibility label for button to share a comment from a notification")
        return button
    }()

    @objc var isSidebarModeEnabled = false

    // MARK: Initialization

    @objc init(comment: Comment,
               isLastInList: Bool,
               managedObjectContext: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {
        self.comment = comment
        self.commentStatus = CommentStatusType.typeForStatus(comment.status)
        self.isLastInList = isLastInList
        self.managedObjectContext = managedObjectContext

        super.init(nibName: nil, bundle: nil)
    }

    init(comment: Comment,
         notification: Notification,
         notificationDelegate: CommentDetailsNotificationDelegate?,
         managedObjectContext: NSManagedObjectContext = ContextManager.sharedInstance().mainContext) {
        self.comment = comment
        self.commentStatus = CommentStatusType.typeForStatus(comment.status)
        self.notification = notification
        self.notificationDelegate = notificationDelegate
        self.managedObjectContext = managedObjectContext

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        configureReplyView()
        configureNavigationBar()
        configureTable()
        configureSections()
        refreshCommentReplyIfNeeded()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // when an orientation change is triggered, recalculate the content cell's height.
        guard let contentRowIndex = rows.firstIndex(of: .content) else {
            return
        }
        tableView.reloadRows(at: [.init(row: contentRowIndex, section: .zero)], with: .fade)
    }

    // Update the Comment being displayed.
    @objc func displayComment(_ comment: Comment, isLastInList: Bool = true) {
        self.comment = comment
        self.isLastInList = isLastInList
        addCommentButton?.placeholder = String(format: .replyPlaceholderFormat, comment.authorForDisplay())
        refreshData()
        refreshCommentReplyIfNeeded()
    }

    // Update the Notification Comment being displayed.
    func refreshView(comment: Comment, notification: Notification) {
        hideNoResults()
        self.notification = notification
        displayComment(comment)
    }

    // Show an empty view with the given values.
    func showNoResultsView(title: String, subtitle: String? = nil, imageName: String? = nil, accessoryView: UIView? = nil) {
        hideNoResults()
        configureAndDisplayNoResults(on: tableView,
                                     title: title,
                                     subtitle: subtitle,
                                     image: imageName,
                                     accessoryView: accessoryView)
    }

}

// MARK: - Private Helpers

private extension CommentDetailViewController {

    typealias Style = WPStyleGuide.CommentDetail

    enum SectionType: Equatable {
        case content([RowType])
        case moderation([RowType])
    }

    enum RowType: Equatable {
        case header
        case content
        case replyIndicator
        case status(status: CommentStatusType)
        case deleteComment
    }

    struct Constants {
        static let tableHorizontalInset: CGFloat = 20.0
        static let tableBottomMargin: CGFloat = 40.0
        static let replyIndicatorVerticalSpacing: CGFloat = 14.0
        static let deleteButtonInsets = UIEdgeInsets(top: 4, left: 20, bottom: 4, right: 20)
        static let deleteButtonNormalColor = UIColor(light: UIAppColor.error, dark: UIAppColor.red(.shade40))
        static let deleteButtonHighlightColor: UIColor = .white
        static let trashButtonBackgroundColor = UIColor.quaternarySystemFill
        static let trashButtonHighlightColor: UIColor = UIColor.tertiarySystemFill
        static let notificationDetailSource = ["source": "notification_details"]
    }

    /// Convenience computed variable for an inset setting that hides a cell's separator by pushing it off the edge of the screen.
    /// This needs to be computed because the frame size changes on orientation change.
    /// NOTE: There's no need to flip the insets for RTL language, since it will be automatically applied.
    var insetsForHiddenCellSeparator: UIEdgeInsets {
        return .init(top: 0, left: -tableView.separatorInset.left, bottom: 0, right: tableView.frame.size.width)
    }

    func configureView() {
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerStackView)
        containerStackView.axis = .vertical
        containerStackView.addArrangedSubview(tableView)
        view.pinSubviewToAllEdges(containerStackView)
    }

    func configureNavigationBar() {
        configureNavBarButton()
    }

    func configureNavBarButton() {
        var barItems: [UIBarButtonItem] = []
        barItems.append(shareBarButtonItem)
        if comment.allowsModeration() {
            barItems.append(editBarButtonItem)
        }
        navigationItem.setRightBarButtonItems(barItems, animated: false)
    }

    func configureTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInsetReference = .fromAutomaticInsets

        // get rid of the separator line for the last cell.
        tableView.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: tableView.frame.size.width, height: Constants.tableBottomMargin))

        // assign 20pt leading inset to the table view, as per the design.
        tableView.directionalLayoutMargins = .init(top: tableView.directionalLayoutMargins.top,
                                                   leading: Constants.tableHorizontalInset,
                                                   bottom: tableView.directionalLayoutMargins.bottom,
                                                   trailing: Constants.tableHorizontalInset)

        tableView.register(CommentContentTableViewCell.defaultNib, forCellReuseIdentifier: CommentContentTableViewCell.defaultReuseID)
    }

    func configureContentRows() -> [RowType] {
        // Header and content cells should always be visible, regardless of user roles.
        var rows: [RowType] = [.header, .content]

        if isCommentReplied {
            rows.append(.replyIndicator)
        }

        return rows
    }

    func configureModerationRows() -> [RowType] {
        var rows: [RowType] = []
        rows.append(.status(status: .approved))
        rows.append(.status(status: .pending))
        rows.append(.status(status: .spam))

        rows.append(.deleteComment)

        return rows
    }

    func configureSections() {
        var sections: [SectionType] = []

        sections.append(.content(configureContentRows()))
        if comment.allowsModeration() {
            sections.append(.moderation(configureModerationRows()))
        }
        self.sections = sections
    }

    /// Performs a complete refresh on the table and the row configuration, since some rows may be hidden due to changes to the Comment object.
    /// Use this method instead of directly calling the `reloadData` on the table view property.
    func refreshData() {
        configureNavBarButton()
        configureSections()
        tableView.reloadData()
    }

    /// Checks if the index path is positioned before the delete button cell.
    func shouldHideCellSeparator(for indexPath: IndexPath) -> Bool {
        switch sections[indexPath.section] {
        case .content:
            return false
        case .moderation(let rows):
            guard let deleteCellIndex = rows.firstIndex(of: .deleteComment) else {
                return false
            }

            return indexPath.row == deleteCellIndex - 1
        }
    }

    // MARK: Cell configuration

    func configureHeaderCell() {
        // if the comment is a reply, show the author of the parent comment.
        if let parentComment = self.parentComment ?? notificationParentComment {
            return headerCell.configure(for: .reply(parentComment.authorForDisplay()),
                                        subtitle: parentComment.contentPreviewForDisplay().trimmingCharacters(in: .whitespacesAndNewlines))
        }

        // otherwise, if this is a comment to a post, show the post title instead.
        headerCell.configure(for: .post, subtitle: comment.titleForDisplay())
        headerCell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 54).isActive = true
    }

    func configureContentCell(_ cell: CommentContentTableViewCell, comment: Comment) {
        let viewModel = CommentCellViewModel(comment: comment, notification: notification)

        cell.configure(viewModel: viewModel, helper: helper) { [weak self] _ in
            self?.tableView.performBatchUpdates({})
        }

        cell.configureForCommentDetails()

        cell.contentLinkTapAction = { [weak self] url in
            // open all tapped links in web view.
            // TODO: Explore reusing URL handling logic from ReaderDetailCoordinator.
            self?.openWebView(for: url)
        }

        cell.accessoryButtonType = .info
        cell.isAccessoryButtonEnabled = true
        cell.accessoryButtonAction = { [weak self] senderView in
            self?.presentUserInfoSheet(senderView)
        }

        cell.replyButtonAction = { [weak self] in
            self?.buttonAddCommentTapped()
        }
    }

    func configuredStatusCell(for status: CommentStatusType) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .moderationCellIdentifier) ?? .init(style: .subtitle, reuseIdentifier: .moderationCellIdentifier)

        cell.selectionStyle = .none
        cell.tintColor = Style.tintColor

        cell.detailTextLabel?.font = Style.textFont
        cell.detailTextLabel?.textColor = Style.textColor
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = status.title

        cell.accessoryView = status == commentStatus ? UIImageView(image: .gridicon(.checkmark)) : nil

        return cell
    }

    // MARK: Data Sync

    func refreshCommentReplyIfNeeded() {
        guard let siteID = siteID?.intValue else {
            return
        }

        commentService.getLatestReplyID(for: Int(comment.commentID), siteID: siteID) { [weak self] replyID in
            guard let self else {
                return
            }

            // only perform Core Data updates when the replyID differs.
            guard replyID != self.comment.replyID else {
                return
            }

            let context = self.comment.managedObjectContext ?? ContextManager.sharedInstance().mainContext
            self.comment.replyID = Int32(replyID)
            ContextManager.sharedInstance().saveContextAndWait(context)

            self.updateReplyIndicator()

        } failure: { error in
            DDLogError("Failed fetching latest comment reply ID: \(String(describing: error))")
        }

    }

    func updateReplyIndicator() {

        // If there is a reply, add reply indicator if it is not being shown.
        if replyID > 0 && !rows.contains(.replyIndicator) {
            // Update the rows first so replyIndicator is present in `rows`.
            configureSections()
            guard let replyIndicatorRow = rows.firstIndex(of: .replyIndicator) else {
                tableView.reloadData()
                return
            }

            tableView.insertRows(at: [IndexPath(row: replyIndicatorRow, section: .zero)], with: .fade)
            return
        }

        // If there is not a reply, remove reply indicator if it is being shown.
        if replyID == 0 && rows.contains(.replyIndicator) {
            // Get the reply indicator row first before it is removed via `configureRows`.
            guard let replyIndicatorRow = rows.firstIndex(of: .replyIndicator) else {
                return
            }

            configureSections()
            tableView.deleteRows(at: [IndexPath(row: replyIndicatorRow, section: .zero)], with: .fade)
        }
    }

    // MARK: Actions and navigations

    // Shows the comment thread with the Notification comment highlighted.
    func navigateToNotificationComment() {
        if let blog = comment.blog,
           !blog.supports(.wpComRESTAPI) {
            openWebView(for: comment.commentURL())
            return
        }

        guard let siteID else {
            return
        }

        // Empty Back Button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)

        try? contentCoordinator.displayCommentsWithPostId(NSNumber(value: comment.postID),
                                                          siteID: siteID,
                                                          commentID: NSNumber(value: comment.commentID),
                                                          source: .commentNotification)
    }

    // Shows the comment thread with the parent comment highlighted.
    func navigateToParentComment() {
        guard let parentComment,
              let siteID,
              let blog = comment.blog,
              blog.supports(.wpComRESTAPI) else {
            let parentCommentURL = URL(string: parentComment?.link ?? "")
            openWebView(for: parentCommentURL)
            return
        }

        try? contentCoordinator.displayCommentsWithPostId(NSNumber(value: comment.postID),
                                                          siteID: siteID,
                                                          commentID: NSNumber(value: parentComment.commentID),
                                                          source: .mySiteComment)
    }

    func navigateToReplyComment() {
        guard let siteID,
              isCommentReplied else {
            return
        }

        try? contentCoordinator.displayCommentsWithPostId(NSNumber(value: comment.postID),
                                                          siteID: siteID,
                                                          commentID: NSNumber(value: replyID),
                                                          source: isNotificationComment ? .commentNotification : .mySiteComment)
    }

    func navigateToPost() {
        guard let blog = comment.blog,
              let siteID,
              blog.supports(.wpComRESTAPI) else {
            let postPermalinkURL = URL(string: comment.post?.permaLink ?? "")
            openWebView(for: postPermalinkURL)
            return
        }

        let readerViewController = ReaderDetailViewController.controllerWithPostID(NSNumber(value: comment.postID), siteID: siteID, isFeed: false)
        if isSidebarModeEnabled {
            let navigationController = UINavigationController(rootViewController: readerViewController)
            navigationController.modalPresentationStyle = .pageSheet
            present(navigationController, animated: true)
        } else {
            navigationController?.pushViewController(readerViewController, animated: true)
        }
    }

    func openWebView(for url: URL?) {
        guard let url else {
            DDLogError("\(Self.classNameWithoutNamespaces()): Attempted to open an invalid URL [\(url?.absoluteString ?? "")]")
            return
        }

        let viewController = WebViewControllerFactory.controllerAuthenticatedWithDefaultAccount(url: url, source: "comment_detail")
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

        CommentAnalytics.trackCommentEditorOpened(comment: comment)
        let navigationControllerToPresent = UINavigationController(rootViewController: editCommentTableViewController)
        present(navigationControllerToPresent, animated: true)
    }

    func deleteButtonTapped() {
        let commentID = comment.commentID
        deleteComment() { [weak self] success in
            if success {
                self?.postNotificationCommentDeleted(commentID)
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

    @objc func shareCommentURL(_ barButtonItem: UIBarButtonItem) {
        guard let commentURL = comment.commentURL() else {
            return
        }

        // track share intent.
        WPAnalytics.track(.siteCommentsCommentShared)

        let activityViewController = UIActivityViewController(activityItems: [commentURL as Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = barButtonItem
        present(activityViewController, animated: true, completion: nil)
    }

    func presentUserInfoSheet(_ senderView: UIView) {
        let viewModel = CommentDetailInfoViewModel(
            url: comment.authorURL(),
            urlToDisplay: comment.authorUrlForDisplay(),
            email: comment.author_email,
            ipAddress: comment.author_ip,
            isAdmin: comment.allowsModeration()
        )
        let viewController = CommentDetailInfoViewController(viewModel: viewModel)
        viewController.title = comment.authorForDisplay()
        viewModel.view = viewController
        viewController.show(from: self, sourceView: senderView)
    }
}

// MARK: - Strings

private extension String {
    // MARK: Constants
    static let replyIndicatorCellIdentifier = "reply-indicator-cell"
    static let replyIndicatorTextIdentifier = "reply-indicator-text"
    static let moderationCellIdentifier = "moderationCell"
    static let trashButtonAccessibilityId = "trash-comment-button"
    static let deleteButtonAccessibilityId = "delete-comment-button"

    // MARK: Localization
    static let replyPlaceholderFormat = NSLocalizedString("Reply to %1$@", comment: "Placeholder text for the reply text field."
                                                          + "%1$@ is a placeholder for the comment author."
                                                          + "Example: Reply to Pamela Nguyen")
    static let replyIndicatorLabelText = NSLocalizedString("You replied to this comment.", comment: "Informs that the user has replied to this comment.")
    static let deleteButtonText = NSLocalizedString("Delete Permanently", comment: "Title for button on the comment details page that deletes the comment when tapped.")
    static let trashButtonText = NSLocalizedString("Move to Trash", comment: "Title for button on the comment details page that moves the comment to trash when tapped.")
}

private extension CommentStatusType {
    var title: String? {
        switch self {
        case .pending:
            return NSLocalizedString("Pending", comment: "Button title for Pending comment state.")
        case .approved:
            return NSLocalizedString("Approved", comment: "Button title for Approved comment state.")
        case .spam:
            return NSLocalizedString("Spam", comment: "Button title for Spam comment state.")
        default:
            return nil
        }
    }
}

// MARK: - Comment Moderation Actions

private extension CommentDetailViewController {
    func unapproveComment() {
        isNotificationComment ? WPAppAnalytics.track(.notificationsCommentUnapproved,
                                                     withProperties: Constants.notificationDetailSource,
                                                     withBlogID: notification?.metaSiteID) :
                                CommentAnalytics.trackCommentUnApproved(comment: comment)

        commentService.unapproveComment(comment, success: { [weak self] in
            self?.showActionableNotice(title: ModerationMessages.pendingSuccess)
            self?.refreshData()
        }, failure: { [weak self] error in
            self?.displayNotice(title: ModerationMessages.pendingFail)
            self?.commentStatus = CommentStatusType.typeForStatus(self?.comment.status)
        })
    }

    func approveComment() {
        isNotificationComment ? WPAppAnalytics.track(.notificationsCommentApproved,
                                                     withProperties: Constants.notificationDetailSource,
                                                     withBlogID: notification?.metaSiteID) :
                                CommentAnalytics.trackCommentApproved(comment: comment)

        commentService.approve(comment, success: { [weak self] in
            self?.showActionableNotice(title: ModerationMessages.approveSuccess)
            self?.refreshData()
        }, failure: { [weak self] error in
            self?.displayNotice(title: ModerationMessages.approveFail)
            self?.commentStatus = CommentStatusType.typeForStatus(self?.comment.status)
        })
    }

    func spamComment() {
        isNotificationComment ? WPAppAnalytics.track(.notificationsCommentFlaggedAsSpam, withBlogID: notification?.metaSiteID) :
                                CommentAnalytics.trackCommentSpammed(comment: comment)

        commentService.spamComment(comment, success: { [weak self] in
            self?.showActionableNotice(title: ModerationMessages.spamSuccess)
            self?.refreshData()
        }, failure: { [weak self] error in
            self?.displayNotice(title: ModerationMessages.spamFail)
            self?.commentStatus = CommentStatusType.typeForStatus(self?.comment.status)
        })
    }

    func trashComment() {
        isNotificationComment ? WPAppAnalytics.track(.notificationsCommentTrashed, withBlogID: notification?.metaSiteID) :
                                CommentAnalytics.trackCommentTrashed(comment: comment)
        trashButtonCell.isLoading = true

        commentService.trashComment(comment, success: { [weak self] in
            self?.trashButtonCell.isLoading = false
            self?.showActionableNotice(title: ModerationMessages.trashSuccess)
            self?.refreshData()
        }, failure: { [weak self] error in
            self?.trashButtonCell.isLoading = false
            self?.displayNotice(title: ModerationMessages.trashFail)
            self?.commentStatus = CommentStatusType.typeForStatus(self?.comment.status)
        })
    }

    func deleteComment(completion: ((Bool) -> Void)? = nil) {
        CommentAnalytics.trackCommentTrashed(comment: comment)
        deleteButtonCell.isLoading = true

        commentService.delete(comment, success: { [weak self] in
            self?.showActionableNotice(title: ModerationMessages.deleteSuccess)
            completion?(true)
        }, failure: { [weak self] error in
            self?.deleteButtonCell.isLoading = false
            self?.displayNotice(title: ModerationMessages.deleteFail)
            completion?(false)
        })
    }

    func notifyDelegateCommentModerated() {
        notificationDelegate?.commentWasModerated(for: notification)
    }

    func postNotificationCommentDeleted(_ commentID: Int32) {
        NotificationCenter.default.post(name: .NotificationCommentDeletedNotification,
                                        object: nil,
                                        userInfo: [userInfoCommentIdKey: commentID])
    }

    func showActionableNotice(title: String) {
        guard !isNotificationComment else {
            return
        }

        guard viewIsVisible, !isLastInList else {
            displayNotice(title: title)
            return
        }

        // Dismiss any old notices to avoid stacked Next notices.
        dismissNotice()

        displayActionableNotice(title: title,
                                style: NormalNoticeStyle(showNextArrow: true),
                                actionTitle: ModerationMessages.next,
                                actionHandler: { [weak self] _ in
            self?.showNextComment()
        })
    }

    func showNextComment() {
        guard viewIsVisible else {
            return
        }

        WPAnalytics.track(.commentSnackbarNext)
        commentDelegate?.nextCommentSelected()
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

// MARK: - UITableView Methods

extension CommentDetailViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .content(let rows):
            return rows.count
        case .moderation(let rows):
            return rows.count
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = {
            let rows: [RowType]
            switch sections[indexPath.section] {
            case .content(let sectionRows), .moderation(let sectionRows):
                rows = sectionRows
            }

            switch rows[indexPath.row] {
            case .header:
                configureHeaderCell()
                return headerCell

            case .content:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentContentTableViewCell.defaultReuseID) as? CommentContentTableViewCell else {
                    return .init()
                }

                configureContentCell(cell, comment: comment)
                return cell

            case .replyIndicator:
                return replyIndicatorCell

            case .deleteComment:
                if comment.deleteWillBePermanent() {
                    return deleteButtonCell
                } else {
                    return trashButtonCell
                }

            case .status(let statusType):
                return configuredStatusCell(for: statusType)
            }
        }()

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sections[section] {
        case .content:
            return nil
        case .moderation:
            return NSLocalizedString("STATUS", comment: "Section title for the moderation section of the comment details screen.")
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = Style.tertiaryTextFont
        header.textLabel?.textColor = UIColor.secondaryLabel
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Hide cell separator if it's positioned before the delete button cell.
        cell.separatorInset = self.shouldHideCellSeparator(for: indexPath) ? self.insetsForHiddenCellSeparator : .zero
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch sections[indexPath.section] {
        case .content(let rows):
            switch rows[indexPath.row] {
            case .header:
                if isNotificationComment {
                    navigateToNotificationComment()
                } else {
                    comment.hasParentComment() ? navigateToParentComment() : navigateToPost()
                }
            case .replyIndicator:
                navigateToReplyComment()
            default:
                break
            }

        case .moderation(let rows):
            switch rows[indexPath.row] {
            case .status(let statusType):
                if commentStatus == statusType {
                    break
                }
                commentStatus = statusType
                notifyDelegateCommentModerated()

                guard let cell = tableView.cellForRow(at: indexPath) else {
                    return
                }
                let activityIndicator = UIActivityIndicatorView(style: .medium)
                cell.accessoryView = activityIndicator
                activityIndicator.startAnimating()
            default:
                break
            }
        }

    }
}

// MARK: - Reply Handling

private extension CommentDetailViewController {

    func configureReplyView() {
        let button = CommentLargeButton()

        button.placeholder = String(format: .replyPlaceholderFormat, comment.authorForDisplay())
        button.accessibilityHint = NSLocalizedString("Reply Text", comment: "Notifications Reply Accessibility Identifier")
        button.onTap = { [weak self] in
            self?.buttonAddCommentTapped()
        }
        button.isHidden = true
        containerStackView.addArrangedSubview(button)
        addCommentButton = button
    }

    @objc func buttonAddCommentTapped() {
        let viewModel = CommentCreateViewModel(replyingTo: comment) { [weak self] in
            try await self?.createReply(content: $0)
        }
        let composerVC = CommentCreateViewController(viewModel: viewModel)
        let navigationVC = UINavigationController(rootViewController: composerVC)
        present(navigationVC, animated: true)
    }

    @MainActor
    func createReply(content: String) async throws {
        isNotificationComment ? WPAppAnalytics.track(.notificationsCommentRepliedTo) :
                                CommentAnalytics.trackCommentRepliedTo(comment: comment)

        // If there is no Blog, try with the Post.
        guard comment.blog != nil else {
            try await createPostCommentReply(content: content)
            return
        }

        try await withUnsafeThrowingContinuation { continuation in
            commentService.createReply(for: comment, content: content) { reply in
                self.commentService.uploadComment(reply, success: { [weak self] in
                    self?.refreshCommentReplyIfNeeded()
                    continuation.resume()
                }, failure: { error in
                    DDLogError("Failed uploading comment reply: \(String(describing: error))")
                    continuation.resume(throwing: error ?? URLError(.unknown))
                })
            }
        }
    }

    @MainActor
    func createPostCommentReply(content: String) async throws {
        guard let post = comment.post as? ReaderPost else {
            return
        }
        try await withUnsafeThrowingContinuation { continuation in
            commentService.replyToHierarchicalComment(withID: NSNumber(value: comment.commentID),
                                                      post: post,
                                                      content: content,
                                                      success: { [weak self] in
                self?.refreshCommentReplyIfNeeded()
                continuation.resume()
            }, failure: { error in
                DDLogError("Failed creating post comment reply: \(String(describing: error))")
                continuation.resume(throwing: error ?? URLError(.unknown))
            })
        }
    }
}

// MARK: - BorderedButtonTableViewCellDelegate

extension CommentDetailViewController: BorderedButtonTableViewCellDelegate {

    func buttonTapped() {
        if comment.deleteWillBePermanent() {
            deleteButtonTapped()
        } else {
            commentStatus = .unapproved
        }
    }
}
