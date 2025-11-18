import UIKit
import CryptoKit
import AVFoundation

/// The system that downloads and caches images, and prepares them for display.
@ImageDownloaderActor
public final class ImageDownloader {
    public nonisolated static let shared = ImageDownloader()

    private nonisolated let cache: MemoryCacheProtocol

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

    public nonisolated init(
        cache: MemoryCacheProtocol = MemoryCache.shared
    ) {
        self.cache = cache
    }

    public func image(
        from url: URL,
        host: MediaHostProtocol? = nil,
        options: ImageRequestOptions = ImageRequestOptions()
    ) async throws -> UIImage {
        try await image(for: ImageRequest(url: url, host: host, options: options))
    }

    public func image(for request: ImageRequest) async throws -> UIImage {
        let options = request.options
        let key = makeKey(for: request.source.url, size: options.size)

        if let cachedImage = try self.fetch(key, options: request.options) {
            return cachedImage
        }

        if case .video(let url, let mediaHost) = request.source {
            let asset: AVAsset = try await mediaHost?.authenticatedAsset(for: url) ?? AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)

            if let size = options.size {
                generator.maximumSize = CGSize(width: size.width, height: size.height)
            }

            let result = try await generator.image(at: .zero)
            let image = UIImage(cgImage: result.image)

            try store(image, for: key, options: options)

            return image
        }

        let data = try await data(for: request)
        let image = try await ImageDecoder.makeImage(from: data, size: options.size.map(CGSize.init))

        try store(image, for: key, options: options)

        return image
    }

    public func data(for request: ImageRequest) async throws -> Data {
        let urlRequest = try await makeURLRequest(for: request)
        return try await _data(for: urlRequest, options: request.options)
    }

    private func makeURLRequest(for request: ImageRequest) async throws -> URLRequest {
        switch request.source {
        case .url(let url, let host):
            var request: URLRequest
            if let host {
                request = try await host.authenticatedRequest(for: url)
            } else {
                request = URLRequest(url: url)
            }
            request.addValue("image/*", forHTTPHeaderField: "Accept")
            return request
        case .urlRequest(let urlRequest):
            return urlRequest
        case .video:
            preconditionFailure("Cannot make URLRequest for video – use AVFoundation APIs instead")
        }
    }

    // MARK: - Caching

    /// Returns an image from the memory cache.
    nonisolated public func cachedImage(for request: ImageRequest) -> UIImage? {
        guard let imageURL = request.source.url else { return nil }
        return cachedImage(for: imageURL, size: request.options.size)
    }

    /// Returns an image from the memory cache.
    ///
    /// - note: Use it to retrieve the image synchronously, which is no not possible
    /// with the async functions.
    nonisolated public func cachedImage(for imageURL: URL, size: ImageSize? = nil) -> UIImage? {
        cache[makeKey(for: imageURL, size: size)]
    }

    nonisolated public func setCachedImage(_ image: UIImage?, for imageURL: URL, size: ImageSize? = nil) {
        cache[makeKey(for: imageURL, size: size)] = image
    }

    private nonisolated func makeKey(for imageURL: URL?, size: ImageSize?) -> String {
        guard let imageURL else {
            assertionFailure("The request.url was nil") // This should never happen
            return ""
        }
        return imageURL.absoluteString + (size.map { "?w=\($0.width),h=\($0.height)" } ?? "")
    }

    public func clearURLSessionCache() {
        urlSessionWithCache.configuration.urlCache?.removeAllCachedResponses()
        urlSession.configuration.urlCache?.removeAllCachedResponses()
    }

    public func clearMemoryCache() {
        self.cache.removeAllObjects()
    }

    // MARK: - Networking

    private func _data(for request: URLRequest, options: ImageRequestOptions) async throws -> Data {
        let requestKey = request.url?.absoluteString ?? ""
        let task = tasks[requestKey] ?? ImageDataTask(key: requestKey, Task {
            try await self._data(for: request, options: options, key: requestKey)
        })
        task.downloader = self

        let subscriptionID = UUID()
        task.subscriptions.insert(subscriptionID)
        tasks[requestKey] = task

        return try await task.getData(subscriptionID: subscriptionID)
    }

    fileprivate nonisolated func unsubscribe(_ subscriptionID: UUID, key: String) {
        Task {
            await _unsubscribe(subscriptionID, key: key)
        }
    }

    private func _unsubscribe(_ subscriptionID: UUID, key: String) {
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

    // MARK: Manual caching
    private func fetch(_ key: String, options: ImageRequestOptions) throws -> UIImage? {

        if options.isMemoryCacheEnabled, let image = cache[key] {
            return image
        }

        guard options.isDiskCacheEnabled else {
            return nil
        }

        let path = path(for: key)

        guard FileManager.default.fileExists(atPath: path.path()) else {
            return nil
        }

        let pngData = try Data(contentsOf: path)
        return UIImage(data: pngData)
    }

    private func store(_ image: UIImage, for key: String, options: ImageRequestOptions) throws {

        if options.isMemoryCacheEnabled {
            cache[key] = image
        }

        // If the image is immutable, store it in the disk cache "forever"
        guard options.isDiskCacheEnabled, options.mutability == .immutable else {
            return
        }

        guard let data = image.pngData() else {
            return
        }

        let path = self.path(for: key)

        try FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: path)
    }

    private func path(for key: String) -> URL {
        let hash = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        return URL.cachesDirectory.appending(path: "image-cache").appending(path: hash)
    }
}

@ImageDownloaderActor
private final class ImageDataTask {
    let key: String
    var subscriptions = Set<UUID>()
    let task: Task<Data, Error>
    weak var downloader: ImageDownloader?

    init(key: String, _ task: Task<Data, Error>) {
        self.key = key
        self.task = task
    }

    nonisolated func getData(subscriptionID: UUID) async throws -> Data {
        try await withTaskCancellationHandler {
            try await task.value
        } onCancel: { [weak downloader, key] in
            downloader?.unsubscribe(subscriptionID, key: key)
        }
    }
}

// MARK: - Helpers

@globalActor
public struct ImageDownloaderActor {
    public actor ImageDownloaderActor { }
    public static let shared = ImageDownloaderActor()
}

public enum ImageDownloaderError: Error, Sendable {
    case unacceptableStatusCode(_ statusCode: Int?)
}

private extension URLSession {
    convenience init(_ conifgure: (URLSessionConfiguration) -> Void) {
        let configuration = URLSessionConfiguration.default
        conifgure(configuration)
        self.init(configuration: configuration)
    }
}

public protocol MediaHostProtocol: Sendable {
    @MainActor func authenticatedRequest(for url: URL) async throws -> URLRequest
    @MainActor func authenticatedAsset(for url: URL) async throws -> AVURLAsset
}
