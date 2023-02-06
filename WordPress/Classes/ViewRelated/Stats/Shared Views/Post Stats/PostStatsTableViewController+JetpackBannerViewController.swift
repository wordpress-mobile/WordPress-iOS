import Foundation

extension PostStatsTableViewController {

    static func withJPBannerForBlog(postID: Int, postTitle: String?, postURL: URL?) -> UIViewController {
        let statsVC = PostStatsTableViewController.loadFromStoryboard()
        statsVC.configure(postID: postID, postTitle: postTitle, postURL: postURL)
        return JetpackBannerWrapperViewController(childVC: statsVC, screen: .stats)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let jetpackBannerWrapper = parent as? JetpackBannerWrapperViewController {
            jetpackBannerWrapper.processJetpackBannerVisibility(scrollView)
        }
    }
}
