import Foundation


public class BlogSettings
{
    @NSManaged var blog                         : Blog
    @NSManaged var relatedPostsAllowed          : Bool
    @NSManaged var relatedPostsEnabled          : Bool
    @NSManaged var relatedPostsShowHeadline     : Bool
    @NSManaged var relatedPostsShowThumbnails   : Bool
}
