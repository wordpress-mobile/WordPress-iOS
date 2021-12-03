/// Encapsulates a command to report a post
final class ReaderReportPostAction {
    func execute(with post: ReaderPost, context: NSManagedObjectContext, origin: UIViewController) {
        guard
            let permalink = post.permaLink,
            let url = reportURL(with: permalink)
        else {
            return
        }

        let configuration = WebViewControllerConfiguration(url: url)
        configuration.addsWPComReferrer = true
        let service = AccountService(managedObjectContext: context)

        if let account = service.defaultWordPressComAccount() {
            configuration.authenticate(account: account)
        }

        let controller = WebViewControllerFactory.controller(configuration: configuration, source: "reader_report")
        let navController = UINavigationController(rootViewController: controller)
        origin.present(navController, animated: true)

        // Track the report action
        let properties = ReaderHelpers.statsPropertiesForPost(post, andValue: nil, forKey: nil)
        WPAnalytics.trackReader(.readerPostReported, properties: properties)
    }

    /// Safely generate the report URL
    private func reportURL(with postURLString: String) -> URL? {
        guard var components = URLComponents(string: Constants.reportURLString) else {
            return nil
        }

        let queryItem = URLQueryItem(name: Constants.reportKey, value: postURLString)
        components.queryItems = [queryItem]
        return components.url
    }

    private struct Constants {
        static let reportURLString = "https://wordpress.com/abuse/"
        static let reportKey = "report_url"
    }
}
