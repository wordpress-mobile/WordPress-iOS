/// Encapsulates a command to report a post
final class ReaderReportPostAction {
    func execute(with post: ReaderPost, target: Target = .post, context: NSManagedObjectContext, origin: UIViewController) {
        guard let url = Self.reportURL(with: post, target: target) else {
            return
        }

        let configuration = WebViewControllerConfiguration(url: url)
        configuration.addsWPComReferrer = true

        if let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context) {
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
    private static func reportURL(with post: ReaderPost, target: Target) -> URL? {
        guard let postURLString = post.permaLink,
              var components = URLComponents(string: Constants.reportURLString)
        else {
            return nil
        }

        var queryItems = [URLQueryItem(name: Constants.reportKey, value: postURLString)]

        if target == .author {
            guard let authorID = post.authorID?.stringValue else {
                DDLogWarn("Author ID is required to report a post's author")
                return nil
            }
            queryItems.append(.init(name: Constants.userKey, value: authorID))
        }

        components.queryItems = queryItems
        return components.url
    }

    // MARK: - Types

    enum Target {
        /// Report the post itself.
        case post

        /// Report the post's author.
        case author
    }

    private struct Constants {
        static let reportURLString = "https://wordpress.com/abuse/"
        static let reportKey = "report_url"
        static let userKey = "report_user_id"
    }
}
