extension Blog {

    /// returns true if the blog is allowed to upload the given asset, true otherwise
    func canUploadAsset(_ asset: WPMediaAsset) -> Bool {
        return canUploadAsset(asset.exceedsFreeSitesAllowance())
    }

    public func canUploadAsset(_ assetExceedsFreeSitesAllowance: Bool) -> Bool {
        return hasPaidPlan || !isHostedAtWPcom || !assetExceedsFreeSitesAllowance
    }
}
