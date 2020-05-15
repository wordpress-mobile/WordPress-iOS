import Foundation
import WordPressShared

/// A collection of helper methods used by the Reader.
///
@objc open class ReaderHelpers: NSObject {


    // MARK: - Topic Helpers

    public static let discoverSiteID = NSNumber(value: 53424024)

    /// Check if the specified topic is a default topic
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is a default topic
    ///
    @objc open class func isTopicDefault(_ topic: ReaderAbstractTopic) -> Bool {
        return topic.isKind(of: ReaderDefaultTopic.self)
    }


    /// Check if the specified topic is a list
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is a list topic
    ///
    @objc open class func isTopicList(_ topic: ReaderAbstractTopic) -> Bool {
        return topic.isKind(of: ReaderListTopic.self)
    }


    /// Check if the specified topic is a site topic
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is a site topic
    ///
    @objc open class func isTopicSite(_ topic: ReaderAbstractTopic) -> Bool {
        return topic.isKind(of: ReaderSiteTopic.self)
    }


    /// Check if the specified topic is a tag topic
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is a tag topic
    ///
    @objc open class func isTopicTag(_ topic: ReaderAbstractTopic) -> Bool {
        return topic.isKind(of: ReaderTagTopic.self)
    }


    /// Check if the specified topic is a search topic
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is a search topic
    ///
    @objc open class func isTopicSearchTopic(_ topic: ReaderAbstractTopic) -> Bool {
        return topic.isKind(of: ReaderSearchTopic.self)
    }


    /// Check if the specified topic is for Freshly Pressed
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is for Freshly Pressed
    ///
    @objc open class func topicIsFreshlyPressed(_ topic: ReaderAbstractTopic) -> Bool {
        return topic.path.hasSuffix("/freshly-pressed")
    }


    /// Check if the specified topic is for Discover
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is for Discover
    ///
    @objc open class func topicIsDiscover(_ topic: ReaderAbstractTopic) -> Bool {
        return topic.path.contains("/read/sites/53424024/posts")
    }


    /// Check if the specified topic is for Following
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is for Following
    ///
    @objc open class func topicIsFollowing(_ topic: ReaderAbstractTopic) -> Bool {
        return topic.path.hasSuffix("/read/following")
    }


    /// Check if the specified topic is for Posts I Like
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is for Posts I Like
    ///
    @objc open class func topicIsLiked(_ topic: ReaderAbstractTopic) -> Bool {
        return topic.path.hasSuffix("/read/liked")
    }

    /// Check if the specified topic is for Posts Saved for Later
    ///
    /// - Parameters:
    ///     - topic: A ReaderAbstractTopic
    ///
    /// - Returns: True if the topic is for Discover
    ///
    @objc open class func topicIsSavedForLater(_ topic: ReaderAbstractTopic) -> Bool {
        //TODO. Update this logic with the right one. I am not sure how this is going to be modeeled now.
        return topic.path.hasSuffix("/mock")
    }


    // MARK: Analytics Helpers

    @objc open class func trackLoadedTopic(_ topic: ReaderAbstractTopic, withProperties properties: [AnyHashable: Any]) {
        var stat: WPAnalyticsStat?

        if topicIsFreshlyPressed(topic) {
            stat = .readerFreshlyPressedLoaded

        } else if isTopicDefault(topic) && topicIsDiscover(topic) {
            // Tracks Discover only if it was one of the default menu items.
            stat = .readerDiscoverViewed

        } else if isTopicList(topic) {
            stat = .readerListLoaded

        } else if isTopicTag(topic) {
            stat = .readerTagLoaded

        }
        if stat != nil {
            WPAnalytics.track(stat!, withProperties: properties)
        }
    }


    @objc open class func statsPropertiesForPost(_ post: ReaderPost, andValue value: AnyObject?, forKey key: String?) -> [AnyHashable: Any] {
        var properties = [AnyHashable: Any]()
        properties[WPAppAnalyticsKeyBlogID] = post.siteID
        properties[WPAppAnalyticsKeyPostID] = post.postID
        properties[WPAppAnalyticsKeyIsJetpack] = post.isJetpack
        if let feedID = post.feedID, let feedItemID = post.feedItemID {
            properties[WPAppAnalyticsKeyFeedID] = feedID
            properties[WPAppAnalyticsKeyFeedItemID] = feedItemID
        }

        if let value = value, let key = key {
            properties[key] = value
        }

        return properties
    }


    @objc open class func bumpPageViewForPost(_ post: ReaderPost) {
        // Don't bump page views for feeds else the wrong blog/post get's bumped
        if post.isExternal && !post.isJetpack {
            return
        }

        guard
            let siteID = post.siteID,
            let postID = post.postID,
            let host = NSURL(string: post.blogURL)?.host else {
            return
        }

        // If the user is an admin on the post's site do not bump the page view unless
        // the the post is private.
        if !post.isPrivate() && isUserAdminOnSiteWithID(siteID) {
            return
        }

        let pixelStatReferrer = "https://wordpress.com/"
        let pixel = "https://pixel.wp.com/g.gif"
        let params: NSArray = [
            "v=wpcom",
            "reader=1",
            "ref=\(pixelStatReferrer)",
            "host=\(host)",
            "blog=\(siteID)",
            "post=\(postID)",
            NSString(format: "t=%d", arc4random())
        ]

        let userAgent = WPUserAgent.wordPress()
        let path  = NSString(format: "%@?%@", pixel, params.componentsJoined(by: "&")) as String
        let url = URL(string: path)

        let request = NSMutableURLRequest(url: url!)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.addValue(pixelStatReferrer, forHTTPHeaderField: "Referer")

        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest)
        task.resume()
    }

    @objc open class func isUserAdminOnSiteWithID(_ siteID: NSNumber) -> Bool {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)
        if let blog = blogService.blog(byBlogId: siteID) {
            return blog.isAdmin
        }
        return false
    }

    // convenience method that returns the topic type
    class func topicType(_ topic: ReaderAbstractTopic?) -> ReaderTopicType {
        guard let topic = topic else {
            return .noTopic
        }
        if topicIsDiscover(topic) {
            return .discover
        }
        if topicIsFollowing(topic) {
            return .following
        }
        if topicIsLiked(topic) {
            return .likes
        }
        if isTopicList(topic) {
            return .list
        }
        if isTopicSearchTopic(topic) {
            return .search
        }
        if isTopicSite(topic) {
            return .site
        }
        if isTopicTag(topic) {
            return .tag
        }
        if topic is ReaderTeamTopic {
            return .team
        }
        return .noTopic
    }

    // MARK: Logged in helper

    @objc open class func isLoggedIn() -> Bool {
        return AccountHelper.isDotcomAvailable()
    }
}

/// Reader tab items
extension ReaderHelpers {

    static let defaultSavedItemPosition = 3

    /// Sorts the default tabs according to the order [Following, Discover, Likes], and adds the Saved tab
    class func rearrange(items: [ReaderTabItem]) -> [ReaderTabItem] {

        guard !items.isEmpty else {
                   return items
               }

        var mutableItems = items
        mutableItems.sort {
            guard let leftTopic = $0.content.topic, let rightTopic = $1.content.topic else {
                return true
            }
            // first item: Following
            if topicIsFollowing(leftTopic) {
                return true
            }
            if topicIsFollowing(rightTopic) {
                return false
            }
            // second item: Discover
            if topicIsDiscover(leftTopic) {
                return true
            }
            if topicIsDiscover(rightTopic) {
                return false
            }
            // third item: Likes
            if topicIsLiked(leftTopic) {
                return true
            }
            if topicIsLiked(rightTopic) {
                return false
            // any other items: sort them alphabetically, grouped by topic type
            }
            if leftTopic.type == rightTopic.type {
                return leftTopic.title < rightTopic.title
            }
            return true
        }

        // fourth item: Saved. It's manually inserted after the sorting
        let savedPosition = min(mutableItems.count, defaultSavedItemPosition)
        mutableItems.insert(ReaderTabItem(ReaderContent(topic: nil, contentType: .saved)), at: savedPosition)
        // in case of log in with a self hosted site, prepend a 'dummy' Following tab
        if !isLoggedIn() {
            mutableItems.insert(ReaderTabItem(ReaderContent(topic: nil, contentType: .selfHostedFollowing)), at: 0)
        }
        return mutableItems
    }
}


/// Typed topic type
enum ReaderTopicType {
    case discover
    case following
    case likes
    case list
    case search
    case site
    case tag
    case team
    case noTopic
}
