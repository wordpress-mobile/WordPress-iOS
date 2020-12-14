/// Encapsulates a command to flag a site
final class ReaderBlockSiteAction {
    private let asBlocked: Bool

    init(asBlocked: Bool) {
        self.asBlocked = asBlocked
    }

    func execute(with post: ReaderPost, context: NSManagedObjectContext, completion: (() -> Void)? = nil) {
        let service = ReaderSiteService(managedObjectContext: context)
        service.flagSite(withID: post.siteID,
                         asBlocked: asBlocked,
                         success: nil,
                         failure: { (error: Error?) in
                            completion?()

                            let message = error?.localizedDescription ?? ""
                            let errorTitle = NSLocalizedString("Error Blocking Site", comment: "Title of a prompt letting the user know there was an error trying to block a site from appearing in the reader.")
                            let cancelTitle = NSLocalizedString("OK", comment: "Text for an alert's dismissal button.")
                            let alertController = UIAlertController(title: errorTitle,
                                                                    message: message,
                                                                    preferredStyle: .alert)
                            alertController.addCancelActionWithTitle(cancelTitle, handler: nil)
                            alertController.presentFromRootViewController()
                            WPAnalytics.trackReader(.readerBlogBlocked, properties: ["blogId": post.siteID as Any])
        })

    }
}
