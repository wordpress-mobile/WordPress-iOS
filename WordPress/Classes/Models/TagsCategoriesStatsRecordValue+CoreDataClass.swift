import Foundation
import CoreData


public enum TagsCategoriesType: Int16 {
    case tag
    case category
    case folder
}

public class TagsCategoriesStatsRecordValue: StatsRecordValue {

    public var linkURL: URL? {
        guard let url = urlString as String? else {
            return nil
        }
        return URL(string: url)
    }

    public override func validateForInsert() throws {
        try super.validateForInsert()

        guard let type = TagsCategoriesType(rawValue: type) else {
            throw StatsCoreDataValidationError.invalidEnumValue
        }

        if let children = children, children.count > 0 {
            guard type == .folder else {
                throw StatsCoreDataValidationError.invalidEnumValue
            }
        }
    }
}

fileprivate extension TagsCategoriesStatsRecordValue {
    convenience init?(context: NSManagedObjectContext, tagCategory: StatsTagAndCategory) {
        self.init(context: context)

        self.name = tagCategory.name
        self.urlString = tagCategory.url?.absoluteString
        self.viewsCount = Int64(tagCategory.viewsCount ?? 0)

        switch tagCategory.kind {
        case .category:
            self.type = TagsCategoriesType.category.rawValue
        case .folder:
            self.type = TagsCategoriesType.folder.rawValue
        case .tag:
            self.type = TagsCategoriesType.tag.rawValue
        }

        let children = tagCategory.children.compactMap { TagsCategoriesStatsRecordValue(context: context, tagCategory: $0) }

        self.children = NSOrderedSet(array: children)
    }
}

extension StatsTagsAndCategoriesInsight: StatsRecordValueConvertible {
    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        return topTagsAndCategories.compactMap {
            return TagsCategoriesStatsRecordValue(context: context, tagCategory: $0)
        }
    }

    init(statsRecordValue: StatsRecordValue) {
        // We won't be needing those until later. I added them to protocol to show the intended design
        // but it doesn't make sense to implement it yet.
        fatalError("This shouldn't be called yet — implementation of StatsRecordValueConvertible is still in progres. This method was added to illustrate intended design, but isn't ready yet.")
    }

    static var recordType: StatsRecordType {
        return .tagsAndCategories
    }


}
