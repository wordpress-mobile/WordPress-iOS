enum PostListStringStore {
    enum NoResults {
        static let noResultsImageName = "posts-no-results"

        static let buttonTitle = NSLocalizedString(
            "Create Post",
            comment: "Button title, encourages users to create post on their blog."
        )

        static let fetchingTitle = NSLocalizedString(
            "Fetching posts...",
            comment: "A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new posts."
        )

        static let noMatchesTitle = NSLocalizedString(
            "No posts matching your search",
            comment: "Displayed when the user is searching the posts list and there are no matching posts"
        )

        static let noDraftsTitle = NSLocalizedString(
            "You don't have any draft posts",
            comment: "Displayed when the user views drafts in the posts list and there are no posts"
        )

        static let noScheduledTitle = NSLocalizedString(
            "You don't have any scheduled posts",
            comment: "Displayed when the user views scheduled posts in the posts list and there are no posts"
        )

        static let noTrashedTitle = NSLocalizedString(
            "You don't have any trashed posts",
            comment: "Displayed when the user views trashed in the posts list and there are no posts"
        )

        static let noPublishedTitle = NSLocalizedString(
            "You haven't published any posts yet",
            comment: "Displayed when the user views published posts in the posts list and there are no posts"
        )

        static let noConnectionTitle: String = NSLocalizedString(
            "Unable to load posts right now.",
            comment: "Title for No results full page screen displayedfrom post list when there is no connection"
        )
        static let noConnectionSubtitle: String = NSLocalizedString(
            "Check your network connection and try again. Or draft a post.",
            comment: "Subtitle for No results full page screen displayed from post list when there is no connection"
        )

        static let searchPosts = NSLocalizedString(
            "Search posts",
            comment: "Text displayed when the search controller will be presented"
        )

    }
}
