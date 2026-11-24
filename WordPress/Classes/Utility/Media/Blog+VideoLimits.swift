import CoreMedia
import AVFoundation
import WordPressData

extension Blog {
    /// Maximum allowed duration for video uploads on free sites, in seconds (5 mins).
    static let maximumVideoDurationForFreeSites: TimeInterval = 300

    /// Returns the video duration limit for the blog. If there is no limit, returns `nil`.
    var videoDurationLimit: TimeInterval? {
        if hasPaidPlan || !isHostedAtWPcom {
            return nil
        }
        return Blog.maximumVideoDurationForFreeSites
    }

    /// Returns `true` if the blog is allowed to upload the video at the given URL.
    ///
    /// Runs on the caller's actor, so the blog is read on the caller's thread,
    /// as with any other access to its properties.
    nonisolated(nonsending) func canUploadVideo(from videoURL: URL) async -> Bool {
        guard let limit = videoDurationLimit else {
            return true
        }
        let asset = AVURLAsset(url: videoURL)
        guard let duration = try? await asset.load(.duration) else {
            return true
        }
        return CMTimeGetSeconds(duration) <= limit
    }
}
