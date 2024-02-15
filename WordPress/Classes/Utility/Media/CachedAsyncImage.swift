import SwiftUI

/// Asynchronous Image View that replicates the public API of `SwiftUI.AsyncImage`.
/// It uses `ImageDownloader` to fetch and cache the images.
struct CachedAsyncImage<Content>: View where Content: View {
    @State private var phase: AsyncImagePhase
    private let url: URL?
    private let transaction: Transaction
    private let content: (AsyncImagePhase) -> Content
    private let imageDownloader: ImageDownloader

    public var body: some View {
        content(phase)
            .task(id: url, load)
    }

    /// Loads and displays an image from the specified URL.
    ///
    /// Until the image loads, SwiftUI displays a default placeholder. When
    /// the load operation completes successfully, SwiftUI updates the
    /// view to show the loaded image. If the operation fails, SwiftUI
    /// continues to display the placeholder. The following example loads
    /// and displays an icon from an example server:
    ///
    ///     CachedAsyncImage(url: URL(string: "https://example.com/icon.png"))
    ///
    /// If you want to customize the placeholder or apply image-specific
    /// modifiers --- like ``Image/resizable(capInsets:resizingMode:)`` ---
    /// to the loaded image, use the ``init(url:content:placeholder:)``
    /// initializer instead.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to display.
    init(url: URL?) where Content == Image {
        self.init(url: url) { phase in
            phase.image ?? Image(uiImage: .init())
        }
    }

    /// Loads and displays a modifiable image from the specified URL using
    /// a custom placeholder until the image loads.
    ///
    /// Until the image loads, SwiftUI displays the placeholder view that
    /// you specify. When the load operation completes successfully, SwiftUI
    /// updates the view to show content that you specify, which you
    /// create using the loaded image. For example, you can show a green
    /// placeholder, followed by a tiled version of the loaded image:
    ///
    ///     CachedAsyncImage(url: URL(string: "https://example.com/icon.png")) { image in
    ///         image.resizable(resizingMode: .tile)
    ///     } placeholder: {
    ///         Color.green
    ///     }
    ///
    /// If the load operation fails, SwiftUI continues to display the
    /// placeholder. To be able to display a different view on a load error,
    /// use the ``init(url:transaction:content:)`` initializer instead.
    ///
    /// - Parameters:
    ///   - content: A closure that takes the loaded image as an input, and
    ///     returns the view to show. You can return the image directly, or
    ///     modify it as needed before returning it.
    ///   - placeholder: A closure that returns the view to show until the
    ///     load operation completes successfully.
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
        transaction: Transaction = Transaction(),
        imageDownloader: ImageDownloader = .shared,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.transaction = transaction
        self.imageDownloader = imageDownloader
        self.content = content

        self._phase = State(wrappedValue: .empty)
        if let url, let image = cachedImage(from: url) {
            self._phase = State(wrappedValue: .success(image))
        }
    }

    @Sendable
    private func load() async {
        do {
            if let url {
                let image = try await Image(uiImage: imageDownloader.image(from: url))
                if let cachedImage = cachedImage(from: url) {
                    phase = .success(cachedImage)
                } else {
                    withAnimation(transaction.animation) {
                        phase = .success(image)
                    }
                }
            } else {
                withAnimation(transaction.animation) {
                    phase = .empty
                }
            }
        } catch {
            withAnimation(transaction.animation) {
                phase = .failure(error)
            }
        }
    }
}

// MARK: - Helpers

private extension CachedAsyncImage {
    private func cachedImage(from url: URL?) -> Image? {
        guard let url, let uiImage = imageDownloader.cachedImage(for: url) else {
            return nil
        }

        return Image(uiImage: uiImage)
    }
}
