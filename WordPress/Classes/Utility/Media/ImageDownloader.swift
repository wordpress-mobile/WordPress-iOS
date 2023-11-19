import UIKit

// MARK: - ImageDownloadTask protocol

/// This protocol can be implemented to represent an image download task handled by the ImageDownloader.
///
protocol ImageDownloaderTask {
    /// Calling this method should cancel the task's execution.
    ///
    func cancel()
}

extension Operation: ImageDownloaderTask {}
extension URLSessionTask: ImageDownloaderTask {}

struct ImageRequestOptions {
    /// If enabled, uses `URLSession` preconfigured with a custom `URLCache`
    /// with a relatively high disk capacity. By default, `true`.
    var isURLCacheEnabled = true
}

// MARK: - Image Downloading Tool

/// The system that downloads and caches images, and prepares them for display.
actor ImageDownloader {

    /// Shared Instance!
    ///
    static let shared = ImageDownloader()

    /// Internal URLSession Instance
    ///
    private let urlSession = URLSession(configuration: {
        let configuration = URLSessionConfiguration.default
        // The service has a custom disk cache for thumbnails, so it's important to
        // disable the native url cache which is by default set to `URLCache.shared`
        configuration.urlCache = nil
        return configuration
    }())

    private let urlSessionWithCache = URLSession(configuration: {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 32 * 1024 * 1024, // 32 MB
            diskCapacity: 256 * 1024 * 1024,  // 256 MB
            diskPath: "org.automattic.ImageDownloader"
        )
        return configuration
    }())

    /// Downloads image for the given URL.
    func image(at url: URL) async throws -> UIImage {
        var request = URLRequest(url: url)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        return try await image(for: request)
    }

    /// Downloads image for the given request.
    func image(for request: URLRequest) async throws -> UIImage {
        final class CancelationToken {
            var task: ImageDownloaderTask?
        }
        let token = CancelationToken()
        return try await withTaskCancellationHandler {
            try await withUnsafeThrowingContinuation { continuation in
                token.task = downloadImage(for: request) { image, error in
                    if let image {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: error ?? URLError(.unknown))
                    }
                }
            }
        } onCancel: {
            token.task?.cancel()
        }
    }

    /// Returns image for the given URL authenticated for the given host.
    func image(from imageURL: URL, host: MediaHost, options: ImageRequestOptions) async throws -> UIImage {
        let data = try await data(from: imageURL, host: host, options: options)
        return try await ImageDecoder.makeImage(from: data)
    }

    /// Returns data for the given URL authenticated for the given host.
    func data(from imageURL: URL, host: MediaHost, options: ImageRequestOptions) async throws -> Data {
        var request = try await MediaRequestAuthenticator()
            .authenticatedRequest(for: imageURL, host: host)
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        return try await data(for: request, options: options)
    }

    #warning("TODO: reimplement these")

    /// Downloads the UIImage resource at the specified URL. On completion the received closure will be executed.
    ///
    @discardableResult
    nonisolated func downloadImage(at url: URL, completion: @escaping (UIImage?, Error?) -> Void) -> ImageDownloaderTask {
        var request = URLRequest(url: url)
        request.addValue("image/*", forHTTPHeaderField: "Accept")

        return downloadImage(for: request, completion: completion)
    }

    /// Downloads the UIImage resource at the specified endpoint. On completion the received closure will be executed.
    ///
    @discardableResult
    nonisolated func downloadImage(for request: URLRequest, completion: @escaping (UIImage?, Error?) -> Void) -> ImageDownloaderTask {
        let task = urlSession.dataTask(with: request) { (data, _, error) in
//            guard let data = data else {
//                if let error = error {
//                    completion(nil, error)
//                } else {
//                    completion(nil, ImageDownloaderError.failed)
//                }
//              return
//            }
//            if let gif = self.makeGIF(with: data, request: request) {
//                completion(gif, nil)
//            } else if let image = UIImage.init(data: data) {
//                completion(image, nil)
//            } else {
//                completion(nil, ImageDownloaderError.failed)
//            }
        }

        task.resume()
        return task
    }

    // MARK: - Networking

    private func data(for request: URLRequest, options: ImageRequestOptions) async throws -> Data {
        let session = options.isURLCacheEnabled ? urlSessionWithCache : urlSession
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

enum ImageDownloaderError: Error {
    case failed
    case unexpectedResponse
    case unacceptableStatusCode(_ statusCode: Int?)
}
