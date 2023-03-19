import Foundation

@objcMembers final class BlazeHelper: NSObject {

    /// Using two separate methods (rather than one method with a default argument) for Obj-C compatibility.
    static func isBlazeFlagEnabled() -> Bool {
        return isBlazeFlagEnabled(featureFlagStore: RemoteFeatureFlagStore())
    }

    static func isBlazeFlagEnabled(featureFlagStore: RemoteFeatureFlagStore) -> Bool {
        guard AppConfiguration.isJetpack else {
            return false
        }
        return featureFlagStore.value(for: FeatureFlag.blaze)
    }

    static func shouldShowCard(for blog: Blog) -> Bool {
        guard isBlazeFlagEnabled() && blog.isBlazeApproved else {
            return false
        }
        return true
    }

    static func hideBlazeCard(for blog: Blog?) {
        guard let blog,
              let siteID = blog.dotComID?.intValue else {
            DDLogError("Blaze: error hiding blaze card.")
            return
        }
        BlogDashboardPersonalizationService(siteID: siteID)
            .setEnabled(false, for: .blaze)
    }
}
