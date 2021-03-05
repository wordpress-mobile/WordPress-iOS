import Foundation
import CoreData

extension PageTemplateLayout {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PageTemplateLayout> {
        return NSFetchRequest<PageTemplateLayout>(entityName: "PageTemplateLayout")
    }

    @NSManaged public var content: String
    @NSManaged public var preview: String
    @NSManaged public var previewTablet: String
    @NSManaged public var previewMobile: String
    @NSManaged public var demoUrl: String
    @NSManaged public var slug: String
    @NSManaged public var title: String?
    @NSManaged public var categories: Set<PageTemplateCategory>?

}

// MARK: Generated accessors for categories
extension PageTemplateLayout {

    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: PageTemplateCategory)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: PageTemplateCategory)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: Set<PageTemplateCategory>)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: Set<PageTemplateCategory>)
}

extension PageTemplateLayout {

    convenience init(context: NSManagedObjectContext, layout: RemoteLayout) {
        self.init(context: context)
        preview = layout.preview ?? ""
        previewTablet = layout.previewTablet ?? ""
        previewMobile = layout.previewMobile ?? ""
        demoUrl = layout.demoUrl ?? ""
        content = layout.content ?? ""
        title = layout.title
        slug = layout.slug
    }
}

extension PageTemplateLayout: Comparable {
    public static func < (lhs: PageTemplateLayout, rhs: PageTemplateLayout) -> Bool {
        return lhs.slug.compare(rhs.slug) == .orderedDescending
    }

    public static func > (lhs: PageTemplateLayout, rhs: PageTemplateLayout) -> Bool {
        return lhs.slug.compare(rhs.slug) == .orderedAscending
    }
}
