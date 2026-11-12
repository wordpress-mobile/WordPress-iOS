import UIKit
import CryptoKit
import AVFoundation
import Synchronization

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
            diskCapacity: 256 * 1024 * 1024, // 256 MB
            diskPath: "org.automattic.ImageDownloader"
        )
    }

    private var tasks: [String: ImageDataTask] = [:]

    /// Where immutable images are saved. Nothing evicts them automatically.
    private nonisolated let diskCacheDirectory: URL

    public nonisolated convenience init(
        cache: MemoryCacheProtocol = MemoryCache.shared
    ) {
        self.init(cache: cache, diskCacheDirectory: URL.cachesDirectory.appending(path: "image-cache"))
    }

    nonisolated init(cache: MemoryCacheProtocol, diskCacheDirectory: URL) {
        self.cache = cache
        self.diskCacheDirectory = diskCacheDirectory
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

        if let cachedImage = await self.fetch(key, options: request.options) {
            return cachedImage
        }

        if case .video(let url, let mediaHost) = request.source {
            let asset: AVAsset = try await mediaHost?.authenticatedAsset(for: url) ?? AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            // Show the frame the way the video plays, e.g. upright for a video shot in portrait
            generator.appliesPreferredTrackTransform = true

            if let size = options.size {
                generator.maximumSize = CGSize(width: size.width, height: size.height)
            }

            let result = try await generator.image(at: .zero)
            let image = UIImage(cgImage: result.image)

            // There is no downloaded file to save, so save the frame
            try store(image, data: { image.jpegData(compressionQuality: 0.9) }, for: key, options: options)

            return image
        }

        let data = try await data(for: request)
        let image = try await ImageDecoder.makeImage(from: data, size: options.size.map(CGSize.init))

        try store(image, data: { data }, for: key, options: options)

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

    /// The current disk usage of the URL cache and the saved immutable images, in bytes.
    public var diskCacheSize: Int {
        let urlCacheSize = urlSessionWithCache.configuration.urlCache?.currentDiskUsage ?? 0
        let files = try? FileManager.default.contentsOfDirectory(
            at: diskCacheDirectory,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey]
        )
        let savedImagesSize = (files ?? [])
            .reduce(0) { size, file in
                size + ((try? file.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize) ?? 0)
            }
        return urlCacheSize + savedImagesSize
    }

    public func clearURLSessionCache() {
        urlSessionWithCache.configuration.urlCache?.removeAllCachedResponses()
        urlSession.configuration.urlCache?.removeAllCachedResponses()
    }

    /// Removes the URL cache and the saved immutable images.
    public func clearDiskCache() {
        clearURLSessionCache()
        try? FileManager.default.removeItem(at: diskCacheDirectory)
    }

    public func clearMemoryCache() {
        self.cache.removeAllObjects()
    }

    // MARK: - Networking

    private func _data(for request: URLRequest, options: ImageRequestOptions) async throws -> Data {
        let requestKey = request.url?.absoluteString ?? ""
        // A failed download stays in `tasks` until it gets back on this actor, which can be after a
        // request with a higher priority. Don't share its error with that request.
        let existingTask = tasks[requestKey].flatMap { $0.hasFailed ? nil : $0 }
        let task = existingTask ?? makeTask(for: request, options: options, key: requestKey)
        task.downloader = self

        let subscriptionID = UUID()
        task.subscriptions.insert(subscriptionID)
        tasks[requestKey] = task

        return try await task.getData(subscriptionID: subscriptionID)
    }

    private func makeTask(for request: URLRequest, options: ImageRequestOptions, key: String) -> ImageDataTask {
        let id = UUID()
        let failure = FailureFlag()
        return ImageDataTask(
            id: id,
            key: key,
            failure: failure,
            Task {
                try await self.download(request, options: options, key: key, id: id, failure: failure)
            }
        )
    }

    fileprivate nonisolated func unsubscribe(_ subscriptionID: UUID, key: String) {
        Task {
            await _unsubscribe(subscriptionID, key: key)
        }
    }

    private func _unsubscribe(_ subscriptionID: UUID, key: String) {
        guard let task = tasks[key],
            task.subscriptions.remove(subscriptionID) != nil,
            task.subscriptions.isEmpty
        else {
            return
        }
        task.task.cancel()
        tasks[key] = nil
    }

    private func download(
        _ request: URLRequest,
        options: ImageRequestOptions,
        key: String,
        id: UUID,
        failure: FailureFlag
    ) async throws -> Data {
        defer {
            // Remove only this download. Once cancelled, it can finish after a newer download for
            // the same URL has replaced it, and that one must stay shared.
            if tasks[key]?.id == id {
                tasks[key] = nil
            }
        }
        let session = options.isDiskCacheEnabled ? urlSessionWithCache : urlSession
        return try await Self.data(for: request, session: session, failure: failure)
    }

    /// Downloads the data off the actor, so that a failure is recorded as soon as it happens.
    private nonisolated static func data(
        for request: URLRequest,
        session: URLSession,
        failure: FailureFlag
    ) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            try validate(response: response)
            return data
        } catch {
            failure.set()
            throw error
        }
    }

    private nonisolated static func validate(response: URLResponse) throws {
        guard let response = response as? HTTPURLResponse else {
            return // The request was made not over HTTP, e.g. a `file://` request
        }
        guard (200..<400).contains(response.statusCode) else {
            throw ImageDownloaderError.unacceptableStatusCode(response.statusCode)
        }
    }

    // MARK: Manual caching
    private func fetch(_ key: String, options: ImageRequestOptions) async -> UIImage? {

        if options.isMemoryCacheEnabled, let image = cache[key] {
            return image
        }

        guard options.isDiskCacheEnabled, options.mutability == .immutable else {
            return nil
        }

        // The file is the downloaded image, or a PNG saved by an earlier version of the app.
        // A missing or unreadable file is a cache miss, and the image is downloaded again.
        guard let data = try? Data(contentsOf: path(for: key)),
            let image = try? await ImageDecoder.makeImage(from: data, size: options.size.map(CGSize.init))
        else {
            return nil
        }
        if options.isMemoryCacheEnabled {
            cache[key] = image
        }
        return image
    }

    /// - parameter data: The file to save if the image is immutable.
    private func store(
        _ image: UIImage,
        data: () -> Data?,
        for key: String,
        options: ImageRequestOptions
    ) throws {

        if options.isMemoryCacheEnabled {
            cache[key] = image
        }

        // If the image is immutable, store it in the disk cache "forever"
        guard options.isDiskCacheEnabled, options.mutability == .immutable else {
            return
        }

        guard let data = data() else {
            return
        }

        let path = self.path(for: key)

        try FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: path, options: .atomic)
    }

    /// The file an immutable image is saved to.
    nonisolated func diskCacheFileURL(for imageURL: URL, size: ImageSize? = nil) -> URL {
        path(for: makeKey(for: imageURL, size: size))
    }

    private nonisolated func path(for key: String) -> URL {
        let hash = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        return diskCacheDirectory.appending(path: hash)
    }
}

@ImageDownloaderActor
private final class ImageDataTask {
    let id: UUID
    let key: String
    var subscriptions = Set<UUID>()
    let task: Task<Data, Error>
    weak var downloader: ImageDownloader?
    private let failure: FailureFlag

    /// Whether the download failed. It is set before the download gets back on the actor.
    var hasFailed: Bool { failure.isSet }

    init(id: UUID, key: String, failure: FailureFlag, _ task: Task<Data, Error>) {
        self.id = id
        self.key = key
        self.failure = failure
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

private final class FailureFlag: Sendable {
    private let value = Mutex(false)

    var isSet: Bool { value.withLock { $0 } }

    func set() {
        value.withLock { $0 = true }
    }
}

@globalActor
public struct ImageDownloaderActor {
    public actor ImageDownloaderActor {}
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
