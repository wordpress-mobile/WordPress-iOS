import Foundation
import AlamofireImage

final class ImageCache {
    /// A shared image cache used by the entire system.
    ///
    /// - warning: It's critical that there is only one cache instance to make
    /// sure it can manage the RAM usage efficiently.
    static let shared = ImageCache()

    private let cache = AutoPurgingImageCache(
        memoryCapacity: 128_000_000, // 128 MB
        preferredMemoryUsageAfterPurge: 64_000_000 // 64 MB
    )

    private init() {

    }
}
