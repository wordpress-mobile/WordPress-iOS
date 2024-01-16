
struct EmptyFilterViewModel {

    let filterType: FilterType
    let suggestedButtonTap: (() -> Void)?
    let searchButtonTap: (() -> Void)?

    var title: String { filterType.title }
    var body: String { filterType.body }
    var suggestedButton: String { filterType.suggestedButton }
    var searchButton: String { filterType.searchButton }

    enum FilterType {
        case blog
        case tag

        var title: String {
            switch self {
            case .blog:
                return Strings.blogTitle
            case .tag:
                return Strings.tagsTitle
            }
        }

        var body: String {
            switch self {
            case .blog:
                return Strings.blogBody
            case .tag:
                return Strings.tagsBody
            }
        }

        var suggestedButton: String {
            switch self {
            case .blog:
                return ""
            case .tag:
                return Strings.tagsSuggestedButton
            }
        }

        var searchButton: String {
            switch self {
            case .blog:
                return Strings.blogSearchButton
            case .tag:
                return Strings.tagsSearchButton
            }
        }
    }

    struct Strings {
        static let tagsTitle = NSLocalizedString(
            "reader.filterSheet.empty.tags.title",
            value: "No tags",
            comment: "Title for an empty filter sheet on the Reader for tags"
        )
        static let blogTitle = NSLocalizedString(
            "reader.filterSheet.empty.blogs.title",
            value: "No blog subscriptions",
            comment: "Title for an empty filter sheet on the Reader for blogs"
        )
        static let tagsBody = NSLocalizedString(
            "reader.filterSheet.empty.tags.body",
            value: "Subscribe to a tag and you’ll be able to see the best posts from it here.",
            comment: "Body text for an empty filter sheet on the Reader for tags"
        )
        static let blogBody = NSLocalizedString(
            "reader.filterSheet.empty.blogs.body",
            value: "Subscribe to blogs in For You and you’ll see their latest posts here. Or search for a blog that you like already.",
            comment: "Body text for an empty filter sheet on the Reader for blogs"
        )
        static let tagsSuggestedButton = NSLocalizedString(
            "reader.filterSheet.empty.tags.suggested",
            value: "Suggested tags",
            comment: "Suggested tags button text for an empty filter sheet on the Reader"
        )
        static let tagsSearchButton = NSLocalizedString(
            "reader.filterSheet.empty.tags.search",
            value: "Search for a tag",
            comment: "Search tags button text for an empty filter sheet on the Reader"
        )
        static let blogSearchButton = NSLocalizedString(
            "reader.filterSheet.empty.blogs.search",
            value: "Search for a blog",
            comment: "Search blogs button text for an empty filter sheet on the Reader"
        )
    }
}

extension FilterProvider {

    var filterType: EmptyFilterViewModel.FilterType {
        switch reuseIdentifier {
        case ReuseIdentifiers.blogs:
            return .blog
        case ReuseIdentifiers.tags:
            return .tag
        default:
            assertionFailure("Unknown filter type, add an empty filter view for it if necessary")
            return .blog
        }
    }

}
