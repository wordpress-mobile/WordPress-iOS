import Combine
import Foundation
import WordPressData
import WordPressKit
import WordPressShared

/// The subset of `PostService`'s post-likes API the ``LikesListViewModel`` depends on.
///
/// A protocol seam keeps the view model testable: production uses `PostService`, while
/// tests provide a fake that records the pagination cursor without touching the network.
protocol PostLikesServing: AnyObject {
    func likeUsersFor(postID: NSNumber, siteID: NSNumber, after: Date?) -> [LikeUser]

    func getLikesFor(
        postID: NSNumber,
        siteID: NSNumber,
        count: Int,
        before: String?,
        excludingIDs: [NSNumber]?,
        purgeExisting: Bool,
        success: @escaping (([LikeUser], Int, Int) -> Void),
        failure: @escaping ((Error?) -> Void)
    )
}

extension PostService: PostLikesServing {}

/// Drives the shared SwiftUI likes list for the Stats and Reader post-likes screens.
///
/// This ports the post-likes fetch and pagination engine from `LikesListController`.
/// Comment likes remain Notifications-only and stay behind the legacy controller.
@MainActor
final class LikesListViewModel: ObservableObject {

    struct ErrorViewModel {
        let title: String
        let subtitle: String?
    }

    @Published private(set) var users: [LikeUser] = []
    @Published private(set) var totalLikes: Int
    @Published private(set) var isLoadingPage = false
    @Published private(set) var error: ErrorViewModel?

    private let siteID: NSNumber
    private let postID: NSNumber
    private let service: PostLikesServing

    // Pagination state ported from `LikesListController`.
    private var isFirstLoad = true
    private var totalLikesFetched = 0
    private var lastFetchedDate: String?
    private var excludeUserIDs: [NSNumber]?

    private let errorTitle = NSLocalizedString(
        "Error loading likes",
        comment: "Text displayed when there is a failure loading notification likes."
    )

    /// Whether another page can be fetched. Mirrors `LikesListController.hasMoreLikes`.
    var hasMoreLikes: Bool {
        totalLikesFetched < totalLikes
    }

    init(siteID: NSNumber, postID: NSNumber, totalLikes: Int, service: PostLikesServing? = nil) {
        self.siteID = siteID
        self.postID = postID
        self.totalLikes = totalLikes
        self.service = service ?? PostService(managedObjectContext: ContextManager.shared.mainContext)
    }

    convenience init?(post: ReaderPost, service: PostLikesServing? = nil) {
        guard let postID = post.postID, let siteID = post.siteID else {
            return nil
        }
        self.init(siteID: siteID, postID: postID, totalLikes: post.likeCount?.intValue ?? 0, service: service)
    }

    /// Loads the next page of likes. Called for the initial load and whenever the last
    /// row appears. Mirrors `LikesListController.refresh()`.
    func loadMore() {
        guard !isLoadingPage else {
            return
        }

        isLoadingPage = true
        error = nil

        if isFirstLoad {
            // Seed from Core Data so cached likes render immediately, before the remote refresh.
            users = service.likeUsersFor(postID: postID, siteID: siteID, after: nil)
        }

        guard ReachabilityUtils.isInternetReachable() else {
            isLoadingPage = false
            error = ErrorViewModel(title: errorTitle, subtitle: nil)
            return
        }

        let wasFirstLoad = isFirstLoad
        let before = modifiedBeforeString()

        service.getLikesFor(
            postID: postID,
            siteID: siteID,
            count: Constants.pageSize,
            before: before,
            excludingIDs: excludeUserIDs,
            purgeExisting: wasFirstLoad,
            success: { [weak self] users, totalLikes, likesPerPage in
                guard let self else {
                    return
                }

                self.users = users
                self.totalLikes = totalLikes
                self.totalLikesFetched = users.count
                self.lastFetchedDate = users.last?.dateLikedString

                if !wasFirstLoad && !users.isEmpty {
                    self.trackFetched(likesPerPage: likesPerPage)
                }

                self.isFirstLoad = false
                self.isLoadingPage = false
                self.trackUsersToExclude()
            },
            failure: { [weak self] error in
                guard let self else {
                    return
                }

                let subtitle: String? = {
                    guard let error = error as? NSError,
                        error.domain == WordPressComRestApiEndpointError.errorDomain,
                        error.code == WordPressComRestApiErrorCode.authorizationRequired.rawValue
                    else {
                        return nil
                    }
                    return Strings.privateBlogErrorMessage
                }()

                self.isLoadingPage = false
                self.error = ErrorViewModel(title: self.errorTitle, subtitle: subtitle)
            }
        )
    }

    /// Loads the next page when the last visible row appears, guarded so we do not
    /// re-fetch while a load is in flight or once every like has been retrieved.
    func loadMoreIfNeeded(displaying user: LikeUser) {
        guard !isLoadingPage, hasMoreLikes, user.objectID == users.last?.objectID else {
            return
        }
        loadMore()
    }

    // MARK: - Cursor

    /// The `before` value sent to the endpoint. Uses the last liker's `dateLiked` bumped
    /// by one second, formatted "YYYY-MM-DD HH:MM:SS" (the endpoint rejects the T/Z that
    /// `ISO8601DateFormatter` emits). Nil until a page has been fetched.
    private func modifiedBeforeString() -> String? {
        // `lastFetchedDate` only gates whether we page; the actual boundary is the +1s date.
        guard lastFetchedDate != nil, let modifiedDate = modifiedBeforeDate() else {
            return nil
        }

        return ISO8601DateFormatter()
            .string(from: modifiedDate)
            .replacingMatches(of: "T", with: " ")
            .replacingMatches(of: "Z", with: "")
    }

    // There is a scenario where multiple users might like a post at the same time and end
    // up split between pages. Track which users we already fetched at/after the boundary and
    // send those to the endpoint to filter out, so we get neither duplicates nor gaps.
    private func trackUsersToExclude() {
        guard let modifiedDate = modifiedBeforeDate() else {
            return
        }

        let fetchedUsers = service.likeUsersFor(postID: postID, siteID: siteID, after: modifiedDate)
        excludeUserIDs = fetchedUsers.map { NSNumber(value: $0.userID) }
    }

    private func modifiedBeforeDate() -> Date? {
        guard let lastDate = users.last?.dateLiked else {
            return nil
        }

        return Calendar.current.date(byAdding: .second, value: 1, to: lastDate)
    }

    // MARK: - Analytics

    private func trackFetched(likesPerPage: Int) {
        var properties: [String: Any] = [:]
        // The shared engine has always reported "reader" for both Stats and Reader post likes.
        properties["source"] = "reader"
        properties["per_page"] = likesPerPage

        if likesPerPage > 0 {
            properties["page"] = Int(ceil(Double(users.count) / Double(likesPerPage)))
        }

        WPAnalytics.track(.likeListFetchedMore, properties: properties)
    }

    private enum Constants {
        static let pageSize = 90
    }

    private enum Strings {
        static let privateBlogErrorMessage = NSLocalizedString(
            "likesListViewController.likesList.privateBlogErrorMessage",
            value: "You don't have permission to view this private blog.",
            comment: "Error message that informs likes from a private blog cannot be fetched."
        )
    }
}
