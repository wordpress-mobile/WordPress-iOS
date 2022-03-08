import Foundation

extension BlogDetailsViewController {

    @objc func shouldShowDashboard() -> Bool {
        return FeatureFlag.mySiteDashboard.enabled && blog.isAccessibleThroughWPCom()
    }
}
