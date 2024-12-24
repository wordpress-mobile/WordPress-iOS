import UIKit
import WordPressMedia
import WordPressUI

extension MemoryCache {
    /// Registers the cache with all the image loading systems used by the app.
    func register() {
        // WordPressUI
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
