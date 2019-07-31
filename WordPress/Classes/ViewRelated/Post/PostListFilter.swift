import Foundation

@objc class PostListFilter: NSObject, FilterTabBarItem {

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
    @objc var accessibilityIdentifier: String = ""

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

        let predicate = NSPredicate(format: "postID > 0 AND status IN %@", statuses.strings)

        let title = NSLocalizedString("Published", comment: "Title of the published filter. This filter shows a list of posts that the user has published.")

        let filter = PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
        filter.accessibilityIdentifier = "published"

        return filter
    }

    @objc class func draftFilter() -> PostListFilter {
        let filterType: Status = .draft
        let statuses: [BasePost.Status] = [.draft, .pending]
        let statusesExcluded: [BasePost.Status] = [.publish, .publishPrivate, .scheduled, .trash]

        // The postID = -1 condition is intentionally a reverse of publishedFilter() so that
        // local published posts will show in the Drafts list instead of the Published list.
        let predicate = NSPredicate(format: "(postID = -1 AND status = %@) OR NOT status IN %@",
                                    BasePost.Status.publish.rawValue, statusesExcluded.strings)

        let title = NSLocalizedString("Drafts", comment: "Title of the drafts filter.  This filter shows a list of draft posts.")

        let filter = PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
        filter.accessibilityIdentifier = "drafts"

        return filter
    }

    @objc class func scheduledFilter() -> PostListFilter {
        let filterType: Status = .scheduled
        let statuses: [BasePost.Status] = [.scheduled]
        let predicate = NSPredicate(format: "status IN %@", statuses.strings)
        let title = NSLocalizedString("Scheduled", comment: "Title of the scheduled filter. This filter shows a list of posts that are scheduled to be published at a future date.")

        let filter = PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
        filter.accessibilityIdentifier = "scheduled"

        return filter
    }

    @objc class func trashedFilter() -> PostListFilter {
        let filterType: Status = .trashed
        let statuses: [BasePost.Status] = [.trash]
        let predicate = NSPredicate(format: "status IN %@", statuses.strings)
        let title = NSLocalizedString("Trashed", comment: "Title of the trashed filter. This filter shows posts that have been moved to the trash bin.")

        let filter = PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
        filter.accessibilityIdentifier = "trashed"

        return filter
    }
}
