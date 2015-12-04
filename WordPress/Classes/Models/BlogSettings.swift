import Foundation


/**
 *  @class           BlogSettings
 *  @brief           This class encapsulates all of the settings available for a Blog entity
 */
public class BlogSettings : NSManagedObject
{
    // MARK: - Relationships
    
    /**
    *  @details Maps to the related Blog.
    */
    @NSManaged var blog : Blog?
    

    
    // MARK: - General
    
    /**
    *  @details Represents the Blog Name.
    */
    @NSManaged var name : String?
    
    /**
     *  @details Stores the Blog's Tagline setting.
     */
    @NSManaged var tagline : String?
    
    /**
     *  @details Stores the Blog's Privacy Preferences Settings
     */
    @NSManaged var privacy : NSNumber?

    
    
    // MARK: - Writing
    /**
    *  @details Contains the Default Category ID. Used when creating new posts.
    */
    
    @NSManaged var defaultCategoryID : NSNumber?
    
    /**
    *  @details Contains the Default Post Format. Used when creating new posts.
    */
    @NSManaged var defaultPostFormat : String?
    
    
    
    // MARK: - Discussion
    
    /**
    *  @details Represents whether comments are allowed, or not.
    */
    @NSManaged var commentsAllowed : Bool
    
    /**
     *  @details Contains a list of words, space separated, that would cause a comment to be automatically
     *           blacklisted.
     */
    @NSManaged var commentsBlacklistKeys : Set<String>?
    
    /**
     *  @details If true, comments will be automatically closed after the number of days, specified
     *           by `commentsCloseAutomaticallyAfterDays`.
     */
    @NSManaged var commentsCloseAutomatically : Bool
    
    /**
     *  @details Represents the number of days comments will be enabled, granted that the
     *           `commentsCloseAutomatically` property is set to true.
     */
    @NSManaged var commentsCloseAutomaticallyAfterDays : NSNumber?
    
    /**
     *  @details When enabled, comments from known users will be whitelisted.
     */
    @NSManaged var commentsFromKnownUsersWhitelisted : Bool
    
    /**
     *  @details Indicates the maximum number of links allowed per comment. When a new comment exceeds this
     *           number, it'll be held in queue for moderation.
     */
    @NSManaged var commentsMaximumLinks : NSNumber?
    
    /**
     *  @details Contains a list of words, space separated, that cause a comment to require moderation.
     */
    @NSManaged var commentsModerationKeys : Set<String>?
    
    /**
     *  @details If true, comment pagination will be enabled.
     */
    @NSManaged var commentsPagingEnabled : Bool
    
    /**
     *  @details Specifies the number of comments per page. This will be used only if the property
     *           `commentsPagingEnabled` is set to true.
     */
    @NSManaged var commentsPageSize : NSNumber?
    
    /**
     *  @details When enabled, new comments will require Manual Moderation, before showing up.
     */
    @NSManaged var commentsRequireManualModeration : Bool
    
    /**
     *  @details If set to true, commenters will be required to enter their name and email.
     */
    @NSManaged var commentsRequireNameAndEmail : Bool
    
    /**
     *  @details Specifies whether commenters should be registered or not.
     */
    @NSManaged var commentsRequireRegistration : Bool
    
    /**
     *  @details Indicates the sorting order of the comments. Ascending / Descending, based on the date.
     */
    @NSManaged var commentsSortOrder : NSNumber?
    
    /**
     *  @details Indicates the number of levels allowed per comment.
     */
    @NSManaged var commentsThreadingDepth : NSNumber?
    
    /**
     *  @details When enabled, comment threading will be supported.
     */
    @NSManaged var commentsThreadingEnabled : Bool

    /**
     *  @details *LOCAL* flag (non stored remotely) indicating whether post geolocation is enabled or not.
     *           This can be overriden on a per-post basis.
     */
    @NSManaged var geolocationEnabled : Bool
    
    /**
     *  @details If set to true, 3rd party sites will be allowed to post pingbacks.
     */
    @NSManaged var pingbackInboundEnabled : Bool
    
    /**
     *  @details When Outbound Pingbacks are enabled, 3rd party sites that get linked will be notified.
     */
    @NSManaged var pingbackOutboundEnabled : Bool

    
    
    // MARK: - Related Posts
    
    /**
    *  @details When set to true, Related Posts will be allowed.
    */
    @NSManaged var relatedPostsAllowed : Bool
    
    /**
    *  @details When set to true, Related Posts will be enabled.
     */
    @NSManaged var relatedPostsEnabled : Bool
    
    /**
     *  @details Indicates whether related posts should show a headline.
     */
    @NSManaged var relatedPostsShowHeadline : Bool
    
    /**
     *  @details Indicates whether related posts should show thumbnails.
     */
    @NSManaged var relatedPostsShowThumbnails : Bool
}
