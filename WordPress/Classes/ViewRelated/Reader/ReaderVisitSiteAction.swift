/// Encapsulates a command to visit a site
final class ReaderVisitSiteAction {
    func execute(with post: ReaderPost, context: NSManagedObjectContext, origin: UIViewController) {
        guard
            let permalink = post.permaLink,
            let siteURL = URL(string: permalink) else {
                return
        }

        let configuration = WebViewControllerConfiguration(url: siteURL)
        configuration.addsWPComReferrer = true
        let service = AccountService(managedObjectContext: context)
        if let account = service.defaultWordPressComAccount() {
            configuration.authenticate(account: account)
        }
        let controller = WebViewControllerFactory.controller(configuration: configuration)
        let navController = UINavigationController(rootViewController: controller)
        origin.present(navController, animated: true, completion: nil)
    }
}
