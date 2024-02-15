import UIKit
import SwiftUI

struct ImageRequestOptions {
    /// Resize the thumbnail to the given size. By default, `nil`.
    var size: CGSize?

    /// If enabled, uses ``MemoryCache`` for caching decompressed images.
    var isMemoryCacheEnabled = true

    /// If enabled, uses `URLSession` preconfigured with a custom `URLCache`
    /// with a relatively high disk capacity. By default, `true`.
    var isDiskCacheEnabled = true
}

/// The system that downloads and caches images, and prepares them for display.
actor ImageDownloader {
    static let shared = ImageDownloader()

    private let cache: MemoryCacheProtocol

    private let urlSession = URLSession {
        $0.urlCache = nil
    }

    private let urlSessionWithCache = URLSession {
        $0.urlCache = URLCache(
            memoryCapacity: 32 * 1024 * 1024, // 32 MB
            diskCapacity: 256 * 1024 * 1024,  // 256 MB
            diskPath: "org.automattic.ImageDownloader"
        )
    }

    private var tasks: [String: ImageDataTask] = [:]

    init(cache: MemoryCacheProtocol = MemoryCache.shared) {
        self.cache = cache
    }

    // MARK: - Images (URL)

    /// Downloads image for the given `URL`.
    func image(from url: URL, options: ImageRequestOptions = .init()) async throws -> UIImage {
        var request = URLRequest(url: url)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        return try await image(from: request, options: options)
    }
    
    /// Downloads image for the given `URL`.
    /// Returns SwiftUI.Image
    func image(from url: URL, options: ImageRequestOptions = .init()) async throws -> SwiftUI.Image {
        return try await Image(uiImage: image(from: url, options: options))
    }

    /// Downloads image for the given `URLRequest`.
    func image(from request: URLRequest, options: ImageRequestOptions = .init()) async throws -> UIImage {
        let key = makeKey(for: request.url, size: options.size)
        if options.isMemoryCacheEnabled, let image = cache[key] {
            return image
        }
        let data = try await data(for: request, options: options)
        let image = try await ImageDecoder.makeImage(from: data, size: options.size)
        if options.isMemoryCacheEnabled {
            cache[key] = image
        }
        return image
    }

    // MARK: - Images (Blog)

    /// Returns image for the given URL authenticated for the given host.
    func image(from imageURL: URL, host: MediaHost, options: ImageRequestOptions) async throws -> UIImage {
        let request = try await authenticatedRequest(for: imageURL, host: host)
        return try await image(from: request, options: options)
    }

    /// Returns data for the given URL authenticated for the given host.
    func data(from imageURL: URL, host: MediaHost, options: ImageRequestOptions) async throws -> Data {
        let request = try await authenticatedRequest(for: imageURL, host: host)
        return try await data(for: request, options: options)
    }

    private func authenticatedRequest(for imageURL: URL, host: MediaHost) async throws -> URLRequest {
        var request = try await MediaRequestAuthenticator()
            .authenticatedRequest(for: imageURL, host: host)
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        return request
    }

    // MARK: - Caching

    /// Returns an image from the memory cache.
    ///
    /// - note: Use it to retrieve the image synchronously, which is no not possible
    /// with the async functions.
    nonisolated func cachedImage(for imageURL: URL, size: CGSize? = nil) -> UIImage? {
        cache[makeKey(for: imageURL, size: size)]
    }

    /// Returns an image from the memory cache.
    ///
    /// - note: Use it to retrieve the image synchronously, which is no not possible
    /// with the async functions.
    nonisolated func cachedImage(for imageURL: URL, size: CGSize? = nil) -> Image? {
        if let uiImage = cache[makeKey(for: imageURL, size: size)] {
            return Image(uiImage: uiImage)
        } else {
            return nil
        }
    }

    nonisolated func setCachedImage(_ image: UIImage?, for imageURL: URL, size: CGSize? = nil) {
        cache[makeKey(for: imageURL, size: size)] = image
    }

    private nonisolated func makeKey(for imageURL: URL?, size: CGSize?) -> String {
        guard let imageURL else {
            assertionFailure("The request.url was nil") // This should never happen
            return ""
        }
        return imageURL.absoluteString + (size.map { "?size=\($0)" } ?? "")
    }

    // MARK: - Networking

    private func data(for request: URLRequest, options: ImageRequestOptions) async throws -> Data {
        let requestKey = request.urlRequest?.url?.absoluteString ?? ""
        let task = tasks[requestKey] ?? ImageDataTask(task: Task {
            try await self._data(for: request, options: options, key: requestKey)
        })
        let subscriptionID = UUID()
        task.subscriptions.insert(subscriptionID)
        tasks[requestKey] = task

        return try await withTaskCancellationHandler {
            try await task.task.value
        } onCancel: {
            Task {
                await self.unsubscribe(subscriptionID, key: requestKey)
            }
        }
    }

    private func unsubscribe(_ subscriptionID: UUID, key: String) {
        guard let task = tasks[key],
              task.subscriptions.remove(subscriptionID) != nil,
              task.subscriptions.isEmpty else {
            return
        }
        task.task.cancel()
        tasks[key] = nil
    }

    private func _data(for request: URLRequest, options: ImageRequestOptions, key: String) async throws -> Data {
        defer { tasks[key] = nil }
        let session = options.isDiskCacheEnabled ? urlSessionWithCache : urlSession
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return data
    }

    private func validate(response: URLResponse) throws {
        guard let response = response as? HTTPURLResponse else {
            return // The request was made not over HTTP, e.g. a `file://` request
        }
        guard (200..<400).contains(response.statusCode) else {
            throw ImageDownloaderError.unacceptableStatusCode(response.statusCode)
        }
    }
}

private final class ImageDataTask {
    var subscriptions = Set<UUID>()
    var isCancelled = false
    var task: Task<Data, Error>

    init(subscriptions: Set<UUID> = Set<UUID>(), task: Task<Data, Error>) {
        self.subscriptions = subscriptions
        self.task = task
    }
}

// MARK: - ImageDownloader (Closures)

extension ImageDownloader {
    @discardableResult
    nonisolated func downloadImage(at url: URL, completion: @escaping (UIImage?, Error?) -> Void) -> ImageDownloaderTask {
        var request = URLRequest(url: url)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        return downloadImage(for: request, completion: completion)
    }

    @discardableResult
    nonisolated func downloadImage(for request: URLRequest, completion: @escaping (UIImage?, Error?) -> Void) -> ImageDownloaderTask {
        let task = Task {
            do {
                let image = try await self.image(from: request, options: .init())
                completion(image, nil)
            } catch {
                completion(nil, error)
            }
        }
        return AnonymousImageDownloadTask(closure: task.cancel)
    }
}

// MARK: - AnimatedImage

final class AnimatedImage: UIImage {
    private(set) var gifData: Data?
    var targetSize: CGSize?

    private static let playbackStrategy: GIFPlaybackStrategy = LargeGIFPlaybackStrategy()

    convenience init?(gifData: Data) {
        self.init(data: gifData, scale: 1)

        // Don't store the gifdata if they're too large
        // We still allow the the RCTAnimatedImage to be rendered since it will still render
        // the first frame, but not eat up data
        guard gifData.count < Self.playbackStrategy.maxSize else {
            return
        }

        self.gifData = gifData
    }
}

// MARK: - Helpers

protocol ImageDownloaderTask {
    func cancel()
}

extension Operation: ImageDownloaderTask {}
extension URLSessionTask: ImageDownloaderTask {}

private struct AnonymousImageDownloadTask: ImageDownloaderTask {
    let closure: () -> Void

    func cancel() {
        closure()
    }
}

enum ImageDownloaderError: Error {
    case unacceptableStatusCode(_ statusCode: Int?)
}

private extension URLSession {
    convenience init(_ conifgure: (URLSessionConfiguration) -> Void) {
        let configuration = URLSessionConfiguration.default
        conifgure(configuration)
        self.init(configuration: configuration)
    }
}
