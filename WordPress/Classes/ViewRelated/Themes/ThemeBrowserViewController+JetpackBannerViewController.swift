import Foundation

extension ThemeBrowserViewController {
    @objc
    func withJPBanner() -> UIViewController {
        navigationItem.largeTitleDisplayMode = .never
        guard JetpackBrandingCoordinator.shouldShowBannerForJetpackDependentFeatures() else {
            return self
        }
        return JetpackBannerWrapperViewController(childVC: self, analyticsId: .themes)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let jetpackBannerWrapper = parent as? JetpackBannerWrapperViewController {
            jetpackBannerWrapper.processJetpackBannerVisibility(scrollView)
        }
    }
}
