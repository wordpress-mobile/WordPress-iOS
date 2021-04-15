import Foundation
import UIKit
import WordPressKit


/// Convenience class that manages the data and display logic for likes.
/// This is intended to be used as replacement for table view delegate and data source.
class LikesListController: NSObject {

    private let formatter = FormattableContentFormatter()

    private let content: ContentIdentifier

    private let siteID: NSNumber

    private let notification: Notification?

    private let tableView: UITableView

    private var likingUsers: [RemoteUser] = []

    private weak var delegate: LikesListControllerDelegate?

    private lazy var postService: PostService = {
        PostService(managedObjectContext: ContextManager.shared.mainContext)
    }()

    private lazy var commentService: CommentService = {
        CommentService(managedObjectContext: ContextManager.shared.mainContext)
    }()

    private var isLoadingContent: Bool = false {
        didSet {
            isLoadingContent ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
            tableView.reloadData()
        }
    }

    // MARK: Views

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var loadingCell: UITableViewCell = {
        let cell = UITableViewCell()

        cell.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.safeCenterXAnchor.constraint(equalTo: cell.safeCenterXAnchor),
            activityIndicator.safeCenterYAnchor.constraint(equalTo: cell.safeCenterYAnchor)
        ])

        return cell
    }()

    // MARK: Lifecycle

    init?(tableView: UITableView,
          notification: Notification,
          delegate: LikesListControllerDelegate? = nil) {
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
    }

    // MARK: Methods

    /// Load likes data from remote, and display it in the table view.
    func refresh() {
        guard !isLoadingContent else {
            return
        }

        // shows the loading cell and prevents double refresh.
        isLoadingContent = true

        fetchLikes(success: { [weak self] users in
            self?.likingUsers = users ?? []
            self?.isLoadingContent = false
        }, failure: { [weak self] _ in
            // TODO: Handle error state
            self?.isLoadingContent = false
        })
    }

    /// Convenient method that fetches likes data depending on the notification's content type.
    /// - Parameters:
    ///   - success: Closure to be called when the fetch is successful.
    ///   - failure: Closure to be called when the fetch failed.
    private func fetchLikes(success: @escaping ([RemoteUser]?) -> Void, failure: @escaping (Error?) -> Void) {
        switch content {
        case .post(let postID):
            postService.getLikesForPostID(postID,
                                          siteID: siteID,
                                          success: success,
                                          failure: failure)
        case .comment(let commentID):
            commentService.getLikesForCommentID(commentID,
                                                siteID: siteID,
                                                success: success,
                                                failure: failure)
        }
    }
}

// MARK: - Table View Related

extension LikesListController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return Constants.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // header section
        if section == Constants.headerSectionIndex {
            return Constants.numberOfHeaderRows
        }

        // users section
        return isLoadingContent ? Constants.numberOfLoadingRows : likingUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Constants.headerSectionIndex {
            return headerCell()
        }

        if isLoadingContent {
            return loadingCell
        }

        return userCell(for: indexPath)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return LikeUserTableViewCell.estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == Constants.headerSectionIndex {
            delegate?.didSelectHeader()
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

// MARK: - Delegate Definitions

protocol LikesListControllerDelegate: class {
    /// Reports to the delegate that the header cell has been tapped.
    func didSelectHeader()

    /// Reports to the delegate that the user cell has been tapped.
    /// - Parameter user: A RemoteUser instance representing the user at the selected row.
    func didSelectUser(_ user: RemoteUser, at indexPath: IndexPath)
}

// MARK: - Private Definitions

private extension LikesListController {

    /// Convenient type that categorizes notification content and its ID.
    enum ContentIdentifier {
        case post(id: NSNumber)
        case comment(id: NSNumber)
    }

    struct Constants {
        static let numberOfSections = 2
        static let headerSectionIndex = 0
        static let headerRowIndex = 0
        static let numberOfHeaderRows = 1
        static let numberOfLoadingRows = 1
    }

}
