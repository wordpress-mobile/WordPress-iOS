import Foundation


extension Blog
{
    /// Returns a string, meant for NSFetchedResultsController consumption. Allows us to
    /// group "Primary Blogs" in their own sections.
    ///
    public func sectionIdentifier() -> String {
        // Note: If (This instance) *is* the default blog, `accountForDefaultBlog` will be non-nil.
        // Otherwise, it'll be nil. This is an *easy* way to figure out which blog is the default one. Yay!
        guard let defaultBlogAccountUserID = accountForDefaultBlog?.userID else {
            return String()
        }
        
        return "\(defaultBlogAccountUserID)"
    }
}
