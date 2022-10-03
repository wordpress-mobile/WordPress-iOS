import Foundation

extension Blog {

    /// Returns the blog currently flagged as the one last used, or the primary blog,
    /// or the first blog in an alphanumerically sorted list, whichever is found first.
    @objc(lastUsedOrFirstInContext:)
    static func lastUsedOrFirst(in context: NSManagedObjectContext) -> Blog? {
        lastUsed(in: context)
            ?? (try? WPAccount.lookupDefaultWordPressComAccount(in: context))?.defaultBlog
            ?? firstBlog(in: context)
    }

    /// Returns the blog currently flaged as the one last used.
    static func lastUsed(in context: NSManagedObjectContext) -> Blog? {
        guard let url = RecentSitesService().recentSites.first else {
            return nil
        }

        return try? CoreDataQuery<Blog>.default()
            .visible(true)
            .hostname(matching: url)
            .first(in: context)
    }

    private static func firstBlog(in context: NSManagedObjectContext) -> Blog? {
        try? CoreDataQuery<Blog>.default()
            .visible(true)
            .first(in: context)
    }

}
