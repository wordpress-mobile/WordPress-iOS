import AVFoundation
import UIKit
import Testing
@testable import AsyncImageKit

@MainActor
@Suite struct ImageViewExtensionsTests {
    @Test func imageViewIsReleasedAfterSetImage() {
        let url = Self.uniqueURL()
        ImageDownloader.shared.setCachedImage(Self.makeImage(), for: url) // A memory-cache hit, so no download
        defer { ImageDownloader.shared.setCachedImage(nil, for: url) }

        weak var weakImageView: UIImageView?
        autoreleasepool {
            let imageView = UIImageView()
            imageView.wp.setImage(with: url)
            #expect(imageView.image != nil)
            weakImageView = imageView
        }

        #expect(weakImageView == nil)
    }

    @Test func imageViewIsReleasedAfterPrepareForReuse() {
        weak var weakImageView: UIImageView?
        autoreleasepool {
            let imageView = UIImageView()
            imageView.wp.prepareForReuse()
            weakImageView = imageView
        }

        #expect(weakImageView == nil)
    }

    @Test func settingImageCancelsLoadInProgress() async throws {
        let host = try GatedMediaHost(image: Self.makeImage(color: .red))
        let imageView = UIImageView()
        imageView.wp.setImage(with: ImageRequest(url: Self.uniqueURL(), host: host))
        let load = try #require(imageView.wp.controller.task)

        // The view moves on to a different image while the earlier load is in progress.
        let newerImage = Self.makeImage(color: .blue)
        imageView.wp.image = newerImage

        host.openGate()
        await load.value

        #expect(imageView.image === newerImage)
    }

    // MARK: - Helpers

    static func uniqueURL(_ ext: String = "png") -> URL {
        URL(string: "https://example.files.wordpress.com/tests/\(UUID().uuidString).\(ext)")!
    }

    static func makeImage(color: UIColor = .red) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
            .image { context in
                color.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
            }
    }
}

/// A host whose requests wait until `openGate()` is called, then load a PNG from disk.
@MainActor
private final class GatedMediaHost: MediaHostProtocol, @unchecked Sendable {
    private let fileURL: URL
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(image: UIImage) throws {
        fileURL = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).png")
        try #require(image.pngData()).write(to: fileURL)
    }

    func openGate() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters = []
    }

    func authenticatedRequest(for url: URL) async throws -> URLRequest {
        if !isOpen {
            await withCheckedContinuation { waiters.append($0) }
        }
        return URLRequest(url: fileURL)
    }

    func authenticatedAsset(for url: URL) async throws -> AVURLAsset {
        AVURLAsset(url: url)
    }
}
