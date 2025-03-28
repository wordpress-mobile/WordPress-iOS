import UIKit

final class ReaderHeaderAction {
    func execute(post: ReaderPost, origin: UIViewController, source: ReaderStreamViewController.StatSource? = nil) {
        let controller = ReaderStreamViewController.controllerWithSiteID(post.siteID, isFeed: post.isExternal)
        if let source {
            controller.statSource = source
        }
        origin.navigationController?.pushViewController(controller, animated: true)

        let properties = ReaderHelpers.statsPropertiesForPost(post, andValue: post.blogURL as AnyObject?, forKey: "url")
        WPAppAnalytics.track(.readerSitePreviewed, withProperties: properties)
    }
}
