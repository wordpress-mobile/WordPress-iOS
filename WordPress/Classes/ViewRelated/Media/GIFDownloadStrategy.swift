import Foundation

public protocol GIFDownloadStrategy {
    /// Maximum size GIF data can be in order to be animated.
    ///
    var maxSize: Int { get }

    /// Verifies the GIF data against the `maxSize` var.
    ///
    /// - Parameter data: object containg the GIF
    /// - Returns: **true** if data is under the maximum size limit (inclusive) and **false** if over the limit
    ///
    func verifyDataSize(_ data: Data) -> Bool
}

extension GIFDownloadStrategy {
    func verifyDataSize(_ data: Data) -> Bool {
        guard data.count <= maxSize else {
            return false
        }
        return true
    }
}

class SmallGIFDownloadStrategy: GIFDownloadStrategy {
    var maxSize = 5_000_000  // in MB
}

class MediumGIFDownloadStrategy: GIFDownloadStrategy {
    var maxSize = 10_000_000  // in MB
}

class LargeGIFDownloadStrategy: GIFDownloadStrategy {
    var maxSize = 20_000_000  // in MB
}
