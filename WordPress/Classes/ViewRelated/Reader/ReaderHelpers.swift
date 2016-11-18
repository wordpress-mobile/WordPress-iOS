import Foundation
import WordPressComAnalytics

/// A collection of helper methods used by the Reader.
///
@objc public class ReaderHelpers : NSObject {

    public class func statsPropertiesForPost(post:ReaderPost, andValue value:AnyObject?, forKey key:String?) -> [NSObject: AnyObject] {
        var properties = [NSObject: AnyObject]()
        properties[WPAppAnalyticsKeyBlogID] = post.siteID
        properties[WPAppAnalyticsKeyPostID] = post.postID
        properties[WPAppAnalyticsKeyIsJetpack] = post.isJetpack
        if let feedID = post.feedID, feedItemID = post.feedItemID {
            properties[WPAppAnalyticsKeyFeedID] = feedID
            properties[WPAppAnalyticsKeyFeedItemID] = feedItemID
        }

        if let value = value, key = key {
            properties[key] = value
        }

        return properties
    }


    public class func bumpPageViewForPost(post: ReaderPost) {
        // Don't bump page views for feeds else the wrong blog/post get's bumped
        if post.isExternal && !post.isJetpack {
            return
        }

        // If the user is an admin on the post's site do not bump the page view unless
        // the the post is private.
        if !post.isPrivate() && isUserAdminOnSiteWithID(post.siteID) {
            return
        }

        guard let host = NSURL(string: post.blogURL)?.host else {
            return
        }

        let pixelStatReferrer = "https://wordpress.com/"
        let pixel = "https://pixel.wp.com/g.gif"
        let params:NSArray = [
            "v=wpcom",
            "reader=1",
            "ref=\(pixelStatReferrer)",
            "host=\(host)",
            "blog=\(post.siteID)",
            "post=\(post.postID)",
            NSString(format:"t=%d", arc4random())
        ]

        let userAgent = WPUserAgent.wordPressUserAgent()
        let path  = NSString(format: "%@?%@", pixel, params.componentsJoinedByString("&")) as String
        let url = NSURL(string: path)

        let request = NSMutableURLRequest(URL: url!)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.addValue(pixelStatReferrer, forHTTPHeaderField: "Referer")

        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request)
        task.resume()
    }

    public class func isUserAdminOnSiteWithID(siteID:NSNumber) -> Bool {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        if let blog = blogService.blogByBlogId(siteID) {
            return blog.isAdmin
        }
        return false
    }


    // MARK: Logged in helper

    public class func isLoggedIn() -> Bool {
        return AccountHelper.isDotcomAvailable()
    }
}
