import AVFoundation
import UIKit
import CryptoKit
import Synchronization
import Testing
import ImageIO
import UniformTypeIdentifiers
@testable import AsyncImageKit
import WordPressTesting
import OHHTTPStubs
import OHHTTPStubsSwift

/// - warning: This suite has to be `serialized` due to the global HTTP mocks.
@Suite(.serialized) final class ImageDownloaderTests {
    private let sut: ImageDownloader
    private let cache = MockMemoryCache()
    private let diskCacheDirectory = FileManager.default.temporaryDirectory
        .appending(path: "ImageDownloaderTests-\(UUID().uuidString)")

    init() async throws {
        sut = ImageDownloader(cache: cache, diskCacheDirectory: diskCacheDirectory)
    }

    deinit {
        HTTPStubs.removeAllStubs()
        try? FileManager.default.removeItem(at: diskCacheDirectory)
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
        defer {
            let hash = SHA256.hash(data: Data(imageURL.absoluteString.utf8)).map { String(format: "%02x", $0) }
            try? FileManager.default.removeItem(at: URL.cachesDirectory.appending(path: "image-cache/\(hash.joined())"))
        }

        let downloader = makeDownloader()
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

            // WHEN the first download is cancelled, and a second request for the same URL comes straight away.
            // It either joins the first download (if it gets there before the cancellation) or starts a new one.
            let first = Task { try await downloader.image(for: request) }
            try await starts.wait(for: 1, url: imageURL)
            first.cancel()
            let second = Task { try await downloader.image(for: request) }
            _ = await starts.reaches(2, url: imageURL, within: .seconds(1)) // If it started one, it has by now
            let startsBeforeThird = starts.count(for: imageURL)

            // THEN a third request shares the second request's download
            let third = Task { try await downloader.image(for: request) }
            try await Task.sleep(for: .milliseconds(300))
            #expect(starts.count(for: imageURL) == startsBeforeThird)

            second.cancel()
            third.cancel()
        }
    }

    @Test func failedDownloadIsNotSharedWithLaterRequest() async throws {
        // GIVEN the first response is an error, and later ones succeed
        let imageURL = try #require(URL(string: "https://example.files.wordpress.com/\(UUID().uuidString).jpg"))
        let imageData = try Data(
            contentsOf: try #require(Bundle.test.url(forResource: "test-image", withExtension: "jpg"))
        )
        let starts = RequestCounter()
        stub(
            condition: { _ in true },
            response: { request in
                starts.increment(request.url)
                let isFirst = starts.count(for: imageURL) == 1
                return HTTPStubsResponse(
                    data: isFirst ? Data() : imageData,
                    statusCode: isFirst ? 500 : 200,
                    headers: nil
                )
                .requestTime(0.2, responseTime: 0)
            }
        )
        let request = ImageRequest(url: imageURL, options: ImageRequestOptions(isDiskCacheEnabled: false))
        let downloader = ImageDownloader(cache: MockMemoryCache())

        // WHEN a second request comes after the first download has failed, but while the downloader is
        // busy (for example decoding another image), so the first caller hasn't got its error back yet
        let first = Task { try await downloader.image(for: request) }
        try await starts.wait(for: 1, url: imageURL)
        let busy = Task { @ImageDownloaderActor in usleep(800_000) }
        try await Task.sleep(for: .milliseconds(500)) // The error response arrives while the downloader is busy
        let second = Task { try await downloader.image(for: request) }
        await busy.value

        // THEN the first request fails, and the second one downloads the image again
        await #expect(throws: (any Error).self) { try await first.value }
        let image = try await second.value
        #expect(image.size == CGSize(width: 1024, height: 680))
    }

    @Test func failedLowPriorityDownloadIsNotSharedWithHigherPriorityRequest() async throws {
        // GIVEN the first response is an error, and later ones succeed
        let imageURL = try #require(URL(string: "https://example.files.wordpress.com/\(UUID().uuidString).jpg"))
        let imageData = try Data(
            contentsOf: try #require(Bundle.test.url(forResource: "test-image", withExtension: "jpg"))
        )
        let starts = RequestCounter()
        stub(
            condition: { _ in true },
            response: { request in
                starts.increment(request.url)
                let isFirst = starts.count(for: imageURL) == 1
                return HTTPStubsResponse(
                    data: isFirst ? Data() : imageData,
                    statusCode: isFirst ? 500 : 200,
                    headers: nil
                )
                .requestTime(0.2, responseTime: 0)
            }
        )
        let request = ImageRequest(url: imageURL, options: ImageRequestOptions(isDiskCacheEnabled: false))
        let downloader = ImageDownloader(cache: MockMemoryCache())

        // WHEN a low-priority request (like a prefetch) fails while the downloader is busy,
        // and a view's request at a higher priority comes in during that time
        let first = Task(priority: .low) { try await downloader.image(for: request) }
        try await starts.wait(for: 1, url: imageURL)
        let busy = Task(priority: .userInitiated) { @ImageDownloaderActor in usleep(800_000) }
        try await Task.sleep(for: .milliseconds(500)) // The error arrives while the downloader is busy
        let second = Task(priority: .userInitiated) { try await downloader.image(for: request) }
        await busy.value

        // THEN the second request downloads the image again, rather than getting the first one's error
        _ = try? await first.value
        let image = try await second.value
        #expect(image.size == CGSize(width: 1024, height: 680))
        #expect(starts.count(for: imageURL) == 2)
    }

    @Test func videoThumbnailIsRotatedLikeTheVideo() async throws {
        // GIVEN a video shot in portrait: landscape frames with a 90° rotation, as the iPhone camera writes them
        let videoURL = try await Fixtures.makeVideo(
            width: 128,
            height: 64,
            transform: CGAffineTransform(rotationAngle: .pi / 2)
        )
        defer { try? FileManager.default.removeItem(at: videoURL) }

        // WHEN
        let options = ImageRequestOptions(isMemoryCacheEnabled: false, isDiskCacheEnabled: false)
        let thumbnail = try await sut.image(for: ImageRequest(videoUrl: videoURL, options: options))

        // THEN the thumbnail is portrait, like the video when it plays
        #expect(thumbnail.size == CGSize(width: 64, height: 128))

        // WHEN a smaller thumbnail is requested
        let smallOptions = ImageRequestOptions(
            size: ImageSize(width: 32, height: 32),
            isMemoryCacheEnabled: false,
            isDiskCacheEnabled: false
        )
        let small = try await sut.image(for: ImageRequest(videoUrl: videoURL, options: smallOptions))

        // THEN it fits the requested size, and is still portrait
        #expect(small.size == CGSize(width: 16, height: 32))
    }

    // MARK: - Disk cache (immutable images)

    @Test func diskCacheKeepsDownloadedFile() async throws {
        // GIVEN a 1024×680 px JPEG
        let data = try Data(contentsOf: try #require(Bundle.test.url(forResource: "test-image", withExtension: "jpg")))

        // WHEN
        let (_, fromDisk, url) = try await downloadThenReadFromDisk(data)

        // THEN the saved file is the downloaded file, not a bigger re-encoded copy
        let saved = try Data(contentsOf: sut.diskCacheFileURL(for: url))
        #expect(saved.count == data.count, "Downloaded \(data.count) bytes, saved \(saved.count) bytes")
        #expect(saved == data)
        #expect(fromDisk.size == CGSize(width: 1024, height: 680))
    }

    @Test func diskCacheResizesImageReadBack() async throws {
        // GIVEN a 1024×680 px JPEG, requested as a thumbnail
        let data = try Data(contentsOf: try #require(Bundle.test.url(forResource: "test-image", withExtension: "jpg")))
        let options = ImageRequestOptions(size: ImageSize(width: 256, height: 256), mutability: .immutable)

        // WHEN
        let (downloaded, fromDisk, _) = try await downloadThenReadFromDisk(data, options: options)

        // THEN
        #expect(downloaded.size == CGSize(width: 386, height: 256))
        #expect(fromDisk.size == CGSize(width: 386, height: 256))
    }

    @Test func diskCacheKeepsGIFAnimated() async throws {
        let data = try Data(contentsOf: try #require(Bundle.test.url(forResource: "anim-reader", withExtension: "gif")))

        let (downloaded, fromDisk, _) = try await downloadThenReadFromDisk(data)

        #expect((downloaded as? AnimatedImage)?.gifData == data)
        #expect((fromDisk as? AnimatedImage)?.gifData == data, "Read back as \(type(of: fromDisk))")
    }

    @Test func diskCacheKeepsEXIFOrientation() async throws {
        // GIVEN 60×30 pixels tagged "rotate 90°", as iPhone photos often are, so it displays as 30×60
        let data = try Fixtures.makeJPEG(width: 60, height: 30, orientation: .right)

        let (downloaded, fromDisk, _) = try await downloadThenReadFromDisk(data)

        #expect(downloaded.size == CGSize(width: 30, height: 60))
        #expect(fromDisk.size == CGSize(width: 30, height: 60))
    }

    @Test func legacyDiskCacheIsRemoved() throws {
        // GIVEN images saved by an earlier version of the app, as PNGs with sideways videos
        let legacyDirectory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: legacyDirectory, withIntermediateDirectories: true)
        try Data([1, 2, 3]).write(to: legacyDirectory.appending(path: "saved-image"))

        // WHEN
        ImageDownloader.removeLegacyDiskCache(at: legacyDirectory)

        // THEN they are deleted, and the app saves new images somewhere else
        #expect(!FileManager.default.fileExists(atPath: legacyDirectory.path()))
        let url = try #require(URL(string: "https://example.files.wordpress.com/image.jpg"))
        let fileURL = ImageDownloader(cache: MockMemoryCache()).diskCacheFileURL(for: url)
        #expect(!fileURL.path().hasPrefix(ImageDownloader.legacyDiskCacheDirectory.path() + "/"))
    }

    @Test func diskCacheKeepsVideoThumbnail() async throws {
        // GIVEN
        let videoURL = try await Fixtures.makeVideo(width: 128, height: 64, transform: .identity)
        let request = ImageRequest(videoUrl: videoURL, options: ImageRequestOptions(mutability: .immutable))
        _ = try await sut.image(for: request)

        // WHEN the thumbnail is requested again after the video is gone
        try FileManager.default.removeItem(at: videoURL)
        let thumbnail = try await makeDownloader().image(for: request)

        // THEN
        #expect(thumbnail.size == CGSize(width: 128, height: 64))
    }

    @Test func diskCacheSavesOneFilePerImage() async throws {
        // GIVEN a 1024×680 px JPEG, downloaded as a thumbnail first
        let data = try Data(contentsOf: try #require(Bundle.test.url(forResource: "test-image", withExtension: "jpg")))
        let thumbnailOptions = ImageRequestOptions(size: ImageSize(width: 256, height: 256), mutability: .immutable)
        let (_, _, url) = try await downloadThenReadFromDisk(data, options: thumbnailOptions)

        // WHEN the full size is requested, offline
        let fullSize = try await makeDownloader()
            .image(
                for: ImageRequest(url: url, options: ImageRequestOptions(mutability: .immutable))
            )

        // THEN it comes from the one saved file
        #expect(fullSize.size == CGSize(width: 1024, height: 680))
        let files = try FileManager.default.contentsOfDirectory(atPath: diskCacheDirectory.path())
        #expect(files.count == 1, "Saved \(files.count) files")
    }

    @Test func diskCacheKeepsFullSizeVideoFrame() async throws {
        // GIVEN a 128×64 video whose thumbnail is first requested small
        let videoURL = try await Fixtures.makeVideo(width: 128, height: 64, transform: .identity)
        let smallOptions = ImageRequestOptions(size: ImageSize(width: 32, height: 32), mutability: .immutable)
        let small = try await sut.image(for: ImageRequest(videoUrl: videoURL, options: smallOptions))
        #expect(small.size == CGSize(width: 32, height: 16))

        // WHEN both sizes are requested again after the video is gone
        try FileManager.default.removeItem(at: videoURL)
        let fullOptions = ImageRequestOptions(mutability: .immutable)
        let fullSize = try await makeDownloader().image(for: ImageRequest(videoUrl: videoURL, options: fullOptions))
        let smallAgain = try await makeDownloader().image(for: ImageRequest(videoUrl: videoURL, options: smallOptions))

        // THEN both come from the saved full-size frame, resized the same way as a fresh thumbnail
        #expect(fullSize.size == CGSize(width: 128, height: 64))
        #expect(smallAgain.size == CGSize(width: 32, height: 16))
    }

    @Test func diskCacheWriteFailureStillReturnsImage() async throws {
        // GIVEN the disk cache can't save files, as when the device is out of space
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        try fileManager.setAttributes([.posixPermissions: 0o555], ofItemAtPath: diskCacheDirectory.path())
        defer { try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: diskCacheDirectory.path()) }
        try mockResponse(withResource: "test-image", fileExtension: "jpg")

        // WHEN
        let imageURL = try #require(URL(string: "https://example.files.wordpress.com/\(UUID().uuidString).jpg"))
        let request = ImageRequest(url: imageURL, options: ImageRequestOptions(mutability: .immutable))
        let image = try await sut.image(for: request)

        // THEN the image is shown, and kept in memory, but not saved
        #expect(image.size == CGSize(width: 1024, height: 680))
        #expect(sut.cachedImage(for: request) != nil)
        #expect(!fileManager.fileExists(atPath: sut.diskCacheFileURL(for: imageURL).path()))
    }

    @Test func clearingDiskCacheRemovesSavedImages() async throws {
        // GIVEN
        let data = try Data(contentsOf: try #require(Bundle.test.url(forResource: "test-image", withExtension: "jpg")))
        await sut.clearDiskCache()
        let (_, _, url) = try await downloadThenReadFromDisk(data)
        let path = sut.diskCacheFileURL(for: url).path()
        try #require(FileManager.default.fileExists(atPath: path))

        // THEN the saved image counts towards the size the Debug menu shows
        let size = await sut.diskCacheSize
        #expect(size >= data.count, "The disk cache size is \(size) bytes")

        // WHEN the cache is cleared, as the Debug menu's "Image cache" button does
        await sut.clearDiskCache()

        // THEN
        let isStillSaved = FileManager.default.fileExists(atPath: path)
        #expect(isStillSaved == false)
    }

    @Test func clearingDiskCacheDuringDownloadDoesNotSaveIt() async throws {
        // GIVEN an immutable image whose download is in flight
        let data = try Data(contentsOf: try #require(Bundle.test.url(forResource: "test-image", withExtension: "jpg")))
        let url = try #require(URL(string: "https://example.files.wordpress.com/\(UUID().uuidString).jpg"))
        let starts = RequestCounter()
        stub(
            condition: { _ in true },
            response: { request in
                starts.increment(request.url)
                return HTTPStubsResponse(data: data, statusCode: 200, headers: nil).requestTime(1, responseTime: 0)
            }
        )
        let request = ImageRequest(
            url: url,
            options: ImageRequestOptions(isMemoryCacheEnabled: false, mutability: .immutable)
        )
        let load = Task { [sut] in try await sut.image(for: request) }
        try await starts.wait(for: 1, url: url)

        // WHEN the cache is cleared, then the download finishes
        await sut.clearDiskCache()
        _ = try await load.value

        // THEN the image isn't saved
        #expect(!FileManager.default.fileExists(atPath: sut.diskCacheFileURL(for: url).path()))
    }

    @Test func videoSizeWithZeroSideIsNoLimitOnThatSide() async throws {
        // GIVEN
        let videoURL = try await Fixtures.makeVideo(width: 128, height: 64, transform: .identity)
        defer { try? FileManager.default.removeItem(at: videoURL) }
        let size = ImageSize(width: 0, height: 32)

        // WHEN
        let mutable = try await sut.image(
            for: ImageRequest(
                videoUrl: videoURL,
                options: ImageRequestOptions(size: size, isMemoryCacheEnabled: false, isDiskCacheEnabled: false)
            )
        )
        let immutable = try await sut.image(
            for: ImageRequest(
                videoUrl: videoURL,
                options: ImageRequestOptions(size: size, isMemoryCacheEnabled: false, mutability: .immutable)
            )
        )

        // THEN both are scaled to the height, as `AVAssetImageGenerator.maximumSize` does
        #expect(mutable.size == CGSize(width: 64, height: 32))
        #expect(immutable.size == CGSize(width: 64, height: 32))
    }

    // MARK: - Helpers

    private func makeDownloader() -> ImageDownloader {
        ImageDownloader(cache: MockMemoryCache(), diskCacheDirectory: diskCacheDirectory)
    }

    /// Downloads `data` as an immutable image, then reads it back the way the next app launch
    /// does: with a new downloader and an empty memory cache, offline.
    private func downloadThenReadFromDisk(
        _ data: Data,
        options: ImageRequestOptions = ImageRequestOptions(mutability: .immutable)
    ) async throws -> (downloaded: UIImage, fromDisk: UIImage, url: URL) {
        let url = try #require(URL(string: "https://example.files.wordpress.com/\(UUID().uuidString)"))
        let request = ImageRequest(url: url, options: options)

        stub(condition: { _ in true }, response: { _ in HTTPStubsResponse(data: data, statusCode: 200, headers: nil) })
        let downloaded = try await sut.image(for: request)

        HTTPStubs.removeAllStubs()
        stub(condition: { _ in true }, response: { _ in HTTPStubsResponse(error: URLError(.notConnectedToInternet)) })
        let fromDisk = try await makeDownloader().image(for: request)

        return (downloaded, fromDisk, url)
    }

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

    func reaches(_ count: Int, url: URL, within timeout: Duration) async -> Bool {
        let deadline = ContinuousClock.now + timeout
        while self.count(for: url) < count, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(5))
        }
        return self.count(for: url) >= count
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

private enum Fixtures {
    /// A JPEG whose pixels are `width`×`height`, tagged with an EXIF orientation.
    static func makeJPEG(width: Int, height: Int, orientation: CGImagePropertyOrientation) throws -> Data {
        let data = NSMutableData()
        let destination = try #require(
            CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)
        )
        let properties = [kCGImagePropertyOrientation: orientation.rawValue] as CFDictionary
        CGImageDestinationAddImage(destination, try makeCGImage(width: width, height: height), properties)
        try #require(CGImageDestinationFinalize(destination))
        return data as Data
    }

    static func makeCGImage(width: Int, height: Int) throws -> CGImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
            .image { context in
                UIColor.red.setFill()
                context.fill(CGRect(x: 0, y: 0, width: width / 2, height: height))
                UIColor.blue.setFill()
                context.fill(CGRect(x: width / 2, y: 0, width: width - width / 2, height: height))
            }
        return try #require(image.cgImage)
    }

    /// A short video whose frames are `width`×`height` pixels, with the given track transform.
    static func makeVideo(width: Int, height: Int, transform: CGAffineTransform) async throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mov")
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264.rawValue,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height
            ]
        )
        input.transform = transform
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        writer.add(input)
        try #require(writer.startWriting(), "\(String(describing: writer.error))")
        writer.startSession(atSourceTime: .zero)

        for frame in 0..<3 {
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(for: .milliseconds(10))
            }
            var buffer: CVPixelBuffer?
            CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, nil, &buffer)
            let pixelBuffer = try #require(buffer)
            CVPixelBufferLockBaseAddress(pixelBuffer, [])
            let base = try #require(CVPixelBufferGetBaseAddress(pixelBuffer))
            memset(base, Int32(64 + frame * 32), CVPixelBufferGetDataSize(pixelBuffer))
            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
            try #require(
                adaptor.append(pixelBuffer, withPresentationTime: CMTime(value: CMTimeValue(frame), timescale: 30))
            )
        }

        input.markAsFinished()
        await writer.finishWriting()
        try #require(writer.status == .completed, "\(String(describing: writer.error))")
        return url
    }
}
