import CoreData
import Foundation

/// A helper to query `Blog` from given `NSManagedObjectContext`.
///
/// Note: the implementation here isn't meant to be a standard way to perform query. But it might be valuable
/// to explore a standard way to perform query. https://github.com/wordpress-mobile/WordPress-iOS/pull/19394 made
/// an attempt, but still has lots of unknowns.
public struct BlogQuery {
    private var predicates = [NSPredicate]()

    public func blogID(_ id: Int) -> Self {
        blogID(Int64(id))
    }

    public func blogID(_ id: NSNumber) -> Self {
        blogID(id.int64Value)
    }

    public func blogID(_ id: Int64) -> Self {
        and(NSPredicate(format: "blogID = %ld", id))
    }

    public func dotComAccountUsername(_ username: String) -> Self {
        and(NSPredicate(format: "account.username = %@", username))
    }

    public func selfHostedBlogUsername(_ username: String) -> Self {
        and(NSPredicate(format: "username = %@", username))
    }

    public func hostname(containing hostname: String) -> Self {
        and(NSPredicate(format: "url CONTAINS %@", hostname))
    }

    public func hostname(matching hostname: String) -> Self {
        and(NSPredicate(format: "url = %@", hostname))
    }

    public func hostedByWPCom(_ flag: Bool) -> Self {
        and(NSPredicate(format: flag ? "account != NULL" : "account == NULL"))
    }

    public func xmlrpc(matching xmlrpc: String) -> Self {
        and(NSPredicate(format: "xmlrpc = %@", xmlrpc))
    }

    public func apiKey(is string: String) -> Self {
        and(NSPredicate(format: "apiKey = %@", string))
    }

    public func count(in context: NSManagedObjectContext) -> Int {
        (try? context.count(for: buildFetchRequest())) ?? 0
    }

    public func blog(in context: NSManagedObjectContext) throws -> Blog? {
        let request = buildFetchRequest()
        request.fetchLimit = 1
        return (try context.fetch(request).first)
    }

    public func blogs(in context: NSManagedObjectContext) throws -> [Blog] {
        try context.fetch(buildFetchRequest())
    }

    private func buildFetchRequest() -> NSFetchRequest<Blog> {
        let request = NSFetchRequest<Blog>(entityName: Blog.entityName())
        request.includesSubentities = false
        request.sortDescriptors = [NSSortDescriptor(key: "settings.name", ascending: true)]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return request
    }

    private func and(_ predicate: NSPredicate) -> Self {
        var query = self
        query.predicates.append(predicate)
        return query
    }
}
