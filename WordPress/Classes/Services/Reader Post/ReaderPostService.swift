import Foundation
import WordPressKit

extension ReaderPostService {

    private var defaultAccount: WPAccount? {
        return try? WPAccount.lookupDefaultWordPressComAccount(in: managedObjectContext)
    }

    func fetchUnblockedPosts(
        topic: ReaderAbstractTopic,
        earlierThan date: Date,
        forceRetry: Bool = false,
        success: SuccessCallback? = nil,
        failure: ErrorCallback? = nil
    ) {
        let maxRetries = RetryOption.maxRetries
        let retryOption = forceRetry || !isSilentlyFetchingPosts ? RetryOption.enabled(retry: 0, maxRetries: maxRetries) : .disabled
        fetchUnblockedPostsWithRetries(topic: topic, earlierThan: date, retryOption: retryOption, success: success, failure: failure)
    }

    private func fetchUnblockedPostsWithRetries(
        topic: ReaderAbstractTopic,
        earlierThan date: Date,
        retryOption: RetryOption,
        success: SuccessCallback? = nil,
        failure: ErrorCallback? = nil
    ) {
        // Don't pass the algorithm if fetching a brand new list.
        // When fetching the beginning of a date ordered list the date passed is "now".
        // If the passed date is equal to the current date we know we're starting from scratch.
        let reqAlgorithm = date == Date() ? nil : topic.algorithm
        let remoteService = ReaderPostServiceRemote(wordPressComRestApi: apiForRequest())
        remoteService.fetchPosts(
            fromEndpoint: URL(string: topic.path),
            algorithm: reqAlgorithm,
            count: numberToSync(for: topic),
            before: date
        ) { posts, algorithm in
            self.processFetchedPostsForTopic(
                topic,
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

    func processFetchedPostsForTopic(
        _ topic: ReaderAbstractTopic,
        remotePosts posts: [Any],
        earlierThan date: Date,
        deletingEarlier: Bool,
        algorithm: String?,
        retryOption: RetryOption,
        success: SuccessCallback? = nil
    ) {
        // The passed-in topic might have missing data, the following code ensures fully realized object.
        guard let topic = try? self.managedObjectContext.existingObject(with: topic.objectID) as? ReaderAbstractTopic else {
            success?(0, true)
            return
        }

        // Update topic locally
        self.updateTopic(topic.objectID, withAlgorithm: algorithm)

        // Filter out blocked posts
        let filteredPosts = self.remotePostsByFilteringOutBlockedPosts(posts)
        let hasMore = self.canLoadMorePosts(for: topic, remotePosts: posts, in: managedObjectContext)

        // Construct a rank from the date provided
        let allPostsAreFilteredOut = filteredPosts.isEmpty && !posts.isEmpty
        if !allPostsAreFilteredOut {
            let rank = date.timeIntervalSinceReferenceDate as NSNumber
            self.mergePosts(filteredPosts, rankedLessThan: rank, forTopic: topic.objectID, deletingEarlier: deletingEarlier) { count, _ in
                success?(count, hasMore)
            }
        } else {
            success?(filteredPosts.count, hasMore)
        }

        // Silently fetch new content when the following conditions are fulfilled:
        //
        // 1. The retries count hasn't exceeded the limit.
        // 2. The fetched posts are all blocked.
        if case let .enabled(retry, maxRetries) = retryOption, let lastPost = posts.last as? RemoteReaderPost {
            let shouldContinueRetrying = filteredPosts.isEmpty && retry < maxRetries
            if shouldContinueRetrying {
                self.fetchUnblockedPostsWithRetries(
                    topic: topic,
                    earlierThan: lastPost.sortDate,
                    retryOption: .enabled(retry: retry + 1, maxRetries: maxRetries)
                )
            }
            self.isSilentlyFetchingPosts = shouldContinueRetrying
        }
    }

    private func remotePostsByFilteringOutBlockedPosts(_ remotePosts: [Any]) -> [Any] {
        let context = ContextManager.shared.mainContext

        guard let posts = remotePosts as? [RemoteReaderPost],
              let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context)
        else {
            return remotePosts
        }

        let blockedAuthors = Set(BlockedAuthor.find(.accountID(account.userID), context: context).map { $0.authorID })

        guard !blockedAuthors.isEmpty else {
            return posts
        }

        return posts.filter { !blockedAuthors.contains($0.authorID) }
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
