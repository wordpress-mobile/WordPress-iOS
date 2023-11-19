import UIKit

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

    private let cache: MemoryCache = .shared

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

    // MARK: - Images (URL)

    /// Downloads image for the given `URL`.
    func image(from url: URL, options: ImageRequestOptions = .init()) async throws -> UIImage {
        var request = URLRequest(url: url)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        return try await image(from: request, options: options)
    }

    /// Downloads image for the given `URLRequest`.
    func image(from request: URLRequest, options: ImageRequestOptions = .init()) async throws -> UIImage {
        if options.isMemoryCacheEnabled, let url = request.url, let image = cachedImage(for: url, targetSize: options.targetSize) {
            return image
        }
        let data = try await data(for: request, options: options)
        let image = try await ImageDecoder.makeImage(from: data, size: options.size)
        if options.isMemoryCacheEnabled, let url = request.url {
            setCachedImage(image, for: url, targetSize: options.targetSize)
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
    nonisolated func cachedImage(for imageURL: URL, targetSize: CGSize? = nil) -> UIImage? {
        cache[makeCacheKey(for: imageURL, targetSize: targetSize)]
    }

    nonisolated func setCachedImage(_ image: UIImage?, for imageURL: URL, targetSize: CGSize? = nil) {
        cache[makeCacheKey(for: imageURL, targetSize: targetSize)] = image
    }

    private nonisolated func makeCacheKey(for imageURL: URL, targetSize: CGSize?) -> String {
        let imageURL = imageURL.absoluteString
        guard let targetSize else { return imageURL }
        return "\(imageURL)?size=\(targetSize)"
    }

    // MARK: - Networking

    private func data(for request: URLRequest, options: ImageRequestOptions) async throws -> Data {
        let session = options.isDiskCacheEnabled ? urlSessionWithCache : urlSession
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return data
    }

    private func validate(response: URLResponse) throws {
        guard let response = response as? HTTPURLResponse else {
            throw ImageDownloaderError.unexpectedResponse
        }
        guard (200..<400).contains(response.statusCode) else {
            throw ImageDownloaderError.unacceptableStatusCode(response.statusCode)
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
                let image = try await self.image(from: request, options: .init())
                completion(image, nil)
            } catch {
                completion(nil, error)
            }
        }
        return AnonumousImageDownloadTask(closure: task.cancel)
    }
}

// MARK: - AnimatedImageWrapper

/// This is a wrapper around `RCTAnimatedImage` that allows including extra information
/// to better render the gifs in text views.
///
/// This class uses the RCTAnimatedImage to verify the image is a valid gif which is why I'm still
/// using that here.
class AnimatedImageWrapper: UIImage {
    var gifData: Data? = nil
    var targetSize: CGSize? = nil

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

private struct AnonumousImageDownloadTask: ImageDownloaderTask {
    let closure: () -> Void

    func cancel() {
        closure()
    }
}

enum ImageDownloaderError: Error {
    case unexpectedResponse
    case unacceptableStatusCode(_ statusCode: Int?)
}

private extension URLSession {
    convenience init(_ conifgure: (URLSessionConfiguration) -> Void) {
        let configuration = URLSessionConfiguration.default
        conifgure(configuration)
        self.init(configuration: configuration)
    }
}
