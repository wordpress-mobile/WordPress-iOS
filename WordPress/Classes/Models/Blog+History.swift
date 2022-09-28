import Foundation

extension Blog {

    /// Returns the blog currently flagged as the one last used, or the primary blog,
    /// or the first blog in an alphanumerically sorted list, whichever is found first.
    @objc(lastUsedOrFirstBlogInContext:)
    static func lastUsedOrFirstBlog(in context: NSManagedObjectContext) -> Blog? {
        lastUsedBlog(in: context)
            ?? (try? WPAccount.lookupDefaultWordPressComAccount(in: context))?.defaultBlog
            ?? firstBlog(in: context)
    }

    /// Returns the blog currently flaged as the one last used.
    static func lastUsedBlog(in context: NSManagedObjectContext) -> Blog? {
        guard let url = RecentSitesService().recentSites.first else {
            return nil
        }

        return blog(with: NSPredicate(format: "visible = YES AND url = %@", url), in: context)
    }

    private static func firstBlog(in context: NSManagedObjectContext) -> Blog? {
        blog(with: NSPredicate(format: "visible = YES"), in: context)
    }

    private static func blog(with predicate: NSPredicate, in context: NSManagedObjectContext) -> Blog? {
        let request = NSFetchRequest<Blog>(entityName: NSStringFromClass(Blog.self))
        request.includesSubentities = false
        request.predicate = predicate
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(key: "settings.name", ascending: true)]

        do {
            return try context.fetch(request).first
        } catch {
            DDLogError("Couldn't fetch blogs with predicate \(predicate): \(error)")
            return nil
        }
    }

}
