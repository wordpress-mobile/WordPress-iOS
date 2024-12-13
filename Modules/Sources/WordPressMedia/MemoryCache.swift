import UIKit

public protocol MemoryCacheProtocol: AnyObject, Sendable {
    subscript(key: String) -> UIImage? { get set }

    func removeAllObjects()
}

/// - note: The type is thread-safe because it uses thread-safe `NSCache`.
public final class MemoryCache: MemoryCacheProtocol, @unchecked Sendable {

    /// A shared image cache used by the entire system.
    public static let shared = MemoryCache()

    private let cache = NSCache<NSString, AnyObject>()

    private init() {
        self.cache.totalCostLimit = 256_000_000 // 256 MB

        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

    @objc private func didReceiveMemoryWarning() {
        cache.removeAllObjects()
    }

    public func removeAllObjects() {
        cache.removeAllObjects()
    }

    // MARK: - UIImage

    public subscript(key: String) -> UIImage? {
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

    public func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString, cost: image.cost)
    }

    public func getImage(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString) as? UIImage
    }

    public func removeImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    // MARK: - Data

    public func setData(_ data: Data, forKey key: String) {
        cache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
    }

    public func geData(forKey key: String) -> Data? {
        cache.object(forKey: key as NSString) as? Data
    }

    public func removeData(forKey key: String) {
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
