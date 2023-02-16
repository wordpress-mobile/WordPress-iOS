import Foundation

final class ReaderPostsLoader {

    // MARK: - Dependencies

    private let postService: ReaderPostService

    // MARK: - Init

    init(postService: ReaderPostService) {
        self.postService = postService
    }

    // MARK: - Fetch Posts

    func fetchPosts(for topic: ReaderAbstractTopic, earlierThan date: Date, success: SuccessCallback?, failure: ErrorCallback?) {
        self.postService.fetchPosts(for: topic, earlierThan: date, success: success, failure: failure)
    }

    // MARK: - Types

    typealias SuccessCallback = (_ count: Int, _ hasMore: Bool) -> Void
    typealias ErrorCallback = (_ error: Error?) -> Void
}
