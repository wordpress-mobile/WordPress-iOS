import UIKit

/// The system that downloads and caches images, and prepares them for display.
actor ImageDownloader {
    static let shared = ImageDownloader()

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

    init(cache: MemoryCacheProtocol = MemoryCache.shared) {
        self.cache = cache
    }

    func image(from url: URL, host: MediaHost? = nil, options: ImageRequestOptions = .init()) async throws -> UIImage {
        try await image(for: ImageRequest(url: url, host: host, options: options))
    }

    func image(for request: ImageRequest) async throws -> UIImage {
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

    func data(for request: ImageRequest) async throws -> Data {
        let urlRequest = try await makeURLRequest(for: request)
        return try await _data(for: urlRequest, options: request.options)
    }

    private func makeURLRequest(for request: ImageRequest) async throws -> URLRequest {
        switch request.source {
        case .url(let url, let host):
            var request: URLRequest
            if let host {
                request = try await MediaRequestAuthenticator()
                    .authenticatedRequest(for: url, host: host)
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
    nonisolated func cachedImage(for imageURL: URL, size: CGSize? = nil) -> UIImage? {
        cache[makeKey(for: imageURL, size: size)]
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

    func clearURLSessionCache() {
        urlSessionWithCache.configuration.urlCache?.removeAllCachedResponses()
        urlSession.configuration.urlCache?.removeAllCachedResponses()
    }

    func clearMemoryCache() {
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
        } onCancel: { [weak self] in
            guard let self else { return }
            self.downloader?.unsubscribe(subscriptionID, key: self.key)
        }
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
                let image = try await self.image(for: ImageRequest(urlRequest: request))
                completion(image, nil)
            } catch {
                completion(nil, error)
            }
        }
        return AnonymousImageDownloadTask(closure: task.cancel)
    }
}

// MARK: - AnimatedImage

final class AnimatedImage: UIImage, @unchecked Sendable {
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
