import UIKit

@MainActor
final class MediaCollectionCellViewModel {
    var onLoadingFinished: ((UIImage?) -> Void)?
    let mediaID: TaggedManagedObjectID<Media>
    var mediaType: MediaType

    private let media: Media
    private let service: MediaImageService
    private let cache: MemoryCache
    private var requestCount = 0
    private var imageTask: Task<Void, Never>?

    deinit {
        imageTask?.cancel()
    }

    init(media: Media,
         service: MediaImageService = .shared,
         cache: MemoryCache = .shared) {
        self.mediaID = TaggedManagedObjectID(media)
        self.media = media
        self.mediaType = media.mediaType
        self.service = service
        self.cache = cache
    }

    // MARK: - Thumbnail

    /// Returns the image from the memory cache.
    func getCachedImage() -> UIImage? {
        cache.getImage(forKey: makeCacheKey(for: media))
    }

    /// Starts loading the image for the given media assets.
    func loadThumbnail() {
        requestCount += 1
        guard requestCount == 1 else {
            return // Already loading
        }
        let task = Task { [service, media, weak self] in
            do {
                let image = try await service.thumbnail(for: media)
                self?.didFinishLoading(with: image, error: nil)
            } catch {
                self?.didFinishLoading(with: nil, error: error)
            }
        }
        imageTask = task
    }

    private func didFinishLoading(with image: UIImage?, error: Error?) {
        if let image {
            cache.setImage(image, forKey: makeCacheKey(for: media))
        }
        onLoadingFinished?(image)
        requestCount = 0
    }

    func cancelLoading() {
        guard requestCount > 0 else { return }
        requestCount -= 1
        if requestCount == 0 {
            imageTask?.cancel()
        }
    }

    private func makeCacheKey(for media: Media) -> String {
        "thumbnail-\(media.objectID)"
    }
}
