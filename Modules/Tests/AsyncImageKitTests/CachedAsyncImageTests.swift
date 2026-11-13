import SwiftUI
import Testing

@testable import AsyncImageKit

struct CachedAsyncImageTests {
    private let cache = InMemoryCache()
    private let imageURL = URL(string: "https://example.com/icon.png")!

    @Test("An image in the memory cache is there from the first frame")
    func startsWithCachedImage() {
        let downloader = ImageDownloader(cache: cache)
        downloader.setCachedImage(Self.image, for: imageURL)

        let phase = CachedAsyncImage<EmptyView>
            .initialPhase(
                for: ImageRequest(url: imageURL),
                imageDownloader: downloader
            )

        #expect(phase.image != nil)
    }

    @Test("An image cached at another size isn't used")
    func ignoresOtherSizes() {
        let downloader = ImageDownloader(cache: cache)
        downloader.setCachedImage(Self.image, for: imageURL, size: ImageSize(width: 56, height: 56))

        let phase = CachedAsyncImage<EmptyView>
            .initialPhase(
                for: ImageRequest(url: imageURL),
                imageDownloader: downloader
            )

        #expect(phase.image == nil)
    }

    @Test("Without a cached image, the view starts empty")
    func startsEmpty() {
        let downloader = ImageDownloader(cache: cache)

        #expect(
            CachedAsyncImage<EmptyView>.initialPhase(for: ImageRequest(url: imageURL), imageDownloader: downloader)
                .image == nil
        )
        #expect(CachedAsyncImage<EmptyView>.initialPhase(for: nil, imageDownloader: downloader).image == nil)
    }

    private static let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }
}

private final class InMemoryCache: MemoryCacheProtocol, @unchecked Sendable {
    private var images: [String: UIImage] = [:]

    subscript(key: String) -> UIImage? {
        get { images[key] }
        set { images[key] = newValue }
    }

    func removeAllObjects() {
        images = [:]
    }
}
