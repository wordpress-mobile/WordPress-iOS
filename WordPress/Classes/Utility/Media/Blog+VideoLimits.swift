import CoreMedia
import AVFoundation

extension Blog {
    /// Maximum allowed duration for video uploads on free sites, in seconds (5 mins).
    static let maximumVideoDurationForFreeSites: TimeInterval = 300

    /// Returns `true` if the blog is allowed to upload the given asset.
    func canUploadAsset(_ asset: WPMediaAsset) -> Bool {
        return canUploadAsset(asset.exceedsFreeSitesAllowance())
    }

    /// Returns `true` if the blog is allowed to upload the video at the given URL.
    func canUploadVideo(from videoURL: URL) -> Bool {
        let asset = AVAsset(url: videoURL)
        let duration = CMTimeGetSeconds(asset.duration)
        let exceedsAllowance = duration > Blog.maximumVideoDurationForFreeSites
        return canUploadAsset(exceedsAllowance)
    }

    public func canUploadAsset(_ assetExceedsFreeSitesAllowance: Bool) -> Bool {
        return hasPaidPlan || !isHostedAtWPcom || !assetExceedsFreeSitesAllowance
    }
}

private extension WPMediaAsset {
    ///  Returns true if the asset is a video and its duration is longer than the maximum allowed duration on free sites.
    func exceedsFreeSitesAllowance() -> Bool {
        assetType() == .video && duration() > Blog.maximumVideoDurationForFreeSites
    }
}
