import Foundation
import UIKit

/// A convenience class for managing image downloads for individual views.
@MainActor
final class ImageViewController {
    var downloader: ImageDownloader = .shared
    var onStateChanged: (State) -> Void = { _ in }

    private(set) var task: Task<Void, Never>?

    enum State {
        case loading
        case success(UIImage)
        case failure(Error)
    }

    deinit {
        task?.cancel()
    }

    func prepareForReuse() {
        task?.cancel()
        task = nil
    }

    /// - parameter completion: Gets called on completion _after_ `onStateChanged`.
    func setImage(
        with imageURL: URL,
        host: MediaHost? = nil,
        size: CGSize? = nil,
        completion: (@MainActor (Result<UIImage, Error>) -> Void)? = nil
    ) {
        task?.cancel()

        if let image = downloader.cachedImage(for: imageURL, size: size) {
            onStateChanged(.success(image))
            completion?(.success(image))
        } else {
            onStateChanged(.loading)
            task = Task { @MainActor [downloader, weak self] in
                do {
                    let options = ImageRequestOptions(size: size)
                    let image: UIImage
                    if let host {
                        image = try await downloader.image(from: imageURL, host: host, options: options)
                    } else {
                        image = try await downloader.image(from: imageURL, options: options)
                    }
                    // This line guarantees that if you cancel on the main thread,
                    // none of the `onStateChanged` callbacks get called.
                    guard !Task.isCancelled else { return }
                    self?.onStateChanged(.success(image))
                    completion?(.success(image))
                } catch {
                    guard !Task.isCancelled else { return }
                    self?.onStateChanged(.failure(error))
                    completion?(.failure(error))
                }
            }
        }
    }
}
