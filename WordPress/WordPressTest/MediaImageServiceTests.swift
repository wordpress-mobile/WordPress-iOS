import XCTest
import OHHTTPStubs
@testable import WordPress

class MediaImageServiceTests: CoreDataTestCase {
    var mediaFileManager: MediaFileManager!
    var sut: MediaImageService!

    override func setUp() {
        super.setUp()

        mediaFileManager = MediaFileManager(directory: .temporary(id: UUID()))
        sut = MediaImageService(
            coreDataStack: contextManager,
            mediaFileManager: mediaFileManager
        )
    }

    override func tearDown() {
        super.tearDown()

        HTTPStubs.removeAllStubs()

        if let directoryURL = try? mediaFileManager.directoryURL() {
            try? FileManager.default.removeItem(at: directoryURL)
        }
    }

    // MARK: - Original Image

    func testLoadOriginalImage() async throws {
        // GIVEN
        let media = Media(context: mainContext)
        media.blog = makeEmptyBlog()
        media.mediaType = .image
        media.width = 1024
        media.height = 680
        let remoteURL = try XCTUnwrap(URL(string: "https://example.files.wordpress.com/2023/09/image.jpg"))
        media.remoteURL = remoteURL.absoluteString
        try mainContext.save()

        // GIVEN remote image is mocked
        try mockResponse(withResource: "test-image", fileExtension: "jpg")

        // WHEN
        let image = try await sut.image(for: media, size: .original)

        // THEN
        XCTAssertEqual(image.size, CGSize(width: 1024, height: 680))
    }

    // MARK: - Local Resources

    func testSmallThumbnailForLocalImage() async throws {
        // GIVEN
        let media = Media(context: mainContext)
        media.blog = makeEmptyBlog()
        media.mediaType = .image
        media.width = 1024
        media.height = 680
        let localURL = try makeLocalURL(forResource: "test-image", fileExtension: "jpg")
        media.absoluteLocalURL = localURL
        try mainContext.save()

        // WHEN
        let thumbnail = try await sut.image(for: media, size: .small)

        // THEN a small thumbnail is created
        let expectedSize = await MediaImageService.getThumbnailSize(for: media.pixelSize(), size: .small)
        XCTAssertEqual(thumbnail.size, expectedSize)

        // GIVEN local asset is deleted
        try FileManager.default.removeItem(at: localURL)

        // WHEN
        let cachedThumbnail = try await sut.image(for: media, size: .small)

        // THEN cached thumbnail is still available
        XCTAssertEqual(cachedThumbnail.size, expectedSize)
    }

    func testThatThumbnailsGeneratedForGIFAreAnimatable() async throws {
        // GIVEN
        let media = Media(context: mainContext)
        media.blog = makeEmptyBlog()
        media.mediaType = .image
        media.width = 360
        media.height = 360

        let localURL = try makeLocalURL(forResource: "test-gif", fileExtension: "gif")
        media.absoluteLocalURL = localURL
        try mainContext.save()

        // WHEN
        let thumbnail = try await sut.thumbnail(for: media)

        // THEN
        XCTAssertEqual(thumbnail.size, MediaImageService.getThumbnailSize(for: media, size: .small))
        let gif = try XCTUnwrap(thumbnail as? AnimatedImageWrapper)
        let data = await gif.gifData ?? Data()
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        XCTAssertEqual(CGImageSourceGetCount(source), 20)
    }

    // MARK: - Remote Resources (Images)

    func testSmallThumbnailForRemoteImage() async throws {
        // GIVEN
        let media = Media(context: mainContext)
        media.blog = makeEmptyBlog()
        media.mediaType = .image
        media.width = 1024
        media.height = 680
        let remoteURL = try XCTUnwrap(URL(string: "https://example.files.wordpress.com/2023/09/image.jpg"))
        media.remoteURL = remoteURL.absoluteString
        try mainContext.save()

        // GIVEN remote image is mocked and is resized based on the parameters
        try mockResizableImage(withResource: "test-image", fileExtension: "jpg")

        // WHEN
        let thumbnail = try await sut.image(for: media, size: .small)

        // THEN a small thumbnail is created
        let expectedSize = await MediaImageService.getThumbnailSize(for: media.pixelSize(), size: .small)
        XCTAssertEqual(thumbnail.size, expectedSize)

        // GIVEN local asset is deleted

        // WHEN
        let cachedThumbnail = try await sut.image(for: media, size: .small)

        // THEN cached thumbnail is still available
        XCTAssertEqual(cachedThumbnail.size, expectedSize)
    }

    // MARK: - Remote Resources (Videos)

    func testSmallThumbnailForRemoteVideo() async throws {
        // GIVEN
        let media = Media(context: mainContext)
        media.blog = makeEmptyBlog()
        media.mediaType = .video
        media.width = 1024
        media.height = 680
        media.remoteThumbnailURL = "https://example.files.wordpress.com/2023/09/video-thumbnail.jpg"
        try mainContext.save()

        // GIVEN remote image is mocked and is resized based on the parameters
        try mockResponse(withResource: "test-image", fileExtension: "jpg")

        // WHEN
        let thumbnail = try await sut.image(for: media, size: .small)

        // THEN a thumbnail is downloaded using the remote URL as is
        XCTAssertEqual(thumbnail.size, CGSize(width: 1024, height: 680))
    }

    // Videos on self-hosted WordPress sites don't have `remoteThumbnailURL`.
    // The only possible way to display a thumbnail is to generate it from
    // `remoteURL`.
    func testSmallThumbnailForRemoteSelfHostedVideo() async throws {
        // GIVEN
        let videoURL = try XCTUnwrap(Bundle.test.url(forResource: "test-video-device-gps", withExtension: "m4v"))

        let media = Media(context: mainContext)
        media.blog = makeEmptyBlog()
        media.mediaType = .video
        media.width = 640
        media.height = 360
        media.remoteURL = videoURL.absoluteString
        try mainContext.save()

        // WHEN
        let thumbnail = try await sut.image(for: media, size: .small)

        let expectedSize = await MediaImageService.getThumbnailSize(for: media.pixelSize(), size: .small)

        // THEN a thumbnail is downloaded using the remote URL as is
        XCTAssertEqual(thumbnail.size.width, expectedSize.width, accuracy: 1.5)
        XCTAssertEqual(thumbnail.size.height, expectedSize.height, accuracy: 1.5)

        // GIVEN local asset is deleted

        // WHEN
        let cachedThumbnail = try await sut.image(for: media, size: .small)

        // THEN cached thumbnail is still available
        XCTAssertEqual(cachedThumbnail.size.width, expectedSize.width, accuracy: 1.5)
        XCTAssertEqual(cachedThumbnail.size.height, expectedSize.height, accuracy: 1.5)
    }

    // MARK: - Target Size

    func testThatLandscapeImageIsResizedToFillTargetSize() {
        XCTAssertEqual(
            MediaImageService.targetSize(
                forMediaSize: CGSize(width: 3000, height: 2000),
                targetSize: CGSize(width: 200, height: 200)
            ),
            CGSize(width: 300, height: 200)
        )
    }

    func testThatPortraitImageIsResizedToFillTargetSize() {
        XCTAssertEqual(
            MediaImageService.targetSize(
                forMediaSize: CGSize(width: 2000, height: 3000),
                targetSize: CGSize(width: 200, height: 200)
            ),
            CGSize(width: 200, height: 300)
        )
    }

    func testThatPanoramaIsResizedToSaneSize() {
        XCTAssertEqual(
            MediaImageService.targetSize(
                forMediaSize: CGSize(width: 4000, height: 400),
                targetSize: CGSize(width: 200, height: 200)
            ),
            CGSize(width: 800, height: 200)
        )
    }

    func testThatImagesAreNotUpscaled() {
        XCTAssertEqual(
            MediaImageService.targetSize(
                forMediaSize: CGSize(width: 30, height: 20),
                targetSize: CGSize(width: 200, height: 200)
            ),
            CGSize(width: 30, height: 20)
        )
    }

    // MARK: - Helpers

    func makeEmptyBlog() -> Blog {
        let blog = Blog.createBlankBlog(in: mainContext)
        blog.url = "example.com/blog"
        blog.xmlrpc = "test"
        return blog
    }

    /// `Media` is hardcoded to work with a specific direcoty URL managed by `MediaFileManager`
    func makeLocalURL(forResource name: String, fileExtension: String) throws -> URL {
        let sourceURL = try XCTUnwrap(Bundle.test.url(forResource: name, withExtension: fileExtension))
        let mediaURL = try MediaFileManager.default.makeLocalMediaURL(withFilename: name, fileExtension: fileExtension)
        try FileManager.default.copyItem(at: sourceURL, to: mediaURL)
        return mediaURL
    }

    func mockResizableImage(withResource name: String, fileExtension: String) throws {
        let sourceURL = try XCTUnwrap(Bundle.test.url(forResource: name, withExtension: fileExtension))
        let image = try XCTUnwrap(UIImage(data: try Data(contentsOf: sourceURL)))

        stub(condition: { _ in
            return true
        }, response: { request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems,
                  let resize = queryItems.first(where: { $0.name == "resize" }),
                  let values = resize.value?.components(separatedBy: ","), values.count == 2,
                  let width = Int(values[0]), let height = Int(values[1]) else {
                return HTTPStubsResponse(error: URLError(.unknown))
            }
            let resizedImage = image.resizedImage(CGSize(width: width, height: height), interpolationQuality: .default)
            let responseData = resizedImage?.jpegData(compressionQuality: 0.8) ?? Data()
            return HTTPStubsResponse(data: responseData, statusCode: 200, headers: nil)
        })
    }

    func mockResponse(withResource name: String, fileExtension: String, expectedURL: URL? = nil) throws {
        let sourceURL = try XCTUnwrap(Bundle.test.url(forResource: name, withExtension: fileExtension))
        let data = try Data(contentsOf: sourceURL)

        stub(condition: { _ in
            return true
        }, response: { request in
            guard expectedURL == nil || request.url == expectedURL else {
                return HTTPStubsResponse(error: URLError(.unknown))
            }
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        })
    }
}
