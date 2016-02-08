import Foundation


/// This class encapsulates all of the settings available for a Blog entity
///
public class BlogSettings : NSManagedObject
{
    // MARK: - Relationships
    
    /// Maps to the related Blog.
    ///
    @NSManaged var blog : Blog?
    

    
    // MARK: - General
    
    /// Represents the Blog Name.
    ///
    @NSManaged var name : String?
    
    /// Stores the Blog's Tagline setting.
    ///
    @NSManaged var tagline : String?
    
    /// Stores the Blog's Privacy Preferences Settings
    ///
    @NSManaged var privacy : NSNumber?
    
    /// Stores the Blog's Language ID Setting
    ///
    @NSManaged var languageID : NSNumber
    
    
    
    // MARK: - Writing

    /// Contains the Default Category ID. Used when creating new posts.
    ///
    @NSManaged var defaultCategoryID : NSNumber?
    
    /// Contains the Default Post Format. Used when creating new posts.
    ///
    @NSManaged var defaultPostFormat : String?
    
    
    
    // MARK: - Discussion
    
    /// Represents whether comments are allowed, or not.
    ///
    @NSManaged var commentsAllowed : Bool
    
    /// Contains a list of words, space separated, that would cause a comment to be automatically blacklisted.
    ///
    @NSManaged var commentsBlacklistKeys : Set<String>?
    
    /// If true, comments will be automatically closed after the number of days, specified by `commentsCloseAutomaticallyAfterDays`.
    ///
    @NSManaged var commentsCloseAutomatically : Bool
    
    /// Represents the number of days comments will be enabled, granted that the `commentsCloseAutomatically` 
    /// property is set to true.
    ///
    @NSManaged var commentsCloseAutomaticallyAfterDays : NSNumber?
    
    /// When enabled, comments from known users will be whitelisted.
    ///
    @NSManaged var commentsFromKnownUsersWhitelisted : Bool
    
    /// Indicates the maximum number of links allowed per comment. When a new comment exceeds this number, 
    /// it'll be held in queue for moderation.
    ///
    @NSManaged var commentsMaximumLinks : NSNumber?
    
    /// Contains a list of words, space separated, that cause a comment to require moderation.
    ///
    @NSManaged var commentsModerationKeys : Set<String>?
    
    /// If true, comment pagination will be enabled.
    ///
    @NSManaged var commentsPagingEnabled : Bool
    
    /// Specifies the number of comments per page. This will be used only if the property `commentsPagingEnabled` 
    /// is set to true.
    ///
    @NSManaged var commentsPageSize : NSNumber?
    
    /// When enabled, new comments will require Manual Moderation, before showing up.
    ///
    @NSManaged var commentsRequireManualModeration : Bool
    
    /// If set to true, commenters will be required to enter their name and email.
    ///
    @NSManaged var commentsRequireNameAndEmail : Bool
    
    /// Specifies whether commenters should be registered or not.
    ///
    @NSManaged var commentsRequireRegistration : Bool
    
    /// Indicates the sorting order of the comments. Ascending / Descending, based on the date.
    ///
    @NSManaged var commentsSortOrder : NSNumber?
    
    /// Indicates the number of levels allowed per comment.
    ///
    @NSManaged var commentsThreadingDepth : NSNumber?
    
    /// When enabled, comment threading will be supported.
    ///
    @NSManaged var commentsThreadingEnabled : Bool

    /// *LOCAL* flag (non stored remotely) indicating whether post geolocation is enabled or not.
    /// This can be overriden on a per-post basis.
    ///
    @NSManaged var geolocationEnabled : Bool
    
    /// If set to true, 3rd party sites will be allowed to post pingbacks.
    ///
    @NSManaged var pingbackInboundEnabled : Bool
    
    /// When Outbound Pingbacks are enabled, 3rd party sites that get linked will be notified.
    ///
    @NSManaged var pingbackOutboundEnabled : Bool

    
    
    // MARK: - Related Posts
    
    /// When set to true, Related Posts will be allowed.
    ///
    @NSManaged var relatedPostsAllowed : Bool
    
    /// When set to true, Related Posts will be enabled.
    ///
    @NSManaged var relatedPostsEnabled : Bool
    
    /// Indicates whether related posts should show a headline.
    ///
    @NSManaged var relatedPostsShowHeadline : Bool
    
    /// Indicates whether related posts should show thumbnails.
    ///
    @NSManaged var relatedPostsShowThumbnails : Bool



    // MARK: - Sharing

    /// Indicates the style to use for the sharing buttons on a particular blog
    ///
    @NSManaged var sharingButtonStyle : String

    /// The title of the sharing label on the user's blog.
    ///
    @NSManaged var sharingLabel : String

    /// Indicates the twitter username to use when sharing via Twitter
    ///
    @NSManaged var sharingTwitterName : String

    /// Indicates whether related posts should show thumbnails.
    ///
    @NSManaged var sharingCommentLikesEnabled : Bool

    /// Indicates whether sharing via post likes has been disabled
    ///
    @NSManaged var sharingDisabledLikes : Bool

    /// Indicates whether sharing by reblogging has been disabled
    ///
    @NSManaged var sharingDisabledReblogs : Bool

}
