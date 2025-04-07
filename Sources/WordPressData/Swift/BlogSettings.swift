import CoreData
import Foundation

/// This class encapsulates all of the settings available for a Blog entity
///
open class BlogSettings: NSManagedObject {
    // MARK: - Relationships

    /// Maps to the related Blog.
    ///
    @NSManaged public var blog: Blog?

    // MARK: - General

    /// Represents the Blog Name.
    ///
    @NSManaged public var name: String?

    /// Stores the Blog's Tagline setting.
    ///
    @NSManaged public var tagline: String?

    /// Stores the Blog's Privacy Preferences Settings
    ///
    @NSManaged public var privacy: NSNumber?

    /// Stores the Blog's Language ID Setting
    ///
    @NSManaged public var languageID: NSNumber

    /// Stores the Blog's Icon Media ID
    ///
    @NSManaged public var iconMediaID: NSNumber?

    /// Stores the Blog's GMT offset
    ///
    @NSManaged public var gmtOffset: NSNumber?

    /// Stores the Blog's timezone
    ///
    @NSManaged public var timezoneString: String?

    // MARK: - Writing

    /// Contains the Default Category ID. Used when creating new posts.
    ///
    @NSManaged public var defaultCategoryID: NSNumber?

    /// Contains the Default Post Format. Used when creating new posts.
    ///
    @NSManaged public var defaultPostFormat: String?

    /// The blog's date format setting
    ///
    @NSManaged public var dateFormat: String

    /// The blog's time format setting
    ///
    @NSManaged public var timeFormat: String

    /// The blog's chosen day to start the week setting
    ///
    @NSManaged public var startOfWeek: String

    /// The number of posts displayed per blog's page
    ///
    @NSManaged public var postsPerPage: NSNumber?

    /// Jetpack Setting: serve images from our servers.
    ///
    @NSManaged public var jetpackServeImagesFromOurServers: Bool

    /// Jetpack Setting: lazy load images.
    ///
    @available(*, deprecated)
    @NSManaged var jetpackLazyLoadImages: Bool

    // MARK: - Discussion

    /// Represents whether comments are allowed, or not.
    ///
    @NSManaged public var commentsAllowed: Bool

    /// Contains a list of words, space separated, that would cause a comment to be automatically blocklisted.
    ///
    @NSManaged public var commentsBlocklistKeys: Set<String>?

    /// If true, comments will be automatically closed after the number of days, specified by `commentsCloseAutomaticallyAfterDays`.
    ///
    @NSManaged public var commentsCloseAutomatically: Bool

    /// Represents the number of days comments will be enabled, granted that the `commentsCloseAutomatically`
    /// property is set to true.
    ///
    @NSManaged public var commentsCloseAutomaticallyAfterDays: NSNumber?

    /// When enabled, comments from known users will be allowlisted.
    ///
    @NSManaged public var commentsFromKnownUsersAllowlisted: Bool

    /// Indicates the maximum number of links allowed per comment. When a new comment exceeds this number,
    /// it'll be held in queue for moderation.
    ///
    @NSManaged public var commentsMaximumLinks: NSNumber?

    /// Contains a list of words, space separated, that cause a comment to require moderation.
    ///
    @NSManaged public var commentsModerationKeys: Set<String>?

    /// If true, comment pagination will be enabled.
    ///
    @NSManaged public var commentsPagingEnabled: Bool

    /// Specifies the number of comments per page. This will be used only if the property `commentsPagingEnabled`
    /// is set to true.
    ///
    @NSManaged public var commentsPageSize: NSNumber?

    /// When enabled, new comments will require Manual Moderation, before showing up.
    ///
    @NSManaged public var commentsRequireManualModeration: Bool

    /// If set to true, commenters will be required to enter their name and email.
    ///
    @NSManaged public var commentsRequireNameAndEmail: Bool

    /// Specifies whether commenters should be registered or not.
    ///
    @NSManaged public var commentsRequireRegistration: Bool

    /// Indicates the sorting order of the comments. Ascending / Descending, based on the date.
    ///
    @NSManaged public var commentsSortOrder: NSNumber?

    /// Indicates the number of levels allowed per comment.
    ///
    @NSManaged public var commentsThreadingDepth: NSNumber?

    /// When enabled, comment threading will be supported.
    ///
    @NSManaged public var commentsThreadingEnabled: Bool

    /// *LOCAL* flag (non stored remotely) indicating whether post geolocation is enabled or not.
    /// This can be overriden on a per-post basis.
    ///
    @NSManaged public var geolocationEnabled: Bool

    /// If set to true, 3rd party sites will be allowed to post pingbacks.
    ///
    @NSManaged public var pingbackInboundEnabled: Bool

    /// When Outbound Pingbacks are enabled, 3rd party sites that get linked will be notified.
    ///
    @NSManaged public var pingbackOutboundEnabled: Bool

    // MARK: - Related Posts

    /// When set to true, Related Posts will be allowed.
    ///
    @NSManaged public var relatedPostsAllowed: Bool

    /// When set to true, Related Posts will be enabled.
    ///
    @NSManaged public var relatedPostsEnabled: Bool

    /// Indicates whether related posts should show a headline.
    ///
    @NSManaged public var relatedPostsShowHeadline: Bool

    /// Indicates whether related posts should show thumbnails.
    ///
    @NSManaged public var relatedPostsShowThumbnails: Bool

    // MARK: - Sharing

    /// Indicates the style to use for the sharing buttons on a particular blog
    ///
    @NSManaged public var sharingButtonStyle: String

    /// The title of the sharing label on the user's blog.
    ///
    @NSManaged public var sharingLabel: String

    /// Indicates the twitter username to use when sharing via Twitter
    ///
    @NSManaged public var sharingTwitterName: String

    /// Indicates whether related posts should show thumbnails.
    ///
    @NSManaged public var sharingCommentLikesEnabled: Bool

    /// Indicates whether sharing via post likes has been disabled
    ///
    @NSManaged public var sharingDisabledLikes: Bool

    /// Indicates whether sharing by reblogging has been disabled
    ///
    @NSManaged public var sharingDisabledReblogs: Bool

    // MARK: AMP

    /// Indicates whether AMP is supported
    ///
    @NSManaged public var ampSupported: Bool

    /// Indicates whether AMP is enabled
    ///
    @NSManaged public var ampEnabled: Bool

    // MARK: - Jetpack Settings

    /// Indicates whether the Jetpack site's monitor is on or off
    ///
    @NSManaged public var jetpackMonitorEnabled: Bool

    /// Indicates whether the Jetpack site's monitor notifications should be sent by email
    ///
    @NSManaged public var jetpackMonitorEmailNotifications: Bool

    /// Indicates whether the Jetpack site's monitor notifications should be sent by push notifications
    ///
    @NSManaged public var jetpackMonitorPushNotifications: Bool

    /// Indicates whether Jetpack will block malicious login attemps
    ///
    @NSManaged public var jetpackBlockMaliciousLoginAttempts: Bool

    /// List of IP addresses that will never be blocked for logins by Jetpack
    ///
    @NSManaged public var jetpackLoginAllowListedIPAddresses: Set<String>?

    /// Indicates whether WordPress.com SSO is enabled for the Jetpack site
    ///
    @NSManaged public var jetpackSSOEnabled: Bool

    /// Indicates whether SSO will try to match accounts by email address
    ///
    @NSManaged public var jetpackSSOMatchAccountsByEmail: Bool

    /// Indicates whether to force or not two-step authentication when users log in via WordPress.com
    ///
    @NSManaged public var jetpackSSORequireTwoStepAuthentication: Bool

}
