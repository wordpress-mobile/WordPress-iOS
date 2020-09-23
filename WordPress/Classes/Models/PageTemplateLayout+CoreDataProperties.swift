import Foundation
import CoreData

extension PageTemplateLayout {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PageTemplateLayout> {
        return NSFetchRequest<PageTemplateLayout>(entityName: "PageTemplateLayout")
    }

    @NSManaged public var content: String?
    @NSManaged public var preview: String?
    @NSManaged public var slug: String?
    @NSManaged public var title: String?
    @NSManaged public var categories: NSSet?

}

// MARK: Generated accessors for categories
extension PageTemplateLayout {

    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: PageTemplateCategory)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: PageTemplateCategory)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: NSSet)
}

extension PageTemplateLayout {

    convenience init(context: NSManagedObjectContext, layout: GutenbergLayout) {
        self.init(context: context)
        preview = layout.preview
        content = layout.content
        title = layout.title
        slug = layout.slug
    }

    func update(with layout: GutenbergLayout) {
        preview = layout.preview
        content = layout.content
        title = layout.title
        slug = layout.slug
    }
}
