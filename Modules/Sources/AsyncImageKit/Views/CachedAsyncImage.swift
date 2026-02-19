import SwiftUI

/// Asynchronous Image View that replicates the public API of `SwiftUI.AsyncImage`.
/// It uses `ImageDownloader` to fetch and cache the images.
public struct CachedAsyncImage<Content>: View where Content: View {
    @State private var phase: AsyncImagePhase = .empty

    private let request: ImageRequest?
    private let content: (AsyncImagePhase) -> Content
    private let imageDownloader: ImageDownloader

    public var body: some View {
        content(phase)
            .task(id: request?.source.url) { await fetchImage() }
    }

    // MARK: - Initializers

    /// Initializes an image without any customization.
    /// Provides a plain color as placeholder
    public init(url: URL?) where Content == _ConditionalContent<Image, Color> {
        let request = url == nil ? nil : ImageRequest(url: url!)

        self.init(request: request) { phase in
            if let image = phase.image {
                image
            } else {
                Color(uiColor: .secondarySystemBackground)
            }
        }
    }

    public init(
        url: URL?,
        host: MediaHostProtocol? = nil,
        imageDownloader: ImageDownloader = .shared,
        mutability: ResourceMutability = .mutable,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        if let url {
            let request = ImageRequest(url: url, host: host, options: ImageRequestOptions(
                mutability: mutability
            ))

            self.init(
                request: request,
                imageDownloader: imageDownloader,
                content: content
            )
        } else {
            self.init(request: nil, imageDownloader: imageDownloader, content: content)
        }
    }

    /// Allows content customization and providing a placeholder that will be shown
    /// until the image download is finalized.
    public init<I, P>(
        url: URL?,
        host: MediaHostProtocol? = nil,
        imageDownloader: ImageDownloader = .shared,
        mutability: ResourceMutability = .mutable,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _ConditionalContent<I, P>, I: View, P: View {
        if let url {
            let request = ImageRequest(url: url, host: host, options: ImageRequestOptions(
                mutability: mutability
            ))

            self.init(
                request: request,
                imageDownloader: imageDownloader,
                content: content,
                placeholder: placeholder
            )
        } else {
            self.init(request: nil, content: content, placeholder: placeholder)
        }
    }

    /// Allows content customization and providing a placeholder that will be shown
    /// until the image download is finalized.
    public init<I, P>(
        videoUrl: URL,
        host: MediaHostProtocol? = nil,
        imageDownloader: ImageDownloader = .shared,
        mutability: ResourceMutability = .mutable,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _ConditionalContent<I, P>, I: View, P: View {
        self.init(
            request: ImageRequest(videoUrl: videoUrl, host: host, options: ImageRequestOptions(
                mutability: mutability
            )),
            imageDownloader: imageDownloader,
            content: content,
            placeholder: placeholder
        )
    }

    /// Allows content customization and providing a placeholder that will be shown
    /// until the image download is finalized.
    private init<I, P>(
        request: ImageRequest?,
        imageDownloader: ImageDownloader = .shared,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _ConditionalContent<I, P>, I: View, P: View {
        self.init(request: request, imageDownloader: imageDownloader) { phase in
            if let image = phase.image {
                content(image)
            } else {
                placeholder()
            }
        }
    }

    private init(
        request: ImageRequest?,
        imageDownloader: ImageDownloader = .shared,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.request = request
        self.imageDownloader = imageDownloader
        self.content = content
    }

    // MARK: - Helpers

    private func fetchImage() async {
        do {
            guard let request, let url = request.source.url else {
                phase = .empty
                return
            }

            if let image = imageDownloader.cachedImage(for: url) {
                phase = .success(Image(uiImage: image))
            } else {
                phase = .empty
                let image = try await imageDownloader.image(for: request)
                phase = .success(Image(uiImage: image))
            }
        } catch {
            phase = .failure(error)
        }
    }
}

fileprivate let testURL = URL(string: "https://i0.wp.com/themes.svn.wordpress.org/twentytwentyfive/1.3/screenshot.png")!

// This video is the preview because it's not just black for the first frame, and right now video previews only fetch the first frame
fileprivate let videoURL = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4")!

#Preview("Basic Image") {
    CachedAsyncImage(url: testURL)
}

#Preview("Image Sized to fit") {
    CachedAsyncImage(url: testURL) { image in
        image.resizable().scaledToFit()
    } placeholder: {
        Text("Loading")
    }
}

#Preview("Image that never loads") {
    CachedAsyncImage(url: nil) { image in
        Text("This shouldn't be visible")
    } placeholder: {
        ProgressView("Forever loading...")
    }
}

@available(iOS 18.0, *)
#Preview("Manual State Handling") {

    @Previewable let cases: [String: URL?] = [
        "Success": testURL,
        "Failure": URL(string: "example://foo/bar"),
        "Never": nil
    ]

    TabView {
        ForEach(cases.keys.sorted().reversed(), id: \.self) { key in
            Tab(key, systemImage: "placeholdertext.fill") {
                CachedAsyncImage(url: cases[key]!, host: nil) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fit)
                    case .failure:
                        Color.red
                    default:
                        Color.gray
                    }
                }
            }
        }
    }
}

#Preview("Video") {
    CachedAsyncImage(videoUrl: videoURL) { image in
        image.resizable().aspectRatio(contentMode: .fit)
    } placeholder: {
        Text("Loading")
    }
}
