import XCTest
import OHHTTPStubs
@testable import WordPress

class ImageDownloaderTests: CoreDataTestCase {
    private var sut: ImageDownloader!
    private let cache = MockMemoryCache()

    override func setUp() {
        super.setUp()

        sut = ImageDownloader(cache: cache)
    }

    // TODO: test canellation
    // TODO: test coalescing
    // TODO: test caching
    // TODO: test resizing

    override func tearDown() {
        super.tearDown()

        HTTPStubs.removeAllStubs()
    }

    func testLoadResizedThumbnail() async throws {
        // GIVEN
        let imageURL = try XCTUnwrap(URL(string: "https://example.files.wordpress.com/2023/09/image.jpg"))

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
        XCTAssertEqual(image.size, CGSize(width: 386, height: 256))
    }

    func testCancellation() async throws {
        // GIVEN
        let imageURL = try XCTUnwrap(URL(string: "https://example.files.wordpress.com/2023/09/image.jpg"))

        // GIVEN remote image is mocked (1024×680 px)
        try mockResponse(withResource: "test-image", fileExtension: "jpg", delay: 3)

        // WHEN
        let options = ImageRequestOptions(
            size: CGSize(width: 256, height: 256),
            isMemoryCacheEnabled: false,
            isDiskCacheEnabled: false
        )
        let task = Task {
            try await sut.image(from: imageURL, options: options)
        }

        DispatchQueue.global().async {
            task.cancel()
        }

        // THEM
        do {
            let _ = try await task.value
            XCTFail()
        } catch {
            XCTAssertEqual((error as? URLError)?.code == .cancelled)
        }
    }

    // MARK: - Helpers

    /// `Media` is hardcoded to work with a specific direcoty URL managed by `MediaFileManager`
    func makeLocalURL(forResource name: String, fileExtension: String) throws -> URL {
        let sourceURL = try XCTUnwrap(Bundle.test.url(forResource: name, withExtension: fileExtension))
        let mediaURL = try MediaFileManager.default.makeLocalMediaURL(withFilename: name, fileExtension: fileExtension)
        try FileManager.default.copyItem(at: sourceURL, to: mediaURL)
        return mediaURL
    }

    func mockResponse(withResource name: String, fileExtension: String, expectedURL: URL? = nil, delay: TimeInterval = 0) throws {
        let sourceURL = try XCTUnwrap(Bundle.test.url(forResource: name, withExtension: fileExtension))
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

private final class MockMemoryCache: MemoryCacheProtocol {
    var cache: [String: UIImage] = [:]

    subscript(key: String) -> UIImage? {
        get { cache[key] }
        set { cache[key] = newValue }
    }
}
