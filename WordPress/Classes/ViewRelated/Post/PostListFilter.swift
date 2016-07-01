import Foundation

@objc class PostListFilter: NSObject {

    enum Status: UInt {
        case Published
        case Draft
        case Scheduled
        case Trashed
    }

    var hasMore: Bool
    var filterType: Status
    var oldestPostDate: NSDate?
    var predicateForFetchRequest: NSPredicate
    var statuses: [String]
    var title: String

    init(title: String, filterType: Status, predicate: NSPredicate, statuses: [String]) {
        hasMore = true

        self.filterType = filterType
        predicateForFetchRequest = predicate
        self.statuses = statuses
        self.title = title
    }

    class func postListFilters() -> [PostListFilter] {
        return [publishedFilter(), draftFilter(), scheduledFilter(), trashedFilter()]
    }

    class func publishedFilter() -> PostListFilter {
        let filterType: Status = .Published
        let predicate = NSPredicate(format: "status IN %@", [PostStatusPublish, PostStatusPrivate])
        let statuses = [PostStatusPublish, PostStatusPrivate]
        let title = NSLocalizedString("Published", comment: "Title of the published filter. This filter shows a list of posts that the user has published.")

        return PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
    }

    class func draftFilter() -> PostListFilter {
        let filterType: Status = .Draft
        let predicate = NSPredicate(format: "NOT status IN %@", [PostStatusPublish, PostStatusPrivate, PostStatusScheduled, PostStatusTrash])
        let statuses = [PostStatusDraft, PostStatusPending]
        let title = NSLocalizedString("Draft", comment: "Title of the draft filter.  This filter shows a list of draft posts.")

        return PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
    }

    class func scheduledFilter() -> PostListFilter {
        let filterType: Status = .Scheduled
        let predicate = NSPredicate(format: "status = %@", PostStatusScheduled)
        let statuses = [PostStatusScheduled]
        let title = NSLocalizedString("Scheduled", comment: "Title of the scheduled filter. This filter shows a list of posts that are scheduled to be published at a future date.")

        return PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
    }

    class func trashedFilter() -> PostListFilter {
        let filterType: Status = .Trashed
        let predicate = NSPredicate(format: "status = %@", PostStatusTrash)
        let statuses = [PostStatusTrash]
        let title = NSLocalizedString("Trashed", comment: "Title of the trashed filter. This filter shows posts that have been moved to the trash bin.")

        return PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
    }
}
