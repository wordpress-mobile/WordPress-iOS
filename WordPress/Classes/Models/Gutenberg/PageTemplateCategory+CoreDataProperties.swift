import Foundation
import CoreData

extension PageTemplateCategory {

    @nonobjc public class func fetchRequest(forBlog blog: Blog, categorySlugs: [String]) -> NSFetchRequest<PageTemplateCategory> {
        let request = NSFetchRequest<PageTemplateCategory>(entityName: "PageTemplateCategory")
        let blogPredicate = NSPredicate(format: "\(#keyPath(PageTemplateCategory.blog)) == %@", blog)
        let categoryPredicate = NSPredicate(format: "\(#keyPath(PageTemplateCategory.slug)) IN %@", categorySlugs)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [blogPredicate, categoryPredicate])
        return request
    }

    @nonobjc public class func fetchRequest(forBlog blog: Blog) -> NSFetchRequest<PageTemplateCategory> {
        let request = NSFetchRequest<PageTemplateCategory>(entityName: "PageTemplateCategory")
        request.predicate = NSPredicate(format: "\(#keyPath(PageTemplateCategory.blog)) == %@", blog)
        return request
    }

    @NSManaged public var desc: String?
    @NSManaged public var emoji: String?
    @NSManaged public var slug: String
    @NSManaged public var title: String
    @NSManaged public var layouts: Set<PageTemplateLayout>?
    @NSManaged public var blog: Blog?
    @NSManaged public var ordinal: Int
}

// MARK: Generated accessors for layouts
extension PageTemplateCategory {

    @objc(addLayoutsObject:)
    @NSManaged public func addToLayouts(_ value: PageTemplateLayout)

    @objc(removeLayoutsObject:)
    @NSManaged public func removeFromLayouts(_ value: PageTemplateLayout)

    @objc(addLayouts:)
    @NSManaged public func addToLayouts(_ values: Set<PageTemplateLayout>)

    @objc(removeLayouts:)
    @NSManaged public func removeFromLayouts(_ values: Set<PageTemplateLayout>)

}

extension PageTemplateCategory {

    convenience init(context: NSManagedObjectContext, category: RemoteLayoutCategory, ordinal: Int) {
        self.init(context: context)
        slug = category.slug
        title = category.title
        desc = category.description
        emoji = category.emoji
        self.ordinal = ordinal
    }
}
