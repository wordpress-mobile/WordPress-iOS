import Foundation

extension JetpackScanViewController {
    @objc
    static func withJPBannerForBlog(_ blog: Blog) -> UIViewController {
        let jetpackScanVC = JetpackScanViewController(blog: blog)
        return JetpackBannerWrapperViewController(childVC: jetpackScanVC, analyticsId: .jetpackScan)
    }
}

extension JetpackScanViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let jetpackBannerWrapper = parent as? JetpackBannerWrapperViewController {
            jetpackBannerWrapper.processJetpackBannerVisibility(scrollView)
        }
    }
}
