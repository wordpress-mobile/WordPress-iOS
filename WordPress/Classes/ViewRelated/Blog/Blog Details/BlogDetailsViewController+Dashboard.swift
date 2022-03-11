import Foundation

extension BlogDetailsViewController {

    @objc func isDashboardEnabled() -> Bool {
        return FeatureFlag.mySiteDashboard.enabled && blog.isAccessibleThroughWPCom()
    }
}
