import UIKit

final class MediaCollectionCellViewModel {
    var onLoadingFinished: ((UIImage?) -> Void)?

    private let media: Media
    private let coordinator: MediaThumbnailCoordinator
    private let cache: MemoryCache
    private var requestCount = 0

    init(media: Media,
         coordinator: MediaThumbnailCoordinator = .shared,
         cache: MemoryCache = .shared) {
        self.media = media
        self.coordinator = coordinator
        self.cache = cache
    }

    // MARK: - Thumbnail

    /// Returns the image from the memory cache.
    func getCachedImage() -> UIImage? {
        cache.getImage(forKey: makeCacheKey(for: media))
    }

    /// Starts loading the image for the given media assets.
    func loadThumbnail(targetSize: CGSize) {
        assert(targetSize != .zero, "Invalid target size")

        requestCount += 1
        guard requestCount == 1 else {
            return // Already loading
        }
        // TODO: keep track of current request and its cancellation
        coordinator.thumbnail(for: media, with: targetSize) { [weak self] in
            self?.didFinishLoading(with: $0, error: $1)
        }
    }

    private func didFinishLoading(with image: UIImage?, error: Error?) {
        if let image {
            cache.setImage(image, forKey: makeCacheKey(for: media))
        }
        onLoadingFinished?(image)
    }

    func cancelLoading() {
        requestCount -= 1
        requestCount = max(0, requestCount) // Just in case
        if requestCount == 0 {
            // TODO: actually cancel
        }
    }

    private func makeCacheKey(for media: Media) -> String {
        "thumbnail-\(media.objectID)"
    }
}
