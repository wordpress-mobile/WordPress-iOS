import Photos

extension PHAsset {
    /// Maximum duration, in seconds, for a video uploaded to a free site. Set to 5 minutes
    static let allowedVideoDurationForFreePlans: TimeInterval = 300

    /// Checks if a video that the user is trying to upload exceeds the allowed video limits
    /// - Parameter blogHasPaidPlan: true if the site has a paid plan
    /// - Returns: true if the video exceeds the limits, false otherwise
    func exceedsVideoLimits(_ blogHasPaidPlan: Bool) -> Bool {
        mediaType == .video && duration > Self.allowedVideoDurationForFreePlans  && !blogHasPaidPlan
    }
}
