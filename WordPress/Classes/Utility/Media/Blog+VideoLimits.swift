extension Blog {

    /// returns true if the blog is allowed to upload the given asset, true otherwise
    func canUploadAsset(_ asset: WPMediaAsset) -> Bool {
        hasPaidPlan || !asset.exceedsFreeSitesAllowance()
    }
}
