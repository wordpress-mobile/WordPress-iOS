import UIKit

extension BlogDetailsViewController {

    @objc func shouldShowSiteMonitoring() -> Bool {
        RemoteFeatureFlag.siteMonitoring.enabled() && blog.isAdmin && blog.isAtomic()
    }

    @objc func showSiteMonitoring() {
        showSiteMonitoring(selectedTab: nil)
    }

    @objc func showSiteMonitoring(selectedTab: NSNumber?) {
        let selectedTab = selectedTab.flatMap { SiteMonitoringTab(rawValue: $0.intValue) }
        let controller = SiteMonitoringViewController(selectedTab: selectedTab)
        presentationDelegate?.presentBlogDetailsViewController(controller)
    }
}
