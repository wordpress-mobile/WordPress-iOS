import Foundation

extension PostCategory {

    static func lookup(withBlogID id: NSManagedObjectID, categoryID: NSNumber, in context: NSManagedObjectContext) throws -> PostCategory? {
        try lookup(withBlogID: id, predicate: NSPredicate(format: "categoryID == %@", categoryID), in: context)
    }

    static func lookup(withBlogID id: NSManagedObjectID, parentCategoryID: NSNumber?, categoryName: String, in context: NSManagedObjectContext) throws -> PostCategory? {
        try lookup(
            withBlogID: id,
            predicate: NSPredicate(format: "(categoryName like %@) AND (parentID = %@)", categoryName, parentCategoryID ?? 0),
            in: context
        )
    }

    private static func lookup(withBlogID id: NSManagedObjectID, predicate: NSPredicate, in context: NSManagedObjectContext) throws -> PostCategory? {
        let object = try context.existingObject(with: id)

        guard let blog = object as? Blog else {
            fatalError("The object id does not belong to a Blog: \(id)")
        }

        return blog.categories?.first { predicate.evaluate(with: $0) } as? PostCategory
    }

}

// MARK: - Objective-C API

extension PostCategory {

    @objc(lookupWithBlogObjectID:categoryID:inContext:)
    static func objc_lookup(withBlogID id: NSManagedObjectID, categoryID: NSNumber, in context: NSManagedObjectContext) -> PostCategory? {
        try? lookup(withBlogID: id, categoryID: categoryID, in: context)
    }

    @objc(lookupWithBlogObjectID:parentCategoryID:categoryName:inContext:)
    static func objc_lookup(withBlogID id: NSManagedObjectID, parentCategoryID: NSNumber?, categoryName: String, in context: NSManagedObjectContext) -> PostCategory? {
        try? lookup(withBlogID: id, parentCategoryID: parentCategoryID, categoryName: categoryName, in: context)
    }

}
