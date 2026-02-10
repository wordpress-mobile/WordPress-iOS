import Foundation
import WordPressAPI
import WordPressAPIInternal

struct CustomPostListFilter: Equatable {
    var status: PostStatus
    var search: String?

    static var `default`: Self {
        get {
            .init(status: .custom("any"))
        }
    }

    func with(search: String) -> Self {
        var copy = self
        copy.search = search
        return copy
    }

    func asPostListFilter() -> WordPressAPIInternal.PostListFilter {
        .init(
            search: search,
            // TODO: Support author?
            searchColumns: search == nil ? [] : [.postTitle, .postContent, .postExcerpt],
            status: [status],
        )
    }
}
