import AsyncImageKit
import ImageIO
import OHHTTPStubs
import OHHTTPStubsSwift
import Testing
import UIKit
import UniformTypeIdentifiers

@testable import WordPress

@MainActor
@Suite(.serialized)
final class NotificationMediaDownloaderTests {
    private static let host = "notification-media.test"

    /// Other suites run at the same time with their own stubs, so remove only this one.
    nonisolated(unsafe) private var stubDescriptor: HTTPStubsDescriptor?

    init() {
        stubDescriptor = stub(condition: isHost(Self.host)) { request in
            let data: Data
            switch request.url?.pathExtension {
            case "gif": data = Self.gif
            case "jpg": data = Self.largeJPEG
            default: data = Self.png
            }
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil).requestTime(0.05, responseTime: 0)
        }
    }

    deinit {
        if let stubDescriptor {
            HTTPStubs.removeStub(stubDescriptor)
        }
    }

    @Test func downloadImageCallsBackOnMainThread() async {
        let isMainThread = await withCheckedContinuation { continuation in
            ImageDownloader.shared.downloadImage(at: Self.makeURL("png")) { _, _ in
                continuation.resume(returning: Thread.isMainThread)
            }
        }

        #expect(isMainThread)
    }

    /// Reads the downloader's images on the main thread while downloads finish, as the notification
    /// details screen does while it lays out. Run with the Thread Sanitizer to check for data races.
    @Test func downloadMediaWhileReadingImages() async {
        let downloader = NotificationMediaDownloader()
        let urls = (0..<3).map { _ in Self.makeURL("png") }

        var isFinished = false
        downloader.downloadMedia(urls: Set(urls), maximumWidth: 2) {
            isFinished = true
        }
        while !isFinished {
            _ = downloader.imagesForUrls(urls)
            downloader.downloadMedia(urls: Set(urls), maximumWidth: 2) {}
            await Task.yield()
        }

        #expect(downloader.imagesForUrls(urls).count == urls.count)
    }

    @Test func animatedImageIsResizedForNewWidth() async throws {
        // GIVEN a 80×40 GIF shown 40 points wide
        let downloader = NotificationMediaDownloader()
        let url = Self.makeURL("gif")
        await withCheckedContinuation { continuation in
            downloader.downloadMedia(urls: [url], maximumWidth: 40) { continuation.resume() }
        }
        let first = try #require(downloader.imagesForUrls([url])[url] as? AnimatedImage)
        #expect(first.targetSize == CGSize(width: 40, height: 20))

        // WHEN the screen rotates, and there are only 20 points
        downloader.resizeMediaWithIncorrectSize(20) {}
        try await Task.sleep(for: .milliseconds(300))

        // THEN
        let resized = try #require(downloader.imagesForUrls([url])[url] as? AnimatedImage)
        #expect(resized.targetSize == CGSize(width: 20, height: 10))
    }

    @Test func animatedImageInSharedCacheIsNotChanged() async throws {
        // GIVEN a GIF that is shown smaller than it is
        let downloader = NotificationMediaDownloader()
        let url = Self.makeURL("gif")
        await download(url, with: downloader, maximumWidth: 40)

        // WHEN the screen rotates
        downloader.resizeMediaWithIncorrectSize(20) {}

        // THEN the copy in the image cache, which other screens share, still has no size set
        let cached = try #require(ImageDownloader.shared.cachedImage(for: url) as? AnimatedImage)
        #expect(cached.targetSize == nil)
    }

    @Test func animatedImageIsCopiedOnce() async throws {
        // GIVEN a GIF that is shown smaller than it is
        let downloader = NotificationMediaDownloader()
        let url = Self.makeURL("gif")
        await download(url, with: downloader, maximumWidth: 40)
        let first = try #require(downloader.imagesForUrls([url])[url])

        // WHEN the screen rotates
        downloader.resizeMediaWithIncorrectSize(20) {}

        // THEN the same copy is resized, rather than copying the GIF again
        #expect(downloader.imagesForUrls([url])[url] === first)
    }

    @Test func lastWidthWinsAfterTwoQuickChanges() async throws {
        // GIVEN a large image
        let downloader = NotificationMediaDownloader()
        let url = Self.makeURL("jpg")
        await download(url, with: downloader, maximumWidth: 100)

        // WHEN the width changes twice in a row, first to one that takes longer to resize
        await withCheckedContinuation { continuation in
            var remaining = 2
            let done = {
                remaining -= 1
                if remaining == 0 { continuation.resume() }
            }
            downloader.resizeMediaWithIncorrectSize(1900, completion: done)
            downloader.resizeMediaWithIncorrectSize(10, completion: done)
        }

        // THEN the image fits the last width
        let image = try #require(downloader.imagesForUrls([url])[url])
        #expect(image.size.width == 10)
    }

    // MARK: - Helpers

    private func download(_ url: URL, with downloader: NotificationMediaDownloader, maximumWidth: CGFloat) async {
        await withCheckedContinuation { continuation in
            downloader.downloadMedia(urls: [url], maximumWidth: maximumWidth) { continuation.resume() }
        }
    }

    private static func makeURL(_ pathExtension: String) -> URL {
        URL(string: "https://\(host)/\(UUID().uuidString).\(pathExtension)")!
    }

    private static let png = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        .pngData { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }

    /// 2000×2000 px, large enough that resizing it takes longer than resizing it again much smaller.
    private static let largeJPEG: Data = {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 2000, height: 2000), format: format)
            .jpegData(withCompressionQuality: 0.8) { context in
                UIColor.green.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 2000, height: 2000))
            }
    }()

    /// Two 80×40 px frames.
    private static let gif: Data = {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, UTType.gif.identifier as CFString, 2, nil)!
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        for color in [UIColor.red, UIColor.blue] {
            let frame = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 40), format: format)
                .image { context in
                    color.setFill()
                    context.fill(CGRect(x: 0, y: 0, width: 80, height: 40))
                }
            CGImageDestinationAddImage(
                destination,
                frame.cgImage!,
                [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.1]] as CFDictionary
            )
        }
        CGImageDestinationFinalize(destination)
        return data as Data
    }()
}
