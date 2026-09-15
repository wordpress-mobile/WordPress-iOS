import Foundation
import WordPressAPI
import WordPressAPIInternal

/// One rendered item of the redesigned list. Group headers occupy list
/// positions of their own, so the list is built from entries rather than
/// straight from the items.
enum CustomPostListEntry: Identifiable, Equatable {
    /// `ordinal` keeps the id unique: a sticky post floats to the top
    /// regardless of its date, so the same group can open twice in one list.
    case header(CustomPostDateGroup, ordinal: Int)
    case post(CustomPostCollectionItem)

    var id: String {
        switch self {
        case .header(_, let ordinal):
            return "header-\(ordinal)"
        case .post(let item):
            return "post-\(item.id)"
        }
    }
}

enum CustomPostListEntryBuilder {
    /// Interleaves date-group headers into `items`.
    ///
    /// Rows are grouped by the date the list is sorted on, so the headers stay
    /// monotonic. A header is emitted whenever the group changes; items that
    /// carry no post yet (still loading, or failed without data) neither emit
    /// nor reset the current group.
    static func entries(
        from items: [CustomPostCollectionItem],
        showsDateGroups: Bool,
        orderby: WpApiParamPostsOrderBy,
        grouper: CustomPostDateGrouper
    ) -> [CustomPostListEntry] {
        guard showsDateGroups else {
            return items.map { .post($0) }
        }

        var entries: [CustomPostListEntry] = []
        var currentGroup: CustomPostDateGroup?
        for item in items {
            if let post = item.post {
                let group = grouper.group(for: post.groupingDate(orderby: orderby))
                if group != currentGroup {
                    entries.append(.header(group, ordinal: entries.count))
                    currentGroup = group
                }
            }
            entries.append(.post(item))
        }
        return entries
    }
}

extension CustomPostCollectionDisplayPost {
    /// The date the list sorts this post on, and so the one it is grouped by.
    func groupingDate(orderby: WpApiParamPostsOrderBy) -> Date {
        orderby == .modified ? (modifiedDate ?? date) : date
    }
}
