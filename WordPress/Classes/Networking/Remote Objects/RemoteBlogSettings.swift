import Foundation


/**
 *  @class           RemoteBlogSettings
 *  @brief           This class encapsulates all of the *remote* settings available for a Blog entity
 */
public class RemoteBlogSettings : NSObject
{
    // MARK: - General
    
    /**
    *  @details Represents the Blog Name.
    */
    var name : String?
    
    /**
     *  @details Stores the Blog's Tagline setting.
     */
    var tagline : String?
    
    /**
     *  @details Stores the Blog's Privacy Preferences Settings
     */
    var privacy : NSNumber?
    
    
    
    // MARK: - Writing
    /**
    *  @details Contains the Default Category ID. Used when creating new posts.
    */
    
    var defaultCategoryID : NSNumber?
    
    /**
     *  @details Contains the Default Post Format. Used when creating new posts.
     */
    var defaultPostFormat : String?
    
    
    
    // MARK: - Discussion
    
    /**
    *  @details Represents whether comments are allowed, or not.
    */
    var commentsAllowed : NSNumber?

    /**
     *  @details Contains a list of words that would automatically blacklist a comment.
     */
    var commentsBlacklistKeys : String?
    
    /**
     *  @details If true, comments will be automatically closed after the number of days, specified
     *           by `commentsCloseAutomaticallyAfterDays`.
     */
    var commentsCloseAutomatically : NSNumber?
    
    /**
     *  @details Represents the number of days comments will be enabled, granted that the
     *           `commentsCloseAutomatically` property is set to true.
     */
    var commentsCloseAutomaticallyAfterDays : NSNumber?

    /**
     *  @details When enabled, comments from known users will be whitelisted.
     */
    var commentsFromKnownUsersWhitelisted : NSNumber?
    
    /**
     *  @details Indicates the maximum number of links allowed per comment. When a new comment exceeds this
     *           number, it'll be held in queue for moderation.
     */
    var commentsMaximumLinks : NSNumber?
    
    /**
     *  @details Contains a list of words that cause a comment to require moderation.
     */
    var commentsModerationKeys : String?
    
    /**
     *  @details If true, comment pagination will be enabled.
     */
    var commentsPagingEnabled : NSNumber?
    
    /**
     *  @details Specifies the number of comments per page. This will be used only if the property
     *           `commentsPagingEnabled` is set to true.
     */
    var commentsPageSize : NSNumber?
    
    /**
     *  @details When enabled, new comments will require Manual Moderation, before showing up.
     */
    var commentsRequireManualModeration : NSNumber?
    
    /**
     *  @details If set to true, commenters will be required to enter their name and email.
     */
    var commentsRequireNameAndEmail : NSNumber?
    
    /**
     *  @details Specifies whether commenters should be registered or not.
     */
    var commentsRequireRegistration : NSNumber?
    
    /**
     *  @details Indicates the sorting order of the comments. Ascending / Descending, based on the date.
     */
    var commentsSortOrder : String?
    
    /**
     *  @details Indicates the number of levels allowed per comment.
     */
    var commentsThreadingDepth : NSNumber?
    
    /**
     *  @details When enabled, comment threading will be supported.
     */
    var commentsThreadingEnabled : NSNumber?
    
    /**
     *  @details If set to true, 3rd party sites will be allowed to post pingbacks.
     */
    var pingbackInboundEnabled : NSNumber?
    
    /**
     *  @details When Outbound Pingbacks are enabled, 3rd party sites that get linked will be notified.
     */
    var pingbackOutboundEnabled : NSNumber?
    
    
    
    // MARK: - Related Posts
    
    /**
    *  @details When set to true, Related Posts will be allowed.
    */
    var relatedPostsAllowed : NSNumber?
    
    /**
     *  @details When set to true, Related Posts will be enabled.
     */
    var relatedPostsEnabled : NSNumber?
    
    /**
     *  @details Indicates whether related posts should show a headline.
     */
    var relatedPostsShowHeadline : NSNumber?
    
    /**
     *  @details Indicates whether related posts should show thumbnails.
     */
    var relatedPostsShowThumbnails : NSNumber?
    

    // MARK: - Sharing

    /// Indicates the style to use for the sharing buttons on a particular blog..
    ///
    var sharingButtonStyle : String?

    /// The title of the sharing label on the user's blog.
    ///
    var sharingLabel : String?

    /// Indicates the twitter username to use when sharing via Twitter
    ///
    var sharingTwitterName : String?

    /// Indicates whether related posts should show thumbnails.
    ///
    var sharingCommentLikesEnabled : NSNumber?

    /// Indicates whether sharing via post likes has been disabled
    ///
    var sharingDisabledLikes : NSNumber?

    /// Indicates whether sharing by reblogging has been disabled
    ///
    var sharingDisabledReblogs : NSNumber?

    
    
    // MARK: - Helpers
    
    /**
    *  @details Computed property, meant to help conversion from Remote / String-Based values, into their
    *           Integer counterparts
    */
    var commentsSortOrderAscending : Bool {
        set {
            commentsSortOrder = newValue ? RemoteBlogSettings.AscendingStringValue :  RemoteBlogSettings.DescendingStringValue
        }
        get {
            return commentsSortOrder == RemoteBlogSettings.AscendingStringValue
        }
    }
    

    
    // MARK: - Private
    
    private static let AscendingStringValue     = "asc"
    private static let DescendingStringValue    = "desc"
}
