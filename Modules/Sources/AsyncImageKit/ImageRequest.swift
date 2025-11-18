import UIKit

public final class ImageRequest: Sendable {
    public enum Source: Sendable {
        case url(URL, MediaHostProtocol?)
        case urlRequest(URLRequest)
        case video(URL, MediaHostProtocol?)

        var url: URL? {
            switch self {
            case .url(let url, _): url
            case .urlRequest(let request): request.url
            case .video(let url, _): url
            }
        }

        var host: MediaHostProtocol? {
            switch self {
            case .url(_, let host): host
            case .urlRequest: nil
            case .video(_, let host): host
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

    public init(videoUrl: URL, host: MediaHostProtocol? = nil, options: ImageRequestOptions = ImageRequestOptions()) {
        self.source = .video(videoUrl, host)
        self.options = options
    }
}

/// Defines the mutability characteristics of a resource for caching purposes.
///
/// This affects how aggressively the resource is cached:
/// - `.mutable`: Resources are cached in memory and URLSession's disk cache (with eviction policies)
/// - `.immutable`: Resources are additionally cached persistently on disk (never evicted automatically)
public enum ResourceMutability: Sendable {
    /// Items that might change over time while keeping the same URL.
    ///
    /// These resources are cached in memory and URLSession's disk cache, but not persistently.
    /// The cache may be evicted based on system policies.
    ///
    /// **Example**: Site Icons, Gravatars - the same URL might return different images as users update their profiles
    case mutable

    /// Items that will never be modified after creation.
    ///
    /// These resources are cached persistently on disk in addition to in-memory caching.
    /// Once downloaded, they remain cached indefinitely since the content at the URL will never change.
    ///
    /// **Example**: Support ticket attachments - these URLs point to immutable content
    case immutable
}

public struct ImageRequestOptions: Hashable, Sendable {
    /// Resize the thumbnail to the given size. By default, `nil`.
    public var size: ImageSize?

    /// If enabled, uses ``MemoryCache`` for caching decompressed images.
    public var isMemoryCacheEnabled = true

    /// If enabled, uses `URLSession` preconfigured with a custom `URLCache`
    /// with a relatively high disk capacity. By default, `true`.
    public var isDiskCacheEnabled = true

    /// Indicates how this asset should be cached based on whether the content can change.
    ///
    /// Use `.mutable` (default) for resources that might change over time (like user avatars).
    /// Use `.immutable` for resources that never change (like support attachments) to enable
    /// persistent disk caching that survives app restarts and system cache evictions.
    ///
    /// - Note: Only applies when `isDiskCacheEnabled` is `true`
    public let mutability: ResourceMutability

    public init(
        size: ImageSize? = nil,
        isMemoryCacheEnabled: Bool = true,
        isDiskCacheEnabled: Bool = true,
        mutability: ResourceMutability = .mutable
    ) {
        self.size = size
        self.isMemoryCacheEnabled = isMemoryCacheEnabled
        self.isDiskCacheEnabled = isDiskCacheEnabled
        self.mutability = mutability
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
