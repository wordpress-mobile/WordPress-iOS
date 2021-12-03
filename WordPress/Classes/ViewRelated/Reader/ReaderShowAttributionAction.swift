/// Encapsulates a command show a post's attribution
final class ReaderShowAttributionAction {
    func execute(with post: ReaderPost, context: NSManagedObjectContext, origin: UIViewController) {
        // Fail safe. If there is no attribution exit.
        guard let sourceAttribution = post.sourceAttribution else {
            return
        }

        // If there is a blogID preview the site
        if let blogID = sourceAttribution.blogID {
            let controller = ReaderStreamViewController.controllerWithSiteID(blogID, isFeed: false)
            origin.navigationController?.pushViewController(controller, animated: true)
            return
        }

        if sourceAttribution.attributionType != SourcePostAttributionTypeSite {
            return
        }

        guard let linkURL = URL(string: sourceAttribution.blogURL) else {
            return
        }
        let configuration = WebViewControllerConfiguration(url: linkURL)
        configuration.addsWPComReferrer = true
        let controller = WebViewControllerFactory.controller(configuration: configuration, source: "reader_attribution")
        let navController = UINavigationController(rootViewController: controller)
        origin.present(navController, animated: true)
    }
}
