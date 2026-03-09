import Foundation
import WordPressAPI
import WordPressAPIInternal

struct CustomPostListFilter: Equatable {
    var statuses: [PostStatus]
    var primaryStatus: PostStatus
    var order: WpApiParamOrder
    var orderby: WpApiParamPostsOrderBy
    var search: String?

    init(
        statuses: [PostStatus],
        primaryStatus: PostStatus = .publish,
        order: WpApiParamOrder = .desc,
        orderby: WpApiParamPostsOrderBy = .date,
        search: String? = nil
    ) {
        self.statuses = statuses
        self.primaryStatus = primaryStatus
        self.order = order
        self.orderby = orderby
        self.search = search
    }

    init(tab: CustomPostTab) {
        self.statuses = tab.statuses
        self.primaryStatus = tab.primaryStatus
        self.order = tab.order
        self.orderby = tab.orderby
    }

    static func search(input: String) -> Self {
        .init(statuses: [.custom("any")], search: input)
    }

    func asPostListFilter() -> WordPressAPIInternal.PostListFilter {
        .init(
            search: search,
            // TODO: Support author?
            searchColumns: search == nil ? [] : [.postTitle, .postContent, .postExcerpt],
            order: order,
            orderby: orderby,
            status: statuses
        )
    }
}
