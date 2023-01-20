import Foundation

extension PostCategory {

    static func create(withBlogID id: NSManagedObjectID, in context: NSManagedObjectContext) throws -> PostCategory {
        let object = try context.existingObject(with: id)

        guard let blog = object as? Blog else {
            fatalError("The object id does not belong to a Blog: \(id)")
        }

        let category = PostCategory(context: context)
        category.blog = blog
        return category
    }

    @objc(createWithBlogObjectID:inContext:)
    static func objc_create(withBlogID id: NSManagedObjectID, in context: NSManagedObjectContext) -> PostCategory? {
        try? create(withBlogID: id, in: context)
    }

}
