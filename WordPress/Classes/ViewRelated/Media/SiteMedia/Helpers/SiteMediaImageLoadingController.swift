import UIKit
import AsyncImageKit
import WordPressData

/// A convenience class for managing image downloads for individual views.
@MainActor
final class SiteMediaImageLoadingController {
    var service: MediaImageService = .shared
    var onStateChanged: (State) -> Void = { _ in }

    private(set) var task: Task<Void, Never>?

    typealias State = ImageLoadingController.State

    deinit {
        task?.cancel()
    }

    func prepareForReuse() {
        task?.cancel()
        task = nil
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
