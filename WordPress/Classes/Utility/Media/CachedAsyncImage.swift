import SwiftUI
import DesignSystem
import WordPressMedia

/// Asynchronous Image View that replicates the public API of `SwiftUI.AsyncImage`.
/// It uses `ImageDownloader` to fetch and cache the images.
struct CachedAsyncImage<Content>: View where Content: View {
    @State private var phase: AsyncImagePhase = .empty
    private let url: URL?
    private let content: (AsyncImagePhase) -> Content
    private let imageDownloader: ImageDownloader
    private let host: MediaHost?

    public var body: some View {
        content(phase)
            .task(id: url) { await fetchImage() }
    }

    // MARK: - Initializers

    /// Initializes an image without any customization.
    /// Provides a plain color as placeholder
    init(url: URL?) where Content == _ConditionalContent<Image, Color> {
        self.init(url: url) { phase in
            if let image = phase.image {
                image
            } else {
                Color(uiColor: UIAppColor.gray(.shade40))
            }
        }
    }

    /// Allows content customization and providing a placeholder that will be shown
    /// until the image download is finalized.
    init<I, P>(url: URL?, host: MediaHost? = nil, @ViewBuilder content: @escaping (Image) -> I, @ViewBuilder placeholder: @escaping () -> P) where Content == _ConditionalContent<I, P>, I: View, P: View {
        self.init(url: url, host: host) { phase in
            if let image = phase.image {
                content(image)
            } else {
                placeholder()
            }
        }
    }

    init(
        url: URL?,
        host: MediaHost? = nil,
        imageDownloader: ImageDownloader = .shared,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.host = host
        self.imageDownloader = imageDownloader
        self.content = content
    }

    // MARK: - Helpers

    private func fetchImage() async {
        do {
            guard let url else {
                phase = .empty
                return
            }
            if let image = imageDownloader.cachedImage(for: url) {
                phase = .success(Image(uiImage: image))
            } else {
                let image: UIImage
                if let host {
                    image = try await imageDownloader.image(from: url, host: host)
                } else {
                    image = try await imageDownloader.image(from: url)
                }
                phase = .success(Image(uiImage: image))
            }
        } catch {
            phase = .failure(error)
        }
    }
}
