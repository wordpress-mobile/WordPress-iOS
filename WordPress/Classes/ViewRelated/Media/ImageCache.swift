import Foundation
import AlamofireImage
import WordPressUI

final class ImageCache {
    /// A shared image cache used by the entire system.
    static let shared = ImageCache()

    fileprivate let cache = AutoPurgingImageCache(
        memoryCapacity: 128_000_000, // 128 MB
        preferredMemoryUsageAfterPurge: 64_000_000 // 64 MB
    )

    private init() {

    }
}

extension ImageCache {
    /// Registers the cache with all the image loading systems used by the app.
    func register() {
        WordPressUI.ImageCache.shared = WordpressUICacheAdapter(cache: .shared)
    }
}

private struct WordpressUICacheAdapter: WordPressUI.ImageCaching {
    let cache: ImageCache

    func setImage(_ image: UIImage, forKey key: String) {
        cache.cache.add(image, withIdentifier: key)
    }

    func getImage(forKey key: String) -> UIImage? {
        cache.cache.image(withIdentifier: key)
    }
}
