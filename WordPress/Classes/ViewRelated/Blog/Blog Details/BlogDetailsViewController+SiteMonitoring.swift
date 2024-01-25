import UIKit

extension BlogDetailsViewController {

    @objc func shouldShowSiteMonitoring() -> Bool {
        RemoteFeatureFlag.siteMonitoring.enabled() && blog.isAdmin && blog.isAtomic()
    }

    @objc func showSiteMonitoring() {
        let controller = SiteMonitoringViewController()
        presentationDelegate?.presentBlogDetailsViewController(controller)
    }
}
