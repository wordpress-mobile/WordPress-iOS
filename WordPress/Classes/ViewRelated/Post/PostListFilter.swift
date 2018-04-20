import Foundation

@objc class PostListFilter: NSObject {

    enum Status: UInt {
        case published
        case draft
        case scheduled
        case trashed
    }

    @objc var hasMore: Bool
    var filterType: Status
    @objc var oldestPostDate: Date?
    @objc var predicateForFetchRequest: NSPredicate
    var statuses: [BasePost.Status]
    @objc var title: String

    /// For Obj-C compatibility only
    @objc(statuses)
    var statusesStrings: [String] {
        get {
            return statuses.strings
        }
        set {
            statuses = newValue.compactMap({ BasePost.Status(rawValue: $0) })
        }
    }

    init(title: String, filterType: Status, predicate: NSPredicate, statuses: [BasePost.Status]) {
        hasMore = false

        self.filterType = filterType
        predicateForFetchRequest = predicate
        self.statuses = statuses
        self.title = title
    }

    var sortField: AbstractPost.SortField {
        switch filterType {
        case .draft:
            return .dateModified
        default:
            return .dateCreated
        }
    }

    @objc var sortAscending: Bool {
        switch filterType {
        case .scheduled:
            return true
        default:
            return false
        }
    }

    @objc var sortDescriptors: [NSSortDescriptor] {
        let dateDescriptor = NSSortDescriptor(key: sortField.keyPath, ascending: sortAscending)
        return [dateDescriptor]
    }

    @objc class func postListFilters() -> [PostListFilter] {
        return [publishedFilter(), draftFilter(), scheduledFilter(), trashedFilter()]
    }

    @objc class func publishedFilter() -> PostListFilter {
        let filterType: Status = .published
        let statuses: [BasePost.Status] = [.publish, .publishPrivate]

        let predicate = NSPredicate(format: "status IN %@", statuses.strings)

        let title = NSLocalizedString("Published", comment: "Title of the published filter. This filter shows a list of posts that the user has published.")

        return PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
    }

    @objc class func draftFilter() -> PostListFilter {
        let filterType: Status = .draft
        let statuses: [BasePost.Status] = [.draft, .pending]
        let statusesExcluded: [BasePost.Status] = [.publish, .publishPrivate, .scheduled, .trash]

        let predicate = NSPredicate(format: "NOT status IN %@", statusesExcluded.strings)

        let title = NSLocalizedString("Drafts", comment: "Title of the drafts filter.  This filter shows a list of draft posts.")

        return PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
    }

    @objc class func scheduledFilter() -> PostListFilter {
        let filterType: Status = .scheduled
        let statuses: [BasePost.Status] = [.scheduled]
        let predicate = NSPredicate(format: "status IN %@", statuses.strings)
        let title = NSLocalizedString("Scheduled", comment: "Title of the scheduled filter. This filter shows a list of posts that are scheduled to be published at a future date.")

        return PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
    }

    @objc class func trashedFilter() -> PostListFilter {
        let filterType: Status = .trashed
        let statuses: [BasePost.Status] = [.trash]
        let predicate = NSPredicate(format: "status IN %@", statuses.strings)
        let title = NSLocalizedString("Trashed", comment: "Title of the trashed filter. This filter shows posts that have been moved to the trash bin.")

        return PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
    }
}
