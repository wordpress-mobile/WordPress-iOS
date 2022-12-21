import Foundation

@objc
extension PeopleViewController {
    static func withJPBannerForBlog(_ blog: Blog) -> UIViewController? {
        guard let peopleViewVC = PeopleViewController.controllerWithBlog(blog) else {
            return nil
        }
        return JetpackBannerWrapperViewController(childVC: peopleViewVC, analyticsId: .people)
    }
}

extension PeopleViewController: JPScrollViewDelegate {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        processJetpackBannerVisibility(scrollView)
    }
}
