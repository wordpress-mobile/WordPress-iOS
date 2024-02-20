import SwiftUI
import DesignSystem

/// Asynchronous Image View that replicates the public API of `SwiftUI.AsyncImage`.
/// It uses `ImageDownloader` to fetch and cache the images.
struct CachedAsyncImage<Content>: View where Content: View {
    @State private var phase: AsyncImagePhase
    private let url: URL?
    private let content: (AsyncImagePhase) -> Content
    private let imageDownloader: ImageDownloader

    public var body: some View {
        content(phase)
            .task(id: url, fetchImage)
    }

    // MARK: - Initializers

    /// Initializes an image without any customization.
    /// Provides a plain color as placeholder
    init(url: URL?) where Content == _ConditionalContent<Image, Color> {
        self.init(url: url) { phase in
            if let image = phase.image {
                image
            } else {
                Color.DS.Background.secondary
            }
        }
    }

    /// Allows content customization and providing a placeholder that will be shown
    /// until the image download is finalized.
    init<I, P>(url: URL?, @ViewBuilder content: @escaping (Image) -> I, @ViewBuilder placeholder: @escaping () -> P) where Content == _ConditionalContent<I, P>, I: View, P: View {
        self.init(url: url) { phase in
            if let image = phase.image {
                content(image)
            } else {
                placeholder()
            }
        }
    }

    init(
        url: URL?,
        imageDownloader: ImageDownloader = .shared,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.imageDownloader = imageDownloader
        self.content = content

        self._phase = State(wrappedValue: .empty)
        if let url, let image = cachedImage(from: url) {
            self._phase = State(wrappedValue: .success(image))
        }
    }

    // MARK: - Helpers

    @Sendable
    private func fetchImage() async {
        do {
            if let url {
                let image = try await Image(uiImage: imageDownloader.image(from: url))
                phase = .success(image)
            } else {
                phase = .empty
            }
        } catch {
            phase = .failure(error)
        }
    }

    private func cachedImage(from url: URL?) -> Image? {
        guard let url, let uiImage = imageDownloader.cachedImage(for: url) else {
            return nil
        }

        return Image(uiImage: uiImage)
    }
}
