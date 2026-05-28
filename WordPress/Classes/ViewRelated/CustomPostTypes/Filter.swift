import Foundation
import WordPressAPI
import WordPressAPIInternal

struct CustomPostListFilter: Equatable {
    var statuses: [PostStatus]
    var primaryStatus: PostStatus
    var order: WpApiParamOrder
    var orderby: WpApiParamPostsOrderBy
    var search: String?
    var author: [UserId]

    init(
        statuses: [PostStatus],
        primaryStatus: PostStatus = .publish,
        order: WpApiParamOrder = .desc,
        orderby: WpApiParamPostsOrderBy = .date,
        search: String? = nil,
        author: [UserId] = []
    ) {
        self.statuses = statuses
        self.primaryStatus = primaryStatus
        self.order = order
        self.orderby = orderby
        self.search = search
        self.author = author
    }

    init(tab: CustomPostTab, author: [UserId] = []) {
        self.statuses = tab.statuses
        self.primaryStatus = tab.primaryStatus
        self.order = tab.order
        self.orderby = tab.orderby
        self.author = author
    }

    static func search(input: String) -> Self {
        .init(statuses: [.any], search: input)
    }

    func asPostListFilter() -> WordPressAPIInternal.PostListFilter {
        .init(
            search: search,
            // TODO: Support author?
            searchColumns: search == nil ? [] : [.postTitle, .postContent, .postExcerpt],
            author: author,
            order: order,
            orderby: orderby,
            status: statuses
        )
    }
}
