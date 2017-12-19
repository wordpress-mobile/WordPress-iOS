import Foundation


/// This class encapsulates all of the *remote* settings available for a Blog entity
///
public class RemoteBlogSettings: NSObject {
    // MARK: - General

    /// Represents the Blog Name.
    ///
    @objc public var name: String?

    /// Stores the Blog's Tagline setting.
    ///
    @objc public var tagline: String?

    /// Stores the Blog's Privacy Preferences Settings
    ///
    @objc public var privacy: NSNumber?

    /// Stores the Blog's Language ID Setting
    ///
    @objc public var languageID: NSNumber?

    /// Stores the Blog's Icon Media ID
    ///
    @objc public var iconMediaID: NSNumber?

    // MARK: - Writing

    /// Contains the Default Category ID. Used when creating new posts.
    ///
    @objc public var defaultCategoryID: NSNumber?

    /// Contains the Default Post Format. Used when creating new posts.
    ///
    @objc public var defaultPostFormat: String?



    // MARK: - Discussion

    /// Represents whether comments are allowed, or not.
    ///
    @objc public var commentsAllowed: NSNumber?

    /// Contains a list of words that would automatically blacklist a comment.
    ///
    @objc public var commentsBlacklistKeys: String?

    /// If true, comments will be automatically closed after the number of days, specified by `commentsCloseAutomaticallyAfterDays`.
    ///
    @objc public var commentsCloseAutomatically: NSNumber?

    /// Represents the number of days comments will be enabled, granted that the `commentsCloseAutomatically`
    /// property is set to true.
    ///
    @objc public var commentsCloseAutomaticallyAfterDays: NSNumber?

    /// When enabled, comments from known users will be whitelisted.
    ///
    @objc public var commentsFromKnownUsersWhitelisted: NSNumber?

    /// Indicates the maximum number of links allowed per comment. When a new comment exceeds this number,
    /// it'll be held in queue for moderation.
    ///
    @objc public var commentsMaximumLinks: NSNumber?

    /// Contains a list of words that cause a comment to require moderation.
    ///
    @objc public var commentsModerationKeys: String?

    /// If true, comment pagination will be enabled.
    ///
    @objc public var commentsPagingEnabled: NSNumber?

    /// Specifies the number of comments per page. This will be used only if the property `commentsPagingEnabled`
    /// is set to true.
    ///
    @objc public var commentsPageSize: NSNumber?

    /// When enabled, new comments will require Manual Moderation, before showing up.
    ///
    @objc public var commentsRequireManualModeration: NSNumber?

    /// If set to true, commenters will be required to enter their name and email.
    ///
    @objc public var commentsRequireNameAndEmail: NSNumber?

    /// Specifies whether commenters should be registered or not.
    ///
    @objc public var commentsRequireRegistration: NSNumber?

    /// Indicates the sorting order of the comments. Ascending / Descending, based on the date.
    ///
    @objc public var commentsSortOrder: String?

    /// Indicates the number of levels allowed per comment.
    ///
    @objc public var commentsThreadingDepth: NSNumber?

    /// When enabled, comment threading will be supported.
    ///
    @objc public var commentsThreadingEnabled: NSNumber?

    /// If set to true, 3rd party sites will be allowed to post pingbacks.
    ///
    @objc public var pingbackInboundEnabled: NSNumber?

    /// When Outbound Pingbacks are enabled, 3rd party sites that get linked will be notified.
    ///
    @objc public var pingbackOutboundEnabled: NSNumber?



    // MARK: - Related Posts

    /// When set to true, Related Posts will be allowed.
    ///
    @objc public var relatedPostsAllowed: NSNumber?

    /// When set to true, Related Posts will be enabled.
    ///
    @objc public var relatedPostsEnabled: NSNumber?

    /// Indicates whether related posts should show a headline.
    ///
    @objc public var relatedPostsShowHeadline: NSNumber?

    /// Indicates whether related posts should show thumbnails.
    ///
    @objc public var relatedPostsShowThumbnails: NSNumber?


    // MARK: - Sharing

    /// Indicates the style to use for the sharing buttons on a particular blog..
    ///
    @objc public var sharingButtonStyle: String?

    /// The title of the sharing label on the user's blog.
    ///
    @objc public var sharingLabel: String?

    /// Indicates the twitter username to use when sharing via Twitter
    ///
    @objc public var sharingTwitterName: String?

    /// Indicates whether related posts should show thumbnails.
    ///
    @objc public var sharingCommentLikesEnabled: NSNumber?

    /// Indicates whether sharing via post likes has been disabled
    ///
    @objc public var sharingDisabledLikes: NSNumber?

    /// Indicates whether sharing by reblogging has been disabled
    ///
    @objc public var sharingDisabledReblogs: NSNumber?



    // MARK: - Helpers

    /// Computed property, meant to help conversion from Remote / String-Based values, into their Integer counterparts
    ///
    @objc public var commentsSortOrderAscending: Bool {
        set {
            commentsSortOrder = newValue ? RemoteBlogSettings.AscendingStringValue :  RemoteBlogSettings.DescendingStringValue
        }
        get {
            return commentsSortOrder == RemoteBlogSettings.AscendingStringValue
        }
    }



    // MARK: - Private

    fileprivate static let AscendingStringValue     = "asc"
    fileprivate static let DescendingStringValue    = "desc"
}
