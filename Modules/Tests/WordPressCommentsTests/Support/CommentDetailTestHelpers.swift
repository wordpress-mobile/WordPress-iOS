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
    resolver: CommentsCapabilityResolver? = nil,
    coordinator: CommentsModerationCoordinator? = nil,
    tracker: (any CommentsTracker)? = nil,
    noticePresenter: (any NoticePresenting)? = nil
) -> CommentDetailViewModel {
    CommentDetailViewModel(
        commentID: commentID,
        seed: seed,
        service: service,
        capabilities: resolver ?? CommentsCapabilityResolver(capabilities: capabilities),
        coordinator: coordinator ?? CommentsModerationCoordinator(service: FakeCommentsService()),
        titleResolver: makeResolver(),
        tracker: tracker,
        noticePresenter: noticePresenter
    )
}

/// A resolver whose lookup has already landed with `canModerate`, standing in
/// for the router's prefetch finishing before a detail screen opens.
@MainActor
func makeResolvedCapabilities(canModerate: Bool) async -> CommentsCapabilityResolver {
    let capabilities = FakeCommentsCapabilities()
    capabilities.canModerate = canModerate
    let resolver = CommentsCapabilityResolver(capabilities: capabilities)
    _ = await resolver.resolve()
    return resolver
}

/// A view model whose authoritative fetch has landed with edit context at
/// `status`, so the toolbar is enabled and actions run through `coordinator`.
@MainActor
func makeLoadedVM(
    status: CommentStatus = .hold,
    coordinator: CommentsModerationCoordinator,
    noticePresenter: (any NoticePresenting)? = nil
) async -> CommentDetailViewModel {
    let service = FakeCommentsService()
    service.fetchCommentResult = .success(makeDetail(id: 1, status: status, editContext: true))
    let vm = makeVM(service: service, coordinator: coordinator, noticePresenter: noticePresenter)
    await vm.onAppear()
    return vm
}
