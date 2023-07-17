import Foundation
import AlamofireImage
import WordPressUI
import SDWebImage

final class MemoryCache {
    /// A shared image cache used by the entire system.
    static let shared = MemoryCache()

    private let cache = SDMemoryCache<NSString, AnyObject>()

    private init() {
        self.cache.totalCostLimit = 128_000_000 // 128 MB
    }

    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString, cost: image.sd_memoryCost)
    }

    func getImage(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString) as? UIImage
    }
}

extension MemoryCache {
    /// Registers the cache with all the image loading systems used by the app.
    func register() {
        WordPressUI.ImageCache.shared = WordpressUICacheAdapter(cache: .shared)
    }
}

private struct WordpressUICacheAdapter: WordPressUI.ImageCaching {
    let cache: MemoryCache

    func setImage(_ image: UIImage, forKey key: String) {
        cache.setImage(image, forKey: key)
    }

    func getImage(forKey key: String) -> UIImage? {
        cache.getImage(forKey: key)
    }
}
