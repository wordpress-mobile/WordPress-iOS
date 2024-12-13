import UIKit
import Testing
import WordPressMedia
import WordPressTesting
import OHHTTPStubs
import OHHTTPStubsSwift

/// - warning: This suite has to be `serialized` due to the global HTTP mocks.
@Suite(.serialized) final class ImageDownloaderTests {
    private let sut: ImageDownloader
    private let cache = MockMemoryCache()

    init() async throws {
        sut = ImageDownloader(cache: cache, authenticator: nil)
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
            size: CGSize(width: 256, height: 256),
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
            size: CGSize(width: 256, height: 256),
            isMemoryCacheEnabled: false,
            isDiskCacheEnabled: false
        )
        let task = Task { [sut] in
            try await sut.image(from: imageURL, options: options)
        }

        DispatchQueue.global().async {
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

        let size = CGSize(width: 256, height: 256)
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
        stub(condition: { _ in true }, response: { _ in
            HTTPStubsResponse(error: URLError(.unknown))
        })

        // WHEN
        let image = try await sut.image(from: imageURL, options: options)

        // THEN resized image is returned from memory cache
        #expect(image.size == CGSize(width: 386, height: 256))
    }

    @Test func failureAndRetry() async throws {
        // GIVEN
        let imageURL = try #require(URL(string: "https://example.files.wordpress.com/2023/09/image.jpg"))
        stub(condition: { _ in true }, response: { _ in
            HTTPStubsResponse(error: URLError(.unknown))
        })

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

    // MARK: - Helpers

    func mockResponse(withResource name: String, fileExtension: String, expectedURL: URL? = nil, delay: TimeInterval = 0) throws {
        let sourceURL = try #require(Bundle.test.url(forResource: name, withExtension: fileExtension))
        let data = try Data(contentsOf: sourceURL)

        stub(condition: { _ in
            return true
        }, response: { request in
            guard expectedURL == nil || request.url == expectedURL else {
                return HTTPStubsResponse(error: URLError(.unknown))
            }
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
                .requestTime(delay, responseTime: 0)
        })
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
