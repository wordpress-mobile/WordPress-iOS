import Foundation
import UIKit
import WordPressKit


/// Convenience class that manages the data and display logic for likes.
/// This is intended to be used as replacement for table view delegate and data source.


@objc protocol LikesListControllerDelegate: AnyObject {
    /// Reports to the delegate that the header cell has been tapped.
    @objc optional func didSelectHeader()

    /// Reports to the delegate that the user cell has been tapped.
    /// - Parameter user: A LikeUser instance representing the user at the selected row.
    func didSelectUser(_ user: LikeUser, at indexPath: IndexPath)

    /// Ask the delegate to show an error view when fetching fails or there is no connection.
    func showErrorView(title: String, subtitle: String?)

    /// Send likes count to delegate.
    @objc optional func updatedTotalLikes(_ totalLikes: Int)
}

class LikesListController: NSObject {

    private let formatter = FormattableContentFormatter()
    private let content: ContentIdentifier
    private let siteID: NSNumber
    private var notification: Notification? = nil
    private var readerPost: ReaderPost? = nil
    private let tableView: UITableView
    private var loadingIndicator = UIActivityIndicatorView()
    private weak var delegate: LikesListControllerDelegate?

    // Used to control pagination.
    private var isFirstLoad = true
    private var totalLikes = 0
    private var totalLikesFetched = 0
    private var lastFetchedDate: String?
    private var excludeUserIDs: [NSNumber]?

    private let errorTitle = NSLocalizedString("Error loading likes",
                                               comment: "Text displayed when there is a failure loading notification likes.")

    private var hasMoreLikes: Bool {
        return totalLikesFetched < totalLikes
    }

    private var isLoadingContent = false {
        didSet {
            if isLoadingContent != oldValue {
                isLoadingContent ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
                // Refresh the footer view's frame
                tableView.tableFooterView = loadingIndicator
            }
        }
    }

    private var likingUsers: [LikeUser] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    private lazy var postService: PostService = {
        PostService(managedObjectContext: ContextManager.shared.mainContext)
    }()

    private lazy var commentService: CommentService = {
        CommentService(managedObjectContext: ContextManager.shared.mainContext)
    }()

    // Notification Likes has a table header. Post Likes does not.
    // Thus this is used to determine table layout depending on which is being shown.
    private var showingNotificationLikes: Bool {
        return notification != nil
    }

    private var usersSectionIndex: Int {
        return showingNotificationLikes ? 1 : 0
    }

    private var numberOfSections: Int {
        return showingNotificationLikes ? 2 : 1
    }

    // MARK: Init

    /// Init with Notification
    ///
    init?(tableView: UITableView, notification: Notification, delegate: LikesListControllerDelegate? = nil) {

        guard let siteID = notification.metaSiteID else {
            return nil
        }

        switch notification.kind {
        case .like:
            // post likes
            guard let postID = notification.metaPostID else {
                return nil
            }
            content = .post(id: postID)

        case .commentLike:
            // comment likes
            guard let commentID = notification.metaCommentID else {
                return nil
            }
            content = .comment(id: commentID)

        default:
            // other notification kinds are not supported
            return nil
        }

        self.notification = notification
        self.siteID = siteID
        self.tableView = tableView
        self.delegate = delegate

        super.init()
        configureLoadingIndicator()
    }

    /// Init with ReaderPost
    ///
    init?(tableView: UITableView, post: ReaderPost, delegate: LikesListControllerDelegate? = nil) {

        guard let postID = post.postID else {
            return nil
        }

        content = .post(id: postID)
        readerPost = post
        siteID = post.siteID
        self.tableView = tableView
        self.delegate = delegate

        super.init()
        configureLoadingIndicator()
    }

    private func configureLoadingIndicator() {
        loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44)
    }

    // MARK: Methods

    /// Load likes data from remote, and display it in the table view.
    func refresh() {

        guard !isLoadingContent else {
            return
        }

        isLoadingContent = true

        if isFirstLoad {
            fetchStoredLikes()
        }

        guard ReachabilityUtils.isInternetReachable() else {
            isLoadingContent = false

            if likingUsers.isEmpty {
                delegate?.showErrorView(title: errorTitle, subtitle: nil)
            }

            return
        }

        fetchLikes(success: { [weak self] users, totalLikes, likesPerPage in
            guard let self = self else {
                return
            }

            if self.isFirstLoad {
                self.delegate?.updatedTotalLikes?(totalLikes)
            }

            self.likingUsers = users
            self.totalLikes = totalLikes
            self.totalLikesFetched = users.count
            self.lastFetchedDate = users.last?.dateLikedString

            if !self.isFirstLoad && !users.isEmpty {
                self.trackFetched(likesPerPage: likesPerPage)
            }

            self.isFirstLoad = false
            self.isLoadingContent = false
            self.trackUsersToExclude()
        }, failure: { [weak self] error in
            guard let self = self else {
                return
            }

            let errorMessage: String? = {
                // Get error message from API response if provided.
                if let error = error,
                   let message = (error as NSError).userInfo[WordPressComRestApi.ErrorKeyErrorMessage] as? String,
                   !message.isEmpty {
                    return message
                }
                return nil
            }()

            self.isLoadingContent = false
            self.delegate?.showErrorView(title: self.errorTitle, subtitle: errorMessage)
        })
    }

    private func trackFetched(likesPerPage: Int) {
        var properties: [String: Any] = [:]
        properties["source"] = showingNotificationLikes ? "notifications" : "reader"
        properties["per_page"] = likesPerPage

        if likesPerPage > 0 {
            properties["page"] = Int(ceil(Double(likingUsers.count) / Double(likesPerPage)))
        }

        WPAnalytics.track(.likeListFetchedMore, properties: properties)
    }

    /// Fetch Likes from Core Data depending on the notification's content type.
    private func fetchStoredLikes() {
        switch content {
        case .post(let postID):
            likingUsers = postService.likeUsersFor(postID: postID, siteID: siteID)
        case .comment(let commentID):
            likingUsers = commentService.likeUsersFor(commentID: commentID, siteID: siteID)
        }
    }

    /// Fetch Likes depending on the notification's content type.
    /// - Parameters:
    ///   - success: Closure to be called when the fetch is successful.
    ///   - failure: Closure to be called when the fetch failed.
    private func fetchLikes(success: @escaping ([LikeUser], Int, Int) -> Void, failure: @escaping (Error?) -> Void) {

        var beforeStr = lastFetchedDate

        if beforeStr != nil,
           let modifiedDate = modifiedBeforeDate() {
            // The endpoints expect a format like YYYY-MM-DD HH:MM:SS. It isn't expecting the T or Z, hence the replacingMatches calls.
            beforeStr = ISO8601DateFormatter().string(from: modifiedDate).replacingMatches(of: "T", with: " ").replacingMatches(of: "Z", with: "")
        }

        switch content {
        case .post(let postID):
            postService.getLikesFor(postID: postID,
                                    siteID: siteID,
                                    before: beforeStr,
                                    excludingIDs: excludeUserIDs,
                                    purgeExisting: isFirstLoad,
                                    success: success,
                                    failure: failure)
        case .comment(let commentID):
            commentService.getLikesFor(commentID: commentID,
                                       siteID: siteID,
                                       before: beforeStr,
                                       excludingIDs: excludeUserIDs,
                                       purgeExisting: isFirstLoad,
                                       success: success,
                                       failure: failure)
        }
    }

    // There is a scenario where multiple users might like a post/comment at the same time,
    // and then end up split between pages of results. So we'll track which users we've already
    // fetched for the lastFetchedDate, and send those to the endpoints to filter out of the response
    // so we don't get duplicates or gaps.
    private func trackUsersToExclude() {
        guard let modifiedDate = modifiedBeforeDate() else {
            return
        }

        var fetchedUsers = [LikeUser]()
        switch content {
        case .post(let postID):
            fetchedUsers = postService.likeUsersFor(postID: postID, siteID: siteID, after: modifiedDate)
        case .comment(let commentID):
            fetchedUsers = commentService.likeUsersFor(commentID: commentID, siteID: siteID, after: modifiedDate)
        }

        excludeUserIDs = fetchedUsers.map { NSNumber(value: $0.userID) }
    }

    private func modifiedBeforeDate() -> Date? {
        guard let lastDate = likingUsers.last?.dateLiked else {
            return nil
        }

        return Calendar.current.date(byAdding: .second, value: 1, to: lastDate)
    }

}

// MARK: - Table View Related

extension LikesListController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Header section
        if showingNotificationLikes && section == Constants.headerSectionIndex {
            return Constants.numberOfHeaderRows
        }

        // Users section
        return likingUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showingNotificationLikes && indexPath.section == Constants.headerSectionIndex {
            return headerCell()
        }

        return userCell(for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let isUsersSection = indexPath.section == usersSectionIndex
        let isLastRow = indexPath.row == totalLikesFetched - 1

        guard !isLoadingContent && hasMoreLikes && isUsersSection && isLastRow else {
            return
        }

        refresh()
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return LikeUserTableViewCell.estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if showingNotificationLikes && indexPath.section == Constants.headerSectionIndex {
            delegate?.didSelectHeader?()
            return
        }

        guard !isLoadingContent,
              let user = likingUsers[safe: indexPath.row] else {
            return
        }

        delegate?.didSelectUser(user, at: indexPath)
    }

}

// MARK: - Notification Cell Handling

private extension LikesListController {

    func headerCell() -> NoteBlockHeaderTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NoteBlockHeaderTableViewCell.reuseIdentifier()) as? NoteBlockHeaderTableViewCell,
              let group = notification?.headerAndBodyContentGroups[Constants.headerRowIndex] else {
            DDLogError("Error: couldn't get a header cell or FormattableContentGroup.")
            return NoteBlockHeaderTableViewCell()
        }

        setupHeaderCell(cell: cell, group: group)
        return cell
    }

    func setupHeaderCell(cell: NoteBlockHeaderTableViewCell, group: FormattableContentGroup) {
        cell.attributedHeaderTitle = nil
        cell.attributedHeaderDetails = nil

        guard let gravatarBlock: NotificationTextContent = group.blockOfKind(.image),
            let snippetBlock: NotificationTextContent = group.blockOfKind(.text) else {
                return
        }

        cell.attributedHeaderTitle = formatter.render(content: gravatarBlock, with: HeaderContentStyles())
        cell.attributedHeaderDetails = formatter.render(content: snippetBlock, with: HeaderDetailsContentStyles())

        // Download the Gravatar
        let mediaURL = gravatarBlock.media.first?.mediaURL
        cell.downloadAuthorAvatar(with: mediaURL)
    }

    func userCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let user = likingUsers[safe: indexPath.row],
              let cell = tableView.dequeueReusableCell(withIdentifier: LikeUserTableViewCell.defaultReuseID) as? LikeUserTableViewCell else {
            DDLogError("Failed dequeueing LikeUserTableViewCell")
            return UITableViewCell()
        }

        cell.configure(withUser: user, isLastRow: (indexPath.row == likingUsers.endIndex - 1))
        return cell
    }

}

// MARK: - Private Definitions

private extension LikesListController {

    /// Convenient type that categorizes notification content and its ID.
    enum ContentIdentifier {
        case post(id: NSNumber)
        case comment(id: NSNumber)
    }

    struct Constants {
        static let headerSectionIndex = 0
        static let headerRowIndex = 0
        static let numberOfHeaderRows = 1
    }

}
