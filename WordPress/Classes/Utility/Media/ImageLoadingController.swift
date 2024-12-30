import Foundation
import UIKit
import WordPressMedia

/// A convenience class for managing image downloads for individual views.
@MainActor
final class ImageLoadingController {
    var downloader: ImageDownloader = .shared
    var service: MediaImageService = .shared
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
    func setImage(with request: ImageRequest, completion: (@MainActor (Result<UIImage, Error>) -> Void)? = nil) {
        task?.cancel()

        if let image = downloader.cachedImage(for: request) {
            onStateChanged(.success(image))
            completion?(.success(image))
        } else {
            onStateChanged(.loading)
            task = Task { @MainActor [downloader, weak self] in
                do {
                    let image = try await downloader.image(for: request)
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

    func setImage(with media: Media, size: MediaImageService.ImageSize) {
        task?.cancel()

        if let image = service.getCachedThumbnail(for: .init(media), size: size) {
            onStateChanged(.success(image))
        } else {
            onStateChanged(.loading)
            task = Task { @MainActor [service, weak self] in
                do {
                    let image = try await service.image(for: media, size: size)
                    // This line guarantees that if you cancel on the main thread,
                    // none of the `onStateChanged` callbacks get called.
                    guard !Task.isCancelled else { return }
                    self?.onStateChanged(.success(image))
                } catch {
                    guard !Task.isCancelled else { return }
                    self?.onStateChanged(.failure(error))
                }
            }
        }
    }
}
