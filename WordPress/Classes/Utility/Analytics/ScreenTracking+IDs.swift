import Foundation

enum ScreenID {
    /// Reader screen identifiers.
    enum Reader {
        static let sidebar = "reader.sidebar"
        static let discover = "reader.discover"
        static let following = "reader.following"
        static let saved = "reader.saved"
        static let likes = "reader.likes"
        static let tag = "reader.tag"
        static let site = "reader.site"
        static let list = "reader.list"
        static let organization = "reader.organization"
        static let search = "reader.search"
        static let article = "reader.article"
        static let comments = "reader.comments"
        static let subscriptions = "reader.subscriptions"
        static let selectInterests = "reader.select_interests"
    }
}

enum ElementID {
    /// Reader trigger component identifiers.
    enum Reader {
        static let postCard = "post_card"
        static let postCardComment = "post_card.comment"
        static let postHeaderSiteName = "post_header.site_name"
        static let suggestedSitesCard = "suggested_sites_card"
        static let suggestedTagsCard = "suggested_tags_card"
        static let relatedPosts = "related_posts"
        static let articleHeaderSiteName = "article_header.site_name"
        static let tagChip = "tag_chip"
        static let commentsSection = "comments_section"
        static let toolbarComment = "toolbar.comment"
        static let searchResult = "search_result"
        static let subscriptionCell = "subscription_cell"
    }
}
