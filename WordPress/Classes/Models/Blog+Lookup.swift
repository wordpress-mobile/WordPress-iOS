import Foundation

/// An extension dedicated to looking up and returning blog objects
public extension Blog {

    /// Lookup a Blog by ID
    ///
    /// - Parameters:
    ///   - id: The ID associated with the blog.
    ///
    ///     On a WPMU site, this is the `blog_id` field on the [the wp_blogs table](https://codex.wordpress.org/Database_Description#Table:_wp_blogs).
    ///   - context:  An NSManagedObjectContext containing the `Blog` object with the given `blogID`.
    /// - Returns: The `Blog` object associated with the given `blogID`, if it exists.
    static func lookup(withID id: Int, in context: NSManagedObjectContext) throws -> Blog? {
        return try lookup(withID: Int64(id), in: context)
    }

    /// Lookup a Blog by ID
    ///
    /// - Parameters:
    ///   - id: The ID associated with the blog.
    ///
    ///     On a WPMU site, this is the `blog_id` field on the [the wp_blogs table](https://codex.wordpress.org/Database_Description#Table:_wp_blogs).
    ///   - context:  An NSManagedObjectContext containing the `Blog` object with the given `blogID`.
    /// - Returns: The `Blog` object associated with the given `blogID`, if it exists.
    static func lookup(withID id: Int64, in context: NSManagedObjectContext) throws -> Blog? {
        let fetchRequest = NSFetchRequest<Self>(entityName: Blog.entityName())
        fetchRequest.predicate = NSPredicate(format: "blogID == %ld", id)
        return try context.fetch(fetchRequest).first
    }

    /// Lookup a Blog by ID
    ///
    /// - Parameters:
    ///   - id: The NSNumber-wrapped ID associated with the blog.
    ///
    ///     On a WPMU site, this is the `blog_id` field on the [the wp_blogs table](https://codex.wordpress.org/Database_Description#Table:_wp_blogs).
    ///   - context:  An NSManagedObjectContext containing the `Blog` object with the given `blogID`.
    /// - Returns: The `Blog` object associated with the given `blogID`, if it exists.
    @objc
    static func lookup(withID id: NSNumber, in context: NSManagedObjectContext) -> Blog? {
        let fetchRequest = NSFetchRequest<Self>(entityName: Blog.entityName())
        fetchRequest.predicate = NSPredicate(format: "blogID == %@", id)
        return try? context.fetch(fetchRequest).first
    }
}
