import UIKit

final class ImageRequest {
    enum Source {
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

    init(url: URL, host: MediaHost? = nil, options: ImageRequestOptions = .init()) {
        self.source = .url(url, host)
        self.options = options
    }

    init(urlRequest: URLRequest, options: ImageRequestOptions = .init()) {
        self.source = .urlRequest(urlRequest)
        self.options = options
    }
}

struct ImageRequestOptions {
    /// Resize the thumbnail to the given size (in pixels). By default, `nil`.
    var size: CGSize?

    /// If enabled, uses ``MemoryCache`` for caching decompressed images.
    var isMemoryCacheEnabled = true

    /// If enabled, uses `URLSession` preconfigured with a custom `URLCache`
    /// with a relatively high disk capacity. By default, `true`.
    var isDiskCacheEnabled = true
}
