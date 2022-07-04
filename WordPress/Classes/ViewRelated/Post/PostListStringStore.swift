import Foundation

enum PostListStringStore {
    enum PostRestoredPrompt {
        static func message(filter: PostListFilter) -> String {
            switch filter.filterType {
            case .published:
                return NSLocalizedString(
                    "Post Restored to Published",
                    comment: "Prompts the user that a restored post was moved to the published list."
                )
            case .scheduled:
                return NSLocalizedString(
                    "Post Restored to Scheduled",
                    comment: "Prompts the user that a restored post was moved to the scheduled list."
                )
            default:
                return NSLocalizedString(
                    "Post Restored to Drafts",
                    comment: "Prompts the user that a restored post was moved to the drafts list."
                )
            }
        }

        static func cancelText() -> String {
            NSLocalizedString(
                "OK",
                comment: "Title of an OK button. Pressing the button acknowledges and dismisses a prompt."
            )
        }
    }

    enum NoResults {
        static let noConnectionTitle = NSLocalizedString(
            "Unable to load posts right now.",
            comment: "Title for No results full page screen displayedfrom post list when there is no connection"
        )

        static let buttonTitle = NSLocalizedString("Create Post", comment: "Button title, encourages users to create post on their blog.")

        static let noConnectionSubtitle = NSLocalizedString(
            "Check your network connection and try again. Or draft a post.",
            comment: "Subtitle for No results full page screen displayed from post list when there is no connection"
        )

        static let searchPosts = NSLocalizedString("Search posts", comment: "Text displayed when the search controller will be presented")

        static func noResultsTitle(filterType: PostListFilter.Status, isSyncing: Bool, isSearching: Bool) -> String {
            if isSyncing {
                return NSLocalizedString(
                    "Fetching posts...",
                    comment: "A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new posts."
                )
            }

            if isSearching {
                return NSLocalizedString(
                    "No posts matching your search",
                    comment: "Displayed when the user is searching the posts list and there are no matching posts"
                )
            }

            return filteredTitle(
                filterType: filterType
            )
        }

        static func noResultsButtonTitle(filterType: PostListFilter.Status, isSyncing: Bool, isSearching: Bool) -> String? {
            if isSyncing || isSearching {
                return nil
            }

            let filterType = filterType
            return filterType == .trashed ? nil : PostListStringStore.NoResults.buttonTitle
        }

        private static func filteredTitle(filterType: PostListFilter.Status) -> String {
            switch filterType {
            case .draft:
                return NSLocalizedString(
                    "You don't have any draft posts",
                    comment: "Displayed when the user views drafts in the posts list and there are no posts"
                )
            case .scheduled:
                return NSLocalizedString(
                    "You don't have any scheduled posts",
                    comment: "Displayed when the user views scheduled posts in the posts list and there are no posts"
                )
            case .trashed:
                return NSLocalizedString(
                    "You don't have any trashed posts",
                    comment: "Displayed when the user views trashed in the posts list and there are no posts"
                )
            case .published:
                return NSLocalizedString(
                    "You haven't published any posts yet",
                    comment: "Displayed when the user views published posts in the posts list and there are no posts"
                )
            }
        }
    }
}
