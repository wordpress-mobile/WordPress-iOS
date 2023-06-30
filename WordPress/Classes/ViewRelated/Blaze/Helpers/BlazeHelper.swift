import Foundation

@objcMembers final class BlazeHelper: NSObject {

    static func isBlazeFlagEnabled() -> Bool {
        guard AppConfiguration.isJetpack else {
            return false
        }
        return RemoteFeatureFlag.blaze.enabled()
    }

    static func shouldShowCard(for blog: Blog) -> Bool {
        guard isBlazeFlagEnabled() && blog.canBlaze else {
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
