import Foundation

/// Blog extension for methods related to Jetpack Social.
extension Blog {
    // MARK: - Publicize

    /// Whether the blog has Social auto-sharing limited.
    /// Note that sites hosted at WP.com has no Social sharing limitations.
    var isSocialSharingLimited: Bool {
        let hasUnlimitedSharing = (planActiveFeatures ?? []).contains(Constants.unlimitedSharingFeatureKey)
        return !(isHostedAtWPcom || isAtomic() || hasUnlimitedSharing)
    }

    /// The auto-sharing limit information for the blog.
    var sharingLimit: PublicizeInfo.SharingLimit? {
        // For blogs with unlimited shares, return nil early.
        // This is because the endpoint will still return sharing limits as if the blog doesn't have unlimited sharing.
        guard isSocialSharingLimited else {
            return nil
        }
        return publicizeInfo?.sharingLimit
    }

    // MARK: - Private constants

    private enum Constants {
        /// The feature key listed in the blog's plan's features. At the moment, `social-shares-1000` means unlimited
        /// sharing, but in the future we might introduce a proper differentiation between 1000 and unlimited.
        static let unlimitedSharingFeatureKey = "social-shares-1000"
    }
}
