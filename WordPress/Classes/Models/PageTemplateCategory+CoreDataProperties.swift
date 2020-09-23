import Foundation
import CoreData

extension PageTemplateCategory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PageTemplateCategory> {
        return NSFetchRequest<PageTemplateCategory>(entityName: "PageTemplateCategory")
    }

    @NSManaged public var desc: String?
    @NSManaged public var emoji: String?
    @NSManaged public var slug: String?
    @NSManaged public var title: String?
    @NSManaged public var layouts: NSSet?

}

// MARK: Generated accessors for layouts
extension PageTemplateCategory {

    @objc(addLayoutsObject:)
    @NSManaged public func addToLayouts(_ value: PageTemplateLayout)

    @objc(removeLayoutsObject:)
    @NSManaged public func removeFromLayouts(_ value: PageTemplateLayout)

    @objc(addLayouts:)
    @NSManaged public func addToLayouts(_ values: NSSet)

    @objc(removeLayouts:)
    @NSManaged public func removeFromLayouts(_ values: NSSet)

}

extension PageTemplateCategory {

    convenience init(context: NSManagedObjectContext, category: GutenbergLayoutCategory) {
        self.init(context: context)
        slug = category.slug
        title = category.title
        desc = category.description
        emoji = category.emoji
    }

    func update(with category: GutenbergLayoutCategory) {
        slug = category.slug
        title = category.title
        desc = category.description
        emoji = category.emoji
    }
}
