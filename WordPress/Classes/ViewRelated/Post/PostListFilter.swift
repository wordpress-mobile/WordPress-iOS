import Foundation

@objc class PostListFilter: NSObject {

    enum Status: UInt {
        case published
        case draft
        case scheduled
        case trashed
    }

    var hasMore: Bool
    var filterType: Status
    var oldestPostDate: Date?
    var predicateForFetchRequest: NSPredicate
    var statuses: [BasePost.Status]
    var title: String

    /// For Obj-C compatibility only
    @objc(statuses)
    var statusesStrings: [String] {
        get {
            return statuses.strings
        }
        set {
            statuses = newValue.flatMap({ BasePost.Status(rawValue: $0) })
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

    var sortAscending: Bool {
        switch filterType {
        case .scheduled:
            return true
        default:
            return false
        }
    }

    var sortDescriptors: [NSSortDescriptor] {
        let dateDescriptor = NSSortDescriptor(key: sortField.keyPath, ascending: sortAscending)
        return [dateDescriptor]
    }

    class func postListFilters() -> [PostListFilter] {
        return [publishedFilter(), draftFilter(), scheduledFilter(), trashedFilter()]
    }

    class func publishedFilter() -> PostListFilter {
        let filterType: Status = .published
        let statuses: [BasePost.Status] = [.publish, .publishPrivate]
        let predicate = NSPredicate(format: "status IN %@ AND remoteStatusNumber <> %d", statuses.strings, AbstractPostRemoteStatus.local.rawValue)
        let title = NSLocalizedString("Published", comment: "Title of the published filter. This filter shows a list of posts that the user has published.")

        return PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
    }

    class func draftFilter() -> PostListFilter {
        let filterType: Status = .draft
        let statuses: [BasePost.Status] = [.draft, .pending]
        let statusesExcluded: [BasePost.Status] = [.publish, .publishPrivate, .scheduled, .trash]
        let predicate = NSPredicate(format: "NOT status IN %@ OR remoteStatusNumber = %d", statusesExcluded.strings, AbstractPostRemoteStatus.local.rawValue)
        let title = NSLocalizedString("Draft", comment: "Title of the draft filter.  This filter shows a list of draft posts.")

        return PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
    }

    class func scheduledFilter() -> PostListFilter {
        let filterType: Status = .scheduled
        let statuses: [BasePost.Status] = [.scheduled]
        let predicate = NSPredicate(format: "status IN %@", statuses.strings)
        let title = NSLocalizedString("Scheduled", comment: "Title of the scheduled filter. This filter shows a list of posts that are scheduled to be published at a future date.")

        return PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
    }

    class func trashedFilter() -> PostListFilter {
        let filterType: Status = .trashed
        let statuses: [BasePost.Status] = [.trash]
        let predicate = NSPredicate(format: "status IN %@", statuses.strings)
        let title = NSLocalizedString("Trashed", comment: "Title of the trashed filter. This filter shows posts that have been moved to the trash bin.")

        return PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
    }
}
