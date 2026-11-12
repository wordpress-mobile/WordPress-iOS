import UIKit
import Synchronization
import Testing
import AsyncImageKit
import WordPressTesting
import OHHTTPStubs
import OHHTTPStubsSwift

/// - warning: This suite has to be `serialized` due to the global HTTP mocks.
@Suite(.serialized) final class ImageDownloaderTests {
    private let sut: ImageDownloader
    private let cache = MockMemoryCache()

    init() async throws {
        sut = ImageDownloader(cache: cache)
    }

    deinit {
        HTTPStubs.removeAllStubs()
    }

    @Test func loadResizedThumbnail() async throws {
        // GIVEN
        let imageURL = try #require(URL(string: "https://example.files.wordpress.com/2023/09/image.jpg"))

        // GIVEN remote image is mocked (1024×680 px)
        try mockResponse(withResource: "test-image", fileExtension: "jpg")

        // WHEN
        let options = ImageRequestOptions(
            size: ImageSize(width: 256, height: 256),
            isMemoryCacheEnabled: false,
            isDiskCacheEnabled: false
        )
        let image = try await sut.image(from: imageURL, options: options)

        // THEN
        #expect(image.size == CGSize(width: 386, height: 256))
    }

    @Test func cancellation() async throws {
        // GIVEN
        let imageURL = try #require(URL(string: "https://example.files.wordpress.com/2023/09/image.jpg"))

        // GIVEN remote image is mocked (1024×680 px)
        try mockResponse(withResource: "test-image", fileExtension: "jpg", delay: 3)

        // WHEN
        let options = ImageRequestOptions(
            size: ImageSize(width: 256, height: 256),
            isMemoryCacheEnabled: false,
            isDiskCacheEnabled: false
        )
        let task = Task { [sut] in
            try await sut.image(from: imageURL, options: options)
        }

        DispatchQueue.global()
            .async {
                task.cancel()
            }

        // THEM
        do {
            let _ = try await task.value
            Issue.record()
        } catch {
            #expect((error as? URLError)?.code == .cancelled)
        }
    }

    @Test func memoryCache() async throws {
        // GIVEN
        let imageURL = try #require(URL(string: "https://example.files.wordpress.com/2023/09/image.jpg"))
        try mockResponse(withResource: "test-image", fileExtension: "jpg")

        let size = ImageSize(width: 256, height: 256)
        let options = ImageRequestOptions(
            size: size,
            isMemoryCacheEnabled: true,
            isDiskCacheEnabled: false
        )
        _ = try await sut.image(from: imageURL, options: options)

        // THEN resized image is stored in memory cache
        let cachedImage = sut.cachedImage(for: imageURL, size: size)
        #expect(cachedImage?.size == CGSize(width: 386, height: 256))

        // GIVEN
        HTTPStubs.removeAllStubs()
        stub(
            condition: { _ in true },
            response: { _ in
                HTTPStubsResponse(error: URLError(.unknown))
            }
        )

        // WHEN
        let image = try await sut.image(from: imageURL, options: options)

        // THEN resized image is returned from memory cache
        #expect(image.size == CGSize(width: 386, height: 256))
    }

    @Test func failureAndRetry() async throws {
        // GIVEN
        let imageURL = try #require(URL(string: "https://example.files.wordpress.com/2023/09/image.jpg"))
        stub(
            condition: { _ in true },
            response: { _ in
                HTTPStubsResponse(error: URLError(.unknown))
            }
        )

        // WHEN
        do {
            _ = try await sut.image(from: imageURL)
            Issue.record("Expected the request to fail")
        } catch {
            // THEN error is returned
            #expect((error as? URLError)?.code == .unknown)
        }

        // GIVEN
        HTTPStubs.removeAllStubs()
        try mockResponse(withResource: "test-image", fileExtension: "jpg")

        // WHEN
        let image = try await sut.image(from: imageURL)

        // THEN resized image is returned from memory cache
        #expect(image.size == CGSize(width: 1024, height: 680))
    }

    @Test func diskCacheHitIsStoredInMemoryCache() async throws {
        // GIVEN an immutable image that is on disk but not in memory
        let imageURL = try #require(URL(string: "https://example.files.wordpress.com/\(UUID().uuidString).jpg"))
        let request = ImageRequest(url: imageURL, options: ImageRequestOptions(mutability: .immutable))
        try mockResponse(withResource: "test-image", fileExtension: "jpg")
        _ = try await sut.image(for: request)

        let downloader = ImageDownloader(cache: MockMemoryCache())
        HTTPStubs.removeAllStubs()
        stub(
            condition: { _ in true },
            response: { _ in
                HTTPStubsResponse(error: URLError(.unknown))
            }
        )

        // WHEN
        _ = try await downloader.image(for: request)

        // THEN the next request can use the memory cache
        #expect(downloader.cachedImage(for: request) != nil)
    }

    @Test func cancelledDownloadDoesNotRemoveNewerDownload() async throws {
        // GIVEN requests that never finish
        let starts = RequestCounter()
        stub(
            condition: { _ in true },
            response: { request in
                starts.increment(request.url)
                return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil).requestTime(30, responseTime: 0)
            }
        )

        for _ in 0..<10 {
            let imageURL = try #require(URL(string: "https://example.files.wordpress.com/\(UUID().uuidString).jpg"))
            let request = ImageRequest(url: imageURL, options: ImageRequestOptions(isDiskCacheEnabled: false))
            let downloader = ImageDownloader(cache: MockMemoryCache())

            // WHEN the first download is cancelled, and a second one for the same URL starts straight away
            let first = Task { try await downloader.image(for: request) }
            try await starts.wait(for: 1, url: imageURL)
            first.cancel()
            let second = Task { try await downloader.image(for: request) }
            try await starts.wait(for: 2, url: imageURL)
            try await Task.sleep(for: .milliseconds(100)) // The cancelled download finishes

            // THEN a third request shares the second download
            let third = Task { try await downloader.image(for: request) }
            try await Task.sleep(for: .milliseconds(100))
            #expect(starts.count(for: imageURL) == 2)

            second.cancel()
            third.cancel()
        }
    }

    // MARK: - Helpers

    func mockResponse(
        withResource name: String,
        fileExtension: String,
        expectedURL: URL? = nil,
        delay: TimeInterval = 0
    ) throws {
        let sourceURL = try #require(Bundle.test.url(forResource: name, withExtension: fileExtension))
        let data = try Data(contentsOf: sourceURL)

        stub(
            condition: { _ in
                true
            },
            response: { request in
                guard expectedURL == nil || request.url == expectedURL else {
                    return HTTPStubsResponse(error: URLError(.unknown))
                }
                return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
                    .requestTime(delay, responseTime: 0)
            }
        )
    }
}

private final class RequestCounter: Sendable {
    private let counts = Mutex<[URL: Int]>([:])

    func increment(_ url: URL?) {
        guard let url else { return }
        counts.withLock { $0[url, default: 0] += 1 }
    }

    func count(for url: URL) -> Int {
        counts.withLock { $0[url, default: 0] }
    }

    func wait(for count: Int, url: URL) async throws {
        for _ in 0..<200 where self.count(for: url) < count {
            try await Task.sleep(for: .milliseconds(5))
        }
        try #require(self.count(for: url) >= count)
    }
}

private final class MockMemoryCache: MemoryCacheProtocol, @unchecked Sendable {
    var cache: [String: UIImage] = [:]

    subscript(key: String) -> UIImage? {
        get { cache[key] }
        set { cache[key] = newValue }
    }

    func removeAllObjects() {
        cache = [:]
    }
}
