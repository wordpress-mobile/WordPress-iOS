import UIKit
import WordPressData

final class ReaderHeaderAction {
    func execute(post: ReaderPost, origin: UIViewController, source: ReaderStreamViewController.StatSource? = nil) {
        guard let siteID = post.siteID else { return }

        let controller = ReaderStreamViewController.controllerWithSiteID(siteID, isFeed: post.isExternal)
        if let source {
            controller.statSource = source
        }
        origin.navigationController?.pushViewController(controller, animated: true)

        let properties = ReaderHelpers.statsPropertiesForPost(post, andValue: post.blogURL as AnyObject?, forKey: "url")
        WPAppAnalytics.track(.readerSitePreviewed, withProperties: properties)
    }
}
