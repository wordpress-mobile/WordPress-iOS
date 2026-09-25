import UIKit

/// Shares dependencies across comment detail and parent destinations.
@MainActor
final class CommentDetailContext {
    private let service: any CommentsServiceProtocol
    /// Shared by every detail view model, so the capability resolves once
    /// while the list loads and later screens read it synchronously.
    private let capabilities: CommentsCapabilityResolver
    private let coordinator: CommentsModerationCoordinator
    let titleResolver: PostTitleResolver
    private let tracker: (any CommentsTracker)?
    private let noticePresenter: any NoticePresenting
    private let makeContentRenderer: @MainActor () -> any CommentContentRendering

    init(
        service: any CommentsServiceProtocol,
        capabilities: any CommentsCapabilitiesProtocol,
        coordinator: CommentsModerationCoordinator,
        titleResolver: PostTitleResolver,
        tracker: (any CommentsTracker)?,
        noticePresenter: any NoticePresenting,
        makeContentRenderer: @escaping @MainActor () -> any CommentContentRendering
    ) {
        self.service = service
        self.capabilities = CommentsCapabilityResolver(capabilities: capabilities)
        self.coordinator = coordinator
        self.titleResolver = titleResolver
        self.tracker = tracker
        self.noticePresenter = noticePresenter
        self.makeContentRenderer = makeContentRenderer
        self.capabilities.prefetch()
    }

    func makeViewModel(id: Int64, seed: CommentListItem?) -> CommentDetailViewModel {
        capabilities.prefetch()
        return CommentDetailViewModel(
            commentID: id,
            seed: seed,
            service: service,
            capabilities: capabilities,
            coordinator: coordinator,
            titleResolver: titleResolver,
            tracker: tracker,
            noticePresenter: noticePresenter
        )
    }

    func makeRenderer() -> any CommentContentRendering {
        let renderer = makeContentRenderer()
        renderer.onLinkTapped = { url in
            UIApplication.shared.open(url)
        }
        return renderer
    }
}
