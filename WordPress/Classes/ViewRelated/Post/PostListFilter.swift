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
    /// The statuses used when synchronizing the tab
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

        let query =
            // existing published/private posts
            "(statusAfterSync = status AND status IN (%@))"
            // existing published/private posts transitioned to another status but not uploaded yet
            + " OR (statusAfterSync != status AND statusAfterSync IN (%@))"
            // Include other existing published/private posts with `nil` `statusAfterSync`. This is
            // unlikely but this ensures that those posts will show up somewhere.
            + " OR (postID > %i AND statusAfterSync = nil AND status IN (%@))"
        let predicate = NSPredicate(format: query,
                                    statuses.strings,
                                    statuses.strings,
                                    BasePost.defaultPostIDValue,
                                    statuses.strings)

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

        let statusesForLocalDrafts: [BasePost.Status] = [.draft, .pending, .publish, .publishPrivate, .scheduled]

        let query =
            // Existing draft/pending posts
            "(statusAfterSync = status AND status IN (%@))"
            // Existing draft/pending posts transitioned to another status but not uploaded yet
            + " OR (statusAfterSync != status AND statusAfterSync IN (%@))"
            // Posts existing only on the device with statuses defined in `statusesForLocalDrafts`.
            + " OR (postID = %i AND status IN (%@))"
            // Include other existing draft/pending posts with `nil` `statusAfterSync`. This is
            // unlikely but this ensures that those posts will show up somewhere.
            + " OR (postID > %i AND statusAfterSync = nil AND status IN (%@))"
        let predicate = NSPredicate(format: query,
                                    statuses.strings,
                                    statuses.strings,
                                    BasePost.defaultPostIDValue,
                                    statusesForLocalDrafts.strings,
                                    BasePost.defaultPostIDValue,
                                    statuses.strings)

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

        let query =
            // existing scheduled posts
            "(statusAfterSync = status AND status IN (%@))"
            // existing scheduled posts transitioned to another status but not uploaded yet
            + " OR (statusAfterSync != status AND statusAfterSync IN (%@))"
            // Include other existing scheduled posts with `nil` `statusAfterSync`. This is
            // unlikely but this ensures that those posts will show up somewhere.
            + " OR (postID > %i AND statusAfterSync = nil AND status IN (%@))"
        let predicate = NSPredicate(format: query,
                                    statuses.strings,
                                    statuses.strings,
                                    BasePost.defaultPostIDValue,
                                    statuses.strings)

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
