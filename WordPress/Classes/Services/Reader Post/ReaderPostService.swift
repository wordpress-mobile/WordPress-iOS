import Foundation
import WordPressKit

extension ReaderPostService {

    // MARK: - Fetch Unblocked Posts

    /// Fetches a list of posts from the API and filters out the posts that belong to a blocked author.
    func fetchUnblockedPosts(
        topic: ReaderAbstractTopic,
        earlierThan date: Date,
        forceRetry: Bool = false,
        success: SuccessCallback? = nil,
        failure: ErrorCallback? = nil
    ) {
        let maxRetries = RetryOption.maxRetries
        let retryOption = forceRetry || !isSilentlyFetchingPosts ? RetryOption.enabled(retry: 0, maxRetries: maxRetries) : .disabled
        fetchUnblockedPostsWithRetries(topicObjectID: topic.objectID, earlierThan: date, retryOption: retryOption, success: success, failure: failure)
    }

    private func fetchUnblockedPostsWithRetries(
        topicObjectID: NSManagedObjectID,
        earlierThan date: Date,
        retryOption: RetryOption,
        success: SuccessCallback? = nil,
        failure: ErrorCallback? = nil
    ) {
        // Don't pass the algorithm if fetching a brand new list.
        // When fetching the beginning of a date ordered list the date passed is "now".
        // If the passed date is equal to the current date we know we're starting from scratch.
        guard let (reqAlgorithm, endpoint, count) = self.coreDataStack.performQuery({ context -> (String?, URL?, UInt)? in
            guard let topic = try? context.existingObject(with: topicObjectID) as? ReaderAbstractTopic else {
                return nil
            }
            return (
                date == Date() ? nil : topic.algorithm,
                URL(string: topic.path),
                self.numberToSync(for: topic)
            )
        }) else {
            success?(0, false)
            return
        }

        let remoteService = ReaderPostServiceRemote(wordPressComRestApi: apiForRequest())
        remoteService.fetchPosts(
            fromEndpoint: endpoint,
            algorithm: reqAlgorithm,
            count: count,
            before: date
        ) { posts, algorithm in
            self.processFetchedPostsForTopic(
                topicObjectID: topicObjectID,
                remotePosts: posts ?? [],
                earlierThan: date,
                deletingEarlier: false,
                algorithm: algorithm,
                retryOption: retryOption,
                success: success
            )
        } failure: { error in
            failure?(error)
        }
    }

    private func processFetchedPostsForTopic(
        topicObjectID: NSManagedObjectID,
        remotePosts posts: [Any],
        earlierThan date: Date,
        deletingEarlier: Bool,
        algorithm: String?,
        retryOption: RetryOption,
        success: SuccessCallback? = nil
    ) {
        // The passed-in topic might have missing data, the following code ensures fully realized object.
        guard let posts = posts as? [RemoteReaderPost]
        else {
            success?(0, true)
            return
        }

        // Update topic locally
        self.updateTopic(topicObjectID, withAlgorithm: algorithm)

        // Filter out blocked posts
        let filteredPosts = self.coreDataStack.performQuery { context in
            self.remotePostsByFilteringOutBlockedPosts(posts, in: context)
        }
        let hasMore = self.coreDataStack.performQuery { context in
            guard let topic = try? context.existingObject(with: topicObjectID) as? ReaderAbstractTopic else { return false }
            return self.canLoadMorePosts(for: topic, remotePosts: posts, in: context)
        }

        // Persist filtered posts locally.
        self.persistRemotePosts(
            filteredPosts: filteredPosts,
            allPosts: posts,
            topicObjectID: topicObjectID,
            beforeDate: date,
            deletingEarlier: deletingEarlier,
            hasMoreContent: hasMore,
            success: success
        )

        // Fetch more posts when certain conditions are fulfilled. See method documentation for more details.
        self.fetchMorePostsIfNeeded(filteredPosts: filteredPosts, allPosts: posts, topicObjectID: topicObjectID, retryOption: retryOption)
    }

    /// Persists the remote posts in Core Data.
    private func persistRemotePosts(
        filteredPosts: [RemoteReaderPost],
        allPosts posts: [RemoteReaderPost],
        topicObjectID: NSManagedObjectID,
        beforeDate date: Date,
        deletingEarlier: Bool,
        hasMoreContent hasMore: Bool,
        success: SuccessCallback? = nil
    ) {
        // We don't want to call `mergePosts` if all posts are blocked, henced filtered out.
        // Because this somehow causes existing posts in Core Data to be removed.
        let allPostsAreFilteredOut = filteredPosts.isEmpty && !posts.isEmpty
        if !allPostsAreFilteredOut {
            let rank = date.timeIntervalSinceReferenceDate as NSNumber
            self.mergePosts(filteredPosts, rankedLessThan: rank, forTopic: topicObjectID, deletingEarlier: deletingEarlier) { count, _ in
                success?(count, hasMore)
            }
        } else {
            success?(filteredPosts.count, hasMore)
        }
    }

    /// Silently fetch new content when the certain conditions are fulfiled.
    ///
    /// Those conditions are:
    ///
    /// 1. The retries count hasn't exceeded the limit.
    /// 2. The fetched posts all belong to a blocked author(s). Which means, they all posts are filtered out.
    private func fetchMorePostsIfNeeded(
        filteredPosts: [RemoteReaderPost],
        allPosts posts: [RemoteReaderPost],
        topicObjectID: NSManagedObjectID,
        retryOption: RetryOption
    ) {
        guard case let .enabled(retry, maxRetries) = retryOption, let lastPost = posts.last else {
            return
        }
        let shouldContinueRetrying = filteredPosts.isEmpty && retry < maxRetries
        if shouldContinueRetrying {
            self.fetchUnblockedPostsWithRetries(
                topicObjectID: topicObjectID,
                earlierThan: lastPost.sortDate,
                retryOption: .enabled(retry: retry + 1, maxRetries: maxRetries)
            )
        }
        self.isSilentlyFetchingPosts = shouldContinueRetrying
    }

    /// Takes a list of remote posts and returns a new list without the blocked posts.
    private func remotePostsByFilteringOutBlockedPosts(_ posts: [RemoteReaderPost], in context: NSManagedObjectContext) -> [RemoteReaderPost] {
        guard let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context),
              let accountID = account.userID
        else {
            return posts
        }

        let blockedAuthors = Set(BlockedAuthor.find(.accountID(accountID), context: context).map { $0.authorID })

        guard !blockedAuthors.isEmpty else {
            return posts
        }

        return posts.filter { post -> Bool in
            guard let authorID = post.authorID else {
                return true
            }
            return !blockedAuthors.contains(authorID)
        }
    }

    // MARK: - Types

    typealias SuccessCallback = (_ count: Int, _ hasMore: Bool) -> Void
    typealias ErrorCallback = (_ error: Error?) -> Void

    enum RetryOption {
        case disabled
        case enabled(retry: Int, maxRetries: Int)

        static let maxRetries = 15
    }
}
