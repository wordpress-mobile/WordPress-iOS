import UIKit

public final class ImageRequest: Sendable {
    public enum Source: Sendable {
        case url(URL, MediaHostProtocol?)
        case urlRequest(URLRequest)

        var url: URL? {
            switch self {
            case .url(let url, _): url
            case .urlRequest(let request): request.url
            }
        }
    }

    let source: Source
    let options: ImageRequestOptions

    public init(url: URL, host: MediaHostProtocol? = nil, options: ImageRequestOptions = .init()) {
        self.source = .url(url, host)
        self.options = options
    }

    public init(urlRequest: URLRequest, options: ImageRequestOptions = .init()) {
        self.source = .urlRequest(urlRequest)
        self.options = options
    }
}

public struct ImageRequestOptions: Hashable, Sendable {
    /// Resize the thumbnail to the given size. By default, `nil`.
    public var size: ImageSize?

    /// If enabled, uses ``MemoryCache`` for caching decompressed images.
    public var isMemoryCacheEnabled = true

    /// If enabled, uses `URLSession` preconfigured with a custom `URLCache`
    /// with a relatively high disk capacity. By default, `true`.
    public var isDiskCacheEnabled = true

    public init(
        size: ImageSize? = nil,
        isMemoryCacheEnabled: Bool = true,
        isDiskCacheEnabled: Bool = true
    ) {
        self.size = size
        self.isMemoryCacheEnabled = isMemoryCacheEnabled
        self.isDiskCacheEnabled = isDiskCacheEnabled
    }
}

/// Image size in **pixels**.
public struct ImageSize: Hashable, Sendable {
    /// Width in **pixels**.
    public var width: Int
    /// Height in **pixels**.
    public var height: Int

    /// Initializes the struct with given size in **pixels**.
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    /// Initializes the struct with given size in **pixels**.
    public init(pixels size: CGSize) {
        self.width = Int(size.width)
        self.height = Int(size.height)
    }

    /// A convenience initializer that creates `ImageSize` with the given size
    /// in **points** scaled for the given view.
    @MainActor
    public init(scaling size: CGSize, in view: UIView) {
        self.init(scaling: size, scale: view.traitCollection.displayScale)
    }

    /// Initializes `ImageSize` with the given size in **points** scaled for the
    /// current trait collection display scale.
    public init(scaling size: CGSize, scale: CGFloat) {
        self.init(pixels: size.scaled(by: max(1, scale)))
    }
}

extension CGSize {
    init(_ size: ImageSize) {
        self.init(width: size.width, height: size.height)
    }
}
