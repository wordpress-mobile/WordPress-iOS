extension WPMediaAsset {
    ///  Returns true if the asset is a video and its duration is longer than the maximum allowed duration on free sites.
    func exceedsFreeSitesAllowance() -> Bool {
        // maximum allowed duration for video uploads on free sites, in seconds (5 mins)
        let maximumVideoDurationForFreeSites: CGFloat = 300
        return assetType() == .video && duration() > maximumVideoDurationForFreeSites
    }
}
