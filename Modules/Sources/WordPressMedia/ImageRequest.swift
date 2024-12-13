import UIKit

public final class ImageRequest: Sendable {
    public enum Source: Sendable {
        case url(URL, MediaHost?)
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

    public init(url: URL, host: MediaHost? = nil, options: ImageRequestOptions = .init()) {
        self.source = .url(url, host)
        self.options = options
    }

    public init(urlRequest: URLRequest, options: ImageRequestOptions = .init()) {
        self.source = .urlRequest(urlRequest)
        self.options = options
    }
}

public struct ImageRequestOptions: Sendable {
    /// Resize the thumbnail to the given size (in pixels). By default, `nil`.
    public var size: CGSize?

    /// If enabled, uses ``MemoryCache`` for caching decompressed images.
    public var isMemoryCacheEnabled = true

    /// If enabled, uses `URLSession` preconfigured with a custom `URLCache`
    /// with a relatively high disk capacity. By default, `true`.
    public var isDiskCacheEnabled = true

    public init(
        size: CGSize? = nil,
        isMemoryCacheEnabled: Bool = true,
        isDiskCacheEnabled: Bool = true
    ) {
        self.size = size
        self.isMemoryCacheEnabled = isMemoryCacheEnabled
        self.isDiskCacheEnabled = isDiskCacheEnabled
    }
}
