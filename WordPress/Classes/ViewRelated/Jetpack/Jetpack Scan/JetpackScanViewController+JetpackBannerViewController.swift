import Foundation

extension JetpackScanViewController {
    @objc
    static func withJPBannerForBlog(_ blog: Blog) -> UIViewController {
        let jetpackScanVC = JetpackScanViewController(blog: blog)
        jetpackScanVC.navigationItem.largeTitleDisplayMode = .never
        return JetpackBannerWrapperViewController(childVC: jetpackScanVC, screen: .scan)
    }
}

extension JetpackScanViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let jetpackBannerWrapper = parent as? JetpackBannerWrapperViewController {
            jetpackBannerWrapper.processJetpackBannerVisibility(scrollView)
        }
    }
}
