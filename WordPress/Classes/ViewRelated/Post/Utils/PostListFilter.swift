import Foundation

@objc class PostListFilter: NSObject, FilterTabBarItem {

    enum Status: UInt {
        case published
        case draft
        case scheduled
        case trashed
        case allNonTrashed
    }

    @objc var hasMore: Bool
    var filterType: Status
    @objc var oldestPostDate: Date?
    @objc var predicateForFetchRequest: NSPredicate
    /// The statuses used when synchronizing the tab
    var statuses: [BasePost.Status]
    @objc var title: String
    @objc var accessibilityIdentifier: String = ""

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
            fallthrough
        case .allNonTrashed:
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

    static func makePredicateForStatuses(_ statuses: [BasePost.Status]) -> NSPredicate {
        NSPredicate(format: "status IN (%@)", statuses.map(\.rawValue))
    }

    /// The filter for the Published tab in the Post List
    ///
    /// Shows:
    ///
    /// - existing published/private posts
    /// - existing published/private posts transitioned to another status (e.g. draft)
    ///   but not uploaded yet
    ///
    @objc class func publishedFilter() -> PostListFilter {
        let filterType: Status = .published
        let statuses: [BasePost.Status] = [.publish, .publishPrivate]

        let predicate = makePredicateForStatuses([.publish, .publishPrivate])

        let title = NSLocalizedString("Published", comment: "Title of the published filter. This filter shows a list of posts that the user has published.")

        let filter = PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
        filter.accessibilityIdentifier = "published"

        return filter
    }

    /// The filter for the Drafts tab in the Post List
    ///
    /// Shows:
    ///
    /// - local drafts: posts that only exist on the device
    /// - local drafts with published/private/scheduled/pending statuses
    /// - existing draft/pending posts
    /// - existing draft/pending posts transitioned to another status (e.g. published)
    ///   but not uploaded yet
    ///
    @objc class func draftFilter() -> PostListFilter {
        let filterType: Status = .draft
        let statuses: [BasePost.Status] = [.draft, .pending]

        let predicate = makePredicateForStatuses([.draft, .pending])

        let title = NSLocalizedString("Drafts", comment: "Title of the drafts filter.  This filter shows a list of draft posts.")

        let filter = PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
        filter.accessibilityIdentifier = "drafts"

        return filter
    }

    /// The filter for the Scheduled tab in the Post List
    ///
    /// Shows:
    ///
    /// - existing scheduled posts
    /// - existing scheduled posts transitioned to another status (e.g. draft) but not uploaded yet
    ///
    @objc class func scheduledFilter() -> PostListFilter {
        let filterType: Status = .scheduled
        let statuses: [BasePost.Status] = [.scheduled]

        let predicate = makePredicateForStatuses([.scheduled])

        let title = NSLocalizedString("Scheduled", comment: "Title of the scheduled filter. This filter shows a list of posts that are scheduled to be published at a future date.")

        let filter = PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
        filter.accessibilityIdentifier = "scheduled"

        return filter
    }

    @objc class func trashedFilter() -> PostListFilter {
        let filterType: Status = .trashed
        let statuses: [BasePost.Status] = [.trash]
        let predicate = makePredicateForStatuses(statuses)
        let title = NSLocalizedString("Trashed", comment: "Title of the trashed filter. This filter shows posts that have been moved to the trash bin.")

        let filter = PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
        filter.accessibilityIdentifier = "trashed"

        return filter
    }

    @objc class func allNonTrashedFilter() -> PostListFilter {
        let filterType: Status = .allNonTrashed
        let statuses: [BasePost.Status] = [.draft, .pending, .publish, .publishPrivate, .scheduled]

        let predicate = makePredicateForStatuses(statuses)

        let title = NSLocalizedString("All", comment: "Title of the drafts filter. This filter shows a list of draft posts.")

        let filter = PostListFilter(title: title, filterType: filterType, predicate: predicate, statuses: statuses)
        filter.accessibilityIdentifier = "all"

        return filter
    }

    func predicate(for blog: Blog, author: PostListFilterSettings.AuthorFilter = .mine) -> NSPredicate {
        var predicates = [NSPredicate]()

        // Show all original posts without a revision & revision posts.
        let basePredicate = NSPredicate(format: "blog = %@ && revision = nil", blog)
        predicates.append(basePredicate)

        predicates.append(predicateForFetchRequest)

        if author == .mine, let myAuthorID = blog.userID {
            // Brand new local drafts have an authorID of 0.
            let authorPredicate = NSPredicate(format: "authorID = %@ || authorID = 0", myAuthorID)
            predicates.append(authorPredicate)
        }

       let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
       return predicate
    }
}
