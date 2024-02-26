import Foundation
import AlamofireImage
import WordPressUI

protocol MemoryCacheProtocol: AnyObject {
    subscript(key: String) -> UIImage? { get set }
}

final class MemoryCache: MemoryCacheProtocol {
    /// A shared image cache used by the entire system.
    static let shared = MemoryCache()

    private let cache = NSCache<NSString, AnyObject>()

    private init() {
        self.cache.totalCostLimit = 256_000_000 // 256 MB

        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

    @objc private func didReceiveMemoryWarning() {
        cache.removeAllObjects()
    }

    // MARK: - UIImage

    subscript(key: String) -> UIImage? {
        get {
            getImage(forKey: key)
        }
        set {
            if let newValue {
                setImage(newValue, forKey: key)
            } else {
                removeImage(forKey: key)
            }
        }
    }

    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString, cost: image.cost)
    }

    func getImage(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString) as? UIImage
    }

    func removeImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    // MARK: - Data

    func setData(_ data: Data, forKey key: String) {
        cache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
    }

    func geData(forKey key: String) -> Data? {
        cache.object(forKey: key as NSString) as? Data
    }

    func removeData(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
}

private extension UIImage {
    /// Returns a rought estimation of how much space the image takes in memory.
    var cost: Int {
        let dataCost = (self as? AnimatedImage)?.gifData?.count ?? 0
        let imageCost = cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        return dataCost + imageCost
    }
}

extension MemoryCache {
    /// Registers the cache with all the image loading systems used by the app.
    func register() {
        // WordPressUI
        WordPressUI.ImageCache.shared = WordpressUICacheAdapter(cache: .shared)

        // AlamofireImage
        UIImageView.af.sharedImageDownloader = AlamofireImage.ImageDownloader(
            imageCache: AlamofireImageCacheAdapter(cache: .shared)
        )

        // WordPress.AnimatedImageCache uses WordPress.MemoryCache directly
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

private struct AlamofireImageCacheAdapter: AlamofireImage.ImageRequestCache {
    let cache: MemoryCache

    func image(for request: URLRequest, withIdentifier identifier: String?) -> AlamofireImage.Image? {
        image(withIdentifier: cacheKey(for: request, identifier: identifier))
    }

    func add(_ image: AlamofireImage.Image, for request: URLRequest, withIdentifier identifier: String?) {
        add(image, withIdentifier: cacheKey(for: request, identifier: identifier))
    }

    func removeImage(for request: URLRequest, withIdentifier identifier: String?) -> Bool {
        removeImage(withIdentifier: cacheKey(for: request, identifier: identifier))
    }

    func image(withIdentifier identifier: String) -> AlamofireImage.Image? {
        cache.getImage(forKey: identifier)
    }

    func add(_ image: AlamofireImage.Image, withIdentifier identifier: String) {
        cache.setImage(image, forKey: identifier)
    }

    func removeImage(withIdentifier identifier: String) -> Bool {
        cache.removeImage(forKey: identifier)
        return true
    }

    func removeAllImages() -> Bool {
        // Do nothing (the app decides when to remove images)
        return true
    }

    private func cacheKey(for request: URLRequest, identifier: String?) -> String {
        var key = request.url?.absoluteString ?? ""
        if let identifier = identifier {
            key += "-\(identifier)"
        }
        return key
    }
}
