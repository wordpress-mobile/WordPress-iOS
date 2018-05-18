final class ReaderHeaderAction {
    func execute(post: ReaderPost, origin: UIViewController) {
        let controller = ReaderStreamViewController.controllerWithSiteID(post.siteID, isFeed: post.isExternal)
        origin.navigationController?.pushViewController(controller, animated: true)

        let properties = ReaderHelpers.statsPropertiesForPost(post, andValue: post.blogURL as AnyObject?, forKey: "url")
        WPAppAnalytics.track(.readerSitePreviewed, withProperties: properties)
    }
}
