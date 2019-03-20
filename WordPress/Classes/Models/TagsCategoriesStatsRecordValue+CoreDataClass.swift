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
        self.type = tagCategoryType(from: tagCategory.kind).rawValue

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

    init?(statsRecordValues: [StatsRecordValue]) {
        guard
            let categories = statsRecordValues as? [TagsCategoriesStatsRecordValue]
            else {
                return nil
        }

        self = StatsTagsAndCategoriesInsight(topTagsAndCategories: categories.compactMap { StatsTagAndCategory(recordValue: $0) })
    }

    static var recordType: StatsRecordType {
        return .tagsAndCategories
    }
}

fileprivate extension StatsTagAndCategory {
    init?(recordValue: TagsCategoriesStatsRecordValue) {
        guard
            let name = recordValue.name,
            let categoriesType = TagsCategoriesType(rawValue: recordValue.type),
            let children = recordValue.children?.array as? [TagsCategoriesStatsRecordValue]
            else {
            return nil
        }

        self = StatsTagAndCategory(name: name, kind: tagAndCategoryKind(from: categoriesType),
                                   url: recordValue.linkURL,
                                   viewsCount: Int(recordValue.viewsCount),
                                   children: children.compactMap { StatsTagAndCategory(recordValue: $0) })
    }
}

fileprivate func tagAndCategoryKind(from localType: TagsCategoriesType) -> StatsTagAndCategory.Kind {
    switch localType {
    case .tag:
        return .tag
    case .category:
        return .category
    case .folder:
        return .folder
    }
}

fileprivate func tagCategoryType(from kind: StatsTagAndCategory.Kind) -> TagsCategoriesType {
    switch kind {
    case .category:
        return TagsCategoriesType.category
    case .folder:
        return TagsCategoriesType.folder
    case .tag:
        return TagsCategoriesType.tag
    }
}
