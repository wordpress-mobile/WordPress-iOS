import SwiftUI
import Testing

@testable import AsyncImageKit

@MainActor
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

    @Test("After the URL changes, the previous URL's image isn't shown")
    func urlChangeDoesNotShowPreviousImage() async throws {
        let downloader = ImageDownloader(cache: cache)
        let otherURL = URL(string: "https://example.invalid/other.png")! // Not cached
        downloader.setCachedImage(Self.image, for: imageURL)

        let recorder = Recorder()
        let harness = Harness(RecordingView(url: imageURL, downloader: downloader, recorder: recorder))
        try await harness.settle()
        #expect(recorder.renders.last?.hasImage == true)

        harness.update(RecordingView(url: otherURL, downloader: downloader, recorder: recorder))
        try await harness.settle()

        let renders = recorder.renders.filter { $0.url == otherURL }
        #expect(!renders.isEmpty)
        #expect(renders.allSatisfy { !$0.hasImage })
    }

    @Test("Re-rendering the parent doesn't look up the memory cache again")
    func parentRendersDoNotReadCache() async throws {
        let cache = CountingCache()
        let downloader = ImageDownloader(cache: cache)
        downloader.setCachedImage(Self.image, for: imageURL)

        let recorder = Recorder()
        let harness = Harness(RecordingView(url: imageURL, downloader: downloader, recorder: recorder))
        try await harness.settle()
        let (readsBefore, rendersBefore) = (cache.reads, recorder.renders.count)

        for tick in 1...10 {
            harness.update(RecordingView(tick: tick, url: imageURL, downloader: downloader, recorder: recorder))
        }
        try await harness.settle()

        #expect(recorder.renders.count - rendersBefore == 10)
        #expect(cache.reads == readsBefore)
    }

    private static let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }
}

// MARK: - Helpers

@MainActor
private final class Recorder {
    struct Render {
        let url: URL
        let hasImage: Bool
    }

    var renders: [Render] = []
}

/// Records each phase `CachedAsyncImage` renders. A different `tick` makes the parent render again.
private struct RecordingView: View {
    var tick = 0
    let url: URL
    let downloader: ImageDownloader
    let recorder: Recorder

    var body: some View {
        ZStack {
            Text(tick, format: .number)
            CachedAsyncImage(url: url, imageDownloader: downloader) { phase in
                let _ = recorder.renders.append(.init(url: url, hasImage: phase.image != nil))
                Color.clear
            }
        }
    }
}

@MainActor
private final class Harness<Root: View> {
    private let host: UIHostingController<Root>
    private let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

    init(_ root: Root) {
        host = UIHostingController(rootView: root)
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
    }

    func update(_ root: Root) {
        host.rootView = root
        host.view.layoutIfNeeded()
    }

    /// Lets the view's task run.
    func settle() async throws {
        try await Task.sleep(for: .milliseconds(300))
        host.view.layoutIfNeeded()
    }
}

private final class CountingCache: MemoryCacheProtocol, @unchecked Sendable {
    private var images: [String: UIImage] = [:]
    private(set) var reads = 0

    subscript(key: String) -> UIImage? {
        get {
            reads += 1
            return images[key]
        }
        set { images[key] = newValue }
    }

    func removeAllObjects() {
        images = [:]
    }
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
