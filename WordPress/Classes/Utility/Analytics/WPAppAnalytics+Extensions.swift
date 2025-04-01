import Foundation
import WordPressShared

extension WPAppAnalytics {

    @objc public class func track(_ stat: WPAnalyticsStat) {
        WPAnalytics.track(stat)
    }

    @objc public class func track(_ stat: WPAnalyticsStat, withProperties properties: [AnyHashable: Any]?) {
        WPAnalytics.track(stat, withProperties: properties)
    }

    // MARK: WPAppAnalytics (Blog)

    @objc(track:withBlog:)
    public class func track(_ stat: WPAnalyticsStat, blog: Blog?) {
        track(stat, properties: nil, blog: blog)
    }

    @objc(track:withProperties:withBlog:)
    public class func track(_ stat: WPAnalyticsStat, properties: [String: Any]?, blog: Blog?) {
        var properties = properties ?? [:]
        if let blog {
            if let blogID = blog.dotComID {
                properties[WPAppAnalyticsKeyBlogID] = blogID
            }
            properties[WPAppAnalyticsKeySiteType] = siteType(for: blog)
        }
        WPAppAnalytics.track(stat, withProperties: properties)
    }

    @objc(track:withBlogID:)
    public class func track(_ stat: WPAnalyticsStat, blogID: NSNumber?) {
        track(stat, properties: nil, blogID: blogID)
    }

    @objc(track:withProperties:withBlogID:)
    public class func track(_ stat: WPAnalyticsStat, properties: [String: Any]?, blogID: NSNumber?) {
        if Thread.isMainThread {
            _track(stat, properties: properties, blogID: blogID)
        } else {
            DispatchQueue.main.async {
                _track(stat, properties: properties, blogID: blogID)
            }
        }
    }

    private static func _track(_ stat: WPAnalyticsStat, properties: [String: Any]? = nil, blogID: NSNumber?) {
        wpAssert(Thread.isMainThread)

        var properties = properties ?? [:]
        if let blogID {
            properties[WPAppAnalyticsKeyBlogID] = blogID

            let context = ContextManager.shared.mainContext
            if let blog = Blog.lookup(withID: blogID, in: context) {
                properties[WPAppAnalyticsKeySiteType] = siteType(for: blog)
            }
        }

        WPAppAnalytics.track(stat, withProperties: properties)
    }

    private static func siteType(for blog: Blog) -> String {
        blog.isWPForTeams() ? WPAppAnalyticsValueSiteTypeP2 : WPAppAnalyticsValueSiteTypeBlog
    }

    // MARK: WPAppAnalytics (AbstractPost)

    static func track(_ stat: WPAnalyticsStat, properties: [String: Any]? = nil, post: AbstractPost) {
        var properties = properties ?? [:]

        if let postID = post.postID, postID.intValue > 0 {
            properties[WPAppAnalyticsKeyPostID] = postID
        }
        properties[Constants.hasGutenbergBlocksKey] = post.containsGutenbergBlocks()

        WPAppAnalytics.track(stat, properties: properties, blog: post.blog)
    }

    // MARK: WPAppAnalytics (Errors)

    static func track(_ stat: WPAnalyticsStat, error: Error) {
        track(stat, error: error, blogID: nil)
    }

    @objc(track:error:withBlogID:)
    public class func track(_ stat: WPAnalyticsStat, error: Error, blogID: NSNumber?) {
        let error = self.sanitizedError(fromError: error) as NSError
        track(stat, withProperties: [
            "error_code": String(error.code),
            "error_domain": error.domain,
            "error_description": error.description,
            WPAppAnalyticsKeyBlogID: blogID ?? 0
        ])
    }
}

private enum Constants {
    static let hasGutenbergBlocksKey = "has_gutenberg_blocks"
}
