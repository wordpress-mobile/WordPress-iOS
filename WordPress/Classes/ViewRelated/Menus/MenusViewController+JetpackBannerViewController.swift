import Foundation

@objc
extension MenusViewController {
    static func withJPBannerForBlog(_ blog: Blog) -> UIViewController {
        let menusVC = MenusViewController(blog: blog)
        menusVC.navigationItem.largeTitleDisplayMode = .never

        guard JetpackBrandingCoordinator.shouldShowBannerForJetpackDependentFeatures() else {
            return menusVC
        }
        return JetpackBannerWrapperViewController(childVC: menusVC, analyticsId: .menus)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let jetpackBannerWrapper = parent as? JetpackBannerWrapperViewController {
            jetpackBannerWrapper.processJetpackBannerVisibility(scrollView)
        }
    }
}
