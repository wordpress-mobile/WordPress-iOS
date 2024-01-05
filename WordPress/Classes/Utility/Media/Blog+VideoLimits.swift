import CoreMedia
import AVFoundation

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
    func canUploadVideo(from videoURL: URL) -> Bool {
        guard let limit = videoDurationLimit else {
            return true
        }
        let asset = AVAsset(url: videoURL)
        let duration = CMTimeGetSeconds(asset.duration)
        return duration <= limit
    }
}
