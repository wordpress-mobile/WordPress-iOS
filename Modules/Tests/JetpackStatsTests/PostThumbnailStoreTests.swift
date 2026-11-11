import Foundation
import Testing
@testable import JetpackStats

@Suite
@MainActor
struct PostThumbnailStoreTests {
    @Test("Resolves a screenful of rows with a single request")
    func gathersRowsIntoOneRequest() async throws {
        let service = PostThumbnailServiceMock()
        let store = PostThumbnailStore(service: service, batchSize: 25, batchDelay: .milliseconds(10))

        for postID in 1...10 {
            store.requestThumbnail(forPostID: postID)
        }

        try await waitUntil { store.thumbnails.count == 10 }
        #expect(await service.requestedBatches == [Array(1...10)])
    }

    @Test("Sends a request as soon as a batch fills, without waiting out the delay")
    func sendsFullBatchImmediately() async throws {
        let service = PostThumbnailServiceMock()
        // A delay long enough that only filling the batch can trigger the request.
        let store = PostThumbnailStore(service: service, batchSize: 3, batchDelay: .seconds(60))

        for postID in 1...3 {
            store.requestThumbnail(forPostID: postID)
        }

        try await waitUntil { store.thumbnails.count == 3 }
        #expect(await service.requestedBatches == [[1, 2, 3]])
    }

    @Test("Asks about a post only once, however often its row reappears")
    func asksAboutEachPostOnce() async throws {
        let service = PostThumbnailServiceMock()
        let store = PostThumbnailStore(service: service, batchSize: 25, batchDelay: .milliseconds(10))

        store.requestThumbnail(forPostID: 1)
        store.requestThumbnail(forPostID: 1)
        try await waitUntil { store.thumbnails.count == 1 }

        store.requestThumbnail(forPostID: 1)
        store.requestThumbnail(forPostID: 2)
        try await waitUntil { store.thumbnails.count == 2 }

        #expect(await service.requestedBatches == [[1], [2]])
    }

    @Test("Omits a post the site reports no featured image for")
    func omitsPostsWithoutAFeaturedImage() async throws {
        let service = PostThumbnailServiceMock(postIDsWithImage: [1])
        let store = PostThumbnailStore(service: service, batchSize: 25, batchDelay: .milliseconds(10))

        store.requestThumbnail(forPostID: 1)
        store.requestThumbnail(forPostID: 2)

        try await waitUntil { store.thumbnails.count == 1 }
        #expect(store.thumbnails[1] != nil)
        #expect(store.thumbnails[2] == nil)
    }

    @Test("Looks a post up again after a failed request")
    func retriesAfterAFailedRequest() async throws {
        let service = PostThumbnailServiceMock()
        await service.setFailing(true)
        let store = PostThumbnailStore(service: service, batchSize: 25, batchDelay: .milliseconds(10))

        store.requestThumbnail(forPostID: 1)
        try await waitUntil { await service.requestedBatches == [[1]] }

        await service.setFailing(false)

        // The service records the batch before the store hears that it failed, so keep
        // offering the ID until the store has forgotten it and takes it again.
        try await waitUntil {
            store.requestThumbnail(forPostID: 1)
            return store.thumbnails[1] != nil
        }
        #expect(await service.requestedBatches == [[1], [1]])
    }

    private func waitUntil(_ condition: () async -> Bool) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now + .seconds(2)
        while !(await condition()) {
            guard clock.now < deadline else {
                throw PostThumbnailStoreTestError.timedOut
            }
            try await Task.sleep(for: .milliseconds(5))
        }
    }
}

private enum PostThumbnailStoreTestError: Error {
    case timedOut
    case requestFailed
}

private actor PostThumbnailServiceMock: PostThumbnailService {
    private(set) var requestedBatches: [[Int]] = []

    /// The posts this site has a featured image for, or `nil` when every post has one.
    private let postIDsWithImage: Set<Int>?
    private var isFailing = false

    init(postIDsWithImage: Set<Int>? = nil) {
        self.postIDsWithImage = postIDsWithImage
    }

    func setFailing(_ isFailing: Bool) {
        self.isFailing = isFailing
    }

    func getFeaturedImageURLs(forPostIDs postIDs: [Int]) async throws -> [Int: URL] {
        requestedBatches.append(postIDs)

        if isFailing {
            throw PostThumbnailStoreTestError.requestFailed
        }

        let postIDsWithAnImage = postIDs.filter { postIDsWithImage?.contains($0) ?? true }
        return postIDsWithAnImage.reduce(into: [:]) { urls, postID in
            urls[postID] = URL(string: "https://example.com/\(postID).jpg")
        }
    }
}
