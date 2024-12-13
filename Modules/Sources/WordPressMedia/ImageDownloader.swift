import UIKit

/// The system that downloads and caches images, and prepares them for display.
@ImageDownloaderActor
public final class ImageDownloader {
    private nonisolated let cache: MemoryCacheProtocol
    private let authenticator: MediaRequestAuthenticatorProtocol?

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
        cache: MemoryCacheProtocol = MemoryCache.shared,
        authenticator: MediaRequestAuthenticatorProtocol?
    ) {
        self.cache = cache
        self.authenticator = authenticator
    }

    public func image(from url: URL, host: MediaHost? = nil, options: ImageRequestOptions = .init()) async throws -> UIImage {
        try await image(for: ImageRequest(url: url, host: host, options: options))
    }

    public func image(for request: ImageRequest) async throws -> UIImage {
        let options = request.options
        let key = makeKey(for: request.source.url, size: options.size)
        if options.isMemoryCacheEnabled, let image = cache[key] {
            return image
        }
        let data = try await data(for: request)
        let image = try await ImageDecoder.makeImage(from: data, size: options.size)
        if options.isMemoryCacheEnabled {
            cache[key] = image
        }
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
            if let host, let authenticator {
                request = try await authenticator.authenticatedRequest(for: url, host: host)
            } else {
                request = URLRequest(url: url)
            }
            request.addValue("image/*", forHTTPHeaderField: "Accept")
            return request
        case .urlRequest(let urlRequest):
            return urlRequest
        }
    }

    // MARK: - Caching

    /// Returns an image from the memory cache.
    ///
    /// - note: Use it to retrieve the image synchronously, which is no not possible
    /// with the async functions.
    nonisolated public func cachedImage(for imageURL: URL, size: CGSize? = nil) -> UIImage? {
        cache[makeKey(for: imageURL, size: size)]
    }

    nonisolated public func setCachedImage(_ image: UIImage?, for imageURL: URL, size: CGSize? = nil) {
        cache[makeKey(for: imageURL, size: size)] = image
    }

    private nonisolated func makeKey(for imageURL: URL?, size: CGSize?) -> String {
        guard let imageURL else {
            assertionFailure("The request.url was nil") // This should never happen
            return ""
        }
        return imageURL.absoluteString + (size.map { "?size=\($0)" } ?? "")
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

    func getData(subscriptionID: UUID) async throws -> Data {
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

public protocol MediaRequestAuthenticatorProtocol: Sendable {
    @MainActor func authenticatedRequest(for url: URL, host: MediaHost) async throws -> URLRequest
}
