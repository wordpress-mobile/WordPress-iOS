import Foundation

@objc public class RemoteLikeUser: RemoteUser {
    @objc public var bio: String?
    @objc public var dateLiked: String?
    @objc public var likedSiteID: NSNumber?
    @objc public var likedPostID: NSNumber?
    @objc public var likedCommentID: NSNumber?
    @objc public var preferredBlog: RemoteLikeUserPreferredBlog?

    @objc public init(dictionary: [String: Any], postID: NSNumber, siteID: NSNumber) {
        super.init()
        setValuesFor(dictionary: dictionary)
        likedPostID = postID
        likedSiteID = siteID
    }

    @objc public init(dictionary: [String: Any], commentID: NSNumber, siteID: NSNumber) {
        super.init()
        setValuesFor(dictionary: dictionary)
        likedCommentID = commentID
        likedSiteID = siteID
    }

    private func setValuesFor(dictionary: [String: Any]) {
        userID = dictionary["ID"] as? NSNumber
        username = dictionary["login"] as? String
        displayName = dictionary["name"] as? String
        primaryBlogID = dictionary["site_ID"] as? NSNumber
        avatarURL = dictionary["avatar_URL"] as? String
        bio = dictionary["bio"] as? String
        dateLiked = dictionary["date_liked"] as? String

        preferredBlog = {
            if let preferredBlogDict = dictionary["preferred_blog"] as? [String: Any] {
                return RemoteLikeUserPreferredBlog.init(dictionary: preferredBlogDict)
            }
            return nil
        }()
    }

}

@objc public class RemoteLikeUserPreferredBlog: NSObject {
    @objc public var blogUrl: String
    @objc public var blogName: String
    @objc public var iconUrl: String
    @objc public var blogID: NSNumber?

    public init(dictionary: [String: Any]) {
        blogUrl = dictionary["url"] as? String ?? ""
        blogName = dictionary["name"] as? String ?? ""
        blogID = dictionary["id"] as? NSNumber ?? nil

        iconUrl = {
            if let iconInfo = dictionary["icon"] as? [String: Any],
               let iconImg = iconInfo["img"] as? String {
                return iconImg
            }
            return ""
        }()
    }
}
