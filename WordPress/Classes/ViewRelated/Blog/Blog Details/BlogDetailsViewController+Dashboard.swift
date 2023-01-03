import Foundation

extension BlogDetailsViewController {

    @objc func isDashboardEnabled() -> Bool {
        return JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled() && blog.isAccessibleThroughWPCom()
    }
}
