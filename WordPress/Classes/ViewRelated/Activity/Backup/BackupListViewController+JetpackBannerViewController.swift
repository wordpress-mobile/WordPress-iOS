import Foundation

extension BackupListViewController {
    @objc
    static func withJPBannerForBlog(_ blog: Blog) -> UIViewController? {
        guard let backupListVC = BackupListViewController(blog: blog) else {
            return nil
        }
        backupListVC.navigationItem.largeTitleDisplayMode = .never
        return JetpackBannerWrapperViewController(childVC: backupListVC, screen: .backup)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        if let jetpackBannerWrapper = parent as? JetpackBannerWrapperViewController {
            jetpackBannerWrapper.processJetpackBannerVisibility(scrollView)
        }
    }
}
