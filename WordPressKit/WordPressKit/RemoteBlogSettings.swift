import Foundation


/// This class encapsulates all of the *remote* settings available for a Blog entity
///
public class RemoteBlogSettings: NSObject {
    // MARK: - General

    /// Represents the Blog Name.
    ///
    public var name: String?

    /// Stores the Blog's Tagline setting.
    ///
    public var tagline: String?

    /// Stores the Blog's Privacy Preferences Settings
    ///
    public var privacy: NSNumber?

    /// Stores the Blog's Language ID Setting
    ///
    public var languageID: NSNumber?

    /// Stores the Blog's Icon Media ID
    ///
    public var iconMediaID: NSNumber?

    // MARK: - Writing

    /// Contains the Default Category ID. Used when creating new posts.
    ///
    public var defaultCategoryID: NSNumber?

    /// Contains the Default Post Format. Used when creating new posts.
    ///
    public var defaultPostFormat: String?



    // MARK: - Discussion

    /// Represents whether comments are allowed, or not.
    ///
    public var commentsAllowed: NSNumber?

    /// Contains a list of words that would automatically blacklist a comment.
    ///
    public var commentsBlacklistKeys: String?

    /// If true, comments will be automatically closed after the number of days, specified by `commentsCloseAutomaticallyAfterDays`.
    ///
    public var commentsCloseAutomatically: NSNumber?

    /// Represents the number of days comments will be enabled, granted that the `commentsCloseAutomatically`
    /// property is set to true.
    ///
    public var commentsCloseAutomaticallyAfterDays: NSNumber?

    /// When enabled, comments from known users will be whitelisted.
    ///
    public var commentsFromKnownUsersWhitelisted: NSNumber?

    /// Indicates the maximum number of links allowed per comment. When a new comment exceeds this number,
    /// it'll be held in queue for moderation.
    ///
    public var commentsMaximumLinks: NSNumber?

    /// Contains a list of words that cause a comment to require moderation.
    ///
    public var commentsModerationKeys: String?

    /// If true, comment pagination will be enabled.
    ///
    public var commentsPagingEnabled: NSNumber?

    /// Specifies the number of comments per page. This will be used only if the property `commentsPagingEnabled`
    /// is set to true.
    ///
    public var commentsPageSize: NSNumber?

    /// When enabled, new comments will require Manual Moderation, before showing up.
    ///
    public var commentsRequireManualModeration: NSNumber?

    /// If set to true, commenters will be required to enter their name and email.
    ///
    public var commentsRequireNameAndEmail: NSNumber?

    /// Specifies whether commenters should be registered or not.
    ///
    public var commentsRequireRegistration: NSNumber?

    /// Indicates the sorting order of the comments. Ascending / Descending, based on the date.
    ///
    public var commentsSortOrder: String?

    /// Indicates the number of levels allowed per comment.
    ///
    public var commentsThreadingDepth: NSNumber?

    /// When enabled, comment threading will be supported.
    ///
    public var commentsThreadingEnabled: NSNumber?

    /// If set to true, 3rd party sites will be allowed to post pingbacks.
    ///
    public var pingbackInboundEnabled: NSNumber?

    /// When Outbound Pingbacks are enabled, 3rd party sites that get linked will be notified.
    ///
    public var pingbackOutboundEnabled: NSNumber?



    // MARK: - Related Posts

    /// When set to true, Related Posts will be allowed.
    ///
    public var relatedPostsAllowed: NSNumber?

    /// When set to true, Related Posts will be enabled.
    ///
    public var relatedPostsEnabled: NSNumber?

    /// Indicates whether related posts should show a headline.
    ///
    public var relatedPostsShowHeadline: NSNumber?

    /// Indicates whether related posts should show thumbnails.
    ///
    public var relatedPostsShowThumbnails: NSNumber?


    // MARK: - Sharing

    /// Indicates the style to use for the sharing buttons on a particular blog..
    ///
    public var sharingButtonStyle: String?

    /// The title of the sharing label on the user's blog.
    ///
    public var sharingLabel: String?

    /// Indicates the twitter username to use when sharing via Twitter
    ///
    public var sharingTwitterName: String?

    /// Indicates whether related posts should show thumbnails.
    ///
    public var sharingCommentLikesEnabled: NSNumber?

    /// Indicates whether sharing via post likes has been disabled
    ///
    public var sharingDisabledLikes: NSNumber?

    /// Indicates whether sharing by reblogging has been disabled
    ///
    public var sharingDisabledReblogs: NSNumber?



    // MARK: - Helpers

    /// Computed property, meant to help conversion from Remote / String-Based values, into their Integer counterparts
    ///
    public var commentsSortOrderAscending: Bool {
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
