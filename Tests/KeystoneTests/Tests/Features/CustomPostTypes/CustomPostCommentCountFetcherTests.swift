import Foundation
import Testing
import WordPressAPI
import WordPressAPIInternal

@testable import WordPress

/// The request closure records the params actually sent and hands back canned
/// pages, so the tests pin the requests made rather than only counting them.
@Suite("CustomPostCommentCountFetcher")
struct CustomPostCommentCountFetcherTests {
    /// The fallback fans out concurrently, so the recorder locks around its state.
    private final class Recorder: @unchecked Sendable {
        private let lock = NSLock()
        private var _params: [CommentListParams] = []
        var responses: [Int64?: Result<CustomPostCommentCountFetcher.Page, Error>] = [:]

        var params: [CommentListParams] {
            lock.withLock { _params }
        }

        /// Batch requests are keyed by `nil`, per-post fallbacks by their post id.
        func request(_ params: CommentListParams) throws -> CustomPostCommentCountFetcher.Page {
            lock.withLock { _params.append(params) }
            let key: Int64? = params.post.count == 1 && params.perPage == 1 ? params.post[0] : nil
            return try responses[key]!.get()
        }
    }

    private struct Failure: Error {}

    private func page(total: UInt32, postIDs: [Int64]) -> Result<CustomPostCommentCountFetcher.Page, Error> {
        .success(.init(postIDs: postIDs, total: total))
    }

    @Test("one request counts every post in the batch")
    func batch() async throws {
        let recorder = Recorder()
        recorder.responses[nil] = page(total: 3, postIDs: [5, 5, 7])
        let fetcher = CustomPostCommentCountFetcher(request: recorder.request)

        let counts = try await fetcher.fetchCommentCounts(for: [5, 7])

        #expect(counts == [5: 2, 7: 1])
        #expect(recorder.params.count == 1)
        #expect(recorder.params[0].post == [5, 7])
        #expect(recorder.params[0].perPage == 100)
    }

    @Test("a post with no comments counts zero rather than being omitted")
    func zeroForAbsent() async throws {
        let recorder = Recorder()
        recorder.responses[nil] = page(total: 1, postIDs: [5])
        let fetcher = CustomPostCommentCountFetcher(request: recorder.request)

        #expect(try await fetcher.fetchCommentCounts(for: [5, 7]) == [5: 1, 7: 0])
    }

    @Test("a batch that would undercount falls back to per-post totals")
    func fallback() async throws {
        let recorder = Recorder()
        recorder.responses[nil] = page(total: 500, postIDs: [5])
        recorder.responses[5] = page(total: 480, postIDs: [])
        recorder.responses[7] = page(total: 20, postIDs: [])
        let fetcher = CustomPostCommentCountFetcher(request: recorder.request)

        let counts = try await fetcher.fetchCommentCounts(for: [5, 7])

        #expect(counts == [5: 480, 7: 20])
        #expect(recorder.params.count == 3)
        #expect(Set(recorder.params.dropFirst().flatMap(\.post)) == [5, 7])
    }

    @Test("a per-post request that fails simply omits that post")
    func fallbackFailure() async throws {
        let recorder = Recorder()
        recorder.responses[nil] = page(total: 500, postIDs: [5])
        recorder.responses[5] = .failure(Failure())
        recorder.responses[7] = page(total: 20, postIDs: [])
        let fetcher = CustomPostCommentCountFetcher(request: recorder.request)

        #expect(try await fetcher.fetchCommentCounts(for: [5, 7]) == [7: 20])
    }

    @Test("a failed batch throws instead of fanning out into per-post requests")
    func batchFailure() async {
        let recorder = Recorder()
        recorder.responses[nil] = .failure(Failure())
        let fetcher = CustomPostCommentCountFetcher(request: recorder.request)

        await #expect(throws: Failure.self) {
            try await fetcher.fetchCommentCounts(for: [5, 7])
        }
        #expect(recorder.params.count == 1)
    }

    @Test("an empty request makes no network call")
    func empty() async throws {
        let recorder = Recorder()
        let fetcher = CustomPostCommentCountFetcher(request: recorder.request)

        #expect(try await fetcher.fetchCommentCounts(for: []).isEmpty)
        #expect(recorder.params.isEmpty)
    }
}
