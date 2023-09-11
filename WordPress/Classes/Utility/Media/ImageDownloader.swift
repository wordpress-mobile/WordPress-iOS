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

extension URLSession: ImageDownloaderTask {
    func cancel() {
        invalidateAndCancel()
    }
}

// MARK: - Image Downloading

final class ImageDownloader {

    /// Shared Instance!
    ///
    static let shared = ImageDownloader()

    /// Internal URLSession Instance
    ///
    private let session = URLSession(configuration: {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = ImageDownloader.sharedUrlCache
        return configuration
    }())

    /// Shared url cached used by a default ``ImageDownloader``. The cache is
    /// initialized with 0 MB memory capacity and 256 MB disk capacity.
    static let sharedUrlCache: URLCache = {
        let diskCapacity = 256 * 1048576 // 256 MB
        let cachePath = "com.automattic.ImageDownloader.Cache"
        return URLCache(memoryCapacity: 0, diskCapacity: diskCapacity, diskPath: cachePath)
    }()

    deinit {
        session.invalidateAndCancel()
    }

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

    /// Downloads the UIImage resource at the specified URL. On completion the received closure will be executed.
    ///
    @discardableResult
    func downloadImage(at url: URL, completion: @escaping (UIImage?, Error?) -> Void) -> ImageDownloaderTask {
        var request = URLRequest(url: url)
        request.addValue("image/*", forHTTPHeaderField: "Accept")

        return downloadImage(for: request, completion: completion)
    }

    /// Downloads the UIImage resource at the specified endpoint. On completion the received closure will be executed.
    ///
    @discardableResult
    func downloadImage(for request: URLRequest, completion: @escaping (UIImage?, Error?) -> Void) -> ImageDownloaderTask {
        let task = session.dataTask(with: request) { (data, _, error) in
            guard let data = data else {
                if let error = error {
                    completion(nil, error)
                } else {
                    completion(nil, ImageDownloaderError.failed)
                }
              return
            }

            if let gif = self.makeGIF(with: data, request: request) {
                completion(gif, nil)
            } else if let image = UIImage.init(data: data) {
                completion(image, nil)
            } else {
                completion(nil, ImageDownloaderError.failed)
            }
        }

        task.resume()
        return task
    }

    private func makeGIF(with data: Data, request: URLRequest) -> AnimatedImageWrapper? {
        guard let url = request.url, url.pathExtension.lowercased() == "gif" else {
            return nil
        }

        return AnimatedImageWrapper(gifData: data)
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

// MARK: - Error Types
//
enum ImageDownloaderError: Error {
    case failed
}
