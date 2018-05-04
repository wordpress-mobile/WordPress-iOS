import Foundation

public protocol GIFPlaybackStrategy {
    /// Maximum size GIF data can be in order to be animated.
    ///
    var maxSize: Int { get }

    /// Maximum number of allowed frames contained in a GIF in order to be animated.
    ///
    var maxNumberOfFrames: Int { get }

    /// The number of frames that should be buffered. A high number will result in more
    /// memory usage and less CPU load, and vice versa.
    ///
    var frameBufferCount: Int { get }

    /// Verifies the GIF data against the `maxSize` var.
    ///
    /// - Parameter data: object containg the GIF
    /// - Returns: **true** if data is under the maximum size limit (inclusive) and **false** if over the limit
    ///
    func verifyDataSize(_ data: Data) -> Bool

    /// Verifies the number of frames against the `maxNumberOfFrames` var.
    ///
    /// - Parameter frames: Total number of frames in gif
    /// - Returns: **true** if frame count is under the maximum size limit (inclusive) and **false** if over the limit
    ///
    func verifyNumberOfFrames(_ frames: Int) -> Bool
}

extension GIFPlaybackStrategy {
    func verifyDataSize(_ data: Data) -> Bool {
        guard data.count <= maxSize else {
            DDLogWarn("⚠️ Maximum GIF data size exceeded \(maxSize) with \(data.count)")
            return false
        }
        return true
    }

    func verifyNumberOfFrames(_ frames: Int) -> Bool {
        guard frames <= maxNumberOfFrames else {
            DDLogWarn("⚠️ Maximum number of GIF frames exceeded \(maxNumberOfFrames) with \(frames)")
            return false
        }
        return true
    }
}

class SmallGIFPlaybackStrategy: GIFPlaybackStrategy {
    var maxSize = 8_000_000  // in MB
    var maxNumberOfFrames = 100
    var frameBufferCount = 40
}

class MediumGIFPlaybackStrategy: GIFPlaybackStrategy {
    var maxSize = 16_000_000  // in MB
    var maxNumberOfFrames = 200
    var frameBufferCount = 50
}

class LargeGIFPlaybackStrategy: GIFPlaybackStrategy {
    var maxSize = 32_000_000  // in MB
    var maxNumberOfFrames = 500
    var frameBufferCount = 60
}
