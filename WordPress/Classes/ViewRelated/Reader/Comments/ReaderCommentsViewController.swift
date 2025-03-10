import Foundation
import UIKit
import SwiftUI
import WordPressShared
import WordPressUI

// Notification sent when a comment is moderated/edited to allow views that display Comments to update if necessary.
// Specifically, the Comments snippet on ReaderDetailViewController.
extension NSNotification.Name {
    static let ReaderCommentModifiedNotification = NSNotification.Name(rawValue: "ReaderCommentModifiedNotification")
}

enum ReaderCommentsSource: String {
    case postCard = "reader_post_card"
    case postDetails = "reader_post_details"
    case postDetailsComments = "reader_post_details_comments"
    case commentNotification = "comment_notification"
    case commentLikeNotification = "comment_like_notification"
    case mySiteComment = "my_site_comment"
    case activityLogDetail = "activity_log_detail"
    case postsList = "posts_list"
}

final class ReaderCommentsViewController: UIViewController, WPContentSyncHelperDelegate, ReaderCommentsFollowPresenterDelegate {
    var source: ReaderCommentsSource?
    var navigateToCommentID: NSNumber?
    var allowsPushingPostDetails = false

    private var post: ReaderPost?
    private var postID: NSNumber?
    private var siteID: NSNumber?

    private lazy var barButtonItemFollowConversation = UIBarButtonItem(title: Strings.follow, style: .plain, target: self, action: #selector(buttonFollowConversationTapped))
    private lazy var barButtonItemFollowingSettings = UIBarButtonItem(image: UIImage(systemName: "bell"), style: .plain, target: self, action: #selector(buttonEditNotificationSettingsTapped))
    private let activityIndicator = UIActivityIndicatorView()
    private var emptyStateView: UIView?
    private let buttonAddComment = CommentLargeButton()
    private var tableVC: ReaderCommentsTableViewController?

    private var fetchCommentsError: NSError?
    private var commentModified = false
    private var highlightedIndexPath: IndexPath?

    private var syncHelper: WPContentSyncHelper?
    private var followCommentsService: FollowCommentsService?
    private var readerCommentsFollowPresenter: ReaderCommentsFollowPresenter?

    let helper = ReaderCommentsHelper()

    init(post: ReaderPost) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }

    init(postID: NSNumber, siteID: NSNumber) {
        self.postID = postID
        self.siteID = siteID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        setupNavigationBar()
        setupView()
        refreshFollowButton()

        if let post {
            configure(with: post)
        } else {
            fetchPost()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refreshAndSync()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        dismissNotice()
        if commentModified {
            NotificationCenter.default.post(name: .ReaderCommentModifiedNotification, object: nil)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableVC?.setBottomInset(buttonAddComment.frame.size.height)
    }

    private func setupNavigationBar() {
        navigationItem.backButtonTitle = ""
        title = Strings.title
        navigationItem.largeTitleDisplayMode = .never
    }

    private func setupView() {
        buttonAddComment.onTap = { [weak self] in
            self?.buttonAddCommentTapped()
        }
        view.addSubview(buttonAddComment)
        buttonAddComment.pinEdges([.horizontal, .bottom])

        view.addSubview(activityIndicator)
        activityIndicator.pinCenter()
    }

    private func makeEmptyStateView(title: String, imageName: String?, description: String?) -> UIView {
        UIHostingView(view: EmptyStateView(label: {
            if let imageName {
                Label(title, image: imageName)
            } else {
                Text(title)
            }
        }, description: {
            if let description {
                Text(description)
            }
        }, actions: {
            EmptyView()
        }))
    }

    func getHeaderView() -> UIView? {
        guard allowsPushingPostDetails, let post else {
            return nil
        }
        return CommentTableHeaderView(
            title: post.titleForDisplay(),
            subtitle: .commentThread,
            showsDisclosureIndicator: allowsPushingPostDetails
        ) { [weak self] in
            self?.handleHeaderTapped()
        }
    }

    // MARK: - Fetch Post

    private func fetchPost() {
        guard let postID, let siteID else {
            return wpAssertionFailure("missing parameters")
        }

        let service = ReaderPostService(coreDataStack: ContextManager.shared)
        buttonAddComment.isHidden = true
        service.fetchPost(postID.uintValue, forSite: siteID.uintValue, isFeed: false, success: { [weak self] post in
            if let post {
                self?.buttonAddComment.isHidden = false
                self?.configure(with: post)
                self?.refreshAndSync()
            }
        }, failure: { [weak self] error in
            self?.fetchCommentsError = error as? NSError
            self?.tableVC?.setLoadingFooterHidden(true)
            self?.refreshTableViewAndNoResultsView()
        })
    }

    private func configure(with post: ReaderPost) {
        self.post = post

        if post.isWPCom || post.isJetpack {
            let tableVC = ReaderCommentsTableViewController(post: post)
            self.tableVC = tableVC
            tableVC.containerViewController = self
            addChild(tableVC)
            view.insertSubview(tableVC.view, belowSubview: buttonAddComment)
            tableVC.view.pinEdges()
            tableVC.didMove(toParent: self)

            self.syncHelper = WPContentSyncHelper()
            self.syncHelper?.delegate = self
        }

        followCommentsService = FollowCommentsService(post: post)
        readerCommentsFollowPresenter = ReaderCommentsFollowPresenter(post: post, delegate: self, presentingViewController: self)
    }

    // MARK: - Sync Comments

    private func refreshAndSync() {
        refreshFollowButton()
        refreshSubscriptionStatusIfNeeded()
        refreshReplyTextView()
        refreshTableViewAndNoResultsView()
        refreshEmptyStateView()
        syncHelper?.syncContent()
    }

    private func refreshFollowButton() {
        guard let post, post.canActuallySubscribeToComments else { return }
        navigationItem.rightBarButtonItem = post.isSubscribedComments ? barButtonItemFollowingSettings : barButtonItemFollowConversation
    }

    private func refreshEmptyStateView() {
        activityIndicator.stopAnimating()

        emptyStateView?.removeFromSuperview()
        emptyStateView = nil

        guard tableVC?.isEmpty == true || post == nil else {
            return
        }

        if (post == nil) || (syncHelper?.isSyncing ?? false) {
            activityIndicator.startAnimating()
        } else {
            let title = fetchCommentsError == nil ? Strings.emptyStateViewTitle : Strings.errorStateViewTitle
            var subtitle: String?
            if let error = fetchCommentsError, error.domain == WordPressComRestApiErrorDomain && error.code == WordPressComRestApiErrorCode.authorizationRequired.rawValue {
                subtitle = Strings.noPermission
            }
            let emptyStateView = makeEmptyStateView(title: title, imageName: "wp-illustration-reader-empty", description: subtitle)
            view.insertSubview(emptyStateView, belowSubview: buttonAddComment)
            emptyStateView.pinEdges()
            self.emptyStateView = emptyStateView
        }
    }

    private func refreshSubscriptionStatusIfNeeded() {
        followCommentsService?.fetchSubscriptionStatus(success: { [weak self] isSubscribed in
            guard let self, let post = self.post else { return }
            post.isSubscribedComments = isSubscribed
            self.refreshFollowButton()
            ContextManager.shared.save(ContextManager.shared.mainContext)
        }, failure: { error in
            DDLogError("Error fetching subscription status for post: \(error ?? URLError(.unknown))")
        })
    }

    private func refreshReplyTextView() {
        if let post {
            buttonAddComment.isCommentingClosed = !post.commentsOpen
        }
    }

    private func refreshTableViewAndNoResultsView() {
        refreshEmptyStateView()
        navigateToCommentIDIfNeeded()
    }

    // MARK: - WPContentSyncHelperDelegate

    func syncHelper(_ syncHelper: WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((Bool) -> Void)?, failure: ((NSError) -> Void)?) {
        guard let post else {
            return wpAssertionFailure("post missing")
        }

        self.fetchCommentsError = nil

        let service = CommentService(coreDataStack: ContextManager.shared)
        service.syncHierarchicalComments(for: post, page: 1, success: { hasMore, _ in
            success?(hasMore)
        }, failure: { failure?($0 as NSError? ?? NSError()) })

        refreshEmptyStateView()
    }

    func syncHelper(_ syncHelper: WPContentSyncHelper, syncMoreWithSuccess success: ((Bool) -> Void)?, failure: ((NSError) -> Void)?) {
        guard let post else {
            return wpAssertionFailure("post missing")
        }

        self.fetchCommentsError = nil
        self.tableVC?.setLoadingFooterHidden(false)

        let service = CommentService(coreDataStack: ContextManager.shared)
        let page = service.number(ofHierarchicalPagesSyncedforPost: post) + 1
        service.syncHierarchicalComments(for: post, page: UInt(page), success: { hasMore, _ in
            success?(hasMore)
        }, failure: { failure?($0 as NSError? ?? NSError()) })
    }

    func syncContentEnded(_ syncHelper: WPContentSyncHelper) {
        self.tableVC?.setLoadingFooterHidden(true)
        refreshTableViewAndNoResultsView()
    }

    func syncContentFailed(_ syncHelper: WPContentSyncHelper) {
        self.fetchCommentsError = NSError(domain: "", code: 0, userInfo: nil)
        self.tableVC?.setLoadingFooterHidden(true)
        refreshTableViewAndNoResultsView()
    }

    // MARK: - Actions

    private func buttonAddCommentTapped() {
        guard let post else {
            return wpAssertionFailure("post missing")
        }
        let viewModel = CommentCreateViewModel(post: post) { [weak self] in
            try await self?.sendComment($0)
        }
        showCommentComposer(viewModel: viewModel)
    }

    func didTapReply(comment: Comment) {
        let viewModel = CommentCreateViewModel(replyingTo: comment) { [weak self] in
            try await self?.sendComment($0, comment: comment)
        }
        showCommentComposer(viewModel: viewModel)
    }

    func handleHeaderTapped() {
        guard let post, allowsPushingPostDetails else {
            return
        }
        let controller = ReaderDetailViewController.controllerWithPost(post)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func presentWebViewController(with url: URL) {
        guard let post else {
            return wpAssertionFailure("post missing")
        }
        var linkURL = url
        if let components = URLComponents(string: url.absoluteString), components.host == nil {
            linkURL = components.url(relativeTo: URL(string: post.blogURL)) ?? linkURL
        }
        let configuration = WebViewControllerConfiguration(url: linkURL)
        configuration.authenticateWithDefaultAccount()
        configuration.addsWPComReferrer = true
        let webVC = WebViewControllerFactory.controller(
            configuration: configuration,
            source: "reader_comments"
        )
        let navigationVC = UINavigationController(rootViewController: webVC)
        self.present(navigationVC, animated: true, completion: nil)
    }

    @objc private func buttonFollowConversationTapped() {
        readerCommentsFollowPresenter?.handleFollowConversationButtonTapped()
    }

    @objc private func buttonEditNotificationSettingsTapped() {
        readerCommentsFollowPresenter?.showNotificationSheet(sourceBarButtonItem: navigationItem.rightBarButtonItem)
    }

    func loadMore() {
        if let syncHelper, syncHelper.hasMoreContent {
            syncHelper.syncMoreContent()
        }
    }

    // MARK: - Configure

    func configureContentCell(
        _ cell: CommentContentTableViewCell,
        viewModel: CommentCellViewModel,
        indexPath: IndexPath,
        tableView: UITableView
    ) {
        let comment = viewModel.comment
        cell.badgeTitle = comment.isFromPostAuthor() ? .authorBadgeText : nil
        cell.depth = Int(comment.depth)

        let isModerationEnabled = comment.allowsModeration()
        cell.accessoryButton.showsMenuAsPrimaryAction = isModerationEnabled
        cell.accessoryButton.menu = isModerationEnabled ? menu(for: comment, indexPath: indexPath, tableView: tableView, sourceView: cell.accessoryButton) : nil
        cell.configure(viewModel: viewModel, helper: helper) { [weak tableView] _ in
            guard let tableView else { return }

            if tableView.alpha == 0 {
                UIView.animate(withDuration: 0.2, delay: 0.1) { // Add 100 ms to let other cells a chance to render
                    tableView.alpha = 1
                }
            }
            UIView.setAnimationsEnabled(false)
            tableView.performBatchUpdates({})
            UIView.setAnimationsEnabled(true)
        }

        cell.isEmphasized = indexPath == highlightedIndexPath
        cell.accessoryButtonAction = { [weak self] sourceView in
            self?.shareComment(comment, sourceView: sourceView)
        }
        cell.replyButtonAction = { [weak self] in
            self?.didTapReply(comment: comment)
        }
        cell.contentLinkTapAction = { [weak self] url in
            self?.presentWebViewController(with: url)
        }
    }

    /// Opens a share sheet, prompting the user to share the URL of the provided comment.
    ///
    func shareComment(_ comment: Comment, sourceView: UIView?) {
        guard let commentURL = comment.commentURL() else {
            return
        }

        // track share intent.
        WPAnalytics.track(.readerArticleCommentShared)

        let activityViewController = UIActivityViewController(activityItems: [commentURL as Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sourceView
        present(activityViewController, animated: true, completion: nil)
    }

    // MARK: - ReaderCommentsFollowPresenterDelegate Methods

    func followConversationComplete(success: Bool, post: ReaderPost) {
        refreshFollowButton()
    }

    func toggleNotificationComplete(success: Bool, post: ReaderPost) {
        // Do nothing
    }

    // MARK: - Misc

    func highlightCommentCell(at indexPath: IndexPath) {
        guard let tableView = tableVC?.tableView else {
            return
        }
        if let highlightedIndexPath, let cell = tableView.cellForRow(at: highlightedIndexPath) as? CommentContentTableViewCell {
            cell.isEmphasized = false
        }
        if let cell = tableView.cellForRow(at: indexPath) as? CommentContentTableViewCell {
            cell.isEmphasized = true
        }
        self.highlightedIndexPath = indexPath
    }

    private func navigateToCommentIDIfNeeded() {
        guard let navigateToCommentID, let tableVC else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            if tableVC.scrollToComment(withID: navigateToCommentID) {
                self.navigateToCommentID = nil
            }
        }
    }

    // MARK: - Tracking

    private func trackCommentsOpened() {
        var properties: [AnyHashable: Any] = [
            WPAppAnalyticsKeySource: source?.rawValue ?? "unknown"
        ]
        if let post {
            properties[WPAppAnalyticsKeyPostID] = post.postID
            properties[WPAppAnalyticsKeyBlogID] = post.siteID
        } else {
            if let postID {
                properties[WPAppAnalyticsKeyPostID] = postID
            }
            if let siteID {
                properties[WPAppAnalyticsKeyBlogID] = siteID
            }
        }
        WPAnalytics.trackReader(.readerArticleCommentsOpened, properties: properties)
    }

    private func trackReply(isReplyingToComment: Bool) {
        guard let post else { return }

        let railcar = post.railcarDictionary()
        var properties: [String: Any] = [
            WPAppAnalyticsKeyBlogID: post.siteID ?? 0,
            WPAppAnalyticsKeyPostID: post.postID ?? 0,
            WPAppAnalyticsKeyIsJetpack: post.isJetpack,
            WPAppAnalyticsKeyReplyingTo: isReplyingToComment ? "comment" : "post"
        ]

        if let feedID = post.feedID, let feedItemID = post.feedItemID {
            properties[WPAppAnalyticsKeyFeedID] = feedID
            properties[WPAppAnalyticsKeyFeedItemID] = feedItemID
        }

        WPAnalytics.trackReaderStat(.readerArticleCommentedOn, properties: properties)

        if let railcar {
            WPAppAnalytics.trackTrainTracksInteraction(.trainTracksInteract, withProperties: railcar)
        }
    }
}

extension ReaderCommentsViewController {
    func showCommentComposer(viewModel: CommentCreateViewModel) {
        let composerVC = CommentCreateViewController(viewModel: viewModel)
        let navigationVC = UINavigationController(rootViewController: composerVC)
        present(navigationVC, animated: true)
    }

    @MainActor
    func sendComment(_ content: String, comment: Comment? = nil) async throws {
        guard let post = self.post else {
            throw URLError(.unknown)
        }
        return try await withUnsafeThrowingContinuation { [weak self] continuation in
            let service = CommentService(coreDataStack: ContextManager.shared)
            if let comment {
                service.replyToHierarchicalComment(withID: comment.commentID as NSNumber, post: post, content: content) {
                    self?.trackReply(isReplyingToComment: true)
                    continuation.resume()
                } failure: {
                    continuation.resume(throwing: $0 ?? URLError(.unknown))
                }
            } else {
                service.reply(to: post, content: content) {
                    self?.trackReply(isReplyingToComment: false)
                    continuation.resume()
                } failure: {
                    continuation.resume(throwing: $0 ?? URLError(.unknown))
                }
            }
        }
    }
}

// MARK: - Popover Presentation Delegate

extension ReaderCommentsViewController: UIPopoverPresentationControllerDelegate {
    // Force popover views to be presented as a popover (instead of being presented as a form sheet on iPhones).
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

// MARK: - Private Helpers

private extension ReaderCommentsViewController {
    var commentService: CommentService {
        return CommentService(coreDataStack: ContextManager.shared)
    }

    /// Returns a `UIMenu` structure to be displayed when the accessory button is tapped.
    /// Note that this should only be called on iOS version 14 and above.
    ///
    /// For example, given an comment menu list `[[Foo, Bar], [Baz]]`, it will generate a menu as below:
    ///     ________
    ///    | Foo   •|
    ///    | Bar   •|
    ///    |--------|
    ///    | Baz   •|
    ///     --------
    ///
    func menu(for comment: Comment, indexPath: IndexPath, tableView: UITableView, sourceView: UIView?) -> UIMenu {
        let commentMenus = commentMenu(for: comment, indexPath: indexPath, tableView: tableView, sourceView: sourceView)
        return UIMenu(title: "", options: .displayInline, children: commentMenus.map {
            UIMenu(title: "", options: .displayInline, children: $0.map({ menu in menu.toAction }))
        })
    }

    /// Returns a list of array that each contains a menu item. Separators will be shown between each array. Note that
    /// the order of comment menu will determine the order of appearance for the corresponding menu element.
    ///
    func commentMenu(for comment: Comment, indexPath: IndexPath, tableView: UITableView, sourceView: UIView?) -> [[ReaderCommentMenu]] {
        return [
            [
                .unapprove { [weak self] in
                    self?.moderateComment(comment, status: .pending)
                },
                .spam { [weak self] in
                    self?.moderateComment(comment, status: .spam)
                },
                .trash { [weak self] in
                    self?.moderateComment(comment, status: .unapproved)
                }
            ],
            [
                .edit { [weak self, weak tableView] in
                    guard let tableView else { return }
                    self?.editMenuTapped(for: comment, indexPath: indexPath, tableView: tableView)
                },
                .share { [weak self] in
                    self?.shareComment(comment, sourceView: sourceView)
                }
            ]
        ]
    }

    func editMenuTapped(for comment: Comment, indexPath: IndexPath, tableView: UITableView) {
        let composerVC = CommentEditViewController(viewModel: CommentEditViewModel(comment: comment))
        let navigationVC = UINavigationController(rootViewController: composerVC)
        present(navigationVC, animated: true)
    }

    func moderateComment(_ comment: Comment, status: CommentStatusType) {
        let successBlock: (String) -> Void = { [weak self] noticeText in
            guard let self else {
                return
            }

            // when a comment is unapproved/spammed/trashed, ensure that all of the replies are hidden.
            self.commentService.updateRepliesVisibility(for: comment) {
                self.commentModified = true
                self.refreshEmptyStateView()

                // Dismiss any old notices to avoid stacked Undo notices.
                self.dismissNotice()

                // If the status is Approved, the user has undone a comment moderation.
                // So don't show the Undo option in this case.
                (status == .approved) ? self.displayNotice(title: noticeText) :
                                        self.showActionableNotice(title: noticeText, comment: comment)
            }
        }

        switch status {
        case .pending:
            commentService.unapproveComment(comment) {
                successBlock(.pendingSuccess)
            } failure: { [weak self] _ in
                self?.displayNotice(title: .pendingFailed)
            }

        case .spam:
            commentService.spamComment(comment) {
                successBlock(.spamSuccess)
            } failure: { [weak self] _ in
                self?.displayNotice(title: .spamFailed)
            }

        case .unapproved: // trash
            commentService.trashComment(comment) {
                successBlock(.trashSuccess)
            } failure: { [weak self] _ in
                self?.displayNotice(title: .trashFailed)
            }
        case .approved:
            commentService.approve(comment) {
                successBlock(.approveSuccess)
            } failure: { [weak self] _ in
                self?.displayNotice(title: .approveFailed)
            }
        default:
            break
        }
    }

    func showActionableNotice(title: String, comment: Comment) {
        displayActionableNotice(title: title,
                                actionTitle: .undoActionTitle,
                                actionHandler: { [weak self] _ in
            // Set the Comment's status back to Approved when the user selects Undo on the notice.
            self?.moderateComment(comment, status: .approved)
        })
    }
}

// MARK: - Reader Comment Menu

/// Represents the available menu when the ellipsis accessory button on the comment cell is tapped.
enum ReaderCommentMenu {
    case unapprove(_ handler: () -> Void)
    case spam(_ handler: () -> Void)
    case trash(_ handler: () -> Void)
    case edit(_ handler: () -> Void)
    case share(_ handler: () -> Void)

    var title: String {
        switch self {
        case .unapprove:
            return NSLocalizedString("Unapprove", comment: "Unapproves a comment")
        case .spam:
            return NSLocalizedString("Mark as Spam", comment: "Marks comment as spam")
        case .trash:
            return NSLocalizedString("Move to Trash", comment: "Trashes the comment")
        case .edit:
            return NSLocalizedString("Edit", comment: "Edits the comment")
        case .share:
            return SharedStrings.Button.share
        }
    }

    var image: UIImage? {
        switch self {
        case .unapprove:
            return .init(systemName: "x.circle")
        case .spam:
            return .init(systemName: "exclamationmark.octagon")
        case .trash:
            return .init(systemName: "trash")
        case .edit:
            return .init(systemName: "pencil")
        case .share:
            return .init(systemName: "square.and.arrow.up")
        }
    }

    var toAction: UIAction {
        switch self {
        case .unapprove(let handler),
                .spam(let handler),
                .trash(let handler),
                .edit(let handler),
                .share(let handler):
            return UIAction(title: title, image: image) { _ in
                handler()
            }
        }
    }
}

// MARK: - Localization

private enum Strings {
    static let title = NSLocalizedString("reader.comments.title", value: "Comments", comment: "Navigation title")
    static let errorStateViewTitle = NSLocalizedString("reader.comments.errorLoadingComments", value: "There has been an unexpected error while loading the comments.", comment: "Empty state view title")
    static let emptyStateViewTitle = NSLocalizedString("reader.comments.emptyStateTitle", value: "Be the first to leave a comment.", comment: "Empty state view title")
    static let noPermission = NSLocalizedString("reader.comments.noPermissionToViewPrivateBlog", value: "You don't have permission to view this private blog.", comment: "Error message that informs reader comments from a private blog cannot be fetched.")
    static let follow = NSLocalizedString("reader.comments.buttonFollow", value: "Follow", comment: "Button title. Follow the comments on a post.")
    static let followingSettings = NSLocalizedString("reader.comments.followingSettingAccessibilityIdentifier", value: "Open notification settings for the post", comment: "VoiceOver hint")
}

// TODO: (kean) change to Strings
private extension String {
    static let authorBadgeText = NSLocalizedString("Author", comment: "Title for a badge displayed beside the comment writer's name. "
                                                   + "Shown when the comment is written by the post author.")
    static let undoActionTitle = NSLocalizedString("Undo", comment: "Button title. Reverts a comment moderation action.")

    // moderation messages
    static let pendingSuccess = NSLocalizedString("Comment set to pending.", comment: "Message displayed when pending a comment succeeds.")
    static let pendingFailed = NSLocalizedString("Error setting comment to pending.", comment: "Message displayed when pending a comment fails.")
    static let spamSuccess = NSLocalizedString("Comment marked as spam.", comment: "Message displayed when spamming a comment succeeds.")
    static let spamFailed = NSLocalizedString("Error marking comment as spam.", comment: "Message displayed when spamming a comment fails.")
    static let trashSuccess = NSLocalizedString("Comment moved to trash.", comment: "Message displayed when trashing a comment succeeds.")
    static let trashFailed = NSLocalizedString("Error moving comment to trash.", comment: "Message displayed when trashing a comment fails.")
    static let approveSuccess = NSLocalizedString("Comment set to approved.", comment: "Message displayed when approving a comment succeeds.")
    static let approveFailed = NSLocalizedString("Error setting comment to approved.", comment: "Message displayed when approving a comment fails.")
}
