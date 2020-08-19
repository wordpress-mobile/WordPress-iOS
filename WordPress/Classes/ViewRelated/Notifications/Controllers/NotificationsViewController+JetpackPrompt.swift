extension NotificationsViewController {

    fileprivate func configureControllerCompletion(_ controller: JetpackLoginViewController, withBlog blog: Blog) {
        controller.completionBlock = { [weak self, weak controller] in
            if AccountHelper.isDotcomAvailable() {
                self?.activityIndicator.stopAnimating()
                WPAppAnalytics.track(.signedInToJetpack, withProperties: ["source": "notifications"], with: blog)
                controller?.view.removeFromSuperview()
                controller?.removeFromParent()
                self?.tableView.reloadData()
            } else {
                self?.activityIndicator.stopAnimating()
                controller?.updateMessageAndButton()
            }
        }
    }


    // MARK: - Private Computed Properties

    fileprivate var blogService: BlogService {
        return BlogService(managedObjectContext: managedObjectContext())
    }

}
