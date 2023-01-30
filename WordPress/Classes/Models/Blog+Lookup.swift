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
        // Because a `nil` NSNumber can be passed from Objective-C, we can't trust the object
        // to have a valid value. For that reason, we'll unwrap it to an `int64` and look that up instead.
        // That way, if the `id` is `nil`, it'll return nil instead of crashing while trying to
        // assemble the predicate as in `NSPredicate("blogID == %@")`
        try? lookup(withID: id.int64Value, in: context)
    }

    /// Lookup a Blog by its hostname
    ///
    /// - Parameters:
    ///   - hostname: The hostname of the blog.
    ///   - context:  An `NSManagedObjectContext` containing the `Blog` object with the given `hostname`.
    /// - Returns: The `Blog` object associated with the given `hostname`, if it exists.
    @objc(lookupWithHostname:inContext:)
    static func lookup(hostname: String, in context: NSManagedObjectContext) -> Blog? {
        try? BlogQuery().hostname(containing: hostname).blog(in: context)
    }

    /// Lookup a Blog by WP.ORG Credentials
    ///
    /// - Parameters:
    ///   - username: The username associated with the blog.
    ///   - xmlrpc: The xmlrpc URL address
    ///   - context:  An NSManagedObjectContext containing the `Blog` object with the given `blogID`.
    /// - Returns: The `Blog` object associated with the given `username` and `xmlrpc`, if it exists.
    @objc(lookupWithUsername:xmlrpc:inContext:)
    static func lookup(username: String, xmlrpc: String, in context: NSManagedObjectContext) -> Blog? {
        try? BlogQuery().xmlrpc(matching: xmlrpc).selfHostedBlogUsername(username).blog(in: context)
    }

    /// Searches for a `Blog` object for this account with the given XML-RPC endpoint
    ///
    /// - Warning: If more than one blog is found, they'll be considered duplicates and be
    /// deleted leaving only one of them.
    ///
    /// - Parameters:
    ///   - xmlrpc: the XML-RPC endpoint URL as a string
    ///   - account: the account the blog belongs to
    ///   - context: the NSManagedObjectContext containing the account and the Blog object.
    /// - Returns: the blog if one was found, otherwise it returns nil
    static func lookup(xmlrpc: String, andRemoveDuplicateBlogsOf account: WPAccount, in context: NSManagedObjectContext) -> Blog? {
        let predicate = NSPredicate(format: "xmlrpc like %@", xmlrpc)
        let foundBlogs = account.blogs.filter { predicate.evaluate(with: $0) }

        if foundBlogs.isEmpty {
            return nil
        }

        if foundBlogs.count == 1 {
            return foundBlogs.first
        }

        // If more than one blog matches, return the first and delete the rest

        // Choose blogs with URL not starting with https to account for a glitch in the API in early 2014
        let blogToReturn = foundBlogs.first { $0.url?.starts(with: "https://") == false }
            ?? foundBlogs.randomElement()!

        // Remove the duplicates
        var duplicates = foundBlogs
        duplicates.remove(blogToReturn)
        duplicates.forEach(context.delete(_:))

        return blogToReturn
    }

    @objc(countInContext:)
    static func count(in context: NSManagedObjectContext) -> Int {
        BlogQuery().count(in: context)
    }

    @objc(wpComBlogCountInContext:)
    static func wpComBlogCount(in context: NSManagedObjectContext) -> Int {
        BlogQuery().hostedByWPCom(true).count(in: context)
    }

    static func hasAnyJetpackBlogs(in context: NSManagedObjectContext) throws -> Bool {
        let fetchRequest = NSFetchRequest<Self>(entityName: Blog.entityName())
        fetchRequest.predicate = NSPredicate(format: "account != NULL AND isHostedAtWPcom = NO")
        if try context.count(for: fetchRequest) > 0 {
            return true
        }

        return Blog.selfHosted(in: context)
            .filter { $0.jetpack?.isConnected == true }
            .count > 0
    }

    @available(swift, obsoleted: 1.0)
    @objc(hasAnyJetpackBlogsInContext:)
    static func objc_hasAnyJetpackBlogs(in context: NSManagedObjectContext) -> Bool {
        (try? hasAnyJetpackBlogs(in: context)) == true
    }

    @objc(selfHostedInContext:)
    static func selfHosted(in context: NSManagedObjectContext) -> [Blog] {
        (try? BlogQuery().hostedByWPCom(false).blogs(in: context)) ?? []
    }

    /// Find a cached comment with given ID.
    ///
    /// - Parameter id: The comment id
    /// - Returns: The `Comment` object associated with the given id, or `nil` if none is found.
    @objc
    func comment(withID id: NSNumber) -> Comment? {
        comment(withID: id.int32Value)
    }

    /// Find a cached comment with given ID.
    ///
    /// - Parameter id: The comment id
    /// - Returns: The `Comment` object associated with the given id, or `nil` if none is found.
    func comment(withID id: Int32) -> Comment? {
        (comments as? Set<Comment>)?.first { $0.commentID == id }
    }

}
