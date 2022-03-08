import Foundation

extension BlogDetailsViewController {

    @objc func dashboardIsEnabled() -> Bool {
        return FeatureFlag.mySiteDashboard.enabled && blog.isAccessibleThroughWPCom()
    }
}
