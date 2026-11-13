import UIKit
import AsyncImageKit

// MARK: - ImageDownloader (Closures)

extension ImageDownloader {
    /// Calls `completion` on the main thread.
    @discardableResult
    nonisolated public func downloadImage(
        at url: URL,
        completion: @escaping (UIImage?, Error?) -> Void
    ) -> ImageDownloaderTask {
        var request = URLRequest(url: url)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        return downloadImage(for: request, completion: completion)
    }

    /// Calls `completion` on the main thread.
    @discardableResult
    nonisolated public func downloadImage(
        for request: URLRequest,
        completion: @escaping (UIImage?, Error?) -> Void
    ) -> ImageDownloaderTask {
        let task = Task { @MainActor in
            do {
                let image = try await self.image(for: ImageRequest(urlRequest: request))
                completion(image, nil)
            } catch {
                completion(nil, error)
            }
        }
        return AnonymousImageDownloadTask(closure: { task.cancel() })
    }
}

public protocol ImageDownloaderTask: Sendable {
    func cancel()
}

extension Operation: ImageDownloaderTask {}

private struct AnonymousImageDownloadTask: ImageDownloaderTask {
    let closure: @Sendable () -> Void

    func cancel() {
        closure()
    }
}
