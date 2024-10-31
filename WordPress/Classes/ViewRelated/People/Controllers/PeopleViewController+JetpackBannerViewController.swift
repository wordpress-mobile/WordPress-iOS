import Foundation

@objc
extension PeopleViewController {
    static func withJPBannerForBlog(_ blog: Blog) -> UIViewController? {
        guard let peopleViewVC = PeopleViewController.controllerWithBlog(blog) else {
            return nil
        }
        peopleViewVC.navigationItem.largeTitleDisplayMode = .never
        guard JetpackBrandingCoordinator.shouldShowBannerForJetpackDependentFeatures() else {
            return peopleViewVC
        }
        return JetpackBannerWrapperViewController(childVC: peopleViewVC, screen: .people)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let jetpackBannerWrapper = parent as? JetpackBannerWrapperViewController {
            jetpackBannerWrapper.processJetpackBannerVisibility(scrollView)
        }
    }
}
