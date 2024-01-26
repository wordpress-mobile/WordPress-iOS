import UIKit

extension BlogDetailsViewController {

    @objc func showSiteMonitoring() {
        let controller = SiteMonitoringViewController()
        presentationDelegate?.presentBlogDetailsViewController(controller)
    }
}
