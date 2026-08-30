import Foundation
import WordPressAPI
@testable import WordPressComments

@MainActor
func makeResolver() -> PostTitleResolver {
    PostTitleResolver(fetcher: { _ in PostTitleResolver.FetchResult(titles: [:]) })
}

func makeDetail(
    id: Int64 = 1,
    parent: Int64 = 0,
    post: Int64 = 10,
    status: CommentStatus = .approved,
    editContext: Bool = false
) -> CommentDetail {
    if editContext {
        return CommentDetail(comment: .editDetailBuilder(id: id, post: post, parent: parent, status: status))
    }
    return CommentDetail(comment: .detailBuilder(id: id, post: post, parent: parent, status: status))
}

@MainActor
func makeVM(
    commentID: Int64 = 1,
    seed: CommentListItem? = nil,
    service: any CommentsServiceProtocol,
    capabilities: FakeCommentsCapabilities = FakeCommentsCapabilities(),
    tracker: (any CommentsTracker)? = nil
) -> CommentDetailViewModel {
    CommentDetailViewModel(
        commentID: commentID,
        seed: seed,
        service: service,
        capabilities: capabilities,
        titleResolver: makeResolver(),
        tracker: tracker
    )
}
